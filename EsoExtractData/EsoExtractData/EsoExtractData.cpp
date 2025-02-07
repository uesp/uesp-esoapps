/*
 * EsoExtractData - by Dave Humphrey (dave@uesp.net)
 *
 * A Windows command line program that extracts data/files from ESO (Elder Scrolls Online)
 * MNF and DAT game data files.
 *
 * Use "EsoExtractData -h" for basic help.
 *
 * CONTRIBUTORS
 *		- Kriskras99: Patch for reconstructing GR2 filenames from model info.
 *
 * HISTORY
 *
 * v0.17 -- 7 November 2014
 *		- Added missing , to MNF file table CSV export.
 *	    - Added the "UserData" column to the ZOSFT file table CSV export. Currently
 *		  is the number of file entries found in the MNF data.
 *		- Converts any .lang file to a CSV format if it can.
 *		- Language file now exported in a normal CSV format (with commas and internal
 *		  double-quotes escaped to \").
 *		- Added the -b/--beginarchive option to start at a specific DAT file index.
 *		- Added the -l/--lang option to convert a .LANG file to a CSV.
 *
 * v0.18 -- 23 November 2014
 *		- Fixed output of Game.Mnf with filenames.
 *
 * v0.20 -- 9 April 2015
 *		- All cells are quoted when saving a LANG file as a CSV.
 *		- Translate DOS linefeeds in LANG file texts as "\r" (was "\n" as previously).
 *		- Convert a language CSV file back to a LANG file using the "-x" option:
 *			- First row must be a header: ID,Unknown,Index,Offset,Text
 *			- Column order is currently fixed.
 *			- Convert \r, \n and \" to their respectice characters.
 *			- Text column must be quoted to preserve commas in texts.
 *			- Resulting LANG file will be larger than the original due to duplicate texts
 *			  not being merged.
 *			- Output filename will be the same filename with ".CSV" replaced with ".LANG".
 *
 * v0.21 -- 9 April 2015
 *		- Escape quotes in text as double-quotes ("") instead of \" in CSV files to import correctly.
 *		- Added the "-o" option for specifying the output filename for -l/-x commands.
 *		- Added the "-p" option for outputting LANG CSV files in a PO compatible format.
 *
 * v0.22 -- 9 April 2015
 *		- Added the "--posourcetext" to use the source text column (2) in a PO-CSV file when
 *		  converting it to a LANG file.
 *		- Assume a PO-CSV file (3 columns) when the -p option is used with -x.
 *		- Fix the location column (1) when creating a PO-CSV file (offset was used instead of index).
 *
 * v0.23 -- 11 April 2015
 *		- Added the "-t" option to output LANG file in a plain text format.
 *
 * v0.24 -- 9 June 2015
 *		- Added the "-i" option to input an ID text.
 *		- An ID file (.id.txt) is output when converting a LANG file. For example:
 *					EsoExtractData.exe -l file.lang 
 *		  outputs the file "file.lang.id.txt".
 *		- Convert a text file along with an ID file to a LANG file.
 *				Using a PO TEXT file (blank line between lines):
 *						EsoExtractData.exe -i file.id.txt -p -t -x file.lang.txt
 *			    Using a TEXT File:
 *						EsoExtractData.exe -i file.id.txt -t -x file.lang.txt
 *				Using a PO TEXT file to new LANG file:
 *						EsoExtractData.exe -i file.id.txt -p -t -x file.lang.txt -o newfile.lang
 * 
 * v0.25 -- 18 August 2015
 *		- Added the "-d" option for comparing LANG/CSV/TXT files:
 *				EsoExtractData.exe -d file1.lang file2.lang
 *				EsoExtractData.exe -d file1.lang file2.csv
 *				EsoExtractData.exe -d file1.csv file2.lang
 *				EsoExtractData.exe -d file1.csv file2.csv
 *				EsoExtractData.exe -d file1.txt file2.lang -i1 file1.id.txt
 *		- Added the "-i2" option for specifying the second ID file when comparing files:
 *				EsoExtractData.exe -d file1.lang file2.txt -i2 file2.id.txt
 *				EsoExtractData.exe -d file1.txt file2.txt -i1 file1.id.txt -i2 file2.id.txt
 *		- Added the "-g" option for specifying a source text for unchanged entries.
 *
 * v0.26 -- 19 August 2015
 *		- When using -d the changed CSV file contains the original translation text supplied
 *		  with -g if it exists in the last column ([id columns], [new], [old], [translated]).
 *		- If the ID file used with -i and -i1 is the same you can omit one or the other parameter on
 *		  the command line. For example, the following commands would be identical:
 *				EsoExtractData -g tr.txt -i id.txt -d old.txt new.txt -i1 id.txt -i2 new.id.txt
 *				EsoExtractData -g tr.txt -i id.txt -d old.txt new.txt            -i2 new.id.txt
 *				EsoExtractData -g tr.txt           -d old.txt new.txt -i1 id.txt -i2 new.id.txt
 *
 * v0.27 -- 4 February 2016
 *		- Added support for the 1.9 update on PTS (Thieves Guild DLC) for finding the ZOSFT in the
 *		  ESO.MNF file. File index for the ZOSFT was changed from 0xFFFFF to 0xFFFFFF.
 *
 * v0.28 -- 8 March 2016
 *		- Fixed a crash when extracting Game.Mnf data from the Thieves Guild DLC release.
 *
 * v0.29 -- 5 September 2016
 *		- Fixed an infinite loop due to a truncated compressed file in file eso0002.dat from the update 12 PTS.
 *
 * v0.30 -- 18 January 2017
 *		- Added more matching magic bytes for recognizing GR2 (Granny) files.
 *		- GR2 model/animation files are output acccording to their internal original path/filename in 
 *		  addition to their ZOSFT filename (if it exists) and numeric file index. The original path will be
 *		  created under the "Granny" path in the base export path.
 *		- Recognize binary Havok files and assign them with the HKX extension.
 *		- Recognize file data containing compressed sub-files and assign them the EsoFileData extensions.
 *		- Recognize file data containing unknown ID data and assign them the EsoIdData extensions.
 *		- Recognize file data for the PSB2 format (unsure exactly what it is though).
 *		- Recognize file data containing more text data (including books) and give it the "TextData" extension.
 *		- Recognize "FFX" file data.
 *		- Recognize UTF-8 text files starting with the byte order mark EF BB BF and give the extension "TXT".
 *		- Recognize the unknown XV4 file which seems to be just a DDS with 12 bytes of extra header data and
 *		  4 bytes of extra footer. The original file and a DDS version without the extra header is saved.
 *		- Include the "--noparsegr2" parameter to prevent the parsing of GR2 files to extract their
 *		  original filename.
 *		- Added the "--extractsubfile" option for extracting compressed data from some file types:
 *				--extractsubfile none		: Default, does nothing
 *				--extractsubfile combined	: Outputs all compressed files in one large file.
 *				--extractsubfile seperate	: Outputs files individually (Warning: This creates over
 *											  1 million files and adds several hours to the extraction).
 *
 *		  The "combined" file format is output in the following format:
 *				Header (same 16 bytes as original compressed file)
 *					dword MagicBytes
 *					dword Unknown1
 *					dword NumRecords
 *					dword Unknown2
 *				x(0...N) Record Data (variable sized)
 *					dword MagicBytes = "####"
 *					dword Index
 *					dword UncompressedSize1
 *					dword UncompressedSize2
 *					dword CompressedSize
 *					dword Index					(from index file if found)
 *					dword OrigFileOffset		(from index file if found)
 *					dword UncompressedSize
 *					byte UncompressedData[UncompressedSize]
 *
 * v0.31 -- 17 April 2017
 *		- Fixed extraction of the ZOSFT from ESO MNF in update 14 PTS files. Unsure how this 
 *		  will work with prior file versions however (is fine with update 13 at least).
 *
 * v0.32 -- 23 October 2018
 *		- Fixed crash from null pointer reference received from Granny API.
 *		- Updated Granny2.dll file which permits more original GR2 filenames to be extracted.
 *
 * v0.33 -- 19 April 2019
 *		- Added the "-n" / "--filename" option.

 * v0.34 -- 30 May 2019
 *		- Fix default for the "-n" / "--filename" option.
 *
 * v0.40 -- 6 February 2020
 *		- Changed to a 64 bit build (to support Oodle decompression).
 *		- Supports the new DAT format introduced in update 25 PTS.
 *		- Skips empty DAT files which reduces the number of error messages.
 *		- Added the "--oodleraw" option which saves subfiles in their original Oodle compression format.
 *
 * v0.41 -- 17 September 2020
 *		- Removed the -c/--convertdds option.
 *		- Added the --luafilelist option.
 *		- Added the --luastartindex option.
 *		- Added the -y/--fileext option.
 *
 * v0.42 -- 30 April 2021
 *		- Removed extra "." in DDS files exported from XV4 files.
 *		- Model/animation names from GR2 Granny files are used to output named files if possible.
 *
 * v0.50 -- 28 June 2021
 *		- RIFF files are automatically converted to OGG/WAV files. Use the "--noriffconvert" command line option to disable.
 *
 * v0.51 -- 28 April 2022
 *		- Added the --matchfilename option for only outputting files that contain the given sub-string.
 *		- Added the --baselangfile option that uses the given LANG file as for base/missing entries when creating a new LANG file.
 *
 * v0.52 -- 25 August 2022
 *		- Added the --debugoutput/-v option for outputting additional messages to the log and output. Default is off (so less messages).
 *		  Set a bunch of error/warning messages to debug only. Note that all messages are still saved to the log file.
 *		- Fixed the format of the subfile index which prevents a bunch of error messages from the ESO00000.DAT file.
 *		- Adjusted tab levels of text output for a little neater visual output.
 *		- Introduced the EsoExtractDataGui program.
 *		- Fixed a memory leak when converting RIFF files to WAV.
 *
 * v0.53 -- 30 April 2024
 *		- Fixed loading of ZOSFT from update 42pts patch 2.
 *		- Fixed the export of ZOSFT text files.
 */

#include "stdafx.h"
#include "stddef.h"
#include <conio.h>
#include <string>
#include <assert.h>
#include <sstream>
#include <iostream>
#include <vector>
#include <algorithm>
#include <stdarg.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include "EsoMnfFile.h"
#include "EsoZosftFile.h"
#include "CmdParamHandler.h"
#include "EsoLangFile.h"
#include "EsoCsvFile.h"
#include "oodle/oodle.h"
#include <memory>

using namespace eso;

#define RENAME_ASSETS false

const int DATA_HEADER_SIZE = 0x0E;
const int ZOSFT_HEADER_SIZE1 = 0x2D;
const int ZOSFT_MIDHEADER_SIZE = 0x08;

//const int OFFSET = 14;   //Game00000.dat
//const int FILE_DELTA = 0;

const int OFFSET = 0x29;   //Game.mnf
const int FILE_DELTA = 0x08;


const int MNF_OFFSET = 0x29;    //Game.mnf
const int MNF_FILE_DELTA = 0x08;

//const int OFFSET = 0x540;     //eso.mnf
//const int FILE_DELTA = 0x08;


const TCHAR DATAFILE[] = _T("game0000.dat");

const TCHAR* OUTPUT_PATH = _T("d:\\esoexport\\");
const TCHAR* INPUT_PATHS[] = { 
		_T("D:\\The Elder Scrolls Online Beta\\game\\client\\"), 
		_T("D:\\The Elder Scrolls Online Beta\\depot\\"),
		_T("D:\\The Elder Scrolls Online Beta\vo_en\\")
};


typedef std::vector<std::string> CSimpleTextFile;


struct esosubfile_t
{
	eso::byte*  pFileData;
	size_t AllocatedSize;
	size_t FileSize;

	size_t StartOffset;
	size_t EndOffset;

	esosubfile_t() : pFileData(nullptr), FileSize(0), StartOffset(0), EndOffset(0), AllocatedSize(0)
	{
	}

	~esosubfile_t()
	{
		Destroy();
	}

	void Destroy (void)
	{
		FileSize = 0;
		delete [] pFileData;
		pFileData = nullptr;
		StartOffset = 0;
		AllocatedSize = 0;
		EndOffset = 0;
	}

	void AppendData (const eso::byte* pData, const size_t Size)
	{
		if (pFileData == nullptr)
		{
			FileSize = Size;
			AllocatedSize = Size * 2;
			pFileData = new eso::byte[AllocatedSize+1];
			memcpy(pFileData, pData, Size);
		}
		else if (FileSize + Size < AllocatedSize)
		{
			AllocatedSize = (FileSize + Size)*2;
			eso::byte* pNewData = new eso::byte[AllocatedSize+1];
			memcpy(pNewData, pFileData, FileSize);
			memcpy(pNewData + FileSize, pData, Size);
			FileSize += Size;
			delete[] pFileData;
			pFileData = pNewData;
		}
		else 
		{
			memcpy(pFileData + FileSize, pData, Size);
			FileSize += Size;
		}

	}

	int GetInputSize(void) { return (int) (EndOffset - StartOffset); }

};


bool InflateSubFile (esosubfile_t& SubFile, FILE* pInputFile, const long FileSize)
{
	const int CHUNK_SIZE = 262144;
    eso::byte InputBuffer[CHUNK_SIZE+64];
	eso::byte OutputBuffer[CHUNK_SIZE+64];
	z_stream Stream;
	long CurOffset;
	long OutputSize;
	int Result;

	SubFile.Destroy();
	SubFile.StartOffset = ftell(pInputFile);

	Stream.zalloc = Z_NULL;
    Stream.zfree = Z_NULL;
    Stream.opaque = Z_NULL;
    Stream.avail_in = 0;
    Stream.next_in = Z_NULL;

    Result = inflateInit(&Stream);

    if (Result != Z_OK)
	{
		PrintError("Error: Failed to initialize the zlib stream!");
		return false;
	}

		/* Decompress until deflate stream ends or end of file */
	do {
		if (Stream.avail_in == 0)
		{
			SubFile.EndOffset = ftell(pInputFile);
			CurOffset = ftell(pInputFile);
			PrintError("\t0x%08X: Loading more input data...", CurOffset);

			if (CurOffset < 0) 
			{
				inflateEnd(&Stream);
				PrintError ("Error: Failed to get current offset in source file!");
				return false;
			}
			else if (CurOffset == FileSize)
			{
				PrintError ("Reached end of input file.");
				break;
			}
			else if (CurOffset > FileSize)
			{
				PrintError ("Warning: Exceeded end of input file by 0x%8X bytes!", CurOffset - FileSize);
				break;
			}

			Stream.avail_in = fread(InputBuffer, 1, CHUNK_SIZE, pInputFile);
			Stream.next_in = InputBuffer;
			SubFile.EndOffset = ftell(pInputFile);

			if (ferror(pInputFile)) {
				inflateEnd(&Stream);
				PrintError("Error: Failed to read bytes from input file!");
				return false;
			}

			if (Stream.avail_in == 0)
			{
				break;
			}
		}

			/* run inflate() on input until output buffer not full */
		do {
			Stream.avail_out = CHUNK_SIZE;
			Stream.next_out = OutputBuffer;

			Result = inflate(&Stream, Z_NO_FLUSH);

			switch (Result) {
			case Z_NEED_DICT:
				Result = Z_DATA_ERROR;     /* and fall through */
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
			case Z_STREAM_ERROR:
			//case Z_BUF_ERROR:
				inflateEnd(&Stream);
				PrintError("Error: Failed to uncompress data stream!");
				return false;
			}

			OutputSize = CHUNK_SIZE - Stream.avail_out;
			SubFile.AppendData(OutputBuffer, OutputSize);
		} while (Stream.avail_out == 0);

		/* done when inflate() says it's done */
	} while (Result != Z_STREAM_END);
	
	SubFile.EndOffset = ftell(pInputFile);
	inflateEnd(&Stream);

	PrintError("Inflated 0x%X bytes from input starting at 0x%X with a length of 0x%X", SubFile.FileSize, SubFile.StartOffset, SubFile.GetInputSize());
	return true;
}


std::string CreateOutputPath(const TCHAR* pFilename, const TCHAR* pBaseOutputPath)
{
	std::string OutputPath(pBaseOutputPath);
	TCHAR SourceDrive[_MAX_DRIVE+4];
	TCHAR SourceDir[_MAX_DIR+4];
	TCHAR SourceFilename[_MAX_FNAME+4];
	TCHAR SourceExt[_MAX_EXT+4];
	errno_t ErrResult;

	if (OutputPath.compare(OutputPath.length()-1, 1, "\\") != 0) OutputPath += '\\';

	ErrResult = _tsplitpath_s(pFilename, SourceDrive, SourceDir, SourceFilename, SourceExt);

	if (ErrResult != 0)
	{
		PrintError("Error splitting path '%s' into components!", pFilename);
		return OutputPath;
	}
	
	OutputPath += SourceFilename;
	OutputPath += SourceExt;
	OutputPath += '\\';

	PrintError ("OutputPath() = %s", OutputPath.c_str());
	return OutputPath;
}


bool LoadSimpleTextFile (const std::string Filename, CSimpleTextFile& TextFile)
{
	std::ifstream inFile(Filename);
	std::string Line;

	TextFile.clear();

	if (!inFile) return PrintError("Error: Failed to open '%s' for input!", Filename.c_str());

	while (std::getline(inFile, Line)) 
	{
		TextFile.push_back(Line);
	}

	inFile.close();
	return true;
}


bool ProcessZOSFT (const TCHAR* pFilename, const char* pOutputPath)
{
	const int CHUNK_SIZE = 262144;
	std::string OutputFilename;
	eso::byte OutputBuffer[CHUNK_SIZE+64];
	char BaseOutputFilename[_MAX_FNAME + 64];
	z_stream Stream;
	FILE* pDestFile;
	int Result;
	int OutputFileCount = 0;
	int OutputSize;

	FILE* pFile = fopen(pFilename, "rb");

	if (pFile == NULL)
	{
		PrintError ("Error: Failed to open the ZOSFT file '%s'!", pFilename);
		return false;
	}

	fseek(pFile, 0, SEEK_END);
	long FileSize = ftell(pFile);
	fseek(pFile, 0, SEEK_SET);

	if (FileSize <= 0)
	{
		PrintError("Error: Invalid file size for ZOSFT!");
		fclose(pFile);
		return false;
	}

	char* pInputBuffer = new char[FileSize + 1024];
	fread(pInputBuffer, 1, FileSize, pFile);
	fclose(pFile);

	if (memcmp(pInputBuffer, "ZOSFT", 5) != 0)
	{
		PrintError("Warning: File is not a ZOSFT format!");
		delete[] pInputBuffer;
		return false;
	}

	PrintError("Found ZOSFT data in last file!");

	Stream.zalloc = Z_NULL;
    Stream.zfree = Z_NULL;
    Stream.opaque = Z_NULL;
    Stream.avail_in = 0;
    Stream.next_in = Z_NULL;

    Result = inflateInit(&Stream);

    if (Result != Z_OK)
	{
		delete[] pInputBuffer;
		return false;
	}

	int InputPos = ZOSFT_HEADER_SIZE1;
	eso::byte* pInputPtr = (eso::byte *) pInputBuffer + InputPos;

	Stream.avail_in = FileSize - InputPos;
	Stream.next_in = pInputPtr;

	while (Stream.avail_in > 0)
	{	
		//pInputPtr = pInputBuffer + Stream.total_in;

		if (OutputFileCount == 8) 
		{
			PrintError("Manually stopping ZOSFT deflation...");
			break;
		}

		if (OutputFileCount > 0)
		{
			Stream.avail_in -= ZOSFT_MIDHEADER_SIZE;
			Stream.next_in  += ZOSFT_MIDHEADER_SIZE;
		}

		if (OutputFileCount == 3 || OutputFileCount == 6)
		{
			Stream.avail_in -= 0x12;
			Stream.next_in  += 0x12;
		}
	
		PrintError("ZOSFT: Processing input at 0x%08X", FileSize - Stream.avail_in);

		++OutputFileCount;
		_snprintf(BaseOutputFilename, _MAX_FNAME, ".%d", OutputFileCount);
		OutputFilename = pFilename;
		OutputFilename += BaseOutputFilename;
		PrintError("%d: Processing ZOSFT output file...", OutputFileCount);
		
		pDestFile = fopen(OutputFilename.c_str(), "wb");

		if (pDestFile == NULL)
		{
			inflateEnd(&Stream);
			PrintError("Error: Failed to open output file '%s' for writing!", OutputFilename.c_str());
			delete[] pInputBuffer;
			return false;
		}
		
			/* decompress until deflate stream ends or end of file */
		do {
			if (Stream.avail_in == 0) break;

				/* run inflate() on input until output buffer not full */
			do {
				Stream.avail_out = CHUNK_SIZE;
				Stream.next_out = OutputBuffer;

				Result = inflate(&Stream, Z_NO_FLUSH);
				//assert(Result != Z_STREAM_ERROR);  /* state not clobbered */

				switch (Result) {
				case Z_NEED_DICT:
					Result = Z_DATA_ERROR;     /* and fall through */
				case Z_DATA_ERROR:
				case Z_MEM_ERROR:
				case Z_STREAM_ERROR:
				//case Z_BUF_ERROR:
					goto ENDDEFLATE;
					inflateEnd(&Stream);					
					PrintError("Error: Failed to uncompress data stream!");
					fclose(pDestFile);
					delete[] pInputBuffer;
					return false;
				}

				OutputSize = CHUNK_SIZE - Stream.avail_out;

				if (fwrite(OutputBuffer, 1, OutputSize, pDestFile) != OutputSize || ferror(pDestFile)) {
					(void)inflateEnd(&Stream);
					PrintError("Error: Failed to write data to output file!");
					fclose(pDestFile);
					delete[] pInputBuffer;
					return false;
				}

			} while (Stream.avail_out == 0);

			/* done when inflate() says it's done */
		} while (Result != Z_STREAM_END);
	
		fclose(pDestFile);
		inflateReset(&Stream);
	}
ENDDEFLATE:
	int EndPos = FileSize - Stream.avail_in - 6;

	inflateEnd(&Stream);

	PrintError("Ended ZOSFT deflation at 0x%08X...parsing strings", EndPos);

	int StringPos = EndPos;
	std::vector<std::string> Lines;

	while (StringPos < FileSize)
	{
		Lines.push_back(pInputBuffer + StringPos);
		StringPos += Lines.back().size() + 1;
	}
	
	PrintError("Found %d lines in ZOSFT...", Lines.size());
	delete[] pInputBuffer;

	OutputFilename = pFilename;
	OutputFilename += ".ZOSFT";

	pFile = fopen(OutputFilename.c_str(), "wb");

	if (pFile == NULL) 
	{
		PrintError ("Error: Failed to open the ZOSFT text file for output!");
		return false;
	}

	for (size_t i = 0; i < Lines.size(); ++i)
	{
		fprintf(pFile, "%s", Lines[i].c_str());
	}

	fclose(pFile);

		/* Rename files */
	if (!RENAME_ASSETS) return true;

	char BaseSrcFilename[256];
	std::string SrcFilename;
	std::string NewFilename;
	std::string NewPath;

	for (size_t i = 0; i < Lines.size(); ++i)
	{
		_snprintf(BaseSrcFilename, 200, "%d.dat", (int) i+1);
		SrcFilename = pOutputPath;
		SrcFilename += BaseSrcFilename;

		NewFilename = pOutputPath;
		NewFilename += Lines[i].c_str() + 1;
		std::replace( NewFilename.begin(), NewFilename.end(), '/', '\\');

		NewPath = NewFilename.c_str();
		int Pos = NewPath.rfind('\\');
		if (Pos != std::string::npos) NewPath.erase(Pos, std::string::npos);		

		//std::string Cmd = "mkdir ";
		//Cmd += NewPath;
		//Cmd += " 2> nul";
		//system(Cmd.c_str());
		EnsurePathExists(NewPath.c_str());

		PrintError("%d: Moving file to '%s'...", i, NewFilename.c_str());
		
		Result = ::MoveFileEx(SrcFilename.c_str(), NewFilename.c_str(), MOVEFILE_REPLACE_EXISTING);

		if (!Result) 
		{
			PrintError ("\tError: File rename failed!");
		}
	}

	return true;
}


bool ExportESODataFile (const TCHAR* pFilename, const TCHAR* pOutputPath)
{
	const int CHUNK_SIZE = 262144;

	std::string OutputPath(CreateOutputPath(pFilename, pOutputPath));
	std::string OutputFilename;

	int OutputFileCount = 0;
	int Result;
    unsigned OutputSize;
    z_stream Stream;
	char BaseOutputFilename[_MAX_FNAME+16];
	eso::byte Header[DATA_HEADER_SIZE + 16];
    eso::byte InputBuffer[CHUNK_SIZE+64];
    eso::byte OutputBuffer[CHUNK_SIZE+64];
	FILE* pSourceFile;
	FILE* pDestFile;

	std::string Cmd = std::string("mkdir ") + OutputPath;
	Cmd += " 2> nul";
	Result = system(Cmd.c_str());

	if (Result != 0) 
	{
		PrintError ("Warning: Failed to create the output directory '%s'!", OutputPath.c_str());
		//return false;
	}
	
		/* allocate deflate state */
	Stream.zalloc = Z_NULL;
    Stream.zfree = Z_NULL;
    Stream.opaque = Z_NULL;
    Stream.avail_in = 0;
    Stream.next_in = Z_NULL;

    Result = inflateInit(&Stream);

    if (Result != Z_OK)
	{
		return false;
	}

	pSourceFile = fopen(pFilename, "rb");

	if (pSourceFile == NULL)
	{
		inflateEnd(&Stream);
		PrintError("Error: Failed to open input file '%s'!", pFilename);
		return false;
	}

	fseek(pSourceFile, 0, SEEK_END);
	long FileSize = ftell(pSourceFile);
	fseek(pSourceFile, 0, SEEK_SET);

	if (FileSize <= 0)
	{
		inflateEnd(&Stream);
		PrintError ("Error: Invalid source file size (too small or too large)!");
		fclose(pSourceFile);
		return false;
	}

	size_t HeaderSize = fread(Header, 1, DATA_HEADER_SIZE, pSourceFile);

	if (HeaderSize != DATA_HEADER_SIZE)
	{
		inflateEnd(&Stream);
		PrintError ("Error: Failed to read %u bytes of header data!", DATA_HEADER_SIZE);
		fclose(pSourceFile);
		return false;
	}

	PrintError("Header: ");

	for (size_t i = 0; i < HeaderSize; ++i)
	{
		PrintError ("%02X ", Header[i]);
	}

	PrintError("");

	while (!ferror(pSourceFile) && !feof(pSourceFile)) 
	{
		long CurOffset = ftell(pSourceFile);

		if (CurOffset < 0) 
		{
			inflateEnd(&Stream);
			PrintError ("Error: Failed to get current offset in source file!");
			fclose(pSourceFile);
			return false;
		}
		else if (CurOffset == FileSize)
		{
			PrintError ("Reached end of input file.");
			break;
		}
		else if (CurOffset > FileSize)
		{
			PrintError ("Warning: Exceeded end of input file by 0x%8X bytes!", CurOffset - FileSize);
			break;
		}
		
		++OutputFileCount;
		_snprintf(BaseOutputFilename, _MAX_FNAME, "%d.dat", OutputFileCount);
		OutputFilename = OutputPath + BaseOutputFilename;
		PrintError("%d: Processing output file...", OutputFileCount);
		
		pDestFile = fopen(OutputFilename.c_str(), "wb");

		if (pDestFile == NULL)
		{
			inflateEnd(&Stream);
			PrintError("Error: Failed to open output file '%s' for writing!", OutputFilename.c_str());
			fclose(pSourceFile);
			return false;
		}
		
			/* decompress until deflate stream ends or end of file */
		do {
			if (Stream.avail_in == 0)
			{
				CurOffset = ftell(pSourceFile);
				PrintError("\t0x%08X: Loading more input data...", CurOffset);

				if (CurOffset < 0) 
				{
					inflateEnd(&Stream);
					PrintError ("Error: Failed to get current offset in source file!");
					fclose(pSourceFile);
					return false;
				}
				else if (CurOffset == FileSize)
				{
					PrintError ("Reached end of input file.");
					break;
				}
				else if (CurOffset > FileSize)
				{
					PrintError ("Warning: Exceeded end of input file by 0x%8X bytes!", CurOffset - FileSize);
					break;
				}

				Stream.avail_in = fread(InputBuffer, 1, CHUNK_SIZE, pSourceFile);
				Stream.next_in = InputBuffer;

				if (ferror(pSourceFile)) {
					inflateEnd(&Stream);
					PrintError("Error: Failed to read bytes from input file!");
					fclose(pDestFile);
					fclose(pSourceFile);
					return false;
				}

				if (Stream.avail_in == 0)
				{
					break;
				}
			}

				/* run inflate() on input until output buffer not full */
			do {
				Stream.avail_out = CHUNK_SIZE;
				Stream.next_out = OutputBuffer;

				Result = inflate(&Stream, Z_NO_FLUSH);
				//assert(Result != Z_STREAM_ERROR);  /* state not clobbered */

				switch (Result) {
				case Z_NEED_DICT:
					Result = Z_DATA_ERROR;     /* and fall through */
				case Z_DATA_ERROR:
				case Z_MEM_ERROR:
				case Z_STREAM_ERROR:
				//case Z_BUF_ERROR:
					(void)inflateEnd(&Stream);
					PrintError("Error: Failed to uncompress data stream!");
					fclose(pDestFile);
					fclose(pSourceFile);
					return false;
				}

				OutputSize = CHUNK_SIZE - Stream.avail_out;

				if (fwrite(OutputBuffer, 1, OutputSize, pDestFile) != OutputSize || ferror(pDestFile)) {
					(void)inflateEnd(&Stream);
					PrintError("Error: Failed to write data to output file!");
					fclose(pDestFile);
					fclose(pSourceFile);
					return false;
				}

			} while (Stream.avail_out == 0);

			/* done when inflate() says it's done */
		} while (Result != Z_STREAM_END);
	
		fclose(pDestFile);
		inflateReset(&Stream);
	} 

	inflateEnd(&Stream);
	fclose(pSourceFile);

	ProcessZOSFT(OutputFilename.c_str(), OutputPath.c_str());

	return true;
}


bool LoadEsoMnfFile (const TCHAR* pFilename, const TCHAR* pOutputPath)
{
	std::string OutputPath(CreateOutputPath(pFilename, pOutputPath));
	std::string OutputFilename;
	esosubfile_t SubFile;
	int OutputFileCount = 0;
	int Result;
	bool fResult;
	char BaseOutputFilename[_MAX_FNAME+16];
	eso::byte Header[DATA_HEADER_SIZE + 16];
	FILE* pSourceFile;
	//FILE* pDestFile;

	std::string Cmd = std::string("mkdir ") + OutputPath;
	Cmd += " 2> nul";
	Result = system(Cmd.c_str());

	if (Result != 0) 
	{
		PrintError ("Warning: Failed to create the output directory '%s'!", OutputPath.c_str());
		//return false;
	}
	
	pSourceFile = fopen(pFilename, "rb");

	if (pSourceFile == NULL)
	{
		PrintError("Error: Failed to open input file '%s'!", pFilename);
		return false;
	}

	fseek(pSourceFile, 0, SEEK_END);
	long FileSize = ftell(pSourceFile);
	fseek(pSourceFile, 0, SEEK_SET);

	if (FileSize <= 0)
	{
		PrintError ("Error: Invalid source file size (too small or too large)!");
		fclose(pSourceFile);
		return false;
	}

	size_t HeaderSize = fread(Header, 1, DATA_HEADER_SIZE, pSourceFile);

	if (HeaderSize != DATA_HEADER_SIZE)
	{
		PrintError ("Error: Failed to read %u bytes of header data!", DATA_HEADER_SIZE);
		fclose(pSourceFile);
		return false;
	}

	PrintError("Header: ");

	for (size_t i = 0; i < HeaderSize; ++i)
	{
		PrintError ("%02X ", Header[i]);
	}

	PrintError("");

	fseek(pSourceFile, MNF_OFFSET - DATA_HEADER_SIZE - MNF_FILE_DELTA, SEEK_CUR);

	while (!ferror(pSourceFile) && !feof(pSourceFile))
	{
		fseek(pSourceFile, MNF_FILE_DELTA, SEEK_CUR);

		long CurOffset = ftell(pSourceFile);

		if (CurOffset < 0) 
		{
			PrintError ("Error: Failed to get current offset in source file!");
			fclose(pSourceFile);
			return false;
		}
		else if (CurOffset == FileSize)
		{
			PrintError ("Reached end of input file.");
			break;
		}
		else if (CurOffset > FileSize)
		{
			PrintError ("Warning: Exceeded end of input file by 0x%8X bytes!", CurOffset - FileSize);
			break;
		}
		
		++OutputFileCount;
		_snprintf(BaseOutputFilename, _MAX_FNAME, "%d.dat", OutputFileCount);
		OutputFilename = OutputPath + BaseOutputFilename;
		PrintError("%d: Processing output file...", OutputFileCount);

		fResult = InflateSubFile(SubFile, pSourceFile, FileSize);

		if (!fResult) 
		{
			fclose(pSourceFile);
			return false;
		}
		
	} 

	fclose(pSourceFile);

	return true;
}


bool LoadESODataFile1(const TCHAR* pFilename)
{
	eso::byte*		pInputBuffer = NULL;
	int			InputBufferSize = 0;
	eso::byte*		pOutputBuffer = NULL;
	int			OutputBufferSize = 0;
	z_stream	Stream;
	int			zResult;

	FILE* pFile = _tfopen(pFilename, _T("rb"));

	if (pFile == NULL) 
	{
		PrintError ("Error: Failed to open file!");
		return false;
	}

	fseek(pFile, 0, SEEK_END);
	InputBufferSize = ftell(pFile);
	fseek(pFile, 0, SEEK_SET);

	pInputBuffer = new eso::byte[InputBufferSize + 1024];
	fread(pInputBuffer, 1, InputBufferSize, pFile);
	fclose(pFile);
	
		/* Initialize the zLib stream */
	Stream.zalloc   = Z_NULL;
	Stream.zfree    = Z_NULL;
	Stream.opaque   = Z_NULL;
	Stream.avail_in = 0;
	Stream.next_in  = Z_NULL;

	OutputBufferSize = InputBufferSize * 4;
	pOutputBuffer = new eso::byte[OutputBufferSize + 1024];

	int InputOffset = 0;
	int OutputOffset = 0;
	int BlockCount = 0;

	while (InputOffset + OFFSET < InputBufferSize) 
	{
		BlockCount++;
		PrintError ("Block %d: ", BlockCount);
		PrintError ("Input Offset: 0x%X ", InputOffset + OFFSET);
		zResult = inflateInit(&Stream);

		if (zResult != Z_OK) 
		{
			PrintError("Error(%d): %s", zResult, Stream.msg);
			return false;
		}

		Stream.next_in   = pInputBuffer + OFFSET + InputOffset;
		Stream.avail_in  = InputBufferSize - OFFSET - InputOffset;
		Stream.avail_out = OutputBufferSize - OutputOffset;
		Stream.next_out  = pOutputBuffer + OutputOffset;

		//Z_STREAM_ERROR
		//Z_STREAM_END = 1
		//PrintError("Next In = 0x%08X", Stream.next_in);

		zResult = inflate(&Stream, Z_NO_FLUSH);
		PrintError(" Result=%d ", zResult);
   
		if (zResult < 0) {
			PrintError("Error(%d): %s", zResult, Stream.msg);
			inflateEnd(&Stream);
			break;
			delete [] pOutputBuffer;
			delete [] pInputBuffer;
			return (false);
		}

		//PrintError("State = 0x%X", Stream.state);
		
		InputOffset  += Stream.total_in;
		OutputOffset  += Stream.total_out;
		PrintError("In-Out: 0x%X 0x%X,  Total: 0x%08X 0x%08X", Stream.total_in, Stream.total_out, InputOffset + OFFSET, OutputOffset);

		inflateEnd(&Stream);

		InputOffset += FILE_DELTA;
	}
		
	pFile = _tfopen(_T("output.dat"), _T("wb"));

	if (pFile == NULL)
	{
		PrintError("Error: Failed to open file for output!");
		delete [] pOutputBuffer;
		delete [] pInputBuffer;
		return false;
	}

	fwrite(pOutputBuffer, 1, OutputOffset, pFile);
	fclose(pFile);

	delete [] pOutputBuffer;
	delete [] pInputBuffer;

	PrintError("Successfully decompressed file!");
	PrintError("End Input Offset = 0x%08X", InputOffset + OFFSET - FILE_DELTA);
	return true;
}


bool ExportESODataFiles(const char* pFileSpec, const char* pOutputPath)
{
	HANDLE hFind;
	WIN32_FIND_DATA FindData;
	std::string BasePath(pFileSpec);
	std::string Filename;
	bool Result;

	hFind = ::FindFirstFile(pFileSpec, &FindData);

	if (hFind == INVALID_HANDLE_VALUE)
	{
		PrintError("Error: Failed to find files matching '%s'!", pFileSpec);
		return false;
	}

	int Pos = BasePath.rfind('\\');
	if (Pos != std::string::npos) BasePath.erase(Pos+1, std::string::npos);

	do {
		Filename = BasePath + FindData.cFileName;

		Result = ExportESODataFile(Filename.c_str(), pOutputPath);
	} while (FindNextFile(hFind, &FindData));
	
	FindClose(hFind);
	return true;
}


typedef std::vector<std::string> CCmdArray;
typedef std::unordered_map<std::string, std::string> CCmdParamMap;
CCmdParamMap	m_CmdParams;
CCmdArray		m_CmdStrings;



bool DumpCommandLine1 (void)
{
	for (CCmdParamMap::iterator i = m_CmdParams.begin(); i != m_CmdParams.end(); ++i)
	{
		PrintLog("Cmd Params: '%s' = '%s'", i->first.c_str(), i->second.c_str());
	}

	for (size_t i = 0; i < m_CmdStrings.size(); ++i)
	{
		PrintLog("Cmd String %d: %s", i+1, m_CmdStrings[i].c_str());
	}

	return true;
}


bool ParseCommandLine1 (int argc, char* argv[])
{
	std::string LastPosParam;

	if (argc > 0)
	{
		m_CmdParams["__program"] = argv[0];
	}

	for (int i = 1; i < argc; ++i)
	{
		std::string Param = argv[i];
		if (Param.empty()) continue;
		
		if (Param[0] == '-') {

			if (!LastPosParam.empty())
			{
				m_CmdParams[LastPosParam] = "";
				LastPosParam.clear();
			}

			Param.erase(0, 1);
			if (Param.empty()) continue;
			if (Param[0] == '-') Param.erase(0, 1);
			if (Param.empty()) continue;
			LastPosParam = Param;
		}
		else if (!LastPosParam.empty())
		{
			m_CmdParams[LastPosParam] = Param;
			LastPosParam.clear();
		}
		else
		{
			m_CmdStrings.push_back(Param);
		}

	}

	return true;
}


bool ConvertRiffFile (const std::string Filename)
{
	eso::CFile File;
	std::string OutputFilename;
	eso::byte* pFileData = nullptr;
	fpos_t FileSize = 0;
	size_t NewFileSize = 0;
	bool Result;

	PrintError("Converting RIFF file %s...", Filename.c_str());	

	pFileData = CFile::ReadAll(Filename.c_str(), FileSize);
	if (!pFileData) return false;

	if (FileSize > INT_MAX) 
	{
		delete[] pFileData;
		return PrintError("RIFF filesize of %lld bytes is too large to convert!", FileSize);
	}

	if (FileSize < 72)
	{
		delete[] pFileData;
		return PrintError("RIFF filesize of %lld bytes is too small to convert!", FileSize);
	}

	NewFileSize = (size_t) FileSize + 4;

	eso::byte* pNewFileData = new eso::byte[NewFileSize + 100];

	memcpy(pNewFileData, pFileData, 72);
	memcpy(pNewFileData+72+4, pFileData+72, (size_t)FileSize-72);

	eso::dword RiffSize = *(dword *)(pFileData + 4);
	RiffSize += 4;
	memcpy(pNewFileData + 4, &RiffSize, 4);

	eso::dword FmtSize = *(dword *)(pFileData + 16);
	if (FmtSize != 24) PrintLog("\tFMT size of %d", FmtSize);
	FmtSize += 0x10;
	memcpy(pNewFileData + 16, &FmtSize, 4);

	eso::word CbSize = *(word *)(pFileData + 36);
	if (CbSize != 6) PrintLog("\tCB size of %d", (int)CbSize);
	CbSize += 0x10;
	memcpy(pNewFileData + 36, &CbSize, 2);

	eso::word ValidBitsPerSample = *(word *)(pFileData + 38);
	if (ValidBitsPerSample != 0) PrintLog("\tValidBitsPerSample of %d", (int)ValidBitsPerSample);
	ValidBitsPerSample += 0x10;
	memcpy(pNewFileData + 38, &ValidBitsPerSample, 2);

	memcpy(pNewFileData + 44, "\x01\x00\x00\x00\x00\x00\x10\x00\x80\x00\x00\xAA\x00\x38\x9B\x71", 16);

	OutputFilename = ::RemoveFileExtension(Filename) + ".wav";
	if (!File.Open(OutputFilename, "wb")) 
	{
		delete[] pNewFileData;
		delete[] pFileData;
		return false;
	}

	Result = File.WriteBytes(pNewFileData, NewFileSize);

	delete[] pNewFileData;
	delete[] pFileData;

	return Result;
}


int g_RiffFileCount = 0;
int g_RiffErrorCount = 0;


bool DoConvertExistingRiffFiles (const std::string RootPath)
{
	HANDLE hFind;
	std::string FileSpec(RootPath);
	std::vector<std::string> PathArray;
	WIN32_FIND_DATA FindData;
	BOOL FindResult = true;
	bool Result;
	
	FileSpec += "*.*";

	hFind = ::FindFirstFileA(FileSpec.c_str(), &FindData);
	if (hFind == INVALID_HANDLE_VALUE) return PrintError("Error: Failed to find any RIFF files to convert!");

	PrintError("Converting RIFF files in %s...", RootPath.c_str());	

	while (FindResult)
	{
		++g_RiffFileCount;
		std::string Filename(RootPath);
		Filename += FindData.cFileName;

		if (FindData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		{
			if (strcmp(FindData.cFileName, ".") != 0 && strcmp(FindData.cFileName, ".."))
			{
				Filename += "\\";
				PathArray.push_back(Filename);
			}
		}
		else
		{
			if (StringEndsWith(Filename, ".riff"))
			{
				Result = ConvertRiffFile(Filename);
				if (!Result) ++g_RiffErrorCount;
			}
		}

		FindResult = FindNextFile(hFind, &FindData);
	}

	FindClose(hFind);

	for (size_t i = 0; i < PathArray.size(); ++i)
	{
		DoConvertExistingRiffFiles(PathArray[i]);
	}

	return true;
}


typedef std::unordered_map<uint64_t, std::string> CLangIdMap;


bool CreateIdMap (CLangIdMap& IdMap, CEsoLangFile& LangFile, const bool UseLangText)
{

	for (size_t i = 0; i < LangFile.GetNumRecords(); ++i)
	{
		lang_record_t& Record = LangFile.GetRecord(i);
		uint64_t id = ((uint64_t) Record.Id) + (((uint64_t)Record.Unknown) << 32) + (((uint64_t)Record.Index) << 42);
		IdMap[id] = Record.Text;
	}

	return true;
}


bool CreateIdMap (CLangIdMap& IdMap, CCsvFile& CsvFile, const bool UsePOCSVFormat)
{
	
	if (CsvFile.GetNumRows() > 0)
	{
		const eso::csvrow_t& FirstRow = CsvFile.GetData()[0];

		if (UsePOCSVFormat && FirstRow.size() > 3) 
		{
			PrintError("Warning: Expected CSV file to have 3 columns but it looks to only %d!", FirstRow.size());
		}
		else if (!UsePOCSVFormat && FirstRow.size() < 5) 
		{
			PrintError("Warning: Expected CSV file to have 5 columns but it looks to have only %d!", FirstRow.size());
		}
	}

	for (int i = 1; i < CsvFile.GetNumRows(); ++i)
	{
		eso::csvcell_t* pValue;
		eso::csvrow_t& Row = (eso::csvrow_t &) CsvFile.GetData()[i];
		uint64_t id = 0;

		if (UsePOCSVFormat) 
		{
			if (Row.size() < 2) continue;
			const eso::csvcell_t& Id = Row[0];
			pValue = &Row[1];

			auto j1 = Id.find('-');
			if (j1 == std::string::npos) continue;
			auto j2 = Id.find('-', j1 + 1);
			if (j2 == std::string::npos) continue;
			const char* pText = Id.c_str();

			id = ((uint64_t) strtoul(pText, nullptr, 10)) + (((uint64_t) strtoul(pText + j1 + 1, nullptr, 10)) << 32) + (((uint64_t) strtoul(pText + j2 + 1, nullptr, 10)) << 42);
		}
		else
		{
			if (Row.size() < 5) continue;
			const eso::csvcell_t& Id = Row[0];
			const eso::csvcell_t& Unknown = Row[1];
			const eso::csvcell_t& Index = Row[2];
			pValue = &Row[4];
			id = ((uint64_t) strtoul(Id.c_str(), nullptr, 10)) + (((uint64_t) strtoul(Unknown.c_str(), nullptr, 10)) << 32) + (((uint64_t) strtoul(Index.c_str(), nullptr, 10)) << 42);
		}
		
		IdMap[id] = ReplaceStrings(ReplaceStrings(ReplaceStrings(*pValue, "\\n", "\x0a"), "\\r", "\x0d"), "\"\"", "\"");
	}

	return true;
}


bool OutputLangTextToFile (CFile& File, std::string Text)
{
	const char* pText = Text.c_str();
	bool Result = true;

	while (*pText)
	{
		if (*pText == '"')
			Result &= File.Printf("\"\"");
		else if (*pText == '\r')
			Result &= File.Printf("\\r");
		else if (*pText == '\n')
			Result &= File.Printf("\\n");
		else
			Result &= File.WriteChar(*pText);
	
		++pText;
	}

	return Result;
}


bool OutputLangEntryToFile (CFile& File, uint64_t ID64, std::string Text, const bool UsePOCSVFormat, std::string Text1 = "", std::string OrigText = "")
{
	unsigned int ID;
	unsigned int Unknown;
	unsigned int Index;
	bool Result = true;

	ID = ID64 & 0xffffffff;
	Unknown = (ID64 >> 32) & 0x3ff;
	Index = (ID64 >> 42) & 0xfffff;

	if (UsePOCSVFormat)	{
		Result = File.Printf("\"%d-%d-%d\",\"%", ID, Unknown, Index);
		Result &= OutputLangTextToFile(File, Text);
		Result = File.Printf("\",\"");
		Result &= OutputLangTextToFile(File, Text1);
		Result = File.Printf("\",\"");
		Result &= OutputLangTextToFile(File, OrigText);
		Result = File.Printf("\"\n");
	}
	else
	{
		Result = File.Printf("\"%d\",\"%d\",\"%d\",\"0\",\"", ID, Unknown, Index);
		Result &= OutputLangTextToFile(File, Text);
		Result = File.Printf("\",\"");
		Result &= OutputLangTextToFile(File, Text1);
		Result = File.Printf("\",\"");
		Result &= OutputLangTextToFile(File, OrigText);
		Result = File.Printf("\"\n");
	}

	return Result;
}



bool DiffLangFiles (std::string OrigLangFilename, std::string OrigLangIdFilename,
					std::string Filename1, std::string Filename2, std::string IdFilename1, std::string IdFilename2, 
					std::string OutputFilename, const bool UseLangText, const bool UsePOCSVFormat)
{
	CEsoLangFile     LangFileOrig;
	CEsoLangFile     LangFile1;
	CEsoLangFile     LangFile2;
	CEsoLangFile     OutputLangFile;
	CCsvFile         CsvFileOrig(!UseLangText);
	CCsvFile         CsvFile1(!UseLangText);
	CCsvFile         CsvFile2(!UseLangText);
	CSimpleTextFile  TextFileOrig;
	CSimpleTextFile  TextFile1;
	CSimpleTextFile  TextFile2;
	CSimpleTextFile  IdFileOrig;
	CSimpleTextFile  IdFile1;
	CSimpleTextFile  IdFile2;
	CLangIdMap	     IdMapOrig;
	CLangIdMap	     IdMap1;
	CLangIdMap    	 IdMap2;
	std::string		 AddedFilename(OutputFilename);
	std::string		 ChangedFilename(OutputFilename);
	std::string		 RemovedFilename(OutputFilename);
	std::string		 OutputLangFilename(OutputFilename);
	CFile			 AddedFile;
	CFile			 ChangedFile;
	CFile			 RemovedFile;

	PrintError("Performing LANG file difference on:");
	std::transform(OrigLangFilename.begin(), OrigLangFilename.end(), OrigLangFilename.begin(), ::tolower);
	std::transform(Filename1.begin(), Filename1.end(), Filename1.begin(), ::tolower);
	std::transform(Filename2.begin(), Filename2.end(), Filename2.begin(), ::tolower);

	if (!OrigLangFilename.empty())
	{
		PrintError("\tOriginal Lang: %s", OrigLangFilename.c_str());

		if (StringEndsWith(OrigLangFilename, ".lang"))
		{
			if (!LangFileOrig.Load(OrigLangFilename)) return false;
			if (!CreateIdMap(IdMapOrig, LangFileOrig, UseLangText)) return false;
		}
		else if (StringEndsWith(OrigLangFilename, ".csv"))
		{
			if (!CsvFileOrig.Load(OrigLangFilename)) return false;			if (!CreateIdMap(IdMapOrig, CsvFileOrig, UsePOCSVFormat)) return false;
		}
		else if (StringEndsWith(OrigLangFilename, ".txt"))
		{
			if (OrigLangIdFilename.empty()) return PrintError("Error: Missing ID file to go with TXT file '%s'!", OrigLangIdFilename.c_str());
			PrintError("\tCreating original LANG file from text file '%s' and ID file '%s'...", OrigLangFilename.c_str(), OrigLangIdFilename.c_str());
			if (!LoadSimpleTextFile(OrigLangFilename, TextFileOrig)) return false;
			if (!LoadSimpleTextFile(OrigLangIdFilename, IdFileOrig)) return false;
			if (!LangFileOrig.CreateFromText(TextFileOrig, IdFileOrig, UsePOCSVFormat, false)) return false;
			if (!CreateIdMap(IdMapOrig, LangFileOrig, UsePOCSVFormat)) return false;
		}
		else
		{
			return PrintError("Error: Unknown file format for '%s' (expected LANG, TXT, or CSV)!", OrigLangFilename.c_str());
		}
	}

	PrintError("\tOld: %s", Filename1.c_str());

	if (StringEndsWith(Filename1, ".lang"))
	{
		if (!LangFile1.Load(Filename1)) return false;
		if (!CreateIdMap(IdMap1, LangFile1, UseLangText)) return false;
	}
	else if (StringEndsWith(Filename1, ".csv"))
	{
		if (!CsvFile1.Load(Filename1)) return false;
		if (!CreateIdMap(IdMap1, CsvFile1, UsePOCSVFormat)) return false;
	}
	else if (StringEndsWith(Filename1, ".txt"))
	{
		if (IdFilename1.empty()) return PrintError("Error: Missing ID file to go with TXT file '%s'!", Filename1.c_str());
		PrintError("\tCreating old LANG file from text file '%s' and ID file '%s'...", Filename1.c_str(), IdFilename1.c_str());
		if (!LoadSimpleTextFile(Filename1, TextFile1)) return false;
		if (!LoadSimpleTextFile(IdFilename1, IdFile1)) return false;
		if (!LangFile1.CreateFromText(TextFile1, IdFile1, UsePOCSVFormat, false)) return false;
		if (!CreateIdMap(IdMap1, LangFile1, UsePOCSVFormat)) return false;
	}
	else
	{
		return PrintError("Error: Unknown file format for '%s' (expected LANG, TXT, or CSV)!", Filename1.c_str());
	}

	PrintError("\tNew: %s", Filename2.c_str());

	if (StringEndsWith(Filename2, ".lang"))
	{
		if (!LangFile2.Load(Filename2)) return false;
		if (!CreateIdMap(IdMap2, LangFile2, UseLangText)) return false;
	}
	else if (StringEndsWith(Filename2, ".csv"))
	{
		if (!CsvFile2.Load(Filename2)) return false;
		if (!CreateIdMap(IdMap2, CsvFile2, UsePOCSVFormat)) return false;
	}
	else if (StringEndsWith(Filename2, ".txt"))
	{
		if (IdFilename2.empty()) return PrintError("Error: Missing ID file to go with TXT file '%s'!", Filename2.c_str());
		PrintError("\tCreating new LANG file from text file '%s' and ID file '%s'...", Filename2.c_str(), IdFilename2.c_str());
		if (!LoadSimpleTextFile(Filename2, TextFile2)) return false;
		if (!LoadSimpleTextFile(IdFilename2, IdFile2)) return false;
		if (!LangFile2.CreateFromText(TextFile2, IdFile2, UsePOCSVFormat, false)) return false;
		if (!CreateIdMap(IdMap2, LangFile2, UsePOCSVFormat)) return false;
	}
	else
	{
		return PrintError("Error: Unknown file format for '%s' (expected LANG, TXT, or CSV)!", Filename2.c_str());
	}

	PrintError("\tFound %d strings in file #1.", IdMap1.size());
	PrintError("\tFound %d strings in file #2.", IdMap2.size());

	AddedFilename += ".added.csv";
	RemovedFilename += ".removed.csv";
	ChangedFilename += ".changed.csv";

	if (!AddedFile.Open(AddedFilename, "wb")) return PrintError("Error: Failed to open file '%s' for output!", AddedFilename.c_str());
	if (!RemovedFile.Open(RemovedFilename, "wb")) return PrintError("Error: Failed to open file '%s' for output!", RemovedFilename.c_str());
	if (!ChangedFile.Open(ChangedFilename, "wb")) return PrintError("Error: Failed to open file '%s' for output!", ChangedFilename.c_str());

	PrintError("Saving added text to '%s'...", AddedFilename.c_str());
	PrintError("Saving changed text to '%s'...", ChangedFilename.c_str());
	PrintError("Saving removed text to '%s'...", RemovedFilename.c_str());
	
	size_t AddCount = 0;
	size_t DiffCount = 0;
	size_t RemoveCount = 0;
	size_t KeptCount = 0;

	for (auto i = IdMap1.begin(); i != IdMap1.end(); ++i)
	{
		uint64_t id = (i->first);

		if (IdMap2.find(id) != IdMap2.end())
		{
			if (IdMap2[id] != IdMap1[id])
			{
				++DiffCount;
				OutputLangEntryToFile(ChangedFile, id, IdMap2[id], UsePOCSVFormat, IdMap1[id], IdMapOrig[id]);
				OutputLangFile.AddEntry(id, IdMap2[id]);
			}
			else if (IdMapOrig.find(id) != IdMapOrig.end())
			{
				OutputLangFile.AddEntry(id, IdMapOrig[id]);
				++KeptCount;
			}
			else
			{
				OutputLangFile.AddEntry(id, IdMap1[id]);
			}
		}
		else
		{
			++RemoveCount;
			OutputLangEntryToFile(RemovedFile, id, IdMap1[id], UsePOCSVFormat);
		}
	}

	for (auto i = IdMap2.begin(); i != IdMap2.end(); ++i)
	{
		uint64_t id = (i->first);

		if (IdMap1.find(id) == IdMap1.end())
		{
			++AddCount;
			OutputLangEntryToFile(AddedFile, id, IdMap2[id], UsePOCSVFormat);
			OutputLangFile.AddEntry(id, IdMap2[id]);
		}
	}

	PrintError("\tAdditions = %d", AddCount);
	PrintError("\tChanges   = %d", DiffCount);
	PrintError("\tRemovals  = %d", RemoveCount);
	PrintError("\tKept      = %d", KeptCount);

	OutputLangFile.SortRecords();

	if (UseLangText)
	{
		OutputLangFilename = OutputFilename + ".txt";
		if (!OutputLangFile.DumpText(OutputLangFilename, UsePOCSVFormat)) return PrintError("Error: Failed to save new TXT file '%s'!", OutputLangFilename.c_str());
		PrintError("Saved new TXT file '%s'!", OutputLangFilename.c_str());

		OutputLangFilename = OutputFilename + ".id.txt";
		if (!OutputLangFile.DumpTextId(OutputLangFilename)) return PrintError("Error: Failed to save new ID file '%s'!", OutputLangFilename.c_str());
		PrintError("Saved new ID file '%s'!", OutputLangFilename.c_str());
	}
	else
	{
		OutputLangFilename = OutputFilename + ".lang";
		if (!OutputLangFile.Save(OutputLangFilename)) return PrintError("Error: Failed to save new LANG file '%s'!", OutputLangFilename.c_str());
		PrintError("Saved new LANG file '%s'!", OutputLangFilename.c_str());
	}

	return true;
}


cmdparamdef_t g_Cmds[] = 
{
	// VarName        Opt  LongOpt           Description															 Req   Option Value   Mult   Default
	{ "mnffile",		"",  "",				"Input MNF filename to load.",										false, false, 1, 0, false, "" },
	{ "outputpath",		"",  "",				"Path to save extracted data files to.",							false, false, 1, 0, false, "" },
	{ "mnfft",			"m", "mnfft",			"Dump the MNF filetable to the specified text file.",				false, true,  1, 0, false, "" },
	{ "zosft",			"z", "zosft",			"Dump the ZOS filetable to the specified text file.",				false, true,  1, 0, false, "" },
	{ "filename",		"n", "filename",		"Only extract the given filename.",									false, true,  1, 0, false, "" },
	{ "fileext",		"y", "fileext",			"Only extract files with the given extension.",						false, true,  1, 0, false, "" },
	{ "startindex",		"s", "startindex",		"Start exporting sub-files at the given file index.",				false, true,  1, 0, false, "-1" },
	{ "endindex",		"e", "endindex",	    "Stop exporting sub-files at the given file index.",				false, true,  1, 0, false, "-1" },
	{ "archiveindex",	"a", "archive",			"Only export MNF file with the given index.",						false, true,  1, 0, false, "-1" },
	{ "beginarchive",	"b", "beginarchive",	"Start with the given MNF file index.",								false, true,  1, 0, false, "-1" },
	{ "fileindex",		"f", "fileindex",		"Only export MNF the subfile with the given file index.",			false, true,  1, 0, false, "-1" },
	//{ "convertdds",		"c", "convertdds",		"(Doesn't Work Yet) Attempt to convert DDS files to PNG.",			false, true,  0, 0, false, "0" },
	{ "skipsubfiles",	"k", "skipsubfiles",	"Don't export subfiles from the MNF data.",							false, true,  0, 0, false, "0" },
	{ "langfile",		"l", "lang",	        "Convert the given .lang file to a CSV.",							false, true,  1, 0, false, "" },
	{ "createlang",		"x", "createlang",		"Convert the given language CSV file to a .LANG.",					false, true,  1, 0, false, "" },
	{ "outputfile",		"o", "outputfile",		"Specify the output file for -l and -x.",							false, true,  1, 0, false, "" },
	{ "pocsv",			"p", "pocsv",			"Import/Export the CSV/Text file in a PO compatible format.",		false, true,  0, 0, false, "0" },
	{ "posourcetext",	"",  "posourcetext",	"Use the source text when converting a PO-CSV file to a LANG.",		false, true,  0, 0, false, "0" },
	{ "langtext",		"t", "langtext",		"Output the LANG file in plain text format.",		   	            false, true,  0, 0, false, "0" },
	{ "idfile",			"i", "idfile",			"The ID file to use when converting a TXT file to LANG.",           false, true,  1, 0, false, "" },
	{ "idfile1",		"i1","idfile1",			"The ID file to use for the first TXT file when comparing files.",  false, true,  1, 0, false, "" },
	{ "idfile2",		"i2","idfile2",			"The ID file to use for the second TXT file when comparing files.", false, true,  1, 0, false, "" },
	{ "difflang",		"d", "difflang",		"Compare two LANG/CSV/TXT files for differences.",                  false, true,  2, 0, false, "" },
	{ "origlang",		"g", "origlang",		"Use this LANG/CSV/TXT file for source texts when comparing files.",false, true,  1, 0, false, "" },
	{ "extractsubfile",	"",	 "extractsubfile",	"Extract compressed subfile data (none/combined/seperate).",        false, true,  1, 0, false, "" },
	{ "noparsegr2",		"",	 "noparsegr2",		"Don't parse GR2 files for their original filename.",               false, true,  0, 0, false, "" },
	{ "oodleoutput",	"",	 "oodleoutput",		"Output the raw/compressed Oodle files.",                           false, true,  0, 0, false, "" },
	{ "luafilelist",	"",	 "luafilelist",		"Output filenames to a LUA formatted array.",					    false, true,  1, 0, false, "" },
	{ "luastartindex",	"",	 "luastartindex",	"Start index for the --luafilelist option.",						false, true,  1, 0, false, "1" },
	{ "noriffconvert",	"",	 "noriffconvert",	"Don't convert RIFF files to WAV/OGG.",								false, true,  0, 0, false, "" },
	{ "matchfilename",	"",	 "matchfilename",	"Only extract files containing the given substring.",				false, true,  1, 0, false, "" },
	{ "baselangfile",	"",	 "baselangfile",	"Use the specified LANG file for missing entries.",					false, true,  1, 0, false, "" },
	{ "debugoutput",	"v", "debugoutput",		"Output additional debug messages.",								false, true,  0, 0, false, "0" },
	{ "",   "", "", "", false, false, false, false, "" }
};

const char g_AppTitle[] = "EsoExtractData v0.53 (30 April 2024)";
const char g_AppDescription[] = "\
EsoExtractData v0.53 is a simple command line application to load and export files\n\
from Elder Scrolls Online's MNF and DAT files. Created by Daveh (dave@uesp.net).\n";


int _tmain(int argc, _TCHAR* argv[])
{ 
	CMnfFile GameMnf;
	CMnfFile EsoMnf;
	CMnfFile EsoAudioMnf;
	mnf_exportoptions_t ExportOptions;

	OpenLog("exportmnf.log");

	if (!LoadOodleLib()) return -1;
	
	CCmdParamHandler CmdParamHandler("ExportMnf", g_AppDescription, g_Cmds);

	if (!CmdParamHandler.ParseCommandLine(argc, argv)) 
	{
		CmdParamHandler.DumpCommandLine();
		PrintError("Invalid command line parameter received...aborting!");
		if (CmdParamHandler.HasParamValue("help")) CmdParamHandler.PrintHelp();
		return -1;
	}

	CmdParamHandler.DumpCommandLine();

	if (CmdParamHandler.HasParamValue("help"))
	{
		CmdParamHandler.PrintHelp();
		return 0;
	}

#ifndef __UESP_NODEVIL
	ilInit();
	iluInit();
	ilEnable(IL_FILE_OVERWRITE);
#endif

	ExportOptions.MnfFilename = CmdParamHandler.GetParamValue("mnffile");
	ExportOptions.OutputPath = TerminatePath(CmdParamHandler.GetParamValue("outputpath"));
	ExportOptions.MnfOutputFileTable = CmdParamHandler.GetParamValue("mnfft");
	ExportOptions.ZosOutputFileTable = CmdParamHandler.GetParamValue("zosft");
	ExportOptions.MnfStartIndex = CmdParamHandler.GetParamValueAsInt("startindex");
	ExportOptions.MnfEndIndex = CmdParamHandler.GetParamValueAsInt("endindex");
	ExportOptions.ArchiveIndex = CmdParamHandler.GetParamValueAsInt("archiveindex");
	ExportOptions.BeginArchiveIndex = CmdParamHandler.GetParamValueAsInt("beginarchive");
	ExportOptions.MnfFileIndex = CmdParamHandler.GetParamValueAsInt("fileindex");

	//ExportOptions.ConvertDDS = CmdParamHandler.HasParamValue("convertdds");
	ExportOptions.ConvertDDS = false;

	ExportOptions.SkipSubFiles = CmdParamHandler.HasParamValue("skipsubfiles");
	ExportOptions.UseLangText = CmdParamHandler.HasParamValue("langtext");
	ExportOptions.UsePOCSVFormat = CmdParamHandler.HasParamValue("pocsv");
	ExportOptions.UsePOSourceText = CmdParamHandler.HasParamValue("posourcetext");
	ExportOptions.NoParseGR2 = CmdParamHandler.HasParamValue("noparsegr2");
	ExportOptions.LangFilename = CmdParamHandler.GetParamValue("langfile");
	ExportOptions.CreateLangFilename = CmdParamHandler.GetParamValue("createlang");
	ExportOptions.OutputFilename = CmdParamHandler.GetParamValue("outputfile");
	ExportOptions.ImportIdFilename = CmdParamHandler.GetParamValue("idfile");
	ExportOptions.DiffLangFilename1 = CmdParamHandler.GetParamValue("difflang", 0);
	ExportOptions.DiffLangFilename2 = CmdParamHandler.GetParamValue("difflang", 1);
	ExportOptions.IdFilename1 = CmdParamHandler.GetParamValue("idfile1", 0);
	ExportOptions.IdFilename2 = CmdParamHandler.GetParamValue("idfile2", 0);
	ExportOptions.OrigLangFilename = CmdParamHandler.GetParamValue("origlang");
	ExportOptions.ExtractFilename = CmdParamHandler.GetParamValue("filename");
	ExportOptions.OodleRawOutput = CmdParamHandler.HasParamValue("oodleoutput");
	ExportOptions.ExtractFileExtension = CmdParamHandler.GetParamValue("fileext");
	ExportOptions.LuaFileList = CmdParamHandler.GetParamValue("luafilelist");
	ExportOptions.LuaStartIndex = CmdParamHandler.GetParamValueAsInt("luastartindex");
	ExportOptions.NoRiffConvert = CmdParamHandler.HasParamValue("noriffconvert");
	ExportOptions.MatchFilename = CmdParamHandler.GetParamValue("matchfilename");
	ExportOptions.BaseLangFilename = CmdParamHandler.GetParamValue("baselangfile");

	PrintError("%s", g_AppTitle);

	if (CmdParamHandler.HasParamValue("debugoutput"))
	{
		PrintError("Outputting additional debug messages.");
		ExportOptions.DebugOutput = true;
		eso::g_OutputDebugLog = true;
	}

	ExportOptions.ExtractSubFileDataType = CmdParamHandler.GetParamValue("extractsubfile");
	std::transform(ExportOptions.ExtractSubFileDataType.begin(), ExportOptions.ExtractSubFileDataType.end(), ExportOptions.ExtractSubFileDataType.begin(), ::tolower);

		/* Handle a LANG file comparison */
	if (!ExportOptions.DiffLangFilename1.empty() && !ExportOptions.DiffLangFilename2.empty())
	{
		std::string OutputFilename = ExportOptions.DiffLangFilename2;
		if (!ExportOptions.OutputFilename.empty()) OutputFilename = ExportOptions.OutputFilename;

		if (ExportOptions.ImportIdFilename.empty()) ExportOptions.ImportIdFilename = ExportOptions.IdFilename1;
		if (ExportOptions.IdFilename1.empty()) ExportOptions.IdFilename1 = ExportOptions.ImportIdFilename;

		if (!DiffLangFiles(ExportOptions.OrigLangFilename, ExportOptions.ImportIdFilename, ExportOptions.DiffLangFilename1, ExportOptions.DiffLangFilename2, ExportOptions.IdFilename1, ExportOptions.IdFilename2, OutputFilename, ExportOptions.UseLangText, ExportOptions.UsePOCSVFormat))
		{
			return -100;
		}

		return 0;
	}
	
		/* Handle a .LANG file conversion to CSV */
	if (!ExportOptions.LangFilename.empty())
	{
		CEsoLangFile LangFile;
		std::string IdOutputFilename = ExportOptions.LangFilename + (ExportOptions.UseLangText ? ".id.txt" : ".id.csv");
		std::string OutputFilename = ExportOptions.LangFilename + (ExportOptions.UseLangText ? ".txt" : ".csv");

		if (!ExportOptions.OutputFilename.empty()) 
		{
			OutputFilename = ExportOptions.OutputFilename;
			IdOutputFilename = ExportOptions.OutputFilename + ".id.txt";
		}

		PrintError("Converting LANG file '%s' to %s '%s'...", ExportOptions.LangFilename.c_str(), ExportOptions.UseLangText ? "TXT" : "CSV", OutputFilename.c_str());

		if (LangFile.Load(ExportOptions.LangFilename))
		{
			PrintError("Loaded LANG file '%s'...", ExportOptions.LangFilename.c_str());

			if (ExportOptions.UseLangText && LangFile.DumpText(OutputFilename, ExportOptions.UsePOCSVFormat))
				PrintError("Saved the LANG file to '%s'!", OutputFilename.c_str());
			else if (!ExportOptions.UseLangText && LangFile.DumpCsv(OutputFilename, ExportOptions.UsePOCSVFormat))
				PrintError("Saved the LANG file to '%s'!", OutputFilename.c_str());
			else
				PrintError("Failed to save the LANG file '%s'!", OutputFilename.c_str());

			if (LangFile.DumpTextId(IdOutputFilename))
				PrintError("Saved the ID text file to '%s'!", IdOutputFilename.c_str());
			else
				PrintError("Failed to save the ID text file '%s'!", IdOutputFilename.c_str());
		}
		else
		{
			PrintError("Failed to load the LANG file '%s'!", ExportOptions.LangFilename.c_str());
		}
	}

		/* Handle a .LANG file creation from CSV */
	if (!ExportOptions.CreateLangFilename.empty())
	{
		CEsoLangFile LangFile;
		CEsoLangFile BaseLangFile;
		CCsvFile     CsvFile(!ExportOptions.UseLangText);
		CSimpleTextFile IdFile;
		CSimpleTextFile TextFile;
		std::string  InputType = (ExportOptions.UseLangText ? "TXT" : "CSV");
		std::string  OutputLangFilename = RemoveFileExtension(ExportOptions.CreateLangFilename);
		
		if (!StringEndsWith(OutputLangFilename, ".lang")) OutputLangFilename += ".lang";
		if (!ExportOptions.OutputFilename.empty()) OutputLangFilename = ExportOptions.OutputFilename;

		PrintError("Converting %s file '%s' to LANG '%s'...", InputType.c_str(), ExportOptions.CreateLangFilename.c_str(), OutputLangFilename.c_str());

		if (!ExportOptions.BaseLangFilename.empty())
		{
			if (!BaseLangFile.Load(ExportOptions.BaseLangFilename))
			{
				PrintError("Error: Failed to load the base LANG file '%s'!", ExportOptions.BaseLangFilename.c_str());
				return -20;
			}

			PrintError("Using LANG file '%s' for the base language entries....", ExportOptions.BaseLangFilename.c_str());
		}

		if (ExportOptions.UseLangText)
		{
			if (ExportOptions.ImportIdFilename.empty())
			{
				PrintError("Error: An ID file (-i <filename>) is required when converting  a TXT file to LANG!");
				return -1;
			}

			if (!LoadSimpleTextFile(ExportOptions.ImportIdFilename, IdFile))
			{
				PrintError("Error: Failed to load the ID file '%s'!", ExportOptions.ImportIdFilename.c_str());
				return -2;
			}

			PrintError("Loaded ID file '%s' with %u rows...", ExportOptions.ImportIdFilename.c_str(), IdFile.size());

			if (!LoadSimpleTextFile(ExportOptions.CreateLangFilename, TextFile))
			{
				PrintError("Error: Failed to load the TXT file '%s'!", ExportOptions.CreateLangFilename.c_str());
				return -3;
			}
			
			PrintError("Loaded TXT file '%s' with %u rows...", ExportOptions.CreateLangFilename.c_str(), TextFile.size());

			if (!LangFile.CreateFromText(TextFile, IdFile, ExportOptions.UsePOCSVFormat, ExportOptions.UsePOSourceText))
			{
				PrintError("Failed to create the LANG file from %s data!", InputType.c_str());
				return -4;
			}

			PrintError("Created the LANG file from the input TEXT data...");

			if (!ExportOptions.BaseLangFilename.empty())
			{
				int numEntries = LangFile.FillMissingEntries(BaseLangFile);
				PrintError("Filled in %d missing entries from the BASE lang file.", numEntries);
			}

			if (LangFile.Save(OutputLangFilename))
				PrintError("Saved the LANG file to '%s'!", OutputLangFilename.c_str());
			else
				PrintError("Failed to save the LANG file to '%s'!", OutputLangFilename.c_str());
		}
		else {

			if (CsvFile.Load(ExportOptions.CreateLangFilename))
			{
				PrintError("Loaded %s file '%s' with %d rows...", InputType.c_str(), ExportOptions.CreateLangFilename.c_str(), CsvFile.GetNumRows());
		
				if (!LangFile.CreateFromCsv(CsvFile, ExportOptions.UsePOCSVFormat, ExportOptions.UsePOSourceText))
				{
					PrintError("Failed to create the LANG file from %s data!", InputType.c_str());
					return -5;
				}

				PrintError("Created the LANG file from the input CSV data...");

				if (!ExportOptions.BaseLangFilename.empty())
				{
					int numEntries = LangFile.FillMissingEntries(BaseLangFile);
					PrintError("Filled in %d missing entries from the BASE lang file.", numEntries);
				}

				if (LangFile.Save(OutputLangFilename))
					PrintError("Saved the LANG file to '%s'!", OutputLangFilename.c_str());
				else
					PrintError("Failed to save the LANG file to '%s'!", OutputLangFilename.c_str());
			}
			else
			{
				PrintError("Failed to load the CSV file '%s'!", ExportOptions.CreateLangFilename.c_str());
				return -6;
			}
		}
	}

	if (!ExportOptions.MnfFilename.empty())
	{
		CMnfFile MnfFile;
		MnfFile.Export(ExportOptions);
	}
	else
	{
		PrintError("Skipping MNF export...no file specified!");
	}

	return 0;
}



