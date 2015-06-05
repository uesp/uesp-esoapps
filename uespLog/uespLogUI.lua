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

local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")

uespLog.SETTINGS_MENU_NAME = "uespLog Options"

uespLog.settingsPanelData = {
	type = "panel",
    name = uespLog.SETTINGS_MENU_NAME,
	displayName = "uespLog Options",
	author = "Dave Humphrey (dave@uesp.net)",
	version = uespLog.version,
	registerForRefresh = true,
	slashCommand = "/uespset",
}

uespLog.optionControlsData = { }


function uespLog.InitSettingsMenu()
	uespLog.InitOptionControlsData()

	LAM2:RegisterAddonPanel(uespLog.SETTINGS_MENU_NAME, uespLog.settingsPanelData)
	LAM2:RegisterOptionControls(uespLog.SETTINGS_MENU_NAME, uespLog.optionControlsData)
end


function uespLog.InitOptionControlsData()
	uespLog.optionControlsData = setmetatable({}, { __index = table })
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Log Data",
		tooltip = "Enable/disable the logging of data using the add-on\n     /uesplog on/off",
		getFunc = function() return uespLog.IsLogData() end,
		setFunc = function(flag) return uespLog.SetLogData(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Logging Output",
		choices = { "off", "on", "extra" },
		tooltip = "Set the console notification level for the add-on\n     /uespdebug on/off/extra",
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
		tooltip = "Enable/disable the use of colored console messages\n     /uespcolor on/off",
		getFunc = function() return uespLog.IsColor() end,
		setFunc = function(flag) return uespLog.SetColor(flag) end,
		disabled = function() return not uespLog.IsLogData() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Mail Delete Prompt",
		tooltip = "Enable/disable the prompt when deleting an in-game mail\n     /uespmail deletenotify on/off",
		getFunc = function() return uespLog.IsMailDeleteNotify() end,
		setFunc = function(flag) return uespLog.SetMailDeleteNotify(flag) end,
	})
	
	-- 		["mailDeleteNotify"] = false,

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
		name = "Item Style Display",
		tooltip = "Enable/disable the display of styles on items info\n     /uespcraft style on/off",
		getFunc = function() return uespLog.IsCraftStyleDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftStyleDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Item Trait Display",
		tooltip = "Enable/disable the display of traits on items info\n     /uespcraft trait on/off",
		getFunc = function() return uespLog.IsCraftTraitDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftTraitDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Recipe Display",
		tooltip = "Enable/disable the display of traits on items info\n     /uespcraft recipe on/off",
		getFunc = function() return uespLog.IsCraftRecipeDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftRecipeDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Ingredient Display",
		tooltip = "Enable/disable the display of traits on items info\n     /uespcraft ingredient on/off",
		getFunc = function() return uespLog.IsCraftIngredientDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftIngredientDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
		getFunc = function() return uespLog.GetSettingsCraftInfoText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Autoloot",
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Custom Autoloot",
		tooltip = "Enable/disable the use of custom autolooting\n     /uespcraft autoloot on/off",
		getFunc = function() return uespLog.IsCraftAutoLoot() end,
		setFunc = function(flag) return not uespLog.SetCraftAutoLoot(flag) end,
	})
	
	uespLog.optionControlsData:insert({
		type = "dropdown",
		name = "Autoloot Min Prov Level",
		choices = { "1", "2", "3", "4", "5" },
		tooltip = "Set the lowest level of provision items that will be autolooted\n     /uespcraft minprovlevel [1-5]",
		getFunc = function() return uespLog.GetCraftAutoLootMinProvLevel() end,
		setFunc = function(choice) return uespLog.SetCraftAutoLootMinProvLevel(choice) end,
		disabled = function() return not uespLog.IsCraftAutoLoot() end,
	})
		
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Statistics",
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
		getFunc = function() return uespLog.GetSettingsStatisticText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "header",
		name = "Time",
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
		getFunc = function() return uespLog.GetSettingsTimeText() end,
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
		title = "",
		text = "",
	})
	
	uespLog.optionControlsData:insert({
		type = "description",
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
	OutputText = OutputText .. "     Player Location = " .. tostring(posString) .. ", " .. tostring(headingStr) .. " deg\n"
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
	local TradeskillName = uespLog.GetCraftingName(craftingType)
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
				
				OutputText = OutputText .. "     " .. tostring(TradeskillName) .. " " .. tostring(name) .. " (" .. tostring(traitName) .. ") has " .. tostring(timeFmt) .. " left.\n"
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