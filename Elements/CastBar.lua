local _, VUF = ...

local SHIELD_TEX = [[Interface\CastingBar\UI-CastingBar-Small-Shield]]
local CASTBAR_GAP = 4

VUF.CAST_DEFAULTS = {
    castColor             = { 0.8, 0.7, 0.2 },
    channelColor          = { 0.2, 0.6, 0.9 },
    notInterruptibleColor = { 0.6, 0.6, 0.6 },
    successColor          = { 0.2, 0.8, 0.3 },
    interruptedColor      = { 0.8, 0.2, 0.2 },
    latencyColor          = { 1, 0.15, 0.15 },
    latencyAlpha          = 0.45,
    castHoldTime          = 0.5,
    castIconPosition      = "left",
    castIconSize          = 0,
    showCastLatency       = true,
    showCastShield        = true,
    castReverse           = false,
    castClassColor        = false,
    castDetached          = false,
    castWidth             = 0,
    castAnchorFrom        = "TOP",
    castAnchorTo          = "BOTTOM",
    castX                 = 0,
    castY                 = -CASTBAR_GAP,
}

-- Same source as the health bar so custom reaction/class colours carry over.
local function classColor(unit)
    local colors = VUF.oUF and VUF.oUF.colors
    if not (colors and unit and UnitExists(unit)) then return end
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local c = class and colors.class[class]
        if c then return c:GetRGB() end
    end
    local c = colors.reaction[UnitReaction(unit, "player") or 4]
    if c then return c:GetRGB() end
end

-- oUF re-stamps SafeZone with a plain red texture on every Enable (GetTexture() is nil
-- for solid colours), so colour and alpha have to be re-asserted, not just set once.
local function applyLatency(cb)
    local conf, zone = cb.vufConf, cb.SafeZone
    if not (conf and zone) then return end
    local c = conf.latencyColor
    zone:SetColorTexture(c[1], c[2], c[3], conf.latencyAlpha)
    zone:SetAlpha(1)
    zone:SetShown(conf.showCastLatency and cb.vufUnit == "player")
end

-- oUF fires PostCastStart for both casts and channels, so one colour hook covers both.
-- notInterruptible is a *secret* value for units we don't control: reading it in an `if`
-- throws, which aborted CastStart before element:Show() and killed target/boss bars.
-- SetVertexColorFromBoolean is the sanctioned branch, same as oUF does for the Shield.
local function refreshColor(cb)
    local conf = cb.vufConf
    if not conf then return end

    local r, g, b
    if conf.castClassColor then
        r, g, b = classColor(cb.vufUnit)
    end
    if not r then
        local c = cb.channeling and conf.channelColor or conf.castColor
        r, g, b = c[1], c[2], c[3]
    end
    cb:SetStatusBarColor(r, g, b)

    -- casting/channeling/empowering are plain booleans; only then is notInterruptible set.
    if cb.casting or cb.channeling or cb.empowering then
        local n = conf.notInterruptibleColor
        cb:GetStatusBarTexture():SetVertexColorFromBoolean(cb.notInterruptible,
            CreateColor(n[1], n[2], n[3]), CreateColor(r, g, b))
    end
    applyLatency(cb)
end

local function endColor(cb, key)
    local conf = cb.vufConf
    if not conf then return end
    local c = conf[key]
    cb:SetStatusBarColor(c[1], c[2], c[3])
    -- oUF only grants hold time on fail/interrupt; give success the same flash.
    cb.holdTime = math.max(cb.holdTime or 0, conf.castHoldTime)
end

-- oUF force-fills the bar to 100% on fail/interrupt (castbar.lua:437) before our hook
-- runs, so it looks like the cast raced to the end. For our own cast we know the real
-- progress, so freeze it there. startTime/endTime are set only for the player unit
-- (castbar.lua:229), which is exactly the self-interrupt case; leave enemy bars as-is
-- (their progress is secret in Midnight anyway). channeling is still set here — oUF's
-- resetAttributes runs after the callback.
local function freezeAtInterrupt(cb)
    if cb.vufUnit ~= "player" then return end
    local s, e = cb.startTime, cb.endTime
    if not (s and e and e > s) then return end
    local frac = (GetTime() - s) / (e - s)
    if cb.channeling then frac = 1 - frac end
    cb:SetMinMaxValues(0, 1)
    cb:SetValue(math.min(math.max(frac, 0), 1))
end

-- A self-cancelled cast fires UNIT_SPELLCAST_STOP with no interruptedBy, exactly like a
-- clean finish, so oUF routes it to PostCastStop (green) and never force-fills — the native
-- timer just keeps animating to the end. Tell cancel from finish by real progress: for our
-- own cast startTime/endTime are readable, so a stop with time still left is a cancel.
-- ponytail: 50ms slop absorbs event latency; a cancel in the final 50ms reads as a clean
-- finish, which is visually indistinguishable anyway. Enemy stops (no times) stay success.
local function endedEarly(cb)
    local s, e = cb.startTime, cb.endTime
    if not (s and e and e > s) then return false end
    return e - GetTime() > 0.05
end

function VUF:CreateCastBar(frame)
    local tex = VUF:GetTexturePath()
    local cb = CreateFrame("StatusBar", nil, frame)
    cb:SetStatusBarTexture(tex)
    cb:Hide()

    local bg = cb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(unpack(VUF:GetVisual("backgroundColor")))
    bg:SetAlpha(VUF:GetVisual("backgroundAlpha"))
    cb.bg = bg

    local icon = cb:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPRIGHT", cb, "TOPLEFT", -2, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cb.Icon = icon

    -- oUF sizes and anchors this itself, but only for the player unit. OVERLAY -1 keeps it
    -- above the fill texture (ARTWORK) but below spark/shield, otherwise the fill hides it.
    local safeZone = cb:CreateTexture(nil, "OVERLAY", nil, -1)
    safeZone:SetColorTexture(1, 0.15, 0.15)
    cb.SafeZone = safeZone

    local spark = cb:CreateTexture(nil, "OVERLAY")
    spark:SetSize(8, 20)
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", cb:GetStatusBarTexture(), "RIGHT", 0, 0)
    cb.Spark = spark

    local shield = cb:CreateTexture(nil, "OVERLAY")
    shield:SetTexture(SHIELD_TEX)
    shield:SetSize(22, 22)
    shield:SetPoint("CENTER", cb, "LEFT", 4, 0)
    shield:SetAlpha(0)
    cb.Shield = shield

    local text = cb:CreateFontString(nil, "OVERLAY")
    VUF:ApplyFont(text)
    text:SetPoint("LEFT", cb, "LEFT", 4, 0)
    text:SetPoint("RIGHT", cb, "RIGHT", -40, 0)
    text:SetJustifyH("LEFT")
    cb.Text = text

    local time = cb:CreateFontString(nil, "OVERLAY")
    VUF:ApplyFont(time)
    time:SetPoint("RIGHT", cb, "RIGHT", -3, 0)
    cb.Time = time

    cb.PostCastStart = refreshColor
    cb.PostCastInterruptible = refreshColor
    cb.PostCastStop = function(bar)
        if endedEarly(bar) then
            freezeAtInterrupt(bar)
            endColor(bar, "interruptedColor")
        else
            endColor(bar, "successColor")
        end
    end
    cb.PostCastFail = function(bar) freezeAtInterrupt(bar); endColor(bar, "interruptedColor") end
    cb.PostCastInterrupted = cb.PostCastFail

    frame.Castbar = cb
end

function VUF:ApplyUnitCastBar(unit)
    if InCombatLockdown() then
        VUF.pendingLayouts = VUF.pendingLayouts or {}
        VUF.pendingLayouts[unit] = true
        return
    end

    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    local cb = frame and frame.Castbar
    if not cb or not conf then return end

    cb.vufConf, cb.vufUnit = conf, unit
    cb:SetHeight(conf.castHeight)
    cb:SetReverseFill(conf.castReverse)
    cb.timeToHold = conf.castHoldTime

    cb:ClearAllPoints()
    if conf.castDetached then
        cb:SetWidth(conf.castWidth > 0 and conf.castWidth or conf.width)
        cb:SetPoint(conf.castAnchorFrom, _G[conf.castParent] or frame, conf.castAnchorTo, conf.castX, conf.castY)
    else
        local anchor = conf.showAdditionalPower and frame.AdditionalPower
            or conf.showClassPower and frame.ClassPower and frame.ClassPower.__isEnabled and frame.ClassPower
            or frame
        cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -CASTBAR_GAP)
        cb:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -CASTBAR_GAP)
    end
    VUF:UpdateCastMover(unit, cb, conf.castDetached)

    local size = conf.castIconSize > 0 and conf.castIconSize or conf.castHeight
    cb.Icon:SetSize(size, size)
    cb.Icon:ClearAllPoints()
    if conf.castIconPosition == "right" then
        cb.Icon:SetPoint("TOPLEFT", cb, "TOPRIGHT", 2, 0)
    else
        cb.Icon:SetPoint("TOPRIGHT", cb, "TOPLEFT", -2, 0)
    end
    cb.Icon:SetShown(conf.castIconPosition ~= "hidden")

    if not conf.showCastShield then cb.Shield:SetAlpha(0) end

    cb.Text:ClearAllPoints()
    cb.Text:SetPoint("LEFT", cb, "LEFT", 4, 0)
    cb.Text:SetPoint("RIGHT", cb, "RIGHT", conf.showCastTime and -40 or -4, 0)
    cb.Text:SetJustifyH(conf.castTextAlign == "center" and "CENTER" or "LEFT")
    VUF:ApplyFont(cb.Text, conf.castTextSize)
    VUF:ApplyFont(cb.Time, conf.castTextSize)
    cb.Text:SetShown(conf.showCastName)
    cb.Time:SetShown(conf.showCastTime)

    refreshColor(cb)
end
