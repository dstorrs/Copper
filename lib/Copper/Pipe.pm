package Copper::Pipe;

use strict;
use warnings;
use feature ':5.10';

use Moose;

#use Scalar::Util qw/reftype blessed/;
use Scalar::Util qw/reftype/;
use List::Util  qw/first/;

use Copper::Part::Pipe::Filter;
use Copper::Types;
use Copper::Source;
use Copper::Source::File;
use Copper::Sink::Return;
use Copper::Sink::STDOUT;

our $VERSION = '0.01';


our @CARP_NOT = ('Moose::Object', 'Class::MOP::Method');


sub next {
	my $self = shift;

	my @results;
	my @data = map { $_->next } $self->all_sources;
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
	},
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
	$args{sinks  } ||= $args{sink} || Copper::Sink::Return->new;
	$args{filters} ||= $args{filter};

	%args = $self->_desugar_params( %args );
	
	#    Autobox attributes
	{
		no warnings 'uninitialized';
		for ( qw/sources sinks filters/ ) {
			$args{$_} = [ $args{$_} ] unless reftype $args{$_} eq 'ARRAY';
		}
	}

	return $self->$orig(%args);
};

###------------------------------------------------------------------------

sub _desugar_params {
	my $self = shift;
	my %args = @_;


	my $make_source = sub {
		my ( $class, $params ) = %{$_[0]};
		$class = "Copper::$_[1]::$class";
		$class->new( %$params );
	};

	for my $term ( qw/sources sinks/ ) {
		my $class = $term;
		chop $class;  #  Txt-spk for "cutting shop class" :>
		$class = ucfirst $class;
		
		given ( $args{$term}) {
			when ( ref $_ eq 'HASH'  ) {
				$args{$term} = [ $make_source->( $_, $class ) ];
			}
			when ( ref $_ eq 'ARRAY' ) {
				$args{$term} = [ map { $make_source->( $_, $class ) } @$_ ];
			}
			default {
				die "Invalid args for '$term'; must be either a hashref or an arrayref of hashrefs";
			}
		}
	}

# 	given ( $args{logger} ) {
# 		when ( blessed $_       ) { }  # All good, do nothing
# 		when ( ref $_ eq 'HASH' ) {
# 			my ($name, $watch, $conf_filepath) = map { $args{$_} } qw/name watch conf_filepath/;
			
# 			my $init_func = 'Log::Log4perl::' . $watch ? 'init_and_watch' : 'init';
# 			{
# 				no warnings;
# 				$init_func->($conf_filepath);
# 			}
# 			$args{logger} = Log::Log4Perl->get_logger( $name );
# 		}
# 		default {
# 			die "Invalid arg in 'logger'; must be either a Log::Log4perl object or a hashref.  Got: $args{logger}";
# 		}
# 	}
	
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

