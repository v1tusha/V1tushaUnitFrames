local _, VUF = ...

function VUF:CreatePowerBar(frame)
    local tex = VUF:GetTexturePath()
    local pb = CreateFrame("StatusBar", nil, frame)
    pb:SetStatusBarTexture(tex)

    local bg = pb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(tex)
    bg:SetVertexColor(unpack(VUF:GetVisual("backgroundColor")))
    bg:SetAlpha(VUF:GetVisual("backgroundAlpha"))
    pb.bg = bg

    local text = pb:CreateFontString(nil, "OVERLAY")
    VUF:ApplyFont(text)
    text:SetPoint("CENTER")
    pb.Value = text

    pb.colorPower = true
    pb.frequentUpdates = true

    frame.Power = pb
    frame:Tag(text, VUF.POWER_FORMATS.full)
end
