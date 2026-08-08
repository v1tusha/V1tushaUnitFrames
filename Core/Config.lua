local _, VUF = ...

local AceGUI = LibStub("AceGUI-3.0")

local UNIT_TABS = {
    { text = "General", value = "general" },
    { text = "Visuals", value = "visuals" },
    { text = "Player", value = "player" },
    { text = "Target", value = "target" },
    { text = "Focus", value = "focus" },
    { text = "Pet", value = "pet" },
    { text = "ToT", value = "targettarget" },
    { text = "FoT", value = "focustarget" },
    { text = "Bosses", value = "boss" },
    { text = "Profiles", value = "profiles" },
}

local FONT_OUTLINES = {
    NONE = "None",
    OUTLINE = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["OUTLINE, MONOCHROME"] = "Outline (mono)",
}

local HEALTH_FORMAT_LABELS = {
    full = "1200 / 3500 (85%)",
    compact = "1200 (85%)",
    percent = "85%",
    hidden = "Hidden",
}

local POWER_FORMAT_LABELS = {
    full = "60 / 100 (60%)",
    compact = "60 (60%)",
    percent = "60%",
    hidden = "Hidden",
}

local COOLDOWN_STYLES = {
    decimalSeconds = "Decimal Seconds (1.1)",
    seconds = "Seconds (10s)",
    secondsOnly = "Seconds (10)",
    clock = "Clock (1:10)",
    minutes = "Minutes (2m)",
    hours = "Hours (1h)",
    days = "Days (1d)",
}

local function addCooldownTextSettings(container)
    local settings = VUF:GetCooldownText()
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle("Cooldown Text Breakpoints")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    container:AddChild(group)

    local note = AceGUI:Create("Label")
    note:SetText("Choose how aura cooldowns display at each minimum remaining-time threshold. Lower thresholds take priority.")
    note:SetFullWidth(true)
    group:AddChild(note)

    for index, breakpoint in ipairs(settings.Breakpoints) do
        local row = AceGUI:Create("InlineGroup")
        row:SetTitle("Breakpoint " .. index)
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        group:AddChild(row)

        local threshold = AceGUI:Create("Slider")
        threshold:SetLabel("Minimum Seconds")
        threshold:SetSliderValues(0, 86400, 1)
        threshold:SetValue(breakpoint.threshold)
        threshold:SetRelativeWidth(0.33)
        threshold:SetCallback("OnValueChanged", function(_, _, value)
            breakpoint.threshold = math.floor(value)
            VUF:RefreshCooldownText()
        end)
        row:AddChild(threshold)

        local style = AceGUI:Create("Dropdown")
        style:SetLabel("Display Style")
        style:SetList(COOLDOWN_STYLES)
        style:SetValue(breakpoint.style)
        style:SetRelativeWidth(0.34)
        style:SetCallback("OnValueChanged", function(_, _, value)
            breakpoint.style = value
            VUF:RefreshCooldownText()
        end)
        row:AddChild(style)

        local colour = AceGUI:Create("ColorPicker")
        colour:SetLabel("Colour")
        local c = breakpoint.color
        colour:SetColor(c[1], c[2], c[3], c[4] or 1)
        colour:SetHasAlpha(false)
        colour:SetRelativeWidth(0.33)
        local saveColour = function(_, _, r, g, b)
            breakpoint.color = { r, g, b, 1 }
            VUF:RefreshCooldownText()
        end
        colour:SetCallback("OnValueChanged", saveColour)
        colour:SetCallback("OnValueConfirmed", saveColour)
        row:AddChild(colour)
    end
end

local function ensureDB()
    return VUF:GetProfileData()
end

local function getSaved(unit, key)
    local db = ensureDB()
    db.units[unit] = db.units[unit] or {}
    return db.units[unit][key]
end

local function setSaved(unit, key, value)
    local db = ensureDB()
    db.units[unit] = db.units[unit] or {}
    db.units[unit][key] = value
end

local function getIndicator(unit, key)
    local db = ensureDB()
    return db.units[unit] and db.units[unit].indicators and db.units[unit].indicators[key]
end

local function setIndicator(unit, key, value)
    local db = ensureDB()
    db.units[unit] = db.units[unit] or {}
    db.units[unit].indicators = db.units[unit].indicators or {}
    db.units[unit].indicators[key] = value
end

local function applyBossOverride(key, value)
    for i = 1, 8 do setSaved("boss" .. i, key, value) end
end

local function applyBossIndicator(key, value)
    for i = 1, 8 do setIndicator("boss" .. i, key, value) end
end

local function defaultsFor(unit)
    return VUF.UNIT_DEFAULTS and VUF.UNIT_DEFAULTS[unit == "boss" and "boss1" or unit]
end

local function closeDropdownOnScroll(scroll)
    scroll.scrollframe:SetScript("OnMouseWheel", function(_, value)
        AceGUI:ClearFocus()
        scroll:MoveScroll(value)
    end)
end

local function addSpacer(container, height)
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    spacer:SetHeight(height or 6)
    container:AddChild(spacer)
end

local function addHeading(container, text)
    local heading = AceGUI:Create("Heading")
    heading:SetText(text)
    heading:SetFullWidth(true)
    container:AddChild(heading)
end

local function isBoss(unit) return unit == "boss" end
local function settingUnit(unit) return isBoss(unit) and "boss1" or unit end
local function hasCastbar(unit) return unit ~= "targettarget" and unit ~= "focustarget" end
local function hasAuras(unit) return hasCastbar(unit) end

local function applySetting(unit, key, value, apply)
    if isBoss(unit) then
        applyBossOverride(key, value)
        VUF:ApplyBossLayouts()
    else
        setSaved(unit, key, value)
        apply(VUF, unit)
    end
end

local function addLayoutSettings(container, unit)
    local boss = isBoss(unit)
    local defaults = defaultsFor(unit)
    local savedUnit = settingUnit(unit)

    local function addField(widget, width)
        widget:SetRelativeWidth(width or 1)
        container:AddChild(widget)
    end

    local enabled = AceGUI:Create("CheckBox")
    enabled:SetLabel("Enabled")
    local savedEnabled = getSaved(savedUnit, "enabled")
    enabled:SetValue(savedEnabled ~= false)
    enabled:SetRelativeWidth(0.25)
    enabled:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "enabled", value, VUF.ApplyUnitLayout)
    end)
    container:AddChild(enabled)

    local width = AceGUI:Create("Slider")
    width:SetLabel("Width")
    width:SetSliderValues(60, 400, 1)
    width:SetValue(getSaved(savedUnit, "width") or defaults.width)
    width:SetRelativeWidth(0.375)
    width:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "width", math.floor(value), VUF.ApplyUnitLayout)
    end)
    container:AddChild(width)

    local height = AceGUI:Create("Slider")
    height:SetLabel("Height")
    height:SetSliderValues(18, 100, 1)
    height:SetValue(getSaved(savedUnit, "height") or defaults.height)
    height:SetRelativeWidth(0.375)
    height:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "height", math.floor(value), VUF.ApplyUnitLayout)
    end)
    container:AddChild(height)

    local anchors = {
        TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
        LEFT = "Left", CENTER = "Center", RIGHT = "Right",
        BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
    }
    local parentList = { UIParent = "UIParent" }
    for _, name in ipairs({ "player", "target", "focus", "pet", "targettarget", "focustarget" }) do
        parentList["V1tushaUnitFrames_" .. name] = name
    end
    local strataList = {
        BACKGROUND = "Background", LOW = "Low", MEDIUM = "Medium", HIGH = "High",
        DIALOG = "Dialog", TOOLTIP = "Tooltip",
    }

    local parent = AceGUI:Create("Dropdown")
    parent:SetLabel("Parent")
    parent:SetList(parentList)
    parent:SetValue(getSaved(savedUnit, "parent") or (type(defaults.point[2]) == "string" and defaults.point[2] or "UIParent"))
    parent:SetRelativeWidth(0.5)
    parent:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "parent", value, VUF.ApplyUnitLayout) end)
    container:AddChild(parent)

    local strata = AceGUI:Create("Dropdown")
    strata:SetLabel("Frame Strata")
    strata:SetList(strataList)
    strata:SetValue(getSaved(savedUnit, "strata") or "MEDIUM")
    strata:SetRelativeWidth(0.5)
    strata:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "strata", value, VUF.ApplyUnitLayout) end)
    container:AddChild(strata)

    local anchorFrom = AceGUI:Create("Dropdown")
    anchorFrom:SetLabel("Anchor From")
    anchorFrom:SetList(anchors)
    anchorFrom:SetValue(getSaved(savedUnit, "anchorFrom") or defaults.point[1])
    anchorFrom:SetRelativeWidth(0.5)
    anchorFrom:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "anchorFrom", value, VUF.ApplyUnitLayout) end)
    container:AddChild(anchorFrom)

    local anchorTo = AceGUI:Create("Dropdown")
    anchorTo:SetLabel("Anchor To")
    anchorTo:SetList(anchors)
    anchorTo:SetValue(getSaved(savedUnit, "anchorTo") or defaults.point[3])
    anchorTo:SetRelativeWidth(0.5)
    anchorTo:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "anchorTo", value, VUF.ApplyUnitLayout) end)
    container:AddChild(anchorTo)

    local x = AceGUI:Create("Slider")
    x:SetLabel("X Offset")
    x:SetSliderValues(-3000, 3000, 1)
    x:SetValue(getSaved(savedUnit, "x") or defaults.point[4])
    x:SetRelativeWidth(0.5)
    x:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "x", math.floor(value), VUF.ApplyUnitLayout) end)
    container:AddChild(x)

    local y = AceGUI:Create("Slider")
    y:SetLabel("Y Offset")
    y:SetSliderValues(-3000, 3000, 1)
    y:SetValue(getSaved(savedUnit, "y") or defaults.point[5])
    y:SetRelativeWidth(0.5)
    y:SetCallback("OnValueChanged", function(_, _, value) applySetting(unit, "y", math.floor(value), VUF.ApplyUnitLayout) end)
    container:AddChild(y)

    addSpacer(container, 10)

    if boss then
        local bossGroup = AceGUI:Create("InlineGroup")
        bossGroup:SetTitle("Boss Frames")
        bossGroup:SetLayout("Flow")
        bossGroup:SetFullWidth(true)
        container:AddChild(bossGroup)

        local growth = AceGUI:Create("Dropdown")
        growth:SetLabel("Growth Direction")
        growth:SetList({ DOWN = "Down", UP = "Up", LEFT = "Left", RIGHT = "Right" })
        growth:SetValue(getSaved(savedUnit, "bossGrowth") or "DOWN")
        growth:SetRelativeWidth(0.47)
        growth:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "bossGrowth", value, VUF.ApplyUnitLayout)
        end)
        bossGroup:AddChild(growth)

        local spacing = AceGUI:Create("Slider")
        spacing:SetLabel("Frame Spacing")
        spacing:SetSliderValues(0, 100, 1)
        spacing:SetValue(getSaved(savedUnit, "bossSpacing") or 6)
        spacing:SetRelativeWidth(0.53)
        spacing:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "bossSpacing", math.floor(value), VUF.ApplyUnitLayout)
        end)
        bossGroup:AddChild(spacing)

        local bossNote = AceGUI:Create("Label")
        bossNote:SetText("|cff888888Boss 1 uses the layout above; Boss 2-8 follow it using this direction and spacing.|r")
        bossNote:SetFullWidth(true)
        bossGroup:AddChild(bossNote)

        local bossPreview = AceGUI:Create("CheckBox")
        bossPreview:SetLabel("Preview Boss Frames")
        bossPreview:SetValue(VUF:IsPreviewing("boss"))
        bossPreview:SetFullWidth(true)
        bossPreview:SetCallback("OnValueChanged", function(widget, _, value)
            VUF:SetUnitPreview("boss", value)
            widget:SetValue(VUF:IsPreviewing("boss"))
        end)
        bossGroup:AddChild(bossPreview)

        addSpacer(container, 10)
    end

    local resetLayout = AceGUI:Create("Button")
    resetLayout:SetText("Reset Layout")
    resetLayout:SetFullWidth(true)
    resetLayout:SetCallback("OnClick", function()
        VUF:ResetUnitLayout(unit)
        container:ReleaseChildren()
        addLayoutSettings(container, unit)
    end)
    container:AddChild(resetLayout)

    addSpacer(container, 6)
    local note = AceGUI:Create("Label")
    note:SetText("|cff888888Layout changes apply immediately outside combat.|r")
    note:SetFullWidth(true)
    container:AddChild(note)
end

local function addBarsSettings(container, unit)
    local savedUnit = settingUnit(unit)

    local function addRow(widget, width)
        widget:SetRelativeWidth(width or 0.5)
        container:AddChild(widget)
    end

    local powerVisible = AceGUI:Create("CheckBox")
    powerVisible:SetLabel("Show Power Bar")
    powerVisible:SetValue(getSaved(savedUnit, "showPowerBar") ~= false)
    powerVisible:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "showPowerBar", value, VUF.ApplyUnitElements)
    end)
    addRow(powerVisible)

    local powerHeight = AceGUI:Create("Slider")
    powerHeight:SetLabel("Power Bar Height")
    powerHeight:SetSliderValues(2, 24, 1)
    powerHeight:SetValue(getSaved(savedUnit, "powerHeight") or 10)
    powerHeight:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "powerHeight", math.floor(value), VUF.ApplyUnitBars)
    end)
    addRow(powerHeight)

    local healthMode = AceGUI:Create("Dropdown")
    healthMode:SetLabel("Health Colour Mode")
    healthMode:SetList({ class = "Class", reaction = "Reaction", custom = "Custom" })
    healthMode:SetValue(VUF:GetUnitConfig(savedUnit).healthColorMode)
    healthMode:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "healthColorMode", value, VUF.ApplyUnitBarColours)
    end)
    addRow(healthMode, 0.47)

    local healthColor = getSaved(savedUnit, "healthColor") or { 0.2, 0.8, 0.2, 1 }
    local healthPicker = AceGUI:Create("ColorPicker")
    healthPicker:SetLabel("Custom Health Colour")
    healthPicker:SetColor(healthColor[1], healthColor[2], healthColor[3], healthColor[4] or 1)
    healthPicker:SetHasAlpha(false)
    local function saveHealthColor(_, _, r, g, b)
        applySetting(unit, "healthColor", { r, g, b, 1 }, VUF.ApplyUnitBarColours)
    end
    healthPicker:SetCallback("OnValueChanged", saveHealthColor)
    healthPicker:SetCallback("OnValueConfirmed", saveHealthColor)
    addRow(healthPicker, 0.53)

    local healthAlpha = AceGUI:Create("Slider")
    healthAlpha:SetLabel("Health Opacity")
    healthAlpha:SetSliderValues(0, 1, 0.05)
    healthAlpha:SetValue(getSaved(savedUnit, "healthAlpha") or 1)
    healthAlpha:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "healthAlpha", value, VUF.ApplyUnitBarColours)
    end)
    addRow(healthAlpha)

    local powerAlpha = AceGUI:Create("Slider")
    powerAlpha:SetLabel("Power Opacity")
    powerAlpha:SetSliderValues(0, 1, 0.05)
    powerAlpha:SetValue(getSaved(savedUnit, "powerAlpha") or 1)
    powerAlpha:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "powerAlpha", value, VUF.ApplyUnitBarColours)
    end)
    addRow(powerAlpha)

    local background = getSaved(savedUnit, "barBackgroundColor") or VUF:GetVisual("backgroundColor")
    local backgroundPicker = AceGUI:Create("ColorPicker")
    backgroundPicker:SetLabel("Bar Background Colour")
    backgroundPicker:SetColor(background[1], background[2], background[3], background[4] or 1)
    backgroundPicker:SetHasAlpha(false)
    local function saveBackground(_, _, r, g, b)
        applySetting(unit, "barBackgroundColor", { r, g, b, 1 }, VUF.ApplyUnitBarColours)
    end
    backgroundPicker:SetCallback("OnValueChanged", saveBackground)
    backgroundPicker:SetCallback("OnValueConfirmed", saveBackground)
    addRow(backgroundPicker)

    local backgroundAlpha = AceGUI:Create("Slider")
    backgroundAlpha:SetLabel("Background Opacity")
    backgroundAlpha:SetSliderValues(0, 1, 0.05)
    backgroundAlpha:SetValue(getSaved(savedUnit, "barBackgroundAlpha") or VUF:GetVisual("backgroundAlpha"))
    backgroundAlpha:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "barBackgroundAlpha", value, VUF.ApplyUnitBarColours)
    end)
    addRow(backgroundAlpha)

    local prediction = AceGUI:Create("CheckBox")
    prediction:SetLabel("Show Incoming Healing and Absorbs")
    prediction:SetValue(getSaved(savedUnit, "showHealthPrediction") ~= false)
    prediction:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "showHealthPrediction", value, VUF.ApplyUnitBars)
    end)
    addRow(prediction, 1)

    local predictionGroup = AceGUI:Create("InlineGroup")
    predictionGroup:SetTitle("Heal Prediction")
    predictionGroup:SetLayout("Flow")
    predictionGroup:SetFullWidth(true)
    container:AddChild(predictionGroup)

    local predictionDefaults = VUF.PREDICTION_DEFAULTS or {}
    local function addPredictionLayer(label, showKey, colorKey, alphaKey)
        local toggle = AceGUI:Create("CheckBox")
        toggle:SetLabel(label)
        toggle:SetValue(getSaved(savedUnit, showKey) ~= false)
        toggle:SetRelativeWidth(0.34)
        toggle:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, showKey, value, VUF.ApplyUnitBars)
        end)
        predictionGroup:AddChild(toggle)

        local color = getSaved(savedUnit, colorKey) or predictionDefaults[colorKey] or { 1, 1, 1 }
        local picker = AceGUI:Create("ColorPicker")
        picker:SetLabel(label .. " Colour")
        picker:SetColor(color[1], color[2], color[3], 1)
        picker:SetHasAlpha(false)
        picker:SetRelativeWidth(0.3)
        local function save(_, _, r, g, b)
            applySetting(unit, colorKey, { r, g, b }, VUF.ApplyUnitBars)
        end
        picker:SetCallback("OnValueChanged", save)
        picker:SetCallback("OnValueConfirmed", save)
        predictionGroup:AddChild(picker)

        local alpha = AceGUI:Create("Slider")
        alpha:SetLabel("Opacity")
        alpha:SetSliderValues(0, 1, 0.05)
        alpha:SetValue(getSaved(savedUnit, alphaKey) or predictionDefaults[alphaKey] or 0.5)
        alpha:SetRelativeWidth(0.36)
        alpha:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, alphaKey, value, VUF.ApplyUnitBars)
        end)
        predictionGroup:AddChild(alpha)
    end

    addPredictionLayer("Incoming Heals", "showIncomingHeals", "incomingHealsColor", "incomingHealsAlpha")
    addPredictionLayer("Damage Absorb", "showDamageAbsorb", "damageAbsorbColor", "damageAbsorbAlpha")
    addPredictionLayer("Over Absorb", "showOverAbsorb", "overAbsorbColor", "overAbsorbAlpha")
    addPredictionLayer("Heal Absorb", "showHealAbsorb", "healAbsorbColor", "healAbsorbAlpha")

    local predictionNote = AceGUI:Create("Label")
    predictionNote:SetText("|cff888888Over Absorb needs Damage Absorb enabled; it shows shielding beyond maximum health.|r")
    predictionNote:SetFullWidth(true)
    predictionGroup:AddChild(predictionNote)

    if unit == "player" then
        local classPowerVisible = AceGUI:Create("CheckBox")
        classPowerVisible:SetLabel("Show Class Power")
        classPowerVisible:SetValue(getSaved(savedUnit, "showClassPower") ~= false)
        classPowerVisible:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "showClassPower", value, VUF.ApplyUnitElements)
        end)
        addRow(classPowerVisible)
    else
        local classPowerSpacer = AceGUI:Create("Label")
        classPowerSpacer:SetText(" ")
        classPowerSpacer:SetHeight(24)
        classPowerSpacer:SetRelativeWidth(0.5)
        container:AddChild(classPowerSpacer)
    end

    if hasCastbar(unit) then
        local castVisible = AceGUI:Create("CheckBox")
        castVisible:SetLabel("Show Cast Bar")
        castVisible:SetValue(getSaved(savedUnit, "showCastBar") ~= false)
        castVisible:SetRelativeWidth(0.5)
        castVisible:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "showCastBar", value, VUF.ApplyUnitElements)
        end)
        container:AddChild(castVisible)

        local castHeight = AceGUI:Create("Slider")
        castHeight:SetLabel("Cast Bar Height")
        castHeight:SetSliderValues(6, 40, 1)
        castHeight:SetValue(getSaved(savedUnit, "castHeight") or 18)
        castHeight:SetRelativeWidth(0.5)
        castHeight:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "castHeight", math.floor(value), VUF.ApplyUnitBars)
        end)
        container:AddChild(castHeight)

        local castName = AceGUI:Create("CheckBox")
        castName:SetLabel("Show Spell Name")
        local savedName = getSaved(savedUnit, "showCastName")
        castName:SetValue(savedName == nil and getSaved(savedUnit, "showCastText") ~= false or savedName)
        castName:SetRelativeWidth(0.5)
        castName:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "showCastName", value, VUF.ApplyUnitBars)
        end)
        container:AddChild(castName)

        local castTime = AceGUI:Create("CheckBox")
        castTime:SetLabel("Show Cast Time")
        local savedTime = getSaved(savedUnit, "showCastTime")
        castTime:SetValue(savedTime == nil and getSaved(savedUnit, "showCastText") ~= false or savedTime)
        castTime:SetRelativeWidth(0.5)
        castTime:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "showCastTime", value, VUF.ApplyUnitBars)
        end)
        container:AddChild(castTime)

        local castTextSize = AceGUI:Create("Slider")
        castTextSize:SetLabel("Cast Text Size")
        castTextSize:SetSliderValues(8, 22, 1)
        castTextSize:SetValue(getSaved(savedUnit, "castTextSize") or 12)
        castTextSize:SetRelativeWidth(0.5)
        castTextSize:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "castTextSize", math.floor(value), VUF.ApplyUnitBars)
        end)
        container:AddChild(castTextSize)

        local castAlign = AceGUI:Create("Dropdown")
        castAlign:SetLabel("Spell Name Alignment")
        castAlign:SetList({ left = "Left", center = "Center" })
        castAlign:SetValue(getSaved(savedUnit, "castTextAlign") or "left")
        castAlign:SetRelativeWidth(0.5)
        castAlign:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "castTextAlign", value, VUF.ApplyUnitBars)
        end)
        container:AddChild(castAlign)
    end
end


local function addTextSettings(container, unit)
    local savedUnit = settingUnit(unit)
    local function save(key, value)
        applySetting(unit, key, value, VUF.ApplyUnitText)
    end

    local name = AceGUI:Create("CheckBox")
    name:SetLabel("Show Name")
    name:SetValue(getSaved(savedUnit, "showName") ~= false)
    name:SetRelativeWidth(0.5)
    name:SetCallback("OnValueChanged", function(_, _, value) save("showName", value) end)
    container:AddChild(name)

    local namePosition = AceGUI:Create("Dropdown")
    namePosition:SetLabel("Name Position")
    namePosition:SetList({ top = "Above Health", bottom = "Below Health" })
    namePosition:SetValue(getSaved(savedUnit, "nameTextPosition") or "top")
    namePosition:SetRelativeWidth(0.5)
    namePosition:SetCallback("OnValueChanged", function(_, _, value) save("nameTextPosition", value) end)
    container:AddChild(namePosition)

    local health = AceGUI:Create("CheckBox")
    health:SetLabel("Show Health Text")
    health:SetValue(getSaved(savedUnit, "showHealthText") ~= false)
    health:SetRelativeWidth(0.5)
    health:SetCallback("OnValueChanged", function(_, _, value) save("showHealthText", value) end)
    container:AddChild(health)

    local healthFormat = AceGUI:Create("Dropdown")
    healthFormat:SetLabel("Health Text Format")
    healthFormat:SetList(HEALTH_FORMAT_LABELS)
    healthFormat:SetValue(VUF:GetUnitConfig(savedUnit).healthTextFormat)
    healthFormat:SetRelativeWidth(0.5)
    healthFormat:SetCallback("OnValueChanged", function(_, _, value) save("healthTextFormat", value) end)
    container:AddChild(healthFormat)

    local powerFormat = AceGUI:Create("Dropdown")
    powerFormat:SetLabel("Power Text Format")
    powerFormat:SetList(POWER_FORMAT_LABELS)
    powerFormat:SetValue(VUF:GetUnitConfig(savedUnit).powerTextFormat)
    powerFormat:SetRelativeWidth(0.5)
    powerFormat:SetCallback("OnValueChanged", function(_, _, value) save("powerTextFormat", value) end)
    container:AddChild(powerFormat)

    local power = AceGUI:Create("CheckBox")
    power:SetLabel("Show Power Text")
    power:SetValue(getSaved(savedUnit, "showPowerText") ~= false)
    power:SetRelativeWidth(0.5)
    power:SetCallback("OnValueChanged", function(_, _, value) save("showPowerText", value) end)
    container:AddChild(power)
end

local function addAuraSettings(container, unit)
    local savedUnit = settingUnit(unit)
    if not hasAuras(unit) then
        local note = AceGUI:Create("Label")
        note:SetText("|cff888888Compact frames do not show aura rows.|r")
        note:SetFullWidth(true)
        container:AddChild(note)
        return
    end

    local anchors = {
        TOPLEFT = "Top Left", TOPRIGHT = "Top Right",
        BOTTOMLEFT = "Bottom Left", BOTTOMRIGHT = "Bottom Right",
    }

    local function addSlider(target, label, key, low, high, default)
        local control = AceGUI:Create("Slider")
        control:SetLabel(label)
        control:SetSliderValues(low, high, 1)
        control:SetValue(getSaved(savedUnit, key) or default)
        control:SetFullWidth(true)
        control:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, key, math.floor(value), VUF.ApplyUnitAuras)
            VUF:RefreshUnitPreview(unit)
        end)
        target:AddChild(control)
    end

    local function addAuraControls(target, title, prefix, countDefault, yDefault)
        addSlider(target, "Icon Size", prefix .. "Size", 12, 48, 22)
        addSlider(target, "Icon Spacing", prefix .. "Spacing", 0, 12, 2)
        addSlider(target, "Maximum " .. title, prefix .. "Count", 1, 40, countDefault)

        local anchor = AceGUI:Create("Dropdown")
        anchor:SetLabel("Position")
        anchor:SetList(anchors)
        anchor:SetValue(getSaved(savedUnit, prefix .. "Anchor") or "BOTTOMLEFT")
        anchor:SetFullWidth(true)
        anchor:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, prefix .. "Anchor", value, VUF.ApplyUnitAuras)
            VUF:RefreshUnitPreview(unit)
        end)
        target:AddChild(anchor)

        addSlider(target, "X Offset", prefix .. "X", -400, 400, 0)
        addSlider(target, "Y Offset", prefix .. "Y", -400, 400, yDefault)
    end

    local previewToggle = AceGUI:Create("CheckBox")
    previewToggle:SetLabel("Preview Frame (auras, cast bar, bars)")
    previewToggle:SetValue(VUF:IsPreviewing(unit))
    previewToggle:SetFullWidth(true)
    previewToggle:SetCallback("OnValueChanged", function(widget, _, value)
        VUF:SetUnitPreview(unit, value)
        widget:SetValue(VUF:IsPreviewing(unit))
    end)
    container:AddChild(previewToggle)

    local buffs = AceGUI:Create("InlineGroup")
    buffs:SetTitle("Buffs")
    buffs:SetLayout("Flow")
    buffs:SetFullWidth(true)
    container:AddChild(buffs)

    local buffsVisible = AceGUI:Create("CheckBox")
    buffsVisible:SetLabel("Show Buffs")
    buffsVisible:SetValue(VUF:GetUnitConfig(savedUnit).showBuffs)
    buffsVisible:SetFullWidth(true)
    buffsVisible:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "showBuffs", value, VUF.ApplyUnitElements)
    end)
    buffs:AddChild(buffsVisible)

    addAuraControls(buffs, "Buffs", "buff", 16, 4)
    local ownBuffs = AceGUI:Create("CheckBox")
    ownBuffs:SetLabel("Only My Buffs")
    ownBuffs:SetValue(getSaved(savedUnit, "onlyPlayerBuffs") == true)
    ownBuffs:SetFullWidth(true)
    ownBuffs:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "onlyPlayerBuffs", value, VUF.ApplyUnitAuras)
    end)
    buffs:AddChild(ownBuffs)

    local debuffs = AceGUI:Create("InlineGroup")
    debuffs:SetTitle("Debuffs")
    debuffs:SetLayout("Flow")
    debuffs:SetFullWidth(true)
    container:AddChild(debuffs)

    local debuffsVisible = AceGUI:Create("CheckBox")
    debuffsVisible:SetLabel("Show Debuffs")
    debuffsVisible:SetValue(VUF:GetUnitConfig(savedUnit).showDebuffs)
    debuffsVisible:SetFullWidth(true)
    debuffsVisible:SetCallback("OnValueChanged", function(_, _, value)
        applySetting(unit, "showDebuffs", value, VUF.ApplyUnitElements)
    end)
    debuffs:AddChild(debuffsVisible)

    addAuraControls(debuffs, "Debuffs", "debuff", 12, 30)
    if unit == "target" then
        local ownDebuffs = AceGUI:Create("CheckBox")
        ownDebuffs:SetLabel("Only My Debuffs")
        ownDebuffs:SetValue(getSaved(savedUnit, "onlyPlayerDebuffs") == true)
        ownDebuffs:SetFullWidth(true)
        ownDebuffs:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "onlyPlayerDebuffs", value, VUF.ApplyUnitAuras)
        end)
        debuffs:AddChild(ownDebuffs)
    end

    if unit == "player" or unit == "target" or unit == "focus" then
        addSpacer(container)
        addHeading(container, "Dispel Feedback")
        local feedback = AceGUI:Create("Dropdown")
        feedback:SetLabel("Dispellable Debuff Tracking")
        feedback:SetList({ color = "Frame Color", icon = "Icon", off = "Off" })
        local savedFeedback = getSaved(savedUnit, "dispelFeedback")
        feedback:SetValue(savedFeedback or (getSaved(savedUnit, "dispelHighlight") ~= false and "color" or (getSaved(savedUnit, "dispelIcon") ~= false and "icon" or "off")))
        feedback:SetFullWidth(true)
        feedback:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "dispelFeedback", value, VUF.ApplyUnitOverlays)
        end)
        container:AddChild(feedback)

        local alpha = AceGUI:Create("Slider")
        alpha:SetLabel("Frame Color Opacity")
        alpha:SetSliderValues(0, 1, 0.05)
        alpha:SetValue(getSaved(savedUnit, "dispelAlpha") or 0.55)
        alpha:SetFullWidth(true)
        alpha:SetCallback("OnValueChanged", function(_, _, value)
            applySetting(unit, "dispelAlpha", value, VUF.ApplyUnitOverlays)
        end)
        container:AddChild(alpha)
    end
end

local function addFeedbackSettings(container, unit)
    local savedUnit = settingUnit(unit)

    local function save(key, value)
        applySetting(unit, key, value, VUF.ApplyUnitOverlays)
    end

    local function saveColor(widget, key)
        local function saveValue(_, _, r, g, b, a)
            save(key, { r, g, b, a })
        end
        widget:SetCallback("OnValueChanged", saveValue)
        widget:SetCallback("OnValueConfirmed", saveValue)
    end

    if unit ~= "target" then
        local targetGlow = AceGUI:Create("CheckBox")
        targetGlow:SetLabel("Target Glow")
        targetGlow:SetValue(getSaved(savedUnit, "targetGlow") ~= false)
        targetGlow:SetFullWidth(true)
        targetGlow:SetCallback("OnValueChanged", function(_, _, value) save("targetGlow", value) end)
        container:AddChild(targetGlow)

        local targetColor = getSaved(savedUnit, "targetGlowColor") or { 1, 1, 1, 0.9 }
        local targetGlowColor = AceGUI:Create("ColorPicker")
        targetGlowColor:SetLabel("Target Glow Color")
        targetGlowColor:SetColor(targetColor[1], targetColor[2], targetColor[3], targetColor[4])
        targetGlowColor:SetHasAlpha(true)
        targetGlowColor:SetFullWidth(true)
        saveColor(targetGlowColor, "targetGlowColor")
        container:AddChild(targetGlowColor)
    end

    local mouseoverGlow = AceGUI:Create("CheckBox")
    mouseoverGlow:SetLabel("Mouseover Glow")
    mouseoverGlow:SetValue(getSaved(savedUnit, "mouseoverGlow") ~= false)
    mouseoverGlow:SetFullWidth(true)
    mouseoverGlow:SetCallback("OnValueChanged", function(_, _, value) save("mouseoverGlow", value) end)
    container:AddChild(mouseoverGlow)

    local mouseoverColor = getSaved(savedUnit, "mouseoverGlowColor") or { 1, 0.9, 0.3, 0.8 }
    local mouseoverGlowColor = AceGUI:Create("ColorPicker")
    mouseoverGlowColor:SetLabel("Mouseover Glow Color")
    mouseoverGlowColor:SetColor(mouseoverColor[1], mouseoverColor[2], mouseoverColor[3], mouseoverColor[4])
    mouseoverGlowColor:SetHasAlpha(true)
    mouseoverGlowColor:SetFullWidth(true)
    saveColor(mouseoverGlowColor, "mouseoverGlowColor")
    container:AddChild(mouseoverGlowColor)


    if unit ~= "player" then
        local range = AceGUI:Create("Slider")
        range:SetLabel("Out-of-Range Opacity")
        range:SetSliderValues(0.1, 1, 0.05)
        range:SetValue(getSaved(savedUnit, "rangeAlpha") or 0.45)
        range:SetFullWidth(true)
        range:SetCallback("OnValueChanged", function(_, _, value) save("rangeAlpha", value) end)
        container:AddChild(range)
    end
end

local function addIndicatorSettings(container, unit)
    local boss = isBoss(unit)
    local savedUnit = settingUnit(unit)
    local function addIndicator(label, key)
        local control = AceGUI:Create("CheckBox")
        control:SetLabel(label)
        control:SetValue(getIndicator(savedUnit, key) ~= false)
        control:SetFullWidth(true)
        control:SetCallback("OnValueChanged", function(_, _, value)
            if boss then
                applyBossIndicator(key, value)
                VUF:ApplyBossLayouts()
            else
                setIndicator(unit, key, value)
                VUF:ApplyUnitIndicators(unit)
            end
        end)
        container:AddChild(control)
    end

    addIndicator("Raid Target Marker", "raidMarker")
    if unit == "player" or unit == "target" then
        addIndicator("Leader Icon", "leader")
        addIndicator("Assistant Icon", "assistant")
        addIndicator("Combat Icon", "combat")
    end
    if unit == "player" then
        addIndicator("Resting Icon", "resting")
        addIndicator("PvP Icon", "pvp")
    end
    if unit == "target" or unit == "focus" then
        addIndicator("Quest Icon", "quest")
        addIndicator("Classification Text", "classification")
    end
end

local function addUnitTab(container, unit)
    local title = isBoss(unit) and "Boss Frames (applies to boss1..boss8)" or (unit:sub(1, 1):upper() .. unit:sub(2))

    local sections = {
        { text = "Layout", value = "layout" },
        { text = "Bars", value = "bars" },
        { text = "Text", value = "text" },
        { text = "Feedback", value = "feedback" },
        { text = "Indicators", value = "indicators" },
    }
    if hasAuras(unit) then table.insert(sections, 3, { text = "Buffs & Debuffs", value = "auras" }) end

    local sectionTitles = {}
    for _, section in ipairs(sections) do sectionTitles[section.value] = section.text end

    local builders = {
        layout = addLayoutSettings,
        bars = addBarsSettings,
        text = addTextSettings,
        auras = addAuraSettings,
        feedback = addFeedbackSettings,
        indicators = addIndicatorSettings,
    }

    local tabs = AceGUI:Create("TabGroup")
    tabs:SetLayout("Fill")
    tabs:SetAutoAdjustHeight(false)
    tabs:SetTabs(sections)
    tabs:SetFullWidth(true)
    tabs:SetFullHeight(true)
    tabs:SetCallback("OnGroupSelected", function(panel, _, section)
        panel:ReleaseChildren()
        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("Flow")
        scroll:SetFullWidth(true)
        scroll:SetFullHeight(true)
        closeDropdownOnScroll(scroll)
        panel:AddChild(scroll)
        builders[section](scroll, unit)
    end)
    container:AddChild(tabs)
    tabs:SelectTab("layout")
end

local function addProfilesTab(container)
    addHeading(container, "Profiles")
    addSpacer(container, 4)

    local profiles = VUF.db:GetProfiles()
    local profileList = {}
    for _, name in ipairs(profiles) do profileList[name] = name end

    local current = AceGUI:Create("Label")
    current:SetText("Current profile: " .. VUF.db:GetCurrentProfile())
    current:SetFullWidth(true)
    container:AddChild(current)

    local selector = AceGUI:Create("Dropdown")
    selector:SetLabel("Switch Profile")
    selector:SetList(profileList)
    selector:SetValue(VUF.db:GetCurrentProfile())
    selector:SetFullWidth(true)
    selector:SetCallback("OnValueChanged", function(_, _, name) VUF.db:SetProfile(name) end)
    container:AddChild(selector)

    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel("New Profile Name")
    nameBox:SetFullWidth(true)
    container:AddChild(nameBox)

    local create = AceGUI:Create("Button")
    create:SetText("Create / Switch")
    create:SetFullWidth(true)
    create:SetCallback("OnClick", function()
        local name = nameBox:GetText():match("^%s*(.-)%s*$")
        if name ~= "" then VUF.db:SetProfile(name); VUF:OpenConfigWindow() end
    end)
    container:AddChild(create)

    local copy = AceGUI:Create("Button")
    copy:SetText("Copy Current Profile")
    copy:SetFullWidth(true)
    copy:SetCallback("OnClick", function()
        local name = nameBox:GetText():match("^%s*(.-)%s*$")
        if name ~= "" then
            local source = VUF.db:GetCurrentProfile()
            VUF.db:SetProfile(name)
            VUF.db:CopyProfile(source)
        end
    end)
    container:AddChild(copy)

    local reset = AceGUI:Create("Button")
    reset:SetText("Reset Active Profile")
    reset:SetFullWidth(true)
    reset:SetCallback("OnClick", function() VUF.db:ResetProfile() end)
    container:AddChild(reset)

    local export = AceGUI:Create("MultiLineEditBox")
    export:SetLabel("Export (copy this text)")
    export:SetText(VUF:ExportProfile())
    export:SetFullWidth(true)
    export:SetNumLines(5)
    export:SetCallback("OnTextChanged", function() end)
    container:AddChild(export)

    local import = AceGUI:Create("MultiLineEditBox")
    import:SetLabel("Import string")
    import:SetFullWidth(true)
    import:SetNumLines(5)
    container:AddChild(import)

    local importName = AceGUI:Create("EditBox")
    importName:SetLabel("Import As Profile")
    importName:SetFullWidth(true)
    container:AddChild(importName)

    local importButton = AceGUI:Create("Button")
    importButton:SetText("Import as New Profile")
    importButton:SetFullWidth(true)
    importButton:SetCallback("OnClick", function()
        local ok, err = VUF:ImportProfile(import:GetText(), importName:GetText())
        print("|cFF8080FFV1tushaUnitFrames|r: " .. (ok and "profile imported" or err))
    end)
    container:AddChild(importButton)

    local note = AceGUI:Create("Label")
    note:SetText("|cff888888Profiles are manual; specialization switching is not automatic yet.|r")
    note:SetFullWidth(true)
    container:AddChild(note)
end
local function addColoursSettings(container)
    local POWER_NAMES = VUF.POWER_NAMES or {}
    local REACTION_NAMES = VUF.REACTION_NAMES or {}

    local function getColours()
        return VUF:GetColours()
    end

    local function saveColours()
        VUF:LoadCustomColours()
    end

    local function addColorRow(container, title, key, colorTable, index)
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")
        container:AddChild(row)

        local label = AceGUI:Create("Label")
        label:SetText(title)
        label:SetWidth(180)
        row:AddChild(label)

        local color = colorTable[index]
        local colorPicker = AceGUI:Create("ColorPicker")
        colorPicker:SetColor(color[1], color[2], color[3], 1)
        colorPicker:SetHasAlpha(false)
        colorPicker:SetWidth(120)
        colorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b)
            colorTable[index] = { r, g, b }
            saveColours()
        end)
        row:AddChild(colorPicker)
    end

    local colours = getColours()

    addHeading(container, "Power Colors")
    for powerType, name in pairs(POWER_NAMES) do
        if colours.Power[powerType] then
            addColorRow(container, name, "Power", colours.Power, powerType)
        end
    end

    addSpacer(container, 8)
    addHeading(container, "Secondary Power Colors")
    for powerType, name in pairs(POWER_NAMES) do
        if colours.SecondaryPower[powerType] then
            addColorRow(container, name, "SecondaryPower", colours.SecondaryPower, powerType)
        end
    end

    addSpacer(container, 8)
    addHeading(container, "Dispel Colors")
    for dispelType, color in pairs(colours.Dispel) do
        local title = dispelType .. " (" .. (dispelType == "Bleed" and "Physical" or dispelType) .. ")"
        addColorRow(container, title, "Dispel", colours.Dispel, dispelType)
    end

    addSpacer(container, 8)
    addHeading(container, "Reaction Colors")
    for reaction, color in pairs(colours.Reaction) do
        local title = REACTION_NAMES[reaction] or "Reaction " .. reaction
        addColorRow(container, title, "Reaction", colours.Reaction, reaction)
    end

    addSpacer(container, 12)
    local note = AceGUI:Create("Label")
    note:SetText("|cff888888Colors apply immediately. Requires /reload to see changes in some cases.|r")
    note:SetFullWidth(true)
    container:AddChild(note)
end

local function addGeneralTab(container)
    addHeading(container, "General")
    addSpacer(container, 4)

    local actions = AceGUI:Create("InlineGroup")
    actions:SetTitle("Actions")
    actions:SetLayout("Flow")
    actions:SetFullWidth(true)
    container:AddChild(actions)

    local reset = AceGUI:Create("Button")
    reset:SetText("Reset All Positions")
    reset:SetRelativeWidth(0.33)
    reset:SetCallback("OnClick", function() VUF:ResetPositions() end)
    actions:AddChild(reset)

    local resetColours = AceGUI:Create("Button")
    resetColours:SetText("Reset All Colours")
    resetColours:SetRelativeWidth(0.34)
    resetColours:SetCallback("OnClick", function()
        VUF:ResetColours()
        container:ReleaseChildren()
        addGeneralTab(container)
    end)
    actions:AddChild(resetColours)

    local wipe = AceGUI:Create("Button")
    wipe:SetText("Reset Active Profile")
    wipe:SetRelativeWidth(0.33)
    wipe:SetCallback("OnClick", function()
        VUF.db:ResetProfile()
        print("|cFF8080FFV1tushaUnitFrames|r: active profile reset.")
    end)
    actions:AddChild(wipe)

    addSpacer(container, 12)

    local uiScale = VUF:GetUIScale()
    local scaleGroup = AceGUI:Create("InlineGroup")
    scaleGroup:SetTitle("UI Scale")
    scaleGroup:SetLayout("Flow")
    scaleGroup:SetFullWidth(true)
    container:AddChild(scaleGroup)

    local enabled = AceGUI:Create("CheckBox")
    enabled:SetLabel("Enable UI Scale")
    enabled:SetValue(uiScale.Enabled)
    enabled:SetRelativeWidth(0.33)
    enabled:SetCallback("OnValueChanged", function(_, _, value)
        uiScale.Enabled = value
        VUF:SetUIScale()
    end)
    scaleGroup:AddChild(enabled)

    local slider = AceGUI:Create("Slider")
    slider:SetLabel("Scale")
    slider:SetSliderValues(0.3, 1.5, 0.01)
    slider:SetValue(uiScale.Scale)
    slider:SetRelativeWidth(0.67)
    slider:SetCallback("OnValueChanged", function(_, _, value)
        uiScale.Scale = value
        VUF:SetUIScale()
    end)
    scaleGroup:AddChild(slider)

    local function addScalePreset(label, value)
        local button = AceGUI:Create("Button")
        button:SetText(label)
        button:SetRelativeWidth(0.33)
        button:SetCallback("OnClick", function()
            uiScale.Enabled = true
            uiScale.Scale = value
            VUF:SetUIScale()
            enabled:SetValue(true)
            slider:SetValue(value)
        end)
        scaleGroup:AddChild(button)
    end

    addScalePreset("Pixel Perfect", VUF:GetPixelPerfectScale())
    addScalePreset("1080p", 0.7111111111)
    addScalePreset("1440p", 0.5333333333)

    addSpacer(container, 12)

    local colours = AceGUI:Create("InlineGroup")
    colours:SetTitle("Colours")
    colours:SetLayout("Flow")
    colours:SetFullWidth(true)
    container:AddChild(colours)
    addColoursSettings(colours)

    addSpacer(container, 12)
    addCooldownTextSettings(container)

    addSpacer(container, 12)
    local hint = AceGUI:Create("Label")
    hint:SetText("|cff888888UI Scale applies immediately and is saved to the current profile. Some Blizzard windows may require /reload.|r")
    hint:SetFullWidth(true)
    container:AddChild(hint)
end


local function addVisualsTab(container)
    addHeading(container, "Visuals (all frames)")
    addSpacer(container, 4)

    local function save(key, value)
        VUF:SetVisual(key, value)
        VUF:ApplyVisuals()
    end

    local texture = AceGUI:Create("Dropdown")
    texture:SetLabel("Bar Texture")
    texture:SetList(VUF.BAR_TEXTURES)
    texture:SetValue(VUF:GetVisual("texture"))
    texture:SetFullWidth(true)
    texture:SetCallback("OnValueChanged", function(_, _, value) save("texture", value) end)
    container:AddChild(texture)

    local font = AceGUI:Create("Dropdown")
    font:SetLabel("Font")
    font:SetList(VUF.LSM:HashTable("font"))
    font:SetValue(VUF:GetVisual("font"))
    font:SetFullWidth(true)
    font:SetCallback("OnValueChanged", function(_, _, value) save("font", value) end)
    container:AddChild(font)

    local size = AceGUI:Create("Slider")
    size:SetLabel("Font Size")
    size:SetSliderValues(8, 22, 1)
    size:SetValue(VUF:GetVisual("fontSize"))
    size:SetFullWidth(true)
    size:SetCallback("OnValueChanged", function(_, _, value) save("fontSize", math.floor(value)) end)
    container:AddChild(size)

    local outline = AceGUI:Create("Dropdown")
    outline:SetLabel("Font Outline")
    outline:SetList(FONT_OUTLINES)
    outline:SetValue(VUF:GetVisual("fontOutline"))
    outline:SetFullWidth(true)
    outline:SetCallback("OnValueChanged", function(_, _, value) save("fontOutline", value) end)
    container:AddChild(outline)

    local healthFormat = AceGUI:Create("Dropdown")
    healthFormat:SetLabel("Health Text Format")
    healthFormat:SetList(HEALTH_FORMAT_LABELS)
    healthFormat:SetValue(VUF:GetVisual("healthFormat"))
    healthFormat:SetFullWidth(true)
    healthFormat:SetCallback("OnValueChanged", function(_, _, value) save("healthFormat", value) end)
    container:AddChild(healthFormat)

    addSpacer(container, 8)
    addHeading(container, "Dark Minimal Style")
    addSpacer(container, 4)

    local background = VUF:GetVisual("backgroundColor")
    local backgroundColor = AceGUI:Create("ColorPicker")
    backgroundColor:SetLabel("Bar Background")
    backgroundColor:SetColor(background[1], background[2], background[3], background[4])
    backgroundColor:SetHasAlpha(false)
    backgroundColor:SetFullWidth(true)
    backgroundColor:SetCallback("OnValueChanged", function(_, _, r, g, b) save("backgroundColor", { r, g, b, 1 }) end)
    container:AddChild(backgroundColor)

    local backgroundAlpha = AceGUI:Create("Slider")
    backgroundAlpha:SetLabel("Bar Background Opacity")
    backgroundAlpha:SetSliderValues(0, 1, 0.05)
    backgroundAlpha:SetValue(VUF:GetVisual("backgroundAlpha"))
    backgroundAlpha:SetFullWidth(true)
    backgroundAlpha:SetCallback("OnValueChanged", function(_, _, value) save("backgroundAlpha", value) end)
    container:AddChild(backgroundAlpha)

    addSpacer(container, 8)
    addHeading(container, "Border")
    addSpacer(container, 4)

    local borderSize = AceGUI:Create("Slider")
    borderSize:SetLabel("Border Thickness (0 = off)")
    borderSize:SetSliderValues(0, 4, 1)
    borderSize:SetValue(VUF:GetVisual("borderSize"))
    borderSize:SetFullWidth(true)
    borderSize:SetCallback("OnValueChanged", function(_, _, value) save("borderSize", math.floor(value)) end)
    container:AddChild(borderSize)

    local border = VUF:GetVisual("borderColor")
    local borderColor = AceGUI:Create("ColorPicker")
    borderColor:SetLabel("Border Color")
    borderColor:SetColor(border[1], border[2], border[3], border[4])
    borderColor:SetHasAlpha(true)
    borderColor:SetFullWidth(true)
    local function saveBorderColor(_, _, r, g, b, a)
        save("borderColor", { r, g, b, a })
    end
    borderColor:SetCallback("OnValueChanged", saveBorderColor)
    borderColor:SetCallback("OnValueConfirmed", saveBorderColor)
    container:AddChild(borderColor)

    addSpacer(container, 10)
    local apply = AceGUI:Create("Button")
    apply:SetText("Apply Appearance")
    apply:SetFullWidth(true)
    apply:SetCallback("OnClick", function() VUF:ApplyVisuals() end)
    container:AddChild(apply)
end

function VUF:OpenConfigWindow()
    if VUF.configWindow then VUF.configWindow:Show(); return end

    local frame = AceGUI:Create("Frame")
    VUF.configWindow = frame
    frame:SetTitle("V1tushaUnitFrames")
    frame:SetStatusText("v0.1.0 — /vuf для команд")
    frame:SetStatusTable({ width = 900, height = 650 })
    frame:SetWidth(900)
    frame:SetHeight(650)
    frame:EnableResize(false)
    frame:SetLayout("Fill")
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        VUF.configWindow = nil
    end)

    local root = AceGUI:Create("TreeGroup")
    root:SetLayout("Fill")
    root:SetFullWidth(true)
    root:SetFullHeight(true)
    root:SetTreeWidth(220, false)
    root:SetTree(UNIT_TABS)
    root:SetCallback("OnGroupSelected", function(widget, _, group)
        widget:ReleaseChildren()
        if group ~= "general" and group ~= "visuals" and group ~= "profiles" then
            addUnitTab(widget, group)
            return
        end

        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("Flow")
        scroll:SetFullWidth(true)
        scroll:SetFullHeight(true)
        closeDropdownOnScroll(scroll)
        widget:AddChild(scroll)
        if group == "general" then
            addGeneralTab(scroll)
        elseif group == "visuals" then
            addVisualsTab(scroll)
        else
            addProfilesTab(scroll)
        end
    end)
    frame:AddChild(root)
    root:SelectByValue("general")
end

