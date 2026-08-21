local ADDON_NAME, EM = ...
local L = EM.L

local function IsPassive(index, bookType)
    return IsPassiveSpell and IsPassiveSpell(index, bookType)
end

-- Laut "/em debug"-Auswertung haben Berufe in Classic Era gar keinen
-- eigenen Spellbook-Tab - Leatherworking/Skinning stecken als ganz normale
-- Eintraege mit im "General"-Tab, zusammen mit Attack/Auto Shot & Co. Ein
-- Filter auf Tab-Ebene kann sie deshalb prinzipiell nicht treffen; wir
-- brauchen die Namen einzeln, um sie unten pro Spell auszusortieren.
--
-- Die Kategorie "Class Skills" (Talentbaum-Namen wie Beast
-- Mastery/Marksmanship/Survival) steht laut Debug-Dump IMMER als erste
-- Kategorie in der Skill-Liste, gefolgt von Professions/Weapon
-- Skills/Armor Proficiencies/Languages. Wir ueberspringen deshalb nur die
-- erste Kategorie und sammeln die Namen aller danach folgenden Skills -
-- das deckt Berufe ab, ohne auf einen lokalisierten Kategorie-Text
-- angewiesen zu sein.
local function GetProfessionSkillNames()
    local names = {}
    local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
    local headerCount = 0
    for i = 1, numSkills do
        local skillName, isHeader = GetSkillLineInfo(i)
        if isHeader then
            headerCount = headerCount + 1
        elseif headerCount > 1 and skillName then
            names[skillName] = true
        end
    end
    return names
end

-- Liefert alle aktuell erlernten, aktiven (nicht-passiven) Zauber des
-- Spielers sowie ggf. des aktuellen Begleiters. Berufs-Faehigkeiten
-- (Alchemie, Erste Hilfe, Kuerschnern, ...) werden ausgeklammert, auch
-- wenn sie im selben Tab wie z.B. Attack/Auto Shot stecken.
function EM:GetKnownSpells()
    local spells = {}
    local seen = {}
    local professionNames = GetProfessionSkillNames()

    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tabIndex)
        offset = offset or 0
        numSlots = numSlots or 0
        for i = offset + 1, offset + numSlots do
            local itemType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
            if itemType == "SPELL" and not IsPassive(i, BOOKTYPE_SPELL) then
                local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
                if name and not professionNames[name] and not seen[name] then
                    seen[name] = true
                    local icon = GetSpellBookItemTexture(i, BOOKTYPE_SPELL)
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

-- Sucht im Spellbook nach dem Fernkampf-Autoattacke-Zauber (Auto Shot bei
-- Hunter, Shoot bei anderen Klassen mit Fernwaffe). Die eingebaute API
-- IsRangedAutoAttackSpell identifiziert ihn unabhaengig von Klasse und
-- Client-Sprache, sodass wir den Namen nicht selbst uebersetzen muessen.
local function FindRangedAutoAttackSpell()
    if not IsRangedAutoAttackSpell then return nil end

    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local _, _, offset, numSlots = GetSpellTabInfo(tabIndex)
        offset = offset or 0
        numSlots = numSlots or 0
        for i = offset + 1, offset + numSlots do
            local itemType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
            if itemType == "SPELL" and spellID and IsRangedAutoAttackSpell(spellID) then
                local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
                local icon = GetSpellBookItemTexture(i, BOOKTYPE_SPELL)
                if name then
                    return name, icon
                end
            end
        end
    end
    return nil
end

-- Oeffentlicher Zugriff fuer MacroBuilder/UI: Name des
-- Fernkampf-Autoattacke-Zaubers, falls der Charakter einen hat.
function EM:GetRangedAutoAttackSpellName()
    return (FindRangedAutoAttackSpell())
end

-- Kombiniert die Befehle (Commands.lua), den dynamisch gefundenen
-- Fernkampf-Autoattacke-Befehl und die bekannten Zauber zu einer
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

    local autoShotName, autoShotIcon = FindRangedAutoAttackSpell()
    if autoShotName then
        table.insert(items, {
            kind = "command",
            name = string.format(L.CMD_AUTOSHOT_LABEL, autoShotName),
            icon = autoShotIcon,
            commandKey = "AUTOSHOT",
            commandLine = "/cast " .. autoShotName,
            commandName = string.format(L.CMD_AUTOSHOT_LABEL, autoShotName),
        })
    end

    for _, spell in ipairs(self:GetKnownSpells()) do
        table.insert(items, spell)
    end

    return items
end
