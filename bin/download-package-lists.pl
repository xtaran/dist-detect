#!/usr/bin/perl

# Copyright 2019, Axel Beckert <axel@ethz.ch> and ETH Zurich.
#
# This file is part of Dist-Detect.
#
# Dist-Detect is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dist-Detect is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dist-Detect.  If not, see
# <https://www.gnu.org/licenses/>.

use strict;
use warnings;
use 5.010;

use Mojo::UserAgent;
use Mojo::File qw(path);
use Mojo::Date;
use Mojo::SQLite;
use FindBin qw($Bin);
use File::Touch;

use Data::Printer;

our $VERSION = '0.1';
our $HOMEPAGE = 'https://github.com/xtaran/dist-detect';

### CONFIG

my @mirrors = @ARGV || qw(
  https://debian.ethz.ch/debian/
  https://debian.ethz.ch/debian-security/
  https://debian.ethz.ch/debian-archive/debian/
  https://debian.ethz.ch/debian-archive/debian-security/
  https://ubuntu.ethz.ch/ubuntu/
  https://raspbian.ethz.ch/raspbian/
  http://archive.raspberrypi.org/debian/
  http://old-releases.ubuntu.com/ubuntu/
);
# TODO: https://archive.raspberrypi.org/debian/ offers HTTPS, but
# results in: SSL connect attempt failed error:141A318A:SSL
# routines:tls_process_ske_dhe:dh key too small

# Skip suite aliases (which are usually symlinks) and kfreebsd (we
# currently don't about any kfreebsd-specific packages and hence we
# don't want to implement special casing for its architecture names)
my $skip_releases = qr/kfreebsd|devel|stable|testing|rc-buggy/;

### CODE

my $download_dir = path("$Bin/../package-lists")->make_path;
my $schema_dir = path("$Bin/../sql")->make_path;

my $ua = Mojo::UserAgent->new();

# old-releases.ubuntu.com occasionally needs over two minutes to only
# return the dists directory.
$ua->connect_timeout(30);

# old-releases.ubuntu.com seems to add artificial lag based on the
# sent user agent string, so set our own
$ua->transactor->name('dist-detect/$VERSION ($HOMEPAGE)');

my $sql = Mojo::SQLite->new("sqlite:$download_dir/packagelists.db");
$sql-> migrations
    -> name('packagelists')
    -> from_file("$schema_dir/packagelists.sql")
    -> migrate;
my $db = $sql->db;

foreach my $base_url (@mirrors) {
    my $res = $ua->get("$base_url/dists/")->result;
    unless ($res->is_success) {
        warn "Can't read $base_url/dists/: ".$res->message;
        next;
    }

    my $dists = $res
        -> dom
        -> find('a[href]')
        -> map(sub { $_[0]->attr('href')})
        -> grep(qr(^[-a-z]+/$))
        -> to_array();

    #p $dists;

    foreach my $dist (@$dists) { # directory name under "dists"
        next if $dist =~ $skip_releases;
        my $plres;
        my $url;
        my $found;
        my $directres;
        my $filename;
        my $release; # Content of release file
        my $distribution; # Name of Distribution, e.g. Debian or Ubuntu
        my $version; # Release version number, e.g. "9"
        my $codename; # Release codename
        my $suite; # Release suite
        my $prefix = '';

        # Some heuristics
        if ($base_url =~ /debian-security|\bsecurity\.debian\./ and
            $dist !~ /bullseye|bookworm/) {
            $dist .= 'updates/';
        }

        my $release_url =
            $dist =~ /slink\/updates\b/ ?
            $base_url."dists/${dist}binary-i386/Release" :
            ($dist =~ /^(bo|slink|hamm)\b/ and
             $dist !~ /-proposed-updates\b/) ?
            $base_url."dists/${dist}main/binary-i386/Release" :
            $base_url."dists/${dist}InRelease";

        # Buzz (1.1) had no Release file at all
        unless ($dist =~ /^(buzz|rex)\b/ or
                ($base_url =~ /debian-security|\bsecurity\.debian\./
                     and $dist =~ /^potato\b/)) {
            my $release_res = $ua->get($release_url)->result;
            if ($release_res->is_error) {
                my $first_error = $release_res->message;
                my $first_url = $release_url;
                # Only try a second guess if we checked for InRelease
                # in first round.
                if ($release_url =~ /InRelease/) {
                    $release_url =~ s/InRelease/Release/;
                    $release_res = $ua->get($release_url)->result;
                    if ($release_res->is_error) {
                        warn "Could neither download $first_url ($first_error) ".
                            "nor $release_url (".$release_res->message.")";
                    }
                } else {
                    warn "Could not download $first_url ($first_error)";
                }
            }

            if ($release_res->is_success) {
                $release = $release_res->body;

                $release =~ /^Label: (.*)$/m or $release =~ /^Origin: (.*)$/m;
                $distribution = $1;

                $release =~ /^Version: (.*)$/m;
                $version = $1;

                $release =~ /^Suite: (.*)$/m;
                $suite = $1;
            }
        } else {
            # Buzz, Rex or Potato Security
            $distribution = 'Debian';
        }

        unless ($distribution) {
            warn "Couldn't determine distribution from release file in $release_url, falling back to parsing URL";
            $distribution = ucfirst($base_url =~ s{^.*/([^/-]+)(-[^/]*)?/?$}{$1}r);

            my @debug = ( $base_url, $dist, $distribution, $version, $codename, $suite );
            p @debug;
        }

        my $main =
            $dist =~ /(hamm|potato|slink)-proposed-updates/ ? '' : 'main';

        my $main_url = $base_url.'dists/'.$dist.$main.'/';
        #p $main_url; next;

        my $mainres = $ua->get($main_url)->result;
        if ($mainres->is_error) {
            # Check for more flat directory structure of ancient Debian releases
            my $test_url = $base_url.'dists/'.$dist.'Packages.gz';
            my $directres = $ua->get($test_url)->result;
            if ($directres->is_error) {
                warn "Skipping $main_url, not accessible: ".$mainres->message;
                next;
            } else {
                $url = $test_url;
            }
        }

        if ($url) {
            $plres = $ua->get($url)->result;
            $filename = $dist.'::Packages.gz';
        } else {
            my @pkglists = qw(
                amd64/Packages.gz
                amd64/Packages.xz
                i386/Packages.gz
                i386/Packages.xz
                );
            if ($base_url =~ /raspbian|raspberry/i) {
                $prefix = "$&-";
                @pkglists = qw(
                    armhf/Packages.xz
                    armhf/Packages.gz
                    arm64/Packages.xz
                    arm64/Packages.gz
                    );
            }
            foreach my $variant (@pkglists) {
                $found = $variant;
                $url = $main_url.'binary-'.$variant;
                #p $url;
                $plres = $ua->get($url)->result;
                last if $plres->is_success();
            }

            if ($plres->is_error) {
                # Skip known and uncorrectable failures:
                # potato: No package list exists
                # slink: only alpha arch
                unless ($url =~ m(debian-archive/debian-security/dists/(potato|slink)/updates/main/)) {
                    warn "Couldn't find package list under $base_url, skipping.\n".
                        "Last URL tried: $url";
                }
                next;
            }

            my $archlist = path($found);
            $filename = sprintf('%s:%s%s:%s:%s:%s',
                                $distribution,
                                $prefix,
                                $dist,
                                $main =~ tr(/)(_)r,
                                $archlist->dirname(),
                                $archlist->basename());
        }

        #p $found;
        #p $url;
        $filename =~ s(/)()g;
        #p $filename;
        say "Downloaded $url to $filename";
        my $save_to = "$Bin/../package-lists/$filename";
        #p $save_to;

        # Will summarize as ->save_to in Mojo >= 8
        $plres->content->asset->move_to($save_to);

        my $last_mod = $plres->headers->last_modified;
        my $count = File::Touch->new(
            mtime => Mojo::Date->new($last_mod)->epoch,
            no_create => 1,
            )->touch($save_to);
        die "Couldn't update mtime of $save_to: $!" unless $count == 1;

        # UPSERT only available from SQLite 3.24.0 (2018-06-04).
        $db->query('replace into packagelists(filename, url, fetched) '.
                   'values (?, ?, ?)', $filename, $url, time());
    }
}
