#!usr/bin/perl

package t::TestUTX_TBX;
use Test::Base -base;

1;

package t::TestUTX_TBX::Filter;
use Test::Base::Filter -base;
use strict;
use warnings;
use Converter::DualConverter_UTX_TBXmin;

sub convert_utx {
	my ($self, $data) = @_;
	my $converted = Converter::DualConverter_UTX_TBXmin->convert_utx($data);
	$converted;
}

sub convert_tbx {
	my ($self, $data) = @_;
	my $converted = Converter::DualConverter_UTX_TBXmin->convert_tbx($data);
	return $converted;
}

sub _format_out {
	my ($self, $data) = @_;
	chomp($data);
	return $data;
}