#pragma once
#include "afxwin.h"


struct ulm_options_t;


class COptionsDlg : public CDialogEx
{
	DECLARE_DYNAMIC(COptionsDlg)

protected:
	ulm_options_t*	m_pOptions;


protected:
	void GetControlData();
	void SetControlData();
	void FillLogNameList();
	void FillLogLevelList();
	void UpdateCustomNameState();
		
public:
	enum { IDD = IDD_OPTIONS_DLG };

public:
	COptionsDlg(CWnd* pParent = NULL);
	virtual ~COptionsDlg();

	int DoModal (ulm_options_t& Options);
	

protected:
	virtual void DoDataExchange(CDataExchange* pDX);

	DECLARE_MESSAGE_MAP()
public:
	virtual BOOL OnInitDialog();
	virtual void OnOK();
	CEdit m_UpdateTimeText;
	CEdit m_FormURLText;
	CEdit m_SavedVarPathText;
	CEdit m_CustomNameText;
	CComboBox m_LogNameList;
	CComboBox m_LogLevelList;
	CEdit m_LastTimestampText;
	CButton m_EnabledCheck;
	afx_msg void OnBnClickedBrowseButton();
	afx_msg void OnCbnSelchangeLognameList();
	CEdit m_BackupDataFilename;
	afx_msg void OnBnClickedBrowsebackupdataButton();
	CEdit m_BackupTimestampText;
};
