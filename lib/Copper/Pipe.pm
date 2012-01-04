package Copper::Pipe;

use strict;
use warnings;

use Moose;

use Scalar::Util qw/reftype/;
use List::Util  qw/first/;

use Copper::Types;
use Copper::Source;
use Copper::Sink::Return;
use Copper::Sink::STDOUT;

our $VERSION = '0.01';


our @CARP_NOT = ('Moose::Object', 'Class::MOP::Method');


sub next {
	my $self = shift;

	my $transform = $self->transform;
	my @results;
	my @data;
	for my $source ( $self->all_sources ) {
		my $e = $source->next;
		push @data, $transform->( $e );
	}

	#  @@TODO: Move this inside the prior 'for' to avoid needing @data
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
	required           => 0,     # Filled in by BUILDARGS if not
	handles       => {
		all_sinks      => 'elements',
		add_sink       => 'push',
		map_sinks      => 'map',
		sink_count     => 'count',
	},
);

has 'transform' => (
	is => 'ro',
	isa => 'CodeRef',
	lazy_build => 1,
);
sub _build_transform { shift; return sub { @_ } }

has 'filters' => (
	is => 'ro',
	isa => 'Maybe[Copper:Filter:Struct]',
	required => 0,
	predicate => 'has_filters',
);

around 'BUILDARGS' => sub {
	my $orig    = shift;
	my $self   = shift;
	my %args    = @_;

	#    Allow either singular or plural
	$args{sources} ||= $args{source};
	$args{sinks  } ||= $args{sink} || Copper::Sink::Return->new;
	$args{filters} ||= $args{filter};

	#    Autobox sources and sinks
	{
		no warnings 'uninitialized';
		$args{sources} = [ $args{sources} ] unless reftype $args{sources} eq 'ARRAY';
		$args{sinks  } = [ $args{sinks  } ] unless reftype $args{sinks  } eq 'ARRAY';
	}

	@_ = %args;

	return $self->$orig(@_);
};

# sub BUILD {
# 	my $self = shift;

# 	$self->validate_filters_or_die();
# }

# sub validate_filters_or_die {
# 	my $self = shift;

# 	if ( $self->has_filters ) {
# 		no warnings 'uninitialized';

# 		my $filters = $self->filters;

# 		croak "Hashref for 'filters' attribute must have either 'pre' key, 'post' key, or both"
# 			unless (exists $filters->{pre}) || (exists $filters->{post});

# 		my ($pre, $post) = map { $filters->{$_} } qw/pre post/;

# 		croak "In 'filters' attribute, value of 'pre' key must be ArrayRef"
# 			unless (reftype $pre) =~ /ARRAY/;

# 		croak "In 'filters' attribute, if value of 'pre' key is ArrayRef, must be non-empty and all elements must be HashRef"
# 			if !@$pre || first { (! ref $_) || (reftype $_ ne 'HASH') } @$pre;

# 		croak "Each item in 'pre' filters must be hashref with at least these keys: 'code', 'action'"
# 			if first { ! (exists $_->{code} && exists $_->{action}) } @$pre;

# 		croak "The 'code' key of each filter value in filters->pre must be a coderef"
# 			if first { reftype $_->{code} ne 'CODE' } @$pre;		

# 		croak "The 'action' key of each filter value in filters->pre must be 'allow' | 'reject' | hashref"
# 			if first { ! /^(?:allow|reject)$/ && reftype $_->{action} ne 'HASH' } @$pre;		

# 		my @f = map { ref $_->{action} } @$filters;
# 		my $msg = "In filters, 'action' keys that are hashrefs must have exactly one key: 'allow' or 'reject'";
# 		for my $f (@f) {
# 			my @k = keys %$f;
# 			croak $msg if @f != 1;
# 			croak $msg if first { ! /^(?:allow|reject)$/ } @k;
# 		}
# 	}
# }

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

