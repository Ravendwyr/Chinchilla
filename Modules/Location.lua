
local Location = Chinchilla:NewModule("Location", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

local LSM = LibStub("LibSharedMedia-3.0")

Location.displayName = L["Location"]
Location.desc = L["Show zone information on or near minimap"]


function Location:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Location", {
		profile = {
			scale = 1.2,
			positionX = 0,
			positionY = 70,
			showClose = true,
			font = LSM.DefaultMedia.font,
			backgroundTexture = "Blizzard Tooltip",
			background = { TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b, 1 },
			borderTexture = "Blizzard Tooltip",
			border = { TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b, 1 },
			enabled = true,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end

local frame, backdrop
function Location:OnEnable()
	backdrop = {
		bgFile = LSM:Fetch("background", self.db.profile.backgroundTexture, true),
		edgeFile = LSM:Fetch("border", self.db.profile.borderTexture, true),
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
		edgeSize = 16,
	}

	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Location_Frame", MinimapCluster, BackdropTemplateMixin and "BackdropTemplate")
		frame:SetBackdrop(backdrop)

		frame:SetWidth(1)
		frame:SetHeight(1)

		local text = frame:CreateFontString(frame:GetName() .. "_FontString", "ARTWORK", "GameFontNormalSmall")
		frame.text = text

		text:SetPoint("CENTER")

		frame:SetScript("OnDragStart", function(this)
			this:StartMoving()
		end)
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

		local closeButton = CreateFrame("Button", frame:GetName() .. "_CloseButton", frame)
		frame.closeButton = closeButton

		closeButton:SetWidth(27)
		closeButton:SetHeight(27)
		closeButton:SetPoint("LEFT", frame, "RIGHT", -6, 0)

		closeButton:SetScript("OnClick", function(this)
			if Minimap:IsShown() then
				PlaySound(SOUNDKIT.IG_MINIMAP_CLOSE)
				Minimap:Hide()
				this:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
				this:SetPushedTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Down")
			else
				PlaySound(SOUNDKIT.IG_MINIMAP_OPEN)
				Minimap:Show()
				this:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
				this:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
			end
			UpdateUIPanelPositions()
		end)

		closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
		closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
		closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
	end

	frame:Show()

	if self.db.profile.showClose then
		frame.closeButton:Show()
	else
		frame.closeButton:Hide()
	end

	self:SetFont()
	self:Update()

	self:RegisterEvent("ZONE_CHANGED", "Update")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "Update")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Update")

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "MediaRegistered")

	if Chinchilla:GetModule("ShowHide", true) then
		Chinchilla:GetModule("ShowHide"):Update()
	end
end

function Location:OnDisable()
	frame:Hide()

	if Chinchilla:GetModule("ShowHide", true) then
		Chinchilla:GetModule("ShowHide"):Update()
	end
end


function Location:MediaRegistered(_, mediaType, mediaName)
	if mediaType == "font" and mediaName == self.db.profile.font then
		self:SetFont()
	elseif mediaType == "background" and mediaName == self.db.profile.backgroundTexture then
		self:SetBackground()
	elseif mediaType == "border" and mediaName == self.db.profile.borderTexture then
		self:SetBorder()
	end
end

function Location:SetFont(font)
	if font then self.db.profile.font = font
	else font = self.db.profile.font end

	frame.text:SetFont(LSM:Fetch("font", font), 11)

	self:Update()
end

function Location:SetBackground(bgFile)
	if bgFile then self.db.profile.backgroundTexture = bgFile
	else bgFile = self.db.profile.backgroundTexture end

	backdrop.bgFile = LSM:Fetch("background", bgFile)

	frame:SetBackdrop(backdrop)
end

function Location:SetBorder(edgeFile)
	if edgeFile then self.db.profile.borderTexture = edgeFile
	else edgeFile = self.db.profile.borderTexture end

	backdrop.edgeFile = LSM:Fetch("border", edgeFile)

	frame:SetBackdrop(backdrop)
end


function Location:Update()
	if not self:IsEnabled() then
		return
	end

	local scale = self.db.profile.scale

	frame:SetScale(scale)
	frame:SetFrameLevel(MinimapCluster:GetFrameLevel() + 7)

	frame.closeButton:SetFrameLevel(MinimapCluster:GetFrameLevel()+7)

	frame:SetBackdropColor(unpack(self.db.profile.background))
	frame:SetBackdropBorderColor(unpack(self.db.profile.border))

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", self.db.profile.positionX+9/scale, self.db.profile.positionY+4/scale)

	frame.text:SetText(GetMinimapZoneText())
	frame:SetWidth(frame.text:GetWidth() + 16)
	frame:SetHeight(frame.text:GetHeight() + 14)

	local pvpType = GetZonePVPInfo()

	if pvpType == "sanctuary" then
		frame.text:SetTextColor(0.41, 0.8, 0.94)
	elseif pvpType == "arena" then
		frame.text:SetTextColor(1.0, 0.1, 0.1)
	elseif pvpType == "friendly" then
		frame.text:SetTextColor(0.1, 1.0, 0.1)
	elseif pvpType == "hostile" then
		frame.text:SetTextColor(1.0, 0.1, 0.1)
	elseif pvpType == "contested" then
		frame.text:SetTextColor(1.0, 0.7, 0.0)
	else
		frame.text:SetTextColor(1.0, 0.82, 0.0)
	end
end

function Location:SetMovable(value)
	frame:SetMovable(value)
	frame:EnableMouse(value)

	if value then frame:RegisterForDrag("LeftButton")
	else frame:RegisterForDrag() end
end

function Location:Hide()
	frame:Hide()
end

function Location:Show()
	frame:Show()
end

function Location:GetOptions()
	return {
		position = {
			name = L["Position"],
			desc = L["Set the position of the location indicator"],
			type = 'group', order = 1,
			inline = true,
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Allow the location indicator to be moved"],
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
					desc = L["Set the position on the x-axis for the location indicator relative to the minimap."],
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
					desc = L["Set the position on the y-axis for the location indicator relative to the minimap."],
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
				self:SetBackground(value)
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
				self:SetBorder(value)
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
			hidden = function()
				return self.db.profile.chat
			end,
		},
		font = {
			name = L["Font"],
			type = 'select', width = "double", order = 6,
			dialogControl = 'LSM30_Font',
			values = AceGUIWidgetLSMlists.font,
			get = function() return self.db.profile.font or LSM.DefaultMedia.font end,
			set = function(_, value) self:SetFont(value) end,
		},
		showClose = {
			name = L["Show close button"],
			desc = L["Show the button to hide the minimap"],
			type = 'toggle', order = 7,
			get = function()
				return self.db.profile.showClose
			end,
			set = function(_, value)
				self.db.profile.showClose = value
				if frame then
					if value then
						frame.closeButton:Show()
					else
						frame.closeButton:Hide()
					end
				end
			end
		},
		scale = {
			name = L["Size"],
			desc = L["Set the size of the location display."],
			type = 'range', order = 8,
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
