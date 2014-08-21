#ifndef __ESOCOMMON_H
#define __ESOCOMMON_H


#include <assert.h>
#include "zlib/zlib.h"
#include "snappy/snappy.h"
#include "devil/include/il/il.h"
#include "devil/include/il/ilu.h"
#include <string>
#include <vector>
#include <map>
#include <unordered_map>
#include <algorithm>

#pragma warning( disable : 4351 )


namespace eso {

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int dword;
typedef unsigned __int64 dword64;


std::string GuessFileExtension (const char* pOutputBuffer, const size_t OutputSize);
std::string RemoveFileExtension (const std::string Filename);
std::string TerminatePath (const std::string Path);
std::string AppendPaths (const std::string Path1, const std::string Path2);
std::string AppendFilenameToPath (const std::string Path1, const std::string Filename);
std::string CreateFilename (const std::string BaseFilename, const char* pString, ...);
std::string RemoveFilename (const std::string Filename);
inline std::string ExtractPath (const std::string Filename) { return RemoveFilename(Filename); }

std::string ReplaceStrings (std::string subject, const std::string& search, const std::string& replace);

void PrintLog   (const char* pString, ...);
bool PrintError (const char* pString, ...);
void PrintLogV  (const char* pString, va_list Args);
bool OpenLog    (const char* pFilename);


word WordSwap (const word i);
dword DwordSwap (const dword i);
dword64 Dword64Swap (const dword64 i);
float FloatSwap (const float f);

bool ReadDword(FILE* pFile, dword& Output, const bool IsBigEndian = false);
bool ReadWord(FILE* pFile, word& Output, const bool IsBigEndian = false);

dword ParseBufferDword(const byte* pBuffer, const bool IsBigEndian = false);
std::string ParseBufferString(const byte* pBuffer, const size_t Offset, const size_t Size);

bool InflateSnappyBlock (byte* pOutputData, size_t& OutputSize, const size_t MaxOutputSize, byte* pInputData, const size_t InputSize, const bool Quiet = false);
bool InflateZlibBlock   (byte* pOutputData, size_t& OutputSize, const size_t MaxOutputSize, byte* pInputData, const size_t InputSize, const bool Quiet = false);


bool StringEndsWith (std::string const &fullString, std::string const &ending);


bool EnsurePathExists(const char* lpszPath);
inline bool EnsurePathExists(const std::string Path) { return EnsurePathExists(Path.c_str()); }
bool DirectoryExists(const char* lpszPath);


double GetTimerMS (void);


bool ConvertDDStoPNG (const byte* pData, const size_t Size, const std::string Filename);

bool FileExists(const char* pFilename);
bool GetFileSize (__int64& FileSize, const std::string Filename);

};

#endif