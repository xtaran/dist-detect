#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

use Mojo::UserAgent;
use Mojo::Collection qw(c);
use List::Util qw(max);
# Maybe use Mojo::Collection::Role::UtilsBy later.

my $api_url = 'https://www.wikidata.org/wiki/Special:EntityData/Q847062.json';
my $ua = Mojo::UserAgent->new;

say max
    @{
        c(
            @{
                $ua->get($api_url)->result->json->{entities}{Q847062}{claims}{P348}
            }
            )
            ->map(sub { $_->{mainsnak}{datavalue}{value} })
            ->grep(sub { !/p\d+$/ })
            ->to_array
    };
