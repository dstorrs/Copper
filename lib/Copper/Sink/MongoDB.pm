package Copper::Sink::MongoDB;

use Moose;

with 'Copper::Sink';

use MongoDB;

sub drain {
	my $self = shift;

	$self
}

has 'config' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { +{ host => 'localhost', port => 27017, db => 'copper' } },
);

around 'config' => sub {
	my ($orig, $self, $args) = @_;

	if ( $args ) { 
		$args->{host} //= 'localhost';
		$args->{port} //= 27017;
		$args->{db  } //= 'copper';
	}
	
	$self->$orig( $args ) if $args;
	$self->$orig;
};

has 'db' => (
	is  => 'ro',
	isa => 'MongoDB::Database',
	lazy_build => 1,
	builder => '_build_db',
);

sub _build_db {
	my $self = shift;

	my $db_name    = $self->config->{db};
	
	my $database   = $self->_connection->$db_name;
}

around 'BUILDARGS' => sub {
	my $orig = shift;
	my $self = shift;
	my %args = @_;

	if ( $args{config} ) {
		$args{config}->{host} //= 'localhost';
		$args{config}->{port} //= 27017;
		$args{config}->{db  } //= 'copper';
		$args{config}->{col_name} //= 'col';
	}
	
	$self->$orig( %args );
};

has '_connection' => (
	is  => 'ro',
	isa => 'MongoDB::Connection',
	lazy_build => 1,
	builder => '_build__connection',
);

sub _build__connection {
	my $self = shift;
	my %args = %{ $self->config };

	delete $args{db};
	delete $args{col_name};

	#
	#    Support args shown on
	#    http://search.cpan.org/~kristina/MongoDB-0.45/lib/MongoDB/Connection.pm
	#    This includes 'w' (how many servers to replicate to before
	#    considering it a 'safe' write), wtimeout (how long to wait
	#    for replication), username, password, etc.
	#
	my $connection = MongoDB::Connection->new( %args );
}

1;

__END__

=head2 config

Takes a hashref.  Keys should be:

    host  => default: localhost
    port  => default: 27017
    db    => default: copper
    col_name => default: col

    Additionally, all of the attributes listed in
    L<MongoDB::Connection> (e.g. w, wtimeout, auto_reconnect...) are
    supported.

=cut

