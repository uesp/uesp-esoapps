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
	--[1] = "Werewolf",  --Intereferes with "iswerewolf" stat
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

uespLog.charDataLastFoodEaten = {
	['name'] = '',
	['itemLink'] = '',
	['type'] = '',
	['desc'] = '',
	['reqLevel'] = '',
	['reqVetRank'] = '',
}


function uespLog.InitCharData()
	uespLog.SaveActionBarForCharData()
end


function uespLog.SaveCharData (note)
	local charData = uespLog.CreateCharData(note)
		
	if (charData == nil) then
		return false
	end
	
	uespLog.savedVars.charInfo.data.charData = charData
	uespLog.savedVars.charData.data.Bank = uespLog.CreateBankInventoryData()
	
	return true
end


function uespLog.OnPlayerDeactivated (eventCode)
	uespLog.DebugExtraMsg("OnPlayerDeactivated")
	
	if (uespLog.GetAutoSaveCharData()) then
		uespLog.SaveCharData()
	end
end


function uespLog.OnLogoutDisallowed (eventCode, quitRequested)
	uespLog.DebugExtraMsg("OnLogoutDisallowed")
	
	if (uespLog.GetAutoSaveCharData()) then
		uespLog.SaveCharData()
	end
end


function uespLog.CreateCharData (note)
	local charData = uespLog.CreateBuildData(note, true, true)
	
	charData.Inventory = uespLog.CreateInventoryData()
	
	return charData
end


function uespLog.CreateInventoryData ()
	-- BAG_BACKPACK == 1
	-- GetMaxBags()
	-- GetItemTotalCount(BAG_BACKPACK, i)
	local inventory = { }
	local i
	
	inventory.size = GetBagSize(BAG_BACKPACK)
	inventory.timestamp = GetTimeStamp()
	inventory.gold = GetCurrentMoney()
	inventory.telvar = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
	
	for i = 0, inventory.size do
		inventory[#inventory + 1] = uespLog.CreateInventorySlotData(BAG_BACKPACK, i)
	end
	
	return inventory
end


function uespLog.CreateBankInventoryData ()
	--BAG_BANK == 2
	local inventory = { }
	local i
	
	inventory.size = GetBagSize(BAG_BANK)
	inventory.timestamp = GetTimeStamp()
	
	inventory.gold = GetBankedMoney()
	inventory.telvar = GetBankedCurrencyAmount(CURT_TELVAR_STONES)
	
	inventory.UniqueAccountName = uespLog.GetUniqueAccountName()
	
	for i = 0, inventory.size do
		inventory[#inventory + 1] = uespLog.CreateInventorySlotData(BAG_BANK, i)
	end
	
	return inventory
end


function uespLog.CreateInventorySlotData (bagId, slotIndex)
	local count = GetSlotStackSize(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex)
	local niceLink = uespLog.MakeNiceLink(itemLink)
	
	if (count == 0 or itemLink == "") then
		return nil
	end
	
	return tostring(count) .. " " .. niceLink
end


function uespLog.GetUniqueAccountName()
	local serverName = GetUniqueNameForCharacter()	
	local accountName = GetDisplayName()
	
	return tostring(serverName) .. tostring(accountName)
end


function uespLog.SaveBuildData (note, forceSave)
	forceSave = forceSave or false
	local charData = uespLog.CreateBuildData(note, forceSave, false)
		
	if (charData == nil) then
		uespLog.MsgColor(uespLog.errorColor, "UESP::Did *not* save current character!")
		return false
	end
	
	local arraySize = #uespLog.savedVars.buildData.data
	uespLog.savedVars.buildData.data[arraySize + 1] = charData
	
	uespLog.Msg("UESP::Saved current character data ("..tostring(#uespLog.savedVars.buildData.data).." characters in log).")
	return true
end


function uespLog.CreateBuildData (note, forceSave, suppressMsg)
	local charData = { }
	suppressMsg = suppressMsg or true
	
	if (not uespLog.HasBothActionBarsForCharData()) then
		if (not forceSave) then
			uespLog.MsgColor(uespLog.errorColor, "ERROR: Unused weapon action bar skills not saved!")
			uespLog.MsgColor(uespLog.errorColor, ".      Try weapon swapping and save character again.")
			return nil
		elseif (not suppressMsg) then
			uespLog.MsgColor(uespLog.errorColor, "Warning: Unused weapon action bar skills not available!")
		end
	end
	
	charData.Note = note or ""
	charData.TimeStamp = GetTimeStamp()
	charData.TimeStamp64 = Id64ToString(charData.TimeStamp)
	charData.Date = GetDateStringFromTimestamp(charData.Timestamp)
	charData.APIVersion = GetAPIVersion()
	
	charData.CharName = GetUnitName("player")
	charData.AccountName = GetDisplayName()
	charData.UniqueAccountName = uespLog.GetUniqueAccountName()
	charData.UniqueName = GetUniqueNameForCharacter(charData.CharName)
	charData.Title = GetUnitTitle("player")
	charData.Race = GetUnitRace("player")
	charData.Class = GetUnitClass("player")
	charData.Gender = GetUnitGender("player")
	charData.Level = GetUnitLevel("player")
	charData.VeteranRank = GetUnitVeteranRank("player")
	charData.EffectiveLevel = GetUnitEffectiveLevel("player")
	charData.Zone = GetUnitZone("player")
	charData.ChampionPointsEarned = GetPlayerChampionPointsEarned()
	charData.BattleLevel = GetUnitBattleLevel("player")
	charData.BattleVeteranRank = GetUnitVetBattleLevel("player")
	charData.BuildType = uespLog.GetCharDataBuildType()
	charData.ActiveAbilityBar = GetActiveWeaponPairInfo()
	
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
	
		-- Note: This function doesn't seem to work, or only works if the character is actually in Werewolf form at the time
	if (IsWerewolf()) then
		charData.Werewolf = 1
	else
		charData.Werewolf = 0
	end
	
	charData.LastFoodEatenName = uespLog.charDataLastFoodEaten.name
	charData.LastFoodEatenLink = uespLog.charDataLastFoodEaten.itemLink
	charData.LastFoodEatenType = uespLog.charDataLastFoodEaten.type
	charData.LastFoodEatenDesc = uespLog.charDataLastFoodEaten.desc
	charData.LastFoodEatenLevel = uespLog.charDataLastFoodEaten.reqLevel
	charData.LastFoodEatenVetRank = uespLog.charDataLastFoodEaten.reqVetRank
	
	charData.Stats = uespLog.CreateCharDataStats()
	charData.Power = uespLog.CreateCharDataPower()
	charData.Buffs, charData.Vampire, charData.Werewolf = uespLog.CreateCharDataBuffs()
	charData.ActionBar = uespLog.CreateCharDataActionBar()
	charData.EquipSlots = uespLog.CreateCharDataEquipSlots()
	charData.ChampionPoints = uespLog.CreateCharDataChampionPoints()
	charData.Crafting = uespLog.CreateCharDataCrafting()
	
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


uespLog.CHARDATA_CRAFTSTYLE_NAMES = {
	[1] = 'Altmer',
	[2] = 'Dunmer',
	[3] = 'Bosmer',
	[4] = 'Nord',
	[5] = 'Breton',
	[6] = 'Redguard',
	[7] = 'Khajiit',
	[8] = 'Orc',
	[9] = 'Argonian',
	[10] = 'Imperial',
	[11] = 'Ancient Elf',
	[12] = 'Barbaric',
	[13] = 'Primal',
	[14] = 'Daedric',
	[15] = 'Dwemer',
	[16] = 'Glass',
	[17] = 'Xivkyn',
	[18] = 'Akaviri',
	[19] = 'Mercenary',
	[20] = 'Yokudan',
	[21] = 'Ancient Orc',
}


function uespLog.CreateCharDataCrafting()
	local crafting = {}
	
	for k, styleName in ipairs(uespLog.CHARDATA_CRAFTSTYLE_NAMES) do
		local known = uespLog.GetStyleKnown(styleName)
		
		if (type(known) == "table") then
			crafting[styleName] = {}
			
			for k, v in ipairs(known) do
				if (v) then
					crafting[styleName][k] = 1
				else
					crafting[styleName][k] = 0
				end
			end
		elseif (known) then
			crafting[styleName] = 1
		else
			crafting[styleName] = 0
		end
	end	
	
	return crafting
end


function uespLog.OnEatDrinkItem(bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
	local itemName = GetItemName(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex)
	local itemType = "unknown"
	local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isVeteranRank = GetItemLinkOnUseAbilityInfo(itemLink)
	local reqLevel = GetItemLinkRequiredLevel(itemLink)
	local reqVetRank = GetItemLinkRequiredVeteranRank(itemLink)
	
	if (itemSoundCategory == 18) then
		itemType = "food"
	elseif (itemSoundCategory == 19) then
		itemType = "drink"
	end
	
	uespLog.charDataLastFoodEaten.name = itemName
	uespLog.charDataLastFoodEaten.itemLink = itemLink
	uespLog.charDataLastFoodEaten.type = itemType
	uespLog.charDataLastFoodEaten.desc = abilityDescription
	uespLog.charDataLastFoodEaten.reqLevel = reqLevel
	uespLog.charDataLastFoodEaten.reqVetRank = reqVetRank
	
	uespLog.savedVars.charInfo.data.lastFoodEaten = uespLog.charDataLastFoodEaten
	
	uespLog.DebugExtraMsg("UESP::You ate/drank "..tostring(itemLink).."")
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
	local isVampire = false
	local isWerewolf = false
	
	for i = 1, numBuffs do
		local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)
	
		if (abilityId > 0) then
			buffs[#buffs + 1] = { ["name"] = buffName, ["id"] = abilityId, ["icon"] = iconFilename }
		end
		
		if (string.find(buffName, "Vampirism") ~= nil) then 
			isVampire = true
		elseif (buffName == "Lycanthropy") then 
			isWerewolf = true
		end
		
	end

	return buffs, isVampire, isWerewolf
end


function uespLog.CreateCharDataEquipSlots()
	local wornSlots = GetBagSize(BAG_WORN)
	local i
	local equipSlots = { }

	for i = 0, wornSlots do
		if (HasItemInSlot(BAG_WORN, i)) then
			local itemLink = GetItemLink(BAG_WORN, i)
			local itemName = GetItemName(BAG_WORN, i)
			local condition = GetItemCondition(BAG_WORN, i)
			local charges, maxCharges = GetChargeInfoForItem(BAG_WORN, i)
			local icon = GetItemLinkInfo(itemLink)
			local hasSet, setName, numBonuses, setCount, maxEquipped = GetItemLinkSetInfo(itemLink)
			
			if (not hasSet) then
				setCount = 0
			end
			
			if (maxCharges > 0) then
				condition = math.floor(charges*100/maxCharges + 0.5)
			end
			
			equipSlots[i] = { ["name"] = itemName, ["link"] = itemLink, ["condition"] = condition, ["icon"] = icon, ["setcount"] = setCount }
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
					elseif (passive and currentUpgradeLevel == 0) then
						rank = 1
						totalSkillPoints = totalSkillPoints + 1
						skillType = "passive"
					elseif (progressionIndex > 0) then
						local progName, morph, skillRank = GetAbilityProgressionInfo(progressionIndex)
						rank = skillRank + morph * 4
						totalSkillPoints = totalSkillPoints + 1 + math.floor(morph/2)
					else
						rank = 0
					end
					
					local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId)
					local minRange, maxRange = GetAbilityRange(abilityId)
					local radius = GetAbilityRadius(abilityId)
					local angleDistance = GetAbilityAngleDistance(abilityId)
					local duration = GetAbilityDuration(abilityId)
					local cost, mechanic = GetAbilityCost(abilityId)
					local targetDesc = GetAbilityTargetDescription(abilityId) or ''
					local costStr = tostring(cost) .. ' ' .. uespLog.GetCombatMechanicText(mechanic)
					local rangeStr = ""
					local areaStr = ""
					
					if (not channeled) then
						channelTime = 0
					end
					
					if (minRange > 0 and maxRange > 0) then
						rangeStr = tostring(minRange/100) .. " - " .. tostring(maxRange/100) .. " meters"
					elseif (minRange <= 0 and maxRange > 0) then
						rangeStr = tostring(maxRange/100) .. " meters"
					elseif (minRange > 0 and maxRange <= 0) then
						rangeStr = "Under " .. tostring(minRange/100) .. " meters"
					end
					
					if (angleDistance > 0) then
						areaStr = tostring(radius/100) .. " x " .. tostring(angleDistance/50) .. " meters"
					end
		
					skills[skillName] = {
							["rank"] = rank, 
							["id"] = abilityId, 
							["icon"] = texture, 
							["desc"] = description, 
							["type"] = skillType, 
							["index"] = abilityIndex,
							["name"] = name, 
							["area"] = areaStr,
							["cost"] = costStr,
							["range"] = rangeStr,
							["radius"] = radius,
							["castTime"] = castTime,
							["channelTime"] = channelTime,
							["duration"] = duration,
							["target"] = targetDesc,
						}
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
		
		championPoints[discName .. ":Points"] = discPoints
		
		for skillIndex = 1, numSkills do
			local skillName = GetChampionSkillName(discIndex, skillIndex)
			local unlockLevel = GetChampionSkillUnlockLevel(discIndex, skillIndex)
			local abilityId = GetChampionAbilityId(discIndex, skillIndex)
			local spentPoints = GetNumPointsSpentOnChampionSkill(discIndex, skillIndex)
			local description = GetChampionAbilityDescription(abilityId, 0)
			local name = discName .. ":" .. tostring(skillName)
			
			unlockLevel = unlockLevel or 100000
			
			if (spentPoints == 0 and unlockLevel <= discPoints) then
				spentPoints = -1
			end
			
			if (spentPoints ~= 0) then
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
	
	return slots
end


function uespLog.GetCombatMechanicText(id)
	local textId = _G['SI_COMBATMECHANICTYPE' .. tostring(id)]
	
	if (textId == nil) then
		return tostring(id)
	end
	
	local text = GetString(textId)
	
	if (text == nil or text == "") then
		return tostring(id)
	end
	
	return text
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
		local channeled, castTime, channelTime = GetAbilityCastInfo(id)
		local minRange, maxRange = GetAbilityRange(id)
		local radius = GetAbilityRadius(id)
		local angleDistance = GetAbilityAngleDistance(id)
		local duration = GetAbilityDuration(id)
		local cost, mechanic = GetAbilityCost(id)
		local targetDesc = GetAbilityTargetDescription(id) or ''
		local costStr = tostring(cost) .. ' ' .. uespLog.GetCombatMechanicText(mechanic)
		local rangeStr = ""
		local areaStr = ""
		
		if (not channeled) then
			channelTime = 0
		end
		
		if (minRange > 0 and maxRange > 0) then
			rangeStr = tostring(minRange/100) .. " - " .. tostring(maxRange/100) .. " meters"
		elseif (minRange <= 0 and maxRange > 0) then
			rangeStr = tostring(maxRange/100) .. " meters"
		elseif (minRange > 0 and maxRange <= 0) then
			rangeStr = "Under " .. tostring(minRange/100) .. " meters"
		end
		
		if (angleDistance > 0) then
			areaStr = tostring(radius/100) .. " x " .. tostring(angleDistance/50) .. " meters"
		end
		
		uespLog.charData_ActionBarData[weaponPairIndex][i] = { 
				["name"] = name, 
				["id"] = id, 
				["icon"] = texture,
				["desc"] = description,
				["area"] = areaStr,
				["cost"] = costStr,
				["range"] = rangeStr,
				["radius"] = radius,
				["castTime"] = castTime,
				["channelTime"] = channelTime,
				["duration"] = duration,
				["target"] = targetDesc,
			}
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


function uespLog.ClearCharData()
	uespLog.savedVars.charInfo.data.charData = { }
	uespLog.savedVars.charData.data.Bank = { }
	uespLog.Msg("UESP::Cleared all character data.")
end


function uespLog.ClearBuildData()
	uespLog.savedVars.buildData.data = { }
	uespLog.Msg("UESP::Cleared logged character build data.")
end


function uespLog.Command_SaveBuildData (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%S+") do table.insert(cmdWords, word) end
	
	firstCmd = string.lower(cmdWords[1]) or ""
	
	if (firstCmd == "help" or cmd == "" or (firstCmd == "forcesave" and #cmdWords <= 1)) then
		uespLog.Msg("UESP::Saves current character build data to the log file (or '/usb').")
		uespLog.Msg(".     /usb help             = Shows basic command format")
		uespLog.Msg(".     /usb reset            = Clears character log")
		uespLog.Msg(".     /usb status           = Shows current character log status")
		uespLog.Msg(".     /usb [buildName]      = Saves current character with given build name")
		uespLog.Msg(".     /usb forcesave [name] = Saves character ignoring any errors")
		uespLog.Msg(".     /usb screenshot       = Takes a 'nice' screenshot of your character")
	elseif (firstCmd == "status") then
		uespLog.Msg("UESP::Currently there are "..tostring(#uespLog.savedVars.buildData.data).." character builds saved in log.")
	elseif (firstCmd == "reset" or firstCmd == "clear") then
		uespLog.ClearBuildData()
	elseif (firstCmd == "forcesave") then
		cmdWords[1] = nil
		buildName = table.concat(cmdWords, ' ')
		uespLog.SaveBuildData(buildName, true)
	elseif (firstCmd == "ss" or firstCmd == "screenshot") then
		uespLog.TakeCharDataScreenshot()
	else
		uespLog.SaveBuildData(cmd, false)
	end
	
end


uespLog.guiHiddenBefore = false
uespLog.isTakingCharDataScreenshot = false


function uespLog.TakeCharDataScreenshot()

	if (uespLog.isTakingCharDataScreenshot) then
		return false
	end
	
	uespLog.Msg("UESP:Taking character screenshot in 1 sec...don't touch anything!")
	
	uespLog.isTakingCharDataScreenshot = true

	SetFrameLocalPlayerInGameCamera(true)
	SetFrameLocalPlayerTarget(0.5, 0.65)
	SetFullscreenEffect(FULLSCREEN_EFFECT_CHARACTER_FRAMING_BLUR, 0.5, 0.65)
	uespLog.guiHiddenBefore = GetGuiHidden("ingame")
	
	if (not uespLog.guiHiddenBefore) then
		ToggleShowIngameGui()
	end
	
	zo_callLater(uespLog.QueuedCharDataScreenshot, 1000)
end


function uespLog.QueuedCharDataScreenshot()
	TakeScreenshot()
	zo_callLater(uespLog.EndQueuedCharDataScreenshot, 500)
end


function uespLog.EndQueuedCharDataScreenshot()
	SetFrameLocalPlayerInGameCamera(false)
	SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
	
	if (not uespLog.guiHiddenBefore and GetGuiHidden("ingame")) then
		ToggleShowIngameGui()
	end
	
	uespLog.isTakingCharDataScreenshot = false
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
					elseif (passive and currentUpgradeLevel == 0) then
						totalSkillPoints = totalSkillPoints + 1
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


SLASH_COMMANDS["/uespsavebuild"] = uespLog.Command_SaveBuildData
SLASH_COMMANDS["/usb"] = uespLog.Command_SaveBuildData


SLASH_COMMANDS["/uespskillpoints"] = function (cmd)
	local skillPointsUsed = uespLog.GetSkillPointsUsed()
	local skillPointsUnused = GetAvailableSkillPoints()
	local skyShards = GetNumSkyShards()
	
	uespLog.Msg("You have used "..tostring(skillPointsUsed).." skill points, "..tostring(skillPointsUnused).." unused skill points and "..tostring(skyShards).." skyshards.")
end


SLASH_COMMANDS["/usp"] = SLASH_COMMANDS["/uespskillpoints"]

