--[[descriptionData = {
	type = "uespdescription",
	title = "My Title",	--(optional)
	text = "My description text to display.",
	width = "full",	--or "half" (optional)
	reference = "MyAddonDescription"	--(optional) unique global reference to control
}	]]


local wm = WINDOW_MANAGER
local tinsert = table.insert


local function UpdateValue(control)
	uespLog.DebugMsg("UpdateValue "..tostring(control)..", "..tostring(control.data.getFunc))

	if (control.title) then
		control.title:SetText(control.data.title)
	end
	
	if (control.data.getFunc) then
		control.data.text = control.data.getFunc()
		control.desc:SetText(control.data.text)
	else
		control.desc:SetText(control.data.text)
	end
	
end


function LAMCreateControl.uespdescription(parent, descriptionData, controlName)
	local control = wm:CreateControl(controlName or descriptionData.reference, parent.scroll or parent, CT_CONTROL)
	control:SetResizeToFitDescendents(true)
	local isHalfWidth = descriptionData.width == "half"
	
	uespLog.DebugMsg("LAMCreateControl.uespdescription")
	
	if isHalfWidth then
		control:SetDimensionConstraints(250, 55, 250, 100)
		control:SetDimensions(250, 55)
	else
		control:SetDimensionConstraints(510, 40, 510, 100)
		control:SetDimensions(510, 30)
	end

	control.desc = wm:CreateControl(nil, control, CT_LABEL)
	local desc = control.desc
	desc:SetVerticalAlignment(TEXT_ALIGN_TOP)
	desc:SetFont("ZoFontGame")
	desc:SetText(descriptionData.text)
	desc:SetWidth(isHalfWidth and 250 or 510)

	if descriptionData.title then
		control.title = wm:CreateControl(nil, control, CT_LABEL)
		local title = control.title
		title:SetWidth(isHalfWidth and 250 or 510)
		title:SetAnchor(TOPLEFT, control, TOPLEFT)
		title:SetFont("ZoFontWinH4")
		title:SetText(descriptionData.title)
		desc:SetAnchor(TOPLEFT, title, BOTTOMLEFT)
	else
		desc:SetAnchor(TOPLEFT)
	end

	control.panel = parent.panel or parent	--if this is in a submenu, panel is its parent
	control.data = descriptionData
	control.UpdateValue = UpdateValue
	
	if control.panel.data.registerForRefresh or control.panel.data.registerForDefaults then	--if our parent window wants to refresh controls, then add this to the list
		tinsert(control.panel.controlsToRefresh, control)
	end

	return control
end