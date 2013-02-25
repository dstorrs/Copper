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
	my $self = shift;

	my ( @results, @data );

	@data = map { $_->next } $self->all_sources;

	#    If the Pipe's 'pre_init_sinks => 1' attribute was set, ensure
	#    that all sinks have had their 'init' routine called (if they
	#    have one).  This is useful to do setup on the sink before the
	#    transform is called -- e.g., to ensure that a filehandle is
	#    instantiated or that the sink is set to a particular state
	#    which is calculated from the data that is about to be
	#    transformed.
	#
	if ( $self->pre_init_sinks ) {
		for my $sink ( $self->all_sinks ) {
			$sink->apply_init( $self, @data );
		}
	}

	@data = map { $self->apply_transform($_) } @data;
	
	for my $sink ( $self->all_sinks ) {
		push @results, $sink->drain( @data );
	}
	
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
	default => 1,
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

Optional method; if called, will be forwarded on to all the C<Sink>s
so that they can (e.g.) flush filehandles, etc.

=cut

=head2 sources

This is an arrayref of all the C<Copper::Source>s that this Pipe will
pull from.  The ordering of the Sources can be important, as data is
pulled from them in the same order that they appear in this arrayref,
and the order of that data is preserved as it flows through the Pipe.

Uses the Moose C<traits> class to act like a regular array.  cf
L<http://search.cpan.org/dist/Moose/lib/Moose/Meta/Attribute/Native/Trait/Array.pm>
for details.  Implemented methods are: all_sources, map_sources,
source_count.  See below for details.

=cut

=over 4

=item all_sources

Returns an array of the C<Copper::Source> objects used by this pipe.

=cut

=item map_sources

C<< $self->map_sources(sub {...}) >> is equivalent to C<map {...}
$self->all_sources> except it doesn't waste time returning an
intermediate list.

=cut

=item source_count

Returns the number of C<Copper::Sources> used by this Pipe.

=cut

=back

=head2 sinks

The complement of C<sources>, C<sinks> stores an arrayref of
C<Copper::Sink> objects which determine what happens to the output of
the Pipe.

Again, this uses Moose delegation to implement the following:

    #
    # Call this...    ...to do this:
    #
	all_sinks      => 'elements', # Returns list of all the Sinks
	add_sink       => 'push',
	map_sinks      => 'map',
	sink_count     => 'count',

=head2 pre_init_sinks

Boolean attribute.  Default: 0.  When set, the C<Pipe> works
(conceptually) as follows:

  @data = map { $_->next } $pipe->all_sinks;
  $_->init(@data) for $pipe->all_sinks;    # If pre-init_sinks is 0, this step is skipped
  @data = map { $pipe->apply_transform($_) } @data;
  ...
    
=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Pipe


You can also look for information at:

=over 4

=item * GitHub

L<http://github.com/dstorrs/Copper>

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

