

#include "EsoMnfBlock.h"


namespace eso {


	CMnfBlock::CMnfBlock(const bool LittleEndian) :
				m_LittleEndian(LittleEndian),
				m_ReadBlockID(true),
				m_DataCount(0)
	{
	}


	CMnfBlock::~CMnfBlock()
	{
		Destroy();
	}


	void CMnfBlock::Destroy()
	{
		for (size_t i = 0; i < m_DataCount; ++i)
		{
			m_Data[i].Destroy();
		}
	}


	CMnfBlock* CMnfBlock::CreateBlock (const word BlockID)
	{
		switch (BlockID)
		{
			case 3: return new CMnfBlock3(false, false);
			case 0:	return new CMnfBlock0(false, false);
		}

		PrintError("Error: Unknown MNF block type %d!", (int)BlockID);
		return nullptr;
	}


	std::string CMnfBlock::GuessFileExtension (const size_t Index)
	{
		if (Index >= m_DataCount) return "";
		if (m_Data[Index].pUncompressedData == nullptr) return "";
		return eso::GuessFileExtension((const char *)m_Data[Index].pUncompressedData, m_Data[Index].UncompressedSize);
	}


	bool CMnfBlock::Read (CBaseFile &File, const bool ReadBlockID)
	{
		Destroy();
		m_ReadBlockID = ReadBlockID;

		PrintLog("Reading MNF block starting at 0x%llX...", File.Tell());

		if (!ReadHeader(File)) return false;
		if (!ReadData(File)) return false;

		PrintLog("Finished reading MNF block at 0x%llX...", File.Tell());
		return true;
	}

	
	bool CMnfBlock::ReadData (CBaseFile &File)
	{

		for (size_t i = 0; i < m_DataCount; ++i)
		{
			if (i >= ZOSFT_BLOCK_MAXDATACOUNT) return PrintError("Error: Exceeded maximum data count of %d in MNF block!", ZOSFT_BLOCK_MAXDATACOUNT);

			PrintLog("Reading MNF block data starting at 0x%llX...", File.Tell());

			if (!ReadRawData(File, m_Data[i])) return false;
			if (!UncompressRawData(m_Data[i])) return false;
			if (!ParseRawData(m_Data[i])) return false;
		}

		return true;
	}


	bool CMnfBlock::ReadRawData (CBaseFile &File, mnf_block_data_t& Data)
	{
		Data.Destroy();

		if (!File.ReadDword(Data.UncompressedSize, m_LittleEndian)) return false;
		if (!File.ReadDword(Data.CompressedSize,   m_LittleEndian)) return false;

		if (Data.CompressedSize >= UINT_MAX - ZOSFT_DATA_OVERSIZE) return PrintError("Error: Data block in MNF file is too large (0x%08X bytes)!", Data.CompressedSize);
		Data.pCompressedData = new byte[Data.CompressedSize + ZOSFT_DATA_OVERSIZE];

		if (!File.ReadBytes(Data.pCompressedData, Data.CompressedSize)) return false;

		return true;
	}


	bool CMnfBlock::SaveBlock (const size_t Index, const char* pFilename)
	{
		CFile File;

		if (Index < 0 || Index >= m_DataCount) return PrintError("Error: Invalid block data index %d!", Index);

		if (!File.Open(pFilename, "wb")) return false;

		if (m_Data[Index].pUncompressedData)
		{
			PrintLog("Saving block #%d, %d bytes of uncompressed data...", Index, m_Data[Index].UncompressedSize);
			return File.WriteBytes(m_Data[Index].pUncompressedData, m_Data[Index].UncompressedSize);
		}
		else if (m_Data[Index].pCompressedData)
		{
			PrintLog("Saving block #%d, %d bytes of unknown or compressed data...", Index, m_Data[Index].CompressedSize);
			return File.WriteBytes(m_Data[Index].pCompressedData, m_Data[Index].CompressedSize);
		}
		
		return PrintError("Error: No data to export in block %d!", Index);
	}
	





	CMnfBlock3::CMnfBlock3(const bool LittleEndian, const bool ReadBlockID) :
				CMnfBlock(LittleEndian),
				m_Header()
	{
		m_ReadBlockID = ReadBlockID;
		m_DataCount = ZOSFT_BLOCK3_DATACOUNT;

		m_Header.BlockID = 3;
	}


	CMnfBlock3::~CMnfBlock3()
	{
		Destroy();
	}


	void CMnfBlock3::Destroy()
	{
		CMnfBlock::Destroy();
	}


	bool CMnfBlock3::ReadData (CBaseFile &File)
	{

		for (size_t i = 0; i < m_DataCount; ++i)
		{
			if (i >= ZOSFT_BLOCK_MAXDATACOUNT) return PrintError("Error: Exceeded maximum data count of %d in MNF block!", ZOSFT_BLOCK_MAXDATACOUNT);

			if (i >= 1 && m_Header.RecordCount23 == 0) 
			{
				PrintLog("Skipping MNF block #%d...", i);
				continue;
			}

			PrintLog("Reading MNF block data starting at 0x%llX...", File.Tell());

			if (!ReadRawData(File, m_Data[i])) return false;
			if (!UncompressRawData(m_Data[i])) return false;
			if (!ParseRawData(m_Data[i])) return false;
		}

		return true;
	}


	bool CMnfBlock3::ReadHeader (CBaseFile &File)
	{
		if (m_ReadBlockID) 
		{
			if (!File.ReadWord(m_Header.BlockID, m_LittleEndian)) return false;
		}

		if (!File.ReadDword(m_Header.Unknown1,      m_LittleEndian)) return false;
		if (!File.ReadDword(m_Header.RecordCount1a, m_LittleEndian)) return false;
		if (!File.ReadDword(m_Header.RecordCount1b, m_LittleEndian)) return false;
		if (!File.ReadDword(m_Header.RecordCount23, m_LittleEndian)) return false;	

		return true;
	}

	
	bool CMnfBlock3::UncompressRawData (mnf_block_data_t& Data)
	{
		size_t OutputSize;

		if (Data.UncompressedSize >= UINT_MAX - ZOSFT_DATA_OVERSIZE) return PrintError("Error: Uncompressed data block in MNF file is too large (0x%08X bytes)!", Data.UncompressedSize);
		Data.pUncompressedData = new byte[Data.UncompressedSize + ZOSFT_DATA_OVERSIZE];

		if (!InflateZlibBlock(Data.pUncompressedData, OutputSize, Data.UncompressedSize+ZOSFT_DATA_OVERSIZE, Data.pCompressedData, Data.CompressedSize)) return false;

		if (OutputSize != Data.UncompressedSize) PrintLog("Warning: Actual uncompressed size (%u bytes) doesn't equal expected size (%u bytes)!", OutputSize, Data.UncompressedSize);
		return true;
	}





	CMnfBlock0::CMnfBlock0(const bool LittleEndian, const bool ReadBlockID) :
				CMnfBlock(LittleEndian),
				m_Header()
	{
		m_ReadBlockID = ReadBlockID;
		m_DataCount = ZOSFT_BLOCK0_DATACOUNT;
		m_Header.BlockID = 0;
	}


	CMnfBlock0::~CMnfBlock0()
	{
		Destroy();
	}


	void CMnfBlock0::Destroy()
	{
		CMnfBlock::Destroy();
	}


	bool CMnfBlock0::ParseRawData (mnf_block_data_t& Data)
	{
		PrintLog("Warning: Don't know how to parse raw data from MNF block0!");
		return true;
	}


	bool CMnfBlock0::ReadRawData (CBaseFile &File, mnf_block_data_t& Data)
	{
		Data.Destroy();

		Data.UncompressedSize = 0;
		if (!File.ReadDword(Data.CompressedSize, m_LittleEndian)) return false;

		if (Data.CompressedSize >= UINT_MAX - ZOSFT_DATA_OVERSIZE) return PrintError("Error: Data block in MNF file is too large (0x%08X bytes)!", Data.CompressedSize);
		Data.pCompressedData = new byte[Data.CompressedSize + ZOSFT_DATA_OVERSIZE];

		if (!File.ReadBytes(Data.pCompressedData, Data.CompressedSize)) return false;

		return true;
	}


	bool CMnfBlock0::ReadHeader (CBaseFile &File)
	{
		if (m_ReadBlockID) 
		{
			if (!File.ReadWord(m_Header.BlockID, m_LittleEndian)) return false;
		}

		if (!File.ReadWord(m_Header.Unknown1, m_LittleEndian)) return false;

		return true;
	}


};