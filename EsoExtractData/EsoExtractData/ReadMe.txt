
	EsoExtractData v0.17 (formally EsoExportMnf)
	by Dave Humphrey (dave@uesp.net)
	7 November 2014
-------------------------------
EsoextractData is a simple Windows command line application that loads and exports
data found in ESO's (Elder Scrolls Online) MNF and DAT files.

WARNING: This application is very early in development and will break easily.
User caution is advised.


     Assumptions/Requirements
-------------------------------

   - There are a few DLLs that must be in the same directory as the EXE.
   - The MNF files are in the same directory as the match DAT files: i.e.
     the file game.mnf is in the same directory as game0000.dat.
   - You have enough free disk space to export files (up to 120GB).


     Basic Usage
-------------------------------
Basic help on command line parameters and options can be viewed by:

     esoextractdata -h

Simple usage is just:

     esoextractdata d:\eso\somepath\data\game.mnf d:\esoexport\

Which will try and load the game.mnf and export all its sub-files (contained
in the DAT files) to the "d:\esoexport\" path. If filename data can be found
then it will be used but if not files will be output in the format:

    OUTPUTPATH\NNN\0123456.dat

where NNN is the archive index and 0123456.dat is the index of the file as it
is found in the MNF file (i.e., first file in the MNF index is 0000000.dat).

=======================
       WARNING:
=======================
Exporting all files from all 3 MNF files will take over 1 hour and require some
120GB of disk free space.


     Converting DDS Files
-------------------------------
You can try to convert DDS files to PNG automatically by:

    esoextractdata game.mnf d:\esoexport\ -c

This works for most DDS files but some will crash the file loader for an unknown
reason and it greatly slows down the exporting process.

Alternatively, you can use the CONVERTDDS.BAT file to convert all DDS files in
a path (recursively) to PNGs. It uses the NCONVERT application:

	http://www.xnview.com/en/nconvert.php 

		
     Advanced Usage
-------------------------------
There are several more advanced command line options which may be useful:

	esoextractdata game.mnf .\export\ -k
		Doesn't export any subfiles (useful to just export file tables or
		to test loading).

	esoextractdata eso.mnf .\export\ -s 123 -e 456
		Manually specify the start and end index to export. Useful to break
		up the export into smaller chunks or to refresh just a select group
		of files.

	esoextractdata eso.mnf .\export\ -a 123
	    Only export a specific archive index (i.e., all files from
	    eso0123.dat).

	esoextractdata eso.mnf .\export\ -f 1234
		Only export a single subfile with the given file index. Note that
		the file index is that which is stored in the MNF file table and
		appears to identify the file.

	esoextractdata eso.mnf .\export\ -z zosft.txt
	    Save the ZOS file table (if found) to the given filename in a CSV
		format.

	esoextractdata eso.mnf .\export\ -m mnfft.txt
	    Save the MNF file table to the given filename in a CSV format.
		
	esoextractdata eso.mnf .\export\ -m mnfft.txt -k 80
		Start extracting at data file index 80 (eso0080.dat).
		
	esoextractdata -l en.lang
		Convert the given LANG file into a CSV (en.lang.csv).
 


     Notes
-------------------------------
   - v0.16 has been updated to support the patch for the 14 Mar 2014 beta.
   - v0.15 has been updated to support the patch for the 8 Feb 2014 beta.
   - One known issue is that there are multiple files from eso0000.dat which
     cannot be uncompressed due to having an unknown/invalid format.