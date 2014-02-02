#!usr/bin/perl

#This test tests that an output file is created.  The other tests check more specific conversion data.

use FindBin qw($Bin);

use feature "say";
use Path::Tiny;

path("$Bin/corpus/Output.test")->remove;

my $utx2tbx = path("$Bin/../bin/utx2tbxmin.pl");
my $tbx2utx = path("$Bin/../bin/tbxmin2utx.pl");
my $utx_datafile = path("$Bin/corpus/Sample.utx");
my $tbx_datafile = path("$Bin/corpus/Sample.tbx");

my $outfile = path("$Bin/corpus", "Output.test");

system(qq{"$^X" -Ilib "$utx2tbx" "$utx_datafile" "$outfile"});

if ( path("$Bin/corpus/Output.test")->exists ) {
	say "utx2tbxmin script conversion SUCCESS.";
	path("$Bin/corpus/Output.test")->remove;
}else{
	say "utx2tbxmin script conversion FAILURE.";
}

system(qq{"$^X" -Ilib "$tbx2utx" "$tbx_datafile" "$outfile"});

if ( path("$Bin/corpus/Output.test")->exists ) {
	say "tbxmin2utx script conversion SUCCESS.";
	path("$Bin/corpus/Output.test")->remove;
}else{
	say "tbxmin2utx script conversion FAILURE.";
}