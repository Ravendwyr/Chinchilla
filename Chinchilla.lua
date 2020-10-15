
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Chinchilla = LibStub("AceAddon-3.0"):NewAddon("Chinchilla", "AceConsole-3.0", "AceHook-3.0")


--@non-debug@
Chinchilla.version = "v2.10.1"
--@end-non-debug@

--[===[@debug@
Chinchilla.version = "Development"
--@end-debug@]===]


function Chinchilla:AddBorderStyle()
	-- blank method, to be replaced in Appearance module
	-- if Appearance module does not exist, other addons should not break by calling this
end

function Chinchilla:AddTrackingDotStyle()
	-- blank method, to be replaced in TrackingDots module
	-- if TrackingDots module does not exist, other addons should not break by calling this
end

function Chinchilla:CallMethodOnAllModules(method, ...)
	for _, module in self:IterateModules() do
		if type(module[method]) == "function" then
			module[method](module, ...)
		end
	end
end

function Chinchilla:Minimap_OnMouseUp(this, button, ...)
	if button == self.db.profile.mouseButton then
		if not InCombatLockdown() then
			self:OpenConfig()
		end
	elseif not self:IsClassic() and button == self.db.profile.trackButton then
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", -10, -20)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	else
		return self.hooks[this].OnMouseUp(this, button, ...)
	end
end

function Chinchilla:IsClassic()
	return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function Chinchilla:OpenConfig()
	AceConfigDialog:Open("Chinchilla")
end

function Chinchilla:CreateConfig()
	local options = {
		name = L["Chinchilla Minimap"],
		type = 'group',
		args = {
			lock = {
				name = L["Lock"],
				desc = L["Lock any draggable items regarding the minimap, so they can't be dragged mistakenly."],
				type = 'toggle',
				tristate = true,
				order = 1,
				get = function()
					local current, max = 0, 0

					for _, module in Chinchilla:IterateModules(false) do
						if type(module.IsLocked) == "function" then
							local locked = module:IsLocked()

							max = max + 1

							if locked then
								if locked == "HALF" then current = current + 0.5
								else current = current + 1 end
							end
						end
					end

					if current == 0 then return false
					elseif current == max then return true
					else return nil end
				end,
				set = function(_, value)
					Chinchilla:CallMethodOnAllModules("SetLocked", not not value)
				end,
			},
			rotateMinimap = {
				name = _G.ROTATE_MINIMAP,
				desc = _G.OPTION_TOOLTIP_ROTATE_MINIMAP,
				type = 'toggle',
				order = 2,
				get = function() return GetCVar("rotateMinimap") == "1" end,
				set = function() InterfaceOptionsDisplayPanelRotateMinimap:Click() end,
			},
			mouseButton = {
				name = L["Preferences button"],
				desc = L["Button to use on the minimap to open the preferences window.\nNote: you can always open with /chin"],
				type = "select",
				order = 3,
				values = {
					RightButton = L["Right mouse button"],
					MiddleButton = L["Middle mouse button"],
					Button4 = L["Mouse button #4"],
					Button5 = L["Mouse button #5"],
					None = L["None"],
				},
				get = function()
					return Chinchilla.db.profile.mouseButton
				end,
				set = function(_, value)
					Chinchilla.db.profile.mouseButton = value
				end,
			},
			trackButton = not Chinchilla:IsClassic() and {
				name = L["Tracking"],
				desc = L["Button to use on the minimap to toggle the tracking menu."],
				type = "select",
				order = 3,
				values = {
					RightButton = L["Right mouse button"],
					MiddleButton = L["Middle mouse button"],
					Button4 = L["Mouse button #4"],
					Button5 = L["Mouse button #5"],
					None = L["None"],
				},
				get = function()
					return Chinchilla.db.profile.trackButton
				end,
				set = function(_, value)
					Chinchilla.db.profile.trackButton = value
				end,
			} or nil,
			version = {
				name = L["Version: %s"]:format(Chinchilla.version),
				type = "description",
				order = 5,
			},
		},
	}

	for key, module in Chinchilla:IterateModules() do
		local t = module.GetOptions and module:GetOptions() or {}

		for _, args in pairs(t) do
			args.hidden = function() return not module:IsEnabled() end
		end

		t.enabled = {
			type = 'toggle',
			name = L["Enable"],
			desc = L["Enable this module"],
			get = function()
				return module:IsEnabled()
			end,
			set = function(_, value)
				module.db.profile.enabled = not not value -- to ensure a boolean

				if value then return module:Enable()
				else return module:Disable() end
			end,
			order = 1,
			width = "full",
		}

		options.args[key] = { type = "group", name = module.displayName, desc = module.desc, handler = module, args = t }
	end

	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Chinchilla.db)
	options.args.profile.order = -1

	return options
end


Chinchilla_BossAnchor = CreateFrame("Frame", "Chinchilla_BossAnchor", UIParent)
Chinchilla_BossAnchor:SetWidth(200)
Chinchilla_BossAnchor:SetHeight(350)


function Chinchilla:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Chinchilla2DB", { profile = { mouseButton = "RightButton", trackButton = "MiddleButton" }}, 'Default')

	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdate")

	-- these frames still exist in Classic although probably not being used
	for i=1, 5, 1 do
		_G["Boss"..i.."TargetFrame"]:ClearAllPoints()
		_G["Boss"..i.."TargetFrame"]:SetParent(Chinchilla_BossAnchor)
		_G["Boss"..i.."TargetFrame"]:SetPoint("TOP", i == 1 and Chinchilla_BossAnchor or _G["Boss"..(i-1).."TargetFrame"], i == 1 and "TOP" or "BOTTOM")
		_G["Boss"..i.."TargetFrame"].SetPoint = function() end
	end
end

function Chinchilla:OnEnable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Chinchilla", Chinchilla.CreateConfig)
	AceConfigDialog:SetDefaultSize("Chinchilla", 800, 600)

	self:RegisterChatCommand("chin", "OpenConfig")
	self:RegisterChatCommand("chinchilla", "OpenConfig")

	MinimapCluster:EnableMouse(false)
	MinimapBorderTop:Hide()
	MinimapZoneTextButton:Hide()

	if self:IsClassic() then
		MinimapToggleButton:Hide()
	end

	-- this button still exists in Classic
	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\Chinchilla\\Art\\UI-MiniMap-WorldMapSquare")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\Chinchilla\\Art\\UI-MiniMap-WorldMapSquare")

	self:RawHookScript(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
end

function Chinchilla:OnDisable()
	MinimapCluster:EnableMouse(true)
	MinimapBorderTop:Show()
	MinimapZoneTextButton:Show()

	if self:IsClassic() then
		MinimapToggleButton:Show()
	end

	MiniMapWorldMapButton:SetNormalTexture("Interface\\Minimap\\UI-MiniMap-WorldMapSquare")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\Minimap\\UI-MiniMap-WorldMapSquare")
end

function Chinchilla:OnProfileUpdate()
	for _, module in self:IterateModules() do
		-- lazy method, turn it off and back on again
		module:Disable()

		if module.db.profile.enabled then
			module:Enable()
		end
	end
end
