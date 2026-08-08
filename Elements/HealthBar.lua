local _, VUF = ...

local function attachPredictionBars(hb, tex, unit)
    local parent = hb
    hb:SetClipsChildren(true)
    local strata = hb:GetFrameStrata()

    local heals = CreateFrame("StatusBar", nil, parent)
    heals:SetFrameStrata(strata)
    heals:SetFrameLevel(hb:GetFrameLevel() + 1)
    heals:SetStatusBarTexture(tex)
    heals:SetStatusBarColor(0, 1, 0.4, 0.4)
    heals:SetPoint("TOP", hb)
    heals:SetPoint("BOTTOM", hb)
    heals:SetPoint("LEFT", hb:GetStatusBarTexture(), "RIGHT")
    heals:SetWidth(hb:GetWidth() or 200)
    hb.HealingAll = heals

    local absorb = CreateFrame("StatusBar", nil, parent)
    absorb:SetFrameStrata(strata)
    absorb:SetFrameLevel(hb:GetFrameLevel() + 2)
    absorb:SetStatusBarTexture(tex)
    absorb:SetStatusBarColor(0.8, 0.6, 0.1, 0.7)
    absorb:SetPoint("TOP", hb)
    absorb:SetPoint("BOTTOM", hb)
    absorb:SetPoint("LEFT", heals:GetStatusBarTexture(), "RIGHT")
    absorb:SetWidth(hb:GetWidth() or 200)
    hb.DamageAbsorb = absorb
    hb.damageAbsorbClampMode = 2

    local overAbsorbClip = CreateFrame("Frame", nil, parent)
    overAbsorbClip:SetFrameStrata(strata)
    overAbsorbClip:SetFrameLevel(hb:GetFrameLevel() + 3)
    overAbsorbClip:SetClipsChildren(true)

    local overAbsorb = CreateFrame("StatusBar", nil, overAbsorbClip)
    overAbsorb:SetFrameStrata(strata)
    overAbsorb:SetFrameLevel(hb:GetFrameLevel() + 4)
    overAbsorb:SetStatusBarTexture(tex)
    overAbsorb:SetStatusBarColor(0.8, 0.6, 0.1, 0.7)

    if hb:GetReverseFill() then
        overAbsorbClip:SetPoint("TOPRIGHT", hb)
        overAbsorbClip:SetPoint("BOTTOMLEFT", hb:GetStatusBarTexture(), "BOTTOMLEFT")
        overAbsorb:SetPoint("TOPLEFT", hb)
        overAbsorb:SetPoint("BOTTOMLEFT", hb)
    else
        overAbsorbClip:SetPoint("TOPLEFT", hb)
        overAbsorbClip:SetPoint("BOTTOMRIGHT", hb:GetStatusBarTexture(), "BOTTOMRIGHT")
        overAbsorb:SetPoint("TOPRIGHT", hb)
        overAbsorb:SetPoint("BOTTOMRIGHT", hb)
        overAbsorb:SetReverseFill(true)
    end
    overAbsorb:SetWidth(hb:GetWidth() or 200)
    overAbsorb:Hide()
    overAbsorbClip:Hide()
    hb.OverDamageAbsorb = overAbsorb
    hb.OverDamageAbsorbClip = overAbsorbClip

    local healAbsorb = CreateFrame("StatusBar", nil, parent)
    healAbsorb:SetFrameStrata(strata)
    healAbsorb:SetFrameLevel(hb:GetFrameLevel() + 3)
    healAbsorb:SetStatusBarTexture(tex)
    healAbsorb:SetStatusBarColor(0.8, 0.2, 0.4, 0.55)
    healAbsorb:SetPoint("TOP", hb)
    healAbsorb:SetPoint("BOTTOM", hb)
    healAbsorb:SetPoint("RIGHT", hb:GetStatusBarTexture())
    healAbsorb:SetWidth(hb:GetWidth() or 200)
    healAbsorb:SetReverseFill(true)
    hb.HealAbsorb = healAbsorb

    local function colorize(bar, color, alpha)
        bar:SetStatusBarColor(color[1], color[2], color[3], alpha)
    end

    hb.RefreshPrediction = function()
        local conf = VUF:GetUnitConfig(unit)
        if not conf then return end
        colorize(heals, conf.incomingHealsColor, conf.incomingHealsAlpha)
        colorize(absorb, conf.damageAbsorbColor, conf.damageAbsorbAlpha)
        colorize(overAbsorb, conf.overAbsorbColor, conf.overAbsorbAlpha)
        colorize(healAbsorb, conf.healAbsorbColor, conf.healAbsorbAlpha)
        if hb.PostUpdate then hb:PostUpdate() end
    end

    hb.PostUpdate = function()
        local conf = VUF:GetUnitConfig(unit)
        if not conf then return end
        local show = conf.showHealthPrediction
        overAbsorb:SetMinMaxValues(absorb:GetMinMaxValues())
        overAbsorb:SetValue(absorb:GetValue())
        overAbsorb:SetWidth(hb:GetWidth())
        heals:SetShown(show and conf.showIncomingHeals)
        absorb:SetShown(show and conf.showDamageAbsorb)
        local over = show and conf.showDamageAbsorb and conf.showOverAbsorb
        overAbsorbClip:SetShown(over)
        overAbsorb:SetShown(over)
        healAbsorb:SetShown(show and conf.showHealAbsorb)
    end

    hb.RefreshPrediction()
end

function VUF:CreateHealthBar(frame)
    local tex = VUF:GetTexturePath()
    local hb = CreateFrame("StatusBar", nil, frame)
    hb:SetStatusBarTexture(tex)

    local bg = hb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(unpack(VUF:GetVisual("backgroundColor")))
    bg:SetAlpha(VUF:GetVisual("backgroundAlpha"))
    hb.bg = bg

    local text = hb:CreateFontString(nil, "OVERLAY")
    VUF:ApplyFont(text)
    text:SetPoint("CENTER")
    hb.Value = text

    hb.colorClass    = true
    hb.colorReaction = true
    hb.colorHealth   = true

    attachPredictionBars(hb, tex, frame.unit)

    frame.Health = hb
    frame:Tag(text, VUF:GetHealthTag())
end
