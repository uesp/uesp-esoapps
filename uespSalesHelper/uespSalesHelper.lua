
uespSalesHelper = uespSalesHelper or {}


uespSalesHelper.isCalibration = false
uespSalesHelper.currentState = "IDLE"
uespSalesHelper.extraData = ""
uespSalesHelper.autoScanStores = false
uespSalesHelper.extraData = ""
uespSalesHelper.lastWayshrineIndex = ""
uespSalesHelper.measuredDistFactor = 0
uespSalesHelper.isInTradingHouse = false


uespSalesHelper.currentTargetData = {
	name = "",
	x = "",
	y = "",
	zone = "",
	action = "",
	interactionType = "",
}


uespSalesHelper.lastTargetData = {
	type = "",
	name = "",
	x = "",
    y = "",
    zone = "",
	gameTime = "",
	timeStamp = "",
	level = "",
	effectiveLevel = "",
	race = "",
	class = "",
	maxHp = "",
	maxMg = "",
	maxSt = "",
	action = "",
	interactionType = "",
}


uespSalesHelper.DEFAULT_SAVED_VARS = {
	autoScanStores = false,
}

uespSalesHelper.savedVars = {}



function uespSalesHelper.OnAddonLoaded(self, addOnName)
	
	uespSalesHelper.savedVars = ZO_SavedVars:NewAccountWide("uespSalesHelperSavedVars", 3, nil, uespSalesHelper.DEFAULT_SAVED_VARS)
	
	uespSalesHelper.autoScanStores = uespSalesHelper.savedVars.autoScanStores or false
	
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_START_FAST_TRAVEL_INTERACTION, uespSalesHelper.OnStartFastTravelInteraction)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_END_FAST_TRAVEL_INTERACTION, uespSalesHelper.OnEndFastTravelInteraction)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_PLAYER_ACTIVATED, uespSalesHelper.OnPlayerActivated)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_OPEN_TRADING_HOUSE, uespSalesHelper.OnOpenTradingHouse)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_CLOSE_TRADING_HOUSE, uespSalesHelper.OnCloseTradingHouse)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, uespSalesHelper.OnTradingHouseResponseReceived)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_CHATTER_END, uespSalesHelper.OnChatterEnd)
	EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_CHATTER_BEGIN, uespSalesHelper.OnChatterBegin)
	
	INTERACT_WINDOW:RegisterCallback("Shown", uespSalesHelper.OnInteractWindowShown)
	
	ZO_CreateStringId("SI_BINDING_NAME_UESPSALESHELPER_SAVEPOINT", "Save Point")
	ZO_CreateStringId("SI_BINDING_NAME_UESPSALESHELPER_SAVEHEADING", "Save Heading")
	ZO_CreateStringId("SI_BINDING_NAME_UESPSALESHELPER_SAVEWAYSHRINE", "Save Wayshrine")
	ZO_CreateStringId("SI_BINDING_NAME_UESPSALESHELPER_SAVEDISTFACTOR", "Save DistFactor")
	
	if (SLASH_COMMANDS["/udf"] == nil) then
		SLASH_COMMANDS["/udf"] = uespSalesHelper.MeasureDistFactor
	end
	
	if (SLASH_COMMANDS["/ush"] == nil) then
		SLASH_COMMANDS["/ush"] = uespSalesHelper.SalesHelperCommand
	end
end


EVENT_MANAGER:RegisterForEvent("uespSalesHelper", EVENT_ADD_ON_LOADED, uespSalesHelper.OnAddonLoaded)


function uespSalesHelper.OnOpenTradingHouse()
	uespLog.DebugMsg("OnOpenTradingHouse")
	uespSalesHelper.isInTradingHouse = true
	
	zo_callLater(uespSalesHelper.CheckScanSalesLockup, 5000)
end


function uespSalesHelper.OnCloseTradingHouse()
	--uespLog.DebugMsg("OnCloseTradingHouse")
	uespSalesHelper.currentState = "IDLE"
	uespSalesHelper.isInTradingHouse = false
end


function uespSalesHelper.OnTradingHouseResponseReceived(event, responseType, result)
end


function uespSalesHelper.OnChatterBegin()
	uespSalesHelper.currentState = "DIALOG"
end


function uespSalesHelper.OnChatterEnd()

	if (uespSalesHelper.currentState == "SCANNING" or uespSalesHelper.currentState == "DIALOG") then
		uespSalesHelper.currentState = "IDLE"
		uespSalesHelper.isInTradingHouse = false
	end
	
end


function uespSalesHelper.CheckScanSalesLockup()

	if (not uespSalesHelper.isInTradingHouse or not uespSalesHelper.autoScanStores) then
		return
	end
	
	if (uespSalesHelper.currentState ~= "SCANNING" or not uespLog.SalesGuildSearchScanStarted) then
		return
	end
	
	local timeStamp = GetTimeStamp()
	local timeDiff = timeStamp - uespLog.SalesLastTraderRequestTime
	
	if (timeDiff > 30) then
		uespLog.Msg("Over 30 seconds since last trader request was sent...trying to restart!")
		uespLog.SalesLastTraderRequestTime = GetTimeStamp()
		uespLog.DoNextGuildListingScan()
	end	
	
	zo_callLater(uespSalesHelper.CheckScanSalesLockup, 1000)
end


function uespSalesHelper.OnInteractWindowShown()
	local _, optionType = GetChatterOption(1)
	
	--uespLog.DebugMsg("OnInteractWindowShown")
	
	if (not uespSalesHelper.autoScanStores) then
		return
	end	
	
	if (optionType == CHATTER_START_TRADINGHOUSE) then
		--uespLog.DebugMsg("CHATTER_START_TRADINGHOUSE")
		local text, numOptions = GetChatterData()
		
		if (numOptions < 1) then
			return
		end
		
		SelectChatterOption(1)
		
		zo_callLater(function() 
				SelectChatterOption(1) 
				uespSalesHelper.currentState = "SCANNING" 
			end, 500)		
		
		if (uespSalesHelper.autoScanStores) then
			uespSalesHelper.currentState = "SCANNING"
			
			zo_callLater(uespLog.StartGuildSearchSalesScanAll, 1000)
		end
		
	elseif (optionType == CHATTER_START_BANK) then
		local text, numOptions = GetChatterData()
		
		if (numOptions < 3) then
			return
		end
	
		SelectChatterOption(3)
		
		zo_callLater(function() 
				SelectChatterOption(3) 
				uespSalesHelper.currentState = "SCANNING"
			end, 500)
		
		if (uespSalesHelper.autoScanStores) then
			uespSalesHelper.currentState = "SCANNING"
			
			zo_callLater(uespLog.StartGuildSearchSalesScanAll, 1000)
		end
	
	end
	
end


function uespSalesHelper.OnPlayerActivated(event, initial)
	uespSalesHelper.currentState = "IDLE"
	uespSalesHelper.lastWayshrineIndex = ""
	uespSalesHelper.measuredDistFactor = 0
	--uespLog.DebugMsg("OnPlayerActivated")
end

 
function uespSalesHelper.OnStartFastTravelInteraction(event, nodeIndex)
	uespSalesHelper.currentState = "JUMP"
	uespSalesHelper.lastWayshrineIndex = nodeIndex
	uespLog.DebugMsg("OnStartFastTravelInteraction "..tostring(nodeIndex))
end


function uespSalesHelper.OnEndFastTravelInteraction(event)
	uespSalesHelper.currentState = "IDLE"
	--uespLog.DebugMsg("OnEndFastTravelInteraction")
end


function uespSalesHelper.UpdateLabels()
	local x, y, characterHeading, zone = uespLog.GetPlayerPosition()
	local cameraHeading = GetPlayerCameraHeading()
	local currentTarget = uespSalesHelper.currentTargetData.name
	local currentState = uespSalesHelper.currentState
	local extraData = uespSalesHelper.extraData or ""
	
	dir = math.floor(cameraHeading * 180 / 3.14159)
	
	if (uespSalesHelper.isCalibration) then
		x = "0.000"
		y = "0.000"
		dir = "000"
		zone = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-_~!@#$%^&*()_+`=[]\\{}||;':\",./<>? 0000000000"
		currentTarget = zone
		extraData = zone
	end
	
	if (extraData == "" and not uespSalesHelper.autoScanStores) then
		extraData = "AUTOSCANSTORES IS OFF"
	end
	
	zone = zone:upper()
	currentTarget = currentTarget:upper()
	currentState = currentState:upper()
	extraData = extraData:upper()
	
	uespSalesHelperUIX:SetText(x)
	uespSalesHelperUIY:SetText(y)
	uespSalesHelperUIDir:SetText(dir)
	uespSalesHelperUIZone:SetText(zone)
	uespSalesHelperUITarget:SetText(currentTarget)
	uespSalesHelperUIState:SetText(currentState)
	uespSalesHelperUIExtra:SetText(extraData)
	
end


function uespSalesHelper.Calibrate()
	uespSalesHelper.isCalibration = not uespSalesHelper.isCalibration
end


function uespSalesHelper.OnUpdate()

    if (IsGameCameraUIModeActive()) then
		uespSalesHelper.UpdateLabels()
        return
    end
	
	local action, name, interactionBlocked, isOwned, additionalInfo, context, contextualLink, isCriminalInteract = GetGameCameraInteractableActionInfo()
	local active = IsPlayerInteractingWithObject()
	local interactionType = GetInteractionType()
	local x, y, z, zone

    if (name == nil) then
		uespSalesHelper.currentTargetData.name = ""
		uespSalesHelper.currentTargetData.x = ""
		uespSalesHelper.currentTargetData.y = ""
		uespSalesHelper.currentTargetData.zone = ""
		uespSalesHelper.UpdateLabels()
        return
    end
	
	if (not active) then
		uespSalesHelper.lastTargetData.name = name
		uespSalesHelper.lastTargetData.x = uespSalesHelper.currentTargetData.x
		uespSalesHelper.lastTargetData.y = uespSalesHelper.currentTargetData.y
		uespSalesHelper.lastTargetData.zone = uespSalesHelper.currentTargetData.zone
		uespSalesHelper.lastTargetData.gameTime = GetGameTimeMilliseconds()
		uespSalesHelper.lastTargetData.timeStamp = GetTimeStamp()
		uespSalesHelper.lastTargetData.action = uespSalesHelper.currentTargetData.action
		uespSalesHelper.lastTargetData.interactionType = uespSalesHelper.currentTargetData.interactionType
    end
	
    if (action == nil or name == "" or name == uespSalesHelper.currentTargetData.name) then
		uespSalesHelper.UpdateLabels()
        return
    end

	if (DoesUnitExist("reticleover")) then
		x, y, z, zone = uespLog.GetUnitPosition("reticleover")
	else
		x, y, z, zone = uespLog.GetPlayerPosition()
	end
	
	uespSalesHelper.currentTargetData.name = name
	uespSalesHelper.currentTargetData.x = x
	uespSalesHelper.currentTargetData.y = y
	uespSalesHelper.currentTargetData.zone = zone
	uespSalesHelper.currentTargetData.action = action
	uespSalesHelper.currentTargetData.interactionType = interactionType
	
	uespSalesHelper.UpdateLabels()
end


function uespSalesHelper.Wayshrine(nodeIndex)
	uespSalesHelper.currentState = "JUMP"
	FastTravelToNode(nodeIndex)
	
	zo_callLater(function() 
		if (uespSalesHelper.currentState == "JUMP" ) then
			uespSalesHelper.currentState = "IDLE" 
		end
	end, 10000)	
end


function uespSalesHelper.SavePoint()
	local currentState = uespSalesHelper.currentState
	
	uespSalesHelper.currentState = "SAVEPOINT"
	
	zo_callLater(function() uespSalesHelper.currentState = currentState end, 200)
end


function uespSalesHelper.SaveHeading()
	local currentState = uespSalesHelper.currentState
	
	uespSalesHelper.currentState = "SAVEHEADING"
	
	zo_callLater(function() uespSalesHelper.currentState = currentState end, 200)
end


function uespSalesHelper.SaveDistFactor()
	local currentState = uespSalesHelper.currentState
	local extraData = uespSalesHelper.extraData
	local numTilesX, numTilesY = GetMapNumTiles()
	local totalTiles = numTilesX * numTilesY
	local distFactor = 1
	
	if (totalTiles > 64) then
		distFactor = 1
	elseif (totalTiles >= 49) then
		distFactor = 2
	elseif (totalTiles >= 36) then
		distFactor = 3
	elseif (totalTiles >= 25) then
		distFactor = 5
	elseif (totalTiles >= 16) then
		distFactor = 10
	elseif (totalTiles >= 9) then
		distFactor = 25
	else
		distFactor = 32
	end
	
	if (uespSalesHelper.measuredDistFactor > 0) then
		distFactor = uespSalesHelper.measuredDistFactor
	end
	
	uespSalesHelper.currentState = "SAVEDISTFACTOR"
	uespSalesHelper.extraData = tostring(distFactor)
	
	zo_callLater(function() 
		uespSalesHelper.currentState = currentState 
		uespSalesHelper.extraData = extraData 
	end, 200)
	
end


function uespSalesHelper.SaveWayshrine()
	local currentState = uespSalesHelper.currentState
	local extraData = uespSalesHelper.extraData
	
	if (uespSalesHelper.lastWayshrineIndex == "") then
		uespLog.DebugMsg("No wayshrine visited recently!")
		return
	end
	
	uespSalesHelper.currentState = "SAVEWAYSHRINE"
	uespSalesHelper.extraData = tostring(uespSalesHelper.lastWayshrineIndex)
	
	zo_callLater(function() 
		uespSalesHelper.currentState = currentState 
		uespSalesHelper.extraData = extraData 
	end, 200)
	
end


function uespSalesHelper.DumpWayshrines()
	local numNodes = GetNumFastTravelNodes()
	local i
	local tempData = uespLog.savedVars.tempData.data
	
	for i = 1, numNodes do
		local known, name = GetFastTravelNodeInfo(i)
		tempData[#tempData + 1] = '{ "' .. name.. '", ' .. i .. ' },'
	end
end


function uespSalesHelper.MeasureDistFactor()
	uespLog.Msg("Start walking forward in a straight line for 5 seconds...")

	zo_callLater(function()
		uespLog.SpeedMeasureEnable()
	end, 1000)
	
	zo_callLater(function()
		local avgSpeed = uespLog.speedTotalDelta / (uespLog.speedLastTimestamp - uespLog.speedFirstTimestamp) * uespLog.speedMagicFactor
		
		uespSalesHelper.measuredDistFactor = math.floor(avgSpeed * 0.7)
		
		uespLog.SpeedMeasureDisable()
		uespLog.Msg("Estimated zone distance factor of "..tostring(uespSalesHelper.measuredDistFactor))
	end, 5000)
end


function uespSalesHelper.EndInteraction()
	local interType = GetInteractionType()
	
	if (interType > 0) then
		EndInteraction(interType)
	end
end


function uespSalesHelper.SalesHelperCommand(cmd)
	
	cmd = cmd:lower()
	
	if (cmd == "on") then
		uespSalesHelper.autoScanStores = true
		uespSalesHelper.savedVars.autoScanStores = true
		uespLog.Msg("UESP sales helper turned on.")
	elseif (cmd == "off") then
		uespSalesHelper.autoScanStores = false
		uespSalesHelper.savedVars.autoScanStores = false
		uespLog.Msg("UESP sales helper turned off.")
	else
		uespLog.Msg("Turns the UESP sales helper on/off:")
		uespLog.Msg(".      /uespsaleshelper [on||off]")
	end
	
end


SLASH_COMMANDS["/uespdistfactor"] = uespSalesHelper.MeasureDistFactor
SLASH_COMMANDS["/uespsaleshelper"] = uespSalesHelper.SalesHelperCommand
