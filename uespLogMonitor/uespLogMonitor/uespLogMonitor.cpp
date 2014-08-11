
#include "stdafx.h"
#include "uespLogMonitor.h"
#include "uespLogMonitorDlg.h"

#ifdef _DEBUG
	#define new DEBUG_NEW
#endif


BEGIN_MESSAGE_MAP(CuespLogMonitorApp, CWinApp)
	ON_COMMAND(ID_HELP, &CWinApp::OnHelp)
END_MESSAGE_MAP()


CuespLogMonitorApp theApp;


CuespLogMonitorApp::CuespLogMonitorApp()
{
	m_dwRestartManagerSupportFlags = AFX_RESTART_MANAGER_SUPPORT_RESTART;
}


BOOL CuespLogMonitorApp::InitInstance()
{
	eso::OpenLog("uespLogMonitor.log"); 

	INITCOMMONCONTROLSEX InitCtrls;
	InitCtrls.dwSize = sizeof(InitCtrls);
	InitCtrls.dwICC = ICC_WIN95_CLASSES;
	InitCommonControlsEx(&InitCtrls);

	AfxInitRichEdit2();

	CWinApp::InitInstance();

	if (!AfxSocketInit())
	{
		AfxMessageBox(IDP_SOCKETS_INIT_FAILED);
		return FALSE;
	}

	AfxEnableControlContainer();

	CShellManager *pShellManager = new CShellManager;
	SetRegistryKey(_T("UESP"));

	CuespLogMonitorDlg dlg;
	m_pMainWnd = &dlg;
	INT_PTR nResponse = dlg.DoModal();

	if (pShellManager != NULL)
	{
		delete pShellManager;
	}
	
	return FALSE;
}

