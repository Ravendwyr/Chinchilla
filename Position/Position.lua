local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_Position = Chinchilla:NewModule("Position", "LibRockHook-1.0", "LibRockEvent-1.0")
local self = Chinchilla_Position
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Position.desc = L["Allow for moving of the minimap and surrounding frames"]

function Chinchilla_Position:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Position")
	Chinchilla:SetDatabaseNamespaceDefaults("Position", "profile", {
		minimap = { "TOPRIGHT", 0, 0 },
		minimapLock = false,
		durability = { "TOPRIGHT", -143, -221 },
		questWatch = { "TOPRIGHT", -183, -226 },
		questTimer = { "TOPRIGHT", -173, -211 },
		capture = { "TOPRIGHT", -9, -190 },
	})
end

local function Minimap_OnDragStart(this)
	MinimapCluster:StartMoving()
end

local function getPointXY(frame)
	local x, y = frame:GetCenter()
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	x = x*scale
	y = y*scale
	local width, height = GetScreenWidth(), GetScreenHeight()
	local point
	if x < width/3 then
		x = frame:GetLeft()*scale
		point = "LEFT"
		if frame == MinimapCluster then
			if x < -35*scale then
				x = -35*scale
			end
		else
			if x < 0 then
				x = 0
			end
		end
	elseif x < width*2/3 then
		x = x - width/2
		point = "CENTER"
	else
		x = frame:GetRight()*scale - width
		point = "RIGHT"
		if frame == MinimapCluster then
			if x > 17*scale then
				x = 17*scale
			end
		else
			if x > 0 then
				x = 0
			end
		end
	end
	
	if y < height/3 then
		point = "BOTTOM" .. (point == "CENTER" and "" or point)
		y = frame:GetBottom()*scale
		if frame == MinimapCluster then
			if y < -30*scale then
				y = -30*scale
			end
		else
			if y < 0 then
				y = 0
			end
		end
	elseif y < height*2/3 then
		y = y - height/2
	else
		point = "TOP" .. (point == "CENTER" and "" or point)
		y = frame:GetTop()*scale - height
		if frame == MinimapCluster then
			if y > 22*scale then
				y = 22*scale
			end
		else
			if y > 0 then
				y = 0
			end
		end
	end
	return point, x/scale, y/scale
end

local function Minimap_OnDragStop(this)
	MinimapCluster:StopMovingOrSizing()
	local point, x, y = getPointXY(MinimapCluster)
	self:SetMinimapPosition(point, x, y)
	Rock("LibRockConfig-1.0"):RefreshConfigMenu(Chinchilla)
end

function Chinchilla_Position:OnEnable()
	self:SetMinimapPosition(nil, nil, nil)
	self:SetFramePosition('durability', nil, nil, nil)
	self:SetFramePosition('questWatch', nil, nil, nil)
	self:SetFramePosition('questTimer', nil, nil, nil)
	self:SetFramePosition('capture', nil, nil, nil)
	self:SetLocked(nil)
	
	Minimap:SetClampedToScreen(true)
	
	--hack so that frame positioning doesn't break
	MinimapCluster:SetMovable(true)
	MinimapCluster:StartMoving()
  	MinimapCluster:StopMovingOrSizing()
	
	self:AddSecureHook(DurabilityFrame, "SetPoint", "DurabilityFrame_SetPoint")
	self:AddSecureHook(QuestWatchFrame, "SetPoint", "QuestWatchFrame_SetPoint")
	self:AddSecureHook(QuestTimerFrame, "SetPoint", "QuestTimerFrame_SetPoint")
	
	self:AddEventListener("UPDATE_WORLD_STATES")
end

function Chinchilla_Position:OnDisable()
	self:SetMinimapPosition(nil, nil, nil)
	self:ShowFrameMover('durability', false)
	self:ShowFrameMover('questWatch', false)
	self:ShowFrameMover('questTimer', false)
	self:ShowFrameMover('capture', false)
	self:SetFramePosition('durability', nil, nil, nil)
	self:SetFramePosition('questWatch', nil, nil, nil)
	self:SetFramePosition('questTimer', nil, nil, nil)
	self:SetFramePosition('capture', nil, nil, nil)
	self:SetLocked(nil)
	
	Minimap:SetClampedToScreen(false)
end

function Chinchilla_Position:UPDATE_WORLD_STATES()
	self:SetFramePosition('capture', nil, nil, nil)
end

local quadrantToShape = {
	"CORNER-TOPRIGHT",
	"SIDE-TOP",
	"CORNER-TOPLEFT",
	"SIDE-RIGHT",
	"ROUND",
	"SIDE-LEFT",
	"CORNER-BOTTOMRIGHT",
	"SIDE-BOTTOM",
	"CORNER-BOTTOMLEFT",
}

function Chinchilla_Position:IsLocked()
	return self.db.profile.minimapLock
end

function Chinchilla_Position:SetLocked(value)
	if value ~= nil then
		self.db.profile.minimapLock = value
	else
		value = self.db.profile.minimapLock
	end
	if not Chinchilla:IsModuleActive(self) then
		value = true
	end
	if value then
		Minimap:RegisterForDrag()
		MinimapZoneTextButton:RegisterForDrag()
		Minimap:SetScript("OnDragStart", nil)
		Minimap:SetScript("OnDragStop", nil)
		MinimapZoneTextButton:SetScript("OnDragStart", nil)
		MinimapZoneTextButton:SetScript("OnDragStop", nil)
		MinimapCluster:SetMovable(false)
	else
		Minimap:RegisterForDrag("LeftButton")
		MinimapZoneTextButton:RegisterForDrag("LeftButton")
		Minimap:SetScript("OnDragStart", Minimap_OnDragStart)
		Minimap:SetScript("OnDragStop", Minimap_OnDragStop)
		MinimapZoneTextButton:SetScript("OnDragStart", Minimap_OnDragStart)
		MinimapZoneTextButton:SetScript("OnDragStop", Minimap_OnDragStop)
		MinimapCluster:SetMovable(true)
	end
end

local lastQuadrant
function Chinchilla_Position:SetMinimapPosition(point, x, y)
	if point then
		self.db.profile.minimap[1] = point
	else
		point = self.db.profile.minimap[1]
	end
	if x then
		self.db.profile.minimap[2] = x
	else
		x = self.db.profile.minimap[2]
	end
	if y then
		self.db.profile.minimap[3] = y
	else
		y = self.db.profile.minimap[3]
	end
	if not Chinchilla:IsModuleActive(self) then
		point, x, y = "TOPRIGHT", 0, 0
	end
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint(point, UIParent, point, x, y)
	
	local x, y = MinimapCluster:GetCenter()
	local scale = MinimapCluster:GetEffectiveScale() / UIParent:GetEffectiveScale()
	x = x*scale
	y = y*scale
	local quadrant = 0
	local width, height = GetScreenWidth(), GetScreenHeight()
	if x < width/3 then
		quadrant = 1
	elseif x < width*2/3 then
		quadrant = 2
	else
		quadrant = 3
	end
	if y < height/3 then
		quadrant = quadrant + 0
	elseif y < height*2/3 then
		quadrant = quadrant + 3
	else
		quadrant = quadrant + 6
	end
	if lastQuadrant and lastQuadrant ~= quadrant and Chinchilla:HasModule("Appearance") and Chinchilla:IsModuleActive("Appearance") and Chinchilla:GetModule("Appearance").db and Chinchilla:GetModule("Appearance").db.profile.shape == quadrantToShape[lastQuadrant] then
		Chinchilla:GetModule("Appearance"):SetShape(quadrantToShape[quadrant])
	end
	lastQuadrant = quadrant
end

local shouldntSetPoint = false
function Chinchilla_Position:DurabilityFrame_SetPoint(this)
	if shouldntSetPoint then
		return
	end
	self:SetFramePosition('durability', nil, nil, nil)
end

function Chinchilla_Position:QuestWatchFrame_SetPoint(this)
	if shouldntSetPoint then
		return
	end
	self:SetFramePosition('questWatch', nil, nil, nil)
end

function Chinchilla_Position:QuestTimerFrame_SetPoint(this)
	if shouldntSetPoint then
		return
	end
	self:SetFramePosition('questTimer', nil, nil, nil)
end

local nameToFrame = {
	durability = DurabilityFrame,
	questWatch = QuestWatchFrame,
	questTimer = QuestTimerFrame,
}
local movers = {}
function Chinchilla_Position:SetFramePosition(frame, point, x, y)
	if point then
		self.db.profile[frame][1] = point
	else
		point = self.db.profile[frame][1]
	end
	if x then
		self.db.profile[frame][2] = x
	else
		x = self.db.profile[frame][2]
	end
	if y then
		self.db.profile[frame][3] = y
	else
		y = self.db.profile[frame][3]
	end
	if not Chinchilla:IsModuleActive(self) then
		-- TODO: get defaults for each frame
		point, x, y = "TOPRIGHT", -143, -221
	end
	shouldntSetPoint = true
	if movers[frame] and movers[frame]:IsShown() then
		movers[frame]:ClearAllPoints()
		movers[frame]:SetPoint(point, UIParent, point, x, y)
	else
		if frame == "capture" then
			for i = 1, NUM_EXTENDED_UI_FRAMES do
				_G["WorldStateCaptureBar" .. i]:ClearAllPoints()
				_G["WorldStateCaptureBar" .. i]:SetPoint(point, UIParent, point, x, y)
			end
		else
			nameToFrame[frame]:ClearAllPoints()
			nameToFrame[frame]:SetPoint(point, UIParent, point, x, y)
		end
	end
	shouldntSetPoint = false
end

local function mover_OnDragStart(this)
	this:StartMoving()
end

local function mover_OnDragStop(this)
	this:StopMovingOrSizing()
	local point, x, y = getPointXY(this)
	self:SetFramePosition(this.name, point, x, y)
	Rock("LibRockConfig-1.0"):RefreshConfigMenu(Chinchilla)
end

local nameToNiceName = {
	durability = L["Durability"],
	questWatch = L["Quest tracker"],
	questTimer = L["Quest timer"],
	capture = L["Capture bar"],
}

function Chinchilla_Position:ShowFrameMover(frame, value)
	local mover = movers[frame]
	if value == not not (mover and mover:IsShown()) then
		return
	end
	if not Chinchilla:IsModuleActive(self) then
		value = false
	end
	if value and not mover then
		mover = CreateFrame("Frame", "Chinchilla_Position_" .. frame .. "_Mover", UIParent)
		movers[frame] = mover
		mover.name = frame
		if frame ~= 'capture' then
			mover:SetFrameStrata(nameToFrame[frame]:GetFrameStrata())
			mover:SetFrameLevel(nameToFrame[frame]:GetFrameLevel())
		end
		mover:SetClampedToScreen(true)
		mover:EnableMouse(true)
		mover:SetMovable(true)
		mover:RegisterForDrag("LeftButton")
		mover:SetScript("OnDragStart", mover_OnDragStart)
		mover:SetScript("OnDragStop", mover_OnDragStop)
		local tex = mover:CreateTexture(mover:GetName() .. "_Texture", "BACKGROUND")
		tex:SetAllPoints(mover)
		tex:SetTexture(1, 0.5, 0, 0.5)
		local text = mover:CreateFontString(mover:GetName() .. "_FontString", "ARTWORK", "GameFontHighlight")
		text:SetPoint("CENTER")
		text:SetText(nameToNiceName[frame])
	end
	if not value then
		if mover then
			mover:Hide()
			self:SetFramePosition(frame, nil, nil, nil)
		end
	else
		if frame == 'capture' then
			mover:SetWidth(173)
			mover:SetHeight(26)
		else
			mover:SetWidth(nameToFrame[frame]:GetWidth())
			mover:SetHeight(nameToFrame[frame]:GetHeight())
		end
		shouldntSetPoint = true
		mover:Show()
		mover:ClearAllPoints()
		mover:SetPoint(self.db.profile[frame][1], UIParent, self.db.profile[frame][1], self.db.profile[frame][2], self.db.profile[frame][3])
		if frame == "capture" then
			for i = 1, NUM_EXTENDED_UI_FRAMES do
				_G["WorldStateCaptureBar" .. i]:ClearAllPoints()
				_G["WorldStateCaptureBar" .. i]:SetAllPoints(mover)
			end
		else
			nameToFrame[frame]:ClearAllPoints()
			nameToFrame[frame]:SetAllPoints(mover)
		end
		shouldntSetPoint = false
	end
end

local choices = {
	TOP = L["Top"],	
	LEFT = L["Left"],
	RIGHT = L["Right"],
	BOTTOM = L["Bottom"],
	CENTER = L["Center"],
	TOPLEFT = L["Top-left"],
	TOPRIGHT = L["Top-right"],
	BOTTOMLEFT = L["Bottom-left"],
	BOTTOMRIGHT = L["Bottom-right"],
}

local function movable_get(frame)
	return movers[frame] and movers[frame]:IsShown()
end

local function point_get(frame)
	return self.db.profile[frame][1]
end

local function point_set(frame, value)
	self:SetFramePosition(frame, value, nil, nil)
end

local function x_get(frame)
	return self.db.profile[frame][2]
end

local function x_set(frame, value)
	self:SetFramePosition(frame, nil, value, nil)
end

local function y_get(frame)
	return self.db.profile[frame][3]
end

local function y_set(frame, value)
	self:SetFramePosition(frame, nil, nil, value)
end

local function x_min()
	return -math.floor(GetScreenWidth()/5 + 0.5)*5
end

local function x_max()
	return math.floor(GetScreenWidth()/5 + 0.5)*5
end

local function y_min()
	return -math.floor(GetScreenHeight()/5 + 0.5)*5
end

local function y_max()
	return math.floor(GetScreenHeight()/5 + 0.5)*5
end

Chinchilla_Position:AddChinchillaOption({
	name = L["Position"],
	desc = Chinchilla_Position.desc,
	type = 'group',
	args = {
		minimap = {
			name = L["Minimap"],
			desc = L["Position of the minimap on the screen"],
			type = 'group',
			groupType = 'inline',
			args = {
				lock = {
					name = L["Lock"],
					desc = L["Lock the minimap so it cannot be mistakenly dragged"],
					type = 'boolean',
					order = 1,
					get = "IsLocked",
					set = "SetLocked"
				},
				point = {
					name = L["Point"],
					desc = L["Point of the screen the minimap is anchored to"],
					type = 'choice',
					choices = choices,
					order = 2,
					get = function()
						return self.db.profile.minimap[1]
					end,
					set = function(value)
						self:SetMinimapPosition(value, nil, nil)
					end
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the minimap."],
					type = 'range',
					min = function()
						return -math.floor(GetScreenWidth()/5 + 0.5)*5
					end,
					max = function()
						return math.floor(GetScreenWidth()/5 + 0.5)*5
					end,
					step = 1,
					bigStep = 5,
					get = function()
						return self.db.profile.minimap[2]
					end,
					set = function(value)
						self:SetMinimapPosition(nil, value, nil)
					end,
					order = 3,
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the minimap."],
					type = 'range',
					min = function()
						return -math.floor(GetScreenHeight()/5 + 0.5)*5
					end,
					max = function()
						return math.floor(GetScreenHeight()/5 + 0.5)*5
					end,
					step = 1,
					bigStep = 5,
					stepBasis = 0,
					get = function()
						return self.db.profile.minimap[3]
					end,
					set = function(value)
						self:SetMinimapPosition(nil, nil, value)
					end,
					order = 4,
				},
			}
		},
		durability = {
			name = L["Durability"],
			desc = L["Position of the metal durability man on the screen"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Show a frame that is movable to show where you want the durability man to be"],
					type = 'boolean',
					order = 1,
					get = movable_get,
					set = "ShowFrameMover",
					passValue = 'durability',
				},
				point = {
					name = L["Point"],
					desc = L["Point of the screen the durability man is anchored to"],
					type = 'choice',
					choices = choices,
					order = 2,
					get = point_get,
					set = point_set,
					passValue = 'durability',
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the durability man."],
					type = 'range',
					min = x_min,
					max = x_max,
					step = 1,
					bigStep = 5,
					get = x_get,
					set = x_set,
					order = 3,
					passValue = 'durability',
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the durability man."],
					type = 'range',
					min = y_min,
					max = y_max,
					step = 1,
					bigStep = 5,
					stepBasis = 0,
					get = y_get,
					set = y_set,
					order = 4,
					passValue = 'durability',
				},
			}
		},
		questWatch = {
			name = L["Quest tracker"],
			desc = L["Position of the quest tracker on the screen"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Show a frame that is movable to show where you want the quest tracker to be"],
					type = 'boolean',
					order = 1,
					get = movable_get,
					set = "ShowFrameMover",
					passValue = 'questWatch',
				},
				point = {
					name = L["Point"],
					desc = L["Point of the screen the quest tracker is anchored to"],
					type = 'choice',
					choices = choices,
					order = 2,
					get = point_get,
					set = point_set,
					passValue = 'questWatch',
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the quest tracker."],
					type = 'range',
					min = x_min,
					max = x_max,
					step = 1,
					bigStep = 5,
					get = x_get,
					set = x_set,
					order = 3,
					passValue = 'questWatch',
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the quest tracker."],
					type = 'range',
					min = y_min,
					max = y_max,
					step = 1,
					bigStep = 5,
					stepBasis = 0,
					get = y_get,
					set = y_set,
					order = 4,
					passValue = 'questWatch',
				},
			}
		},
		questTimer = {
			name = L["Quest timer"],
			desc = L["Position of the quest timer on the screen"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Show a frame that is movable to show where you want the quest timer to be"],
					type = 'boolean',
					order = 1,
					get = movable_get,
					set = "ShowFrameMover",
					passValue = 'questTimer',
				},
				point = {
					name = L["Point"],
					desc = L["Point of the screen the quest timer is anchored to"],
					type = 'choice',
					choices = choices,
					order = 2,
					get = point_get,
					set = point_set,
					passValue = 'questTimer',
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the quest timer."],
					type = 'range',
					min = x_min,
					max = x_max,
					step = 1,
					bigStep = 5,
					get = x_get,
					set = x_set,
					order = 3,
					passValue = 'questTimer',
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the quest timer."],
					type = 'range',
					min = y_min,
					max = y_max,
					step = 1,
					bigStep = 5,
					stepBasis = 0,
					get = y_get,
					set = y_set,
					order = 4,
					passValue = 'questTimer',
				},
			}
		},
		capture = {
			name = L["Capture bar"],
			desc = L["Position of the capture bar on the screen"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Show a frame that is movable to show where you want the capture bar to be"],
					type = 'boolean',
					order = 1,
					get = movable_get,
					set = "ShowFrameMover",
					passValue = 'capture',
				},
				point = {
					name = L["Point"],
					desc = L["Point of the screen the capture bar is anchored to"],
					type = 'choice',
					choices = choices,
					order = 2,
					get = point_get,
					set = point_set,
					passValue = 'capture',
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the capture bar."],
					type = 'range',
					min = x_min,
					max = x_max,
					step = 1,
					bigStep = 5,
					get = x_get,
					set = x_set,
					order = 3,
					passValue = 'capture',
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the capture bar."],
					type = 'range',
					min = y_min,
					max = y_max,
					step = 1,
					bigStep = 5,
					stepBasis = 0,
					get = y_get,
					set = y_set,
					order = 4,
					passValue = 'capture',
				},
			}
		},
	}
})
