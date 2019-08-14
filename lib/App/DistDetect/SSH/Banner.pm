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

=head1 NAME

App::DistDetect::SSH::Banner - Helper functions to work SSH banners

=head1 DESCRIPTION

App::DistDetect::SSH::Banner is part of dist-detect and offers
functions to work with SSH banners.

=cut

package App::DistDetect::SSH::Banner;

use strict;
use warnings;
use 5.010;

use App::DistDetect::History::SSH;

require Exporter;
our @ISA = qw(Exporter);

# DEBUG HELPER
use Data::Printer;

=head1 FUNCTIONS

All functions are exported by default.

=over 4

=cut

our @EXPORT = qw(
    expected_banner_from_version
);

=item expected_banner_from_version

Calculates the expected SSH server banner based on a given package
version.

=cut

sub expected_banner_from_version {
    my ($version, $os) = @_;
    my $banner = $version;

    # Strip (Debian) epoch from OpenSSH package
    $banner =~ s/^\d+://;

    # Mange version to become a banner
    $banner =~ s/^([^-]*)-(.*)$/SSH-2.0-OpenSSH_$1 $os-$2/;

    # TODO: Handle SSHv1+2 vs SSHv2 only

    return $banner;
}

=back
