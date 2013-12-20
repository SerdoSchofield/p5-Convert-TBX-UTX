#!usr/bin/perl

package Converter::DualConverter_UTX_TBXmin;
use strict;
use warnings;
use feature 'state';
use DateTime;
use TBX::Min;
use File::Slurp;
use open ':encoding(utf8)', ':std';

#converts utx to tbx
sub convert_utx {
	my ($self, $data) = @_;
	my @UTX = _import_utx($data);
	my $TBX = _export_tbx(@UTX);
	return $TBX;
}

#converts tbx to utx
sub convert_tbx {
	my ($self, $data) = @_;
	my @TBX = _import_tbx($data);
	my $UTX = _export_utx(@TBX);
	return $UTX;
}

#private subroutines
sub _run {
	my ($in, $out, $die_message);

	$die_message = "\nExample (TBX-Min to UTX): DualConverter_UTX_TBXmin.pm --tbx Input.tbx Output.utx\n"
		."Example (UTX to TBX-Min): DualConverter_UTX_TBXmin.pm --utx Input.utx Output.tbx\n\n";

	@ARGV == 3 or die "usage: DualConverter_UTX_TBXmin.pm <--utx or --tbx (input file type)> <input_path> <output_path>\n".$die_message;

	my $data = read_file($ARGV[1]);
	
	$in = lc $1 if ($ARGV[0] =~ /--(tbx|utx)/i);
	($in =~ /tbx/i) ? ($out = 'utx') : ($out = 'tbx');

	my %import_type = (
		tbx => \&_import_tbx,
		utx => \&_import_utx
	);
	my %export_type = (
		tbx => \&_export_tbx,
		utx => \&_export_utx
	);
		
	my $Converted = $export_type{$out}->($import_type{$in}->($data));
	
	open my $fhout, '>', $ARGV[2] 
		or die "An error occured: $!";
		
	print $fhout $Converted;
}

sub _import_tbx {  #really only checks for validity of TBX file
	my $data = shift;
	die "Not a TBX-Min file" unless ($data =~ /tbx-min/i);
	return $data;
}

sub _import_utx {
	my $data = shift;
	open my $fhin, '<', \$data;
	my ($id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record, @field_name);

	# header lines
	# input all relevant information until last line of header is found
	# keep checking until 'src' or 'tgt' (last line of a UTX header)
	do {
		state $linein++;
		$_ = <$fhin>;
		s/\s*$//; # chomp all trailing whitespace: space, CR, LF, whatever.
		if ($linein == 1){
			die "not a UTX file\n" unless /^#UTX/;
			($src, $tgt) = ($1, $2) if m{([a-zA-Z-]*)/([a-zA-Z-]*)};
		}
		if($_ !~ /^#[src|tgt]/i){
			$creator = $1 if /creator|copyright: ?([^;]+)/i;
			$license = $1 if /license: ?([^;]+)/i;
			$description = $1 if /description: ?([^;]+)/i;
			$id = $1 if /dictionary id:* ?([^;]+)/i;
			$directionality = $1 if /(bidirectional)/i;
			$subject = $1 if /subject\w*: ?([^;]+)/i;
		}
		$linein = 0 if /^#[src|tgt]/i;  #needs to reset before next run-through of auto-tests
	} until ($_ =~ /^#[src|tgt]/i);
	s/^#//;
	@field_name = split /\t/;
	die "no src column\n" unless $field_name[0] eq 'src';
	die "no tgt column\n" unless $field_name[1] eq 'tgt';
	die "no pos column\n" unless $field_name[2] =~ /pos/i;
	# a 'validating' UTX parser would also check for src:pos
	# but we defer POS issues here

	# body lines
	while (<$fhin>) {
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

	return [$data, $id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record];

} # end import_utx

sub _export_tbx {
	my $glossary = shift;
	my ($data, $id, $src, $tgt, $creator, $license, $directionality, $description, $subject, @record) = @$glossary;

	my $timestamp = DateTime->now()->iso8601();

	my $TBX = TBX::Min->new();
	$TBX->source_lang($src) if (defined $src);
	$TBX->target_lang($tgt) if (defined $tgt);
	$TBX->creator($creator) if (defined $creator);
	#~ $TBX->date_created($timestamp);
	$TBX->description($description) if (defined $description);
	$TBX->directionality($directionality) if (defined $directionality);
	$TBX->license($license) if (defined $license);
	$TBX->id($id) if (defined $id);

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
				($term_group_src, $lang_group_src) = _set_terms($key, $value, $term_group_src, $lang_group_src);
			}
			elsif ($key =~ /tgt/ && $key !~ /tgt$/){
				($term_group_tgt, $lang_group_tgt) = _set_terms($key, $value, $term_group_tgt, $lang_group_tgt);
			}
			elsif ($key =~ /\bid\b/i){
				$concept->id($value) if (defined $value);
			}
			elsif($key !~ /src|tgt/i){
				($term_group_tgt, $lang_group_tgt) = _set_terms($key, $value, $term_group_tgt, $lang_group_tgt);
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
		if (defined $concept->id == 0) {$concept->id('-')};
		$TBX->add_concept($concept);
	}
	#~ print OUT $TBX->as_xml;
	my $TBXstring .= "<?xml version='1.0' encoding=\"UTF-8\"?>\n".$TBX->as_xml;
	return $TBXstring;
} #end export_tbx

sub _export_utx {
	my $data = shift;
	my $TBX = TBX::Min->new_from_xml(\$data);
	my ($source_lang, $target_lang, $creator, $license, $directionality, $DictID, 
		$description, $concepts); #because TBX-Min supports multiple subject fields and UTX does not, subject_field cannot be included here
	#note that in UTX 1.11, $source_lang, $target_lang,$creator, and $license are required
	
	my $timestamp = DateTime->now()->iso8601();
	
	#Get values from input
	$source_lang = $TBX->source_lang;
	$target_lang = $TBX->target_lang;
	$creator = "copyright: ".$TBX->creator."; ";
	$license = "license: ".$TBX->license."; ";
	$directionality = $TBX->directionality."; " if (defined $TBX->directionality);
	$DictID = "Dictionary ID: ".$TBX->id."; " if (defined $TBX->id);
	$description = "description: ".$TBX->description."; " if (defined $TBX->description);
	$concepts = $TBX->concepts;
	
	my @output;
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists) = 0;
	
	foreach my $concept (@$concepts){
		my ($concept_id, $lang_groups, $src_term, $tgt_term, $src_pos, $tgt_pos, $src_note, $tgt_note, $customer);
	
		if (defined $concept->id){
			$concept_id = "\t".$concept->id;
			$concept_id_exists = 1;
		}
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
	
	my $UTX = _print_utx([$tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists,
					$source_lang, $target_lang, $timestamp, $creator, $license, $directionality, $DictID, $description, @output]);
	return $UTX;
} # end _export_utx

sub _set_terms {  #used when exporting to TBX
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
} # end _set_terms

sub _print_utx { #accepts $exists, and @output
	my $args = shift;
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $concept_id_exists,
		$source_lang, $target_lang, $timestamp, $creator, $license, $directionality, $DictID, $description, @output) = @$args;
	my $UTX;
	
	#print header
	#~ $UTX .= "#UTX 1.11;  $source_lang/$target_lang;  $timestamp;$creator$license$directionality$DictID\n";
	$UTX .= "#UTX 1.11; $source_lang/$target_lang; $creator$license$directionality$DictID\n";
	$UTX .= "#$description\n" if (defined $description); #print middle of header if necessary
	$UTX .= "#src	tgt	src:pos";  #print necessary values of final line of Header
	
	$UTX .= "\ttgt:pos" if ($tgt_pos_exists);
	$UTX .= "\tterm status" if ($status_exists);
	$UTX .= "\tcustomer" if ($customer_exists);
	$UTX .= "\tsrc:comment" if ($src_note_exists);
	$UTX .= "\ttgt:comment" if ($tgt_note_exists);
	$UTX .= "\tconcept ID" if ($concept_id_exists);
	
	foreach my $output_line_ref (@output) {
				
		my ($src_term, $tgt_term, $src_pos, $tgt_pos, $status, $customer, $src_note, $tgt_note, $concept_id) = @$output_line_ref;
		
		if (defined $src_term && defined $tgt_term){
			$UTX .= "\n$src_term$tgt_term$src_pos";
			
			if ($tgt_pos_exists){ (defined $tgt_pos) ? ($UTX .= "$tgt_pos") : ($UTX .= "\t-") }
			if ($status_exists){ (defined $status) ? ($UTX .= "$status") : ($UTX .= "\t-") }
			if ($customer_exists){ (defined $customer) ? ($UTX .= "$customer") : ($UTX .= "\t-") }
			if ($src_note_exists){ (defined $src_note) ? ($UTX .= "$src_note") : ($UTX .= "\t-") }
			if ($tgt_note_exists){ (defined $tgt_note) ? ($UTX .= "$tgt_note") : ($UTX .= "\t-") }
			if ($concept_id_exists){ (defined $concept_id) ? ($UTX .= "$concept_id") : ($UTX .= "\t-") }
		}
	}
	#~ print OUT $UTX;
	return $UTX;
} #end _print_utx

_run() unless caller;
