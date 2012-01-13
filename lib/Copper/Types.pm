package Copper::Types;

use strict;
use warnings;

use List::MoreUtils qw/all/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(HashRef ArrayRef CodeRef Str);
use MooseX::Types::Structured qw(Optional Map Dict);

1;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Copper::Types

=head1 SYNOPSIS

=head1 DECRIPTION

=cut
