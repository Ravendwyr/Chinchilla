
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Chinchilla = LibStub("AceAddon-3.0"):NewAddon("Chinchilla", "AceHook-3.0")


--[===[@non-debug@
Chinchilla.version = "@project-version@"
--@end-non-debug@]===]

--@debug@
Chinchilla.version = "Development"
--@end-debug@


function Chinchilla:AddBorderStyle()
	-- blank method, to be replaced in Appearance module
	-- if Appearance module does not exist, other addons should not break by calling this
end

function Chinchilla:AddTrackingDotStyle()
	-- blank method, to be replaced in TrackingDots module
	-- if TrackingDots module does not exist, other addons should not break by calling this
end

function Chinchilla:CallMethodOnAllModules(method, ...)
	for name, module in self:IterateModules() do
		if type(module[method]) == "function" then
			module[method](module, ...)
		end
	end
end

function Chinchilla:SetCVar(key, value)
	if key == "rotateMinimap" then
		self:CallMethodOnAllModules("OnRotateMinimapUpdate", value == "1")
	end
end

function Chinchilla:Minimap_OnMouseUp(this, button, ...)
	if button == self.db.profile.mouseButton then
		AceConfigDialog:Open("Chinchilla")
	elseif button == self.db.profile.trackButton then
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", -10, -20)
		PlaySound("igMainMenuOptionCheckBoxOn")
	else
		return self.hooks[this].OnMouseUp(this, button, ...)
	end
end


local options
function Chinchilla:OpenConfig()
	options = {
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

					for name, module in Chinchilla:IterateModules(false) do
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
				get = function()
					return GetCVar("rotateMinimap") == "1"
				end,
				set = function(_, value)
					SetCVar("rotateMinimap", value and "1" or "0")
					Minimap_UpdateRotationSetting()
				end,
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
			trackButton = {
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
			},
			version = {
				name = L["Version: %s"]:format(Chinchilla.version),
				type = "description",
				order = 5,
			},
		},
	}

	for key, module in Chinchilla:IterateModules() do
		local t = module.GetOptions and module:GetOptions() or {}

		for option, args in pairs(t) do
			if not args.disabled then
				args.disabled = function() return not module:IsEnabled() end
			end
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

	Chinchilla.OpenConfig = nil -- delete it, no longer needed

	return options
end


function Chinchilla:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Chinchilla2DB", { profile = { mouseButton = "RightButton", trackButton = "MiddleButton" }}, 'Default')

	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdate")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdate")
end

function Chinchilla:OnEnable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Chinchilla", Chinchilla.OpenConfig)
	AceConfigDialog:AddToBlizOptions("Chinchilla", L["Chinchilla Minimap"])
	AceConfigDialog:SetDefaultSize("Chinchilla", 800, 500)

	_G["SLASH_CHINCHILLA1"] = "/chinchilla"
	_G["SLASH_CHINCHILLA2"] = "/chin"

	_G.hash_SlashCmdList["CHINCHILLA"] = nil
	_G.SlashCmdList["CHINCHILLA"] = function() AceConfigDialog:Open("Chinchilla") end

	MinimapCluster:EnableMouse(false)
	MinimapBorderTop:Hide()
	MinimapZoneTextButton:Hide()

	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\Chinchilla\\Art\\UI-MiniMap-WorldMapSquare")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\Chinchilla\\Art\\UI-MiniMap-WorldMapSquare")

	self:RawHookScript(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:SecureHook("SetCVar")
end

function Chinchilla:OnDisable()
	MinimapCluster:EnableMouse(true)
	MinimapBorderTop:Show()
	MinimapZoneTextButton:Show()

	MiniMapWorldMapButton:SetNormalTexture("Interface\\Minimap\\UI-MiniMap-WorldMapSquare")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\Minimap\\UI-MiniMap-WorldMapSquare")

	self:RawHookScript(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:SecureHook("SetCVar")
end

function Chinchilla:OnProfileUpdate()
	for name, module in self:IterateModules() do
		module:Disable()

		if module.db.profile.enabled then
			module:Enable() -- simply reboot the module as I'm too lazy to add checks to everything
		end
	end
end
