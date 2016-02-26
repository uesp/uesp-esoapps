-- uespLogTradeData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to mining skill coefficients.

--/ud uespLog.SkillCoefData['Crystal Shard']
--/ud uespLog.SkillCoefAbilityData['Crystal Shard']

uespLog.SkillCoefData = {}
uespLog.SkillCoefAbilityData = {}
uespLog.SkillCoefAbilityCount = 0
uespLog.SkillCoefNumValidCoefCount = 0
uespLog.SkillCoefDataPointCount = 0
uespLog.SkillCoefDataIsCalculated = false

uespLog.SkillCoef_CaptureWykkyd_Prefix = "SkillCoef"
uespLog.SkillCoef_CaptureWykkyd_StartIndex = 1
uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
uespLog.SkillCoef_CaptureWykkyd_EndIndex = 5
uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = 5
uespLog.SkillCoef_CaptureWykkyd_TimeDelayLoadSet = 5000


SLASH_COMMANDS["/uespskillcoef"] = function(cmd)
	local cmds, cmd1 = uespLog.SplitCommands(cmd)
	local result
	
	if (cmd1 == "save") then
		result = uespLog.CaptureSkillCoefData()

		if (result) then
			uespLog.Msg("Successfully captured skill data for current character/equipment.")
		else
			uespLog.Msg("Error: Failed to capture skill data for current character/equipment!")
		end
		
	elseif (cmd1 == "calc" or cmd1 == "compute") then
		result = uespLog.ComputeSkillCoef()
		
		if (result) then
			uespLog.Msg("Successfully calculated skill coefficients.")
		else
			uespLog.Msg("Error: Failed to calculate skill coefficients!")
		end
		
	elseif (cmd1 == "coef") then
		local skillName = uespLog.implodeStart(cmds, " ", 2)
		uespLog.ShowSkillCoef(skillName)
	elseif (cmd1 == "status") then
		local calcStatus = "not "
		
		if (uespLog.SkillCoefDataIsCalculated) then
			calcStatus = ""
		end
		
		uespLog.Msg("There are "..tostring(uespLog.SkillCoefAbilityCount).." skills with "..tostring(uespLog.SkillCoefDataPointCount).." data points for calculating skill coefficients.")
		uespLog.Msg("Skill data is "..calcStatus.."calculated with "..tostring(uespLog.SkillCoefNumValidCoefCount).." skill variables with valid coefficients.")
		
		if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
			local setName = uespLog.SkillCoef_CaptureWykkyd_Prefix .. uespLog.SkillCoef_CaptureWykkyd_CurrentIndex
			uespLog.Msg(".     Currently saving skill data for Wykkyd's set "..tostring(setName))
		end
	elseif (cmd1 == "clear" or cmd1 == "reset") then
		uespLog.ClearSkillCoefData()
	elseif (cmd1 == "savewyk") then
		uespLog.CaptureSkillCoefDataWykkyd(cmds[2], cmds[3], cmds[4])
	elseif (cmd1 == "stop" or cmd1 == "end" or cmd1 == "abort") then
		uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = uespLog.SkillCoef_CaptureWykkyd_EndIndex + 1
		
		if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
			uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
			uespLog.Msg("Stopped saving skill data using Wykkyd's sets...")
		end
	else
		uespLog.Msg("Saves and calculates coefficients for all skills the character knows. Note that the saved skill data is *not* saved when you /reloadui or logout.")
		uespLog.Msg("To use use the 'save' command with at least 3 different sets of character stat (spell damage/magicka or weapon damage/stamina) and then use the 'calc' command.")
		uespLog.Msg(".     /uespsavecoef ...      Normal command form")
		uespLog.Msg(".     /usc ...                      Short form")
		uespLog.Msg(".     /usc save                 Save current skill data")
		uespLog.Msg(".     /usc calc                  Calculate coefficients using saved data")
		uespLog.Msg(".     /usc coef [name]      Shows the coefficients for the given skill name")
		uespLog.Msg(".     /usc coef [id]         Shows the coefficients for the given skill ID")
		uespLog.Msg(".     /usc status               Current status of saved skill data")
		uespLog.Msg(".     /usc clear                 Resets the saved skill data")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]  Saves skill data using Wykkyd's Outfitter. For example: '/usc savewyk Test 1 9' would try to load the sets 'Test1'...'Test10' and save the skill data for each of them.")
	end

end

SLASH_COMMANDS["/usc"] = SLASH_COMMANDS["/uespskillcoef"]


function uespLog.LogSkillCoefData()
	local logData = {}
	local rowData = {}
	
	uespLog.ClearSavedVarSection("tempData")
	
	table.insert(rowData, "Skill Name")
	table.insert(rowData, "ID")
	table.insert(rowData, "NumVars")
	table.insert(rowData, "Description")
	table.insert(rowData, "a1")
	table.insert(rowData, "b1")
	table.insert(rowData, "c1")
	table.insert(rowData, "R1")
	table.insert(rowData, "a2")
	table.insert(rowData, "b2")
	table.insert(rowData, "c2")
	table.insert(rowData, "R2")
	table.insert(rowData, "a3")
	table.insert(rowData, "b3")
	table.insert(rowData, "c3")
	table.insert(rowData, "R3")
	
	local data = uespLog.savedVars.tempData.data
	data[#data+1] = uespLog.implode(rowData, ", ")
	
	logData.event = "SkillCoef::Start"
	logData.numSkills = uespLog.SkillCoefAbilityCount
	logData.numPoints = uespLog.SkillCoefDataPointCount
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		uespLog.LogSkillCoefDataSkill(abilityData)
		uespLog.LogSkillCoefDataSkillCsv(abilityData)
	end
	
	logData.event = "SkillCoef::End"
	uespLog.AppendDataToLog("all", logData)
end


function uespLog.LogSkillCoefDataSkill(abilityData)
	local logData = {}
	
	if (not abilityData.isValid or abilityData.result == nil or #(abilityData.result) == 0) then
		return
	end
	
	logData.event = "SkillCoef"
	logData.desc = abilityData.newDesc
	logData.numVars = abilityData.numVars
	logData.name = abilityData.name
	logData.abilityId = abilityData.id
	
	for i,result in ipairs(abilityData.result) do
		local doesVary = abilityData.numbersVary[i]
		local a  = string.format("%.5f", result.a)
		local b  = string.format("%.5f", result.b)
		local c  = string.format("%.5f", result.c)
		local R2 = string.format("%.5f", result.R2)
		local index = abilityData.numbersIndex[i]
		
		if (doesVary) then
			logData['a'..tostring(index)] = a
			logData['b'..tostring(index)] = b
			logData['c'..tostring(index)] = c
			logData['R'..tostring(index)] = R2
		end
	end	
	
	uespLog.AppendDataToLog("all", logData)
end


function uespLog.LogSkillCoefDataSkillCsv(abilityData)
	local rowData = {}
	
	if (not abilityData.isValid or abilityData.result == nil or #(abilityData.result) == 0) then
		return
	end
	
	table.insert(rowData, "'"..abilityData.name.."'")
	table.insert(rowData, abilityData.id)
	table.insert(rowData, abilityData.numVars)
	table.insert(rowData, "'"..abilityData.newDesc.."'")
	
	for i,result in ipairs(abilityData.result) do
		local doesVary = abilityData.numbersVary[i]
		local a  = string.format("%.5f", result.a)
		local b  = string.format("%.5f", result.b)
		local c  = string.format("%.5f", result.c)
		local R2 = string.format("%.5f", result.R2)
		local index = abilityData.numbersIndex[i]
		
		if (doesVary) then
			table.insert(rowData, a)
			table.insert(rowData, b)
			table.insert(rowData, c)
			table.insert(rowData, R2)
		end
	end	
	
	local data = uespLog.savedVars.tempData.data
	data[#data+1] = uespLog.implode(rowData, ", ")
end


function uespLog.CaptureSkillCoefDataWykkyd(setPrefix, startIndex, endIndex)

	if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return false
	end
	
	if (setPrefix == nil or setPrefix == "" or startIndex == nil or endIndex == nil) then
		uespLog.Msg("Error: Missing required parameters! Command format is:")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]")
		return false
	end
	
	startIndex = tonumber(startIndex)
	endIndex   = tonumber(endIndex)
	
	if (startIndex == nil or endIndex == nil) then
		uespLog.Msg("Error: 'start' and 'end' must be valid numbers! Command format is:")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]")
		return false
	end
	
	if (SLASH_COMMANDS['/loadset'] == nil) then
		uespLog.Msg("Error: It doesn't look like the Wykkyd's Outfitter add-on is installed!")
		return false
	end
	
	uespLog.SkillCoef_CaptureWykkyd_Prefix = setPrefix
	uespLog.SkillCoef_CaptureWykkyd_StartIndex = startIndex
	uespLog.SkillCoef_CaptureWykkyd_EndIndex = endIndex
	uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = 1
	
	local startSet = setPrefix .. tostring(startIndex)
	local endSet = setPrefix .. tostring(endIndex)
	
	uespLog.Msg("Starting skill data capture using Wykkyd's sets "..tostring(startSet).."..."..tostring(endSet))
	
	uespLog.SkillCoef_CaptureWykkyd_IsWorking = true
	uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()

	return true
end


function uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()

	if (not uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return
	end

	if (uespLog.SkillCoef_CaptureWykkyd_CurrentIndex > uespLog.SkillCoef_CaptureWykkyd_EndIndex) then
		local startSet = uespLog.SkillCoef_CaptureWykkyd_Prefix .. tostring(uespLog.SkillCoef_CaptureWykkyd_StartIndex)
		local endSet = uespLog.SkillCoef_CaptureWykkyd_Prefix .. tostring(uespLog.SkillCoef_CaptureWykkyd_EndIndex)
		uespLog.Msg("Finished skill data capture using Wykkyd's sets "..tostring(startSet).."..."..tostring(endSet))
		uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
		return
	end
	
	local setName = tostring(uespLog.SkillCoef_CaptureWykkyd_Prefix) .. tostring(uespLog.SkillCoef_CaptureWykkyd_CurrentIndex)
	SLASH_COMMANDS['/loadset'](setName)
	
	zo_callLater(uespLog.CaptureNextSkillCoefDataWykkyd_SaveData, uespLog.SkillCoef_CaptureWykkyd_TimeDelayLoadSet)
end


function uespLog.CaptureNextSkillCoefDataWykkyd_SaveData()

	if (not uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return
	end
	
	local setName = tostring(uespLog.SkillCoef_CaptureWykkyd_Prefix) .. tostring(uespLog.SkillCoef_CaptureWykkyd_CurrentIndex)

	if (uespLog.CaptureSkillCoefData()) then
		uespLog.Msg("Saved skill data for Wykyyd's set '"..tostring(setName).."'.")
	else
		uespLog.Msg("Error: Failed to savedskill data for Wykyyd's set '"..tostring(setName).."'!")
	end
	
	uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = uespLog.SkillCoef_CaptureWykkyd_CurrentIndex + 1
	uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()
end
	

function uespLog.ShowSkillCoef(name)
	local abilityId = tonumber(name)
	local coefData = nil

	if (name == nil or name == "") then
		return false
	end
	
	if (abilityId ~= nil) then
		coefData = uespLog.SkillCoefAbilityData[abilityId]
	else
		coefData = uespLog.FindSkillAbilityData(name)
	end
	
	if (coefData == nil) then
		uespLog.Msg("Skill #"..tostring(name).." does not exist in coefficient data!")
		return false
	end
	
	if (not coefData.isValid or coefData.result == nil) then
		uespLog.Msg("Coefficient data for skill #"..tostring(name).." is not valid!")
		return false
	end
	
	uespLog.Msg("Skill '"..tostring(coefData.name).." ("..tostring(coefData.id)..")' has coefficient data for "..tostring(coefData.numVars).." variable(s):")
	
	for i,result in ipairs(coefData.result) do
		local doesVary = coefData.numbersVary[i]
		local a  = string.format("%.5f", result.a)
		local b  = string.format("%.5f", result.b)
		local c  = string.format("%.5f", result.c)
		local R2 = string.format("%.5f", result.R2)
		local index = coefData.numbersIndex[i]
		
		if (doesVary) then
			uespLog.Msg(".     $"..tostring(index)..": "..a..", "..b..", "..c..", "..R2)
		end
	end	
	
	uespLog.Msg(tostring(coefData.newDesc))
	
	return true
end


function uespLog.FindSkillAbilityData(name)

	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		if (abilityData.name == name) then
			return abilityData
		end
	end
	
	return nil
end


function uespLog.ClearSkillCoefData()
	uespLog.SkillCoefData = {}
	uespLog.SkillCoefAbilityData = {}
	uespLog.SkillCoefAbilityCount = 0
	uespLog.SkillCoefDataPointCount = 0
	uespLog.SkillCoefNumValidCoefCount = 0
	uespLog.SkillCoefDataIsCalculated = false
end


function uespLog.CaptureSkillCoefData()
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local skillCount = 0
		
	uespLog.DebugLogMsg("Saving current skill data for character...")

	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
					
			for abilityIndex = 1, numSkillAbilities do
				skillCount = skillCount + 1
				
				local name, _, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local ability1 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local ability2 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, true)
				local ability3 = -1
				local ability4 = -1
				local ability5 = -1
				
				if (progressionIndex ~= nil and progressionIndex > 0) then
					ability3 = GetAbilityProgressionAbilityId(progressionIndex, 0, 4)
					ability4 = GetAbilityProgressionAbilityId(progressionIndex, 1, 4)
					ability5 = GetAbilityProgressionAbilityId(progressionIndex, 2, 4)
					uespLog.SaveSkillCoefData(ability3)
					uespLog.SaveSkillCoefData(ability4)
					uespLog.SaveSkillCoefData(ability5)
				else
					uespLog.SaveSkillCoefData(ability1)
					uespLog.SaveSkillCoefData(ability2)
				end
		
			end
		end
	end
	
	uespLog.DebugMsg(".     Saved data for "..tostring(skillCount).." character skills!")
	uespLog.SkillCoefDataPointCount = uespLog.SkillCoefDataPointCount + 1
	return true
end


function uespLog.SaveSkillCoefData(abilityId)
	local name = GetAbilityName(abilityId)
	local description = GetAbilityDescription(abilityId)
	local cost, mechanic = GetAbilityCost(abilityId)

	--POWERTYPE_MAGICKA == 0
	--POWERTYPE_STAMINA == 6
	--POWERTYPE_ULTIMATE == 10

	if (abilityId <= 0 or name == "" or description == "") then
		return false
	end
	
	if (uespLog.SkillCoefData[abilityId] == nil) then
		uespLog.SkillCoefData[abilityId] = {}
	end
	
	if (uespLog.SkillCoefAbilityData[abilityId] == nil) then
		uespLog.SkillCoefAbilityData[abilityId] = 
		{
			["name"] = name,
			["id"]   = abilityId,
			["desc"] = description,
			["type"] = mechanic,
			["data"] = {},
			["numVars"] = -1,
			["numbersVary"] = {},
			["numbersIndex"] = {},
		}
		uespLog.SkillCoefAbilityCount = uespLog.SkillCoefAbilityCount + 1
	end
	
	local i = #(uespLog.SkillCoefData[abilityId])
	
	uespLog.SkillCoefData[abilityId][i+1] = 
	{
		["mag"]  = GetPlayerStat(STAT_MAGICKA_MAX),
		["sta"]  = GetPlayerStat(STAT_STAMINA_MAX),
		["sd"] 	 = GetPlayerStat(STAT_SPELL_POWER),
		["wd"]   = GetPlayerStat(STAT_WEAPON_POWER),
		["desc"] = description,
	}
	
	return true
end


function uespLog.ParseSkillCoefData()

	for abilityId, skillsData in pairs(uespLog.SkillCoefData) do
		uespLog.ParseSkillCoefDataSkill(abilityId, skillsData)
	end
	
	return true
end


function uespLog.ParseSkillCoefDataSkill(abilityId, skillsData)

	for i,data in ipairs(skillsData) do
		local iter = string.gmatch(data['desc'], "%d+\[.]?%d*")
		data['numbers'] = {}
		
		for number in iter do
			table.insert(data['numbers'], tonumber(number))
		end
		
	end
	
end


function uespLog.ComputeSkillCoef()
	uespLog.ParseSkillCoefData()
	
	if (uespLog.SkillCoefDataPointCount < 3) then
		uespLog.Msg("Error: You need a minimum of 3 data points to compute skill coefficients.")
		return false
	end
	
	for abilityId, skillsData in pairs(uespLog.SkillCoefData) do
	
		if (uespLog.CheckSkillCoef(abilityId, skillsData)) then
			uespLog.ComputeSkillCoefSkill(abilityId, skillsData)
		end
		
	end
	
	uespLog.ReplaceSkillDescriptions()
	uespLog.LogSkillCoefData()
	uespLog.SkillCoefDataIsCalculated = true
	return true
end


function uespLog.CheckSkillCoef(abilityId, skillsData)
	local numbersCheck = {}
	local abilityData = uespLog.SkillCoefAbilityData[abilityId]
	
	abilityData.numVars = 0
	abilityData.numbersVary = {}
	abilityData.numbersIndex = {}
	
	if (#skillsData == 0) then
		return false
	end
	
	for i,number in ipairs(skillsData[1].numbers) do
		table.insert(numbersCheck, number)
		table.insert(abilityData.numbersVary, false)
	end
	
	for i = 2, #skillsData do
		for j,number in ipairs(skillsData[i].numbers) do
			if (number ~= numbersCheck[j]) then
				abilityData.numbersVary[j] = true
			end
		end
	end
	
	local index = 1
	
	for i,number in ipairs(abilityData.numbersVary) do
		if (abilityData.numbersVary[i]) then
			abilityData.numVars = abilityData.numVars + 1
			table.insert(abilityData.numbersIndex, index)
			index = index + 1
		else
			table.insert(abilityData.numbersIndex, 0)
		end
	end
	
	return (abilityData.numVars > 0)
end


function uespLog.ComputeSkillCoefSkill(abilityId, skillsData)
    -- z = ax + by + c
	-- x = Mag/Sta
	-- y = SD/WD
	-- z = Tooltip value
	-- X = a, b, c
	-- A X = B
	-- X = Ainv B	
	local abilityData = uespLog.SkillCoefAbilityData[abilityId]
	
	abilityData.data = {}
	abilityData.numPoints = #skillsData
	
	if (abilityData.numPoints < 3) then
		return false
	end
	
	local numberCount = #(skillsData[1].numbers)
	
	if (numberCount < 0) then
		return false
	end
	
	local coefData = {}
	coefData.A = uespLog.SkillCoefComputeAMatrix(skillsData, abilityData)
	coefData.Ainv, coefData.isValid = uespLog.SkillCoefComputeAMatrixInv(coefData.A)
	coefData.B = {}
	coefData.result = {}
	
	if (not coefData.isValid) then
		abilityData.data = coefData
		abilityData.result = coefData.result
		abilityData.isValid = coefData.isValid
		return false
	end
	
	for i = 1, numberCount do
	
		if (abilityData.numbersVary[i]) then
			local B = uespLog.SkillCoefComputeBMatrix(skillsData, abilityData, i)
			table.insert(coefData.B, B)
		
			local result = uespLog.SkillCoefComputeMatrixMultAB(coefData.Ainv, B)
			result.R2 = uespLog.SkillCoefComputeR2(result, skillsData, abilityData, i)
			table.insert(coefData.result, result)
			
			if (not uespLog.isFinite(result.a) or not uespLog.isFinite(result.b) or not uespLog.isFinite(result.c) or not uespLog.isFinite(result.R2)) then
				coefData.isValid = false
			else
				uespLog.SkillCoefNumValidCoefCount = uespLog.SkillCoefNumValidCoefCount + 1
			end
			
		else
			table.insert(coefData.result, { ['a']=0, ['b']=0, ['c']=skillsData[1].numbers[i], ['R2']=1 } )
		end
		
	end
	
	abilityData.data = coefData
	abilityData.result = coefData.result
	abilityData.isValid = coefData.isValid
	return true
end


function uespLog.SkillCoefComputeR2(coef, skillsData, abilityData, numberIndex)
	local R2 = 0
	local count = #skillsData
	local averageZ = 0
	local SSres = 0
	local SStot = 0
	local x = 0
	local y = 0
	
	if (count == 0 or coef.a == nil ) then
		return R2
	end
	
	for i,skill in ipairs(skillsData) do
		local z = skill.numbers[numberIndex]
		averageZ = averageZ + z
	end
	
	averageZ = averageZ / count
	
	for i,skill in ipairs(skillsData) do
		x = skill.mag
		y = skill.sd
		
		if (abilityData.type == POWERTYPE_STAMINA or (abilityData.type == POWERTYPE_ULTIMATE and skill.sta > skill.mag)) then
			x = skill.sta
			y = skill.wd
		end
		
		local z = skill.numbers[numberIndex]
		local f = x * coef.a + y * coef.b + coef.c
		local e = z - f
		local d = z - averageZ
		
		SStot = SStot + d * d
		SSres = SSres + e * e
	end
	
	if (SStot == 0) then
		return R2
	end

	R2 = 1 - SSres / SStot
	return R2
end


function uespLog.SkillCoefComputeMatrixMultAB(A, B)
	local result = {}
	
	result.a = A[11] * B[1] + A[12] * B[2] + A[13] * B[3]
	result.b = A[21] * B[1] + A[22] * B[2] + A[23] * B[3]
	result.c = A[31] * B[1] + A[32] * B[2] + A[33] * B[3]
	
	return result
end


function uespLog.SkillCoefComputeAMatrix(skillsData, abilityData)
	-- A =  sum_i x[i]*x[i],    sum_i x[i]*y[i],    sum_i x[i]
	--		sum_i x[i]*y[i],    sum_i y[i]*y[i],    sum_i y[i]
	--		sum_i x[i],         sum_i y[i],         sum_i 1
	
	local A = {}
	local x = 0
	local y = 0
	
	A[11] = 0
	A[12] = 0
	A[13] = 0
	A[21] = 0
	A[22] = 0
	A[23] = 0
	A[31] = 0
	A[32] = 0
	A[33] = 0
	
	for i,skill in ipairs(skillsData) do
		x = skill.mag
		y = skill.sd
		
		if (abilityData.type == POWERTYPE_STAMINA or (abilityData.type == POWERTYPE_ULTIMATE and skill.sta > skill.mag)) then
			x = skill.sta
			y = skill.wd
		end
		
		A[11] = A[11] + x*x
		A[12] = A[12] + x*y
		A[13] = A[13] + x
		A[21] = A[21] + x*y
		A[22] = A[22] + y*y
		A[23] = A[23] + y
		A[31] = A[31] + x
		A[32] = A[32] + y
		A[33] = A[33] + 1
	end
	
	return A
end


function uespLog.SkillCoefComputeBMatrix(skillsData, abilityData, numberIndex)
	-- B =  sum_i x[i]*z[i],    sum_i y[i]*z[i],    sum_i z[i]
	
	local B = {}
	local x = 0
	local y = 0
	
	B[1] = 0
	B[2] = 0
	B[3] = 0
	
	for i,skill in ipairs(skillsData) do
		x = skill.mag
		y = skill.sd
		z = skill.numbers[numberIndex]
		
		if (abilityData.type == POWERTYPE_STAMINA or (abilityData.type == POWERTYPE_ULTIMATE and skill.sta > skill.mag)) then
			x = skill.sta
			y = skill.wd
		end
		
		B[1] = B[1] + x*z
		B[2] = B[2] + y*z
		B[3] = B[3] + z		
	end
	
	return B
end


function uespLog.SkillCoefComputeAMatrixInv(A)
	local Adet = uespLog.SkillCoefComputeAMatrixDet(A)
	local Ainv = {}
		
	if (det == 0) then
		Ainv[11] = 0
		Ainv[12] = 0
		Ainv[13] = 0
		Ainv[21] = 0
		Ainv[22] = 0
		Ainv[23] = 0
		Ainv[31] = 0
		Ainv[32] = 0
		Ainv[33] = 0

		return Ainv, false
	end
	
	Ainv[11] = (A[22]*A[33] - A[32]*A[23]) / Adet
	Ainv[12] = (A[13]*A[32] - A[33]*A[12]) / Adet
	Ainv[13] = (A[12]*A[23] - A[22]*A[13]) / Adet
	Ainv[21] = (A[23]*A[31] - A[33]*A[21]) / Adet
	Ainv[22] = (A[11]*A[33] - A[31]*A[13]) / Adet
	Ainv[23] = (A[13]*A[21] - A[23]*A[11]) / Adet
	Ainv[31] = (A[21]*A[32] - A[31]*A[22]) / Adet
	Ainv[32] = (A[12]*A[31] - A[32]*A[11]) / Adet
	Ainv[33] = (A[11]*A[22] - A[21]*A[12]) / Adet
	
	return Ainv, true
end	


function uespLog.SkillCoefComputeAMatrixDet(A)
	local Adet = 0
	
	Adet = A[11]*A[22]*A[33] + A[12]*A[23]*A[31] + A[13]*A[21]*A[32] - A[31]*A[22]*A[13] - A[32]*A[23]*A[11] - A[33]*A[21]*A[12]
	
	return Adet
end


function uespLog.SkillCoefNumber_Average(numbers)
	local sum = 0
	local count = #numbers
	local average = 0
	
	for i,number in ipairs(numbers) do
		sum = sum + number
	end
	
	if (count ~= 0) then
		average = sum / count
	end
	
	return average, sum
end


function uespLog.SkillCoefNumber_AverageDiff(numbers, value)
	local sum = 0
	local count = #numbers
	local average = 0
	
	for i,number in ipairs(numbers) do
		sum = sum + number - value
	end
	
	if (count ~= 0) then
		average = sum / count
	end
	
	return average, sum
end


function uespLog.ReplaceSkillDescriptions()
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		uespLog.ReplaceSkillDescriptionAbility(abilityData)
	end
	
end


function uespLog.ReplaceSkillDescriptionAbility(abilityData)
	local i = 0
    
	local newDesc = string.gsub(abilityData.desc, "%d+\[.]?%d*", function (number)
		i = i + 1
	
		if (abilityData.numbersVary[i]) then
			return "$" .. tostring(abilityData.numbersIndex[i])
		end
		
    end)
	
	abilityData.newDesc = newDesc
	return newDesc
end


function uespLog.isFinite(number)
	return number > -math.huge and number < math.huge 
end


