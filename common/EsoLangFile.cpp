#include "EsoLangFile.h"

using namespace eso;


CEsoLangFile::CEsoLangFile()
{
	m_RecordCount = 0;
	m_FileId = 0x02;
}


CEsoLangFile::~CEsoLangFile()
{
	Destroy();
}


void CEsoLangFile::Destroy()
{
	m_Records.clear();
	m_RecordCount = 0;
	m_FileId = 0x02;
}


bool CEsoLangFile::AddEntry (uint64_t Id64, const std::string Text)
{
	dword Id = Id64 & 0xffffffff;
	dword Unknown = (Id64 >> 32) & 0x3ff;
	dword Index = (Id64 >> 42) & 0xfffff;

	return AddEntry(Id, Unknown, Index, 0, Text);
}


bool CEsoLangFile::AddEntry (dword Id, dword Unknown, dword Index, dword Offset, const std::string Text)
{
	lang_record_t NewRecord;

	NewRecord.Id = Id;
	NewRecord.Unknown = Unknown;
	NewRecord.Index = Index;
	NewRecord.Offset = Offset;
	NewRecord.Text = Text;

	m_Records.push_back(NewRecord);
	++m_RecordCount;

	return true;
}


void CEsoLangFile::SortRecords (void)
{
	std::sort(m_Records.begin(), m_Records.end());
}


int CEsoLangFile::CreateRecordsFromCSV (const eso::CCsvFile& CsvFile, const bool UsePOSourceText)
{
	int RecordCount = 0;
	int RowCount = 0;

	for (auto r = CsvFile.GetData().begin(); r != CsvFile.GetData().end(); ++r, ++RowCount)
	{
		if (RowCount == 0 && CsvFile.HasHeaderRow()) continue;
		
		if (r->size() < 5) 
		{
			PrintError("%d: Need at least 5 columns in CSV row to convert to LANG data!", RowCount + 1);
			continue;
		}

		lang_record_t& Record = m_Records[RecordCount];

		Record.Id      = atoi(r->at(0).c_str());
		Record.Unknown = atoi(r->at(1).c_str());
		Record.Index   = atoi(r->at(2).c_str());
		Record.Offset  = atoi(r->at(3).c_str());
		Record.Text    = ReplaceStrings(ReplaceStrings(ReplaceStrings(r->at(4), "\\n", "\x0a"), "\\r", "\x0d"), "\"\"", "\"");

		++RecordCount;
	}

	return RecordCount;
}


int CEsoLangFile::CreateRecordsFromPOCSV (const eso::CCsvFile& CsvFile, const bool UsePOSourceText)
{
	int RecordCount = 0;
	int RowCount = 0;
	int Offset = 0;

	for (auto r = CsvFile.GetData().begin(); r != CsvFile.GetData().end(); ++r, ++RowCount)
	{
		if (RowCount == 0 && CsvFile.HasHeaderRow()) continue;
		
		if (r->size() < 3) 
		{
			PrintError("%d: Need at least 3 columns in a PO-CSV row to convert to LANG data!", RowCount + 1);
			continue;
		}

		lang_record_t& Record = m_Records[RecordCount];

		int Result = sscanf(r->at(0).c_str(), "%u-%u-%u", &Record.Id, &Record.Unknown, &Record.Index);
		if (Result != 3) PrintError("%d: Failed to convert column 1 value '%s' to ID/Unknown/Index values!", RowCount + 1, r->at(0).c_str());

		Record.Offset  = Offset;

		if (UsePOSourceText)
			Record.Text = ReplaceStrings(ReplaceStrings(ReplaceStrings(r->at(1), "\\n", "\x0a"), "\\r", "\x0d"), "\"\"", "\"");
		else
			Record.Text = ReplaceStrings(ReplaceStrings(ReplaceStrings(r->at(2), "\\n", "\x0a"), "\\r", "\x0d"), "\"\"", "\"");

		Offset += (int) Record.Text.length() + 1;
		++RecordCount;
	}

	return RecordCount;
}


int CEsoLangFile::CreateRecordsFromTEXT (const std::vector<std::string>& TextFile, const std::vector<std::string>& IdFile, const bool UsePOFormat, const bool UsePOSourceText)
{
	int Delta = 1;
	size_t i;
	size_t id;
	int RecordCount = 0;
	int RowCount = 0;
	int Offset = 0;

	if (UsePOFormat) Delta = 2;

	if (UsePOFormat && IdFile.size() != TextFile.size()/2)
	{
		PrintError("Warning: Text file and ID file don't have the same number of rows (%d != %d)!", TextFile.size()/2, IdFile.size());
	}
	else if (!UsePOFormat && IdFile.size() != TextFile.size())
	{
		PrintError("Warning: Text file and ID file don't have the same number of rows (%d != %d)!", TextFile.size(), IdFile.size());
	}

	for (i = 0, id = 0; i < TextFile.size() && id < IdFile.size();  ++id, i += Delta)
	{
		lang_record_t& Record = m_Records[RecordCount];

		int Result = sscanf(IdFile[id].c_str(), "%u-%u-%u", &Record.Id, &Record.Unknown, &Record.Index);
		if (Result != 3) PrintError("%d: Failed to convert column 1 value '%s' to ID/Unknown/Index values!", RowCount + 1, IdFile[id].c_str());

		Record.Offset  = Offset;
		Record.Text = ReplaceStrings(ReplaceStrings(ReplaceStrings(TextFile[i], "\\n", "\x0a"), "\\r", "\x0d"), "\"\"", "\"");

		Offset += (int) Record.Text.length() + 1;
		++RecordCount;
	}
		
	return RecordCount;
}


bool CEsoLangFile::CreateFromText (const std::vector<std::string>& TextFile, const std::vector<std::string>& IdFile, const bool UsePOFormat, const bool UsePOSourceText)
{
	int RecordCount = 0;

	Destroy();

	m_Records.clear();

	PrintError("UsePOFormat = %d", UsePOFormat);

	if (UsePOFormat)
		m_RecordCount = (int) TextFile.size()/2;
	else
		m_RecordCount = (int) TextFile.size();

	m_Records.reserve(m_RecordCount + 100);
	m_Records.resize(m_RecordCount);

	RecordCount = CreateRecordsFromTEXT(TextFile, IdFile, UsePOFormat, UsePOSourceText);
	
	if (m_RecordCount != RecordCount)
	{
		PrintError("Warning: Expected %d language records from TEXT but only found %d!", m_RecordCount, RecordCount);
		m_RecordCount = RecordCount;
		m_Records.resize(m_RecordCount);
	}
	else
	{
		PrintError("Created %d language records from TEXT data...", m_RecordCount);
	}

	return true;
}


bool CEsoLangFile::CreateFromCsv (const eso::CCsvFile& CsvFile, const bool UsePOFormat, const bool UsePOSourceText)
{
	int RecordCount = 0;

	Destroy();

	m_Records.clear();
	m_RecordCount = CsvFile.GetNumDataRows();
	m_Records.reserve(m_RecordCount + 100);
	m_Records.resize(m_RecordCount);

	if (UsePOFormat)
		RecordCount = CreateRecordsFromPOCSV(CsvFile, UsePOSourceText);
	else
		RecordCount = CreateRecordsFromCSV(CsvFile, UsePOSourceText);

	if (m_RecordCount != RecordCount)
	{
		PrintError("Warning: Expected %d language records from CSV but only found %d!", m_RecordCount, RecordCount);
		m_RecordCount = RecordCount;
		m_Records.resize(m_RecordCount);
	}
	else
	{
		PrintError("Created %d language records from CSV data...", m_RecordCount);
	}

	return true;
}


bool CEsoLangFile::DumpCsv (const std::string Filename, const bool UsePOFormat)
{
	CFile File;

	if (!File.Open(Filename, "wb")) return false;

	if (UsePOFormat)
		File.Printf("\"Location\",\"Source\",\"Target\"\n");
	else
		File.Printf("\"ID\",\"Unknown\",\"Index\",\"Offset\",\"Text\"\n");

	for (size_t i = 0; i < m_Records.size(); ++i)
	{
		lang_record_t& Record = m_Records[i];

		if (UsePOFormat)
		{
			std::string Location;
			File.Printf("\"%d-%d-%d\",\"", Record.Id, Record.Unknown, Record.Index);
			DumpTextFile(File, Record);
			File.Printf("\",\"\"\n");
		}
		else
		{
			File.Printf("\"%d\",\"%d\",\"%d\",\"%d\",\"", Record.Id, Record.Unknown, Record.Index, Record.Offset);
			DumpTextFile(File, Record);
			File.Printf("\"\n");
		}
	}

	return true;
}


bool CEsoLangFile::DumpText (const std::string Filename, const bool UsePOFormat)
{
	CFile File;

	if (!File.Open(Filename, "wb")) return false;

	for (size_t i = 0; i < m_Records.size(); ++i)
	{
		lang_record_t& Record = m_Records[i];
		const char* pText = Record.Text.c_str();

		while (*pText)
		{
			if (*pText == '\r')
				File.Printf("\\r");
			else if (*pText == '\n')
				File.Printf("\\n");
			else
				File.WriteChar(*pText);
	
			++pText;
		}

		//File.Printf("%s\n", Record.Text.c_str());
		File.Printf("\n");
		if (UsePOFormat) File.Printf("\n");
	}

	return true;
}


bool CEsoLangFile::DumpTextId (const std::string Filename)
{
	CFile File;

	if (!File.Open(Filename, "wb")) return false;

	for (size_t i = 0; i < m_Records.size(); ++i)
	{
		lang_record_t& Record = m_Records[i];
		File.Printf("%u-%u-%u\n", Record.Id, Record.Unknown, Record.Index);
	}

	return true;
}


bool CEsoLangFile::DumpTextFile (CFile& File, lang_record_t& Record)
{
	const char* pText = Record.Text.c_str();

	while (*pText)
	{
		if (*pText == '"')
			File.Printf("\"\"");
		else if (*pText == '\r')
			File.Printf("\\r");
		else if (*pText == '\n')
			File.Printf("\\n");
		else
			File.WriteChar(*pText);
	
		++pText;
	}

	return true;
}


int CEsoLangFile::FillMissingEntries(CEsoLangFile& BaseLang)
{
	int entriesFilled = 0;
	CEsoLangIndexMap index;

		/* Create ID map of existng entries */
	for (size_t i = 0; i < m_RecordCount; ++i)
	{
		lang_record_t& Record = m_Records[i];
		char buffer[256];

		snprintf(buffer, 250, "%ud-%ud-%ud", Record.Id, Record.Unknown, Record.Index);
		index[buffer] = &m_Records[i];
	}

	PrintError("\tCreated index with %d entries from a total of %d!", index.size(), m_RecordCount);
	PrintError("\tMerging in a possible %d entries...", BaseLang.m_RecordCount);

		/* Add all entries from BaseLang that don't already exist */
	for (size_t i = 0; i < BaseLang.m_RecordCount; ++i)
	{
		lang_record_t& Record = BaseLang.m_Records[i];
		char buffer[256];

		snprintf(buffer, 250, "%ud-%ud-%ud", Record.Id, Record.Unknown, Record.Index);

		if (index.find(buffer) == index.end())
		{
			++m_RecordCount;
			++entriesFilled;
			m_Records.push_back(Record);
		}
	}

	return entriesFilled;
}


bool CEsoLangFile::Load (const std::string Filename)
{
	CFile File;

	if (!File.Open(Filename, "rb")) return false;
	if (!Read(File)) return false;

	return true;
}


bool CEsoLangFile::ParseData (eso::byte* pData, const fpos_t Size)
{
	if (pData == nullptr || Size <= 0) return PrintError ("Error: Invalid input received to CEsoLangFile::ParseFile()!");

	if (Size < 8) return PrintError ("Error: Language file too small (< 8 bytes)!");
	if (Size > INT_MAX) return PrintError ("Error: Language file too big!");

	m_FileId = ParseBufferDword(pData+0, true);
	m_RecordCount = ParseBufferDword(pData+4, true);

	if (m_RecordCount > UINT_MAX / TEXT_RECORD_SIZE - 100) {
		PrintError("Error: Too many records found in language file (%d)!", m_RecordCount);
		m_RecordCount = 0;
		return false;
	}

	if (m_RecordCount*TEXT_RECORD_SIZE > Size)
	{
		PrintError("Error: Language file has too many records (read past end of file)!");
		m_RecordCount = 0;
		return false;
	}

	m_Records.clear();
	m_Records.reserve(m_RecordCount + 100);
	m_Records.resize(m_RecordCount);

	size_t StartTextOffset = m_RecordCount*TEXT_RECORD_SIZE + 8;

	for (size_t i = 0; i < m_RecordCount; ++i)
	{
		size_t Offset = 8 + i * TEXT_RECORD_SIZE;
		lang_record_t& Record = m_Records[i];

		Record.Id      = ParseBufferDword(pData+Offset+0x0, true);
		Record.Unknown = ParseBufferDword(pData+Offset+0x4, true);
		Record.Index   = ParseBufferDword(pData+Offset+0x8, true);
		Record.Offset  = ParseBufferDword(pData+Offset+0xC, true);

		fpos_t TextOffset = Record.Offset + StartTextOffset;

		if (TextOffset < Size)
		{
			//std::string Temp = ParseBufferString(pData, TextOffset, (size_t)Size);
			//Record.Text = ReplaceStrings(ReplaceStrings(Temp, "\x0d", "\\r"), "\x0a", "\\n");
			Record.Text = ParseBufferString(pData, TextOffset, (size_t)Size);
		}
		else
		{
			PrintLog("Warning: Read past end of file (offset 0x%08X) in text record #%d", TextOffset, i);
		}
	}

	return true;
}


bool CEsoLangFile::Read (CFile& File)
{
	fpos_t FileSize;
	byte* pFileBuffer = File.ReadAll(FileSize);

	if (pFileBuffer == nullptr) return false;

	bool Result = ParseData(pFileBuffer, FileSize);
	delete[] pFileBuffer;

	return Result;
}


bool CEsoLangFile::Save (const std::string Filename)
{
	CFile File;
	if (!File.Open(Filename, "wb")) return false;
	return Write(File);
}


bool CEsoLangFile::Write (CFile& File)
{
	dword Offset = 0;

	if (!File.WriteDword(m_FileId, false)) return false;
	if (!File.WriteDword(m_RecordCount, false)) return false;
	
	for (size_t i = 0; i < m_RecordCount; ++i)
	{
		lang_record_t& Record = m_Records[i];
		Record.Offset = Offset;
		
		if (!File.WriteDword(Record.Id, false)) return false;
		if (!File.WriteDword(Record.Unknown, false)) return false;
		if (!File.WriteDword(Record.Index, false)) return false;
		if (!File.WriteDword(Record.Offset, false)) return false;

		Offset += (int) Record.Text.length() + 1;
	}

	for (size_t i = 0; i < m_RecordCount; ++i)
	{
		if (!File.WriteString(m_Records[i].Text)) return false;
		if (!File.WriteChar(0)) return false;
	}

	return true;
}
