package Copper::Sink::File::CSV;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

use Moose;
use IO::File;
use Text::CSV;

extends 'Copper::Sink::File';

has 'csv' => (
	is => 'rw',
	isa => 'Text::CSV',
	lazy_build => 1,
);
sub _build_csv {
	my $self = shift;

	my $csv = Text::CSV->new({ %{_default_csv_args()}, %{$self->csv_args} })
		or die "Could not create CSV object: $!";
}

has 'csv_args' => (
	is   => 'ro',
	isa  => 'Maybe[HashRef]',
	required => 0,
	lazy_build => 1,
);
sub _build_csv_args { shift->_default_csv_args } # This exists only to be a hook

sub _default_csv_args {
	+{
		binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"'
	}
}

around 'drain' => sub {
	my $orig = shift;
	my $self = shift;
	my @lines = @_;

	my $csv = $self->csv;

	my $prep = sub {
		$csv->combine( @{ shift() } );
		return $csv->string();
	};

	$self->$orig( map { $prep->($_) } @lines );
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

A sink for writing CSV files via Copper.

    #    Some simply financials...
    my $sink;
    my @rows = (
        [ qw/Id Date        Amount    Category/,      'Transaction Notes' ],
        [ qw/1  2011-12-10  $25.23    Food/,          'Groceries' ],
        [ qw/2  2011-12-12  $19.08    Food/,          'Dinner at "Mediteranee"' ],
        [ qw/3  2011-12-12  $4.67     Indulgence/,    'Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)' ],
    );
    sub write_rows {
        my $sink = shift;
        $sink->drain( @rows );
        $sink->finalize;  #  Or just let the $sink go out of scope
    }

    #    This...
    $sink = Copper::Sink::File::CSV->new( filepath => '/tmp/some_file.csv' );
    write_rows( $sink );

    #    ...clobbers /tmp/some_file.csv and outputs the following to that file:
    Id,Date,Amount,Category,"Transaction Notes" 
    1,2011-12-10,$25.23,Food,Groceries 
    2,2011-12-12,$19.08,Food,"Dinner at ""Mediteranee"" 
    3,2011-12-12,$4.67,Indulgence,"Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)" 

    #    This...
    $sink = Copper::Sink::File::CSV->new( filepath => '/tmp/some_file.csv', csv_args => {sep_char => "\t"} );
    write_rows( $sink );
    
    #    ...clobbers /tmp/some_file.csv and outputs the following to that file:
    Id Date        Amount    Category        "Transaction Notes" 
    1  2011-12-10  $25.23    Food            Groceries 
    2  2011-12-12  $19.08    Food            "Dinner at ""Mediteranee"" 
    3  2011-12-12  $4.67     Indulgence      "Coffee @ 4-Barrel Coffee (GOTTA cut back, but mmmm!)" 
    
    

=head1 DESCRIPTION

Uses Text::CSV under the hood, to actually write the files.  The
default arguments for creating the object are:

    {
		binary => 1, sep_char => ",", escape_char => '"', eol => "\n", quote_char => '"'
	}

You can supply your own arguments via the csv_args() attribute; these
will be merged with the defaults in simple overwrite fashion
(i.e. anything you supply takes precedence, anything you don't supply
uses the default).


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
