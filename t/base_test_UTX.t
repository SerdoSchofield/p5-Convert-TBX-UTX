#!usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Path::Tiny;

my $convertUTX_test = path("$Bin/UTX-TBX", "convertUTX.t");

system( qq("$^X" -I "../p5-TBX-Min/lib" -Ilib "$convertUTX_test") );