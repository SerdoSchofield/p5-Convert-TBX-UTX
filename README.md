UTX-TBXnny-Converter
====================

A dual converter for Termbase Exchange files in UTX 1.11 (see http://www.aamt.info/english/utx/ for specifications) format to TBX-Min.


lib/TBX/UTX.pm  ->   This converter takes in either TBX or UTX 1.11 files and outputs their respective counterpart (TBX->UTX, UTX->TBX)


Usage:  
======
***Required Modules: TBX::Min, DateTime***

*~$ perl (Converter Name) (--tbx2utx or --utx2tbx depending on the conversion direction) (Input) (Output)*




Example (TBX-Min to UTX): UTX.pm --tbx2utx Input.tbx Output.utx

Example (UTX to TBX-Min): UTX.pm --utx2tbx Input.utx Output.tbx
