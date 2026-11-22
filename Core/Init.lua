-- NexusKit  –  Core/Init.lua
-- Initialises saved variables, localization switching, helpers, slash commands,
-- and the private namespace.
local addonName, FP = ...

------------------------------------------------------------------------
-- Private-namespace tables
------------------------------------------------------------------------
FP.routes                = FP.routes or {}
FP.activeRoute           = nil
FP.currentStepIndex      = nil
FP.OnStepChangedCallbacks = FP.OnStepChangedCallbacks or {}

------------------------------------------------------------------------
-- Version & Media (mirror of TOC) & Global Export
------------------------------------------------------------------------
local function GetAddonVersion()
    local name = addonName or "NexusKit"
    local v
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        v = C_AddOns.GetAddOnMetadata(name, "Version") or C_AddOns.GetAddOnMetadata("NexusKit", "Version") or C_AddOns.GetAddOnMetadata("NexKit", "Version")
    elseif GetAddOnMetadata then
        v = GetAddOnMetadata(name, "Version") or GetAddOnMetadata("NexusKit", "Version") or GetAddOnMetadata("NexKit", "Version")
    end
    return (v and v ~= "" and v ~= "@project-version@") and v or "0.3.4"
end

FP.VERSION      = GetAddonVersion()
FP.LOGO_TEXTURE = "Interface\\AddOns\\" .. (addonName or "NexKit") .. "\\Media\\Logo.tga"

-- Export global addon table for macros, WeakAuras, and external scripts
_G.NexKit      = FP
_G.NK          = FP
_G.NexusKit    = FP
_G.ForeverPath = FP

------------------------------------------------------------------------
-- Universal Safe Timer (C_Timer shim for legacy/custom clients)
------------------------------------------------------------------------
local timerQueue = {}
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self)
    local now = (GetTime and GetTime()) or 0
    local remaining = 0
    for i = #timerQueue, 1, -1 do
        local item = timerQueue[i]
        if now >= item.fireAt then
            table.remove(timerQueue, i)
            if type(item.callback) == "function" then
                pcall(item.callback)
            end
        else
            remaining = remaining + 1
        end
    end
    if remaining == 0 then
        self:Hide()
    end
end)

function FP:After(delay, callback)
    if type(callback) ~= "function" then return end
    local d = tonumber(delay) or 0
    if C_Timer and type(C_Timer.After) == "function" then
        pcall(C_Timer.After, d, callback)
        return
    end
    local fireAt = ((GetTime and GetTime()) or 0) + math.max(0, d)
    table.insert(timerQueue, { fireAt = fireAt, callback = callback })
    timerFrame:Show()
end

-- Ensure global C_Timer.After is safely available for all components
if not C_Timer then
    C_Timer = {}
end
if type(C_Timer.After) ~= "function" then
    C_Timer.After = function(delay, callback)
        FP:After(delay, callback)
    end
end

------------------------------------------------------------------------
-- Supported locales (in display order)
------------------------------------------------------------------------
FP.SUPPORTED_LOCALES = {
    { code = "auto", labelKey = "LANGUAGE_AUTO" },
    { code = "enUS", name = "English" },
    { code = "itIT", name = "Italiano" },
    { code = "esES", name = "Español" },
    { code = "ruRU", name = "Русский" },
    { code = "deDE", name = "Deutsch" },
    { code = "frFR", name = "Français" },
}

------------------------------------------------------------------------
-- Color themes (configurable in Settings -> Buffs & UI)
------------------------------------------------------------------------
FP.COLOR_THEMES = {
    {
        id       = "blizzard",
        labelKey = "THEME_BLIZZARD",
        fallback = "Blizzard (Gold & White)",
        accent   = { r = 1.00, g = 0.82, b = 0.00, hex = "ffd100" },
        hud      = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffff" },
    },
    {
        id       = "white",
        labelKey = "THEME_WHITE",
        fallback = "Minimal White",
        accent   = { r = 0.96, g = 0.96, b = 0.98, hex = "f5f5fa" },
        hud      = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffff" },
    },
    {
        id       = "cyan",
        labelKey = "THEME_CYAN",
        fallback = "Sky Blue",
        accent   = { r = 0.35, g = 0.88, b = 1.00, hex = "59e0ff" },
        hud      = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffff" },
    },
    {
        id       = "emerald",
        labelKey = "THEME_EMERALD",
        fallback = "Emerald Mint",
        accent   = { r = 0.00, g = 1.00, b = 0.59, hex = "00ff96" },
        hud      = { r = 0.00, g = 1.00, b = 0.59, hex = "00ff96" },
    },
}

function FP:GetThemePalette()
    local key = (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.uiTheme) or "blizzard"
    for _, entry in ipairs(FP.COLOR_THEMES) do
        if entry.id == key then
            return entry
        end
    end
    return FP.COLOR_THEMES[1]
end

function FP:GetAccentColor()
    local a = self:GetThemePalette().accent
    return a.r, a.g, a.b, a.hex
end

function FP:GetHudTextColor()
    local h = self:GetThemePalette().hud
    return h.r, h.g, h.b, h.hex
end

function FP:SyncAccentTable(target)
    if type(target) == "table" then
        local r, g, b, hex = self:GetAccentColor()
        target.r, target.g, target.b, target.hex = r, g, b, hex
    end
    return target
end

function FP:ApplyTheme(themeId)
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings.uiTheme = themeId or "blizzard"
    end
    if self.RefreshAllUI then
        self:RefreshAllUI()
    end
end

local LOCALE_ALIASES = {
    esMX = "esES",
    enGB = "enUS",
}

local function WipeTable(t)
    if wipe then
        wipe(t)
    else
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

local function Trim(s)
    if not s then return "" end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function FP:CropButtonTextures(btn, inset)
    if not btn then return end
    local lo = inset or 0.14
    local hi = 1 - lo
    for _, getter in ipairs({ btn.GetNormalTexture, btn.GetPushedTexture, btn.GetHighlightTexture }) do
        if type(getter) == "function" then
            local tex = getter(btn)
            if tex and tex.SetTexCoord then
                tex:SetTexCoord(lo, hi, lo, hi)
            end
        end
    end
end

function FP:FitButtonToText(btn, minW, pad, labelObj, maxW)
    if not btn then return minW or 0 end
    local fs = labelObj or btn.label or (btn.GetFontString and btn:GetFontString())
    if not fs then
        local w = minW or (btn.GetWidth and btn:GetWidth()) or 80
        btn:SetWidth(w)
        return w
    end

    if not btn._nkOrigFont and fs.GetFont then
        local fPath, fSize, fFlags = fs:GetFont()
        if fPath and fSize then
            btn._nkOrigFont = fPath
            btn._nkOrigSize = fSize
            btn._nkOrigFlags = fFlags
        end
    end
    if btn._nkOrigFont and btn._nkOrigSize and fs.SetFont then
        fs:SetFont(btn._nkOrigFont, btn._nkOrigSize, btn._nkOrigFlags)
    end
    if fs.SetWordWrap then
        fs:SetWordWrap(false)
    end

    local padPx = pad or 22
    local tw = (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth())
        or (fs.GetStringWidth and fs:GetStringWidth()) or 0
    local wantW = math.max(minW or 0, math.ceil(tw + padPx))

    if maxW and maxW > 0 and wantW > maxW then
        wantW = maxW
        if btn._nkOrigFont and btn._nkOrigSize and fs.SetFont then
            local innerLimit = math.max(16, maxW - math.min(padPx, 12))
            local sz = btn._nkOrigSize
            local minSz = math.max(8, btn._nkOrigSize - 3.5)
            while tw > innerLimit and sz > minSz do
                sz = sz - 0.5
                fs:SetFont(btn._nkOrigFont, sz, btn._nkOrigFlags)
                tw = (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth())
                    or (fs.GetStringWidth and fs:GetStringWidth()) or 0
            end
        end
    end

    if btn.SetWidth then
        btn:SetWidth(wantW)
    end
    return wantW
end

function FP:ResolveLocaleCode(code)
    if not code or code == "auto" then
        local client = GetLocale and GetLocale() or "enUS"
        client = LOCALE_ALIASES[client] or client
        if FP.Locales and FP.Locales[client] then
            return client
        end
        return "enUS"
    end
    code = LOCALE_ALIASES[code] or code
    if FP.Locales and FP.Locales[code] then
        return code
    end
    return "enUS"
end

function FP:ApplyLocale(code)
    local resolved = self:ResolveLocaleCode(code)
    local source = (FP.Locales and FP.Locales[resolved]) or (FP.Locales and FP.Locales["enUS"]) or {}
    local fallback = (FP.Locales and FP.Locales["enUS"]) or {}

    FP.L = FP.L or {}
    WipeTable(FP.L)
    for k, v in pairs(fallback) do
        FP.L[k] = v
    end
    for k, v in pairs(source) do
        FP.L[k] = v
    end
    FP.activeLocale = resolved

    if FP.RefreshAllUI then
        FP:RefreshAllUI()
    end
    return resolved
end

function FP:GetEffectiveLocale()
    if FP.activeLocale then return FP.activeLocale end
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locale then
        return self:ResolveLocaleCode(NexusKitDB.settings.locale)
    end
    return (GetLocale and GetLocale()) or "enUS"
end

------------------------------------------------------------------------
-- Main event frame
------------------------------------------------------------------------
local frame = CreateFrame("Frame", "NexusKitCoreFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:RegisterEvent("ADDON_ACTION_BLOCKED")

------------------------------------------------------------------------
-- Print helper (coloured prefix)
------------------------------------------------------------------------
function FP:Print(msg)
    local _, _, _, hex = self:GetAccentColor()
    local prefix = "|cff" .. hex .. "NexusKit|r: "
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(msg))
    end
end

------------------------------------------------------------------------
-- Quest title helper (compatible with Retail, Classic Era & Cata)
------------------------------------------------------------------------
function FP:GetQuestTitleCompat(questID)
    if not questID then return nil end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and type(title) == "string" and (not issecretvalue or not issecretvalue(title)) and title ~= "" then
            return title
        end
    end
    if GetQuestLogIndexByID and GetQuestLogTitle then
        local idx = GetQuestLogIndexByID(questID)
        if idx and idx > 0 then
            local title = GetQuestLogTitle(idx)
            if type(title) == "string" and title ~= "" then
                return title
            end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Player-info helpers
------------------------------------------------------------------------
function FP:GetPlayerFaction()
    return UnitFactionGroup("player")
end

function FP:GetPlayerClass()
    return select(2, UnitClass("player"))
end

function FP:GetPlayerRace()
    return select(2, UnitRace("player"))
end

function FP:GetPlayerLevel()
    return UnitLevel("player") or 1
end

function FP:GetPlayerXPPercent()
    local maxXP = UnitXPMax("player")
    if not maxXP or maxXP == 0 then return 0 end
    return (UnitXP("player") or 0) / maxXP
end

------------------------------------------------------------------------
-- Route registration (light-weight; full validation lives in Parser.lua)
------------------------------------------------------------------------
function FP:RegisterRoute(routeTable)
    if not routeTable or not routeTable.routeId then return false end
    self.routes[routeTable.routeId] = routeTable
    return true
end

------------------------------------------------------------------------
-- UI refresh broadcast hook
------------------------------------------------------------------------
function FP:RefreshAllUI()
    if self.RefreshTracker then self:RefreshTracker() end
    if self.ApplyTrackerScale then self:ApplyTrackerScale() end
    if self.RefreshWaypointsUI then self:RefreshWaypointsUI() end
    if self.RefreshZonePOIs then self:RefreshZonePOIs() end
    if self.RefreshCoordsUI then self:RefreshCoordsUI() end
    if self.RefreshCustomWaypointUI then self:RefreshCustomWaypointUI() end
    if self.RefreshHighlights then self:RefreshHighlights() end
    if self.ApplyProfessionScale then self:ApplyProfessionScale() end
    if self.RefreshProfessionAdvisor then self:RefreshProfessionAdvisor() end
    if self.RefreshReagentTrackerUI then self:RefreshReagentTrackerUI() end
    if self.ApplyBuffAdvisorScale then self:ApplyBuffAdvisorScale() end
    if self.RefreshBuffAdvisor then self:RefreshBuffAdvisor() end
    if self.RefreshDungeonGuide then self:RefreshDungeonGuide() end
    if self.RefreshQuestRewardHighlights then self:RefreshQuestRewardHighlights() end
    if self.RefreshImporterUI then self:RefreshImporterUI() end
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
    if self.RefreshWelcomeUI then self:RefreshWelcomeUI() end
end

------------------------------------------------------------------------
-- Saved-variable defaults
------------------------------------------------------------------------
local SV_DEFAULTS = {
    seenWelcome  = false,
    customRoutes = {},
    settings     = {
        -- General & Quests
        autoAccept              = true,
        autoTurnIn              = true,
        highlightQuestRewards   = true,
        rewardSpecByClass       = {},
        warnKeepQuestLoot       = true,
        syncDeprioritizeDungeons = true,
        syncPreferWatched       = true,
        syncSuggestTrainers     = true,
        autoSkipByLevel         = true,
        upcomingStepsCount      = 4,
        showQuestItemBtn        = true,
        locale                  = "auto",

        -- Navigation & Highlights
        enableHighlights        = true,
        enableRaidMarkers       = true,
        enableMapPins           = true,
        showTrajectories        = true,
        showMinimapTrajectories = true,
        showMinimapPin          = true,
        showZonePOIs            = false,
        zonePOIsOnlyUndiscovered = false,
        zonePOIFlight           = true,
        zonePOIInn              = true,
        zonePOITransport        = true,
        zonePOIServices         = true,
        zonePOIDungeons         = true,
        zonePOIOppositeFaction  = false,
        crossZoneProjection     = true,
        arrowHideInCombat       = false,
        showPlayerCoords        = true,
        arrowScale              = 1,

        -- Professions Advisor
        enableProfessionAdvisor = true,
        profAutoSelectHero      = false,
        profIncludeMedium       = true,
        profIncludeEasy         = true,
        profPreferIntermediate  = true,
        profDefaultCraftableOnly = false,
        profHighlightReagents   = true,
        profShowTrackedHud      = true,
        reagentHudLocked        = false,
        profBagTrackButtons     = true,
        profMaxResults          = 30,
        profScale               = 1,

        -- Buffs & Interface
        enableBuffAdvisor       = true,
        buffCheckClass          = true,
        buffCheckTracking       = true,
        buffCheckProfessionItems = true,
        buffHideResting         = false,
        buffTransparentBar      = true,
        enableDungeonGuide      = true,
        dungeonGuideFirstTimeOnly = true,
        buffExpiringSeconds     = 120,
        buffScale               = 1,
        trackerScale            = 1,
        uiTheme                 = "blizzard",
        showMinimapButton       = true,
        minimapButtonPos        = 220,
        locked                  = false,
        arrowLocked             = false,

        -- Quest Starter Alert & Class Frames
        enableQuestStarterAlert = true,
        showClassColorsAndIcons = true,
    },
}

local CHAR_DEFAULTS = {
    completedSteps          = {},
    activeRouteId           = nil,
    previousRouteId         = nil,
    currentStepIdx          = 1,
    discoveredFlights       = {},
    discoveredZonePOIs      = {},
    manualUndiscoveredPOIs  = {},
    seenDungeonGuides       = {},
    defeatedBosses          = {},
}

local function InitTable(src, defaults)
    for k, v in pairs(defaults) do
        if src[k] == nil then
            if type(v) == "table" then
                src[k] = {}
                InitTable(src[k], v)
            else
                src[k] = v
            end
        elseif type(v) == "table" and type(src[k]) == "table" then
            InitTable(src[k], v)
        end
    end
end

function FP:ResetSettingsToDefaults()
    if type(NexusKitDB) ~= "table" then
        NexusKitDB = {}
    end
    NexusKitDB.settings = {}
    InitTable(NexusKitDB.settings, SV_DEFAULTS.settings)
    NexusKitDB.settings._migratedMinimapPinOff = true
    if self.ApplyArrowLockVisual then self:ApplyArrowLockVisual() end
    if self.RefreshArrowLockVisual then self:RefreshArrowLockVisual() end
    if self.RefreshMinimapButton then self:RefreshMinimapButton() end
    self:ApplyLocale(NexusKitDB.settings.locale)
    if self.RefreshQuestRewardHighlights then self:RefreshQuestRewardHighlights() end
    if self.UpdateCurrentStep and self.activeRoute then
        self:UpdateCurrentStep()
    end
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
local function FindMatchingLocaleArg(arg)
    local lower = arg:lower()
    for _, entry in ipairs(FP.SUPPORTED_LOCALES) do
        if entry.code:lower() == lower then
            return entry.code
        end
    end
    return nil
end

local function HandleSlashCommand(input)
    local raw = Trim(input or "")
    local cmd, rest = raw:match("^(%S+)%s*(.-)$")
    cmd = (cmd or ""):lower()
    rest = Trim(rest or "")
    local L = FP.L

    if cmd == "import" then
        if FP.ToggleImporterFrame then
            FP:ToggleImporterFrame()
        end
    elseif cmd == "sync" then
        if FP.ToggleQuestSync then
            FP:ToggleQuestSync()
        end
    elseif cmd == "reset" then
        if NexusKitCharDB and NexusKitCharDB.completedSteps then
            WipeTable(NexusKitCharDB.completedSteps)
            NexusKitCharDB.currentStepIdx = 1
        end
        if NexusKitCharDB then
            NexusKitCharDB.skippedTrainKey = nil
        end
        if FP.skippedSyncQuests then
            WipeTable(FP.skippedSyncQuests)
        end
        FP.currentStepIndex = nil
        if FP.UpdateCurrentStep then FP:UpdateCurrentStep() end
        FP:Print(L["RESET_CONFIRM"])
    elseif cmd == "config" or cmd == "settings" then
        if FP.ToggleSettingsFrame then
            FP:ToggleSettingsFrame()
        end
    elseif cmd == "prof" or cmd == "professions" then
        if FP.ToggleProfessionAdvisor then
            FP:ToggleProfessionAdvisor()
        end
    elseif cmd == "track" or cmd == "reagent" or cmd == "target" or cmd == "goal" or cmd == "desiderata" then
        if FP.SetTrackReagentFromInput then
            FP:SetTrackReagentFromInput(rest)
        else
            FP:Print(L["USAGE"])
        end
    elseif cmd == "trackbtn" or cmd == "bagbuttons" or cmd == "bagbtns" or cmd == "trackbuttons" then
        if NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.profBagTrackButtons = not (NexusKitDB.settings.profBagTrackButtons ~= false)
            if FP.RefreshReagentTrackerUI then FP:RefreshReagentTrackerUI() end
            local statusStr = NexusKitDB.settings.profBagTrackButtons and "|cff00ff00ATTIVATI|r" or "|cffff0000DISATTIVATI|r"
            FP:Print("Pulsanti [+] sui reagenti in borsa: " .. statusStr)
        end
    elseif cmd == "buffs" or cmd == "buff" then
        if FP.ToggleBuffAdvisor then
            FP:ToggleBuffAdvisor()
        end
    elseif cmd == "todo" or cmd == "task" or cmd == "tasks" or cmd == "appunti" or cmd == "note" then
        if FP.ToggleTodoList then
            if rest == "" then
                FP:ToggleTodoList()
            elseif rest:lower() == "hud" then
                NexusKitDB.settings.showTodoHud = not (NexusKitDB.settings.showTodoHud == true)
                if FP.RefreshTodoHUD then FP:RefreshTodoHUD() end
                local statusStr = NexusKitDB.settings.showTodoHud and "|cff00ff00ATTIVATO|r" or "|cffff0000DISATTIVATO|r"
                FP:Print("HUD Promemoria To-Do a schermo: " .. statusStr)
            elseif rest:lower() == "clear" or rest:lower() == "clean" then
                if FP.ClearDoneTodoTasks then FP:ClearDoneTodoTasks() end
                FP:Print("Promemoria completati rimossi.")
            else
                local toAdd = rest:match("^[Aa][Dd][Dd]%s+(.+)$") or rest
                if FP.AddTodoTask then
                    FP:AddTodoTask(toAdd)
                    FP:Print("|cff00ff96[To-Do]|r Promemoria aggiunto: " .. toAdd)
                end
            end
        else
            FP:Print(L["USAGE"])
        end
    elseif cmd == "boss" or cmd == "dungeon" or cmd == "dungeons" or cmd == "tactics" then
        if FP.ToggleDungeonGuide then
            FP:ToggleDungeonGuide(rest)
        end
    elseif cmd == "resetdungeons" or cmd == "bossreset" then
        if FP.ResetDungeonGuideSeen then
            FP:ResetDungeonGuideSeen()
        elseif NexusKitCharDB then
            NexusKitCharDB.seenDungeonGuides = {}
        end
        FP:Print(L["DUNGEON_RESET_MSG"] or "Dungeon guide visit history reset for this character.")
    elseif cmd == "toggle" or cmd == "show" or cmd == "hide" then
        if FP.ToggleTrackerFrame then
            FP:ToggleTrackerFrame(cmd == "show" and true or (cmd == "hide" and false or nil))
        end
    elseif cmd == "coords" or cmd == "coord" then
        if FP.TogglePlayerCoords then
            FP:TogglePlayerCoords()
        end
    elseif cmd == "poi" or cmd == "pois" or cmd == "map" then
        if NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.showZonePOIs = not (NexusKitDB.settings.showZonePOIs == true)
            if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            FP:Print("Zone POIs: " .. (NexusKitDB.settings.showZonePOIs and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        end
    elseif cmd == "classframes" or cmd == "classcolors" or cmd == "classicons" or cmd == "party" then
        if NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.showClassColorsAndIcons = not (NexusKitDB.settings.showClassColorsAndIcons ~= false)
            if FP.RefreshClassFrames then FP:RefreshClassFrames() end
            local st = NexusKitDB.settings.showClassColorsAndIcons and "|cff00ff00ATTIVATI|r" or "|cffff0000DISATTIVATI|r"
            FP:Print("Colori & Icone di Classe: " .. st)
        end
    elseif cmd == "testparty" then
        if FP.DumpPartyStatus then
            FP:DumpPartyStatus()
        else
            FP:Print("Modulo ClassFrames non disponibile.")
        end
    elseif cmd == "questalert" or cmd == "starteralert" then
        if NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.enableQuestStarterAlert = not (NexusKitDB.settings.enableQuestStarterAlert ~= false)
            local st = NexusKitDB.settings.enableQuestStarterAlert and "|cff00ff00ATTIVATO|r" or "|cffff0000DISATTIVATO|r"
            FP:Print("Avviso Oggetti che Iniziano Missioni: " .. st)
        end
    elseif cmd == "mmtrail" or cmd == "mmroute" or cmd == "minimaptrail" then
        if NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.showMinimapTrajectories = not (NexusKitDB.settings.showMinimapTrajectories ~= false)
            if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            FP:Print("Minimap Trajectory: " .. (NexusKitDB.settings.showMinimapTrajectories and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        end
    elseif cmd == "status" then
        local rName = (FP.activeRoute and (FP.activeRoute.title or FP.activeRoute.routeId)) or "None"
        local stepIdx = FP.currentStepIndex or (NexusKitCharDB and NexusKitCharDB.currentStepIdx) or 1
        local total = (FP.activeRoute and FP.activeRoute.steps and #FP.activeRoute.steps) or 0
        FP:Print(string.format("Route: %s | Step: %d / %d | Sync: %s", rName, stepIdx, total, (FP.IsQuestSyncActive and FP:IsQuestSyncActive()) and "ON" or "OFF"))
    elseif cmd == "way" or cmd == "goto" or cmd == "wp" then
        if FP.SetCustomWaypointFromInput then
            FP:SetCustomWaypointFromInput(rest)
        else
            FP:Print(L["USAGE"])
        end
    elseif cmd == "clear" or cmd == "unway" then
        if FP.ClearCustomWaypoint then
            FP:ClearCustomWaypoint()
        end
    elseif cmd == "donate" or cmd == "support" or cmd == "kofi" or cmd == "paypal" then
        if FP.ShowDonateDialog then
            FP:ShowDonateDialog()
        elseif FP.ToggleWelcomeFrame then
            FP:ToggleWelcomeFrame()
        end
    elseif cmd == "help" or cmd == "?" then
        if FP.ToggleWelcomeFrame then
            FP:ToggleWelcomeFrame()
        else
            FP:Print(L["USAGE"])
        end
    elseif cmd == "lang" or cmd == "locale" then
        local matched = FindMatchingLocaleArg(rest)
        if matched and NexusKitDB and NexusKitDB.settings then
            NexusKitDB.settings.locale = matched
            local resolved = FP:ApplyLocale(matched)
            FP:Print(string.format(FP.L["LANGUAGE_CHANGED"], resolved))
        else
            FP:Print(L["USAGE"])
        end
    else
        FP:Print(L["USAGE"])
    end
end

-- Register slash commands immediately at file load so /nk and aliases are always available
SLASH_NEXKIT1 = "/nk"
SLASH_NEXKIT2 = "/nexkit"
SLASH_NEXKIT3 = "/nexuskit"
SLASH_NEXKIT4 = "/fp"
SLASH_NEXKIT5 = "/foreverpath"
SlashCmdList["NEXKIT"] = HandleSlashCommand
SlashCmdList["NEXUSKIT"] = HandleSlashCommand

-- Convenience /way alias when no other waypoint addon already owns it
if not SLASH_TOMTOM_WAY1 and not SlashCmdList["TOMTOM_WAY"] and not SlashCmdList["WAY"] then
    SLASH_NEXKIT_WAY1 = "/way"
    SlashCmdList["NEXKIT_WAY"] = function(msg)
        if FP.SetCustomWaypointFromInput then
            FP:SetCustomWaypointFromInput(msg)
        else
            FP:Print(FP.L["USAGE"])
        end
    end
end

------------------------------------------------------------------------
-- Event handler
------------------------------------------------------------------------
frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and (arg1 == addonName or arg1 == "NexKit" or arg1 == "NexusKit") then
        -- Initialise global saved variables with smooth backward compatibility
        if type(NexKitDB) ~= "table" then
            NexKitDB = (type(NexusKitDB) == "table") and NexusKitDB or {}
        end
        NexusKitDB = NexKitDB -- alias for backwards compatibility
        InitTable(NexKitDB, SV_DEFAULTS)
        if NexKitDB.settings and not NexKitDB.settings._migratedMinimapPinOff then
            NexKitDB.settings.showMinimapPin = false
            NexKitDB.settings._migratedMinimapPinOff = true
        end

        -- Initialise per-character saved variables
        if type(NexKitCharDB) ~= "table" then
            NexKitCharDB = (type(NexusKitCharDB) == "table") and NexusKitCharDB or {}
        end
        NexusKitCharDB = NexKitCharDB -- alias for backwards compatibility
        InitTable(NexKitCharDB, CHAR_DEFAULTS)

        -- Clean up any obsolete/stale custom waypoints pointing to old riddle coordinates
        if NexusKitCharDB and NexusKitCharDB.customWaypoint then
            local cw = NexusKitCharDB.customWaypoint
            local title = cw.title or ""
            if title:find("Collana", 1, true) or title:find("Necklace", 1, true) or title:find("Hilary", 1, true)
                or (cw.mapID == 1433 and IsSafeNum(cw.x) and math.abs(cw.x - 0.478) < 0.05) then
                NexusKitCharDB.customWaypoint = nil
            end
        end

        -- Apply configured language (defaults to client locale -> enUS fallback)
        FP:ApplyLocale(NexKitDB.settings.locale)

        -- Re-register any previously imported custom routes
        if NexKitDB.customRoutes then
            for _, routeTable in pairs(NexKitDB.customRoutes) do
                FP:RegisterRoute(routeTable)
            end
        end

        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        local L = FP.L
        -- Enable CVar taint logging to Logs\taint.log for deep Blizzard UI diagnostics
        pcall(SetCVar, "taintLog", "2")
        local lastId = NexusKitCharDB.activeRouteId

        -- Auto-select faction default route on first run (when activeRouteId == nil)
        if lastId == nil then
            local faction = FP:GetPlayerFaction()
            local level = UnitLevel and UnitLevel("player") or 1
            if faction == "Alliance" then
                if level >= 40 and FP.routes["ALLIANCE_40_60_OPTIMAL"] then
                    lastId = "ALLIANCE_40_60_OPTIMAL"
                elseif level >= 20 and FP.routes["ALLIANCE_20_40_OPTIMAL"] then
                    lastId = "ALLIANCE_20_40_OPTIMAL"
                elseif FP.routes["ALLIANCE_1_20_OPTIMAL"] then
                    lastId = "ALLIANCE_1_20_OPTIMAL"
                end
            elseif faction == "Horde" then
                if level >= 40 and FP.routes["HORDE_40_60_OPTIMAL"] then
                    lastId = "HORDE_40_60_OPTIMAL"
                elseif level >= 20 and FP.routes["HORDE_20_40_OPTIMAL"] then
                    lastId = "HORDE_20_40_OPTIMAL"
                elseif FP.routes["HORDE_1_20_OPTIMAL"] then
                    lastId = "HORDE_1_20_OPTIMAL"
                end
            end
        end

        if lastId == FP.QUEST_SYNC_ROUTE_ID and FP.RebuildQuestSyncRoute then
            FP:RebuildQuestSyncRoute()
        end

        if lastId and lastId ~= false and FP.routes[lastId] then
            if FP.SetActiveRoute then
                FP:SetActiveRoute(lastId)
            else
                FP.activeRoute = FP.routes[lastId]
                FP.currentStepIndex = nil
            end
        elseif FP.RefreshAllUI then
            FP:RefreshAllUI()
        end

        -- Compartment registration via Lua is omitted to avoid Blizzard secure menu taint (standalone minimap icon is provided)
        FP:Print(string.format(L["ADDON_LOADED"], FP.VERSION))

    elseif event == "PLAYER_ENTERING_WORLD" then
        if FP.UpdateCurrentStep and FP.activeRoute then
            FP:UpdateCurrentStep()
        end
        if FP.OnPlayerEnteringWorld then
            FP:OnPlayerEnteringWorld()
        end

    elseif event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" then
        local blockedAddon = tostring(arg1 or "nil")
        local blockedFunc = tostring(arg2 or "nil")
        local stack = (debugstack and debugstack(2, 6, 6)) or ""
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff2040[NexusKit Diagnostica]|r %s intercettato! Addon: %s | Azione bloccata: %s", event, blockedAddon, blockedFunc))
            if stack ~= "" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffa040[Stack]:|r " .. stack:gsub("\n", " -> "))
            end
        end
    end
end)
