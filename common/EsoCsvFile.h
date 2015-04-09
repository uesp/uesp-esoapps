#ifndef __ESOCSVFILE_H
#define __ESOCSVFILE_H


#include "EsoFile.h"
#include <vector>
#include <string>


namespace eso
{
	class CCsvFile 
	{
	protected:
		typedef std::string csvcell_t;
		typedef std::vector<csvcell_t> csvrow_t;

		std::vector<csvrow_t> m_Data;
		bool m_HasHeaderRow;

	public:

		CCsvFile() : m_HasHeaderRow(false) { }
		CCsvFile(bool HasHeaderRow) : m_HasHeaderRow(HasHeaderRow) { }

		const std::vector<csvrow_t>& GetData (void) const { return m_Data; }

		int GetNumRows (void) const { return m_Data.size(); }
		int GetNumDataRows (void) const { return m_Data.size() <= 0 ? m_Data.size() : (m_HasHeaderRow ? m_Data.size() - 1 : m_Data.size()); }
		bool HasHeaderRow (void) const { return m_HasHeaderRow; }

		void Dump (void);

		bool Load (const std::string Filename);
		bool Parse (const char* pData);

		bool Save (const std::string Filename);

		void ReplaceStrings (const std::string Src, const std::string Dest);
		
	};

};


#endif

