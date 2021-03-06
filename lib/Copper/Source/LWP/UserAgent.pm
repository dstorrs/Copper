package Copper::Source::LWP::UserAgent;

use v5.10.1;
use strict;
use warnings;

our $VERSION = '0.01';

use Moose;
use LWP::UserAgent;

with 'Copper::Source';

has 'url' => (
	is => 'rw',
	isa => 'Str|CodeRef',
);

has '_ua' => (
	is => 'ro',
	isa => 'LWP::UserAgent',
	lazy_build => 1,
);
sub _build__ua { LWP::UserAgent->new }

sub next {
	my $self = shift;

	my $url = $self->url;
	$url = $url->( $self, @_ ) if ref $url;
	
	my (@res) =	$self->_ua->get( $url );
	return wantarray ? @res : $res[0];
}

sub multi    { shift->next }
sub multi_n  { shift->next }

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

Returns the next value in the sequence and advances the sequence.

=head2 peek

Returns the next value in the sequence without advancing.

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
