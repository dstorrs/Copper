#!/usr/bin/env perl

use common::sense;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Copper::Source::Ints;
use Copper::Sink::Log::Log4perl;
use Copper::Pipe;

chdir $Bin;

my @name = qw/home foo quux/;
my $pipe = Copper::Pipe->new(
	source => { Array => { init => [ @name ] } },

	transform => sub {
		my ($self, $username) = @_;
		state $ua = Copper::Source::LWP::UserAgent->new(
			url => 'placeholder',
			pre_hook => sub { my ($self, $val) = @_; $self->url( "http://localhost:7777/$val" )	},
		);
		return $ua->next($username);
	},
	sinks => [
		{
			File => {
				filepath => sub { "$Bin/" . $_[1] },
				init => sub { my ($self, $pipe, @args) = @_;            $self->ensure_fh( @args ) },
				transform => sub { my ($self, $http_response) = @_; 	$http_response->decoded_content	},
			},
		},
		{
			'Log::Log4perl' => {
				pre_hook => sub {
					my ($self, $res) = (shift, shift);
					$self->log_info(
						$res->is_success 
							? "Successfully retrieved: " . $res->request->uri
							: "Failed to retrieve: " . $res->request->uri . "; " . $res->status_line
				    );
				},
			},
		},
	],
);
$pipe->next for @name;

__END__

