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
# WITHOUT ANY WARRANTY; without even the implied warranty aof
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dist-Detect.  If not, see
# <https://www.gnu.org/licenses/>.

use strict;
use warnings;
use 5.010;

my $latest = '7.9';
my %ssh = (
    # Debian 3.1 Sarge
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_3.8.1p1 Debian-8\E($|\.sarge)/s => '[EoL] Debian 3.1 Sarge',
    # Debian 6.0 Squeeze
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.5p1 Debian-6/s => '[EoL] Debian 6.0 Squeeze',
    # Debian 7 Wheezy
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1 Debian-4+deb7u10\E$/s => 'Debian 7 ELTS Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1 Debian-4+deb7u\E[89]$/s => '[NO-SEC-UPD] Debian 7 ELTS Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1 Debian-4+deb7u7\E$/s => '[EoL-ish] [NO-ELTS] Debian 7 LTS Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1 Debian-4\E($|\+deb7u[1-6]\b)/s => '[EoL-ish] [NO-SEC-UPD] Debian 7 LTS Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.6p1 Debian-4~bpo70+1\E$/s => '[NO-SEC-UPD] Debian 7 Wheezy + Backports',
    # Debian 8 Jessie
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.7p1 Debian-5+deb8u7\E$/s => 'Debian 8 LTS Jessie',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.7p1 Debian-5\E($|\+deb8u[1-6]\b)/s => '[NO-SEC-UPD] Debian 8 LTS Jessie',
    # Debian 9 Stretch
    qr/^\QSSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u5\E\b/s => 'Debian 9 Stretch',
    qr/^\QSSH-2.0-OpenSSH_7.4p1 Debian-\E([1-9]|10\+deb9u[1-4])\b/s => '[NO-SEC-UPD] Debian 9 Stretch',
    # Raspbian
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1 Raspbian-4\E\b/s => '[EoL] Raspbian 7 Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.7p1 Raspbian-5\E\b/s => '[EoL-ish] Raspbian 8 Jessie',
    qr/^\QSSH-2.0-OpenSSH_7.4p1 Raspbian-10\E\b/s => 'Raspbian 9 Stretch',
    # Debian/Raspbian with "DebianBanner=no"
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.0p1\E$/s => '[EoL-ish] (maybe) Debian 7 Wheezy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.7p1\E$/s => '(maybe) Debian 8 Jessie',
    qr/^\QSSH-2.0-OpenSSH_7.4p1\E$/s => '(maybe) Debian 9 Stretch',
    # Ubuntu
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_3.8.1p1 Debian-11ubuntu/s => '[EoL] Ubuntu 4.10 Warty',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_4.7p1 Debian-8ubuntu/s => '[EoL] Ubuntu 8.04 LTS Hardy',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.3p1 Debian-3ubuntu/s => '[EoL] Ubuntu 10.04 LTS Lucid',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.5p1 Debian-4ubuntu/s => '[EoL] Ubuntu 10.10 Maverick',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.8p1 Debian-7ubuntu/s => '[EoL] Ubuntu 11.10',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.9p1 Debian-\E[45]ubuntu/s => '[EoL-ish] Ubuntu 12.04 LTS Precise',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.6p1 Ubuntu-4ubuntu/s => '[NO-SEC-UPD] Ubuntu 14.04 LTS Trusty w/o 6.6.1 fix',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2.10/s => 'Ubuntu 14.04 LTS Trusty',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.6.1p1 Ubuntu-2ubuntu\E(1|2|2\.[0-9])$/s => '[NO-SEC-UPD] Ubuntu 14.04 LTS Trusty',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.6.1p1\E$/s => '(maybe) Ubuntu 14.04 LTS Trusty',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_6.7p1 Ubuntu-5ubuntu/s => '[EoL] Ubuntu 15.04 Vivid',
    qr/^\QSSH-2.0-OpenSSH_7.2p2 Ubuntu-4\E($|ubuntu(1|1\.\d+|2|2\.[0-6]))$/s => '[NO-SEC-UPD] Ubuntu 16.04 LTS Xenial',
    qr/^\QSSH-2.0-OpenSSH_7.2p2 Ubuntu-4ubuntu2.7\E\b/s => 'Ubuntu 16.04 LTS Xenial',
    qr/^\QSSH-2.0-OpenSSH_7.5p1 Ubuntu-10ubuntu0.1/s => '[EoL] Ubuntu 17.10 Artful',
    qr/^\QSSH-2.0-OpenSSH_7.6p1 Ubuntu-4\E(\b|ubuntu)/s => 'Ubuntu 18.04 LTS Bionic',
    qr/^\QSSH-2.0-OpenSSH_7.7p1 Ubuntu-4\E(\b|ubuntu)/s => 'Ubuntu 18.10 Cosmic',
    # RHEL / CentOS (and some Apple)
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_3.1p1\E$/s => '[EoL] RHL 7.3 (2002, pre-fedora)',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_4.3\E$/s => '[EoL] RHEL/CentOS 5',
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.3\E$/s => 'RHEL/CentOS 6',
    ### https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/7.4_release_notes/#BZ1341754
    ### https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/7.1_release_notes/#idm140132757747728
    ### https://www.certdepot.net/rhel7-changes-between-versions/
    qr/^\QSSH-2.0-OpenSSH_6.4\E$/s => '[NO-SEC-UPD] RHEL 7.0 / CentOS 7.0-1406',
    qr/^\QSSH-2.0-OpenSSH_6.6.1\E$/s => '[NO-SEC-UPD] RHEL 7.1→3 / CentOS 7-1503→1611',
    qr/^\QSSH-2.0-OpenSSH_7.4\E$/s => 'RHEL 7.4+ / CentOS 7-1708+ or OS X, 10.12 Sierra',
    # SuSE, c.f. https://software.opensuse.org/package/openssh
    qr/^SSH-(2\.0|1\.99)\Q-OpenSSH_5.0\E$/s => '[EoL] openSUSE 10.x / SLES 10.x',
    # Apple, see https://opensource.apple.com/
    qr/^\QSSH-2.0-OpenSSH_5.1\E$/ => "Mac OS X 10.4 Tiger or Mac OS X 10.5.8 Leopard",
    qr/^\QSSH-2.0-OpenSSH_4.5\E$/ => "Mac OS X 10.5 Leopard",
    qr/^\QSSH-2.0-OpenSSH_5.2\E$/ => "Mac OS X 10.6 Snow Leopard",
    qr/^\QSSH-2.0-OpenSSH_5.6\E$/ => "Mac OS X 10.7 Lion",
    qr/^\QSSH-2.0-OpenSSH_5.9\E$/ => "OS X 10.8 Mountain Lion",
    qr/^\QSSH-2.0-OpenSSH_6.2\E$/ => "OS X 10.9 Mavericks or OS X 10.10 Yosemite",
    qr/^\QSSH-2.0-OpenSSH_6.9\E$/ => "OS X 10.11 El Capitan or [NO-SEC-UPD] macOS 10.12.1 Sierra",
    # https://developer.apple.com/library/archive/technotes/tn2449/_index.html
    # https://jira.atlassian.com/browse/SRCTREE-4346
    qr/^\QSSH-2.0-OpenSSH_7.2\E$/ => "[NO-SEC-UPD] macOS 10.12.1 Sierra",
    qr/^\QSSH-2.0-OpenSSH_7.3\E$/ => "[NO-SEC-UPD] macOS 10.12.2 → 10.12.3 Sierra",
    qr/^\QSSH-2.0-OpenSSH_7.4\E$/ => "macOS 10.12.4 → 10.12.6 Sierra",
    qr/^\QSSH-2.0-OpenSSH_7.6\E$/ => "macOS 10.13 High Sierra",
    qr/^\QSSH-2.0-OpenSSH_7.7\E$/ => "macOS 10.14 Mojave",
    # Embedded
    qr/^\QSSH-1.99-cryptlib\E$/ => 'cryptlib SSHd (maybe APC AOS)',
);

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
        if ($sshbanner =~ $key) {
            $match = $ssh{$key};
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
