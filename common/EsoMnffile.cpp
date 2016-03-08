


#include "EsoMnfFile.h"
#include "EsoLangFile.h"


namespace eso {


	CMnfFile::CMnfFile() :
				m_HasBlock0(false),
				m_Block0(false, false),
				m_Block3(false, false)
	{
		memcpy(m_Header.FileID, MNF_MAGIC_ID, MNF_HEADER_MAGICSIZE);
		m_Header.DataSize  = 0;
		m_Header.FileCount = 0;
		m_Header.Unknown1  = 2;
		m_Header.Unknown2  = 1;
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

		m_Block0.Destroy();
		m_Block3.Destroy();

		m_HasBlock0 = false;
		m_Header.DataSize  = 0;
		m_Header.FileCount = 0;
	}


	bool CMnfFile::CreateFileTable (void)
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

		if ( pData1->UncompressedSize % MNF_BLOCK1_RECORDSIZE != 0) PrintLog("Warning: MNF Block1 (%d bytes) is not an even multiple of the record size %d!", pData1->UncompressedSize, MNF_BLOCK1_RECORDSIZE);
		if ( pData2->UncompressedSize % MNF_BLOCK2_RECORDSIZE != 0) PrintLog("Warning: MNF Block2 (%d bytes) is not an even multiple of the record size %d!", pData2->UncompressedSize, MNF_BLOCK2_RECORDSIZE);
		if ( pData3->UncompressedSize % MNF_BLOCK3_RECORDSIZE != 0) PrintLog("Warning: MNF Block3 (%d bytes) is not an even multiple of the record size %d!", pData3->UncompressedSize, MNF_BLOCK3_RECORDSIZE);

		for (size_t i = 0; i < m_Block3.GetHeader().RecordCount23; ++i) 
		{
			TableEntry.Index = i;

			if (Offset1 + MNF_BLOCK1_RECORDSIZE <= pData1->UncompressedSize) 
			{
				TableEntry.ID1 = *((dword *) (pData1->pUncompressedData + Offset1));

				do 
				{
					Offset1 += MNF_BLOCK1_RECORDSIZE;
				} while (Offset1 + MNF_BLOCK1_RECORDSIZE <= pData1->UncompressedSize && pData1->pUncompressedData[Offset1+3] != 0x80);
			}
			else
			{
				TableEntry.ID1 = 0;
			}

			if (Offset2 + MNF_BLOCK2_RECORDSIZE <= pData2->UncompressedSize) 
			{
				TableEntry.FileIndex = *((dword *) (pData2->pUncompressedData + Offset2 + 0));
				TableEntry.Unknown1  = *((dword *) (pData2->pUncompressedData + Offset2 + 4));
				Offset2 += MNF_BLOCK2_RECORDSIZE;
			}
			else
			{
				TableEntry.FileIndex = 0;
				TableEntry.Unknown1  = 0;
			}

			if (Offset3 + MNF_BLOCK3_RECORDSIZE <= pData3->UncompressedSize) 
			{
				TableEntry.Size           = *((dword *) (pData3->pUncompressedData + Offset3 + 0));
				TableEntry.CompressedSize = *((dword *) (pData3->pUncompressedData + Offset3 + 4));
				TableEntry.Hash           = *((dword *) (pData3->pUncompressedData + Offset3 + 8));
				TableEntry.Offset         = *((dword *) (pData3->pUncompressedData + Offset3 + 12));
				TableEntry.CompressType   = pData3->pUncompressedData[Offset3 + 16];
				TableEntry.ArchiveIndex   = pData3->pUncompressedData[Offset3 + 17];
				TableEntry.Unknown2       = *((word  *) (pData3->pUncompressedData + Offset3 + 18));
				Offset3 += MNF_BLOCK3_RECORDSIZE;
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


	bool CMnfFile::CreateFileMaps (void)
	{
		m_FileHashMap.clear();
		m_FileIndexMap.clear();

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			m_FileHashMap[m_FileTable[i].Hash]       = &m_FileTable[i];
			m_FileIndexMap[m_FileTable[i].FileIndex] = &m_FileTable[i];
		}


		return true;
	}

	bool CMnfFile::DumpFileTable (const char* pFilename) 
	{
		return DumpFileTable(pFilename, m_FileTable);
	}


	bool CMnfFile::DumpFileTable (const char* pFilename, CMnfFileTableArray& FileTable)
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


	bool CMnfFile::FindZosftHash (dword& ZosftHash)
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
			if (m_FileIndexMap.find(0xFFFFF) != m_FileIndexMap.end()) {	ZosftHash = m_FileIndexMap[0xFFFFF]->Hash; return true;	}
			if (m_FileIndexMap.find(0x00FFFFFF) != m_FileIndexMap.end()) { ZosftHash = m_FileIndexMap[0x00FFFFFF]->Hash; return true; }

			if (HasFileHash(MNF_ESOZOSFT_HASH)) { ZosftHash = MNF_ESOZOSFT_HASH; return true; }
			if (HasFileHash(0xF4FD2ECD)) { ZosftHash = 0xF4FD2ECD; return true; }
			if (HasFileHash(0x4C99266E)) { ZosftHash = 0x4C99266E; return true; }
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


	bool CMnfFile::Export (const mnf_exportoptions_t ExportOptions)
	{
		CZosftFile ZosftFile;

		PrintError("Loading MNF file '%s'...", ExportOptions.MnfFilename.c_str());

		if (!Load(ExportOptions.MnfFilename.c_str()))
		{
			PrintError("Failed to load MNF file '%s'...aborting!", ExportOptions.MnfFilename.c_str());
			return false;
		}

		PrintError("Trying to find and load ZOSFT entry from MNF file!");

		dword ZosftHash = 0;
				
		if (!FindZosftHash(ZosftHash))
		{
			PrintError("ERROR: Failed to find the ZOSFT entry in the MNF file!");
		}
		else if (!LoadZosft(ZosftHash, ZosftFile))
		{
			PrintError("Failed to load the ZOSFT data from MNF file data!\nFiles will be exported but without any filenames set.\n");
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

		if (ExportOptions.SkipSubFiles)
		{
			PrintError("Skipping extraction of subfile data....\n");
			return true;
		}

		if (ExportOptions.MnfFileIndex > 0) return SaveSubFile(ExportOptions.MnfFileIndex, ExportOptions);
		return SaveSubFiles(ExportOptions);
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
			//delete [] DataInfo.pRawData;
			//delete [] DataInfo.pUncompressedData;
			return false;
		}

		//delete [] DataInfo.pRawData;
		//delete [] DataInfo.pUncompressedData;

		LinkToZosft(ZosftFile);
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
			PrintError("Error: Found unknown block type %d in MNF file!", (int) BlockID);
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

		if (!File.ReadWord(m_Header.Unknown1)) return false;
		if (!File.ReadByte(m_Header.FileCount)) return false;
		if (!File.ReadDword(m_Header.Unknown2)) return false;
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
			if (i % 100 == 0) PrintError("Subfile %u: %.0f%% complete...", i, (float)i*100.0f/(float)m_FileTable.size());
			Result &= SaveSubFile(m_FileTable[i], BasePath, ConvertDDS);
		}

		double EndTime = GetTimerMS();
		PrintLog("Exported %u sub-files in %g secs!", m_FileTable.size(), (EndTime - StartTime)*1000.0);
		return Result;
	}


	bool CMnfFile::SaveSubFile (mnf_filetable_t& FileEntry, const std::string BasePath, const bool ConvertDDS, CFile* pFile)
	{
		dat_subfileinfo_t DataInfo;
		std::string OutputFilename;
		std::string OutputPath;
		CFile File;
		
		DataInfo.DeletePtrs = true;

		if (!ReadDataFile(FileEntry, DataInfo, pFile)) 
		{
			return PrintError("Error: Failed to load the file data from MNF %03u with file index %u (absolute index %u)!", (dword)FileEntry.ArchiveIndex, FileEntry.FileIndex, FileEntry.Index);
		}

		if (DataInfo.pFileDataStart == nullptr) return PrintError("Error: No uncompressed data to write to file!");

		if (FileEntry.pZosftEntry != nullptr && !FileEntry.pZosftEntry->Filename.empty())
		{
			OutputFilename = AppendFilenameToPath(BasePath, FileEntry.pZosftEntry->Filename);
			OutputPath = RemoveFilename(OutputFilename);
			if (!EnsurePathExists(OutputPath)) return false;

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
		}

		OutputFilename = CreateFilename(BasePath, "%03u\\%06u.%s", (dword)FileEntry.ArchiveIndex, FileEntry.Index, GuessFileExtension((char *)DataInfo.pFileDataStart, DataInfo.FileDataSize).c_str());
		OutputPath = RemoveFilename(OutputFilename);
		if (!EnsurePathExists(OutputPath)) return false;

		if (!File.Open(OutputFilename.c_str(), "wb")) return false;
		if (!File.WriteBytes(DataInfo.pFileDataStart, DataInfo.FileDataSize)) return false;
		File.Close();

		if (ConvertDDS && StringEndsWith(OutputFilename, ".dds"))
		{
			ConvertDDStoPNG(DataInfo.pFileDataStart, DataInfo.FileDataSize, OutputFilename);
		}

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
		if (m_FileIndexMap.find(FileIndex) == m_FileIndexMap.end())	return PrintError("Failed to find the file with index %d (0x%08X) in MNF file!", FileIndex, FileIndex);

		PrintError("Saving file index %d (0x%08X) from MNF file...", FileIndex, FileIndex);
		PrintError("Saving data to '%s'...", ExportOptions.OutputPath.c_str());
		return SaveSubFile(*m_FileIndexMap[FileIndex], ExportOptions.OutputPath, ExportOptions.ConvertDDS);
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
					EndIndex = i-1;
					break;
				}
				++ArchiveCount;
			}

			if (ArchiveCount == 0) return PrintError("No files in MNF that have an archive index of %05d!", ExportOptions.ArchiveIndex);
		}

		if (ExportOptions.MnfStartIndex > 0) StartIndex = ExportOptions.MnfStartIndex;
		if (ExportOptions.MnfEndIndex   > 0) EndIndex   = ExportOptions.MnfEndIndex;

		double EndTime = GetTimerMS();	
		PrintLog("Sorted MNF file table in %g ms...", EndTime - StartTime);

		StartTime = GetTimerMS();

		if (ExportOptions.ArchiveIndex >= 0)
			PrintError("Saving %u sub-files (%u-%u) from archive %04d in MNF file...", ArchiveCount, StartIndex, EndIndex, ExportOptions.ArchiveIndex);
		else if (ExportOptions.BeginArchiveIndex >= 0)
			PrintError("Saving sub-files from archive %04d and above in MNF file...", ExportOptions.BeginArchiveIndex);
		else
			PrintError("Saving %u sub-files (%u-%u) in MNF file...", EndIndex - StartIndex + 1, StartIndex, EndIndex);

		PrintError("Saving sub-files to '%s'...", ExportOptions.OutputPath.c_str());

		for (size_t i = StartIndex; i <= EndIndex; ++i)
		{
			if (ExportOptions.ArchiveIndex >= 0 && ExportOptions.ArchiveIndex != SortedTable[i].ArchiveIndex) continue;
			if (ExportOptions.BeginArchiveIndex >= 0 && SortedTable[i].ArchiveIndex < ExportOptions.BeginArchiveIndex) continue;

			if (i % 100 == 0) 
			{
				if (ExportOptions.ArchiveIndex >= 0)
					PrintError("Subfile %u: %.0f%% complete...", i, (float)(i - StartIndex)*100.0f/(float)(ArchiveCount + 1));
				else
					PrintError("Subfile %u: %.0f%% complete...", i, (float)(i - StartIndex)*100.0f/(float)(EndIndex - StartIndex + 1));
			}

			if (SortedTable[i].ArchiveIndex != LastArchive)
			{
				InputFilename = CreateDataFilename(SortedTable[i].ArchiveIndex);
				InputFile.Close();
				PrintError("Loading DAT '%s'...", InputFilename.c_str());

				if (!InputFile.Open(InputFilename, "rb")) continue;
				LastArchive = SortedTable[i].ArchiveIndex;
			}

			Result = SaveSubFile(SortedTable[i], ExportOptions.OutputPath, ExportOptions.ConvertDDS, &InputFile);
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
		PrintLog("Sorted MNF file table in %g ms...", EndTime - StartTime);

		StartTime = GetTimerMS();
		PrintError("Saving %d sub-files referenced in MNF file to '%s'...", SortedTable.size(), BasePath.c_str());

		for (size_t i = StartIndex; i < SortedTable.size(); ++i)
		{
			if (i % 100 == 0) PrintError("Subfile %u: %.0f%% complete...", i, (float)i*100.0f/(float)SortedTable.size());

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
		PrintLog("Successfully exported %u sub-files in %g secs!", SuccessCount, (EndTime - StartTime)/1000.0);
		return SaveResult;
	}


	std::string CMnfFile::CreateDataFilename(const byte ArchiveIndex)
	{
		return CreateFilename(RemoveFileExtension(m_Filename), "%04u.dat", (dword)ArchiveIndex);
	}


};