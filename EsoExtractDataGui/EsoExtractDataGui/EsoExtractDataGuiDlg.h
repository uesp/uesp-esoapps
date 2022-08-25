#pragma once


using namespace eso;


class CEsoExtractDataGuiDlg : public CDialogEx
{
public:
	mnf_exportoptions_t	m_Options;
	CMnfFile	m_MnfFile;
	CString		m_FilterText;
	CString		m_FilterArchives;

	std::vector<dword> m_SortedFileIndexes;
	int	m_SortedColumn = -1;
	bool m_SortedColumnInverse = false;


public:
	CEsoExtractDataGuiDlg(CWnd* pParent = nullptr);


	bool LoadMnfFile(CString Filename);
	void CreateSortedFileIndex();
	void SortFileIndexes();
	bool ExtractFiles();
	std::unordered_map<dword, dword> ParseArchiveFilter();

	void LoadRegistrySettings();
	void SaveRegistrySettings();

	std::string GetEsoInstallPath();
	std::string GetEsoLiveInstallPath();
	std::string GetEsoPtsInstallPath();


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
	afx_msg void OnColumnclickFilelist(NMHDR *pNMHDR, LRESULT *pResult);
	CEdit m_FilterEdit;
	afx_msg void OnChangeFilteredit();
	CButton m_ExtractButton;
	afx_msg void OnViewOptions();
	afx_msg void OnHelpAbout();
	afx_msg void OnBnClickedExtractButton();
	afx_msg void OnEnChangeArchiveedit();
	CEdit m_ArchiveEdit;
};
