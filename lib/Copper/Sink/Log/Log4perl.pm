package Copper::Sink::Log::Log4perl;

use v5.10.1;
use strict;
use warnings;
use feature ':5.10';

use FindBin qw/$Bin/;
use Log::Log4perl;
use File::Basename qw/fileparse/;
use File::Spec;

use Moose;

with 'Copper::Sink'; 

sub drain {
	my $self = shift;
	return @_;
}

has 'conf_path' => (
	is => 'ro',
	isa => 'Str',
	default => sub { File::Spec->catfile( $Bin, qw/conf log4perl.conf/ ) },
);

sub log_filepath {	File::Spec->catfile( $Bin, qw/logfile.log/ ) }

has '_logger' => (
	is => 'ro',
	isa => 'Log::Log4perl::Logger',
	lazy_build => 1,
	handles => {
		log_trace => 'trace',
		log_debug => 'debug',
		log_info  => 'info',
		log_warn  => 'warn',
		log_error => 'error',
		log_fatal => 'fatal',
	},
);

sub _build__logger {
	my $self = shift;
	
	Log::Log4perl->init( $self->conf_path );

	my $logger = Log::Log4perl::get_logger();
	return $logger;
}

1;

__END__

=head1 NAME

Copper::Sink::Log::Log4perl

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

@@TODO

=head1 METHODS

=over 4

=item drain

@@TODO

=item log_filepath


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
