#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::XML;
plan tests => 1*blocks();

filters {
	tbx => 'convert_tbx',
	output => '_format_out'
};

for my $block(blocks()){
	is($block->tbx, $block->output, "expected");
}

__DATA__
=== UTX Conversion
--- output chomp
#UTX 1.11; ja-JP/en-US; copyright: Francis Bond (2008); license: CC-by 3.0; bidirectional; Dictionary ID: 18347322; 
#description: djalbja; 
#src	tgt	src:pos	src:comment	concept ID
NICE nice	NICE property	-	nice	C002
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
		<header>
			<id>18347322</id>
			<creator>Francis Bond (2008)</creator>
			<license>CC-by 3.0</license>
			<directionality>bidirectional</directionality>
			<description>djalbja</description>
			<languages source="ja-JP" target="en-US"/>
		</header>
	<body>
		<conceptEntry id="C002">
			<langGroup xml:lang="ja-JP">
				<termGroup>
					<term>NICE nice</term>
					<note>nice</note>
					<partOfSpeech>other</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en-US">
				<termGroup>
					<term>NICE property</term>
				</termGroup>
			</langGroup>
		</conceptEntry>
	</body>
</TBX>
