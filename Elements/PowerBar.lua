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

    pb.colorPower = true
    pb.frequentUpdates = true

    frame.Power = pb
end
