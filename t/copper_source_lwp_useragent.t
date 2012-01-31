#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

use lib '../lib';

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';	 # Verify that it gets loaded from base module
}
;

lives_ok { new_obj() } "Can create a new Copper::Source::LWP::UserAgent with default params";
isa_ok( new_obj(), 'Copper::Source::LWP::UserAgent' );

test "next() works with static or dynamic urls" => sub {
	my ($res1) = new_obj( url => 'http://google.com' )->next;
	my ($res2) = new_obj(
		url      => 'placeholder',
		pre_hook => sub { shift->url( join('', "http://gdata.youtube.com/feeds/api/users/", @_) ) },
	)->next('lisanova');

	isa_ok( $res1, 'HTTP::Response' );
	isa_ok( $res2, 'HTTP::Response' );

	is( $res1->code, 200, "obj->next succeeded with fixed URL" );
	is( $res2->code, 200, "obj->next succeeded with dynamic URL" );
};

# START - Add more tests here


done_testing();

sub new_obj {
	Copper::Source::LWP::UserAgent->new(

		@_,
	);
}
