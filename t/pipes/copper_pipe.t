#!/usr/bin/env perl

use feature ':5.10';
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Output;
use Test::Group;

use Data::Dumper;
use File::Slurp;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";
use Copper::Pipe;
use Copper::Source::Ints;
use Copper::Sink::Return;
use Copper::Sink::File;


is(1, 1, 'testing framework is working');

test "Basic checks - does not throw under normal circumstances" => sub {
	lives_ok { new_pipe() } "Can create a Copper::Pipe with default settings";
	lives_ok { new_pipe()->next() } "pipe->next works";
};

test "Results from Sink::Return are correct" => sub {
	my $squared = new_pipe(
		sink        => { Return => { transform   => \&square } },
	);
	#
	#   Need to use 'is_deeply' here because 'is' would force scalar context
	is_deeply( [ $squared->next() ], [0], "squared->next is 0 the first time" );
	is_deeply( [ $squared->next() ], [1], "squared->next is 1 the second time" );
	is_deeply( [ $squared->next() ], [4], "squared->next is 4 the third time" );
	is_deeply( [ $squared->next() ], [9], "squared->next is 9 the fourth time" );
};


test "Output from Sink::STDOUT is correct" => sub {
	stdout_is(
		sub { new_pipe( sink => { STDOUT => {} })->next() },
		"0",
		"piping Source::Ints through Identity transform to Sink::STDOUT works"
	);
	stdout_is(
		sub {
			new_pipe(
				sink => { STDOUT => {} },
				source => { Ints => { next_num => 7 } },
			)->next()
		},
		"7",
		"piping Source::Ints through Identity transform to Sink::STDOUT works"
	);
};

test "Results from Sink::File are correct" => sub {

	my $test_file = '/tmp/test.txt';
	unlink $test_file;
	ok( ! -e $test_file, "$test_file does not exist before tests" );
	my $multi_squared = Copper::Pipe->new(
		sources => [ { Ints => { next_num => 7 } }, { Ints => { next_num => 2 } }  ],
		sinks   => [ { File => { filepath => $test_file } }, { Return => { transform => \&square } } ],
	);
	is_deeply( [ $multi_squared->next() ], [49, 4], "multi_squared->next returns correct values on next() #1");
	is_deeply( [ $multi_squared->next() ], [64, 9], "multi_squared->next returns correct values on next() #2");
	is_deeply( [ $multi_squared->next() ], [81, 16], "multi_squared->next returns correct values on next() #3");
	is_deeply( [ $multi_squared->next() ], [100, 25], "multi_squared->next returns correct values on next() #4");
	$multi_squared->finalize;

	ok( -e $test_file, "$test_file does exist after tests" );
	is( read_file($test_file), "728394105", "Test file contents are as expected" );
};

test "Pipes with transforms work" => sub {
	my $pipe = new_pipe( source => { Ints => { next_num => 2 } }, sink => { Return => {} }, transform => sub { shift; ++$_[0] } );
	is_deeply( [ $pipe->next ], [ 3 ], "transform works" );
	is_deeply( [ $pipe->next ], [ 4 ], "transform works" );
	is_deeply( [ $pipe->next ], [ 5 ], "transform works" );
};

###----------------------------------------------------------------

sub new_pipe {
	Copper::Pipe->new(
		source => { Ints => {} },
		@_,
	);
}

###----------------------------------------------------------------

sub square {
	my ($self, $val) = @_;
	return $val ** 2
}

###----------------------------------------------------------------

done_testing();
