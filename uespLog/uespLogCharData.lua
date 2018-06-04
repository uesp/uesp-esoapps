-- uespLogCharData.lua -- by Dave Humphrey, dave@uesp.net
-- 
-- 

	-- Only save action bars at most every X seconds
uespLog.SAVEACTIONBAR_MINDELTATIME = 5
uespLog.LastSavedActionBar_TimeStamp = 0
uespLog.LastSavedActionBar_WeaponPair = 0

uespLog.LastBankingBag = 0


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
	--[4] = "Power",	--Interferes with "power" stat
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
	[2] = { },
	[3] = { }, -- Overload
	[4] = { }, -- Werewolf
}


uespLog.charData_SkillsData = { 
	[1] = { },
	[2] = { },
	[3] = { }, -- Overload
	[4] = { }, -- Werewolf
}


uespLog.charData_StatsData = { 
	[1] = { },
	[2] = { },
	[3] = { }, -- Overload
	[4] = { }, -- Werewolf
}


uespLog.charDataLastScreenShot = ""
uespLog.charDataLastScreenShotTimestamp = 0
uespLog.charDataLastScreenShotTaken = false
uespLog.charDataLastScreenShotCaption = ""
uespLog.guiHiddenBefore = false
uespLog.isTakingCharDataScreenshot = false


uespLog.charDataLastFoodEaten = {
	['itemLink'] = '',
	['type'] = '',
	['desc'] = '',
	['reqLevel'] = '',
	['reqCP'] = '',
}


	-- Active and passive skills where the first level is given free (does not count towards character's total skill points)
uespLog.FREE_SKILLS = {
	[33293] = 1,		-- Craftsman (Orc)
	[35965] = 1,		-- Highborn (High Elf)
	[36008] = 1,		-- Acrobat (Wood Elf)
	[36063] = 1,		-- Cutpurse (Khajiit)
	[36247] = 1,		-- Opportunist (Breton)
	[36312] = 1,		-- Diplomat (Imperial)
	[36582] = 1,		-- Amphibian (Argonian)
	[36588] = 1,		-- Ashlander (Dark Elf)
	[36626] = 1,		-- Reveler (Nord)
	[84680] = 1,		-- Wayfarer (Redguard)
	
	[74580] = 1,		-- Finders Keepers
	[78219] = 1,		-- Blade of Woe
	
	[26768] = 1,		-- Soul Trap 1
	[43050] = 1,		-- Soul Trap 2
	[43053] = 1,		-- Soul Trap 3
	[43056] = 1,		-- Soul Trap 4	
	[40328] = 1,		-- Soul Splitting Trap 1
	[43059] = 1,		-- Soul Splitting Trap 2
	[43063] = 1,		-- Soul Splitting Trap 3
	[43067] = 1,		-- Soul Splitting Trap 4
	[40317] = 1,		-- Consuming Trap 1
	[43071] = 1,		-- Consuming Trap 2
	[43077] = 1,		-- Consuming Trap 3
	[43083] = 1,		-- Consuming Trap 4
	
	[44590] = 1,		-- Recipe Improvement 1
	[44595] = 1,		-- Recipe Improvement 2
	[44597] = 1,		-- Recipe Improvement 3
	[44598] = 1,		-- Recipe Improvement 4
	[44599] = 1,		-- Recipe Improvement 5
	[44650] = 1,		-- Recipe Improvement 6
	[44625] = 1,		-- Recipe Quality     1
	[44630] = 1,		-- Recipe Quality     2
	[44631] = 1,		-- Recipe Quality     3
	[69953] = 1,		-- Recipe Quality     4
	[45542] = 1,		-- Solvent Proficiency 1
	[45547] = 1,		-- Solvent Proficiency 2
	[45550] = 1,		-- Solvent Proficiency 3
	[45551] = 1,		-- Solvent Proficiency 4
	[45552] = 1,		-- Solvent Proficiency 5
	[49163] = 1,		-- Solvent Proficiency 6
	[70042] = 1,		-- Solvent Proficiency 7
	[70043] = 1,		-- Solvent Proficiency 8
	[46727] = 1,		-- Potency Improvement 1
	[46729] = 1,		-- Potency Improvement 2
	[46731] = 1,		-- Potency Improvement 3
	[46735] = 1,		-- Potency Improvement 4
	[46736] = 1,		-- Potency Improvement 5
	[46740] = 1,		-- Potency Improvement 6
	[49112] = 1,		-- Potency Improvement 7
	[49113] = 1,		-- Potency Improvement 8
	[49114] = 1,		-- Potency Improvement 9
	[70045] = 1,		-- Potency Improvement 10
	[46758] = 1,		-- Aspect Improvement 1
	[46759] = 1,		-- Aspect Improvement 2
	[46760] = 1,		-- Aspect Improvement 3
	[46763] = 1,		-- Aspect Improvement 4
	[47276] = 1,		-- Metalworking 1
	[47277] = 1,		-- Metalworking 2
	[47278] = 1,		-- Metalworking 3
	[47279] = 1,		-- Metalworking 4
	[47280] = 1,		-- Metalworking 5
	[47281] = 1,		-- Metalworking 6
	[48157] = 1,		-- Metalworking 7
	[48158] = 1,		-- Metalworking 8
	[48159] = 1,		-- Metalworking 9
	[70041] = 1,		-- Metalworking 10
	[47282] = 1,		-- Woodworking 1
	[47283] = 1,		-- Woodworking 2
	[47284] = 1,		-- Woodworking 3
	[47285] = 1,		-- Woodworking 4
	[47286] = 1,		-- Woodworking 5
	[47287] = 1,		-- Woodworking 6
	[48172] = 1,		-- Woodworking 7
	[48173] = 1,		-- Woodworking 8
	[48174] = 1,		-- Woodworking 9
	[70046] = 1,		-- Woodworking 10
	[47288] = 1,		-- Tailoring 1
	[47289] = 1,		-- Tailoring 2
	[47290] = 1,		-- Tailoring 3
	[47291] = 1,		-- Tailoring 4
	[47292] = 1,		-- Tailoring 5
	[47293] = 1,		-- Tailoring 6
	[48187] = 1,		-- Tailoring 7
	[48188] = 1,		-- Tailoring 8
	[48189] = 1,		-- Tailoring 9
	[70044] = 1,		-- Tailoring 10
	[103632] = 1,		-- Jewelycrafting 1
	[103633] = 1,		-- Jewelycrafting 2
	[103634] = 1,		-- Jewelycrafting 3
	[103635] = 1,		-- Jewelycrafting 4
	[103636] = 1,		-- Jewelycrafting 5
	[103793] = 1,		-- Psijic Order 1
	
	--[32624] = 1,		-- Bat Swarm 1
	--[41918] = 1,		-- Bat Swarm 2
	--[41919] = 1,		-- Bat Swarm 3
	--[41920] = 1,		-- Bat Swarm 4
	--[38932] = 1,		-- Clouding Swarm 1
	--[41924] = 1,		-- Clouding Swarm 2
	--[41925] = 1,		-- Clouding Swarm 3
	--[41926] = 1,		-- Clouding Swarm 4
	--[38931] = 1,		-- Devouring Swarm 1
	--[41933] = 1,		-- Devouring Swarm 2
	--[41936] = 1,		-- Devouring Swarm 3
	--[41937] = 1,		-- Devouring Swarm 4
		
	[32455] = 1,		-- Werewolf Transformation 1
	[42356] = 1,		-- Werewolf Transformation 2
	[42357] = 1,		-- Werewolf Transformation 3
	[42358] = 1,		-- Werewolf Transformation 4
	[39075] = 1,		-- Pack Leader 1
	[42365] = 1,		-- Pack Leader 2
	[42366] = 1,		-- Pack Leader 3
	[42367] = 1,		-- Pack Leader 4
	[39076] = 1,		-- Werewolf Berserker 1
	[42377] = 1,		-- Werewolf Berserker 2
	[42378] = 1,		-- Werewolf Berserker 3
	[42379] = 1,		-- Werewolf Berserker 4
}


uespLog.CHARDATA_MINTIMESTAMP_DIFF = 60
uespLog.charDataLastSaveTimestamp = 0
uespLog.charDataLogoutSave = false


function uespLog.InitCharData()
	uespLog.SaveActionBarForCharData()
	uespLog.SaveStatsForCharData()
	--uespLog.SaveSkillsForCharData()
end


function uespLog.SaveCharData (note)
	local charData = uespLog.CreateCharData(note)
		
	if (charData == nil) then
		return false
	end
	
	uespLog.savedVars.charData.data = charData
	uespLog.savedVars.bankData.data = uespLog.CreateBankData()
	uespLog.savedVars.craftBagData.data = uespLog.CreateCraftBagData()
	
	uespLog.DebugMsg("UESP: Saved character data...")
	
	uespLog.charDataLastSaveTimestamp = GetTimeStamp()
	return true
end


function uespLog.OnLogoutAutoSaveCharData()

	if (uespLog.GetAutoSaveCharData() and not uespLog.charDataLogoutSave) then
		uespLog.SaveCharData()
		uespLog.charDataLogoutSave = true
	end
	
end


function uespLog.OnPlayerDeactivated (eventCode)
	--uespLog.DebugMsg("OnPlayerDeactivated")
	
	uespLog.ClearTargetHealthData()
end


function uespLog.OnLogoutDisallowed (eventCode, quitRequested)
	uespLog.DebugExtraMsg("OnLogoutDisallowed")
end


function uespLog.CreateCharData (note)
	local charData = uespLog.CreateBuildData(note, true, true)
	
	charData.Password = uespLog.GetCharDataPassword()
	charData.OldPassword = uespLog.GetCharDataOldPassword()

	charData.Guilds = uespLog.CreateGuildsCharData()
	charData.Inventory = uespLog.CreateInventoryData()
	charData.Research = uespLog.GetCharDataResearchInfo()

	if (uespLog.GetSaveExtendedCharData()) then
		charData.ExtendedData = 1
		charData.Recipes = uespLog.CreateCharDataRecipes()
		charData.Achievements = uespLog.CreateCharDataAchievements()
		charData.Books = uespLog.CreateCharDataBooks()
		charData.Collectibles = uespLog.CreateCharDataCollectibles()
		charData.Journal = uespLog.CreateJournalCharData()
		charData.CompletedQuests = uespLog.CreateCompletedQuestCharData()
	else
		charData.ExtendedData = 0
	end
		
		-- Only save house storage if it has been accessed on this character
	if (uespLog.savedVars.houseStorage and uespLog.savedVars.houseStorage.data) then
		charData.HouseStorage = uespLog.savedVars.houseStorage.data
	end
	
	return charData
end


function uespLog.CreateInventoryData ()
	-- BAG_BACKPACK == 1
	-- GetMaxBags()
	-- GetItemTotalCount(BAG_BACKPACK, i)
	local inventory = { }
	local i
	
	inventory.Size = GetBagSize(BAG_BACKPACK)
	inventory.TimeStamp = GetTimeStamp()
	inventory.Gold = GetCurrentMoney()
	inventory.Telvar = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
	inventory.WritVoucher = GetCarriedCurrencyAmount(CURT_WRIT_VOUCHERS)
	
	for i = 0, inventory.Size do
		inventory[#inventory + 1] = uespLog.CreateInventorySlotData(BAG_BACKPACK, i)
	end
	
	return inventory
end


function uespLog.GetCharDataHouseStorageInfo()
	local storage = { }
	local i, j
	
	if (GetCollectibleForHouseBankBag == nil or BAG_HOUSE_BANK_ONE == nil) then
		return nil
	end
		
	storage.TimeStamp = GetTimeStamp()
	storage.TotalSize = 0
	storage.TotalUsedSize = 0
	
	for i = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN do
		local box = { }
		
		box.CollectId = GetCollectibleForHouseBankBag(i)
		box.Size = GetBagSize(i)
		box.UsedSize = GetNumBagUsedSlots(i)
		
		if (box.CollectId > 0 and not IsCollectibleUnlocked(box.CollectId)) then
			box.Size = 0
		end
		
		storage.TotalSize = storage.TotalSize + box.Size
		storage.TotalUsedSize = storage.TotalUsedSize + box.UsedSize
				
		for j = 0, box.Size do
			box[#box + 1] = uespLog.CreateInventorySlotData(i, j)
		end
						
		storage[i] = box
	end
	
	return storage
end


function uespLog.OnBankOpened(event)

	if (GetBankingBag) then
		uespLog.LastBankingBag = GetBankingBag()
		
		if (IsHouseBankBag(uespLog.LastBankingBag)) then
			uespLog.savedVars.houseStorage.data = uespLog.GetCharDataHouseStorageInfo()
		end	
	end
	
end


function uespLog.OnBankClosed(event)

	if (IsHouseBankBag == nil or not IsHouseBankBag(uespLog.LastBankingBag)) then
		return
	end
	
	uespLog.savedVars.houseStorage.data = uespLog.GetCharDataHouseStorageInfo()
end


function uespLog.CreateBankData ()
	--BAG_BANK == 2
	local bankData = { }
	local i
	local bankSize = GetBagUseableSize(BAG_BANK)
			
	bankData.IsBank = 1
	bankData.Size = bankSize + GetBagUseableSize(BAG_SUBSCRIBER_BANK)
	bankData.UsedSize = GetNumBagUsedSlots(BAG_BANK) + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
	bankData.TimeStamp = GetTimeStamp()
	bankData.Gold = GetBankedMoney()
	bankData.Telvar = GetBankedCurrencyAmount(CURT_TELVAR_STONES)
	bankData.AP = GetBankedCurrencyAmount(CURT_ALLIANCE_POINTS)
	bankData.WritVouchers = GetBankedCurrencyAmount(CURT_WRIT_VOUCHERS)
	bankData.UniqueAccountName = uespLog.GetUniqueAccountName()
	bankData.Inventory = {}
	
	for i = 0, bankSize do
		bankData.Inventory[#bankData.Inventory + 1] = uespLog.CreateInventorySlotData(BAG_BANK, i)
	end
	
	for i = 0, bankSize do
		bankData.Inventory[#bankData.Inventory + 1] = uespLog.CreateInventorySlotData(BAG_SUBSCRIBER_BANK, i)
	end
	
	return bankData
end


function uespLog.CreateCraftBagData ()
	--BAG_VIRTUAL == 5
	local craftBagData = { }
	local i
	
	craftBagData.IsCraftBag = 1
	craftBagData.UsedSize = GetNumBagUsedSlots(BAG_VIRTUAL)
	craftBagData.TimeStamp = GetTimeStamp()
	craftBagData.UniqueAccountName = uespLog.GetUniqueAccountName()
	craftBagData.Inventory = {}
	
	local slotIndex = GetNextVirtualBagSlotId(nil)
	
	while (slotIndex ~= nil) do
		craftBagData.Inventory[#craftBagData.Inventory + 1] = uespLog.CreateInventorySlotData(BAG_VIRTUAL, slotIndex)
		slotIndex = GetNextVirtualBagSlotId(slotIndex)
	end
	
	return craftBagData
end


function uespLog.CreateInventorySlotData (bagId, slotIndex)
	local count = GetSlotStackSize(bagId, slotIndex)
	local itemLink = GetItemLink(bagId, slotIndex)
	local niceLink = uespLog.MakeNiceLink(itemLink)
	local isJunk = IsItemJunk(bagId, slotIndex)
	local isConsumable = IsItemLinkConsumable(itemLink)
	local extraData = ""
	
	if (count == 0 or itemLink == "") then
		return nil
	end
	
	if (isJunk) then
		extraData = extraData .. "Junk "
	end
	
	if (isConsumable) then
		extraData = extraData .. "Cons "
	end
	
	return tostring(count) .. " " .. niceLink .. " " .. extraData;
end


uespLog.PLATFORM_STRINGS = {
	[0] = "XBox",
	[1] = "PS4",
	[2] = "PC",
}


function uespLog.GetUIPlatformString (platform)
	local value = tonumber(platform)
	
	if (platform == nil) then
		value = tonumber(GetUIPlatform())
	end
	
	if (value < 0 or value > 2) then
		return tostring(value)
	end
	
	return uespLog.PLATFORM_STRINGS[value]
end


function uespLog.GetUniqueAccountName()
	local serverName = GetUniqueNameForCharacter()	
	local accountName = GetDisplayName()
	local platformName = uespLog.GetUIPlatformString()
	
	return tostring(serverName) .. platformName .. tostring(accountName)
end


function uespLog.SaveBuildData (note, forceSave)
	forceSave = forceSave or false
	local charData = uespLog.CreateBuildData(note, forceSave, false)
		
	if (charData == nil) then
		uespLog.MsgColor(uespLog.errorColor, "UESP: Did *not* save current character!")
		return false
	end
	
	local arraySize = #uespLog.savedVars.buildData.data
	uespLog.savedVars.buildData.data[arraySize + 1] = charData
	
	uespLog.Msg("UESP: Saved current character data ("..tostring(#uespLog.savedVars.buildData.data).." characters in log).")
	return true
end


function uespLog.AddBuildDataBarStat (charData, barIndex, name, value)
	charData["Bar" .. tostring(barIndex) .. ":" .. tostring(name)] = value
end


function uespLog.GetBuildDataActiveBarIndex()
	local barIndex = GetActiveWeaponPairInfo()
	
	if (uespLog.IsInOverloadState()) then
		barIndex = 3
	elseif (IsWerewolf()) then
		barIndex = 4
	end
	
	return barIndex
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
	
	charData.CharIndex, charData.CharId, charData.LocationId = uespLog.FindCharIndex()
	charData.CharName = GetUnitName("player")
	charData.AccountName = GetDisplayName()
	charData.UniqueAccountName = uespLog.GetUniqueAccountName()
	charData.UniqueName = GetUniqueNameForCharacter(charData.CharName)
	charData.Title = GetUnitTitle("player")
	charData.Race = GetUnitRace("player")
	charData.Class = GetUnitClass("player")
	charData.Gender = GetUnitGender("player")
	charData.Level = GetUnitLevel("player")
	charData.EffectiveLevel = GetUnitEffectiveLevel("player")
	charData.Zone = GetUnitZone("player")
	charData.ChampionPointsEarned = GetPlayerChampionPointsEarned()
	charData.BattleLevel = GetUnitBattleLevel("player")
	charData.BuildType = uespLog.GetCharDataBuildType()
	charData.SecondsPlayed = GetSecondsPlayed()
	charData.Latency = GetLatency()
	
	charData.ActiveWeaponBar = uespLog.GetBuildDataActiveBarIndex()
	charData.ActiveAbilityBar = charData.ActiveWeaponBar
	charData.OverloadState = 0
	
	if (uespLog.IsInOverloadState()) then
		charData.OverloadState = 1
	end
	
	charData.LightArmorCount = uespLog.CountEquippedArmor(ARMORTYPE_LIGHT)
	charData.MediumArmorCount = uespLog.CountEquippedArmor(ARMORTYPE_MEDIUM)
	charData.HeavyArmorCount = uespLog.CountEquippedArmor(ARMORTYPE_HEAVY)
	charData.ArmorTypeCount = uespLog.CountEquippedArmorTypes()
	
	charData.DaggerWeaponCount = uespLog.CountEquippedWeapons(WEAPONTYPE_DAGGER)
	charData.SwordWeaponCount = uespLog.CountEquippedWeapons(WEAPONTYPE_SWORD)
	charData.MaceWeaponCount = uespLog.CountEquippedWeapons(WEAPONTYPE_HAMMER)
	charData.AxeWeaponCount = uespLog.CountEquippedWeapons(WEAPONTYPE_AXE)
	uespLog.AddBuildDataBarStat(charData, charData.ActiveWeaponBar, "DaggerWeaponCount", charData.DaggerWeaponCount)
	uespLog.AddBuildDataBarStat(charData, charData.ActiveWeaponBar, "SwordWeaponCount", charData.SwordWeaponCount)
	uespLog.AddBuildDataBarStat(charData, charData.ActiveWeaponBar, "MaceWeaponCount", charData.MaceWeaponCount)
	uespLog.AddBuildDataBarStat(charData, charData.ActiveWeaponBar, "AxeWeaponCount", charData.AxeWeaponCount)
	
	charData.Alliance = GetAllianceName(GetUnitAlliance("player"))
	charData.AllianceRank = GetUnitAvARank("player")
	charData.AlliancePoints = GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS)	--GetAlliancePoints()	
	charData.AllianceCampaign = GetCampaignName(GetAssignedCampaignId())
	charData.AllianceGuestCampaign = GetCampaignName(GetGuestCampaignId())
	
		-- TODO: Crowns, Crown Gems?
	charData.Money = GetCurrentMoney()
	charData.BankedMoney = GetBankedMoney()
	charData.TelvarStones = GetCarriedCurrencyAmount(CURT_TELVAR_STONES)
	charData.WritVoucher = GetCarriedCurrencyAmount(CURT_WRIT_VOUCHERS)
	
	if (GetCurrencyAmount ~= nil) then
		charData.TransmuteCrystals = GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
	end
	
	charData.BankedTelvarStones = GetBankedTelvarStones()
	charData.BankedAP = GetBankedCurrencyAmount(CURT_ALLIANCE_POINTS)
	charData.BankedWritVouchers = GetBankedCurrencyAmount(CURT_WRIT_VOUCHERS)
	charData.InventorySize = GetBagSize(BAG_BACKPACK)
	charData.InventoryUsedSize = GetNumBagUsedSlots(BAG_BACKPACK) 
	charData.BankSize = GetBagUseableSize(BAG_BANK) + GetBagUseableSize(BAG_SUBSCRIBER_BANK)
	charData.BankUsedSize = GetNumBagUsedSlots(BAG_BANK) + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK)
	
	charData.Bounty = GetBounty()
	charData.AttributesUnspent = GetAttributeUnspentPoints()
	charData.AttributesHealth = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
	charData.AttributesMagicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
	charData.AttributesStamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
	charData.AttributesTotal = charData.AttributesUnspent + charData.AttributesHealth + charData.AttributesMagicka + charData.AttributesStamina
	charData.SkillPointsUnused = GetAvailableSkillPoints()
	charData.SkyShards = GetNumSkyShards()
	charData.SkyshardsFound, charData.SkyshardsTotal = uespLog.GetSkyshardsFound()

	local inventoryBonus, maxInventoryBonus, staminaBonus, maxStaminaBonus, speedBonus, maxSpeedBonus = GetRidingStats()
	charData.RidingInventory = inventoryBonus
	charData.RidingStamina = staminaBonus
	charData.RidingSpeed = speedBonus
	charData.RidingTrainingDone = 0
	
	local timeUntilTrained = GetTimeUntilCanBeTrained()
	
	if (timeUntilTrained > 0) then
		charData.RidingTrainingDone = GetTimeStamp() + math.floor(timeUntilTrained/1000)
	end
	
	charData.Stealth = GetUnitStealthState("player")
	
	if (type(uespLog.charDataLastFoodEaten) == "string") then
		uespLog.charDataLastFoodEaten = {}
	end
	
	charData.LastFoodEatenName = uespLog.charDataLastFoodEaten.name
	charData.LastFoodEatenLink = uespLog.charDataLastFoodEaten.itemLink
	charData.LastFoodEatenType = uespLog.charDataLastFoodEaten.type
	charData.LastFoodEatenDesc = uespLog.charDataLastFoodEaten.desc
	charData.LastFoodEatenLevel = uespLog.charDataLastFoodEaten.reqLevel
	charData.LastFoodEatenCP = uespLog.charDataLastFoodEaten.reqCP
		
	charData.Stats = uespLog.CreateCharDataStats(false)
	charData.Power = uespLog.CreateCharDataPower(false)
	charData.NonCombat = uespLog.CreateCharDataNonCombat()
	charData.Buffs, charData.Vampire, charData.Werewolf = uespLog.CreateCharDataBuffs()
	charData.ActionBar = uespLog.CreateCharDataActionBar()
	charData.EquipSlots = uespLog.CreateCharDataEquipSlots()
	charData.ChampionPoints = uespLog.CreateCharDataChampionPoints()
	charData.Crafting = uespLog.CreateCharDataCrafting()
			
			-- Note: This function only works if the character is actually in Werewolf form at the time
	if (IsWerewolf()) then
		charData.Werewolf = 2
	end

	charData.Skills = uespLog.CreateCharDataSkills()
	charData.SkillPointsUsed = uespLog.GetSkillPointsUsed(showDebug)
	charData.SkillPointsTotal = charData.SkillPointsUsed + charData.SkillPointsUnused	
		
	blackSkill = charData.Skills["Craft:Blacksmithing:Miner Hireling"] or { rank = 0 }
	clothSkill = charData.Skills["Craft:Clothing:Outfitter Hireling"] or { rank = 0 }
	enchantSkill = charData.Skills["Craft:Enchanting:Hireling"] or { rank = 0 }
	provSkill = charData.Skills["Craft:Provisioning:Hireling"] or { rank = 0 }
	woodSkill = charData.Skills["Craft:Woodworking:Lumberjack Hireling"] or { rank = 0 }
	
	charData['HirelingSkill:Provisioning'] = blackSkill.rank
	charData['HirelingSkill:Woodworking'] = clothSkill.rank
	charData['HirelingSkill:Blacksmithing'] = enchantSkill.rank
	charData['HirelingSkill:Enchanting'] = provSkill.rank
	charData['HirelingSkill:Clothier'] = woodSkill.rank
	
	if (uespLog.savedVars.charInfo.data.hirelingMailTime ~= nil) then
	
		if (blackSkill.rank > 0) then
			charData['HirelingMailTime:Blacksmithing'] = uespLog.savedVars.charInfo.data.hirelingMailTime[CRAFTING_TYPE_BLACKSMITHING]
		else
			charData['HirelingMailTime:Blacksmithing'] = -1
		end
		
		if (clothSkill.rank > 0) then
			charData['HirelingMailTime:Clothier'] = uespLog.savedVars.charInfo.data.hirelingMailTime[CRAFTING_TYPE_CLOTHIER]
		else
			charData['HirelingMailTime:Clothier'] = -1
		end
		
		if (enchantSkill.rank > 0) then
			charData['HirelingMailTime:Enchanting'] = uespLog.savedVars.charInfo.data.hirelingMailTime[CRAFTING_TYPE_ENCHANTING]
		else
			charData['HirelingMailTime:Enchanting'] = -1
		end
		
		if (provSkill.rank > 0) then
			charData['HirelingMailTime:Provisioning'] = uespLog.savedVars.charInfo.data.hirelingMailTime[CRAFTING_TYPE_PROVISIONING]
		else
			charData['HirelingMailTime:Provisioning'] = -1
		end
		
		if (woodSkill.rank > 0) then
			charData['HirelingMailTime:Woodworking'] = uespLog.savedVars.charInfo.data.hirelingMailTime[CRAFTING_TYPE_WOODWORKING]
		else
			charData['HirelingMailTime:Woodworking'] = -1
		end
		
	end
		
	local screenShotDeltaTime = GetTimeStamp() - uespLog.charDataLastScreenShotTimestamp 
	
	if (uespLog.charDataLastScreenShotTaken or (screenShotDeltaTime >= 0 and screenShotDeltaTime <= 200)) then
		charData.ScreenShot = uespLog.charDataLastScreenShot
		charData.ScreenShotCaption = uespLog.charDataLastScreenShotCaption
		
		uespLog.charDataLastScreenShotTaken = false
		uespLog.charDataLastScreenShotCaption = ""
		uespLog.charDataLastScreenShotTimestamp  = 0
	else
		charData.ScreenShot = ""
		charData.ScreenShotCaption = ""
	end
	
	uespLog.MergeBuildDataStats(charData)
	-- uespLog.MergeBuildDataSkills(charData)

	return charData
end


function uespLog.FindCharIndex()
	local numChars = GetNumCharacters()
	local charName = GetUnitName("player"):gsub("%^.*", "")
	
	for charIndex = 1, numChars do
		local name, gender, level, classId, raceId, alliance, charId, locationId = GetCharacterInfo(charIndex)
		name = name:gsub("%^.*", "")
		
		if (name == charName) then
			return charIndex, charId, locationId
		end
	end
	
	return -1, -1, -1
end


function uespLog.MergeBuildDataStats(charData)
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	
	for i = 1, 4 do
		if (i ~= barIndex) then 
		
			for name, value in pairs(uespLog.charData_StatsData[i]) do
				charData.Stats[name] = value
			end

		end
	end
	
end


function uespLog.MergeBuildDataSkills(charData)
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	
	for i = 1, 4 do
		if (i ~= barIndex) then 
		
			for name, skillData in pairs(uespLog.charData_SkillsData[i]) do
				local key
				
				key = "desc" .. tostring(barIndex)
				--charData.Skills[name][key] = skillData[key]
				
				key = "cost" .. tostring(barIndex)
				--charData.Skills[name][key] = skillData[key]
			end

		end
	end
	
end


function uespLog.CreateCharDataCrafting()
	local crafting = {}
	local maxStyle = GetHighestItemStyleId()

	for k = 1, maxStyle do
		local styleName = GetItemStyleName(k) or ""
		local known = uespLog.GetStyleKnown(styleName)
		
		if (styleName == "") then
			-- Do nothing
		elseif (type(known) == "table") then
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


function uespLog.CreateCharDataRecipes()
	local recipes = {}
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local knownCount = 0
	
	for recipeListIndex = 1, numRecipeLists do
		local listName, numRecipes = GetRecipeListInfo(recipeListIndex)
		
		for recipeIndex = 1, numRecipes do
			local known, name = GetRecipeInfo(recipeListIndex, recipeIndex)
	
			if (known and name ~= "") then
				local resultLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)
				local resultId = uespLog.ParseLinkItemId(resultLink)
				
				knownCount = knownCount + 1
				
				if (resultId > 0) then
					recipes["Recipe:"..tostring(resultId)] = name
				else
					recipes["Recipe"] = name
				end
			end
			
			recipeCount = recipeCount + 1
		end
	end
	
	recipes.RecipeTotalCount = recipeCount
	recipes.RecipeKnownCount = knownCount
	
	return recipes
end


function uespLog.ParseAchievementLinkId(link)

	if (link == nil or link == "") then
		return -1, 0, 0
	end
	
	local linkType, itemText, achId, achData, achTimestamp = link:match("|H(.-):(.-):(.-):(.-):(.-)|h|h")	
	
	if (achId == nil or achData == nil or achTimestamp == nil) then
		return -1, 0, 0
	end

	return achId, tonumber(achData), tonumber(achTimestamp)
end


function uespLog.CreateCharDataAchievements()
	local achievements = {}
	local numTopLevelCategories = GetNumAchievementCategories()
	
	for topLevelIndex = 1, numTopLevelCategories do
		local cateName, numCategories, numCateAchievements, earnedPoints, totalPoints, hidesPoints = GetAchievementCategoryInfo(topLevelIndex)
		
		achievements["AchievementPoints:"..tostring(topLevelIndex)] = "" .. tostring(earnedPoints) .. ", " .. tostring(totalPoints)
		
		for categoryIndex = 1, numCategories do
			local subcategoryName, numAchievements, earnedSubSubPoints, totalSubSubPoints, hidesSubSubPoints = GetAchievementSubCategoryInfo(topLevelIndex, categoryIndex)
			
			achievements["AchievementPoints:"..tostring(topLevelIndex)..":"..tostring(categoryIndex)] = "" .. tostring(earnedSubSubPoints) .. ", " .. tostring(totalSubSubPoints)
			
			earnedPoints = earnedPoints - earnedSubSubPoints
			totalPoints = totalPoints - totalSubSubPoints
			
			for achievementIndex = 1, numAchievements do
				local achId = GetAchievementId(topLevelIndex, categoryIndex, achievementIndex)
				local currentId = GetFirstAchievementInLine(achId)
				
				if (currentId == 0) then currentId = achId end
								
				while (currentId ~= nil and currentId > 0) do
					local achLink = GetAchievementLink(currentId)
					local _, progress, timestamp = uespLog.ParseAchievementLinkId(achLink)
					
					if (progress ~= 0 or timestamp ~= 0) then
						achievements["Achievement:"..tostring(currentId)] = "" .. tostring(progress) .. ", " .. tostring(timestamp)
					end
					
					currentId = GetNextAchievementInLine(currentId)
				end				
			end
		end
		
		achievements["AchievementPoints:"..tostring(topLevelIndex) .. ":0"] = "" .. tostring(earnedPoints) .. ", " .. tostring(totalPoints)
		
		for achievementIndex = 1, numCateAchievements do
			local achId = GetAchievementId(topLevelIndex, nil, achievementIndex)
			local currentId = GetFirstAchievementInLine(achId)
			
			if (currentId == 0) then currentId = achId end
				
			while (currentId ~= nil and currentId > 0) do
				local achLink = GetAchievementLink(currentId)
				local _, progress, timestamp = uespLog.ParseAchievementLinkId(achLink)
				
				if (progress ~= 0 or timestamp ~= 0) then
					achievements["Achievement:"..tostring(currentId)] = "" .. tostring(progress) .. ", " .. tostring(timestamp)
				end
				
				currentId = GetNextAchievementInLine(currentId)
			end				
		end
	end
	
	achievements.AchievementEarnedPoints = GetEarnedAchievementPoints()
	achievements.AchievementTotalPoints = GetTotalAchievementPoints()
		
	return achievements
end


function uespLog.CreateCharDataBooks()
	local books = {}
	local numCategories = GetNumLoreCategories()
	local categoryIndex
	local collectionIndex
	local bookIndex
	local totalBooks = 0
	local knownBooks = 0

	for categoryIndex = 1, numCategories do
		local catName, numCollections, categoryId = GetLoreCategoryInfo(categoryIndex)
		
		for collectionIndex = 1, numCollections do
			local colName, colDesc, numKnownBooks, numBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
			
			totalBooks = totalBooks + numBooks
			
			for bookIndex = 1, numBooks do
				local title, icon, known, bookId = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
				
				if (known) then
					known = 1
					knownBooks = knownBooks + 1
				else
					known = 0
				end
				
				if (known ~= 0) then
					books["Book:"..tostring(bookId)] = known
				end
			end
		end
	end
	
	books['TotalBooks'] = totalBooks
	books['KnownBooks'] = knownBooks
	
	return books
end



function uespLog.CreateCharDataCollectibles()
	local collect = {}
	local numCategories = GetNumCollectibleCategories()
	local categoryIndex
	local subCategoryIndex
	local collectibleIndex
	local collectibleId 
	local maxCollectibleId = 0
	local numCollectibles = 0
	local knownCollectibles = 0
		
	for categoryIndex = 1, numCategories do
		local catName, numSubCategories, numCollectibles = GetCollectibleCategoryInfo(categoryIndex)
		
		for collectibleIndex = 1, numCollectibles do
			collectibleId = GetCollectibleId(categoryIndex, nil, collectibleIndex)
			local name, desc, icon, lockedIcon, purchased = GetCollectibleInfo(collectibleId)
			
			if (purchased) then
				purchased = 1
				knownCollectibles = knownCollectibles + 1
			else
				purchased = 0
			end
			
			if (maxCollectibleId < collectibleId) then
				maxCollectibleId = collectibleId
			end
			
			if (purchased ~= 0) then
				collect["Collectible:"..tostring(collectibleId)] = purchased
			end
			
			numCollectibles = numCollectibles + 1
		end
		
		for subCategoryIndex = 1, numSubCategories do
			local subCatName, numCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subCategoryIndex)
			
			for collectibleIndex = 1, numCollectibles do
				collectibleId = GetCollectibleId(categoryIndex, subCategoryIndex, collectibleIndex)
				local name, desc, icon, lockedIcon, purchased = GetCollectibleInfo(collectibleId)
				
				if (purchased) then
					purchased = 1
					knownCollectibles = knownCollectibles + 1
				else
					purchased = 0
				end
				
				if (maxCollectibleId < collectibleId) then
					maxCollectibleId = collectibleId
				end
			
				if (purchased ~= 0) then
					collect["Collectible:"..tostring(collectibleId)] = purchased
				end
				
				numCollectibles = numCollectibles + 1
			end
		end

	end	
	
	collect['KnownCollectibles'] = knownCollectibles
	collect['NumCollectibles'] = numCollectibles
	collect['MaxCollectibleId'] = maxCollectibleId
	
	return collect
end


function uespLog.OnZoneChanged(eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId)
	uespLog.DebugExtraMsg("OnZoneChanged: "..tostring(newSubzone))
	--uespLog.DebugMsg("UESP: OnZoneChanged "..tostring(zoneName)..", "..tostring(subZoneName)..", "..tostring(newSubzone)..", "..tostring(zoneId)..", "..tostring(subZoneId))
	
	local diffTime = GetTimeStamp() - uespLog.charDataLastSaveTimestamp
	
	if (uespLog.GetAutoSaveCharData() and uespLog.GetAutoSaveZoneCharData() and diffTime > uespLog.CHARDATA_MINTIMESTAMP_DIFF) then
		uespLog.SaveCharData()
	end

end


function uespLog.OnEatDrinkItem(itemLink)
	local itemName = GetItemLinkName(itemLink)
	local itemTypeString = "unknown"
	local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel = GetItemLinkOnUseAbilityInfo(itemLink)
	local reqLevel = GetItemLinkRequiredLevel(itemLink)
	local reqCP = GetItemLinkRequiredChampionPoints(itemLink)
	local itemType = GetItemLinkItemType(itemLink)

	if (itemName == "" or itemLink == "") then
		return
	end
		
	if (itemType == 4) then
		itemTypeString = "Food"
	elseif (itemType == 12) then
		itemTypeString = "Drink"
	else
		return
	end
	
	if (type(uespLog.charDataLastFoodEaten) == "string") then
		uespLog.charDataLastFoodEaten = {}
	end
	
	uespLog.charDataLastFoodEaten.itemLink = itemLink
	uespLog.charDataLastFoodEaten.type = itemTypeString
	uespLog.charDataLastFoodEaten.desc = abilityDescription
	uespLog.charDataLastFoodEaten.reqLevel = reqLevel
	uespLog.charDataLastFoodEaten.reqCP = reqCP
	
	uespLog.savedVars.charInfo.data.lastFoodEaten = uespLog.charDataLastFoodEaten
	
	uespLog.DebugMsg("UESP: You ate/drank "..tostring(itemLink) )
end


function uespLog.OnScreenShotSaved(eventCode, directory, filename)
	uespLog.charDataLastScreenShot = tostring(directory)..""..tostring(filename)
	uespLog.charDataLastScreenShotTimestamp = GetTimeStamp()
	uespLog.charDataLastScreenShotTaken = uespLog.isTakingCharDataScreenshot
	uespLog.DebugMsg("Screenshot Saved: "..uespLog.charDataLastScreenShot)
end


function uespLog.SaveStatsForCharData()
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	local statsData = uespLog.CreateCharDataStats(true)
	local powerData = uespLog.CreateCharDataPower(true)
	
	statsData["Bar" .. tostring(barIndex) .. ":ActiveWeaponBar"] = GetActiveWeaponPairInfo()
	
	uespLog.charData_StatsData[barIndex] = statsData
	
	uespLog.savedVars.charInfo.data.stats = uespLog.charData_StatsData
end


function uespLog.CreateCharDataStats(onlyBar)
	local stats = {}
	local i
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	
	for i = -10, 100 do
		if (uespLog.CHARDATA_STATS[i] ~= nil) then
			local value = GetPlayerStat(i, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
			local name = uespLog.CHARDATA_STATS[i]
			
			if (value ~= nil) then
				
				if (not onlyBar) then
					stats[name] = value
				end
				
				stats["Bar" .. tostring(barIndex) .. ":" .. tostring(name)] = value
			end
		end
	end
	
	return stats
end


function uespLog.CreateCharDataPower(onlyBar)
	local power = {}
	local i
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	
	for i = -10, 50 do
		if (uespLog.CHARDATA_POWER[i] ~= nil) then
			local current, currentMax, effectiveMax = GetUnitPower("player", i)
			local name = uespLog.CHARDATA_POWER[i]
			
			if (currentMax ~= nil) then
			
				if (not onlyBar) then
					power[name] = currentMax
				end
				
				power["Bar" .. tostring(barIndex) .. ":" .. tostring(name)] = currentMax
			end
		end
	end
	
	return power
end




uespLog.NONCOMBAT_BONUS_NAMES = {
	[0] = 'Invalid',
	[1] = 'EnchantingLevel',
	[2] = 'AlchemyLevel',
	[3] = 'ProvisioningLevel',
	[4] = 'ProvisioningRarityLevel',
	[5] = 'ProvisioningCreateExtraFood',
	[6] = 'ProvisioningCreateExtraDrink',
	[7] = 'ProvisioningFoodDuration',
	[8] = 'ProvisioningDrinkDuration',
	[9] = 'ProvisioningHirelingLevel',
	[10] = 'AlchemyThirdSlot',
	[11] = 'AlchemyCreateExtra',
	[12] = 'EnchantingRarityLevel',
	[13] = 'AlchemyCreatePercentDiscount',
	[14] = 'AlchemyPotionDuration',
	[15] = 'EnchantingDeconstructionUpgrade',
	[16] = 'EnchantingHirelingLevel',
	[17] = 'EnchantingCraftPercentDiscount',
	[18] = 'BlacksmithingLevel',
	[19] = 'BlacksmithingShowNodes',
	[20] = 'BlacksmithingBoosterBonus',
	[21] = 'BlacksmithingExtractLevel',
	[22] = 'BlacksmithingCraftPercentDiscount',
	[23] = 'BlacksmithingResearchLevel',
	[24] = 'BlacksmithingHirelingLevel',
	[25] = 'WoodworkingLevel',
	[26] = 'WoodworkingShowNodes',
	[27] = 'WoodworkingBoosterBonus',
	[28] = 'WoodworkingExtractLevel',
	[29] = 'WoodworkingCraftPercentDiscount',
	[30] = 'WoodworkingResearchLevel',
	[31] = 'WoodworkingHirelingLevel',
	[32] = 'ClothierLevel',
	[33] = 'ClothierShowNodes',
	[34] = 'ClothierBoosterBonus',
	[35] = 'ClothierExtractLevel',
	[36] = 'ClothierCraftPercentDiscount',
	[37] = 'ClothierResearchLevel',
	[38] = 'ClothierHirelingLevel',
	[39] = 'EnchantingSlotImprovement',
	[40] = 'EnchantingShowNodes',
	[41] = 'AlchemyShowNodes',
	[42] = 'ProvisioningShowNodes',
	[43] = 'AlchemyNegativeDuration',
	[44] = 'SpellcraftingAbilitiesLearned',
	[45] = 'SpellcraftingTabletCreationTime',
	[46] = 'SpellcraftingTabletQuality',
	[47] = 'SpellcraftingFocusUltimate',
	[48] = 'SpellcraftingFocusCastTime',
	[49] = 'SpellcraftingFocusDuration',
	[50] = 'SpellcraftingFocusCheaper',
	[51] = 'SpellcraftingFocusArea',
	[52] = 'FortuneSeeker',
	[53] = 'MasterGatherer',
	[54] = 'ArmorKnowledge',
	[55] = 'TraitIdentifier',
	[56] = 'Impatience',
	[57] = 'Groom',
	[58] = 'Enlightened',
	[59] = 'Unused',
	[60] = 'Extraction',
	[61] = 'PickpocketChance',
	[62] = 'FenceSalesman',
	[63] = 'Sly',
	[64] = 'BountyDecay',
	[65] = 'HeatDecay',
	[66] = 'Haggling',
	[67] = 'WitnessRangeReduction',
	[68] = 'SecondaryWitnessRangeReduction',
	[69] = 'GuardPursuitDistanceReduction',
	[70] = 'Clemency',
	[71] = 'TimelyEscape',
	[72] = 'ClemencyArrestImmunity',
	[73] = 'MurderBountyReduction',
	[74] = 'AssaultBountyReduction',
	[75] = 'GuardKill',
	[76] = 'TelvarMultiplier',
	[77] = 'MountedAggroRadiusReduction',
	[78] = 'AvoidBladeOfWoeWitnessChance',
	[79] = 'ShadowyConnections',
}


function uespLog.CreateCharDataNonCombat()
	local nonCombat = {}

	for i = 1, NON_COMBAT_BONUS_MAX_VALUE  do
		local name = uespLog.NONCOMBAT_BONUS_NAMES[i] or tostring(i)
		nonCombat["NonCombat:"..name] = GetNonCombatBonus(i)
	end
	
	return nonCombat
end


function uespLog.CreateCharDataBuffs()
	local buffs = {}
	local numBuffs = GetNumBuffs("player")
	local i
	local isVampire = false
	local werewolfStage = 0
	
	for i = 1, numBuffs do
		local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)
	
		if (abilityId > 0) then
			local desc = GetAbilityDescription(abilityId)
			buffs[#buffs + 1] = { ["name"] = buffName, ["id"] = abilityId, ["icon"] = iconFilename, ["desc"] = desc }
		end
		
		if (string.find(buffName, "Vampirism") ~= nil) then 
			isVampire = true
		elseif (buffName == "Lycanthropy") then 
			werewolfStage = 1
		end
		
	end

	return buffs, isVampire, werewolfStage
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


function uespLog.SaveSkillsForCharData()
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	local skillsData = uespLog.CreateCharDataSkills()
	
	uespLog.charData_SkillsData[barIndex] = skillsData
	
	uespLog.savedVars.charInfo.data.skills = uespLog.charData_SkillsData
end


function uespLog.CreateCharDataSkills()
	local skills = {}
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local barIndex = uespLog.GetBuildDataActiveBarIndex()
	
	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
			local skillLineName, skillLineRank = GetSkillLineInfo(skillType, skillIndex)
			
			skills[tostring(skillTypeName)..":"..tostring(skillLineName)] = skillLineRank
			
			for abilityIndex = 1, numSkillAbilities do
				local name, texture, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local skillName = tostring(skillTypeName)..":"..tostring(skillLineName)..":"..tostring(name)
				local abilityId = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local description = GetAbilityDescription(abilityId)
				local descHeader = tostring(GetAbilityDescriptionHeader(abilityId))
				local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				local skillType = "skill"
				
				if (descHeader ~= "") then
					description = "|cffffff" .. descHeader .. "|r\n" .. description
				end
				
				if (ultimate) then
					skillType = "ultimate"
				end
				
				progressionIndex = progressionIndex or 0
				currentUpgradeLevel = currentUpgradeLevel or 0
				
				if (purchase and abilityId > 0) then
				
					if (passive and currentUpgradeLevel > 0) then
						rank = currentUpgradeLevel
						skillType = "passive"
					elseif (passive and currentUpgradeLevel == 0) then
						rank = 1
						skillType = "passive"
					elseif (progressionIndex > 0) then
						local progName, morph, skillRank = GetAbilityProgressionInfo(progressionIndex)
						rank = skillRank + morph * 4
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
							--["desc" .. tostring(barIndex)] = description, 
							["type"] = skillType, 
							["index"] = abilityIndex,
							["name"] = name, 
							["area"] = areaStr,
							["cost"] = costStr,
							--["cost" .. tostring(barIndex)] = costStr,
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
	
	return skills
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
	
	for j = 1, 4 do
		if (uespLog.charData_ActionBarData[j] ~= nil) then
			for i = 3, 8 do
				slots[i + (j-1)*100] = uespLog.charData_ActionBarData[j][i]
			end
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
	local weaponPairIndex = 1
	local timestamp = GetTimeStamp()
	
	weaponPairIndex = uespLog.GetBuildDataActiveBarIndex()
	
	if (weaponPairIndex < 1 or weaponPairIndex > 4) then
		return false
	end
	
	if (uespLog.LastSavedActionBar_WeaponPair == weaponPairIndex and timestamp - uespLog.LastSavedActionBar_TimeStamp >= uespLog.SAVEACTIONBAR_MINDELTATIME) then
		return false
	end
	
	uespLog.LastSavedActionBar_WeaponPair = weaponPairIndex
	uespLog.LastSavedActionBar_TimeStamp = timestamp
	
	uespLog.charData_ActionBarData[weaponPairIndex] = { }
	
	for i = 3, 8 do
		local texture = GetSlotTexture(i)
		local id = GetSlotBoundId(i)
		local name = GetSlotName(i)
		local description = GetAbilityDescription(id)
		local descHeader = tostring(GetAbilityDescriptionHeader(id))
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
		
		if (descHeader ~= "") then
			description = descHeader .. "\n" .. description
		end
		
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
	
	uespLog.savedVars.charInfo.data.actionBar = uespLog.charData_ActionBarData	
	
	uespLog.DebugExtraMsg("UESP: ***Current action bar saved*** barIndex "..weaponPairIndex)
end


function uespLog.HasBothActionBarsForCharData()

	if (uespLog.charData_ActionBarData[1][3] ~= nil and uespLog.charData_ActionBarData[2][3] ~= nil) then
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
	elseif (AttributesHealth >= 30) then
		return "Health"
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
	zo_callLater(uespLog.SaveActionBarForCharData, 200)
	zo_callLater(uespLog.SaveStatsForCharData, 300)
end


uespLog.lastActionSlotUpdatedCall = 0
uespLog.lastActionSlotUpdatedCount = 0

-- Note: This gets called **alot** (40-50 times) when a mob is killed with a Destruction Staff wielded
function uespLog.OnActionSlotUpdated (eventCode, slotNum)

	if (GetGameTimeMilliseconds() - uespLog.lastActionSlotUpdatedCall > 2) then
		uespLog.lastActionSlotUpdatedCount = 0	
	end
	
	uespLog.lastActionSlotUpdatedCount = uespLog.lastActionSlotUpdatedCount + 1
	uespLog.lastActionSlotUpdatedCall = GetGameTimeMilliseconds()
	
	uespLog.DebugExtraMsg(tostring(uespLog.lastActionSlotUpdatedCount)..": OnActionSlotUpdated "..tostring(slotNum)..":"..tostring(GetGameTimeMilliseconds()))
	
	--local data = uespLog.savedVars.tempData.data
	--local timestamp = GetGameTimeMilliseconds()
	--data[#data+1] = "EVENT_ACTION_SLOT_UPDATED "..tostring(slotNum).." "..tostring(timestamp)
	
	--uespLog.SaveActionBarForCharData()
end


function uespLog.OnActiveQuickSlotChanged (eventCode, slotId)
	--uespLog.DebugMsg("OnActiveQuickSlotChanged "..tostring(slotId))
	
	zo_callLater(uespLog.SaveActionBarForCharData, 200)
	zo_callLater(uespLog.SaveStatsForCharData, 300)
end


function uespLog.OnActiveWeaponPairChanged (eventCode, activeWeaponPair, locked)
	uespLog.DebugExtraMsg("OnActiveWeaponPairChanged "..tostring(activeWeaponPair))
	
	zo_callLater(uespLog.SaveActionBarForCharData, 400)
	zo_callLater(uespLog.SaveStatsForCharData, 500)
	
		-- Far too slow
	--uespLog.SaveSkillsForCharData()
end


function uespLog.ClearCharData()
	uespLog.savedVars.charData.data = { }
	uespLog.savedVars.bankData.data = { }
	uespLog.savedVars.craftBagData.data = { }
	uespLog.Msg("Cleared all character data.")
end


function uespLog.ClearBuildData()
	uespLog.savedVars.buildData.data = { }
	uespLog.Msg("Cleared logged character build data.")
end


function uespLog.Command_SaveBuildData (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%S+") do table.insert(cmdWords, word) end
	
	firstCmd = string.lower(cmdWords[1]) or ""
	
	if (firstCmd == "help" or cmd == "" or (firstCmd == "forcesave" and #cmdWords <= 1)) then
		uespLog.Msg("Saves current character build data to the log file (or '/usb').")
		uespLog.Msg(".     /usb help          Shows basic command format")
		uespLog.Msg(".     /usb reset          Clears character log")
		uespLog.Msg(".     /usb status          Shows current character log status")
		uespLog.Msg(".     /usb [buildName]       Saves current character with given build name")
		uespLog.Msg(".     /usb forcesave [name]     Saves character ignoring any errors")
		uespLog.Msg(".     /usb screenshot [caption]  Takes a 'nice' screenshot of your character")
	elseif (firstCmd == "status") then
		uespLog.Msg("Currently there are "..tostring(#uespLog.savedVars.buildData.data).." character builds saved in log.")
	elseif (firstCmd == "reset" or firstCmd == "clear") then
		uespLog.ClearBuildData()
	elseif (firstCmd == "forcesave") then
		cmdWords[1] = nil
		buildName = table.concat(cmdWords, ' ')
		uespLog.SaveBuildData(buildName, true)
	elseif (firstCmd == "ss" or firstCmd == "screenshot") then
		local caption = uespLog.trim(cmd:sub(12))
		
		if (firstCmd == "ss") then
			caption = uespLog.trim(cmd:sub(4))
		end
		
		uespLog.TakeCharDataScreenshot(caption)
	else
		uespLog.SaveBuildData(cmd, false)
	end
	
end


function uespLog.TakeCharDataScreenshot(caption)
	caption = caption or ""

	if (uespLog.isTakingCharDataScreenshot) then
		return false
	end
	
	uespLog.Msg("UESP:Taking character screenshot in 1 sec...don't touch anything!")
	
	uespLog.isTakingCharDataScreenshot = true
	uespLog.charDataLastScreenShotCaption = caption

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


function uespLog.GetSkillPointsUsed(showDebug)
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local totalSkillPoints = 0
	
	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
			local skillLineName, skillLineRank, discovered = GetSkillLineInfo(skillType, skillIndex)
			
			if (discovered) then
				
				for abilityIndex = 1, numSkillAbilities do
					local name, texture, rank, passive, ultimate, purchase, progressionIndex, rankIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
					local abilityId = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
					local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
					local isFree = uespLog.FREE_SKILLS[abilityId] ~= nil

					--uespLog.DebugMsg(name..": "..abilityId..", "..skillType..":"..skillIndex..":"..abilityIndex)
					
					progressionIndex = progressionIndex or 0
					currentUpgradeLevel = currentUpgradeLevel or 0
					
					if (purchase and abilityId > 0) then
					
						if (passive and currentUpgradeLevel > 0) then
							totalSkillPoints = totalSkillPoints + currentUpgradeLevel
							
							if (showDebug) then
								uespLog.DebugMsg(name..": "..currentUpgradeLevel.." skill points from passive")
							end
							
							if (isFree) then
								totalSkillPoints = totalSkillPoints - 1
								
								if (showDebug) then
									uespLog.DebugMsg(name.." Ignoring first passive skill point!")
								end
							end
							
						elseif (passive and currentUpgradeLevel == 0) then
							totalSkillPoints = totalSkillPoints + 1
							
							if (showDebug) then
								uespLog.DebugMsg(name..": 1 skill point from passive")
							end
							
							if (isFree) then
								totalSkillPoints = totalSkillPoints - 1
								
								if (showDebug) then
									uespLog.DebugMsg(name..": Ignoring first passive skill point!")
								end
							end
							
						elseif (progressionIndex > 0) then
							local name, morph, skillRank = GetAbilityProgressionInfo(progressionIndex)
							local points = 1 + math.ceil(morph/2)
							totalSkillPoints = totalSkillPoints + points
							
							if (showDebug) then
								uespLog.DebugMsg(name..": "..points.." skill points from active")
							end
							
							if (isFree) then
								totalSkillPoints = totalSkillPoints - 1
								
								if (showDebug) then
									uespLog.DebugMsg(name..": Ignoring first active skill point!")
								end
							end
						end
					end
				end
			end
		end
	
	end
	
	return totalSkillPoints
end


function uespLog.MergeTables(table1, table2)

	for k,v in pairs(table2) do 
		table1[k] = v
	end
	
	return table1
end


function uespLog.GetCharDataResearchInfo()
	local researchData = {}
	
	local researchData1 = uespLog.GetCharDataResearchInfoCraftType(CRAFTING_TYPE_CLOTHIER)
	local researchData2 = uespLog.GetCharDataResearchInfoCraftType(CRAFTING_TYPE_BLACKSMITHING)
	local researchData3 = uespLog.GetCharDataResearchInfoCraftType(CRAFTING_TYPE_WOODWORKING)
	local researchData4 = uespLog.GetCharDataResearchInfoCraftType(CRAFTING_TYPE_JEWELRYCRAFTING)
	
	local researchTrait1 = uespLog.GetCharDataResearchTraits(CRAFTING_TYPE_CLOTHIER)
	local researchTrait2 = uespLog.GetCharDataResearchTraits(CRAFTING_TYPE_BLACKSMITHING)
	local researchTrait3 = uespLog.GetCharDataResearchTraits(CRAFTING_TYPE_WOODWORKING)
	local researchTrait4 = uespLog.GetCharDataResearchTraits(CRAFTING_TYPE_JEWELRYCRAFTING)
	
	uespLog.MergeTables(researchData, researchData1)
	uespLog.MergeTables(researchData, researchData2)
	uespLog.MergeTables(researchData, researchData3)
	uespLog.MergeTables(researchData, researchData4)
	uespLog.MergeTables(researchData, researchTrait1)
	uespLog.MergeTables(researchData, researchTrait2)
	uespLog.MergeTables(researchData, researchTrait3)
	uespLog.MergeTables(researchData, researchTrait4)
	
	researchData["Timestamp"] = GetTimeStamp()
	
	return researchData
end


function uespLog.GetCharDataResearchTraits(craftingType)
	local TradeskillName = uespLog.GetCraftingName(craftingType)
	local numLines = GetNumSmithingResearchLines(craftingType)
	local totalAllTraits = 0
	local totalKnownTraits = 0
	local researchData = {}
	local varName = ""
	
	if (numLines == 0) then
		return researchData
	end
	
	for researchLineIndex = 1, numLines do
		local slotName, _, numTraits, _ = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
		local knownTraits = {}
		local unknownTraits = {}
		local totalTraits = 0
		local knownTraitCount = 0
		local unknownTraitCount = 0
		local researchTrait = ""
		
		for traitIndex = 1, numTraits do
			local duration, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
			local traitType, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			local traitName = uespLog.GetItemTraitName(traitType)
			totalTraits = totalTraits + 1
			
			if (known) then
				knownTraits[traitIndex] = traitName
				knownTraitCount = knownTraitCount + 1
			elseif (duration ~= nil ) then  -- Being researched
				researchTrait = "["..traitName.."]"
				knownTraits[traitIndex] = "["..traitName.."]"
				unknownTraitCount = unknownTraitCount + 1
			else
				unknownTraits[traitIndex] = traitName
				unknownTraitCount = unknownTraitCount + 1
			end
		end
		
		totalAllTraits = totalAllTraits + totalTraits
		totalKnownTraits = totalKnownTraits + knownTraitCount
		varName = TradeskillName..":Trait:"..tostring(slotName)
		
		if (unknownTraitCount == 0) then
			researchData[varName] = "All traits known"
		elseif (knownTraitCount == 0) then
			researchData[varName] = "No traits known"
		else
			local knownString = uespLog.implode(knownTraits, ", ")
			local unknownString = uespLog.implode(unknownTraits, ", ") .. " " .. researchTrait
			researchData[varName] = knownString .. " ("..tostring(knownTraitCount).."/"..tostring(totalTraits)..")"
			researchData[varName..":Unknown"] = unknownString .. " ("..tostring(unknownTraitCount).."/"..tostring(totalTraits)..")"
		end
		
		researchData[varName..":Known"] = knownTraitCount
		researchData[varName..":Total"] = totalTraits
	end
	
	varName = TradeskillName..":Trait"
	researchData[varName..":Known"] = totalKnownTraits
	researchData[varName..":Total"] = totalAllTraits
	return researchData
end


function uespLog.GetCharDataResearchInfoCraftType(craftingType)
	local TradeskillName = uespLog.GetCraftingName(craftingType)
	local numLines = GetNumSmithingResearchLines(craftingType)
	local maxSimultaneousResearch = GetMaxSimultaneousSmithingResearch(craftingType)
	local researchCount = 0
	local researchData = {}
	
	if (numLines == 0 or maxSimultaneousResearch == 0) then
		return researchData
	end
	
	for researchLineIndex = 1, numLines do
		local slotName, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
		
		for traitIndex = 1, numTraits do
			local duration, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			local traitName = uespLog.GetItemTraitName(traitType)
			
			if (duration ~= nil) then
				researchCount = researchCount + 1
				researchData[TradeskillName .. ":Trait" .. tostring(researchCount)] = traitName
				researchData[TradeskillName .. ":Item" .. tostring(researchCount)] = slotName
				researchData[TradeskillName .. ":Time" .. tostring(researchCount)] = timeRemainingSecs
			end
		end
	end
	
	if (researchCount < maxSimultaneousResearch) then
		local slotsOpen = maxSimultaneousResearch - researchCount
		researchData[TradeskillName .. ":Open"] = slotsOpen
	else
		researchData[TradeskillName .. ":Open"] = 0
	end

	return researchData
end


SLASH_COMMANDS["/uespsavebuild"] = uespLog.Command_SaveBuildData
SLASH_COMMANDS["/uespbuild"] = uespLog.Command_SaveBuildData


SLASH_COMMANDS["/uespskillpoints"] = function (cmd)
	local skillPointsUsed = uespLog.GetSkillPointsUsed(cmd == "debug")
	local skillPointsUnused = GetAvailableSkillPoints()
	local totalPoints = skillPointsUsed + skillPointsUnused
	local skyShards = GetNumSkyShards()
	local foundSkyshards, totalSkyshards = uespLog.GetSkyshardsFound()
	
	uespLog.Msg("You have used "..tostring(skillPointsUsed).." skill points, "..tostring(skillPointsUnused).." unused skill points ("..totalPoints.." total) and "..tostring(skyShards).." skyshards.")
	uespLog.Msg("You found a total of "..tostring(foundSkyshards).." out of "..tostring(totalSkyshards).." skyshards!");
end


function uespLog.UpdateCharDataPassword(password1, password2)
	password1 = uespLog.trim(password1)
	password2 = uespLog.trim(password2)

	if (password1 == nil or password1 == "") then
		uespLog.ShowCharDataPassword()
		return
	elseif (password1:lower() == "clear") then
		uespLog.SetCharDataPassword("")
	else
		uespLog.SetCharDataPassword(password1)
	end
	
	uespLog.ShowCharDataPassword()
end


function uespLog.ShowCharDataPassword()
	local currentPassword = uespLog.GetCharDataPassword()
	
	if (currentPassword == "") then
		uespLog.Msg("You have no char data password!")
	else
		uespLog.Msg("Current char data password is '"..tostring(uespLog.GetCharDataPassword()).."'.")
	end
		
end


function uespLog.IsInOverloadState()
	local playerClass = GetUnitClass('player')
	local numBuffs = GetNumBuffs("player")
	local i
	
	if (playerClass ~= "Sorcerer") then
		return false
	end
	
	for i = 1, numBuffs do
		local buffName = GetUnitBuffInfo("player", i)
	
		if (buffName == "Power Overload" or buffName == "Overload" or buffName == "Energy Overload") then
			return true
		end
	end
	
	return false
end


function uespLog.LogCompletedQuestData()
	local data = uespLog.savedVars.tempData.data
	local questId = GetNextCompletedQuestId(nil)
	
	while (questId ~= nil) do
		local name, questType = GetCompletedQuestInfo(questId)
		local zoneName, objectiveName, zoneIndex, poiIndex = GetCompletedQuestLocationInfo(questId)
		
		data[#data + 1] = ""..questId..",'" .. name .. "',"..questType..",'"..zoneName.."','"..objectiveName.."'"
	
		questId = GetNextCompletedQuestId(questId)
	end
end


function uespLog.CreateJournalCharData()
	local journalData = {}
	local numQuests = GetNumJournalQuests()
	local journalIndex
	local conditionIndex
	
	journalData["NumJournalQuests"] = numQuests
	
	for journalIndex = 1, numQuests do
		journalData["Journal:"..journalIndex..":Name"] = GetJournalQuestName(journalIndex)
		journalData["Journal:"..journalIndex..":Type"] = GetJournalQuestType(journalIndex)
		journalData["Journal:"..journalIndex..":Repeat"] = GetJournalQuestRepeatType(journalIndex)
		journalData["Journal:"..journalIndex..":Zone"] = GetJournalQuestLocationInfo(journalIndex)
		journalData["Journal:"..journalIndex..":Tasks"] = ""
		
		local questName, backgroundText, activeStepText, activeStepType, overrideText = GetJournalQuestInfo(journalIndex)
		journalData["Journal:"..journalIndex..":Text"] = backgroundText
		journalData["Journal:"..journalIndex..":ActiveText"] = activeStepText
		journalData["Journal:"..journalIndex..":ActiveType"] = activeStepType
		
		local numSteps = GetJournalQuestNumSteps(journalIndex)
		
		if (overrideText ~= "") then
			journalData["Journal:"..journalIndex..":Tasks"] = tostring(overrideText)
		elseif (numSteps >= 1) then
			local numConditions = GetJournalQuestNumConditions(journalIndex, 1)
			local taskText = ""
			
			for conditionIndex = 1, numConditions do
				local text, current, maxCount, isFail, isComplete, isCreditShared, isVisible = GetJournalQuestConditionInfo(journalIndex, stepIndex, conditionIndex)		
				
				if (isVisible) then
					if (taskText ~= "") then
						taskText = taskText .. "|"
					end
					
					taskText = taskText .. text
				end
				
			end
			
			taskText = taskText:gsub("•", "~*")			
			journalData["Journal:"..journalIndex..":Tasks"] = taskText
		end

	end
	
	return journalData
end


function uespLog.CreateCompletedQuestCharData()
	local questData = {}
	local questId = GetNextCompletedQuestId(nil)
	local questCount = 0
	
	while (questId ~= nil) do
		local name, questType = GetCompletedQuestInfo(questId)
		local zoneName, objectiveName, zoneIndex, poiIndex = GetCompletedQuestLocationInfo(questId)
		
		questCount = questCount + 1
		questData["Quest:"..questCount] = tostring(questId).."|"..tostring(name).."|"..tostring(questType).."|"..tostring(zoneName).."|"..tostring(objectiveName)
		
		questId = GetNextCompletedQuestId(questId)
	end	
	
	questData["NumCompletedQuests"] = questCount
	
	return questData
end


function uespLog.CreateGuildsCharData()
	local guildData = {}
	local numGuilds = GetNumGuilds()
	local guildIndex
	
	guildData["NumGuilds"] = numGuilds
	
	for guildIndex = 1, numGuilds do
		local name = GetGuildName(guildIndex)
		local memberIndex = GetPlayerGuildMemberIndex(guildIndex)
		local _, _, rankIndex, playerStatus = GetGuildMemberInfo(guildIndex, memberIndex)
		
		guildData["Guild:"..tostring(guildIndex)] = name
		guildData["Guild:"..tostring(guildIndex)..":Members"] = GetNumGuildMembers(guildIndex)
		guildData["Guild:"..tostring(guildIndex)..":Rank"] = GetGuildRankCustomName(guildIndex, rankIndex)
		guildData["Guild:"..tostring(guildIndex)..":Founded"] = GetGuildFoundedDate(guildIndex)
	end

	return guildData
end