-- NexusKit - UI/DispelAlert.lua
-- Real-Time Dispellable Debuff Alert HUD (Self, Party & Raid)
-- Alerts when you or an ally has a Magic, Poison, Disease, or Curse debuff
-- that your character can currently dispel, showing the target, debuff, spell & keybind.
local addonName, FP = ...

local ACCENT = { r = 0.25, g = 0.75, b = 1.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local IsSecret          = FP.IsSecret
local IsAccessible      = FP.IsAccessible
local IsSafeNum         = FP.IsSafeNum
local IsSafeStr         = FP.IsSafeStr
local SafeCall          = FP.SafeCall
local SafeBoolean       = FP.SafeBoolean
local SafeNumber        = FP.SafeNumber
local SafeRegisterEvent = FP.SafeRegisterEvent
local DISPEL_COLORS     = FP.DISPEL_COLORS or {
    Magic   = { r = 0.20, g = 0.65, b = 1.00 },
    Curse   = { r = 0.70, g = 0.25, b = 1.00 },
    Disease = { r = 0.85, g = 0.48, b = 0.12 },
    Poison  = { r = 0.10, g = 0.85, b = 0.20 },
    none    = { r = 0.85, g = 0.15, b = 0.15 },
}

local function GetSettings()
    local db = NexKitDB or NexusKitDB
    return (db and db.settings) or {}
end

local function IsDispelAlertEnabled()
    return GetSettings().enableDispelAlert ~= false
end

local function IsDispelSoundEnabled()
    return GetSettings().dispelAlertSound ~= false
end

local function IsDispelAlertLocked()
    return GetSettings().dispelAlertLocked ~= false
end

local function GetDispelAlertScale()
    local s = tonumber(GetSettings().dispelAlertScale) or 1.0
    if s < 0.70 then s = 0.70 elseif s > 1.50 then s = 1.50 end
    return s
end

local function GetClassColorHex(unit)
    local _, cls = UnitClass and SafeCall(UnitClass, unit)
    if IsSafeStr(cls) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls] then
        local c = RAID_CLASS_COLORS[cls]
        return string.format("%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255))
    end
    return "ffffff"
end

local function IsUnitSpellInRange(spellID, unit)
    if not unit or unit == "player" or not spellID then return true end
    if C_Spell and C_Spell.IsSpellInRange then
        local r = SafeCall(C_Spell.IsSpellInRange, spellID, unit)
        if IsAccessible(r) and r ~= nil then
            return (r == true or r == 1)
        end
    elseif IsSpellInRange then
        local r = SafeCall(IsSpellInRange, spellID, unit)
        if IsAccessible(r) and r ~= nil then
            return (r == true or r == 1)
        end
    end
    return true
end

local function GetUnitHealthPct(unit)
    if not UnitHealth or not UnitHealthMax then return 1.0 end
    local hp = SafeCall(UnitHealth, unit)
    local maxHp = SafeCall(UnitHealthMax, unit)
    if IsSafeNum(hp) and IsSafeNum(maxHp) and maxHp > 0 then
        return math.max(0, math.min(1, hp / maxHp))
    end
    return 1.0
end

local function GetLocalizedSchoolLabel(school)
    local L = FP.L or {}
    if school == "Magic" then
        return L["DISPEL_TYPE_MAGIC"] or "DISPEL MAGIC"
    elseif school == "Curse" then
        return L["DISPEL_TYPE_CURSE"] or "REMOVE CURSE"
    elseif school == "Disease" then
        return L["DISPEL_TYPE_DISEASE"] or "CURE DISEASE"
    elseif school == "Poison" then
        return L["DISPEL_TYPE_POISON"] or "CURE POISON"
    end
    return L["DISPEL_TYPE_GENERIC"] or "DISPEL DEBUFF"
end

-------------------------------------------------------------------------------
-- Scanner: Self, Party1..4, or Raid1..40
-------------------------------------------------------------------------------
local function CollectTargetUnits()
    local units = { "player" }
    local inRaid = IsInRaid and SafeBoolean(SafeCall(IsInRaid), false)
    if inRaid then
        local n = (GetNumGroupMembers and SafeNumber(SafeCall(GetNumGroupMembers), 0)) or 0
        n = math.min(n, 40)
        for i = 1, n do
            local u = "raid" .. i
            if UnitExists and SafeBoolean(SafeCall(UnitExists, u), false) then
                if not (UnitIsUnit and SafeBoolean(SafeCall(UnitIsUnit, u, "player"), false)) then
                    units[#units + 1] = u
                end
            end
        end
    else
        local inParty = (IsInGroup and SafeBoolean(SafeCall(IsInGroup), false))
            or (GetNumPartyMembers and SafeNumber(SafeCall(GetNumPartyMembers), 0) > 0)
        if inParty then
            for i = 1, 4 do
                local u = "party" .. i
                if UnitExists and SafeBoolean(SafeCall(UnitExists, u), false) then
                    units[#units + 1] = u
                end
            end
        end
    end
    return units
end

local function PickFallbackDispelSchool(dispelInfo)
    if dispelInfo and dispelInfo.schools then
        if dispelInfo.schools["Magic"] then return "Magic" end
        local k = next(dispelInfo.schools)
        if k then return k end
    end
    return "Magic"
end

local function SafeReadAuraFields(unit, aura)
    local okI, rawInstanceID = pcall(function() return aura.auraInstanceID end)
    if not okI then rawInstanceID = nil end
    local okN, rawName = pcall(function() return aura.name end)
    if not okN then rawName = nil end
    local okIc, rawIcon = pcall(function() return aura.icon end)
    if not okIc then rawIcon = nil end
    local okA, rawApps = pcall(function() return aura.applications end)
    if not okA then rawApps = nil end
    local okD, rawDispel = pcall(function() return aura.dispelName end)
    if not okD then rawDispel = nil end
    local okDu, rawDur = pcall(function() return aura.duration end)
    if not okDu then rawDur = nil end
    local okEx, rawExp = pcall(function() return aura.expirationTime end)
    if not okEx then rawExp = nil end

    local durObj = nil
    if rawInstanceID ~= nil and C_UnitAuras and C_UnitAuras.GetAuraDuration then
        local okObj, obj = pcall(C_UnitAuras.GetAuraDuration, unit, rawInstanceID)
        if okObj and obj ~= nil then
            durObj = obj
        end
    end

    return {
        rawInstanceID  = rawInstanceID,
        safeInstanceID = IsAccessible(rawInstanceID) and rawInstanceID or nil,
        rawName        = rawName,
        safeName       = IsSafeStr(rawName) and rawName or nil,
        rawIcon        = rawIcon,
        safeIcon       = IsAccessible(rawIcon) and rawIcon or nil,
        safeApps       = SafeNumber(rawApps, 0),
        safeDispel     = IsSafeStr(rawDispel) and rawDispel or nil,
        dispelIsSecret = IsSecret(rawDispel) and true or false,
        safeDur        = SafeNumber(rawDur, 0),
        safeExp        = SafeNumber(rawExp, 0),
        durationObj    = durObj,
    }
end

local knownDebuffSchools = FP.nkKnownDebuffSchools
local NON_DISPELLABLE_DEBUFFS = FP.NON_DISPELLABLE_DEBUFFS
local lastSafeUnitNames = {}
local lastSafeUnitGUIDs = {}

local function IsInstanceDispellableByPlayer(unit, rawInstanceID)
    if rawInstanceID == nil or not C_UnitAuras or not C_UnitAuras.IsAuraFilteredOutByInstanceID then
        return false
    end
    local okF, filteredOut = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, rawInstanceID, "HARMFUL|RAID_PLAYER_DISPELLABLE")
    if okF and not IsSecret(filteredOut) and filteredOut == false then
        return true
    end
    return false
end

local function ScanUnitDispellables(unit, dispelInfo, outList)
    if not UnitExists or SafeBoolean(SafeCall(UnitExists, unit), false) ~= true then return end
    if UnitIsConnected and SafeBoolean(SafeCall(UnitIsConnected, unit), true) ~= true then return end
    if UnitIsDeadOrGhost and SafeBoolean(SafeCall(UnitIsDeadOrGhost, unit), false) == true then return end

    local isPlayer = (unit == "player") or (UnitIsUnit and SafeBoolean(SafeCall(UnitIsUnit, unit, "player"), false) == true)
    local unitRole = UnitGroupRolesAssigned and SafeCall(UnitGroupRolesAssigned, unit)
    local hpPct = GetUnitHealthPct(unit)
    local rawGUID = UnitGUID and SafeCall(UnitGUID, unit)
    local unitGUID = IsSafeStr(rawGUID) and rawGUID or unit
    if IsSafeStr(rawGUID) and lastSafeUnitGUIDs[unit] ~= rawGUID then
        lastSafeUnitGUIDs[unit] = rawGUID
        lastSafeUnitNames[unit] = nil
    end
    local okUN, rawName = pcall(UnitName, unit)
    rawName = okUN and rawName or nil
    if IsSafeStr(rawName) then
        lastSafeUnitNames[unit] = rawName
    end
    local unitName = (IsSafeStr(rawName) and rawName) or lastSafeUnitNames[unit] or unit
    local rawUnitName = (not IsSafeStr(rawName) and IsSecret(rawName)) and rawName or nil
    local colorHex = GetClassColorHex(unit)
    local now = (GetTime and SafeCall(GetTime)) or 0
    local fallbackSchool = PickFallbackDispelSchool(dispelInfo)

    local function PushMatch(matchedSchool, f)
        local spellInfo = dispelInfo.spellsBySchool[matchedSchool]
        if not spellInfo then
            spellInfo = dispelInfo.spellsBySchool[fallbackSchool]
            if not spellInfo then
                local _, firstSpell = next(dispelInfo.spellsBySchool)
                spellInfo = firstSpell
            end
        end
        if not spellInfo then return end

        local inRange = isPlayer or IsUnitSpellInRange(spellInfo.spellID, unit)
        local cdRem, cdDur, isReady, cdDurObj = 0, 0, true, nil
        if FP.GetSpellCooldown then
            local rRem, rDur, rReady, rObj = FP.GetSpellCooldown(spellInfo.spellID)
            cdRem = SafeNumber(rRem, 0)
            cdDur = SafeNumber(rDur, 0)
            isReady = SafeBoolean(rReady, true)
            cdDurObj = rObj
        end

        local remSec = (f.safeExp > 0 and IsSafeNum(now)) and math.max(0, f.safeExp - now) or 0
        local stacks = f.safeApps or 0

        local score = 0
        if inRange then score = score + 10000 end
        if isReady then score = score + 5000 end
        if isPlayer then
            score = score + 2000
        elseif unitRole == "TANK" then
            score = score + 1200
        elseif unitRole == "HEALER" then
            score = score + 1000
        end
        score = score + math.floor((1 - hpPct) * 500) + math.min(stacks, 10) * 15

        outList[#outList + 1] = {
            unit              = unit,
            unitGUID          = unitGUID,
            unitName          = unitName,
            rawUnitName       = rawUnitName,
            isPlayer          = isPlayer,
            colorHex          = colorHex,
            debuffName        = f.safeName or "Debuff",
            rawDebuffName     = (not f.safeName and IsSecret(f.rawName)) and f.rawName or nil,
            debuffIcon        = f.safeIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
            rawDebuffIcon     = f.rawIcon,
            auraInstanceID    = f.safeInstanceID,
            debuffDurationObj = f.durationObj,
            secretColorObj    = f.secretColorObj,
            stacks            = stacks,
            remaining         = remSec,
            duration          = f.safeDur or 0,
            school            = matchedSchool,
            spellID           = spellInfo.spellID,
            spellName         = spellInfo.name,
            spellIcon         = spellInfo.icon,
            inRange           = inRange,
            cdRemaining       = cdRem or 0,
            cdDuration        = cdDur or 0,
            cdDurationObj     = cdDurObj,
            isSpellReady      = isReady,
            score             = score,
        }
    end

    local function ResolveSecretDebuffSchool(f)
        local cached = f.safeInstanceID and knownDebuffSchools[f.safeInstanceID] or nil
        if cached == false then
            return nil
        elseif cached and dispelInfo.schools[cached] then
            return cached
        end
        if FP.ProbeAuraDispelColor then
            local probeStatus, probeSchool, probeColor = FP:ProbeAuraDispelColor(unit, f.rawInstanceID, dispelInfo.schools)
            if probeStatus == "matched" then
                if f.safeInstanceID then knownDebuffSchools[f.safeInstanceID] = probeSchool end
                return probeSchool
            elseif probeStatus == "none" then
                if f.safeInstanceID then knownDebuffSchools[f.safeInstanceID] = false end
                return nil
            elseif probeStatus == "secret" then
                f.secretColorObj = probeColor
            end
        end
        return "SECRET_UNVERIFIED"
    end

    -- Pass 1 (Combat Midnight Secret-Value Safe): Ask C_UnitAuras directly for HARMFUL|RAID_PLAYER_DISPELLABLE
    local filterHitCount = 0
    local seenInstances = {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 16 do
            local okF, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL|RAID_PLAYER_DISPELLABLE")
            if not okF or type(aura) ~= "table" then
                break
            end
            local f = SafeReadAuraFields(unit, aura)
            if f.safeName and NON_DISPELLABLE_DEBUFFS[f.safeName] then
                if f.safeInstanceID then knownDebuffSchools[f.safeInstanceID] = false end
            elseif not (f.safeInstanceID and seenInstances[f.safeInstanceID]) then
                if f.safeInstanceID then seenInstances[f.safeInstanceID] = true end
                if not f.dispelIsSecret then
                    -- Readable dispelName: enforce strict school match and remember non-dispellable instances
                    if f.safeInstanceID then
                        knownDebuffSchools[f.safeInstanceID] = f.safeDispel or false
                    end
                    if f.safeDispel and dispelInfo.schools[f.safeDispel] then
                        PushMatch(f.safeDispel, f)
                        filterHitCount = filterHitCount + 1
                    elseif not f.safeDispel then
                        -- Client ignored RAID_PLAYER_DISPELLABLE and returned a non-dispellable debuff (e.g. Webs/Physical)
                        FP.nkRaidDispelFilterBroken = true
                    end
                else
                    local resolved = ResolveSecretDebuffSchool(f)
                    if resolved == "SECRET_UNVERIFIED" then
                        if not FP.nkRaidDispelFilterBroken then
                            PushMatch(fallbackSchool, f)
                            filterHitCount = filterHitCount + 1
                        end
                    elseif resolved then
                        PushMatch(resolved, f)
                        filterHitCount = filterHitCount + 1
                    end
                end
            end
        end
    end

    if filterHitCount > 0 then
        return
    end

    -- Pass 2: Full HARMFUL scan (handles readable dispelName, pre-combat cache, color-curve & RAID_PLAYER_DISPELLABLE)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 24 do
            local okC, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not okC or type(aura) ~= "table" then
                break
            end
            local f = SafeReadAuraFields(unit, aura)
            if f.safeName and NON_DISPELLABLE_DEBUFFS[f.safeName] then
                if f.safeInstanceID then knownDebuffSchools[f.safeInstanceID] = false end
            else
                if not f.dispelIsSecret and f.safeInstanceID then
                    knownDebuffSchools[f.safeInstanceID] = f.safeDispel or false
                end
                local matchedSchool = nil
                if f.safeDispel and dispelInfo.schools[f.safeDispel] then
                    matchedSchool = f.safeDispel
                elseif f.dispelIsSecret then
                    local resolved = ResolveSecretDebuffSchool(f)
                    if resolved == "SECRET_UNVERIFIED" then
                        if not FP.nkRaidDispelFilterBroken and IsInstanceDispellableByPlayer(unit, f.rawInstanceID) then
                            matchedSchool = fallbackSchool
                        end
                    elseif resolved then
                        matchedSchool = resolved
                    end
                end
                if matchedSchool then
                    PushMatch(matchedSchool, f)
                end
            end
        end
    elseif UnitDebuff then
        for i = 1, 24 do
            local okD, dName, dIcon, dCount, dDispel, dDur, dExp = pcall(UnitDebuff, unit, i)
            if not okD or not dName then
                break
            end
            local safeDName = IsSafeStr(dName) and dName or nil
            local safeDispel = IsSafeStr(dDispel) and dDispel or nil
            if safeDName and NON_DISPELLABLE_DEBUFFS[safeDName] then
                -- Skip known non-dispellable debuffs
            elseif safeDispel and dispelInfo.schools[safeDispel] then
                PushMatch(safeDispel, {
                    safeName   = safeDName,
                    rawIcon    = dIcon,
                    safeIcon   = IsAccessible(dIcon) and dIcon or nil,
                    safeApps   = SafeNumber(dCount, 0),
                    safeDispel = safeDispel,
                    safeDur    = SafeNumber(dDur, 0),
                    safeExp    = SafeNumber(dExp, 0),
                })
            end
        end
    end
end

local function ScanGroupDispellables()
    local dispelInfo = FP.GetPlayerDispelInfo and FP:GetPlayerDispelInfo()
    if not dispelInfo or not dispelInfo.canDispelAny then
        return {}
    end

    local results = {}
    local units = CollectTargetUnits()
    for _, u in ipairs(units) do
        ScanUnitDispellables(u, dispelInfo, results)
    end

    if #results > 1 then
        table.sort(results, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            if a.remaining ~= b.remaining then
                if a.remaining == 0 then return false end
                if b.remaining == 0 then return true end
                return a.remaining < b.remaining
            end
            return a.unit < b.unit
        end)
    end
    return results
end

-------------------------------------------------------------------------------
-- Position & Sound Presets
-------------------------------------------------------------------------------
local DISPEL_POS_PRESETS = {
    { key = "TOPRIGHT",  labelKey = "DISPEL_POS_TOPRIGHT",  fallback = "Top Right",         point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -230, y = -145 },
    { key = "TOPLEFT",   labelKey = "DISPEL_POS_TOPLEFT",   fallback = "Top Left",          point = "TOPLEFT",  relPoint = "TOPLEFT",  x = 24,   y = -145 },
    { key = "TOPCENTER", labelKey = "DISPEL_POS_TOPCENTER", fallback = "Top Center",        point = "TOP",      relPoint = "TOP",      x = 0,    y = -90  },
    { key = "CENTER",    labelKey = "DISPEL_POS_CENTER",    fallback = "Center (Above PC)", point = "CENTER",   relPoint = "CENTER",   x = 0,    y = 155  },
    { key = "CUSTOM",    labelKey = "DISPEL_POS_CUSTOM",    fallback = "Custom (Drag)" },
}
FP.DISPEL_POS_PRESETS = DISPEL_POS_PRESETS

local DISPEL_SOUND_PRESETS = {
    { key = "readycheck", labelKey = "DISPEL_SND_READYCHECK", fallback = "Ready Check (Default)", kit = "READY_CHECK",           fallbackId = 8960  },
    { key = "ping",       labelKey = "DISPEL_SND_PING",       fallback = "Map Ping",              kit = "MAP_PING",              fallbackId = 3175  },
    { key = "raid",       labelKey = "DISPEL_SND_RAID",       fallback = "Raid Warning",          kit = "RAID_WARNING",          fallbackId = 8959  },
    { key = "alarm",      labelKey = "DISPEL_SND_ALARM",      fallback = "Clock Chime",           kit = "ALARM_CLOCK_WARNING_3", fallbackId = 12889 },
}
FP.DISPEL_SOUND_PRESETS = DISPEL_SOUND_PRESETS

local function FindPreset(tbl, key)
    for _, opt in ipairs(tbl) do
        if opt.key == key then return opt end
    end
    return tbl[1]
end

-------------------------------------------------------------------------------
-- Alert HUD Frame (Non-Secure, 100% Combat-Safe Visuals & Movement)
-------------------------------------------------------------------------------
local alertFrame = CreateFrame("Frame", "NKDispelAlertFrame", UIParent, "BackdropTemplate")
alertFrame:SetSize(304, 58)
alertFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -230, -145)
alertFrame:SetClampedToScreen(true)
alertFrame:SetMovable(true)
alertFrame:EnableMouse(false)
alertFrame:SetFrameStrata("HIGH")
alertFrame:SetFrameLevel(60)
alertFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 16, edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
alertFrame:SetBackdropColor(0.05, 0.06, 0.09, 0.94)
alertFrame:SetBackdropBorderColor(0.20, 0.65, 1.00, 1.00)
alertFrame.secretBorder = FP.CreateEdgeBorderOverlay and FP:CreateEdgeBorderOverlay(alertFrame, 2, 0, alertFrame:GetFrameLevel() + 8) or nil
alertFrame:Hide()

alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", function(self)
    if not IsDispelAlertLocked() and not (InCombatLockdown and InCombatLockdown()) then
        self:StartMoving()
    end
end)
alertFrame:SetScript("OnDragStop", function(self)
    if InCombatLockdown and InCombatLockdown() then return end
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    local s = GetSettings()
    s.dispelAlertPosPreset = "CUSTOM"
    s.dispelAlertPos = { point = point, relPoint = relPoint, x = x, y = y }
    if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
end)

-- Debuff Icon Box (Left)
local debuffBox = CreateFrame("Frame", nil, alertFrame, "BackdropTemplate")
debuffBox:SetSize(42, 42)
debuffBox:SetPoint("LEFT", alertFrame, "LEFT", 8, 0)
debuffBox:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 16, edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
debuffBox:SetBackdropColor(0, 0, 0, 0.9)
debuffBox.secretBorder = FP.CreateEdgeBorderOverlay and FP:CreateEdgeBorderOverlay(debuffBox, 2, 0, debuffBox:GetFrameLevel() + 8) or nil

local debuffIcon = debuffBox:CreateTexture(nil, "ARTWORK")
debuffIcon:SetPoint("TOPLEFT", 2, -2)
debuffIcon:SetPoint("BOTTOMRIGHT", -2, 2)
debuffIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local debuffCooldown = CreateFrame("Cooldown", nil, debuffBox, "CooldownFrameTemplate")
debuffCooldown:SetPoint("TOPLEFT", 2, -2)
debuffCooldown:SetPoint("BOTTOMRIGHT", -2, 2)
if debuffCooldown.SetDrawEdge then debuffCooldown:SetDrawEdge(true) end
if debuffCooldown.SetSwipeColor then debuffCooldown:SetSwipeColor(0, 0, 0, 0.55) end
if debuffCooldown.SetHideCountdownNumbers then debuffCooldown:SetHideCountdownNumbers(false) end

local debuffTextOverlay = CreateFrame("Frame", nil, debuffBox)
debuffTextOverlay:SetAllPoints(debuffBox)
debuffTextOverlay:SetFrameLevel(debuffCooldown:GetFrameLevel() + 6)

local debuffTimer = debuffTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
debuffTimer:SetPoint("CENTER", debuffTextOverlay, "CENTER", 0, 0)
debuffTimer:SetTextColor(1, 0.95, 0.25, 1)

local debuffStacks = debuffTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
debuffStacks:SetPoint("BOTTOMRIGHT", debuffTextOverlay, "BOTTOMRIGHT", -2, 2)

-- Dispel Spell Icon Box (Right)
local spellBox = CreateFrame("Frame", nil, alertFrame, "BackdropTemplate")
spellBox:SetSize(38, 38)
spellBox:SetPoint("RIGHT", alertFrame, "RIGHT", -8, 0)
spellBox:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 16, edgeSize = 1.5,
    insets = { left = 1.5, right = 1.5, top = 1.5, bottom = 1.5 }
})
spellBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95)
spellBox:SetBackdropBorderColor(0.85, 0.85, 0.90, 0.9)

local spellIcon = spellBox:CreateTexture(nil, "ARTWORK")
spellIcon:SetPoint("TOPLEFT", 1.5, -1.5)
spellIcon:SetPoint("BOTTOMRIGHT", -1.5, 1.5)
spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local spellCooldown = CreateFrame("Cooldown", nil, spellBox, "CooldownFrameTemplate")
spellCooldown:SetPoint("TOPLEFT", 1.5, -1.5)
spellCooldown:SetPoint("BOTTOMRIGHT", -1.5, 1.5)
if spellCooldown.SetDrawEdge then spellCooldown:SetDrawEdge(true) end
if spellCooldown.SetSwipeColor then spellCooldown:SetSwipeColor(0, 0, 0, 0.72) end
if spellCooldown.SetHideCountdownNumbers then spellCooldown:SetHideCountdownNumbers(true) end

local spellTextOverlay = CreateFrame("Frame", nil, spellBox)
spellTextOverlay:SetAllPoints(spellBox)
spellTextOverlay:SetFrameLevel(spellCooldown:GetFrameLevel() + 6)

local spellKeybind = spellTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
spellKeybind:SetPoint("TOPRIGHT", spellTextOverlay, "TOPRIGHT", -2, -2)
spellKeybind:SetTextColor(1, 1, 1, 1)

-- Center Info Texts
local titleText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOPLEFT", debuffBox, "TOPRIGHT", 8, -1)
titleText:SetPoint("RIGHT", spellBox, "LEFT", -8, 0)
titleText:SetJustifyH("LEFT")
if titleText.SetWordWrap then titleText:SetWordWrap(false) end

local targetText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
targetText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
targetText:SetPoint("RIGHT", spellBox, "LEFT", -8, 0)
targetText:SetJustifyH("LEFT")
if targetText.SetWordWrap then targetText:SetWordWrap(false) end

local actionText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
actionText:SetPoint("TOPLEFT", targetText, "BOTTOMLEFT", 0, -2)
actionText:SetPoint("RIGHT", spellBox, "LEFT", -8, 0)
actionText:SetJustifyH("LEFT")
if actionText.SetWordWrap then actionText:SetWordWrap(false) end

-------------------------------------------------------------------------------
-- State, Sound Throttle & Rendering
-------------------------------------------------------------------------------
local previewUntil = 0
local lastSoundAt = 0
local lastAlertKey = nil
local lastScale = nil
local lastLocked = nil
local pulsePhase = 0

local function PlayDispelCue(force)
    if not IsDispelSoundEnabled() then return end
    local now = (GetTime and SafeCall(GetTime)) or 0
    if not force and (now - lastSoundAt) < 3.0 then return end
    lastSoundAt = now
    local presetKey = GetSettings().dispelAlertSoundPreset or "readycheck"
    local preset = FindPreset(DISPEL_SOUND_PRESETS, presetKey)
    local soundId = (SOUNDKIT and preset.kit and SOUNDKIT[preset.kit]) or preset.fallbackId or 8960
    pcall(PlaySound, soundId, "Master")
end

local function ApplyAlertAnchor()
    local s = GetSettings()
    local presetKey = s.dispelAlertPosPreset
    if not presetKey then
        presetKey = s.dispelAlertPos and "CUSTOM" or "TOPRIGHT"
    end
    alertFrame:ClearAllPoints()
    if presetKey == "CUSTOM" and type(s.dispelAlertPos) == "table" and s.dispelAlertPos.point then
        alertFrame:SetPoint(s.dispelAlertPos.point, UIParent, s.dispelAlertPos.relPoint or s.dispelAlertPos.point, s.dispelAlertPos.x or 0, s.dispelAlertPos.y or 0)
    else
        local p = FindPreset(DISPEL_POS_PRESETS, presetKey ~= "CUSTOM" and presetKey or "TOPRIGHT")
        alertFrame:SetPoint(p.point or "TOPRIGHT", UIParent, p.relPoint or "TOPRIGHT", p.x or -230, p.y or -145)
    end
    alertFrame.posLoaded = true
end

local function BuildPreviewEntry()
    local L = FP.L or {}
    local dispelInfo = FP.GetPlayerDispelInfo and FP:GetPlayerDispelInfo()
    local school = (dispelInfo and next(dispelInfo.schools)) or "Magic"
    local spellInfo = dispelInfo and dispelInfo.spellsBySchool and dispelInfo.spellsBySchool[school]
    local playerName = (UnitName and SafeCall(UnitName, "player")) or "Player"
    if not IsSafeStr(playerName) then playerName = "Player" end

    return {
        unit         = "player",
        unitGUID     = "preview",
        unitName     = playerName,
        isPlayer     = true,
        colorHex     = GetClassColorHex("player"),
        debuffName   = L["DISPEL_TEST_DEBUFF"] or "Polymorph (Test)",
        debuffIcon   = "Interface\\Icons\\Spell_Nature_Polymorph",
        stacks       = 0,
        remaining    = 8.0,
        duration     = 10.0,
        school       = school,
        spellID      = spellInfo and spellInfo.spellID or 4987,
        spellName    = (spellInfo and spellInfo.name) or (L["DISPEL_TEST_SPELL"] or "Dispel"),
        spellIcon    = (spellInfo and spellInfo.icon) or "Interface\\Icons\\Spell_Holy_DispelMagic",
        inRange      = true,
        cdRemaining  = 0,
        cdDuration   = 0,
        isSpellReady = true,
        isPreview    = true,
    }
end

local function ApplyAlertVisual(entry, totalCount)
    local L = FP.L or {}
    local col = DISPEL_COLORS[entry.school] or DISPEL_COLORS.none
    alertFrame:SetBackdropBorderColor(col.r, col.g, col.b, 1.0)
    debuffBox:SetBackdropBorderColor(col.r, col.g, col.b, 1.0)
    if FP.ApplySecretBorderColor then
        FP:ApplySecretBorderColor(alertFrame.secretBorder, entry.secretColorObj)
        FP:ApplySecretBorderColor(debuffBox.secretBorder, entry.secretColorObj)
    end
    local okTex = false
    if IsSecret(entry.rawDebuffIcon) then
        okTex = pcall(debuffIcon.SetTexture, debuffIcon, entry.rawDebuffIcon)
    elseif entry.rawDebuffIcon ~= nil then
        okTex = pcall(debuffIcon.SetTexture, debuffIcon, entry.rawDebuffIcon)
    end
    if not okTex then
        debuffIcon:SetTexture(entry.debuffIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end

    if entry.stacks and entry.stacks > 1 then
        debuffStacks:SetText(tostring(entry.stacks))
        debuffStacks:Show()
    else
        debuffStacks:Hide()
    end

    if entry.remaining and entry.remaining > 0.3 then
        debuffCooldown:Clear()
        if entry.remaining >= 10 then
            debuffTimer:SetText(string.format("%ds", math.ceil(entry.remaining)))
        else
            debuffTimer:SetText(string.format("%.1f", entry.remaining))
        end
        debuffTimer:Show()
    elseif entry.debuffDurationObj and debuffCooldown.SetCooldownFromDurationObject then
        debuffTimer:Hide()
        if debuffCooldown.SetHideCountdownNumbers then
            pcall(debuffCooldown.SetHideCountdownNumbers, debuffCooldown, false)
        end
        local okObj = pcall(debuffCooldown.SetCooldownFromDurationObject, debuffCooldown, entry.debuffDurationObj)
        if not okObj then debuffCooldown:Clear() end
    else
        debuffCooldown:Clear()
        debuffTimer:Hide()
    end

    local schoolLabel = GetLocalizedSchoolLabel(entry.school)
    local suffix = ""
    if not entry.inRange then
        suffix = string.format(" |cffff5555(%s)|r", L["DISPEL_OUT_OF_RANGE"] or "Out of range")
    elseif totalCount and totalCount > 1 then
        suffix = string.format(" |cffaaaaaa(+%d)|r", totalCount - 1)
    end
    titleText:SetText(string.format("|cff%02x%02x%02x%s|r%s", math.floor(col.r * 255), math.floor(col.g * 255), math.floor(col.b * 255), schoolLabel, suffix))

    local targetPrefix = entry.isPlayer and (L["DISPEL_YOU"] or "YOU") or entry.unitName
    local targetArg = entry.isPlayer and targetPrefix or (entry.rawUnitName or targetPrefix)
    local debuffArg = entry.rawDebuffName or entry.debuffName
    local okFmt = (not entry.isPreview) and (entry.rawUnitName ~= nil or entry.rawDebuffName ~= nil)
        and pcall(targetText.SetFormattedText, targetText, "|cff%s%s|r — |cffffffff%s|r", entry.colorHex or "ffffff", targetArg, debuffArg)
    if not okFmt then
        targetText:SetText(string.format("|cff%s%s|r — |cffffffff%s|r", entry.colorHex or "ffffff", targetPrefix, entry.debuffName))
    end

    spellIcon:SetTexture(entry.spellIcon or "Interface\\Icons\\Spell_Holy_DispelMagic")
    local key = FP.GetSpellKeybind and FP:GetSpellKeybind(entry.spellID)
    if key and key ~= "" then
        spellKeybind:SetText(key)
        spellKeybind:Show()
    else
        spellKeybind:Hide()
    end

    if not entry.isSpellReady and entry.cdRemaining > 0 and entry.cdDuration > 0 then
        if spellCooldown.SetHideCountdownNumbers then
            spellCooldown:SetHideCountdownNumbers(true)
        end
        local now = (GetTime and SafeCall(GetTime)) or 0
        local start = (now + entry.cdRemaining) - entry.cdDuration
        if start > 0 then
            spellCooldown:SetCooldown(start, entry.cdDuration)
        else
            spellCooldown:Clear()
        end
        spellIcon:SetVertexColor(0.5, 0.5, 0.5)
        spellBox:SetBackdropBorderColor(0.85, 0.5, 0.2, 0.95)
        actionText:SetText(string.format("|cffffb040%s (%.1fs)|r", entry.spellName, entry.cdRemaining))
    elseif not entry.isSpellReady and entry.cdDurationObj and spellCooldown.SetCooldownFromDurationObject then
        if spellCooldown.SetHideCountdownNumbers then
            pcall(spellCooldown.SetHideCountdownNumbers, spellCooldown, false)
        end
        local okCdObj = pcall(spellCooldown.SetCooldownFromDurationObject, spellCooldown, entry.cdDurationObj)
        if not okCdObj then spellCooldown:Clear() end
        spellIcon:SetVertexColor(0.5, 0.5, 0.5)
        spellBox:SetBackdropBorderColor(0.85, 0.5, 0.2, 0.95)
        actionText:SetText(string.format("|cffffb040%s (CD)|r", entry.spellName))
    else
        spellCooldown:Clear()
        if not entry.inRange then
            spellIcon:SetVertexColor(1.0, 0.45, 0.45)
            spellBox:SetBackdropBorderColor(1.0, 0.3, 0.3, 1.0)
            actionText:SetText(string.format("|cffff7070%s: %s|r", L["DISPEL_MOVE_CLOSER"] or "Move closer", entry.spellName))
        else
            spellIcon:SetVertexColor(1.0, 1.0, 1.0)
            spellBox:SetBackdropBorderColor(col.r, col.g, col.b, 0.95)
            local s = GetSettings()
            local hasGridDispel = (s.showClassColorsAndIcons ~= false and s.useGridPartyFrames ~= false)
            if hasGridDispel then
                actionText:SetText(string.format("|cff90e8ff%s: |cffffffff%s|r |cff88ffcc[Shift+Clic]|r", L["DISPEL_USE_SPELL"] or "Cast", entry.spellName))
            else
                actionText:SetText(string.format("|cff90e8ff%s: |cffffffff%s|r", L["DISPEL_USE_SPELL"] or "Cast", entry.spellName))
            end
        end
    end
end

local function UpdateDispelAlert()
    local L = FP.L or {}
    if not alertFrame.posLoaded then
        ApplyAlertAnchor()
    end

    local locked = IsDispelAlertLocked()
    if locked ~= lastLocked then
        lastLocked = locked
        alertFrame:EnableMouse(not locked)
    end

    local scale = GetDispelAlertScale()
    if scale ~= lastScale then
        lastScale = scale
        alertFrame:SetScale(scale)
    end

    if not IsDispelAlertEnabled() then
        lastAlertKey = nil
        if alertFrame:IsShown() then alertFrame:Hide() end
        return
    end

    local matches = ScanGroupDispellables()
    local top = matches[1]
    local now = (GetTime and SafeCall(GetTime)) or 0
    local inPreview = (not locked) or (previewUntil > now)

    if top then
        local idTag = top.auraInstanceID and tostring(top.auraInstanceID) or tostring(top.debuffName)
        local alertKey = tostring(top.unitGUID) .. "|" .. idTag .. "|" .. tostring(top.school)
        if alertKey ~= lastAlertKey then
            lastAlertKey = alertKey
            PlayDispelCue()
        end
        ApplyAlertVisual(top, #matches)
        if not alertFrame:IsShown() then alertFrame:Show() end
    elseif inPreview then
        lastAlertKey = nil
        ApplyAlertVisual(BuildPreviewEntry(), 1)
        if not alertFrame:IsShown() then alertFrame:Show() end
    else
        lastAlertKey = nil
        if alertFrame:IsShown() then
            alertFrame:SetAlpha(1.0)
            alertFrame:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function FP:RefreshDispelAlert()
    if self.InvalidateDispelCache then self:InvalidateDispelCache() end
    UpdateDispelAlert()
end

function FP:SetDispelAlertLocked(locked)
    local L = FP.L or {}
    local s = GetSettings()
    s.dispelAlertLocked = (locked == true)
    UpdateDispelAlert()
    if s.dispelAlertLocked then
        FP:Print(L["DISPEL_LOCKED_MSG"] or "Dispel Alert position locked.")
    else
        FP:Print(L["DISPEL_UNLOCKED_MSG"] or "Dispel Alert unlocked: drag it anywhere on screen, then lock it again.")
    end
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
end

function FP:SetDispelAlertPosPreset(presetKey)
    local s = GetSettings()
    local chosen = FindPreset(DISPEL_POS_PRESETS, presetKey)
    s.dispelAlertPosPreset = chosen.key
    if chosen.key ~= "CUSTOM" then
        s.dispelAlertPos = nil
    else
        s.dispelAlertLocked = false
    end
    ApplyAlertAnchor()
    local now = (GetTime and SafeCall(GetTime)) or 0
    previewUntil = now + 3.5
    UpdateDispelAlert()
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
end

function FP:SetDispelAlertSoundPreset(presetKey)
    local s = GetSettings()
    local chosen = FindPreset(DISPEL_SOUND_PRESETS, presetKey)
    s.dispelAlertSoundPreset = chosen.key
    s.dispelAlertSound = true
    PlayDispelCue(true)
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
end

function FP:ResetDispelAlertPos()
    local L = FP.L or {}
    local s = GetSettings()
    s.dispelAlertPosPreset = "TOPRIGHT"
    s.dispelAlertPos = nil
    ApplyAlertAnchor()
    UpdateDispelAlert()
    FP:Print(L["DISPEL_POS_RESET_MSG"] or "Dispel Alert position reset.")
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
end

function FP:ToggleDispelAlert()
    local L = FP.L or {}
    local s = GetSettings()
    s.enableDispelAlert = not (s.enableDispelAlert ~= false)
    UpdateDispelAlert()
    if s.enableDispelAlert then
        FP:Print(L["DISPEL_ENABLED_MSG"] or "|cff00ff00Dispel Alert HUD enabled.|r")
    else
        FP:Print(L["DISPEL_DISABLED_MSG"] or "|cffff5555Dispel Alert HUD disabled.|r")
    end
    if self.RefreshSettingsUI then self:RefreshSettingsUI() end
end

function FP:TriggerDispelAlertTest()
    local s = GetSettings()
    s.enableDispelAlert = true
    local now = (GetTime and SafeCall(GetTime)) or 0
    previewUntil = now + 6.0
    lastSoundAt = 0
    PlayDispelCue()
    UpdateDispelAlert()
end

-------------------------------------------------------------------------------
-- Event Watcher & Pulse Loop
-------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
SafeRegisterEvent(ev, "PLAYER_LOGIN")
SafeRegisterEvent(ev, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(ev, "UNIT_AURA")
SafeRegisterEvent(ev, "GROUP_ROSTER_UPDATE")
SafeRegisterEvent(ev, "PARTY_MEMBERS_CHANGED")
SafeRegisterEvent(ev, "RAID_ROSTER_UPDATE")
SafeRegisterEvent(ev, "SPELLS_CHANGED")
SafeRegisterEvent(ev, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(ev, "CHARACTER_POINTS_CHANGED")
SafeRegisterEvent(ev, "PLAYER_SPECIALIZATION_CHANGED")
SafeRegisterEvent(ev, "SPELL_UPDATE_COOLDOWN")
SafeRegisterEvent(ev, "PLAYER_REGEN_ENABLED")
SafeRegisterEvent(ev, "PLAYER_REGEN_DISABLED")

ev:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and type(unit) == "string" then
        if unit ~= "player" and not unit:match("^party%d+$") and not unit:match("^raid%d+$") then
            return
        end
    end
    pcall(UpdateDispelAlert)
end)

local tickerAccum = 0
ev:SetScript("OnUpdate", function(_, elapsed)
    local hasActive = alertFrame:IsShown()
    if hasActive then
        pulsePhase = pulsePhase + (elapsed * 4.5)
        local alpha = 0.80 + 0.20 * math.sin(pulsePhase)
        alertFrame:SetAlpha(alpha)
    end
    tickerAccum = tickerAccum + elapsed
    local interval = hasActive and 0.15 or 0.45
    if tickerAccum >= interval then
        tickerAccum = 0
        pcall(UpdateDispelAlert)
    end
end)
