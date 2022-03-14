local toolbelt = LibStub('toolbelt')

if not toolbelt or toolbelt.NewMenu then return end

local AddonName = ...
local actionAura = LibStub("AceAddon-3.0"):GetAddon(AddonName)

local pageMixin = {}

function toolbelt.Page(parent, optionInfo)
	local page = CreateFrame("ScrollFrame", parent:GetName().."_"..optionInfo.name, parent); do
		page.name = optionInfo.name
		Mixin(page, pageMixin)
		optionInfo.page = page
		page:SetSize(255 + 18 + 6, 250)
		
		page.Viewport = parent:GetParent():GetParent().Viewport
		
		page:SetPoint("Top", page.Viewport, 0, -3)
		page:SetPoint("Bottom", page.Viewport, 0, 0 )
		
		tinsert(toolbelt.AllItems.page, function() return page end)
	end
	
	page.PageAnchor = CreateFrame("Frame", page:GetName().."_Container", page); do
		page.PageAnchor:SetHeight(300)
		page.PageAnchor:SetPoint("Top", 0, -3)
		page.PageAnchor:SetPoint("Left", page)
		page.PageAnchor:SetPoint("Right", page)
		page:SetScrollChild(page.PageAnchor)
	end
	
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
		slide:SetValueStep(1)
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

		slide:SetScript("OnMouseWheel", function(_, delta)
			page:GetScript("OnMouseWheel")(page, delta)
		end)

		optionInfo.slide = slide
		page.slide = slide
	end	
	
	page:SetScript("OnUpdate", function()
		if page.shouldUpdate then
			page:Update()
		end
	end)

	page.pageValue = (#parent.pages == 0) and 0 or (page.Viewport:GetWidth() * #parent.pages)
	
	page:SetPoint("Left", parent, page.pageValue, 0)
		
	page.New = {}
	for i, b in pairs(toolbelt) do
		if i ~= "Page" and i ~= "NewMenu" then
			page.New[i] = function(optionDetails)
				return b(page, optionDetails)
			end
		end
	end
	
	page.Items = {}

	page.objectHeight = 0

	if optionInfo.options then
		for i, optionDetails in pairs(optionInfo.options) do
			local item = page.New[optionDetails.kind]
			if item then
				local object = item(optionDetails)
				
				-- object.Position = page.objectHeight
				-- page.objectHeight = page.objectHeight + object:GetHeight()
			end
		end

	end
	
	function page:OnShow()
		page.Layout()
	end
		

	page.scrollValue = 1

	page.used = {}
	local function SetScroll(instant)
		local baseHeight = page:GetHeight() 

		slide:SetShown(page.objectHeight > baseHeight)
		page:SetWidth( page.Viewport:GetWidth() - (slide:IsVisible() and 25 or 0))

		local value = floor(page.scrollValue)
		local count = 0

		 for i, object in pairs(page.used) do
			if (object.Position - object:GetHeight()) <= (page.objectHeight - baseHeight) then
				count = count + 1
			end
		 end
		
		slide:SetMinMaxValues(1, max(1, count))
		page.scrollValue = max(min(page.scrollValue, count), 1)

		if page.scrollValue ~= slide:GetValue() then
			slide:SetValue(page.scrollValue)
		end

		local object = page.used[page.scrollValue]
		if object then
			page.value = object.Position
			CloseDropDownMenus()
			if not instant then
				page.prevValue = page:GetVerticalScroll()

				page.Fps = ceil(GetFramerate()/6)
				
				page.increment = (page.value - page.prevValue) / page.Fps
				page.index = 0
				page.shouldUpdate = true
				page.Update = page.Update or function()
					page.index = min(page.Fps+1, page.index + 1)

					local newVal
					if page.index >= page.Fps+1 then
						newVal = page.value
						page.shouldUpdate = nil
					else
						newVal = page.prevValue + (page.index * page.increment)
					end
					
					page:SetVerticalScroll(min(page.objectHeight -  page:GetHeight() , newVal))
				end
			else
				page.shouldUpdate = nil
				page:SetVerticalScroll(page.value)
			end
		end		
	end
	
	slide:SetScript("OnValueChanged", function(_, value)
		page.scrollValue = floor(slide:GetValue())
		SetScroll()
	end)

	page:SetScript("OnMouseWheel", function(_, delta)
		local low, high = slide:GetMinMaxValues()
		slide:SetValue(floor( max(min(page.scrollValue - delta, high), low)))
	end)
	
	page.SetScroll = SetScroll

	page.Layout = function()		
		page.objectHeight = 0
		wipe(page.used)
		
		local skipping = nil
		for i, object in pairs(page.Items) do
			skipping = object.skipping or skipping
			
			if not object.SkipSetPoint then
				if skipping and skipping == object.skipper then
					object:SetShown(false)
				else
					object:SetShown(true)
				end
				
				if object:IsShown() then
					object:SetPoint("TopLeft", 0, #page.used == 0 and 0 or -page.objectHeight)
					tinsert(page.used, object)
					
					object.Position = page.objectHeight
					page.objectHeight = page.objectHeight + object:GetHeight()
					
					local _ = object.OnShow and object.OnShow(object)
				else
					object.Position = nil
				end
			end
		end
		
		if page.objectHeight <= page:GetHeight() then
			page.scrollValue = 1
		 end

		SetScroll(true)
	end

	page.Index = #parent.pages + 1

	page:SetScript("OnSizeChanged", function()
		local w, h = page:GetSize()
		page.PageAnchor:SetSize(w, h - (page.offset or 0))

		page.Layout()
	end)

	if #parent.pages < 1 then
		parent:SetPageTitle(optionInfo.name)
		parent:SetPageIndex(1 .."/".. #parent.pages)
	end

	tinsert(parent.pages, page)

	return page
end




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
	
	do --Interconnected Objects
		panel.Viewport = CreateFrame("ScrollFrame", panel:GetName().."_ScrollPanel", panel); do
			panel.Viewport:SetPoint("TopLeft", panel, 10, -(27+18 +8))
			panel.Viewport:SetPoint("BottomRight", panel, -10, 10)
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

		panel.PageAnchor = CreateFrame("Frame", panel:GetName().."_Container", panel.Viewport); do
			panel.Viewport:SetScrollChild(panel.PageAnchor)
			panel.PageAnchor:SetPoint("TopLeft")
			panel.PageAnchor:SetSize(300, 300)

			panel.PageAnchor.SetPageTitle = function(text)
				panel.PageTitle:SetText(text)
			end

			panel.PageAnchor.SetPageIndex = function(text)
				panel.PageIndex:SetText(text)
			end
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
	
		panel.pages = {}
		panel.PageAnchor.pages = panel.pages
		panel.New = {}
		
		panel.pageIndex = 1

		panel.PageButton:SetScript("OnMouseWheel", function(_, delta)
			panel:OnMouseWheel(delta)
		end)

		panel:SetScript("OnHide", panel.OnHide)
		panel.PageButton:SetScript("OnUpdate", panel.OnUpdate)
		hooksecurefunc(panel, "StopMovingOrSizing", panel.OnStopMovingOrSizing)
		hooksecurefunc(panel, "StartSizing", panel.OnStartSizing)
		panel:SetScript("OnSizeChanged", panel.OnSizeChanged)
	end
	
	do --Create Pages
		if optionInfo.pages then
			for i, pageDetails in pairs(optionInfo.pages) do
				toolbelt.Page(panel.PageAnchor, pageDetails)
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

function panelMixin:OnUpdate()
	if self.shouldUpdate then
		self:Update()
	end
end

function panelMixin:OnMouseWheel(delta)
	local _min, _max = 1, #self.pages

	local prevPage = self.pages[self.pageIndex]
	
	if prevPage and prevPage.Clear then
		prevPage.Clear()
	end	

	self.pageIndex = self.pageIndex + delta
	if self.pageIndex < _min then
		self.pageIndex = _max
	elseif self.pageIndex > _max then
		self.pageIndex = _min
	end
	
	local page = self.pages[self.pageIndex]

	self.page = self.pageIndex

	local p = self.PageButton

	p.value = page.pageValue

	p.prevValue = self.Viewport:GetHorizontalScroll()

	p.Fps = ceil(GetFramerate()/3)
	
	p.increment = (p.value - p.prevValue) / p.Fps
	p.index = 0
	self.PageButton.shouldUpdate = true
	self.PageButton.Update = self.PageButton.Update or function()
		p.index = min(p.Fps+1, p.index + 1)
		if p.index >= p.Fps+1 then
			self.PageButton.shouldUpdate = nil
		else
			self.Viewport:SetHorizontalScroll(p.prevValue + (p.index * p.increment))
		end
	end

	self.PageTitle:SetText(page.name)
	self.PageIndex:SetText(self.pageIndex .."/".. #self.pages)
	
	self.help.Panel.Header:SetText(page.tooltip or "")

	self.LeftArrow:SetShown(not (self.pageIndex <= _min))
	self.RightArrow:SetShown(not (self.pageIndex >= _max))

	local _ = page.OnShow and page.OnShow()

	CloseDropDownMenus()
end

function panelMixin:OnStopMovingOrSizing()
	self.IsSizing = nil
end

function panelMixin:OnHide()
	actionAura.EnableLinks = nil
end

function panelMixin:OnStartSizing()
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
end

function panelMixin:OnSizeChanged()
	if not self.ignoreResize then
		if self.IsSizing then
			self.IsSizing()
		end
		local width = self.Viewport:GetWidth()
		for i, page in pairs(self.pages) do
			page.pageValue = width * i
			page:SetPoint("Left", page.pageValue, 0)
			page.SetScroll(true)
		end
					
		self.Viewport:SetHorizontalScroll(self.pages[self.pageIndex].pageValue)
	end
end

--functions
function panelMixin:Refresh()
	for i, page in pairs(self.pages) do
		if page.OnShow then
			page:OnShow(page)
		end
	end
	
	self.pageIndex = 1
	self.PageButton:GetScript("OnMouseWheel")(self.PageButton, 0)
end

function panelMixin:AddPage(pageDetails)
	return toolbelt.Page(self.PageAnchor, pageDetails), self:Refresh()
end

function toolbelt.NewMenu(optionInfo)
	local panel = panelMixin.Create(optionInfo)



	return panel
end
