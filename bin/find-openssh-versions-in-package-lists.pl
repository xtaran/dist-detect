#!/usr/bin/env perl

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

use FindBin qw($Bin);
use lib "$Bin/../lib";
use DPKG::Parse::FromHandle;

use Mojo::File qw(path);
use Mojo::SQLite;
use DPKG::Parse::Packages;
use Dpkg::Compression::FileHandle;
use App::DistDetect::SSH::Banner;

# DEBUG HELPER
use Data::Printer;

my $pkglistdir = path("$Bin/../package-lists")->make_path;
my $schema_dir = path("$Bin/../sql")->make_path;
my $db_dir = path("$Bin/../db")->make_path;

my $sql = Mojo::SQLite->new("sqlite:$db_dir/pattern.db");
$sql-> migrations
    -> name('packagelists')
    -> from_file("$schema_dir/pattern.sql")
    -> migrate;
my $db = $sql->db;

my $pkglst_sql = Mojo::SQLite->new("sqlite:$pkglistdir/packagelists.db");
$sql-> migrations
    -> name('packagelists')
    -> from_file("$schema_dir/packagelists.sql")
    -> migrate;
my $pkglst_db = $pkglst_sql->db;

foreach my $pkglist (glob("$pkglistdir/*Packages*")) {
    #p $pkglist;
    my $z = Dpkg::Compression::FileHandle->new(filename => $pkglist);
    $z->ensure_open('r');

    # Skip empty package lists
    next if $z->eof;

    my $pkglst_file = path($pkglist)->basename;
    my $pkglst_meta =
        $pkglst_db->query("select * from packagelists where filename='$pkglst_file'")
        ->hash;

    my $pkgs = DPKG::Parse::FromHandle->new('handle' => $z);
    $pkgs->parse();
    #p $pkgs;
    my $pkg = $pkgs->get_package(name => 'openssh-server')
        || $pkgs->get_package(name => 'ssh');
    #p $pkg;
    next unless $pkg;

    # Strip directory name
    my $pkglistshort = path($pkglist)->basename;

    # Extract information from package list file name
    my ($os, $repo, $arch) = split(/:/, $pkglistshort);
    my $release = $repo =~ s/-.*$//r;

    my $version = $pkg->version;

    my $tags =
        ($pkglst_meta->{url} =~ /old-releases|debian-archive/) ?
        'EOL' : '';

    # The current version
    say("$version | ".($tags?"[$tags] ":'')."$pkglistshort")
        if defined($version) && $version ne '';
    $db->query('replace into version2os(version,os,source,lastmod,tags) '.
               'values (?, ?, ?, ?, ?)',
               $version, $os, $pkglistshort, path($pkglist)->stat->mtime,
               $tags);

    my @banners = expected_banner_from_version($version, $os);
    p @banners;
    foreach my $banner (@banners) {
        $db->query('replace into banner2version(version,os,banner,source) '.
                   'values (?, ?, ?, ?)',
                   $version, $os, $banner, $pkglistshort);
    }

    # Calculate predecessor versions of security updates
    # Examples for $version:
    # 1:7.2p2-4ubuntu2.8
    # 1:7.4p1-10+deb9u6
    # TODO: 1:6.6p1-4~bpo70+1
    if ($pkglist !~ /proposed/ and
        $version =~ /^
        (
          # Optional epoch
          (?: \d+ : )?
          # Upstream version
          [\d.p]+
          # Delimited between upstream version and package release
          -
          # Package release (dot possible for NMUs)
          [\d.]+
          # End of Debian base package version
        )
        # Updates
        (
          # Update prefix for Debian and Ubuntu
          # (Raspbian uses Debian's infixes.)
          (
            ubuntu       |
            build        |
            \+ deb \d+ u |
            \. woody \.  |
            \. sarge \.  |
            etch         |
            \+ squeeze   |
          )
          # This is where stable updates get counted
          ( [\d.]+ )
        )$/x) {

        my $local_tags = $tags ? $tags.' NO-UPD' : 'NO-UPD';

        my $v_unchanged   = $1;
        my $v_infix       = $3;
        my $v_upd_counter = $4;

        my @upd_counter_values = ();

        # Check if there's a dot in the update counter
        if ($v_upd_counter =~ /\./) {
            my $first  = $`;
            my $second = $';
            if ($second > 1) {
                foreach my $suffix (1..($second-1)) {
                    push(@upd_counter_values,
                         $v_unchanged.$v_infix.$first.'.'.$suffix);
                }
            }

            foreach my $suffix (1..$first) {
                push(@upd_counter_values,
                     $v_unchanged.$v_infix.$suffix);
            }
        } else { # no dot
            # Ubuntu starts counting with zero
            if ($v_upd_counter > 0) {
                foreach my $suffix (0..($v_upd_counter-1)) {
                    push(@upd_counter_values,
                         $v_unchanged.$v_infix.$suffix);
                }
            }
        }

        # Also list the initial version for that release
        push(@upd_counter_values, $v_unchanged);

        p @upd_counter_values;

        foreach my $no_sec_upd_version (@upd_counter_values) {
            say("$no_sec_upd_version | ".($local_tags?"[$local_tags] ":'').
                " $pkglistshort")
                if defined($no_sec_upd_version) && $no_sec_upd_version ne '';
            $db->query('replace into version2os(version,os,source,lastmod,tags) '.
                       'values (?, ?, ?, ?, ?)',
                       $no_sec_upd_version, $os, $pkglistshort,
                       path($pkglist)->stat->mtime, $local_tags);

            my @banners = expected_banner_from_version($no_sec_upd_version, $os);
            p @banners;
            foreach my $banner (@banners) {
                $db->query('replace into banner2version(version,os,banner,source) '.
                           'values (?, ?, ?, ?)',
                           $no_sec_upd_version, $os, $banner, $pkglistshort);
            }
        }
    }
}
