local ADDON_NAME, EM = ...
local L = EM.L

local DEFAULT_ANGLE = 200
local RADIUS = 80

local button

local function UpdatePosition(angle)
    local x = math.cos(math.rad(angle)) * RADIUS
    local y = math.sin(math.rad(angle)) * RADIUS
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate(self)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale

    local angle = math.deg(math.atan2(py - my, px - mx))
    EM.db.minimapAngle = angle
    UpdatePosition(angle)
end

-- Wird von Core.lua aufgerufen, sobald EasyMakroDB geladen ist.
function EM.InitMinimapButton()
    if button or not Minimap then return end
    if EM.db.minimapAngle == nil then
        EM.db.minimapAngle = DEFAULT_ANGLE
    end

    button = CreateFrame("Button", "EasyMakroMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("TOPLEFT", 7, -6)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("EasyMakro", 1, 1, 1)
        GameTooltip:AddLine(L.MINIMAP_TOOLTIP_LEFT, 0.6, 1, 0.6)
        GameTooltip:AddLine(L.MINIMAP_TOOLTIP_RIGHT, 0.6, 1, 0.6)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            ShowMacroFrame()
        else
            EM.UI.Toggle()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    UpdatePosition(EM.db.minimapAngle)
end
