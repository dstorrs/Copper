package Copper::Sink::STDOUT;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

our $VERSION = '0.01';


use Moose;

with 'Copper::Sink'; 

sub drain {
	my $self = shift;
	print @_;
	return;
}

1;

__END__

=head1 NAME

Copper::Sink::STDOUT 

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

A Copper::Sink with a drain() method that simply prints values to
STDOUT.

=head1 METHODS

=head2 drain

Print @_ to STDOUT.

=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Sink::STDOUT


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

1; # End of Copper::Sink::STDOUT
