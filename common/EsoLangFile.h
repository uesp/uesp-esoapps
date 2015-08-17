#ifndef __ESOLANGFILE_H
#define __ESOLANGFILE_H


	/* Required includes */
#include "EsoCommon.h"
#include "EsoFile.h"
#include "EsoCsvFile.h"


struct lang_record_t
{
	eso::dword  Id;
	eso::dword  Unknown;
	eso::dword  Index;
	eso::dword  Offset;
	std::string Text;

	bool operator < (const lang_record_t &rhs) const
	{ 
		if (Id == rhs.Id) 
		{
			if (Unknown == rhs.Unknown) 
			{
				return (Index < rhs.Index);
			}

			return (Unknown < rhs.Unknown);
		}
		
		return (Id < rhs.Id);
	}
};


typedef std::vector<lang_record_t> CEsoLangRecords;


class CEsoLangFile 
{
protected:
	static const eso::dword TEXT_RECORD_SIZE = 0x10;

	eso::dword m_FileId;
	eso::dword m_RecordCount;

	CEsoLangRecords m_Records;

protected:
	bool ParseData (eso::byte* pData, const fpos_t Size);

	int CreateRecordsFromCSV   (const eso::CCsvFile& CsvFile, const bool UsePOSourceText);
	int CreateRecordsFromTEXT  (const std::vector<std::string>& TextFile, const std::vector<std::string>& IdFile, const bool UsePOFormat, const bool UsePOSourceText);
	int CreateRecordsFromPOCSV (const eso::CCsvFile& CsvFile, const bool UsePOSourceText);


public:
	CEsoLangFile();
	virtual ~CEsoLangFile();
	virtual void Destroy();

	bool AddEntry (uint64_t Id, const std::string Text);
	bool AddEntry (eso::dword Id, eso::dword Unknown, eso::dword Index, eso::dword Offset, const std::string Text);

	bool CreateFromCsv (const eso::CCsvFile& CsvFile, const bool UsePOFormat = false, const bool UsePOSourceText = false);
	bool CreateFromText (const std::vector<std::string>& TextFile, const std::vector<std::string>& IdFile, const bool UsePOFormat = false, const bool UsePOSourceText = false);

	bool DumpCsv (const std::string Filename, const bool UsePOFormat = false);
	bool DumpText (const std::string Filename, const bool UsePOFormat = false);
	bool DumpTextFile (eso::CFile& File, lang_record_t& Record);
	bool DumpTextId (const std::string Filename);

	eso::dword GetNumRecords () const { return m_RecordCount; }
	lang_record_t& GetRecord(eso::dword i) { return m_Records[i]; }

	void SortRecords (void);

	bool Load (const std::string Filename);
	bool Read (eso::CFile& File);

	bool Save (const std::string Filename);
	bool Write (eso::CFile& File);
};



#endif