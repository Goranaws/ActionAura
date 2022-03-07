local AddonName = ...
local actionAura = LibStub("AceAddon-3.0"):NewAddon(AddonName)
local variables = "actionAura_SV"

--settings access
local function deepRegister(source, dest)
	for key, value in pairs(source) do
		if type(value) == table then
			dest[key] = dest[key] or {}
			deepRegister(value, dest[key])
		else
			dest[key] = dest[key] or value
		end
	end
end

function actionAura:RegisterVariables(reset)
	--Either create from scratch, or add new defaults to existing settings 
	if reset == true then
		_G[variables] = nil
	end
	_G[variables] = _G[variables] or {}
	if self.defaults then
		deepRegister(self.defaults, _G[variables])
	end
	
	for i, spellSettings in pairs(_G[variables].spells) do
		deepRegister(self.spellDefaults, spellSettings)
		spellSettings.poop = nil
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

		return setting
	else
		return (not key and _G[variables]) or _G[variables][key] or self.defaults and self.defaults[key]
	end
end

function actionAura:Set(key, value)
	_G[variables][key] = value
end

function actionAura:Reset()
	self:RegisterVariables(true)
end


