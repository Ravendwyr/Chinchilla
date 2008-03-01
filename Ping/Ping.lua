local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_Ping = Chinchilla:NewModule("Ping", "LibRockEvent-1.0", "LibRockHook-1.0")
local self = Chinchilla_Ping
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Ping.desc = L["Show who last pinged the minimap"]

function Chinchilla_Ping:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Ping")
	Chinchilla:SetDatabaseNamespaceDefaults("Ping", "profile", {
		chat = false,
		scale = 1,
		positionX = 0,
		positionY = 60,
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
function Chinchilla_Ping:OnEnable()
	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Ping_Frame", MiniMapPing) -- anchor to MiniMapPing so that it hides/shows based on MiniMapPing
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
			frame:ClearAllPoints()
			frame:SetPoint("CENTER", Minimap, "CENTER", self.db.profile.positionX, self.db.profile.positionY)
			Rock("LibRockConfig-1.0"):RefreshConfigMenu(Chinchilla)
		end)
	end
	frame:Show()
	self:AddEventListener("MINIMAP_PING")
	
	self:AddHook("Minimap_SetPing")
	self:AddHook("Minimap_OnClick")
end

function Chinchilla_Ping:OnDisable()
	frame:Hide()
end

local allowNextPlayerPing = false
function Chinchilla_Ping:MINIMAP_PING(ns, event, unit)
	if UnitIsUnit("player", unit) and not allowNextPlayerPing then
		frame:Hide()
		return
	end
	allowNextPlayerPing = false
	
	local name, server = UnitName(unit)
	if server and server ~= "" then
		name = name .. '-' .. server
	end
	local _, class = UnitClass(unit)
	local color = RAID_CLASS_COLORS[class]

	if self.db.profile.chat then
		DEFAULT_CHAT_FRAME:AddMessage(L["Minimap pinged by %s"]:format(("|cff%02x%02x%02x%s|r"):format(color.r*255, color.g*255, color.b*255, name)))
		return
	end
	frame:Show()
	
	frame.text:SetText(L["Ping by %s"]:format(("|cff%02x%02x%02x%s|r"):format(color.r*255, color.g*255, color.b*255, name)))
	frame:SetScale(self.db.profile.scale)
	frame:SetFrameLevel(MinimapCluster:GetFrameLevel()+5)
	frame:SetWidth(frame.text:GetWidth() + 12)
	frame:SetHeight(frame.text:GetHeight() + 12)
	frame.text:SetTextColor(unpack(self.db.profile.textColor))
	frame:SetBackdropColor(unpack(self.db.profile.background))
	frame:SetBackdropBorderColor(unpack(self.db.profile.border))
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", self.db.profile.positionX, self.db.profile.positionY)
end

local function test()
	allowNextPlayerPing = true
	Minimap:PingLocation(0, 0)
end

function Chinchilla_Ping:SetMovable(value)
	frame:SetMovable(value)
	frame:EnableMouse(value)
	if value then
		frame:SetParent(Minimap)
		frame:RegisterForDrag("LeftButton")
		if not MiniMapPing:IsShown() then
			test()
		end
	else
		frame:SetParent(MiniMapPing)
		frame:RegisterForDrag()
	end
end

local function isCornerRound(x, y)
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	
	if minimapShape == "ROUND" then
		return true
	elseif minimapShape == "SQUARE" then
		return false
	elseif minimapShape == "CORNER-TOPRIGHT" then
		return x > 0 and y > 0
	elseif minimapShape == "CORNER-TOPLEFT" then
		return x < 0 and y > 0
	elseif minimapShape == "CORNER-BOTTOMRIGHT" then
		return x > 0 and y < 0
	elseif minimapShape == "CORNER-BOTTOMLEFT" then
		return x < 0 and y < 0
	elseif minimapShape == "SIDE-LEFT" then
		return x < 0
	elseif minimapShape == "SIDE-RIGHT" then
		return x > 0
	elseif minimapShape == "SIDE-TOP" then
		return y > 0
	elseif minimapShape == "SIDE-BOTTOM" then
		return y < 0
	elseif minimapShape == "TRICORNER-TOPRIGHT" then
		return x > 0 or y > 0
	elseif minimapShape == "TRICORNER-TOPLEFT" then
		return x < 0 or y > 0
	elseif minimapShape == "TRICORNER-BOTTOMRIGHT" then
		return x > 0 or y < 0
	elseif minimapShape == "TRICORNER-BOTTOMLEFT" then
		return x < 0 or y < 0
	end
	return true
end

function Chinchilla_Ping:Minimap_SetPing(x, y, playSound)
	x = x * Minimap:GetWidth()
	y = y * Minimap:GetHeight()
	local radius = Minimap:GetWidth()/2
	
	if x > radius or x < -radius or y > radius or y < -radius or (x^2 + y^2 > radius^2 and isCornerRound(x, y)) then
		MiniMapPing:Hide()
		return
	end
	
	MiniMapPing:SetPoint("CENTER", "Minimap", "CENTER", x, y)
	MiniMapPing:SetAlpha(1)
	MiniMapPing:Show()
	if playSound then
		PlaySound("MapPing")
	end
end

function Chinchilla_Ping:Minimap_OnClick()
	local x, y = GetCursorPosition()
	x = x / Minimap:GetEffectiveScale()
	y = y / Minimap:GetEffectiveScale()

	local cx, cy = Minimap:GetCenter()
	x = x - cx
	y = y - cy
	
	local radius = Minimap:GetWidth()/2
	
	if x > radius or x < -radius or y > radius or y < -radius or (x^2 + y^2 > radius^2 and isCornerRound(x, y)) then
		return
	end
	Minimap:PingLocation(x, y)
end

Chinchilla_Ping:AddChinchillaOption(function() return {
	name = L["Ping"],
	desc = Chinchilla_Ping.desc,
	type = 'group',
	args = {
		test = {
			name = L["Test"],
			desc = L["Show a test ping"],
			type = 'execute',
			func = test,
			order = -1,
		},
		chat = {
			name = L["Show in chat"],
			desc = L["Show who pinged in chat instead of in a frame on the minimap."],
			type = 'boolean',
			get = function()
				return self.db.profile.chat
			end,
			set = function(value)
				self.db.profile.chat = value
			end
		},
		scale = {
			name = L["Size"],
			desc = L["Set the size of the ping display."],
			type = 'number',
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
				test()
			end,
			hidden = function()
				return self.db.profile.chat
			end
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
				test()
			end,
			hidden = function()
				return self.db.profile.chat
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
				test()
			end,
			hidden = function()
				return self.db.profile.chat
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
				test()
			end,
			hidden = function()
				return self.db.profile.chat
			end
		},
		position = {
			name = L["Position"],
			desc = L["Set the position of the ping indicator"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Allow the ping indicator to be moved"],
					type = 'boolean',
					get = function()
						return frame and frame:IsMovable()
					end,
					set = "SetMovable",
					order = 1,
					disabled = function()
						return not frame
					end,
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the ping indicator relative to the minimap."],
					type = 'number',
					min = function()
						return -math.floor(GetScreenWidth()/5 + 0.5)*5
					end,
					max = function()
						return math.floor(GetScreenWidth()/5 + 0.5)*5
					end,
					step = 1,
					bigStep = 5,
					get = function()
						return self.db.profile.positionX
					end,
					set = function(value)
						self.db.profile.positionX = value
						test()
					end,
					order = 2,
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the ping indicator relative to the minimap."],
					type = 'number',
					min = function()
						return -math.floor(GetScreenHeight()/5 + 0.5)*5
					end,
					max = function()
						return math.floor(GetScreenHeight()/5 + 0.5)*5
					end,
					step = 1,
					bigStep = 5,
					get = function()
						return self.db.profile.positionY
					end,
					set = function(value)
						self.db.profile.positionY = value
						test()
					end,
					order = 3,
				},
			}
		},
	}
} end)
