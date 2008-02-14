local VERSION = tonumber(("$Revision$"):match("%d+"))

local Chinchilla = Chinchilla
local Chinchilla_MoveButtons = Chinchilla:NewModule("MoveButtons", "LibRockHook-1.0")
local self = Chinchilla_MoveButtons
if Chinchilla.revision < VERSION then
	Chinchilla.version = "1.0r" .. VERSION
	Chinchilla.revision = VERSION
	Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")
end
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_MoveButtons.desc = L["Move buttons around the minimap"]

local buttons = {
	battleground = MiniMapBattlefieldFrame,
	map = MiniMapWorldMapButton,
	mail = MiniMapMailFrame,
	lfg = MiniMapMeetingStoneFrame,
	clock = GameTimeFrame,
	track = MiniMapTracking,
	voice = MiniMapVoiceChatFrame,
	zoomIn = MinimapZoomIn,
	zoomOut = MinimapZoomOut
}

local buttonStarts = {}

local function getOffset(deg)
	local angle = math.rad(deg)
	
	local cos, sin = math.cos(angle), math.sin(angle)
	
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	
	local round = true
	if minimapShape == "ROUND" then
		-- do nothing
	elseif minimapShape == "SQUARE" then
		round = false
	elseif minimapShape == "CORNER-TOPRIGHT" then
		if cos < 0 or sin < 0 then
			round = false
		end
	elseif minimapShape == "CORNER-TOPLEFT" then
		if cos > 0 or sin < 0 then
			round = false
		end
	elseif minimapShape == "CORNER-BOTTOMRIGHT" then
		if cos < 0 or sin > 0 then
			round = false
		end
	elseif minimapShape == "CORNER-BOTTOMLEFT" then
		if cos > 0 or sin > 0 then
			round = false
		end
	elseif minimapShape == "SIDE-LEFT" then
		if cos > 0 then
			round = false
		end
	elseif minimapShape == "SIDE-RIGHT" then
		if cos < 0 then
			round = false
		end
	elseif minimapShape == "SIDE-TOP" then
		if sin < 0 then
			round = false
		end
	elseif minimapShape == "SIDE-BOTTOM" then
		if sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-TOPRIGHT" then
		if cos < 0 and sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-TOPLEFT" then
		if cos > 0 and sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMRIGHT" then
		if cos < 0 and sin < 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMLEFT" then
		if cos > 0 and sin < 0 then
			round = false
		end
	end
	
	if round then
		return 80 * cos, 80 * sin
	else
		return math.max(-82, math.min(110 * cos, 84)), math.max(-86, math.min(110 * sin, 82))
	end
end

local function getAngle(x1, y1)
	local x2, y2 = Minimap:GetCenter()
	local x, y = x1 - x2, y1 - y2
	local deg = math.deg(math.atan2(y, x))
	while deg < 0 do
		deg = deg + 360
	end
	while deg > 360 do
		deg = deg - 360
	end
	return math.floor(deg + 0.5)
end

local function button_OnUpdate(this)
	this:ClearAllPoints()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	x, y = x / scale, y / scale
	local deg = math.floor(getAngle(x, y) + 0.5)
	for k,v in pairs(buttons) do
		if v == this then
			self.db.profile[k] = deg
			break
		end
	end
	this:ClearAllPoints()
	this:SetPoint("CENTER", Minimap, "CENTER", getOffset(deg))
	
	Rock("LibRockConfig-1.0"):RefreshConfigMenu(Chinchilla)
end
local function button_OnDragStart(this)
	this.isMoving = true
	this:SetScript("OnUpdate", button_OnUpdate)
	this:StartMoving()
end
local function button_OnDragStop(this)
	if not this.isMoving then
		return
	end
	this.isMoving = nil
	this:SetScript("OnUpdate", nil)
	this:StopMovingOrSizing()
	button_OnUpdate(this)
end

function Chinchilla_MoveButtons:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("MoveButtons")
	Chinchilla:SetDatabaseNamespaceDefaults("MoveButtons", "profile", {
	})
	
	for k,v in pairs(buttons) do
		buttonStarts[k] = getAngle(v:GetCenter())
	end
end

function Chinchilla_MoveButtons:OnEnable()
	for k,v in pairs(buttons) do
		v:SetMovable(true)
		v:RegisterForDrag("LeftButton")
		v:SetScript("OnDragStart", button_OnDragStart)
		v:SetScript("OnDragStop", button_OnDragStop)
	end
	self:Update()
end

function Chinchilla_MoveButtons:OnDisable()
	for k,v in pairs(buttons) do
		v:SetMovable(false)
		v:RegisterForDrag()
		v:SetScript("OnDragStart", nil)
		v:SetScript("OnDragStop", nil)
		
		local deg = buttonStarts[k]
		v:ClearAllPoints()
		v:SetPoint("CENTER", Minimap, "CENTER", getOffset(deg))
	end
end

function Chinchilla_MoveButtons:Update()
	for k,v in pairs(buttons) do
		local deg = self.db.profile[k] or buttonStarts[k]
		if not deg then
			deg = getAngle(v:GetCenter())
		end
		v:ClearAllPoints()
		v:SetPoint("CENTER", Minimap, "CENTER", getOffset(deg))
	end
end

local function get(key)
	return self.db.profile[key] or getAngle(buttons[key]:GetCenter())
end

local function set(key, value)
	self.db.profile[key] = value
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	buttons[key]:ClearAllPoints()
	buttons[key]:SetPoint("CENTER", Minimap, "CENTER", getOffset(value))
end

Chinchilla_MoveButtons:AddChinchillaOption({
	name = L["Move Buttons"],
	desc = Chinchilla_MoveButtons.desc,
	type = 'group',
	args = {
		battleground = {
			name = L["Battleground"],
			desc = L["Set the position of the battleground indicator"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'battleground',
			get = get,
			set = set,
		},
		map = {
			name = L["World map"],
			desc = L["Set the position of the world map button"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'map',
			get = get,
			set = set,
		},
		mail = {
			name = L["Mail"],
			desc = L["Set the position of the mail indicator"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'mail',
			get = get,
			set = set,
		},
		lfg = {
			name = L["LFG"],
			desc = L["Set the position of the looking for group indicator"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'lfg',
			get = get,
			set = set,
		},
		clock = {
			name = L["Clock"],
			desc = L["Set the position of the clock"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'clock',
			get = get,
			set = set,
		},
		track = {
			name = L["Tracking"],
			desc = L["Set the position of the tracking indicator"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'track',
			get = get,
			set = set,
		},
		voice = {
			name = L["Voice chat"],
			desc = L["Set the position of the voice chat button"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'voice',
			get = get,
			set = set,
		},
		zoomIn = {
			name = L["Zoom in"],
			desc = L["Set the position of the zoom in button"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'zoomIn',
			get = get,
			set = set,
		},
		zoomOut = {
			name = L["Zoom out"],
			desc = L["Set the position of the zoom out button"],
			type = 'range',
			min = 0,
			max = 360,
			step = 1,
			bigStep = 5,
			passValue = 'zoomOut',
			get = get,
			set = set,
		},
	}
})
