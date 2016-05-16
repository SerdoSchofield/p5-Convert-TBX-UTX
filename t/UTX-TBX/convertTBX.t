#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::LongString;
plan tests => 1*blocks();

filters {
	tbx => 'convert_tbx',
};
my $int;

for my $block(blocks()){
	$int++;
	print "\n" if $int == 1; #this prevents a rather confusing error of scalar refs contained in the blocks() array printing to STDOUT for no real reason?
	is_string_nows($block->tbx, $block->output, "Expected $int");
}
__DATA__
=== Header 1
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

--- output chomp
#UTX 1.2; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: TBX sample;
##description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos



=== Body 2
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
		<termEntry id="C002"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</tig>
				<tig><!--terminological information group-->
					<term>hound</term>
					<termStatus>notRecommended</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

--- output chomp
#UTX 1.2; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
##description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	non-standard	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008

=== test UTX conformant conversion of properNoun to noun 3
--- tbx chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<description>A short sample file demonstrating TBX-Min</description>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
		<languages source="de" target="en"/>
		<creator>Klaus-Dirk Schmidt</creator>
		<directionality>monodirectional</directionality>
		<license>CC BY license can be freely copied and modified</license>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</tig>
				<tig><!--terminological information group-->
					<term>hound</term>
					<termStatus>notRecommended</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<partOfSpeech>properNoun</partOfSpeech>
					<customer>SAP</customer>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

--- output chomp
#UTX 1.2; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
##description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	non-standard	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008


=== Test conversion to valid use of bidirectional flag in UTX 4
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
		<termEntry id="C002"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</tig>
				<tig><!--terminological information group-->
					<term>hound</term>
					<termStatus>admitted</termStatus>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
					<noteGrp> 						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note> 					</noteGrp>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<customer>SAP</customer>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

--- output chomp
#UTX 1.2; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
##description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun	provisional	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008




=== Test conversion to valid use of bidirectional flag in UTX 5
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
		<termEntry id="C002"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</tig>
				<tig><!--terminological information group-->
					<term>hound</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
		<subjectField>biology</subjectField>
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<partOfSpeech>noun</partOfSpeech>
					<termStatus>preferred</termStatus>
					<customer>SAP</customer>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

--- output chomp
#UTX 1.2; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; bidirectional; Dictionary ID: TBX sample;
##description: A short sample file demonstrating TBX-Min;
#term:de	term:en	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun		SAP	c008