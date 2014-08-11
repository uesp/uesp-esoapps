

#include "EsoZosftFile.h"


namespace eso {


	CZosftFile::CZosftFile() :
					m_Header(),
					m_Footer(),
					m_RawFileDataSize(0),
					m_pRawFileData(nullptr)
	{
	}

	CZosftFile::~CZosftFile() 
	{
		Destroy();
	}

	void CZosftFile::Destroy()
	{
		delete[] m_pRawFileData;
		m_pRawFileData = nullptr;
		m_RawFileDataSize = 0;
		m_Filenames.clear();

		memset(&m_Header, 0, sizeof(m_Header));
		memset(&m_Footer, 0, sizeof(m_Footer));

		m_FileIndexMap.clear();
		m_FileTable.clear();		
	}


	void CZosftFile::CheckBlockFormats (void)
	{
		for (size_t i = 0; i < ZOSFT_BLOCK_COUNT; ++i)
		{
			for (size_t j = 0; j < 3; ++j)
			{
				mnf_block_data_t* pData = m_Blocks[i].GetData(j);

				if (pData == nullptr)
				{
					PrintLog("%d-%d: No data in block!", i+1, j+1);
					continue;
				}

				if (pData->pUncompressedData == nullptr)
				{
					PrintLog("%d-%d: No uncompressed data in block!", i+1, j+1);
					continue;
				}

				if (snappy::IsValidCompressedBuffer((const char *)pData->pUncompressedData, pData->UncompressedSize))
				{
					PrintLog("%d-%d: Snappy data!", i+1, j+1);
					continue;
				}

				if (memcmp(pData->pUncompressedData, "\x78\x9C", 2) == 0)
				{
					PrintLog("%d-%d: zLib data!", i+1, j+1);
					continue;
				}

				PrintLog("%d-%d: Unknown data!", i+1, j+1);
			}
		}

		TestCount80(0, 0);
		TestCount80(1, 0);
		TestCount80(2, 0);		
	}


	bool CZosftFile::CreateFileMaps (void)
	{
		m_FileIndexMap.clear();

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			m_FileIndexMap[m_FileTable[i].FileIndex] = &m_FileTable[i];
		}

		return true;
	}


	bool CZosftFile::CreateFileTable (void)
	{		
		size_t Offset11 = 0;
		size_t Offset13 = 0;
		size_t Offset21 = 0;
		size_t Offset23 = 0;
		zosft_filetable_t Entry;

		m_FileTable.clear();
		m_FileTable.reserve(m_Header.RecordCount + 100);

		mnf_block_data_t* pData11 = m_Blocks[0].GetData(0);
		mnf_block_data_t* pData13 = m_Blocks[0].GetData(2);
		mnf_block_data_t* pData21 = m_Blocks[1].GetData(0);
		mnf_block_data_t* pData23 = m_Blocks[1].GetData(2);

		if (pData11 == nullptr || pData13 == nullptr || pData21 == nullptr || pData23 == nullptr ||
			pData11->pUncompressedData == nullptr || pData13->pUncompressedData == nullptr || 
			pData21->pUncompressedData == nullptr || pData23->pUncompressedData == nullptr)
		{
			PrintError("Error: Missing required data to generate ZOSFT table!");
			return false;
		}		

		for (size_t i = 0; i < m_Header.RecordCount; ++i)
		{
			Entry.Index = i;
			
			if (Offset11 < pData11->UncompressedSize)
			{
				Entry.Index11 = *(dword *)(pData11->pUncompressedData + Offset11);

				do {
					Offset11 += 4;
				} while (Offset11 < pData11->UncompressedSize && pData11->pUncompressedData[Offset11+3] != 0x80);
			}
			else 
			{
				Entry.Index11 = 0;
			}

			if (Offset13 < pData13->UncompressedSize)
			{
				Entry.Index13 = *(dword *)(pData13->pUncompressedData + Offset13);
				Offset13 += 4;
			}
			else 
			{
				Entry.Index13 = 0;
			}

			if (Offset21 < pData21->UncompressedSize)
			{
				Entry.Index21 = *(dword *)(pData21->pUncompressedData + Offset21);

				do {
					Offset21 += 4;
				} while (Offset21 < pData21->UncompressedSize && pData21->pUncompressedData[Offset21+3] != 0x80);
			}
			else 
			{
				Entry.Index21 = 0;
			}

			if (Offset23 < pData23->UncompressedSize)
			{
				Entry.FileIndex = *(dword *)(pData23->pUncompressedData + Offset23);
				Offset23 += 4;

				Entry.FilenameOffset = *(dword *)(pData23->pUncompressedData + Offset23);
				Offset23 += 4;				

				Entry.FileID = *(dword64 *)(pData23->pUncompressedData + Offset23);
				Offset23 += 8;

				if (Entry.FilenameOffset < m_RawFileDataSize) 
				{
					Entry.Filename = (const char *)(m_pRawFileData + Entry.FilenameOffset);
					std::replace(Entry.Filename.begin(), Entry.Filename.end(), '/', '\\');
				}
				else
				{
					Entry.Filename = "";
				}
			}
			else 
			{
				Entry.FileID = 0;
				Entry.FileIndex = 0;
				Entry.FilenameOffset = 0;
			}

			m_FileTable.push_back(Entry);
		}

		if (Offset11 != pData11->UncompressedSize) PrintLog("Warning: Mismatch between parsed size (%d) and total size (%d) of block 1-1 data!", Offset11, pData11->UncompressedSize);
		if (Offset13 != pData13->UncompressedSize) PrintLog("Warning: Mismatch between parsed size (%d) and total size (%d) of block 1-3 data!", Offset13, pData13->UncompressedSize);
		if (Offset21 != pData21->UncompressedSize) PrintLog("Warning: Mismatch between parsed size (%d) and total size (%d) of block 2-1 data!", Offset21, pData21->UncompressedSize);
		if (Offset23 != pData23->UncompressedSize) PrintLog("Warning: Mismatch between parsed size (%d) and total size (%d) of block 2-3 data!", Offset23, pData23->UncompressedSize);

		return CreateFileMaps();
	}


	bool CZosftFile::DumpFileTable (const char* pFilename)
	{
		CFile File;
		std::string OutputPath = ExtractPath(pFilename);

		if (!EnsurePathExists(OutputPath)) return false;
		if (!File.Open(pFilename, "wb")) return false;

		File.Printf("  Index,   Index11 ,   Index13 ,   Index21 , FileIndex,  FileOffset,      FileID       ,                Filename\n");

		for (size_t i = 0; i < m_FileTable.size(); ++i)
		{
			zosft_filetable_t &Entry = m_FileTable[i];

			File.Printf("%7d, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%08X, 0x%016llX, '%s'\n", 
				Entry.Index, Entry.Index11, Entry.Index13, Entry.Index21, Entry.FileIndex, Entry.FilenameOffset, Entry.FileID, Entry.Filename.c_str());
		}

		return true;
	}


	bool CZosftFile::Load (const char* pFilename)
	{
		CFile File;

		if (!File.Open(pFilename, "rb")) return false;

		return Load(File);
	}


	bool CZosftFile::Load (CBaseFile& File)
	{
		Destroy();

		double StartTime = GetTimerMS();
		
		if (!ReadHeader(File)) return false;
		if (!ReadBlockData(File)) return false;		
		if (!ReadFileData(File)) return false;		
		if (!ReadFooter(File)) return false;

		CreateFileTable();

		double EndTime = GetTimerMS();
		PrintLog("Successfully loaded ZOSFT in %g ms!", EndTime - StartTime);

		return true;
	}


	zosft_filetable_t* CZosftFile::LookupIndex (dword FileIndex)
	{
		if (m_FileIndexMap.find(FileIndex) != m_FileIndexMap.end()) return m_FileIndexMap[FileIndex];
		return nullptr;
	}


	bool CZosftFile::ReadHeader (CBaseFile& File)
	{
		if (!File.ReadBytes(m_Header.FileID, ZOSFT_HEADER_MAGICSIZE)) return false;
		if (memcmp(m_Header.FileID, ZOSFT_MAGIC_ID, ZOSFT_HEADER_MAGICSIZE) != 0) PrintError("Warning: Didn't find the expected '%s' at start of ZOSFT file!", ZOSFT_MAGIC_ID);

		if (!File.ReadWord (m_Header.Unknown1)) return false;
		if (!File.ReadDword(m_Header.Unknown2)) return false;
		if (!File.ReadDword(m_Header.Unknown3)) return false;
		if (!File.ReadDword(m_Header.RecordCount)) return false;

		return true;
	}


	bool CZosftFile::ReadBlockData (CBaseFile& File)
	{
		for (size_t i = 0; i < ZOSFT_BLOCK_COUNT; ++i)
		{
			if (!m_Blocks[i].Read(File, true)) return false;
		}

		return true;
	}


	bool CZosftFile::ReadFileData (CBaseFile& File)
	{
		if (!File.ReadDword(m_RawFileDataSize)) return false;
		
		delete[] m_pRawFileData;
		m_pRawFileData = new byte[m_RawFileDataSize];

		if (!File.ReadBytes(m_pRawFileData, m_RawFileDataSize)) return false;
		
		SplitRawFileData();
		return true;
	}


	bool CZosftFile::ReadFooter (CBaseFile& File)
	{
		if (!File.ReadBytes(m_Footer, ZOSFT_FOOTER_MAGICSIZE)) return false;

		if (memcmp(m_Footer, ZOSFT_MAGIC_ID, ZOSFT_FOOTER_MAGICSIZE) != 0) PrintError("Warning: Didn't find the expected '%s' at end of ZOSFT file!", ZOSFT_MAGIC_ID);

		fpos_t FileSize = File.GetSize();
		fpos_t CurPos   = File.Tell();

		if (FileSize != CurPos) 
			PrintLog("Didn't reach exact end of ZOSFT file: %u bytes read, %u bytes total!", CurPos, FileSize);
		else
			PrintLog("Read all of ZOSFT file!");

		return true;
	}


	void CZosftFile::SplitRawFileData()
	{
		size_t LastStartPos = 0;
		if (m_RawFileDataSize == 0 || m_pRawFileData == nullptr) return;

		for (size_t i = 0; i < m_RawFileDataSize; ++i)
		{
			if (m_pRawFileData[i] == '\0')
			{
				m_Filenames.push_back(std::string((const char *)m_pRawFileData + LastStartPos, i - LastStartPos + 1));
				LastStartPos = i + 1;
			}
		}
		
		PrintLog("Found %d filenames in raw ZOSFT file data!", m_Filenames.size());
	}


	bool CZosftFile::SaveBlock (const size_t BlockIndex, const size_t Index, const char* pFilename)
	{
		if (BlockIndex >= ZOSFT_BLOCK_COUNT) return PrintError("Error: Invalid ZOSFT block index %d!", BlockIndex);
		return m_Blocks[BlockIndex].SaveBlock(Index, pFilename);
	}


	void CZosftFile::TestCount80 (const size_t BlockIndex, const size_t Index)
	{
		
		if (BlockIndex >= ZOSFT_BLOCK_COUNT) 
		{
			PrintLog("Error: Invalid block index %u!", BlockIndex);
			return;
		}

		mnf_block_data_t* pData = m_Blocks[BlockIndex].GetData(Index);

		if (pData == nullptr)
		{
			PrintLog("Error: Invalid block data index %u-%u!", BlockIndex, Index);
			return;
		}

		size_t Offset = 0;
		size_t Count = 0;

		while (Offset + 4 <= pData->UncompressedSize)
		{
			dword Value = *((dword *)(pData->pUncompressedData + Offset));
			if ((Value >> 24) == 0x80) Count++;
			Offset += 4;
		}

		PrintLog("%u-%u: Found %u 0x80XXXXXX records in block!", BlockIndex+1, Index+1, Count);
	}
};
