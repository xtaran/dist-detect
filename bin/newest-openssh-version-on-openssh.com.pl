#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

use Mojo::UserAgent;

my $url = 'https://www.openssh.com/';
my $ua = Mojo::UserAgent->new;

my $callout =  $ua->get($url)->result->dom->at('#callout')->at('a');
my $callout_link = $callout->attr('href') =~ s/^txt\/release-//r;
my $callout_text = $callout->text =~ s/^OpenSSH //r;

if ($callout_link eq $callout_text) {
    say $callout_link;
} else {
    warn "Either the callout's link or text couldn't be found or parsed, reporting both";
    say $callout_link;
    say $callout_text;
}
