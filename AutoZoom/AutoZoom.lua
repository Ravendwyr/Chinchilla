local VERSION = tonumber(("$Revision$"):match("%d+"))

local Chinchilla = Chinchilla
local Chinchilla_AutoZoom = Chinchilla:NewModule("AutoZoom", "LibRockTimer-1.0", "LibRockHook-1.0")
local self = Chinchilla_AutoZoom
if Chinchilla.revision < VERSION then
	Chinchilla.version = "1.0r" .. VERSION
	Chinchilla.revision = VERSION
	Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")
end
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_AutoZoom.desc = L["Automatically zoom out after a specified time."]

function Chinchilla_AutoZoom:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("AutoZoom")
	Chinchilla:SetDatabaseNamespaceDefaults("AutoZoom", "profile", {
		time = 20,
	})
end

local frame
local nextZoomOutTime = 0
function Chinchilla_AutoZoom:OnEnable()
	if not frame then
		frame = CreateFrame("Frame")
		frame:SetScript("OnUpdate", function(this, elapsed)
			local currentTime = GetTime()
			if nextZoomOutTime <= currentTime then
				if Minimap:GetZoom() > 0 then
					Minimap_ZoomOut()
					nextZoomOutTime = currentTime -- reset and do it every frame
				else
					this:Hide()
				end
			end
		end)
	end
	frame:Show()
	self:AddSecureHook(Minimap, "SetZoom", "Minimap_SetZoom")
end

function Chinchilla_AutoZoom:OnDisable()
	frame:Hide()
end

function Chinchilla_AutoZoom:Minimap_SetZoom(...)
	frame:Show()
	nextZoomOutTime = GetTime() + self.db.profile.time
end

Chinchilla_AutoZoom:AddChinchillaOption({
	name = L["Auto zoom"],
	desc = Chinchilla_AutoZoom.desc,
	type = 'group',
	args = {
		time = {
			name = L["Time to zoom"],
			desc = L["Set the time it takes between manually zooming in and automatically zooming out"],
			type = 'range',
			min = 1,
			max = 60,
			step = 0.1,
			bigStep = 1,
			get = function()
				return self.db.profile.time
			end,
			set = function(value)
				self.db.profile.time = value
			end
		}
	}
})
