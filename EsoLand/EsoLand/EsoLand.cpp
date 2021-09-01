// EsoLand.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "pch.h"
#include <iostream>
#include <string>
#include <vector>
#include "EsoFile.h"
#include "CmdParamHandler.h"

using namespace eso;


ILuint g_BigImage;
int g_BigImageX = 0;
int g_BigImageY = 0;


void AddBigImage(std::vector<word>& Data)
{
	ilBindImage(g_BigImage);
	ilSetPixels(g_BigImageX*65, g_BigImageY*65, 0, 65, 65, 1, IL_LUMINANCE, IL_UNSIGNED_SHORT, Data.data());

	++g_BigImageX;

	if (g_BigImageX >= 49)
	{
		g_BigImageX = 0;
		++g_BigImageY;
	}
}


struct esolandrecinfo_t 
{
	byte Index;
	dword Offset;
	dword Length;
};


struct esohandheader_t
{
	static const size_t UNKNOWN3_SIZE = 20;

	dword Magic;
	byte Unknown1;
	dword Magic2;
	byte NumRecords;

	std::vector< esolandrecinfo_t > RecInfos;

	word Unknown2;
	dword Unknown3[UNKNOWN3_SIZE];
};



struct esolanddata_t 
{
	dword Magic;
	dword Height;
	dword Height2;
	dword Width;

	std::vector<dword> Data;

	dword Footer;
};


class CEsoLandFile
{

protected:
	const static size_t MAGIC_HEADER = 0xBEEF000C;

	std::string m_Filename;

	esohandheader_t m_Header;
	std::vector<esolanddata_t> m_Data;


protected:

	bool ReadHeader(CFile &File);
	bool ReadDataSection(CFile &File, const size_t Index);
	

public:

	CEsoLandFile();
	~CEsoLandFile();


	bool ExportImages(std::string Path);


	bool Load(std::string Filename);

	static bool IsLandFile (std::string Filename);

};


CEsoLandFile::CEsoLandFile()
{

}


CEsoLandFile::~CEsoLandFile()
{

}


bool CEsoLandFile::ReadHeader(CFile &File)
{
	if (!File.ReadDword(m_Header.Magic)) return false;

	if (m_Header.Magic != MAGIC_HEADER) return PrintError("Error: File is not a recognized ESO land data file!");

	if (!File.ReadByte(m_Header.Unknown1)) return false;
	if (!File.ReadDword(m_Header.Magic2)) return false;
	if (!File.ReadByte(m_Header.NumRecords)) return false;

	m_Header.RecInfos.resize(m_Header.NumRecords);

	for (size_t i = 0; i < m_Header.NumRecords; ++i)
	{
		esolandrecinfo_t RecInfo;

		if (!File.ReadByte(RecInfo.Index)) return false;
		if (!File.ReadDword(RecInfo.Offset)) return false;
		if (!File.ReadDword(RecInfo.Length)) return false;

		m_Header.RecInfos[i] = RecInfo;
	}

	if (!File.ReadWord(m_Header.Unknown2)) return false;

	for (size_t i = 0; i < m_Header.UNKNOWN3_SIZE; ++i)
	{
		if (!File.ReadDword(m_Header.Unknown3[i])) return false;
	}
		
	return true;
}


bool CEsoLandFile::ReadDataSection(CFile &File, const size_t Index)
{
	if (Index >= m_Header.NumRecords) return PrintError("\tError: Data index overflow in section #%u!", Index);

	esolandrecinfo_t& RecInfo = m_Header.RecInfos[Index];
	word Width = 0;
	esolanddata_t& Data = m_Data[Index];

	if (RecInfo.Offset == 0 || RecInfo.Length == 0) return true;

	if (!File.Seek(RecInfo.Offset)) return PrintError("\tError: Failed to jump to start of data section #%d (offset 0x%08X)", Index, RecInfo.Offset);

	if (!File.ReadDword(Data.Magic)) return false;
	if (!File.ReadDword(Data.Height)) return false;
	if (!File.ReadDword(Data.Height2)) return false;
	if (!File.ReadDword(Data.Width)) return false;

	if (Data.Height != Data.Height2) PrintError("\tWarning: Height mismatch in data section #%d (%d != %d)", Index, Data.Height, Data.Height2);

	size_t DataSize = Data.Height * Data.Width;
	size_t RecSize = 16 + Data.Height * (Data.Width + 2) + 4;
	if (RecInfo.Length != RecSize) PrintError("\tWarning: Data section #%u has record length mismatch (%u != %u)", Index, RecInfo.Length, RecSize);

	Data.Data.resize(DataSize/4);

	for (size_t y = 0; y < Data.Height; ++y)
	{
		if (!File.ReadWord(Width)) return PrintError("\tError: Failed to read data width in section #%u:%u!", Index, y);
		if (Width != Data.Width) return PrintError("\tError: Row width mismsatch in data section #%u:%u (%u != %u)", Index, y, (size_t)Width, Data.Width);

		//if (!File.ReadBytes(Data.Data.data() + y * Data.Width, Width)) return PrintError("\tError: Failed to read %u bytes of row data in section #%u:%u!", Width, Index, y);

		for (size_t x = 0; x < Data.Width/4; ++x)
		{
			if (!File.ReadDword(Data.Data[x + y * Data.Width/4])) return PrintError("\tError: Failed to read dword row data in section #%u:%u:%u", Index, y, x);
		} 
	}

	if (!File.ReadDword(Data.Footer)) return false;
	return true;
}


bool CEsoLandFile::Load(std::string Filename)
{
	CFile File;

	m_Filename = Filename;

	if (!File.Open(Filename, "rb")) return PrintError("Error: Failed to open file '%s' for reading!", Filename.c_str());

	if (!ReadHeader(File)) return PrintError("Error: Failed to read header data for file '%s'!", Filename.c_str());

	m_Data.resize(m_Header.NumRecords);

	for (size_t i = 0; i < m_Header.NumRecords; ++i)
	{
		if (!ReadDataSection(File, i)) return PrintError("Error: Failed to read data section #%u for file '%s'!", i, Filename.c_str());
	}

	return true;
}


bool CEsoLandFile::IsLandFile(std::string Filename)
{
	CFile File;
	dword Magic = 0;

	if (!File.Open(Filename, "rb")) return PrintError("Error: Failed to open file '%s' for reading!", Filename.c_str());
	if (!File.ReadDword(Magic)) return false;

	return (Magic == MAGIC_HEADER);
}


std::vector<float> g_MinValues(10, (float)INT_MAX);
std::vector<float> g_MaxValues(10, (float)INT_MIN);


bool CEsoLandFile::ExportImages(std::string Path)
{
	CFile File;
	std::string BaseFilename = RemoveFileExtension(m_Filename);

	for (size_t i = 0; i < m_Header.NumRecords; ++i)
	{
		esolandrecinfo_t& RecInfo = m_Header.RecInfos[i];
		esolanddata_t& Data = m_Data[i];

		if (RecInfo.Offset == 0 || RecInfo.Length == 0) continue;

		std::string Filename = BaseFilename + "-" + std::to_string(i) + ".png";

		float Value = (float) (int) Data.Data[0];

		if (i == 0 || i == 6) Value = *(float *)&Data.Data[0];
		float min = Value;
		float max = Value;

		/*
		for (size_t j = 1; j < Data.Data.size(); ++j)
		{
			Value = (float)(int) Data.Data[j];
			if (i == 0 || i == 6) Value = *(float *)&Data.Data[j];

			if (Value < min) min = Value;
			if (Value > max) max = Value;
		}

		PrintError("\t%u: Value Range: %f - %f", i, min, max); 

		if (g_MinValues[i] > min) g_MinValues[i] = min;
		if (g_MaxValues[i] < max) g_MaxValues[i] = max;
		//*/

		std::vector<word> TmpData(Data.Data.size());

		for (size_t j = 0; j < Data.Data.size(); ++j)
		{
			TmpData[j] = (word) ((*(float *)& Data.Data[j]) / 1000.0f * 65535.0f);
		}

		ILuint image = ilGenImage();
		ilBindImage(image);
		ilTexImage(Data.Width / 4, Data.Height, 1, 1, IL_LUMINANCE, IL_UNSIGNED_SHORT, TmpData.data());
		if (!ilSave(IL_PNG, Filename.c_str())) PrintError("Error: Failed to save PNG file '%s'!", Filename.c_str());

		AddBigImage(TmpData);
		
		if (i == 0) break;
	}
	
	return true;
}


std::vector<std::string> FindAllDirectoriesInPath(std::string Path)
{
	std::vector<std::string> Result;
	WIN32_FIND_DATA FindData;
	std::string FileSpec = Path + "*.*";
	BOOL FindResult;
	HANDLE hFind;

	hFind = FindFirstFile(FileSpec.c_str(), &FindData);
	if (hFind == INVALID_HANDLE_VALUE) return Result;

	do
	{
		if ((FindData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && strcmp(FindData.cFileName, ".") && strcmp(FindData.cFileName, "..") ) 
		{
			Result.push_back(Path + FindData.cFileName + "/");
		}
		FindResult = FindNextFile(hFind, &FindData);
	} while (FindResult);

	FindClose(hFind);
	return Result;
}


void ParseAllEsoLandFiles(std::string Path)
{
	WIN32_FIND_DATA FindData;
	std::string FileSpec = Path + "*.dat";
	HANDLE hFind;
	BOOL FindResult;
	int TotalCount = 0;
	int ErrorCount = 0;

	std::vector<std::string> Dirs = FindAllDirectoriesInPath(Path);

	PrintError("Loading all ESO land data files in %s:", Path.c_str());

	hFind = FindFirstFile(FileSpec.c_str(), &FindData);
	if (hFind == INVALID_HANDLE_VALUE) return;

	do
	{
		std::string Filename = Path + FindData.cFileName;

		if (CEsoLandFile::IsLandFile(Filename))
		{
			CEsoLandFile TestFile;

			PrintError("Loading %s...", Filename.c_str());

			++TotalCount;

			if (!TestFile.Load(Filename.c_str()))
				++ErrorCount;
			else
				TestFile.ExportImages(Path);
		}

		FindResult = FindNextFile(hFind, &FindData);
	} while (FindResult);

	FindClose(hFind);

	for (auto&& dir : Dirs)
	{
		ParseAllEsoLandFiles(dir);
	}

	PrintError("\tLoaded %d files successfully, %d with errors!", TotalCount, ErrorCount);

	for (size_t i = 0; i < 10; i++)
	{
		PrintError("\t%d: %f to %f", i, g_MinValues[i], g_MaxValues[i]);
	}
}

/*
	095
		0: 0.000000 to 456.803833
		1: -16776960.000000 to 0.000000
		2: -2147483648.000000 to 2147353088.000000
		3: -2147483648.000000 to 2138832896.000000
		4: 0.000000 to 65280.000000
		5: 0.000000 to 0.000000
		6: -0.999949 to 1.000000
		7: -65536.000000 to 65535.000000
		8: -2147483648.000000 to 2130721536.000000
		9: 2147483648.000000 to -2147483648.000000

	All Files
		0: 0.000000 to 1000.000000
		1: -2131035392.000000 to 2147483648.000000
		2: -2147483648.000000 to 2147353088.000000
		3: -2147483648.000000 to 2146697216.000000
		4: -2147483648.000000 to 2139029504.000000
		5: -2113929216.000000 to 2113929216.000000
		6: -0.999995 to 1.000000
		7: -65536.000000 to 65535.000000
		8: -2147483648.000000 to 2130771968.000000
		9: 2147483648.000000 to -2147483648.000000
*/



int main()
{
	CEsoLandFile TestFile;

	ilInit();
	iluInit();
	ilEnable(IL_FILE_OVERWRITE);

	g_BigImage = ilGenImage();
	ilBindImage(g_BigImage);
	ilTexImage(65 * 49, 65*49, 1, 1, IL_LUMINANCE, IL_UNSIGNED_SHORT, nullptr);

	OpenLog("esoland.log");

	//TestFile.Load("E:/esoexport/esomnf-29/095/770284.dat");

	ParseAllEsoLandFiles("e:/esoexport/esomnf-29/095/");

	ilBindImage(g_BigImage);
	ilSave(IL_PNG, "e:/esoexport/esomnf-29/095/combined.png");

	return 0;
}

