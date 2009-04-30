--@debug@
LibStub("AceLocale-3.0"):NewLocale("Chinchilla", "enUS", true, true)
--@end-debug@
local L = LibStub("AceLocale-3.0"):GetLocale("Chinchilla")

Chinchilla = Rock:NewAddon("Chinchilla", "LibRockDB-1.0", "LibRockModuleCore-1.0", "LibRockHook-1.0", "LibRockConfig-1.0")
local Chinchilla, self = Chinchilla, Chinchilla
Chinchilla.L = L
Chinchilla.version = "@project-version@"
if Chinchilla.version:match("@") then
	Chinchilla.version = "Development"
end

Chinchilla:SetDatabase("ChinchillaDB")
Chinchilla:SetDatabaseDefaults('profile', {
	mouseButton = "RightButton"
})

local opts = {}
Chinchilla.options = {
	name = "Chinchilla",
	desc = L["Minimap addon of awesomeness. *chewing sound*. It'll nibble your hay pellets."],
	type = 'group',
	icon = [[Interface\AddOns\Chinchilla\icon]],
	args = function()
		local args = {
			lock = {
				name = L["Lock"],
				desc = L["Lock any draggable items regarding the minimap, so they can't be dragged mistakenly."],
				type = 'boolean',
				get = function()
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
						return "HALF"
					end
				end,
				set = function(value)
					Chinchilla:CallMethodOnAllModules(false, "SetLocked", value)
				end
			},
			rotateMinimap = {
				name = _G.ROTATE_MINIMAP,
				desc = _G.OPTION_TOOLTIP_ROTATE_MINIMAP,
				type = 'boolean',
				get = function()
					return GetCVar("rotateMinimap") == "1"
				end,
				set = function(value)
					SetCVar("rotateMinimap", value and "1" or "0")
				end,
			},
			mouseButton = {
				name = L["Preferences button"],
				desc = L["Button to use on the minimap to open the preferences window.\nNote: you can always open with /chin"],
				type = 'choice',
				choices = {
					RightButton = L["Right mouse button"],
					MiddleButton = L["Middle mouse button"],
					Button4 = L["Mouse button #4"],
					Button5 = L["Mouse button #5"],
					None = L["None"],
				},
				choiceOrder = {
					"RightButton",
					"MiddleButton",
					"Button4",
					"Button5",
					"None",
				},
				get = function()
					return Chinchilla.db.profile.mouseButton
				end,
				set = function(value)
					Chinchilla.db.profile.mouseButton = value
				end,
			},
		}
		
		for module, func in pairs(opts) do
			local t = func()
			if not t.handler then
				t.handler = module
			end
			if t.args then
				t.args.active = {
					type = 'boolean',
					name = L["Enable"],
					desc = L["Enable this module"],
					get = "IsModuleActive",
					set = "ToggleModuleActive",
					handler = Chinchilla,
					passValue = module,
					order = 1,
				}
			end
			args[module.name] = t
		end
		
		return "@cache", args
	end,
}
Chinchilla:SetConfigTable(Chinchilla.options)
Chinchilla:SetConfigSlashCommand("/Chinchilla", "/Chin")

function Chinchilla.modulePrototype:AddChinchillaOption(data)
	assert(type(data) == "function")
	
	opts[self] = data
end

function Chinchilla:OnInitialize()
	self:AddScriptHook(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:AddSecureHook("SetCVar")
end

function Chinchilla:OnDisable()
	self:AddScriptHook(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
	self:AddSecureHook("SetCVar")
end

function Chinchilla:Minimap_OnMouseUp(this, button, ...)
	if button == self.db.profile.mouseButton then
		self:OpenConfigMenu()
	else
		return self.hooks[this].OnMouseUp(this, button, ...)
	end
end

function Chinchilla:SetCVar(key, value)
	if key == "rotateMinimap" then
		self:CallMethodOnAllModules(false, "OnRotateMinimapUpdate", value == "1")
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
