
local Coordinates = Chinchilla:NewModule("Coordinates", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

local LSM = LibStub("LibSharedMedia-3.0")

Coordinates.displayName = L["Coordinates"]
Coordinates.desc = L["Show coordinates on or near the minimap"]


local coordString
local function recalculateCoordString()
	local sep

	if ("%.1f"):format(1.1) == "1,1" then sep = " x "
	else sep = ", " end

	local prec = Coordinates.db.profile.precision

	coordString = ("%%.%df%s%%.%df"):format(prec, sep, prec)
end

function Coordinates:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Coordinates", {
		profile = {
			precision = 1,
			scale = 1,
			positionX = -30,
			positionY = -50,
			background = { TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b, 1 },
			backgroundTexture = "Blizzard Tooltip",
			border = { TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b, 1 },
			borderTexture = "Blizzard Tooltip",
			textColor = { 0.8, 0.8, 0.6, 1 },
			font = LSM.DefaultMedia.font,
			enabled = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local frame, timerID, backdrop
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local GetBestMapForUnit = C_Map.GetBestMapForUnit

function Coordinates:OnEnable()
	backdrop = {
		bgFile = LSM:Fetch("background", self.db.profile.backgroundTexture, true),
		edgeFile = LSM:Fetch("border", self.db.profile.borderTexture, true),
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
		edgeSize = 16,
	}

	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Coordinates_Frame", MinimapBackdrop, BackdropTemplateMixin and "BackdropTemplate")
		frame:SetBackdrop(backdrop)

		frame:SetWidth(1)
		frame:SetHeight(1)

		local text = frame:CreateFontString(frame:GetName() .. "_FontString", "ARTWORK", "GameFontNormalSmall")
		frame.text = text
		text:SetPoint("CENTER")

		function frame:Update()
			local uiMapID = GetBestMapForUnit("player")
			if not uiMapID then self:Hide() return end

			local coords = GetPlayerMapPosition(uiMapID, "player")
			if not coords then self:Hide() return end

			if not self:IsShown() then
				self:Show()
				Coordinates:Update()
				return
			end

			text:SetText(coordString:format(coords.x*100, coords.y*100))
		end

		frame:SetScript("OnDragStart", function(this) this:StartMoving() end)
		frame:SetScript("OnDragStop", function(this)
			this:StopMovingOrSizing()

			local cx, cy = this:GetCenter()
			local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()

			cx, cy = cx*scale, cy*scale

			local mx, my = Minimap:GetCenter()
			local mscale = Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale()

			mx, my = mx*mscale, my*mscale

			local x, y = cx - mx, cy - my

			self.db.profile.positionX = x/scale
			self.db.profile.positionY = y/scale
			self:Update()

			LibStub("AceConfigRegistry-3.0"):NotifyChange("Chinchilla")
		end)
	end

	frame:Show()

	-- need these otherwise the frame won't scale on login
	recalculateCoordString()
	self:ScheduleTimer("Update", 0)

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "MediaRegistered")

	timerID = self:ScheduleRepeatingTimer(frame.Update, 0.1, frame)
end

function Coordinates:OnDisable()
	self:CancelTimer(timerID)
	frame:Hide()
end


function Coordinates:MediaRegistered(_, mediaType, mediaName)
	if mediaType == "font" and mediaName == self.db.profile.font
	or mediaType == "border" and mediaName == self.db.profile.borderTexture
	or mediaType == "background" and mediaName == self.db.profile.backgroundTexture
	then self:Update() end
end

function Coordinates:Update()
	if not self:IsEnabled() then return end

	recalculateCoordString()

	frame:SetScale(self.db.profile.scale)

	frame.text:SetFont(LSM:Fetch("font", self.db.profile.font), 11)
	frame.text:SetText(coordString:format(12.345, 23.456))
	frame.text:SetTextColor(unpack(self.db.profile.textColor))

	frame:SetFrameLevel(MinimapCluster:GetFrameLevel() + 7)
	frame:SetWidth(frame.text:GetWidth() + 16)
	frame:SetHeight(frame.text:GetHeight() + 14)

	backdrop.edgeFile = LSM:Fetch("border", self.db.profile.borderTexture)
	backdrop.bgFile = LSM:Fetch("background", self.db.profile.backgroundTexture)

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(unpack(self.db.profile.background))
	frame:SetBackdropBorderColor(unpack(self.db.profile.border))

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", self.db.profile.positionX, self.db.profile.positionY)

	frame:Update()
end

function Coordinates:SetMovable(value)
	frame:SetMovable(value)
	frame:EnableMouse(value)

	if value then frame:RegisterForDrag("LeftButton")
	else frame:RegisterForDrag() end
end


function Coordinates:GetOptions()
	return {
		position = {
			name = L["Position"],
			desc = L["Set the position of the coordinate indicator"],
			type = 'group', order = 1,
			inline = true,
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Allow the coordinate indicator to be moved"],
					type = 'toggle',
					get = function()
						return frame and frame:IsMovable()
					end,
					set = function(_, value)
						self:SetMovable(value)
					end,
					order = 1,
					disabled = function()
						return not frame
					end,
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the coordinate indicator relative to the minimap."],
					type = 'range',
					min = -math.floor(GetScreenWidth()/5 + 0.5)*5,
					max = math.floor(GetScreenWidth()/5 + 0.5)*5,
					step = 1,
					bigStep = 5,
					get = function()
						return self.db.profile.positionX
					end,
					set = function(_, value)
						self.db.profile.positionX = value
						self:Update()
					end,
					order = 2,
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the coordinate indicator relative to the minimap."],
					type = 'range',
					min = -math.floor(GetScreenHeight()/5 + 0.5)*5,
					max = math.floor(GetScreenHeight()/5 + 0.5)*5,
					step = 1,
					bigStep = 5,
					get = function()
						return self.db.profile.positionY
					end,
					set = function(_, value)
						self.db.profile.positionY = value
						self:Update()
					end,
					order = 3,
				},
			},
		},
		backgroundTexture = {
			name = L["Background"],
			type = "select", dialogControl = 'LSM30_Background',
			order = 2, width = "double",
			values = AceGUIWidgetLSMlists.background,
			get = function() return self.db.profile.backgroundTexture end,
			set = function(_, value)
				self.db.profile.backgroundTexture = value
				self:Update()
			end,
		},
		background = {
			name = L["Background"],
			desc = L["Set the background color"],
			type = 'color', order = 3,
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.background)
			end,
			set = function(_, r, g, b, a)
				local t = self.db.profile.background
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end,
		},
		borderTexture = {
			name = L["Border"],
			type = "select", dialogControl = 'LSM30_Border',
			order = 4, width = "double",
			values = AceGUIWidgetLSMlists.border,
			get = function() return self.db.profile.borderTexture end,
			set = function(_, value)
				self.db.profile.borderTexture = value
				self:Update()
			end,
		},
		border = {
			name = L["Border"],
			desc = L["Set the border color"],
			type = 'color', order = 5,
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.border)
			end,
			set = function(_, r, g, b, a)
				local t = self.db.profile.border
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end,
		},
		font = {
			name = L["Font"],
			type = 'select', order = 6, width = "double",
			dialogControl = 'LSM30_Font',
			values = AceGUIWidgetLSMlists.font,
			get = function() return self.db.profile.font or LSM.DefaultMedia.font end,
			set = function(_, value)
				self.db.profile.font = value
				self:Update()
			end,
		},
		textColor = {
			name = L["Text"],
			desc = L["Set the text color"],
			type = 'color', order = 7,
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.textColor)
			end,
			set = function(_, r, g, b, a)
				local t = self.db.profile.textColor
				t[1] = r
				t[2] = g
				t[3] = b
				t[4] = a
				self:Update()
			end,
		},
		precision = {
			name = L["Precision"],
			desc = L["Set the amount of numbers past the decimal place to show."],
			type = 'range', order = 8,
			min = 0,
			max = 3,
			step = 1,
			get = function()
				return self.db.profile.precision
			end,
			set = function(_, value)
				self.db.profile.precision = value
				self:Update()
			end,
		},
		scale = {
			name = L["Size"],
			desc = L["Set the size of the coordinate display."],
			type = 'range', order = 9,
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
			get = function()
				return self.db.profile.scale
			end,
			set = function(_, value)
				self.db.profile.scale = value
				self:Update()
			end,
		},
	}
end
