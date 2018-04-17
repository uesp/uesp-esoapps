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

	v0.20 - December 2015
		- Added support for automatic uploading of character build data.
		- Fix for loading Lua files with a mix of number and non-number keys.

	v0.30 - 4 March 2016
		- Added character data uploading support.
		- Remote error messages are output when a form upload/parse fails.
		- Build data uploading correctly follows the "enabled" flag.

	v0.40 - 29 May 2016
		- Added support for parsing crafting bag data from log files.
		- Fixed "Send Other File" to include build and character data.

	v0.50 - 22 May 2017
		- Improved mutex handling to prevent many "Failed to wait for send queue mutex!" errors.
		- Scrolling of log text improved to stay at bottom of log unless you manually scrolled elsewhere.
		- Log text is no longer all selected at startup.
		- Prevent closing dialog when the ESC key is pressed.
		- Disabled messages when "0 elements" are removed from a section.
		- Shortened the message when the log file size hasn't changed.
		- Added the date/time to log messages.
		- Removed unnecessary delays when sending data that makes it much faster.
		- Output data is now compressed which makes sending it much faster (x5 on average).
		- Increased the amount of log data sent per request now that it is compressed.
		- Skipped an unecessary log check after log entries are removed and the log is saved.
		- Removed the "Check Now" button.
		- Added the option to automatically or manually download the latest sales price data from
				http://esosales.uesp.net/salesPrices.shtml
		  Set your server in the options menu. Automatic downloading only occurs if enabled and only
		  once every 1 hour. You can manually download the latest price data using the 
		  "File-Download Price List" menu item.
		- Added the "Clear Log Text" in the view menu to clear all existing log texts.
		- Changed the default backup and build data backups to be empty (disabled). This only 
		  affects new installations.
		- Added warnings if any of the backup file/folders is too large on startup.
		- Added menu items in the "File" menu to delete log/build/character backup data if it exists.
		- Added "Check File Size" to the "View" menu to show the file sizes in the log.

	v0.60 - ? April 2018
		- Now is able to upload screenshot files taken along with character or build data. There is an
		  option to disable it in program settings (default is on).
		- Fix crash bug if the info data section has table data values.
		- Price list downloads are no longer cached in order to ensure the latest version is received.
		- Price list downloads are now done asynchronously.
		- uespSalesPrices.lua is downloaded into its own add-on directory.
		- The uespSalesPrices.lua file is downloaded compressed to save time.

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
const std::string ulm_options_t::DEFAULT_BACKUPDATAFILENAME("");
const std::string ulm_options_t::DEFAULT_BACKUPBUILDDATAFOLDER("");
const std::string ulm_options_t::DEFAULT_BACKUPCHARDATAFOLDER("");
const std::string ulm_options_t::DEFAULT_BUILDDATA_FORMURL("content3.uesp.net/esobuilddata/parseBuildData.php");
const std::string ulm_options_t::DEFAULT_CHARDATA_FORMURL("content3.uesp.net/esobuilddata/parseCharData.php");
const std::string ulm_options_t::DEFAULT_PRICESERVER("NA");

const char ULM_REGISTRY_SECTION_SETTINGS[] = "Settings";
const char ULM_REGISTRY_KEY_UPDATETIME[] = "UpdateTime";
const char ULM_REGISTRY_KEY_USELOGNAME[] = "UseLogName";
const char ULM_REGISTRY_KEY_CUSTOMLOGNAME[] = "CustomLogName";
const char ULM_REGISTRY_KEY_UESPWIKIUSERNAME[] = "UespWikiUserName";
const char ULM_REGISTRY_KEY_FORMURL[] = "FormURL";
const char ULM_REGISTRY_KEY_BUILDDATAFORMURL[] = "BuildDataFormURL";
const char ULM_REGISTRY_KEY_CHARDATAFORMURL[] = "CharDataFormURL";
const char ULM_REGISTRY_KEY_ENABLED[] = "Enabled";
const char ULM_REGISTRY_KEY_BUILDDATAENABLED[] = "BuildDataEnabled";
const char ULM_REGISTRY_KEY_CHARDATAENABLED[] = "CharDataEnabled";
const char ULM_REGISTRY_KEY_SAVEDVARPATH[] = "SavedVarPath";
const char ULM_REGISTRY_KEY_LASTTIMESTAMP[] = "LastTimeStamp";
const char ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP[] = "LastBackupTimeStamp";
const char ULM_REGISTRY_KEY_LOGLEVEL[] = "LogLevel";
const char ULM_REGISTRY_KEY_BACKUPDATAFILENAME[] = "BackupDataFilename";
const char ULM_REGISTRY_KEY_BACKUPBUILDDATAFOLDER[] = "BackupBuildDataFolder";
const char ULM_REGISTRY_KEY_BACKUPCHARDATAFOLDER[] = "BackupCharDataFolder";
const char ULM_REGISTRY_KEY_PRICESERVER[] = "PriceServer";
const char ULM_REGISTRY_KEY_AUTODOWNLOADPRICES[] = "AutoDownloadPrices";
const char ULM_REGISTRY_KEY_UPLOADSCREENSHOTS[] = "UploadScreenshots";

const std::string ULM_LOGSTRING_JOIN("#STR#");
const int  ULM_LOGSTRING_MAXLENGTH = 1900;

const ULONGLONG ULM_MINIMUM_LOGCHECK_TIMEMS = 5000;
const DWORD ULM_FILE_MONITOR_TIMER = 2000;

const DWORD ULM_PRICEDOWNLOAD_PERIODMS = 1000 * 3600;

const __int64 ULM_WARN_BACKUP_DATASIZE = 500000000;
const __int64 ULM_WARN_CHARBACKUP_DATASIZE = 100000000;
const __int64 ULM_WARN_BUILDBACKUP_DATASIZE = 100000000;

const char ULM_SAVEDVAR_NAME[] = "uespLogSavedVars";
const char ULM_SAVEDVAR_FILENAME[] = "uespLog.lua";
const char ULM_SAVEDVAR_BASEPATH[] = "Elder Scrolls Online\\live\\SavedVariables\\";
const char ULM_SAVEDVAR_ALTBASEPATH[] = "Elder Scrolls Online\\liveeu\\SavedVariables\\";
const char ULM_PRICEDOWNLOAD_URLBASE[] = "http://esosales.uesp.net/";

const int ULM_SENDDATA_MAXPOSTSIZE = 500000;		/* Maximum desired size of post data in bytes before compression */

const int ULM_TIMER_ID  = 5566;
const int ULM_TIMER_ID2 = 6655;


#ifdef _DEBUG
	#define new DEBUG_NEW
#endif


BEGIN_MESSAGE_MAP(CuespLogMonitorDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_COMMAND(ID_FILE_EXIT, &CuespLogMonitorDlg::OnFileExit)
	ON_WM_TIMER()
	ON_COMMAND(ID_VIEW_OPTIONS, &CuespLogMonitorDlg::OnViewOptions)
	ON_WM_SIZE()
	ON_COMMAND(ID_FILE_SENDOTHERLOG, &CuespLogMonitorDlg::OnFileSendotherlog)
	ON_COMMAND(ID_FILE_CHECKLOGNOW, &CuespLogMonitorDlg::OnFileChecklognow)
	ON_BN_CLICKED(IDC_CHECKNOW_BUTTON, &CuespLogMonitorDlg::OnBnClickedChecknowButton)
	ON_COMMAND(ID_FILE_DOWNLOADPRICELIST, &CuespLogMonitorDlg::OnFileDownloadpricelist)
	ON_COMMAND(ID_VIEW_CLEARLOG, &CuespLogMonitorDlg::OnViewClearlog)
	ON_COMMAND(ID_FILE_DELETELOGBACKUP, &CuespLogMonitorDlg::OnFileDeletelogbackup)
	ON_UPDATE_COMMAND_UI(ID_FILE_DELETELOGBACKUP, &CuespLogMonitorDlg::OnUpdateFileDeletelogbackup)
	ON_COMMAND(ID_FILE_DELETEBUILDBACKUP, &CuespLogMonitorDlg::OnFileDeletebuildbackup)
	ON_UPDATE_COMMAND_UI(ID_FILE_DELETEBUILDBACKUP, &CuespLogMonitorDlg::OnUpdateFileDeletebuildbackup)
	ON_COMMAND(ID_FILE_DELETECHARBACKUP, &CuespLogMonitorDlg::OnFileDeletecharbackup)
	ON_UPDATE_COMMAND_UI(ID_FILE_DELETECHARBACKUP, &CuespLogMonitorDlg::OnUpdateFileDeletecharbackup)
	ON_COMMAND(ID_VIEW_CHECKFILESIZES, &CuespLogMonitorDlg::OnViewCheckfilesizes)
	ON_WM_INITMENUPOPUP()
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
	m_FileMonitorTimerId(0),
	m_SkipNextFileMonitor(false),
	m_LastLogFileSize(0),
	m_IsInTray(false),
	m_IsCheckingFile(false),
	m_hSendQueueThread(NULL),
	m_hSendQueueMutex(NULL),
	m_StopSendQueueThread(0),
	m_BuildDataValidScreenshotCount(0),
	m_CharDataCount(0),
	m_FormErrorRetryCount(0),
	m_LastLogCheckTime(0),
	m_LastPriceDownloadTime(0),
	m_hFileMonitor(INVALID_HANDLE_VALUE),
	m_hPriceDownloadThread(NULL)
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
	StopFileMonitor();
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
	DestroyTimer();

	m_TimerId = SetTimer(ULM_TIMER_ID, m_Options.UpdateTime * 1000, NULL);

	m_FileMonitorTimerId = SetTimer(ULM_TIMER_ID2, ULM_FILE_MONITOR_TIMER, NULL);
}


void CuespLogMonitorDlg::DestroyTimer (void)
{
	if (m_TimerId > 0)
	{
		KillTimer(m_TimerId);
		m_TimerId = 0;
	}

	if (m_FileMonitorTimerId > 0)
	{
		KillTimer(m_FileMonitorTimerId);
		m_FileMonitorTimerId = 0;
	}
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
			
			if (Value <= 0 || Value > MaxValidIndex)
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
	if (VarName != "$AccountWide")
	{
		return ParseSavedVarCharacterAccount(VarName, pUserData);
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Parsing data sections in saved variable log for account '%s'...", VarName.c_str());

	ParseSavedVarDataSection("globals",			&CuespLogMonitorDlg::ParseSavedVarGlobals);
	ParseSavedVarDataSection("all",				&CuespLogMonitorDlg::ParseSavedVarAll);
	ParseSavedVarDataSection("achievements",	&CuespLogMonitorDlg::ParseSavedVarAchievements);

	ParseSavedVarDataSection("buildData",		&CuespLogMonitorDlg::ParseSavedVarBuildData);
	ParseSavedVarDataSection("bankData",        &CuespLogMonitorDlg::ParseSavedVarBankData);
	ParseSavedVarDataSection("craftBagData",    &CuespLogMonitorDlg::ParseSavedVarCraftBagData);

	ParseSavedVarDataSection("info",			&CuespLogMonitorDlg::ParseSavedVarInfo);
	
	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarCharacterAccount (const std::string VarName, void* pUserData)
{
	PrintLogLine(ULM_LOGLEVEL_INFO, "Parsing data sections in saved variable log for character '%s'...", VarName.c_str());

	ParseSavedVarDataSection("charData", &CuespLogMonitorDlg::ParseSavedVarCharData);

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
		if (lua_type(m_pLuaState, -2) == LUA_TSTRING && lua_type(m_pLuaState, -1) == LUA_TSTRING)
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


bool CuespLogMonitorDlg::ParseSavedVarBuildData(const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	m_BuildData = "";
	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in buildData section!");
		return false;
	}

	int numObjects = lua_rawlen(m_pLuaState, -1);

	m_BuildData = GetLuaVariableString("uespBuildData", false);

	if (m_BuildData.empty())
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to parse the buildData variable data!");
		return false;
	}

	if (m_BuildData.size() < CuespLogMonitorDlg::MINIMUM_VALID_BUILDDATA_SIZE)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found the buildData section with no characters.");
		m_BuildData.clear();
		lua_pop(m_pLuaState, 1);
		return true;
	}

	m_BuildData += "\n";
	m_BuildData += "uespBuildData.UserName = '";
	m_BuildData += GetCurrentUserName();
	m_BuildData += "'\n";
	m_BuildData += "uespBuildData.WikiUser = '";
	m_BuildData += m_Options.UespWikiAccountName;
	m_BuildData += "'\n";

	ParseBuildDataScreenshots(numObjects);

	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the buildData section with %d characters (%u bytes).", numObjects, m_BuildData.length());
	PrintLogLine(ULM_LOGLEVEL_INFO, "Found %d valid screenShot files for the character data.", m_BuildDataValidScreenshotCount);
	lua_pop(m_pLuaState, 1);

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarCharData(const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in charData account section!");
		return false;
	}

	int numObjects = lua_rawlen(m_pLuaState, -1);

	char nameBuffer[256];
	snprintf(nameBuffer, 250, "uespCharData[%d]", m_CharDataCount + 1);
	
	std::string dataString = GetLuaVariableString(nameBuffer, false);

	if (dataString.empty())
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to parse the charData variable data!");
		return false;
	}

	if (dataString.size() < CuespLogMonitorDlg::MINIMUM_VALID_CHARDATA_SIZE)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found the charData section with no content.");
		lua_pop(m_pLuaState, 1);
		return true;
	}

	++m_CharDataCount;
	if (m_CharData.empty()) m_CharData = "uespCharData = {}\n";

	m_CharData += "\n";
	m_CharData += dataString;

	m_CharData += "\n";
	m_CharData += nameBuffer;
	m_CharData += ".UserName = '";
	m_CharData += GetCurrentUserName();
	m_CharData += "'\n";
	m_CharData += nameBuffer;
	m_CharData += ".WikiUser = '";
	m_CharData += m_Options.UespWikiAccountName;
	m_CharData += "'\n";

	ParseCharDataScreenshots(true);

	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the charData section with %d rows (%u bytes).", numObjects, m_CharData.length());
	lua_pop(m_pLuaState, 1);

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarBankData (const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in bankData account section!");
		return false;
	}
		
	int numObjects = lua_rawlen(m_pLuaState, -1);

	char nameBuffer[256];
	snprintf(nameBuffer, 250, "uespCharData[%d]", m_CharDataCount + 1);

	std::string dataString = GetLuaVariableString(nameBuffer, false);

	if (dataString.empty())
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to parse the bankData variable data!");
		return false;
	}

	if (dataString.size() < CuespLogMonitorDlg::MINIMUM_VALID_CHARDATA_SIZE)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found the bankData section with no content.");
		lua_pop(m_pLuaState, 1);
		return true;
	}

	++m_CharDataCount;
	if (m_CharData.empty()) m_CharData = "uespCharData = {}\n";

	m_CharData += "\n";
	m_CharData += dataString;

	m_CharData += "\n";
	m_CharData += nameBuffer;
	m_CharData += ".UserName = '";
	m_CharData += GetCurrentUserName();
	m_CharData += "'\n";
	m_CharData += nameBuffer;
	m_CharData += ".WikiUser = '";
	m_CharData += m_Options.UespWikiAccountName;
	m_CharData += "'\n";
	m_CharData += nameBuffer;
	m_CharData += ".IsBank = 1\n";

	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the bankData section with %d rows (%u bytes).", numObjects, m_CharData.length());
	lua_pop(m_pLuaState, 1);

	return true;
}


bool CuespLogMonitorDlg::ParseSavedVarCraftBagData(const std::string VarName, void* pUserData)
{
	std::string Version = ParseSavedVarDataVersion();

	lua_getfield(m_pLuaState, -1, "data");

	if (lua_isnil(m_pLuaState, -1))
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to find the 'data' field in craftBagData account section!");
		return false;
	}

	int numObjects = lua_rawlen(m_pLuaState, -1);

	char nameBuffer[256];
	snprintf(nameBuffer, 250, "uespCharData[%d]", m_CharDataCount + 1);

	std::string dataString = GetLuaVariableString(nameBuffer, false);

	if (dataString.empty())
	{
		lua_pop(m_pLuaState, 1);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to parse the craftBagData variable data!");
		return false;
	}

	if (dataString.size() < CuespLogMonitorDlg::MINIMUM_VALID_CHARDATA_SIZE)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found the craftBagData section with no content.");
		lua_pop(m_pLuaState, 1);
		return true;
	}

	++m_CharDataCount;
	if (m_CharData.empty()) m_CharData = "uespCharData = {}\n";

	m_CharData += "\n";
	m_CharData += dataString;

	m_CharData += "\n";
	m_CharData += nameBuffer;
	m_CharData += ".UserName = '";
	m_CharData += GetCurrentUserName();
	m_CharData += "'\n";
	m_CharData += nameBuffer;
	m_CharData += ".WikiUser = '";
	m_CharData += m_Options.UespWikiAccountName;
	m_CharData += "'\n";
	m_CharData += nameBuffer;
	m_CharData += ".IsCraftBag = 1\n";

	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the craftBagData section with %d rows (%u bytes).", numObjects, m_CharData.length());
	lua_pop(m_pLuaState, 1);

	return true;
}


bool CuespLogMonitorDlg::ParseBuildDataScreenshots(const int NumBuilds)
{
	bool Result = true;

	for (int i = 1; i <= NumBuilds; ++i)
	{
		lua_rawgeti(m_pLuaState, -1, i);

		if (!lua_isnil(m_pLuaState, -1))
		{
			Result &= ParseCharDataScreenshots(false);
		}

		lua_pop(m_pLuaState, 1);
	}

	return Result;
}


bool CuespLogMonitorDlg::ParseCharDataScreenshots(const bool isCharData)
{
	int index = lua_gettop(m_pLuaState);
	int i = 1;
	ulm_screenshot_t Screenshot;

	Screenshot.IsValid = false;
	Screenshot.IsBuildData = !isCharData;
	Screenshot.IsCharData = isCharData;

	lua_getfield(m_pLuaState, -1, "ScreenShot");

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Could not load the ScreenShot field!");
		lua_pop(m_pLuaState, 1);
		return false;
	}

	Screenshot.Filename = lua_tostring(m_pLuaState, -1);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Found the ScreenShot field: %s", Screenshot.Filename.c_str());
	lua_pop(m_pLuaState, 1);

	lua_getfield(m_pLuaState, -1, "ScreenShotCaption");

	if (!lua_isnil(m_pLuaState, -1))
	{
		Screenshot.Caption = lua_tostring(m_pLuaState, -1);
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found the ScreenShot caption: %s", Screenshot.Caption.c_str());
	}

	lua_pop(m_pLuaState, 1);

	if (Screenshot.Filename.length() <= 0)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Empty screenShot field!");
		return false;
	}

	bool Exists = eso::FileExists(Screenshot.Filename.c_str());

	if (Exists)
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Found ScreenShot File: %s", Screenshot.Filename.c_str());
		++m_BuildDataValidScreenshotCount;
		Screenshot.IsValid = true;

		m_Screenshots.push_back(Screenshot);
	}
	else
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Missing ScreenShot File: %s", Screenshot.Filename.c_str());
	}

	return true;
}


std::string CuespLogMonitorDlg::GetScreenshotFormQuery(const bool isCharData)
{
	std::string FormQuery;

	for (auto & it : m_Screenshots)
	{
		if (!it.IsValid) continue;
		if (it.IsCharData != isCharData) continue;

		FormQuery += "screenshot[]=";
		FormQuery += it.EncodedFileData;
		FormQuery += "&";
		FormQuery += "ssfilename[]=";
		FormQuery += it.ConvertFilename;
		FormQuery += "&";
		FormQuery += "origfilename[]=";
		FormQuery += it.Filename;
		FormQuery += "&";
		FormQuery += "sscaption[]=";
		FormQuery += it.Caption;
		FormQuery += "&";
	}

	return FormQuery;
}


bool CuespLogMonitorDlg::LoadScreenshots()
{
	bool Result = true;

	for (auto & it : m_Screenshots)
	{
		Result &= ConvertScreenshotToJpg(it);
	}

	return Result;
}


bool CuespLogMonitorDlg::LoadScreenshot(ulm_screenshot_t& Screenshot)
{
	if (!Screenshot.IsValid || Screenshot.JpgFilename.empty()) return true;

	eso::CFile File;
	fpos_t FileSize;

	if (!File.Open(Screenshot.JpgFilename, "rb"))
	{
		Screenshot.IsValid = false;
		return false;
	}
		
	FileSize = File.GetSize();

	if (FileSize <= 0 || FileSize + 100 >= INT_MAX)
	{
		Screenshot.IsValid = false;
		return false;
	}

	Screenshot.FileData.resize((size_t)FileSize);


	if (!File.ReadBytes(Screenshot.FileData.data(), (size_t)FileSize))
	{
		Screenshot.IsValid = false;
		return false;
	}

	Screenshot.IsValid = true;

	PrintLogLine(ULM_LOGLEVEL_INFO, "Loaded %u bytes from the screenshot '%s'.", Screenshot.FileData.size(), Screenshot.JpgFilename.c_str());

	Screenshot.EncodedFileData = EncodeLogDataForQuery(Screenshot.FileData);
	Screenshot.ConvertFilename = eso::RemoveFileExtension(Screenshot.Filename) + ".jpg";

	PrintLogLine(ULM_LOGLEVEL_INFO, "Encoded screenshot image to %u bytes of form data.", Screenshot.EncodedFileData.size());

	return true;
}


bool CuespLogMonitorDlg::ConvertScreenshotToJpg(ulm_screenshot_t& Screenshot)
{
	if (!Screenshot.IsValid) return true;

	CImage Image;
	HRESULT Result;

	Result = Image.Load(Screenshot.Filename.c_str());

	if (FAILED(Result))
	{
		Screenshot.IsValid = false;
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to read the PNG screenshot file '%s'!", Screenshot.Filename.c_str());
		return false;
	}

	std::string JpgFilename = std::tmpnam(nullptr);
	JpgFilename += ".jpg";

	Result = Image.Save(JpgFilename.c_str());

	if (FAILED(Result))
	{
		Screenshot.IsValid = false;
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to save the converted JPG screenshot file '%s'!", JpgFilename.c_str());
		return false;
	}

	Screenshot.JpgFilename = JpgFilename;
	PrintLogLine(ULM_LOGLEVEL_INFO, "Converted the screenshot file to a JPG '%s'!", JpgFilename.c_str());
	return LoadScreenshot(Screenshot);
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


std::string CuespLogMonitorDlg::EncodeLogDataForQuery(const CFileByteArray Data)
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

			for (i = 0; (i <4); i++)
				EncodedData += base64_chars[char_array_4[i]];

			i = 0;
		}

		++index;
	}

	if (i)
	{
		for (j = i; j < 3; j++)
			char_array_3[j] = '\0';

		char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
		char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
		char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
		char_array_4[3] = char_array_3[2] & 0x3f;

		for (j = 0; (j < i + 1); j++)
			EncodedData += base64_chars[char_array_4[j]];

		while ((i++ < 3))
			EncodedData += '=';
	}

	return EncodedData;
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


bool CuespLogMonitorDlg::SendFormData (const std::string FormURL, std::string FormQuery, bool Compress, size_t& SentSize)
{
	HINTERNET hinet, higeo, hreq;
	BOOL Result;

	SentSize = 0;

	std::string EscQuery = FormQuery;
	replaceAll(EscQuery, "+", "%2b");
	replaceAll(EscQuery, "/", "%2f");

	std::string SiteName;
	std::string PageURI; 

	size_t Pos = FormURL.find("/");

	if (Pos == std::string::npos)
	{
		SiteName = FormURL;
	}
	else
	{
		SiteName.assign(FormURL, 0, Pos);
		PageURI.assign(FormURL, Pos, FormURL.size() - Pos);
	}

	hinet = InternetOpen("MyBrowser/1.0", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
	higeo = InternetConnect(hinet, SiteName.c_str(), INTERNET_DEFAULT_HTTP_PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
	hreq = HttpOpenRequest(higeo, "POST", PageURI.c_str(), "", SiteName.c_str(), NULL, INTERNET_FLAG_KEEP_CONNECTION | INTERNET_FLAG_FORMS_SUBMIT, 0);

	HttpAddRequestHeaders(hreq, "Content-Type: application/x-www-form-urlencoded", -1, HTTP_ADDREQ_FLAG_ADD | HTTP_ADDREQ_FLAG_REPLACE);

	if (Compress)
	{
		byte* pCompressedData = new byte[EscQuery.size() + 200];
		size_t CompressedSize = 0;

		bool CompressResult = eso::DeflateZlibBlock(pCompressedData, CompressedSize, EscQuery.size() + 90, (eso::byte *) EscQuery.c_str(), EscQuery.size());

		if (CompressResult)
		{
			//PrintLogLine("Sending Compressed Data: %d -> %d", EscQuery.size(), CompressedSize);
			HttpAddRequestHeaders(hreq, "Content-Encoding: gzip", -1, HTTP_ADDREQ_FLAG_ADD | HTTP_ADDREQ_FLAG_REPLACE);
			Result = HttpSendRequest(hreq, 0, 0, (void *)pCompressedData, CompressedSize);
			SentSize = CompressedSize;
		}
		else
		{
			PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to compress the HTTP form request data!");
			Compress = false;
		}

		delete[] pCompressedData;
	}

	if (!Compress)
	{
		HttpAddRequestHeaders(hreq, "Content-Encoding", -1, HTTP_ADDREQ_FLAG_REPLACE);
		Result = HttpSendRequest(hreq, 0, 0, (void *)EscQuery.c_str(), EscQuery.size());
		SentSize = EscQuery.size();
	}

	if (!Result)
	{
		SentSize = 0;
		InternetCloseHandle(hreq);
		InternetCloseHandle(higeo);
		InternetCloseHandle(hinet);
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to send the HTTP form request!");
		return false;
	}
	
	char Buffer[1220];
	DWORD Size = 1200;
	
	Result = HttpQueryInfo(hreq, HTTP_QUERY_STATUS_CODE, &Buffer, &Size, NULL);
	
	char ErrorBuffer[1220] = "X-Uesp-Error";
	DWORD ErrorSize = 1200;
	DWORD ErrorResult = HttpQueryInfo(hreq, HTTP_QUERY_CUSTOM, (LPVOID)ErrorBuffer, &ErrorSize, NULL);
	if (!ErrorResult) strcpy(ErrorBuffer, "Unknown Error!");

	InternetCloseHandle(hreq);
	InternetCloseHandle(higeo);
	InternetCloseHandle(hinet);

	if (!Result) 
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to receive a HTTP response when sending form data! %s", ErrorBuffer);
		++m_FormErrorRetryCount;
		return false;
	}
	
	if (strcmp(Buffer, "200") != 0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Received a '%s' HTTP response when sending form data! %s", Buffer, ErrorBuffer);
		++m_FormErrorRetryCount;
		return false;
	}

	m_FormErrorRetryCount = 0;
	return true;
}


bool CuespLogMonitorDlg::SendQueuedData ()
{
	return true; // The send queue thread will automatically send data now
}


bool CuespLogMonitorDlg::SendQueuedBuildDataThread()
{
	std::string FormQuery;
	std::string CurrentData;
	size_t SentSize = 0;

	if (m_BuildDataQueue.empty()) return true;
	if (CuespLogMonitorDlg::BUILDDATA_UPLOAD_TESTONLY) return true;

	if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

	CurrentData = m_BuildDataQueue;
	m_BuildDataQueue.clear();

	ReleaseMutex(m_hSendQueueMutex);

	std::string TempData = EncodeLogDataForQuery(CurrentData);
	FormQuery += "chardata=";
	FormQuery += TempData;
	FormQuery += "&";
	if (m_Options.UploadScreenshots) FormQuery += GetScreenshotFormQuery(false);

	bool Result = SendFormData(m_Options.BuildDataFormURL, FormQuery, true, SentSize);

	if (!Result)
	{
		if (m_FormErrorRetryCount > MAXIMUM_FORMERROR_RETRYCOUNT)
		{
			m_FormErrorRetryCount = 0;
			PrintLogLine(ULM_LOGLEVEL_INFO, "Exceeded %d failed send attempts...aborting send of build data!", MAXIMUM_FORMERROR_RETRYCOUNT);
		}
		else
		{
			if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0)
			{
				PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
				return false;
			}

			m_BuildDataQueue += CurrentData;
			ReleaseMutex(m_hSendQueueMutex);
		}

		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %u bytes of build data!", SentSize);
	return true;
}


bool CuespLogMonitorDlg::SendQueuedCharDataThread()
{
	std::string FormQuery;
	std::string CurrentData;
	size_t SentSize = 0;

	if (m_CharDataQueue.empty()) return true;
	if (CuespLogMonitorDlg::CHARDATA_UPLOAD_TESTONLY) return true;

	if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

	CurrentData = m_CharDataQueue;
	m_CharDataQueue.clear();

	ReleaseMutex(m_hSendQueueMutex);

	std::string TempData = EncodeLogDataForQuery(CurrentData);
	FormQuery += "chardata=";
	FormQuery += TempData;
	FormQuery += "&";
	if (m_Options.UploadScreenshots) FormQuery += GetScreenshotFormQuery(true);

	if (!SendFormData(m_Options.CharDataFormURL, FormQuery, true, SentSize))
	{
		if (m_FormErrorRetryCount > MAXIMUM_FORMERROR_RETRYCOUNT)
		{
			m_FormErrorRetryCount = 0;
			PrintLogLine(ULM_LOGLEVEL_INFO, "Exceeded %d failed send attempts...aborting send of character data!", MAXIMUM_FORMERROR_RETRYCOUNT);
		}
		else
		{
			if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0)
			{
				PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
				return false;
			}

			m_CharDataQueue += CurrentData;
			ReleaseMutex(m_hSendQueueMutex);
		}

		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %u bytes of character data!", SentSize);
	return true;
}


bool CuespLogMonitorDlg::SendQueuedDataThread()
{
	CUlmLogDataArray SentData;
	std::string FormQuery;
	size_t i = 0;
	size_t LastIndex = -1;
	size_t SentSize = 0;

	if (m_SendQueue.size() == 0) return true;

	if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0) 
	{ 
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
		return false;
	}

	size_t OrigQueueSize = m_SendQueue.size();

	for (i = 0; i < m_SendQueue.size(); ++i)
	{
		LastIndex = i;
		SentData.push_back(m_SendQueue[i]);

		std::string TempData = EncodeLogDataForQuery(m_SendQueue[i].Data);

		FormQuery += "log[]=";
		FormQuery += TempData;
		FormQuery += "&";

		if (FormQuery.size() > ULM_SENDDATA_MAXPOSTSIZE)
		{
			break;
		}
	}

	m_SendQueue.erase(m_SendQueue.begin(), m_SendQueue.begin() + LastIndex + 1);
	ReleaseMutex(m_hSendQueueMutex);

	if (FormQuery.size() <= 0) return true;

	if (!SendFormData(m_Options.FormURL, FormQuery, true, SentSize)) 
	{
		if (m_FormErrorRetryCount > MAXIMUM_FORMERROR_RETRYCOUNT)
		{
			m_FormErrorRetryCount = 0;
			PrintLogLine(ULM_LOGLEVEL_INFO, "Exceeded %d failed send attempts...aborting send of log data!", MAXIMUM_FORMERROR_RETRYCOUNT);
		}
		else
		{
			if (WaitForSingleObject(m_hSendQueueMutex, INFINITE) != WAIT_OBJECT_0)
			{
				PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex!");
				return false;
			}

			m_SendQueue.insert(m_SendQueue.end(), SentData.begin(), SentData.end());

			ReleaseMutex(m_hSendQueueMutex);
		}

		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sent %d of %d log entries in %d bytes!", LastIndex + 1, OrigQueueSize, SentSize);

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


bool CuespLogMonitorDlg::CheckAndSendBuildData()
{
	bool Result = true;

	if (!m_Options.BuildDataEnabled) return true;

	Result &= BackupBuildData();
	Result &= QueueBuildData();

	return Result;
}


bool CuespLogMonitorDlg::CheckAndSendCharData()
{
	bool Result = true;

	if (!m_Options.CharDataEnabled) return true;

	Result &= BackupCharData();
	Result &= QueueCharData();

	return Result;
}



bool CuespLogMonitorDlg::QueueBuildData()
{
	if (m_BuildData.empty()) return true;

	m_BuildDataQueue += m_BuildData;

	return true;
}


bool CuespLogMonitorDlg::QueueCharData()
{
	if (m_CharData.empty()) return true;

	m_CharDataQueue += m_CharData;

	return true;
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

	PrintLogLine(ULM_LOGLEVEL_INFO, "Queued %d log entries.", SentCount);
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

	PrintLogLine(ULM_LOGLEVEL_INFO, "Queued %d log entries.", SentCount);
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
	CString CurrentDate;
	SYSTEMTIME t;

	GetLocalTime(&t);
	CurrentDate.Format("%02d-%02d %02d:%02d:%02d.%03d -- ", t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond, t.wMilliseconds);

	eso::PrintLogV(pString, Args);
	Buffer.FormatV(pString, Args);
	Buffer = CurrentDate + Buffer + "\r\n";

	CHARRANGE OrigSelRange;
	m_LogText.GetSel(OrigSelRange);

	bool IsAtBottom = false;
	long OrigTextLength = m_LogText.GetTextLength();
	SCROLLINFO ScrollInfo;
	int OrigScrollPos = m_LogText.GetScrollPos(SB_VERT);
	int nOldFirstVisibleLine = m_LogText.GetFirstVisibleLine();

	if (m_LogText.GetScrollInfo(SB_VERT, &ScrollInfo, SIF_ALL))
	{
		IsAtBottom = ((ScrollInfo.nPos + ScrollInfo.nPage >= (UINT)ScrollInfo.nMax) || ScrollInfo.nPage == 0);
	}

	m_LogText.LockWindowUpdate();

	long TextLength = m_LogText.GetTextLength();
	m_LogText.SetSel(TextLength, TextLength);
	m_LogText.ReplaceSel(Buffer, false);
	
	int nNewFirstVisibleLine = m_LogText.GetFirstVisibleLine();
	if (nOldFirstVisibleLine != nNewFirstVisibleLine) m_LogText.LineScroll(nOldFirstVisibleLine - nNewFirstVisibleLine);
	
		/* Force scroll to bottom with no text selection */
	if (IsAtBottom)
	{
		TextLength = m_LogText.GetTextLength();
		m_LogText.SetSel(TextLength, TextLength);
		m_LogText.SendMessage(WM_VSCROLL, SB_BOTTOM, NULL);
	}

	if (OrigSelRange.cpMax != OrigSelRange.cpMin) m_LogText.SetSel(OrigSelRange);
	m_LogText.UnlockWindowUpdate();
	m_LogText.RedrawWindow();
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
		SendQueuedDataThread();
		Sleep(100);

		SendQueuedBuildDataThread();
		Sleep(100);

		SendQueuedCharDataThread();
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

	InitializeFileMonitor();

	InitSendQueueThread();

	m_LogText.SetOptions(ECOOP_OR, ECO_SAVESEL);

	PrintLogLine(ULM_LOGLEVEL_INFO, "Program initialized...");
	PrintSettings();

	CheckBackupDataSize();
	CheckCharBackupDataSize();
	CheckBuildBackupDataSize();

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

	if (CuespLogMonitorDlg::CHARDATA_UPLOAD_TESTONLY) PrintLogLine(ULM_LOGLEVEL_INFO, "WARNING: CHARDATA_UPLOAD_TESTONLY is on! Not uploading char data!");
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
	m_Options.BuildDataEnabled = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BUILDDATAENABLED, m_Options.BuildDataEnabled) != 0);
	m_Options.CharDataEnabled = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAENABLED, m_Options.CharDataEnabled) != 0);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CUSTOMLOGNAME, m_Options.CustomLogName.c_str());
	m_Options.CustomLogName = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UESPWIKIUSERNAME, m_Options.UespWikiAccountName.c_str());
	m_Options.UespWikiAccountName = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTTIMESTAMP, "0");
	m_Options.LastTimeStamp = _atoi64(Buffer);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP, "0");
	m_Options.LastBackupTimeStamp = _atoi64(Buffer);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_SAVEDVARPATH, m_Options.SavedVarPath.c_str());
	m_Options.SavedVarPath = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPDATAFILENAME, m_Options.BackupDataFilename.c_str());
	m_Options.BackupDataFilename = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPBUILDDATAFOLDER, m_Options.BackupBuildDataFolder.c_str());
	m_Options.BackupBuildDataFolder = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPCHARDATAFOLDER, m_Options.BackupCharDataFolder.c_str());
	m_Options.BackupCharDataFolder = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_FORMURL, m_Options.FormURL.c_str());
	m_Options.FormURL = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BUILDDATAFORMURL, m_Options.BuildDataFormURL.c_str());
	m_Options.BuildDataFormURL = Buffer;

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAFORMURL, m_Options.CharDataFormURL.c_str());
	m_Options.CharDataFormURL = Buffer;

	m_Options.AutoDownloadPrices = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_AUTODOWNLOADPRICES, m_Options.AutoDownloadPrices) != 0);

	Buffer = pApp->GetProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_PRICESERVER, m_Options.PriceServer.c_str());
	m_Options.PriceServer = Buffer;	

	m_Options.UploadScreenshots = (pApp->GetProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UPLOADSCREENSHOTS, m_Options.UploadScreenshots) != 0);

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
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BUILDDATAENABLED, m_Options.BuildDataEnabled);
	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAENABLED, m_Options.CharDataEnabled);

	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CUSTOMLOGNAME, m_Options.CustomLogName.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UESPWIKIUSERNAME, m_Options.UespWikiAccountName.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_FORMURL,       m_Options.FormURL.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BUILDDATAFORMURL, m_Options.BuildDataFormURL.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_CHARDATAFORMURL, m_Options.CharDataFormURL.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_SAVEDVARPATH,  m_Options.SavedVarPath.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPDATAFILENAME, m_Options.BackupDataFilename.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPBUILDDATAFOLDER, m_Options.BackupBuildDataFolder.c_str());
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_BACKUPCHARDATAFOLDER, m_Options.BackupCharDataFolder.c_str());

	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_AUTODOWNLOADPRICES, m_Options.AutoDownloadPrices);
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_PRICESERVER, m_Options.PriceServer.c_str());

	Buffer.Format("%I64d", m_Options.LastTimeStamp);
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTTIMESTAMP, Buffer);

	Buffer.Format("%I64d", m_Options.LastBackupTimeStamp);
	pApp->WriteProfileString(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_LASTBACKUPTIMESTAMP, Buffer);

	pApp->WriteProfileInt(ULM_REGISTRY_SECTION_SETTINGS, ULM_REGISTRY_KEY_UPLOADSCREENSHOTS, m_Options.UploadScreenshots);

	return true;
}


void CuespLogMonitorDlg::OnClose()
{
	//EndDialog(0);
}


BOOL CuespLogMonitorDlg::DestroyWindow()
{
	SaveRegistrySettings();
	return CDialogEx::DestroyWindow();
}


void CuespLogMonitorDlg::OnFileExit()
{
	EndDialog(0);
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
	  //Sleep(400);

	  Result = HttpQueryInfo(hreq, HTTP_QUERY_STATUS_CODE, &Buffer, &Size, NULL);
	  eso::PrintLog("HTTP Query Info = %d (%s)", Result, Buffer);  

	  char ErrorBuffer[1220] = "X-EsoBuildData-Error";
	  DWORD ErrorSize = 1200;
	  DWORD ErrorResult = HttpQueryInfo(hreq, HTTP_QUERY_CUSTOM, (LPVOID)ErrorBuffer, &ErrorSize, NULL);
	  if (!ErrorResult) strcpy(ErrorBuffer, "Unknown Error!");

	  InternetCloseHandle(hreq);
	  InternetCloseHandle(higeo);
	  InternetCloseHandle(hinet);
}


void CuespLogMonitorDlg::OnOK()
{
}


void CuespLogMonitorDlg::InitializeFileMonitor()
{
	StopFileMonitor();

	m_hFileMonitor = FindFirstChangeNotification(m_Options.SavedVarPath.c_str(), FALSE, FILE_NOTIFY_CHANGE_LAST_WRITE);
}


void CuespLogMonitorDlg::StopFileMonitor()
{

	if (m_hFileMonitor != INVALID_HANDLE_VALUE)
	{
		FindCloseChangeNotification(m_hFileMonitor);
		m_hFileMonitor = INVALID_HANDLE_VALUE;
	}

}


void CuespLogMonitorDlg::OnLogCheckTimer()
{
	if (m_IsCheckingFile) return;
	m_IsCheckingFile = true;

	DoLogCheck();

	DoPriceDownloadCheck();

	m_IsCheckingFile = false;
}


bool CuespLogMonitorDlg::DoPriceDownloadCheck()
{
	if (!m_Options.AutoDownloadPrices) return false;

	ULONGLONG CurrentTime = GetTickCount64();
	ULONGLONG DeltaTime = CurrentTime - m_LastPriceDownloadTime;

	if (DeltaTime < ULM_PRICEDOWNLOAD_PERIODMS) return false;

	DoDownloadPriceListThread();
	
	return true;
}


DWORD WINAPI l_DoDownloadPriceListThread(LPVOID lpParameter)
{
	CuespLogMonitorDlg* pThis = (CuespLogMonitorDlg *)lpParameter;
	return pThis->DownloadPriceList();
}


bool CuespLogMonitorDlg::DoDownloadPriceListThread()
{
	DWORD result = WaitForSingleObject(m_hPriceDownloadThread, 0);

	if (m_hPriceDownloadThread == NULL || result == WAIT_OBJECT_0 || result == WAIT_FAILED)
	{
		m_hPriceDownloadThread = CreateThread(NULL, 0, l_DoDownloadPriceListThread, this, 0, NULL);
		return true;
	}

	PrintLogLine(ULM_LOGLEVEL_WARNING, "Price download is currently in progress...");
	return false;
}


bool CuespLogMonitorDlg::DownloadPriceList()
{
	CString DownloadURL(ULM_PRICEDOWNLOAD_URLBASE);
	CString TargetFile(m_Options.SavedVarPath.c_str());
	CString TmpFile;
	CString BackupFile;
	BOOL Result;

	DownloadURL += "prices";
	DownloadURL += m_Options.PriceServer.c_str();
	DownloadURL += "/uespSalesPrices.lua";
	if (DOWNLOADPRICES_AS_ZIP) DownloadURL += ".gz";

	TargetFile.Replace("\\SavedVariables", "\\AddOns\\uespLogSalesPrices");
	TargetFile += "uespSalesPrices.lua";
	TmpFile = TargetFile + ".new";
	if (DOWNLOADPRICES_AS_ZIP) TmpFile += ".gz";
	BackupFile = TargetFile + ".old";

	std::string Path = eso::ExtractPath(std::string(TargetFile));

	if (!eso::DirectoryExists(Path.c_str()))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "The upload path '%s' does not exist!", Path.c_str());
		PrintLogLine("Make sure you are running the latest version of uespLog (v1.50 or higher)!");
		return false;
	}
	
	PrintLogLine(ULM_LOGLEVEL_INFO, "Attempting to download price list from '%s'...", DownloadURL);
	PrintLogLine(ULM_LOGLEVEL_INFO, "Attempting to save price list to '%s'...", TmpFile);

	DeleteUrlCacheEntry(DownloadURL);
	HRESULT hResult = URLDownloadToFile(NULL, DownloadURL, TmpFile, 0, NULL);

	if (hResult != S_OK)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to download price list from %s!", DownloadURL);
		return false;
	}

	if (DOWNLOADPRICES_AS_ZIP)
	{
		CString TmpFile1 = TargetFile + ".new";
		eso::CFile OutputFile;
		gzFile inputFile = gzopen(TmpFile, "rb");
		const int BUFFER_SIZE = 4096;
		unsigned char buffer[BUFFER_SIZE + 32];
		int bytesRead;

		if (!OutputFile.Open(std::string(TmpFile1), "wb"))
		{
			PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to open output price data file %s!", TmpFile1);
			return false;
		}

		if (!inputFile)
		{
			PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to open zipped price data file %s!", TmpFile);
			return false;
		}
		
		do
		{
			bytesRead = gzread(inputFile, buffer, BUFFER_SIZE);

			if (bytesRead > 0)
			{
				if (!OutputFile.WriteBytes(buffer, bytesRead))
				{
					PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed writing %d bytes to file %s!", bytesRead, TmpFile);
					gzclose(inputFile);
					return false;
				}
			}

		} while (!gzeof(inputFile) && bytesRead == BUFFER_SIZE);


		gzclose(inputFile);
		TmpFile = TmpFile1;
	}	

	MoveFileEx(TargetFile, BackupFile, MOVEFILE_REPLACE_EXISTING);
	

	Result = MoveFileEx(TmpFile, TargetFile, MOVEFILE_REPLACE_EXISTING);

	if (!Result)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to copy downloaded price list to '%s'!", TargetFile);
		CopyFileEx(BackupFile, TargetFile, NULL, NULL, FALSE, 0);
		return false;
	}

	long long FileSize = 0;
	eso::GetFileSize(FileSize, (const char *) TargetFile);

	PrintLogLine("Successfully downloaded the latest %s price list data (%.1f MB)!", m_Options.PriceServer.c_str(), (float)FileSize/1000000);

	PrintLogLine(ULM_LOGLEVEL_WARNING, "Next automatic price download will be in %d minutes...", ULM_PRICEDOWNLOAD_PERIODMS / 60000);
	m_LastPriceDownloadTime = GetTickCount64();

	return true;
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

	ULONGLONG CurrentTime = GetTickCount64();
	ULONGLONG DeltaTime = CurrentTime - m_LastLogCheckTime;

	if (DeltaTime < ULM_MINIMUM_LOGCHECK_TIMEMS) return false;
	
	if (!HasLogChanged()) return false;

	m_LastLogCheckTime = CurrentTime;

	PrintLogLine(ULM_LOGLEVEL_INFO, "Checking log...");
	//PrintLogLine(ULM_LOGLEVEL_INFO, "Pre-TimeStamp: %I64d", m_Options.LastTimeStamp);
	//PrintLogLine(ULM_LOGLEVEL_INFO, "Pre-Backup TimeStamp: %I64d", m_Options.LastBackupTimeStamp);

	m_BuildData = "";
	m_CharData = "";
	m_CharDataCount = 0;
	m_Screenshots.clear();

	if (!LoadSavedVars()) return false;

	LoadScreenshots();

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

	if (!CheckAndSendBuildData())
	{
		ReleaseMutex(m_hSendQueueMutex);
		return false;
	}

	if (!CheckAndSendCharData())
	{
		ReleaseMutex(m_hSendQueueMutex);
		return false;
	}

	UpdateLogFileSize();
	m_SkipNextFileMonitor = true;

	bool Result = DeleteOldLogData();
	Result &= SaveSavedVars();

	UpdateLogFileSize();

	//eso::PrintLog("LUA Stack size = %d", lua_gettop(m_pLuaState));
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
	if (VarName != "$AccountWide")
	{
		DeleteOldLogDataSection("charData", -1, VarName);
		return true;
	}

	DeleteOldLogDataSection("all", -1, VarName);
	DeleteOldLogDataSection("globals", -1, VarName);
	DeleteOldLogDataSection("achievements", -1, VarName);
	DeleteOldLogDataSection("buildData", -1, VarName);

	DeleteOldLogDataSection("bankData", -1, VarName);
	DeleteOldLogDataSection("craftBagData", -1, VarName);

	return true;
}


bool CuespLogMonitorDlg::DeleteOldLogDataSection (const std::string Section, const int StackIndex, const std::string Parent)
{
	lua_getfield(m_pLuaState, StackIndex, Section.c_str());

	if (lua_isnil(m_pLuaState, -1))
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Failed to delete the section '%s::%s' as it doesn't exist!", Parent.c_str(), Section.c_str());
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

	if (OrigTableLength != 0) PrintLogLine(ULM_LOGLEVEL_INFO, "Removed %d elements from '%s' data.", OrigTableLength, Section.c_str());
	
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
		PrintLogLine(ULM_LOGLEVEL_INFO, "Log file size hasn't changed since last check.");
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
	else if (nIDEvent == m_FileMonitorTimerId)
	{
		OnCheckFileMonitorTimer();
		return;
	}

	CDialogEx::OnTimer(nIDEvent);
}


void CuespLogMonitorDlg::OnCheckFileMonitorTimer()
{
	DWORD dwWaitStatus = WaitForSingleObject(m_hFileMonitor, 0);

	if (dwWaitStatus == WAIT_OBJECT_0)
	{
		OnFileMonitorUpdate();
	}
}


void CuespLogMonitorDlg::OnFileMonitorUpdate()
{
	ULONGLONG CurrentTime = GetTickCount64();
	ULONGLONG DeltaTime = CurrentTime - m_LastLogCheckTime;

	if (m_SkipNextFileMonitor || DeltaTime < ULM_MINIMUM_LOGCHECK_TIMEMS)
	{
		m_SkipNextFileMonitor = false;
		FindNextChangeNotification(m_hFileMonitor);
		return;
	}

	Sleep(500);

	PrintLogLine(ULM_LOGLEVEL_INFO, "Automatically checking for changes in log file...");
		
	DoLogCheck();
	FindNextChangeNotification(m_hFileMonitor);
}


void CuespLogMonitorDlg::OnViewOptions()
{
	COptionsDlg Dlg;
	int OrigUpdateTime = m_Options.UpdateTime;

	if (Dlg.DoModal(m_Options) != IDOK) return;

	InitializeFileMonitor();

	if (OrigUpdateTime != m_Options.UpdateTime)
	{
		CreateTimer();
	}
}


bool CuespLogMonitorDlg::BackupBuildData()
{
	eso::CFile File;
	time_t rawtime;
	struct tm * timeinfo;
	char DateBuffer[80];
	std::string Filename;
	CString FilenameBuffer;
	int FileIndex = 0;

	if (m_Options.BackupBuildDataFolder.empty() || m_BuildData.empty()) return true;

	if (!eso::EnsurePathExists(m_Options.BackupBuildDataFolder))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to create the backup folder '%s'!", m_Options.BackupBuildDataFolder.c_str());
		return false;
	}

	do {

		if (FileIndex > 1000)
		{
			PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to create a build data backup filename that doesn't already exist!");
			return false;
		}

		time(&rawtime);
		timeinfo = localtime(&rawtime);
		strftime(DateBuffer, 70, "%Y-%m-%d-%H%M%S", timeinfo);

		if (FileIndex == 0)
			FilenameBuffer.Format("uespBackupBuildData-%s.txt", DateBuffer);
		else
			FilenameBuffer.Format("uespBackupBuildData-%s-%d.txt", DateBuffer, FileIndex);

		Filename = eso::TerminatePath(m_Options.BackupBuildDataFolder);
		Filename += FilenameBuffer;
		++FileIndex;
	} while (eso::FileExists(Filename.c_str()));
	
	if (!File.Open(Filename, "wb"))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to open the backup build data file '%s' for output!", Filename.c_str());
		return false;
	}

	if (!File.WriteString(m_BuildData))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to write the build data to the backup file!");
		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Backed up %u bytes of build data...", m_BuildData.size());
	return true;
}


bool CuespLogMonitorDlg::BackupCharData()
{
	eso::CFile File;
	time_t rawtime;
	struct tm * timeinfo;
	char DateBuffer[80];
	std::string Filename;
	CString FilenameBuffer;
	int FileIndex = 0;

	if (m_Options.BackupCharDataFolder.empty() || m_CharData.empty()) return true;

	if (!eso::EnsurePathExists(m_Options.BackupCharDataFolder))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to create the backup folder '%s'!", m_Options.BackupCharDataFolder.c_str());
		return false;
	}

	do {

		if (FileIndex > 1000)
		{
			PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to create a character data backup filename that doesn't already exist!");
			return false;
		}

		time(&rawtime);
		timeinfo = localtime(&rawtime);
		strftime(DateBuffer, 70, "%Y-%m-%d-%H%M%S", timeinfo);

		if (FileIndex == 0)
			FilenameBuffer.Format("uespBackupCharData-%s.txt", DateBuffer);
		else
			FilenameBuffer.Format("uespBackupCharData-%s-%d.txt", DateBuffer, FileIndex);

		Filename = eso::TerminatePath(m_Options.BackupCharDataFolder);
		Filename += FilenameBuffer;
		++FileIndex;
	} while (eso::FileExists(Filename.c_str()));

	if (!File.Open(Filename, "wb"))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to open the backup character data file '%s' for output!", Filename.c_str());
		return false;
	}

	if (!File.WriteString(m_CharData))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to write the character data to the backup file!");
		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Backed up %u bytes of character data...", m_CharData.size());
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
		m_LogText.SetWindowPos(NULL, 0, 0, cx-20, cy-20, SWP_NOMOVE | SWP_NOZORDER);
	}
	
}


void CuespLogMonitorDlg::OnFileSendotherlog()
{
	CFileDialog FileDlg(FALSE, nullptr, "", OFN_HIDEREADONLY, "LUA Files (*.lua)|*.lua|All Files (*.*)|*.*||", this);

	if (FileDlg.DoModal() != IDOK) return;
	std::string Buffer = (const char *) FileDlg.GetPathName();

	SendEntireLog(Buffer);
}


bool CuespLogMonitorDlg::SendEntireLog (const std::string Filename)
{
	if (HasQueuedData())
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "Sending remaining queued log data...");
		SendQueuedData();
	}

	if (WaitForSingleObject(m_hSendQueueMutex, 1000) != WAIT_OBJECT_0)
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "ERROR: Failed to wait for send queue mutex! Try again later...");
		return false;
	}

	PrintLogLine(ULM_LOGLEVEL_INFO, "Sending log file '%s'...", Filename.c_str());
	m_IsCheckingFile = true;

	if (!LoadSavedVars(Filename))
	{
		m_IsCheckingFile = false;
		ReleaseMutex(m_hSendQueueMutex);
		return false;
	}

			/* Send any data that needs to be updated */
	bool Result = true;
	
	Result &= CheckAndSendLogData();
	Result &= CheckAndSendBuildData();
	Result &= CheckAndSendCharData();

	ReleaseMutex(m_hSendQueueMutex);

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


BOOL CuespLogMonitorDlg::PreTranslateMessage(MSG* pMsg)
{

	if (pMsg->message == WM_KEYDOWN)
	{
		if (pMsg->wParam == VK_RETURN || pMsg->wParam == VK_ESCAPE)
		{
			return TRUE;                // Do not process further
		}
	}

	return CDialog::PreTranslateMessage(pMsg);
}


void CuespLogMonitorDlg::OnFileDownloadpricelist()
{
	DoDownloadPriceListThread();
}


void CuespLogMonitorDlg::ClearLog()
{
	m_LogText.SetWindowText("");
	PrintLogLine("Cleared all log text...");
}


void CuespLogMonitorDlg::OnViewClearlog()
{
	ClearLog();
}


void CuespLogMonitorDlg::CheckBackupDataSize()
{
	__int64 FileSize = GetBackupDataSize();
	if (FileSize <= 0) return;
	
	if (FileSize >= ULM_WARN_BACKUP_DATASIZE)
	{
		PrintLogLine("WARNING: The backup data file %s is %d MB in size!", m_Options.BackupDataFilename.c_str(), (int)(FileSize / 1000000));
	}
	else
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "The backup file is %.1f MB in size.", FileSize / 1000000.0);
	}

}


void CuespLogMonitorDlg::CheckCharBackupDataSize()
{
	__int64 DirSize = GetCharBackupDataSize();
	if (DirSize <= 0) return;
	
	if (DirSize >= ULM_WARN_CHARBACKUP_DATASIZE)
	{
		PrintLogLine("WARNING: The backup character data in %s is %d MB in size!", m_Options.BackupCharDataFolder.c_str(), (int)(DirSize / 1000000));
	}
	else
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "The backup character folder is %.1f MB in size.", DirSize / 1000000.0);
	}

}


void CuespLogMonitorDlg::CheckBuildBackupDataSize()
{
	__int64 DirSize = GetBuildBackupDataSize();
	if (DirSize <= 0) return;

	if (DirSize >= ULM_WARN_BUILDBACKUP_DATASIZE)
	{
		PrintLogLine("WARNING: The backup build data in %s is %d MB in size!", m_Options.BackupBuildDataFolder.c_str(), (int)(DirSize / 1000000));
	}
	else
	{
		PrintLogLine(ULM_LOGLEVEL_INFO, "The backup build folder is %.1f MB in size.", DirSize / 1000000.0);
	}
}


__int64 CuespLogMonitorDlg::GetBackupDataSize()
{
	__int64 FileSize;

	if (m_Options.BackupDataFilename.empty()) return 0;
	if (!eso::GetFileSize(FileSize, m_Options.BackupDataFilename)) return 0;

	return FileSize;
}


__int64 CuespLogMonitorDlg::GetCharBackupDataSize()
{
	__int64 DirSize;
	std::string FileSpec = eso::TerminatePath(m_Options.BackupCharDataFolder) + "uespBackupCharData*.txt";

	if (m_Options.BackupCharDataFolder.empty()) return 0;
	if (!eso::GetFilesSize(DirSize, FileSpec)) return 0;

	return DirSize;
}


__int64 CuespLogMonitorDlg::GetBuildBackupDataSize()
{
	__int64 DirSize;
	std::string FileSpec = eso::TerminatePath(m_Options.BackupBuildDataFolder) + "uespBackupBuildData*.txt";

	if (m_Options.BackupBuildDataFolder.empty()) return 0;
	if (!eso::GetFilesSize(DirSize, FileSpec)) return 0;

	return DirSize;
}


void CuespLogMonitorDlg::OnViewCheckfilesizes()
{
	__int64 FileSize = 0;
	eso::GetFileSize(FileSize, GetSavedVarFilename());

	__int64 BackupSize = GetBackupDataSize();
	__int64 CharSize = GetCharBackupDataSize();
	__int64 BuildSize = GetBuildBackupDataSize();

	PrintLogLine("Saved variable file is currently %0.1f MB in size.", FileSize / 1000000.0);
	PrintLogLine("Backup log file is currently %0.1f MB in size.", BackupSize / 1000000.0);
	PrintLogLine("Backup build data is currently %0.1f MB in size.", BuildSize / 1000000.0);
	PrintLogLine("Backup character data is currently %0.1f MB in size.", CharSize / 1000000.0);
}


void CuespLogMonitorDlg::OnFileDeletelogbackup()
{
	__int64 FileSize = GetBackupDataSize();
	CString Buffer;

	if (FileSize <= 0) return;

	Buffer.Format("Do you really wish to delete the file '%s' containing %0.1fMB of backup log data?\r\nThis action cannot be undone!", m_Options.BackupDataFilename.c_str(), FileSize / 1000000.0);
	int Result = AfxMessageBox(Buffer, MB_OKCANCEL);
	if (Result != IDOK) return;

	PrintLogLine("Deleting backup log file '%s' with %0.1f MB of data...", m_Options.BackupDataFilename.c_str(), FileSize / 1000000.0);

	if (!DeleteFile(m_Options.BackupDataFilename.c_str()))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to delete the backup log file '%s'!", m_Options.BackupDataFilename.c_str());
	}
}


void CuespLogMonitorDlg::OnUpdateFileDeletelogbackup(CCmdUI *pCmdUI)
{
	__int64 FileSize = GetBackupDataSize();
	pCmdUI->Enable(FileSize > 0);
}


void CuespLogMonitorDlg::OnFileDeletebuildbackup()
{
	__int64 FileSize = GetBuildBackupDataSize();
	CString Buffer;

	if (FileSize <= 0) return;

	Buffer.Format("Do you really wish to delete files in '%s' containing %0.1fMB of data?\r\nThis action cannot be undone!", m_Options.BackupBuildDataFolder.c_str(), FileSize / 1000000.0);
	int Result = AfxMessageBox(Buffer, MB_OKCANCEL);
	if (Result != IDOK) return;

	PrintLogLine("Deleting all build backup log data in '%s' containing %0.1f MB of data...", m_Options.BackupBuildDataFolder.c_str(), FileSize / 1000000.0);

	std::string FileSpec = eso::TerminatePath(m_Options.BackupBuildDataFolder) + "uespBackupBuildData*.txt";

	if (!eso::DeleteFiles(FileSpec))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to delete the backup build data files matching '%s'!", FileSpec.c_str());
	}
}


void CuespLogMonitorDlg::OnUpdateFileDeletebuildbackup(CCmdUI *pCmdUI)
{
	__int64 FileSize = GetBuildBackupDataSize();
	pCmdUI->Enable(FileSize > 0);
}


void CuespLogMonitorDlg::OnFileDeletecharbackup()
{
	__int64 FileSize = GetCharBackupDataSize();
	CString Buffer;

	if (FileSize <= 0) return;

	Buffer.Format("Do you really wish to delete files in '%s' containing %0.1fMB of data?\r\nThis action cannot be undone!", m_Options.BackupCharDataFolder.c_str(), FileSize / 1000000.0);
	int Result = AfxMessageBox(Buffer, MB_OKCANCEL);
	if (Result != IDOK) return;

	PrintLogLine("Deleting all character backup log data in '%s' containing %0.1f MB of data...", m_Options.BackupCharDataFolder.c_str(), FileSize / 1000000.0);

	std::string FileSpec = eso::TerminatePath(m_Options.BackupCharDataFolder) + "uespBackupCharData*.txt";

	if (!eso::DeleteFiles(FileSpec))
	{
		PrintLogLine(ULM_LOGLEVEL_ERROR, "Failed to delete the backup character data files matching '%s'!", FileSpec.c_str());
	}
}


void CuespLogMonitorDlg::OnUpdateFileDeletecharbackup(CCmdUI *pCmdUI)
{
	__int64 FileSize = GetCharBackupDataSize();
	pCmdUI->Enable(FileSize > 0);
}


void CuespLogMonitorDlg::OnInitMenuPopup(CMenu *pPopupMenu, UINT nIndex, BOOL bSysMenu)
{
	ASSERT(pPopupMenu != NULL);
	// Check the enabled state of various menu items.

	CCmdUI state;
	state.m_pMenu = pPopupMenu;
	ASSERT(state.m_pOther == NULL);
	ASSERT(state.m_pParentMenu == NULL);

	// Determine if menu is popup in top-level menu and set m_pOther to
	// it if so (m_pParentMenu == NULL indicates that it is secondary popup).
	HMENU hParentMenu;
	if (AfxGetThreadState()->m_hTrackingMenu == pPopupMenu->m_hMenu)
		state.m_pParentMenu = pPopupMenu;    // Parent == child for tracking popup.
	else if ((hParentMenu = ::GetMenu(m_hWnd)) != NULL)
	{
		CWnd* pParent = this;
		// Child windows don't have menus--need to go to the top!
		if (pParent != NULL &&
			(hParentMenu = ::GetMenu(pParent->m_hWnd)) != NULL)
		{
			int nIndexMax = ::GetMenuItemCount(hParentMenu);
			for (int nIndex = 0; nIndex < nIndexMax; nIndex++)
			{
				if (::GetSubMenu(hParentMenu, nIndex) == pPopupMenu->m_hMenu)
				{
					// When popup is found, m_pParentMenu is containing menu.
					state.m_pParentMenu = CMenu::FromHandle(hParentMenu);
					break;
				}
			}
		}
	}

	state.m_nIndexMax = pPopupMenu->GetMenuItemCount();
	for (state.m_nIndex = 0; state.m_nIndex < state.m_nIndexMax;
	state.m_nIndex++)
	{
		state.m_nID = pPopupMenu->GetMenuItemID(state.m_nIndex);
		if (state.m_nID == 0)
			continue; // Menu separator or invalid cmd - ignore it.

		ASSERT(state.m_pOther == NULL);
		ASSERT(state.m_pMenu != NULL);
		if (state.m_nID == (UINT)-1)
		{
			// Possibly a popup menu, route to first item of that popup.
			state.m_pSubMenu = pPopupMenu->GetSubMenu(state.m_nIndex);
			if (state.m_pSubMenu == NULL ||
				(state.m_nID = state.m_pSubMenu->GetMenuItemID(0)) == 0 ||
				state.m_nID == (UINT)-1)
			{
				continue;       // First item of popup can't be routed to.
			}
			state.DoUpdate(this, TRUE);   // Popups are never auto disabled.
		}
		else
		{
			// Normal menu item.
			// Auto enable/disable if frame window has m_bAutoMenuEnable
			// set and command is _not_ a system command.
			state.m_pSubMenu = NULL;
			state.DoUpdate(this, FALSE);
		}

		// Adjust for menu deletions and additions.
		UINT nCount = pPopupMenu->GetMenuItemCount();
		if (nCount < state.m_nIndexMax)
		{
			state.m_nIndex -= (state.m_nIndexMax - nCount);
			while (state.m_nIndex < nCount &&
				pPopupMenu->GetMenuItemID(state.m_nIndex) == state.m_nID)
			{
				state.m_nIndex++;
			}
		}
		state.m_nIndexMax = nCount;
	}
}