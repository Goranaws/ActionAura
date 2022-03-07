local AddonName = ...
local variables = "actionAura_SV"
local actionAura  = LibStub("AceAddon-3.0"):GetAddon(AddonName)

	local commands = {}
	
	function actionAura:AddCmd(cmd, func)
		commands[cmd] = func
	end

	actionAura:AddCmd("reset", function(self, ...)
		self:Reset(...)
		if self.optionsPanel then
			self.optionsPanel.Refresh(...)
		end
	end)


	function actionAura:RunCommand(Cmd, ...)
		local cmdStrings = {string.split(" ", string.lower(Cmd))}
		
		for cmd, func in pairs(commands) do
			if cmdStrings[1] == cmd then
				tremove(cmdStrings, 1)
				return func(self, unpack(cmdStrings))
			end
		end
		
		if commands["default"] then
			commands["default"](self)
		end
		
		-- if string.find(cmdStrings, "reset", 1) then
			-- self:Reset()
			-- if self.optionsPanel then
				-- self.optionsPanel.Refresh()
			-- end
		-- else
			-- actionAura:ShowOptions()
		-- end
	end
	SlashCmdList[string.upper(AddonName)] = function(Cmd, ...)
		actionAura:RunCommand(Cmd, ...)
	end

	_G["SLASH_".. string.upper(AddonName) .."1"] = "/aaura"
	_G["SLASH_".. string.upper(AddonName) .."2"] = "/"..string.lower(AddonName)