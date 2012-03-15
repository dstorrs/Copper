package Copper::Manual::Intro;

1;

__END__

=head1 OVERVIEW

Most programming consists of pulling a set of values from X and
pushing them to Y, possibly applying some kind of transformation along
the way.  A lot of this code is boilerplate -- e.g. create your input
(filehandle / DB handle / integer generator / etc), write a loop to
process the (lines of text / rows of data / numbers / etc) that come
from it, write your output to a separate filehandle, etc.  Copper is a
toolkit for abstracting as much of this work as possible.

=head1 COPPER PARTS 

There are three main pieces to Copper: Sources, Sinks, and Pipes.
Sources pull data from various places, Sinks write it to various
places, and Pipes connect one or more Sources with one or more Sinks.
Transforms, filters, and pre- and post-hooks allow you to control
exactly how data flowing through these parts is modified and when.

=head1 EXAMPLES

    #    Create some simple Sources
    #
    my $names   = Copper::Source::Array->new( init => [ qw/joe bob tom/ ] );
    print $names->next; #  joe
    print $names->next; #  bob
    print $names->next; #  tom
    print $names->next; #  undef
    print $names->next; #  joe  ...etc

    my $logfile = Copper::Source::File->new(  filepath => '/var/log/apache2/access.log' );
    $logfile->next;     #  first line of access.log
    $logfile->next;     #  second line of access.log...etc

    my $logfile = Copper::Source::File->new(  filepath => '/var/log/apache2/access.log' );
    $logfile->next;     #  first line of access.log
    $logfile->next;     #  second line of access.log...etc

    #  
    #    A simple webcrawler that pulls data from the YouTube API.  You feed it an array of names (e.g. 'redbull, lisanova, raywilliamjohnson'); it downloads the profile feed for each of those users, writes the feed to disk, and logs whether or not it was successful.
    #    given an array of channel names.  You feed 
    #  
	my $pipe = Copper::Pipe->new(
		source => { Array => { init => [ @name ] } },

		pre_init_sinks => 1,

		sinks   => [
            #    Write each feed to a particular file
			{
				File => {
					filepath => sub {                   # LisaNova's profile gets saved in '/tmp/lisanova' 
                        my ($self, $val) = @_;          # Could also use a string here (not a subref) but then it
                		$val =~ s/[ #]/_/g;             # would be overwritten with each new value through the pipe 
                		lc "/tmp/$val";
                	},

					init => sub {                       # Recalculate the filepath for each new value
						my ($self, $pipe, @args) = @_;
						$self->ensure_fh( @args );
					},

					transform => sub {                  # Write the content of the response, not "HTTP::Response(0xdeadbeef)"
						my ($self, $res) = @_;          # NB:  Transforms change the value seen by later sinks.  
						$res->decoded_content           # This transform is applied only when a value reaches this sink
					},
				},
			},

            #    Log the results of the write
			{
				'Log::Log4perl' => {                    
					config_filepath => 'data/log4perl.conf',

					pre_hook => sub {                       #  Again, hooks do not change the value seen by later sinks.
						my ($self, $res) = (shift, shift);

						my $uri = $res->request->uri;
						if ( $res->is_success ) { $self->log_info("Successfully retrieved: $uri")	                }
						else                    { $self->log_info("Failed to retrieve: $uri : ", $res->status_line)	}
					},
				},
			},
		],

        #    This transform is applied to all values going through the pipe, after all
        #    sources have spat out their next value but before anything is sent to the sinks.
		transform => sub {                              
			my ($self, $profile) = @_;                  

            #    Create a static LWP::UA object to be used on each pass
			state $ua = Copper::Source::LWP::UserAgent->new(
				url => 'placeholder',
				pre_hook => sub {
					my ($self, $val) = @_;
					$self->url( join('', "http://gdata.youtube.com/feeds/api/users/", $val) )
				},
			);

			return $ua->next($profile);
		},
	);

=cut

