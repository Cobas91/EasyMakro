local ADDON_NAME, EM = ...
local L = EM.L

local MAX_MACRO_NAME_LEN = 16
local MAX_MACRO_BODY_LEN = 255

local function NormalizeMacroIcon(icon)
    if type(icon) == "number" then
        return icon
    end
    if type(icon) == "string" then
        return (icon:gsub("^Interface\\Icons\\", ""))
    end
    return "INV_Misc_QuestionMark"
end

-- entry = {
--   kind = "spell" | "command",
--   spellName, spellID,      -- für kind == "spell"
--   commandKey, commandLine,  -- für kind == "command" (commandLine
--                              -- überschreibt die Zeile aus Commands.lua,
--                              -- z.B. für dynamisch ermittelte Befehle)
--   opts = {
--     mouseoverHarm, mouseoverHelp, selfFallback,
--     autoAttack, petAttack, stopCasting,
--   },
-- }
function EM:BuildMacroBody(entry)
    local opts = entry.opts or {}
    local lines = {}

    if entry.kind == "spell" then
        table.insert(lines, "#showtooltip " .. entry.spellName)
    end

    if opts.stopCasting then
        table.insert(lines, "/stopcasting")
    end
    if opts.autoAttack then
        table.insert(lines, "/startattack")
    end
    if opts.petAttack then
        table.insert(lines, "/petattack")
    end

    if entry.kind == "spell" then
        local conditions = {}
        if opts.mouseoverHarm then
            table.insert(conditions, "@mouseover,harm,nodead")
        end
        if opts.mouseoverHelp then
            table.insert(conditions, "@mouseover,help,nodead")
        end
        if opts.selfFallback then
            table.insert(conditions, "@player")
        else
            table.insert(conditions, "")
        end

        if #conditions == 1 and conditions[1] == "" then
            table.insert(lines, "/cast " .. entry.spellName)
        else
            table.insert(lines, "/cast [" .. table.concat(conditions, "][") .. "] " .. entry.spellName)
        end
    elseif entry.kind == "command" then
        local line = entry.commandLine
        if not line then
            local cmd = self:GetCommandByKey(entry.commandKey)
            line = cmd and cmd.line
        end
        if line then
            table.insert(lines, line)
        end
    end

    return table.concat(lines, "\n")
end

-- Findet einen freien, bis zu 16 Zeichen langen Makronamen. ignoreName darf
-- kollidieren (wird beim Bearbeiten eines bestehenden Makros benutzt).
function EM:MakeUniqueMacroName(baseName, ignoreName)
    baseName = baseName ~= "" and baseName or "EasyMakro"
    local truncated = baseName:sub(1, MAX_MACRO_NAME_LEN)
    local candidate = truncated
    local suffix = 1
    while true do
        if candidate == ignoreName then
            return candidate
        end
        local existingIndex = GetMacroIndexByName(candidate)
        if existingIndex == 0 then
            return candidate
        end
        local suffixStr = tostring(suffix)
        candidate = truncated:sub(1, MAX_MACRO_NAME_LEN - #suffixStr) .. suffixStr
        suffix = suffix + 1
    end
end

local function CopyOpts(opts)
    local copy = {}
    for k, v in pairs(opts or {}) do
        copy[k] = v
    end
    return copy
end

-- Erstellt oder aktualisiert (existingName gesetzt) ein echtes WoW-Makro und
-- merkt sich die verwendeten Optionen in der SavedVariable zum späteren
-- Bearbeiten. Gibt (name) oder (nil, Fehlermeldung) zurück.
function EM:SaveMacro(entry, existingName)
    local body = self:BuildMacroBody(entry)
    if #body > MAX_MACRO_BODY_LEN then
        return nil, string.format(L.ERR_TOO_LONG, #body, MAX_MACRO_BODY_LEN)
    end

    local defaultBaseName = entry.spellName
    if entry.kind == "command" then
        local cmd = self:GetCommandByKey(entry.commandKey)
        defaultBaseName = (cmd and cmd.name) or entry.commandName or "EasyMakro"
    end

    local requestedName = (entry.customName and entry.customName ~= "") and entry.customName or defaultBaseName
    local name = self:MakeUniqueMacroName(requestedName, existingName)
    local icon = NormalizeMacroIcon(entry.icon)
    local perChar = entry.perChar and true or nil

    -- Ob ein Makro "General" oder "Per Character" ist, wird nur bei der
    -- Erstellung festgelegt und lässt sich per EditMacro nicht mehr
    -- ändern. Hat der Nutzer die Kategorie gewechselt, muss das alte
    -- Makro gelöscht und neu angelegt werden.
    local existingWasPerChar = existingName and self.db.macros[existingName] and self.db.macros[existingName].perChar
    local categoryChanged = existingName and (existingWasPerChar and true or false) ~= (perChar and true or false)

    local index
    if existingName and not categoryChanged then
        index = EditMacro(existingName, name, icon, body)
    else
        if existingName and categoryChanged then
            DeleteMacro(existingName)
            self.db.macros[existingName] = nil
        end
        index = CreateMacro(name, icon, body, perChar)
    end

    if not index then
        return nil, L.ERR_SAVE_FAILED
    end

    if existingName and existingName ~= name then
        self.db.macros[existingName] = nil
    end

    self.db.macros[name] = {
        kind = entry.kind,
        spellName = entry.spellName,
        spellID = entry.spellID,
        commandKey = entry.commandKey,
        commandLine = entry.commandLine,
        commandName = entry.commandName,
        opts = CopyOpts(entry.opts),
        perChar = entry.perChar and true or false,
        icon = entry.icon,
    }

    return name
end

function EM:DeleteManagedMacro(name)
    DeleteMacro(name)
    if self.db and self.db.macros then
        self.db.macros[name] = nil
    end
end
