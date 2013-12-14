#!usr/bin/perl

use 5.016;
use strict;
use warnings;
use DateTime;
use TBX::Min;
use open ':encoding(utf8)', ':std';

my ($in, $out, $die_message);

$die_message = "\nExample (TBX-Min to UTX): Converter(UTX-TBXmin).pl Input.tbx Output.utx\n"
	."Example (UTX to TBX-Min): Converter(UTX-TBXmin).pl Input.utx Output.tbx\n\n";

@ARGV == 2 or die "usage: Converter(UTX-TBXmin).pl <input_path(.tbx or .utx)> <output_path(.tbx or .utx)>\n".
				$die_message;

($ARGV[0] =~ /\.(tbx|utx)/i) ?
	(open IN, '<', $ARGV[0]) :
	(die "File Extensions must be either .tbx or .utx\n".$die_message);

($ARGV[1] =~ /\.(tbx|utx)/i) ?
	(open OUT, '>', $ARGV[1]) :
	(die "File Extensions must be either .tbx or .utx\n".$die_message);


my $file_ext = qr/\.(tbx|utx)/i;
$in = lc $1 if ($ARGV[0] =~ /$file_ext/);
$out = lc $1 if ($ARGV[1] =~ /$file_ext/);
die "Both files cannot have the same extension:\n$die_message" if $in eq $out;

my %import_type = (
		tbx => \&import_tbx,
		utx => \&import_utx
	);
my %export_type = (
		tbx => \&export_tbxnny,
		utx => \&export_utx
	);


sub import_tbx {  #really only checks for validity of TBX file
	@_ = <IN>;
	die "Not a TBX-Min file" unless ("@_" =~ /tbx-min/i);
}

sub import_utx {

	my ($id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record, @field_name);

	# header lines
	# input all relevant information until last line of header is found
	# keep checking until 'src' or 'tgt' (last line of a UTX header)
	do {
		state $linein++;
		$_ = <IN>;
		s/\s*$//; # chomp all trailing whitespace: space, CR, LF, whatever.
		if ($linein == 1){
			die "not a UTX file\n" unless /^#UTX/;
			($src, $tgt) = ($1, $2) if m{([a-zA-Z-]*)/([a-zA-Z-]*)};
		}
		$creator = $1 if /creator|copyright: ?([^;]+)/i; # error later if not
		$license = $1 if /license: ?([^;]+)/i;
		$description = $1 if /comment|description: ?([^;]+)/i;
		$id = $1 if /dictionary id:* ?([^;]+)/i;
		$directionality = $1 if /(bidirectional)/i;
		$subject = $1 if /subject\w*: ?([^;]+)/i;
	} until ($_ =~ /^#[src|tgt]/i);
	s/\s*$//;
	s/^#//;
	@field_name = split /\t/;
	die "no src column\n" unless $field_name[0] eq 'src';
	die "no tgt column\n" unless $field_name[1] eq 'tgt';
	die "no pos column\n" unless $field_name[2] =~ /pos/i;
	# a 'validating' UTX parser would also check for src:pos
	# but we defer POS issues here

	# body lines
	while (<IN>) {
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

	#	This goes through each 
	foreach my $hash_ref (@record) {
		my ($lang_group_src, $lang_group_tgt, $term_group_src, $term_group_tgt, $concept, @redo);
		my %hash = %$hash_ref;
		$concept = TBX::Min::ConceptEntry->new();
		while(my ($key, $value) = each %hash){
			if ($key =~ /src$/){
				$lang_group_src = TBX::Min::LangGroup->new({code => $src});
				$term_group_src = TBX::Min::TermGroup->new({term => $value});
			}
			elsif ($key =~ /tgt$/){
				$lang_group_tgt = TBX::Min::LangGroup->new({code => $tgt});
				$term_group_tgt = TBX::Min::TermGroup->new({term => $value});
			}
			
		}
		while(my ($key, $value) = each %hash){
			if ($key =~ /src/ && $key !~ /src$/){
				($term_group_src, $lang_group_src) = set_terms($key, $value, $term_group_src, $lang_group_src);
			}
			elsif ($key =~ /tgt/ && $key !~ /tgt$/){
				($term_group_tgt, $lang_group_tgt) = set_terms($key, $value, $term_group_tgt, $lang_group_tgt);
			}
			elsif ($key =~ /\bid\b/i){
				$concept->id($value);
			}
			elsif($key !~ /src|tgt/i){
				($term_group_tgt, $lang_group_tgt) = set_terms($key, $value, $term_group_tgt, $lang_group_tgt);
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
} #end export_tbxnny

sub export_utx {
	my $TBX = TBX::Min->new_from_xml($ARGV[0]);
	my ($source_lang, $target_lang, $creator, $license, $directionality, $DictID, 
		$description, $concepts); #because TBX-Min supports multiple subject fields and UTX does not, subject_field cannot be included here
	#note that in UTX 1.11, $source_lang, $target_lang,$creator, and $license are required
	
	my $timestamp = DateTime->now()->iso8601();
	
	#Get values from input
	$source_lang = $TBX->source_lang;
	$target_lang = $TBX->target_lang;
	$creator = "  copyright: ".$TBX->creator.";";
	$license = "  license: ".$TBX->license.";";
	$directionality = "  ".$TBX->directionality.";" if (defined $TBX->directionality);
	$DictID = "  Dictionary ID: ".$TBX->id.";" if (defined $TBX->id);
	$description = "description: ".$TBX->description.";" if (defined $TBX->description);
	$concepts = $TBX->concepts;
	
	#print header
	print OUT "#UTX 1.11;  $source_lang/$target_lang;  $timestamp;$creator$license$directionality$DictID\n";
	print OUT "#$description\n" if (defined $description); #print middle of header if necessary
	print OUT "#src	tgt	src:pos";  #print necessary values of final line of Header
	
	my @output;
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists) = 0;
	
	foreach my $concept (@$concepts){
		my ($concept_id, $lang_groups, $src_term, $tgt_term, $src_pos, $tgt_pos, $src_note, $tgt_note, $customer);
		(defined $concept->id) ? (($concept_id = "\t".$concept->id) && ($concept_id_exists = 1)) : 0; #($concept_id = "\t-");
		$lang_groups = $concept->lang_groups;
		
		foreach my $lang_group (@$lang_groups){
			my $term_groups = $lang_group->term_groups;
			my $code = $lang_group->code;
			
			foreach my $term_group (@$term_groups){
				
				my $status;
				
				if ($code eq $source_lang){
					$src_term = $term_group->term."\t";
					
					my $value = $term_group->part_of_speech;
					(defined $value && $value =~ /noun|properNoun|verb|adjective|adverb/i) ? ($src_pos = $value) : ($src_pos = "-");
					
					if (defined $term_group->note){
						($src_note = "\t".$term_group->note);
						$src_note_exists = 1;
					}
				}
				elsif ($code eq $target_lang){
					$tgt_term = $term_group->term."\t";
					
					my $value = $term_group->part_of_speech;
					if (defined $value && $value =~ /noun|properNoun|verb|adjective|adverb|sentece/i){ #technically sentence should never exist in current TBX-Min
						$tgt_pos = "\t".$value;
						$tgt_pos_exists = 1;
					}
					
					if (defined $term_group->note){
						($tgt_note = "\t".$term_group->note);
						$tgt_note_exists = 1;
					}
				}
				
				if (defined $term_group->customer){
					($customer = "\t".$term_group->customer);
					$customer_exists = 1;
				}
				if (defined $term_group->status){{
					
					my $value = $term_group->status;
					($value =~ /admitted|preferred|notRecommended|obsolete/i) ? ($status = $value) : next;
					
					$status = "provisional" if $status =~ /admitted/i;
					$status = "approved" if $status =~ /preferred/i;
					$status = "non-standard" if $status =~ /notRecommended/i;
					$status = "forbidden" if $status =~ /obsolete/i;
					
					$status = "\t".$status if defined $status;
					$status_exists = 1;
				}}
				
				if (defined $src_term && defined $tgt_term){
					my @output_line = ($src_term, $tgt_term, $src_pos, $tgt_pos, $status, $customer, $src_note, $tgt_note, $concept_id);
					push @output, \@output_line;
				}
			}
		}
	}
	
	print_utx([$tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists, @output]);
}

sub set_terms {  #used when exporting to TBX
	my ($key, $value, $term_group, $lang_group) = @_;
	if ($key =~ /pos$/){
		
		$value = "other" if $value !~ /verb|adjective|adverb|noun/i;
		
		$term_group->part_of_speech($value);
	}
	elsif ($key =~ /status$/){{
		$value = "admitted" if $value =~ /provisional/i;
		$value = "preferred" if $value =~ /approved/i;
		$value = "notRecommended" if $value =~ /non-standard/i;
		$value = "obsolete" if $value =~ /forbidden/i;
		($value =~ /admitted|preferred|notRecommended|obsolete/i) ? $term_group->status($value) : next;
	}}
	elsif ($key =~ /customer/i){
		$term_group->customer($value);
	}
	else {
		$term_group->note($value);
	}
	return ($term_group, $lang_group);
}

sub print_utx { #accepts $exists, and @output
	my $args = shift;
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists, @output) = @$args;
	
	print OUT "\ttgt:pos" if ($tgt_pos_exists);
	print OUT "\tterm status" if ($status_exists);
	print OUT "\tcustomer" if ($customer_exists);
	print OUT "\tsrc:comment" if ($src_note_exists);
	print OUT "\ttgt:comment" if ($tgt_note_exists);
	print OUT "\tconcept ID" if ($concept_id_exists);
	
	foreach my $output_line_ref (@output) {
				
		my ($src_term, $tgt_term, $src_pos, $tgt_pos, $status, $customer, $src_note, $tgt_note, $concept_id) = @$output_line_ref;
		
		if (defined $src_term && defined $tgt_term){
			print OUT "\n$src_term$tgt_term$src_pos";
			
			if ($tgt_pos_exists){ (defined $tgt_pos) ? (print OUT "$tgt_pos") : (print OUT "\t-") }
			if ($status_exists){ (defined $status) ? (print OUT "$status") : (print OUT "\t-") }
			if ($customer_exists){ (defined $customer) ? (print OUT "$customer") : (print OUT "\t-") }
			if ($src_note_exists){ (defined $src_note) ? (print OUT "$src_note") : (print OUT "\t-") }
			if ($tgt_note_exists){ (defined $tgt_note) ? (print OUT "$tgt_note") : (print OUT "\t-") }
			if ($concept_id_exists){ (defined $concept_id) ? (print OUT "$concept_id") : (print OUT "\t-") }
		}
	}
}

$export_type{$out}->($import_type{$in}->());
