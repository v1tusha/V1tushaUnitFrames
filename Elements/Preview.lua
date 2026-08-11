local _, VUF = ...

-- ponytail: preview forces the real frames visible and mutes the oUF elements that
-- would otherwise wipe the fake children. Everything here is out-of-combat only.
VUF.preview = {}

local BUFF_ICON = 135769
local DEBUFF_ICON = 135768
local DURATIONS = { 12, 46, 95, 620, 240, 33, 8, 1800 }
local STACKS = { nil, 2, nil, 9, nil, 3, nil, 12 }

local function dispelColour(index)
    local colours = VUF:GetColours().Dispel
    local order = { colours.Magic, colours.Curse, colours.Disease, colours.Poison, colours.Bleed }
    local c = order[(index - 1) % #order + 1]
    return c[1], c[2], c[3], 1
end

local function fakeIcon(container, index, texture)
    local icon = container["vufFake" .. index]
    if icon then return icon end

    icon = CreateFrame("Frame", nil, container)
    icon:SetFrameLevel(container:GetFrameLevel() + 6)

    icon.border = icon:CreateTexture(nil, "BACKGROUND")
    icon.border:SetAllPoints()

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexture(texture)
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.texture)
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetDrawSwipe(true)
    icon.cooldown:SetHideCountdownNumbers(false)

    icon.count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    icon.count:SetPoint("BOTTOMRIGHT", 2, 0)

    container["vufFake" .. index] = icon
    return icon
end

local function hideFakes(container)
    if not container then return end
    for index = 1, (container.vufFakeCount or 0) do
        local icon = container["vufFake" .. index]
        if icon then icon:Hide() end
    end
end

local function layoutFakes(container, count, size, spacing, isDebuff)
    if not container then return end

    for _, button in ipairs(container) do button:Hide() end

    local maxCols = math.max(1, container.maxCols or 1)
    for index = 1, count do
        local icon = fakeIcon(container, index, isDebuff and DEBUFF_ICON or BUFF_ICON)
        local col = (index - 1) % maxCols
        local row = math.floor((index - 1) / maxCols)

        icon:SetSize(size, size)
        icon:ClearAllPoints()
        icon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", col * (size + spacing), row * (size + spacing))

        if isDebuff then
            icon.border:SetColorTexture(dispelColour(index))
        else
            icon.border:SetColorTexture(0, 0, 0, 1)
        end

        local duration = DURATIONS[(index - 1) % #DURATIONS + 1]
        icon.cooldown:SetCooldown(GetTime() - (duration * 0.2), duration)
        VUF:ApplyCooldownFormatter(icon.cooldown)

        local stacks = STACKS[(index - 1) % #STACKS + 1]
        icon.count:SetText(stacks and tostring(stacks) or "")
        VUF:ApplyFont(icon.count, math.max(8, math.floor(size * 0.45)))
        icon:Show()
    end

    for index = count + 1, (container.vufFakeCount or 0) do
        local icon = container["vufFake" .. index]
        if icon then icon:Hide() end
    end
    container.vufFakeCount = math.max(count, container.vufFakeCount or 0)
end
--@VUFPREVIEW2@

-- Tag slots can hold anything, so preview shows a canned sample picked from what the
-- string actually asks for — keying samples off the slot number lied as soon as the
-- user rearranged the slots. Unknown strings show themselves, which is still honest.
local PREVIEW_SAMPLES = {
    { "name", "Preview Unit" },
    { "hp", "1.2M / 1.4M (85%)" },
    { "mana", "60 / 100 (60%)" },
    { "pp", "60 / 100 (60%)" },
    { "level", "70" },
    { "absorbs", "45K" },
}

local function previewSample(text)
    local sample, best
    for _, entry in ipairs(PREVIEW_SAMPLES) do
        local at = text:find(entry[1], 1, true)
        if at and (not best or at < best) then sample, best = entry[2], at end
    end
    return sample or text
end

local CAST_DURATION = 5

local function startFakeCast(frame, conf)
    local cb = frame.Castbar
    if not cb then return end

    frame:DisableElement("Castbar")
    cb:SetMinMaxValues(0, 1)
    cb:SetValue(0)
    cb:Show()
    if cb.Text then cb.Text:SetText("Preview Spell") end
    if cb.Icon then
        cb.Icon:SetTexture(136235)
        cb.Icon:SetShown(conf.castIconPosition ~= "hidden")
    end
    if cb.Shield then cb.Shield:Hide() end

    cb.vufFakeElapsed = 0
    cb:SetScript("OnUpdate", function(self, elapsed)
        self.vufFakeElapsed = ((self.vufFakeElapsed or 0) + elapsed) % CAST_DURATION
        self:SetValue(self.vufFakeElapsed / CAST_DURATION)
        if self.Time then self.Time:SetText(string.format("%.1f", CAST_DURATION - self.vufFakeElapsed)) end
    end)
end

local function stopFakeCast(frame, conf)
    local cb = frame.Castbar
    if not cb then return end

    cb:SetScript("OnUpdate", nil)
    cb.vufFakeElapsed = nil
    cb:Hide()
    if conf.showCastBar then frame:EnableElement("Castbar") end
end

local function applyPreview(unit, enabled)
    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if not enabled then
        hideFakes(frame.Buffs)
        hideFakes(frame.Debuffs)
        stopFakeCast(frame, conf)
        RegisterUnitWatch(frame)
        if not UnitExists(unit) then frame:Hide() end
        VUF:ApplyUnitLayout(unit)
        return
    end

    UnregisterUnitWatch(frame)
    frame:Show()

    -- Fill bars only when the unit is absent, so live units keep their real values.
    if not UnitExists(unit) then
        local index = tonumber(unit:match("%d+$")) or 1
        local healthMax, powerMax = 1000000, 100
        local health = math.floor(healthMax * (100 - (index - 1) * 9) / 100)
        local power = math.floor(powerMax * (85 - (index - 1) * 7) / 100)

        if frame.Health then
            frame.Health:SetMinMaxValues(0, healthMax)
            frame.Health:SetValue(health)
        end
        if frame.Power then
            frame.Power:SetMinMaxValues(0, powerMax)
            frame.Power:SetValue(power)
        end
        for slot, fs in ipairs(frame.Tags or {}) do
            local tag = conf.tags[slot]
            local sample = previewSample(tag.tag)
            if unit:sub(1, 4) == "boss" and tag.tag:find("name", 1, true) then sample = "Boss " .. index end
            fs:SetText(VUF:IsTagActive(tag) and sample or "")
        end
    end

    if conf.showCastBar and frame.Castbar then startFakeCast(frame, conf) end

    if frame.Buffs or frame.Debuffs then
        frame:DisableElement("Auras")
        if frame.Buffs then
            if conf.showBuffs then
                frame.Buffs:Show()
                layoutFakes(frame.Buffs, conf.buffCount, conf.buffSize, conf.buffSpacing, false)
            else
                hideFakes(frame.Buffs)
            end
        end
        if frame.Debuffs then
            if conf.showDebuffs then
                frame.Debuffs:Show()
                layoutFakes(frame.Debuffs, conf.debuffCount, conf.debuffSize, conf.debuffSpacing, true)
            else
                hideFakes(frame.Debuffs)
            end
        end
    end
end

local function expand(unit)
    if unit ~= "boss" then return { unit } end
    local units = {}
    for index = 1, 8 do units[index] = "boss" .. index end
    return units
end

function VUF:SetUnitPreview(unit, enabled)
    if InCombatLockdown() then
        print("|cFF8080FFV1tushaUnitFrames|r: preview cannot change in combat.")
        return
    end

    VUF.preview[unit] = enabled or nil
    for _, name in ipairs(expand(unit)) do applyPreview(name, enabled) end
end

function VUF:RefreshUnitPreview(unit)
    local key = unit:sub(1, 4) == "boss" and "boss" or unit
    if not VUF.preview[key] then return end
    if unit == "boss" then
        for _, name in ipairs(expand(unit)) do applyPreview(name, true) end
    else
        applyPreview(unit, true)
    end
end

function VUF:IsPreviewing(unit)
    return VUF.preview[unit] == true
end
