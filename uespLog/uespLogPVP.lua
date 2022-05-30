-- uespLogPVP.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to the PVP data portion of the add-on
--
-- QueryCampaignSelectionData()
-- Update when logging in to a PVP zone


uespLog.PVPLOG_LIMIT_ENTRIES = 100					-- Only log the first N entries in a PVP leaderboard
uespLog.PVPLOG_AUTO_LEADERBOARD_TIMESECS = 1800		-- Seconds between auto leaderboard logging
uespLog.PVPLOG_LEADERBOARD_TIMESTAMP = 300			-- Minimum time from last leaderboard update before we query for another one

uespLog.lastPvpAutoLogTime = 0
uespLog.lastPvpLeaderboardTimestamp = 0

function uespLog.LogAllCyrodiilCampaigns()
	local i
	local count = 0

	for i = 1, 200 do
		local campaignId = GetSelectionCampaignId(i)
	
		if (campaignId > 0) then
			uespLog.LogCyrodiilCampaign(campaignId, i)
			count = count + 1
		end
	end
	
	uespLog.DebugMsg("Logged "..tostring(count) .. " Cyrodiil campaigns!")
end


function uespLog.LogCyrodiilCampaign(campaignId, campaignIndex)
	local logData = {}
	
	logData.event = "campaign"
	logData.id = campaignId
	logData.index = campaignIndex
	logData.name = GetCampaignName(campaignId)
	logData.server = uespLog.GetServerPlatformString()
	logData.score1 = GetSelectionCampaignAllianceScore(campaignIndex, 1)
	logData.score2 = GetSelectionCampaignAllianceScore(campaignIndex, 2)
	logData.score3 = GetSelectionCampaignAllianceScore(campaignIndex, 3)
	logData.underdog = GetSelectionCampaignUnderdogLeaderAlliance(campaignIndex)

	logData.pop1 = GetSelectionCampaignPopulationData(campaignIndex, 1)
	logData.pop2 = GetSelectionCampaignPopulationData(campaignIndex, 1)
	logData.pop3 = GetSelectionCampaignPopulationData(campaignIndex, 1)
	
	logData.waitTime = GetSelectionCampaignQueueWaitTime(campaignIndex)
	logData.startTime, logData.endTime = GetSelectionCampaignTimes(campaignIndex)
	
	-- Returns 0s in IC
	--GetCampaignHoldingScoreValues(number campaignId)
	--Returns: number keepValue, number resourceValue, number outpostValue, number defensiveArtifactValue, number offensiveArtifactValue
	
	-- GetCampaignRulesetName(number campaignId) ?

	
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
end


function uespLog.LogCurrentCyrodiilLeaderboard()
	local logData = {}
	local campaignId = GetCurrentCampaignId()
	
	if (campaignId == nil or campaignId <= 0) then
		uespLog.DebugMsg("Not currently in a campaign!")
		return false
	end
	
	logData.event = "campaign::Leaderboard"
	logData.id = campaignId
	logData.name = GetCampaignName(campaignId)
	logData.server = uespLog.GetServerPlatformString()
	
	logData.count = GetNumCampaignLeaderboardEntries(campaignId)
	logData.count1 = GetNumCampaignAllianceLeaderboardEntries(campaignId, 1)
	logData.count2 = GetNumCampaignAllianceLeaderboardEntries(campaignId, 2)
	logData.count3 = GetNumCampaignAllianceLeaderboardEntries(campaignId, 3)
	
	logData.score1 = GetCampaignAllianceScore(campaignId, 1)
	logData.score2 = GetCampaignAllianceScore(campaignId, 2)
	logData.score3 = GetCampaignAllianceScore(campaignId, 3)
		
	logData.potScore1 = GetCampaignAlliancePotentialScore(campaignId, 1)
	logData.potScore2 = GetCampaignAlliancePotentialScore(campaignId, 2)
	logData.potScore3 = GetCampaignAlliancePotentialScore(campaignId, 3)
	
	-- HOLDINGTYPE_DEFENSIVE_ARTIFACT 3
	-- HOLDINGTYPE_KEEP 0
	-- HOLDINGTYPE_OFFENSIVE_ARTIFACT 4
	-- HOLDINGTYPE_OUTPOST 2
	-- HOLDINGTYPE_RESOURCE 1
	
	-- 0s in IC?
	--GetCampaignHoldings(number campaignId, number CampaignHoldingType holdingType, number Alliance alliance, number Alliance targetAlliance)
	--Returns: number holdingsControlled
	
	-- Empty in IC
	--GetCampaignEmperorInfo(number campaignId)
	--Returns: number Alliance emperorAlliance, string emperorCharacterName, string emperorDisplayName

	logData.maxRank = GetCampaignLeaderboardMaxRank(campaignId)
	logData.seqId = GetLeaderboardCampaignSequenceId(campaignId)

	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	uespLog.LogCurrentCyrodiilLeaderboardEntries(campaignId)
	uespLog.LogCurrentCyrodiilLeaderboardAllianceEntries(1, campaignId)
	uespLog.LogCurrentCyrodiilLeaderboardAllianceEntries(2, campaignId)
	uespLog.LogCurrentCyrodiilLeaderboardAllianceEntries(3, campaignId)
	
	return true
end


function uespLog.LogCurrentCyrodiilLeaderboardEntries(campaignId)
	local numEntries = GetNumCampaignLeaderboardEntries(campaignId)
	local logData = {}
	local isPlayer
	local server = uespLog.GetServerPlatformString()
	local i
	
			-- This assumes the entries are sorted by highest score first
	if (numEntries > uespLog.PVPLOG_LIMIT_ENTRIES) then
		numEntries = uespLog.PVPLOG_LIMIT_ENTRIES
	end
	
	for i = 1, numEntries do
		logData = {}
		logData.event = "campaign::LeadEntry"
		logData.campaignId = campaignId
		logData.server = server
		
		isPlayer, logData.rank, logData.name, logData.points, logData.classId, logData.alliance, logData.displayName = GetCampaignLeaderboardEntryInfo(campaignId, i)
		
		uespLog.AppendDataToLog("all", logData)
	end

	uespLog.DebugMsg("Logged "..tostring(numEntries).." campaign leaderboard entries!")
end


-- This doesn't seem to ever return results?
function uespLog.LogCurrentCyrodiilLeaderboardAllianceEntries(alliance, campaignId)
	local numEntries = GetNumCampaignAllianceLeaderboardEntries(alliance, campaignId)
	local logData = {}
	local isPlayer 
	local i
	
			-- This assumes the entries are sorted by highest score first
	if (numEntries > uespLog.PVPLOG_LIMIT_ENTRIES) then
		numEntries = uespLog.PVPLOG_LIMIT_ENTRIES
	end
	
	for i = 1, numEntries do
		logData = {}
		logData.event = "campaign::AllianceEntry"
		logData.campaignId = campaignId
		logData.alliance = alliance
		
		isPlayer, logData.rank, logData.name, logData.points, logData.classId, logData.displayName = GetCampaignAllianceLeaderboardEntryInfo(campaignId, alliance, i)
		
		uespLog.AppendDataToLog("all", logData)
	end

	uespLog.DebugMsg("Logged "..tostring(numEntries).." campaign leaderboard entries for alliance "..tostring(alliance).."!")
end


function uespLog.CheckAutoPVPLogging(overrideTimestamp)
	local campaignId = GetCurrentCampaignId()
	
	if (overrideTimestamp == nil) then
		overrideTimestamp = false
	end
	
	if (campaignId == nil or campaignId <= 0) then
		return
	end
	
	if (not uespLog.IsPvpAutoLog()) then
		return
	end
	
	local currentTime = GetTimeStamp()
	
	if (not overrideTimestamp and currentTime - uespLog.lastPvpAutoLogTime < uespLog.PVPLOG_AUTO_LEADERBOARD_TIMESECS) then
		return
	end
	
	uespLog.DebugMsg("Auto logging PVP campaign and leaderboard data...")
	
	uespLog.LogAllCyrodiilCampaigns()
	uespLog.LogCurrentCyrodiilLeaderboard()

	uespLog.lastPvpAutoLogTime = currentTime
end


function uespLog.OnCampaignLeaderboardDataChanged(event)
	uespLog.DebugMsg("OnCampaignLeaderboardDataChanged")
	
	uespLog.CheckAutoPVPLogging()
end