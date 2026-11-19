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
    if color and class then
        local healthbar = TargetFrameHealthBar or TargetFrame.healthbar
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
local function HookBlizzardUnitFrames()
    if PartyMemberFrame_UpdateMember then
        hooksecurefunc("PartyMemberFrame_UpdateMember", UpdatePartyMember)
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
        hooksecurefunc("TargetFrame_Update", UpdateTargetFrame)
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

evFrame:SetScript("OnEvent", function(self, event, unit)
    pcall(function()
        if event == "PLAYER_LOGIN" then
            HookBlizzardUnitFrames()
            UpdateAllPartyMembers()
            UpdateTargetFrame()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            UpdateAllPartyMembers()
            UpdateTargetFrame()
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateTargetFrame()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            UpdateNameplateUnit(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            RemoveNameplateUnit(unit)
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if unit == "target" then
                UpdateTargetFrame()
            elseif unit and unit:match("^party%d+$") then
                local num = unit:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
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
