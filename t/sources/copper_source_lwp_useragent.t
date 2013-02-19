#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';	 # Verify that it gets loaded from base module
}

my $has_net_connection = 0;  #  Assume the worst
{
	my $ua = LWP::UserAgent->new; 

	#
	#   Test an arbitrary list of big, massively redundant sites.
	#   It's remotely possible that there's a netsplit and you
	#   actually do have net access but one of these hosts is not
	#   accessible, but one of them should be reachable.
	#
  PING: for ( 'cnn.com', 'google.com', 'yahoo.com', 'amazon.com' ) { # Yeah, yeah, it's not really a ping, it's an HTTP request. 
		if ( $ua->get("http://$_/") ) {
			$has_net_connection = 1;
			last PING;
		} 
	}
	if ( $has_net_connection == 1 ) {
		; # Do nothing
		# diag "Ok, you have basic net access, good"
	}
	else {
		diag('No net connection available; skipping all remaining tests');
		done_testing();
		exit;
	}
}

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
