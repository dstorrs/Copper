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


use DateTime;

chdir $Bin;

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';  # Verify that it gets loaded from base module
};

$Log::Log4perl::DateFormat::GMTIME = 1;

lives_ok { new_obj() } "Can create a new Copper::Sink::Log::Log4perl with default params";
isa_ok( new_obj(), 'Copper::Sink::Log::Log4perl' );

is( new_obj()->config_filepath, 'data/log4perl.conf', "got correct config_filepath" );
is( new_obj()->log_filepath, "$Bin/logfile.log",  "got correct default log_filepath" );

unlink new_obj()->log_filepath;
ok( ! -e new_obj()->log_filepath, "before testing starts, output file does NOT exist" );

new_obj()->log_trace( "trace test" );
new_obj()->log_debug( "debug test" );
new_obj()->log_info( "info test" );
new_obj()->log_warn( "warn test" );
new_obj()->log_error( "error test" );
new_obj()->log_fatal( "fatal test" );

(my $got = slurp(new_obj()->log_filepath)) =~ s/ln:\d+/ln:/g;
$got =~ s/^\n//;
is( $got, correct(),  "got correct log_filepath" );

# START - Add more tests here


done_testing();

sub new_obj {
	Copper::Sink::Log::Log4perl->new(
		config_filepath => 'data/log4perl.conf',
		@_,
	);
}

sub correct {
	my $correct = <<'EOT';
[yyyy/MM/dd hh:mm:ss ln:] trace test 
[yyyy/MM/dd hh:mm:ss ln:] debug test 
[yyyy/MM/dd hh:mm:ss ln:] info test 
[yyyy/MM/dd hh:mm:ss ln:] warn test 
[yyyy/MM/dd hh:mm:ss ln:] error test 
[yyyy/MM/dd hh:mm:ss ln:] fatal test 
EOT

	my $now = DateTime->now;
	my ($ymd, $hms) = ($now->ymd('/'), $now->hms);
	my $ts = "$ymd $hms";

	$correct =~ s<yyyy/MM/dd hh:mm:ss><$ts>g;
	$correct =~ s<ln:\d+><ln:>g;

	return $correct;
}

