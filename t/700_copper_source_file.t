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
use Copper::Source::File;

is(1, 1, 'testing framework is working');

my $file;
lives_ok { $file = new_file( filepath => "$Bin/data/copper_source_file.data" ) } "Can create a Copper::Source::File with default settings";

is_deeply( [ new_file()->next ], [ '  this is a ' ],  "next() works" );
is_deeply( [ new_file()->multi_n(2) ], [ '  this is a ', 'test file ' ], "multi_n() works" );
is_deeply( [ new_file()->multi ], [ '  this is a ', 'test file ', ' for Copper::Source::File ' ], "multi() works" );

test "trim() works" => sub {
	is( new_file( chomp => 0 )->next , "  this is a \n",  "next() works (no trim given, chomp => 0)" );	
	is( new_file( chomp => 0, trim => 'none' )->next , "  this is a \n",  "next() works (trim => 'none', chomp => 0)" );	
	is( new_file( trim => 'pre'  )->next, "this is a ",  "next( trim => pre ) works" );
	is( new_file( trim => 'post' )->next, "  this is a", "next( trim => post ) works" );
	is( new_file( trim => 'both' )->next, "this is a",   "next( trim => both ) works" );
};

done_testing();

sub raw_file { Copper::Source::File->new( @_ ) }
sub new_file { Copper::Source::File->new( filepath => "$Bin/data/copper_source_file.data", @_ ) }
