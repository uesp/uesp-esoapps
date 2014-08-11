
	-- Add all files to combine and convert here
INPUT_FILENAMES = {
	"d:\\esoexport\\uespLog\\uespTest.lua",
	"d:\\esoexport\\uespLog\\uespLog.lua",
	"d:\\esoexport\\uespLog\\uespLog(1).lua",
	"d:\\esoexport\\uespLog\\uespLog (2).lua",
	"d:\\esoexport\\uespLog\\uespLog (3).lua",
	"d:\\esoexport\\uespLog\\uespLog (4).lua",
	"d:\\esoexport\\uespLog\\uespLog (5).lua",
	"d:\\esoexport\\uespLog\\uespLog (6).lua",
	"d:\\esoexport\\uespLog\\uespLog 02.lua",
	"d:\\esoexport\\uespLog\\Esohead.lua",	
}


ItemIdMap = { }


	-- Specify the output path here
	-- Make sure this path and '\books' exists
OUTPUT_PATH = "d:\\esoexport\\uespLog\\output\\"

	-- The field seperator character (usually , for CSV)
FIELD_SEP = ","
LINE_TERMINATOR = "\n"
STRING_QUOTE_CHAR = "\""


	-- Don't need to change the below values unless desired
OUTPUT_BOOK_PATH = OUTPUT_PATH .. "books\\"
OUTPUT_LOCATION_FILENAME = OUTPUT_PATH .. "locations.csv"
OUTPUT_ITEM_FILENAME = OUTPUT_PATH .. "items.csv"
OUTPUT_QUEST_FILENAME = OUTPUT_PATH .. "quests.csv"
OUTPUT_GLOBAL_FILENAME = OUTPUT_PATH .. "globals.csv"
OUTPUT_RECIPE_FILENAME = OUTPUT_PATH .. "recipes.csv"
OUTPUT_ACHIEVEMENT_FILENAME = OUTPUT_PATH .. "achievements.csv"
OUTPUT_LOREBOOK_FILENAME = OUTPUT_PATH .. "lorebooks.csv"
OUTPUT_BOOK_FILENAME = OUTPUT_PATH .. "books.csv"
OUTPUT_SKYSHARD_FILENAME = OUTPUT_PATH .. "skyshards.csv"
OUTPUT_NPC_FILENAME = OUTPUT_PATH .. "npcs.csv"
OUTPUT_CHEST_FILENAME = OUTPUT_PATH .. "chests.csv"
OUTPUT_FISH_FILENAME = OUTPUT_PATH .. "fishingholes.csv"
OUTPUT_DIALOG_FILENAME = OUTPUT_PATH .. "dialog.csv"
OUTPUT_MISCLOCATION_FILENAME = OUTPUT_PATH .. "misclocs.csv"
OUTPUT_ITEMDB_FILENAME = OUTPUT_PATH .. "itemdb.csv"
OUTPUT_COMBINEDLOCS_FILENAME = OUTPUT_PATH .. "combinedlocs.csv"


currentPlayerName = ""

ITEMDB_CSV_FORMAT = {
	"id",
	"name",
	"value",
	"trait",
	"quality",
	{ "type", "itemtype" },
	"equiptype",
	"crafttype",
	"icon"
}

COMBINEDLOC_CSV_FORMAT = {
	{ "category", "type" },
	"name",
	"x",
	"y",
	"zone",
	"timestamp",
	{ "user", "currentplayername" },
}

MISCLOCATION_CSV_FORMAT = {
	"type",
	"source",
	"itemname",
	"itemid",
	"qnt",
	"level",
	"material",
	"npcname",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"timestamp",
	{ "user", "currentplayername" },
}	

DIALOG_CSV_FORMAT = {
	"index",
	"text",
	"npcname",
	"npclevel",
	"option",
	"opttype",
	"optarg",
	"isimportant",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

NPC_CSV_FORMAT = {
	"name",
	"level",
	"gender",
	"difficulty",
	{ "maxhealth", "maxheath" },
	"maxmagic",
	"maxstamina",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

SKYSHARD_CSV_FORMAT = {
	"x",
	"y", 
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}		

CHEST_CSV_FORMAT = {
	"x",
	"y", 
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}		

FISH_CSV_FORMAT = {
	"x",
	"y", 
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}		

BOOK_CSV_FORMAT = {
	"booktitle",
	"medium",
	"booklength",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}	

LOREBOOK_CSV_FORMAT = {
	"booktitle",
	"categoryindex",
	"collectionindex",
	"bookindex",
	"guildindex",
	"icon",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

LOCATION_CSV_FORMAT = {
	"name",
	"x",
	"y",
	"z",
	"zone",
	"world",
	{ "user", "currentplayername" },
}

ITEM_CSV_FORMAT = {
	{ "name", "itemname" },
	{ "linkcolor", "itemcolor" },
	"baseitemid",
	"itemdata",
	--{ "itemsound", "itemsoundcategory" },
	{ "value", "money", "sellprice" },
	{ "style", "itemstyle" },
	{ "trait", "itemtrait" },
	"quality",
	{ "type", "itemtype" },
	"equiptype",
	{ "crafttype", "craftingtype", "usedincraftingtype" },
	"icon",
	{ "source", "lasttarget" },
	"qnt",
	"x",
	"y",
	"z",
	"zone",
	"world",
	"gametime",
	"timestamp",
	"event",
	{ "user", "currentplayername" },
}

QUEST_CSV_FORMAT = {
	"index",
	{ "name", "questname" },
	"objective",
	"conditiontext",
	"conditiontype",
	{ "conditionvalue", "newconditionval" },
	"conditionmax",
	{ "complete", "iscomplete" },
	"xpgained",
	"gametime",
	"event",
	{ "user", "player", "currentplayername" }
}
			
RECIPE_CSV_FORMAT = {
	"recipecount",
	"recipelist",
	"recipename",
	{ "recipelevel", "provlevelreq" },
	{ "recipequality", "qualityreq" },
	{ "specialingr", "specialingrtype" },
	"itemtype",
	{ "itemname", "name" },
	"itemlink",
	{ "qnt", "stack", "reqqnt" },
	{ "value", "sellprice" },
	"quality",
	"icon",
	{ "user", "currentplayername" },
}

GLOBAL_CSV_FORMAT = {
	"globaltype",
	"globalname",
}
		
ACHIEVEMENT_CSV_FORMAT = {
	"index",
	"category",
	"subcategory",
	"type",
	{ "name", "description", "category", "subcategory" },
	{ "points", "totalcatepoints", "totalsubcatepoints" },
	"icon",
	"itemlink"	
}


function appendCsvRowFormat (filename, itemCsvFormat, rowData)
	local f = io.open(filename, "a+b")
	outputCsvRowFormat(f, itemCsvFormat, rowData)
	f:close()
end


function outputCsvRowFormat (file, itemCsvFormat, rowData)

	for k, v in ipairs(itemCsvFormat) do
		if (k > 1) then file:write(FIELD_SEP) end
		
		local value = nil
		
		if (type(v) == "string") then
			value = rowData[v]
		elseif (type(v) == "table") then
			for k1, v1 in pairs(v) do
				value = rowData[v1]
				if (value ~= nil) then break end
			end
		end
				
		if (value ~= nil and value ~= "") then
			if (type(value) == "string") then file:write(STRING_QUOTE_CHAR) end
			file:write(value)
			if (type(value) == "string") then file:write(STRING_QUOTE_CHAR) end
		end
	end
	
	file:write(LINE_TERMINATOR)
end


function createCsvFile (filename, itemCsvFormat)
	local f = io.open(filename, "wb")
	writeCsvFileHeader(f, itemCsvFormat)
	f:close()
end


function writeCsvFileHeader (f, itemCsvFormat)

	for k, v in ipairs(itemCsvFormat) do
		if (k > 1) then f:write(FIELD_SEP) end
		
		local title = nil
		
		if (type(v) == "string") then
			title = v
		elseif (type(v) == "table") then
			title = v[1]
		end
				
		if (title == nil) then title = tostring(k) end
		f:write(title)
	end
	
	f:write(LINE_TERMINATOR)
end


function setItemMap (itemId, itemName, value, trait, quality, itemType, equipType, craftType, icon)
	local parseId = tonumber(itemId)
	
	if (parseId <= 0) then return end
	
	if (ItemIdMap[parseId] == nil) then
		ItemIdMap[parseId] = {
				["name"] = "",
				["trait"] = "",
				["value"] = "",
				["quality"] = "",
				["type"] = "",
				["equiptype"] = "",
				["crafttype"] = "",
				["icon"] = "",
			}
	end

	ItemIdMap[parseId].id = itemId
	
	if (itemName ~= nil and itemName ~= "") then ItemIdMap[parseId].name = itemName end
	if (value ~= nil and value ~= "") then ItemIdMap[parseId].value = value end
	if (trait ~= nil and trait ~= "") then ItemIdMap[parseId].trait = trait end
	if (quality ~= nil and quality ~= "") then ItemIdMap[parseId].quality = quality end
	if (itemType ~= nil and itemType ~= "") then ItemIdMap[parseId].type = itemType end
	if (equipType ~= nil and equipType ~= "") then ItemIdMap[parseId].equiptype = equipType end
	if (craftType ~= nil and craftType ~= "") then ItemIdMap[parseId].crafttype = craftType end
	if (icon ~= nil and icon ~= "") then ItemIdMap[parseId].icon = icon end
end


function dumpItemMap ()
	local f = io.open(OUTPUT_ITEMDB_FILENAME, "wb")

	writeCsvFileHeader(f, ITEMDB_CSV_FORMAT)
	--f:write("ID,Name,Value,Trait,Quality,ItemType,EquipType,CraftType,Icon\n")
	
	for id, item in pairs(ItemIdMap) do
		--print (id)
		--f:write(tostring(id)..",\""..tostring(item.name).."\","..tostring(item.value)..","..tostring(item.trait)..","..tostring(item.quality)..","..tostring(item.itemType)..","..tostring(item.equipType)..","..tostring(item.craftType)..",\""..tostring(item.icon).."\"")
		--f:write("\n")
		
		outputCsvRowFormat(f, ITEMDB_CSV_FORMAT, item)
	end
	
	f:close()
end


function parseLocationData (data, version)
	--Position():0.51492345333099, 0.60769790410995,  a:0.13334512710571,  zone:nil,  world:Betnikh
	
	local f = io.open(OUTPUT_LOCATION_FILENAME, "a+b")
		
	for k, v in ipairs(data) do
		local rowData = { ["currentplayername"] = currentPlayerName }
		rowData.name, rowData.x, rowData.y, rowData.z, rowData.zone, rowData.world = string.match(v, 'Position%((.*)%):(.*), (.*),  a:(.*),  zone:(.*),  world:(.*)')
		
		rowData.x = tonumber(rowData.x)
		rowData.y = tonumber(rowData.y)
		rowData.z = tonumber(rowData.z)
		
		if (rowData.zone == nil) then
			rowData.zone = ""
		end
				
		if (rowData.name ~= nil) then
			outputCsvRowFormat(f, LOCATION_CSV_FORMAT, rowData)
		end		
	end

	f:close()
end


function parseItemLink (itemLink)
	if (itemLink == nil) then return nil, nil, nil, nil, nil end
	
	--local itemColor, linkType, baseItemId, itemData, itemName = string.match(itemLink, "|H(.-):(%a+):(%d+):(.*)|h%[(.*)%]|h")
	local itemColor, linkType, baseItemId, itemData, itemName = string.match(itemLink, "|H(.-):(%a+):(%d+):(.*)|h(.*)|h")
		
	if (itemName == nil) then
		itemName = itemLink
		linkType = ""
		itemColor = ""
		baseItemId = -1
		itemData = ""
	else
		baseItemId = tonumber(baseItemId)
	end
	
	local itemName1 = string.match(itemName, "%[(.*)%]")
	if (itemName1 ~= nil) then itemName = itemName1; end
	
	local itemName2 = string.match(itemName, "(.*)%^.*")
	if (itemName2 ~= nil) then itemName = itemName2; end
	
	return itemColor, linkType, baseItemId, itemData, itemName
end


function parseItemLinkIP (item, field)
	item.linkcolor, item.linktype, item.baseitemid, item.itemdata, item.name = parseItemLink(item[field])
end


function parsePosition (position)
	--0.44451248645782, 0.73686248064041, -1.9488228559494, Auridon, Auridon
	
	if (position == nil) then return nil, nil, nil, nil, nil end
	
	local x, y, z, zone, world = string.match(position, "(.*), (.*), (.*), (.*), (.*)")
	
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)
	
	return x, y, z, zone, world
end


function parsePositionIP (item, field)
	item.x, item.y, item.z, item.zone, item.world = parsePosition(item[field])
end


function parseFields (data)
	local item = { ["currentplayername"] = currentPlayerName }
		
	for name, value in string.gmatch(data, "(%a+){(.-)}") do
		local lname = name:lower()
		local number = tonumber(value)
		
		if (number ~= nil and #value < 16) then
			item[lname] = number
		else
			item[lname] = value
		end
	end

	return item
end


function parseItemData (data, version)
	--event{LootGained}  ItemName{|HFFFFFF:item:44702:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h[cast-off Maple Ice Staff^n]|h}   LootType{1}  ItemSound{17}  Qnt{1}  receivedBy{Reorx the Wizard^Mx} lootedBySelf{true}  	gameTime{332715}
	--event{SellReceipt}  itemName{|HFFFFFF:item:30588:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[stale radish]|h}   itemQuantity{1}  gameTime{8488904}
	--event{BuyReceipt}  itemName{|HFFFFFF:item:33251:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h[Molybdenum]|h}   entryType{0}  entryQuantity{1}  money{21}  itemSoundCategory{31}  gameTime{13784832}
	
	--event{slotUpdate}  bag{1}  slot{2}  itemName{onion}  itemLink{|HFFFFFF:item:27064:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|honion|h}  itemTrait{0}  itemType{10}  icon{/esoui/art/icons/crafting_onion.dds}  stack{1}  sellPrice{0}  meetsUsageRequirement{true}  locked{false}  equipType{0}  itemStyle{0}  quality{1}  usedInCraftingType{5}  extraInfo1{nil}  extraInfo2{nil}  extraInfo3{nil}
    ---event{LootGained}  event{LootGained}  itemName{|HFFFFFF:item:27064:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|honion|h}   lootType{1}  itemSound{0}  qnt{1}  receivedBy{Reorx the Wizard^Mx} lootedBySelf{true}  lastTarget{Trunk}  icon{/esoui/art/icons/crafting_onion.dds}  sellPrice{0}  equipType{0}  itemStyle{nil}  position{0.59117156267166, 0.65214705467224, 4.5382080078125, Daggerfall, Glenumbra}  gameTime{2646552}  timeStamp{4743637415485243392}
	--event{dumpInv}  bag{0}  slot{12}  itemName{Signet of the Warlock}  itemLink{|H2DC50E:item:29516:3:15:0:0:0:0:0:0:0:0:0:0:0:0:1:0:1:0:0|hSignet of the Warlock|h}  itemTrait{22}  itemType{2}  icon{/esoui/art/icons/gear_breton_ring_a.dds}  stack{1}  sellPrice{21}  meetsUsageRequirement{true}  locked{false}  equipType{12}  itemStyle{1}  quality{2}  usedInCraftingType{0}  extraInfo1{nil}  extraInfo2{nil}  extraInfo3{nil}                       

	local f = io.open(OUTPUT_ITEM_FILENAME, "a+b")
	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		if (rowData.itemlink == nil) then rowData.itemlink = rowData.itemname end
	
		parseItemLinkIP(rowData, "itemlink")
		parsePositionIP(rowData, "position")
		
		outputCsvRowFormat(f, ITEM_CSV_FORMAT, rowData)
		
		setItemMap(rowData.baseitemid, rowData.itemname, chooseValue(rowData.value, rowData.money, rowData.sellprice), chooseValue(rowData.trait, rowData.itemtrait), rowData.quality, chooseValue(rowData.entrytype, rowData.itemtype), rowData.equiptype, chooseValue(rowData.usedincraftingtype, rowData.crafttype), rowData.icon)
	end

	f:close()
end


function chooseValue(...)

	for i = 1, select('#', ...) do
		local value = select(i, ...)
		if (value ~= nil) then return value end
	end
	
	return nil
end


function parseQuestData (data, version)
	--event{QuestAdded}  journalIndex{1}   questName{Soul Shriven in Coldharbour}  objectiveName{}  gameTime{260627}
    --event{QuestCounterChanged}  journalIndex{1}   questName{Soul Shriven in Coldharbour}  conditionText{Search the Cell}  conditionType{17}  currConditionVal{0}  newConditionVal{1}  conditionMax{1}  isFailCondition{false}  stepOverrideText{}  isPushed{false}  isComplete{false}  isConditionComplete{true}  isStepHidden{false}  gameTime{268020}
	--event{QuestRemoved}  isCompleted{true}   questIndex{1}  questName{Soul Shriven in Coldharbour}  zoneIndex{336}  poiIndex{294967291}  gameTime{1122590}
	--event{ObjectiveCompleted}  zoneIndex{293}   poiIndex{2}  xpGained{490}  gameTime{4880324}
	
	local f = io.open(OUTPUT_QUEST_FILENAME, "a+b")
	local index = 1
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)

		parsePositionIP(rowData, "position")
		
		rowData.index = index
		outputCsvRowFormat(f, QUEST_CSV_FORMAT, rowData)
		
		index = index + 1
	end
	
	f:close()
end


function parseGlobalData (data, version)
	--event{global}  Global: _G.tonumber()
	--event{global}  Private: _G.PerformInterrupt()
	--event{global}  Global: _G.FRAME_TARGET_CENTERED_FRAGMENT.table: A6EA3680
	local f = io.open(OUTPUT_GLOBAL_FILENAME, "a+b")
	    	
	for k, v in ipairs(data) do
		local globalType, globalName = string.match(v, "event{global}  (%a+): _G.(.*)%(%)")
		
		if (globalType == nil) then
			globalType, globalName = string.match(v, "event{global}  (%a+): _G.(.*).table:.*")
			globalType = "table"
		end
		
		if (globalType == "Global") then globalType = "Function" end
		
		local rowData = { }
		rowData.globaltype = globalType
		rowData.globalname = globalName		
		
		outputCsvRowFormat(f, GLOBAL_CSV_FORMAT, rowData)
		--f:write("\""..tostring(globalType).."\",\""..tostring(globalName).."\"\n")
	end
	
	f:close()
end


function parseRecipeData (data, version)
	--event{recipeList}  name{Grilled}  numRecipes{57}
	--event{recipe}  name{roast goat}  numIngredients{2}  provLevelReq{1}  qualityReq{1}  specialIngrType{1}
	--event{recipeResult}  name{roast goat}  icon{/esoui/art/icons/crafting_dom_meat_001.dds}  stack{2}  sellPrice{2}  quality{2}  itemLink{|H2DC50E:item:33813:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hroast goat|h}
	--event{ingredient}  name{goat meat}  icon{/esoui/art/icons/crafting_outfitter_potion_sp_names_002.dds}  reqQnt{1}  sellPrice{0}  quality{1}  itemLink{|HFFFFFF:item:28603:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hgoat meat|h}
	
	local f = io.open(OUTPUT_RECIPE_FILENAME, "a+b")
	
	local recipeList = ""
	local recipeName = ""
	local recipeLevel = ""
	local recipeQuality = ""
	local specialIngr = ""
	local recipeCount = 0
	local output = false
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)

		rowData.recipecount = recipeCount
		rowData.recipelist = recipeList
		rowData.recipename = recipeName
		rowData.recipelevel = recipeLevel
		rowData.recipequality = recipeQuality
		rowData.specialingr = specialIngr
		
		if (rowData.event == "recipeList") then
			recipeList = rowData.name
			output = false
		elseif (rowData.event == "recipe") then
			recipeName = rowData.name
			recipeLevel = rowData.provlevelreq
			recipeQuality = rowData.qualityreq
			specialIngr = rowData.specialingrtype
			recipeCount = recipeCount + 1
			rowData.itemtype = "Recipe"
			output = false
		elseif (rowData.event == "ingredient") then
			rowData.itemtype = "Ingredient"
			output = true
		elseif (rowData.event == "recipeResult") then
			rowData.itemtype = "Result"
			output = true
		end

		if (output) then
			outputCsvRowFormat(f, RECIPE_CSV_FORMAT, rowData)
		end
			
		--#,list,name,level,quality,special,type,itemName,itemLink,qnt,sellPrice,quality,icon
--f:write(tostring(recipeCount)..",\""..tostring(recipeList).."\",\""..tostring(recipeName).."\","..tostring(recipeLevel)..","..tostring(recipeQuality)..","..tostring(specialIngr)..",\""..tostring(itemType).."\",\""..tostring(itemName).."\",\""..tostring(itemLink).."\","..tostring(qnt)..","..tostring(sellPrice)..","..tostring(quality)..",\""..tostring(icon).."\","..tostring(currentPlayerName).."\n")
	end
	
	f:close()
end


function parseAchievementData (data, version)
	--event{category}  category{General}  numSubCategories{0}  numCateAchievements{12}  earnedCatePoints{25}  totalCatePoints{235}  hidesCatePoints{false}  normalIcon{/esoui/art/icons/achievements_indexicon_general_up.dds} 
	--event{subcategory}  subcategory{Public Dungeons}  numsubCateAchievements{32}  earnedSubCatePoints{0}  totalSubCatePoints{1240}  hidesSubCatePoints{false}	pressedIcon{/esoui/art/icons/achievements_indexicon_general_down.dds}  mouseoverIcon{/esoui/art/icons/achievements_indexicon_general_over.dds}
	--event{achievement}  achievementId{18}  description{Loot an artifact item.}  points{5}  icon{/esoui/art/icons/procs_006.dds}  numRewards{1}  numCriteria{1}
	--event{reward}  type{points}  points{5}  name{}  icon{)  quality{0}  itemLink{}
	--event{criteria}  description{Loot any artifact quality item}  numCompleted{1}  numRequired{1}

	local f = io.open(OUTPUT_ACHIEVEMENT_FILENAME, "a+b")
	local achCategory = ""
	local achSubCategory = ""
	local achCount = 0
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		rowData.event = rowData.event:lower()
		
		if (rowData.event == "category") then
			rowData.type = "Category"
			achCategory = rowData.category
			rowData.icon = rowData.normalicon
		elseif (rowData.event == "subcategory") then
			rowData.type = "Subcategory"
			achSubCategory = rowData.subcategory
			rowData.icon = rowData.pressedIcon
		elseif (rowData.event == "achievement") then
			rowData.type = "Achievement"
			achCount = achCount + 1
		elseif (rowData.event == "reward") then
			rowData.type = "Reward"
		elseif (rowData.event == "criteria") then
			rowData.type = "Criteria"
			
			rowData.name = rowData.description
			local numRequired = rowData.numrequired
			if (numRequired == nil) then numRequired = "" end
			rowData.name = rowData.name .. " (x" .. tostring(numRequired) ..")"
		end
				
		rowData.index = achCount
		rowData.category = achCategory
		rowData.subcategory = achSubCategory
		
		outputCsvRowFormat(f, ACHIEVEMENT_CSV_FORMAT, rowData)
	
		-- #,cate,subcate,type,name,points,icon,itemlink	
		--f:write(tostring(achCount)..",\""..tostring(achCategory).."\",\""..tostring(achSubCategory).."\",\""..tostring(achType).."\",\""..tostring(name).."\","..tostring(points)..",\""..tostring(icon).."\",\""..tostring(itemLink).."\"\n")
	end
	
	f:close()
end

function escapeBookTitle(bookTitle)
	bookTitle = bookTitle:gsub("\"", "'")
	bookTitle = bookTitle:gsub("\226", "-")
	bookTitle = bookTitle:gsub("\128", "")
	bookTitle = bookTitle:gsub("\148", "")
	return bookTitle
end


function parseLorebookData (data, version)
	--event{LoreBookLearned}  bookTitle{On Activation}  categoryIndex{2}   collectionIndex{14}  bookIndex{10}  guildIndex{0}  icon{/esoui/art/icons/quest_plans_001.dds}  position{0.44451248645782, 0.73686248064041, -1.9488228559494, Auridon, Auridon}  gameTime{10710388}  timeStamp{4743637449312305152}
	local f = io.open(OUTPUT_LOREBOOK_FILENAME, "a+b")
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		rowData.booktitle = escapeBookTitle(rowData.booktitle)
		
		outputCsvRowFormat(f, LOREBOOK_CSV_FORMAT, rowData)
		logCombinedLocation("lorebook", rowData.booktitle, rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	end
	
	f:close()
end


function parseBookData (data, version)
	--event{ShowBook}  bookTitle{Wulfmare's Guide to Better Thieving}  body{...}  medium{0}  position{0.59121084213257, 0.63727581501007, 0.35757386684418, Daggerfall, Glenumbra}  gameTime{2652910}  timeStamp{4743637415514603520}
	local f = io.open(OUTPUT_BOOK_FILENAME, "a+b")
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
								
		rowData.booktitle = escapeBookTitle(rowData.booktitle)
		rowData.booklength = string.len(rowData.body)
		
		outputCsvRowFormat(f, BOOK_CSV_FORMAT, rowData)
		logCombinedLocation("book", rowData.booktitle, rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	
		outputBookText(rowData.booktitle, rowData.body)
	end
	
	f:close()
end


function outputBookText (bookTitle, bookText)
	bookTitle = bookTitle:gsub(":", ";")
	local outFilename = OUTPUT_BOOK_PATH .. bookTitle .. ".txt"
	outFilename = outFilename:gsub("%?", "")
	outFilename = outFilename:gsub("'", "")
	
	local status, ftext = pcall(io.open, outFilename, "wb")
	
	if (status and ftext ~= nil) then
		ftext:write(bookText)
		ftext:close()
	else
		print("Error: Failed to open file ".. outFilename .. " for writing!") 
	end
	
end


function parseSkyshardData (data, version)
	--event{Skyshard}    position{0.38867929577827, 0.24923412501812, 4.7972617149353, Haven, Grahtwood}  gameTime{22777431}  timeStamp{4743637499924971520}
	local f = io.open(OUTPUT_SKYSHARD_FILENAME, "a+b")
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		
		outputCsvRowFormat(f, SKYSHARD_CSV_FORMAT, rowData)
		logCombinedLocation("skyshard", "skyshard", rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	end
	
	f:close()
end


function parseChestData (data, version)
	--event{Chest}    position{0.48204457759857, 0.44108471274376, 2.141859292984, Haven, Grahtwood}  gameTime{23931716}  timeStamp{4743637504765198336}
	local f = io.open(OUTPUT_CHEST_FILENAME, "a+b")
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		
		outputCsvRowFormat(f, CHEST_CSV_FORMAT, rowData)
		logCombinedLocation("chest", "chest", rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	end
	
	f:close()
end


function parseFishData (data, version)
	--event{FishingHole}    position{0.67333918809891, 0.64926213026047, 3.1344387531281, Deshaan, Deshaan}  gameTime{22921282}  timeStamp{4743637956395270144}
	local f = io.open(OUTPUT_FISH_FILENAME, "a+b")
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		
		outputCsvRowFormat(f, FISH_CSV_FORMAT, rowData)
		logCombinedLocation("fish", "fishing hole", rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	end
	
	f:close()
end
   
   
function parseNPCData (data, version)
	--event{onTargetChange}  name{Angier Stower}  level{5}  gender{1}  class{}  race{}  difficulty{0}  maxHeath{227}  maxMagic{0}  maxStamina{0}  position{0.58369451761246, 0.65154242515564, 1.4812371730804, Daggerfall, Glenumbra}  gameTime{2643531}  timeStamp{4743637415472660480}
	local f = io.open(OUTPUT_NPC_FILENAME, "a+b")
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		
		outputCsvRowFormat(f, NPC_CSV_FORMAT, rowData)
		logCombinedLocation("npc", rowData.name, rowData.x, rowData.y, rowData.zone, rowData.timestamp, currentPlayerName)
	end
	
	f:close()
end


function parseDialogData (data, version)
	--event{ChatterBegin}  numOptions{3}  greeting{...}  backToToc{}  farewell{}  npcName{Angier Stower}  npcLevel{5}  option{Bank}  optionType{1200}  optionalArgument{0}  isImportant{false}  chosenBefore{false}  option{Guild Bank}  optionType{3300}  optionalArgument{0}  isImportant{false}  chosenBefore{false}  option{Guild Store}  optionType{3400}  optionalArgument{0}  isImportant{false}  chosenBefore{false}  position{0.58686345815659, 0.65107929706573, 4.9711017608643, Daggerfall, Glenumbra}  gameTime{2665213}  timeStamp{4743637415564935168}
	--event{ConversationUpdate}  conversationBodyText{...}  conversationOptionCount{1}  npcName{Gjalder}  npcLevel{1}  option{...}  optionType{101}  optionalArgument{0}  isImportant{false}  chosenBefore{false}  position{0.2060848325491, 0.55047249794006, 2.7681832313538, Foundry of Woe, The Foundry of Woe}  gameTime{4561679}  timeStamp{4743637423521529856}
		--msg = msg .. "  option{".. tostring(optionString).. "}  optionType{".. tostring(optionType) .."}  optionalArgument{".. tostring(optionalArgument) .."}  isImportant{".. tostring(isImportant) .."}  chosenBefore{".. tostring(chosenBefore) .."}"
		--msg = msg .. "  option{".. tostring(optionString).. "}  optionType{".. tostring(optionType) .."}  optionalArgument{".. tostring(optionalArgument) .."}  isImportant{".. tostring(isImportant) .."}  chosenBefore{".. tostring(chosenBefore) .."}"
	local f = io.open(OUTPUT_DIALOG_FILENAME, "a+b")
	local dialogIndex = 0
		    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
		
		parsePositionIP(rowData, "position")
		
		local text = rowData.greeting
		if (text == nil) then text = rowData.conversationbodytext end
		if (text == nil) then text = "" end
		text = string.gsub(text, "\"", "'")
		rowData.text = text
	
		dialogIndex = dialogIndex + 1
		rowData.index = dialogIndex
		
		outputCsvRowFormat(f, DIALOG_CSV_FORMAT, rowData)
		
		for name, value in string.gmatch(v, "(%a+){(.-)}") do
			lname = name:lower()
			
			if (lname == "option") then
				rowData.option = string.gsub(value, "\"", "'")				
				rowData.opttype = ""
				rowData.optarg = ""
				rowData.isimportant = ""
			elseif (lname == "optionType") then
				rowData.opttype = value
			elseif (lname == "optionalargument") then
				rowData.optarg = value
			elseif (lname == "isimportant") then
				rowData.isimportant = value
			elseif (lname == "chosenbefore") then
				outputCsvRowFormat(f, DIALOG_CSV_FORMAT, rowData)
			end
		end
	end
	
	f:close()
end


function parseDataSection (section, data, version)
	print("\tParsing ".. section ..", found ".. #data .." records...")
	
	if (section == "locations") then
		parseLocationData(data, version)
	elseif (section == "items") then
		parseItemData(data, version)
	elseif (section == "quests") then
		parseQuestData(data, version)
	elseif (section == "globals") then
		parseGlobalData(data, version)
	elseif (section == "recipes") then
		parseRecipeData(data, version)
	elseif (section == "achievements") then
		parseAchievementData(data, version)
	elseif (section == "lorebooks") then
		parseLorebookData(data, version)
	elseif (section == "books") then
		parseBookData(data, version)
	elseif (section == "skyshards") then
		parseSkyshardData(data, version)
	elseif (section == "npcs") then
		parseNPCData(data, version)
	elseif (section == "chests") then
		parseChestData(data, version)
	elseif (section == "fish") then
		parseFishData(data, version)
	elseif (section == "dialog") then
		parseDialogData(data, version)
	elseif (section == "test" or section == "debug" or section == "settings") then
		print("\tSkipping section "..section.."...")
	else
		print("\tError: Don't know how to parse "..section.."!")
	end

end


function parseEsoHeadNpcData (data, version)
	local f = io.open(OUTPUT_NPC_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for npcName, npcData in pairs(zoneData) do
			rowData.name = npcName
			
			for k, posData in ipairs(npcData) do
				rowData.x = posData[1]
				rowData.y = posData[2]
				rowData.level = posData[3]
				
				outputCsvRowFormat(f, NPC_CSV_FORMAT, rowData)
				logCombinedLocation("npc", rowData.name, rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
			end
		end
	end
	
	f:close()
end


function parseEsoHeadBookData (data, version)
	local f = io.open(OUTPUT_BOOK_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for bookName, bookData in pairs(zoneData) do
			rowData.booktitle = escapeBookTitle(bookName)
			
			for k, posData in ipairs(bookData) do
				rowData.x = posData[1]
				rowData.y = posData[2]
				
				outputCsvRowFormat(f, BOOK_CSV_FORMAT, rowData)
				logCombinedLocation("book", rowData.booktitle, rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
			end
		end
	end
	
	f:close()
end


function parseEsoHeadFishData (data, version)
	local f = io.open(OUTPUT_FISH_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for k, posData in ipairs(zoneData) do
			rowData.x = posData[1]
			rowData.y = posData[2]
						
			outputCsvRowFormat(f, FISH_CSV_FORMAT, rowData)
			logCombinedLocation("fish", "fishing hole", rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
		end
	end
	
	f:close()
end


function parseEsoHeadProvisioningData (data, version)
	local f = io.open(OUTPUT_MISCLOCATION_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"
	rowData.type = "Provisioning"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for material, itemTypeData in pairs(zoneData) do
			rowData.material = material
			
			for itemId, itemData in pairs(itemTypeData) do
				rowData.itemid = itemid
				
				for k, posData in ipairs(itemData) do
					rowData.x = posData[1]
					rowData.y = posData[2]
					rowData.qnt = posData[3]
					rowData.source = posData[4]
					
					if (ItemIdMap[itemId] ~= nil) then 
						rowData.itemname = ItemIdMap[itemId].itemname
					end
					
					outputCsvRowFormat(f, MISCLOCATION_CSV_FORMAT, rowData)
					logCombinedLocation("provision", rowData.source, rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
				end
			end
		end
	end
	
	f:close()
end


function parseEsoHeadHarvestData (data, version)
	local f = io.open(OUTPUT_MISCLOCATION_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"
	rowData.type = "Harvest"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for material, itemTypeData in pairs(zoneData) do
			rowData.material = material
		
			for k, posData in ipairs(itemTypeData) do
				rowData.x = posData[1]
				rowData.y = posData[2]
				rowData.qnt = posData[3]
				rowData.source = posData[4]
				rowData.itemid = posData[5]
				rowData.itemname = ItemIdMap[itemId]
				
				outputCsvRowFormat(f, MISCLOCATION_CSV_FORMAT, rowData)
				logCombinedLocation("harvest", rowData.source, rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
			end
		end
	end
	
	f:close()
end


function parseEsoHeadSkyshardData (data, version)
	local f = io.open(OUTPUT_SKYSHARD_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for k, posData in ipairs(zoneData) do
			rowData.x = posData[1]
			rowData.y = posData[2]
		
			outputCsvRowFormat(f, SKYSHARD_CSV_FORMAT, rowData)	
			logCombinedLocation("skyshard", "skyshard", rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
		end
	end
	
	f:close()
end


function parseEsoHeadChestData (data, version)
	local f = io.open(OUTPUT_CHEST_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for k, posData in ipairs(zoneData) do
			rowData.x = posData[1]
			rowData.y = posData[2]
		
			outputCsvRowFormat(f, CHEST_CSV_FORMAT, rowData)	
			logCombinedLocation("chest", "chest", rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
		end
	end
	
	f:close()
end


function parseEsoHeadQuestData (data, version)
	local f = io.open(OUTPUT_MISCLOCATION_FILENAME, "a+b")
	local rowData = { }
	
	rowData.currentplayername = "EsoHead"
	rowData.type = "Quest"

	for zone, zoneData in pairs(data) do
		rowData.zone = zone
		
		for questName, questData in pairs(zoneData) do
			rowData.source = questName
			
			for k, posData in ipairs(questData) do
				rowData.x = posData[1]
				rowData.y = posData[2]
				rowData.level = posData[3]
				rowData.npcname = posData[4]
				rowData.level = posData[5]
				
				outputCsvRowFormat(f, MISCLOCATION_CSV_FORMAT, rowData)	
				logCombinedLocation("quest", rowData.source, rowData.x, rowData.y, rowData.zone, "", rowData.currentplayername)
			end
		end
	end
	
	f:close()
end


function parseEsoHeadDataSection(section, data, version)
	print("\tParsing ".. section ..", found ".. tostring(#data) .." records...")
		
	if (section == "npc") then
		parseEsoHeadNpcData(data, version)
	elseif (section == "provisioning") then
		parseEsoHeadProvisioningData(data, version)
	elseif (section == "harvest") then
		parseEsoHeadHarvestData(data, version)
	elseif (section == "skyshard") then
		parseEsoHeadSkyshardData(data, version)
	elseif (section == "book") then
		parseEsoHeadBookData(data, version)
	elseif (section == "fish") then
		parseEsoHeadFishData(data, version)
	elseif (section == "chest") then
		parseEsoHeadChestData(data, version)
	elseif (section == "quest") then
		parseEsoHeadQuestData(data, version)
	elseif (section == "vendor") then
		print("\tSkipping section "..section.."...")
	elseif (section == "test" or section == "debug") then
		print("\tSkipping section "..section.."...")
	else
		print("\tError: Don't know how to parse "..section.."!")
	end

end


function parseAllData (allData)

	for k, v in pairs(allData) do
		local version = v["version"]
		local data = v["data"]
		
		if (data == nil) then
			print("\tError: Missing [\"data\"] section in "..k.." data!")
		else
			parseDataSection(k, data, version)
		end
	end
	
end


function parseEsoHeadAllData (allData)

	for k, v in pairs(allData) do
		local version = v["version"]
		local data = v["data"]
		
		if (k == "internal") then
			print("\tSkipping "..k.." data...")
		elseif (data == nil) then
			print("\tError: Missing [\"data\"] section in "..k.." data!")
		else
			parseEsoHeadDataSection(k, data, version)
		end
	end
	
end


function parseSavedVarData (savedVar)
	local foundCount = 0

	if (savedVar == nil) then
		return false
	end
	
	for k1, v1 in pairs(savedVar) do
		local parentGroup = k1
		
		for k2, v2 in pairs(v1) do
			local playerName = k2
			currentPlayerName = string.match(playerName, "@(.*)")
			if (currentPlayerName == nil) then currentPlayerName = playerName end
			
			for k3, v3 in pairs(v2) do
				local section = k3
				print("Found saved variable data in ".. parentGroup .."::"..playerName.."::"..section)
				foundCount = foundCount + 1
				parseAllData(v3)
			end
		end
	end

	if (foundCount == 0) then
		print("Error: Could not find saved variable data!")
		return false
	end
	
	return true
end


function parseEsoHeadData (savedVar)
	local foundCount = 0

	if (savedVar == nil) then
		return false
	end
	
	print("Parsing ESOHead log...")
	
	for k1, v1 in pairs(savedVar) do
		local parentGroup = k1
		
		for k2, v2 in pairs(v1) do
			local playerName = k2
			currentPlayerName = string.match(playerName, "@(.*)")
			if (currentPlayerName == nil) then currentPlayerName = playerName end
			
			for k3, v3 in pairs(v2) do
				local section = k3
				print("Found saved variable data in ".. parentGroup .."::"..playerName.."::"..section)
				foundCount = foundCount + 1
				parseEsoHeadAllData(v3)
			end
		end
	end
	
	if (foundCount == 0) then
		print("Error: Could not find saved variable data!")
		return false
	end
	
	return true
end


function initializeOutputFiles ()
	
	createCsvFile(OUTPUT_LOCATION_FILENAME, LOCATION_CSV_FORMAT)
	createCsvFile(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT)
	createCsvFile(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT)
	createCsvFile(OUTPUT_RECIPE_FILENAME, RECIPE_CSV_FORMAT)
	createCsvFile(OUTPUT_GLOBAL_FILENAME, GLOBAL_CSV_FORMAT)
	createCsvFile(OUTPUT_ACHIEVEMENT_FILENAME, ACHIEVEMENT_CSV_FORMAT)
	createCsvFile(OUTPUT_LOREBOOK_FILENAME, LOREBOOK_CSV_FORMAT)
	createCsvFile(OUTPUT_BOOK_FILENAME, BOOK_CSV_FORMAT)
	createCsvFile(OUTPUT_SKYSHARD_FILENAME, SKYSHARD_CSV_FORMAT)
	createCsvFile(OUTPUT_CHEST_FILENAME, CHEST_CSV_FORMAT)
	createCsvFile(OUTPUT_FISH_FILENAME, FISH_CSV_FORMAT)
	createCsvFile(OUTPUT_NPC_FILENAME, NPC_CSV_FORMAT)
	createCsvFile(OUTPUT_DIALOG_FILENAME, DIALOG_CSV_FORMAT)
	createCsvFile(OUTPUT_MISCLOCATION_FILENAME, MISCLOCATION_CSV_FORMAT)
	createCsvFile(OUTPUT_COMBINEDLOCS_FILENAME, COMBINEDLOC_CSV_FORMAT)

end


function logCombinedLocation (category, name, x, y, zone, timeStamp, user)
	local f = io.open(OUTPUT_COMBINEDLOCS_FILENAME, "a+b")
	local rowData = { }
	
	rowData.category = category
	rowData.name = name
	rowData.x = x
	rowData.y = y
	rowData.zone = zone
	rowData.timestamp = timeStamp
	rowData.user = user
	
	outputCsvRowFormat(f, COMBINEDLOC_CSV_FORMAT, rowData)	
	f:close()
end


function main ()
	initializeOutputFiles()

	for k, v in ipairs(INPUT_FILENAMES) do
		uespSavedVars = nil
		uespLogSavedVars = nil
		Esohead_SavedVariables = nil
		
		dofile(v)
		
		if (uespSavedVars ~= nil) then parseSavedVarData(uespSavedVars) end
		if (uespLogSavedVars ~= nil) then parseSavedVarData(uespLogSavedVars) end
		if (Esohead_SavedVariables ~= nil) then parseEsoHeadData(Esohead_SavedVariables) end
	end

	dumpItemMap()
end


main()
