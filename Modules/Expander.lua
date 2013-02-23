
local Expander = Chinchilla:NewModule("Expander")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Expander.displayName = L["Expander"]
Expander.desc = L["Show an expanded minimap on keypress"]


function Expander:OnInitialize()
	self.db = Chinchilla.db:RegisterNamespace("Expander", {
		profile = {
			enabled = true,
			key = false, toggle = true,
			scale = 3, alpha = 1,
			anchor = "CENTER", x = 0, y = 0,
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


local cluster, minimap, button, overlay, GM2
local show, locked = false, true

function Expander:Refresh()
	if not minimap then
		minimap = CreateFrame("Minimap", "Chinchilla_Expander_Minimap", cluster)
		minimap:SetFrameStrata("BACKGROUND")
		minimap:SetWidth(140 * self.db.profile.scale)
		minimap:SetHeight(140 * self.db.profile.scale)
		minimap:SetScale(1.2)
		minimap:SetPoint("CENTER")
		minimap:SetAlpha(self.db.profile.alpha)
		minimap:EnableMouse(false)
		minimap:EnableMouseWheel(false)
		minimap:EnableKeyboard(false)

		setmetatable(cluster, { __index = minimap })

		cluster.GetScale = function() return 1 end
	end

	if show then
		Minimap:Hide()

		cluster:Show()
		minimap:Show()

		local z = minimap:GetZoom()

		if z > 2 then minimap:SetZoom(z-1)
		else minimap:SetZoom(z+1) end

		minimap:SetZoom(z)

		if GM2 then
			GM2:ReparentMinimapPins(cluster)
			GM2:UpdateMiniMap(true)
		end

		if Routes and Routes.ReparentMinimap then Routes:ReparentMinimap(cluster) end
		if overlay and overlay.SetMinimapFrame then overlay:SetMinimapFrame(cluster) end
		if TomTom and TomTom.ReparentMinimap then TomTom:ReparentMinimap(cluster) end
	else
		cluster:Hide()
		minimap:Hide()

		Minimap:Show()

		local z = Minimap:GetZoom()

		if z > 2 then Minimap:SetZoom(z-1)
		else Minimap:SetZoom(z+1) end

		Minimap:SetZoom(z)

		if GM2 then
			GM2:ReparentMinimapPins(Minimap)
			GM2:UpdateMiniMap(true)
		end

		if Routes and Routes.ReparentMinimap then Routes:ReparentMinimap(Minimap) end
		if overlay and overlay.SetMinimapFrame then overlay:SetMinimapFrame(Minimap) end
		if TomTom and TomTom.ReparentMinimap then TomTom:ReparentMinimap(Minimap) end
	end
end


function Expander:OnEnable()
	if not cluster then
		cluster = CreateFrame("Frame", nil, UIParent)
		cluster:Hide()
		cluster:SetClampedToScreen(true)
		cluster:SetFrameStrata("BACKGROUND")
		cluster:SetWidth(168 * self.db.profile.scale)
		cluster:SetHeight(168 * self.db.profile.scale)
		cluster:SetScale(1.2)
		cluster:SetPoint(self.db.profile.anchor, "UIParent", self.db.profile.anchor, self.db.profile.x, self.db.profile.y)
	end

	self:SetLocked(true)

	if not button then
		button = CreateFrame("Button", "Chinchilla_Expander_Button")
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

	if _NPCScan and _NPCScan.Overlay then
		overlay = _NPCScan.Overlay.Modules.List["Minimap"]
	end

	if GatherMate2 then
		GM2 = GatherMate2:GetModule("Display")
	end
end

function Expander:OnDisable()
	button:SetScript("OnMouseDown", nil)
	button:SetScript("OnMouseUp", nil)
end


function Expander:SetSizes()
	if cluster then
		cluster:SetWidth(168 * self.db.profile.scale)
		cluster:SetHeight(168 * self.db.profile.scale)
		cluster:SetScale(1.2)
	end

	if minimap then
		minimap:SetWidth(140 * self.db.profile.scale)
		minimap:SetHeight(140 * self.db.profile.scale)
		minimap:SetScale(1.2)
	end
end


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

function Expander:IsLocked()
	return locked
end

function Expander:SetLocked(value)
	locked = value

	if not cluster then return end

	if not locked then
		cluster:SetMovable(true)
		cluster:RegisterForDrag("LeftButton")
		cluster:SetScript("OnMouseDown", StartMoving)
		cluster:SetScript("OnMouseUp", StopMoving)
		cluster:EnableMouse(true)
	else
		cluster:SetMovable()
		cluster:RegisterForDrag()
		cluster:SetScript("OnMouseDown", nil)
		cluster:SetScript("OnMouseUp", nil)
		cluster:EnableMouse(false)
	end
end


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
				self:SetSizes()
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
				if minimap then minimap:SetAlpha(value) end
			end,
		},

		toggle = {
			name = L["Toggle"],
			desc = L["Choose to toggle the expanded minimap or only keep it shown while pressing the button down."],
			type = 'toggle',
			order = 5,
			get = function() return self.db.profile.toggle end,
			set = function(_, value) self.db.profile.toggle = value end,
		},
	}
end
