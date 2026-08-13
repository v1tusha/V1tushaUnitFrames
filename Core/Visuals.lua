local _, VUF = ...

local LSM = LibStub("LibSharedMedia-3.0")

local MEDIA_PATH = [[Interface\AddOns\V1tushaUnitFrames\Media\]]

LSM:Register("statusbar", "V1tusha BetterBlizzard", MEDIA_PATH .. "Textures\\BetterBlizzard.blp")
LSM:Register("statusbar", "V1tusha Dragonflight",   MEDIA_PATH .. "Textures\\Dragonflight.tga")
LSM:Register("statusbar", "V1tusha Skyline",        MEDIA_PATH .. "Textures\\Skyline.tga")
LSM:Register("statusbar", "V1tusha Stripes",        MEDIA_PATH .. "Textures\\Stripes.png")
LSM:Register("statusbar", "V1tusha ThinStripes",    MEDIA_PATH .. "Textures\\ThinStripes.png")
LSM:Register("statusbar", "V1tusha Gradient",       MEDIA_PATH .. "Textures\\Gradient.png")
for i = 1, 5 do
    LSM:Register("statusbar", "V1tusha HND Gradient " .. i, MEDIA_PATH .. "Textures\\hnd_gradient" .. i .. ".tga")
    LSM:Register("statusbar", "V1tusha HND Gradient " .. i .. " Line", MEDIA_PATH .. "Textures\\hnd_gradient" .. i .. "_line.tga")
end

VUF.BAR_TEXTURES = {
    ["V1tusha BetterBlizzard"] = "BetterBlizzard",
    ["V1tusha Dragonflight"] = "Dragonflight",
    ["V1tusha Skyline"] = "Skyline",
    ["V1tusha Stripes"] = "Stripes",
    ["V1tusha ThinStripes"] = "ThinStripes",
    ["V1tusha Gradient"] = "Gradient",
    ["V1tusha HND Gradient 1"] = "HND Gradient 1",
    ["V1tusha HND Gradient 1 Line"] = "HND Gradient 1 Line",
    ["V1tusha HND Gradient 2"] = "HND Gradient 2",
    ["V1tusha HND Gradient 2 Line"] = "HND Gradient 2 Line",
    ["V1tusha HND Gradient 3"] = "HND Gradient 3",
    ["V1tusha HND Gradient 3 Line"] = "HND Gradient 3 Line",
    ["V1tusha HND Gradient 4"] = "HND Gradient 4",
    ["V1tusha HND Gradient 4 Line"] = "HND Gradient 4 Line",
    ["V1tusha HND Gradient 5"] = "HND Gradient 5",
    ["V1tusha HND Gradient 5 Line"] = "HND Gradient 5 Line",
}

LSM:Register("font", "V1tusha Expressway", MEDIA_PATH .. "Fonts\\Expressway.ttf")
LSM:Register("font", "V1tusha Avante",     MEDIA_PATH .. "Fonts\\Avante.ttf")

local DEFAULTS = {
    texture            = "V1tusha Skyline",
    font               = "V1tusha Expressway",
    fontSize           = 12,
    fontOutline        = "OUTLINE",
    healthFormat       = "full",
    borderSize         = 1,
    borderColor        = { 0, 0, 0, 1 },
    backgroundColor    = { 0.06, 0.07, 0.09, 1 },
    backgroundAlpha    = 0.9,
}

local POWER_COLORS = {
    [0]  = { 0,    0,    1    },  -- Mana
    [1]  = { 1,    0,    0    },  -- Rage
    [2]  = { 1,    0.5,  0.25 },  -- Focus
    [3]  = { 1,    1,    0    },  -- Energy
    [6]  = { 0,    0.82, 1    },  -- Runic Power
    [8]  = { 0.75, 0.52, 0.9  },  -- Lunar/Astral Power
    [11] = { 0,    0.5,  1    },  -- Maelstrom
    [13] = { 0.4,  0,    0.8  },  -- Insanity
    [17] = { 0.79, 0.26, 0.99 },  -- Fury
    [18] = { 1,    0.61, 0    },  -- Pain
}

local SECONDARY_POWER_COLORS = {
    [4]  = { 1,    0.96, 0.41 },  -- Combo Points
    [5]  = { 0.5,  0.5,  0.5  },  -- Runes
    [7]  = { 0.58, 0.51, 0.79 },  -- Soul Shards
    [9]  = { 0.95, 0.9,  0.6  },  -- Holy Power
    [12] = { 0.71, 1,    0.92 },  -- Chi
    [16] = { 0.41, 0.8,  0.94 },  -- Arcane Charges
    [19] = { 100/255, 173/255, 206/255 }, -- Essence
    -- oUF's fake power types: string keys, deliberately no numeric id (colors.lua).
    TIP_OF_THE_SPEAR = { 108/255, 188/255, 40/255  },  -- Survival Hunter
    ICICLES          = { 116/255, 217/255, 246/255 },  -- Frost Mage
}

-- oUF resolves power colours by token (colors.power.MANA), not by numeric id, so custom
-- colours have to be written to the token or nothing changes. Fakes are their own token.
local POWER_TOKENS = {
    [0]  = "MANA",        [1]  = "RAGE",        [2]  = "FOCUS",       [3]  = "ENERGY",
    [4]  = "COMBO_POINTS",[5]  = "RUNES",       [6]  = "RUNIC_POWER", [7]  = "SOUL_SHARDS",
    [8]  = "LUNAR_POWER", [9]  = "HOLY_POWER",  [11] = "MAELSTROM",   [12] = "CHI",
    [13] = "INSANITY",    [16] = "ARCANE_CHARGES", [17] = "FURY",     [18] = "PAIN",
    [19] = "ESSENCE",
}

local REACTION_COLORS = {
    [1] = { 204/255, 64/255,  64/255  },  -- Hated
    [2] = { 204/255, 64/255,  64/255  },  -- Hostile
    [3] = { 204/255, 128/255, 64/255 },  -- Unfriendly
    [4] = { 204/255, 204/255, 64/255 },  -- Neutral
    [5] = { 64/255,  204/255, 64/255 },  -- Friendly
    [6] = { 64/255,  204/255, 64/255 },  -- Honored
    [7] = { 64/255,  204/255, 64/255 },  -- Revered
    [8] = { 64/255,  204/255, 64/255 },  -- Exalted
}

local DISPEL_COLORS = {
    Magic   = { 0.2,  0.6,  1    },
    Curse   = { 0.6,  0,    1    },
    Disease = { 0.6,  0.4,  0    },
    Poison  = { 0,    0.6,  0    },
    Bleed   = { 0.6,  0,    0.1  },
}

local POWER_NAMES = {
    [0]  = "Mana",
    [1]  = "Rage",
    [2]  = "Focus",
    [3]  = "Energy",
    [4]  = "Combo Points",
    [5]  = "Runes",
    [6]  = "Runic Power",
    [7]  = "Soul Shards",
    [8]  = "Astral Power",
    [9]  = "Holy Power",
    [11] = "Maelstrom",
    [12] = "Chi",
    [13] = "Insanity",
    [16] = "Arcane Charges",
    [17] = "Fury",
    [18] = "Pain",
    [19] = "Essence",
    TIP_OF_THE_SPEAR = "Tip of the Spear",
    ICICLES = "Icicles",
}

local REACTION_NAMES = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

VUF.POWER_NAMES = POWER_NAMES
VUF.REACTION_NAMES = REACTION_NAMES

local HEALTH_FORMATS = {
    full    = "[curhp] / [maxhp] ([perhp]%)",
    compact = "[curhp] ([perhp]%)",
    percent = "[perhp]%",
    hidden  = "",
}

local POWER_FORMATS = {
    full    = "[curpp] / [maxpp] ([perpp]%)",
    compact = "[curpp] ([perpp]%)",
    percent = "[perpp]%",
    hidden  = "",
}

local function ensureVisuals()
    local profile = VUF:GetProfileData()
    profile.visuals = profile.visuals or {}
    return profile.visuals
end

function VUF:GetVisual(key)
    local v = ensureVisuals()
    if v[key] == nil then return DEFAULTS[key] end
    return v[key]
end

function VUF:SetVisual(key, val)
    ensureVisuals()[key] = val
end

function VUF:GetTexturePath()
    return LSM:Fetch("statusbar", VUF:GetVisual("texture")) or LSM:Fetch("statusbar", DEFAULTS.texture)
end

local function ensureColours()
    local profile = VUF:GetProfileData()
    profile.general = profile.general or {}
    profile.general.Colours = profile.general.Colours or {}
    profile.general.Colours.Power = profile.general.Colours.Power or {}
    profile.general.Colours.SecondaryPower = profile.general.Colours.SecondaryPower or {}
    profile.general.Colours.Reaction = profile.general.Colours.Reaction or {}
    profile.general.Colours.Dispel = profile.general.Colours.Dispel or {}
    -- Backfill colours added after a profile was first written (or dropped by an
    -- imported profile): otherwise the config tab has no row for them and they can
    -- never be recoloured, and readers that index a colour directly nil-error.
    local function backfill(dest, src)
        for key, color in pairs(src) do
            if not dest[key] then dest[key] = { color[1], color[2], color[3] } end
        end
    end
    backfill(profile.general.Colours.Power, POWER_COLORS)
    backfill(profile.general.Colours.SecondaryPower, SECONDARY_POWER_COLORS)
    backfill(profile.general.Colours.Reaction, REACTION_COLORS)
    backfill(profile.general.Colours.Dispel, DISPEL_COLORS)
    return profile.general.Colours
end

function VUF:GetColours()
    return ensureColours()
end

function VUF:ResetColours()
    local profile = VUF:GetProfileData()
    profile.general = profile.general or {}
    profile.general.Colours = {
        Power = {},
        SecondaryPower = {},
        Reaction = {},
        Dispel = {},
    }

    for powerType, color in pairs(POWER_COLORS) do
        profile.general.Colours.Power[powerType] = { color[1], color[2], color[3] }
    end
    for powerType, color in pairs(SECONDARY_POWER_COLORS) do
        profile.general.Colours.SecondaryPower[powerType] = { color[1], color[2], color[3] }
    end
    for reaction, color in pairs(REACTION_COLORS) do
        profile.general.Colours.Reaction[reaction] = { color[1], color[2], color[3] }
    end
    for dispelType, color in pairs(DISPEL_COLORS) do
        profile.general.Colours.Dispel[dispelType] = { color[1], color[2], color[3] }
    end

    VUF:LoadCustomColours()
end

function VUF:GetUIScale()
    local profile = VUF:GetProfileData()
    profile.general = profile.general or {}
    profile.general.UIScale = profile.general.UIScale or { Enabled = false, Scale = 1 }
    return profile.general.UIScale
end

function VUF:GetPixelPerfectScale()
    local _, height = GetPhysicalScreenSize()
    return 768 / height
end

function VUF:SetUIScale()
    local settings = VUF:GetUIScale()

    -- Remember Blizzard's own scale before we ever override it, so disabling restores it.
    if VUF.blizzardUIScale == nil then VUF.blizzardUIScale = UIParent:GetScale() end

    if not settings.Enabled then
        -- Never force scale 1 here: that would override WoW's resolution-based default.
        if VUF.uiScaleOverridden then
            UIParent:SetScale(VUF.blizzardUIScale)
            VUF.uiScaleOverridden = nil
        end
        return
    end

    local value = settings.Scale
    VUF.uiScaleOverridden = true
    UIParent:SetScale(value)
    -- Blizzard may recalculate UIParent after frame-position updates; re-apply next frame.
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local current = VUF:GetUIScale()
            if current.Enabled and current.Scale == value then UIParent:SetScale(value) end
        end)
    end
end

function VUF:LoadCustomColours()
    local oUF = VUF.oUF
    if not oUF or not oUF.colors then return end

    local colours = ensureColours()

    -- powerType is either a numeric id or, for oUF's fake powers, the token itself.
    local function applyPower(powerType, color)
        local name = POWER_NAMES[powerType]
        if not name then return end
        local c = oUF:CreateColor(color[1], color[2], color[3])
        oUF.colors.power[name] = c
        oUF.colors.power[powerType] = c
        local token = POWER_TOKENS[powerType] or (type(powerType) == "string" and powerType)
        if token then oUF.colors.power[token] = c end
    end

    for powerType, color in pairs(colours.Power) do
        applyPower(powerType, color)
    end

    for powerType, color in pairs(colours.SecondaryPower) do
        applyPower(powerType, color)
    end

    for reaction, color in pairs(colours.Reaction) do
        oUF.colors.reaction[reaction] = oUF:CreateColor(color[1], color[2], color[3])
    end

    if colours.Dispel then
        local dispelMap = {
            Magic = oUF.Enum and oUF.Enum.DispelType and oUF.Enum.DispelType.Magic,
            Curse = oUF.Enum and oUF.Enum.DispelType and oUF.Enum.DispelType.Curse,
            Disease = oUF.Enum and oUF.Enum.DispelType and oUF.Enum.DispelType.Disease,
            Poison = oUF.Enum and oUF.Enum.DispelType and oUF.Enum.DispelType.Poison,
            Bleed = oUF.Enum and oUF.Enum.DispelType and oUF.Enum.DispelType.Bleed,
        }
        for dispelType, index in pairs(dispelMap) do
            local color = colours.Dispel[dispelType]
            if color and index then
                oUF.colors.dispel[index] = oUF:CreateColor(color[1], color[2], color[3])
            end
        end
    end

    for _, obj in next, oUF.objects do
        if obj.UpdateAllElements then obj:UpdateAllElements("CUSTOM_COLORS") end
        if obj.RefreshDispelColors then obj:RefreshDispelColors() end
    end
end

function VUF:GetFontPath()
    return LSM:Fetch("font", VUF:GetVisual("font")) or LSM:Fetch("font", DEFAULTS.font)
end

function VUF:ApplyFont(fs, size)
    local path = VUF:GetFontPath()
    local fontSize = size or VUF:GetVisual("fontSize")
    local outline = VUF:GetVisual("fontOutline")
    if path and fontSize then fs:SetFont(path, fontSize, outline == "NONE" and "" or outline) end
    fs:SetShadowOffset(1, -1)
end

function VUF:CreateBorder(frame)
    local edges = {}
    frame.Border = edges

    for _, edge in ipairs({
        { "TOPLEFT", "TOPRIGHT", "h" },
        { "BOTTOMLEFT", "BOTTOMRIGHT", "h" },
        { "TOPLEFT", "BOTTOMLEFT", "v" },
        { "TOPRIGHT", "BOTTOMRIGHT", "v" },
    }) do
        local t = frame:CreateTexture(nil, "BORDER")
        edges[#edges + 1] = { texture = t, a1 = edge[1], a2 = edge[2], dim = edge[3] }
    end

    VUF:ApplyBorder(frame)
end

function VUF:ApplyBorder(frame)
    if not frame.Border then return end

    local size = VUF:GetVisual("borderSize")
    local color = VUF:GetVisual("borderColor")
    for _, edge in ipairs(frame.Border) do
        local t, a1, a2 = edge.texture, edge.a1, edge.a2
        t:ClearAllPoints()
        t:SetColorTexture(color[1], color[2], color[3], color[4])
        t:SetShown(size > 0)
        if edge.dim == "h" then
            t:SetHeight(size)
            t:SetPoint(a1, frame, a1, -size, a1 == "TOPLEFT" and size or -size)
            t:SetPoint(a2, frame, a2, size, a2 == "TOPRIGHT" and size or -size)
        else
            t:SetWidth(size)
            t:SetPoint(a1, frame, a1, a1 == "TOPLEFT" and -size or size, size)
            t:SetPoint(a2, frame, a2, a2 == "BOTTOMLEFT" and -size or size, -size)
        end
    end
end

local function applyBarTexture(bar, texture, background, alpha)
    if not bar then return end
    bar:SetStatusBarTexture(texture)
    if bar.bg then
        bar.bg:SetTexture(texture)
        bar.bg:SetVertexColor(background[1], background[2], background[3], background[4] or 1)
        bar.bg:SetAlpha(alpha)
    end
end

function VUF:ApplyVisuals()
    if InCombatLockdown() then
        VUF.pendingProfileRefresh = true
        print("|cFF8080FFV1tushaUnitFrames|r: appearance changes apply after combat.")
        return
    end

    local texture = VUF:GetTexturePath()
    local background = VUF:GetVisual("backgroundColor")
    local alpha = VUF:GetVisual("backgroundAlpha")

    for _, frame in pairs(VUF.frames or {}) do
        VUF:ApplyBorder(frame)
        applyBarTexture(frame.Health, texture, background, alpha)
        applyBarTexture(frame.Power, texture, background, alpha)
        applyBarTexture(frame.Castbar, texture, background, alpha)
        applyBarTexture(frame.AdditionalPower, texture, background, alpha)
        applyBarTexture(frame.View, texture, background, alpha)
        if frame.ClassPower then
            for i = 1, #frame.ClassPower do
                applyBarTexture(frame.ClassPower[i], texture, background, alpha)
            end
        end

        for _, text in pairs({ frame.Castbar and frame.Castbar.Text, frame.Castbar and frame.Castbar.Time }) do
            if text then VUF:ApplyFont(text) end
        end
    end

    for unit in pairs(VUF.frames or {}) do VUF:ApplyUnitText(unit) end
end

VUF.LSM = LSM
VUF.HEALTH_FORMATS = HEALTH_FORMATS
VUF.POWER_FORMATS = POWER_FORMATS
