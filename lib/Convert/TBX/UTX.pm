#!usr/bin/perl
#
# This file is part of Convert-TBX-UTX
#
# This software is copyright (c) 2014 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Convert::TBX::UTX;
use strict;
use warnings;
use feature 'state';
use feature 'say';
use DateTime;
use TBX::Min 0.07;
use Path::Tiny;
use Exporter::Easy (
	OK => [ 'utx2min', 'min2utx' ]
	);
use open ':encoding(utf8)', ':std';
	
our $VERSION = '0.04';

# ABSTRACT:  Convert UTX to TBX-Min
sub utx2min {
	my ($fh, $TBX);
	my ($input, $output) = @_;
	$fh = _get_handle($input);
	
	$TBX = _import_utx($fh);
	
	if (defined $output) { _print_converted($TBX, $output) };
	return \$TBX;
}

# ABSTRACT:  Convert TBX-Min to UTX
sub min2utx {
	my ($fh, $data, $UTX);
	my ($input, $output, $option) = @_;
	if (!defined $option) {
        $option = "--1.11";
    }

	$UTX = _export_utx($input, $option);
	if (defined $output) { _print_converted($UTX, $output) };
	
	return \$UTX;
}

sub _get_handle {
    my ($input) = @_;

    my $fh;

    if((ref $input) eq 'SCALAR'){

        open $fh, '<', $input; ## no critic(RequireBriefOpen)

    }else{

		$fh = path($input)->filehandle('<');
     
    }
    return $fh;
}

# used if UTX.pm is called as a script
sub _run {
	my ($in, $out, $die_message);

	$die_message = "\nExample (TBX-Min to UTX): UTX.pm --tbx2utx Input.tbx Output.utx\n"
		."Example (UTX to TBX-Min): UTX.pm --utx2tbx Input.utx Output.tbx\n\n";

	(@ARGV == 3 || @ARGV == 4) or die "usage: UTX.pm <--utx2tbx or --tbx2utx (conversion direction)> <input_path> <output_path>\n".$die_message;
	
	if ($ARGV[0] =~ /--(tbx2utx|utx2tbx)/i){
		$in = lc $1 ;
		($in =~ /tbx2utx/i) ? ($out = 'utx2tbx') : ($out = 'tbx');
	}else{ die "usage: UTX.pm <--utx2tbx or --tbx2utx (conversion direction)> <input_path> <output_path>\n".$die_message; }

	my %import_type = (
		tbx2utx => \&min2utx,
		utx2tbx => \&utx2min
	);

	$import_type{$in}->($ARGV[1], $ARGV[2]);
		
}

sub _print_converted {
	my ($Converted, $output) = @_;
	open my $fhout, '>', $output
		or die "An error occured: $!";
		
	print $fhout $Converted;
}

sub _import_utx {
	my $fhin = shift;
# 	open my $fhin, '<', \$data;
	my ($linein, $id, $src, $tgt, $timestamp, $creator, $license, $directionality, $description, $subject, @record, @field_name);

	my $monolingual = 0;
	# header lines
	# input all relevant information until last line of header is found
	# keep checking until 'src' or 'tgt' (last line of a UTX header)
	do {
		$linein++;
		$_ = <$fhin>;
		s/\s*$//; # chomp all trailing whitespace: space, CR, LF, whatever.
		if ($linein == 1){
			s/^(.+)#UTX/#UTX/; #eliminate any type of BOM
			die "not a UTX file\n" unless /#UTX/;
			if (m{([a-zA-Z-]*)/([a-zA-Z-]*)})
			{
				($src, $tgt) = ($1, $2);
			}
			elsif(m{#UTX\s*[0-9\.]*\s*;\s*\t*([a-zA-Z-]*)\s*;?})
			{
				$src = $1;
				$monolingual = 1;
			}
		}
		if($_ !~ /^#[src|tgt]/i){
			$timestamp = $1 if /; ?([0-9T:+-]+)/;
			$creator = $1 if /creator|copyright: ?([^;]+)/i;
			$license = $1 if /license: ?([^;]+)/i;
			$description = $1 if /description: ?([^;]+)/i;
			$id = $1 if /dictionary id:* ?([^;]+)/i;
			$directionality = $1 if /(bidirectional)/i;
			$subject = $1 if /domain: ?([^;]+)/i;
		}
	} until ($_ =~ /^#[src|tgt|term]/i or eof); #eof catch is used for testing
	
	if ($_ =~ /^#[src|tgt|term]/i ){ #used for testing
		s/^#//;
		@field_name = split /\t/;
		if ($field_name[0] !~ /term/)
		{
			die "no src column\n" unless $field_name[0] eq 'src';
		}
		# die "no tgt column\n" unless $field_name[1] eq 'tgt';
		die "no pos column\n" unless "@field_name" =~ /pos/i;
		# a 'validating' UTX parser would also check for src:pos
		# but we defer POS issues here
		# As of UTX 1.2, a monolingual dictionary is allowed, therefore the check for 'tgt' column is not required in those cases

		# body lines
		while (<$fhin>) {
			next if /^#/;
			s/\s*$//;
			next if /^$/;
			# turn line to list, then list to hash
			my @field = split /\t/;
			my %record;
			%record = map {$field_name[$_] => $field[$_]} (0..$#field);
			# clear out blanks, except src, tgt, or term
			for my $field (grep {$_ ne 'src' and $_ ne 'tgt' and $_ ne 'term'} keys %record) {
				delete $record{$field} unless $record{$field} =~ /\S/
			}
			push @record, \%record;
		}
	}

	#test and adjust directionality if needed before sending it
	if (defined $directionality) {
		$directionality = 'monodirectional' if ($directionality ne 'bidirectional');
	}
	else{
		$directionality = 'monodirectional';
	}
#	$id = '' if defined $id == 0;
	
	_export_tbx([$fhin, $id, $src, $tgt, $timestamp, $creator, $license, $directionality, $description, $subject, $monolingual, @record]);
# 	return [$data, $id, $src, $tgt, $timestamp, $creator, $license, $directionality, $description, $subject, @record];

} # end import_utx

sub _export_tbx {
	my $glossary = shift;
	my ($data, $id, $src, $tgt, $timestamp, $creator, $license, $directionality, $description, $subject, $monolingual, @record) = @$glossary;

	my $generated_timestamp = DateTime->now()->iso8601();  #only use if desired timestamp is time of conversion rather than the timestamp included on the file being converted or if there is no timestamp to convert

	my $ID_Check = TBX::Min->new();
	my $TBX = TBX::Min->new();
	$TBX->source_lang($src) if (defined $src);
	$TBX->target_lang($tgt) if (defined $tgt);
	$TBX->creator($creator) if (defined $creator);
	(defined $timestamp) ? ($TBX->date_created($timestamp)) : ($TBX->date_created($generated_timestamp));
	$TBX->description($description) if (defined $description);
	$TBX->directionality($directionality) if (defined $directionality && $monolingual == 0);
	$TBX->license($license) if (defined $license);
	$TBX->id($id) if (defined $id);

	#	This goes through each 
	foreach my $hash_ref (@record) {
			my ($note_group, $noteGroupSrc, $noteGroupTgt, $lang_group_src, $lang_group_tgt, $term_group_src, $term_group_tgt, $entry, $status_bidirectional, @redo);
		my %hash = %$hash_ref;
		$entry = TBX::Min::TermEntry->new();
		
		if (keys(%hash) !~ /status$/ && $directionality eq 'bidirectional'){
				$status_bidirectional = 1;
			}
		
		while(my ($key, $value) = each %hash){
			if ($key =~ /src$/  || $key =~ /term:$src/){
				$lang_group_src = TBX::Min::LangSet->new({code => $src});
				$term_group_src = TBX::Min::TIG->new({term => $value});
			}
			elsif (defined $tgt && ($key =~ /tgt$/ || $key =~ /term:$tgt/)){
				$lang_group_tgt = TBX::Min::LangSet->new({code => $tgt});
				$term_group_tgt = TBX::Min::TIG->new({term => $value});
			}
			
		}
		while(my ($key, $value) = each %hash){
			if (($key =~ /src/ && $key !~ /src$/) || ($key =~ /pos:$src/) || ($key =~ /term status:$src/)){
				($term_group_src, $noteGroupSrc) = _set_terms($key, $value, $term_group_src, $status_bidirectional, $note_group);
			}
			elsif (defined $tgt && ($key =~ /tgt/ && $key !~ /tgt$/ || ($key =~ /pos:$tgt/) || ($key =~ /term status:$tgt/))){
				($term_group_tgt, $noteGroupTgt) = _set_terms($key, $value, $term_group_tgt, $status_bidirectional, $note_group);
			}
			elsif ($key =~ /\bid\b/i){
					$value = "C".$value if (defined($value) && ($value !~ /\w*[a-z]\w*/gi));
				$entry->id($value) if (defined $value);
			}
			elsif($key =~ /term status$/i){
				($term_group_tgt, undef, $term_group_src) = _set_terms($key, $value, $term_group_tgt, undef, undef, $term_group_src);
			}
			elsif($key !~ /src|tgt/i){
				($term_group_src, $noteGroupSrc) = _set_terms($key, $value, $term_group_src, undef, $note_group);
				($term_group_tgt, $noteGroupTgt) = _set_terms($key, $value, $term_group_tgt, undef, $note_group);
			}
		}
		
		if (defined $term_group_src){
			if (defined $noteGroupSrc && @{$noteGroupSrc->notes} > 0){
				$term_group_src->add_note_group($noteGroupSrc);
			}
			$lang_group_src->add_term_group($term_group_src);
			$entry->add_lang_group($lang_group_src);
		}
		if (defined $term_group_tgt){
			if (defined $noteGroupTgt && @{$noteGroupTgt->notes} > 0){
				$term_group_tgt->add_note_group($noteGroupTgt);
			}
			$lang_group_tgt->add_term_group($term_group_tgt);
			$entry->add_lang_group($lang_group_tgt);
		}
		$entry->subject_field($subject);
		
		$ID_Check->add_entry($entry);
	}
	
	my (%count_ids_one, %count_ids_two, @entry_ids, $generated_ids);
	my $entry_list = $ID_Check->entries;
	foreach my $entry_value (@$entry_list) {
		my $c_id = $entry_value->id;
		if (defined $c_id){
			$count_ids_one{$c_id}++;
			for ($c_id) {s/C([0-9]+)/$1/i};
			push (@entry_ids, $c_id);
		}
	}
	
	foreach my $entry_value (@$entry_list) {
		my $c_id = $entry_value->id;
		$count_ids_two{$c_id}++ if defined $c_id;
		
		if (defined $c_id == 0 or $c_id eq '-'  or (defined $c_id && $count_ids_one{$c_id} > 1 && $count_ids_two{$c_id} > 1)) {
			do  {$generated_ids++} until ("@entry_ids" !~ sprintf("%03d", $generated_ids));
			push @entry_ids, $generated_ids;
			$entry_value->id("C".sprintf("%03d", $generated_ids))
		}
		$TBX->add_entry($entry_value);
	}	
	
	my $TBX_ref = $TBX->as_xml;
	my $TBXstring = "<?xml version='1.0' encoding=\"UTF-8\"?>\n".$$TBX_ref;  #as_xml returns a string ref
	return $TBXstring; #returns a string
} #end export_tbx

sub _export_utx {
	my $fh = shift;
	my $option = shift;
	my $printUTX1_2 = -1;
	if ($option eq "--1.2") {
        $printUTX1_2 = 1;
    }
    
	
    
	
	my $TBX = TBX::Min->new_from_xml($fh);
	my ($source_lang, $target_lang, $timestamp, $creator, $license, $directionality, $DictID, 
		$description, $entries, @custom); #because TBX-Min supports multiple subject fields and UTX does not, subject_field cannot be included here
	#note that in UTX 1.11, $source_lang, $target_lang,$creator, and $license are required
	
	#~ my $timestamp = DateTime->now()->iso8601();   #this was used to generate timestamp at time of conversion rather than read in the old one
	
	#Get values from input
	$source_lang = $TBX->source_lang if (defined $TBX->source_lang);
	$target_lang = $TBX->target_lang if (defined $TBX->target_lang);
	(defined $TBX->date_created) ? ($timestamp = $TBX->date_created) : ($timestamp = DateTime->now()->iso8601());
	$creator = "copyright: ".$TBX->creator if (defined $TBX->creator);
	$license = "license: ".$TBX->license if (defined $TBX->license);
	$directionality = $TBX->directionality if (defined $TBX->directionality);
	$DictID = "Dictionary ID: ".$TBX->id if (defined $TBX->id);
	$description = "description: ".$TBX->description if (defined $TBX->description);
	$entries = $TBX->entries if (defined $TBX->entries);
	
	my (@output, @status_list);
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $src_custom_exists, $tgt_custom_exists, $entry_id_exists) = 0;
	
	foreach my $entry (@$entries){
		my $notehistory;
		my ($entry_id, $lang_groups, $src_term, $tgt_term, $src_pos, $tgt_pos, $src_note, $tgt_note, $customer);
		my ($value_count, $approved_count);
		my (@source_term_info, @target_term_info);
		if (defined $entry->id){
			$entry_id = "\t".$entry->id;
			$entry_id_exists = 1;
		}
		$lang_groups = $entry->lang_groups;
		
		foreach my $lang_group (@$lang_groups){
			
			my $term_groups = $lang_group->term_groups;
			my $code = $lang_group->code;
			
			foreach my $term_group (@$term_groups){
				
				my ($status, %term_info);
				
				if ($code eq $source_lang){
					$src_term = "\t" if (!defined $term_group->term || (defined $term_group->term && $term_group->term eq "\t"));
					$src_term = $term_group->term."\t" if (defined $term_group->term);
					$term_info{term} = $src_term;
					
					my $value = $term_group->part_of_speech;
					if (defined $value && $value =~ /noun|properNoun|verb|adjective|adverb/i)
					{
						$value = "" if $value eq "\t";
						$src_pos = $value
					}
					else
					{
						$src_pos = ""
					}
					# (defined $value && $value =~ /noun|properNoun|verb|adjective|adverb/i) ? ($src_pos = $value) : ($src_pos = "");
					$src_pos = 'noun' if $src_pos eq 'properNoun';
					$term_info{pos} = $src_pos;
					
					if (@{$term_group->note_groups}){
						foreach my $note_group (@{$term_group->note_groups})
						{
							foreach my $note (@{$note_group->notes})
							{
								$src_note = "\t" if (defined $notehistory && $note->noteValue eq $notehistory);

								
								if(!defined $notehistory || $note->noteValue ne $notehistory)
								{
									# print "CREATING NOTE HISTORY FROM $source_lang: ".$term_group->note."\n\n\n";
									$notehistory = $note->noteValue;
								}
								$src_note = "\t".$note->noteValue unless (defined $src_note);
# 								print "hello source note $source_lang: ".$src_note."\n\n\n";
								
								if (defined $note->noteKey)
								{
									push(@custom, $note->noteKey)  if $note->noteKey !~ @custom;
									$term_info{$note->noteKey} = $src_note;
									$src_custom_exists = 1;
								}
								else
								{
									$term_info{note} = $src_note;
									$src_note_exists = 1;
								}
								
							}
						}
					}
				}
				elsif ($code eq $target_lang){
					$tgt_term = $term_group->term;
					$tgt_term = "" if (!defined $tgt_term || (defined $tgt_term && $tgt_term eq "\t"));
					$term_info{term} = $tgt_term;
					
					my $value = $term_group->part_of_speech;
					if (defined $value && $value =~ /noun|properNoun|verb|adjective|adverb|sentence/i){ #technically sentence should never exist in current TBX-Min
						$value = 'noun' if $value =~ /properNoun/i;
						$value = "" if ($value eq "\t");
						$tgt_pos = "\t".$value;
						$term_info{pos} = $tgt_pos;
						$tgt_pos_exists = 1;
					}
					
					if (@{$term_group->note_groups}){
						foreach my $note_group (@{$term_group->note_groups})
						{
							foreach my $note (@{$note_group->notes})
							{
								$tgt_note = undef if (defined $notehistory && $note->noteValue eq $notehistory);
								if(!defined $notehistory || $note->noteValue ne $notehistory)
								{
									# print "CREATING NOTE HISTORY FROM $target_lang".$term_group->note."\n\n\n";
									$notehistory = $note->noteValue;
								}
								$tgt_note = "\t".$note->noteValue unless (defined $tgt_note);
								# $notehistory = $term_group->note unless (defined $notehistory);
# 								print "hello target note $target_lang: ".$tgt_note."\n\n\n";
								if ($note->noteKey && defined $tgt_note)
								{
									push(@custom, $note->noteKey) if $note->noteKey !~ @custom;
									$term_info{$note->noteKey} = $tgt_note;
									$tgt_custom_exists = 1;
								}
								else
								{
									$term_info{note} = $tgt_note;
									$tgt_note_exists = 1;
								}
								
							}
						}
					}
				}
				
				if (defined $term_group->customer){
					if($term_group->customer eq "\t"){$customer = " "}
					else {$customer = $term_group->customer};
					$customer = "\t".$customer;
					$term_info{customer} = $customer;
					$customer_exists = 1;
				}
				
				if (defined $term_group->status){
					my $value = $term_group->status;
					if ($value =~ /admitted|preferred|notRecommended|obsolete/i){
						$value_count++;
						$status = $value;
						$status = "provisional" if $status =~ /admitted/;
						$status = "non-standard" if $status =~ /notRecommended/;
						$status = "forbidden" if $status =~ /obsolete/;
						if ($status =~ /preferred/){
							$approved_count++;
							$status = "approved";
						}
					}else{
						$value_count++;
						$status = undef;
					};
					
					#~ push @status_list, $status;
					$status = "\t".$status if defined $status;
					$term_info{status} = $status if defined $status;
					$status_exists = 1;
					
				}
				#in UTX file can only have 'bidirectional' flag if all terms are approved
				$directionality = undef unless (defined $approved_count && defined $value_count && 
											$approved_count == $value_count);
											
				push @source_term_info, \%term_info if ($code eq $source_lang);
				push @target_term_info, \%term_info if (defined $target_lang && $code eq $target_lang);
			}
		}
		
		if (@source_term_info) {
			foreach my $src_hash_ref (@source_term_info) {
				my %src_term_info = %$src_hash_ref;
				
				if (@target_term_info) {
					foreach my $tgt_hash_ref (@target_term_info){
						my ($status, $customer);
						my %tgt_term_info = %$tgt_hash_ref;

							if (defined $src_term_info{status} == 1 && defined $tgt_term_info{status} == 1) { $status = $tgt_term_info{status} }
							elsif (defined $src_term_info{status} == 0 && defined $tgt_term_info{status} == 1) { $status = $tgt_term_info{status} }
							elsif (defined $src_term_info{status} == 1 && defined $tgt_term_info{status} == 0) { $status = $src_term_info{status} }
						
							if (defined $src_term_info{customer} == 1 && defined $tgt_term_info{customer} == 1) { $customer = $tgt_term_info{customer} }
							elsif (defined $src_term_info{customer} == 0 && defined $tgt_term_info{customer} == 1) { $customer = $tgt_term_info{customer} }
							elsif (defined $src_term_info{customer} == 1 && defined $tgt_term_info{customer} == 0) { $customer = $src_term_info{customer} }
						
# 							foreach (@custom)
# 							{
# 								if (defined $src_term_info{$_} == 1 && defined $tgt_term_info{$_} == 1) { $_ = $tgt_term_info{$_} }
# 								elsif (defined $src_term_info{$_} == 0 && defined $tgt_term_info{$_} == 1) { $_ = $tgt_term_info{$_} }
# 								elsif (defined $src_term_info{$_} == 1 && defined $tgt_term_info{$_} == 0) { $_ = $src_term_info{$_} }
# 							}
						
						my @output_line = ($src_term_info{term}, $tgt_term_info{term}, $src_term_info{pos}, $tgt_term_info{pos}, $status, $customer,
										   $src_term_info{note}, $tgt_term_info{note}, $entry_id, \%src_term_info, \%tgt_term_info);
						push @output, \@output_line;
					}
				}else {
					my @output_line = ($src_term_info{term}, "", $src_term_info{pos}, "", $src_term_info{status}, $src_term_info{customer},
									   $src_term_info{note}, "", $entry_id, \%src_term_info);
					push @output, \@output_line;
				}
			}
		} else {
			print "The following target terms could not be converted into valid UTX due to lack of corresponding source terms:\n\n";
			foreach my $tgt_hash_ref (@target_term_info){
				# my ($status, $customer);
				my %tgt_term_info = %$tgt_hash_ref;
				
				print $tgt_term_info{term}."\n";
			}
		}
	}
	
	my $UTX = _format_utx([$tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $src_custom_exists, $tgt_custom_exists,
					$entry_id_exists, $source_lang, $target_lang, $timestamp, $creator, $license, $directionality, $DictID, $description, $printUTX1_2, \@custom, @output]);
	return $UTX;
} # end _export_utx

sub _set_terms {  #used when exporting to TBX
	my ($key, $value, $term_group, $status_bidirectional, $note_group, $source_term_group) = @_;
	$note_group = TBX::Min::NoteGrp->new() unless defined $note_group;
	if ($key =~ /pos$/ || $key =~ /pos:/){
		
		$value = "other" if $value !~ /verb|adjective|adverb|noun/i;
		
		$term_group->part_of_speech($value);
	}
	elsif ($key =~ /status$/ || $key =~ /status:/){
		$value = "admitted" if $value =~ /provisional/i;
		$value = "preferred" if $value =~ /approved/i;
		$value = "notRecommended" if $value =~ /non-standard/i;
		$value = "obsolete" if $value =~ /forbidden/i;
		$term_group->status($value) if ($value =~ /admitted|preferred|notRecommended|obsolete/i);
		if ($key =~ /status$/)
		{
			$source_term_group->status($value) if ($value =~ /preferred/i);
		}
	}
	elsif ($key =~ /customer/i){
		$term_group->customer($value) unless $value eq '';
	}
	elsif ($key =~ /comment/i) {

		#print "<(^_^)>$key(>^_^)>$value\n";
		if (defined $value)
		{
			my $note = TBX::Min::Note->new({noteValue => $value});
			$note_group->add_note($note);
		}
	}
	else{
		#print "<(^_^)>$key<(^_^<)$value\n";
		if (defined $value)
		{
			my $note = TBX::Min::Note->new({
				noteValue => $value,
				noteKey => $key
			});
			$note_group->add_note($note);
		}
	}
	$term_group->status('preferred') if defined $status_bidirectional; #UTX allows empty term status if bidirectionality flag is true
	return ($term_group, $note_group, $source_term_group); #return to &_export_tbx;
} # end _set_terms

sub _format_utx { #accepts $exists, and @output
	my $args = shift;
	my ($tgt_pos_exists, $status_exists, $customer_exists, $src_note_exists, $tgt_note_exists, $src_custom_exists, $tgt_custom_exists, $entry_id_exists,
		$source_lang, $target_lang, $timestamp, $creator, $license, $directionality, $DictID, $description, $printUTX1_2, $customRef, @output) = @$args;
	my $UTX;
	
	my @custom = @$customRef;
	
	if($printUTX1_2){
		#print header
		$UTX .= "#UTX 1.2;";
		$UTX .= " $source_lang" if defined $source_lang;
		(defined $target_lang) ? ($UTX .= "/$target_lang;") : ($UTX .= ";");
		$UTX .= " $timestamp;" if defined $timestamp;
		$UTX .= " $creator;" if defined $creator;
		$UTX .= " $license;" if defined $license;
		$UTX .= " bidirectional;" if (defined $directionality && $directionality =~ /bidirectional/ && defined $target_lang);
		$UTX .= " $DictID;" if defined $DictID;
		$UTX .= "\n##$description;" if (defined $description); #print middle of header if necessary
		
		if(defined $directionality && $directionality =~ /bidirectional/)
		{
			$UTX .= "\n#term:$source_lang term:$target_lang src:pos"
		}
		elsif(defined$target_lang)
		{
			$UTX .= "\n#src	tgt	src:pos";  #print necessary values of final line of Header
		}
		else
		{
			$UTX .= "\n#term:$source_lang	src:pos";  #print necessary values of final line of Header
		}
		
		$UTX .= "\ttgt:pos" if ($tgt_pos_exists);
		$UTX .= "\tterm status" if ($status_exists && (defined $directionality == 0 or $directionality ne 'bidirectional'));
		$UTX .= "\tsrc:comment" if ($src_note_exists);
		$UTX .= "\ttgt:comment" if ($tgt_note_exists);
		$UTX .= "\tcustomer" if ($customer_exists);
		if (@custom){
			foreach (@custom)
					{
						$UTX .= "\t$_" if (($src_custom_exists && !$tgt_custom_exists) || (!$src_custom_exists && $tgt_custom_exists));
						$UTX .= "\tsrc:$_\ttgt:$_" if ($src_custom_exists && $tgt_custom_exists);
					}
		}
		$UTX .= "\tconcept ID" if ($entry_id_exists);
		
		$status_exists = 0 if (defined $directionality && $directionality =~ /bidirectional/);
		
		foreach my $output_line_ref (@output) {
					
			my ($src_term, $tgt_term, $src_pos, $tgt_pos, $status, $customer, $src_note, $tgt_note, $entry_id, $src_term_info_hash_ref, $tgt_term_info_hash_ref) = @$output_line_ref;
			
			my %src_term_info = %$src_term_info_hash_ref;
			my %tgt_term_info = %$tgt_term_info_hash_ref;
			
			###This block may need to be deleted in the future
			$src_term = "\t" if (!defined $src_term || (defined $src_term && $src_term eq "\t") || (defined $src_term eq ""));
			
			$tgt_term = "" if ((!defined $tgt_term || (defined $tgt_term && $tgt_term eq "\t")  || (defined $tgt_term eq "")) && defined $target_lang);
			$tgt_term = $tgt_term."\t" if (defined $target_lang);
			
			
			$src_pos = "\t" if (!defined $src_pos || (defined $src_pos && $src_pos eq "\t")  || (defined $src_pos eq ""));
			####
			if (defined $src_term && defined $tgt_term){
				$UTX .= "\n$src_term$tgt_term$src_pos";
							
				if ($tgt_pos_exists)
				{ 
					if(defined $tgt_pos && $tgt_pos !~ /^\s*$/)
						{
						$UTX .= "$tgt_pos";
						}else{$UTX .= "\t"}
				}
				if ($status_exists)
				{ 
					if (defined $status && $status !~ /^\s*$/)
						{
							$UTX .= "$status";
						}else{$UTX .= "\t"}
				}
				if ($src_note_exists)
				{ 
					if(defined $src_note && $src_note !~ /^\s*$/)
						{ 
						$UTX .= "$src_note";
						}else{$UTX .= "\t" }
				}
				if ($tgt_note_exists)
				{
					if(defined $tgt_note && $tgt_note !~ /^\s*$/){ 
						$UTX .= "$tgt_note";
					}else {
						$UTX .= "\t";
						}
				}
				if ($customer_exists && defined $customer && $customer !~ /^\s*$/)
				{ 
					if(defined $customer) { 
						$UTX .= "$customer";
					} else{ $UTX .= "\t" }
				}
				if ($entry_id_exists)
				{ 
					if(defined $entry_id && $entry_id !~ /^\s*$/)
					{
						$UTX .= "$entry_id";
					}else{$UTX .= "\t"}
				}
				
				foreach (@custom)
				{
					if (defined $src_term_info{$_})
					{
						$UTX .= "\t".$src_term_info{$_};
					}
				}
			}
			elsif(defined $src_term)
			{
				$UTX .= "\n$src_term$src_pos";
							
				if ($status_exists)
				{ 
					if (defined $status && $status !~ /^\s*$/)
						{
							$UTX .= "$status";
						}else{$UTX .= "\t"}
				}
				if ($src_note_exists)
				{ 
					if(defined $src_note && $src_note !~ /^\s*$/)
						{ 
						$UTX .= "$src_note";
						}else{$UTX .= "\t" }
				}
				if ($customer_exists && $customer !~ /^\s*$/)
				{ 
					if(defined $customer) { 
						$UTX .= "$customer";
					} else{ $UTX .= "\t" }
				}
				if ($entry_id_exists)
				{ 
					if(defined $entry_id && $entry_id !~ /^\s*$/)
					{
						$UTX .= "$entry_id";
					}else{$UTX .= "\t"}
				}
				
				foreach (@custom)
				{
					if (defined $src_term_info{$_})
					{
						$UTX .= "\t".$src_term_info{$_};
					}
				}
			}
		}
	}else
	{
		#print header
		$UTX .= "#UTX 1.11;";
		$UTX .= " $source_lang" if defined $source_lang;
		(defined $target_lang) ? ($UTX .= "/$target_lang;") : ($UTX .= ";");
		$UTX .= " $timestamp;" if defined $timestamp;
		$UTX .= " $creator;" if defined $creator;
		$UTX .= " $license;" if defined $license;
		$UTX .= " bidirectional;" if (defined $directionality && $directionality =~ /bidirectional/ && defined $target_lang);
		$UTX .= " $DictID;" if defined $DictID;
		$UTX .= "\n#$description;" if (defined $description); #print middle of header if necessary
			
		if(defined$target_lang)
		{
			$UTX .= "\n#src	tgt	src:pos";  #print necessary values of final line of Header
		}
		else
		{
			$UTX .= "\n#src	src:pos";  #print necessary values of final line of Header
		}
		
		$UTX .= "\ttgt:pos" if ($tgt_pos_exists);
		$UTX .= "\tterm status" if ($status_exists && (defined $directionality == 0 or $directionality ne 'bidirectional'));
		$UTX .= "\tsrc:comment" if ($src_note_exists);
		$UTX .= "\ttgt:comment" if ($tgt_note_exists);
		$UTX .= "\tcustomer" if ($customer_exists);
		if (@custom){
			foreach (@custom)
					{
						if ($src_custom_exists && $tgt_custom_exists)
						{
							$UTX .= "\tsrc:$_\ttgt:$_" ;
						}
						else
						{
							$UTX .= "\t$_";
						}
					}
		}
		$UTX .= "\tconcept ID" if ($entry_id_exists);
	
		$status_exists = 0 if (defined $directionality && $directionality =~ /bidirectional/);
	
		foreach my $output_line_ref (@output) {
				
			my ($src_term, $tgt_term, $src_pos, $tgt_pos, $status, $customer, $src_note, $tgt_note, $entry_id, $src_term_info_hash_ref, $tgt_term_info_hash_ref) = @$output_line_ref;
		
			my %src_term_info = %$src_term_info_hash_ref;
			my %tgt_term_info = %$tgt_term_info_hash_ref;
			
			###This block may need to be deleted in the future
			$src_term = "\t" if (!defined $src_term || (defined $src_term && $src_term eq "\t") || (defined $src_term eq ""));
			
			$tgt_term = "" if ((!defined $tgt_term || (defined $tgt_term && $tgt_term eq "\t")  || (defined $tgt_term eq "")) && defined $target_lang);
			$tgt_term = $tgt_term."\t" if (defined $target_lang);
			
			
			$src_pos = "\t" if (!defined $src_pos || (defined $src_pos && $src_pos eq "\t")  || (defined $src_pos eq ""));
			####
			if (defined $src_term && defined $tgt_term){
				$UTX .= "\n$src_term$tgt_term$src_pos";
			
				if ($tgt_pos_exists)
				{ 
					if(defined $tgt_pos && $tgt_pos !~ /^\s*$/)
						{
						$UTX .= "$tgt_pos";
						}else{$UTX .= "\t"}
				}
				if ($status_exists)
				{ 
					if (defined $status && $status !~ /^\s*$/)
						{
							$UTX .= "$status";
						}else{$UTX .= "\t"}
				}
				if ($src_note_exists)
				{ 
					if(defined $src_note && $src_note !~ /^\s*$/)
						{ 
						$UTX .= "$src_note";
						}else{$UTX .= "\t" }
				}
				if ($tgt_note_exists)
				{
					if(defined $tgt_note && $tgt_note !~ /^\s*$/){ 
						$UTX .= "$tgt_note";
					}else {
						$UTX .= "\t";
						}
				}
				if ($customer_exists && defined $customer && $customer !~ /^\s*$/)
				{ 
					if(defined $customer) { 
						$UTX .= "$customer";
					} else{ $UTX .= "\t" }
				}
				if ($src_custom_exists)
				{
					foreach (@custom)
					{
						if (defined $src_term_info{$_})
						{
							$UTX .= $src_term_info{$_};
						}
						else
						{
							$UTX .= "\t";
						}
					}
				}
				if ($tgt_custom_exists)
				{
					foreach (@custom)
					{
						if (defined $tgt_term_info{$_})
						{
							$UTX .= $tgt_term_info{$_};
						}
						else
						{
							$UTX .= "\t";
						}
					}
				}
				if ($entry_id_exists)
				{ 
					if(defined $entry_id && $entry_id !~ /^\s*$/)
					{
						$UTX .= "$entry_id";
					}else{$UTX .= "\t"}
				}
				
				
			}
			elsif(defined $src_term)
			{
				$UTX .= "\n$src_term$src_pos";
							
				if ($status_exists)
				{ 
					if (defined $status && $status !~ /^\s*$/)
						{
							$UTX .= "$status";
						}else{$UTX .= "\t"}
				}
				if ($src_note_exists)
				{ 
					if(defined $src_note && $src_note !~ /^\s*$/)
						{ 
						$UTX .= "$src_note";
						}else{$UTX .= "\t" }
				}
				if ($customer_exists && $customer !~ /^\s*$/)
				{ 
					if(defined $customer) { 
						$UTX .= "$customer";
					} else{ $UTX .= "\t" }
				}
				if ($src_custom_exists)
				{
					foreach (@custom)
					{
						if (defined $src_term_info{$_} )
						{
							$UTX .= "\t".$src_term_info{$_};
						}
						else
						{
							$UTX .= "\t";
						}
					}
				}
				if ($entry_id_exists)
				{ 
					if(defined $entry_id && $entry_id !~ /^\s*$/)
					{
						$UTX .= "$entry_id";
					}else{$UTX .= "\t"}
				}
			}
		
		
		
		}
	}
	$UTX =~ s/\n/\r\n/g;
	return $UTX;
} #end _print_utx

_run() unless caller;

__END__
 
=pod
 
=head1 NAME
 
Convert::TBX::UTX - Convert TBX-Min to UTX or UTX to TBX-Min
 
=head1 VERSION
 
version 0.032
 
=head1 SYNOPSIS
 
        use Convert::TBX::UTX 'min2utx';
        min2utx('/path/to/file' [, '/path/to/output']); # string pointer okay too
        
        use Convert::TBX::UTX 'utx2min';
        utx2min('/path/to/file' [, '/path/to/output']); # string pointer okay too
        
        
        (in Terminal)
        -$ tbx2utx '/path/to/file' '/path/to/output'
        -$ utx2tbx '/path/to/file' '/path/to/output'
 
=head1 DESCRIPTION
 
This module converts TBX-Min XML into TBX-Basic XML.
 
=head1 FUNCTIONS
 
=head2 C<min2utx>
 
Converts TBX-Min into UTX format.  'Input' can be either filename or scalar ref containing scalar data.
If given only 'input' it returns a scalar ref containing the converted data.
If given both 'input' and 'output', it will print converted data to the 'output' file.

=head2 C<utx2min>

Converts UTX into TBX-Min format.  'Input' can be either filename or scalar ref containing scalar data.
If given only 'input' it returns a scalar ref containing the converted data.
If given both 'input' and 'output', it will print converted data to the 'output' file.
 
 
=head1 TERMINAL COMMANDS

=head2 C<tbx2utx>
 
Converts TBX-Min into UTX format.  
Input must be filename and Output must be desired output filename.

=head2 C<utx2tbx>

Converts UTX into TBX-Min format. 
Input must be filename and Output must be desired output filename.

=head1 AUTHOR
 
James Hayes <james.s.hayes@gmail.com>,
Nathan Glenn <garfieldnate@gmail.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2014 by Alan Melby.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut

