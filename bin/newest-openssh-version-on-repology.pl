#!/usr/bin/perl

use strict;
use warnings;
use 5.014;

use Mojo::UserAgent;
use Mojo::Collection qw(c);

my $api_url = 'https://repology.org/api/v1/project/openssh';

my $ua = Mojo::UserAgent->new;

c( map { $_->{version} =~ s/_//r } # Some distributions use "X.Y_pZ"
   grep { exists($_->{name})      and exists($_->{status}) and
          $_->{name} eq "openssh" and $_->{status} eq "newest" }
   @{ $ua->get($api_url)->result->json }
 )->uniq->join("\n")->say;
