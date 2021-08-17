#ifndef __ESOMNFBLOCK_H
#define __ESOMNFBLOCK_H


#include "EsoCommon.h"
#include "EsoFile.h"


namespace eso {


	const size_t ZOSFT_DATA_OVERSIZE = 32;
	const size_t ZOSFT_BLOCK_MAXDATACOUNT = 3;


	struct mnf_block_data_t
	{
		dword	UncompressedSize;
		dword	CompressedSize;
		byte*	pCompressedData;
		byte*	pUncompressedData;

		mnf_block_data_t() : 
					UncompressedSize(0), CompressedSize(0),
					pCompressedData(nullptr), pUncompressedData(nullptr)
		{ }

		~mnf_block_data_t() 
		{ 
			Destroy(); 
		}

		void Destroy()
		{
			UncompressedSize = 0;
			CompressedSize = 0;
			delete[] pCompressedData;
			delete[] pUncompressedData;
			pCompressedData = nullptr;
			pUncompressedData = nullptr;
		}

	};


	class CMnfBlock
	{

	protected:
		bool	m_LittleEndian;
		bool	m_ReadBlockID;

		mnf_block_data_t	m_Data[ZOSFT_BLOCK_MAXDATACOUNT];
		size_t				m_DataCount;


	protected:

		virtual bool ReadData     (CBaseFile &File);
		virtual bool ReadHeader   (CBaseFile &File) = 0;
		virtual bool ReadRawData  (CBaseFile &File, mnf_block_data_t& Data);

		virtual bool ParseRawData      (mnf_block_data_t& Data) { return true; }
		virtual bool UncompressRawData (mnf_block_data_t& Data) { return true; }


	public:
		CMnfBlock(const bool LittleEndian = true);
		virtual ~CMnfBlock();
		virtual void Destroy();

		static CMnfBlock* CreateBlock (const word BlockID);

		std::string GuessFileExtension (const size_t Index);

		mnf_block_data_t* GetData (const size_t Index) { return (Index >= 0 && Index < m_DataCount) ? &m_Data[Index] : nullptr; }

		virtual bool HasData() const { return true;  }

		virtual bool Read (CBaseFile &File, const bool ReadBlockID = true);

		bool SaveBlock (const size_t Index, const char* pFilename);

	};


	

	const size_t ZOSFT_BLOCK3_HEADER_SIZE = 0x12;
	const size_t ZOSFT_BLOCK3_DATACOUNT = 3;


	struct mnf_block3_header_t
	{
		word	BlockID;
		dword	Unknown1;
		dword	RecordCount1a;
		dword	RecordCount1b;
		dword	RecordCount23;
	};


	class CMnfBlock3 : public CMnfBlock
	{
		mnf_block3_header_t	m_Header;
		

	protected:
		virtual bool ReadData   (CBaseFile &File);
		virtual bool ReadHeader (CBaseFile &File);

		virtual bool UncompressRawData (mnf_block_data_t& Data);


	public:
		CMnfBlock3(const bool LittleEndian = true, const bool ReadBlockID = true);
		virtual ~CMnfBlock3();
		virtual void Destroy();

		mnf_block3_header_t& GetHeader (void) { return m_Header; }

		virtual bool HasData() const { return m_Header.RecordCount1a != 0 || m_Header.RecordCount1b != 0 || m_Header.RecordCount23 != 0; }

	};




	const size_t ZOSFT_BLOCK0_DATACOUNT = 2;
	const size_t ZOSFT_BLOCK0_HEADER_SIZE = 4;


	struct zosft_block0_header_t
	{
		word	BlockID;
		word	Unknown1;
	};


	class CMnfBlock0 : public CMnfBlock
	{
		zosft_block0_header_t	m_Header;


	protected:
		virtual bool ReadHeader   (CBaseFile &File);
		virtual bool ReadRawData  (CBaseFile &File, mnf_block_data_t& Data);
		virtual bool ParseRawData (mnf_block_data_t& Data);


	public:
		CMnfBlock0(const bool LittleEndian = true, const bool ReadBlockID = true);
		virtual ~CMnfBlock0();
		virtual void Destroy();

		zosft_block0_header_t& GetHeader (void) { return m_Header; }

	};

};


#endif