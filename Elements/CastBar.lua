local _, VUF = ...

local SHIELD_TEX = [[Interface\CastingBar\UI-CastingBar-Small-Shield]]

local COLOR_CAST    = { 0.8, 0.7, 0.2 }
local COLOR_CHANNEL = { 0.2, 0.6, 0.9 }

local function colorForCast(cb)
    local c = cb.channeling and COLOR_CHANNEL or COLOR_CAST
    cb:SetStatusBarColor(c[1], c[2], c[3])
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

    cb.PostCastStart = colorForCast
    cb.PostChannelStart = colorForCast

    frame.Castbar = cb
end
