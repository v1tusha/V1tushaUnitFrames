local _, VUF = ...

local COLOR = { 1.0, 0.9, 0.3, 0.8 }
local THICKNESS = 2

local function edge(parent, a1, a2, dim)
    -- sublevel 7 (above TargetGlow's 6): on the target frame the always-on target glow
    -- would otherwise cover the mouseover glow, which reads as "glow never appears".
    local t = parent:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetColorTexture(COLOR[1], COLOR[2], COLOR[3], COLOR[4])
    if dim == "h" then
        t:SetHeight(THICKNESS)
        t:SetPoint(a1, parent, a1, -THICKNESS, a1 == "TOPLEFT" and THICKNESS or -THICKNESS)
        t:SetPoint(a2, parent, a2, THICKNESS, a2 == "TOPRIGHT" and THICKNESS or -THICKNESS)
    else
        t:SetWidth(THICKNESS)
        t:SetPoint(a1, parent, a1, a1 == "TOPLEFT" and -THICKNESS or THICKNESS, THICKNESS)
        t:SetPoint(a2, parent, a2, a2 == "BOTTOMLEFT" and -THICKNESS or THICKNESS, -THICKNESS)
    end
    t:SetAlpha(0)
    return t
end

function VUF:CreateMouseoverGlow(frame, unit)
    local edges = {
        edge(frame, "TOPLEFT",    "TOPRIGHT",    "h"),
        edge(frame, "BOTTOMLEFT", "BOTTOMRIGHT", "h"),
        edge(frame, "TOPLEFT",    "BOTTOMLEFT",  "v"),
        edge(frame, "TOPRIGHT",   "BOTTOMRIGHT", "v"),
    }
    frame.MouseoverGlowEdges = edges

    local ev = CreateFrame("Frame")

    -- UnitIsUnit can hand back a secret boolean, so we cannot branch on it — poll and let
    -- the Blizzard API set the alpha. This runs every frame while enabled, so keep it cheap:
    -- no GetUnitConfig here (it allocates ~90 fields). Colour/enabled only change on a config
    -- edit, so they are handled in update() instead.
    local function poll()
        for _, e in ipairs(edges) do
            e:SetAlphaFromBoolean(UnitIsUnit("mouseover", unit), 1, 0)
            if frame:IsMouseOver() then e:SetAlpha(1) end
        end
    end

    local function update()
        local conf = VUF:GetUnitConfig(unit)
        local enabled = conf and conf.mouseoverGlow ~= false and UnitExists(unit)
        local color = conf and conf.mouseoverGlowColor or COLOR
        for _, e in ipairs(edges) do
            e:SetColorTexture(color[1], color[2], color[3], color[4])
            if not enabled then e:SetAlpha(0) end
        end
        if enabled then poll() end
        ev:SetScript("OnUpdate", enabled and poll or nil)
    end

    frame.UpdateMouseoverGlow = update
    ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    ev:SetScript("OnEvent", update)
    frame:HookScript("OnShow", update)
    frame:HookScript("OnEnter", update)
    frame:HookScript("OnLeave", update)
end
