
#include "stdafx.h"
#include "AboutDlg.h"


BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()


CAboutDlg::CAboutDlg() : CDialogEx(CAboutDlg::IDD)
{
}


void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, ID_VERSION_LABEL, m_VersionLabel);
}


void CAboutDlg::UpdateVersionInfo()
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

	m_VersionLabel.SetWindowText(Buffer);
}


BOOL CAboutDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	UpdateVersionInfo();

	return TRUE;
}
