local _, VUF = ...

function VUF:CreateAdditionalPower(frame)
    local texture = VUF:GetTexturePath()
    local ap = CreateFrame("StatusBar", nil, frame)
    ap:SetStatusBarTexture(texture)

    local bg = ap:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(texture)
    local color = VUF:GetVisual("backgroundColor")
    bg:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    bg:SetAlpha(VUF:GetVisual("backgroundAlpha"))
    ap.bg = bg

    local text = ap:CreateFontString(nil, "OVERLAY")
    VUF:ApplyFont(text)
    text:SetPoint("CENTER")
    ap.Value = text

    ap.colorPower = true
    ap.frequentUpdates = true

    frame.AdditionalPower = ap
    frame:Tag(text, "[curpp] / [maxpp]")
end
