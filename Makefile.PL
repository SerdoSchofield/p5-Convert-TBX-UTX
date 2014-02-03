use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME	=> 'Convert::TBX::UTX',
	VERSION_FROM	=> 'lib/Convert/TBX/UTX.pm',
	EXE_FILES	=> [ qw(bin/tbxmin2utx.pl bin/utx2tbxmin.pl) ],
	PREREQ_PM	=> {
		"TBX::Min" => "0.05",
		"Exporter::Easy" => "0.16",
		"DateTime" => "1.06",
		"Path::Tiny" => "0.052",
		"Test::LongString" => "0.15",
		"Test::XML" => "0.08",
		}
);