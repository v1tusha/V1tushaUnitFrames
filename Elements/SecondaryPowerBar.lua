local _, VUF = ...

local BAR_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]
local MAX_PIPS    = 10

local function classPowerPostUpdate(element, _, max)
    pcall(function()
        if not max or max == 0 then return end
        local frameWidth = element.__width
        local spacing    = element.__spacing
        local pipWidth   = (frameWidth - (max - 1) * spacing) / max
        for i = 1, max do
            local bar = element[i]
            bar:ClearAllPoints()
            bar:SetWidth(pipWidth)
            if i == 1 then
                bar:SetPoint("LEFT", element, "LEFT", 0, 0)
            else
                bar:SetPoint("LEFT", element[i-1], "RIGHT", spacing, 0)
            end
        end
    end)
end

local function addBorder(bar)
    for _, edge in ipairs({
        { "TOPLEFT", "TOPRIGHT", "h" }, { "BOTTOMLEFT", "BOTTOMRIGHT", "h" },
        { "TOPLEFT", "BOTTOMLEFT", "v" }, { "TOPRIGHT", "BOTTOMRIGHT", "v" },
    }) do
        local line = bar:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0, 0, 0, 1)
        if edge[3] == "h" then
            line:SetHeight(1)
        else
            line:SetWidth(1)
        end
        line:SetPoint(edge[1], bar, edge[1])
        line:SetPoint(edge[2], bar, edge[2])
    end
end

function VUF:CreateClassPower(frame, frameWidth, spacing)
    local texture = VUF:GetTexturePath()
    local background = VUF:GetVisual("backgroundColor")
    local container = CreateFrame("Frame", nil, frame)
    container.__width   = frameWidth
    container.__spacing = spacing or 2

    for i = 1, MAX_PIPS do
        local bar = CreateFrame("StatusBar", nil, container)
        bar:SetStatusBarTexture(texture)
        bar:SetMinMaxValues(0, 1)
        bar:SetHeight(10)

        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(texture)
        bg:SetVertexColor(background[1], background[2], background[3], background[4] or 1)
        bg:SetAlpha(VUF:GetVisual("backgroundAlpha"))
        bar.bg = bg
        addBorder(bar)

        container[i] = bar
    end

    container.PostUpdate = classPowerPostUpdate

    frame.ClassPower = container
    return container
end
