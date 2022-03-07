local toolbelt = LibStub('toolbelt')

if not toolbelt or toolbelt.NewMenu then return end

local AddonName = ...
local actionAura = LibStub("AceAddon-3.0"):GetAddon(AddonName)

local panelMixin = {}

panelMixin.Create = function(optionInfo)
	local panel = CreateFrame("Frame", AddonName..optionInfo.title.."Container", UIParent, "TooltipBorderedFrameTemplate");do
		Mixin(panel, panelMixin)
		
		panel:SetSize(300, 300)
		panel:SetPoint("Center")
		panel:SetMovable(true)

		panel:SetScript("OnMouseDown", panel.StartMoving)
		panel:SetScript("OnMouseUp", panel.StopMovingOrSizing)
	end
	
	do --Self Contained Objects
		local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");do
			title:SetPoint("TopLeft", 11, -9)
			title:SetText(optionInfo.DisplayTitle)
		end

		local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton"); do
			closeButton:SetPoint("TopRight")
			closeButton:SetScale(.8)
			closeButton:SetScript("OnClick", function() panel:Hide() end)
		end

		local help = CreateFrame("Button", nil, panel, "UIMenuButtonStretchTemplate"); do
			help:SetSize(45, 18)
			help:SetPoint("TopRight", -23, -5)
			
			help.Panel = CreateFrame("Frame", nil, panel, "TooltipBorderedFrameTemplate")
			help.Panel:SetSize(250, 150)
			
			help.Panel.Body = help.Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			help.Panel.Body:SetPoint("BottomLeft", panel,"BottomRight", 10, 10)
			help.Panel.Body:SetWidth(250)
			help.Panel.Body:SetWordWrap(true)
			help.Panel.Body:SetJustifyH("LEFT")
			help.Panel.Body:SetJustifyV("Bottom") 
			help.Panel.Body:SetText("Need Something?")
			
			help.Panel.Header = help.Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			help.Panel.Header:SetPoint("BottomLeft", help.Panel.Body, "TopLeft", 0, 3)
			help.Panel.Header:SetPoint("BottomRight", help.Panel.Body, "BottomRight", 0, 3)
			help.Panel.Header:SetJustifyH("LEFT")
			help.Panel.Header:SetJustifyV("TOP") 
			help.Panel.Header:SetWordWrap(true)
			help.Panel:SetPoint("TopRight", help.Panel.Header, 10, 10)
			help.Panel:SetPoint("BottomLeft", help.Panel.Body, -10, -10)

			help.Panel:Hide()
			
			help:SetScript("OnClick", function()
				if help.Panel:IsShown() then
					help.Panel:Hide()
					actionAura.HELP = nil
				else
					help.Panel:Show()
					actionAura.HELP = help.Panel
				end
			end)
			
			local line = help.Panel:CreateLine(nil, 'ARTWORK', 1)
			line:SetThickness(2)
			line:SetStartPoint("TopLeft", help.Panel.Body, 0, 1.5)
			line:SetEndPoint("TopRight", help.Panel.Body, 0, 1.5)
			line:Hide()
			line:SetColorTexture(.8,.8,.8,.6)
				
			help.Panel:SetScript("OnSizeChanged", function()
				if help.Panel.Body:GetText() == " " or help.Panel.Body:GetText() == nil 
				or help.Panel.Header:GetText() == " " or help.Panel.Header:GetText() == nil then
					line:Hide()
					help.Panel.Header:SetPoint("BottomLeft", help.Panel.Body, "TopLeft", 0, 0)
					help.Panel.Header:SetPoint("BottomRight", help.Panel.Body, "BottomRight", 0, 0)
				else
					line:Show()
					help.Panel.Header:SetPoint("BottomLeft", help.Panel.Body, "TopLeft", 0, 3)
					help.Panel.Header:SetPoint("BottomRight", help.Panel.Body, "BottomRight", 0, 3)
				end
			end)
			
			help.Text:ClearAllPoints()
			help.Text:SetPoint("Center")
			
			help.Text:SetText("Help")
			
			panel.help = help
		end

		panel.resize = CreateFrame("Button", nil, panel); do
			panel.resize:SetSize(14, 14)
			panel.resize:SetPoint("BottomRight")
			
			panel.resize:SetNormalAtlas("GarrMission_RewardsBorder-Corner")
			panel.resize:SetHighlightAtlas("GarrMission_RewardsBorder-Corner")
			panel.resize:GetHighlightTexture():SetBlendMode("ADD")
			panel.resize:GetHighlightTexture():SetTexCoord(1, 0, 1, 0)
			
			panel.resize:GetNormalTexture():SetTexCoord(1, 0, 1, 0)
			panel.resize:GetNormalTexture():SetVertexColor(1,1,1,1)
			
			
			panel:SetMinResize(300, 300)
			panel:SetMaxResize(900, 900)
			
			panel.resize:SetScript("OnDoubleClick", function()
				panel:ResizeOnDoubleClick()
			end)
			panel.resize:SetScript("OnMouseDown", function()
				panel:ResizeOnMouseDown()
			end)
			panel.resize:SetScript("OnMouseUp", function()
				panel:ResizeOnMouseUp()
			end)
		end
	end
	
	do --Interconnected object
		panel.PageContainer = CreateFrame("ScrollFrame", panel:GetName().."_ScrollPanel", panel); do
			panel.PageContainer:SetPoint("TopLeft", panel, 10, -(27+18 +8))
			panel.PageContainer:SetPoint("BottomRight", panel, -10, 10)
		end

		panel.PageAnchor = CreateFrame("Frame", panel:GetName().."_Container", panel.PageContainer); do
			panel.PageAnchor:SetPoint("TopLeft")
			panel.PageAnchor:SetSize(300, 300)
			panel.PageContainer:SetScrollChild(panel.PageAnchor)
		end

		panel.PageButton = CreateFrame("Frame", nil, panel, "TooltipBorderedFrameTemplate"); do
			panel.PageButton:SetHeight(23)
			panel.PageButton:EnableMouse(true)
			panel.PageButton:SetPoint("Top", 0, -27)
			panel.PageButton:SetPoint("Left",10, 0)
			panel.PageButton:SetPoint("Right", -10, 0)

			panel.PageButton.high = panel.PageButton:CreateTexture(nil, 'OVERLAY', 2)
			panel.PageButton.high:Hide()
			panel.PageButton.high:SetPoint("TopLeft", 4, -4)
			panel.PageButton.high:SetPoint("BottomRight", -4, 3)
			panel.PageButton.high:SetAtlas("soulbinds_collection_entry_highlight")
			
			
			panel.PageButton:SetScript("OnEnter", function(self)
				self.high:Show()
			end)
			
			panel.PageButton:SetScript("OnLeave", function(self)
				self.high:Hide()
			end)
		end

		panel.PageIndex = panel.PageButton:CreateFontString(nil, "ARTWORK", "GameFontNormal"); do
			panel.PageIndex:SetPoint("Right", -18, -1)
			panel.PageIndex:SetJustifyH("RIGHT")
		end
		
		panel.PageTitle = panel.PageButton:CreateFontString(nil, "ARTWORK", "GameFontNormal"); do
			panel.PageTitle:SetPoint("Left", 18, -1)
			panel.PageTitle:SetPoint("Right", panel.PageIndex, "Left", -3, 0)
			panel.PageTitle:SetJustifyH("LEFT")
		end

		panel.LeftArrow = CreateFrame("Button", nil, panel.PageButton); do
			panel.LeftArrow:SetHighlightAtlas("covenantsanctum-renown-arrow")
			panel.LeftArrow:SetNormalAtlas("covenantsanctum-renown-arrow-disabled")
			panel.LeftArrow:SetPushedAtlas("covenantsanctum-renown-arrow-depressed")
			panel.LeftArrow:SetHitRectInsets(0, -panel.PageButton:GetWidth()/2, -1.5, -1.5)
			
			panel.LeftArrow:GetHighlightTexture():SetVertexColor(1,1,1, 1)
			panel.LeftArrow:GetNormalTexture():SetVertexColor(1,1,1, 1)
			panel.LeftArrow:GetPushedTexture():SetVertexColor(1,1,1, 1)
			
			panel.LeftArrow:RegisterForClicks("AnyUp")
			panel.LeftArrow:SetPoint("Left", 5, 0)
			panel.LeftArrow:SetSize(13, 16)
			panel.LeftArrow:Hide()

			panel.LeftArrow:SetScript("OnClick", function()
				panel.PageButton:GetScript("OnMouseWheel")(panel.PageButton, -1)
			end)
			
			panel.LeftArrow:SetScript("OnEnter", function()
				panel.PageButton.high:Show()
			end)
			
			panel.LeftArrow:SetScript("OnLeave", function()
				panel.PageButton.high:Hide()
			end)
		end
		
		panel.RightArrow = CreateFrame("Button", nil, panel.PageButton); do
			panel.RightArrow:SetHighlightAtlas("covenantsanctum-renown-arrow")
			panel.RightArrow:SetNormalAtlas("covenantsanctum-renown-arrow-disabled")
			panel.RightArrow:SetPushedAtlas("covenantsanctum-renown-arrow-depressed")
			
			panel.RightArrow:GetHighlightTexture():SetVertexColor(1,1,1, 1)
			panel.RightArrow:GetNormalTexture():SetVertexColor(1,1,1, 1)
			panel.RightArrow:GetPushedTexture():SetVertexColor(1,1,1, 1)
			
			panel.RightArrow:GetHighlightTexture():SetTexCoord(1,0,0,1)
			panel.RightArrow:GetNormalTexture():SetTexCoord(1,0,0,1)
			panel.RightArrow:GetPushedTexture():SetTexCoord(1,0,0,1)
			
			panel.RightArrow:SetHitRectInsets(-panel.PageButton:GetWidth(), 0, -1.5, -1.5)
			panel.RightArrow:RegisterForClicks("AnyUp")
			panel.RightArrow:SetPoint("Right", -5, 0)
			panel.RightArrow:SetSize(13, 16)
			
			panel.RightArrow:SetScript("OnClick", function()
				panel.PageButton:GetScript("OnMouseWheel")(panel.PageButton, 1)
			end)
			
			panel.RightArrow:SetScript("OnEnter", function()
				panel.PageButton.high:Show()
			end)
			
			panel.RightArrow:SetScript("OnLeave", function()
				panel.PageButton.high:Hide()
			end)
		end
		
		do --Arrows have a dynamic display
			panel.RightArrow:SetScript("OnShow", function()
				panel.LeftArrow:SetHitRectInsets(0, -panel.PageButton:GetWidth()/2, -1.5, -1.5)
			end)
			
			panel.RightArrow:SetScript("OnHide", function()
				panel.LeftArrow:SetHitRectInsets(0, -panel.PageButton:GetWidth(), -1.5, -1.5)
			end)
			
			panel.LeftArrow:SetScript("OnShow", function()
				panel.RightArrow:SetHitRectInsets(-panel.PageButton:GetWidth()/2, 0, -1.5, -1.5)
			end)
			
			panel.LeftArrow:SetScript("OnHide", function()
				panel.RightArrow:SetHitRectInsets(-panel.PageButton:GetWidth(), 0, -1.5, -1.5)
			end)
		end
	end

	do --scripts and functions
		panel:SetScript("OnHide", function()
			actionAura.EnableLinks = nil
		end)
	
		panel.PageAnchor.SetPageTitle = function(text)
			panel.PageTitle:SetText(text)
		end
		panel.PageAnchor.SetPageIndex = function(text)
			panel.PageIndex:SetText(text)
		end

		panel.PageAnchor.optionPanels = {}
		panel.New = {}
		
		panel.pageIndex = 1

		panel.PageButton:SetScript("OnUpdate", function()
			if panel.PageButton.Update then
				panel.PageButton:Update()
			end
		end)
				
		panel.PageButton:SetScript("OnMouseWheel", function(_, delta)
			local _min, _max = 1, #panel.PageAnchor.optionPanels
		
			local prevPage = panel.PageAnchor.optionPanels[panel.pageIndex]
			
			if prevPage and prevPage.Clear then
				prevPage.Clear()
			end	
		
			panel.pageIndex = panel.pageIndex + delta
			if panel.pageIndex < _min then
				panel.pageIndex = _max
			elseif panel.pageIndex > _max then
				panel.pageIndex = _min
			end
			
			local page = panel.PageAnchor.optionPanels[panel.pageIndex]

			panel.page = panel.pageIndex

			local value = page.pageValue

			local prevValue = panel.PageContainer:GetHorizontalScroll()

			local Fps = ceil(GetFramerate()/3)
			
			local increment = (value - prevValue) / Fps
			local index = 0

			panel.PageButton.Update = function()
				index = min(Fps+1, index + 1)
				if index >= Fps+1 then
					panel.PageButton.Update = nil
				else
					panel.PageContainer:SetHorizontalScroll(prevValue + (index * increment))
				end
			end

			panel.PageTitle:SetText(page.name)

			if page.tooltip then
				panel.help.Panel.Header:SetText(page.tooltip)
			else
				panel.help.Panel.Header:SetText("")
			end
			
			if panel.pageIndex <= _min then
				panel.LeftArrow:Hide()
			else
				panel.LeftArrow:Show()
			end
			
			if panel.pageIndex >= _max then
				panel.RightArrow:Hide()
			else
				panel.RightArrow:Show()
			end
			
			panel.PageIndex:SetText(panel.pageIndex .."/".. #panel.PageAnchor.optionPanels)
			
			if page.OnShow then
				page:OnShow(page)
			end
			
			CloseDropDownMenus()
		end)
		
		hooksecurefunc(panel, "StopMovingOrSizing", function()
			panel.IsSizing = nil
		end)
		
		hooksecurefunc(panel, "StartSizing", function(self)
			local lowW, lowH = self:GetMinResize()
			local highW, highH = self:GetMaxResize()

			local s = self:GetEffectiveScale()

			local left = self:GetLeft()
			local right = self:GetRight()
			local bottom = self:GetBottom()
			local top = self:GetTop()
			
			self:ClearAllPoints()
			self:SetPoint("TopLeft", UIParent, "BottomLeft", left, top)
			
			local cX, cY = GetCursorPosition()
			cX, cY = cX / s, cY / s
			
			local oW, oH = right - cX, cY - bottom
			
			self.IsSizing = function()
				cX, cY = GetCursorPosition()
				cX, cY = (cX / s) + oW, (cY / s) - oH
			
				width = min(highW ,max(lowW, cX - left))
				height = min(highH ,max(lowH, top - cY))
				self.ignoreResize = true
				self:SetSize(width, height)
				self.ignoreResize = nil
			end
		end)

		panel:SetScript("OnSizeChanged", function(self)
			if not self.ignoreResize then
				if self.IsSizing then
					self.IsSizing()
				end
				local w, h = panel.PageContainer:GetSize()
				for i, page in pairs(self.PageAnchor.optionPanels) do
					page.pageValue = panel.PageContainer:GetWidth() * i
					page.page:SetPoint("Left", page.pageValue, 0)
					page.page.updateDisplay()
				end
							
				self.PageContainer:SetHorizontalScroll(self.PageAnchor.optionPanels[self.pageIndex].pageValue)
			end
		end)

		for i, b in pairs(toolbelt) do
			panel.New[i] = function(optionDetails)
				return b(panel.PageAnchor, optionDetails)
			end
		end

		if optionInfo.pages then
			for i, pageDetails in pairs(optionInfo.pages) do
				panel.New.Page(pageDetails)
			end
		end

		panel:Refresh()
	end
	
	tinsert(toolbelt.AllItems.panel, function() return panel end)
	
	return panel
end

--scripts
function panelMixin:ResizeOnDoubleClick()
	local w, h = self:GetSize()

	if w > 600 then
		w = 300
	else
		w = 700
	end
	if h > 600 then
		h = 300
	else
		h = 700
	end

	self:SetSize(w, h)
end

function panelMixin:ResizeOnMouseDown()
	self:SetResizable(true)
	self:StartSizing()
end

function panelMixin:ResizeOnMouseUp()
	self:StopMovingOrSizing()
end

function panelMixin:Refresh()
	for i, page in pairs(self.PageAnchor.optionPanels) do
		if page.OnShow then
			page:OnShow(page)
		end
	end
	
	self.pageIndex = 1
	self.PageButton:GetScript("OnMouseWheel")(self.PageButton, 0)
end

function panelMixin:AddPage(pageDetails)
	return self.New.Page(pageDetails), self:Refresh()
end


function toolbelt.NewMenu(optionInfo)
	local panel = panelMixin.Create(optionInfo)



	return panel
end
