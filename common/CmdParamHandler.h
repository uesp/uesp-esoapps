#ifndef __CMDPARAMHANDLER_H
#define __CMDPARAMHANDLER_H


#include "EsoCommon.h"
#include <vector>


typedef std::vector<std::string> cmdvalues_t;


namespace eso {


	struct cmdparamdef_t
	{
		std::string Name;
		std::string ShortCmd;
		std::string LongCmd;
		std::string Description;

		bool IsRequired;
		bool IsOption;
		int  NumValues;
		bool PermitMultiples;

		std::string DefaultValue;
	};


	struct cmdparamvalue_t
	{
		cmdparamdef_t* pCmdDef;
		cmdvalues_t    Values;
		size_t		   Count;

		cmdparamvalue_t()
		{
			Values.push_back("");
		}
	};


	typedef std::vector<cmdparamdef_t *> CCmdParamArray;
	typedef std::unordered_map<std::string, cmdparamvalue_t > CCmdParamValueMap;
	typedef std::unordered_map<std::string, cmdparamdef_t* > CCmdParamDefMap;
	typedef std::vector<std::string> CCmdParamStringArray;
	

	class CCmdParamHandler
	{
	protected:
		std::string			m_AppDescription;
		std::string			m_AppName;

		CCmdParamDefMap		m_CmdMapName;
		CCmdParamDefMap		m_CmdMapShort;
		CCmdParamDefMap		m_CmdMapLong;
		CCmdParamArray		m_AllCmds;

		CCmdParamStringArray m_RawCmdParams;

		CCmdParamValueMap	m_CmdParamValues;

	protected:

		bool CheckForMissingParams (void);

		cmdparamdef_t* GetCmdParamDef (std::string Param);

		bool IsParamFormat (const std::string Param);
		bool IsParamName   (std::string Param);
		bool IsShortParam  (std::string Param);
		bool IsLongParam   (std::string Param);

		bool SetNextCommandParamValue (const std::string Param);



	public:
		CCmdParamHandler(const std::string AppName, const std::string AppDesc, cmdparamdef_t CmdDefs[], const bool UseDefaultCmdDefs = true);

		void AddCommandParamDefs (cmdparamdef_t CmdDefs[]);

		void DumpCommandLine (void);
				
		size_t GetParamCount (std::string Param);
		std::string GetParamValue (std::string Param);
		std::string GetParamValue (std::string Param, const size_t Index);
		int GetParamValueAsInt (std::string Param);
		bool HasParamValue (std::string Param);

		bool ParseCommandLine (int argc, char* argv[]);

		void PrintHelp (void);

		bool SetCommandParamValue(const std::string Name, const std::string Value);
		bool SetCommandParamValue(const std::string Name, const std::string Value, const size_t Index);

	};


};



#endif