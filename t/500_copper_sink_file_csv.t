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

test "csv() works" => sub {
	my $csv;
	isa_ok( csv(), 'Text::CSV' );

	$csv = csv(	binary => 0, sep_char => ":", escape_char => 'X', eol => "\t", quote_char => "'" );
	isa_ok( $csv, 'Text::CSV' );
	is( $csv->binary,      0,     "csv->binary      != 0" );
	is( $csv->sep_char,    ':',   "csv->sep_char    != :" );
	is( $csv->escape_char, 'X',   "csv->escape_char != X" );
	is( $csv->eol,         "\t",  "csv->eol         != tab" );
	is( $csv->quote_char,  "'",   "csv->quote_char  != '" );
};

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

test 'Sink with specified CSV obj' => sub {
	my $csv_args = { eol => "\n\n", sep_char => "\t" };
	
	my $sink = setup( csv => csv( %$csv_args ) );
	
	my $expected_output =
		qq{Day\t"Daily Average Sales"\n\n"Mon\n(first Mon of month)"\t1\n\nMon\t1\n\nTue\t0\n\nWeds\t-1\n\nThurs\t1.22\n\nFriday\t-1.27\n\nSat\t-0.2\n\nSun\t0.7\n\n};

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
		expected_text( rows => \@input, csv_args => $csv_args ),
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

test 'Verify that csv_args() works' => sub {

	eval { new_sink( csv_args => { sep_char => 'X', } )->drain( msgs() ) };
	match_and_teardown(
		join(   "\n",
				qq{IdXMsg},
				qq{1X"Msg #1\t"},
				qq{2X"Msg #2\t"},
				qq{3X"Msg #3\t"},
			) . "\n",
		"spec'd csv_args in chained call"
	);
};

test "verify examples from POD" => sub {
    my $sink;
    my @rows = (
        [ qw/Id Date        Amount    Category/,      'Transaction Notes' ],
        [ qw/1  2011-12-10  $25.23    Food/,          'Groceries' ],
        [ qw/2  2011-12-12  $19.08    Food/,          'Dinner at "Mediteranee"' ],
        [ qw/3  2011-12-12  $4.67     Indulgence/,    'Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)' ],
    );
    my $check_rows = sub {
        my $sink = shift;
		my $msg = shift;
		my $expected = shift;
		
        $sink->drain( @rows );
        $sink->finalize;  #  Or just let the $sink go out of scope
		
		my $filepath = $sink->filepath;
		ok( -e $filepath && -f _, "file exists and is regular file" );
		is( slurp($filepath), $expected, $msg );
    };

	my $expected;
    $check_rows->(
		Copper::Sink::File::CSV->new( filepath => '/tmp/some_file.csv' ),
		"embedded quotes work",
		q{Id,Date,Amount,Category,"Transaction Notes"
1,2011-12-10,$25.23,Food,Groceries
2,2011-12-12,$19.08,Food,"Dinner at ""Mediteranee"""
3,2011-12-12,$4.67,Indulgence,"Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)"
},
	);

    #    This...
    $check_rows->( 
		Copper::Sink::File::CSV->new( filepath => '/tmp/some_file.csv', csv_args => {sep_char => "\t"} ),
		"punctuation and such, no issues",
		$expected = qq{Id\tDate\tAmount\tCategory\t"Transaction Notes"
1\t2011-12-10\t\$25.23\tFood\tGroceries
2\t2011-12-12\t\$19.08\tFood\t"Dinner at ""Mediteranee"""
3\t2011-12-12\t\$4.67\tIndulgence\t"Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)"
},
	);
};

done_testing();

###----------------------------------------------------------------
###----------------------------------------------------------------
###----------------------------------------------------------------

sub csv {
	my %args = (
		binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"',		
		@_
	);

	return Text::CSV->new( \%args ) or die "Could not create CSV object: $!";	
}

###----------------------------------------------------------------

sub expected_text {
	my %args = ( csv_args => {}, @_ );
	
	my $csv = csv( %{$args{csv_args}} );
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

sub setup {
	unlink $test_filepath;
	ok( ! -e $test_filepath, "Before test, file does not exist" );
	new_sink( @_ );
}

sub match_and_teardown {
	my ($expected, $msg) = (shift, shift);
	my $filepath = shift || $test_filepath;
	
 	ok( -e $filepath, "After test, file exists" );

 	is( scalar slurp($filepath), $expected, $msg );

 	unlink $filepath;
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
