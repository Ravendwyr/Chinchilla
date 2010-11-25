
local ShowHide = Chinchilla:NewModule("ShowHide", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

ShowHide.displayName = L["Show / Hide"]
ShowHide.desc = L["Show and hide interface elements of the minimap"]


function ShowHide:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("ShowHide", {
		profile = {
			boss = true,
			battleground = true,
			north = true,
			locationBar = true,
			locationText = true,
			difficulty = true,
			map = true,
			mail = true,
			lfg = true,
			dayNight = true,
			track = true,
			voice = true,
			zoom = true,
			record = true,
			clock = true,
			vehicleSeats = true,

			enabled = true,
			onMouseOver = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local frames = {
	boss = Chinchilla_BossAnchor,
	battleground = MiniMapBattlefieldFrame,
	difficulty = MiniMapInstanceDifficulty,
	guilddifficulty = GuildInstanceDifficulty,
	north = MinimapNorthTag,
	map = MiniMapWorldMapButton,
	mail = MiniMapMailFrame,
	lfg = MiniMapLFGFrame,
	dayNight = GameTimeFrame,
	track = MiniMapTracking,
	voice = MiniMapVoiceChatFrame,
	zoomIn = MinimapZoomIn,
	zoomOut = MinimapZoomOut,
	vehicleSeats = VehicleSeatIndicator,
	clock = TimeManagerClockButton,
	record = IsMacClient() and MiniMapRecordingButton or nil,
}

local framesShown = {}

function ShowHide:OnEnable()
	-- these hooks are here to ensure Chinchilla plays nicely with Broker uClock and Titan Clock
	if IsAddOnLoaded("Broker_uClock") or TITAN_CLOCK_ID then
		self:HookScript(TimeManagerClockButton, "OnShow", function() self.db.profile.clock = true end)
		self:HookScript(TimeManagerClockButton, "OnHide", function() self.db.profile.clock = false end)
		self:HookScript(GameTimeFrame, "OnShow", function() self.db.profile.dayNight = true end)
		self:HookScript(GameTimeFrame, "OnHide", function() self.db.profile.dayNight = false end)
	end

	if self.db.profile.onMouseOver then
		self:HookScript(Minimap, "OnEnter")
		self:HookScript(Minimap, "OnLeave")
	end

	for k, v in pairs(frames) do
		framesShown[v] = v:IsShown()

		self:SecureHook(frames[k], "Show", "frame_Show")
		self:SecureHook(frames[k], "Hide", "frame_Hide")
	end

	framesShown[MinimapZoneTextButton] = not not MinimapZoneTextButton:IsShown() -- to ensure a boolean

	self:SecureHook(MinimapZoneTextButton, "Show", "MinimapZoneTextButton_Show")
	self:SecureHook(MinimapZoneTextButton, "Hide", "MinimapZoneTextButton_Hide")

	self:Update()
end

function ShowHide:OnDisable()
	for k, v in pairs(frames) do
		if framesShown[v] then
			v:Show()
		end
	end

	if framesShown[MinimapZoneTextButton] then
		MinimapBorderTop:Show()
		MinimapZoneTextButton:Show()
	end
end

function ShowHide:Update()
	if not self:IsEnabled() then return end

	for key, frame in pairs(frames) do
		if key == "zoomOut" or key == "zoomIn" then
			key = "zoom"
		elseif key == "guilddifficulty" then
			key = "difficulty"
		end

		local value = self.db.profile[key]

		if key == "boss" then
			self:SetBoss(value)
		elseif value == true then
			if framesShown[frame] then
				frame:Show()
			end
		else -- Minimap:IsMouseOver() isn't going to happen while the config is open
		 	if frame:IsShown() then
				frame:Hide()
				framesShown[frame] = true
			end
		end
	end

	if Chinchilla:GetModule("Location", true) and Chinchilla:GetModule("Location"):IsEnabled() then
		MinimapBorderTop:Hide()
		MinimapZoneTextButton:Hide()
	elseif not self.db.profile.locationBar then
		MinimapBorderTop:Hide()

		if not self.db.profile.locationText then
			MinimapZoneTextButton:Hide()
		else
			MinimapZoneTextButton:Show()
		end
	else
		MinimapBorderTop:Show()
		MinimapZoneTextButton:Show()
	end
end

function ShowHide:frame_Show(object)
	local object_k

	for k, v in pairs(frames) do
		if v == object then
			if k == "zoomIn" or k == "zoomOut" then
				object_k = "zoom"
			elseif k == "guilddifficulty" then
				object_k = "difficulty"
			else
				object_k = k
			end

			break
		end
	end

	if object_k and self.db.profile[object_k] == false or (self.db.profile[object_k] == "mouseover" and not Minimap:IsMouseOver() ) then
		object:Hide()
	end

	framesShown[object] = true
end

function ShowHide:frame_Hide(object)
	framesShown[object] = false
end


function ShowHide:MinimapZoneTextButton_Show(object)
	if not self.db.profile.locationText or ( Chinchilla:GetModule("Location", true) and Chinchilla:GetModule("Location"):IsEnabled() ) then
		MinimapBorderTop:Hide()
		MinimapZoneTextButton:Hide()
	end

	framesShown[object] = true
end

function ShowHide:MinimapZoneTextButton_Hide(object)
	framesShown[object] = false
end


function ShowHide:SetBoss(value)
	if value then
		Boss1TargetFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss2TargetFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss3TargetFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss4TargetFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	else
		Boss1TargetFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss2TargetFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss3TargetFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		Boss4TargetFrame:UnregisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	end
end


function ShowHide:OnEnter()
	self:CancelTimer("HideAll", true)

	for key, value in pairs(self.db.profile) do
		if value == "mouseover" then
			if key == "zoom" then
				frames["zoomIn"]:Show()
				frames["zoomOut"]:Show()
			elseif key == "mail" then
				if HasNewMail() then frames["mail"]:Show() end
			elseif key == "lfg" then
				if GetLFGMode() then frames["lfg"]:Show() end
			elseif key == "battleground" then
				if MiniMapBattlefieldFrame.status == "active" then frames["battleground"]:Show() end
			else
				frames[key]:Show()
			end
		end
	end
end

function ShowHide:OnLeave()
	self:ScheduleTimer("HideAll", 2)
end

function ShowHide:HideAll()
	for key, value in pairs(self.db.profile) do
		if value == "mouseover" then
			if key == "zoom" then
				frames["zoomIn"]:Hide()
				frames["zoomOut"]:Hide()
			else
				frames[key]:Hide()
			end
		end
	end
end

function ShowHide:OnMouseOverUpdate(info, value)
	if info then self.db.profile.onMouseOver = value end

	if self.db.profile.onMouseOver then
		self:HookScript(Minimap, "OnEnter")
		self:HookScript(Minimap, "OnLeave")
	else
		self:Unhook(Minimap, "OnEnter")
		self:Unhook(Minimap, "OnLeave")
	end
end


function ShowHide:GetOptions()
	local function get(info)
		local key = info[#info]

		if self.db.profile[key] == "mouseover" then
			return nil
		else
			return self.db.profile[key]
		end
	end

	local function set(info, value)
		local key = info[#info]

		if value == nil then
			if not self.db.profile.onMouseOver then value = false
			else value = "mouseover" end
		end

		self.db.profile[key] = value
		self:Update(key, value)
	end

	return {
		onMouseOver = {
			name = L["On Mouse Over"],
			desc = L["Only show certain buttons when the cursor is hovering over the minimap."],
			type = 'toggle',
			width = 'full',
			order = 1,
			get = get, set = "OnMouseOverUpdate",
		},
		tutorial = {
			name = L["A gold tick means the button will be shown at all times. A silver tick means the button will be shown when you hover the cursor over the minimap. An empty tickbox means the button will not be shown at all."],
			type = "description",
			order = 2,
			hidden = function() return not self.db.profile.onMouseOver end,
		},
		battleground = {
			name = L["Battleground"],
			desc = L["Show the battleground indicator"],
			type = 'toggle',
			tristate = true,
			order = 3,
			get = get, set = set,
		},
		north = {
			name = L["North"],
			desc = L["Show the north symbol on the minimap"],
			type = 'toggle',
			order = 4,
			get = get, set = set,
		},
		difficulty = {
			name = L["Instance difficulty"],
			desc = L["Show the instance difficulty flag on the minimap"],
			type = 'toggle',
			order = 5,
			get = get, set = set,
		},
		locationText = {
			name = L["Location text"],
			desc = L["Show the location text above the minimap"],
			type = 'toggle',
			order = 6,
			get = get, set = set,
		},
		locationBar = {
			name = L["Location bar"],
			desc = L["Show the location bar above the minimap"],
			type = 'toggle',
			order = 7,
			get = get, set = set,
			disabled = function()
				return not self.db.profile.locationText
			end,
		},
		map = {
			name = L["World map"],
			desc = L["Show the world map button"],
			type = 'toggle',
			tristate = true,
			order = 8,
			get = get, set = set,
		},
		mail = {
			name = L["Mail"],
			desc = L["Show the mail indicator"],
			type = 'toggle',
			tristate = true,
			order = 9,
			get = get, set = set,
		},
		lfg = {
			name = L["LFG"],
			desc = L["Show the looking for group indicator"],
			type = 'toggle',
			tristate = true,
			order = 10,
			get = get, set = set,
		},
		dayNight = {
			name = L["Calendar"],
			desc = L["Show the calendar"],
			type = 'toggle',
			tristate = (IsAddOnLoaded("Broker_uClock") or TITAN_CLOCK_ID) and false or true,
			order = 11,
			get = get,
			set = function(...)
				if TITAN_CLOCK_ID then TitanPanelClockButton_ToggleGameTimeFrameShown()
				else set(...) end
			end,
		},
		clock = {
			name = L["Clock"],
			desc = L["Show the clock"],
			type = 'toggle',
			tristate = (IsAddOnLoaded("Broker_uClock") or TITAN_CLOCK_ID) and false or true,
			order = 12,
			get = get,
			set = function(...)
				if TITAN_CLOCK_ID then TitanPanelClockButton_ToggleMapTime()
				else set(...) end
			end,
		},
		track = {
			name = L["Tracking"],
			desc = L["Show the tracking indicator"],
			type = 'toggle',
			tristate = true,
			order = 13,
			get = get, set = set,
		},
		voice = {
			name = L["Voice chat"],
			desc = L["Show the voice chat button"],
			type = 'toggle',
			tristate = true,
			order = 14,
			get = get, set = set,
		},
		zoom = {
			name = L["Zoom"],
			desc = L["Show the zoom in and out buttons"],
			type = 'toggle',
			tristate = true,
			order = 15,
			get = get, set = set,
		},
		vehicleSeats = {
			name = L["Vehicle seats"],
			desc = L["Show the vehicle seats indicator"],
			type = 'toggle',
			order = 16,
			get = get, set = set,
		},
		boss = {
			name = L["Boss frames"],
			desc = L["Show the boss unit frames"],
			type = 'toggle',
			order = 17,
			get = get, set = set,
		},
		record = IsMacClient() and {
			name = L["Recording"],
			desc = L["Show the recording button"],
			type = 'toggle',
			tristate = true,
			order = 18,
			get = get, set = set,
		} or nil,
	}
end
