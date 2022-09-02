
local ShowHide = Chinchilla:NewModule("ShowHide", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

ShowHide.displayName = L["Show / Hide"]
ShowHide.desc = L["Show and hide interface elements of the minimap"]


local ShowHideFrame = CreateFrame("Frame")
ShowHideFrame:Hide()

local frames


function ShowHide:ShowFrame(frame)
	if _G[frame] then
		_G[frame]:SetParent( _G[frame].__origParent )
	end
end

function ShowHide:HideFrame(frame)
	if _G[frame] then
		_G[frame]:SetParent(ShowHideFrame)
	end
end


function ShowHide:OnInitialize()
	if Chinchilla:IsClassic() then
		frames = {
			north = "MinimapNorthTag",
			map = "MiniMapWorldMapButton",
			mail = "MiniMapMailFrame",
			dayNight = "GameTimeFrame",
			track = "MiniMapTrackingFrame",
			zoomIn = "MinimapZoomIn",
			zoomOut = "MinimapZoomOut",
			clock = "TimeManagerClockButton",
		}
	elseif Chinchilla:IsWrathClassic() then
		frames = {
			north = "MinimapNorthTag",
			map = "MiniMapWorldMapButton",
			mail = "MiniMapMailFrame",
			dayNight = "GameTimeFrame",
			track = "MiniMapTracking",
			zoomIn = "MinimapZoomIn",
			zoomOut = "MinimapZoomOut",
			clock = "TimeManagerClockButton",
		}
	else
		frames = {
			boss = "Chinchilla_BossAnchor",
			difficulty = "MiniMapInstanceDifficulty",
			guilddifficulty = "GuildInstanceDifficulty",
			north = "MinimapNorthTag",
			map = "MiniMapWorldMapButton",
			mail = "MiniMapMailFrame",
			lfg = "QueueStatusMinimapButton",
			dayNight = "GameTimeFrame",
			track = "MiniMapTracking",
			zoomIn = "MinimapZoomIn",
			zoomOut = "MinimapZoomOut",
			vehicleSeats = "VehicleSeatIndicator",
			clock = "TimeManagerClockButton",
			garrison = "GarrisonLandingPageMinimapButton",
		}
	end

	for _, frame in pairs(frames) do
		if _G[frame] then
			_G[frame].__origParent = _G[frame]:GetParent():GetName()
		else
			Chinchilla:Print(frame, "has changed or no longer exists. Please notify the addon author.")
		end
	end

	self.db = Chinchilla.db:RegisterNamespace("ShowHide", {
		profile = {
			enabled = true,
			onMouseOver = true, calendarInviteOnly = false,

			boss = true, north = true, difficulty = true, map = true,
			mail = true, lfg = true, dayNight = true, track = true,
			zoom = true, clock = true, vehicleSeats = true,
			garrison = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

function ShowHide:OnEnable()
	if Chinchilla:IsRetail() then
		self:RegisterEvent("CALENDAR_ACTION_PENDING", "UpdateCalendar")
		self:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", "UpdateCalendar")
	end

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
			self:ShowFrame(frame)
		else
			-- Minimap:IsMouseOver() isn't going to return true with the config open, so just hide the button
		 	self:HideFrame(frame)
		end
	end
end

function ShowHide:UpdateCalendar()
	if not self.db.profile.calendarInviteOnly then return end

	if C_Calendar.GetNumPendingInvites() > 0 then
		self:ShowFrame("GameTimeFrame")
	else
		self:HideFrame("GameTimeFrame")
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
			self:ShowFrame(frame)
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
			self:HideFrame(frame)
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
		calendarInviteOnly = Chinchilla:IsRetail() and {
			name = L["Unread Invites Only"],
			desc = L["Only show the calendar when you have unread invites waiting for you."],
			type = 'toggle',
			order = 2,
			get = get, set = set,
			disabled = function() return self.db.profile.dayNight == false end,
		} or nil,
		description = {
			name = L["A gold tick means the button will be shown at all times. A silver tick means the button will be shown when you hover the cursor over the minimap. An empty tickbox means the button will not be shown at all."],
			type = "description",
			order = 3,
		},
		north = frames.north and {
			name = L["North"],
			desc = L["Show the north symbol on the minimap"],
			type = 'toggle',
			order = 4,
			get = get, set = set,
		} or nil,
		difficulty = frames.difficulty and {
			name = L["Instance difficulty"],
			desc = L["Show the instance difficulty flag on the minimap"],
			type = 'toggle',
			tristate = true,
			order = 5,
			get = get, set = set,
		} or nil,
		map = frames.map and {
			name = L["World map"],
			desc = L["Show the world map button"],
			type = 'toggle',
			tristate = true,
			order = 6,
			get = get, set = set,
		} or nil,
		mail = frames.mail and {
			name = L["Mail"],
			desc = L["Show the mail indicator"],
			type = 'toggle',
			tristate = true,
			order = 7,
			get = get, set = set,
		} or nil,
		lfg = frames.lfg and {
			name = L["LFG"],
			desc = L["Show the looking for group indicator"],
			type = 'toggle',
			order = 8,
			get = get, set = set,
		} or nil,
		track = frames.track and {
			name = L["Tracking"],
			desc = L["Show the tracking indicator"],
			type = 'toggle',
			tristate = true,
			order = 9,
			get = get, set = set,
		} or nil,
		garrison = frames.garrison and {
			name = L["Garrison"],
			desc = L["Show the garrison report button"],
			type = 'toggle',
			tristate = true,
			order = 10,
			get = get, set = set,
		} or nil,
		clock = frames.clock and {
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
		} or nil,
		dayNight = frames.dayNight and {
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
		} or nil,
		zoom = frames.zoomIn and {
			name = L["Zoom"],
			desc = L["Show the zoom in and out buttons"],
			type = 'toggle',
			tristate = true,
			order = 14,
			get = get, set = set,
		} or nil,
		vehicleSeats = frames.vehicleSeats and {
			name = L["Vehicle seats"],
			desc = L["Show the vehicle seats indicator"],
			type = 'toggle',
			order = 15,
			get = get, set = set,
		} or nil,
		boss = frames.boss and {
			name = L["Boss frames"],
			desc = L["Show the boss unit frames"],
			type = 'toggle',
			order = 16,
			get = get, set = set,
		} or nil,
	}
end
