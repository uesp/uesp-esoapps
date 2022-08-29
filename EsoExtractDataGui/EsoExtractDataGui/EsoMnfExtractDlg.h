#pragma once

using namespace eso;


class CEsoMnfExtractDlg : public CDialogEx
{
	DECLARE_DYNAMIC(CEsoMnfExtractDlg)
public:

	const int BATCH_SIZE = 10;

	CMnfFile& m_MnfFile;
	mnf_exportoptions_t	m_Options;
	std::vector<dword> m_FileIndexes;
	std::vector<dword> m_SortedFileIndexes;
	int	m_ExtractedFileCount;
	int m_ExtractedErrorCount;

	CFont m_ButtonFont;
	CFont m_LogFont;

	int m_LastArchiveIndex;
	int m_NextFileIndex;
	bool m_IsExtractionFinished;
	bool m_IsExtractionEnabled;

	UINT_PTR m_hTimer;

	eso::CFile m_InputFile;

public:
	CEsoMnfExtractDlg(CMnfFile& MnfFile, mnf_exportoptions_t& Options, std::vector<dword>& FileIndexes, CWnd* pParent = nullptr);
	virtual ~CEsoMnfExtractDlg();

	std::vector<dword> CreateSortedFileIndexes();
	bool SaveFileTables();

	bool DoNextFileExtraction();
	bool DoNextFileExtractionBatch();
	void EndFileExtraction();

	void OnLogOutput(const char* pString, va_list Args);


#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_EXTRACTFILE_DIALOG };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);

	DECLARE_MESSAGE_MAP()
	virtual void OnOK();
	virtual void OnCancel();
public:
	virtual BOOL OnInitDialog();
	afx_msg void OnClose();
	afx_msg void OnBnClickedStopextractButton();
	CButton m_StopButton;
	CProgressCtrl m_ProgressBar;
	afx_msg void OnTimer(UINT_PTR nIDEvent);
	CStatic m_ProgressLabel;
	CRichEditCtrl m_LogEdit;
};
