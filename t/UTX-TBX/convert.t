#!/usr/bin/perl
use strict;
use warnings;
use t::TestUTX_TBX;
use Test::XML;
plan tests => 2*blocks();

filters {
	utx => 'convert_utx',
	tbx => 'convert_tbx',
	output => '_format_out'
};

for my $block(blocks()){
	is_xml($block->utx, $block->output, "Expected");
}

for my $block(blocks()){
	is_good_xml($block->utx);
}

__DATA__
=== UTX Conversion
--- utx
#UTX 1.11; ja-JP/en-US; 2008-05-21; copyright: Francis Bond (2008); bidirectional; dictionary ID 18347322
#description: djalbja; license: CC-by 3.0;
#src	tgt	src:pos	src:yomi	Concept ID
NICE nice	NICE property	-	nice	C002
--- output
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
=== Full File
--- utx
#UTX-S 1.01; en-US/ja-JP; copyright: Medical Informatics, School of Allied Health Sciences, Kitazato University (2009); license: CC-BY 3.0			
#description: This is a medical dictionary. You may use this dictionary only when you agreed that you and you alone are fully responsible for the results of its use. The author of the original data, AAMT and its members do not guarantee the contents of this dictionary including, but not limited to its accuracy. Some part of speech properties are indicated as noun, even when they are not. / ??????????????????????????????????????????????????????????AAMT???AAMT????????????????????????????????????????????????????????????????			
#src	tgt	src:pos	comment
1/2 T vector	1/2T????	noun	
1/2FF	1/2????	noun	
1/3 ER mean	????1/3????????	noun	
1/3EF	1/3????	noun	
1/3ER mean	????1/3????????	noun	
1/3FF	1/3????	noun	
1/3FR mean	????1/3??????????	noun	
11-deoxycorticosterone acetate salt hypertension	DOCA?????	noun	
11-deoxycortisosterone	11-????????????	noun	
131I-hippurate	131I-?????	noun
--- output
<?xml version='1.0' encoding="UTF-8"?>
<TBX dialect="TBX-Min"
><header
><creator
>Medical Informatics, School of Allied Health Sciences, Kitazato University (2009)</creator
><license
>CC-BY 3.0</license
><languages source="en-US" target="ja-JP"
 /></header
><body
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/2 T vector</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>1/2T????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/2FF</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>1/2????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/3 ER mean</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>????1/3????????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/3EF</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>1/3????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/3ER mean</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>????1/3????????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/3FF</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>1/3????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>1/3FR mean</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>????1/3??????????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>11-deoxycorticosterone acetate salt hypertension</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>DOCA?????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>11-deoxycortisosterone</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>11-????????????</term
></termGroup
></langGroup
></conceptEntry
><conceptEntry
><langGroup xml:lang="en-US"
><termGroup
><term
>131I-hippurate</term
><partOfSpeech
>noun</partOfSpeech
></termGroup
></langGroup
><langGroup xml:lang="ja-JP"
><termGroup
><term
>131I-?????</term
></termGroup
></langGroup
></conceptEntry
></body
></TBX>