local VERSION = tonumber(("$Revision$"):match("%d+"))

local Chinchilla = Chinchilla
local Chinchilla_Appearance = Chinchilla:NewModule("Appearance", "LibRockEvent-1.0", "LibRockTimer-1.0")
local self = Chinchilla_Appearance
if Chinchilla.revision < VERSION then
	Chinchilla.version = "1.0r" .. VERSION
	Chinchilla.revision = VERSION
	Chinchilla.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")
end
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Chinchilla")

Chinchilla_Appearance.desc = L["Allow for a customized look of the minimap"]

function Chinchilla_Appearance:OnInitialize()
	self.db = Chinchilla:GetDatabaseNamespace("Appearance")
	Chinchilla:SetDatabaseNamespaceDefaults("Appearance", "profile", {
		scale = 1,
		alpha = 1,
		borderAlpha = 1,
		buttonBorderAlpha = 1,
		strata = "BACKGROUND",
		shape = "CORNER-BOTTOMLEFT",
	})
end

local cornerTextures = {}
function Chinchilla_Appearance:OnEnable()
	self:SetScale(nil)
	self:SetAlpha(nil)
	self:SetFrameStrata(nil)
	self:SetShape(nil)
	self:SetBorderAlpha(nil)
	self:SetButtonBorderAlpha(nil)
	
	MinimapBorder:Hide()
	for i,v in ipairs(cornerTextures) do
		v:Show()
	end
	
	self:AddEventListener("MINIMAP_UPDATE_ZOOM")
	self:AddEventListener("CVAR_UPDATE", "CVAR_UPDATE", 0.05)
	
	if IsMacClient() then --temporary hack to try and fix minimaps going black for Mac users. ~Ellipsis
		self:AddEventListener("DISPLAY_SIZE_CHANGED", "CVAR_UPDATE")
		self:AddEventListener("ZONE_CHANGED_NEW_AREA", "CVAR_UPDATE")
	end
end

function Chinchilla_Appearance:OnDisable()
	self:SetScale(nil)
	self:SetAlpha(nil)
	self:SetFrameStrata(nil)
	self:SetShape(nil)
	self:SetBorderAlpha(nil)
	self:SetButtonBorderAlpha(nil)
	
	MinimapBorder:Show()
	Minimap:SetMaskTexture([[Textures\MinimapMask]])
	
	for i,v in ipairs(cornerTextures) do
		v:Hide()
	end
	if Chinchilla:HasModule("MoveButtons") then
		Chinchilla:GetModule("MoveButtons"):Update()
	end
end

local indoors
function Chinchilla_Appearance:MINIMAP_UPDATE_ZOOM()
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	indoors = GetCVar("minimapZoom")+0 ~= Minimap:GetZoom()
	Minimap:SetZoom(zoom)
	
	self:SetAlpha(nil)
end

function Chinchilla_Appearance:CVAR_UPDATE()
	self:SetShape(nil)
	self:SetAlpha(nil)
end

function Chinchilla_Appearance:SetScale(value)
	if value then
		self.db.profile.scale = value
	else
		value = self.db.profile.scale
	end
	if not Chinchilla:IsModuleActive(self) then
		value = 1
	end
	
	MinimapCluster:SetScale(value)
end

function Chinchilla_Appearance:SetAlpha(value)
	if value then
		self.db.profile.alpha = value
	else
		value = self.db.profile.alpha
	end
	if not Chinchilla:IsModuleActive(self) or indoors then
		value = 1
	end
	
	MinimapCluster:SetAlpha(value)
end

function Chinchilla_Appearance:SetFrameStrata(value)
	if value then
		self.db.profile.strata = value
	else
		value = self.db.profile.strata
	end
	if not Chinchilla:IsModuleActive(self) then
		value = "BACKGROUND"
	end

	MinimapCluster:SetFrameStrata(value)
end

local shapeToMask = {
	["ROUND"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Round]],
	["SQUARE"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Square]],
	["CORNER-TOPLEFT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Corner-TopLeft]],
	["CORNER-TOPRIGHT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Corner-TopRight]],
	["CORNER-BOTTOMLEFT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Corner-BottomLeft]],
	["CORNER-BOTTOMRIGHT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Corner-BottomRight]],
	["SIDE-TOP"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Side-Top]],
	["SIDE-RIGHT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Side-Right]],
	["SIDE-BOTTOM"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Side-Bottom]],
	["SIDE-LEFT"] = [[Interface\AddOns\Chinchilla\Appearance\Mask-Side-Left]],
}

local tmp = {}
function Chinchilla_Appearance:SetShape(shape)
	if shape then
		self.db.profile.shape = shape
	else
		shape = self.db.profile.shape
	end
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	
	-- topleft round?
	tmp[1] = shape == "ROUND" or shape == "CORNER-TOPLEFT" or shape == "SIDE-LEFT" or shape == "SIDE-TOP"
	-- topright round?
	tmp[2] = shape == "ROUND" or shape == "CORNER-TOPRIGHT" or shape == "SIDE-RIGHT" or shape == "SIDE-TOP"
	-- bottomleft round?
	tmp[3] = shape == "ROUND" or shape == "CORNER-BOTTOMLEFT" or shape == "SIDE-LEFT" or shape == "SIDE-BOTTOM"
	-- bottomright round?
	tmp[4] = shape == "ROUND" or shape == "CORNER-BOTTOMRIGHT" or shape == "SIDE-RIGHT" or shape == "SIDE-BOTTOM"
	
	if not cornerTextures[1] then
		for i = 1, 4 do
			local tex = MinimapBackdrop:CreateTexture("Chinchilla_Appearance_MinimapCorner" .. i, "ARTWORK")
			cornerTextures[i] = tex
			cornerTextures[i]:SetWidth(72)
			cornerTextures[i]:SetHeight(72)
		end
		
		cornerTextures[1]:SetPoint("BOTTOMRIGHT", Minimap, "CENTER")
		cornerTextures[1]:SetTexCoord(0, 0.5, 0, 0.5)
		
		cornerTextures[2]:SetPoint("BOTTOMLEFT", Minimap, "CENTER")
		cornerTextures[2]:SetTexCoord(0.5, 1, 0, 0.5)
		
		cornerTextures[3]:SetPoint("TOPRIGHT", Minimap, "CENTER")
		cornerTextures[3]:SetTexCoord(0, 0.5, 0.5, 1)
		
		cornerTextures[4]:SetPoint("TOPLEFT", Minimap, "CENTER")
		cornerTextures[4]:SetTexCoord(0.5, 1, 0.5, 1)
	end
	
	for i,v in ipairs(cornerTextures) do
		v:SetTexture(tmp[i] and [[Interface\AddOns\Chinchilla\Appearance\Border-Blizzard-Round]] or [[Interface\AddOns\Chinchilla\Appearance\Border-Blizzard-Square]])
	end
	
	Minimap:SetMaskTexture(shapeToMask[shape])
	
	if Chinchilla:HasModule("MoveButtons") then
		Chinchilla:GetModule("MoveButtons"):Update()
	end
end

function Chinchilla_Appearance:SetBorderAlpha(alpha)
	if alpha then
		self.db.profile.borderAlpha = alpha
	else
		alpha = self.db.profile.borderAlpha
	end
	if not Chinchilla:IsModuleActive(self) then
		return
	end
	
	for i,v in ipairs(cornerTextures) do
		v:SetAlpha(alpha)
	end
end

local buttonBorderTextures = {
	MiniMapBattlefieldBorder,
	MiniMapWorldBorder,
	MiniMapMailBorder,
	MiniMapMeetingStoneBorder,
--	GameTimeFrame,
	MiniMapTrackingBorder,
	MiniMapVoiceChatFrameBorder,
--	MinimapZoomIn,
--	MinimapZoomOut
}
function Chinchilla_Appearance:SetButtonBorderAlpha(alpha)
	if alpha then
		self.db.profile.buttonBorderAlpha = alpha
	else
		alpha = self.db.profile.buttonBorderAlpha
	end
	if not Chinchilla:IsModuleActive(self) then
		alpha = 1
	end
	
	for i,v in ipairs(buttonBorderTextures) do
		v:SetAlpha(alpha)
	end
end

Chinchilla_Appearance:AddChinchillaOption({
	name = L["Appearance"],
	desc = Chinchilla_Appearance.desc,
	type = 'group',
	args = {
		scale = {
			name = L["Size"],
			desc = L["Set how large the minimap is"],
			type = 'number',
			min = 0.25,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.scale
			end,
			set = "SetScale",
			isPercent = true,
		},
		alpha = {
			name = L["Opacity"],
			desc = L["Set how transparent or opaque the minimap is"],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.alpha
			end,
			set = "SetAlpha",
			isPercent = true,
		},
		strata = {
			name = L["Strata"],
			desc = L["Set which layer the minimap is layed on in relation to others in your interface."],
			type = 'choice',
			choices = {
				BACKGROUND = L["Background"],
				LOW = L["Low"],
				MEDIUM = L["Medium"],
				HIGH = L["High"],
				DIALOG = L["Dialog"],
				FULLSCREEN = L["Fullscreen"],
				FULLSCREEN_DIALOG = L["Fullscreen-dialog"],
				TOOLTIP = L["Tooltip"]
			},
			choiceOrder = {
				"BACKGROUND",
				"LOW",
				"MEDIUM",
				"HIGH",
				"DIALOG",
				"FULLSCREEN",
				"FULLSCREEN_DIALOG",
				"TOOLTIP"
			},
			get = function()
				return Chinchilla_Appearance.db.profile.strata
			end,
			set = "SetFrameStrata",
		},
		shape = {
			name = L["Shape"],
			desc = L["Set the shape of the minimap."],
			type = 'choice',
			choices = {
				["ROUND"] = L["Round"],
				["SQUARE"] = L["Square"],
				["CORNER-TOPRIGHT"] = L["Corner, top-right rounded"],
				["CORNER-TOPLEFT"] = L["Corner, top-left rounded"],
				["CORNER-BOTTOMRIGHT"] = L["Corner, bottom-right rounded"],
				["CORNER-BOTTOMLEFT"] = L["Corner, bottom-left rounded"],
				["SIDE-TOP"] = L["Side, top rounded"],
				["SIDE-RIGHT"] = L["Side, right rounded"],
				["SIDE-BOTTOM"] = L["Side, bottom rounded"],
				["SIDE-LEFT"] = L["Side, left rounded"],
			},
			get = function()
				return Chinchilla_Appearance.db.profile.shape
			end,
			set = "SetShape",
		},
		borderAlpha = {
			name = L["Border opacity"],
			desc = L["Set how transparent or opaque the minimap border is."],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.borderAlpha
			end,
			set = "SetBorderAlpha",
			isPercent = true,
		},
		buttonBorderAlpha = {
			name = L["Button border opacity"],
			desc = L["Set how transparent or opaque the minimap button borders are."],
			type = 'number',
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			get = function()
				return Chinchilla_Appearance.db.profile.buttonBorderAlpha
			end,
			set = "SetButtonBorderAlpha",
			isPercent = true,
		}
	}
})

function _G.GetMinimapShape()
	if Chinchilla:IsModuleActive(self) then
		return self.db.profile.shape
	else
		return "ROUND"
	end
end
