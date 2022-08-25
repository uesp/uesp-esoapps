#include "pch.h"
#include "EsoMnfFile.h"
#include "EsoExtractDataGui.h"
#include "EsoMnfOptionsDlg.h"
#include "afxdialogex.h"


IMPLEMENT_DYNAMIC(CEsoMnfOptionsDlg, CDialogEx)

CEsoMnfOptionsDlg::CEsoMnfOptionsDlg(CWnd* pParent)
	: CDialogEx(IDD_OPTIONSDIALOG, pParent)
{

}

CEsoMnfOptionsDlg::~CEsoMnfOptionsDlg()
{
}

void CEsoMnfOptionsDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_PARSEGR2_CHECK, m_ParseGr2Check);
	DDX_Control(pDX, IDC_SAVEMNFFILELIST_CHECK, m_SaveMnfFileListCheck);
	DDX_Control(pDX, IDC_SAVEZOSFTFILELIST_CHECK, m_SaveZosftFileListCheck);
	DDX_Control(pDX, IDC_CONVERTRIFF_CHECK, m_ConvertRiffCheck);
	DDX_Control(pDX, IDC_DEBUGOUTPUT_CHECK, m_DebugOutputCheck);
}


BEGIN_MESSAGE_MAP(CEsoMnfOptionsDlg, CDialogEx)
END_MESSAGE_MAP()


void CEsoMnfOptionsDlg::OnOK()
{
	GetControlData();

	CDialogEx::OnOK();
}


BOOL CEsoMnfOptionsDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	SetControlData();

	return TRUE;
}


void CEsoMnfOptionsDlg::GetControlData()
{
	if (m_ParseGr2Check.GetCheck() == BST_UNCHECKED)
		m_MnfOptions.NoParseGR2 = true;
	else
		m_MnfOptions.NoParseGR2 = false;

	if (m_SaveMnfFileListCheck.GetCheck() == BST_CHECKED)
		m_MnfOptions.MnfOutputFileTable = "mnf.txt";
	else
		m_MnfOptions.MnfOutputFileTable = "";

	if (m_SaveZosftFileListCheck.GetCheck() == BST_CHECKED)
		m_MnfOptions.ZosOutputFileTable = "zosft.txt";
	else
		m_MnfOptions.ZosOutputFileTable = "";

	if (m_ConvertRiffCheck.GetCheck() == BST_UNCHECKED)
		m_MnfOptions.NoRiffConvert = true;
	else
		m_MnfOptions.NoRiffConvert = false;

	if (m_DebugOutputCheck.GetCheck() == BST_CHECKED)
		m_MnfOptions.DebugOutput = true;
	else
		m_MnfOptions.DebugOutput = false;
}


void CEsoMnfOptionsDlg::SetControlData()
{
	if (m_MnfOptions.NoParseGR2)
		m_ParseGr2Check.SetCheck(BST_UNCHECKED);
	else
		m_ParseGr2Check.SetCheck(BST_CHECKED);

	if (m_MnfOptions.MnfOutputFileTable.empty())
		m_SaveMnfFileListCheck.SetCheck(BST_UNCHECKED);
	else
		m_SaveMnfFileListCheck.SetCheck(BST_CHECKED);

	if (m_MnfOptions.ZosOutputFileTable.empty())
		m_SaveZosftFileListCheck.SetCheck(BST_UNCHECKED);
	else
		m_SaveZosftFileListCheck.SetCheck(BST_CHECKED);

	if (m_MnfOptions.NoRiffConvert)
		m_ConvertRiffCheck.SetCheck(BST_UNCHECKED);
	else
		m_ConvertRiffCheck.SetCheck(BST_CHECKED);

	if (m_MnfOptions.DebugOutput)
		m_DebugOutputCheck.SetCheck(BST_CHECKED);
	else
		m_DebugOutputCheck.SetCheck(BST_UNCHECKED);
}
