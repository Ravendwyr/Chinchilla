local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_MoveButtons = Chinchilla:NewModule("MoveButtons", "LibRockHook-1.0")
local self = Chinchilla_MoveButtons
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
		if cos < 0 and sin < 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-TOPLEFT" then
		if cos > 0 and sin < 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMRIGHT" then
		if cos < 0 and sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMLEFT" then
		if cos > 0 and sin > 0 then
			round = false
		end
	end
	
	local radius = Chinchilla_MoveButtons.db.profile.radius
	
	if round then
		return radius * cos, radius * sin
	else
		local x = radius * 2^0.5 * cos
		local y = radius * 2^0.5 * sin
		if x < -radius then
			x = -radius
		elseif x > radius then
			x = radius
		end
		if y < -radius then
			y = -radius
		elseif y > radius then
			y = radius
		end
		return x, y
	end
end

local function getAngle(x1, y1)
	local x2, y2 = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale()
	x2 = x2*scale
	y2 = y2*scale
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
	local deg
	if not IsAltKeyDown() then
		x, y = x / scale, y / scale
		deg = math.floor(getAngle(x, y) + 0.5)
		for k,v in pairs(buttons) do
			if v == this then
				self.db.profile[k] = deg
				break
			end
		end
	else
		for k,v in pairs(buttons) do
			if v == this then
				deg = self.db.profile[k]
				if type(deg) == "number" then
					deg = {}
					self.db.profile[k] = deg
				end
				break
			end
		end
		assert(deg)
		deg[1] = x / Minimap:GetEffectiveScale()
		deg[2] = y / Minimap:GetEffectiveScale()
	end
	this:ClearAllPoints()
	if type(deg) == "table" then
		this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", deg[1], deg[2])
	else
		this:SetPoint("CENTER", Minimap, "CENTER", getOffset(deg))
	end
	
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
		lock = false,
		radius = 80,
	})
	
	for k,v in pairs(buttons) do
		buttonStarts[k] = getAngle(v:GetCenter())
	end
end

function Chinchilla_MoveButtons:OnEnable()
	self:SetLocked(nil)
	self:Update()
end

function Chinchilla_MoveButtons:OnDisable()
	self:SetLocked(nil)
	for k,v in pairs(buttons) do
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
		if type(deg) == "table" then
			v:SetPoint("CENTER", UIParent, "BOTTOMLEFT", deg[1], deg[2])
		else
			v:SetPoint("CENTER", Minimap, "CENTER", getOffset(deg))
		end
	end
end

local function get(key)
	return self.db.profile[key] or getAngle(buttons[key]:GetCenter())
end
local angle_get = get

local function set(key, value)
	self.db.profile[key] = value
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	buttons[key]:ClearAllPoints()
	buttons[key]:SetPoint("CENTER", Minimap, "CENTER", getOffset(value))
end
local angle_set = set

local function attach_get(key)
	return not self.db.profile[key] or type(self.db.profile[key]) == "number"
end

local function not_attach_get(key)
	return not attach_get(key)
end

local function attach_set(key, value)
	if not value then
		self.db.profile[key] = { buttons[key]:GetCenter() }
	else
		self.db.profile[key] = getAngle(buttons[key]:GetCenter())
		buttons[key]:ClearAllPoints()
		buttons[key]:SetPoint("CENTER", Minimap, "CENTER", getOffset(self.db.profile[key]))
	end
end

local function x_get(key)
	return self.db.profile[key][1]
end

local function x_set(key, value)
	self.db.profile[key][1] = value
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	buttons[key]:ClearAllPoints()
	buttons[key]:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(self.db.profile[key]))
end

local function y_get(key)
	return self.db.profile[key][2]
end

local function y_set(key, value)
	self.db.profile[key][2] = value
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	buttons[key]:ClearAllPoints()
	buttons[key]:SetPoint("CENTER", UIParent, "BOTTOMLEFT", unpack(self.db.profile[key]))
end

local function x_max()
	return math.floor(GetScreenWidth()/10 + 0.5) * 10
end

local function y_max()
	return math.floor(GetScreenHeight()/10 + 0.5) * 10
end

function Chinchilla_MoveButtons:IsLocked()
	return self.db.profile.lock
end

function Chinchilla_MoveButtons:SetLocked(value)
	if value ~= nil then
		self.db.profile.lock = value
	else
		value = self.db.profile.lock
	end
	if not Chinchilla:IsModuleActive(self) then
		value = true
	end
	if value then
		for k,v in pairs(buttons) do
			v:SetMovable(false)
			v:RegisterForDrag()
			v:SetScript("OnDragStart", nil)
			v:SetScript("OnDragStop", nil)
		end
	else
		for k,v in pairs(buttons) do
			v:SetMovable(true)
			v:RegisterForDrag("LeftButton")
			v:SetScript("OnDragStart", button_OnDragStart)
			v:SetScript("OnDragStop", button_OnDragStop)
		end
	end
end

function Chinchilla_MoveButtons:SetRadius(value)
	if value then
		self.db.profile.radius = value
	end
	self:Update()
end

local args = {
	attach = {
		name = L["Attach to minimap"],
		desc = L["Whether to stay attached to the minimap or move freely.\nNote: If you hold Alt while dragging, it will automatically unattach."],
		type = 'boolean',
		get = attach_get,
		set = attach_set,
		order = 1,
	},
	angle = {
		name = L["Angle"],
		desc = L["Angle on the minimap"],
		type = 'number',
		min = 0,
		max = 360,
		step = 1,
		bigStep = 5,
		get = angle_get,
		set = angle_set,
		hidden = not_attach_get,
	},
	x = {
		name = L["Horizontal position"],
		desc = L["Horizontal position of the button on-screen"],
		type = 'range',
		min = 0,
		max = x_max,
		step = 1,
		bigStep = 5,
		get = x_get,
		set = x_set,
		hidden = attach_get,
	},
	y = {
		name = L["Vertical position"],
		desc = L["Vertical position of the button on-screen"],
		type = 'range',
		min = 0,
		max = y_max,
		step = 1,
		bigStep = 5,
		get = y_get,
		set = y_set,
		hidden = attach_get,
	},
}

Chinchilla_MoveButtons:AddChinchillaOption({
	name = L["Move Buttons"],
	desc = Chinchilla_MoveButtons.desc,
	type = 'group',
	args = {
		lock = {
			name = L["Lock"],
			desc = L["Lock buttons in place so that they won't be mistakenly dragged"],
			type = 'boolean',
			order = 2,
			get = "IsLocked",
			set = "SetLocked",
		},
		radius = {
			name = L["Radius"],
			desc = L["Set how far away from the center to place buttons on the minimap"],
			type = 'number',
			order = 3,
			min = 60,
			max = 100,
			step = 1,
			get = function()
				return Chinchilla_MoveButtons.db.profile.radius
			end,
			set = "SetRadius",
		},
		battleground = {
			name = L["Battleground"],
			desc = L["Set the position of the battleground indicator"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'battleground',
			args = args,
		},
		map = {
			name = L["World map"],
			desc = L["Set the position of the world map button"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'map',
			args = args,
		},
		mail = {
			name = L["Mail"],
			desc = L["Set the position of the mail indicator"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'mail',
			args = args,
		},
		lfg = {
			name = L["LFG"],
			desc = L["Set the position of the looking for group indicator"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'lfg',
			args = args,
		},
		clock = {
			name = L["Clock"],
			desc = L["Set the position of the clock"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'clock',
			args = args,
		},
		track = {
			name = L["Tracking"],
			desc = L["Set the position of the tracking indicator"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'track',
			args = args,
		},
		voice = {
			name = L["Voice chat"],
			desc = L["Set the position of the voice chat button"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'voice',
			args = args,
		},
		zoomIn = {
			name = L["Zoom in"],
			desc = L["Set the position of the zoom in button"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'zoomIn',
			args = args,
		},
		zoomOut = {
			name = L["Zoom out"],
			desc = L["Set the position of the zoom out button"],
			type = 'group',
			groupType = 'inline',
			child_passValue = 'zoomOut',
			args = args,
		},
	}
})
