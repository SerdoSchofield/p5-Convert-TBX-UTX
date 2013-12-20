#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::XML;
plan tests => 1*blocks();

filters {
	utx => 'convert_utx',
	output => '_format_out_tbx'
};

for my $block(blocks()){
	is_xml($block->utx, $block->output, "Expected");
}

__DATA__
=== Header
--- utx chomp
#UTX 1.11; de/en-US; copyright: Francis Bond (2008); license: CC-by 3.0; bidirectional; Dictionary ID: 18347322;
#description: djalbja;
--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>bidirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>
