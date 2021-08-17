#ifndef __ABOUTDLG_H
#define __ABOUTDLG_H


#include "resource.h"
#include "afxwin.h"


class CAboutDlg : public CDialogEx
{
protected:

	void UpdateVersionInfo();

public:
	CAboutDlg();

	enum { IDD = IDD_ABOUTBOX };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);

protected:
	DECLARE_MESSAGE_MAP()
public:
	CStatic m_VersionLabel;
	virtual BOOL OnInitDialog();
	afx_msg void OnStnClickedVersionLabel();
};

#endif