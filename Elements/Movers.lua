local _, VUF = ...

VUF.movers = {}
VUF.moversUnlocked = false

local UNIT_LABELS = {
    player = "Player", target = "Target", targettarget = "ToT",
    focus = "Focus", focustarget = "FoT", pet = "Pet",
}
for i = 1, 8 do UNIT_LABELS["boss" .. i] = "Boss " .. i end

local function edge(parent, a1, a2, dim, val, r, g, b, a)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(r, g, b, a)
    if dim == "h" then t:SetHeight(val) else t:SetWidth(val) end
    t:SetPoint(a1, parent, a1, 0, 0)
    t:SetPoint(a2, parent, a2, 0, 0)
    return t
end

function VUF:LoadSavedPosition(unit)
    local profile = VUF:GetProfileData()
    return profile.positions and profile.positions[unit] or nil
end

local function saveSnapshot(unit, frame)
    local profile = VUF:GetProfileData()
    profile.positions = profile.positions or {}
    local from, parent, to, x, y = frame:GetPoint(1)
    if not from then return end
    local parentName = parent and parent.GetName and parent:GetName() or "UIParent"
    profile.positions[unit] = { from, parentName, to, x or 0, y or 0 }
    profile.units[unit] = profile.units[unit] or {}
    local layout = profile.units[unit]
    layout.parent, layout.anchorFrom, layout.anchorTo = parentName, from, to
    layout.x, layout.y = x or 0, y or 0
end

local function saveCastSnapshot(unit, cb)
    local profile = VUF:GetProfileData()
    local from, parent, to, x, y = cb:GetPoint(1)
    if not from then return end
    profile.units[unit] = profile.units[unit] or {}
    local layout = profile.units[unit]
    layout.castParent = parent and parent.GetName and parent:GetName() or "UIParent"
    layout.castAnchorFrom, layout.castAnchorTo = from, to
    layout.castX, layout.castY = x or 0, y or 0
end

function VUF:MoveUnitBy(unit, dx, dy)
    if InCombatLockdown() then return end
    local frame = VUF[unit:upper()]
    if not frame then return end

    local cx, cy = frame:GetCenter()
    local uix, uiy = UIParent:GetCenter()
    if not (cx and uix) then return end

    local newOffX = (cx + dx) - uix
    local newOffY = (cy + dy) - uiy

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", newOffX, newOffY)
    saveSnapshot(unit, frame)
end

function VUF:CreateMover(frame, key, label, save)
    if VUF.movers[key] then return end

    save = save or saveSnapshot

    local m = CreateFrame("Button", "V1tushaUnitFramesMover_" .. key, UIParent)
    m.unit = key
    m:SetAllPoints(frame)
    m:SetFrameStrata("TOOLTIP")
    m:SetMovable(true)
    m:SetClampedToScreen(true)
    m:RegisterForDrag("LeftButton")
    m:EnableMouse(false)
    m:Hide()

    local fill = m:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(0.3, 0.6, 1.0, 0.35)

    edge(m, "TOPLEFT",     "TOPRIGHT",    "h", 1, 0.4, 0.8, 1.0, 0.9)
    edge(m, "BOTTOMLEFT",  "BOTTOMRIGHT", "h", 1, 0.4, 0.8, 1.0, 0.9)
    edge(m, "TOPLEFT",     "BOTTOMLEFT",  "v", 1, 0.4, 0.8, 1.0, 0.9)
    edge(m, "TOPRIGHT",    "BOTTOMRIGHT", "v", 1, 0.4, 0.8, 1.0, 0.9)

    local text = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetShadowOffset(1, -1)
    text:SetText(label or UNIT_LABELS[key] or key)

    local function stopDragging(self, saveNow)
        self:SetScript("OnUpdate", nil)
        if saveNow then save(key, frame) end
        self.cursorX, self.cursorY = nil, nil
        self.frameX, self.frameY = nil, nil
        self.lastX, self.lastY = nil, nil
    end

    m:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        local cursorX, cursorY = GetCursorPosition()
        local frameX, frameY = frame:GetCenter()
        local uiX, uiY = UIParent:GetCenter()
        local scale = UIParent:GetEffectiveScale()
        if not (cursorX and frameX and uiX and scale) then return end
        self.cursorX, self.cursorY = cursorX / scale, cursorY / scale
        self.frameX, self.frameY = frameX - uiX, frameY - uiY
        self:SetScript("OnUpdate", function(mover)
            if InCombatLockdown() then
                stopDragging(mover, false)
                return
            end

            local cursorX, cursorY = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if not (cursorX and scale) then return end
            local dx, dy = cursorX / scale - mover.cursorX, cursorY / scale - mover.cursorY
            if dx == mover.lastX and dy == mover.lastY then return end
            mover.lastX, mover.lastY = dx, dy
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", mover.frameX + dx, mover.frameY + dy)
        end)
    end)
    m:SetScript("OnDragStop", function(self)
        if not self.cursorX then return end
        stopDragging(self, not InCombatLockdown())
    end)

    VUF.movers[key] = m
end

-- Cast movers only exist while the bar is detached; attached bars follow the frame.
function VUF:UpdateCastMover(unit, cb, detached)
    local key = unit .. "Cast"
    if detached and not VUF.movers[key] then
        VUF:CreateMover(cb, key, (UNIT_LABELS[unit] or unit) .. " Cast", function(_, bar)
            saveCastSnapshot(unit, bar)
        end)
    end

    local m = VUF.movers[key]
    if not m then return end
    m.vufSkip = not detached
    if not detached then
        m:EnableMouse(false)
        m:Hide()
    end
end

local function setMoversShown(shown)
    for _, m in pairs(VUF.movers) do
        local visible = shown and not m.vufSkip
        m:EnableMouse(visible)
        m:SetShown(visible)
    end
end

function VUF:ShowEditModeMovers()
    if not VUF.moversUnlocked then
        VUF.editModeMovers = true
        setMoversShown(true)
    end
end

function VUF:HideEditModeMovers()
    if VUF.editModeMovers then
        VUF.editModeMovers = nil
        setMoversShown(false)
    end
end

function VUF:ToggleMovers()
    if InCombatLockdown() then
        print("|cFF8080FFV1tushaUnitFrames|r: cannot toggle movers in combat.")
        return
    end
    VUF.moversUnlocked = not VUF.moversUnlocked
    setMoversShown(VUF.moversUnlocked)
    print("|cFF8080FFV1tushaUnitFrames|r: movers " .. (VUF.moversUnlocked and "|cff33ff33UNLOCKED|r" or "|cffff5555locked|r"))
end

function VUF:ResetUnitLayout(unit)
    if InCombatLockdown() then
        print("|cFF8080FFV1tushaUnitFrames|r: cannot reset layout in combat.")
        return
    end

    local units = unit == "boss" and {} or { unit }
    if unit == "boss" then
        for i = 1, 8 do units[i] = "boss" .. i end
    end

    local profile = VUF:GetProfileData()
    for _, name in ipairs(units) do
        local saved = profile.units and profile.units[name]
        if saved then
            for _, key in ipairs({ "parent", "anchorFrom", "anchorTo", "x", "y", "strata", "width", "height", "bossGrowth", "bossSpacing",
                "castDetached", "castParent", "castAnchorFrom", "castAnchorTo", "castX", "castY", "castWidth" }) do
                saved[key] = nil
            end
        end
        if profile.positions then profile.positions[name] = nil end
        VUF:ApplyUnitLayout(name)
    end
end

function VUF:ResetPositions()
    if InCombatLockdown() then
        print("|cFF8080FFV1tushaUnitFrames|r: cannot reset positions in combat.")
        return
    end

    VUF:GetProfileData().positions = {}
    print("|cFF8080FFV1tushaUnitFrames|r: positions reset, reloading UI...")
    ReloadUI()
end
