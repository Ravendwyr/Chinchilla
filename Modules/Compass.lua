
local Compass = Chinchilla:NewModule("Compass", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Compass.displayName = L["Compass"]
Compass.desc = L["Show direction indicators on the minimap"]


function Compass:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Compass", {
		profile = {
			radius = 61,
			color = { 1, 0.82, 0, 1 },
			fontSize = 12,
			nonNorthSize = 0.8,
			enabled = false,
		}
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local rotateMinimap
local frame
local function repositionCompass()
	local angle = 0
	local facing = GetPlayerFacing() or 0

	if rotateMinimap == "1" then
		angle = -facing or angle
	end

	local radius = Compass.db.profile.radius
	frame.east:SetPoint("CENTER", Minimap, "CENTER", radius*math.cos(angle), radius*math.sin(angle))
	frame.north:SetPoint("CENTER", Minimap, "CENTER", radius*math.cos(angle + math.pi/2), radius*math.sin(angle + math.pi/2))
	frame.west:SetPoint("CENTER", Minimap, "CENTER", radius*math.cos(angle + math.pi), radius*math.sin(angle + math.pi))
	frame.south:SetPoint("CENTER", Minimap, "CENTER", radius*math.cos(angle + math.pi*3/2), radius*math.sin(angle + math.pi*3/2))
end

function Compass:OnEnable()
	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Compass_Frame", MinimapBackdrop)
		frame:SetAllPoints()

		local north = frame:CreateFontString(frame:GetName() .. "_North", "ARTWORK", "GameFontNormal")
		frame.north = north
		north:SetText("N")

		local east = frame:CreateFontString(frame:GetName() .. "_East", "ARTWORK", "GameFontNormalSmall")
		frame.east = east
		east:SetText("E")

		local south = frame:CreateFontString(frame:GetName() .. "_South", "ARTWORK", "GameFontNormalSmall")
		frame.south = south
		south:SetText("S")

		local west = frame:CreateFontString(frame:GetName() .. "_West", "ARTWORK", "GameFontNormalSmall")
		frame.west = west
		west:SetText("W")
	end

	MinimapCompassTexture:SetAlpha(0)
	MinimapNorthTag:SetAlpha(0)

	frame:Show()

	rotateMinimap = GetCVar("rotateMinimap")
	repositionCompass()

	if rotateMinimap == "1" then
		frame:SetScript("OnUpdate", repositionCompass)
	end

	self:RegisterEvent("CVAR_UPDATE")
	self:SetFontSize()
	self:SetColor()
end

function Compass:OnDisable()
	frame:SetScript("OnUpdate", nil)
	frame:Hide()

	MinimapCompassTexture:SetAlpha(1)
	MinimapNorthTag:SetAlpha(1)
end


function Compass:CVAR_UPDATE(_, key, value)
	if key == "ROTATE_MINIMAP" then
		rotateMinimap = value

		if value == "1" then
			frame:SetScript("OnUpdate", repositionCompass)
		else
			frame:SetScript("OnUpdate", nil)
			repositionCompass()
		end
	end
end


function Compass:SetRadius(value)
	self.db.profile.radius = value

	if self:IsEnabled() then
		repositionCompass()
	end
end

function Compass:SetColor(r, g, b, a)
	local color = self.db.profile.color

	if r then
		color[1] = r
		color[2] = g
		color[3] = b
		color[4] = a
	else
		r, g, b, a = unpack(color)
	end

	if frame then
		frame.north:SetTextColor(r, g, b, a)
		frame.east:SetTextColor(r, g, b, a)
		frame.south:SetTextColor(r, g, b, a)
		frame.west:SetTextColor(r, g, b, a)
	end
end

function Compass:SetFontSize(value)
	if value then self.db.profile.fontSize = value
	else value = self.db.profile.fontSize end

	local nonNorthSize = self.db.profile.nonNorthSize

	if frame then
		local font, _, style = frame.north:GetFont()

		frame.north:SetFont(font, value, style)
		frame.east:SetFont(font, value*nonNorthSize, style)
		frame.south:SetFont(font, value*nonNorthSize, style)
		frame.west:SetFont(font, value*nonNorthSize, style)
	end
end

function Compass:SetNonNorthSize(value)
	self.db.profile.nonNorthSize = value
	self:SetFontSize(nil)
end


function Compass:GetOptions()
	return {
		radius = {
			name = L["Radius"],
			desc = L["The distance from the center of the minimap to show the indicators."],
			type = 'range',
			min = 50,
			max = 100,
			step = 1,
			get = function()
				return self.db.profile.radius
			end,
			set = function(_, value)
				self:SetRadius(value)
			end,
		},
		color = {
			name = L["Color"],
			desc = L["Color of the indicators"],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.color)
			end,
			set = function(_, r, g, b, a)
				self:SetColor(r, g, b, a)
			end,
		},
		fontSize = {
			name = L["Size"],
			desc = L["Size of the indicators"],
			type = 'range',
			min = 6,
			max = 24,
			step = 1,
			get = function()
				return self.db.profile.fontSize
			end,
			set = function(_, value)
				self:SetFontSize(value)
			end,
		},
		nonNorthSize = {
			name = L["Non-north size"],
			desc = L["Size of the east, west, and south indicators relative to the north indicator"],
			type = 'range',
			min = 0.5,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
			get = function()
				return self.db.profile.nonNorthSize
			end,
			set = function(_, value)
				self:SetNonNorthSize(value)
			end,
		},
	}
end
