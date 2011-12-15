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

use Copper::Sink::File;

my $test_filepath = '/tmp/copper_sink_test' . time();

is(1, 1, 'testing framework is working');

lives_ok {  new_sink() } "Can create a Copper::Sink::File with default settings";

#    Test #1
file_contains(
	sub { new_sink() },
	"Msg #1\tMsg #2\tMsg #3\t",
	"Default case",
);

#    Test #2
file_contains(
	sub {
		new_sink( format => sub { join("\n", @_) } )
	},
	"Msg #1\t\nMsg #2\t\nMsg #3\t",
	"Newlines after each line except the last",
);


done_testing();

sub new_sink {
	Copper::Sink::File->new( filepath => $test_filepath, @_ );
}

sub file_contains {
	my $func = shift;
	my $expected = shift;
	my $msg      = shift;

	test "contents match" => sub {
		unlink $test_filepath;
		ok( ! -e $test_filepath, "Before create, file does not exist" );
		my $sink = $func->();
		$sink->drain( msgs() );
		$sink->finalize;
		ok( -e $test_filepath, "After create, file exists" );
		is( scalar slurp($test_filepath), $expected, $msg );
		unlink $test_filepath;
	};
}

sub msgs {  map { "Msg #$_\t" } 1..3 }