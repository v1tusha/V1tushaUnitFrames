local _, VUF = ...

local oUF = VUF.oUF
local Methods, Events = oUF.Tags.Methods, oUF.Tags.Events

VUF.TAG_SLOTS = 5

local HEALTH_EVENTS = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"
local POWER_EVENTS  = "UNIT_POWER_UPDATE UNIT_MAXPOWER UNIT_DISPLAYPOWER"

-- Midnight hands out secret values for other units' data; string.format, arithmetic and
-- concatenation all error on one. pcall keeps a secret from taking the whole tag down —
-- the raw value still renders fine once it reaches the font string.
local function fmt(pattern, value, ...)
    local ok, text = pcall(string.format, pattern, value, ...)
    return ok and text or value
end

local function abbrev(value)
    local ok, text = pcall(AbbreviateNumbers, value)
    return ok and text or value
end

local function isSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function hex(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function precision(digits)
    return math.max(0, math.min(3, math.floor(tonumber(digits) or 0)))
end

local function healthStatus(unit)
    if UnitIsDead(unit) then return "Dead" end
    if UnitIsGhost(unit) then return "Ghost" end
    if not UnitIsConnected(unit) then return "Offline" end
end

function VUF:GetUnitColour(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local colour = class and RAID_CLASS_COLORS[class]
        if colour then return colour.r, colour.g, colour.b end
    end
    local reaction = UnitReaction(unit, "player")
    local colour = reaction and VUF:GetColours().Reaction[reaction]
    if colour then return colour[1], colour[2], colour[3] end
    return 1, 1, 1
end

local function powerColour(unit)
    local powerType = UnitPowerType(unit)
    local colours = VUF:GetColours()
    local colour = powerType and (colours.Power[powerType] or colours.SecondaryPower[powerType])
    if colour then return colour[1], colour[2], colour[3] end
    return 1, 1, 1
end

-- Health ---------------------------------------------------------------------

Methods["curhp:abbr"] = function(unit)
    if not UnitExists(unit) then return "" end
    return healthStatus(unit) or abbrev(UnitHealth(unit))
end
Events["curhp:abbr"] = HEALTH_EVENTS

Methods["maxhp:abbr"] = function(unit)
    if not UnitExists(unit) then return "" end
    return abbrev(UnitHealthMax(unit))
end
Events["maxhp:abbr"] = HEALTH_EVENTS

Methods["perhp:prec"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    return fmt("%." .. precision(digits) .. "f", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end
Events["perhp:prec"] = HEALTH_EVENTS

Methods["curhpperhp"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    local status = healthStatus(unit)
    if status then return status end
    return fmt("%s | %." .. precision(digits) .. "f%%", UnitHealth(unit),
        UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end
Events["curhpperhp"] = HEALTH_EVENTS

Methods["curhpperhp:abbr"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    local status = healthStatus(unit)
    if status then return status end
    return fmt("%s | %." .. precision(digits) .. "f%%", abbrev(UnitHealth(unit)),
        UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
end
Events["curhpperhp:abbr"] = HEALTH_EVENTS

Methods["absorbs"] = function(unit)
    if not UnitExists(unit) then return "" end
    return UnitGetTotalAbsorbs(unit) or 0
end
Events["absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED"

Methods["absorbs:abbr"] = function(unit)
    if not UnitExists(unit) then return "" end
    return abbrev(UnitGetTotalAbsorbs(unit) or 0)
end
Events["absorbs:abbr"] = "UNIT_ABSORB_AMOUNT_CHANGED"

Methods["absorbs:truncate"] = function(unit)
    if not UnitExists(unit) then return "" end
    return C_StringUtil.TruncateWhenZero(UnitGetTotalAbsorbs(unit) or 0)
end
Events["absorbs:truncate"] = "UNIT_ABSORB_AMOUNT_CHANGED"

-- Power ----------------------------------------------------------------------

Methods["curpp:abbr"] = function(unit)
    if not UnitExists(unit) then return "" end
    return abbrev(UnitPower(unit))
end
Events["curpp:abbr"] = POWER_EVENTS

Methods["maxpp:abbr"] = function(unit)
    if not UnitExists(unit) then return "" end
    return abbrev(UnitPowerMax(unit))
end
Events["maxpp:abbr"] = POWER_EVENTS

Methods["perpp:prec"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    return fmt("%." .. precision(digits) .. "f", UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100))
end
Events["perpp:prec"] = POWER_EVENTS

-- Mana as a percentage, every other resource as its raw value.
Methods["curpp:mana"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    if UnitPowerType(unit) ~= Enum.PowerType.Mana then return UnitPower(unit) end
    return fmt("%." .. precision(digits) .. "f%%",
        UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100))
end
Events["curpp:mana"] = POWER_EVENTS

Methods["curpp:mana:abbr"] = function(unit, _, digits)
    if not UnitExists(unit) then return "" end
    if UnitPowerType(unit) ~= Enum.PowerType.Mana then return abbrev(UnitPower(unit)) end
    return fmt("%." .. precision(digits) .. "f%%",
        UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100))
end
Events["curpp:mana:abbr"] = POWER_EVENTS

Methods["powercolour"] = function(unit)
    return hex(powerColour(unit))
end
Events["powercolour"] = "UNIT_DISPLAYPOWER"

-- Name -----------------------------------------------------------------------

local function shortName(unit, chars)
    local name = UnitName(unit)
    if not name then return "" end
    if isSecret(name) then return name end
    chars = math.floor(tonumber(chars) or 10)
    if chars > 0 then name = fmt("%." .. chars .. "s", name) end
    return name
end

Methods["name:short"] = function(unit, _, chars)
    return shortName(unit, chars)
end
Events["name:short"] = "UNIT_NAME_UPDATE"

Methods["name:target"] = function(unit)
    local target = unit .. "target"
    if not UnitExists(target) then return "" end
    return UnitName(target) or ""
end
Events["name:target"] = "UNIT_NAME_UPDATE UNIT_TARGET"

Methods["name:target:short"] = function(unit, _, chars)
    local target = unit .. "target"
    if not UnitExists(target) then return "" end
    return shortName(target, chars)
end
Events["name:target:short"] = "UNIT_NAME_UPDATE UNIT_TARGET"

-- Misc -----------------------------------------------------------------------

Methods["reactioncolour"] = function(unit)
    local reaction = UnitReaction(unit, "player")
    local colour = reaction and VUF:GetColours().Reaction[reaction]
    if colour then return hex(colour[1], colour[2], colour[3]) end
    return "|cffffffff"
end
Events["reactioncolour"] = "UNIT_FACTION UNIT_NAME_UPDATE"

-- Class colour for players, reaction colour for everything else.
Methods["unitcolour"] = function(unit)
    return hex(VUF:GetUnitColour(unit))
end
Events["unitcolour"] = "UNIT_CLASSIFICATION_CHANGED UNIT_FACTION UNIT_NAME_UPDATE"

Methods["resetcolour"] = function() return "|r" end

-- Catalogue for the config dropdowns -----------------------------------------

VUF.TAG_DB = {
    {
        key = "Health",
        tags = {
            { "curhp", "Current health" },
            { "curhp:abbr", "Current health, abbreviated (1.2M / Dead / Ghost)" },
            { "maxhp", "Maximum health" },
            { "maxhp:abbr", "Maximum health, abbreviated" },
            { "perhp", "Health percentage" },
            { "perhp:prec(2)", "Health percentage, 0-3 decimals" },
            { "curhpperhp", "Current health | percentage" },
            { "curhpperhp:abbr", "Current health | percentage, abbreviated" },
            { "curhpperhp:abbr(1)", "Current health | percentage, 0-3 decimals" },
            { "missinghp", "Missing health (hidden at zero)" },
            { "absorbs", "Total absorbs" },
            { "absorbs:abbr", "Total absorbs, abbreviated" },
            { "absorbs:truncate", "Total absorbs, hidden at zero" },
        },
    },
    {
        key = "Power",
        tags = {
            { "curpp", "Current power" },
            { "curpp:abbr", "Current power, abbreviated" },
            { "maxpp", "Maximum power" },
            { "maxpp:abbr", "Maximum power, abbreviated" },
            { "perpp", "Power percentage" },
            { "perpp:prec(2)", "Power percentage, 0-3 decimals" },
            { "curpp:mana", "Mana as a percentage, other resources raw" },
            { "curpp:mana:abbr", "Mana as a percentage, other resources abbreviated" },
            { "missingpp", "Missing power (hidden at zero)" },
            { "curmana", "Current mana (always mana, whatever the spec uses)" },
            { "maxmana", "Maximum mana (always mana, whatever the spec uses)" },
        },
    },
    {
        key = "Name",
        tags = {
            { "name", "Unit name" },
            { "name:short(10)", "Unit name, cut to N characters" },
            { "name:target", "Name of the unit's target" },
            { "name:target:short(10)", "Name of the unit's target, cut to N characters" },
        },
    },
    {
        key = "Misc",
        tags = {
            { "level", "Unit level" },
            { "smartlevel", "Unit level, ?? for bosses" },
            { "classification", "Elite / Rare / Boss" },
            { "shortclassification", "Elite / Rare / Boss, abbreviated" },
            { "creature", "Creature type" },
            { "class", "Unit class" },
            { "group", "Raid group number" },
            { "status", "Dead / Ghost / Offline / Resting" },
            { "threat", "Threat percentage" },
            { "unitcolour", "Prefix: class colour, reaction colour for NPCs" },
            { "raidcolor", "Prefix: class colour" },
            { "powercolour", "Prefix: power colour" },
            { "reactioncolour", "Prefix: reaction colour" },
            { "threatcolor", "Prefix: threat colour" },
            { "resetcolour", "Ends a colour prefix" },
        },
    },
}

-- Frame plumbing -------------------------------------------------------------

local JUSTIFY = {
    TOPLEFT = "LEFT", LEFT = "LEFT", BOTTOMLEFT = "LEFT",
    TOPRIGHT = "RIGHT", RIGHT = "RIGHT", BOTTOMRIGHT = "RIGHT",
}

function VUF:CreateUnitTags(frame)
    -- Own layer above the bars: health prediction and the cast bar are child frames
    -- with higher frame levels, so text parented to the bars would sit behind them.
    local layer = CreateFrame("Frame", nil, frame)
    layer:SetAllPoints(frame)
    layer:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.TagLayer = layer

    frame.Tags = {}
    for index = 1, VUF.TAG_SLOTS do
        frame.Tags[index] = layer:CreateFontString(nil, "OVERLAY")
    end
end

local function anchorFor(frame, region)
    if region == "power" then return frame.Power end
    if region == "altpower" then return frame.AdditionalPower end
    if region == "frame" then return frame end
    return frame.Health
end

-- A slot anchored to a bar the user switched off would float over nothing, so the
-- region has to be live before the slot may show. Bars oUF hides on its own (unpowered
-- NPCs) are not tracked — add an OnHide hook on the bar if that ever shows up.
local function regionShown(frame, conf, region)
    if region == "power" then return conf.showPowerBar end
    if region == "altpower" then return frame.AdditionalPower ~= nil and conf.showAdditionalPower end
    return true
end

-- Empty string means "nothing to draw"; enabled == false means "keep the string, just
-- do not draw it" — that is the off switch, so turning a slot off is not destructive.
function VUF:IsTagActive(tag)
    return tag.enabled ~= false and tag.tag ~= ""
end

function VUF:ApplyUnitTags(unit)
    local frame = VUF.frames and VUF.frames[unit]
    local conf = VUF:GetUnitConfig(unit)
    if not frame or not frame.Tags or not conf then return end

    for index, tag in ipairs(conf.tags) do
        local fs = frame.Tags[index]
        local hidden = not VUF:IsTagActive(tag) or not regionShown(frame, conf, tag.region)

        -- Size 0 means "follow the global font size", so a slot can be handed back.
        VUF:ApplyFont(fs, tag.size ~= 0 and tag.size or nil)
        fs:SetTextColor(tag.colour[1], tag.colour[2], tag.colour[3], 1)
        fs:SetJustifyH(JUSTIFY[tag.from] or "CENTER")
        fs:ClearAllPoints()
        fs:SetPoint(tag.from, anchorFor(frame, tag.region) or frame, tag.to, tag.x, tag.y)

        if hidden then
            frame:Untag(fs)
            fs:SetText("")
            fs:Hide()
        else
            -- A typo in the tag string must not take the whole frame down with it.
            pcall(frame.Tag, frame, fs, tag.tag)
            fs:Show()
            if fs.UpdateTag then fs:UpdateTag() end
        end
    end
end
