
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
		},
	})

	if not self.db.profile.enabled then
		self:SetEnabledState(false)
	end
end


local cluster, minimap, button, overlay
local show = false

function Expander:Refresh()
	if show then
		if not cluster then
			cluster = CreateFrame("Frame", nil, UIParent)
			cluster:SetFrameStrata("LOW")
			cluster:SetWidth(140 * self.db.profile.scale)
			cluster:SetHeight(140 * self.db.profile.scale)
			cluster:SetScale(1.2)
			cluster:SetPoint("CENTER")

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

		MinimapCluster:Hide()

		cluster:Show()
		minimap:Show()

		local z = minimap:GetZoom()

		if z > 2 then minimap:SetZoom(z-1)
		else minimap:SetZoom(z+1) end

		minimap:SetZoom(z)

		if GatherMate2 then GatherMate2:GetModule("Display"):ReparentMinimapPins(cluster) end
		if Routes and Routes.ReparentMinimap then Routes:ReparentMinimap(cluster) end
		if overlay and overlay.SetMinimapFrame then overlay:SetMinimapFrame(cluster) end
		if TomTom and TomTom.ReparentMinimap then TomTom:ReparentMinimap(cluster) end
	else
		cluster:Hide()
		minimap:Hide()

		MinimapCluster:Show()

		local z = Minimap:GetZoom()

		if z > 2 then Minimap:SetZoom(z-1, true)
		else Minimap:SetZoom(z+1, true) end

		Minimap:SetZoom(z, true)

		if GatherMate2 then GatherMate2:GetModule("Display"):ReparentMinimapPins(Minimap) end
		if Routes and Routes.ReparentMinimap then Routes:ReparentMinimap(Minimap) end
		if overlay and overlay.SetMinimapFrame then overlay:SetMinimapFrame(Minimap) end
		if TomTom and TomTom.ReparentMinimap then TomTom:ReparentMinimap(Minimap) end
	end
end


function Expander:OnEnable()
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

	if _NPCScan and _NPCScan.Overlay and not overlay then
		overlay = _NPCScan.Overlay.Modules.List["Minimap"]
	end
end

function Expander:OnDisable()
	button:SetScript("OnMouseDown", nil)
	button:SetScript("OnMouseUp", nil)
end


function Expander:SetSizes()
	if not cluster or not minimap then return end

	cluster:SetWidth(140 * self.db.profile.scale)
	cluster:SetHeight(140 * self.db.profile.scale)
	cluster:SetScale(1.2)

	minimap:SetWidth(140 * self.db.profile.scale)
	minimap:SetHeight(140 * self.db.profile.scale)
	minimap:SetScale(1.2)
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
		scale = {
			name = L["Size"],
			desc = L["The size of the expanded minimap"],
			type = 'range',
			order = 2,
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
			order = 3,
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
			order = 4,
			get = function() return self.db.profile.toggle end,
			set = function(_, value) self.db.profile.toggle = value end,
		},
	}
end
