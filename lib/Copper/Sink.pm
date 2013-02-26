package Copper::Sink;

use v5.10.1;
use strict;
use warnings;

our $VERSION = '0.01';

use Moose::Role;

with ( map { "Copper::Role::$_" } qw/Named HasTransform HasHooks/ );


requires 'drain';

around 'drain' => sub {
	my ($orig, $self, @vals) = @_;

	my @res = map {
			$self->apply_pre_hook( $_ );
			my @res = $self->apply_transform( $_ );
			$self->apply_post_hook( $_ );
			@res;
		} @vals;
	
	$self->$orig( @res );
};

has 'init' => (
	is => 'ro',
	isa => 'Maybe[CodeRef]',
	predicate => 'has_init',
	builder => '_build_init',
	lazy => 1,		
);
sub _build_init { sub {} }

sub apply_init {
	my $self = $_[0];
	$self->init->( @_ ) if $self->has_init;
} 

sub finalize {}  # Can be used to flush filehandles, etc

sub DEMOLISH {
	shift->finalize;
}

1;

__END__

=head1 NAME

Copper::Sink

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Copper::Sink is a Role which classes inherit from.  Such classes take
in values and send them somewhere else -- a disk file, a database,
STDOUT, etc.  See the specific classes for examples.

=head1 METHODS

=head2 apply_init

If $self has an init, it will be applied.  Otherwise, this is a
null-op.

=head2 drain

Takes an array of values, sends them on.

=head2 finalize

C<::Sink>s may redefine this to, e.g., flush output handles.

=head2 DEMOLISH

Calls $self->finalize.

=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Sink


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

1; # End of Copper::Sink
