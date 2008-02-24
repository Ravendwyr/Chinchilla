local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_ShowHide = Chinchilla:NewModule("ShowHide", "LibRockHook-1.0")
local self = Chinchilla_ShowHide
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_ShowHide.desc = L["Show and hide interface elements of the minimap"]

function Chinchilla_ShowHide:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("ShowHide")
	Chinchilla:SetDatabaseNamespaceDefaults("ShowHide", "profile", {
		battleground = true,
		north = true,
		locationBar = true,
		locationText = true,
		map = true,
		mail = true,
		lfg = true,
		clock = true,
		track = true,
		voice = true,
		zoom = true,
		record = true,
	})
end

local frames = {
	battleground = MiniMapBattlefieldFrame,
	north = MinimapNorthTag,
	map = MiniMapWorldMapButton,
	mail = MiniMapMailFrame,
	lfg = MiniMapMeetingStoneFrame,
	clock = GameTimeFrame,
	track = MiniMapTracking,
	voice = MiniMapVoiceChatFrame,
	zoomIn = MinimapZoomIn,
	zoomOut = MinimapZoomOut,
	record = IsMacClient() and MiniMapRecordingButton or nil,
}

local framesShown = {}

function Chinchilla_ShowHide:OnEnable()
	for k,v in pairs(frames) do
		framesShown[v] = not not v:IsShown()
		self:AddSecureHook(frames[k], "Show", "frame_Show")
		self:AddSecureHook(frames[k], "Hide", "frame_Hide")
	end
	framesShown[MinimapZoneTextButton] = not not MinimapZoneTextButton:IsShown()
	self:AddSecureHook(MinimapZoneTextButton, "Show", "MinimapZoneTextButton_Show")
	self:AddSecureHook(MinimapZoneTextButton, "Hide", "MinimapZoneTextButton_Hide")
	self:Update()
end

function Chinchilla_ShowHide:OnDisable()
	for k,v in pairs(frames) do
		if framesShown[v] then
			v:Show()
		end
	end
	if framesShown[MinimapZoneTextButton] then
		MinimapToggleButton:Show()
		MinimapBorderTop:Show()
		MinimapZoneTextButton:Show()
	end
end

function Chinchilla_ShowHide:Update()
	if Chinchilla:IsModuleActive(self) then
		for k,v in pairs(frames) do
			local key = k
			if key == "zoomOut" or key == "zoomIn" then
				key = "zoom"
			end
			if not self.db.profile[key] then
			 	if v:IsShown() then
					v:Hide()
					
					framesShown[v] = true
				end
			else
				if framesShown[v] then
					v:Show()
				end
			end
		end
		if Chinchilla:HasModule("Location") and Chinchilla:IsModuleActive("Location") then
			MinimapToggleButton:Hide()
			MinimapBorderTop:Hide()
			MinimapZoneTextButton:Hide()
		elseif not self.db.profile.locationBar then
			MinimapToggleButton:Hide()
			MinimapBorderTop:Hide()
			if not self.db.profile.locationText then
				MinimapZoneTextButton:Hide()
			else
				MinimapZoneTextButton:Show()
			end
		else
			MinimapToggleButton:Show()
			MinimapBorderTop:Show()
			MinimapZoneTextButton:Show()
		end
	end
end

local lastShow = 0
local lastShowObject = nil
function Chinchilla_ShowHide:frame_Show(object)
	local object_k
	for k,v in pairs(frames) do
		if v == object then
			if k == "zoomIn" or k == "zoomOut" then
				object_k = "zoom"
			else
				object_k = k
			end
			break
		end
	end
	if object_k and not self.db.profile[object_k] then
		if lastShow < GetTime() - 1e5 or lastShowObject ~= object then
			-- don't want infinite loops
			lastShow = GetTime()
			lastShowObject = object
			object:Hide()
		end
	end
	
	framesShown[object] = true
end

function Chinchilla_ShowHide:frame_Hide(object)
	framesShown[object] = false
end

function Chinchilla_ShowHide:MinimapZoneTextButton_Show(object)
	if not self.db.profile.locationText or (Chinchilla:HasModule("Location") and Chinchilla:IsModuleActive("Location")) then
		if lastShow < GetTime() - 1e5 or lastShowObject ~= object then
			lastShow = GetTime()
			lastShowObject = object
			MinimapToggleButton:Hide()
			MinimapBorderTop:Hide()
			MinimapZoneTextButton:Hide()
		end
	end
	
	framesShown[object] = true
end

function Chinchilla_ShowHide:MinimapZoneTextButton_Hide(object)
	framesShown[object] = false
end

local function get(key)
	return self.db.profile[key]
end
local function set(key, value)
	self.db.profile[key] = value
	Chinchilla_ShowHide:Update(key, value)
end
Chinchilla_ShowHide:AddChinchillaOption({
	name = L["Show / Hide"],
	desc = Chinchilla_ShowHide.desc,
	type = 'group',
	args = {
		battleground = {
			name = L["Battleground"],
			desc = L["Show the battleground indicator"],
			type = 'boolean',
			passValue = 'battleground',
			get = get,
			set = set,
		},
		north = {
			name = L["North"],
			desc = L["Show the north symbol on the minimap"],
			type = 'boolean',
			passValue = 'north',
			get = get,
			set = set,
		},
		locationBar = {
			name = L["Location bar"],
			desc = L["Show the location bar above the minimap"],
			type = 'boolean',
			passValue = 'locationBar',
			get = get,
			set = set,
		},
		locationText = {
			name = L["Location text"],
			desc = L["Show the location text above the minimap"],
			type = 'boolean',
			passValue = 'locationText',
			get = get,
			set = set,
			disabled = function()
				return self.db.profile.locationBar
			end
		},
		map = {
			name = L["World map"],
			desc = L["Show the world map button"],
			type = 'boolean',
			passValue = 'map',
			get = get,
			set = set,
		},
		mail = {
			name = L["Mail"],
			desc = L["Show the mail indicator"],
			type = 'boolean',
			passValue = 'mail',
			get = get,
			set = set,
		},
		lfg = {
			name = L["LFG"],
			desc = L["Show the looking for group indicator"],
			type = 'boolean',
			passValue = 'lfg',
			get = get,
			set = set,
		},
		clock = {
			name = L["Clock"],
			desc = L["Show the clock"],
			type = 'boolean',
			passValue = 'clock',
			get = get,
			set = set,
		},
		track = {
			name = L["Tracking"],
			desc = L["Show the tracking indicator"],
			type = 'boolean',
			passValue = 'track',
			get = get,
			set = set,
		},
		voice = {
			name = L["Voice chat"],
			desc = L["Show the voice chat button"],
			type = 'boolean',
			passValue = 'voice',
			get = get,
			set = set,
		},
		zoom = {
			name = L["Zoom"],
			desc = L["Show the zoom in and out buttons"],
			type = 'boolean',
			passValue = 'zoom',
			get = get,
			set = set,
		},
		record = IsMacClient() and {
			name = L["Recording"],
			desc = L["Show the recording button"],
			type = 'boolean',
			passValue = 'record',
			get = get,
			set = set,
		} or nil,
	}
})
