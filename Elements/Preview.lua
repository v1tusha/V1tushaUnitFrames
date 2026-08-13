local _, VUF = ...

-- ponytail: preview forces the real frames visible and mutes the oUF elements that
-- would otherwise wipe the fake children. Everything here is out-of-combat only.
-- VUF.preview[unit] is a set of active parts ("frame" / "cast" / "auras"), so previewing
-- auras does not also start a fake cast. Any active part shows the frame, since a unit
-- that does not exist is hidden by RegisterUnitWatch and nothing would be visible.
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

    cb.vufFakeCast = true
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
    -- Only tear down if we actually started a fake cast. stopFakeCast runs on EVERY preview
    -- teardown (e.g. toggling indicator preview), and if no fake cast was active the Castbar
    -- element is still enabled, so EnableElement below returns early (ouf.lua:98) and never
    -- restores oUF's onUpdate — killing the holdTime->Hide logic so real casts freeze on
    -- screen forever. Bailing here leaves the live castbar untouched.
    if not cb or not cb.vufFakeCast then return end
    cb.vufFakeCast = nil

    cb:SetScript("OnUpdate", nil)
    cb.vufFakeElapsed = nil
    cb:Hide()
    if conf.showCastBar then frame:EnableElement("Castbar") end
end

-- Bar values are faked only for an absent unit: it receives no UNIT_HEALTH events, so a
-- fake value simply stays. A live unit keeps its real bars — muting the element to hold a
-- fake value is not an option, because oUF's health and power Disable both call
-- element:Hide() and the bar would vanish (health.lua:614, power.lua:572).
--
-- Tag text is faked in both cases, which is what makes this useful on the player: sample
-- text shows whether the widest value still fits the bar. Untag first, or oUF re-renders
-- the font string on its own events and wipes the sample.
local function noop() end

-- Override is oUF's own hook for replacing an element's update (health.lua:357,
-- power.lua:346). Parking a no-op there freezes the fake value while the bar stays on
-- screen. DisableElement would hide it — both health and power Disable call element:Hide()
-- — which is why this preview looked dead on a live unit before.
local function startFakeBars(frame, conf, unit)
    local index = tonumber(unit:match("%d+$")) or 1
    local healthMax, powerMax = 1000000, 100

    -- Never 100%: a full-HP player forced to full looks pixel-identical to reality, so the
    -- preview reads as "nothing happened". A clearly partial fill is the whole point here.
    if frame.Health then
        frame.Health.Override = noop
        frame.Health:SetMinMaxValues(0, healthMax)
        frame.Health:SetValue(math.floor(healthMax * (75 - (index - 1) * 9) / 100))
    end
    if frame.Power then
        frame.Power.Override = noop
        frame.Power:SetMinMaxValues(0, powerMax)
        frame.Power:SetValue(math.floor(powerMax * (60 - (index - 1) * 7) / 100))
    end
end

local function stopFakeBars(frame, conf, unit)
    if frame.Health then frame.Health.Override = nil end
    if frame.Power then frame.Power.Override = nil end

    if not UnitExists(unit) then return end
    if frame.Health and frame.Health.ForceUpdate then frame.Health:ForceUpdate() end
    if frame.Power and frame.Power.ForceUpdate and conf.showPowerBar then frame.Power:ForceUpdate() end
end

-- Untag first, or oUF re-renders the font string on its own events and wipes the sample.
-- Faked for live units too: sample text is how you check the widest value still fits.
local function startFakeTags(frame, conf, unit)
    local index = tonumber(unit:match("%d+$")) or 1
    for slot, fs in ipairs(frame.Tags or {}) do
        local tag = conf.tags[slot]
        local sample = previewSample(tag.tag)
        if unit:sub(1, 4) == "boss" and tag.tag:find("name", 1, true) then sample = "Boss " .. index end
        frame:Untag(fs)
        fs:SetText(VUF:IsTagActive(tag) and sample or "")
    end
end

local function stopFakeTags(frame, conf, unit)
    -- ApplyUnitTags, not ApplyUnitText: the latter ends in RefreshUnitPreview and would
    -- come straight back into here while a preview part is still active.
    VUF:ApplyUnitTags(unit)
end

-- The glows and the dispel tint all bail out on a unit that is not your target, not
-- moused over, or carrying nothing dispellable — none of which you can stage on demand.
-- Preview drives the textures directly and leaves their Update functions alone.
local function startFakeFeedback(frame, conf)
    for _, edges in ipairs({ frame.TargetGlowEdges, frame.MouseoverGlowEdges }) do
        if edges then
            local colour = edges == frame.TargetGlowEdges and conf.targetGlowColor or conf.mouseoverGlowColor
            local shown = edges == frame.TargetGlowEdges and conf.targetGlow or conf.mouseoverGlow
            for _, e in ipairs(edges) do
                e:SetColorTexture(colour[1], colour[2], colour[3], colour[4] or 1)
                e:SetAlpha(shown and 1 or 0)
            end
        end
    end
    if frame.DispelHighlight and conf.dispelHighlight then
        -- Dispel is only seeded by ResetColours (the Reset button), so a fresh profile has
        -- an empty table here; fall back to the shipped Magic default instead of nil-indexing.
        local magic = VUF:GetColours().Dispel.Magic or { 0.2, 0.6, 1 }
        frame.DispelHighlight:SetAlpha(conf.dispelAlpha)
        frame.DispelHighlight:SetVertexColor(magic[1], magic[2], magic[3], 1)
        frame.DispelHighlight:Show()
    end
    if frame.DispelIcon and conf.dispelIcon then
        frame.DispelIcon:SetTexture(135932)
        frame.DispelIcon:Show()
    end
end

local function stopFakeFeedback(frame)
    if frame.DispelHighlight then frame.DispelHighlight:Hide() end
    if frame.DispelIcon then frame.DispelIcon:Hide() end
    if frame.UpdateTargetGlow then frame:UpdateTargetGlow() end
    if frame.UpdateMouseoverGlow then frame:UpdateMouseoverGlow() end
    if frame.UpdateDispelHighlight then frame:UpdateDispelHighlight() end
end

-- Raid mark 1, leader crown, elite. Every one of these needs group state or a live target
-- that cannot be conjured, so preview sets the textures itself.
local FAKE_INDICATORS = {
    { field = "RaidTargetIndicator", key = "raidMarker", texture = [[Interface\TargetingFrame\UI-RaidTargetingIcons]],
      coords = { 0, 0.25, 0, 0.25 } },
    { field = "LeaderIndicator", key = "leader", texture = [[Interface\GroupFrame\UI-Group-LeaderIcon]] },
    { field = "AssistantIndicator", key = "assistant", texture = [[Interface\GroupFrame\UI-Group-AssistantIcon]] },
    { field = "CombatIndicator", key = "combat" },
    { field = "RestingIndicator", key = "resting", texture = [[Interface\CharacterFrame\UI-StateIcon]],
      coords = { 0, 0.5, 0, 0.42 } },
    { field = "PvPIndicator", key = "pvp", texture = [[Interface\PVPFrame\PVP-Currency-Alliance]] },
    { field = "QuestIndicator", key = "quest", texture = [[Interface\TargetingFrame\PortraitQuestBadge]] },
}

local function startFakeIndicators(frame, conf)
    for _, entry in ipairs(FAKE_INDICATORS) do
        local element = frame[entry.field]
        if element and conf.indicators[entry.key] ~= false then
            if entry.texture then element:SetTexture(entry.texture) end
            if entry.coords then element:SetTexCoord(unpack(entry.coords)) end
            element:Show()
        end
    end
    if frame.ClassificationText and conf.indicators.classification ~= false then
        frame.ClassificationText:SetText("|cffffcc00E|r")
    end
end

local function stopFakeIndicators(frame, unit)
    for _, entry in ipairs(FAKE_INDICATORS) do
        local element = frame[entry.field]
        if element then element:Hide() end
    end
    if frame.ClassificationText then frame.ClassificationText:SetText("") end
    VUF:ApplyUnitIndicators(unit)
end

-- Buffs and debuffs are previewed independently, but oUF has a single Auras element
-- feeding both rows: while either row is faked the element has to go, so real auras stop
-- on both. Faking one row and keeping live auras in the other is not possible.
-- Rows are laid out whatever Show Buffs / Show Debuffs say — ticking preview is an
-- explicit request to see a row, which is how you size it before switching it on.
local function applyFakeAuras(frame, conf, unit, parts)
    if not (frame.Buffs or frame.Debuffs) then return end

    local faking = parts.buffs or parts.debuffs
    if faking then frame:DisableElement("Auras") end

    if frame.Buffs then
        if parts.buffs then
            frame.Buffs:Show()
            layoutFakes(frame.Buffs, conf.buffCount, conf.buffSize, conf.buffSpacing, false)
        else
            hideFakes(frame.Buffs)
            frame.Buffs:SetShown(conf.showBuffs)
        end
    end
    if frame.Debuffs then
        if parts.debuffs then
            frame.Debuffs:Show()
            layoutFakes(frame.Debuffs, conf.debuffCount, conf.debuffSize, conf.debuffSpacing, true)
        else
            hideFakes(frame.Debuffs)
            frame.Debuffs:SetShown(conf.showDebuffs)
        end
    end

    if not faking and (conf.showBuffs or conf.showDebuffs) then
        frame:EnableElement("Auras")
        local auras = frame.Buffs or frame.Debuffs
        -- oUF only skips absent units inside UpdateAllElements; a direct ForceUpdate does not.
        if auras and auras.ForceUpdate and UnitExists(unit) then auras:ForceUpdate() end
    end
end

local function applyPreview(unit, parts)
    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not conf then return end

    if not next(parts) then
        stopFakeBars(frame, conf, unit)
        stopFakeTags(frame, conf, unit)
        stopFakeFeedback(frame)
        stopFakeIndicators(frame, unit)
        applyFakeAuras(frame, conf, unit, parts)
        stopFakeCast(frame, conf)
        -- Both calls are blocked in combat: RegisterUnitWatch is a protected SetAttribute,
        -- and the frame itself is protected (SecureUnitButtonTemplate, ouf.lua:736), so
        -- Hide() would throw ADDON_ACTION_BLOCKED the moment combat starts. Skipping both
        -- is safe: ApplyUnitLayout defers via pendingLayouts, and on regen it re-registers
        -- the watch, which hides the frame for an absent unit anyway.
        if not InCombatLockdown() then
            RegisterUnitWatch(frame)
            if not UnitExists(unit) then frame:Hide() end
        end
        VUF:ApplyUnitLayout(unit)
        return
    end

    UnregisterUnitWatch(frame)
    frame:Show()

    if parts.frame then startFakeBars(frame, conf, unit) else stopFakeBars(frame, conf, unit) end
    if parts.tags then startFakeTags(frame, conf, unit) else stopFakeTags(frame, conf, unit) end
    if parts.feedback then startFakeFeedback(frame, conf) else stopFakeFeedback(frame) end
    if parts.indicators then startFakeIndicators(frame, conf) else stopFakeIndicators(frame, unit) end
    applyFakeAuras(frame, conf, unit, parts)

    if parts.cast and conf.showCastBar and frame.Castbar then
        startFakeCast(frame, conf)
    else
        stopFakeCast(frame, conf)
    end
end

local function expand(unit)
    if unit ~= "boss" then return { unit } end
    local units = {}
    for index = 1, 8 do units[index] = "boss" .. index end
    return units
end

function VUF:SetUnitPreview(unit, part, enabled)
    if InCombatLockdown() then
        print("|cFF8080FFV1tushaUnitFrames|r: preview cannot change in combat.")
        return
    end

    local parts = VUF.preview[unit] or {}
    parts[part] = enabled or nil
    -- Dropped entirely when the last part goes, so RefreshUnitPreview stays a cheap
    -- nil check and the teardown path below cannot recurse through ApplyUnitLayout.
    VUF.preview[unit] = next(parts) and parts or nil
    for _, name in ipairs(expand(unit)) do applyPreview(name, parts) end
end

function VUF:CancelPreviews()
    local active = {}
    for unit in pairs(VUF.preview or {}) do active[#active + 1] = unit end

    for _, unit in ipairs(active) do
        VUF.preview[unit] = nil
        for _, name in ipairs(expand(unit)) do applyPreview(name, {}) end
    end
end

function VUF:RefreshUnitPreview(unit)
    local key = unit:sub(1, 4) == "boss" and "boss" or unit
    local parts = VUF.preview[key]
    if not parts then return end
    for _, name in ipairs(expand(unit)) do applyPreview(name, parts) end
end

function VUF:IsPreviewing(unit, part)
    local parts = VUF.preview[unit]
    if not parts then return false end
    if part then return parts[part] == true end
    return next(parts) ~= nil
end
