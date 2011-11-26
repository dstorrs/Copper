package Copper::Sink::Return;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

use Moose;

with 'Copper::Sink'; 

sub drain {
	my $self = shift;
	return @_;
}

1;

__END__

=head1 NAME

Copper::Sink::Return

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Simply returns the values that are sent to it without alteration or
side-effects.  Useful for testing or if you want to connect the output
of the pipe to another pipe.

If you are going to use this at all, you usually want it to come last
in the list of 'sinks' in a pipe.

=head1 METHODS

=over 4

=item drain

Shift off $self, then return @_ unchanged.

=back

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
