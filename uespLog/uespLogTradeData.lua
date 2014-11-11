-- uespLogTradeData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the tradeskill data portion of the add-on


uespLog.iconControls = { }
uespLog.styleIconControls = { }
uespLog.tradeRowClicked = nil
uespLog.equippedRowClicked = nil
uespLog.lastPopupLink = nil

uespLog.TRADE_NORMAL_COLOR = { 1, 1, 1 }
uespLog.TRADE_FINE_COLOR = { 0.18, 0.78, 0.02 }
uespLog.TRADE_SUPERIOR_COLOR = { 0.23, 0.55, 1 }
uespLog.TRADE_EPIC_COLOR = { 0.63, 0.18, 0.97 }
uespLog.TRADE_KNOWN_COLOR = { 1, 1, 1 }
uespLog.TRADE_UNKNOWN_COLOR = { 1, 0.2, 0.2 }
uespLog.TRADE_ORNATE_COLOR = { 1, 1, 0.25 }
uespLog.TRADE_INTRICATE_COLOR = { 0, 1, 1 }
uespLog.TRADE_STYLE_COLOR = { 1, 0.75, 0.25 }

uespLog.TRADE_UNKNOWN_TEXTURE = "uespLog\\images\\unknown.dds"
uespLog.TRADE_KNOWN_TEXTURE = "uespLog\\images\\known.dds"
uespLog.TRADE_ORNATE_TEXTURE = "/esoui/art/tradinghouse/tradinghouse_sell_tabicon_disabled.dds"
uespLog.TRADE_INTRICATE_TEXTURE = "/esoui/art/progression/progression_indexicon_guilds_up.dds"
--uespLog.TRADE_ORNATE_TEXTURE = "uespLog\\images\\ornate.dds"
--uespLog.TRADE_INTRICATE_TEXTURE = "uespLog\\images\\intricate.dds"

uespLog.STYLE_ICON_UNKNOWN = "uespLog\\images\\unknown.dds"


uespLog.ALT_STYLE_ICON_DATA = {
	[ITEMSTYLE_RACIAL_NORD]  		= "uespLog\\images\\stylenord.dds",  		-- Corundum, Nord, 33256, ITEMSTYLE_RACIAL_NORD=5, /esoui/art/icons/crafting_metals_corundum.dds
	[ITEMSTYLE_RACIAL_REDGUARD]  	= "uespLog\\images\\styleredguard.dds",		-- Starmetal, Redguard, 33258, ITEMSTYLE_RACIAL_REDGUARD=2, /esoui/art/icons/crafting_medium_armor_sp_names_002.dds
	[ITEMSTYLE_RACIAL_ORC]  		= "uespLog\\images\\styleorc.dds",			-- Manganese, Orc, 33257, ITEMSTYLE_RACIAL_ORC=3, /esoui/art/icons/crafting_metals_manganese.dds
	[ITEMSTYLE_RACIAL_KHAJIIT]  	= "uespLog\\images\\stylekhajiit.dds",		-- Moonstone, Khajiit, 33255, ITEMSTYLE_RACIAL_KHAJIIT=9, /esoui/art/icons/crafting_smith_plug_sp_names_001.dds
	[ITEMSTYLE_RACIAL_HIGH_ELF]  	= "uespLog\\images\\stylealtmer.dds",		-- Adamantite, Altmer, 33252, ITEMSTYLE_RACIAL_HIGH_ELF=7, /esoui/art/icons/grafting_gems_adamantine.dds
	[ITEMSTYLE_RACIAL_WOOD_ELF]  	= "uespLog\\images\\stylebosmer.dds",		-- Bone, Bosmer, 33194, ITEMSTYLE_RACIAL_WOOD_ELF=8, /esoui/art/icons/crafting_gems_daedra_skull.dds
	[ITEMSTYLE_RACIAL_ARGONIAN]  	= "uespLog\\images\\styleargonian.dds",		-- Flint, Argonian, 33150, ITEMSTYLE_RACIAL_ARGONIAN=6, /esoui/art/icons/crafting_smith_potion_standard_f_002.dds
	[ITEMSTYLE_RACIAL_BRETON]  		= "uespLog\\images\\stylebreton.dds",		-- Molybdenum, Breton, 33251, ITEMSTYLE_RACIAL_BRETON=1, /esoui/art/icons/crafting_metals_molybdenum.dds
	[ITEMSTYLE_RACIAL_DARK_ELF] 	= "uespLog\\images\\styledunmer.dds",		-- Obsidian, Dunmer, 33253, ITEMSTYLE_RACIAL_DARK_ELF=4, /esoui/art/icons/crafting_metals_graphite.dds
	[ITEMSTYLE_ENEMY_PRIMITIVE] 	= "uespLog\\images\\styleprimal.dds",		-- Argentum, Primal, 46150, ITEMSTYLE_ENEMY_PRIMITIVE=19, /esoui/art/icons/crafting_metals_argentum.dds
	[ITEMSTYLE_RACIAL_IMPERIAL]  	= "uespLog\\images\\styleimperial.dds",		-- Nickel, Imperial, 33254, ITEMSTYLE_RACIAL_IMPERIAL=34, /esoui/art/icons/crafting_heavy_armor_sp_names_001.dds
	[ITEMSTYLE_AREA_REACH]  		= "uespLog\\images\\stylebarbaric.dds",		-- Copper, Barbaric, 46149, ITEMSTYLE_AREA_REACH=17, /esoui/art/icons/crafting_smith_potion_standard_f_001.dds
	[ITEMSTYLE_ENEMY_DAEDRIC] 		= "uespLog\\images\\styledaedric.dds",		-- Daedra Heart, Daedric, 46151, ITEMSTYLE_ENEMY_DAEDRIC=20, /esoui/art/icons/crafting_walking_dead_mort_heart.dds
	[ITEMSTYLE_AREA_ANCIENT_ELF] 	= "uespLog\\images\\styleancientelf.dds",	-- Palladium, Ancient Elf, 46152, ITEMSTYLE_AREA_ANCIENT_ELF=15, /esoui/art/icons/crafting_ore_palladuim.dds
	[ITEMSTYLE_AREA_DWEMER] 	    = "uespLog\\images\\styledwemer.dds",		-- Dwemer Frame, Dwemer, 57587, ITEMSTYLE_AREA_DWEMER=14, /esoui/art/icons/crafting_dwemer_shiny_tube.dds
	--[ITEMSTYLE_AREA_YOKUDAN] = "", --Yokudan
}


uespLog.STYLE_ICON_DATA = {
	[ITEMSTYLE_RACIAL_NORD]  		= "/esoui/art/icons/crafting_metals_corundum.dds",
	[ITEMSTYLE_RACIAL_REDGUARD]  	= "/esoui/art/icons/crafting_medium_armor_sp_names_002.dds",
	[ITEMSTYLE_RACIAL_ORC]  		= "/esoui/art/icons/crafting_metals_manganese.dds",
	[ITEMSTYLE_RACIAL_KHAJIIT]  	= "/esoui/art/icons/crafting_smith_plug_sp_names_001.dds",
	[ITEMSTYLE_RACIAL_HIGH_ELF]  	= "/esoui/art/icons/grafting_gems_adamantine.dds",
	[ITEMSTYLE_RACIAL_WOOD_ELF]  	= "/esoui/art/icons/crafting_gems_daedra_skull.dds",
	[ITEMSTYLE_RACIAL_ARGONIAN]  	= "/esoui/art/icons/crafting_smith_potion_standard_f_002.dds",
	[ITEMSTYLE_RACIAL_BRETON]  		= "/esoui/art/icons/crafting_metals_molybdenum.dds",
	[ITEMSTYLE_RACIAL_DARK_ELF] 	= "/esoui/art/icons/crafting_metals_graphite.dds",
	[ITEMSTYLE_ENEMY_PRIMITIVE] 	= "/esoui/art/icons/crafting_metals_argentum.dds",
	[ITEMSTYLE_RACIAL_IMPERIAL]  	= "/esoui/art/icons/crafting_heavy_armor_sp_names_001.dds",
	[ITEMSTYLE_AREA_REACH]  		= "/esoui/art/icons/crafting_smith_potion_standard_f_001.dds",
	[ITEMSTYLE_ENEMY_DAEDRIC] 		= "/esoui/art/icons/crafting_walking_dead_mort_heart.dds",
	[ITEMSTYLE_AREA_ANCIENT_ELF] 	= "/esoui/art/icons/crafting_ore_palladuim.dds",
	[ITEMSTYLE_AREA_DWEMER] 	    = "/esoui/art/icons/crafting_dwemer_shiny_tube.dds",
	--[ITEMSTYLE_AREA_YOKUDAN] = "", --Yokudan
}


uespLog.PROVISION_ICONS = {
	[1]   = "uespLog\\images\\newtrade1.dds",
	[2]   = "uespLog\\images\\newtrade2.dds",
	[3]   = "uespLog\\images\\newtrade3.dds",
	[4]   = "uespLog\\images\\newtrade4.dds",
	[5]   = "uespLog\\images\\newtrade5.dds",
	[6]   = "uespLog\\images\\newtrade6.dds",
	[100] = "uespLog\\images\\newspecial1.dds",
	[101] = "uespLog\\images\\newspecial2.dds",
}


uespLog.PROVISION_COLORS = {
	[1]   = uespLog.TRADE_NORMAL_COLOR,
	[2]   = uespLog.TRADE_NORMAL_COLOR,
	[3]   = uespLog.TRADE_NORMAL_COLOR,
	[4]   = uespLog.TRADE_NORMAL_COLOR,
	[5]   = uespLog.TRADE_NORMAL_COLOR,
	[6]   = uespLog.TRADE_NORMAL_COLOR,
	[100] = uespLog.TRADE_SUPERIOR_COLOR,
	[101] = uespLog.TRADE_EPIC_COLOR,
}


-- Ingredients to not include in autoloot checks (always loot)
uespLog.AUTOLOOT_ALWAYS_INGREDIENTS = {
	[28606] = 1,		-- Plump worms
	[34311] = 1,	 	-- Crawdad
}

-- 1-6 = Provisioning level
-- 100 = Superior ingredient
-- 101 = Epic ingredient
uespLog.INGREDIENT_DATA = {
	[34329] = 1,	--aged meat
	[40261] = 2, 	--amber malt
	[28639] = 3,	--ash millet
	[27003] = 5,	--baker's flour
	[27057] = 101, 	--barley
	[40273] = 4, 	--barley mash
	[33753] = 1,	--battaglir weeds
	[33754] = 1,	--bear haunch
	[34321] = 4,	--beef
	[34348] = 6,	--bervez fruit
	[33774] = 3,	--black tea
	[26987] = 2,	--broth
	[40260] = 1,	--brown malt
	[27002] = 4,	--cake flour
	[40268] = 4,	--camaralet grapes
	[27053] = 100,	--canis root
	[33752] = 1,	--capon meat
	[40262] = 3,	--caramalt
	[28609] = 3,	--chaurus meat
	[29030] = 2,	--comberry
	[33756] = 2,	--combwort
	[27049] = 100,	--concord grapes
	[26974] = 2,	--cooking fat
	[40270] = 1,	--corn mash
	[34311] = 3, 	--crawdad
	[34345] = 4,	--crystal berry
	[33771] = 2,	--dark bile
	[33773] = 3,	--desert heather
	[28636] = 1,	--dragon's tongue-sap
	[26966] = 1,	--drippings
	[34330] = 1,	--dusk beetle
	[45523] = 6,	--emperor grapes
	[26977] = 5,	--fatback
	[33755] = 3,	--flank steak
	[28610] = 3,	--frog legs
	[27100] = 101,	--garlic
	[26990] = 5,	--glace viande
	[34334] = 2,	--glitter rock
	[34308] = 2,	--goat bits
	[28603]	= 1,	--goat meat
	[45524] = 100,	--golden malt
	[40266] = 2,	--grasa grapes
	[27056] = 100,	--groose berry
	[34305] = 1,	--guar eggs
	[27043] = 100,	--hallertau hops
	[34324] = 6,	--honey comb
	[27035] = 101,	--hops
	[33758] = 3,	--horker meat
	[27004] = 6,	--imperial flour
	[45522] = 6,	--imperial mash
	[26998] = 6, 	--imperial stock
	[33768] = 1,	--iron peat
	[34349] = 6,	--jazbay grapes (1)
	[27051] = 101,	--jazbay grapes (2)
	[27052] = 100,	--juniper berry
	[26989] = 4,	--jus
	[34346] = 5,	--kaveh beans
	[28604] = 1, 	--kwama eggs
	[40267] = 3,	--lado grapes
	[26976] = 4,	--lard
	[34307] = 1,	--liver
	[26999] = 1,	--meal
	[27000] = 2,	--milled flour
	[34335] = 3,	--molasses
	[34309] = 2,	--moon sugar
	[34347] = 5,	--mountain berries
	[34323] = 5,	--mudcrab meat
	[40276] = 1,	--mutton flank
	[40272] = 3,	--oat mash
	[27059] = 101,	--oats
	[27064] = 100,	--onion
	[33772] = 2,	--orc hops
	[26962] = 101,	--pepper
	[34333] = 2,	--pig's milk
	[26978] = 6,	--pinguis
	[28608] = 2,	--plump maggots
	[28607] = 2,	--plump rodent toes
	[28606] = 1,	--plump worms
	[34304] = 1,	--pork
	[27063] = 101,	--potato
	[27050] = 100,	--raspberry
	[27058] = 100,	--red wheat
	[40269] = 5,	--ribier grapes
	[27060] = 100,	--rice
	[40274] = 100,	--rice mash
	[34331] = 1,	--ripe apple
	[28638] = 3,	--river grapes
	[27044] = 101,	--saaz hops
	[26954] = 100,	--salt
	[34312] = 3,	--saltrice
	[28605] = 1,	--scuttle meat
	[34322] = 4,	--shank
	[33767] = 1,	--shornhelm grapes
	[27001] = 3,	--sifted flour
	[28632] = 1,	--snake slime
	[28634] = 1,	--snake venom
	[28666] = 100,	--snowberry
	[34336] = 3,	--spring essence
	[26988] = 3,	--stock
	[26975] = 3,	--suet
	[28637] = 2,	--sujamma berries
	[34306] = 1,	--sweetmeats
	[33769] = 1,	--tangerine
	[26986] = 1,	--thin broth
	[26802] = 101,	--tomato
	[33757] = 2,	--venison
	[33770] = 1,	--wasp squeezings
	[40263] = 4,	--wheat malt
	[40271] = 2,	--wheat mash
	[27048] = 101,	--white grapes
	[40264] = 5,	--white malt
	[28635] = 1,	--wild honey
	[40265] = 1,	--wine grapes
	[34332] = 1,	--wisp floss
}


function uespLog.InitTradeData()
	uespLog.SetupInventoryHooks()
end


function uespLog.SetupInventoryHooks()
	uespLog.SetupInventoryListHooks(PLAYER_INVENTORY.inventories[1].listView, {GetItemLink, "bagId", "slotIndex"})
	uespLog.SetupInventoryListHooks(PLAYER_INVENTORY.inventories[3].listView, {GetItemLink, "bagId", "slotIndex"})
	uespLog.SetupInventoryListHooks(PLAYER_INVENTORY.inventories[4].listView, {GetItemLink, "bagId", "slotIndex"})
	uespLog.SetupInventoryListHooks(LOOT_WINDOW.list, {GetLootItemLink, "lootId", nil})
	uespLog.SetupInventoryListHooks(SMITHING.deconstructionPanel.inventory.list, {GetItemLink, "bagId", "slotIndex"})
	--uespLog.SetupInventoryListHooks(SMITHING.improvementPanel.inventory.list, {GetItemLink, "bagId", "slotIndex"})
	uespLog.SetupInventoryListHooks(STORE_WINDOW.list, {GetStoreItemLink, "slotIndex", nil})
	uespLog.SetupInventoryListHooks(BUY_BACK_WINDOW.list, {GetBuybackItemLink, "slotIndex", nil})
	uespLog.SetupInventoryListHooks(REPAIR_WINDOW.list, {GetItemLink, "bagId", "slotIndex"})
	
	ZO_ScrollList_RefreshVisible(ZO_PlayerInventoryBackpack)
	ZO_ScrollList_RefreshVisible(ZO_PlayerBankBackpack)
	ZO_ScrollList_RefreshVisible(ZO_GuildBankBackpack)	
	ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack)
	
	ZO_PreHookHandler(ItemTooltip, "OnShow", function() zo_callLater(function() uespLog.AddCraftDetailsToToolTipRow(moc()) end, 100) end)
	ZO_PreHookHandler(ItemTooltip, "OnUpdate", function() return uespLog.AddCraftDetailsToToolTipRow(moc()) end)
	ZO_PreHookHandler(ItemTooltip, "OnHide", function() uespLog.tradeRowClicked = nil return false end )
	
	ZO_PreHookHandler(PopupTooltip, "OnShow", function() zo_callLater(function() uespLog.AddCraftDetailsToPopupToolTip() end, 100) end)
	ZO_PreHookHandler(PopupTooltip, "OnUpdate", function() return uespLog.AddCraftDetailsToPopupToolTip() end)
	ZO_PreHookHandler(PopupTooltip, "OnHide", function() uespLog.lastPopupLink = nil return false end )
	
	--ZO_PreHookHandler(ComparativeTooltip1, "OnShow", function() zo_callLater(function() uespLog.AddCraftDetailsToToolTipRow(moc()) end, 100) end)
	--ZO_PreHookHandler(ComparativeTooltip1, "OnUpdate", function() return uespLog.AddCraftDetailsToToolTipRow(moc()) end)
	--ZO_PreHookHandler(ComparativeTooltip1, "OnHide", function() uespLog.tradeRowClicked = nil return false end )
	
	ZO_PreHook("ZO_InventorySlot_ShowContextMenu", uespLog.UpdateInventoryContextMenuHook)
	
	--ZO_PreHookHandler(PLAYER_INVENTORY.inventories[1].listView, "OnClicked", function() uespLog.TestInventoryClick() return false end )
	--ZO_PreHookHandler(PLAYER_INVENTORY.inventories[3].listView, "OnClicked", function() uespLog.TestInventoryClick() return false end )
	--ZO_PreHookHandler(PLAYER_INVENTORY.inventories[4].listView, "OnClicked", function() uespLog.TestInventoryClick() return false end )
	
	--ZO_PreHookHandler(InformationTooltip, "OnShow", function() zo_callLater(function() uespLog.AddDetailsToInfoToolTip(moc()) end, 100) end)
	--ZO_PreHookHandler(InformationTooltip, "OnUpdate", function() return uespLog.AddDetailsToInfoToolTip(moc()) end)
	--ZO_PreHookHandler(InformationTooltip, "OnHide", function() uespLog.equippedRowClicked = nil return false end )
end


function uespLog.UpdateInventoryContextMenuHook(rowControl) 
	local controlName = rowControl:GetName()
	local parentName = ""
	local parentName2 = ""
	
	if (rowControl:GetParent() ~= nil) then
		parentName = rowControl:GetParent():GetName()
		
		if (rowControl:GetParent():GetParent() ~= nil) then
			parentName2 = rowControl:GetParent():GetParent():GetName()
		end
	end

	if (parentName2 == "ZO_SmithingTopLevelResearchPanelResearchLineListList") then
		-- Skip this
	elseif (rowControl:GetParent() == nil or parentName == "ZO_Character"
				or controlName == "ZO_SmithingTopLevelImprovementPanelSlotContainerBoosterSlot" 
				or controlName == "ZO_SmithingTopLevelImprovementPanelSlotContainerImprovementSlot"
				or parentName == "ZO_SmithingTopLevelCreationPanelPatternListListScroll"
				or parentName == "ZO_SmithingTopLevelCreationPanelMaterialListListScroll"
				or parentName == "ZO_SmithingTopLevelCreationPanelStyleListListScroll"
				or parentName == "ZO_SmithingTopLevelCreationPanelTraitListListScroll") then
		zo_callLater(function() uespLog.UpdateInventoryContextMenu(rowControl) end, 50)
	else
		zo_callLater(function() uespLog.UpdateInventoryContextMenu(rowControl:GetParent()) end, 50)
	end
	
end


function uespLog.UpdateInventoryContextMenu(rowControl)
	AddMenuItem("Show Item Info", function() uespLog.ShowItemInfoRowControl(rowControl) end, MENU_ADD_OPTION_LABEL)
	ShowMenu(self)
end


function uespLog.TestInventoryClick() 
	uespLog.DebugMsg("TestInventoryClick")
end


function uespLog.AddDetailsToInfoToolTip (row)	
	uespLog.DebugMsg("InfoRow = "..tostring(row.dataEntry))
	return uespLog.AddCraftDetailsToToolTip (row)	
end


function uespLog.AddCraftDetailsToPopupToolTip() 

	if (uespLog.lastPopupLink == PopupTooltip.lastLink) then
		return false
	end
	
	uespLog.lastPopupLink = PopupTooltip.lastLink
	
	return uespLog.AddCraftDetailsToToolTip(PopupTooltip, PopupTooltip.lastLink)
end


function uespLog.AddCraftDetailsToToolTipRow (row)	

	if (not uespLog.IsCraftDisplay()) then
		return false
	end
	
	--GetItemInfo(mouseOverControl.bagId, mouseOverControl.itemIndex)};
	--uespLog.DebugMsg("Row = "..tostring(row.itemIndex))
	
	if (row.dataEntry == nil and row.bagId == nil) then
		return false 
	elseif (row.dataEntry ~= nil and (row.dataEntry.data == nil or uespLog.tradeRowClicked == row)) then
		return false
	elseif (row.bagId ~= nil and (row.itemIndex == nil or uespLog.equippedRowClicked == row)) then
		return false
	end
	
	if (ZO_Store_IsShopping()) then
		local storeMode = ZO_MenuBar_GetSelectedDescriptor(STORE_WINDOW.modeBar.menuBar)
		
		--SI_STORE_MODE_REPAIR SI_STORE_MODE_BUY_BACK SI_STORE_MODE_BUY  SI_STORE_MODE_SELL
		if (storeMode ~= SI_STORE_MODE_SELL) then
			return false
		end
		
	end
	
	if (row.dataEntry ~= nil) then
		uespLog.tradeRowClicked = row
	elseif (row.bagId ~= nil) then
		uespLog.equippedRowClicked = row
	end
	
	local bagId = nil
	local slotIndex = nil
	
	if (row.dataEntry ~= nil) then
		local rowInfo = row.dataEntry.data
		bagId = rowInfo.bagId or rowInfo.lootId
		slotIndex = rowInfo.slotIndex
	elseif (row.bagId ~= nil) then
		bagId = row.bagId
		slotIndex = row.itemIndex
	end

	local itemLink = nil
	
	if (slotIndex) then
		itemLink = GetItemLink(bagId, slotIndex)
	else
		itemLink = GetLootItemLink(bagId)
	end
	
	return uespLog.AddCraftDetailsToToolTip(ItemTooltip, itemLink, bagId, slotIndex)
end


function uespLog.AddCraftDetailsToToolTip (ThisToolTip, itemLink, bagId, slotIndex)	
	
	if (itemLink == nil) then
		return false
	end
	
	local itemId = uespLog.GetItemLinkID(itemLink)
	local tradeType = uespLog.GetItemTradeType(itemId)
	local iconTexture, iconColor = uespLog.GetTradeIconTexture(itemId, itemLink)
	local color1, color2, color3
	local itemStyleIcon, itemStyleText = uespLog.GetItemStyleIcon(itemLink)
	local addedBlankLine = false
	
	if (itemStyleIcon ~= nil and uespLog.IsCraftStyleDisplay()) then
		color1, color2, color3 = unpack(uespLog.TRADE_STYLE_COLOR)
		ThisToolTip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE)
		ThisToolTip:AddLine("Item Style: "..itemStyleText, "ZoFontWinH4", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
		addedBlankLine = true
	end
	
	if (iconTexture ~= nil and tradeType ~= nil) then
	
		if (uespLog.IsCraftIngredientDisplay()) then
			--ZO_Tooltip_AddDivider(ThisToolTip)		
			local itemText = ""
			color1, color2, color3 = unpack(iconColor)
			
			if (tradeType >= 1 and tradeType <= 6) then
				itemText = "Recipe Level "..tostring(tradeType)
			else
				itemText = "Special Ingredient"
			end
			
			if (not addedBlankLine) then
				ThisToolTip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, 0)
			end
			
			ThisToolTip:AddLine(itemText, "ZoFontWinH5", color1, color2, color3, BOTTOM, 0)
		end
		
		return false
	end
	
	if (slotIndex == nil) then
		return false
	end
	
	local isResearchable = uespLog.CheckIsItemResearchable(bagId, slotIndex)
	
	if (isResearchable < 0) then
		return false
	end
	
	itemText = ""
	iconColor = uespLog.TRADE_KNOWN_COLOR
	
	if (isResearchable == 9) then
		--iconControl:SetHidden(false)		
		--iconControl:SetTexture(uespLog.TRADE_ORNATE_TEXTURE)
		--iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
		--iconControl:SetColor(unpack(uespLog.TRADE_ORNATE_COLOR))
		itemText = "Ornate"
		iconColor = uespLog.TRADE_ORNATE_COLOR
	elseif (isResearchable == 10) then
		--iconControl:SetHidden(false)		
		--iconControl:SetTexture(uespLog.TRADE_INTRICATE_TEXTURE)
		--iconControl:SetColor(unpack(uespLog.TRADE_INTRICATE_COLOR))
		itemText = "Intricate"
		iconColor = uespLog.TRADE_INTRICATE_COLOR
	elseif (isResearchable > 0) then
		--iconControl:SetHidden(false)
		--iconControl:SetTexture(uespLog.TRADE_UNKNOWN_TEXTURE)
		--iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
		itemText = "Trait Unknown"
		iconColor = uespLog.TRADE_UNKNOWN_COLOR
	else
		--iconControl:SetHidden(false)
		--iconControl:SetTexture(uespLog.TRADE_KNOWN_TEXTURE)
		--iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
		itemText = "Trait Known"
		iconColor = uespLog.TRADE_KNOWN_COLOR
	end	
	
	if (uespLog.IsCraftTraitDisplay()) then
		color1, color2, color3 = unpack(iconColor)	
		
		if (not addedBlankLine) then
			ThisToolTip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
		end
		
		ThisToolTip:AddLine(itemText, "ZoFontWinH5", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
	end

	return true
end


function uespLog.SetupInventoryListHooks(list, hookData)

	if (not list) or (not list.dataTypes) or (not list.dataTypes[1]) then
		return false
	end
	
	local listName = list:GetName()
	local oldCallback = list.dataTypes[1].setupCallback
	
	if oldCallback then
		list.dataTypes[1].setupCallback = 
			function(rowControl, slot)
				oldCallback(rowControl, slot)
				uespLog.AddCraftInfoToInventorySlot(rowControl, hookData, list)
			end				
	else
		uespLog.Msg("UESP::Failed to hook the inventory callback!")
	end
		
    return true
end


function uespLog.AddCraftInfoToInventorySlot (rowControl, hookData, list)

	if (not uespLog.IsCraftDisplay()) then
		return
	end
	
	--local bagId list.dataEntry.data.bagId
	--local slotIndex = list.dataEntry.data.slotIndex
	
	local GetItemLinkFunc = hookData[1]	
    local slot = rowControl.dataEntry.data
    local bagId = slot[hookData[2]]
    local slotIndex = (hookData[3] and slot[hookData[3]]) or nil
	
	if (not slot.name) or (slot.name == "") then 
		return
	end
	
	local iconControl = uespLog.GetIconControl(rowControl)
	local styleIconControl = uespLog.GetStyleIconControl(rowControl)
	local itemLink = GetItemLinkFunc(bagId, slotIndex)
	local itemId = uespLog.GetItemLinkID(itemLink)	
	local tradeType = uespLog.GetItemTradeType(itemId)
	local iconTexture, iconColor = uespLog.GetTradeIconTexture(itemId, itemLink)
	local nameControl = rowControl:GetNamedChild("Name")
	local itemStyleIcon, itemStyleText = uespLog.GetItemStyleIcon(itemLink)
	local iconOffset = 0
	
	--uespLog.DebugMsg("IconTexture = "..tostring(iconTexture))
	
	if (list == LOOT_WINDOW.list) then
		--uespLog.DebugMsg("Loot item link = "..tostring(itemLink))
		iconOffset = 50
	end
	
	iconControl:SetHidden(true)		
	iconControl:SetDimensions(32, 32)
	iconControl:ClearAnchors()
	--iconControl:SetAnchor(RIGHT, rowControl, RIGHT, -50)
	iconControl:SetAnchor(CENTER, rowControl, CENTER, 120 + iconOffset)
		
	styleIconControl:SetHidden(true)		
	styleIconControl:SetDimensions(32, 32)
	styleIconControl:ClearAnchors()
	styleIconControl:SetAnchor(CENTER, rowControl, CENTER, 90 + iconOffset)
	
	if (itemStyleIcon ~= nil and uespLog.IsCraftStyleDisplay()) then
		styleIconControl:SetHidden(false)		
		styleIconControl:SetTexture(itemStyleIcon)
		--iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
	end
	
	if (iconTexture ~= nil) then
	
		if (uespLog.IsCraftIngredientDisplay()) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(iconTexture)
	
			iconControl:SetColor(unpack(iconColor))
			if (nameControl ~= nil) then nameControl:SetColor(unpack(iconColor)) end
		end
		
		return
	end
	
	local recipeName = uespLog.GetRecipeNameFromLink(itemLink)
	
	if (recipeName ~= nil) then
		if (uespLog.IsCraftRecipeDisplay()) then
			if (uespLog.IsRecipeKnown(recipeName)) then
				iconControl:SetHidden(false)		
				iconControl:SetTexture(uespLog.TRADE_KNOWN_TEXTURE)
				iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
			else
				iconControl:SetHidden(false)		
				iconControl:SetTexture(uespLog.TRADE_UNKNOWN_TEXTURE)
				iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
			end
		end
		
		return
	end
	
	if (slotIndex == nil or list == LOOT_WINDOW.list) then
		return
	end
	
	local isResearchable = uespLog.CheckIsItemResearchable(bagId, slotIndex)
	--uespLog.DebugMsg("Trait for "..itemLink.." is "..tostring(isResearchable))
	
	if (isResearchable < 0) then
		return
	end

	if (uespLog.IsCraftTraitDisplay()) then
	
		if (isResearchable == 9) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(uespLog.TRADE_ORNATE_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
			iconControl:SetColor(unpack(uespLog.TRADE_ORNATE_COLOR))
		elseif (isResearchable == 10) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(uespLog.TRADE_INTRICATE_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_INTRICATE_COLOR))
		elseif (isResearchable > 0) then
			iconControl:SetHidden(false)
			iconControl:SetTexture(uespLog.TRADE_UNKNOWN_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
		else
			iconControl:SetHidden(false)
			iconControl:SetTexture(uespLog.TRADE_KNOWN_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
		end
		
	end
	
end


function uespLog.CheckIsItemResearchable(bagId, slotIndex)
	local itemType = GetItemType(bagId, slotIndex)
	
	if (itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
		return -8
	end

	local traitType = GetItemTrait(bagId, slotIndex)
	local traitIndex = traitType

	if (traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return 9
	elseif (traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return 10
	end

	local _,_,_,_,_,equipType = GetItemInfo(bagId, slotIndex)
	
	if (equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK) then
		return -5
	end

	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if (traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if (not (traitIndex >= 1 and traitIndex <= 8)) then
		return -4
	end

	local check1 = uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_BLACKSMITHING, traitIndex)
	if (check1 >= 0) then return check1 end
	
	local check2 = uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_CLOTHIER, traitIndex)
	if (check2 >= 0) then return check2 end
	
	return uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_WOODWORKING, traitIndex)
end


function uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, craftingSkillType, traitIndex)

		--if it can't be extracted or refined here, then it can't be researched!
	if (not CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, craftingSkillType)) then
		return -2
	end
	
	local numLines = GetNumSmithingResearchLines(craftingSkillType)

	for i = 1, numLines do
		if (CanItemBeSmithingTraitResearched(bagId, slotIndex, craftingSkillType, i, traitIndex)
			and not GetSmithingResearchLineTraitTimes(craftingSkillType, i, traitIndex)) then --if not nil, then researching
			--return craftingSkillType * 1000000 + equipType * 10000 + i * 100 + traitIndex
			return traitIndex
		end
	end

	return 0
end


function uespLog.GetRecipeNameFromLink (itemLink) 
	local itemName, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
	if (itemName == nil or niceName == nil) then
		return
	end
	
		-- TODO: Only works with english version
	if (not uespLog.EndsWith(itemName, " Recipe")) then
		return
	end
	
	local recipeName = string.sub(niceName, 1, #niceName - 7)
	return recipeName
end


function uespLog.IsRecipeKnown (inputRecipeName)
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local ingrCount = 0
	local logData = { }
	local checkRecipeName = string.lower(inputRecipeName)
	
	for recipeListIndex = 1, numRecipeLists do
		local name, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
		
		for recipeIndex = 1, numRecipes do
			local known, recipeName, numIngredients, provisionerLevelReq, qualityReq, specialIngredientType = GetRecipeInfo(recipeListIndex, recipeIndex)
			
			if (known and string.lower(recipeName) == checkRecipeName) then
				return true, recipeListIndex, recipeIndex
			end
		end
	end

	return false, nil, nil
end


function uespLog.DumpItemControl (itemControl)
	uespLog.DebugMsg("UESP::Dumping item control "..tostring(itemControl))
	
	uespLog.printDumpObject = true
	--uespLog.DumpObject("PopupTooltip", getmetatable(PopupTooltip), 0, 2)
		
	--for k, v in pairs(PopupTooltip) do
		--uespLog.DebugMsg(".    " .. tostring(k) .. "=" .. tostring(v))
	--end
	
	local numChildren = itemControl:GetNumChildren()
	uespLog.DebugMsg("UESP::Has "..tostring(numChildren).." children")
	
    for i = 1, numChildren do
        local child = itemControl:GetChild(i)
		--uespLog.DumpObject("child", getmetatable(child), 0, 2)
		local name = child:GetName()
		uespLog.DebugMsg(".   "..tostring(i)..") "..tostring(name))
    end
	
	uespLog.printDumpObject = false
end


function uespLog.GetItemTradeType(itemId)
	return uespLog.INGREDIENT_DATA[itemId], uespLog.AUTOLOOT_ALWAYS_INGREDIENTS[itemId]
end


function uespLog.GetTradeIconTexture (itemId, itemLink)
	local tradeType = uespLog.GetItemTradeType(itemId)
	
	if (tradeType == nil or tradeType <= 0) then 
		return nil, nil
	end
	
	if (uespLog.PROVISION_ICONS[tradeType] ~= nil) then
		return uespLog.PROVISION_ICONS[tradeType], uespLog.PROVISION_COLORS[tradeType]
	end
	
	--[[
	if (tradeType <= 6) then
		return "uespLog\\images\\provision"..tostring(tradeType)..".dds", uespLog.TRADE_NORMAL_COLOR
	elseif (tradeType == 100) then
		return "uespLog\\images\\provspecial1.dds", uespLog.TRADE_SUPERIOR_COLOR
	elseif (tradeType == 101) then
		return "uespLog\\images\\provspecial2.dds", uespLog.TRADE_EPIC_COLOR
	end --]]
	
	return nil, nil
end


function uespLog.GetIconControl (rowControl)
	local iconControl = uespLog.iconControls[rowControl:GetName()]
	
	if (not iconControl) then		
		iconControl = WINDOW_MANAGER:CreateControl(rowControl:GetName() .. "uespLogIcon", rowControl, CT_TEXTURE)
        uespLog.iconControls[rowControl:GetName()] = iconControl	
	end
	
	return iconControl
end


function uespLog.GetStyleIconControl (rowControl)
	local styleIconControl = uespLog.styleIconControls[rowControl:GetName()]
	
	if (not styleIconControl) then		
		styleIconControl = WINDOW_MANAGER:CreateControl(rowControl:GetName() .. "uespLogStyleIcon", rowControl, CT_TEXTURE)
        uespLog.styleIconControls[rowControl:GetName()] = styleIconControl	
	end
	
	return styleIconControl
end


function uespLog.DisplayUespCraftHelp()
	uespLog.Msg("UESP:: /uespcraft on/off            -- Turns all crafting displays on/off")
	uespLog.Msg("UESP:: /uespcraft style on/off      -- Turns style display on/off")
	uespLog.Msg("UESP:: /uespcraft trait on/off      -- Turns trait display on/off")
	uespLog.Msg("UESP:: /uespcraft recipe on/off     -- Turns recipe display on/off")
	uespLog.Msg("UESP:: /uespcraft ingredient on/off -- Turns ingredient display on/off")
	uespLog.Msg("UESP:: /uespcraft autoloot on/off   -- Turns craft autoloot on/off")
	uespLog.Msg("UESP:: /uespcraft minprovlevel #    -- Set the minimum provisioner level of ingredients to autoloot")
    uespLog.Msg("UESP:: Craft display is "..uespLog.BoolToOnOff(uespLog.IsCraftDisplay()))
	uespLog.Msg("UESP:: Craft style display is "..uespLog.BoolToOnOff(uespLog.IsCraftStyleDisplay()))
	uespLog.Msg("UESP:: Craft trait display is "..uespLog.BoolToOnOff(uespLog.IsCraftTraitDisplay()))
	uespLog.Msg("UESP:: Craft recipe display is "..uespLog.BoolToOnOff(uespLog.IsCraftRecipeDisplay()))
	uespLog.Msg("UESP:: Craft ingredient display is "..uespLog.BoolToOnOff(uespLog.IsCraftIngredientDisplay()))
	uespLog.Msg("UESP:: Craft autoloot is "..uespLog.BoolToOnOff(uespLog.IsCraftAutoLoot()))
	uespLog.Msg("UESP:: Autoloot min provisioner level is "..uespLog.GetCraftAutoLootMinProvLevel())
end


function uespLog.IsCraftDisplay()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craft
end


function uespLog.IsCraftAutoLoot()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftAutoLoot
end


function uespLog.GetCraftAutoLootMinProvLevel()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftAutoLootMinProvLevel
end


function uespLog.IsCraftStyleDisplay()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftStyle
end


function uespLog.IsCraftRecipeDisplay()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftRecipe
end


function uespLog.IsCraftTraitDisplay()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftTrait
end

function uespLog.IsCraftIngredientDisplay()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.craftIngredient
end


function uespLog.SetCraftDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craft = flag
end	


function uespLog.SetCraftAutoLoot(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftAutoLoot = flag
end


function uespLog.SetCraftAutoLootMinProvLevel(level)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	local levelNum = tonumber(level)
	
	if (levelNum == nil or levelNum < 1) then
		levelNum = 1 
	end
	
	uespLog.savedVars.settings.data.craftAutoLootMinProvLevel = levelNum
end


function uespLog.SetCraftStyleDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftStyle = flag
end	


function uespLog.SetCraftRecipeDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftRecipe = flag
end	


function uespLog.SetCraftTraitDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftTrait = flag
end	


function uespLog.SetCraftIngredientDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftIngredient = flag
end	


SLASH_COMMANDS["/uespcraft"] = function (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%w+") do table.insert(cmdWords, string.lower(word)) end
	
	if (#cmdWords < 1) then
		uespLog.DisplayUespCraftHelp()
		return
	end
	
	local flag = false
	
	if (cmdWords[1] == "recipe") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftRecipeDisplay(true)
			uespLog.Msg("UESP::Turned recipe display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftRecipeDisplay(false)
			uespLog.Msg("UESP::Turned recipe display off")
		else
			uespLog.Msg("UESP::Craft recipe display is "..uespLog.BoolToOnOff(uespLog.IsCraftRecipeDisplay()))
		end
		
	elseif (cmdWords[1] == "ingredient") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftIngredientDisplay(true)
			uespLog.Msg("UESP::Turned ingredient display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftIngredientDisplay(false)
			uespLog.Msg("UESP::Turned ingredient display off")
		else
			uespLog.Msg("UESP::Craft ingredient display is "..uespLog.BoolToOnOff(uespLog.IsCraftIngredientDisplay()))
		end
		
	elseif (cmdWords[1] == "style") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftStyleDisplay(true)
			uespLog.Msg("UESP::Turned style display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftStyleDisplay(false)
			uespLog.Msg("UESP::Turned style display off")
		else
			uespLog.Msg("UESP::Craft style display is "..uespLog.BoolToOnOff(uespLog.IsCraftStyleDisplay()))
		end
				
	elseif (cmdWords[1] == "trait") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftTraitDisplay(true)
			uespLog.Msg("UESP::Turned trait display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftTraitDisplay(false)
			uespLog.Msg("UESP::Turned trait display off")
		else
			uespLog.Msg("UESP::Craft trait display is "..uespLog.BoolToOnOff(uespLog.IsCraftTraitDisplay()))
		end
		
	elseif (cmdWords[1] == "autoloot") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftAutoLoot(true)
			uespLog.Msg("UESP::Turned craft autoloot on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftAutoLoot(false)
			uespLog.Msg("UESP::Turned craft autoloot off")
		else
			uespLog.Msg("UESP::Craft autoloot is "..uespLog.BoolToOnOff(uespLog.IsCraftAutoLoot()))
		end
		
	elseif (cmdWords[1] == "minprovlevel") then
	
		if (cmdWords[2] ~= "" and cmdWords[2] ~= nil) then
			uespLog.SetCraftAutoLootMinProvLevel(cmdWords[2])
			uespLog.Msg("UESP::Set craft autoloot min provisioner level to "..uespLog.GetCraftAutoLootMinProvLevel())
		else
			uespLog.Msg("UESP::Craft autoloot min provisioner level is "..uespLog.GetCraftAutoLootMinProvLevel())
		end
	
	elseif (cmdWords[1] == "on") then
		uespLog.SetCraftDisplay(true)
		uespLog.Msg("UESP::Turned crafting display on")
	elseif (cmdWords[1] == "off") then
		uespLog.SetCraftDisplay(false)
		uespLog.Msg("UESP::Turned crafting display off")
	else
		uespLog.DisplayUespCraftHelp()
	end
	
end


function uespLog.GetStyleFromItemLink(itemLink)
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	return itemStyle
end


function uespLog.GetItemStyleIcon(itemLink)
	local itemStyle = uespLog.GetStyleFromItemLink(itemLink)
	
	if (itemStyle == nil or itemStyle <= 0) then
		return nil, nil
	end
	
	local itemStyleText = uespLog.GetItemStyleStr(itemStyle)
	
	if (uespLog.STYLE_ICON_DATA[itemStyle] ~= nil) then
		return uespLog.STYLE_ICON_DATA[itemStyle], itemStyleText
	end
	
	return uespLog.STYLE_ICON_UNKNOWN, itemStyleText
end


function uespLog.GetStoreMode()
	--SI_STORE_MODE_REPAIR SI_STORE_MODE_BUY_BACK SI_STORE_MODE_BUY  SI_STORE_MODE_SELL
	
	if (ZO_Store_IsShopping()) then
		return ZO_MenuBar_GetSelectedDescriptor(STORE_WINDOW.modeBar.menuBar)
	end
	
	return 0
end


function uespLog.CraftAutoLoot()
--LootAll()
--GetLootItemLink(integer lootId, LinkStyle linkStyle)
--Returns: string link
--LootItemById(integer lootId)
--LootMoney()
--EndLooting()
	local numLoot = GetNumLootItems()
	local MinProvLevel = uespLog.GetCraftAutoLootMinProvLevel()
	
	if (LOOT_WINDOW.returnScene) then
		SCENE_MANAGER:Hide("loot")
		SCENE_MANAGER:Show(LOOT_WINDOW.returnScene)
		SCENE_MANAGER:Hide(LOOT_WINDOW.returnScene)
	else
		SCENE_MANAGER:Hide("loot")
	end
	
	LOOT_WINDOW.control:SetHidden(true)
	--SCENE_MANAGER:Hide("loot")
	--LOOT_WINDOW:Hide()
	
	uespLog.DebugExtraMsg("UESP::Auto looting "..tostring(numLoot).." items...")
	LootMoney()
	
	local targetName, targetType, actionName = GetLootTargetInfo()
	
	local extraLogData = { }
	extraLogData.lootTarget = targetName
	extraLogData.targetType = targetType
	extraLogData.actionName = actionName
	extraLogData.skippedLoot = 1
	
	for lootIndex = 1, numLoot do
		local lootId, name, icon, count, quality, value, isQuest = GetLootItemInfo(lootIndex)
		local itemLink = GetLootItemLink(lootId)
		local itemId = uespLog.GetItemLinkID(itemLink)
		local tradeType, alwaysLoot = uespLog.GetItemTradeType(itemId)
		
		extraLogData.tradeType = tradeType
		
		if (tradeType == nil or tradeType >= MinProvLevel or alwaysLoot) then
			LootItemById(lootId)
		else
			uespLog.OnLootGained("LootGained", "player", itemLink, count, nil, nil, true, extraLogData)
		end
	end
	
	--LOOT_WINDOW.control:SetHidden(false)
	EndLooting()
	--SCENE_MANAGER:Hide("loot")
end


function uespLog.CreateNiceLink(link)
	
	if type(link) == "string" then
		local data, text = link:match("|H(.-)|h(.-)|h")
		
		if (text == nil or data == nil) then
			return link
		end
		
		local niceLink = link
		
		if (text ~= nil) then
			local niceName = text:gsub("%^.*", "")
			niceLink = "|H"..data.."|h["..niceName.."]|h"
		end
		
		return niceLink
    end
	
	return link
end


function uespLog.OnLootUpdated (eventCode)

	if (uespLog.IsCraftAutoLoot()) then
		uespLog.CraftAutoLoot()
	end
	
end