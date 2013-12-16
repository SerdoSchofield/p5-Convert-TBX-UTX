#!/usr/bin/perl
use strict;
use warnings;
use Converter::DualConverter_UTX_TBXmin;
plan tests => 1*blocks();

filters {
	input => 'convert_utx',
	log => [qw(lines chomp array)],
};

for my $block(blocks()){
	my $converted = $block->input;
	
	if chomp($converted) == chomp($block->output){
		print 'passed';
	}
	else { die "nothing"; }
}

__DATA__
=== TBX
--- input
#UTX-S 0.91; ja-JP/en-US; 2008-05-21; copyright: Francis Bond (2008); bidirectional; dictionary ID 18347322
#description: djalbja; license: CC-by 3.0;
#src	tgt	src:pos	src:yomi	Concept ID
NICE nice	NICE property	-	nice	C002
--- output
<TBX dialect="TBX-Min">
<header>
<id>18347322</id>
<creator>Francis Bond (2008)</creator>
<license>CC-by 3.0</license>
<directionality>bidirectional</directionality>
<description>djalbja</description>
<languages source="ja-JP" target="en-US"/>
<dateCreated>2013-12-16T03:42:24</dateCreated>
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