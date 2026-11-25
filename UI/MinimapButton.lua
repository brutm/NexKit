local addonName, FP = ...

-------------------------------------------------------------------------------
-- UI/MinimapButton.lua – Circular Minimap quick launcher for modules & config
-------------------------------------------------------------------------------

local MINIMAP_SHAPES = {
    ["ROUND"]                 = { true,  true,  true,  true  },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { false, false, false, true  },
    ["CORNER-TOPRIGHT"]       = { false, false, true,  false },
    ["CORNER-BOTTOMLEFT"]     = { false, true,  false, false },
    ["CORNER-BOTTOMRIGHT"]    = { true,  false, false, false },
    ["SIDE-LEFT"]             = { false, true,  false, true  },
    ["SIDE-RIGHT"]            = { true,  false, true,  false },
    ["SIDE-TOP"]              = { false, false, true,  true  },
    ["SIDE-BOTTOM"]           = { true,  true,  false, false },
    ["TRICORNER-TOPLEFT"]     = { false, true,  true,  true  },
    ["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true  },
    ["TRICORNER-BOTTOMLEFT"]  = { true,  true,  false, true  },
    ["TRICORNER-BOTTOMRIGHT"] = { true,  true,  true,  false },
}

local atan2Compat = math.atan2 or math.atan or atan2

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsMinimapButtonEnabled()
    return GetSettings().showMinimapButton ~= false
end

local function IsFrameVisible(frameName)
    local f = _G[frameName]
    return f and f.IsShown and f:IsShown() and true or false
end

local ICON_IDLE_SIZE = 33
local ICON_PRESS_SIZE = 30

local minimapBtn = CreateFrame("Button", "NexusKitMinimapButton", Minimap or UIParent)
minimapBtn:SetSize(34, 34)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:EnableMouse(true)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetClampedToScreen(true)
minimapBtn:Hide()

-- Logo.tga already renders its own circular golden ring and transparent alpha,
-- so render it edge-to-edge without Blizzard's smaller TrackingBorder/Background overlay.
local iconTex = minimapBtn:CreateTexture(nil, "ARTWORK")
iconTex:SetSize(ICON_IDLE_SIZE, ICON_IDLE_SIZE)
iconTex:SetPoint("CENTER", 0, 0)
iconTex:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

local function UpdateButtonPosition()
    if not Minimap then return end
    if minimapBtn:GetParent() ~= Minimap then
        minimapBtn:SetParent(Minimap)
    end
    local deg = tonumber(GetSettings().minimapButtonPos) or 220
    local rad = math.rad(deg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local radius = ((Minimap:GetWidth() or 140) * 0.5) + 6
    local shape = (type(GetMinimapShape) == "function" and GetMinimapShape()) or "ROUND"
    local quadTable = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]

    local q = 1
    if cos < 0 then q = q + 1 end
    if sin > 0 then q = q + 2 end

    local x, y
    if quadTable[q] then
        x, y = cos * radius, sin * radius
    else
        local diag = math.sqrt(2 * (radius * radius)) - 10
        x = math.max(-radius, math.min(radius, cos * diag))
        y = math.max(-radius, math.min(radius, sin * diag))
    end

    minimapBtn:SetFrameStrata((Minimap.GetFrameStrata and Minimap:GetFrameStrata()) or "MEDIUM")
    minimapBtn:SetFrameLevel(math.max(8, (Minimap:GetFrameLevel() or 2) + 8))
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function ToggleTrackedHudSetting()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local enabled = not (NexusKitDB.settings.profShowTrackedHud ~= false)
    NexusKitDB.settings.profShowTrackedHud = enabled
    local L = FP.L or {}
    if FP.RefreshTrackedReagentsHUD then
        FP:RefreshTrackedReagentsHUD()
    end
    if FP.RefreshSettingsUI then
        FP:RefreshSettingsUI()
    end
    if enabled then
        FP:Print(L["REAGENT_HUD_ENABLED_MSG"] or "|cff00ff00HUD Reagenti Tracciati abilitato.|r")
        local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents
        local hasAny = type(tracked) == "table" and next(tracked) ~= nil
        if not hasAny then
            FP:Print(L["REAGENT_TRACK_USAGE"] or "Uso: Alt+Click su un oggetto in borsa, o /nk track [Link Oggetto]")
        end
    else
        FP:Print(L["REAGENT_HUD_DISABLED_MSG"] or "|cffff5555HUD Reagenti Tracciati disabilitato.|r")
    end
end

local function ToggleBuffAdvisorSetting()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local enabled = not (NexusKitDB.settings.enableBuffAdvisor ~= false)
    NexusKitDB.settings.enableBuffAdvisor = enabled
    local L = FP.L or {}
    if enabled then
        FP:Print(L["BUFF_ENABLED_MSG"] or "|cff00ff00Consigliere Buff e Tracking abilitato.|r")
        if FP.ToggleBuffAdvisor then
            FP:ToggleBuffAdvisor()
        end
    else
        FP:Print(L["BUFF_DISABLED_MSG"] or "|cffff5555Consigliere Buff e Tracking disabilitato.|r")
        if NexusKitBuffFrame then
            NexusKitBuffFrame:Hide()
        end
    end
    if FP.RefreshSettingsUI then
        FP:RefreshSettingsUI()
    end
end

local function ToggleRotationAdvisorSetting()
    if FP.ToggleRotationAdvisor then
        FP:ToggleRotationAdvisor()
    end
    if FP.RefreshSettingsUI then
        FP:RefreshSettingsUI()
    end
end

local function ToggleDispelAlertSetting()
    if FP.ToggleDispelAlert then
        FP:ToggleDispelAlert()
    end
    if FP.RefreshSettingsUI then
        FP:RefreshSettingsUI()
    end
end

local function ToggleCoordsSetting()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local enabled = not (NexusKitDB.settings.showPlayerCoords ~= false)
    NexusKitDB.settings.showPlayerCoords = enabled
    local L = FP.L or {}
    if enabled then
        FP:Print(L["COORDS_ENABLED_MSG"] or "|cff00ff00Coordinate in tempo reale abilitate.|r")
    else
        FP:Print(L["COORDS_DISABLED_MSG"] or "|cffff5555Coordinate in tempo reale disabilitate.|r")
    end
    if FP.RefreshCoordsUI then
        FP:RefreshCoordsUI()
    end
    if FP.RefreshSettingsUI then
        FP:RefreshSettingsUI()
    end
end

local function ToggleProfessionMenuAction()
    local L = FP.L or {}
    if NexusKitProfFrame and NexusKitProfFrame:IsShown() then
        NexusKitProfFrame:Hide()
        return
    end
    if FP.ToggleProfessionAdvisor then
        FP:ToggleProfessionAdvisor()
    end
    local anchor = FP.SafeGetTradeSkillAnchor and FP.SafeGetTradeSkillAnchor()
    if not anchor then
        FP:Print(L["PROF_OPEN_TIP_CHAT"] or "|cffffcc00[NexKit]|r Consigliere Professioni aperto. Apri una professione (es. Alchimia, Primo Soccorso) o clicca 'Opzioni Professioni'.")
    end
end

function FP:OpenMinimapLauncherMenu(anchorBtn)
    if not self.ShowPopupMenu then return end
    local L = self.L or {}
    local settings = GetSettings()
    local owner = anchorBtn or minimapBtn

    local items = {
        -- Section 1: Finestre & Guide
        {
            text = L["MINIMAP_MENU_SEC_WINDOWS"] or "FINESTRE & GUIDE",
            isHeader = true,
        },
        {
            text = L["MINIMAP_MENU_TRACKER"] or "Tracker Percorso",
            checked = function() return IsFrameVisible("NexusKitTrackerFrame") end,
            func = function()
                if FP.ToggleTrackerFrame then FP:ToggleTrackerFrame() end
            end,
        },
        {
            text = L["MINIMAP_MENU_DUNGEON"] or "Guida Boss Dungeon & Raid",
            checked = function() return IsFrameVisible("NexusKitDungeonFrame") end,
            func = function()
                if FP.ToggleDungeonGuide then FP:ToggleDungeonGuide() end
            end,
        },
        {
            text = L["MINIMAP_MENU_PROF"] or "Consigliere Professioni",
            checked = function() return IsFrameVisible("NexusKitProfFrame") end,
            func = ToggleProfessionMenuAction,
        },
        {
            text = L["MINIMAP_MENU_TODO"] or "To-Do List / Promemoria",
            checked = function() return IsFrameVisible("NexusKitTodoFrame") end,
            func = function()
                if FP.ToggleTodoList then FP:ToggleTodoList() end
            end,
        },
        {
            text = L["IMPORT_TITLE"] or "Importa pacchetto percorso",
            checked = function() return IsFrameVisible("NexusKitImporterFrame") end,
            func = function()
                if FP.ToggleImporterFrame then FP:ToggleImporterFrame() end
            end,
        },

        -- Section 2: Widget & HUD a Schermo
        {
            text = L["MINIMAP_MENU_SEC_WIDGETS"] or "WIDGET & HUD ATTIVI",
            isHeader = true,
        },
        {
            text = L["MINIMAP_MENU_BUFFS"] or "Consigliere Buff e Tracking",
            checked = function() return GetSettings().enableBuffAdvisor ~= false end,
            keepOpen = true,
            func = ToggleBuffAdvisorSetting,
        },
        {
            text = L["MINIMAP_MENU_ROTATION"] or "Consigliere Rotazione Spell",
            checked = function() return GetSettings().enableRotationAdvisor ~= false end,
            keepOpen = true,
            func = ToggleRotationAdvisorSetting,
        },
        {
            text = L["MINIMAP_MENU_DISPEL"] or "Avviso Dispel Debuff",
            checked = function() return GetSettings().enableDispelAlert ~= false end,
            keepOpen = true,
            func = ToggleDispelAlertSetting,
        },
        {
            text = L["MINIMAP_MENU_REAGENTS"] or "HUD Reagenti Tracciati",
            checked = function() return GetSettings().profShowTrackedHud ~= false end,
            keepOpen = true,
            func = ToggleTrackedHudSetting,
        },
        {
            text = L["MINIMAP_MENU_COORDS"] or "Coordinate in Tempo Reale",
            checked = function() return GetSettings().showPlayerCoords ~= false end,
            keepOpen = true,
            func = ToggleCoordsSetting,
        },
        {
            text = L["MINIMAP_MENU_SYNC"] or "Sincronia Quest Log",
            checked = function() return (FP.IsQuestSyncActive and FP:IsQuestSyncActive()) or false end,
            keepOpen = true,
            func = function()
                if FP.ToggleQuestSync then FP:ToggleQuestSync() end
            end,
        },

        -- Section 3: Configurazioni & Aiuto
        {
            text = L["MINIMAP_MENU_SEC_CONFIG"] or "CONFIGURAZIONE",
            isHeader = true,
        },
        {
            text = L["MINIMAP_MENU_UNLOCK_ALL"] or "Sblocca / Sposta Finestre",
            checked = function() return (FP.AreAllHUDsUnlocked and FP:AreAllHUDsUnlocked()) or false end,
            keepOpen = true,
            func = function()
                if FP.SetAllHUDsUnlocked and FP.AreAllHUDsUnlocked then
                    FP:SetAllHUDsUnlocked(not FP:AreAllHUDsUnlocked())
                end
            end,
        },
        {
            text = L["MINIMAP_MENU_CFG_PROF"] or "Configura Professioni...",
            func = function()
                if FP.ToggleSettingsFrame then FP:ToggleSettingsFrame("prof") end
            end,
        },
        {
            text = L["MINIMAP_MENU_CFG_BUFFS"] or "Configura Buff & Interfaccia...",
            func = function()
                if FP.ToggleSettingsFrame then FP:ToggleSettingsFrame("buffs") end
            end,
        },
        {
            text = L["SETTINGS_TITLE"] or "Impostazioni NexKit",
            checked = function() return IsFrameVisible("NexusKitSettingsFrame") end,
            func = function()
                if FP.ToggleSettingsFrame then FP:ToggleSettingsFrame() end
            end,
        },
        {
            text = L["HELP_BTN_TIP"] or "Guida e Comandi (/nk help)",
            checked = function() return IsFrameVisible("NexusKitWelcomeFrame") end,
            func = function()
                if FP.ToggleWelcomeFrame then FP:ToggleWelcomeFrame() end
            end,
        },
    }

    self:ShowPopupMenu(owner, "TOPRIGHT", "BOTTOMLEFT", -4, 4, 245, items)
end

local isDragging = false

minimapBtn:SetScript("OnMouseDown", function(_, mouseBtn)
    if mouseBtn == "LeftButton" then
        iconTex:SetSize(ICON_PRESS_SIZE, ICON_PRESS_SIZE)
    end
end)

minimapBtn:SetScript("OnMouseUp", function()
    iconTex:SetSize(ICON_IDLE_SIZE, ICON_IDLE_SIZE)
end)

minimapBtn:SetScript("OnDragStart", function(self)
    if not Minimap or not atan2Compat then return end
    isDragging = true
    if FP.ClosePopupMenu then FP:ClosePopupMenu() end
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        if mx and my and cx and cy and scale and scale > 0 then
            local deg = math.deg(atan2Compat((cy / scale) - my, (cx / scale) - mx))
            if NexusKitDB and NexusKitDB.settings then
                NexusKitDB.settings.minimapButtonPos = deg
            end
            UpdateButtonPosition()
        end
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    iconTex:SetSize(ICON_IDLE_SIZE, ICON_IDLE_SIZE)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function() isDragging = false end)
    else
        isDragging = false
    end
end)

minimapBtn:SetScript("OnClick", function(self, mouseBtn)
    if isDragging then return end
    if mouseBtn == "RightButton" then
        if FP.ClosePopupMenu then FP:ClosePopupMenu() end
        if FP.ToggleSettingsFrame then
            FP:ToggleSettingsFrame()
        end
    elseif IsShiftKeyDown and IsShiftKeyDown() then
        if FP.ClosePopupMenu then FP:ClosePopupMenu() end
        if FP.ToggleTrackerFrame then
            FP:ToggleTrackerFrame()
        end
    else
        FP:OpenMinimapLauncherMenu(self)
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
    local L = FP.L or {}
    local r, g, b = FP:GetAccentColor()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("NexusKit |cff8899aav" .. (FP.VERSION or "0.1") .. "|r", r, g, b)
    GameTooltip:AddLine(L["MINIMAP_BTN_TIP_LEFT"] or "Left-click: Open modules & windows menu", 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_BTN_TIP_RIGHT"] or "Right-click: Open Settings", 0.45, 0.92, 1.0)
    GameTooltip:AddLine(L["MINIMAP_BTN_TIP_SHIFT"] or "Shift + Left-click: Toggle Route Tracker", 0.85, 0.88, 0.92)
    GameTooltip:AddLine(L["MINIMAP_BTN_TIP_DRAG"] or "Drag: Move icon around Minimap", 0.65, 0.70, 0.78)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
end)

function FP:RefreshMinimapButton()
    if not Minimap or not Minimap:IsVisible() then
        minimapBtn:Hide()
        return
    end
    if not IsMinimapButtonEnabled() then
        minimapBtn:Hide()
        return
    end
    UpdateButtonPosition()
    minimapBtn:Show()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    FP:RefreshMinimapButton()
end)
