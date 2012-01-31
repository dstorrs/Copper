package Copper::Source;


use v5.10.1;
use strict;
use warnings;

use Moose::Role;

with ('Copper::Role::Named', 'Copper::Role::HasHooks', 'Copper::Role::HasTransform');

our $VERSION = '0.01';


requires 'next';
requires 'multi';

has 'default_multi' => ( is => 'rw', isa => 'Int', lazy => 1, builder => '_build_default_multi' );
sub _build_default_multi { 100 }

around 'next' => sub {
	my ($orig, $self, @vals) = @_;

	$self->apply_pre_hook(  @vals );
	my @result = $self->$orig( @vals );
	@result = $self->apply_transform( @result );
	$self->apply_post_hook( @vals );
	return @result;
};

sub multi_n  {
	my $self = shift;
	my $n    = shift;
	
	my @results;
	do { push @results, $self->next } for 1..$n;
	return @results;
}

1;

__END__

=head1 NAME

Copper::Source 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Generates data which can be manipulated directly from Perl code or
plugged into a Copper::Pipe.  ::Source is actually a Role, so the
following example is based on the ::Source::Ints subclass.

    use Copper::Source::Ints;

    my $positives = Copper::Source::Ints->new( next_num => 1 );

    @data = $positives->next;          # 1
    @data = $positives->next;          # 2
    @data = $positives->next;          # 3
    @data = $positives->multi_n(6);    # (4..9)
    @data = $positives->multi;         # (10..109)  ; By default, 'Ints::multi' returns 100 values

    $positives->default_multi(2)       #   From 
    @data = $positives->multi;         # (110,111)

=head1 DESCRIPTION

Sources are iterators.  Copper::Source itself is a Role which defines
a three-method interface: next, multi_n, and multi.  These generate
(respectively) one value, N values, and "all" values -- but, since
some sources produce an infinite number of values, a Source is free to
redefine 'all' to mean 'as many values as specified by the
'default_multi' attribute.


=head1 REQUIRES

=head2 next

Should return a single value (although this is not enforced).

=cut


=head2 multi_n(N)  # e.g. $obj->multi_n(7)

Returns N values.

=cut


=head2 default_multi

If a particular Source iterates across an infinite sequence, then
C<multi()> cannot return all values.  The C<default_multi> attribute
can be used to specify how many values C<multi()> should return.

=cut


=head2 multi

Should return all values left in the sequence or, if that is not
possible, the number of values specified by C<default_multi>.

=cut

=head2 pre_hook, post_hook, transform

These optional attributes each take a coderef and run it at various
times in the processing cycle.  Each coderef will be passed two
arguments -- $self, and the value that is currently being processed.
C<pre_hook> receives the values before they are sent to C<next> /
C<multi> / C<multi_n>.  C<post_hook> receives the values afterwards.
Both of the '*_hook' refs are called in isolation and are intended to
be used for their side effects; their return value is ignored.
C<transform>, on the other hand, will actually modify the value that
is returned from the source, meaning that the sinks will receive a
different value than was originally sent.

Note that these are similar to, but distinct from, Moose method
modifiers and it is possible to use these in conjunction with Moose's
C<before>, C<after>, and C<around> modifiers.  These hooks are
intended to make it easy to provide modifiers for a single object.


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

1; # End of Copper::Source
