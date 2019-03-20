#include "stdafx.h"
#include <string>
#include <vector>
#include "EsoCommon.h"
#include "EsoFile.h"
#include <stdarg.h>

using namespace eso;

	// The file extracted from ESO.MNF that contains the skill data
const std::string SKILLDATA_FILENAME = "e:/esoexport/esomnf-21pts/000/694374_Uncompressed.EsoFileData";

const std::string OUTPUT_FILENAME = "e:/esoexport/goodimages-21pts/SummarySkills.csv";

const fpos_t SKILLDATA_RECORDSIZE_OFFSET = 32;

const size_t U2SIZE = 24;
const size_t FLAGSIZE = 175;
const size_t U6SIZE = 6;
const size_t U6ASIZE = 6;
const size_t U7SIZE = 8;
const size_t U8SIZE = 24;
const size_t U9SIZE = 4;
const size_t U10SIZE = 9;
const size_t U11SIZE = 16;
const size_t U12SIZE = 23;

typedef std::vector<dword> idlist_t;

struct skilldata_t
{
	fpos_t startOffset;
	fpos_t endOffset;

	dword magicHeader;	// ####
	dword mnfIndex;
	dword uncompressedSize1;
	dword uncompressedSize2;
	dword compressedSize;
	dword mnfId;
	dword origFileOffset;
	dword uncompressedSize;

	dword id;
	std::string name;

	byte u1;
	word u1a;
	dword u2[U2SIZE];	//3 = time_t
	byte flags[FLAGSIZE];

	dword size1;		// Synergy Types
	idlist_t list1;

	dword size2;		// Synergy IDs
	idlist_t list2;

	dword u6[U6SIZE];

	dword size6a;
	idlist_t list6a;

	dword u6a[U6ASIZE];	

	dword size6aa;
	idlist_t list6aa;

	dword size6ab;
	idlist_t list6ab;

	dword size3;	// Coef types
	idlist_t list3;

	dword size4;	// Coef IDs
	idlist_t list4;

	dword u7[U7SIZE];	//IDs?
		
	dword size5;
	idlist_t list5;

	dword size6;
	idlist_t list6;

	dword u8[U8SIZE];

	dword size7;
	idlist_t list7;

	dword u9[U9SIZE];
		
	dword size8;
	idlist_t list8;

	dword u8a;
	dword u8b;
	//dword u8c;

	dword size9;
	idlist_t list9;

	dword size10;
	idlist_t list10;

	dword u10[U10SIZE];

	dword size11;
	idlist_t list11;

	dword size12;
	idlist_t list12;

	dword u11[U11SIZE];

	dword size13;
	idlist_t list13;

	dword u12[U12SIZE];
};


std::vector<skilldata_t> g_Skills;
std::vector<dword> g_ZeroCounts(200, 0);
dword g_MagicHeader = 0;
dword g_Unknown1Header = 0;
dword g_Unknown2Header = 0;
dword g_NumRecordsHeader = 0;
fpos_t g_SizeOfSkillsFile = 0;


bool ReportError(const char* pFmt, ...)
{
	va_list Args;

	va_start(Args, pFmt);
	vprintf(pFmt, Args);
	va_end(Args);

	printf("\n");

	return false;
}


void AnalyzeZerosSkill(skilldata_t& skill)
{
	if (skill.u1 == 0) g_ZeroCounts[0]++;
	if (skill.u1a == 0) g_ZeroCounts[1]++;

	for (dword i = 0; i < U2SIZE; ++i)
	{
		if (skill.u2[i] == 0) g_ZeroCounts[2 + i]++;
	}

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		if (skill.flags[i] == 0) g_ZeroCounts[1 + 1 + U2SIZE + i]++;
	}

	if (skill.size1 == 0) g_ZeroCounts[1 + 1 + U2SIZE + FLAGSIZE + 1]++;
}


void PrintZeros()
{
	printf("Showing zero record field data:\n");

	for (dword i = 0; i < 198; ++i)
	{
		float percent = (float) g_ZeroCounts[i] / g_Skills.size() * 100;
		printf("\t%3d: %6u (%0.1f%%) \n", i, g_ZeroCounts[i], percent);
	}
}


void AnalyzeZeros()
{

	for (auto&& skill : g_Skills)
	{
		AnalyzeZerosSkill(skill);
	}

}


void AnalyzeNames()
{
	size_t minLength = 1000;
	size_t maxLength = 0;
	size_t numEmpty = 0;

	for (auto&& skill : g_Skills)
	{
		size_t length = skill.name.length();
		if (length > maxLength) maxLength = length;
		if (length < minLength) minLength = length;
		if (length == 0) ++numEmpty;
	}

	printf("Empty Name Strings = %d\n", numEmpty);
	printf("Min Name Length = %d\n", minLength);
	printf("Max Name Length = %d\n", maxLength);
}


bool ReadSkillRecord(CFile& File)
{
	skilldata_t skill;
	bool result = true;
	word stringSize = 0;

	skill.startOffset = File.Tell();

	result &= File.ReadDword(skill.magicHeader, false);
	result &= File.ReadDword(skill.mnfIndex, false);
	result &= File.ReadDword(skill.uncompressedSize1, false);
	result &= File.ReadDword(skill.uncompressedSize2, false);
	result &= File.ReadDword(skill.compressedSize, false);
	result &= File.ReadDword(skill.mnfId, false);
	result &= File.ReadDword(skill.origFileOffset, false);
	result &= File.ReadDword(skill.uncompressedSize, false);

	if (!result) return ReportError("Error: Failed to read skill data header!");
	if (skill.magicHeader != 0x23232323) return ReportError("Error: Skill data header 0x%08X not expected value!", skill.magicHeader);

	skill.endOffset = skill.startOffset + skill.uncompressedSize1 + SKILLDATA_RECORDSIZE_OFFSET;

	result &= File.ReadDword(skill.id, false);
	result &= File.ReadWord(stringSize, false);

	skill.name.resize(stringSize + 4);
	result &= File.ReadBytes((byte *) skill.name.data(), stringSize);
	skill.name[stringSize] = 0;

	skill.name = ReplaceStrings(skill.name, "\xE2\x80\xA6", "...");

	if (!result) return ReportError("Error: Failed to read skill id/name!");
	
	result &= File.ReadByte(skill.u1);
	result &= File.ReadWord(skill.u1a, false);

	for (dword i = 0; i < U2SIZE; ++i)
	{
		result &= File.ReadDword(skill.u2[i], false);
	}

	result &= File.ReadBytes((byte *)skill.flags, FLAGSIZE);

	if (!result) return ReportError("Error: Failed to read skill.flags data!");

	result &= File.ReadDword(skill.size1, false);
	skill.list1.resize(skill.size1, 0);

	for (size_t i = 0; i < skill.size1; ++i)
	{
		result &= File.ReadDword(skill.list1[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list1 data!");

	result &= File.ReadDword(skill.size2, false);
	skill.list2.resize(skill.size2, 0);

	for (size_t i = 0; i < skill.size2; ++i)
	{
		result &= File.ReadDword(skill.list2[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list2 data!");

	for (dword i = 0; i < U6SIZE; ++i)
	{
		result &= File.ReadDword(skill.u6[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u6 data!");

	result &= File.ReadDword(skill.size6a, false);
	skill.list6a.resize(skill.size6a, 0);

	for (size_t i = 0; i < skill.size6a; ++i)
	{
		result &= File.ReadDword(skill.list6a[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6a data!");

	for (dword i = 0; i < U6ASIZE; ++i)
	{
		result &= File.ReadDword(skill.u6a[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u6a data!");

	result &= File.ReadDword(skill.size6aa, false);
	skill.list6aa.resize(skill.size6aa, 0);

	for (size_t i = 0; i < skill.size6aa; ++i)
	{
		result &= File.ReadDword(skill.list6aa[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6aa data!");

	result &= File.ReadDword(skill.size6ab, false);
	skill.list6ab.resize(skill.size6ab, 0);

	for (size_t i = 0; i < skill.size6ab; ++i)
	{
		result &= File.ReadDword(skill.list6ab[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6ab data!");

	result &= File.ReadDword(skill.size3, false);
	skill.list3.resize(skill.size3, 0);

	for (size_t i = 0; i < skill.size3; ++i)
	{
		result &= File.ReadDword(skill.list3[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list3 data!");

	result &= File.ReadDword(skill.size4, false);
	skill.list4.resize(skill.size4, 0);

	for (size_t i = 0; i < skill.size4; ++i)
	{
		result &= File.ReadDword(skill.list4[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list4 data!");

	for (dword i = 0; i < U7SIZE; ++i)
	{
		result &= File.ReadDword(skill.u7[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u7 data!");

	result &= File.ReadDword(skill.size5, false);
	skill.list5.resize(skill.size5, 0);

	for (size_t i = 0; i < skill.size5; ++i)
	{
		result &= File.ReadDword(skill.list5[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list5 data!");
//*
	result &= File.ReadDword(skill.size6, false);
	skill.list6.resize(skill.size6, 0);

	for (size_t i = 0; i < skill.size6; ++i)
	{
		result &= File.ReadDword(skill.list6[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6 data!"); //*/

	for (dword i = 0; i < U8SIZE; ++i)
	{
		result &= File.ReadDword(skill.u8[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u8 data!");

	result &= File.ReadDword(skill.size7, false);
	skill.list7.resize(skill.size7, 0);

	for (size_t i = 0; i < skill.size7; ++i)
	{
		result &= File.ReadDword(skill.list7[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list7 data!");

	for (dword i = 0; i < U9SIZE; ++i)
	{
		result &= File.ReadDword(skill.u9[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u9 data!");
	
	result &= File.ReadDword(skill.size8, false);
	skill.list8.resize(skill.size8, 0);

	for (size_t i = 0; i < skill.size8; ++i)
	{
		result &= File.ReadDword(skill.list8[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list8 data!");//*/

	result &= File.ReadDword(skill.u8a, false);
	result &= File.ReadDword(skill.u8b, false);
	//result &= File.ReadDword(skill.u8c, false);

	result &= File.ReadDword(skill.size9, false);
	skill.list9.resize(skill.size9, 0);

	for (size_t i = 0; i < skill.size9; ++i)
	{
		result &= File.ReadDword(skill.list9[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list9 data!");

	result &= File.ReadDword(skill.size10, false);
	skill.list10.resize(skill.size10, 0);

	for (size_t i = 0; i < skill.size10; ++i)
	{
		result &= File.ReadDword(skill.list10[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list10 data!");

	for (dword i = 0; i < U10SIZE; ++i)
	{
		result &= File.ReadDword(skill.u10[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u10 data!");

	result &= File.ReadDword(skill.size11, false);
	skill.list11.resize(skill.size11, 0);

	for (size_t i = 0; i < skill.size11; ++i)
	{
		result &= File.ReadDword(skill.list11[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list11 data!");

	result &= File.ReadDword(skill.size12, false);
	skill.list12.resize(skill.size12, 0);

	for (size_t i = 0; i < skill.size12; ++i)
	{
		result &= File.ReadDword(skill.list12[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list12 data!");

	for (dword i = 0; i < U11SIZE; ++i)
	{
		result &= File.ReadDword(skill.u11[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u11 data!");

	result &= File.ReadDword(skill.size13, false);
	skill.list13.resize(skill.size13*2, 0);

	for (size_t i = 0; i < skill.size13*2; ++i)
	{
		result &= File.ReadDword(skill.list13[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list13 data!");

	for (dword i = 0; i < U12SIZE; ++i)
	{
		result &= File.ReadDword(skill.u12[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u12 data!");


	fpos_t curPos = File.Tell();

	if (curPos != skill.endOffset)
	{
		ReportError("\t%08I64X: Under/over read skill by %I64d bytes!", skill.startOffset, skill.endOffset - curPos);
	}

	result = File.Seek(skill.endOffset, SEEK_SET);
	if (!result) return ReportError("Error: Failed to skill to end of skill data 0x%08I64X!", skill.endOffset);

	g_Skills.push_back(skill);
	return true;
}


bool ReadSkillRecords(CFile& File)
{
	dword recordCount = 0;
	dword result;
	fpos_t offset;

	do {
		offset = File.Tell();

		if (offset >= g_SizeOfSkillsFile) 
		{
			ReportError("Reached end of file (%d bytes left over)!", g_SizeOfSkillsFile - offset);
			break;
		}

		result = ReadSkillRecord(File);
		if (result) ++recordCount;
	} while (result);

	ReportError("Read %u of %u skill records!", recordCount, g_NumRecordsHeader);

	return true;
}


bool LoadSkillData(const std::string filename)
{
	CFile File;
	bool result = true;

	ReportError("Loading and parsing skill data file '%s'...", filename.c_str());

	if (!File.Open(filename, "rb")) return ReportError("Error: Failed to open file!");

	g_SizeOfSkillsFile = File.GetSize();

	result &= File.ReadDword(g_MagicHeader, false);
	result &= File.ReadDword(g_Unknown1Header, false);
	result &= File.ReadDword(g_NumRecordsHeader, false);
	result &= File.ReadDword(g_Unknown2Header, false);

	if (!result) return ReportError("Error: Failed to read file header!");

	if (g_MagicHeader != 0xFAFAEBEB) return ReportError("Error: Magic header 0x%08X not expected value!", g_MagicHeader);
	
	result = ReadSkillRecords(File);

	return result;
}



void AnalyzeFlags()
{
	dword numZeros = 0;
	dword numOnes = 0;
	dword numOther = 0;

	for (auto&& skill : g_Skills)
	{

		for (size_t i = 0; i < FLAGSIZE; ++i)
		{
			byte flags = skill.flags[i];

			if (flags == 0)
				++numZeros;
			else if (flags == 1)
				++numOnes;
			else
				++numOther;

		}
	}

	printf("0 Flags = %u\n", numZeros);
	printf("1 Flags = %u\n", numOnes);
	printf("# Flags = %u\n", numOther);
}


void OutputSummaryCsv()
{
	CFile File;

	File.Open(OUTPUT_FILENAME, "wb");

	for (auto&& skill : g_Skills)
	{
		File.Printf("%07d, ", skill.id);
		File.Printf("\"%36s\", ", skill.name.c_str());
		File.Printf("%02X,", skill.u1);
		File.Printf("%04X,", skill.u1a);

		for (dword i = 0; i < 26; ++i)
		{
			File.Printf("%08X,", skill.u2[i]);
		}

		for (dword i = 0; i < FLAGSIZE; ++i)
		{
			File.Printf("%d,", skill.flags[i]);
		}

		File.Printf("%08X,", skill.size1);
		File.Printf("%08X,", skill.size2);

		File.Printf("\n");
	}
}


int main()
{
	if (!LoadSkillData(SKILLDATA_FILENAME)) return ReportError("Failed to load file!");

	AnalyzeZeros();
	PrintZeros();

	AnalyzeNames();
	AnalyzeFlags();

	//OutputSummaryCsv();

    return 0;
}


