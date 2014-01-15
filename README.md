UTX-TBXnny-Converter
====================

A dual converter for Termbase Exchange files in UTX 1.11 (see http://www.aamt.info/english/utx/ for specifications) format to TBX-Min.


lib/TBX/UTX.pm  ->   This converter takes in either TBX or UTX 1.11 files and outputs their respective counterpart (TBX->UTX, UTX->TBX)


Usage:  
======
***Required Modules: TBX::Min, DateTime***

*~$ perl (Converter Name) (--tbx or --utx depending on Input type) (Input) (Output)*




Example (TBX-Min to UTX): DualConverter_UTX_TBXmin.pm --tbx Input.tbx Output.utx

Example (UTX to TBX-Min): DualConverter_UTX_TBXmin.pm --utx Input.utx Output.tbx
