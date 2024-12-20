#!/bin/sh

# Split up CIDR ranges into /24

splitup_cidr_ranges() {
    if echo "$ip" | egrep -q '/(2[4-9]|3[0-2])$' ; then
        echo "$ip"
    elif echo "$ip" | fgrep -q / ; then
        prips "$ip" | awk -F. '{print $1"."$2"."$3".0/24"}' | uniq
    else
        echo "$ip"
    fi
}

if [ -n "$*" ] ; then
    for ip in "$@"; do
        splitup_cidr_ranges
    done
else
    while read ips ; do
        for ip in $ips; do
            splitup_cidr_ranges
        done
    done
fi
