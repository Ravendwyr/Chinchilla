local Chinchilla = Chinchilla
Chinchilla:ProvideVersion("$Revision$", "$Date$")
Chinchilla:SetModuleDefaultState("RangeCircle", false)
local Chinchilla_RangeCircle = Chinchilla:NewModule("RangeCircle", "LibRockEvent-1.0", "LibRockHook-1.0")
local self = Chinchilla_RangeCircle
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_RangeCircle.desc = L["Show a circle on the minimap at a prefered range"]

local newDict, unpackDictAndDel = Rock:GetRecyclingFunctions("Chinchilla", "newDict", "unpackDictAndDel")


function Chinchilla_RangeCircle:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("RangeCircle")
	Chinchilla:SetDatabaseNamespaceDefaults("RangeCircle", "profile", {
		range = 90,
		color = { 1, 0.82, 0, 0.5 },
		style = "Solid",
	})
end

local styles = {
	Solid = {
		L["Solid"],
		[[Interface\AddOns\Chinchilla\RangeCircle\Solid]],
	},
	Outline = {
		L["Outline"],
		[[Interface\AddOns\Chinchilla\RangeCircle\Outline]],
	}
}

local minimapSize = { -- radius of minimap
	indoor = {
		[0] = 150,
		[1] = 120,
		[2] = 90,
		[3] = 60,
		[4] = 40,
		[5] = 25,
	},
	outdoor = {
		[0] = 233 + 1/3,
		[1] = 200,
		[2] = 166 + 2/3,
		[3] = 133 + 1/6,
		[4] = 100,
		[5] = 66 + 2/3,
	},
}

local texture
local indoors
function Chinchilla_RangeCircle:OnEnable()
	if not texture then
		texture = Minimap:CreateTexture("Chinchilla_RangeCircle_Circle", "OVERLAY")
		local style = styles[self.db.profile.style] or styles.Solid
		local tex = style and style[2] or [[Interface\AddOns\Chinchilla\RangeCircle\Solid]]
		texture:SetTexture(tex)
		texture:SetPoint("CENTER")
		texture:SetVertexColor(unpack(self.db.profile.color))
	end
	texture:Show()
	
	self:AddEventListener("MINIMAP_UPDATE_ZOOM")
	self:Update()
	
	self:AddSecureHook(Minimap, "SetZoom", "Minimap_SetZoom")
end

function Chinchilla_RangeCircle:OnDisable()
	texture:Hide()
end

function Chinchilla_RangeCircle:MINIMAP_UPDATE_ZOOM()
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	indoors = GetCVar("minimapZoom")+0 ~= Minimap:GetZoom()
	Minimap:SetZoom(zoom)
	
	self:Update()
end

function Chinchilla_RangeCircle:Update()
	if not self:IsActive() then
		return
	end
	local radius = minimapSize[indoors and "indoor" or "outdoor"][Minimap:GetZoom()]
	local range = self.db.profile.range
	local minimapWidth = Minimap:GetWidth()
	local size = minimapWidth * range/radius
	if size > minimapWidth then
		local ratio = minimapWidth/size
		texture:SetTexCoord(0.5 - ratio/2, 0.5 + ratio/2, 0.5 - ratio/2, 0.5 + ratio/2)
		texture:SetWidth(minimapWidth)
		texture:SetHeight(minimapWidth)
	else
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetWidth(size)
		texture:SetHeight(size)
	end
end

function Chinchilla_RangeCircle:Minimap_SetZoom()
	self:Update()
end

Chinchilla_RangeCircle:AddChinchillaOption({
	name = L["Range circle"],
	desc = Chinchilla_RangeCircle.desc,
	type = 'group',
	args = {
		range = {
			type = 'number',
			name = L["Radius"],
			desc = L["The radius in yards of how large the radius of the circle should be"],
			min = 5,
			max = 250,
			step = 1,
			bigStep = 5,
			get = function()
				return self.db.profile.range
			end,
			set = function(value)
				self.db.profile.range = value
				self:Update()
			end
		},
		color = {
			type = 'color',
			name = L["Color"],
			desc = L["Color of the circle"],
			hasAlpha = true,
			get = function()
				return unpack(self.db.profile.color)
			end,
			set = function(r, g, b, a)
				local data = self.db.profile.color
				data[1] = r
				data[2] = g
				data[3] = b
				data[4] = a
				if texture then
					texture:SetVertexColor(r, g, b, a)
				end
			end
		},
		style = {
			type = 'choice',
			name = L["Style"],
			desc = L["What texture style to use for the circle"],
			choices = function()
				local t = newDict()
				for k,v in pairs(styles) do
					t[k] = v[1]
				end
				return "@dict", unpackDictAndDel(t)
			end,
			get = function()
				return self.db.profile.style
			end,
			set = function(value)
				self.db.profile.style = value
				if texture then
					local style = styles[value] or styles.Solid
					local tex = style and style[2] or [[Interface\AddOns\Chinchilla\RangeCircle\Solid]]
					texture:SetTexture(tex)
				end
			end
		}
	}
})