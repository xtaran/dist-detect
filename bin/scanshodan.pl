#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Mojo::File;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Data::Validate::IP qw(is_ip);

my $api_key = Mojo::File->new($ENV{HOME}.'/.shodan/api_key')->slurp();
my $api_url = 'https://api.shodan.io/shodan/host/';
my $ua      = Mojo::UserAgent->new;
$ua->max_redirects(2);
my $fmt = '%-31s | %-39s | %s';

foreach my $ip (@ARGV) {
    if (!is_ip($ip)) {
        warn "$ip doesn't look like an IP, skipping";
        next;
    }

    my $res = $ua->get( $api_url . $ip . '?key=' . $api_key)->result;

    if ($res->is_success) {
        my $json = decode_json($res->body);

        my $data = find_data_set($json->{data}, 'data', '^SSH-');
        my @data = split(/\n/, $data, 2);
        say sprintf($fmt,
                    find_data_set($json->{data}, 'ip_str'),
                    join(', ', @{find_data_set($json->{data}, 'hostnames')}),
                    $data[0]);
    }
    elsif ($res->is_error) {
        warn "$ip: ". $res->message;
    }
    else {
        say 'Whatever...';
    }
}

sub find_data_set {
    my $data = shift;
    my $key = shift;
    my $match = shift;

    foreach my $item (@$data) {
        if (exists($item->{$key})) {
            if (defined $match) {
                if ($item->{$key} =~ /$match/) {
                    return $item->{$key};
                } else {
                    next;
                }
            } else {
                return $item->{$key};
            }
        }
    }
    return undef;
}
