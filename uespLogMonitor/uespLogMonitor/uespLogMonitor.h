#pragma once

#ifndef __AFXWIN_H__
	#error "include 'stdafx.h' before including this file for PCH"
#endif


#include "resource.h"
#include "EsoCommon.h"
#include "EsoFile.h"


class CuespLogMonitorApp : public CWinApp
{
public:
	CuespLogMonitorApp();

public:
	virtual BOOL InitInstance();

	DECLARE_MESSAGE_MAP()
};


extern CuespLogMonitorApp theApp;