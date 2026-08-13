local _, VUF = ...

local addon = LibStub("AceAddon-3.0"):NewAddon("V1tushaUnitFrames")
VUF.addon = addon
-- VUF.oUF is set by Libraries/oUF/init.lua into our shared namespace

function addon:OnInitialize()
    VUF:InitializeProfiles()
    VUF:SetUIScale()
    VUF:LoadCustomColours()
    VUF:RefreshCooldownText()
    print("|cFF8080FFV1tushaUnitFrames|r loaded. Type /vuf")

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            VUF:CancelPreviews()
            return
        end
        if VUF.pendingProfileRefresh then
            VUF.pendingProfileRefresh = nil
            VUF:ApplyProfile()
            return
        end
        for unit in pairs(VUF.pendingLayouts or {}) do VUF:ApplyUnitLayout(unit) end
        VUF.pendingLayouts = nil
    end)
end

function addon:OnEnable()
    VUF:SpawnUnit("player")
    VUF:SpawnUnit("target")
    VUF:SpawnUnit("targettarget")
    VUF:SpawnUnit("focus")
    VUF:SpawnUnit("focustarget")
    VUF:SpawnUnit("pet")
    for i = 1, 8 do VUF:SpawnUnit("boss" .. i) end
end

SLASH_VUF1 = "/vuf"
SlashCmdList["VUF"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S+)")
    if cmd == "unlock" or cmd == "u" then
        VUF:ToggleMovers()
    elseif cmd == "lock" or cmd == "l" then
        if VUF.moversUnlocked then VUF:ToggleMovers() end
    elseif cmd == "reset" or cmd == "r" then
        VUF:ResetPositions()
    elseif cmd == "config" or cmd == "c" or cmd == nil then
        VUF:OpenConfigWindow()
    else
        -- Version lives in the .toc only, so a release bump cannot drift from the code.
        print("|cFF8080FFV1tushaUnitFrames|r v" .. (C_AddOns.GetAddOnMetadata("V1tushaUnitFrames", "Version") or "?"))
        print("  /vuf         — open config window")
        print("  /vuf unlock  — show movers, drag frames")
        print("  /vuf lock    — hide movers")
        print("  /vuf reset   — reset all positions to defaults")
    end
end
