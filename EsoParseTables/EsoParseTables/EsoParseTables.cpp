// EsoParseTables.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <stdlib.h>
#include <vector>
#include <string>
#include <stdarg.h>
#include <intrin.h>
#include <algorithm>
#include <iostream>


const std::string INPUT_FILENAME = "E:\\Temp\\testexport\\000\\498177_Uncompressed.dat";
const std::string INPUT_FILENAME1 = "E:\\Temp\\testexport\\000\\497777_Uncompressed.dat";


typedef unsigned int dword;
typedef unsigned short word;
typedef unsigned char byte;



bool ReportError(const char* pMsg, ...)
{
	va_list Args;

	va_start(Args, pMsg);
	vprintf(pMsg, Args);
	printf("\n");

	return false;
}



bool ReadBigEndianDword(FILE* pFile, dword& Input)
{
	dword TempInput;

	if (fread(&TempInput, 1, 4, pFile) != 4) 
	{
		Input = 0;
		return ReportError("Failed to read 4 bytes from file at offset 0x%08X!", ftell(pFile));
	}

	Input = _byteswap_ulong(TempInput);
	return true;
}


bool ReadBigEndianWord(FILE* pFile, word& Input)
{
	word TempInput;

	if (fread(&TempInput, 1, 2, pFile) != 2)
	{
		Input = 0;
		return ReportError("Failed to read 2 bytes from file at offset 0x%08X!", ftell(pFile));
	}

	Input = _byteswap_ushort(TempInput);
	return true;
}


struct esodatatableentry_t 
{
	dword Level;
	dword Quality;
	dword Value;
};


class CEsoDataTableRecord
{
public:
	dword m_RecordIndex;
	dword m_UncompressedSize1;
	dword m_UncompressedSize2;
	dword m_CompressedSize;
	dword m_Index;
	dword m_OrigFileOffset;
	dword m_UncompressedSize;
	dword m_Index2;

	std::string m_Name;

	dword m_Unknown1;
	dword m_Unknown2;
	dword m_Unknown3;
	word  m_Unknown4;
	dword m_Unknown5;

	std::vector<esodatatableentry_t> m_Entries;


public:


	void Dump (FILE* pOutput = stdout)
	{
		fprintf(pOutput, "%s (%d):\n", m_Name.c_str(), m_Index2);
		dword LastLevel = 1;

		for (size_t i = 0; i < m_Entries.size(); )
		{
			LastLevel = m_Entries[i].Level;
			fprintf(pOutput, "\t %u = ", LastLevel);

			while (i < m_Entries.size() && m_Entries[i].Level == LastLevel)
			{
				fprintf(pOutput, "%u ", m_Entries[i].Value);
				++i;
			}

			fprintf(pOutput, "\n");
		}
	}


	void DumpPhp (FILE* pOutput = stdout)
	{
		fprintf(pOutput, "// %s (%d)\n", m_Name.c_str(), m_Index2);
		fprintf(pOutput, "%s = array(\n", GetPhpName().c_str());
		fprintf(pOutput, "\t0 => array(0, 0, 0, 0, 0, 0),\n");
		dword LastLevel = 1;

		for (size_t i = 0; i < m_Entries.size(); )
		{
			LastLevel = m_Entries[i].Level;
			fprintf(pOutput, "\t%u => array(", LastLevel);

			while (i < m_Entries.size() && m_Entries[i].Level == LastLevel)
			{
				fprintf(pOutput, "%u, ", m_Entries[i].Value);
				++i;
			}

			fprintf(pOutput, ");\n");
		}

		fprintf(pOutput, ");\n\n");
	}


	void DumpSummary (FILE* pOutput = stdout)
	{
		fprintf(pOutput, "%s (%d)\n", m_Name.c_str(), m_Index2);
	}


	void DumpHeaders (FILE* pOutput = stdout)
	{
		fprintf(pOutput, "%d = %s\n", m_Index2, m_Name.c_str());
	}


	dword  GetIndex() const { return m_Index2; }


	std::string GetPhpName()
	{
		std::string name(m_Name);
		
		std::string::size_type i = name.find("& ");
		if (i != std::string::npos) name.erase(i, 2);

		i = name.find(" and");
		if (i != std::string::npos) name.erase(i, 4);

		name.erase(std::remove(name.begin(), name.end(), '&'), name.end());
		name.erase(std::remove(name.begin(), name.end(), ','), name.end());

		std::replace(name.begin(), name.end(), ' ', '_');

		std::transform(name.begin(), name.end(), name.begin(), ::toupper);

		name = "$ESODATATABLE_" + name;

		return name;
	}


	bool ReadEntryBlock (FILE* pFile, dword& Level)
	{
		dword NumRecords;
		dword NumEntries;
		
		if (!ReadBigEndianDword(pFile, NumRecords)) return false;
		//printf("Read NumRecords: %u\n", NumRecords);

		for (dword i = 0; i < NumRecords; ++i)
		{
			dword Quality = 0;

			if (!ReadBigEndianDword(pFile, NumEntries)) return false;
			//printf("Read NumEntries: %u\n", NumEntries);

			for (dword j = 0; j < NumEntries; ++j)
			{
				esodatatableentry_t Entry;

				Entry.Level = Level;
				Entry.Quality = Quality;
				if (!ReadBigEndianDword(pFile, Entry.Value)) return false;

				//printf("Read Entry: %u %u %u\n", Level, Quality, Entry.Value);

				m_Entries.push_back(Entry);
				++Quality;
			}

			++Level;
		}

		return true;
	}


	bool Read (FILE* pFile)
	{
		dword Tmp;
		word NameLength;

		if (!ReadBigEndianDword(pFile, Tmp)) return false; //####
		if (!ReadBigEndianDword(pFile, m_RecordIndex)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize1)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize2)) return false;
		if (!ReadBigEndianDword(pFile, m_CompressedSize)) return false;
		if (!ReadBigEndianDword(pFile, m_Index)) return false;
		if (!ReadBigEndianDword(pFile, m_OrigFileOffset)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize)) return false;
		if (!ReadBigEndianDword(pFile, m_Index2)) return false;

		if (!ReadBigEndianWord(pFile, NameLength)) return false;

		char* pBuffer = new char[NameLength + 4];
		if (fread(pBuffer, 1, NameLength + 1, pFile) != NameLength + 1) return ReportError("Failed to read %d bytes from file!", NameLength+1);
		m_Name = pBuffer;
		delete[] pBuffer;

		if (!ReadBigEndianDword(pFile, m_Unknown1)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown2)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown3)) return false;
		if (!ReadBigEndianWord(pFile, m_Unknown4)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown5)) return false;
		
		dword Level = 1;

		if (!ReadEntryBlock(pFile, Level)) return false;
		if (!ReadEntryBlock(pFile, Level)) return false;

		return true;
	}


	bool ReadHeaders(FILE* pFile)
	{
		dword Tmp;
		word NameLength;

		if (!ReadBigEndianDword(pFile, Tmp)) return false; //####
		if (!ReadBigEndianDword(pFile, m_RecordIndex)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize1)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize2)) return false;
		if (!ReadBigEndianDword(pFile, m_CompressedSize)) return false;
		if (!ReadBigEndianDword(pFile, m_Index)) return false;
		if (!ReadBigEndianDword(pFile, m_OrigFileOffset)) return false;
		if (!ReadBigEndianDword(pFile, m_UncompressedSize)) return false;

		fpos_t StartPos = ftell(pFile);

		if (!ReadBigEndianDword(pFile, m_Index2)) return false;
		if (!ReadBigEndianWord(pFile, NameLength)) return false;

		char* pBuffer = new char[NameLength + 4];
		if (fread(pBuffer, 1, NameLength + 1, pFile) != NameLength + 1) return ReportError("Failed to read %d bytes from file!", NameLength + 1);
		m_Name = pBuffer;
		delete[] pBuffer;

		long offset = (long)StartPos + m_UncompressedSize;
		fseek(pFile, offset, SEEK_SET);

		return true;
	}

};


class CEsoDataTable
{
public:
	dword m_MagicBytes;
	dword m_Unknown1;
	dword m_NumRecords;
	dword m_Unknown2;

	std::vector<CEsoDataTableRecord> m_Records;
	

public:


	void Dump (FILE* pOutput = stdout)
	{
		for (auto &Record : m_Records)
		{
			Record.Dump(pOutput);
		}
	}


	void DumpHeaders(FILE* pOutput = stdout)
	{
		for (auto &Record : m_Records)
		{
			Record.DumpHeaders(pOutput);
		}
	}


	void DumpPhp(FILE* pOutput = stdout)
	{
		for (auto &Record : m_Records)
		{
			Record.DumpPhp(pOutput);
		}

		fprintf(pOutput, "$ESODATATABLE_ALL = array(\n");

		for (auto &Record : m_Records)
		{
			fprintf(pOutput, "\t%d => &%s,\n", Record.GetIndex(), Record.GetPhpName().c_str());
		}

		fprintf(pOutput, ");\n");
		
	}


	void DumpSummary(FILE* pOutput = stdout)
	{
		for (auto &Record : m_Records)
		{
			Record.DumpSummary(pOutput);
		}
	}


	bool Read (FILE* pFile)
	{
		if (!ReadBigEndianDword(pFile, m_MagicBytes)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown1)) return false;
		if (!ReadBigEndianDword(pFile, m_NumRecords)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown2)) return false;

		for (dword i = 0; i < m_NumRecords; ++i)
		{
			CEsoDataTableRecord Record;

			if (!Record.Read(pFile)) return false;

			m_Records.push_back(Record);
		}

		long LastOffset = ftell(pFile);
		fseek(pFile, 0, SEEK_END);
		long FileSize = ftell(pFile);

		if (FileSize > LastOffset) ReportError("Warning: %d extra bytes left at end of file!", FileSize - LastOffset);
		
		return true;
	}


	bool ReadHeaders(FILE* pFile)
	{
		if (!ReadBigEndianDword(pFile, m_MagicBytes)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown1)) return false;
		if (!ReadBigEndianDword(pFile, m_NumRecords)) return false;
		if (!ReadBigEndianDword(pFile, m_Unknown2)) return false;

		for (dword i = 0; i < m_NumRecords; ++i)
		{
			CEsoDataTableRecord Record;

			if (!Record.ReadHeaders(pFile)) return false;

			m_Records.push_back(Record);
		}

		long LastOffset = ftell(pFile);
		fseek(pFile, 0, SEEK_END);
		long FileSize = ftell(pFile);

		if (FileSize > LastOffset) ReportError("Warning: %d extra bytes left at end of file!", FileSize - LastOffset);

		return true;
	}

};


CEsoDataTable g_DataTable;


bool LoadTables(const std::string Filename)
{
	FILE* pFile = fopen(Filename.c_str(), "rb");
	if (pFile == nullptr) return ReportError("Failed to open '%s' for reading!", Filename.c_str());

	g_DataTable.Read(pFile);

	fclose(pFile);
	return true;
}


bool LoadTableHeaders(const std::string Filename)
{
	FILE* pFile = fopen(Filename.c_str(), "rb");
	if (pFile == nullptr) return ReportError("Failed to open '%s' for reading!", Filename.c_str());

	g_DataTable.ReadHeaders(pFile);

	fclose(pFile);
	return true;
}


int main()
{
	
	if (!LoadTableHeaders(INPUT_FILENAME1))
	{
		ReportError("Failed to load file!");
		return -1;
	}

	g_DataTable.DumpHeaders();
	//g_DataTable.DumpPhp();
	//g_DataTable.DumpSummary();

    return 0;
}

