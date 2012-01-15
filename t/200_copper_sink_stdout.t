#!/usr/bin/env perl 

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Test::Output;
use Data::Dumper;
use FindBin qw/$Bin/;

use lib "$Bin/../lib";

use Copper::Sink::STDOUT;

is(1, 1, 'testing framework is working');

lives_ok {  new_sink() } "Can create a Copper::Sink::STDOUT with default settings";

is( new_sink()->name, '*unnamed*', "Sinks have a default name" );
is( new_sink( name => 'foo_sink' )->name, 'foo_sink', "can set the name of the sink" );

stdout_is( sub { new_sink()->drain(msgs()) }, join('', msgs()), 'drain, str' );

stdout_is( sub { new_sink()->drain() }, '', 'drain, null str' );

stdout_like( sub { new_sink()->drain( {}, [] ) }, qr/((HASH|ARRAY)\(0x[\da-f]+\)){2}/, 'drain, hashref+arrayref' ); 
stdout_like( sub { new_sink()->drain( [], {} ) }, qr/((HASH|ARRAY)\(0x[\da-f]+\)){2}/, 'drain, arrayref+hashref' ); 


done_testing();

sub new_sink { Copper::Sink::STDOUT->new( @_ ) }
sub msgs {  map { "Msg #$_\t" } 1..10 }
