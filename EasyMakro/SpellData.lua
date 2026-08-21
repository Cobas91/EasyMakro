local ADDON_NAME, EM = ...

local function IsPassive(index, bookType)
    return IsPassiveSpell and IsPassiveSpell(index, bookType)
end

-- Namen aller Skills, die im Skills-Fenster unter der Kategorie
-- "Berufe"/"Professions" stehen (Primär- und Sekundärberufe sowie
-- Sammelberufe wie Bergbau/Kräuterkunde/Kürschnern). Ihre Spellbook-Tabs
-- werden aus der Zauberliste ausgeschlossen.
local function GetProfessionTabNames()
    local names = {}
    local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
    local inProfessions = false
    for i = 1, numSkills do
        local skillName, isHeader = GetSkillLineInfo(i)
        if isHeader then
            inProfessions = (skillName == PROFESSIONS)
        elseif inProfessions and skillName then
            names[skillName] = true
        end
    end
    return names
end

-- Liefert alle aktuell erlernten, aktiven (nicht-passiven) Zauber des
-- Spielers sowie ggf. des aktuellen Begleiters. Berufs-Tabs (Alchemie,
-- Erste Hilfe, Kürschnern, ...) werden ausgeklammert.
function EM:GetKnownSpells()
    local spells = {}
    local seen = {}
    local professionTabs = GetProfessionTabNames()

    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local tabName, _, offset, numSlots = GetSpellTabInfo(tabIndex)
        offset = offset or 0
        numSlots = numSlots or 0
        if not professionTabs[tabName] then
            for i = offset + 1, offset + numSlots do
                local itemType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
                if itemType == "SPELL" and not IsPassive(i, BOOKTYPE_SPELL) then
                    local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
                    local icon = GetSpellBookItemTexture(i, BOOKTYPE_SPELL)
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(spells, {
                            kind = "spell",
                            name = name,
                            icon = icon,
                            spellID = spellID,
                            isPet = false,
                        })
                    end
                end
            end
        end
    end

    if HasPetSpells then
        local numPetSpells = HasPetSpells()
        if numPetSpells and numPetSpells > 0 then
            for i = 1, numPetSpells do
                local itemType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_PET)
                if itemType == "SPELL" and not IsPassive(i, BOOKTYPE_PET) then
                    local name = GetSpellBookItemName(i, BOOKTYPE_PET)
                    local icon = GetSpellBookItemTexture(i, BOOKTYPE_PET)
                    if name and not seen[name] then
                        seen[name] = true
                        table.insert(spells, {
                            kind = "spell",
                            name = name,
                            icon = icon,
                            spellID = spellID,
                            isPet = true,
                        })
                    end
                end
            end
        end
    end

    table.sort(spells, function(a, b) return a.name < b.name end)
    return spells
end

-- Kombiniert die Befehle (Commands.lua) und die bekannten Zauber zu einer
-- einzigen, nach Typ und Name sortierten Liste für die UI.
function EM:GetAllListItems()
    local items = {}

    for _, cmd in ipairs(self.Commands) do
        table.insert(items, {
            kind = "command",
            name = cmd.name,
            icon = cmd.icon,
            commandKey = cmd.key,
        })
    end

    for _, spell in ipairs(self:GetKnownSpells()) do
        table.insert(items, spell)
    end

    return items
end
