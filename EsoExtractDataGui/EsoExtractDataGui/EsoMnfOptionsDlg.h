#pragma once

using namespace eso;


class CEsoMnfOptionsDlg : public CDialogEx
{
	DECLARE_DYNAMIC(CEsoMnfOptionsDlg)

public:
	CEsoMnfOptionsDlg(CWnd* pParent = nullptr);
	virtual ~CEsoMnfOptionsDlg();

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_OPTIONSDIALOG };
#endif

protected:
	virtual void DoDataExchange(CDataExchange* pDX);

	DECLARE_MESSAGE_MAP()
	virtual void OnOK();

public:
	virtual BOOL OnInitDialog();

	void GetControlData();
	void SetControlData();

	mnf_exportoptions_t m_MnfOptions;
	CButton m_ParseGr2Check;
	CButton m_SaveMnfFileListCheck;
	CButton m_SaveZosftFileListCheck;
	CButton m_ConvertRiffCheck;
	CButton m_DebugOutputCheck;
	CComboBox m_SubfileExtractTypeList;
};
