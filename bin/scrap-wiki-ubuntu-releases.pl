#!/usr/bin/perl

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

use strict;
use warnings;
use 5.010;

use Mojo::UserAgent;
use Mojo::SQLite;

#use Data::Printer;

my $url = 'https://wiki.ubuntu.com/Releases';

my $ua = Mojo::UserAgent->new;
my $res = $ua->get($url)->res;
die $res->message unless $res->is_success;

$res->dom->find('h3[id]')->each(
    sub {
        my $section = $_->{id};
        return unless ($section eq 'Current' or
                       $section eq 'End_of_Life');

        my $sibling = $_;
        my $table;
        while ($sibling and !$table) {
            $table = $sibling->at('table')
                or $sibling = $sibling->next;
        }
        return unless $table;

        $table->find('tr')->each(
            sub {
                $_->find('td')->each(
                    sub {
                        my $text = $_->all_text;
                        #p $text;
                    });
            });
    });
