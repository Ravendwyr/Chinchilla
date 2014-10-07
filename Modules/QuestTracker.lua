
local QuestTracker = Chinchilla:NewModule("QuestTracker")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

QuestTracker.displayName = L["Quest Tracker"]
QuestTracker.desc = L["Tweak the quest tracker"]


local toc = select(4, GetBuildInfo())
local button, headers


function QuestTracker:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("QuestTracker", {
		profile = {
			enabled = true,

			frameHeight = 700,
			showTitle = true, showCollapseButton = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end

	if toc == 60000 then
		-- Warlords of Draenor
		button = _G.ObjectiveTrackerFrame.HeaderMenu.MinimizeButton
		headers = { "QuestHeader", "AchievementHeader", "ScenarioHeader" }
	else
		-- Mists of Pandaria
		button = _G.WatchFrameCollapseExpandButton
	end
end

function QuestTracker:OnEnable()
	self:ToggleTitle()
	self:ToggleCollapseButton()

	if toc == 60000 then
		-- Warlords of Draenor
		ObjectiveTrackerFrame:SetHeight(self.db.profile.frameHeight)
	else
		-- Mists of Pandaria
		WatchFrame:SetHeight(self.db.profile.frameHeight)
	end
end

function QuestTracker:OnDisable()
	button:EnableMouse(true)
	button:SetAlpha(1)

	if toc == 60000 then
		-- Warlords of Draenor
		for _, header in pairs(headers) do
			_G.ObjectiveTrackerBlocksFrame[header]:SetAlpha(1)
		end
	else
		-- Mists of Pandaria
		WatchFrameHeader:EnableMouse(true)
		WatchFrameHeader:SetAlpha(1)
	end
end


function QuestTracker:ToggleTitle()
	local value = self.db.profile.showTitle

	if toc == 60000 then
		-- Warlords of Draenor
		for _, header in pairs(headers) do
			_G.ObjectiveTrackerBlocksFrame[header]:SetAlpha(value and 1 or 0)
		end
	else
		-- Mists of Pandaria
		if value then
			WatchFrameHeader:EnableMouse(true)
			WatchFrameHeader:SetAlpha(1)
		else
			WatchFrameHeader:EnableMouse(false)
			WatchFrameHeader:SetAlpha(0)
		end
	end
end

function QuestTracker:ToggleCollapseButton()
	if self.db.profile.showCollapseButton then
		button:EnableMouse(true)
		button:SetAlpha(1)
	else
		button:EnableMouse(false)
		button:SetAlpha(0)
	end
end


function QuestTracker:GetOptions()
	return {
		showTitle = {
			name = L["Show title"],
			desc = L["Show the title of the quest tracker."],
			type = 'toggle',
			get = function() return self.db.profile.showTitle end,
			set = function(_, value)
				self.db.profile.showTitle = value
				self:ToggleTitle()
			end,
			order = 1,
		},
		showCollapseButton = {
			name = L["Show collapse button"],
			desc = L["Show the collapse button on the quest tracker."],
			type = 'toggle',
			get = function() return self.db.profile.showCollapseButton end,
			set = function(_, value)
				self.db.profile.showCollapseButton = value
				self:ToggleCollapseButton()
			end,
			order = 2,
		},
		frameHeight = {
			name = L["Height"],
			desc = L["Set the height of the quest tracker."],
			type = 'range',
			min = 140,
			max = math.floor(GetScreenHeight()),
			step = 1, bigStep = 5,
			get = function() return self.db.profile.frameHeight end,
			set = function(_, value)
				self.db.profile.frameHeight = value

				if toc == 60000 then
					-- Warlords of Draenor
					ObjectiveTrackerFrame:SetHeight(value)
				else
					-- Mists of Pandaria
					WatchFrame:SetHeight(value)
				end
			end,
			order = 3,
		},
	}
end
