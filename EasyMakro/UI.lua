local ADDON_NAME, EM = ...

EM.UI = {}

local FRAME_WIDTH, FRAME_HEIGHT = 780, 560
local ROW_HEIGHT = 20

local frame
local listRows = {}
local macroRows = {}
local allItems = {}
local filteredItems = {}

local selectedItem = nil
local editingMacroName = nil

local iconTex, nameLabel, kindLabel
local cbMouseoverHarm, cbMouseoverHelp, cbSelfFallback
local cbAutoAttack, cbPetAttack, cbStopCasting, cbPerChar
local nameEdit, previewBox, saveButton, cancelButton, statusText
local searchBox, listScroll, listContent
local macroScroll, macroContent, macroHeader

--------------------------------------------------------------------------
-- Hilfsfunktionen
--------------------------------------------------------------------------

local function SetIconTexture(tex, icon)
    if type(icon) == "number" then
        tex:SetTexture(icon)
    elseif type(icon) == "string" then
        tex:SetTexture(icon)
    else
        tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

local checkboxCounter = 0
local function CreateCheckbox(parent, label)
    checkboxCounter = checkboxCounter + 1
    local cb = CreateFrame("CheckButton", "EasyMakroCheck" .. checkboxCounter, parent, "UICheckButtonTemplate")
    cb.text = _G[cb:GetName() .. "Text"]
    cb.text:SetText(label)
    cb.text:SetFontObject("GameFontHighlightSmall")
    return cb
end

local function GatherOpts()
    return {
        mouseoverHarm = cbMouseoverHarm:GetChecked() and true or false,
        mouseoverHelp = cbMouseoverHelp:GetChecked() and true or false,
        selfFallback = cbSelfFallback:GetChecked() and true or false,
        autoAttack = cbAutoAttack:GetChecked() and true or false,
        petAttack = cbPetAttack:GetChecked() and true or false,
        stopCasting = cbStopCasting:GetChecked() and true or false,
    }
end

local function BuildCurrentEntry()
    if not selectedItem then return nil end
    return {
        kind = selectedItem.kind,
        spellName = selectedItem.name,
        spellID = selectedItem.spellID,
        commandKey = selectedItem.commandKey,
        icon = selectedItem.icon,
        opts = GatherOpts(),
        perChar = cbPerChar:GetChecked() and true or false,
        customName = nameEdit:GetText(),
    }
end

local function UpdatePreview()
    if not selectedItem then
        previewBox:SetText("")
        return
    end
    local entry = BuildCurrentEntry()
    previewBox:SetText(EM:BuildMacroBody(entry))
end

local function SetStatus(msg, isError)
    statusText:SetText(msg or "")
    if isError then
        statusText:SetTextColor(1, 0.25, 0.25)
    else
        statusText:SetTextColor(0.6, 1, 0.6)
    end
end

--------------------------------------------------------------------------
-- Builder-Panel (rechte Seite)
--------------------------------------------------------------------------

local function RefreshBuilderPanel(item, macroName, storedOpts, storedPerChar)
    selectedItem = item
    editingMacroName = macroName

    if not item then
        iconTex:SetTexture(nil)
        nameLabel:SetText("Waehle links einen Zauber oder Befehl aus")
        kindLabel:SetText("")
        nameEdit:SetText("")
        saveButton:SetEnabled(false)
        cancelButton:Hide()
        previewBox:SetText("")
        return
    end

    SetIconTexture(iconTex, item.icon)
    nameLabel:SetText(item.name)
    kindLabel:SetText(item.kind == "spell" and (item.isPet and "Pet-Zauber" or "Zauber") or "Befehl")

    local opts = storedOpts or {}
    cbMouseoverHarm:SetChecked(opts.mouseoverHarm)
    cbMouseoverHelp:SetChecked(opts.mouseoverHelp)
    cbSelfFallback:SetChecked(opts.selfFallback)
    cbAutoAttack:SetChecked(opts.autoAttack)
    cbPetAttack:SetChecked(opts.petAttack)
    cbStopCasting:SetChecked(opts.stopCasting)
    cbPerChar:SetChecked(storedPerChar)

    -- Mouseover-/Selbst-Optionen ergeben nur bei echten Zaubern Sinn.
    local isSpell = item.kind == "spell"
    for _, cb in ipairs({ cbMouseoverHarm, cbMouseoverHelp, cbSelfFallback }) do
        if isSpell then
            cb:Enable()
        else
            cb:SetChecked(false)
            cb:Disable()
        end
    end

    nameEdit:SetText(macroName or EM:MakeUniqueMacroName(item.name))
    saveButton:SetEnabled(true)
    saveButton:SetText(macroName and "Makro aktualisieren" or "Makro erstellen")
    cancelButton:SetShown(macroName ~= nil)

    SetStatus("")
    UpdatePreview()
end

--------------------------------------------------------------------------
-- Linke Liste (Zauber & Befehle)
--------------------------------------------------------------------------

local function LayoutListRows()
    local shown = 0
    for _, row in ipairs(listRows) do
        row:Hide()
    end
    for i, item in ipairs(filteredItems) do
        local row = listRows[i]
        if not row then
            row = CreateFrame("Button", nil, listContent)
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("RIGHT", listContent, "RIGHT", -4, 0)
            row:SetPoint("LEFT", listContent, "LEFT", 0, 0)

            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", 2, 0)

            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.text:SetPoint("RIGHT", -2, 0)
            row.text:SetJustifyH("LEFT")

            row.highlight = row:CreateTexture(nil, "BACKGROUND")
            row.highlight:SetAllPoints()
            row.highlight:SetColorTexture(1, 1, 1, 0.08)
            row.highlight:Hide()

            row:SetScript("OnClick", function(self)
                RefreshBuilderPanel(self.item)
            end)
            row:SetScript("OnEnter", function(self) self.highlight:Show() end)
            row:SetScript("OnLeave", function(self) self.highlight:Hide() end)

            listRows[i] = row
        end

        row.item = item
        SetIconTexture(row.icon, item.icon)
        local prefix = item.kind == "command" and "|cff66ccff[Befehl]|r " or ""
        row.text:SetText(prefix .. item.name)
        row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:Show()
        shown = i
    end
    listContent:SetHeight(math.max(shown * ROW_HEIGHT, 1))
end

local function ApplyFilter()
    local query = searchBox:GetText():lower()
    wipe(filteredItems)
    for _, item in ipairs(allItems) do
        if query == "" or item.name:lower():find(query, 1, true) then
            table.insert(filteredItems, item)
        end
    end
    LayoutListRows()
end

local function RefreshSpellList()
    allItems = EM:GetAllListItems()
    ApplyFilter()
end

--------------------------------------------------------------------------
-- Verwaltete Makros (unten)
--------------------------------------------------------------------------

local function FindItemForMacro(data)
    if data.kind == "command" then
        for _, item in ipairs(allItems) do
            if item.kind == "command" and item.commandKey == data.commandKey then
                return item
            end
        end
        local cmd = EM:GetCommandByKey(data.commandKey)
        if cmd then
            return { kind = "command", name = cmd.name, icon = cmd.icon, commandKey = cmd.key }
        end
    else
        for _, item in ipairs(allItems) do
            if item.kind == "spell" and item.name == data.spellName then
                return item
            end
        end
        return { kind = "spell", name = data.spellName, icon = data.icon, spellID = data.spellID }
    end
    return nil
end

local function DeleteMacroConfirmed(name)
    EM:DeleteManagedMacro(name)
    if editingMacroName == name then
        RefreshBuilderPanel(nil)
    end
    EM.UI.RefreshMacroList()
end

StaticPopupDialogs["EASYMAKRO_DELETE_MACRO"] = {
    text = "EasyMakro-Makro '%s' wirklich loeschen?",
    button1 = "Loeschen",
    button2 = "Abbrechen",
    OnAccept = function(self, data)
        DeleteMacroConfirmed(data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function LayoutMacroRows()
    local names = {}
    for name in pairs(EM.db.macros) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, row in ipairs(macroRows) do
        row:Hide()
    end

    for i, name in ipairs(names) do
        local data = EM.db.macros[name]
        local row = macroRows[i]
        if not row then
            row = CreateFrame("Frame", nil, macroContent)
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("LEFT", macroContent, "LEFT", 0, 0)
            row:SetPoint("RIGHT", macroContent, "RIGHT", -4, 0)

            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", 2, 0)

            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
            row.text:SetJustifyH("LEFT")
            row.text:SetWidth(220)

            row.editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.editBtn:SetSize(90, 18)
            row.editBtn:SetPoint("RIGHT", -96, 0)
            row.editBtn:SetText("Bearbeiten")

            row.deleteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.deleteBtn:SetSize(90, 18)
            row.deleteBtn:SetPoint("RIGHT", -2, 0)
            row.deleteBtn:SetText("Loeschen")

            macroRows[i] = row
        end

        row.macroName = name
        SetIconTexture(row.icon, data.icon)
        local suffix = data.perChar and " |cff999999(Charakter)|r" or " |cff999999(Allgemein)|r"
        row.text:SetText(name .. suffix)

        row.editBtn:SetScript("OnClick", function()
            local item = FindItemForMacro(data)
            RefreshBuilderPanel(item, name, data.opts, data.perChar)
        end)
        row.deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("EASYMAKRO_DELETE_MACRO", name, nil, name)
        end)

        row:SetPoint("TOPLEFT", macroContent, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:Show()
    end

    macroContent:SetHeight(math.max(#names * ROW_HEIGHT, 1))
    macroHeader:SetText(string.format("Meine EasyMakro-Makros (%d)", #names))
end

function EM.UI.RefreshMacroList()
    LayoutMacroRows()
end

--------------------------------------------------------------------------
-- Frame-Aufbau
--------------------------------------------------------------------------

local function BuildFrame()
    frame = CreateFrame("Frame", "EasyMakroFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetToplevel(true)
    frame:SetFrameStrata("HIGH")
    frame:Hide()
    table.insert(UISpecialFrames, "EasyMakroFrame")

    frame.TitleText:SetText("EasyMakro")

    ----------------------------------------------------------------
    -- Linke Spalte: Suche + Liste
    ----------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, frame)
    leftPanel:SetPoint("TOPLEFT", 12, -32)
    leftPanel:SetSize(300, FRAME_HEIGHT - 210)

    searchBox = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
    searchBox:SetSize(270, 20)
    searchBox:SetPoint("TOPLEFT", 8, -6)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", ApplyFilter)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local searchHint = leftPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    searchHint:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 2, -2)
    searchHint:SetText("Suche nach Zauber- oder Befehlsname")

    listScroll = CreateFrame("ScrollFrame", "EasyMakroListScroll", leftPanel, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 0, -50)
    listScroll:SetPoint("BOTTOMRIGHT", -26, 2)

    listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(1, 1)
    listScroll:SetScrollChild(listContent)

    ----------------------------------------------------------------
    -- Rechte Spalte: Builder
    ----------------------------------------------------------------
    local rightPanel = CreateFrame("Frame", nil, frame)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 16, 0)
    rightPanel:SetPoint("BOTTOMRIGHT", -12, 210)

    iconTex = rightPanel:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(36, 36)
    iconTex:SetPoint("TOPLEFT", 4, -4)

    nameLabel = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    nameLabel:SetPoint("TOPLEFT", iconTex, "TOPRIGHT", 10, -2)
    nameLabel:SetPoint("RIGHT", -4, 0)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetText("Waehle links einen Zauber oder Befehl aus")

    kindLabel = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    kindLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)

    local optionsHeader = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    optionsHeader:SetPoint("TOPLEFT", iconTex, "BOTTOMLEFT", 0, -14)
    optionsHeader:SetText("Ausloesung")

    cbMouseoverHarm = CreateCheckbox(rightPanel, "Mouseover-Ziel verwenden (Gegner)")
    cbMouseoverHarm:SetPoint("TOPLEFT", optionsHeader, "BOTTOMLEFT", -2, -4)
    cbMouseoverHelp = CreateCheckbox(rightPanel, "Mouseover-Ziel verwenden (Freund/Heilung)")
    cbMouseoverHelp:SetPoint("TOPLEFT", cbMouseoverHarm, "BOTTOMLEFT", 0, -2)
    cbSelfFallback = CreateCheckbox(rightPanel, "Sonst auf mir selbst wirken")
    cbSelfFallback:SetPoint("TOPLEFT", cbMouseoverHelp, "BOTTOMLEFT", 0, -2)

    local extraHeader = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    extraHeader:SetPoint("TOPLEFT", cbSelfFallback, "BOTTOMLEFT", 2, -10)
    extraHeader:SetText("Zusaetzliche Befehle")

    cbAutoAttack = CreateCheckbox(rightPanel, "Auto-Attack aktivieren (/startattack)")
    cbAutoAttack:SetPoint("TOPLEFT", extraHeader, "BOTTOMLEFT", -2, -4)
    cbPetAttack = CreateCheckbox(rightPanel, "Pet zum Angriff schicken (/petattack)")
    cbPetAttack:SetPoint("TOPLEFT", cbAutoAttack, "BOTTOMLEFT", 0, -2)
    cbStopCasting = CreateCheckbox(rightPanel, "Laufenden Zauber vorher abbrechen (/stopcasting)")
    cbStopCasting:SetPoint("TOPLEFT", cbPetAttack, "BOTTOMLEFT", 0, -2)

    for _, cb in ipairs({ cbMouseoverHarm, cbMouseoverHelp, cbSelfFallback, cbAutoAttack, cbPetAttack, cbStopCasting }) do
        cb:SetScript("OnClick", UpdatePreview)
    end

    cbPerChar = CreateCheckbox(rightPanel, "Nur fuer diesen Charakter speichern")
    cbPerChar:SetPoint("TOPLEFT", cbStopCasting, "BOTTOMLEFT", 0, -10)

    local nameLbl = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    nameLbl:SetPoint("TOPLEFT", cbPerChar, "BOTTOMLEFT", 2, -12)
    nameLbl:SetText("Makroname (max. 16 Zeichen)")

    nameEdit = CreateFrame("EditBox", nil, rightPanel, "InputBoxTemplate")
    nameEdit:SetSize(200, 20)
    nameEdit:SetPoint("TOPLEFT", nameLbl, "BOTTOMLEFT", 4, -4)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetMaxLetters(16)
    nameEdit:SetScript("OnTextChanged", UpdatePreview)
    nameEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local previewLbl = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    previewLbl:SetPoint("TOPLEFT", nameEdit, "BOTTOMLEFT", -4, -10)
    previewLbl:SetText("Makro-Vorschau")

    local previewBackdrop = CreateFrame("Frame", nil, rightPanel, "InsetFrameTemplate")
    previewBackdrop:SetPoint("TOPLEFT", previewLbl, "BOTTOMLEFT", -2, -4)
    previewBackdrop:SetPoint("RIGHT", -4, 0)
    previewBackdrop:SetHeight(90)

    previewBox = CreateFrame("EditBox", nil, previewBackdrop)
    previewBox:SetMultiLine(true)
    previewBox:SetFontObject("GameFontHighlightSmall")
    previewBox:SetPoint("TOPLEFT", 6, -6)
    previewBox:SetPoint("BOTTOMRIGHT", -6, 6)
    previewBox:SetAutoFocus(false)
    previewBox:EnableMouse(true)
    previewBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    previewBox:SetScript("OnTextChanged", function(self)
        -- schreibgeschuetzt: Aenderungen des Nutzers verwerfen
        if selectedItem then
            local entry = BuildCurrentEntry()
            local generated = EM:BuildMacroBody(entry)
            if self:GetText() ~= generated then
                self:SetText(generated)
            end
        end
    end)

    saveButton = CreateFrame("Button", nil, rightPanel, "UIPanelButtonTemplate")
    saveButton:SetSize(150, 24)
    saveButton:SetPoint("TOPLEFT", previewBackdrop, "BOTTOMLEFT", 2, -12)
    saveButton:SetText("Makro erstellen")
    saveButton:SetEnabled(false)
    saveButton:SetScript("OnClick", function()
        local entry = BuildCurrentEntry()
        if not entry then return end
        local name, err = EM:SaveMacro(entry, editingMacroName)
        if not name then
            SetStatus(err, true)
            return
        end
        SetStatus("Gespeichert als '" .. name .. "'. Zieh das Icon aus deinem Makro-Fenster (/macro) in die Aktionsleiste.")
        EM.UI.RefreshMacroList()
        RefreshBuilderPanel(selectedItem, name, entry.opts, entry.perChar)
    end)

    cancelButton = CreateFrame("Button", nil, rightPanel, "UIPanelButtonTemplate")
    cancelButton:SetSize(150, 24)
    cancelButton:SetPoint("LEFT", saveButton, "RIGHT", 8, 0)
    cancelButton:SetText("Neues Makro")
    cancelButton:Hide()
    cancelButton:SetScript("OnClick", function()
        RefreshBuilderPanel(selectedItem, nil, nil, nil)
    end)

    statusText = rightPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", saveButton, "BOTTOMLEFT", 0, -8)
    statusText:SetPoint("RIGHT", -4, 0)
    statusText:SetJustifyH("LEFT")
    statusText:SetWordWrap(true)
    statusText:SetHeight(30)

    ----------------------------------------------------------------
    -- Unten: verwaltete Makros
    ----------------------------------------------------------------
    macroHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    macroHeader:SetPoint("TOPLEFT", leftPanel, "BOTTOMLEFT", 4, -12)
    macroHeader:SetText("Meine EasyMakro-Makros")

    local macroBackdrop = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    macroBackdrop:SetPoint("TOPLEFT", macroHeader, "BOTTOMLEFT", -4, -6)
    macroBackdrop:SetPoint("BOTTOMRIGHT", -14, 12)

    macroScroll = CreateFrame("ScrollFrame", "EasyMakroMacroScroll", macroBackdrop, "UIPanelScrollFrameTemplate")
    macroScroll:SetPoint("TOPLEFT", 4, -4)
    macroScroll:SetPoint("BOTTOMRIGHT", -26, 4)

    macroContent = CreateFrame("Frame", nil, macroScroll)
    macroContent:SetSize(1, 1)
    macroScroll:SetScrollChild(macroContent)

    RefreshSpellList()
    LayoutMacroRows()
    RefreshBuilderPanel(nil)
end

--------------------------------------------------------------------------
-- Oeffentliches API
--------------------------------------------------------------------------

function EM.UI.Toggle()
    if not frame then
        BuildFrame()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        RefreshSpellList()
        LayoutMacroRows()
        frame:Show()
    end
end
