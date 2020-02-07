
#include "stdafx.h"
#include "oodle.h"


namespace eso {

	OodleLZ_Compress_Func*   g_OodleCompressFunc   = nullptr;
	OodleLZ_Decompress_Func* g_OodleDecompressFunc = nullptr;


	bool LoadOodleLib() 
	{
		HINSTANCE mod = LoadLibrary("oo2core_8_win64.dll");

		if (mod == NULL) return PrintError("Failed to load Oodle DLL!");

		g_OodleCompressFunc = (OodleLZ_Compress_Func *) GetProcAddress(mod, "OodleLZ_Compress");
		g_OodleDecompressFunc = (OodleLZ_Decompress_Func *) GetProcAddress(mod, "OodleLZ_Decompress");

		if (!g_OodleCompressFunc || !g_OodleDecompressFunc) PrintError("Failed to find Oodle compress/decompress functions in DLL!");

		return true;
	}

}