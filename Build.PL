use Module::Build;

my $build = Module::Build->new(
	module_name => 'Copper',
	license  => 'perl',
	dist_abstract => 'A data pipelining system for connecting arbitrary sources to arbirary sinks',
	build_requires => {
		'Test::Exception' => '0.31',
		'Test::Group' => '0.18',
		'Test::More' => '0.98',
		'Test::Output' => '1.01',
	},
	requires => {
		'perl'          => '5.10.1',
		'Data::Dumper'  => '0',
		'DateTime'      => '0.78',
		'File::Slurp'   => '0',
		'File::Temp'    => '0',
		'FindBin'       => '0',
		'MongoDB'       => '0.503.2',
		'Text::CSV'     => '1.21',
	},
);

$build->create_build_script;
