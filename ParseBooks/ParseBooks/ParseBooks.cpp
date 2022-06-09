/*
	ParseBooks.cpp : March 2017, Dave Humphrey, dave@uesp.net

	Parses english book title/text from the raw game data files. Assumes the english text is in the subfile
	498404 from eso0000.dat.

*/

#include "stdafx.h"
#include "ParseBooks.h"
#include <stdarg.h>  
#include <map>

using namespace std;
using namespace eso;

	/* Now defined by command line arguments */
string VERSION = "34";
string BASEPATH = "e:\\esoexport\\";

string INPUT_PATH_PREFIX;
string OUTPUT_PATH_PREFIX;

string INPUT_FILENAME;
string BOOK_OUTPUT_PATH;
string BOOK_OUTPUT_SQL_FILE;
string BOOK_OUTPUT_PHP_FILE;

//string QUEST_INPUT_FILE = INPUT_PATH_PREFIX "000\\589829_Uncompressed.EsoFileData";		// Update 17pts, last patch
//string QUEST_INPUT_FILE = INPUT_PATH_PREFIX "000\\589825_Uncompressed.EsoFileData";		// Update 17, original patch
//string QUEST_INPUT_FILE = INPUT_PATH_PREFIX "000\\590070_Uncompressed.EsoFileData";		// Update 17, 3.3.11.1585543
string QUEST_OUTPUT_SQL_FILE;
string QUEST_OUTPUT_PHP_FILE;
string QUEST_OUTPUT_TXT_FILE;
string ZONE_OUTPUT_TXT_FILE;
string MNF_TEXT_FILE;

string SET_OUTPUT_PHP_FILE;
string SET_OUTPUT_TXT_FILE;

const dword BOOK_TITLE_ID = 0x030D11F5;
const dword BOOK_TEXT_ID  = 0x014593B4;

const dword ZONE_NAME_ID = 162658389;

const dword QUEST_NAME_ID = 52420949;
const dword QUEST_JOURNAL_ID = 265851556;

const dword SET_NAME_ID = 38727365;

unordered_map<dword, bookdata_t> BookTexts;
unordered_map<string, dword> BookUniqueTitles;
unordered_map<string, vector<dword>> BookUniqueIds;
unordered_map<dword, bool> BookIdenticalText;

unordered_map<dword, questdata_t> QuestData;
unordered_map<string, dword> QuestUniqueNames;
unordered_map<dword, string> ZoneNames;

map<dword, string> SetNames;


std::string EscapeSql(const std::string Input)
{
	std::string escInput = ReplaceStrings(Input, "\\", "\\\\");

	escInput = ReplaceStrings(escInput, "'", "\\'");
	escInput = ReplaceStrings(escInput, "\"", "\\\"");
	escInput = ReplaceStrings(escInput, "\n", "\\n");
	escInput = ReplaceStrings(escInput, "\r", "\\r");
	escInput = ReplaceStrings(escInput, "\t", "\\t");

	return escInput;
}


std::string EscapePhp(const std::string Input)
{
	std::string escInput = ReplaceStrings(Input, "\"", "\\\"");

	escInput = ReplaceStrings(escInput, "\n", "\\n");
	escInput = ReplaceStrings(escInput, "\r", "\\r");
	escInput = ReplaceStrings(escInput, "\t", "\\t");
	escInput = ReplaceStrings(escInput, "—", "-");

	return escInput;
}


bool ParseBooks(CEsoLangFile& LangData)
{
	printf("Parsing book titles and texts...\n");

	for (dword i = 0; i < LangData.GetNumRecords(); ++i)
	{
		lang_record_t& Record = LangData.GetRecord(i);

		if (Record.Id == BOOK_TITLE_ID)
		{
			BookTexts[Record.Index].Index = Record.Index;
			BookTexts[Record.Index].Title = Record.Text;
			BookUniqueTitles[Record.Text] += 1;
			BookUniqueIds[Record.Text].push_back(Record.Index);
			BookIdenticalText[Record.Index] = false;
		}
		else if (Record.Id == BOOK_TEXT_ID)
		{
			BookTexts[Record.Index].Index = Record.Index;
			BookTexts[Record.Index].Text = Record.Text;
			BookIdenticalText[Record.Index] = false;
		}
	}

	printf("Found %u books with %u unique titles...\n", BookTexts.size(), BookUniqueTitles.size());
	printf("Searching for duplicate titles with identical texts...\n");

	dword MatchingTextCount = 0;

	for (auto it : BookUniqueIds)
	{
		if (it.second.size() <= 1) continue;

		for (dword i = 0; i < it.second.size(); ++i)
		{
			dword id1 = it.second[i];
			std::string Text1 = BookTexts[id1].Text;

			for (dword j = 0; j < it.second.size(); ++j)
			{
				if (j <= i) continue;

				dword id2 = it.second[j];
				std::string Text2 = BookTexts[id2].Text;

				if (Text1 == Text2)
				{
					printf("\tFound identical texts for %s (%u + %u)\n", BookTexts[id1].Title.c_str(), i, j);
					++MatchingTextCount;
					BookIdenticalText[BookTexts[id2].Index] = true;
				}

			}
		}
	}

	printf("Found %u identical book texts!\n", MatchingTextCount);
	printf("The %u non-unique book titles are:\n", BookTexts.size() - BookUniqueTitles.size());

	for (auto it : BookUniqueTitles)
	{
		if (it.second > 1)
		{
			printf("\t%3u: %s\n", it.second, it.first.c_str());
		}

	}

	printf("Exporting all book texts and SQL file...\n");

	EnsurePathExists(BOOK_OUTPUT_PATH);
	unordered_map<string, dword> BookTitleCount;
	CFile SqlFile;
	CFile PhpFile;

	if (!SqlFile.Open(BOOK_OUTPUT_SQL_FILE, "wb")) return false;
	if (!PhpFile.Open(BOOK_OUTPUT_PHP_FILE, "wb")) return false;

	PhpFile.Printf("<?php\n");
	PhpFile.Printf("$BOOK_TITLES = array(\n");

	for (auto it : BookTexts)
	{
		bookdata_t& Record = it.second;

		if (BookIdenticalText[Record.Index]) continue;

		dword TitleCount = BookTitleCount[Record.Title]++;
		char OutputFilename[1024];
		char Buffer[32];
		CFile File;

		string Title = Record.Title;
		std::replace(Title.begin(), Title.end(), '?', '_');
		std::replace(Title.begin(), Title.end(), '"', '\'');
		std::replace(Title.begin(), Title.end(), ':', '_');
		std::replace(Title.begin(), Title.end(), ':', '_');
		std::replace(Title.begin(), Title.end(), '\t', ' ');
		Title = ReplaceStrings(Title, "â€", " - ");
		Title = ReplaceStrings(Title, "\xE2\x80\xA6", "...");
		Title = ReplaceStrings(Title, "\xE2\x80\x94", " - ");
		//â€
		//â€”

		if (TitleCount > 0)
			snprintf(OutputFilename, 1000, "%s%s_%u.txt", BOOK_OUTPUT_PATH.c_str(), Title.c_str(), TitleCount);
		else
			snprintf(OutputFilename, 1000, "%s%s.txt", BOOK_OUTPUT_PATH.c_str(), Title.c_str());

		if (!File.Open(OutputFilename, "wb")) continue;

		File.Printf("%s\n\n", Record.Title.c_str());
		File.Printf("%s", Record.Text.c_str());

		string escTitle = EscapeSql(Record.Title);
		string escText = EscapeSql(Record.Text);

		if (TitleCount > 0)
		{
			snprintf(Buffer, 20, " (%u)", TitleCount);
			escTitle += Buffer;
		}

		//SqlFile.Printf("INSERT IGNORE INTO book SET bookId=%d, title='%s';\n", Record.Index, escTitle.c_str());
		SqlFile.Printf("UPDATE book SET body='%s', bookId=%d WHERE title='%s';\n", escText.c_str(), Record.Index, escTitle.c_str());

		escTitle = EscapePhp(Record.Title);
		
		if (TitleCount > 0)
		{
			snprintf(Buffer, 20, " (%u)", TitleCount);
			escTitle += Buffer;
		}

		PhpFile.Printf("\t%d => \"%s\",\n", Record.Index, escTitle.c_str());
	}

	PhpFile.Printf(");\n\n");
	PhpFile.Close();
	SqlFile.Close();

	printf("The following books have identical titles and unique texts:\n");

	for (auto it : BookTitleCount)
	{
		if (it.second > 1)
		{
			printf("\t%3u: %s\n", it.second, it.first.c_str());
		}
	}

	return true;
}


bool ParseQuests(CEsoLangFile& LangData)
{
	printf("Parsing quest names and journal texts...\n");

	for (dword i = 0; i < LangData.GetNumRecords(); ++i)
	{
		lang_record_t& Record = LangData.GetRecord(i);

		if (Record.Id == QUEST_NAME_ID)
		{
			QuestData[Record.Index].Id = Record.Index;
			QuestData[Record.Index].Name = Record.Text;
			QuestUniqueNames[Record.Text] += 1;
		}
		else if (Record.Id == QUEST_JOURNAL_ID)
		{
			QuestData[Record.Index].Id = Record.Index;
			QuestData[Record.Index].Journal = Record.Text;
		}
	}

	printf("Found %u quests with %u unique names...\n", QuestData.size(), QuestUniqueNames.size());
	printf("Exporting all quest data and SQL file...\n");

	CFile SqlFile;
	CFile PhpFile;
	CFile TxtFile;
	
	if (!SqlFile.Open(QUEST_OUTPUT_SQL_FILE, "wb")) return false;
	if (!PhpFile.Open(QUEST_OUTPUT_PHP_FILE, "wb")) return false;
	if (!TxtFile.Open(QUEST_OUTPUT_TXT_FILE, "wb")) return false;
	
	PhpFile.Printf("<?php\n");
	PhpFile.Printf("$ESO_QUEST_DATA = array(\n");

	TxtFile.Printf("\"ID\", \"Name\", \"Type\", \"Journal\", \"InternalName\", \"Zone\", \"ZoneID\"\n");

	for (auto it : QuestData)
	{
		questdata_t& Record = it.second;
		CFile File;

		string QuestName = Record.Name;
		string escName = EscapeSql(Record.Name);
		string escJournal = EscapeSql(Record.Journal);
		string escIntName = EscapeSql(Record.InternalName);
		string escZone = EscapeSql(Record.ZoneName);

		SqlFile.Printf("UPDATE quest SET internalId='%d' WHERE name='%s';\n", Record.Id, escName.c_str());

		escName = EscapePhp(Record.Name);
		escJournal = EscapePhp(Record.Journal);
		escIntName = EscapePhp(Record.InternalName);
		escZone = EscapePhp(Record.ZoneName);

		PhpFile.Printf("\t%d => array(\n", Record.Id);
		PhpFile.Printf("\t\t\t'name'    => \"%s\",\n",  escName.c_str());
		PhpFile.Printf("\t\t\t'journal' => \"%s\",\n", escJournal.c_str());
		PhpFile.Printf("\t\t\t'internalName' => \"%s\",\n", escIntName.c_str());
		PhpFile.Printf("\t\t\t'zoneId' => %d,\n", Record.ZoneId);
		PhpFile.Printf("\t\t\t'zone' => \"%s\",\n", escZone.c_str());
		PhpFile.Printf("\t\t\t'type' => %d,\n", Record.Type);
		PhpFile.Printf("\t\t),\n");

		TxtFile.Printf("%d, \"%s\", %d, \"%s\", \"%s\", \"%s\", %d\n", Record.Id, escName.c_str(), Record.Type, escJournal.c_str(), escIntName.c_str(), escZone.c_str(), Record.ZoneId);
		
	}

	PhpFile.Printf(");\n\n");
	PhpFile.Close();
	SqlFile.Close();

	return true;
}


bool ReportError(const char* pMsg, ...)
{
	va_list Args;

	va_start(Args, pMsg);
	vprintf(pMsg, Args);
	return false;
}


bool ParseQuestData(const std::string QuestDataFilename)
{
	CFile QuestFile;
	dword NumRecords = 0;
	int iVersion = atoi(VERSION.c_str());

	printf("Parsing quest data from raw file '%s'..\n", QuestDataFilename.c_str());

	if (!QuestFile.Open(QuestDataFilename, "rb")) return ReportError("Failed to load quest data file!\n");
	if (!QuestFile.Seek(8, SEEK_SET)) return ReportError("Failed to find NumRecords field in quest data file!\n");
	if (!QuestFile.ReadDword(NumRecords, false)) return ReportError("Failed to read NumRecords field in quest data file!\n");
	if (!QuestFile.Seek(16, SEEK_SET)) return ReportError("Failed to find first record in quest data file!\n");

	printf("Loading %d quest records...\n", NumRecords);

	for (dword RecordIndex = 1; RecordIndex <= NumRecords; ++RecordIndex)
	{
		fpos_t StartOffset = QuestFile.Tell();

		fpos_t EndOffset;
		dword FullRecordSize;
		dword RecordSize;
		dword ZoneId;
		dword QuestId;
		word NameSize;
		dword Type;
		word RecordCount1;
		dword Constant1;
		dword RecordCount2;
		dword RecordCount3;
		dword RecordCount4;
		std::string Name;

		if (!QuestFile.Seek(8, SEEK_CUR)) return ReportError("Failed to find record size in quest data file!\n");
		if (!QuestFile.ReadDword(RecordSize, false)) return ReportError("Failed to read record size in quest data file!\n");

			// Update 27 reverses the first ID field with the previous unknown field
		//if (!QuestFile.Seek(8, SEEK_CUR)) return ReportError("Failed to find quest Id in quest data file!\n");	

		if (!QuestFile.Seek(20, SEEK_CUR)) return ReportError("Failed to find quest Id in quest data file!\n");
		if (!QuestFile.ReadDword(QuestId, false)) return ReportError("Failed to read quest Id in quest data file!\n");

		//if (!QuestFile.Seek(12, SEEK_CUR)) return ReportError("Failed to find name size in quest data file!\n");
		if (!QuestFile.ReadWord(NameSize, false)) return ReportError("Failed to read name size in quest data file!\n");

		FullRecordSize = RecordSize + 32;
		EndOffset = StartOffset + FullRecordSize;

		//ReportError("%d: 0x%lX - 0x%lX\n", QuestId, (int) StartOffset, (int)EndOffset);
		
		char* pBuffer = new char[NameSize + 4];
		if (!QuestFile.ReadBytes((eso::byte *) pBuffer, NameSize + 1)) return ReportError("Failed to read quest name in quest data file!\n");
		Name = pBuffer;
		delete[] pBuffer;

			// Version 20-25: 22
			// Version 26: 23
			// Version 27: 22
		if (iVersion == 26 || iVersion >= 30)
		{
			if (!QuestFile.Seek(23, SEEK_CUR)) return ReportError("Failed to find record1 count in quest data file!\n");
		}
		else
		{
			if (!QuestFile.Seek(22, SEEK_CUR)) return ReportError("Failed to find record1 count in quest data file!\n");
		}
		
		if (!QuestFile.ReadWord(RecordCount1, false)) return ReportError("Failed to read record1 count in quest data file!\n");

		fpos_t MiddleOffset = QuestFile.Tell();
		fpos_t DeltaOffset;

		DeltaOffset = 4 * RecordCount1;
		if (MiddleOffset + DeltaOffset > EndOffset) return ReportError("Data overflow in record1 field!\n");
		if (!QuestFile.Seek(DeltaOffset, SEEK_CUR)) return ReportError("Failed to find record2 count in quest data file!\n");
		if (!QuestFile.ReadDword(RecordCount2, false)) return ReportError("Failed to read record2 count in quest data file!\n");
		MiddleOffset += DeltaOffset + 4;

		DeltaOffset = 4 * RecordCount2;
		if (MiddleOffset + DeltaOffset > EndOffset) return ReportError("Data overflow in record2 field!\n");
		if (!QuestFile.Seek(DeltaOffset, SEEK_CUR)) return ReportError("Failed to find record2 count in quest data file!\n");
		if (!QuestFile.ReadDword(RecordCount3, false)) return ReportError("Failed to read record3 count in quest data file!\n");
		MiddleOffset += DeltaOffset + 4;

		DeltaOffset = 4 * RecordCount3 + 4;
		if (MiddleOffset + DeltaOffset > EndOffset) return ReportError("Data overflow in record3 field!\n");
		if (!QuestFile.Seek(DeltaOffset, SEEK_CUR)) return ReportError("Failed to find record4 count in quest data file!\n");
		if (!QuestFile.ReadDword(RecordCount4, false)) return ReportError("Failed to read record4 count in quest data file!\n");
		MiddleOffset += DeltaOffset + 4;

		DeltaOffset = 4 * RecordCount4;
		if (MiddleOffset + DeltaOffset > EndOffset) return ReportError("Data overflow in record4 field (0x%08lX, 0x%lX, 0x%lX, 0x%lX)!\n",(int) MiddleOffset, (int)RecordCount4, (int)DeltaOffset, (int)EndOffset);
		if (!QuestFile.Seek(DeltaOffset, SEEK_CUR)) return ReportError("Failed to find end of record4 data in quest data file!\n");

		//if (!QuestFile.Seek(StartOffset + RecordSize + 32 - 68, SEEK_SET)) return ReportError("Failed to find quest type field in quest data file!\n");
		if (!QuestFile.ReadDword(Type, false)) return ReportError("Failed to read quest type field in quest data file!\n");
		if (!QuestFile.ReadDword(Constant1, false)) return ReportError("Failed to read 0x32 constant field in quest data file!\n");
		if (Constant1 != 0x32 && Constant1 != 0 && Constant1 != 0x3B) return ReportError("Failed to find 0x32 constant field in quest data file (%d, %d, 0x%08X, %d, %d, %d)!\n", Constant1, Type, QuestFile.Tell(), RecordCount1, RecordCount2, RecordCount3);

		/*if (Type == 50)
		{
			if (!QuestFile.Seek(StartOffset + RecordSize + 32 - 68 - 4, SEEK_SET)) return ReportError("Failed to find quest type field in quest data file!\n");
			if (!QuestFile.ReadDword(Type, false)) return ReportError("Failed to read quest type field in quest data file!\n");
		}*/

		// Update 20-25 = -4
		// Update 27-? = -12

		int zoneOffset = 4;
		if (iVersion >= 27) zoneOffset = 12;
		if (iVersion >= 30) zoneOffset = 12 + 16;
		if (iVersion >= 34) zoneOffset = 12 + 16 + 4;
		
		if (!QuestFile.Seek(StartOffset + RecordSize - zoneOffset, SEEK_SET)) return ReportError("Failed to find zone field in quest data file!\n");
		//ReportError("%d: ZoneId: 0x%lX\n", QuestId, (int) (StartOffset + RecordSize - zoneOffset));
		if (!QuestFile.ReadDword(ZoneId, false)) return ReportError("Failed to read zone field in quest data file!\n");

		// Update 20-25: 0-13
		// Update 26: 0-15

		if (Type < 0 || Type > 20) return ReportError("Invalid type value of %d found at 0x%08X!\n", Type, QuestFile.Tell());

		printf("\t%d) %s (%d) = %d / %d\n", RecordIndex, Name.c_str(), QuestId, Type, ZoneId);

		QuestData[QuestId].InternalName = Name;
		QuestData[QuestId].ZoneId = ZoneId;
		QuestData[QuestId].Type = Type;
		if (ZoneNames.find(ZoneId) != ZoneNames.end()) QuestData[QuestId].ZoneName = ZoneNames[ZoneId];

		if (!QuestFile.Seek(StartOffset + RecordSize + 32, SEEK_SET)) return ReportError("Failed to find record size in quest data file!\n");
	}

	return true;
}


bool ParseZoneNames(CEsoLangFile& LangData)
{
	CFile ZoneFile;

	if (!ZoneFile.Open(ZONE_OUTPUT_TXT_FILE, "wb")) return false;
	printf("Parsing zone names...\n");

	for (dword i = 0; i < LangData.GetNumRecords(); ++i)
	{
		lang_record_t& Record = LangData.GetRecord(i);

		if (Record.Id == ZONE_NAME_ID)
		{
			ZoneNames[Record.Index] = Record.Text;
			ZoneFile.Printf("%d, \"%s\"\n", Record.Index, Record.Text.c_str());
		}
	}

	printf("Found %d zone names!\n", ZoneNames.size());

	return true;
}


bool FindQuestDataFile(std::string &Filename)
{
	CCsvFile MnfFile;

	if (!MnfFile.Load(MNF_TEXT_FILE)) return ReportError("Failed to load and parse the MNF text file '%s'!\n", MNF_TEXT_FILE);

	for (int i = 0; i < MnfFile.GetNumRows(); ++i)
	{
		const csvrow_t& Row = MnfFile.GetData()[i];
		if (Row.size() < 4) continue;

		int Index = strtol(Row[0].c_str(), nullptr, 10);
		int ID1 = strtol(Row[1].c_str(), nullptr, 16);
		int FileIndex = strtol(Row[2].c_str(), nullptr, 16);
		int Unk1 = strtol(Row[3].c_str(), nullptr, 16);

		if (ID1 == 0 && FileIndex == 10 && Unk1 == 0x60000000)
		{
			Filename = INPUT_PATH_PREFIX + std::string("000\\") + ReplaceStrings(Row[0], " ", "") + "_Uncompressed.EsoFileData";
			ReportError("Found the quest data file: %s\n", Filename.c_str());
			return true;
		}
	}

	ReportError("Failed to find the quest data file!\n");
	return false;
}



bool ParseSets(CEsoLangFile& LangData)
{
	printf("Parsing set name...\n");

	for (dword i = 0; i < LangData.GetNumRecords(); ++i)
	{
		lang_record_t& Record = LangData.GetRecord(i);

		if (Record.Id == SET_NAME_ID)
		{
			SetNames[Record.Index] = Record.Text;
		}
	}

	printf("Found %u sets...\n", SetNames.size());
	CFile PhpFile;
	CFile TxtFile;

	printf("Saving set data to %s...\n", SET_OUTPUT_PHP_FILE.c_str());

	if (!PhpFile.Open(SET_OUTPUT_PHP_FILE, "wb")) return false;
	if (!TxtFile.Open(SET_OUTPUT_TXT_FILE, "wb")) return false;

	PhpFile.Printf("$ESO_SET_INDEXES = array(\n");
	TxtFile.Printf("ID, Name\n");

	for (auto it : SetNames)
	{
		dword id = it.first;
		string& name = it.second;
		string escName = EscapePhp(name);

		TxtFile.Printf("%d, %s\n", id, name.c_str());

		PhpFile.Printf("\t\t%d => \"%s\",\n", id, escName.c_str());
	}

	PhpFile.Printf(");\n");
	
	return true;
}


void MakeInputOutputFilenames()
{
	BASEPATH = TerminatePath(BASEPATH);

	INPUT_PATH_PREFIX = BASEPATH + "esomnf-" + VERSION + "\\";
	OUTPUT_PATH_PREFIX = BASEPATH + "goodimages-" + VERSION + "\\";;

	INPUT_FILENAME = INPUT_PATH_PREFIX + "gamedata\\lang\\en.lang";
	BOOK_OUTPUT_PATH = OUTPUT_PATH_PREFIX + "Books\\";
	BOOK_OUTPUT_SQL_FILE = OUTPUT_PATH_PREFIX + "books.sql";
	BOOK_OUTPUT_PHP_FILE = OUTPUT_PATH_PREFIX + "BookTitles.php";

	QUEST_OUTPUT_SQL_FILE = OUTPUT_PATH_PREFIX + "Quests\\quests.sql";
	QUEST_OUTPUT_PHP_FILE = OUTPUT_PATH_PREFIX + "Quests\\Quests.php";
	QUEST_OUTPUT_TXT_FILE = OUTPUT_PATH_PREFIX + "Quests\\Quests.txt";
	MNF_TEXT_FILE = INPUT_PATH_PREFIX + "mnf.txt";

	ZONE_OUTPUT_TXT_FILE = OUTPUT_PATH_PREFIX + "Quests\\Zones.txt";

	SET_OUTPUT_PHP_FILE = OUTPUT_PATH_PREFIX + "Sets.php";
	SET_OUTPUT_TXT_FILE = OUTPUT_PATH_PREFIX + "Sets.txt";
}


int main(int argc, char* argv[])
{
	CEsoLangFile LangData;
	std::string QuestDataFilename;

	OpenLog("ParseBooks.log");

	if (argc < 3) return ReportError("Missing required command line arguments: [Version] [BasePath]\n");

	VERSION = argv[1];
	BASEPATH = argv[2];

	MakeInputOutputFilenames();

	printf("Loading language file %s...\n", INPUT_FILENAME.c_str());

	LangData.Load(INPUT_FILENAME);
	printf("Loaded %u records from language data!\n", LangData.GetNumRecords());
	
	ParseZoneNames(LangData);

	if (FindQuestDataFile(QuestDataFilename))
	{
		ParseQuestData(QuestDataFilename);
	}
	
	ParseBooks(LangData);
	ParseQuests(LangData);

	ParseSets(LangData);
	
    return 0;
}
