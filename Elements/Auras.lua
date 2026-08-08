local _, VUF = ...

local DEFAULT_BREAKPOINTS = {
    { threshold = 0, style = "decimalSeconds", color = { 1, 1, 1, 1 } },
    { threshold = 3, style = "secondsOnly", color = { 1, 1, 1, 1 } },
    { threshold = 60, style = "clock", color = { 1, 1, 1, 1 } },
    { threshold = 120, style = "minutes", color = { 1, 1, 1, 1 } },
    { threshold = 3600, style = "hours", color = { 1, 1, 1, 1 } },
}

local STYLE_FORMATS = {
    decimalSeconds = { step = 0.1, format = "%.1f" },
    seconds = { step = 1, format = "%ds" },
    secondsOnly = { step = 1, format = "%d" },
    clock = { step = 1, format = "%d:%02d" },
    minutes = { step = 1, format = "%dm" },
    hours = { step = 1, format = "%dh" },
    days = { step = 1, format = "%dd" },
}

local formatter = C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and C_StringUtil.CreateNumericRuleFormatter()

local function getComponents(style, threshold)
    if style == "clock" then
        if threshold >= 86400 then return { { div = 86400 }, { div = 3600, mod = 24 } } end
        if threshold >= 3600 then return { { div = 3600 }, { div = 60, mod = 60 } } end
        return { { div = 60 }, { mod = 60 } }
    elseif style == "minutes" then
        return { { div = 60 } }
    elseif style == "hours" then
        return { { div = 3600 } }
    elseif style == "days" then
        return { { div = 86400 } }
    end
end

local function colorCode(color)
    return "ff" .. string.format("%02x%02x%02x", (color[1] or 1) * 255, (color[2] or 1) * 255, (color[3] or 1) * 255)
end

function VUF:GetCooldownText()
    local profile = VUF:GetProfileData()
    profile.general = profile.general or {}
    profile.general.CooldownText = profile.general.CooldownText or {}
    local settings = profile.general.CooldownText
    settings.FontSize = tonumber(settings.FontSize) or 12
    settings.Breakpoints = settings.Breakpoints or {}
    for i, defaults in ipairs(DEFAULT_BREAKPOINTS) do
        local breakpoint = settings.Breakpoints[i]
        if type(breakpoint) ~= "table" then
            breakpoint = { threshold = defaults.threshold, style = defaults.style, color = { unpack(defaults.color) } }
            settings.Breakpoints[i] = breakpoint
        end
        breakpoint.threshold = tonumber(breakpoint.threshold) or defaults.threshold
        breakpoint.style = STYLE_FORMATS[breakpoint.style] and breakpoint.style or defaults.style
        breakpoint.color = type(breakpoint.color) == "table" and breakpoint.color or { unpack(defaults.color) }
    end
    return settings
end

function VUF:RefreshCooldownText()
    local settings = VUF:GetCooldownText()
    if formatter then
        local rules = {}
        for i, breakpoint in ipairs(settings.Breakpoints) do
            local style = STYLE_FORMATS[breakpoint.style]
            rules[i] = {
                threshold = breakpoint.threshold,
                step = style.step,
                rounding = Enum.NumericRuleFormatRounding.Up,
                format = "|c" .. colorCode(breakpoint.color) .. style.format .. "|r",
                components = getComponents(breakpoint.style, breakpoint.threshold),
            }
        end
        formatter:SetBreakpoints(rules)
    end

    for _, frame in pairs(VUF.frames or {}) do
        for _, container in ipairs({ frame.Buffs, frame.Debuffs }) do
            if container then
                for _, button in ipairs(container) do
                    if button.Cooldown and formatter and button.Cooldown.SetCountdownFormatter then
                        button.Cooldown:SetCountdownFormatter(formatter)
                        for _, region in ipairs({ button.Cooldown:GetRegions() }) do
                            if region:GetObjectType() == "FontString" then VUF:ApplyFont(region, settings.FontSize) end
                        end
                    end
                end
            end
        end
    end
end

local function applyCooldownText(button)
    VUF:ApplyCooldownFormatter(button.Cooldown)
end

function VUF:ApplyCooldownFormatter(cooldown)
    if not (formatter and cooldown and cooldown.SetCountdownFormatter) then return end
    cooldown:SetCountdownFormatter(formatter)
    local settings = VUF:GetCooldownText()
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then VUF:ApplyFont(region, settings.FontSize) end
    end
end

local function postCreateButton(_, button)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 0, 0, 1)

    if button.Icon then
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("TOPLEFT", 1, -1)
        button.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
        button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if button.Count then
        button.Count:SetFontObject(NumberFontNormal)
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", 2, 0)
    end
    applyCooldownText(button)
end

function VUF:CreateAuraContainer(frame, kind, opts)
    local c = CreateFrame("Frame", nil, frame)
    c.size            = opts.size or 22
    c.spacing         = opts.spacing or 2
    c.num             = opts.num or 12
    c.initialAnchor   = opts.initialAnchor or "BOTTOMLEFT"
    c.growthX         = opts.growthX or "RIGHT"
    c.growthY         = opts.growthY or "UP"
    c.maxCols         = opts.maxCols
    c.disableMouse    = false
    c.disableCooldown = false
    c.showDebuffType  = (kind == "Debuffs")
    c.showStealableBuffs = (kind == "Buffs")
    c.PostCreateButton = postCreateButton
    if opts.filter then c.filter = opts.filter end
    if opts.onlyShowPlayer then c.onlyShowPlayer = true end
    frame[kind] = c
    return c
end
