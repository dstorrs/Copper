package Copper::Pipe;

use strict;
use warnings;

our $VERSION = '0.01';


use Moose;

use Copper::Source;
use Copper::Sink::Return;
use Copper::Sink::STDOUT;

sub next {
	my $self = shift;

	my $transform = $self->transform;
	my @results;
	my @data;
	for my $source ( $self->all_sources ) {
		my $e = $source->next;
		push @data, $transform->( $e );
	}
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
		add_source     => 'push',
		map_sources    => 'map',
		source_count   => 'count',
	},
);

has 'sinks' => (
	traits             => ['Array'],
	isa                => 'ArrayRef[Copper::Sink]',
	required           => 0,
	handles       => {
		all_sinks      => 'elements',
		add_sink       => 'push',
		map_sinks      => 'map',
		sink_count     => 'count',
		#finalize       => 'apply' # Syntax?
	},
);
sub _build_sinks {
	my $self = shift;
	return [ Copper::Sink->new( sink => Copper::Sink::STDOUT->new ) ];
}

has 'transform' => (
	is => 'ro',
	isa => 'CodeRef',
	lazy_build => 1,
);
sub _build_transform { shift; return sub { @_ } }

around 'BUILDARGS' => sub {
	my $orig    = shift;
	my $self   = shift;
	my %args    = @_;

	#    Allow either singular or plural 
	$args{sources} ||= $args{source};
	$args{sinks  } ||= [ $args{sink} || Copper::Sink::Return->new ];
		
	#    Autobox sources and sinks
	{
		no warnings 'uninitialized';
		$args{sources} = [ $args{sources} ] unless ref $args{sources} eq 'ARRAY';
		$args{sinks  } = [ $args{sinks  } ] unless ref $args{sources} eq 'ARRAY';
	}
	@_ = %args;
	
	return $self->$orig(@_);
};

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

