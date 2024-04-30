EsoExtractDataGui v0.02 (30 April 2024) by Dave Humphrey (dave@uesp.net)

EsoExtractDataGui is a 64-bit Windows application that can perform basic extraction of data from the 
Elder Scrolls Online MNF and DAT files. It uses the same extraction code as the command line
EsoExtractData program but without the ability for manipulating LANG files and other features.

Note: This is the first release of the program and it may contain bugs.


	Installation
===============================================================================
Unzip the EsoExtractData.zip file into a folder of your choice and run the EsoExtractDataGui.exe
program from there.

Note: If you receive an error about a missing DLL you may need to install the Visual C++ 
Redistributable for Visual Studio 2015 available at:

	https://www.microsoft.com/en-ie/download/details.aspx?id=48145


	Basic Usage
===============================================================================
File:New -- Clears the current loaded MNF data file.
File:Load... -- Loads a new MNF data file. By default the program tries to find and load from the ESO 
	installation directory.
File:Live... -- Attempts to load the standard MNF files from the Live installation of the game. If
	the installation folder cannot be found you'll have to use the general Load... option.
File:PTS... -- Attempts to load the standard MNF files from the PTS installation of the game. If
	the installation folder cannot be found you'll have to use the general Load... option.
File:Exit -- Exit the program
View:Options -- Edit program options.
	Parse GR2 Files -- If checked any GR2 file is loaded/parsed and a filename set based on the
		GR2 model and components names.
	Save MNF File Table -- Saves a CSV file MNF.txt in the extraction directory containing a list
		of all files in the loaded MNF.
	Save ZOSFT File Table -- Saves a CSV file ZOS.txt in the extraction directory containing a list
		of all files in the ZOSFT directory (if found in the current MNF).
	Convert RIFF Files -- Tries to convert RIFF sound files to a playable format by modifying the 
		file header.
	Show Debug Output -- Outputs more messages and information during extraction.
Help:About -- Shows a version dialog and this README file.


	Main Interface
===============================================================================
Filter -- Specify a text string to filter entries in the current MNF. Only filenames containing this
	string will be displayed and extracted. Entries with no filename will not be displayed.
Archives -- Specify which archive indexes (0...) should be displayed and extracted. This can be any 
	of the following formats:
						All archives
			1			Single archive
			4-10		Range of archives
			1,2,3		Multiple archives
			1,4-9,10	Mix of formats
Extract -- Attempt to extract all the currently displayed files to a choosen directory.


	Extraction
===============================================================================
After pressing the "Extract" button on the top-right of the main dialog and choosing an output
directory the main extraction dialog will be displayed:

	Log -- A text showing the current status of extraction and any errors.
	Progress Bar -- Shows the overall progress of the extraction.
	Stop -- Abort the extraction process (this changes to Finish once extraction is done)

