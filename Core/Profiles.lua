local _, VUF = ...

local AceDB = LibStub("AceDB-3.0")
local Serializer = LibStub("AceSerializer-3.0")
local Deflate = LibStub("LibDeflate")

local DEFAULTS = {
    profile = {
        visuals = {},
        units = {},
        positions = {},
        general = {
            UIScale = {
                Enabled = false,
                Scale = 1,
            },
            CooldownText = {
                FontSize = 12,
                Breakpoints = {
                    { threshold = 0, style = "decimalSeconds", color = { 1, 1, 1, 1 } },
                    { threshold = 3, style = "secondsOnly", color = { 1, 1, 1, 1 } },
                    { threshold = 60, style = "clock", color = { 1, 1, 1, 1 } },
                    { threshold = 120, style = "minutes", color = { 1, 1, 1, 1 } },
                    { threshold = 3600, style = "hours", color = { 1, 1, 1, 1 } },
                },
            },
            Colours = {
                Power = {
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
                },
                SecondaryPower = {
                    [4]  = { 1,    0.96, 0.41 },  -- Combo Points
                    [5]  = { 0.5,  0.5,  0.5  },  -- Runes
                    [7]  = { 0.58, 0.51, 0.79 },  -- Soul Shards
                    [9]  = { 0.95, 0.9,  0.6  },  -- Holy Power
                    [12] = { 0.71, 1,    0.92 },  -- Chi
                    [16] = { 0.41, 0.8,  0.94 },  -- Arcane Charges
                    [19] = { 100/255, 173/255, 206/255 },  -- Essence
                },
                Reaction = {
                    [1] = { 204/255, 64/255,  64/255  },
                    [2] = { 204/255, 64/255,  64/255  },
                    [3] = { 204/255, 128/255, 64/255 },
                    [4] = { 204/255, 204/255, 64/255 },
                    [5] = { 64/255,  204/255, 64/255 },
                    [6] = { 64/255,  204/255, 64/255 },
                    [7] = { 64/255,  204/255, 64/255 },
                    [8] = { 64/255,  204/255, 64/255 },
                },
                Dispel = {
                    Magic   = { 0.2,  0.6,  1    },
                    Curse   = { 0.6,  0,    1    },
                    Disease = { 0.6,  0.4,  0    },
                    Poison  = { 0,    0.6,  0    },
                    Bleed   = { 0.6,  0,    0.1  },
                },
            },
        },
    },
    global = {
        vufSchema = 1,
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function VUF:GetProfileData()
    return VUF.db.profile
end

function VUF:InitializeProfiles()
    local legacy = _G.V1tushaUnitFramesDB
    local needsMigration = type(legacy) == "table" and not legacy.profiles and (
        type(legacy.visuals) == "table" or type(legacy.units) == "table" or type(legacy.positions) == "table"
    )

    VUF.db = AceDB:New("V1tushaUnitFramesDB", DEFAULTS)
    if needsMigration then
        VUF.db.profile.visuals = copy(legacy.visuals or {})
        VUF.db.profile.units = copy(legacy.units or {})
        VUF.db.profile.positions = copy(legacy.positions or {})
        VUF.db.global.vufMigratedLegacy = true
    end

    if not VUF.db.global.vufMigratedCharacterProfiles then
        local saved = VUF.db.sv
        local profiles = saved and saved.profiles
        local profileKeys = saved and saved.profileKeys
        local defaultProfile = profiles and profiles.Default
        if type(profiles) == "table" and type(profileKeys) == "table" and type(defaultProfile) == "table" then
            for character, profileName in pairs(profileKeys) do
                if profileName == "Default" then
                    local target = character
                    local suffix = 1
                    while profiles[target] do
                        target = character .. (suffix == 1 and " (Personal)" or " (" .. suffix .. ")")
                        suffix = suffix + 1
                    end
                    profiles[target] = copy(defaultProfile)
                    profileKeys[character] = target
                end
            end
        end
        VUF.db.global.vufMigratedCharacterProfiles = true
    end

    local currentProfile = VUF.db.sv.profileKeys[VUF.db.keys.char]
    if currentProfile and currentProfile ~= VUF.db.keys.profile then
        VUF.db:SetProfile(currentProfile)
    end
    VUF.db.RegisterCallback(VUF, "OnProfileChanged", function() VUF:SetUIScale() VUF:LoadCustomColours() VUF:QueueProfileRefresh() end)
    VUF.db.RegisterCallback(VUF, "OnProfileCopied", function() VUF:SetUIScale() VUF:QueueProfileRefresh() end)
    VUF.db.RegisterCallback(VUF, "OnProfileReset", function() VUF:SetUIScale() VUF:LoadCustomColours() VUF:QueueProfileRefresh() end)
end

function VUF:ApplyProfile()
    if InCombatLockdown() then
        VUF.pendingProfileRefresh = true
        return
    end

    VUF:ApplyVisuals()
    VUF:RefreshCooldownText()
    for unit in pairs(VUF.frames or {}) do VUF:ApplyUnitLayout(unit) end
end

function VUF:QueueProfileRefresh()
    if InCombatLockdown() then
        VUF.pendingProfileRefresh = true
    else
        VUF:ApplyProfile()
    end
end

function VUF:ExportProfile()
    local serialized = Serializer:Serialize({ schema = 1, profile = copy(VUF.db.profile) })
    return "VUF1:" .. Deflate:EncodeForPrint(Deflate:CompressDeflate(serialized))
end

function VUF:ImportProfile(text, name)
    if type(text) ~= "string" or #text > 50000 or text:sub(1, 5) ~= "VUF1:" then
        return nil, "Invalid VUF profile string."
    end
    name = (name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, "Enter a profile name." end

    local decoded = Deflate:DecodeForPrint(text:sub(6))
    local decompressed = decoded and Deflate:DecompressDeflate(decoded)
    local ok, payload = decompressed and Serializer:Deserialize(decompressed)
    if not ok or type(payload) ~= "table" or payload.schema ~= 1 or type(payload.profile) ~= "table" then
        return nil, "Invalid or unsupported VUF profile."
    end
    if type(payload.profile.visuals) ~= "table" or type(payload.profile.units) ~= "table" or type(payload.profile.positions) ~= "table" then
        return nil, "Profile is missing VUF settings."
    end

    VUF.db:SetProfile(name)
    VUF.db.profile.visuals = copy(payload.profile.visuals)
    VUF.db.profile.units = copy(payload.profile.units)
    VUF.db.profile.positions = copy(payload.profile.positions)
    if type(payload.profile.general) == "table" then
        VUF.db.profile.general = copy(payload.profile.general)
    end
    VUF:QueueProfileRefresh()
    return true
end
