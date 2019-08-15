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

### CONFIG

my @mirrors = @ARGV || qw(
  https://debian.ethz.ch/debian/
  https://debian.ethz.ch/debian-security/
  https://debian.ethz.ch/debian-archive/debian/
  https://debian.ethz.ch/debian-archive/debian-security/
  https://ubuntu.ethz.ch/ubuntu/
  http://old-releases.ubuntu.com/ubuntu/
  https://raspbian.ethz.ch/raspbian/
);
# TODO:
#  https://archive.raspberrypi.org/debian/
# results in:
# SSL connect attempt failed error:141A318A:SSL routines:tls_process_ske_dhe:dh key too small

# Skip suite aliases (which are usually symlinks) and kfreebsd (we
# currently don't about any kfreebsd-specific packages and hence we
# don't want to implement special casing for its architecture names)
my $skip_releases = qr/kfreebsd|devel|stable|testing|rc-buggy/;

### CODE

my $download_dir = "$Bin/../package-lists";
my $schema_dir = "$Bin/../sql";

my $ua = Mojo::UserAgent->new();
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

    my $distribution = ucfirst($base_url =~ s{^.*/([^/-]+)(-[^/]*)?/?$}{$1}r);
    #p $base_url;
    #p $distribution;
    die "Couldn't determine distribution from $base_url" unless $distribution;

    my $dists = $res
        -> dom
        -> find('a[href]')
        -> map(sub { $_[0]->attr('href')})
        -> grep(qr(^[-a-z]+/$))
        -> to_array();

    #p $dists;

    foreach my $dist (@$dists) {
        next if $dist =~ $skip_releases;
        my $plres;
        my $url;
        my $found;
        my $directres;
        my $filename;
        my $prefix = '';

        my $main =
            $base_url =~ /debian-security|\bsecurity\.debian\./ ? 'updates/main' :
            $dist =~ /(hamm|potato|slink)-proposed-updates/ ? '' :
            'main';

        my $main_url = $base_url.'dists/'.$dist.$main.'/';
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
            $filename = sprintf('%s:%s%s:%s:%s',
                                $distribution,
                                $prefix,
                                $dist,
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
