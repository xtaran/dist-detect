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

use FindBin qw($Bin);

use Mojo::SQLite;

# TODO: Needs to be determined automatically and stored in DB.
my $latest = '8.0';

my $schema_dir = "$Bin/../sql";
my $db_dir = "$Bin/../db";
my $sql = Mojo::SQLite->new("sqlite:$db_dir/pattern.db");
$sql-> migrations
    -> name('packagelists')
    -> from_file("$schema_dir/pattern.sql")
    -> migrate;
my $db = $sql->db;

my %ssh = ();
my $banners = $db->query('select * from banner2version join version2os on banner2version.version=version2os.version and banner2version.os=version2os.os');
while (my $next = $banners->hash) {
    unless (exists $ssh{$next->{banner}}) {
        $ssh{$next->{banner}} = [];
    }

    push(@{$ssh{$next->{banner}}}, $next->{source} =~ s/([^:]*:[^:]*):.*$/$1/r);
}

# Generic patterns
my %ssh_generic = (
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_\E([123]\.|4\.[0-2]\b)/s => '[EoL] Older than RHEL 5',
    qr/^SSH-1\.[^9]/s => '[Scary] SSH-1.x-only server',
    qr/^\QSSH-1.99-/s => '[Insecure] SSH prot. 2 server with SSH prot. 1 still enabled',
    qr/^\QSSH-2.0-OpenSSH_$latest\E(p\d+)?/s => '[BLEEDING EDGE]',
);

my $fmt = "%s|%s|%s|%s";

# autoflush
$| = 1;

while (<>) {
    chomp;
    next if /^$/;
    my ($host, $addr, $sshbanner) = split(/\s+\|\s+/);

    my $match;
    foreach my $key (keys %ssh) {
        if ($sshbanner eq $key) {
            $match = join(',', @{$ssh{$key}});
        }
    }

    unless (defined $match) {
        foreach my $key (keys %ssh_generic) {
            if ($sshbanner =~ $key) {
                $match = $ssh_generic{$key};
            }
        }
    }

    if (defined $match) {
        say sprintf($fmt, $host, $addr, $match, $sshbanner);
    } else {
        say sprintf($fmt, $host, $addr, '[UNKNOWN]', $sshbanner);
    }
}
