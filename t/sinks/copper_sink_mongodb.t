#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

chdir $Bin;

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';	 # Verify that it gets loaded from base module
}
;

lives_ok { new_obj() } "Can create a new Copper::Sink::MongoDB with default params";
isa_ok( new_obj(), 'Copper::Sink::MongoDB' );
isa_ok( new_obj()->_client, 'MongoDB::MongoClient' );
isa_ok( new_obj()->db, 'MongoDB::Database' );
isa_ok( new_obj()->coll, 'MongoDB::Collection' );


test "config works" => sub {
	my $defaults = { host => 'localhost', port => 27017, db => 'copper' };

	isa_ok( new_obj()->config, 'HASH' );
	is_deeply( new_obj()->config, $defaults, "config not set; still works" );

	for (
		[ [], "provided but all defaults" ],
		[ [host => 'bleh'], "host set" ],
		[ [ host => 'bleh', port => 10 ], "config provided with host and port set" ],
		[ [ host => 'bleh', port => 10, db => 'foo' ], "config provided with host, port, and db set; works" ],
		[ [ host => 'bleh', port => 10, db => 'foo', w => 2 ], "config supprts w" ],
		[ [ host => 'bleh', port => 10, db => 'foo', wtimeout => 2 ], "config supprts wtimeout" ],
	) {
		my $args = { %$defaults, @{$_->[0]} };
		is_deeply(   new_obj(config => $args)->config,
					 $args,
					 $_->[1],
				 );
	}
};

test "writing to DB works" => sub {
	my $obj = new_obj( config => { coll_name => 'copper_tests' });
	my ($db, $coll) = ($obj->db, $obj->coll);
	$coll->drop;  # Start with an empty collection

	is( $coll->count, 0, "collection has no entries" );
	$obj->drain( { a => 1 }, { b => 1 }, { c => 1 }, );
	is( $coll->count, 3, "collection has 3 entries" );
};

# START - Add more tests here


done_testing();

sub new_obj { Copper::Sink::MongoDB->new( @_ ) }
