#pragma once

#include "../EsoCommon.h"

namespace eso {

	typedef unsigned int uint;
	typedef unsigned long ulong;

	//typedef int __stdcall OodleLZ_Compress_Func(uint fmt, byte* buffer, long bufferSize, byte* outputBuffer, ulong level, uint unused1, uint unused2, uint unused3);
	typedef int __stdcall OodleLZ_Compress_Func(uint fmt, byte* buffer, int bufferSize, byte* outputBuffer, int level, void* unused1, void* unused2, void* unused3);

	//typedef int __stdcall OodleLZ_Decompress_Func(byte* buffer, long bufferSize, byte* outputBuffer, long outputBufferSize, uint a, uint b, ulong c, uint d, uint e, uint f, uint g, uint h, uint i, uint threadModule);
	typedef int __stdcall OodleLZ_Decompress_Func(byte* buffer, int bufferSize, byte* outputBuffer, int outputBufferSize, int a, int b, int c, void* d, void* e, void* f, void* g, void* h, void* i, int threadModule);

	extern OodleLZ_Compress_Func*   g_OodleCompressFunc;
	extern OodleLZ_Decompress_Func* g_OodleDecompressFunc;


	bool LoadOodleLib();

}
