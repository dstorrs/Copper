package Copper::Sink::File;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

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
	writer => '_set_fh',
	isa => 'IO::File',
	lazy_build => 1,
);
sub _build__fh {
#	say "in File::_build__fh. args are @_";
	
	my $self = shift;
	my $val  = shift // '';

#	say "in File::_build__fh. val is $val";
	
	my $filepath = $self->filepath;
	$filepath = $filepath->( $self, $val ) if ref $filepath;

	my $mode = $self->mode;
	my $fh = IO::File->new($filepath, "${mode}:encoding(utf8)")
		or die "Could not open '" . $filepath . "': $!";

#	say "in File::_build__fh. fh is $fh";

	return $fh;
}

sub ensure_fh {
#	say "In File::ensure_fh.  args are @_";
	
	my $self = shift;
	my $val  = shift;

	my $is_ref = ref $self->filepath;

	# filepath is ref && fh NOT set  => rebuild fh 
	# filepath is ref && fh is set   => rebuild fh
	# filepath is NOT ref && fh NOT set rebuild fh
	# filepath is NOT ref && fh is set => do not rebuild

	if ( !($is_ref) && $self->_fh ) {
		#    Do nothing
#		say "In File::ensure_fh, doing nothing";
	}
	else {
#		say "In File::ensure_fh, rebuilding _fh";
		$self->_set_fh( $self->_build__fh( $val ) );
#		say "In File::ensure_fh, after rebuilding _fh";
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

	my $is_ref = ref $self->filepath;
	
	my $fh = $self->_fh;
	for ( @_ ) {
		print $fh $_;
	}
}

sub drain {
#	say "in File::drain, args are:  @_";
	
	my $self = shift;
	my @rest = @_;
	
	if ( $self->has_init ) {
		#    Do nothing -- init is assumed to have set up the filehandle
	}
	else {
		$self->ensure_fh(@rest);
	}

	@rest = $self->format->( @rest ) if $self->has_format;
	$self->_print( @rest );

	if ( ref $self->filepath ) { $self->_clear_fh };
	
	return;
}

sub finalize {
	my $self = shift;

	$self->_fh->flush;
}

sub DEMOLISH {
	my $self = shift;
	$self->finalize;
}

before 'apply_transform' => sub {
	my $self = shift;

	#    If there is an 'init', it is responsible for having init'd the _fh
#	say "in File::apply_transform; has_init, so will return without rebuilding" if $self->has_init; 
#	say "in File::apply_transform; has_init: ", $self->has_init, ", has_fh: ", $self->_has_fh;
	return if $self->has_init && $self->_has_fh;
	
	if ( $self->has_transform ) {
#		say "In File::apply_transform, about to call ensure_fh";		
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

1; # End of Copper::Sink::File
