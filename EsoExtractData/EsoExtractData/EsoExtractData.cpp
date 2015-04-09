/*
 * EsoExtractData - by Dave Humphrey (dave@uesp.net)
 *
 * A Windows command line program that extracts data/files from ESO (Elder Scrolls Online)
 * MNF and DAT game data files.
 *
 * Use "EsoExtractData -h" for basic help.
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
#include "EsoMnfFile.h"
#include "EsoZosftFile.h"
#include "CmdParamHandler.h"
#include "EsoLangFile.h"
#include "EsoCsvFile.h"

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

	int GetInputSize(void) { return EndOffset - StartOffset; }

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
		PrintError("Warning: Last file is not a ZOSFT format!");
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
		_snprintf(BaseSrcFilename, 200, "%d.dat", i+1);
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


cmdparamdef_t g_Cmds[] = 
{
	{ "mnffile",      "", "",				"Input MNF filename to load.",								false, false, true,  false, "" },
	{ "outputpath",   "", "",				"Path to save extracted data files to.",					false, false, true,  false, "" },
	{ "mnfft",        "m", "mnfft",			"Dump the MNF filetable to the specified text file.",		false, true,  true,  false, "" },
	{ "zosft",        "z", "zosft",			"Dump the ZOS filetable to the specified text file.",		false, true,  true,  false, "" },
	{ "startindex",   "s", "startindex",	"Start exporting sub-files at the given file index.",		false, true,  true,  false, "-1" },
	{ "endindex",     "e", "endindex",	    "Stop exporting sub-files at the given file index.",		false, true,  true,  false, "-1" },
	{ "archiveindex", "a", "archive",		"Only export MNF file with the given index.",				false, true,  true,  false, "-1" },
	{ "beginarchive", "b", "beginarchive",	"start with the given MNF file index.",						false, true,  true,  false, "-1" },
	{ "fileindex",    "f", "fileindex",		"Only export MNF the subfile with the given file index.",	false, true,  true,  false, "-1" },
	{ "convertdds",   "c", "convertdds",    "(Doesn't Work Yet) Attempt to convert DDS files to PNG.",	false, true,  false, false, "0" },
	{ "skipsubfiles", "k", "skipsubfiles",	"Don't export subfiles from the MNF data.",		            false, true,  false, false, "0" },
	{ "langfile",     "l", "lang",	        "Convert the given .lang file to a CSV.",		            false, false, true,  false, "" },
	{ "createlang",   "x", "createlang",    "Convert the given language CSV file to a .LANG.",	        false, false, true,  false, "" },
	{ "",   "", "", "", false, false, false, false, "" }
};

const char g_AppDescription[] = "\
ExportMnf v0.20 is a simple command line application to load and export files\n\
from ESO's MNF and DAT files. Created by Daveh (dave@uesp.net).\n\
\n\
WARNING: This app is in early development and is fragile. User discretion is\n\
advised.\n\
";

int _tmain(int argc, _TCHAR* argv[])
{ 
	CMnfFile GameMnf;
	CMnfFile EsoMnf;
	CMnfFile EsoAudioMnf;
	CZosftFile GameZosft;
	CZosftFile EsoZosft;
	mnf_exportoptions_t ExportOptions;

	OpenLog("exportmnf.log");

	/*
	CCsvFile CsvFile(true);

	CsvFile.Load("d:\\temp\\en.lang.csv");
	//CsvFile.Dump();
	CsvFile.Save("d:\\temp\\test.lang.csv");

	CEsoLangFile LangFile;
	LangFile.CreateFromCsv(CsvFile);
	LangFile.Save("d:\\temp\\test.lang");

	CEsoLangFile LangFile1;
	LangFile1.Load("d:\\temp\\en.lang");
	LangFile1.DumpCsv("d:\\temp\\en.lang.csv");

	return 0; //*/

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

	ilInit();
	iluInit();
	ilEnable(IL_FILE_OVERWRITE);

	ExportOptions.MnfFilename = CmdParamHandler.GetParamValue("mnffile");
	ExportOptions.OutputPath = TerminatePath(CmdParamHandler.GetParamValue("outputpath"));
	ExportOptions.MnfOutputFileTable = CmdParamHandler.GetParamValue("mnfft");
	ExportOptions.ZosOutputFileTable = CmdParamHandler.GetParamValue("zosft");
	ExportOptions.MnfStartIndex = CmdParamHandler.GetParamValueAsInt("startindex");
	ExportOptions.MnfEndIndex = CmdParamHandler.GetParamValueAsInt("endindex");
	ExportOptions.ArchiveIndex = CmdParamHandler.GetParamValueAsInt("archiveindex");
	ExportOptions.BeginArchiveIndex = CmdParamHandler.GetParamValueAsInt("beginarchive");
	ExportOptions.MnfFileIndex = CmdParamHandler.GetParamValueAsInt("fileindex");
	ExportOptions.ConvertDDS = CmdParamHandler.HasParamValue("convertdds");
	ExportOptions.SkipSubFiles = CmdParamHandler.HasParamValue("skipsubfiles");
	ExportOptions.LangFilename = CmdParamHandler.GetParamValue("langfile");
	ExportOptions.CreateLangFilename = CmdParamHandler.GetParamValue("createlang");

		/* Handle a .LANG file conversion to CSV */
	if (!ExportOptions.LangFilename.empty())
	{
		CEsoLangFile LangFile;
		std::string OutputCSVFilename = ExportOptions.LangFilename + ".csv";

		if (LangFile.Load(ExportOptions.LangFilename))
		{
			PrintError("Loaded LANG file '%s'...", ExportOptions.LangFilename.c_str());

			if (LangFile.DumpCsv(OutputCSVFilename))
				PrintError("Saved the LANG file to '%s'!", OutputCSVFilename.c_str());
			else
				PrintError("Failed to save the LANG file '%s'!", OutputCSVFilename.c_str());
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
		CCsvFile     CsvFile(true);
		std::string  OutputLangFilename = RemoveFileExtension(ExportOptions.CreateLangFilename);
		if (!StringEndsWith(OutputLangFilename, ".lang")) OutputLangFilename += ".lang";

		if (CsvFile.Load(ExportOptions.CreateLangFilename))
		{
			PrintError("Loaded CSV file '%s'...", ExportOptions.CreateLangFilename.c_str());

			if (LangFile.CreateFromCsv(CsvFile))
			{
				PrintError("Created the LANG file from the CSV data...");

				if (LangFile.Save(OutputLangFilename))
					PrintError("Saved the LANG file to '%s'!", OutputLangFilename.c_str());
				else
					PrintError("Failed to save the LANG file to '%s'!", OutputLangFilename.c_str());
			}
			else
			{
				PrintError("Failed to create the LANG file from CSV data!");
			}
		}
		else
		{
			PrintError("Failed to load the CSV file '%s'!", ExportOptions.CreateLangFilename.c_str());
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



