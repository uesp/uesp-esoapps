
// EsoExtractDataGuiDlg.cpp : implementation file
//

#include "stdafx.h"
#include "EsoMnfFile.h"
#include "framework.h"
#include "EsoExtractDataGui.h"
#include "EsoExtractDataGuiDlg.h"
#include "EsoMnfOptionsDlg.h"
#include "EsoMnfExtractDlg.h"
#include "afxdialogex.h"


#ifdef _DEBUG
	#define new DEBUG_NEW
#endif


class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);

protected:
	DECLARE_MESSAGE_MAP()
public:
	
};

CAboutDlg::CAboutDlg() : CDialogEx(IDD_ABOUTBOX)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()





CEsoExtractDataGuiDlg::CEsoExtractDataGuiDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_ESOEXTRACTDATAGUI_DIALOG, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CEsoExtractDataGuiDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_FILELIST, m_FileList);
	DDX_Control(pDX, IDC_FILTEREDIT, m_FilterEdit);
	DDX_Control(pDX, IDC_EXTRACT_BUTTON, m_ExtractButton);
	DDX_Control(pDX, IDC_ARCHIVEEDIT, m_ArchiveEdit);
}

BEGIN_MESSAGE_MAP(CEsoExtractDataGuiDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_COMMAND(ID_FILE_EXIT, &CEsoExtractDataGuiDlg::OnFileExit)
	ON_WM_CLOSE()
	ON_COMMAND(ID_FILE_NEW, &CEsoExtractDataGuiDlg::OnFileNew)
	ON_COMMAND(ID_FILE_LOADMNF, &CEsoExtractDataGuiDlg::OnFileLoadmnf)
	ON_WM_SIZE()
	ON_NOTIFY(LVN_GETDISPINFO, IDC_FILELIST, &CEsoExtractDataGuiDlg::OnLvnGetdispinfoFileList)
	ON_NOTIFY(LVN_COLUMNCLICK, IDC_FILELIST, &CEsoExtractDataGuiDlg::OnColumnclickFilelist)
	ON_EN_CHANGE(IDC_FILTEREDIT, &CEsoExtractDataGuiDlg::OnChangeFilteredit)
	ON_COMMAND(ID_VIEW_OPTIONS, &CEsoExtractDataGuiDlg::OnViewOptions)
	ON_COMMAND(ID_HELP_ABOUT, &CEsoExtractDataGuiDlg::OnHelpAbout)
	ON_BN_CLICKED(IDC_EXTRACT_BUTTON, &CEsoExtractDataGuiDlg::OnBnClickedExtractButton)
	ON_EN_CHANGE(IDC_ARCHIVEEDIT, &CEsoExtractDataGuiDlg::OnEnChangeArchiveedit)
END_MESSAGE_MAP()


BOOL CEsoExtractDataGuiDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != nullptr)
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

	LoadRegistrySettings();

	m_FileList.SetExtendedStyle(LVS_EX_FULLROWSELECT);
	m_FileList.SetExtendedStyle(LVS_EX_GRIDLINES);

		// Get around the first column not center aligning
	m_FileList.InsertColumn(0, "Index", LVCFMT_CENTER, 75);
	m_FileList.InsertColumn(1, "Index", LVCFMT_CENTER, 75);
	m_FileList.DeleteColumn(0);

	m_FileList.InsertColumn(1, "Filename", LVCFMT_LEFT, 360);
	m_FileList.InsertColumn(2, "Archive", LVCFMT_CENTER, 50);
	m_FileList.InsertColumn(3, "Hash", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(4, "Size", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(5, "ID", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(6, "FileIndex", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(7, "Offset", LVCFMT_LEFT, 90);
	
	return TRUE;
}

void CEsoExtractDataGuiDlg::OnSysCommand(UINT nID, LPARAM lParam)
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


void CEsoExtractDataGuiDlg::OnPaint()
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

HCURSOR CEsoExtractDataGuiDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void CEsoExtractDataGuiDlg::OnFileExit()
{
	CDialog::EndDialog(0);
}


void CEsoExtractDataGuiDlg::OnOK()
{
	// Do Nothing
}


void CEsoExtractDataGuiDlg::OnCancel()
{
	// Do Nothing
}


void CEsoExtractDataGuiDlg::OnClose()
{
	CDialogEx::OnCancel();
}


void CEsoExtractDataGuiDlg::OnFileNew()
{
	m_MnfFile.Destroy();
	CreateSortedFileIndex();
	m_FileList.Invalidate();
}


void CEsoExtractDataGuiDlg::OnFileLoadmnf()
{
	const TCHAR szFilter[] = _T("MNF Files (*.mnf)|*.mnf|All Files (*.*)|*.*||");
	CFileDialog dlg(TRUE, _T("mnf"), NULL, OFN_HIDEREADONLY | OFN_FILEMUSTEXIST, szFilter, this);
	auto installPath = GetEsoLiveInstallPath();

	dlg.m_ofn.lpstrInitialDir = installPath.c_str();

	if (dlg.DoModal() != IDOK) return;

	CString sFilePath = dlg.GetPathName();
	LoadMnfFile(sFilePath);
}


void CEsoExtractDataGuiDlg::OnSize(UINT nType, int cx, int cy)
{
	CDialogEx::OnSize(nType, cx, cy);

	if (nType != SIZE_MINIMIZED)
	{
		const int BORDER_WIDTH = 5;
		const int OFFSET_TOP = 35;

		cx -= BORDER_WIDTH*2;
		cy -= BORDER_WIDTH*2 + OFFSET_TOP;

		if (cx < 100) cx = 100;
		if (cy < 100) cy = 100;

		m_FileList.MoveWindow(BORDER_WIDTH, BORDER_WIDTH + OFFSET_TOP, cx, cy, TRUE);
		m_ExtractButton.SetWindowPos(NULL, cx - BORDER_WIDTH - 75, BORDER_WIDTH + 5, -1, -1, SWP_NOSIZE | SWP_NOZORDER);
	}
	
}


bool CEsoExtractDataGuiDlg::LoadMnfFile(CString Filename)
{
	m_MnfFile.Destroy();
	m_SortedFileIndexes.clear();
	m_FileList.SetItemCount(0);
	m_Options.MnfFilename = Filename;
	
	if (!m_MnfFile.Load(Filename))
	{
		AfxMessageBox("Error: Failed to load the MNF file!");
		return false;
	}

	if (!m_MnfFile.LoadZosft())
	{
		AfxMessageBox("Error: Failed to find or load the ZOSFT entry in the MNF file!");
	}

	CreateSortedFileIndex();
	
	return true;
}


afx_msg void CEsoExtractDataGuiDlg::OnLvnGetdispinfoFileList(NMHDR* pNotifyStruct, LRESULT* result)
{
	NMLVDISPINFO *pDispInfo = reinterpret_cast<NMLVDISPINFO *>(pNotifyStruct);
	LVITEM *pItem = &(pDispInfo)->item;
	CString Buffer;
	int iItem = m_SortedFileIndexes[pItem->iItem];
	auto& record = m_MnfFile.GetFileTable()[iItem];

	/*
	m_FileList.InsertColumn(0, "Index", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(1, "Filename", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(2, "Archive", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(3, "Hash", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(4, "Size", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(5, "ID", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(6, "FileIndex", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(7, "Offset", LVCFMT_LEFT, 90);
	*/

	if (pItem->mask & LVIF_TEXT)
	{
		switch (pItem->iSubItem)
		{
		case 0:
			Buffer.Format("%d", record.Index);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 1:
			if (record.pZosftEntry == nullptr)
				_tcscpy_s(pItem->pszText, pItem->cchTextMax, "");
			else
				_tcscpy_s(pItem->pszText, pItem->cchTextMax, record.pZosftEntry->Filename.c_str());

			break;
		case 2:
			Buffer.Format("%d", record.ArchiveIndex);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 3:
			Buffer.Format("0x%08X", record.Hash);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 4:
			Buffer.Format("%d", record.Size);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 5:
			Buffer.Format("0x%08X", record.ID1);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 6:
			Buffer.Format("%d", record.FileIndex);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		case 7:
			Buffer.Format("0x%08X", record.Offset);
			_tcscpy_s(pItem->pszText, pItem->cchTextMax, Buffer);
			break;
		}
	}

}


std::unordered_map<dword, dword> CEsoExtractDataGuiDlg::ParseArchiveFilter()
{
	std::unordered_map<dword, dword> archiveMap;

	if (m_FilterArchives.IsEmpty()) return archiveMap;

	auto strings = SplitString(std::string(m_FilterArchives), ',');

	for (auto & element : strings) 
	{
		auto range = SplitString(element, '-');

		if (range.size() >= 2)
		{
			auto start = atoi(range[0].c_str());
			auto end = atoi(range[0].c_str());

			if (start >= 0 && end >= 0 && start <= end && start < 1000 && end < 1000)
			{
				for (dword i = (dword)start; i <= (dword)end; ++i)
				{
					archiveMap[i] = 1;
				}
			}
		}
		else
		{
			auto start = atoi(range[0].c_str());

			if (start >= 0 && start < 1000)
			{
				archiveMap[start] = 1;
			}
		}
	}

	return archiveMap;
}


void CEsoExtractDataGuiDlg::CreateSortedFileIndex()
{
	auto& table = m_MnfFile.GetFileTable();
	auto archiveMap = ParseArchiveFilter();

	m_SortedFileIndexes.clear();
	m_SortedFileIndexes.reserve(table.size());

	for (dword i = 0; i < table.size(); ++i)
	{
		if (!m_FilterText.IsEmpty())
		{
			auto& record = table[i];

			if (record.pZosftEntry == nullptr) continue;
			if (record.pZosftEntry->Filename.find(m_FilterText) == std::string::npos) continue;
		}

		if (!archiveMap.empty())
		{
			auto& record = table[i];
			if (archiveMap.find(record.ArchiveIndex) == archiveMap.end()) continue;
		}

		m_SortedFileIndexes.push_back(i);
	}

	m_FileList.SetItemCount((int)m_SortedFileIndexes.size());
	SortFileIndexes();
}


void CEsoExtractDataGuiDlg::OnColumnclickFilelist(NMHDR *pNMHDR, LRESULT *pResult)
{
	LPNMLISTVIEW pNMLV = reinterpret_cast<LPNMLISTVIEW>(pNMHDR);

	int column = pNMLV->iSubItem;

	if (column == m_SortedColumn)
	{
		m_SortedColumnInverse = !m_SortedColumnInverse;
	}
	else
	{
		m_SortedColumn = column;
		m_SortedColumnInverse = false;
	}

	SortFileIndexes();
	m_FileList.Invalidate();
	
	*pResult = 0;
}


void CEsoExtractDataGuiDlg::SortFileIndexes()
{
	/*
	auto f0 = [this](const dword& lhs, const dword& rhs) { return m_MnfFile.GetFileTable()[lhs].Index < m_MnfFile.GetFileTable()[rhs].Index; };
	auto f2 = [this](const dword& lhs, const dword& rhs) { return m_MnfFile.GetFileTable()[lhs].ArchiveIndex < m_MnfFile.GetFileTable()[rhs].ArchiveIndex; };
	auto begin = m_SortedFileIndexes.begin();
	auto end = m_SortedFileIndexes.end();

	auto f = f0;
	f0 = f2;

	if (m_SortedColumnInverse)
	{
		begin = m_SortedFileIndexes.rbegin();
		end = m_SortedFileIndexes.rend();
	}

	switch (m_SortedColumn)
	{
		case 0:
			return std::sort(begin, end, f0);
	} //*/

	if (m_SortedColumn < 0) return;

	std::sort(m_SortedFileIndexes.begin(), m_SortedFileIndexes.end(), [this](dword lhs, dword rhs)
	{
		bool result = false;

		if (m_SortedColumnInverse) std::swap(lhs, rhs);

		auto& a = m_MnfFile.GetFileTable()[lhs];
		auto& b = m_MnfFile.GetFileTable()[rhs];

		switch (m_SortedColumn)
		{
		case 0:
			result = a.Index < b.Index;
			break;
		case 1:
			result = (a.pZosftEntry ? a.pZosftEntry->Filename : "") < (b.pZosftEntry ? b.pZosftEntry->Filename : "");
			break;
		case 2:
			result = a.ArchiveIndex < b.ArchiveIndex;
			break;
		case 3:
			result = a.Hash < b.Hash;
			break;
		case 4:
			result = a.Size < b.Size;
			break;
		case 5:
			result = a.ID1 < b.ID1;
			break;
		case 6:
			result = a.FileIndex < b.FileIndex;
			break;
		case 7:
			result = a.Offset < b.Offset;
			break;
		default:
			result = lhs < rhs;
			break;
		}
		
		return result;
	});
}


void CEsoExtractDataGuiDlg::OnChangeFilteredit()
{
	CString NewText;

	m_FilterEdit.GetWindowText(NewText);

	NewText.Trim();

	if (NewText != m_FilterText)
	{
		m_FilterText = NewText;
		CreateSortedFileIndex();
		m_FileList.Invalidate();
	}
}


void CEsoExtractDataGuiDlg::OnBnClickedExtractButton()
{
	if (m_SortedFileIndexes.size() == 0)
	{
		AfxMessageBox("No files to extract!");
		return;
	}
	
	CFolderPickerDialog folderPickerDialog("", OFN_FILEMUSTEXIST | OFN_ENABLESIZING, this, sizeof(OPENFILENAME));
	//folderPickerDialog.m_ofn.lpstrTitle = "Select Output Folder";

	if (folderPickerDialog.DoModal() != IDOK) return;

	POSITION pos = folderPickerDialog.GetStartPosition();
	CString folderPath;

	while (pos)
	{
		folderPath = folderPickerDialog.GetNextPathName(pos);
	}
	
	m_Options.OutputPath = folderPath;
	m_Options.OutputPath = eso::TerminatePath(m_Options.OutputPath);

	ExtractFiles();
}


bool CEsoExtractDataGuiDlg::ExtractFiles()
{
	CEsoMnfExtractDlg extractDlg(m_MnfFile, m_Options, m_SortedFileIndexes);

	extractDlg.DoModal();
	return true;
}


void CEsoExtractDataGuiDlg::OnViewOptions()
{
	CEsoMnfOptionsDlg optionsDlg;

	optionsDlg.m_MnfOptions = m_Options;

	if (optionsDlg.DoModal() == IDOK)
	{
		m_Options = optionsDlg.m_MnfOptions;
		eso::g_OutputDebugLog = m_Options.DebugOutput;

		SaveRegistrySettings();
	}

}


void CEsoExtractDataGuiDlg::OnHelpAbout()
{
	CAboutDlg Dlg;
	Dlg.DoModal();
}


void CEsoExtractDataGuiDlg::OnEnChangeArchiveedit()
{
	CString ArchiveText;

	m_ArchiveEdit.GetWindowText(ArchiveText);
	ArchiveText.Trim();

	if (m_FilterArchives != ArchiveText)
	{
		m_FilterArchives = ArchiveText;
		CreateSortedFileIndex();
		m_FileList.Invalidate();
	}
	
}


std::string CEsoExtractDataGuiDlg::GetEsoLiveInstallPath()
{
	return GetEsoInstallPath() + "The Elder Scrolls Online\\";
}


std::string CEsoExtractDataGuiDlg::GetEsoPtsInstallPath()
{
	return GetEsoInstallPath() + "The Elder Scrolls Online PTS\\";
}



std::string CEsoExtractDataGuiDlg::GetEsoInstallPath()
{
		// Default if we can't find it in the registry
	std::string installPath("C:\\Program Files (x86)\\Zenimax Online\\");

	HKEY key;
	DWORD type, size;
	char data[512];
	size = sizeof(data);

	int result = RegOpenKeyEx(HKEY_LOCAL_MACHINE, "SOFTWARE\\WOW6432Node\\Zenimax_Online\\Launcher", 0, KEY_READ, &key);

	if (result != ERROR_SUCCESS) return installPath;

	result = RegQueryValueEx(key, "InstallPath", 0, &type, (BYTE*)data, &size);

	if (result != ERROR_SUCCESS)
	{
		RegCloseKey(key);
		return installPath;
	}

	installPath = eso::TerminatePath(data);

	RegCloseKey(key);
	return installPath;
}


void CEsoExtractDataGuiDlg::LoadRegistrySettings()
{
	CWinApp* pApp = AfxGetApp();

	m_Options.DebugOutput = (pApp->GetProfileInt("Settings", "DebugOutput", (int)m_Options.DebugOutput) != 0);
	m_Options.NoParseGR2 = (pApp->GetProfileInt("Settings", "NoParseGR2", (int)m_Options.NoParseGR2) != 0);
	m_Options.NoRiffConvert = (pApp->GetProfileInt("Settings", "NoRiffConvert", (int)m_Options.NoRiffConvert) != 0);
	m_Options.MnfOutputFileTable = pApp->GetProfileString("Settings", "MnfOutputFileTable", m_Options.MnfOutputFileTable.c_str());
	m_Options.ZosOutputFileTable = pApp->GetProfileString("Settings", "ZosOutputFileTable", m_Options.ZosOutputFileTable.c_str());
}


void CEsoExtractDataGuiDlg::SaveRegistrySettings()
{
	CWinApp* pApp = AfxGetApp();

	pApp->WriteProfileInt("Settings", "DebugOutput", (int)m_Options.DebugOutput);
	pApp->WriteProfileInt("Settings", "NoParseGR2", (int)m_Options.NoParseGR2);
	pApp->WriteProfileInt("Settings", "NoRiffConvert", (int)m_Options.NoRiffConvert);
	pApp->WriteProfileString("Settings", "MnfOutputFileTable", m_Options.MnfOutputFileTable.c_str());
	pApp->WriteProfileString("Settings", "ZosOutputFileTable", m_Options.ZosOutputFileTable.c_str());
}