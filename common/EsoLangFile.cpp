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


bool CEsoLangFile::CreateFromCsv (const eso::CCsvFile& CsvFile)
{
	int RowCount = 0;
	int RecordCount = 0;

	Destroy();

	m_Records.clear();
	m_RecordCount = CsvFile.GetNumDataRows();
	m_Records.reserve(m_RecordCount + 100);
	m_Records.resize(m_RecordCount);

	size_t StartTextOffset = m_RecordCount*TEXT_RECORD_SIZE + 8;

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
		Record.Text    = ReplaceStrings(ReplaceStrings(ReplaceStrings(r->at(4), "\\n", "\x0a"), "\\r", "\x0d"), "\\\"", "\"");

		++RecordCount;
	}

	if (m_RecordCount != RecordCount)
	{
		PrintError("Warning: Expected %d language records from CSV but only found %d!", m_RecordCount, RecordCount);
		m_RecordCount = RecordCount;
		m_Records.resize(m_RecordCount);
	}
	else
	{
		PrintError("Found %d language records from CSV data...", m_RecordCount);
	}

	return true;
}


bool CEsoLangFile::DumpCsv (const std::string Filename)
{
	CFile File;

	if (!File.Open(Filename, "wb")) return false;

	File.Printf("\"ID\",\"Unknown\",\"Index\",\"Offset\",\"Text\"\n");

	for (size_t i = 0; i < m_Records.size(); ++i)
	{
		lang_record_t& Record = m_Records[i];

		File.Printf("\"%d\",\"%d\",\"%d\",\"%d\",\"", Record.Id, Record.Unknown, Record.Index, Record.Offset);
		DumpTextFile(File, Record);
		File.Printf("\"\n");
	}

	return true;
}


bool CEsoLangFile::DumpTextFile (CFile& File, lang_record_t& Record)
{
	const char* pText = Record.Text.c_str();

	while (*pText)
	{
		if (*pText == '"')
			File.Printf("\\\"");
		else
			File.WriteChar(*pText);
	
		++pText;
	}

	return true;
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

	if (m_RecordCount > INT_MAX/TEXT_RECORD_SIZE - 100) return PrintError ("Error: Too many records found in language file!");

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

		size_t TextOffset = Record.Offset + StartTextOffset;

		if (TextOffset < Size)
		{
			std::string Temp = ParseBufferString(pData, TextOffset, (size_t)Size);
			//std::replace(Temp.begin(), Temp.end(), '\x0d', '\x0a');
			Record.Text = ReplaceStrings(ReplaceStrings(Temp, "\x0d", "\\r"), "\x0a", "\\n");
		}
		else
			PrintLog("Warning: Read passed end of file (offset 0x%08X) in text record #%d", TextOffset, i);
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

		Offset += Record.Text.length() + 1;
	}

	for (size_t i = 0; i < m_RecordCount; ++i)
	{
		if (!File.WriteString(m_Records[i].Text)) return false;
		if (!File.WriteChar(0)) return false;
	}

	return true;
}
