package Copper::Sink::File;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';
use Carp qw/cluck/;

use Moose;
use IO::File;

with 'Copper::Sink', 'Copper::Role::HasTransform';

has 'filepath' => (
	is => 'rw',
	isa => 'Str|CodeRef',
	required => 1,
);

has 'mode' => (
	is => 'ro',
	isa => 'Str',
	lazy_build => 1,
);
sub _build_mode {
	my $self = shift;
	my $filepath = $self->filepath;
	return '>>' if ref $filepath;
	return '>';
}


has '_fh' => (
	is => 'ro',
	isa => 'IO::File',
	writer => '_set_fh',
	lazy_build => 1,
);
sub _build__fh {
	my $self = shift;
	my $val  = shift // '';
    my $all = shift // [];
	
	my $filepath = $self->filepath;
	$filepath = $filepath->( $self, $val, $all ) if ref $filepath;

	my $mode = $self->mode;
	my $fh = IO::File->new($filepath, "${mode}:encoding(utf8)")
		or die "Could not open '" . $filepath . "': $!";

	return $fh;
}

sub ensure_fh {
	my $self = shift;
	my $val  = shift;
	my $all  = shift;
	
	my $is_ref = ref $self->filepath;

	# 	 filepath is ref                    => rebuild fh
	# 	 filepath is NOT ref && fh NOT set  => rebuild fh
	# 	 filepath is NOT ref && fh is set   => do not rebuild
	#
	if ( !($is_ref) && $self->_has_fh ) {
		# Do nothing
	}
	else {
		$self->_set_fh( $self->_build__fh( $val, $all ) );
	}

	return $self->_fh;
}

has 'format' => (
	is => 'ro',
	isa => 'CodeRef',
	predicate => 'has_format',
	required => 0,
);

sub _print {
	my $self = shift;
	my @all = @_;
	
	my $is_ref = ref $self->filepath;

	for ( @all ) {
		$self->ensure_fh($_, \@all) if ! $self->has_init;
		my $fh = $self->_fh;

		print $fh $_;

		$self->_clear_fh
			if ( ref $self->filepath && $self->has_init );
	}

}

sub drain {
	my $self = shift;
	my @rest = @_;

	@rest = $self->format->( @rest ) if $self->has_format;

	$self->_print( @rest );

	return;
}

sub finalize {
	my $self = shift;
	$self->_fh->flush if $self->_has_fh;
}

sub DEMOLISH {
	my $self = shift;
	$self->finalize;
}

before 'apply_transform' => sub {
	my $self = shift;

	#  If there is an 'init', it is responsible for having init'd the _fh
	return if $self->has_init && $self->_has_fh;

	if ( $self->has_transform ) {
		$self->ensure_fh( @_ );
	}
};

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

REQUIRED attribute.  Where to write the file; can be either a string
or a coderef.  If it is a string, the fh will be created once, but if
it is a ref, the ref will be called once for every value that is sent
to drain().  There will be three arguments to each call; $self, the
value currently being printed, and a reference to all the args that
were passed to drain(), e.g.:

    $self->filepath->($self, $current_val, @all_vals)

filepath() should use $self->ensure_fh to set to fh.

=cut

=head2 drain

Prints its arguments to the file specified by $self->filepath.

=head2 format

OPTIONAL attribute.  If defined, this should should be a CODEREF.
Arguments will be passed through C<format()> before being sent to
C<drain()>; this is a convenient place to (e.g.) insert spaces /
commas / translate to JSON, etc.

=head2 ensure_fh

ARGS:  
Will create the file handle if it does not exist, or do nothing.  Handles the case where filepath() is a coderef.

=head2 finalize

Flushes the filehandle in order to guarantee that all output has gone
to disk.

=head2 DEMOLISH

Called by Moose when the object is destroyed.  Will call finalize()
for you.

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

		1;  End of Copper::Sink::File
