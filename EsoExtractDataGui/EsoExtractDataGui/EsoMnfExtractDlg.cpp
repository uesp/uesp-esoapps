#include "pch.h"
#include "EsoMnfFile.h"
#include "EsoExtractDataGui.h"
#include "EsoMnfExtractDlg.h"
#include "afxdialogex.h"


CEsoMnfExtractDlg* g_pExtractDlg = nullptr;


IMPLEMENT_DYNAMIC(CEsoMnfExtractDlg, CDialogEx)


BEGIN_MESSAGE_MAP(CEsoMnfExtractDlg, CDialogEx)
	ON_WM_CLOSE()
	ON_BN_CLICKED(IDC_STOPEXTRACT_BUTTON, &CEsoMnfExtractDlg::OnBnClickedStopextractButton)
	ON_WM_TIMER()
END_MESSAGE_MAP()


void l_OnLogOutput(const char* pString, va_list Args)
{
	if (g_pExtractDlg) g_pExtractDlg->OnLogOutput(pString, Args);
}


CEsoMnfExtractDlg::CEsoMnfExtractDlg(CMnfFile& MnfFile, mnf_exportoptions_t& Options, std::vector<dword>& FileIndexes, CWnd* pParent)
	: CDialogEx(IDD_EXTRACTFILE_DIALOG, pParent), m_MnfFile(MnfFile), m_Options(Options), m_FileIndexes(FileIndexes), m_ExtractedFileCount(0),
	m_ExtractedErrorCount(0)
{
	g_pExtractDlg = this;
}


CEsoMnfExtractDlg::~CEsoMnfExtractDlg()
{
	g_pExtractDlg = nullptr;
}


void CEsoMnfExtractDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);

	DDX_Control(pDX, IDC_STOPEXTRACT_BUTTON, m_StopButton);
	DDX_Control(pDX, IDC_EXTRACT_PROGRESS, m_ProgressBar);
	DDX_Control(pDX, IDC_PROGRESS_LABEL, m_ProgressLabel);
	DDX_Control(pDX, IDC_LOGTEXT_EDIT, m_LogEdit);
}


void CEsoMnfExtractDlg::OnOK()
{
	// Do nothing
}


void CEsoMnfExtractDlg::OnCancel()
{
	// Do nothing
}


void CEsoMnfExtractDlg::OnClose()
{

	CDialogEx::EndDialog(IDOK);
}


std::vector<dword> CEsoMnfExtractDlg::CreateSortedFileIndexes()
{
	m_SortedFileIndexes = m_FileIndexes;

	// Sort by archive index and offset to optimize file loading/reading
	sort(m_SortedFileIndexes.begin(), m_SortedFileIndexes.end(), [this](dword lhs, dword rhs) {
		auto& i = m_MnfFile.GetFileTable()[lhs];
		auto& j = m_MnfFile.GetFileTable()[rhs];

		if (i.ArchiveIndex < j.ArchiveIndex) return true;
		if (i.ArchiveIndex == j.ArchiveIndex) return i.Offset < j.Offset;

		return false;
	});

	return m_SortedFileIndexes;
}


BOOL CEsoMnfExtractDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	if (!m_LogFont.CreatePointFont(100, _T("Consolas")))
	{
		m_LogFont.CreatePointFont(80, _T("Courier New"));
	}
	
	m_LogEdit.SetFont(&m_LogFont);
	m_LogEdit.SetOptions(ECOOP_OR, ECO_SAVESEL);

	CFont* pFont = m_StopButton.GetFont();

	LOGFONT logFont;
	pFont->GetLogFont(&logFont);
	logFont.lfWeight = FW_BOLD;

	m_ButtonFont.CreateFontIndirect(&logFont);
	m_StopButton.SetFont(&m_ButtonFont);

	m_ProgressLabel.SetWindowPos(&m_ProgressBar, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

	m_LastArchiveIndex = -1;
	m_NextFileIndex = 0;
	m_IsExtractionFinished = false;
	m_IsExtractionEnabled = true;
	m_ExtractedFileCount = 0;
	m_ExtractedErrorCount = 0;

	m_LogEdit.LimitText(200000);

	g_LogCallbackFunc = l_OnLogOutput;

	CreateSortedFileIndexes();
	SaveFileTables();

	m_ProgressBar.SetRange32(0, 10000);
	m_ProgressBar.SetPos(0);

	m_hTimer = SetTimer(1234, 100, NULL);

	return true;
}


void CEsoMnfExtractDlg::EndFileExtraction()
{
	CString Buffer;

	KillTimer(m_hTimer);
	m_IsExtractionFinished = true;

	m_StopButton.SetWindowText("Finish");
	Buffer.Format("Saving Subfile %7u of %7u (100%% complete)", m_SortedFileIndexes.size(), m_SortedFileIndexes.size());
	m_ProgressLabel.SetWindowText(Buffer);

	PrintError("Finished extracting %d files with %d errors!", m_ExtractedFileCount, m_ExtractedErrorCount);

	m_ProgressBar.SetPos(10000);
}


bool CEsoMnfExtractDlg::DoNextFileExtractionBatch()
{
	if (m_NextFileIndex < 0) return false;
	if (!m_IsExtractionEnabled) return false;

	for (int i = 0; i < BATCH_SIZE; ++i)
	{
		if (m_NextFileIndex >= m_SortedFileIndexes.size()) 
		{
			EndFileExtraction();
			return false;
		}

		DoNextFileExtraction();
	}

	return true;
}


bool CEsoMnfExtractDlg::DoNextFileExtraction()
{
	if (!m_IsExtractionEnabled) return false;

	if (m_NextFileIndex < 0 || m_NextFileIndex >= m_SortedFileIndexes.size())
	{
		EndFileExtraction();
		return false;
	}

	if (m_NextFileIndex % 100 == 0 && m_NextFileIndex != 0)
	{
		PrintError("\tSubfile %7u of %7u: %.0f%% complete...", m_NextFileIndex, m_SortedFileIndexes.size(), (float)m_NextFileIndex*100.0f / (float)(m_SortedFileIndexes.size() + 1));
	}

	m_ProgressBar.SetPos((int)((float)m_NextFileIndex*10000.0f / (float)(m_SortedFileIndexes.size() + 1)));

	CString ProgressText;
	ProgressText.Format("Saving Subfile %7u of %7u (%.0f%% complete)", m_NextFileIndex, m_SortedFileIndexes.size(), ((float)m_NextFileIndex*100.0f / (float)(m_SortedFileIndexes.size() + 1)));
	m_ProgressLabel.SetWindowText(ProgressText);

	dword index = m_SortedFileIndexes[m_NextFileIndex];
	auto& record = m_MnfFile.GetFileTable()[index];
	++m_NextFileIndex;

	if (m_LastArchiveIndex != record.ArchiveIndex)
	{
		std::string InputFilename = m_MnfFile.CreateDataFilename(record.ArchiveIndex);

		if (!m_InputFile.Open(InputFilename, "rb"))
		{
			PrintError("Error: Failed to open DAT '%s'...", InputFilename.c_str());
			return true;
		}

		fpos_t FileSize = m_InputFile.GetSize();

		if (FileSize <= 14)
		{
			PrintError("Skipping empty DAT '%s'...", InputFilename.c_str());
			return true;
		}

		PrintError("Loading DAT '%s'...", InputFilename.c_str());
		m_LastArchiveIndex = record.ArchiveIndex;
	}

	bool result = m_MnfFile.SaveSubFile(record, m_Options.OutputPath, m_Options.ConvertDDS, &m_InputFile, m_Options.ExtractSubFileDataType, m_Options.NoParseGR2, m_Options.ExtractFileExtension, m_Options.NoRiffConvert, m_Options.MatchFilename);

	if (result)
		++m_ExtractedFileCount;
	else
		++m_ExtractedErrorCount;

	return true;
}


bool CEsoMnfExtractDlg::SaveFileTables()
{

	if (!m_Options.MnfOutputFileTable.empty())
	{
		std::string Filename = m_Options.OutputPath + m_Options.MnfOutputFileTable;

		if (!m_MnfFile.DumpFileTable(Filename.c_str()))
			PrintError("Error: Failed to dump the MNF filetable to a text file '%s'!", Filename.c_str());
		else
			PrintError("Saved the MNF filetable to '%s'!", Filename.c_str());
	}

	if (!m_Options.ZosOutputFileTable.empty())
	{
		std::string Filename = m_Options.OutputPath + m_Options.ZosOutputFileTable;

		if (!m_MnfFile.GetZosftFile().DumpFileTable(Filename.c_str()))
			PrintError("Error: Failed to dump the ZOS filetable to a text file '%s'!", Filename.c_str());
		else
			PrintError("Saved the ZOSFT to '%s'!", Filename.c_str());
	}

	return true;
}



void CEsoMnfExtractDlg::OnBnClickedStopextractButton()
{

	if (!m_IsExtractionFinished)
	{
		m_IsExtractionEnabled = false;

		int result = AfxMessageBox("Are you sure you wish to abort file extraction?", MB_YESNO);

		m_IsExtractionEnabled = true;
		if (result != IDYES) return;
	}

	EndDialog(IDOK);
}


void CEsoMnfExtractDlg::OnTimer(UINT_PTR nIDEvent)
{
	if (nIDEvent == m_hTimer) DoNextFileExtractionBatch();

	CDialogEx::OnTimer(nIDEvent);
}


void CEsoMnfExtractDlg::OnLogOutput(const char* pString, va_list Args)
{
	CString LogBuffer;
	CString Buffer;

	LogBuffer.FormatV(pString, Args);

	time_t Now = time(nullptr);
	char TimeBuffer[110];
	SYSTEMTIME SysTime;

	GetLocalTime(&SysTime);
	strftime(TimeBuffer, 100, "%H:%M:%S", localtime(&Now));

	Buffer.Format("%s.%03d -- %s\r\n", TimeBuffer, SysTime.wMilliseconds, LogBuffer);

	long textLength = m_LogEdit.GetWindowTextLength();
	bool IsAtBottom = false;
	SCROLLINFO ScrollInfo;
	long startSel, endSel;

	m_LogEdit.GetSel(startSel, endSel);

	if (m_LogEdit.GetScrollInfo(SB_VERT, &ScrollInfo, SIF_ALL))
	{
		IsAtBottom = ((ScrollInfo.nPos + ScrollInfo.nPage >= (UINT)ScrollInfo.nMax) || ScrollInfo.nPage == 0);
	}

	m_LogEdit.LockWindowUpdate();
	
	m_LogEdit.SetSel(textLength, textLength);
	m_LogEdit.ReplaceSel(Buffer, false);

	if (IsAtBottom)
	{
		long TextLength = m_LogEdit.GetTextLength();
		m_LogEdit.SetSel(TextLength, TextLength);
		m_LogEdit.SendMessage(WM_VSCROLL, SB_BOTTOM, NULL);
	}

	if (startSel != endSel) m_LogEdit.SetSel(startSel, endSel);

	m_LogEdit.UnlockWindowUpdate();
	m_LogEdit.RedrawWindow();
}