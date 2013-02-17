#!/usr/bin/env perl

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Copper',
	license  => 'perl',

	requires => {
		'perl'          => '5.10.1',
		'Moose'         => '0',
		'MooseX::Types::Structured'  => '0',
	},

	build_requires      => {
		'Net::Ping'               => 0,
		'Test::Group'             => 0,
		'Test::Output'            => 0,
		'Test::Pod'               => 0,
		'Test::Pod::Coverage'     => 0,
		'Test::Exception'         => 0,
	},
);
$build->create_build_script;
