package Copper::Source::File;


use v5.10.1;
use strict;
use warnings;
use File::Slurp;

our $VERSION = '0.01';

use Moose;

with 'Copper::Source';

###-----------
#   @@TODO PULL ALL OF THIS OUT INTO A ROLE AND USE IT IN BOTH SOURCE::FILE AND SINK::FILE

has 'filepath' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has '_fh' => (
	is => 'ro',
	isa => 'IO::File',
	lazy_build => 1,
);
sub _build__fh {
	my $self = shift;
	my $fh = IO::File->new($self->filepath, "<:encoding(utf8)")
		or die "Could not open '" . $self->filepath . "': $!";
	return $fh;
}

###-----------

has 'chomp' => (
	is => 'rw',
	isa => 'Bool',
	default => sub { 1 },
);

has 'trim' => (
	is => 'rw',
	isa => 'Str',
	predicate => 'has_trim',
	default => sub { 'none' },
);

sub foobar { my $x = 7 }
around 'trim' => sub {
		foobar();

	my $orig = shift;
	my $self = shift;

	if ( @_ ) {
		die "Value for 'trim' must be 'none' (the default), 'pre', 'post', or 'both'"
			unless $_[0] =~ /none|pre|post|both/;
	}
	
	$self->$orig(@_);
};

sub _clean {
	my $self = shift;
	my $val = shift;

	chomp $val if $self->chomp;
	
	if ( $self->has_trim ) {
		given ( $self->trim ) {
			when ( 'none'  ) {
				my $x = 7;
			} #  Do nothing
			when ( 'pre'  ) {
				$val =~ s/^\s*//
			}
			when ( 'post' ) {
				$val =~ s/\s*$//
			}
			when ( 'both' ) {
				$val =~ s/^\s*//; $val =~ s/\s*$//;
			}
			default {
				die "Sanity check failed!";
			}
		}
	}

	return $val;
}

sub next {
	my $self = shift;
	$self->_clean( $self->_fh->getline() );
}

sub multi  {
	my $self = shift;
	return map { $self->_clean($_) } $self->_fh->getlines();
}

1;

__END__

=head1 NAME

Copper::Source

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Reads from a file and returns the data therein -- next() returns one
line, multi() returns all the lines.  Be careful about using multi()
on very large files!

=head1 METHODS

=head2 default_multi

'rw' attribute.  Defines how many values will be returned by 'multi'.

=head2 next

Returns the next line.

=head2 multi

Return the remaining lines in the file.

=head2 multi_n(N)

Return the next N lines from the file.  So, $file->multi_n(3) would
return the next 3 lines.

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
