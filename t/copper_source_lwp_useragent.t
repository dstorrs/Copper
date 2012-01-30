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

lives_ok { new_obj() } "Can create a new Copper::Source::LWP::UserAgent with default params";
isa_ok( new_obj(), 'Copper::Source::LWP::UserAgent' );

isa_ok( new_obj( url => 'http://google.com' )->next, 'HTTP::Response' );

# START - Add more tests here


done_testing();

sub new_obj {
	Copper::Source::LWP::UserAgent->new(

		@_,
	);
}