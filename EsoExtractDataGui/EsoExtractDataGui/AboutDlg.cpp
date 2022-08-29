
#include "stdafx.h"
#include "EsoMnfFile.h"
#include "afxdialogex.h"
#include "framework.h"
#include "AboutDlg.h"


using namespace eso;


#ifdef _DEBUG
	#define new DEBUG_NEW
#endif



CAboutDlg::CAboutDlg() : CDialogEx(IDD_ABOUTBOX)
{
}


void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_READMETEXT, m_ReadmeText);
}


BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()



bool CAboutDlg::LoadReadme()
{
	eso::CFile File;
	fpos_t FileSize;

	byte* pBytes = File.ReadAll("README.txt", FileSize);

	m_ReadmeText.SetWindowTextA((const char*) pBytes);
	m_ReadmeText.SetSel(-1, 0);

	delete[] pBytes;

	return true;
}


BOOL CAboutDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	if (!m_LogFont.CreatePointFont(100, _T("Consolas")))
	{
		m_LogFont.CreatePointFont(80, _T("Courier New"));
	}

	m_ReadmeText.SetFont(&m_LogFont);
	m_ReadmeText.SetOptions(ECOOP_OR, ECO_SAVESEL);

	LoadReadme();

	return TRUE;
}
