UTX-TBXnny-Converter
====================

A set of converters for termbase exchange files in UTX 1.11 (see http://www.aamt.info/english/utx/ for specifications) format to TBX:NNY (no name yet, aka TBX-Min) and back.


There are three converters provided:

1: UTXtoTBXminConverter.pl  ->  This converts UTX version 1.11 to TBXnny/TBX-Min

2: TBXtoUTXConverter.pl  ->  This converts TBXnny/TBX-Min to UTX version 1.11

3: DualConverter_UTX_TBXmin.pm  ->  This is a combination of the first two converters.  It takes in either TBX or UTX 1.11 files and outputs their respective counterpart (TBX->UTX, UTX->TBX)


Usage:  
======
***Required Modules: TBX::Min, DateTime***

*~$ perl (Converter Name) (--tbx or --utx depending on Input type) (Input) (Output)*




Example (TBX-Min to UTX): DualConverter_UTX_TBXmin.pm Input.tbx Output.utx

Example (UTX to TBX-Min): DualConverter_UTX_TBXmin.pm Input.utx Output.tbx
