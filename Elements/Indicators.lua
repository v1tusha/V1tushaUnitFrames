local _, VUF = ...

-- Indicators are freely positioned, so any of them can be dragged over the power bar or a
-- secondary-resource bar. Those are sibling frames with a higher draw order and would cover
-- a texture parented to Health. Host every indicator on a raised child overlay (frame level
-- +20) so it draws above the bars; overlays don't clip, so edge overflow onto neighbours is
-- intentional (raid marker sits outside by default).
local function overlayHost(frame)
    local o = frame.IndicatorOverlay
    if not o then
        o = CreateFrame("Frame", nil, frame)
        o:SetAllPoints(frame)
        o:SetFrameLevel(frame:GetFrameLevel() + 20)
        frame.IndicatorOverlay = o
    end
    return o
end

local function externalTex(frame, size)
    local t = overlayHost(frame):CreateTexture(nil, "OVERLAY")
    t:SetSize(size, size)
    return t
end

-- Health clips its children (heal prediction), so anything anchored outside must sit on the frame.
function VUF:CreateRaidTargetIndicator(frame)
    local t = externalTex(frame, 18)
    t:SetPoint("LEFT", frame, "RIGHT", 4, 0)
    frame.RaidTargetIndicator = t
end

function VUF:CreateCombatIndicator(frame)
    local t = externalTex(frame, 16)
    t:SetPoint("CENTER", frame, "LEFT", -12, 0)
    t:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
    t:SetTexCoord(0.5, 1, 0, 0.49)
    frame.CombatIndicator = t
end

function VUF:CreateLeaderIndicator(frame)
    local t = externalTex(frame, 14)
    t:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", 1, -1)
    frame.LeaderIndicator = t
end

function VUF:CreateAssistantIndicator(frame)
    local t = externalTex(frame, 14)
    t:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", 1, -1)
    frame.AssistantIndicator = t
end

function VUF:CreateRestingIndicator(frame)
    local t = externalTex(frame, 16)
    t:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", 1, -1)
    frame.RestingIndicator = t
end

function VUF:CreatePvPIndicator(frame)
    local t = externalTex(frame, 16)
    t:SetPoint("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -2, 2)
    frame.PvPIndicator = t
end

function VUF:CreateQuestIndicator(frame)
    local t = externalTex(frame, 16)
    t:SetPoint("CENTER", frame, "RIGHT", 14, 0)
    frame.QuestIndicator = t
end

local CLASS_LABEL = {
    rare       = "|cffb0b0b0R|r",
    rareelite  = "|cffb0b0b0R+|r",
    elite      = "|cffffcc00E|r",
    worldboss  = "|cffff2020B|r",
}

function VUF:CreateClassificationIndicator(frame, unit)
    local text = frame.Health:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPRIGHT", frame.Health, "TOPRIGHT", -3, -1)
    text:SetShadowOffset(1, -1)
    frame.ClassificationText = text

    local function update()
        local conf = VUF:GetUnitConfig(unit)
        if not UnitExists(unit) or (conf and conf.indicators.classification == false) then text:SetText(""); return end
        text:SetText(CLASS_LABEL[UnitClassification(unit)] or "")
    end
    frame.UpdateClassification = update
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_FOCUS_CHANGED")
    ev:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    ev:SetScript("OnEvent", update)
    frame:HookScript("OnShow", update)
    update()
end
