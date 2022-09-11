
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
			hideCombat = false
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


local Appearance, Position
local DBI = LibStub("LibDBIcon-1.0", true)

local show, button
local origPoint, origParent, origAnchor, origX, origY
local origHeight, origWidth, origWheel
local origAlpha, origStrata

function Expander:Refresh(fromCombat)
	if show then
		origPoint, origParent, origAnchor, origX, origY = Minimap:GetPoint()
		origHeight, origWidth = Minimap:GetSize()
		origWheel = Minimap:IsMouseWheelEnabled()
		origAlpha = Minimap:GetParent():GetEffectiveAlpha()
		origStrata = Minimap:GetFrameStrata()

		Minimap:SetWidth(140 * self.db.profile.scale)
		Minimap:SetHeight(140 * self.db.profile.scale)

		Minimap:ClearAllPoints()
		Minimap:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

		Minimap:GetParent():SetAlpha(self.db.profile.alpha)
		Minimap:SetFrameStrata(self.db.profile.strata)
		MinimapBackdrop:SetFrameStrata(self.db.profile.strata)

		Minimap:SetMouseClickEnabled(false)
		Minimap:EnableMouseWheel(false)

		MinimapBackdrop:Hide()

		Minimap:SetMaskTexture([[Interface\AddOns\Chinchilla\Art\Mask-Square]])

		if DBI then
			for icon in pairs(DBI.objects) do
				DBI:Hide(icon)
			end
		end

		if Chinchilla:IsWrathClassic() then
			MiniMapInstanceDifficulty:Hide()
		elseif Chinchilla:IsRetail() then
			MiniMapInstanceDifficulty:Hide()
			GuildInstanceDifficulty:Hide()
			MiniMapChallengeMode:Hide()
		end

		if((Chinchilla:GetModule("Location", true) and Chinchilla:GetModule("Location"):IsEnabled())) then
			Chinchilla:GetModule("Location"):Hide()
		end

		if(self.db.profile.hideCombat) then
			MinimapBackdrop:RegisterEvent('PLAYER_REGEN_DISABLED')
			MinimapBackdrop:RegisterEvent('PLAYER_REGEN_ENABLED')
			MinimapBackdrop:SetScript('OnEvent', function(self, event, ...)
				if(event == 'PLAYER_REGEN_DISABLED') then
					show = false
				elseif(event == 'PLAYER_REGEN_ENABLED') then
					show = true
				end

				Expander:Refresh(true)
			end)
		end
	else
		Minimap:SetWidth(origWidth)
		Minimap:SetHeight(origHeight)

		if Position and Position:IsEnabled() then
			Position:SetMinimapPosition()
		else
			Minimap:ClearAllPoints()
			Minimap:SetPoint(origPoint, origParent, origAnchor, origX, origY)
		end

		Minimap:SetMouseClickEnabled(true)
		Minimap:EnableMouseWheel(origWheel)

		MinimapBackdrop:Show()

		Minimap:GetParent():SetAlpha(origAlpha or 1)

		if Appearance then
			Appearance:SetAlpha()
			Appearance:SetFrameStrata()
			Appearance:SetShape()
		else
			Minimap:SetFrameStrata(origStrata)
			MinimapBackdrop:SetFrameStrata(origStrata)
			Minimap:SetMaskTexture([[Textures\MinimapMask]])
			Minimap:SetAlpha(1)
		end

		if DBI then
			for icon in pairs(DBI.objects) do
				DBI:Refresh(icon)
			end
		end

		if((Chinchilla:GetModule("Location", true) and Chinchilla:GetModule("Location"):IsEnabled())) then
			Chinchilla:GetModule("Location"):Show()
		end

		if Chinchilla:IsRetail() then
			MiniMapInstanceDifficulty_Update()
		end

		if(self.db.profile.hideCombat and fromCombat ~= true) then
			MinimapBackdrop:UnregisterEvent('PLAYER_REGEN_DISABLED')
			MinimapBackdrop:UnregisterEvent('PLAYER_REGEN_ENABLED')
		end
	end

	local z = Minimap:GetZoom()
	if z > 2 then Minimap:SetZoom(z-1)
	else Minimap:SetZoom(z+1) end
	Minimap:SetZoom(z)
end


function Expander:OnEnable()
	Appearance = Chinchilla:GetModule("Appearance", true)
	Position = Chinchilla:GetModule("Position", true)

	origPoint, origParent, origAnchor, origX, origY = Minimap:GetPoint()
	origHeight, origWidth = Minimap:GetSize()
	origWheel = Minimap:IsMouseWheelEnabled()

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
	show = false
	self:Refresh()

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
			set = function(_, value)
				self.db.profile.toggle = value

				show = false
				self:Refresh()
			end,
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
				end
			end,
			order = 5,
		},
		hideCombat = {
			name = L["Hide In Combat"],
			desc = L["Choose to close the expanded minimap when entering combat."],
			type = 'toggle',
			order = 6,
			width = "double",
			get = function() return self.db.profile.hideCombat end,
			set = function(_, value)
				self.db.profile.hideCombat = value
				show = false
				self:Refresh()
			end,
		},
	}
end
