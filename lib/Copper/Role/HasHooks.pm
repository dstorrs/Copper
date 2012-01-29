package Copper::Role::HasHooks;

use Moose::Role;

has 'pre_hook' => (
	is => 'ro',
	isa => 'Maybe[CodeRef]',
	predicate => 'has_pre_hook',
);

has 'post_hook' => (
	is => 'ro',
	isa => 'Maybe[CodeRef]',
	predicate => 'has_post_hook',
);

sub apply_pre_hook {
	my $self = shift;
	return @_ unless $self->has_pre_hook;
	$self->pre_hook->(@_);
}

sub apply_post_hook {
	my $self = shift;
	return @_ unless $self->has_post_hook;
	$self->post_hook->(@_);
}

1;

__END__

=head1 NAME

Copper::Role::HasHooks

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Copper::Role::HasHooks 

=head1 METHODS

=head2 pre_hook

Optional coderef Attribute.  That ref will be passed two values:
$self, and the $val to be manipulated.

=head2 post_hook

Optional coderef Attribute.  That ref will be passed two values:
$self, and the $val to be manipulated.

=head2 apply_pre_hook

Optional coderef Attribute.  That ref will be passed two values:
$self, and the $val to be manipulated.

=head2 apply_post_hook

Optional coderef Attribute.  That ref will be passed two values:
$self, and the $val to be manipulated.


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
