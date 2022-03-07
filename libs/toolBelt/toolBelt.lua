local toolbelt = LibStub:NewLibrary('toolbelt', 1)

if not toolbelt then return end

local AddonName = ...
local actionAura  = LibStub("AceAddon-3.0"):GetAddon(AddonName)

local function GetSpellNameFromLink(linkText)
	if linkText:match(":(%d+)") then --it is a link of some sort
	
		if strfind(linkText, "spell:", 1, true) then
			-- it is a spell link
			linkText = GetSpellInfo(tonumber(linkText:match("spell:(%d+)")))
		elseif strfind(linkText, "item:", 1, true) then
			linkText = GetItemSpell(tonumber(linkText:match("item:(%d+)")))
		elseif strfind(linkText, "summonmount:", 1, true) then
			local name, spellID, icon, isActive,
			isUsable, sourceType, isFavorite,
			isFactionSpecific, faction, shouldHideOnChar,
			isCollected, mountID = C_MountJournal.GetMountInfoByID(tonumber(linkText:match("summonmount:(%d+)")))
					
			linkText = spellID and GetSpellLink(spellID)
		elseif strfind(linkText, "battlepet:", 1, true) then
			local info = {string.split(":", linkText)}
			
			local speciesID, customName, level, xp,
			maxXp, displayID, isFavorite, name, icon,
			petType, creatureID, sourceText, description,
			isWild, canBattle, tradable, unique, obtainable = C_PetJournal.GetPetInfoByPetID(info[8])

			 linkText = name 
		else
			--it is not a spell link, don't allow it
			linkText = nil
		end
	end
		
	
	return linkText
end

local function forceLinkText(text)
	if not text then
		return
	end

	if ACTIVE_CHAT_EDIT_BOX then
		if ACTIVE_CHAT_EDIT_BOX == MacroFrameText then
			local item = strfind(text, "item:", 1, true) and GetItemInfo(text)
			text = item or GetSpellNameFromLink(text)
			
			local cursorPosition = MacroFrameText:GetCursorPosition();
			if (cursorPosition == 0 or strsub(MacroFrameText:GetText(), cursorPosition, cursorPosition) == "\n" ) then
				local slash = (item and GetItemSpell(text)) and SLASH_USE1 or (item and SLASH_EQUIP1) or SLASH_CAST1
				text = slash.." "..text
			else
				text = item or text
			end
		end
	
		ACTIVE_CHAT_EDIT_BOX:Insert(text)
		ACTIVE_CHAT_EDIT_BOX:ClearFocus()
		ACTIVE_CHAT_EDIT_BOX = nil
	end
end

toolbelt.AllItems = {
	editBox = {},
	dropDown = {},
	editDrop = {},
	check = {},
	slider = {},
	button = {},
	page = {},
	list = {},
	title = {},
	panel = {},
}

local CanLink, EnableLinks

local ActionLink = CreateFrame("Button", nil, UIParent, "TooltipBorderedFrameTemplate"); do

	ActionLink:SetBackdropColor(1,1,0,0)

	ActionLink:SetFrameStrata("TOOLTIP")

	local function GetActiveEditBox()
		for i, func in pairs(toolbelt.AllItems.slider) do
			local box = func()
			if box and box:HasFocus() and box:IsVisible() then
				ACTIVE_CHAT_EDIT_BOX = box
			end
		end
		return ACTIVE_CHAT_EDIT_BOX
	end

	function actionAura:CanLink()
		if actionAura.EnableLinks == true then
			for i, func in pairs(toolbelt.AllItems.slider) do
				local box = func()
				if box and MouseIsOver(box) then
				
					return [[|n Select Direct From Action Bars:|n     Click here, then click on an action button to quickly program a spell.]]
				end
			end
		end
		return ""
	end
	
	local currentMouseFocus, currentIndex
	function actionAura:ShowLink()
		if actionAura.EnableLinks ~= true then
			ActionLink:SetAlpha(0)
			ActionLink:EnableMouse(false)
			return
		end

		local newMouseFocus = GetMouseFocus()
		local newIndex = newMouseFocus and self:GetActionIndex(newMouseFocus)

		if newMouseFocus and (newMouseFocus ~= ActionLink) and newIndex then
			currentMouseFocus, currentIndex = newMouseFocus, newIndex
		end
		
		local active = GetActiveEditBox()
		if active and (currentMouseFocus and MouseIsOver(currentMouseFocus) and currentIndex) then
			ActionLink.showing = true
			ActionLink.action = currentIndex
			ActionLink:SetAlpha(1)
			ActionLink:EnableMouse(true)
			
				ActionLink:SetAllPoints(currentMouseFocus)

				actionAura:Ping(currentMouseFocus)

				local parent = currentMouseFocus:GetParent();
				if ( parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft ) then
					GameTooltip:SetOwner(ActionLink, "ANCHOR_LEFT");
				else
					GameTooltip:SetOwner(ActionLink, "ANCHOR_RIGHT");
				end
			if ( GameTooltip:SetAction(ActionLink.action) ) then
				GameTooltip:Show()

			end
			-- elseif currentMouseFocus:GetScript("OnEnter") then
				-- currentMouseFocus:GetScript("OnEnter")(ActionLink)
			-- end
			
		else
			if ActionLink.showing then
				ActionLink.showing = nil
				GameTooltip:Hide()
			end
			ActionLink:SetAlpha(0)
			ActionLink:EnableMouse(false)
			currentMouseFocus = nil
			ActionLink.action = nil
		end
	end

	ActionLink:SetScript("OnClick", function(self)
		if ActionLink.action then
			local spellName, link
			local actionType, actionID, subType, globalID = GetActionInfo(ActionLink.action)
			if actionType == 'spell' then
				if actionID and actionID > 0 then
					spellName, link = GetSpellInfo(actionID)
				elseif globalID then
					spellName, link = GetSpellInfo(globalID)
				end
				
				if spellName then
					spellName = GetSpellLink(spellName)
				end
			elseif actionType == 'item' then
				spellName, link = GetItemInfo(actionID)		
			elseif actionType == 'macro' then
				actionID = GetMacroSpell(actionID)
				if actionID then
					spellName, link = GetSpellInfo(actionID)
				end
				if spellName then
					spellName = GetSpellLink(spellName)
				end
			elseif actionType == "summonmount" then
				local name, spellID, icon, isActive,
				isUsable, sourceType, isFavorite,
				isFactionSpecific, faction, shouldHideOnChar,
				isCollected, mountID = C_MountJournal.GetMountInfoByID(actionID)
				spellName = name
				
				link = GetSpellLink(spellID)
			elseif actionType == "summonpet" then
				link = C_PetJournal.GetBattlePetLink(actionID)
			else
				--print(actionType, actionID, subType, globalID)
			end

			if spellName or link then
				forceLinkText(link or spellName)
			end
		end
		
	end)

	ActionLink:SetScript("OnUpdate", function(self)
		actionAura:ShowLink()
	end)
end

function toolbelt.advEditBox(parent, title, noShowTitle)
	local button = CreateFrame("Frame", parent:GetName()..title.."Button", parent.PageAnchor or parent, "TooltipBorderedFrameTemplate")
	button:SetHeight(25)

	if noShowTitle == nil then
		button.title = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		button.title:SetPoint("TopLeft", 5, 0)
		button.title:SetPoint("BottomLeft", 5, 0)
		
		button.title:SetJustifyH("Left")		
		button.title:SetJustifyV("Middle")		
		
		button.title:SetText(title..": ")
	end
	
	button.edit = CreateFrame("Button", parent:GetName()..title.."ButtonEdit", button); do
		button.edit:SetPoint("TopRight", -5, -5)
		button.edit:SetPoint("BottomRight", -5, 5)

		button.edit:SetPushedAtlas("NPE_ArrowDown")
		button.edit:SetNormalAtlas("NPE_ArrowDownGlow")
		button.edit:SetHighlightAtlas("bags-glow-artifact")
	end
	
	button.text = CreateFrame("EditBox", parent:GetName()..title.."ButtonText", button, "InputBoxScriptTemplate"); do
		button.text:SetHeight(15)
		button.text:SetAutoFocus(false)
		button.text:SetTextColor(1,1,1,1)
		button.text:SetHighlightColor(.5,1,.5)
		button.text:SetFontObject("GameFontNormal")
		button.text:SetPoint("TopLeft", button.title or button, button.title and "TopRight" or "TopLeft", 5, -5)
		button.text:SetPoint("BottomRight", button.edit, "BottomLeft", 0, 0)
		button.text:SetHitRectInsets(button.title and -button.title:GetWidth() - 5 or 0, -15, -5, -5)
		button.text.Insert = button.text.SetText
		
		button.text:SetScript("OnEscapePressed", function()
			button.text:ClearFocus()
			button.text:SetText(button.text.saveText or "")
		end)
		
	
		tinsert(toolbelt.AllItems.slider, function() return button.text end)
	end
	
	button.text.high = button.text:CreateTexture(nil, 'HIGHLIGHT', 2); do
		button.text.high:SetPoint("TopLeft", 0, 3)
		button.text.high:SetPoint("BottomRight", 0, -3)
		button.text.high:SetAtlas("soulbinds_collection_entry_highlight")
	end
			
	button:SetScript("OnSizeChanged", function()
		local w, h = button:GetSize()
		--Auto Scaling!
		button.edit:SetWidth(h - 10)
	end)

	button:EnableMouse(true)

	button.text:SetScript("OnEnter", function()
		if actionAura.HELP and button.tooltip then
			local text = button.tooltip..actionAura:CanLink()

			actionAura.HELP.Body:SetFormattedText(text)
		elseif actionAura.HELP then
			actionAura.HELP.Body:SetText("")
		end
	end)

	button.text:SetScript("OnLeave", function()
		if actionAura.HELP then
			actionAura.HELP.Body:SetText("")
		end
	end)
	
	button:SetScript("OnEnter", function()
		if actionAura.HELP and button.tooltip then
			local text = button.tooltip..actionAura:CanLink()

			actionAura.HELP.Body:SetFormattedText(text)
		elseif actionAura.HELP then
			actionAura.HELP.Body:SetText("")
		end
	end)

	button:SetScript("OnLeave", function()
		if actionAura.HELP then
			actionAura.HELP.Body:SetText("")
		end
	end)

	button.text:SetScript("OnTextChanged", function()
		local text = button.text:GetText()
		
		text = (text and GetSpellNameFromLink) and GetSpellNameFromLink(text) or text
		
		if text and text ~= button.text:GetText() then
			--if the text was formatted from a link, automatically add it to the list!
			button.text:SetText(text)
			
			--local _ = button.AddEntry and button.AddEntry(text)
			button.text:ClearFocus()
		end
	end)
	
	if parent.Items and not tContains(parent.Items, button) then
		tinsert(parent.Items, button)
	end
	
	return button
end

function toolbelt.DropDown(parent, title)
	local button = CreateFrame("Frame", parent:GetName()..title.."DropDown", parent.PageAnchor or parent, "TooltipBorderedFrameTemplate")
	button:SetHeight(25)

	button.title = button:CreateFontString(nil, "ARTWORK", "GameFontNormal"); do
		button.title:SetPoint("TopLeft", 5, 0)
		button.title:SetPoint("BottomLeft", 5, 0)
		
		button.title:SetJustifyH("Left")		
		button.title:SetJustifyV("Middle")		
		
		button.title:SetText(title..": ")
	end

	button.edit = CreateFrame("DropDownToggleButton", parent:GetName()..title.."ButtonEdit", button)
		
		button.edit:SetPoint("Top", 0, -5)
		button.edit:SetPoint("Right", -5, 0)
		button.edit:SetPoint("Bottom", 0, 5)
		
		button.edit:SetPushedAtlas("NPE_ArrowDown")
		button.edit:SetNormalAtlas("NPE_ArrowDownGlow")
		button.edit:SetHighlightAtlas("bags-glow-artifact")
		button.edit:GetHighlightTexture():SetAllPoints(button.edit)

		button.edit:SetScript("OnSizeChanged", function()
			button.edit:SetWidth(button.edit:GetHeight())
		end)

		tinsert(toolbelt.AllItems.dropDown, function() return button.edit end)

		button.tooltip = "Mouse-wheel or click the arrow to change options."
	
		button:SetScript("OnEnter", function()
			if actionAura.HELP and button.tooltip then
				actionAura.HELP.Body:SetText(button.tooltip)
			elseif actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)

		button:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)

	button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		button.text:SetTextColor(1,1,1,1)
		button.text:SetPoint("Top", button.title, "Top", 0, 0)
		button.text:SetPoint("Bottom", button.title, "Bottom", 0,0)
		
		button.text:SetPoint("Left", button.title, "Right", 5, 0)
		button.text:SetPoint("Right", button.edit, "Left", 0, 0)

		button.text:SetJustifyH("Center")		
		button.text:SetJustifyV("Middle")	
		
		button.high = button:CreateTexture(nil, 'HIGHLIGHT', 2)
		button.high:SetAllPoints(button.text)
		button.high:SetPoint("TopLeft", button, 0, -3)
		button.high:SetPoint("BottomRight", button, 0, 3)
		button.high:SetAtlas("soulbinds_collection_entry_highlight")
		--button:SetHitRectInsets(-5, -15, -5, -5)
	
		button.index = 1

	button:SetScript("OnShow", function()
		local _ = button.OnShow and button.OnShow()
	end)
	
	button:SetScript("OnMouseWheel", function(_, delta)
	
		local list = type(button.list) == "table" and button.list or type(button.list)=="function" and button.list()
		
		button.index = button.index + delta
		
		if button.index > #list then
			button.index = 1
		elseif button.index < 1 then
			button.index = #list
		end
		
		
		button.text:SetText(list[button.index])
		
		if button.SetValue then
			button.SetValue(list[button.index])
		else
			button.Update()
		end
		CloseDropDownMenus()
	end)

	button.edit:SetScript("OnMouseDown", function()
		button.edit.list = type(button.list) == "table" and button.list or type(button.list) == "function" and button.list()
	

			if UIDROPDOWNMENU_OPEN_MENU == button.edit then
				UIDROPDOWNMENU_OPEN_MENU = nil
				CloseDropDownMenus()
			else
				do
					local listFrameName = "DropDownList"..1;
					local listFrame = _G[listFrameName];
					UIDropDownMenu_ClearCustomFrames(listFrame);
					
					listFrame:Hide();
					
					UIDROPDOWNMENU_OPEN_MENU = button.edit
					listFrame:ClearAllPoints()
					
					-- Set the dropdownframe scale
					local uiScale;
					local uiParentScale = UIParent:GetScale();
					if ( GetCVar("useUIScale") == "1" ) then
						uiScale = tonumber(GetCVar("uiscale"));
						if ( uiParentScale < uiScale ) then
							uiScale = uiParentScale;
						end
					else
						uiScale = uiParentScale;
					end
					listFrame:SetScale(uiScale);
										
					listFrame:SetPoint("TopRight", button.edit, "BottomRight", 0, 0)
				
					_G[listFrameName.."Backdrop"]:Hide();
					_G[listFrameName.."MenuBackdrop"]:Show();
					
					UIDropDownMenu_Initialize(button.edit, function(_, level, ...)
						for i, b in pairs(button.edit.list) do
							UIDropDownMenu_AddButton({
								text = b,
								notCheckable = true,
								hasArrow = nil,
								func = function()
									button.index = tIndexOf(button.edit.list, b)
									button.text:SetText(b)
		
									if button.SetValue then
										button.SetValue(b)
									else
										button.Update()
									end
								end,
							})
						end
					end, nil, 1)
				
					listFrame:Show()
				end

				local _ = DropDownList1 and RegisterAutoHide(DropDownList1, 3)
				local _ = DropDownList1 and AddToAutoHide(DropDownList1, button.edit)
			end
		end)
	
	button:EnableMouse(true)

	if parent.Items and not tContains(parent.Items, button) then
		tinsert(parent.Items, button)
	end
	
	return button
end

function toolbelt.DropDownEditBox(parent, optionInfo)
	local button = CreateFrame("Frame", parent:GetName()..optionInfo.title.."DropDown", parent.PageAnchor or parent, "TooltipBorderedFrameTemplate")
	button:SetHeight(25)

	tinsert(toolbelt.AllItems.editDrop, function() return button end)
	
	button.skipper = optionInfo.skipper

	button.title = button:CreateFontString(nil, "ARTWORK", "GameFontNormal"); do
		button.title:SetPoint("TopLeft", 5, 0)
		button.title:SetPoint("BottomLeft", 5, 0)
		
		button.title:SetJustifyH("Left")		
		button.title:SetJustifyV("Middle")		
		
		button.title:SetText(optionInfo.title..": ")
	end

	button.edit = CreateFrame("Button", parent:GetName()..optionInfo.title.."ButtonEdit", button); do
		button.edit:SetPoint("Top", 0, -5)
		button.edit:SetPoint("Right", -5, 0)
		button.edit:SetPoint("Bottom", 0, 5)
		
		button.edit:SetPushedAtlas("NPE_ArrowDown")
		button.edit:SetNormalAtlas("NPE_ArrowDownGlow")
		button.edit:SetHighlightAtlas("bags-glow-artifact")
		button.edit:GetHighlightTexture():SetAllPoints(button.edit)

		button.edit:SetScript("OnSizeChanged", function()
			button.edit:SetWidth(button.edit:GetHeight())
		end)
	end

	button.text = CreateFrame("EditBox", parent:GetName()..optionInfo.title.."ButtonText", button, "InputBoxScriptTemplate"); do
		button.text:SetHeight(15)
		button.text:SetAutoFocus(false)
		button.text:SetTextColor(1,1,1,1)
		button.text:SetHighlightColor(.5,1,.5)
		button.text:SetFontObject("GameFontNormal")
		button.text:SetPoint("TopLeft", button.title, "TopRight", 0, -5)
		button.text:SetPoint("BottomRight", button.edit, "BottomLeft", 0, 0)
		
		button.text.Insert = button.text.SetText
		
		button.text:SetHitRectInsets(-button.title:GetWidth(), 0, 0, 0)
		
		tinsert(toolbelt.AllItems.slider, function() return button.text end)
		
		button.text:SetScript("OnEscapePressed", function()
			button.text:ClearFocus()
			if button.text.saveText then
				button.text:SetText(button.text.saveText)
			end
		end)
		
		button.text.high = button.text:CreateTexture(nil, 'HIGHLIGHT', 2); do
			button.text.high:SetPoint("TopLeft", button.text, 0, 3)
			button.text.high:SetPoint("BottomRight", button.text, 0, -3)
			button.text.high:SetAtlas("soulbinds_collection_entry_highlight")
		end
		
		button.text:SetScript("OnEnter", function()
			if actionAura.HELP and button.tooltip then
				local text = button.tooltip..actionAura:CanLink()
				actionAura.HELP.Body:SetFormattedText(text)
			elseif actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			
			end
		end)

		button.text:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)

		button:SetScript("OnEnter", function()
			if actionAura.HELP then
				if button.tooltip then
					actionAura.HELP.Body:SetText(button.tooltip)
				else
					actionAura.HELP.Body:SetText("")
				
				end
			end
		end)

		button:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)
	end

	button.index = 1

	button:SetScript("OnMouseWheel", function(_, delta)
		
		local list = type(button.list) == "table" and button.list or type(button.list)=="function" and button.list()
		
		button.index = button.index + delta
		
		if button.index > #list then
			button.index = 1
		elseif button.index < 1 then
			button.index = #list
		end
		
		
		button.text:SetText(list[button.index])
		
		button.Update(list[button.index])
		CloseDropDownMenus()
	end)

	button.edit:SetScript("OnMouseDown", function()
		button.edit.list = type(button.list) == "table" and button.list or type(button.list) == "function" and button.list()
	
			if UIDROPDOWNMENU_OPEN_MENU == button.edit then
				UIDROPDOWNMENU_OPEN_MENU = nil
				CloseDropDownMenus()
			else
				do
					local listFrameName = "DropDownList"..1;
					local listFrame = _G[listFrameName];
					UIDropDownMenu_ClearCustomFrames(listFrame);
					
					listFrame:Hide();
					
					UIDROPDOWNMENU_OPEN_MENU = button.edit
					listFrame:ClearAllPoints()
					
					-- Set the dropdownframe scale
					local uiScale;
					local uiParentScale = UIParent:GetScale();
					if ( GetCVar("useUIScale") == "1" ) then
						uiScale = tonumber(GetCVar("uiscale"));
						if ( uiParentScale < uiScale ) then
							uiScale = uiParentScale;
						end
					else
						uiScale = uiParentScale;
					end
					listFrame:SetScale(uiScale);
										
					listFrame:SetPoint("TopRight", button.edit, "BottomRight", 0, 0)
				
					_G[listFrameName.."Backdrop"]:Hide();
					_G[listFrameName.."MenuBackdrop"]:Show();
					
					UIDropDownMenu_Initialize(button.edit, function(_, level, ...)
						for i, b in pairs(button.edit.list) do
							UIDropDownMenu_AddButton({
								text = b,
								notCheckable = true,
								hasArrow = nil,
								func = function()
									button.index = tIndexOf(button.edit.list, b)
									button.text:SetText(b)
									button.Update(b)
								end,
							})
						end
					end, nil, 1)
				
					listFrame:Show()
				end
				
				local _ = DropDownList1 and DropDownList1:IsVisible() and RegisterAutoHide(DropDownList1, 3)
			--	local _ = DropDownList1 and DropDownList1:IsVisible() and AddToAutoHide(DropDownList1, button.edit)
			end
		end)
	


	button:EnableMouse(true)

	if optionInfo.allowDelete then
		button:SetPoint("Right", parent, "Right", -15, 0)
		
		button.delete = CreateFrame("Button", button:GetName().."Delete", button)
		button.delete:SetSize(15, 15)
		button.delete:SetPoint("Left", button, "Right", 0, 0)
		button.delete:SetPushedAtlas("BackupPet-DeadFrame")
		button.delete:SetNormalAtlas("BattleBar-SwapPetFrame-DeadIcon")
		button.delete:SetHighlightAtlas("bags-glow-artifact")

		button.delete:SetScript("OnClick", function()
			local _ = button.DeleteEntry and button.DeleteEntry(button.text:GetText())
			button.text:SetText("")
			local _ = button.update and button.update(button.text:GetText())
		end)
		
		button.tooltip = [[Click here first, then Shift-click on a spell in your spellbook to add it quickly. |nPress the Arrow to modify or add to an existing spell. |nClick the red "X" to delete all entries for this spell.]]
		
	else
		button.tooltip = [[Click here first, then Shift-click on a spell in your spellbook to add it quickly. |nPress the Arrow to modify or add to an existing spell.]]
		button:SetPoint("Right", parent, "Right", -10, 0)
	end
	
	if parent.Items and not tContains(parent.Items, button) then
		tinsert(parent.Items, button)
	end

	button.text:SetScript("OnTextChanged", function()
		local text = button.text:GetText()
		
		text = (text and GetSpellNameFromLink) and GetSpellNameFromLink(text) or text
		
		if text and text ~= button.text:GetText() then
			--if the text was formatted from a link, automatically add it to the list!
			button.text:SetText(text)
			
			local _ = button.AddEntry and button.AddEntry(text)
			button.text:ClearFocus()
		end
	end)

	button.text:SetScript("OnEditFocusGained", function()
		ACTIVE_CHAT_EDIT_BOX = button.text
		button.text:HighlightText()
		button.text.saveText = button.text:GetText()
	end)

	button.text:SetScript("OnEnterPressed", function()
		if button.text:GetText() ~= "" then
			local _ = button.AddEntry and button.AddEntry(button.text:GetText())
			button.text.saveText = nil
			button.text:ClearFocus()
		end
	end)
	
	button:SetScript("OnShow", function()
		local _ = button.OnShow and button.OnShow(button)
	end)

	return button
end

function toolbelt.CheckButton(parent, optionDetails)
	local checkButton = CreateFrame("CheckButton", parent:GetName()..optionDetails.title, parent.PageAnchor or parent, "UICheckButtonTemplate")
	checkButton.text:SetText(optionDetails.title)
	checkButton.text:SetFont(checkButton.text:GetFont(), 12) --don't want to change font, just size.

	tinsert(toolbelt.AllItems.check, function() return checkButton end)
	
	function checkButton:SetTarget(target)
		checkButton.target = target
	end

	checkButton:SetHitRectInsets(0, -checkButton.text:GetWidth(), 0, 0)

	checkButton:SetScript("OnClick", optionDetails.OnClick)
	checkButton:SetScript("OnShow", optionDetails.OnShow)
	checkButton.OnShow = optionDetails.OnShow
	
	optionDetails.OnShow(checkButton)
	checkButton.skipper = optionDetails.skipper
	if optionDetails.tooltip then
		checkButton:SetScript("OnEnter", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText(optionDetails.tooltip)
			end
		end)

		checkButton:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)
	end

	if parent.Items and not tContains(parent.Items, checkButton) then
		tinsert(parent.Items, checkButton)
	end

	checkButton.resize = checkButton.text

	return checkButton
end

function toolbelt.Slider(parent, optionDetails)
	local contain = CreateFrame("Frame", nil, parent.PageAnchor or parent)
	contain:SetSize(parent:GetWidth() - 20, 38)

	contain:SetPoint("Right", 0, 0)

	local slider = CreateFrame("Slider", parent:GetName()..optionDetails.title.."Slider", contain, "HorizontalSliderTemplate")
	tinsert(toolbelt.AllItems.slider, function() return slider end)
	slider:SetHitRectInsets(0, 0, 0, 0)
	
	contain.skipper = optionDetails.skipper
	
	slider.Title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	slider.Title:SetPoint("TopLeft", contain, 3, 0)
	slider.Title:SetPoint("Bottom", contain, "Center", 0, 0)
	slider.Title:SetJustifyH("Left")		
	slider.Title:SetText(optionDetails.title)
	
	if optionDetails.tooltip then
		slider:SetScript("OnEnter", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText(optionDetails.tooltip)
			end
		end)

		slider:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)
		contain:SetScript("OnEnter", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText(optionDetails.tooltip)
			end
		end)

		contain:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)
	end
	
	slider.Value = CreateFrame("EditBox", slider:GetName().."ButtonValue", contain, "InputBoxScriptTemplate"); do
		slider.Value:SetText(" ")
		slider.Value:SetWidth(35)
		slider.Value:SetHeight(15)
		slider.Value:SetAutoFocus(false)
		slider.Value:SetJustifyH("Right")
		slider.Value:SetTextColor(1,1,1,1)
		slider.Value:SetHighlightColor(.5,1,.5)
		slider.Value:SetFontObject("GameFontNormal")

		slider.Value.high = slider.Value:CreateTexture(nil, 'HIGHLIGHT', 2); do
			slider.Value.high:SetPoint("TopLeft", slider.Value, -4, 5)
			slider.Value.high:SetPoint("BottomRight", slider.Value, 4, -3)
			slider.Value.high:SetAtlas("worldstate-capturebar-neutralglow-bastionarmor")
			slider.Value.high:SetVertexColor(1,1,1,.6)
		end
		
		slider.Value.Insert = slider.Value.SetText

		slider.Value:SetScript("OnEditFocusGained", function()
			slider.saveValue = slider:GetValue()
			slider.Value:HighlightText()
			
			slider:SetScript("OnValueChanged", function(self)
				optionDetails.OnValueChanged(slider)
			end)
			
			slider.Value:SetScript("OnTextChanged", function()
				local text = slider.Value:GetText() or 0

				local low, high = slider:GetMinMaxValues()
				
				if low >= 0 and text and string.find(text, "-") then
					return slider.Value:SetText(gsub(text, "-", ""))
				end
		
				local num = tonumber(text)
				
				if not num then
					num = slider.Value.lastNum
				end
			
				local val = num
				
				local short = val and string.find(val, ".") and tonumber(string.sub(val, 1, 4)) or val
				
				short = short and max(low, min(short, high))
				
				if val ~= short then
					slider.Value:SetText(short)
				end
										
				if optionDetails.Absolute == true then
					
					local fVal = floor(short)
					
					if short ~= fVal then
						short = fVal
						slider.Value:SetText(short)
					end
				end
			
				short = tonumber(short)
			
				slider:SetValue(short or low)
				slider.Value.lastNum = short or slider.Value.lastNum
				
			end)
		end)
		slider.Value:SetScript("OnEditFocusLost", function()
			slider.Value:SetScript("OnTextChanged", function()
				local val = slider:GetValue()
				
				val = val and tonumber(string.format("%.2f", val)) or val
			
				if val ~= tonumber(slider.Value:GetText()) then
					slider.Value:SetText(val)
				end
			end)
			slider:SetScript("OnValueChanged", function(self)
				local val = slider:GetValue()
				
				val = val and tonumber(string.format("%2.f", val)) or val
			
				if val ~= slider:GetValue() then
					slider:SetValue(val)
				end
			
				optionDetails.OnValueChanged(slider)
				slider.Value:SetText(slider:GetValue())
			end)
		end)
		
		slider.Value:SetScript("OnTextChanged", function()
			local val = slider:GetValue()
			
			val = val and tonumber(string.format("%.2f", val)) or val
		
			if val ~= tonumber(slider.Value:GetText()) then
				slider.Value:SetText(val)
			end
		end)
			
		
		slider.Value:SetScript("OnEscapePressed", function()
			slider.Value:ClearFocus()
			if slider.saveValue then
				slider.Value:SetText(slider.saveValue)
				slider.saveValue = nil
			end
		end)	
		slider.Value:SetScript("OnEnterPressed", function()
			slider.Value:ClearFocus()
			slider.saveValue = nil
		end)

		if optionDetails.indicatorText then
			local ind = contain:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			ind:SetPoint("TopRight", -3, 0)
			ind:SetPoint("Bottom", contain, "Center", 0, 0)
			ind:SetJustifyH("RIGHT")
			ind:SetJustifyV("CENTER")
			ind:SetTextColor(1,1,1,1)
			ind:SetText("("..optionDetails.indicatorText..")")
			
			slider.Value.high:SetPoint("BottomRight", ind, 8, -3)
			
			slider.Value:SetHitRectInsets(0, -ind:GetWidth(), 0, 0)
			
			slider.Value:SetPoint("TopRight", ind, "TopLeft", -1, 0)
			slider.Value:SetPoint("Bottom", contain, "Center", 0, 0)
				
		else
			slider.Value:SetPoint("TopRight", contain, -3, 0)
		end

	end
	
	slider:SetPoint("Top", slider.Title, "Bottom", 0, 0)
	slider:SetPoint("Left")
	slider:SetPoint("Right")
	slider:SetPoint("Bottom", 0, 4)
	
	slider.high = slider:CreateLine(nil, 'OVERLAY', 2); do
		slider.high:SetThickness(3)
		slider.high:SetColorTexture(.2,.2,.8,.8)
		slider.high:SetStartPoint("Left", slider, 4, 1)
		slider.high:SetEndPoint("Right", slider, -4, 1)
		slider.Thumb:SetDrawLayer('OVERLAY', 3)
		slider.high:Hide()
		
		slider:SetScript("OnEnter", function() slider.high:Show() end)
		slider:SetScript("OnLeave", function() slider.high:Hide() end)
	end
	
	slider:SetMinMaxValues(optionDetails.min or 1, optionDetails.max or 200)
	
	slider:SetScript("OnValueChanged", function(self)
		local val = slider:GetValue()
		
		val = val and tonumber(string.format("%.2f", val)) or val
	
		if val ~= slider:GetValue() then
			slider:SetValue(val)
		end
	
		optionDetails.OnValueChanged(slider)
		slider.Value:SetText(slider:GetValue())
	end)
	slider:SetScript("OnShow", optionDetails.OnShow)
	
	function contain:SetTarget(target)
		slider.target = target
	end
	
	contain.OnShow = function()
	
		optionDetails.OnShow(slider)
	end
	
	slider:SetValueStep(optionDetails.step or 1)
	
	slider:SetScript("OnMouseWheel", function(_, delta)
		slider.Value:ClearFocus()
		local step
	
		if (IsShiftKeyDown() == true) and (optionDetails.Absolute ~= true) then
			step = .1
		else
			step = slider:GetValueStep() or 1

		end
		
		slider:SetValueStep(step)
					
		local val = slider:GetValue() + (delta * step)
	
		val = val and tonumber(string.format("%.2f", val)) or val
	
		slider:SetValue(val)
	end)
	
	if optionDetails.Absolute == true then
		slider:SetObeyStepOnDrag(true)
	end
	local _ = optionDetails.OnShow and optionDetails.OnShow(slider)

	if optionDetails.checkable then
		local check = CreateFrame("CheckButton", nil, contain)
		slider.check = check
		
		check:SetScript("OnClick", function()
			optionDetails.SetToggle(slider, check:GetChecked())
		end)
		
		check:SetScript("OnSizeChanged", function()
			check:SetWidth(check:GetHeight())
		end)
		
		check:SetPoint("Top", slider.Title, "Bottom", 0, 0)
		check:SetPoint("Left", 5, 0)
		check:SetPoint("Bottom", 0, 0)
		
		check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
		check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
		check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Disabled")
		
		slider:SetPoint("Left", check, "Right", 5, 0)
	end

	if parent.Items and not tContains(parent.Items, contain) then
		tinsert(parent.Items, contain)
	end

	return contain
end

function toolbelt.Button(parent, optionDetails)
	local button = CreateFrame("Button", nil, parent.PageAnchor or parent, "UIMenuButtonStretchTemplate")
	button:SetSize(parent:GetWidth(), 25)
	
	button.Text:SetText(optionDetails.title)
	
	button:SetScript("OnClick", optionDetails.OnClick)

	tinsert(toolbelt.AllItems.button, function() return button end)
	
	if parent.Items and not tContains(parent.Items, button) then
		tinsert(parent.Items, button)
	end

	return button
end

function toolbelt.Page(parent, optionInfo)
	local page = CreateFrame("ScrollFrame", parent:GetName().."_"..optionInfo.name, parent)
	optionInfo.page = page
	page:SetSize(255 + 18 + 6, 250)
	page:SetPoint("Top", parent, 0, -3)
	
	tinsert(toolbelt.AllItems.page, function() return page end)


	page.PageAnchor = CreateFrame("Frame", page:GetName().."_Container", page); do
		page.PageAnchor:SetHeight(300)
		page.PageAnchor:SetPoint("Top", 0, -3)
		page.PageAnchor:SetPoint("Left", page)
		page.PageAnchor:SetPoint("Right", page)
		page:SetScrollChild(page.PageAnchor)
	end

	page:SetScript("OnSizeChanged", function()
		page.PageAnchor:SetSize(page:GetSize())
	end)

	optionInfo.pageValue = (#parent.optionPanels == 0) and 0 or (300 * #parent.optionPanels)
	
	page:SetPoint("Left", parent, optionInfo.pageValue, 0)
	local yBase, yOffset = page:GetBottom()
	
	local panelCount = #parent.optionPanels
	
	page.New = {}
	for i, b in pairs(toolbelt) do
		if i ~= Page then
			page.New[i] = function(optionDetails)
				return b(page, optionDetails)
			end
		end
	end
	
	page.Items = {}

	local objectHeight = 5

	if optionInfo.options then
		for i, optionDetails in pairs(optionInfo.options) do
			local item = page.New[optionDetails.kind]
			if item then
				local object = item(optionDetails)
				
				if not tContains(page.Items, object) then
					--Some objects add themselves on creation.
					object.Position = objectHeight
					objectHeight = objectHeight + object:getHeight()
					tinsert(page.Items, object)
				end
			end
		end

	end
	
	function optionInfo:OnShow()
		page:SetPoint("Left", parent, optionInfo.pageValue, 0)
	

			
		page.Layout()
	end
	
	if #parent.optionPanels < 1 then
		parent:SetPageTitle(optionInfo.name)
		parent:SetPageIndex(1 .."/".. #parent.optionPanels)
	end

	tinsert(parent.optionPanels, optionInfo)
	
	
	local slide = CreateFrame("Slider", _, page, "HorizontalSliderTemplate") do
		slide:SetWidth(18)
		slide:ClearAllPoints()
		slide:SetPoint("Top", parent, 0, 4)
		slide:SetPoint("Bottom", parent:GetParent(), 0, -4)
		slide:SetPoint("Left", page, "Right", 6, 0)
		
		slide:SetObeyStepOnDrag(true)
		slide:Hide()
		
		if optionInfo.options then
		slide:SetMinMaxValues(1, #optionInfo.options)
		slide:SetValue(1)
		slide:SetValueStep(page:GetHeight())
		end
		slide:SetOrientation("VERTICAL")
		
		
		slide.high = slide:CreateLine(nil, 'OVERLAY', 2); do
			slide.high:SetThickness(12)
			slide.high:SetColorTexture(.2,.2,.8,.4)
			slide.high:SetStartPoint("Top", slide, 0, -7)
			slide.high:SetEndPoint("Bottom", slide, 0, 7)
				

			slide.Thumb:SetDrawLayer('OVERLAY', 3)
			slide.high:Hide()
			
			slide:SetScript("OnEnter", function() slide.high:Show() end)
			slide:SetScript("OnLeave", function() slide.high:Hide() end)
		end

		optionInfo.slide = slide
	end	
	
	page:SetScript("OnUpdate", function()
		if page.Update then
			page:Update()
		end
	end)

	local used = {}
	local function SetScroll(instant)
		local value = floor(slide:GetValue())
		objectHeight = 5
		wipe(used)
		for i, object in pairs(page.Items) do
			if object:IsVisible() and object.Position then
				object.Position = objectHeight
				objectHeight = objectHeight + object:GetHeight()
				if (object.Position) <= (page.range + object:GetHeight()) then
					tinsert(used, object)
				end
			end
		end
		
		slide:SetMinMaxValues(1, max(1, #used))
		value = max(min(value, #used), 1)

		local object = used[value]
		if object then
			local value = -8 + object.Position

			if not instant then
				local prevValue = page:GetVerticalScroll()

				local Fps = ceil(GetFramerate()/6)
				
				local increment = (value - prevValue) / Fps
				local index = 0

				page.Update = function()
					index = min(Fps+1, index + 1)
					if index >= Fps+1 then
						page.Update = nil
					else
						page:SetVerticalScroll(min(page.range-13, prevValue + (index * increment)))
					end
				end
			else
				page:SetVerticalScroll(value)
			end
		end
	end
	
	slide:SetScript("OnValueChanged", function(_, value)
		SetScroll()
	end)

	slide:SetScript("OnMouseWheel", function(_, delta)
		slide:SetValue(floor(slide:GetValue() - delta))
	end)

	page:SetScript("OnMouseWheel", function(_, delta)
		slide:SetValue(floor(slide:GetValue() - delta))
	end)
	local count = 1

	page.updateDisplay = function()
		objectHeight = 5
		count = 1
		
		local skipping = nil
		for i, object in pairs(page.Items) do
			if not object.SkipSetPoint then
				if object:IsVisible() then
					count = count + 1
					object.Position = objectHeight
					objectHeight = objectHeight + object:GetHeight()
				end
			end
		end
		
		
		local baseHeight = parent:GetParent():GetParent().PageContainer:GetHeight() 
		if objectHeight > baseHeight then
			slide:Show()
			--slide:SetValueStep(1)
			slide:SetMinMaxValues(1, count)
			page:SetWidth( parent:GetParent():GetParent().PageContainer:GetWidth() - 25)

			page.range = objectHeight - baseHeight

			page:SetHeight(objectHeight)
		
			slide:SetValue(slide:GetValue() or 1)
		else
			page.range = 0
			slide:SetValue(1)
			slide:Hide()
			page:SetWidth(( parent:GetParent():GetParent().PageContainer:GetWidth()))
			slide:SetMinMaxValues(1, 1)
		end
		SetScroll(true)
	end


	page.Layout = function()		
		objectHeight = 5
		count = 1
		
		local skipping = nil
		local last = nil
		for i, object in pairs(page.Items) do
			if not object.SkipSetPoint then
				skipping = object.skipping or skipping

				if skipping and skipping == object.skipper then
					object.Position = nil
					object:Hide()
				else
					object:Show()
					
					if count == 1 then
						object:SetPoint("TopLeft", 0, 5)
					else
						object:SetPoint("TopLeft", last, "BottomLeft", 0, 0)
					end
					
					local _ = object.OnShow and object.OnShow(object)
					last = object
					
					object.Position = objectHeight
					objectHeight = objectHeight + object:GetHeight()
					count = count + 1
				end
			end
		end
		

		page.updateDisplay()
		
	end

	local num =  #parent.optionPanels

	page.SetScroll = SetScroll

	return page
end

function toolbelt.ListBox(panel, optionInfo)
	local listBox = CreateFrame("Frame", panel:GetName().."ListBox", panel.PageAnchor or panel, "TooltipBorderedFrameTemplate"); do
		listBox:SetPoint("Left", -1, 0)
		listBox:SetPoint("Right", 1, 0)
		if not optionInfo.unset then
			listBox:SetPoint("Top", 3, -27)
			listBox:SetPoint("Bottom", -3, 7)
		else
			listBox:SetHeight(panel:GetHeight()*(.5))
		end
		listBox:SetBackdropColor(0,0,0,0)
		
		tinsert(toolbelt.AllItems.list, function() return listBox end)
		
		if panel.Items and not tContains(panel.Items, listBox) then
			tinsert(panel.Items, listBox)
		end
	end
	
	listBox.skipper = optionInfo.skipper
	
	local buttons = {}
	local displayOffset = 0
	local slide = CreateFrame("Slider", listBox:GetName().."Scroll", listBox, "HorizontalSliderTemplate") do
		slide:SetBackdropColor(1,1,1,1)
		slide:Hide()
		slide:SetWidth(18)
		slide.stepSize = 1
		slide:ClearAllPoints()
		slide:SetPoint("TopRight", -5, -28)
		slide:SetPoint("BottomRight", -5, 1)
		slide:SetOrientation("VERTICAL")
		
		slide:SetScript("OnMouseWheel", function(_, delta)
			local low, high = slide:GetMinMaxValues()
		
			local newVal = floor(slide:GetValue()-delta)
						
			if (low == high or newVal > high or newVal < low) and panel:GetScript("OnMouseWheel") then
				panel:GetScript("OnMouseWheel")(panel, delta)
				slide:SetValue(floor(slide:GetValue()-delta))
			end
		end)
		
		slide:SetScript("OnValueChanged", function()
			displayOffset = floor(slide:GetValue())
			listBox.update()
		end)

		listBox:SetScript("OnMouseWheel", function(_, delta)
			slide:GetScript("OnMouseWheel")(slide, delta)
		end)
	end

	local addEntry = toolbelt.advEditBox(listBox, optionInfo.addText or "", noShowTitle); do
		addEntry.SkipSetPoint = true
		addEntry:SetHeight(25)
		addEntry:SetPoint("Top", 0, -5)
		addEntry:SetPoint("Left", 5, 0)
		addEntry:SetPoint("Right", -5, 0)
		addEntry.tooltip = "Click here first, then Shift-click on a spell in your spellbook to add it quickly." .. (optionInfo.tooltip and "|n" .. optionInfo.tooltip or "")
		addEntry.edit:SetNormalAtlas("bags-icon-addslots")
	end


	
	local height = listBox:GetHeight() - 35
	local minButtonHeight = 25
	local numButtons = floor(height / minButtonHeight)
	local buttonHeight = height / numButtons
	
	
	local function SetButtons()
		height = listBox:GetHeight() - 35
		minButtonHeight = (105)/4
		numButtons = floor(height / minButtonHeight)
		buttonHeight = height / numButtons

		local height = (listBox:GetHeight() - 35)/numButtons
		for i, button in pairs(buttons) do

		end

		for i = 1, max(numButtons, #buttons) do
			local button = buttons[i] or toolbelt.advEditBox(listBox, "Button"..i, true)

			button:SetHeight(height)

			if not buttons[i] then
				button:SetPoint("Left", 5, 0)
				button:SetPoint("Right", -10, 0)
				
				if i == 1 then
					button:SetPoint("Top", 0, -30)
				else
					button:SetPoint("Top", buttons[i-1], "Bottom", 0, 0)
				end
				
				button.edit:SetPushedAtlas("BackupPet-DeadFrame")
				button.edit:SetNormalAtlas("BattleBar-SwapPetFrame-DeadIcon")

				button.edit:SetScript("OnClick", function()
					tremove(listBox.currentList, button.displayedIndex)
					listBox.update()
				end)

				button.text:SetScript("OnEnterPressed", function()
					listBox.currentList[button.displayedIndex] = button.text:GetText()
					button.text:ClearFocus()
					button.text:SetCursorPosition(0)
				end)

				button.text:SetScript("OnEscapePressed", function()
					if button.text.saveText then
						button.text:SetText(button.text.saveText or "")
					end
					listBox.currentList[button.displayedIndex] = button.text:GetText()
					button.text:ClearFocus()
				end)

				button.text:SetScript("OnEditFocusLost", function()
					button.text:SetText(listBox.currentList[button.displayedIndex] or "")
				end)

				button.text:SetScript("OnEditFocusGained", function()
					ACTIVE_CHAT_EDIT_BOX = button.text
					button.text:HighlightText()
					button.text.saveText = button.text:GetText()
				end)

				button.text:SetScript("OnTextChanged", function()
					local text = button.text:GetText()
					text = (text and GetSpellNameFromLink) and GetSpellNameFromLink(text) or text
					if text and text ~= button.text:GetText() then
						--if the text was formatted from a link, automatically add it to the list!
						button.text:SetText(text)
						listBox.currentList[button.displayedIndex] = text
						button.text:ClearFocus()
						button.text:SetCursorPosition(0)
						
					end
				end)

				button:Hide()
				
				button.tooltip = [[Click the text to edit this entry, or hit the red "X" to delete it.]]
			
				button:SetScript("OnEnter", function()
					if actionAura.HELP and button.tooltip then
						local text = button.tooltip..actionAura:CanLink()
						actionAura.HELP.Body:SetFormattedText(text)
					elseif actionAura.HELP then
						actionAura.HELP.Body:SetText("")
					end
				end)

				button:SetScript("OnLeave", function()
					if actionAura.HELP then
						actionAura.HELP.Body:SetText("")
					end
				end)
			end
			buttons[i] = button
		end
		
		listBox.update()
		
	end
	
	listBox:SetScript("OnSizeChanged", function()
		if optionInfo.unset then				
			listBox:SetHeight(min(200, panel:GetParent():GetParent():GetHeight()*(.5)))

		end
		SetButtons()

	end)
	function listBox.clear()
		listBox.currentList = nil
	end

	function listBox:SetList(list, force)
		listBox.currentList = force and nil or list or listBox.currentList
	end

	function listBox.update(list, newEntry)
		local list = listBox.Create and listBox.Create() or list or listBox.currentList
		
		listBox:SetList(list)
		
		
		list = listBox.currentList
			
		local newEntry = (newEntry and GetSpellNameFromLink) and GetSpellNameFromLink(newEntry) or newEntry

		if newEntry and newEntry ~= "" then
			if not tContains(list, newEntry) then
				tinsert(list, newEntry)
			end
		end
		
		if list and #list > numButtons then
			slide:Show()
		else
			slide:Hide()
		end

		local low, high = 0, list and max(0, #list - numButtons) or 0

		local value = slide:GetValue() or 0

		slide:SetMinMaxValues(low, high)
		slide:SetValue((list and value > high) and 0 or value)

		displayOffset = max(displayOffset, min(displayOffset, high), low)


		for i, button in pairs(buttons) do
			button.text:ClearFocus()
			button:SetPoint("Right", slide:IsShown() and slide or -5, slide:IsShown() and "Left" or 0)
			if (list and list[i + displayOffset]) and i <= numButtons then
				button:Show()
				button.text:SetText(list[i + displayOffset])
				button.text:SetCursorPosition(0)
				button.displayedIndex = i + displayOffset
			else
				button:Hide()
				button.text:SetText("")
			end
		end
	
	end

	addEntry.text:SetScript("OnTextChanged", function()
		local text = addEntry.text:GetText()
		
		text = (text and GetSpellNameFromLink) and GetSpellNameFromLink(text) or text
		
		if text and text ~= addEntry.text:GetText() then
			--if the text was formatted from a link, automatically add it to the list!
			addEntry.text:SetText("")
			listBox.update(nil, text)
		end
	end)

	addEntry.text:SetScript("OnEditFocusGained", function()
		ACTIVE_CHAT_EDIT_BOX = addEntry.text
		addEntry.text:HighlightText()
	end)

	addEntry.text:SetScript("OnEnterPressed", function()
		if addEntry.text:GetText() ~= "" then
			listBox.update(nil, addEntry.text:GetText())
			addEntry.text:SetText("")
		end
	end)

	addEntry.edit:SetScript("OnClick", function()
		if addEntry.text:GetText() ~= "" then
			listBox.update(nil, addEntry.text:GetText())
			addEntry.text:SetText("")
		end
		addEntry.text:ClearFocus()
	end)


	SetButtons()

	return listBox
end

function toolbelt.ListFrame(parent, optionInfo)
	local panel = CreateFrame("Frame", parent:GetName().. optionInfo.listName .."Panel", parent.PageAnchor or parent)
	panel.Items = {}

	if parent.Items and not tContains(parent.Items, panel) then
		tinsert(parent.Items, panel)
	end

	local formatText = GetSpellNameFromLink

	local listDropdownButton; do
		if optionInfo.allowDelete == true then
			listDropdownButton = toolbelt.DropDownEditBox(panel, {title = optionInfo.listName})
			listDropdownButton.SkipSetPoint = true
			listDropdownButton.delete = CreateFrame("Button", listDropdownButton:GetName().."Delete", listDropdownButton)
			listDropdownButton.delete:SetSize(15, 15)
			listDropdownButton.delete:SetPoint("Left", listDropdownButton, "Right", 0, 0)
			listDropdownButton.delete:SetPushedAtlas("BackupPet-DeadFrame")
			listDropdownButton.delete:SetNormalAtlas("BattleBar-SwapPetFrame-DeadIcon")

			listDropdownButton.delete:SetHighlightAtlas("bags-glow-artifact")
			listDropdownButton:SetPoint("TopRight", panel, -15, 0)
			
			
			listDropdownButton.tooltip = [[Click here first, then Shift-click on a spell in your spellbook to add it quickly. |nPress the Arrow to modify or add to an existing spell. |nClick the red "X" to delete all entries for this spell.]]
			
			
		else
			listDropdownButton = parent.New.DropDown(optionInfo.listName)
		
			listDropdownButton.SkipSetPoint = true
			listDropdownButton:SetHeight(25)
			listDropdownButton:SetPoint("TopRight", panel, 0, 0)
		end
		
		listDropdownButton:SetPoint("Left", 0, 0)
		
		local list = type(optionInfo.initialList) == "table" and optionInfo.initialList or type(optionInfo.initialList)=="function" and optionInfo.initialList(listDropdownButton)
		listDropdownButton.text:SetText(list[1]  or "")
	end
	
	local listBox = toolbelt.ListBox(panel, optionInfo)

	listBox:SetPoint("Bottom", panel:GetParent():GetParent():GetParent(), 0, 0)

	local CurrentTranslationList

	local function UpdateItems(newEntry)
		CurrentTranslationList = optionInfo.GetList(listDropdownButton.text:GetText())
		
		listDropdownButton.list = type(optionInfo.initialList) == "table" and optionInfo.initialList or type(optionInfo.initialList)=="function" and optionInfo.initialList(listDropdownButton)
		
		listBox.update(CurrentTranslationList, newEntry)
	end
	
	if listDropdownButton.delete then
		listDropdownButton.delete:SetScript("OnClick", function()
			optionInfo.DeleteEntry(listDropdownButton.text:GetText())
			listDropdownButton.text:SetText("")
			UpdateItems()
		end)

		listDropdownButton.text:SetScript("OnTextChanged", function()
			local text = listDropdownButton.text:GetText()
			
			text = (text and GetSpellNameFromLink) and GetSpellNameFromLink(text) or text
			
			if text and text ~= listDropdownButton.text:GetText() then
				--if the text was formatted from a link, automatically add it to the list!
				listDropdownButton.text:SetText(text)
				optionInfo.AddEntry(text)
				listDropdownButton.text:ClearFocus()
				UpdateItems()
			end
		end)

		listDropdownButton.text:SetScript("OnEditFocusGained", function()
			ACTIVE_CHAT_EDIT_BOX = listDropdownButton.text
			listDropdownButton.text:HighlightText()
			listDropdownButton.text.saveText = listDropdownButton.text:GetText()
		end)

		listDropdownButton.text:SetScript("OnEnterPressed", function()
			if listDropdownButton.text:GetText() ~= "" then
				optionInfo.AddEntry(listDropdownButton.text:GetText())
				UpdateItems()
				listDropdownButton.text.saveText = nil
			end
		end)
	end

	panel:SetPoint("TopLeft",0, 0)
	panel:SetPoint("BottomRight", 0, 9)

	listDropdownButton.list = optionInfo.initialList
	listDropdownButton.Update = UpdateItems

	UpdateItems()

	function panel:OnShow()
		if panel.Items then
			for i, object in pairs(panel.Items) do
				if object.OnShow then
					object:OnShow(object)
				end
			end
		end
	end

	panel.SkipSetPoint = true

	return panel
end

function toolbelt.TitleLine(parent, optionInfo)
	local lineFrame = CreateFrame("Frame", nil, parent.PageAnchor or parent)
	lineFrame:SetPoint("Left")
	lineFrame:SetPoint("Right", 0, 0)
	lineFrame:SetHeight(30)
	
	tinsert(toolbelt.AllItems.title, function() return lineFrame end)
	
	lineFrame.line = lineFrame:CreateLine(nil, 'ARTWORK', 1)
	lineFrame.line:SetThickness(2)
	lineFrame.line:SetColorTexture(.8,.8,.8,.4)
	lineFrame.line:SetStartPoint("BottomLeft", lineFrame, 0, 4)
	lineFrame.line:SetEndPoint("BottomRight", lineFrame, 0, 4)

	lineFrame.text = lineFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		lineFrame.text:SetPoint("Top", 0, -6)
		lineFrame.text:SetAllPoints(lineFrame)
		lineFrame.text:SetJustifyH("MIDDLE") 
		lineFrame.text:SetText(optionInfo.title) 

	lineFrame.text.high = lineFrame:CreateTexture(nil, 'HIGHLIGHT', 2); do
		lineFrame.text.high:SetPoint("TopLeft", lineFrame, 0, -3)
		lineFrame.text.high:SetPoint("BottomRight", lineFrame, 0, 3)
		lineFrame.text.high:SetAtlas("soulbinds_collection_entry_highlight")
	end
	
	if parent.Items and not tContains(parent.Items, lineFrame) then
		tinsert(parent.Items, lineFrame)
	end
	
	if optionInfo.skipping then
		lineFrame.left = lineFrame:CreateTexture(nil, "Artwork")
		lineFrame.left:SetSize(15, 7.5)
		lineFrame.left:SetPoint("Left")
		lineFrame.left:SetAtlas("helptip-arrow")
		lineFrame.left:SetTexCoord(0,1,1,0)
		
		lineFrame.left:SetVertexColor(1,1,1,.75)
		
		lineFrame.right = lineFrame:CreateTexture(nil, "Artwork")
		lineFrame.right:SetSize(15, 7.5)
		lineFrame.right:SetPoint("Right")
		lineFrame.right:SetAtlas("helptip-arrow")
		lineFrame.right:SetTexCoord(0,1,1,0)
	
		lineFrame.right:SetVertexColor(1,1,1,.75)
	
		lineFrame:EnableMouse(true)
		lineFrame:SetScript("OnMouseDown", function()
			if not lineFrame.skipping then
				lineFrame.skipping = optionInfo.skipping
				lineFrame.left:SetTexCoord(0,1,0,1)
				lineFrame.right:SetTexCoord(0,1,0,1)
			else
				lineFrame.skipping = nil
				
				lineFrame.left:SetTexCoord(0,1,1,0)
				lineFrame.right:SetTexCoord(0,1,1,0)
			end
			parent:Layout()
		end)
		
	
	end

	if optionInfo.tooltip then
		lineFrame:SetScript("OnEnter", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText(optionInfo.tooltip)
			end
		end)

		lineFrame:SetScript("OnLeave", function()
			if actionAura.HELP then
				actionAura.HELP.Body:SetText("")
			end
		end)
	end

	
	return lineFrame
end

