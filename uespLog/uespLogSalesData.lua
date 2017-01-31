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
uespLog.NewGuildSales = 0
uespLog.SalesCurrentGuildIndex = 1
uespLog.SalesStartEventIndex = 1
uespLog.SalesScanCurrentLastTimestamp = -1
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
end


function uespLog.IsSalesDataSave()
	local salesConfig = uespLog.GetSalesDataConfig()
	return salesConfig.saveSales
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


function uespLog.StartGuildSalesScan(guildIndex)

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
	local requested = RequestGuildHistoryCategoryNewest(guildId, GUILD_HISTORY_STORE)
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
	
	uespLog.SalesStartEventIndex = 1
	uespLog.SalesCurrentGuildIndex = guildIndex
	uespLog.SalesScanCurrentLastTimestamp = -1
	uespLog.SalesBadScanCount = 0
	
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.StartGuildSalesScanMore(guildIndex)
	local guildId = GetGuildId(guildIndex)
	local hasMore = DoesGuildHistoryCategoryHaveMoreEvents(guildId, GUILD_HISTORY_STORE)
		
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
	local requested = RequestGuildHistoryCategoryOlder(guildId, GUILD_HISTORY_STORE)
			
	zo_callLater(function() uespLog.ScanGuildSales(guildIndex) end, uespLog.SALES_SCAN_DELAY)
	
	return true
end


function uespLog.ScanGuildSales(guildIndex)
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
	local eventType, seconds, seller, buyer, qnt, itemLink, gold, taxes = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, eventIndex)
	local eventId = GetGuildEventId(guildId, GUILD_HISTORY_STORE, eventIndex)
	local logData = {}
	local currentTimestamp = GetTimeStamp()
	
	logData.event = "GuildSale"
	logData.type = eventType
	logData.saleTimestamp = tostring(currentTimestamp - seconds)
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
	logData.quality = GetItemLinkQuality(logData.itemLink)
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


function uespLog.ResetLastListingSalesDataTimestamps()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	salesConfig.guildListTimes = {}
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

	if (uespLog.IsSalesDataSave()) then
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
	logData.icon, logData.item, logData.quality, logData.qnt, logData.seller, logData.timeRemaining, logData.price, logData.currency = GetTradingHouseSearchResultItemInfo(itemIndex)
	logData.itemLink = GetTradingHouseSearchResultItemLink(itemIndex)
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkQuality(logData.itemLink)
	logData.level = uespLog.GetItemLinkRequiredEffectiveLevel(logData.itemLink)
	local listTimestamp = currentTimestamp + logData.timeRemaining - uespLog.SALES_MAX_LISTING_TIME
	logData.listTimestamp = tostring(listTimestamp)
	
	if (checkScan and uespLog.SalesGuildSearchScanStarted and listTimestamp < uespLog.SalesGuildSearchScanLastTimestamp) then
		uespLog.SalesGuildSearchScanFinish = true
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


function uespLog.OnTradingHouseResponseReceived(event, responseType, result)
	--TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING
	--TRADING_HOUSE_RESULT_PURCHASE_PENDING
	--TRADING_HOUSE_RESULT_POST_PENDING
	--TRADING_HOUSE_RESULT_LISTINGS_PENDING
	
	uespLog.DebugExtraMsg("UESP: OnTradingHouseResponseReceived "..tostring(responseType).. " - "..tostring(result))
	
	if (result ~= TRADING_HOUSE_RESULT_SUCCESS) then
		return
	end
		
	if (responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
		uespLog.GuildSalesLastListingTimestamp = GetTimeStamp()
		uespLog.OnTradingHouseListingUpdate()
	elseif (responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING) then
		uespLog.OnTradingHouseListingCancel()
	elseif (responseType == TRADING_HOUSE_RESULT_POST_PENDING) then
		uespLog.OnTradingHouseListingNew()
	end
	
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
	logData.quality = GetItemLinkQuality(logData.itemLink)
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
		local icon, name, quality, qnt, seller, timeRemaining, price = GetTradingHouseListingItemInfo(i)
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
	logData.icon, logData.item, logData.quality, logData.qnt, logData.seller, logData.timeRemaining, logData.price = GetTradingHouseListingItemInfo(itemIndex)
	logData.itemLink = GetTradingHouseListingItemLink(itemIndex)
	logData.trait = GetItemLinkTraitInfo(logData.itemLink)
	logData.quality = GetItemLinkQuality(logData.itemLink)
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
		uespLog.Msg("You must be in the bank guild store in order to start a listing scan!")
		return
	end
	
	if (numTradeGuilds == 1) then
		uespLog.StartGuildSearchSalesScan()
		return
	end
		
	uespLog.SalesGuildSearchScanGuildCount = numTradeGuilds
	uespLog.SalesGuildSearchScanAllGuilds = true
	uespLog.SalesGuildSearchScanGuildId = 0
	
	uespLog.StartGuildSearchSalesScanNextGuild()
end


function uespLog.StartGuildSearchSalesScanNextGuild()
	local guildId, guildName = GetCurrentTradingHouseGuildDetails()
		
	uespLog.SalesGuildSearchScanGuildId = uespLog.SalesGuildSearchScanGuildId + 1
	uespLog.SalesGuildSearchScanStarted = false
		
	if (uespLog.SalesGuildSearchScanGuildId > uespLog.SalesGuildSearchScanGuildCount) then
		uespLog.SalesGuildSearchScanAllGuilds = false
		uespLog.Msg("Finished scanning listings from all guilds!")
		return
	end
	
	if (guildId ~= uespLog.SalesGuildSearchScanGuildId) then
	
		if (not SelectTradingHouseGuildId(uespLog.SalesGuildSearchScanGuildId)) then
			uespLog.SalesGuildSearchScanAllGuilds = false
			uespLog.Msg("Error: Failed to select guild ID "..tostring(uespLog.SalesGuildSearchScanGuildId).." for listing scan!")
			return
		end
	end
	
	uespLog.StartGuildSearchSalesScan()
end


function uespLog.StartGuildSearchSalesScan()

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
	uespLog.SalesGuildSearchScanNumItems = 0
	uespLog.SalesGuildSearchScanStartTime = GetTimeStamp()
	uespLog.SalesGuildSearchScanLastTimestamp = 0
	uespLog.SalesGuildSearchScanFinishIndex = 0
	uespLog.SalesGuildSearchScanNumItems = 0
	uespLog.SalesGuildSearchScanPage = 0
	uespLog.SalesGuildSearchScanFinish = false
	uespLog.Msg("Starting guild listing scan for "..tostring(guildName).."...do not leave trader until it is finished.")
	
	local salesConfig = uespLog.GetSalesDataConfig()
		
	if (salesConfig.guildListTimes[guildName] == nil) then
		uespLog.SalesGuildSearchScanLastTimestamp = 0
	else
		uespLog.SalesGuildSearchScanLastTimestamp = salesConfig.guildListTimes[guildName]
	end
		
	uespLog.SalesGuildSearchScanListTimestamp = GetTimeStamp()
		
	ClearAllTradingHouseSearchTerms()
	ExecuteTradingHouseSearch(0, TRADING_HOUSE_SORT_EXPIRY_TIME, false)
end


function uespLog.StopGuildSearchSalesScan()

	if (not uespLog.SalesGuildSearchScanStarted) then
		uespLog.Msg("Guild listing scan has been stopped!")
	end
	
	uespLog.SalesGuildSearchScanStarted = false
end


function uespLog.OnGuildSearchScanItemsReceived(guildId, numItemsOnPage, currentPage, hasMorePages)
	local _, guildName = GetCurrentTradingHouseGuildDetails()
	
	uespLog.SalesGuildSearchScanPage = uespLog.SalesGuildSearchScanPage + 1
	uespLog.SalesGuildSearchScanNumItems = uespLog.SalesGuildSearchScanNumItems + numItemsOnPage - uespLog.SalesGuildSearchScanFinishIndex
	uespLog.SalesGuildSearchScanFinishIndex = 0

	if (not hasMorePages or uespLog.SalesGuildSearchScanFinish) then
		local deltaTime = GetTimeStamp() - uespLog.SalesGuildSearchScanStartTime
		uespLog.Msg("Finished guild listing scan for "..tostring(guildName).."! "..uespLog.SalesGuildSearchScanNumItems.." items in "..uespLog.SalesGuildSearchScanPage.." pages scanned in "..tostring(deltaTime).." secs.")	
		uespLog.SalesGuildSearchScanStarted = false
		
		local salesConfig = uespLog.GetSalesDataConfig()
		salesConfig.guildListTimes[guildName] = uespLog.SalesGuildSearchScanListTimestamp
		
		if (uespLog.SalesGuildSearchScanAllGuilds) then
			zo_callLater(uespLog.StartGuildSearchSalesScanNextGuild, GetTradingHouseCooldownRemaining() + 250)	
		end
		
		return
	end
		
	zo_callLater(uespLog.DoNextGuildListingScan, GetTradingHouseCooldownRemaining() + 250)	
	
	uespLog.DebugMsg("Guild Listing Scan for "..tostring(guildName)..": Logged "..numItemsOnPage.." items on page "..uespLog.SalesGuildSearchScanPage..".")	
end


function uespLog.DoNextGuildListingScan()

	if (GetNumTradingHouseGuilds() == 0) then
		uespLog.Msg("Scan Aborted! You must be on a guild trader in order to perform a listing scan.")
		uespLog.SalesGuildSearchScanStarted = false
		return
	end
	
	ExecuteTradingHouseSearch(uespLog.SalesGuildSearchScanPage, TRADING_HOUSE_SORT_EXPIRY_TIME, false)
end


function uespLog.SalesCommand (cmd)
	local cmds, firstCmd = uespLog.SplitCommands(cmd)
	
	if (firstCmd == "on") then
		uespLog.SetSalesDataSave(true)
		uespLog.Msg("Guild sales data logging is now ON!")
	elseif (firstCmd == "off") then
		uespLog.SetSalesDataSave(false)
		uespLog.Msg("Guild sales data logging is now OFF!")
	elseif (firstCmd == "scan") then
		uespLog.StartGuildSearchSalesScanAll()
	elseif (firstCmd == "stop") then
		uespLog.StopGuildSearchSalesScan()
	elseif (firstCmd == "scanall") then
		uespLog.StartGuildSearchSalesScanAll()		
	elseif (firstCmd == "reset") then
		uespLog.ResetNewSalesDataTimestamps()
		uespLog.ResetLastListingSalesDataTimestamps()
		uespLog.Msg("Reset the last scan timestamps for all sales/listing in all guilds on account!")
	elseif (firstCmd == "resetlist") then
		uespLog.ResetLastListingSalesDataTimestamps()
		uespLog.Msg("Reset the last scan timestamps for all listings in all guilds on account!")
	elseif (firstCmd == "resetsale") then
		uespLog.ResetLastListingSalesDataTimestamps()
		uespLog.Msg("Reset the last scan timestamps for all sales in all guilds on account!")
	else
		uespLog.Msg("Logs various guild sales data:")
		uespLog.Msg(".       /uespsalesdata [on||off]     Turns logging on/off")
		uespLog.Msg(".       /uespsalesdata scan          Scans all guild store listings")
		uespLog.Msg(".       /uespsalesdata stop          Stops the current listing scan")
		uespLog.Msg(".       /uespsalesdata reset         Reset the sales and listing scan timestamps")
		uespLog.Msg(".       /uespsalesdata resetsale         Reset the sales scan timestamps")
		uespLog.Msg(".       /uespsalesdata resetlist         Reset the listing scan timestamps")
		uespLog.Msg("Guild sales data logging is currently "..uespLog.BoolToOnOff(uespLog.GetSalesDataConfig().saveSales)..".")
	end		
	
end


SLASH_COMMANDS["/uespsales"] = uespLog.SalesCommand