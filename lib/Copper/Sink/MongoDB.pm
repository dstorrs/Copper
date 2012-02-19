package Copper::Sink::MongoDB;

use Moose;

with 'Copper::Sink';

use MongoDB;

my $DEFAULT_COLL_NAME = 'col';

sub drain {
	my $self = shift;
	my @vals = @_;

	my $meth = 'batch_insert';
	$meth = 'save' if ( @vals == 1 );
	$self->coll->$meth( \@vals );
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

has 'coll' => (
	'is' => 'rw',  #  Let the user change it if they want, perhaps in a hook or transform
	'isa' => 'MongoDB::Collection',
	lazy_build => 1,
);
sub _build_coll {
	my $self = shift;
	my $coll_name = $self->_coll_name;
	
	$self->db->$coll_name;
}

sub _coll_name { shift->config->{coll_name} || $DEFAULT_COLL_NAME }

has 'db' => (
	is  => 'ro',
	isa => 'MongoDB::Database',
	lazy_build => 1,
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
		$args{config}->{coll_name} //= $DEFAULT_COLL_NAME;
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
	delete $args{coll_name};

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
    coll_name => name of collection to write to.  default: col

    Additionally, all of the attributes listed in
    L<MongoDB::Connection> (e.g. w, wtimeout, auto_reconnect...) are
    supported.

=cut

