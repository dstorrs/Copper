package Copper::Part::Pipe::Filter;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';
use Data::Dumper;

our $VERSION = '0.01';

use Carp;
use Moose;
use Scalar::Util qw/reftype/;

our @CARP_NOT = ('Moose::Object', 'Class::MOP::Method' );

sub _filter_policies { qw(allow reject) }

sub _filter_policies_match {
	state $opts = join('|', _filter_policies());
	state $re = qr/^(?:$opts)$/i;
	return shift() =~ $re;
}

has 'name' => (
	is => 'ro',
	isa => 'Str',		   #  Will be set by BUILDARGS if not provided
	default => sub { '*unknown*' },
);

has 'code' => (
	is => 'ro',
	isa => 'CodeRef'
);

has 'when' => (
	is => 'ro',
	isa => 'Str',
);

has 'policy' => (
	is => 'ro',
	isa => 'Str | HashRef[ArrayRef]',
	default => sub { 'reject' },
);

sub apply_to {
	my $self = shift;

	state $policy_is_accept = $self->policy eq 'accept';
	state $result = sub {
		my $val = shift;
		my $res = $self->code->($val);
		return $val if $policy_is_accept && $res;
		return $val if ( ! $policy_is_accept ) && ( ! $res );
		return;
	};

	return map { $result->($_) } @_;
}

around 'BUILDARGS' => sub {
	my $orig = shift;
	my $self = shift;

	my %args = @_;

	no warnings 'uninitialized';

	croak "No 'when' key provided to filter" unless $args{when};
	croak "'when' key must be 'pre' or 'post'"	 unless $args{when} =~ qw/^(pre|post)$/;

	if ( $args{policy} ) {
		my $policy = $args{policy};
		my $legal_vals = join('|', _filter_policies());
		my $msg = "'policy' must be single-key hashref (with key =~ $legal_vals), or string =~ $legal_vals";
		
		if ( ref $policy ) {
			croak $msg 	unless ( ref $policy eq 'HASH' );
			croak $msg 	unless ( keys %$policy == 1 && _filter_policies_match( keys %$policy ) );
		}
		else {
			croak $msg unless _filter_policies_match( $args{policy} );
		}
	}

	return $self->$orig( @_ );	
};

1;

__END__

=head1 NAME

Copper::Part::Pipe::Filter;

=head1 VERSION

Version 0.01

=cut


=head1 DESCRIPTION

Copper::Part::Pipe::Filter defines a filter for use in a Copper::Pipe.

       #    Minimal filter: runs pre- or post-transform, allows / rejects each value to all sinks if code returns true
       Copper::Part::Pipe::Filter->new(
           when => pre | post,
           policy => allow | reject,
           code => sub { ... }
       )

       #    Filter that applies only to certain sinks
       Copper::Part::Pipe::Filter->new(
           when => pre | post,
           policy => { allow | reject => [qw/sink_name1 sink_name2 .../] },
           code => sub { ... },
       )

       #    Filters can have names for easier reference:
       Copper::Part::Pipe::Filter->new(
           name => 'my_filter',
           when => pre | post,
           policy => ...
           code => ...
       )



=head1 METHODS

=over 4

=item apply_to

Apply the filter to a set of values.

=back


=head1 AUTHOR

David K. Storrs, C<< <david.storrs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-copper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Copper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Copper::Part::Pipe::Filter


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

1;								# End of Copper::Part::Pipe::Filter
