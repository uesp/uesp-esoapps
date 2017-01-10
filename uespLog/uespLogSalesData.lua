-- uespLogSalesData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the saving of guild sales data.
--
--	EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE
--	EVENT_TRADING_HOUSE_RESPONSE_RECEIVED
--	EVENT_PLAYER_ACTIVATED
--  EVENT_GUILD_SELF_JOINED_GUILD
--	EVENT_GUILD_SELF_LEFT_GUILD
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

	if (not uespLog.IsSalesDataSave()) then
		uespLog.IsSavingGuildSales = false
		return
	end	
	
	uespLog.DebugMsg("UESP: Looking for new guild sales data...")
		
	for i = 1, uespLog.MAX_GUILD_INDEX do
		uespLog.SaveGuildSummary(i)
	end
	
	uespLog.StartGuildSalesScan(1)
end


function uespLog.StartGuildSalesScan(guildIndex)

	if (guildIndex > uespLog.MAX_GUILD_INDEX) then
	
		if (uespLog.NewGuildSales > 0) then
			uespLog.DebugMsg("UESP: Found and saved "..tostring(uespLog.NewGuildSales).." new guild sales!")
		else
			uespLog.DebugExtraMsg("UESP: Found no new guild sales since last save!")
		end
		
		uespLog.IsSavingGuildSales = false
		return false
	end
		
	uespLog.DebugExtraMsg("UESP: Starting sales scan for guild #"..tostring(guildIndex))
	
	local guildId = GetGuildId(guildIndex)
	local requested = RequestGuildHistoryCategoryNewest(guildId, GUILD_HISTORY_STORE)
	uespLog.GuildHistoryLastReceivedTimestamp = GetTimeStamp()
	
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
	
		if (uespLog.SalesScanSingleGuild) then
			uespLog.SalesScanSingleGuild = false
		else
			uespLog.StartGuildSalesScan(guildIndex + 1)
		end
		
		return true
	end
		
	uespLog.SalesStartEventIndex = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
	uespLog.SalesCurrentGuildIndex = guildIndex
	
	uespLog.DebugExtraMsg("UESP: Loading more sales for guild #"..tostring(guildIndex)..", starting at event #"..tostring(uespLog.SalesStartEventIndex))
	
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
	elseif (uespLog.SalesScanSingleGuild) then
		uespLog.SalesScanSingleGuild = false
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


function uespLog.SaveGuildPurchase(guildId, eventIndex)
	local eventType, seconds, seller, buyer, qnt, itemLink, gold, taxes = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, eventIndex)
	local eventId = GetGuildEventId(guildId, GUILD_HISTORY_STORE, eventIndex)
	local logData = {}
	local currentTimestamp = GetTimeStamp()
	
	logData.event = "GuildSale"
	logData.type = eventType
	logData.saleTimestamp = tostring(currentTimestamp - seconds)
	logData.eventId = tostring(eventId)
	logData.seller = seller
	logData.buyer = buyer
	logData.qnt = qnt
	logData.gold = gold
	logData.taxes = taxes
	logData.server = GetWorldName()
	logData.guild = GetGuildName(guildId)
	logData.itemLink = itemLink
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.ResetNewSalesDataTimestamps()
	local salesConfig = uespLog.GetSalesDataConfig()
	
	salesConfig.lastTimestamp = 0
	
	for i = 1, 5 do
		salesConfig[i].lastTimestamp = 0
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
		["guildId"] = 1,
		["lastTimestamp"] = 0,
	}

end


function uespLog.OnTradingHouseSearchResultsReceived (eventCode, guildId, numItemsOnPage, currentPage, hasMorePages)

	if (uespLog.IsSalesDataSave()) then
		uespLog.SaveTradingHouseSalesData(guildId, numItemsOnPage, currentPage)	
	end

end


function uespLog.SaveTradingHouseSalesData(guildId, numItemsOnPage, currentPage)
	local currentTimestamp = GetTimeStamp()
	local logData = {}
	
	uespLog.DebugMsg("UESP: Saving guild sales search results...")
	
	logData.event = "GuildSaleSearchInfo"
	logData.guildId, logData.guild = GetCurrentTradingHouseGuildDetails()
	logData.server = GetWorldName()	
	logData.zone = uespLog.lastTargetData.zone
	logData.lastTarget = uespLog.lastTargetData.name
	logData.kiosk = GetGuildOwnedKioskInfo(guildId)
	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())

	for i = 1, numItemsOnPage do
		uespLog.SaveTradingHouseSalesItem(guildId, i, currentTimestamp)
	end
	
end


function uespLog.SaveTradingHouseSalesItem(guildId, itemIndex, currentTimestamp, extraData)
	local logData = {}
	
	logData.event = "GuildSaleSearchEntry"
	logData.guildId, logData.guild = GetCurrentTradingHouseGuildDetails()
	logData.server = GetWorldName()
	logData.icon, logData.item, logData.quality, logData.qnt, logData.seller, logData.timeRemaining, logData.price, logData.currency = GetTradingHouseSearchResultItemInfo(itemIndex)
	logData.itemLink = GetTradingHouseSearchResultItemLink(itemIndex)
	logData.listTimestamp = tostring(currentTimestamp + logData.timeRemaining - uespLog.SALES_MAX_LISTING_TIME)
	
	logData.timeRemaining = nil
	logData.stack = nil
	logData.currency = nil
	
	if (logData.itemLink == "") then
		return
	end
		
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData(), extraData)
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
		uespLog.OnTradingHouseListingUpdate()
	elseif (responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING) then
		uespLog.OnTradingHouseListingCancel()
	elseif (responseType == TRADING_HOUSE_RESULT_POST_PENDING) then
		uespLog.OnTradingHouseListingNew()
	end
	
end


function uespLog.OnTradingHouseListingNew()

	if (uespLog.IsSalesDataSave()) then
		uespLog.SaveTradingHouseListingData()
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
	
	uespLog.DebugExtraMsg("UESP: Saving "..tostring(#cancelledListings).." cancelled listing guild sales items...")
	
	for i = 1, #cancelledListings do
		uespLog.SaveTradingHouseListingDataItem("GuildSaleListingEntry::Cancel", uespLog.SalesCurrentListingData[cancelledListings[i]])
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
	local currentTimestamp = GetTimeStamp()
	
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
	local currentTimestamp = GetTimeStamp()
	
	uespLog.SalesCurrentListingData = {}

	if (guildName == "" or numListings <= 0) then
		return
	end
	
	uespLog.DebugMsg("UESP: Saving guild sale listings...")
	
	logData.event = "GuildSaleListingInfo"
	logData.guildId = guildId
	logData.guild = guildName
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
	logData.listTimestamp = tostring(currentTimestamp + logData.timeRemaining - uespLog.SALES_MAX_LISTING_TIME)
	
	logData.timeRemaining = nil
	logData.stack = nil
	
	if (logData.itemLink == "") then
		return
	end
			
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.OnGuildHistoryResponseReceived(event)
	uespLog.DebugExtraMsg("UESP: OnGuildHistoryResponseReceived")
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