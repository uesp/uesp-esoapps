-- uespLog.lua -- by Dave Humphrey, dave@uesp.net
-- AddOn for ESO that logs various game data for use on www.uesp.net
--
-- TODO:
--		- Log game version?
--		- Display charges of weapon
--		- Better loot target/source logging
--			- GetLootTargetInfo() Returns: string name, InteractTargetType targetType, string actionName
--		- Extended loot display messages (level, trait, style)
--		- Display message when weapon charges run out
--		- "Item Info" menu for all crafting stations tooltips
--
--
-- CHANGELOG:
--		v0.10 - 30 March 2014
--			- First release (earlier versions were for beta)
--
--		v0.11 - 31 March 2014
--			- Added a list of common NPCs to ignore (Rat, Mudcrab, Familiar, etc...)
--			- Removed inventory update message
--			- Fixed crash when using /uesplog on/off
--			- Tweaked some messages
--			- Gold looted and gold quest rewards are now logged
--
--		v0.11a - 31 March 2014
--			- Removed money messages used for testing
--
--		v0.12 - 8 April 2014
--			- Added /uesptime command
--			- Log change in skill points (for quest rewards)
--			- Now logs maximum HP/MG/ST for NPC targets
--			- Logs lock quality on chests
--			- Coordinates shown in bottom left on map in range (0,0) to (1,1)
--			- Added 'recipes' and 'achievements' options to /uespcount
--			- Added the 'extra' option to /uespdebug for testing purposes
--
--		v0.13 - 15 April 2014
--			- Shows inspiration for crafting events
--			- Shows the link for crafted items
--			- Added the /uespresearch command
--			- Added some messages in custom colors
--			- Added the /uespcolor on|off command
--			- uespLogMonitor: Fixed escape issue
--			- uespLogMonitor: Fixed issue not sending log entries with "blank" section in saved variable file
--			- uespLogMonitor: Log file is appended to and more things output to it
--			- uespLogMonitor: Added two file menu commands
--			- Fixed logging of target positions
--
--		v0.13a - 15 April 2014
--			- uespLogMonitor: Fixed incorrect use of blank account names
--
--		v0.14 - 2 May 2014
--			- Fixed item link/name display for crafted items
--			- Better logging of resource node positions
--			- Distinguish between group and self loot event
--			- Added estimated game time and moon phase for /uesptime
--			- Added /uespcount traits
--			- Added XP display and logging
--			- Improved display of item links
--			- Added MG/HP/ST/UT change display in debug output mode
--			- More colors (disable color messages with /uespcolor off)
--
--		v0.15 - 18 May 2014
--			- Added the "/uespdump smith|smithset" commands
--				- Dumps all smithable items to log when using an appropriate crafting station
--			- Adds a right-click "Link in Chat" menu option to popup item link
--			- Adds a right-click "Show Item Info" menu option on inventory lists and item popups
--			- Added the "/uespmakelink" (/uml) command 
--				- Format: /uespmakelink ID LEVEL SUBTYPE
--				- ID is required but LEVEL/SUBTYPE are optional
--				- For SUBTYPE description see http://www.uesp.net/wiki/User:Daveh/ESO_Notes#Item_Link_Format
--			- Fixed crash when looting some resources in non-english versions of the game
--			- Added the "/uespcharinfo" (/uci) command
--			- Added logging of veteran and alliance points
--			- Trade skill information display:
--				- Use "/uespcraft" to turn various components of the display on/off
--				- Shows provisioning level of ingredients in inventory lists and tooltips
--				- Color codes blue/purple ingredients
--				- Shows whether recipe is known or not in inventory lists (english only at the moment)
--				- Shows whether weapon/armor trait is known or not in inventory lists and tooltips
--				- Shows the item style in inventory lists and tooltips
--				- Provides a similar function as the Show Motifs add-on
--				- Compatible and similar function as the SousChef add-on
--				- Compatible and similar function as the ResearchAssistant add-on+
--			- In Testing: Added autolooting of provisioning ingredients:
--				- Only loot ingredients more than a specific level
--				- Auto loot all other items and money
--				- Turn off the autoloot in the game options to use
--				- Use "/uespcraft autoloot on/off" to enable (initially disabled)
--				- Use "/uespcraft minprovlevel [level]" to set which level of ingredients to autoloot
--				- Normal ingredient level is 1-6, 100 for blue ingredients and 101 for purple
--				- Displays a "Skipped..." message for items not looted
--				- Skipped provisioning items remain in the container
--
--		- v0.16 - 19 May 2014
--			- Fixed display of the "Show Item Info" menu item.
--			- Ingredient and style information shown in tooltip from a clicked item link (trait info can't be shown).
--			- Tweaked looting messages.
--			- Game language added to all log data.
--			- Footlockers now close properly when autoloot is on.
--
--		- v0.17 - 24 May 2014
--			- Always loot plump worms and crawdads (so flower nodes disappear when looted).
--			- Fix crash when autolooting quest items.
--			- Fixed display of pepper ingredient.
--			- Upgraded to 100004 API version for Craglorn.
--
--		- v0.18 - 2 July 2014
--			- Items linked in chat messages are logged.
--			- Items looted from mail messages are logged.
--			- Added a simple craft inspiration summation meter.
--				- Reset via: /uespreset inspiration
--				- Check via: /uespcount inspiration
--			- Item information shows the weapon and armor types.
--			- Added "/uesptime calibrate" to help with time calibration and testing.
--			- Improved the game time estimation.
--			- Changed API version to 100007.
--			- Added check to prevent NIL string outputs to log data.
--
--		- v0.19 - ?
--			- Changed API version to 100008.
--



--	GLOBAL DEFINITIONS
uespLog = { }

	-- Use only for testing
uespLog.enableTesting = false

--if (uespLog.enableTesting) then
	--require "test/uespLog_mock"
--end

uespLog.version = "0.18"
uespLog.releaseDate = "2 July 2014"

uespLog.TAB_CHARACTER = "\t"
uespLog.MIN_TARGET_CHANGE_TIMEMS = 2000
uespLog.ACTION_UNLOCK = GetString(SI_GAMECAMERAACTIONTYPE12)
uespLog.ACTION_USE = GetString(SI_GAMECAMERAACTIONTYPE5)
uespLog.ACTION_FISH = GetString(SI_GAMECAMERAACTIONTYPE16)
uespLog.ACTION_OPEN = GetString(SI_GAMECAMERAACTIONTYPE13)
uespLog.ACTION_SEARCH = GetString(SI_GAMECAMERAACTIONTYPE1)
uespLog.ACTION_HARVEST = GetString(SI_GAMECAMERAACTIONTYPE3)
uespLog.ACTION_MINE = GetString(SI_KEEPRESOURCEPROVIDERTYPE3)
uespLog.ACTION_CUT = "Cut"
uespLog.ACTION_COLLECT = "Collect"

uespLog.currentHarvestTarget = nil
uespLog.lastHarvestTarget = { }

uespLog.startGameTime = GetGameTimeMilliseconds()
uespLog.startTimeStamp = GetTimeStamp()
uespLog.currentXp = GetUnitXP('player')
uespLog.currentVeteranXp = GetUnitVeteranPoints('player')

uespLog.lastMailItems = { }
uespLog.lastMailId = 0

uespLog.lastPlayerHP = -1
uespLog.lastPlayerMG = -1
uespLog.lastPlayerST = -1
uespLog.lastPlayerUT = -1

uespLog.printDumpObject = false
uespLog.countGlobal = 0


uespLog.savedVars = {}
    
	-- DayLength / OffsetMod / MoonStartMod
	-- 21000 / 3600 / 0
	-- 17280 / 9000 / 0
	-- 21000 / 4475 / 207360
	--
uespLog.GAMETIME_REALSECONDS_OFFSET = 6471		-- in real seconds
uespLog.GAMETIME_DAY_OFFSET = 0.37				-- in game time days
uespLog.DEFAULT_GAMETIME_OFFSET = 1396083600
uespLog.DEFAULT_GAMETIME_YEAROFFSET = 582

uespLog.DEFAULT_REALSECONDSPERGAMEDAY = 20955
uespLog.DEFAULT_REALSECONDSPERGAMEYEAR = uespLog.DEFAULT_REALSECONDSPERGAMEDAY * 365
uespLog.DEFAULT_REALSECONDSPERGAMEHOUR = uespLog.DEFAULT_REALSECONDSPERGAMEDAY / 24
uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE = uespLog.DEFAULT_REALSECONDSPERGAMEHOUR / 60
uespLog.DEFAULT_REALSECONDSPERGAMESECOND = uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE / 60

uespLog.DEFAULT_MOONPHASESTARTTIME = 1396083600 - 207360
uespLog.DEFAULT_MOONPHASETIME = 96 * 3600

uespLog.TES_MONTHS = {
	"Morning Star",
	"Sun's Dawn", 
	"First Seed",
	"Rain's Hand",
	"Second Seed",
	"Midyear",
	"Sun's Height",
	"Last Seed",
	"Hearthfire",
	"Frostfall",
	"Sun's Dusk",
	"Evening Star"
}
	
uespLog.TES_WEEKS = {
	"Sundas",
	"Morndas",
	"Tirdas",
	"Middas",
	"Turdas",
	"Fredas",
	"Loredas" 
}

uespLog.ignoredNPCs = {
	Familiar = 1,
	Cat = 1,
	Rat = 1,
	Lizard = 1,
	Mudcrab = 1,
	Horse = 1,
	Snake = 1,
	Scorpion = 1,
	Beetle = 1,
	Fox = 1,
	Goat = 1,
	Chicken = 1,
	Dog = 1,
	Rabbit = 1,
	Clannfear = 1,
	Frog = 1,
	Deer = 1,
	Spider = 1,
	Torchbug = 1,
	Pig = 1, 
	Sheep = 1,
	Cow = 1,
	Butterfly = 1,
	Squirrel = 1,
	Centipede = 1,
	Fleshflies = 1,
	Monkey = 1,
	Wasp = 1,
	Honor = 1,
	Scuttler = 1,
	Scrib = 1,
	Antelope = 1,
	Ox = 1,
	Wormmouth = 1,  	--Craglorn
	Skavenger = 1, 		--Craglorn
	Fellrunner = 1,  	--Craglorn
	Daggerback = 1,  	--Craglorn
	["Fennec Fox"] = 1,  	--Craglorn
	["Thorn Geko"] = 1,  	--Craglorn
	["Pony Guar"] = 1,
	["Bantam Guar"] = 1,
	["Razak's Opus"] = 1,
	["Draft Horse"] = 1,
	["Light Horse"] = 1,
	["Restoring Twilight"] = 1,
	["Winged Twilight"] = 1,
	["Twilight Matriarch"] = 1,
	["Volatile Familiar"] = 1,
}

uespLog.lastTargetData = {
	type = "",
	name = "",
	x = "",
    y = "",
    zone = "",
	gameTime = "",
	timeStamp = "",
	level = "",
	race = "",
	class = "",
	maxHp = "",
	maxMg = "",
	maxSt = "",
}

uespLog.lastOnTargetChange = ""
uespLog.lastOnTargetChangeGameTime = 0
uespLog.lastMoneyChange = 0
uespLog.lastMoneyGameTime = 0
uespLog.lastItemLink = ""
uespLog.lastItemLinks = { }

uespLog.researchColor = "00ffff"
uespLog.timeColor = "00ffff"
uespLog.traitColor = "00ffff"
uespLog.countColor = "00ffff"
uespLog.xpColor = "6699ff"
uespLog.itemColor = "ff9900"
uespLog.statColor = "44ffff"

uespLog.currentTargetData = {
	name = "",
	x = "",
	y = "",
	zone = "",
}

uespLog.currentConversationData = {
    npcName = "",
    npcLevel = "",
    x = "",
    y = "",
    zone = "",
}

uespLog.DEFAULT_DATA = 
{
	data = {}
}

uespLog.DEFAULT_SETTINGS = 
{
	data = {
		["debug"] = false,
		["debugExtra"] = false,
		["logData"] = true,
		["color"] = true,
		["totalInspiration"] = 0,
		["craft"] = true,
		["craftStyle"] = true,
		["craftTrait"] = true,
		["craftRecipe"] = true,
		["craftIngredient"] = true,
		["craftAutoLoot"] = false,
		["craftAutoLootMinProvLevel"] = 1,
	}
}


function uespLog.BoolToOnOff(flag)
	if (flag) then return "on" end
	return "off"
end


function uespLog.GetTotalInspiration()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.totalInspiration == nil) then
		uespLog.savedVars.settings.data.totalInspiration = 0
	end
	
	return uespLog.savedVars.settings.data.totalInspiration
end


function uespLog.SetTotalInspiration(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.totalInspiration = value
end


function uespLog.AddTotalInspiration(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.totalInspiration == nil) then
		uespLog.savedVars.settings.data.totalInspiration = 0
	end
	
	uespLog.savedVars.settings.data.totalInspiration = uespLog.savedVars.settings.data.totalInspiration + value
end


function uespLog.IsDebug()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.debug
end


function uespLog.IsDebugExtra()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.debugExtra == nil) then
		uespLog.savedVars.settings.data.debugExtra = uespLog.DEFAULT_SETTINGS.data.debugExtra
	end
	
	return uespLog.savedVars.settings.data.debugExtra
end


function uespLog.IsColor()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.color
end


function uespLog.SetDebug(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.debug = flag
end	


function uespLog.SetColor(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.color = flag
end	


function uespLog.SetDebugExtra(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.debugExtra == nil) then
		uespLog.savedVars.settings.data.debugExtra = uespLog.DEFAULT_SETTINGS.data.debugExtra
	end
	
	uespLog.savedVars.settings.data.debugExtra = flag
end	


function uespLog.IsLogData()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.logData
end


function uespLog.SetLogData(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.logData = flag
end	


function uespLog.Msg(text)
    d(text)
end


function uespLog.MsgColor(Color, text)
	if (uespLog.IsColor()) then
		d("|c" .. Color .. text)
	else
		d(text)
	end
end


function uespLog.DebugLogMsg(text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = "UESP::Ignored " .. text
		else
			text = "UESP::Logged " .. text
		end
		
		d(text)
	end

end


function uespLog.DebugLogMsgColor(Color, text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = "UESP::Ignored " .. text
		else
			text = "UESP::Logged " .. text
		end
		
		if (uespLog.IsColor()) then
			d("|c" .. Color .. text)
		else
			d(text)
		end
	end

end


function uespLog.DebugMsg(text)
	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		d(text)
	end
end


function uespLog.DebugMsgColor(Color, text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		if (uespLog.IsColor()) then
			d("|c" .. Color .. text)
		else
			d(text)
		end
	end
	
end


function uespLog.DebugExtraMsg(text)
	if (uespLog.IsDebugExtra()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		d(text)
	end
end


function uespLog.gameTime()
	return GetGameTimeMilliseconds()
end


function uespLog.EndsWith(s, send)
	return #s >= #send and s:find(send, #s-#send+1, true) and true or false
end


function uespLog.AppendDataToLog(section, ...)

	if (not uespLog.IsLogData()) then return end
	
	local logString = ""
	local arg = {...}
		
	for i = 1, #arg do
		local argValue = arg[i]
		
		if (argValue == nil) then
			-- Skip nil inputs
		elseif (type(argValue) == "table") then
			
					-- Try to make the event the first thing output
			if (argValue.event ~= nil) then
				logString = logString .. "event{" .. tostring(argValue.event) .. "}  "
			end
			
			for varName, varValue in pairs(argValue) do
				if (varName ~= "event") then
					logString = logString .. tostring(varName).."{" .. tostring(varValue) .. "}  "
				end
			end
		else
			logString = logString .. "unknown{" .. tostring(argValue) .. "}  "
		end
    end
	
	logString = logString .. "lang{".. GetCVar("Language.2") .."}  "
	
	uespLog.AppendStringToLog(section, logString)
end


function uespLog.AppendStringToLog(section, logString)

	if (not uespLog.IsLogData()) then return end
	
	if (logString == nil) then return end

	if (uespLog.savedVars[section] == nil) then
		uespLog.DebugMsg("UESP::Error -- The section" .. tostring(section) .." is not valid!")
		return
	end
	
	local sv = uespLog.savedVars[section].data
	
	if (sv == nil) then
		sv = { }
	end
	
	sv[#sv+1] = logString
end


function uespLog.GetTimeData()
	local result = { }
	
	result.timeStamp = Id64ToString(GetTimeStamp())
	result.gameTime = GetGameTimeMilliseconds()
	
	return result
end


function uespLog.GetLastTargetData()
	local result = { }
	
	result.x = uespLog.lastTargetData.x
	result.y = uespLog.lastTargetData.y
	result.zone = uespLog.lastTargetData.zone
	result.lastTarget = uespLog.lastTargetData.name
	
	return result
end


function uespLog.GetCurrentTargetData()
	local result = { }
	
	result.x = uespLog.currentTargetData.x
	result.y = uespLog.currentTargetData.y
	result.zone = uespLog.currentTargetData.zone
	result.lastTarget = uespLog.currentTargetData.name
	
	return result
end


function uespLog.GetPlayerPositionData()
	return uespLog.GetUnitPositionData("player")
end


function uespLog.GetUnitPositionData(unitTag)
	local result = { }
	
	result.x, result.y = GetMapPlayerPosition(unitTag)
	result.zone = GetMapName()
	
	return result
end


function uespLog.GetUnitPosition(unitName)
	local x, y, z = GetMapPlayerPosition(unitName)
	local zone = GetMapName()
	return x, y, z, zone
end


function uespLog.GetPlayerPosition()
	return uespLog.GetUnitPosition("player")
end


function uespLog.ParseLink(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if type(link) == "string" then
		local color, data, text = link:match("|H(.-):(.-)|h(.-)|h")
		
		if (color == nil or text == nil or data == nil) then
			return link, "", "", "", link, ""
		end
		
		local niceName = link
		local niceLink = link
		
		if (text ~= nil) then
			niceName = text:gsub("%^.*", "")
			niceLink = "|H"..color..":"..data.."|h["..niceName.."]|h"
		end
		
		return text, color, data, niceName, niceLink
    end
	
	return "", "", "", "", link
end


function uespLog.ParseLinkID(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if (type(link) == "string") then
		local color, itemType, itemId, data1, data2, data, text = link:match("|H(.-):(.-):(.-):(.-):(.-):(.-)|h(.-)|h")
		
		if (color == nil or itemId == nil or data1 == nil or data == nil) then
			return link, "", "", "", "", link, link
		end
		
		local niceName = link
		local niceLink = link
		local allData = itemId..":"..data1 .. ":" .. data2 .. ":" .. data
		
		if (text ~= nil) then
			niceName = text:gsub("%^.*", "")
			niceLink = "|H"..color..":"..itemType..":"..allData.."|h["..niceName.."]|h"
		end
		
		
		return text, color, itemId, data2, allData, niceName, niceLink
    end
	
	return "", "", "", "", "", "", link
end


function uespLog.GetItemLinkID(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if type(link) == "string" then
		local color, itemType, itemId, data, text = link:match("|H(.-):(.-):(.-):(.-)|h(.-)|h")
		
		if (color == nil or itemId == nil or itemType == nil or data == nil or text == nil) then
			return nil
		end
		
		local parsedId = tonumber(itemId)
		
		if (parsedId == nil or parsedId <= 0) then
			return nil
		end
		
		return parsedId
    end
	
	return nil
end


--	Function fired at addon loaded to setup variables and default settings
function uespLog.Initialize( self, addOnName )

	if ( addOnName ~= "uespLog" ) then 
		return 
	end
	
	uespLog.savedVars = {
		--["items"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "items", uespLog.DEFAULT_DATA),
		--["quests"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "quests", uespLog.DEFAULT_DATA),
		--["locations"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "locations", uespLog.DEFAULT_DATA),
        --["lorebooks"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "lorebooks", uespLog.DEFAULT_DATA),
        --["books"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "books", uespLog.DEFAULT_DATA),
        --["skyshards"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "skyshards", uespLog.DEFAULT_DATA),
        --["chests"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "chests", uespLog.DEFAULT_DATA),
        --["fish"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "fish", uespLog.DEFAULT_DATA),  
		--["dialog"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "dialog", uespLog.DEFAULT_DATA),  
		--["npcs"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "npcs", uespLog.DEFAULT_DATA),  
		--["recipes"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 2, "recipes", uespLog.DEFAULT_DATA),  
		
		["all"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 3, "all", uespLog.DEFAULT_DATA),  
		
		["achievements"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 3, "achievements", uespLog.DEFAULT_DATA),  
		["globals"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 3, "globals", uespLog.DEFAULT_DATA),  
		
		["info"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 3, "info", uespLog.DEFAULT_DATA),  
		
			-- Parameters
		["settings"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", 3, "settings", uespLog.DEFAULT_SETTINGS),  		
	}
		
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_RETICLE_TARGET_CHANGED, uespLog.OnTargetChange)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_CONDITION_COUNTER_CHANGED, uespLog.OnQuestCounterChanged)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_ADDED, uespLog.OnQuestAdded)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_REMOVED, uespLog.OnQuestRemoved)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_OBJECTIVE_COMPLETED, uespLog.OnQuestObjectiveCompleted)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_ADVANCED, uespLog.OnQuestAdvanced)	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_COMPLETE_EXPERIENCE, uespLog.OnQuestCompleteExperience)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_OPTIONAL_STEP_ADVANCED, uespLog.OnQuestOptionalStepAdvanced)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SKILL_POINTS_CHANGED, uespLog.OnSkillPointsChanged)
		
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LOOT_UPDATED, uespLog.OnLootUpdated)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LOOT_RECEIVED, uespLog.OnLootGained)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MONEY_UPDATE, uespLog.OnMoneyUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_INVENTORY_SINGLE_SLOT_UPDATE, uespLog.OnInventorySlotUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_INVENTORY_ITEM_USED, uespLog.OnInventoryItemUsed)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_BUY_RECEIPT, uespLog.OnBuyReceipt)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SELL_RECEIPT, uespLog.OnSellReceipt)

    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LORE_BOOK_ALREADY_KNOWN, uespLog.OnLoreBookAlreadyKnown)
    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LORE_BOOK_LEARNED, uespLog.OnLoreBookLearned)

    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SHOW_BOOK, uespLog.OnShowBook)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SKILL_RANK_UPDATE, uespLog.OnSkillRankUpdate)

	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CRAFT_COMPLETED, uespLog.OnCraftCompleted)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CONVERSATION_UPDATED, uespLog.OnConversationUpdated)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHATTER_BEGIN, uespLog.OnChatterBegin)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHATTER_END, uespLog.OnChatterEnd)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_RECIPE_LEARNED, uespLog.OnRecipeLearned)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_BEGIN_LOCKPICK, uespLog.OnBeginLockPick)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_EXPERIENCE_UPDATE, uespLog.OnExperienceUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_VETERAN_POINTS_UPDATE, uespLog.OnVeteranPointsUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_ALLIANCE_POINT_UPDATE, uespLog.OnAlliancePointsUpdate)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_POWER_UPDATE, uespLog.OnPowerUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SYNERGY_ABILITY_GAINED, uespLog.OnSynergyAbilityGained)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SYNERGY_ABILITY_LOST, uespLog.OnSynergyAbilityLost)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_EFFECT_CHANGED, uespLog.OnEffectChanged)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHAT_MESSAGE_CHANNEL, uespLog.OnChatMessage)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, uespLog.OnMailMessageTakeAttachedItem)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MAIL_READABLE, uespLog.OnMailMessageReadable)
	
	uespLog.lastPlayerHP = GetUnitPower("player", POWERTYPE_HEALTH)
	uespLog.lastPlayerMG = GetUnitPower("player", POWERTYPE_MAGICKA)
	uespLog.lastPlayerST = GetUnitPower("player", POWERTYPE_STAMINA)
	uespLog.lastPlayerUT = GetUnitPower("player", POWERTYPE_ULTIMATE)
	 	
	uespLog.fillInfoData()
	uespLog.Msg("Initialized uespLog...")
	
	--uespLog.Old_OnAddGameData = ZO_ItemIconTooltip_OnAddGameData
	--ZO_ItemIconTooltip_OnAddGameData = uespLog.new_OnAddGameData
	
	--uespLog.Old_ItemOnAddGameData = ZO_ItemIconTooltip_ItemOnAddGameData
	--ZO_ItemIconTooltip_ItemOnAddGameData = uespLog.new_ItemOnAddGameData
	
    PopupTooltip:SetHandler("OnMouseUp", uespLog.OnTooltipMouseUp)
    --self.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", uespLog.OnTooltipMouseUp)
	SMITHING.creationPanel.resultTooltip:SetHandler("OnMouseUp", uespLog.SmithingCreationOnTooltipMouseUp)
	ALCHEMY.tooltip:SetHandler("OnMouseUp", uespLog.AlchemyOnTooltipMouseUp)
	ALCHEMY.tooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
	ENCHANTING.resultTooltip:SetHandler("OnMouseUp", uespLog.EnchantingOnTooltipMouseUp)
	ENCHANTING.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
	
	zo_callLater(uespLog.InitTradeData, 1000) 
	
	--uespLog.Old_InventorySlot_ShowContextMenu = ZO_InventorySlot_ShowContextMenu
	--uespLog.Old_ZO_InventorySlot_DoPrimaryAction = ZO_InventorySlot_DoPrimaryAction
	--ZO_InventorySlot_ShowContextMenu = uespLog.New_InventorySlot_ShowContextMenu
	--ZO_InventorySlot_DoPrimaryAction = uespLog.ZO_InventorySlot_DoPrimaryAction
end


function uespLog.EnchantingOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetEnchantingResultingItemLink, ENCHANTING:GetAllCraftingBagAndSlots())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(ENCHANTING)
		end
	end
end


function uespLog.AlchemyOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetAlchemyResultingItemLink, ALCHEMY:GetAllCraftingBagAndSlots())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(ALCHEMY)
		end
	end
end



function uespLog.SmithingCreationOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink, SMITHING.creationPanel:GetAllCraftingParameters())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(SMITHING)
		end
	end
end


function uespLog.OnInventoryShowItemInfo (inventorySlot, slotActions)
	local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
	local itemLink = GetItemLink(bag, index, LINK_STYLE_DEFAULT)
	uespLog.ShowItemInfo(itemLink)
end


function uespLog.ZO_InventorySlot_DoPrimaryAction (inventorySlot)
    inventorySlot = GetInventorySlotComponents(inventorySlot)
    PerClickInitializeActions(inventorySlot, PREVENT_CONTEXT_MENU)
    g_slotActions:DoPrimaryAction()
end


function uespLog.New_InventorySlot_ShowContextMenu (inventorySlot)
	PerClickInitializeActions(inventorySlot, USE_CONTEXT_MENU)
    g_slotActions:Show()
	--g_slotActions:AddSlotAction("Show Item Info", uespLog.OnInventoryShowItemInfo, "primary")
	--uespLog.Old_InventorySlot_ShowContextMenu(inventorySlot)
end


function uespLog.OnTooltipMouseUp (control, button, upInside)
	--uespLog.DebugMsg("UESP::OnTooltipMouseUp")

	if upInside and button == 2 then
		--uespLog.DebugMsg("UESP::OnTooltipMouseUp")
		local link = PopupTooltip.lastLink
		
		if link ~= "" then
			--uespLog.DebugMsg("UESP::OnTooltipMouseUp")
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(PopupTooltip)
		end
	end
	
end


function uespLog.ShowItemInfoRowControl (rowControl)
	local dataEntry = rowControl.dataEntry
	local bagId, slotIndex 
	local itemLink = nil
	local storeMode = uespLog.GetStoreMode()
	--SI_STORE_MODE_REPAIR SI_STORE_MODE_BUY_BACK SI_STORE_MODE_BUY  SI_STORE_MODE_SELL

	if (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.slotIndex ~= nil) then
		slotIndex = dataEntry.data.slotIndex
		bagId = dataEntry.data.bagId
	
		if (storeMode == SI_STORE_MODE_BUY_BACK) then
			itemLink = GetBuybackItemLink(slotIndex, LINK_STYLE_DEFAULT)	
		elseif (storeMode == SI_STORE_MODE_BUY) then
			itemLink = GetStoreItemLink(slotIndex, LINK_STYLE_DEFAULT)	
		else
			itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
		end
		
	elseif (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.bag ~= nil) then
		bagId = dataEntry.data.bag
		slotIndex = dataEntry.data.index 
		itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	elseif (rowControl.bagId ~= nil) then
		bagId = rowControl.bagId
		slotIndex = rowControl.itemIndex
		itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	elseif (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.lootId ~= nil) then
		slotIndex = dataEntry.data.lootId
		itemLink = GetLootItemLink(slotIndex, LINK_STYLE_DEFAULT)
	elseif (rowControl.slotIndex ~= nil) then
		slotIndex = rowControl.slotIndex
		itemLink = GetLootItemLink(slotIndex, LINK_STYLE_DEFAULT)
	else
		--uespLog.DebugMsg("UESP::rowControl statValue = "..tostring(rowControl.dataEntry.data.statValue))
		--uespLog.DebugMsg("UESP::rowControl slotIndex = "..tostring(rowControl.dataEntry.data.slotIndex))
		--uespLog.DebugMsg("UESP::ShowItemInfoRowControl no slot info found!")
		return
	end

	if (itemLink == nil) then
		--uespLog.DebugMsg("UESP::ShowItemInfoRowControl null itemLink!")
		return
	end
	
	uespLog.ShowItemInfo(itemLink)
end


uespLog.ARMOR_TYPE_STRINGS = {
	[ARMORTYPE_HEAVY] = "Heavy",
	[ARMORTYPE_LIGHT] = "Light",
	[ARMORTYPE_MEDIUM] = "Medium", 
	[ARMORTYPE_NONE] = "None",
}


uespLog.WEAPON_TYPE_STRINGS = {
	[WEAPONTYPE_AXE] = "Axe",
	[WEAPONTYPE_BOW] = "Bow",
	[WEAPONTYPE_DAGGER] = "Dagger",
	[WEAPONTYPE_FIRE_STAFF] = "Fire Staff",
	[WEAPONTYPE_FROST_STAFF] = "Frost Staff",
	[WEAPONTYPE_HAMMER] = "Hammer",
	[WEAPONTYPE_HEALING_STAFF] = "Healing Staff",
	[WEAPONTYPE_LIGHTNING_STAFF] = "Lightning Staff",
	[WEAPONTYPE_NONE] = "None",
	[WEAPONTYPE_PROP] = "Prop", 
	[WEAPONTYPE_RUNE] = "Rune",
	[WEAPONTYPE_SHIELD] = "Shield",
	[WEAPONTYPE_SWORD] = "Sword",
	[WEAPONTYPE_TWO_HANDED_AXE] = "Two-Handed Axe",
	[WEAPONTYPE_TWO_HANDED_HAMMER] = "Two-Handed Hammer",
	[WEAPONTYPE_TWO_HANDED_SWORD] = "Two-Handed Sword",
}


function uespLog.GetWeaponTypeStr(weaponType)

	if (uespLog.WEAPON_TYPE_STRINGS[weaponType] ~= nil) then
		return uespLog.WEAPON_TYPE_STRINGS[weaponType]
	end
	
	return "Unknown"
end


function uespLog.GetArmorTypeStr(armorType)

	if (uespLog.ARMOR_TYPE_STRINGS[armorType] ~= nil) then
		return uespLog.ARMOR_TYPE_STRINGS[armorType]
	end
	
	return "Unknown"
end



function uespLog.ShowItemInfo (itemLink)
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
	local styleStr = uespLog.GetItemStyleStr(itemStyle)
	local equipTypeStr = uespLog.GetItemEquipTypeStr(equipType)
	local weaponType = GetItemWeaponType(itemLink)
	local armorType = GetItemArmorType(itemLink)
	
	uespLog.MsgColor(uespLog.itemColor, "UESP::Information for "..tostring(itemLink))
	uespLog.MsgColor(uespLog.itemColor, ".    Data: "..tostring(itemData))
	uespLog.MsgColor(uespLog.itemColor, ".    ID: "..tostring(itemId))
	uespLog.MsgColor(uespLog.itemColor, ".    Level: "..tostring(itemLevel))
	uespLog.MsgColor(uespLog.itemColor, ".    Icon: "..tostring(icon))
	uespLog.MsgColor(uespLog.itemColor, ".    Color: "..tostring(itemColor))
	uespLog.MsgColor(uespLog.itemColor, ".    Value: "..tostring(sellPrice))
	uespLog.MsgColor(uespLog.itemColor, ".    Equip Type: "..equipTypeStr.." ("..tostring(equipType)..")")
	uespLog.MsgColor(uespLog.itemColor, ".    Weapon/Armor Type: "..uespLog.GetWeaponTypeStr(weaponType).." ("..tostring(weaponType)..") / "..uespLog.GetArmorTypeStr(armorType).." ("..tostring(armorType)..")")
	uespLog.MsgColor(uespLog.itemColor, ".    Style: "..styleStr.." ("..tostring(itemStyle)..")")
end


function uespLog.new_ItemOnAddGameData (tooltipControl, gameDataType, ...)
	local data = {...}
	
	uespLog.DebugMsg("UESP::gameItemDataType = "..tostring(gameDataType))
	--uespLog.DebugMsg("UESP::Length Data = "..tostring(#data))
	
	for i = 1, #data do
		uespLog.DebugMsg(".  "..tostring(i)..") "..tostring(data[i]))
	end
	
	uespLog.Old_ItemOnAddGameData(tooltipControl, gameDataType, unpack(data))
end


function uespLog.new_OnAddGameData (tooltipControl, gameDataType, ...)
	local data = {...}
	
	uespLog.DebugMsg("UESP::gameDataType = "..tostring(gameDataType))
	--uespLog.DebugMsg("UESP::Length Data = "..tostring(#data))
	
	for i = 1, #data do
		uespLog.DebugMsg(".  "..tostring(i)..") "..tostring(data[i]))
	end
	
	uespLog.Old_OnAddGameData(tooltipControl, gameDataType, unpack(data))
end


function uespLog.fillInfoData ()
	local data = uespLog.savedVars["info"].data
	
	data["uespLogVersion"] = uespLog.version
	data["version"] = _VERSION
	data["language"] = GetCVar("language.2")
	
	local charName = GetUnitName("player")
	local serverCharName = GetUniqueNameForCharacter(charName)
	data["accountName"] = GetDisplayName()
	data["serverCharName"] = serverCharName
	data["characterName"] = charName
	
	data["startGameTime"] = uespLog.startGameTime
	data["startTimeStamp"] = uespLog.startTimeStamp
	data["startTimeStampStr"] = GetDateStringFromTimestamp(uespLog.startTimeStamp)
end


	--	Hook initialization onto the ADD_ON_LOADED event  
EVENT_MANAGER:RegisterForEvent("uespLog" , EVENT_ADD_ON_LOADED, uespLog.Initialize)


function uespLog.OnConversationUpdated (eventCode, conversationBodyText, conversationOptionCount)

	local logData = { }

	logData.event = "ConversationUpdated"
	logData.bodyText = conversationBodyText
	logData.optionCount = conversationOptionCount
	
	uespLog.AppendDataToLog("all", logData, uespLog.currentConversationData, uespLog.GetTimeData())
	
	for i = 1, conversationOptionCount do
		logData = { }
		
		logData.event = "ConversationUpdated::Option"
		logData.option, logData.type, logData.optArg, logData.isImportant, logData.chosenBefore = GetChatterOption(i)
		
		uespLog.AppendDataToLog("all", logData)
	end
	
	uespLog.DebugMsg("UESP::Updated conversation...")
end


function uespLog.OnChatterEnd (eventCode)
	uespLog.currentConversationData.npcName = ""
    uespLog.currentConversationData.npcLevel = ""
    uespLog.currentConversationData.x = ""
    uespLog.currentConversationData.y = ""
    uespLog.currentConversationData.zone = ""
end


function uespLog.OnChatterBegin (eventCode, optionCount)

	local x, y, z, zone = uespLog.GetUnitPosition("interact")
    local npcLevel = GetUnitLevel("interact")
	local npcName = GetUnitName("interact")
	local logData = { }
	
	if (x == nil) then
		x, y, z, zone = uespLog.GetPlayerPosition()
	end
	
	if (npcLevel == nil) then
		npcLevel = ""
	end

    uespLog.currentConversationData.npcName = npcName
    uespLog.currentConversationData.npcLevel = npcLevel
    uespLog.currentConversationData.x = x
    uespLog.currentConversationData.y = y
    uespLog.currentConversationData.zone = zone
	
	logData.event = "ChatterBegin"
	logData.bodyText = GetChatterGreeting()
	logData.optionCount = optionCount
		
	uespLog.AppendDataToLog("all", logData, uespLog.currentConversationData, uespLog.GetTimeData())
	
	for i = 1, optionCount do
		logData = { }
		
		logData.event = "ChatterBegin::Option"
		logData.option, logData.type, logData.optArg, logData.isImportant, logData.chosenBefore = GetChatterOption(i)
		
		uespLog.AppendDataToLog("all", logData)
	end
	
	uespLog.DebugLogMsg("chatter begin...")
end


function uespLog.OnBeginLockPick (eventCode)
	local logData = { }
	
	logData.event = "LockPick"
	logData.quality = GetLockQuality()
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("lock of quality "..tostring(logData.quality))
end


function uespLog.OnShowBook (eventCode, bookTitle, body, medium, showTitle)
	local logData = { }
	
	logData.event = "ShowBook"
	logData.bookTitle = bookTitle
	logData.body = body
	logData.medium = medium
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("book "..bookTitle)
end


function uespLog.OnLoreBookAlreadyKnown (eventCode, bookTitle)
	local logData = { }
	
	logData.event = "LoreBook"
	logData.bookTitle = bookTitle
	logData.known = true
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("lore book "..bookTitle.." (already known)")
end


function uespLog.OnLoreBookLearned (eventCode, categoryIndex, collectionIndex, bookIndex, guildIndex)
	local logData = { }
    local bookTitle, icon, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
	
	logData.event = "LoreBook"
	logData.bookTitle = bookTitle	
	logData.icon = icon
	logData.category = categoryIndex
	logData.collection = collectionIndex
	logData.index = bookIndex
	logData.guild = guildIndex
	logData.known = known
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
		 
	uespLog.DebugLogMsg("lore book "..bookTitle.." (guild "..tostring(guildIndex)..")")
end


function uespLog.OnSkillRankUpdate (eventCode, skillType, skillIndex, rank)
	local logData = { }
	local name, rank1 = GetSkillLineInfo(skillType, skillIndex)

	logData.event = "SkillRankUpdate"
	logData.skillType = skillType	
	logData.skillIndex = skillIndex
	logData.rank = rank
	logData.name = name
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
		 
	uespLog.DebugLogMsg("skill rank update for "..name)
end


function uespLog.OnBuyReceipt (eventCode, itemLink, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
	local logData = { }
	local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
	logData.event = "Buy"
	logData.itemLink = itemLink
	logData.entryType = entryType
	logData.value = money
	logData.qnt = entryQuantity
	logData.sound = itemSoundCategory
	
	if (specialCurrencyQuantity1 > 0) then 
		logData.currency1 = specialCurrencyInfo1
		logData.currencyQnt1 = specialCurrencyQuantity1
	end
	
	if (specialCurrencyQuantity2 > 0) then 
		logData.currency2 = specialCurrencyInfo2
		logData.currencyQnt2 = specialCurrencyQuantity2
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.itemColor, "buy receipt for "..niceLink.."")
end


function uespLog.OnSellReceipt (eventCode, itemLink, itemQuantity, money)
	local logData = { }
	local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
	logData.event = "Sell"
	logData.itemLink = itemLink
	logData.qnt = itemQuantity
	logData.value = money

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.itemColor, "sell receipt for "..niceLink.."")
end


function uespLog.OnQuestAdded (eventCode, journalIndex, questName, objectiveName)
	local logData = { }
	
	logData.event = "QuestAdded"
	logData.quest = questName
	logData.objective = objectiveName
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("quest added "..questName.."::"..objectiveName)
end


function uespLog.OnQuestRemoved (eventCode, isCompleted, questIndex, questName, zoneIndex, poiIndex)
	local logData = { }
	
	logData.event = "QuestRemoved"
	logData.quest = questName
	logData.completed = isCompleted
	logData.zoneIndex = zoneIndex
	logData.poiIndex = poiIndex
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())

	uespLog.DebugLogMsg("quest removed "..questName)
end


function uespLog.OnQuestObjectiveCompleted (eventCode, zoneIndex, poiIndex, xpGained)
	local logData = { }
	
	logData.event = "QuestObjComplete"
	logData.xpGained = xpGained
	logData.zoneIndex = zoneIndex
	logData.poiIndex = poiIndex
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("objective completed")
end


function uespLog.OnQuestCounterChanged (eventCode, journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden)
	local logData = { }
	
	logData.event = "QuestChanged"
	logData.quest = questName
	logData.condition = conditionText
	logData.condType = conditionType
	logData.condVal = newConditionVal
	logData.condMaxVal = conditionMax
	logData.isFail = isFailCondition
	logData.isPushed = isPushed
	logData.isComplete = isComplete
	logData.isCondComplete = isConditionComplete
	logData.isHidden = isStepHidden
	if (stepOverrideText ~= "") then logData.overrideText = stepOverrideText end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
 
	uespLog.DebugLogMsg("change in quest "..questName.."::"..conditionText)
end


function uespLog.OnQuestCompleteExperience (eventCode, questName, xpGained)
	local logData = { }
	
	logData.event = "QuestCompleteExperience"
	logData.quest = questName
	logData.xpGained = xpGained
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg(questName.." complete.")
end


uespLog.EQUIPTYPES = {
	[0]  = "Invalid",
	[1]  = "Head",
	[2]  = "Neck",
	[3]  = "Chest",
	[4]  = "Shoulders",
	[5]  = "One Hand",
	[6]  = "Two Hand",
	[7]  = "Off Hand",
	[8]  = "Waist",
	[9]  = "Legs",
	[10] = "Feet",
	[11] = "Costume",
	[12] = "Ring",
	[13] = "Hand",
	[14] = "Main Hand",
}


function uespLog.GetItemEquipTypeStr(equipType)
	if (uespLog.EQUIPTYPES[equipType] ~= nil) then
		return uespLog.EQUIPTYPES[equipType]
	end
	
	return "Unknown ("..tostring(equipType)..")"
end



uespLog.ITEMSTYLES = {
	[0]  = "None",
	[1]  = "Breton",
	[2]  = "Redguard",
	[3]  = "Orc",
	[4]  = "Dunmer",
	[5]  = "Nord",
	[6]  = "Argonian",
	[7]  = "Altmer",
	[8]  = "Bosmer",
	[9]  = "Khajiit",
	[10] = "Unique",
	[11] = "Aldermi Dominion",
	[12] = "Ebonheart Pact",
	[13] = "Daggerfall Covenant",
	[14] = "Dwemer",
	[15] = "Ancient Elf",
	[16] = "Imperial (area)",
	[17] = "Reach (Barbaric)",
	[18] = "Bandit",
	[19] = "Primitive (Primal)",
	[20] = "Daedric",
	[21] = "Warrior",
	[22] = "Mage",
	[23] = "Rogue",
	[24] = "Summoner",
	[25] = "Marauder",
	[26] = "Healer",
	[27] = "Battlemage",
	[28] = "Nightblade",
	[29] = "Ranger",
	[30] = "Knight",
	[31] = "Draugr",
	[32] = "Maormer",
	[33] = "Akaviri",
	[34] = "Imperial (race)",
	[35] = "Yokudan",
}


function uespLog.GetItemStyleStr(itemStyle)
	if (uespLog.ITEMSTYLES[itemStyle] ~= nil) then
		return uespLog.ITEMSTYLES[itemStyle]
	end
	
	return "Unknown ("..tostring(itemStyle)..")"
end

uespLog.XPREASONS = {
	[-1] = "none",
	[0] = "kill",
	[1] = "quest",
	[2] = "complete poi",
	[3] = "discover poi",
	[4] = "command",
	[5] = "keep reward",
	[6] = "battleground",
	[7] = "scripted event", 
	[8] = "medal",
	[9] = "finesse",
	[10] = "lockpick",
	[11] = "collect book",
	[12] = "skill book",
	[13] = "action",
	[14] = "guild rep",
	[15] = "AVA",
	[16] = "tradeskill",
	[17] = "reward",
	[18] = "tradeskill achievement",
	[19] = "tradeskill quest",
	[20] = "tradeskill consume", 
	[21] = "tradeskill harvest",
	[22] = "tradeskill recipe",
	[23] = "tradeskill trait",
	[24] = "boss kill",
}

uespLog.VETERANXPREASONS = {
	[-1] = "none",
	[0] = "complete poi",
	[1] = "alliance points",
	[2] = "PVP emperor",
	[3] = "monster kill",
	[4] = "dungeon challenge A",
	[5] = "command",
	[6] = "dungeon challenge A",
	[7] = "dungeon challenge A",
	[8] = "dungeon challenge A",
	[9] = "dungeon challenge A",
	[10] = "quest low",
	[11] = "quest med",
	[12] = "quest high",
	[13] = "boss kill",
}


function uespLog.GetXPReasonStr(reason)
	if (uespLog.XPREASONS[reason] ~= nil) then
		return uespLog.XPREASONS[reason]
	end
	
	return "unknown ("..tostring(reason)..")"
end


function uespLog.GetVeteranXPReasonStr(reason)
	if (uespLog.VETERANXPREASONS[reason] ~= nil) then
		return uespLog.VETERANXPREASONS[reason]
	end
	
	return "unknown ("..tostring(reason)..")"
end


function uespLog.OnExperienceUpdate (eventCode, unitTag, currentExp, maxExp, reason)
	local logData = { }
	
	 --if ( unitTag ~= 'player' ) th6en return end
	
	logData.event = "ExperienceUpdate"
	logData.unit = unitTag
	logData.xpGained = currentExp - uespLog.currentXp
	logData.maxXP = maxExp
	logData.reason = reason
	
	uespLog.currentXp = currentExp
	
	if (logData.xpGained == 0 or reason == -1) then
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." xp for "..uespLog.GetXPReasonStr(reason))
end


function uespLog.OnVeteranPointsUpdate (eventCode, unitTag, currentExp, maxExp, reason)
	local logData = { }
	
	 --if ( unitTag ~= 'player' ) th6en return end
	
	logData.event = "VeteranXPUpdate"
	logData.unit = unitTag
	logData.xpGained = currentExp - uespLog.currentVeteranXp
	logData.maxXP = maxExp
	logData.reason = reason
	
	uespLog.currentVeteranXp = currentExp
	
	if (logData.xpGained == 0 or reason == -1) then
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." veteran points for "..uespLog.GetVeteranXPReasonStr(reason))
end


function uespLog.OnAlliancePointsUpdate (eventCode, alliancePoints, playSound, difference)
	local logData = { }
	
	logData.event = "AllianceXPUpdate"
	logData.xpGained = difference
	logData.maxXP = alliancePoints
	
	if (logData.difference == 0) then
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." alliance points.")
end


function uespLog.OnSkillPointsChanged (eventCode, pointsBefore, pointsNow, isSkyShard)

	--if (isSkyShard) then
		--return
	--end

	local logData = { }
	
	logData.event = "SkillPointsChanged"
	logData.points = pointsNow - pointsBefore
	logData.pointsBefore = pointsBefore
	logData.pointsNow = pointsNow
		
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("skill points changed (".. tostring(logData.points) ..")")
end


function uespLog.OnQuestOptionalStepAdvanced (eventCode, text)

	if(text == "") then
		return
	end
	
	local logData = { }
	
	logData.event = "QuestOptionalStep"
	logData.text = text

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("quest optional step advanced ("..text..")")
end


function uespLog.OnQuestAdvanced (eventCode, journalIndex, questName, isPushed, isComplete, mainStepChanged)
	local logData = { }
	
	logData.event = "QuestAdvanced"
	logData.quest = questName
	logData.isPushed = isPushed
	logData.isComplete = isComplete
	logData.mainStepChanged = mainStepChanged

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("quest advanced "..questName)
end


function uespLog.OnRecipeLearned (eventCode, recipeListIndex, recipeIndex)
	uespLog.DumpRecipe(recipeListIndex, recipeIndex,  uespLog.GetTimeData())
	
	local known, recipeName = GetRecipeInfo(recipeListIndex, recipeIndex)
	uespLog.DebugLogMsg("new recipe " .. recipeName)
end


function uespLog.OnMoneyUpdate (eventCode, newMoney, oldMoney, reason)
	local logData = { }
	local posData = uespLog.GetLastTargetData()
	
	if (posData.x == nil or posData.x == "") then
		posData = uespLog.GetPlayerPositionData()
	end
	
	uespLog.lastMoneyChange = newMoney - oldMoney
	uespLog.lastMoneyGameTime = GetGameTimeMilliseconds()

		-- 0 = loot
	if (reason == 0) then
		logData.event = "MoneyGained"
		logData.qnt = uespLog.lastMoneyChange
			
		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
		uespLog.DebugLogMsgColor(uespLog.itemColor, "You looted "..tostring(uespLog.lastMoneyChange).." gold")
		
		-- 4 = quest reward
	elseif (reason == 4) then
		logData.event = "QuestMoney"
		logData.qnt = uespLog.lastMoneyChange

		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
		uespLog.DebugLogMsgColor(uespLog.itemColor, "quest reward "..tostring(uespLog.lastMoneyChange).." gold")
	else
		uespLog.DebugExtraMsg("UESP::Money Change, New="..tostring(newMoney)..",  Old="..tostring(oldMoney)..",  Diff="..tostring(uespLog.lastMoneyChange)..",  Reason="..tostring(reason))
	end	
	
end


function uespLog.OnLootGained (eventCode, receivedBy, itemLink, quantity, itemSound, lootType, self, extraLogData)
	local logData = { }
	local posData = uespLog.GetLastTargetData()
	local msgType = "item"
	--local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	local itemText, itemColor, itemId, itemLevel, itemData, niceName, niceLink = uespLog.ParseLinkID(itemLink)
	local itemStyleStr = uespLog.GetItemStyleStr(itemStyle)
	
	if (uespLog.currentHarvestTarget ~= nil) then
		posData.x = uespLog.currentHarvestTarget.x
		posData.y = uespLog.currentHarvestTarget.y
		posData.zone = uespLog.currentHarvestTarget.zone
		posData.lastTarget = uespLog.currentHarvestTarget.name
		posData.harvestType = uespLog.currentHarvestTarget.harvestType
		msgType = "resource(" .. tostring(posData.harvestType) .. ")"
	elseif (niceLink == niceName) then
		msgType = "quest item"
	end
	
	logData.event = "LootGained"
	logData.itemLink = itemLink
	logData.qnt = quantity
	logData.lootType = lootType
	
	if (posData.x == nil or posData.x == "") then
		posData = uespLog.GetPlayerPositionData()
	end

	if (self) then
		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData(), extraLogData)
		--You looted [Sword] (x1) (level 30, Breton)
		
		if (extraLogData ~= nil and extraLogData.skippedLoot) then
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::Skipped looting "..niceLink.." (x"..tostring(quantity)..") (prov level "..tostring(extraLogData.tradeType)..")")
		else
			--uespLog.DebugLogMsgColor(uespLog.itemColor, "You looted "..msgType.." "..niceLink.." (x"..tostring(quantity)..") (level "..tostring(itemLevel)..", "..itemStyleStr..")")
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You looted "..msgType.." "..niceLink.." (x"..tostring(quantity)..")")
		end
		
		local money = GetLootMoney()
		uespLog.DebugExtraMsg("UESP::LootMoney = "..tostring(money))
	else
		uespLog.DebugMsgColor(uespLog.itemColor, "UESP::Someone looted "..msgType.." "..niceLink.." (x"..tostring(quantity)..")")
	end
	
end


function uespLog.OnCraftCompleted (eventCode, craftSkill)
	local inspiration = GetLastCraftingResultTotalInspiration()
	local numItemsGained = GetNumLastCraftingResultItems()
	local logData = { }
	
	logData.event = "CraftComplete"
	logData.craftSkill = craftSkill
	logData.inspiration = inspiration
	logData.qnt = numItemsGained

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	
	uespLog.AddTotalInspiration(inspiration)
	
	uespLog.DebugLogMsg("craft completed with "..tostring(inspiration).." xp ("..tostring(uespLog.GetTotalInspiration()).." since last reset)")
	
    for i = 1, numItemsGained do
		local itemName, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType, itemStyle, quality, itemSoundCategory, itemInstanceId = GetLastCraftingResultItemInfo(i)
		
		logData = { }
		logData.event = "CraftComplete::Result"
		logData.itemName = itemName
		logData.type = itemType
		logData.equipType = equipType
		logData.quality = quality	
		logData.value = sellPrice
		logData.icon = icon
		logData.qnt = stack
		logData.itemInstanceId = itemInstanceId
		
		uespLog.AppendDataToLog("all", logData)
		
		local itemLink = uespLog.lastItemLinks[itemName]
		if (itemLink == nil) then itemLink = itemName end
		
		local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
		uespLog.DebugLogMsgColor(uespLog.itemColor, "crafted item ".. tostring(niceLink) .." (x"..tostring(stack)..")")
	end
	
	if (numItemsGained == 0) then
		uespLog.DebugLogMsg("0 items crafted")
	end	
end


-- ITEM_SOUND_CATEGORY_FOOTLOCKER
function uespLog.OnInventoryItemUsed (eventCode, itemSoundCategory)
	local logData = { }

	if (itemSoundCategory == ITEM_SOUND_CATEGORY_FOOTLOCKER) then
		logData.event = "OpenFootLocker"
		logData.sound = itemSoundCategory
		uespLog.AppendDataToLog("all", logData)
		uespLog.DebugLogMsg("footlocker opened")
		return
	end
	
	uespLog.DebugExtraMsg("UESP::OnInventoryItemUsed sound="..tostring(itemSoundCategory))
end


function uespLog.OnInventorySlotUpdate (eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
	local itemName = GetItemName(bagId, slotIndex)

		-- Skip durability updates or items already logged
	if (updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE) then
		--uespLog.DebugExtraMsg("UESP::Skipping inventory slot update for "..itemName..", reason "..tostring(updateReason)..", sound "..tostring(itemSoundCategory))
		return
	end
	
	if (not isNewItem) then
		uespLog.DebugExtraMsg("UESP::Skipping inventory slot update for "..itemName..", old, reason "..tostring(updateReason)..", sound "..tostring(itemSoundCategory))
		return
	end
		
	local result = uespLog.LogInventoryItem(bagId, slotIndex, "SlotUpdate")
	
	if (result) then
		uespLog.DebugExtraMsg("inventory slot update for "..itemName..", reason "..tostring(INVENTORY_UPDATE_REASON_DURABILITY_CHANGE)..", sound "..tostring(itemSoundCategory))
	end
	
end


function uespLog.OnTargetChange (eventCode)
    local unitTag = "reticleover"
    local unitType = GetUnitType(unitTag)
	
		--COMBAT_UNIT_TYPE_GROUP
		--COMBAT_UNIT_TYPE_NONE
		--COMBAT_UNIT_TYPE_OTHER
		--COMBAT_UNIT_TYPE_PLAYER
		--COMBAT_UNIT_TYPE_PLAYER_PET

    if (unitType == 2) then -- NPC, COMBAT_UNIT_TYPE_OTHER?
        local name = GetUnitName(unitTag)
        local x, y, z, zone = uespLog.GetUnitPosition(unitTag)
		local gameTime = GetGameTimeMilliseconds()
		local diffTime = gameTime - uespLog.lastOnTargetChangeGameTime

        if (name == nil or name == "" or x <= 0 or y <= 0) then
            return
        end
		
		uespLog.lastTargetData.x = x
		uespLog.lastTargetData.y = y
		uespLog.lastTargetData.zone = zone
		uespLog.lastTargetData.name = name
		
        local level = GetUnitLevel(unitTag)
		local gender = GetUnitGender(unitTag)
		local class = GetUnitClass(unitTag)   	-- Empty?
		local race = GetUnitRace(unitTag)		-- Empty?
		local difficulty = GetUnitDifficulty(unitTag)
		local currentHp, maxHp, effectiveHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
		local currentMg, maxMg, effectiveMg = GetUnitPower(unitTag, POWERTYPE_MAGICKA)
		local currentSt, maxSt, effectiveSt = GetUnitPower(unitTag, POWERTYPE_STAMINA)
		
		uespLog.lastTargetData.maxHp = maxHp
		uespLog.lastTargetData.maxMg = maxMg
		uespLog.lastTargetData.maxSt = maxSt
		uespLog.lastTargetData.level = level
		uespLog.lastTargetData.race = race
		uespLog.lastTargetData.class = class
		uespLog.lastTargetData.type = unitType		
		
		if (uespLog.IsIgnoredNPC(name)) then
			return
		end
	
		if (name == uespLog.lastOnTargetChange or diffTime < uespLog.MIN_TARGET_CHANGE_TIMEMS) then
			return
		end
		
		uespLog.lastOnTargetChange = name
		uespLog.lastOnTargetChangeGameTime = gameTime
		
		local logData = { }
		
		logData.event = "TargetChange"
		logData.name = name
		logData.level = level
		logData.gender = gender
		logData.difficulty = difficulty
		logData.maxHp = maxHp
		logData.maxMg = maxMg
		logData.maxSt = maxSt
		
		uespLog.AppendDataToLog("all", logData, uespLog.GetLastTargetData(), uespLog.GetTimeData())
		
		uespLog.DebugLogMsg("npc "..name)
	elseif (unitType ~= 0) then
		uespLog.lastTargetData.level = ""
		uespLog.lastTargetData.race = ""
		uespLog.lastTargetData.class = ""
		uespLog.lastTargetData.type = unitType		
		uespLog.lastOnTargetChange = ""
	else
		uespLog.lastOnTargetChange = ""
    end
	
end


function uespLog.OnSynergyAbilityGained (eventCode, synergyBuffSlot, grantedAbilityName, beginTime, endTime, iconName)
	--EVENT_SYNERGY_ABILITY_GAINED (integer synergyBuffSlot, string grantedAbilityName, number beginTime, number endTime, string iconName)
	deltaTime = endTime - beginTime
	uespLog.DebugExtraMsg("Gained synergy "..grantedAbilityName.." for "..tostring(deltaTime).."s")
end


function uespLog.OnSynergyAbilityLost (eventCode, synergyBuffSlot)
	--EVENT_SYNERGY_ABILITY_LOST (integer synergyBuffSlot)
	uespLog.DebugExtraMsg("Lost synergy #"..synergyBuffSlot)
end


function uespLog.OnEffectChanged (eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType)
	--EVENT_EFFECT_CHANGED (integer changeType, integer effectSlot, string effectName, string unitTag, number beginTime, number endTime, integer stackCount, string iconName, string buffType, integer effectType, integer abilityType, integer statusEffectType)
	uespLog.DebugExtraMsg("Effect Changed: "..effectName.." unit:"..unitTag.." type:"..changeType.."")
end


function uespLog.OnPowerUpdate (eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	--EVENT_POWER_UPDATE (string unitTag, luaindex powerIndex, integer powerType, integer powerValue, integer powerMax, integer powerEffectiveMax)
	
	if (unitTag ~= "player") then
		return
	end
	
	local diff = 0
	local typeString = ""
	
	if (powerType == POWERTYPE_HEALTH) then
		diff = powerValue - uespLog.lastPlayerHP
		uespLog.lastPlayerHP = GetUnitPower("player", POWERTYPE_HEALTH)
		typeString = "health"
	elseif (powerType == POWERTYPE_MAGICKA) then
		diff = powerValue - uespLog.lastPlayerMG
		uespLog.lastPlayerMG = GetUnitPower("player", POWERTYPE_MAGICKA)
		typeString = "magicka"
	elseif (powerType == POWERTYPE_STAMINA) then
		diff = powerValue - uespLog.lastPlayerST
		uespLog.lastPlayerST = GetUnitPower("player", POWERTYPE_STAMINA)
		typeString = "stamina"
	elseif (powerType == POWERTYPE_ULTIMATE) then
		diff = powerValue - uespLog.lastPlayerUT
		uespLog.lastPlayerUT = GetUnitPower("player", POWERTYPE_ULTIMATE)
		typeString = "ultimate"
	end
	
	if (diff < 0) then
		diff = math.abs(diff)
		uespLog.DebugExtraMsg("Lost "..tostring(diff).." "..typeString)
	elseif (diff > 0) then
		uespLog.DebugExtraMsg("Gained "..tostring(diff).." "..typeString)
	else
		--uespLog.DebugExtraMsg("powerIndex = "..tostring(powerIndex)..", type="..tostring(powerType)..", value="..tostring(powerValue)..", max="..tostring(powerMax)..", effMax="..tostring(powerEffectiveMax))
		--uespLog.DebugExtraMsg("Lost "..tostring(diff).." "..typeString)
	end
	
end


function uespLog.OnFoundSkyshard ()
	local logData = { }
	
	logData.event = "Skyshard"
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("skyshard data...")
end


function uespLog.OnFoundTreasure (name)
	local logData = { }
	
	logData.event = "FoundTreasure"
	logData.name = name
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("treasure found ("..tostring(name)..")")
end


function uespLog.OnFoundFish ()
	local logData = { }
	
	logData.event = "Fish"
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("fishing hole data...")
end


function uespLog.OnMailMessageReadable (eventCode, mailId)
	local senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	
	uespLog.DebugExtraMsg("Read mail from " ..tostring(senderDisplayName).." with "..tostring(numAttachments).." items")
	
	uespLog.lastMailItems = { }
	uespLog.lastMailId = mailId
		
	for attachIndex = 1, numAttachments do
		local itemLink = GetAttachedItemLink(mailId, attachIndex)
		local icon, stack, creatorName = GetAttachedItemInfo(mailId, attachIndex) 
		
		local newItem = { }
		newItem.itemLink = itemLink
		newItem.stack = stack
		newItem.icon = icon
		
		uespLog.lastMailItems[attachIndex] = newItem
	end
	
end


function uespLog.OnMailMessageTakeAttachedItem (eventCode, mailId)
	local senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	local tradeType = CRAFTING_TYPE_INVALID
	local logData = { }
	local timeData = uespLog.GetTimeData()
	
	uespLog.DebugExtraMsg("Received mail item from " ..tostring(senderDisplayName))
	
	if (mailId ~= uespLog.lastMailId or #uespLog.lastMailItems == 0) then
		uespLog.DebugMsg("No attachments in mail")
		return
	end
	
	if (subject == "Getting Groceries" or senderDisplayName == "Gavin Gavonne") then
		tradeType = CRAFTING_TYPE_PROVISIONING
	elseif (senderDisplayName == "Pacrooti") then
		tradeType = CRAFTING_TYPE_WOODWORKING
	elseif (senderDisplayName == "Valinka Stoneheaver") then
		tradeType = CRAFTING_TYPE_BLACKSMITHING
	elseif (senderDisplayName == "Abnab") then
		tradeType = CRAFTING_TYPE_ENCHANTING
	elseif (senderDisplayName == "UNKNOWN") then
		tradeType = CRAFTING_TYPE_CLOTHIER
	elseif (subject == "Raw Materials") then -- Unknown hireling message
		tradeType = 100
	else -- Not a tradeskill hireling message
		tradeType = CRAFTING_TYPE_INVALID
	end
	
	for attachIndex = 1,  #uespLog.lastMailItems do
		--local itemLink = GetAttachedItemLink(mailId, attachIndex)
		--local icon, stack, creatorName = GetAttachedItemInfo(mailId, attachIndex) 
		
		local lastItem = uespLog.lastMailItems[attachIndex]
		
		logData = { }
		logData.event = "MailItem"
		logData.tradeType = tradeType
		logData.itemLink = lastItem.itemLink
		logData.qnt = lastItem.stack
		logData.icon = lastItem.icon
		
		uespLog.AppendDataToLog("all", logData, timeData)
		
		if (tradeType > 0) then
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You received hireling mail item "..tostring(lastItem.itemLink).." (x"..tostring(lastItem.stack)..")")
		else
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You received mail item "..tostring(lastItem.itemLink).." (x"..tostring(lastItem.stack)..")")
		end
	end
	
	uespLog.lastMailItems = { }
	uespLog.lastMailId = 0
end


 function uespLog.OnChatMessage (eventCode, messageType, fromName, chatText)
	--|HFFFFFF:item:45810:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h"
	
	--uespLog.DebugMsg("Chat Message "..tostring(messageType))
	
	local numLinks = 0
	local timeData = uespLog.GetTimeData()
	local logData = { }
	
	for link in string.gmatch(chatText, "|H.-:item:.-|h.-|h") do
		numLinks = numLinks + 1
		--uespLog.DebugMsg("Found link: "..tostring(link))
		
		logData = { }
		logData.itemLink = link
		logData.event = "ItemLink"
		logData.msgType = messageType
		
		uespLog.AppendDataToLog("all", logData, timeData)
    end
	
	if (numLinks > 0) then
		uespLog.DebugExtraMsg("Logged "..tostring(numLinks).." item links from chat message.")
	end
	
	--uespLog.DebugMsg("Chat Message with "..tostring(numLinks).." links")
 end


uespLog.menuUpdated = false


function uespLog.OnUpdate ()

    if IsGameCameraUIModeActive() then
        return
    end

    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()
	local active = IsPlayerInteractingWithObject()
	local interactionType = GetInteractionType()
	local x, y, z, zone
	
	if (interactionType ~= INTERACTION_HARVEST and uespLog.currentHarvestTarget ~= nil) then
		uespLog.DebugExtraMsg("Stopped harvesting "..tostring(uespLog.currentHarvestTarget.name))
		uespLog.currentHarvestTarget = nil
	elseif (interactionType == INTERACTION_HARVEST and uespLog.currentHarvestTarget == nil) then
		uespLog.currentHarvestTarget = { }
		uespLog.currentHarvestTarget.x = uespLog.lastHarvestTarget.x
		uespLog.currentHarvestTarget.y = uespLog.lastHarvestTarget.y
		uespLog.currentHarvestTarget.zone = uespLog.lastHarvestTarget.zone
		uespLog.currentHarvestTarget.name = uespLog.lastHarvestTarget.name
		uespLog.currentHarvestTarget.harvestType = uespLog.lastHarvestTarget.harvestType
				
		uespLog.DebugExtraMsg("Started harvesting "..tostring(uespLog.currentHarvestTarget.name))
	end

    if (name == nil) then
		--if (uespLog.currentTargetData.name ~= "") then uespLog.DebugExtraMsg("CurrentTarget cleared") end
		uespLog.currentTargetData.name = ""
		uespLog.currentTargetData.x = ""
		uespLog.currentTargetData.y = ""
		uespLog.currentTargetData.zone = ""
        return
    end
	
	if (not active) then
		uespLog.lastTargetData.name = name
		uespLog.lastTargetData.x = uespLog.currentTargetData.x
		uespLog.lastTargetData.y = uespLog.currentTargetData.y
		uespLog.lastTargetData.zone = uespLog.currentTargetData.zone
		uespLog.lastTargetData.gameTime = GetGameTimeMilliseconds()
		uespLog.lastTargetData.timeStamp = GetTimeStamp()
    end
	
	if (interactionType == INTERACTION_NONE and action == uespLog.ACTION_COLLECT) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found collect node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "collect"
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_MINE) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found ore node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "ore"
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_CUT) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found wood node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "wood"
	end

    if (action == nil or name == "" or name == uespLog.currentTargetData.name) then
        return
    end
	
	if (DoesUnitExist("recticleover")) then
		x, y, z, zone = uespLog.GetUnitPositionPosition("recticleover")
	else
		x, y, z, zone = uespLog.GetPlayerPosition()
	end
	
	uespLog.currentTargetData.name = name
	uespLog.currentTargetData.x = x
	uespLog.currentTargetData.y = y
	uespLog.currentTargetData.zone = zone
	
	--uespLog.DebugExtraMsg("CurrentTarget = "..tostring(name))
	
    if (interactionType == INTERACTION_NONE and action == uespLog.ACTION_USE) then

        if name == "Skyshard" then
			uespLog.OnFoundSkyshard()
        end

    elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_UNLOCK) then
	
		if (name == "Chest") then
			uespLog.OnFoundTreasure("Chest")
		end
		
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_SEARCH) then
	
		if (name == "Heavy Sack") then
			uespLog.OnFoundTreasure("Heavy Sack")
		end
	
    elseif (action == uespLog.ACTION_FISH) then
		uespLog.OnFoundFish()
    end

end


function uespLog.getDayOfMonth (yearDay)

	if yearDay < 30 then
		return yearDay + 1, 1
	elseif yearDay < 58 then
		return yearDay - 29, 2
	elseif yearDay < 89 then
		return yearDay - 57, 3
	elseif yearDay < 119 then
		return yearDay - 88, 4
	elseif yearDay < 150 then
		return yearDay - 118, 5
	elseif yearDay < 180 then
		return yearDay - 149, 6
	elseif yearDay < 211 then
		return yearDay - 179, 7
	elseif yearDay < 242 then
		return yearDay - 210, 8
	elseif yearDay < 272 then
		return yearDay - 241, 9
	elseif yearDay < 303 then
		return yearDay - 271, 10
	elseif yearDay < 333 then
		return yearDay - 302, 11
	else
		return yearDay - 333, 12
	end
	
end


function uespLog.getMoonPhaseStr(inputTimeStamp)
	local timeStamp = inputTimeStamp or GetTimeStamp()
	
	local moonOffsetTime = timeStamp - uespLog.DEFAULT_MOONPHASESTARTTIME
	local moonPhase = moonOffsetTime / uespLog.DEFAULT_MOONPHASETIME
	local moonPhaseNorm = moonPhase % 1
	local phaseStr = "Unknown"
	
	if (moonPhaseNorm <= 0.06) then
		phaseStr = "New"
	elseif (moonPhaseNorm <= 0.185) then
		phaseStr = "Waxing Crescent"
	elseif (moonPhaseNorm <= 0.31) then
		phaseStr = "First Quarter"
	elseif (moonPhaseNorm <= 0.435) then
		phaseStr = "Waxing Gibbous"
	elseif (moonPhaseNorm <= 0.56) then
		phaseStr = "Full"
	elseif (moonPhaseNorm <= 0.685) then
		phaseStr = "Waning Gibbous"
	elseif (moonPhaseNorm <= 0.81) then
		phaseStr = "Third Quarter"
	elseif (moonPhaseNorm <= 0.935) then
		phaseStr = "Waning Crescent"
	else
		phaseStr = "New"
	end	
	
	local result = string.format("%s (%0.2f)", phaseStr, moonPhase)
	
	return result	
end


function uespLog.getGameTimeStr(inputTimestamp)
	local timeStamp = inputTimestamp or GetTimeStamp()

	local offsetTime = timeStamp - (uespLog.DEFAULT_GAMETIME_OFFSET - uespLog.GAMETIME_REALSECONDS_OFFSET) - uespLog.GAMETIME_DAY_OFFSET * uespLog.DEFAULT_REALSECONDSPERGAMEDAY
	local gameDayTime = offsetTime % uespLog.DEFAULT_REALSECONDSPERGAMEDAY
	local year = math.floor(offsetTime / uespLog.DEFAULT_REALSECONDSPERGAMEYEAR) + uespLog.DEFAULT_GAMETIME_YEAROFFSET
	local yearDay = math.floor((offsetTime % uespLog.DEFAULT_REALSECONDSPERGAMEYEAR) / uespLog.DEFAULT_REALSECONDSPERGAMEDAY)
	local day, month = uespLog.getDayOfMonth(yearDay)
	local weekDay = math.floor((offsetTime / uespLog.DEFAULT_REALSECONDSPERGAMEDAY) % 7) + 1
	local monthStr = uespLog.TES_MONTHS[month]
	local weekDayStr = uespLog.TES_WEEKS[weekDay]
	local hour = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMEHOUR) % 24)
	local minute = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE) % 60)
	local second = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMESECOND) % 60)
	
	local hourStr = string.format("%02d", hour)
	local minuteStr = string.format("%02d", minute)
	local secondStr = string.format("%02d", second)
	
	local TimeStr = "2E "..tostring(year).." "..monthStr.."("..tostring(month).."), "..weekDayStr.."("..tostring(weekDay).."), "..hourStr..":"..minuteStr..":"..secondStr
	--"2E 582 Hearth's Fire, Morndas 08:12:11" 
	
	return TimeStr
end


function uespLog.ShowTime (inputTimestamp)
	local timeStamp = inputTimestamp or GetTimeStamp()
	local localGameTime = GetGameTimeMilliseconds()
	local timeStampStr = Id64ToString(timeStamp)
	local timeStampFmt = GetDateStringFromTimestamp(timeStamp)
	local version = _VERSION
	local gameTimeStr = uespLog.getGameTimeStr(timeStamp)
	local moonPhaseStr = uespLog.getMoonPhaseStr(timeStamp)
		
	uespLog.MsgColor(uespLog.timeColor, "UESP::Game Time = " .. gameTimeStr .. " (est)")
	uespLog.MsgColor(uespLog.timeColor, "UESP::Moon Phase = " .. moonPhaseStr .. " (est)")
	uespLog.MsgColor(uespLog.timeColor, "UESP::localGameTime = " .. tostring(localGameTime/1000) .. " sec")
	uespLog.MsgColor(uespLog.timeColor, "UESP::timeStamp = " .. tostring(timeStamp))
	uespLog.MsgColor(uespLog.timeColor, "UESP::timeStamp Date = " .. timeStampFmt)
	uespLog.MsgColor(uespLog.timeColor, "UESP::_VERSION = " .. version)	
	uespLog.DebugExtraMsg(uespLog.timeColor, "UESP::timeStampStr = " .. timeStampStr)
end


SLASH_COMMANDS["/uesptime"] = function (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%S+") do table.insert(cmdWords, string.lower(word)) end
	
	if (#cmdWords < 1) then
		uespLog.ShowTime()
	elseif (cmdWords[1] == "cal" or cmdWords[1] == "calibrate") then
		local timeStamp = GetTimeStamp()
		local x, y, heading, zone = GetMapPlayerPosition("player")
		local headingStr = string.format("%.2f", heading*57.29582791)
		local cameraHeading = GetPlayerCameraHeading()
		local camHeadingStr = string.format("%.2f", cameraHeading*57.29582791)
		uespLog.MsgColor(uespLog.timeColor, "UESP::Current Time Stamp = " .. tostring(timeStamp).." secs")
		uespLog.MsgColor(uespLog.timeColor, "UESP::Player Heading = " .. tostring(headingStr).." degrees")
		uespLog.MsgColor(uespLog.timeColor, "UESP::Camera Heading = " .. tostring(camHeadingStr).." degrees")
		return
	elseif (cmdWords[1] == "daylength") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day length is currently "..tostring(uespLog.DEFAULT_REALSECONDSPERGAMEDAY).." secs")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value > 0) then
			uespLog.DEFAULT_REALSECONDSPERGAMEDAY = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day length set to "..tostring(uespLog.DEFAULT_REALSECONDSPERGAMEDAY).." secs")
		end
	elseif (cmdWords[1] == "realoffset") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time real offset is currently "..tostring(uespLog.GAMETIME_REALSECONDS_OFFSET).." secs")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value ~= nil) then
			uespLog.GAMETIME_REALSECONDS_OFFSET = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time real offset set to "..tostring(uespLog.GAMETIME_REALSECONDS_OFFSET).." secs")
		end
	elseif (cmdWords[1] == "dayoffset") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day offset is currently "..tostring(uespLog.GAMETIME_DAY_OFFSET).." days")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value ~= nil) then
			uespLog.GAMETIME_DAY_OFFSET = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day offset set to "..tostring(uespLog.GAMETIME_DAY_OFFSET).." days")
		end
	else
		uespLog.ShowTime()
	end
	
end

--[[
STAT_ARMOR_RATING
STAT_ATTACK_POWER
STAT_BLOCK
STAT_CRITICAL_RESISTANCE
STAT_CRITICAL_STRIKE
STAT_DAMAGE_RESIST_COLD
STAT_DAMAGE_RESIST_DISEASE
STAT_DAMAGE_RESIST_DROWN
STAT_DAMAGE_RESIST_EARTH
STAT_DAMAGE_RESIST_FIRE
STAT_DAMAGE_RESIST_GENERIC
STAT_DAMAGE_RESIST_MAGIC
STAT_DAMAGE_RESIST_OBLIVION
STAT_DAMAGE_RESIST_PHYSICAL
STAT_DAMAGE_RESIST_POISON
STAT_DAMAGE_RESIST_SHOCK
STAT_DAMAGE_RESIST_START
STAT_DODGE
STAT_HEALING_TAKEN
STAT_HEALTH_MAX
STAT_HEALTH_REGEN_COMBAT
STAT_HEALTH_REGEN_IDLE
STAT_MAGICKA_MAX
STAT_MAGICKA_REGEN_COMBAT
STAT_MAGICKA_REGEN_IDLE
STAT_MISS
STAT_MITIGATION
STAT_MOUNT_STAMINA_MAX
STAT_MOUNT_STAMINA_REGEN_COMBAT
STAT_MOUNT_STAMINA_REGEN_MOVING
STAT_NONE
STAT_PARRY
STAT_PHYSICAL_PENETRATION
STAT_PHYSICAL_RESIST
STAT_POWER
STAT_SPELL_CRITICAL
STAT_SPELL_MITIGATION
STAT_SPELL_PENETRATION
STAT_SPELL_POWER
STAT_SPELL_RESIST
STAT_STAMINA_MAX
STAT_STAMINA_REGEN_COMBAT
STAT_STAMINA_REGEN_IDLE
STAT_WEAPON_POWER 

STAT_BONUS_OPTION_APPLY_BONUS
STAT_BONUS_OPTION_DONT_APPLY_BONUS

STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP
STAT_SOFT_CAP_OPTION_DONT_APPLY_SOFT_CAP

POWERTYPE_FINESSE
POWERTYPE_HEALTH
POWERTYPE_INVALID
POWERTYPE_MAGICKA
POWERTYPE_MOUNT_STAMINA
POWERTYPE_STAMINA
POWERTYPE_ULTIMATE
POWERTYPE_WEREWOLF

GetUnitPower(string unitTag, CombatMechanicType powerType)
Returns: integer current, integer max, integer effectiveMax
--]]


function uespLog.DisplayPowerStat (statType, statName)
	local currentStat, maxValue, effectiveMax = GetUnitPower("player", statType)
	uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." (effective max "..tostring(effectiveMax).." of ".. tostring(maxValue)..")")
end


function uespLog.DisplayStat (statType, statName)
	--value = GetPlayerStat(DerivedStats derivedStat, StatBonusOption statBonusOption, StatSoftCapOption statSoftCapOption)

	local softCap = GetStatSoftCap(statType)
	local currentStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
	local noCapStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_DONT_APPLY_SOFT_CAP)
	
	if (softCap == nil) then
		uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." (no cap)")
	else
		uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." ("..tostring(noCapStat).." with cap of ".. tostring(softCap)..")")
	end
end


SLASH_COMMANDS["/uespcharinfo"] = function (cmd)
	local numPoints = GetAvailableSkillPoints()
	local numSkyShards = GetNumSkyShards()
	
	uespLog.Msg("UESP::Skill Points = ".. tostring(numPoints))
	uespLog.Msg("UESP::Skyshards = ".. tostring(numSkyShards))
	
	local armorSC = GetStatSoftCap(STAT_ARMOR_RATING)
	local hpSC = GetStatSoftCap(STAT_HEALTH_MAX)
	local mgSC = GetStatSoftCap(STAT_MAGICKA_MAX)
	
	local stSC = GetStatSoftCap(STAT_MAGICKA_REGEN_COMBAT)
	--local value = GetPlayerStat(DerivedStats derivedStat, StatBonusOption statBonusOption, StatSoftCapOption statSoftCapOption)
	
	uespLog.DisplayStat(STAT_HEALTH_MAX, "HP")
	uespLog.DisplayStat(STAT_MAGICKA_MAX, "Magicka")
	uespLog.DisplayStat(STAT_STAMINA_MAX, "Stamina")
	
	uespLog.DisplayStat(STAT_HEALTH_REGEN_COMBAT, "HP Combat Regen")
	uespLog.DisplayStat(STAT_MAGICKA_REGEN_COMBAT, "Magicka Combat Regen")
	uespLog.DisplayStat(STAT_STAMINA_REGEN_COMBAT, "Stamina Combat Regen")
	
	uespLog.DisplayStat(STAT_HEALTH_REGEN_IDLE, "HP Idle Regen")
	uespLog.DisplayStat(STAT_MAGICKA_REGEN_IDLE, "Magicka Idle Regen")
	uespLog.DisplayStat(STAT_STAMINA_REGEN_IDLE, "Stamina Idle Regen")
	
	uespLog.DisplayStat(STAT_ARMOR_RATING, "Armor")
	uespLog.DisplayStat(STAT_BLOCK, "Block")
	uespLog.DisplayStat(STAT_CRITICAL_RESISTANCE, "Critical Resist")
	uespLog.DisplayStat(STAT_SPELL_RESIST, "Spell Resist")
	uespLog.DisplayStat(STAT_SPELL_MITIGATION, "Spell Mitigation")
	uespLog.DisplayStat(STAT_DODGE, "Dodge")
	uespLog.DisplayStat(STAT_PARRY, "Parry")
	uespLog.DisplayStat(STAT_PHYSICAL_RESIST, "Physical Resist")
	
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_COLD, "Resist Cold")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_DISEASE, "Resist Disease")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_DROWN, "Resist Drown")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_EARTH, "Resist Earth")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_FIRE, "Resist Fire")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_GENERIC, "Resist Generic")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_MAGIC, "Resist Magic")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_OBLIVION, "Resist Oblivion")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_PHYSICAL, "Resist Physical")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_POISON, "Resist Poison")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_SHOCK, "Resist Shock")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_START, "Resist Start")
		
	uespLog.DisplayStat(STAT_CRITICAL_STRIKE, "Critical Strike")
	uespLog.DisplayStat(STAT_WEAPON_POWER, "Weapon Power")
	uespLog.DisplayStat(STAT_SPELL_POWER, "Spell Power")
	uespLog.DisplayStat(STAT_SPELL_CRITICAL, "Spell Critical")
	uespLog.DisplayStat(STAT_SPELL_PENETRATION, "Spell Penetration")
	uespLog.DisplayStat(STAT_POWER, "Power")
	uespLog.DisplayStat(STAT_ATTACK_POWER, "Attack Power")
	uespLog.DisplayStat(STAT_MISS, "Miss")
	uespLog.DisplayStat(STAT_PHYSICAL_PENETRATION, "Physical Penetration")
	
	uespLog.DisplayPowerStat(POWERTYPE_HEALTH, "HP")
	uespLog.DisplayPowerStat(POWERTYPE_MAGICKA, "Magicka")
	uespLog.DisplayPowerStat(POWERTYPE_STAMINA, "Stamina")
	uespLog.DisplayPowerStat(POWERTYPE_ULTIMATE, "Ultimate")
	uespLog.DisplayPowerStat(POWERTYPE_FINESSE, "Finesse")
	uespLog.DisplayPowerStat(POWERTYPE_WEREWOLF, "Werewolf")
	uespLog.DisplayPowerStat(POWERTYPE_MOUNT_STAMINA, "Mount Stamina")
	
	--uespLog.DisplayStat(STAT_CRITICAL_STRIKE, "")
	
	--uespLog.Msg("UESP::HP Soft Cap = ".. tostring(hpSC))
	--uespLog.Msg("UESP::MG Soft Cap = ".. tostring(mgSC))
	--uespLog.Msg("UESP::ST Soft Cap = ".. tostring(stSC))
	--uespLog.Msg("UESP::Armor Soft Cap = ".. tostring(armorSC))
end

SLASH_COMMANDS["/uci"] = SLASH_COMMANDS["/uespcharinfo"]


SLASH_COMMANDS["/loc"] = function (cmd)
	local Msg = "Position"
	local logData = { }
	local posData = uespLog.GetPlayerPositionData()
	local x, y, heading, zone = GetMapPlayerPosition("player")
		
	logData.event = "Location"
	
	if (cmd ~= "") then
		logData.label = cmd
		Msg = Msg .. "["..cmd.."]"
	end
	
	Msg = Msg .. string.format(" %.4f, %.4f, %s, heading %.1f deg", posData.x, posData.y, posData.zone, heading*57.29582791)
	--Msg = Msg .. " " .. tostring(posData.x) .. ", " .. tostring(posData.y) ..", " .. tostring(posData.zone) ..", heading "..tostring(heading)
	uespLog.Msg(Msg)
	
	uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
end


SLASH_COMMANDS["/uespdebug"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetDebug(true)
		uespLog.SetDebugExtra(false)
		uespLog.Msg("Turned UESP log messages on.")
	elseif (cmd == "off") then
		uespLog.SetDebug(false)
		uespLog.SetDebugExtra(false)
		uespLog.Msg("Turned UESP log messages off.")
	elseif (cmd == "extra") then
		uespLog.SetDebug(true)
		uespLog.SetDebugExtra(true)
		uespLog.Msg("Turned UESP log messages to DEBUG mode.")
	elseif (cmd == "") then
		local flagStr = uespLog.BoolToOnOff(uespLog.IsDebug())
		if (uespLog.IsDebugExtra()) then flagStr = "DEBUG" end
		uespLog.Msg("uespdebug is currently " .. flagStr .. ". Use on/off/extra to set!")
	end
	
end


SLASH_COMMANDS["/uesplog"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetLogData(true)
		uespLog.Msg("Turned UESP data logging on.")
	elseif (cmd == "off") then
		uespLog.SetLogData(false)
		uespLog.Msg("Turned UESP data logging off.")
	elseif (cmd == "") then
		uespLog.Msg("UESP data logging is currently " .. uespLog.BoolToOnOff(uespLog.IsLogData()) .. ". Use 'on' or 'off' to set!")
	end
	
end


SLASH_COMMANDS["/uespcolor"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetColor(true)
		uespLog.Msg("Turned UESP color output on.")
	elseif (cmd == "off") then
		uespLog.SetColor(false)
		uespLog.Msg("Turned UESP color output off.")
	elseif (cmd == "") then
		uespLog.Msg("UESP color output is currently " .. uespLog.BoolToOnOff(uespLog.IsColor()) .. ". Use 'on' or 'off' to set!")
	end
	
end


SLASH_COMMANDS["/uespdump"] = function(cmd)
	local cmds = { }
	local helpString = "Use one of: recipes, achievements, inventory, globals"

	for i in string.gmatch(cmd, "%S+") do
		cmds[#cmds + 1] = i
	end

	if (#cmds <= 0) then
		uespLog.Msg(helpString)
	elseif (cmds[1] == "recipes") then
		uespLog.DumpRecipes()
	elseif (cmds[1] == "achievements") then
		uespLog.DumpAchievements()
	elseif (cmds[1] == "inventory") then
		uespLog.DumpInventory()
	elseif (cmds[1] == "globals") then
		uespLog.DumpGlobals(tonumber(cmds[2]))
	elseif (cmds[1] == "smith") then
		uespLog.DumpSmithItems(false)
	elseif (cmds[1] == "smithset") then
		uespLog.DumpSmithItems(true)
	elseif (cmds[1] == "tooltip") then
		uespLog.DumpToolTip()
	else
		uespLog.Msg(helpString)
	end
	
end


uespLog.countVariable = function(object)
	local size = 0
	local count = 0
	
	if (object == nil) then
		return 0, 0
	end
	
	for k, v in pairs(object) do
		count = count + 1
		
		if (type(v) == "string") then
			size = size + #v + 16
		elseif (type(v) == "number") then
			size = size + 4
		end
	end
	
	return count, size
end


uespLog.countSection = function(section)
	local size = 0
	local count = 0
	
	if (uespLog.savedVars[section] ~= nil) then
		count, size = uespLog.countVariable(uespLog.savedVars[section].data)
	end
	
	uespLog.Msg("UESP:: Section \"" .. tostring(section) .. "\" has " .. tostring(count) .. " records taking up " .. string.format("%.2f", size/1000000) .. " MB")
	
	return count, size
end


function uespLog.countTraits (craftingSkillType)
	local numLines = GetNumSmithingResearchLines(craftingSkillType)
	local numTraitItems = GetNumSmithingTraitItems()
	local tradeName = uespLog.GetCraftingName(craftingSkillType)
	local totalTraits = 0
	local totalKnown = 0
	
	for researchLineIndex = 1, numLines do
		local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingSkillType, researchLineIndex)

	    uespLog.MsgColor(uespLog.traitColor, "UESP::Traits for "..tradeName.."::"..tostring(name))
	
		for traitIndex = 1, numTraits do
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
			
			if (traitType ~= nil and traitType ~= 0) then
				local knownStr = "not known"
			
				if (known) then
					knownStr = "known"
					uespLog.MsgColor(uespLog.traitColor, ".       "..uespLog.GetItemTraitName(traitType).." is "..knownStr)
					totalKnown = totalKnown + 1
				else
				end
				
				totalTraits = totalTraits + 1
			end
		end
	end

	uespLog.MsgColor(uespLog.traitColor, ".  You know "..totalKnown.." of "..totalTraits.." "..tradeName.." traits.")
end


SLASH_COMMANDS["/uespcount"] = function(cmd)

	if (cmd == "recipes") then
		uespLog.CountRecipes()
		return
	elseif (cmd == "achievements") then
		uespLog.CountAchievements()
		return
	elseif (cmd == "inspiration") then
		uespLog.MsgColor(uespLog.countColor, "You have accumulated "..tostring(uespLog.GetTotalInspiration()).." crafting inspiration since the last reset")
		return
	elseif (cmd == "traits") then
		uespLog.countTraits(CRAFTING_TYPE_BLACKSMITHING)
		uespLog.countTraits(CRAFTING_TYPE_CLOTHIER)
		uespLog.countTraits(CRAFTING_TYPE_WOODWORKING)
		return
	end
	
	local count1, size1 = uespLog.countSection("all")
	local count2, size2 = uespLog.countSection("globals")
	local count3, size3 = uespLog.countSection("achievements")
	local count = count1 + count2 + count3
	local size = size1 + size2 + size3
	
	uespLog.MsgColor(uespLog.countColor, "UESP:: Total of " .. tostring(count) .. " records taking up " .. string.format("%.2f", size/1000000) .. " MB")
end


SLASH_COMMANDS["/uesphelp"] = function(cmd)
	uespLog.Msg("UESP::uespLog Addon v".. tostring(uespLog.version) .. " released ".. uespLog.releaseDate)
	uespLog.Msg("UESP::This add-on logs a variety of data to the saved variables folder.")
	uespLog.Msg("    /uesplog      Turns the logging of data on and off")
	uespLog.Msg("    /uespcount    Displays statistics on the current log")
	uespLog.Msg("    /uespreset    Clears all or part of the logged data")
	uespLog.Msg("    /uespdebug    Turns the debug messages on and off")
	uespLog.Msg("    /uespdump     Outputs a variety of data to the log")
	uespLog.Msg("    /uesptime     Displays the various game times")
	uespLog.Msg("    /uespresearch Shows info on crafting research timers")
	uespLog.Msg("    /uespcolor    Turns color messages on and off")
	uespLog.Msg("    /loc          Displays your current location")
end


function uespLog.LogInventoryItem (bagId, slotIndex, event, extraData)
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	local itemName = GetItemName(bagId, slotIndex)
	local itemTrait = GetItemTrait(bagId, slotIndex)
	local itemType = GetItemType(bagId, slotIndex)
	local icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bagId, slotIndex)
	local usedInCraftingType, craftItemType, extraInfo1, extraInfo2, extraInfo3 = GetItemCraftingInfo(bagId, slotIndex)
	local logData = { }

	if (tostring(itemName) == "") then
		return false
	end
		
	uespLog.lastItemLink = itemLink
	uespLog.lastItemLinks[itemName] = itemLink
	
	logData.event = event
	logData.itemLink = itemLink
	logData.trait = itemTrait
	logData.type = itemType
	logData.icon = icon
	logData.value = sellPrice
	logData.locked = locked
	logData.equipType = equipType
	logData.itemStyle = itemStyle
	logData.quality = quality
	logData.craftType = craftItemType
	logData.qnt = stack
	logData.bag = bagId
	logData.slot = slotIndex

	uespLog.AppendDataToLog("all", logData, extraData)

	return true
end


function uespLog.DumpBag (bagId)
	local bagIcon, bagSlots = GetBagInfo(bagId)
	local slotCount = 0
		
	for slotIndex = 1, bagSlots do
		local result = uespLog.LogInventoryItem(bagId, slotIndex, "InvDump")
		
		if (result) then
			slotCount = slotCount + 1
		end
	end
	
	return slotCount
end


function uespLog.DumpInventory ()
	local maxBags = GetMaxBags()
	local slotCount = 0
	
	local logData = { }
	logData.event = "InvDumpStart"
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	slotCount = slotCount + uespLog.DumpBag(BAG_WORN)	   --0
	slotCount = slotCount + uespLog.DumpBag(BAG_BACKPACK)  --1
	slotCount = slotCount + uespLog.DumpBag(BAG_BANK)	   --2
	slotCount = slotCount + uespLog.DumpBag(BAG_BUYBACK)   --3
	slotCount = slotCount + uespLog.DumpBag(BAG_GUILDBANK) --4
	
	logData = { }
	logData.event = "InvDumpEnd"
	uespLog.AppendDataToLog("all", logData)
	
	uespLog.DebugMsg("UESP::Output ".. slotCount .." inventory items to log!");
end


function uespLog.DumpObject (prefix, a, level, maxLevel) 
	local logData = { }
	local parentPrefix = ""
	
	if (prefix ~= "_G") then
		parentPrefix = prefix .. "."
	end
	
	newLevel = level + 1
	
		-- Prevent recursion of the global object
	if (newLevel > 1 and tostring(a) == "_G") then
		return
	end
  	
	local status, tableIndex, value = pcall(next, a, nil)
  
	while (status and tableIndex ~= nil) do
		local lastIndex = tableIndex
	
		if type(value) == "table" then
			if (level <= maxLevel) then
				uespLog.DumpObject(parentPrefix .. tableIndex, value, newLevel, maxLevel)
			else
				logData = { }
				logData.event = "Global"
				logData.label = "Public"
				logData.type = "table"
				logData.name = parentPrefix .. tostring(tableIndex)
				logData.value = tostring(value)
				uespLog.AppendDataToLog("globals", logData)
				
				if (uespLog.printDumpObject) then
					uespLog.DebugMsg("UESP::table "..tostring(tableIndex))
				end
			end
		elseif type(value) == "function" then
			logData = {} 
			logData.event = "Global"
			logData.type = "function"
			logData.label = "Public"
			logData.value = tostring(value)
			logData.name = parentPrefix .. tostring(tableIndex) .. "()"
			uespLog.AppendDataToLog("globals", logData)
			uespLog.countGlobal = uespLog.countGlobal + 1
			
			if (uespLog.printDumpObject) then
				uespLog.DebugMsg("UESP::Function "..tostring(tableIndex))
			end
		else
			objType = type(value)
			
			logData = {} 
			logData.event = "Global"
			logData.type = objType
			logData.label = "Public"
			logData.name = parentPrefix .. tostring(tableIndex)
			logData.value = tostring(value)
			uespLog.AppendDataToLog("globals", logData)
			
			if (uespLog.printDumpObject) then
				uespLog.DebugMsg("UESP::Function "..tostring(tableIndex).." = "..tostring(value))
			end
			
			uespLog.countGlobal = uespLog.countGlobal + 1
		end
		
		repeat
			status, tableIndex, value = pcall(next, a, tableIndex)
			
			if (not status) then
				local errIndex = string.match(tableIndex, "attempt to access a private function '(%a*)' from")
								
				logData = {} 
				logData.event = "Global"
				logData.label = "Private"
				logData.name = parentPrefix .. tostring(errIndex) .. "()"
				uespLog.AppendDataToLog("globals", logData)
				
				uespLog.countGlobalError = uespLog.countGlobalError + 1
				tableIndex = errIndex
				
				if (uespLog.printDumpObject) then
					uespLog.DebugMsg("UESP::Private "..tostring(errIndex))
				end
			end
		until status or tableIndex == nil
		
	end
  
end


function uespLog.DumpGlobals (maxLevel)
	
		-- Clear global object
	uespLog.savedVars["globals"].data = { }
	
	uespLog.countGlobal = 0
	uespLog.countGlobalError = 0
	
	if (maxLevel == nil or maxLevel <= 0) then
		maxLevel = 3
	elseif (maxLevel > 10) then
		maxLevel = 10
	end
	
	uespLog.DebugMsg("UESP::Dumping global objects to a depth of ".. tostring(maxLevel).."...")
	
	local logData = {} 
	logData.event = "Global::Start"
	uespLog.AppendDataToLog("globals", logData, uespLog.GetTimeData())
	
	uespLog.DumpObject("_G", _G, 0, maxLevel)
	
	logData = {} 
	logData.event = "Global::End"
	uespLog.AppendDataToLog("globals", logData)
		
	uespLog.DebugMsg("UESP::Output ".. tostring(uespLog.countGlobal) .." global objects and ".. tostring(uespLog.countGlobalError) .." private functions to log...")
end


function uespLog.DumpRecipe (recipeListIndex, recipeIndex, extraData)

	local known, recipeName, numIngredients, provisionerLevelReq, qualityReq, specialIngredientType = GetRecipeInfo(recipeListIndex, recipeIndex)
	local resultName, resultIcon, resultStack, resultSellPrice, resultQuality = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
	local resultLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex, LINK_STYLE_DEFAULT)
	local ingrCount = 0

	if (tostring(recipeName) == "") then
		return 0
	end
	
	logData = { }
	logData.event = "Recipe"
	logData.name = recipeName
	logData.numRecipes = numRecipes	
	logData.provLevel = provisionerLevelReq
	logData.numIngredients = numIngredients
	logData.quality = qualityReq
	logData.specialType = specialIngredientType
	uespLog.AppendDataToLog("all", logData, extraData)
	
	logData = { }
	logData.event = "Recipe::Result"
	logData.name = resultName
	logData.icon = resultIcon	
	logData.qnt = resultStack
	logData.value = resultSellPrice
	logData.quality = resultQuality
	logData.itemLink = resultLink
	uespLog.AppendDataToLog("all", logData, extraData)				
	
	for ingredientIndex = 1, numIngredients do
		local ingrName, ingrIcon, requiredQuantity, sellPrice, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
		local itemLink = GetRecipeIngredientItemLink(recipeListIndex, recipeIndex, ingredientIndex, LINK_STYLE_DEFAULT)
		
		logData = { }
		logData.event = "Recipe::Ingredient"
		logData.name = ingrName
		logData.icon = ingrIcon	
		logData.qnt = requiredQuantity
		logData.value = sellPrice
		logData.quality = quality
		logData.itemLink = itemLink
		uespLog.AppendDataToLog("all", logData, extraData)	
		
		ingrCount = ingrCount + 1
	end
	
	return ingrCount
end	


function uespLog.DumpRecipes ()	
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local ingrCount = 0
	local logData = { }
	
	for recipeListIndex = 1, numRecipeLists do
		local name, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
		
		logData = { }
		logData.event = "Recipe::List"
		logData.name = name
		logData.numRecipes = numRecipes
		uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
		
		for recipeIndex = 1, numRecipes do
			ingrCount = ingrCount + uespLog.DumpRecipe(recipeListIndex, recipeIndex)
			recipeCount = recipeCount + 1
		end
	end
	
	logData = { }
	logData.event = "Recipe::End"
	uespLog.AppendDataToLog("all", logData)
	
	uespLog.DebugLogMsg("".. tostring(recipeCount) .." recipes with ".. tostring(ingrCount) .." total ingredients to log...")
end


function uespLog.CountRecipes()
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local knownCount = 0
	
	for recipeListIndex = 1, numRecipeLists do
		local name, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
		
		for recipeIndex = 1, numRecipes do
			local known = GetRecipeInfo(recipeListIndex, recipeIndex)
			recipeCount = recipeCount + 1
			
			if (known) then
				knownCount = knownCount + 1
			end
		end
	end
	
	uespLog.MsgColor(uespLog.countColor, "UESP::You know "..tostring(knownCount).."/"..tostring(recipeCount).." recipes.")	
end


function uespLog.CountAchievements()
	local numCategories = GetNumAchievementCategories()
	local achCount = 0
	local completeCount = 0
	
	for categoryIndex = 1, numCategories do
		local categoryName, numSubCategories, numCateAchievements, earnedCatePoints, totalCatePoints, hidesCatePoints, normalIcon, pressedIcon, mouseoverIcon = GetAchievementCategoryInfo(categoryIndex)
		
		for subCategoryIndex = 1, numSubCategories do
			local subcategoryName, numsubCateAchievements, earnedSubCatePoints, totalSubCatePoints, hidesSubCatePoints = GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
						
			for achievementIndex = 1, numsubCateAchievements do
				local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
				local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
				achCount = achCount + 1
			
				if (achCompleted) then
					completeCount = completeCount + 1
				end
			end
		end
		
		for achievementIndex = 1, numCateAchievements do
			local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
			local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
			achCount = achCount + 1
		
			if (achCompleted) then
				completeCount = completeCount + 1
			end
		end
	end
	
	uespLog.MsgColor(uespLog.countColor, "UESP::You have "..tostring(completeCount).."/"..tostring(achCount).." achievements.")	
end


function uespLog.DumpAchievementPriv (categoryIndex, subCategoryIndex, achievementIndex)
	local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
	local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
	local numRewards = GetAchievementNumRewards(achievementId)	
	local numCriteria = GetAchievementNumCriteria(achievementId)
	local rewardCount = 0
	local criteriaCount = 0
	local logData = { }	
	
	logData.event = "Achievement"
	logData.label = "Achievement"
	logData.description = achDescription
	logData.id = achievementId
	logData.points = achPoints
	logData.icon = achIcon
	logData.numRewards = numRewards
	logData.numCriteria = numCriteria
	uespLog.AppendDataToLog("achievements", logData)
					
	for rewardIndex = 1, numRewards do
		local rewardType, rewardPoints, rewardName, rewardIcon, rewardQuality = GetAchievementRewardInfo(achievementId, rewardIndex)
		local itemLink = ""
		local typeName = ""
							
		if (rewardType == ACHIEVEMENT_REWARD_TYPE_ITEM) then
			itemLink = GetAchievementItemLink(achievementId, rewardIndex, LINK_STYLE_DEFAULT)
			typeName = "item"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_TITLE) then
			typeName = "title"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_POINTS) then
			typeName = "points"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_NONE) then
			typeName = "none"
		end
		
		logData = { }
		logData.event = "Achievement"
		logData.label = "Reward"
		logData.type = typeName
		logData.name = rewardName
		logData.points = rewardPoints
		logData.icon = rewardIcon
		logData.quality = rewardQuality
		logData.itemLink = itemLink
		uespLog.AppendDataToLog("achievements", logData)
	
		rewardCount = rewardCount + 1
	end
	
	for criterionIndex = 1, numCriteria do
		local critDescription, critNumCompleted, critNumRequired = GetAchievementCriterion(achievementId, criterionIndex)
		
		logData = { }
		logData.event = "Achievement"
		logData.label = "Criteria"
		logData.description = critDescription
		logData.numRequired = critNumRequired
		uespLog.AppendDataToLog("achievements", logData)
		
		criteriaCount = criteriaCount + 1
	end

	return rewardCount, criteriaCount
end


function uespLog.DumpAchievements ()
	local numCategories = GetNumAchievementCategories()
	local outputCount = 0
	local rewardCount = 0
	local criteriaCount = 0
	local Msg = ""
	
		-- Clear achievements data
	uespLog.savedVars["achievements"].data = { }
	
	local logData = { }
	logData.event = "Achievement::Start"
	uespLog.AppendDataToLog("achievements", logData, uespLog.GetTimeData())
	
	for categoryIndex = 1, numCategories do
		local categoryName, numSubCategories, numCateAchievements, earnedCatePoints, totalCatePoints, hidesCatePoints, normalIcon, pressedIcon, mouseoverIcon = GetAchievementCategoryInfo(categoryIndex)
		
		logData = { }
		logData.event = "Category"
		logData.name = categoryName
		logData.subCategories = numSubCategories
		logData.numAchievements = numCateAchievements
		logData.points = totalCatePoints
		logData.hidesPoints = hidesCatePoints
		logData.icon = normalIcon
		logData.pressedIcon = pressedIcon
		logData.mouseoverIcon = mouseoverIcon
		uespLog.AppendDataToLog("achievements", logData)
		
		for subCategoryIndex = 1, numSubCategories do
			local subcategoryName, numsubCateAchievements, earnedSubCatePoints, totalSubCatePoints, hidesSubCatePoints = GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
			
			logData = { }
			logData.event = "Subcategory"
			logData.name = subcategoryName
			logData.numAchievements = numsubCateAchievements
			logData.points = totalSubCatePoints
			logData.hidesPoints = hidesSubCatePoints
			uespLog.AppendDataToLog("achievements", logData)
			
			for achievementIndex = 1, numsubCateAchievements do
				local rc, cc = uespLog.DumpAchievementPriv (categoryIndex, subCategoryIndex, achievementIndex)
				rewardCount = rewardCount + rc
				criteriaCount = criteriaCount + cc
				outputCount = outputCount + 1
			end
		end
		
		for achievementIndex = 1, numCateAchievements do
			local rc, cc = uespLog.DumpAchievementPriv (categoryIndex, nil, achievementIndex)
			rewardCount = rewardCount + rc
			criteriaCount = criteriaCount + cc
			outputCount = outputCount + 1
		end

	end
	
	logData = { }
	logData.event = "Achievement::End"
	uespLog.AppendDataToLog("achievements", logData)
	
	uespLog.DebugMsg("UESP::Output ".. outputCount .." achievements, ".. rewardCount.." rewards, and "..criteriaCount.." criterias to log!");
end


uespLog.IsIgnoredNPC = function (name)
	return (uespLog.ignoredNPCs[name] ~= nil)
end


uespLog.clearSection = function(section)

	if (uespLog.savedVars[section] ~= nil) then
		uespLog.savedVars[section].data = { }
	end
	
end


SLASH_COMMANDS["/uespreset"] = function (cmd)
	
	if (cmd == "all") then
		uespLog.clearSection("all")
		uespLog.clearSection("globals")
		uespLog.clearSection("achievements")
		uespLog.Msg("UESP::Reset all logged data")
	elseif (cmd == "globals") then
		uespLog.clearSection("globals")
		uespLog.Msg("UESP::Reset logged global data")
	elseif (cmd == "achievements") then
		uespLog.clearSection("achievements")
		uespLog.Msg("UESP::Reset logged achievement data")
	elseif (cmd == "inspiration") then
		uespLog.SetTotalInspiration(0)
		uespLog.Msg("UESP::Reset crafting inspiration total")
	else
		uespLog.Msg("UESP::Parameter expected...use one of: all, globals, achievements, inspiration")
	end

end


SLASH_COMMANDS["/uesptargetinfo"] = function (cmd)
	uespLog.ShowTargetInfo()
end


SLASH_COMMANDS["/uti"] = function (cmd)
	uespLog.ShowTargetInfo()
end


uespLog.GetCraftingName = function (craftingType)

	if (craftingType == CRAFTING_TYPE_ALCHEMY) then return "Alchemy" end
	if (craftingType == CRAFTING_TYPE_BLACKSMITHING) then return "Blacksmithing" end
	if (craftingType == CRAFTING_TYPE_CLOTHIER) then return "Clothier" end
	if (craftingType == CRAFTING_TYPE_ENCHANTING) then return "Enchanting" end
	if (craftingType == CRAFTING_TYPE_INVALID) then return "Invalid" end
	if (craftingType == CRAFTING_TYPE_PROVISIONING) then return "Provisioning" end
	if (craftingType == CRAFTING_TYPE_WOODWORKING) then return "Woodworking" end
	
	return "Unknown"
end


uespLog.GetItemTraitName = function (traitType)
	return GetString(SI_ITEMTRAITTYPE0 + traitType)
end


uespLog.ShowResearchInfo = function (craftingType)
	local TradeskillName = uespLog.GetCraftingName(craftingType)
	local numLines = GetNumSmithingResearchLines(craftingType)
	local maxSimultaneousResearch = GetMaxSimultaneousSmithingResearch(craftingType)
	local researchCount = 0
	
	if (numLines == 0 or maxSimultaneousResearch == 0) then
		uespLog.MsgColor(uespLog.researchColor, "UESP::"..TradeskillName.." doesn't have any research lines available!")
		return
	end
	
	for researchLineIndex = 1, numLines do
		local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
		
		for traitIndex = 1, numTraits do
			local duration, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
			local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			local traitName = uespLog.GetItemTraitName(traitType)
			
			if (duration ~= nil) then
				local days = math.floor(timeRemainingSecs / 3600 / 24)
				local hours = math.floor(timeRemainingSecs / 3600) % 24
				local minutes = math.floor(timeRemainingSecs / 60) % 60
				local seconds = timeRemainingSecs % 60
				local timeFmt = ""
				
				if (days > 1) then
					timeFmt = string.format("%d days %02d:%02d:%02d", days, hours, minutes, seconds)
				elseif (days > 0) then
					timeFmt = string.format("%d day %02d:%02d:%02d", days, hours, minutes, seconds)
				else
					timeFmt = string.format("%02d:%02d:%02d", hours, minutes, seconds)
				end
				
				--uespLog.Msg("UESP::"..tostring(TradeskillName).." line for "..tostring(name).." ("..tostring(traitName)..") has "..timeFmt.." left on research.")
				uespLog.MsgColor(uespLog.researchColor, "UESP::"..tostring(TradeskillName).." "..tostring(name).." ("..tostring(traitName)..") has "..timeFmt.." left.")
				researchCount = researchCount + 1
			end
		end
	end
	
	if (researchCount < maxSimultaneousResearch) then
		local slotsOpen = maxSimultaneousResearch - researchCount
		uespLog.MsgColor(uespLog.researchColor, "UESP::"..TradeskillName.." has "..tostring(slotsOpen).." research slots available.")
	end

end


SLASH_COMMANDS["/uesptest"] = function (cmd)

	--uespLog.DebugMsg("Showing Test Time (noon)....")
	--uespLog.ShowTime(1398882554)	-- 1398882554 = 14:30 April 30th 2014 which should be exactly noon in game time 
	--uespLog.DebugMsg("Showing Test Time (sunset)....")
	--uespLog.ShowTime(1398889754)   -- 1308889754 = 16:32 April 30th 2014 which should be sunset
	--uespLog.DebugMsg("Showing Test Time (almost new moon)....")
	--uespLog.ShowTime(1399083327)   -- 1399083327 = Wanning crescent moon, almost new, 0.97
	--uespLog.DebugMsg("Showing Test Time (noon)....")
	--uespLog.ShowTime(1399133861)   -- 1399133861 = 12:20 3 May 2014, noon in-game
	--uespLog.DebugMsg("Showing Test Time (midnight)....")
	--uespLog.ShowTime(1399753920)   -- 1399753920 = 16:35 10 May 2014, should be midnight in game with a wanning crescent moon (0.875)
	
	uespLog.DebugMsg("Showing Test Time (12:03)....")
	uespLog.ShowTime(1399133820)
	
	uespLog.DebugMsg("Showing Test Time (12:32)....")
	uespLog.ShowTime(1401041076)
	
	uespLog.DebugMsg("Showing Test Time (12:12)....")
	uespLog.ShowTime(1401061920)
	
	
	local test1 = { }
	local test2 = { }
	
	for i = 1, 10 do
		test1[i] = i+100
	end
	
	for i = 1, 10 do
		table.insert(test2, i+100)
	end
	
	test1[1] = nil
	test2[1] = nil
	
	uespLog.Msg("test1 = "..tostring(table.getn(test1, 1)))
	uespLog.Msg("test2 = "..tostring(table.getn(test2, 1)))
	
	for i = 1, 10 do
		uespLog.Msg("test = "..tostring(test1[i])..", "..tostring(test2[i]))
	end
	
	
	--uespLog.getGameTimeStr()
	
	--local itemLink = "|HFFFFFF:item:45810:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h"
	--d("|HFFFFFF:item:45810:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h test item")
	--ZO_PopupTooltip_SetLink(itemLink)
	
	--PopupTooltip:SetHandler("OnMouseUp", uespLog.OnTooltipMouseUp)
end


SLASH_COMMANDS["/uespresearch"] = function (cmd)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_CLOTHIER)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_BLACKSMITHING)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_WOODWORKING)
end


SLASH_COMMANDS["/uri"] = SLASH_COMMANDS["/uespresearch"]


function uespLog.ShowTargetInfo ()
	--local unitTag = "reticleover"
    --local type = GetUnitType(unitTag)
    --local name = GetUnitName(unitTag)
	--local x, y, z, zone = uespLog.GetUnitPosition(unitTag)
	--local level = GetUnitLevel(unitTag)
	--local gender = GetUnitGender(unitTag)
	--local class = GetUnitClass(unitTag)
	--local race = GetUnitRace(unitTag)
	--local difficulty = GetUnitDifficulty(unitTag)
	--local currentHp, maxHp, effectiveHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
	--local currentMg, maxMg, effectiveMg = GetUnitPower(unitTag, POWERTYPE_MAGICKA)
	--local currentSt, maxSt, effectiveSt = GetUnitPower(unitTag, POWERTYPE_STAMINA)
	--uespLog.Msg("Name:"..tostring(name)..", type:"..tostring(type)..", level:"..tostring(level)..", gender:"..tostring(gender)..", class:"..tostring(class)..", race:"..tostring(race))
	
	if (uespLog.lastTargetData == nil) then
		return
	end
	
	uespLog.Msg("UESP::Last Target Info -- Name:"..tostring(uespLog.lastTargetData.name)..", type:"..tostring(uespLog.lastTargetData.type)..", level:"..tostring(uespLog.lastTargetData.level)..", gender:"..tostring(uespLog.lastTargetData.gender)..", class:"..tostring(uespLog.lastTargetData.class)..", race:"..tostring(uespLog.lastTargetData.race)..",  maxHP:"..tostring(uespLog.lastTargetData.maxHp)..",  maxMG:"..tostring(uespLog.lastTargetData.maxMg)..",  maxST:"..tostring(uespLog.lastTargetData.maxSt))
end


function uespLog.UpdateCoordinates()
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()

    if (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer) then
        local currentOffsetX = ZO_WorldMapContainer:GetLeft()
        local currentOffsetY = ZO_WorldMapContainer:GetTop()
        local parentOffsetX = ZO_WorldMap:GetLeft()
        local parentOffsetY = ZO_WorldMap:GetTop()
        local mouseX, mouseY = GetUIMousePosition()
        local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
        local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

        local normalizedX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
        local normalizedY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000
		local xStr = string.format("%.03f", normalizedX)
		local yStr = string.format("%.03f", normalizedY)

        uespLogCoordinates:SetAlpha(0.8)
        uespLogCoordinates:SetDrawLayer(ZO_WorldMap:GetDrawLayer() + 1)
        uespLogCoordinates:SetAnchor(TOPLEFT, nil, TOPLEFT, parentOffsetX + 0, parentOffsetY + parentHeight)
        uespLogCoordinatesValue:SetText("Coordinates: " .. tostring(xStr) .. ", " .. tostring(yStr))
    else
        uespLogCoordinates:SetAlpha(0)
    end
end


function uespLog.DumpSmithItems(onlySetItems)
	local numPatterns = GetNumSmithingPatterns()
	local numStyles = GetNumSmithingStyleItems()
	local numImprovementItems = GetNumSmithingImprovementItems()
	local numTraitItems = GetNumSmithingTraitItems()
	local craftingType = GetCraftingInteractionType()
	local tradeskillName = uespLog.GetCraftingName(craftingType)
	
	if (numPatterns == 0 or craftingType == 0) then
		uespLog.DebugMsg("UESP::You must be using a smithing station for this to work!")
		return
	end
	
	local startPattern = 1
	
	if (onlySetItems) then
		if (craftingType == CRAFTING_TYPE_BLACKSMITHING) then
			startPattern = 15
		elseif (craftingType == CRAFTING_TYPE_CLOTHIER) then
			startPattern = 15
		elseif (craftingType == CRAFTING_TYPE_WOODWORKING) then
			startPattern = 7
		end
		
		if (startPattern > numPatterns) then
			uespLog.DebugMsg("UESP::You must be at a set smithing station for this to work!")	
			return
		end
		
		uespLog.DebugMsg("UESP::Dumping set items for "..tradeskillName.."...")
	else
		uespLog.DebugMsg("UESP::Dumping items for "..tradeskillName.."...")
	end
		
	--GetSmithingImprovementItemInfo(CRAFTING_TYPE_BLACKSMITHING, luaindex improvementItemIndex)
		--Returns: string itemName, textureName icon, integer currentStack, integer sellPrice, bool meetsUsageRequirement, integer equipType, integer itemStyle, integer quality
	--local itemLink = GetSmithingImprovementItemLink(TradeskillType craftingSkillType, luaindex improvementItemIndex, LinkStyle linkStyle)
	--GetSmithingImprovedItemInfo(integer itemToImproveBagId, integer itemToImproveSlotIndex, TradeskillType craftingSkillType)
		--Returns: string itemName, textureName icon, integer sellPrice, bool meetsUsageRequirement, integer equipType, integer itemStyle, integer quality
	--local itemLink = GetSmithingImprovedItemLink(integer itemToImproveBagId, integer itemToImproveSlotIndex, TradeskillType craftingSkillType, LinkStyle linkStyle)

	--local itemLink = GetSmithingPatternMaterialItemLink(luaindex patternIndex, luaindex materialIndex, LINK_STYLE_DEFAULT)
	--local itemLink = GetSmithingPatternResultLink(luaindex patternIndex, luaindex materialIndex, integer materialQuantity, luaindex styleIndex, luaindex traitIndex, LINK_STYLE_DEFAULT)
	
	--local patternName, baseName, icon, numMaterials, numTraitsRequired, numTraitsKnown, resultItemFilterType = GetSmithingPatternInfo(2)
	--local itemLink = GetSmithingPatternResultLink(2, 1, 7, 1, 1, LINK_STYLE_DEFAULT)
	--local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
	--uespLog.DebugMsg("UESP::Num Materials = " .. tostring(numMaterials))
	--uespLog.DebugMsg("UESP::Item " .. tostring(itemNiceLink))
	--uespLog.DebugMsg("UESP::Item ID " .. tostring(itemId))	
	--uespLog.DebugMsg("UESP::Item Level " .. tostring(itemLevel))
	
	local itemCount = 0
	local logData = { }
	local maxItemCount = 10000
	local timeData = uespLog.GetTimeData()
	
	if true then
		--return
	end
	
	for patternIndex = startPattern, numPatterns do
		local patternName, baseName, icon, numMaterials, numTraitsRequired, numTraitsKnown, resultItemFilterType = GetSmithingPatternInfo(2)
		
		logData = { }
		local styleIndex = 1
		
		--for materialIndex = 1, numMaterials do
		materialIndex = 1
		
			for traitIndex = 1, numTraitItems do
			
				for materialQuantity = 3, 14 do
					local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, LINK_STYLE_DEFAULT)
				
					if (itemLink ~= "") then
						local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
						
						logData = { }
						
						logData.event = "ItemDump::Smith"
						logData.craftType = craftingType
						logData.itemLink = itemLink
						logData.itemId = itemId
						logData.level = itemLevel
						logData.itemName = itemNiceName
						logData.pattern = patternIndex
						logData.style = styleIndex
						logData.material = materialIndex
						logData.materialQnt = materialQuantity
						logData.trait = traitIndex
						
						uespLog.AppendDataToLog("all", logData, timeData)
						
						itemCount = itemCount + 1
						break
					end
				end
				
				if (itemCount > maxItemCount) then
					return
				end
				
			end
		--end
	end
	
	uespLog.DebugMsg("UESP::Output Items " .. tostring(itemCount))
end


SLASH_COMMANDS["/uespsmithtest"] = function (cmd)
	uespLog.DumpSmithItems(false)
end


SLASH_COMMANDS["/uespsmithsetdump"] = function (cmd)
	uespLog.DumpSmithItems(true)
end


SLASH_COMMANDS["/uespsmithinfo"] = function (cmd)
	local numPatterns = GetNumSmithingPatterns()
	local numStyles = GetNumSmithingStyleItems()
	local numImprovementItems = GetNumSmithingImprovementItems()
	local numTraitItems = GetNumSmithingTraitItems()
	local craftingType = GetCraftingInteractionType()
	local tradeskillName = uespLog.GetCraftingName(craftingType)
	
	uespLog.DebugMsg("UESP::Craft Type(" .. tostring(craftingType) .. ") = " .. tradeskillName)
	uespLog.DebugMsg("UESP::Num Patterns = " .. tostring(numPatterns))
	uespLog.DebugMsg("UESP::Num Styles = " .. tostring(numStyles))
	uespLog.DebugMsg("UESP::Num Improvements = " .. tostring(numImprovementItems))
	uespLog.DebugMsg("UESP::Num Traits = " .. tostring(numTraitItems))	
end


function uespLog.MakeItemLink(itemId, inputLevel, inputQuality)
	local itemLevel = inputLevel or 1
	local itemQuality = inputQuality or 1
	
	local itemLink = "|HFFFFFF:item:"..tostring(itemId)..":"..tostring(itemQuality)..":"..tostring(itemLevel)..":0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Item ".. tostring(itemId) .."]|h"
	return itemLink
end


SLASH_COMMANDS["/uespmakelink"] = function (cmd)
	local cmds = { }
	
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	
	local itemId = cmds[1]
	
	if (itemId == nil) then
		uespLog.Msg("UESP::Use the format: /uespmakelink [id] [level] [subtype]")
		return
	end
	
	local itemLink = uespLog.MakeItemLink(itemId, cmds[2], cmds[3])
	
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)

	if (icon == nil or icon == "" or icon == "") then
		uespLog.Msg("UESP::Item "..tostring(itemId).." is not valid!")
		return
	end
	
	uespLog.Msg("UESP::Created Item Link "..itemLink)
	
	uespLog.DebugExtraMsg("UESP::Icon "..tostring(icon))
	uespLog.DebugExtraMsg("UESP::Value "..tostring(sellPrice))
	uespLog.DebugExtraMsg("UESP::Equip Type "..tostring(equipType))
	uespLog.DebugExtraMsg("UESP::Item Style "..tostring(itemStyle))
	
	ZO_PopupTooltip_SetLink(itemLink)
	
	--ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemLink))
	--ZO_LinkHandler_InsertLink(itemLink)
end

SLASH_COMMANDS["/uml"] = SLASH_COMMANDS["/uespmakelink"]


function uespLog.DumpToolTip ()
	uespLog.DebugMsg("UESP::Dumping tooltip "..tostring(PopupTooltip))
	
	uespLog.printDumpObject = true
	--uespLog.DumpObject("PopupTooltip", getmetatable(PopupTooltip), 0, 2)
		
	--for k, v in pairs(PopupTooltip) do
		--uespLog.DebugMsg(".    " .. tostring(k) .. "=" .. tostring(v))
	--end
	
	local numChildren = PopupTooltip:GetNumChildren()
	uespLog.DebugMsg("UESP::Has "..tostring(numChildren).." children")
	
    for i = 1, numChildren do
        local child = PopupTooltip:GetChild(i)
		--uespLog.DumpObject("child", getmetatable(child), 0, 2)
		local name = child:GetName()
		uespLog.DebugMsg(".   "..tostring(i)..") "..tostring(name))
    end
	
	uespLog.printDumpObject = false
end


function uespLog.DumpItems()
	--	d("|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h test item")
	local itemLink = ""
	local startId = 1
	local endId = 100
	local logData = { }
	
	for itemId = startId, endId do
		itemLink = "|HFFFFF:item:"..itemId..":1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hUnknown|h"
		local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)

	end	
	
end

	
--if (uespLog.enableTesting) then
	--require "test/uespLog_test"
--end

--]]











