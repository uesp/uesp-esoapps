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


bool CEsoLangFile::DumpCsv (const std::string Filename)
{
	CFile File;

	if (!File.Open(Filename, "wb")) return false;

	File.Printf("ID`Unknown`Index`Offset`Text\n");

	for (size_t i = 0; i < m_Records.size(); ++i)
	{
		lang_record_t& Record = m_Records[i];

		File.Printf("%d`%d`%d`%d`%s\n", Record.Id, Record.Unknown, Record.Index, Record.Offset, Record.Text.c_str());
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
			std::replace(Temp.begin(), Temp.end(), '\x0d', '\x0a');
			Record.Text = ReplaceStrings(Temp, "\x0a", "\\n");
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