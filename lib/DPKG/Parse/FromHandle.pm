package DPKG::Parse::FromHandle;
use strict;
use warnings;

our $VERSION = '0.01';

use Params::Validate qw(:all);
use Class::C3;
use base 'DPKG::Parse';

# DEBUG HELPER
use Data::Printer;

sub new {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'handle' => { 'isa' => [qw[IO::Handle]]},
            'debug' => { 'type' => SCALAR, 'default' => 0, 'optional' => 1 },
        }
    );
    my $ref = {};
    if ($p{'handle'}) {
        $ref->{'handle'} = $p{'handle'};
    };
    $ref->{debug} = $p{debug};
    $ref->{'entryarray'} = [];
    $ref->{'entryhash'} = {};
    bless($ref, $pkg);
    return $ref;
}

sub parse {
    my $pkg = shift;
    $pkg->parse_package_format_from_handle;
}

sub parse_package_format_from_handle {
    my $pkg = shift;
    my $entry;
    my $line_num = -1;
    my $entry_line = 0;
    STATUSLINE: while (my $line = $pkg->{handle}->getline) {
        ++$line_num;
        $line =~ s/^\t/        /;
        if ($line =~ /^\n$/) {
            my $dpkg_entry = DPKG::Parse::Entry->new(
                'data' => $entry,
                'debug' => $pkg->debug,
                'line_num' => $entry_line,
                );
            push(@{$pkg->{'entryarray'}}, $dpkg_entry);
            $pkg->{'entryhash'}->{$dpkg_entry->package} = $dpkg_entry;
            $entry = undef;
            $entry_line = $line_num + 1;
            next STATUSLINE;
        }
        $entry = $entry . $line;
    }
}

1;
