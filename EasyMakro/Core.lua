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

    if EM.InitMinimapButton then
        EM.InitMinimapButton()
    end

    self:UnregisterEvent("ADDON_LOADED")
end)

local function DebugDump(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffEasyMakro:|r " .. msg)
end

-- Temporaerer Diagnose-Befehl: zeigt die rohen Spellbook-Tabs und die
-- Skill-Liste des Charakters, um die Berufe-Filterung zuverlaessig gegen
-- echte Client-Daten abzugleichen (statt gegen Annahmen).
local function RunDebugDump()
    DebugDump("--- Spellbook tabs ---")
    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local tabName, _, offset, numSlots = GetSpellTabInfo(tabIndex)
        DebugDump(string.format("Tab %d: name='%s' offset=%d numSlots=%d", tabIndex, tostring(tabName), offset or -1, numSlots or -1))
    end

    DebugDump("--- Skill lines ---")
    local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
    for i = 1, numSkills do
        local skillName, isHeader = GetSkillLineInfo(i)
        DebugDump(string.format("Skill %d: name='%s' isHeader=%s", i, tostring(skillName), tostring(isHeader)))
    end
end

SLASH_EASYMAKRO1 = "/easymakro"
SLASH_EASYMAKRO2 = "/em"
SlashCmdList["EASYMAKRO"] = function(msg)
    if msg == "debug" then
        RunDebugDump()
        return
    end
    if EM.UI and EM.UI.Toggle then
        EM.UI.Toggle()
    end
end
