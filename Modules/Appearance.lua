
local Appearance = Chinchilla:NewModule("Appearance", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Appearance.displayName = L["Appearance"]
Appearance.desc = L["Allow for a customized look of the minimap"]


local DEFAULT_MINIMAP_WIDTH = Minimap:GetWidth()
local DEFAULT_MINIMAP_HEIGHT = Minimap:GetHeight()
local MINIMAP_POINTS = {}

for i = 1, Minimap:GetNumPoints() do
	MINIMAP_POINTS[i] = { Minimap:GetPoint(i) }
end


local rotateMinimap
function Appearance:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Appearance", {
		profile = {
			enabled = true,
			scale = 1, blipScale = 1, alpha = 1, combatAlpha = 1,
			borderColor = { 1, 1, 1, 1 }, buttonBorderAlpha = 1,
			strata = "LOW", shape = "CORNER-BOTTOMLEFT",
			borderStyle = "Blizzard", borderRadius = 80,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local borderStyles = {}
function Appearance:AddBorderStyle(english, localized, round, square)
	if type(english) ~= "string" then
		error(("Bad argument #1 to `AddBorderStyle'. Expected string, got %q."):format(type(english)), 2)
	elseif borderStyles[english] then
		error(("Bad argument #1 to `AddBorderStyle'. Style %q already exists."):format(english), 2)
	elseif type(localized) ~= "string" then
		error(("Bad argument #2 to `AddBorderStyle'. Expected string, got %q."):format(type(localized)), 2)
	elseif type(round) ~= "string" then
		error(("Bad argument #3 to `AddBorderStyle'. Expected string, got %q."):format(type(round)), 2)
	elseif type(square) ~= "string" then
		error(("Bad argument #4 to `AddBorderStyle'. Expected string, got %q."):format(type(square)), 2)
	end

	borderStyles[english] = { localized, round, square }
end

Chinchilla.AddBorderStyle = Appearance.AddBorderStyle
Appearance:AddBorderStyle(NONE,             NONE,             "", "")
Appearance:AddBorderStyle(FACTION_ALLIANCE, FACTION_ALLIANCE, "Interface\\AddOns\\Chinchilla\\Art\\Border-Alliance-Round",   "Interface\\AddOns\\Chinchilla\\Art\\Border-Alliance-Square")
Appearance:AddBorderStyle("Blizzard",       L["Blizzard"],    "Interface\\AddOns\\Chinchilla\\Art\\Border-Blizzard-Round",   "Interface\\AddOns\\Chinchilla\\Art\\Border-Blizzard-Square")
Appearance:AddBorderStyle("Thin",           L["Thin"],        "Interface\\AddOns\\Chinchilla\\Art\\Border-Thin-Round",       "Interface\\AddOns\\Chinchilla\\Art\\Border-Thin-Square")
Appearance:AddBorderStyle("Tooltip",        L["Tooltip"],     "Interface\\AddOns\\Chinchilla\\Art\\Border-Tooltip-Round",    "Interface\\AddOns\\Chinchilla\\Art\\Border-Tooltip-Square")
Appearance:AddBorderStyle("Tubular",        L["Tubular"],     "Interface\\AddOns\\Chinchilla\\Art\\Border-Tubular-Round",    "Interface\\AddOns\\Chinchilla\\Art\\Border-Tubular-Square")
Appearance:AddBorderStyle("Flat",			L["Flat"],        "Interface\\AddOns\\Chinchilla\\Art\\Border-Flat-Round",       "Interface\\AddOns\\Chinchilla\\Art\\Border-Flat-Square")
Appearance:AddBorderStyle("Chinchilla",	      "Chinchilla",	  "Interface\\AddOns\\Chinchilla\\Art\\Border-Chinchilla-Round", "Interface\\AddOns\\Chinchilla\\Art\\Border-Chinchilla-Square")

local cornerTextures = {}
local inCombat = InCombatLockdown() and true or false
local indoors

function Appearance:OnEnable()
	rotateMinimap = GetCVar("rotateMinimap")

	self:SetScale()
	self:SetFrameStrata()
	self:SetShape()
	self:SetBorderColor()
	self:SetButtonBorderAlpha()

	if inCombat then self:SetCombatAlpha()
	else self:SetAlpha() end

	MinimapBorder:Hide()

	for _, v in ipairs(cornerTextures) do
		v:Show()
	end

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED")

	-- Removes the circular "waffle-like" texture that shows when using a non-circular minimap in the blue quest objective area.
	-- Thank you Funkeh` for the code!
	if Chinchilla:IsRetail() then
		Minimap:SetArchBlobRingScalar(0)
		Minimap:SetArchBlobRingAlpha(0)
		Minimap:SetQuestBlobRingScalar(0)
		Minimap:SetQuestBlobRingAlpha(0)
	end
end

function Appearance:OnDisable()
	self:SetScale()
	self:SetFrameStrata()
	self:SetShape()
	self:SetBorderColor()
	self:SetButtonBorderAlpha()

	MinimapBorder:Show()
	Minimap:SetAlpha(1)

	if Chinchilla:IsClassic() or Chinchilla:IsWrathClassic() then
		Minimap:SetMaskTexture("Textures\\MinimapMask")
	else
		Minimap:SetMaskTexture(186178)
	end

	for _, v in ipairs(cornerTextures) do
		v:Hide()
	end

	if Chinchilla:GetModule("MoveButtons", true) then
		Chinchilla:GetModule("MoveButtons"):Update()
	end

	if Chinchilla:IsRetail() then
		Minimap:SetArchBlobRingScalar(1)
		Minimap:SetArchBlobRingAlpha(1)
		Minimap:SetQuestBlobRingScalar(1)
		Minimap:SetQuestBlobRingAlpha(1)
	end
end


local iconLib
function Appearance:ADDON_LOADED()
	self:RecheckMinimapButtons()

	iconLib = iconLib or LibStub("LibDBIcon-1.0", true)

	if iconLib and iconLib.RegisterCallback then
		iconLib.RegisterCallback(self, "LibDBIcon_IconCreated", "RecheckMinimapButtons")
	end
end

function Appearance:CVAR_UPDATE(_, key, value)
	if key == "ROTATE_MINIMAP" then rotateMinimap = value end
end


function Appearance:ZONE_CHANGED_INDOORS()
	indoors = true

	if inCombat then self:SetCombatAlpha()
	else self:SetAlpha() end
end

function Appearance:ZONE_CHANGED()
	indoors = false

	if inCombat then self:SetCombatAlpha()
	else self:SetAlpha() end
end


function Appearance:PLAYER_REGEN_ENABLED()
	inCombat = false
	self:SetScale()
	self:SetAlpha()
end

function Appearance:PLAYER_REGEN_DISABLED()
	inCombat = true
	self:SetCombatAlpha()
end


local minimapButtons = {}
do
	local tmp = {}

	local function fillTmp(...)
		for i = 1, select('#', ...) do
			tmp[i] = select(i, ...)
		end
	end

	function Appearance:RecheckMinimapButtons()
		fillTmp(Minimap:GetChildren())

		local found = false

		for _, v in ipairs(tmp) do
			local childName = v:GetName() or ""

			if childName:find("^LibDBIcon10_") then
				found = true
				minimapButtons[childName] = true
			end
		end

		wipe(tmp)

		if found then
			self:SetScale()
			self:SetButtonBorderAlpha()
		end
	end
end


function Appearance:SetScale(value)
	if inCombat then return end

	if value then self.db.profile.scale = value
	else value = self.db.profile.scale end

--	local blipScale = self.db.profile.blipScale

	if not self:IsEnabled() then
		value = 1
--		blipScale = 1
	end

--[[
	Minimap:SetWidth(DEFAULT_MINIMAP_WIDTH / blipScale)
	Minimap:SetHeight(DEFAULT_MINIMAP_HEIGHT / blipScale)
	Minimap:SetScale(blipScale)

	for _, v in ipairs { Minimap:GetChildren() } do
		if v:GetName() ~= "Chinchilla_Coordinates_Frame" then
			v:SetScale(1 / blipScale)
		end
	end

	for _, v in ipairs(MINIMAP_POINTS) do
		Minimap:SetPoint(v[1], v[2], v[3], v[4]/blipScale, v[5]/blipScale)
	end
]]--

	Minimap:SetScale(value)

	if Chinchilla:IsClassic() then
		QuestWatchFrame:GetSize()
	elseif Chinchilla:IsWrathClassic() then
		WatchFrame:GetSize()
		MiniMapInstanceDifficulty:SetScale(value)
	else
		ObjectiveTrackerFrame:GetSize()
	-- Fix Instance Difficulty size --
		MiniMapInstanceDifficulty:SetScale(value)
		GuildInstanceDifficulty:SetScale(value)
		MiniMapChallengeMode:SetScale(value)
	end
end

--[[
function Appearance:SetBlipScale(value)
	if value then
		self.db.profile.blipScale = value
		self:SetScale(nil)
	end
end
]]--

function Appearance:SetAlpha(value)
	if value then self.db.profile.alpha = value
	else value = self.db.profile.alpha end

	if not self:IsEnabled() then value = 1 end
	if indoors then
		if value > 0 then value = 1 end
	end

	if inCombat then self:SetCombatAlpha()
	else
		Minimap:SetAlpha(value)

		-- to work around a Blizzard bug where the minimap loses its image when indoors with an alpha setting below 1
		Minimap:SetZoom(Minimap:GetZoom() + 1)
		Minimap:SetZoom(Minimap:GetZoom() - 1)
	end
end

function Appearance:SetCombatAlpha(value)
	if value then self.db.profile.combatAlpha = value
	else value = self.db.profile.combatAlpha end

	if not inCombat then return end
	if not self:IsEnabled() then value = 1 end
	if indoors then
		if value > 0 then value = 1 end
	end

	Minimap:SetAlpha(value)

	-- to work around a Blizzard bug where the minimap loses its image when indoors with an alpha setting below 1
	Minimap:SetZoom(Minimap:GetZoom() + 1)
	Minimap:SetZoom(Minimap:GetZoom() - 1)
end

function Appearance:SetFrameStrata(value)
	if value then self.db.profile.strata = value
	else value = self.db.profile.strata end

	Minimap:SetFrameStrata(value)
	MinimapBackdrop:SetFrameStrata(value)
--	MinimapCluster:SetFrameStrata(value)
end


local roundShapes = {
	{
		["ROUND"] = true,
		["CORNER-TOPLEFT"] = true,
		["SIDE-LEFT"] = true,
		["SIDE-TOP"] = true,
		["TRICORNER-TOPRIGHT"] = true,
		["TRICORNER-TOPLEFT"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-TOPRIGHT"] = true,
		["SIDE-RIGHT"] = true,
		["SIDE-TOP"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
		["TRICORNER-TOPRIGHT"] = true,
		["TRICORNER-TOPLEFT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-BOTTOMLEFT"] = true,
		["SIDE-LEFT"] = true,
		["SIDE-BOTTOM"] = true,
		["TRICORNER-TOPLEFT"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
	},
	{
		["ROUND"] = true,
		["CORNER-BOTTOMRIGHT"] = true,
		["SIDE-RIGHT"] = true,
		["SIDE-BOTTOM"] = true,
		["TRICORNER-BOTTOMLEFT"] = true,
		["TRICORNER-BOTTOMRIGHT"] = true,
		["TRICORNER-TOPRIGHT"] = true,
	},
}

function Appearance:SetShape(shape)
	if shape then self.db.profile.shape = shape
	else shape = self.db.profile.shape end

	if not self:IsEnabled() then
		return
	end

		if not cornerTextures[1] then
			local borderRadius = self.db.profile.borderRadius

			for i = 1, 4 do
				local tex = MinimapBackdrop:CreateTexture("Chinchilla_Appearance_MinimapCorner" .. i, "ARTWORK")
				cornerTextures[i] = tex
				cornerTextures[i]:SetWidth(borderRadius)
				cornerTextures[i]:SetHeight(borderRadius)
			end

			cornerTextures[1]:SetPoint("BOTTOMRIGHT", Minimap, "CENTER")
			cornerTextures[1]:SetTexCoord(0, 0.5, 0, 0.5)

			cornerTextures[2]:SetPoint("BOTTOMLEFT", Minimap, "CENTER")
			cornerTextures[2]:SetTexCoord(0.5, 1, 0, 0.5)

			cornerTextures[3]:SetPoint("TOPRIGHT", Minimap, "CENTER")
			cornerTextures[3]:SetTexCoord(0, 0.5, 0.5, 1)

			cornerTextures[4]:SetPoint("TOPLEFT", Minimap, "CENTER")
			cornerTextures[4]:SetTexCoord(0.5, 1, 0.5, 1)
		end

	local borderStyle = borderStyles[self.db.profile.borderStyle] or borderStyles.Blizzard
	local round = borderStyle and borderStyle[2] or [[Interface\AddOns\Chinchilla\Art\Border-Blizzard-Round]]
	local square = borderStyle and borderStyle[3] or [[Interface\AddOns\Chinchilla\Art\Border-Blizzard-Square]]

		for i,v in ipairs(cornerTextures) do
			v:SetTexture(roundShapes[i][shape] and round or square)
		end

	self:SetBorderColor() -- prevent border reverting to white, not sure if there's a way around this
	Minimap:SetMaskTexture([[Interface\AddOns\Chinchilla\Art\Mask-]] .. shape)

	if Chinchilla:GetModule("MoveButtons", true) then
		Chinchilla:GetModule("MoveButtons"):Update()
	end
end

function Appearance:SetBorderStyle(style)
	if style then self.db.profile.borderStyle = style
	else return end

	self:SetShape()
end

function Appearance:SetBorderRadius(value)
	if value then self.db.profile.borderRadius = value
	else return end

	if cornerTextures[1] then
		for _, v in ipairs(cornerTextures) do
			v:SetWidth(value)
			v:SetHeight(value)
		end
	end
end

function Appearance:SetBorderColor(r, g, b, a)
	if r and g and b and a then
		self.db.profile.borderColor[1] = r
		self.db.profile.borderColor[2] = g
		self.db.profile.borderColor[3] = b
		self.db.profile.borderColor[4] = a
	else
		r = self.db.profile.borderColor[1]
		g = self.db.profile.borderColor[2]
		b = self.db.profile.borderColor[3]
		a = self.db.profile.borderColor[4]
	end

	if not self:IsEnabled() then
		return
	end

	for _, v in ipairs(cornerTextures) do
		v:SetVertexColor(r, g, b, a)
	end
end


local buttonBorderTextures = {
	"MiniMapMailBorder",
	"MiniMapTrackingButtonBorder",
	"MiniMapVoiceChatFrameBorder",
	"QueueStatusMinimapButtonBorder",
}

function Appearance:SetButtonBorderAlpha(alpha)
	if alpha then self.db.profile.buttonBorderAlpha = alpha
	else alpha = self.db.profile.buttonBorderAlpha end

	if not self:IsEnabled() then
		alpha = 1
	end

	-- FrameXML buttons
	for _, v in ipairs(buttonBorderTextures) do
		if _G[v] then _G[v]:SetAlpha(alpha) end
	end

	-- LibDBIcon-1.0 buttons
	for k, v in pairs(minimapButtons) do
		for _, region in ipairs({ _G[k]:GetRegions() }) do
			if region:GetTexture() == "Interface\\Minimap\\MiniMap-TrackingBorder" then
  				region:SetAlpha(alpha)
  			end
  		end
	end
end


function Appearance:GetOptions()
	local shape_choices = {
		["ROUND"] = L["Round"],
		["SQUARE"] = L["Square"],
		["CORNER-TOPRIGHT"] = L["Corner, top-right rounded"],
		["CORNER-TOPLEFT"] = L["Corner, top-left rounded"],
		["CORNER-BOTTOMRIGHT"] = L["Corner, bottom-right rounded"],
		["CORNER-BOTTOMLEFT"] = L["Corner, bottom-left rounded"],
		["SIDE-TOP"] = L["Side, top rounded"],
		["SIDE-RIGHT"] = L["Side, right rounded"],
		["SIDE-BOTTOM"] = L["Side, bottom rounded"],
		["SIDE-LEFT"] = L["Side, left rounded"],
		["TRICORNER-TOPRIGHT"] = L["Tri-corner, bottom-left square"],
		["TRICORNER-BOTTOMRIGHT"] = L["Tri-corner, top-left square"],
		["TRICORNER-BOTTOMLEFT"] = L["Tri-corner, top-right square"],
		["TRICORNER-TOPLEFT"] = L["Tri-corner, bottom-right square"],
	}

	local shape_choices_alt = { ["ROUND"] = L["Round"], ["SQUARE"] = L["Square"] }

	return {
		scale = {
			name = L["Size"],
			desc = L["Set how large the minimap is"],
			type = 'range',
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return self.db.profile.scale
			end,
			set = function(_, value)
				self:SetScale(value)
			end,
			isPercent = true,
			order = 1,
		},
--[[
		blipScale = {
			name = L["Blip size"],
			desc = L["Set how large the blips on the minimap are"],
			type = 'range',
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return self.db.profile.blipScale
			end,
			set = function(_, value)
				self:SetBlipScale(value)
			end,
			isPercent = true,
			order = 2,
		},
]]--
		strata = {
			name = L["Strata"],
			desc = L["Set which layer the minimap is layered on in relation to others in your interface."],
			type = 'select',
			values = {
				LOW = L["Low"],
				MEDIUM = L["Medium"],
				HIGH = L["High"],
			},
			get = function()
				return self.db.profile.strata
			end,
			set = function(_, value)
				self:SetFrameStrata(value)
			end,
			order = 3,
		},
		alpha = {
			name = L["Opacity"],
			desc = L["Set how transparent or opaque the minimap is when not in combat"],
			type = 'range',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return self.db.profile.alpha
			end,
			set = function(_, value)
				self:SetAlpha(value)
			end,
			isPercent = true,
			order = 4,
		},
		combatAlpha = {
			name = L["Combat opacity"],
			desc = L["Set how transparent or opaque the minimap is when in combat"],
			type = 'range',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return self.db.profile.combatAlpha
			end,
			set = function(_, value)
				self:SetCombatAlpha(value)
			end,
			isPercent = true,
			order = 5,
		},
		shape = {
			name = L["Shape"],
			desc = L["Set the shape of the minimap."],
			type = 'select',
			values = function()
				return rotateMinimap == "1" and shape_choices_alt or shape_choices
			end,
			get = function()
				local shape = self.db.profile.shape

				if rotateMinimap == "1" then
					if shape == "SQUARE" then return "SQUARE"
					else return "ROUND" end
				else
					return shape
				end
			end,
			set = function(_, value)
				self:SetShape(value)
			end,
			order = 6,
		},
		borderAlpha = {
			name = L["Border color"],
			desc = L["Set the color the minimap border is."],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.borderColor)
			end,
			set = function(_, ...)
				self:SetBorderColor(...)
			end,
			order = 7,
		},
		borderStyle = {
			name = L["Border style"],
			desc = L["Set what texture style you want the minimap border to use."],
			type = 'select',
			values = function()
				local t = {}
				for k, v in pairs(borderStyles) do t[k] = v[1] end
				return t
			end,
			get = function()
				return self.db.profile.borderStyle
			end,
			set = function(_, value)
				self:SetBorderStyle(value)
			end,
			order = 8,
		},
		borderRadius = {
			name = L["Border radius"],
			desc = L["Set how large the border texture is."],
			type = 'range',
			min = 50,
			max = 200,
			step = 1,
			bigStep = 5,
			get = function()
				return self.db.profile.borderRadius
			end,
			set = function(_, value)
				self:SetBorderRadius(value)
			end,
			order = 9,
		},
		buttonBorderAlpha = {
			name = L["Button border opacity"],
			desc = L["Set how transparent or opaque the minimap button borders are."],
			type = 'range',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return self.db.profile.buttonBorderAlpha
			end,
			set = function(_, value)
				self:SetButtonBorderAlpha(value)
			end,
			isPercent = true,
		},
	}
end


function _G.GetMinimapShape()
	if not Appearance.db then return "ROUND" end

	if Appearance:IsEnabled() and rotateMinimap == "0" then
		return Appearance.db.profile.shape
	else
		if Appearance.db.profile.shape == "SQUARE" then return "SQUARE"
		else return "ROUND" end
	end
end
