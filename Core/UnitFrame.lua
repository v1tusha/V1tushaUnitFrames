local _, VUF = ...

VUF.UNIT_DEFAULTS = VUF.UNIT_DEFAULTS or {}
local UNIT_DEFAULTS = VUF.UNIT_DEFAULTS
for k in pairs(UNIT_DEFAULTS) do UNIT_DEFAULTS[k] = nil end

local __DEFAULT_UNITS = {
    player       = { width = 240, height = 46, point = { "CENTER", "UIParent", "CENTER", -260, -180 } },
    target       = { width = 240, height = 46, point = { "CENTER", "UIParent", "CENTER",  260, -180 } },
    targettarget = { width = 120, height = 30, point = { "LEFT",   "V1tushaUnitFrames_target",  "RIGHT",  8, 0 } },
    focus        = { width = 220, height = 40, point = { "CENTER", "UIParent", "CENTER", -260,   80 } },
    focustarget  = { width = 120, height = 30, point = { "LEFT",   "V1tushaUnitFrames_focus",   "RIGHT",  8, 0 } },
    pet          = { width = 150, height = 28, point = { "RIGHT",  "V1tushaUnitFrames_player",  "LEFT",  -8, 0 } },
}

for i = 1, 8 do
    __DEFAULT_UNITS["boss" .. i] = {
        width = 200,
        height = 34,
        point = { "RIGHT", "UIParent", "RIGHT", -30, 100 - (i - 1) * 40 },
    }
end

for k, v in pairs(__DEFAULT_UNITS) do UNIT_DEFAULTS[k] = v end

local SMALL_FRAMES  = { targettarget = true, focustarget = true }
local FRIENDLY_HL   = { player = true, target = true, focus = true, pet = true }
local RANGE_FADE    = { target = true, targettarget = true, focus = true, focustarget = true, pet = true }

local POWER_HEIGHT   = 10
local BAR_GAP        = 1
local CASTBAR_HEIGHT = 18
local CASTBAR_GAP    = 4
local ALT_POWER_H    = 6

local BAR_DEFAULTS = {
    powerHeight = POWER_HEIGHT,
    castHeight = CASTBAR_HEIGHT,
    showCastText = true,
}

local CAST_DEFAULTS = VUF.CAST_DEFAULTS  -- defined in Elements/CastBar.lua, which loads first

local AURA_DEFAULTS = {
    buffSize = 22,
    buffSpacing = 2,
    buffCount = 16,
    buffAnchor = "BOTTOMLEFT",
    buffX = 0,
    buffY = 4,
    debuffSize = 22,
    debuffSpacing = 2,
    debuffCount = 12,
    debuffAnchor = "BOTTOMLEFT",
    debuffX = 0,
    debuffY = 30,
    onlyPlayerBuffs = false,
    onlyPlayerDebuffs = false,
}

local OVERLAY_DEFAULTS = {
    targetGlow = true,
    targetGlowColor = { 1, 1, 1, 0.9 },
    mouseoverGlow = true,
    mouseoverGlowColor = { 1, 0.9, 0.3, 0.8 },
    dispelHighlight = true,
    dispelAlpha = 0.55,
    rangeAlpha = 0.45,
}

-- Tag slots replace the old fixed Name / Health text / Power text. The first three
-- slots default to exactly what those used to render, reading the legacy keys, so an
-- existing profile keeps its layout until the Tags tab writes over a slot. Slot 4
-- carries the player's secondary mana readout, which used to be a hardcoded font
-- string on the bar itself. size = 0 means "follow the global font size".
local function tagDefaults(db, unit)
    local function legacy(key, fallback)
        if db and db[key] ~= nil then return db[key] end
        return fallback
    end

    local nameTop = legacy("nameTextPosition", "top") ~= "bottom"
    local white = { 1, 1, 1 }

    return {
        {
            tag = "[name]",
            enabled = legacy("showName", true) ~= false,
            region = "health",
            from = nameTop and "BOTTOMLEFT" or "TOPLEFT",
            to = nameTop and "TOPLEFT" or "BOTTOMLEFT",
            x = 2 + legacy("nameTextX", 0),
            y = (nameTop and 3 or -3) + legacy("nameTextY", 0),
            size = 0, colour = white,
        },
        {
            tag = VUF.HEALTH_FORMATS[legacy("healthTextFormat", VUF:GetVisual("healthFormat"))] or VUF.HEALTH_FORMATS.full,
            enabled = legacy("showHealthText", true) ~= false,
            region = "health", from = "CENTER", to = "CENTER",
            x = legacy("healthTextX", 0), y = legacy("healthTextY", 0),
            size = 0, colour = white,
        },
        {
            tag = VUF.POWER_FORMATS[legacy("powerTextFormat", "full")] or VUF.POWER_FORMATS.full,
            enabled = legacy("showPowerText", true) ~= false,
            region = "power", from = "CENTER", to = "CENTER",
            x = legacy("powerTextX", 0), y = legacy("powerTextY", 0),
            size = 0, colour = white,
        },
        unit == "player"
            and { tag = "[curmana] / [maxmana]", enabled = true, region = "altpower",
                  from = "CENTER", to = "CENTER", x = 0, y = 0, size = 0, colour = white }
            or { tag = "", enabled = true, region = "frame", from = "TOPRIGHT", to = "TOPRIGHT", x = -2, y = -2, size = 0, colour = white },
        { tag = "", enabled = true, region = "frame", from = "BOTTOMRIGHT", to = "BOTTOMRIGHT", x = -2, y = 2, size = 0, colour = white },
    }
end

local function resolveTags(db, unit)
    local defaults = tagDefaults(db, unit)
    local saved = db and db.tags
    for index, entry in ipairs(defaults) do
        local override = saved and saved[index]
        if override then
            for key, value in pairs(override) do
                if value ~= nil then entry[key] = value end
            end
        end
    end
    return defaults
end

local PREDICTION_DEFAULTS = {
    incomingHealsColor = { 0, 1, 0.4 },
    damageAbsorbColor  = { 0.8, 0.6, 0.1 },
    overAbsorbColor    = { 0.8, 0.6, 0.1 },
    healAbsorbColor    = { 0.8, 0.2, 0.4 },
    incomingHealsAlpha = 0.4,
    damageAbsorbAlpha  = 0.7,
    overAbsorbAlpha    = 0.7,
    healAbsorbAlpha    = 0.55,
}
VUF.PREDICTION_DEFAULTS = PREDICTION_DEFAULTS

local INDICATORS = {
    { key = "raidMarker", field = "RaidTargetIndicator" },
    { key = "leader", field = "LeaderIndicator" },
    { key = "assistant", field = "AssistantIndicator" },
    { key = "combat", field = "CombatIndicator" },
    { key = "resting", field = "RestingIndicator" },
    { key = "pvp", field = "PvPIndicator" },
    { key = "quest", field = "QuestIndicator" },
}

local function isBossUnit(unit) return unit:sub(1, 4) == "boss" end

-- Auras may stack above tag slot 1 instead of anchoring to the frame, which keeps them
-- clear of the unit name. Only sensible while that slot is actually drawn above the
-- health bar; the stackAuras toggle lets the user take the frame anchor back.
local function tagOneOnTop(conf)
    local tag = conf.tags[1]
    return VUF:IsTagActive(tag) and tag.region == "health" and tag.to:sub(1, 3) == "TOP"
end

-- X/Y stay live in both modes so no slider is silently dead. Stacked, buffs offset from
-- the tag (defaults 0/4 reproduce the old hardcoded gap exactly).
-- ponytail: stacked debuffs keep a fixed 4px chain gap — debuffY's default of 30 is
-- calibrated for anchoring against the frame and would jump the row. Give the stack its
-- own offset keys if anyone ever needs to tune that gap.
local function anchorAuras(frame, conf)
    local stacked = conf.stackAuras and tagOneOnTop(conf)
    if frame.Buffs then
        frame.Buffs:ClearAllPoints()
        if stacked then
            frame.Buffs:SetPoint("BOTTOMLEFT", frame.Tags[1], "TOPLEFT", conf.buffX, conf.buffY)
        else
            frame.Buffs:SetPoint(conf.buffAnchor, frame, conf.buffAnchor, conf.buffX, conf.buffY)
        end
    end
    if frame.Debuffs then
        frame.Debuffs:ClearAllPoints()
        if stacked and frame.Buffs then
            frame.Debuffs:SetPoint("BOTTOMLEFT", frame.Buffs, "TOPLEFT", conf.debuffX, 4)
        else
            frame.Debuffs:SetPoint(conf.debuffAnchor, frame, conf.debuffAnchor, conf.debuffX, conf.debuffY)
        end
    end
end

local function frameStyle(frame, unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    frame:HookScript("OnEnter", UnitFrame_OnEnter)
    frame:HookScript("OnLeave", UnitFrame_OnLeave)

    VUF:CreateBorder(frame)
    VUF:CreateHealthBar(frame)
    VUF:CreatePowerBar(frame)

    frame.Power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.Power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.Power:SetHeight(VUF:GetUnitConfig(unit).powerHeight)

    frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.Health:SetPoint("BOTTOM", frame.Power, "TOP", 0, BAR_GAP)

    VUF:CreateUnitTags(frame)

    if not SMALL_FRAMES[unit] then
        VUF:CreateCastBar(frame)
        frame.Castbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -CASTBAR_GAP)
        frame.Castbar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -CASTBAR_GAP)
        frame.Castbar:SetHeight(VUF:GetUnitConfig(unit).castHeight)
    end

    if not SMALL_FRAMES[unit] then
        local conf = VUF:GetUnitConfig(unit)
        local buffCols = math.floor(conf.width / (conf.buffSize + conf.buffSpacing))
        local debuffCols = math.floor(conf.width / (conf.debuffSize + conf.debuffSpacing))

        local buffs = VUF:CreateAuraContainer(frame, "Buffs", {
            size = conf.buffSize, spacing = conf.buffSpacing, num = conf.buffCount, maxCols = buffCols,
            initialAnchor = "BOTTOMLEFT", growthX = "RIGHT", growthY = "UP", onlyShowPlayer = conf.onlyPlayerBuffs,
        })
        buffs:SetSize(conf.width, conf.buffSize + conf.buffSpacing)

        local debuffs = VUF:CreateAuraContainer(frame, "Debuffs", {
            size = conf.debuffSize, spacing = conf.debuffSpacing, num = conf.debuffCount, maxCols = debuffCols,
            initialAnchor = "BOTTOMLEFT", growthX = "RIGHT", growthY = "UP", onlyShowPlayer = conf.onlyPlayerDebuffs,
        })
        debuffs:SetSize(conf.width, conf.debuffSize + conf.debuffSpacing)

        anchorAuras(frame, conf)
    end

    VUF:CreateRaidTargetIndicator(frame)
    VUF:CreateLeaderIndicator(frame)
    VUF:CreateAssistantIndicator(frame)
    VUF:CreatePvPIndicator(frame)

    if unit == "player" or unit == "target" then
        VUF:CreateCombatIndicator(frame)
    end
    if unit == "player" then
        VUF:CreateRestingIndicator(frame)
    end
    if unit == "target" or unit == "focus" then
        VUF:CreateQuestIndicator(frame)
        VUF:CreateClassificationIndicator(frame, unit)
    end

    if unit == "player" then
        local conf = VUF:GetUnitConfig(unit)
        local cp = VUF:CreateClassPower(frame, conf.width, 2)
        cp:SetSize(conf.width, 10)
        cp:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -4)
        cp.PostVisibility = function()
            VUF:ApplyUnitElements(unit)
        end

        VUF:CreateAdditionalPower(frame)
        frame.AdditionalPower:SetPoint("TOPLEFT", cp, "BOTTOMLEFT", 0, -3)
        frame.AdditionalPower:SetPoint("TOPRIGHT", cp, "BOTTOMRIGHT", 0, -3)
        frame.AdditionalPower:SetHeight(ALT_POWER_H)
    end

    if FRIENDLY_HL[unit] then
        VUF:CreateDispelHighlight(frame, unit)
    end

    if RANGE_FADE[unit] or isBossUnit(unit) then
        frame.Range = { insideAlpha = 1.0, outsideAlpha = 0.45 }
    end

    VUF:CreateTargetGlow(frame, unit)
    VUF:CreateMouseoverGlow(frame, unit)
end

local function settingOrDefault(db, key, default)
    if db and db[key] ~= nil then return db[key] end
    return default
end

function VUF:GetUnitConfig(unit)
    local d = UNIT_DEFAULTS[unit]
    if not d then return nil end
    local db = VUF:GetProfileData().units and VUF:GetProfileData().units[unit]
    local dispelFeedback = settingOrDefault(db, "dispelFeedback",
        (not db or db.dispelHighlight ~= false) and "color" or (db.dispelIcon ~= false and "icon" or "off"))
    return {
        enabled = db and db.enabled ~= nil and db.enabled or (db == nil or db.enabled ~= false),
        width = (db and db.width) or d.width,
        height = (db and db.height) or d.height,
        powerHeight = (db and db.powerHeight) or BAR_DEFAULTS.powerHeight,
        castHeight = (db and db.castHeight) or BAR_DEFAULTS.castHeight,
        showCastText = not db or db.showCastText ~= false,
        showCastName = settingOrDefault(db, "showCastName", settingOrDefault(db, "showCastText", true)),
        showCastTime = settingOrDefault(db, "showCastTime", settingOrDefault(db, "showCastText", true)),
        castTextSize = (db and db.castTextSize) or 12,
        castTextAlign = (db and db.castTextAlign) or "left",
        castColor = (db and db.castColor) or CAST_DEFAULTS.castColor,
        channelColor = (db and db.channelColor) or CAST_DEFAULTS.channelColor,
        notInterruptibleColor = (db and db.notInterruptibleColor) or CAST_DEFAULTS.notInterruptibleColor,
        successColor = (db and db.successColor) or CAST_DEFAULTS.successColor,
        interruptedColor = (db and db.interruptedColor) or CAST_DEFAULTS.interruptedColor,
        latencyColor = (db and db.latencyColor) or CAST_DEFAULTS.latencyColor,
        latencyAlpha = settingOrDefault(db, "latencyAlpha", CAST_DEFAULTS.latencyAlpha),
        castHoldTime = settingOrDefault(db, "castHoldTime", CAST_DEFAULTS.castHoldTime),
        castIconPosition = (db and db.castIconPosition) or CAST_DEFAULTS.castIconPosition,
        castIconSize = settingOrDefault(db, "castIconSize", CAST_DEFAULTS.castIconSize),
        showCastLatency = settingOrDefault(db, "showCastLatency", CAST_DEFAULTS.showCastLatency),
        showCastShield = settingOrDefault(db, "showCastShield", CAST_DEFAULTS.showCastShield),
        castReverse = settingOrDefault(db, "castReverse", CAST_DEFAULTS.castReverse),
        castClassColor = settingOrDefault(db, "castClassColor", CAST_DEFAULTS.castClassColor),
        castDetached = settingOrDefault(db, "castDetached", CAST_DEFAULTS.castDetached),
        castWidth = settingOrDefault(db, "castWidth", CAST_DEFAULTS.castWidth),
        castParent = (db and db.castParent) or ("V1tushaUnitFrames_" .. unit),
        castAnchorFrom = (db and db.castAnchorFrom) or CAST_DEFAULTS.castAnchorFrom,
        castAnchorTo = (db and db.castAnchorTo) or CAST_DEFAULTS.castAnchorTo,
        castX = settingOrDefault(db, "castX", CAST_DEFAULTS.castX),
        castY = settingOrDefault(db, "castY", CAST_DEFAULTS.castY),
        tags = resolveTags(db, unit),
        stackAuras = not db or db.stackAuras ~= false,
        showHealthPrediction = not db or db.showHealthPrediction ~= false,
        showIncomingHeals = settingOrDefault(db, "showIncomingHeals", true),
        showDamageAbsorb = settingOrDefault(db, "showDamageAbsorb", true),
        showOverAbsorb = settingOrDefault(db, "showOverAbsorb", true),
        showHealAbsorb = settingOrDefault(db, "showHealAbsorb", true),
        incomingHealsColor = (db and db.incomingHealsColor) or PREDICTION_DEFAULTS.incomingHealsColor,
        damageAbsorbColor = (db and db.damageAbsorbColor) or PREDICTION_DEFAULTS.damageAbsorbColor,
        overAbsorbColor = (db and db.overAbsorbColor) or PREDICTION_DEFAULTS.overAbsorbColor,
        healAbsorbColor = (db and db.healAbsorbColor) or PREDICTION_DEFAULTS.healAbsorbColor,
        incomingHealsAlpha = settingOrDefault(db, "incomingHealsAlpha", PREDICTION_DEFAULTS.incomingHealsAlpha),
        damageAbsorbAlpha = settingOrDefault(db, "damageAbsorbAlpha", PREDICTION_DEFAULTS.damageAbsorbAlpha),
        overAbsorbAlpha = settingOrDefault(db, "overAbsorbAlpha", PREDICTION_DEFAULTS.overAbsorbAlpha),
        healAbsorbAlpha = settingOrDefault(db, "healAbsorbAlpha", PREDICTION_DEFAULTS.healAbsorbAlpha),
        healthColorMode = (db and db.healthColorMode) or "reaction",
        healthColor = (db and db.healthColor) or { 0.2, 0.8, 0.2, 1 },
        healthAlpha = settingOrDefault(db, "healthAlpha", 1),
        powerAlpha = settingOrDefault(db, "powerAlpha", 1),
        barBackgroundColor = (db and db.barBackgroundColor) or VUF:GetVisual("backgroundColor"),
        barBackgroundAlpha = settingOrDefault(db, "barBackgroundAlpha", VUF:GetVisual("backgroundAlpha")),
        showPowerBar = not db or db.showPowerBar ~= false,
        showCastBar = not db or db.showCastBar ~= false,
        showBuffs = settingOrDefault(db, "showBuffs", settingOrDefault(db, "showAuras", false)),
        showDebuffs = settingOrDefault(db, "showDebuffs", settingOrDefault(db, "showAuras", false)),
        showClassPower = not db or db.showClassPower ~= false,
        showAdditionalPower = not db or db.showAdditionalPower ~= false,
        buffSize = (db and (db.buffSize or db.auraSize)) or AURA_DEFAULTS.buffSize,
        buffSpacing = (db and (db.buffSpacing or db.auraSpacing)) or AURA_DEFAULTS.buffSpacing,
        buffCount = (db and db.buffCount) or AURA_DEFAULTS.buffCount,
        buffAnchor = (db and db.buffAnchor) or AURA_DEFAULTS.buffAnchor,
        buffX = (db and db.buffX) or AURA_DEFAULTS.buffX,
        buffY = (db and db.buffY) or AURA_DEFAULTS.buffY,
        debuffSize = (db and (db.debuffSize or db.auraSize)) or AURA_DEFAULTS.debuffSize,
        debuffSpacing = (db and (db.debuffSpacing or db.auraSpacing)) or AURA_DEFAULTS.debuffSpacing,
        debuffCount = (db and db.debuffCount) or AURA_DEFAULTS.debuffCount,
        debuffAnchor = (db and db.debuffAnchor) or AURA_DEFAULTS.debuffAnchor,
        debuffX = (db and db.debuffX) or AURA_DEFAULTS.debuffX,
        debuffY = (db and db.debuffY) or AURA_DEFAULTS.debuffY,
        onlyPlayerBuffs = db and db.onlyPlayerBuffs == true or false,
        onlyPlayerDebuffs = db and db.onlyPlayerDebuffs == true or false,
        targetGlow = not db or db.targetGlow ~= false,
        targetGlowColor = (db and db.targetGlowColor) or OVERLAY_DEFAULTS.targetGlowColor,
        mouseoverGlow = not db or db.mouseoverGlow ~= false,
        mouseoverGlowColor = (db and db.mouseoverGlowColor) or OVERLAY_DEFAULTS.mouseoverGlowColor,
        dispelHighlight = dispelFeedback == "color",
        dispelIcon = dispelFeedback == "icon",
        dispelAlpha = (db and db.dispelAlpha) or OVERLAY_DEFAULTS.dispelAlpha,
        rangeAlpha = (db and db.rangeAlpha) or OVERLAY_DEFAULTS.rangeAlpha,
        indicators = (db and db.indicators) or {},
        point = d.point,
        parent = settingOrDefault(db, "parent", type(d.point[2]) == "string" and d.point[2] or "UIParent"),
        anchorFrom = settingOrDefault(db, "anchorFrom", d.point[1]),
        anchorTo = settingOrDefault(db, "anchorTo", d.point[3]),
        x = settingOrDefault(db, "x", d.point[4]),
        y = settingOrDefault(db, "y", d.point[5]),
        strata = settingOrDefault(db, "strata", "MEDIUM"),
        bossGrowth = settingOrDefault(db, "bossGrowth", "DOWN"),
        bossSpacing = settingOrDefault(db, "bossSpacing", 6),
        hasLayout = db and (db.parent ~= nil or db.anchorFrom ~= nil or db.anchorTo ~= nil or db.x ~= nil or db.y ~= nil or db.strata ~= nil),
    }
end

local function bossFollowPoint(unit, conf)
    local index = tonumber(unit:match("^boss(%d+)$"))
    if not index or index < 2 then return nil end

    local previous = "V1tushaUnitFrames_boss" .. (index - 1)
    local spacing = conf.bossSpacing
    local growth = conf.bossGrowth
    if growth == "UP" then
        return "BOTTOMLEFT", previous, "TOPLEFT", 0, spacing
    elseif growth == "LEFT" then
        return "RIGHT", previous, "LEFT", -spacing, 0
    elseif growth == "RIGHT" then
        return "LEFT", previous, "RIGHT", spacing, 0
    end
    return "TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing
end

function VUF:ApplyUnitIndicators(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    for _, definition in ipairs(INDICATORS) do
        local indicator = definition
        local element = frame[indicator.field]
        if element then
            element.PostUpdate = function(self)
                if conf.indicators[indicator.key] == false then self:Hide() end
            end
            if conf.indicators[indicator.key] == false then element:Hide() end
            if element.ForceUpdate then element:ForceUpdate() end
        end
    end
    if frame.UpdateClassification then frame:UpdateClassification() end
end

function VUF:ApplyUnitOverlays(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if frame.Range then
        frame.Range.insideAlpha = 1
        frame.Range.outsideAlpha = conf.rangeAlpha
    end
    if frame.UpdateTargetGlow then frame:UpdateTargetGlow() end
    if frame.UpdateMouseoverGlow then frame:UpdateMouseoverGlow() end
    if frame.UpdateDispelHighlight then frame:UpdateDispelHighlight() end
end

local function setElement(frame, name, enabled)
    if enabled then
        frame:EnableElement(name)
    else
        frame:DisableElement(name)
    end
end

local function hasVisibleClassPower(frame, conf)
    return conf.showClassPower and frame.ClassPower and frame.ClassPower.__isEnabled
end

function VUF:ApplyUnitElements(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if frame.Power then setElement(frame, "Power", conf.showPowerBar) end
    if frame.Castbar then setElement(frame, "Castbar", conf.showCastBar) end
    if frame.Buffs or frame.Debuffs then
        local showAuras = conf.showBuffs or conf.showDebuffs
        setElement(frame, "Auras", showAuras)
        if showAuras then
            local auras = frame.Buffs or frame.Debuffs
            if auras.ForceUpdate then auras:ForceUpdate() end
        end
        if frame.Buffs then frame.Buffs:SetShown(conf.showBuffs) end
        if frame.Debuffs then frame.Debuffs:SetShown(conf.showDebuffs) end
    end
    if frame.ClassPower then
        setElement(frame, "ClassPower", conf.showClassPower)
        if conf.showClassPower and frame.ClassPower.ForceUpdate then frame.ClassPower:ForceUpdate() end
    end
    if frame.AdditionalPower then
        if conf.showAdditionalPower then
            setElement(frame, "AdditionalPower", true)
            if frame.AdditionalPower.ForceUpdate then frame.AdditionalPower:ForceUpdate() end
        else
            setElement(frame, "AdditionalPower", false)
            frame.AdditionalPower:Hide()
        end
    end

    if frame.Health then
        frame.Health:ClearAllPoints()
        frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Health:SetPoint("BOTTOM", conf.showPowerBar and frame.Power or frame, conf.showPowerBar and "TOP" or "BOTTOM", 0, conf.showPowerBar and BAR_GAP or 0)
    end

    local anchor = frame
    if hasVisibleClassPower(frame, conf) then
        frame.ClassPower:ClearAllPoints()
        frame.ClassPower:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
        anchor = frame.ClassPower
    end
    if frame.AdditionalPower and conf.showAdditionalPower then
        frame.AdditionalPower:ClearAllPoints()
        frame.AdditionalPower:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
        frame.AdditionalPower:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -3)
        anchor = frame.AdditionalPower
    end
    if frame.Castbar and conf.showCastBar then
        VUF:ApplyUnitCastBar(unit)
    end

    -- Slots hide themselves when the bar they hang off is switched off, so every
    -- element toggle has to re-run the tag pass or the text floats over nothing.
    VUF:ApplyUnitText(unit)
end

function VUF:ApplyUnitText(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    VUF:ApplyUnitTags(unit)
    anchorAuras(frame, conf)
    if VUF.RefreshUnitPreview then VUF:RefreshUnitPreview(unit) end
end

function VUF:ApplyUnitAuras(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf or not frame.Buffs then return end

    frame.Buffs.size = conf.buffSize
    frame.Buffs.spacing = conf.buffSpacing
    frame.Buffs.num = conf.buffCount
    frame.Buffs.maxCols = math.max(1, math.floor(conf.width / (conf.buffSize + conf.buffSpacing)))
    frame.Buffs.onlyShowPlayer = conf.onlyPlayerBuffs
    frame.Buffs:SetSize(conf.width, conf.buffSize + conf.buffSpacing)

    frame.Debuffs.size = conf.debuffSize
    frame.Debuffs.spacing = conf.debuffSpacing
    frame.Debuffs.num = conf.debuffCount
    frame.Debuffs.maxCols = math.max(1, math.floor(conf.width / (conf.debuffSize + conf.debuffSpacing)))
    frame.Debuffs.onlyShowPlayer = conf.onlyPlayerDebuffs
    frame.Debuffs:SetSize(conf.width, conf.debuffSize + conf.debuffSpacing)

    anchorAuras(frame, conf)
    frame.Buffs:ForceUpdate()
    frame.Debuffs:ForceUpdate()
end

function VUF:ApplyUnitBarColours(unit)
    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if frame.Health then
        local mode = conf.healthColorMode
        -- class mode still falls through to reaction for NPCs, matching Blizzard behaviour
        local useReaction = mode == "class" or mode == "reaction"
        frame.Health.colorClass = mode == "class"
        frame.Health.colorHealth = mode ~= "custom"
        if frame.Health.SetColorReaction then
            frame.Health:SetColorReaction(useReaction)
        else
            frame.Health.colorReaction = useReaction
        end
        frame.Health:SetAlpha(conf.healthAlpha)
        frame.Health.PostUpdateColor = conf.healthColorMode == "custom" and function(bar)
            bar:SetStatusBarColor(conf.healthColor[1], conf.healthColor[2], conf.healthColor[3], conf.healthColor[4] or 1)
        end or nil
        if frame.Health.bg then
            frame.Health.bg:SetVertexColor(conf.barBackgroundColor[1], conf.barBackgroundColor[2], conf.barBackgroundColor[3], conf.barBackgroundColor[4] or 1)
            frame.Health.bg:SetAlpha(conf.barBackgroundAlpha)
        end
        if frame.Health.ForceUpdate then frame.Health:ForceUpdate() end
    end
    if frame.Power then
        frame.Power:SetAlpha(conf.powerAlpha)
        if frame.Power.bg then
            frame.Power.bg:SetVertexColor(conf.barBackgroundColor[1], conf.barBackgroundColor[2], conf.barBackgroundColor[3], conf.barBackgroundColor[4] or 1)
            frame.Power.bg:SetAlpha(conf.barBackgroundAlpha)
        end
        if frame.Power.ForceUpdate then frame.Power:ForceUpdate() end
    end
end

function VUF:ApplyUnitBars(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if frame.Health and frame.Health.RefreshPrediction then
        frame.Health.RefreshPrediction()
    end
    if frame.Power then
        frame.Power:SetHeight(conf.powerHeight)
    end
    if frame.Health and frame.Power then
        frame.Health:ClearAllPoints()
        frame.Health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Health:SetPoint("BOTTOM", frame.Power, "TOP", 0, BAR_GAP)
        if frame.Health.ForceUpdate then frame.Health:ForceUpdate() end
    end
    if frame.ClassPower then
        frame.ClassPower:ClearAllPoints()
        frame.ClassPower:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -4)
        frame.ClassPower:SetSize(conf.width, 10)
        frame.ClassPower.__width = conf.width
        if frame.ClassPower.Update then frame.ClassPower:Update() end
    end
    if frame.AdditionalPower and frame.ClassPower then
        frame.AdditionalPower:ClearAllPoints()
        frame.AdditionalPower:SetPoint("TOPLEFT", frame.ClassPower, "BOTTOMLEFT", 0, -3)
        frame.AdditionalPower:SetPoint("TOPRIGHT", frame.ClassPower, "BOTTOMRIGHT", 0, -3)
        frame.AdditionalPower:SetHeight(ALT_POWER_H)
    end
    VUF:ApplyUnitBarColours(unit)
    VUF:ApplyUnitCastBar(unit)
end

function VUF:ApplyUnitLayout(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if conf.enabled == false then
        UnregisterUnitWatch(frame)
        frame:Hide()
    else
        RegisterUnitWatch(frame)
    end
    frame:SetSize(conf.width, conf.height)
    local savedPos = VUF:LoadSavedPosition(unit)
    local bFrom, bParent, bTo, bX, bY = bossFollowPoint(unit, conf)
    frame:ClearAllPoints()
    if bFrom then
        frame:SetPoint(bFrom, _G[bParent] or UIParent, bTo, bX, bY)
    elseif savedPos and not conf.hasLayout then
        frame:SetPoint(unpack(savedPos))
    else
        local parent = _G[conf.parent] or UIParent
        frame:SetPoint(conf.anchorFrom, parent, conf.anchorTo, conf.x, conf.y)
    end
    frame:SetFrameStrata(conf.strata)
    if frame.Health and frame.Power then
        frame.Health:SetPoint("BOTTOM", frame.Power, "TOP", 0, BAR_GAP)
        if frame.Health.ForceUpdate then frame.Health:ForceUpdate() end
    end
    if frame.Buffs then
        frame.Buffs:SetWidth(conf.width)
        frame.Buffs.maxCols = math.max(1, math.floor(conf.width / (conf.buffSize + conf.buffSpacing)))
        if frame.Buffs.ForceUpdate then frame.Buffs:ForceUpdate() end
    end
    if frame.Debuffs then
        frame.Debuffs:SetWidth(conf.width)
        frame.Debuffs.maxCols = math.max(1, math.floor(conf.width / (conf.debuffSize + conf.debuffSpacing)))
        if frame.Debuffs.ForceUpdate then frame.Debuffs:ForceUpdate() end
    end
    if frame.ClassPower then
        frame.ClassPower.__width = conf.width
        frame.ClassPower:SetWidth(conf.width)
        if frame.ClassPower.Update then frame.ClassPower:Update() end
    end
    if VUF.movers and VUF.movers[unit] then VUF.movers[unit]:SetAllPoints(frame) end
    VUF:ApplyUnitBars(unit)
    VUF:ApplyUnitElements(unit)
    VUF:ApplyUnitText(unit)
    VUF:ApplyUnitAuras(unit)
    VUF:ApplyUnitOverlays(unit)
    VUF:ApplyUnitIndicators(unit)
    if VUF.RefreshUnitPreview then VUF:RefreshUnitPreview(unit) end
end

function VUF:ApplyBossLayouts()
    for i = 1, 8 do VUF:ApplyUnitLayout("boss" .. i) end
end

function VUF:SpawnUnit(unit)
    local oUF = VUF.oUF
    local conf = VUF:GetUnitConfig(unit)
    if not conf then return end

    local styleName = "V1tushaUnitFrames_" .. unit

    oUF:RegisterStyle(styleName, function(frame) frameStyle(frame, unit) end)
    oUF:SetActiveStyle(styleName)

    local frame = oUF:Spawn(unit, styleName)
    frame:SetSize(conf.width, conf.height)
    local savedPos = VUF:LoadSavedPosition(unit)
    local bFrom, bParent, bTo, bX, bY = bossFollowPoint(unit, conf)
    if bFrom then
        frame:SetPoint(bFrom, _G[bParent] or UIParent, bTo, bX, bY)
    elseif savedPos and not conf.hasLayout then
        frame:SetPoint(unpack(savedPos))
    else
        frame:SetPoint(conf.anchorFrom, _G[conf.parent] or UIParent, conf.anchorTo, conf.x, conf.y)
    end
    frame:SetFrameStrata(conf.strata)
    RegisterUnitWatch(frame)

    VUF[unit:upper()] = frame
    VUF.frames = VUF.frames or {}
    VUF.frames[unit] = frame
    VUF:CreateMover(frame, unit)
    VUF:ApplyUnitLayout(unit)
    return frame
end
