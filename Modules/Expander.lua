
local Expander = Chinchilla:NewModule("Expander")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Expander.displayName = L["Expander"]
Expander.desc = L["Show an expanded minimap on keypress"]


function Expander:OnInitialize()
	GameTimeFrame:SetParent(MinimapBackdrop)
	TimeManagerClockButton:SetParent(MinimapBackdrop)

	self.db = Chinchilla.db:RegisterNamespace("Expander", {
		profile = {
			enabled = true,
			key = false, toggle = true,
			scale = 3, alpha = 1, strata = "LOW",
			anchor = "CENTER", x = 0, y = 0,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


local Appearance
local DBI = LibStub("LibDBIcon-1.0", true)

local show, button
local origPoint, origParent, origAnchor, origX, origY
local origHeight, origWidth, origStrata, origWheel

function Expander:Refresh()
	if show then
		origPoint, origParent, origAnchor, origX, origY = Minimap:GetPoint()
		origHeight, origWidth = Minimap:GetSize()
		origStrata = MinimapCluster:GetFrameStrata()
		origWheel = Minimap:IsMouseWheelEnabled()

		Minimap:SetWidth(140 * self.db.profile.scale)
		Minimap:SetHeight(140 * self.db.profile.scale)

		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		Minimap:SetAlpha(self.db.profile.alpha)

		Minimap:SetFrameStrata(self.db.profile.strata)
		MinimapBackdrop:SetFrameStrata(self.db.profile.strata)
		MinimapCluster:SetFrameStrata(self.db.profile.strata)

		Minimap:EnableMouse(false)
		Minimap:EnableMouseWheel(false)

		MinimapBackdrop:Hide()

		Minimap:SetMaskTexture([[Interface\AddOns\Chinchilla\Art\Mask-Square]])

		if DBI then
			for icon in pairs(DBI.objects) do
				DBI.objects[icon]:Hide()
			end
		end
	else
		Minimap:ClearAllPoints()
		Minimap:SetPoint(origPoint, origParent, origAnchor, origX, origY)

		Minimap:EnableMouse(true)
		Minimap:EnableMouseWheel(origWheel)

		MinimapBackdrop:Show()

		if Appearance then
			Appearance:SetAlpha()
			Appearance:SetFrameStrata()
			Appearance:SetScale()
			Appearance:SetShape()
		else
			Minimap:SetWidth(origWidth)
			Minimap:SetHeight(origHeight)
			Minimap:SetFrameStrata(origStrata)
			MinimapBackdrop:SetFrameStrata(origStrata)
			MinimapCluster:SetFrameStrata(origStrata)
			Minimap:SetMaskTexture([[Textures\MinimapMask]])
			Minimap:SetAlpha(1)
		end

		if DBI then
			for icon in pairs(DBI.objects) do
				DBI.objects[icon]:Show()
			end
		end
	end

	local z = Minimap:GetZoom()
	if z > 2 then Minimap:SetZoom(z-1)
	else Minimap:SetZoom(z+1) end
	Minimap:SetZoom(z)
end


function Expander:OnEnable()
	Appearance = Chinchilla:GetModule("Appearance", true)

	if not button then
		button = CreateFrame("Button", "Chinchilla_Expander_Button") -- button use for keybinding hax0rz
	end

	button:SetScript("OnMouseDown", function()
		if self.db.profile.toggle then
			show = not show
		else
			show = true
		end

		self:Refresh()
	end)

	button:SetScript("OnMouseUp", function()
		if not self.db.profile.toggle then
			show = false
			self:Refresh()
		end
	end)

	if self.db.profile.key then
		CreateFrame("Frame"):SetScript("OnUpdate", function(this)
			if InCombatLockdown() then return end
			SetBindingClick(self.db.profile.key, "Chinchilla_Expander_Button")
			this:Hide()
		end)
	end
end


function Expander:OnDisable()
	button:SetScript("OnMouseDown", nil)
	button:SetScript("OnMouseUp", nil)
end

--[[
local function StartMoving()
	cluster:StartMoving()
end

local function StopMoving()
	cluster:StopMovingOrSizing()

	local anchor, _, _, x, y = cluster:GetPoint()

	Expander.db.profile.anchor = anchor
	Expander.db.profile.x = x
	Expander.db.profile.y = y
end
]]

function Expander:GetOptions()
	return {
		key = {
			name = L["Keybinding"],
			desc = L["The key to press to show the expanded minimap"],
			type = 'keybinding',
			order = 1,
			get = function() return self.db.profile.key end,
			set = function(_, value)
				if self.db.profile.key then
					SetBinding(self.db.profile.key, nil)
				end

				self.db.profile.key = value

				if button and value then
					SetBindingClick(value, "Chinchilla_Expander_Button")
				end
			end,
			disabled = function() return InCombatLockdown() or not self:IsEnabled() end,
		},
		toggle = {
			name = L["Toggle"],
			desc = L["Choose to toggle the expanded minimap or only keep it shown while pressing the button down."],
			type = 'toggle',
			order = 2,
			width = "double",
			get = function() return self.db.profile.toggle end,
			set = function(_, value) self.db.profile.toggle = value end,
		},
--[[
		movable = {
			name = L["Movable"],
			desc = L["Allow the minimap to be movable so you can drag it where you want"],
			type = 'toggle',
			order = 2,
			width = 'double',
			get = function()
				return not self:IsLocked()
			end,
			set = function(_, value)
				self:SetLocked(not value)
			end,
		},
]]
		scale = {
			name = L["Size"],
			desc = L["The size of the expanded minimap"],
			type = 'range',
			order = 3,
			min = 0.5,
			max = 8,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
			get = function() return self.db.profile.scale end,
			set = function(_, value)
				self.db.profile.scale = value

				if show then
					Minimap:SetWidth(140 * self.db.profile.scale)
					Minimap:SetHeight(140 * self.db.profile.scale)

					local z = Minimap:GetZoom()

					if z > 2 then Minimap:SetZoom(z-1)
					else Minimap:SetZoom(z+1) end

					Minimap:SetZoom(z)
				end
			end,
		},
		alpha = {
			name = L["Opacity"],
			type = 'range',
			order = 4,
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			get = function() return self.db.profile.alpha end,
			set = function(_, value)
				self.db.profile.alpha = value

				if show then
					Minimap:SetAlpha(value)
				end
			end,
		},
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
				self.db.profile.strata = value

				if show then
					Minimap:SetFrameStrata(self.db.profile.strata)
					MinimapBackdrop:SetFrameStrata(self.db.profile.strata)
					MinimapCluster:SetFrameStrata(self.db.profile.strata)
				end
			end,
			order = 5,
		},
	}
end
