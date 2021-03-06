#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::XML;
plan tests => 1*blocks();

filters {
	utx => 'convert_utx',
};

my $int;
for my $block(blocks()){
	$int++;
	is_xml($block->utx, $block->output, "Expected $int");
}

__DATA__
=== Header
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; bidirectional; Dictionary ID: 18347322;
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

=== Test unstated directionality
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: 18347322;
#description: djalbja;

--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

=== Test monodirectional
--- utx chomp
#UTX 1.11; de/en-US; 2013-12-20T17:00:45; copyright: Francis Bond (2008); license: CC-by 3.0; Dictionary ID: 18347322;
#description: djalbja;

--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>18347322</id>
		<creator>Francis Bond (2008)</creator>
		<license>CC-by 3.0</license>
		<directionality>monodirectional</directionality>
		<description>djalbja</description>
		<languages source="de" target="en-US"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
	</body>
</TBX>

=== Body(Repeated concept ID should get changed in TBX)
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun			SAP	c008


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
			 <tig><!--terminological information group-->
			   <term>Hund</term>
			   <customer>SAP</customer>
			   <partOfSpeech>noun</partOfSpeech>
			 </tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<noteGrp>
						<note>
						  <noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>


=== No_Concept_IDs
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer
Hund	dog	noun	noun	approved		SAP
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP
Katze	cat	noun	noun			SAP


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
			<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C003"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>


=== Some_Concept_IDs
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:comment	customer	concept ID
Hund	dog	noun	noun	approved		SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun			SAP	C008
Foo	bar	noun	noun				
Bar	Foo	noun	noun	approved	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C003"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C008"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C004"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>bar</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<customer>Walmart</customer>
					<noteGrp>
						<note>
							<noteValue>Foobar</noteValue>
						</note>
					</noteGrp>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

=== Test implied approved term status with bidirectional flag
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; bidirectional; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun		SAP	C008
Foo	bar	noun	noun			
Bar	Foo	noun	noun	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>bidirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C003"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C008"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C004"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Bar</term>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<customer>Walmart</customer>
					<noteGrp>
						<note>
							<noteValue>Foobar</noteValue>
						</note>
					</noteGrp>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>



=== Test approved term status insertion without flag or term status column
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	tgt:comment	customer	concept ID
Hund	dog	noun	noun		SAP	C002
Hund	hound	noun	noun	however bloodhound is used rather than blooddog	SAP	-
Katze	cat	noun	noun		SAP	C008
Foo	bar	noun	noun			
Bar	Foo	noun	noun	Foobar	Walmart	C001


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C003"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<noteGrp>
						<note>
							<noteValue>however bloodhound is used rather than blooddog</noteValue>
						</note>
					</noteGrp>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C008"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C004"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>bar</term>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Bar</term>
					<customer>Walmart</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>Foo</term>
					<customer>Walmart</customer>
					<noteGrp>
						<note>
							<noteValue>Foobar</noteValue>
						</note>
					</noteGrp>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>

=== Custom Columns Not Converted to TBX
--- utx chomp
#UTX 1.11; de/en; 2013-12-20T17:00:45; copyright: Klaus-Dirk Schmidt; license: CC BY license can be freely copied and modified; Dictionary ID: TBX sample;
#description: A short sample file demonstrating TBX-Min;
#src	tgt	src:pos	tgt:pos	term status	tgt:custom	customer	concept ID
Hund	dog	noun	noun	approved	CUSTOM NOTE	SAP	C002
Hund	hound	noun	noun		however bloodhound is used rather than blooddog	SAP	C002
Katze	cat	noun	noun		CUSTOM NOTE	SAP	c008


--- output chomp
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min">
	<header>
		<id>TBX sample</id>
		<creator>Klaus-Dirk Schmidt</creator>
		<license>CC BY license can be freely copied and modified</license>
		<directionality>monodirectional</directionality>
		<description>A short sample file demonstrating TBX-Min</description>
		<languages source="de" target="en"/>
		<dateCreated>2013-12-20T17:00:45</dateCreated>
	</header>
	<body>
		<termEntry id="C002"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>dog</term>
					<customer>SAP</customer>
					<termStatus>preferred</termStatus>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
			<termEntry id="C001"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Hund</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>hound</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
		<termEntry id="c008"><!--terminological entry-->
			<langSet xml:lang="de">
				<tig><!--terminological information group-->
					<term>Katze</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
			<langSet xml:lang="en">
				<tig><!--terminological information group-->
					<term>cat</term>
					<customer>SAP</customer>
					<partOfSpeech>noun</partOfSpeech>
				</tig>
			</langSet>
		</termEntry>
	</body>
</TBX>
