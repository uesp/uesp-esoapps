-- uespLogSalesData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the saving of guild sales data.
--
--	EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE
--	EVENT_TRADING_HOUSE_RESPONSE_RECEIVED
--	EVENT_PLAYER_ACTIVATED
--  EVENT_GUILD_SELF_JOINED_GUILD
--	EVENT_GUILD_SELF_LEFT_GUILD
--	EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE
--


uespLog.SALES_FIRSTSCAN_DELAYMS = 3000
uespLog.SALES_SCAN_DELAY = 1500
uespLog.SALESSCAN_EXTRADELAY = 200
uespLog.NewGuildSales = 0
uespLog.SalesCurrentGuildIndex = 1
uespLog.SalesStartEventIndex = 1
uespLog.SalesScanCurrentLastTimestamp = -1
uespLog.SalesRequestId = -1
uespLog.SalesScanSingleGuild = false
uespLog.MAX_GUILD_INDEX = 5
uespLog.SalesCurrentListingData = {}
uespLog.SALES_MAX_LISTING_TIME = 30*86400
uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
uespLog.IsSavingGuildSales = false
uespLog.SalesBadScanCount = 0
uespLog.GuildSalesLastListingTimestamp = 0

uespLog.SalesGuildSearchScanStarted = false
uespLog.SalesGuildSearchScanNumItems = 0
uespLog.SalesGuildSearchScanPage = 0
uespLog.SalesGuildSearchScanStartTime = 0
uespLog.SalesGuildSearchScanLastTimestamp = 0
uespLog.SalesGuildSearchScanFinish = false
uespLog.SalesGuildSearchScanFinishIndex = 0
uespLog.SalesGuildSearchScanAllGuilds = false 
uespLog.SalesGuildSearchScanGuildId = 1
uespLog.SalesGuildSearchScanGuildCount = 0
uespLog.SalesGuildSearchLastError = false

uespLog.SalesLastSearchCooldownGameTime = 0
uespLog.SalesLastSearchCooldownUpdate = false
uespLog.SalesLastSearchCooldownCount = 0
uespLog.SalesLastSearchCooldownMaxCount = 10
uespLog.SalesLastTraderRequestTime = 0

uespLog.Orig_WritWorthyMMPrice = nil

uespLog.SalesPrices = nil
uespLog.SalesPricesVersion = 0

uespLog.SalesDealValues = {}
uespLog.SalesDealProfits = {}


function uespLog.LoadSalePriceData()

	if ((uespLog.IsSalesShowPrices() or uespLog.IsSalesShowTooltip()) and uespLog.InitSalesPrices ~= nil) then
		uespLog.InitSalesPrices()
		uespLog.InitSalesFunctions()
	else
		uespLog.SalesPrices = nil
		uespLog.SalesPricesVersion = 0
	end
	
end


function uespLog.InitSalesFunctions()

	if (MasterMerchant ~= nil) then
		MasterMerchant.SetupPendingPost = uespLog.SetupPendingPost
	end
	
	TRADING_HOUSE.SetupPendingPost = uespLog.SetupPendingPost
	
	if (WritWorthy ~= nil and WritWorthy.Util ~= nil) then
	
		if (uespLog.Orig_WritWorthyMMPrice == nil) then
			uespLog.Orig_WritWorthyMMPrice = WritWorthy.Util.MMPrice
		end
		
		WritWorthy.Util.MMPrice = uespLog.WritWorthyMMPrice
	end

end


function uespLog.GetSalesDataConfig()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	return uespLog.savedVars.settings.data.salesData
end


function uespLog.SetSalesDataSave(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.saveSales = flag
	
	uespLog.UpdateUespScanSalesButton()
end


function uespLog.IsSalesDataSave()
	local salesConfig = uespLog.GetSalesDataConfig()
	return salesConfig.saveSales
end


function uespLog.SetSalesShowPrices(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.showPrices = flag
	
	uespLog.LoadSalePriceData()
end


function uespLog.IsSalesShowPrices()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	if (salesConfig.showPrices == nil) then
		salesConfig.showPrices = false
	end
	
	return salesConfig.showPrices
end


function uespLog.SetSalesShowTooltip(flag)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.showTooltip = flag
end


function uespLog.IsSalesShowTooltip()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	if (salesConfig.showTooltip == nil) then
		salesConfig.showTooltip = false
	end
	
	return salesConfig.showTooltip
end


function uespLog.SetSalesShowSaleType(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.showSaleType = value
end


function uespLog.GetSalesShowSaleType()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	if (uespLog.savedVars.settings.data.salesData.showSaleType == nil) then
		uespLog.savedVars.settings.data.salesData.showSaleType = "both"
	end
	
	return uespLog.savedVars.settings.data.salesData.showSaleType
end


function uespLog.SetSalesShowDealType(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.showDealType = value
end


function uespLog.GetSalesPostPriceType()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	if (uespLog.savedVars.settings.data.salesData.postPriceType == nil) then
		uespLog.savedVars.settings.data.salesData.postPriceType = "uesp"
	end
	
	return uespLog.savedVars.settings.data.salesData.postPriceType
end


function uespLog.SetSalesPostPriceType(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.postPriceType = value
end


function uespLog.GetSalesUseWritWorthy()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	if (uespLog.savedVars.settings.data.salesData.useWritWorthy == nil) then
		uespLog.savedVars.settings.data.salesData.useWritWorthy = uespLog.DEFAULT_SETTINGS.salesData.useWritWorthy
	end
	
	return uespLog.savedVars.settings.data.salesData.useWritWorthy
end


function uespLog.SetSalesUseWritWorthy(value)

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.salesData == nil) then
		uespLog.savedVars.settings.data.salesData = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	uespLog.savedVars.settings.data.salesData.useWritWorthy = value
end


function uespLog.GetSalesShowDealType()

	if (uespLog.savedVars.settings == nil) then
		uespLog.savedVars.settings = uespLog.DEFAULT_SETTINGS
	end
	
	if (uespLog.savedVars.settings.data.showSaleType == nil) then
		uespLog.savedVars.settings.data.showSaleType = uespLog.DEFAULT_SETTINGS.salesData
	end
	
	if (uespLog.savedVars.settings.data.salesData.showDealType == nil) then
		uespLog.savedVars.settings.data.salesData.showDealType = "uesp"
	end
	
	return uespLog.savedVars.settings.data.salesData.showDealType
end


function uespLog.OnActivateSalesData()

	if (uespLog.IsSavingGuildSales) then
		return
	end

	uespLog.IsSavingGuildSales = true
	zo_callLater(uespLog.SaveNewSalesData, uespLog.SALES_FIRSTSCAN_DELAYMS)
end


function uespLog.SaveNewSalesData()

	uespLog.NewGuildSales = 0
	uespLog.SalesCurrentGuildIndex = 1
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesScanCurrentLastTimestamp = -1
	uespLog.SalesScanSingleGuild = false
	uespLog.SalesBadScanCount = 0

	if (not uespLog.IsSalesDataSave()) then
		uespLog.IsSavingGuildSales = false
		return
	end	
	
	uespLog.DebugExtraMsg("UESP: Looking for new guild sales data...")
		
	for i = 1, uespLog.MAX_GUILD_INDEX do
		uespLog.SaveGuildSummary(i)
	end
	
	uespLog.StartGuildSalesScan(1)
end


function uespLog.StartGuildSalesScan_old(guildIndex)

	if (RequestGuildHistoryCategoryNewest == nil) then
		--uespLog.DebugExtraMsg("UESP: RequestGuildHistoryCategoryNewest is nil...aborting scan")
		--return false
	end
	
	if (RequestMoreGuildHistoryCategoryEvents == nil) then
		return false
	end

	if (guildIndex > uespLog.MAX_GUILD_INDEX) then
	
		if (uespLog.NewGuildSales > 0) then
			uespLog.Msg("UESP: Found and saved "..tostring(uespLog.NewGuildSales).." new guild sales!")
		else
			uespLog.DebugMsg("UESP: Found no new guild sales since last save!")
		end
		
		uespLog.IsSavingGuildSales = false
		return false
	end
		
	uespLog.DebugExtraMsg("UESP: Starting sales history scan for guild #"..tostring(guildIndex))
	
	local guildId = GetGuildId(guildIndex)
	local requested = RequestMoreGuildHistoryCategoryEvents(guildId, GUILD_HISTORY_STORE)
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
	
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesCurrentGuildIndex = guildIndex
	uespLog.SalesScanCurrentLastTimestamp = -1
	uespLog.SalesBadScanCount = 0
	
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


uespLog.MAX_GUILD_TRADER_EVENTS_LOGCOUNT = 100


function uespLog.StartGuildSalesScan(guildIndex)
	local guildId = GetGuildId(guildIndex)
	
	if (uespLog.SalesRequestId > 0) then
		DestroyGuildHistoryRequest(uespLog.SalesRequestId)
		uespLog.SalesRequestId = -1
	end
	
	if (guildIndex > uespLog.MAX_GUILD_INDEX) then
	
		if (uespLog.NewGuildSales > 0) then
			uespLog.Msg("UESP: Found and saved "..tostring(uespLog.NewGuildSales).." new guild sales!")
		else
			uespLog.DebugMsg("UESP: Found no new guild sales since last save!")
		end
		
		uespLog.IsSavingGuildSales = false
		return false
	end
		
	uespLog.DebugExtraMsg("UESP: Starting sales history scan for guild #"..tostring(guildIndex))
	
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
	
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesCurrentGuildIndex = guildIndex
	uespLog.SalesScanCurrentLastTimestamp = -1
	uespLog.SalesBadScanCount = 0
	
	--uespLog.SalesRequestId = CreateGuildHistoryRequest(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER, GetTimeStamp(), 0)
	--uespLog.SalesRequestId = CreateGuildHistoryRequest(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
	--RequestMoreGuildHistoryEvents(uespLog.SalesRequestId, true)
		
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.StartGuildSalesScanMore(guildIndex)
	local guildId = GetGuildId(guildIndex)
	return false
end


function uespLog.ScanGuildSales_Loop(guildId, currentTimestamp, lastTimestamp)
	local numEvents = GetNumGuildHistoryEvents(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
	
	if (numEvents <= 0) then
		uespLog.DebugExtraMsg("No sales events for guild ID "..tostring(guildId))
		return false
	end
	
	uespLog.DebugExtraMsg("Checking "..tostring(numEvents).." sales events for guild ID "..tostring(guildId).." starting at "..tostring(uespLog.SalesStartEventIndex))
	
	for eventIndex = uespLog.SalesStartEventIndex, numEvents do
		local eventId, seconds, isRedacted, eventType = GetGuildHistoryTraderEventInfo(guildId, eventIndex)
		local eventTimestamp = seconds
		
		if (eventTimestamp < lastTimestamp) then
			return false
		end
		
		if (eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD) then
			uespLog.SaveGuildPurchase(guildId, eventIndex)
			uespLog.NewGuildSales = uespLog.NewGuildSales + 1
		end
	end
	
	return false
end


function uespLog.ScanGuildSales(guildIndex)
	local salesConfig = uespLog.GetSalesDataConfig()
	local guildConfig = salesConfig[guildIndex]
	local lastTimestamp = salesConfig.lastTimestamp
	local guildId = GetGuildId(guildIndex)
	local requested = false
	local currentTimestamp = uespLog.GuildHistoryLastReceivedTimestamp
	local numEvents = GetNumGuildHistoryEvents(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
		
	if (uespLog.SalesStartEventIndex >= numEvents and numEvents > 0) then
		uespLog.SalesBadScanCount = uespLog.SalesBadScanCount + 1
		uespLog.DebugExtraMsg("UESP: Bad guild sale scan "..guildIndex..":"..uespLog.SalesBadScanCount)
		
		if (uespLog.SalesBadScanCount > 10) then
			uespLog.StartGuildSalesScan(guildIndex + 1)
			return false
		end
		
		uespLog.StartGuildSalesScanMore(guildIndex)	
		return false
	end
	
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
	
	uespLog.DebugExtraMsg("UESP: Scanning sales history for guild #"..tostring(guildIndex)..", up to timestamp "..lastTimestamp)
	
	--lastTimestamp = 0
	
	local scanMore = uespLog.ScanGuildSales_Loop(guildId, currentTimestamp, lastTimestamp)
	
	if (scanMore) then
		uespLog.StartGuildSalesScanMore(guildIndex)
	elseif (uespLog.SalesScanSingleGuild) then
		uespLog.SalesScanSingleGuild = false
	else
		uespLog.StartGuildSalesScan(guildIndex + 1)
	end
	
	return true
end


function uespLog.StartGuildSalesScanMore_old(guildIndex)
	local guildId = GetGuildId(guildIndex)
	local hasMore = DoesGuildHistoryCategoryHaveMoreEvents(guildId, GUILD_HISTORY_STORE)
	
	if (RequestGuildHistoryCategoryOlder == nil) then
		--uespLog.DebugExtraMsg("UESP: RequestGuildHistoryCategoryOlder is nil...aborting scan")
		--return false
	end
	
	if (not hasMore) then
	
		if (uespLog.SalesScanSingleGuild) then
			uespLog.SalesScanSingleGuild = false
		else
			uespLog.StartGuildSalesScan(guildIndex + 1)
		end
		
		return true
	end
	
	uespLog.SalesStartEventIndex = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
	uespLog.SalesCurrentGuildIndex = guildIndex
	
	uespLog.DebugExtraMsg("UESP: Loading more sales history for guild #"..tostring(guildIndex)..", starting at event #"..tostring(uespLog.SalesStartEventIndex))
	
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
	local requested = RequestMoreGuildHistoryCategoryEvents(guildId, GUILD_HISTORY_STORE)
	
	-- CreateGuildHistoryRequest(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_, *integer53* _newestTimeS_, *integer53* _oldestTimeS_)
	--		CreateGuildHistoryRequest(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER, 1710423616, 0)
	--		CreateGuildHistoryRequest(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER, GetTimeStamp(), 0)
	--		GetNumGuildHistoryEvents(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
	--		RequestMoreGuildHistoryEvents(3, true)
	--		GetGuildHistoryEventIndicesForTimeRange(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER, 1710423616, 0)
	--		GetGuildHistoryEventIndicesForTimeRange(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER, 0, 1000)
	--		GetGuildHistoryTraderEventInfo(4993, 1)
	--		GetGuildHistoryTraderEventInfo(4993, 603)
	--		GetGuildHistoryTraderEventInfo(4993, 604)
	--		GetOldestGuildHistoryEventIndexForUpToDateEventsWithoutGaps(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
	--		GetNumGuildHistoryEventRanges(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
	--		GetGuildHistoryEventRangeInfo(4993, GUILD_HISTORY_EVENT_CATEGORY_TRADER, 1)
	-- GetNumGuildHistoryEventRanges(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_)
		--_Returns:_ *integer* _numGuildHistoryEventRanges_
	-- GetGuildHistoryEventRangeInfo(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_, *luaindex* _rangeIndex_)
		--_Returns:_ *integer53* _newestTimeS_, *integer53* _oldestTimeS_, *integer53* _newestEventId_, *integer53* _oldestEventId_

	-- GetOldestGuildHistoryEventIndexForUpToDateEventsWithoutGaps(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_)
	-- RequestMoreGuildHistoryEvents (*integer* _requestId_, *bool* _queueRequestIfOnCooldown_)
	-- DestroyGuildHistoryRequest(*integer* _requestId_)
	-- GetNumGuildHistoryEvents(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_)
	-- GetGuildHistoryEventIndicesForTimeRange(*integer* _guildId_, *[GuildHistoryEventCategory|#GuildHistoryEventCategory]* _category_, *integer53* _newestTimeS_, *integer53* _oldestTimeS_)
		--** _Returns:_ *luaindex:nilable* _newestEventIndex_, *luaindex:nilable* _oldestEventIndex_
	--GetGuildHistoryTraderEventInfo(*integer* _guildId_, *luaindex* _eventIndex_)
		--** _Returns:_ *integer53* _eventId_, *integer53* _timestampS_, *[GuildHistoryTraderEvent|#GuildHistoryTraderEvent]* _eventType_, *string* _sellerDisplayName_, *string* _buyerDisplayName_, *string* _itemLink_, *integer* _quantity_, *integer* _price_, *integer* _tax_
			
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.ScanGuildSales_old(guildIndex)
	local salesConfig = uespLog.GetSalesDataConfig()
	local guildConfig = salesConfig[guildIndex]
	local lastTimestamp = salesConfig.lastTimestamp
	local guildId = GetGuildId(guildIndex)
	local requested = false
	local currentTimestamp = uespLog.GuildHistoryLastReceivedTimestamp
	local numEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
		
	if (uespLog.SalesStartEventIndex >= numEvents and numEvents > 0) then
		uespLog.SalesBadScanCount = uespLog.SalesBadScanCount + 1
		uespLog.DebugExtraMsg("UESP: Bad guild sale scan "..guildIndex..":"..uespLog.SalesBadScanCount)
		
		if (uespLog.SalesBadScanCount > 10) then
			uespLog.StartGuildSalesScan(guildIndex + 1)
			return false
		end
		
		uespLog.StartGuildSalesScanMore(guildIndex)	
		return false
	end
	
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
	
	uespLog.DebugExtraMsg("UESP: Scanning sales history for guild #"..tostring(guildIndex)..", up to timestamp "..lastTimestamp)
	
	local scanMore = uespLog.ScanGuildSales_Loop(guildId, currentTimestamp, lastTimestamp)
	
	if (scanMore) then
		uespLog.StartGuildSalesScanMore(guildIndex)
	elseif (uespLog.SalesScanSingleGuild) then
		uespLog.SalesScanSingleGuild = false
	else
		uespLog.StartGuildSalesScan(guildIndex + 1)
	end
	
	return true
end


function uespLog.ScanGuildSales_Loop_old(guildId, currentTimestamp, lastTimestamp)
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
	local salesConfig = uespLog.GetSalesDataConfig()
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
	logData.kiosk = GetGuildOwnedKioskInfo(logData.guildId)
	logData.server = GetWorldName()
	
	salesConfig[guildIndex].guildName = logData.name
	salesConfig[guildIndex].guildId = logData.guildId
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.GetItemLinkRequiredEffectiveLevel(itemLink)
	local reqLevel = GetItemLinkRequiredLevel(itemLink)
	local reqCP = GetItemLinkRequiredChampionPoints(itemLink)
	
	if (reqCP > 0) then
		return 50 + math.floor(reqCP/10)
	end
	
	return reqLevel
end


function uespLog.SaveGuildPurchase(guildId, eventIndex)
	--local eventType, seconds, seller, buyer, qnt, itemLink, gold, taxes = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, eventIndex)
	--local eventId = GetGuildEventId(guildId, GUILD_HISTORY_STORE, eventIndex)
	local eventId, seconds, isRedacted, eventType, seller, buyer, itemLink, qnt, gold, taxes = GetGuildHistoryTraderEventInfo(guildId, eventIndex)
	
	local logData = {}
	local currentTimestamp = GetTimeStamp()
	
	logData.event = "GuildSale"
	logData.type = eventType
	logData.saleTimestamp = tostring(seconds)
	logData.eventId = Id64ToString(eventId)
	logData.seller = seller
	logData.buyer = buyer
	logData.qnt = qnt
	logData.gold = gold
	logData.taxes = taxes
	logData.server = GetWorldName()
	logData.guild = GetGuildName(guildId)
	logData.itemLink = itemLink
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkDisplayQuality(logData.itemLink)
	logData.level = uespLog.GetItemLinkRequiredEffectiveLevel(logData.itemLink)
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.ResetNewSalesDataTimestamps()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	salesConfig.lastTimestamp = 0
	
	for i = 1, 5 do
		salesConfig[i].lastTimestamp = 0
	end
end


function uespLog.ResetLastListingSalesDataTimestamps(guildName)
	local salesConfig = uespLog.GetSalesDataConfig()
		
	if (guildName == nil or guildName == "" or guildName:lower() == "all") then
		salesConfig.guildListTimes = {}
		uespLog.Msg("Reset the last scan timestamps for all listings in all guilds!")
	elseif (guildName:lower() == "current") then
		local _, realGuildName = GetCurrentTradingHouseGuildDetails()		
		
		if (realGuildName ~= nil and realGuildName ~= "") then
			salesConfig.guildListTimes[realGuildName] = 0
			uespLog.Msg("Reset the last scan timestamp for all listings in '"..tostring(realGuildName).."'!")
		else
			uespLog.Msg("You need to be at a guild trader to reset the current guild listings!")
		end
	else
		salesConfig.guildListTimes[guildName] = 0
		uespLog.Msg("Reset the last scan timestamp for all listings in '"..tostring(guildName).."'!")
	end
	
end


function uespLog.OnJoinedGuild (event, guildId, guildName)

	if (not uespLog.IsSalesDataSave()) then
		return
	end

	for i = 1, uespLog.MAX_GUILD_INDEX do
		local id = GetGuildId(i)
		
		if (id == guildId) then
			uespLog.SaveGuildSummary(i)
			uespLog.SalesScanSingleGuild = true
			uespLog.StartGuildSalesScan(i)
			return
		end
	end
	
end


function uespLog.OnLeftGuild (event, guildId, guildName)
	local salesConfig = uespLog.GetSalesDataConfig()
	local oldGuildIndex = -1

	if (not uespLog.IsSalesDataSave()) then
		return
	end
	
	for i = 1, uespLog.MAX_GUILD_INDEX do
		
		if (salesConfig[i].guildName == guildName) then
			uespLog.DeleteGuildSalesData(i)
			return
		end
	end
end


function uespLog.DeleteGuildSalesData(guildIndex)
	local salesConfig = uespLog.GetSalesDataConfig()

	for i = guildIndex, uespLog.MAX_GUILD_INDEX - 1 do
		salesConfig[i] = salesConfig[i + 1]
	end
	
	salesConfig[uespLog.MAX_GUILD_INDEX - 1] = 
	{
		["guildName"] = "",
		["guildId"] = 0,
		["lastTimestamp"] = 0,
	}

end


function uespLog.OnTradingHouseSearchResultsReceived (eventCode, guildId, numItemsOnPage, currentPage, hasMorePages)

	uespLog.DebugExtraMsg("OnTradingHouseSearchResultsReceived "..tostring(numItemsOnPage)..", "..tostring(currentPage)..", "..tostring(hasMorePages))
	
		-- Sometimes this event is called before the actual data is available via the API
	zo_callLater(function () uespLog.OnTradingHouseSearchResultsReceived_Delay(eventCode, guildId, numItemsOnPage, currentPage, hasMorePages) end, 50)
end


function uespLog.OnTradingHouseSearchResultsReceived_Delay (eventCode, guildId, numItemsOnPage, currentPage, hasMorePages)

	if (uespLog.IsSalesDataSave()) then
	
			-- Update 21 doesn't update results control when scanning
		if (uespLog.SalesGuildSearchScanStarted) then
			TRADING_HOUSE:RebuildSearchResultsPage()
		end
		
		uespLog.SaveTradingHouseSalesData(guildId, numItemsOnPage, currentPage)
		
		if (uespLog.SalesGuildSearchScanStarted) then
			uespLog.OnGuildSearchScanItemsReceived(guildId, numItemsOnPage, currentPage, hasMorePages)
		end
		
	end

end


function uespLog.SaveTradingHouseSalesData(guildId, numItemsOnPage, currentPage)
	local currentTimestamp = GetTimeStamp()
	local logData = {}
		
	logData.event = "GuildSaleSearchInfo"
	logData.guildId, logData.name = GetCurrentTradingHouseGuildDetails()
	logData.server = GetWorldName()	
	logData.zone = uespLog.lastTargetData.zone
	logData.lastTarget = uespLog.lastTargetData.name
	logData.kiosk = GetGuildOwnedKioskInfo(guildId)
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	if (numItemsOnPage == 0) then
		return
	end

	if (not uespLog.SalesGuildSearchScanStarted) then
		uespLog.DebugMsg("UESP: Saving "..tostring(numItemsOnPage).." sales from "..logData.name.."...")
	end

	for i = 1, numItemsOnPage do
		local saveResult = uespLog.SaveTradingHouseSalesItem(guildId, i, currentTimestamp, nil, true)
		
		if (not saveResult) then
			uespLog.SalesGuildSearchScanFinishIndex = numItemsOnPage - i + 1
			--uespLog.DebugMsg("Stopped saving items at index "..tostring(i).."!")
			return
		end
	end
	
end


function uespLog.SaveTradingHouseSalesItem(guildId, itemIndex, currentTimestamp, extraData, checkScan)
	local logData = {}
	
	logData.event = "GuildSaleSearchEntry"
	logData.guildId, logData.guild = GetCurrentTradingHouseGuildDetails()
	logData.server = GetWorldName()
	logData.icon, logData.item, logData.quality, logData.qnt, logData.seller, logData.timeRemaining, logData.price, logData.currency, logData.uniqueId = GetTradingHouseSearchResultItemInfo(itemIndex)
	logData.itemLink = GetTradingHouseSearchResultItemLink(itemIndex)
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkDisplayQuality(logData.itemLink)
	logData.level = uespLog.GetItemLinkRequiredEffectiveLevel(logData.itemLink)
	local listTimestamp = currentTimestamp + logData.timeRemaining - uespLog.SALES_MAX_LISTING_TIME
	logData.listTimestamp = tostring(listTimestamp)
	logData.uniqueId = Id64ToString(logData.uniqueId)
	
	if (checkScan and uespLog.SalesGuildSearchScanStarted and listTimestamp < uespLog.SalesGuildSearchScanLastTimestamp) then
		uespLog.SalesGuildSearchScanFinish = true
		--uespLog.DebugMsg("Finished Scan: "..itemIndex..", "..tostring(uespLog.SalesGuildSearchScanStarted)..", "..tostring(listTimestamp)..", "..uespLog.SalesGuildSearchScanLastTimestamp)
		--uespLog.DebugMsg(".   "..currentTimestamp..", "..logData.timeRemaining..", "..uespLog.SALES_MAX_LISTING_TIME)
		--uespLog.DebugMsg(".   ".. GetTradingHouseSearchResultItemLink(itemIndex))
		return false
	end
	
	logData.timeRemaining = nil
	logData.stack = nil
	logData.currency = nil
	
	if (logData.itemLink == "") then
		return true
	end
		
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData(), extraData)
	return true
end


function uespLog.OnTradingHouseError(event, errorCode)
	uespLog.DebugMsg("Trading House Error " .. tostring(errorCode))
	
	if (errorCode == 8) then
	
		if (uespLog.SalesGuildSearchScanStarted) then
			zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
		end
		
	elseif (errorCode == 17) then
	
		if (uespLog.SalesGuildSearchScanStarted) then
			zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
		end
	end
	
end


function uespLog.OnTradingHouseTimeOut(event, errorCode)
	uespLog.DebugExtraMsg("Trading House Time Out " .. tostring(errorCode))
end


function uespLog.OnTradingHouseSearchCooldownUpdate(event, cooldown)
	uespLog.DebugExtraMsg("OnTradingHouseSearchCooldownUpdate " .. tostring(cooldown))
	
	if (cooldown <= 0) then
		uespLog.SalesLastSearchCooldownUpdate = true
		uespLog.SalesLastSearchCooldownGameTime = GetGameTimeMilliseconds()
	end
end


function uespLog.OnTradingHouseResponseReceived(event, responseType, result)
	--TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING
	--TRADING_HOUSE_RESULT_PURCHASE_PENDING
	--TRADING_HOUSE_RESULT_POST_PENDING
	--TRADING_HOUSE_RESULT_LISTINGS_PENDING
	--TRADING_HOUSE_RESULT_SEARCH_PENDING = 14
	
	uespLog.DebugExtraMsg("UESP: OnTradingHouseResponseReceived "..tostring(responseType).. " - "..tostring(result))
	
	if (result ~= TRADING_HOUSE_RESULT_SUCCESS) then
	
		if (result == 8) then
			uespLog.SalesGuildSearchLastError = true
		end
		
		return
	end
		
	if (responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
		uespLog.GuildSalesLastListingTimestamp = GetTimeStamp()
		uespLog.OnTradingHouseListingUpdate()
	elseif (responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING) then
		uespLog.OnTradingHouseListingCancel()
	elseif (responseType == TRADING_HOUSE_RESULT_POST_PENDING) then
		uespLog.OnTradingHouseListingNew()
	elseif (responseType == TRADING_HOUSE_RESULT_SEARCH_PENDING) then
		local numItemsOnPage, currentPage, hasMorePages = GetTradingHouseSearchResultsInfo()
		local guildId = GetCurrentTradingHouseGuildDetails()
		uespLog.OnTradingHouseSearchResultsReceived_Delay(0, guildId, numItemsOnPage, currentPage, hasMorePages)
	elseif (responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING) then
	
		if (uespLog.lastTradingHousePurchaseIndex >= 0 and uespLog.lastTradingHousePurchaseItemLink ~= "" and uespLog.lastTradingHousePurchasePrice > 0) then
			uespLog.MsgColorType(uespLog.MSG_LOOT, uespLog.itemColor, "You purchased "..tostring(uespLog.lastTradingHousePurchaseItemLink).." for "..tostring(uespLog.lastTradingHousePurchasePrice).." gp.")
		end	
	end
	
    uespLog.SetupTradingHouseRowCallbacks()
end


function uespLog.OnTradingHouseListingNew()

	if (uespLog.IsSalesDataSave()) then
		local numListings = GetNumTradingHouseListings()
		
		if (numListings == 0) then
			RequestTradingHouseListings()
			return
		end
		
		--uespLog.SaveTradingHouseListingData()
		uespLog.SaveTradingHouseListingNewData()
	end
	
end


function uespLog.OnTradingHouseListingCancel()

	if (uespLog.IsSalesDataSave()) then
		uespLog.SaveTradingHouseListingCancelData()
	end
end


function uespLog.OnTradingHouseListingUpdate()

	if (uespLog.IsSalesDataSave()) then
		uespLog.SaveTradingHouseListingData()
	end
	
end


function uespLog.SaveTradingHouseListingCancelData()
	local newListingData = uespLog.MakeSalesListingData()
	local cancelledListings = uespLog.FindMissingListingData(uespLog.SalesCurrentListingData, newListingData)
	
	if (#cancelledListings <= 0) then
		return
	end
	
	uespLog.DebugMsg("UESP: Saving "..tostring(#cancelledListings).." cancelled guild listings...")
	
	for i = 1, #cancelledListings do
		uespLog.SaveTradingHouseListingDataItem("GuildSaleListingEntry::Cancel", uespLog.SalesCurrentListingData[cancelledListings[i]])
	end	
	
	uespLog.SalesCurrentListingData = newListingData
end


function uespLog.SaveTradingHouseListingNewData()
	local newListingData = uespLog.MakeSalesListingData()
	local newListings = uespLog.FindMissingListingData(newListingData, uespLog.SalesCurrentListingData)
	
	if (#newListings <= 0) then
		return
	end
	
	uespLog.DebugMsg("UESP: Saving "..tostring(#newListings).." new guild listings ...")
	
	for i = 1, #newListings do
		uespLog.SaveTradingHouseListingDataItem("GuildSaleListingEntry::Cancel", uespLog.SalesCurrentListingData[newListings[i]])
	end	
	
	uespLog.SalesCurrentListingData = newListingData
end


function uespLog.SaveTradingHouseListingDataItem(eventName, listingData)
	local logData = {}
	
	if (listingData == nil or listingData.itemLink == nil or listingData.itemLink == "") then
		return
	end
		
	logData.event = eventName
	logData.guildId, logData.guild = GetCurrentTradingHouseGuildDetails()
	logData.server = GetWorldName()
	logData.qnt = listingData.qnt
	logData.seller = listingData.seller
	logData.item = listingData.name
	logData.quality = listingData.quality
	logData.price = listingData.price
	logData.itemLink = listingData.itemLink
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkDisplayQuality(logData.itemLink)
	logData.level = uespLog.GetItemLinkRequiredEffectiveLevel(logData.itemLink)
	logData.listTimestamp = tostring(listingData.listTimestamp)
			
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.MakeSalesListingId(listing)
	return tostring(listing.listTimestamp) .. "-" .. tostring(listing.itemLink) .. "-" .. tostring(listing.qnt) .. "-"..tostring(listing.price)
end


function uespLog.FindMissingListingData(oldListing, newListing)
	local itemMap = {}
	local missingListing = {}
	
	for i = 1, #oldListing do
		local listing = oldListing[i]
		local id = uespLog.MakeSalesListingId(listing)
		
		itemMap[id] = 
		{
			["value"] = 1,
			["index"] = i,
		}
	end
	
	for i = 1, #newListing do
		local listing = newListing[i]
		local id = uespLog.MakeSalesListingId(listing)
		
		if (itemMap[id] ~= nil) then
			itemMap[id]["value"] = 0
		end
	end
	
	for id, data in pairs(itemMap) do
	
		if (data.value > 0) then
			missingListing[#missingListing + 1] = data.index
		end
	end
		
	return missingListing
end


function uespLog.MakeSalesListingData()
	local numListings = GetNumTradingHouseListings()
	local data = {}
	local currentTimestamp = uespLog.GuildSalesLastListingTimestamp
	
	for i = 1, numListings do
		local icon, name, quality, qnt, seller, timeRemaining, price, currency, uniqueId = GetTradingHouseListingItemInfo(i)
		local itemLink = GetTradingHouseListingItemLink(i)
	
		data[i] = 
		{
			["listTimestamp"] = currentTimestamp + timeRemaining - uespLog.SALES_MAX_LISTING_TIME,
			["itemLink"] = itemLink,
			["qnt"] = qnt,
			["price"] = price,	
			["name"] = name,		
			["quality"] = quality,	
			["seller"] = seller,
			["uniqueId"] = Id64ToString(uniqueId),
		}
	end
	
	return data
end


function uespLog.SaveTradingHouseListingData()
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
	local logData = {}
	local numListings = GetNumTradingHouseListings()
	local currentTimestamp = uespLog.GuildSalesLastListingTimestamp
	
	uespLog.SalesCurrentListingData = {}

	if (guildName == "" or numListings <= 0) then
		return
	end
	
	uespLog.DebugMsg("UESP: Saving "..tostring(numListings).." guild listings...")
	
	logData.event = "GuildSaleListingInfo"
	logData.guildId = guildId
	logData.name = guildName
	logData.server = GetWorldName()	
	logData.zone = uespLog.lastTargetData.zone
	logData.lastTarget = uespLog.lastTargetData.name
	logData.kiosk = GetGuildOwnedKioskInfo(guildId)
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())

	for i = 1, numListings do
		uespLog.SaveTradingHouseListingItem(i, currentTimestamp)
	end
	
	uespLog.SalesCurrentListingData = uespLog.MakeSalesListingData()
end


function uespLog.SaveTradingHouseListingItem(itemIndex, currentTimestamp)
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
	local logData = {}
		
	logData.event = "GuildSaleListingEntry"
	logData.guildId = guildId
	logData.guild = guildName
	logData.server = GetWorldName()
	logData.icon, logData.item, logData.quality, logData.qnt, logData.seller, logData.timeRemaining, logData.price, _, logData.uniqueId = GetTradingHouseListingItemInfo(itemIndex)
	logData.itemLink = GetTradingHouseListingItemLink(itemIndex)
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkDisplayQuality(logData.itemLink)
	logData.level = uespLog.GetItemLinkRequiredEffectiveLevel(logData.itemLink)
	logData.listTimestamp = tostring(currentTimestamp + logData.timeRemaining - uespLog.SALES_MAX_LISTING_TIME)
	
	logData.timeRemaining = nil
	logData.stack = nil
	
	if (logData.itemLink == "") then
		return
	end
			
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.OnGuildHistoryResponseReceived(event)
	--uespLog.DebugExtraMsg("UESP: OnGuildHistoryResponseReceived")
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
end


function uespLog.OnTradingHouseConfirmPurchase(event, pendingPurchaseIndex)
	local extraData = {}
	local currentTimestamp = GetTimeStamp()
	
	uespLog.DebugExtraMsg("UESP: OnTradingHouseConfirmPurchase "..tostring(pendingPurchaseIndex))
	
	extraData.purchase = 1
	extraData.buyer = GetDisplayName()
	extraData.saleTimestamp = tostring(currentTimestamp)

	uespLog.SaveTradingHouseSalesItem(GetSelectedTradingHouseGuildId(), pendingPurchaseIndex, currentTimestamp, extraData)
end


function uespLog.StartGuildSearchSalesScanAll()
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
	local numTradeGuilds = GetNumTradingHouseGuilds()
	
	if (uespLog.SalesGuildSearchScanStarted) then
		uespLog.Msg("Guild listing scan is already in progress...")
		return
	end
	
	if (GetNumTradingHouseGuilds() == 0) then
		uespLog.Msg("You must be in a guild store in order to start a listing scan!")
		
		if (uespSalesHelper and uespSalesHelper.autoScanStores and uespSalesHelper.currentState == "SCANNING") then
			zo_callLater(uespLog.StartGuildSearchSalesScanAll, 1000)
		end
		
		return
	end
	
	if (numTradeGuilds == 1) then
		uespLog.StartGuildSearchSalesScan()
		return
	end
		
	uespLog.SalesGuildSearchScanGuildCount = numTradeGuilds
	uespLog.SalesGuildSearchScanAllGuilds = true
	uespLog.SalesGuildSearchLastError = false
	uespLog.SalesGuildSearchScanGuildId = 0
	uespLog.SalesGuildSearchScanStarted = false
	
	uespLog.StartGuildSearchSalesScanNextGuild()
end


function uespLog.StartGuildSearchSalesScanNextGuild()
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
	local cooldown = GetTradingHouseCooldownRemaining()
	
	if (not uespLog.SalesGuildSearchScanAllGuilds) then
		return false
	end
	
	if (GetNumTradingHouseGuilds() == 0) then
		uespLog.Msg("Scan Aborted! You must be on a guild trader in order to perform a listing scan.")
		uespLog.SalesGuildSearchScanStarted = false
		uespLog.SalesGuildSearchScanAllGuilds = false
		uespLog.UpdateUespScanSalesButton()
		return
	end
	
	if (cooldown > 0 or not uespLog.SalesLastSearchCooldownUpdate) then
		uespLog.SalesLastSearchCooldownCount = uespLog.SalesLastSearchCooldownCount + 1
		
		if (uespLog.SalesLastSearchCooldownCount < uespLog.SalesLastSearchCooldownMaxCount) then
			zo_callLater(uespLog.StartGuildSearchSalesScanNextGuild, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
			return
		end
	end	
		
	uespLog.SalesGuildSearchScanGuildId = uespLog.SalesGuildSearchScanGuildId + 1
	uespLog.SalesGuildSearchScanStarted = false
		
	if (uespLog.SalesGuildSearchScanGuildId > uespLog.SalesGuildSearchScanGuildCount) then
		uespLog.SalesGuildSearchScanAllGuilds = false
		uespLog.SalesGuildSearchScanStarted = false
		uespLog.Msg("Finished scanning listings from all guilds!")
		uespLog.UpdateUespScanSalesButton()
		
		if (uespSalesHelper and uespSalesHelper.autoScanStores) then
			EndInteraction(26)
		end
		
		return
	end
	
	if (guildId ~= uespLog.SalesGuildSearchScanGuildId) then
	
		if (not SelectTradingHouseGuildId(uespLog.SalesGuildSearchScanGuildId)) then
			uespLog.SalesGuildSearchScanAllGuilds = false
			uespLog.SalesGuildSearchScanStarted = false
			uespLog.Msg("Error: Failed to select guild ID "..tostring(uespLog.SalesGuildSearchScanGuildId).." for listing scan!")
			uespLog.UpdateUespScanSalesButton()
			return
		end
	end
	
	uespLog.StartGuildSearchSalesScan()
end


function uespLog.StartGuildSearchSalesScanPage(startPage)
	local pageNum = tonumber(startPage)
	
	if (pageNum == nil) then
		uespLog.Msg("Error: Page number '"..tostring(startPage).."' is not a valid number!")
		return
	end
	
	uespLog.StartGuildSearchSalesScan(pageNum)
end


function uespLog.StartGuildSearchSalesScan(startPage)

	if (startPage == nil) then
		startPage = 0
	end

	if (uespLog.SalesGuildSearchScanStarted) then
		uespLog.Msg("Guild listing scan is already in progress...")
		return
	end
	
	if (GetNumTradingHouseGuilds() == 0) then
		uespLog.Msg("You must be on a guild trader in order to start a listing scan!")
		return
	end
	
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
	
	uespLog.SalesGuildSearchScanStarted = true
	uespLog.SalesGuildSearchLastError = false
	uespLog.SalesGuildSearchScanNumItems = 0
	uespLog.SalesGuildSearchScanStartTime = GetTimeStamp()
	uespLog.SalesGuildSearchScanLastTimestamp = 0
	uespLog.SalesGuildSearchScanFinishIndex = 0
	uespLog.SalesGuildSearchScanNumItems = 0
	uespLog.SalesGuildSearchScanPage = startPage
	uespLog.SalesGuildSearchScanFinish = false
		
	uespLog.UpdateUespScanSalesButton()
	
	local salesConfig = uespLog.GetSalesDataConfig()
		
	if (salesConfig.guildListTimes[guildName] == nil) then
		uespLog.SalesGuildSearchScanLastTimestamp = 0
		uespLog.Msg("Starting guild listing scan for "..tostring(guildName).." (all items)...do not leave trader until it is finished.")
	else
		uespLog.SalesGuildSearchScanLastTimestamp = salesConfig.guildListTimes[guildName]
		local diff = GetTimeStamp() - uespLog.SalesGuildSearchScanLastTimestamp
		local diffTime = ""
		local days = 0
		local hours = 0
		local minutes = 0
		
		if (diff > 86400) then
			days = diff/86400
			diffTime = string.format("%.1f days", days)
		elseif (diff > 3600) then
			hours = diff/3600
			diffTime = string.format("%.1f hours", hours)
		elseif (diff > 60) then
			minutes = diff/60
			diffTime = string.format("%.1f mins", minutes)
		else
			diffTime = tostring(diff) .. " secs"
		end
		
		if (days > 30) then
			uespLog.Msg("Starting guild listing scan for "..tostring(guildName).." (all items)...do not leave trader until it is finished.")
		else
			uespLog.Msg("Starting guild listing scan for "..tostring(guildName).." (new items in the last "..diffTime..")...do not leave trader until it is finished.")
		end
	end
		
	uespLog.SalesGuildSearchScanListTimestamp = GetTimeStamp()
		
	uespLog.SalesLastSearchCooldownUpdate = false
	uespLog.SalesLastSearchCooldownCount = 0
	uespLog.SalesLastTraderRequestTime = GetTimeStamp()
	
	ClearAllTradingHouseSearchTerms()
	ExecuteTradingHouseSearch(startPage, TRADING_HOUSE_SORT_EXPIRY_TIME, false)
end


function uespLog.StopGuildSearchSalesScan(quiet)

	if (not uespLog.SalesGuildSearchScanStarted) then
		if (quiet ~= true) then
			uespLog.Msg("Guild listing scan has been stopped!")
		end
	end
	
	uespLog.SalesGuildSearchScanStarted = false
	uespLog.SalesGuildSearchScanAllGuilds = false
end


function uespLog.OnGuildSearchScanItemsReceived(guildId, numItemsOnPage, currentPage, hasMorePages)
	local _, guildName = GetCurrentTradingHouseGuildDetails()
	
	if (uespLog.SalesGuildSearchLastError) then
		uespLog.SalesGuildSearchLastError = false
		zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
		return
	end
	
	uespLog.SalesGuildSearchScanPage = uespLog.SalesGuildSearchScanPage + 1
	uespLog.SalesGuildSearchScanNumItems = uespLog.SalesGuildSearchScanNumItems + numItemsOnPage - uespLog.SalesGuildSearchScanFinishIndex
	uespLog.SalesGuildSearchScanFinishIndex = 0

	if (not hasMorePages or uespLog.SalesGuildSearchScanFinish) then
		local deltaTime = GetTimeStamp() - uespLog.SalesGuildSearchScanStartTime
		uespLog.Msg("Finished guild listing scan for "..tostring(guildName).."! "..uespLog.SalesGuildSearchScanNumItems.." items in "..tostring(uespLog.SalesGuildSearchScanPage).." pages scanned in "..tostring(deltaTime).." secs.")	
		uespLog.SalesGuildSearchScanStarted = false
		uespLog.UpdateUespScanSalesButton()
		
		local salesConfig = uespLog.GetSalesDataConfig()
		salesConfig.guildListTimes[guildName] = uespLog.SalesGuildSearchScanListTimestamp
		
		if (uespLog.SalesGuildSearchScanAllGuilds) then
			zo_callLater(uespLog.StartGuildSearchSalesScanNextGuild, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
		elseif (uespSalesHelper and uespSalesHelper.autoScanStores) then
			EndInteraction(26)
		end
		
		return
	end
		
	zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
	
	uespLog.DebugMsg("Scanning "..tostring(guildName)..": Logged "..numItemsOnPage.." items on page "..uespLog.SalesGuildSearchScanPage..".")	
end


function uespLog.DoNextGuildListingScan()
	local cooldown = GetTradingHouseCooldownRemaining()
	
	if (not uespLog.SalesGuildSearchScanStarted) then
		return false
	end

	if (GetNumTradingHouseGuilds() == 0) then
		uespLog.Msg("Scan Aborted! You must be on a guild trader in order to perform a listing scan.")
		uespLog.SalesGuildSearchScanStarted = false
		uespLog.UpdateUespScanSalesButton()
		return
	end
	
	if (cooldown > 0 or not uespLog.SalesLastSearchCooldownUpdate) then
		uespLog.SalesLastSearchCooldownCount = uespLog.SalesLastSearchCooldownCount + 1
		
		if (uespLog.SalesLastSearchCooldownCount < uespLog.SalesLastSearchCooldownMaxCount) then
			zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + uespLog.SALESSCAN_EXTRADELAY)	
			return
		end
	end
	
	uespLog.SalesLastSearchCooldownUpdate = false
	uespLog.SalesLastSearchCooldownCount = 0
	uespLog.SalesLastTraderRequestTime = GetTimeStamp()
	
	ExecuteTradingHouseSearch(uespLog.SalesGuildSearchScanPage, TRADING_HOUSE_SORT_EXPIRY_TIME, false)
end


function uespLog.SalesPriceToChatRowControl(rowControl)
	local itemLink = uespLog.GetItemLinkRowControl(rowControl)

	if (itemLink == nil) then
		return
	end
	
	uespLog.SalesPriceToChat(itemLink)
end

	
function uespLog.AddStatsPopupTooltip() 

	PopupTooltip:GetOwningWindow():SetDrawTier(ZO_Menus:GetDrawTier() - 1)
 	--PopupTooltip:SetHandler("OnMouseUp", MasterMerchant.ThisItem)

	if (not uespLog.IsSalesShowPrices() or not uespLog.IsSalesShowTooltip()) then
		return
	end
		
	if (PopupTooltip.lastLink == nil) then
		return 
	end 
	
	if (uespLog.ActiveTooltipItemLink and uespLog.ActiveTooltipItemLink == PopupTooltip.lastLink) then 
		return
	end

	if (uespLog.activeTip ~= PopupTooltip.lastLink) then
		
		if (PopupTooltip.uespTextPool) then
			PopupTooltip.uespTextPool:ReleaseAllObjects()
		end
		
		PopupTooltip.uespText = nil
	end
	
	uespLog.ActiveTooltipItemLink = PopupTooltip.lastLink

	uespLog.AddSalesPricetoTooltip(PopupTooltip.lastLink, PopupTooltip)
end


function uespLog.RemoveStatsPopupTooltip()
	uespLog.ActiveTooltipItemLink = nil
	
	if (PopupTooltip.uespTextPool) then
		PopupTooltip.uespTextPool:ReleaseAllObjects()
	end
	
	PopupTooltip.uespText = nil
end


function uespLog.GetItemLinkFromItemTooltip() 
	local skMoc = moc()
	local itemLink = nil
	local mocParent = skMoc:GetParent():GetName()
	
	if mocParent == 'ZO_StoreWindowListContents' then 
		itemLink = GetStoreItemLink(skMoc.index)
	elseif mocParent == 'ZO_BuyBackListContents' then 
		itemLink = GetBuybackItemLink(skMoc.index)
	elseif mocParent == 'ZO_TradingHousePostedItemsListContents' then
		local mocData = skMoc.dataEntry.data
		itemLink = GetTradingHouseListingItemLink(mocData.slotIndex)
	elseif mocParent == 'ZO_TradingHouseItemPaneSearchResultsContents' then
		local rData = skMoc.dataEntry and skMoc.dataEntry.data or nil
		
		if not rData or rData.timeRemaining == 0 then return end
		itemLink = GetTradingHouseSearchResultItemLink(rData.slotIndex)

	elseif mocParent == 'ZO_TradingHouseLeftPanePostItemFormInfo' then
		if skMoc.slotIndex and skMoc.bagId then itemLink = GetItemLink(skMoc.bagId, skMoc.slotIndex) end
  
	elseif 	mocParent == 'ZO_PlayerInventoryBackpackContents' or
			mocParent == 'ZO_PlayerInventoryListContents' or
			mocParent == 'ZO_CraftBagListContents' or
			mocParent == 'ZO_QuickSlotListContents' or
			mocParent == 'ZO_PlayerBankBackpackContents' or
			mocParent == 'ZO_SmithingTopLevelImprovementPanelInventoryBackpackContents' or
			mocParent == 'ZO_SmithingTopLevelDeconstructionPanelInventoryBackpackContents' or
			mocParent == 'ZO_SmithingTopLevelRefinementPanelInventoryBackpackContents' or
			mocParent == 'ZO_EnchantingTopLevelInventoryBackpackContents' or
			mocParent == 'ZO_GuildBankBackpackContents' then
			
		if skMoc and skMoc.dataEntry then
            local rData = skMoc.dataEntry.data
            itemLink = GetItemLink(rData.bagId, rData.slotIndex)
		end
  
	elseif mocParent == 'ZO_Character' then 
		itemLink = GetItemLink(skMoc.bagId, skMoc.slotIndex)
	elseif mocParent == 'ZO_LootAlphaContainerListContents' then 
		itemLink = GetLootItemLink(skMoc.dataEntry.data.lootId)
	elseif mocParent == 'ZO_MailInboxMessageAttachments' then 
		itemLink = GetAttachedItemLink(MAIL_INBOX:GetOpenMailId(), skMoc.id, LINK_STYLE_DEFAULT)
	elseif mocParent == 'ZO_MailSendAttachments' then 
		itemLink = GetMailQueuedAttachmentLink(skMoc.id, LINK_STYLE_DEFAULT)
    end
  
  return itemLink
end
 
 
function uespLog.AddStatsItemTooltip() 
	local currentControl = moc()
	
	if (not uespLog.IsSalesShowPrices() or not uespLog.IsSalesShowTooltip()) then
		return
	end
	
	if (not currentControl or not currentControl:GetParent()) then
		return
	end
	
	if (currentControl == uespLog.CurrentTooltipControl) then 
		return 
	end
	
	local itemLink = uespLog.GetItemLinkFromItemTooltip()

	if (itemLink == nil) then
		return
	end
	
    if (uespLog.CurrentTooltipControl ~= currentControl) then
	
		if (ItemTooltip.uespTextPool) then
			ItemTooltip.uespTextPool:ReleaseAllObjects()
		end
		
		ItemTooltip.uespText = nil
    end

    uespLog.CurrentTooltipControl = currentControl
    uespLog.AddSalesPricetoTooltip(itemLink, ItemTooltip)
end
	
	
function uespLog.RemoveStatsItemTooltip() 
	uespLog.CurrentTooltipControl = nil 
	
	if (ItemTooltip.uespTextPool) then
		ItemTooltip.uespTextPool:ReleaseAllObjects()
	end
	
	ItemTooltip.uespText = nil
end


function uespLog.AddSalesPricetoTooltip(itemLink, tooltip)
		
    if (not uespLog.IsSalesShowPrices() or not uespLog.IsSalesShowTooltip()) then
		return
	end
	
	local msg = uespLog.GetSalesPriceTip(itemLink, false)
	
	if (not tooltip.uespTextPool) then
		tooltip.uespTextPool = ZO_ControlPool:New('UespTooltipSalesLabel', tooltip, 'UespText')
	end

	if (not tooltip.uespText) then
		tooltip.uespText = tooltip.uespTextPool:AcquireObject()
		tooltip:AddControl(tooltip.uespText)
		tooltip.uespText:SetAnchor(CENTER)   
	end

	if (tooltip.uespText) then
		tooltip.uespText:SetText(msg)
		tooltip.uespText:SetColor(1,1,1,1)
	end
	
end


function uespLog.GetSalesPriceTip(itemLink, isChat)

	if (itemLink == nil) then
		return ""
	end
	
	local prices = uespLog.FindSalesPrice(itemLink)
	local newItemLink = itemLink:gsub("|H0:", "|H1:")
	
	if (prices == nil) then
		if (isChat) then
			return "UESP has no price data for "..tostring(newItemLink)
		else
			return ""
		end
	end
	
	local price = prices.price
	local countSold = prices.countSold
	local countListed = prices.countListed
	local itemCount = prices.items
	
	if (uespLog.GetSalesShowSaleType() == "list") then
		price = prices.priceListed
		countSold = 0
		countListed = prices.countListed
		itemCount = prices.itemsListed
	elseif (uespLog.GetSalesShowSaleType() == "sold") then
		price = prices.priceSold
		countSold = prices.countSold
		countListed = 0
		itemCount = prices.itemsSold
	end
	
	if (countSold + countListed == 0) then
		if (isChat) then
			return "UESP has no price data for "..tostring(newItemLink)
		else
			return ""
		end
	end
			
	local msg = "UESP price ("
		
	if (countListed > 0) then
		
		if (countListed >= 1000) then
			msg = msg .. tostring(math.floor(countListed/1000)).."k listed"
		else		
			msg = msg .. tostring(countListed).." listed"
		end
		
		if (countSold > 0) then
			msg = msg .. ", "
		end
	end
	
	if (countSold >= 1000) then
		msg = msg .. tostring(math.floor(countSold/1000)).."k sold"
	elseif (countSold > 0) then
		msg = msg .. tostring(countSold).." sold"
	end	
	
	if (itemCount > countSold + countListed) then
	
		if (itemCount >= 1000000) then
			msg = msg .. ", "..tostring(math.floor(itemCount/1000000)).."M items"
		elseif (itemCount >= 1000) then
			msg = msg .. ", "..tostring(math.floor(itemCount/1000)).."k items"
		else
			msg = msg .. ", "..tostring(itemCount).." items"
		end
	end
	
	msg = msg .. "): " .. tostring(price)
	
	if (isChat) then
		msg = msg .. " gp for "..tostring(newItemLink)
	else
		msg = msg .. "|t16:16:EsoUI/Art/currency/currency_gold.dds|t"
	end
	
	return msg
end


function uespLog.SalesPriceToChat(itemLink)
	local msg = uespLog.GetSalesPriceTip(itemLink, true)
	
	local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    ChatEditControl:InsertText(msg)
end


function uespLog.FindSalesPrice(itemLink)

	if (itemLink == nil) then
		return nil
	end
	
	local linkData = uespLog.ParseItemLinkEx(itemLink)
	
	if (not linkData or uespLog.SalesPrices == nil) then
		return nil
	end
	
	linkData.itemId = tonumber(linkData.itemId)
	
	local levelData = uespLog.SalesPrices[linkData.itemId]
	
	if (levelData == nil) then
		--uespLog.DebugMsg("FindSalesPrice: No ItemID Data")
		return nil
	end
	
	local quality = GetItemLinkDisplayQuality(itemLink)
	local trait = GetItemLinkTraitInfo(itemLink)
	local level = GetItemLinkRequiredLevel(itemLink)
	local reqCP = GetItemLinkRequiredChampionPoints(itemLink)
	
	if (reqCP > 0) then
		level = 50 + math.floor(reqCP/10)
	end
	
	linkData.potionData = tonumber(linkData.potionData)
	
	if (linkData.potionData == nil) then
		linkData.potionData = 0
	end
	
	if (linkData.writ1 > 0) then
		linkData.potionData = linkData.writ1 .. ":" .. linkData.writ2 .. ":" .. linkData.writ3 .. ":" .. linkData.writ4 .. ":" .. linkData.writ5 .. ":" .. linkData.writ6
	end			
		
	local qualityData = levelData[level]
	
	if (qualityData == nil) then
		--uespLog.DebugMsg("FindSalesPrice: No Level Data")
		return nil
	end
	
	local traitData = qualityData[quality]
	
	if (traitData == nil) then
		--uespLog.DebugMsg("FindSalesPrice: No Quality Data")
		return nil
	end
	
	local potionData = traitData[trait]
	
	if (potionData == nil) then
		--uespLog.DebugMsg("FindSalesPrice: No Trait Data")
		return nil
	end
	
	local salesData = potionData[linkData.potionData]
	
	if (salesData == nil) then
		--uespLog.DebugMsg("FindSalesPrice: No Potion Data")
		return nil
	end
	
	if (uespLog.SalesPricesVersion == nil or uespLog.SalesPricesVersion > 1) then
		return nil
	end
	
	local result = {}
	
	result.price = salesData[1]
	result.priceSold = salesData[2]
	result.priceListed = salesData[3]
	result.countSold = salesData[4]
	result.countListed = salesData[5]
	result.itemsSold = salesData[6]
	result.itemsListed = salesData[7]
	result.count = result.countSold + result.countListed
	result.items = result.itemsSold + result.itemsListed
	result.itemLink = itemLink
	
	return result
end


function uespLog.SumBagValue(bagId)

	if (bagId == BAG_VIRTUAL) then
		return uespLog.SumCraftBagValue()
	end
	
	local numItems = GetBagSize(bagId)
	local totalItems = 0
	local validItems = 0
	local totalValue = 0
	
	for i = 0, numItems do
		local itemLink = GetItemLink(bagId, i)
		
		if (itemLink ~= "") then
			local prices = uespLog.FindSalesPrice(itemLink)
			validItems = validItems + 1
			
			if (prices) then
				local icon, qnt = GetItemInfo(bagId, i)
				totalItems = totalItems + 1
				totalValue = totalValue + prices.price*qnt
			end
		end
	end
	
	return totalItems, totalValue, validItems
end


function uespLog.SumCraftBagValue()
	local totalItems = 0
	local validItems = 0
	local totalValue = 0
	local slotId = GetNextVirtualBagSlotId(nil)
	
	while (slotId) do
		local itemLink = GetItemLink(BAG_VIRTUAL, slotId)
		
		if (itemLink ~= "") then
			local prices = uespLog.FindSalesPrice(itemLink)
			validItems = validItems + 1
			
			if (prices) then
				local icon, qnt = GetItemInfo(BAG_VIRTUAL, slotId)
				totalItems = totalItems + 1
				totalValue = totalValue + prices.price*qnt
			end
		end
		
		slotId = GetNextVirtualBagSlotId(slotId)
	end
	
	return totalItems, totalValue, validItems
	
end


function uespLog.ShowInventoryValue(bag1, bag2)
	local numItems = 0
	local totalValue = 0
	local validItems = 0

	if (bag1) then
		local items, value, valid = uespLog.SumBagValue(bag1)
		numItems = numItems + items
		totalValue = totalValue + value
		validItems = validItems + valid
	end
	
	if (bag2) then
		local items, value, valid = uespLog.SumBagValue(bag2)
		numItems = numItems + items
		totalValue = totalValue + value
		validItems = validItems + valid
	end
	
	totalValue = math.floor(totalValue)
	totalValue = ZO_CommaDelimitNumber(totalValue)
	
	uespLog.Msg("Found "..numItems.." sellable items out of "..validItems.." total items worth "..totalValue.." gold!")
end


function uespLog.SalesCommand (cmd)
	local cmds, firstCmd = uespLog.SplitCommands(cmd)
	
	if (firstCmd == "on") then
		uespLog.SetSalesDataSave(true)
		uespLog.Msg("Guild sales data logging is now ON!")
	elseif (firstCmd == "off") then
		uespLog.SetSalesDataSave(false)
		uespLog.Msg("Guild sales data logging is now OFF!")
	elseif (firstCmd == "price" or firstCmd == "prices") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "on") then
			uespLog.SetSalesShowPrices(true)
			uespLog.Msg("UESP sale price data is now ON!")
		elseif (secondCmd == "off") then
			uespLog.SetSalesShowPrices(false)
			uespLog.Msg("UESP sale price data is now OFF!")
		else
			uespLog.Msg("UESP sale price data is currently "..uespLog.BoolToOnOff(uespLog.IsSalesShowPrices()))
		end		
		
	elseif (firstCmd == "tooltip" or firstCmd == "tooltips") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "on") then
			uespLog.SetSalesShowTooltip(true)
			uespLog.Msg("UESP sale price item tooltips are now ON!")
		elseif (secondCmd == "off") then
			uespLog.SetSalesShowTooltip(false)
			uespLog.Msg("UESP sale price item tooltips are now OFF!")
		else
			uespLog.Msg("UESP sale price item tooltips are currently "..uespLog.BoolToOnOff(uespLog.IsSalesShowTooltip()))
		end		
		
	elseif (firstCmd == "scan") then
	
		if (cmds[2] == nil) then
			uespLog.StartGuildSearchSalesScanAll()
		else
			local page = tonumber(cmds[2]) or 1
			uespLog.StartGuildSearchSalesScanPage(page - 1)
		end
		
	elseif (firstCmd == "saletype") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "both" or secondCmd == "all") then
			uespLog.SetSalesShowSaleType("both")
			uespLog.Msg("UESP sale prices now display both listed and sold data!")
		elseif (secondCmd == "listed" or secondCmd == "list") then
			uespLog.SetSalesShowSaleType("list")
			uespLog.Msg("UESP sale prices now display only list data!")
		elseif (secondCmd == "sold") then
			uespLog.SetSalesShowSaleType("sold")
			uespLog.Msg("UESP sale prices now display only sold data!")
		else
			uespLog.Msg("UESP sale price display is currently using "..uespLog.GetSalesShowSaleType().." data!")
		end		
		
	elseif (firstCmd == "stop") then
		uespLog.StopGuildSearchSalesScan()
	elseif (firstCmd == "scanall") then
		uespLog.StartGuildSearchSalesScanAll()		
	elseif (firstCmd == "resetall") then
		uespLog.ResetNewSalesDataTimestamps()
		uespLog.ResetLastListingSalesDataTimestamps()
		uespLog.Msg("Reset the last scan timestamps for all sales/listing in all guilds!")
	elseif (firstCmd == "resetlist") then
		local guildName = uespLog.implodeOrder(cmds, " ", 2)
		
		if (guildName == "") then
			uespLog.Msg("Missing guild name to reset or 'all' for all guilds!")
			return
		end
		
		uespLog.ResetLastListingSalesDataTimestamps(guildName)
		
	elseif (firstCmd == "postprice") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "mm") then
			uespLog.SetSalesPostPriceType("mm")
			uespLog.Msg("Guild posted prices now use MasterMerchant price data!")
		elseif (secondCmd == "uesp") then
			uespLog.SetSalesPostPriceType("uesp")
			uespLog.Msg("Guild posted prices now use UESP price data!")
		else
			uespLog.Msg("UESP item deals setting is currently "..uespLog.GetSalesPostPriceType():upper()..".")
		end
		
	elseif (firstCmd == "deal" or firstCmd == "dealtype") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "mm") then
			uespLog.SetSalesShowDealType("mm")
			uespLog.Msg("Item deals are now shown using MasterMerchant price data!")
		elseif (secondCmd == "uesp") then
			uespLog.SetSalesShowDealType("uesp")
			uespLog.Msg("Item deals are now shown using UESP price data!")
		elseif (secondCmd == "off" or secondCmd == "none") then
			uespLog.SetSalesShowDealType("none")
			uespLog.Msg("UESP item deals are not shown in guild listings!")
		else
			uespLog.Msg("UESP item deals setting is currently "..uespLog.GetSalesShowDealType():upper()..".")
		end				
		
	elseif (firstCmd == "resetsold") then
		uespLog.ResetNewSalesDataTimestamps()
		uespLog.Msg("Reset the last scan timestamps for all sales in all guilds on account!")
	elseif (firstCmd == "craftbag" or firstCmd == "craft") then
		uespLog.ShowInventoryValue(BAG_VIRTUAL)
	elseif (firstCmd == "bank") then
		uespLog.ShowInventoryValue(BAG_BANK, BAG_SUBSCRIBER_BANK)
	elseif (firstCmd == "inventory") then
		uespLog.ShowInventoryValue(BAG_BACKPACK)
	elseif (firstCmd == "writworthy") then
		local secondCmd = string.lower(cmds[2])
		
		if (secondCmd == "on") then
			uespLog.SetSalesUseWritWorthy(true)
			uespLog.Msg("Writ Worthy will now use UESP prices!")
		elseif (secondCmd == "off") then
			uespLog.SetSalesUseWritWorthy(false)
			uespLog.Msg("Writ Worthy will now use MasterMerchant prices!")
		else
			if (uespLog.GetSalesUseWritWorthy()) then
				uespLog.Msg("Writ Worthy currently uses UESP prices!")
			else
				uespLog.Msg("Writ Worthy currently uses MasterMerchant prices!")
			end
		end		
		
	else
		uespLog.Msg("Logs various guild sales data:")
		uespLog.Msg(".       /uespsales [on||off]     Turns logging on/off")
		uespLog.Msg(".       /uespsales prices [on||off]     Enables/disables all uesp price usage")
		uespLog.Msg(".       /uespsales tooltip [on||off]     Turns price item tooltip display on/off")
		uespLog.Msg(".       /uespsales saletype [both||list||sold]     Sets type of sale price average to display")
		uespLog.Msg(".       /uespsales scan          Scans all guild store listings")
		uespLog.Msg(".       /uespsales scan [page]   Scans the current guild store listing at the given page")
		uespLog.Msg(".       /uespsales stop          Stops the current listing scan")
		uespLog.Msg(".       /uespsales resetall         Reset the sales and listing scan timestamps")
		uespLog.Msg(".       /uespsales resetsold         Reset the sales scan timestamps")
		uespLog.Msg(".       /uespsales resetlist all     Reset the listing timestamps for all guilds")
		uespLog.Msg(".       /uespsales resetlist current Reset the listing timestamps for the current guild trader")
		uespLog.Msg(".       /uespsales resetlist [name]  Reset the listing timestamps for that guild")
		uespLog.Msg(".       /uespsales dealtype [uesp||mm||none]   Sets the type of item deal to display")
		uespLog.Msg(".       /uespsales postprice [uesp||mm]   Sets price to use when posting items for sale")
		uespLog.Msg(".       /uespsales craftbag      Shows total estimated value of your craft bag")
		uespLog.Msg(".       /uespsales bank        Shows total estimated value of your bank")
		uespLog.Msg(".       /uespsales inventory       Shows total estimated value of your inventory")
		uespLog.Msg(".       /uespsales writworthy [on||off]    Use UESP prices for Writ Worthy values")
		uespLog.Msg("Guild sales data logging is currently "..uespLog.BoolToOnOff(uespLog.GetSalesDataConfig().saveSales)..".")
		uespLog.Msg("Sale price data usage is currently "..uespLog.BoolToOnOff(uespLog.IsSalesShowPrices()))
		uespLog.Msg("Sale price item tooltips are currently "..uespLog.BoolToOnOff(uespLog.IsSalesShowTooltip()))
	end		
	
end


SLASH_COMMANDS["/uespsales"] = uespLog.SalesCommand


function uespLog.GotoUespSalesPage (itemLink)

	if (itemLink == nil or itemLink == "") then
		return
	end
	
	local salesPage = "http://esosales.uesp.net/viewSales.php?text=" .. tostring(itemLink)
	local serverName = GetUniqueNameForCharacter()
	local server = "Other"
	
	if (serverName:sub(1, 2) == "NA") then
		server = "NA"
	elseif (serverName:sub(1, 2) == "EU") then
		server = "EU"
	elseif (serverName:sub(1, 2) == "PTS") then
		server = "PTS"
	end	
	
	salesPage = salesPage .. "&server=" .. server
	
	RequestOpenUnsafeURL(salesPage)
end


function uespLog.GotoUespSalesPageRowControl (rowControl)
	local itemLink = uespLog.GetItemLinkRowControl(rowControl)

	if (itemLink == nil) then
		return
	end
	
	uespLog.GotoUespSalesPage(itemLink)
end


-- Copied from /esoui/ingame/tradinghouse/tradinghouse_shared.lua
function uespLog.ZO_TradingHouse_CreateListingItemData(index)
    --local icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseListingItemInfo(index)
	local icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = uespLog.Old_MM_GetTradingHouseSearchResultItemInfo(index)
    local itemLink = GetTradingHouseListingItemLink(index)
    return ZO_TradingHouse_CreateItemData(index, icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemLink, itemUniqueId, purchasePricePerUnit)
end


function uespLog.ZO_TradingHouse_CreateSearchResultItemData(index)
    --local icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo(index)
	local icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = uespLog.Old_MM_GetTradingHouseSearchResultItemInfo(index)
    local itemLink = GetTradingHouseSearchResultItemLink(index)
    return ZO_TradingHouse_CreateItemData(index, icon, name, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemLink, itemUniqueId, purchasePricePerUnit)
end
-- End of Copy


function uespLog.GetTradingHouseSearchResultItemInfo(index)

	if ((uespLog.GetSalesShowDealType() ~= "uesp" or not uespLog.IsSalesShowPrices()) and uespLog.Old_MM_GetTradingHouseSearchResultItemInfo ~= nil) then
		return uespLog.Old_MM_GetTradingHouseSearchResultItemInfo(index)
	end

	local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, unitPrice = uespLog.Old_MM_GetTradingHouseSearchResultItemInfo(index)
	
	if (index == nil) then
		return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, unitPrice
	end
	
	local setPrice = nil
	local salesCount = 0
	local tipLine = nil
	local itemLink = GetTradingHouseSearchResultItemLink(index, LINK_STYLE_DEFAULT)
	
	if (name ~= '' and stackCount > 0) then
		if (itemLink) then
			local uespPrice = uespLog.FindSalesPrice(itemLink)
			
			if (uespPrice) then
				local saleType = uespLog.GetSalesShowSaleType()
				
				if (saleType == "both") then
					setPrice = uespPrice.price
					salesCount = uespPrice.count
				elseif (saleType == "list") then
					setPrice = uespPrice.priceListed
					salesCount = uespPrice.countListed
				elseif (saleType == "sold") then
					setPrice = uespPrice.priceSold
					salesCount = uespPrice.countSold
				else
					setPrice = uespPrice.price
					salesCount = uespPrice.count
				end
			end
		end

		local deal, margin, profit, isValid = uespLog.DealCalc(setPrice, salesCount, purchasePrice, stackCount)
		local dealString = ''
		local marginString = ''
		
		if (isValid) then 
			dealString = string.format('%.0f', deal) 
			uespLog.SalesDealValues[index] = deal
			
			if (isValid and profit) then
				uespLog.SalesDealProfits[index] = profit
			end
			
			if (margin) then 
				marginString = string.format('%.0f', margin) 
			end 
		
			sellerName = sellerName .. '|c000000;' .. dealString .. ';' .. marginString .. '|r'
		end

		return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, unitPrice
	end
	
	return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, unitPrice
end
	
	
function uespLog.GetTradingHouseListingItemInfo(index)

	if ((uespLog.GetSalesShowDealType() ~= "uesp"  or not uespLog.IsSalesShowPrices()) and uespLog.Old_MM_GetTradingHouseListingItemInfo ~= nil) then
		return uespLog.Old_MM_GetTradingHouseListingItemInfo(index)
	end
	
	local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, salePricePerUnit = uespLog.Old_MM_GetTradingHouseListingItemInfo(index)
	
	if (index == nil) then
		return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, unitPrice
	end
	
	local setPrice = nil
	local salesCount = 0
	local tipLine = nil
	local itemLink = GetTradingHouseSearchResultItemLink(index, LINK_STYLE_DEFAULT)
	
	if (name ~= '' and stackCount > 0) then
		if (itemLink) then
			local uespPrice = uespLog.FindSalesPrice(itemLink)
			
			if (uespPrice ~= nil and uespPrice.price > 0) then
				local saleType = uespLog.GetSalesShowSaleType()
				
				if (saleType == "both") then
					setPrice = uespPrice.price
					salesCount = uespPrice.count
				elseif (saleType == "list") then
					setPrice = uespPrice.priceListed
					salesCount = uespPrice.countListed
				elseif (saleType == "sold") then
					setPrice = uespPrice.priceSold
					salesCount = uespPrice.countSold
				else
					setPrice = uespPrice.price
					salesCount = uespPrice.count
				end
			end
		end

		local deal, margin, profit, isValid = uespLog.DealCalc(setPrice, salesCount, purchasePrice, stackCount)
		local dealString = ''
		local marginString = ''
		
		if (isValid) then
			dealString = string.format('%.0f', deal) 
			uespLog.SalesDealValues[index] = deal
				
			if (profit) then
				uespLog.SalesDealProfits[index] = profit
			end

			if (margin) then 
				marginString = string.format('%.0f', margin) 
			end 
			
			sellerName = sellerName .. '|c000000;' .. dealString .. ';' .. marginString .. '|r'
		end

		return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, salePricePerUnit
	end
	
	return icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, uniqueId, salePricePerUnit
end


function uespLog.DealCalc(setPrice, salesCount, purchasePrice, stackCount)

	if (uespLog.Old_MM_DealCalc and (uespLog.GetSalesShowDealType() ~= "uesp" or not uespLog.IsSalesShowPrices())) then
		return uespLog.Old_MM_DealCalc(setPrice, salesCount, purchasePrice, stackCount), true
	end
	
	local deal = 0
	local margin = 0
	local profit = 0
	
	if (not setPrice) then
		return 0, 0, 0, false
	end
	
	local unitPrice = (purchasePrice / stackCount) or 0
	
	profit = ((setPrice - unitPrice) * stackCount) or 0
	margin = (math.floor(((setPrice - unitPrice) / setPrice) * 10000 + 0.5)/100) or 0
		
	if (margin >= 85) then
		deal = 5
	elseif (margin >= 65 and profit >= 1000) then
		deal = 5
	elseif (margin >= 50 and profit >= 3000) then
		deal = 5
	elseif (margin >= 50 and profit >= 500) then
		deal = 4
	elseif (margin >= 35 and profit >= 3000) then
		deal = 4
	elseif (margin >= 35 and profit >= 100) then
		deal = 3
	elseif (margin >= 20) then
		deal = 2
	elseif (margin >= -2.5) then
		deal = 1
	else
		deal = 0
	end

	return deal, margin, profit, true
end


function uespLog.GetDealValue(index)

	if (uespLog.Old_MM_GetDealValue and (uespLog.GetSalesShowDealType() ~= "uesp" or not uespLog.IsSalesShowPrices())) then
		return uespLog.Old_MM_GetDealValue(index)
	end

	return uespLog.SalesDealValues[index]
end


function uespLog.GetProfitValue(index)

	if (uespLog.Old_MM_GetProfitValue and (uespLog.GetSalesShowDealType() ~= "uesp" or not uespLog.IsSalesShowPrices())) then
		return uespLog.Old_MM_GetProfitValue(index)
	end
	
	return uespLog.SalesDealProfits[index]
end


function uespLog.SetupPendingPost(self)
	local useUespPrice = uespLog.GetSalesPostPriceType() == "uesp"

	if (MasterMerchant and uespLog.Old_MM_SetupPendingPost and (not useUespPrice or not uespLog.IsSalesShowPrices())) then
		return uespLog.Old_MM_SetupPendingPost(self)
	end

	uespLog.OriginalSetupPendingPost(self)
	
	--uespLog.DebugMsg("SetupPendingPost: "..tostring(self.m_pendingItemSlot))
	
	if (self.m_pendingItemSlot) then
		local itemLink = GetItemLink(BAG_BACKPACK, self.m_pendingItemSlot)
		local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, self.m_pendingItemSlot)
		local priceToUse = 0
		
		--uespLog.DebugMsg("SPP: "..tostring(itemLink).." x"..tostring(stackCount))
		
		if (MasterMerchant and not useUespPrice) then
    		local settingsToUse = MasterMerchant:ActiveSettings()
			local theIID = string.match(itemLink, '|H.-:item:(.-):')
			local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
		
			if (settingsToUse.pricingData and settingsToUse.pricingData[tonumber(theIID)] and settingsToUse.pricingData[tonumber(theIID)][itemIndex]) then
				priceToUse = math.floor(settingsToUse.pricingData[tonumber(theIID)][itemIndex] * stackCount)
			end
		end
		
		if (priceToUse == 0) then
			local saleData = uespLog.FindSalesPrice(itemLink)
			
			if (saleData) then
				local saleType = uespLog.GetSalesShowSaleType()
				
				if (saleType == "both" and saleData.count > 0) then
					priceToUse = math.floor(saleData.price * stackCount)
				elseif (saleType == "list" and saleData.countListed > 0) then
					priceToUse = math.floor(saleData.priceListed * stackCount)
				elseif (saleType == "sold" and saleData.countSold > 0) then
					priceToUse = math.floor(saleData.priceSold * stackCount)
				elseif (saleData.count > 0) then
					priceToUse = math.floor(saleData.price * stackCount)
				end
			end
			
			--uespLog.DebugMsg("SPP: Price="..tostring(priceToUse))
		end
		
		if (priceToUse > 0) then
			self:SetPendingPostPrice(priceToUse)
			zo_callLater(function() self:SetPendingPostPrice(priceToUse) end, 50)
			--uespLog.DebugMsg("SPP: Setting Price "..tostring(priceToUse)..", "..tostring(self))
		end
	end
end


function uespLog.SetupTraderControls()

	if (not uespLog.IsSalesShowPrices() or UespSalesScanButton ~= nil) then
		return
	end
	
	local isAGSInstalled = AwesomeGuildStore ~= nil

	local salesScanButton = CreateControlFromVirtual('UespSalesScanButton', ZO_TradingHouseBrowseItemsLeftPane, 'ZO_DefaultButton')
	local salesResetButton = CreateControlFromVirtual('UespSalesResetButton', ZO_TradingHouseBrowseItemsLeftPane, 'ZO_DefaultButton')
	
	if (salesScanButton == nil or salesResetButton == nil) then
		uespLog.DebugMsg("UESP: Failed to setup sales buttons!")
		return
	end
	
	if (isAGSInstalled) then
		salesScanButton:SetAnchor(CENTER, ZO_TradingHouseBrowseItemsLeftPane, BOTTOM, -75, 25)
		salesScanButton:SetWidth(120)
		salesScanButton:SetHeight(20)
	else
		salesScanButton:SetAnchor(CENTER, ZO_TradingHouseBrowseItemsLeftPane, BOTTOM, -75, 25)
		salesScanButton:SetWidth(120)
		salesScanButton:SetHeight(20)
	end
	
	salesScanButton:SetText("UESP Scan Sales...")
	salesScanButton:SetHandler('OnClicked', uespLog.OnUespScanSalesButton)
	salesScanButton:SetHidden(true)
	salesScanButton:SetFont("EsoUi/Common/Fonts/Univers57.otf|15|")
	
	if (isAGSInstalled) then
		salesResetButton:SetAnchor(CENTER, ZO_TradingHouseBrowseItemsLeftPane, BOTTOM, 50, 25)
		salesResetButton:SetWidth(120)
		salesResetButton:SetHeight(20)
	else
		salesResetButton:SetAnchor(CENTER, ZO_TradingHouseBrowseItemsLeftPane, BOTTOM, 75, 25)
		salesResetButton:SetWidth(120)
		salesResetButton:SetHeight(20)
	end
	
	salesResetButton:SetText("UESP Reset Scan")
	salesResetButton:SetHandler('OnClicked', function() uespLog.ResetLastListingSalesDataTimestamps('current') end)
	salesResetButton:SetHidden(true)
	salesResetButton:SetFont("EsoUi/Common/Fonts/Univers57.otf|15|")
	
	uespLog.UpdateUespScanSalesButton()
end


function uespLog.OnUespScanSalesButton()

	if (not uespLog.SalesGuildSearchScanStarted) then
		uespLog.StartGuildSearchSalesScanAll()
	else
		uespLog.StopGuildSearchSalesScan()
	end
	
	uespLog.UpdateUespScanSalesButton()
end


function uespLog.UpdateUespScanSalesButton()

	if (UespSalesScanButton == nil) then
		uespLog.SetupTraderControls()
		
		if (UespSalesScanButton == nil) then
			return
		end
	end
	
	if (uespLog.SalesGuildSearchScanStarted) then
		UespSalesScanButton:SetText("UESP Stop Scan")
	else
		UespSalesScanButton:SetText("UESP Scan Sales...")
	end
	
	if (not uespLog.IsSalesShowPrices()) then
		UespSalesScanButton:SetHidden(true)
		UespSalesResetButton:SetHidden(true)
	else
		UespSalesScanButton:SetHidden(false)
		UespSalesResetButton:SetHidden(false)
	end

end


uespLog.lastTradingHousePurchaseIndex = -1
uespLog.lastTradingHousePurchaseItemLink = ""
uespLog.lastTradingHousePurchasePrice = -1


function uespLog.OnTradingHouseConfirmItemPurchase(eventCode, purchaseIndex)

	uespLog.DebugExtraMsg("OnTradingHouseConfirmItemPurchase "..tostring(purchaseIndex))
	
	local icon, name, quality, stackCount, sellerName, timeRemaining, purchasePrice = GetTradingHouseSearchResultItemInfo(purchaseIndex)
	
	uespLog.lastTradingHousePurchaseIndex = purchaseIndex
	uespLog.lastTradingHousePurchaseItemLink = GetTradingHouseSearchResultItemLink(purchaseIndex)
	uespLog.lastTradingHousePurchasePrice = purchasePrice
	
	if (purchaseIndex == nil) then
		uespLog.lastTradingHousePurchaseIndex = -1
	end
	
end


function uespLog.OnTradingHouseOpen()
	uespLog.SetupTradingHouseRowCallbacks() 
end


function uespLog.OnTradingHouseClose()
	uespLog.StopGuildSearchSalesScan(true)
end


function uespLog.SetupTradingHouseRowCallbacks() 
	
	if (MasterMerchant ~= nil) then return end
	if (uespLog.originalSetupCallback) then return end
	if (TRADING_HOUSE.searchResultsList == nil) then return end
	if (TRADING_HOUSE.searchResultsList.dataTypes == nil) then return end

	local dataType = TRADING_HOUSE.searchResultsList.dataTypes[1]
	uespLog.originalSetupCallback = dataType.setupCallback
	
	if uespLog.originalSetupCallback then
		dataType.setupCallback = function(...)
			local row, data = ...
			
			uespLog.AddCraftInfoToTraderSlot(row, data) 
				
			if (MasterMerchant == nil) then 
				uespLog.AddBuyingAdvice(row, data) 
			end
			
			uespLog.originalSetupCallback(...)
		end
	else
		uespLog.DebugMsg("Error setting up the Buying Advice callback!")
	end
	
end


function uespLog.AddBuyingAdvice(rowControl, result)
    local buyingAdvice = rowControl:GetNamedChild('BuyingAdvice')
		
	if (not buyingAdvice) then
		local controlName = rowControl:GetName() .. 'BuyingAdvice'
		local anchorControl = rowControl:GetNamedChild('TimeRemaining')
		
		buyingAdvice = rowControl:CreateControl(controlName, CT_LABEL)		
		--buyingAdvice:SetAnchor(RIGHT, anchorControl, LEFT, -20, 6)
		buyingAdvice:SetAnchor(RIGHT, anchorControl, LEFT, 65, 5)
		buyingAdvice:SetFont('/esoui/common/fonts/univers67.otf|14|soft-shadow-thin')
	end
    
    local sellerName, dealString, margin = zo_strsplit(';', result.sellerName)
    --local margin = result.marginString
    
	
    if (dealString ) then 
		local dealValue = tonumber(dealString)
			buyingAdvice:SetText(margin .. '%')  
			local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
			if dealValue == 0 then r = 0.98; g = 0.01; b = 0.01; end
			buyingAdvice:SetColor(r, g, b, 1)
			buyingAdvice:SetHidden(false)
		
		local sellerControl = rowControl:GetNamedChild('SellerName')
		
		if (sellerControl) then
			sellerControl:SetText(sellerName)
		end
		
	else
		buyingAdvice:SetHidden(true)
    end
	
    buyingAdvice = nil
end


function uespLog.ShowGuildTime()
	local salesConfig = uespLog.GetSalesDataConfig()
	local _, guildName = GetCurrentTradingHouseGuildDetails()
	local lastTime = salesConfig.guildListTimes[guildName]
	local nowTimestamp = GetTimeStamp()
	
	if (lastTime == nil) then
		uespLog.DebugMsg("Nil guild time, "..nowTimestamp.." now")
	else
		local diff = nowTimestamp - lastTime
		uespLog.DebugMsg("" ..lastTime.." guild time, "..nowTimestamp.." now ("..diff.." diff)")		
	end
end


function uespLog.SetGuildTime(timestamp)
	local salesConfig = uespLog.GetSalesDataConfig()
	local _, guildName = GetCurrentTradingHouseGuildDetails()
	
	salesConfig.guildListTimes[guildName] = timestamp
	uespLog.ShowGuildTime()
end


function uespLog.WritWorthyMMPrice(link)
	local useUespPrice = uespLog.IsSalesShowPrices()
	local overrideWritWorthy = uespLog.GetSalesUseWritWorthy()

	if (useUespPrice and overrideWritWorthy and link) then
		local saleData = uespLog.FindSalesPrice(link)
			
		if (saleData) then
			local saleType = uespLog.GetSalesShowSaleType()
			
			if (saleType == "both" and saleData.count > 0) then
				priceToUse = math.floor(saleData.price)
			elseif (saleType == "list" and saleData.countListed > 0) then
				priceToUse = math.floor(saleData.priceListed)
			elseif (saleType == "sold" and saleData.countSold > 0) then
				priceToUse = math.floor(saleData.priceSold)
			else
				priceToUse = math.floor(saleData.price)
			end
			
			return priceToUse
		end
	end
    
	return uespLog.Orig_WritWorthyMMPrice(link)
end


--
-- Based on Writ Worthy and CraftStore's tooltip code.
--
function uespLog.InstallItemTooltip()
    local tt = ItemTooltip.SetBagItem
	
    ItemTooltip.SetBagItem = function(control, bagId, slotIndex, ...)
        tt(control, bagId, slotIndex, ...)
        uespLog.TooltipInsertText(control, GetItemLink(bagId, slotIndex))
    end
	
    local tt = ItemTooltip.SetLootItem
	
    ItemTooltip.SetLootItem = function(control, lootId,...)
        tt(control, lootId, ...)
        uespLog.TooltipInsertText(control, GetLootItemLink(lootId))
    end
	
    local tt = PopupTooltip.SetLink
	
    PopupTooltip.SetLink = function(control, link, ...)
        tt(control, link, ...)
        uespLog.TooltipInsertText(control, link)
    end
	
    local tt = ItemTooltip.SetTradingHouseItem
	
    ItemTooltip.SetTradingHouseItem = function(control, tradingHouseIndex,...)
        tt(control, tradingHouseIndex, ...)
		uespLog.TooltipInsertText(control, GetTradingHouseSearchResultItemLink(tradingHouseIndex))
    end

end


function uespLog.TooltipInsertText(control, itemLink)

	if (not uespLog.IsSalesShowPrices() or not uespLog.IsSalesShowTooltip()) then
		return
	end
	
	local msg = uespLog.GetSalesPriceTip(itemLink, false)		
	   
	if (msg ~= "") then
		control:AddLine("\n" .. msg)
	end
end