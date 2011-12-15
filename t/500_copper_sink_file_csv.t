#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;
use File::Slurp qw/slurp/;
use Text::CSV;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";

use Copper::Sink::File::CSV;

$| = 1;

my $test_filepath = '/tmp/copper_sink_test' . time();
my $filepath__expected = "$test_filepath.expected";

is(1, 1, 'testing framework is working');

#    Verify that basic data is correct
is(
	expected_text( rows => [ msgs() ] ),
	qq{Id,Msg\n1,"Msg #1\t"\n2,"Msg #2\t"\n3,"Msg #3\t"\n},
	"Basic data is correct"
);

#    Does the most minimal version work?
lives_ok {  new_sink() } "Can create a Copper::Sink::File::CSV with default settings";

#    Can we actually print some data?
test 'Basic Sink; CSV file with id, simple text message including spaces, embedded \n, and various kinds of numbers' => sub {
	my $sink = setup();
	
	my $expected_output =
		qq{Day,"Daily Average Sales"\n"Mon\n(first Mon of month)",1\nMon,1\nTue,0\nWeds,-1\nThurs,1.22\nFriday,-1.27\nSat,-0.2\nSun,0.7\n};

	my @input = (
		[ 'Day', q{Daily Average Sales} ],
		[ qq{Mon\n(first Mon of month)}, 1 ],
		[ 'Mon', 1 ],
		[ 'Tue', 0 ],
		[ 'Weds', -1 ],
		[ 'Thurs', 1.22 ],
		[ 'Friday', -1.27 ],
		[ 'Sat', -0.2 ],
		[ 'Sun', 0.7 ],
	);
	
	is(
		expected_text( rows => \@input ),
		$expected_output,
		"Text::CSV output is as expected"
	);

	$sink->drain( @input );
	$sink->finalize;
	
	match_and_teardown(
		$expected_output,
		'Basic Sink; CSV file with id, simple text message including spaces, embedded \n, and various kinds of numbers'
	);
};

done_testing();

###----------------------------------------------------------------
###----------------------------------------------------------------
###----------------------------------------------------------------

sub expected_text {
	my %args = (
		csv_args => {},
		@_
	);
	$args{csv_args} = {
		binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"',		
		%{ $args{csv_args} },
	};
	
	my $csv = $args{csv} || Text::CSV->new( $args{csv_args} ) or die "Could not create CSV object: $!";
	my $fh  = correct_file_fh();
	for (@{ $args{rows} }) {
		$csv->print( $fh, $_);
	}
	close_correct_file_fh();

	scalar slurp($filepath__expected);
}

###----------------------------------------------------------------

{
	my $fh;
	
	sub correct_file_fh {
		if ( ! $fh ) {
			open $fh, ">:encoding(utf8)", $filepath__expected or die "$filepath__expected: $!";
		}
		return $fh;
	}
	
	sub close_correct_file_fh {
		$fh->flush if $fh;
		undef $fh;
	}
}

sub new_csv {
	my $csv = Text::CSV->new(
		{ binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"', @_ }
	) or die "Could not create CSV object: $!";
}

sub setup {
	unlink $test_filepath;
	ok( ! -e $test_filepath, "Before test, file does not exist" );
	new_sink( @_ );
}

sub match_and_teardown {
	my ($expected, $msg) = @_;
	
 	ok( -e $test_filepath, "After test, file exists" );

 	is( scalar slurp($test_filepath), $expected, $msg );

 	unlink $test_filepath;
}

unlink $test_filepath;			#    Clean up
unlink $filepath__expected;		#    Clean up

sub new_sink {
 	Copper::Sink::File::CSV->new( filepath => $test_filepath, @_ );
}

sub msgs {
	return ( 
		[ qw/Id Msg/ ],
		map {
			[ $_,"Msg #$_\t" ]
		} 1..3
	);
}
