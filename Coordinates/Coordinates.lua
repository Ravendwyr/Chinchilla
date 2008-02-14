local VERSION = tonumber(("$Revision$"):match("%d+"))

local Chinchilla = Chinchilla
local Chinchilla_Coordinates = Chinchilla:NewModule("Coordinates")
local self = Chinchilla_Coordinates
if Chinchilla.revision < VERSION then
	Chinchilla.version = "1.0r" .. VERSION
	Chinchilla.revision = VERSION
	Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")
end
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Coordinates.desc = L["Use the mouse wheel to zoom in and out on the minimap."]

local coordString
local function recalculateCoordString()
	local sep
	if ("%.1f"):format(1.1) == "1,1" then
		sep = " x "
	else
		sep = ", "
	end
	local prec = self.db.profile.precision
	coordString = ("%%.%df%s%%.%df"):format(prec, sep, prec)
end

function Chinchilla_Coordinates:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Coordinates")
	Chinchilla:SetDatabaseNamespaceDefaults("Coordinates", "profile", {
		precision = 1,
		scale = 1,
		point = "BOTTOMLEFT",
		relpoint = "BOTTOMLEFT",
		background = {
			TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
			TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
			TOOLTIP_DEFAULT_BACKGROUND_COLOR.b,
			1
		},
		border = {
			TOOLTIP_DEFAULT_COLOR.r,
			TOOLTIP_DEFAULT_COLOR.g,
			TOOLTIP_DEFAULT_COLOR.b,
			1
		},
		textColor = {
			0.8,
			0.8,
			0.6,
			1
		}
	})
end

local frame
function Chinchilla_Coordinates:OnEnable()
	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Coordinates_Frame", Minimap)
		frame:SetBackdrop({
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = {
				left = 4,
				right = 4,
				top = 4,
				bottom = 4
			}
		})
		frame:SetWidth(1)
		frame:SetHeight(1)
		local text = frame:CreateFontString(frame:GetName() .. "_FontString", "ARTWORK", "GameFontNormalSmall")
		frame.text = text
		text:SetPoint("CENTER")
		local countdown = 0
		function frame:Update()
			local x, y = GetPlayerMapPosition("player")
			text:SetText(coordString:format(x*100, y*100))
		end
		frame:SetScript("OnUpdate", function(this, elapsed)
			countdown = countdown - elapsed
			if countdown > 0 then
				return
			end
			countdown = 0.1
			this:Update()
		end)
	end
	frame:Show()
	self:Update()
end

function Chinchilla_Coordinates:OnDisable()
	frame:Hide()
end

function Chinchilla_Coordinates:Update()
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	recalculateCoordString()
	frame:SetScale(self.db.profile.scale)
	frame.text:SetText(coordString:format(12.345, 23.456))
	frame:SetFrameLevel(MinimapCluster:GetFrameLevel()+5)
	frame:SetWidth(frame.text:GetWidth() + 12)
	frame:SetHeight(frame.text:GetHeight() + 12)
	frame.text:SetTextColor(unpack(self.db.profile.textColor))
	frame:SetBackdropColor(unpack(self.db.profile.background))
	frame:SetBackdropBorderColor(unpack(self.db.profile.border))
	frame:ClearAllPoints()
	frame:SetPoint(self.db.profile.point, Minimap, self.db.profile.relpoint)
	frame:Update()
end

Chinchilla_Coordinates:AddChinchillaOption({
	name = L["Coordinates"],
	desc = Chinchilla_Coordinates.desc,
	type = 'group',
	args = {
		precision = {
			name = L["Precision"],
			desc = L["Set the amount of numbers past the decimal place to show."],
			type = 'range',
			min = 0,
			max = 3,
			step = 1,
			get = function()
				return self.db.profile.precision
			end,
			set = function(value)
				self.db.profile.precision = value
				self:Update()
			end,
		},
		scale = {
			name = L["Size"],
			desc = L["Set the size of the coordinate display."],
			type = 'range',
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
			get = function()
				return self.db.profile.scale
			end,
			set = function(value)
				self.db.profile.scale = value
				self:Update()
			end,
		},
		background = {
			name = L["Background"],
			desc = L["Set the background color"],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.background)
			end,
			set = function(r, g, b, a)
				local t = self.db.profile.background
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end
		},
		border = {
			name = L["Border"],
			desc = L["Set the border color"],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.border)
			end,
			set = function(r, g, b, a)
				local t = self.db.profile.border
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end
		},
		textColor = {
			name = L["Text"],
			desc = L["Set the text color"],
			type = 'color',
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.textColor)
			end,
			set = function(r, g, b, a)
				local t = self.db.profile.textColor
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end
		},
		position = {
			name = L["Position"],
			desc = L["Set the position of the coordinate indicator"],
			type = 'choice',
			choices = {
				["BOTTOM;BOTTOM"] = L["Bottom, inside"],
				["TOP;BOTTOM"] = L["Bottom, outside"],
				["TOP;TOP"] = L["Top, inside"],
				["BOTTOM;TOP"] = L["Top, outside"],
				["TOPLEFT;TOPLEFT"] = L["Top-left"],
				["BOTTOMLEFT;BOTTOMLEFT"] = L["Bottom-left"],
				["TOPRIGHT;TOPRIGHT"] = L["Top-right"],
				["BOTTOMRIGHT;BOTTOMRIGHT"] = L["Bottom-right"]
			},
			get = function()
				return self.db.profile.point .. ";" .. self.db.profile.relpoint
			end,
			set = function(value)
				self.db.profile.point, self.db.profile.relpoint = value:match("(.*);(.*)")
				self:Update()
			end
		}
	}
})
