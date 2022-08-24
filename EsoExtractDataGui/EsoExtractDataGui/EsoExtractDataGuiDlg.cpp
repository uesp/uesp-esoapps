
// EsoExtractDataGuiDlg.cpp : implementation file
//

#include "stdafx.h"
#include "EsoMnfFile.h"
#include "framework.h"
#include "EsoExtractDataGui.h"
#include "EsoExtractDataGuiDlg.h"
#include "afxdialogex.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CAboutDlg dialog used for App About

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

// Dialog Data
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

// Implementation
protected:
	DECLARE_MESSAGE_MAP()
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


// CEsoExtractDataGuiDlg dialog



CEsoExtractDataGuiDlg::CEsoExtractDataGuiDlg(CWnd* pParent /*=nullptr*/)
	: CDialogEx(IDD_ESOEXTRACTDATAGUI_DIALOG, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CEsoExtractDataGuiDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_FILELIST, m_FileList);
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

	m_FileList.SetExtendedStyle(LVS_EX_FULLROWSELECT);
	m_FileList.SetExtendedStyle(LVS_EX_GRIDLINES);

	m_FileList.InsertColumn(0, "Index", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(1, "Filename", LVCFMT_LEFT, 90);
	m_FileList.InsertColumn(2, "Archive", LVCFMT_LEFT, 90);
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
}


void CEsoExtractDataGuiDlg::OnFileLoadmnf()
{
	const TCHAR szFilter[] = _T("MNF Files (*.mnf)|*.mnf|All Files (*.*)|*.*||");
	CFileDialog dlg(TRUE, _T("mnf"), NULL, OFN_HIDEREADONLY | OFN_FILEMUSTEXIST, szFilter, this);

		// TODO: Grab from registry
	dlg.m_ofn.lpstrInitialDir = "c:\\Program Files (x86)\\Zenimax Online\\The Elder Scrolls Online\\";

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

		cx -= BORDER_WIDTH*2;
		cy -= BORDER_WIDTH*2;

		if (cx < 100) cx = 100;
		if (cy < 100) cy = 100;

		m_FileList.MoveWindow(BORDER_WIDTH, BORDER_WIDTH, cx, cy, TRUE);
	}
	
}


bool CEsoExtractDataGuiDlg::LoadMnfFile(CString Filename)
{
	m_MnfFile.Destroy();
	m_FileList.SetItemCount(0);

	if (!m_MnfFile.Load(Filename))
	{
		AfxMessageBox("Error: Failed to load the MNF file!");
		return false;
	}

	if (!m_MnfFile.LoadZosft())
	{
		AfxMessageBox("Error: Failed to find or load the ZOSFT entry in the MNF file!");
	}

	m_FileList.SetItemCount((int)m_MnfFile.GetFileTable().size());
	
	return true;
}


afx_msg void CEsoExtractDataGuiDlg::OnLvnGetdispinfoFileList(NMHDR* pNotifyStruct, LRESULT* result)
{
	NMLVDISPINFO *pDispInfo = reinterpret_cast<NMLVDISPINFO *>(pNotifyStruct);
	LVITEM *pItem = &(pDispInfo)->item;
	CString Buffer;
	int iItem = pItem->iItem;
	auto record = m_MnfFile.GetFileTable()[iItem];

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