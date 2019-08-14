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

my $pkglistdir = "$Bin/../package-lists";
my $schema_dir = "$Bin/../sql";
my $db_dir = "$Bin/../db";

my $sql = Mojo::SQLite->new("sqlite:$db_dir/pattern.db");
$sql-> migrations
    -> name('packagelists')
    -> from_file("$schema_dir/pattern.sql")
    -> migrate;
my $db = $sql->db;


foreach my $pkglist (glob("$pkglistdir/*Packages*")) {
    #p $pkglist;
    my $z = Dpkg::Compression::FileHandle->new(filename => $pkglist);
    $z->ensure_open('r');

    # Skip empty package lists
    next if $z->eof;

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
    say("$version | $pkglistshort") if defined($version) && $version ne '';
    $db->query('replace into version2os(version,os,source,lastmod) '.
               'values (?, ?, ?, ?)',
               $version, $os, $pkglistshort, path($pkglist)->stat->mtime);

    my @banners = expected_banner_from_version($version, $os);
    p @banners;
    foreach my $banner (@banners) {
        $db->query('replace into banner2version(version,banner) '.
                   'values (?, ?)',
                   $version, $banner);
    }
}
