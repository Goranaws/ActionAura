local AddonName = ...
local actionAura  = LibStub("AceAddon-3.0"):GetAddon(AddonName)

function actionAura:OnInitialize()
	if not self.eventHandler then
		self:RegisterVariables(reset)

		hooksecurefunc("ActionButton_UpdateCooldown", function(actionButton)
			if self.UpdateActionAura then
				self:UpdateActionAura(actionButton)
			end
		end)
		
		if CooldownFrame_Set then
			--Bartender4 Support
			hooksecurefunc("CooldownFrame_Set", function(cd)
				if self.UpdateActionAura then
					self:UpdateActionAura(cd:GetParent())
				end
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
			if self.GetButtons then
				for _, button in pairs(self:GetButtons()) do
					self:UpdateActionAura(button)
				end
			end
		end)
	end
end
