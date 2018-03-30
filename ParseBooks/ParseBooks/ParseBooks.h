#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <algorithm>
#include "../../common/EsoCommon.h"
#include "../../common/EsoFile.h"
#include "../../common/EsoLangFile.h"


namespace eso 
{


	struct bookdata_t
	{
		dword Index;
		std::string Title;
		std::string Text;
	};

	struct questdata_t
	{
		dword Id;
		std::string Name;
		std::string InternalName;
		std::string Journal;
		dword ZoneId;
		std::string ZoneName;
		dword Type;

	};

};