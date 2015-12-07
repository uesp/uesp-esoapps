/*
	v0.13 - 
		- Added the "Check Log Now" menu
		- Added the "Send Log File.." menu
		- Log file is appended to and more things output to it
		- Fixed issue with some log entries not being output due to a "blank" entry in the uespLog.lua saved variable file

	v0.14?

	v0.15 - 21 August 2014
		- Added handling of split-line logs.
		- Checks for the "liveeu" path for AddOns if "live" is not found.

	v0.16 - November 2014
		- Added the "Check Now" button.
		- "Check Now" command ignores the enabled option.
		- Saved variable file is now written to a temporary file and then moved once the write is
		  complete in order to prevent write errors from blanking the file.
		- Original saved variable file is copied to uespLog.lua.old before each overwrite.
		- Auto-scrolls to end of console window on update.
		- HTTP send queue is now threaded to prevent delays/pauses in UI when sending 
		  large amounts of data.


	TODO:
		- Proper UI threading.

 */

#include "stdafx.h"
#include "AboutDlg.h"
#include "uespLogMonitor.h"
#include "uespLogMonitorDlg.h"
#include "afxdialogex.h"
#include <openssl/aes.h>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/dsa.h>
#include <openssl/pem.h>
#include <stdarg.h>
#include "OptionsDlg.h"


const std::string ulm_options_t::DEFAULT_FORMURL("content3.uesp.net/esolog/esolog.php");
const std::string ulm_options_t::DEFAULT_BACKUPDATAFILENAME("uespLog_backupData.txt");
const std::string ulm_options_t::DEFAULT_BACKUPCHARDATAFILENAME("uespLog_backupCharData.txt");
const std::string ulm_options_t::DEFAULT_CHARDATA_FORMURL("content3.uesp.net/esochardata/esochardata.php");

const char ULM_REGISTRY_SECTION_SETTINGS[] = "Settings";
const char ULM_REGISTRY_KEY_UPDATETIME[] = "UpdateTime";
const char ULM_REGISTRY_KEY_USELOGNAME[] = "UseLogName";
const char ULM_REGISTRY_KEY_CUSTOMLOGNAME[] = "CustomLogName";
const char ULM_REGISTRY_KEY_FORMURL[] = "FormURL";
const char ULM_REGISTRY_KEY_CHARDATAFORMURL[] = "CharDataFormURL";
const char ULM_REGISTRY_KEY_ENABLED[] = "Enabled";
const char ULM_REGISTRY_KEY_CHARDATAENABLED[] = "CharDataEnabled";
const char ULM_REGISTRY_KEY_SAVEDVARPATH[] = "SavedVarPath";
const char ULM_REGISTRY_KEY_LASTTIMESTAMP[] = "LastTimeStamp";
const char ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP[] = "LastBackupTimeStamp";
const char ULM_REGISTRY_KEY_LOGLEVEL[] = "LogLevel";
const char ULM_REGISTRY_KEY_BACKUPDATAFILENAME[] = "BackupDataFilename";
const char ULM_REGISTRY_KEY_BACKUPCHARDATAFILENAME[] = "BackupCharDataFilename";

const std::string ULM_LOGSTRING_JOIN("#STR#");
const int  ULM_LOGSTRING_MAXLENGTH = 1900;

const char ULM_SAVEDVAR_NAME[] = "uespLogSavedVars";
const char ULM_SAVEDVAR_FILENAME[] = "uespLog.lua";
const char ULM_SAVEDVAR_BASEPATH[] = "Elder Scrolls Online\\live\\SavedVariables\\";
const char ULM_SAVEDVAR_ALTBASEPATH[] = "Elder Scrolls Online\\liveeu\\SavedVariables\\";

const int ULM_SENDDATA_MAXPOSTSIZE = 100000;		/* Maximum desired size of post data in bytes */

const int ULM_TIMER_ID = 5566;


#ifdef _DEBUG
	#define new DEBUG_NEW
#endif


BEGIN_MESSAGE_MAP(CuespLogMonitorDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_CLOSE()
	ON_WM_QUERYDRAGICON()
	ON_COMMAND(IDCLOSE, &CuespLogMonitorDlg::OnClose)
	ON_COMMAND(ID_FILE_EXIT, &CuespLogMonitorDlg::OnFileExit)
	ON_COMMAND(IDCANCEL, &CuespLogMonitorDlg::OnCancel)
	ON_WM_TIMER()
	ON_COMMAND(ID_VIEW_OPTIONS, &CuespLogMonitorDlg::OnViewOptions)
	ON_WM_SIZE()
	ON_COMMAND(ID_FILE_SENDOTHERLOG, &CuespLogMonitorDlg::OnFileSendotherlog)
	ON_COMMAND(ID_FILE_CHECKLOGNOW, &CuespLogMonitorDlg::OnFileChecklognow)
	ON_BN_CLICKED(IDC_CHECKNOW_BUTTON, &CuespLogMonitorDlg::OnBnClickedChecknowButton)
END_MESSAGE_MAP()


void replaceAll(std::string& str, const std::string& from, const std::string& to)
{
	if (from.empty()) return;
	size_t start_pos = 0;

	while ((start_pos = str.find(from, start_pos)) != std::string::npos)
	{
		str.replace(start_pos, from.length(), to);
		start_pos += to.length();
	}
}


CuespLogMonitorDlg::CuespLogMonitorDlg(CWnd* pParent) :
	CDialogEx(CuespLogMonitorDlg::IDD, pParent),
	m_TimerId(0),
	m_LastLogFileSize(0),
	m_IsInTray(false),
	m_IsCheckingFile(false),
	m_hSendQueueThread(NULL),
	m_hSendQueueMutex(NULL),
	m_StopSendQueueThread(0),
	m_CharDataValidScreenShotCount(0)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);

	m_Options.SavedVarPath = FindSavedVarPath();

	m_pLuaState = luaL_newstate();
	luaL_openlibs(m_pLuaState);

	//std::string Test = EncodeLogDataForQuery("<Place the masking salve.>");
	//std::string Test = EncodeLogDataForQuery("event{ConversationUpdated::Option}  isImportant{false}  chosenBefore{false}  type{101}  optArg{0}  option{<Place the masking salve.>}  userName{Reorx}  end{}  ");
	//std::string Test = EncodeLogDataForQuery("event{ConversationUpdated::Option}  isImportant{false}  chosenBefore{false}  type{101}  optArg{0}  option{<Place the masking salve.\x1F\x48\x08\x1D\x5C\xD9\x5C\x93\x98\x5B\x59\x5E\xD4\x99\x5B\xDC\x9E\x1F\x48\x08\x19\x5B\x99\x1E\xDF\x48\x08");
	//eso::PrintLog("EncodeTest: '%s'", Test.c_str());
}


CuespLogMonitorDlg::~CuespLogMonitorDlg()
{
	DestroySendQueueThread();
	lua_close(m_pLuaState);
}

void CuespLogMonitorDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_LOGTEXT, m_LogText);
}


void CuespLogMonitorDlg::CreateTimer (void)
{
	if (m_TimerId > 0) DestroyTimer();
	m_TimerId = SetTimer(ULM_TIMER_ID, m_Options.UpdateTime * 1000, NULL);
}


void CuespLogMonitorDlg::DestroyTimer (void)
{
	if (m_TimerId < 0) return;
	KillTimer(m_TimerId);
	m_TimerId = 0;
}


bool CuespLogMonitorDlg::LuaIterateSimpleTable (const int StackIndex, ULM_LUA_TABLEITERATOR TableIteratorMethod, void* pUserData)
{
	std::string VarName;
	int index = StackIndex;

	if (StackIndex < 0) 
	{
		index = lua_gettop(m_pLuaState) + StackIndex + 1;
	}

	lua_pushnil(m_pLuaState); 
	
    while (lua_next(m_pLuaState, index) != 0)
	{
		int keyType = lua_type(m_pLuaState, -2);

			/* uses 'key' (at index -2) and 'value' (at index -1) */
		if (keyType == LUA_TSTRING) 
		{
			VarName = lua_tostring(m_pLuaState, -2);
			(this->*TableIteratorMethod)(VarName, pUserData);
		}
		else if (keyType == LUA_TNUMBER) 
		{
			VarName = std::to_string((long long) lua_tointeger(m_pLuaState, -2));
			(this->*TableIteratorMethod)(VarName, pUserData);
		}
		else
		{
			eso::PrintLog("LuaIterateSimpleTable(): Skipping table key with type %s", lua_type(m_pLuaState, -2));
		}

		lua_pop(m_pLuaState, 1);
    }

	return true;
}


bool CuespLogMonitorDlg::LuaIterateSimpleTableInOrder (const int StackIndex, ULM_LUA_TABLEITERATOR TableIteratorMethod, void* pUserData)
{
	std::string VarName;
	int index = StackIndex;
	int MaxValidIndex = 0;

	if (StackIndex < 0) 
	{
		index = lua_gettop(m_pLuaState) + StackIndex + 1;
	}

		/* Iterate array in numerical order first */
	int i = 1;

	while (true)
	{
		lua_pushinteger(m_pLuaState, i);
		lua_rawgeti(m_pLuaState, index, i);

		if (lua_isnil(m_pLuaState, -1)) {
			lua_pop(m_pLuaState, 2);
			break;
		}

		VarName = std::to_string((long long)i);
		(this->*TableIteratorMethod)(VarName, pUserData);

		lua_pop(m_pLuaState, 2);
		MaxValidIndex = i;
		++i;
	}

		/* Iterate all remaining keys */
	lua_pushnil(m_pLuaState);
	
    while (lua_next(m_pLuaState, index) != 0)
	{
		int keyType = lua_type(m_pLuaState, -2);

			/* uses 'key' (at index -2) and 'value' (at index -1) */
		if (keyType == LUA_TSTRING) 
		{
			VarName = lua_tostring(m_pLuaState, -2);
			(this->*TableIteratorMethod)(VarName, pUserData);
		}
			/* Skip integer index if already output */
		else if (keyType == LUA_TNUMBER) 
		{
			int Value = lua_tointeger(m_pLuaState, -2);
			
			if (Value > MaxValidIndex)
			{
				VarName = std::to_string(Value);
				(this->*TableIteratorMethod)(VarName, pUserData);
			}
		}
		else
		{
			VarName = "unknown";
			eso::PrintLog("LuaIterateSimpleTableInOrder(): Skipping table key with type %s", lua_type(m_pLuaState, -2));
			(this->*TableIteratorMethod)(VarName, pUserData);
		}

		lua_pop(m_pLuaState, 1);
    }

	return true;
}

bool CuespLogMonitorDlg::ParseSavedVarFirstLevel (const std::string VarName, void* pUserData)
{
	LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::ParseSavedVarUserName, nullptr);
	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarUserName (const std::string VarName, void* pUserData)
{
	if (VarName != "")
	{
		m_CurrentPlayerName = VarName;
		if (m_CurrentPlayerName[0] == '@') m_CurrentPlayerName.erase(0, 1);
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found data for user '%s' in saved variable data.", m_CurrentPlayerName.c_str());
	}
	else
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found data for blank user in saved variable data.");
	}

	LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::ParseSavedVarAccount, nullptr);
	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarDataSection (const std::string SectionName, ULM_LUA_TABLEITERATOR Method)
{
	lua_getfield(m_pLuaState, -1, SectionName.c_str());

	if (lua_isnil(m_pLuaState, -1)) 
	{
		PrintLogLine(ULM_LOGLEVEL_WARNING, "Warning: Failed to find the log section '%s'!", SectionName.c_str());
		lua_pop(m_pLuaState, 1);
		return false;
	}

	bool Result = (this->*Method)(SectionName, nullptr);
	lua_pop(m_pLuaState, 1);

	return Result;
}


bool CuespLogMonitorDlg::ParseSavedVarAccount (const std::string VarName, void* pUserData)
{
	PrintLogLine(ULM_LOGLEVEL_INFO, "Parsing data sections in saved variable log...");

	ParseSavedVarDataSection("globals",			&CuespLogMonitorDlg::ParseSavedVarGlobals);
	ParseSavedVarDataSection("all",				&CuespLogMonitorDlg::ParseSavedVarAll);
	ParseSavedVarDataSection("achievements",	&CuespLogMonitorDlg::ParseSavedVarAchievements);

	ParseSavedVarDataSection("charData", &CuespLogMonitorDlg::ParseSavedVarCharData);

	ParseSavedVarDataSection("info",			&CuespLogMonitorDlg::ParseSavedVarInfo);
	
	return true;
}


std::string CuespLogMonitorDlg::ParseSavedVarDataVersion()
{
	std::string Version;

	lua_getfield(m_pLuaState, -1, "version");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		return Version;
	}

	Version = lua_tostring(m_pLuaState, -1);
	lua_pop(m_pLuaState, 1);

	return Version;
}


__int64 CuespLogMonitorDlg::ParseTimeStampFromData (const std::string Data)
{
	size_t tsStartPos = Data.find("timeStamp{");
	if (tsStartPos == std::string::npos) return 0;

	size_t tsEndPos = Data.find("}", tsStartPos);
	if (tsEndPos == std::string::npos) return 0;

	std::string TimeStamp(Data, tsStartPos+10, tsEndPos-1);
	return ::_atoi64(TimeStamp.c_str());
}


bool CuespLogMonitorDlg::ParseSavedVarDataArray (CUlmLogDataArray& Output, const std::string Version)
{
	bool IsLastStringTruncated = false;
	bool IsStringTruncatedRight = false;
	bool IsStringTruncatedLeft = false;
	ulm_sectiondata_t LastTruncatedData;

	//Output.clear();
	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in log section!");
		return false;
	}

		/* Iterate array in numerical order */
	int i = 1;

	while (true)
	{
		lua_rawgeti(m_pLuaState, -1, i);

		if (lua_isnil(m_pLuaState, -1)) {
			lua_pop(m_pLuaState, 1);
			break;
		}

		if (lua_type(m_pLuaState, -1) == LUA_TSTRING) 
		{
			ulm_sectiondata_t NewData;
			NewData.Data = lua_tostring(m_pLuaState, -1);
			IsStringTruncatedLeft = false;
			IsStringTruncatedRight = false;

			if (eso::StringEndsWith(NewData.Data, ULM_LOGSTRING_JOIN))
			{
				IsStringTruncatedRight = true;
				NewData.Data.erase(NewData.Data.size() - ULM_LOGSTRING_JOIN.length());

				PrintLogLine(ULM_LOGLEVEL_DEBUG, "Found right truncated log string.");
			}

			if (NewData.Data.compare(0, ULM_LOGSTRING_JOIN.length(), ULM_LOGSTRING_JOIN) == 0)
			{
				IsStringTruncatedLeft = true;
				NewData.Data.erase(0, ULM_LOGSTRING_JOIN.length());
				PrintLogLine(ULM_LOGLEVEL_DEBUG, "Found left truncated log string.");
			}
			 
			if (!IsLastStringTruncated && IsStringTruncatedRight)
			{
				LastTruncatedData = NewData;
				LastTruncatedData.TimeStamp = 0;
				IsLastStringTruncated = true;
				PrintLogLine(ULM_LOGLEVEL_DEBUG, "Found start of new truncated log string.");
			}
			else if (IsLastStringTruncated && IsStringTruncatedLeft && !IsStringTruncatedRight)
			{
				LastTruncatedData.Data += NewData.Data;

				PrintLogLine(ULM_LOGLEVEL_DEBUG, "Found end of truncated log string (total length = %d).", LastTruncatedData.Data.length());
				
				LastTruncatedData.TimeStamp = ParseTimeStampFromData(LastTruncatedData.Data);
				Output.push_back(LastTruncatedData);

				LastTruncatedData.Data.clear();
				LastTruncatedData.TimeStamp = 0;
				IsLastStringTruncated = false;
			}
			else if (IsLastStringTruncated && IsStringTruncatedLeft && IsStringTruncatedRight)
			{
				PrintLogLine(ULM_LOGLEVEL_DEBUG, "Found middle truncated log string.");
				LastTruncatedData.Data += NewData.Data;
			}
			else
			{
				if (IsLastStringTruncated) //Shouldn't happen
				{
					PrintLogLine(ULM_LOGLEVEL_DEBUG, "Warning: Found unterminated truncated log string.");

					IsLastStringTruncated = false;
					LastTruncatedData.TimeStamp = ParseTimeStampFromData(LastTruncatedData.Data);
					Output.push_back(LastTruncatedData);
					LastTruncatedData.Data.clear();
					LastTruncatedData.TimeStamp = 0;
				}

				NewData.TimeStamp = ParseTimeStampFromData(NewData.Data);
				Output.push_back(NewData);
			}
		}

		lua_pop(m_pLuaState, 1);
		++i;
	}

	lua_pop(m_pLuaState, 1);
	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarDataMap (CUlmLogMap& Output, const std::string Version)
{
	//Output.clear();
	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in log section!");
		return false;
	}

	std::string KeyName;
	std::string ValueName;

	int index = lua_gettop(m_pLuaState);
	lua_pushnil(m_pLuaState); 
	
    while (lua_next(m_pLuaState, index) != 0)
	{
		if (lua_type(m_pLuaState, -2) == LUA_TSTRING) 
		{
			KeyName = lua_tostring(m_pLuaState, -2);
			ValueName = lua_tostring(m_pLuaState, -1);

			Output[KeyName] = ValueName;
			eso::PrintLog("Found data info: %s = %s", KeyName.c_str(), Output[KeyName].c_str());
		}
		
		lua_pop(m_pLuaState, 1);
    }

	lua_pop(m_pLuaState, 1);
	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarGlobals (const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	ParseSavedVarDataArray(m_LogGlobalData, Version);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Loaded %d elements from the global section.", m_LogGlobalData.size());

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarCharData(const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	m_CharData = "";
	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in charData section!");
		return false;
	}

	int numObjects = lua_rawlen(m_pLuaState, -1);

	m_CharData = GetLuaVariableString("uespCharData", false);

	if (m_CharData.empty())
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to parse the charData variable data!");
		return false;
	}

	ParseCharDataScreenshots();

	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the charData section with %d characters (%u bytes).", numObjects, m_CharData.length());
	PrintLogLine(ULM_LOGLEVEL_INFO, "Found %d valid screenShot files for the character data.", m_CharDataValidScreenShotCount);
	lua_pop(m_pLuaState, 1);
	return true;
}


bool CuespLogMonitorDlg::ParseCharDataScreenshots()
{
	int index = lua_gettop(m_pLuaState);
	int i = 1;
	
	m_CharDataScreenShots.clear();
	m_CharDataValidScreenShotCount = 0;

	while (true)
	{
		lua_pushinteger(m_pLuaState, i);
		lua_rawgeti(m_pLuaState, index, i);

		if (lua_isnil(m_pLuaState, -1)) {
			lua_pop(m_pLuaState, 2);
			break;
		}

		lua_getfield(m_pLuaState, -1, "ScreenShot");

		if (lua_isnil(m_pLuaState, -1))
		{
			m_CharDataScreenShots.push_back("");
		}
		else
		{
			m_CharDataScreenShots.push_back(lua_tostring(m_pLuaState, -1));

			if (m_CharDataScreenShots.back().length() > 0)
			{
				bool Exists = eso::FileExists(m_CharDataScreenShots.back().c_str());

				if (Exists)
				{
					PrintLogLine(ULM_LOGLEVEL_INFO, "%d: Found ScreenShot File: %s", i, m_CharDataScreenShots.back().c_str());
					++m_CharDataValidScreenShotCount;
				}
				else
				{
					PrintLogLine(ULM_LOGLEVEL_INFO, "%d: Missing ScreenShot File: %s", i, m_CharDataScreenShots.back().c_str());
				}
			}
		}
		
		lua_pop(m_pLuaState, 3);
		++i;
	}

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarAchievements (const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	ParseSavedVarDataArray(m_LogAchievementData, Version);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Loaded %d elements from the achievement section.", m_LogAchievementData.size());

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarAll (const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	ParseSavedVarDataArray(m_LogAllData, Version);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Loaded %d elements from the main log section.", m_LogAllData.size());

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarInfo (const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	ParseSavedVarDataMap(m_LogInfoData, Version);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Loaded %d elements from the info section.", m_LogInfoData.size());

	if (m_LogInfoData.find("characterName") != m_LogInfoData.end()) m_CurrentCharacterName = m_LogInfoData["characterName"];

	if (m_LogInfoData.find("accountName")   != m_LogInfoData.end() && m_LogInfoData["accountName"] != "")
	{
		m_CurrentPlayerName = m_LogInfoData["accountName"];
		if (m_CurrentPlayerName[0] == '@') m_CurrentPlayerName.erase(0, 1);
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found data for user '%s' in saved variable info section.", m_CurrentPlayerName.c_str());
	}

	return true;
}


bool CuespLogMonitorDlg::SaveSavedVars()
{
	std::string Filename = GetSavedVarFilename();
	std::string TmpFilename = Filename + ".tmp";
	std::string CopyFilename = Filename + ".old";

	if (!SaveLuaVariable(TmpFilename, ULM_SAVEDVAR_NAME))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to write the saved variable data to file '%s'!", TmpFilename.c_str());
		return false;
	}

	if (!MoveFileEx(Filename.c_str(), CopyFilename.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_REPLACE_EXISTING))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to move saved variable file to '%s'!", CopyFilename.c_str());
		return false;
	}

	if (!MoveFileEx(TmpFilename.c_str(), Filename.c_str(), MOVEFILE_REPLACE_EXISTING))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to move temporary saved variabile file to '%s'!", Filename.c_str());
		return false;
	}

	return true;
}


bool CuespLogMonitorDlg::SaveLuaVariable(const std::string Filename, const std::string Variable)
{
	ulm_dumpinfo_t DumpInfo;

	DumpInfo.OutputFile = true;
	DumpInfo.TabLevel = 1;

	PrintLogLine(ULM_LOGLEVEL_INFO, "Writing saved variables to '%s'...", Filename.c_str());
	lua_getglobal(m_pLuaState, Variable.c_str());

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Could not find the variable '%s' in the LUA saved variable file!", Variable.c_str());
		lua_pop(m_pLuaState, 1);
		return false;
	}

	if (!DumpInfo.File.Open(Filename, "wb"))
	{
		lua_settop(m_pLuaState, 0);
		return false;
	}

	DumpInfo.File.Printf("%s = \n{\n", Variable.c_str());
	DumpInfo.TabLevel = 1;

	bool Result = LuaIterateSimpleTableInOrder(-1, &CuespLogMonitorDlg::DumpLuaObjectFile, (void *)&DumpInfo);

	DumpInfo.File.Printf("}");
	DumpInfo.File.Close();

	lua_settop(m_pLuaState, 0);
	
	return Result;
}


std::string CuespLogMonitorDlg::GetLuaVariableString(const std::string Variable, const bool LoadGlobal)
{
	ulm_dumpinfo_t DumpInfo;
	DumpInfo.OutputFile = false;
	DumpInfo.TabLevel = 1;

	if (LoadGlobal)
	{
		lua_getglobal(m_pLuaState, Variable.c_str());
	}

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Could not find the variable '%s'!", Variable.c_str());
		lua_pop(m_pLuaState, 1);
		return DumpInfo.OutputBuffer;
	}

	DumpInfo.OutputBuffer += Variable;
	DumpInfo.OutputBuffer += " = \n{\n";

	bool Result = LuaIterateSimpleTableInOrder(-1, &CuespLogMonitorDlg::DumpLuaObjectString, (void *)&DumpInfo);
		
	DumpInfo.OutputBuffer += "}";

	return DumpInfo.OutputBuffer;
}


bool CuespLogMonitorDlg::DumpLuaObjectFile (const std::string ParentVarName, void* pUserData)
{
	ulm_dumpinfo_t* pDumpInfo = (ulm_dumpinfo_t *) pUserData;
	if (pDumpInfo == nullptr) return false;

	std::string VarName;
	std::string Value;

	int keyType = lua_type(m_pLuaState, -2);
	int valType = lua_type(m_pLuaState, -1);

		/* Output tab indentation */
	for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->File.Printf("\t"); }

	if (keyType == LUA_TSTRING)
	{
		pDumpInfo->File.Printf("[\"%s\"] = ", ParentVarName.c_str());
	}
	else if (keyType == LUA_TNUMBER)
	{
		pDumpInfo->File.Printf("[%s] = ", ParentVarName.c_str());
	}
	else 
	{
		pDumpInfo->File.Printf("[\"unknown\"] = ");
	}

	if (valType == LUA_TSTRING)
	{
		Value = lua_tostring(m_pLuaState, -1);

		std::string newValue = Value;
		replaceAll(newValue, "\n", "\\n");
		replaceAll(newValue, "\r", "\\r");
		replaceAll(newValue, "\"", "\\\"");

		pDumpInfo->File.Printf("\"%s\",\n", newValue.c_str());
	}
	else if (valType == LUA_TNUMBER)
	{
		Value = lua_tostring(m_pLuaState, -1);
		pDumpInfo->File.Printf("%s,\n", Value.c_str());
	}
	else if (valType == LUA_TBOOLEAN)
	{
		Value = lua_toboolean(m_pLuaState, -1) != 0 ? "true" : "false";
		pDumpInfo->File.Printf("%s,\n", Value.c_str());
	}
	else if (valType == LUA_TTABLE)
	{
		pDumpInfo->File.Printf("\n");
		for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->File.Printf("\t"); }
		pDumpInfo->File.Printf("{\n");
		++pDumpInfo->TabLevel;

		bool Result = LuaIterateSimpleTableInOrder(-1, &CuespLogMonitorDlg::DumpLuaObjectFile, (void *) pDumpInfo);

		--pDumpInfo->TabLevel;
		for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->File.Printf("\t"); }
		pDumpInfo->File.Printf("},\n");

		return Result;
	}
	else
	{
		eso::PrintError("DumpLuaObjectFile() -- Can't output LUA object with type %d!", valType);
		return false;
	}

	return true;
}


bool CuespLogMonitorDlg::DumpLuaObjectString (const std::string ParentVarName, void* pUserData)
{
	ulm_dumpinfo_t* pDumpInfo = (ulm_dumpinfo_t *)pUserData;
	if (pDumpInfo == nullptr) return false;

	std::string VarName;
	std::string Value;

	int keyType = lua_type(m_pLuaState, -2);
	int valType = lua_type(m_pLuaState, -1);

		/* Output tab indentation */
	for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->OutputBuffer += "\t"; }

	if (keyType == LUA_TSTRING)
	{
		pDumpInfo->OutputBuffer += "[\"";
		pDumpInfo->OutputBuffer += ParentVarName;
		pDumpInfo->OutputBuffer += "\"] = ";
	}
	else if (keyType == LUA_TNUMBER)
	{
		pDumpInfo->OutputBuffer += "[";
		pDumpInfo->OutputBuffer += ParentVarName;
		pDumpInfo->OutputBuffer += "] = ";
	}
	else
	{
		pDumpInfo->OutputBuffer += "[\"unknown\"] = ";
	}

	if (valType == LUA_TSTRING)
	{
		Value = lua_tostring(m_pLuaState, -1);
		pDumpInfo->OutputBuffer += "\"";

		std::string newValue = Value;
		replaceAll(newValue, "\n", "\\n");
		replaceAll(newValue, "\r", "\\r");
		replaceAll(newValue, "\"", "\\\"");

		pDumpInfo->OutputBuffer += newValue;
		pDumpInfo->OutputBuffer += "\",\n";
	}
	else if (valType == LUA_TNUMBER)
	{
		Value = lua_tostring(m_pLuaState, -1);
		pDumpInfo->OutputBuffer += Value;
		pDumpInfo->OutputBuffer += ",\n";
	}
	else if (valType == LUA_TBOOLEAN)
	{
		Value = lua_toboolean(m_pLuaState, -1) != 0 ? "true" : "false";
		pDumpInfo->OutputBuffer += Value;
		pDumpInfo->OutputBuffer += ",\n";
	}
	else if (valType == LUA_TTABLE)
	{
		pDumpInfo->OutputBuffer += "\n";
		for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->OutputBuffer += "\t"; }
		pDumpInfo->OutputBuffer += "{\n";
		++pDumpInfo->TabLevel;

		bool Result = LuaIterateSimpleTableInOrder(-1, &CuespLogMonitorDlg::DumpLuaObjectString, (void *)pDumpInfo);

		--pDumpInfo->TabLevel;
		for (int i = 0; i < pDumpInfo->TabLevel; ++i) { pDumpInfo->OutputBuffer += "\t"; }
		pDumpInfo->OutputBuffer += "},\n";

		return Result;
	}
	else
	{
		eso::PrintError("DumpLuaObjectString() -- Can't output LUA object with type %d!", valType);
		return false;
	}

	return true;
}


bool CuespLogMonitorDlg::LoadSavedVars()
{
	return LoadSavedVars(GetSavedVarFilename());
}


bool CuespLogMonitorDlg::LoadSavedVars (const std::string Filename)
{
	PrintLogLine(ULM_LOGLEVEL_INFO, "Loading saved variables from '%s'...", Filename.c_str());
	ClearLogData();

		/* Load the saved variable file */
	int Result = luaL_dofile(m_pLuaState, Filename.c_str());

	if (Result != 0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to read the saved variable data (LUA error code %d)!", Result);
		return false;
	}

		/* Try to find the root saved variable */
	lua_getglobal(m_pLuaState, ULM_SAVEDVAR_NAME);

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Could not find the variable '%s' in the LUA saved variable file!", ULM_SAVEDVAR_NAME);
		lua_pop(m_pLuaState, 1);
		return false;
	}
	
		/* Find and parse data from the saved variable contents */
	bool bResult = LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::ParseSavedVarFirstLevel, nullptr);

	lua_settop(m_pLuaState, 0);
	return bResult;
}


std::string CuespLogMonitorDlg::GetCurrentUserName ()
{
	std::string UserName;

	switch (m_Options.UseLogName) 
	{
		default:
		case ULM_USELOGNAME_ANONYMOUS:	UserName = std::string("Anonymous"); break;
		case ULM_USELOGNAME_CHARACTER:	UserName = m_CurrentCharacterName; break;
		case ULM_USELOGNAME_PLAYER:		UserName = m_CurrentPlayerName; break;
		case ULM_USELOGNAME_CUSTOM:		UserName = m_Options.CustomLogName; break;
	}

	if (UserName.empty()) return UserName = "Unknown";
	return UserName;
}


std::string CuespLogMonitorDlg::GetExtraLogData ()
{
	std::string ExtraData = "userName{" + GetCurrentUserName() + "}  ";

	return ExtraData;
}


bool CuespLogMonitorDlg::SendLogData (const std::string Section, const ulm_sectiondata_t Data)
{
	if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0) 
	{ 
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

	m_SendQueue.push_back(Data);
	m_SendQueue.back().Data += GetExtraLogData();

	ReleaseMutex(m_hSendQueueMutex);
	return true;
}


bool CuespLogMonitorDlg::BackupLogData (const std::string Section, const ulm_sectiondata_t Data)
{
	m_BackupQueue.push_back(Data);
	m_BackupQueue.back().Data += GetExtraLogData();

	return true;
}


std::string CuespLogMonitorDlg::EncodeLogDataForQuery (const std::string Data)
{
	static const std::string base64_chars = 
             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
             "abcdefghijklmnopqrstuvwxyz"
             "0123456789+/";

	std::string EncodedData;
	int i = 0;
	int j = 0;
	unsigned char char_array_3[3];
	unsigned char char_array_4[4];
	size_t index = 0;

	while (index < Data.size())
	{
		char_array_3[i++] = Data[index];

		if (i == 3) 
		{
			char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
			char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
			char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
			char_array_4[3] = char_array_3[2] & 0x3f;

			for (i = 0; (i <4) ; i++)
				EncodedData += base64_chars[char_array_4[i]];

			i = 0;
		}

		++index;
	}

	if (i)
	{
		for(j = i; j < 3; j++)
			char_array_3[j] = '\0';

		char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
		char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
		char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
		char_array_4[3] = char_array_3[2] & 0x3f;

		for (j = 0; (j < i + 1); j++)
			EncodedData += base64_chars[char_array_4[j]];

		while((i++ < 3))
			EncodedData += '=';
	}

	return EncodedData;
}


bool CuespLogMonitorDlg::SendFormData (const std::string FormQuery)
{
	HINTERNET hinet, higeo, hreq;
	BOOL Result;

	std::string EscQuery = FormQuery;
	replaceAll(EscQuery, "+", "%2b");
	replaceAll(EscQuery, "/", "%2f");

	std::string SiteName;
	std::string PageURI; 

	size_t Pos = m_Options.FormURL.find("/");

	if (Pos == std::string::npos)
	{
		SiteName = m_Options.FormURL;
	}
	else
	{
		SiteName.assign(m_Options.FormURL, 0, Pos);
		PageURI.assign(m_Options.FormURL, Pos, m_Options.FormURL.size() - Pos);
		//eso::PrintLog("URL: '%s' '%s'", SiteName.c_str(), PageURI.c_str());
	}

	hinet = InternetOpen("MyBrowser/1.0", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
	higeo = InternetConnect(hinet, SiteName.c_str(), INTERNET_DEFAULT_HTTP_PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
	hreq = HttpOpenRequest(higeo, "POST", PageURI.c_str(), "", SiteName.c_str(), NULL, INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_FORMS_SUBMIT, 0);

	HttpAddRequestHeaders(hreq, "Content-Type: application/x-www-form-urlencoded", -1, HTTP_ADDREQ_FLAG_ADD);
	Result = HttpSendRequest(hreq, 0, 0, (void *)EscQuery.c_str(), EscQuery.size());

	if (!Result)
	{
		InternetCloseHandle(hreq);
		InternetCloseHandle(higeo);
		InternetCloseHandle(hinet);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to send the HTTP form request!");
		return false;
	}
	
	char Buffer[220];
	DWORD Size = 200;
	
	Sleep(100); // TODO?

	Result = HttpQueryInfo(hreq, HTTP_QUERY_STATUS_CODE, &Buffer, &Size, NULL);

	InternetCloseHandle(hreq);
	InternetCloseHandle(higeo);
	InternetCloseHandle(hinet);

	if (!Result) 
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to receive a HTTP response!");
		return false;
	}
	
	if (strcmp(Buffer, "200") != 0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Received a '%s' HTTP response!", Buffer);
		return false;
	}

	return true;
}


bool CuespLogMonitorDlg::SendQueuedData ()
{
	return true; // The send queue thread will automatically send data now
}


bool CuespLogMonitorDlg::SendQueuedDataThread()
{
	std::string FormQuery;
	size_t i;

	if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0) 
	{ 
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

	for (i = 0; i < m_SendQueue.size(); ++i)
	{
		std::string TempData = EncodeLogDataForQuery(m_SendQueue[i].Data);
		//eso::PrintLog("%s", TempData.c_str());

		FormQuery += "log[]=";
		FormQuery += TempData;
		FormQuery += "&";

		if (FormQuery.size() > ULM_SENDDATA_MAXPOSTSIZE)
		{
			break;
		}
	}

	if (FormQuery.size() > 0) 
	{
		if (!SendFormData(FormQuery)) 
		{
			ReleaseMutex(m_hSendQueueMutex);
			return false;
		}

		PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %d of %d log entries in %d bytes!", i, m_SendQueue.size(), FormQuery.size());
		m_SendQueue.erase(m_SendQueue.begin(), m_SendQueue.begin() + i);
	}

	ReleaseMutex(m_hSendQueueMutex);
	return true;
}


bool CuespLogMonitorDlg::CheckAndSendLogData ()
{
	bool Result = true;
		
	Result &= CheckAndSendLogDataAll();
	Result &= CheckAndSendLogDataGlobal();
	Result &= CheckAndSendLogDataAchievement();

	Result &= BackupData();
	Result &= SendQueuedData();

	if (Result)
	{
		m_Options.LastTimeStamp = m_LastParsedTimeStamp;
	}

	return Result;
}


bool CuespLogMonitorDlg::SendAllLogData ()
{
	bool Result = true;
	
	Result &= SendLogData(m_LogAllData);
	Result &= SendLogData(m_LogGlobalData);
	Result &= SendLogData(m_LogAchievementData);

	PrintLogLine(ULM_LOGLEVEL_WARNING, "Warning: Sending %d log entries...this may take a few mintues for large log files....", m_SendQueue.size());

	Result &= SendQueuedData();

	return Result;
}


bool CuespLogMonitorDlg::CheckAndSendLogDataAll ()
{
	__int64 LastValidTimeStamp = m_Options.LastTimeStamp;
	int SentCount = 0;

	m_LastParsedTimeStamp = m_Options.LastTimeStamp;

	for (size_t i = 0; i < m_LogAllData.size(); ++i)
	{
		ulm_sectiondata_t& Data = m_LogAllData[i];
		if (Data.TimeStamp > 0) LastValidTimeStamp = Data.TimeStamp;
		
		if (LastValidTimeStamp >= m_Options.LastTimeStamp)
		{
			//eso::PrintLog("%d: Found valid timestamp %I64d", i, Data.TimeStamp);
			SendLogData("all", Data);
			++SentCount;

			if (m_LastParsedTimeStamp < LastValidTimeStamp) m_LastParsedTimeStamp = LastValidTimeStamp + 1;
		}
		else
		{
			//eso::PrintLog("%d: Found INVALID timestamp %I64d", i, Data.TimeStamp);
		}
	}

	//if (LastValidTimeStamp == 0) LastValidTimeStamp = m_Options.LastTimeStamp - 1;
	//m_LastParsedTimeStamp = LastValidTimeStamp + 1;

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %d log entries.", SentCount);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Last Parsed Timestamp = %I64d", m_LastParsedTimeStamp);
	return true;
}


bool CuespLogMonitorDlg::SendLogData (CUlmLogDataArray& DataArray)
{
	__int64 LastValidTimeStamp = 0;
	int SentCount = 0;

	for (size_t i = 0; i < DataArray.size(); ++i)
	{
		ulm_sectiondata_t& Data = DataArray[i];
		SendLogData("", Data);
		++SentCount;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %d log entries.", SentCount);
	return true;
}


bool CuespLogMonitorDlg::CheckAndSendLogDataGlobal ()
{
	int SentCount = 0;

	for (size_t i = 0; i < m_LogGlobalData.size(); ++i)
	{
		ulm_sectiondata_t& Data = m_LogGlobalData[i];

		BackupLogData("global", Data);
		++SentCount;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Backed up %d global entries.", SentCount);
	return true;
}


bool CuespLogMonitorDlg::CheckAndSendLogDataAchievement ()
{
	int SentCount = 0;

	for (size_t i = 0; i < m_LogAchievementData.size(); ++i)
	{
		ulm_sectiondata_t& Data = m_LogAchievementData[i];

		BackupLogData("achievement", Data);
		++SentCount;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Backed up %d achievement entries.", SentCount);

	return true;
}


std::string CuespLogMonitorDlg::FindSavedVarPath (void)
{	std::string SavedVarPath;
	CHAR MyDocuments[MAX_PATH+100];

	HRESULT result = SHGetFolderPath(NULL, CSIDL_PERSONAL, NULL, SHGFP_TYPE_CURRENT, MyDocuments);

	if (result != S_OK)
	{ 
		eso::PrintError("Failed to get the path to the Window user's Documents!");
		return SavedVarPath;
	}
		
	SavedVarPath = eso::TerminatePath(MyDocuments);
	SavedVarPath += ULM_SAVEDVAR_BASEPATH;

	eso::PrintLog("Documents Path = %s", MyDocuments);
	eso::PrintLog("SavedVars Path = %s", SavedVarPath.c_str());

	if (!eso::DirectoryExists(SavedVarPath.c_str()))
	{
		eso::PrintError("WARNING: The default saved variable path '%s' does not exist!", SavedVarPath.c_str());

		SavedVarPath = eso::TerminatePath(MyDocuments);
		SavedVarPath += ULM_SAVEDVAR_ALTBASEPATH;

		eso::PrintLog("SavedVars Alt Path = %s", SavedVarPath.c_str());

		if (!eso::DirectoryExists(SavedVarPath.c_str()))
		{
			eso::PrintError("WARNING: The alternate saved variable path '%s' does not exist!", SavedVarPath.c_str());
		}
	}

	return SavedVarPath;
}


void CuespLogMonitorDlg::PrintLogLine (const ulm_loglevel_t LogLevel, const char* pString, ...)
{
	if (LogLevel > m_Options.LogLevel) return;

	va_list Args;

	va_start(Args, pString);
	PrintLogLineV(pString, Args);
	va_end(Args);
}


void CuespLogMonitorDlg::PrintLogLine (const char* pString, ...)
{
	va_list Args;

	va_start(Args, pString);
	PrintLogLineV(pString, Args);
	va_end(Args);
}


void CuespLogMonitorDlg::PrintLogLineV (const char* pString, va_list Args)
{
	CString Buffer;

	eso::PrintLogV(pString, Args);
	Buffer.FormatV(pString, Args);
	Buffer += "\r\n";

	CHARRANGE OrigSelRange;
	m_LogText.GetSel(OrigSelRange);

	int MinScrollPos, MaxScrollPos;
	int OrigScrollPos = m_LogText.GetScrollPos(SB_VERT);
	m_LogText.GetScrollRange(SB_VERT, &MinScrollPos, &MaxScrollPos);

	m_LogText.LockWindowUpdate();

	long TextLength = m_LogText.GetTextLength();
	m_LogText.SetSel(TextLength, TextLength);
	m_LogText.ReplaceSel(Buffer, false);

	if (TextLength > 0)
		m_LogText.SetSel(OrigSelRange);
	else
		m_LogText.SetSel(m_LogText.GetTextLength(), m_LogText.GetTextLength());

	m_LogText.UnlockWindowUpdate();
	m_LogText.RedrawWindow();
	
	if (OrigScrollPos == MaxScrollPos) 
	{
		//m_LogText.GetScrollRange(SB_VERT, &MinScrollPos, &MaxScrollPos);
		//m_LogText.SetScrollPos(SB_VERT, MaxScrollPos, TRUE);
		m_LogText.SendMessage(WM_VSCROLL, SB_BOTTOM, NULL);
	}
	else
	{
		//m_LogText.SetScrollPos(SB_VERT, OrigScrollPos, TRUE);
	}
	
		/* Force scroll to bottom with no text selection */
	TextLength = m_LogText.GetTextLength();
	m_LogText.SetSel(TextLength, TextLength);
	m_LogText.SendMessage(WM_VSCROLL, SB_BOTTOM, NULL);
}


void CuespLogMonitorDlg::InitTrayIcon()
{
	m_TrayIconData.hWnd = m_hWnd;
	m_TrayIconData.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
	m_TrayIconData.uCallbackMessage = WM_SYSCOMMAND;
	m_TrayIconData.uID = 12345;
	m_TrayIconData.hIcon = GetIcon(true);

	SetTrayToolTip("uespLogMonitor");
}


void CuespLogMonitorDlg::ShowInTray (const bool Show, const bool UpdateWindow)
{
	if (Show)
	{
		if (!IsInTray ())
		{
			m_IsInTray = true;
			Shell_NotifyIcon (NIM_ADD, &m_TrayIconData);
		}
		if (UpdateWindow) ShowWindow (SW_HIDE);
	}
	else
	{
		if (IsInTray ())
		{
			m_IsInTray = false;
			Shell_NotifyIcon (NIM_DELETE, &m_TrayIconData);
			if (UpdateWindow) ShowWindow (SW_SHOW);
		}
	}
}

void CuespLogMonitorDlg::SetTrayToolTip (const CString Buffer)
{
	strcpy(m_TrayIconData.szTip, Buffer.Mid (0, 63));
	if (IsInTray()) Shell_NotifyIcon (NIM_MODIFY, &m_TrayIconData);
}


DWORD WINAPI l_SendQueueThreadProc (LPVOID lpParameter)
{
	CuespLogMonitorDlg* pThis = (CuespLogMonitorDlg *) lpParameter;
	return pThis->SendQueueThreadProc();
}


DWORD CuespLogMonitorDlg::SendQueueThreadProc()
{

	while(!m_StopSendQueueThread)
	{
		//if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) == WAIT_OBJECT_0) 
		{ 
			SendQueuedDataThread();
			//ReleaseMutex(m_hSendQueueMutex);
		}

		Sleep(100);
	}

	return 0;
}


void CuespLogMonitorDlg::InitSendQueueThread()
{
	m_StopSendQueueThread = 0;
	m_hSendQueueThread = CreateThread(NULL, 0, l_SendQueueThreadProc, this, 0, NULL);
	m_hSendQueueMutex = CreateMutex(NULL, FALSE, "SendQueueMutex");
}


void CuespLogMonitorDlg::DestroySendQueueThread()
{
	InterlockedExchange(&m_StopSendQueueThread, 1);

	if (m_hSendQueueThread != NULL)
	{
		if (WaitForSingleObject(m_hSendQueueThread, 10000) != WAIT_OBJECT_0)
		{
			TerminateThread(m_hSendQueueThread, 0);
		}

		CloseHandle(m_hSendQueueThread);
		m_hSendQueueThread = NULL;
	}

	CloseHandle(m_hSendQueueMutex);
}


BOOL CuespLogMonitorDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	InitTrayIcon();
	LoadRegistrySettings();
	CreateTimer();
	UpdateDialogTitle();

	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);

	if (pSysMenu != NULL)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);

		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	SetIcon(m_hIcon, TRUE);
	SetIcon(m_hIcon, FALSE);

	InitSendQueueThread();

	PrintLogLine(ULM_LOGLEVEL_INFO, "Program initialized...");
	PrintSettings();

		/* Load the saved variable file */
	int Result = luaL_dofile(m_pLuaState, "d:\\temp\\test.lua");

	if (Result != 0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to read the saved variable data (LUA error code %d)!", Result);
		return false;
	}

	SaveLuaVariable("d:\\temp\\test_out.lua", "EquipSlots");
		
	return TRUE;
}


void CuespLogMonitorDlg::ClearLogData (void)
{
	m_LogGlobalData.clear();
	m_LogAllData.clear();
	m_LogInfoData.clear();
	m_LogAchievementData.clear();
}


void CuespLogMonitorDlg::PrintSettings (void)
{
	PrintLogLine(ULM_LOGLEVEL_INFO, "Log monitoring is %s", m_Options.Enabled ? "enabled" : "disabled");
	PrintLogLine(ULM_LOGLEVEL_INFO, "Saved variable path set to '%s'", m_Options.SavedVarPath.c_str());
	PrintLogLine(ULM_LOGLEVEL_INFO, "Sending logged data to '%s'", m_Options.FormURL.c_str());
	PrintLogLine(ULM_LOGLEVEL_INFO, "Checking log every %d seconds", m_Options.UpdateTime);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Using '%I64d' as last parsed timestamp", m_Options.LastTimeStamp);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Using '%I64d' as last backup timestamp", m_Options.LastBackupTimeStamp);

	switch (m_Options.UseLogName) 
	{
	default:
	case ULM_USELOGNAME_ANONYMOUS:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Using anonymous identity");
		break;
	case ULM_USELOGNAME_CHARACTER:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Using current character name for identity");
		break;
	case ULM_USELOGNAME_PLAYER:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Using player/account name for identity");
		break;
	case ULM_USELOGNAME_CUSTOM:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Using custom name '%s' as identity", m_Options.CustomLogName.c_str());
		break;
	}

	switch (m_Options.LogLevel) 
	{
	default:
	case ULM_LOGLEVEL_NONE:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log level set to display no messages");
		break;
	case ULM_LOGLEVEL_ERROR:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log level set to display errors only");
		break;
	case ULM_LOGLEVEL_WARNING:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log level set to display warnings and errors");
		break;
	case ULM_LOGLEVEL_INFO:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log level set to display info, warning, and error messages");
		break;
	case ULM_LOGLEVEL_DEBUG:
	case ULM_LOGLEVEL_ALL:
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log level set to display all messages");
		break;
	}

}


void CuespLogMonitorDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}


void CuespLogMonitorDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this);

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialogEx::OnPaint();
	}
}


HCURSOR CuespLogMonitorDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}


bool CuespLogMonitorDlg::LoadRegistrySettings (void)
{
	CWinApp* pApp = AfxGetApp();
	CString Buffer;

	m_Options.UpdateTime = pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UPDATETIME, m_Options.UpdateTime);
	if (m_Options.UpdateTime < ulm_options_t::MIN_UPDATETIME) m_Options.UpdateTime = ulm_options_t::MIN_UPDATETIME;
	if (m_Options.UpdateTime > ulm_options_t::MAX_UPDATETIME) m_Options.UpdateTime = ulm_options_t::MAX_UPDATETIME;

	m_Options.UseLogName = static_cast<ulm_uselogname_t>( pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_USELOGNAME, m_Options.UseLogName) );
	m_Options.LogLevel = static_cast<ulm_loglevel_t>( pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LOGLEVEL, m_Options.LogLevel) );
	m_Options.Enabled = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_ENABLED, m_Options.Enabled) != 0);
	m_Options.CharDataEnabled = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAENABLED, m_Options.CharDataEnabled) != 0);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CUSTOMLOGNAME, m_Options.CustomLogName.c_str());
	m_Options.CustomLogName = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTTIMESTAMP, "0");
	m_Options.LastTimeStamp = _atoi64(Buffer);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP, "0");
	m_Options.LastBackupTimeStamp = _atoi64(Buffer);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_SAVEDVARPATH, m_Options.SavedVarPath.c_str());
	m_Options.SavedVarPath = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPDATAFILENAME, m_Options.BackupDataFilename.c_str());
	m_Options.BackupDataFilename = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPCHARDATAFILENAME, m_Options.BackupCharDataFilename.c_str());
	m_Options.BackupCharDataFilename = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_FORMURL, m_Options.FormURL.c_str());
	m_Options.FormURL = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAFORMURL, m_Options.CharDataFormURL.c_str());
	m_Options.CharDataFormURL = Buffer;

	return true;
}


bool CuespLogMonitorDlg::SaveRegistrySettings (void)
{
	CWinApp* pApp = AfxGetApp();
	CString Buffer;

	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UPDATETIME, m_Options.UpdateTime);
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_USELOGNAME, m_Options.UseLogName);
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LOGLEVEL,   m_Options.LogLevel);
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_ENABLED,    m_Options.Enabled);
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAENABLED, m_Options.CharDataEnabled);

	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CUSTOMLOGNAME, m_Options.CustomLogName.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_FORMURL,       m_Options.FormURL.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAFORMURL, m_Options.CharDataFormURL.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_SAVEDVARPATH,  m_Options.SavedVarPath.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPDATAFILENAME, m_Options.BackupDataFilename.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPCHARDATAFILENAME, m_Options.BackupCharDataFilename.c_str());

	Buffer.Format("%I64d", m_Options.LastTimeStamp);
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTTIMESTAMP, Buffer);

	Buffer.Format("%I64d", m_Options.LastBackupTimeStamp);
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP, Buffer);

	return true;
}


void CuespLogMonitorDlg::OnClose()
{
	OnOK();
}


BOOL CuespLogMonitorDlg::DestroyWindow()
{
	SaveRegistrySettings();
	return CDialogEx::DestroyWindow();
}


void CuespLogMonitorDlg::OnFileExit()
{
	OnOK();
}


void TestOpenSSL() 
{
	/*
	salt=C85BB02CA3A74318
	key=DB27BAD9AC272A3CD0E77759D6B78E55EAF795F499D1862E61EE61EB04B44B6F
	iv =A1DC8AB2FB65A6C1DCB9DF391BCAE955

	salt=F0FC292456410C8C
	key=B643CC4A20610FE77CF75053C9637FE4
	iv =85C6DF68AC81AE6F38FB7B347187C8CF

	*/

  int bytes_read;
  unsigned char indata[100] = "0123456789ABC";
  unsigned char outdata[200];
  unsigned char outdata1[200];

  /* ckey and ivec are the two 128-bits keys necesary to
     en- and recrypt your data.  Note that ckey can be
     192 or 256 bits as well */
  unsigned char salt[] = "\xF0\xFC\x29\x24\x56\x41\x0C\x8C";
  unsigned char ckey[] =  "\xB6\x43\xCC\x4A\x20\x61\x0F\xE7\x7C\xF7\x50\x53\xC9\x63\x7F\xE4";
  unsigned char ivec[] = "\x85\xC6\xDF\x68\xAC\x81\xAE\x6F\x38\xFB\x7B\x34\x71\x87\xC8\xCF";

  /* data structure that contains the key itself */
  AES_KEY key;
  AES_KEY dekey;

  /* set the encryption key */
  

  /* set where on the 128 bit encrypted block to begin encryption*/
  int num = 0;
  bytes_read = strlen((char *)ivec);

	AES_set_encrypt_key(ckey, 128, &key);
	//AES_encrypt(indata, outdata, &key);
	AES_cfb128_encrypt(indata, outdata, AES_BLOCK_SIZE, &key, ivec, &num, AES_ENCRYPT);
	//AES_cbc_encrypt((unsigned char *)indata, outdata, AES_BLOCK_SIZE, &key, ivec, AES_ENCRYPT);
  	eso::PrintLog("Encrypted Data(%d): %s", num, outdata);

	AES_set_decrypt_key(ckey, 128, &dekey);
	//AES_cbc_encrypt(outdata, outdata1, AES_BLOCK_SIZE, &dekey, ivec, AES_DECRYPT);
	AES_cfb128_encrypt(outdata, outdata1, AES_BLOCK_SIZE, &dekey, ivec, &num, AES_DECRYPT);
	//AES_decrypt(outdata, outdata1, &dekey);
	eso::PrintLog("Decrypted Data(%d): %s", num, outdata1);

	EVP_CIPHER_CTX e_ctx;
	EVP_CIPHER_CTX d_ctx;
	//int i, nrounds = 5;
	//unsigned char key[32], iv[32];
	//EVP_BytesToKey(EVP_aes_256_cbc(), EVP_sha1(), salt, key_data, key_data_len, nrounds, key, iv);
	EVP_CIPHER_CTX_init(&e_ctx);
	 EVP_EncryptInit_ex(&e_ctx, EVP_aes_128_cbc(), NULL, ckey, ivec);
	EVP_CIPHER_CTX_init(&d_ctx);
	EVP_DecryptInit_ex(&d_ctx, EVP_aes_128_cbc(), NULL, ckey, ivec);

	int c_len, f_len;
	EVP_EncryptInit_ex(&e_ctx, NULL, NULL, NULL, NULL);
	EVP_EncryptUpdate(&e_ctx, outdata, &c_len, indata, 16);
	EVP_EncryptFinal_ex(&e_ctx, outdata+c_len, &f_len);

	eso::PrintLog("Encrypted Data(%d, %d): %s", c_len, f_len, outdata);

	int p_len;
	EVP_DecryptInit_ex(&d_ctx, NULL, NULL, NULL, NULL);
	EVP_DecryptUpdate(&d_ctx, outdata1, &p_len, outdata, f_len);
	EVP_DecryptFinal_ex(&d_ctx, outdata1 + p_len, &f_len);

	eso::PrintLog("Decrypted Data(%d, %d): %s", p_len, f_len, outdata1);


	RSA *keypair = RSA_generate_key(2048, 3, NULL, NULL);
	
	//RSA* keypair;
	keypair = RSA_new();
	BIGNUM *oBigNbr = BN_new();
	BN_set_word(oBigNbr, RSA_F4);
	int RsaResult = RSA_generate_key_ex(keypair, 2048, oBigNbr, NULL);
	//char msg[2048];

	//RSA *rsa = PEM_read_RSA_PUBKEY(f,NULL,NULL,NULL);
	//RSA *rsa = PEM_read_RSAPrivateKey(f,NULL,NULL,NULL);
	//BN_hex2bn(&keypair->n, "C0E7FC730EB5CF85B040EC25DAEF288912641889AD651B3707CFED9FC5A1D3F6C40062AD46E3B3C3E21D4E71CC4800C80226D453242AEB2F86D748B41DDF35FD");
	//BN_hex2bn(&keypair->e, "010001");
	
	// Encrypt the message
	char encrypt[4096];
	int encrypt_len;

	encrypt_len = RSA_public_encrypt(strlen((char *)indata)+1, (unsigned char*)indata, (unsigned char*)encrypt, keypair, RSA_PKCS1_OAEP_PADDING);
	eso::PrintLog("Encrypted Data(%d): %s", encrypt_len, encrypt);

	char decrypt[4096];
	int der = RSA_private_decrypt(encrypt_len, (unsigned char*)encrypt, (unsigned char*)decrypt, keypair, RSA_PKCS1_OAEP_PADDING);
	eso::PrintLog("Decrypted Data(%d): %s", der, decrypt);
}


void CuespLogMonitorDlg::OnBnClickedButton1()
{
	int Result = luaL_dofile(m_pLuaState, "d:\\esoexport\\uesplog\\addon\\test\\testoutput.lua");
	eso::PrintLog("DoFile Result = %d", Result);
	
	lua_getglobal(m_pLuaState, "uespLogSavedVars");
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));

	lua_getfield (m_pLuaState, -1, "Default");
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));

	int index = lua_gettop(m_pLuaState);
	eso::PrintLog("Stack Top index = %d", index);
	std::string UserName;

	lua_pushnil(m_pLuaState);  /* first key */

    while (lua_next(m_pLuaState, index) != 0)
	{
			/* uses 'key' (at index -2) and 'value' (at index -1) */

		if (lua_type(m_pLuaState, -2) == LUA_TSTRING) 
		{
			//lua_pushvalue(m_pLuaState, -2);
			const char* pName = lua_tostring(m_pLuaState, -2);
			//lua_pop(m_pLuaState, 1);
			eso::PrintLog("String name = '%s'", pName);
			UserName = pName;
		}

		eso::PrintLog("%s - %s",
              lua_typename(m_pLuaState, lua_type(m_pLuaState, -2)),
              lua_typename(m_pLuaState, lua_type(m_pLuaState, -1)));

			/* removes 'value'; keeps 'key' for next iteration */
		lua_pop(m_pLuaState, 1);
    }

	if (UserName.empty()) return;

	lua_getfield (m_pLuaState, -1, UserName.c_str());
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));

	lua_getfield (m_pLuaState, -1, "$AccountWide");
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));

	lua_getfield (m_pLuaState, -1, "achievements");
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));

	lua_getfield (m_pLuaState, -1, "data");
	eso::PrintLog("DoFile isTable() = %d", lua_istable(m_pLuaState, -1));
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));

	int i = 1;

	while (true)
	{
		lua_rawgeti(m_pLuaState, -1, i);

		if (lua_isnil(m_pLuaState, -1)) {
			lua_pop(m_pLuaState, 1);
			break;
		}

		if (lua_type(m_pLuaState, -1) == LUA_TSTRING) 
		{
			const char* pName = lua_tostring(m_pLuaState, -1);
			eso::PrintLog("Value[%d] = %s", i, pName);
		}
		else
		{
			eso::PrintLog("%d", i);
		}

		lua_pop(m_pLuaState, 1);
		++i;
	}

	lua_getfield(m_pLuaState, -1, "test");
	eso::PrintLog("isnil = %d", lua_isnil(m_pLuaState, -1));
	PostURL();
	TestOpenSSL();
}


void CuespLogMonitorDlg::PostURL()
{
	  HINTERNET hinet, higeo, hreq;
	  char formdata[] = "test=data";
	  BOOL Result;

	  hinet = InternetOpen("MyBrowser/1.0", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
	  higeo = InternetConnect(hinet, "content3.uesp.net", INTERNET_DEFAULT_HTTP_PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
	  hreq = HttpOpenRequest(higeo, "POST", "/form/?formid=123456&sec=submit", "", "content3.uesp.net", NULL, INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_FORMS_SUBMIT, 0);

	  HttpAddRequestHeaders(hreq, "Content-Type: application/x-www-form-urlencoded", -1, HTTP_ADDREQ_FLAG_ADD);
	  Result = HttpSendRequest(hreq, 0, 0, (void *)formdata, strlen(formdata));
	  eso::PrintLog("HTTP Send Request = %d", Result);

	  char Buffer[220];
	  DWORD Size = 200;
	  Sleep(400);

	  Result = HttpQueryInfo(hreq, HTTP_QUERY_STATUS_CODE, &Buffer, &Size, NULL);
	  eso::PrintLog("HTTP Query Info = %d (%s)", Result, Buffer);  

	  InternetCloseHandle(hreq);
	  InternetCloseHandle(higeo);
	  InternetCloseHandle(hinet);
}


void CuespLogMonitorDlg::OnCancel()
{
	/* Do nothing to prevent ESC from closing dialog */
	//eso::PrintLog("OnCancel");
}


void CuespLogMonitorDlg::OnLogCheckTimer()
{
	if (m_IsCheckingFile) return;
	m_IsCheckingFile = true;

	DoLogCheck();

	m_IsCheckingFile = false;
}


bool CuespLogMonitorDlg::DoLogCheck(const bool OverrideEnable)
{
	if (!OverrideEnable && !m_Options.Enabled) return true;

		/* Make sure we can obtain the mutex */
	if (WaitForSingleObject(m_hSendQueueMutex, 1000) != WAIT_OBJECT_0) 
	{ 
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Skipping log check...failed to acquire send queue mutex!");
		return false;
	}

	ReleaseMutex(m_hSendQueueMutex);

	PrintLogLine(ULM_LOGLEVEL_INFO, "Checking log...");
	//PrintLogLine(ULM_LOGLEVEL_INFO, "Pre-TimeStamp: %I64d", m_Options.LastTimeStamp);
	//PrintLogLine(ULM_LOGLEVEL_INFO, "Pre-Backup TimeStamp: %I64d", m_Options.LastBackupTimeStamp);

	if (HasQueuedData()) 
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Sending remaining queued log data...");

		if (SendQueuedData())
		{
			m_Options.LastTimeStamp = m_LastParsedTimeStamp;
		}
	}

	if (!HasLogChanged()) return false;
	if (!LoadSavedVars()) return false;

	if (WaitForSingleObject(m_hSendQueueMutex, 1000) != WAIT_OBJECT_0) 
	{ 
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

			/* Send any data that needs to be updated */
	if (!CheckAndSendLogData()) 
	{
		ReleaseMutex(m_hSendQueueMutex);
		return false;
	}

	UpdateLogFileSize();

	bool Result = DeleteOldLogData();
	Result &= SaveSavedVars();

	eso::PrintLog("LUA Stack size = %d", lua_gettop(m_pLuaState));
	lua_settop(m_pLuaState, 0);

	ReleaseMutex(m_hSendQueueMutex);

	//PrintLogLine(ULM_LOGLEVEL_INFO, "Post-TimeStamp: %I64d", m_Options.LastTimeStamp);
	//PrintLogLine(ULM_LOGLEVEL_INFO, "Post-Backup TimeStamp: %I64d", m_Options.LastBackupTimeStamp);

	return Result;
}


bool CuespLogMonitorDlg::DeleteOldLogData()
{
	lua_getglobal(m_pLuaState, ULM_SAVEDVAR_NAME);

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the saved variable data!");
		return false;
	}

	LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::DeleteOldLogDataRoot, nullptr);

	return true;
}


bool CuespLogMonitorDlg::DeleteOldLogDataRoot (const std::string VarName, void* pUserData)
{
	return LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::DeleteOldLogDataUser, nullptr);
}


bool CuespLogMonitorDlg::DeleteOldLogDataUser (const std::string VarName, void* pUserData)
{
	return LuaIterateSimpleTable(-1, &CuespLogMonitorDlg::DeleteOldLogDataAccount, nullptr);
}


bool CuespLogMonitorDlg::DeleteOldLogDataAccount (const std::string VarName, void* pUserData)
{
	DeleteOldLogDataSection("all", -1);
	DeleteOldLogDataSection("globals", -1);
	DeleteOldLogDataSection("achievements", -1);
	return true;
}


bool CuespLogMonitorDlg::DeleteOldLogDataSection (const std::string Section, const int StackIndex)
{
	lua_getfield(m_pLuaState, StackIndex, Section.c_str());

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the section '%s' in the saved variable data!", Section.c_str());
		lua_pop(m_pLuaState, 1);
		return false;
	}

	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field for section '%s' in the saved variable data!", Section.c_str());
		lua_pop(m_pLuaState, 1);
		return false;
	}

	size_t OrigTableLength = lua_rawlen(m_pLuaState, -1);
	lua_pop(m_pLuaState, 1);

	lua_newtable(m_pLuaState);
	lua_setfield(m_pLuaState, -2, "data");

	PrintLogLine(ULM_LOGLEVEL_INFO, "Removed %d elements from '%s' data.", OrigTableLength, Section.c_str());
	
	lua_pop(m_pLuaState, 1);
	return true;
}


std::string CuespLogMonitorDlg::GetSavedVarFilename()
{
	return eso::TerminatePath(m_Options.SavedVarPath) + ULM_SAVEDVAR_FILENAME;
}


void CuespLogMonitorDlg::UpdateLogFileSize()
{
	eso::GetFileSize(m_LastLogFileSize, GetSavedVarFilename());
}


bool CuespLogMonitorDlg::HasLogChanged()
{
	std::string Filename = GetSavedVarFilename();
	__int64 FileSize;

	if ( !eso::FileExists(Filename.c_str()) )
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Saved variable file not found!");
		return false;
	}

	if (!eso::GetFileSize(FileSize, Filename))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to get the size of the saved variable file!");
		return false;
	}

	if (FileSize == m_LastLogFileSize) 
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log file size hasn't changed");
		return false;
	}

	__int64 DiffSize = FileSize - m_LastLogFileSize;

	if (DiffSize > 0)
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log has gained %lld bytes", DiffSize);
	else
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log has lost %lld bytes", -DiffSize);

	return true;
}


void CuespLogMonitorDlg::OnTimer(UINT_PTR nIDEvent)
{

	if (nIDEvent == m_TimerId)
	{
		OnLogCheckTimer();
		return;
	}

	CDialogEx::OnTimer(nIDEvent);
}



void CuespLogMonitorDlg::OnViewOptions()
{
	COptionsDlg Dlg;
	int OrigUpdateTime = m_Options.UpdateTime;

	if (Dlg.DoModal(m_Options) != IDOK) return;

	if (OrigUpdateTime != m_Options.UpdateTime)
	{
		CreateTimer();
	}
}


bool CuespLogMonitorDlg::BackupCharData()
{
	if (m_Options.BackupCharDataFilename.empty() || m_CharData.empty()) return true;

	eso::CFile File;
	
	PrintLogLine(ULM_LOGLEVEL_INFO, "Backing up character data...");

	if (!File.Open(m_Options.BackupCharDataFilename, "a+b"))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to open the backup character data file for output!");
		return false;
	}

	if (!File.WriteString(m_CharData))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to write the character data to the backup file!");
		return false;
	}

	return true;
}


bool CuespLogMonitorDlg::BackupData()
{
	if (m_Options.BackupDataFilename.empty()) return true;

	eso::CFile File;
	__int64 MaxTimeStamp = m_Options.LastBackupTimeStamp;
	__int64 LastValidTimeStamp = m_Options.LastBackupTimeStamp;
	int BackupCount = 0;

	PrintLogLine(ULM_LOGLEVEL_INFO, "Backing up new data...");

	if (!File.Open(m_Options.BackupDataFilename, "a+b"))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to open the backup file for output!");
		return false;
	}

		/* Output all data in the send queue */
	for (size_t i = 0; i < m_SendQueue.size(); ++i)
	{
		ulm_sectiondata_t& Data = m_SendQueue[i];

		if (Data.TimeStamp > 0) LastValidTimeStamp = Data.TimeStamp;

		if (LastValidTimeStamp >= m_Options.LastBackupTimeStamp)
		{
			++BackupCount;
			File.Printf("%s\n", Data.Data.c_str());
			if (LastValidTimeStamp > MaxTimeStamp) MaxTimeStamp = LastValidTimeStamp;
		}
	}

		/* Output all backup data */
	for (size_t i = 0; i < m_BackupQueue.size(); ++i)
	{
		ulm_sectiondata_t& Data = m_BackupQueue[i];

		++BackupCount;
		File.Printf("%s\n", Data.Data.c_str());
	}

	m_BackupQueue.clear();

	m_Options.LastBackupTimeStamp = MaxTimeStamp;
	PrintLogLine(ULM_LOGLEVEL_INFO, "Backed up %d rows of new data.", BackupCount);
	return true;
}


void CuespLogMonitorDlg::UpdateDialogTitle()
{
	HRSRC hResInfo;
	DWORD dwSize;
	HGLOBAL hResData;
	LPVOID pRes, pResCopy;
	UINT uLen;
	VS_FIXEDFILEINFO *lpFfi;
	HINSTANCE hInstance = AfxGetApp()->m_hInstance;

	hResInfo = FindResource(hInstance, MAKEINTRESOURCE(VS_VERSION_INFO), RT_VERSION);
	dwSize = SizeofResource(hInstance, hResInfo);
	hResData = LoadResource(hInstance, hResInfo);
	pRes = LockResource(hResData);
	pResCopy = LocalAlloc(LMEM_FIXED, dwSize);
	CopyMemory(pResCopy, pRes, dwSize);
	FreeResource(hResData);

	BOOL Result = VerQueryValue(pResCopy, TEXT("\\"), (LPVOID*)&lpFfi, &uLen);

	DWORD dwFileVersionMS = lpFfi->dwFileVersionMS;
	DWORD dwFileVersionLS = lpFfi->dwFileVersionLS;

	DWORD dwLeftMost     = HIWORD(dwFileVersionMS);
	DWORD dwSecondLeft   = LOWORD(dwFileVersionMS);
	DWORD dwSecondRight  = HIWORD(dwFileVersionLS);
	DWORD dwRightMost    = LOWORD(dwFileVersionLS);

	LocalFree(pResCopy);

	CString Buffer;
	Buffer.Format("uespLogMonitor v%d.%d%d", dwLeftMost, dwSecondLeft, dwSecondRight);

	SetWindowText(Buffer);
}


void CuespLogMonitorDlg::OnSize(UINT nType, int cx, int cy)
{
	CDialogEx::OnSize(nType, cx, cy);

	if (nType != SIZE_MINIMIZED && IsWindow(m_LogText.m_hWnd))
	{
		m_LogText.SetWindowPos(NULL, 0, 0, cx-20, cy-20-40, SWP_NOMOVE | SWP_NOZORDER);
	}
	
}


void CuespLogMonitorDlg::OnFileSendotherlog()
{
	CFileDialog FileDlg(FALSE, nullptr, "", OFN_HIDEREADONLY, "LUA Files (*.lua)|*.lua|All Files (*.*)|*.*||", this);

	if (FileDlg.DoModal() != IDOK) return;
	std::string Buffer = FileDlg.GetPathName();

	SendEntireLog(Buffer);
}


bool CuespLogMonitorDlg::SendEntireLog (const std::string Filename)
{
	PrintLogLine(ULM_LOGLEVEL_INFO, "Sending log file '%s'...", Filename.c_str());
	m_IsCheckingFile = true;

	if (HasQueuedData()) 
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Sending remaining queued log data...");
		SendQueuedData();
	}

	if (!LoadSavedVars(Filename))
	{
		m_IsCheckingFile = false;
		return false;
	}

			/* Send any data that needs to be updated */
	bool Result = SendAllLogData();

	eso::PrintLog("LUA Stack size = %d", lua_gettop(m_pLuaState));
	lua_settop(m_pLuaState, 0);

	m_IsCheckingFile = false;
	return Result;
}


void CuespLogMonitorDlg::OnFileChecklognow()
{
	DoLogCheck(true);
}


void CuespLogMonitorDlg::OnBnClickedChecknowButton()
{
	DoLogCheck(true);
}
