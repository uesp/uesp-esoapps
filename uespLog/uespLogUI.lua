-- uespLogUI.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the user interface portion of the add-on

-- 		["totalInspiration"] = 0,
-- 		["mailDeleteNotify"] = false,
-- 		["mineItemsAutoNextItemId"] = 1,
-- 		["mineItemAutoReload"] = false,
-- 		["mineItemAutoRestart"] = false,
-- 		["mineItemsEnabled"] = false,
-- 		["mineItemOnlySubType"] = -1,
-- 		["isAutoMiningItems"] = false,

local LAM2 = LibAddonMenu2

uespLog.settingsPanelData = {
	type = "panel",
    name = "uespLog",
	displayName = "uespLog",
	author = "Dave Humphrey (dave@uesp.net)",
	version = uespLog.version,
	registerForRefresh = true,
	slashCommand = "/uespset",
}

uespLog.optionControlsData = { }


function uespLog.InitSettingsMenu()
	LAM2:RegisterWidget("uespdescription", 6)
	uespLog.InitOptionControlsData()

	LAM2:RegisterAddonPanel("uespLog_LAM", uespLog.settingsPanelData)
	LAM2:RegisterOptionControls("uespLog_LAM", uespLog.optionControlsData)
end


function uespLog.InitOptionControlsData()
	uespLog.optionControlsData = setmetatable({}, { __index = table })
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Log Data",
		tooltip = "Enable/disable the logging of data using the add-on.\n     /uesplog on/off",
		getFunc = function() return uespLog.IsLogData() end,
		setFunc = function(flag) return uespLog.SetLogData(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Logging Output",
		choices = { "off", "on", "extra" },
		tooltip = "Set the console notification level for the add-on's debug messages.\n     /uespdebug on/off/extra",
		getFunc = 	function() 
						if (uespLog.IsDebugExtra() and uespLog.IsDebug) then return "extra" end
						if (uespLog.IsDebug()) then return "on" end
						return "off"
					end,
		setFunc = 	function(choice) 
						if (choice == "on") then 
							uespLog.SetDebug(true) 
							uespLog.SetDebugExtra(false) 
						elseif (choice == "extra") then 
							uespLog.SetDebug(true) 
							uespLog.SetDebugExtra(true)
						else
							uespLog.SetDebug(false) 
							uespLog.SetDebugExtra(false)
						end
					end,
		disabled = function() return not uespLog.IsLogData() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Use Color",
		tooltip = "Enable/disable the use of colored console messages.\n     /uespcolor on/off",
		getFunc = function() return uespLog.IsColor() end,
		setFunc = function(flag) return uespLog.SetColor(flag) end,
		disabled = function() return not uespLog.IsLogData() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Mail Delete Prompt",
		tooltip = "Enable/disable the prompt when deleting an in-game mail.\n     /uespmail deletenotify on/off",
		getFunc = function() return uespLog.IsMailDeleteNotify() end,
		setFunc = function(flag) return uespLog.SetMailDeleteNotify(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "PVP Update",
		tooltip = "Show PVP/campaign updates in the chat window.\n     /uesppvp on/off",
		getFunc = function() return uespLog.IsPvpUpdate() end,
		setFunc = function(flag) return uespLog.SetPvpUpdate(flag) end,
	})
		
	--uespLog.optionControlsData:insert({
		--type = "checkbox",
		--name = "Show All Lorebooks",
		--tooltip = "Show all non-guild lore book 'learned' messages.\n     /uesplorebook on/off",
		--getFunc = function() return uespLog.GetLoreBookMsgFlag() end,
		--setFunc = function(flag) return uespLog.SetLoreBookMsgFlag(flag) end,
	--})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Map Coordinates", 
		tooltip = "Shows coordinates of a point on map the cursor is over. Disable if using another addon for coordinates.\n      /uespshowcoor on/off", 
		getFunc = uespLog.GetShowCursorMapCoordsFlag,
		setFunc = uespLog.SetShowCursorMapCoordsFlag,
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Inventory Container Autoloot", 
		tooltip = "When enabled you will autoloot containers you open in your inventory.\n      /uespcontloot on/off", 
		getFunc = uespLog.GetContainerAutoLoot,
		setFunc = uespLog.SetContainerAutoLoot,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Show Custom Stats", 
		choices = { "off", "on", "custom" },
		tooltip = "Enables the display of extra stats in the character and inventory windows.\n      /uespcustomstats on/off", 
		warning = "Requires the UI to be reloaded to take effect.",
		
		getFunc = 	function() 
						if (uespLog.GetInventoryStatsConfig() == "custom") then return "custom" end
						return uespLog.GetCustomStatDisplay()
					end,
		setFunc = 	function(choice) 
						if (choice == "custom") then 
							uespLog.SetInventoryStatsConfig("custom")
							
							if (uespLog.GetInventoryStatsConfig() == "off") then
								uespLog.SetInventoryStatsConfig("on")
								uespLog.ModifyInventoryStatsWindow()
							end
						elseif (choice == "on" or choice == true) then
							uespLog.SetCustomStatDisplay(true)
							
							if (uespLog.GetInventoryStatsConfig() == "off") then
								uespLog.SetInventoryStatsConfig("on")
								uespLog.ModifyInventoryStatsWindow()
							end
						else
							uespLog.SetCustomStatDisplay(false)
							
							if (uespLog.GetInventoryStatsConfig() ~= "off") then
								uespLog.SetInventoryStatsConfig("off")
								--uespLog.ModifyInventoryStatsWindow()
							end
						end
					end,
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Loot Messages", 
		tooltip = "Enables the display of all loot related messages in the chat window.\n      /uespmsg loot on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_LOOT) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_LOOT, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Quest Messages", 
		tooltip = "Enables the display of all quest related messages in the chat window.\n      /uespmsg quest on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_QUEST) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_QUEST, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show NPC Messages", 
		tooltip = "Enables the display of all NPC related messages in the chat window.\n      /uespmsg npc on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_NPC) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_NPC, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Experience Messages", 
		tooltip = "Enables the display of all experience related messages in the chat window.\n      /uespmsg xp on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_XP) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_XP, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Inspiration Messages", 
		tooltip = "Enables the display of all crafting inspiration  related messages in the chat window.\n      /uespmsg inspiration on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_INSPIRATION) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_INSPIRATION, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Show Other Messages", 
		tooltip = "Enables the display of other messages in the chat window.\n      /uespmsg other on/off", 
		getFunc = function () return uespLog.GetMessageDisplay(uespLog.MSG_MISC) end,
		setFunc = function (value) uespLog.SetMessageDisplay(uespLog.MSG_MISC, value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Keep Chat Open", 
		tooltip = "Keeps the chat window open all the time when entering trade, crown store, and other windows.\n", 
		getFunc = function () return uespLog.GetKeepChatOpen()  end,
		setFunc = function (value) uespLog.SetKeepChatOpen(value) uespLog.UpdateKeepChatOpen() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Play Nirncrux Sound", 
		tooltip = "Plays a sound when you loot a Potent or Fortified Nirncrux.\n      /uespnirnsound on/off", 
		getFunc = function () return uespLog.GetNirnSound() end,
		setFunc = function (value) uespLog.SetNirnSound(value) end
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Guild Sales Data (Beta)",
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Log Guild Sales", 
		tooltip = "Logs various sources of guild sales data.\n      /uespsales on/off", 
		getFunc = function () return uespLog.IsSalesDataSave() end,
		setFunc = function (value) uespLog.SetSalesDataSave(value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Use UESP Price Data", 
		tooltip = "Enables/disables the usage of UESP price data.\n      /uespsales prices on/off", 
		warning = "Requires the UI to be reloaded to take effect.",
		getFunc = function () return uespLog.IsSalesShowPrices() end,
		setFunc = function (value) uespLog.SetSalesShowPrices(value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Price Item Tooltips", 
		tooltip = "Show UESP specific price info on item tooltips.\n      /uespsales tooltip on/off", 
		getFunc = function () return uespLog.IsSalesShowTooltip() end,
		setFunc = function (value) uespLog.SetSalesShowTooltip(value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Price Display Type", 
		choices = { "both", "list", "sold" },
		tooltip = "Select the type of data to use for price displays.\n      /uespsales saletype both/list/sold", 
		getFunc = function () return uespLog.GetSalesShowSaleType() end,
		setFunc = function (value) uespLog.SetSalesShowSaleType(value) end
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Deal Display Type", 
		choices = { "uesp", "mm", "none" },
		tooltip = "Selects which price data to use for showing deals in guild listings.\n      /uespsales deal uesp/mm/none", 
		getFunc = function () return uespLog.GetSalesShowDealType() end,
		setFunc = function (value) uespLog.SetSalesShowDealType(value) end
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Crafting",
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Craft/Item Display",
		tooltip = "Enable/disable the display of all crafting/item info\n     /uespcraft on/off",
		getFunc = function() return uespLog.IsCraftDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftDisplay(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Alchemy Tooltip Display",
		tooltip = "Enable/disable the display of tooltips in the alchemy crafting window\n     /uespcraft alchemy on/off",
		getFunc = function() return uespLog.GetCraftAlchemyTooltipDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftAlchemyTooltipDisplay(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		choices = { "none", "tooltip", "inventory", "both" },
		name = "Item Style Display",
		tooltip = "Enable/disable the display of styles on items info\n     /uespcraft style ...",
		getFunc = function() return uespLog.GetCraftStyleDisplay() end,
		setFunc = function(value) return uespLog.SetCraftStyleDisplay(value) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		choices = { "none", "tooltip", "inventory", "both" },
		name = "Trait Known Display",
		tooltip = "Enable/disable the display of traits on items info\n     /uespcraft trait ...",
		getFunc = function() return uespLog.GetCraftTraitDisplay() end,
		setFunc = function(value) return uespLog.SetCraftTraitDisplay(value) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Trait Icon Display",
		tooltip = "Enable/disable the display of intricate/ornate icons in the inventory window\n     /uespcraft traiticon on/off",
		getFunc = function() return uespLog.GetShowTraitIcon() end,
		setFunc = function(value) return uespLog.SetShowTraitIcon(value) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		choices = { "none", "tooltip", "inventory", "both" },
		name = "Recipe Display",
		tooltip = "Enable/disable the display of known/unknown on recipes\n     /uespcraft recipe on/off",
		getFunc = function() return uespLog.GetCraftRecipeDisplay() end,
		setFunc = function(value) return uespLog.SetCraftRecipeDisplay(value) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		choices = { "none", "tooltip", "inventory", "both" },
		name = "Ingredient Display",
		tooltip = "Enable/disable the display of ingredient information\n     /uespcraft ingredient on/off",
		getFunc = function() return uespLog.GetCraftIngredientDisplay() end,
		setFunc = function(value) return uespLog.SetCraftIngredientDisplay(value) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Include Set Items in Research",
		tooltip = "Include or exclude set items in smithing research listings\n     /uespresearch includesets on/off",
		getFunc = function() return uespLog.GetIncludeSetItemsForTraitResearch() end,
		setFunc = function(flag) return uespLog.SetIncludeSetItemsForTraitResearch(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		choices = { 0, 1, 2, 3, 4, 5 },
		name = "Max Quality for Item Research",
		tooltip = "Sets the max quality for items to show for smithing research listings\n     /uespresearch maxquality [value]",
		getFunc = function() return uespLog.GetMaxQualityForTraitResearch() end,
		setFunc = function(value) return uespLog.SetMaxQualityForTraitResearch(value) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Autoloot Hireling Mails",
		tooltip = "Turn the automatic looting of mails from Hirelings on and off\n      /uesphireling autoloot [on||off]",
		getFunc = function() return uespLog.GetAutoLootHirelingMails() end,
		setFunc = function(value) return uespLog.SetAutoLootHirelingMails(value) end,
	})	
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = uespLog.GetSettingsCraftInfoText(),
		getFunc = function() return uespLog.GetSettingsCraftInfoText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Statistics",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = uespLog.GetSettingsStatisticText(),
		getFunc = function() return uespLog.GetSettingsStatisticText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Time",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text =  uespLog.GetSettingsTimeText(),
		getFunc = function() return uespLog.GetSettingsTimeText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Character Information",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = uespLog.GetCharInfoText(),
		getFunc = function() return uespLog.GetCharInfoText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
		
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})

	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})

	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Reset Logs",
	})
		
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Log",
		tooltip = "Clear the normal logged data currently in memory\n     /uespreset log",
		func = function() SLASH_COMMANDS["/uespreset"]("log") end
	})
	
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Global Log",
		tooltip = "Clear the global data log\n     /uespreset globals",
		func = function() SLASH_COMMANDS["/uespreset"]("globals") end
	})
	
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Achievements Log",
		tooltip = "Clear the achievement data log\n     /uespreset achievements",
		func = function() SLASH_COMMANDS["/uespreset"]("globals") end
	})
	
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Character Data",
		tooltip = "Clear the saved character data currently in memory\n     /uespreset chardata",
		func = function() SLASH_COMMANDS["/uespreset"]("chardata") end
	})
	
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Build Data",
		tooltip = "Clear the saved build data currently in memory\n     /uespreset builddata",
		func = function() SLASH_COMMANDS["/uespreset"]("builddata") end
	})
	
	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset Temp Data",
		tooltip = "Clear the temporary ata currently in memory\n     /uespreset temp",
		func = function() SLASH_COMMANDS["/uespreset"]("temp") end
	})

	uespLog.optionControlsData:insert({
		type = "button",
		name = "Reset All Logs",
		tooltip = "Clear all logged data\n     /uespreset all",
		func = function() SLASH_COMMANDS["/uespreset"]("globals") end
	})
		
end


function uespLog.GetSettingsStatisticText()
	local count1, size1 = uespLog.GetSectionCounts("all")
	local count2, size2 = uespLog.GetSectionCounts("globals")
	local count3, size3 = uespLog.GetSectionCounts("achievements")
	local count = count1 + count2 + count3
	local size = size1 + size2 + size3
	local achCount, achCompleteCount = uespLog.GetAchievementCounts()
	local timeStamp = GetTimeStamp()
	local x, y, heading, zone = GetMapPlayerPosition("player")
	local headingStr = string.format("%.2f", heading*57.29582791)
	local cameraHeading = GetPlayerCameraHeading()
	local camHeadingStr = string.format("%.2f", cameraHeading*57.29582791)
	local version = _VERSION
	local apiVersion = GetAPIVersion()
	local posData = uespLog.GetPlayerPositionData()
	local x, y, heading, zone = GetMapPlayerPosition("player")
	local posString = string.format(" %.4f, %.4f, %s", posData.x, posData.y, posData.zone)
	local OutputText = ""
	
	OutputText = OutputText .. "     " .. tostring(count) .. " log records taking up " .. string.format("%.2f", size/1000000) .. " MB\n"
	OutputText = OutputText .. "          Log: " .. tostring(count1) .. " records taking up " .. string.format("%.2f", size1/1000000) .. " MB\n"
	OutputText = OutputText .. "          Global: " .. tostring(count2) .. " records taking up " .. string.format("%.2f", size2/1000000) .. " MB\n"
	OutputText = OutputText .. "          Achievement: " .. tostring(count3) .. " records taking up " .. string.format("%.2f", size3/1000000) .. " MB\n"
	OutputText = OutputText .. "     " .. tostring(achCompleteCount) .. " / " .. tostring(achCount) .. " achievements complete\n"
	OutputText = OutputText .. "     Location = " .. tostring(posString) .. ", " .. tostring(headingStr) .. " deg\n"
	OutputText = OutputText .. "     Camera Heading = " .. tostring(camHeadingStr) .. " degrees\n"
	OutputText = OutputText .. "     Game _VERSION = "  .. version .. "\n"
	OutputText = OutputText .. "     Game API = " .. tostring(apiVersion) .. "\n"
	
	return OutputText
end


function uespLog.GetSettingsTimeText()
	local timeStamp = GetTimeStamp()
	local localGameTime = GetGameTimeMilliseconds()
	local timeStampStr = Id64ToString(timeStamp)
	local timeStampFmt = GetDateStringFromTimestamp(timeStamp)
	local gameTimeStr = uespLog.getGameTimeStr(timeStamp, false)
	local moonPhaseStr = uespLog.getMoonPhaseStr(timeStamp, false)
	local OutputText = ""
	
	OutputText = OutputText .. "     Game Time = " .. gameTimeStr .. "\n"
	OutputText = OutputText .. "     Moon Phase = " .. moonPhaseStr .. "\n"
	OutputText = OutputText .. "     Local Game Time = " .. tostring(localGameTime/1000) .. " sec\n"
	OutputText = OutputText .. "     Time Stamp = " .. tostring(timeStamp) .. "\n"
	OutputText = OutputText .. "     Time Stamp Date = " .. timeStampFmt .. "\n"
	OutputText = OutputText .. "     Time Stamp Raw = " .. timeStampStr .. "\n"
	OutputText = OutputText .. "     Game Time Day Length = " .. tostring(uespLog.DEFAULT_REALSECONDSPERGAMEDAY) .. " secs\n"
	OutputText = OutputText .. "     Game Time Real Offset = " .. tostring(uespLog.GAMETIME_REALSECONDS_OFFSET) .. " secs\n"
	OutputText = OutputText .. "     Game Time Day Offset = " .. tostring(uespLog.GAMETIME_DAY_OFFSET) .. " days\n"
	
	return OutputText
end


function uespLog.GetSettingsResearchInfoCraftText(craftingType)
	local TradeskillName = uespLog.GetShortCraftingName(craftingType)
	local numLines = GetNumSmithingResearchLines(craftingType)
	local maxSimultaneousResearch = GetMaxSimultaneousSmithingResearch(craftingType)
	local researchCount = 0
	local OutputText = ""
	
	if (numLines == 0 or maxSimultaneousResearch == 0) then
		return TradeskillName .. " doesn't have any research lines available!"
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
				
				OutputText = OutputText .. "     " .. tostring(TradeskillName) .. " " .. tostring(name) .. "::" .. tostring(traitName) .. ": " .. tostring(timeFmt) .. " left.\n"
				researchCount = researchCount + 1
			end
		end
	end
	
	if (researchCount < maxSimultaneousResearch) then
		local slotsOpen = maxSimultaneousResearch - researchCount
		OutputText = OutputText .. "     " .. tostring(TradeskillName) .. " has " .. tostring(slotsOpen) .. " research slots available.\n"
	end
	
	return OutputText
end


function uespLog.GetSettingsCraftInfoText()
	local recipeCount, knownRecipeCount = uespLog.GetRecipeCounts()
	local bsTraits, bsTraitsKnown = uespLog.GetTraitCounts(CRAFTING_TYPE_BLACKSMITHING)
	local clTraits, clTraitsKnown = uespLog.GetTraitCounts(CRAFTING_TYPE_CLOTHIER)
	local wwTraits, wwTraitsKnown = uespLog.GetTraitCounts(CRAFTING_TYPE_WOODWORKING)	
	local OutputText = ""
	
	OutputText = OutputText .. uespLog.GetSettingsResearchInfoCraftText(CRAFTING_TYPE_BLACKSMITHING)
	OutputText = OutputText .. uespLog.GetSettingsResearchInfoCraftText(CRAFTING_TYPE_CLOTHIER)
	OutputText = OutputText .. uespLog.GetSettingsResearchInfoCraftText(CRAFTING_TYPE_WOODWORKING)
	
	OutputText = OutputText .. "     " .. tostring(knownRecipeCount) .. " / " .. tostring(recipeCount) .. " recipes known\n"
	OutputText = OutputText .. "     " .. tostring(bsTraitsKnown) .. " / " .. tostring(bsTraits) .. " BlackSmith traits known\n"
	OutputText = OutputText .. "     " .. tostring(clTraitsKnown) .. " / " .. tostring(clTraits) .. " Clothier traits known\n"
	OutputText = OutputText .. "     " .. tostring(wwTraitsKnown) .. " / " .. tostring(wwTraits) .. " WoodWorking traits known\n"
	
	OutputText = OutputText .. "     " .. tostring(uespLog.GetTotalInspiration()) .. " crafting inspiration since the last reset\n"
	
	return OutputText
end


function uespLog.GetStatText (statType, statName)
	local currentStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
	--local noCapStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_DONT_APPLY_SOFT_CAP)
	local OutputText = ""
	
	OutputText = tostring(statName)..": "..tostring(currentStat).." (no cap)"
		
	return OutputText
end


function uespLog.GetPowerStatText(statType, statName)
	local currentStat, maxValue, effectiveMax = GetUnitPower("player", statType)
	return tostring(statName)..": "..tostring(currentStat).." (effective max "..tostring(effectiveMax).." of ".. tostring(maxValue)..")"
end


function uespLog.GetCharInfoText()
	local numPoints = GetAvailableSkillPoints()
	local numSkyShards = GetNumSkyShards()
	local OutputText = ""
	
	OutputText = OutputText .. "     Skill Points: " .. tostring(numPoints) .. "\n"
	OutputText = OutputText .. "     Skyshards: " .. tostring(numSkyShards) .. "\n"
		
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_HEALTH_MAX, "HP") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_MAGICKA_MAX, "Magicka") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_STAMINA_MAX, "Stamina") .. "\n"
	
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_HEALTH_REGEN_COMBAT, "HP Combat Regen") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_MAGICKA_REGEN_COMBAT, "Magicka Combat Regen") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_STAMINA_REGEN_COMBAT, "Stamina Combat Regen") .. "\n"
	
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_HEALTH_REGEN_IDLE, "HP Idle Regen") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_MAGICKA_REGEN_IDLE, "Magicka Idle Regen") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_STAMINA_REGEN_IDLE, "Stamina Idle Regen") .. "\n"
	
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_ARMOR_RATING, "Armor") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_BLOCK, "Block") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_CRITICAL_RESISTANCE, "Critical Resist") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_SPELL_RESIST, "Spell Resist") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_SPELL_MITIGATION, "Spell Mitigation") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DODGE, "Dodge") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_PARRY, "Parry") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_PHYSICAL_RESIST, "Physical Resist") .. "\n"
	
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_COLD, "Resist Cold") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_DISEASE, "Resist Disease") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_DROWN, "Resist Drown") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_EARTH, "Resist Earth") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_FIRE, "Resist Fire") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_GENERIC, "Resist Generic") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_MAGIC, "Resist Magic") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_OBLIVION, "Resist Oblivion") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_PHYSICAL, "Resist Physical") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_POISON, "Resist Poison") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_SHOCK, "Resist Shock") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_DAMAGE_RESIST_START, "Resist Start") .. "\n"
		
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_CRITICAL_STRIKE, "Critical Strike") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_WEAPON_POWER, "Weapon Power") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_SPELL_POWER, "Spell Power") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_SPELL_CRITICAL, "Spell Critical") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_SPELL_PENETRATION, "Spell Penetration") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_POWER, "Power") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_ATTACK_POWER, "Attack Power") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_MISS, "Miss") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetStatText(STAT_PHYSICAL_PENETRATION, "Physical Penetration") .. "\n"
	
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_HEALTH, "HP") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_MAGICKA, "Magicka") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_STAMINA, "Stamina") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_ULTIMATE, "Ultimate") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_FINESSE, "Finesse") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_WEREWOLF, "Werewolf") .. "\n"
	OutputText = OutputText .. "     " .. uespLog.GetPowerStatText(POWERTYPE_MOUNT_STAMINA, "Mount Stamina") .. "\n"
		
	return OutputText
end


function uespLog_CopyItemLinkDialog_OnNext()
end