#!/bin/sh

# Split up CIDR ranges into /24

for ip in "$@"; do
    if echo "$ip" | egrep -q '/(2[4-9]|3[0-2])$' ; then
        echo -n "$ip "
    elif echo "$ip" | fgrep -q / ; then
        prips "$ip" | awk -F. '{print $1"."$2"."$3".0/24"}' | uniq | tr '\n' ' '
    else
        echo -n "$ip "
    fi
done
