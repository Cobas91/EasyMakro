local ADDON_NAME, EM = ...

local function IsPassive(index, bookType)
    return IsPassiveSpell and IsPassiveSpell(index, bookType)
end

-- Liefert alle aktuell erlernten, aktiven (nicht-passiven) Zauber des
-- Spielers sowie ggf. des aktuellen Begleiters.
function EM:GetKnownSpells()
    local spells = {}
    local seen = {}

    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tabIndex)
        offset = offset or 0
        numSlots = numSlots or 0
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
-- einzigen, nach Typ und Name sortierten Liste fuer die UI.
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
