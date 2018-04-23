-- uespLogDaily.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to daily quest tracking.

--"Critical Mass"/"Masse critique"/"Kritische Masse"
--"Supreme Power"/"Puissance supérieure"/"Unbeschreibliche Macht"
--"The Fallen City of Shada"/"La cité perdue de Shada"/"Die gefallene Stadt Shada"
--"The Seeker's Archive"/"L'Archive des Sourciers"/"Das Archiv des Suchers"
--"The Trials of Rahni'Za"/"Les épreuves de Rahni'Za"/"Die Prüfungen von Rahni'Za"

--"Iron and Scales"/"Fer et écailles"/"Eisen und Schuppen"
--"Souls of the Betrayed"/"Les âmes des trahis"/"Die Seelen der Verratenen"
--"Taken Alive"/"Capturés vivants"/"Lebendig gefangen"
--"The Blood of Nirn"/"Le sang de Nirn"/"Das Blut Nirns"
--"The Gray Passage"/"Passage gris"/"Der Graue Lauf"
--"The Truer Fangs"/"Les crocs ajustés"/"Die wahren Giftzähne"
--"Uncaged"/"Libéré"/"Entfesselt"

--Breakfast of the Bizarre: Complete a contract for the Dragonstar Caravan Company.
--Fire in the Hold: Deal with the bandits in Watcher's Hold for the Dragonstar Caravan Company.
--Free Spirits: Set free the spirits trapped by the evil sorcerer, Gorlar the Dark.
--Getting a Bellyful: Obtain special durzog feed for a client for the Dragonstar Caravan Company.
--Heresy of Ignorance: Stop the Worm Cult from summoning a terrible champion.
--Nature's Bounty: Cleanse the corruption that is blighting the Wrothgar wilderness.
--Parts of the Whole: Collect data on the constructs of Zthenganaz.
--Meat for the Masses: Get supplies for the workers rebuilding Orsinium.
--Reeking of Foul Play: Deal with the Riekrs who are raiding caravans.
--Scholarly Salvage: Deal with a threat in Wrothgar's wilderness.
--Snow and Steam: Deal with some dangerous Dwarven machines.
--The Skin Trade: Complete a contract for the Dragonstar Caravan Company.


uespLog.DAILY_QUESTS = 
{

	["Clockwork City"] = 
	{
		["Bursar of Tributes"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"A Matter of Leisure",
				"A Matter of Respect",
				"A Matter of Tributes",
				"Glitter and Gleam",
				"Nibbles and Bits",
				"Morsels and Pecks",
			},
		},
		
		["Razgurug"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Enchanted Accumulation",
				"A Bitter Pill",
				"Fuel for our Fires",
				"A Daily Grind",
				"Loose Strands",
				"A Sticky Solution",
			},
		},
		
		["Clockwork Facilitator"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Inciting the Imperfect",
				"A Fine-Feathered Foe",
			},
		},
		
		["Novice Holli"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Replacing the Commutators",
				"The Shadow Cleft",
				"Again Into the Shadows",
				"A Shadow Malfunction",
				"Changing the Filters",
				"Oiling the Fans",
				"A Shadow Misplaced",
			},
		},
	},

	["Morrowind"] = 
	{
		["Traylan Omoril"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Daedric Disruptions",
				"Kwama Conundrum",
				"Planting Misinformation",
				"Tax Deduction",
				"Tribal Troubles",
				"Unsettled Syndicate",
			},
		},
		
		["Beleru Omoril"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"The Anxious Apprentice",
				"A Creeping Hunger",
				"Culling the Swarm",
				"Oxen Free",
				"Salothan's Curse",
				"Siren's Song",
			},
		},
		
		["Numani-Rasi"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Relics of Ashurnabitashpi",
				"Relics of Ebernanit",
				"Relics of Yasammidan",
				"Relics of Assarnatamat",
				"Relics of Dushariran",
				"Relics of Ashalmawia",
				"Relics of Maelkashishi",
			},
		},
		
		["Huntmaster Sorim-Nakar"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Mother Jagged-Claw Hunt",
				"Ash-Eater Hunt",
				"Tarra-Suj Hunt",
				"Writhing Sveeth Hunt",
				"Old Stomper Hunt",
				"King Razor-Tusk Hunt",
				"Great Zexxin Hunt",
			},
		},
	},

	["Gold Coast"] = 
	{
		["Kvatch Bounty Board"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Looming Shadows",
				"The Roar of the Crowds",
			},
		},
		
		["Anvil Bounty Board"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"The Common Good",
				"Buried Evil",
			},
		},
	},
	
	["Hew's Bane"] = 
	{
		["Heists"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Heist: Deadhollow Halls",
				"Heist: Glittering Grotto",
				"Heist: The Hideaway",
				"Heist: Underground Sepulcher",
				"Heist: Secluded Sewers",
			},
		},
		
		["Reacquisition Board"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Thrall Cove",
				"Memories of Youth",
				"The Sailor's Pipe",
				"The Lost Pearls",
			},
		},
	},
	
	["Wrothgar"] = 
	{
		["World Boss"] = 
		{
			["maxCount"] = -1,
			["quests"] = 
			{
				"Snow and Steam",
				"Heresy of Ignorance",
				"Nature's Bounty",
				"Meat for the Masses",
				"Reeking of Foul Play",
				"Scholarly Salvage",
			},
		},
		
		["Dungeon"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Breakfast of the Bizarre",
				"Getting a Bellyful",
				"Fire in the Hold",
				"Free Spirits",
				"The Skin Trade",
				"Parts of the Whole",				
			},
		},
	},
	
	["Craglorn"] = 
	{
		["maxCount"] = -1,
		["quests"] = 
		{
			"Critical Mass",
			"Supreme Power",
			"The Fallen City of Shada",
			"The Seeker's Archive",
			"The Trials of Rahni'Za",
		},
	},
	
	["Crafting"] = 
	{
		["maxCount"] = -1,
		["quests"] = 
		{
			"Alchemist Writ",
			"Blacksmith Writ",
			"Clothier Writ",
			"Enchanter Writ",
			"Jewelry Crafting Writ",	-- TODO18
			"Provisioner Writ",
			"Woodworker Writ",
		},
	},
	
	["Cyrodiil"] = 
	{
		["Chorrol"] = -- Lliae the Quick
		{
			["maxCount"] = 5,
			["quests"] = 
			{
				"Death to the Black Daggers!",
				"Guard Work is Never Done",
				"Field of Fire",
				"The High Cost of Lying",
				"The Cache",
			},
		},
		["Weynon Priory"] =  -- Mael
		{
			["maxCount"] = 5,
			["quests"] = 
			{
				"Abominations",
				"Black Dagger Supplies",
				"Claw of Akatosh",
				"Overdue Supplies",
				"The Lich",
			},
		},
		["Rathisa the Ripper"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Shipping Manifest"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Zimar"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Nirnroot Wine",
			},
		},
		["Doctor's Bag"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Rasha"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Sands of Sentinel",
				-- More?
			},
		},
		["Bruma:Grigerda"] = 
		{
			["maxCount"] = 5,
			["quests"] = 
			{
				"Bring Down the Magister",
				"Know thy Enemy",
				"Requests for Aid",
				"Timely Intervention",
				"The Unseen",
			},
		},
		["Bruma:Hjorik"] = 
		{
			["maxCount"] = 5,
			["quests"] = 
			{
				"Capstone Caps",
				"Dangerously Low",
				"Enemy Reinforcements",
				"Lost and Alone",
				"The Standing Stones",
			},
		},
		["Mansa"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Catch of the Day",
			},
		},
		["Wet Bag"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Tertius Falto"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Krodak"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Note"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Crate"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
			},
		},
		["Sylvain Quintin"] = 
		{
			["maxCount"] = 1,
			["quests"] = 
			{
				"Special Delivery",
			},
		},
		["Cheydinhal:Sylvain Herius"] = 
		{
			["maxCount"] = 5,
			["quests"] = 
			{
			},
		},
		["Cheydinhal:Vyctoria Girien"] = 
		{
			["maxCount"] = 5,
			["quests"] = 
			{
			},
		},
		-- More single quests?
	},

}


	-- Assume a 2am reset time (do we need a time zone offset?)
uespLog.DAILYQUEST_RESETOFFSET = 60*60*2


uespLog.DAILYQUEST_GROUPS = 
{
	["craft"] = "Crafting",
	["crafts"] = "Crafting",
	["crafting"] = "Crafting",
	["writ"] = "Crafting",
	["writs"] = "Crafting",
	
	["craglorn"] = "Craglorn",
	["crag"] = "Craglorn",
	
	["cyrodiil"] = "Cyrodiil",
	["cyrodil"] = "Cyrodiil",
	["cyro"] = "Cyrodiil",
	["pvp"] = "Cyrodiil",
	
	["wrothgar"] = "Wrothgar",
	["wroth"] = "Wrothgar",
	["orsinium"] = "Wrothgar",
	["ors"] = "Wrothgar",
	["orsi"] = "Wrothgar",
	
	["hewsbane"] = "Hew's Bane",
	["hews"] = "Hew's Bane",
	["thievesguild"] = "Hew's Bane",
	["tg"] = "Hew's Bane",
	["thieves"] = "Hew's Bane",
	
	["goldcoast"] = "Gold Coast",
	["gold"] = "Gold Coast",
	["darkbrotherhood"] = "Gold Coast",
	["db"] = "Gold Coast",
	
	["morrowind"] = "Morrowind",
	["morrow"] = "Morrowind",
	["mw"] = "Morrowind",
	["vvardenfell"] = "Morrowind",
	
	["clockworkcity"] = "Clockwork City",
	["clockwork"] = "Clockwork City",
	["cwc"] = "Clockwork City",
}


-- /uespdaily 
-- /uespdaily craft
-- /uespdaily craglorn
-- /uespdaily cyrodiil
-- /uespdaily wrothgar
-- /uespdaily hewsbane
-- /uespdaily all
-- /uespdaily done
-- /uespdaily notdone
-- /uespdaily timeleft
function uespLog.DailyCommand(cmd)
	local cmds, firstCmd = uespLog.SplitCommands(cmd)
	local groupName = uespLog.DAILYQUEST_GROUPS[firstCmd]
	
	if (groupName ~= nil) then
		uespLog.Msg("Showing daily quests for "..tostring(groupName)..":")
		uespLog.ShowDailyQuestStatus(groupName)
		return
	elseif (firstCmd == "help") then
		uespLog.Msg("Shows information on daily quests done by this character:")
		uespLog.Msg(".     /uespdaily                 Show all daily quests")
		uespLog.Msg(".     /uespdaily [group]      Show daily quests for the given group")
		uespLog.Msg(".           Valid Groups: writ, craglorn, cyrodiil, goldcoast, wrothgar,")
		uespLog.Msg(".                               hewsbane, goldcoast, morrowind, clockwork")
		uespLog.Msg(".     /uespdaily help          Show help for command")
		return
	else
		uespLog.ShowDailyQuestStatusAll()
	end
	
end


SLASH_COMMANDS["/uespdaily"] = uespLog.DailyCommand


function uespLog.ShowDailyQuestStatusAll()
	uespLog.Msg("Showing all daily quests...")

	for name, data in pairs(uespLog.DAILY_QUESTS) do
		 uespLog.ShowDailyQuestStatus(name)
	end
	
end


function uespLog.ShowDailyQuestStatus(zoneName)
	local questData = uespLog.DAILY_QUESTS[zoneName]
	
	if (questData == nil) then
		uespLog.Msg("No daily quests found for "..tostring(zoneName).."!")
		return false
	end
	
	if (questData.maxCount ~= nil) then
		uespLog.ShowDailyQuestStatus_List('', zoneName, questData)
	else
		uespLog.ShowDailyQuestStatus_Group(zoneName, questData)
	end
		
	return true
end


function uespLog.ShowDailyQuestStatus_List(parentName, groupName, questData)
	local quests = questData.quests or {}
	local maxCount = questData.maxCount or -1
	local charQuestData = uespLog.GetDailyQuestData()
	local typeMsg = "do ALL of"
	local parentMsg = ""
	local groupCompleted, groupAcquired, groupReady
	local isFirst = true
	local lastStartTime = -1
	local lastQuestName = ""
	local lastQuestStatus = ""
	local numOutput = 0
	
	if (maxCount == 1) then
		typeMsg = "do ONE of"
	end
	
	if (parentName ~= "") then
		parentMsg = parentName .. "::"
	end
	
	if (groupName ~= "") then
		uespLog.Msg(""..parentMsg..tostring(groupName).." ("..typeMsg.."):")
	end
		
	for i, name in ipairs(quests) do
		local questCompleted, questAcquired, questReady, statusStr = uespLog.IsDailyQuestCompleted(name)
		local skip = false
	
		if (maxCount == 1) then
			skip = true
		
			if (isFirst) then
				groupCompleted, groupAcquired, groupReady = uespLog.IsDailyQuestGroupCompleted(name)
				isFirst = false
			end
			
			if (charQuestData[name] ~= nil and charQuestData[name].startTimestamp > lastStartTime) then
				lastStartTime = charQuestData[name].startTimestamp
				lastQuestName = name
				lastQuestStatus = statusStr
			end
			
			local canDo = uespLog.CanDoDailyQuest(name)
			
			if (canDo) then
				skip = false
			end
		end
		
		if (not skip) then
			numOutput = numOutput + 1
			uespLog.Msg(".      "..tostring(name)..": "..statusStr)
		end
	end
	
	if (numOutput == 0 and lastQuestName ~= "") then
		uespLog.Msg(".      "..tostring(lastQuestName)..": "..lastQuestStatus)
	end
	
end


function uespLog.ShowDailyQuestStatus_Group(groupName, questData)
	--uespLog.Msg(""..tostring(groupName)..":")
	
	for name, data in pairs(questData) do
		uespLog.ShowDailyQuestStatus_List(groupName, name, data)
	end
	
end


-- Returns: completed, acquired, ready, statusMsg
function uespLog.IsDailyQuestCompleted(questName)
	
	if (uespLog.CanDoDailyQuest(questName)) then
		return false, false, true, "READY to Acquire"
	end
	
	return uespLog.IsDailyQuestCompletedSimple(questName)
end


-- Returns: completed, acquired, ready, statusMsg
function uespLog.IsDailyQuestCompletedSimple(questName)
	local questData = uespLog.GetDailyQuestData()[questName]
	
	if (questData == nil) then
		return false, false, true, "READY to Acquire"
	end

	if (questData.startTimestamp <= 0) then
		return false, false, true, "READY to Acquire"
	end
	
	if (questData.isCompleted) then
		return true, false, false, "COMPLETED"
	end
		
	return false, true, false, "In Progress..."
end


function uespLog.FindDailyQuestGroup(questName)

	for name, questData in pairs(uespLog.DAILY_QUESTS) do
		local groupData = nil
	
		if (questData.maxCount ~= nil) then
			if (uespLog.FindDailyQuestGroup_List(questName, questData)) then
				groupData = questData
			end
		else
			groupData = uespLog.FindDailyQuestGroup_Group(questName, questData)
		end
		
		if (groupData ~= nil) then
			return groupData
		end
	end
	
	return nil
end


function uespLog.FindDailyQuestGroup_List(questName, questData)
	local quests = questData.quests or {}
	
	for i, name in ipairs(quests) do
		if (name == questName) then
			return true
		end
	end

	return false
end


function uespLog.FindDailyQuestGroup_Group(questName, questData)
	
	for name, data in pairs(questData) do
		if (uespLog.FindDailyQuestGroup_List(questName, data)) then
			return data
		end
	end

	return nil
end


-- Returns: completed, acquired, ready, statusMsg, lastStartTime
function uespLog.IsDailyQuestGroupCompleted(questName)
	local questGroup = uespLog.FindDailyQuestGroup(questName)
	local lastStartTime = -100
	local isCompleted = false
	local isAcquired = false
	local isReady = false
	
	if (questGroup == nil or questGroup.quests == nil) then
		return false, false, false, 'READY to Acquire', -1
	end
	
	if (questGroup.maxCount < 1) then
		return false, false, false, 'READY to Acquire', -1
	end
	
	for i, name in ipairs(questGroup.quests) do
		local questComplete, questAcquired, questReady = uespLog.IsDailyQuestCompletedSimple(name)
		local charQuestData = uespLog.GetDailyQuestData()[name]
		
		if (charQuestData ~= nil) then
		
			if (charQuestData.startTimestamp > lastStartTime) then
				lastStartTime = charQuestData.startTimestamp
			end
			
			if (questAcquired) then
				isAcquired = true
			end
			
			if (questComplete) then
				isCompleted = true
			end
			
			if (questReady) then
				isReady = true
			end
		end		
	end
		
	if (isAcquired) then
		return false, true, false, 'In Progress...', lastStartTime
	end
	
	if (isCompleted) then
		return true, false, false, 'COMPLETED', lastStartTime
	end
	
	if (isReady) then
		return false, false, true, 'READY to Acquire', lastStartTime
	end
	
	return false, false, false, 'READY to Acquire', lastStartTime
end


function uespLog.CanDoDailyQuest(questName)
	local lastStartTime = -1
	local lastResetTime = uespLog.GetLastDailyQuestResetTimestamp()
	local completed, acquired, ready, statusMsg = uespLog.IsDailyQuestCompletedSimple(questName)
	local groupCompleted, groupAcquired, groupReady, _, lastStartTime = uespLog.IsDailyQuestGroupCompleted(questName)
	local questData = uespLog.GetDailyQuestData()[questName]
	
	if (lastStartTime < 0 and questData ~= nil) then
		lastStartTime = questData.startTimestamp
	end
	
	if (lastStartTime >= lastResetTime) then
		return false
	end
		
	if (groupReady) then
		return true
	end
	
	if (groupAcquired) then
		return false
	end
	
	if (acquired) then
		return false
	end
	
	if (lastStartTime <= 0) then
		return true
	end
	
	if (lastStartTime < lastResetTime) then
		return true
	end
		
	return false
end


function uespLog.GetLastDailyQuestResetTimestamp()
	local currentTime = GetTimeStamp()
	local secondsFromMidnight = GetSecondsSinceMidnight()

	return currentTime - secondsFromMidnight + uespLog.DAILYQUEST_RESETOFFSET
end


function uespLog.GetDailyQuestData()

	if (uespLog.savedVars.charInfo == nil) then
		uespLog.savedVars.charInfo = uespLog.DEFAULT_CHARINFO
	end
	
	if (uespLog.savedVars.charInfo.data.dailyQuestData == nil) then
		uespLog.savedVars.charInfo.data.dailyQuestData = uespLog.DEFAULT_CHARINFO.dailyQuestData
	end
	
	return uespLog.savedVars.charInfo.data.dailyQuestData
end


function uespLog.IsDailyQuest(questName)
	local isDailyQuest = false

	for zone, zoneData in pairs(uespLog.DAILY_QUESTS) do
	
		if (zoneData.maxCount ~= nil) then
			isDailyQuest = uespLog.IsDailyQuest_List(questName, zoneData)
		else
			isDailyQuest = uespLog.IsDailyQuest_Group(questName, zoneData)
		end
		
		if (isDailyQuest) then
			return true
		end
		
	end

	return false
end


function uespLog.IsDailyQuest_Group(questName, questData)

	for group, groupData in pairs(questData) do
		local isDailyQuest = uespLog.IsDailyQuest_List(questName, groupData)
		
		if (isDailyQuest) then
			return true
		end
	end	
	
	return false
end


function uespLog.IsDailyQuest_List(questName, questData)
	local quests = questData.quests or {}
	
	for i,name in ipairs(quests) do
		if (name == questName) then
			return true
		end
	end
	
	return false
end


function uespLog.DailyQuestOnQuestStart(questName, journalIndex)
	local dailyQuest = uespLog.GetDailyQuestData()
	
	--uespLog.DebugMsg("DailyQuestOnQuestStart for "..tostring(questName)..", "..tostring(journalIndex))
	
	if (not uespLog.IsDailyQuest(questName)) then
		--uespLog.DebugMsg(".    Not a daily quest!")
		return false
	end
	
	if (dailyQuest[questName] == nil) then
	
		dailyQuest[questName] = 
		{ 
			["count"] = 0,
		}
		
	end
	
	dailyQuest[questName].isCompleted = false
	dailyQuest[questName].startTimestamp = GetTimeStamp()
	dailyQuest[questName].endTimestamp = -1	
	
	return true
end


function uespLog.DailyQuestOnQuestComplete(questName, journalIndex, isComplete)
	local dailyQuest = uespLog.GetDailyQuestData()
	
	--uespLog.DebugMsg("DailyQuestOnQuestComplete for "..tostring(questName)..", "..tostring(journalIndex)..", "..tostring(isComplete))
	
	if (not uespLog.IsDailyQuest(questName)) then
		--uespLog.DebugMsg(".    Not a daily quest!")
		return false
	end
	
	if (dailyQuest[questName] == nil) then
	
		dailyQuest[questName] = 
		{ 
			["count"] = 0,
			["startTimestamp"] = GetTimeStamp(),
		}
		
	end
	
	if (isComplete) then
		dailyQuest[questName].count = dailyQuest[questName].count + 1
	else
		dailyQuest[questName].startTimestamp = -1
	end
	
	dailyQuest[questName].isCompleted = isComplete
	dailyQuest[questName].endTimestamp = GetTimeStamp()
	
	return true
end








