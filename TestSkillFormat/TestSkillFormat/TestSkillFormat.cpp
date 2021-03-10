#include "stdafx.h"
#include <string>
#include <vector>
#include "EsoCommon.h"
#include "EsoFile.h"
#include <stdarg.h>
#include <unordered_map>
#include <regex>

using namespace eso;

	// The file extracted from ESO.MNF that contains the skill data
//const std::string SKILLDATA_FILENAME = "e:/esoexport/esomnf-21pts/000/694374_Uncompressed.EsoFileData";

//const std::string SKILLDATA_FILENAME = "e:/esoexport/esomnf-29pts/000/807315_Uncompressed.EsoFileData";
//const std::string SKILLDATA_MINEDSKILLS_FILENAME = "e:/esoexport/goodimages-29pts/minedSkills29pts.csv";
//const std::string SKILLDATA_SKILLDESC_FILENAME = "e:/esoexport/goodimages-29pts/skillDesc29pts.csv";

const std::string SKILLDATA_FILENAME = "e:/esoexport/esomnf-29pts1/000/807785_Uncompressed.EsoFileData";
const std::string SKILLDATA_MINEDSKILLS_FILENAME = "e:/esoexport/goodimages-29pts1/minedSkills29pts.csv";
const std::string SKILLDATA_SKILLDESC_FILENAME = "e:/esoexport/goodimages-29pts1/skillDesc29pts.csv";
const std::string AOEHEALS_FILENAME = "e:/esoexport/goodimages-29pts1/AoeHeals.csv";
const std::string HOTHEALS_FILENAME = "e:/esoexport/goodimages-29pts1/HotHeals.csv";
const std::string STHEALS_FILENAME = "e:/esoexport/goodimages-29pts1/SingleTargetHeals.csv";
const std::string ALLHEALS_FILENAME = "e:/esoexport/goodimages-29pts1/HealingSpells.csv";

//const std::string OUTPUT_CSV_FILENAME = "e:/esoexport/goodimages-21pts/SummarySkills.csv";
//const std::string OUTPUT_CSV_FILENAME = "e:/esoexport/goodimages-29pts/SkillData/SummarySkills.csv";
//const std::string OUTPUT_FLAG_PATH = "e:/esoexport/goodimages-29pts/SkillData/";
//const std::string OUTPUT_SKILL_PATH = "e:/esoexport/goodimages-29pts/SkillData/Skills/";

const std::string OUTPUT_CSV_FILENAME = "e:/esoexport/goodimages-29pts1/SkillData/SummarySkills.csv";
const std::string OUTPUT_FLAG_PATH = "e:/esoexport/goodimages-29pts1/SkillData/";
const std::string OUTPUT_SKILL_PATH = "e:/esoexport/goodimages-29pts1/SkillData/Skills/";

const fpos_t SKILLDATA_RECORDSIZE_OFFSET = 32;

	/* Update 21 */
/*const size_t U2SIZE = 24;
const size_t FLAGSIZE = 175;
const size_t U6SIZE = 6;
const size_t U6ASIZE = 6;
const size_t U7SIZE = 8;
const size_t U8SIZE = 24;
const size_t U9SIZE = 4;
const size_t U10SIZE = 9;
const size_t U11SIZE = 16;
const size_t U12SIZE = 23; //*/

	/* Update 29 */
const size_t U2SIZE = 22;
const size_t FLAGSIZE = 189;	//188 in first 29pts version
const size_t U6SIZE = 6;
const size_t U6ASIZE = 7;
const size_t U7SIZE = 9;
const size_t U8SIZE = 25;
const size_t U9SIZE = 4;
const size_t U10SIZE = 9;
const size_t U11SIZE = 16;
const size_t U12SIZE = 22;
const size_t U13SIZE = 2;

typedef std::vector<dword> idlist_t;

/*
struct skilldata_21_t
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

	byte u1;			// Zero
	word u1a;			// Zero
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
}; //*/


struct skilllist_t {
	int abilityId;
	std::string name;
	std::vector<int> indexes;
};

std::vector<skilllist_t> g_AoeHealSkills;
std::vector<skilllist_t> g_HotHealSkills;
std::vector<skilllist_t> g_StHealSkills;
std::vector<skilllist_t> g_AllHealSkills;


struct skilldata_t
{
	fpos_t startOffset;
	fpos_t endOffset;

	dword magicHeader;			// ####
	dword index;				// Consecutive number starting at 1
	dword recordLength1;		// Always the same as recordLength2 and recordLength3
	dword recordLength2;
	dword unknown1;
	dword unknown2;
	dword abilityId1;			// Always the same as abilityId2
	dword recordLength3;

	dword abilityId2;
	std::string name;

	byte zero1;					// Always 0
	word zero2;					// Always 0
	dword zero3;				// Always 0

	word u20a;
	word u20b;

	dword zero4;

	dword u2[U2SIZE];
	byte flags[FLAGSIZE];

	dword size1;
	idlist_t list1;

	dword size2;
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

	//dword size5;
	//idlist_t list5;

	dword size6;
	idlist_t list6;

	dword size6b;
	idlist_t list6b;

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

	dword size14;
	idlist_t list14;

	dword u13[U13SIZE];
};


struct minedskill_t
{
	int abilityId;
	int displayId;
	std::string name;
	std::string description;
	std::string target;
	int skillType;
	std::string upgradeLines;
	std::string effectLines;
	int duration;
	int cost;
	int minRange;
	int maxRange;
	int radius;
	bool isPassive;
	bool isChanneled;
	bool isPermanent;
	int castTime;
	int channelTime;
	int angleDistance;
	int mechanic;
	std::string texture;
	bool isPlayer;
	int raceType;
	int classType;
	int skillLine;
	int prevSkill;
	int nextSkill;
	int nextSkill2;
	int baseAbilityId;
	int learnedLevel;
	int rank;
	int morph;
	int skillIndex;
	int buffType;
	bool isToggle;
	int chargeFreq;
	int numCoefVars;
	std::string coefDescription;

	int type[6];
	float a[6];
	float b[6];
	float c[6];
	float r[6];
	float avg[6];
};



std::vector<skilldata_t> g_Skills;
std::unordered_map<int, minedskill_t> g_MinedSkills;
std::unordered_map<int, std::string> g_SkillDescriptions;

std::unordered_map<dword, dword> g_ValidSkillIds;
std::unordered_map<std::string, dword> g_OtherZeroes;
std::vector<dword> g_ZeroCounts(500, 0);
std::vector<dword> g_FlagCounts(FLAGSIZE, 0);
std::vector<int> g_MinU2Values(U2SIZE + 2, INT_MAX);
std::vector<int> g_MaxU2Values(U2SIZE + 2, INT_MIN);

//std::unordered_map<dword, dword> g_List8Sizes;
std::vector<std::unordered_map<int, int>> g_U8Values(U8SIZE);
std::vector<int> g_MinU8Values(U8SIZE, INT_MAX);
std::vector<int> g_MaxU8Values(U8SIZE, INT_MIN);

std::vector<std::unordered_map<int, int>> g_List1Values;
std::vector<std::unordered_map<int, int>> g_List3Values;

dword g_MagicHeader = 0;
dword g_Unknown1Header = 0;
dword g_Unknown2Header = 0;
dword g_NumRecordsHeader = 0;
fpos_t g_SizeOfSkillsFile = 0;
dword g_SkillIndex = 0;


struct idlistinfo_t {
	std::string name;

	int totalChecked;
	int totalEmpty;
	int totalEntries;
	int validIdCount;

	idlistinfo_t() : totalEmpty(0), validIdCount(0), totalChecked(0), totalEntries(0)
	{
	}
};

std::unordered_map<std::string, idlistinfo_t> g_IdListInfos;


bool ReportError(const char* pFmt, ...)
{
	va_list Args;

	va_start(Args, pFmt);
	vprintf(pFmt, Args);
	va_end(Args);

	printf("\n");

	return false;
}


void AnalyzeFlagsSkill(skilldata_t& skill)
{

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		if (skill.flags[i] != 0 && skill.flags[i] != 1) g_FlagCounts[i]++;
	}
}


void CheckZero(std::string name, dword value)
{
	if (value == 0) g_OtherZeroes[name]++;
}


void CheckZeroArray(std::string name, dword array[], dword arraySize)
{
	for (size_t i = 0; i < arraySize; ++i)
	{
		CheckZero(name + std::to_string(i), array[i]);
	}
}


void AnalyzeZerosSkill(skilldata_t& skill)
{
	if (skill.zero1 == 0) g_ZeroCounts[0]++;
	if (skill.zero2 == 0) g_ZeroCounts[1]++;
	if (skill.zero3 == 0) g_ZeroCounts[2]++;
	if (skill.u20a == 0) g_ZeroCounts[3]++;
	if (skill.u20b == 0) g_ZeroCounts[4]++;
	if (skill.zero4 == 0) g_ZeroCounts[5]++;

	for (dword i = 0; i < U2SIZE; ++i)
	{
		if (skill.u2[i] == 0) g_ZeroCounts[6 + i]++;
	}

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		if (skill.flags[i] == 0) g_ZeroCounts[6 + U2SIZE + i]++;
	}

	if (skill.size1 == 0) g_ZeroCounts[6 + U2SIZE + FLAGSIZE]++;

	//CheckZeroArray();
	//CheckZero();
	/*
	dword u6[U6SIZE];
	dword u6a[U6ASIZE];
	dword u7[U7SIZE];
	dword u8[U8SIZE];
	dword u9[U9SIZE];
	dword u8a;
	dword u8b;
	dword u10[U10SIZE];
	dword u11[U11SIZE];
	dword u12[U12SIZE];
	dword u13[U13SIZE];
	*/
	CheckZeroArray("u6", skill.u6, U6SIZE);
	CheckZeroArray("u6a", skill.u6a, U6ASIZE);
	CheckZeroArray("u7", skill.u7, U7SIZE);
	CheckZeroArray("u8", skill.u8, U8SIZE);
	CheckZeroArray("u9", skill.u9, U9SIZE);
	CheckZeroArray("u10", skill.u10, U10SIZE);
	CheckZeroArray("u11", skill.u11, U11SIZE);
	CheckZeroArray("u12", skill.u12, U12SIZE);
	CheckZeroArray("u13", skill.u13, U13SIZE);

	CheckZero("u8a", skill.u8a);
	CheckZero("u8b", skill.u8b);
}


void PrintU2Data()
{
	printf("Showing U2 Data:\n");

	for (dword i = 0; i < g_MinU2Values.size(); ++i)
	{
		int min = g_MinU2Values[i];
		int max = g_MaxU2Values[i];

		printf("\t%d) %d - %d (0x%08X - 0x%08X)\n", i, min, max, min, max);
	}
}


void PrintZeros()
{
	size_t totalCount = g_Skills.size();

	printf("Showing zero record field data:\n");

	for (dword i = 0; i < 6 + U2SIZE + FLAGSIZE + 1; ++i)
	{
		float percent = (float) g_ZeroCounts[i] / totalCount * 100;
		dword j = i;

		if (i == 0)
			printf("Zero Fields:\n");
		else if (i == 6)
			printf("U2 Data:\n");
		else if (i == 6 + U2SIZE)
			printf("Flags:\n");
		else if (i == 6 + U2SIZE + FLAGSIZE)
			printf("Size1:\n");

		if (i < 6)
			j = i;
		else if (i < 6 + U2SIZE)
			j = i - 6;
		else if (i < 6 + U2SIZE + FLAGSIZE)
			j = i - 6 - U2SIZE;
		else 
			j = i - 6 - U2SIZE - FLAGSIZE;

		if (totalCount == g_ZeroCounts[i])
			printf("\t%3d: %6u (ALL) \n", j, g_ZeroCounts[i]);
		else
			printf("\t%3d: %6u (%0.1f%%)  %6u\n", j, g_ZeroCounts[i], percent, (int)totalCount - g_ZeroCounts[i]);
	}

	printf("Other Zero Data:\n");

	for (auto i : g_OtherZeroes)
	{
		float percent = (float)i.second / totalCount * 100;

		if (totalCount == i.second)
			printf("\t%s: %6u (ALL)\n", i.first.c_str(), i.second);
		else
			printf("\t%s: %6u (%0.1f%%)\n", i.first.c_str(), i.second, percent);
	}

}

void PrintFlags()
{
	printf("Showing non 0/1 flag data:\n");

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		if (g_FlagCounts[i] > 0)
			printf("\t%3d: %6u not 0/1 \n", i, g_FlagCounts[i]);
		else
			printf("\t%3d: All 0/1\n", i);
	}
}


void AnalyzeZeros()
{

	for (auto&& skill : g_Skills)
	{
		AnalyzeZerosSkill(skill);
	}

}


void AnalyzeU2DataSkill(skilldata_t& skill)
{
	for (dword i = 0; i < U2SIZE; ++i)
	{
		int value = (int)skill.u2[i];
		if (value < g_MinU2Values[i]) g_MinU2Values[i] = value;
		if (value > g_MaxU2Values[i]) g_MaxU2Values[i] = value;
	}

	int value = (int)skill.u20a;
	if (value < g_MinU2Values[U2SIZE]) g_MinU2Values[U2SIZE] = value;
	if (value > g_MaxU2Values[U2SIZE]) g_MaxU2Values[U2SIZE] = value;

	value = (int)skill.u20b;
	if (value < g_MinU2Values[U2SIZE + 1]) g_MinU2Values[U2SIZE + 1] = value;
	if (value > g_MaxU2Values[U2SIZE + 1]) g_MaxU2Values[U2SIZE + 1] = value;
}


void AnalyzeU2Data()
{

	for (auto&& skill : g_Skills)
	{
		AnalyzeU2DataSkill(skill);
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

	printf("Empty Name Strings = %zu\n", numEmpty);
	printf("Min Name Length = %zu\n", minLength);
	printf("Max Name Length = %zu\n", maxLength);
}


bool ReadSkillRecord(CFile& File)
{
	skilldata_t skill;
	bool result = true;
	word stringSize = 0;

	++g_SkillIndex;

	skill.startOffset = File.Tell();
	//ReportError("%06d: 0x%08X", g_SkillIndex, skill.startOffset);

	result &= File.ReadDword(skill.magicHeader, false);
	result &= File.ReadDword(skill.index, false);
	result &= File.ReadDword(skill.recordLength1, false);
	result &= File.ReadDword(skill.recordLength2, false);
	result &= File.ReadDword(skill.unknown1, false);
	result &= File.ReadDword(skill.unknown2, false);
	result &= File.ReadDword(skill.abilityId1, false);
	result &= File.ReadDword(skill.recordLength3, false);

	if (!result) return ReportError("Error: Failed to read skill data header!");
	if (skill.magicHeader != 0x23232323) return ReportError("Error: Skill data header 0x%08X not expected value!", skill.magicHeader);
	if (skill.index != g_SkillIndex) ReportError("Skill Index Mismatch: %d != %d", skill.index, g_SkillIndex);

	if (skill.recordLength1 != skill.recordLength2) ReportError("Record Length 1+2 Mismatch: 0x%08lX 0x%08lX ", skill.recordLength1, skill.recordLength2);
	if (skill.recordLength1 != skill.recordLength3) ReportError("Record Length 1+3 Mismatch: 0x%08lX 0x%08lX ", skill.recordLength1, skill.recordLength3);
	if (skill.recordLength2 != skill.recordLength3) ReportError("Record Length 2+3 Mismatch: 0x%08lX 0x%08lX ", skill.recordLength2, skill.recordLength3);

	skill.endOffset = skill.startOffset + skill.recordLength1 + SKILLDATA_RECORDSIZE_OFFSET;

	result &= File.ReadDword(skill.abilityId2, false);
	if (skill.abilityId1 != skill.abilityId2) ReportError("Ability ID 1+2 Mismatch: 0x%08lX 0x%08lX ", skill.abilityId1, skill.abilityId2);
	g_ValidSkillIds[skill.abilityId1] = g_SkillIndex;

	result &= File.ReadWord(stringSize, false);
	skill.name.resize(stringSize + 4);
	result &= File.ReadBytes((byte *) skill.name.data(), stringSize);
	skill.name[stringSize] = 0;

	skill.name = ReplaceStrings(skill.name, "\xE2\x80\xA6", "...");

	if (!result) return ReportError("Error: Failed to read skill id/name!");
	
	result &= File.ReadByte(skill.zero1);
	result &= File.ReadWord(skill.zero2, false);
	result &= File.ReadDword(skill.zero3, false);
	result &= File.ReadWord(skill.u20a, false);
	result &= File.ReadWord(skill.u20b, false);
	result &= File.ReadDword(skill.zero4, false);

	for (dword i = 0; i < U2SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u2[i], false);
	}

	result &= File.ReadBytes((byte *)skill.flags, FLAGSIZE);

	if (!result) return ReportError("Error: Failed to read skill.flags data!");

	result &= File.ReadDword(skill.size1, false);
	skill.list1.resize(skill.size1, 0);

	for (size_t i = 0; i < skill.size1 && result; ++i)
	{
		result &= File.ReadDword(skill.list1[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list1 data!");

	result &= File.ReadDword(skill.size2, false);
	skill.list2.resize(skill.size2, 0);

	for (size_t i = 0; i < skill.size2 && result; ++i)
	{
		result &= File.ReadDword(skill.list2[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list2 data!");

	for (dword i = 0; i < U6SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u6[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u6 data!");

	result &= File.ReadDword(skill.size6a, false);
	skill.list6a.resize(skill.size6a, 0);

	for (size_t i = 0; i < skill.size6a && result; ++i)
	{
		result &= File.ReadDword(skill.list6a[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6a data!");

	for (dword i = 0; i < U6ASIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u6a[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u6a data!");

	result &= File.ReadDword(skill.size6aa, false);
	skill.list6aa.resize(skill.size6aa, 0);

	for (size_t i = 0; i < skill.size6aa && result; ++i)
	{
		result &= File.ReadDword(skill.list6aa[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6aa data!");

	result &= File.ReadDword(skill.size6ab, false);
	skill.list6ab.resize(skill.size6ab, 0);

	for (size_t i = 0; i < skill.size6ab && result; ++i)
	{
		result &= File.ReadDword(skill.list6ab[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6ab data!");

	result &= File.ReadDword(skill.size3, false);
	skill.list3.resize(skill.size3, 0);

	for (size_t i = 0; i < skill.size3 && result; ++i)
	{
		result &= File.ReadDword(skill.list3[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list3 data!");

	result &= File.ReadDword(skill.size4, false);
	skill.list4.resize(skill.size4, 0);

	for (size_t i = 0; i < skill.size4 && result; ++i)
	{
		result &= File.ReadDword(skill.list4[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list4 data!");

	for (dword i = 0; i < U7SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u7[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u7 data!");
/*
	result &= File.ReadDword(skill.size5, false);
	skill.list5.resize(skill.size5, 0);

	for (size_t i = 0; i < skill.size5 && result; ++i)
	{
		result &= File.ReadDword(skill.list5[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list5 data!"); */
//*
	result &= File.ReadDword(skill.size6, false);
	skill.list6.resize(skill.size6, 0);

	for (size_t i = 0; i < skill.size6 && result; ++i)
	{
		result &= File.ReadDword(skill.list6[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6 data!"); //*/

	result &= File.ReadDword(skill.size6b, false);
	skill.list6b.resize(skill.size6b, 0);

	for (size_t i = 0; i < skill.size6b && result; ++i)
	{
		result &= File.ReadDword(skill.list6b[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list6 data!"); //*/

	for (dword i = 0; i < U8SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u8[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u8 data!");

	result &= File.ReadDword(skill.size7, false);
	skill.list7.resize(skill.size7, 0);

	for (size_t i = 0; i < skill.size7 && result; ++i)
	{
		result &= File.ReadDword(skill.list7[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list7 data!");

	for (dword i = 0; i < U9SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u9[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u9 data!");
	
	result &= File.ReadDword(skill.size8, false);
	skill.list8.resize(skill.size8, 0);

	for (size_t i = 0; i < skill.size8 && result; ++i)
	{
		result &= File.ReadDword(skill.list8[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list8 data!");//*/

	result &= File.ReadDword(skill.u8a, false);
	result &= File.ReadDword(skill.u8b, false);
	//result &= File.ReadDword(skill.u8c, false);

	result &= File.ReadDword(skill.size9, false);
	skill.list9.resize(skill.size9, 0);

	for (size_t i = 0; i < skill.size9 && result; ++i)
	{
		result &= File.ReadDword(skill.list9[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list9 data!");

	result &= File.ReadDword(skill.size10, false);
	skill.list10.resize(skill.size10, 0);

	for (size_t i = 0; i < skill.size10 && result; ++i)
	{
		result &= File.ReadDword(skill.list10[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list10 data!");

	for (dword i = 0; i < U10SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u10[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u10 data!");

	result &= File.ReadDword(skill.size11, false);
	skill.list11.resize(skill.size11, 0);

	for (size_t i = 0; i < skill.size11 && result; ++i)
	{
		result &= File.ReadDword(skill.list11[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list11 data!");

	result &= File.ReadDword(skill.size12, false);
	skill.list12.resize(skill.size12, 0);

	for (size_t i = 0; i < skill.size12 && result; ++i)
	{
		result &= File.ReadDword(skill.list12[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list12 data!");

	for (dword i = 0; i < U11SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u11[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u11 data!");

	result &= File.ReadDword(skill.size13, false);
	skill.list13.resize(skill.size13*2, 0);

	for (size_t i = 0; i < skill.size13*2 && result; ++i)
	{
		result &= File.ReadDword(skill.list13[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list13 data!");

	for (dword i = 0; i < U12SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u12[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u12 data!");

	result &= File.ReadDword(skill.size14, false);
	skill.list14.resize(skill.size14 * 2, 0);

	for (size_t i = 0; i < skill.size14 * 2 && result; ++i)
	{
		result &= File.ReadDword(skill.list14[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.list13 data!");

	for (dword i = 0; i < U13SIZE && result; ++i)
	{
		result &= File.ReadDword(skill.u13[i], false);
	}

	if (!result) return ReportError("Error: Failed to read skill.u13 data!");


	fpos_t curPos = File.Tell();

	if (curPos == skill.endOffset)
	{

	}
	else if (curPos > skill.endOffset)
	{
		ReportError("\t%08I64X: #%06d: Over read skill by %I64d bytes!", skill.startOffset, g_SkillIndex, curPos - skill.endOffset);
	}
	else if (curPos < skill.endOffset)
	{
		ReportError("\t%08I64X: #%06d: Under read skill by %I64d bytes!", skill.startOffset, g_SkillIndex, skill.endOffset - curPos);
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


void AnalyzeIdList(std::string name, idlist_t& idList)
{
	if (g_IdListInfos.find(name) == g_IdListInfos.end())
	{
		idlistinfo_t newInfo;
		newInfo.name = name;
		g_IdListInfos[name] = newInfo;
	}

	idlistinfo_t& idListInfo = g_IdListInfos[name];

	++idListInfo.totalChecked;

	if (idList.size() == 0)
	{
		++idListInfo.totalEmpty;
		return;
	}

	for (auto id : idList)
	{
		++idListInfo.totalEntries;
		if (g_ValidSkillIds.find(id) != g_ValidSkillIds.end()) ++idListInfo.validIdCount;
	}

}


void AnalyzeIdListSkill(skilldata_t& skill)
{
	/*
	idlist_t list1;
	idlist_t list2;
	idlist_t list6a;
	idlist_t list6aa;
	idlist_t list6ab;
	idlist_t list3;
	idlist_t list4;
	idlist_t list6;
	idlist_t list6b;
	idlist_t list7;
	idlist_t list8;
	idlist_t list9;
	idlist_t list10;
	idlist_t list11;
	idlist_t list13;
	idlist_t list14; */

	AnalyzeIdList("1", skill.list1);
	AnalyzeIdList("2", skill.list2);
	AnalyzeIdList("6a", skill.list6a);
	AnalyzeIdList("6aa", skill.list6aa);
	AnalyzeIdList("6ab", skill.list6ab);
	AnalyzeIdList("3", skill.list3);
	AnalyzeIdList("4", skill.list4);
	AnalyzeIdList("5", skill.list6);
	AnalyzeIdList("6b", skill.list6b);
	AnalyzeIdList("7", skill.list7);
	AnalyzeIdList("8", skill.list8);
	AnalyzeIdList("9", skill.list9);
	AnalyzeIdList("10", skill.list10);
	AnalyzeIdList("11", skill.list11);
	AnalyzeIdList("13", skill.list13);
	AnalyzeIdList("14", skill.list14);
}


void AnalyzeIdLists()
{
	for (auto&& skill : g_Skills)
	{
		AnalyzeIdListSkill(skill);
	}
}


void OutputIdListSummary()
{
	printf("ID List Infos:\n");

	for (auto&& idListInfo : g_IdListInfos)
	{
		idlistinfo_t& info = idListInfo.second;

		printf("\t%s: %d checked, %d empty, %d total list entries, %d valid IDs\n", info.name.c_str(), info.totalChecked, info.totalEmpty, info.totalEntries, info.validIdCount);
	}
}


void OutputSummaryCsv()
{
	CFile File;

	printf("Outputting summary CSV...\n");

	if (!File.Open(OUTPUT_CSV_FILENAME, "wb")) return;

	File.Printf("id, name, u20a, u20b, ");

	for (dword i = 0; i < U2SIZE; ++i)
	{
		File.Printf("U%d,", i);
	}

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		File.Printf("F%d,", i);
	}

	//File.Printf("size1, size2\n");

	for (auto&& skill : g_Skills)
	{
		std::string name = skill.name;

		std::replace(name.begin(), name.end(), '"', '\'');

		File.Printf("%07d, ", skill.abilityId2);
		File.Printf("\"%s\", ", name.c_str());
		File.Printf("%d,", (int)skill.u20a);
		File.Printf("%d,", (int)skill.u20b);
		//File.Printf("%02X,", skill.zero1);
		//File.Printf("%04X,", skill.zero2);

		for (dword i = 0; i < U2SIZE; ++i)
		{
			File.Printf("%d,", (int)skill.u2[i]);
		}

		for (dword i = 0; i < FLAGSIZE; ++i)
		{
			File.Printf("%d,", (int)skill.flags[i]);
		}

		//File.Printf("%08X,", skill.size1);
		//File.Printf("%08X,", skill.size2);

		File.Printf("\n");
	}
}


void OutputFlagCsv()
{
	printf("Outputting flag CSV...\n");

	
	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		CFile File;
		std::string filename = OUTPUT_FLAG_PATH + "Flags-" + std::to_string(i) + ".csv";

		if (!File.Open(filename, "wb")) continue;

		for (auto&& skill : g_Skills)
		{
			//if (!g_MinedSkills[skill.abilityId1].isPlayer) continue;

			std::string name = skill.name;
			std::replace(name.begin(), name.end(), '"', '\'');
			if (skill.flags[i]) File.Printf("%06d, %s\n", skill.abilityId1, name.c_str());
		}
	}
	
}


bool OutputSkillIdList(CFile& File, std::string name, idlist_t& list)
{
	File.Printf("List %s:\n", name.c_str());
	int i = 0;

	for (auto&& id : list)
	{
		File.Printf("\t%d = %d", i, id); 

		if (g_ValidSkillIds.find(id) != g_ValidSkillIds.end())
		{
			int skillIndex = g_ValidSkillIds[id] - 1;
			skilldata_t& skill = g_Skills[skillIndex];
			File.Printf(" (Skill %d, %s)", skill.abilityId1, skill.name.c_str());
		}
		
		File.Printf("\n");
		++i;
	}

	//File.Printf("Flags: ");
	return true;
}


bool OutputSkillData(CFile& File, std::string name, dword value[], dword numValues)
{
	File.Printf("Array %s:\n", name.c_str());

	for (dword i = 0; i < numValues; ++i)
	{
		File.Printf("\t%d = %d\n", i, value[i]);
	}

	return true;
}


bool OutputSkill(skilldata_t& skill)
{
	CFile File;
	std::string filename = OUTPUT_SKILL_PATH + "Skill-" + std::to_string(skill.abilityId1) + ".txt";

	if (!File.Open(filename, "wb")) return false;

	File.Printf("Name: %s\n", skill.name.c_str());
	File.Printf("ID: %d, %d\n", skill.abilityId1, skill.abilityId2);

	File.Printf("U2: %d, %d", skill.u20a, skill.u20b);

	for (dword i = 0; i < U2SIZE; ++i)
	{
		File.Printf(", %d", skill.u2[i]);
	}

	File.Printf("\n");
	File.Printf("Flags: ");

	for (dword i = 0; i < FLAGSIZE; ++i)
	{
		File.Printf("%d", skill.flags[i]);
	}

	File.Printf("\n");
	OutputSkillIdList(File, "List1", skill.list1);
	OutputSkillIdList(File, "List2", skill.list2);
	OutputSkillIdList(File, "List6a", skill.list6a);
	OutputSkillIdList(File, "List6aa", skill.list6aa);
	OutputSkillIdList(File, "List6ab", skill.list6ab);
	OutputSkillIdList(File, "List3", skill.list3);
	OutputSkillIdList(File, "List4", skill.list4);
	OutputSkillIdList(File, "List6", skill.list6);
	OutputSkillIdList(File, "List6b", skill.list6b);
	OutputSkillIdList(File, "List7", skill.list7);
	OutputSkillIdList(File, "List8", skill.list8);
	OutputSkillIdList(File, "List9", skill.list9);
	OutputSkillIdList(File, "List10", skill.list10);
	OutputSkillIdList(File, "List11", skill.list11);
	OutputSkillIdList(File, "List12", skill.list12);
	OutputSkillIdList(File, "List13", skill.list13);
	OutputSkillIdList(File, "List14", skill.list14);

	OutputSkillData(File, "U6", skill.u6, U6SIZE);
	OutputSkillData(File, "U6A", skill.u6a, U6ASIZE);
	OutputSkillData(File, "U7", skill.u7, U7SIZE);
	OutputSkillData(File, "U8", skill.u8, U8SIZE);

	File.Printf("Value U8A: %d\n", skill.u8a);
	File.Printf("Value U8B: %d\n", skill.u8b);

	OutputSkillData(File, "U9", skill.u9, U9SIZE);
	OutputSkillData(File, "U10", skill.u10, U10SIZE);
	OutputSkillData(File, "U11", skill.u11, U11SIZE);
	OutputSkillData(File, "U12", skill.u12, U12SIZE);
	OutputSkillData(File, "U13", skill.u13, U13SIZE);

	return true;
}


skilldata_t CompareSkills(std::vector<dword> skillIds)
{
	skilldata_t compare{ 0 };
	size_t numCompares = 0;

	if (skillIds.size() <= 1) 
	{
		printf("Error: Need 2 or more skills in order to compare them!");
		return compare;
	}

	if (g_ValidSkillIds.find(skillIds[0]) == g_ValidSkillIds.end())
	{
		printf("Error: First compare skill ID %d is not valid (no skill found)!", skillIds[0]);
		return compare;
	}

	size_t index = g_ValidSkillIds[skillIds[0]] - 1;

	if (index >= g_Skills.size())
	{
		printf("Error: First compare skill ID %d is not valid (bad index)!", skillIds[0]);
		return compare;
	}

	skilldata_t& firstSkill = g_Skills[index];

	compare.list1.resize(firstSkill.list1.size(), 0);
	compare.list2.resize(firstSkill.list2.size(), 0);
	compare.list6a.resize(firstSkill.list6a.size(), 0);
	compare.list6aa.resize(firstSkill.list6aa.size(), 0);
	compare.list6ab.resize(firstSkill.list6ab.size(), 0);
	compare.list3.resize(firstSkill.list3.size(), 0);
	compare.list4.resize(firstSkill.list4.size(), 0);
	compare.list6.resize(firstSkill.list6.size(), 0);
	compare.list6b.resize(firstSkill.list6b.size(), 0);
	compare.list7.resize(firstSkill.list7.size(), 0);
	compare.list8.resize(firstSkill.list8.size(), 0);
	compare.list9.resize(firstSkill.list9.size(), 0);
	compare.list10.resize(firstSkill.list10.size(), 0);
	compare.list11.resize(firstSkill.list11.size(), 0);
	compare.list12.resize(firstSkill.list12.size(), 0);
	compare.list13.resize(firstSkill.list13.size(), 0);
	compare.list14.resize(firstSkill.list14.size(), 0);

	printf("Comparing Skills:\n");
	printf("\t%06d : %s\n", firstSkill.abilityId1, firstSkill.name.c_str());
	
	for (size_t i = 1; i < skillIds.size(); ++i)
	{
		if (g_ValidSkillIds.find(skillIds[i]) == g_ValidSkillIds.end())
		{
			printf("Error: Skill ID %d is not valid (no skill found)!", skillIds[i]);
			continue;
		}

		index = g_ValidSkillIds[skillIds[i]] - 1;

		if (index >= g_Skills.size())
		{
			printf("Error: Skill ID %d is not valid (bad index)!", skillIds[i]);
			continue;
		}

		skilldata_t& skill = g_Skills[index];
		++numCompares;
		printf("\t%06d : %s\n", skill.abilityId1, skill.name.c_str());

		if (skill.unknown1 == firstSkill.unknown1) ++compare.unknown1;
		if (skill.unknown2 == firstSkill.unknown2) ++compare.unknown2;
		if (skill.u20a == firstSkill.u20a) ++compare.u20a;
		if (skill.u20b == firstSkill.u20b) ++compare.u20b;
		if (skill.u8a == firstSkill.u8a) ++compare.u8a;
		if (skill.u8b == firstSkill.u8b) ++compare.u8b;

		for (size_t j = 0; j < U2SIZE; ++j) {
			if (skill.u2[j] == firstSkill.u2[j]) ++compare.u2[j];
		}

		for (size_t j = 0; j < FLAGSIZE; ++j) {
			if (skill.flags[j] == firstSkill.flags[j]) ++compare.flags[j];
		}

		for (size_t j = 0; j < U6SIZE; ++j) {
			if (skill.u6[j] == firstSkill.u6[j]) ++compare.u6[j];
		}

		for (size_t j = 0; j < U6ASIZE; ++j) {
			if (skill.u6a[j] == firstSkill.u6a[j]) ++compare.u6a[j];
		}

		for (size_t j = 0; j < U7SIZE; ++j) {
			if (skill.u7[j] == firstSkill.u7[j]) ++compare.u7[j];
		}

		for (size_t j = 0; j < U8SIZE; ++j) {
			if (skill.u8[j] == firstSkill.u8[j]) ++compare.u8[j];
		}

		for (size_t j = 0; j < U9SIZE; ++j) {
			if (skill.u9[j] == firstSkill.u9[j]) ++compare.u9[j];
		}

		for (size_t j = 0; j < U10SIZE; ++j) {
			if (skill.u10[j] == firstSkill.u10[j]) ++compare.u10[j];
		}

		for (size_t j = 0; j < U11SIZE; ++j) {
			if (skill.u11[j] == firstSkill.u11[j]) ++compare.u11[j];
		}

		for (size_t j = 0; j < U12SIZE; ++j) {
			if (skill.u12[j] == firstSkill.u12[j]) ++compare.u12[j];
		}

		for (size_t j = 0; j < U13SIZE; ++j) {
			if (skill.u13[j] == firstSkill.u13[j]) ++compare.u13[j];
		}

		if (skill.size1 == firstSkill.size1) ++compare.size1;
		if (skill.size2 == firstSkill.size2) ++compare.size2;
		if (skill.size6a == firstSkill.size6a) ++compare.size6a;
		if (skill.size6aa == firstSkill.size6aa) ++compare.size6aa;
		if (skill.size6ab == firstSkill.size6ab) ++compare.size6ab;
		if (skill.size3 == firstSkill.size3) ++compare.size3;
		if (skill.size4 == firstSkill.size4) ++compare.size4;
		if (skill.size6 == firstSkill.size6) ++compare.size6;
		if (skill.size6b == firstSkill.size6b) ++compare.size6b;
		if (skill.size7 == firstSkill.size7) ++compare.size7;
		if (skill.size8 == firstSkill.size8) ++compare.size8;
		if (skill.size9 == firstSkill.size9) ++compare.size9;
		if (skill.size10 == firstSkill.size10) ++compare.size10;
		if (skill.size11 == firstSkill.size11) ++compare.size11;
		if (skill.size12 == firstSkill.size12) ++compare.size12;
		if (skill.size13 == firstSkill.size13) ++compare.size13;
		if (skill.size14 == firstSkill.size14) ++compare.size14;

		for (size_t j = 0; j < firstSkill.list1.size(); ++j) {
			if (j >= skill.list1.size()) break;
			if (skill.list1[j] == firstSkill.list1[j]) ++compare.list1[j];
		}

		for (size_t j = 0; j < firstSkill.list2.size(); ++j) {
			if (j >= skill.list2.size()) break;
			if (skill.list2[j] == firstSkill.list2[j]) ++compare.list2[j];
		}

		for (size_t j = 0; j < firstSkill.list6a.size(); ++j) {
			if (j >= skill.list6a.size()) break;
			if (skill.list6a[j] == firstSkill.list6a[j]) ++compare.list6a[j];
		}

		for (size_t j = 0; j < firstSkill.list6aa.size(); ++j) {
			if (j >= skill.list6aa.size()) break;
			if (skill.list6aa[j] == firstSkill.list6aa[j]) ++compare.list6aa[j];
		}

		for (size_t j = 0; j < firstSkill.list6ab.size(); ++j) {
			if (j >= skill.list6ab.size()) break;
			if (skill.list6ab[j] == firstSkill.list6ab[j]) ++compare.list6ab[j];
		}

		for (size_t j = 0; j < firstSkill.list3.size(); ++j) {
			if (j >= skill.list3.size()) break;
			if (skill.list3[j] == firstSkill.list3[j]) ++compare.list3[j];
		}

		for (size_t j = 0; j < firstSkill.list4.size(); ++j) {
			if (j >= skill.list4.size()) break;
			if (skill.list4[j] == firstSkill.list4[j]) ++compare.list4[j];
		}

		for (size_t j = 0; j < firstSkill.list6.size(); ++j) {
			if (j >= skill.list6.size()) break;
			if (skill.list6[j] == firstSkill.list6[j]) ++compare.list6[j];
		}

		for (size_t j = 0; j < firstSkill.list6b.size(); ++j) {
			if (j >= skill.list6b.size()) break;
			if (skill.list6b[j] == firstSkill.list6b[j]) ++compare.list6b[j];
		}

		for (size_t j = 0; j < firstSkill.list7.size(); ++j) {
			if (j >= skill.list7.size()) break;
			if (skill.list7[j] == firstSkill.list7[j]) ++compare.list7[j];
		}

		for (size_t j = 0; j < firstSkill.list8.size(); ++j) {
			if (j >= skill.list8.size()) break;
			if (skill.list8[j] == firstSkill.list8[j]) ++compare.list8[j];
		}

		for (size_t j = 0; j < firstSkill.list9.size(); ++j) {
			if (j >= skill.list9.size()) break;
			if (skill.list9[j] == firstSkill.list9[j]) ++compare.list9[j];
		}

		for (size_t j = 0; j < firstSkill.list10.size(); ++j) {
			if (j >= skill.list10.size()) break;
			if (skill.list10[j] == firstSkill.list10[j]) ++compare.list10[j];
		}

		for (size_t j = 0; j < firstSkill.list11.size(); ++j) {
			if (j >= skill.list11.size()) break;
			if (skill.list11[j] == firstSkill.list11[j]) ++compare.list11[j];
		}

		for (size_t j = 0; j < firstSkill.list12.size(); ++j) {
			if (j >= skill.list12.size()) break;
			if (skill.list12[j] == firstSkill.list12[j]) ++compare.list12[j];
		}

		for (size_t j = 0; j < firstSkill.list13.size(); ++j) {
			if (j >= skill.list13.size()) break;
			if (skill.list13[j] == firstSkill.list13[j]) ++compare.list13[j];
		}

		for (size_t j = 0; j < firstSkill.list14.size(); ++j) {
			if (j >= skill.list14.size()) break;
			if (skill.list14[j] == firstSkill.list14[j]) ++compare.list14[j];
		}

	}

	printf("Common Field Values:\n");

	if (compare.unknown1 == numCompares) printf("\t unknown1 = %d\n", firstSkill.unknown1);
	else compare.unknown1 = 0;
	if (compare.unknown2 == numCompares) printf("\t unknown2 = %d\n", firstSkill.unknown2);
	else compare.unknown2= 0;
	if (compare.u20a == numCompares) printf("\t u20a = %d\n", firstSkill.u20a);
	else compare.u20a = 0;
	if (compare.u20b == numCompares) printf("\t u20b = %d\n", firstSkill.u20b);
	else compare.u20b = 0;
	if (compare.u8a == numCompares) printf("\t u8a = %d\n", firstSkill.u8a);
	else compare.u8a = 0;
	if (compare.u8b == numCompares) printf("\t u8b = %d\n", firstSkill.u8b);
	else compare.u8b = 0;
	
	for (size_t j = 0; j < U2SIZE; ++j) {
		if (compare.u2[j] == numCompares) printf("\t u2[%zu] = %d\n", j, firstSkill.u2[j]);
		else compare.u2[j] = 0;
	}

	for (size_t j = 0; j < FLAGSIZE; ++j) {
		if (compare.flags[j] == numCompares) printf("\t flags[%zu] = %d\n", j, firstSkill.flags[j]);
		else compare.flags[j] = 0;
	}

	for (size_t j = 0; j < U6SIZE; ++j) {
		if (compare.u6[j] == numCompares) printf("\t u6[%zu] = %d\n", j, firstSkill.u6[j]);
		else compare.u6[j] = 0;
	}

	for (size_t j = 0; j < U6ASIZE; ++j) {
		if (compare.u6a[j] == numCompares) printf("\t u6a[%zu] = %d\n", j, firstSkill.u6a[j]);
		else compare.u6a[j] = 0;
	}

	for (size_t j = 0; j < U7SIZE; ++j) {
		if (compare.u7[j] == numCompares) printf("\t u7[%zd] = %d\n", j, firstSkill.u7[j]);
		else compare.u7[j] = 0;
	}

	for (size_t j = 0; j < U8SIZE; ++j) {
		if (compare.u8[j] == numCompares) printf("\t u8[%zd] = %d\n", j, firstSkill.u8[j]);
		else compare.u8[j] = 0;
	}

	for (size_t j = 0; j < U9SIZE; ++j) {
		if (compare.u9[j] == numCompares) printf("\t u9[%zd] = %d\n", j, firstSkill.u9[j]);
		else compare.u9[j] = 0;
	}

	for (size_t j = 0; j < U10SIZE; ++j) {
		if (compare.u10[j] == numCompares) printf("\t u10[%zd] = %d\n", j, firstSkill.u10[j]);
		else compare.u10[j] = 0;
	}

	for (size_t j = 0; j < U11SIZE; ++j) {
		if (compare.u11[j] == numCompares) printf("\t u11[%zd] = %d\n", j, firstSkill.u11[j]);
		else compare.u11[j] = 0;
	}

	for (size_t j = 0; j < U12SIZE; ++j) {
		if (compare.u12[j] == numCompares) printf("\t u12[%zd] = %d\n", j, firstSkill.u12[j]);
		else compare.u12[j] = 0;
	}

	for (size_t j = 0; j < U13SIZE; ++j) {
		if (compare.u13[j] == numCompares) printf("\t u13[%zd] = %d\n", j, firstSkill.u13[j]);
		else compare.u13[j] = 0;
	}

	if (compare.size1 == numCompares) printf("\t list1 size = %zd\n", firstSkill.list1.size());
	else compare.size1 = 0;
	for (size_t j = 0; j < firstSkill.list1.size(); ++j) {
		if (compare.list1[j] == numCompares) printf("\t list1[%zd] = %d\n", j, firstSkill.list1[j]);
		else compare.list1[j] = 0;
	}

	if (compare.size2 == numCompares) printf("\t list2 size = %zd\n", firstSkill.list2.size());
	else compare.size2 = 0;
	for (size_t j = 0; j < firstSkill.list2.size(); ++j) {
		if (compare.list2[j] == numCompares) printf("\t list2[%zd] = %d\n", j, firstSkill.list2[j]);
		else compare.list2[j] = 0;
	}

	if (compare.size6a == numCompares) printf("\t list6a size = %zd\n", firstSkill.list6a.size());
	else compare.size6a = 0;
	for (size_t j = 0; j < firstSkill.list6a.size(); ++j) {
		if (compare.list6a[j] == numCompares) printf("\t list6a[%zd] = %d\n", j, firstSkill.list6a[j]);
		else compare.list6a[j] = 0;
	}

	if (compare.size6aa == numCompares) printf("\t list6aa size = %zd\n", firstSkill.list6aa.size());
	else compare.size6aa = 0;
	for (size_t j = 0; j < firstSkill.list6aa.size(); ++j) {
		if (compare.list6aa[j] == numCompares) printf("\t list6aa[%zd] = %d\n", j, firstSkill.list6aa[j]);
		else compare.list6aa[j] = 0;
	}

	if (compare.size6ab == numCompares) printf("\t list6ab size = %zd\n", firstSkill.list6ab.size());
	else compare.size6ab = 0;
	for (size_t j = 0; j < firstSkill.list6ab.size(); ++j) {
		if (compare.list6ab[j] == numCompares) printf("\t list6ab[%zd] = %d\n", j, firstSkill.list6ab[j]);
		else compare.list6ab[j] = 0;
	}

	if (compare.size3 == numCompares) printf("\t list3 size = %zd\n", firstSkill.list3.size());
	else compare.size3 = 0;
	for (size_t j = 0; j < firstSkill.list3.size(); ++j) {
		if (compare.list3[j] == numCompares) printf("\t list3[%zd] = %d\n", j, firstSkill.list3[j]);
		else compare.list3[j] = 0;
}

	if (compare.size4 == numCompares) printf("\t list4 size = %zd\n", firstSkill.list4.size());
	else compare.size4 = 0;
	for (size_t j = 0; j < firstSkill.list4.size(); ++j) {
		if (compare.list4[j] == numCompares) printf("\t list4[%zd] = %d\n", j, firstSkill.list4[j]);
		else compare.list4[j] = 0;
	}

	if (compare.size6 == numCompares) printf("\t list6 size = %zd\n", firstSkill.list6.size());
	else compare.size6 = 0;
	for (size_t j = 0; j < firstSkill.list6.size(); ++j) {
		if (compare.list6[j] == numCompares) printf("\t list6[%zd] = %d\n", j, firstSkill.list6[j]);
		else compare.list6[j] = 0;
	}

	if (compare.size6b == numCompares) printf("\t list6b size = %zd\n", firstSkill.list6b.size());
	for (size_t j = 0; j < firstSkill.list6b.size(); ++j) {
		if (compare.list6b[j] == numCompares) printf("\t list6b[%zd] = %d\n", j, firstSkill.list6b[j]);
		else compare.list6b[j] = 0;
	}

	if (compare.size7 == numCompares) printf("\t list7 size = %zd\n", firstSkill.list7.size());
	else compare.size7 = 0;
	for (size_t j = 0; j < firstSkill.list7.size(); ++j) {
		if (compare.list7[j] == numCompares) printf("\t list7[%zd] = %d\n", j, firstSkill.list7[j]);
		else compare.list7[j] = 0;
	}

	if (compare.size8 == numCompares) printf("\t list8 size = %zd\n", firstSkill.list8.size());
	else compare.size8 = 0;
	for (size_t j = 0; j < firstSkill.list8.size(); ++j) {
		if (compare.list8[j] == numCompares) printf("\t list8[%zd] = %d\n", j, firstSkill.list8[j]);
		else compare.list8[j] = 0;
	}

	if (compare.size9 == numCompares) printf("\t list9 size = %zd\n", firstSkill.list9.size());
	else compare.size9 = 0;
	for (size_t j = 0; j < firstSkill.list9.size(); ++j) {
		if (compare.list9[j] == numCompares) printf("\t list9[%zd] = %d\n", j, firstSkill.list9[j]);
		else compare.list9[j] = 0;
	}

	if (compare.size10 == numCompares) printf("\t list10 size = %zd\n", firstSkill.list10.size());
	else compare.size10 = 0;
	for (size_t j = 0; j < firstSkill.list10.size(); ++j) {
		if (compare.list10[j] == numCompares) printf("\t list10[%zd] = %d\n", j, firstSkill.list10[j]);
		else compare.list10[j] = 0;
	}

	if (compare.size11 == numCompares) printf("\t list11 size = %zd\n", firstSkill.list11.size());
	else compare.size11 = 0;
	for (size_t j = 0; j < firstSkill.list11.size(); ++j) {
		if (compare.list11[j] == numCompares) printf("\t list11[%zd] = %d\n", j, firstSkill.list11[j]);
		else compare.list11[j] = 0;
	}

	if (compare.size12 == numCompares) printf("\t list12 size = %zd\n", firstSkill.list12.size());
	else compare.size12 = 0;
	for (size_t j = 0; j < firstSkill.list12.size(); ++j) {
		if (compare.list12[j] == numCompares) printf("\t list12[%zd] = %d\n", j, firstSkill.list12[j]);
		else compare.list12[j] = 0;
	}

	if (compare.size13 == numCompares) printf("\t list13 size = %zd\n", firstSkill.list13.size());
	else compare.size13 = 0;
	for (size_t j = 0; j < firstSkill.list13.size(); ++j) {
		if (compare.list13[j] == numCompares) printf("\t list13[%zd] = %d\n", j, firstSkill.list13[j]);
		else compare.list13[j] = 0;
	}

	if (compare.size14 == numCompares) printf("\t list14 size = %zd\n", firstSkill.list14.size());
	else compare.size14 = 0;
	for (size_t j = 0; j < firstSkill.list14.size(); ++j) {
		if (compare.list14[j] == numCompares) printf("\t list14[%zd] = %d\n", j, firstSkill.list14[j]);
		else compare.list14[j] = 0;
	}
	
	return compare;
}


void CompareFlags(std::vector<dword> skillIds)
{
	int flagCompare[FLAGSIZE] = {};
	int uniqueFlags[FLAGSIZE] = {};
	int skillIndex = 0;
	int numCompares = 0;
	skilldata_t firstSkill;
	std::unordered_map<dword, dword> CheckedIdMap;

	printf("Comparing Flags from %d Skills:\n", skillIds.size());
	if (skillIds.size() <= 1) return;

	for (auto&& id : skillIds)
	{
		CheckedIdMap[id] = 1;

		if (g_ValidSkillIds.find(id) == g_ValidSkillIds.end()) continue;
		size_t index = g_ValidSkillIds[id] - 1;

		if (index >= g_Skills.size()) continue;
		skilldata_t& skill = g_Skills[index];

		if (skillIndex == 0)
		{
			firstSkill = skill;
			++skillIndex;
			continue;
		}

		++skillIndex;
		++numCompares;

		for (size_t j = 0; j < FLAGSIZE; ++j) 
		{
			if (skill.flags[j] == firstSkill.flags[j]) ++flagCompare[j];
		}
	}

	for (size_t j = 0; j < FLAGSIZE; ++j) 
	{
		if (flagCompare[j] == numCompares) 
		{
			printf("\t flags[%zu] = %d\n", j, firstSkill.flags[j]);
		}
	}

	printf(" Flags: ");

	for (size_t j = 0; j < FLAGSIZE; ++j) 
	{
		if (flagCompare[j] == numCompares)
		{
			printf("%d", firstSkill.flags[j]);
			uniqueFlags[j] = 1;
		}
		else
		{
			printf(" ");
		}
	}

	printf("\n");
	std::smatch m;
	int numSkills = 0;

	for (auto&& skill : g_Skills)
	{
		if (CheckedIdMap.find(skill.abilityId1) != CheckedIdMap.end()) continue;

		auto desc = g_SkillDescriptions[skill.abilityId1];
		if (desc == "") continue;
		if (!std::regex_search(desc, m, std::regex("<<"))) continue;
		++numSkills;

		for (size_t j = 0; j < FLAGSIZE; ++j)
		{
			if (flagCompare[j] != numCompares) continue;
			if (firstSkill.flags[j] == skill.flags[j]) uniqueFlags[j] = 0;
		}
	}

	printf("Unique Flags (compared against %d skills):\n", numSkills);

	for (size_t j = 0; j < FLAGSIZE; ++j)
	{
		if (uniqueFlags[j])
		{
			printf("\t flags[%zu] = %d\n", j, firstSkill.flags[j]);
		}
	}
	
	for (auto&& id : skillIds)
	{
		if (g_ValidSkillIds.find(id) == g_ValidSkillIds.end()) continue;
		size_t index = g_ValidSkillIds[id] - 1;

		if (index >= g_Skills.size()) continue;
		skilldata_t& skill = g_Skills[index];

		printf("%06d: ", id);

		for (int i = 0; i < FLAGSIZE; ++i)
		{
			printf("%1d", skill.flags[i]);
		}

		printf("\n");
	}

}


void DiffValue (std::string name, dword value1, dword value2, int showDiff)
{
	if (showDiff == 1 && value1 != value2)
		printf("\t%s  %d != %d\n", name.c_str(), value1, value2);
	else if (showDiff == 0 && value1 == value2)
		printf("\t%s  %d equal\n", name.c_str(), value1);

}


void DiffArray(std::string name, dword value1[], dword value2[], dword size, int showDiff)
{
	for (dword i = 0; i < size; ++i)
	{
		if (showDiff == 1 && value1[i] != value2[i])
			printf("\t%s[%d]  %d != %d\n", name.c_str(), i, value1[i], value2[i]);
		else if (showDiff == 0 && value1 == value2)
			printf("\t%s[%d]  %d equal\n", name.c_str(), i, value1[i]);
	}

}

void DiffArray(std::string name, byte value1[], byte value2[], dword size, int showDiff)
{
	for (dword i = 0; i < size; ++i)
	{
		if (showDiff == 1 && value1[i] != value2[i])
			printf("\t%s[%d]  %d != %d\n", name.c_str(), i, value1[i], value2[i]);
		else if (showDiff == 0 && value1 == value2)
			printf("\t%s[%d]  %d equal\n", name.c_str(), i, value1[i]);
	}

}


void DiffIdList(std::string name, idlist_t& value1, idlist_t& value2, int showDiff)
{
	if (showDiff == 1 && value1.size() != value2.size())
		printf("\t%s  sizes %d != %d\n", name.c_str(), (int)value1.size(), (int)value2.size());
	else if (showDiff == 0 && value1.size() != value2.size())
		printf("\t%s size %d equal\n", name.c_str(), (int)value1.size());

	for (dword i = 0; i < value1.size() && i < value2.size(); ++i)
	{
		if (showDiff == 1 && value1[i] != value2[i])
			printf("\t%s[%d]  %d != %d\n", name.c_str(), i, value1[i], value2[i]);
		else if (showDiff == 0 && value1 == value2)
			printf("\t%s[%d]  %d equal\n", name.c_str(), i, value1[i]);
	}

}


void DiffSkills(skilldata_t& skill1, skilldata_t& skill2, int showDiff = 1)
{
	if (showDiff)
		printf("Diffing Skills:\n");
	else
		printf("Comparing Skills:\n");

	printf("\t%06d : %s\n", skill1.abilityId1, skill1.name.c_str());
	printf("\t%06d : %s\n", skill2.abilityId1, skill2.name.c_str());

	DiffValue("unknown1", skill1.unknown1, skill2.unknown2, showDiff);
	DiffValue("unknown2", skill1.unknown2, skill2.unknown2, showDiff);
	DiffValue("u20a", skill1.u20a, skill2.u20a, showDiff);
	DiffValue("u20b", skill1.u20b, skill2.u20b, showDiff);
	DiffValue("u8a", skill1.u8a, skill2.u8a, showDiff);
	DiffValue("u8b", skill1.u8b, skill2.u8b, showDiff);

	DiffArray("u2", skill1.u2, skill2.u2, U2SIZE, showDiff);
	DiffArray("flags", skill1.flags, skill2.flags, FLAGSIZE, showDiff);
	DiffArray("u6", skill1.u6, skill2.u6, U6SIZE, showDiff);
	DiffArray("u6a", skill1.u6a, skill2.u6a, U6ASIZE, showDiff);
	DiffArray("u7", skill1.u7, skill2.u7, U7SIZE, showDiff);
	DiffArray("u8", skill1.u8, skill2.u8, U8SIZE, showDiff);
	DiffArray("u9", skill1.u9, skill2.u9, U9SIZE, showDiff);
	DiffArray("u10", skill1.u10, skill2.u10, U10SIZE, showDiff);
	DiffArray("u11", skill1.u11, skill2.u11, U11SIZE, showDiff);
	DiffArray("u12", skill1.u12, skill2.u12, U12SIZE, showDiff);
	DiffArray("u13", skill1.u13, skill2.u13, U13SIZE, showDiff);

	DiffIdList("list1",   skill1.list1,   skill2.list1, showDiff);
	DiffIdList("list2",   skill1.list2,   skill2.list2, showDiff);
	DiffIdList("list6a",  skill1.list6a,  skill2.list6a, showDiff);
	DiffIdList("list6aa", skill1.list6aa, skill2.list6aa, showDiff);
	DiffIdList("list6ab", skill1.list6ab, skill2.list6ab, showDiff);
	DiffIdList("list3",   skill1.list3,   skill2.list3, showDiff);
	DiffIdList("list4",   skill1.list4,   skill2.list4, showDiff);
	DiffIdList("list6",   skill1.list6,   skill2.list6, showDiff);
	DiffIdList("list6a",  skill1.list6a,  skill2.list6a, showDiff);
	DiffIdList("list7",   skill1.list7,   skill2.list7, showDiff);
	DiffIdList("list8",   skill1.list8,   skill2.list8, showDiff);
	DiffIdList("list9",   skill1.list9,   skill2.list9, showDiff);
	DiffIdList("list10",  skill1.list10,  skill2.list10, showDiff);
	DiffIdList("list11",  skill1.list11,  skill2.list11, showDiff);
	DiffIdList("list12",  skill1.list12,  skill2.list12, showDiff);
	DiffIdList("list13",  skill1.list13,  skill2.list13, showDiff);
	DiffIdList("list14",  skill1.list14,  skill2.list14, showDiff);
	
}


void DiffSkills(dword skillId1, dword skillId2, int showDiff = 1)
{

	if (g_ValidSkillIds.find(skillId1) == g_ValidSkillIds.end())
	{
		printf("Error: Diff skill ID %d is not valid (no skill found)!", skillId1);
		return;
	}

	if (g_ValidSkillIds.find(skillId2) == g_ValidSkillIds.end())
	{
		printf("Error: Diff skill ID %d is not valid (no skill found)!", skillId2);
		return;
	}

	size_t index1 = g_ValidSkillIds[skillId1] - 1;
	size_t index2 = g_ValidSkillIds[skillId2] - 1;

	if (index1 >= g_Skills.size())
	{
		printf("Error: Diff skill ID %d is not valid (bad index)!", skillId1);
		return;
	}

	if (index2 >= g_Skills.size())
	{
		printf("Error: Diff skill ID %d is not valid (bad index)!", skillId1);
		return;
	}

	skilldata_t& skill1 = g_Skills[index1];
	skilldata_t& skill2 = g_Skills[index2];

	DiffSkills(skill1, skill2, showDiff);
}


void OutputSkills()
{
	printf("Outputting all skill files...\n");

	for (auto&& skill : g_Skills)
	{
		OutputSkill(skill);
	}
}


std::string UnescapeString(std::string value)
{
	//value = std::regex_replace(value, std::regex("\\\""), "\"");
	//value = std::regex_replace(value, std::regex("\\n"), "\n");
	value = ReplaceStrings(value, "\\\"", "\"");
	value = ReplaceStrings(value, "\\n", "\n");
	return value;
}


bool LoadSkillListCsv(std::string filename, std::vector<skilllist_t>& List)
{
	printf("Loading skill list data from '%s'...\n", filename.c_str());

	CFile File;
	char Buffer[10100];
	int lineCount = 0;

	if (!File.Open(filename, "rb")) return false;

	while (!File.IsEOF())
	{
		++lineCount;

		char *pError = fgets(Buffer, 10000, File.GetFile());

		if (pError == nullptr && ferror(File.GetFile()))
		{
			printf("Error: Failed to read line %d from file %s!\n", lineCount, filename.c_str());
			return false;
		}

		const char* pParse = Buffer;
		const char* pColStart = pParse;
		const char* pColEnd = nullptr;
		std::string colValue;
		bool isInQuote = false;
		int colIndex = 0;
		std::vector<std::string> colValues(10, "");

		while (true)
		{
			if (*pParse == 0)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";

				colValues[colIndex] = UnescapeString(colValue);
				++colIndex;
				break;
			}
			else if (*pParse == '"')
			{
				if (isInQuote)
				{
					isInQuote = false;
					pColEnd = pParse - 1;
				}
				else
				{
					isInQuote = true;
					pColStart = pParse + 1;
				}
			}
			else if (*pParse == '\\')
			{
				if (pParse[1] == '"') ++pParse;
			}
			else if (*pParse == ',' && !isInQuote)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";

				colValues[colIndex] = UnescapeString(colValue);

				pColStart = pParse + 1;
				pColEnd = nullptr;
				colValue = "";
				++colIndex;
			}

			++pParse;
		}

		skilllist_t entry;

		entry.abilityId = atoi(colValues[0].c_str());
		entry.name = colValues[1];

		for (int j = 2; j < colIndex; ++j)
		{ 
			entry.indexes.push_back(atoi(colValues[j].c_str()) + 1);
		}

		List.push_back(entry);
	}

	printf("\tLoaded %d skill list entries!\n", List.size());
	return true;
}


bool LoadSkillDescriptionCsv(std::string filename)
{
	printf("Loading skill description data...\n");

	CFile File;
	char Buffer[10100];
	int lineCount = 0;

	if (!File.Open(filename, "rb")) return false;

	while (!File.IsEOF())
	{
		++lineCount;

		char *pError = fgets(Buffer, 10000, File.GetFile());

		if (pError == nullptr && ferror(File.GetFile()))
		{
			printf("Error: Failed to read line %d from file %s!\n", lineCount, filename.c_str());
			return false;
		}

		const char* pParse = Buffer;
		const char* pColStart = pParse;
		const char* pColEnd = nullptr;
		std::string colValue;
		bool isInQuote = false;
		int colIndex = 0;
		std::vector<std::string> colValues(10, "");

		while (true)
		{
			if (*pParse == 0)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";

				colValues[colIndex] = UnescapeString(colValue);
				++colIndex;
				break;
			}
			else if (*pParse == '"')
			{
				if (isInQuote)
				{
					isInQuote = false;
					pColEnd = pParse - 1;
				}
				else
				{
					isInQuote = true;
					pColStart = pParse + 1;
				}
			}
			else if (*pParse == '\\')
			{
				if (pParse[1] == '"') ++pParse;
			}
			else if (*pParse == ',' && !isInQuote)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";

				colValues[colIndex] = UnescapeString(colValue);

				pColStart = pParse + 1;
				pColEnd = nullptr;
				colValue = "";
				++colIndex;
			}

			++pParse;
		}

		int id = atoi(colValues[2].c_str());
		if (id > 0) g_SkillDescriptions[id] = colValues[4];
	}

	printf("\tLoaded %d skill descriptions!\n", g_SkillDescriptions.size());
	return true;
}


bool LoadMinedSkillCsv(std::string filename)
{
	printf("Loading mined skills data...\n");

	CFile File;
	char Buffer[10100];
	int lineCount = 0;

	if (!File.Open(filename, "rb")) return false;

	g_MinedSkills.reserve(100000);
	
	while (!File.IsEOF())
	{
		++lineCount;

		char *pError = fgets(Buffer, 10000, File.GetFile());

		if (pError == nullptr && ferror(File.GetFile()))
		{
			printf("Error: Failed to read line %d from file %s!\n", lineCount, filename.c_str());
			return false;
		}

		const char* pParse = Buffer;
		const char* pColStart = pParse;
		const char* pColEnd = nullptr;
		std::string colValue;
		bool isInQuote = false;
		int colIndex = 0;
		//std::unordered_map<int, std::string> colValues;
		std::vector<std::string> colValues(100, "");

		while (true)
		{
			if (*pParse == 0)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";

				colValues[colIndex] = UnescapeString(colValue);
				++colIndex;
				break;
			}
			else if (*pParse == '"')
			{
				if (isInQuote)
				{
					isInQuote = false;
					pColEnd = pParse - 1;
				}
				else
				{
					isInQuote = true;
					pColStart = pParse + 1;
				}
			}
			else if (*pParse == '\\')
			{
				if (pParse[1] == '"') ++pParse;
			}
			else if (*pParse == ',' && !isInQuote)
			{
				if (pColEnd == nullptr) pColEnd = pParse - 1;

				if (pColEnd >= pColStart)
					colValue.assign(pColStart, pColEnd - pColStart + 1);
				else
					colValue = "";
				
				colValues[colIndex] = UnescapeString(colValue);

				pColStart = pParse + 1;
				pColEnd = nullptr;
				colValue = "";
				++colIndex;
			}

			++pParse;
		}

		minedskill_t skill;

			// id, displayId, name, description, target, skillType, upgradeLines, effectLines, duration, cost, minRange, maxRange, radius, 
			// isPassive, isChanneled, isPermanent, castTime, channelTime, angleDistance, mechanic, texture, isPlayer, raceType, classType,
			// skillLine, prevSkill, nextSkill, nextSkill2, baseAbilityId, learnedLevel, rank, morph, skillIndex, buffType, isToggle, 
			// chargeFreq, numCoefVars, coefDescription, type1, a1, b1, c1, R1, avg1, type2, a2, b2, c2, R2, avg2, type3, a3, b3, c3, R3, avg3, 
			// type4, a4, b4, c4, R4, avg4, type5, a5, b5, c5, R5, avg5, type6, a6, b6, c6, R6, avg6
		
		skill.abilityId = atoi(colValues[0].c_str());
		skill.displayId = atoi(colValues[1].c_str());
		skill.name = colValues[2];
		skill.description = colValues[3];
		skill.target = colValues[4];
		skill.skillType = atoi(colValues[5].c_str());
		skill.upgradeLines = colValues[6];
		skill.effectLines = colValues[7];
		skill.duration = atoi(colValues[8].c_str());
		skill.cost = atoi(colValues[9].c_str());
		skill.minRange = atoi(colValues[10].c_str());
		skill.maxRange = atoi(colValues[11].c_str());
		skill.radius = atoi(colValues[12].c_str());
		skill.isPassive = atoi(colValues[13].c_str()) != 0;
		skill.isChanneled = atoi(colValues[14].c_str()) != 0;
		skill.isPermanent = atoi(colValues[15].c_str()) != 0;
		skill.castTime = atoi(colValues[16].c_str());
		skill.channelTime = atoi(colValues[17].c_str());
		skill.angleDistance = atoi(colValues[18].c_str());
		skill.mechanic = atoi(colValues[19].c_str());
		skill.texture = colValues[20];
		skill.isPlayer = atoi(colValues[21].c_str()) != 0;
		skill.raceType = atoi(colValues[22].c_str());
		skill.classType = atoi(colValues[23].c_str());
		skill.skillLine = atoi(colValues[24].c_str());
		skill.prevSkill = atoi(colValues[25].c_str());
		skill.nextSkill = atoi(colValues[26].c_str());
		skill.nextSkill2 = atoi(colValues[27].c_str());
		skill.baseAbilityId = atoi(colValues[28].c_str());
		skill.learnedLevel = atoi(colValues[29].c_str());
		skill.rank = atoi(colValues[30].c_str());
		skill.morph = atoi(colValues[31].c_str());
		skill.skillIndex = atoi(colValues[32].c_str());
		skill.buffType = atoi(colValues[33].c_str());
		skill.isToggle = atoi(colValues[34].c_str()) != 0;
		skill.chargeFreq = atoi(colValues[35].c_str());
		skill.numCoefVars = atoi(colValues[36].c_str());
		skill.coefDescription = colValues[37];

		for (int i = 0; i < 6; ++i)
		{
				//type1, a1, b1, c1, R1, avg1
			skill.type[i] = atoi(colValues[38 + i * 6].c_str());
			skill.a[i] = (float) atof(colValues[39 + i * 6].c_str());
			skill.b[i] = (float) atof(colValues[40 + i * 6].c_str());
			skill.c[i] = (float) atof(colValues[41 + i * 6].c_str());
			skill.r[i] = (float) atof(colValues[42 + i * 6].c_str());
			skill.avg[i] = (float) atof(colValues[43 + i * 6].c_str());
		}
		
		g_MinedSkills[skill.abilityId] = skill;
		//printf("\t%zd\n", g_MinedSkills.size());
	}

	printf("\tLoaded %zd mined skills!\n", g_MinedSkills.size());
	return true;
}


void CompareSkills1()
{
	std::vector<dword> Passives;

	for (auto&& skill : g_MinedSkills)
	{
		if (skill.second.isPassive && skill.second.isPlayer) Passives.push_back(skill.second.abilityId);
	}

	skilldata_t compare1 = CompareSkills(Passives);
}


void AnalyzeU8()
{
	for (auto&& skill : g_Skills)
	{
		for (int i = 0; i < U8SIZE; ++i)
		{
			if ((int)skill.u8[i] < g_MinU8Values[i]) g_MinU8Values[i] = (int)skill.u8[i];
			if ((int)skill.u8[i] > g_MaxU8Values[i]) g_MaxU8Values[i] = (int)skill.u8[i];
			g_U8Values[i][skill.u8[i]]++;
		}
	}

	printf("U8 Values:\n");

	for (int i = 0; i < U8SIZE; ++i)
	{
		printf("\t%d: %d - %d (%d values)\n", i, g_MinU8Values[i], g_MaxU8Values[i], g_U8Values[i].size());

		for (auto &&j : g_U8Values[i])
		{
			printf("\t\t%d: x%d\n", j.first, j.second);
		}

	}

}


void AnalyzeList1()
{
	int minSize = 1000;
	int maxSize = 0;

	for (auto&& skill : g_Skills)
	{
		if (minSize > skill.list1.size()) minSize = skill.list1.size();
		if (maxSize < skill.list1.size()) maxSize = skill.list1.size();

		for (int i = 0; i < skill.list1.size(); ++i)
		{
			if (g_List1Values.size() <= i) g_List1Values.resize(i+1);
			g_List1Values[i][skill.list1[i]]++;
		}
	}

	printf("List1 Data: Size %d - %d\n", minSize, maxSize);

	for (int i = 0; i < g_List1Values.size(); ++i)
	{
		printf("\t%d: %d values\n", i, g_List1Values[i].size());

		for (auto&& j : g_List1Values[i])
		{
			printf("\t\t%d: x%d\n", j.first, j.second);
		}
	}

}


void AnalyzeList3()
{
	int minSize = 1000;
	int maxSize = 0;

	for (auto&& skill : g_Skills)
	{
		if (minSize > skill.list3.size()) minSize = skill.list3.size();
		if (maxSize < skill.list3.size()) maxSize = skill.list3.size();

		for (int i = 0; i < skill.list3.size(); ++i)
		{
			if (g_List3Values.size() <= i) g_List3Values.resize(i + 1);
			g_List3Values[i][skill.list3[i]]++;
		}
	}

	printf("List3 Data: Size %d - %d\n", minSize, maxSize);

	for (int i = 0; i < g_List3Values.size(); ++i)
	{
		printf("\t%d: %d values\n", i, g_List3Values[i].size());

		for (auto&& j : g_List3Values[i])
		{
			printf("\t\t%d: x%d\n", j.first, j.second);
		}
	}

}


void CheckDescriptions()
{
	printf("Checking Skill Descriptions:\n");

	for (auto&& skill : g_MinedSkills)
	{
		if (skill.second.abilityId > 10000000) continue;
		if (!skill.second.isPassive && skill.second.rank != 1) continue;

		if (!skill.second.description.empty() && g_SkillDescriptions.find(skill.second.abilityId) == g_SkillDescriptions.end())
		{
			printf("\tSkill %d missing skill description text!\n", skill.second.abilityId);
			printf("\t\t%s\n", skill.second.description.c_str());
		}
		else if (skill.second.description.empty() && g_SkillDescriptions.find(skill.second.abilityId) != g_SkillDescriptions.end())
		{
			printf("\tSkill %d missing mined skill description!\n", skill.second.abilityId);
			printf("\t\t%s\n", g_SkillDescriptions[skill.second.abilityId].c_str());
		}
	}

}


float ConvertDwordToFloat(const dword value)
{
	dword rValue = ((value & 0xff) << 24) | ((value & 0xff00) << 8) | ((value & 0xff0000) >> 8) | ((value & 0xff000000) >> 24);
	return *(float *)&rValue;
}


void CheckSkillCosts()
{
	std::unordered_map<int, int> U9_2Values;
	int u2_14_count = 0;
	int u2_15_count = 0;
	int u9_1_count = 0;
	int error_count = 0;
	int total_count = 0;

	printf("Checking Skill Costs...\n");

	for (auto&& skill : g_Skills)
	{
		if (g_MinedSkills.find(skill.abilityId1) == g_MinedSkills.end()) 
		{
			printf("\tError: Missing mined skill %d!\n", skill.abilityId1);
			continue;
		}

		minedskill_t& minedSkill = g_MinedSkills[skill.abilityId1];
		//if (!minedSkill.isPlayer) continue;

		++total_count;

		U9_2Values[skill.u9[2]]++;

		if (minedSkill.cost == skill.u2[14])
			++u2_14_count;
		else if (minedSkill.cost == skill.u2[15])
			++u2_15_count;
		else if (minedSkill.cost > 0 && abs((int) (floor(ConvertDwordToFloat(skill.u9[1]) * 72)) - minedSkill.cost) <= 1)
		{
			//printf("\tFound u9[1] cost match: %d %s\n", skill.abilityId1, skill.name.c_str());
			++u9_1_count;
		}
		else
		{
			printf("\tCost No Match: %d %s (%d: %d, %d, %.2f)\n", skill.abilityId1, skill.name.c_str(), minedSkill.cost, skill.u2[14], skill.u2[15], ConvertDwordToFloat(skill.u9[1]) * 72);
			++error_count;
		}

	}

	printf("Found %d unique U9[2] values:\n", U9_2Values.size());

	for (auto&& i : U9_2Values)
	{
		printf("\t%d (0x%X): x%d\n", i.first, i.first, i.second);
	}

	printf("Checked %d skills\n", total_count);
	printf("\tFound %d skills with u2[14] matching cost\n", u2_14_count);
	printf("\tFound %d skills with u2[15] matching cost\n", u2_15_count);
	printf("\tFound %d skills with u9[1]*72 matching cost\n", u9_1_count);
	printf("\tFound %d skills no matching cost\n", error_count);
}



void CheckTooltipTypes()
{
	std::unordered_map<int, std::vector<std::string> > TypeValues;
	std::vector<dword> MagicDamageIds;
	std::vector<dword> FlameDamageIds;
	std::vector<dword> FrostDamageIds;
	std::vector<dword> ShockDamageIds;
	std::vector<dword> PhysicalDamageIds;
	std::vector<dword> PoisonDamageIds;
	std::vector<dword> DiseaseDamageIds;
	std::vector<dword> BleedDamageIds;
	std::vector<dword> GenericDamageIds;

	int matchCount = 0;
	int noMatchCount = 0;
	int totalCount = 0;

	printf("Checking Tooltips:\n");

	for (auto&& skill : g_Skills)
	{
		if (g_SkillDescriptions.find(skill.abilityId1) == g_SkillDescriptions.end()) continue;
		if (g_MinedSkills.find(skill.abilityId1) == g_MinedSkills.end()) continue;

		minedskill_t& minedSkill = g_MinedSkills[skill.abilityId1];
		std::string desc = g_SkillDescriptions[skill.abilityId1];
		std::string matchDesc;
		std::string minedDesc = minedSkill.description;
		std::smatch m;

		desc = ReplaceStrings(desc, "<<AB_DURATION:17566))>>", "AB_DURATION");
		desc = ReplaceStrings(desc, ")>>", ">>");	//2 cases?
		desc = ReplaceStrings(desc, "|cffffff", "");
		desc = ReplaceStrings(desc, "|r", "");
		//desc = ReplaceStrings(desc, "  ", " ");	//Helps some, hurts some
		matchDesc = desc;

		bool hasTooltips = std::regex_match(desc, m, std::regex("<<[0-9]+>>"));
		hasTooltips = desc.find("<<") != std::string::npos;
		if (!hasTooltips) continue;

		++totalCount;

		minedDesc = ReplaceStrings(minedDesc, "|cffffff", "");
		minedDesc = ReplaceStrings(minedDesc, "|r", "");

		for (int i = 0; i <= 10; ++i)
		{
			matchDesc = std::regex_replace(matchDesc, std::regex("<<" + std::to_string(i+1) + ">>"), "(.*)");
		}

		bool isMatched = std::regex_match(minedDesc, m, std::regex(matchDesc));

		if (isMatched)
		{
			++matchCount;
			printf("\t%06d %s: Matched!\n", skill.abilityId1, minedSkill.name.c_str());

			for (unsigned i = 1; i < m.size(); ++i) 
			{
				//auto subMatch = m[i];
				printf("\t\t%d: %s\n", i, m.str(i).c_str());

				if (i - 1 >= skill.list3.size())
				{
					printf("\t\tError: Missing tooltip #%d type/ID in data!\n", i);
				}
				else
				{
					int type = skill.list3[i - 1];
					TypeValues[type].push_back(m.str(i));

					if (m.str(i).find("Magic Damage") != std::string::npos) {
						MagicDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Frost Damage") != std::string::npos) {
						FrostDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Shock Damage") != std::string::npos) {
						ShockDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Flame Damage") != std::string::npos) {
						FlameDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Physical Damage") != std::string::npos) {
						PhysicalDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Poison Damage") != std::string::npos) {
						PoisonDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Disease Damage") != std::string::npos) {
						DiseaseDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Bleed Damage") != std::string::npos) {
						BleedDamageIds.push_back(skill.list4[i - 1]);
					}
					else if (m.str(i).find("Generic Damage") != std::string::npos) {
						GenericDamageIds.push_back(skill.list4[i - 1]);
					}
				}
			}
		}
		else
		{
			++noMatchCount;
			printf("\t%06d %s: No Match\n", skill.abilityId1, minedSkill.name.c_str());
			printf("\t\t%s\n", matchDesc.c_str());
			printf("\t\t%s\n", minedDesc.c_str());
		}
	}

	printf("Tooltip Type Values:\n");

	for (auto&& i : TypeValues)
	{
		printf("\t%d: x%d values\n", i.first, i.second.size());

		for (auto&& j : i.second)
		{
			printf("\t\t%s\n", j.c_str());
		}
	}

	printf("Compared %d tooltips, matched %d and %d with no match.\n", totalCount, matchCount, noMatchCount);

	skilldata_t data1 = CompareSkills(MagicDamageIds);
	skilldata_t data2 = CompareSkills(FlameDamageIds);
	skilldata_t data3 = CompareSkills(FrostDamageIds);
	skilldata_t data4 = CompareSkills(ShockDamageIds);
	skilldata_t data5 = CompareSkills(PhysicalDamageIds);
	skilldata_t data6 = CompareSkills(PoisonDamageIds);
	skilldata_t data7 = CompareSkills(DiseaseDamageIds);
	skilldata_t data8 = CompareSkills(BleedDamageIds);
	skilldata_t data9 = CompareSkills(GenericDamageIds);

	//DiffSkills(data1, data2, true);
	//DiffSkills(data1, data3, true);
	//DiffSkills(data1, data4, true);
	//DiffSkills(data1, data5, true);
	//DiffSkills(data1, data6, true);
	//DiffSkills(data1, data7, true);
	//DiffSkills(data1, data8, true);
	//DiffSkills(data1, data9, true);

	printf("Found %d magic damage tooltips.\n", MagicDamageIds.size());
	printf("Found %d flame damage tooltips.\n", FlameDamageIds.size());
	printf("Found %d frost damage tooltips.\n", FrostDamageIds.size());
	printf("Found %d shock damage tooltips.\n", ShockDamageIds.size());
	printf("Found %d physical damage tooltips.\n", PhysicalDamageIds.size());
	printf("Found %d poison damage tooltips.\n", PoisonDamageIds.size());
	printf("Found %d disease damage tooltips.\n", DiseaseDamageIds.size());
	printf("Found %d bleed damage tooltips.\n", BleedDamageIds.size());
	printf("Found %d generic damage tooltips.\n", GenericDamageIds.size());

	//Compared 3638 tooltips, matched 3096 and 542 with no match.
}


void CompareSkillList(std::string Name, std::vector<skilllist_t>& SkillList)
{
	auto numberRegex = std::regex("[0-9]+(?:\\.[0-9]+)?");
	std::vector<dword> CompareIds;

	printf("Comparing %d %s Skills:\n", SkillList.size(), Name.c_str());

	for (auto&& entry : SkillList)
	{
		int abilityId = entry.abilityId;

		if (g_SkillDescriptions.find(abilityId) == g_SkillDescriptions.end()) {	printf("\tError: Failed to find skill descriptions %d!\n", abilityId);  continue; }
		if (g_MinedSkills.find(abilityId) == g_MinedSkills.end()) { printf("\tError: Failed to find mined skill %d!\n", abilityId);  continue; }
		if (g_ValidSkillIds.find(abilityId) == g_ValidSkillIds.end()) { printf("\tError: Failed to find skill data %d!\n", abilityId);  continue; }

		auto& skillDesc = g_SkillDescriptions[abilityId];
		auto& minedSkill = g_MinedSkills[abilityId];
		auto skillIndex = g_ValidSkillIds[abilityId] - 1;
		auto& skill = g_Skills[skillIndex];
		auto minedDesc = minedSkill.description;

		skillDesc = ReplaceStrings(skillDesc, "<<AB_DURATION:17566))>>", "AB_DURATION");
		skillDesc = ReplaceStrings(skillDesc, ")>>", ">>");	//2 cases?
		skillDesc = ReplaceStrings(skillDesc, "|cffffff", "");
		skillDesc = ReplaceStrings(skillDesc, "|r", "");
		skillDesc = ReplaceStrings(skillDesc, "  ", " ");

		minedDesc = ReplaceStrings(minedDesc, "|cffffff", "");
		minedDesc = ReplaceStrings(minedDesc, "|r", "");
		minedDesc = ReplaceStrings(minedDesc, "  ", " ");
		minedDesc = std::regex_replace(minedDesc, std::regex("WITH .* EQUIPPED\n"), "");
		auto niceMinedDesc = ReplaceStrings(minedDesc, "\n\n", "\n");

		/*
			Call down a battle standard, dealing <<1>> every <<2>> for <<3>> to enemies and applying Major Defile to them, reducing their healing received and Health Recovery by <<4>>.
			An ally near the standard can activate the |cffffffShackle|r synergy, dealing <<5>> to enemies in the area and immobilizing them for <<6>>.

			Call down a battle standard, dealing 1587 Flame Damage every 1 second for 16 seconds to enemies and applying Major Defile to them, reducing their healing received and Health Recovery by 16%.
			An ally near the standard can activate the Shackle synergy, dealing 4799 Flame Damage to enemies in the area and immobilizing them for 5 seconds
		*/

		auto matchDesc = skillDesc;

		for (int i = 0; i <= 10; ++i)
		{
			matchDesc = std::regex_replace(matchDesc, std::regex("<<" + std::to_string(i + 1) + ">>"), "(.*)");
		}

		matchDesc = std::regex_replace(matchDesc, numberRegex, ".*");

		auto indexDesc = minedDesc;
		std::smatch m;
		int charIndex = 0;

		while (std::regex_search(indexDesc, m, numberRegex))
		{
			char idChar = 'A' + charIndex;

			std::string id = "#";
			id += idChar;
			id += "#";

			++charIndex;
			indexDesc = std::regex_replace(indexDesc, numberRegex, id, std::regex_constants::format_first_only);
		} 

		printf("----------------------------------------------------------------------------------------------------\n");
		printf("\t%d: %s\n", abilityId, minedSkill.name.c_str());
		
		bool isMatched = std::regex_search(indexDesc, m, std::regex(matchDesc));

		if (!isMatched) 
		{
			printf("\t\tError: No match!\n");
			printf("%s\n", skillDesc.c_str());
			printf("%s\n", indexDesc.c_str());
			printf("%s\n", matchDesc.c_str());
			continue;
		}

		std::unordered_map<int, int> IndexMap;
		std::unordered_map<int, int> IndexReverseMap;

		printf("%s\n", niceMinedDesc.c_str());

		for (unsigned i = 1; i < m.size(); ++i)
		{
			std::string subMatch = m.str(i);
			std::smatch m1;

			isMatched = std::regex_search(subMatch, m1, std::regex("#([A-Z])#"));

			if (isMatched)
			{
				char ch = m1.str(1).c_str()[0];
				int index = ch - 'A' + 1;

				IndexMap[i] = index;
				IndexReverseMap[index] = i;

				printf("\t\t%d: %s => %d\n", i, m.str(i).c_str(), index);
			}
			else
			{
				printf("\t\t%d: %s\n", i, m.str(i).c_str());
			}
		}

		/*
		  28348: Absorption Field
				1: #A# seconds
				2: #B#
				3: #C# seconds
		*/

		for (auto&& numberIndex : entry.indexes)
		{
			if (IndexMap.find(numberIndex) == IndexMap.end())
			{
				printf("\t\tError: Number index %d does not has a valid tooltip index!\n", numberIndex);
				continue;
			}

			size_t tooltipIndex = IndexMap[numberIndex];

			if (tooltipIndex - 1 >= skill.list4.size())
			{
				printf("\t\tError: TooltipIndex %d (from number index %d) is not valid!\n", tooltipIndex, numberIndex);
				continue;
			}

			auto abilityId1 = skill.list4[tooltipIndex - 1];

			if (g_ValidSkillIds.find(abilityId1) == g_ValidSkillIds.end()) 
			{ 
				printf("\t\tError: Failed to find skill data for %d!\n", abilityId1);
				continue; 
			}

			auto skillIndex1 = g_ValidSkillIds[abilityId1];
			auto& skill1 = g_Skills[skillIndex1];

			CompareIds.push_back(abilityId1);
			printf("\t\t%d: %s -- Adding to compare\n", abilityId1, skill1.name.c_str());
		}
	}

	printf("Found %d skills to compare\n", CompareIds.size());
	CompareSkills(CompareIds);
	CompareFlags(CompareIds);
}


int main()
{
	//std::cmatch cm;
	//bool m1 = std::regex_search("asdasd 1234 asd", cm, std::regex("[0-9]"));
	//bool m2 = std::regex_search("asdasd 1234 asd", cm, std::regex("[0-9]+"));
	//bool m3 = std::regex_search("asdasd 1234 asd", cm, std::regex("[0-9]+\\.?"));
	//bool m4 = std::regex_search("asdasd 1234 asd", cm, std::regex("[0-9]+\\.?[0-9]*"));
	//return 0;

	//float f1 = ConvertDwordToFloat(0x12345678);
	//float f2 = ConvertDwordToFloat(-1701197506);
	//return 0;

	LoadSkillListCsv(AOEHEALS_FILENAME, g_AoeHealSkills);
	LoadSkillListCsv(HOTHEALS_FILENAME, g_HotHealSkills);
	LoadSkillListCsv(STHEALS_FILENAME, g_StHealSkills);
	LoadSkillListCsv(ALLHEALS_FILENAME, g_AllHealSkills);

	LoadSkillDescriptionCsv(SKILLDATA_SKILLDESC_FILENAME);
	LoadMinedSkillCsv(SKILLDATA_MINEDSKILLS_FILENAME);

	//CheckDescriptions();
	//return 0;

	if (!LoadSkillData(SKILLDATA_FILENAME)) return ReportError("Failed to load file!");

	//CompareSkillList("AOE Heals", g_AoeHealSkills);
	//CompareSkillList("HOT Heals", g_HotHealSkills);
	//CompareSkillList("SingleTarget Heals", g_StHealSkills);
	CompareSkillList("All Heals", g_AllHealSkills);

	OutputFlagCsv();
	//OutputSkills();
	return 0;

	//CheckSkillCosts();
	//CheckTooltipTypes();
	//return 0;

	//AnalyzeU8();
	//AnalyzeList1();
	//AnalyzeList3();
	//return 0;

	//CompareSkills1();

	//AnalyzeZeros();
	//AnalyzeU2Data();

	//PrintZeros();
	//PrintU2Data();

	//AnalyzeNames();
	//AnalyzeFlags();
	//PrintFlags();

	//AnalyzeIdLists();
	//OutputIdListSummary();

	//OutputSummaryCsv();
	//OutputFlagCsv();

	//OutputSkills();

	//CompareSkills({ 28988, 29012, 115001, 25091, 27706, 22138, 83272, 32624, 35713 });	//Ultimates
	//CompareSkills({ 115307, 33308, 39489, 31642 });	//Health Skills

	//CompareSkills({ 28995, 23806,  20805, 20657, 20917, 114108, 20492, 20499, 20496, 28967 });	//Flame DD Skills
	//CompareSkills({ 20668, 20944, 117624, 86019, 94445,  38685, 38701, 28869, 38645, 38660 });	//Poison DD Skills
	//44363, 31102			// Flame DOT
	//44369,31103, 38703, 44540, 44545, 44549			// Poison DOT

	//skilldata_t compare1 = CompareSkills({ 23806, 20805, 20657, 20917, 20492, 20499, 20496 });	//Flame DD Skills
	//skilldata_t compare2 = CompareSkills({ 20944, 86019, 94445, 38701, 28869, 38645, 38660 });	//Poison DD Skills

	//skilldata_t compare1 = CompareSkills({ 44363, 31102, 44369, 31103,  38703, 44540, 44545, 44549 });	//DOT
	//skilldata_t compare2 = CompareSkills({ 28995, 23806, 20805, 20944, 117624, 86019, 94445, 28869 });	//DD
	//DiffSkills(compare1, compare2, false);

	skilldata_t compare1 = CompareSkills({ 31837, 36052, 23189 });	//AOE 
	skilldata_t compare2 = CompareSkills({ 23806, 20657, 33386 });	//Single Target

	//  DD Heals: 22250, 114196,
	// AOE Heals: 22304, 115318, 28386
	// DOT Heals: 28536, 28385

	//skilldata_t compare1 = CompareSkills({ 23211, 33333, 101703 });	//DOT
	//skilldata_t compare2 = CompareSkills({ 22057, 23806,  43714 });	//DD

	//DiffSkills(compare1, compare2);
	//DiffSkills(20668, 28995);
	//DiffSkills(20944, 23806);

    return 0;
}



 





