package Copper::Types;

use strict;
use warnings;

use List::MoreUtils qw/all/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(HashRef ArrayRef CodeRef Str);
use MooseX::Types::Structured qw(Optional Map Dict);

enum 'Copper:Filter:RunTimes' => [qw( pre post )];
coerce 'Copper:Filter:RunTimes' => from 'Str' => via {lc};

enum 'Copper:Filter:Action:Policies' => [qw( allow reject )];
coerce 'Copper:Filter:Action:Policies' => from 'Str' => via {lc};

subtype 'Copper:Filter:Action:Restricted'
	=> as Map['Copper:Filter:Action:Policies', ArrayRef[Str]]
	=> where { keys %$_ == 1 && scalar grep { defined $_ } values %$_ };

union 'Copper:Filter:Action' => [qw( Copper:Filter:Action:Policies HashRef )];

subtype 'Copper:Filter',
	as Dict[
		name    => Optional[Str],
		code    => CodeRef,
		action  => 'Copper:Filter:Action',
	];

subtype 'Copper:Filter:Struct'
	=> as Map[ 'Copper:Filter:RunTimes', 'Copper:Filter:List' ]
	=> where { keys %$_ > 0 }
	=> message { "In 'filters', at least one of 'pre' or 'post' must appear.  Value must be a non-empty arrayref" };

subtype 'Copper:Filter:List'
	=> as ArrayRef[ 'Copper:Filter' ]
	=> where { @$_ > 0 }
	=> message { "Filter arrayref cannot be empty" };

1;

__PACKAGE__->meta->make_immutable;

__END__
