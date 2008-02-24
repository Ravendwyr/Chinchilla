local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
Chinchilla:SetModuleDefaultState("Expander", false)
local Chinchilla_Expander = Chinchilla:NewModule("Expander", "LibRockTimer-1.0")
local self = Chinchilla_Expander
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Expander.desc = L["Show direction indicators on the minimap"]

BINDING_HEADER_CHINCHILLA = "Chinchilla"
BINDING_NAME_CHINCHILLA_EXPANDMINIMAP = L["Expand minimap"]

function Chinchilla_Expander:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Expander")
	Chinchilla:SetDatabaseNamespaceDefaults("Expander", "profile", {
		key = false,
		scale = 3,
	})
end

local frame
local minimap
function Chinchilla_Expander:OnEnable()
	if not frame then
		frame = CreateFrame("Button", "Chinchilla_Expander_Button")
		frame:SetScript("OnMouseDown", function(this, button)
			if not self:IsActive() then
				return
			end
			
			MinimapCluster:Hide()
			if not minimap then
				minimap = CreateFrame("Minimap", "Chinchilla_Expander_Minimap", UIParent)
				minimap:SetWidth(160)
				minimap:SetHeight(160)
				minimap:SetScale(self.db.profile.scale)
				minimap:SetPoint("CENTER")
				minimap:SetFrameStrata("TOOLTIP")
				minimap:EnableMouse(false)
				minimap:EnableMouseWheel(false)
				minimap:EnableKeyboard(false)
			end
			minimap:Show()
			local z = minimap:GetZoom()
			if z > 2 then
				minimap:SetZoom(z-1)
			else
				minimap:SetZoom(z+1)
			end
			minimap:SetZoom(z)
		end)
		frame:SetScript("OnMouseUp", function(this, button)
			if not self:IsActive() then
				return
			end
			
			minimap:Hide()
			MinimapCluster:Show()
			local z = Minimap:GetZoom()
			if z > 2 then
				Minimap:SetZoom(z-1)
			else
				Minimap:SetZoom(z+1)
			end
			Minimap:SetZoom(z)
		end)
	end
	if self.db.profile.key then
		self:AddTimer(0, function()
			SetBindingClick(self.db.profile.key, "Chinchilla_Expander_Button")
		end)
	end
end

function Chinchilla_Expander:OnDisable()
end


Chinchilla_Expander:AddChinchillaOption({
	name = L["Expander"],
	desc = Chinchilla_Expander.desc,
	type = 'group',
	args = {
		key = {
			name = L["Keybinding"],
			desc = L["The key to press to show the expanded minimap"],
			type = 'keybinding',
			get = function()
				return self.db.profile.key
			end,
			set = function(value)
				SetBinding(self.db.profile.key)
				self.db.profile.key = value
				if frame and value then
					SetBindingClick(value, "Chinchilla_Expander_Button")
				end
			end,
		},
		scale = {
			name = L["Size"],
			desc = L["The size of the expanded minimap"],
			type = 'number',
			min = 0.5,
			max = 8,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
			get = function()
				return self.db.profile.scale
			end,
			set = function(value)
				self.db.profile.scale = value
				if minimap then
					minimap:SetScale(value)
				end
			end
		}
	}
})