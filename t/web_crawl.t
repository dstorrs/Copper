#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

no warnings 'uninitialized';

use Test::More;
use Test::Exception;
use Test::Group;
use Data::Dumper;

use File::Slurp qw/slurp/;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Copper::Source::LWP::UserAgent;
use Copper::Source::Ints;
use Copper::Sink::File;
use Copper::Sink::Log::Log4perl;

chdir $Bin;

BEGIN {
	is(1, 1, 'testing framework is working');
	use_ok 'Copper';	 # Verify that it gets loaded from base module
}
;

test "can download a file to disk" => sub {
	my @name = qw/lisanova nigahiga/;

	my $make_path = sub {
		my ($self, $val) = @_;
		$val =~ s/[ #]/_/g;
		my $res = lc "/tmp/$val";
		return $res;
	};

	for ( @name ) {
		unlink $make_path->( undef, $_ ) ;
		ok( ! -e $make_path->( undef, $_ ), $make_path->( undef, $_ ) . " (correctly) does not exist" )
	}
	my $log_filepath = "./logfile.log";
	unlink $log_filepath;
	ok( ! -e $log_filepath, "logfile does NOT exist" );

	my $pipe = Copper::Pipe->new(
		source => { Array => { init => [ @name ] } },

		pre_init_sinks => 1,

		sinks   => [
			{
				File => {
					filepath => $make_path,

					init => sub {
						#						say "in File::init. args are @_";

						my ($self, $pipe, @args) = @_;
						$self->ensure_fh( @args );
					},

					transform => sub {
						#						say "in File::init. args are @_";
						my ($self, $res) = @_;
						$res->decoded_content
					},
				},
			},
			{
				'Log::Log4perl' => {
					config_filepath => 'data/log4perl.conf',

					pre_hook => sub {
						#						say "in 'Log::Log4perl'::pre_hook. args are: @_";

						my $self = shift;
						my $res = shift;

						#						say "DEBUGGING about to get Log::Log4perl::log_filepath";
						# 						say "Log::Log4perl log_filepath is: ", Copper::Sink::Log::Log4perl::log_filepath;
						# 						say "DEBUGGING got Log::Log4perl::log_filepath";

						given ( $res ) {
							when ( $_->is_success ) {
								#						say "in 'Log::Log4perl'::pre_hook. about to log success";
								$self->log_info("Successfully retrieved: ", $res->request->uri);
								#						say "in 'Log::Log4perl'::pre_hook. just logged success";
							}
							default {
								#						say "in 'Log::Log4perl'::pre_hook. about to log failure";
								$self->log_info("Failed to retrieve: ", $res->request->uri, "; ", $self->status_line);
								#						say "in 'Log::Log4perl'::pre_hook. just  logged failure";
							}
						}
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
					$self->url( join('', "http://gdata.youtube.com/feeds/api/users/", $val) )
				},
			);

			my $res = $ua->next($profile);
			#					say "IN LWP::UA::transform, args are: @_";
			#			say "LWP::UA::transform returning $res";

			return $res;
		},
	);

	for ( @name ) {
		#		say "in main. val is $_";
		$pipe->next;
		ok( -e $make_path->( undef, $_ ), $make_path->( undef, $_ ) . " exists" );
	}

	ok( -e $log_filepath, "$log_filepath exists" );
	my $data = slurp( $log_filepath );
	like( $data, qr<Successfully retrieved: http://gdata.youtube.com/feeds/api/users/lisanova>, "logged lisanova" );
	like( $data, qr<Successfully retrieved: http://gdata.youtube.com/feeds/api/users/nigahiga>, "logged nigahiga" );
};

done_testing();

__END__
