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

my $test_filepath = '/tmp/copper_sink_test' . time();
my $correct_file = "$test_filepath.correct";

my $fh = correct_file_fh();
my $csv = new_csv();
$csv->print($fh, $_) for msgs();
close_correct_file_fh();

is(1, 1, 'testing framework is working');

#    Verify that basic data is correct
is( scalar slurp($correct_file), qq{Id,Msg\n1,"Msg #1\t"\n2,"Msg #2\t"\n3,"Msg #3\t"\n}, "Basic data is correct" );


lives_ok {  new_sink() } "Can create a Copper::Sink::File::CSV with default settings";

test 'Basic Sink...CSV file with id and simple text message including spaces and tabs' => sub {
	my $sink = setup();
	
	$sink->drain( msgs() );
	$sink->finalize;

	match_and_teardown(
		qq{Id,Msg\n1,"Msg #1	"\n2,"Msg #2	"\n3,"Msg #3	"\n},
		'Basic Sink...CSV file with id and simple text message including spaces and tabs'
	);
};

done_testing();

###----------------------------------------------------------------
###----------------------------------------------------------------
###----------------------------------------------------------------

{
	my $fh;
	
	sub correct_file_fh {
		open $fh, ">:encoding(utf8)", $correct_file or die "$correct_file: $!";
		return $fh;
	}
	
	sub close_correct_file_fh {
		$fh->flush;
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

# file_contains(
# 	sub { new_sink() },
# 	"Msg #1\tMsg #2\tMsg #3\t",
# 	"Default case",
# );

# file_contains(
# 	sub {
# 		new_sink( format => sub { join("\n", @_) } )
# 	},
# 	"Msg #1\t\nMsg #2\t\nMsg #3\t",
# 	"Newlines after each line",
# );


unlink $test_filepath;			#    Clean up
unlink $correct_file;     		#    Clean up

sub new_sink {
 	Copper::Sink::File::CSV->new( filepath => $test_filepath, @_ );
}

# sub file_contains {
# 	my $func = shift;
# 	my $expected = shift;
# 	my $msg      = shift;

# 	test "contents match" => sub {
# 		unlink $test_filepath;
# 		ok( ! -e $test_filepath, "Before create, file does not exist" );
# 		my $sink = $func->();
# 		$sink->drain( msgs() );
# 		$sink->finalize;
# 		ok( -e $test_filepath, "After create, file exists" );
# 		is( scalar slurp($test_filepath), $expected, $msg );
# 		unlink $test_filepath;
# 	};
# }

sub msgs {
	return ( 
		[ qw/Id Msg/ ],
		map {
			[ $_,"Msg #$_\t" ]
		} 1..3
	);
}
