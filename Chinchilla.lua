local VERSION = tonumber(("$Revision$"):match("%d+"))

Chinchilla = Rock:NewAddon("Chinchilla", "LibRockDB-1.0", "LibRockModuleCore-1.0", "LibRockHook-1.0", "LibRockConfig-1.0")
local Chinchilla, self = Chinchilla, Chinchilla
Chinchilla.version = "1.0r" .. VERSION
Chinchilla.revision = VERSION
Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

Chinchilla:SetDatabase("ChinchillaDB")
Chinchilla:SetDatabaseDefaults('profile', {
})

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla.options = {
	name = "Chinchilla",
	desc = L["Minimap addon of awesomeness. *chewing sound*. It'll nibble your hay pellets."],
	type = 'group',
	icon = [[Interface\AddOns\Chinchilla\icon]],
	args = {},
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
end

function Chinchilla:OnDisable()
	self:AddScriptHook(Minimap, "OnMouseUp", "Minimap_OnMouseUp")
end

function Chinchilla:Minimap_OnMouseUp(this, button, ...)
	if button == "RightButton" then
		self:OpenConfigMenu()
	else
		return self.hooks[this].OnMouseUp(this, button, ...)
	end
end
