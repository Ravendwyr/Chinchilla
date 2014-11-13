
local ShowHide = Chinchilla:NewModule("ShowHide", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

ShowHide.displayName = L["Show / Hide"]
ShowHide.desc = L["Show and hide interface elements of the minimap"]


local frames = {
	boss = "Chinchilla_BossAnchor",
	difficulty = "MiniMapInstanceDifficulty",
	guilddifficulty = "GuildInstanceDifficulty",
	north = "MinimapNorthTag",
	map = "MiniMapWorldMapButton",
	mail = "MiniMapMailFrame",
	lfg = "QueueStatusMinimapButton",
	dayNight = "GameTimeFrame",
	track = "MiniMapTracking",
	voice = "MiniMapVoiceChatFrame",
	zoomIn = "MinimapZoomIn",
	zoomOut = "MinimapZoomOut",
	vehicleSeats = "VehicleSeatIndicator",
	clock = "TimeManagerClockButton",
	garrison = "GarrisonLandingPageMinimapButton",
	record = IsMacClient() and "MiniMapRecordingButton" or nil,
}


function ShowHide:ShowFrame(key, frame)
	frame = _G[frame]

	self:Unhook(frame, "Show")

	if key == "dayNight" then
		if self.db.profile.calendarInviteOnly then
			if CalendarGetNumPendingInvites() > 0 then
				frame:Show()
			else
				self:HideFrame("dayNight", "GameTimeFrame")
			end
		else
			frame:Show()
		end
	elseif key == "mail" then
		if HasNewMail() then frame:Show() end
	elseif key == "lfg" then
		-- there must be a better way to do this
		local showMinimapButton = false

		-- try each LFG type
		for i=1, NUM_LE_LFG_CATEGORYS do
			local mode = GetLFGMode(i)
			if mode then
				showMinimapButton = true
			end
		end

		-- try all PvP queues
		for i=1, GetMaxBattlefieldID() do
			local status = GetBattlefieldStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
			end
		end

		-- try all World PvP queues
		for i=1, MAX_WORLD_PVP_QUEUES do
			local status = GetWorldPVPQueueStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
			end
		end

		-- World PvP areas we're currently in
		if CanHearthAndResurrectFromArea() then
			showMinimapButton = true
		end

		-- Pet Battle PvP Queue
		if C_PetBattles.GetPVPMatchmakingInfo() then
			showMinimapButton = true
		end

		if showMinimapButton then frame:Show() end
	elseif key == "difficulty" then
		MiniMapInstanceDifficulty_Update()
	elseif key == "record" then
		if GetCVar("MovieRecordingIcon") == "1" and MovieRecording_IsRecording() then
			frame:Show()
		end
	elseif key == "voice" then
		MiniMapVoiceChat_Update()
	else
		frame:Show()
	end
end

function ShowHide:HideFrame(key, frame)
	frame = _G[frame]

	if frame.isMoving then return end

	if not self:IsHooked(frame, "Show") then
		self:SecureHook(frame, "Show", frame.Hide)
	end

	frame:Hide()
end


function ShowHide:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("ShowHide", {
		profile = {
			enabled = true,
			onMouseOver = true, calendarInviteOnly = false,

			boss = true, north = true, difficulty = true, map = true,
			mail = true, lfg = true, dayNight = true, track = true,
			voice = true, zoom = true, clock = true, vehicleSeats = true,
			garrison = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

function ShowHide:OnEnable()
	self:RegisterEvent("CALENDAR_ACTION_PENDING", "UpdateCalendar")
	self:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateCalendar")

	self:UpdateMouseover()
	self:Update()
end


function ShowHide:Update()
	if not self:IsEnabled() then return end

	for key, frame in pairs(frames) do
		if key:find("^zoom") then
			key = "zoom"
		elseif key == "guilddifficulty" then
			key = "difficulty"
		end

		if self.db.profile[key] == true then
			self:ShowFrame(key, frame)
		else
			-- Minimap:IsMouseOver() isn't going to return true with the config open, so just hide the button
		 	self:HideFrame(key, frame)
		end
	end
end

function ShowHide:UpdateCalendar()
	if not self.db.profile.calendarInviteOnly then return end

	if CalendarGetNumPendingInvites() > 0 then
		self:ShowFrame("dayNight", "GameTimeFrame")
	else
		self:HideFrame("dayNight", "GameTimeFrame")
	end
end

function ShowHide:UpdateMouseover(info, value)
	if info then self.db.profile.onMouseOver = value
	else value = self.db.profile.onMouseOver end

	if value then
		self:HookScript(Minimap, "OnEnter")
		self:HookScript(Minimap, "OnLeave")
	else
		self:Unhook(Minimap, "OnEnter")
		self:Unhook(Minimap, "OnLeave")
	end
end


local timerID = nil
function ShowHide:OnEnter()
	if timerID then
		self:CancelTimer(timerID)
		timerID = nil
	end

	for key, frame in pairs(frames) do
		if key:find("^zoom") then -- zoomIn/zoomOut -> zoom
			key = "zoom"
		elseif key:find("difficulty") then -- guilddifficulty -> difficulty
			key = "difficulty"
		end

		if self.db.profile[key] == "mouseover" then
			self:ShowFrame(key, frame)
		end
	end
end

function ShowHide:OnLeave()
	timerID = self:ScheduleTimer("HideAllMouseoverButtons", 3)
end

function ShowHide:HideAllMouseoverButtons()
	for key, frame in pairs(frames) do
		if key:find("^zoom") then -- zoomIn/zoomOut -> zoom
			key = "zoom"
		elseif key:find("difficulty") then -- guilddifficulty -> difficulty
			key = "difficulty"
		end

		if self.db.profile[key] == "mouseover" then
			self:HideFrame(key, frame)
		end
	end

	timerID = nil
end


function ShowHide:GetOptions()
	local function get(info)
		local key = info[#info]

		if info.option.tristate and self.db.profile[key] == "mouseover" then
			return nil
		else
			return not not self.db.profile[key] -- to force a boolean
		end
	end

	local function set(info, value)
		local key = info[#info]

		if value == nil then
			if info.option.tristate then value = "mouseover"
			else value = false end
		end

		self.db.profile[key] = value
		self:Update()
	end

	return {
		onMouseOver = {
			name = L["On Mouse Over"],
			desc = L["Only show certain buttons when the cursor is hovering over the minimap."],
			type = 'toggle',
			order = 1,
			get = get, set = "UpdateMouseover",
		},
		calendarInviteOnly = {
			name = L["Unread Invites Only"],
			desc = L["Only show the calendar when you have unread invites waiting for you."],
			type = 'toggle',
			order = 2,
			get = get, set = set,
			disabled = function() return self.db.profile.dayNight == false end,
		},
		description = {
			name = L["A gold tick means the button will be shown at all times. A silver tick means the button will be shown when you hover the cursor over the minimap. An empty tickbox means the button will not be shown at all."],
			type = "description",
			order = 3,
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
			tristate = true,
			order = 5,
			get = get, set = set,
		},
		map = {
			name = L["World map"],
			desc = L["Show the world map button"],
			type = 'toggle',
			tristate = true,
			order = 6,
			get = get, set = set,
		},
		mail = {
			name = L["Mail"],
			desc = L["Show the mail indicator"],
			type = 'toggle',
			tristate = true,
			order = 7,
			get = get, set = set,
		},
		lfg = {
			name = L["LFG"],
			desc = L["Show the looking for group indicator"],
			type = 'toggle',
			order = 8,
			get = get, set = set,
		},
		track = {
			name = L["Tracking"],
			desc = L["Show the tracking indicator"],
			type = 'toggle',
			tristate = true,
			order = 9,
			get = get, set = set,
		},
		garrison = {
			name = L["Garrison"],
			desc = L["Show the garrison report button"],
			type = 'toggle',
			tristate = true,
			order = 10,
			get = get, set = set,
		},
		clock = {
			name = L["Clock"],
			desc = L["Show the clock"],
			type = 'toggle',
			tristate = true,
			order = 11,
			get = get, set = function(info, value)
				if TITAN_CLOCK_ID then
					if value == true or value == nil then
						TitanSetVar(TITAN_CLOCK_ID, "HideMapTime", false)
					else
						TitanSetVar(TITAN_CLOCK_ID, "HideMapTime", 1)
					end
				end

				set(info, value)
			end,
		},
		dayNight = {
			name = L["Calendar"],
			desc = L["Show the calendar"],
			type = 'toggle',
			tristate = true,
			order = 12,
			get = get, set = function(info, value)
				if TITAN_CLOCK_ID then
					if value == true or value == nil then
						TitanSetVar(TITAN_CLOCK_ID, "HideGameTimeMinimap", false)
					else
						TitanSetVar(TITAN_CLOCK_ID, "HideGameTimeMinimap", 1)
					end
				end

				set(info, value)
			end,
		},
		voice = {
			name = L["Voice chat"],
			desc = L["Show the voice chat button"],
			type = 'toggle',
			tristate = true,
			order = 13,
			get = get, set = set,
		},
		zoom = {
			name = L["Zoom"],
			desc = L["Show the zoom in and out buttons"],
			type = 'toggle',
			tristate = true,
			order = 14,
			get = get, set = set,
		},
		vehicleSeats = {
			name = L["Vehicle seats"],
			desc = L["Show the vehicle seats indicator"],
			type = 'toggle',
			order = 15,
			get = get, set = set,
		},
		boss = {
			name = L["Boss frames"],
			desc = L["Show the boss unit frames"],
			type = 'toggle',
			order = 16,
			get = get, set = set,
		},
		record = IsMacClient() and {
			name = L["Recording"],
			desc = L["Show the recording button"],
			type = 'toggle',
			order = 17,
			get = function() return GetCVar("MovieRecordingIcon") == "1" end,
			set = function() MacOptionsFrameCheckButton2:Click() end,
		} or nil,
	}
end
