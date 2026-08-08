local _, VUF = ...

local function hookEditMode()
    if not EditModeManagerFrame then return end

    EditModeManagerFrame:HookScript("OnShow", function()
        if not InCombatLockdown() then VUF:ShowEditModeMovers() end
    end)
    EditModeManagerFrame:HookScript("OnHide", VUF.HideEditModeMovers)
end

hookEditMode()
