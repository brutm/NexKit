-- NexusKit - UI/ClassFrames.lua
-- Class colors & Class icons for Party frames, Nameplates, and Target when clicking player characters (PCs).
local addonName, FP = ...

local FALLBACK_CLASS_COORDS = {
    ["WARRIOR"]     = {0, 0.25, 0, 0.25},
    ["MAGE"]        = {0.25, 0.49609375, 0, 0.25},
    ["ROGUE"]       = {0.49609375, 0.7421875, 0, 0.25},
    ["DRUID"]       = {0.7421875, 0.98828125, 0, 0.25},
    ["HUNTER"]      = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"]      = {0.25, 0.49609375, 0.25, 0.5},
    ["PRIEST"]      = {0.49609375, 0.7421875, 0.25, 0.5},
    ["WARLOCK"]     = {0.7421875, 0.98828125, 0.25, 0.5},
    ["PALADIN"]     = {0, 0.25, 0.5, 0.75},
}

local function IsForbiddenObj(obj)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return true end
    return (obj.IsForbidden and obj:IsForbidden()) and true or false
end

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsClassFeaturesEnabled()
    return GetSettings().showClassColorsAndIcons ~= false
end

local function GetUnitClassColor(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return nil, nil end
    local ok, _, class = pcall(UnitClass, unit)
    if not ok or not class then return nil, nil end
    local color = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
        or (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or { r = 0.8, g = 0.8, b = 0.8 }
    return color, class
end

local function ApplyClassTextureToIcon(icon, class)
    if not icon or not class then return end
    icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    local coords = (CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]) or FALLBACK_CLASS_COORDS[class]
    if coords then
        icon:SetTexCoord(unpack(coords))
    end
end

-------------------------------------------------------------------------------
-- Specialization & Talent Detection (Player & Inspected Party/Target)
-------------------------------------------------------------------------------
local cachedPlayerSpecs = {}
local lastInspectTargetGUID = nil
local lastInspectTime = 0
local currentTooltipOwner = nil
local currentTooltipUnit = nil

local function GetUnitSpecInfo(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return nil, nil end
    if UnitIsUnit(unit, "player") then
        local maxPoints = -1
        local topName = nil
        local p = {}
        local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3
        for tab = 1, numTabs do
            local _, name, _, _, points = GetTalentTabInfo(tab)
            points = points or 0
            p[#p + 1] = points
            if points > maxPoints then
                maxPoints = points
                topName = name
            end
        end
        local pts = table.concat(p, "/")
        if maxPoints <= 0 then
            return nil, pts
        end
        return topName, pts
    else
        local guid = UnitGUID(unit)
        if guid and cachedPlayerSpecs[guid] then
            return cachedPlayerSpecs[guid].specName, cachedPlayerSpecs[guid].pts
        end
    end
    return nil, nil
end

local function RequestInspectUnit(unit)
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then return end
    if not (CanInspect and CanInspect(unit)) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if CheckInteractDistance and not CheckInteractDistance(unit, 1) then return end

    local now = (GetTime and GetTime()) or 0
    if (now - lastInspectTime) < 1.0 then return end

    local guid = UnitGUID(unit)
    if not guid then return end
    if cachedPlayerSpecs[guid] and ((now - (cachedPlayerSpecs[guid].time or 0)) < 300) then
        return
    end

    if InspectFrame and InspectFrame:IsShown() then return end

    lastInspectTargetGUID = guid
    lastInspectTime = now
    pcall(NotifyInspect, unit)
end

local function ShowPortraitTooltip(owner, unit)
    if not owner or not unit or not UnitExists(unit) then return end
    local isPlayer = UnitIsPlayer(unit)
    local name = UnitName(unit)
    local color, class = GetUnitClassColor(unit)
    local className = (UnitClass and select(1, UnitClass(unit))) or class
    local level = UnitLevel(unit)
    local race = UnitRace and select(1, UnitRace(unit))
    local specName, pts = GetUnitSpecInfo(unit)

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local hex = (color and string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)) or "00ff96"

    if isPlayer and color then
        GameTooltip:AddLine(string.format("|cff%s%s|r", hex, name or "Giocatore"), 1, 1, 1)
    else
        GameTooltip:AddLine(name or "Bersaglio", 1, 1, 1)
    end

    if isPlayer then
        if specName then
            local specDisplay = (pts and pts ~= "") and string.format("%s (%s)", specName, pts) or specName
            GameTooltip:AddLine(string.format("|cff%s%s|r — |cffffffff%s|r", hex, className or "Classe", specDisplay), 1, 1, 1)
        else
            GameTooltip:AddLine(string.format("|cff%s%s|r", hex, className or "Classe"), 1, 1, 1)
            if not UnitIsUnit(unit, "player") then
                RequestInspectUnit(unit)
            end
        end

        local levelStr = (level and level > 0) and ("Livello " .. level) or "??"
        if race then
            GameTooltip:AddLine(string.format("|cffaaaaaa%s %s|r", levelStr, race), 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine(string.format("|cffaaaaaa%s|r", levelStr), 0.8, 0.8, 0.8)
        end
    else
        local creatureType = UnitCreatureType and UnitCreatureType(unit)
        local levelStr = (level and level > 0) and ("Livello " .. level) or "??"
        if creatureType then
            GameTooltip:AddLine(string.format("|cffaaaaaa%s %s|r", levelStr, creatureType), 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine(string.format("|cffaaaaaa%s|r", levelStr), 0.8, 0.8, 0.8)
        end
    end

    GameTooltip:Show()
    currentTooltipOwner = owner
    currentTooltipUnit = unit
end

local function HandleInspectReady(guid)
    if not guid then return end
    if lastInspectTargetGUID and guid ~= lastInspectTargetGUID then return end
    lastInspectTargetGUID = nil

    local numTabs = (GetNumTalentTabs and GetNumTalentTabs(true)) or 3
    local maxPoints = -1
    local topName = nil
    local p = {}
    for tab = 1, numTabs do
        local _, name, _, _, points = GetTalentTabInfo(tab, true)
        points = points or 0
        p[#p + 1] = points
        if points > maxPoints then
            maxPoints = points
            topName = name
        end
    end
    local pts = table.concat(p, "/")
    cachedPlayerSpecs[guid] = {
        specName = (maxPoints > 0) and topName or nil,
        pts = pts,
        time = (GetTime and GetTime()) or 0,
    }

    if ClearInspectPlayer then
        pcall(ClearInspectPlayer)
    end

    if currentTooltipOwner and currentTooltipUnit and UnitExists(currentTooltipUnit) then
        if UnitGUID(currentTooltipUnit) == guid and GameTooltip:IsShown() then
            ShowPortraitTooltip(currentTooltipOwner, currentTooltipUnit)
        end
    end
end

local function SetupPortraitHover(parentFrame, portraitTexture, getUnitFunc)
    if not parentFrame or not portraitTexture or parentFrame.nkPortraitHover then return end

    local overlay = CreateFrame("Frame", nil, parentFrame)
    overlay:SetAllPoints(portraitTexture)
    overlay:SetFrameLevel((parentFrame.GetFrameLevel and parentFrame:GetFrameLevel() or 1) + 5)
    overlay:EnableMouse(true)
    if overlay.SetPropagateMouseClicks then
        overlay:SetPropagateMouseClicks(true)
    end
    if overlay.SetPassThroughButtons then
        overlay:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
    end

    overlay:SetScript("OnEnter", function(self)
        if not IsClassFeaturesEnabled() then return end
        local unit = getUnitFunc and getUnitFunc()
        if unit and UnitExists(unit) then
            ShowPortraitTooltip(self, unit)
        end
    end)

    overlay:SetScript("OnLeave", function(self)
        if currentTooltipOwner == self then
            currentTooltipOwner = nil
            currentTooltipUnit = nil
        end
        GameTooltip:Hide()
    end)

    parentFrame.nkPortraitHover = overlay
end

local function SetupAllPortraitHovers()
    -- Player Frame
    if PlayerFrame then
        local pTex = PlayerPortrait or PlayerFrame.portrait
        if pTex then
            SetupPortraitHover(PlayerFrame, pTex, function() return "player" end)
        end
    end

    -- Target Frame
    if TargetFrame then
        local tTex = TargetFramePortrait or TargetFrame.portrait
        if tTex then
            SetupPortraitHover(TargetFrame, tTex, function() return "target" end)
        end
    end

    -- Party Frames
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            local pTex = _G["PartyMemberFrame" .. i .. "Portrait"] or f.portrait
            if pTex then
                SetupPortraitHover(f, pTex, function() return "party" .. i end)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 1. Party Frames (PartyMemberFrame1..4)
-------------------------------------------------------------------------------
local function UpdatePartyMember(frame)
    if not frame or IsForbiddenObj(frame) then return end
    if not IsClassFeaturesEnabled() then
        if frame.nkClassIcon then frame.nkClassIcon:Hide() end
        return
    end

    local id = frame.GetID and frame:GetID()
    local unit = frame.unit or (id and ("party" .. id))
    if not unit or not UnitExists(unit) then
        if frame.nkClassIcon then frame.nkClassIcon:Hide() end
        return
    end

    local color, class = GetUnitClassColor(unit)
    if color and class then
        local healthbar = frame.healthbar or _G[frame:GetName() .. "HealthBar"]
        if healthbar and healthbar.SetStatusBarColor then
            healthbar:SetStatusBarColor(color.r, color.g, color.b)
        end

        local icon = frame.nkClassIcon
        if not icon then
            icon = frame:CreateTexture(nil, "ARTWORK", nil, 6)
            icon:SetSize(18, 18)
            icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -2)
            frame.nkClassIcon = icon
        end
        ApplyClassTextureToIcon(icon, class)
        icon:Show()
    else
        if frame.nkClassIcon then frame.nkClassIcon:Hide() end
    end
end

local function UpdateAllPartyMembers()
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            UpdatePartyMember(frame)
        end
    end
end

-------------------------------------------------------------------------------
-- 2. Target Frame (Quando clicchi su qualsiasi PG)
-------------------------------------------------------------------------------
local function UpdateTargetFrame()
    if not TargetFrame or IsForbiddenObj(TargetFrame) then return end
    if not TargetFrame:IsShown() then
        if TargetFrame.nkClassIcon then TargetFrame.nkClassIcon:Hide() end
        return
    end

    if not IsClassFeaturesEnabled() then
        if TargetFrame.nkClassIcon then TargetFrame.nkClassIcon:Hide() end
        return
    end

    local unit = TargetFrame.unit or "target"
    local color, class = GetUnitClassColor(unit)
    local healthbar = TargetFrameHealthBar or TargetFrame.healthbar

    if color and class then
        if healthbar and healthbar.SetStatusBarColor then
            healthbar:SetStatusBarColor(color.r, color.g, color.b)
        end

        local icon = TargetFrame.nkClassIcon
        if not icon then
            icon = TargetFrame:CreateTexture(nil, "ARTWORK", nil, 6)
            icon:SetSize(22, 22)
            icon:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", -22, -10)
            TargetFrame.nkClassIcon = icon
        end
        ApplyClassTextureToIcon(icon, class)
        icon:Show()
    else
        if TargetFrame.nkClassIcon then
            TargetFrame.nkClassIcon:Hide()
        end
        -- Restore Blizzard's native selection color for NPCs and mobs (Red for hostile, Green for friendly, Yellow for neutral)
        if healthbar and healthbar.SetStatusBarColor and UnitExists(unit) then
            local r, g, b = UnitSelectionColor(unit)
            if r and g and b then
                healthbar:SetStatusBarColor(r, g, b)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 3. Nameplates (Barra della vita con colore di classe + icona classe su ogni PG)
-------------------------------------------------------------------------------
local activePlayerPlates = {}

local function UpdateNameplateUnit(unit)
    if not unit or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate or IsForbiddenObj(plate) then return end

    local host = (plate.UnitFrame and not IsForbiddenObj(plate.UnitFrame) and plate.UnitFrame) or plate
    if IsForbiddenObj(host) then return end

    if not IsClassFeaturesEnabled() or not UnitIsPlayer(unit) then
        if host.nkClassIcon then host.nkClassIcon:Hide() end
        activePlayerPlates[plate] = nil
        return
    end

    local color, class = GetUnitClassColor(unit)
    if color and class then
        activePlayerPlates[plate] = unit

        local healthBar = host.healthBar or host.HealthBar
        if healthBar and healthBar.SetStatusBarColor then
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        end

        local icon = host.nkClassIcon
        if not icon then
            icon = host:CreateTexture(nil, "OVERLAY", nil, 6)
            icon:SetSize(16, 16)
            local nameFs = host.name or host.Name
            if nameFs and nameFs.IsVisible and nameFs:IsVisible() then
                icon:SetPoint("RIGHT", nameFs, "LEFT", -3, 0)
            elseif healthBar then
                icon:SetPoint("RIGHT", healthBar, "LEFT", -4, 0)
            else
                icon:SetPoint("LEFT", host, "LEFT", -18, 0)
            end
            host.nkClassIcon = icon
        end
        ApplyClassTextureToIcon(icon, class)
        icon:Show()
    else
        if host.nkClassIcon then host.nkClassIcon:Hide() end
        activePlayerPlates[plate] = nil
    end
end

local function RemoveNameplateUnit(unit)
    if not unit or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and not IsForbiddenObj(plate) then
        local host = (plate.UnitFrame and not IsForbiddenObj(plate.UnitFrame) and plate.UnitFrame) or plate
        if host and host.nkClassIcon then
            host.nkClassIcon:Hide()
        end
        activePlayerPlates[plate] = nil
    end
end

-------------------------------------------------------------------------------
-- Hooks & Event Wiring
-------------------------------------------------------------------------------
local function EnhanceUnitTooltip(tooltip)
    if not tooltip or not IsClassFeaturesEnabled() then return end
    local _, unit = tooltip:GetUnit()
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    local n = tooltip:NumLines() or 0
    local name = tooltip:GetName()
    if name then
        for i = 1, n do
            local line = _G[name .. "TextLeft" .. i]
            if line then
                local text = line:GetText()
                if text and (text:find("Spec:", 1, true) or text:find("Specializzazione:", 1, true)) then
                    return
                end
            end
        end
    end

    local specName, pts = GetUnitSpecInfo(unit)
    if specName then
        local specLine = (pts and pts ~= "") and string.format("|cffffd100Spec:|r |cff00ff96%s|r |cff888888(%s)|r", specName, pts)
            or string.format("|cffffd100Spec:|r |cff00ff96%s|r", specName)
        tooltip:AddLine(specLine, 1, 1, 1)
        tooltip:Show()
    else
        if not UnitIsUnit(unit, "player") then
            RequestInspectUnit(unit)
        end
    end
end

local function HookBlizzardUnitFrames()
    SetupAllPortraitHovers()

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            pcall(EnhanceUnitTooltip, tooltip)
        end)
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            pcall(EnhanceUnitTooltip, self)
        end)
    end

    if PartyMemberFrame_UpdateMember then
        hooksecurefunc("PartyMemberFrame_UpdateMember", function(frame)
            UpdatePartyMember(frame)
            SetupAllPortraitHovers()
        end)
    end
    if UnitFrameHealthBar_Update then
        hooksecurefunc("UnitFrameHealthBar_Update", function(bar, unit)
            if not IsClassFeaturesEnabled() or not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
            if unit == "target" then
                UpdateTargetFrame()
            elseif unit:match("^party%d+$") then
                local num = unit:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        end)
    end
    if TargetFrame_Update then
        hooksecurefunc("TargetFrame_Update", function()
            UpdateTargetFrame()
            SetupAllPortraitHovers()
        end)
    end
end

local function SafeRegisterEvent(frame, evt)
    pcall(frame.RegisterEvent, frame, evt)
end

local evFrame = CreateFrame("Frame")
SafeRegisterEvent(evFrame, "PLAYER_LOGIN")
SafeRegisterEvent(evFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(evFrame, "GROUP_ROSTER_UPDATE")
SafeRegisterEvent(evFrame, "PARTY_MEMBERS_CHANGED")
SafeRegisterEvent(evFrame, "PLAYER_TARGET_CHANGED")
SafeRegisterEvent(evFrame, "NAME_PLATE_UNIT_ADDED")
SafeRegisterEvent(evFrame, "NAME_PLATE_UNIT_REMOVED")
SafeRegisterEvent(evFrame, "UNIT_HEALTH")
SafeRegisterEvent(evFrame, "UNIT_MAXHEALTH")
SafeRegisterEvent(evFrame, "INSPECT_READY")
SafeRegisterEvent(evFrame, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(evFrame, "CHARACTER_POINTS_CHANGED")

evFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    pcall(function()
        if event == "PLAYER_LOGIN" then
            HookBlizzardUnitFrames()
            UpdateAllPartyMembers()
            UpdateTargetFrame()
            SetupAllPortraitHovers()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            UpdateAllPartyMembers()
            UpdateTargetFrame()
            SetupAllPortraitHovers()
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateTargetFrame()
            SetupAllPortraitHovers()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            UpdateNameplateUnit(arg1)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            RemoveNameplateUnit(arg1)
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if arg1 == "target" then
                UpdateTargetFrame()
            elseif arg1 and arg1:match("^party%d+$") then
                local num = arg1:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        elseif event == "INSPECT_READY" then
            HandleInspectReady(arg1)
        elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" then
            -- Player's talents refreshed
            if currentTooltipOwner and currentTooltipUnit and UnitIsUnit(currentTooltipUnit, "player") then
                ShowPortraitTooltip(currentTooltipOwner, currentTooltipUnit)
            end
        end
    end)
end)

function FP:RefreshClassFrames()
    UpdateAllPartyMembers()
    UpdateTargetFrame()
    if C_NamePlate and C_NamePlate.GetNamePlates then
        local plates = C_NamePlate.GetNamePlates()
        if type(plates) == "table" then
            for _, plate in ipairs(plates) do
                if plate and plate.UnitFrame and plate.UnitFrame.unit then
                    UpdateNameplateUnit(plate.UnitFrame.unit)
                end
            end
        end
    end
end
