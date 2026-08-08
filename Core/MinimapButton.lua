local _, VUF = ...

local RADIUS = 102

local function getAngle()
    local profile = VUF:GetProfileData()
    return profile.minimapAngle or -45
end

local function place(button)
    local angle = math.rad(getAngle())
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

function VUF:CreateMinimapButton()
    if VUF.minimapButton then return end

    local button = CreateFrame("Button", "V1tushaUnitFramesMinimapButton", Minimap)
    button:SetSize(36, 36)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetPoint("BOTTOMRIGHT", -6, 6)
    icon:SetColorTexture(0.1, 0.75, 0.55, 1)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("V")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(36, 36)
    border:SetPoint("CENTER")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function()
        VUF:OpenConfigWindow()
    end)
    button:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self.dragging = true
    end)
    button:SetScript("OnDragStop", function(self)
        if not self.dragging then return end
        self.dragging = nil
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
        VUF:GetProfileData().minimapAngle = angle
        place(self)
    end)
    button:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        VUF:GetProfileData().minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
        place(self)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("V1tushaUnitFrames")
        GameTooltip:AddLine("Left-click: open settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    VUF.minimapButton = button
    place(button)
end

function VUF:UpdateMinimapButton()
    if VUF.minimapButton then place(VUF.minimapButton) end
end
