#pragma once


using namespace eso;


class CEsoExtractDataGuiDlg : public CDialogEx
{
protected:
	CMnfFile	m_MnfFile;

public:
	CEsoExtractDataGuiDlg(CWnd* pParent = nullptr);


	bool LoadMnfFile(CString Filename);

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_ESOEXTRACTDATAGUI_DIALOG };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);


protected:
	HICON m_hIcon;

	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	virtual void OnOK();
	virtual void OnCancel();
	afx_msg void OnClose();
	afx_msg void OnLvnGetdispinfoFileList(NMHDR* pNotifyStruct, LRESULT* result);

	DECLARE_MESSAGE_MAP()

public:
	afx_msg void OnFileExit();
	afx_msg void OnFileNew();
	afx_msg void OnFileLoadmnf();
	CListCtrl m_FileList;
	afx_msg void OnSize(UINT nType, int cx, int cy);
};
