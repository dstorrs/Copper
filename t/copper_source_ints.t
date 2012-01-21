#!/usr/bin/env perl 

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;
use Copper::Source::Ints;

is(1, 1, 'testing framework is working');

my $ints;
lives_ok { $ints = new_ints() } "Can create a Copper::Source::Ints with default settings";

test "default source::int counts up from 0 by ones" => sub {
	for ( 1..10 ) {
		my $val = -1;
		is( $val = $ints->next, $_ - 1, "Result #$_ from a 'Ints' source is $val" );
	}
};

is( $ints->peek, 10, "ints->peek is 10" );
is( $ints->next, 10, "ints->next is 10" );

is_deeply( [ new_ints()->multi ], [ 0..99 ], "default source::int 'multi'" );
is_deeply( [ new_ints()->multi_n(7) ], [ 0..6 ], "default source::int->multi_n(7) returns 0..6" );

is( new_ints(default_multi => 2)->default_multi, 2, "default_multi set corrctly");
is_deeply( [ new_ints(default_multi => 2)->multi ], [ 0..1 ], "source::int(default_multi => 2)->multi" );

is_deeply( [ new_ints(default_multi => 2)->multi_n(7) ], [ 0..6 ], "source::int(default_multi => 2)->multi_n(7)" );

done_testing();

sub new_ints { Copper::Source::Ints->new( @_ ) }
