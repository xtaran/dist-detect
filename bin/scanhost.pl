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
use IO::Socket::INET6;
use Net::DNS;
use Net::CIDR::Set;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

our $VERSION = '0.1';

my $fmt = '%-31s | %-39s | %s';
my $res = Net::DNS::Resolver->new();

# autoflush
$| = 1;

my @hosts = ();

my $port = 22;
my $help = 0;

GetOptions(
    "port|p=s" => \$port,
    "help|h"   => \$help,
    )
    or pod2usage(-verbose => 2, -exitval => 1);

if ($help) {
    pod2usage(-verbose => 2, -exitval => 0);
}

foreach my $param (@ARGV) {
    if ($param =~ m(^[0-9.:]+(/\d+|-[0-9.:]+)$)) {
        push(@hosts, range2addr($param));
    } else {
        push(@hosts, $param);
    }
}

foreach my $host (@hosts) {
    my $sock = IO::Socket::INET6->new(PeerAddr => $host,
                                      PeerPort => $port,
                                      Proto    => 'tcp',
                                      Timeout  => 2,
        );

    if (!defined $sock) {
        say sprintf($fmt, $host, '[UNKNOWN]', "[CONNFAIL] $!");
    } elsif ($sock->connected) {
        my $banner = <$sock> || '';
        say $sock "SSH-2.0-Dist-Detect_$VERSION";
        # TODO: Make complaints address configurable:
        # . ' (send complaints to example@example.com)';
        my $remote_reverse = lookup($host, $sock);
        $sock->shutdown(2);
        $banner =~ s([\r\n]+$)();
        say sprintf($fmt, $host, $remote_reverse, $banner);
    } else {
        say sprintf($fmt, $host, '[NOCONN]');
    }
}

sub lookup {
    my ($address, $sock) = @_;
    if ($address =~ m(
        # IPv4, not necessarily valid, would match 321.456.789.257
        ^ ( \d{1,3} \. ){1,3} \d{1,3} $ |
        # IPv6 without "::"
        ^ ( [a-f0-9]{1,4} : ){7} [a-f0-9]{1,4} $ |
        # IPv6 with "::" in the last place
        ^ ( [a-f0-9]{1,4} : ){1,7} : [a-f0-9]{1,4} $ | # Abbreviated IPv6
        # IPv6 with "::" somewhere inbetween, possibly too long address
        ^ ( [a-f0-9]{1,4} : ){1,6} : ( [a-f0-9]{1,4} : ){1,6} [a-f0-9]{1,4} $ |
        # IPv6 with "::" in the first place, like fe80::…
        ^ [a-f0-9]{1,4} :: ( [a-f0-9]{1,4} : ){1,6} [a-f0-9]{1,4} $
        )xi) {

        my $reply = $res->query($address, 'PTR');
        if ($reply) {
            foreach my $rr ($reply->answer) {
                if ($rr->type() eq 'PTR') {
                    return $rr->ptrdname();
                }
            }
            return '[DNS ERROR] '.$reply->errorstring;
        } else {
            return '[NO DNS REPLY] ';
        }
    }
    elsif (defined $sock) {
        # Doesn't look like an IP address, so it's probably a
        # hostname, so lets see where it actuallty connected to

        return $sock->peerhost();
    }
    else {
        # Doesn't look like an IP address, so it's probably a
        # hostname, so lets see where it actuallty connected to

        return '[UNKNOWN]';
    }
}

sub range2addr {
    return Net::CIDR::Set->new(@_)->as_address_array();
}

__END__

=head1 NAME

scanhost - Dist-Detect component to gather response data from hosts

=head1 SYNOPSIS

scanhost [B<--help>|B<-h>] [B<--port>|B<-p> I<default-ssh-port>] I<ip[:port]-or-cidr> [I<ip[:port]-or-cidr]>]

=head1 OPTIONS

=over 4

=item B<--help>, B<-h>

Show this help

=item B<--port> I<default-ssh-port>, B<-p> I<default-ssh-port>

Set the default SSH port. (Defaults to 22.)

=back

=head1 EXAMPLES

C<scanhost -p 2222 198.51.100.0/24 2001:db8:2::/64 192.0.2.42:443 '[2001:db8::1]:2022'>

Scans the networks C<198.51.100.0/24> and C<2001:db8:2::/64> on port
C<2222> and the two single IP address with specific ports (those
behind the colon).
