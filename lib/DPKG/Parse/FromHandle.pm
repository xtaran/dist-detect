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
    my $self = shift;
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
    bless($ref, $self);
    return $ref;
}

sub parse {
    my $self = shift;
    $self->parse_package_format_from_handle;
}

sub parse_package_format_from_handle {
    my $self = shift;
    my $handle = $self->{handle};
    my $entry = '';
    my $line_num = -1;
    my $entry_line = 0;
    STATUSLINE: while (my $line = $handle->getline) {
        #p $line;
        ++$line_num;
        $line =~ s/^\t/        /;
        if ($line =~ /^\n$/) {
            my $dpkg_entry = DPKG::Parse::Entry->new(
                'data' => $entry,
                'debug' => $self->debug,
                'line_num' => $entry_line,
                );
            push(@{$self->{'entryarray'}}, $dpkg_entry);
            $self->{'entryhash'}->{$dpkg_entry->package} = $dpkg_entry;
            $entry = '';
            $entry_line = $line_num + 1;
            next STATUSLINE;
        }
        $entry = $entry . $line;
    }
}

1;
