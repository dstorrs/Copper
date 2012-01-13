#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;

use Data::Dumper;
use File::Slurp qw/slurp/;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";

use Copper::Part::Pipe::Filter;


is(1, 1, 'testing framework is working');

throws_ok { raw_filter() } qr/No 'when' key provided to filter/, "Filters must have 'when' key";
throws_ok { raw_filter(when => 'foo') } qr/'when' key must be 'pre' or 'post'/, "'when' key must be 'pre' or 'post'";
throws_ok { raw_filter(when => 'pre', code => sub {}, policy => 'foo') } qr/'policy' must be single-key hashref \(with key =~ allow|reject\), or string =~ allow\|reject/,
	"'foo' is not a legal policy";

is( new_filter()->name, '*unknown*', "Name defaults to '*unknown*'" );

is_deeply( [ new_filter( name => 'remove_evens' )->apply_to(8) ], [   ], "remove_evens properly removed 8" );
is_deeply( [ new_filter( name => 'remove_evens' )->apply_to(7) ], [ 7 ], "remove_evens properly did NOT remove 7" );

lives_ok  { raw_filter(when => 'pre', code => sub {}, policy => 'allow') } "'allow' is a legal policy";
lives_ok  { raw_filter(when => 'pre', code => sub {}, policy => 'reject') } "'reject' is a legal policy";
lives_ok  { new_filter(	policy => { allow => [ qw/sink_name1 sink_name2/ ] } ) } "hashref->allow is a legal policy";
lives_ok  { new_filter(	policy => { reject => [ qw/sink_name1 sink_name2/ ] } ) } "hashref->reject is a legal policy";
throws_ok { new_filter(	policy => { foo => [ qw/sink_name1 sink_name2/ ] } ) } qr/'policy' must be single-key hashref/,
	"hashref->foo is not a legal policy";

	
done_testing();

sub raw_filter { Copper::Part::Pipe::Filter->new( @_ ) }

sub new_filter {
	return Copper::Part::Pipe::Filter->new(
		when => 'pre',
		policy => 'reject',
		code => sub { 0 == ($_[0] % 2) },
		@_
	)
}

__END__
