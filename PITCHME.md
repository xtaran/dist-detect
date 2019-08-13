Dist-Detect
===========

Axel Beckert <axel@ethz.ch>

#HSLIDE

Purpose
-------

Quickly get an idea …

* of the Linux/BSD/Unix distribution and distribution release of a
  remote system

* if the admin applies security updates regularily

* if the remote system is running an EoL release

just by looking at the responses of a few common network services
(typically SSH and web servers), i.e. very fast.

#HSLIDE

Scenario
--------

* Heterogenous networks (e.g. with BYOD or many self-managed machines)
  as common in academia, data-centers with a lot of internet-facing,
  rented servers/racks, etc.

* Find old, not yet streamlined / automated / documented deployments.

### Focus on Low Hanging Fruits

* No False Positives: If the scanner finds something bad, it's bad.
* False Negatives: Unknown/unclear versions stay unknown/ unclear.

#HSLIDE

Why a Dedicated Tool?
---------------------

Scanning your own network for badly maintained / not updated Linux,
BSD and other Unix systems is currently tedious and slow:

* Most vulnerability scanners still test tons of (from this point of
  view unnecessary) stuff and take rather long per host.

* Many vulnerability scanners just look at the reported upstream
  version and trigger a lot of false positives when a distribution
  just fixes security issues instead of packaging new upstream
  versions (which is rather common with so called "stable releases").

* Nmap and friends don't look at server application versions to
  determine the OS. Takes rather long, too, even witth `-T
  aggressive`.

#HSLIDE

General Idea
------------

* Many services display also the exact package version on some
  distributions (especially OpenSSH on Debian, Ubuntu and
  derivatives), so let's scan specifically for these.

* Specific versions of OpenSSH, Apache, Nginx, Dropbear, etc. are only
  shipped with very few "stable releases", so you can easily limit the
  list of possible/likely OS/distributions to a few if not even
  one.

    * E.g. RedHat as well as macOS only report the upstream OpenSSH
      version, but there are still very few OpenSSH versions which are
      shipped in both RHEL and macOS.

    * RHEL and macOS report OpenSSH version without the "p1" and hence
      this can be used to distinguish it from other distributions.

#HSLIDE

Capabilities
------------

Check that version to determine …

* which OS/distribution is running. (Might report multiple
  possibilities.)

    * …f the OS/distribution is EoL

* which package version is running. (Might not be possible.)

    * if the running package is the most recent security update.

    * if not, for how long at least the admin hasn't applied security
      updates.

    * if the server uses SSH backports

    * if the server uses proposed updates

    * if the server uses LTS repositories

* Bonus: Find SSH servers which still offer the known to be vulnerable
  SSHv1 protocol versions.

#HSLIDE

Real-Life Example SSH Banners
-----------------------------

```
$ echo 'foobar' | nc unstable 22
SSH-2.0-OpenSSH_7.9p1 Debian-5
Protocol mismatch.

$ tail -1 /var/log/auth.log
Jan 31 14:05:55 unstable sshd[7647]: Bad protocol version identification 'foobar' from 127.0.0.1 port 40140

$ echo 'foobar' | nc some-mac 22
SSH-2.0-OpenSSH_7.9
Protocol mismatch.

$ echo 'foobar' | nc some-turris-omnia 22
SSH-2.0-OpenSSH_7.9
Protocol mismatch.

$ echo 'foobar' | nc guesstheos 22
SSH-2.0-OpenSSH_7.4p1 Debian-10+deb9u4
Protocol mismatch.

$ echo 'foobar' | nc somerhel7 22
SSH-2.0-OpenSSH_7.4
Protocol mismatch.

$ echo 'foobar' | nc someubuntu 22
SSH-2.0-OpenSSH_7.2p2 Ubuntu-4ubuntu2.6
Protocol mismatch.

$ echo 'foobar' | nc somesupportedubuntuwithoutsecurityupdates 22
SSH-2.0-OpenSSH_7.2p2 Ubuntu-4
Protocol mismatch.

$ echo 'foobar' | nc obvioustoo 22
SSH-2.0-OpenSSH_6.7p1 Debian-5+deb8u7
Protocol mismatch.

$ echo 'foobar' | nc eolishalready 22
SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u10
Protocol mismatch.

$ echo 'foobar' | nc somerhel6 22
SSH-2.0-OpenSSH_5.3
Protocol mismatch.

$ echo 'foobar' | nc someancientmachinefrom2002withsshv1enabled 22
SSH-1.99-OpenSSH_3.1p1
Protocol mismatch.
```

Current State of Project
------------------------

* Scanner (native) works and is reasonably fast (about 10-15 seconds
  per /24 if all hosts are online)

* Version string interpreter works, but consists of handwritten
  regular expressions which need to be updated regularily and
  manually.

* A rudimentary scraper for Debian and Ubuntu package repositories
  exist.

* Written in Perl 5.

** First prototype was written in Shell using `echo '' | nc $host
   22`. :-)

** Perl 6 might be an option, too.

### Example Regular Expressions

(These are manually maintained examples which got stuck at a time
before the Buster release and while Wheezy still had ELTS support.)

```perl
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
```

#HSLIDE

TODO
-----

* Let the scraper save the found package versions in a database
  (SQLite).

* Generate regular expressions to match service banners from package
  versions automatically based on scraped repository data.

#HSLIDE

Wanted, too
-----------

* Unit testing

    * Travis CI
    * Coveralls

* Package for CPAN.

    * Probably with Dist::Zilla aka dzil

* Package for Debian.

    * Probably with dh-dist-zilla.

#HSLIDE

Further Ideas
-------------

* Also store results and scan dates in a database.

* Check if using repology.org might be better than downloading
  complete package lists.

* Extend the system to also be able to check ports 80 and 443 and
  maybe others.

* Maybe download and parse package changelogs to see which versions
  actually existed.

* Add optional scanning backends.

    * scanssh, pnscan, masscan
    * Shodan.io? (i.e. interpreting publicly available/found data)

* Ping (fping?) before scan.
