local VERSION = tonumber(("$Revision$"):match("%d+"))

Chinchilla = Rock:NewAddon("Chinchilla", "LibRockDB-1.0", "LibRockModuleCore-1.0", "LibRockHook-1.0", "LibRockConfig-1.0")
local Chinchilla, self = Chinchilla, Chinchilla
Chinchilla.version = "1.0r" .. VERSION
Chinchilla.revision = VERSION
Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

Chinchilla:SetDatabase("ChinchillaDB")
Chinchilla:SetDatabaseDefaults('profile', {
	mouseButton = "RightButton"
})

function Chinchilla:ProvideVersion(revision, date)
	revision = tonumber(revision:match("%d+"))
	if Chinchilla.revision < revision then
		Chinchilla.version = "1.0r" .. revision
		Chinchilla.revision = revision
		Chinchilla.date = date:match("%d%d%d%d%-%d%d%-%d%d")
	end
end

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla.options = {
	name = "Chinchilla",
	desc = L["Minimap addon of awesomeness. *chewing sound*. It'll nibble your hay pellets."],
	type = 'group',
	icon = [[Interface\AddOns\Chinchilla\icon]],
	args = {
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
	},
}
Chinchilla:SetConfigTable(Chinchilla.options)
Chinchilla:SetConfigSlashCommand("/Chinchilla", "/Chin")

function Chinchilla.modulePrototype:AddChinchillaOption(data)
	local args = Chinchilla.options.args
	local name = self.name
	if args[name] then
		local i = 2
		while args[name .. i] do
			i = i + 1
		end
		name = name .. i
	end
	args[name] = data
	if not data.handler then
		data.handler = self
	end
	if data.args then
		data.args.active = {
			type = 'boolean',
			name = L["Enable"],
			desc = L["Enable this module"],
			get = "IsModuleActive",
			set = "ToggleModuleActive",
			handler = Chinchilla,
			passValue = self,
			order = 1,
		}
	end
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

function Chinchilla:AddBlipStyle()
	-- blank method, to be replaced in Blips module
	-- if Blips module does not exist, other addons should not break by calling this
end
