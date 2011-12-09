package Copper::Sink::File::CSV;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

use Moose;
use IO::File;
use Text::CSV;

extends 'Copper::Sink::File';

has 'csv' => (
	is => 'rw',
	isa => 'Text::CSV',
	lazy_build => 1,
);
sub _build_csv {
	my $self = shift;
	
	my $csv = Text::CSV->new(
		{ binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"' }
	) or die "Could not create CSV object: $!";
	
}

sub drain {
	my $self = shift;
	my @rows = @_;

	my $csv = $self->csv;
	my $fh  = $self->_fh;
	
	for my $row ( @rows ) {
		if ( $self->has_format ) {
			$csv->print( $fh, $self->format->( $row ) );
		}
		else {
			$csv->print( $fh, $row );
		}
	}
	
	return;
}

sub finalize {
	my $self = shift;

	$self->_fh->flush;
}

1;

__END__

=head1 NAME

Copper::Sink::File

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

A very simplistic proof-of-concept for writing files via Copper.  Does
not support append mode, or any sort of options on the filehandle --
it is always :utf8 and mode is '>'.

=head1 METHODS

=head2 filepath

REQUIRED attribute.  Where to write the file.  

=cut

=head2 drain

Prints its arguments to the file specified by $self->filepath.

=head2 format

OPTIONAL attribute.  If defined, this should should be a CODEREF.
Arguments will be passed through C<format()> before being sent to
C<drain()>; this is a convenient place to (e.g.) insert spaces /
commas / translate to JSON, etc.

=head2 finalize

Flushes the filehandle in order to guarantee that all output has gone
to disk.


=cut

=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Sink::File


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

1; # End of Copper::Sink::File
