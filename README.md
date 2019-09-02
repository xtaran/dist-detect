Dist-Detect
===========

Dist-Detect is an active commandline scanner to detect the Linux or
Unix distribution running on a remote host by looking at the banners
or responses of typical Unix netowrk services.

Dist-Detect is currently work in progress. For now only the SSH
service is supported and works already quite well in detecting Debian
and derivatives (Ubuntu, Raspbian, etc.), but HTTP/HTTPS and SMTP
might be a good data source as well.

Purpose
-------

Quickly get an idea …

* … of the Linux/BSD/Unix distribution and distribution release of a
  remote system …

* … if the admin applies security updates regularily …

* … if the remote system is running an EoL release …

… just by looking at the responses of a few common network services,
i.e. very fast.

This is especially useful in heterogenous networks (e.g. with BYOD or
many self-managed machines) as common in academia, data-centers with a
lot of internet-facing, rented servers/racks, etc.

### Focus on Low Hanging Fruits

* If the scanner finds something bad, it's quite sure → nearly no False Positives
* Unknown or unclear versions stay unknown or unclear → will contain False Negatives

Example
-------

```
SSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u4
```

The `7.4p1 Debian` as well as the `deb9` clearly show that this is a
Debian 9 Stretch. From the banner you can determine the according
package version to be `1:7.4p1-10+deb9u4`.

Now you can check against the version in the Debian 9 Stretch
(security) repositories (e.g. [in the Debian Package
Tracker](https://tracker.debian.org/pkg/openssh) if it's the latest
one (it's not as of this writing) and hence if OpenSSH security
updates as provided by Debian have been applied.

This tools tries to automate this kind of analysis and is hence
allowing to scan your whole network quickly for obviously outdated
machines. I call this _Low Hanging Fruits Scanning_.


Work in Progress
----------------

As of now, this work in progress. The prototype currently uses
hardcoded regular expression (which are outdated already), but the
plan is to extract the current versions automatically from the
repositories of or other sources about the recognized operating system
releases.

Especially the database schema will likely still change without
migration path between each incarnation.

License and Copyright
----------------------

Copyright 2019, Axel Beckert <axel@ethz.ch> and [ETH
Zurich](https://www.ethz.ch/).

Dist-Detect is free software: you can redistribute it and/or modify it
under the terms of the [GNU General Public
License](https://www.gnu.org/licenses/gpl.html) as published by the
Free Software Foundation, either [version 3 of the
License](https://www.gnu.org/licenses/gpl-3.0.html), or (at your
option) any later version.

Dist-Detect is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received [a copy of the GNU General Public
License](LICENSE.md) along with Dist-Detect.  If not, see
<https://www.gnu.org/licenses/>.

Thanks!
-------

* Jakob Dhondt for the project name suggestion.
* The [SWITCH Open Source Security Tools Hackathon
  2019](https://www.eventbrite.de/e/open-source-security-tools-hackathon-2019-tickets-59395447382)
  for providing the right atmosphere to get the project away from the
  Proof of Concept state. :-)

Resources
---------

### Short Slide Deck about Dist-Detect

[Slideshow via GitPitch](https://gitpitch.com/xtaran/dist-detect)
([Source file rendered as normal Markdown
file](https://github.com/xtaran/dist-detect/blob/master/PITCHME.md))

### OpenSSH Upstream

* [OpenSSH Release Notes](https://www.openssh.com/releasenotes.html)

### Package Versions

* [OpenSSH in the Debian Package
  Tracker](https://tracker.debian.org/pkg/openssh)

* [Launchpad: OpenSSH package in Ubuntu
  (Overview)](https://launchpad.net/ubuntu/+source/openssh)

* [CertDepot: RHEL7 Changes between
  versions](https://www.certdepot.net/rhel7-changes-between-versions/)

* [OpenSSH package of
  SuSE/openSUSE](https://software.opensuse.org/package/openssh)

* [Open Source Code in use at Apple](https://opensource.apple.com/)

### Specific Details

* [Debian Bug #562048 explains how the DebianBanner patch came
  along](https://bugs.debian.org/562048)

### Unsorted

* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/7.4_release_notes/#BZ1341754
* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/7.1_release_notes/#idm140132757747728
* https://jira.atlassian.com/browse/SRCTREE-4346
