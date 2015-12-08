-- uespLogCharData.lua -- by Dave Humphrey, dave@uesp.net
-- 
-- 


uespLog.CHARDATA_STATS = {
	[1] = "AttackPower",
	[2] = "WeaponPower",
	[3] = "ArmorRating",
	[4] = "Magicka",
	[5] = "MagickaRegenCombat",
	[6] = "MagickaRegenIdle",
	[7] = "Health",
	[8] = "HealthRegenCombat",
	[9] = "HealthRegenIdle",
	[10] = "HealingTaken",
	[11] = "Dodge",
	[12] = "Parry",
	[13] = "SpellResist",
	[14] = "Block",
	[16] = "CriticalStrike",
	[20] = "Mitigation",
	[22] = "PhysicalResist",
	[23] = "SpellCritical",
	[24] = "CriticalResistance",
	[25] = "SpellPower",
	[26] = "SpellMitigation",
	[29] = "Stamina",
	[30] = "StaminaRegenCombat",
	[31] = "StaminaRegenIdle",
	[32] = "Miss",
	[33] = "PhysicalPenetration",
	[34] = "SpellPenetration",
	[35] = "Power",
	[36] = "DamageResistStart",
	[37] = "DamageResistGeneric",
	[38] = "DamageResistPhysical",
	[39] = "DamageResistFire",
	[40] = "DamageResistShock",
	[41] = "DamageResistOblivion",
	[42] = "DamageResistCold",
	[43] = "DamageResistEarth",
	[44] = "DamageResistMagic",
	[45] = "DamageResistDrown",
	[46] = "DamageResistDisease",
	[47] = "DamageResistPoison",
	[48] = "MountStaminaMax",
	[49] = "MountStaminaRegenCombat",
	[50] = "MountStaminaRegenMoving",
}


uespLog.CHARDATA_POWER = {
	[-2] = "Health",
	[0] = "Magicka",
	[1] = "Werewolf",
	[2] = "Fervor",
	[3] = "Combo",
	[4] = "Power",
	[5] = "Charges",
	[7] = "Momentum",
	[6] = "Stamina",
	[8] = "Adrenaline",
	[9] = "Finesse",
	[10] = "Ultimate",
	[11] = "MountStamina",
	[12] = "HealthBonus",
}


uespLog.charData_ActionBarData = { 
	[1] = { },
	[2] = { }
}


uespLog.charDataLastScreenShot = ""
uespLog.charDataLastScreenShotTimestamp = 0


function uespLog.InitCharData()
	uespLog.SaveActionBarForCharData()
end


function uespLog.SaveCharData (note)
	local charData = uespLog.CreateCharData(note)
	local arraySize = #uespLog.savedVars.charData.data
	
	uespLog.savedVars.charData.data[arraySize + 1] = charData
	
	uespLog.Msg("UESP::Saved current character data ("..tostring(#uespLog.savedVars.charData.data).." characters in log).")
end


function uespLog.CreateCharData (note)
	local charData = { }
	
	charData.Note = note or ""
	charData.TimeStamp = GetTimeStamp()
	charData.TimeStamp64 = Id64ToString(charData.TimeStamp)
	charData.Date = GetDateStringFromTimestamp(charData.Timestamp)
	charData.APIVersion = GetAPIVersion()
	
	charData.CharName = GetUnitName("player")
	charData.AccountName = GetDisplayName()
	charData.Title = GetUnitTitle("player")
	charData.Race = GetUnitRace("player")
	charData.Class = GetUnitClass("player")
	charData.Gender = GetUnitGender("player")
	charData.Level = GetUnitLevel("player")
	charData.VeteranRank = GetUnitVeteranRank("player")
	charData.EffectiveLevel = GetUnitEffectiveLevel("player")
	charData.Zone = GetUnitZone("player")
	charData.ChampionPoints = GetPlayerChampionPointsEarned()
	charData.BattleLevel = GetUnitBattleLevel("player")
	charData.BattleVeteranRank = GetUnitVetBattleLevel("player")
	charData.BuildType = uespLog.GetCharDataBuildType()
	
	charData.Alliance = GetAllianceName(GetUnitAlliance("player"))
	charData.AllianceRank = GetUnitAvARank("player")
	charData.AlliancePoints = GetAlliancePoints()
	charData.AllianceCampaign = GetCampaignName(GetAssignedCampaignId())
	charData.AllianceGuestCampaign = GetCampaignName(GetGuestCampaignId())
	
	charData.Money = GetCurrentMoney()
	charData.BankedMoney = GetBankedMoney()
	charData.TelvarStones = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
	charData.BankedTelvarStones = GetBankedTelvarStones()
	
	charData.Bounty = GetBounty()
	charData.AttributesUnspent = GetAttributeUnspentPoints()
	charData.AttributesHealth = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
	charData.AttributesMagicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
	charData.AttributesStamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
	charData.AttributesTotal = charData.AttributesUnspent + charData.AttributesHealth + charData.AttributesMagicka + charData.AttributesStamina
	charData.SkillPointsUnused = GetAvailableSkillPoints()
	charData.SkyShards = GetNumSkyShards()

	local inventoryBonus, maxInventoryBonus, staminaBonus, maxStaminaBonus, speedBonus, maxSpeedBonus = GetRidingStats()
	charData.RidingInventory = inventoryBonus
	charData.RidingStamina = staminaBonus
	charData.RidingSpeeed = speedBonus
	
	charData.Stealth = GetUnitStealthState("player")
	
	charData.Stats = uespLog.CreateCharDataStats()
	charData.Power = uespLog.CreateCharDataPower()
	charData.Buffs = uespLog.CreateCharDataBuffs()
	charData.ActionBar = uespLog.CreateCharDataActionBar()
	charData.EquipSlots = uespLog.CreateCharDataEquipSlots()
	charData.ChampionPoints = uespLog.CreateCharDataChampionPoints()
	
	charData.Skills, charData.SkillPointsUsed = uespLog.CreateCharDataSkills()
	charData.SkillPointsTotal = charData.SkillPointsUsed + charData.SkillPointsUnused
	
	local screenShotDeltaTime = GetTimeStamp() - uespLog.charDataLastScreenShotTimestamp 
	
	if (screenShotDeltaTime >= 0 and screenShotDeltaTime <= 200) then
		charData.ScreenShot = uespLog.charDataLastScreenShot	
	else
		charData.ScreenShot = ""
	end
	
	return charData
end


function uespLog.OnScreenShotSaved(eventCode, directory, filename)
	uespLog.charDataLastScreenShot = tostring(directory)..""..tostring(filename)
	uespLog.charDataLastScreenShotTimestamp = GetTimeStamp()
	uespLog.DebugMsg("Screenshot Saved: "..uespLog.charDataLastScreenShot)
end


function uespLog.CreateCharDataStats()
	local stats = {}
	local i
	
	for i = -10, 100 do
		if (uespLog.CHARDATA_STATS[i] ~= nil) then
			local stat = GetPlayerStat(i, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
			
			if (stat ~= nil) then
				stats[uespLog.CHARDATA_STATS[i]] = stat
			end
		end
	end
	
	return stats
end


function uespLog.CreateCharDataPower()
	local power = {}
	local i
	
	for i = -10, 50 do
		if (uespLog.CHARDATA_POWER[i] ~= nil) then
			local current, currentMax, effectiveMax = GetUnitPower("player", i)
			
			if (currentMax ~= nil) then
				power[uespLog.CHARDATA_POWER[i]] = currentMax
			end
		end
	end
	
	return power
end


function uespLog.CreateCharDataBuffs()
	local buffs = {}
	local numBuffs = GetNumBuffs("player")
	local i
	
	for i = 1, numBuffs do
		local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)
	
		if (abilityId > 0) then
			buffs[#buffs + 1] = { ["name"] = buffName, ["id"] = abilityId, ["icon"] = iconFilename }
		end
	
	end

	return buffs
end


function uespLog.CreateCharDataEquipSlots()
	local wornSlots = GetBagSize(BAG_WORN)
	local i
	local equipSlots = { }
	

	for i = 1, wornSlots do
		if (HasItemInSlot(BAG_WORN, i)) then
			local itemLink = GetItemLink(BAG_WORN, i)
			local itemName = GetItemName(BAG_WORN, i)
			local condition = GetItemCondition(BAG_WORN, i)
			local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, i)
			local icon = GetItemLinkInfo(itemLink)
			
			if (maxCharges > 0) then
				condition = math.floor(charges*100/maxCharges + 0.5)
			end
			
			equipSlots[i] = { ["name"] = itemName, ["link"] = itemLink, ["condition"] = condition, ["icon"] = icon }
		end
	end
	
	
	return equipSlots
end


function uespLog.CreateCharDataSkills()
	local skills = {}
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local totalSkillPoints = -8   -- To account for crafting passives given by default
	
	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
			local skillLineName = GetSkillLineInfo(skillType, skillIndex)
			
			for abilityIndex = 1, numSkillAbilities do
				local name, texture, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local skillName = tostring(skillTypeName)..":"..tostring(skillLineName)..":"..tostring(name)
				local abilityId = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local description = GetAbilityDescription(abilityId)
				local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				local skillType = "skill"
				
				if (ultimate) then
					skillType = "ultimate"
				end
				
				progressionIndex = progressionIndex or 0
				currentUpgradeLevel = currentUpgradeLevel or 0
				
				if (purchase and abilityId > 0) then
				
					if (passive and currentUpgradeLevel > 0) then
						rank = currentUpgradeLevel
						totalSkillPoints = totalSkillPoints + rank
						skillType = "passive"
					elseif (progressionIndex > 0) then
						local name, morph, skillRank = GetAbilityProgressionInfo(progressionIndex)
						rank = skillRank + morph * 4
						totalSkillPoints = totalSkillPoints + 1 + math.floor(morph/2)
					else
						rank = 0
					end
					
					skills[skillName] = { ["rank"] = rank, ["id"] = abilityId, ["icon"] = texture, ["desc"] = description, ["type"] = skillType, ["index"] = abilityIndex }
				end
				
			end
		end
	
	end
	
	return skills, totalSkillPoints
end


function uespLog.CreateCharDataChampionPoints()
	local championPoints = {}
	local numDisc = GetNumChampionDisciplines()
	local discIndex
	local skillIndex
	
	for discIndex = 1, numDisc do
		local discName = tostring(GetChampionDisciplineName(discIndex))
		local numSkills = GetNumChampionDisciplineSkills(discIndex)
		local discPoints = GetNumPointsSpentInChampionDiscipline(discIndex)
		
		--championPoints[discName] = {}
		--championPoints[discName]["PointsSpent"] = GetNumPointsSpentInChampionDiscipline(discIndex)
		--championPoints[discName]["Attribute"] = GetChampionDisciplineAttribute(discIndex)		
		
		for skillIndex = 1, numSkills do
			local skillName = GetChampionSkillName(discIndex, skillIndex)
			local unlockLevel = GetChampionSkillUnlockLevel(discIndex, skillIndex)
			local abilityId = GetChampionAbilityId(discIndex, skillIndex)
			local spentPoints = GetNumPointsSpentOnChampionSkill(discIndex, skillIndex)
			local description = GetChampionAbilityDescription(abilityId, 0)
			local name = discName .. ":" .. tostring(skillName)
			
			unlockLevel = unlockLevel or 100000
			
			if (spentPoints == 0 and unlockLevel <= discPoints) then
				spentPoints = 1
			end
			
			if (spentPoints > 0) then
				championPoints[name] = { ["points"] = spentPoints, ["desc"] = description, ["id"] = abilityId }
			end
		end
	end
	
	championPoints["Health:Unspent"] = GetNumUnspentChampionPoints(ATTRIBUTE_HEALTH)
	championPoints["Magicka:Unspent"] = GetNumUnspentChampionPoints(ATTRIBUTE_MAGICKA)
	championPoints["Stamina:Unspent"] = GetNumUnspentChampionPoints(ATTRIBUTE_STAMINA)
	championPoints["Health:Spent"] = GetNumSpentChampionPoints(ATTRIBUTE_HEALTH)
	championPoints["Magicka:Spent"] = GetNumSpentChampionPoints(ATTRIBUTE_MAGICKA)
	championPoints["Stamina:Spent"] = GetNumSpentChampionPoints(ATTRIBUTE_STAMINA)
	championPoints["MaxSpendablePerAttribute"] = GetMaxSpendableChampionPointsInAttribute()
	
	championPoints["Total:Unspent"] = championPoints["Health:Unspent"] + championPoints["Magicka:Unspent"] + championPoints["Stamina:Unspent"]
	championPoints["Total:Spent"]   = championPoints["Health:Spent"] + championPoints["Magicka:Spent"] + championPoints["Stamina:Spent"]
	
	return championPoints, championPoints["Total:Spent"] , championPoints["Total:Unspent"]
end


function uespLog.CreateCharDataActionBar()
	local slots = {}
	local i
	local j
	
	uespLog.SaveActionBarForCharData()
	
	for j = 1, 2 do
		for i = 3, 8 do
			slots[i + (j-1)*100] = uespLog.charData_ActionBarData[j][i]
		end
	end
	
	if (not uespLog.HasBothActionBarsForCharData()) then
		uespLog.MsgColor(uespLog.errorColor, "WARNING: Unused weapon swap action bar skills not saved!")
        uespLog.MsgColor(uespLog.errorColor, ".        Try weapon swapping and save character again.")
	end
	
	return slots
end


function uespLog.SaveActionBarForCharData()
	local weaponPairIndex, isLocked = GetActiveWeaponPairInfo()
	
	if (weaponPairIndex < 1 or weaponPairIndex > 2) then
		return false
	end
	
	uespLog.charData_ActionBarData[weaponPairIndex] = { }
	
	for i = 3, 8 do
		local texture = GetSlotTexture(i)
		local id = GetSlotBoundId(i)
		local name = GetSlotName(i)
		local description = GetAbilityDescription(id)
		
		uespLog.charData_ActionBarData[weaponPairIndex][i] = { ["name"] = name, ["id"] = id, ["icon"] = texture, ["desc"] = description }
	end
	
end


function uespLog.HasBothActionBarsForCharData()

	if (#uespLog.charData_ActionBarData[1] > 0 and #uespLog.charData_ActionBarData[2] > 0) then
		return true
	end

	return false
end


function uespLog.GetCharDataBuildType()
	local AttributesHealth = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
	local AttributesMagicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
	local AttributesStamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
	
	if (AttributesMagicka >= 20 and AttributesMagicka * 0.75 > AttributesStamina) then
		return "Magicka"
	elseif (AttributesStamina >= 20 and AttributesStamina * 0.75 > AttributesMagicka) then
		return "Stamina"
	end
	
	return "Other"
end


function uespLog.OnActionSlotsFullUpdate (eventCode, isHotbarSwap)
	--uespLog.DebugMsg("OnActionSlotsFullUpdate "..tostring(isHotbarSwap))
	
	if (isHotbarSwap) then
		--uespLog.SaveActionBarForCharData()
	end
	
end


function uespLog.OnActionSlotAbilitySlotted (eventCode, newAbilitySlotted)
	--uespLog.DebugMsg("OnActionSlotAbilitySlotted "..tostring(newAbilitySlotted))
	--uespLog.SaveActionBarForCharData()
end


function uespLog.OnActionSlotUpdated (eventCode, slotNum)
	--uespLog.DebugMsg("OnActionSlotUpdated "..tostring(slotNum))
	--uespLog.SaveActionBarForCharData()
end


function uespLog.OnActiveQuickSlotChanged (eventCode, slotId)
	--uespLog.DebugMsg("OnActiveQuickSlotChanged "..tostring(slotId))
	--uespLog.SaveActionBarForCharData()
end


function uespLog.OnActiveWeaponPairChanged (eventCode, activeWeaponPair, locked)
	--uespLog.DebugMsg("OnActiveWeaponPairChanged "..tostring(activeWeaponPair))
	uespLog.SaveActionBarForCharData()
end


function uespLog.Command_SaveCharData (cmd)
	lcmd = string.lower(cmd)
	
	if (lcmd == "help" or cmd == "") then
		uespLog.Msg("UESP::Saves current character data to the log file.")
		uespLog.Msg(".     /uespsavechar help         = Shows basic command format")
		uespLog.Msg(".     /uespsavechar reset        = Clears character log")
		uespLog.Msg(".     /uespsavechar status       = Shows current character log status")
		uespLog.Msg(".     /uespsavechar [buildName]  = Saves current character with given build name")
	elseif (lcmd == "status") then
		uespLog.Msg("UESP::Currently there are "..tostring(#uespLog.savedVars.charData.data).." characters saved in log.")
	elseif (lcmd == "reset" or lcmd == "clear") then
		uespLog.savedVars.charData.data = { }
		uespLog.Msg("UESP::Cleared logged character data.")
	else
		uespLog.SaveCharData(cmd)
	end
	
end


function uespLog.GetSkillPointsUsed()
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local totalSkillPoints = -8			 -- To account for crafting passives given by default
	
	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
			
			for abilityIndex = 1, numSkillAbilities do
				local name, texture, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local abilityId = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				
				progressionIndex = progressionIndex or 0
				currentUpgradeLevel = currentUpgradeLevel or 0
				
				if (purchase and abilityId > 0) then
				
					if (passive and currentUpgradeLevel > 0) then
						totalSkillPoints = totalSkillPoints + currentUpgradeLevel
					elseif (progressionIndex > 0) then
						local name, morph, skillRank = GetAbilityProgressionInfo(progressionIndex)
						totalSkillPoints = totalSkillPoints + 1 + math.floor(morph/2)
					end
				end
				
			end
		end
	
	end
	
	return totalSkillPoints
end


SLASH_COMMANDS["/uespsavechar"] = uespLog.Command_SaveCharData
SLASH_COMMANDS["/usc"] = uespLog.Command_SaveCharData


SLASH_COMMANDS["/uespskillpoints"] = function (cmd)
	local skillPointsUsed = uespLog.GetSkillPointsUsed()
	local skillPointsUnused = GetAvailableSkillPoints()
	local skyShards = GetNumSkyShards()
	
	uespLog.Msg("You have used "..tostring(skillPointsUsed).." skill points, "..tostring(skillPointsUnused).." unused skill points and "..tostring(skyShards).." skyshards.")
end


SLASH_COMMANDS["/usp"] = SLASH_COMMANDS["/uespskillpoints"]