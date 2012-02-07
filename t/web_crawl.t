#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

no warnings 'uninitialized';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;
use Carp qw/cluck/;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Copper::Source::LWP::UserAgent;
use Copper::Sink::File;
use Copper::Source::Ints;

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';	 # Verify that it gets loaded from base module
}
;

test "can download a file to disk" => sub {
	my @name = qw/lisanova nigahiga/;

	my $make_path = sub {
#		say "in make_path. args are: @_";
		#cluck "in make_path. longmess:  \n";
		
		my ($self, $val) = @_;
		$val =~ s/[ #]/_/g;
		my $res = lc "/tmp/$val";

#		say "in make_path, final result is $res";

		return $res;
	};

	for ( @name ) {
		unlink $make_path->( undef, $_ ) ;
		ok( ! -e $make_path->( undef, $_ ), $make_path->( undef, $_ ) . " (correctly) does not exist" )
	}

	my $pipe = Copper::Pipe->new(
		source => { Array => { init => [ @name ] } },

		pre_init_sinks => 1,
		
		sinks   => [
			{
				File => {
					filepath => $make_path,

					init => sub {
						my ($self, $pipe, @args) = @_;
#						say "IN FILE::init, self: $self, pipe: $pipe, args: @args";
						$self->ensure_fh( @args );
					},

					transform => sub {
#						say "In File::transform, args are: @_";
						shift;
						shift->decoded_content
					},
				},
			},
		],

		transform => sub {
			my ($self, $profile) = @_;

			state $ua = Copper::Source::LWP::UserAgent->new(
				url => 'placeholder',
				pre_hook => sub {
					my ($self, $val) = @_;
#					say "IN LWP::UA::transform, args are: @_";
					$self->url( join('', "http://gdata.youtube.com/feeds/api/users/", $val) )
				},
			);

			my $res = $ua->next($profile);

#			say "LWP::UA::transform returning $res";
			
			return $res;
		},
	);

	for ( @name ) {
#		say "in main. val is $_";
		$pipe->next;
		ok( -e $make_path->( $_ ), $make_path->( $_ ) . " exists" );
	}
};

done_testing();

__END__
