local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
local Chinchilla_Location = Chinchilla:NewModule("Location", "LibRockEvent-1.0")
local self = Chinchilla_Location
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Location.desc = L["Show zone information on or near minimap"]

function Chinchilla_Location:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Location")
	Chinchilla:SetDatabaseNamespaceDefaults("Location", "profile", {
		scale = 1.2,
		positionX = 0,
		positionY = 70,
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
			1,
			0.82,
			0,
			1
		}
	})
end

local frame
function Chinchilla_Location:OnEnable()
	if not frame then
		frame = CreateFrame("Frame", "Chinchilla_Location_Frame", Minimap)
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
			self:Update()
			Rock("LibRockConfig-1.0"):RefreshConfigMenu(Chinchilla)
		end)
	end
	frame:Show()
	self:Update()
	self:AddEventListener("ZONE_CHANGED", "Update")
	self:AddEventListener("ZONE_CHANGED_INDOORS", "Update")
	self:AddEventListener("ZONE_CHANGED_NEW_AREA", "Update")
	MinimapToggleButton:Hide()
	MinimapBorderTop:Hide()
	MinimapZoneTextButton:Hide()
	if Chinchilla:HasModule("ShowHide") then
		Chinchilla:GetModule("ShowHide"):Update()
	end
end

function Chinchilla_Location:OnDisable()
	frame:Hide()
	MinimapToggleButton:Show()
	MinimapBorderTop:Show()
	MinimapZoneTextButton:Show()
	if Chinchilla:HasModule("ShowHide") then
		Chinchilla:GetModule("ShowHide"):Update()
	end
end

function Chinchilla_Location:Update()
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	frame:SetScale(self.db.profile.scale)
	frame:SetFrameLevel(MinimapCluster:GetFrameLevel()+5)
	frame.text:SetTextColor(unpack(self.db.profile.textColor))
	frame:SetBackdropColor(unpack(self.db.profile.background))
	frame:SetBackdropBorderColor(unpack(self.db.profile.border))
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", self.db.profile.positionX, self.db.profile.positionY)
	frame.text:SetText(GetMinimapZoneText())
	frame:SetWidth(frame.text:GetWidth() + 12)
	frame:SetHeight(frame.text:GetHeight() + 12)
end

function Chinchilla_Location:SetMovable(value)
	frame:SetMovable(value)
	frame:EnableMouse(value)
	if value then
		frame:RegisterForDrag("LeftButton")
	else
		frame:RegisterForDrag()
	end
end

Chinchilla_Location:AddChinchillaOption({
	name = L["Location"],
	desc = Chinchilla_Location.desc,
	type = 'group',
	args = {
		scale = {
			name = L["Size"],
			desc = L["Set the size of the location display."],
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
			desc = L["Set the position of the location indicator"],
			type = 'group',
			groupType = 'inline',
			args = {
				movable = {
					name = L["Movable"],
					desc = L["Allow the location indicator to be moved"],
					type = 'boolean',
					get = function()
						return frame:IsMovable()
					end,
					set = "SetMovable",
					order = 1,
				},
				x = {
					name = L["Horizontal position"],
					desc = L["Set the position on the x-axis for the location indicator relative to the minimap."],
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
						self:Update()
					end,
					order = 2,
				},
				y = {
					name = L["Vertical position"],
					desc = L["Set the position on the y-axis for the location indicator relative to the minimap."],
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
						self:Update()
					end,
					order = 3,
				},
			}
		},
	}
})
