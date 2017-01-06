-- uespLogSalesData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the saving of guild sales data.
--
--	EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE
--	EVENT_TRADING_HOUSE_RESPONSE_RECEIVED
--	EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE
--	EVENT_TRADING_HOUSE_RESPONSE_RECEIVED
--	EVENT_PLAYER_ACTIVATED
-- 		guild remove/add?
--


uespLog.SALES_FIRSTSCAN_DELAYMS = 3000
uespLog.SALES_SCAN_DELAY = 1500
uespLog.NewGuildSales = 0
uespLog.SalesCurrentGuildIndex = 1
uespLog.SalesStartEventIndex = 1
uespLog.SalesScanCurrentLastTimestamp = -1
uespLog.MAX_GUILD_INDEX = 5


function uespLog.GetSalesDataConfig()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	return uespLog.savedVars.settings.data.salesData
end


function uespLog.IsSalesDataSave()
	local salesConfig = uespLog.GetSalesDataConfig()
	return salesConfig.saveSales
end


function uespLog.OnActivateSalesData()
	zo_callLater(uespLog.SaveNewSalesData, uespLog.SALES_FIRSTSCAN_DELAYMS)
end


function uespLog.SaveNewSalesData()

	uespLog.NewGuildSales = 0
	uespLog.SalesCurrentGuildIndex = 1
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesScanCurrentLastTimestamp = -1

	if (not uespLog.IsSalesDataSave()) then
		return
	end	
	
	uespLog.DebugMsg("UESP: Looking for new guild sales data...")
		
	for i = 1, uespLog.MAX_GUILD_INDEX do
		uespLog.SaveGuildSummary(i)
	end
	
	uespLog.StartGuildSalesScan(1)

	--uespLog.DebugMsg("UESP: Found and saved "..tostring(newSales).." new guild sales!")
end


function uespLog.StartGuildSalesScan(guildIndex)

	if (guildIndex > uespLog.MAX_GUILD_INDEX) then
		uespLog.DebugMsg("UESP: Found and saved "..tostring(uespLog.NewGuildSales).." new guild sales!")
		return false
	end
		
	uespLog.DebugExtraMsg("UESP: Starting sales scan for guild #"..tostring(guildIndex))
	
	local guildId = GetGuildId(guildIndex)
	local requested = RequestGuildHistoryCategoryNewest(guildId, GUILD_HISTORY_STORE)
	
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesCurrentGuildIndex = guildIndex
	uespLog.SalesScanCurrentLastTimestamp = -1
	
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.StartGuildSalesScanMore(guildIndex)
	local guildId = GetGuildId(guildIndex)
	local hasMore = DoesGuildHistoryCategoryHaveMoreEvents(guildId, GUILD_HISTORY_STORE)
		
	if (not hasMore) then
		uespLog.StartGuildSalesScan(guildIndex + 1)
		return true
	end
		
	uespLog.SalesStartEventIndex = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
	uespLog.SalesCurrentGuildIndex = guildIndex
	
	uespLog.DebugExtraMsg("UESP: Loading more sales for guild #"..tostring(guildIndex)..", starting at event #"..tostring(uespLog.SalesStartEventIndex))
	
	local requested = RequestGuildHistoryCategoryOlder(guildId, GUILD_HISTORY_STORE)
	uespLog.DebugMsg(".     Requested = "..tostring(requested))
	
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.ScanGuildSales(guildIndex)
	local salesConfig = uespLog.GetSalesDataConfig()
	local guildConfig = salesConfig[guildIndex]
	local lastTimestamp = salesConfig.lastTimestamp
	local guildId = GetGuildId(guildIndex)
	local requested = false
	local currentTimestamp = GetTimeStamp()
	
	if (guildConfig.lastTimestamp < lastTimestamp) then
		lastTimestamp = guildConfig.lastTimestamp
	end
	
	if (uespLog.SalesScanCurrentLastTimestamp >= 0) then
		lastTimestamp = uespLog.SalesScanCurrentLastTimestamp
	else
		guildConfig.lastTimestamp = currentTimestamp
		salesConfig.lastTimestamp = currentTimestamp
		uespLog.SalesScanCurrentLastTimestamp = lastTimestamp
	end
	
	uespLog.DebugExtraMsg("UESP: Scanning sales for guild #"..tostring(guildIndex)..", up to timestamp "..lastTimestamp)
	
	local scanMore = uespLog.ScanGuildSales_Loop(guildId, currentTimestamp, lastTimestamp)
	
	if (scanMore) then
		uespLog.StartGuildSalesScanMore(guildIndex)
	else
		uespLog.StartGuildSalesScan(guildIndex + 1)
	end
	
end


function uespLog.ScanGuildSales_Loop(guildId, currentTimestamp, lastTimestamp)
	local numEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
	
	if (numEvents <= 0) then
		return false
	end
	
	for eventIndex = uespLog.SalesStartEventIndex, numEvents do
		local eventType, seconds = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, eventIndex)
		local eventTimestamp = currentTimestamp - seconds
		
		if (eventTimestamp < lastTimestamp) then
			return false
		end
		
		if (eventType == GUILD_EVENT_ITEM_SOLD) then
			uespLog.SaveGuildPurchase(guildId, eventIndex)
			uespLog.NewGuildSales = uespLog.NewGuildSales + 1
		end
	end
	
	return true
end


function uespLog.SaveGuildSummary(guildIndex)
	local logData = {}
	
	logData.event = "GuildSummary"
	logData.guildIndex = guildIndex
	logData.guildId = GetGuildId(guildIndex)
	
	if (logData.guildId <= 0) then
		return
	end
	
	logData.name = GetGuildName(logData.guildId)
	logData.founded = GetGuildFoundedDate(logData.guildId)
	logData.numMembers, logData.numOnline, logData.leader = GetGuildInfo(logData.guildId)
	--logData.description = GetGuildDescription(logData.guildId)
	--logData.motd = GetGuildMotD(logData.guildId)
	logData.kiosk = GetGuildOwnedKioskInfo(guildId)
	logData.server = GetWorldName()
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.SaveGuildPurchase(guildId, eventIndex)
	local eventType, seconds, seller, buyer, qnt, itemLink, gold, taxes = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, eventIndex)
	local eventId = GetGuildEventId(guildId, GUILD_HISTORY_STORE, eventIndex)
	local logData = {}
	local currentTimestamp = GetTimeStamp()
	
	logData.event = "GuildSale"
	logData.type = eventType
	logData.timestamp = currentTimestamp - seconds
	logData.eventId = Id64ToString(eventId)
	logData.seller = seller
	logData.buyer = buyer
	logData.qnt = qnt
	logData.gold = gold
	logData.taxes = taxes
	logData.server = GetWorldName()
	logData.guild = GetGuildName(guildId)
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.ResetNewSalesDataTimestamps()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	salesConfig.lastTimestamp = 0
	
	for i = 1, 5 do
		salesConfig[i].lastTimestamp = 0
	end
end