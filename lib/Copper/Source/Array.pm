package Copper::Source::Array;


use v5.10.1;
use strict;
use warnings;

our $VERSION = '0.01';


use Moose;

with 'Copper::Source';
use Copper::Source::Ints;

has '_curr_index' => (
	is => 'ro',
	isa => 'Copper::Source::Ints',
	default => sub { Copper::Source::Ints->new() }
);

has '_vals' => (
	traits => ['Array'],
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [] },
	handles => {
		_all_vals    => 'elements',
		_get_val     => 'get',
		_set_val     => 'set',
		_count_vals  => 'count',
		_has_vals    => 'count',
		_has_no_vals => 'is_empty',
	},		
);

around 'BUILDARGS' => sub {
 	my ($orig, $self, %args) = @_;

	die "No 'init' arg to Copper::Source::Array" unless $args{ init };
	die "'init' arg to Copper::Source::Array must be arrayref or coderef"
		unless ref $args{ init } && ref( $args{ init } ) =~ /^(ARRAY|CODE)$/;

	given ( ref $args{ init } ) {
		when ('ARRAY') {  $args{ _vals } = $args{ init }      }
		when ('CODE')  {  $args{ _vals } = $args{ init }->()  }
		default        {  die "Sanity check failed!"          } 
	}
	
 	$self->$orig( %args );
};

sub next {
	my $self = shift;
	my @res = $self->_get_val( $self->_curr_index->next );
	return wantarray ? @res : $res[0];
}

after 'next' => sub {
	my $self = shift;
	$self->_curr_index->reset_next_num		if $self->_curr_index->peek >= $self->_count_vals;
};

sub multi {
	my $self = shift;
	return ;
}

1;

__END__

=head1 NAME

Copper::Source

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Generates an infinite string of integers, counting up.

See the documentation of C<Copper::Source>, since this module was used
as the example there.

=head1 METHODS

=head2 default_multi

'rw' attribute.  Defines how many values will be returned by 'multi'.

=head2 next

Returns the next value in the sequence.

=head2 multi

Return the next C<$self->default_multi> values from the sequence.

=head2 multi_n(N)

Return the next N values from the sequence.  So,
$counter_1->multi_n(3) would return the next 3 values.

=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Source


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

1;							# End of Copper::Source
