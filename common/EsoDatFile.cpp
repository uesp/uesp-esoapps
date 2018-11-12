

#include "EsoDatFile.h"
#include "EsoMnfFile.h"


namespace eso {


	bool ParseSubFileRawData (dat_subfileinfo_t& FileInfo, const mnf_header_t& Header)
	{
		if (FileInfo.pUncompressedData == nullptr) return PrintError("Error: No uncompressed data in DAT sub-file to parse!");
		if (FileInfo.UncompressedSize < 4) return PrintError("Error: Uncompressed data in DAT sub-file too small to parse!");

		if (Header.Unknown2 != 6)
		{
			FileInfo.DataSize1 = 0;
			FileInfo.DataSize2 = 0;
			FileInfo.pData1 = nullptr;
			FileInfo.pData2 = nullptr;
			FileInfo.pFileDataStart = FileInfo.pUncompressedData;
			FileInfo.FileDataSize = FileInfo.UncompressedSize;
			return true;
		}

		FileInfo.NullByte = *(dword *) FileInfo.pUncompressedData;
		if (FileInfo.NullByte != 0) PrintLog("\tNullByte = 0x%08X", FileInfo.NullByte);

		if (FileInfo.UncompressedSize < 8) return PrintError("Error: Missing data1 size in DAT sub-file!");
		FileInfo.DataSize1 = DwordSwap(*(dword *) (FileInfo.pUncompressedData + 4));

		if (FileInfo.UncompressedSize < 8 + FileInfo.DataSize1) return PrintError("Error: Missing data1 record data in DAT sub-file!");
		FileInfo.pData1 = FileInfo.pUncompressedData + 8;		

		if (FileInfo.UncompressedSize < 8 + FileInfo.DataSize1) return PrintError("Error: Missing data2 size in DAT sub-file!");
		FileInfo.DataSize2 = DwordSwap(*(dword *) (FileInfo.pUncompressedData + FileInfo.DataSize1 + 8));

		if (FileInfo.UncompressedSize < 12 + FileInfo.DataSize1 + FileInfo.DataSize2) return PrintError("Error: Missing data2 record data in DAT sub-file!");
		FileInfo.pData2 = FileInfo.pUncompressedData + 12 + FileInfo.DataSize1;

		FileInfo.pFileDataStart = FileInfo.pUncompressedData + 12 + FileInfo.DataSize1 + FileInfo.DataSize2;
		FileInfo.FileDataSize = FileInfo.UncompressedSize - 12 - FileInfo.DataSize1 - FileInfo.DataSize2;

		if (snappy::IsValidCompressedBuffer((char *)FileInfo.pData1, FileInfo.DataSize1)) PrintLog("\tData1 is snappy format");
		if (snappy::IsValidCompressedBuffer((char *)FileInfo.pData2, FileInfo.DataSize2)) PrintLog("\tData2 is snappy format");

		byte TempData[2048];
		dword OutputSize;
		if (InflateZlibBlock(TempData, OutputSize, 2040, FileInfo.pData1, FileInfo.DataSize1, true)) PrintLog("\tData1 is zlib format");
		if (InflateZlibBlock(TempData, OutputSize, 2040, FileInfo.pData2, FileInfo.DataSize2, true)) PrintLog("\tData2 is zlib format");

		//PrintLog("\tDataSizes = 0x%08X  0x%08X", FileInfo.DataSize1, FileInfo.DataSize2);
		if (FileInfo.DataSize1 < 0x1B8 || FileInfo.DataSize1 > 0x1BC) PrintLog("\tDataSize1 = 0x%08X", FileInfo.DataSize1);
		if (FileInfo.DataSize2 != 0x28) PrintLog("\tDataSize2 = 0x%08X", FileInfo.DataSize2);
		return true;
	}


	bool ReadSubFileRawData (dat_subfileinfo_t& FileInfo, const mnf_header_t& Header, CFile* pInputFile)
	{
		CFile File;

		if (FileInfo.RawSize > INT_MAX) return PrintError("Error: Input size of DAT sub-file is too large (%u bytes)!", FileInfo.RawSize);

		if (pInputFile == nullptr) 
		{
			if (!File.Open(FileInfo.Filename.c_str(), "rb")) return false;
			pInputFile = &File;
		}

		if (!pInputFile->Seek(FileInfo.Offset)) return false;

		FileInfo.pRawData = new byte[FileInfo.RawSize + 100];

		if (!pInputFile->ReadBytes(FileInfo.pRawData, FileInfo.RawSize))
		{
			delete[] FileInfo.pRawData;
			FileInfo.pRawData = nullptr;
			return false;
		}

		return true;
	}


	bool ReadSubFileData (dat_subfileinfo_t& FileInfo, const mnf_header_t& Header, CFile* pInputFile)
	{
		dword OutputSize;
	
		if (!ReadSubFileRawData(FileInfo, Header, pInputFile)) return PrintError("Error: Failed to read raw data for DAT subfile!");

		if (FileInfo.UncompressedSize > INT_MAX) return PrintError("Error: Uncompressed size of DAT sub-file is too large (%u bytes)!", FileInfo.UncompressedSize);

		if (FileInfo.CompressType == 0)
		{
			FileInfo.pUncompressedData = FileInfo.pRawData;
			FileInfo.pRawData = nullptr;
			FileInfo.UncompressedSize = FileInfo.RawSize;
		}
		else if (FileInfo.CompressType == 1)
		{			
			FileInfo.pUncompressedData = new byte[FileInfo.UncompressedSize + 100];

			if (!InflateZlibBlock(FileInfo.pUncompressedData, OutputSize, FileInfo.UncompressedSize, FileInfo.pRawData, FileInfo.RawSize))
			{
				delete[] FileInfo.pUncompressedData;
				FileInfo.pUncompressedData = nullptr;
				OutputSize  = 0;
				return false;
			}
		}
		else if (FileInfo.CompressType == 2)
		{		
			FileInfo.pUncompressedData = new byte[FileInfo.UncompressedSize + 100];

			if (!InflateSnappyBlock(FileInfo.pUncompressedData, OutputSize, FileInfo.UncompressedSize, FileInfo.pRawData, FileInfo.RawSize))
			{
				PrintError("Error: Failed to decompress the Snappy data!");
				delete[] FileInfo.pUncompressedData;	 
				FileInfo.pUncompressedData = nullptr;
				OutputSize = 0;
				return false;
			}
		}
		else
		{
			PrintError("Error: Unknown compression type %u found in DAT sub-file!", (dword) FileInfo.CompressType);
			return false;
		}

		return ParseSubFileRawData(FileInfo, Header);
	}


};