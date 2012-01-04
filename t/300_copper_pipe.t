#!/usr/bin/env perl 

use feature ':5.10';
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Output;
use Data::Dumper;
use File::Slurp;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";
use Copper::Pipe;
use Copper::Source::Ints;
use Copper::Sink::Return;
use Copper::Sink::File;


is(1, 1, 'testing framework is working');

#    Basic checks
lives_ok { new_pipe() } "Can create a Copper::Pipe with default settings";
lives_ok { new_pipe()->next() } "pipe->next works";

#    Output from Sink::STDOUT is correct
stdout_is(
	sub { new_pipe( sink => Copper::Sink::STDOUT->new)->next() },
	"0",
	"piping Source::Ints through Identity transform to Sink::STDOUT works"
);
stdout_is(
	sub {
		new_pipe(
			sink => Copper::Sink::STDOUT->new,
			source => Copper::Source::Ints->new(next_num => 7)
		)->next()
	},
	"7",
	"piping Source::Ints through Identity transform to Sink::STDOUT works"
);

#    Results from Sink::Return are correct
sub square { shift()**2 }
my $squared = new_pipe(
	sink        => Copper::Sink::Return->new,
	transform   => \&square,
);
#
#   Need to use 'is_deeply' here because 'is' would force scalar context
is_deeply( [ $squared->next() ], [0], "squared->next is 0 the first time" );
is_deeply( [ $squared->next() ], [1], "squared->next is 1 the second time" );
is_deeply( [ $squared->next() ], [4], "squared->next is 4 the third time" );
is_deeply( [ $squared->next() ], [9], "squared->next is 9 the fourth time" );

my $test_file = '/tmp/test.txt';
unlink $test_file;
ok( ! -e $test_file, "$test_file does not exist before tests" );
my $multi_squared = Copper::Pipe->new(
	sources => [ Copper::Source::Ints->new( next_num => 7 ), Copper::Source::Ints->new( next_num => 2 ) ],
	sinks   => [ Copper::Sink::File->new(filepath => $test_file), Copper::Sink::Return->new ],
	transform => \&square,
);
is_deeply( [ $multi_squared->next() ], [49, 4], "multi_squared->next returns correct values on next() #1");
is_deeply( [ $multi_squared->next() ], [64, 9], "multi_squared->next returns correct values on next() #2");
is_deeply( [ $multi_squared->next() ], [81, 16], "multi_squared->next returns correct values on next() #3");
is_deeply( [ $multi_squared->next() ], [100, 25], "multi_squared->next returns correct values on next() #4");
$multi_squared->finalize;

ok( -e $test_file, "$test_file does exist after tests" );
is( read_file($test_file), "494649811610025", "Test file contents are as expected" );

###----------------------------------------------------------------

sub new_pipe {
	Copper::Pipe->new(
		source => Copper::Source::Ints->new,
		@_,
	)
}

done_testing();
