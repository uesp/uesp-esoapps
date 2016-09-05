
	EsoExtractData v0.29 (formally EsoExportMnf)
	by Dave Humphrey (dave@uesp.net)
	5 September 2016
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

	esoextractdata -l en.lang -p
		Convert the given LANG file into a CSV (en.lang.csv) using a format
		that can be used to convert directly to PO (Pootle) files. The CSV
		file will have 3 columns (location, source, target) with the location
		data having the format "ID-UNKNOWN-INDEX" to uniquely identify the
		text. Also outputs the file "en.lang.id.txt" which contains a list
		of all the text IDs in a single column text file which is needed if
		you wish to convert a text file back into a LANG file.

	esoextractdata -l en.lang -o test.csv
		Manually specify the output file for CSV/LANG conversions. Also outputs
		the ID file "test.csv.id.txt"

	esoextractdata -x en.csv
		Convert the given CSV file into a LANG (en.lang). The CSV file should
		be in the same format as one created from the "-l" option including:
		    - One header row: ID,Unknown,Index,Offset,Text
			- Column order is currently fixed.
			- Offset column is recomputed when saving.
 			- Convert \r, \n and \" in texts to their respective characters.
 			- Text column must be quoted to preserve commas in texts.
 			- Resulting LANG file will be larger than the original due to 
			  duplicate texts not being merged.

    esoextractdata -x en.csv -p
	    Convert a PO compatible CSV file into a LANG file.
		
	esoextractdata -x en.csv -p -o newfile.lang
	    Convert a PO compatible CSV file into a LANG file of the given name.

	esoextractdata -l en.lang -t
	    Convert the LANG file to a plain text file (one text per line).

	esoextractdata -l en.lang -t -p
	    Convert the LANG file to a plain text file that is compatible with
		Pootle (txt2po) with an extra blank line between texts.
		
	esoextractdata -x file.lang.txt -i file.id.txt -t 
		Converts the given text and ID files into a LANG file file.lang. Assumes 
		the two	input text files match and have the same length.
		
	esoextractdata -x file.lang.txt -i file.id.txt -t -o newfile.lang
		Same as the previous command but saves the result to newfile.lang.
		
	esoextractdata -x file.lang.txt -i file.id.txt -t -p
		Converts the given text and ID files into a LANG file. The input text file
		should have a blank line following each text and should have twice the
		number of lines as the ID file.

		WARNING: The following is extremely new and experimental. Use with caution
		         and make backups of all files.
	esoextractdata -d file1.lang file2.lang
	esoextractdata -d file1.lang file2.csv
	esoextractdata -d file1.csv file2.lang
	esoextractdata -d file1.txt file2.lang -i1 file1.id.txt
	esoextractdata -d file1.lang file2.txt -i2 file2.id.txt
	esoextractdata -d file1.txt file2.txt -i1 file1.id.txt -i2 file2.id.txt
	...
		Compares two LANG/TXT/CSV files for changes, additions and removals. Will save 4
		files (either file2... or the output file specified with -o):
		    file2.added.csv    - Rows in file2 but not in file1
			file2.removed.csv  - Rows in file1 but not in file2
			file2.changed.csv  - Rows that have different texts between both files. Columns are:
										[id columns]..., [new], [old], [translated]
			file2.lang         - A new LANG/TXT file that has all texts removed/changed/added in file2.

		If the ID files used for -i and -i1 are the same then one of the parameters can be omitted.
		For example, the following commands would be identical:
 				EsoExtractData -g tr.txt -i id.txt -d old.txt new.txt -i1 id.txt -i2 new.id.txt
 				EsoExtractData -g tr.txt -i id.txt -d old.txt new.txt            -i2 new.id.txt
 				EsoExtractData -g tr.txt           -d old.txt new.txt -i1 id.txt -i2 new.id.txt

	esoextractdata -g orig.lang -d file1.lang file2.lang
	esoextractdata -g orig.csv -d file1.lang file2.lang
	esoextractdata -g orig.txt -i orig.id.txt -d file1.lang file2.lang
	     The -g option uses the following LANG/TXT/CSV file for any text that hasn't been changed or 
		 removed. In this way you can keep translated lines from orig.XXX and update any text that
		 has been changed/added/removed in a new LANG file.


     Notes
-------------------------------
   - See http://www.uesp.net/wiki/Online:EsoExtractData for more information.
   - v0.16 has been updated to support the patch for the 14 Mar 2014 beta.
   - v0.15 has been updated to support the patch for the 8 Feb 2014 beta.
   - One known issue is that there are multiple files from eso0000.dat which
     cannot be uncompressed due to having an unknown/invalid format.