
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
TrackingDots:AddTrackingDotStyle("BlizzardBigR",   "Blizzard, Big Resources",	[[Interface\AddOns\Chinchilla\Art\Blip-BlizzardBigR]])
TrackingDots:AddTrackingDotStyle("GlassSpheres", L["Glass Spheres"],		[[Interface\AddOns\Chinchilla\Art\Blip-GlassSpheres]])
TrackingDots:AddTrackingDotStyle("SolidSpheres", L["Solid Spheres"],		[[Interface\AddOns\Chinchilla\Art\Blip-SolidSpheres]])


function TrackingDots:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("TrackingDots", {
		profile = {
			trackingDotStyle = "Blizzard", blink = true,
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
	self.db.profile.blink = value

	if not self:IsEnabled() then
		value = false
	end

	if value then
		self:ScheduleRepeatingTimer("Blink", 0.5)
	else
		Minimap:SetBlipTexture(blipFile)
		self:CancelAllTimers()
	end
end


function TrackingDots:GetOptions()
	local AceGUI = LibStub("AceGUI-3.0")

	local previewValues = {
		L["Party member or pet"],
		L["Friendly player"],
		L["Neutral player"],
		L["Enemy player"],

		L["Friendly npc"],
		L["Neutral npc"],
		L["Enemy npc"],

		L["Tracked resource"],

		L["Available quest"],
		L["Completed quest"],
		L["Available daily quest"],
		L["Completed daily quest"],

		L["New flight path"],
	}

	do
		local texCoords = {
			{ 0, 0.125, 0, 0.125 },    -- party
			{ 0.5, 0.625, 0, 0.125 },  -- friend
			{ 0.375, 0.5, 0, 0.125 },  -- neutral
			{ 0.25, 0.375, 0, 0.125 }, -- enemy

			{ 0.875, 1, 0, 0.125 },    -- friendly npc
			{ 0.75, 0.875, 0, 0.125 }, -- neutral npc
			{ 0.625, 0.75, 0, 0.125 }, -- enemy npc

			{ 0, 0.125, 0.125, 0.25 },    -- tracked object

			{ 0.125, 0.25, 0.125, 0.25 }, -- quest available
			{ 0.25, 0.375, 0.125, 0.25 }, -- quest complete
			{ 0.375, 0.5, 0.125, 0.25 },  -- daily quest available
			{ 0.5, 0.625, 0.125, 0.25 },  -- daily quest complete

			{ 0.625, 0.75, 0.125, 0.25 }, -- undiscovered flight point
		}

		local min, max, floor = math.min, math.max, math.floor

		do
			local widgetType = "Chinchilla_TrackingDots_Item_Select"
			local widgetVersion = 1

			local function SetText(self, text, ...)
				if text and text ~= "" then
					self.texture:SetTexture(getBlipTexture(TrackingDots.db.profile.trackingDotStyle))
					self.texture:SetTexCoord(unpack(texCoords[text]))
				end

				self.text:SetText(previewValues[text] or "")
			end

			local function Constructor()
				local self = AceGUI:Create("Dropdown-Item-Toggle")
				self.useHighlight = false
				self.type = widgetType
				self.SetText = SetText

				local texture = self.frame:CreateTexture(nil, "BACKGROUND")
				texture:SetTexture(0, 0, 0, 0)
				texture:SetPoint("BOTTOMRIGHT", self.frame, "TOPLEFT", 22, -17)
				texture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, -1)
				self.texture = texture

				return self
			end

			AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
		end

		do
			local widgetType = "Chinchilla_TrackingDots_Select"
			local widgetVersion = 1

			local function SetText(self, text)
				self.text:SetText(text or "")
			end

			local function AddListItem(self, value, text)
				local item = AceGUI:Create("Chinchilla_TrackingDots_Item_Select")
				item.disabled = true
				item:SetText(text)
				item.userdata.obj = self
				item.userdata.value = value
				self.pullout:AddItem(item)
			end

			local sortlist = {}
			local function SetList(self, list)
				self.list = list
				self.pullout:Clear()

				for v in pairs(self.list) do
					sortlist[#sortlist + 1] = v
				end

				table.sort(sortlist)

				for i, value in pairs(sortlist) do
					AddListItem(self, value, value)
					sortlist[i] = nil
				end
			end

			local function Constructor()
				local self = AceGUI:Create("Dropdown")
				self.type = widgetType
				self.SetText = SetText
				self.SetList = SetList

				local left = _G[self.dropdown:GetName() .. "Left"]
				local middle = _G[self.dropdown:GetName() .. "Middle"]
				local right = _G[self.dropdown:GetName() .. "Right"]

				local texture = self.dropdown:CreateTexture(nil, "ARTWORK")
				texture:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -39, 26)
				texture:SetPoint("TOPLEFT", left, "TOPLEFT", 24, -24)
				self.texture = texture

				return self
			end

			AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
		end
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
			get = function(info)
				return self.db.profile.trackingDotStyle
			end,
			set = function(info, value)
				self:SetBlipTexture(value)
			end,
			order = 2,
		},
		preview = {
			name = L["Preview"],
			desc = L["See how the tracking dots will look"],
			type = 'select',
			values = previewValues,
			order = 3,
			dialogControl = "Chinchilla_TrackingDots_Select",
		},
		blink = {
			name = L["Blinking Blips"],
			desc = L["Make the minimap blips flash to make them more noticable."],
			type = 'toggle',
			get = function(info)
				return self.db.profile.blink
			end,
			set = "SetBlinking",
		},
	}
end
