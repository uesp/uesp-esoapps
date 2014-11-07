#ifndef __ESOFILE_H
#define __ESOFILE_H


#include "EsoCommon.h"


namespace eso {


	class CBaseFile
	{
	protected:

	public:
		CBaseFile();
		virtual ~CBaseFile();
		virtual void Destroy();

		virtual void Close() { Destroy(); }

		virtual fpos_t GetSize (void) = 0;

		virtual bool IsEOF (void) const = 0;
		
		virtual bool ReadDword64 (dword64& Output, const bool LittleEndian = true) = 0;
		virtual bool ReadFloat   (float&   Output, const bool LittleEndian = true) = 0;
		virtual bool ReadDword   (dword&   Output, const bool LittleEndian = true) = 0;
		virtual bool ReadWord    (word&    Output, const bool LittleEndian = true) = 0;
		virtual bool ReadByte    (byte&    Output) = 0;
		virtual bool ReadBytes   (byte*   pOutput, const size_t Count) = 0;

		virtual bool   Seek (const fpos_t Pos, const int SeekType = SEEK_SET) = 0;
		virtual fpos_t Tell (void) = 0;

	};


	class CFile : public CBaseFile
	{
	protected:
		FILE* m_pFile;
		bool  m_CloseFile;
		

	public:
		CFile();
		CFile(FILE* pFile, const bool CloseFile = false);
		virtual ~CFile() { Destroy(); }
		virtual void Destroy();

		virtual fpos_t GetSize (void);
		virtual FILE* GetFile (void) { return m_pFile; }

		virtual bool Flush (void) { if (m_pFile) return fflush(m_pFile) == 0; return false;}

		virtual bool IsEOF  (void) const;
		virtual bool IsOpen (void) const { return m_pFile != nullptr; }

		bool Open (std::string Filename, std::string Mode);

		virtual bool Printf  (const char* pString, ...);
		virtual bool VPrintf (const char* pString, va_list Args);

		static byte* ReadAll(const char* pFilename, fpos_t& FileSize);
		byte* ReadAll(fpos_t& FileSize);

		virtual bool ReadDword64 (dword64& Output, const bool LittleEndian = true);
		virtual bool ReadFloat   (float&   Output, const bool LittleEndian = true);
		virtual bool ReadDword   (dword&   Output, const bool LittleEndian = true);
		virtual bool ReadWord    (word&    Output, const bool LittleEndian = true);
		virtual bool ReadByte    (byte&    Output);
		virtual bool ReadBytes   (byte*   pOutput, const size_t Count);

		virtual bool   Seek (const fpos_t Pos, const int SeekType = SEEK_SET);
		virtual fpos_t Tell (void);

		void SetFile (FILE* pFile, const bool CloseFile = false);
		
		virtual bool WriteBytes (const byte* pData, const size_t Size);
		virtual bool WriteChar (const char Data);
	};



	class CMemoryFile : public CBaseFile
	{
	protected:
		byte*	m_pBuffer;
		size_t	m_BufferSize;
		size_t	m_Pos;
		bool	m_DeleteBuffer;
		

	public:
		CMemoryFile();
		CMemoryFile(byte* pBuffer, const size_t MaxSize, const bool DeleteBuffer = false);
		virtual ~CMemoryFile() { Destroy(); }
		virtual void Destroy();

		virtual fpos_t GetSize (void);

		virtual bool IsEOF (void) const;

		virtual bool ReadDword64 (dword64& Output, const bool LittleEndian = true);
		virtual bool ReadFloat   (float&   Output, const bool LittleEndian = true);
		virtual bool ReadDword   (dword&   Output, const bool LittleEndian = true);
		virtual bool ReadWord    (word&    Output, const bool LittleEndian = true);
		virtual bool ReadByte    (byte&    Output);
		virtual bool ReadBytes   (byte*   pOutput, const size_t Count);

		virtual bool   Seek (const fpos_t Pos, const int SeekType = SEEK_SET);
		virtual fpos_t Tell (void) { return (fpos_t) m_Pos; }

		void SetBuffer (byte* pBuffer, const size_t MaxSize, const bool DeleteBuffer = false);
	};

};

#endif
