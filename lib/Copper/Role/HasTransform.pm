package Copper::Role::HasTransform;

use Moose::Role;

has '_transform' => (
	is => 'ro',
	isa => 'Maybe[CodeRef]',
	predicate => 'has_transform',
	init_arg => 'transform',
);

sub apply_transform {
	my $self = shift;
	return $self->_transform->($self, @_) if $self->has_transform;
	return @_;
}

1;

__END__

=head1 NAME

Copper::Role::HasTransform

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Copper::Role::HasTransform is a simple role that provides the
'transform' method.  It is used by Copper::Pipe and Copper::Sink

=head1 METHODS

=head2 transform

Takes a coderef.  That ref will be passed two values: $self, and the
$val to be transformed.

=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Role::HasTransform


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
