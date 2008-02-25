local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_TrackingDots = Chinchilla:NewModule("TrackingDots")
local self = Chinchilla_TrackingDots
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_TrackingDots.desc = L["Change how the tracking dots look on the minimap."]

local newDict, unpackDictAndDel = Rock:GetRecyclingFunctions("Chinchilla", "newDict", "unpackDictAndDel")

local trackingDotStyles = {}
function Chinchilla_TrackingDots:AddTrackingDotStyle(english, localized, texture)
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
Chinchilla.AddTrackingDotStyle = Chinchilla_TrackingDots.AddTrackingDotStyle

Chinchilla_TrackingDots:AddTrackingDotStyle("Blizzard", L["Blizzard"], [[Interface\MiniMap\ObjectIcons]])
Chinchilla_TrackingDots:AddTrackingDotStyle("Nandini", "Nandini", [[Interface\AddOns\Chinchilla\TrackingDots\Blip-Nandini]])
Chinchilla_TrackingDots:AddTrackingDotStyle("BlizzardBig", L["Big Blizzard"], [[Interface\AddOns\Chinchilla\TrackingDots\Blip-BlizzardBig]])
Chinchilla_TrackingDots:AddTrackingDotStyle("GlassSpheres", L["Glass Spheres"], [[Interface\AddOns\Chinchilla\TrackingDots\Blip-GlassSpheres]])
Chinchilla_TrackingDots:AddTrackingDotStyle("SolidSpheres", L["Solid Spheres"], [[Interface\AddOns\Chinchilla\TrackingDots\Blip-SolidSpheres]])

function Chinchilla_TrackingDots:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("TrackingDots")
	Chinchilla:SetDatabaseNamespaceDefaults("TrackingDots", "profile", {
		trackingDotStyle = "Blizzard"
	})
end

function Chinchilla_TrackingDots:OnEnable()
	self:SetBlipTexture(nil)
end

function Chinchilla_TrackingDots:OnDisable()
	self:SetBlipTexture(nil)
end

local function getBlipTexture(name)
	local style = trackingDotStyles[name] or trackingDotStyles["Blizzard"]
	local texture = style and style[2] or [[Interface\MiniMap\ObjectIcons]]
	return texture
end

function Chinchilla_TrackingDots:SetBlipTexture(name)
	if not name then
		name = self.db.profile.trackingDotStyle
	else
		self.db.profile.trackingDotStyle = name
	end
	local texture = getBlipTexture(name)
	if not self:IsActive() then
		texture = [[Interface\MiniMap\ObjectIcons]]
	end
	Minimap:SetBlipTexture(texture)
end

Chinchilla_TrackingDots:AddChinchillaOption({
	name = L["Tracking dots"],
	desc = Chinchilla_TrackingDots.desc,
	type = 'group',
	args = {
		style = {
			name = L["Style"],
			desc = L["Set the style of how the tracking dots should look."],
			type = 'choice',
			choices = function()
				local t = newDict()
				for k, v in pairs(trackingDotStyles) do
					t[k] = v[1]
				end
				return "@dict", unpackDictAndDel(t)
			end,
			get = function()
				return self.db.profile.trackingDotStyle
			end,
			set = "SetBlipTexture",
			order = 2,
		},
		preview = {
			name = L["Preview"],
			desc = L["See how the tracking dots will look"],
			type = 'choice',
			choices = {
				PARTY = L["Party member or pet"],
				RAID = L["Raid member"],
				FRIEND = L["Friendly player"],
				NEUTRAL = L["Neutral player"],
				ENEMY = L["Enemy player"],
				
				FRIENDNPC = L["Friendly npc"],
				NEUTRALNPC = L["Neutral npc"],
				ENEMYNPC = L["Enemy npc"],
				TRACK = L["Tracked resource"],
			
				AVAIL = L["Available quest"],
				COMPLETE = L["Completed quest"],
				AVAILDAILY = L["Available daily quest"],
				COMPLETEDAILY = L["Completed daily quest"],
				FLIGHT = L["New flight path"],
			},
			choiceOrder = {
				"PARTY", "RAID", "FRIEND", "NEUTRAL", "ENEMY",
				"FRIENDNPC", "NEUTRALNPC", "ENEMYNPC", "TRACK",
				"AVAIL", "COMPLETE", "AVAILDAILY", "COMPLETEDAILY", "FLIGHT"
			},
			choiceIcons = function()
				local t = newDict()
				local tex = getBlipTexture(self.db.profile.trackingDotStyle)
				t.PARTY = tex
				t.RAID = tex
				t.FRIEND = tex
				t.NEUTRAL = tex
				t.ENEMY = tex
				
				t.FRIENDNPC = tex
				t.NEUTRALNPC = tex
				t.ENEMYNPC = tex
				t.TRACK = tex
				
				t.AVAIL = tex
				t.COMPLETE = tex
				t.AVAILDAILY = tex
				t.COMPLETEDAILY = tex
				t.FLIGHT = tex
				return "@dict", unpackDictAndDel(t)
			end,
			choiceIconTexCoords = {
				RAID = { 0, 0.125, 0, 0.5 },
				PARTY = { 0.125, 0.25, 0, 0.5 },
				FRIEND = { 0.5, 0.625, 0, 0.5 },
				NEUTRAL = { 0.375, 0.5, 0, 0.5 },
				ENEMY = { 0.25, 0.375, 0, 0.5 },
				
				FRIENDNPC = { 0.875, 1, 0, 0.5 },
				NEUTRALNPC = { 0.75, 0.875, 0, 0.5 },
				ENEMYNPC = { 0.625, 0.75, 0, 0.5 },
				TRACK = { 0, 0.125, 0.5, 1 },
			
				AVAIL = { 0.125, 0.25, 0.5, 1 },
				COMPLETE = { 0.25, 0.375, 0.5, 1 },
				AVAILDAILY = { 0.375, 0.5, 0.5, 1 },
				COMPLETEDAILY = { 0.5, 0.625, 0.5, 1 },
				FLIGHT = { 0.625, 0.75, 0.5, 1 },
			},
			get = function() end,
			set = function() end,
			order = 3,
		},
	}
})
