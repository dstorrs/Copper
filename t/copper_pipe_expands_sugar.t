#!/usr/bin/env perl 

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';
};

test "blessed sinks / sources are accepted" => sub {
	lives_ok {
		Copper::Pipe->new(
			source => Copper::Source::Ints->new,
			sink   => Copper::Sink::Return->new,
		),
	} "blessed source and sink, solo";
	
	lives_ok {
		Copper::Pipe->new(
			source => [ Copper::Source::Ints->new ], 
			sink   => [ Copper::Sink::Return->new ], 
		),
	} "blessed source and sink, array";

	lives_ok {
		Copper::Pipe->new(
			sources => [ Copper::Source::Ints->new ], 
			sinks   => [ Copper::Sink::Return->new ], 
		),
	} "blessed sourceS and sinkS, array";

	lives_ok {
		Copper::Pipe->new(
			sources => Copper::Source::Ints->new, 
			sinks   => Copper::Sink::Return->new, 
		),
	} "blessed sourceS and sinkS, array";
};


test "source expands" => sub {
	my $pipe = new_pipe( source => { Array => { init => sub { [ qw/a b c/ ] } } } );

	isa_ok( $pipe, 'Copper::Pipe');
	isa_ok( $pipe->_get_source(0), 'Copper::Source::Array');
	is( $pipe->_get_source(0)->next, 'a', "first  entry in array is 'a'" );
	is( $pipe->_get_source(0)->next, 'b', "second entry in array is 'b'" );
	is( $pipe->_get_source(0)->next, 'c', "third  entry in array is 'c'" );
};

test "sink expands" => sub {
	my $pipe = new_pipe( sink => { Return => {} } );
	isa_ok( $pipe, 'Copper::Pipe');
	isa_ok( $pipe->_get_sink(0), 'Copper::Sink::Return');
};

done_testing();

sub new_pipe {
	Copper::Pipe->new(
		source => { Ints => { init => [ 0..9 ] } },
		sink   => { Return => {} },
		@_
	);
}
