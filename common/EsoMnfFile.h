#ifndef __ESOMNFFILE_H
#define __ESOMNFFILE_H


#include "EsoMnfBlock.h"
#include "EsoDatFile.h"
#include "EsoZosftFile.h"
#include "EsoSubFile.h"
#include <vector>


namespace eso {

	const size_t MNF_HEADER_MAGICSIZE = 4;
	const size_t MNF_HEADER_SIZE = 0x0F;
	const size_t MNF_BLOCK1_RECORDSIZE = 4;
	const size_t MNF_BLOCK2_RECORDSIZE = 8;
	const size_t MNF_BLOCK3_RECORDSIZE = 20;

	//const dword MNF_GAMEZOSFT_HASH = 0xF969BEE8;  //Jan Beta
	//const dword MNF_GAMEZOSFT_HASH = 0xA16BBD50;	//Feb Beta
	//const dword MNF_GAMEZOSFT_HASH = 0x3001A8A2;	//Mar Beta
	const dword MNF_GAMEZOSFT_HASH = 0x201F2232;	//May 20, 2014

	//const dword MNF_ESOZOSFT_HASH  = 0xF4FD2ECD;	//Jan Beta
	//const dword MNF_ESOZOSFT_HASH  = 0x4C99266E;	//Feb Beta
	//const dword MNF_ESOZOSFT_HASH  = 0x8F2034EC;	//Mar Beta
	const dword MNF_ESOZOSFT_HASH  = 0x7950A6A0;	//May 20, 2014

	const byte MNF_MAGIC_ID[] = "MES2";


	struct mnf_exportoptions_t
	{
		std::string MnfFilename;
		std::string OutputPath;
		std::string MnfOutputFileTable;
		std::string ZosOutputFileTable;
		std::string LangFilename;
		std::string CreateLangFilename;
		std::string OutputFilename;
		std::string ImportIdFilename;
		std::string DiffLangFilename1;
		std::string DiffLangFilename2;
		std::string OrigLangFilename;
		std::string IdFilename1;
		std::string IdFilename2;
		std::string ExtractSubFileDataType;
		std::string ExtractFilename;
		std::string ExtractFileExtension;
		std::string LuaFileList;
		std::string MatchFilename;
		std::string BaseLangFilename;
		int MnfStartIndex;
		int MnfEndIndex;
		int ArchiveIndex;
		int MnfFileIndex;
		int BeginArchiveIndex;
		int LuaStartIndex;
		bool ConvertDDS;
		bool SkipSubFiles;
		bool UsePOCSVFormat;
		bool UsePOSourceText;
		bool UseLangText;
		bool NoParseGR2;
		bool OodleRawOutput;
		bool NoRiffConvert;

		mnf_exportoptions_t() :
					MnfStartIndex(-1), 
					MnfEndIndex(-1),
					ArchiveIndex(-1),
					MnfFileIndex(-1),
					BeginArchiveIndex(-1),
					ConvertDDS(false),
					SkipSubFiles(false),
					UsePOCSVFormat(false),
					UsePOSourceText(false),
					UseLangText(false),
					ExtractSubFileDataType("none"),
					NoParseGR2(false),
					OodleRawOutput(false),
					NoRiffConvert(false)
		{
		}

	};

	typedef std::vector<word> mnf_filetypes_t;


	struct mnf_header_t
	{
		byte	FileID[MNF_HEADER_MAGICSIZE];
		word	Version;
		dword	FileCount;
		dword	Type;
		dword	DataSize;

		mnf_filetypes_t FileTypes;

		word    Unknown1;
	};


	struct mnf_filetable_t
	{
		dword	Index;
		dword	ID1;	
		dword	FileIndex;
		dword	Unknown1;
		dword	Size;
		dword	CompressedSize;
		dword	Hash;
		dword	Offset;
		byte	CompressType;
		byte	ArchiveIndex;
		word	Unknown2;	

		zosft_filetable_t*	pZosftEntry;

		mnf_filetable_t() : pZosftEntry(nullptr) { };
	};


	typedef std::vector<mnf_filetable_t> CMnfFileTableArray;
	typedef std::unordered_map<dword, mnf_filetable_t*> CMnfFileHashMap;
	typedef std::unordered_map<dword, mnf_filetable_t*> CMnfFileIndexMap;
	typedef std::unordered_map<std::string, dword> CMnfDuplicateMap;


	class CMnfFile
	{
	protected:
		std::string		m_Filename;

		mnf_header_t	m_Header;

		CMnfBlock0		m_Block0;
		bool			m_HasBlock0;
		CMnfBlock3		m_Block3;

		CMnfFileTableArray	m_FileTable;
		CMnfFileHashMap     m_FileHashMap;
		CMnfFileIndexMap    m_FileIndexMap;
		CMnfFileIndexMap	m_FileInternalIndexMap;
		CMnfDuplicateMap	m_DuplicateNameMap;

		bool				m_DecompressOodle;

		std::string		m_Ww2OggPackedBinFilename;


	protected:
		std::string CreateDataFilename(const byte ArchiveIndex);

		bool CreateFileTable (void);
		bool CreateFileMaps  (void);
		bool CreateDuplicateMap (CZosftFile& ZosftFile);

		bool ConvertRiffFile(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo);
		bool ConvertRiffFileToOgg(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo);
		bool ConvertRiffFileToWav(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo);

		bool DumpFileTable (const char* pFilename, CMnfFileTableArray& FileTable);

		bool ParseDataFileVer3(mnf_filetable_t& FileEntry, dat_subfileinfo_t& DataInfo);

		bool ReadDataFile(mnf_filetable_t& FileEntry, dat_subfileinfo_t& OutputDataInfo, CFile* pFile = nullptr);

		bool ReadHeader (CBaseFile& File);
		bool ReadHeaderVersion3(CBaseFile& File);
		bool ReadBlocks (CBaseFile& File);

		bool SaveSubFileZosft(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo);
		bool SaveSubFileGR2(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo);
		bool SaveSubFileXV4(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo);
		bool SaveSubFile (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS = false, CFile* pFile = nullptr, const std::string ExtractSubFileDataType = "none", const bool NoExtractGR2 = false, const std::string ExtractFileExtension = "", const bool NoConvertRiff = false, const std::string MatchFilename = "");
		bool ExtractSubFileDataCombined(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo);
		bool ExtractSubFileDataSeperate(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo);


	public:
		CMnfFile();
		~CMnfFile();
		void Destroy();

		bool DumpFileTable (const char* pFilename);

		bool Export (const mnf_exportoptions_t ExportOptions);

		bool ExportLuaFileList(const mnf_exportoptions_t ExportOptions);

		bool ExtractSpecificFile(std::string Filename, mnf_exportoptions_t ExportOptions);
		
		bool FindZosftHash (dword& ZosftHash);

		bool HasFileHash (const dword Hash) { return m_FileHashMap.find(Hash) != m_FileHashMap.end(); }

		bool LoadZosft (const dword Hash, CZosftFile& ZosftFile);
		bool LinkToZosft (CZosftFile& ZosftFile);

		bool Load (const char* pFilename);
		bool Load (CBaseFile& File);

		bool SaveBlock (const size_t BlockType, const size_t Index, const char* pFilename);

		bool SaveSubFiles     (const std::string BasePath, const bool ConvertDDS = false, const size_t StartIndex = 0);
		bool SaveSubFilesFast (const std::string BasePath, const bool ConvertDDS = false, const size_t StartIndex = 0);
		bool SaveSubFiles     (const mnf_exportoptions_t ExportOptions);
		bool SaveSubFile      (const size_t FileIndex, const mnf_exportoptions_t ExportOptions);
		
	};


};


#endif