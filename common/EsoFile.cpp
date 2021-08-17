

#include "EsoFile.h"
#include <stdarg.h>


namespace eso {


	CBaseFile::CBaseFile()
	{
	}


	CBaseFile::~CBaseFile()
	{
		Destroy();
	}


	void CBaseFile::Destroy()
	{
	}





	CFile::CFile() :
			m_pFile(nullptr),
			m_CloseFile(false)
	{
	}


	CFile::CFile(FILE* pFile, const bool CloseFile) :
			m_pFile(pFile),
			m_CloseFile(CloseFile)
	{
	}


	void CFile::Destroy()
	{
		if (m_pFile && m_CloseFile) fclose(m_pFile);
		m_pFile = nullptr;

		CBaseFile::Destroy();
	}


	fpos_t CFile::GetSize (void)
	{
		fpos_t CurPos;
		fpos_t FileSize = 0;

		if (m_pFile == nullptr) 
		{
			PrintError("Error: File not open in CFile::GetSize()!");
			return 0;
		}

		if (fgetpos(m_pFile, &CurPos) != 0) 
		{
			PrintError("Error: Failed to get current position in file!");
			return 0;
		}

		if (_fseeki64(m_pFile, 0, SEEK_END) != 0)
		{
			PrintError("Error: Failed to get current position in file!");
			return 0;
		}

		if (fgetpos(m_pFile, &FileSize) != 0)
		{
			PrintError("Error: Failed to get current position in file!");
			FileSize = 0;
		}
				
		if (fsetpos(m_pFile, &CurPos) != 0) PrintError("Error: Failed to reset file position in CFile::GetSize()!");

		return FileSize;
	}


	bool CFile::IsEOF (void) const 
	{
		if (m_pFile == nullptr) return true;
		return feof(m_pFile) != 0;
	}


	bool CFile::Open (std::string Filename, std::string Mode)
	{
		Destroy();

		m_CloseFile = true;
		PrintLog("Opening file '%s' in mode '%s'...", Filename.c_str(), Mode.c_str());

		m_pFile = fopen(Filename.c_str(), Mode.c_str());
		if (m_pFile == nullptr) return PrintError("Error: Failed to open file '%s' in mode '%s'!", Filename.c_str(), Mode.c_str());

		return true;
	}


	bool CFile::Printf (const char* pString, ...)
	{
		va_list Args;

		if (m_pFile == nullptr) return PrintError("Error: No file defined to write to!");
		
		va_start(Args, pString);
		int Result = vfprintf(m_pFile, pString, Args);
		va_end(Args);

		return Result >= 0;
	}


	bool CFile::VPrintf (const char* pString, va_list Args)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to write to!");
		int Result = vfprintf(m_pFile, pString, Args);
		return Result >= 0;
	}


	byte* CFile::ReadAll(const char* pFilename, fpos_t& FileSize)
	{
		CFile File;
		if (!File.Open(pFilename, "rb")) return nullptr;
		return File.ReadAll(FileSize);
	}


	byte* CFile::ReadAll(fpos_t& FileSize)
	{
		byte* pFileData;

		if (m_pFile == nullptr) 
		{
			PrintError("Error: No file defined to read from!");
			return nullptr;
		}

		if (!Seek(0, SEEK_SET)) return nullptr;
		FileSize = GetSize();
		if (FileSize <= 0) return nullptr;

		if (FileSize >= INT_MAX)
		{
			PrintError("Error: Exceeded maximum size of file that can be loaded at once!");
			return nullptr;
		}

		pFileData = new byte[(size_t)FileSize + 100];

		if (!ReadBytes(pFileData, (size_t)FileSize))
		{
			delete[] pFileData;
			return nullptr;
		}

		pFileData[FileSize] = 0;
		return pFileData;
	}
	

	bool CFile::ReadDword64 (dword64& Output, const bool LittleEndian)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread(&Output, 1, sizeof(dword64), m_pFile);
		if (ReadBytes != sizeof(dword64)) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, sizeof(dword64), Tell());
		if (!LittleEndian) Output = Dword64Swap(Output);
		return true;
	}


	bool CFile::ReadFloat (float& Output, const bool LittleEndian)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread(&Output, 1, sizeof(float), m_pFile);
		if (ReadBytes != sizeof(float)) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, sizeof(float), Tell());
		if (!LittleEndian) Output = FloatSwap(Output);
		return true;
	}


	bool CFile::ReadDword (dword& Output, const bool LittleEndian)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread(&Output, 1, sizeof(dword), m_pFile);
		if (ReadBytes != sizeof(dword)) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, sizeof(dword), Tell());
		if (!LittleEndian) Output = DwordSwap(Output);
		return true;
	}


	bool CFile::ReadWord (word&  Output, const bool LittleEndian)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread(&Output, 1, sizeof(word), m_pFile);
		if (ReadBytes != sizeof(word)) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, sizeof(word), Tell());
		if (!LittleEndian) Output = WordSwap(Output);
		return true;
	}


	bool CFile::ReadByte (byte& Output)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread(&Output, 1, 1, m_pFile);
		if (ReadBytes != 1) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, 1, Tell());
		return true;
	}


	bool CFile::ReadBytes (byte* pOutput, const size_t Count)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t ReadBytes = fread((char *)pOutput, 1, Count, m_pFile);
		if (ReadBytes != Count) return PrintError("Error: Only read %u of %u bytes from position 0x%llX!", ReadBytes, Count, Tell());
		return true;
	}


	void CFile::SetFile (FILE* pFile, const bool CloseFile) 
	{ 
		Destroy();

		m_pFile = pFile;
		m_CloseFile = CloseFile; 
	}


	bool CFile::Seek (const fpos_t Pos, const int SeekType)
	{
		if (m_pFile == nullptr) return false;

		if (SeekType == SEEK_SET)
		{
			if (fsetpos(m_pFile, &Pos) != 0) return PrintError("Error: Failed to seek to position 0x%016llX from start of file!", Pos);
		}
		else if (SeekType == SEEK_END)
		{
			if (_fseeki64(m_pFile, Pos, SEEK_END) != 0) return PrintError("Error: Failed to seek to position 0x%016llX from end of file!", Pos);
		}
		else if (SeekType == SEEK_CUR)
		{
			if (_fseeki64(m_pFile, Pos, SEEK_CUR) != 0) return PrintError("Error: Failed to seek to position 0x%016llX relative to current file position!", Pos);
		}
		else
		{
			PrintError("Error: Unknown seek type %d received in CFile::Seek()!", SeekType);
			return false;
		}

		return true;
	}


	fpos_t CFile::Tell (void)
	{
		fpos_t Pos = 0;

		if (m_pFile == nullptr) 
		{
			PrintError("Error: No file defined to read from!");
			return 0;
		}

		if (fgetpos(m_pFile, &Pos) != 0) PrintError("Error: Failed to get current file position!");
		return Pos;
	}


	bool CFile::WriteBytes (const byte* pData, const size_t Size)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");

		size_t WriteBytes = fwrite(pData, 1, Size, m_pFile);
		if (WriteBytes != Size) return PrintError("Error: Only wrote %u of %u bytes to file!", WriteBytes, Size);

		return true;
	}


	bool CFile::WriteChar (const char Data)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		
		return (fputc(Data, m_pFile) != EOF);
	}


	bool CFile::WriteDword (dword Output, const bool LittleEndian)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		if (!LittleEndian) Output = DwordSwap(Output);
		size_t WriteBytes = fwrite(&Output, 1, sizeof(dword), m_pFile);
		if (WriteBytes != sizeof(dword)) return PrintError("Error: Only wrote %u of %u bytes at position 0x%llX!", WriteBytes, sizeof(dword), Tell());
		return true;
	}


	bool CFile::WriteString (const std::string Data)
	{
		if (m_pFile == nullptr) return PrintError("Error: No file defined to read from!");
		size_t WriteBytes = fwrite(Data.c_str(), 1, Data.length(), m_pFile);
		if (WriteBytes != Data.length()) return PrintError("Error: Only wrote %u of %u bytes at position 0x%llX!", WriteBytes, Data.length(), Tell());
		return true;
	}
	

	CMemoryFile::CMemoryFile() :
					m_pBuffer(nullptr),
					m_BufferSize(0),
					m_DeleteBuffer(false),
					m_Pos(0)
	{
	}

	CMemoryFile::CMemoryFile(byte* pBuffer, const size_t MaxSize, const bool DeleteBuffer) :
					m_pBuffer(pBuffer),
					m_BufferSize(MaxSize),
					m_DeleteBuffer(DeleteBuffer),
					m_Pos(0)
	{
	}


	void CMemoryFile::Destroy()
	{
		if (m_DeleteBuffer) delete[] m_pBuffer;
		m_pBuffer = nullptr;
		m_BufferSize = 0;
		m_Pos = 0;

		CBaseFile::Destroy();
	}


	fpos_t CMemoryFile::GetSize (void)
	{
		return m_BufferSize;
	}


	bool CMemoryFile::IsEOF (void) const 
	{
		return m_Pos >= m_BufferSize;
	}


	bool CMemoryFile::ReadDword64 (dword64& Output, const bool LittleEndian)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + sizeof(dword64) > m_BufferSize) 
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", sizeof(dword64), m_Pos);
		}

		memcpy((void *) &Output, m_pBuffer + m_Pos, sizeof(dword64));
		m_Pos += sizeof(dword64);
		if (!LittleEndian) Output = Dword64Swap(Output);
		return true;
	}


	bool CMemoryFile::ReadFloat (float& Output, const bool LittleEndian)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + sizeof(float) > m_BufferSize) 
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", sizeof(float), m_Pos);
		}

		memcpy((void *) &Output, m_pBuffer + m_Pos, sizeof(float));
		m_Pos += sizeof(float);
		if (!LittleEndian) Output = FloatSwap(Output);
		return true;
	}


	bool CMemoryFile::ReadDword (dword& Output, const bool LittleEndian)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + sizeof(dword) > m_BufferSize)
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", sizeof(dword), m_Pos);
		}

		memcpy((void *) &Output, m_pBuffer + m_Pos, sizeof(dword));
		m_Pos += sizeof(dword);
		if (!LittleEndian) Output = DwordSwap(Output);
		return true;
	}


	bool CMemoryFile::ReadWord (word&  Output, const bool LittleEndian)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + sizeof(word) > m_BufferSize) 
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", sizeof(word), m_Pos);
		}

		memcpy((void *) &Output, m_pBuffer + m_Pos, sizeof(word));
		m_Pos += sizeof(word);
		if (!LittleEndian) Output = WordSwap(Output);
		return true;
	}


	bool CMemoryFile::ReadByte (byte& Output)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + 1 > m_BufferSize) 
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", 1, m_Pos);
		}

		Output = m_pBuffer[m_Pos];
		m_Pos += 1;
		return true;
	}


	bool CMemoryFile::ReadBytes (byte* pOutput, const size_t Count)
	{
		if (m_pBuffer == nullptr) return PrintError("Error: No buffer set to read from!");

		if (m_Pos + Count > m_BufferSize)
		{
			m_Pos = m_BufferSize;
			return PrintError("Error: Buffer overflow reading %d bytes at offset 0x%08X!", Count, m_Pos);
		}

		memcpy((void *)pOutput, m_pBuffer + m_Pos, Count);
		m_Pos += Count;
		return true;
	}


	void CMemoryFile::SetBuffer (byte* pBuffer, const size_t MaxSize, const bool DeleteBuffer)
	{
		Destroy();

		m_pBuffer = pBuffer;
		m_BufferSize = MaxSize;
		m_Pos = 0;
	}


	bool CMemoryFile::Seek (const fpos_t Pos, const int SeekType)
	{
		if (m_pBuffer == nullptr) return false;

		if (SeekType == SEEK_SET)
		{
			if (Pos < 0 || Pos >= UINT_MAX) return PrintError("Error: Invalid buffer position 0x%016llX received in CMemoryFile::Seek()!", Pos);

			if (Pos >= m_BufferSize)
			{
				m_Pos = m_BufferSize;
				return PrintError("Error: Position 0x%016llX exceeds size of buffer!", Pos);
			}

			m_Pos = (size_t)Pos;
			return true;
		}
		else if (SeekType == SEEK_END)
		{
			if (Pos < 0 || Pos >= UINT_MAX) return PrintError("Error: Invalid buffer position 0x%016llX received in CMemoryFile::Seek()!", Pos);

			if (Pos >= m_BufferSize)
			{
				m_Pos = 0;
				return PrintError("Error: Position 0x%016llX exceeds size of buffer!", Pos);
			}

			m_Pos = m_BufferSize - (size_t)Pos;
			return true;
		}
		else if (SeekType == SEEK_CUR)
		{
			fpos_t NewPos = (fpos_t)m_Pos + Pos;

			if (NewPos < 0) 
			{
				m_Pos = 0;
				return PrintError("Error: Invalid buffer position 0x%016llX before start of buffer!", NewPos);
			}
			else if (NewPos >= m_BufferSize) 
			{
				m_Pos = m_BufferSize;
				return PrintError("Error: Invalid buffer position 0x%016llX past end of buffer!", NewPos);
			}

			m_Pos = (size_t) NewPos;

			return true;
		}

		PrintError("Error: Unknown seek type %d received in CMemoryFile::Seek()!", SeekType);
		return false;
	}




};
