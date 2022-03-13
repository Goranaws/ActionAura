local AddonName = ...
local actionAura  = LibStub("AceAddon-3.0"):GetAddon(AddonName)

actionAura.buttonRegistry = {}

 --Default Settings
actionAura.defaults = {
	translations = {
		["Entangling Roots"] = {"Mass Entanglement"},
	},
	personalAurasOnly == true,
	coloredBorderShow = true,
	filterOverride = {
		buff = {},
		debuff = {},
		ignore = {}
	},
	spells = {
		["Force of Nature"] = {
			override = "debuff",
			flashWhen = {
				missingFlash = false,
				
				expire = false,
				expireTime = 0,
				
				stack = false,
				stackCount = 0,
				
				missing = {},
				present = {},
				
				health = false,
				healthBelow = 0,
			},
			displayAs = {},
			units = {
				target = false,
				player = false,
				mouseover = false,
				focus = false,
			},
		},
		["Entangling Roots"] = {
			override = "debuff",
			flashWhen = {
				missingFlash = false,
				
				expire = false,
				expireTime = 0,
				
				stack = false,
				stackCount = 0,
				
				missing = {},
				present = {},
				
				health = false,
				healthBelow = 0,
			},
			displayAs = {"Mass Entanglement"},
			units = {
				target = false,
				player = false,
				mouseover = false,
				focus = false,
			},
		},
		["Mass Entanglement"] = {
			override = "debuff",
			flashWhen = {
				missingFlash = false,
				
				expire = false,
				expireTime = 0,
				
				stack = false,
				stackCount = 0,
				
				missing = {},
				present = {},
				
				health = false,
				healthBelow = 0,
			},
			displayAs = {"Entangling Roots"},
			units = {
				target = false,
				player = false,
				mouseover = false,
				focus = false,
			},
		},
	},
}

actionAura.spellDefaults = {
	override = "ignore",
	auraPriority = true,
	displayAs = {},
	
	flashWhen = {
		missingFlash = false,
		
		expire = false,
		expireTime = 0,
		
		stack = false,
		stackCount = 0,
		stackStyle = "Aura Above or Equal",
		
		missing = {},
		present = {},
		
		health = false,
		healthBelow = 0,
	},
	
	units = {
		target = false,
		player = false,
		mouseover = false,
		focus = false,
	},
	harm = {
		target = false,
		player = false,
		mouseover = false,
		focus = false,
	},
}

--Define the locals
local possibleUnits = {
		"mouseover",
		"target",
		"focus" ,
		"player",
 }

local function HarmfulUnitIsPresent(unit)
	if (UnitExists(unit) == true)
	and(UnitIsDeadOrGhost(unit) ~= true)
	and(UnitCanAttack(unit, "player") == true) then
		return true
	end
end

local function HelpfulUnitIsPresent(unit)
	if (UnitExists(unit) == true)
	and(UnitIsDeadOrGhost(unit) ~= true)
	and(UnitCanAttack(unit, "player") ~= true) then
		return true
	end
end

local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

local GetUnit = {
	HARMFUL = function(auraName)
		local unit
		local sets = auraName and actionAura:Get("spells")[auraName]
		
		if sets then
			for i, possibleUnit in pairs(possibleUnits) do
				if sets.harm[possibleUnit] == false then
					if HarmfulUnitIsPresent(possibleUnit) then
						unit = possibleUnit
						break
					end
				end
			end
		else
			for i, possibleUnit in pairs(possibleUnits) do
				if actionAura:Get("ignoreHarm_"..possibleUnit) ~= true then
					if HarmfulUnitIsPresent(possibleUnit) then
						unit = possibleUnit
						break
					end
				end
			end
		end
				
		return unit
	end,
	HELPFUL = function(auraName)
		local unit
		local sets = auraName and actionAura:Get("spells")[auraName]
		
		if sets then
			for i, possibleUnit in pairs(possibleUnits) do
				if sets.units[possibleUnit] == false then
					if HelpfulUnitIsPresent(possibleUnit) then
						unit = possibleUnit
						break
					end
				end
			end
		else
			for i, possibleUnit in pairs(possibleUnits) do
				if actionAura:Get("ignoreHelp_"..possibleUnit) ~= true then
					if HelpfulUnitIsPresent(possibleUnit) then
						unit = possibleUnit
						break
					end
				end
			end
		end
	
		return unit
	end,
}

local isUnitPlayer = {
	player = true,
	vehicle = true,
	pet = true,
}

local auraColor = {
	HELPFUL = {0,1,0,1},
	HARMFUL = {1,0,0,1},
	[""] = {1,1,1,1},
}

--Datas Source
local dataControl = CreateFrame("Frame")
dataControl.Auras = {}

local lastUnit = {}
local function UpdateSpells(unit, filter)
	if not (unit and filter) then
		lastUnit[filter] = nil
		return
	end
	if lastUnit[filter] ~= unit then
		dataControl.Auras = {}
	end
	
	local index = 1
	local name, icon, count, dispelType, duration, expirationTime, source, _, _, spellId = UnitAura(unit, index, filter) 
	
	while name do
		if isUnitPlayer[source] then
			dataControl.Auras[name] = dataControl.Auras[name] or {}
			local details = dataControl.Auras[name]
			
			details.name = name
			details.duration = duration
			details.expirationTime = expirationTime
			details.source = source
			details.dispelType = dispelType
			details.unit = unit
			details.filter = filter
			details.count = count
			details.spellId = spellId
		end
		index = index + 1
		name, icon, count, dispelType, duration, expirationTime, source = UnitAura(unit, index, filter) 
	end
	lastUnit[filter] = unit
end

dataControl:SetScript("OnUpdate", function()
	for i, unit in pairs(possibleUnits) do
		local enemy = HarmfulUnitIsPresent(unit)
		if enemy then
			UpdateSpells(unit, "HARMFUL")
			break
		end
	end
	for i, unit in pairs(possibleUnits) do
		local friend = HelpfulUnitIsPresent(unit)
		if friend then
			UpdateSpells(unit, "HELPFUL")
			break
		end
	end
end)

--The Machinery!
function actionAura:GetActionIndex(actionButton)
	local name = actionButton.name or actionButton:GetName()	
	if type(name) == "string" and name and string.find(name, 'BT4Button', 1) then
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

	return filter and GetUnit[filter](auraName)
end

function actionAura:GetFilter(spellName)
	if not spellName then
		return
	end
	local filter = IsHarmfulSpell(spellName) and "HARMFUL" or IsHelpfulSpell(spellName) and "HELPFUL" or "HARMFUL"

	local filterOverride = self:Get("filterOverride")

	if actionAura:Get("spells")[spellName] then
		local override = actionAura:Get("spells")[spellName].override
		if override == "ignore" then
			return
		else
			filter = override == "debuff" and "HARMFUL" or override == "buff" and "HELPFUL"
		end
	elseif tContains(filterOverride.debuff, spellName) then
		filter = "HARMFUL"
	elseif tContains(filterOverride.buff, spellName) then
		filter = "HELPFUL"
	end

	return filter
end

function actionAura:GetAuraDetails(spellName, actionType, actionID)
	--Check for spell Overrides, if found, return them instead

	--spell Specific overrides
	if spellName and actionAura:Get("spells")[spellName] and (#actionAura:Get("spells")[spellName].displayAs > 0) then
		for i, overRideSpellName in pairs(actionAura:Get("spells")[spellName].displayAs) do
			if overRideSpellName then
				local details = dataControl.Auras[overRideSpellName]
				if details then
					return details.name, details.duration, details.expirationTime, details.source, details.filter
				end
			end
		end
	end

	--Maybe Delete Soon: Mass override List
	if spellName and actionAura:Get("translations")[spellName] and (#actionAura:Get("translations")[spellName] > 0) then
		for i, overRideSpellName in pairs(actionAura:Get("translations")[spellName]) do
			if overRideSpellName then
				local details = dataControl.Auras[overRideSpellName]
				if details then
					return details.name, details.duration, details.expirationTime, details.source, details.filter
				end
			end
		end
	end
	
	if spellName then
		local details = dataControl.Auras[spellName]
		if details then
			return details.name, details.duration, details.expirationTime, details.source, details.filter
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
		
		local ignore = actionAura:Get("filterOverride").ignore

		if (spellName and tContains(ignore, spellName)) or (auraName and tContains(ignore, auraName)) then
			return
		end
		
		
		if not self:Get("personalAurasOnly") == true then
			source = "player"
		end
		
		if auraName and isUnitPlayer[source] then
			local spellStart, spellDuration = GetSpellCooldown(spellName)
			return auraName, filter, auraExpireTime, auraDuration, spellStart or 0, spellDuration or 0
		end
	end
end

local allActionButtons = {}

function actionAura:RegisterButton(actionButton)
	if actionButton and actionButton.auraCooldown == nil and not tContains(allActionButtons, actionButton) then
		tinsert(allActionButtons, actionButton)
		local name = actionButton.name or actionButton:GetName()
		actionButton.spellCooldown = name and _G[name .. 'Cooldown'] or actionButton.cooldown -- catches more things.
		actionButton.auraCooldown = CreateFrame('Cooldown', nil, actionButton, 'CooldownFrameTemplate'); do
			actionButton.auraCooldown:SetAllPoints(actionButton.icon)
			actionButton.auraCooldown.statusGlow = actionButton.auraCooldown:CreateTexture(nil, 'OVERLAY', 2)
			actionButton.auraCooldown.statusGlow:SetAllPoints(actionButton.icon)
			actionButton.auraCooldown.statusGlow:SetAtlas("bags-glow-white")
		end
		
		--never show both cooldown textures at the same time.
		--Using (:SetAlpha) instead of (:Show) and (:Hide).
		--If using OmniCC, cooldown text is lost with (:Hide) and (:Show).
		actionButton.auraCooldown:SetScript("OnShow", function()
			actionButton.spellCooldown:SetAlpha(0)
		end)

		actionButton.auraCooldown:SetScript("OnHide", function()
			actionButton.spellCooldown:SetAlpha(1)
		end)
		
		actionButton.spellCooldown:SetScript("OnShow", function()
			if actionButton.auraCooldown:IsShown() then
				actionButton.spellCooldown:SetAlpha(0)
			end
		end)
		
		actionAura:RegisterButtonGlow(actionButton)
		
	end
end

function actionAura:SetAuraCooldown(actionButton, filter, expireTime, duration)
	self:RegisterButton(actionButton)

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
	
	local sets = actionAura:Get("spells")[auraName]
	
	local auraPriority = sets and sets.auraPriority and actionAura:Get("prioritizeAura") == true or auraLongerThanCooldown
	
	if hasAuraTimer and (auraPriority) then
		self:SetAuraCooldown(actionButton, filter, auraExpireTime, auraDuration)
	elseif actionButton.auraCooldown and actionButton.auraCooldown:IsShown() then
		actionButton.auraCooldown:SetCooldown(0, 0)
		actionButton.auraCooldown:Hide()
	end
end

function actionAura.FindAuraByName(spellName, unit, filter)
	local details = dataControl.Auras[spellName]
	if details then
		return details.name, details.duration, details.expirationTime, details.source, details.filter, details.count
	end
end

local flashDrive = CreateFrame("Frame")

local flashWhen = {
		health = false,
		healthBelow = 0,

		missingFlash = false,
		expire = false,
		expireTime = 0,
		
		stack = false,
		stackCount = 0,
		stackStyle = {
			"Aura Above",
			"Spell Above",
			"Aura Above or Equal",
			"Spell Above or Equal",
			"Aura Below",
			"Spell Below",
			"Aura Below or Equal",
			"Spell Below or Equal",
			"Aura Exact",
			"Spell Exact",
		},
		missing = {},
		present = {},
		
		missingFlash = false,
		
	}

local tracker = {}

local function GetButtonSpellName(button)
	local actionIndex = actionAura:GetActionIndex(button)
	local actionType, actionID, subType, globalID = GetActionInfo(actionIndex) --Returns information about a specific action.
	local spellName

	if actionType then
		local metric = actionType..actionID

		local spellID

		if tracker[metric] then
			spellName, spellID = unpack(tracker[metric])
		elseif actionType == 'spell' then
			if actionID and actionID > 0 then
				spellName, _, _, _, _, _, _, spellID = GetSpellInfo(actionID)
			elseif globalID then
				spellName, _, _, _, _, _, _, spellID = GetSpellInfo(globalID)
			end
		elseif actionType == 'item' then
			spellName, spellID = GetItemSpell(actionID)
		elseif actionType == 'macro' then
			actionID = GetMacroSpell(actionID)
			if actionID then
				spellName, _, _, _, _, _, _, spellID = GetSpellInfo(actionID)
			end
		end
		
		tracker[metric] = {spellName, spellID}
		
		return spellName, actionType, spellID or actionID
	end
end

local lastGCD

local function shouldAuraPing(spellName, unit, filter, flashSettings, count, lastGCD, spellExpire, shouldPing)
	local auraCount
	local name, duration, expireTime, _, _, auraCount = actionAura.FindAuraByName(spellName, unit, filter)
	
	if string.find(flashSettings.stackStyle or "Aura Above or Equal", "Aura", 1) then
		count = (auraCount and auraCount ~= 0) and auraCount or count
	end
	
	local duration = duration ~= 0 and duration or nil

	if duration and duration > lastGCD and name and expireTime then
		spellExpire = expireTime - GetTime()
	end
	
	return shouldPing, count, spellExpire, name
end

--[[Flash Logic Explanation
	
	A: Get Details
		1: Determine type of spell
			-Debuff or Buff
		2: Find applicable friendly targetUnit
		3: Find applicable enemy targetUnit
	
	B:Priority for flashes
		1: Health below specified amount 
		2: Aura/Spell expire time
		3: Aura Missing
		4: Aura Present
		5: Spell is Castable/ Not on cooldown, or Aura is not present
		6: Aura/Spell Stack Count
	
	
--]]

local function TryPing(button, spellName, actionType, spellID, spellSettings, flashSettings)
	local shouldPing = false
	
	 --Does this spell have specific settings?
	if spellSettings then
		--Spell Specific Settings have been found!
		--1A
		local override = spellSettings.override or IsHarmfulSpell(spellName) and "debuff" or IsHelpfulSpell(spellName) and "buff" or "debuff"

		local unit; do--1B
			for i, b in pairs(possibleUnits) do
				if spellSettings.units[b] == false then
					--This unit is not being ignored!
					if (override == "debuff" and HarmfulUnitIsPresent(b))
					or (override == "buff"   and HelpfulUnitIsPresent(b)) then
						unit = b
					end
				end
			end
		end

		local reactionUnit; do--1C
			for i, b in pairs(possibleUnits) do
				if spellSettings.harm[b] == false then
					--This unit is not being ignored!
					if (HarmfulUnitIsPresent(b)) then
						reactionUnit = b
					end
				end
			end
		end
	
--1. Health
		if flashSettings.health == true and reactionUnit then
			local value, high = UnitHealth(reactionUnit), UnitHealthMax(reactionUnit) 
			if (value / high) * 100 <= flashSettings.healthBelow then
				shouldPing = true
			end
		end
		
		--combatRestrict is not enabled, or we are in combat!
		local combat = flashSettings.combatOnly ~= true and true or InCombatLockdown() 
		
		--What type of spell are we tracking?
		local filter = override == "debuff" and "HARMFUL" or override == "buff" and "HELPFUL"

		
		do --flashSettings.missingFlash = false, flashSettings.expire = false, flashSettings.expireTime = 0,
		
			local spellStart, spellDuration = GetSpellCooldown(spellName)
			spellStart = spellStart ~= 0 and spellStart
			spellDuration = spellDuration ~= 0 and spellDuration

			local count = GetSpellCharges(spellName)

			local spellExpire = spellStart and spellStart + spellDuration - GetTime()	

			if unit then
				local name; do
					if not spellDuration or (spellDuration <= lastGCD) == true then
						--there is no cooldown or it's less than the Global Cooldown
						shouldPing, count, spellExpire, name = shouldAuraPing(spellName, unit, filter, flashSettings, count, lastGCD, spellExpire, shouldPing)
						
						for i, spellName in pairs(spellSettings.displayAs) do
							shouldPing, count, spellExpire, name = shouldAuraPing(spellName, unit, filter, flashSettings, count, lastGCD, spellExpire, shouldPing)
						end

						if combat and flashSettings.expire == true then
							if not spellExpire or spellExpire <= flashSettings.expireTime then
								--the spell was on cooldown or had an aura timer, and it's time is about to expire.
								shouldPing = true
							end
						end
						
						-- count, spellExpire, shouldPing, name
					end
				end
				
				if not name and (not spellExpire or spellExpire <= lastGCD) and combat and flashSettings.missingFlash == true then
					--this spell is not present on target, and the spell can be casted
					shouldPing = true
				end
		
				if not spellExpire then --Don't highlight a spell, unless it can be casted.
					for i, missingSpell in pairs(flashSettings.missing) do
						local name = actionAura.FindAuraByName(missingSpell, unit)--, filter)); --We don't care what type of spell it is, react to it's existence
						if not name then
							--one the spells on this spell's missing list was not found
							shouldPing = true
						end
					end
					for i, presentSpell in pairs(flashSettings.present) do
						local name  = actionAura.FindAuraByName(presentSpell, unit)--, filter));
						if name then
							--one the spells on this spell's present list was found
							shouldPing = true
						end
					end
				end
			end
			
			if combat and flashSettings.stack == true and count and count ~= 0 then
				local style = gsub(gsub(flashSettings.stackStyle or "Aura Above or Equal", "Aura ", ""), "Spell ", "")
						
				shouldPing = style == "Above" and count > flashSettings.stackCount
						  or style == "Above or Equal" and count >= flashSettings.stackCount
						  or style == "Below" and count < flashSettings.stackCount
						  or style == "Below or Equal" and count <= flashSettings.stackCount
						  or style == "Exact" and count == flashSettings.stackCount
						  or shouldPing
			end

		end
		
		actionAura:Ping(button, shouldPing, spellName)
	end
end

local function FlashButton(button)
	local spellName, actionType, spellID = GetButtonSpellName(button)
	local spellSettings  = actionAura:Get("spells")[spellName]
	local flashSettings = spellSettings and spellSettings.flashWhen --Flash details
	if spellSettings then
		TryPing(button, spellName, actionType, spellID, spellSettings, flashSettings)
		for i, spellName in pairs(spellSettings.displayAs) do
			local spellType, id = GetSpellBookItemInfo(spellName)
		
			TryPing(button, spellName, actionType, id, spellSettings, flashSettings)
		end
	end
	
end
flashDrive:SetScript("OnUpdate", function()
	
	local buttons = actionAura.GetButtons and actionAura:GetButtons()
	if not buttons or #buttons == 0 then
		return
	end
	
	--Global Cooldown, for detecting when a spell is on cooldown
	local _, GCD, enabled, modRate = GetSpellCooldown(61304)
	lastGCD = GCD ~= 0 and GCD or lastGCD or 0

	local shown = actionAura.optionsPanel and actionAura.optionsPanel:IsShown() == true and actionAura.optionsPanel.page == 5 or nil

	if not shown then
		for i, button in pairs(buttons) do
			FlashButton(button)
		end
	end
end)


local overlayed = {}

local function IsOverlayed(spellName, spellID)
	return overlayed[spellName] or spellID and IsSpellOverlayed(spellID)
end

local function UpdateOverlayGlow(self)
	local spellType, id, subType  = GetActionInfo(self.action);
	local spellName = id and GetSpellInfo(id)
	
	if ( spellType == "spell" and (IsOverlayed(spellName, id)) ) then
		local _= not self.overlay and ActionButton_ShowOverlayGlow(self);
	elseif ( spellType == "macro" ) then
		local spellId = GetMacroSpell(id);
		spellName = spellId and GetSpellInfo(spellId) or spellName
		if ( spellId and (IsOverlayed(spellName, spellId)) ) then
			local _= not self.overlay and ActionButton_ShowOverlayGlow(self);
		else
			ActionButton_HideOverlayGlow(self);
		end
	else
		ActionButton_HideOverlayGlow(self);
	end
end

function actionAura:RegisterButtonGlow(button)
	button.UpdateOverlayGlow = UpdateOverlayGlow
end

function actionAura:Ping(button, shouldPing, spellName)
	if spellName then
		overlayed[spellName] = shouldPing == true or nil
	end
	
	local spellType, id, subType  = GetActionInfo(button.action);
	local spellName = id and GetSpellInfo(id)
	
	if ( spellType == "spell" and (overlayed[spellName] or IsSpellOverlayed(id)) ) then
		ActionButton_ShowOverlayGlow(button);
	elseif ( spellType == "macro" ) then
		local spellId = GetMacroSpell(id);
		spellName = spellId and GetSpellInfo(spellId) or spellName
		if ( spellId and (overlayed[spellName] or IsSpellOverlayed(spellId)) ) then
			ActionButton_ShowOverlayGlow(button);
		else
			ActionButton_HideOverlayGlow(button);
		end
	else
		ActionButton_HideOverlayGlow(button);
	end
end

function actionAura:PingSpell(spellNameToMatch, shouldPing)
	local buttons = actionAura:GetButtons()
	if not buttons or #buttons == 0 then
		return
	end

	for i, actionButton in pairs(buttons) do
		local actionIndex = actionAura:GetActionIndex(actionButton)
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
		
		if spellName and spellNameToMatch and spellNameToMatch == spellName then
			actionAura:Ping(actionButton, shouldPing, spellName)
		end
	end
end

--Build the Options Menu
local toolbelt = LibStub('toolbelt')
function actionAura:ShowOptions()
	if not self.optionsPanel then
		self.optionsPanel = toolbelt.NewMenu({title = "Options",
			DisplayTitle = "Action Aura",
			pages = {
				{name = "Basic",
					tooltip = "These Options apply to all buffs and debuffs.",
					options = {
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
						{
							title = "Select Direct from Bars",
							tooltip = "Click to enter text, then click on any button on your action bars to quickly add them to different list in this addon.",
							kind = "CheckButton",
							OnShow = function(self)
								self:SetChecked(actionAura.EnableLinks)
							end,
							OnClick = function(self)
								actionAura.EnableLinks = self:GetChecked()
							end,
						},
					},
				},
				{name = "Units",
					tooltip = "Ignore all buffs or debuffs for a specific unit.",		
					options = {
						{
							kind = "TitleLine",
							title = "Ignore Unit Buffs",
							skipping = "buffs",
							tooltip = "Click to toggle display of this section.",
						},
						{
							title = "Mouseover",
							tooltip = "Ignore Buffs for Mouseover.",
							kind = "CheckButton",
							skipper = "buffs",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHelp_mouseover"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHelp_mouseover", self:GetChecked())
							end,
						},
						{
							title = "Target",
							tooltip = "Ignore Buffs for Target.",
							kind = "CheckButton",
							skipper = "buffs",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHelp_target"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHelp_target", self:GetChecked())
							end,
						},
						{
							title = "Focus",
							tooltip = "Ignore Buffs for Focus.",
							kind = "CheckButton",
							skipper = "buffs",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHelp_focus"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHelp_focus", self:GetChecked())
							end,
						},
						{
							title = "Player",
							tooltip = "Ignore Buffs for Player.",
							kind = "CheckButton",
							skipper = "buffs",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHelp_player"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHelp_player", self:GetChecked())
							end,
						},
						{
							kind = "TitleLine",
							title = "Ignore Unit Debuffs",
							skipping = "debuff",
							tooltip = "Click to toggle display of this section.",
						},
						{
							title = "Mouseover",
							tooltip = "Ignore Debuffs for Mouseover.",
							kind = "CheckButton",
							skipper = "debuff",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHarm_mouseover"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHarm_mouseover", self:GetChecked())
							end,
						},
						{
							title = "Target",
							tooltip = "Ignore Debuffs for Target.",
							kind = "CheckButton",
							skipper = "debuff",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHarm_target"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHarm_target", self:GetChecked())
							end,
						},
						{
							title = "Focus",
							tooltip = "Ignore Debuffs for Focus.",
							kind = "CheckButton",
							skipper = "debuff",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHarm_focus"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHarm_focus", self:GetChecked())
							end,
						},
						{
							title = "Player",
							tooltip = "Ignore Debuffs for Player.",
							kind = "CheckButton",
							skipper = "debuff",
							OnShow = function(self)
								self:SetChecked(actionAura:Get("ignoreHarm_player"))
							end,
							OnClick = function(self)
								actionAura:Set("ignoreHarm_player", self:GetChecked())
							end,
						},
					},
				},
				{name = "Translations",
					tooltip = [[Some buffs and debuffs may not mach the name of the spell that casts them. If this happens, the aura timer will not display on the action button.
To fix this, type the name of the spell into the "Original" line and press Enter and then type the name of the aura into the "Translation" line and press Enter.]],
					options = {
						{
							kind = "ListFrame",
							listName = "Original",
							addText = "Translation",
							
							
							initialList = function(self)
								self._list = self._list or {} 
								local list = self._list
								wipe(list)
								
								for key, b in pairs(actionAura:Get("translations")) do
									tinsert(list, key)
								end

								return list
							end,
							GetList = function(listName)
								return actionAura:Get("translations")[listName]
							end,
							formatText = GetSpellNameFromLink,
							numButtons = 7,
							allowDelete = true,
							DeleteEntry = function(text)
								actionAura:Get("translations")[text] = nil
							end,
							AddEntry = function(text)
								actionAura:Get("translations")[text] = actionAura:Get("translations")[text] or {}
							end,
						},
					},
				},
				{name = "Overrides",
					tooltip = [[If a spell button is not showing an aura timer, you can attempt to force it to show.
Select an "Override Aura Type", and type the name of the spell into the "Spell Name" line and press enter.]],
					options = {
						{
							kind = "ListFrame",
							listName = "Override Aura Type",
							addText = "Spell Name",
							initialList = {"Debuff", "Buff", "Ignore"},
							GetList = function(listName)
								return actionAura:Get("filterOverride")[string.lower(listName)]
							end,
							formatText = GetSpellNameFromLink,
							numButtons = 7,
						},
					},
				},
			}
		})
		
		--custom Pages: panel:AddPage(pageDetails)
		
		local spellSpecific = self.optionsPanel:AddPage({name = "Spell Specific",
		tooltip = "Program each spell individually.",})

		local updates = {}
		
		local box = spellSpecific.New.DropDownEditBox({title = "Spell", allowDelete = true}); do
			function box.GetList()
				box._list = box._list or {} 
				local list = box._list
				wipe(list)
				for key, b in pairs(actionAura:Get("spells")) do
					tinsert(list, key)
					actionAura:PingSpell(key)
					
					
					
					
				end
				return list
			end
			
			box.OnShow = function()
				box.list = box.GetList()
				
				local t = box.text:GetText()
				local text = t ~= "" and t or box.list[1]
								
				box.Update(text)
				return box.text:SetText(text or "")
			end
			
			box.AddEntry = function(text)
				if text then
					if not actionAura:Get("spells")[text] then
						actionAura:Get("spells")[text] = actionAura.spellDefaults
						
						local auraType = IsHarmfulSpell(text) and "debuff" or IsHelpfulSpell(text) and "buff" or "ignore"
						
						actionAura:Get("spells")[text].override = auraType
						
					end					
				end
				box.GetList()
				box.Update(text)
			end
			
			function box.DeleteEntry(entry)
				actionAura:Get("spells")[entry] = nil
				box.Update()
			end
			
			box.Update = function(text)
				box.GetList()
				for i, b in pairs(updates) do
					b(text)
				end

				if box:IsVisible() then
					for i, item in pairs(box.list) do
						actionAura:PingSpell(item, item == text)
					end
				end
			end
			
			box.Clear = function()
				if box.list then
					for i, item in pairs(box.list) do
						actionAura:PingSpell(item, false)
					end
				end
			end
		end
		
		spellSpecific.New.TitleLine({title = "Display As:", skipping = "DisplayAs"})
		
		local box = spellSpecific.New.DropDown("Status"); do
			box.skipper = "DisplayAs"
			box.list = {"Buff", "Debuff", "Ignore"}
			box:SetHeight(25)
			box:SetPoint("Right")
			
			box.OnShow = function()
				local up = box.target and box.target.override and (box.target.override:gsub("^%l", string.upper) or box.target.override)
				box.index = up and tIndexOf(box.list, up) or 1
			
				return box.text:SetText(up or "")
			end

			box.SetValue = function(text)
				if box.target then
					box.target.override = text and string.lower(text)
				else
					box.text:SetText("")
				end
			end

			tinsert(updates, function(text)
				box.target = actionAura:Get("spells")[text]
				box.OnShow(box)
			end)
			
			if spellSpecific.Items and not tContains(spellSpecific.Items, box) then
				tinsert(spellSpecific.Items, box)
			end
		end

		local check = spellSpecific.New.CheckButton({title = "Prioritize Aura Timer",
			tooltip = "Show the Aura's timer, even if the spell's cooldown is longer.",
			skipper = "DisplayAs",
			OnShow = function(self)
				self:SetChecked(self.target and self.target.auraPriority)
			end,
			OnClick = function(self)
				if self.target then
					self.target.auraPriority = not self.target.auraPriority
				else
					self:SetChecked(false)
				end
			end,
		})

		tinsert(updates, function(text)
			check:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text])
			check.OnShow(check)
		end)
			
		local listBox = spellSpecific.New.ListBox({numButtons = 4, unset = true, addText = "Translation", skipper = "DisplayAs", tooltip = "If an aura's name does not match the name of the spell that casts it, add the aura to this list /n May be used for other shenanigans as well, figure it out.",}); do
			tinsert(updates, function(text)
				listBox.Adding = text
				if not text or not actionAura:Get("spells")[text].displayAs then
					listBox:SetList(nil, true)
					listBox.clear()
				end
				
				listBox.update(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].displayAs)
			end)				
		end

		spellSpecific.New.TitleLine({title = "Flash:", skipping = "flash"})
		
		local check = spellSpecific.New.CheckButton({title = "Flash when Missing or Castable",
			tooltip = "If this spell is not detected on target, flash the action button. |nIf this spell does not cast an aura, it will flash whenever it is not on cooldown.",
			skipper = "flash",
			OnShow = function(self)
				self:SetChecked(self.target and self.target.missingFlash)
			end,
			OnClick = function(self)
				if self.target then
					self.target.missingFlash = not self.target.missingFlash
				else
					self:SetChecked(false)
				end
			end,
		})

		tinsert(updates, function(text)
			check:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen)
			check.OnShow(check)
		end)

		local slide = spellSpecific.New.Slider({title = "Time Remaining",
			tooltip = "If this aura's time remainning is less than this amount, flash the icon.",
			skipper = "flash",
			indicatorText = "seconds",
			OnShow = function(self)
				if self.target then
					self:SetValue(self.target and self.target.expireTime or self:GetMinMaxValues())
					self:Enable()
				else
					self:SetValue(self:GetMinMaxValues())
					self:Disable()
				end
				if self.check then
					self.check:SetChecked(self.target and self.target.expire or false)
				end
			end,
			OnValueChanged = function(self)
				if self.target then
					self.target.expireTime = self:GetValue()
				end
			end,
			min = 0,
			max = 20,
			step = 1,
			checkable = true,
			SetToggle = function(self, state)
				if self.target then
					self.target.expire = state
				end
			end,
			GetToggle = function(self)
				return self.target and self.target.expire or false
			end,
		})
		
		tinsert(updates, function(text)
			slide:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen)
			slide.OnShow(slide)
		end)
			
		local slide = spellSpecific.New.Slider({title = "Stack Count",
			Absolute = true,
			tooltip = "If this aura's stack count is greater than this amount, flash the icon. (Zero = no flash)",
			skipper = "flash",
			OnShow = function(self)
				if self.target then
					self:SetValue(self.target.stackCount or self:GetMinMaxValues())
					self:Enable()
				else
					self:SetValue(self:GetMinMaxValues())
					self:Disable()
				end	
			end,
			OnValueChanged = function(self)
				if self.target then
					self.target.stackCount = self:GetValue()
				else
					self.ignore = true
				--	self:SetValue(self:GetMinMaxValues())
					self.ignore = nil
				end
			end,
			min = 0,
			max = 20,
			checkable = true,
			SetToggle = function(self, state)
				if self.target then
					self.target.stack = state
				end
			end,
			GetToggle = function(self)
				return self.target and self.target.stack or false
			end,
		})
		
		tinsert(updates, function(text)
			slide:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen)
			slide.OnShow(slide)
		end)
		
		local stackStyle = {
			"Aura Above",
			"Spell Above",
			"Aura Above or Equal",
			"Spell Above or Equal",
			"Aura Below",
			"Spell Below",
			"Aura Below or Equal",
			"Spell Below or Equal",
			"Aura Exact",
			"Spell Exact",
		}
		
	--stackStyle	
		local box = spellSpecific.New.DropDown("Stack Style"); do
			box.skipper = "DisplayAs"
			box.list = stackStyle
			box:SetHeight(25)
			box:SetPoint("Right")
			
			box.OnShow = function()
				local up = box.target and box.target.stackStyle and (box.target.stackStyle:gsub("^%l", string.upper) or box.target.stackStyle)
				box.index = up and tIndexOf(box.list, up) or 1
			
				return box.text:SetText(up or "")
			end

			box.SetValue = function(text)
				if box.target then
					box.target.stackStyle = text
				else
					box.text:SetText("")
				end
			end

			tinsert(updates, function(text)
				box.target = actionAura:Get("spells")[text].flashWhen
				box.OnShow(box)
			end)
			
			if spellSpecific.Items and not tContains(spellSpecific.Items, box) then
				tinsert(spellSpecific.Items, box)
			end
		end

		
		local slide = spellSpecific.New.Slider({title = "Health",
			indicatorText = "percent",
			tooltip = "If target's health is less than this amount, flash the icon. (Zero = no flash)",
			skipper = "flash",
			OnShow = function(self)
				if self.target then
					self:SetValue(self.target.healthBelow or self:GetMinMaxValues())
					self:Enable()
				else
					self:SetValue(self:GetMinMaxValues())
					self:Disable()
				end	
			end,
			OnValueChanged = function(self)
				if self.target then
					self.target.healthBelow = self:GetValue()
				else
					self.ignore = true
				--	self:SetValue(self:GetMinMaxValues())
					self.ignore = nil
				end
			end,
			min = 0,
			max = 100,
			checkable = true,
			SetToggle = function(self, state)
				if self.target then
					self.target.health = state
				end
			end,
			GetToggle = function(self)
				return self.target and self.target.health or false
			end,
		})
		
		tinsert(updates, function(text)
			slide:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen)
			slide.OnShow(slide)
		end)

		local listBox = spellSpecific.New.ListBox({numButtons = 4, unset = true, addText = "Missing", skipper = "flash"}); do
			listBox.Create = function(text)
				if listBox.Adding and actionAura:Get("spells")[listBox.Adding] then
					return actionAura:Get("spells")[listBox.Adding].flashWhen.missing
				end
			end
			
			tinsert(updates, function(text)
				listBox.Adding = text
				if not text or  not actionAura:Get("spells")[text].flashWhen or not actionAura:Get("spells")[text].flashWhen.missing then
					listBox:SetList(nil, true)
					listBox.clear()
				end
				
				listBox.update(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen.missing)
			end)
		end

		local listBox = spellSpecific.New.ListBox({numButtons = 4, unset = true, addText = "Present", skipper = "flash"}); do
			listBox.Create = function(text)
				if listBox.Adding and actionAura:Get("spells")[listBox.Adding].flashWhen then
					--actionAura:Get("spells")[listBox.Adding].flashWhen.present = actionAura:Get("spells")[listBox.Adding].flashWhen.present or {}
					return actionAura:Get("spells")[listBox.Adding].flashWhen.present
				end
			end
			
			tinsert(updates, function(text)
				listBox.Adding = text
				if not text or not actionAura:Get("spells")[text] or not actionAura:Get("spells")[text].flashWhen.present then
					listBox.clear()
				end
				
				listBox.update(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen.present)
			end)
		end

		
		local check = spellSpecific.New.CheckButton({title = "Combat Restrict",
			tooltip = "Resrict some flashes to only happen in combat. (Missing(self), Time Remaining and Cooldown Completes)",
			skipper = "flash",
			OnShow = function(self)
				self:SetChecked(self.target and self.target.combatOnly)
			end,
			OnClick = function(self)
				if self.target then
					self.target.combatOnly = not self.target.combatOnly
				else
					self:SetChecked(false)
				end
			end,
		})

		tinsert(updates, function(text)
			check:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].flashWhen)
			check.OnShow(check)
		end)


		spellSpecific.New.TitleLine({title = "Ignore Friendly units:", skipping = "units"})

		for i, unit in pairs(possibleUnits) do
			local check = spellSpecific.New.CheckButton({title = firstToUpper(unit), skipper = "units",
				tooltip = "Dont track any helpful information about this aura, for "..firstToUpper(unit),
				OnShow = function(self)
					self:SetChecked(self.target and self.target[unit])
				end,
				OnClick = function(self)
					if self.target then
						self.target[unit] = not self.target[unit]
					else
						self:SetChecked(false)
					end
				end,
			})

			tinsert(updates, function(text)
				check:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].units)
				check.OnShow(check)
			end)
		end	
		spellSpecific.New.TitleLine({title = "Ignore Enemy Units:", skipping = "eunits"})

		for i, unit in pairs(possibleUnits) do
			local check = spellSpecific.New.CheckButton({title = firstToUpper(unit), skipper = "eunits",
				tooltip = "Don't track any harmful information about this aura, for "..firstToUpper(unit),
				OnShow = function(self)
					self:SetChecked(self.target and self.target[unit])
				end,
				OnClick = function(self)
					if self.target then
						self.target[unit] = not self.target[unit]
					else
						self:SetChecked(false)
					end
				end,
			})

			tinsert(updates, function(text)
				check:SetTarget(text and actionAura:Get("spells")[text] and actionAura:Get("spells")[text].harm)
				check.OnShow(check)
			end)
		end	

		box.OnShow(box)

		spellSpecific.Layout()
	end

	self.optionsPanel:Show()
end

actionAura:AddCmd("default", function(self, ...)
	self:ShowOptions(...)
end)

local LAB10

local bars = {
	{"ActionButton", 1, 12}, --"ActionButton", --12
	{"MultiBarRightButton", 25, 36}, --"MultiBarRightButton", --12
	{"MultiBarLeftButton", 37, 48}, --"MultiBarLeftButton", --12
	{"MultiBarBottomRightButton", 49, 60}, --"MultiBarBottomRightButton", --12
	{"MultiBarBottomLeftButton", 61, 72}, --"MultiBarBottomLeftButton", --12
}

function actionAura:GetButtons(shouldReload)
	if #allActionButtons == 0 or shouldReload then
		if Dominos then
			for i, actionButton in pairs(Dominos.ActionButtons) do
				actionAura:RegisterButton(actionButton)
			end
		end
		
		if Bartender4 then
			LAB10 = LAB10 or LibStub("LibActionButton-1.0")
			for actionButton in next, LAB10:GetAllButtons() do
				actionAura:RegisterButton(actionButton)
			end
		end
		
		for _, barDetails in pairs(bars) do
			local name, low, high = unpack(barDetails)
			
			for i = low, high do
				actionAura:RegisterButton(_G[name..i])
			end
		end
	end
	return allActionButtons
end