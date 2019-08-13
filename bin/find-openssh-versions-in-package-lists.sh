#!/bin/sh

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

PKGLISTDIR="$(dirname $0)/../package-lists"

for pkglist in ${PKGLISTDIR}/*Packages*; do
    pkglistshort=$(basename $pkglist)
    printf "$pkglistshort: "

    case $pkglistshort in
        *.gz)      CAT=zcat   ;;
        *.xz)      CAT=xzcat  ;;
        *.bz2)     CAT=bzcat  ;;
        *.lz4)     CAT=lz4cat ;;
        *Packages) CAT=cat    ;;
        *Packages.*) echo "Unknown compression format: $pkglistshort"; exit 1;;
    esac
    ${CAT} ${pkglist} | grep-dctrl -X -P openssh-server -n -s Version \
        || ${CAT} ${pkglist} | grep-dctrl -X -P ssh -n -s Version \
        || echo ''
done \
    | egrep -v ': $' \
    | awk -F': ' '{print $2" | "$1}' \
    | sort
