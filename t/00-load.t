#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Copper' ) || print "Bail out!\n";
    use_ok( 'Copper::Source' ) || print "Bail out!\n";
    use_ok( 'Copper::Pipe' ) || print "Bail out!\n";
    use_ok( 'Copper::Sink' ) || print "Bail out!\n";
    use_ok( 'Copper::Sink::STDOUT' ) || print "Bail out!\n";
}

diag( "Testing Copper $Copper::VERSION, Perl $], $^X" );
