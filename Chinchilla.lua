--@debug@
LibStub("AceLocale-3.0"):NewLocale("Chinchilla", "enUS", true, true)
--@end-debug@
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Chinchilla = LibStub("AceAddon-3.0"):NewAddon("Chinchilla", "AceHook-3.0")
local Chinchilla, self = Chinchilla, Chinchilla
Chinchilla.L = L
Chinchilla.version = "@project-version@"
if Chinchilla.version:match("@") then
	Chinchilla.version = "Development"
end

local opts = {}
local module = {}
function module:AddChinchillaOption(data)
	assert(type(data) == "function")
	
	opts[self] = data
end
Chinchilla:SetDefaultModulePrototype(module)

function Chinchilla:OnInitialize()
	local db = LibStub("AceDB-3.0"):New("Chinchilla2DB", {
		profile = {
			mouseButton = "RightButton"
		}
	}, 'Default')
	self.db = db
end

function Chinchilla:OnEnable()
	self:RawHookScript(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:SecureHook("SetCVar")
end

function Chinchilla:OnDisable()
	self:RawHookScript(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:SecureHook("SetCVar")
end

function Chinchilla:Minimap_OnMouseUp(this, button, ...)
	if button == self.db.profile.mouseButton then
		self:OpenConfig()
	else
		return self.hooks[this].OnMouseUp(this, button, ...)
	end
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

function Chinchilla:AddBorderStyle()
	-- blank method, to be replaced in Appearance module
	-- if Appearance module does not exist, other addons should not break by calling this
end

function Chinchilla:AddTrackingDotStyle()
	-- blank method, to be replaced in TrackingDots module
	-- if Blips module does not exist, other addons should not break by calling this
end

local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
if not AceConfig then
	LoadAddOn("Ace3")
	AceConfig = LibStub and LibStub("AceConfig-3.0", true)
	if not LibSimpleOptions then
		message(("Chinchilla requires the library %q and will not work without it."):format("AceConfig-3.0"))
		error(("Chinchilla requires the library %q and will not work without it."):format("AceConfig-3.0"))
	end
end
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

AceConfig:RegisterOptionsTable("Chinchilla_Bliz", {
	name = L["Chinchilla Minimap"],
	handler = Chinchilla,
	type = 'group',
	args = {
		config = {
			name = L["Standalone config"],
			desc = L["Open a standlone config window, allowing you to actually configure Chinchilla Minimap."],
			type = 'execute',
			func = function()
				Chinchilla:OpenConfig()
			end
		}
	},
})
AceConfigDialog:AddToBlizOptions("Chinchilla_Bliz", L["Chinchilla Minimap"])

do
	for i, cmd in ipairs { "/Chinchilla", "/Chin" } do
		_G["SLASH_CHINCHILLA" .. (i*2 - 1)] = cmd
		_G["SLASH_CHINCHILLA" .. (i*2)] = cmd:lower()
	end

	_G.hash_SlashCmdList["CHINCHILLA"] = nil
	_G.SlashCmdList["CHINCHILLA"] = function()
		return Chinchilla:OpenConfig()
	end
end

function Chinchilla:OpenConfig()
	-- redefine it so that we just open up the pane next time
	function self:OpenConfig()
		AceConfigDialog:Open("Chinchilla")
	end
	
	local options = {
		name = L["Chinchilla Minimap"],
		desc = L["Minimap addon of awesomeness. *chewing sound*. It'll nibble your hay pellets."],
		type = 'group',
		icon = [[Interface\AddOns\Chinchilla\icon]],
		args = {
			lock = {
				name = L["Lock"],
				desc = L["Lock any draggable items regarding the minimap, so they can't be dragged mistakenly."],
				type = 'toggle',
				tristate = true,
				get = function(info)
					local current = 0
					local max = 0
					for name, module in Chinchilla:IterateModules(false) do
						if type(module.IsLocked) == "function" then
							local locked = module:IsLocked()
							max = max + 1
							if locked then
								if locked == "HALF" then
									current = current + 0.5
								else
									current = current + 1
								end
							end
						end
					end
					if current == 0 then
						return false
					elseif current == max then
						return true
					else
						return nil
					end
				end,
				set = function(info, value)
					Chinchilla:CallMethodOnAllModules("SetLocked", not not value)
				end
			},
			rotateMinimap = {
				name = _G.ROTATE_MINIMAP,
				desc = _G.OPTION_TOOLTIP_ROTATE_MINIMAP,
				type = 'toggle',
				get = function(info)
					return GetCVar("rotateMinimap") == "1"
				end,
				set = function(info, value)
					SetCVar("rotateMinimap", value and "1" or "0")
				end,
			},
			mouseButton = {
				name = L["Preferences button"],
				desc = L["Button to use on the minimap to open the preferences window.\nNote: you can always open with /chin"],
				type = 'select',
				values = {
					RightButton = L["Right mouse button"],
					MiddleButton = L["Middle mouse button"],
					Button4 = L["Mouse button #4"],
					Button5 = L["Mouse button #5"],
					None = L["None"],
				},
				get = function(info)
					return Chinchilla.db.profile.mouseButton
				end,
				set = function(info, value)
					Chinchilla.db.profile.mouseButton = value
				end,
			},
			version = {
				name = L["Version: %s"]:format(Chinchilla.version),
				type = 'description',
				order = -1,
				width = 'normal',
			}
		}
	}
		
	for module, func in pairs(opts) do
		local t = func()
		if not t.handler then
			t.handler = module
		end
		if t.args then
			t.args.active = {
				type = 'toggle',
				name = L["Enable"],
				desc = L["Enable this module"],
				get = function(info)
					return module:IsEnabled()
				end,
				set = function(info, value)
					module.db.profile.enabled = not not value
					if value then
						return module:Enable()
					else
						return module:Disable()
					end
				end,
				order = 1,
				width = "full",
			}
		end
		options.args[module.name] = t
	end
	opts = nil
	
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	options.args.profile.order = -1
	
	AceConfig:RegisterOptionsTable("Chinchilla", options)
	AceConfigDialog:SetDefaultSize("Chinchilla", 835, 550)
	
	return self:OpenConfig()
end
