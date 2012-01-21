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

test "source expands" => sub {
	my $pipe = new_pipe( source => { Array => { init => sub { [ qw/a b c/ ] } } } );

	isa_ok( $pipe, 'Copper::Pipe');
	isa_ok( $pipe->_get_source(0), 'Copper::Source::Array');
	is( $pipe->_get_source(0)->next, 'a', "first  entry in array is 'a'" );
	is( $pipe->_get_source(0)->next, 'b', "second entry in array is 'b'" );
	is( $pipe->_get_source(0)->next, 'c', "third  entry in array is 'c'" );
};

done_testing();

sub new_pipe {
	Copper::Pipe->new(
		source => { Ints => { init => [ 0..9 ] } },
		sink   => { Return => {} },
		@_
	);
}
