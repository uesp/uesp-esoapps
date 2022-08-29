#pragma once

#include "resource.h"

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ABOUTBOX };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);
	bool LoadReadme();

protected:
	DECLARE_MESSAGE_MAP()
public:

	CRichEditCtrl m_ReadmeText;
	virtual BOOL OnInitDialog();
	CFont m_LogFont;
};

