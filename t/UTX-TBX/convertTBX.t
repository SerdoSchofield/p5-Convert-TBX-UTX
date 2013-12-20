#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::LongString;
plan tests => 1*blocks();
### is_string_nows Test::LongString


filters {
	tbx => 'convert_tbx',
	output => '_format_out_utx'
};

for my $block(blocks()){
	is_string_nows($block->tbx, $block->output, "Expected");
}

__DATA__
=== Header
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>bidirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; bidirectional; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos



=== Body
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>bidirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<conceptEntry id="C002">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</termGroup>
				<termGroup>
					<term>hound</term>
					<termStatus>deprecated</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<note>however bloodhound is used rather than blooddog</note>
				</termGroup>
			</langGroup>
		</conceptEntry>
		<conceptEntry id="c008">
		<subjectField>biology</subjectField>
			<langGroup xml:lang="de">
				<termGroup>
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</termGroup>
			</langGroup>
			<langGroup xml:lang="en">
				<termGroup>
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
				</termGroup>
			</langGroup>
		</conceptEntry>
	</body>
</TBX>

--- output chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; bidirectional; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	customer	tgt:comment	concept ID
Hund	dog	noun	noun	approved	-	SAP	C002
Hund	hound	noun	noun	-	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun	-	-	SAP	c008
