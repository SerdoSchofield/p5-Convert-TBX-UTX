UTX-TBXnny-Converter
====================

A set of converters for termbase exchange files in UTX 1.11 format to TBX:NNY (no name yet, aka TBX-Min) and back.


There are three converters provided:

1: UTXtoTBXminConverter.pl  ->  This converts UTX version 1.11 (see http://www.aamt.info/english/utx/ for specifications) to TBXnny/TBX-Min

2: TBXtoUTXConverter.pl  ->  This converts TBXnny/TBX-Min to UTX version 1.11

3: DualConverter(UTX-TBXmin).pl  ->  This is a combination of the first two converters.  It takes in either TBX or UTX 1.11 files and outputs their respective counterpart (TBX->UTX, UTX->TBX)


Usage:  
======

*~$ perl (Converter Name) (Input .tbx or .utx) (Output .tbx or .utx)*

***All arguments must have proper file extenstions to work.***



Example (TBX-Min to UTX): DualConverter(UTX-TBXmin).pl Input.tbx Output.utx

Example (UTX to TBX-Min): DualConverter(UTX-TBXmin).pl Input.utx Output.tbx

