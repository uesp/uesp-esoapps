

#include "CmdParamHandler.h"


namespace eso {


	CCmdParamHandler::CCmdParamHandler (const std::string AppName, const std::string AppDesc, cmdparamdef_t CmdDefs[], const bool UseDefaultCmdDefs) :
							m_AppDescription(AppDesc),
							m_AppName(AppName)
	{
		static cmdparamdef_t s_DefaultCmdDefs[] = {
			{ "__program",    "", "", "Program executable name.",	false, false, false, false, "" },
			{ "verbose",      "v", "verbose", "Description",		false, true,  false,  true, "" },
			{ "help",         "h", "help",    "Help",				false, true,  false,  true, "" },
			{ "",   "", "", "", false, false, false, false, "" }
		};
		
		if (UseDefaultCmdDefs) AddCommandParamDefs(s_DefaultCmdDefs);
		AddCommandParamDefs(CmdDefs);
	}


	void CCmdParamHandler::AddCommandParamDefs (cmdparamdef_t CmdDefs[])
	{
		for (size_t i = 0; !CmdDefs[i].Name.empty(); ++i)
		{
			m_AllCmds.push_back(&CmdDefs[i]);

			m_CmdMapName[CmdDefs[i].Name] = &CmdDefs[i];
			if (!CmdDefs[i].ShortCmd.empty()) m_CmdMapShort[CmdDefs[i].ShortCmd] = &CmdDefs[i];
			if (!CmdDefs[i].LongCmd.empty())  m_CmdMapLong[CmdDefs[i].LongCmd]   = &CmdDefs[i];
		}
	}


	void CCmdParamHandler::DumpCommandLine (void)
	{
		size_t Count = 0;

		PrintLog("Dumping parsed command line parameters:");

		for (CCmdParamValueMap::iterator i = m_CmdParamValues.begin(); i != m_CmdParamValues.end(); ++i)
		{
			if (i->second.pCmdDef->IsOption)
			{
				if (i->second.pCmdDef->PermitMultiples)
					PrintLog("\tOption %s (x%d) = ", i->first.c_str(), i->second.Count);
				else
					PrintLog("\tOption %s = ", i->first.c_str());

			}
			else
			{
				PrintLog("\t%s = ", i->first.c_str());
			}

			for (size_t j = 0; j < i->second.Values.size(); ++j)
			{
				PrintLog("'%s' ", i->second.Values[j].c_str());
			}

			++Count;
		}
	}


	bool CCmdParamHandler::CheckForMissingParams (void)
	{
		bool ReturnResult = true;

		for (size_t i = 0; i < m_AllCmds.size(); ++i)
		{
			if (m_AllCmds[i]->IsRequired)
			{
				if (!HasParamValue(m_AllCmds[i]->Name))
				{
					if (m_AllCmds[i]->IsOption)
						PrintError("Missing required command option for %s ( %s%s%s%s%s )!", m_AllCmds[i]->Name.c_str(), 
							m_AllCmds[i]->ShortCmd.empty() ? "" : "-",
							m_AllCmds[i]->ShortCmd.empty() ? "" : m_AllCmds[i]->ShortCmd.c_str(),
							m_AllCmds[i]->ShortCmd.empty() ? "" : " or ",
							m_AllCmds[i]->LongCmd.empty() ? "" : "--",
							m_AllCmds[i]->LongCmd.empty() ? "" : m_AllCmds[i]->LongCmd.c_str());
					else
						PrintError("Missing required command parameter for %s!", m_AllCmds[i]->Name.c_str());
						
					ReturnResult = false;
				}
			}
		}

		return ReturnResult;
	}


	cmdparamdef_t* CCmdParamHandler::GetCmdParamDef (std::string Param)
	{
		if (Param.empty()) return nullptr;
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);

		if (Param[0] == '-') 
		{
			Param.erase(0, 1);
			if (Param.empty()) return nullptr;

			if (Param[0] == '-') 
			{
				Param.erase(0, 1);
				if (Param.empty()) return nullptr;
				if (m_CmdMapLong.find(Param) != m_CmdMapLong.end()) return m_CmdMapLong[Param];
			}
			else if (m_CmdMapShort.find(Param) != m_CmdMapShort.end())
			{
				 return m_CmdMapShort[Param];
			}
		}

		return nullptr;
	}


	std::string CCmdParamHandler::GetParamValue (std::string Param)
	{
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);

		if (!HasParamValue(Param)) 
		{
			if (!IsParamName(Param)) return "";
			return m_CmdMapName[Param]->DefaultValue;
		}
		else if (m_CmdParamValues[Param].Values.size() == 0)
		{
			if (!IsParamName(Param)) return "";
			return m_CmdMapName[Param]->DefaultValue;
		}

		return m_CmdParamValues[Param].Values[0];
	}


	std::string CCmdParamHandler::GetParamValue (std::string Param, const size_t Index)
	{
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);

		if (!HasParamValue(Param)) 
		{
			if (!IsParamName(Param)) return "";
			return m_CmdMapName[Param]->DefaultValue;
		}
		else if (m_CmdParamValues[Param].Values.size() <= Index)
		{
			if (!IsParamName(Param)) return "";
			return m_CmdMapName[Param]->DefaultValue;
		}

		return m_CmdParamValues[Param].Values[Index];
	}


	int CCmdParamHandler::GetParamValueAsInt (std::string Param)
	{
		return atoi(GetParamValue(Param).c_str());
	}


	size_t CCmdParamHandler::GetParamCount (std::string Param)
	{
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);
		if (!HasParamValue(Param)) return 0;

		return m_CmdParamValues[Param].Count;
	}


	bool CCmdParamHandler::IsShortParam (std::string Param)
	{
		if (Param.empty()) return false;
		if (Param[0] == '-') Param.erase(0, 1);
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);
		return m_CmdMapShort.find(Param) != m_CmdMapShort.end();
	}


	bool CCmdParamHandler::IsLongParam (std::string Param)
	{
		if (Param.size() < 2) return false;
		if (Param.compare(0, 2, "--") == 0) Param.erase(0, 2);
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);
		return m_CmdMapLong.find(Param) != m_CmdMapLong.end();
	}


	bool CCmdParamHandler::IsParamName (std::string Param)
	{
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);
		return m_CmdMapName.find(Param) != m_CmdMapName.end();
	}


	bool CCmdParamHandler::IsParamFormat (const std::string Param)
	{
		if (Param.compare(0, 1, "-")  == 0) return true;
		if (Param.compare(0, 2, "--") == 0) return true;
		return false;
	}

	
	bool CCmdParamHandler::HasParamValue (std::string Param)
	{
		std::transform(Param.begin(), Param.end(), Param.begin(), ::tolower);
		return m_CmdParamValues.find(Param) != m_CmdParamValues.end();
	}


	bool CCmdParamHandler::ParseCommandLine (int argc, char* argv[])
	{
		bool ReturnResult = true;

		if (argc > 0) SetCommandParamValue("__program", argv[0]);

		for (int i = 1; i < argc; ++i)
		{
			std::string Param = argv[i];
			if (Param.empty()) continue;

			m_RawCmdParams.push_back(Param);

			cmdparamdef_t* pCmdDef = GetCmdParamDef(Param);

			if (pCmdDef != nullptr)
			{
				SetCommandParamValue(pCmdDef->Name, "");

				for (int j = 0; j < pCmdDef->NumValues; ++j)
				{
					if (i+1 >= argc)
					{
						PrintError("Missing required parameter value after option '%s'!", Param.c_str());
						ReturnResult = false;
					}
					else if (IsParamFormat(argv[i+1]))
					{
						PrintError("Missing required parameter value after option '%s'!", Param.c_str());
						ReturnResult = false;
					}
					else 
					{
						SetCommandParamValue(pCmdDef->Name, argv[i+1], j);
						++i;
					}
				}

				for (int j = 0; j < pCmdDef->NumOptValues; ++j)
				{
					if (i+1 >= argc)
					{
						break;
					}
					else if (IsParamFormat(argv[i+1]))
					{
						break;
					}
					else 
					{
						SetCommandParamValue(pCmdDef->Name, argv[i+1], pCmdDef->NumValues + j);
						++i;
					}
				}
			}
			else if (IsParamFormat(Param))
			{
				PrintError("Unknown command option '%s' found!", Param.c_str());
				ReturnResult = false;
			}
			else 
			{
				if (!SetNextCommandParamValue(Param)) ReturnResult = false;
			}

		}

		if (!CheckForMissingParams()) ReturnResult = false;
		return ReturnResult;
	}


	void CCmdParamHandler::PrintHelp (void)
	{
		printf("\n");
		printf("%s\n", m_AppDescription.c_str());
		printf("\n");
		printf("Usage: %s [options]", m_AppName.c_str());

		for (size_t i = 0; i < m_AllCmds.size(); ++i)
		{
			if (m_AllCmds[i]->IsOption) continue;
			if (m_AllCmds[i]->Name.compare(0, 2, "__")  == 0) continue;

			if (m_AllCmds[i]->IsRequired) 
				printf(" %s", m_AllCmds[i]->Name.c_str());
			else
				printf(" [%s (opt)]", m_AllCmds[i]->Name.c_str());
		}

		printf("\n");
		printf("\n");
		printf("Options:\n");

		for (size_t i = 0; i < m_AllCmds.size(); ++i)
		{
			if (!m_AllCmds[i]->IsOption) continue;
			std::string UpperName = m_AllCmds[i]->Name;
			std::transform(UpperName.begin(), UpperName.end(), UpperName.begin(), ::toupper);

			if (!m_AllCmds[i]->ShortCmd.empty()) 
			{
				if (m_AllCmds[i]->NumValues == 1)
					printf("   -%s [%s]",  m_AllCmds[i]->ShortCmd.c_str(), UpperName.c_str());
				else if (m_AllCmds[i]->NumValues == 2)
					printf("   -%s [%s1] [%s2]",  m_AllCmds[i]->ShortCmd.c_str(), UpperName.c_str(), UpperName.c_str());
				else if (m_AllCmds[i]->NumValues <= 0)
					printf("   -%s",  m_AllCmds[i]->ShortCmd.c_str());
				else
					printf("   -%s [%s]...",  m_AllCmds[i]->ShortCmd.c_str(), UpperName.c_str());
			}

			if (!m_AllCmds[i]->LongCmd.empty()) 
			{
				if (!m_AllCmds[i]->ShortCmd.empty()) 
					printf(", ");
				else 
					printf("   ");

				if (m_AllCmds[i]->NumValues == 1)
					printf("--%s [%s]", m_AllCmds[i]->LongCmd.c_str(), UpperName.c_str());
				else if (m_AllCmds[i]->NumValues == 2)
					printf("--%s [%s1] [%s2]", m_AllCmds[i]->LongCmd.c_str(), UpperName.c_str(), UpperName.c_str());
				else if (m_AllCmds[i]->NumValues <= 0)
					printf("--%s", m_AllCmds[i]->LongCmd.c_str());
				else
					printf("--%s [%s]...", m_AllCmds[i]->LongCmd.c_str(), UpperName.c_str());
					
					
			}

			if (m_AllCmds[i]->IsRequired) printf("    (Required) ");
			if (m_AllCmds[i]->PermitMultiples) printf("    (Multiples Allowed) ");
			printf("\n");

			printf("\t%s\n", m_AllCmds[i]->Description.c_str());
		}

	}


	bool CCmdParamHandler::SetCommandParamValue (const std::string Name, const std::string Value)
	{
		cmdparamvalue_t ParamValue;

		if (!IsParamName(Name)) return false;

		if (HasParamValue(Name))
		{
			m_CmdParamValues[Name].Values[0] = Value;
			m_CmdParamValues[Name].Count++;
		}
		else
		{
			ParamValue.pCmdDef = m_CmdMapName[Name];
			ParamValue.Values[0] = Value;
			ParamValue.Count = 1;
			m_CmdParamValues[Name] = ParamValue;
		}

		return true;
	}


	bool CCmdParamHandler::SetCommandParamValue(const std::string Name, const std::string Value, const size_t Index)
	{
		cmdparamvalue_t ParamValue;

		if (!IsParamName(Name)) return false;

		if (HasParamValue(Name))
		{
			m_CmdParamValues[Name].Values.resize(Index+1);
			m_CmdParamValues[Name].Values[Index] = Value;
			m_CmdParamValues[Name].Count++;
		}
		else
		{
			ParamValue.pCmdDef = m_CmdMapName[Name];
			ParamValue.Values.resize(Index+1);
			ParamValue.Values[Index] = Value;
			ParamValue.Count = 1;
			m_CmdParamValues[Name] = ParamValue;
		}

		return true;
	}


	bool CCmdParamHandler::SetNextCommandParamValue (const std::string Param)
	{

		for (size_t i = 0; i < m_AllCmds.size(); ++i)
		{
			if (m_AllCmds[i]->IsOption) continue;

			if (!HasParamValue(m_AllCmds[i]->Name))
			{
				SetCommandParamValue(m_AllCmds[i]->Name, Param);
				return true;
			}
		}

		PrintError("Extra command parameter '%s' found!", Param.c_str());
		return false;
	}


	bool DumpCommandLine (void)
	{
		return true;
	}


};