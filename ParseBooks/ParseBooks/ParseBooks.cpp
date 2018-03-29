/*
	ParseBooks.cpp : March 2017, Dave Humphrey, dave@uesp.net

	Parses english book title/text from the raw game data files. Assumes the english text is in the subfile
	498404 from eso0000.dat.

*/

#include "stdafx.h"
#include "ParseBooks.h"

using namespace std;
using namespace eso;


//const string INPUT_FILENAME = "e:\\Temp\\testexport\\000\\498404.dat";
const string INPUT_FILENAME = "e:\\esoexport\\esomnf-17\\gamedata\\lang\\en.lang";
const string BOOK_OUTPUT_PATH = "e:\\esoexport\\goodimages-17\\BookExport\\";
const string BOOK_OUTPUT_SQL_FILE = "e:\\esoexport\\goodimages-17\\books.sql";
const string BOOK_OUTPUT_PHP_FILE = "e:\\esoexport\\goodimages-17\\BookTitles.php";

const string QUEST_OUTPUT_SQL_FILE = "e:\\esoexport\\goodimages-17\\quests.sql";
const string QUEST_OUTPUT_PHP_FILE = "e:\\esoexport\\goodimages-17\\Quests.php";

const dword BOOK_TITLE_ID = 0x030D11F5;
const dword BOOK_TEXT_ID  = 0x014593B4;

const dword QUEST_NAME_ID = 52420949;
const dword QUEST_JOURNAL_ID = 265851556;

unordered_map<dword, bookdata_t> BookTexts;
unordered_map<string, dword> BookUniqueTitles;
unordered_map<string, vector<dword>> BookUniqueIds;
unordered_map<dword, bool> BookIdenticalText;

unordered_map<dword, questdata_t> QuestData;
unordered_map<string, dword> QuestUniqueNames;


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

		string escTitle = Record.Title;
		string escText = Record.Text;

		escTitle = ReplaceStrings(escTitle, "\\", "\\\\");
		escTitle = ReplaceStrings(escTitle, "'", "\\'");
		escTitle = ReplaceStrings(escTitle, "\"", "\\\"");
		escTitle = ReplaceStrings(escTitle, "\n", "\\n");
		escTitle = ReplaceStrings(escTitle, "\r", "\\r");
		escTitle = ReplaceStrings(escTitle, "\t", "\\t");

		escText = ReplaceStrings(escText, "\\", "\\\\");
		escText = ReplaceStrings(escText, "'", "\\'");
		escText = ReplaceStrings(escText, "\"", "\\\"");
		escText = ReplaceStrings(escText, "\n", "\\n");
		escText = ReplaceStrings(escText, "\r", "\\r");
		escText = ReplaceStrings(escText, "\t", "\\t");

		if (TitleCount > 0)
		{
			snprintf(Buffer, 20, " (%u)", TitleCount);
			escTitle += Buffer;
		}

		//SqlFile.Printf("INSERT IGNORE INTO book SET bookId=%d, title='%s';\n", Record.Index, escTitle.c_str());
		SqlFile.Printf("UPDATE book SET body='%s', bookId=%d WHERE title='%s';\n", escText.c_str(), Record.Index, escTitle.c_str());

		escTitle = Record.Title;
		escTitle = ReplaceStrings(escTitle, "\"", "\\\"");
		escTitle = ReplaceStrings(escTitle, "\n", "\\n");
		escTitle = ReplaceStrings(escTitle, "\r", "\\r");
		escTitle = ReplaceStrings(escTitle, "\t", "\\t");
		escTitle = ReplaceStrings(escTitle, "—", "-");

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

	if (!SqlFile.Open(QUEST_OUTPUT_SQL_FILE, "wb")) return false;
	if (!PhpFile.Open(QUEST_OUTPUT_PHP_FILE, "wb")) return false;

	PhpFile.Printf("<?php\n");
	PhpFile.Printf("$ESO_QUEST_DATA = array(\n");

	for (auto it : QuestData)
	{
		questdata_t& Record = it.second;
		CFile File;

		string QuestName = Record.Name;
		string escName = Record.Name;
		string escJournal = Record.Journal;

		escName = ReplaceStrings(escName, "\\", "\\\\");
		escName = ReplaceStrings(escName, "'", "\\'");
		escName = ReplaceStrings(escName, "\"", "\\\"");
		escName = ReplaceStrings(escName, "\n", "\\n");
		escName = ReplaceStrings(escName, "\r", "\\r");
		escName = ReplaceStrings(escName, "\t", "\\t");

		escJournal = ReplaceStrings(escJournal, "\\", "\\\\");
		escJournal = ReplaceStrings(escJournal, "'", "\\'");
		escJournal = ReplaceStrings(escJournal, "\"", "\\\"");
		escJournal = ReplaceStrings(escJournal, "\n", "\\n");
		escJournal = ReplaceStrings(escJournal, "\r", "\\r");
		escJournal = ReplaceStrings(escJournal, "\t", "\\t");

		SqlFile.Printf("UPDATE quest SET internalId='%d' WHERE name='%s';\n", Record.Id, escName.c_str());

		escName = Record.Name;
		escName = ReplaceStrings(escName, "\"", "\\\"");
		escName = ReplaceStrings(escName, "\n", "\\n");
		escName = ReplaceStrings(escName, "\r", "\\r");
		escName = ReplaceStrings(escName, "\t", "\\t");
		escName = ReplaceStrings(escName, "—", "-");

		escJournal = Record.Journal;
		escJournal = ReplaceStrings(escJournal, "\"", "\\\"");
		escJournal = ReplaceStrings(escJournal, "\n", "\\n");
		escJournal = ReplaceStrings(escJournal, "\r", "\\r");
		escJournal = ReplaceStrings(escJournal, "\t", "\\t");
		escJournal = ReplaceStrings(escJournal, "—", "-");

		PhpFile.Printf("\t%d => array(\n", Record.Id);
		PhpFile.Printf("\t\t\t'name'    => \"%s\",\n",  escName.c_str());
		PhpFile.Printf("\t\t\t'journal' => \"%s\",\n", escJournal.c_str());
		PhpFile.Printf("\t\t),\n");
	}

	PhpFile.Printf(");\n\n");
	PhpFile.Close();
	SqlFile.Close();

	return true;
}


int main()
{
	CEsoLangFile LangData;

	OpenLog("ParseBooks.log");

	printf("Loading language file %s...\n", INPUT_FILENAME.c_str());

	LangData.Load(INPUT_FILENAME);
	printf("Loaded %u records from language data!\n", LangData.GetNumRecords());

	//ParseBooks(LangData);
	ParseQuests(LangData);

    return 0;
}
