


#include "EsoMnfFile.h"
#include "EsoLangFile.h"
#include "granny/granny211.h"
#include <Windows.h>  
#include <exception>  
#include <inttypes.h>
#include "oodle/oodle.h"
#include <iostream>
#include <fstream>
#include <cstring>
#include "src/wwriff.h"
#include "stdint.h"
#include "errors.h"


namespace eso {

	typedef granny_file GrannyFile_t;
	typedef granny_file_info FileInfo_t;


	CMnfFile::CMnfFile() :
		m_HasBlock0(false),
		m_Block0(false, false),
		m_Block3(false, false),
		m_DecompressOodle(true),
		m_ZosftFile(0)
	{
		memcpy(m_Header.FileID, MNF_MAGIC_ID, MNF_HEADER_MAGICSIZE);
		m_Header.DataSize = 0;
		m_Header.FileCount = 0;
		m_Header.Version = 2;
		m_Header.Type = 1;

		char path[MAX_PATH + 4];
		GetModuleFileName(NULL, path, MAX_PATH);

		m_Ww2OggPackedBinFilename = ExtractPath(path) + "packed_codebooks_aoTuV_603.bin";
	}


	CMnfFile::~CMnfFile()
	{
		Destroy();
	}


	void CMnfFile::Destroy()
	{
		m_Filename.clear();

		m_FileTable.clear();
		m_FileHashMap.clear();
		m_FileIndexMap.clear();
		m_FileInternalIndexMap.clear();

		m_Block0.Destroy();
		m_Block3.Destroy();

		m_HasBlock0 = false;
		m_Header.DataSize = 0;
		m_Header.FileCount = 0;
	}


	bool CMnfFile::CreateFileTable(void)
	{
		mnf_filetable_t  TableEntry;
		mnf_block_data_t* pData1 = m_Block3.GetData(0);
		mnf_block_data_t* pData2 = m_Block3.GetData(1);
		mnf_block_data_t* pData3 = m_Block3.GetData(2);
		size_t Offset1 = 0;
		size_t Offset2 = 0;
		size_t Offset3 = 0;

		if (pData1 == nullptr || pData2 == nullptr || pData3 == nullptr ||
			pData1->pUncompressedData == nullptr || pData2->pUncompressedData == nullptr || pData3->pUncompressedData == nullptr)
		{
			return PrintError("Error: Missing one or more block data(s) required to create MNF file table!");
		}

		double StartTime = GetTimerMS();
		PrintLog("Creating MNF file table....");

		if (pData1->UncompressedSize % MNF_BLOCK1_RECORDSIZE != 0) PrintLog("Warning: MNF Block1 (%d bytes) is not an even multiple of the record size %d!", pData1->UncompressedSize, MNF_BLOCK1_RECORDSIZE);
		if (pData2->UncompressedSize % MNF_BLOCK2_RECORDSIZE != 0) PrintLog("Warning: MNF Block2 (%d bytes) is not an even multiple of the record size %d!", pData2->UncompressedSize, MNF_BLOCK2_RECORDSIZE);
		if (pData3->UncompressedSize % MNF_BLOCK3_RECORDSIZE != 0) PrintLog("Warning: MNF Block3 (%d bytes) is not an even multiple of the record size %d!", pData3->UncompressedSize, MNF_BLOCK3_RECORDSIZE);

		for (size_t i = 0; i < m_Block3.GetHeader().RecordCount23; ++i)
		{
			TableEntry.Index = (dword)i;

			if (Offset1 + MNF_BLOCK1_RECORDSIZE <= pData1->UncompressedSize)
			{
				TableEntry.ID1 = *((dword *)(pData1->pUncompressedData + Offset1));

				do
				{
					Offset1 += MNF_BLOCK1_RECORDSIZE;
				} while (Offset1 + MNF_BLOCK1_RECORDSIZE <= pData1->UncompressedSize && pData1->pUncompressedData[Offset1 + 3] != 0x80);
			}
			else
			{
				TableEntry.ID1 = 0;
			}

			if (Offset2 + MNF_BLOCK2_RECORDSIZE <= pData2->UncompressedSize)
			{
				TableEntry.FileIndex = *((dword *)(pData2->pUncompressedData + Offset2 + 0));
				TableEntry.Unknown1 = *((dword *)(pData2->pUncompressedData + Offset2 + 4));
				Offset2 += MNF_BLOCK2_RECORDSIZE;
			}
			else
			{
				TableEntry.FileIndex = 0;
				TableEntry.Unknown1 = 0;
			}

			if (Offset3 + MNF_BLOCK3_RECORDSIZE <= pData3->UncompressedSize)
			{
				TableEntry.Size = *((dword *)(pData3->pUncompressedData + Offset3 + 0));
				TableEntry.CompressedSize = *((dword *)(pData3->pUncompressedData + Offset3 + 4));
				TableEntry.Hash = *((dword *)(pData3->pUncompressedData + Offset3 + 8));
				TableEntry.Offset = *((dword *)(pData3->pUncompressedData + Offset3 + 12));
				TableEntry.CompressType = pData3->pUncompressedData[Offset3 + 16];
				TableEntry.ArchiveIndex = pData3->pUncompressedData[Offset3 + 17];
				TableEntry.Unknown2 = *((word  *)(pData3->pUncompressedData + Offset3 + 18));
				Offset3 += MNF_BLOCK3_RECORDSIZE;

				if (m_Header.Version >= 3)
				{
					byte tmp = TableEntry.CompressType;
					TableEntry.CompressType = TableEntry.ArchiveIndex;
					TableEntry.ArchiveIndex = tmp;
				}
			}
			else
			{
				TableEntry.Size = 0;
				TableEntry.CompressedSize = 0;
				TableEntry.Hash = 0;
				TableEntry.Offset = 0;
				TableEntry.CompressType = 0;
				TableEntry.ArchiveIndex = 0;
				TableEntry.Unknown2 = 0;
			}

			m_FileTable.push_back(TableEntry);
		}

		if (pData1->UncompressedSize != Offset1) PrintLog("Warning: Did not fully parse MNF Block1: only %d of %d bytes read!", Offset1, pData1->UncompressedSize);
		if (pData2->UncompressedSize != Offset2) PrintLog("Warning: Did not fully parse MNF Block2: only %d of %d bytes read!", Offset2, pData2->UncompressedSize);
		if (pData3->UncompressedSize != Offset3) PrintLog("Warning: Did not fully parse MNF Block3: only %d of %d bytes read!", Offset3, pData3->UncompressedSize);

		if (!CreateFileMaps()) return false;

		double EndTime = GetTimerMS();
		PrintLog("MNF filetable filled with %d entries in %g ms!", m_FileTable.size(), EndTime - StartTime);

		return true;
	}


	bool CMnfFile::CreateFileMaps(void)
	{
		m_FileHashMap.clear();
		m_FileIndexMap.clear();
		m_FileInternalIndexMap.clear();

		m_FileHashMap.reserve(m_FileTable.size());
		m_FileIndexMap.reserve(m_FileTable.size());
		m_FileInternalIndexMap.reserve(m_FileTable.size());

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			m_FileHashMap[m_FileTable[i].Hash] = &m_FileTable[i];
			m_FileIndexMap[m_FileTable[i].FileIndex] = &m_FileTable[i];
			m_FileInternalIndexMap[m_FileTable[i].Index] = &m_FileTable[i];
		}

		return true;
	}


	bool CMnfFile::CreateDuplicateMap(CZosftFile& ZosftFile)
	{
		m_DuplicateNameMap.reserve(ZosftFile.GetSize());

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			zosft_filetable_t* pZosftEntry = m_FileTable[i].pZosftEntry;
			if (pZosftEntry == nullptr) continue;
			if (pZosftEntry->UserData <= 1) continue;

			dword Index = m_FileTable[i].Index;

			if (m_DuplicateNameMap[pZosftEntry->Filename] < Index)
			{
				m_DuplicateNameMap[pZosftEntry->Filename] = Index;
			}
		}

		return true;
	}


	bool CMnfFile::DumpFileTable(const char* pFilename)
	{
		return DumpFileTable(pFilename, m_FileTable);
	}


	bool CMnfFile::DumpFileTable(const char* pFilename, CMnfFileTableArray& FileTable)
	{
		CFile File;
		std::string OutputPath = ExtractPath(pFilename);

		if (!EnsurePathExists(OutputPath)) return false;
		if (!File.Open(pFilename, "wb")) return false;

		File.Printf(" Index ,    ID1    , FileIndex ,   Unk1    ,    Size   ,   ZSize   ,    Hash   ,   Offset  , ZTyp, Arch,  Unk2 , Filename\n");

		for (size_t i = 0; i < FileTable.size(); ++i)
		{
			mnf_filetable_t& Entry = FileTable[i];
			File.Printf("%7d, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%02X, 0x%02X, 0x%04X, %s\n",
				Entry.Index, Entry.ID1, Entry.FileIndex, Entry.Unknown1, Entry.Size, Entry.CompressedSize, Entry.Hash, Entry.Offset, Entry.CompressType, Entry.ArchiveIndex, Entry.Unknown2,
				Entry.pZosftEntry ? Entry.pZosftEntry->Filename.c_str() : "");
		}

		return true;
	}


	bool CMnfFile::FindZosftHash(dword& ZosftHash)
	{
		bool CheckEso = true;
		bool CheckGame = true;

		if (StringEndsWith(m_Filename, "eso.mnf"))
		{
			CheckEso = true;
			CheckGame = false;
		}
		else if (StringEndsWith(m_Filename, "game.mnf"))
		{
			CheckEso = false;
			CheckGame = true;
		}

		if (CheckEso)
		{
			if (m_FileIndexMap.find(0x00FFFFFF) != m_FileIndexMap.end()) { ZosftHash = m_FileIndexMap[0x00FFFFFF]->Hash; return true; }
			if (m_FileIndexMap.find(0xFFFFF) != m_FileIndexMap.end()) { ZosftHash = m_FileIndexMap[0xFFFFF]->Hash; return true; }

			if (HasFileHash(MNF_ESOZOSFT_HASH)) { ZosftHash = MNF_ESOZOSFT_HASH; return true; }
			if (HasFileHash(0xF4FD2ECD)) { ZosftHash = 0xF4FD2ECD; return true; }
			if (HasFileHash(0x4C99266E)) { ZosftHash = 0x4C99266E; return true; }
			if (HasFileHash(0x8F2034EC)) { ZosftHash = 0x8F2034EC; return true; }
			if (HasFileHash(0x8F2034EC)) { ZosftHash = 0x8F2034EC; return true; }
		}

		if (CheckGame)
		{
			if (m_FileIndexMap.find(0) != m_FileIndexMap.end()) { ZosftHash = m_FileIndexMap[0]->Hash; return true; }

			if (HasFileHash(MNF_GAMEZOSFT_HASH)) { ZosftHash = MNF_GAMEZOSFT_HASH; return true; }
			if (HasFileHash(0xF969BEE8)) { ZosftHash = 0xF969BEE8; return true; }
			if (HasFileHash(0xA16BBD50)) { ZosftHash = 0xA16BBD50; return true; }
			if (HasFileHash(0x3001A8A2)) { ZosftHash = 0x3001A8A2; return true; }
		}

		return false;
	}


	bool CMnfFile::LoadZosft()
	{
		m_ZosftFile.Destroy();
		m_ZosftFile.SetVersion(m_Header.Version);

		dword ZosftHash = 0;

		if (!FindZosftHash(ZosftHash))
		{
			return PrintError("ERROR: Failed to find the ZOSFT entry in the MNF file!");
		}
		else if (!LoadZosft(ZosftHash, m_ZosftFile))
		{
			return PrintError("Failed to load the ZOSFT data from MNF file data!\nFiles will be exported but without any filenames set.");
		}
		
		return true;
	}
	

	bool CMnfFile::Export (const mnf_exportoptions_t ExportOptions)
	{
		PrintError("Loading MNF file '%s'...", ExportOptions.MnfFilename.c_str());

		m_DecompressOodle = !ExportOptions.OodleRawOutput;

		if (!Load(ExportOptions.MnfFilename.c_str()))
		{
			PrintError("Failed to load MNF file '%s'...aborting!", ExportOptions.MnfFilename.c_str());
			return false;
		}

		CZosftFile ZosftFile(m_Header.Version);

		PrintError("Trying to find and load ZOSFT entry from MNF file!");

		dword ZosftHash = 0;
				
		if (!FindZosftHash(ZosftHash))
		{
			PrintError("ERROR: Failed to find the ZOSFT entry in the MNF file!");
		}
		else if (!LoadZosft(ZosftHash, ZosftFile))
		{
			PrintError("Failed to load the ZOSFT data from MNF file data!\nFiles will be exported but without any filenames set.");
		}
		else 
		{
			PrintError("Successfully loaded the ZOSFT entry for MNF file!");
		}

		if (!ExportOptions.MnfOutputFileTable.empty())
		{
			if (!DumpFileTable(ExportOptions.MnfOutputFileTable.c_str())) PrintError("Failed to dump the MNF filetable to a text file!");
			PrintError("Saved the MNF filetable to %s!", ExportOptions.MnfOutputFileTable.c_str());
		}

		if (!ExportOptions.ZosOutputFileTable.empty())
		{
			if (!ZosftFile.DumpFileTable(ExportOptions.ZosOutputFileTable.c_str())) PrintError("Failed to dump the ZOS filetable to a text file!");
			PrintError("Saved the ZOSFT to %s!", ExportOptions.ZosOutputFileTable.c_str());
		}

		if (ExportOptions.LuaFileList != "") 
		{
			return ExportLuaFileList(ExportOptions);
		}

		if (ExportOptions.SkipSubFiles)
		{
			PrintError("Skipping extraction of subfile data....\n");
			return true;
		}

		if (!ExportOptions.ExtractFilename.empty()) return ExtractSpecificFile(ExportOptions.ExtractFilename, ExportOptions);

		if (ExportOptions.MnfFileIndex > 0) return SaveSubFile(ExportOptions.MnfFileIndex, ExportOptions);
		return SaveSubFiles(ExportOptions);
	}


	bool CMnfFile::ExportLuaFileList(const mnf_exportoptions_t ExportOptions)
	{
		CFile LuaFile;
		int fileIndex = ExportOptions.LuaStartIndex;

		PrintError("Saving list of files to LUA file '%s'...\n", ExportOptions.LuaFileList.c_str());

		if (ExportOptions.ExtractFileExtension != "")
		{
			PrintError("Only outputting files with extension of '%s'...\n", ExportOptions.ExtractFileExtension.c_str());
		}

		if (ExportOptions.MatchFilename != "")
		{
			PrintError("Only outputting files containing the substring of '%s'...\n", ExportOptions.MatchFilename.c_str());
		}

		if (!LuaFile.Open(ExportOptions.LuaFileList.c_str(), "wb")) return false;
		
		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			mnf_filetable_t &FileEntry = m_FileTable[i];

			if (FileEntry.pZosftEntry == nullptr) continue;

			if (ExportOptions.ExtractFileExtension != "") 
			{
				if (!StringEndsWith(FileEntry.pZosftEntry->Filename, ExportOptions.ExtractFileExtension)) continue;
			}

			if (ExportOptions.MatchFilename != "")
			{
				if (FileEntry.pZosftEntry->Filename.find(ExportOptions.MatchFilename) == std::string::npos) continue;
			}

			std::string modString = FileEntry.pZosftEntry->Filename;
			std::replace(modString.begin(), modString.end(), '\\', '/');

			LuaFile.Printf("\t[%d] = \"%s\",\n", fileIndex, modString.c_str());
			++fileIndex;
		}

		return true;
	}


	bool CMnfFile::ExtractSpecificFile(std::string Filename, mnf_exportoptions_t ExportOptions)
	{
		bool Result = true;

		std::transform(Filename.begin(), Filename.end(), Filename.begin(), ::tolower);
		PrintError("Extracting any filename matching '%s'...", Filename.c_str());

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			mnf_filetable_t &FileEntry = m_FileTable[i];
			std::string SubFilenameNoExt;
			std::string SubFilename;
			std::string SubFilenameFull;

			if (FileEntry.pZosftEntry != nullptr && !FileEntry.pZosftEntry->Filename.empty())
			{
				SubFilenameFull = FileEntry.pZosftEntry->Filename;
				std::transform(SubFilenameFull.begin(), SubFilenameFull.end(), SubFilenameFull.begin(), ::tolower);

				SubFilename = SubFilenameFull;
				size_t last_slash_idx = SubFilename.find_last_of("\\/");
				if (std::string::npos != last_slash_idx) SubFilename.erase(0, last_slash_idx + 1);

				SubFilenameNoExt = SubFilename;
				size_t period_idx = SubFilenameNoExt.rfind('.');
				if (std::string::npos != period_idx) SubFilenameNoExt.erase(period_idx);
			}
			
			if (SubFilename == Filename || SubFilenameFull == Filename || SubFilenameNoExt == Filename || Filename == std::to_string(FileEntry.Index))
			{
				PrintError("Extracting matching subfile #%d!", FileEntry.Index, SubFilename.c_str());
				Result &= SaveSubFile(FileEntry, ExportOptions.OutputPath, ExportOptions.ConvertDDS);
			}
		}

		return Result;
	}


	bool CMnfFile::LinkToZosft (CZosftFile& ZosftFile)
	{
		size_t FoundCount = 0;
		bool IsEsoMnf = StringEndsWith(m_Filename, "eso.mnf");

		PrintLog("Looking up all MNF entries in given ZOSFT file...");

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
				/* Skip entries with a non-zero Unknown1 for ESO.mnf files */
			if (IsEsoMnf && m_FileTable[i].Unknown1 != 0) continue;

			zosft_filetable_t* pEntry = ZosftFile.LookupIndex(m_FileTable[i].FileIndex);
			
			if (pEntry)
			{
				++pEntry->UserData;
				m_FileTable[i].pZosftEntry = pEntry;
				++FoundCount;
			}
			
		}

		PrintLog("Found %u of %u MNF entries in ZSOFT file!", FoundCount, m_FileTable.size());
		return true;
	}


	bool CMnfFile::Load (const char* pFilename)
	{
		CFile File;

		if (!File.Open(pFilename, "rb")) return false;
		
		bool Result = Load(File);

		m_Filename = pFilename;

		return Result;
	}


	bool CMnfFile::Load (CBaseFile& File)
	{
		Destroy();

		double StartTime = GetTimerMS();

		if (!ReadHeader(File)) return false;
		if (!ReadBlocks(File)) return false;
		if (!CreateFileTable()) return false;

		double EndTime = GetTimerMS();
		PrintLog("Loaded MNF file in %g ms!", EndTime - StartTime);
		return true;
	}


	bool CMnfFile::LoadZosft (const dword Hash, CZosftFile& ZosftFile)
	{
		mnf_filetable_t*  pFileEntry;
		dat_subfileinfo_t DataInfo;

		DataInfo.DeletePtrs = true;
		PrintLog("Trying to load ZOSFT sub-file identified by hash 0x%08X...", Hash);

		if (m_FileHashMap.find(Hash) == m_FileHashMap.end()) return PrintError("Error: The file hash 0x%08X was not found in MNF file table!");

		pFileEntry = m_FileHashMap[Hash];
		if (pFileEntry == nullptr) return PrintError("Error: Invalid file entry in MNF hash map!");

		if (!ReadDataFile(*pFileEntry, DataInfo)) return false;

		CMemoryFile File(DataInfo.pFileDataStart, DataInfo.FileDataSize);

		if (!ZosftFile.Load(File))
		{
			PrintLog("Failed to load ZOSFT sub-file identified by hash 0x%08X!", Hash);
			return false;
		}

		LinkToZosft(ZosftFile);
		CreateDuplicateMap(ZosftFile);

		return true;
	}


	bool CMnfFile::ReadDataFile (mnf_filetable_t& FileEntry, dat_subfileinfo_t& OutputDataInfo, CFile* pFile) 
	{
		OutputDataInfo.Filename = CreateDataFilename(FileEntry.ArchiveIndex);
		OutputDataInfo.CompressType = FileEntry.CompressType;
		OutputDataInfo.ArchiveIndex = FileEntry.ArchiveIndex;
		OutputDataInfo.RawSize = FileEntry.CompressedSize;
		OutputDataInfo.UncompressedSize = FileEntry.Size;
		OutputDataInfo.Offset = FileEntry.Offset;
		OutputDataInfo.pUncompressedData = nullptr;
		OutputDataInfo.pRawData = nullptr;
				
		if (!ReadSubFileData(OutputDataInfo, m_Header, pFile)) return false;

		if (m_Header.Version >= 3) {
			ParseDataFileVer3(FileEntry, OutputDataInfo);
			return true;
		}

		return true;
	}


	bool CMnfFile::ParseDataFileVer3(mnf_filetable_t& FileEntry, dat_subfileinfo_t& DataInfo)
	{
		if (DataInfo.pFileDataStart == nullptr) return true;
		if (DataInfo.pFileDataStart[0] != 0x8C && DataInfo.pFileDataStart[0] != 0xCC) return true;
		if (DataInfo.pFileDataStart[1] != 0x06 && DataInfo.pFileDataStart[1] != 0x0A) return true;

		if (!m_DecompressOodle) return true;

		byte* pOutputBuffer =  nullptr;
		int BytesDecompressed = 0;

		int OutputBufferSize = FileEntry.Size + 10000;
		pOutputBuffer = new byte[OutputBufferSize];

		BytesDecompressed = g_OodleDecompressFunc(DataInfo.pFileDataStart, DataInfo.FileDataSize, pOutputBuffer, FileEntry.Size, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3);

		if (BytesDecompressed <= 0)
		{
			delete[] pOutputBuffer;
			PrintDebug("\t%d: Warning: Failed to decompress V3 data file!", FileEntry.FileIndex);
			return false;
		}
		
		DataInfo.pOoodleCompressedData = DataInfo.pFileDataStart;
		DataInfo.OodleCompressedSize = DataInfo.FileDataSize;

		DataInfo.pOodleDecompressed = pOutputBuffer;
		DataInfo.pFileDataStart = pOutputBuffer;
		DataInfo.FileDataSize = BytesDecompressed;

		if (DataInfo.pFileDataStart[0] != 0x00 || DataInfo.pFileDataStart[1] != 0x00 || DataInfo.pFileDataStart[2] != 0x00 || DataInfo.pFileDataStart[3] != 0x00) return true;

		word HeaderOffset1 = ParseBufferWord(pOutputBuffer + 6, true) + 8;

		if (HeaderOffset1 >= BytesDecompressed) 
		{
			PrintLog("\t\tHeader Offset #1 in V3 DAT file exceeds file size (0x%04X > 0x%08X)!", (dword)HeaderOffset1, BytesDecompressed);
			return false;
		}

		dword HeaderOffset2 = ParseBufferDword(pOutputBuffer + HeaderOffset1, true) + 4 + HeaderOffset1;

		if (HeaderOffset2 >= (dword) BytesDecompressed) 
		{
			PrintLog("\t\tHeader Offset #2 in V3 DAT file exceeds file size (0x%04X > 0x%08X)!", HeaderOffset2, BytesDecompressed);
			return false;
		}

		DataInfo.pFileDataStart = pOutputBuffer + HeaderOffset2;
		DataInfo.FileDataSize = BytesDecompressed - HeaderOffset2;

		return true;
	}


		/* For now try to read an optional block 0 followed by a block 3 */
	bool CMnfFile::ReadBlocks (CBaseFile& File)
	{
		word BlockID;

		if (!File.ReadWord(BlockID, false)) return false;

		if (BlockID == 0)
		{
			m_HasBlock0 = true;
			if (!m_Block0.Read(File, false)) return false;
			if (!File.ReadWord(BlockID, false)) return false;
		}

		if (BlockID == 3)
		{
			m_HasBlock0 = false;
			if (!m_Block3.Read(File, false)) return false;
		}
		else
		{
			PrintError("Error: Found unknown block type %d in MNF file at 0x%" PRIx64 "!", (int) BlockID, File.Tell());
			return false;
		}
				
		fpos_t CurPos = File.Tell();
		fpos_t FileSize = File.GetSize();

		if (CurPos < FileSize) 
			PrintLog("Warning: Extra %lld bytes found at end of MNF file (read %lld of %lld bytes)!", FileSize - CurPos, CurPos, FileSize);
		else
			PrintLog("No bytes left over in MNF file!");

		return true;
	}


	bool CMnfFile::ReadHeader (CBaseFile& File)
	{
		if (!File.ReadBytes(m_Header.FileID, MNF_HEADER_MAGICSIZE)) return false;
		if (memcmp(m_Header.FileID, MNF_MAGIC_ID, MNF_HEADER_MAGICSIZE) != 0) PrintLog("Warning: Did not find the magic bytes of '%s' at start of MNF file!", MNF_MAGIC_ID);

		if (!File.ReadWord(m_Header.Version)) return false;

		if (m_Header.Version >= 3) return ReadHeaderVersion3(File);

		byte TempVersion = 0;
		if (!File.ReadByte(TempVersion)) return false;
		m_Header.FileCount = TempVersion;
				
		if (!File.ReadDword(m_Header.Type)) return false;
		if (!File.ReadDword(m_Header.DataSize)) return false;

		return true;
	}


	bool CMnfFile::ReadHeaderVersion3(CBaseFile& File) 
	{
		if (!File.ReadDword(m_Header.FileCount)) return false;

		if (m_Header.FileCount > 0) {
			m_Header.FileTypes.resize(m_Header.FileCount);

			for (dword i = 0; i < m_Header.FileCount; ++i) {
				word FileType;
				if (!File.ReadWord(FileType)) return false;
				m_Header.FileTypes[i] = FileType;
			}
		}

		if (!File.ReadWord(m_Header.Unknown1)) return false;
		if (!File.ReadDword(m_Header.DataSize)) return false;

		return true;
	}


	bool CMnfFile::SaveBlock (const size_t BlockType, const size_t Index, const char* pFilename)
	{
		if (BlockType == 0)
		{
			return m_Block0.SaveBlock(Index, pFilename);
		}
		else if (BlockType == 3)
		{
			return m_Block3.SaveBlock(Index, pFilename);
		}

		return PrintError("Error: Unknown block type %d!", BlockType);
	}


	bool CMnfFile::SaveSubFiles (const std::string BasePath, const bool ConvertDDS, const size_t StartIndex)
	{
		bool Result = true;
		double StartTime = GetTimerMS();

		PrintError("Saving %u sub-files referenced in MNF file to '%s'...", m_FileTable.size(), BasePath.c_str());

		for (size_t i = StartIndex; i < m_FileTable.size(); ++i)
		{
			if (i % 100 == 0) PrintError("\tSubfile %7u of %7u: %.0f%% complete...", i, m_FileTable.size(), (float)i*100.0f/(float)m_FileTable.size());
			Result &= SaveSubFile(m_FileTable[i], BasePath, ConvertDDS);
		}

		double EndTime = GetTimerMS();
		PrintLog("Exported %u sub-files in %g secs!", m_FileTable.size(), (EndTime - StartTime)*1000.0);
		return Result;
	}


	bool CMnfFile::SaveSubFileZosft (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo)
	{
		std::string OutputFilename = AppendFilenameToPath(BasePath, FileEntry.pZosftEntry->Filename);
		std::string OutputPath = RemoveFilename(OutputFilename);
		CFile File;

		if (!EnsurePathExists(OutputPath)) return false;
		
		dword ValidIndex = m_DuplicateNameMap[FileEntry.pZosftEntry->Filename];

		if (ValidIndex > 0 && FileEntry.Index != ValidIndex)
		{
			PrintDebug("\tWarning: Skipping duplicate file '%s' with index %d!", OutputFilename.c_str(), FileEntry.Index);
			return false;
		}

		if (!File.Open(OutputFilename.c_str(), "wb")) return false;
		if (!File.WriteBytes(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;
		File.Close();

		if (ConvertDDS && StringEndsWith(OutputFilename, ".dds"))
		{
			ConvertDDStoPNG(DataInfo.pFileDataStart, DataInfo.FileDataSize, OutputFilename);
		}
		else if (StringEndsWith(OutputFilename, ".lang"))
		{
			CEsoLangFile LangFile;

			if (LangFile.Load(OutputFilename))
			{
				std::string LangOutputFilename(OutputFilename);
				LangOutputFilename += ".csv";
				LangFile.DumpCsv(LangOutputFilename);
			}
		}

		return true;
	}


	bool CMnfFile::ExtractSubFileDataCombined (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo)
	{
		CEsoSubFileDataFile SubFileData;
		CEsoSubFileIndexFile SubFileIndex;
		dat_subfileinfo_t IndexDataInfo;
				
		if (!SubFileData.Parse(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;

		if (m_FileInternalIndexMap.find(FileEntry.Index + 1) != m_FileInternalIndexMap.end())
		{
			mnf_filetable_t* pIndexFileEntry = m_FileInternalIndexMap[FileEntry.Index + 1];

			if (ReadDataFile(*pIndexFileEntry, IndexDataInfo, nullptr))
			{
				if (SubFileIndex.Parse(IndexDataInfo.pFileDataStart, IndexDataInfo.FileDataSize))
				{
					SubFileData.UpdateIndex(SubFileIndex.GetRecords());
				}
			}
		}

		std::string Filename = CreateFilename(BasePath, "%03u\\%06u%s", (dword)FileEntry.ArchiveIndex, FileEntry.Index, "_Uncompressed.EsoFileData");
		
		if (!SubFileData.SaveCombinedFile(Filename)) return false;

		return true;
	}


	bool CMnfFile::ExtractSubFileDataSeperate (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo)
	{
		CEsoSubFileDataFile SubFileData;
		CEsoSubFileIndexFile SubFileIndex;
		dat_subfileinfo_t IndexDataInfo;

		if (!SubFileData.Parse(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;

		if (m_FileInternalIndexMap.find(FileEntry.Index + 1) != m_FileInternalIndexMap.end())
		{
			mnf_filetable_t* pIndexFileEntry = m_FileInternalIndexMap[FileEntry.Index + 1];

			if (ReadDataFile(*pIndexFileEntry, IndexDataInfo, nullptr))
			{
				if (SubFileIndex.Parse(IndexDataInfo.pFileDataStart, IndexDataInfo.FileDataSize))
				{
					SubFileData.UpdateIndex(SubFileIndex.GetRecords());
				}
			}
		}

		std::string OutputPath = CreateFilename(BasePath, "%03u\\%06u\\", (dword)FileEntry.ArchiveIndex, FileEntry.Index, "");

		if (!EnsurePathExists(OutputPath)) return false;

		if (!SubFileData.SaveFiles(OutputPath)) return false;

		return true;
	}

	
	GrannyFile_t* TryLoadGrannnyFile (mnf_filetable_t& FileEntry, dat_subfileinfo_t& DataInfo)
	{
		GrannyFile_t* pGrannyFile = nullptr;

		__try
		{
			pGrannyFile = GrannyReadEntireFileFromMemory(DataInfo.FileDataSize, DataInfo.pFileDataStart);
		}
		__except (1) {
			PrintError("\tError: Expection occurred when parsing Granny file data (file %03u\\%06u.gr2)!", (dword)FileEntry.ArchiveIndex, FileEntry.Index);
			return nullptr;
		}

		return pGrannyFile;
	}


	bool CMnfFile::SaveSubFileGR2 (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo)
	{
		CFile File;
		GrannyFile_t* pGrannyFile = nullptr;

		pGrannyFile = TryLoadGrannnyFile(FileEntry, DataInfo);
		
		if (pGrannyFile == nullptr)
		{
			return PrintError("\tError: Failed to parse Granny file data (file %03u\\%06u.gr2)!", (dword)FileEntry.ArchiveIndex, FileEntry.Index);
		}

		FileInfo_t* pGrannyInfo = GrannyGetFileInfo(pGrannyFile);

		if (pGrannyInfo == nullptr)
		{
			GrannyFreeFile(pGrannyFile);
			return PrintError("\tError: Failed to get Granny file info (file %03u\\%06u.gr2)!", (dword)FileEntry.ArchiveIndex, FileEntry.Index);
		}

		std::string OrigFile = pGrannyInfo->FromFileName ? pGrannyInfo->FromFileName : "";

		// Use alternative reconstruction method if no filename is available or the filename is only numbers
		if (OrigFile == "" || std::all_of(OrigFile.begin(), OrigFile.end(), ::isdigit))
		{
			// Extract the name of the first model in the granny file
			std::string ModelName = "";
			if (pGrannyInfo->ModelCount)
			{
				ModelName = pGrannyInfo->Models[0]->Name;
			}

			// Extract the name of the first mesh in the granny file
			std::string MeshName = "";
			if (pGrannyInfo->MeshCount)
			{
				MeshName = pGrannyInfo->Meshes[0]->Name;
			}

			// Extract the name of the first animation in the granny file
			std::string AnimationName = "";
			if (pGrannyInfo->AnimationCount)
			{
				AnimationName = pGrannyInfo->Animations[0]->Name;
			}

			GrannyFreeFile(pGrannyFile);

			std::string OutputFilename = BasePath + "Granny\\Reconstructed\\";

			// if we have a model name add it to the filename
			if (ModelName != "")
			{
				OutputFilename += "Mdl_" + ModelName + "-";
			}

			// if we have a mesh name add it to the filename
			if (MeshName != "")
			{
				OutputFilename += "Msh_" + MeshName + "-";
			}

			// if we have an animation name add it to the filename
			if (AnimationName != "")
			{
				// Some AnimationNames contain the entire filepath of the animation,
				// which can cause the path length to become to large for windows.
				// Thus we only preserve the filename
				size_t last_backslash = AnimationName.find_last_of("\\");
				if (last_backslash != std::string::npos)
				{
					AnimationName.erase(0, last_backslash + 1);
				}
				OutputFilename += "Anm_" + AnimationName + "-";
			}

			// if we dont have a model, mesh or animation name we give up
			if (OutputFilename == BasePath + "Granny\\Reconstructed\\")
			{
				return PrintError("\tWarning: No original file, model, mesh or animation name found in Granny file data (file %03u\\%06u.gr2)!", (dword)FileEntry.ArchiveIndex, FileEntry.Index);
			}
			// add the numbers from the original filename to differentiate files with same model, mesh and animation names
			else if (OrigFile != "")
			{
				OutputFilename.pop_back();	// Remove last '-'
				OutputFilename += "[" + OrigFile + "]";
			}

			// some names contain '|', which are invalid in filenames
			std::replace(OutputFilename.begin(), OutputFilename.end(), '|', '_');

			OutputFilename += ".gr2";

			std::string OutputPath = RemoveFilename(OutputFilename);

			if (!EnsurePathExists(OutputPath)) return false;

			if (!File.Open(OutputFilename.c_str(), "wb")) return false;
			if (!File.WriteBytes(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;
			File.Close();

			return true;
		}

		GrannyFreeFile(pGrannyFile);
		
		size_t PathPos = OrigFile.find("\\", 0);
		if (PathPos == std::string::npos) PathPos = -1;

		std::string OutputFilename = BasePath + "Granny\\" + OrigFile.substr(PathPos + 1);
		OutputFilename = RemoveFileExtension(OutputFilename) + ".gr2";
		std::string OutputPath = RemoveFilename(OutputFilename);

		if (!EnsurePathExists(OutputPath)) return false;

		//PrintError("\tSaving GR2 file to '%s'...", OutputFilename.c_str());

		if (!File.Open(OutputFilename.c_str(), "wb")) return false;
		if (!File.WriteBytes(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;
		File.Close();

		return true;
	}


	bool CMnfFile::SaveSubFileXV4(mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, dat_subfileinfo_t& DataInfo)
	{
		std::string OutputFilename;
		std::string OutputPath;
		CFile File;

		if (DataInfo.FileDataSize <= 12) return false;

		OutputFilename = CreateFilename(BasePath, "%03u\\%06u.%s", (dword)FileEntry.ArchiveIndex, FileEntry.Index, "dds");
		OutputPath = RemoveFilename(OutputFilename);
		if (!EnsurePathExists(OutputPath)) return false;

		if (!File.Open(OutputFilename.c_str(), "wb")) return false;
		if (!File.WriteBytes(DataInfo.pFileDataStart + 12, DataInfo.FileDataSize - 12)) return false;
		File.Close();

		if (ConvertDDS)
		{
			ConvertDDStoPNG(DataInfo.pFileDataStart, DataInfo.FileDataSize, OutputFilename);
		}

		return true;
	}


	bool CMnfFile::SaveSubFile (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, CFile* pFile, const std::string ExtractSubFileDataType, const bool NoExtractGR2, const std::string ExtractFileExtension, const bool NoConvertRiff, const std::string MatchFilename)
	{
		dat_subfileinfo_t DataInfo;
		std::string OutputFilename;
		std::string OutputPath;
		CFile File;

		DataInfo.DeletePtrs = true;

		if (ExtractFileExtension != "")
		{
			if (FileEntry.pZosftEntry == nullptr) return (false);
			if (!StringEndsWith(FileEntry.pZosftEntry->Filename, ExtractFileExtension)) return (false);
		}

		if (MatchFilename != "")
		{
			if (FileEntry.pZosftEntry == nullptr) return (false);
			if (FileEntry.pZosftEntry->Filename.find(MatchFilename) == string::npos) return (false);
			//printf("\tMatched: %s, %s\n", FileEntry.pZosftEntry->Filename.c_str(), MatchFilename.c_str());
		}

		if (!ReadDataFile(FileEntry, DataInfo, pFile)) 
		{
				// Special case for the first MNF file with known data truncation issues
			if (FileEntry.ArchiveIndex == 0 && FileEntry.Index >= 880) //TODO: Hardcoded index might change
			{
				PrintDebug("\tError: Failed to load the file data from MNF %03u with file index %u (absolute index %u)!", (dword)FileEntry.ArchiveIndex, FileEntry.FileIndex, FileEntry.Index);
				return PrintError("\tWarning: Failed to load subfile %u from the end of MNF 000 due to a truncated file (this is a known issue with this file)!", FileEntry.Index);
			}
			
			return PrintError("\tError: Failed to load the file data from MNF %03u with file index %u (absolute index %u)!", (dword)FileEntry.ArchiveIndex, FileEntry.FileIndex, FileEntry.Index);
		}

		if (DataInfo.pFileDataStart == nullptr) return PrintError("\tError: No uncompressed data to write to file!");

		std::string FileExtension = GuessFileExtension((unsigned char *)DataInfo.pFileDataStart, DataInfo.FileDataSize);
		
		if (FileEntry.pZosftEntry != nullptr && !FileEntry.pZosftEntry->Filename.empty())
		{
			SaveSubFileZosft(FileEntry, BasePath, ConvertDDS, DataInfo);
		}

		if (FileExtension == "gr2" && !NoExtractGR2)
		{
			SaveSubFileGR2(FileEntry, BasePath, ConvertDDS, DataInfo);
		}
		else if (FileExtension == "EsoFileData")
		{
			if (ExtractSubFileDataType == "combined")
				ExtractSubFileDataCombined(FileEntry, BasePath, ConvertDDS, DataInfo);
			else if (ExtractSubFileDataType == "seperate")
				ExtractSubFileDataSeperate(FileEntry, BasePath, ConvertDDS, DataInfo);
		}
		else if (FileExtension == "xv4")
		{
			SaveSubFileXV4(FileEntry, BasePath, ConvertDDS, DataInfo);
		}

		OutputFilename = CreateFilename(BasePath, "%03u\\%06u.%s", (dword)FileEntry.ArchiveIndex, FileEntry.Index, FileExtension.c_str());
		OutputPath = RemoveFilename(OutputFilename);
		if (!EnsurePathExists(OutputPath)) return false;

		if (!File.Open(OutputFilename.c_str(), "wb")) return false;
		if (!File.WriteBytes(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;
		File.Close();

		if (ConvertDDS && StringEndsWith(OutputFilename, ".dds"))
		{
			ConvertDDStoPNG(DataInfo.pFileDataStart, DataInfo.FileDataSize, OutputFilename);
		}

		if (FileExtension == "riff" && !NoConvertRiff)
		{
			ConvertRiffFile(FileEntry, OutputFilename, DataInfo);
		}

		return true;
	}


	bool CMnfFile::ConvertRiffFile(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo)
	{
		eso::byte* pFileData = DataInfo.pFileDataStart;

		if (DataInfo.FileDataSize > INT_MAX)
		{
			return PrintError("RIFF filesize of %lld bytes is too large to convert!", DataInfo.FileDataSize);
		}

		if (DataInfo.FileDataSize < 72)
		{
			return PrintError("RIFF filesize of %lld bytes is too small to convert!", DataInfo.FileDataSize);
		}

		if (memcmp(DataInfo.pFileDataStart, "RIFF", 4) != 0)
		{
			return PrintError("Missing 'RIFF' file header...file is probably not a RIFF file!");
		}

		if (memcmp(DataInfo.pFileDataStart + 8, "WAVE", 4) != 0)
		{
			return PrintError("Unknown RIFF type '%4.4s' found, expecting 'WAVE'!", DataInfo.pFileDataStart + 8);
		}

		if (memcmp(DataInfo.pFileDataStart + 12, "fmt ", 4) != 0)
		{
			return PrintError("Unknown RIFF chunk '%4.4s' found, expecting 'fmt '!", DataInfo.pFileDataStart + 12);
		}

		word formatType = *(word *)(DataInfo.pFileDataStart + 20);

		if (formatType == 0xFFFF)
			return ConvertRiffFileToOgg(FileEntry, OutputFilename, DataInfo);
		else if (formatType == 0xFFFE)
			return ConvertRiffFileToWav(FileEntry, OutputFilename, DataInfo);

		return PrintError("Unknown RIFF format 0x%04X found, expecting 0xFFFE or 0xFFFF!", (dword) formatType);
	}


	bool CMnfFile::ConvertRiffFileToOgg(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo)
	{
		std::string OggFilename;

		try
		{		// This could be a little faster if we didn't reload the RIFF file for conversion

			Wwise_RIFF_Vorbis ww(OutputFilename, m_Ww2OggPackedBinFilename, false, false, kNoForcePacketFormat);

			//ww.print_info();
			//cout << "Output: " << opt.get_out_filename() << endl;

			OggFilename = OutputFilename + ".ogg";
			ofstream of(OggFilename, ios::binary);
			if (!of) throw File_open_error(OggFilename);

			ww.generate_ogg(of);
		}
		catch (const File_open_error& fe)
		{
			cout << fe << endl;
			return false;
		}
		catch (const Parse_error& pe)
		{
			cout << pe << endl;
			return false;
		}
	
		return true;
	}


	bool CMnfFile::ConvertRiffFileToWav(mnf_filetable_t& FileEntry, const std::string OutputFilename, dat_subfileinfo_t& DataInfo)
	{
		CFile File;
		std::string WavFilename;
		eso::byte* pFileData = DataInfo.pFileDataStart;
		size_t NewFileSize = 0;
		bool Result;

		NewFileSize = (size_t)DataInfo.FileDataSize + 4;

		eso::byte* pNewFileData = new eso::byte[NewFileSize + 100];

		memcpy(pNewFileData, pFileData, 72);
		//memcpy(pNewFileData + 72 + 4, pFileData + 72, (size_t)DataInfo.FileDataSize - 72);

		eso::dword RiffSize = *(dword *)(pFileData + 4);
		RiffSize += 4;
		memcpy(pNewFileData + 4, &RiffSize, 4);

		eso::dword FmtSize = *(dword *)(pFileData + 16);
		//if (FmtSize != 24) PrintLog("\tFMT size of %d", FmtSize);
		FmtSize += 0x10;
		memcpy(pNewFileData + 16, &FmtSize, 4);

		eso::word OldCbSize = *(word *)(pFileData + 36);
		//if (CbSize != 6) PrintLog("\tCB size of %d", (int)CbSize);
		eso::word CbSize = OldCbSize + 0x10;
		memcpy(pNewFileData + 36, &CbSize, 2);

		eso::word ValidBitsPerSample = *(word *)(pFileData + 38);
		//if (ValidBitsPerSample != 0) PrintLog("\tValidBitsPerSample of %d", (int)ValidBitsPerSample);
		ValidBitsPerSample += 0x10;
		memcpy(pNewFileData + 38, &ValidBitsPerSample, 2);

		memcpy(pNewFileData + 44, "\x01\x00\x00\x00\x00\x00\x10\x00\x80\x00\x00\xAA\x00\x38\x9B\x71", 16);

		eso::dword oldChunkStart = 36 + 2 + OldCbSize;
		eso::dword newChunkStart = 36 + 2 + CbSize;
		memcpy(pNewFileData + newChunkStart, pFileData + oldChunkStart, (size_t)DataInfo.FileDataSize - oldChunkStart);

		WavFilename = OutputFilename + ".wav";

		if (!File.Open(WavFilename, "wb")) return false;
		Result = File.WriteBytes(pNewFileData, NewFileSize);
		if (!Result) return false;

		return true;
	}


	bool l_FileSortFunc (const mnf_filetable_t i, const mnf_filetable_t j) 
	{ 
		if (i.ArchiveIndex < j.ArchiveIndex) 
		{
			return true;
		}
		else if (i.ArchiveIndex == j.ArchiveIndex) 
		{
			return i.Offset < j.Offset;
		}

		return false; 
	}


	bool CMnfFile::SaveSubFile (const size_t FileIndex, const mnf_exportoptions_t ExportOptions)
	{
		if (m_FileIndexMap.find((dword) FileIndex) == m_FileIndexMap.end())	return PrintError("Failed to find the file with index %d (0x%08X) in MNF file!", FileIndex, FileIndex);

		PrintError("Saving file index %d (0x%08X) from MNF file...", FileIndex, FileIndex);
		PrintError("Saving data to '%s'...", ExportOptions.OutputPath.c_str());
		return SaveSubFile(*m_FileIndexMap[(dword)FileIndex], ExportOptions.OutputPath, ExportOptions.ConvertDDS, nullptr, ExportOptions.ExtractSubFileDataType, ExportOptions.NoParseGR2, ExportOptions.ExtractFileExtension, ExportOptions.NoRiffConvert, ExportOptions.MatchFilename);
	}

	
	bool CMnfFile::SaveSubFiles (const mnf_exportoptions_t ExportOptions)
	{
		CMnfFileTableArray SortedTable(m_FileTable);
		std::string InputFilename;
		CFile InputFile;
		int	LastArchive = -1;
		bool SaveResult = true;
		size_t SuccessCount = 0;
		size_t StartIndex;
		size_t EndIndex;
		bool Result;
		bool SkipEmptyDat = false;
		double StartTime = GetTimerMS();
		size_t ArchiveCount = 0;
		
		std::sort(SortedTable.begin(), SortedTable.end(), l_FileSortFunc);
		if (SortedTable.size() == 0) return PrintError("No entries in MNF file to export!");

		StartIndex = 0;
		EndIndex = SortedTable.size() - 1;

		if (ExportOptions.ArchiveIndex >= 0)
		{
			size_t i;

			for (i = 0; i < SortedTable.size(); ++i)
			{
				if (SortedTable[i].ArchiveIndex == ExportOptions.ArchiveIndex) 
				{
					StartIndex = i;
					break;
				}
			}

			for (; i < SortedTable.size(); ++i)
			{
				if (SortedTable[i].ArchiveIndex != ExportOptions.ArchiveIndex) 
				{
					EndIndex = i - 1;
					break;
				}
				++ArchiveCount;
			}

			if (ArchiveCount == 0) return PrintError("No files in MNF that have an archive index of %05d!", ExportOptions.ArchiveIndex);
		}

		if (ExportOptions.MnfStartIndex > 0) StartIndex = ExportOptions.MnfStartIndex;
		if (ExportOptions.MnfEndIndex   > 0) EndIndex   = ExportOptions.MnfEndIndex;

		double EndTime = GetTimerMS();	
		PrintDebug("Sorted MNF file table in %g ms...", EndTime - StartTime);

		StartTime = GetTimerMS();

		if (ExportOptions.ArchiveIndex >= 0)
			PrintError("Saving %u sub-files (%u-%u) from archive %04d in MNF file...", ArchiveCount, StartIndex, EndIndex, ExportOptions.ArchiveIndex);
		else if (ExportOptions.BeginArchiveIndex >= 0)
			PrintError("Saving sub-files from archive %04d and above in MNF file...", ExportOptions.BeginArchiveIndex);
		else
			PrintError("Saving %u sub-files (%u-%u) in MNF file...", EndIndex - StartIndex + 1, StartIndex, EndIndex);

		PrintDebug("Saving sub-files to '%s'...", ExportOptions.OutputPath.c_str());

		for (size_t i = StartIndex; i <= EndIndex; ++i)
		{
			if (ExportOptions.ArchiveIndex >= 0 && ExportOptions.ArchiveIndex != SortedTable[i].ArchiveIndex) continue;
			if (ExportOptions.BeginArchiveIndex >= 0 && SortedTable[i].ArchiveIndex < ExportOptions.BeginArchiveIndex) continue;

			if (i % 100 == 0 && i > 0) 
			{
				if (ExportOptions.ArchiveIndex >= 0)
					PrintError("\tSubfile %7u of %7u: %.0f%% complete...", i, ArchiveCount, (float)(i - StartIndex)*100.0f/(float)(ArchiveCount + 1));
				else
					PrintError("\tSubfile %7u of %7u: %.0f%% complete...", i, EndIndex - StartIndex, (float)(i - StartIndex)*100.0f/(float)(EndIndex - StartIndex + 1));
			}

			if (SortedTable[i].ArchiveIndex != LastArchive)
			{
				SkipEmptyDat = false;
				LastArchive = SortedTable[i].ArchiveIndex;
				InputFile.Close();

				InputFilename = CreateDataFilename(SortedTable[i].ArchiveIndex);
				
				if (!InputFile.Open(InputFilename, "rb")) 
				{
					PrintError("Error: Failed to open DAT '%s'...", InputFilename.c_str());
					SkipEmptyDat = true;
					continue;
				}

				fpos_t FileSize = InputFile.GetSize();

				if (FileSize <= 14) 
				{
					PrintError("Skipping empty DAT '%s'...", InputFilename.c_str());
					SkipEmptyDat = true;
					continue;
				}

				PrintError("Loading DAT '%s'...", InputFilename.c_str());
			}

			if (SkipEmptyDat) continue;

			Result = SaveSubFile(SortedTable[i], ExportOptions.OutputPath, ExportOptions.ConvertDDS, &InputFile, ExportOptions.ExtractSubFileDataType, ExportOptions.NoParseGR2, ExportOptions.ExtractFileExtension, ExportOptions.NoRiffConvert, ExportOptions.MatchFilename);
			if (Result) ++SuccessCount;
			SaveResult &= Result;
		}

		EndTime = GetTimerMS();
		PrintError("Successfully exported %u sub-files in %g secs!", SuccessCount, (EndTime - StartTime)/1000.0);
		return SaveResult;
	}	


	bool CMnfFile::SaveSubFilesFast (const std::string BasePath, const bool ConvertDDS, const size_t StartIndex)
	{
		CMnfFileTableArray SortedTable(m_FileTable);
		std::string InputFilename;
		CFile InputFile;
		int	LastArchive = -1;
		bool SaveResult = true;
		size_t SuccessCount = 0;
		bool Result;

		double StartTime = GetTimerMS();

		std::sort(SortedTable.begin(), SortedTable.end(), l_FileSortFunc);

		double EndTime = GetTimerMS();
		PrintDebug("Sorted MNF file table in %g ms...", EndTime - StartTime);

		StartTime = GetTimerMS();
		PrintError("Saving %d sub-files referenced in MNF file to '%s'...", SortedTable.size(), BasePath.c_str());

		for (size_t i = StartIndex; i < SortedTable.size(); ++i)
		{
			if (i % 100 == 0) PrintError("\tSubfile %7u of %7u: %.0f%% complete...", i, SortedTable.size(), (float)i*100.0f/(float)SortedTable.size());

			if (SortedTable[i].ArchiveIndex != LastArchive)
			{
				InputFilename = CreateDataFilename(SortedTable[i].ArchiveIndex);
				InputFile.Close();
				PrintError("Starting archive %s...", InputFilename.c_str());

				if (!InputFile.Open(InputFilename, "rb")) continue;
				LastArchive = SortedTable[i].ArchiveIndex;
			}

			Result = SaveSubFile(SortedTable[i], BasePath, ConvertDDS, &InputFile);
			if (Result) ++SuccessCount;
			SaveResult &= Result;
		}

		EndTime = GetTimerMS();
		PrintDebug("Successfully exported %u sub-files in %g secs!", SuccessCount, (EndTime - StartTime)/1000.0);
		return SaveResult;
	}


	std::string CMnfFile::CreateDataFilename(const byte ArchiveIndex)
	{
		return CreateFilename(RemoveFileExtension(m_Filename), "%04u.dat", (dword)ArchiveIndex);
	}


};