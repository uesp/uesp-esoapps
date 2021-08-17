#ifndef __ESOZOSFTFILE_H
#define __ESOZOSFTFILE_H


	/* Required include files */
#include "EsoCommon.h"
#include "EsoMnfBlock.h"


namespace eso {

	const size_t ZOSFT_HEADER_MAGICSIZE = 5;
	const size_t ZOSFT_FOOTER_MAGICSIZE = 5;
	const size_t ZOSFT_HEADER_SIZE = 0x13;

	const size_t ZOSFT_BLOCK_COUNT = 0x3;

	const byte ZOSFT_MAGIC_ID[] = "ZOSFT";

	typedef std::vector<std::string> CZosftFileArray;


	struct zosft_filetable_t
	{
		dword		Index;
		dword		Index11;
		dword		Index13;
		dword		Index21;
		dword		FileIndex;
		dword		FilenameOffset;
		dword64		FileID;
		std::string Filename;

		dword		UserData;	/* Extra data */
	};


	struct zosft_header_t
	{
		byte	FileID[ZOSFT_HEADER_MAGICSIZE];
		word	Unknown1;
		dword	Unknown2;
		dword	Unknown3;
		dword	RecordCount;
	};

	typedef std::vector<zosft_filetable_t> CZosftFileTableArray;
	typedef std::unordered_map<dword, zosft_filetable_t*> CZosftFileIndexMap;


	class CZosftFile 
	{
		dword			m_MnfVersion;
		zosft_header_t	m_Header;

		CZosftFileArray	m_Filenames;
		dword			m_RawFileDataSize;
		byte*			m_pRawFileData;

		CMnfBlock3		m_Blocks[ZOSFT_BLOCK_COUNT];
		
		byte			m_Footer[ZOSFT_FOOTER_MAGICSIZE];

		CZosftFileTableArray	m_FileTable;
		CZosftFileIndexMap		m_FileIndexMap;


	protected:

		bool CreateFileTable (void);
		bool CreateFileMaps  (void);

		bool ReadHeader    (CBaseFile& File);
		bool ReadBlockData (CBaseFile& File);
		bool ReadFileData  (CBaseFile& File);
		bool ReadFooter    (CBaseFile& File);

		void SplitRawFileData ();

		void TestCount80 (const size_t BlockIndex, const size_t Index);


	public:

		CZosftFile(const dword MnfVersion);
		~CZosftFile();
		void Destroy ();

		void CheckBlockFormats (void);

		bool DumpFileTable (const char* pFilename);

		size_t GetSize() { return m_FileTable.size(); }

		zosft_filetable_t* LookupIndex (dword FileIndex);

		bool Load (CBaseFile& File);
		bool Load (const char* pFilename);

		bool SaveBlock (const size_t BlockIndex, const size_t Index, const char* pFilename);

	};

};



#endif
