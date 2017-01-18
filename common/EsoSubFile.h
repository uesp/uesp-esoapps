#pragma once

#include "EsoCommon.h"

namespace eso
{


	struct eso_indexsubfile_data_t
	{
		dword Index;
		dword Offset;
	};



	class CEsoSubFileDataRecord
	{

	public:
		dword m_UncompressedSize1;
		dword m_UncompressedSize2;
		dword m_CompressedSize;
		byte* m_pCompressedData;

		dword m_UncompressedSize;
		byte* m_pUncompressedData;

		dword m_Index;
		dword m_OrigFileOffset;

	public:

		CEsoSubFileDataRecord() :
			m_CompressedSize(0),
			m_pCompressedData(nullptr),
			m_UncompressedSize(0),
			m_pUncompressedData(nullptr),
			m_UncompressedSize1(0),
			m_UncompressedSize2(0),
			m_Index(0),
			m_OrigFileOffset(0)
		{
		}


		~CEsoSubFileDataRecord()
		{
			Destroy();
		}


		void Destroy()
		{
			if (m_pCompressedData != nullptr)
			{
				delete[] m_pCompressedData;
				m_pCompressedData = nullptr;
			}

			if (m_pUncompressedData != nullptr)
			{
				delete[] m_pUncompressedData;
				m_pUncompressedData = nullptr;
			}

			m_CompressedSize = 0;
			m_UncompressedSize = 0;
		}


		bool Parse(byte* pData, const size_t Size, size_t& Pos)
		{
			if (Pos >= Size || Size - Pos < 12) return PrintError("Not enough data for subfile data header!");

			pData += Pos;

			m_UncompressedSize1 = ConvertMotorolaBytesToDword(pData);
			m_UncompressedSize2 = ConvertMotorolaBytesToDword(pData + 4);
			m_CompressedSize = ConvertMotorolaBytesToDword(pData + 8);

			if (m_CompressedSize + 12 > Size) return PrintError("Not enough data for uncompressed subfile data!");
			if (m_UncompressedSize1 == 0 || m_CompressedSize == 0) return PrintError("Empty compressed file found (skipping rest of empty data)!");

			m_pCompressedData = new byte[m_CompressedSize + 4];
			memcpy(m_pCompressedData, pData + 12, m_CompressedSize);

			//PrintError("\tFound compressed data with %u bytes.", m_CompressedSize);

			size_t MaxOutputSize = m_UncompressedSize1 + 16;
			m_UncompressedSize = MaxOutputSize;
			m_pUncompressedData = new byte[MaxOutputSize + 1];

			bool Result = InflateZlibBlock(m_pUncompressedData, m_UncompressedSize, MaxOutputSize, m_pCompressedData, m_CompressedSize, false);

			if (!Result)
			{
				PrintError("\t\tError uncompressing stream (%u / %u / %u bytes)!", m_UncompressedSize, m_UncompressedSize1, m_UncompressedSize2);
			}
			else if (m_UncompressedSize1 != m_UncompressedSize2)
			{
				PrintError("\t\tUncompressed stream (%u / %u / %u bytes)", m_UncompressedSize, m_UncompressedSize1, m_UncompressedSize2);
			}

			Pos += 12 + m_CompressedSize;
			return true;
		}


		bool Save(const std::string Filename)
		{
			if (m_pUncompressedData == nullptr || m_UncompressedSize == 0) return false;

			FILE* pFile = fopen(Filename.c_str(), "wb");
			if (pFile == nullptr) return PrintError("Failed to open file '%s' for writing!", Filename.c_str());

			bool Result = true;
			if (fwrite(m_pUncompressedData, 1, m_UncompressedSize, pFile) != m_UncompressedSize) Result = false;

			fclose(pFile);
			return Result;
		}


		bool SaveCombined(FILE* pFile, const int Index)
		{
			if (m_pUncompressedData == nullptr || m_UncompressedSize == 0) return false;
			size_t BytesWritten;

			BytesWritten = fwrite("####", 1, 4, pFile);
			if (BytesWritten != 4) return false;

			if (!WriteMotorolaDword(pFile, Index)) return false;
			if (!WriteMotorolaDword(pFile, m_UncompressedSize1)) return false;
			if (!WriteMotorolaDword(pFile, m_UncompressedSize2)) return false;
			if (!WriteMotorolaDword(pFile, m_CompressedSize)) return false;
			if (!WriteMotorolaDword(pFile, m_Index)) return false;
			if (!WriteMotorolaDword(pFile, m_OrigFileOffset)) return false;
			if (!WriteMotorolaDword(pFile, m_UncompressedSize)) return false;

			BytesWritten = fwrite(m_pUncompressedData, 1, m_UncompressedSize, pFile);
			if (BytesWritten != m_UncompressedSize) return false;

			return true;
		}


	};




	class CEsoSubFileDataFile
	{
	public:

		dword m_MagicBytes;
		dword m_Unknown1;
		dword m_NumRecords;
		dword m_Unknown2;
		std::vector<CEsoSubFileDataRecord *> m_Records;

	public:

		CEsoSubFileDataFile() :
			m_MagicBytes(0xFAFAEBEB),
			m_Unknown1(0x00000011),
			m_NumRecords(0),
			m_Unknown2(0)
		{
		}


		~CEsoSubFileDataFile()
		{
			Destroy();
		}


		size_t GetNumSubFiles() const { return m_Records.size(); }


		void Destroy()
		{

			for (auto &pRecord : m_Records)
			{
				delete pRecord;
			}

			m_Records.clear();
			m_NumRecords = 0;
		}


		/* For testing only */
		bool Load(const std::string Filename)
		{
			FILE* pFile = fopen(Filename.c_str(), "rb");
			if (pFile == nullptr) return PrintError("Failed to open ESOSubFile data file for reading!");

			fseek(pFile, 0, SEEK_END);
			long FileSize = ftell(pFile);
			fseek(pFile, 0, SEEK_SET);

			byte* pFileData = new byte[FileSize + 100];

			long BytesRead = fread(pFileData, 1, FileSize, pFile);

			fclose(pFile);

			if (BytesRead != FileSize)
			{
				delete[] pFileData;
				return PrintError("Failed to read ESOSubFile data file!");
			}

			bool Result = Parse(pFileData, (size_t)FileSize);

			delete[] pFileData;
			return Result;
		}


		bool ParseHeader(byte* pData, const size_t Size)
		{
			if (Size < 16) return PrintError("Not enough data for subfile header (%08X)!", Size);

			m_MagicBytes = ConvertMotorolaBytesToDword(pData);
			m_Unknown1 = ConvertMotorolaBytesToDword(pData + 4);
			m_NumRecords = ConvertMotorolaBytesToDword(pData + 8);
			m_Unknown2 = ConvertMotorolaBytesToDword(pData + 12);

			//PrintError("Loading subfile data: 0x%08X, 0x%08X, %u records, 0x%08X", m_MagicBytes, m_Unknown1, m_NumRecords, m_Unknown2);
			return true;
		}


		bool ParseFileData(byte* pData, const size_t Size, size_t& Pos)
		{
			if (Pos >= Size || Size - Pos < 12) return PrintError("Not enough data for record header (%08X / %08X)!", Pos, Size);
			//PrintError("Parsing subfile at %u (%u)...", Pos, Size);

			CEsoSubFileDataRecord* pRecord = new CEsoSubFileDataRecord();

			if (!pRecord->Parse(pData, Size, Pos))
			{
				delete pRecord;
				return false;
			}

			m_Records.push_back(pRecord);

			return true;
		}


		bool Parse(byte* pData, const size_t Size)
		{
			size_t Pos = 0;

			if (!ParseHeader(pData, Size)) return false;

			Pos = 16;

			while (Pos < Size)
			{
				if (!ParseFileData(pData, Size, Pos)) return false;
			}

			if (Pos < Size) PrintError("Warning: %u extra bytes left over at end of data subfile!", Size - Pos);

			return true;
		}


		bool SaveFiles(const std::string Path)
		{
			int Index = 0;

			PrintError("Saving uncompressed record data to seperate files in '%s'...", Path.c_str());

			for (auto &pRecord : m_Records)
			{
				++Index;

				if (Index % 1000 == 0)
				{
					PrintError("Saved %d of %d files...", Index, m_Records.size());
				}

				char Buffer[16];
				_snprintf(Buffer, 10, "%d", Index);

				std::string Filename = Path;
				Filename += Buffer;
				Filename += ".dat";

				pRecord->Save(Filename);
			}

			return true;
		}


		bool SaveCombinedFile(const std::string Filename)
		{
			FILE* pFile = fopen(Filename.c_str(), "wb");
			if (pFile == nullptr) return PrintError("Failed to open file '%s' for writing!", Filename.c_str());

			PrintError("Saving uncompressed record data to combined file '%s'...", Filename.c_str());

			int Index = 0;

			if (!WriteMotorolaDword(pFile, m_MagicBytes)) return false;
			if (!WriteMotorolaDword(pFile, m_Unknown1)) return false;
			if (!WriteMotorolaDword(pFile, m_NumRecords)) return false;
			if (!WriteMotorolaDword(pFile, m_Unknown2)) return false;

			for (auto &pRecord : m_Records)
			{
				++Index;
				pRecord->SaveCombined(pFile, Index);
			}

			fclose(pFile);
			return true;
		}


		void UpdateIndex(std::vector<eso_indexsubfile_data_t>& Records)
		{
			for (size_t i = 0; i < Records.size() && i < m_Records.size(); ++i)
			{
				m_Records[i]->m_Index = Records[i].Index;
				m_Records[i]->m_OrigFileOffset = Records[i].Offset;
			}
		}


	};




	class CEsoSubFileIndexFile
	{
	public:

		dword m_MagicBytes;
		dword m_Unknown1;
		word  m_Unknown2;
		dword m_Unknown3;
		dword m_Unknown4;
		dword m_Unknown5;
		dword m_NumRecords;

		std::vector<eso_indexsubfile_data_t> m_Records;

	public:

		CEsoSubFileIndexFile() :
			m_MagicBytes(0xFBFBECEC),
			m_Unknown1(0x00000004),
			m_Unknown2(0x0001),
			m_Unknown3(0x00000011),
			m_Unknown4(0),
			m_Unknown5(0),
			m_NumRecords(0)
		{
		}


		~CEsoSubFileIndexFile()
		{
			Destroy();
		}


		void Destroy()
		{
			m_Records.clear();
			m_NumRecords = 0;
		}


		size_t GetNumRecords() const { return m_Records.size(); }

		std::vector<eso_indexsubfile_data_t>& GetRecords() { return m_Records; }


		/* For testing only */
		bool Load(const std::string Filename)
		{
			FILE* pFile = fopen(Filename.c_str(), "rb");
			if (pFile == nullptr) return PrintError("Failed to open ESOSubFile index file for reading!");

			fseek(pFile, 0, SEEK_END);
			long FileSize = ftell(pFile);
			fseek(pFile, 0, SEEK_SET);

			byte* pFileData = new byte[FileSize + 100];

			long BytesRead = fread(pFileData, 1, FileSize, pFile);

			fclose(pFile);

			if (BytesRead != FileSize)
			{
				delete[] pFileData;
				return PrintError("Failed to read ESOSubFile index file!");
			}

			bool Result = Parse(pFileData, (size_t)FileSize);

			delete[] pFileData;
			return Result;
		}


		bool ParseHeader(byte* pData, const size_t Size)
		{
			if (Size < 16) return PrintError("Not enough data for index subfile header (%08X)!", Size);

			m_MagicBytes = ConvertMotorolaBytesToDword(pData);
			m_Unknown1 = ConvertMotorolaBytesToDword(pData + 4);
			m_Unknown2 = ConvertMotorolaBytesToWord(pData + 8);
			m_Unknown3 = ConvertMotorolaBytesToDword(pData + 10);
			m_Unknown4 = ConvertMotorolaBytesToDword(pData + 14);
			m_Unknown5 = ConvertMotorolaBytesToDword(pData + 18);
			m_NumRecords = ConvertMotorolaBytesToDword(pData + 22);

			PrintError("Loading subfile index: 0x%08X, 0x%08X, %u records, 0x%08X", m_MagicBytes, m_Unknown1, m_NumRecords, m_Unknown2);

			return true;
		}


		bool Parse(byte* pData, const size_t Size)
		{
			size_t Pos = 0;
			eso_indexsubfile_data_t Temp;

			if (!ParseHeader(pData, Size)) return false;

			Pos = 26;
			m_Records.reserve(m_NumRecords);

			while (Pos + 8 <= Size)
			{
				Temp.Index = ConvertMotorolaBytesToDword(pData + Pos);
				Temp.Offset = ConvertMotorolaBytesToDword(pData + Pos + 4);
				m_Records.push_back(Temp);

				Pos += 8;
			}

			if (Pos < Size) PrintError("Warning: %u extra bytes left over at end of index subfile!", Size - Pos);
			if (m_NumRecords != m_Records.size()) PrintError("Warning: Record count mismatch in index subfile (%u / %u)!", m_NumRecords, m_Records.size());

			return true;
		}


	};


};