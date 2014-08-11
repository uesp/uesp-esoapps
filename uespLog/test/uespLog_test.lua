
-- Use only for testing addon outside of the game


function Serialize (f, object, objName)
	f:write(objName .. " = ")
	SerializePriv(f, object)
end


function SerializePriv (f, object, tabString)

	if (tabString == nil) then tabString = "" end
	
    if type(object) == "number" then
        f:write(object)
	elseif type(object) == "boolean" then
		f:write(tostring(object))
	elseif type(object) == "string" then
		f:write("[[" .. object .. "]]")
	elseif type(object) == "table" then
		f:write("\n" .. tabString .. "{\n")
		local maxIndex = 0
		
				-- Output all numeric keys in order first
		for k,v in ipairs(object) do
			f:write(tabString .. uespLog.TAB_CHARACTER)
			
			if (type(k) == "string") then
				f:write("[\"", k, "\"] = ")
			else
				f:write("[", k, "] = ")
			end
			
			SerializePriv(f, v, tabString .. uespLog.TAB_CHARACTER)
			f:write(",\n")
			maxIndex = k
		end
		
				-- Output all remaining keys next
		for k,v in pairs(object) do
			if (type(k) == "number" and k <= maxIndex) then
				--skip
			else
				f:write(tabString .. uespLog.TAB_CHARACTER)
			
				if (type(k) == "string") then
					f:write("[\"", k, "\"] = ")
				else
					f:write("[", k, "] = ")
				end
			
				SerializePriv(f, v, tabString .. uespLog.TAB_CHARACTER)
				f:write(",\n")
			end
		end

		f:write(tabString .. "}")
	else
		--error("cannot serialize a " .. type(object))
	end
	  
end


function uespLog.DeepCopy (o, seen)
	seen = seen or {}
	if o == nil then return nil end
	if seen[o] then return seen[o] end

	local no
	
	if type(o) == 'table' then
		no = {}
		seen[o] = no

		for k, v in next, o, nil do
			no[uespLog.DeepCopy(k, seen)] = uespLog.DeepCopy(v, seen)
		end
		setmetatable(no, uespLog.DeepCopy(getmetatable(o), seen))
	else -- number, string, boolean, etc
		no = o
	end
	
	return no
end


math.randomseed(os.time())
uespLog.SetDebug(true)
uespLog.Initialize(nil, "uespLog")
eventCode = 1234
itemLink = "|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h"

	-- OnUpdate event
uespLog.OnUpdate()
uespLog.OnUpdate()
uespLog.OnUpdate()
uespLog.OnUpdate()
uespLog.OnUpdate()
uespLog.OnUpdate()
uespLog.OnUpdate()

	-- Dialog
uespLog.OnChatterBegin (eventCode, 1)
uespLog.OnConversationUpdated (eventCode, "Body Text...", 1)
uespLog.OnChatterEnd (eventCode)

	-- Books
uespLog.OnShowBook (eventCode, "Title", "book Body", 1, true)
uespLog.OnLoreBookAlreadyKnown (eventCode, "Title")
uespLog.OnLoreBookLearned (eventCode, 1, 2, 3, 4)
uespLog.OnSkillRankUpdate(eventCode, 1, 2, 3)

	-- Loot and items
uespLog.OnBuyReceipt (eventCode, itemLink, 1, 2, 10, 0, 0, 0, 0, 0, 0, 23)
uespLog.OnSellReceipt (eventCode, itemLink, 1, 11)
uespLog.OnLootGained (eventCode, "Reorx", itemLink, 1, 23, 2, true)
uespLog.OnInventorySlotUpdate (eventCode, 1, 2, true, 12, 1)

	-- Quests
uespLog.OnQuestAdded (eventCode, 1, "Quest Name", "Objective")
uespLog.OnQuestObjectiveCompleted (eventCode, 123, 456, 500)
uespLog.OnQuestCounterChanged (eventCode, 1, "Quest Name", "Condition", 1, 1, 2, 4, false, "", false, false, false, false)
uespLog.OnQuestCompleteExperience (eventCode, "Quest Name", 500)
uespLog.OnQuestOptionalStepAdvanced (eventCode, "Optional Step")
uespLog.OnQuestAdvanced (eventCode, 1, "Quest Name", false, false, false)
uespLog.OnQuestRemoved (eventCode, true, 1, "Quest Name", 123, 456)

	-- Crafting
uespLog.OnCraftCompleted (eventCode, 2)
uespLog.OnRecipeLearned (1, 2)

	-- Target/NPC
uespLog.OnTargetChange (eventCode)
uespLog.OnTargetChange (eventCode)
uespLog.OnTargetChange (eventCode)
uespLog.OnTargetChange (eventCode)
uespLog.OnTargetChange (eventCode)

	-- Slash Commands
SLASH_COMMANDS["/loc"]("name")
SLASH_COMMANDS["/uti"]()
SLASH_COMMANDS["/uespcount"]()
SLASH_COMMANDS["/uespdump"]("recipes")
SLASH_COMMANDS["/uespdump"]("achievements")
SLASH_COMMANDS["/uespdump"]("globals")
SLASH_COMMANDS["/uespdump"]("inventory")
SLASH_COMMANDS["/uespreset"]()
--SLASH_COMMANDS["/uespreset"]("globals")

	-- Other
uespLog.OnFoundSkyshard()
uespLog.OnFoundFish()
uespLog.OnFoundTreasure("treasurename")

	-- Run last
SLASH_COMMANDS["/uespcount"]()


	-- Output test file
outputData = { }
outputData.Default = { }
outputData.Default["@Reorx"] = { }
outputData.Default["@Reorx"]["$AccountWide"] = uespLog.savedVars	

f = io.open("test/testOutput.lua", "wb")
Serialize (f, outputData, "uespLogSavedVars")
f:close()