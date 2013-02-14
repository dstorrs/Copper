use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Copper',
    license             => 'perl',
    dist_author         => q{David K. Storrs <david.storrs@gmail.com>},
    dist_version_from   => 'lib/Copper.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'          => 5.10.1,
		'Moose'         => 0,
		'File::Slurp'   => 0,
    },
    add_to_cleanup      => [ 'Copper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
