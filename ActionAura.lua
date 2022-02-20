local AddonName  = ...
local actionAura = LibStub("AceAddon-3.0"):NewAddon(AddonName)
local variables = "actionAura_SV"

actionAura.isUnitPlayer = {
	player = true,
	vehicle = true,
	pet = true,
}

actionAura.units = {
		"mouseover",
		"target",
		"focus" ,
		"player",
 }

actionAura.GetUnit = {
	HARMFUL = function()
		for i, unitTarget in pairs(actionAura.units) do
			if  actionAura:Get("ignoreHarm_"..unitTarget) ~= true then
				if (UnitExists(unitTarget) == true)
				and(UnitIsDeadOrGhost(unitTarget) ~= true)
				and(UnitCanAttack(unitTarget, "player") == true) then
					return unitTarget, i
				end
			end
		end
		--if no unit is found, return a filler unit to prevent errors
		return actionAura:Get("ignoreHarm_".."target") ~= true and "target"
	end,
	HELPFUL = function()
		for i, unitTarget in pairs(actionAura.units) do
			if  actionAura:Get("ignoreHelp_"..unitTarget) ~= true then
				if (UnitExists(unitTarget) == true)
				and(UnitIsDeadOrGhost(unitTarget) ~= true)
				and(UnitCanAttack(unitTarget, "player") ~= true) then
					return unitTarget, i
				end
			end
		end
		--if no unit is found, return a filler unit to prevent errors
		return actionAura:Get("ignoreHelp_".."player") ~= true and "player"
	end,
}

function actionAura:GetActionIndex(actionButton)
	local name = actionButton.name or actionButton:GetName()	
	if name and string.find(name, 'BT4Button', 1) then
		--Bartender4 Support
		local actionType, actionID = actionButton:GetAction()
		if actionType == 'action' then
			return actionID
		end
	else
		return actionButton.action
	end
end

function actionAura:GetAuraTarget(actionType, actionID, filter, auraName)
	if actionType == 'macro' then
		local macroName = GetMacroInfo(actionID)
		if macroName ~= nil then
			-- check if we have 'Focus' in the macro name, if so, target is 'focus' for this button
				--may now be any of four units in the macro title. (mouseover, target, focus, player) ~Goranaws
			for i, unitTarget in pairs(self.units) do
				local startPos, endPos = string.find(string.lower(macroName), unitTarget)
				if startPos ~= nil then
					return unitTarget
				end
			end
		end
	end
	return self.GetUnit[filter]()
end

local filterOverride = {
	buff = {},
	debuff = {
		"Force of Nature",
	},
}

function actionAura:GetFilter(spellName)
	local filter = IsHarmfulSpell(spellName) and "HARMFUL" or IsHelpfulSpell(spellName) and "HELPFUL" or "HARMFUL"

	local filterOverride = self:Get("filterOverride")

	if tContains(filterOverride.debuff, spellName) then
		filter = "HARMFUL"
	elseif tContains(filterOverride.buff, spellName) then
		filter = "HELPFUL"
	end

	return filter
end

function actionAura:GetAuraDetails(spellName, actionType, actionID)
	if spellName and _G[variables].translations[spellName] and (#_G[variables].translations[spellName] > 0) then
		for i, overRideSpellName in pairs(_G[variables].translations[spellName]) do
			if overRideSpellName then
				local filter = self:GetFilter(spellName)
				local unit = self:GetAuraTarget(actionType, actionID, filter, overRideSpellName)
				if unit then
					local name, _, _, _, duration, expireTime, source, _, _, _, _, _, castByPlayer = AuraUtil.FindAuraByName(overRideSpellName, unit, filter)
					if name then
						return name, duration, expireTime, (castByPlayer == true) and "player" or source, filter
					end
				end
			end
		end
	end
	if spellName then
		local filter = self:GetFilter(spellName)
				
		local unit = self:GetAuraTarget(actionType, actionID, filter, spellName)
				
		if unit then
			local name, _, _, _, duration, expireTime, source, _, _, _, _, _, castByPlayer = AuraUtil.FindAuraByName(spellName, unit, filter)
			
			if name then
				return name, duration, expireTime, (castByPlayer == true) and "player" or source, filter
			end
		end
	end
end

function actionAura:GetAuraName(actionButton)
	local actionIndex = self:GetActionIndex(actionButton)
	if actionIndex then
		local actionType, actionID, subType, globalID = GetActionInfo(actionIndex) --Returns information about a specific action.
		local spellName

		if actionType == 'spell' then
			if actionID and actionID > 0 then
				spellName = GetSpellInfo(actionID)
			elseif globalID then
				spellName = GetSpellInfo(globalID)
			end
		elseif actionType == 'item' then
			spellName = GetItemSpell(actionID)
		elseif actionType == 'macro' then
			actionID = GetMacroSpell(actionID)
			if actionID then
				spellName = GetSpellInfo(actionID)
			end
		end

		local auraName, auraDuration, auraExpireTime, source, filter = self:GetAuraDetails(spellName, actionType, actionID)
		
		if not actionAura:Get("personalAurasOnly") == true then
			source = "player"
		end
		
		if auraName and self.isUnitPlayer[source] then
			local spellStart, spellDuration = GetSpellCooldown(spellName)
			return auraName, filter, auraExpireTime, auraDuration, spellStart or 0, spellDuration or 0
		end
	end
end

local auraColor = {
	HELPFUL = {0,1,0,1},
	HARMFUL = {1,0,0,1},
	[""] = {1,1,1,1},
}

actionAura.buttonRegistry = {}
function actionAura:SetAuraCooldown(actionButton, filter, expireTime, duration)
	if actionButton.auraCooldown == nil then
		if not tContains(self.buttonRegistry, actionButton) then
			tinsert(self.buttonRegistry, actionButton)
			local name = actionButton.name or actionButton:GetName()
			actionButton.spellCooldown = name and _G[name .. 'Cooldown'] or actionButton.cooldown -- catches more things.
			actionButton.auraCooldown = CreateFrame('Cooldown', nil, actionButton, 'CooldownFrameTemplate')
			actionButton.auraCooldown:SetAllPoints(actionButton.icon)
			actionButton.auraCooldown.statusGlow = actionButton.auraCooldown:CreateTexture(nil, 'OVERLAY', 2)
			actionButton.auraCooldown.statusGlow:SetAllPoints(actionButton.icon)
			actionButton.auraCooldown.statusGlow:SetAtlas("bags-glow-white")

			--never show both cooldown textures at the same time.
			actionButton.auraCooldown:SetScript("OnShow", function()
				actionButton.spellCooldown:Hide()
			end)

			actionButton.auraCooldown:SetScript("OnHide", function()
				actionButton.spellCooldown:Show()
			end)
			
			actionButton.spellCooldown:SetScript("OnShow", function()
				if actionButton.auraCooldown:IsShown() then
					actionButton.spellCooldown:Hide()
				end
			end)
		end
	end
	
	if actionAura:Get("coloredBorderShow") == true then
		actionButton.auraCooldown.statusGlow:SetVertexColor(unpack(auraColor[filter or ""]))
	else
		actionButton.auraCooldown.statusGlow:SetVertexColor(0,0,0,0)
	end
	
	actionButton.auraCooldown:SetCooldown(expireTime - duration, duration)
end

function actionAura:UpdateActionAura(actionButton)
	local auraName, filter, auraExpireTime, auraDuration, spellStart, spellDuration = self:GetAuraName(actionButton)

	local hasAuraTimer = auraName and auraExpireTime
	local auraLongerThanCooldown = hasAuraTimer and auraExpireTime > spellStart + spellDuration
	
	if hasAuraTimer and ((actionAura:Get("prioritizeAura") == true) or auraLongerThanCooldown)  then
		self:SetAuraCooldown(actionButton, filter, auraExpireTime, auraDuration)
	elseif actionButton.auraCooldown and actionButton.auraCooldown:IsShown() then
		actionButton.auraCooldown:SetCooldown(0, 0)
		actionButton.auraCooldown:Hide()
	end
end

function actionAura:OnInitialize()
	if not self.eventHandler then
		self:RegisterVariables(reset)

		hooksecurefunc("ActionButton_UpdateCooldown", function(actionButton)
			self:UpdateActionAura(actionButton)
		end)
		
		if CooldownFrame_Set then
			--Bartender4 Support
			hooksecurefunc("CooldownFrame_Set", function(cd)
				self:UpdateActionAura(cd:GetParent())
			end)
		end

		--the following is for fringe cases
		self.eventHandler = CreateFrame("Frame")
		self.eventHandler:RegisterEvent("PET_BAR_UPDATE_USABLE")
		self.eventHandler:RegisterEvent("PET_UI_UPDATE")
		self.eventHandler:RegisterEvent("UNIT_AURA")
		self.eventHandler:RegisterEvent("UNIT_COMBAT")
		self.eventHandler:RegisterEvent("UNIT_PET")
		self.eventHandler:RegisterEvent("UNIT_SPELLCAST_SENT")
		self.eventHandler:RegisterEvent("UNIT_ENTERED_VEHICLE")
		self.eventHandler:RegisterEvent("UNIT_HEALTH")
		self.eventHandler:RegisterEvent("UNIT_TARGET")
		self.eventHandler:RegisterEvent("PLAYER_FOCUS_CHANGED")

		self.eventHandler:SetScript("OnEvent", function()
			for _, button in pairs(self.buttonRegistry) do
				self:UpdateActionAura(button)
			end
		end)
	end
end

do --settings access
	
	actionAura.defaults = {
		translations = {
			["Entangling Roots"] = {"Mass Entanglement"},

		},
		personalAurasOnly == true,
		coloredBorderShow = true,
		filterOverride = {
			buff = {},
			debuff = {
				"Force of Nature"
			},
		}
	}

	function actionAura:RegisterVariables(reset)
		if reset == true then
			_G[variables] = nil
		end
		_G[variables] = _G[variables] or {}
		if self.defaults then
			for key, value in pairs(self.defaults) do
				_G[variables][key] = _G[variables][key] or value
			end
		end
	end

	function actionAura:Get(key, ...)
		if ... then
			--not yet working
			local setting = _G[variables][key]
			for _, key in pairs({...}) do
				if type(setting) == "table" then
					setting = setting[key]
				elseif not setting[key] then
					setting = nil
					break
				else
					setting = setting[key]
				end
			end
			
			if self.defaults and not setting then
				setting = self.defaults[key]
				for _, key in pairs({...}) do
					if type(setting) == "table" then
						setting = setting[key]
					elseif not setting[key] then
						setting = nil
						break
					else
						setting = setting[key]
					end
				end
			end
			return setting
		else
			return _G[variables][key] or self.defaults and self.defaults[key]
		end
	end

	function actionAura:Set(key, value)
		_G[variables][key] = value
	end

	function actionAura:Reset()
		self:RegisterVariables(true)
	end
end

function actionAura:AddTranslation(spellName, translation)
	_G[variables].translations[spellName] = _G[variables].translations[spellName] or {}
	if translation then
		if not tContains(_G[variables].translations[spellName], translation) then
			tinsert(_G[variables].translations[spellName], translation)
		end
	end
end

local optionItems = {}

function optionItems.advEditBox(parent, title)
	local button = CreateFrame("Frame", AddonName..title.."Button", parent, "TooltipBorderedFrameTemplate")
	button:SetHeight(25)

	button.edit = CreateFrame("Button", AddonName..title.."ButtonEdit", button)
		button.edit:SetSize(15, 15)
		button.edit:SetPoint("Right", -5, 0)
		button.edit:SetPushedAtlas("NPE_ArrowDown")
		button.edit:SetNormalAtlas("NPE_ArrowDownGlow")
		button.edit:SetHighlightAtlas("bags-glow-artifact")

	button.text = CreateFrame("EditBox", AddonName..title.."ButtonText", button, "InputBoxScriptTemplate")
		button.text:SetHeight(15)
		button.text:SetAutoFocus(false)
		button.text:SetTextColor(1,1,1,1)
		button.text:SetHighlightColor(.5,1,.5)
		button.text:SetFontObject("GameFontNormal")
		button.text:SetPoint("Left", 5, 0)
		button.text:SetPoint("Right", button.edit, "Left", 0, 0)

		button.text.high = button.text:CreateTexture(nil, 'HIGHLIGHT', 2)
		button.text.high:SetAllPoints(button.text)
		button.text.high:SetPoint("TopLeft", 0, 1)
		button.text.high:SetPoint("BottomRight", 0, -1)
		button.text.high:SetAtlas("soulbinds_collection_entry_highlight")
		button.text:SetHitRectInsets(-5, -15, -5, -5)

	return button
end

function optionItems.DropDown(parent, title)
	local button = CreateFrame("Frame", AddonName..title.."DropDown", parent, "TooltipBorderedFrameTemplate")
	button:SetHeight(25)

	button.edit = CreateFrame("Button", AddonName..title.."ButtonEdit", button)
		button.edit:SetSize(15, 15)
		button.edit:SetPoint("Right", -5, 0)
		button.edit:SetPushedAtlas("NPE_ArrowDown")
		button.edit:SetNormalAtlas("NPE_ArrowDownGlow")
		button.edit:SetHighlightAtlas("bags-glow-artifact")

	button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		button.text:SetTextColor(1,1,1,1)
		button.text:SetPoint("Left", 5, 0)
		button.text:SetPoint("Right", button.edit, "Left", 0, 0)

		button.high = button:CreateTexture(nil, 'HIGHLIGHT', 2)
		button.high:SetAllPoints(button.text)
		button.high:SetPoint("TopLeft", button.text, 0, 1)
		button.high:SetPoint("BottomRight", button.text, 0, -1)
		button.high:SetAtlas("soulbinds_collection_entry_highlight")
		--button:SetHitRectInsets(-5, -15, -5, -5)
	
	button:EnableMouse(true)
	
	return button
end

function optionItems.CheckButton(parent, optionDetails)
	local checkButton = CreateFrame("CheckButton", parent:GetName()..optionDetails.title, parent, "UICheckButtonTemplate")
	checkButton.text:SetText(optionDetails.title)
	checkButton.text:SetFont(checkButton.text:GetFont(), 12) --don't want to change font, just size.

	checkButton:SetHitRectInsets(0, -checkButton.text:GetWidth(), 0, 0)

	checkButton:SetScript("OnClick", optionDetails.OnClick)
	checkButton:SetScript("OnShow", optionDetails.OnShow)
	optionDetails.OnShow(checkButton)

	if optionDetails.tooltip then
		checkButton:SetScript("OnEnter",  function()
			GameTooltip:SetOwner(checkButton.text, "ANCHOR_RIGHT")
			GameTooltip:SetText(optionDetails.tooltip)
			GameTooltip:Show()
		end)

		checkButton:SetScript("OnLeave",  function()
			GameTooltip:Hide()
		end)
	end

	return checkButton
end

function optionItems.Slider(parent, optionDetails)
	local contain = CreateFrame("Frame", nil, parent)
	contain:SetSize(parent:GetWidth(), 20)

	local slider = CreateFrame("Slider", parent:GetName()..optionDetails.title, contain, "HorizontalSliderTemplate")
	
	slider.Title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	slider.Title:SetPoint("Left", contain, 3, 0)
	slider.Title:SetJustifyH("Left")		
	slider.Title:SetText(optionDetails.title)
	
	if optionDetails.tooltip then
		slider:SetScript("OnEnter",  function()
			GameTooltip:SetOwner(slider.Title, "ANCHOR_RIGHT")
			GameTooltip:SetText(optionDetails.tooltip)
			GameTooltip:Show()
		end)

		slider:SetScript("OnLeave",  function()
			GameTooltip:Hide()
		end)
	end
	
	slider.Value = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	slider.Value:SetPoint("Right", contain, -3, 0)
	slider.Value:SetJustifyH("Right")		
	slider.Value:SetText(" ")
	slider.Value:SetWidth(25)
	
	slider:SetSize(150, 15)
	
	slider:SetPoint("TopLeft", slider.Title, "TopRight", 2, 0)
	slider:SetPoint("TopRight", slider.Value, "TopLeft", -2, 0)
	
	slider:SetMinMaxValues(optionDetails.min or 1, optionDetails.max or 200)
	
	slider:SetScript("OnValueChanged", function(self)
		optionDetails.OnValueChanged(slider)
		slider.Value:SetText(self:GetValue())
	
	end)
	slider:SetScript("OnShow", optionDetails.OnShow)
	
	slider:SetValueStep(optionDetails.step or 1)
	
	slider:SetScript("OnMouseWheel", function(_, delta) slider:SetValue(slider:GetValue() + (delta * slider:GetValueStep())) end)
	
	slider:SetObeyStepOnDrag(true)
	
	optionDetails.OnShow(slider)


	return contain
end

function optionItems.Button(parent, optionDetails)
	local button = CreateFrame("Button", nil, parent, "UIMenuButtonStretchTemplate")
	button:SetSize(parent:GetWidth(), 25)
	
	button.Text:SetText(optionDetails.title)
	
	button:SetScript("OnClick", optionDetails.OnClick)

	return button
end

function optionItems.Page(parent, optionInfo)
	optionInfo.panel = CreateFrame("Frame", parent:GetName().."_"..optionInfo.name, parent)

	optionInfo.panel:SetSize(parent:GetWidth()-10, 250)
	optionInfo.panel:SetPoint("TopLeft", parent, (#parent.optionPanels == 0) and 0 or (300 *  #parent.optionPanels), -3)
	local yBase, yOffset = optionInfo.panel:GetBottom()
	
	local panelCount = #parent.optionPanels
	
	optionInfo.panel.New = {}
	for i, b in pairs(optionItems) do
		if i ~= Page then
			optionInfo.panel.New[i] = function(optionDetails)
				return b(optionInfo.panel, optionDetails)
			end
		end
	end
	
	if optionInfo.options then
		optionInfo.panel.Items = {}
		for i, optionDetails in pairs(optionInfo.options) do
			local item = optionInfo.panel.New[optionDetails.kind]
			if item then
				local object = item(optionDetails)
			
				object:SetPoint("TopLeft", 0, -5 -(#optionInfo.panel.Items * 30) )
				
				yOffset = object:GetBottom()
				
				tinsert(optionInfo.panel.Items, object)
			end
		end

	end
	if #parent.optionPanels < 1 then
		parent.PageTitle:SetText(optionInfo.name)
	end

	tinsert(parent.optionPanels, optionInfo)
	
	if yBase and yOffset and ((yBase - yOffset) > 0) then
		local range = (yBase - yOffset) + 8
	
		optionInfo.panel:SetSize(parent:GetWidth()-10, 250 + range)
	
		local scroll = 0
		optionInfo.panel:SetScript("OnMouseWheel", function(_, delta)
			scroll = scroll - (delta*20)
			scroll = max(0, min(range, scroll))
			--optionInfo.panel:SetPoint("TopLeft")
			optionInfo.panel:SetPoint("TopLeft", parent, (panelCount == 0) and 0 or (190 *  panelCount), (-3) + scroll)
		end)
	end
	
	parent.PageIndex:SetText(1 .."/".. #parent.optionPanels)
	
	return optionInfo.panel
end

local function GetSpellNameFromLink(linkText)
	if linkText:match(":(%d+)") then --it is a link of some sort
		if strfind(linkText, "spell:", 1, true) then
			-- it is a spell link
			linkText = GetSpellInfo(tonumber(linkText:match("spell:(%d+)")))
		else
			--it is not a spell link, don't allow it
			linkText = nil
		end
	end
	return linkText
end

local function SetActiveEditBox(editBox, oEditBox)
	local text = GetSpellNameFromLink(editBox:GetText())

	if text == nil then
		ACTIVE_CHAT_EDIT_BOX = self.Original.text
	else
		local text = GetSpellNameFromLink(oEditBox:GetText())
		if text == nil then
			ACTIVE_CHAT_EDIT_BOX = self.Translation.text
		else
			ACTIVE_CHAT_EDIT_BOX = nil
		end
	end
end

function actionAura:ShowTranslationPanel()
	if not self.optionsPanel then
		self.optionsPanel = CreateFrame("Frame", AddonName.."optionsPanel", UIParent, "TooltipBorderedFrameTemplate"); do
			self.optionsPanel:SetSize(300, 300)
			self.optionsPanel:SetPoint("Center")
			self.optionsPanel:SetMovable(true)
			self.optionsPanel:SetScript("OnMouseDown", self.optionsPanel.StartMoving)
			self.optionsPanel:SetScript("OnMouseUp", self.optionsPanel.StopMovingOrSizing)

			local title = self.optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			title:SetPoint("TopLeft", 5, -5)
			title:SetText("Action Aura")

			local closeButton = CreateFrame("Button", nil, self.optionsPanel, "UIPanelCloseButton")
			closeButton:SetPoint("TopRight", 2, 2)
			closeButton:SetScale(.8)
			closeButton:SetScript("OnClick", function() self.optionsPanel:Hide() end)
		end
		local h = 23

		local PageContainer = CreateFrame("ScrollFrame", self.optionsPanel:GetName().."_ScrollPanel", self.optionsPanel); do
			PageContainer:SetPoint("TopLeft", self.optionsPanel, 10, -(27+18 +3))
			PageContainer:SetPoint("BottomRight", self.optionsPanel, -10, 10)
		end
		
		local PageAnchor = CreateFrame("Frame", self.optionsPanel:GetName().."_Container", PageContainer); do
			PageAnchor:SetPoint("TopLeft")
			PageAnchor:SetSize(300, 300)
			PageContainer:SetScrollChild(PageAnchor)
		end
		
		local pageButton = CreateFrame("Frame", nil, self.optionsPanel, "TooltipBorderedFrameTemplate"); do
			pageButton:SetHeight(h)
			pageButton:SetPoint("TopLeft", (h + 2), -27)
			pageButton:SetPoint("TopRight", -(h + 2), -27)
			pageButton:EnableMouse(true)
			
			pageButton.high = pageButton:CreateTexture(nil, 'OVERLAY', 2)
			pageButton.high:SetPoint("TopLeft", 4, -4)
			pageButton.high:SetPoint("BottomRight", -4, 3)
			pageButton.high:SetAtlas("soulbinds_collection_entry_highlight")
			pageButton.high:Hide()
			
			pageButton:SetScript("OnEnter", function()
				pageButton.high:Show()
			end)
			
			pageButton:SetScript("OnLeave", function()
				pageButton.high:Hide()
			end)
			
		end
		
		local PageIndex = pageButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		PageIndex:SetPoint("Right", -5, 0)
		
		local PageTitle = pageButton:CreateFontString(nil, "ARTWORK", "GameFontNormal"); do
			PageTitle:SetPoint("Left", 5, 0)
			PageTitle:SetPoint("Right", PageIndex, "Left", -3, 0)
			PageTitle:SetJustifyH("LEFT") 
		end

		local LeftArrow = CreateFrame("Button", nil, pageButton); do
			LeftArrow:SetSize(h-6, h-3)
			LeftArrow:RegisterForClicks("AnyUp")
			LeftArrow:SetPoint("Right", pageButton, "Left", 0, 0)

			LeftArrow:SetHitRectInsets(0, -pageButton:GetWidth()/2, -1.5, -1.5)

			LeftArrow:SetHighlightTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow-Highlight")
			LeftArrow:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow-Pushed")
			LeftArrow:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow")
			LeftArrow:GetHighlightTexture():SetBlendMode("ADD")

			LeftArrow:GetNormalTexture():SetVertexColor(1,1,1, 1)
			LeftArrow:GetPushedTexture():SetVertexColor(1,1,1, 1)
			LeftArrow:GetHighlightTexture():SetVertexColor(1,1,1, 1)
			
			LeftArrow:SetScript("OnClick", function()
				pageButton:GetScript("OnMouseWheel")(pageButton, 1)
			end)
			
			LeftArrow:SetScript("OnEnter", function()
				pageButton.high:Show()
			end)
			
			LeftArrow:SetScript("OnLeave", function()
				pageButton.high:Hide()
			end)
			
			LeftArrow:Hide()
		end
		
		local RightArrow = CreateFrame("Button", nil, pageButton); do
			RightArrow:SetSize(h-6, h-3)
			RightArrow:RegisterForClicks("AnyUp")
			RightArrow:SetPoint("Left", pageButton, "Right", 0, 0)

			RightArrow:SetHitRectInsets(-pageButton:GetWidth()/2, 0, -1.5, -1.5)

			RightArrow:SetHighlightTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow-Highlight")
			RightArrow:SetPushedTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow-Pushed")
			RightArrow:SetNormalTexture("Interface\\AddOns\\"..AddonName.."\\artwork\\LeftArrow")
			RightArrow:GetHighlightTexture():SetBlendMode("ADD")
			
			RightArrow:GetHighlightTexture():SetTexCoord(1,0,0,1)
			RightArrow:GetNormalTexture():SetTexCoord(1,0,0,1)
			RightArrow:GetPushedTexture():SetTexCoord(1,0,0,1)

			RightArrow:GetHighlightTexture():SetVertexColor(1,1,1, 1)
			RightArrow:GetNormalTexture():SetVertexColor(1,1,1, 1)
			RightArrow:GetPushedTexture():SetVertexColor(1,1,1, 1)
			
			RightArrow:SetScript("OnClick", function()
				pageButton:GetScript("OnMouseWheel")(pageButton, -1)
			end)
			
			RightArrow:SetScript("OnEnter", function()
				pageButton.high:Show()
			end)
			
			RightArrow:SetScript("OnLeave", function()
				pageButton.high:Hide()
			end)
			
		end

		local width = self.optionsPanel:GetWidth()
		
		PageAnchor.optionPanels = {}
		PageAnchor.PageTitle = PageTitle
		PageAnchor.PageIndex = PageIndex
		
		pageButton:SetScript("OnMouseWheel", function(_,delta)
			local _min = 0
			local  _max = (#PageAnchor.optionPanels - 1) * width
			local val = min(max(_min, PageContainer:GetHorizontalScroll() - (delta * width)), _max)
			local panel = floor(val/width) + 1
			PageTitle:SetText(PageAnchor.optionPanels[panel].name)
			PageContainer:SetHorizontalScroll(val)
			
			if val <= _min then
				LeftArrow:Hide()
			else
				LeftArrow:Show()
			end
			
			if val >= _max then
				RightArrow:Hide()
			else
				RightArrow:Show()
			end
			
			PageIndex:SetText(panel .."/".. #PageAnchor.optionPanels)
		end)

		self.optionsPanel.New = {}
		
		for i, b in pairs(optionItems) do
			self.optionsPanel.New[i] = function(optionDetails)
				return b(PageAnchor, optionDetails)
			end
		end

		local options = {
				{
					title = "Show Colored Borders",
					tooltip = "Red glow is for debuffs, Green glow is for buffs.",
					kind = "CheckButton",
					OnShow = function(self)
						self:SetChecked(actionAura:Get("coloredBorderShow"))
					end,
					OnClick = function(self)
						actionAura:Set("coloredBorderShow", self:GetChecked())
					end,
				},
				{
					title = "Show Personal Only",
					tooltip = "Ignore buffs and debuffs that you CAN cast, but weren't cast by you.",
					kind = "CheckButton",
					OnShow = function(self)
						self:SetChecked(actionAura:Get("personalAurasOnly"))
					end,
					OnClick = function(self)
						actionAura:Set("personalAurasOnly", self:GetChecked())
					end,
				},
				{
					title = "Prioritize Aura Timer",
					tooltip = "Always show aura timer, even if the spell cooldown is longer.",
					kind = "CheckButton",
					OnShow = function(self)
						self:SetChecked(actionAura:Get("prioritizeAura"))
					end,
					OnClick = function(self)
						actionAura:Set("prioritizeAura", self:GetChecked())
					end,
				},
			}
			for i, unitTarget in pairs(actionAura.units) do
				tinsert(options, {
					title = "Ignore ".. unitTarget .." buffs",
					tooltip = "Ignore Buffs for ".. unitTarget ..".",
					kind = "CheckButton",
					OnShow = function(self)
						self:SetChecked(actionAura:Get("ignoreHelp_"..unitTarget))
					end,
					OnClick = function(self)
						actionAura:Set("ignoreHelp_"..unitTarget, self:GetChecked())
					end,
				})
				tinsert(options, {
					title = "Ignore ".. unitTarget .." debuffs",
					tooltip = "Ignore Debuffs for ".. unitTarget ..".",
					kind = "CheckButton",
					OnShow = function(self)
						self:SetChecked(actionAura:Get("ignoreHarm_"..unitTarget))
					end,
					OnClick = function(self)
						actionAura:Set("ignoreHarm_"..unitTarget, self:GetChecked())
					end,
				})

			end
		local basic = self.optionsPanel.New.Page({
			name = "Basic",
			options = options,
		})
		
		local transPanel = self.optionsPanel.New.Page({name = "Translations",}); do
			local topX = 0

			local t = transPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			t:SetPoint("TopLeft", 5, topX - 5)
			t:SetText("Original:")

			local u = transPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			u:SetPoint("TopLeft", 5, -30)
			u:SetText("Translation:")

			self.Original = transPanel.New.advEditBox("TransPanelOriginalSpell")
			self.Original:SetHeight(25)
			self.Original:SetPoint("Left", t, "Right", 3, 0)
			self.Original:SetPoint("TopRight", -30, topX)


			self.delete = CreateFrame("Button", AddonName.."DeleteEntry", transPanel)
			self.delete:SetSize(15, 15)
			self.delete:SetPoint("Left", self.Original,"Right")

			self.delete:SetHighlightAtlas("bags-glow-artifact")
			self.delete:SetNormalAtlas("BackupPet-DeadFrame")
			self.delete:SetPushedAtlas("BattleBar-SwapPetFrame-DeadIcon")
			self.delete:SetDisabledAtlas("Objective-Fail")
			self.delete:GetDisabledTexture():SetDesaturated(true)

			self.delete:Disable()

			self.delete:SetScript("OnEnter",  function()
				GameTooltip:SetOwner(self.delete, "ANCHOR_RIGHT")
				GameTooltip:SetText("Click to delete all entries for this spell.")
				GameTooltip:Show()
			end)


			self.delete:SetScript("OnLeave",  function()
				GameTooltip:Hide()
			end)

			self.Translation = transPanel.New.advEditBox("TransPanelOriginalSpell")
			self.Translation:SetHeight(25)
			self.Translation:SetPoint("TopLeft", self.Original, "BottomLeft", 20, 0)
			self.Translation:SetPoint("TopRight", -15, topX - 25)
			--self.Translation:SetPoint("TopRight", self.Original, "BottomRight", 0, 0)


			transPanel.Original = self.Original
			transPanel.Translation = self.Translation

			transPanel:SetScript("OnHide", function(_, delta)
				transPanel:Show()
			end)
			self.Translation.edit:SetNormalAtlas("bags-icon-addslots")

			local line = transPanel:CreateLine(nil, 'ARTWORK', 1)
			line:SetThickness(2)
			line:SetStartPoint("TopLeft", 0, -53 + topX)
			line:SetEndPoint("TopRight", 0, -53 + topX)

			line:SetColorTexture(.8,.8,.8,.4)

			local s = transPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			s:SetPoint("Top", line, "Bottom", 0, -5)
			s:SetText("Translations")

			local buttons = {}
			local displayOffset = 0

			local slide = CreateFrame("Slider", transPanel:GetName().."Scroll", transPanel, "HorizontalSliderTemplate")

			slide:Hide()
			slide:SetWidth(18)
			slide:ClearAllPoints()
			slide:SetPoint("Top", 0, -65 + topX)
			slide:SetPoint("BottomRight", -8, 3)
			slide:SetOrientation("VERTICAL")

			slide:SetScript("OnMouseWheel", function(_, delta)
				slide:SetValue(floor(slide:GetValue()-delta))
			end)

			transPanel:SetScript("OnMouseWheel", function(_, delta)
				slide:SetValue(floor(slide:GetValue()-delta))
			end)

			local numButtons = 7

			local wi, he = transPanel:GetSize()

			local h = (he - (83 - topX))/numButtons


			local w = (wi - 10)

			self.Translation.text:SetScript("OnTextChanged", function()
				local text = GetSpellNameFromLink(self.Translation.text:GetText())
				
				local _ = text ~= self.Translation.text:GetText() and self.Translation.text:SetText(text)

				if not self.Translation.text:HasFocus() then
					self.Translation.text:SetFocus()
				end
			end)

			local CurrentTranslationList
			local lastSpell
			local function RegisterNew(spellName, translation)
				if spellName and spellName ~= "" then
					actionAura:AddTranslation(spellName or lastSpell, translation)
					lastSpell = spellName or lastSpell
					local translations = _G[variables].translations[spellName]
					CurrentTranslationList = translations
				end
				if CurrentTranslationList then
					local oWidth = wi - 33
					if #CurrentTranslationList > numButtons then
						slide:Enable()
						local v = slide:GetValue()
						slide:SetMinMaxValues(0, #CurrentTranslationList - numButtons)

						if (not v) or (v == 0) or v > #CurrentTranslationList - numButtons then
							slide:SetValue(0)
						end
						slide:Show()
						oWidth = wi - 33
					else
					
						slide:SetMinMaxValues(0, 0)
						slide:Hide()
						oWidth = wi - 15
					end

					for i = 1, numButtons do
						local b = buttons[i]
						b:SetWidth(oWidth)
						b.text:ClearFocus()
						if CurrentTranslationList[i + displayOffset] then
							b:Show()
							b.text:SetText(CurrentTranslationList[i + displayOffset])
							b.text:SetCursorPosition(0)
						else
							b:Hide()
							b.text:SetText("")
						end
					end

				else
					for i = 1, numButtons do
						local b = buttons[i]
						b:Hide()
					end
					self.delete:Disable()

				end
			end
			slide.stepSize = 1
			transPanel.stepSize = 1
			transPanel.min = 0
			transPanel.stepSize = 1


			self.Original.text:SetScript("OnTextChanged", function()
				local text = GetSpellNameFromLink(self.Original.text:GetText())

				
				if text and text ~= "" and GetSpellInfo(text) then
					local _ = text ~= self.Original.text:GetText() and (self.Original.text:SetText(text) == nil and self.Translation.text:SetFocus())
					RegisterNew(text)
					if _G[variables].translations[text] then
						self.delete:Enable()
					else
						self.delete:Disable()
					end
				else
					if text ~= self.Original.text:GetText() then
						self.Original.text:SetText(text)
					end

					for i = 1, numButtons do
						local b = buttons[i]
						b:Hide()
					end

					slide:Hide()

					self.delete:Disable()
				end
			end)

			slide:SetScript("OnValueChanged", function()
				displayOffset = floor(slide:GetValue())
				RegisterNew()
			end)

			self.delete:SetScript("OnClick", function()

				local text = self.Original.text:GetText()

				if text:match(":(%d+)") then --it is a link of some sort
					if strfind(text, "spell:", 1, true) then
						-- it is a spell link
						text = GetSpellInfo(tonumber(text:match("spell:(%d+)")))
					else
						--it is not a spell link, don't allow it
						text = nil
					end
				end


				if text and text ~= "" then
					if _G[variables].translations[text] then
						_G[variables].translations[text] = nil
						RegisterNew("")
						self.Original.text:SetText("")
					end
				else
					RegisterNew("")
				end
			end)


			for i = 1, numButtons do
				buttons[i] = transPanel.New.advEditBox("Button"..i)
				buttons[i]:SetSize(w, h)
				buttons[i]:SetPoint("TopLeft", 5, -(70 - topX) - ((h * (i - 1))))

				buttons[i].edit:SetPushedAtlas("BackupPet-DeadFrame")
				buttons[i].edit:SetNormalAtlas("BattleBar-SwapPetFrame-DeadIcon")

				buttons[i].edit:SetScript("OnClick", function()
					tremove(CurrentTranslationList, i + displayOffset)
					RegisterNew()
				end)

				buttons[i].text:SetScript("OnEnterPressed", function()
					CurrentTranslationList[i + displayOffset] = buttons[i].text:GetText()
					buttons[i].text:ClearFocus()
					buttons[i].text:SetCursorPosition(0)
				end)

				buttons[i].text:SetScript("OnEditFocusLost", function()
					buttons[i].text:SetText(CurrentTranslationList[i + displayOffset] or "")
				end)

				buttons[i]:Hide()
			end

			self.Original.text:SetScript("OnEditFocusGained", function()
				self.Original.text:HighlightText()
				ACTIVE_CHAT_EDIT_BOX = self.Original.text
			end)

			self.Original.text:SetScript("OnEditFocusLost", function()
				SetActiveEditBox(self.Original.text, self.Translation.text)
			end)

			self.Original.text:SetScript("OnEnterPressed", function()
				local text = GetSpellNameFromLink(self.Original.text:GetText())


				if text then
					RegisterNew(text)
					self.Original.text:SetText(text)
					self.Translation.text:SetFocus()
				else
					self.Original.text:SetText("")
					self.Original.text:ClearFocus()
				end
			end)

			self.Original.edit:SetScript("OnMouseDown", function()
				if not self.dropDown then
					self.dropDown = CreateFrame("Frame", AddonName.."DropDown", self.Original, "UIDropDownMenuTemplate")
					UIDropDownMenu_Initialize(self.dropDown, function(_, level, ...)
							UIDropDownMenu_AddButton({
								text = "Library",
								notCheckable = true,
								hasArrow = nil,
								isTitle = true,
								func = function()

								end,
							})
						for spellName, translations in pairs(_G[variables].translations) do
							UIDropDownMenu_AddButton({
								text = spellName,
								notCheckable = true,
								hasArrow = nil,
								func = function()
									self.Original.text:SetText(spellName)
									RegisterNew(spellName, nil)
								end,
							})
						end

					end, "MENU")
				end
				ToggleDropDownMenu(1, 1, self.dropDown, self.Original:GetName(), 0, 0)
			end)



			self.Translation.text:SetScript("OnEditFocusGained", function()
				self.Translation.text:HighlightText()
				ACTIVE_CHAT_EDIT_BOX = self.Translation.text
			end)

			self.Translation.text:SetScript("OnEditFocusLost", function()
				SetActiveEditBox(self.Original.text, self.Translation.text)
			end)

			self.Translation.text:SetScript("OnEnterPressed", function()
				if self.Original.text:GetText() ~= "" and self.Translation.text:GetText() ~= "" then
					local text = GetSpellNameFromLink(self.Translation.text:GetText())

					RegisterNew(self.Original.text:GetText(), text)
					self.Translation.text:SetText("")
				end
			end)

			self.Translation.edit:SetScript("OnClick", function()
				if self.Original.text:GetText() ~= "" and self.Translation.text:GetText() ~= "" then
					RegisterNew(self.Original.text:GetText(), self.Translation.text:GetText())
					self.Translation.text:SetText("")
				end
				self.Translation.text:ClearFocus()
			end)

			transPanel:SetScript("OnShow", function()
				self.Original.text:SetText("")
				self.Translation.text:SetText("")
			
				ACTIVE_CHAT_EDIT_BOX = self.Original.text
			end)

			transPanel:SetScript("OnHide", function()
				ACTIVE_CHAT_EDIT_BOX = nil
			end)
		end

		local override = self.optionsPanel.New.Page({name = "Overrides",}); do
			local t = override:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			t:SetPoint("TopLeft", 5, -5)
			t:SetText("Override Aura Type:")
			
			
			local Drop = override.New.DropDown("FilterType")
			Drop:SetHeight(25)
			Drop:SetPoint("Left", t, "Right", 3, 0)
			Drop:SetPoint("TopRight", -15, 0)
			
			Drop.text:SetText("Debuff")
			
			local u = override:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			u:SetPoint("TopLeft", 5, -30)
			u:SetText("Spell Name:")
			
			local spellName = override.New.advEditBox("overrideSpellName")
			spellName:SetHeight(25)
			spellName:SetPoint("TopLeft", u, "Right", 3, 11)
			spellName:SetPoint("TopRight", -15, 11)	

			spellName.edit:SetNormalAtlas("bags-icon-addslots")

			local ActiveFilter = "HARMFUL"





			local slide = CreateFrame("Slider", override:GetName().."Scroll", override, "HorizontalSliderTemplate")

			slide:Hide()
			slide:SetWidth(18)
			slide:ClearAllPoints()
			slide:SetPoint("Top", 0, -45 + 0)
			slide:SetPoint("BottomRight", -8, 5)
			slide:SetOrientation("VERTICAL")

			slide:SetScript("OnMouseWheel", function(_, delta)
				slide:SetValue(floor(slide:GetValue()-delta))
			end)

			override:SetScript("OnMouseWheel", function(_, delta)
				slide:SetValue(floor(slide:GetValue()-delta))
			end)

			local numButtons = 8

			local wi, he = override:GetSize()

			local h = (he - (60))/numButtons


			local w = (wi - 10)

			local buttons = {}
			local displayOffset = 0




			local CurrentTranslationList
			local lastSpell
			local function RegisterNew(spellName)
				local translations = _G[variables].filterOverride[string.lower(Drop.text:GetText())]
				CurrentTranslationList = translations
			
				if spellName and spellName ~= "" then
					if not tContains(translations, spellName) then
						tinsert(translations, spellName)
					end
				end
				if CurrentTranslationList then
					local oWidth = wi - 33
					if #CurrentTranslationList > numButtons then
						slide:Enable()
						local v = slide:GetValue()
						slide:SetMinMaxValues(0, #CurrentTranslationList - numButtons)

						if (not v) or (v == 0) or v > #CurrentTranslationList - numButtons then
							slide:SetValue(0)
						end
						slide:Show()
						oWidth = wi - 33
					else
						slide:SetMinMaxValues(0, 0)
						slide:Hide()
						oWidth = wi - 15
					end

					for i = 1, numButtons do
						local b = buttons[i]
						b:SetWidth(oWidth)
						b.text:ClearFocus()
						if CurrentTranslationList[i + displayOffset] then
							b:Show()
							b.text:SetText(CurrentTranslationList[i + displayOffset])
							b.text:SetCursorPosition(0)
						else
							b:Hide()
							b.text:SetText("")
						end
					end

				else
					for i = 1, numButtons do
						local b = buttons[i]
						b:Hide()
					end
					self.delete:Disable()

				end
			end
			slide.stepSize = 1



			slide:SetScript("OnValueChanged", function()
				displayOffset = floor(slide:GetValue())
				RegisterNew()
			end)


			for i = 1, numButtons do
				buttons[i] = override.New.advEditBox("Button"..i)
				buttons[i]:SetSize(w, h)
				buttons[i]:SetPoint("TopLeft", 5, -(50 - 0) - ((h * (i - 1))))

				buttons[i].edit:SetPushedAtlas("BackupPet-DeadFrame")
				buttons[i].edit:SetNormalAtlas("BattleBar-SwapPetFrame-DeadIcon")

				buttons[i].edit:SetScript("OnClick", function()
					tremove(CurrentTranslationList, i + displayOffset)
					RegisterNew()
				end)

				buttons[i].text:SetScript("OnEnterPressed", function()
					CurrentTranslationList[i + displayOffset] = buttons[i].text:GetText()
					buttons[i].text:ClearFocus()
					buttons[i].text:SetCursorPosition(0)
				end)

				buttons[i].text:SetScript("OnEditFocusLost", function()
					buttons[i].text:SetText(CurrentTranslationList[i + displayOffset] or "")
				end)

				buttons[i]:Hide()
			end







			local dropDown
			Drop.edit:SetScript("OnMouseDown", function()
				if not dropDown then
					dropDown = CreateFrame("Frame", AddonName.."DropDown2", Drop, "UIDropDownMenuTemplate")
					UIDropDownMenu_Initialize(dropDown, function(_, level, ...)
							UIDropDownMenu_AddButton({
								text = "Filter Types",
								notCheckable = true,
								hasArrow = nil,
								isTitle = true,

							})
							UIDropDownMenu_AddButton({
								text = "Buff",
								notCheckable = true,
								hasArrow = nil,
								func = function()
									Drop.text:SetText("Buff")
									RegisterNew()
								end,
							})
							UIDropDownMenu_AddButton({
								text = "Debuff",
								notCheckable = true,
								hasArrow = nil,
								func = function()
									Drop.text:SetText("Debuff")
									RegisterNew()
								end,
							})
						

					end, "MENU")
				end
				ToggleDropDownMenu(1, 1, dropDown, Drop:GetName(), 0, 0)
			end)


			spellName.text:SetScript("OnTextChanged", function()
				local text = GetSpellNameFromLink(spellName.text:GetText())
				
				local _ = text ~= spellName.text:GetText() and spellName.text:SetText(text)

				if not spellName.text:HasFocus() then
					spellName.text:SetFocus()
				end
			end)




			spellName.text:SetScript("OnEditFocusGained", function()
				spellName.text:HighlightText()
				ACTIVE_CHAT_EDIT_BOX = spellName.text
			end)

			spellName.text:SetScript("OnEditFocusLost", function()
				ACTIVE_CHAT_EDIT_BOX = nil
			end)

			spellName.text:SetScript("OnEnterPressed", function()
				if spellName.text:GetText() ~= "" then
					RegisterNew(GetSpellNameFromLink(spellName.text:GetText()))
					spellName.text:SetText("")
				end
			end)

			spellName.edit:SetScript("OnClick", function()
				if spellName.text:GetText() ~= "" then
					RegisterNew(GetSpellNameFromLink(spellName.text:GetText()))
					spellName.text:SetText("")
				end
				spellName.text:ClearFocus()
			end)



RegisterNew()


		end

	end

	self.optionsPanel:Show()
end

function actionAura:RunCommand(Cmd, ...)
	local cmdStrings = string.lower(Cmd)
	if string.find(cmdStrings, "reset", 1) then
		self:Reset()
	else
		actionAura:ShowTranslationPanel()
	end
end

SlashCmdList[string.upper(AddonName)] = function(Cmd, ...)
	actionAura:RunCommand(Cmd, ...)
end

_G["SLASH_".. string.upper(AddonName) .."1"] = "/aaura"
_G["SLASH_".. string.upper(AddonName) .."2"] = "/"..string.lower(AddonName)
