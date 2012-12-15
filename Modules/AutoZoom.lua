
local AutoZoom = Chinchilla:NewModule("AutoZoom", "AceHook-3.0", "LibShefkiTimer-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

AutoZoom.displayName = L["Auto zoom"]
AutoZoom.desc = L["Automatically zoom out after a specified time."]


function AutoZoom:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("AutoZoom", {
		profile = {
			time = 20,
			enabled = true,
		}
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


function AutoZoom:OnEnable()
	timerID = self:ScheduleTimer("ZoomOut", self.db.profile.time)
	self:SecureHook(Minimap, "SetZoom", "Minimap_SetZoom")
end


local timerID
function AutoZoom:Minimap_SetZoom(_, zoomLevel, ignore)
	if zoomLevel == 0 or ignore then return end

	if timerID then
		self:CancelTimer(timerID, true)
		timerID = nil
	end

	timerID = self:ScheduleTimer("ZoomOut", self.db.profile.time)
end

function AutoZoom:ZoomOut()
	Minimap:SetZoom(0, true)
	timerID = nil
end


function AutoZoom:GetOptions()
	return {
		time = {
			name = L["Time to zoom"],
			desc = L["Set the time it takes between manually zooming in and automatically zooming out"],
			type = 'range',
			min = 1,
			max = 60,
			step = 1,
			get = function(info)
				return self.db.profile.time
			end,
			set = function(info, value)
				self.db.profile.time = value
			end,
		},
	}
end
