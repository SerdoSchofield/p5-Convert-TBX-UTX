#!usr/bin/perl

# UTX to TBX:NNY converter v0.01, 18 Nov 2013
# Export code by James Hayes
#
# UTX import code found in:
# Glossary format converter, v0.93, 28 Feb 2011
# by Nathan Rasmussen, primarily written June 2010
# updated as needed by James Hayes November 2013


use 5.016;
use strict;
use warnings;
use DateTime;
use TBX::Min;
use open ':encoding(utf8)', ':std';

@ARGV == 2 or die 'usage: UTX-TBXnny-Converter.pl <utx_path> <output_path>';

open my $in, '<', $ARGV[0]
		or die "cannot open $ARGV[0] for reading\n";
open OUT, '>', $ARGV[1]
		or die "Please specify an Output file";

sub import_utx {

	my ($id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record, @field_name);

	# first header line
	$_ = <$in>;
	die "not a UTX file\n" unless /^#UTX/;
	s/\s*$//; # chomp all trailing whitespace: space, CR, LF, whatever.
	($src, $tgt) = ($1, $2) if m{([a-zA-Z-]*)/([a-zA-Z-]*)};
	$creator = $1 if /creator|copyright: ?([^;]+)/i; # error later if not
	$license = $1 if /license: ?([^;]+)/i;
	$description = $1 if /comment|description: ?([^;]+)/i;
	$id = $1 if /dictionary id:* ?([^;]+)/i;
	$directionality = $1 if /(bidirectional)/i;
	$subject = $1 if /subject\w*: ?([^;]+)/i;

	# second header line
	# keep checking until 'src' or 'tgt' are found.  This is in case the second header is a description (which it shouldn't be)
	do {$_ = <$in>} until ($_ =~ /^#[src|tgt]/i);
	s/\s*$//;
	s/^#//;
	@field_name = split /\t/;
	die "no src column\n" unless $field_name[0] eq 'src';
	die "no tgt column\n" unless $field_name[1] eq 'tgt';
	die "no pos column\n" unless $field_name[2] =~ /pos/i;
	# a 'validating' UTX parser would also check for src:pos
	# but we defer POS issues here

	# body lines
	while (<$in>) {
		next if /^#/;
		s/\s*$//;
		next if /^$/;
		# turn line to list, then list to hash
		my @field = split /\t/;
		my %record;
		%record = map {$field_name[$_] => $field[$_]} (0..$#field);
		# clear out blanks, except src and tgt
		for my $field (grep {$_ ne 'src' and $_ ne 'tgt'} keys %record) {
			delete $record{$field} unless $record{$field} =~ /\S/
		}
		push @record, \%record;
	}

	return [$id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record];

} # end import_utx

sub export_tbxnny {
	my $glossary = shift;
	my ($id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record) = @$glossary;

	my $timestamp = DateTime->now()->iso8601();

	my $TBX = TBX::Min->new();
	$TBX->source_lang($src);
	$TBX->target_lang($tgt);
	$TBX->creator($creator);
	$TBX->date_created($timestamp);
	$TBX->description($description);
	$TBX->directionality($directionality);
	$TBX->license($license);
	$TBX->id($id);

	#~ $TBX->{concepts} = [];
	say OUT "<?xml version='1.0' encoding=\"UTF-8\"?>";

	foreach my $hash_ref (@record) {
		state ($lang_group_src, $lang_group_tgt, $term_group_src, $term_group_tgt, $concept);
		my %hash = %$hash_ref;
		$concept = TBX::Min::ConceptEntry->new();
		while(my ($key, $value) = each %hash){
			if ($key =~ /src/){
				($term_group_src, $lang_group_src) = set_terms($key, $value, $src, $term_group_src, $lang_group_src);
			}
			elsif ($key =~ /tgt/){
				($term_group_tgt, $lang_group_tgt) = set_terms($key, $value, $tgt, $term_group_tgt, $lang_group_tgt);
			}
			elsif ($key =~ /\bid\b/i){
				$concept->id($value);
			}
		}
		if (defined $term_group_src){
			$lang_group_src->add_term_group($term_group_src);
			$concept->add_lang_group($lang_group_src);
		}
		if (defined $term_group_tgt){
			$lang_group_tgt->add_term_group($term_group_tgt);
			$concept->add_lang_group($lang_group_tgt);
		}
		$concept->subject_field($subject);
		$TBX->add_concept($concept);
	}
	print OUT $TBX->as_xml;
}

sub set_terms {
	my ($key, $value, $src_or_tgt, $term_group, $lang_group) = @_;
	if ($key =~ /src$|tgt$/){
			$lang_group = TBX::Min::LangGroup->new({code => $src_or_tgt});
			$term_group = TBX::Min::TermGroup->new({term => $value});
	}
	elsif ($key =~ /pos$/){
		$term_group->part_of_speech($value);
	}
	elsif ($key =~ /status/){
		$term_group->status($value);
	}
	elsif ($key =~ /customer/i){
		$term_group->customer($value);
	}
	else {
		$term_group->note($value);
	}
	return ($term_group, $lang_group);
}

export_tbxnny(import_utx());