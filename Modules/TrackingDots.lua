
local TrackingDots = Chinchilla:NewModule("TrackingDots", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

TrackingDots.displayName = L["Tracking dots"]
TrackingDots.desc = L["Change how the tracking dots look on the minimap."]

local blipFile = ""
local trackingDotStyles = {}

function TrackingDots:AddTrackingDotStyle(english, localized, texture)
	if type(english) ~= "string" then
		error(("Bad argument #2 to `AddTrackingDotStyle'. Expected %q, got %q"):format("string", type(english)), 2)
	elseif trackingDotStyles[english] then
		error(("Bad argument #2 to `AddTrackingDotStyle'. %q already provided"):format(english), 2)
	elseif type(localized) ~= "string" then
		error(("Bad argument #3 to `AddTrackingDotStyle'. Expected %q, got %q"):format("string", type(localized)), 2)
	elseif type(texture) ~= "string" then
		error(("Bad argument #4 to `AddTrackingDotStyle'. Expected %q, got %q"):format("string", type(texture)), 2)
	end

	trackingDotStyles[english] = { localized, texture }
end

Chinchilla.AddTrackingDotStyle = TrackingDots.AddTrackingDotStyle

TrackingDots:AddTrackingDotStyle("Blizzard",     L["Blizzard"],			[[Interface\MiniMap\ObjectIcons]])
TrackingDots:AddTrackingDotStyle("Nandini",        "Nandini",			[[Interface\AddOns\Chinchilla\Art\Blip-Nandini]])
TrackingDots:AddTrackingDotStyle("NandiniNew",     "Nandini New",		[[Interface\AddOns\Chinchilla\Art\Blip-Nandini-New]])
TrackingDots:AddTrackingDotStyle("BlizzardBig",  L["Big Blizzard"],		[[Interface\AddOns\Chinchilla\Art\Blip-BlizzardBig]])
TrackingDots:AddTrackingDotStyle("BlizzardBigR", L["Blizzard, Big Resources"],	[[Interface\AddOns\Chinchilla\Art\Blip-BlizzardBigR]])
TrackingDots:AddTrackingDotStyle("GlassSpheres", L["Glass Spheres"],		[[Interface\AddOns\Chinchilla\Art\Blip-GlassSpheres]])
TrackingDots:AddTrackingDotStyle("SolidSpheres", L["Solid Spheres"],		[[Interface\AddOns\Chinchilla\Art\Blip-SolidSpheres]])
TrackingDots:AddTrackingDotStyle("Charmed",      L["Charmed"],			[[Interface\AddOns\Chinchilla\Art\Blip-Charmed]])


function TrackingDots:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("TrackingDots", {
		profile = {
			trackingDotStyle = "Blizzard", blink = false, blinkRate = 0.5,
			enabled = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

function TrackingDots:OnEnable()
	self:SetBlipTexture()
	self:SetBlinking()
end

function TrackingDots:OnDisable()
	self:SetBlipTexture()
	self:SetBlinking()
end


local function getBlipTexture(name)
	local style = trackingDotStyles[name] or trackingDotStyles["Blizzard"]
	local texture = style and style[2] or [[Interface\MiniMap\ObjectIcons]]

	return texture
end


function TrackingDots:SetBlipTexture(name)
	if not name then
		name = self.db.profile.trackingDotStyle
	else
		self.db.profile.trackingDotStyle = name
	end

	blipFile = getBlipTexture(name)

	if not self:IsEnabled() then
		blipFile = [[Interface\MiniMap\ObjectIcons]]
	end

	Minimap:SetBlipTexture(blipFile)

	LibStub("AceConfigRegistry-3.0"):NotifyChange("Chinchilla")
end


local show = true
function TrackingDots:Blink()
	if show then
		Minimap:SetBlipTexture(blipFile)
	else
		Minimap:SetBlipTexture([[Interface\AddOns\Chinchilla\Art\Blip-Blank]])
	end

	show = not show
end

function TrackingDots:SetBlinking(_, value)
	if value ~= nil then self.db.profile.blink = value
	else value = self.db.profile.blink end

	if not self:IsEnabled() then
		value = false
	end

	if value then
		self:ScheduleRepeatingTimer("Blink", self.db.profile.blinkRate)
	else
		Minimap:SetBlipTexture(blipFile)
		self:CancelAllTimers()
	end
end


function TrackingDots:GetOptions()
	local function image()
		return getBlipTexture(self.db.profile.trackingDotStyle), 24, 24
	end

	return {
		style = {
			name = L["Style"],
			desc = L["Set the style of how the tracking dots should look."],
			type = 'select',
			values = function()
				local t = {}
				for k, v in pairs(trackingDotStyles) do
					t[k] = v[1]
				end
				return t
			end,
			get = function()
				return self.db.profile.trackingDotStyle
			end,
			set = function(_, value)
				self:SetBlipTexture(value)
			end,
			order = 1,
		},
		blink = {
			name = L["Blinking Blips"],
			desc = L["Make the minimap blips flash to make them more noticable."],
			type = 'toggle',
			get = function()
				return self.db.profile.blink
			end,
			set = "SetBlinking",
			order = 2,
		},
		blinkRate = {
			name = L["Blink Rate"],
			desc = L["Set how fast the blips flash."],
			type = 'range',
			min = 0.1, max = 2, step = 0.1,
			order = 3,
			get = function() return self.db.profile.blinkRate end,
			set = function(_, value)
				self.db.profile.blinkRate = value

				self:CancelAllTimers()
				self:SetBlinking()
			end,
			disabled = function() return not self.db.profile.blink end,
		},

		preview1 = {
			name = L["Party member or pet"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0, 0.125, 0, 0.125 },
			order = 4,
		},
		preview2 = {
			name = L["Friendly player"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.5, 0.625, 0, 0.125 },
			order = 5,
		},
		preview3 = {
			name = L["Neutral player"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.375, 0.5, 0, 0.125 },
			order = 6,
		},
		preview4 = {
			name = L["Enemy player"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.25, 0.375, 0, 0.125 },
			order = 7,
		},
		preview5 = {
			name = L["Friendly npc"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.875, 1, 0, 0.125 },
			order = 8,
		},
		preview6 = {
			name = L["Neutral npc"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.75, 0.875, 0, 0.125 },
			order = 9,
		},
		preview7 = {
			name = L["Enemy npc"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.625, 0.75, 0, 0.125 },
			order = 10,
		},
		preview8 = {
			name = L["Tracked resource"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0, 0.125, 0.125, 0.25 },
			order = 11,
		},
		preview9 = {
			name = L["Available quest"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.125, 0.25, 0.125, 0.25 },
			order = 12,
		},
		preview10 = {
			name = L["Completed quest"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.25, 0.375, 0.125, 0.25 },
			order = 13,
		},
		preview11 = {
			name = L["Available daily quest"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.375, 0.5, 0.125, 0.25 },
			order = 14,
		},
		preview12 = {
			name = L["Completed daily quest"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.5, 0.625, 0.125, 0.25 },
			order = 15,
		},
		preview13 = {
			name = L["New flight path"],
			type = 'description',
			fontSize = "medium",
			image = image,
			imageCoords = { 0.625, 0.75, 0.125, 0.25 },
			order = 16,
		},
	}
end
