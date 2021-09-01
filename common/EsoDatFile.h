#ifndef __ESODATFILE_H
#define __ESODATFILE_H


#include "esocommon.h"
#include "EsoFile.h"


namespace eso {


	struct mnf_header_t;

	struct dat_subfileinfo_t 
	{
		std::string Filename;
		byte		ArchiveIndex;
		byte		CompressType;
		size_t		Offset;
		size_t		RawSize;
		size_t		UncompressedSize;
		byte*		pRawData;
		byte*		pUncompressedData;
		bool		DeletePtrs;

		dword		NullByte;
		dword		DataSize1;
		byte*		pData1;
		dword		DataSize2;		
		byte*		pData2;

		byte*		pFileDataStart;
		dword		FileDataSize;

		//byte*		pFileDataStartV3;
		//dword		FileDataSizeV3;
		//byte*		pFooterV3;
		//dword		FooterSizeV3;
		//dword		HeaderSizeV3;

		byte*		pOoodleCompressedData;
		dword		OodleCompressedSize;
		byte*		pOodleDecompressed;


		dat_subfileinfo_t() :
			ArchiveIndex(0),
			CompressType(0),
			Offset(0),
			RawSize(0),
			UncompressedSize(0),
			pRawData(nullptr),
			pUncompressedData(nullptr),
			DeletePtrs(false),
			NullByte(0),
			DataSize1(0),
			pData1(nullptr),
			DataSize2(0),
			pData2(nullptr),
			pFileDataStart(nullptr),
			pOoodleCompressedData(nullptr),
			OodleCompressedSize(0),
			pOodleDecompressed(nullptr)
		{
		}


		~dat_subfileinfo_t() 
		{
			if (DeletePtrs)
			{
				delete[] pRawData;
				delete[] pUncompressedData;
			}

			if (pOodleDecompressed) {
				delete[] pOodleDecompressed;
				pOodleDecompressed = nullptr;
			}
		}

	};


	bool ReadSubFileRawData (dat_subfileinfo_t& FileInfo, const mnf_header_t& Header, CFile* pInputFile = nullptr);
	bool ReadSubFileData    (dat_subfileinfo_t& FileInfo, const mnf_header_t& Header, CFile* pInputFile = nullptr);

};


#endif