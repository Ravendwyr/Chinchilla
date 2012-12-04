
local Zoom = Chinchilla:NewModule("Zoom", "AceHook-3.0", "LibShefkiTimer-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Zoom.displayName = L["Zoom"]
Zoom.desc = L["Use the mouse wheel to zoom in and out on the minimap."]


function Zoom:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Zoom", {
		profile = {
			enabled = true,
			wheelZoom = true, autoZoom = true, autoZoomTime = 20,
		}
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


local timerID, frame
function Zoom:OnEnable()
	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_WheelZoom_Frame", Minimap)
		frame:SetAllPoints(Minimap)
		frame:SetScript("OnMouseWheel", function(this, change)
			if change > 0 then
				Minimap_ZoomIn()
			else
				Minimap_ZoomOut()
			end
		end)
	end

	frame:Show()
	frame:EnableMouseWheel(true)

	timerID = self:ScheduleTimer("ZoomOut", self.db.profile.time)
	self:SecureHook(Minimap, "SetZoom", "Minimap_SetZoom")
end

function Zoom:OnDisable()
	frame:Hide()
	frame:EnableMouseWheel(false)
end


function Zoom:Minimap_SetZoom(_, zoomLevel, ignore)
	if zoomLevel == 0 or ignore then return end

	if timerID then
		self:CancelTimer(timerID, true)
		timerID = nil
	end

	timerID = self:ScheduleTimer("ZoomOut", self.db.profile.autoZoomTime)
end

function Zoom:ZoomOut()
	Minimap:SetZoom(0, true)
	timerID = nil
end


function Zoom:GetOptions()
	return {
		time = {
			name = L["Time to zoom"],
			desc = L["Set the time it takes between manually zooming in and automatically zooming out"],
			type = 'range',
			min = 1, max = 60, step = 1,
			order = 3,
			get = function()
				return self.db.profile.autoZoomTime
			end,
			set = function(_, value)
				self.db.profile.autoZoomTime = value
			end,
		},
	}
end
