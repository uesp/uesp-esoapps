#include "EsoCsvFile.h"

namespace eso 
{

	void CCsvFile::Dump (void)
	{
		int RowCount = 0;

		printf("CSV has %d rows...\n", m_Data.size());

		for (auto r = m_Data.begin(); r != m_Data.end(); ++r)
		{
			printf ("%d: ", RowCount);
			++RowCount;

			for (auto c = r->begin(); c != r->end(); ++c)
			{
				printf("%s, ", c->c_str());
			}

			printf("\n");
		}
	}


	bool CCsvFile::Load (const std::string Filename)
	{
		CFile File;
		fpos_t FileSize;

		m_Data.clear();

		byte* pFileData = File.ReadAll(Filename.c_str(), FileSize);
		if (pFileData == nullptr) return false;
	
		bool Result = Parse((char *) pFileData);
		delete pFileData;

		return Result;
	}


	bool CCsvFile::Parse (const char* pData)
	{
		const char* pStart = pData;
		const char* pEnd = nullptr;
		const char* pParse = pData;
		bool SaveCell = false;
		bool NewRow = true;
		bool LastQuote = false;
		char QuoteChar = 0;
		int ColCount = 0;
		int RowCount = 0;
		csvrow_t* pCurrentRow = nullptr;

		while (true)
		{

			switch (*pParse)
			{
			case '\\':
				if (QuoteChar != 0) LastQuote = true;
				break;

			case '\r':

				if (QuoteChar == 0)
				{
					if (pEnd == nullptr) pEnd = pParse;
				}

				LastQuote = false;
				break;

			case '\n':

				if (QuoteChar == 0)
				{
					RowCount = 0;
					++ColCount;
					SaveCell = true;
					NewRow = true;
					if (pEnd == nullptr) pEnd = pParse;
				}

				LastQuote = false;
				break;

			case ',':

				if (QuoteChar == 0)
				{
					++RowCount;
					SaveCell = true;
					if (pEnd == nullptr) pEnd = pParse;
				}

				LastQuote = false;
				break;

			case '"':

				if (QuoteChar != 0 && pParse[1] == '"' && !LastQuote)
				{
					++pParse;
				}
				else if (QuoteChar != 0 && !LastQuote)
				{
					QuoteChar = 0;
					pEnd = pParse;
				}
				else if (QuoteChar == 0)
				{
					QuoteChar = *pParse;
					pStart = pParse + 1;
				}

				LastQuote = false;
				break;

			case 0:
				if (pEnd == nullptr) pEnd = pParse;
				SaveCell = true;
				LastQuote = false;
				break;

			default:
				LastQuote = false;
				break;
			}

			if (SaveCell)
			{
				if (pEnd <= pStart && *pParse == 0) break;

				if (pCurrentRow == nullptr) 
				{
					m_Data.push_back(csvrow_t());
					pCurrentRow = &m_Data.back();
				}

				if (pStart == pEnd)
					pCurrentRow->push_back(csvcell_t(""));
				else
					pCurrentRow->push_back(csvcell_t(pStart, pEnd));

				pStart = pParse + 1;
				pEnd = nullptr;
				SaveCell = false;
			}

			if (NewRow)
			{
				pCurrentRow = nullptr;
				NewRow = false;
			}

			if (*pParse == 0) break;
			++pParse;
		}

		return true;
	}


	bool CCsvFile::Save (const std::string Filename)
	{
		CFile File;

		if (!File.Open(Filename, "wb")) return false;

		for (auto r = m_Data.begin(); r != m_Data.end(); ++r)
		{

			for (auto c = r->begin(); c != r->end(); ++c)
			{
				if (c != r->begin()) {
					if (!File.WriteChar(',')) return false;
				}
				if (!File.Printf("\"%s\"",c->c_str())) return false;
			}

			if (!File.WriteChar('\n')) return false;
		}

		return true;
	}


	void CCsvFile::ReplaceStrings(const std::string Src, const std::string Dest)
	{
		for (auto r = m_Data.begin(); r != m_Data.end(); ++r)
		{
			for (auto c = r->begin(); c != r->end(); ++c)
			{
				(*c) = eso::ReplaceStrings(*c, Src, Dest);
			}
		}
	}


};