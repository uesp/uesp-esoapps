#pragma once

#ifndef __AFXWIN_H__
	#error "include 'pch.h' before including this file for PCH"
#endif

#include "resource.h"


class CEsoExtractDataGuiApp : public CWinApp
{
public:
	CEsoExtractDataGuiApp();

public:
	virtual BOOL InitInstance();


	DECLARE_MESSAGE_MAP()
};

extern CEsoExtractDataGuiApp theApp;
