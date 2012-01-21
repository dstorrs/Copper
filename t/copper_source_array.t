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
	use_ok 'Copper';  # Verify that it gets loaded from base module
};

lives_ok { new_obj() } "Can create a new Copper::Source::Array with default params";
isa_ok( new_obj(), 'Copper::Source::Array' );

test "accepts an arrayref init" => sub {
	my $a = Copper::Source::Array->new( init => [ qw/a b c/ ] );
	is( $a->next, 'a', "1st element 'a'" );
	is( $a->next, 'b', "2nd element 'b'" );
	is( $a->next, 'c', "3rd element 'c'" );
};

test "accepts a coderef init" => sub {
	my $a = Copper::Source::Array->new( init => sub { [ qw/a b c/ ] } );
	is( $a->next, 'a', "1st element 'a'" );
	is( $a->next, 'b', "2nd element 'b'" );
	is( $a->next, 'c', "3rd element 'c'" );
};

# START - Add more tests here


done_testing();

sub new_obj {
	Copper::Source::Array->new(
		init => [ 1, 2, 3 ],
		@_,
	);
}
