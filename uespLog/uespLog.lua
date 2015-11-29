-- uespLog.lua -- by Dave Humphrey, dave@uesp.net
-- AddOn for ESO that logs various game data for use on www.uesp.net
--
-- TODO:
--		- Log game version?
--		- Display charges of weapon
--		- Better loot target/source logging
--			- GetLootTargetInfo() Returns: string name, InteractTargetType targetType, string actionName
--		- Extended loot display messages (level, trait, style)
--		- Display message when weapon charges run out
--		- "Item Info" menu for all crafting stations tooltips
--		- MAC Install Issue
--				- Make root folder "uespLog"
--				- Remove utility folder?
--		- Yokudan style icon (35)?
--		- Akaviri style icon?
--		- Ancient Elf style icon (15)?
--
--
-- CHANGELOG:
--		v0.10 - 30 March 2014
--			- First release (earlier versions were for beta)
--
--		v0.11 - 31 March 2014
--			- Added a list of common NPCs to ignore (Rat, Mudcrab, Familiar, etc...)
--			- Removed inventory update message
--			- Fixed crash when using /uesplog on/off
--			- Tweaked some messages
--			- Gold looted and gold quest rewards are now logged
--
--		v0.11a - 31 March 2014
--			- Removed money messages used for testing
--
--		v0.12 - 8 April 2014
--			- Added /uesptime command
--			- Log change in skill points (for quest rewards)
--			- Now logs maximum HP/MG/ST for NPC targets
--			- Logs lock quality on chests
--			- Coordinates shown in bottom left on map in range (0,0) to (1,1)
--			- Added 'recipes' and 'achievements' options to /uespcount
--			- Added the 'extra' option to /uespdebug for testing purposes
--
--		v0.13 - 15 April 2014
--			- Shows inspiration for crafting events
--			- Shows the link for crafted items
--			- Added the /uespresearch command
--			- Added some messages in custom colors
--			- Added the /uespcolor on|off command
--			- uespLogMonitor: Fixed escape issue
--			- uespLogMonitor: Fixed issue not sending log entries with "blank" section in saved variable file
--			- uespLogMonitor: Log file is appended to and more things output to it
--			- uespLogMonitor: Added two file menu commands
--			- Fixed logging of target positions
--
--		v0.13a - 15 April 2014
--			- uespLogMonitor: Fixed incorrect use of blank account names
--
--		v0.14 - 2 May 2014
--			- Fixed item link/name display for crafted items
--			- Better logging of resource node positions
--			- Distinguish between group and self loot event
--			- Added estimated game time and moon phase for /uesptime
--			- Added /uespcount traits
--			- Added XP display and logging
--			- Improved display of item links
--			- Added MG/HP/ST/UT change display in debug output mode
--			- More colors (disable color messages with /uespcolor off)
--
--		v0.15 - 18 May 2014
--			- Added the "/uespdump smith|smithset" commands
--				- Dumps all smithable items to log when using an appropriate crafting station
--			- Adds a right-click "Link in Chat" menu option to popup item link
--			- Adds a right-click "Show Item Info" menu option on inventory lists and item popups
--			- Added the "/uespmakelink" (/uml) command 
--				- Format: /uespmakelink ID LEVEL SUBTYPE
--				- ID is required but LEVEL/SUBTYPE are optional
--				- For SUBTYPE description see http://www.uesp.net/wiki/User:Daveh/ESO_Notes#Item_Link_Format
--			- Fixed crash when looting some resources in non-english versions of the game
--			- Added the "/uespcharinfo" (/uci) command
--			- Added logging of veteran and alliance points
--			- Trade skill information display:
--				- Use "/uespcraft" to turn various components of the display on/off
--				- Shows provisioning level of ingredients in inventory lists and tooltips
--				- Color codes blue/purple ingredients
--				- Shows whether recipe is known or not in inventory lists (english only at the moment)
--				- Shows whether weapon/armor trait is known or not in inventory lists and tooltips
--				- Shows the item style in inventory lists and tooltips
--				- Provides a similar function as the Show Motifs add-on
--				- Compatible and similar function as the SousChef add-on
--				- Compatible and similar function as the ResearchAssistant add-on+
--			- In Testing: Added autolooting of provisioning ingredients:
--				- Only loot ingredients more than a specific level
--				- Auto loot all other items and money
--				- Turn off theloot in the game options to use
--				- Use "/uespcraft autoloot on/off" to enable (initially disabled)
--				- Use "/uespcraft minprovlevel [level]" to set which level of ingredients to autoloot
--				- Normal ingredient level is 1-6, 100 for blue ingredients and 101 for purple
--				- Displays a "Skipped..." message for items not looted
--				- Skipped provisioning items remain in the container
--
--		- v0.16 - 19 May 2014
--			- Fixed display of the "Show Item Info" menu item.
--			- Ingredient and style information shown in tooltip from a clicked item link (trait info can't be shown).
--			- Tweaked looting messages.
--			- Game language added to all log data.
--			- Footlockers now close properly when autoloot is on.
--
--		- v0.17 - 24 May 2014
--			- Always loot plump worms and crawdads (so flower nodes disappear when looted).
--			- Fix crash when autolooting quest items.
--			- Fixed display of pepper ingredient.
--			- Upgraded to 100004 API version for Craglorn.
--
--		- v0.18 - 2 July 2014
--			- Items linked in chat messages are logged.
--			- Items looted from mail messages are logged.
--			- Added a simple craft inspiration summation meter.
--				- Reset via: /uespreset inspiration
--				- Check via: /uespcount inspiration
--			- Item information shows the weapon and armor types.
--			- Added "/uesptime calibrate" to help with time calibration and testing.
--			- Improved the game time estimation.
--			- Changed API version to 100007.
--			- Added check to prevent NIL string outputs to log data.
--
--		- v0.19 - 21 August 2014
--			- Changed API version to 100008.
--			- Fixed crash when using "/uespdump inventory" due to API change.
--			- Fixed "nil string" crash bug due to strings over 1999 bytes being output to
--            the saved variable file. Long strings are split.
--
--		- v0.20 - 4 November 2014
--			- Fixed updated GetNumLastCraftingResultItemsAndPenalty() function.
--			- Updated API to 100010.
--			- Fix the CSV export utility.
--			- Attempted fix to replace the now remove 'reticleover' target position (uses the player position instead).
--			- Show item info fixed (updated new function names).
--
--		- v0.21 - 17 November 2014
--			- Fixed "/uespdump achievements" due to removed function.
--			- Fixed issue with facial animations.
--			- More conversation data is now logged.
--			- Added Dwemer style icon.
--			- The "Show Item Info" context menu works in more places now.
--			- "Show Item Info" displays much more item information.
--			- Much more item information is now logged.
--			- If you receive a "Low LUA Memory" warning you can try to increase the "LuaMemoryLimitMB" 
--			  parameter in the UserSettings.txt file.
--			- Dumping globals works better. Removed duplicate entries and unecessary objects. Userdata
-- 	          objects now dumped. Duplicate "classes" no longer dumped to save space.
--			- Dump globals now outputs the string for SI_* values.
--			- Added a method to iteratively dump all the global objects.
--					/uespdump globals [maxlevel]        -- Normal method all at once
--					/uespdump globals start [maxlevel]  -- Start iterative dumping
--					/uespdump globals stop              -- Stop iterative dumping
--					/uespdump globals status            -- Current status of iterative dump
--			- Started work on "/uespmineitems" (/umi) for mining item data. Use with caution as it can easily 
--			  crash your client. 
--						/uespmineitems [itemId]
--						/uespmineitems status
--						/uespmineitems start [startItemId]
-- 						/uespmineitems stop
--			  ItemIds are just numbers from 1-100000.
--			- BUG: Sometimes the saved variable data gets corrupted. This seems to occur during a global
--			  dump on rare occasions and is most likely an ESO/LUA engine bug. Use "/uespreset all" to
--			  clear the saved variable data back to an empty state which can usually fix this.
--			- Added short initialization message on startup.
--
--		- v0.22 - 11 March 2015
--			- Added "/uespmail deletenotify on|off" to turn the mail delete notification prompt on/off.
--			- Created item links use the item's name if available and valid.
--			- Added the "/uespcomparelink" (/ucl) command for testing item link comparisons.
--			- Added more data to the show item info output and item data logs.
--			- Warning is shown if any section data exceeds 65000 elements. The game seems to truncate
--			  arrays loaded from the saved variables to under ~65540 elements.
--			- Added the "/uespmineitem autostart [id]" mode. In this mode the item-miner will create 50000
--			  log entries before automatically reloading the UI, resetting the logged data and continuing.
--			  It will stop when you do "/uespmineitem stop" or the itemId reaches 100000.
--			- Changed color of item mining output to be more unique.
--			- Added the "/uespmineitem qualitymap".
--			- Added the "/uespmineitem subtype [number]" for only mining items of a certain type.
--			- Added the "/ut" shortcut for "/uesptime".
--			- Added the "/uespmakeenchant" (/ume) command.
--			- Fixed showing and logging of item trait abilities (crafted potions).
--			- Fixed crash on looting items from Update 6.
--			- Fixed crash due to renamed INTERACT_WINDOW object.
--			- Changed API version to 100011.
--			- Fixed issue with autolooting.
--
--		- v0.23 - 3 June 2015
--			- Fixed bug with Justice System / bounty error (no longer errors out when a guard acosts you).
--
--		- v0.24 - 27 July 2015
--			- Fixed item mining due to new item link format (1 more unknown data field).
--			- Added a basic settings menu using LibAddonMenu-2.0. Settings can
--			  be accessed through the game's Settings--Addon menu or via "/uespset".
--			- Bundled uespLogMonitor updated to v0.16 (minor performance based improvements). 
--			- Added the "/uespreset log" option to reset just the normal logged data section.
--			- Fixed display issue when turning crafting display on/off.
--			- Removed the autoloot function since ingredients don't have levels after update #6.
--			- Provisional ingredients updated from update #6.
--			- Item style text/icon only displayed for weapons and armors.
--			- Craft/trait/style info is now shown in the guild trader windows.
--			- Added the "/uespmineitems idcheck" command. Simply loops through all IDs and checks
--			  if it is a valid item or not and outputs a list of valid item ID ranges to the log.
--			- Added basic icons for Yokudan and Akaviri styles.
--			- Updated the experience messages. Veteran players will no longer receive the double
--			  experience debug message.
--			- Fixed game crash bug when trying to buy a horse.
--			- Fixed a game crash bug when using a quartermaster in Cyrodiil.
--			- Gold stolen from safeboxes will now be displayed.
--			- Shortened/tweaked the log message displayed in the chat window.
--			- Fixed the trait known/unknown display for nirnhoned items.
--
--		- v0.25 - 30 July 3015
--			- Add "/uespdump skills".
--			- Fix bug with negative xp values sometimes displayed.
--			- Added the "/uespenl" command to show the character's enlightenment pool.
--			- Added viewing of PVP events toggled by the "/uesppvp on/off" command (default is off).
--			  This is currently in testing and may be a bit spammy if you are in an active campaign.
--			- "/uesppvp showfights" will show all known fights in the current campaign.
--			- Fixed bug that results in a very large saved variable file.
--			- Fixed more crash bugs related to the guild store.
--			- Tweaked startup message.
--
--		- v0.26 - 31 July 2015
--			- Fixed another crash bug when the guild store is first opened.
--			- Style of rings and necklaces will no longer be shown.
--			- Item tooltips for stacks of items in the guild store include a "price per item" line.
--
--		- v0.30 - 30 Aug 2015
--			- Tweaked /uesptime output, added day of month and adjusted moon phase calculation.
--			- Online game time can be seen at: http://content3.uesp.net/esoclock/esoclock.php
--			- Update API version to 1000012.
--			- Telvar stones gained/lost will be shown if debug output is on.
--			- Added style icons for the new Glass/Xivkyn styles.
--			- Added the "/uespd [cmd]" (or "/ud [cmd]") command which is a short form for "/script d([cmd])".
--			- "/upf" is now a short form for "/uesppvp showfights".
--			- "/ue" is now a short form for "/uespenl".
--			- All colored text is closed by a "|r" to make sure it doesn't 'leak',
--			- Added known/unknown display to motif tooltips and rows.
-- 			- Tweak position of style/known icons in lists.
--			- Changed the skill dump command and output. Now outputs a lot more information to the log.
--			  Now has the format:
--				/uespdump skills 
--				/uespdump skills [basic/progression/learned/types/all] [note]
--
--		- v0.40 - 2 November 2015
--			- Ability icons are logged in skill dumps with the new GetAbilityIcon(abilityId) function.
--			- Added new item sub-types for V15/V16 equipment for item mining.
--			- Added some creatures to ignore from the Imperial City.
--			- "/uespdump globals" now works with private functions with numbers in their name.
--			- Trait display fixed for Nirnhoned items currently being researched.
--			- Tweaked looting messages and included Safeboxes in logged data.
--			- Added the /uesptreasuretimer (or /utt) for keeping track of looted containers. Once a
--			  container (chest, heavy sack, or safebox) is looted a timer will start and notify you
--			  with a chat message in a given amount of time. Current defaults are 2 minutes (120 sec)
--			  which works for chests in delves but may be too short for other containers in some zones.
--					/utt 					: Shows the current status
--					/utt [on/off]			: Turns the timer on/off (default is off)
--					/utt [name]				: Shows the timer length for the given container name.
--											: Valid names are: Chest, Heavy Sack, Safebox
--					/utt [name] [duration]	: Set the duration in seconds for the given container.
--			- Added more options to "/uespdump skills" to make it easier to dump partial skill logs for
--			  a certain class/race.
--			- The "/umi idcheck" was changed to do an iterative check instead of trying to do it all at
--			  once which resulted in a game crash. Now when run it will check 5000 items every 2 secs
--			  until finished. It cannot be stopped/interrupted once started.
--			- Added the "/umi quick [on/off]" option for mining items. Only mines/logs the normal v16
--			  version of each item.
--			- Fixed item links with no name showing (for Orsinium PTS).
--			- Added Orsinium mobs to ignore when logging.
--
--		- v0.41 -
--			- Added some more Orsinium mobs to ignore when logging.
--			- Fixed logging of hireling mail items (properly logs hireling type).
--			- Added new/missing style icons.
--			- Removed the "Craft completed..." log message if no inspiration was gained.
--			- Tweaked inventory style/trait icon positions.
--			- Added the /uesplorebook (/ulb) command. This turns the various "Lorebook Learned"
--		      messages seen at the top of the window on/off as follows:
--					/uesplorebook        -- Display status
--					/uesplorebook help   -- Display basic help
--					/uesplorebook on     -- Display all lorebook messages (default)
--					/uesplorebook off    -- Only display Mages Guild related lorebook messages
--
--	


--	GLOBAL DEFINITIONS
uespLog = { }

uespLog.version = "0.41"
uespLog.releaseDate = "2 November 2015"
uespLog.DATA_VERSION = 3

	-- Saved strings cannot exceed 1999 bytes in length (nil is output corrupting the log file)
uespLog.MAX_LOGSTRING_LENGTH = 1900

uespLog.TAB_CHARACTER = "\t"
uespLog.MIN_TARGET_CHANGE_TIMEMS = 2000
uespLog.ACTION_UNLOCK = GetString(SI_GAMECAMERAACTIONTYPE12)
uespLog.ACTION_USE = GetString(SI_GAMECAMERAACTIONTYPE5)
uespLog.ACTION_FISH = GetString(SI_GAMECAMERAACTIONTYPE16)
uespLog.ACTION_OPEN = GetString(SI_GAMECAMERAACTIONTYPE13)
uespLog.ACTION_SEARCH = GetString(SI_GAMECAMERAACTIONTYPE1)
uespLog.ACTION_HARVEST = GetString(SI_GAMECAMERAACTIONTYPE3)
uespLog.ACTION_MINE = GetString(SI_KEEPRESOURCEPROVIDERTYPE3)
uespLog.ACTION_CUT = "Cut"
uespLog.ACTION_COLLECT = "Collect"
uespLog.ACTION_STEALFROM = GetString(SI_GAMECAMERAACTIONTYPE20)
uespLog.ACTION_STEAL = GetString(SI_GAMECAMERAACTIONTYPE19)

uespLog.currentHarvestTarget = nil
uespLog.lastHarvestTarget = { }

uespLog.startGameTime = GetGameTimeMilliseconds()
uespLog.startTimeStamp = GetTimeStamp()
uespLog.currentXp = GetUnitXP('player')
uespLog.currentVeteranXp = GetUnitVeteranPoints('player')

uespLog.lastMailItems = { }
uespLog.lastMailId = 0

uespLog.lastPlayerHP = -1
uespLog.lastPlayerMG = -1
uespLog.lastPlayerST = -1
uespLog.lastPlayerUT = -1

uespLog.printDumpObject = false
uespLog.logDumpObject = true
uespLog.dumpIterateUserTable = true
uespLog.dumpIterateNextIndex = nil
uespLog.dumpIterateObject = nil
uespLog.dumpIterateStatus = 0
uespLog.dumpIterateParentName = ""
uespLog.dumpIterateMaxLevel = 3
uespLog.dumpIterateCurrentLevel = 0
uespLog.DUMP_ITERATE_TIMERDELAY = 100
uespLog.DUMP_ITERATE_LOOPCOUNT = 1000
uespLog.dumpIterateEnabled = false
uespLog.dumpMetaTable = { }
uespLog.dumpIndexTable = { }
uespLog.dumpTableTable = { }
uespLog.countGlobal = 0
uespLog.countGlobalError = 0

uespLog.origLoreBookLearnedFunction = nil
uespLog.origLoreBookLearnedSkillExpFunction = nil

uespLog.NextSectionSizeWarning = { }
uespLog.NextSectionWarningGameTime = { }
uespLog.NEXT_SECTION_SIZE_WARNING = 100
uespLog.FIRST_SECTION_SIZE_WARNING = 65000
uespLog.SECTION_SIZE_WARNING_COLOR = "ff9999"
uespLog.NEXT_SECTION_SIZE_WARNING_TIMEMS = 30000

	-- Objects to ignore when dumping
uespLog.dumpIgnoreObjects = { 
	["_G"] = 1, 
	["uespLog"] = 1, 
	["uespLogSavedVars"] = 1, 
	["uespLogCoordinates"] = 1, 
	["uespLogCoordinatesValue"] = 1,
	["uespLogUI"] = 1,
	["Zgoo"] = 1,
	["ZgooFrame"] = 1,
	["ZgooSV"] = 1,
	["ZGOO_ADDRESS_LOOKUP"] = 1
}

uespLog.lastConversationOption = { }
uespLog.lastConversationOption.Text = ""
uespLog.lastConversationOption.Type = ""
uespLog.lastConversationOption.Gold = ""
uespLog.lastConversationOption.Index = ""
uespLog.lastConversationOption.Important = ""

uespLog.lastLootUpdateCount = -1
uespLog.lastLootTargetName = ""

uespLog.savedVars = {}
    
	-- DayLength / OffsetMod / MoonStartMod
	-- 21000 / 3600 / 0
	-- 17280 / 9000 / 0
	-- 21000 / 4475 / 207360
	--
uespLog.GAMETIME_REALSECONDS_OFFSET = 6471		-- in real seconds
uespLog.GAMETIME_DAY_OFFSET = 0.37				-- in game time days
uespLog.DEFAULT_GAMETIME_OFFSET = 1396083600
uespLog.DEFAULT_GAMETIME_YEAROFFSET = 582

uespLog.DEFAULT_REALSECONDSPERGAMEDAY = 20955
uespLog.DEFAULT_REALSECONDSPERGAMEYEAR = uespLog.DEFAULT_REALSECONDSPERGAMEDAY * 365
uespLog.DEFAULT_REALSECONDSPERGAMEHOUR = uespLog.DEFAULT_REALSECONDSPERGAMEDAY / 24
uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE = uespLog.DEFAULT_REALSECONDSPERGAMEHOUR / 60
uespLog.DEFAULT_REALSECONDSPERGAMESECOND = uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE / 60

uespLog.DEFAULT_MOONPHASESTARTTIME = 1396083600 - 207360 - 180000
uespLog.DEFAULT_MOONPHASETIME = 100 * 3600

uespLog.TES_MONTHS = {
	"Morning Star",
	"Sun's Dawn", 
	"First Seed",
	"Rain's Hand",
	"Second Seed",
	"Midyear",
	"Sun's Height",
	"Last Seed",
	"Hearthfire",
	"Frostfall",
	"Sun's Dusk",
	"Evening Star"
}
	
uespLog.TES_WEEKS = {
	"Sundas",
	"Morndas",
	"Tirdas",
	"Middas",
	"Turdas",
	"Fredas",
	"Loredas" 
}

uespLog.ignoredNPCs = {
	Familiar = 1,
	Cat = 1,
	Rat = 1,
	Lizard = 1,
	Mudcrab = 1,
	Horse = 1,
	Snake = 1,
	Scorpion = 1,
	Beetle = 1,
	Fox = 1,
	Goat = 1,
	Chicken = 1,
	Dog = 1,
	Rabbit = 1,
	Clannfear = 1,
	Frog = 1,
	Deer = 1,
	Spider = 1,
	Torchbug = 1,
	Pig = 1, 
	Sheep = 1,
	Cow = 1,
	Butterfly = 1,
	Squirrel = 1,
	Centipede = 1,
	Fleshflies = 1,
	Monkey = 1,
	Wasp = 1,
	Honor = 1,
	Scuttler = 1,
	Scrib = 1,
	Antelope = 1,
	Ox = 1,
	Wormmouth = 1,  	--Craglorn
	Skavenger = 1, 		--Craglorn
	Fellrunner = 1,  	--Craglorn
	Daggerback = 1,  	--Craglorn
	["Fennec Fox"] = 1,  	--Craglorn
	["Thorn Geko"] = 1,  	--Craglorn
	["Pony Guar"] = 1,
	["Bantam Guar"] = 1,
	["Razak's Opus"] = 1,
	["Draft Horse"] = 1,
	["Light Horse"] = 1,
	["Restoring Twilight"] = 1,
	["Winged Twilight"] = 1,
	["Twilight Matriarch"] = 1,
	["Volatile Familiar"] = 1,
	["Thorn Gecko"] = 1,  	--Craglorn
	["Sandroach"] = 1,  	--Craglorn
	["Camel"] = 1,  		--Craglorn
	["Daedrat"] = 1,		--Imperial City
	["Fiendroth"] = 1,		--Imperial City
	["Bear Cub"] = 1,		--Orsinium
	["Pocket Mammoth"] = 1,	--Orsinium
	["Chub Loon"] = 1,		--Orsinium
	["Pack Echatere"] = 1,	--Orsinium
	["Echalette"] = 1,		--Orsinium
}

uespLog.lastTargetData = {
	type = "",
	name = "",
	x = "",
    y = "",
    zone = "",
	gameTime = "",
	timeStamp = "",
	level = "",
	race = "",
	class = "",
	maxHp = "",
	maxMg = "",
	maxSt = "",
	action = "",
	interactionType = "",
}

uespLog.lastOnTargetChange = ""
uespLog.lastOnTargetChangeGameTime = 0
uespLog.lastMoneyChange = 0
uespLog.lastMoneyGameTime = 0
uespLog.lastItemLink = ""
uespLog.lastItemLinks = { }

uespLog.researchColor = "00ffff"
uespLog.timeColor = "00ffff"
uespLog.traitColor = "00ffff"
uespLog.countColor = "00ffff"
uespLog.xpColor = "6699ff"
uespLog.itemColor = "ff9900"
uespLog.statColor = "44ffff"
uespLog.mineColor = "99ff99"
uespLog.mineColorWarning = "ff9999"
uespLog.pvpColor = "ff33ff"

uespLog.currentTargetData = {
	name = "",
	x = "",
	y = "",
	zone = "",
	action = "",
	interactionType = "",
}

uespLog.currentConversationData = {
    npcName = "",
    npcLevel = "",
    x = "",
    y = "",
    zone = "",
}

uespLog.ALLIANCE_SHORT_NAMES = {
	[1] = "AD",
	[2] = "EP",
	[3] = "DC",
}

uespLog.ALLIANCE_NAMES = {
	[1] = "Aldmeri Dominion",
	[2] = "Ebonheart Pack",
	[3] = "Daggerfall Covenant",
}

uespLog.MINEITEM_LEVELS = {
	{  1, 50,   1,   6, "dropped" },
	{  1, 50 ,  7,   9, "dropped" },
	{  1,  1,  30,  34, "crafted" },
	{  4,  4,  25,  29, "crafted" },
	{  6, 50,  20,  24, "crafted" },
	{ 50, 50,  39,  48, "quest" },
	{ 50, 50,  51,  60, "dropped" },
	{ 50, 50,  61,  70, "dropped" },
	{ 50, 50,  81,  90, "dropped" },
	{ 50, 50,  91, 100, "dropped" },
	{ 50, 50, 101, 110, "dropped" },
	{ 50, 50, 111, 120, "dropped/sold" },
	{ 50, 50, 125, 134, "crafted" },
	{ 50, 50, 135, 144, "crafted" },
	{ 50, 50, 145, 154, "crafted" },
	{ 50, 50, 155, 164, "crafted" },
	{ 50, 50, 165, 174, "crafted" },
	{ 50, 50, 235, 235, "store" },
	{ 50, 50, 236, 240, "crafted" }, --VR11
	{ 50, 50, 241, 245, "dropped" }, --VR11
	{ 50, 50, 253, 253, "store" },
	{ 50, 50, 254, 258, "crafted" },
	{ 50, 50, 259, 263, "dropped" },
	{ 50, 50, 272, 276, "crafted" },
	{ 50, 50, 277, 281, "dropped" },
	{ 50, 50, 290, 294, "crafted" },
	{ 50, 50, 295, 299, "dropped" },
	{ 50, 50, 301, 301, "dropped" },
	{ 50, 50, 304, 307, "dropped" },
	{ 50, 50, 308, 312, "crafted" },
	{ 50, 50, 313, 317, "dropped" },
	{  1, 50, 319, 319, "novalue" },
	{ 50, 50, 323, 338, "novalue" },
	{ 50, 50, 358, 364, "dropped" },
	{ 50, 50, 366, 370, "crafted" },
}

uespLog.MINEITEM_ONLYSUBTYPE = 366
uespLog.MINEITEM_ONLYLEVEL = 50

uespLog.mineItemBadCount = 0
uespLog.mineItemCount = 0
uespLog.mineUpdateItemCount = 0
uespLog.mineNextItemId = 1
uespLog.isAutoMiningItems = false
uespLog.MINEITEMS_AUTODELAY = 1000 -- Delay in ms
uespLog.MINEITEMS_AUTOLOOPCOUNT = 400
uespLog.MINEITEMS_AUTOMAXLOOPCOUNT = 400
uespLog.mineItemsAutoNextItemId = 1
uespLog.mineItemsEnabled = false
uespLog.MINEITEMS_AUTOSTOP_LOGCOUNT = 50000
uespLog.mineItemAutoReload = false
uespLog.mineItemLastReloadTimeMS = GetGameTimeMilliseconds()
uespLog.MINEITEM_AUTORELOAD_DELTATIMEMS = 120000
uespLog.mineItemAutoRestart = false
uespLog.mineItemAutoRestartOutputEnd = false
uespLog.MINEITEM_AUTO_MAXITEMID = 100000
uespLog.mineItemOnlySubType = -1
uespLog.mineItemOnlyLevel = -1
uespLog.MINEITEM_QUALITYMAP_ITEMID = 47000
uespLog.MINEITEM_IDCHECK_NUMITEMS = 5000
uespLog.MINEITEM_IDCHECK_TIMEDELTA = 2000
uespLog.CurrentIdCheckItemId = 1
uespLog.IsIdCheckInProgress = false
uespLog.IdCheckRangeIdStart = -1
uespLog.IdCheckValidCount = 0
uespLog.IdCheckTotalCount = 0


uespLog.DEFAULT_DATA = 
{
	data = {}
}

uespLog.DEFAULT_SETTINGS = 
{
	data = {
		["debug"] = false,
		["debugExtra"] = false,
		["logData"] = true,
		["color"] = true,
		["totalInspiration"] = 0,
		["craft"] = true,
		["craftStyle"] = true,
		["craftTrait"] = true,
		["craftRecipe"] = true,
		["craftIngredient"] = true,
		["craftAutoLoot"] = false,
		["craftAutoLootMinProvLevel"] = 1,
		["mailDeleteNotify"] = false,
		["mineItemsAutoNextItemId"] = 1,
		["mineItemAutoReload"] = false,
		["mineItemAutoRestart"] = false,
		["mineItemsEnabled"] = false,
		["mineItemOnlySubType"] = -1,
		["mineItemOnlyLevel"] = -1,
		["isAutoMiningItems"] = false,
		["pvpUpdate"] = false,
		["enabledTreasureTimers"] = false,
		["TREASURE_TIMER_DURATIONS"] = {
			["chest"] = 120,
			["heavy sack"] = 120,
			["safebox"] = 120,
		},
		["loreBookMsg"] = true,
	}
}


function uespLog.BoolToOnOff(flag)
	if (flag) then return "on" end
	return "off"
end


function uespLog.GetLoreBookMsgFlag()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.loreBookMsg == nil) then
		uespLog.savedVars.settings.data.loreBookMsg = uespLog.DEFAULT_SETTINGS.loreBookMsg
	end
	
	return uespLog.savedVars.settings.data.loreBookMsg
end


function uespLog.SetLoreBookMsgFlag(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.loreBookMsg = flag
end


function uespLog.GetTreasureTimers()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.TREASURE_TIMER_DURATIONS == nil) then
		uespLog.savedVars.settings.data.TREASURE_TIMER_DURATIONS = uespLog.DEFAULT_SETTINGS.TREASURE_TIMER_DURATIONS
	end
	
	return uespLog.savedVars.settings.data.TREASURE_TIMER_DURATIONS
end


function uespLog.IsTreasureTimerEnabled()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.enabledTreasureTimers == nil) then
		uespLog.savedVars.settings.data.enabledTreasureTimers = uespLog.DEFAULT_SETTINGS.enabledTreasureTimers
	end
	
	return uespLog.savedVars.settings.data.enabledTreasureTimers
end


function uespLog.SetTreasureTimerEnabled(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.enabledTreasureTimers = flag
end	


function uespLog.GetTotalInspiration()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.totalInspiration == nil) then
		uespLog.savedVars.settings.data.totalInspiration = 0
	end
	
	return uespLog.savedVars.settings.data.totalInspiration
end


function uespLog.SetTotalInspiration(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.totalInspiration = value
end


function uespLog.AddTotalInspiration(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.totalInspiration == nil) then
		uespLog.savedVars.settings.data.totalInspiration = 0
	end
	
	uespLog.savedVars.settings.data.totalInspiration = uespLog.savedVars.settings.data.totalInspiration + value
end


function uespLog.IsMailDeleteNotify()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.mailDeleteNotify
end


function uespLog.SetMailDeleteNotify(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.mailDeleteNotify = flag
end	


function uespLog.NotifyDeleteMailAdded (self)

	if not self.mailId or not self:IsMailDeletable() then
		return
	end

	local numAttachments, attachedMoney = GetMailAttachmentInfo(self.mailId)
	self.pendingDelete = true

	if numAttachments > 0 and attachedMoney > 0 then
		ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS_AND_MONEY", self.mailId)
	elseif numAttachments > 0 then
		ZO_Dialogs_ShowDialog("DELETE_MAIL_ATTACHMENTS", self.mailId)
	elseif attachedMoney > 0 then
		ZO_Dialogs_ShowDialog("DELETE_MAIL_MONEY", self.mailId)
	elseif uespLog.IsMailDeleteNotify() then
		ZO_Dialogs_ShowDialog("DELETE_MAIL", { callback = function(...) self:ConfirmDelete(...) end, mailId = self.mailId } )
	else
		self.confirmedDelete = false
		self:ConfirmDelete(self.mailId)
	end
		
end


function uespLog.IsDebug()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.debug
end


function uespLog.IsDebugExtra()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.debugExtra == nil) then
		uespLog.savedVars.settings.data.debugExtra = uespLog.DEFAULT_SETTINGS.data.debugExtra
	end
	
	return uespLog.savedVars.settings.data.debugExtra
end


function uespLog.IsColor()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.color
end


function uespLog.IsPvpUpdate()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.pvpUpdate
end


function uespLog.SetDebug(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.debug = flag
end	


function uespLog.SetPvpUpdate(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.pvpUpdate = flag
end	


function uespLog.SetColor(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.color = flag
end	


function uespLog.SetDebugExtra(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.debugExtra == nil) then
		uespLog.savedVars.settings.data.debugExtra = uespLog.DEFAULT_SETTINGS.data.debugExtra
	end
	
	uespLog.savedVars.settings.data.debugExtra = flag
end	


function uespLog.IsLogData()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	return uespLog.savedVars.settings.data.logData
end


function uespLog.SetLogData(flag)
	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	uespLog.savedVars.settings.data.logData = flag
end	


function uespLog.Msg(text)
    d(text)
end


function uespLog.MsgColor(Color, text)
	if (uespLog.IsColor()) then
		d("|c" .. Color .. text .. "|r")
	else
		d(text)
	end
end


function uespLog.DebugLogMsg(text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = "UESP::Ignored " .. text
		else
			text = "UESP::" .. text
		end
		
		d(text)
	end

end


function uespLog.DebugLogMsgColor(Color, text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = "UESP::Ignored " .. text
		else
			text = "UESP::" .. text
		end
		
		if (uespLog.IsColor()) then
			d("|c" .. Color .. text.."|r")
		else
			d(text)
		end
	end

end


function uespLog.DebugMsg(text)
	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		d(text)
	end
end


function uespLog.DebugMsgColor(Color, text)

	if (uespLog.IsDebug()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		if (uespLog.IsColor()) then
			d("|c" .. Color .. text .. "|r")
		else
			d(text)
		end
	end
	
end


function uespLog.DebugExtraMsg(text)
	if (uespLog.IsDebugExtra()) then
	
		if (not uespLog.IsLogData()) then 
			text = text .. " (logging off)"
		end
		
		d(text)
	end
end


function uespLog.gameTime()
	return GetGameTimeMilliseconds()
end


function uespLog.EndsWith(s, send)
	return #s >= #send and s:find(send, #s-#send+1, true) and true or false
end


function uespLog.BeginsWith(s, sBegin)
	return string.sub(s, 1, string.len(sBegin)) == sBegin
end


function uespLog.AppendDataToLog(section, ...)

	if (not uespLog.IsLogData()) then return end
	
	local logString = ""
	local arg = {...}
		
	for i = 1, #arg do
		local argValue = arg[i]
		
		if (argValue == nil) then
			-- Skip nil inputs
		elseif (type(argValue) == "table") then
			
					-- Try to make the event the first thing output
			if (argValue.event ~= nil) then
				logString = logString .. "event{" .. tostring(argValue.event) .. "}  "
			end
			
			for varName, varValue in pairs(argValue) do
				if (varName ~= "event") then
					logString = logString .. tostring(varName).."{" .. tostring(varValue) .. "}  "
				end
			end
		else
			logString = logString .. "unknown{" .. tostring(argValue) .. "}  "
		end
    end
	
	logString = logString .. "lang{".. GetCVar("Language.2") .."}  "
	
	uespLog.AppendStringToLog(section, logString)
end


function uespLog.AppendStringToLog(section, logString)

	if (not uespLog.IsLogData()) then return end
	if (logString == nil) then return end

	if (uespLog.savedVars[section] == nil) then
		uespLog.DebugMsg("UESP::Error -- The section" .. tostring(section) .." is not valid!")
		return
	end
	
	local sv = uespLog.savedVars[section].data
	
	if (sv == nil) then
		uespLog.savedVars[section].data = { }
		sv = uespLog.savedVars[section].data
	end
		
	if (uespLog.NextSectionSizeWarning[section] == nil) then
		uespLog.NextSectionSizeWarning[section] = uespLog.FIRST_SECTION_SIZE_WARNING
		uespLog.NextSectionWarningGameTime[section] = 0
	end
		
	if (#sv >= uespLog.NextSectionSizeWarning[section] and GetGameTimeMilliseconds() >= uespLog.NextSectionWarningGameTime[section]) then
		uespLog.MsgColor(uespLog.SECTION_SIZE_WARNING_COLOR, "WARNING: Log '"..tostring(section).."' data exceeds "..tostring(#sv).." elements in size.")
		uespLog.DebugMsgColor(uespLog.SECTION_SIZE_WARNING_COLOR, "Loss of data is possible when loading the saved variable file!")
		uespLog.DebugMsgColor(uespLog.SECTION_SIZE_WARNING_COLOR, "You should save the data, submit it to the UESP and do \"/uespreset all\".")
		uespLog.NextSectionSizeWarning[section] = #sv + uespLog.NEXT_SECTION_SIZE_WARNING
		uespLog.NextSectionWarningGameTime[section] = GetGameTimeMilliseconds() + uespLog.NEXT_SECTION_SIZE_WARNING_TIMEMS
	end
	
		-- Fix long strings being output as "nil"
	while (#logString >= uespLog.MAX_LOGSTRING_LENGTH) do
		local firstPart = string.sub(logString, 1, uespLog.MAX_LOGSTRING_LENGTH)
		local secondPart = string.sub(logString, uespLog.MAX_LOGSTRING_LENGTH+1, -1)
		sv[#sv+1] = firstPart .. "#STR#"
		logString = "#STR#" .. secondPart
	end
	
	sv[#sv+1] = logString
end


function uespLog.GetTimeData()
	local result = { }
	
	result.timeStamp = Id64ToString(GetTimeStamp())
	result.gameTime = GetGameTimeMilliseconds()
	
	return result
end


function uespLog.GetLastTargetData()
	local result = { }
	
	result.x = uespLog.lastTargetData.x
	result.y = uespLog.lastTargetData.y
	result.zone = uespLog.lastTargetData.zone
	result.lastTarget = uespLog.lastTargetData.name
	
	return result
end


function uespLog.GetCurrentTargetData()
	local result = { }
	
	result.x = uespLog.currentTargetData.x
	result.y = uespLog.currentTargetData.y
	result.zone = uespLog.currentTargetData.zone
	result.lastTarget = uespLog.currentTargetData.name
	
	return result
end


function uespLog.GetPlayerPositionData()
	return uespLog.GetUnitPositionData("player")
end


function uespLog.GetUnitPositionData(unitTag)
	local result = { }
	
	if (unitTag == "reticleover") then
		result.x, result.y = GetMapPlayerPosition("player")
	elseif (unitTag == "interact") then
		result.x, result.y = GetMapPlayerPosition("player")
	else
		result.x, result.y = GetMapPlayerPosition(unitTag)
	end
	
	result.zone = GetMapName()
	
	return result
end


function uespLog.GetUnitPosition(unitName)
	local x, y, z
                     
	if (unitName == "reticleover") then
		x, y, z = GetMapPlayerPosition("player")
	elseif (unitName == "interact") then
		x, y, z = GetMapPlayerPosition("player")
	else
		x, y, z = GetMapPlayerPosition(unitName)
	end
	
	local zone = GetMapName()
	return x, y, z, zone
end


function uespLog.GetPlayerPosition()
	return uespLog.GetUnitPosition("player")
end


function uespLog.ParseLink(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if type(link) == "string" then
		local color, data, text = link:match("|H(.-):(.-)|h(.-)|h")
		
		if (color == nil or text == nil or data == nil) then
			return link, "", "", "", link, ""
		end
		
		local niceName = link
		local niceLink = link
		
		if (text == "") then
			text = GetItemLinkName(link)
		end
		
		if (text ~= nil) then
			niceName = text:gsub("%^.*", "")
			niceLink = "|H"..color..":"..data.."|h["..niceName.."]|h"
		end
		
		return text, color, data, niceName, niceLink
    end
	
	return "", "", "", "", link
end


function uespLog.MakeNiceLink(link)
	
	if type(link) == "string" then
		local color, data, text = link:match("|H(.-):(.-)|h(.-)|h")
		
		if (color == nil or text == nil or data == nil) then
			return link, ""
		end
		
		local niceName = link
		local niceLink = link
		
		if (text == "") then
			text = GetItemLinkName(link)
		end
		
		if (text ~= nil) then
			niceName = text:gsub("%^.*", "")
			niceLink = "|H"..color..":"..data.."|h["..niceName.."]|h"
		end
		
		return niceLink, niceName
    end
	
	return link, ""
end


function uespLog.ParseLinkID(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if (type(link) == "string") then
		local color, itemType, itemId, data1, data2, data, text = link:match("|H(.-):(.-):(.-):(.-):(.-):(.-)|h(.-)|h")
		
		if (color == nil or itemId == nil or data1 == nil or data == nil) then
			return link, "", "", "", "", link, link
		end
		
		local niceName = link
		local niceLink = link
		local allData = itemId..":"..data1 .. ":" .. data2 .. ":" .. data
		
		if (text == "") then
			text = GetItemLinkName(link)
		end
		
		if (text ~= nil) then
			niceName = text:gsub("%^.*", "")
			niceLink = "|H"..color..":"..itemType..":"..allData.."|h["..niceName.."]|h"
		end		
		
		return text, color, itemId, data2, allData, niceName, niceLink
    end
	
	return "", "", "", "", "", "", link
end


function uespLog.GetItemLinkID(link)
	--|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h
	
	if type(link) == "string" then
		local color, itemType, itemId, data, text = link:match("|H(.-):(.-):(.-):(.-)|h(.-)|h")
		
		if (color == nil or itemId == nil or itemType == nil or data == nil or text == nil) then
			return nil
		end
		
		local parsedId = tonumber(itemId)
		
		if (parsedId == nil or parsedId <= 0) then
			return nil
		end
		
		return parsedId
    end
	
	return nil
end


--	Function fired at addon loaded to setup variables and default settings
function uespLog.Initialize( self, addOnName )

	if ( addOnName ~= "uespLog" ) then 
		return 
	end
	
	if (uespLog.origLoreBookLearnedFunction == nil) then
		uespLog.origLoreBookLearnedFunction = ZO_CenterScreenAnnounce_GetHandlers()[EVENT_LORE_BOOK_LEARNED]
	end
	
	if (uespLog.origLoreBookLearnedSkillExpFunction == nil) then
		uespLog.origLoreBookLearnedSkillExpFunction = ZO_CenterScreenAnnounce_GetHandlers()[EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE]
	end
	
	ZO_CenterScreenAnnounce_GetHandlers()[EVENT_LORE_BOOK_LEARNED] = uespLog.EventLoreBookLearned
	ZO_CenterScreenAnnounce_GetHandlers()[EVENT_LORE_BOOK_LEARNED_SKILL_EXPERIENCE] = uespLog.EventLoreBookLearnedSkillExperience
	
	uespLog.savedVars = {
		["all"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", uespLog.DATA_VERSION, "all", uespLog.DEFAULT_DATA),  
		["achievements"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", uespLog.DATA_VERSION, "achievements", uespLog.DEFAULT_DATA),  
		["globals"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", uespLog.DATA_VERSION, "globals", uespLog.DEFAULT_DATA),  
		["info"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", uespLog.DATA_VERSION, "info", uespLog.DEFAULT_DATA),  
		["settings"] = ZO_SavedVars:NewAccountWide("uespLogSavedVars", uespLog.DATA_VERSION, "settings", uespLog.DEFAULT_SETTINGS),  		
	}
	
	uespLog.mineItemsAutoNextItemId = uespLog.savedVars.settings.data.mineItemsAutoNextItemId or uespLog.mineItemsAutoNextItemId
	uespLog.mineItemAutoReload = uespLog.savedVars.settings.data.mineItemAutoReload or uespLog.mineItemAutoReload
	uespLog.mineItemAutoRestart = uespLog.savedVars.settings.data.mineItemAutoRestart or uespLog.mineItemAutoRestart
	uespLog.mineItemsEnabled = uespLog.savedVars.settings.data.mineItemsEnabled or uespLog.mineItemsEnabled
	uespLog.isAutoMiningItems = uespLog.savedVars.settings.data.isAutoMiningItems or uespLog.isAutoMiningItems
	uespLog.mineItemOnlySubType = uespLog.savedVars.settings.data.mineItemOnlySubType or uespLog.mineItemOnlySubType
	uespLog.mineItemOnlyLevel = uespLog.savedVars.settings.data.mineItemOnlyLevel or uespLog.mineItemOnlyLevel
	uespLog.pvpUpdate = uespLog.savedVars.settings.data.pvpUpdate or uespLog.pvpUpdate
	uespLog.mineItemLastReloadTimeMS = GetGameTimeMilliseconds()
	
	zo_callLater(uespLog.InitAutoMining, 5000)
	
	uespLog.InitSettingsMenu()
			
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_RETICLE_TARGET_CHANGED, uespLog.OnTargetChange)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_CONDITION_COUNTER_CHANGED, uespLog.OnQuestCounterChanged)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_ADDED, uespLog.OnQuestAdded)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_REMOVED, uespLog.OnQuestRemoved)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_OBJECTIVE_COMPLETED, uespLog.OnQuestObjectiveCompleted)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_ADVANCED, uespLog.OnQuestAdvanced)	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_COMPLETE_EXPERIENCE, uespLog.OnQuestCompleteExperience)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_OPTIONAL_STEP_ADVANCED, uespLog.OnQuestOptionalStepAdvanced)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SKILL_POINTS_CHANGED, uespLog.OnSkillPointsChanged)
		
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LOOT_UPDATED, uespLog.OnLootUpdated)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LOOT_RECEIVED, uespLog.OnLootGained)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LOOT_CLOSED, uespLog.OnLootClosed)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MONEY_UPDATE, uespLog.OnMoneyUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_INVENTORY_SINGLE_SLOT_UPDATE, uespLog.OnInventorySlotUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_INVENTORY_ITEM_USED, uespLog.OnInventoryItemUsed)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_BUY_RECEIPT, uespLog.OnBuyReceipt)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SELL_RECEIPT, uespLog.OnSellReceipt)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_TELVAR_STONE_UPDATE, uespLog.OnTelvarStoneUpdate)	

    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LORE_BOOK_ALREADY_KNOWN, uespLog.OnLoreBookAlreadyKnown)
    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_LORE_BOOK_LEARNED, uespLog.OnLoreBookLearned)

    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SHOW_BOOK, uespLog.OnShowBook)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SKILL_RANK_UPDATE, uespLog.OnSkillRankUpdate)

	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CRAFT_COMPLETED, uespLog.OnCraftCompleted)
	
	ZO_InteractWindow:UnregisterForEvent(EVENT_CHATTER_BEGIN)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CONVERSATION_UPDATED, uespLog.OnConversationUpdated)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_QUEST_OFFERED, uespLog.OnQuestOffered)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHATTER_BEGIN, uespLog.OnChatterBegin)
    EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHATTER_END, uespLog.OnChatterEnd)
	
	uespLog.Old_HandleChatterOptionClicked = ZO_InteractionManager.HandleChatterOptionClicked
	ZO_InteractionManager.HandleChatterOptionClicked = uespLog.HandleChatterOptionClicked
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_RECIPE_LEARNED, uespLog.OnRecipeLearned)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_BEGIN_LOCKPICK, uespLog.OnBeginLockPick)
	
	--EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_EXPERIENCE_UPDATE, uespLog.OnExperienceUpdate)
	--EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_VETERAN_POINTS_UPDATE, uespLog.OnVeteranPointsUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_EXPERIENCE_GAIN, uespLog.OnExperienceGain)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_VETERAN_POINTS_GAIN, uespLog.OnVeteranPointsGain)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_ALLIANCE_POINT_UPDATE, uespLog.OnAlliancePointsUpdate)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_POWER_UPDATE, uespLog.OnPowerUpdate)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SYNERGY_ABILITY_GAINED, uespLog.OnSynergyAbilityGained)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_SYNERGY_ABILITY_LOST, uespLog.OnSynergyAbilityLost)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_EFFECT_CHANGED, uespLog.OnEffectChanged)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CHAT_MESSAGE_CHANNEL, uespLog.OnChatMessage)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, uespLog.OnMailMessageTakeAttachedItem)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_MAIL_READABLE, uespLog.OnMailMessageReadable)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_JUSTICE_GOLD_PICKPOCKETED, uespLog.OnGoldPickpocketed)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_JUSTICE_GOLD_REMOVED, uespLog.OnGoldRemoved)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_JUSTICE_ITEM_PICKPOCKETED, uespLog.OnItemPickpocketed)
	
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_ARTIFACT_CONTROL_STATE, uespLog.OnArtifactControlState)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CAPTURE_AREA_STATUS, uespLog.OnCaptureAreaStatus)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_CORONATE_EMPEROR_NOTIFICATION, uespLog.OnCoronateEmpererNotification)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_OBJECTIVE_CONTROL_STATE, uespLog.OnObjectiveControlState)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_KEEP_ALLIANCE_OWNER_CHANGED, uespLog.OnKeepAllianceOwnerChanged)
	--EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_KEEP_RESOURCE_UPDATE, uespLog.OnKeepResourceUpdate)   -- Happens very frequently
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_KEEP_UNDER_ATTACK_CHANGED, uespLog.OnKeepUnderAttack)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_KEEP_GATE_STATE_CHANGED, uespLog.OnKeepGateStateChanged)
	EVENT_MANAGER:RegisterForEvent( "uespLog" , EVENT_GUILD_KEEP_CLAIM_UPDATED, uespLog.OnGuildKeepClaimUpdated)	
		
	-- EVENT_ARTIFACT_CONTROL_STATE(integer eventCode, string artifactName, integer keepId, string playerName, integer playerAlliance, integer controlEvent, integer controlState, integer campaignId)
	--EVENT_CAPTURE_AREA_STATUS (integer eventCode, integer keepId, integer objectiveId, integer battlegroundContext, integer capturePoolValue, integer capturePoolMax, integer capturingPlayers, integer contestingPlayers, integer 	owningAlliance)
	--EVENT_CORONATE_EMPEROR_NOTIFICATION (integer eventCode, integer campaignId, string emperorName, integer emperorAlliance)
	--EVENT_DEPOSE_EMPEROR_NOTIFICATION (integer eventCode, integer campaignId, string emperorName, integer emperorAlliance, bool abdication)
	--EVENT_FORWARD_CAMPS_UPDATED (integer eventCode)
	--EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS (integer durationMS)
	--EVENT_OBJECTIVE_CONTROL_STATE (integer eventCode, integer objectiveKeepId, integer objectiveObjectiveId, integer battlegroundContext, string objectiveName, integer objectiveType, integer objectiveControlEvent, integer objectiveControlState, integer objectiveParam1, integer objectiveParam2)
	--EVENT_ZONE_SCORING_CHANGED (integer eventCode)
	--EVENT_KEEPS_INITIALIZED (integer eventCode)
	--EVENT_KEEP_ALLIANCE_OWNER_CHANGED (integer eventCode, integer keepId, integer battlegroundContext, integer owningAlliance)
	--EVENT_KEEP_END_INTERACTION (integer eventCode)
	--EVENT_KEEP_GATE_STATE_CHANGED (integer eventCode, integer keepId, bool open)
	--EVENT_KEEP_GUILD_CLAIM_UPDATE (integer eventCode, integer keepId, integer battlegroundContext)
	--EVENT_KEEP_INITIALIZED (integer eventCode, integer keepId, integer battlegroundContext)
	--EVENT_KEEP_OWNERSHIP_CHANGED_NOTIFICATION (integer eventCode, integer campaignId, integer keepId, integer oldOwner, integer newOwner)
	--EVENT_KEEP_RESOURCE_UPDATE (integer eventCode, integer keepId)
	--EVENT_KEEP_START_INTERACTION (integer eventCode)
	--EVENT_KEEP_UNDER_ATTACK_CHANGED (integer eventCode, integer keepId, integer battlegroundContext, bool underAttack)
	--EVENT_END_KEEP_GUILD_CLAIM_INTERACTION (integer eventCode)
	--EVENT_END_KEEP_GUILD_RELEASE_INTERACTION (integer eventCode)
	--EVENT_START_KEEP_GUILD_CLAIM_INTERACTION (integer eventCode)
	--EVENT_START_KEEP_GUILD_RELEASE_INTERACTION (integer eventCode)
	--EVENT_GUILD_KEEP_CLAIM_UPDATED (integer eventCode, integer guildId)
		
	uespLog.lastPlayerHP = GetUnitPower("player", POWERTYPE_HEALTH)
	uespLog.lastPlayerMG = GetUnitPower("player", POWERTYPE_MAGICKA)
	uespLog.lastPlayerST = GetUnitPower("player", POWERTYPE_STAMINA)
	uespLog.lastPlayerUT = GetUnitPower("player", POWERTYPE_ULTIMATE)
	 	
	uespLog.fillInfoData()
	uespLog.Msg("Initialized uespLog...")
	
	--uespLog.Old_OnAddGameData = ZO_ItemIconTooltip_OnAddGameData
	--ZO_ItemIconTooltip_OnAddGameData = uespLog.new_OnAddGameData
	
	--uespLog.Old_ItemOnAddGameData = ZO_ItemIconTooltip_ItemOnAddGameData
	--ZO_ItemIconTooltip_ItemOnAddGameData = uespLog.new_ItemOnAddGameData
	
    PopupTooltip:SetHandler("OnMouseUp", uespLog.OnTooltipMouseUp)
    --self.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", uespLog.OnTooltipMouseUp)
	SMITHING.creationPanel.resultTooltip:SetHandler("OnMouseUp", uespLog.SmithingCreationOnTooltipMouseUp)
	SMITHING.improvementPanel.resultTooltip:SetHandler("OnMouseUp", uespLog.SmithingImprovementOnTooltipMouseUp)
	ALCHEMY.tooltip:SetHandler("OnMouseUp", uespLog.AlchemyOnTooltipMouseUp)
	ALCHEMY.tooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
	ENCHANTING.resultTooltip:SetHandler("OnMouseUp", uespLog.EnchantingOnTooltipMouseUp)
	ENCHANTING.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", OnTooltipMouseUp)
	
	uespLog.Old_NotifyDeleteMailAdded = MAIL_INBOX.Delete
	MAIL_INBOX.Delete = uespLog.NotifyDeleteMailAdded 
	MAIL_INBOX:RefreshData()
	
	zo_callLater(uespLog.InitTradeData, 500) 
	zo_callLater(uespLog.outputInitMessage, 4000)
end

	--	Hook initialization onto the ADD_ON_LOADED event  
EVENT_MANAGER:RegisterForEvent("uespLog" , EVENT_ADD_ON_LOADED, uespLog.Initialize)


function uespLog.InitAutoMining ()

	if (uespLog.isAutoMiningItems and uespLog.mineItemAutoRestart) then
		
		uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Auto-resetting current log data...")
		uespLog.ClearSavedVarSection("all")
		
		if (uespLog.mineItemsAutoNextItemId > uespLog.MINEITEM_AUTO_MAXITEMID) then
			uespLog.isAutoMiningItems = false
			uespLog.savedVars.settings.data.isAutoMiningItems = false
			uespLog.mineItemAutoReload = false
			uespLog.savedVars.settings.data.mineItemAutoReload = false
			uespLog.mineItemAutoRestart = false
			uespLog.savedVars.settings.data.mineItemAutoRestart = false
			uespLog.MsgColor(uespLog.mineColor, "UESP::Stopped auto-mining due to reach max ID of "..tostring(uespLog.mineItemsAutoNextItemId))
		else
			uespLog.MsgColor(uespLog.mineColor, "UESP::Auto-restarting item mining at ID "..tostring(uespLog.mineItemsAutoNextItemId).." in 10 secs...")
			zo_callLater(uespLog.MineItemsAutoLoop, 10000)
			uespLog.MineItemsOutputStartLog()
			uespLog.mineItemAutoRestartOutputEnd = false
		end
	end
	
end


function uespLog.outputInitMessage ()
	local flagStr = uespLog.BoolToOnOff(uespLog.IsDebug())
	if (uespLog.IsDebugExtra()) then flagStr = "EXTRA" end
	uespLog.Msg("uespLog v"..uespLog.version.." add-on initialized...debug output is currently "..tostring(flagStr)..".")
end


function uespLog.EnchantingOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetEnchantingResultingItemLink, ENCHANTING:GetAllCraftingBagAndSlots())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(ENCHANTING)
		end
	end
end


function uespLog.AlchemyOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetAlchemyResultingItemLink, ALCHEMY:GetAllCraftingBagAndSlots())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(ALCHEMY)
		end
	end
end


function uespLog.SmithingCreationOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local link = ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink, SMITHING.creationPanel:GetAllCraftingParameters())
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(SMITHING)
		end
	end
end


function uespLog.SmithingImprovementOnTooltipMouseUp(control, button, upInside)
	if upInside and button == 2 then
		local itemToImproveBagId, itemToImproveSlotIndex, craftingType = SMITHING.improvementPanel:GetCurrentImprovementParams()
		local link = GetSmithingImprovedItemLink(itemToImproveBagId, itemToImproveSlotIndex, craftingType, LINK_STYLE_BRACKETS)
		
		if link ~= "" then
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(SMITHING)
		end
	end
end


function uespLog.OnInventoryShowItemInfo (inventorySlot, slotActions)
	local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
	local itemLink = GetItemLink(bag, index, LINK_STYLE_DEFAULT)
	uespLog.ShowItemInfo(itemLink)
end


function uespLog.ZO_InventorySlot_DoPrimaryAction (inventorySlot)
    inventorySlot = GetInventorySlotComponents(inventorySlot)
    PerClickInitializeActions(inventorySlot, PREVENT_CONTEXT_MENU)
    g_slotActions:DoPrimaryAction()
end


function uespLog.New_InventorySlot_ShowContextMenu (inventorySlot)
	PerClickInitializeActions(inventorySlot, USE_CONTEXT_MENU)
    g_slotActions:Show()
	--g_slotActions:AddSlotAction("Show Item Info", uespLog.OnInventoryShowItemInfo, "primary")
	--uespLog.Old_InventorySlot_ShowContextMenu(inventorySlot)
end


function uespLog.OnTooltipMouseUp (control, button, upInside)
	--uespLog.DebugMsg("UESP::OnTooltipMouseUp")

	if upInside and button == 2 then
		--uespLog.DebugMsg("UESP::OnTooltipMouseUp")
		local link = PopupTooltip.lastLink
		
		if link ~= "" then
			--uespLog.DebugMsg("UESP::OnTooltipMouseUp")
			ClearMenu()

			local function AddLink()
				ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
			end
			
			local function GetInfo()
				uespLog.ShowItemInfo(link)
			end

			AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), AddLink)
			AddMenuItem("Show Item Info", GetInfo)
				
			ShowMenu(PopupTooltip)
		end
	end
	
end


function uespLog.FindDataIndexFromHorizontalList (scrollListControl, rootList, dataName, defaultIndex)
	local selIndex = nil
	local control

	for i, control in ipairs(rootList.controls) do
		if scrollListControl == control then
			selIndex = 1 - ((rootList.selectedIndex or 0) - (i - rootList.halfNumVisibleEntries - 1))
			--uespLog.DebugMsg("Found index at "..tostring(i)..", "..tostring(rootList.selectedIndex)..", "..tostring(selIndex)..", default="..tostring(defaultIndex))
			--uespLog.DebugMsg("Control data = "..tostring(control[dataName]))
		
			if (dataName ~= nil and control[dataName] ~= nil) then
				return control[dataName]
			end
			
			return selIndex
		end
	end
	
	return defaultIndex
end


function uespLog.ShowItemInfoRowControl (rowControl)
	local dataEntry = rowControl.dataEntry
	local bagId, slotIndex 
	local itemLink = nil
	local storeMode = uespLog.GetStoreMode()
	--SI_STORE_MODE_REPAIR SI_STORE_MODE_BUY_BACK SI_STORE_MODE_BUY  SI_STORE_MODE_SELL
	
	--uespLog.DebugMsg("uespLog.ShowItemInfoRowControl() "..tostring(rowControl:GetName()))

	if (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.slotIndex ~= nil) then
		slotIndex = dataEntry.data.slotIndex
		bagId = dataEntry.data.bagId
	
		if (storeMode == SI_STORE_MODE_BUY_BACK) then
			itemLink = GetBuybackItemLink(slotIndex, LINK_STYLE_DEFAULT)	
		elseif (storeMode == SI_STORE_MODE_BUY) then
			itemLink = GetStoreItemLink(slotIndex, LINK_STYLE_DEFAULT)	
		elseif (bagId == nil) then
			itemLink = GetTradingHouseSearchResultItemLink(slotIndex)
		else
			itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
		end
		
	elseif (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.bag ~= nil) then
		bagId = dataEntry.data.bag
		slotIndex = dataEntry.data.index 
		itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	elseif (rowControl.bagId ~= nil and rowControl.itemIndex ~= nil) then
		bagId = rowControl.bagId
		slotIndex = rowControl.itemIndex
		itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	elseif (rowControl.bagId ~= nil and rowControl.slotIndex ~= nil) then
		bagId = rowControl.bagId
		slotIndex = rowControl.slotIndex
		itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	elseif (dataEntry ~= nil and dataEntry.data ~= nil and dataEntry.data.lootId ~= nil) then
		slotIndex = dataEntry.data.lootId
		itemLink = GetLootItemLink(slotIndex, LINK_STYLE_DEFAULT)
	elseif (rowControl.slotIndex ~= nil) then
		slotIndex = rowControl.slotIndex
		itemLink = GetLootItemLink(slotIndex, LINK_STYLE_DEFAULT)
	else
		local parents = { }
		local parentNames = {} 
		local i
		
		parents[0] = rowControl
		
		for i = 1, 6 do
			if (parents[i-1] == nil) then
				parents[i] = nil
			else
				parents[i] = parents[i-1]:GetParent()
			end
		end
		
		for i = 0, 6 do
			if (parents[i] == nil) then
				parentNames[i] = ""
			else
				parentNames[i] = parents[i]:GetName()
			end
		end
		
		if (parentNames[3] == "ZO_SmithingTopLevelCreationPanelPatternList") then
			local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()
			patternIndex = uespLog.FindDataIndexFromHorizontalList(rowControl, SMITHING.creationPanel.patternList, nil, patternIndex)
			itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex)
		elseif (parentNames[3] == "ZO_SmithingTopLevelCreationPanelMaterialList") then
			local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()			
			materialIndex = uespLog.FindDataIndexFromHorizontalList(rowControl, SMITHING.creationPanel.materialList, "materialIndex", materialIndex)
			itemLink = GetSmithingPatternMaterialItemLink(patternIndex, materialIndex)
		elseif (parentNames[3] == "ZO_SmithingTopLevelCreationPanelStyleList") then
			local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()			
			styleIndex = uespLog.FindDataIndexFromHorizontalList(rowControl, SMITHING.creationPanel.styleList, "styleIndex", styleIndex)
			itemLink = GetSmithingStyleItemLink(styleIndex)
		elseif (parentNames[3] == "ZO_SmithingTopLevelCreationPanelTraitList") then
			local patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex = SMITHING.creationPanel:GetAllCraftingParameters()			
			traitIndex = uespLog.FindDataIndexFromHorizontalList(rowControl, SMITHING.creationPanel.traitList, "traitIndex", traitIndex)
			itemLink = GetSmithingTraitItemLink(traitIndex)
		elseif (parentNames[0] == "ZO_SmithingTopLevelImprovementPanelSlotContainerBoosterSlot") then
			local itemToImproveBagId, itemToImproveSlotIndex, craftingType = SMITHING.improvementPanel:GetCurrentImprovementParams()
			itemLink = GetSmithingImprovementItemLink(craftingType, SMITHING.improvementPanel:GetBoosterRowForQuality(SMITHING.improvementPanel.currentQuality).index)
		elseif (parentNames[0] == "ZO_SmithingTopLevelImprovementPanelSlotContainerImprovementSlot") then
			local itemToImproveBagId, itemToImproveSlotIndex, craftingType = SMITHING.improvementPanel:GetCurrentImprovementParams()
			itemLink = GetItemLink(itemToImproveBagId, itemToImproveSlotIndex)
		elseif (parentNames[1] == "ZO_SmithingTopLevelRefinementPanel") then
			if (SMITHING.refinementPanel.extractionSlot.bagId == nil) then
				return
			end
			itemLink = GetItemLink(SMITHING.refinementPanel.extractionSlot.bagId, SMITHING.refinementPanel.extractionSlot.slotIndex)
		elseif (parentNames[1] == "ZO_SmithingTopLevelDeconstructionPanel") then
			if (SMITHING.deconstructionPanel.extractionSlot.bagId == nil) then
				return
			end
			itemLink = GetItemLink(SMITHING.deconstructionPanel.extractionSlot.bagId, SMITHING.deconstructionPanel.extractionSlot.slotIndex)
		end				
		
		--uespLog.DebugMsg("UESP::rowControl parent[a] = "..tostring(rowControl.patternIndex))
		--uespLog.DebugMsg("UESP::rowControl parent[b] = "..tostring(rowControl.materialIndex))
		--uespLog.DebugMsg("UESP::rowControl parent[c] = "..tostring(rowControl.styleIndex))
		--uespLog.DebugMsg("UESP::rowControl parent[d] = "..tostring(rowControl.traitIndex))
		--uespLog.DebugMsg("UESP::rowControl parent[0] = "..tostring(parentNames[0]))
		--uespLog.DebugMsg("UESP::rowControl parent[1] = "..tostring(parentNames[1]))
		--uespLog.DebugMsg("UESP::rowControl parent[2] = "..tostring(parentNames[2]))
		--uespLog.DebugMsg("UESP::rowControl statValue = "..tostring(rowControl.dataEntry.data.statValue))
		--uespLog.DebugMsg("UESP::rowControl slotIndex = "..tostring(rowControl.dataEntry.data.slotIndex))
		--uespLog.DebugMsg("UESP::ShowItemInfoRowControl no slot info found!")
		--return
	end

	if (itemLink == nil) then
		uespLog.DebugExtraMsg("UESP::ShowItemInfoRowControl -- No itemLink found!")
		return
	end
	
	uespLog.ShowItemInfo(itemLink)
end


function uespLog.GetWeaponTypeStr(weaponType)
	return GetString(SI_WEAPONTYPE0 + weaponType) or "Unknown"
end


function uespLog.GetArmorTypeStr(armorType)
	return GetString(SI_ARMORTYPE0 + armorType) or "Unknown"
end


function uespLog.GetItemTypeStr(itemType)
	 return GetString(SI_ITEMTYPE0 + itemType) or "Unknown"
end


function uespLog.ShowItemInfo (itemLink)
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
	local styleStr = uespLog.GetItemStyleStr(itemStyle)
	local equipTypeStr = uespLog.GetItemEquipTypeStr(equipType)
	local weaponType = GetItemLinkWeaponType(itemLink)
	local armorType = GetItemLinkArmorType(itemLink)
	
	itemName = GetItemLinkName(itemLink)
	
	local itemType = GetItemLinkItemType(itemLink)
	local weaponPower = GetItemLinkWeaponPower(itemLink)
	local armorRating = GetItemLinkArmorRating(itemLink, false)
	local reqLevel = GetItemLinkRequiredLevel(itemLink)
	local reqVetLevel = GetItemLinkRequiredVeteranRank(itemLink)
	local value = GetItemLinkValue(itemLink, false)
	local condition = GetItemLinkCondition(itemLink)
	local hasArmorDecay = DoesItemLinkHaveArmorDecay(itemLink)
	local maxCharges = GetItemLinkMaxEnchantCharges(itemLink)
	local numCharges = GetItemLinkNumEnchantCharges(itemLink)
	local hasCharges = DoesItemLinkHaveEnchantCharges(itemLink)
	local hasEnchant, enchantHeader, enchantDesc = GetItemLinkEnchantInfo(itemLink)
	local hasUseAbility, useAbilityHeader, useAbilityDesc, useAbilityCooldown = GetItemLinkOnUseAbilityInfo(itemLink)
	local trait, traitText = GetItemLinkTraitInfo(itemLink)
	local isSetItem, setName, numSetBonuses, numSetEquipped, maxSetEquipped = GetItemLinkSetInfo(itemLink)
	--local setBonusRequired, setBonusDesc = GetItemLinkSetBonusInfo(itemLink)
	local flavourText = GetItemLinkFlavorText(itemLink)
	local isCrafted = IsItemLinkCrafted(itemLink)
	local isVendorTrash = IsItemLinkVendorTrash(itemLink)
	local maxSiegeHP = GetItemLinkSiegeMaxHP(itemLink)
	local siegeType = GetItemLinkSiegeType(itemLink)
	local quality = GetItemLinkQuality(itemLink)
	local isUnique = IsItemLinkUnique(itemLink)
	local isUniqueEquipped = IsItemLinkUniqueEquipped(itemLink)
	local equipType1 = GetItemLinkEquipType(itemLink)
	local isConsumable = IsItemLinkConsumable(itemLink)
	local craftSkill = GetItemLinkCraftingSkillType(itemLink)
	local isRune = IsItemLinkEnchantingRune(itemLink)
	local runeType = GetItemLinkEnchantingRuneClassification(itemLink)
	local runeRank = GetItemLinkRequiredCraftingSkillRank(itemLink)		
	local isBound = IsItemLinkBound(itemLink)
	local bindType = GetItemLinkBindType(itemLink)
	local glyphMinLevel, glyphMaxLevel, glyphMinVetLevel, glyphMaxVetLevel = GetItemLinkGlyphMinMaxLevels(itemLink)
	local bookTitle = GetItemLinkBookTitle(itemLink)
	local isBookKnown = IsItemLinkBookKnown(itemLink)
	local craftSkillRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
	local recipeRank = GetItemLinkRecipeRankRequirement(itemLink)
	local recipeQuality = GetItemLinkRecipeQualityRequirement(itemLink)
	local resultItemLink = GetItemLinkRecipeResultItemLink(itemLink)
	local refinedItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)
	local materialLevelDescription = GetItemLinkMaterialLevelDescription(itemLink)
	
	local flagString = ""
	local levelString = ""
	local glyphLevelString = ""
	
	if (hasEnchant) then flagString = flagString.."Enchant  " end
	if (isSetItem) then flagString = flagString.."Set  " end
	if (isCrafted) then flagString = flagString.."Crafted  " end
	if (isVendorTrash) then flagString = flagString.."Vendor  " end
	if (hasArmorDecay) then flagString = flagString.."ArmorDecay  " end
	if (isUnique) then flagString = flagString.."Unique  " end
	if (isUniqueEquipped) then flagString = flagString.."UniqueEquip  " end
	if (isConsumable) then flagString = flagString.."Consumable  " end
	if (isBound) then flagString = flagString.."Bound  " end
	if (siegeType > 0) then flagString = flagString.."Siege  " end
	if (hasUseAbility) then flagString = flagString.."UseAbility  " end
	
	uespLog.MsgColor(uespLog.itemColor, "UESP::Information for "..tostring(itemNiceLink))
	uespLog.MsgColor(uespLog.itemColor, ".    Data: "..tostring(itemData))
	uespLog.MsgColor(uespLog.itemColor, ".    Type: ".. uespLog.GetItemTypeStr(itemType) .." ("..tostring(itemType)..")      Equip: "..equipTypeStr.." ("..tostring(equipType)..")")
	
	if (glyphMinLevel ~= nil and glyphMaxLevel ~= nil) then
		glyphLevelString = tostring(glyphMinLevel).." to "..tostring(glyphMaxLevel)
	elseif (glyphMinVetLevel ~= nil and glyphMaxVetLevel ~= nil) then
		glyphLevelString = "V"..tostring(glyphMinVetLevel).." to V"..tostring(glyphMaxVetLevel)
	elseif (glyphMinLevel ~= nil and glyphMaxVetLevel ~= nil) then
		glyphLevelString = tostring(glyphMinLevel).." to V"..tostring(glyphMaxVetLevel)
	end
	
	if (weaponType > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".     Weapon: "..uespLog.GetWeaponTypeStr(weaponType).." ("..tostring(weaponType)..")     Power: "..tostring(weaponPower).."    Glyphs: "..glyphLevelString)
	elseif (armorType > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".     Armor: "..uespLog.GetArmorTypeStr(armorType).." ("..tostring(armorType)..")     Rating: "..tostring(armorRating).."    Glyphs: "..glyphLevelString)
	elseif (glyphLevelString ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".     Glyphs: "..glyphLevelString)
	end
		
	if (flagString ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".    Flags: "..flagString)
	end
	
	if (reqVetLevel ~= nil and reqVetLevel > 0) then
		levelString = "V"..tostring(reqVetLevel)
	elseif (reqLevel ~= nil) then
		levelString = tostring(reqLevel)
	end
	
	if (traitText ~= "") then
		traitText = ", " .. tostring(traitText)
	end
	
	uespLog.MsgColor(uespLog.itemColor, ".    Level: "..levelString.."     Value: "..tostring(value).."     Condition: "..tostring(condition).."     Quality: "..tostring(quality))
	uespLog.MsgColor(uespLog.itemColor, ".    Style: "..styleStr.." ("..tostring(itemStyle)..")     Trait: "..uespLog.GetItemTraitName(trait).." ("..tostring(trait)..") "..tostring(traitText))
	uespLog.MsgColor(uespLog.itemColor, ".    Icon: "..tostring(icon))
	
	if (hasCharges) then
		uespLog.MsgColor(uespLog.itemColor, ".    Charges: "..tostring(numCharges).." / "..tostring(maxCharges))
	end
		
	if (hasEnchant) then
		uespLog.MsgColor(uespLog.itemColor, ".    Enchant: "..tostring(enchantHeader).." -- "..tostring(enchantDesc))
	end
	
	if (hasUseAbility) then
		uespLog.MsgColor(uespLog.itemColor, ".    UseAbility: "..tostring(useAbilityHeader).." -- "..tostring(useAbilityDesc).."     Cooldown: "..tostring(useAbilityCooldown/1000).." sec")
	end
	
	local traitAbilityCount = 0
	
	for i = 1, GetMaxTraits() do
		local hasTraitAbility, traitAbilityDescription, traitCooldown = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
		
		if (hasTraitAbility) then
			traitAbilityCount = traitAbilityCount + 1
			uespLog.MsgColor(uespLog.itemColor, ".    TraitAbility" .. tostring(traitAbilityCount) .. ": "..tostring(traitAbilityDescription).."   Cooldown: "..tostring(traitCooldown/1000).." sec")
		end
	end
	
	if (isSetItem) then
		uespLog.MsgColor(uespLog.itemColor, ".    Set: "..tostring(setName).."   Bonuses: "..tostring(numSetBonuses).." ("..tostring(numSetEquipped).." / "..tostring(maxSetEquipped).." equipped)")
		local i
		
		for i = 1, numSetBonuses do
			local setBonusRequired, setBonusDesc = GetItemLinkSetBonusInfo(itemLink, NOT_EQUIPPED, i)
			uespLog.MsgColor(uespLog.itemColor, ".       "..tostring(setBonusRequired)..": "..tostring(setBonusDesc))
		end
	end
	
	if (craftSkill ~= nil and craftSkill > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".    Craft: "..tostring(craftSkill).."   Rank: "..tostring(craftSkillRank))
	end
	
	if (recipeQuality ~= nil and recipeQuality > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".    Recipe Rank: "..tostring(recipeRank).."   Quality: "..tostring(recipeQuality))
	end
	
	if (resultItemLink ~= nil and resultItemLink ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".    Recipe Result: "..tostring(resultItemLink))
	end

	if (refinedItemLink ~= nil and refinedItemLink ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".    Refined Item: "..tostring(refinedItemLink))
	end
	
	local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
	
	if (numIngredients ~= nil) then
		for i = 1, numIngredients do
			local ingredientName, numOwned = GetItemLinkRecipeIngredientInfo(itemLink, i)
			uespLog.MsgColor(uespLog.itemColor, ".    Ingredient "..tostring(i)..":  "..tostring(ingredientName))
		end
	end
		
	if (runeType ~= nil and runeType > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".    Rune: "..tostring(runeType).."   Rank: "..tostring(runeRank))
	end
	
	if (bindType ~= nil and bindType > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".    Bind: "..tostring(bindType))
	end
	
	if (bookTitle ~= nil or itemType == 8) then
		uespLog.MsgColor(uespLog.itemColor, ".    Book: "..tostring(bookTitle).."    Known: "..tostring(isBookKnown))
	end
	
	if (siegeType ~= nil and siegeType > 0 and maxSiegeHP > 0) then
		uespLog.MsgColor(uespLog.itemColor, ".    SiegeType: "..tostring(siegeType).."   SiegeHP: "..tostring(maxSiegeHP))
	end
	
	if (materialLevelDescription ~= nil and materialLevelDescription ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".    Material Level: "..tostring(materialLevelDescription))
	end
		
	if (flavourText ~= "") then
		uespLog.MsgColor(uespLog.itemColor, ".    Description: "..tostring(flavourText))
	end
	
end


function uespLog.new_ItemOnAddGameData (tooltipControl, gameDataType, ...)
	local data = {...}
	
	uespLog.DebugMsg("UESP::gameItemDataType = "..tostring(gameDataType))
	--uespLog.DebugMsg("UESP::Length Data = "..tostring(#data))
	
	for i = 1, #data do
		uespLog.DebugMsg(".  "..tostring(i)..") "..tostring(data[i]))
	end
	
	uespLog.Old_ItemOnAddGameData(tooltipControl, gameDataType, unpack(data))
end


function uespLog.new_OnAddGameData (tooltipControl, gameDataType, ...)
	local data = {...}
	
	uespLog.DebugMsg("UESP::gameDataType = "..tostring(gameDataType))
	--uespLog.DebugMsg("UESP::Length Data = "..tostring(#data))
	
	for i = 1, #data do
		uespLog.DebugMsg(".  "..tostring(i)..") "..tostring(data[i]))
	end
	
	uespLog.Old_OnAddGameData(tooltipControl, gameDataType, unpack(data))
end


function uespLog.fillInfoData ()
	local data = uespLog.savedVars["info"].data
	
	data["uespLogVersion"] = uespLog.version
	data["apiVersion"] = GetAPIVersion() 
	data["version"] = _VERSION
	data["language"] = GetCVar("language.2")
	
	local charName = GetUnitName("player")
	local serverCharName = GetUniqueNameForCharacter(charName)
	data["accountName"] = GetDisplayName()
	data["serverCharName"] = serverCharName
	data["characterName"] = charName
	
	data["startGameTime"] = uespLog.startGameTime
	data["startTimeStamp"] = uespLog.startTimeStamp
	data["startTimeStampStr"] = GetDateStringFromTimestamp(uespLog.startTimeStamp)
end


function uespLog.HandleChatterOptionClicked (self, label)
	--uespLog.DebugExtraMsg("UESP::HandleChatterOptionClicked")
	--uespLog.DebugExtraMsg("Index:"..tostring(label.optionIndex))
	--uespLog.DebugExtraMsg("Text:"..tostring(label:GetText()))
	--uespLog.DebugExtraMsg("Type:"..tostring(label.optionType))
	
	uespLog.lastConversationOption.Text = label:GetText()
	uespLog.lastConversationOption.Type = label.optionType
	uespLog.lastConversationOption.Gold = label.gold
	uespLog.lastConversationOption.Index = label.optionIndex
	uespLog.lastConversationOption.Important = label.isImportant
		--label.chosenBefore
		
	uespLog.Old_HandleChatterOptionClicked(self, label)
end


function uespLog.OnQuestOffered (eventCode)
    local dialog, response = GetOfferedQuestInfo()
    local _, farewell = GetChatterFarewell()
	local logData = { }
	
	if (farewell == "") then farewell = GetString(SI_GOODBYE) end
	
	logData.event = "QuestOffered"
	logData.farewell = farewell
	logData.dialog = dialog
	logData.response = response
	logData.optionText = uespLog.lastConversationOption.Text
	logData.optionType = uespLog.lastConversationOption.Type
	logData.optionGold = uespLog.lastConversationOption.Gold
	logData.optionIndex = uespLog.lastConversationOption.Index
	logData.optionImp = uespLog.lastConversationOption.Important
	
	uespLog.AppendDataToLog("all", logData, uespLog.currentConversationData, uespLog.GetTimeData())
	
	uespLog.DebugMsg("UESP::Updated Conversation (QuestOffered)...")
	--uespLog.DebugExtraMsg("UESP::dialog = "..tostring(dialog))
	--uespLog.DebugExtraMsg("UESP::response = "..tostring(response))
	--uespLog.DebugExtraMsg("UESP::farewell = "..tostring(farewell))	
end


function uespLog.OnConversationUpdated (eventCode, conversationBodyText, conversationOptionCount)

	local logData = { }
	
	uespLog.DebugMsg("UESP::Updated conversation START...")

	logData.event = "ConversationUpdated"
	logData.bodyText = conversationBodyText
	logData.optionCount = conversationOptionCount
	
	uespLog.AppendDataToLog("all", logData, uespLog.currentConversationData, uespLog.GetTimeData())
	
	for i = 1, conversationOptionCount do
		logData = { }
		
		logData.event = "ConversationUpdated::Option"
		logData.option, logData.type, logData.optArg, logData.isImportant, logData.chosenBefore = GetChatterOption(i)
		
		uespLog.AppendDataToLog("all", logData)
	end
	
	uespLog.DebugMsg("UESP::Updated conversation...")
	
	uespLog.lastConversationOption.Text = ""
	uespLog.lastConversationOption.Type = ""
	uespLog.lastConversationOption.Gold = ""
	uespLog.lastConversationOption.Index = ""
	uespLog.lastConversationOption.Important = ""
	
end


function uespLog.OnChatterEnd (eventCode)
	uespLog.currentConversationData.npcName = ""
    uespLog.currentConversationData.npcLevel = ""
    uespLog.currentConversationData.x = ""
    uespLog.currentConversationData.y = ""
    uespLog.currentConversationData.zone = ""
	
	uespLog.lastConversationOption.Text = ""
	uespLog.lastConversationOption.Type = ""
	uespLog.lastConversationOption.Gold = ""
	uespLog.lastConversationOption.Index = ""
	uespLog.lastConversationOption.Important = ""
end


function uespLog.OnChatterBegin (eventCode, optionCount)
	local x, y, heading, zone = uespLog.GetUnitPosition("interact")
    local npcLevel = GetUnitLevel("interact")
	local npcName = GetUnitName("interact")
	local logData = { }
	local ChatterGreeting = GetChatterGreeting()
	
	uespLog.lastConversationOption.Text = ""
	uespLog.lastConversationOption.Type = ""
	uespLog.lastConversationOption.Gold = ""
	uespLog.lastConversationOption.Index = ""
	uespLog.lastConversationOption.Important = ""
		
	if (x == nil) then
		x, y, heading, zone = uespLog.GetPlayerPosition()
	end
	
	if (npcLevel == nil) then
		npcLevel = ""
	end
	
    uespLog.currentConversationData.npcName = npcName
    uespLog.currentConversationData.npcLevel = npcLevel
    uespLog.currentConversationData.x = x
    uespLog.currentConversationData.y = y
    uespLog.currentConversationData.zone = zone
		
	logData.event = "ChatterBegin"
	logData.bodyText = ChatterGreeting
	logData.optionCount = optionCount
	-- logData.chatText, logData.numOptions, logData.atGreeting = GetChatterData()   -- Still has issue with facial animations
		
	uespLog.AppendDataToLog("all", logData, uespLog.currentConversationData, uespLog.GetTimeData())
	
	for i = 1, optionCount do
		logData = { }
		
		logData.event = "ChatterBegin::Option"
		logData.option, logData.type, logData.optArg, logData.isImportant, logData.chosenBefore = GetChatterOption(i)
		
		uespLog.AppendDataToLog("all", logData)
	end
	
	uespLog.DebugExtraMsg("UESP::Chatter begin...")
	
		-- Manually call the original function to update the chat window
	INTERACTION:InitializeInteractWindow(ChatterGreeting)
	INTERACTION.optionCount, INTERACTION.importantOptions = INTERACTION:PopulateChatterOptions(optionCount, false)
end


function uespLog.OnBeginLockPick (eventCode)
	local logData = { }
	
	logData.event = "LockPick"
	logData.quality = GetLockQuality()
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Lock of quality "..tostring(logData.quality))
end


function uespLog.OnShowBook (eventCode, bookTitle, body, medium, showTitle)
	local logData = { }
	
	logData.event = "ShowBook"
	logData.bookTitle = bookTitle
	logData.body = body
	logData.medium = medium
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Book "..bookTitle)
end


function uespLog.OnLoreBookAlreadyKnown (eventCode, bookTitle)
	local logData = { }
	
	logData.event = "LoreBook"
	logData.bookTitle = bookTitle
	logData.known = true
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Lore book "..bookTitle.." (already known)")
end


function uespLog.OnLoreBookLearned (eventCode, categoryIndex, collectionIndex, bookIndex, guildIndex)
	local logData = { }
    local bookTitle, icon, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
	
	logData.event = "LoreBook"
	logData.bookTitle = bookTitle	
	logData.icon = icon
	logData.category = categoryIndex
	logData.collection = collectionIndex
	logData.index = bookIndex
	logData.guild = guildIndex
	logData.known = known
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
		 
	uespLog.DebugLogMsg("Lore book "..bookTitle.." (guild "..tostring(guildIndex)..")")
end


function uespLog.OnSkillRankUpdate (eventCode, skillType, skillIndex, rank)
	local logData = { }
	local name, rank1 = GetSkillLineInfo(skillType, skillIndex)

	logData.event = "SkillRankUpdate"
	logData.skillType = skillType	
	logData.skillIndex = skillIndex
	logData.rank = rank
	logData.name = name
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
		 
	uespLog.DebugLogMsg("Skill rank update for "..name)
end


function uespLog.OnBuyReceipt (eventCode, itemLink, entryType, entryQuantity, money, specialCurrencyType1, specialCurrencyInfo1, specialCurrencyQuantity1, specialCurrencyType2, specialCurrencyInfo2, specialCurrencyQuantity2, itemSoundCategory)
	local logData = { }
	local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
	logData.event = "Buy"
	logData.itemLink = itemLink
	logData.entryType = entryType
	logData.value = money
	logData.qnt = entryQuantity
	logData.sound = itemSoundCategory
	
	if (specialCurrencyQuantity1 > 0) then 
		logData.currency1 = specialCurrencyInfo1
		logData.currencyQnt1 = specialCurrencyQuantity1
	end
	
	if (specialCurrencyQuantity2 > 0) then 
		logData.currency2 = specialCurrencyInfo2
		logData.currencyQnt2 = specialCurrencyQuantity2
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.itemColor, "Bought "..niceLink.." for "..tostring(money).."gp")
end


function uespLog.OnSellReceipt (eventCode, itemLink, itemQuantity, money)
	local logData = { }
	local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
	logData.event = "Sell"
	logData.itemLink = itemLink
	logData.qnt = itemQuantity
	logData.value = money

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.itemColor, "Sold "..niceLink.." for "..tostring(money).."gp")
end


function uespLog.OnQuestAdded (eventCode, journalIndex, questName, objectiveName)
	local logData = { }
	
	logData.event = "QuestAdded"
	logData.quest = questName
	logData.objective = objectiveName
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Quest added "..questName.."::"..objectiveName)
end


function uespLog.OnQuestRemoved (eventCode, isCompleted, questIndex, questName, zoneIndex, poiIndex)
	local logData = { }
	
	logData.event = "QuestRemoved"
	logData.quest = questName
	logData.completed = isCompleted
	logData.zoneIndex = zoneIndex
	logData.poiIndex = poiIndex
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())

	uespLog.DebugLogMsg("Quest removed "..questName)
end


function uespLog.OnQuestObjectiveCompleted (eventCode, zoneIndex, poiIndex, xpGained)
	local logData = { }
	
	logData.event = "QuestObjComplete"
	logData.xpGained = xpGained
	logData.zoneIndex = zoneIndex
	logData.poiIndex = poiIndex
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("Objective completed")
end


function uespLog.OnQuestCounterChanged (eventCode, journalIndex, questName, conditionText, conditionType, currConditionVal, newConditionVal, conditionMax, isFailCondition, stepOverrideText, isPushed, isComplete, isConditionComplete, isStepHidden)
	local logData = { }
	
	logData.event = "QuestChanged"
	logData.quest = questName
	logData.condition = conditionText
	logData.condType = conditionType
	logData.condVal = newConditionVal
	logData.condMaxVal = conditionMax
	logData.isFail = isFailCondition
	logData.isPushed = isPushed
	logData.isComplete = isComplete
	logData.isCondComplete = isConditionComplete
	logData.isHidden = isStepHidden
	if (stepOverrideText ~= "") then logData.overrideText = stepOverrideText end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
 
	uespLog.DebugLogMsg("Change in quest "..questName.."::"..conditionText)
end


function uespLog.OnQuestCompleteExperience (eventCode, questName, xpGained)
	local logData = { }
	
	logData.event = "QuestCompleteExperience"
	logData.quest = questName
	logData.xpGained = xpGained
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Finished "..questName)
end


uespLog.EQUIPTYPES = {
	[0]  = "Invalid",
	[1]  = "Head",
	[2]  = "Neck",
	[3]  = "Chest",
	[4]  = "Shoulders",
	[5]  = "One Hand",
	[6]  = "Two Hand",
	[7]  = "Off Hand",
	[8]  = "Waist",
	[9]  = "Legs",
	[10] = "Feet",
	[11] = "Costume",
	[12] = "Ring",
	[13] = "Hand",
	[14] = "Main Hand",
}


function uespLog.GetItemEquipTypeStr(equipType)
	if (uespLog.EQUIPTYPES[equipType] ~= nil) then
		return uespLog.EQUIPTYPES[equipType]
	end
	
	return "Unknown ("..tostring(equipType)..")"
end



uespLog.ITEMSTYLES = {
	[0]  = "None",
	[1]  = "Breton",
	[2]  = "Redguard",
	[3]  = "Orc",
	[4]  = "Dunmer",
	[5]  = "Nord",
	[6]  = "Argonian",
	[7]  = "Altmer",
	[8]  = "Bosmer",
	[9]  = "Khajiit",
	[10] = "Unique",
	[11] = "Aldermi Dominion",
	[12] = "Ebonheart Pact",
	[13] = "Daggerfall Covenant",
	[14] = "Dwemer",
	[15] = "Ancient Elf",
	[16] = "Imperial (area)",
	[17] = "Reach (Barbaric)",
	[18] = "Bandit",
	[19] = "Primitive (Primal)",
	[20] = "Daedric",
	[21] = "Warrior",
	[22] = "Mage",
	[23] = "Rogue",
	[24] = "Summoner",
	[25] = "Marauder",
	[26] = "Healer",
	[27] = "Battlemage",
	[28] = "Nightblade",
	[29] = "Ranger",
	[30] = "Knight",
	[31] = "Draugr",
	[32] = "Maormer",
	[33] = "Akaviri",
	[34] = "Imperial (race)",
	[35] = "Yokudan",
	[36] = "Universal",
	[37] = "Reach Winter",
}


function uespLog.GetItemStyleStr(itemStyle)
	if (uespLog.ITEMSTYLES[itemStyle] ~= nil) then
		return uespLog.ITEMSTYLES[itemStyle]
	end
	
	return "Unknown ("..tostring(itemStyle)..")"
end

uespLog.old_XPREASONS = {
	[-1] = "none",
	[0] = "kill",
	[1] = "quest",
	[2] = "complete poi",
	[3] = "discover poi",
	[4] = "command",
	[5] = "keep reward",
	[6] = "battleground",
	[7] = "scripted event", 
	[8] = "medal",
	[9] = "finesse",
	[10] = "lockpick",
	[11] = "collect book",
	[12] = "skill book",
	[13] = "action",
	[14] = "guild rep",
	[15] = "AVA",
	[16] = "tradeskill",
	[17] = "reward",
	[18] = "tradeskill achievement",
	[19] = "tradeskill quest",
	[20] = "tradeskill consume", 
	[21] = "tradeskill harvest",
	[22] = "tradeskill recipe",
	[23] = "tradeskill trait",
	[24] = "boss kill",
}

uespLog.XPREASONS = {
	[-1] = "none",
	[PROGRESS_REASON_ACHIEVEMENT] = "achievement",
	[PROGRESS_REASON_ACTION] = "action",
	[PROGRESS_REASON_ALLIANCE_POINTS] = "alliance points",
	[PROGRESS_REASON_AVA] = "AVA",
	[PROGRESS_REASON_BATTLEGROUND] = "battleground",
	[PROGRESS_REASON_BOOK_COLLECTION_COMPLETE] = "book collection complete",
	[PROGRESS_REASON_BOSS_KILL] = "boss kill",
	[PROGRESS_REASON_COLLECT_BOOK] = "collect book",
	[PROGRESS_REASON_COMMAND] = "command",
	[PROGRESS_REASON_COMPLETE_POI] = "complete POI",
	[PROGRESS_REASON_DARK_ANCHOR_CLOSED] = "dark anchor closed",
	[PROGRESS_REASON_DARK_FISSURE_CLOSED] = "dark fissure closed",
	[PROGRESS_REASON_DISCOVER_POI] = "discover POI",
	[PROGRESS_REASON_DUNGEON_CHALLENGE] = "unknown challenge",
	[PROGRESS_REASON_EVENT] = "event",
	[PROGRESS_REASON_FINESSE] = "finesse",
	[PROGRESS_REASON_GRANT_REPUTATION] = "grant reputation",
	[PROGRESS_REASON_GUILD_REP] = "guild rep",
	[PROGRESS_REASON_JUSTICE_SKILL_EVENT] = "justice skill event",
	[PROGRESS_REASON_KEEP_REWARD] = "keep reward",
	[PROGRESS_REASON_KILL] = "kill",
	[PROGRESS_REASON_LOCK_PICK] = "lockpick",
	[PROGRESS_REASON_MEDAL] = "medal",
	--[PROGRESS_REASON_NONE] = "none",
	[PROGRESS_REASON_OTHER] = "other",
	[PROGRESS_REASON_OVERLAND_BOSS_KILL] = "boss kill",
	[PROGRESS_REASON_PVP_EMPEROR] = "PVP emperor",
	[PROGRESS_REASON_QUEST] = "quest",
	[PROGRESS_REASON_REWARD] = "reward",
	[PROGRESS_REASON_SCRIPTED_EVENT] = "scripted event",
	[PROGRESS_REASON_SKILL_BOOK] = "skill book",
	[PROGRESS_REASON_TRADESKILL] = "tradeskill",
	[PROGRESS_REASON_TRADESKILL_ACHIEVEMENT] = "tradeskill achievement",
	[PROGRESS_REASON_TRADESKILL_CONSUME] = "tradeskill consume",
	[PROGRESS_REASON_TRADESKILL_HARVEST] = "harvest",
	[PROGRESS_REASON_TRADESKILL_QUEST] = "tradeskill quest",
	[PROGRESS_REASON_TRADESKILL_RECIPE] = "recipe",
	[PROGRESS_REASON_TRADESKILL_TRAIT] = "tradeskill trait",
}

uespLog.old_VETERANXPREASONS = {
	[-1] = "none",
	[0] = "complete poi",
	[1] = "alliance points",
	[2] = "PVP emperor",
	[3] = "monster kill",
	[4] = "dungeon challenge A",
	[5] = "command",
	[6] = "dungeon challenge A",
	[7] = "dungeon challenge A",
	[8] = "dungeon challenge A",
	[9] = "dungeon challenge A",
	[10] = "quest low",
	[11] = "quest med",
	[12] = "quest high",
	[13] = "boss kill",
}

uespLog.VETERANXPREASONS = uespLog.XPREASONS


function uespLog.GetXPReasonStr(reason)
	if (uespLog.XPREASONS[reason] ~= nil) then
		return uespLog.XPREASONS[reason]
	end
	
	return "unknown ("..tostring(reason)..")"
end


function uespLog.GetVeteranXPReasonStr(reason)
	if (uespLog.VETERANXPREASONS[reason] ~= nil) then
		return uespLog.VETERANXPREASONS[reason]
	end
	
	return "unknown ("..tostring(reason)..")"
end


function uespLog.OnExperienceGain (eventCode, reason, level, previousExperience, currentExperience)
	local logData = { }
	
	logData.event = "ExperienceUpdate"
	logData.unit = "player"
	logData.xpGained = currentExperience - previousExperience
	logData.level = level
	logData.reason = reason
	
	uespLog.currentXp = currentExperience
	
	if (logData.xpGained == 0) then
		return
	elseif (reason == -1) then
		uespLog.DebugExtraMsg("UESP::Gained "..tostring(logData.xpGained).." xp for unknown reason")
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	if (GetUnitVeteranRank("player") <= 0) then
		uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." xp for "..uespLog.GetXPReasonStr(reason))
	end
end


function uespLog.OnExperienceUpdate (eventCode, unitTag, currentExp, maxExp, reason)
	local logData = { }
	
	 --if ( unitTag ~= 'player' ) then return end
	
	logData.event = "ExperienceUpdate"
	logData.unit = unitTag
	logData.xpGained = currentExp - uespLog.currentXp
	logData.maxXP = maxExp
	logData.reason = reason
	
	uespLog.currentXp = currentExp
	
	if (logData.xpGained == 0) then
		return
	elseif (reason == -1) then
		uespLog.DebugExtraMsg("UESP::Gained "..tostring(logData.xpGained).." xp for unknown reason")
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	if (unitTag == "player" and GetUnitVeteranRank(unitTag) <= 0) then
		uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." xp for "..uespLog.GetXPReasonStr(reason))
	end
end


function uespLog.OnVeteranPointsGain (eventCode, reason, rank, previousExperience, currentExperience)
	local logData = { }
	
	logData.event = "VeteranXPUpdate"
	logData.unit = "player"
	logData.xpGained = currentExperience - previousExperience
	logData.rank = rank
	logData.reason = reason
	
	uespLog.currentVeteranXp = currentExperience
	
	if (logData.xpGained == 0) then
		return
	elseif (reason == -1) then
		uespLog.DebugExtraMsg("UESP::Gained "..tostring(logData.xpGained).." veteran points for unknown reason")
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." veteran points for "..uespLog.GetVeteranXPReasonStr(reason))
end


function uespLog.OnVeteranPointsUpdate (eventCode, unitTag, currentExp, maxExp, reason)
	local logData = { }
	
	 --if ( unitTag ~= 'player' ) th6en return end
	
	logData.event = "VeteranXPUpdate"
	logData.unit = unitTag
	logData.xpGained = currentExp - uespLog.currentVeteranXp
	logData.maxXP = maxExp
	logData.reason = reason
	
	uespLog.currentVeteranXp = currentExp
	
	if (logData.xpGained == 0) then
		return
	elseif (reason == -1) then
		uespLog.DebugExtraMsg("UESP::Gained "..tostring(logData.xpGained).." veteran points for unknown reason")
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." veteran points for "..uespLog.GetVeteranXPReasonStr(reason))
end


function uespLog.OnAlliancePointsUpdate (eventCode, alliancePoints, playSound, difference)
	local logData = { }
	
	logData.event = "AllianceXPUpdate"
	logData.xpGained = difference
	logData.maxXP = alliancePoints
	
	if (logData.difference == 0) then
		return
	end
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsgColor(uespLog.xpColor, "Gained "..tostring(logData.xpGained).." alliance points.")
end


function uespLog.OnSkillPointsChanged (eventCode, pointsBefore, pointsNow, isSkyShard)

	--if (isSkyShard) then
		--return
	--end

	local logData = { }
	
	logData.event = "SkillPointsChanged"
	logData.points = pointsNow - pointsBefore
	logData.pointsBefore = pointsBefore
	logData.pointsNow = pointsNow
		
	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Skill points changed (".. tostring(logData.points) ..")")
end


function uespLog.OnQuestOptionalStepAdvanced (eventCode, text)

	if(text == "") then
		return
	end
	
	local logData = { }
	
	logData.event = "QuestOptionalStep"
	logData.text = text

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Quest optional step advanced ("..text..")")
end


function uespLog.OnQuestAdvanced (eventCode, journalIndex, questName, isPushed, isComplete, mainStepChanged)
	local logData = { }
	
	logData.event = "QuestAdvanced"
	logData.quest = questName
	logData.isPushed = isPushed
	logData.isComplete = isComplete
	logData.mainStepChanged = mainStepChanged

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	 
	uespLog.DebugLogMsg("Quest advanced "..questName)
end


function uespLog.OnRecipeLearned (eventCode, recipeListIndex, recipeIndex)
	uespLog.DumpRecipe(recipeListIndex, recipeIndex,  uespLog.GetTimeData())
	
	local known, recipeName = GetRecipeInfo(recipeListIndex, recipeIndex)
	uespLog.DebugLogMsg("New recipe " .. recipeName)
end


function uespLog.OnTelvarStoneUpdate (eventCode, newStones, oldStones, reason)
	local msg = "gained"
	local logData = { }
	local posData = uespLog.GetLastTargetData()
	
	if (posData.x == nil or posData.x == "") then
		posData = uespLog.GetPlayerPositionData()
	end
	
	logData.event = "TelvarUpdate"
	logData.qnt = newStones - oldStones
	logData.reason = reason
			
	uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
	
	if (logData.qnt == 0) then
		return
	elseif (logData.qnt < 0) then
		logData.qnt = -1*logData.qnt
		msg = "lost"
	end
	
	uespLog.DebugLogMsgColor(uespLog.itemColor, "You "..msg.." "..tostring(logData.qnt).." telvar stones ("..tostring(newStones).." total)")
end


function uespLog.OnMoneyUpdate (eventCode, newMoney, oldMoney, reason)
	local logData = { }
	local posData = uespLog.GetLastTargetData()
	local lootMsg = ""
	
	if (posData.x == nil or posData.x == "") then
		posData = uespLog.GetPlayerPositionData()
	end
	
	uespLog.lastMoneyChange = newMoney - oldMoney
	uespLog.lastMoneyGameTime = GetGameTimeMilliseconds()
	
	if (posData.lastTarget ~= nil) then
		lootMsg = " from "..tostring(posData.lastTarget)
	end

		-- 0 = loot
	if (reason == 0) then
		logData.event = "MoneyGained"
		logData.qnt = uespLog.lastMoneyChange
			
		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
		uespLog.DebugLogMsgColor(uespLog.itemColor, "You looted "..tostring(uespLog.lastMoneyChange).." gold"..lootMsg)
		
		-- 4 = quest reward
	elseif (reason == 4) then
		logData.event = "QuestMoney"
		logData.qnt = uespLog.lastMoneyChange

		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
		uespLog.DebugLogMsgColor(uespLog.itemColor, "Quest reward "..tostring(uespLog.lastMoneyChange).." gold"..lootMsg)
		
		-- 62 = Stolen
	elseif (reason == 62) then
		logData.event = "Stolen"
		logData.qnt = uespLog.lastMoneyChange

		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
		uespLog.DebugLogMsgColor(uespLog.itemColor, "You stole "..tostring(uespLog.lastMoneyChange).." gold"..lootMsg)
	else
		uespLog.DebugExtraMsg("UESP::Money Change, New="..tostring(newMoney)..",  Old="..tostring(oldMoney)..",  Diff="..tostring(uespLog.lastMoneyChange)..",  Reason="..tostring(reason))
	end	
	
end


function uespLog.OnLootUpdated (eventCode, actionName, isOwned)
	--uespLog.DebugMsg("OnLootUpdated::count = "..tostring(GetNumLootItems()))
	--uespLog.DebugExtraMsg("OnLootUpdated::actionName = "..tostring(actionName))
	--uespLog.DebugExtraMsg("OnLootUpdated::isOwned = "..tostring(isOwned))
	
	uespLog.lastLootUpdateCount = GetNumLootItems()
	uespLog.lastLootTargetName = uespLog.lastTargetData.name
end


function uespLog.OnTreasureLooted (targetName)
	safeName = string.lower(targetName)
	local duration = uespLog.GetTreasureTimers()[safeName]

	if (not uespLog.IsTreasureTimerEnabled() or duration == nil or duration <= 0) then
		return
	end
		
	zo_callLater(	function()
						uespLog.MsgColor(uespLog.itemColor, "A "..tostring(targetName).." was looted "..tostring(duration).." sec ago.")
					end, duration*1000)
	
	uespLog.DebugLogMsgColor(uespLog.itemColor, "Created "..tostring(duration).." sec timer for "..tostring(targetName).." just looted.")
end


function uespLog.OnLootClosed (eventCode)
	--uespLog.DebugMsg("OnLootClosed::count = "..tostring(GetNumLootItems()))
	
	if (uespLog.lastLootUpdateCount == 0) then
		uespLog.OnTreasureLooted(uespLog.lastLootTargetName)
		--uespLog.DebugMsg("Finished looting "..tostring(uespLog.lastLootTargetName))
	elseif (uespLog.lastLootUpdateCount > 0) then
		--uespLog.DebugMsg("Did not finish looting "..tostring(uespLog.lastLootTargetName))
	else
		--uespLog.DebugMsg("Unknown "..tostring(uespLog.lastLootUpdateCount).."::"..tostring(uespLog.lastLootTargetName))
	end
	
	uespLog.lastLootUpdateCount = -1
	uespLog.lastLootTargetName = ""
end


function uespLog.OnLootGained (eventCode, receivedBy, itemLink, quantity, itemSound, lootType, self, isPickPocket, extraLogData)
	local logData = { }
	local posData = uespLog.GetLastTargetData()
	local msgType = "item"
	local rcvType = "looted"
	--local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)
	local itemText, itemColor, itemId, itemLevel, itemData, niceName, niceLink = uespLog.ParseLinkID(itemLink)
	local itemStyleStr = uespLog.GetItemStyleStr(itemStyle)
	local lootMsg = ""
	
	uespLog.lastLootUpdateCount = GetNumLootItems()
	uespLog.lastLootTargetName = uespLog.lastTargetData.name
	
	--uespLog.DebugMsg("OnLootGained::count = "..tostring(GetNumLootItems()))
	
	if (uespLog.currentHarvestTarget ~= nil) then
		posData.x = uespLog.currentHarvestTarget.x
		posData.y = uespLog.currentHarvestTarget.y
		posData.zone = uespLog.currentHarvestTarget.zone
		posData.lastTarget = uespLog.currentHarvestTarget.name
		posData.harvestType = uespLog.currentHarvestTarget.harvestType
		msgType = "resource(" .. tostring(posData.harvestType) .. ")"
		rcvType = "harvested"
	elseif (niceLink == niceName) then
		msgType = "quest item"
		rcvType = "looted quest item"
	end
	
	if (isPickPocket) then
		rcvType = "pickpocketed"
	elseif (uespLog.lastTargetData.action == uespLog.ACTION_STEALFROM or uespLog.lastTargetData.action == uespLog.ACTION_STEAL) then
		rcvType = "stole"
	end

	logData.event = "LootGained"
	logData.itemLink = itemLink
	logData.qnt = quantity
	logData.lootType = lootType
	logData.rvcType = rcvType
	
	if (posData.x == nil or posData.x == "") then
		posData = uespLog.GetPlayerPositionData()
	end
	
	if (posData.lastTarget ~= nil) then
		lootMsg = " from "..tostring(posData.lastTarget)
	end

	if (self) then
		uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData(), extraLogData)
		--You looted [Sword] (x1) (level 30, Breton)
		
		if (extraLogData ~= nil and extraLogData.skippedLoot) then
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::Skipped looting "..niceLink.." (x"..tostring(quantity)..") (prov level "..tostring(extraLogData.tradeType)..")"..lootMsg)
		else
			--uespLog.DebugLogMsgColor(uespLog.itemColor, "You looted "..msgType.." "..niceLink.." (x"..tostring(quantity)..") (level "..tostring(itemLevel)..", "..itemStyleStr..")")
			--uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You "..rcvType.." "..msgType.." "..niceLink.." (x"..tostring(quantity)..") from "..tostring(posData.lastTarget))
			
			if (quantity == 1) then
				uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You "..rcvType.." "..niceLink..lootMsg)
			else
				uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You "..rcvType.." "..niceLink.." (x"..tostring(quantity)..")"..lootMsg)
			end
		end
		
		local money, stolenMoney = GetLootMoney()
		uespLog.DebugExtraMsg("UESP::LootMoney = "..tostring(money)..", stolen = "..tostring(stolenMoney))
	else
		uespLog.DebugMsgColor(uespLog.itemColor, "UESP::Someone "..rcvType.." "..msgType.." "..niceLink.." (x"..tostring(quantity)..")")
	end
	
end


function uespLog.OnCraftCompleted (eventCode, craftSkill)
	local inspiration = GetLastCraftingResultTotalInspiration()
	local numItemsGained, penalty = GetNumLastCraftingResultItemsAndPenalty()
	local logData = { }
	
	logData.event = "CraftComplete"
	logData.craftSkill = craftSkill
	logData.inspiration = inspiration
	logData.qnt = numItemsGained

	uespLog.AppendDataToLog("all", logData, uespLog.GetPlayerPositionData(), uespLog.GetTimeData())
	
	uespLog.AddTotalInspiration(inspiration)
	
	if (inspiration > 0) then
		uespLog.DebugLogMsg("Craft completed with "..tostring(inspiration).." xp ("..tostring(uespLog.GetTotalInspiration()).." since last reset)")
	end
	
    for i = 1, numItemsGained do
		local itemName, icon, stack, sellPrice, meetsUsageRequirement, equipType, itemType, itemStyle, quality, itemSoundCategory, itemInstanceId = GetLastCraftingResultItemInfo(i)
		
		logData = { }
		logData.event = "CraftComplete::Result"
		logData.itemName = itemName
		logData.type = itemType
		logData.equipType = equipType
		logData.quality = quality	
		logData.value = sellPrice
		logData.icon = icon
		logData.qnt = stack
		logData.itemInstanceId = itemInstanceId
		
		uespLog.AppendDataToLog("all", logData)
		
		local itemLink = uespLog.lastItemLinks[itemName]
		if (itemLink == nil) then itemLink = itemName end
		
		local itemText, itemColor, itemData, niceName, niceLink = uespLog.ParseLink(itemLink)
	
		uespLog.DebugLogMsgColor(uespLog.itemColor, "Crafted item ".. tostring(niceLink) .." (x"..tostring(stack)..")")
	end
	
	if (numItemsGained == 0) then
		uespLog.DebugLogMsg("0 items crafted")
	end	
end


-- ITEM_SOUND_CATEGORY_FOOTLOCKER
function uespLog.OnInventoryItemUsed (eventCode, itemSoundCategory)
	local logData = { }

	if (itemSoundCategory == ITEM_SOUND_CATEGORY_FOOTLOCKER) then
		logData.event = "OpenFootLocker"
		logData.sound = itemSoundCategory
		uespLog.AppendDataToLog("all", logData)
		uespLog.DebugLogMsg("Footlocker opened")
		
		uespLog.lastTargetData.action = "opened"
		local x, y, z, zone = uespLog.GetUnitPosition(unitTag)
		
		uespLog.lastTargetData.x = x
		uespLog.lastTargetData.y = y
		uespLog.lastTargetData.zone = zone
		uespLog.lastTargetData.name = "footlocker"
		
		return
	end
	
	uespLog.DebugExtraMsg("UESP::OnInventoryItemUsed sound="..tostring(itemSoundCategory))
end


function uespLog.OnInventorySlotUpdate (eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason)
	local itemName = GetItemName(bagId, slotIndex)

		-- Skip durability updates or items already logged
	if (updateReason == INVENTORY_UPDATE_REASON_DURABILITY_CHANGE) then
		--uespLog.DebugExtraMsg("UESP::Skipping inventory slot update for "..itemName..", reason "..tostring(updateReason)..", sound "..tostring(itemSoundCategory))
		return
	end
	
	if (not isNewItem) then
		uespLog.DebugExtraMsg("UESP::Skipping inventory slot update for "..itemName..", old, reason "..tostring(updateReason)..", sound "..tostring(itemSoundCategory))
		return
	end
		
	local result = uespLog.LogInventoryItem(bagId, slotIndex, "SlotUpdate")
	
	if (result) then
		uespLog.DebugExtraMsg("inventory slot update for "..itemName..", reason "..tostring(INVENTORY_UPDATE_REASON_DURABILITY_CHANGE)..", sound "..tostring(itemSoundCategory))
	end
	
end


function uespLog.OnTargetChange (eventCode)
    local unitTag = "reticleover"
    local unitType = GetUnitType(unitTag)
	
		--COMBAT_UNIT_TYPE_GROUP
		--COMBAT_UNIT_TYPE_NONE
		--COMBAT_UNIT_TYPE_OTHER
		--COMBAT_UNIT_TYPE_PLAYER
		--COMBAT_UNIT_TYPE_PLAYER_PET

    if (unitType == 2) then -- NPC, COMBAT_UNIT_TYPE_OTHER?
        local name = GetUnitName(unitTag)
        local x, y, z, zone = uespLog.GetUnitPosition(unitTag)
		local gameTime = GetGameTimeMilliseconds()
		local diffTime = gameTime - uespLog.lastOnTargetChangeGameTime
		
        if (name == nil or name == "" or x <= 0 or y <= 0) then
            return
        end
				
		uespLog.lastTargetData.x = x
		uespLog.lastTargetData.y = y
		uespLog.lastTargetData.zone = zone
		uespLog.lastTargetData.name = name
		
        local level = GetUnitLevel(unitTag)
		local gender = GetUnitGender(unitTag)
		local class = GetUnitClass(unitTag)   	-- Empty?
		local race = GetUnitRace(unitTag)		-- Empty?
		local difficulty = GetUnitDifficulty(unitTag)
		local currentHp, maxHp, effectiveHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
		local currentMg, maxMg, effectiveMg = GetUnitPower(unitTag, POWERTYPE_MAGICKA)
		local currentSt, maxSt, effectiveSt = GetUnitPower(unitTag, POWERTYPE_STAMINA)
		
		uespLog.lastTargetData.maxHp = maxHp
		uespLog.lastTargetData.maxMg = maxMg
		uespLog.lastTargetData.maxSt = maxSt
		uespLog.lastTargetData.level = level
		uespLog.lastTargetData.race = race
		uespLog.lastTargetData.class = class
		uespLog.lastTargetData.type = unitType		
		
		if (uespLog.IsIgnoredNPC(name)) then
			return
		end
		
		if (name == uespLog.lastOnTargetChange or diffTime < uespLog.MIN_TARGET_CHANGE_TIMEMS) then
			return
		end
		
		uespLog.lastOnTargetChange = name
		uespLog.lastOnTargetChangeGameTime = gameTime
		
		local logData = { }
		
		logData.event = "TargetChange"
		logData.name = name
		logData.level = level
		logData.gender = gender
		logData.difficulty = difficulty
		logData.maxHp = maxHp
		logData.maxMg = maxMg
		logData.maxSt = maxSt
		
		uespLog.AppendDataToLog("all", logData, uespLog.GetLastTargetData(), uespLog.GetTimeData())
		
		uespLog.DebugLogMsg("Npc "..name)
	elseif (unitType == COMBAT_UNIT_TYPE_PLAYER) then
		uespLog.lastOnTargetChange = ""
	elseif (unitType ~= 0) then
		uespLog.lastTargetData.level = ""
		uespLog.lastTargetData.race = ""
		uespLog.lastTargetData.class = ""
		uespLog.lastTargetData.type = unitType		
		uespLog.lastOnTargetChange = ""
	else
		uespLog.lastOnTargetChange = ""
    end
	
end


function uespLog.OnSynergyAbilityGained (eventCode, synergyBuffSlot, grantedAbilityName, beginTime, endTime, iconName)
	--EVENT_SYNERGY_ABILITY_GAINED (integer synergyBuffSlot, string grantedAbilityName, number beginTime, number endTime, string iconName)
	deltaTime = endTime - beginTime
	uespLog.DebugExtraMsg("Gained synergy "..grantedAbilityName.." for "..tostring(deltaTime).."s")
end


function uespLog.OnSynergyAbilityLost (eventCode, synergyBuffSlot)
	--EVENT_SYNERGY_ABILITY_LOST (integer synergyBuffSlot)
	uespLog.DebugExtraMsg("Lost synergy #"..synergyBuffSlot)
end


function uespLog.OnEffectChanged (eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType)
	--EVENT_EFFECT_CHANGED (integer changeType, integer effectSlot, string effectName, string unitTag, number beginTime, number endTime, integer stackCount, string iconName, string buffType, integer effectType, integer abilityType, integer statusEffectType)
	uespLog.DebugExtraMsg("Effect Changed: "..effectName.." unit:"..unitTag.." type:"..changeType.."")
end


function uespLog.OnPowerUpdate (eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	--EVENT_POWER_UPDATE (string unitTag, luaindex powerIndex, integer powerType, integer powerValue, integer powerMax, integer powerEffectiveMax)
	
	if (unitTag ~= "player") then
		return
	end
	
	local diff = 0
	local typeString = ""
	
	if (powerType == POWERTYPE_HEALTH) then
		diff = powerValue - uespLog.lastPlayerHP
		uespLog.lastPlayerHP = GetUnitPower("player", POWERTYPE_HEALTH)
		typeString = "health"
	elseif (powerType == POWERTYPE_MAGICKA) then
		diff = powerValue - uespLog.lastPlayerMG
		uespLog.lastPlayerMG = GetUnitPower("player", POWERTYPE_MAGICKA)
		typeString = "magicka"
	elseif (powerType == POWERTYPE_STAMINA) then
		diff = powerValue - uespLog.lastPlayerST
		uespLog.lastPlayerST = GetUnitPower("player", POWERTYPE_STAMINA)
		typeString = "stamina"
	elseif (powerType == POWERTYPE_ULTIMATE) then
		diff = powerValue - uespLog.lastPlayerUT
		uespLog.lastPlayerUT = GetUnitPower("player", POWERTYPE_ULTIMATE)
		typeString = "ultimate"
	end
	
	if (diff < 0) then
		diff = math.abs(diff)
		uespLog.DebugExtraMsg("Lost "..tostring(diff).." "..typeString)
	elseif (diff > 0) then
		uespLog.DebugExtraMsg("Gained "..tostring(diff).." "..typeString)
	else
		--uespLog.DebugExtraMsg("powerIndex = "..tostring(powerIndex)..", type="..tostring(powerType)..", value="..tostring(powerValue)..", max="..tostring(powerMax)..", effMax="..tostring(powerEffectiveMax))
		--uespLog.DebugExtraMsg("Lost "..tostring(diff).." "..typeString)
	end
	
end


function uespLog.OnFoundSkyshard ()
	local logData = { }
	
	logData.event = "Skyshard"
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("Found skyshard")
end


function uespLog.OnFoundTreasure (name)
	local logData = { }
	
	logData.event = "FoundTreasure"
	logData.name = name
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("Found "..tostring(name))

	uespLog.lastLootTargetName = name
end


function uespLog.OnFoundFish ()
	local logData = { }
	
	logData.event = "Fish"
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetCurrentTargetData(), uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("Found fishing hole")
end


function uespLog.OnMailMessageReadable (eventCode, mailId)
	local senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	
	uespLog.DebugExtraMsg("Read mail from " ..tostring(senderDisplayName).." with "..tostring(numAttachments).." items")
	
	uespLog.lastMailItems = { }
	uespLog.lastMailId = mailId
		
	for attachIndex = 1, numAttachments do
		local itemLink = GetAttachedItemLink(mailId, attachIndex)
		local icon, stack, creatorName = GetAttachedItemInfo(mailId, attachIndex) 
		
		local newItem = { }
		newItem.itemLink = itemLink
		newItem.stack = stack
		newItem.icon = icon
		
		uespLog.lastMailItems[attachIndex] = newItem
	end
	
end


function uespLog.OnMailMessageTakeAttachedItem (eventCode, mailId)
	local senderDisplayName, senderCharacterName, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
	local tradeType = CRAFTING_TYPE_INVALID
	local logData = { }
	local timeData = uespLog.GetTimeData()
	
	uespLog.DebugExtraMsg("Received mail item from " ..tostring(senderDisplayName))
	
	if (mailId ~= uespLog.lastMailId or #uespLog.lastMailItems == 0) then
		uespLog.DebugMsg("No attachments in mail")
		return
	end
	
	if (subject == "Getting Groceries" or subject == "Raw Provisioner Materials" or senderDisplayName == "Gavin Gavonne") then
		tradeType = CRAFTING_TYPE_PROVISIONING
	elseif (subject == "Raw Woodworker Materials" or senderDisplayName == "Pacrooti") then
		tradeType = CRAFTING_TYPE_WOODWORKING
	elseif (subject == "Raw Blacksmith Materials" or senderDisplayName == "Valinka Stoneheaver") then
		tradeType = CRAFTING_TYPE_BLACKSMITHING
	elseif (subject == "Raw Enchanter Materials" or senderDisplayName == "Abnab") then
		tradeType = CRAFTING_TYPE_ENCHANTING
	elseif (subject == "Raw Clothier Materials" or senderDisplayName == "UNKNOWN") then
		tradeType = CRAFTING_TYPE_CLOTHIER
	elseif (subject == "Raw Materials") then -- Unknown hireling message
		tradeType = 100
	else -- Not a tradeskill hireling message
		tradeType = CRAFTING_TYPE_INVALID
	end
	
	for attachIndex = 1,  #uespLog.lastMailItems do
		--local itemLink = GetAttachedItemLink(mailId, attachIndex)
		--local icon, stack, creatorName = GetAttachedItemInfo(mailId, attachIndex) 
		
		local lastItem = uespLog.lastMailItems[attachIndex]
		
		logData = { }
		logData.event = "MailItem"
		logData.tradeType = tradeType
		logData.itemLink = uespLog.MakeNiceLink(lastItem.itemLink)
		logData.qnt = lastItem.stack
		logData.icon = lastItem.icon
		logData.sender = senderDisplayName
		logData.subject = subject
		
		uespLog.AppendDataToLog("all", logData, timeData)
		
		if (tradeType > 0) then
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You received hireling mail item "..tostring(logData.itemLink).." (x"..tostring(lastItem.stack)..")")
		else
			uespLog.DebugMsgColor(uespLog.itemColor, "UESP::You received mail item "..tostring(logData.itemLink).." (x"..tostring(lastItem.stack)..")")
		end
	end
	
	uespLog.lastMailItems = { }
	uespLog.lastMailId = 0
end


 function uespLog.OnChatMessage (eventCode, messageType, fromName, chatText)
	--|HFFFFFF:item:45810:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h"
	
	--uespLog.DebugMsg("Chat Message "..tostring(messageType))
	
	local numLinks = 0
	
	
	for link in string.gmatch(chatText, "|H.-:item:.-|h.-|h") do
		numLinks = numLinks + 1
		
		local logData = uespLog.GetTimeData()
		logData.msgType = messageType
		uespLog.LogItemLink(link, "ItemLink", logData)
    end
	
	if (numLinks > 0) then
		uespLog.DebugExtraMsg("Logged "..tostring(numLinks).." item links from chat message.")
	end
	
 end


uespLog.menuUpdated = false
uespLog.PvpCheckCounter = 0
uespLog.PvpCheckCounterMax = 1000	-- Check roughly every 10 secs


function uespLog.OnUpdate ()

	uespLog.PvpCheckCounter = uespLog.PvpCheckCounter + 1
	
	if (uespLog.PvpCheckCounter >= uespLog.PvpCheckCounterMax) then
		uespLog.CheckForNewLocalBattles()
		uespLog.PvpCheckCounter = 0
	end

    if IsGameCameraUIModeActive() then
        return
    end

    local action, name, interactionBlocked, additionalInfo, context = GetGameCameraInteractableActionInfo()
	local active = IsPlayerInteractingWithObject()
	local interactionType = GetInteractionType()
	local x, y, z, zone
	
	if (interactionType ~= INTERACTION_HARVEST and uespLog.currentHarvestTarget ~= nil) then
		uespLog.DebugExtraMsg("Stopped harvesting "..tostring(uespLog.currentHarvestTarget.name))
		uespLog.currentHarvestTarget = nil
	elseif (interactionType == INTERACTION_HARVEST and uespLog.currentHarvestTarget == nil) then
		uespLog.currentHarvestTarget = { }
		uespLog.currentHarvestTarget.x = uespLog.lastHarvestTarget.x
		uespLog.currentHarvestTarget.y = uespLog.lastHarvestTarget.y
		uespLog.currentHarvestTarget.zone = uespLog.lastHarvestTarget.zone
		uespLog.currentHarvestTarget.name = uespLog.lastHarvestTarget.name
		uespLog.currentHarvestTarget.harvestType = uespLog.lastHarvestTarget.harvestType
				
		uespLog.DebugExtraMsg("Started harvesting "..tostring(uespLog.currentHarvestTarget.name))
	end

    if (name == nil) then
		--if (uespLog.currentTargetData.name ~= "") then uespLog.DebugExtraMsg("CurrentTarget cleared") end
		uespLog.currentTargetData.name = ""
		uespLog.currentTargetData.x = ""
		uespLog.currentTargetData.y = ""
		uespLog.currentTargetData.zone = ""
        return
    end
	
	if (not active) then
		uespLog.lastTargetData.name = name
		uespLog.lastTargetData.x = uespLog.currentTargetData.x
		uespLog.lastTargetData.y = uespLog.currentTargetData.y
		uespLog.lastTargetData.zone = uespLog.currentTargetData.zone
		uespLog.lastTargetData.gameTime = GetGameTimeMilliseconds()
		uespLog.lastTargetData.timeStamp = GetTimeStamp()
		uespLog.lastTargetData.action = uespLog.currentTargetData.action
		uespLog.lastTargetData.interactionType = uespLog.currentTargetData.interactionType
    end
	
	if (interactionType == INTERACTION_NONE and action == uespLog.ACTION_COLLECT) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found collect node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "collect"
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_MINE) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found ore node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "ore"
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_CUT) then
		if (uespLog.lastHarvestTarget.name ~= uespLog.currentTargetData.name) then uespLog.DebugExtraMsg("Found wood node") end
		uespLog.lastHarvestTarget.x = uespLog.currentTargetData.x
		uespLog.lastHarvestTarget.y = uespLog.currentTargetData.y
		uespLog.lastHarvestTarget.zone = uespLog.currentTargetData.zone
		uespLog.lastHarvestTarget.name = uespLog.currentTargetData.name
		uespLog.lastHarvestTarget.harvestType = "wood"
	end

    if (action == nil or name == "" or name == uespLog.currentTargetData.name) then
        return
    end
	
	if (DoesUnitExist("reticleover")) then
		x, y, z, zone = uespLog.GetUnitPosition("reticleover")
	else
		x, y, z, zone = uespLog.GetPlayerPosition()
	end
	
	uespLog.currentTargetData.name = name
	uespLog.currentTargetData.x = x
	uespLog.currentTargetData.y = y
	uespLog.currentTargetData.zone = zone
	uespLog.currentTargetData.action = action
	uespLog.currentTargetData.interactionType = interactionType
	
	--uespLog.DebugExtraMsg("CurrentTarget = "..tostring(name))
	--uespLog.DebugExtraMsg("CurrentAction = "..tostring(action))
	--uespLog.DebugExtraMsg("interactionType = "..tostring(interactionType))
	
    if (interactionType == INTERACTION_NONE and action == uespLog.ACTION_USE) then

        if name == "Skyshard" then
			uespLog.OnFoundSkyshard()
        end

    elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_UNLOCK) then
	
		if (name == "Chest") then
			uespLog.OnFoundTreasure("Chest")
		end
		
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_STEALFROM) then
	
		if (name == "Safebox") then
			uespLog.OnFoundTreasure("Safebox")
		end
		
	elseif (interactionType == INTERACTION_NONE and action == uespLog.ACTION_SEARCH) then
	
		if (name == "Heavy Sack") then
			uespLog.OnFoundTreasure("Heavy Sack")
		end
	
    elseif (action == uespLog.ACTION_FISH) then
		uespLog.OnFoundFish()
    end

end


function uespLog.getDayOfMonth (yearDay)

	if yearDay < 30 then
		return yearDay + 1, 1
	elseif yearDay < 58 then
		return yearDay - 29, 2
	elseif yearDay < 89 then
		return yearDay - 57, 3
	elseif yearDay < 119 then
		return yearDay - 88, 4
	elseif yearDay < 150 then
		return yearDay - 118, 5
	elseif yearDay < 180 then
		return yearDay - 149, 6
	elseif yearDay < 211 then
		return yearDay - 179, 7
	elseif yearDay < 242 then
		return yearDay - 210, 8
	elseif yearDay < 272 then
		return yearDay - 241, 9
	elseif yearDay < 303 then
		return yearDay - 271, 10
	elseif yearDay < 333 then
		return yearDay - 302, 11
	else
		return yearDay - 333, 12
	end
	
end


function uespLog.getMoonPhaseStr(inputTimeStamp, includeDetails)
	local timeStamp = inputTimeStamp or GetTimeStamp()
	
	local moonOffsetTime = timeStamp - uespLog.DEFAULT_MOONPHASESTARTTIME
	local moonPhase = moonOffsetTime / uespLog.DEFAULT_MOONPHASETIME
	local moonPhaseNorm = moonPhase % 1
	local phaseStr = "Unknown"
	
	if (moonPhaseNorm <= 0.06) then
		phaseStr = "New"
	elseif (moonPhaseNorm <= 0.185) then
		phaseStr = "Waxing Crescent"
	elseif (moonPhaseNorm <= 0.31) then
		phaseStr = "First Quarter"
	elseif (moonPhaseNorm <= 0.435) then
		phaseStr = "Waxing Gibbous"
	elseif (moonPhaseNorm <= 0.56) then
		phaseStr = "Full"
	elseif (moonPhaseNorm <= 0.685) then
		phaseStr = "Waning Gibbous"
	elseif (moonPhaseNorm <= 0.81) then
		phaseStr = "Third Quarter"
	elseif (moonPhaseNorm <= 0.935) then
		phaseStr = "Waning Crescent"
	else
		phaseStr = "New"
	end	
	
	local result
	
	if (includeDetails) then
		result = string.format("%s (%0.2f)", phaseStr, moonPhase)
	else
		relMoonPhase = 100 - math.abs((moonPhase % 1)- 0.5)*200
		result = string.format("%s (%0.0f%% full)", phaseStr, relMoonPhase)
	end
	
	return result	
end


function uespLog.getGameTimeStr(inputTimestamp, includeDetails)
	local timeStamp = inputTimestamp or GetTimeStamp()

	local offsetTime = timeStamp - (uespLog.DEFAULT_GAMETIME_OFFSET - uespLog.GAMETIME_REALSECONDS_OFFSET) - uespLog.GAMETIME_DAY_OFFSET * uespLog.DEFAULT_REALSECONDSPERGAMEDAY
	local gameDayTime = offsetTime % uespLog.DEFAULT_REALSECONDSPERGAMEDAY
	local year = math.floor(offsetTime / uespLog.DEFAULT_REALSECONDSPERGAMEYEAR) + uespLog.DEFAULT_GAMETIME_YEAROFFSET
	local yearDay = math.floor((offsetTime % uespLog.DEFAULT_REALSECONDSPERGAMEYEAR) / uespLog.DEFAULT_REALSECONDSPERGAMEDAY)
	local day, month = uespLog.getDayOfMonth(yearDay)
	local weekDay = math.floor((offsetTime / uespLog.DEFAULT_REALSECONDSPERGAMEDAY) % 7) + 1
	local monthStr = uespLog.TES_MONTHS[month]
	local weekDayStr = uespLog.TES_WEEKS[weekDay]
	local hour = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMEHOUR) % 24)
	local minute = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMEMINUTE) % 60)
	local second = math.floor((gameDayTime / uespLog.DEFAULT_REALSECONDSPERGAMESECOND) % 60)
	
	local hourStr = string.format("%02d", hour)
	local minuteStr = string.format("%02d", minute)
	local secondStr = string.format("%02d", second)
	
	local TimeStr
	
		--"2E 582 Hearth's Fire, Morndas 08:12:11" 
	if (includeDetails) then
		TimeStr = "2E "..tostring(year).." "..monthStr.."("..tostring(month)..") "..tostring(day)..", "..weekDayStr.."("..tostring(weekDay).."), "..hourStr..":"..minuteStr..":"..secondStr
	else
		TimeStr = "2E "..tostring(year).." "..monthStr.." "..tostring(day)..", "..weekDayStr..", "..hourStr..":"..minuteStr..":"..secondStr
	end
		
	return TimeStr
end


function uespLog.ShowTime (inputTimestamp)
	local timeStamp = inputTimestamp or GetTimeStamp()
	local localGameTime = GetGameTimeMilliseconds()
	local timeStampStr = Id64ToString(timeStamp)
	local timeStampFmt = GetDateStringFromTimestamp(timeStamp)
	local version = _VERSION
	local apiVersion = GetAPIVersion()
	local gameTimeStr = uespLog.getGameTimeStr(timeStamp, uespLog.IsDebugExtra())
	local moonPhaseStr = uespLog.getMoonPhaseStr(timeStamp, uespLog.IsDebugExtra())
		
	uespLog.MsgColor(uespLog.timeColor, "UESP::Game Time = " .. gameTimeStr .. "")
	uespLog.MsgColor(uespLog.timeColor, "UESP::Moon Phase = " .. moonPhaseStr .. "")
	uespLog.MsgColor(uespLog.timeColor, "UESP::localGameTime = " .. tostring(localGameTime/1000) .. " sec")
	uespLog.MsgColor(uespLog.timeColor, "UESP::timeStamp = " .. tostring(timeStamp))
	uespLog.MsgColor(uespLog.timeColor, "UESP::timeStamp Date = " .. timeStampFmt)
	uespLog.MsgColor(uespLog.timeColor, "UESP::_VERSION = " ..version..",  API = "..tostring(apiVersion))	
	uespLog.DebugExtraMsg(uespLog.timeColor, "UESP::timeStampStr = " .. timeStampStr)
end


function uespLog.ShowTreasureTimerHelp()
	uespLog.Msg("Expected one of the command formats:")
	uespLog.Msg(".      /uesptreasuretimer [on/off]")
	uespLog.Msg(".      /uesptreasuretimer [name] [duration]")
		
	if (uespLog.IsTreasureTimerEnabled()) then
		uespLog.Msg("Treasure timer is currently enabled.")
	else
		uespLog.Msg("Treasure timer is currently disabled.")
	end
end


function uespLog.SetTreasureTimerDuration(name, duration)

	if (name == nil) then
		return
	end
	
	local safeName = string.lower(name)
	local currentDuration = uespLog.GetTreasureTimers()[safeName]

	if (currentDuration == nil) then
		uespLog.Msg("There is no treasure timer for "..tostring(name))
	elseif (duration == nil or duration == "") then
		uespLog.Msg("Treasure timer for "..tostring(name).." is "..tostring(currentDuration).." sec.")
		return
	else
		local newDuration = tonumber(duration)
		uespLog.GetTreasureTimers()[safeName] = newDuration
		uespLog.Msg("Set the treasure timer for "..tostring(name).." to "..tostring(newDuration).." sec.")
	end
	
end


SLASH_COMMANDS["/uesptreasuretimer"] = function (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%S+") do table.insert(cmdWords, word) end
	
	if (#cmdWords < 1) then
		uespLog.ShowTreasureTimerHelp()
		return
	end
	
	firstCmd = string.lower(cmdWords[1])
	
	if (firstCmd == "on") then
		uespLog.SetTreasureTimerEnabled(true)
		uespLog.Msg("Treasure timer is now enabled.")
	elseif (firstCmd == "off") then
		uespLog.SetTreasureTimerEnabled(false)
		uespLog.Msg("Treasure timer is now disabled.")
	elseif (firstCmd ~= "") then
	
		if (firstCmd == "heavy") then
			cmdWords[1] = cmdWords[1].." "..cmdWords[2]
			cmdWords[2] = cmdWords[3]
		end
		
		uespLog.SetTreasureTimerDuration(cmdWords[1], cmdWords[2])
	else
		uespLog.ShowTreasureTimerHelp()
	end
	
end


SLASH_COMMANDS["/utt"] = SLASH_COMMANDS["/uesptreasuretimer"]


SLASH_COMMANDS["/uesptime"] = function (cmd)
	cmdWords = {}
	for word in cmd:gmatch("%S+") do table.insert(cmdWords, string.lower(word)) end
	
	if (#cmdWords < 1) then
		uespLog.ShowTime()
	elseif (cmdWords[1] == "cal" or cmdWords[1] == "calibrate") then
		local timeStamp = GetTimeStamp()
		local x, y, heading, zone = GetMapPlayerPosition("player")
		local headingStr = string.format("%.2f", heading*57.29582791)
		local cameraHeading = GetPlayerCameraHeading()
		local camHeadingStr = string.format("%.2f", cameraHeading*57.29582791)
		uespLog.MsgColor(uespLog.timeColor, "UESP::Current Time Stamp = " .. tostring(timeStamp).." secs")
		uespLog.MsgColor(uespLog.timeColor, "UESP::Player Heading = " .. tostring(headingStr).." degrees")
		uespLog.MsgColor(uespLog.timeColor, "UESP::Camera Heading = " .. tostring(camHeadingStr).." degrees")
		return
	elseif (cmdWords[1] == "daylength") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day length is currently "..tostring(uespLog.DEFAULT_REALSECONDSPERGAMEDAY).." secs")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value > 0) then
			uespLog.DEFAULT_REALSECONDSPERGAMEDAY = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day length set to "..tostring(uespLog.DEFAULT_REALSECONDSPERGAMEDAY).." secs")
		end
	elseif (cmdWords[1] == "realoffset") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time real offset is currently "..tostring(uespLog.GAMETIME_REALSECONDS_OFFSET).." secs")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value ~= nil) then
			uespLog.GAMETIME_REALSECONDS_OFFSET = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time real offset set to "..tostring(uespLog.GAMETIME_REALSECONDS_OFFSET).." secs")
		end
	elseif (cmdWords[1] == "dayoffset") then
	
		if (cmdWords[2] == nil) then
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day offset is currently "..tostring(uespLog.GAMETIME_DAY_OFFSET).." days")
			return
		end
		
		local value = tonumber(cmdWords[2])
		
		if (value ~= nil) then
			uespLog.GAMETIME_DAY_OFFSET = value
			uespLog.MsgColor(uespLog.timeColor, "UESP::Game time day offset set to "..tostring(uespLog.GAMETIME_DAY_OFFSET).." days")
		end
	else
		uespLog.ShowTime()
	end
	
end


SLASH_COMMANDS["/uespd"] = function(cmd)
	SLASH_COMMANDS["/script"]("d(".. tostring(cmd) .. ")")
end


SLASH_COMMANDS["/ud"] = SLASH_COMMANDS["/uespd"]


SLASH_COMMANDS["/uespenl"] = function (cmd)
	local enl = GetEnlightenedPool()
	local mult = GetEnlightenedMultiplier()

	uespLog.MsgColor(uespLog.xpColor, "UESP::You have "..tostring(enl).." enlightenment at a x"..tostring(mult).." bonus.")
end


SLASH_COMMANDS["/ue"] = SLASH_COMMANDS["/uespenl"]


function uespLog.DisplayPowerStat (statType, statName)
	local currentStat, maxValue, effectiveMax = GetUnitPower("player", statType)
	uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." (effective max "..tostring(effectiveMax).." of ".. tostring(maxValue)..")")
end


function uespLog.DisplayStat (statType, statName)
	--value = GetPlayerStat(DerivedStats derivedStat, StatBonusOption statBonusOption, StatSoftCapOption statSoftCapOption)

	local softCap = GetStatSoftCap(statType)
	local currentStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
	local noCapStat = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_DONT_APPLY_SOFT_CAP)
	
	if (softCap == nil) then
		uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." (no cap)")
	else
		uespLog.MsgColor(uespLog.statColor, "UESP::"..tostring(statName).." "..tostring(currentStat).." ("..tostring(noCapStat).." with cap of ".. tostring(softCap)..")")
	end
end


SLASH_COMMANDS["/uespcharinfo"] = function (cmd)
	local numPoints = GetAvailableSkillPoints()
	local numSkyShards = GetNumSkyShards()
	
	uespLog.Msg("UESP::Skill Points = ".. tostring(numPoints))
	uespLog.Msg("UESP::Skyshards = ".. tostring(numSkyShards))
	
	local armorSC = GetStatSoftCap(STAT_ARMOR_RATING)
	local hpSC = GetStatSoftCap(STAT_HEALTH_MAX)
	local mgSC = GetStatSoftCap(STAT_MAGICKA_MAX)
	
	local stSC = GetStatSoftCap(STAT_MAGICKA_REGEN_COMBAT)
	--local value = GetPlayerStat(DerivedStats derivedStat, StatBonusOption statBonusOption, StatSoftCapOption statSoftCapOption)
	
	uespLog.DisplayStat(STAT_HEALTH_MAX, "HP")
	uespLog.DisplayStat(STAT_MAGICKA_MAX, "Magicka")
	uespLog.DisplayStat(STAT_STAMINA_MAX, "Stamina")
	
	uespLog.DisplayStat(STAT_HEALTH_REGEN_COMBAT, "HP Combat Regen")
	uespLog.DisplayStat(STAT_MAGICKA_REGEN_COMBAT, "Magicka Combat Regen")
	uespLog.DisplayStat(STAT_STAMINA_REGEN_COMBAT, "Stamina Combat Regen")
	
	uespLog.DisplayStat(STAT_HEALTH_REGEN_IDLE, "HP Idle Regen")
	uespLog.DisplayStat(STAT_MAGICKA_REGEN_IDLE, "Magicka Idle Regen")
	uespLog.DisplayStat(STAT_STAMINA_REGEN_IDLE, "Stamina Idle Regen")
	
	uespLog.DisplayStat(STAT_ARMOR_RATING, "Armor")
	uespLog.DisplayStat(STAT_BLOCK, "Block")
	uespLog.DisplayStat(STAT_CRITICAL_RESISTANCE, "Critical Resist")
	uespLog.DisplayStat(STAT_SPELL_RESIST, "Spell Resist")
	uespLog.DisplayStat(STAT_SPELL_MITIGATION, "Spell Mitigation")
	uespLog.DisplayStat(STAT_DODGE, "Dodge")
	uespLog.DisplayStat(STAT_PARRY, "Parry")
	uespLog.DisplayStat(STAT_PHYSICAL_RESIST, "Physical Resist")
	
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_COLD, "Resist Cold")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_DISEASE, "Resist Disease")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_DROWN, "Resist Drown")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_EARTH, "Resist Earth")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_FIRE, "Resist Fire")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_GENERIC, "Resist Generic")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_MAGIC, "Resist Magic")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_OBLIVION, "Resist Oblivion")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_PHYSICAL, "Resist Physical")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_POISON, "Resist Poison")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_SHOCK, "Resist Shock")
	uespLog.DisplayStat(STAT_DAMAGE_RESIST_START, "Resist Start")
		
	uespLog.DisplayStat(STAT_CRITICAL_STRIKE, "Critical Strike")
	uespLog.DisplayStat(STAT_WEAPON_POWER, "Weapon Power")
	uespLog.DisplayStat(STAT_SPELL_POWER, "Spell Power")
	uespLog.DisplayStat(STAT_SPELL_CRITICAL, "Spell Critical")
	uespLog.DisplayStat(STAT_SPELL_PENETRATION, "Spell Penetration")
	uespLog.DisplayStat(STAT_POWER, "Power")
	uespLog.DisplayStat(STAT_ATTACK_POWER, "Attack Power")
	uespLog.DisplayStat(STAT_MISS, "Miss")
	uespLog.DisplayStat(STAT_PHYSICAL_PENETRATION, "Physical Penetration")
	
	uespLog.DisplayPowerStat(POWERTYPE_HEALTH, "HP")
	uespLog.DisplayPowerStat(POWERTYPE_MAGICKA, "Magicka")
	uespLog.DisplayPowerStat(POWERTYPE_STAMINA, "Stamina")
	uespLog.DisplayPowerStat(POWERTYPE_ULTIMATE, "Ultimate")
	uespLog.DisplayPowerStat(POWERTYPE_FINESSE, "Finesse")
	uespLog.DisplayPowerStat(POWERTYPE_WEREWOLF, "Werewolf")
	uespLog.DisplayPowerStat(POWERTYPE_MOUNT_STAMINA, "Mount Stamina")
	
	--uespLog.DisplayStat(STAT_CRITICAL_STRIKE, "")
	
	--uespLog.Msg("UESP::HP Soft Cap = ".. tostring(hpSC))
	--uespLog.Msg("UESP::MG Soft Cap = ".. tostring(mgSC))
	--uespLog.Msg("UESP::ST Soft Cap = ".. tostring(stSC))
	--uespLog.Msg("UESP::Armor Soft Cap = ".. tostring(armorSC))
end

SLASH_COMMANDS["/uci"] = SLASH_COMMANDS["/uespcharinfo"]


SLASH_COMMANDS["/loc"] = function (cmd)
	local Msg = "Position"
	local logData = { }
	local posData = uespLog.GetPlayerPositionData()
	local x, y, heading, zone = GetMapPlayerPosition("player")
		
	logData.event = "Location"
	
	if (cmd ~= "") then
		logData.label = cmd
		Msg = Msg .. "["..cmd.."]"
	end
	
	Msg = Msg .. string.format(" %.4f, %.4f, %s, heading %.1f deg", posData.x, posData.y, posData.zone, heading*57.29582791)
	--Msg = Msg .. " " .. tostring(posData.x) .. ", " .. tostring(posData.y) ..", " .. tostring(posData.zone) ..", heading "..tostring(heading)
	uespLog.Msg(Msg)
	
	uespLog.AppendDataToLog("all", logData, posData, uespLog.GetTimeData())
end


SLASH_COMMANDS["/uespdebug"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetDebug(true)
		uespLog.SetDebugExtra(false)
		uespLog.Msg("Turned UESP log messages on.")
	elseif (cmd == "off") then
		uespLog.SetDebug(false)
		uespLog.SetDebugExtra(false)
		uespLog.Msg("Turned UESP log messages off.")
	elseif (cmd == "extra") then
		uespLog.SetDebug(true)
		uespLog.SetDebugExtra(true)
		uespLog.Msg("Turned UESP log messages to EXTRA mode.")
	elseif (cmd == "") then
		local flagStr = uespLog.BoolToOnOff(uespLog.IsDebug())
		if (uespLog.IsDebugExtra()) then flagStr = "EXTRA" end
		uespLog.Msg("uespdebug is currently " .. flagStr .. ". Use on/off/extra to set!")
	end
	
end


SLASH_COMMANDS["/uesplog"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetLogData(true)
		uespLog.Msg("Turned UESP data logging on.")
	elseif (cmd == "off") then
		uespLog.SetLogData(false)
		uespLog.Msg("Turned UESP data logging off.")
	elseif (cmd == "") then
		uespLog.Msg("UESP data logging is currently " .. uespLog.BoolToOnOff(uespLog.IsLogData()) .. ". Use 'on' or 'off' to set!")
	end
	
end


SLASH_COMMANDS["/uespmail"] = function (cmd)
	local cmds = { }
	local displayHelp = false
	
	for i in string.gmatch(cmd, "%S+") do cmds[#cmds + 1] = i end
	
	if (#cmds <= 0 or cmds[1] == "help") then
		displayHelp = true
	elseif (cmds[1] == "deletenotify") then
		if (cmds[2] == "on") then
			uespLog.SetMailDeleteNotify(true)
			uespLog.Msg("Turned UESP delete mail notify on.")
		elseif (cmds[2] == "off") then
			uespLog.SetMailDeleteNotify(false)
			uespLog.Msg("Turned UESP delete mail notify off.")
		elseif (cmds[2] == "" or cmds[2] == nil) then
			uespLog.Msg("UESP delete mail notification is currently " .. uespLog.BoolToOnOff(uespLog.IsMailDeleteNotify()) .. ". Use 'on' or 'off' to set!")
		else
			displayHelp = true
		end
	else
		displayHelp = true
	end
	
	if (displayHelp) then
		uespLog.Msg("UESP::Format of /uespmail is:")
		uespLog.Msg(".      /uespmail deletenotify [on||off]")
	end
	
end


SLASH_COMMANDS["/uespcolor"] = function (cmd)

	if (cmd == "on") then
		uespLog.SetColor(true)
		uespLog.Msg("Turned UESP color output on.")
	elseif (cmd == "off") then
		uespLog.SetColor(false)
		uespLog.Msg("Turned UESP color output off.")
	elseif (cmd == "") then
		uespLog.Msg("UESP color output is currently " .. uespLog.BoolToOnOff(uespLog.IsColor()) .. ". Use 'on' or 'off' to set!")
	end
	
end


SLASH_COMMANDS["/uespdump"] = function(cmd)
	local cmds = { }
	local helpString = "Use one of: recipes, skills, achievements, inventory, globals"

	for i in string.gmatch(cmd, "%S+") do
		cmds[#cmds + 1] = i
	end

	if (#cmds <= 0) then
		uespLog.Msg(helpString)
	elseif (cmds[1] == "recipes") then
		uespLog.DumpRecipes()
	elseif (cmds[1] == "skills") then
		uespLog.DumpSkills(cmds[2], cmds[3])
	elseif (cmds[1] == "achievements") then
		uespLog.DumpAchievements()
	elseif (cmds[1] == "inventory") then
		uespLog.DumpInventory()
	elseif (cmds[1] == "globals") then
		
		if (cmds[2] == "end" or cmds[2] == "stop") then
			uespLog.DumpGlobalsIterateEnd()
		elseif (cmds[2] == "begin" or cmds[2] == "start") then
			uespLog.DumpGlobalsIterateStart(tonumber(cmds[3]))
		elseif (not uespLog.dumpIterateEnabled) then
			uespLog.DumpGlobals(tonumber(cmds[2]))
		else
			uespLog.DebugMsg("UESP::Dump globals iterative currently running...")
		end
	
	elseif (cmds[1] == "globalprefix") then
		local l1, l2, l3 = globalprefixes()
		uespLog.DumpGlobals(tonumber(cmds[2]), l2)
	elseif (cmds[1] == "smith") then
		uespLog.DumpSmithItems(false)
	elseif (cmds[1] == "smithset") then
		uespLog.DumpSmithItems(true)
	elseif (cmds[1] == "tooltip") then
		uespLog.DumpToolTip()
	else
		uespLog.Msg(helpString)
	end
	
end


function uespLog.DumpSkills(opt1, opt2)

	if (opt2 == nil) then opt2 = "" end

	if (opt1 == nil or opt1 == "" or opt1 == "basic") then
		return uespLog.DumpSkillsBasic()
	elseif (opt1 == "progression") then
		uespLog.DumpSkillsProgression(opt2)
		return true
	elseif (opt1 == "learned") then
		uespLog.DumpLearnedAbilities(opt2)
		return true
	elseif (opt1 == "types") then
		uespLog.DumpSkillTypes(opt2)
		return true
	elseif (opt1 == "all") then
		uespLog.DumpSkillsStart(opt2)
		uespLog.DumpSkillTypes(opt2)
		uespLog.DumpSkillsProgression(opt2)
		uespLog.DumpLearnedAbilities(opt2)
		return true
	elseif (opt1 == "abilities") then
		uespLog.DumpSkillsStart(opt2)
		return true
	elseif (opt1 == "char" or opt1 == "character") then
		uespLog.DumpSkillTypes(opt2)
		uespLog.DumpSkillsProgression(opt2)
		uespLog.DumpLearnedAbilities(opt2)
		return true
	elseif (opt1 == "class") then
		uespLog.DumpSkillTypes(opt2, true)
		uespLog.DumpSkillsProgression(opt2, true)
		uespLog.DumpLearnedAbilities(opt2)
		return true
	elseif (opt1 == "race") then
		uespLog.DumpSkillTypes(opt2, false, true)
		uespLog.DumpLearnedAbilities(opt2)
		return true
	else
		uespLog.Msg("Expected format:")
		uespLog.Msg(".     /uespdump skills [basic/progression/abilities/character/race/class/learned/types/all] [note]")
	end
	
	return false
end


function uespLog.GetSkillTypeName(skillType)
	return GetString(SI_SKILLTYPE1 + skillType - 1)
end


function uespLog.DumpSkillTypes(note, classOnly, raceOnly)
	local logData = { }
	local count = 0
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local count = 0
	local startSkill = 1
	local endSkill = numSkillTypes
	
	classOnly = classOnly or false
	raceOnly = raceOnly or false
	uespLog.DebugLogMsg("Logging abilities by skill types for current character...")
	
	if (classOnly) then
		startSkill = 1
		
		if (raceOnly) then
			endSkill = 7
			uespLog.DebugLogMsg(".     Logging only class and race abilities...")
		else
			endSkill = 1
			uespLog.DebugLogMsg(".     Logging only class abilities...")
		end
	elseif (raceOnly) then
		startSkill = 7
		endSkill = 7
		uespLog.DebugLogMsg(".     Logging only race abilities...")
	end
	
	logData.event = "skillDump::StartType"
	logData.apiVersion = GetAPIVersion()
	logData.note = note
	logData.classOnly = classOnly
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	for skillType = startSkill, endSkill do
	
		if (skillType > 1 and classOnly and raceOnly) then
			skillType = 7
		end
			
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		logData = { }
		logData.event = "skillType"
		logData.class = GetUnitClass("player")
		logData.race = GetUnitRace("player")
		logData.classId = GetUnitClassId("player")
		logData.skillType = skillType
		logData.skillName = skillTypeName
		logData.numSkillLines = numSkillLines
		
		uespLog.AppendDataToLog("all", logData)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
			
			logData = { }
			logData.event = "skillLine"
			logData.skillType = skillType
			
			if (skillType == 1) then
				logData.class = GetUnitClass("player")
			elseif (skillType == 7) then
				logData.race = GetUnitRace("player")
			end
			
			logData.xpString = "0"
			logData.numRanks = 1
		
			for i = 1, 70 do
				local startXP, nextRankStartXP = GetSkillLineRankXPExtents(skillType, skillIndex, i)
				
				if (startXP == nil or nextRankStartXP == nil) then 
					break
				end
				
				logData.xpString = logData.xpString .. "," .. tostring(nextRankStartXP)
				logData.numRanks = logData.numRanks + 1
			end
			
			logData.skillIndex = skillIndex
			logData.numAbilities = numSkillAbilities
			logData.name = GetSkillLineInfo(skillType, skillIndex)
			uespLog.AppendDataToLog("all", logData)
			
			for abilityIndex = 1, numSkillAbilities do
				local progressionIndex
				count = count + 1
				
				logData = { }
				logData.event = "skillAbility"
				logData.skillType = skillType
				
				if (skillType == 1) then
					logData.class = GetUnitClass("player")
				elseif (skillType == 7) then
					logData.race = GetUnitRace("player")
				end
				
				logData.skillIndex = skillIndex
				logData.abilityIndex = abilityIndex
				logData.name, logData.texture, logData.rank, logData.passive, logData.ultimate, logData.purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				logData.abilityId1 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				logData.abilityId2 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, true)
				logData.level, logData.maxLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				if (logData.level == nil) then logData.level = 1 end
				if (logData.maxLevel == nil) then logData.maxLevel = 1 end
				uespLog.AppendDataToLog("all", logData)
			end
		end
		
		if (classOnly) then
			if (raceOnly) then
				numSkillTypes = 1
				uespLog.DebugLogMsg(".     Logging only class abilities...")
			end
		end
	end
	
	uespLog.DebugMsg(".     Found "..tostring(count).." abilities by type!")
	
	logData = { }
	logData.event = "skillDump::EndType"
	logData.count = count
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.DumpLearnedAbilities(note)
	local logData = { }
	local count = 0
	local level = 0
	
	uespLog.DebugLogMsg("Logging learned abilities...")
	
	logData.event = "skillDump::StartLearned"
	logData.apiVersion = GetAPIVersion()
	logData.note = note
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	for level = 0, 70 do
		local learnedIndex
		local numLearned = GetNumAbilitiesLearnedForLevel(level, false)
		
		for learnedIndex = 1, numLearned do
			logData = { }
			
			logData.event = "skillLearned"
			logData.progress = 0
			logData.level = level
			logData.name, logData.texture, logData.abilityIndex, logData.progressionIndex = GetLearnedAbilityInfoForLevel(level, learnedIndex, false)
			logData.id = GetAbilityIdByIndex(logData.abilityIndex)
			uespLog.AppendDataToLog("all", logData)
			
			count = count + 1
		end
	end

	uespLog.DebugMsg(".     Found "..tostring(count).." learned abilities!")
	
	logData = { }
	logData.event = "skillDump::EndLearned"
	logData.count = count
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.DumpSkillsProgression(note, classOnly)
	local logData = { }
	local progressionIndex = 0
	local count = 0
	
	uespLog.DebugLogMsg("Logging skill progressions...")
	
		-- Doesn't work as GetSkillAbilityIndicesFromProgressionIndex() doesn't seem to work correctly
	classOnly = classOnly or false
	
	logData.event = "skillDump::StartProgression"
	logData.apiVersion = GetAPIVersion()
	logData.note = note
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())

	for progressionIndex = 1, 1000 do
		local name, morph, rank = GetAbilityProgressionInfo(progressionIndex)
		
		if (name == "" or morph < 0 or rank < 0) then
			break
		end
				
		logData = { }
		logData.event = "skillProgression"
		logData.name = name
		logData.index = progressionIndex
		
			-- NOTE: The abilityIndex# returned by this function doesn't appear to be correct
		logData.name0, logData.texture0, logData.abilityIndex0 = GetAbilityProgressionAbilityInfo(progressionIndex, 0, 1)
		logData.name1, logData.texture1, logData.abilityIndex1 = GetAbilityProgressionAbilityInfo(progressionIndex, 1, 1)
		logData.name2, logData.texture2, logData.abilityIndex2 = GetAbilityProgressionAbilityInfo(progressionIndex, 2, 1)
		
			-- NOTE: This function doesn't seem to return the correct values
		logData.skillType, logData.skillIndex, logData.abilityIndex = GetSkillAbilityIndicesFromProgressionIndex(progressionIndex)
		
		logData.id01 = GetAbilityProgressionAbilityId(progressionIndex, 0, 1)
		logData.id02 = GetAbilityProgressionAbilityId(progressionIndex, 0, 2)
		logData.id03 = GetAbilityProgressionAbilityId(progressionIndex, 0, 3)
		logData.id04 = GetAbilityProgressionAbilityId(progressionIndex, 0, 4)
		logData.id11 = GetAbilityProgressionAbilityId(progressionIndex, 1, 1)
		logData.id12 = GetAbilityProgressionAbilityId(progressionIndex, 1, 2)
		logData.id13 = GetAbilityProgressionAbilityId(progressionIndex, 1, 3)
		logData.id14 = GetAbilityProgressionAbilityId(progressionIndex, 1, 4)
		logData.id21 = GetAbilityProgressionAbilityId(progressionIndex, 2, 1)
		logData.id22 = GetAbilityProgressionAbilityId(progressionIndex, 2, 2)
		logData.id23 = GetAbilityProgressionAbilityId(progressionIndex, 2, 3)
		logData.id24 = GetAbilityProgressionAbilityId(progressionIndex, 2, 4)
		
		uespLog.AppendDataToLog("all", logData)
		count = count + 1
	end
	
	uespLog.DebugMsg(".     Found "..tostring(count).." skill progressions!")
	
	logData = { }
	logData.event = "skillDump::EndProgression"
	logData.count = count
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())	
end


function uespLog.DumpSkillsStart(note)
	local abilityId
	local endId =  80000
	local validAbilityCount = 0
	local logData = { }
	
	logData.event = "skillDump::Start"
	logData.apiVersion = GetAPIVersion()
	logData.note = note
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	uespLog.DebugLogMsg("Logging all skills with note '"..tostring(note).."'...")

	for abilityId = 1, endId do
		if (DoesAbilityExist(abilityId)) then
			validAbilityCount = validAbilityCount + 1
			uespLog.DumpSkill(abilityId)
		end
	end

	uespLog.DebugMsg("    Logged "..tostring(validAbilityCount).." abilities...")
	
	logData = { }
	logData.event = "skillDump::End"
	logData.abilityCount = validAbilityCount
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	return true
end


function uespLog.DumpSkill(abilityId)
-- GetAbilityInfoByIndex(integer abilityIndex) Returns: string name, string texture, integer rank, integer actionSlotType, boolean passive, boolean showInSpellbook
-- GetAbilityIdByIndex(integer abilityIndex) Returns: integer abilityId
-- GetChampionAbilityDescription(integer abilityId, integer numPendingPoints) Returns: string description
-- GetChampionAbilityId(integer disciplineIndex, integer skillIndex) Returns: integer abilityId
	local name = GetAbilityName(abilityId)
	local isPassive = IsAbilityPassive(abilityId)
	local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId)
	local targetDesc = GetAbilityTargetDescription(abilityId)
	local minRange, maxRange = GetAbilityRange(abilityId)
	local radius = GetAbilityRadius(abilityId)
	local angleDistance = GetAbilityAngleDistance(abilityId)
	local duration = GetAbilityDuration(abilityId)
	local cost, mechanic = GetAbilityCost(abilityId)
	local descHeader = GetAbilityDescriptionHeader(abilityId)
	local description = GetAbilityDescription(abilityId)
	local upgradeLines = uespLog.FormatSkillUpgradeLines(GetAbilityUpgradeLines(abilityId))
	local effectLines = uespLog.FormatSkillEffectLines(GetAbilityNewEffectLines(abilityId))
	local logData = { }
	
	logData.event = "skill"
	logData.id = abilityId
	logData.name = name
	logData.passive = isPassive
	logData.channel = channeled
	logData.castTime = castTime
	logData.channelTime = channelTime
	logData.target = targetDesc
	logData.minRange = minRange
	logData.maxRange = maxRange
	logData.radius = radius
	logData.angleDistance = angleDistance
	logData.duration = duration
	logData.cost = cost
	logData.mechanic = mechanic
	logData.desc = tostring(descHeader) .. tostring(description)
	logData.icon = GetAbilityIcon(abilityId)
	
	if (upgradeLines and upgradeLines ~= "") then logData.upgradeLines = upgradeLines end
	if (effectLines and effectLines ~= "") then logData.effectLines = effectLines end
	
	uespLog.AppendDataToLog("all", logData)
end


function uespLog.FormatSkillUpgradeLines(...)
	local output = ""
	
    local numUpgradeReturns = select("#", ...)
	
    if (numUpgradeReturns > 0) then
	
        for i = 1, numUpgradeReturns, 3 do
            local label, oldValue, newValue = select(i, ...)
            if (i > 1) then output = output .. ", " end
			output = output .. tostring(label) .."::"..tostring(oldValue).."::"..tostring(newValue)
        end
		
    end
	
	return output
end


function uespLog.FormatSkillEffectLines(...)
	local output = ""
	
    local numEffectLines = select("#", ...)
	
    if (numEffectLines > 0) then
	
        for i = 1, numEffectLines do
            local newEffect = select(i, ...)
            if (i > 1) then output = output .. ", " end
			output = output .. tostring(newEffect)
        end
		
    end
	
	return output
end


function uespLog.DumpSkillsBasic()
	--GetNumAbilities() Returns: integer num
	--GetAbilityInfoByIndex(integer abilityIndex) Returns: string name, string texture, integer rank, integer actionSlotType, boolean passive, boolean showInSpellbook
	--GetNumAbilitiesLearnedForLevel(integer level, boolean progression) Returns: integer abilitiesLearned
	--GetLearnedAbilityInfoForLevel(integer level, integer learnedIndex, boolean progression) Returns: string name, string texture, integer abilityIndex, integer progressionIndex
	--PlayerHasAttributeUpgrades() Returns: boolean hasLevelUpgrades
	--ChooseAbilityProgressionMorph(integer progressionIndex, integer morph)
	
	--GetAbilityProgressionInfo(integer progressionIndex) Returns: string name, integer morph, integer rank
	--GetAbilityProgressionXPInfo(integer progressionIndex) Returns: integer lastRankXp, integer nextRankXP, integer currentXP, boolean atMorph
	--GetAbilityProgressionAbilityInfo(integer progressionIndex, integer morph, integer rank) Returns: string name, string texture, integer abilityIndex
	--GetAbilityProgressionRankFromAbilityId(integer abilityId) Returns: integer:nilable rank
	--GetAbilityProgressionXPInfoFromAbilityId(integer abilityId) Returns: boolean hasProgression, integer progressionIndex, integer lastRankXp, integer nextRankXP, integer currentXP, boolean atMorph
	--GetAttributeDerivedStatPerPointValue(integer attribute, integer stat) Returns: number amountPerPoint
	
	--GetAbilityIdByIndex(integer abilityIndex) Returns: integer abilityId
	
	--DoesAbilityExist(integer abilityId) Returns: boolean exists
	--GetAbilityProgressionRankFromAbilityId(integer abilityId) Returns: integer:nilable rank
	--GetAbilityProgressionXPInfoFromAbilityId(integer abilityId) Returns: boolean hasProgression, integer progressionIndex, integer lastRankXp, integer nextRankXP, integer currentXP, boolean atMorph
	
	local numAbilities = GetNumAbilities()
	local abilityIndex 
	local abilityId
	local validAbilityCount = 0
	local firstAbility = -1
	local lastAbility = -1
	
	uespLog.DebugMsg("Dumping Basic Skill Info...")
	uespLog.DebugMsg("    "..tostring(numAbilities).." Character Abilities")
	
	--for abilityIndex = 1, numAbilities do
		--local name, texture, rank, slotType, passive, showInSpellBook = GetAbilityInfoByIndex(abilityIndex)
		--uespLog.DebugMsg("       "..tostring(abilityIndex)..": "..tostring(name).." "..tostring(passive).." "..tostring(slotType).." "..tostring(showInSpellBook))
	--end
	
	for abilityId = 1, 99000 do
		if (DoesAbilityExist(abilityId)) then
			lastAbility = abilityId
			validAbilityCount = validAbilityCount + 1
			if (firstAbility < 0) then firstAbility = abilityId end
			
			local t1 = uespLog.CountVarReturns(GetAbilityUpgradeLines(abilityId))
			local t2 = uespLog.CountVarReturns(GetAbilityNewEffectLines(abilityId))
			
			if (t1 > 0 or t2 > 0) then
				--uespLog.DebugMsg("     "..tostring(abilityId).." upgrades "..tostring(t1).."  effects "..tostring(t2))
			end
		end
	end
	
	uespLog.DebugMsg("     Found "..tostring(validAbilityCount).." abilities overall.")
	uespLog.DebugMsg("     First at "..tostring(firstAbility).." , last at "..tostring(lastAbility))
	
	return true
end


function uespLog.CountVarReturns(...)
    local numReturns = select("#", ...)
	return numReturns
end


uespLog.countVariable = function(object)
	local size = 0
	local count = 0
	
	if (object == nil) then
		return 0, 0
	end
	
	for k, v in pairs(object) do
		count = count + 1
		
		if (type(v) == "string") then
			size = size + #v + 16
		elseif (type(v) == "number") then
			size = size + 4
		end
	end
	
	return count, size
end


uespLog.countSection = function(section)
	local size = 0
	local count = 0
	
	if (uespLog.savedVars[section] ~= nil) then
		count, size = uespLog.countVariable(uespLog.savedVars[section].data)
	end
	
	uespLog.Msg("UESP:: Section \"" .. tostring(section) .. "\" has " .. tostring(count) .. " records taking up " .. string.format("%.2f", size/1000000) .. " MB")
	
	return count, size
end


function uespLog.GetSectionCounts(section)
	local size = 0
	local count = 0
	
	if (uespLog.savedVars[section] ~= nil) then
		count, size = uespLog.countVariable(uespLog.savedVars[section].data)
	end

	return count, size
end


function uespLog.GetTraitCounts(craftingSkillType)
	local numLines = GetNumSmithingResearchLines(craftingSkillType)
	local numTraitItems = GetNumSmithingTraitItems()
	local tradeName = uespLog.GetCraftingName(craftingSkillType)
	local totalTraits = 0
	local totalKnown = 0
	
	for researchLineIndex = 1, numLines do
		local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingSkillType, researchLineIndex)
	
		for traitIndex = 1, numTraits do
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
			
			if (traitType ~= nil and traitType ~= 0) then
			
				if (known) then
					totalKnown = totalKnown + 1
				end
				
				totalTraits = totalTraits + 1
			end
		end
	end

	return totalTraits, totalKnown
end


function uespLog.countTraits(craftingSkillType)
	local numLines = GetNumSmithingResearchLines(craftingSkillType)
	local numTraitItems = GetNumSmithingTraitItems()
	local tradeName = uespLog.GetCraftingName(craftingSkillType)
	local totalTraits = 0
	local totalKnown = 0
	
	for researchLineIndex = 1, numLines do
		local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingSkillType, researchLineIndex)

	    uespLog.MsgColor(uespLog.traitColor, "UESP::Traits for "..tradeName.."::"..tostring(name))
	
		for traitIndex = 1, numTraits do
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
			
			if (traitType ~= nil and traitType ~= 0) then
				local knownStr = "not known"
			
				if (known) then
					knownStr = "known"
					uespLog.MsgColor(uespLog.traitColor, ".       "..uespLog.GetItemTraitName(traitType).." is "..knownStr)
					totalKnown = totalKnown + 1
				else
				end
				
				totalTraits = totalTraits + 1
			end
		end
	end

	uespLog.MsgColor(uespLog.traitColor, ".  You know "..totalKnown.." of "..totalTraits.." "..tradeName.." traits.")
end


SLASH_COMMANDS["/uespcount"] = function(cmd)

	if (cmd == "recipes") then
		uespLog.CountRecipes()
		return
	elseif (cmd == "achievements") then
		uespLog.CountAchievements()
		return
	elseif (cmd == "inspiration") then
		uespLog.MsgColor(uespLog.countColor, "You have accumulated "..tostring(uespLog.GetTotalInspiration()).." crafting inspiration since the last reset")
		return
	elseif (cmd == "traits") then
		uespLog.countTraits(CRAFTING_TYPE_BLACKSMITHING)
		uespLog.countTraits(CRAFTING_TYPE_CLOTHIER)
		uespLog.countTraits(CRAFTING_TYPE_WOODWORKING)
		return
	end
	
	local count1, size1 = uespLog.countSection("all")
	local count2, size2 = uespLog.countSection("globals")
	local count3, size3 = uespLog.countSection("achievements")
	local count = count1 + count2 + count3
	local size = size1 + size2 + size3
	
	uespLog.MsgColor(uespLog.countColor, "UESP:: Total of " .. tostring(count) .. " records taking up " .. string.format("%.2f", size/1000000) .. " MB")
end


SLASH_COMMANDS["/uesphelp"] = function(cmd)
	uespLog.Msg("UESP::uespLog Addon v".. tostring(uespLog.version) .. " released ".. uespLog.releaseDate)
	uespLog.Msg("UESP::This add-on logs a variety of data to the saved variables folder.")
	uespLog.Msg("    /uespset      Access the add-on's settings menu")
	uespLog.Msg("    /uesplog      Turns the logging of data on and off")
	uespLog.Msg("    /uespcount    Displays statistics on the current log")
	uespLog.Msg("    /uespreset    Clears all or part of the logged data")
	uespLog.Msg("    /uespdebug    Turns the debug messages on and off")
	uespLog.Msg("    /uespdump     Outputs a variety of data to the log")
	uespLog.Msg("    /uesptime     Displays the various game times")
	uespLog.Msg("    /uespresearch Shows info on crafting research timers")
	uespLog.Msg("    /uespcolor    Turns color messages on and off")
	uespLog.Msg("    /loc          Displays your current location")
end


function uespLog.LogInventoryItem (bagId, slotIndex, event, extraData)
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
	local itemName = GetItemName(bagId, slotIndex)
	--local itemTrait = GetItemTrait(bagId, slotIndex)
	--local itemType = GetItemType(bagId, slotIndex)
	local icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(bagId, slotIndex)
	--local usedInCraftingType, craftItemType, extraInfo1, extraInfo2, extraInfo3 = GetItemCraftingInfo(bagId, slotIndex)
	local logData = { }

	if (tostring(itemName) == "") then
		return false
	end
		
	uespLog.lastItemLink = itemLink
	uespLog.lastItemLinks[itemName] = itemLink
	
	if (extraData == nil) then
		extraData = { }
	end
	
	extraData.itemStyle = itemStyle
	extraData.icon = icon
	extraData.locked = locked
	extraData.stack = stack
	extraData.bag = bagId
	extraData.slot = slotIndex
	
	uespLog.LogItemLink(itemLink, event, extraData)
	
	--[[ old log data
	logData.event = event
	logData.itemLink = itemLink
	logData.trait = itemTrait
	logData.type = itemType
	logData.icon = icon
	logData.value = sellPrice
	logData.locked = locked
	logData.equipType = equipType
	logData.itemStyle = itemStyle
	logData.quality = quality
	logData.craftType = craftItemType
	logData.qnt = stack
	logData.bag = bagId
	logData.slot = slotIndex
	
	uespLog.AppendDataToLog("all", logData, extraData) --]]

	return true
end


uespLog.ITEMCHANGE_IGNORE_FIELDS = { 
	['level'] = 1,  
	['reqLevel'] = 1, 
	['reqVetLevel'] = 1, 
	['quality'] = 1,
	['itemLink'] = 1,	
}


function uespLog.DoesItemChangeWithLevelQuality (itemId)
	local itemLink1 = uespLog.MakeItemLink(itemId, 1, 1)
	local itemLink2 = uespLog.MakeItemLink(itemId, 50, 312)
	local itemLog1 = uespLog.CreateItemLinkLog(itemLink1)
	local itemLog2 = uespLog.CreateItemLinkLog(itemLink2)
	
	local itemDiff = uespLog.CompareItemLogs(itemLog1, itemLog2)
	
	for k, v in pairs(itemDiff) do
		if (uespLog.ITEMCHANGE_IGNORE_FIELDS[k] == nil) then
			return true
		end
	end
		
	return false
end


function uespLog.CompareItemLinks (itemLink1, itemLink2)
	local itemLog1 = uespLog.CreateItemLinkLog(itemLink1)
	local itemLog2 = uespLog.CreateItemLinkLog(itemLink2)
	return uespLog.CompareItemLogs(itemLog1, itemLog2)
end


function uespLog.CompareItemLogs (itemLog1, itemLog2)
	local diffItem = { }

	for k, v in pairs(itemLog1) do
		if (v ~= itemLog2[k]) then
			diffItem[k] = itemLog2[k]
		end
	end
	
	for k, v in pairs(itemLog2) do
		if (itemLog1[k] == nil) then
			diffItem[k] = v
		end
	end
	
	return diffItem
end


function uespLog.CreateItemLinkLog (itemLink)
	local enchantName, enchantDesc
	local useAbilityName, useAbilityDesc, cooldown
	local traitText
	local setName, numSetBonuses
	local bookTitle
	local craftSkill
	local siegeType
	local hasCharges, hasEnchant, hasUseAbility, hasArmorDecay, isSetItem, isCrafted, isVendorTrash, isUnique, isUniqueEquipped
	local isConsumable, isRune
	local flagString = ""
	local flavourText
	local logData = { }
	
	logData.itemLink = itemLink
	
	logData.name = GetItemLinkName(itemLink)
	logData.type = GetItemLinkItemType(itemLink)
	logData.icon, _, _, _, logData.itemStyle = GetItemLinkInfo(itemLink)
	logData.equipType = GetItemLinkEquipType(itemLink)
	logData.weaponType = GetItemLinkWeaponType(itemLink)
	logData.armorType = GetItemLinkArmorType(itemLink)
	logData.weaponPower = GetItemLinkWeaponPower(itemLink)
	logData.armorRating = GetItemLinkArmorRating(itemLink, false)
	logData.reqLevel = GetItemLinkRequiredLevel(itemLink)
	logData.reqVetLevel = GetItemLinkRequiredVeteranRank(itemLink)
	logData.value = GetItemLinkValue(itemLink, false)
	logData.condition = GetItemLinkCondition(itemLink)
	
	hasArmorDecay = DoesItemLinkHaveArmorDecay(itemLink)
	if (hasArmorDecay) then flagString = flagString .. "ArmorDecay " end
	
	hasCharges = DoesItemLinkHaveEnchantCharges(itemLink)
	
	if (hasCharges) then
		logData.maxCharges = GetItemLinkMaxEnchantCharges(itemLink)
	end
	
	hasEnchant, enchantName, enchantDesc = GetItemLinkEnchantInfo(itemLink)
	
	if (hasEnchant) then
		logData.enchantName = enchantName
		logData.enchantDesc = enchantDesc
	end
	
	hasUseAbility, useAbilityName, useAbilityDesc, cooldown = GetItemLinkOnUseAbilityInfo(itemLink)
	
	if (hasUseAbility) then
		logData.useAbilityName = useAbilityName
		logData.useAbilityDesc = useAbilityDesc
		logData.useCooldown = cooldown
	end
	
	logData.trait, logData.traitDesc = GetItemLinkTraitInfo(itemLink)
	local isSetItem, setName, numSetBonuses, numSetEquipped, maxSetEquipped = GetItemLinkSetInfo(itemLink)
	
	if (logData.traitDesc == "") then
		logData.traitDesc = nil
	end
	
	if (isSetItem) then
		logData.setName = setName
		logData.setBonusCount = numSetBonuses
		logData.setMaxCount = maxSetEquipped
		local i
		
		for i = 1, numSetBonuses do
			local setBonusRequired, setBonusDesc = GetItemLinkSetBonusInfo(itemLink, NOT_EQUIPPED, i)
			logData["setBonus"..tostring(i)] = tostring(setBonusRequired)
			logData["setDesc"..tostring(i)] = tostring(setBonusDesc)
		end
	end
	
	flavourText = GetItemLinkFlavorText(itemLink)
	if (flavourText ~= "") then logData.flavourText = flavourText end
		
	isCrafted = IsItemLinkCrafted(itemLink)
	if (isCrafted) then flagString = flagString .. "Crafted " end
	
	isVendorTrash = IsItemLinkVendorTrash(itemLink)
	if (isVendorTrash) then flagString = flagString .. "Vendor " end
	
	siegeType = GetItemLinkSiegeType(itemLink)
	
	if (siegeType > 0) then
		logData.siegeType = siegeType
		logData.maxSiegeHP = GetItemLinkSiegeMaxHP(itemLink)
	end
	
	logData.quality = GetItemLinkQuality(itemLink)
	
	isUnique = IsItemLinkUnique(itemLink)
	if (isUnique) then flagString = flagString .. "Unique " end
	
	isUniqueEquipped = IsItemLinkUniqueEquipped(itemLink)
	if (isUniqueEquipped) then flagString = flagString .. "UniqueEquipped " end
	
	isConsumable = IsItemLinkConsumable(itemLink)
	if (isConsumable) then flagString = flagString .. "Consumable " end
	
	isRune = IsItemLinkEnchantingRune(itemLink)
			
	if (isRune) then
		runeKnown, logData.runeName = GetItemLinkEnchantingRuneName() 
		logData.runeType = GetItemLinkEnchantingRuneClassification(itemLink)
		logData.runeRank = GetItemLinkRequiredCraftingSkillRank(itemLink)		
	end
	
	craftSkill = GetItemLinkCraftingSkillType(itemLink)
	
	if (craftSkill > 0) then 
		logData.craftSkill = craftSkill 
	end
	
	requiredQuality = GetItemLinkRecipeQualityRequirement(itemLink)
	
	if (requiredQuality > 0) then
		logData.recipeQuality = requiredQuality
	end
	
	requiredRank = GetItemLinkRecipeRankRequirement(itemLink)
	
	if (requiredRank > 0) then
		logData.recipeRank = requiredRank
	end
	
	resultItemLink = GetItemLinkRecipeResultItemLink(itemLink)
	
	if (resultItemLink ~= nil and resultItemLink ~= "") then
		logData.recipeLink = resultItemLink
	end
	
	refinedItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)
	
	if (refinedItemLink ~= nil and refinedItemLink ~= "") then
		logData.refinedItemLink = refinedItemLink
	end
	
	craftSkillRank = GetItemLinkRequiredCraftingSkillRank(itemLink)
	
	if (craftSkillRank ~= nil and requiredRank > 0) then
		logData.craftSkillRank = craftSkillRank
	end
	
	local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
	
	for i = 1, numIngredients do
		local ingredientName, numOwned = GetItemLinkRecipeIngredientInfo(itemLink, i)
		logData["ingrName"..tostring(i)] = ingredientName
	end
	
	--logData.isBound = IsItemLinkBound(itemLink)
	logData.bindType = GetItemLinkBindType(itemLink)

	local glyphMinLevel, glyphMaxLevel, glyphMinVetLevel, glyphMaxVetLevel = GetItemLinkGlyphMinMaxLevels(itemLink)
	
	if (glyphMinLevel ~= nil and glyphMaxLevel ~= nil) then
		logData.minGlyphLevel = glyphMinLevel
		logData.maxGlyphLevel = glyphMaxLevel
	elseif (glyphMinVetLevel ~= nil and glyphMaxVetLevel ~= nil) then
		logData.minGlyphLevel = glyphMinVetLevel + 49
		logData.maxGlyphLevel = glyphMaxVetLevel + 49
	elseif (glyphMinLevel ~= nil and glyphMaxVetLevel ~= nil) then
		logData.minGlyphLevel = glyphMinLevel
		logData.maxGlyphLevel = glyphMaxVetLevel + 49
	end
	
	local traitAbilityCount = 0
	
	for i = 1, GetMaxTraits() do
		local hasTraitAbility, traitAbilityDescription, traitCooldown = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
		
		if (hasTraitAbility) then
			traitAbilityCount = traitAbilityCount + 1
			logData["traitAbility" .. tostring(traitAbilityCount) ] = traitAbilityDescription
			logData["traitCooldown" .. tostring(traitAbilityCount) ] = traitCooldown
		end
	end

	local levelsDescription = GetItemLinkMaterialLevelDescription(itemLink)
	
	if (levelsDescription ~= nil and levelsDescription ~= "") then
		logData.matLevelDesc = levelsDescription
	end
	
	bookTitle = GetItemLinkBookTitle(itemLink)
	--logData.isBookKnown = IsItemLinkBookKnown(itemLink)
	
	if (bookTitle ~= "") then
		logData.bookTitle = bookTitle
	end
	
	--GetItemLinkInfo()
	--local known, name = GetItemLinkReagentTraitInfo(itemLink, traitIndex) 
	
	if (flagString ~= "") then
		logData.flag = flagString
	end
	
	return logData
end

	
function uespLog.LogItemLink (itemLink, event, extraData)
	local logData = uespLog.CreateItemLinkLog(itemLink)
	logData.event = event
	uespLog.AppendDataToLog("all", logData, extraData)
end


function uespLog.LogItemLinkShort (itemLink, event, extraData)
	local enchantName, enchantDesc
	local useAbilityName, useAbilityDesc, cooldown
	local traitText
	local setName, numSetBonuses
	local bookTitle
	local logData = { }
	local craftSkill
	local siegeType
	local hasCharges, hasEnchant, hasUseAbility, hasArmorDecay, isSetItem, isCrafted, isVendorTrash, isUnique, isUniqueEquipped
	local isConsumable, isRune
	local flagString = ""
	local flavourText
	
	logData.event = event
	logData.itemLink = itemLink
	
	logData.weaponPower = GetItemLinkWeaponPower(itemLink)
	logData.armorRating = GetItemLinkArmorRating(itemLink, false)
	logData.reqLevel = GetItemLinkRequiredLevel(itemLink)
	logData.reqVetLevel = GetItemLinkRequiredVeteranRank(itemLink)
	logData.value = GetItemLinkValue(itemLink, false)
	logData.condition = GetItemLinkCondition(itemLink)
		
	hasCharges = DoesItemLinkHaveEnchantCharges(itemLink)
	
	if (hasCharges) then
		logData.maxCharges = GetItemLinkMaxEnchantCharges(itemLink)
	end
	
	hasEnchant, enchantName, enchantDesc = GetItemLinkEnchantInfo(itemLink)
	
	if (hasEnchant) then
		logData.enchantName = enchantName
		logData.enchantDesc = enchantDesc
	end
	
	hasUseAbility, useAbilityName, useAbilityDesc, cooldown = GetItemLinkOnUseAbilityInfo(itemLink)
	
	if (hasUseAbility) then
		logData.useAbilityName = useAbilityName
		logData.useAbilityDesc = useAbilityDesc
		logData.useCooldown = cooldown
	end
	
	isSetItem, setName, numSetBonuses = GetItemLinkSetInfo(itemLink)
	
	if (logData.isSetItem) then
		logData.setName = setName
		logData.setBonusCount = numSetBonuses
		local i
		
		for i = 1, numSetBonuses do
			local setBonusRequired, setBonusDesc = GetItemLinkSetBonusInfo(itemLink, NOT_EQUIPPED, i)
			logData["setBonus"..tostring(i)] = tostring(setBonusRequired)
			logData["setDesc"..tostring(i)] = tostring(setBonusDesc)
		end
	end

	siegeType = GetItemLinkSiegeType(itemLink)
	
	if (siegeType > 0) then
		logData.maxSiegeHP = GetItemLinkSiegeMaxHP(itemLink)
	end
	
	logData.quality = GetItemLinkQuality(itemLink)
	
	--logData.isBound = IsItemLinkBound(itemLink)
	--logData.bindType = GetItemLinkBindType(itemLink)

	--logData.glyphMinLevel, logData.glyphMaxLevel, logData.glyphMinVetLevel, logData.glyphMaxVetLevel = GetItemLinkGlyphMinMaxLevels(itemLink)
	--logData.isBookKnown = IsItemLinkBookKnown(itemLink)
	
	uespLog.AppendDataToLog("all", logData, extraData)
end


function uespLog.DumpBag (bagId)
	local bagSlots = GetBagSize(bagId)
	local slotCount = 0
		
	for slotIndex = 1, bagSlots do
		local result = uespLog.LogInventoryItem(bagId, slotIndex, "InvDump")
		
		if (result) then
			slotCount = slotCount + 1
		end
	end
	
	return slotCount
end


function uespLog.DumpInventory ()
	local maxBags = GetMaxBags()
	local slotCount = 0
	
	local logData = { }
	logData.event = "InvDumpStart"
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	slotCount = slotCount + uespLog.DumpBag(BAG_WORN)	   --0
	slotCount = slotCount + uespLog.DumpBag(BAG_BACKPACK)  --1
	slotCount = slotCount + uespLog.DumpBag(BAG_BANK)	   --2
	slotCount = slotCount + uespLog.DumpBag(BAG_BUYBACK)   --3
	slotCount = slotCount + uespLog.DumpBag(BAG_GUILDBANK) --4
	
	logData = { }
	logData.event = "InvDumpEnd"
	uespLog.AppendDataToLog("all", logData)
	
	uespLog.DebugMsg("UESP::Output ".. slotCount .." inventory items to log!");
end


function uespLog.GetAddress(obj)

	if type(obj) == "function" or type(obj) == "table" or type(obj) == "userdata" then
		return tostring(obj):match(": ([%u%d]+)")
	end
	
	return nil
end


function uespLog.DumpGlobalsIterateStart(maxLevel)
	local logData = {} 

	if (uespLog.dumpIterateEnabled) then
		uespLog.DebugMsg("UESP::Dump globals iteration already running!")
		return
	end
	
	if (maxLevel == nil) then
		maxLevel = 3
	elseif (maxLevel < 0) then
		maxLevel = 0
	elseif (maxLevel > 10) then
		maxLevel = 10
	end
	
	uespLog.savedVars["globals"].data = { }

	uespLog.dumpIterateNextIndex = _nil
	uespLog.dumpIterateObject = _G
	uespLog.dumpIterateStatus = 0
	uespLog.dumpIterateCurrentLevel = 0
	uespLog.countGlobal = 0
	uespLog.countGlobalError = 0
	uespLog.dumpIterateParentName = ""
	uespLog.dumpIterateMaxLevel = maxLevel
	uespLog.dumpMetaTable = { }
	uespLog.dumpIndexTable = { }
	uespLog.dumpTableTable = { }
	uespLog.dumpIterateEnabled = true
		
	uespLog.DebugMsg("UESP::Dumping globals iteratively to a depth of ".. tostring(uespLog.dumpIterateMaxLevel).."...")
	
	logData.event = "Global::Start"
	logData.niceDate = GetDate()
	logData.niceTime = GetTimeString()
	logData.apiVersion = GetAPIVersion() 
	uespLog.AppendDataToLog("globals", logData, uespLog.GetTimeData())

	zo_callLater(uespLog.DumpObjectIterate, uespLog.DUMP_ITERATE_TIMERDELAY)
end


function uespLog.DumpGlobalsIterateEnd()
	local logData = {} 

	if (not uespLog.dumpIterateEnabled) then
		uespLog.DebugMsg("UESP::Dump globals iteration not running!")
		return
	end

	logData.event = "Global::End"
	uespLog.AppendDataToLog("globals", logData, uespLog.GetTimeData())
	
	uespLog.dumpIterateEnabled = false
	uespLog.DebugMsg("UESP::Stopped dump globals iteration...")
	uespLog.DebugMsg("UESP::Found ".. tostring(uespLog.countGlobal) .." objects and ".. tostring(uespLog.countGlobalError) .." private functions...")
	
	local metaSize = 0
	local indexSize = 0
	local tableSize = 0
	
	for _ in pairs(uespLog.dumpMetaTable) do metaSize = metaSize + 1 end
	for _ in pairs(uespLog.dumpIndexTable) do indexSize = indexSize + 1 end
	for _ in pairs(uespLog.dumpTableTable) do tableSize = tableSize + 1 end
	
	uespLog.DebugMsg("UESP::Size of tables = "..tostring(metaSize) .. " / " .. tostring(indexSize) .. " / " ..tostring(tableSize))
end


function uespLog.DumpObjectInnerLoop(dumpObject, nextIndex, parentName, level, maxLevel)
	local skipMeta = false
	local skipTable = false
	local skipObject = false
	
	local status, tableIndex, value = pcall(next, dumpObject, nextIndex)
		
	if (tableIndex == nil) then
		return tableIndex
	end
	
	if (uespLog.dumpIgnoreObjects[tostring(tableIndex)] ~= nil) then
		skipObject = true
	end
			
	if (status and not skipObject) then
		skipTable, skipMeta = uespLog.DumpUpdateObjectTables(value)
	end
	
	if (not status) then
		tableIndex = uespLog.DumpObjectPrivate(tableIndex, value, parentName, level)
		uespLog.DebugExtraMsg("UESP::Error on dump object iteration...("..tostring(tableIndex)..")")
	elseif (skipObject) then
		uespLog.DebugExtraMsg("UESP::Skipping dump for object "..tostring(tableIndex))
	elseif (tableIndex == "__index" and uespLog.EndsWith(parentName, "__index")) then
		uespLog.DebugExtraMsg("UESP::Skipping dump for recursive __index")
	elseif type(value) == "table" then
		uespLog.DumpObjectTable(tableIndex, value, parentName, level)
		
		if (not skipTable and level < maxLevel) then
			uespLog.DumpObject(parentName, tableIndex, value, level+1, maxLevel)
		end
	elseif type(value) == "userdata" then		
		local indexTable = uespLog.GetIndexTable(value)
		
		uespLog.DumpObjectUserData(tableIndex, value, parentName, level)
		
		if (uespLog.dumpIterateUserTable and not skipMeta and indexTable ~= nil and level < maxLevel) then
			uespLog.DumpObject(parentName, tableIndex, indexTable, level+1, maxLevel)
		end

	elseif type(value) == "function" then
		uespLog.DumpObjectFunction(tableIndex, value, parentName, level)
	else
		uespLog.DumpObjectOther(tableIndex, value, parentName, level)
	end
	
	return tableIndex
end


function uespLog.DumpObjectIterate()
	local startCount = uespLog.countGlobal
	local startErrorCount = uespLog.countGlobalError
	local deltaCount

	if (not uespLog.dumpIterateEnabled) then
		return
	end
	
	uespLog.DebugExtraMsg("uespLog.DumpObjectIterate()")
	
	repeat
		local nextIndex = uespLog.DumpObjectInnerLoop(uespLog.dumpIterateObject, uespLog.dumpIterateNextIndex, uespLog.dumpIterateParentName, uespLog.dumpIterateCurrentLevel, uespLog.dumpIterateMaxLevel)
		
		if (nextIndex == nil) then
			uespLog.DumpGlobalsIterateEnd()
			return
		end
		
		deltaCount = uespLog.countGlobal - startCount
		uespLog.dumpIterateNextIndex = nextIndex

	until deltaCount >= uespLog.DUMP_ITERATE_LOOPCOUNT
	
	uespLog.DebugMsg("UESP::Dump iterate created "..tostring(uespLog.countGlobal-startCount).." logs with "..tostring(uespLog.countGlobalError-startErrorCount).." errors.")
	
	zo_callLater(uespLog.DumpObjectIterate, uespLog.DUMP_ITERATE_TIMERDELAY)
end


function uespLog.DumpObjectTable (objectName, objectValue, parentName, varLevel)
	local logData = { }
	
	logData.event = "Global"
	logData.label = "Public"
	logData.type = "table"
	logData.meta = uespLog.GetAddress(getmetatable(objectValue))
	--logData.index = uespLog.GetAddress(uespLog.GetIndexTable(objectValue))  -- Same as meta for tables
	logData.name = parentName .. tostring(objectName)
	logData.value = uespLog.GetAddress(objectValue)
	
	if (uespLog.dumpTableTable[logData.value] == 1) then
		logData.firstTable = 1
	end
	
	if (logData.meta and uespLog.dumpMetaTable[logData.meta] == 1) then
		logData.firstMeta = 1
	end
		
	if (uespLog.logDumpObject) then
		uespLog.AppendDataToLog("globals", logData)
	end
	
	if (uespLog.printDumpObject) then
		uespLog.DebugMsg("UESP:"..tostring(varLevel)..":table "..logData.name)
	end
	
	uespLog.countGlobal = uespLog.countGlobal + 1
end


function uespLog.DumpObjectUserData (objectName, objectValue, parentName, varLevel)
	local logData = { }
	
	logData.event = "Global"
	logData.label = "Public"
	logData.type = "userdata"
	logData.meta = uespLog.GetAddress(getmetatable(objectValue))
	logData.index = uespLog.GetAddress(uespLog.GetIndexTable(objectValue))
	logData.name = parentName .. tostring(objectName)
	logData.value = uespLog.GetAddress(objectValue)
	
	if (logData.meta and uespLog.dumpMetaTable[logData.meta] == 1) then
		logData.firstMeta = 1
	end
	
	if (logData.index and uespLog.dumpIndexTable[logData.index] == 1) then
		logData.firstIndex = 1
	end
	
	if (uespLog.logDumpObject) then
		uespLog.AppendDataToLog("globals", logData)
	end
	
	if (uespLog.printDumpObject) then
		uespLog.DebugMsg("UESP::userdata "..logData.name)
	end
	
	uespLog.countGlobal = uespLog.countGlobal + 1
end


function uespLog.DumpObjectFunction (objectName, objectValue, parentName, varLevel)
	local logData = {} 
	
	logData.event = "Global"
	logData.type = "function"
	logData.label = "Public"
	logData.value = uespLog.GetAddress(objectValue)
	logData.name = parentName .. tostring(objectName) .. "()"
	
	if (uespLog.logDumpObject) then
		uespLog.AppendDataToLog("globals", logData)
	end
	
	if (uespLog.printDumpObject) then
		uespLog.DebugMsg("UESP:"..tostring(varLevel)..":Function "..logData.name)
	end
	
	uespLog.countGlobal = uespLog.countGlobal + 1
end


function uespLog.DumpObjectOther (objectName, objectValue, parentName, varLevel)
	local objType = type(objectValue)
	local logData = {} 
	
	logData.event = "Global"
	logData.type = objType
	logData.label = "Public"
	logData.name = parentName .. tostring(objectName)
	logData.value = tostring(objectValue)
	
	if (objType == "number" and uespLog.BeginsWith(tostring(objectName), "SI_")) then
		logData.string = GetString(objectValue)
	end
		
	if (uespLog.logDumpObject) then
		uespLog.AppendDataToLog("globals", logData)
	end
	
	if (uespLog.printDumpObject) then
		uespLog.DebugMsg("UESP:"..tostring(varLevel)..":Global "..logData.name.." = "..tostring(value))
	end
	
	uespLog.countGlobal = uespLog.countGlobal + 1
end


function uespLog.DumpObjectPrivate (objectName, objectValue, parentName, varLevel)
	local errIndex = string.match(objectName, "attempt to access a private function '(%w*)' from")
	local logData = {} 
	
	logData.event = "Global"
	logData.label = "Private"
	logData.name = parentName .. tostring(errIndex) .. "()"
	
	if (uespLog.logDumpObject) then
		uespLog.AppendDataToLog("globals", logData)
	end
		
	if (uespLog.printDumpObject) then
		uespLog.DebugMsg("UESP:"..tostring(level)..":Private "..logData.name)
	else
		--uespLog.DebugExtraMsg(".     "..tostring(level)..":Private "..logData.name)
	end
	
	uespLog.countGlobal = uespLog.countGlobal + 1
	uespLog.countGlobalError = uespLog.countGlobalError + 1
	
	return errIndex
end


function uespLog.GetIndexTable(var)
	local metaTable = getmetatable(var)
	
	if (metaTable == nil) then
		return nil
	end
	
	return metaTable.__index
end


function uespLog.DumpUpdateObjectTables (value)
	local metaTable = getmetatable(value)
	local indexTable = uespLog.GetIndexTable(value)
	local metaAddress = uespLog.GetAddress(metaTable)
	local indexAddress = uespLog.GetAddress(indexTable)
	local tableAddress = uespLog.GetAddress(value)
	local skipTable = false
	local skipMeta = false
	
	if (tableAddress ~= nil) then
	
		if (uespLog.dumpTableTable[tableAddress] ~= nil) then
			skipTable = true
		end
		
		uespLog.dumpTableTable[tableAddress] = (uespLog.dumpTableTable[tableAddress] or 0) + 1
	end
	
	if (metaAddress ~= nil) then
	
		if (uespLog.dumpMetaTable[metaAddress] ~= nil) then
			skipMeta = true
		end
		
		uespLog.dumpMetaTable[metaAddress] = (uespLog.dumpMetaTable[metaAddress] or 0) + 1
	end
	
	if (indexAddress ~= nil) then
	
		if (uespLog.dumpIndexTable[indexAddress] ~= nil) then
			skipMeta = true
		end
		
		uespLog.dumpIndexTable[indexAddress] = (uespLog.dumpIndexTable[indexAddress] or 0) + 1
	end
	
	return skipTable, skipMeta
end


function uespLog.DumpObject(prefix, varName, a, level, maxLevel) 
	local parentPrefix = ""
	local tableIndex = nil
	
	if (prefix ~= "_G" and prefix ~= "") then
		parentPrefix = prefix
		
		if (not uespLog.EndsWith(prefix, ".")) then
			parentPrefix = parentPrefix .. "."
		end
	end	
	
	if (varName ~= "_G" and varName ~= "") then
		parentPrefix = parentPrefix .. tostring(varName) .. "."
	end	
	
	newLevel = level + 1
	
		-- Special case for the global object
	if (varName == "_G") then
		if (newLevel > 1) then
			return
		end
	elseif (uespLog.dumpIgnoreObjects[varName] ~= nil) then
		return
	end
	
	repeat
		tableIndex = uespLog.DumpObjectInnerLoop(a, tableIndex, parentPrefix, level, maxLevel)
	until tableIndex == nil
	
end


function uespLog.DumpGlobals (maxLevel, baseObject)
	
		-- Clear global object
	uespLog.savedVars["globals"].data = { }
	
	uespLog.countGlobal = 0
	uespLog.countGlobalError = 0
	uespLog.dumpMetaTable = { }
	uespLog.dumpIndexTable = { }
	uespLog.dumpTableTable = { }
	
	if (baseObject == nil) then
		baseObject = _G
	end
	
	if (maxLevel == nil) then
		maxLevel = 3
	elseif (maxLevel < 0) then
		maxLevel = 0
	elseif (maxLevel > 10) then
		maxLevel = 10
	end
	
	uespLog.DebugMsg("UESP::Dumping global objects to a depth of ".. tostring(maxLevel).."...")
	
	local logData = {} 
	logData.event = "Global::Start"
	logData.niceDate = GetDate()
	logData.niceTime = GetTimeString()
	logData.apiVersion = GetAPIVersion()
	uespLog.AppendDataToLog("globals", logData, uespLog.GetTimeData())
	
	uespLog.DumpObject("", "_G", baseObject, 0, maxLevel)
	
	logData = {} 
	logData.event = "Global::End"
	uespLog.AppendDataToLog("globals", logData, uespLog.GetTimeData())
		
	uespLog.DebugMsg("UESP::Output ".. tostring(uespLog.countGlobal) .." global objects and ".. tostring(uespLog.countGlobalError) .." private functions to log...")
end


function uespLog.DumpRecipe (recipeListIndex, recipeIndex, extraData)

	local known, recipeName, numIngredients, provisionerLevelReq, qualityReq, specialIngredientType = GetRecipeInfo(recipeListIndex, recipeIndex)
	local resultName, resultIcon, resultStack, resultSellPrice, resultQuality = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
	local resultLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex, LINK_STYLE_DEFAULT)
	local ingrCount = 0

	if (tostring(recipeName) == "") then
		return 0
	end
	
	logData = { }
	logData.event = "Recipe"
	logData.name = recipeName
	logData.numRecipes = numRecipes	
	logData.provLevel = provisionerLevelReq
	logData.numIngredients = numIngredients
	logData.quality = qualityReq
	logData.specialType = specialIngredientType
	uespLog.AppendDataToLog("all", logData, extraData)
	
	logData = { }
	logData.event = "Recipe::Result"
	logData.name = resultName
	logData.icon = resultIcon	
	logData.qnt = resultStack
	logData.value = resultSellPrice
	logData.quality = resultQuality
	logData.itemLink = resultLink
	uespLog.AppendDataToLog("all", logData, extraData)				
	
	for ingredientIndex = 1, numIngredients do
		local ingrName, ingrIcon, requiredQuantity, sellPrice, quality = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
		local itemLink = GetRecipeIngredientItemLink(recipeListIndex, recipeIndex, ingredientIndex, LINK_STYLE_DEFAULT)
		
		logData = { }
		logData.event = "Recipe::Ingredient"
		logData.name = ingrName
		logData.icon = ingrIcon	
		logData.qnt = requiredQuantity
		logData.value = sellPrice
		logData.quality = quality
		logData.itemLink = itemLink
		uespLog.AppendDataToLog("all", logData, extraData)	
		
		ingrCount = ingrCount + 1
	end
	
	return ingrCount
end	


function uespLog.DumpRecipes ()	
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local ingrCount = 0
	local logData = { }
	
	for recipeListIndex = 1, numRecipeLists do
		local name, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
		
		logData = { }
		logData.event = "Recipe::List"
		logData.name = name
		logData.numRecipes = numRecipes
		uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
		
		for recipeIndex = 1, numRecipes do
			ingrCount = ingrCount + uespLog.DumpRecipe(recipeListIndex, recipeIndex)
			recipeCount = recipeCount + 1
		end
	end
	
	logData = { }
	logData.event = "Recipe::End"
	uespLog.AppendDataToLog("all", logData)
	
	uespLog.DebugLogMsg("".. tostring(recipeCount) .." recipes with ".. tostring(ingrCount) .." total ingredients to log...")
end


function uespLog.GetRecipeCounts()
	local numRecipeLists = GetNumRecipeLists()
	local recipeCount = 0
	local knownCount = 0
	
	for recipeListIndex = 1, numRecipeLists do
		local name, numRecipes, upIcon, downIcon, overIcon, disabledIcon, createSound = GetRecipeListInfo(recipeListIndex)
		
		for recipeIndex = 1, numRecipes do
			local known = GetRecipeInfo(recipeListIndex, recipeIndex)
			recipeCount = recipeCount + 1
			
			if (known) then
				knownCount = knownCount + 1
			end
		end
	end
	
	return recipeCount, knownCount
end

	
function uespLog.CountRecipes()
	local recipeCount, knownCount = uespLog.GetRecipeCounts()
	uespLog.MsgColor(uespLog.countColor, "UESP::You know "..tostring(knownCount).."/"..tostring(recipeCount).." recipes.")	
end


function uespLog.GetAchievementCounts()
	local numCategories = GetNumAchievementCategories()
	local achCount = 0
	local completeCount = 0
	
	for categoryIndex = 1, numCategories do
		local categoryName, numSubCategories, numCateAchievements, earnedCatePoints, totalCatePoints, hidesCatePoints, normalIcon, pressedIcon, mouseoverIcon = GetAchievementCategoryInfo(categoryIndex)
		
		for subCategoryIndex = 1, numSubCategories do
			local subcategoryName, numsubCateAchievements, earnedSubCatePoints, totalSubCatePoints, hidesSubCatePoints = GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
						
			for achievementIndex = 1, numsubCateAchievements do
				local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
				local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
				achCount = achCount + 1
			
				if (achCompleted) then
					completeCount = completeCount + 1
				end
			end
		end
		
		for achievementIndex = 1, numCateAchievements do
			local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
			local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
			achCount = achCount + 1
		
			if (achCompleted) then
				completeCount = completeCount + 1
			end
		end
	end
	
	return achCount, completeCount
end
	
	
function uespLog.CountAchievements()	
	local achCount, completeCount = uespLog.GetAchievementCounts()
	uespLog.MsgColor(uespLog.countColor, "UESP::You have "..tostring(completeCount).."/"..tostring(achCount).." achievements.")	
end


if GetAchievementRewardInfo == nil then
   function GetAchievementRewardInfo(achievementId, rewardIndex)
      local rewards = {}

      local points = GetAchievementRewardPoints(achievementId)
      table.insert(rewards, {ACHIEVEMENT_REWARD_TYPE_POINTS, points})

      local hasRewardItem, itemName, iconTextureName, quality = GetAchievementRewardItem(achievementId)
      if hasRewardItem then
         table.insert(rewards, {ACHIEVEMENT_REWARD_TYPE_ITEM, itemName, iconTextureName, quality})
      end

      local hasRewardTitle, titleName = GetAchievementRewardTitle(achievementId)
      if hasRewardTitle then
         table.insert(rewards, {ACHIEVEMENT_REWARD_TYPE_TITLE, titleName})
      end

      local hasRewardDye, dyeIndex = GetAchievementRewardDye(achievementId)
      if hasRewardDye then
         table.insert(rewards, {ACHIEVEMENT_REWARD_TYPE_DYE, dyeIndex})
      end
      
      return unpack(rewards[rewardIndex])
   end
end


function uespLog.DumpAchievementPriv (categoryIndex, subCategoryIndex, achievementIndex)
	local achievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex)
	local achName, achDescription, achPoints, achIcon, achCompleted, achData, achTime = GetAchievementInfo(achievementId)
	local numRewards = GetAchievementNumRewards(achievementId)	
	local numCriteria = GetAchievementNumCriteria(achievementId)
	local rewardCount = 0
	local criteriaCount = 0
	local logData = { }	
	
	logData.event = "Achievement"
	logData.label = "Achievement"
	logData.description = achDescription
	logData.id = achievementId
	logData.points = achPoints
	logData.icon = achIcon
	logData.numRewards = numRewards
	logData.numCriteria = numCriteria
	uespLog.AppendDataToLog("achievements", logData)
					
	for rewardIndex = 1, numRewards do
		local rewardType, rewardPoints, rewardName, rewardIcon, rewardQuality = GetAchievementRewardInfo(achievementId, rewardIndex)
		local itemLink = ""
		local typeName = ""
							
		if (rewardType == ACHIEVEMENT_REWARD_TYPE_ITEM) then
			itemLink = GetAchievementItemLink(achievementId, rewardIndex, LINK_STYLE_DEFAULT)
			typeName = "item"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_TITLE) then
			typeName = "title"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_POINTS) then
			typeName = "points"
		elseif (rewardType == ACHIEVEMENT_REWARD_TYPE_NONE) then
			typeName = "none"
		end
		
		logData = { }
		logData.event = "Achievement"
		logData.label = "Reward"
		logData.type = typeName
		logData.name = rewardName
		logData.points = rewardPoints
		logData.icon = rewardIcon
		logData.quality = rewardQuality
		logData.itemLink = itemLink
		uespLog.AppendDataToLog("achievements", logData)
	
		rewardCount = rewardCount + 1
	end
	
	for criterionIndex = 1, numCriteria do
		local critDescription, critNumCompleted, critNumRequired = GetAchievementCriterion(achievementId, criterionIndex)
		
		logData = { }
		logData.event = "Achievement"
		logData.label = "Criteria"
		logData.description = critDescription
		logData.numRequired = critNumRequired
		uespLog.AppendDataToLog("achievements", logData)
		
		criteriaCount = criteriaCount + 1
	end

	return rewardCount, criteriaCount
end


function uespLog.DumpAchievements ()
	local numCategories = GetNumAchievementCategories()
	local outputCount = 0
	local rewardCount = 0
	local criteriaCount = 0
	local Msg = ""
	
		-- Clear achievements data
	uespLog.savedVars["achievements"].data = { }
	
	local logData = { }
	logData.event = "Achievement::Start"
	uespLog.AppendDataToLog("achievements", logData, uespLog.GetTimeData())
	
	for categoryIndex = 1, numCategories do
		local categoryName, numSubCategories, numCateAchievements, earnedCatePoints, totalCatePoints, hidesCatePoints, normalIcon, pressedIcon, mouseoverIcon = GetAchievementCategoryInfo(categoryIndex)
		
		logData = { }
		logData.event = "Category"
		logData.name = categoryName
		logData.subCategories = numSubCategories
		logData.numAchievements = numCateAchievements
		logData.points = totalCatePoints
		logData.hidesPoints = hidesCatePoints
		logData.icon = normalIcon
		logData.pressedIcon = pressedIcon
		logData.mouseoverIcon = mouseoverIcon
		uespLog.AppendDataToLog("achievements", logData)
		
		for subCategoryIndex = 1, numSubCategories do
			local subcategoryName, numsubCateAchievements, earnedSubCatePoints, totalSubCatePoints, hidesSubCatePoints = GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
			
			logData = { }
			logData.event = "Subcategory"
			logData.name = subcategoryName
			logData.numAchievements = numsubCateAchievements
			logData.points = totalSubCatePoints
			logData.hidesPoints = hidesSubCatePoints
			uespLog.AppendDataToLog("achievements", logData)
			
			for achievementIndex = 1, numsubCateAchievements do
				local rc, cc = uespLog.DumpAchievementPriv (categoryIndex, subCategoryIndex, achievementIndex)
				rewardCount = rewardCount + rc
				criteriaCount = criteriaCount + cc
				outputCount = outputCount + 1
			end
		end
		
		for achievementIndex = 1, numCateAchievements do
			local rc, cc = uespLog.DumpAchievementPriv (categoryIndex, nil, achievementIndex)
			rewardCount = rewardCount + rc
			criteriaCount = criteriaCount + cc
			outputCount = outputCount + 1
		end

	end
	
	logData = { }
	logData.event = "Achievement::End"
	uespLog.AppendDataToLog("achievements", logData)
	
	uespLog.DebugMsg("UESP::Output ".. outputCount .." achievements, ".. rewardCount.." rewards, and "..criteriaCount.." criterias to log!");
end


uespLog.IsIgnoredNPC = function (name)
	return (uespLog.ignoredNPCs[name] ~= nil)
end


uespLog.ClearSavedVarSection = function(section)

	if (uespLog.savedVars[section] ~= nil) then
		uespLog.savedVars[section].data = { }
		uespLog.NextSectionSizeWarning[section] = uespLog.FIRST_SECTION_SIZE_WARNING
		uespLog.NextSectionWarningGameTime[section] = 0
	end
	
end


function uespLog.IsValidItemId (itemId)
	local itemLink = uespLog.MakeItemLink(itemId, 1, 1)
	return uespLog.IsValidItemLink(itemLink)
end


function uespLog.IsValidItemLink (itemLink)
	return (GetItemLinkItemType(itemLink) > 0)
end


function uespLog.MineItemIterateLevels (itemId)
	local i, value
	local level, quality
	local setCount = 0
	local badItems = 0
	local itemLink
	local itemName
	local extraData = uespLog.GetTimeData()

	for i, value in ipairs(uespLog.MINEITEM_LEVELS) do
		local levelStart = value[1]
		local levelEnd = value[2]
		local qualityStart = value[3]
		local qualityEnd = value[4]
		local comment = value[5]
		
		for level = levelStart, levelEnd do
			for quality = qualityStart, qualityEnd do
				setCount = setCount + 1
				uespLog.mineItemCount = uespLog.mineItemCount + 1
				
				itemLink = uespLog.MakeItemLinkEx( { itemId = itemId, level = level, quality = quality, style = 1 } )
				
				if (uespLog.IsValidItemLink(itemLink)) then
					extraData.comment = comment
					uespLog.LogItemLink(itemLink, "mineitem", extraData)
				else
					badItems = badItems + 1
					uespLog.mineItemBadCount = uespLog.mineItemBadCount + 1
				end				
				
				if (uespLog.mineItemCount % uespLog.mineUpdateItemCount == 0) then
					uespLog.DebugMsgColor(uespLog.mineColor, ".     Mined "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad...")
				end
			end
		end
	end
	
	--uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Made "..tostring(setCount).." items with ID "..tostring(itemId)..", "..tostring(badItems).." bad")
	return setCount, badCount
end


function uespLog.MineItemIterateLevelsShort (itemId)
	local i, value
	local level, quality
	local setCount = 0
	local badItems = 0
	local itemLink
	local itemName
	local extraData = { }
	local isFirst = true
	local fullItemLog = { }
	local lastItemLog = { }
	local newItemLog = { }
	local diffItemLog = { }

	for i, value in ipairs(uespLog.MINEITEM_LEVELS) do
		local levelStart = value[1]
		local levelEnd = value[2]
		local qualityStart = value[3]
		local qualityEnd = value[4]
		local comment = value[5]
		isFirst = true
		
		for level = levelStart, levelEnd do
		
			if (uespLog.mineItemOnlyLevel < 0 or level == uespLog.mineItemOnlyLevel) then
			
				for quality = qualityStart, qualityEnd do
				
					if (uespLog.mineItemOnlySubType < 0 or quality == uespLog.mineItemOnlySubType) then
						setCount = setCount + 1
						uespLog.mineItemCount = uespLog.mineItemCount + 1
						
						itemLink = uespLog.MakeItemLinkEx( { itemId = itemId, level = level, quality = quality, style = 0 } )
						
						if (uespLog.IsValidItemLink(itemLink)) then
							
							if (isFirst) then
								isFirst = false
								extraData.comment = comment
								fullItemLog = uespLog.CreateItemLinkLog(itemLink)
								fullItemLog.event = "mineitem"
								uespLog.AppendDataToLog("all", fullItemLog, extraData)
								extraData.comment = nil
								lastItemLog = fullItemLog
							else
								newItemLog = uespLog.CreateItemLinkLog(itemLink)
								diffItemLog = uespLog.CompareItemLogs(lastItemLog, newItemLog)
								diffItemLog.event = "mi"
								uespLog.AppendDataToLog("all", diffItemLog, extraData)
								lastItemLog = newItemLog
								--uespLog.LogItemLinkShort(itemLink, "mi", extraData)
							end
							
						else
							badItems = badItems + 1
							uespLog.mineItemBadCount = uespLog.mineItemBadCount + 1
						end				
						
						if (uespLog.mineItemCount % uespLog.mineUpdateItemCount == 0) then
							uespLog.DebugMsgColor(uespLog.mineColor, ".     Mined "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad...")
						end
					end
				end
			end
		end
	end
	
	--uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Made "..tostring(setCount).." items with ID "..tostring(itemId)..", "..tostring(badItems).." bad")
	return setCount, badCount
end


function uespLog.MineItemIterateOther (itemId)
	local itemLink
	local extraData = uespLog.GetTimeData()
	
	itemLink = uespLog.MakeItemLinkEx( { itemId = itemId, level = 1, quality = 1, style = 0 } )
	uespLog.mineItemCount = uespLog.mineItemCount + 1
	
	if (uespLog.mineItemCount % uespLog.mineUpdateItemCount == 0) then
		uespLog.DebugMsgColor(uespLog.mineColor, ".     Mined "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad...")
	end
	
	if (uespLog.IsValidItemLink(itemLink)) then
		uespLog.LogItemLink(itemLink, "mineitem", extraData)
	else
		uespLog.mineItemBadCount = uespLog.mineItemBadCount + 1
		return 1, 1
	end
	
	return 1, 0
end


function uespLog.MineItemIterate (itemId)
	
	if (not uespLog.IsValidItemId(itemId)) then
		uespLog.mineItemCount = uespLog.mineItemCount + 1
		uespLog.mineItemBadCount = uespLog.mineItemBadCount + 1
		return 1, 0
	end
	
	local changesWithLevel = uespLog.DoesItemChangeWithLevelQuality(itemId)
	
	if (changesWithLevel) then
		return uespLog.MineItemIterateLevelsShort(itemId)
	end
	
	return uespLog.MineItemIterateOther(itemId)
end


function uespLog.MineItems (startId, endId)
	local itemLink
	local itemName
	local logData
	local itemCount = 0
	local badCount = 0
	local itemId
	
	uespLog.mineItemBadCount = 0
	uespLog.mineItemCount = 0
	uespLog.MsgColor(uespLog.mineColor, "UESP::Mining items from IDs "..tostring(startId).." to "..tostring(endId))
	
	if (uespLog.mineItemOnlyLevel >= 0) then
		uespLog.DebugMsgColor(uespLog.mineColor, ".     Only mining items with internal level of "..tostring(uespLog.mineItemOnlyLevel))
	end
	
	if (uespLog.mineItemOnlySubType >= 0) then
		uespLog.DebugMsgColor(uespLog.mineColor, ".     Only mining items with internal type of "..tostring(uespLog.mineItemOnlySubType))
	end
	
	logData = { }
	logData.startId = startId
	logData.endId = endId
	logData.event = "mineitem::Start"
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())

	for itemId = startId, endId do
		uespLog.MineItemIterate(itemId)
	end
	
	uespLog.mineNextItemId = endId + 1
	
	logData = { }
	logData.event = "mineitem::End"
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	uespLog.DebugMsgColor(uespLog.mineColor, ".    Finished Mining "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad")
end


function uespLog.MineItemsAutoLoop ()
	local initItemCount = uespLog.mineItemCount
	local initBadCount = uespLog.mineItemBadCount
	local initItemId = uespLog.mineItemsAutoNextItemId
	local itemId
	local i	
	
	if (not uespLog.isAutoMiningItems) then
		return
	end
	
	for i = 1, uespLog.MINEITEMS_AUTOLOOPCOUNT do
	
		if (#uespLog.savedVars.all.data >= uespLog.MINEITEMS_AUTOSTOP_LOGCOUNT or uespLog.mineItemsAutoNextItemId > uespLog.MINEITEM_AUTO_MAXITEMID) then
		
			if (uespLog.mineItemsAutoNextItemId > uespLog.MINEITEM_AUTO_MAXITEMID) then	
				uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Stopped auto-mining at item "..tostring(uespLog.mineItemsAutoNextItemId).." due to reaching max ID.")
			elseif (initItemId < uespLog.mineItemsAutoNextItemId) then
				uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Paused auto-mining at item "..tostring(uespLog.mineItemsAutoNextItemId).." due to full log.")
			end
			
			if (not uespLog.mineItemAutoRestartOutputEnd) then
				uespLog.MineItemsOutputEndLog()
				uespLog.mineItemAutoRestartOutputEnd = true
			end
			
			local reloadTime = uespLog.mineItemLastReloadTimeMS + uespLog.MINEITEM_AUTORELOAD_DELTATIMEMS - GetGameTimeMilliseconds()

			if (uespLog.mineItemAutoReload and reloadTime <= 0) then
				uespLog.MsgColor(uespLog.mineColor, "UESP::Item mining auto reloading UI....")
				SLASH_COMMANDS["/reloadui"]()
			elseif (uespLog.mineItemAutoReload) then
				uespLog.MsgColor(uespLog.mineColor, "UESP::Item mining auto UI reload in "..tostring(math.ceil(reloadTime/5000)*5).." secs...")
			end
			
			break
		end
		
		itemId = uespLog.mineItemsAutoNextItemId
		uespLog.mineItemsAutoNextItemId = uespLog.mineItemsAutoNextItemId + 1
		uespLog.savedVars.settings.data.mineItemsAutoNextItemId = uespLog.mineItemsAutoNextItemId
		
		uespLog.MineItemIterate(itemId)
		
		if (uespLog.mineItemCount - initItemCount > uespLog.MINEITEMS_AUTOMAXLOOPCOUNT) then
			break
		end

	end

		-- Chain the call to keep going if required
	if (uespLog.isAutoMiningItems) then
	
		if (initItemId < uespLog.mineItemsAutoNextItemId) then
			zo_callLater(uespLog.MineItemsAutoLoop, uespLog.MINEITEMS_AUTODELAY)
		elseif (uespLog.mineItemAutoReload) then
			zo_callLater(uespLog.MineItemsAutoLoop, uespLog.MINEITEMS_AUTODELAY * 5)
		end
	end
	
	if (initItemId < uespLog.mineItemsAutoNextItemId) then
		uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Auto-mined "..tostring(uespLog.mineItemCount - initItemCount).." items, "..
				tostring(uespLog.mineItemBadCount - initBadCount).." bad, IDs "..tostring(initItemId).."-"..tostring(itemId)..
				" (total "..tostring(uespLog.mineItemCount).." items)")	
	end
end


function uespLog.MineItemsAutoStart ()
	local logData

	if (uespLog.isAutoMiningItems) then
		return
	end
	
	uespLog.mineItemBadCount = 0
	uespLog.mineItemCount = 0
	
	uespLog.MineItemsOutputStartLog()
	
	uespLog.isAutoMiningItems = true
	uespLog.savedVars.settings.data.isAutoMiningItems = uespLog.isAutoMiningItems
	uespLog.MsgColor(uespLog.mineColor, "UESP::Started auto-mining items at ID "..tostring(uespLog.mineItemsAutoNextItemId))
	
	if (uespLog.mineItemOnlyLevel >= 0) then
		uespLog.DebugMsgColor(uespLog.mineColor, ".     Only mining items with internal level of "..tostring(uespLog.mineItemOnlyLevel))
	end
	
	if (uespLog.mineItemOnlySubType >= 0) then
		uespLog.DebugMsgColor(uespLog.mineColor, ".     Only mining items with internal type of "..tostring(uespLog.mineItemOnlySubType))
	end
	
	zo_callLater(uespLog.MineItemsAutoLoop, uespLog.MINEITEMS_AUTODELAY)
end


function uespLog.MineItemsOutputStartLog ()
	local logData = { }
	
	logData = { }
	logData.itemId = uespLog.mineItemsAutoNextItemId
	logData.event = "mineItem::Start"
	logData.onlySubType = uespLog.mineItemOnlySubType
	logData.onlyLevel = uespLog.mineItemOnlyLevel
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	uespLog.mineItemAutoRestartOutputEnd = false
end


function uespLog.MineItemsOutputEndLog ()
	local logData = { }
	
	logData.itemId = uespLog.mineItemsAutoNextItemId
	logData.itemCount = uespLog.mineItemCount
	logData.badCount = uespLog.mineItemBadCount
	logData.event = "mineItem::End"
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	uespLog.mineItemAutoRestartOutputEnd = true
end


function uespLog.MineItemsAutoEnd ()
	local logData

	if (not uespLog.isAutoMiningItems) then
		return
	end
	
	uespLog.mineItemAutoReload = false
	uespLog.mineItemAutoRestart = false
	uespLog.savedVars.settings.data.mineItemAutoReload = false
	uespLog.savedVars.settings.data.mineItemAutoRestart = false
	uespLog.isAutoMiningItems = false
	uespLog.savedVars.settings.data.isAutoMiningItems = false
	
	if (not uespLog.mineItemAutoRestartOutputEnd) then
		uespLog.MineItemsOutputEndLog()
	end
	
	uespLog.MsgColor(uespLog.mineColor, "UESP::Stopped auto-mining items at ID "..tostring(uespLog.mineItemsAutoNextItemId))
	uespLog.DebugMsgColor(uespLog.mineColor, "UESP::Total auto-mined "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad")	
end


function uespLog.MineItemsAutoStatus ()
	
	if (uespLog.isAutoMiningItems) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Currently auto-mining items.")
		uespLog.MsgColor(uespLog.mineColor, "UESP::Total auto-mined "..tostring(uespLog.mineItemCount).." items, "..tostring(uespLog.mineItemBadCount).." bad")	
		uespLog.MsgColor(uespLog.mineColor, "UESP::Auto-reload = "..tostring(uespLog.mineItemAutoReload)..",  auto-restart = "..tostring(uespLog.mineItemAutoRestart))	
	else
		uespLog.MsgColor(uespLog.mineColor, "UESP::Not currently auto-mining items.")
	end
	
	uespLog.MsgColor(uespLog.mineColor, "UESP::Next auto-mine itemId is "..tostring(uespLog.mineItemsAutoNextItemId))
	
	if (uespLog.mineItemOnlyLevel >= 0 and uespLog.mineItemOnlySubType >= 0) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Only mining items with internal level "..tostring(uespLog.mineItemOnlyLevel).." and type of "..tostring(uespLog.mineItemOnlySubType)..".")
	elseif (uespLog.mineItemOnlyLevel >= 0) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Only mining items with internal level "..tostring(uespLog.mineItemOnlyLevel)..".")
	elseif (uespLog.mineItemOnlySubType >= 0) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Only mining items with internal type of "..tostring(uespLog.mineItemOnlySubType)..".")
	end
end


function uespLog.MineItemsQualityMapLogItem(itemLink, intLevel, intSubtype, extraData)
	local logData = { }
	local reqLevel = GetItemLinkRequiredLevel(itemLink)
	local reqVetLevel = GetItemLinkRequiredVeteranRank(itemLink)
	local quality = GetItemLinkQuality(itemLink)
	local level = 0
	
	if (reqVetLevel ~= nil and reqVetLevel > 0) then
		level = reqVetLevel + 49
	elseif (reqLevel ~= nil and reqLevel > 0) then
		level = reqLevel
	end
	
	logData.event = "mineItem::quality"
	logData.itemLink = itemLink
	logData.intLevel = intLevel
	logData.intSubtype = intSubtype
	logData.level = level
	logData.quality = quality
	logData.csv = tostring(intLevel) .. ", "..tostring(intSubtype)..", "..tostring(level)..", "..tostring(quality)

	uespLog.AppendDataToLog("all", logData, extraData)
end


function uespLog.MineItemsQualityMap(level)
	local extraData = uespLog.GetTimeData()
	level = level or 1
		
	uespLog.MsgColor(uespLog.mineColor, "UESP::Creating type quality map for item #"..tostring(uespLog.MINEITEM_QUALITYMAP_ITEMID).." at level "..tostring(level))
	
	for subtype = 1, 400 do
		local itemLink = uespLog.MakeItemLink(uespLog.MINEITEM_QUALITYMAP_ITEMID, level, subtype)
			
		if (uespLog.IsValidItemLink(itemLink)) then
			 uespLog.MineItemsQualityMapLogItem(itemLink, level, subtype, extraData)
		end
		
	end
	
end


function uespLog.MineItemsIdCheck(note)
	local itemId
	local logData = { }
	local extraData = uespLog.GetTimeData()
	
	if (uespLog.IsIdCheckInProgress) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::ID Check is already in progress...")
		return false
	end

	uespLog.MsgColor(uespLog.mineColor, "UESP::Starting ID check of items...")
	
	logData.event = "mineItem::idCheck::start"
	logData.note = note or ""
	logData.apiVersion = GetAPIVersion()
	logData.gameVersion = _VERSION
	uespLog.AppendDataToLog("all", logData, extraData)
	
	uespLog.IdCheckRangeIdStart = -1
	uespLog.CurrentIdCheckItemId = 1
	uespLog.IdCheckValidCount = 0
	uespLog.IdCheckTotalCount = 0
	uespLog.IsIdCheckInProgress = true
	
	zo_callLater(uespLog.MineItemsIdCheckDoNext, uespLog.MINEITEM_IDCHECK_TIMEDELTA)
end


function uespLog.MineItemsIdCheckDoNext()
	local startId = uespLog.CurrentIdCheckItemId
	local endId = uespLog.CurrentIdCheckItemId + uespLog.MINEITEM_IDCHECK_NUMITEMS - 1
	local itemId
	local validCount = 0
	
	if (endId > uespLog.MINEITEM_AUTO_MAXITEMID) then
		endId = uespLog.MINEITEM_AUTO_MAXITEMID
	end

	for itemId = startId, endId do
		local itemLink = uespLog.MakeItemLink(itemId, 1, 1)
		uespLog.IdCheckTotalCount = uespLog.IdCheckTotalCount + 1
			
		if (uespLog.IsValidItemLink(itemLink)) then
			 uespLog.IdCheckValidCount = uespLog.IdCheckValidCount + 1
			 validCount = validCount + 1
			 
			if (uespLog.IdCheckRangeIdStart < 0) then
				uespLog.IdCheckRangeIdStart = itemId
			end
		elseif (uespLog.IdCheckRangeIdStart > 0) then
			uespLog.MineItemsLogValidIdRange(uespLog.IdCheckRangeIdStart, itemId-1)
			uespLog.IdCheckRangeIdStart = -1
		end
		
		uespLog.CurrentIdCheckItemId = itemId
	end
	
	uespLog.MsgColor(uespLog.mineColor,".     Item ID Check: "..tostring(startId).."-"..tostring(endId).." ("..tostring(validCount).." valid)")
	
	if (uespLog.CurrentIdCheckItemId < uespLog.MINEITEM_AUTO_MAXITEMID) then
		uespLog.CurrentIdCheckItemId = uespLog.CurrentIdCheckItemId + 1
		zo_callLater(uespLog.MineItemsIdCheckDoNext, uespLog.MINEITEM_IDCHECK_TIMEDELTA)
	else
		uespLog.MineItemsIdCheckEnd()
	end
	
end


function uespLog.MineItemsIdCheckEnd()

	if (uespLog.IdCheckRangeIdStart > 0) then
		uespLog.MineItemsLogValidIdRange(uespLog.IdCheckRangeIdStart, uespLog.CurrentIdCheckItemId-1)
		uespLog.IdCheckRangeIdStart = -1
	end
	
	logData = { }
	logData.event = "mineItem::idCheck::end"
	logData.validCount = uespLog.IdCheckValidCount
	logData.totalCount = uespLog.IdCheckTotalCount
	uespLog.AppendDataToLog("all", logData)
	
	uespLog.MsgColor(uespLog.mineColor, "UESP::Found "..tostring(uespLog.IdCheckValidCount).." valid items!")
	uespLog.IsIdCheckInProgress = false
end


function uespLog.MineItemsLogValidIdRange(startId, endId)
	local logData = { }
	
	logData.event = "mineItem::idCheck"
	logData.startId = startId
	logData.endId = endId
	
	uespLog.AppendDataToLog("all", logData, extraData)
end


SLASH_COMMANDS["/uespmineitems"] = function (cmd)
	local cmds = { }
	
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	
	if (cmds[1] == "enable") then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Enabled use of /uespmineitems (/umi)!")
		uespLog.MsgColor(uespLog.mineColorWarning, ".         WARNING -- This feature is experimental and can crash the")
		uespLog.MsgColor(uespLog.mineColorWarning, ".         ESO client! Use at your own risk....")
		uespLog.mineItemsEnabled = true
		uespLog.savedVars.settings.data.mineItemsEnabled = true
		return
	elseif (not uespLog.mineItemsEnabled) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Use of /uespmineitems (/umi) is currently disabled!")
		uespLog.MsgColor(uespLog.mineColor, ".         Enable with: /uespmineitems enable")
		return
	end
	
	if (cmds[1] == "start" or cmds[1] == "begin") then
		
		if (cmds[2] ~= nil) then
			uespLog.mineItemsAutoNextItemId = tonumber(cmds[2])
			uespLog.savedVars.settings.data.mineItemsAutoNextItemId = uespLog.mineItemsAutoNextItemId
		end
		
		uespLog.MineItemsAutoStart()
		return
	elseif (cmds[1] == "subtype" or cmds[1] == "type") then
		uespLog.mineItemOnlySubType = tonumber(cmds[2])
		if (uespLog.mineItemOnlySubType == null) then uespLog.mineItemOnlySubType = -1 end
		uespLog.savedVars.settings.data.mineItemOnlySubType = uespLog.mineItemOnlySubType
		
		if (uespLog.mineItemOnlySubType < 0) then
			uespLog.MsgColor(uespLog.mineColor, "UESP::Mining items with all internal types.")
		else
			uespLog.MsgColor(uespLog.mineColor, "UESP::Only mining items with internal type of "..tostring(uespLog.mineItemOnlySubType)..".")
		end
		
		return
	elseif (cmds[1] == "quick") then
		local option = string.lower(cmds[2])
		
		if (option == "on") then
			uespLog.savedVars.settings.data.mineItemOnlySubType = uespLog.MINEITEM_ONLYSUBTYPE
			uespLog.savedVars.settings.data.mineItemOnlyLevel = uespLog.MINEITEM_ONLYLEVEL
			uespLog.MsgColor(uespLog.mineColor, "UESP::Only mining items with internal level "..tostring(uespLog.savedVars.settings.data.mineItemOnlyLevel).." and type "..tostring(uespLog.savedVars.settings.data.mineItemOnlySubType)..".")
		elseif (option == "off") then
			uespLog.MsgColor(uespLog.mineColor, "UESP::Mining items with all internal levels/types.")
		else
			uespLog.MsgColor(uespLog.mineColor, "UESP::Valid options for 'quick' are 'on'/'off'.")
		end
		
		return
	elseif (cmds[1] == "end" or cmds[1] == "stop") then
		uespLog.MineItemsAutoEnd()
		return
	elseif (cmds[1] == "status") then
		uespLog.MineItemsAutoStatus()
		return
	elseif (cmds[1] == "qualitymap") then
		uespLog.MineItemsQualityMap(1)
		uespLog.MineItemsQualityMap(50)
		return
	elseif (cmds[1] == "idcheck") then
		uespLog.MineItemsIdCheck(cmds[2])
		return
	elseif (cmds[1] == "autostart") then
		uespLog.mineItemAutoReload = true
		uespLog.mineItemAutoRestart = true
		uespLog.savedVars.settings.data.mineItemAutoReload = true
		uespLog.savedVars.settings.data.mineItemAutoRestart = true
		
		if (cmds[2] ~= nil) then
			uespLog.mineItemsAutoNextItemId = tonumber(cmds[2])
			uespLog.savedVars.settings.data.mineItemsAutoNextItemId = uespLog.mineItemsAutoNextItemId
		end
		
		uespLog.MsgColor(uespLog.mineColor, "UESP::Turned on item mining auto reload and restart!")
		uespLog.MsgColor(uespLog.mineColorWarning, ".   WARNING::This will reload the UI and clear log data automatically!")
		uespLog.MsgColor(uespLog.mineColorWarning, ".                      To stop use: /uespmineitem end")
		uespLog.MineItemsAutoStart()
		return
	end
	
	if (cmds[1] == nil) then cmds[1] = uespLog.mineNextItemId end
	local startNumber = tonumber(cmds[1])
	
	if (startNumber == nil) then
		uespLog.MsgColor(uespLog.mineColor, "UESP::Invalid input to /uespmineitems (/umi)! Expected format is one of:")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems [itemId]")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems status")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems start [startId]")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems stop")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems autostart [startId]")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems qualitymap")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems subtype [subType]")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems idcheck [note]")
		uespLog.MsgColor(uespLog.mineColor, ".              /uespmineitems quick [on/off]")
		return
	end
	
	uespLog.MsgColor(uespLog.mineColor, "UESP::Trying to mine items with ID "..tostring(startNumber))
	uespLog.MineItems(startNumber, startNumber)
end


function uespLog.ClearAllSavedVarSections()

	for key, value in pairs(uespLog.savedVars) do
	
		if (key == "settings" or key == "info") then
			-- Keep data
		elseif (key == "globals" or key == "all" or key == "achievements") then
			uespLog.savedVars[key].data = { }
			uespLog.savedVars[key].version = uespLog.DATA_VERSION
		else
			uespLog.savedVars[key] = nil
		end
	end

end


function uespLog.ClearRootSavedVar()
	
	for key1, value1 in pairs(uespLogSavedVars) do  	-- Default
		for key2, value2 in pairs(value1) do			-- @User
			for key3, value3 in pairs(value2) do		-- $AccountWide
				for key4, value4 in pairs(value3) do	-- globals, all, info, settings, ....
					uespLog.DebugExtraMsg("UESP::Clearing saved data section "..tostring(key4))
					
					if (key4 == "settings" or key4 == "info") then
						-- Keep data
					elseif (key4 == "globals" or key4 == "all" or key4 == "achievements") then
						uespLogSavedVars[key1][key2][key3][key4].data = { }
						uespLogSavedVars[key1][key2][key3][key4].version = uespLog.DATA_VERSION
					else
						uespLogSavedVars[key1][key2][key3][key4] = nil  -- Delete unknown section
					end
			
				end
			end
		end
	end
	
end


SLASH_COMMANDS["/umi"] = SLASH_COMMANDS["/uespmineitems"]


SLASH_COMMANDS["/uespreset"] = function (cmd)
	
	if (cmd == "all") then
		uespLog.ClearSavedVarSection("all")
		uespLog.ClearSavedVarSection("globals")
		uespLog.ClearSavedVarSection("achievements")
		uespLog.SetTotalInspiration(0)
		uespLog.ClearAllSavedVarSections()
		uespLog.ClearRootSavedVar()
		uespLog.Msg("UESP::Reset all logged data")
	elseif (cmd == "log") then
		uespLog.ClearSavedVarSection("all")
		uespLog.Msg("UESP::Reset regular logged data")
	elseif (cmd == "globals") then
		uespLog.ClearSavedVarSection("globals")
		uespLog.Msg("UESP::Reset logged global data")
	elseif (cmd == "achievements") then
		uespLog.ClearSavedVarSection("achievements")
		uespLog.Msg("UESP::Reset logged achievement data")
	elseif (cmd == "inspiration") then
		uespLog.SetTotalInspiration(0)
		uespLog.Msg("UESP::Reset crafting inspiration total")
	else
		uespLog.Msg("UESP::Parameter expected...use one of: all, log, globals, achievements, inspiration")
	end

end


SLASH_COMMANDS["/uesptargetinfo"] = function (cmd)
	uespLog.ShowTargetInfo()
end


SLASH_COMMANDS["/uti"] = function (cmd)
	uespLog.ShowTargetInfo()
end


uespLog.GetCraftingName = function (craftingType)

	if (craftingType == CRAFTING_TYPE_ALCHEMY) then return "Alchemy" end
	if (craftingType == CRAFTING_TYPE_BLACKSMITHING) then return "Blacksmithing" end
	if (craftingType == CRAFTING_TYPE_CLOTHIER) then return "Clothier" end
	if (craftingType == CRAFTING_TYPE_ENCHANTING) then return "Enchanting" end
	if (craftingType == CRAFTING_TYPE_INVALID) then return "Invalid" end
	if (craftingType == CRAFTING_TYPE_PROVISIONING) then return "Provisioning" end
	if (craftingType == CRAFTING_TYPE_WOODWORKING) then return "Woodworking" end
	
	return "Unknown"
end


uespLog.GetShortCraftingName = function (craftingType)

	if (craftingType == CRAFTING_TYPE_ALCHEMY) then return "AL" end
	if (craftingType == CRAFTING_TYPE_BLACKSMITHING) then return "BS" end
	if (craftingType == CRAFTING_TYPE_CLOTHIER) then return "CL" end
	if (craftingType == CRAFTING_TYPE_ENCHANTING) then return "EN" end
	if (craftingType == CRAFTING_TYPE_INVALID) then return "IN" end
	if (craftingType == CRAFTING_TYPE_PROVISIONING) then return "PV" end
	if (craftingType == CRAFTING_TYPE_WOODWORKING) then return "WW" end
	
	return "??"
end


uespLog.GetItemTraitName = function (traitType)
	return GetString(SI_ITEMTRAITTYPE0 + traitType)
end


uespLog.ShowResearchInfo = function (craftingType)
	local TradeskillName = uespLog.GetCraftingName(craftingType)
	local numLines = GetNumSmithingResearchLines(craftingType)
	local maxSimultaneousResearch = GetMaxSimultaneousSmithingResearch(craftingType)
	local researchCount = 0
	
	if (numLines == 0 or maxSimultaneousResearch == 0) then
		uespLog.MsgColor(uespLog.researchColor, "UESP::"..TradeskillName.." doesn't have any research lines available!")
		return
	end
	
	for researchLineIndex = 1, numLines do
		local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftingType, researchLineIndex)
		
		for traitIndex = 1, numTraits do
			local duration, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
			local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			local traitName = uespLog.GetItemTraitName(traitType)
			
			if (duration ~= nil) then
				local days = math.floor(timeRemainingSecs / 3600 / 24)
				local hours = math.floor(timeRemainingSecs / 3600) % 24
				local minutes = math.floor(timeRemainingSecs / 60) % 60
				local seconds = timeRemainingSecs % 60
				local timeFmt = ""
				
				if (days > 1) then
					timeFmt = string.format("%d days %02d:%02d:%02d", days, hours, minutes, seconds)
				elseif (days > 0) then
					timeFmt = string.format("%d day %02d:%02d:%02d", days, hours, minutes, seconds)
				else
					timeFmt = string.format("%02d:%02d:%02d", hours, minutes, seconds)
				end
				
				--uespLog.Msg("UESP::"..tostring(TradeskillName).." line for "..tostring(name).." ("..tostring(traitName)..") has "..timeFmt.." left on research.")
				uespLog.MsgColor(uespLog.researchColor, "UESP::"..tostring(TradeskillName).." "..tostring(name).." ("..tostring(traitName)..") has "..timeFmt.." left.")
				researchCount = researchCount + 1
			end
		end
	end
	
	if (researchCount < maxSimultaneousResearch) then
		local slotsOpen = maxSimultaneousResearch - researchCount
		uespLog.MsgColor(uespLog.researchColor, "UESP::"..TradeskillName.." has "..tostring(slotsOpen).." research slots available.")
	end

end


SLASH_COMMANDS["/uesptestpotion"] = function (cmd)
	local cmds = { }
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	
	local itemLink = uespLog.MakeItemLinkEx( { itemId = cmds[3] or 54339, level = cmds[1] or 1, quality = cmds[2] or 1, potionEffect = cmds[4] or 8454917 } )
	uespLog.Msg("UESP::Make test link ".. itemLink)
	ZO_PopupTooltip_SetLink(itemLink)
end


SLASH_COMMANDS["/uesptest"] = function (cmd)
	--uespLog.DebugMsg("Showing Test Time (noon)....")
	--uespLog.ShowTime(1398882554)	-- 1398882554 = 14:30 April 30th 2014 which should be exactly noon in game time 
	--uespLog.DebugMsg("Showing Test Time (sunset)....")
	--uespLog.ShowTime(1398889754)   -- 1308889754 = 16:32 April 30th 2014 which should be sunset
	--uespLog.DebugMsg("Showing Test Time (almost new moon)....")
	--uespLog.ShowTime(1399083327)   -- 1399083327 = Wanning crescent moon, almost new, 0.97
	--uespLog.DebugMsg("Showing Test Time (noon)....")
	--uespLog.ShowTime(1399133861)   -- 1399133861 = 12:20 3 May 2014, noon in-game
	--uespLog.DebugMsg("Showing Test Time (midnight)....")
	--uespLog.ShowTime(1399753920)   -- 1399753920 = 16:35 10 May 2014, should be midnight in game with a wanning crescent moon (0.875)
	-- Moon Phase ~ Full Moon, TimeStamp = 1435838770, LocalTime = 124897, 2 July 2015 08:11
	-- Moon Phase ~ Full Moon, TimeStamp = 1438352285 (14:20 31 July 2015)
	-- Moon Phase ~ Slightly Waxing Gibbous past First Quarter (0.3-0.35), TimeStamp = 1440087745 (12:26 20 Aug 2015)

	uespLog.DebugMsg("Showing Test Time (Full Moon, 0.5)....")
	uespLog.ShowTime(1435838770)
	
	uespLog.DebugMsg("Showing Test Time (Full Moon, 0.5)....")
	uespLog.ShowTime(1438352285)
	
	uespLog.DebugMsg("Showing Test Time (Waxing Gibbous Moon, 0.33)....")
	uespLog.ShowTime(1440087745)	
	
end


SLASH_COMMANDS["/uespresearch"] = function (cmd)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_CLOTHIER)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_BLACKSMITHING)
	uespLog.ShowResearchInfo(CRAFTING_TYPE_WOODWORKING)
end


SLASH_COMMANDS["/uri"] = SLASH_COMMANDS["/uespresearch"]


function uespLog.ShowTargetInfo ()
	--local unitTag = "reticleover"
    --local type = GetUnitType(unitTag)
    --local name = GetUnitName(unitTag)
	--local x, y, z, zone = uespLog.GetUnitPosition(unitTag)
	--local level = GetUnitLevel(unitTag)
	--local gender = GetUnitGender(unitTag)
	--local class = GetUnitClass(unitTag)
	--local race = GetUnitRace(unitTag)
	--local difficulty = GetUnitDifficulty(unitTag)
	--local currentHp, maxHp, effectiveHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
	--local currentMg, maxMg, effectiveMg = GetUnitPower(unitTag, POWERTYPE_MAGICKA)
	--local currentSt, maxSt, effectiveSt = GetUnitPower(unitTag, POWERTYPE_STAMINA)
	--uespLog.Msg("Name:"..tostring(name)..", type:"..tostring(type)..", level:"..tostring(level)..", gender:"..tostring(gender)..", class:"..tostring(class)..", race:"..tostring(race))
	
	if (uespLog.lastTargetData == nil) then
		return
	end
	
	uespLog.Msg("UESP::Last Target Info -- Name:"..tostring(uespLog.lastTargetData.name)..", type:"..tostring(uespLog.lastTargetData.type)..", level:"..tostring(uespLog.lastTargetData.level)..", gender:"..tostring(uespLog.lastTargetData.gender)..", class:"..tostring(uespLog.lastTargetData.class)..", race:"..tostring(uespLog.lastTargetData.race)..",  maxHP:"..tostring(uespLog.lastTargetData.maxHp)..",  maxMG:"..tostring(uespLog.lastTargetData.maxMg)..",  maxST:"..tostring(uespLog.lastTargetData.maxSt))
end


function uespLog.UpdateCoordinates()
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()

    if (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer) then
        local currentOffsetX = ZO_WorldMapContainer:GetLeft()
        local currentOffsetY = ZO_WorldMapContainer:GetTop()
        local parentOffsetX = ZO_WorldMap:GetLeft()
        local parentOffsetY = ZO_WorldMap:GetTop()
        local mouseX, mouseY = GetUIMousePosition()
        local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
        local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

        local normalizedX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
        local normalizedY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000
		local xStr = string.format("%.03f", normalizedX)
		local yStr = string.format("%.03f", normalizedY)

        uespLogCoordinates:SetAlpha(0.8)
        uespLogCoordinates:SetDrawLayer(ZO_WorldMap:GetDrawLayer() + 1)
        uespLogCoordinates:SetAnchor(TOPLEFT, nil, TOPLEFT, parentOffsetX + 0, parentOffsetY + parentHeight)
        uespLogCoordinatesValue:SetText("Coordinates: " .. tostring(xStr) .. ", " .. tostring(yStr))
    else
        uespLogCoordinates:SetAlpha(0)
    end
end


function uespLog.DumpSmithItems(onlySetItems)
	local numPatterns = GetNumSmithingPatterns()
	local numStyles = GetNumSmithingStyleItems()
	local numImprovementItems = GetNumSmithingImprovementItems()
	local numTraitItems = GetNumSmithingTraitItems()
	local craftingType = GetCraftingInteractionType()
	local tradeskillName = uespLog.GetCraftingName(craftingType)
	
	if (numPatterns == 0 or craftingType == 0) then
		uespLog.DebugMsg("UESP::You must be using a smithing station for this to work!")
		return
	end
	
	local startPattern = 1
	
	if (onlySetItems) then
		if (craftingType == CRAFTING_TYPE_BLACKSMITHING) then
			startPattern = 15
		elseif (craftingType == CRAFTING_TYPE_CLOTHIER) then
			startPattern = 15
		elseif (craftingType == CRAFTING_TYPE_WOODWORKING) then
			startPattern = 7
		end
		
		if (startPattern > numPatterns) then
			uespLog.DebugMsg("UESP::You must be at a set smithing station for this to work!")	
			return
		end
		
		uespLog.DebugMsg("UESP::Dumping set items for "..tradeskillName.."...")
	else
		uespLog.DebugMsg("UESP::Dumping items for "..tradeskillName.."...")
	end
		
	--GetSmithingImprovementItemInfo(CRAFTING_TYPE_BLACKSMITHING, luaindex improvementItemIndex)
		--Returns: string itemName, textureName icon, integer currentStack, integer sellPrice, bool meetsUsageRequirement, integer equipType, integer itemStyle, integer quality
	--local itemLink = GetSmithingImprovementItemLink(TradeskillType craftingSkillType, luaindex improvementItemIndex, LinkStyle linkStyle)
	--GetSmithingImprovedItemInfo(integer itemToImproveBagId, integer itemToImproveSlotIndex, TradeskillType craftingSkillType)
		--Returns: string itemName, textureName icon, integer sellPrice, bool meetsUsageRequirement, integer equipType, integer itemStyle, integer quality
	--local itemLink = GetSmithingImprovedItemLink(integer itemToImproveBagId, integer itemToImproveSlotIndex, TradeskillType craftingSkillType, LinkStyle linkStyle)

	--local itemLink = GetSmithingPatternMaterialItemLink(luaindex patternIndex, luaindex materialIndex, LINK_STYLE_DEFAULT)
	--local itemLink = GetSmithingPatternResultLink(luaindex patternIndex, luaindex materialIndex, integer materialQuantity, luaindex styleIndex, luaindex traitIndex, LINK_STYLE_DEFAULT)
	
	--local patternName, baseName, icon, numMaterials, numTraitsRequired, numTraitsKnown, resultItemFilterType = GetSmithingPatternInfo(2)
	--local itemLink = GetSmithingPatternResultLink(2, 1, 7, 1, 1, LINK_STYLE_DEFAULT)
	--local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
	--uespLog.DebugMsg("UESP::Num Materials = " .. tostring(numMaterials))
	--uespLog.DebugMsg("UESP::Item " .. tostring(itemNiceLink))
	--uespLog.DebugMsg("UESP::Item ID " .. tostring(itemId))	
	--uespLog.DebugMsg("UESP::Item Level " .. tostring(itemLevel))
	
	local itemCount = 0
	local logData = { }
	local maxItemCount = 10000
	local timeData = uespLog.GetTimeData()
	
	if true then
		--return
	end
	
	for patternIndex = startPattern, numPatterns do
		local patternName, baseName, icon, numMaterials, numTraitsRequired, numTraitsKnown, resultItemFilterType = GetSmithingPatternInfo(2)
		
		logData = { }
		local styleIndex = 1
		
		--for materialIndex = 1, numMaterials do
		materialIndex = 1
		
			for traitIndex = 1, numTraitItems do
			
				for materialQuantity = 3, 14 do
					local itemLink = GetSmithingPatternResultLink(patternIndex, materialIndex, materialQuantity, styleIndex, traitIndex, LINK_STYLE_DEFAULT)
				
					if (itemLink ~= "") then
						local itemName, itemColor, itemId, itemLevel, itemData, itemNiceName, itemNiceLink = uespLog.ParseLinkID(itemLink)
						
						logData = { }
						
						logData.event = "ItemDump::Smith"
						logData.craftType = craftingType
						logData.itemLink = itemLink
						logData.itemId = itemId
						logData.level = itemLevel
						logData.itemName = itemNiceName
						logData.pattern = patternIndex
						logData.style = styleIndex
						logData.material = materialIndex
						logData.materialQnt = materialQuantity
						logData.trait = traitIndex
						
						uespLog.AppendDataToLog("all", logData, timeData)
						
						itemCount = itemCount + 1
						break
					end
				end
				
				if (itemCount > maxItemCount) then
					return
				end
				
			end
		--end
	end
	
	uespLog.DebugMsg("UESP::Output Items " .. tostring(itemCount))
end


SLASH_COMMANDS["/uespsmithtest"] = function (cmd)
	uespLog.DumpSmithItems(false)
end


SLASH_COMMANDS["/uespsmithsetdump"] = function (cmd)
	uespLog.DumpSmithItems(true)
end


SLASH_COMMANDS["/uespsmithinfo"] = function (cmd)
	local numPatterns = GetNumSmithingPatterns()
	local numStyles = GetNumSmithingStyleItems()
	local numImprovementItems = GetNumSmithingImprovementItems()
	local numTraitItems = GetNumSmithingTraitItems()
	local craftingType = GetCraftingInteractionType()
	local tradeskillName = uespLog.GetCraftingName(craftingType)
	
	uespLog.DebugMsg("UESP::Craft Type(" .. tostring(craftingType) .. ") = " .. tradeskillName)
	uespLog.DebugMsg("UESP::Num Patterns = " .. tostring(numPatterns))
	uespLog.DebugMsg("UESP::Num Styles = " .. tostring(numStyles))
	uespLog.DebugMsg("UESP::Num Improvements = " .. tostring(numImprovementItems))
	uespLog.DebugMsg("UESP::Num Traits = " .. tostring(numTraitItems))	
end


function uespLog.MakeEnchantLink(enchantId, inputLevel, inputType, inputItemId, inputItemLevel, inputItemType)
	local enchantLevel = inputLevel or 1
	local enchantType = inputType or 1
	local itemId = inputItemId or 70
	local itemLevel = inputItemLevel or 1
	local itemType = inputItemType or 1
		
	local itemLink = "|H0:item:"..tostring(itemId)..":"..tostring(itemType)..":"..tostring(itemLevel)..":"..tostring(enchantId)..":"..tostring(enchantType)..":"..tostring(enchantLevel)..":0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Item "..tostring(itemId).."]|h"

	local itemName = GetItemLinkName(itemLink)
	
	if (itemName ~= "" and itemName ~= nil) then
		itemLink = "|H0:item:"..tostring(itemId)..":"..tostring(itemType)..":"..tostring(itemLevel)..":"..tostring(enchantId)..":"..tostring(enchantType)..":"..tostring(enchantLevel)..":0:0:0:0:0:0:0:0:0:0:0:0:0:0|h["..tostring(itemName).."]|h"
		itemLink = "|H0:item:"..tostring(itemId)..":"..tostring(itemType)..":"..tostring(itemLevel)..":"..tostring(enchantId)..":"..tostring(enchantType)..":"..tostring(enchantLevel)..":"..tostring(enchantId)..":"..tostring(enchantType)..":"..tostring(enchantLevel)..":0:0:0:0:0:0:0:0:0:0:0|h["..tostring(itemName).."]|h"
	end
	
	return itemLink
end



function uespLog.MakeItemLink(itemId, inputLevel, inputQuality)
	local itemLevel = inputLevel or 1
	local itemQuality = inputQuality or 1
	
	local itemLink = "|H0:item:"..tostring(itemId)..":"..tostring(itemQuality)..":"..tostring(itemLevel)..":0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[Item ".. tostring(itemId) .."]|h"
	local itemName = GetItemLinkName(itemLink)
	
	if (itemName ~= "" and itemName ~= nil) then
		itemLink = "|H0:item:"..tostring(itemId)..":"..tostring(itemQuality)..":"..tostring(itemLevel)..":0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h[".. tostring(itemName) .."]|h"
	end
	
	return itemLink
end


function uespLog.MakeItemLinkEx(itemData)
	--     |H0:item:ID:SUBTYPE:LEVEL:ENCHANTID:ENCHANTSUBTYPE:ENCHANTLEVEL:0:0:0:0:0:0:0:0:0:STYLE:CRAFTED:BOUND:CHARGES:POTIONEFFECT|hNAME|h
	local itemId = itemData.itemId or 1
	local itemLevel = itemData.level or 1
	local itemQuality = itemData.quality or 1
	local enchantId = itemData.enchantId or 0
	local enchantQuality = itemData.enchantQuality or 0
	local enchantLevel = itemData.enchantLevel or 0
	local style = itemData.style or 0
	local potionEffect = itemData.potionEffect or 0
	local charges = itemData.charges or 0
	local bound = itemData.bound or 0
	local crafted = itemData.crafted or 0
	
	local itemLinkBase = "|H0:item:"..tostring(itemId)..":"..tostring(itemQuality)..":"..tostring(itemLevel)..":"
			..tostring(enchantId)..":"..tostring(enchantQuality)..":"..tostring(enchantLevel)..":0:0:0:0:0:0:0:0:0:0:"
			..tostring(style)..":"..tostring(crafted)..":"..tostring(bound)..":"..tostring(charges)..":"..tostring(potionEffect).."|h"
		
	local itemLink = itemLinkBase .. "[Item ".. tostring(itemId) .."]|h"
	local itemName = GetItemLinkName(itemLink)
	
	if (itemName ~= "" and itemName ~= nil) then
		itemLink = itemLinkBase .. "[".. tostring(itemName) .."]|h"
	end
			
	return itemLink
end


SLASH_COMMANDS["/uespcomparelink"] = function (cmd)
	local cmds = { }
	
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	
	local itemId = cmds[1]
	
	if (itemId == nil) then
		uespLog.Msg("UESP::Use the format: /uespcomparelink [id]")
		return
	end
	
	local itemLink1 = uespLog.MakeItemLink(itemId, 1, 1)
	local itemLink2 = uespLog.MakeItemLink(itemId, 50, 312)
	
	resultDiff = uespLog.CompareItemLinks(itemLink1, itemLink2)
	
	uespLog.Msg("UESP::Comparing items "..tostring(itemLink1).." and "..tostring(itemLink2).."")
	d(resultDiff)
end

SLASH_COMMANDS["/ucl"] = SLASH_COMMANDS["/uespcomparelink"]


SLASH_COMMANDS["/uespmakelink"] = function (cmd)
	local cmds = { }
	
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	
	local itemId = cmds[1]
	
	if (itemId == nil) then
		uespLog.Msg("UESP::Use the format: /uespmakelink [id] [level] [subtype]")
		return
	end
	
	local itemLink = uespLog.MakeItemLink(itemId, cmds[2], cmds[3])
	
	local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)

	if (icon == nil or icon == "" or icon == "") then
		uespLog.Msg("UESP::Item "..tostring(itemId).." is not valid!")
		return
	end
	
	uespLog.Msg("UESP::Created Item Link "..itemLink)
	
	uespLog.DebugExtraMsg("UESP::Icon "..tostring(icon))
	uespLog.DebugExtraMsg("UESP::Value "..tostring(sellPrice))
	uespLog.DebugExtraMsg("UESP::Equip Type "..tostring(equipType))
	uespLog.DebugExtraMsg("UESP::Item Style "..tostring(itemStyle))
	
	ZO_PopupTooltip_SetLink(itemLink)
end

SLASH_COMMANDS["/uml"] = SLASH_COMMANDS["/uespmakelink"]


SLASH_COMMANDS["/uespmakeenchant"] = function (cmd)
	local cmds = { }
	for word in cmd:gmatch("%S+") do table.insert(cmds, word) end
	local enchantId = cmds[1]
	
	if (enchantId == nil) then
		uespLog.Msg("UESP::Use the format: /uespmakeenchant [id] [level] [subtype] [itemid] [itemlevel] [itemsubtype]")
		return
	end
	
	local itemLink = uespLog.MakeEnchantLink(enchantId, cmds[2], cmds[3], cmds[4], cmds[5], cmds[6])
	uespLog.Msg("UESP::Created Enchant Link "..itemLink)
	
	ZO_PopupTooltip_SetLink(itemLink)
end

SLASH_COMMANDS["/ume"] = SLASH_COMMANDS["/uespmakeenchant"]


SLASH_COMMANDS["/uesptestdump"] = function(cmd)

	uespLog.printDumpObject = true
	uespLog.logDumpObject = false
	
	uespLog.DumpObject("", "BANK_FRAGMENT", BANK_FRAGMENT, 0, 3)
	uespLog.DebugMsg("CC"..tostring(#BANK_FRAGMENT))
	uespLog.DumpObject("", "BANK_FRAGMENT", BANK_FRAGMENT.control, 0, 3)
	
	local tmpTable = getmetatable(BANK_FRAGMENT.control)
	
	if (tmpTable ~= nil) then
		uespLog.DebugMsg("DD"..tostring(#tmpTable))
		--uespLog.DumpObject("", "BANK_FRAGMENT", tmpTable, 0, 3)
	end --]]
	
	--[[
	uespLog.DumpObject("", "TreasureMap", TreasureMap, 0, 3)
	uespLog.DebugMsg("AA"..tostring(#TreasureMap.__index))
	uespLog.DumpObject("", "TreasureMap", TreasureMap.__index, 0, 3)
	
	local tmpTable = getmetatable(TreasureMap)
	
	if (tmpTable ~= nil) then
		uespLog.DebugMsg("BB"..tostring(#tmpTable))
		uespLog.DumpObject("", "TreasureMap.__meta", tmpTable, 0, 3)
	end	--]]
	
	uespLog.printDumpObject = false
	uespLog.logDumpObject = true	
end


function uespLog.DumpToolTip ()
	uespLog.DebugMsg("UESP::Dumping tooltip "..tostring(PopupTooltip))
	
	uespLog.printDumpObject = true
	--uespLog.DumpObject("", "PopupTooltip", getmetatable(PopupTooltip), 0, 2)
		
	--for k, v in pairs(PopupTooltip) do
		--uespLog.DebugMsg(".    " .. tostring(k) .. "=" .. tostring(v))
	--end
	
	local numChildren = PopupTooltip:GetNumChildren()
	uespLog.DebugMsg("UESP::Has "..tostring(numChildren).." children")
	
    for i = 1, numChildren do
        local child = PopupTooltip:GetChild(i)
		--uespLog.DumpObject("", "child", getmetatable(child), 0, 2)
		local name = child:GetName()
		uespLog.DebugMsg(".   "..tostring(i)..") "..tostring(name))
    end
	
	uespLog.printDumpObject = false
end


function uespLog.DumpItems()
	--	d("|HFFFFFF:item:45817:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hJode|h test item")
	local itemLink = ""
	local startId = 1
	local endId = 100
	local logData = { }
	
	for itemId = startId, endId do
		itemLink = "|HFFFFF:item:"..itemId..":1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hUnknown|h"
		local icon, sellPrice, meetsUsageRequirement, equipType, itemStyle = GetItemLinkInfo(itemLink)

	end	
	
end


function uespLog.OnGoldPickpocketed(eventCode, goldAmount)
	uespLog.DebugExtraMsg("Pickpocketed "..tostring(goldAmount).." gold")
end


function uespLog.OnGoldRemoved(eventCode, goldAmount)
	uespLog.DebugExtraMsg("Justice: Removed "..tostring(goldAmount).." gold")
end


function uespLog.OnItemPickpocketed (eventCode, itemName, itemCount)

	if (itemCount == 1) then
		uespLog.DebugExtraMsg("Pickpocketed "..tostring(itemName))
	else
		uespLog.DebugExtraMsg("Pickpocketed "..tostring(itemName).." (x"..tostring(itemCount)..")")
	end
	
end


function uespLog.GetAllianceShortName (allianceIndex)
	if (uespLog.ALLIANCE_SHORT_NAMES[allianceIndex] == nil) then return "??" end
	return uespLog.ALLIANCE_SHORT_NAMES[allianceIndex]
end


uespLog.SHORT_ALLIANCE_COLORED_NAMES = { }

uespLog.ALLIANCE_COLORS = 
{
    [ALLIANCE_ALDMERI_DOMINION] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, ALLIANCE_ALDMERI_DOMINION)),
    [ALLIANCE_EBONHEART_PACT] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, ALLIANCE_EBONHEART_PACT)),
    [ALLIANCE_DAGGERFALL_COVENANT] = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, ALLIANCE_DAGGERFALL_COVENANT)),
}


function GetColoredAllianceShortName(alliance)
    local coloredName = SHORT_ALLIANCE_COLORED_NAMES[alliance]
	
    if (coloredName == nil) then
        local color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, alliance))
        SHORT_ALLIANCE_COLORED_NAMES[alliance] = color:Colorize(GetAllianceShortName(alliance))
        return SHORT_ALLIANCE_COLORED_NAMES[alliance]
    end
	
    return coloredName
end


function uespLog.GetAllianceColoredName (alliance, name)
    local color = uespLog.ALLIANCE_COLORS[alliance]
	
    if (color == nil) then return name end
    return color:Colorize(name) .. "|r"
end


function uespLog.OnArtifactControlState (eventCode, artifactName, keepId, playerName, playerAlliance, controlEvent, controlState, campaignId)
	local msg = ""
	
	if (not uespLog.IsPvpUpdate()) then return end
	
	msg = msg .. tostring(artifactName) .. " changed state by " .. tostring(playerName) .. "[" .. uespLog.GetAllianceShortName(playerAlliance) .. "]."
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnCaptureAreaStatus (eventCode, keepId, objectiveId, battlegroundContext, capturePoolValue, capturePoolMax, capturingPlayers, contestingPlayers, owningAlliance)
	local msg = ""
	
	if (not uespLog.IsPvpUpdate()) then return end
	
	--local objName, ovbjType, objState, param1, param2 = GetAvAObjectiveInfo(keepId, objectiveId, battlegroundContext)
	local name = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, battlegroundContext)
	
	if (capturePoolValue ~= 100) then		
		msg = tostring(name) .. " capture at "..tostring(capturePoolValue).. "% by "..uespLog.GetAllianceShortName(owningAlliance) .. "."
		uespLog.MsgColor(uespLog.pvpColor, msg)
	end
end


function uespLog.OnCoronateEmpererNotification  (eventCode, campaignId, emperorName, emperorAlliance)
	local msg = ""
	
	if (not uespLog.IsPvpUpdate()) then return end
	if (GetCurrentCampaignId() ~= campaignId) then return end
	
	msg = tostring(emperorName) .. "["..tostring(uespLog.GetAllianceShortName(emperorAlliance)).."] was crowned Emperor!"
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnObjectiveControlState (eventCode, objectiveKeepId, objectiveObjectiveId, battlegroundContext, objectiveName, objectiveType, objectiveControlEvent, objectiveControlState, objectiveParam1, objectiveParam2)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	local name = GetKeepName(objectiveKeepId)
	local alliance = GetKeepAlliance(objectiveKeepId, battlegroundContext)
	--local objName, objType, objState, param1, param2 = GetAvAObjectiveInfo(keepId, objectiveId, battlegroundContext)
	local colorName = uespLog.GetAllianceColoredName(alliance, objectiveName.."["..uespLog.GetAllianceShortName(alliance).."]")
	local eventDesc = GetAvAObjectiveEventDescription(objectiveKeepId, objectiveObjectiveId, colorName.."|c"..uespLog.pvpColor, objectiveType, objectiveControlEvent, objectiveParam1, objectiveParam2)
	
	if (eventDesc ~= nil and eventDesc ~= "") then
		msg = tostring(eventDesc)
		uespLog.MsgColor(uespLog.pvpColor, msg)
	end
	
end


function uespLog.OnKeepAllianceOwnerChanged (eventCode, keepId, battlegroundContext, owningAlliance)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	local name = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, battlegroundContext)
	local alliance
	
	msg = tostring(name).."|c"..uespLog.pvpColor.." changed ownership to "..GetColoredAllianceName(owningAlliance).."."
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnKeepResourceUpdate (eventCode, keepId)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	msg = "Resource update for keep "..tostring(keepId) .. "."
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnKeepUnderAttack (eventCode, keepId, battlegroundContext, underAttack)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	local name = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, battlegroundContext)
	local colorName = uespLog.GetAllianceColoredName(alliance, name.."["..uespLog.GetAllianceShortName(alliance).."]")
	
	if (underAttack) then
		msg = colorName.."|c"..uespLog.pvpColor.." is under attack!".."|r"
	else
		msg = colorName.."|c"..uespLog.pvpColor.." is no longer under attack.".."|r"
	end
	
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnKeepGateStateChanged (eventCode, keepId, open)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	local name = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, battlegroundContext)
	local colorName = uespLog.GetAllianceColoredName(alliance, name.."["..uespLog.GetAllianceShortName(alliance).."]")
	
	if (underAttack) then
		msg = colorName.."|c"..uespLog.pvpColor.." is now open!".."|r"
	else
		msg = colorName.."|c"..uespLog.pvpColor.." is now closed!".."|r"
	end
	
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


function uespLog.OnGuildKeepClaimUpdated (eventCode, keepId, battlegroundContext)
	local msg = ""
	if (not uespLog.IsPvpUpdate()) then return end
	
	local name = GetKeepName(keepId)
	local alliance = GetKeepAlliance(keepId, battlegroundContext)
	local colorName = uespLog.GetAllianceColoredName(alliance, name.."["..uespLog.GetAllianceShortName(alliance).."]")
	
	msg = colorName.."|c"..uespLog.pvpColor.." ownership was changed.".."|r"
	uespLog.MsgColor(uespLog.pvpColor, msg)
end


SLASH_COMMANDS["/uesppvp"] = function (cmd)
	cmd = string.lower(cmd)

	if (cmd == "on") then
		uespLog.SetPvpUpdate(true)
		uespLog.Msg("PVP update is now ON!")
	elseif (cmd == "off") then
		uespLog.SetPvpUpdate(false)
		uespLog.Msg("PVP update is now OFF!")
	elseif (cmd == "showfights") then
		uespLog.ShowPvpFights()
	else
		uespLog.Msg("PVP update is currently "..uespLog.BoolToOnOff(uespLog.IsPvpUpdate()))
		uespLog.Msg("    Use /uesppvp on/off to change setting")
	end
	
end


uespLog.KnownLocalBattles = { }
uespLog.KNOWN_LOCAL_BATTLES_DELETETIMEMS = 300000


uespLog.PINTYPE_BATTLE_NAMES = {
	[83] = "Large Keep Attack",
	[84] = "Small Keep Attack",
	[96] = "Small EP vs AD battle",
	[97] = "Medium EP vs AD battle",
	[98] = "Large EP vs AD battle",
	[99] = "Small AD vs DC battle",
	[100] = "Medium AD vs DC battle",
	[101] = "Large AD vs DC battle",
	[102] = "Small DC vs EP battle",
	[103] = "Medium DC vs EP battle",
	[104] = "Large DC vs EP battle",
}


function uespLog.FindClosestKeep(nx, ny)
	local numAvaObj = GetNumAvAObjectives()
	local bestIndex = -1
	local bestDistance = 100000
	
	for i = 1, numAvaObj do
		local keepId, objId, bgContext = GetAvAObjectiveKeysByIndex(i)
		local pinType, currentX, currentY, contUpdate = GetAvAObjectivePinInfo(keepId, objId, bgContext)
		
		local diffX = nx - currentX
		local diffY = ny - currentY
		local distance = math.sqrt(diffX * diffX + diffY * diffY)
		
		if (distance < bestDistance) then
			bestDistance = distance
			bestIndex = i
		end
	end
	
	local keepId, objId, bgContext = GetAvAObjectiveKeysByIndex(bestIndex)
	local pinType, currentX, currentY, contUpdate = GetAvAObjectivePinInfo(keepId, objId, bgContext)
	local diffX = currentX - nx
	local diffY = currentY - ny
	local angle = math.atan2(diffY, diffX) * 57.29578
	local direction = "?"
	
	if (angle >= -22.5 and angle < 22.5) then
		direction = "E"
	elseif (angle >= 22.5 and angle < 67.5) then
		direction = "NE"
	elseif (angle >= 67.5 and angle < 112.5) then
		direction = "N"
	elseif (angle >= 112.5 and angle < 157.5) then
		direction = "NW"
	elseif (angle >= 157.5 or angle < -157.5) then
		direction = "W"
	elseif (angle >= -157.5 and angle < -112.5) then
		direction = "SW"
	elseif (angle >= -112.5 and angle < -67.5) then
		direction = "S"
	elseif (angle >= -67.5 and angle < -22.5) then
		direction = "SE"
	end
		
	return keepId, objId, bgContext, direction
end


function uespLog.CheckForNewLocalBattles()

	if (not uespLog.IsPvpUpdate()) then return end
	uespLog.DeleteOldKnownLocalBattles()
	
	uespLog.FindPvpFights(false)
	
	local killNum = GetNumKillLocations()
	
	for i = 1, killNum do
		local pinType, currentX, currentY = GetKillLocationPinInfo(i)
		
		if (pinType ~= nil) then
			if ((pinType >= 83 and pinType <= 83) or (pinType >= 96 and pinType <= 104)) then
				local uniqueId = math.floor(math.floor((currentX or 0) * 1000)*1000 + math.floor((currentY or 0)*1000))
			
				if (uespLog.KnownLocalBattles[uniqueId] == nil) then            
					uespLog.KnownLocalBattles[uniqueId] = GetGameTimeMilliseconds()
				
					local coorStr = string.format("(%0.3f, %0.3f)", currentX, currentY)
					local pinName = uespLog.PINTYPE_BATTLE_NAMES[pinType] or "battle"
					local keepId, objId, bgContext, direction = uespLog.FindClosestKeep(currentX, currentY)
					local name = GetKeepName(keepId)
					local alliance = GetKeepAlliance(keepId, bgContext)
					local colorName = uespLog.GetAllianceColoredName(alliance, name.."["..uespLog.GetAllianceShortName(alliance).."]")
					local msg = "" .. pinName .. " "..direction.." of "..colorName.."|c"..uespLog.pvpColor.." "..coorStr.."|r"
					--local msg = "Found " .. pinName .. ", "..coorStr.." in current map"
					
					uespLog.MsgColor(uespLog.pvpColor, msg)
				end
			end
		end
	end
			
end


function uespLog.FindPvpFights(showAll)
	local killNum = GetNumKillLocations()
	local outputNum = 0
	
	for i = 1, killNum do
		local pinType, currentX, currentY = GetKillLocationPinInfo(i)
		
		if (pinType ~= nil) then
			if ((pinType >= 83 and pinType <= 83) or (pinType >= 96 and pinType <= 104)) then
				local uniqueId = math.floor(math.floor((currentX or 0) * 1000)*1000 + math.floor((currentY or 0)*1000))
			
				if (showAll or uespLog.KnownLocalBattles[uniqueId] == nil) then            
				
					if (not showAll) then
						uespLog.KnownLocalBattles[uniqueId] = GetGameTimeMilliseconds()
					end
				
					local coorStr = string.format("(%0.3f, %0.3f)", currentX, currentY)
					local pinName = uespLog.PINTYPE_BATTLE_NAMES[pinType] or "battle"
					local keepId, objId, bgContext, direction = uespLog.FindClosestKeep(currentX, currentY)
					local name = GetKeepName(keepId)
					local alliance = GetKeepAlliance(keepId, bgContext)
					local colorName = uespLog.GetAllianceColoredName(alliance, name.."["..uespLog.GetAllianceShortName(alliance).."]")
					local msg = "" .. pinName .. " "..direction.." of "..colorName.."|c"..uespLog.pvpColor.." "..coorStr.."|r"
					--local msg = "Found " .. pinName .. ", "..coorStr.." in current map"
					
					uespLog.MsgColor(uespLog.pvpColor, msg)
					outputNum = outputNum + 1
				end
			end
		end
	end
	
	if (showAll and outputNum == 0) then
		uespLog.MsgColor(uespLog.pvpColor, "No PVP fights found!")
	end
			
end


function uespLog.DeleteOldKnownLocalBattles()
	local idsToDelete = { }
	local CurrentTime = GetGameTimeMilliseconds()
	
	for id, knownBattleTime in pairs(uespLog.KnownLocalBattles) do
	
		if (knownBattleTime == nil) then
			idsToDelete[#idsToDelete + 1] = id
		elseif (CurrentTime - knownBattleTime >= uespLog.KNOWN_LOCAL_BATTLES_DELETETIMEMS) then
			idsToDelete[#idsToDelete + 1] = id
		end
	end
	
	for i = 1, #idsToDelete do
		uespLog.KnownLocalBattles[idsToDelete[i]] = nil
	end
	
end


function uespLog.ShowPvpFights()
	local killNum = GetNumKillLocations()
	
	if (killNum == 0) then
		uespLog.MsgColor(uespLog.pvpColor, "No PVP fights found!")
	else
		--uespLog.MsgColor(uespLog.pvpColor, tostring(killNum).." PVP fights found!")
		uespLog.FindPvpFights(true)
	end
end


SLASH_COMMANDS["/upf"] = uespLog.ShowPvpFights


SLASH_COMMANDS["/uesplorebook"] = function (cmd)
	cmd = string.lower(cmd)
	
	if (cmd == 'on') then
		uespLog.SetLoreBookMsgFlag(true)
		uespLog.Msg("UESP::Set LoreBook to: "..uespLog.BoolToOnOff(uespLog.GetLoreBookMsgFlag()) )
	elseif (cmd == 'off') then
		uespLog.SetLoreBookMsgFlag(false)
		uespLog.Msg("UESP::Set LoreBook to: "..uespLog.BoolToOnOff(uespLog.GetLoreBookMsgFlag()) )
	elseif (cmd == '') then
		uespLog.Msg("UESP::Current LoreBook Setting is: "..uespLog.BoolToOnOff(uespLog.GetLoreBookMsgFlag()) )
	else
		uespLog.Msg("UESP::Turns on/off the 'LoreBook Learned' messages.")
		uespLog.Msg(".     Use the format: /uesplorebook [on/off]")
		uespLog.Msg(".     Current Setting is: "..uespLog.BoolToOnOff(uespLog.GetLoreBookMsgFlag()) )
	end
		
end


function uespLog.EventLoreBookLearned(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
	uespLog.DebugMsg("LoreBook Learned: "..tostring(guildReputationIndex))
	
	if (uespLog.GetLoreBookMsgFlag() == 'on') then
		return uespLog.origLoreBookLearnedFunction(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
	else
	
		if (guildReputationIndex > 0 and isMaxRank) then
			return uespLog.origLoreBookLearnedFunction(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, isMaxRank)
		end
	end
	
end


function uespLog.EventLoreBookLearnedSkillExperience(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, skillType, skillIndex, rank, previousXP, currentXP)
	uespLog.DebugMsg("LoreBookSkillExp Learned: "..tostring(guildReputationIndex))
	return uespLog.origLoreBookLearnedSkillExpFunction(categoryIndex, collectionIndex, bookIndex, guildReputationIndex, skillType, skillIndex, rank, previousXP, currentXP)
end


SLASH_COMMANDS["/ulb"] = SLASH_COMMANDS["/uesplorebook"]

