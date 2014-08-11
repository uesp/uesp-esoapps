#ifndef __ESOLANGFILE_H
#define __ESOLANGFILE_H


	/* Required includes */
#include "EsoCommon.h"
#include "EsoFile.h"


struct lang_record_t
{
	eso::dword  Id;
	eso::dword  Unknown;
	eso::dword  Index;
	eso::dword  Offset;
	std::string Text;
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

public:
	CEsoLangFile();
	virtual ~CEsoLangFile();
	virtual void Destroy();

	bool DumpCsv (const std::string Filename);

	bool Load (const std::string Filename);
	bool Read (eso::CFile& File);
};



#endif