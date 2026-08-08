local _, VUF = ...

local LibDispel = LibStub("LibDispel-1.0", true)

local function buildColorCurve()
    if not C_CurveUtil then return nil end
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)

    local oUF = VUF.oUF
    if not (oUF and oUF.Enum and oUF.Enum.DispelType and oUF.colors and oUF.colors.dispel) then
        return curve
    end
    if not LibDispel then return curve end

    local myTypes = LibDispel:GetMyDispelTypes()
    if not myTypes then return curve end

    for dispelType, canDo in pairs(myTypes) do
        if canDo then
            local idx = oUF.Enum.DispelType[dispelType]
            local color = idx and oUF.colors.dispel[idx]
            if color then curve:AddPoint(idx, color) end
        end
    end
    return curve
end

local function findDispellableAura(unit, curve)
    if not curve then return nil end
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not aura or not aura.auraInstanceID then return nil end
        local color = C_UnitAuras.GetAuraDispelTypeColor(unit, aura.auraInstanceID, curve)
        if color then return color, aura end
    end
end

function VUF:CreateDispelHighlight(frame, unit)
    local hl = frame.Health:CreateTexture(nil, "OVERLAY")
    hl:SetPoint("TOP")
    hl:SetPoint("BOTTOM")
    hl:SetPoint("LEFT")
    hl:SetPoint("RIGHT", frame.Health:GetStatusBarTexture())
    hl:SetTexture([[Interface\Buttons\WHITE8x8]])
    hl:SetBlendMode("BLEND")
    hl:SetAlpha(0.55)
    hl:Hide()
    frame.DispelHighlight = hl

    local icon = frame.Health:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("BOTTOMLEFT", frame.Health, "TOPRIGHT", 2, 2)
    icon:Hide()
    frame.DispelIcon = icon

    local state = { curve = buildColorCurve() }

    local function refresh()
        local conf = VUF:GetUnitConfig(unit)
        if not conf or not conf.showDebuffs or (not conf.dispelHighlight and not conf.dispelIcon)
            or not UnitExists(unit) or not UnitIsFriend("player", unit) then
            hl:Hide()
            icon:Hide()
            return
        end

        local color, aura = findDispellableAura(unit, state.curve)
        if conf.dispelHighlight and color then
            hl:SetAlpha(conf.dispelAlpha)
            hl:SetVertexColor(color:GetRGBA())
            hl:Show()
        else
            hl:Hide()
        end
        if conf.dispelIcon and aura and aura.icon then
            icon:SetTexture(aura.icon)
            icon:Show()
        else
            icon:Hide()
        end
    end

    frame.UpdateDispelHighlight = refresh
    frame.RefreshDispelColors = function()
        state.curve = buildColorCurve()
        refresh()
    end

    local ev = CreateFrame("Frame")
    ev:RegisterUnitEvent("UNIT_AURA", unit)
    ev:RegisterEvent("SPELLS_CHANGED")
    ev:RegisterEvent("PLAYER_TALENT_UPDATE")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_FOCUS_CHANGED")
    ev:SetScript("OnEvent", function(_, event)
        if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            state.curve = buildColorCurve()
        end
        refresh()
    end)
end
