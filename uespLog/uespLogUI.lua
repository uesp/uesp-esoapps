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
	LAM2:RegisterWidget("uespdescription", 5)
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
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "PVP Update",
		tooltip = "Show PVP/campaign updates in the chat window\n     /uesppvp on/off",
		getFunc = function() return uespLog.IsPvpUpdate() end,
		setFunc = function(flag) return uespLog.SetPvpUpdate(flag) end,
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
		tooltip = "Enable/disable the display of known/unknown on recipes\n     /uespcraft recipe on/off",
		getFunc = function() return uespLog.IsCraftRecipeDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftRecipeDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "checkbox",
		name = "Ingredient Display",
		tooltip = "Enable/disable the display of ingredient information\n     /uespcraft ingredient on/off",
		getFunc = function() return uespLog.IsCraftIngredientDisplay() end,
		setFunc = function(flag) return uespLog.SetCraftIngredientDisplay(flag) end,
		disabled = function() return not uespLog.IsCraftDisplay() end
	})
	
	uespLog.optionControlsData:insert({
		type = "uespdescription",
		title = "",
		text = "",
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
		text = "",
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
		text = "",
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
		text = "",
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
	local softCap = GetStatSoftCap(statType)
	local currentStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
	local noCapStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_DONT_APPLY_SOFT_CAP)
	local OutputText = ""
	
	if (softCap == nil) then
		OutputText = tostring(statName)..": "..tostring(currentStat).." (no cap)"
	else
		OutputText = tostring(statName)..": "..tostring(currentStat).." ("..tostring(noCapStat).." with cap of ".. tostring(softCap)..")"
	end
	
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