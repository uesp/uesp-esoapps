#include "stdafx.h"
#include "uespLogMonitor.h"
#include "OptionsDlg.h"
#include "afxdialogex.h"
#include "uespLogMonitorDlg.h"


IMPLEMENT_DYNAMIC(COptionsDlg, CDialogEx)


BEGIN_MESSAGE_MAP(COptionsDlg, CDialogEx)
	ON_BN_CLICKED(IDC_BROWSE_BUTTON, &COptionsDlg::OnBnClickedBrowseButton)
	ON_CBN_SELCHANGE(IDC_LOGNAME_LIST, &COptionsDlg::OnCbnSelchangeLognameList)
	ON_BN_CLICKED(IDC_BROWSEBACKUPDATA_BUTTON, &COptionsDlg::OnBnClickedBrowsebackupdataButton)
END_MESSAGE_MAP()


COptionsDlg::COptionsDlg(CWnd* pParent) : 
	CDialogEx(COptionsDlg::IDD, pParent),
	m_pOptions(nullptr)
{

}


COptionsDlg::~COptionsDlg()
{
}


void COptionsDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);

	DDX_Control(pDX, IDC_UPDATETIME_TEXT, m_UpdateTimeText);
	DDX_Control(pDX, IDC_FORMURL_TEXT, m_FormURLText);
	DDX_Control(pDX, IDC_SAVEDVARPATH_TEXT, m_SavedVarPathText);
	DDX_Control(pDX, IDC_CUSTOMNAME_TEXT, m_CustomNameText);
	DDX_Control(pDX, IDC_LOGNAME_LIST, m_LogNameList);
	DDX_Control(pDX, IDC_LOGLEVEL_LIST, m_LogLevelList);
	DDX_Control(pDX, IDC_LASTTIMESTAMP_TEXT, m_LastTimestampText);
	DDX_Control(pDX, IDC_ENABLED_CHECK, m_EnabledCheck);
	DDX_Control(pDX, IDC_BACKUPFILENAME_TEXT, m_BackupDataFilename);
	DDX_Control(pDX, IDC_BACKUPTIMESTAMP_TEXT, m_BackupTimestampText);
	DDX_Control(pDX, IDC_CHARDATAENABLED_CHECK, m_CharDataEnabledCheck);
	DDX_Control(pDX, IDC_CHARDATAFORMURL_TEXT, m_CharDataFormURLText);
}


int COptionsDlg::DoModal (ulm_options_t& Options)
{
	m_pOptions = &Options;
	return CDialogEx::DoModal();
}


BOOL COptionsDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	FillLogNameList();
	FillLogLevelList();
	SetControlData();
	
	return TRUE;
}


void AddComboString (CComboBox& Combo, const char* pString, const int Data)
{	
	int ListIndex = Combo.AddString(pString);
	if (ListIndex >= 0) Combo.SetItemData(ListIndex, Data);
}


int SelectComboItem (CComboBox& Combo, const int Data)
{
	for (int i = 0; i < Combo.GetCount(); ++i)
	{
		if (Combo.GetItemData(i) == Data)
		{
			Combo.SetCurSel(i);
			return i;
		}
	}

	return -1;
}

int GetComboSelData (CComboBox& Combo, const int Default)
{
	int ListIndex = Combo.GetCurSel();
	if (ListIndex < 0) return Default;
	return Combo.GetItemData(ListIndex);
}



void COptionsDlg::FillLogNameList()
{
	AddComboString(m_LogNameList, "Anonymous", ULM_USELOGNAME_ANONYMOUS);
	AddComboString(m_LogNameList, "Character", ULM_USELOGNAME_CHARACTER);
	AddComboString(m_LogNameList, "Player/Account", ULM_USELOGNAME_PLAYER);
	AddComboString(m_LogNameList, "Custom", ULM_USELOGNAME_CUSTOM);
}


void COptionsDlg::FillLogLevelList()
{
	AddComboString(m_LogLevelList, "None", ULM_LOGLEVEL_NONE);
	AddComboString(m_LogLevelList, "Error", ULM_LOGLEVEL_ERROR);
	AddComboString(m_LogLevelList, "Warning", ULM_LOGLEVEL_WARNING);
	AddComboString(m_LogLevelList, "Info", ULM_LOGLEVEL_INFO);
	AddComboString(m_LogLevelList, "Debug", ULM_LOGLEVEL_DEBUG);
	AddComboString(m_LogLevelList, "All", ULM_LOGLEVEL_ALL);
}


void COptionsDlg::OnOK()
{
	GetControlData();
	CDialogEx::OnOK();
}


void COptionsDlg::GetControlData()
{
	CString Buffer;

	if (m_pOptions == nullptr) return;

	m_UpdateTimeText.GetWindowText(Buffer);
	m_pOptions->UpdateTime = atoi(Buffer);

	m_LastTimestampText.GetWindowText(Buffer);
	m_pOptions->LastTimeStamp = _atoi64(Buffer);

	m_BackupTimestampText.GetWindowText(Buffer);
	m_pOptions->LastBackupTimeStamp = _atoi64(Buffer);

	m_FormURLText.GetWindowText(Buffer);
	m_pOptions->FormURL = Buffer;

	m_SavedVarPathText.GetWindowText(Buffer);
	m_pOptions->SavedVarPath = Buffer;

	m_BackupDataFilename.GetWindowText(Buffer);
	m_pOptions->BackupDataFilename = Buffer;

	m_CustomNameText.GetWindowText(Buffer);
	m_pOptions->CustomLogName = Buffer;

    m_pOptions->LogLevel = static_cast<ulm_loglevel_t>(GetComboSelData(m_LogLevelList, m_pOptions->LogLevel));
	m_pOptions->UseLogName = static_cast<ulm_uselogname_t>(GetComboSelData(m_LogNameList, m_pOptions->UseLogName));

	m_pOptions->Enabled = m_EnabledCheck.GetCheck() != 0;

	m_pOptions->CharDataEnabled = m_CharDataEnabledCheck.GetCheck() != 0;

	m_CharDataFormURLText.GetWindowText(Buffer);
	m_pOptions->CharDataFormURL = Buffer;
}


void COptionsDlg::SetControlData()
{
	CString Buffer;

	if (m_pOptions == nullptr) return;

	Buffer.Format("%d", m_pOptions->UpdateTime);
	m_UpdateTimeText.SetWindowText(Buffer);

	Buffer.Format("%lld", m_pOptions->LastTimeStamp);
	m_LastTimestampText.SetWindowText(Buffer);

	Buffer.Format("%lld", m_pOptions->LastBackupTimeStamp);
	m_BackupTimestampText.SetWindowText(Buffer);

	m_FormURLText.SetWindowText(m_pOptions->FormURL.c_str());
	m_SavedVarPathText.SetWindowText(m_pOptions->SavedVarPath.c_str());
	m_CustomNameText.SetWindowText(m_pOptions->CustomLogName.c_str());
	m_BackupDataFilename.SetWindowText(m_pOptions->BackupDataFilename.c_str());

	m_EnabledCheck.SetCheck(m_pOptions->Enabled);

	SelectComboItem(m_LogLevelList, m_pOptions->LogLevel);
	SelectComboItem(m_LogNameList, m_pOptions->UseLogName);

	m_CharDataEnabledCheck.SetCheck(m_pOptions->CharDataEnabled);
	m_CharDataFormURLText.SetWindowText(m_pOptions->CharDataFormURL.c_str());

	UpdateCustomNameState();
}


void COptionsDlg::UpdateCustomNameState()
{
	int LogName = GetComboSelData(m_LogNameList, ULM_USELOGNAME_ANONYMOUS);
	m_CustomNameText.EnableWindow(LogName == ULM_USELOGNAME_CUSTOM);
}


static int CALLBACK BrowseCallbackProc(HWND hwnd,UINT uMsg, LPARAM lParam, LPARAM lpData)
{

    if(uMsg == BFFM_INITIALIZED)
    {
        std::string tmp = (const char *) lpData;
        SendMessage(hwnd, BFFM_SETSELECTION, TRUE, lpData);
    }

    return 0;
}


void COptionsDlg::OnBnClickedBrowseButton()
{
	BROWSEINFO BrowseInfo = { 0 };
	TCHAR Path[MAX_PATH + 64];
	CString Buffer;

	m_SavedVarPathText.GetWindowText(Buffer);

	BrowseInfo.lpszTitle  = "Select folder...";
    BrowseInfo.ulFlags    = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
    BrowseInfo.lpfn       = BrowseCallbackProc;
    BrowseInfo.lParam     = (LPARAM) (const char *) Buffer;

	LPITEMIDLIST pList = SHBrowseForFolder(&BrowseInfo);
	if (pList == nullptr) return;

	SHGetPathFromIDList (pList, Path);

	IMalloc * imalloc = nullptr;

    if ( SUCCEEDED( SHGetMalloc ( &imalloc )) )
    {
		imalloc->Free(pList);
		imalloc->Release();
	}

	m_SavedVarPathText.SetWindowText(Path);
}


void COptionsDlg::OnBnClickedBrowsebackupdataButton()
{
	CString Buffer;
	m_BackupDataFilename.GetWindowText(Buffer);

	//TCHAR AbsFilename[MAX_PATH + 64];
	//::GetFullPathNameA(Buffer, Buffer.GetLength(), AbsFilename, NULL);

	CFileDialog FileDlg(FALSE, nullptr, Buffer, OFN_HIDEREADONLY, "Text Files (*.txt)|*.txt|All Files (*.*)|*.*||", this);

	if (FileDlg.DoModal() != IDOK) return;

	Buffer = FileDlg.GetPathName();
	m_BackupDataFilename.SetWindowText(Buffer);
}


void COptionsDlg::OnCbnSelchangeLognameList()
{
	UpdateCustomNameState();
}


