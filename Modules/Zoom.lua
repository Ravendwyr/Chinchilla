
local Zoom = Chinchilla:NewModule("Zoom", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Zoom.displayName = L["Zoom"]
Zoom.desc = L["Use the mouse wheel to zoom in and out on the minimap."]


-- some of the code in this module was inspired by SexyMap (written by Funkeh`)
-- and is used with his permission.

local timerID
local function OnMouseWheel(_, delta)
	if not Zoom.db.profile.wheelZoom then return end

	if delta > 0 then
		Minimap_ZoomIn()
	else
		Minimap_ZoomOut()
	end
end


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

function Zoom:OnEnable()
	Minimap:SetScript("OnMouseWheel", OnMouseWheel)
	Minimap:EnableMouseWheel(true)

	timerID = self:ScheduleTimer("ZoomOut", self.db.profile.autoZoomTime)
	self:SecureHook(Minimap, "SetZoom", "Minimap_SetZoom")
end

function Zoom:OnDisable()
	Minimap:SetScript("OnMouseWheel", nil)
	Minimap:EnableMouseWheel(false)
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
		wheelZoom = {
			name = L["Wheel zoom"],
			desc = L["Use the mouse wheel to zoom in and out on the minimap."],
			type = 'toggle', order = 1,
			get = function() return self.db.profile.wheelZoom end,
			set = function(_, value) self.db.profile.wheelZoom = value end,
		},
		autoZoom = {
			name = L["Auto zoom"],
			desc = L["Automatically zoom out after a specified time."],
			type = 'toggle', order = 1,
			get = function() return self.db.profile.autoZoom end,
			set = function(_, value) self.db.profile.autoZoom = value end,
		},
		autoZoomTime = {
			name = L["Time to zoom"],
			desc = L["Set the time it takes between manually zooming in and automatically zooming out"],
			type = 'range', order = 3,
			min = 1, max = 60, step = 1,
			get = function() return self.db.profile.autoZoomTime end,
			set = function(_, value) self.db.profile.autoZoomTime = value end,
		},
	}
end
