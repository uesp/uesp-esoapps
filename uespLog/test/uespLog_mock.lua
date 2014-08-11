
-- Use only for testing addon outside of the game

function GetString(id)
	return tostring(id)
end


function GetGameTimeMilliseconds()
	return os.time() * 1000
end


function GetTimeStamp()
	return 1234567890000
end


EVENT_MANAGER = { }
SLASH_COMMANDS = { }
ZO_SavedVars = { }

INVENTORY_UPDATE_REASON_DURABILITY_CHANGE = 2
LINK_STYLE_DEFAULT = 1
ACHIEVEMENT_REWARD_TYPE_NONE = 0
ACHIEVEMENT_REWARD_TYPE_ITEM = 1
ACHIEVEMENT_REWARD_TYPE_TITLE = 2
ACHIEVEMENT_REWARD_TYPE_POINTS = 3

EVENT_MANAGER.RegisterForEvent = function(self, addOnName, eventCode, funcObject)
end


ZO_SavedVars.NewAccountWide = function(self, savedVarName, version, section, defaultData)
	local Filename = "c:\\users\\dave\\documents\\elder scrolls online\\live\\savedvariables\\uespLog.lua"
	local msg = "return " .. savedVarName .. "[\"Default\"][\"@Reorx\"][\"$AccountWide\"][\""..section.."\"]"
	--print(msg)

	dofile(Filename)
	
	local f = assert(loadstring(msg))
	local result = f()
	
	if (result == nil) then
		result = uespLog.DeepCopy(defaultData)
	end
	
	--print(tostring(result), type(result))
	return result
end


function IsGameCameraUIModeActive()
	if (math.random(2) == 1) then return true end
	return false
end


function GetMapPlayerPosition(unitTag)
	return 0.183874, 0.9138137, 1.2034
end

function GetChatterGreeting()
	return "Chatter Greeting..."
end


function GetChatterOption(Index)
	return "Option text...", 2, 3, false, false
end

function GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
	return "Title", "icon.dds", false
end


function GetItemName(bagId, slotIndex)
	return "ItemName"
end


function GetItemLink(bagId, slotIndex, LinkStyle)
	return "|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest item|h"
end

function GetItemTrait(bagId, slotIndex)
	return 4
end


function GetItemType(bagId, slotIndex)
	return 1
end

function GetItemInfo(bagId, slotIndex)
	return "icon.dds", 2, 11, true, false, 1, 2, 3
end

function GetItemCraftingInfo(bagId, slotIndex)
	return true, 1, "", "", ""
end

function GetLastCraftingResultTotalInspiration()
	return 111
end

function GetNumLastCraftingResultItems()
	return 1
end

function GetLastCraftingResultItemInfo(index)
	return "Item Name", "icon.dds", 1, 11, true, 1, 2, 3, 4, 23, 89171726364
end

function Id64ToString(Id)
	return tostring(Id)
end

function GetMaxBags()
	return 5
end

function GetBagInfo(bagId)
	return "bagicon.dds", math.random(10)
end

function GetMapName()
	return "MapName"
end


function GetUnitLevel()
	return 10
end

	
function GetGameCameraInteractableActionInfo()
	return action, name, interactionBlocked, additionalInfo, context
end


 function GetUnitType(unitTag)
	return math.random(4)
 end
 
 
 function GetUnitGender(unitTag)
	return math.random(2) + 1
 end
 
 
 function GetUnitClass(unitTag)
	return "Class"
 end
 
 
 function GetUnitRace(unitTag)
	return "Race"
 end
 
 
 function GetUnitDifficulty(unitTag)
	return 1
 end
 
 
 function GetUnitPower(unitTag, powerType)
	return 100, 100, 100
 end
 
 function GetNumRecipeLists()
	return 2
 end
 
 function GetRecipeListInfo(recipeListIndex)
	return "RecipeList", 5, "upicon.dds", "downicon.dds", "overicon.dds", "disabled.dds", 123
 end
 
 function GetRecipeInfo(recipeListIndex, recipeIndex)
	return true, "Recipe Name", 2, 2, 1, 0
end

function GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
	return "Item Name", "icon.dds", 1, 12, 1
end

function GetRecipeResultItemLink(recipeListIndex, recipeIndex, linkStyle)
	return "|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest recipe item|h"
end

function GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
	return "Ingre Name", "icon.dds", 2, 7, 1
end

function GetRecipeIngredientItemLink(recipeListIndex, recipeIndex, ingredientIndex, LINK_STYLE_DEFAULT)
	return "|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest ingre|h"
end 

function GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
	return 123
end

function GetAchievementInfo(achievementId)
	return "Ach Name", "Description", 10, "icon.dds", false, "", 1
end

function GetAchievementNumRewards(achievementId)	
	return 1
end

function GetAchievementNumCriteria(achievementId)
	return 1
end

function GetNumAchievementCategories()
	return 10
end

function GetAchievementCategoryInfo(categoryIndex)
	return "Category", math.random(2)*4, 4, 0, 100, 0, "icon.dds", "pressed.dds", "mouseover.dds"
end

function GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
	return "SubCate Name", 6, 0, 60, 0
end

function GetAchievementRewardInfo(achievementId, rewardIndex)
	return math.random(4), 10, "Title", "icon.dds", 1 
end

function GetAchievementItemLink(achievementId, rewardIndex, LinkStyle)
	return "|HFFFFFF:item:27038:2:7:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|htest ingre|h"
end

function GetAchievementCriterion(achievementId, criterionIndex)
	return "Description", 0, 5
end

function IsPlayerInteractingWithObject()
	if (math.random(2) == 1) then return true end
	return false
end


function GetUnitName(unitTag)
	local roll = math.random(10)
	
	if (roll == 0) then
		return ""
	elseif (roll == 1) then
		return "chest"
	elseif (roll == 2) then
		return "skyshard"
	elseif (roll == 3) then
		return "heavy bag"
	elseif (roll == 4) then
		return "Mob 1"		
	elseif (roll == 5) then
		return "Mob2"		
	elseif (roll == 6) then
		return "NPC1"
	elseif (roll == 7) then
		return "NPC2"		
	else
		return ""
	end
end


function GetSkillLineInfo(skillIndex, skillType)
	return "Skill name", 16
end


function GetUniqueNameForCharacter(charname)
	return "Character Name"
end


function GetDisplayName()
	return "Display Name"
end


function GetDateStringFromTimestamp (timeStamp)
	return "1 March 2014"
end


function d(...)
	local Msg = ""

	for i = 1, select("#", ...) do
        local argValue = select(i, ...)
		Msg = Msg .. tostring(argValue)
	end
	
	print(Msg)	
end




