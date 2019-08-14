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

App::DistDetect::History::SSH - knows about OpenSSH feature introductions and removals

=head1 DESCRIPTION

App::DistDetect::History::SSH is part of dist-detect and offers
functions to query if a given OpenSSH (package) version does have a
specific feature (like SSHv1 support or the DebianBanner patch) or
not.

=cut

package App::DistDetect::History::SSH;

use strict;
use warnings;
use 5.010;

use Dpkg::Version;

require Exporter;
our @ISA = qw(Exporter);

=head1 FUNCTIONS

All functions are exported by default.

=over 4

=cut

our @EXPORT = qw(
    upstream_version
    upstream_version_portable
    supports_SSH_v1
    supports_SSH_v2
    supports_DebianBanner_setting
    hardcoded_DebianBanner_setting
);

=item upstream_version_portable($package_version)

Returns the upstream component of an OpenSSH Debian package.

=cut

sub upstream_version_portable {
    my $package_version = shift;
    my $dv =
        ref($package_version) eq 'Dpkg::Version' ?
        $package_version :
        Dpkg::Version->new($package_version);
    return $dv->version;
}

=item upstream_version($package_version)

Returns the upstream component of an OpenSSH Debian package without
the "p<n>" suffix of the portable OpenSSH, i.e. without the usual "p1".

Warning: This function does not necessarily return a string which is
parsable as number as there also were

=cut

sub upstream_version {
    my $package_version = upstream_version_portable(shift);
    return $package_version =~ s/p\d+$//r;
}

=item supports_SSH_v1($package_version)

Returns true if given (package or upstream) version supports the SSHv1
protocol. (Does not necessarily mean that SSHv1 is enabled by
default.)

=cut

sub supports_SSH_v1 {
    my $package_version = shift;
    my $upstream_version = upstream_version($package_version);

    return version_compare_relation($upstream_version, '<<', '7.6');
}

=item supports_SSH_v1($package_version)

Returns true if given (package or upstream) version supports the SSHv2
protocol. (Does not necessarily mean that SSHv2 is enabled by
default.)

=cut

sub supports_SSH_v2 {
    my $package_version = shift;
    my $upstream_version = upstream_version($package_version);

    return version_compare_relation($upstream_version, '>=', '2');
}

=item supports_DebianBanner_setting($package_version)

Returns true if given package version supports the Debian-specific
DebianBanner setting in sshd_config and hence allows both, the
upstream portable banner as well as the Debian-specific banner with
the exact Debian package version.

=cut

sub supports_DebianBanner_setting {
    my $package_version = shift;

    return version_compare_relation($package_version, '>=', '1:5.2p1-2');
}

=item hardcoded_DebianBanner($package_version)

Returns true if given package version has the exact Debian package
version hardcoded in the banner (i.e. before the fix for
L<https://bugs.debian.org/562048>).

=cut

sub hardcoded_DebianBanner {
    my $package_version = shift;

    return (
        version_compare_relation($package_version, '<<', '1:5.2p1-2') and
        version_compare_relation($package_version, '>=', '1:4.0p1-1')
    );
}

=item special_banner($package_version)

Returns undef if there's no special rule to be applied to calculate
the banner from the package version.

If there is a special rule to apply, it will return the banner with
this rule applied.

This is so far only the case if an upstream security patch has been
applied in the package and this patch changes the banner, e.g. with
with 6.6.1 patch against the packaged 6.6 version.

TODO: Not yet implemented.

=cut

sub special_banner {
    # TODO: 6.6.1 in Ubuntu or Debian was applied as patch and hence
    # banner and upstream version don't match. This function should
    # detect and correct that.
}

=back
