local _, VUF = ...

local COLOR = { 1.0, 1.0, 1.0, 0.9 }
local THICKNESS = 2

local function edge(parent, a1, a2, dim)
    -- sublevel 6 (below MouseoverGlow's 7) so hovering the target shows the mouseover glow.
    local t = parent:CreateTexture(nil, "OVERLAY", nil, 6)
    t:SetColorTexture(COLOR[1], COLOR[2], COLOR[3], COLOR[4])
    if dim == "h" then t:SetHeight(THICKNESS) else t:SetWidth(THICKNESS) end
    if dim == "h" then
        t:SetPoint(a1, parent, a1, -THICKNESS, dim == "h" and (a1 == "TOPLEFT" and THICKNESS or -THICKNESS) or 0)
        t:SetPoint(a2, parent, a2, THICKNESS, dim == "h" and (a2 == "TOPRIGHT" and THICKNESS or -THICKNESS) or 0)
    else
        t:SetPoint(a1, parent, a1, a1 == "TOPLEFT" and -THICKNESS or THICKNESS, THICKNESS)
        t:SetPoint(a2, parent, a2, a2 == "BOTTOMLEFT" and -THICKNESS or THICKNESS, -THICKNESS)
    end
    t:SetAlpha(0)
    return t
end

function VUF:CreateTargetGlow(frame, unit)
    local edges = {
        edge(frame, "TOPLEFT",    "TOPRIGHT",    "h"),
        edge(frame, "BOTTOMLEFT", "BOTTOMRIGHT", "h"),
        edge(frame, "TOPLEFT",    "BOTTOMLEFT",  "v"),
        edge(frame, "TOPRIGHT",   "BOTTOMRIGHT", "v"),
    }
    frame.TargetGlowEdges = edges

    local function update()
        local conf = VUF:GetUnitConfig(unit)
        if not conf or not conf.targetGlow or not UnitExists(unit) then
            for _, e in ipairs(edges) do e:SetAlpha(0) end
            return
        end
        local color = conf.targetGlowColor
        local show = UnitIsUnit("target", unit)
        for _, e in ipairs(edges) do
            e:SetColorTexture(color[1], color[2], color[3], color[4])
            e:SetAlphaFromBoolean(show, 1, 0)
        end
    end

    frame.UpdateTargetGlow = update
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:SetScript("OnEvent", update)
    frame:HookScript("OnShow", update)
end
