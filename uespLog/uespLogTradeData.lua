-- uespLogTradeData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the tradeskill data portion of the add-on


uespLog.iconControls = { }
uespLog.styleIconControls = { }
uespLog.tradeRowClicked = nil
uespLog.equippedRowClicked = nil
uespLog.lastPopupLink = nil
uespLog.isStableInteract = false


uespLog.TRADE_NORMALTEXT_COLOR = { 0.77, 0.77, 0.62 }
uespLog.TRADE_NORMAL_COLOR = { 1, 1, 1 }
uespLog.TRADE_FINE_COLOR = { 0.18, 0.78, 0.02 }
uespLog.TRADE_SUPERIOR_COLOR = { 0.23, 0.55, 1 }
uespLog.TRADE_EPIC_COLOR = { 0.63, 0.18, 0.97 }
uespLog.TRADE_KNOWN_COLOR = { 1, 1, 1 }
uespLog.TRADE_UNKNOWN_COLOR = { 1, 0.2, 0.2 }
uespLog.TRADE_ORNATE_COLOR = { 1, 1, 0.25 }
uespLog.TRADE_INTRICATE_COLOR = { 0, 1, 1 }
uespLog.TRADE_STYLE_COLOR = { 1, 0.75, 0.25 }
uespLog.TRADE_PRICE_COLOR = { 1.0, 1.0, 0.5 }

uespLog.ORNATE_TRAIT_INDEX = 20  --10, 19
uespLog.INTRICATE_TRAIT_INDEX = 21 --9, 20

uespLog.TRADE_UNKNOWN_TEXTURE = "uespLog\\images\\unknown.dds"
uespLog.TRADE_KNOWN_TEXTURE = "uespLog\\images\\known.dds"
--uespLog.TRADE_ORNATE_TEXTURE = "/esoui/art/tradinghouse/tradinghouse_sell_tabicon_disabled.dds"   -- No longer exist?
--uespLog.TRADE_INTRICATE_TEXTURE = "/esoui/art/progression/progression_indexicon_guilds_up.dds"
uespLog.TRADE_ORNATE_TEXTURE = "uespLog\\images\\ornate.dds"
uespLog.TRADE_INTRICATE_TEXTURE = "uespLog\\images\\intricate.dds"

uespLog.STYLE_ICON_UNKNOWN = "uespLog\\images\\unknown.dds"


uespLog.ALT_STYLE_ICON_DATA = {
	[ITEMSTYLE_RACIAL_NORD]  		 = "uespLog\\images\\stylenord.dds",  		-- Corundum, Nord, 33256, ITEMSTYLE_RACIAL_NORD=5, /esoui/art/icons/crafting_metals_corundum.dds
	[ITEMSTYLE_RACIAL_REDGUARD]  	 = "uespLog\\images\\styleredguard.dds",	-- Starmetal, Redguard, 33258, ITEMSTYLE_RACIAL_REDGUARD=2, /esoui/art/icons/crafting_medium_armor_sp_names_002.dds
	[ITEMSTYLE_RACIAL_ORC]  		 = "uespLog\\images\\styleorc.dds",			-- Manganese, Orc, 33257, ITEMSTYLE_RACIAL_ORC=3, /esoui/art/icons/crafting_metals_manganese.dds
	[ITEMSTYLE_RACIAL_KHAJIIT]  	 = "uespLog\\images\\stylekhajiit.dds",		-- Moonstone, Khajiit, 33255, ITEMSTYLE_RACIAL_KHAJIIT=9, /esoui/art/icons/crafting_smith_plug_sp_names_001.dds
	[ITEMSTYLE_RACIAL_HIGH_ELF]  	 = "uespLog\\images\\stylealtmer.dds",		-- Adamantite, Altmer, 33252, ITEMSTYLE_RACIAL_HIGH_ELF=7, /esoui/art/icons/grafting_gems_adamantine.dds
	[ITEMSTYLE_RACIAL_WOOD_ELF]  	 = "uespLog\\images\\stylebosmer.dds",		-- Bone, Bosmer, 33194, ITEMSTYLE_RACIAL_WOOD_ELF=8, /esoui/art/icons/crafting_gems_daedra_skull.dds
	[ITEMSTYLE_RACIAL_ARGONIAN]  	 = "uespLog\\images\\styleargonian.dds",	-- Flint, Argonian, 33150, ITEMSTYLE_RACIAL_ARGONIAN=6, /esoui/art/icons/crafting_smith_potion_standard_f_002.dds
	[ITEMSTYLE_RACIAL_BRETON]  		 = "uespLog\\images\\stylebreton.dds",		-- Molybdenum, Breton, 33251, ITEMSTYLE_RACIAL_BRETON=1, /esoui/art/icons/crafting_metals_molybdenum.dds
	[ITEMSTYLE_RACIAL_DARK_ELF] 	 = "uespLog\\images\\styledunmer.dds",		-- Obsidian, Dunmer, 33253, ITEMSTYLE_RACIAL_DARK_ELF=4, /esoui/art/icons/crafting_metals_graphite.dds
	[ITEMSTYLE_ENEMY_PRIMITIVE] 	 = "uespLog\\images\\styleprimal.dds",		-- Argentum, Primal, 46150, ITEMSTYLE_ENEMY_PRIMITIVE=19, /esoui/art/icons/crafting_metals_argentum.dds
	[ITEMSTYLE_RACIAL_IMPERIAL]  	 = "uespLog\\images\\styleimperial.dds",	-- Nickel, Imperial, 33254, ITEMSTYLE_RACIAL_IMPERIAL=34, /esoui/art/icons/crafting_heavy_armor_sp_names_001.dds
	[ITEMSTYLE_AREA_REACH]  		 = "uespLog\\images\\stylebarbaric.dds",	-- Copper, Barbaric, 46149, ITEMSTYLE_AREA_REACH=17, /esoui/art/icons/crafting_smith_potion_standard_f_001.dds
	[ITEMSTYLE_ENEMY_DAEDRIC] 		 = "uespLog\\images\\styledaedric.dds",		-- Daedra Heart, Daedric, 46151, ITEMSTYLE_ENEMY_DAEDRIC=20, /esoui/art/icons/crafting_walking_dead_mort_heart.dds
	[ITEMSTYLE_AREA_ANCIENT_ELF] 	 = "uespLog\\images\\styleancientelf.dds",	-- Palladium, Ancient Elf, 46152, ITEMSTYLE_AREA_ANCIENT_ELF=15, /esoui/art/icons/crafting_ore_palladuim.dds
	[ITEMSTYLE_AREA_DWEMER] 	     = "uespLog\\images\\styledwemer.dds",		-- Dwemer Frame, Dwemer, 57587, ITEMSTYLE_AREA_DWEMER=14, /esoui/art/icons/crafting_dwemer_shiny_tube.dds
	[ITEMSTYLE_AREA_AKAVIRI] 		 = "uespLog/images/aicon.dds", 				-- Akaviri, 33
	[ITEMSTYLE_GLASS]		 		 = "uespLog/images/malachite.dds", 			-- Glass, 28
	[ITEMSTYLE_AREA_XIVKYN] 		 = "uespLog/images/charcoal.dds", 			-- Xivkyn, 29
	[ITEMSTYLE_UNDAUNTED] 			 = "uespLog/images/laurel.dds",				-- Mercenary, 26, /esoui/art/icons/crafting_laurel.dds
	[ITEMSTYLE_AREA_ANCIENT_ORC] 	 = "uespLog/images/cassiterite.dds",		-- Ancient Orc, 22 /esoui/art/icons/crafting_smith_plug_standard_f_001.dds
	[47]							 = "uespLog/images/roguessoot.dds",			-- Outlaw, 47 ITEMSTYLE_UNUSED9 /esoui/art/icons/crafting_outlaw_styleitem.dds, 
	[ITEMSTYLE_DEITY_MALACATH]		 = "uespLog/images/potash.dds", 			-- Malacath, 13 /esoui/art/icons/crafting_style_item_malacath.dds
	[ITEMSTYLE_DEITY_TRINIMAC]		 = "uespLog/images/aurictusk.dds",			-- Trinimac, 21 /esoui/art/icons/crafting_style_item_trinimac.dds
	[ITEMSTYLE_AREA_SOUL_SHRIVEN]	 = "uespLog/images/azureplasm.dds",			-- Soul Shriven, 30 /esoui/art/icons/crafting_runecrafter_plug_component_005.dds
	[ITEMSTYLE_ALLIANCE_DAGGERFALL]  = "uespLog/images/lionfang.dds",			-- Daggerfall, 23 /esoui/art/icons/crafting_style_item_daggerfall_covenant.dds
	[ITEMSTYLE_ALLIANCE_EBONHEART] 	 = "uespLog/images/dragonscute.dds",		-- Ebonheart, 24 /esoui/art/icons/crafting_style_item_ebonheart_pact.dds
	[ITEMSTYLE_ALLIANCE_ALDMERI] 	 = "uespLog/images/eaglefeather.dds",		-- Aldmeri, 25 /esoui/art/icons/crafting_style_item_aldmeri_dominion.dds
	[ITEMSTYLE_UNIVERSAL] 			 = "uespLog/images/mimicstone.dds",			-- Universal, 36 /esoui/art/icons/crafing_universal_item.dds  (incorrect spelling "crafing" in 1.9 PTS)
	[ITEMSTYLE_ORG_THIEVES_GUILD] 	 = "uespLog/images/thievesguild_style.dds",	-- Thieves Guild, 11 /esoui/art/icons/crafting_style_item_thieves_guild_r2.dds
	[ITEMSTYLE_ORG_ABAHS_WATCH] 	 = "uespLog/images/abahswatch.dds",			-- Abah's Watch, 41, /esoui/art/icons/crafting_style_item_abahs_watch_r2.dds
	[ITEMSTYLE_ORG_ASSASSINS]	 	 = "uespLog/images/assassinsleague.dds",	-- Assassin's League, 46, /esoui/art/icons/crafting_style_item_assassins_league_r2.dds
	[ITEMSTYLE_ORG_DARK_BROTHERHOOD] = "uespLog/images/darkbrotherhood.dds",	-- Black Beeswax, Dark Brotherhood, 12, /esoui/art/icons/crafting_style_item_dark_brotherhood_r2.dds
	[39] 							 = "uespLog/images/minotaur.dds",			-- Oxblood Fungus, Minotaur, 39, /esoui/art/icons/crafting_style_item_minotaur_r2.dds
	[16] 							 = "uespLog/images/akatosh.dds",			-- Pearl Sand, Akatosh, 16, /esoui/art/icons/crafting_style_item_orderoth_r2.dds
	[45] 							 = "uespLog/images/dromothra.dds",			-- Defiled Whiskers, Dro-m'Athra, 45, /esoui/art/icons/crafting_style_item_dromothra_r2.dds
	[58]							 = "uespLog/images/grimarlequin.dds",		-- Grinstone, Grim Arlequin, 57, /esoui/art/icons/crafting_style_item_harlequin_r2.dds
	[59]							 = "uespLog/images/hollowjack.dds",			-- Amber Marble, Hollowjack, 59, /esoui/art/icons/crafting_style_item_hollowjack_r2.dds
	[ITEMSTYLE_AREA_YOKUDAN] 		 = "uespLog/images/yokudan.dds",			-- Yokudan, Ferrous Salts, 35, /esoui/art/icons/crafting_humanoid_daedra_void_salts.dds
	[27]							 = "uespLog/images/celestial.dds",			-- Celestial, Star Sapphires, 27, /esoui/art/icons/crafting_style_item_celestial_r2.dds
	[31]							 = "uespLog/images/draugr.dds",				-- Draugr, Pristine Shrouds, 31, /esoui/art/icons/crafting_style_item_draugr_r2.dds	
	[42]							 = "uespLog/images/skinchanger.dds",		-- Skinchanger, Wolfsbane Incense, 42, /esoui/art/icons/crafting_style_item_wolfsbane_r2.dds	
	[53]							 = "uespLog/images/stalhrim.dds",			-- Stalhrim Frostcaster, Stalhrim Shard, 53, /esoui/art/icons/crafting_runecrafter_armor__standard_r_003.dds	
	[56]							 = "uespLog/images/silkenring.dds",			-- Silken Ring, Distilled Slowsilver, 56, /esoui/art/icons/crafting_style_item_mirrorsheen_r2.dds
	[57]							 = "uespLog/images/mazzatun.dds",			-- Mazzatun, Leviathan Scrimshaw, 57, /esoui/art/icons/crafting_style_item_mazzatun_r2.dds
	[44]							 = "uespLog/images/ragada.dds",				-- Ra Gada, Ancient Sandstone, 44, /esoui/art/icons/crafting_style_item_ragada_r2.dds
	[40]							 = "uespLog/images/ebony.dds",				-- Ebony, Night Pumice, 40, /esoui/art/icons/crafting_style_item_ebony_r2.dds
}


uespLog.STYLE_ICON_DATA = {
	[ITEMSTYLE_RACIAL_NORD]  		 = "/esoui/art/icons/crafting_metals_corundum.dds",
	[ITEMSTYLE_RACIAL_REDGUARD]  	 = "/esoui/art/icons/crafting_medium_armor_sp_names_002.dds",
	[ITEMSTYLE_RACIAL_ORC]  		 = "/esoui/art/icons/crafting_metals_manganese.dds",
	[ITEMSTYLE_RACIAL_KHAJIIT]  	 = "/esoui/art/icons/crafting_smith_plug_sp_names_001.dds",
	[ITEMSTYLE_RACIAL_HIGH_ELF]  	 = "/esoui/art/icons/grafting_gems_adamantine.dds",
	[ITEMSTYLE_RACIAL_WOOD_ELF]  	 = "/esoui/art/icons/crafting_gems_daedra_skull.dds",
	[ITEMSTYLE_RACIAL_ARGONIAN]  	 = "/esoui/art/icons/crafting_smith_potion_standard_f_002.dds",
	[ITEMSTYLE_RACIAL_BRETON]  		 = "/esoui/art/icons/crafting_metals_molybdenum.dds",
	[ITEMSTYLE_RACIAL_DARK_ELF] 	 = "/esoui/art/icons/crafting_metals_graphite.dds",
	[ITEMSTYLE_ENEMY_PRIMITIVE] 	 = "/esoui/art/icons/crafting_metals_argentum.dds",
	[ITEMSTYLE_RACIAL_IMPERIAL]  	 = "/esoui/art/icons/crafting_heavy_armor_sp_names_001.dds",
	[ITEMSTYLE_AREA_REACH]  		 = "/esoui/art/icons/crafting_smith_potion_standard_f_001.dds",
	[ITEMSTYLE_ENEMY_DAEDRIC] 		 = "/esoui/art/icons/crafting_walking_dead_mort_heart.dds",
	[ITEMSTYLE_AREA_ANCIENT_ELF] 	 = "/esoui/art/icons/crafting_ore_palladuim.dds",
	[ITEMSTYLE_AREA_DWEMER] 	     = "/esoui/art/icons/crafting_dwemer_shiny_tube.dds",
	[ITEMSTYLE_AREA_AKAVIRI]		 = "uespLog/images/aicon.dds",
	[ITEMSTYLE_GLASS]		 		 = "uespLog/images/malachite.dds",
	[ITEMSTYLE_AREA_XIVKYN] 		 = "uespLog/images/charcoal.dds",
	[ITEMSTYLE_UNDAUNTED] 			 = "/esoui/art/icons/crafting_laurel.dds",
	[ITEMSTYLE_AREA_ANCIENT_ORC] 	 = "/esoui/art/icons/crafting_smith_plug_standard_f_001.dds",
	[47]							 = "/esoui/art/icons/crafting_outlaw_styleitem.dds",		-- ITEMSTYLE_UNUSED9
	[ITEMSTYLE_DEITY_MALACATH]		 = "/esoui/art/icons/crafting_style_item_malacath.dds",
	[ITEMSTYLE_DEITY_TRINIMAC]		 = "/esoui/art/icons/crafting_style_item_trinimac.dds",
	[ITEMSTYLE_AREA_SOUL_SHRIVEN]	 = "/esoui/art/icons/crafting_runecrafter_plug_component_005.dds",
	[ITEMSTYLE_ALLIANCE_DAGGERFALL]  = "/esoui/art/icons/crafting_style_item_daggerfall_covenant.dds",
	[ITEMSTYLE_ALLIANCE_EBONHEART] 	 = "/esoui/art/icons/crafting_style_item_ebonheart_pact.dds",
	[ITEMSTYLE_ALLIANCE_ALDMERI] 	 = "/esoui/art/icons/crafting_style_item_aldmeri_dominion.dds",
	[ITEMSTYLE_UNIVERSAL] 			 = "/esoui/art/icons/crafing_universal_item.dds",	-- Incorrect spelling "crafing" in 1.9 PTS
	[ITEMSTYLE_ORG_THIEVES_GUILD] 	 = "/esoui/art/icons/crafting_style_item_thieves_guild_r2.dds",
	[ITEMSTYLE_ORG_ABAHS_WATCH] 	 = "/esoui/art/icons/crafting_style_item_abahs_watch_r2.dds",
	[ITEMSTYLE_ORG_ASSASSINS]	 	 = "/esoui/art/icons/crafting_style_item_assassins_league_r2.dds",
	[ITEMSTYLE_ORG_DARK_BROTHERHOOD] = "/esoui/art/icons/crafting_style_item_dark_brotherhood_r2.dds",
	[39] 							 = "/esoui/art/icons/crafting_style_item_minotaur_r2.dds",
	[16] 							 = "/esoui/art/icons/crafting_style_item_orderoth_r2.dds",
	[45] 							 = "/esoui/art/icons/crafting_style_item_dromothra_r2.dds",
	[58]							 = "/esoui/art/icons/crafting_style_item_harlequin_r2.dds",
	[59]							 = "/esoui/art/icons/crafting_style_item_hollowjack_r2.dds",
	[ITEMSTYLE_AREA_YOKUDAN] 		 = "/esoui/art/icons/crafting_humanoid_daedra_void_salts.dds",
	[27]							 = "/esoui/art/icons/crafting_style_item_celestial_r2.dds",
	[31]							 = "/esoui/art/icons/crafting_style_item_draugr_r2.dds",
	[42]							 = "/esoui/art/icons/crafting_style_item_wolfsbane_r2.dds",
	[53]							 = "/esoui/art/icons/crafting_runecrafter_armor__standard_r_003.dds",
	[56]							 = "/esoui/art/icons/crafting_style_item_mirrorsheen_r2.dds",
	[57]							 = "/esoui/art/icons/crafting_style_item_mazzatun_r2.dds",
	[44]							 = "/esoui/art/icons/crafting_style_item_ragada_r2.dds",
	[40]							 = "/esoui/art/icons/crafting_style_item_ebony_r2.dds",
}


uespLog.PROVISION_ICONS = {
	[1]   = "uespLog\\images\\newtrade1.dds",
	[2]   = "uespLog\\images\\newtrade2.dds",
	[3]   = "uespLog\\images\\newtrade3.dds",
	[4]   = "uespLog\\images\\newtrade4.dds",
	[5]   = "uespLog\\images\\newtrade5.dds",
	[6]   = "uespLog\\images\\newtrade6.dds",
	[10]   = "uespLog\\images\\newtrade10.dds",
	[11]   = "uespLog\\images\\newtrade11.dds",
	[12]   = "uespLog\\images\\newtrade12.dds",
	[20]   = "uespLog\\images\\newtrade20.dds",
	[21]   = "uespLog\\images\\newtrade21.dds",
	[22]   = "uespLog\\images\\newtrade22.dds",
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
	[10]   = uespLog.TRADE_NORMAL_COLOR,
	[11]   = uespLog.TRADE_NORMAL_COLOR,
	[12]   = uespLog.TRADE_NORMAL_COLOR,
	[20]   = uespLog.TRADE_NORMAL_COLOR,
	[21]   = uespLog.TRADE_NORMAL_COLOR,
	[22]   = uespLog.TRADE_NORMAL_COLOR,
	[100] = uespLog.TRADE_SUPERIOR_COLOR,
	[101] = uespLog.TRADE_EPIC_COLOR,
}


uespLog.PROVISION_TEXTS = {
	[1] = "Old Ingredient Level 1",
	[2] = "Old Ingredient Level 2",
	[3] = "Old Ingredient Level 3",
	[4] = "Old Ingredient Level 4",
	[5] = "Old Ingredient Level 5",
	[6] = "Old Ingredient Level 6",
	[10] = "Meat",
	[11] = "Fruit",
	[12] = "Vegetable",
	[20] = "Alcholic",
	[21] = "Tea",
	[22] = "Tonic",
	[100] = "Medium Ingredient",
	[101] = "Improvement Ingredient",
}


-- 1-6 = Provisioning level (no longer used since update #6)
-- 10 = Meats
-- 11 = Fruits
-- 12 = Vegetables
-- 20 = Alcholic
-- 21 = Tea
-- 22 = Tonic
-- 100 = Superior ingredient
-- 101 = Epic ingredient
uespLog.INGREDIENT_DATA = {
	[33753] = 10, 	-- Fish
	[28609] = 10, 	-- Game
	[34321] = 10, 	-- Poultry
	[33752] = 10, 	-- Red Meat
	[33756] = 10, 	-- Small Game
	[33754] = 10, 	-- White Meat
	[34311] = 11, 	-- Apples
	[33755] = 11, 	-- Bananas
	[28610] = 11, 	-- Jazbay Grapes
	[34308] = 11, 	-- Melon
	[34305] = 11, 	-- Pumpkin
	[28603] = 11, 	-- Tomato
	[34309] = 12, 	-- Beets
	[34324] = 12, 	-- Carrots or 28600?
	[34323] = 12, 	-- Corn
	[28604] = 12, 	-- Greens
	[33758] = 12, 	-- Potato
	[34307] = 12, 	-- Radish
	[34329] = 20, 	-- Barley
	[29030] = 20, 	-- Rice or 27060?
	[28639] = 20, 	-- Rye or 33744?
	[34345] = 20, 	-- Surilie Grapes or 28650?
	[34348] = 20, 	-- Wheat
	[33774] = 20, 	-- Yeast
	[34334] = 21, 	-- Bittergreen
	[33768] = 21, 	-- Comberry
	[33771] = 21, 	-- Jasmine
	[34330] = 21, 	-- Lotus
	[33773] = 21, 	-- Mint
	[28636] = 21, 	-- Rose
	[34349] = 22, 	-- Acai Berry
	[33772] = 22, 	-- Coffee
	[34346] = 22, 	-- Ginkgo
	[34347] = 22, 	-- Ginseng
	[34333] = 22, 	-- Guarana
	[34335] = 22, 	-- Yerba Mate
	[27057] = 100,	-- Cheese
	[27100] = 100,	-- Flour
	[26954] = 100,	-- Garlic
	[27064] = 100,	-- Millet
	[27063] = 100,	-- Saltrice or 28625?
	[27058] = 100,	-- Seasoning
	[27052] = 100,	-- Ginger
	[27043] = 100,	-- Honey
	[27035] = 100,	-- Isinglass
	[27049] = 100,	-- Lemon
	[27048] = 100,	-- Metheglin
	[28666] = 100,	-- Seaweed
	[26802] = 101,	-- Frost Mirriam
	[27059] = 101,	-- Bervez Juice
}


function uespLog.InitTradeData()
	uespLog.SetupInventoryHooks()
end


function uespLog.SetupInventoryHooks()
	EVENT_MANAGER:RegisterForEvent("uespLog", EVENT_STABLE_INTERACT_START, uespLog.OnStableInteractStart)
    EVENT_MANAGER:RegisterForEvent("uespLog", EVENT_STABLE_INTERACT_END, uespLog.OnStableInteractEnd)
	
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


function uespLog.OnStableInteractStart()
	--uespLog.DebugExtraMsg("OnStableInteractStart")
	uespLog.isStableInteract = true
end


function uespLog.OnStableInteractEnd()
	--uespLog.DebugExtraMsg("OnStableInteractEnd")
	uespLog.isStableInteract = false
end


function uespLog.UpdateInventoryContextMenuHook(rowControl) 
	local controlName = ""
	local parentName = ""
	local parentName2 = ""
	
	if (rowControl == nil) then
		return
	end
	
	controlName = rowControl:GetName()
	
	if (controlName == nil) then
		return
	end
	
	if (rowControl:GetParent() ~= nil) then
		parentName = rowControl:GetParent():GetName()
		
		if (rowControl:GetParent():GetParent() ~= nil) then
			parentName2 = rowControl:GetParent():GetParent():GetName()
		end
	end
	
	--uespLog.DebugExtraMsg("parentName::"..parentName..",  parentName2::"..parentName2)

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
	AddMenuItem("Copy Item Link", function() uespLog.CopyItemLinkRowControl(rowControl) end, MENU_ADD_OPTION_LABEL)
	
	if (uespLog.IsSalesShowPrices()) then
		AddMenuItem("UESP Price to Chat", function() uespLog.SalesPriceToChatRowControl(rowControl) end, MENU_ADD_OPTION_LABEL)
	end
	
	ShowMenu(self)
end


function uespLog.TestInventoryClick() 
	uespLog.DebugMsg("TestInventoryClick")
end


function uespLog.AddDetailsToInfoToolTip (row)	
	--uespLog.DebugMsg("InfoRow = "..tostring(row.dataEntry))
	return uespLog.AddCraftDetailsToToolTip(row)	
end


function uespLog.AddCraftDetailsToPopupToolTip() 

	if (PopupTooltip == nil) then
		return false
	end

	if (uespLog.lastPopupLink == PopupTooltip.lastLink) then
		return false
	end
	
	uespLog.lastPopupLink = PopupTooltip.lastLink
	
	return uespLog.AddCraftDetailsToToolTip(PopupTooltip, PopupTooltip.lastLink)
end


function uespLog.AddCraftDetailsToToolTipRow (row)	

	if (not uespLog.IsCraftDisplay()) or row == nil then
		return false
	end
	
	if (uespLog.isStableInteract) then
		return false
	end
	
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
	local tradingHouseMode = TRADING_HOUSE:GetCurrentMode()
	local isTradingHouseListing = false
	
	if (slotIndex and bagId) then
		itemLink = GetItemLink(bagId, slotIndex)
	elseif (slotIndex) then
		if (tradingHouseMode == ZO_TRADING_HOUSE_MODE_BROWSE and TRADING_HOUSE.m_numItemsOnPage ~= nil and TRADING_HOUSE.m_numItemsOnPage >= slotIndex and slotIndex > 0) then
			itemLink = GetTradingHouseSearchResultItemLink(slotIndex)
			isTradingHouseListing = true
		elseif (tradingHouseMode == ZO_TRADING_HOUSE_MODE_LISTINGS and GetNumTradingHouseListings() >= slotIndex and slotIndex > 0) then
			itemLink = GetTradingHouseListingItemLink(slotIndex)
		else
			return false
		end
	elseif (bagId and GetNumLootItems() >= bagId) then
		itemLink = GetLootItemLink(bagId)
	else
		return false
	end
			
	uespLog.AddCraftDetailsToToolTip(ItemTooltip, itemLink, bagId, slotIndex)
	
	if (isTradingHouseListing) then
		local icon, itemName, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType = GetTradingHouseSearchResultItemInfo(slotIndex)
		
		if (stackCount > 1) then
			local pricePerItem = purchasePrice / stackCount
			local priceMsg = string.format("Price per Item = %0.2f", pricePerItem)
			local color1, color2, color3 = unpack(uespLog.TRADE_PRICE_COLOR)
			ItemTooltip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE)
			ItemTooltip:AddLine(priceMsg, "ZoFontGame", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
		end
	end
	
	return true
end


function uespLog.AddCraftDetailsToToolTip(ThisToolTip, itemLink, bagId, slotIndex)	

	if (not uespLog.IsCraftDisplay()) then
		return false
	end
	
	if (itemLink == nil or itemLink == "" or ThisToolTip == nil) then
		return false
	end
	
	if (uespLog.isStableInteract) then
		return false
	end
	
	local itemId = uespLog.GetItemLinkID(itemLink)
	local tradeType = uespLog.GetItemTradeType(itemId)
	local iconTexture, iconColor = uespLog.GetTradeIconTexture(itemId, itemLink)
	local color1, color2, color3
	local itemStyleIcon, itemStyleText = uespLog.GetItemStyleIcon(itemLink)
	local addedBlankLine = false
	local itemType = GetItemLinkItemType(itemLink)
	local equipType = GetItemLinkEquipType(itemLink)
	local itemText = ""
	local fontName = "ZoFontWinH5"
	
	if (itemStyleIcon ~= nil and (itemType == 1 or itemType == 2) and (equipType ~= 12 and equipType ~= 2) and uespLog.IsCraftStyleDisplay()) then
		color1, color2, color3 = unpack(uespLog.TRADE_STYLE_COLOR)
		ThisToolTip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE)
		ThisToolTip:AddLine("Item Style: "..tostring(itemStyleText), "ZoFontWinH4", color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
		addedBlankLine = true
	end
	
	if (iconTexture ~= nil and tradeType ~= nil) then
	
		if (uespLog.IsCraftIngredientDisplay()) then
			itemText = uespLog.GetItemTradeTypeText(tradeType)
			color1, color2, color3 = unpack(iconColor)
		
			if (not addedBlankLine) then
				ThisToolTip:AddLine("", "ZoFontWinH5", color1, color2, color3, BOTTOM, 0)
			end
				ThisToolTip:AddLine(itemText, "ZoFontWinH5", color1, color2, color3, BOTTOM, 0)
		end
		
		return false
	end
	
	itemText = ""
	iconColor = uespLog.TRADE_KNOWN_COLOR
	
		-- Motifs
	if (itemType == 8) then
		if (uespLog.IsCraftRecipeDisplay() and uespLog.IsCraftDisplay()) then
			local isKnown, isCertain = IsItemLinkBookKnown(itemLink)
			
			if (not isCertain) then
				itemText = ""
				iconColor = uespLog.TRADE_KNOWN_COLOR
			elseif (isKnown) then
				itemText = "Motif Known"
				iconColor = uespLog.TRADE_KNOWN_COLOR
			else
				itemText = "Motif Unknown"
				iconColor = uespLog.TRADE_UNKNOWN_COLOR
			end
		end
		
		-- Enchanting Potency Runestone
	elseif (itemType == 51) then
		local glyphMinLevel, glyphMinCP = GetItemLinkGlyphMinLevels(itemLink)
		local minString = ""
		
		if (glyphMinLevel ~= nil) then
			minString = "level "..tostring(glyphMinLevel)
		elseif (glyphMinCP ~= nil) then
			minString = "|t24:24:esoui/art/champion/champion_icon.dds|t CP "..tostring(glyphMinCP)
		end
		
		itemText = "Used to create glyphs of "..minString.." and higher."
		
		iconColor = uespLog.TRADE_NORMALTEXT_COLOR
		fontName = "ZoFontGame"
	end

	local isResearchable = uespLog.CheckIsItemLinkResearchable(itemLink)
	
	if (isResearchable >= 0 and uespLog.IsCraftTraitDisplay()) then
		local isResearching = uespLog.IsResearchingItemLink(itemLink)
	
		if (isResearchable == uespLog.ORNATE_TRAIT_INDEX) then
			itemText = "Ornate"
			iconColor = uespLog.TRADE_ORNATE_COLOR
		elseif (isResearchable == uespLog.INTRICATE_TRAIT_INDEX) then
			itemText = "Intricate"
			iconColor = uespLog.TRADE_INTRICATE_COLOR
		elseif (isResearchable > 0) then
			itemText = "Trait Unknown"
			iconColor = uespLog.TRADE_UNKNOWN_COLOR
		elseif (isResearching) then
			itemText = "Trait Researching"
			iconColor = uespLog.TRADE_KNOWN_COLOR
		else
			itemText = "Trait Known"
			iconColor = uespLog.TRADE_KNOWN_COLOR
		end
		
	end
	
	if (itemText ~= "") then
		color1, color2, color3 = unpack(iconColor)	
		
		if (not addedBlankLine) then
			ThisToolTip:AddLine("", fontName, color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
		end
		
		ThisToolTip:AddLine(itemText, fontName, color1, color2, color3, BOTTOM, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
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
		uespLog.Msg("UESP: Failed to hook the inventory callback!")
	end
		
    return true
end


function uespLog.AddCraftInfoToInventorySlot (rowControl, hookData, list)
	--local bagId list.dataEntry.data.bagId
	--local slotIndex = list.dataEntry.data.slotIndex
	
	if (rowControl == nil or hookData == nil or list == nil) then
		return
	end
	
	if (uespLog.isStableInteract) then
		return
	end
	
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
	local itemType = GetItemLinkItemType(itemLink)
	local equipType = GetItemLinkEquipType(itemLink)
	local iconOffset = 25
	
	if (list == LOOT_WINDOW.list) then
		iconOffset = 50
	end
	
	iconControl:SetHidden(true)		
	iconControl:SetDimensions(32, 32)
	iconControl:ClearAnchors()
	--iconControl:SetAnchor(RIGHT, rowControl, RIGHT, -50)
	iconControl:SetAnchor(CENTER, rowControl, CENTER, 110 + iconOffset)
		
	styleIconControl:SetHidden(true)		
	styleIconControl:SetDimensions(32, 32)
	styleIconControl:ClearAnchors()
	styleIconControl:SetAnchor(CENTER, rowControl, CENTER, 85 + iconOffset)
	
	if (itemStyleIcon ~= nil and (itemType == 1 or itemType == 2) and (equipType ~= 12 and equipType ~= 2) and uespLog.IsCraftStyleDisplay()) then
		styleIconControl:SetHidden(false)		
		styleIconControl:SetTexture(itemStyleIcon)
		--iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
	end
	
	if (iconTexture ~= nil) then
	
		if (uespLog.IsCraftIngredientDisplay() and uespLog.IsCraftDisplay()) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(iconTexture)
	
			iconControl:SetColor(unpack(iconColor))
			if (nameControl ~= nil) then nameControl:SetColor(unpack(iconColor)) end
		end
		
		return
	end
	
	if (itemType == ITEMTYPE_RECIPE) then
		if (uespLog.IsCraftRecipeDisplay() and uespLog.IsCraftDisplay()) then
			if (IsItemLinkRecipeKnown(itemLink)) then
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
	
		-- Motifs
	if (itemType == 8) then
		if (uespLog.IsCraftRecipeDisplay() and uespLog.IsCraftDisplay()) then
			local isKnown, isCertain = IsItemLinkBookKnown(itemLink)
			
			if (not isCertain) then
				iconControl:SetHidden(true)		
			elseif (isKnown) then
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

	if (uespLog.IsCraftTraitDisplay() and uespLog.IsCraftDisplay()) then
	
		if (isResearchable == uespLog.ORNATE_TRAIT_INDEX) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(uespLog.TRADE_ORNATE_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
			iconControl:SetColor(unpack(uespLog.TRADE_ORNATE_COLOR))
		elseif (isResearchable == uespLog.INTRICATE_TRAIT_INDEX) then
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


function uespLog.CheckIsItemLinkResearchable(itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	
	if (itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
		return -8
	end

	local traitType = GetItemLinkTraitInfo(itemLink)
	local traitIndex = traitType

	if (traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return uespLog.ORNATE_TRAIT_INDEX
	elseif (traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return uespLog.INTRICATE_TRAIT_INDEX
	end
	
	if (traitIndex <= 0) then
		return -1
	end

	local _,_,_,_,_,equipType = GetItemLinkInfo(itemLink)
	
	if (equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK) then
		return -5
	end

	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if (traitIndex == 25) then -- Nirnhoned
		traitIndex = 9
	elseif (traitIndex == 26) then -- Nirnhoned
		traitIndex = 9
	elseif (traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if (not (traitIndex >= 1 and traitIndex <= 9)) then
		--uespLog.DebugMsg("        -4:"..tostring(traitIndex))
		return -4
	end
	
	local craftType = uespLog.GetItemLinkCraftSkillType(itemLink)
	
	if (craftType <= 0) then
		return -11
	end

	return uespLog.CheckIsItemLinkResearchableInSkill(itemLink, itemType, equipType, craftType, traitIndex)
end


function uespLog.CheckIsItemResearchable(bagId, slotIndex)
	local itemType = GetItemType(bagId, slotIndex)
	
	if (itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON) then
		return -8
	end

	local traitType = GetItemTrait(bagId, slotIndex)
	local traitIndex = traitType

	if (traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return uespLog.ORNATE_TRAIT_INDEX
	elseif (traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return uespLog.INTRICATE_TRAIT_INDEX
	end
	
	if (traitIndex == 25) then
		traitIndex = 9
	elseif (traitIndex == 26) then
		traitIndex = 9
	elseif (traitIndex <= 0) then
		return -1
	end

	local _,_,_,_,_,equipType = GetItemInfo(bagId, slotIndex)
	
	if (equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK) then
		return -5
	end
	
	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if (traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if (not (traitIndex >= 1 and traitIndex <= 9)) then
		--uespLog.DebugExtraMsg("        -4b: "..tostring(traitIndex))
		return -4
	end

	local check1 = uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_BLACKSMITHING, traitIndex)
	if (check1 >= 0) then return check1 end
	
	local check2 = uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_CLOTHIER, traitIndex)
	if (check2 >= 0) then return check2 end
	
	return uespLog.CheckIsItemResearchableInSkill(bagId, slotIndex, equipType, CRAFTING_TYPE_WOODWORKING, traitIndex)
end


function uespLog.GetItemLinkCraftSkillType (itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	
	if (itemType == ITEMTYPE_ARMOR) then
		local armorType = GetItemLinkArmorType(itemLink)
		
		if (armorType == ARMORTYPE_MEDIUM or armorType == ARMORTYPE_LIGHT) then
			return CRAFTING_TYPE_CLOTHIER
		elseif (armorType == ARMORTYPE_HEAVY) then
			return CRAFTING_TYPE_BLACKSMITHING
		end		
	end

	if (itemType == ITEMTYPE_WEAPON) then
		local weaponType = GetItemLinkWeaponType(itemLink)
		
		if (weaponType == WEAPONTYPE_SHIELD) then
			return CRAFTING_TYPE_WOODWORKING
		elseif (weaponType == WEAPONTYPE_BOW) then
			return CRAFTING_TYPE_WOODWORKING
		elseif (weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_HEALING_STAFF or weaponType == 15) then
			return CRAFTING_TYPE_WOODWORKING
		else
			return CRAFTING_TYPE_BLACKSMITHING
		end
		
	end
	
	return -1
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


uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT = {

	[CRAFTING_TYPE_BLACKSMITHING] = {
		[ITEMTYPE_ARMOR] = {
			[ARMORTYPE_HEAVY] = {
				[EQUIP_TYPE_CHEST] = 8,
				[EQUIP_TYPE_FEET] = 9,
				[EQUIP_TYPE_HAND] = 10,
				[EQUIP_TYPE_HEAD] = 11,
				[EQUIP_TYPE_LEGS] = 12,
				[EQUIP_TYPE_SHOULDERS] = 13,
				[EQUIP_TYPE_WAIST] = 14,
			}
		},
		[ITEMTYPE_WEAPON] = {
			[WEAPONTYPE_AXE] = 1,
			[WEAPONTYPE_HAMMER] = 2,
			[WEAPONTYPE_SWORD] = 3,
			[WEAPONTYPE_TWO_HANDED_AXE] = 4,
			[WEAPONTYPE_TWO_HANDED_HAMMER] = 5,
			[WEAPONTYPE_TWO_HANDED_SWORD] = 6,
			[WEAPONTYPE_DAGGER] = 7,
		}		
	},
	
	[CRAFTING_TYPE_CLOTHIER] = {
		[ITEMTYPE_ARMOR] = {
			[ARMORTYPE_LIGHT] = {
				[EQUIP_TYPE_CHEST] = 1,
				[EQUIP_TYPE_FEET] = 2,
				[EQUIP_TYPE_HAND] = 3,
				[EQUIP_TYPE_HEAD] = 4,
				[EQUIP_TYPE_LEGS] = 5,
				[EQUIP_TYPE_SHOULDERS] = 6,
				[EQUIP_TYPE_WAIST] = 7,
			},
			[ARMORTYPE_MEDIUM] = {
				[EQUIP_TYPE_CHEST] = 8,
				[EQUIP_TYPE_FEET] = 9,
				[EQUIP_TYPE_HAND] = 10,
				[EQUIP_TYPE_HEAD] = 11,
				[EQUIP_TYPE_LEGS] = 12,
				[EQUIP_TYPE_SHOULDERS] = 13,
				[EQUIP_TYPE_WAIST] = 14,
			},
		}
	},
	
	[CRAFTING_TYPE_WOODWORKING] = {
		[ITEMTYPE_WEAPON] = {
			[WEAPONTYPE_BOW] = 1,
			[WEAPONTYPE_FIRE_STAFF] = 2,
			[WEAPONTYPE_FROST_STAFF] = 3,
			[15] = 4,		
			[WEAPONTYPE_HEALING_STAFF] = 5,
			[WEAPONTYPE_SHIELD] = 6,
		}
	},
}


function uespLog.CheckIsItemLinkResearchableInSkill(itemLink, itemType, equipType, craftType, traitIndex)
	local numLines = GetNumSmithingResearchLines(craftType)
	local realTraitType = GetItemLinkTraitInfo(itemLink)
	local researchLineIndex = uespLog.GetItemLinkResearchLineIndex(itemLink)
	
	if (researchLineIndex <= 0) then
		return -1
	end

	local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftType, researchLineIndex)
    local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftType, researchLineIndex, traitIndex)
	--uespLog.DebugMsg("UESP: "..itemLink..":"..tostring(traitType)..", "..tostring(traitDescription)..","..tostring(known)..", "..tostring(researchLineIndex)..", "..tostring(name))
		
	if (traitType ~= nil and traitType ~= 0 and known) then
		return 0
	end
	
	if (uespLog.IsResearchingItemLink(itemLink)) then
		return 0
	end

	return 1
end


function uespLog.GetItemLinkResearchLineIndex(itemLink)
	local researchLineIndex = -1
	local craftType = uespLog.GetItemLinkCraftSkillType(itemLink)
	local itemType = GetItemLinkItemType(itemLink)

	if (uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType] == nil) then
		return -1
	end
	
	if (uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType] == nil) then
		return -2
	end
	
	if (itemType == ITEMTYPE_WEAPON) then
		local weaponType = GetItemLinkWeaponType(itemLink) 
		
		if (uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType][weaponType] == nil) then
			return -3
		end
		
		researchLineIndex = uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType][weaponType] 
		
	elseif (itemType == ITEMTYPE_ARMOR) then
		local equipType = GetItemLinkEquipType(itemLink) 
		local armorType = GetItemLinkArmorType(itemLink)
		
		if (uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType][armorType] == nil) then
			return -4
		end
		
		if (uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType][armorType][equipType] == nil) then
			return -5
		end
		
		researchLineIndex = uespLog.CRAFTING_SKILL_RESEARCHLINE_CONVERT[craftType][itemType][armorType][equipType] 
	end
	
	return researchLineIndex
end


function uespLog.IsResearchingItemLink(itemLink)
    local craftingType = uespLog.GetItemLinkCraftSkillType(itemLink)
	local itemTraitType = GetItemLinkTraitInfo(itemLink)
	local researchLineIndex = uespLog.GetItemLinkResearchLineIndex(itemLink)
	local itemTraitIndex = itemTraitType
	
	if (itemTraitIndex == 25 or itemTraitIndex == 26) then
		itemTraitIndex = 9
	end
	
	if (craftingType <= 0 or researchLineIndex <= 0) then
		return false
	end

	local numLines = GetNumSmithingResearchLines(craftingType)
	local maxSimultaneousResearch = GetMaxSimultaneousSmithingResearch(craftingType)
	
	if (numLines == 0 or maxSimultaneousResearch == 0) then
		return false
	end
	
	local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
		
	for traitIndex = 1, numTraits do
		local duration, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
		local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			
		if (duration ~= nil and traitType == itemTraitType) then
			return true
		end
	end
	
	return false
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
	uespLog.DebugMsg("UESP: Dumping item control "..tostring(itemControl))
	
	uespLog.printDumpObject = true
	--uespLog.DumpObject("PopupTooltip", getmetatable(PopupTooltip), 0, 2)
		
	--for k, v in pairs(PopupTooltip) do
		--uespLog.DebugMsg(".    " .. tostring(k) .. "=" .. tostring(v))
	--end
	
	local numChildren = itemControl:GetNumChildren()
	uespLog.DebugMsg("UESP: Has "..tostring(numChildren).." children")
	
    for i = 1, numChildren do
        local child = itemControl:GetChild(i)
		--uespLog.DumpObject("child", getmetatable(child), 0, 2)
		local name = child:GetName()
		uespLog.DebugMsg(".   "..tostring(i)..") "..tostring(name))
    end
	
	uespLog.printDumpObject = false
end


function uespLog.GetItemTradeType(itemId)
	return uespLog.INGREDIENT_DATA[itemId], 0
end


function uespLog.GetItemTradeTypeText(tradeType)

	if (uespLog.PROVISION_TEXTS[tradeType] ~= nil) then
		return uespLog.PROVISION_TEXTS[tradeType]
	end
	
	return "Unknown"
end


function uespLog.GetTradeIconTexture (itemId, itemLink)
	local tradeType = uespLog.GetItemTradeType(itemId)
	
	if (tradeType == nil or tradeType <= 0) then 
		return nil, nil
	end
	
	if (uespLog.PROVISION_ICONS[tradeType] ~= nil) then
		return uespLog.PROVISION_ICONS[tradeType], uespLog.PROVISION_COLORS[tradeType]
	end
	
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
	uespLog.Msg("/uespcraft on/off            -- Turns all crafting displays on/off")
	uespLog.Msg("/uespcraft style on/off      -- Turns style display on/off")
	uespLog.Msg("/uespcraft trait on/off      -- Turns trait display on/off")
	uespLog.Msg("/uespcraft recipe on/off     -- Turns recipe display on/off")
	uespLog.Msg("/uespcraft ingredient on/off -- Turns ingredient display on/off")
    uespLog.Msg("Craft display is "..uespLog.BoolToOnOff(uespLog.IsCraftDisplay()))
	uespLog.Msg("Craft style display is "..uespLog.BoolToOnOff(uespLog.IsCraftStyleDisplay()))
	uespLog.Msg("Craft trait display is "..uespLog.BoolToOnOff(uespLog.IsCraftTraitDisplay()))
	uespLog.Msg("Craft recipe display is "..uespLog.BoolToOnOff(uespLog.IsCraftRecipeDisplay()))
	uespLog.Msg("Craft ingredient display is "..uespLog.BoolToOnOff(uespLog.IsCraftIngredientDisplay()))
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


function uespLog.UpdateCraftDisplay()
	ZO_ScrollList_RefreshVisible(ZO_PlayerInventoryBackpack)
	ZO_ScrollList_RefreshVisible(ZO_PlayerBankBackpack)
	ZO_ScrollList_RefreshVisible(ZO_GuildBankBackpack)	
	ZO_ScrollList_RefreshVisible(ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack)
end


function uespLog.SetCraftDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craft = flag
	uespLog.UpdateCraftDisplay()
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
	uespLog.UpdateCraftDisplay()
end	


function uespLog.SetCraftTraitDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftTrait = flag
	uespLog.UpdateCraftDisplay()
end	


function uespLog.SetCraftIngredientDisplay(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.craftIngredient = flag
	uespLog.UpdateCraftDisplay()
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
			uespLog.Msg("Turned recipe display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftRecipeDisplay(false)
			uespLog.Msg("Turned recipe display off")
		else
			uespLog.Msg("Craft recipe display is "..uespLog.BoolToOnOff(uespLog.IsCraftRecipeDisplay()))
		end
		
	elseif (cmdWords[1] == "ingredient") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftIngredientDisplay(true)
			uespLog.Msg("Turned ingredient display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftIngredientDisplay(false)
			uespLog.Msg("Turned ingredient display off")
		else
			uespLog.Msg("Craft ingredient display is "..uespLog.BoolToOnOff(uespLog.IsCraftIngredientDisplay()))
		end
		
	elseif (cmdWords[1] == "style") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftStyleDisplay(true)
			uespLog.Msg("Turned style display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftStyleDisplay(false)
			uespLog.Msg("Turned style display off")
		else
			uespLog.Msg("Craft style display is "..uespLog.BoolToOnOff(uespLog.IsCraftStyleDisplay()))
		end
				
	elseif (cmdWords[1] == "trait") then
	
		if (cmdWords[2] == "on") then
			uespLog.SetCraftTraitDisplay(true)
			uespLog.Msg("Turned trait display on")
		elseif (cmdWords[2] == "off") then
			uespLog.SetCraftTraitDisplay(false)
			uespLog.Msg("Turned trait display off")
		else
			uespLog.Msg("Craft trait display is "..uespLog.BoolToOnOff(uespLog.IsCraftTraitDisplay()))
		end
		
	elseif (cmdWords[1] == "autoloot") then
		uespLog.Msg("Craft autoloot is deprecated since update #6")
	elseif (cmdWords[1] == "minprovlevel") then
		uespLog.Msg("Craft autoloot is deprecated since update #6")
	elseif (cmdWords[1] == "on") then
		uespLog.SetCraftDisplay(true)
		uespLog.Msg("Turned crafting display on")
	elseif (cmdWords[1] == "off") then
		uespLog.SetCraftDisplay(false)
		uespLog.Msg("Turned crafting display off")
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
	local numLoot = GetNumLootItems()
	local MinProvLevel = uespLog.GetCraftAutoLootMinProvLevel()
	
	uespLog.DebugExtraMsg("UESP: Auto looting "..tostring(numLoot).." items...")
	LootMoney()
	
	local targetName, targetType, actionName = GetLootTargetInfo()
	
	local extraLogData = { }
	extraLogData.lootTarget = targetName
	extraLogData.targetType = targetType
	extraLogData.actionName = actionName
	extraLogData.skippedLoot = 1
	
	for lootIndex = 1, numLoot do
		local lootId, name, icon, count, quality, value, isQuest, isStolen = GetLootItemInfo(lootIndex)
		local itemLink = GetLootItemLink(lootId)
		local itemId = uespLog.GetItemLinkID(itemLink)
		local tradeType, alwaysLoot = uespLog.GetItemTradeType(lootId)
		
		-- uespLog.DebugExtraMsg("UESP: Auto looting "..tostring(itemLink))
		
		extraLogData.tradeType = tradeType
		
		if (tradeType == nil or tradeType >= MinProvLevel or alwaysLoot) then
			LootItemById(lootId)
		else
			uespLog.OnLootGained("LootGained", "player", itemLink, count, nil, nil, true, false, extraLogData)
		end
	end
	
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


-- The following is copy/pasted from ingame/tradinghouse/tradinghouse.lua due to use of local
-- functions needed to hook into the trader listing for updates.
local SEARCH_RESULTS_DATA_TYPE = 1
local ITEM_LISTINGS_DATA_TYPE = 2
local GUILD_SPECIFIC_ITEM_DATA_TYPE = 3


local ITEM_RESULT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

TRADING_HOUSE.InitializeSearchResults = function(self, control)
    local searchResultsList = control:GetNamedChild("ItemPaneSearchResults")
    self.m_searchResultsList = searchResultsList
    self.m_searchResultsControlsList = {}
    self.m_searchResultsInfoList = {}
	
    local function SetupBaseSearchResultRow(rowControl, result)
        self.m_searchResultsControlsList[#self.m_searchResultsControlsList+1] = rowControl
        self.m_searchResultsInfoList[#self.m_searchResultsInfoList+1] = result
        local slotIndex = result.slotIndex
        local nameControl = GetControl(rowControl, "Name")
        nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, result.name))
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, result.quality)
        nameControl:SetColor(r, g, b, 1)
        local sellerControl = GetControl(rowControl, "SellerName")
        sellerControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_SELLER_NAME, result.sellerName))
        local sellPriceControl = GetControl(rowControl, "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, result.currencyType, result.purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS, nil, self.m_playerMoney[result.currencyType] < result.purchasePrice)
        local resultControl = GetControl(rowControl, "Button")
        ZO_Inventory_SetupSlot(resultControl, result.stackCount, result.icon)
        -- Cached for verification when the player tries to purchase this
        resultControl.sellerName = result.sellerName
        resultControl.purchasePrice = result.purchasePrice
        resultControl.currencyType = result.currencyType
			
        return resultControl
    end
	
    local function SetupSearchResultRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)
        local timeRemainingControl = GetControl(rowControl, "TimeRemaining")
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(result.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))
        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT, result.slotIndex)
		
		uespLog.AddCraftInfoToTraderSlot(rowControl, result) 	-- Added
    end
	
    local function SetupGuildSpecificItemRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)
        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_GUILD_SPECIFIC_ITEM, result.slotIndex)
    end
	
    ZO_ScrollList_Initialize(searchResultsList)
    ZO_ScrollList_AddDataType(searchResultsList, SEARCH_RESULTS_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupSearchResultRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddDataType(searchResultsList, GUILD_SPECIFIC_ITEM_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupGuildSpecificItemRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddResizeOnScreenResize(searchResultsList)
end
-- End of copy/paste from ingame/tradinghouse/tradinghouse.lua


function uespLog.AddCraftInfoToTraderSlot (rowControl, result)

	if (not uespLog.IsCraftDisplay()) then
		return
	end

	if (TRADING_HOUSE:GetCurrentMode() ~= ZO_TRADING_HOUSE_MODE_BROWSE) then
		return
	end
	
	local iconControl = uespLog.GetIconControl(rowControl)
	local styleIconControl = uespLog.GetStyleIconControl(rowControl)
	local slotIndex = result.slotIndex
	local itemLink = GetTradingHouseSearchResultItemLink(result.slotIndex)
	
	iconControl:SetHidden(true)		
	iconControl:SetDimensions(32, 32)
	iconControl:ClearAnchors()
	iconControl:SetAnchor(CENTER, rowControl, CENTER, 195)
		
	styleIconControl:SetHidden(true)		
	styleIconControl:SetDimensions(32, 32)
	styleIconControl:ClearAnchors()
	styleIconControl:SetAnchor(CENTER, rowControl, CENTER, 225)
	
	if (itemLink == nil or itemLink == "") then
		return
	end
	
	local itemId = uespLog.GetItemLinkID(itemLink)	
	local tradeType = uespLog.GetItemTradeType(itemId)
	local iconTexture, iconColor = uespLog.GetTradeIconTexture(itemId, itemLink)
	local itemStyleIcon, itemStyleText = uespLog.GetItemStyleIcon(itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	local equipType = GetItemLinkEquipType(itemLink)
	
	if (itemStyleIcon ~= nil and (itemType == 1 or itemType == 2) and (equipType ~= 12 and equipType ~= 2) and uespLog.IsCraftStyleDisplay()) then
		styleIconControl:SetHidden(false)		
		styleIconControl:SetTexture(itemStyleIcon)
	end
	
	local isResearchable = uespLog.CheckIsItemLinkResearchable(itemLink)

	if (isResearchable >= 0 and uespLog.IsCraftTraitDisplay() and uespLog.IsCraftDisplay()) then
	
		if (isResearchable == uespLog.ORNATE_TRAIT_INDEX) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(uespLog.TRADE_ORNATE_TEXTURE)
			iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
			iconControl:SetColor(unpack(uespLog.TRADE_ORNATE_COLOR))
		elseif (isResearchable == uespLog.INTRICATE_TRAIT_INDEX) then
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
	
		-- Motifs
	if (itemType == 8) then
		if (uespLog.IsCraftRecipeDisplay() and uespLog.IsCraftDisplay()) then
			local isKnown, isCertain = IsItemLinkBookKnown(itemLink)
			
			if (not isCertain) then
				iconControl:SetHidden(true)		
			elseif (isKnown) then
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
	
	if (iconTexture ~= nil) then
		if (uespLog.IsCraftIngredientDisplay() and uespLog.IsCraftDisplay()) then
			iconControl:SetHidden(false)		
			iconControl:SetTexture(iconTexture)
			iconControl:SetColor(unpack(iconColor))
			if (nameControl ~= nil) then nameControl:SetColor(unpack(iconColor)) end
		end
		
		return
	end
	
	if (itemType == ITEMTYPE_RECIPE) then
		if (uespLog.IsCraftRecipeDisplay() and uespLog.IsCraftDisplay()) then
			if (IsItemLinkRecipeKnown(itemLink)) then
				iconControl:SetHidden(false)		
				iconControl:SetTexture(uespLog.TRADE_KNOWN_TEXTURE)
				iconControl:SetColor(unpack(uespLog.TRADE_KNOWN_COLOR))
			else
				iconControl:SetHidden(false)		
				iconControl:SetTexture(uespLog.TRADE_UNKNOWN_TEXTURE)
				iconControl:SetColor(unpack(uespLog.TRADE_UNKNOWN_COLOR))
			end
		end
	end
	
end



