#pragma once
#include "afxcmn.h"
#include "../../common/EsoCommon.h"


	/* Type of name to use for logging */
enum ulm_uselogname_t {
		ULM_USELOGNAME_ANONYMOUS,
		ULM_USELOGNAME_PLAYER,
		ULM_USELOGNAME_CHARACTER,
		ULM_USELOGNAME_CUSTOM
};


enum ulm_loglevel_t {
		ULM_LOGLEVEL_NONE,
		ULM_LOGLEVEL_ERROR,
		ULM_LOGLEVEL_WARNING,
		ULM_LOGLEVEL_INFO,
		ULM_LOGLEVEL_DEBUG,
		ULM_LOGLEVEL_ALL
};


struct ulm_dumpinfo_t
{
	std::string OutputBuffer;
	eso::CFile	File;
	int			TabLevel;
	bool		OutputFile;
};


	/* Options and settings for the main application */
struct ulm_options_t
{
	const static int DEFAULT_UPDATETIME = 60;
	const static int MIN_UPDATETIME = 5;
	const static int MAX_UPDATETIME = 2000000;
	const static ulm_uselogname_t DEFAULT_SHOWNAME = ULM_USELOGNAME_PLAYER;
	const static ulm_loglevel_t DEFAULT_LOGLEVEL = ULM_LOGLEVEL_INFO;
	const static std::string DEFAULT_FORMURL;
	const static std::string DEFAULT_BACKUPDATAFILENAME;
	const static std::string DEFAULT_BACKUPBUILDDATAFOLDER;
	const static std::string DEFAULT_BACKUPCHARDATAFOLDER;
	const static std::string DEFAULT_BUILDDATA_FORMURL;
	const static std::string DEFAULT_CHARDATA_FORMURL;
	const static std::string DEFAULT_PRICESERVER;

	int					UpdateTime;		/* Time between updates in seconds */
	ulm_uselogname_t	UseLogName;
	ulm_loglevel_t		LogLevel;
	std::string			CustomLogName;
	std::string			FormURL;
	std::string			BuildDataFormURL;
	std::string			CharDataFormURL;
	std::string			SavedVarPath;
	std::string			BackupDataFilename;
	std::string			BackupBuildDataFolder;
	std::string			BackupCharDataFolder;
	std::string			UespWikiAccountName;
	bool				Enabled;
	bool				BuildDataEnabled;
	bool				CharDataEnabled;
	__int64				LastTimeStamp;
	__int64				LastBackupTimeStamp;
	bool				AutoDownloadPrices;
	std::string			PriceServer;
	bool				UploadScreenshots;

	ulm_options_t() :
		UpdateTime(DEFAULT_UPDATETIME),
		UseLogName(DEFAULT_SHOWNAME),
		LogLevel(DEFAULT_LOGLEVEL),
		CustomLogName(),
		FormURL(DEFAULT_FORMURL),
		BuildDataFormURL(DEFAULT_BUILDDATA_FORMURL),
		CharDataFormURL(DEFAULT_CHARDATA_FORMURL),
		Enabled(true),
		AutoDownloadPrices(true),
		BuildDataEnabled(true),
		CharDataEnabled(true),
		SavedVarPath(),
		LastTimeStamp(0),
		BackupDataFilename(DEFAULT_BACKUPDATAFILENAME),
		BackupBuildDataFolder(DEFAULT_BACKUPBUILDDATAFOLDER),
		BackupCharDataFolder(DEFAULT_BACKUPCHARDATAFOLDER),
		LastBackupTimeStamp(0),
		PriceServer(DEFAULT_PRICESERVER),
		UploadScreenshots(true)
	{ 
	}

};


struct ulm_sectiondata_t 
{
	std::string Data;
	__int64		TimeStamp;
};

typedef std::vector<unsigned char> CFileByteArray;
typedef std::vector<std::string> CUlmLogArray;
typedef std::vector<ulm_sectiondata_t> CUlmLogDataArray;
typedef std::unordered_map<std::string, std::string> CUlmLogMap;
typedef std::vector<std::string> CUlmBuildDataQueue;

struct ulm_screenshot_t 
{
	CFileByteArray	FileData;
	std::string		EncodedFileData;
	std::string		Filename;
	std::string		JpgFilename;
	std::string		ConvertFilename;
	std::string		Caption;
	bool			IsValid;
	bool			IsCharData;
	bool			IsBuildData;
	int				BuildIndex;
};

class CuespLogMonitorDlg;
typedef bool (CuespLogMonitorDlg::*ULM_LUA_TABLEITERATOR) (const std::string VarName, void* pUserData);


class CuespLogMonitorDlg : public CDialogEx
{
protected:

	const static int CHARDATA_UPLOAD_TESTONLY  = false;	/* Don't actually upload char/build data. Set to false for release builds */
	const static int BUILDDATA_UPLOAD_TESTONLY = false;

	const static int MINIMUM_VALID_BUILDDATA_SIZE = 24;
	const static int MINIMUM_VALID_CHARDATA_SIZE = 32;

	const static int MAXIMUM_FORMERROR_RETRYCOUNT = 10;

	const static bool DOWNLOADPRICES_AS_ZIP = true;

	NOTIFYICONDATA	m_TrayIconData;
	bool			m_IsInTray;

	HICON			m_hIcon;
	lua_State*		m_pLuaState;

	ulm_options_t	m_Options;
	long long		m_LastLogFileSize;
	__int64			m_LastParsedTimeStamp;
	bool			m_IsCheckingFile;

	std::string		m_CurrentPlayerName;
	std::string		m_CurrentCharacterName;

	UINT_PTR		m_TimerId;
	UINT_PTR		m_FileMonitorTimerId;

	CUlmLogDataArray	m_LogGlobalData;
	CUlmLogDataArray	m_LogAchievementData;
	CUlmLogDataArray	m_LogAllData;
	CUlmLogMap			m_LogInfoData;
	
	CUlmLogDataArray	m_SendQueue;
	CUlmLogDataArray	m_BackupQueue;   // Data that should be backed up but not sent
	CUlmBuildDataQueue	m_BuildDataQueue;
	std::string			m_CharDataQueue;

	HANDLE				m_hSendQueueThread;
	HANDLE				m_hSendQueueMutex;
	HANDLE				m_hPriceDownloadThread;
	LONG				m_StopSendQueueThread;
	int					m_FormErrorRetryCount;

	CUlmBuildDataQueue			m_BuildData;
	int							m_BuildDataValidScreenshotCount;
	int							m_BuildDataIndex;
	std::vector<ulm_screenshot_t> m_Screenshots;

	std::string					m_CharData;
	int							m_CharDataCount;

	ULONGLONG	m_LastLogCheckTime;
	ULONGLONG	m_LastPriceDownloadTime;

	bool    m_SkipNextFileMonitor;
	HANDLE	m_hFileMonitor;


public:
	enum { IDD = IDD_UESPLOGMONITOR_DIALOG };


protected:
	virtual void DoDataExchange(CDataExchange* pDX);
	void PostURL();

	void InitTrayIcon();
	bool IsInTray() { return m_IsInTray; }
	void ShowInTray (const bool Show, const bool UpdateWindow);
	void SetTrayToolTip (const CString Buffer);

	void PrintSettings ();
	void PrintLogLineV (const char* pString, va_list Args);
	void PrintLogLine (const char* pString, ...);
	void PrintLogLine (const ulm_loglevel_t LogLevel, const char* pString, ...);

	bool LoadRegistrySettings ();
	bool SaveRegistrySettings ();

	std::string FindSavedVarPath ();

	void DestroyTimer ();
	void CreateTimer ();
	void OnLogCheckTimer();
	void OnCheckFileMonitorTimer();
	void OnFileMonitorUpdate();

	void ClearLogData ();

	bool HasLogChanged();
	bool DoLogCheck(const bool OverrideEnable = false);
	bool DoPriceDownloadCheck();
	void UpdateLogFileSize();

	void ClearLog();

	std::string GetSavedVarFilename ();
		
	bool LoadSavedVars();
	bool LoadSavedVars(const std::string Filename);
	bool SaveSavedVars();

	bool LuaIterateSimpleTable (const int StackIndex, ULM_LUA_TABLEITERATOR TableIteratorMethod, void* pUserData);
	bool LuaIterateSimpleTableInOrder (const int StackIndex, ULM_LUA_TABLEITERATOR TableIteratorMethod, void* pUserData);

	bool ParseSavedVarFirstLevel	  (const std::string VarName, void* pUserData);
	bool ParseSavedVarUserName		  (const std::string VarName, void* pUserData);
	bool ParseSavedVarAccount		  (const std::string VarName, void* pUserData);
	bool ParseSavedVarSection		  (const std::string VarName, void* pUserData);
	bool ParseSavedVarBuildData       (const std::string VarName, void* pUserData);
	bool ParseSavedVarCharData        (const std::string VarName, void* pUserData);
	bool ParseSavedVarBankData        (const std::string VarName, void* pUserData);
	bool ParseSavedVarCraftBagData    (const std::string VarName, void* pUserData);
	bool ParseSavedVarGlobals		  (const std::string VarName, void* pUserData);
	bool ParseSavedVarAchievements	  (const std::string VarName, void* pUserData);
	bool ParseSavedVarAll			  (const std::string VarName, void* pUserData);
	bool ParseSavedVarInfo			  (const std::string VarName, void* pUserData);
	bool ParseSavedVarCharacterAccount(const std::string VarName, void* pUserData);
  
	bool ParseBuildDataScreenshots(const int NumBuilds);
	bool ParseCharDataScreenshots(const bool isCharData, const int BuildIndex);
	std::string GetScreenshotFormQuery(const bool isCharData, const int BuildIndex);
	bool LoadScreenshots();
	bool LoadScreenshot(ulm_screenshot_t& Screenshot);
	bool ConvertScreenshotToJpg(ulm_screenshot_t& Screenshot);

	std::string ParseSavedVarDataVersion();

	bool ParseSavedVarDataSection (const std::string SectionName, ULM_LUA_TABLEITERATOR Method);
	bool ParseSavedVarDataArray (CUlmLogDataArray& Output, const std::string Version);
	bool ParseSavedVarDataMap   (CUlmLogMap& Output, const std::string Version);

	__int64 ParseTimeStampFromData (const std::string Data);

	bool CheckAndSendLogData();
	bool CheckAndSendLogDataAll();
	bool CheckAndSendLogDataGlobal();
	bool CheckAndSendLogDataAchievement();
	bool SendAllLogData();

	void InitializeFileMonitor(void);
	void StopFileMonitor(void);

	bool CheckAndSendBuildData();
	bool CheckAndSendCharData();
	bool QueueBuildData();
	bool QueueCharData();

	bool SendLogData (CUlmLogDataArray& DataArray);
	bool SendLogData (const std::string Section, const ulm_sectiondata_t Data);
	bool BackupLogData (const std::string Section, const ulm_sectiondata_t Data);
	bool SendQueuedData ();
	std::string EncodeLogDataForQuery (const std::string Data);
	std::string EncodeLogDataForQuery (const CFileByteArray Data);
	bool SendFormData (const std::string FormURL, std::string FormQuery, bool Compress, size_t& SentSize);
	bool HasQueuedData (void) { return m_SendQueue.size() > 0; }

	std::string GetCurrentUserName ();

	bool DeleteOldLogData();
	bool DeleteOldLogDataRoot (const std::string VarName, void* pUserData);
	bool DeleteOldLogDataUser (const std::string VarName, void* pUserData);
	bool DeleteOldLogDataAccount (const std::string VarName, void* pUserData);
	bool DeleteOldLogDataSection (const std::string Section, const int StackIndex, const std::string Parent);

	std::string GetExtraLogData ();

	bool SaveLuaVariable      (const std::string Filename, const std::string Variable);
	std::string GetLuaVariableString (const std::string Variable, const bool LoadGlobal = true);

	bool DumpLuaObjectFile  (const std::string VarName, void* pUserData);
	bool DumpLuaObjectString(const std::string VarName, void* pUserData);

	void UpdateDialogTitle();

	bool BackupData (void);
	bool BackupCharData(void);
	bool BackupBuildData(void);

	bool SendEntireLog(const std::string Filename);

	void InitSendQueueThread();
	void DestroySendQueueThread();
	bool SendQueuedDataThread();
	bool SendQueuedBuildDataThread();
	bool SendQueuedCharDataThread();

	void CheckBackupDataSize();
	void CheckCharBackupDataSize();
	void CheckBuildBackupDataSize();

	__int64 GetBackupDataSize();
	__int64 GetCharBackupDataSize();
	__int64 GetBuildBackupDataSize();


public:
	CuespLogMonitorDlg(CWnd* pParent = NULL);
	virtual ~CuespLogMonitorDlg();

	DWORD SendQueueThreadProc();
	bool DoDownloadPriceListThread();
	bool DownloadPriceList();


protected:
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();

	BOOL PreTranslateMessage(MSG* pMsg);

	DECLARE_MESSAGE_MAP()

public:
	afx_msg void OnClose();
	virtual BOOL DestroyWindow();
	afx_msg void OnFileExit();
	CRichEditCtrl m_LogText;
	afx_msg void OnTimer(UINT_PTR nIDEvent);
	afx_msg void OnViewOptions();
	afx_msg void OnSize(UINT nType, int cx, int cy);
	afx_msg void OnFileSendotherlog();
	afx_msg void OnFileChecklognow();
	afx_msg void OnBnClickedChecknowButton();
	virtual void OnOK();
	afx_msg void OnFileDownloadpricelist();
	afx_msg void OnViewClearlog();
	afx_msg void OnFileDeletelogbackup();
	afx_msg void OnUpdateFileDeletelogbackup(CCmdUI *pCmdUI);
	afx_msg void OnFileDeletebuildbackup();
	afx_msg void OnUpdateFileDeletebuildbackup(CCmdUI *pCmdUI);
	afx_msg void OnFileDeletecharbackup();
	afx_msg void OnUpdateFileDeletecharbackup(CCmdUI *pCmdUI);
	afx_msg void OnViewCheckfilesizes();
	afx_msg void OnInitMenuPopup(CMenu *pPopupMenu, UINT nIndex, BOOL bSysMenu);
};
