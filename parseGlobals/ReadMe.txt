
	parseGlobals -- by Dave Humphrey, dave@uesp.net
===============================================================================	
parseGlobals is a Python project that parses various data from the Elder 
Scrolls Online (ESO) MMORPG and outputs it into txt/Html formats. 

Data includes:

   - Global objects
   - Lua source code
   - Lua function definitions and calls
   
Current ESO data is available at:

		http://esodata.uesp.net/
   
   
   Usage  
===============================================================================	

   - Using the ESO uespLog addon (http://www.uesp.net/wiki/Online:UespLog_AddOn)
     dump global object using the in-game command "/uespdump globals".
   - Exit the game (or do a "/reloadui") to update the saved variable data.
   - Open the ESO file "documents/Elder Scrolls Online/live/SavedVariables/uespLog.lua"
     in a text editor.  File location may be different depending on your location
	 and OS.
   - Copy the global data and save into its own txt file. Copy all lines from
			[1] = "event{Global::Start}...
	 to
			[XXXX] = "event{Global::End}...",
   - Use the Windows EsoExtractData command line program (http://www.uesp.net/wiki/File:EsoExportMnf.zip)
     to extract the Game.Mnf/Dat ESO files
   - Edit EsoParseData.py to reference the global txt file and the "esoui" directory
     from the extracted Game.Mnf data. Modify the output path in the same file if desired.
   - Run EsoParseData.py.
   - If everything works you'll get a bunch of status output and no errors.
   - Test load the new content.
