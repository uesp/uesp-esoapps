

//#include "stdafx.h"
#include "EsoCommon.h"
#include <tchar.h>
#include "windows.h"
#include "EsoFile.h"
#include <time.h>
#include <iostream>
#include <string>


namespace eso {

CFile g_LogFile;


bool OpenLog(const char* pFilename)
{
	g_LogFile.Close();
	return g_LogFile.Open(pFilename, "wb");
}


bool PrintError(const char* pString, ...)
{
	va_list Args;

	va_start(Args, pString);
	vprintf(pString, Args);
	printf("\n");
	fflush(stdout);
	
	PrintLogV(pString, Args);

	va_end(Args);
	return false;
}


void PrintLogV(const char* pString, va_list Args)
{
	if (g_LogFile.GetFile() == nullptr) return;

	time_t Now = time(nullptr);
	char Buffer[110];
	SYSTEMTIME SysTime;

	GetLocalTime(&SysTime);
	strftime(Buffer, 100, "%H:%M:%S", localtime(&Now));
	
	fprintf (g_LogFile.GetFile(), "%s.%03d -- ", Buffer, SysTime.wMilliseconds);
	vfprintf(g_LogFile.GetFile(), pString, Args);
	fprintf (g_LogFile.GetFile(), "\n");

	//vprintf(pString, Args);
	//printf ("\n");

	fflush(g_LogFile.GetFile());
}


void PrintLog(const char* pString, ...)
{
	va_list Args;

	va_start(Args, pString);
	PrintLogV(pString, Args);
	va_end(Args);
}


word WordSwap (const word s)
{
	unsigned char b1, b2;
  
	b1 = s & 255;
	b2 = (s >> 8) & 255;

	return (b1 << 8) + b2;
}


dword DwordSwap (const dword i)
{
	unsigned char b1, b2, b3, b4;

	b1 = i & 255;
	b2 = ( i>> 8 ) & 255;
	b3 = ( i>>16 ) & 255;
	b4 = ( i>>24 ) & 255;

	return ((dword)b1 << 24) + ((dword)b2 << 16) + ((dword)b3 << 8) + b4;
}


dword64 Dword64Swap (const dword64 i)
{
	unsigned char b1, b2, b3, b4, b5, b6, b7, b8;

	b1 = i & 255;
	b2 = ( i>> 8 ) & 255;
	b3 = ( i>>16 ) & 255;
	b4 = ( i>>24 ) & 255;
	b5 = ( i>>32 ) & 255;
	b6 = ( i>>40 ) & 255;
	b7 = ( i>>48 ) & 255;
	b8 = ( i>>56 ) & 255;

	return ((dword64)b1 << 56) + ((dword64)b2 << 48) + ((dword64)b3 << 40) + ((dword64)b4 << 32) + ((dword64)b5 << 24) + ((dword64)b6 << 16) + ((dword64)b7 << 8) + b8;
}


float FloatSwap (const float f)
{
	//TODO
	assert(false);
	return f;
}


bool ReadDword(FILE* pFile, dword& Output, const bool IsBigEndian)
{
	size_t ReadBytes = fread(&Output, 1, sizeof(dword), pFile);
	if (IsBigEndian) Output = DwordSwap(Output);
	return ReadBytes == sizeof(dword);
}


bool ReadWord(FILE* pFile, word& Output, const bool IsBigEndian)
{
	size_t ReadBytes = fread(&Output, 1, sizeof(word), pFile);
	if (IsBigEndian) Output = WordSwap(Output);
	return ReadBytes == sizeof(word);
}


bool InflateZlibBlock (byte* pOutputData, dword &OutputSize, const size_t MaxOutputSize, const byte* pInputData, const size_t InputSize, const bool Quiet)
{
	z_stream Stream;
	int Result;

	Stream.zalloc = Z_NULL;
    Stream.zfree = Z_NULL;
    Stream.opaque = Z_NULL;
    Stream.avail_in = 0;
    Stream.next_in = Z_NULL;

    Result = inflateInit(&Stream);
    if (Result != Z_OK) return Quiet ? false : PrintError("Error: Failed to initialize the zlib stream!");

	Stream.avail_in = InputSize;
	Stream.avail_out = MaxOutputSize;
	Stream.next_out = pOutputData;
	Stream.next_in = (byte *)pInputData;

		/* Decompress until deflate stream ends or end of block data */
	do {
		Result = inflate(&Stream, Z_NO_FLUSH);

		switch (Result) {
			case Z_BUF_ERROR:
				if (Stream.avail_in == 0) Result = Z_STREAM_END;
				break;
			case Z_NEED_DICT:
				Result = Z_DATA_ERROR;     /* and fall through */
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
			case Z_STREAM_ERROR:
			//case Z_BUF_ERROR:
				OutputSize = Stream.total_out;
				inflateEnd(&Stream);
				return Quiet ? false : PrintError("Error: Failed to uncompress data stream!");
		};

	} while (Result != Z_STREAM_END);

	OutputSize = Stream.total_out;
	inflateEnd(&Stream);
	return true;
}


bool InflateSnappyBlock (byte* pOutputData, dword &OutputSize, const size_t MaxOutputSize, const byte* pInputData, const size_t InputSize, const bool Quiet)
{
	bool Result;
	size_t RealOutputSize;

	OutputSize = 0;

	if (InputSize > INT_MAX) return Quiet ? false : PrintError("Error: Compressed snappy data size is too large (%u byte)!", InputSize);

	Result = snappy::GetUncompressedLength((char *)pInputData, InputSize, &RealOutputSize);
	if (!Result) return Quiet ? false : PrintError("Error: Invalid Snappy data format found!");
	if (RealOutputSize > INT_MAX) return Quiet ? false : PrintError("Error: Uncompressed snappy data size is too large (%u bytes)!", OutputSize);

	if (RealOutputSize > MaxOutputSize) return Quiet ? false : PrintError("Error: Uncompressed snappy data size exceeds in the output buffer (%u bytes)!", RealOutputSize);

	Result = snappy::RawUncompress((char *)pInputData, InputSize, (char *)pOutputData);			
	if (!Result) Quiet ? false : PrintError("Error: Failed to decompress the Snappy data!");

	OutputSize = RealOutputSize;
	return true;
}



bool DeflateZlibBlock(byte* pOutputData, dword &OutputSize, const size_t MaxOutputSize, const byte* pInputData, const size_t InputSize, const bool Quiet)
{
	z_stream Stream;
	int Result;

	Stream.zalloc = Z_NULL;
	Stream.zfree = Z_NULL;
	Stream.opaque = Z_NULL;
	Stream.avail_in = 0;
	Stream.next_in = Z_NULL;

	Result = deflateInit(&Stream, -1);
	if (Result != Z_OK) return Quiet ? false : PrintError("Error: Failed to initialize the zlib stream!");

	Stream.avail_in = InputSize;
	Stream.avail_out = MaxOutputSize;
	Stream.next_out = pOutputData;
	Stream.next_in = (byte *) pInputData;

		/* Compress until stream ends or end of block data */
	do {
		Result = deflate(&Stream, Z_FINISH);

		switch (Result) {
		case Z_BUF_ERROR:
			if (Stream.avail_out == 0) return Quiet ? false : PrintError("Error: No more output space available!");
			Result = Z_STREAM_END;
			break;
		case Z_NEED_DICT:
			Result = Z_DATA_ERROR;     /* and fall through */
		case Z_DATA_ERROR:
		case Z_MEM_ERROR:
		case Z_STREAM_ERROR:
			//case Z_BUF_ERROR:
			OutputSize = Stream.total_out;
			deflateEnd(&Stream);
			return Quiet ? false : PrintError("Error: Failed to compress data stream!");
		};

	} while (Result != Z_STREAM_END);

	OutputSize = Stream.total_out;
	deflateEnd(&Stream);
	return true;
}



bool StringEndsWith (std::string const &fullString, std::string const &ending)
{
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare(fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}


// Ensures the given path exists, creating it if needed
bool EnsurePathExists(const char* lpszPath)
{
	char PathBuffer[_MAX_FNAME+10];

  // Nothing to do if path already exists
  if (DirectoryExists(lpszPath))
    return true;

  // Ignore trailing backslash
  int nLen = _tcslen(lpszPath);
  if (lpszPath[nLen - 1] == '\\')
    nLen--;

  // Skip past drive specifier
  int nCurrLen = 0;
  if (nLen >= 3 && lpszPath[1] == ':' && lpszPath[2] == '\\')
    nCurrLen = 2;

  // We can't create root so skip past any root specifier
  while (lpszPath[nCurrLen] == '\\')
    nCurrLen++;

  // Test each component of this path, creating directories as needed
  while (nCurrLen < nLen)
  {
    // Parse next path compenent
    LPCTSTR psz = _tcschr(lpszPath + nCurrLen, '\\');
    if (psz != NULL)
      nCurrLen = (int)(psz - lpszPath);
    else
      nCurrLen = nLen;

    // Ensure this path exists
	if (nCurrLen > _MAX_FNAME) return false;
	strncpy(PathBuffer, lpszPath, nCurrLen);
	PathBuffer[nCurrLen] = '\0';
    //sPath.SetString(lpszPath, nCurrLen);
    if (!DirectoryExists(PathBuffer))
      if (!::CreateDirectory(PathBuffer, NULL))
	  {
		PrintError("Error: Failed to create the directory '%s'!", PathBuffer);
        return false;
	  }

    // Skip over current backslash
    if (lpszPath[nCurrLen] != '\0')
      nCurrLen++;
  }
  return true;
}


// Returns true if the specified path exists and is a directory
bool DirectoryExists(const char* lpszPath)
{
	DWORD dw = ::GetFileAttributes(lpszPath);
	return (dw != INVALID_FILE_ATTRIBUTES && (dw & FILE_ATTRIBUTE_DIRECTORY) != 0);
}


std::string GuessFileExtension (const unsigned char* pOutputBuffer, const size_t OutputSize)
{
	std::string Extension;

	if (memcmp(pOutputBuffer, "DDS ", 4) == 0)
	{
		Extension = "dds";
	}
	else if (memcmp(pOutputBuffer, "\x00\x01\x00\x00\x00\x0E\x00\x80", 8) == 0 ||
			memcmp(pOutputBuffer, "OTTO", 4) == 0 || 
			memcmp(pOutputBuffer+11, "POS/2", 5) == 0 )
	{
		Extension = "ttf";
	}
	else if (memcmp(pOutputBuffer, "\x1E\x0D\x0B\xCD\xCE\xFA\x11", 7) == 0)
	{
		Extension = "hk";
	}
	else if (memcmp(pOutputBuffer, "\x29\xDE\x6C\xC0", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\xE5\x9B\x49\x5E", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x29\x75\x31\x82", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x0E\x11\x95\xB5", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x0E\x74\xA2\x0A", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\xE5\x2F\x4A\xE1", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x31\x95\xD4\xE3", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x31\xC2\x4E\x7C", 4) == 0)
	{
		Extension = "gr2";
	}
	else if (memcmp(pOutputBuffer, "\x1E\x0D\xB0\xCA", 4) == 0)
	{
		Extension = "hkx";
	}
	else if (memcmp(pOutputBuffer, "\xFA\xFA\xEB\xEB", 4) == 0)
	{
		Extension = "EsoFileData";
	}
	else if (memcmp(pOutputBuffer, "\xFB\xFB\xEC\xEC", 4) == 0)
	{
		Extension = "EsoIdData";
	}
	else if (memcmp(pOutputBuffer, "\x00\x00\x00\x02", 4) == 0)
	{
		Extension = "EsoIdData";
	}
	else if (memcmp(pOutputBuffer, "\xEF\xBB\xBF", 3) == 0)
	{
		Extension = "txt";
	}
	else if (memcmp(pOutputBuffer, "xV4", 3) == 0)
	{
		Extension = "xv4";
	}
	else if (memcmp(pOutputBuffer, "__ffx", 5) == 0)
	{
		Extension = "ffx";
	}
	else if (memcmp(pOutputBuffer, "RIFF", 4) == 0)
	{
		Extension = "riff";
	}
	else if (memcmp(pOutputBuffer, "; ", 2) == 0 ||
			memcmp(pOutputBuffer + OutputSize - 4, ".lua", 4) == 0)
	{
		Extension = "txt";
	}
	else if (memcmp(pOutputBuffer, "#", 1) == 0 ||
			memcmp(pOutputBuffer, "//", 2) == 0 ||
			memcmp(pOutputBuffer, "\r\n#", 3) == 0 ||
			memcmp(pOutputBuffer, "/*", 2) == 0 )
	{
		Extension = "fx";
	}
	else if (memcmp(pOutputBuffer, "--", 2) == 0 ||
			memcmp(pOutputBuffer, "local", 5) == 0 ||
			memcmp(pOutputBuffer, "function", 7) == 0 )
	{
		Extension = "lua";
	}
	else if (memcmp(pOutputBuffer, "<", 1) == 0)
	{
		Extension = "xml";
	}
	else if (memcmp(pOutputBuffer, "ZOSFT", 5) == 0)
	{
		Extension = "zosft";
	}
	else if (memcmp(pOutputBuffer, "PSB2", 4) == 0)
	{
		Extension = "psb2";
	}
	else if (memcmp(pOutputBuffer + OutputSize - 5, "end", 3) == 0 || 
			memcmp(pOutputBuffer + OutputSize - 3, "end", 3) == 0 ||
			memcmp(pOutputBuffer + OutputSize - 7, "end", 3) == 0 ||
			memcmp(pOutputBuffer + OutputSize - 2, "\r", 2) == 0)
	{
		Extension = "lua";
	}
	else
	{
		Extension = "dat";
	}

	return Extension;
}


std::string RemoveFileExtension (const std::string Filename)
{
	std::string Output(Filename);
	std::replace(Output.begin(), Output.end(), '/', '\\');

	for (int i = Output.size(); i > 0; --i)
	{
		if (Output[i-1] == '\\') break;
		if (Output[i-1] == ':')  break;

		if (Output[i-1] == '.')
		{
			Output.erase(i-1, std::string::npos);
			break;
		}
	}

	return Output;
}


std::string RemoveFilename (const std::string Filename)
{
	std::string Output(Filename);
	std::replace(Output.begin(), Output.end(), '/', '\\');

	for (int i = Output.size(); i > 0; --i)
	{
		if (Output[i-1] == '\\' || Output[i-1] == ':')
		{
			Output.erase(i, std::string::npos);
			break;
		}
	}
	
	return Output;
}


std::string TerminatePath (const std::string Path)
{
	std::string Output(Path);

	std::replace(Output.begin(), Output.end(), '/', '\\');

	if (!Output.empty() && Output[Output.size()-1] != '\\')
	{
		Output += "\\";
	}

	return Output;
}


std::string AppendPaths (const std::string Path1, const std::string Path2)
{
	std::string Output(Path1);

	std::replace(Output.begin(), Output.end(), '/', '\\');

	if (!Output.empty() && Output[Output.size()-1] != '\\') Output += "\\";

	if (Path2[0] == '\\')
		Output.append(Path2, 1, std::string::npos);
	else
		Output += Path2;

	std::replace(Output.begin(), Output.end(), '/', '\\');

	if (!Output.empty() && Output[Output.size()-1] != '\\') Output += "\\";
	return Output;
}


std::string AppendFilenameToPath (const std::string Path, const std::string Filename)
{
	std::string Output(Path);

	std::replace(Output.begin(), Output.end(), '/', '\\');
	if (!Output.empty() && Output[Output.size()-1] != '\\') Output += "\\";

	if (Filename[0] == '\\')
		Output.append(Filename, 1, std::string::npos);
	else
		Output += Filename;

	return Output;
}


std::string CreateFilename (const std::string BaseFilename, const char* pString, ...)
{
	va_list Args;
	char Buffer[1024];

	std::string Output(BaseFilename);
	std::replace(Output.begin(), Output.end(), '/', '\\');

	va_start(Args, pString);
	_vsnprintf(Buffer, 1000, pString, Args);
	va_end(Args);

	if (Buffer[0] == '\\' && !Output.empty() && Output.back() == '\\')
		Output += Buffer + 1;
	else
		Output += Buffer;

	return Output;
}


double GetTimerMS (void)
{
	static double Frequency = 1;
	LARGE_INTEGER Counter;

	if (!::QueryPerformanceCounter(&Counter)) return (double) ::GetTickCount();

	if (Frequency == 1)
	{
		LARGE_INTEGER Freq;
		if (!::QueryPerformanceFrequency(&Freq)) return (double) ::GetTickCount();
		Frequency = (double)Freq.QuadPart;
	}

	return (double)Counter.QuadPart * 1000.0 / Frequency;
}


bool ConvertDDStoPNG (const byte* pData, const size_t Size, const std::string Filename)
{
	std::string OutputFilename = RemoveFileExtension(Filename) + ".png";

	try 
	{/*
		if (!ilLoadImage(Filename.c_str())) 
		{
			ILenum Error = ilGetError();
			const char* pErrorStr = iluErrorString(Error);
			return PrintError("Failed to load DDS image data from file '%s': (%d) %s", Filename.c_str(), Error, pErrorStr);
		} //*/

			//This crashes sometimes? 
		if (!ilLoadL(IL_DDS, pData, Size)) 
		{
			ILenum Error = ilGetError();
			const char* pErrorStr = iluErrorString(Error);
			return PrintError("Failed to load DDS image data from memory buffer: (%d) %s", Error, pErrorStr);
		} //*/

		if (!ilSave(IL_PNG, OutputFilename.c_str())) 
		{
			ILenum Error = ilGetError();
			const char* pErrorStr = iluErrorString(Error);
			return PrintError("Failed to save PNG image to file '%s':(%d) %s", OutputFilename.c_str(), Error, pErrorStr);
		}
	}
	catch (std::exception& e)
	{
		return PrintError("Caught exception in trying to convert DDS to PNG: %s", e.what());
	}
	catch (...)
	{
		return PrintError("Caught exception in trying to convert DDS to PNG!");
	}

	return true;
}


dword ParseBufferDword(const byte* pBuffer, const bool IsBigEndian)
{
	dword Result = 0;

	memcpy(&Result, pBuffer, sizeof(dword));

	if (IsBigEndian) return DwordSwap(Result);
	return Result;
}


std::string ParseBufferString(const byte* pBuffer, const size_t Offset, const size_t Size)
{
	std::string Result;

	if (Offset >= Size) return Result;

	const byte* pStart = pBuffer + Offset;
	size_t i = 0;

	for (i = 0; pStart[i] && i + Offset < Size; ++i)
	{
	}

	Result.assign((const char *)pStart, i);
	return Result;
}

std::string ReplaceStrings (std::string subject, const std::string& search, const std::string& replace) {
    size_t pos = 0;
    while((pos = subject.find(search, pos)) != std::string::npos) {
         subject.replace(pos, search.length(), replace);
         pos += replace.length();
    }
    return subject;
}


bool GetFileSize (__int64& FileSize, const std::string Filename)
{
	FILE* pFile = fopen(Filename.c_str(), "rb");

	if (pFile == nullptr) 
	{
		FileSize = 0;
		return false;
	}

	if (_fseeki64(pFile, 0, SEEK_END) != 0)
	{
		FileSize = 0;
		return false;
	}

	FileSize = _ftelli64(pFile);
	fclose(pFile);

	if (FileSize < 0) 
	{
		FileSize = 0;
		return false;
	}
	
	return true;
}


bool FileExists(const char* pFilename)
{
	DWORD dw = ::GetFileAttributes(pFilename);
	return (dw != INVALID_FILE_ATTRIBUTES && (dw & FILE_ATTRIBUTE_DIRECTORY) == 0);
}


bool WriteMotorolaDword(FILE* pFile, const dword Value)
{
	if (fputc((Value >> 24) & 0xff, pFile) == EOF) return false;
	if (fputc((Value >> 16) & 0xff, pFile) == EOF) return false;
	if (fputc((Value >> 8) & 0xff, pFile) == EOF) return false;
	if (fputc(Value & 0xff, pFile) == EOF) return false;

	return true;
}


bool GetFilesSize(__int64& DirSize, const std::string FileSpec)
{
	WIN32_FIND_DATAA data;
	HANDLE sh = NULL;

	DirSize = 0;

	sh = FindFirstFileA(FileSpec.c_str(), &data);
	if (sh == INVALID_HANDLE_VALUE) return false;

	do
	{
		if (std::string(data.cFileName).compare(".") != 0 && std::string(data.cFileName).compare("..") != 0)
		{
			if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY)
			{
			}
			else
			{
				DirSize += (__int64)(data.nFileSizeHigh * (MAXDWORD)+data.nFileSizeLow);
			}
		}

	} while (FindNextFileA(sh, &data));

	FindClose(sh);
	return true;
}


bool GetFolderSize(__int64& DirSize, const std::string Path)
{
	WIN32_FIND_DATAA data;
	HANDLE sh = NULL;

	DirSize = 0;

	sh = FindFirstFileA((Path + "\\*").c_str(), &data);
	if (sh == INVALID_HANDLE_VALUE) return false;
	
	do
	{
		if (std::string(data.cFileName).compare(".") != 0 && std::string(data.cFileName).compare("..") != 0)
		{
			if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY)
			{
				__int64 DirSize1;
				GetFolderSize(DirSize1, Path + "\\" + data.cFileName);
				DirSize += DirSize1;
			}
			else
			{
				DirSize += (__int64)(data.nFileSizeHigh * (MAXDWORD)+data.nFileSizeLow);
			}
		}

	} while (FindNextFileA(sh, &data));

	FindClose(sh);
	return true;
}


bool DeleteFiles(const std::string FileSpec)
{
	WIN32_FIND_DATAA data;
	HANDLE sh = NULL;
	bool Return = true;
	std::string BaseFilename(FileSpec);
	auto n = BaseFilename.find('\\');

	if (n != BaseFilename.npos) BaseFilename.resize(n);
	BaseFilename = eso::TerminatePath(BaseFilename);

	sh = FindFirstFileA(FileSpec.c_str(), &data);
	if (sh == INVALID_HANDLE_VALUE) return false;

	do
	{
		if (std::string(data.cFileName).compare(".") != 0 && std::string(data.cFileName).compare("..") != 0)
		{
			if ((data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY)
			{
			}
			else
			{
				std::string Filename = BaseFilename + data.cFileName;
				if (!DeleteFile(Filename.c_str())) Return = false;
			}
		}

	} while (FindNextFileA(sh, &data));

	FindClose(sh);
	return Return;
}

};
