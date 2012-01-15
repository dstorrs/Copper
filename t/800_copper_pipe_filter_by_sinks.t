#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Copper::Pipe;
use Copper::Source::Ints;

is(1, 1, 'testing framework is working');
is( new_ints(5)->next, 5, "new_ints(8)->next is 5" );
is( new_ints(8)->next, 8, "new_ints(8)->next is 8" );

my $p = new_pipe();
is_deeply(
	[ new_pipe()->next() ],
	[ "first => 2", "first => 10", "second => 2", "second => 10" ],
	"values come to sinks as expected"
);

		   
done_testing();

sub new_pipe {
	my %args = @_;

	my $trans = sub {
		my ($self, $val) = @_;
		$self->name . " => $val"
	};
	
	$args{sources} ||= [ 2, 10 ];
	$args{sinks  } ||= [
		Copper::Sink::Return->new(	name => 'first'	 , transform => $trans ),
		Copper::Sink::Return->new(	name => 'second' , transform => $trans ),
	];
	
	Copper::Pipe->new(
		sources => [ map { new_ints($_) } @{$args{sources}} ],
		sinks   => $args{sinks},
	);
}

sub new_ints { Copper::Source::Ints->new( next_num => @_ ) }
