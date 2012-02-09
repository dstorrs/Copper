package Copper::Pipe;

use strict;
use warnings;
use feature ':5.10';

use Moose;

use Scalar::Util qw/blessed reftype looks_like_number/;
use List::Util  qw/first/;
use Data::Dumper;

use Copper;

with ('Copper::Role::HasTransform', 'Copper::Role::HasHooks');

our $VERSION = '0.01';


our @CARP_NOT = ('Moose::Object', 'Class::MOP::Method');


sub next {
#	say "in Pipe::next, args: @_";
	
	my $self = shift;

#	say "in Pipe::next, has_pre_hook: ", $self->has_pre_hook;
#	say "in Pipe::next, has_post_hook: ", $self->has_post_hook;
	
	my ( @results, @data );

	@data = map { $_->next } $self->all_sources;

#	say "in Pipe::next, after all_source->next.  data is: @data";
	
	if ( $self->pre_init_sinks ) {
#		say "in Pipe::next, has pre_init_sinks";
		
		for my $sink ( $self->all_sinks ) {
#			say "in Pipe::next, initing $sink";
			$sink->apply_init( $self, @data );
		}
#			say "in Pipe::next, inited all sinks";
	}
#			say "in Pipe::next, after pre_init_sinks.  data is @data";

	@data = map { $self->apply_transform($_) } @data;
#			say "in Pipe::next, after apply_transform.  data is @data";
	
	for my $sink ( $self->all_sinks ) {
#		say "in Pipe::next, before running drain.  current sink is: $sink, data is @data";
		push @results, $sink->drain( @data );
#		say "in Pipe::next, after running drain.  sink was: $sink, result is @results";
	}
#			say "in Pipe::next, exiting. results are @results";
	
	return @results;
}

sub finalize {
	my $self = shift;
	$_->finalize for $self->all_sinks;
}

has 'sources' => (
	traits             => ['Array'],
	isa                => 'ArrayRef[Copper::Source]',
	required           => 1,
	handles       => {
		all_sources    => 'elements',
		map_sources    => 'map',
		source_count   => 'count',

		_get_source    => 'get',
	},
);

has 'sinks' => (
	traits             => ['Array'],
	isa                => 'ArrayRef[Copper::Sink]',
	required           => 0,     # Filled in by BUILDARGS if not
	handles       => {
		all_sinks      => 'elements',
		add_sink       => 'push',
		map_sinks      => 'map',
		sink_count     => 'count',

		_get_sink      => 'get',
	},
);

has 'pre_init_sinks' => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

has 'filters' => (
	is => 'ro',
	isa => 'ArrayRef[Maybe[Copper::Part::Pipe::Filter]]',
	predicate => 'has_filters',
	default => sub { [] },
);

around 'BUILDARGS' => sub {
	my $orig    = shift;
	my $self    = shift;
	my %args    = @_;

	#    Allow either singular or plural
	$args{sources} ||= $args{source};
	$args{sinks  } ||= $args{sink} || { Return => {} };
	$args{filters} ||= $args{filter};

	#    Autobox attributes
	{
		no warnings 'uninitialized';
		for ( qw/sources sinks filters/ ) {
			$args{$_} = [ $args{$_} ] unless reftype $args{$_} eq 'ARRAY';
		}
	}

	%args = $self->_desugar_params( %args );
	
	return $self->$orig(%args);
};

###------------------------------------------------------------------------

sub _desugar_params {
	my $self = shift;
	my %args = @_;


	my $make_obj = sub {
		my ($hashref, $type) = @_;
		return $hashref if blessed $hashref;
		
		die "$hashref is not a hashref" unless reftype $hashref eq 'HASH';
		my ( $class, $params ) = %$hashref;
		$class =~ s/^Copper::(?:Source|Sink):://; # If it was there, cope
		$class = "Copper::${type}::$class";       # If it wasn't, add it
		$class->new( %$params );
	};

	for my $term ( qw/sources sinks/ ) {
		my $class = $term;
		chop $class;  #  "chop class" == txt-spk for "Cut sHOP class" :>
		$class = ucfirst $class;
		
 		given ( $args{$term}) {
			when ( blessed $_ ) {
				$args{$term} =  [ $_ ];
			}
			when ( ref $_ eq 'HASH'  ) {
				$args{$term} = [ $make_obj->( $_, $class ) ];
			}
			when ( ref $_ eq 'ARRAY' ) {
				$args{$term} = [ map { $make_obj->( $_, $class ) } @$_ ];
			}
			default {
				die "Invalid args for '$term'; must be either a hashref or an arrayref of hashrefs";
			}
 		}
 	}
	
	return %args;
}

__PACKAGE__->meta->make_immutable;

1;								# End of Copper::Pipe

__END__

=head1 NAME

Copper::Pipe

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    use Copper::Pipe;

    #    Generate two infinite sequences of integers, pipe them
    #    through a simple transformation function (squares them),
    #    arrange for them to be writen to disk and to STDOUT, and
    #    return them so that they can be further processed in-line.
    #
	my $pipe = Copper::Pipe->new(
		sources => [ Copper::Source::Ints->new( next_num => 7 ), Copper::Source::Ints->new( next_num => 2 ) ],
		sinks   => [ Copper::Sink::File->new(filepath => '/tmp/test'), Copper::Sink::STDOUT->new, Copper::Sink::Return->new ],
		transform => sub { shift() ** 2 }
	);
    my @data;
    @data = $pipe->next;  # @data = (49,4), and it was written to disk and to STDOUT
    @data = $pipe->next;  # @data = (64,9), and it was written to disk and to STDOUT
    ...

=head1 METHODS

=head2 next

Calls ->next on each of the elements of C<sources>, then sends the
results to ->drain for each of the C<sink>s in turn.

=cut

=head2 finalize

Optional method; if called, will be forwarded on to all the C<sink>s
so that they can (e.g.) flush filehandles, etc.

=cut


=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Pipe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Copper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Copper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Copper>

=item * Search CPAN

L<http://search.cpan.org/dist/Copper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David K. Storrs.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

