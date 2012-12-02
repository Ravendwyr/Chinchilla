
local ShowHide = Chinchilla:NewModule("ShowHide", "AceEvent-3.0", "AceHook-3.0", "LibShefkiTimer-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

ShowHide.displayName = L["Show / Hide"]
ShowHide.desc = L["Show and hide interface elements of the minimap"]


function ShowHide:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("ShowHide", {
		profile = {
			enabled = true, onMouseOver = true, calendarInviteOnly = false,

			boss = true,
			north = true,
			difficulty = true,
			map = true,
			mail = true,
			lfg = true,
			dayNight = true,
			track = true,
			voice = true,
			zoom = true,
			clock = true,
			vehicleSeats = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local frames = {
	boss = Chinchilla_BossAnchor,
	difficulty = MiniMapInstanceDifficulty,
	guilddifficulty = GuildInstanceDifficulty,
	north = MinimapNorthTag,
	map = MiniMapWorldMapButton,
	mail = MiniMapMailFrame,
	lfg = QueueStatusMinimapButton,
	dayNight = GameTimeFrame,
	track = MiniMapTracking,
	voice = MiniMapVoiceChatFrame,
	zoomIn = MinimapZoomIn,
	zoomOut = MinimapZoomOut,
--	vehicleSeats = VehicleSeatIndicator,
	clock = TimeManagerClockButton,
	record = IsMacClient() and MiniMapRecordingButton or nil,
}

local framesShown = {}

function ShowHide:OnEnable()
	if self.db.profile.onMouseOver then
		self:HookScript(Minimap, "OnEnter")
		self:HookScript(Minimap, "OnLeave")
	end

	for k, v in pairs(frames) do
		framesShown[v] = v:IsShown()

		self:SecureHook(frames[k], "Show", "frame_Show")
		self:SecureHook(frames[k], "Hide", "frame_Hide")
	end

	self:RegisterEvent("CALENDAR_ACTION_PENDING", "UpdateCalendar")
	self:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateCalendar")

	self:Update()
end

function ShowHide:OnDisable()
	for k, v in pairs(frames) do
		if framesShown[v] then
			v:Show()
		end
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

		if value == true then
--			if framesShown[frame] then
				self:SetFrameShown(key, frame)
--			end
		else -- Minimap:IsMouseOver() isn't going to return true when settings are being changed, so just hide the buttons
		 	if frame:IsShown() then
				frame:Hide()
				framesShown[frame] = true
			end
		end
	end
end

function ShowHide:UpdateCalendar()
	self:SetFrameShown("dayNight", GameTimeFrame)
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

	if self.db.profile[object_k] == false or ( self.db.profile[object_k] == "mouseover" and not Minimap:IsMouseOver() ) then
		object:Hide()
	end

	framesShown[object] = true
end

function ShowHide:frame_Hide(object)
	framesShown[object] = false
end


function ShowHide:SetFrameShown(key, frame)
	if key == "dayNight" then
		if self.db.profile.calendarInviteOnly then
			if CalendarGetNumPendingInvites() > 0 then
				frame:Show()
			else
				frame:Hide()
				framesShown[frame] = true
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
			local mode, submode = GetLFGMode(i)
			if mode then
				showMinimapButton = true
			end
		end

		-- try all PvP queues
		for i=1, GetMaxBattlefieldID() do
			local status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch, eligibleInQueue, waitingOnOtherActivity = GetBattlefieldStatus(i)
			if status and status ~= "none" then
				showMinimapButton = true
			end
		end

		-- try all World PvP queues
		for i=1, MAX_WORLD_PVP_QUEUES do
			local status, mapName, queueID = GetWorldPVPQueueStatus(i)
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
	elseif key == "difficulty" and self.db.profile[key] then
		MiniMapInstanceDifficulty_Update()
	elseif key == "record" then
		if GetCVar("MovieRecordingIcon") == "1" and MovieRecording_IsRecording() then
			frame:Show()
		else
			frame:Hide()
		end
	else
		frame:Show()
	end
end


local timerID = nil
function ShowHide:OnEnter()
	if timerID then
		self:CancelTimer(timerID)
		timerID = nil
	end

	local realKey

	for key, frame in pairs(frames) do
		-- we don't bother with "guilddifficulty" -> "difficulty" here as the instance flag is not yet tristate
		if key == "zoomIn" or key == "zoomOut" then
			realKey = "zoom"
		else
			realKey = key
		end

		if self.db.profile[realKey] == "mouseover" then
			self:SetFrameShown(realKey, frame)
		end
	end
end

function ShowHide:OnLeave()
	timerID = self:ScheduleTimer("HideAll", 2)
end

function ShowHide:HideAll()
	local realKey

	for key, frame in pairs(frames) do
		if key == "zoomIn" or key == "zoomOut" then
			realKey = "zoom"
		else
			realKey = key
		end

		if self.db.profile[realKey] == "mouseover" then
			frame:Hide()
			framesShown[frame] = true
		end
	end

	timerID = nil
end

function ShowHide:OnMouseOverUpdate(info, value)
	if info then self.db.profile.onMouseOver = value end

	if value then
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

		if self.db.profile.onMouseOver and self.db.profile[key] == "mouseover" then
			return nil
		else
			return not not self.db.profile[key]
		end
	end

	local function set(info, value)
		local key = info[#info]

		if value == nil then
			if self.db.profile.onMouseOver then value = "mouseover"
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
			get = get, set = "OnMouseOverUpdate",
		},
		calendarInviteOnly = {
			name = L["Unread Invites Only"],
			desc = L["Only show the calendar when you have unread invites waiting for you."],
			type = 'toggle',
			order = 2,
			get = get, set = set,
			width = "double",
			disabled = function() return self.db.profile.dayNight == false end,
		},
		tutorial = {
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
			order = 5,
			get = get, set = set,
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
		track = {
			name = L["Tracking"],
			desc = L["Show the tracking indicator"],
			type = 'toggle',
			tristate = true,
			order = 11,
			get = get, set = set,
		},
		clock = {
			name = L["Clock"],
			desc = L["Show the clock"],
			type = 'toggle',
			tristate = true,
			order = 12,
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
			order = 13,
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
--[[
		vehicleSeats = {
			name = L["Vehicle seats"],
			desc = L["Show the vehicle seats indicator"],
			type = 'toggle',
			order = 16,
			get = get, set = set,
		},
]]--
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
			order = 18,
			get = function() return GetCVar("MovieRecordingIcon") == "1" and true or false end,
			set = function(_, value)
				if value then SetCVar("MovieRecordingIcon", "1")
				else SetCVar("MovieRecordingIcon", "0") end
			end,
		} or nil,
	}
end
