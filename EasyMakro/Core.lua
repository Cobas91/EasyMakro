local ADDON_NAME, EM = ...

EasyMakro = EM
EM.name = ADDON_NAME

local defaults = {
    macros = {}, -- [macroName] = { kind, spellName, spellID, commandKey, opts, perChar, icon }
}

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= ADDON_NAME then return end

    EasyMakroDB = EasyMakroDB or {}
    for key, value in pairs(defaults) do
        if EasyMakroDB[key] == nil then
            EasyMakroDB[key] = value
        end
    end
    EM.db = EasyMakroDB

    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_EASYMAKRO1 = "/easymakro"
SLASH_EASYMAKRO2 = "/em"
SlashCmdList["EASYMAKRO"] = function()
    if EM.UI and EM.UI.Toggle then
        EM.UI.Toggle()
    end
end
