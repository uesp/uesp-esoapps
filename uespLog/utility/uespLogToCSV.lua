
	-- Add all files to combine and convert here
INPUT_FILENAMES = {
	"d:\\esoexport\\uespLog\\addon\\test\\testOutput.lua",
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
OUTPUT_CRAFT_FILENAME = OUTPUT_PATH .. "crafting.csv"
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
	"timestamp",
	{ "user", "currentplayername" },
}	

DIALOG_CSV_FORMAT = {
	"index",
	{ "text", "bodytext" },
	"npcname",
	"npclevel",
	"option",
	{ "type", "opttype" },
	"optarg",
	"isimportant",
	"x",
	"y",
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

CRAFT_CSV_FORMAT = {
	{ "type", "craftskill", "crafttype" },
	"inspiration",
	"itemname",
	"qnt",
	"quality",
	{ "itemtype", "type" },
	"equiptype",
	"x",
	"y",
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

NPC_CSV_FORMAT = {
	"name",
	"level",
	"gender",
	"difficulty",
	{ "maxhealth", "maxhp" },
	{ "maxmagic", "maxmg" },
	{ "maxstamina", "maxst" },
	"x",
	"y",
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

SKYSHARD_CSV_FORMAT = {
	"x",
	"y", 
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}		

CHEST_CSV_FORMAT = {
	"name",
	"x",
	"y", 
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}		

FISH_CSV_FORMAT = {
	"x",
	"y", 
	"z",
	"zone",
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
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}	

LOREBOOK_CSV_FORMAT = {
	"booktitle",
	"category",
	"collection",
	"index",
	"guild",
	"icon",
	"x",
	"y",
	"z",
	"zone",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

LOCATION_CSV_FORMAT = {
	{ "label", "name" },
	"x",
	"y",
	"z",
	"zone",
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
	{ "type", "itemtype", "entrytype", "loottype" },
	"equiptype",
	{ "crafttype", "craftingtype", "usedincraftingtype" },
	"icon",
	{ "source", "lasttarget" },
	"qnt",
	"locked",
	"x",
	"y",
	"z",
	"zone",
	"gametime",
	"timestamp",
	"event",
	{ "user", "currentplayername" },
}

QUEST_CSV_FORMAT = {
	"index",
	{ "name", "quest", "questname" },
	"objective",
	{ "condition", "text", "conditiontext" },
	{ "condtype", "conditiontype" },
	{ "condval", "conditionvalue", "newconditionval" },
	{ "condmaxval", "conditionmax" },
	{ "complete", "iscomplete" },
	"iscondcomplete",
	"isfail",
	"ishidden",
	"ispushed",
	"xpgained",
	"gametime",
	"event",
	{ "user", "player", "currentplayername" },
}
			
RECIPE_CSV_FORMAT = {
	"index",
	"recipelist",
	"type",
	"name",
	"provlevel",
	"quality",
	"specialtype",
	"itemname",
	"baseitemid",
	"itemlink",
	"qnt",
	"value",
	"icon",
	"gametime",
	"timestamp",
	{ "user", "currentplayername" },
}

GLOBAL_CSV_FORMAT = {
	"label",
	"type",
	"name",
	"value",
}
		
ACHIEVEMENT_CSV_FORMAT = {
	"index",
	"category",
	"subcategory",
	"event",
	"id",
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
	item.linkcolor, item.linktype, item.baseitemid, item.itemdata, item.itemname = parseItemLink(item[field])
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


function parseGlobalData (data, version)
	-- value{function: 004BF9E0}  type{function}  name{_G.uespLog.OnObjectiveCompleted()}  label{Global}
	-- value{2000}  type{number}  name{_G.uespLog.MIN_TARGET_CHANGE_TIMEMS}  label{Global}  
	-- value{table: 004E6060}  type{table}  name{_G.uespLog.currentTargetData}  label{Global-max}  
	
	local f = io.open(OUTPUT_GLOBAL_FILENAME, "a+b")
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
	
		outputCsvRowFormat(f, GLOBAL_CSV_FORMAT, rowData)
	end
	
	f:close()
end


function parseAchievementData (data, version)
	-- event{Category}  numAchievements{4}  hidesPoints{0}  name{Category}  mouseoverIcon{mouseover.dds}  pressedIcon{pressed.dds}  subCategories{4}  icon{icon.dds}  totalPoints{100} 
	-- event{Subcategory}  name{SubCate Name}  numAchievements{6}  hidesPoints{0}  totalPoints{60}  
	-- event{Achievement}  numCriteria{1}  description{Description}  numRewards{1}  id{123}  points{10}  icon{icon.dds}  
	-- event{Reward}  type{points}  name{Title}  itemLink{}  icon{icon.dds}  points{10}  quality{1}  
	-- event{Criteria}  description{Description}  numRequired{5} 
	
	local f = io.open(OUTPUT_ACHIEVEMENT_FILENAME, "a+b")
	local achCategory = ""
	local achSubCategory = ""
	local achCount = 0
	    	
	for k, v in ipairs(data) do
		local rowData = parseFields(v)
				
		if (rowData.event == "Category") then
			achCategory = rowData.name
			rowData.icon = rowData.normalicon
		elseif (rowData.event == "Subcategory") then
			achSubCategory = rowData.name
			rowData.icon = rowData.pressedIcon
		elseif (rowData.event == "Achievement") then
			achCount = achCount + 1
		elseif (rowData.event == "Reward") then
			rowData.name = rowData.type .. ": " .. rowData.name
			if (rowData.type == "points") then rowData.name = rowData.name .. tostring(rowData.points) end
		elseif (rowData.event == "Criteria") then
			rowData.name = rowData.description
			local numRequired = rowData.numrequired
			if (numRequired == nil) then numRequired = "" end
			rowData.name = rowData.name .. " (x" .. tostring(numRequired) ..")"
		end
				
		rowData.index = achCount
		rowData.category = achCategory
		rowData.subcategory = achSubCategory
		
		outputCsvRowFormat(f, ACHIEVEMENT_CSV_FORMAT, rowData)
	end
	
	f:close()
end


function escapeBookTitle (bookTitle)
	bookTitle = bookTitle:gsub("\"", "'")
	bookTitle = bookTitle:gsub("\226", "-")
	bookTitle = bookTitle:gsub("\128", "")
	bookTitle = bookTitle:gsub("\148", "")
	return bookTitle
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


invDumpData = { }
invDumpData.gametime = ""
invDumpData.timestamp = ""

conversationData = { }
conversationData.index = 0

questData = { }
questData.index = 0

craftingData = { }
craftingData.inspiration = ""
craftingData.x = ""
craftingData.y = ""
craftingData.z = ""
craftingData.zone = ""
craftingData.gametime = ""
craftingData.timestamp = ""
craftingData.craftskill = ""

recipeData = { }
recipeData.index = 0
recipeData.list = ""
recipeData.numrecipes = 0
recipeData.gametime = ""
recipeData.timestamp = ""


function OnLogEventInvDumpStart (rowData, version)
	invDumpData = { }
	invDumpData.gametime = rowData.gametime
	invDumpData.timestamp = rowData.timestamp
end


function OnLogEventInvDumpEnd (rowData, version)
	invDumpData = { }
end


function OnLogEventInvDump (rowData, version)
	--event{InvDump}  type{1}  qnt{2}  slot{1}  craftType{1}  trait{4}  itemStyle{2}  icon{icon.dds}  equipType{1}  value{11}  locked{false}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h}  quality{3}
	
	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT, rowData)	
end


function OnLogEventChatterBegin (rowData, version)
	-- event{ChatterBegin}  optionCount{1}  bodyText{Chatter Greeting...}  npcName{}  x{0.183874}  zone{MapName}  npcLevel{10}  y{0.9138137}  gameTime{1395521483000}  timeStamp{1234567890000}  
	
	conversationData.index = conversationData.index + 1
	rowData.index = conversationData.index
	
	appendCsvRowFormat(OUTPUT_DIALOG_FILENAME, DIALOG_CSV_FORMAT, rowData)	
end


function OnLogEventChatterBeginOption (rowData, version)
	-- event{ChatterBegin::Option}  chosenBefore{false}  type{2}  optArg{3}  option{1}  isImportant{false}  
	
	rowData.index = conversationData.index
	
	appendCsvRowFormat(OUTPUT_DIALOG_FILENAME, DIALOG_CSV_FORMAT, rowData)	
end


function OnLogEventConversationUpdated (rowData, version)
	-- event{ConversationUpdated}  optionCount{1}  bodyText{Body Test}  npcName{}  x{0.183874}  zone{MapName}  npcLevel{10}  y{0.9138137}  gameTime{1395521483000}  timeStamp{1234567890000}  
	
	rowData.index = conversationData.index
	
	appendCsvRowFormat(OUTPUT_DIALOG_FILENAME, DIALOG_CSV_FORMAT, rowData)	
end


function OnLogEventConversationUpdatedOption (rowData, version)
	-- event{ConversationUpdated::Option}  chosenBefore{false}  type{2}  optArg{3}  option{1}  isImportant{false}  
	
	rowData.index = conversationData.index
	
	appendCsvRowFormat(OUTPUT_DIALOG_FILENAME, DIALOG_CSV_FORMAT, rowData)	
end


function OnLogEventShowBook (rowData, version)
	-- event{ShowBook}  medium{1}  body{book Body}  bookTitle{Title}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395522429000}  timeStamp{1234567890000}  
	
	rowData.booktitle = escapeBookTitle(rowData.booktitle)
	rowData.booklength = #rowData.body
					
	appendCsvRowFormat(OUTPUT_BOOK_FILENAME, BOOK_CSV_FORMAT, rowData)	
	outputBookText(rowData.booktitle, rowData.body)
end


function OnLogEventLoreBook (rowData, version)
	-- event{LoreBook}  known{true}  bookTitle{Title}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395522429000}  timeStamp{1234567890000}  
	-- event{LoreBook}  known{false}  guild{4}  index{3}  category{1}  collection{2}  icon{icon.dds}  bookTitle{Title}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395522429000} timeStamp{1234567890000}  
	
	rowData.booktitle = escapeBookTitle(rowData.booktitle)
	
	appendCsvRowFormat(OUTPUT_LOREBOOK_FILENAME, LOREBOOK_CSV_FORMAT, rowData)	
end


function OnLogEventBuy (rowData, version)
	-- event{Buy}  qnt{2}  sound{23}  value{10}  entryType{1}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395522429000}  	timeStamp{1234567890000}  

	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT, rowData)	
end


function OnLogEventSell (rowData, version)
	-- event{Sell}  value{11}  qnt{1}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395522429000}  timeStamp{1234567890000}  
	
	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT, rowData)	
end


function OnLogEventLootGained (rowData, version)
	-- event{LootGained}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h}  lootType{2}  y{}  x{}  lastTarget{}  zone{}  gameTime{1395522429000}  timeStamp{1234567890000}  
	
	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT, rowData)	
end


function OnLogEventSlotUpdate (rowData, version)
	-- event{SlotUpdate}  type{1}  qnt{2}  slot{2}  bag{1}  craftType{1}  trait{4}  itemStyle{2}  icon{icon.dds}  equipType{1}  value{11}  locked{false}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h}  quality{3}  

	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_ITEM_FILENAME, ITEM_CSV_FORMAT, rowData)	
end


function OnLogEventQuestAdded (rowData, version)
	-- event{QuestAdded}  objective{Objective}  quest{Quest Name}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	questData.index = questData.index + 1
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestObjComplete (rowData, version)
	-- event{QuestObjComplete}  zoneIndex{123}  xpGained{500}  poiIndex{456}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestChanged (rowData, version)
	-- event{QuestChanged}  isCondComplete{false}  condMaxVal{4}  isHidden{false}  isPushed{false}  isFail{false}  isComplete{false}  condType{1}  condVal{2}  quest{Quest Name}  condition{Condition}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestCompleteExperience (rowData, version)
	-- event{QuestCompleteExperience}  xpGained{500}  quest{Quest Name}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  	
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestOptionalStep (rowData, version)
	-- event{QuestOptionalStep}  text{Optional Step}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestAdvanced (rowData, version)
	-- event{QuestAdvanced}  isPushed{false}  isComplete{false}  quest{Quest Name}  mainStepChanged{false}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventQuestRemoved (rowData, version)
	-- event{QuestRemoved}  completed{true}  zoneIndex{123}  poiIndex{456}  quest{Quest Name}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395523909000}  timeStamp{1234567890000}  
	
	rowData.index = questData.index
	
	appendCsvRowFormat(OUTPUT_QUEST_FILENAME, QUEST_CSV_FORMAT, rowData)	
end


function OnLogEventCraftComplete (rowData, version)
	-- event{CraftComplete}  inspiration{111}  qnt{1}  craftSkill{2}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395524070000}  timeStamp{1234567890000}  
	
	craftingData.inspiration = rowData.inspiration
	craftingData.x = rowData.x
	craftingData.y = rowData.y
	craftingData.z = rowData.z
	craftingData.zone = rowData.zone
	craftingData.gametime = rowData.gametime
	craftingData.timestamp = rowData.timestamp
	craftingData.craftskill = rowData.craftskill
end


function OnLogEventCraftCompleteResult (rowData, version)
	-- event{CraftComplete::Result}  type{2}  qnt{1}  itemInstanceId{89171726364}  equipType{1}  value{11}  itemName{Item Name}  icon{icon.dds}  quality{4}  
	
	rowData.inspiration = craftingData.inspiration
	rowData.x = craftingData.x
	rowData.y = craftingData.y
	rowData.z = craftingData.z
	rowData.zone = craftingData.zone
	rowData.gametime = craftingData.gametime
	rowData.timestamp = craftingData.timestamp
	rowData.craftskill = craftingData.craftskill
		
	appendCsvRowFormat(OUTPUT_CRAFT_FILENAME, CRAFT_CSV_FORMAT, rowData)	
end


function OnLogEventTargetChange (rowData, version)
	-- event{TargetChange}  difficulty{1}  maxSt{100}  name{skyshard}  maxHp{100}  maxMg{100}  level{10}  gender{3}  y{}  x{}  lastTarget{}  zone{}  gameTime{1395524070000}  timeStamp{1234567890000}  
	appendCsvRowFormat(OUTPUT_NPC_FILENAME, NPC_CSV_FORMAT, rowData)	
end


function OnLogEventLocation (rowData, version)
	-- event{Location}  label{name}  y{0.9138137}  x{0.183874}  zone{MapName}  gameTime{1395524070000}  timeStamp{1234567890000}  
	appendCsvRowFormat(OUTPUT_LOCATION_FILENAME, LOCATION_CSV_FORMAT, rowData)	
end


function OnLogEventRecipeList (rowData, version)
	-- event{RecipeList}  name{RecipeList}  numRecipes{5}  gameTime{1395524070000}  timeStamp{1234567890000}  
	
	recipeData.list = rowData.name
	recipeData.numrecipes = rowData.numrecipes
	recipeData.gametime = rowData.gametime
	recipeData.timestamp = rowData.timestamp
end


function OnLogEventRecipe (rowData, version)
	-- event{Recipe}  specialType{0}  name{Recipe Name}  quality{1}  numIngredients{2}  provLevel{2}  numRecipes{5}  
	
	recipeData.index = recipeData.index + 1
	rowData.index = recipeData.index
	rowData.recipelist = recipeData.list
	rowData.gametime = recipeData.gametime
	rowData.timestamp = recipeData.timestamp
	rowData.type = "Recipe"
	
	appendCsvRowFormat(OUTPUT_RECIPE_FILENAME, RECIPE_CSV_FORMAT, rowData)	
end


function OnLogEventRecipeResult (rowData, version)
	-- event{RecipeResult}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest recipe item|h}  name{Item Name}  icon{icon.dds}  value{12}  qnt{1}  quality{1}  
	
	rowData.index = recipeData.index
	rowData.recipelist = recipeData.list
	rowData.gametime = recipeData.gametime
	rowData.timestamp = recipeData.timestamp
	rowData.type = "Result"
	
	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_RECIPE_FILENAME, RECIPE_CSV_FORMAT, rowData)	
end


function OnLogEventIngredient (rowData, version)
	-- event{Ingredient}  itemLink{|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest ingre|h}  name{Ingre Name}  icon{icon.dds}  value{7}  qnt{2}  quality{1}  
	
	rowData.index = recipeData.index
	rowData.recipelist = recipeData.list
	rowData.gametime = recipeData.gametime
	rowData.timestamp = recipeData.timestamp
	rowData.type = "Ingredient"
	
	parseItemLinkIP(rowData, "itemlink")
	
	appendCsvRowFormat(OUTPUT_RECIPE_FILENAME, RECIPE_CSV_FORMAT, rowData)	
end


function OnLogEventRecipeEnd (rowData, version)

end


function OnLogEventSkyshard (rowData, version)
	-- event{Skyshard}  y{}  x{}  lastTarget{}  zone{}  gameTime{1395524070000}  timeStamp{1234567890000}  
	appendCsvRowFormat(OUTPUT_SKYSHARD_FILENAME, SKYSHARD_CSV_FORMAT, rowData)	
end


function OnLogEventFishingHole (rowData, version)
	-- event{Fish}  y{}  x{}  lastTarget{}  zone{}  gameTime{1395524070000}  timeStamp{1234567890000}  
	appendCsvRowFormat(OUTPUT_FISH_FILENAME, FISH_CSV_FORMAT, rowData)	
end


function OnLogEventFoundTreasure (rowData, version)
	-- event{FoundTreasure}  name{treasurename}  y{}  x{}  lastTarget{}  zone{}  gameTime{1395524070000}  timeStamp{1234567890000}  
	appendCsvRowFormat(OUTPUT_CHEST_FILENAME, CHEST_CSV_FORMAT, rowData)	
end


LOGEVENT_FUNCTION_TABLE = {
	["invdump"] = OnLogEventInvDump,
	["invdumpend"] = OnLogEventInvDumpEnd,
	["invdumpstart"] = OnLogEventInvDumpStart,
	["chatterbegin"] = OnLogEventChatterBegin,
	["chatterbegin::option"] = OnLogEventChatterBeginOption,
	["conversationupdated"] = OnLogEventConversationUpdated,
	["conversationupdated::option"] = OnLogEventConversationUpdatedOption,
	["showbook"] = OnLogEventShowBook,
	["lorebook"] = OnLogEventLoreBook,
	["sell"] = OnLogEventSell,
	["buy"] = OnLogEventBuy,
	["lootgained"] = OnLogEventLootGained,
	["slotupdate"] = OnLogEventSlotUpdate,
	["questadded"] = OnLogEventQuestAdded,
	["questobjcomplete"] = OnLogEventQuestObjComplete,
	["questchanged"] = OnLogEventQuestChanged,
	["questcompleteexperience"] = OnLogEventQuestCompleteExperience,
	["questoptionalstep"] = OnLogEventQuestOptionalStep,
	["questadvanced"] = OnLogEventQuestAdvanced,
	["questremoved"] = OnLogEventQuestRemoved,
	["craftcomplete"] = OnLogEventCraftComplete,
	["craftcomplete::result"] = OnLogEventCraftCompleteResult,
	["targetchange"] = OnLogEventTargetChange,
	["location"] = OnLogEventLocation,
	["recipe::list"] = OnLogEventRecipeList,
	["recipe"] = OnLogEventRecipe,
	["recipe::result"] = OnLogEventRecipeResult,
	["recipe::ingredient"] = OnLogEventIngredient,
	["recipe::end"] = OnLogEventRecipeEnd,
	["skyshard"] = OnLogEventSkyshard,
	["fish"] = OnLogEventFishingHole,
	["foundtreasure"] = OnLogEventFoundTreasure,
}


function parseSectionAllData (data, version)

	for k, v in ipairs(data) do
		local rowData = parseFields(v)	
		local event = rowData.event:lower()
		local func = LOGEVENT_FUNCTION_TABLE[event]
		
		if (func == nil) then
			print("\tERROR: Unknown event '" .. tostring(rowData.event) .. "' found!")
		else
			func(rowData, version)
		end		
	end
	
end


function parseDataSection (section, data, version)
	print("\tParsing ".. section ..", found ".. #data .." records...")
	
	if (section == "all") then
		parseSectionAllData(data, version)
	elseif (section == "info") then
		-- TODO
	elseif (section == "locations") then
		parseLocationData(data, version)
	elseif (section == "globals") then
		parseGlobalData(data, version)
	elseif (section == "achievements") then
		parseAchievementData(data, version)
	elseif (section == "test" or section == "debug" or section == "settings") then
		print("\t\tSkipping section "..section.."...")
	else
		print("\t\tError: Don't know how to parse section '"..section.."'!")
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
	createCsvFile(OUTPUT_CRAFT_FILENAME, CRAFT_CSV_FORMAT)	

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
