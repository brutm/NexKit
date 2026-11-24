-- NexusKit - UI/RotationAdvisor.lua
-- Contextual, Spec-Aware Spell Rotation Advisor
-- Recommends the optimal next spell and upcoming sequence based on class, spec,
-- cooldowns, resource levels, and target aura/health state.
local addonName, FP = ...

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local function GetSettings()
    local db = NexKitDB or NexusKitDB
    return (db and db.settings) or {}
end

local function IsRotationEnabled()
    return GetSettings().enableRotationAdvisor ~= false
end

local function IsRotationLocked()
    return GetSettings().rotationLocked ~= false
end

local function GetRotationScale()
    local s = tonumber(GetSettings().rotationScale) or 1.0
    if s < 0.6 then s = 0.6 elseif s > 1.8 then s = 1.8 end
    return s
end

local function GetRotationAlpha()
    local a = tonumber(GetSettings().rotationAlpha) or 1.0
    if a < 0.2 then a = 0.2 elseif a > 1.0 then a = 1.0 end
    return a
end

local function GetRotationMode()
    return GetSettings().rotationMode or "always"
end

local function IsQueueVisible()
    return GetSettings().rotationShowQueue == true
end

-------------------------------------------------------------------------------
-- Safe WoW API & Secret Value Compatibility Guards
-------------------------------------------------------------------------------
local function IsSecret(v)
    return (issecretvalue and issecretvalue(v)) or (issecret and issecret(v)) or false
end

local function IsAccessible(v)
    if v == nil then return false end
    if IsSecret(v) then return false end
    return true
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = { pcall(fn, ...) }
    if not results[1] then return nil end
    for i = 2, #results do
        if IsSecret(results[i]) then
            results[i] = nil
        end
    end
    return unpack(results, 2)
end

local function SafeBoolean(val, fallback)
    if val == nil or IsSecret(val) then return fallback end
    local ok, res = pcall(function()
        if val then return true else return false end
    end)
    if ok then return res end
    return fallback
end

local function SafeRegisterEvent(f, eventName)
    pcall(f.RegisterEvent, f, eventName)
end

local function GetSpellNameCompat(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local name = SafeCall(C_Spell.GetSpellName, spellID)
        if IsAccessible(name) and name ~= "" then return name end
    end
    if GetSpellInfo then
        local name = SafeCall(GetSpellInfo, spellID)
        if IsAccessible(name) and name ~= "" then return name end
    end
    return nil
end

local function GetSpellTextureCompat(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = SafeCall(C_Spell.GetSpellTexture, spellID)
        if IsAccessible(tex) and tex then return tex end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = SafeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and IsAccessible(info.iconID) and info.iconID then
            return info.iconID
        end
    end
    if GetSpellTexture then
        local tex = SafeCall(GetSpellTexture, spellID)
        if IsAccessible(tex) and tex then return tex end
    end
    if GetSpellInfo then
        local _, _, tex = SafeCall(GetSpellInfo, spellID)
        if IsAccessible(tex) and tex then return tex end
    end
    return nil
end

local function IsSpellKnownCompat(spellID)
    if not spellID then return false end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local known = SafeCall(C_SpellBook.IsSpellKnown, spellID)
        if IsAccessible(known) and known then return true end
    end
    if IsPlayerSpell then
        local known = SafeCall(IsPlayerSpell, spellID)
        if IsAccessible(known) and known then return true end
    end
    if IsSpellKnown then
        local known = SafeCall(IsSpellKnown, spellID)
        if IsAccessible(known) and known then return true end
    end
    return false
end

local spellbookByName = {}
local resolvedSpellCache = {}
local spellbookLoaded = false

local function InvalidateRotationCaches()
    spellbookLoaded = false
    for k in pairs(resolvedSpellCache) do
        resolvedSpellCache[k] = nil
    end
end

local function RebuildSpellbookCache()
    for k in pairs(spellbookByName) do
        spellbookByName[k] = nil
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        local spellType = (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell) or 1
        local numLines = SafeCall(C_SpellBook.GetNumSpellBookSkillLines) or 0
        for l = 1, numLines do
            local lineInfo = SafeCall(C_SpellBook.GetSpellBookSkillLineInfo, l)
            if type(lineInfo) == "table" and not lineInfo.shouldHide and (not lineInfo.offSpecID or lineInfo.offSpecID == 0) then
                local offset = lineInfo.itemIndexOffset or 0
                local numSlots = lineInfo.numSpellBookItems or 0
                for s = offset + 1, offset + numSlots do
                    local itemInfo = SafeCall(C_SpellBook.GetSpellBookItemInfo, s, bank)
                    if type(itemInfo) == "table"
                        and (itemInfo.itemType == spellType or itemInfo.itemType == "SPELL")
                        and not itemInfo.isPassive
                        and not itemInfo.isOffSpec
                        and IsAccessible(itemInfo.spellID)
                        and IsAccessible(itemInfo.name)
                    then
                        spellbookByName[string.lower(itemInfo.name)] = itemInfo.spellID
                    end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local bookType = BOOKTYPE_SPELL or "spell"
        local numTabs = SafeCall(GetNumSpellTabs) or 0
        for t = 1, numTabs do
            local _, _, offset, numSlots, _, offSpecID = SafeCall(GetSpellTabInfo, t)
            if (not offSpecID or offSpecID == 0) and offset and numSlots then
                for s = offset + 1, offset + numSlots do
                    local sName = SafeCall(GetSpellBookItemName, s, bookType)
                    local sType, sid = nil, nil
                    if GetSpellBookItemInfo then
                        sType, sid = SafeCall(GetSpellBookItemInfo, s, bookType)
                    end
                    if IsAccessible(sName) and sName ~= "" and (sType == "SPELL" or sType == nil) then
                        local key = string.lower(sName)
                        if sid and IsAccessible(sid) then
                            spellbookByName[key] = sid
                        elseif not spellbookByName[key] then
                            spellbookByName[key] = true
                        end
                    end
                end
            end
        end
    end
    spellbookLoaded = true
end

local function GetSpellCooldownCompat(spellID)
    if not spellID then return 0, 0, true end
    if FP.GetSpellCooldown then
        return FP.GetSpellCooldown(spellID)
    end
    return 0, 0, true
end

local function IsSpellUsableCompat(spellID)
    if not spellID then return false, false end
    if C_Spell and C_Spell.IsSpellUsable then
        local usable, noMana = SafeCall(C_Spell.IsSpellUsable, spellID)
        if IsAccessible(usable) then
            return (usable == true), (IsAccessible(noMana) and noMana == true)
        end
    elseif IsUsableSpell then
        local usable, noMana = SafeCall(IsUsableSpell, spellID)
        if IsAccessible(usable) then
            return (usable == true), (IsAccessible(noMana) and noMana == true)
        end
    end
    return true, false
end

local function IsSpellInRangeCompat(spellID, unit)
    unit = unit or "target"
    if not spellID or not SafeBoolean(UnitExists(unit), false) then return nil end
    if C_Spell and C_Spell.IsSpellInRange then
        local inRange = SafeCall(C_Spell.IsSpellInRange, spellID, unit)
        if IsAccessible(inRange) then return inRange end
    elseif IsSpellInRange then
        local inRange = SafeCall(IsSpellInRange, spellID, unit)
        if IsAccessible(inRange) then return inRange end
    end
    return nil
end

local function MatchesAuraTarget(name, spellId, expTime, caster, spellNames, ownOnly, minRemaining)
    if caster and ownOnly and caster ~= "player" then
        return false
    end
    if minRemaining and minRemaining > 0 and type(expTime) == "number" and expTime > 0 then
        local now = (GetTime and SafeCall(GetTime)) or 0
        if type(now) == "number" and (expTime - now) <= minRemaining then
            return false
        end
    end
    local lowName = type(name) == "string" and string.lower(name) or nil
    for _, targetName in ipairs(spellNames) do
        if type(targetName) == "number" and spellId == targetName then
            return true
        elseif lowName and type(targetName) == "string" then
            local lowTarget = string.lower(targetName)
            if lowName == lowTarget or lowName:find(lowTarget, 1, true) then
                return true
            end
        end
    end
    return false
end

local function UnitHasAuraNamed(unit, spellNames, ownOnly, minRemaining)
    if not unit or not SafeBoolean(UnitExists(unit), false) or not spellNames then return false end
    if type(spellNames) == "string" then spellNames = { spellNames } end

    for i = 1, 40 do
        local name, spellId, expTime, caster = nil, nil, nil, nil
        if UnitBuff then
            local ok, bName, _, _, _, _, bExp, bCaster, _, _, bSid = pcall(UnitBuff, unit, i)
            if ok and IsAccessible(bName) then name = bName end
            if ok and IsAccessible(bExp) then expTime = bExp end
            if ok and IsAccessible(bCaster) then caster = bCaster end
            if ok and IsAccessible(bSid) then spellId = bSid end
        end
        if not name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not ok then break end
            if type(a) == "table" then
                local okF = pcall(function()
                    if IsAccessible(a.name) then name = a.name end
                    if IsAccessible(a.expirationTime) then expTime = a.expirationTime end
                    if IsAccessible(a.sourceUnit) then caster = a.sourceUnit end
                    if IsAccessible(a.spellId) then spellId = a.spellId end
                end)
                if not okF then break end
            end
        end
        if name or spellId then
            if MatchesAuraTarget(name, spellId, expTime, caster, spellNames, ownOnly, minRemaining) then
                return true
            end
        elseif i > 8 then
            break
        end
    end
    return false
end

local function UnitHasDebuffNamed(unit, spellNames, ownOnly, minRemaining)
    if not unit or not SafeBoolean(UnitExists(unit), false) or not spellNames then return false end
    if type(spellNames) == "string" then spellNames = { spellNames } end

    for i = 1, 40 do
        local name, spellId, expTime, caster = nil, nil, nil, nil
        if UnitDebuff then
            local ok, dName, _, _, _, _, dExp, dCaster, _, _, dSid = pcall(UnitDebuff, unit, i)
            if ok and IsAccessible(dName) then name = dName end
            if ok and IsAccessible(dExp) then expTime = dExp end
            if ok and IsAccessible(dCaster) then caster = dCaster end
            if ok and IsAccessible(dSid) then spellId = dSid end
        end
        if not name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not ok then break end
            if type(a) == "table" then
                local okF = pcall(function()
                    if IsAccessible(a.name) then name = a.name end
                    if IsAccessible(a.expirationTime) then expTime = a.expirationTime end
                    if IsAccessible(a.sourceUnit) then caster = a.sourceUnit end
                    if IsAccessible(a.spellId) then spellId = a.spellId end
                end)
                if not okF then break end
            end
        end
        if name or spellId then
            if MatchesAuraTarget(name, spellId, expTime, caster, spellNames, ownOnly, minRemaining) then
                return true
            end
        elseif i > 8 then
            break
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Action Bar Keybind Finder Helper (delegates to shared FP:GetSpellKeybind)
-------------------------------------------------------------------------------
local function InvalidateKeybindCache()
    if FP.InvalidateSpellKeybindCache then
        FP:InvalidateSpellKeybindCache()
    end
end

local function GetKeybindForSpell(spellID)
    if FP.GetSpellKeybind then
        return FP:GetSpellKeybind(spellID)
    end
    return nil
end

-------------------------------------------------------------------------------
-- Rotation Engine: Spec & Context Detectors
-------------------------------------------------------------------------------
local function GetPlayerCombatContext()
    local specInfo = FP.GetPlayerSpecInfo and FP:GetPlayerSpecInfo() or nil
    local classTag = (specInfo and specInfo.classTag) or select(2, SafeCall(UnitClass, "player")) or "WARRIOR"
    local rawLvl = SafeCall(UnitLevel, "player")
    local level = (IsAccessible(rawLvl) and type(rawLvl) == "number" and rawLvl) or 1
    local tabIdx = (specInfo and specInfo.tabIdx) or 1
    local tabPts = (specInfo and specInfo.tabPts) or 0
    local isShieldEquipped = (specInfo and specInfo.isShieldEquipped) or false

    if not specInfo and type(GetNumTalentTabs) == "function" and type(GetTalentTabInfo) == "function" then
        local rawNumTabs = SafeCall(GetNumTalentTabs)
        local numTabs = (IsAccessible(rawNumTabs) and tonumber(rawNumTabs)) or 0
        for t = 1, numTabs do
            local _, pointsSpent = FP.ReadTalentTabCompat and FP.ReadTalentTabCompat(t)
            if IsAccessible(pointsSpent) and type(pointsSpent) == "number" and pointsSpent > tabPts then
                tabPts = pointsSpent
                tabIdx = t
            end
        end
    end

    local inCombat = SafeBoolean(InCombatLockdown and InCombatLockdown(), false)
    local hasTarget = SafeBoolean(UnitExists and SafeCall(UnitExists, "target"), false)
    local targetHostile = hasTarget and SafeBoolean(UnitCanAttack and SafeCall(UnitCanAttack, "player", "target"), false)
    local targetDead = hasTarget and (SafeBoolean(UnitIsDead and SafeCall(UnitIsDead, "target"), false) or SafeBoolean(UnitIsGhost and SafeCall(UnitIsGhost, "target"), false))

    local targetHp = 100
    if hasTarget and not targetDead and UnitHealth and UnitHealthMax then
        local hp = SafeCall(UnitHealth, "target") or 1
        local maxHp = SafeCall(UnitHealthMax, "target") or 1
        if IsAccessible(hp) and IsAccessible(maxHp) and maxHp > 0 then
            targetHp = math.floor((hp / maxHp) * 100)
        end
    end

    local rawPt = UnitPowerType and SafeCall(UnitPowerType, "player")
    local powerType = (IsAccessible(rawPt) and type(rawPt) == "number" and rawPt) or 0
    local rawPower = SafeCall(UnitPower, "player") or 0
    local power = (IsAccessible(rawPower) and type(rawPower) == "number" and rawPower) or 0
    local rawMaxPower = (UnitPowerMax and SafeCall(UnitPowerMax, "player")) or 1
    local maxPower = (IsAccessible(rawMaxPower) and type(rawMaxPower) == "number" and rawMaxPower > 0 and rawMaxPower) or 1
    local powerPct = math.max(0, math.min(1, power / maxPower))

    local rawSelfHp = UnitHealth and SafeCall(UnitHealth, "player") or 1
    local rawSelfMaxHp = UnitHealthMax and SafeCall(UnitHealthMax, "player") or 1
    local selfHpPct = (IsAccessible(rawSelfHp) and IsAccessible(rawSelfMaxHp) and type(rawSelfMaxHp) == "number" and rawSelfMaxHp > 0)
        and (rawSelfHp / rawSelfMaxHp) or 1.0

    local mainSpeed = (UnitAttackSpeed and SafeCall(UnitAttackSpeed, "player"))
    if not IsAccessible(mainSpeed) or type(mainSpeed) ~= "number" or mainSpeed <= 0 then
        mainSpeed = 2.5
    end

    local isStealthed = (IsStealthed and SafeBoolean(SafeCall(IsStealthed), false)) or false

    local comboPoints = (GetComboPoints and SafeCall(GetComboPoints, "player", "target"))
        or (UnitPower and SafeCall(UnitPower, "player", (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4))
        or 0
    if not IsAccessible(comboPoints) or type(comboPoints) ~= "number" then
        comboPoints = 0
    end

    return {
        classTag         = classTag,
        level            = level,
        tabIdx           = tabIdx,
        tabPts           = tabPts,
        tabs             = specInfo and specInfo.tabs or nil,
        specID           = specInfo and specInfo.specID or nil,
        role             = specInfo and specInfo.role or "DAMAGER",
        isShieldEquipped = isShieldEquipped,
        inCombat         = inCombat,
        hasTarget        = hasTarget,
        targetHostile    = targetHostile,
        targetDead       = targetDead,
        targetHp         = targetHp,
        selfHpPct        = selfHpPct,
        powerType        = powerType,
        power            = power,
        powerPct         = powerPct,
        mainSpeed        = mainSpeed,
        isStealthed      = isStealthed,
        comboPoints      = comboPoints,
    }
end

-------------------------------------------------------------------------------
-- Class Rotation Rules
-------------------------------------------------------------------------------
local function FindBestSpellInRanks(rankList, aliases)
    if not spellbookLoaded then
        RebuildSpellbookCache()
    end
    if type(rankList) ~= "table" or #rankList == 0 then return nil end

    local cacheKey = rankList[1]
    if cacheKey and resolvedSpellCache[cacheKey] ~= nil then
        return (resolvedSpellCache[cacheKey] ~= false) and resolvedSpellCache[cacheKey] or nil
    end

    -- 1. Try direct active (non-passive) rank spell IDs
    for i = #rankList, 1, -1 do
        local sid = rankList[i]
        if IsSpellKnownCompat(sid) and not (FP.IsSpellPassive and FP.IsSpellPassive(sid)) then
            if cacheKey then resolvedSpellCache[cacheKey] = sid end
            return sid
        end
    end

    -- 2. Try spellbook cache by name (for WoW Forever and client discrepancies)
    for i = #rankList, 1, -1 do
        local baseName = GetSpellNameCompat(rankList[i])
        if baseName then
            local found = spellbookByName[string.lower(baseName)]
            if found then
                local castID = (type(found) == "number") and found or rankList[i]
                if cacheKey then resolvedSpellCache[cacheKey] = castID end
                return castID
            end
        end
    end

    -- 3. Try explicit aliases
    if type(aliases) == "table" then
        for _, alias in ipairs(aliases) do
            local found = spellbookByName[string.lower(alias)]
            if found then
                local castID = (type(found) == "number") and found or rankList[1]
                if cacheKey then resolvedSpellCache[cacheKey] = castID end
                return castID
            end
        end
    end

    if cacheKey then resolvedSpellCache[cacheKey] = false end
    return nil
end

-------------------------------------------------------------------------------
-- Real-time Cast & Sequence Tracking
-------------------------------------------------------------------------------
local lastCastSpellID = nil
local lastCastTime = 0
local lastCastName = nil
local lastSentSpellID = nil
local lastSentTime = 0
local activeSealGraceUntil = 0
local combatTrackedSealUntil = 0
local lastConfirmedSealUntil = 0
local sealConsumedByJudgement = nil
local pendingJudgementVerifyAt = 0

local PALADIN_SEAL_SPELLS = {
    [20154] = true, [21082] = true, [21084] = true, [20287] = true, [20288] = true, [20289] = true, [20290] = true,
    [20291] = true, [20292] = true, [20293] = true, [27155] = true, -- Seal of Righteousness
    [20375] = true, [20915] = true, [20918] = true, [20919] = true, [20920] = true, [27170] = true, -- Seal of Command
    [20165] = true, [20356] = true, [20357] = true, [27166] = true, -- Seal of Wisdom
    [20305] = true, [20306] = true, [20307] = true, [20308] = true, [20162] = true, [20309] = true, [27158] = true, -- Seal of the Crusader
    [20166] = true, [20332] = true, [20333] = true, [20334] = true, [27160] = true, -- Seal of Light
    [20164] = true, [10324] = true, [10325] = true, [10326] = true, -- Seal of Justice
    [31801] = true, [53736] = true, [348704] = true, -- Seal of Vengeance / Truth
    [31892] = true, [53720] = true, -- Seal of Blood / Corruption
}

local function IsPaladinSealSpellOrBuff(name, sid, extraIDs, extraNames, icon, extraIcons)
    if sid and (PALADIN_SEAL_SPELLS[sid] or (extraIDs and extraIDs[sid])) then
        return true
    end
    if icon and extraIcons and extraIcons[icon] then
        return true
    end
    if type(icon) == "string" then
        local lowIcon = string.lower(icon)
        if lowIcon:find("ability_thunderbolt", 1, true) or lowIcon:find("righteousnessaura", 1, true) then
            return true
        end
    end
    if type(name) == "string" and name ~= "" then
        local low = string.lower(name)
        if extraNames and extraNames[low] then
            return true
        end
        if low:find("seal of", 1, true)
            or low:find("sigillo", 1, true)
            or low:find("siegel ", 1, true)
            or low:find("sello ", 1, true)
            or low:find("sceau ", 1, true)
            or low:find("печать ", 1, true)
        then
            if not low:find("blessing", 1, true) and not low:find("benedizione", 1, true) and not low:find("fury", 1, true) and not low:find("furia", 1, true) then
                return true
            end
        end
    end
    return false
end

local function IsJudgementSpell(name, sid)
    if sid == 20271 or sid == 53408 or sid == 53407 or sid == 20473 then
        if sid == 20473 then return false end
        return true
    end
    if type(name) == "string" and name ~= "" then
        local low = string.lower(name)
        if low:find("judgement", 1, true) or low:find("judgment", 1, true)
            or low:find("giudizio", 1, true) or low:find("richturteil", 1, true)
            or low:find("sentencia", 1, true) or low:find("jugement", 1, true)
        then
            return true
        end
    end
    return false
end

local lastSealDebug = {}

local function IsPaladinSealActive(knownSeals)
    local now = (GetTime and SafeCall(GetTime)) or 0
    if type(now) ~= "number" then now = 0 end

    local extraIDs, extraNames, extraIcons = {}, {}, {}
    if type(knownSeals) == "table" then
        for _, sid in ipairs(knownSeals) do
            if type(sid) == "number" then
                extraIDs[sid] = true
                local sName = GetSpellNameCompat(sid)
                if sName and sName ~= "" then
                    extraNames[string.lower(sName)] = true
                end
                local sTex = GetSpellTextureCompat(sid)
                if sTex and sTex ~= "" and sTex ~= 135962 then
                    extraIcons[sTex] = true
                end
            end
        end
    end

    local matchedLive = false
    local matchedExp = 0
    local totalSlots = 0
    local readableSlots = 0
    local hadAuraError = false

    -- 1. Try direct C_UnitAuras.GetPlayerAuraBySpellID first (works cleanly on modern 1.60.1)
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local checkSet = {}
        for sid in pairs(extraIDs) do checkSet[sid] = true end
        for sid in pairs(PALADIN_SEAL_SPELLS) do checkSet[sid] = true end
        for sid in pairs(checkSet) do
            local sec = C_Secrets and C_Secrets.ShouldSpellAuraBeSecret and SafeCall(C_Secrets.ShouldSpellAuraBeSecret, sid)
            if not sec then
                local aura = SafeCall(C_UnitAuras.GetPlayerAuraBySpellID, sid)
                if type(aura) == "table" then
                    matchedLive = true
                    local okExp, expT = pcall(function()
                        return IsAccessible(aura.expirationTime) and tonumber(aura.expirationTime) or 0
                    end)
                    if okExp and type(expT) == "number" and expT > 0 then
                        matchedExp = expT
                    end
                    break
                end
            end
        end
    end

    -- 2. Scan player buff list via C_UnitAuras.GetAuraDataByIndex (preferred) or UnitBuff fallback
    if not matchedLive then
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            for i = 1, 40 do
                local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
                if not ok then
                    hadAuraError = true
                    break
                end
                if not aura then break end
                totalSlots = totalSlots + 1
                if type(aura) == "table" then
                    local okRead, aName, aSid, aIcon, aExp = pcall(function()
                        local n = IsAccessible(aura.name) and aura.name or nil
                        local s = IsAccessible(aura.spellId) and aura.spellId or nil
                        local ic = IsAccessible(aura.icon) and aura.icon or nil
                        local ex = IsAccessible(aura.expirationTime) and tonumber(aura.expirationTime) or 0
                        return n, s, ic, ex
                    end)
                    if not okRead then
                        hadAuraError = true
                        break
                    end
                    if aName or aSid or aIcon then
                        readableSlots = readableSlots + 1
                        if IsPaladinSealSpellOrBuff(aName, aSid, extraIDs, extraNames, aIcon, extraIcons) then
                            matchedLive = true
                            matchedExp = (type(aExp) == "number" and aExp > 0) and aExp or 0
                            break
                        end
                    end
                end
            end
        elseif UnitBuff then
            for i = 1, 40 do
                local ok, bName, _, bIcon, _, _, bExp, _, _, _, bSid = pcall(UnitBuff, "player", i)
                if not ok then
                    hadAuraError = true
                    break
                end
                if bName == nil and bSid == nil and bIcon == nil then
                    break
                end
                totalSlots = totalSlots + 1
                local n = IsAccessible(bName) and bName or nil
                local s = IsAccessible(bSid) and bSid or nil
                local ic = IsAccessible(bIcon) and bIcon or nil
                local ex = (IsAccessible(bExp) and tonumber(bExp)) or 0
                if n or s or ic then
                    readableSlots = readableSlots + 1
                    if IsPaladinSealSpellOrBuff(n, s, extraIDs, extraNames, ic, extraIcons) then
                        matchedLive = true
                        matchedExp = (ex > 0) and ex or 0
                        break
                    end
                end
            end
        end
    end

    local globalSecret = (C_Secrets and C_Secrets.ShouldAurasBeSecret and SafeCall(C_Secrets.ShouldAurasBeSecret)) == true
    local aurasRestricted = (globalSecret == true) or hadAuraError or (totalSlots > 0 and readableSlots == 0)

    lastSealDebug.aurasRestricted = aurasRestricted
    lastSealDebug.totalSlots = totalSlots
    lastSealDebug.readableSlots = readableSlots
    lastSealDebug.matchedLive = matchedLive

    if matchedLive then
        lastConfirmedSealUntil = (matchedExp > now) and matchedExp or (now + 30.0)
        combatTrackedSealUntil = math.max(combatTrackedSealUntil, lastConfirmedSealUntil)
        if pendingJudgementVerifyAt > 0 and now >= pendingJudgementVerifyAt then
            sealConsumedByJudgement = false
            pendingJudgementVerifyAt = 0
        end
        return true
    end

    if aurasRestricted then
        return (combatTrackedSealUntil > now) or (lastConfirmedSealUntil > now) or (activeSealGraceUntil > now)
    end

    -- Auras are readable and no Seal buff was found:
    if pendingJudgementVerifyAt > 0 and now >= pendingJudgementVerifyAt then
        sealConsumedByJudgement = true
        pendingJudgementVerifyAt = 0
    end
    return (activeSealGraceUntil > now)
end

local function BuildRotation(ctx)
    local list = {}
    local cls = ctx.classTag

    local function AddCandidate(spellID, badge, reason, opts)
        if not spellID then return end
        opts = opts or {}
        local remaining, dur, isReady = GetSpellCooldownCompat(spellID)
        local usable, noMana = IsSpellUsableCompat(spellID)
        if opts.requireUsable and (not usable or noMana) then
            return
        end
        local inRange = opts.noRangeCheck and 1 or IsSpellInRangeCompat(spellID, "target")
        local keybind = GetKeybindForSpell(spellID)
        local name = GetSpellNameCompat(spellID) or "Spell"
        local icon = GetSpellTextureCompat(spellID) or "Interface\\Icons\\INV_Misc_QuestionMark"

        -- Brief 0.45s post-cast bridge while cooldown/aura updates settle cleanly
        local now = (GetTime and SafeCall(GetTime)) or 0
        local wasJustCast = false
        if isReady and type(now) == "number" and (now - lastCastTime) < 0.45 then
            if lastCastSpellID and lastCastSpellID == spellID then
                wasJustCast = true
            elseif lastCastName and name and (string.lower(lastCastName) == string.lower(name)) then
                wasJustCast = true
            end
        end

        local effReady = isReady and not wasJustCast
        local effRem = wasJustCast and math.max(remaining, math.max(0.2, 0.45 - (now - lastCastTime))) or remaining
        local effDur = wasJustCast and math.max(dur or 0, 1.5) or (dur or 0)

        list[#list + 1] = {
            spellID     = spellID,
            name        = name,
            icon        = icon,
            isReady     = effReady,
            remaining   = effRem,
            duration    = effDur,
            usable      = usable,
            noMana      = noMana,
            inRange     = inRange,
            keybind     = keybind,
            badge       = badge or "NEXT",
            reason      = reason or "",
            wasJustCast = wasJustCast,
            order       = #list + 1,
        }
    end

    local canAttack = ctx.hasTarget and ctx.targetHostile and not ctx.targetDead

    ---------------------------------------------------------------------------
    -- 1. PALADIN ROTATION (Protection, Retribution, Retri/Prot Hybrid, Holy)
    ---------------------------------------------------------------------------
    if cls == "PALADIN" then
        local isProt = (ctx.role == "TANK") or (ctx.tabIdx == 2) or (ctx.isShieldEquipped == true)
        local isRet  = (ctx.tabIdx == 3) and not isProt
        local isHoly = (ctx.tabIdx == 1) and not isProt

        local sealRighteous = FindBestSpellInRanks({ 20154, 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293, 27155 }, { "Seal of Righteousness", "Sigillo dell'Integrità", "Sigillo della Rettitudine", "Sigillo di Rettitudine" })
        local sealCommand   = FindBestSpellInRanks({ 20375, 20915, 20918, 20919, 20920, 27170 }, { "Seal of Command", "Sigillo del Comando" })
        local sealVengeance = FindBestSpellInRanks({ 31801, 53736, 348704 }, { "Seal of Vengeance", "Seal of Truth", "Seal of Corruption", "Seal of Blood" })
        local sealWisdom    = FindBestSpellInRanks({ 20165, 20356, 20357, 27166 }, { "Seal of Wisdom", "Sigillo della Saggezza" })
        local sealCrusader  = FindBestSpellInRanks({ 20305, 20306, 20307, 20308, 20162, 20309, 27158 }, { "Seal of the Crusader", "Sigillo del Crociato" })

        local activeSeal = IsPaladinSealActive({ sealRighteous, sealCommand, sealVengeance, sealWisdom, sealCrusader })

        local holyShield       = FindBestSpellInRanks({ 20925, 20927, 20928, 27179, 48952 }, { "Holy Shield", "Scudo Sacro" })
        local shieldRighteous  = FindBestSpellInRanks({ 53600, 61411 }, { "Shield of Righteousness", "Shield of the Righteous", "Scudo del Giusto" })
        local hammerRighteous  = FindBestSpellInRanks({ 53595 }, { "Hammer of the Righteous", "Martello del Giusto" })
        local avengersShield   = FindBestSpellInRanks({ 31935, 31589, 32699, 32700, 48827 }, { "Avenger's Shield", "Scudo del Vendicatore" })
        local crusaderStrike   = FindBestSpellInRanks({ 35395 }, { "Crusader Strike", "Assalto del Crociato" })
        local divineStorm      = FindBestSpellInRanks({ 53385 }, { "Divine Storm", "Tempesta Divina" })
        local judgement        = FindBestSpellInRanks({ 20271, 53408, 53407 }, { "Judgement", "Judgement of Light", "Judgement of Wisdom", "Giudizio", "Giudizio della Luce", "Giudizio della Saggezza" })
        local consecrate       = FindBestSpellInRanks({ 26573, 20116, 20922, 20923, 20924, 27173, 48819 }, { "Consecration", "Consacrazione" })
        local hammerOfWrath    = FindBestSpellInRanks({ 24275, 24274, 24239, 27180, 48806 }, { "Hammer of Wrath", "Martello dell'Ira" })
        local exorcism         = FindBestSpellInRanks({ 879, 5614, 5615, 10312, 10313, 10314, 27138, 48801 }, { "Exorcism", "Esorcismo" })
        local hammerOfJustice  = FindBestSpellInRanks({ 853, 5588, 5589, 10308 }, { "Hammer of Justice", "Martello della Giustizia" })

        -- Seal preference: Prot / Shield / Fast weapon -> Seal of Righteousness; Slow 2H Ret -> Command or Righteousness; Holy low mana -> Wisdom
        local preferredSeal = nil
        if isHoly then
            preferredSeal = (ctx.powerPct < 0.65 and sealWisdom) or sealRighteous or sealWisdom
        elseif isProt then
            preferredSeal = sealRighteous or sealVengeance or sealWisdom
        elseif isRet then
            if sealCommand and ctx.mainSpeed >= 2.9 then
                preferredSeal = sealCommand
            else
                preferredSeal = sealRighteous or sealCommand or sealVengeance
            end
        else
            preferredSeal = sealRighteous or sealCommand or sealCrusader
        end

        if preferredSeal and not activeSeal then
            AddCandidate(preferredSeal, "SIGILLO", "Attiva il Sigillo per il combattimento", { noRangeCheck = true })
        end

        local hasArtOfWar = UnitHasAuraNamed("player", { "The Art of War", "L'Arte della Guerra" })
        local cType = canAttack and UnitCreatureType and SafeCall(UnitCreatureType, "target") or nil
        local isDemonOrUndead = IsAccessible(cType) and (cType == "Undead" or cType == "Non Morto" or cType == "Demon" or cType == "Demone")

        if isProt then
            if holyShield and ctx.isShieldEquipped and not UnitHasAuraNamed("player", { "Holy Shield", "Scudo Sacro", 20925, 20927, 20928, 27179, 48952 }) then
                AddCandidate(holyShield, "DIFESA", "Holy Shield: Parata & minaccia sacra", { noRangeCheck = true })
            end
            if avengersShield and canAttack then
                AddCandidate(avengersShield, "PULL/BURST", "Scudo del Vendicatore: Danno sacro a rimbalzo")
            end
            if hammerOfWrath and canAttack and ctx.targetHp <= 20 then
                AddCandidate(hammerOfWrath, "ESECUZIONE", "Hammer of Wrath: Bersaglio < 20% salute")
            end
            if shieldRighteous and canAttack and ctx.isShieldEquipped then
                AddCandidate(shieldRighteous, "MINACCIA", "Shield of Righteousness: Danno/Minaccia con scudo")
            end
            if hammerRighteous and canAttack then
                AddCandidate(hammerRighteous, "AOE", "Hammer of the Righteous: Colpo multiplo tank")
            end
            if judgement and canAttack then
                local jUsable = IsSpellUsableCompat(judgement)
                if activeSeal or jUsable then
                    AddCandidate(judgement, "GIUDIZIO", "Judgement: Scarica il sigillo sul bersaglio")
                end
            end
            if crusaderStrike and canAttack then
                AddCandidate(crusaderStrike, "STRIKE", "Crusader Strike: Colpo fisico/sacro")
            end
            if consecrate and (ctx.inCombat or canAttack) then
                AddCandidate(consecrate, "AOE", "Consacrazione: Minaccia ad area sul terreno", { noRangeCheck = true })
            end
            if exorcism and canAttack and (isDemonOrUndead or hasArtOfWar) then
                AddCandidate(exorcism, "BURST", "Esorcismo: Danno sacro istantaneo")
            end
            if hammerOfJustice and canAttack then
                AddCandidate(hammerOfJustice, "STUN", "Martello della Giustizia")
            end
        elseif isRet then
            if hammerOfWrath and canAttack and ctx.targetHp <= 20 then
                AddCandidate(hammerOfWrath, "ESECUZIONE", "Hammer of Wrath: Esecuzione < 20%")
            end
            if crusaderStrike and canAttack then
                AddCandidate(crusaderStrike, "STRIKE", "Crusader Strike su ricarica")
            end
            if judgement and canAttack then
                local jUsable = IsSpellUsableCompat(judgement)
                if activeSeal or jUsable then
                    AddCandidate(judgement, "GIUDIZIO", "Judgement sul bersaglio")
                end
            end
            if divineStorm and canAttack then
                AddCandidate(divineStorm, "AOE", "Divine Storm: Danno sacro ad area")
            end
            if exorcism and canAttack and (isDemonOrUndead or hasArtOfWar) then
                AddCandidate(exorcism, "PROC", "Esorcismo")
            end
            if consecrate and (ctx.inCombat or canAttack) then
                AddCandidate(consecrate, "AOE", "Consacrazione", { noRangeCheck = true })
            end
            if hammerOfJustice and canAttack then
                AddCandidate(hammerOfJustice, "STUN", "Martello della Giustizia")
            end
        else
            local holyShock = FindBestSpellInRanks({ 20473, 20929, 20930, 27174, 48825 }, { "Holy Shock", "Folgore Sacra" })
            if holyShock and canAttack then AddCandidate(holyShock, "SHOCK", "Holy Shock istantaneo") end
            if judgement and canAttack and (activeSeal or IsSpellUsableCompat(judgement)) then
                AddCandidate(judgement, "GIUDIZIO", "Giudizio")
            end
            if consecrate and canAttack then AddCandidate(consecrate, "AOE", "Consacrazione", { noRangeCheck = true }) end
            if exorcism and canAttack and isDemonOrUndead then AddCandidate(exorcism, "BURST", "Esorcismo") end
        end

    ---------------------------------------------------------------------------
    -- 2. WARRIOR ROTATION (Arms, Fury, Protection)
    ---------------------------------------------------------------------------
    elseif cls == "WARRIOR" then
        local isProt = (ctx.role == "TANK") or (ctx.tabIdx == 3) or ctx.isShieldEquipped
        local isFury = (ctx.tabIdx == 2) and not isProt

        local battleShout  = FindBestSpellInRanks({ 6673, 5242, 6192, 11549, 11550, 11551, 25289, 2048, 47436 }, { "Battle Shout", "Urlo di Battaglia" })
        local execute      = FindBestSpellInRanks({ 5308, 20658, 20660, 20661, 20662, 25236, 47471 }, { "Execute", "Esecuzione" })
        local shieldSlam   = FindBestSpellInRanks({ 23922, 23923, 23924, 23925, 25258, 47488 }, { "Shield Slam", "Colpo di Scudo" })
        local revenge      = FindBestSpellInRanks({ 6572, 6574, 7379, 11600, 11601, 25288, 57823 }, { "Revenge", "Rivincita" })
        local devastate    = FindBestSpellInRanks({ 20243, 30016, 30022, 47498 }, { "Devastate", "Devastazione" })
        local shockwave    = FindBestSpellInRanks({ 46968 }, { "Shockwave", "Onda d'Urto" })
        local thunderClap  = FindBestSpellInRanks({ 6343, 8198, 8204, 8205, 11580, 11581, 25264, 47502 }, { "Thunder Clap", "Tuono" })
        local shieldBlock  = FindBestSpellInRanks({ 2565 }, { "Shield Block", "Blocco con lo Scudo" })
        local sunder       = FindBestSpellInRanks({ 7386, 7405, 8380, 11596, 11597, 25225 }, { "Sunder Armor", "Fendi Armatura" })
        local mortalStrike = FindBestSpellInRanks({ 12294, 21551, 21552, 21553, 25248, 30330, 47486 }, { "Mortal Strike", "Assalto Mortale" })
        local overpower    = FindBestSpellInRanks({ 7384, 7887, 11584, 11585 }, { "Overpower", "Sopraffazione" })
        local bloodthirst  = FindBestSpellInRanks({ 23881, 23892, 23893, 23894, 25251, 30335 }, { "Bloodthirst", "Sete di Sangue" })
        local whirlwind    = FindBestSpellInRanks({ 1680 }, { "Whirlwind", "Turbine" })
        local victoryRush  = FindBestSpellInRanks({ 34428 }, { "Victory Rush", "Frenesia della Vittoria" })
        local rend         = FindBestSpellInRanks({ 772, 6546, 6547, 6548, 11572, 11573, 11574, 25208, 47465 }, { "Rend", "Lacerazione" })
        local heroicStrike = FindBestSpellInRanks({ 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, 47450 }, { "Heroic Strike", "Assalto Eroico" })

        if battleShout and ctx.inCombat and ctx.power >= 10 and not UnitHasAuraNamed("player", { "Battle Shout", "Commanding Shout", "Urlo di Battaglia" }) then
            AddCandidate(battleShout, "BUFF", "Battle Shout: +Attack Power", { noRangeCheck = true })
        end

        if canAttack and ctx.targetHp <= 20 and execute then
            AddCandidate(execute, "EXECUTE", "Execute: Bersaglio sotto al 20% salute!", { requireUsable = true })
        end

        if canAttack and victoryRush then
            AddCandidate(victoryRush, "PROC", "Victory Rush: Cura e danno gratuito", { requireUsable = true })
        end

        if isProt then
            if shieldBlock and ctx.inCombat and ctx.isShieldEquipped and not UnitHasAuraNamed("player", { "Shield Block", "Blocco con lo Scudo" }) then
                AddCandidate(shieldBlock, "DIFESA", "Shield Block: Attiva blocco garantito", { noRangeCheck = true })
            end
            if canAttack and shieldSlam and ctx.isShieldEquipped then
                AddCandidate(shieldSlam, "MINACCIA", "Shield Slam: Massima generazione minaccia")
            end
            if canAttack and revenge then
                AddCandidate(revenge, "PROC", "Revenge: Contrattacco ad alta minaccia", { requireUsable = true })
            end
            if canAttack and shockwave then
                AddCandidate(shockwave, "STUN", "Shockwave: Cono stordimento/minaccia", { noRangeCheck = true })
            end
            if canAttack and thunderClap then
                AddCandidate(thunderClap, "AOE", "Thunder Clap: Rallenta attacchi nemici", { noRangeCheck = true })
            end
            if canAttack and devastate then
                AddCandidate(devastate, "MINACCIA", "Devastate: Danno e Sunder Armor")
            elseif canAttack and sunder then
                AddCandidate(sunder, "DEBUFF", "Sunder Armor: Riduci armatura e accumula minaccia")
            end
        elseif canAttack and isFury then
            if bloodthirst then AddCandidate(bloodthirst, "BURST", "Bloodthirst su ricarica") end
            if whirlwind then AddCandidate(whirlwind, "AOE", "Whirlwind su ricarica", { noRangeCheck = true }) end
            if victoryRush then AddCandidate(victoryRush, "PROC", "Victory Rush", { requireUsable = true }) end
        elseif canAttack then
            if overpower then
                AddCandidate(overpower, "PROC", "Overpower: Colpo imparabile su schivata", { requireUsable = true })
            end
            if mortalStrike then AddCandidate(mortalStrike, "BURST", "Mortal Strike su ricarica") end
            if rend and not UnitHasDebuffNamed("target", { "Rend", "Lacerazione" }, true, 1.5) then
                AddCandidate(rend, "DOT", "Rend: Applica sanguinamento")
            end
            if whirlwind then AddCandidate(whirlwind, "AOE", "Whirlwind", { noRangeCheck = true }) end
        end

        if canAttack and ctx.power >= 50 and heroicStrike then
            AddCandidate(heroicStrike, "RABBIA", "Heroic Strike: Scarica rabbia in eccesso")
        end

    ---------------------------------------------------------------------------
    -- 3. MAGE ROTATION (Arcane, Fire, Frost)
    ---------------------------------------------------------------------------
    elseif cls == "MAGE" then
        local arcaneBlast    = FindBestSpellInRanks({ 30451, 42894, 42896, 42897 }, { "Arcane Blast", "Detonazione Arcana" })
        local arcaneBarrage  = FindBestSpellInRanks({ 44425, 44780, 44781 }, { "Arcane Barrage", "Sbarramento Arcano" })
        local arcaneMissiles = FindBestSpellInRanks({ 5143, 5144, 5145, 8416, 8417, 10211, 10212, 25345, 42846 }, { "Arcane Missiles", "Dardi Arcani" })
        local livingBomb     = FindBestSpellInRanks({ 44457, 55359, 55360 }, { "Living Bomb", "Bomba Vivente" })
        local pyroblast      = FindBestSpellInRanks({ 11366, 12505, 12522, 12523, 12524, 12525, 12526, 18809, 27132, 33938, 42891 }, { "Pyroblast", "Pirosfera" })
        local fireball       = FindBestSpellInRanks({ 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306, 42833 }, { "Fireball", "Palla di Fuoco" })
        local fireBlast      = FindBestSpellInRanks({ 2136, 2137, 2138, 8412, 8413, 10197, 10199, 10200, 27079, 42873 }, { "Fire Blast", "Detonazione di Fuoco" })
        local deepFreeze     = FindBestSpellInRanks({ 44572 }, { "Deep Freeze", "Congelamento Profondo" })
        local iceLance       = FindBestSpellInRanks({ 30455, 42913, 42914 }, { "Ice Lance", "Lancia di Ghiaccio" })
        local frostbolt      = FindBestSpellInRanks({ 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304, 42842 }, { "Frostbolt", "Dardo di Gelo" })

        if canAttack then
            if ctx.targetHp <= 18 and fireBlast then
                AddCandidate(fireBlast, "FINISHER", "Fire Blast: Colpo istantaneo finale")
            end
            if ctx.tabIdx == 1 and arcaneBlast then
                if UnitHasAuraNamed("player", { "Missile Barrage", "Sbarramento di Dardi" }) and arcaneMissiles then
                    AddCandidate(arcaneMissiles, "PROC", "Arcane Missiles su Missile Barrage!")
                end
                AddCandidate(arcaneBlast, "NUKE", "Arcane Blast")
                if arcaneBarrage then AddCandidate(arcaneBarrage, "INSTANT", "Arcane Barrage") end
            elseif ctx.tabIdx == 2 and fireball then
                if UnitHasAuraNamed("player", { "Hot Streak", "Serie Positiva" }) and pyroblast then
                    AddCandidate(pyroblast, "PROC", "Pyroblast istantaneo (Hot Streak)!")
                end
                if livingBomb and not UnitHasDebuffNamed("target", { "Living Bomb", "Bomba Vivente" }, true) then
                    AddCandidate(livingBomb, "DOT", "Living Bomb")
                end
                if fireBlast then AddCandidate(fireBlast, "INSTANT", "Fire Blast") end
                AddCandidate(fireball, "NUKE", "Fireball")
            else
                if deepFreeze then
                    AddCandidate(deepFreeze, "STUN", "Deep Freeze", { requireUsable = true })
                end
                if iceLance and (UnitHasAuraNamed("player", { "Fingers of Frost", "Dita di Gelo" }) or UnitHasDebuffNamed("target", { "Frost Nova", "Freeze", "Frostbite" })) then
                    AddCandidate(iceLance, "CRIT", "Ice Lance su bersaglio congelato!")
                end
                if frostbolt then
                    AddCandidate(frostbolt, "NUKE", "Frostbolt: Danno e rallentamento")
                elseif fireball then
                    AddCandidate(fireball, "NUKE", "Fireball")
                end
                if fireBlast then AddCandidate(fireBlast, "INSTANT", "Fire Blast istantaneo") end
            end
        end

    ---------------------------------------------------------------------------
    -- 4. ROGUE ROTATION (Assassination, Combat, Subtlety)
    ---------------------------------------------------------------------------
    elseif cls == "ROGUE" then
        local ambush       = FindBestSpellInRanks({ 8676, 8724, 8725, 11267, 11268, 11269, 27441, 48691 }, { "Ambush", "Agguato" })
        local cheapShot    = FindBestSpellInRanks({ 1833 }, { "Cheap Shot", "Colpo Basso" })
        local sliceAndDice = FindBestSpellInRanks({ 5171, 6774 }, { "Slice and Dice", "Affettamento" })
        local mutilate     = FindBestSpellInRanks({ 1329, 34411, 34412, 34413, 48663, 48666 }, { "Mutilate", "Mutilazione" })
        local envenom      = FindBestSpellInRanks({ 32645, 32684, 57992, 57993 }, { "Envenom", "Avvelenamento" })
        local rupture      = FindBestSpellInRanks({ 1943, 8639, 8640, 11273, 11274, 11275, 26867, 48672 }, { "Rupture", "Perforazione" })
        local eviscerate   = FindBestSpellInRanks({ 2098, 6747, 8623, 8624, 11299, 11300, 11301, 26865, 48668 }, { "Eviscerate", "Sventramento" })
        local hemorrhage   = FindBestSpellInRanks({ 16511, 17347, 17348, 26864, 48660 }, { "Hemorrhage", "Emorragia" })
        local sinister     = FindBestSpellInRanks({ 1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294, 26861, 48638 }, { "Sinister Strike", "Assalto Funesto" })
        local riposte      = FindBestSpellInRanks({ 14251 }, { "Riposte", "Risposta" })

        if canAttack then
            if ctx.isStealthed then
                if ambush then AddCandidate(ambush, "STEALTH", "Ambush da Furtività!", { requireUsable = true }) end
                if cheapShot then AddCandidate(cheapShot, "STUN", "Cheap Shot: Apri con stordimento") end
            end
            local hasSnD = UnitHasAuraNamed("player", { "Slice and Dice", "Affettamento" }, false, 1.5)
            if riposte then
                AddCandidate(riposte, "PROC", "Riposte: Disarma il nemico", { requireUsable = true })
            end
            if ctx.comboPoints >= 1 and not hasSnD and sliceAndDice then
                AddCandidate(sliceAndDice, "BUFF", "Slice and Dice: +Velocità d'attacco", { noRangeCheck = true })
            end
            if (ctx.comboPoints >= 4 or (ctx.targetHp <= 20 and ctx.comboPoints >= 2)) then
                if ctx.tabIdx == 1 and envenom then
                    AddCandidate(envenom, "FINISHER", "Envenom: Consuma combo con veleno")
                elseif rupture and ctx.targetHp > 35 and not UnitHasDebuffNamed("target", { "Rupture", "Perforazione" }, true, 2.0) then
                    AddCandidate(rupture, "DOT", "Rupture: Sanguinamento ad alto danno")
                elseif eviscerate then
                    AddCandidate(eviscerate, "FINISHER", "Eviscerate: Consuma i punti combo")
                end
            end
            if ctx.tabIdx == 1 and mutilate then
                AddCandidate(mutilate, "BUILDER", "Mutilate: Genera 2 punti combo")
            elseif ctx.tabIdx == 3 and hemorrhage then
                AddCandidate(hemorrhage, "BUILDER", "Hemorrhage: Debuff & combo")
            elseif sinister then
                AddCandidate(sinister, "BUILDER", "Sinister Strike: Genera punti combo")
            end
        end

    ---------------------------------------------------------------------------
    -- 5. WARLOCK ROTATION (Affliction, Demonology, Destruction)
    ---------------------------------------------------------------------------
    elseif cls == "WARLOCK" then
        local haunt      = FindBestSpellInRanks({ 48181, 59161, 59163, 59164 }, { "Haunt", "Infestazione" })
        local ua         = FindBestSpellInRanks({ 30108, 30404, 30405, 47841, 47843 }, { "Unstable Affliction", "Afflizione Instabile" })
        local agony      = FindBestSpellInRanks({ 980, 1014, 6217, 11711, 11712, 11713, 27218, 47864 }, { "Curse of Agony", "Maledizione dell'Agonia" })
        local corruption = FindBestSpellInRanks({ 172, 6222, 6223, 7648, 11671, 11672, 25311, 27216, 47813 }, { "Corruption", "Corruzione" })
        local immolate   = FindBestSpellInRanks({ 348, 707, 1094, 2941, 11665, 11667, 11668, 27215, 47811 }, { "Immolate", "Immolazione" })
        local conflag    = FindBestSpellInRanks({ 17962 }, { "Conflagrate", "Conflagrazione" })
        local chaosBolt  = FindBestSpellInRanks({ 50796, 59170, 59171, 59172 }, { "Chaos Bolt", "Dardo del Caos" })
        local incinerate = FindBestSpellInRanks({ 29722, 32231, 47837, 47838 }, { "Incinerate", "Incenerimento" })
        local shadowburn = FindBestSpellInRanks({ 17877, 18867, 18868, 18869, 18870, 18871, 27263, 30546, 47827 }, { "Shadowburn", "Bruciatura dell'Ombra" })
        local shadowbolt = FindBestSpellInRanks({ 686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307, 27209, 47809 }, { "Shadow Bolt", "Dardo d'Ombra" })
        local drainSoul  = FindBestSpellInRanks({ 1120, 8288, 8289, 11675, 27217, 47855 }, { "Drain Soul", "Risucchio d'Anima" })

        if canAttack then
            if ctx.targetHp <= 20 and drainSoul then
                AddCandidate(drainSoul, "SHARD", "Drain Soul: Frammento / Esecuzione < 20%")
            end
            if ctx.tabIdx == 3 then -- Destruction
                if immolate and not UnitHasDebuffNamed("target", { "Immolate", "Immolazione" }, true, 1.5) then
                    AddCandidate(immolate, "DOT", "Immolate: Prepara Conflagrate")
                end
                if conflag and UnitHasDebuffNamed("target", { "Immolate", "Immolazione" }, true) then
                    AddCandidate(conflag, "BURST", "Conflagrate su Immolate!", { requireUsable = true })
                end
                if chaosBolt then AddCandidate(chaosBolt, "NUKE", "Chaos Bolt") end
                if ctx.targetHp <= 25 and shadowburn then
                    AddCandidate(shadowburn, "FINISHER", "Shadowburn")
                end
                if incinerate then AddCandidate(incinerate, "NUKE", "Incinerate")
                elseif shadowbolt then AddCandidate(shadowbolt, "NUKE", "Shadow Bolt") end
            else -- Affliction / Demonology / Leveling
                if haunt and not UnitHasDebuffNamed("target", { "Haunt", "Infestazione" }, true, 1.5) then
                    AddCandidate(haunt, "DOT", "Haunt: Potenzia i DoT")
                end
                if ua and not UnitHasDebuffNamed("target", { "Unstable Affliction", "Afflizione Instabile" }, true, 1.5) then
                    AddCandidate(ua, "DOT", "Unstable Affliction")
                end
                if agony and not UnitHasDebuffNamed("target", { "Curse of Agony", "Maledizione dell'Agonia" }, true, 1.5) then
                    AddCandidate(agony, "DOT", "Curse of Agony")
                end
                if corruption and not UnitHasDebuffNamed("target", { "Corruption", "Corruzione" }, true, 1.5) then
                    AddCandidate(corruption, "DOT", "Corruption")
                end
                if immolate and not ua and not UnitHasDebuffNamed("target", { "Immolate", "Immolazione" }, true, 1.5) then
                    AddCandidate(immolate, "DOT", "Immolate")
                end
                if shadowbolt then AddCandidate(shadowbolt, "NUKE", "Shadow Bolt") end
            end
        end

    ---------------------------------------------------------------------------
    -- 6. PRIEST ROTATION (Shadow, Discipline, Holy)
    ---------------------------------------------------------------------------
    elseif cls == "PRIEST" then
        local isShadow = (ctx.tabIdx == 3) or UnitHasAuraNamed("player", { "Shadowform", "Forma d'Ombra" })
        local vt         = FindBestSpellInRanks({ 34914, 34916, 34917, 48160 }, { "Vampiric Touch", "Tocco Vampirico" })
        local devPlague  = FindBestSpellInRanks({ 2944, 19276, 19277, 19278, 19279, 19280, 25467, 48300 }, { "Devouring Plague", "Piaga Divoratrice" })
        local swp        = FindBestSpellInRanks({ 589, 594, 970, 992, 2767, 10892, 10893, 10894, 25368, 48125 }, { "Shadow Word: Pain", "Parola d'Ombra: Dolore" })
        local mindBlast  = FindBestSpellInRanks({ 8092, 8102, 8103, 8104, 10945, 10946, 10947, 25375, 48127 }, { "Mind Blast", "Detonazione Mentale" })
        local swd        = FindBestSpellInRanks({ 32379, 32996, 48158 }, { "Shadow Word: Death", "Parola d'Ombra: Morte" })
        local mindFlay   = FindBestSpellInRanks({ 15407, 17311, 17312, 17313, 17314, 18807, 25387, 48156 }, { "Mind Flay", "Tortura Mentale" })
        local holyFire   = FindBestSpellInRanks({ 14914, 15262, 15263, 15264, 15265, 15266, 15267, 25384, 48135 }, { "Holy Fire", "Fuoco Sacro" })
        local penance    = FindBestSpellInRanks({ 47540, 53005, 53006, 53007 }, { "Penance", "Penitenza" })
        local smite      = FindBestSpellInRanks({ 585, 591, 598, 984, 1004, 6060, 10933, 10934, 25364, 48123 }, { "Smite", "Punizione" })

        if canAttack then
            if swd and ctx.targetHp <= 20 then AddCandidate(swd, "ESECUZIONE", "Shadow Word: Death") end
            if isShadow or mindFlay then
                if vt and not UnitHasDebuffNamed("target", { "Vampiric Touch", "Tocco Vampirico" }, true, 1.5) then
                    AddCandidate(vt, "DOT", "Vampiric Touch")
                end
                if devPlague and not UnitHasDebuffNamed("target", { "Devouring Plague", "Piaga Divoratrice" }, true, 1.5) then
                    AddCandidate(devPlague, "DOT", "Devouring Plague")
                end
                if swp and not UnitHasDebuffNamed("target", { "Shadow Word: Pain", "Parola d'Ombra: Dolore" }, true, 1.5) then
                    AddCandidate(swp, "DOT", "Shadow Word: Pain")
                end
                if mindBlast then AddCandidate(mindBlast, "BURST", "Mind Blast") end
                if mindFlay then AddCandidate(mindFlay, "CHANNEL", "Mind Flay") elseif smite then AddCandidate(smite, "NUKE", "Smite") end
            else
                if holyFire then AddCandidate(holyFire, "DOT", "Holy Fire") end
                if swp and not UnitHasDebuffNamed("target", { "Shadow Word: Pain", "Parola d'Ombra: Dolore" }, true, 1.5) then
                    AddCandidate(swp, "DOT", "Shadow Word: Pain")
                end
                if penance then AddCandidate(penance, "CHANNEL", "Penance") end
                if smite then AddCandidate(smite, "NUKE", "Smite") end
                if mindBlast then AddCandidate(mindBlast, "BURST", "Mind Blast") end
            end
        end

    ---------------------------------------------------------------------------
    -- 7. HUNTER ROTATION (BM, Marksmanship, Survival)
    ---------------------------------------------------------------------------
    elseif cls == "HUNTER" then
        local killShot   = FindBestSpellInRanks({ 53351, 61005, 61006 }, { "Kill Shot", "Tiro Mortale" })
        local mark       = FindBestSpellInRanks({ 1130, 14323, 14324, 14325, 53338 }, { "Hunter's Mark", "Marchio del Cacciatore" })
        local sting      = FindBestSpellInRanks({ 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016, 49001 }, { "Serpent Sting", "Morso del Serpente" })
        local chimera    = FindBestSpellInRanks({ 53209 }, { "Chimera Shot", "Tiro della Chimera" })
        local explosive  = FindBestSpellInRanks({ 53301, 60051, 60052, 60053 }, { "Explosive Shot", "Tiro Esplosivo" })
        local blackArrow = FindBestSpellInRanks({ 3674, 63668, 63669, 63670 }, { "Black Arrow", "Freccia Nera" })
        local aimed      = FindBestSpellInRanks({ 19434, 20900, 20901, 20902, 20903, 20904, 27065, 49050 }, { "Aimed Shot", "Tiro Mirato" })
        local multi      = FindBestSpellInRanks({ 2643, 14288, 14289, 14290, 25294, 27021, 49048 }, { "Multi-Shot", "Tiro Multiplo" })
        local arcane     = FindBestSpellInRanks({ 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287, 27019, 49045 }, { "Arcane Shot", "Tiro Arcano" })
        local steady     = FindBestSpellInRanks({ 34120, 49051, 49052 }, { "Steady Shot", "Tiro Stabilizzato" })

        if canAttack then
            if killShot and ctx.targetHp <= 20 then AddCandidate(killShot, "ESECUZIONE", "Kill Shot < 20%!") end
            if mark and not UnitHasDebuffNamed("target", { "Hunter's Mark", "Marchio del Cacciatore" }) then
                AddCandidate(mark, "MARK", "Hunter's Mark: +Ranged Attack Power")
            end
            if sting and not UnitHasDebuffNamed("target", { "Serpent Sting", "Morso del Serpente" }, true, 1.5) then
                AddCandidate(sting, "DOT", "Serpent Sting: Veleno continuativo")
            end
            if explosive then AddCandidate(explosive, "BURST", "Explosive Shot") end
            if chimera then AddCandidate(chimera, "BURST", "Chimera Shot") end
            if blackArrow then AddCandidate(blackArrow, "DOT", "Black Arrow") end
            if aimed then AddCandidate(aimed, "BURST", "Aimed Shot") end
            if multi then AddCandidate(multi, "BURST", "Multi-Shot") end
            if arcane then AddCandidate(arcane, "INSTANT", "Arcane Shot") end
            if steady then AddCandidate(steady, "FILLER", "Steady Shot") end
        end

    ---------------------------------------------------------------------------
    -- 8. DRUID ROTATION (Balance, Feral Bear, Feral Cat, Resto)
    ---------------------------------------------------------------------------
    elseif cls == "DRUID" then
        local faerieFire = FindBestSpellInRanks({ 770, 778, 9749, 9907, 16857, 17390, 17391, 17392, 26993 }, { "Faerie Fire", "Faerie Fire (Feral)", "Fuoco Fatato" })
        local mangleBear = FindBestSpellInRanks({ 33878, 33986, 33987, 48564 }, { "Mangle (Bear)", "Lacerazione (Orso)" })
        local lacerate   = FindBestSpellInRanks({ 33745, 48567, 48568 }, { "Lacerate", "Lacerazione" })
        local swipe      = FindBestSpellInRanks({ 779, 780, 769, 9754, 9908, 26997, 48562 }, { "Swipe", "Swipe (Bear)", "Spazzata" })
        local maul       = FindBestSpellInRanks({ 6807, 6808, 6809, 6810, 9745, 9880, 9881, 26996, 48480 }, { "Maul", "Zampata" })

        local mangleCat  = FindBestSpellInRanks({ 33876, 33982, 33983, 48566 }, { "Mangle (Cat)", "Lacerazione (Felino)" })
        local rake       = FindBestSpellInRanks({ 1822, 1823, 1824, 9904, 27003, 48574 }, { "Rake", "Graffio" })
        local savageRoar = FindBestSpellInRanks({ 52610 }, { "Savage Roar", "Ruggito Selvaggio" })
        local claw       = FindBestSpellInRanks({ 1082, 3029, 5201, 9849, 9850, 27000, 48570 }, { "Claw", "Artiglio" })
        local shred      = FindBestSpellInRanks({ 5221, 6800, 8992, 9829, 9830, 27002, 48572 }, { "Shred", "Dilaniamento" })
        local rip        = FindBestSpellInRanks({ 1079, 9492, 9493, 9752, 9894, 9896, 27008, 49800 }, { "Rip", "Squarcio" })
        local ferocious  = FindBestSpellInRanks({ 22568, 22827, 22828, 22829, 31018, 24248, 48577 }, { "Ferocious Bite", "Morso Feroce" })

        local insectSwarm = FindBestSpellInRanks({ 5570, 24974, 24975, 24976, 24977, 27013, 48468 }, { "Insect Swarm", "Sciame d'Insetti" })
        local moonfire   = FindBestSpellInRanks({ 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835, 26988, 48463 }, { "Moonfire", "Fuoco Lunare" })
        local starfire   = FindBestSpellInRanks({ 2912, 8949, 8950, 8951, 9875, 9876, 25298, 26986, 48465 }, { "Starfire", "Fuoco Stellare" })
        local wrath      = FindBestSpellInRanks({ 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912, 26985, 48461 }, { "Wrath", "Ira" })

        if canAttack then
            if ctx.powerType == 1 then -- Bear / Guardian
                if mangleBear then AddCandidate(mangleBear, "THREAT", "Mangle (Bear): Danno & Minaccia") end
                if faerieFire and not UnitHasDebuffNamed("target", { "Faerie Fire", "Fuoco Fatato" }) then
                    AddCandidate(faerieFire, "DEBUFF", "Faerie Fire: Riduci armatura")
                end
                if lacerate and not UnitHasDebuffNamed("target", { "Lacerate", "Lacerazione" }, true, 3.0) then
                    AddCandidate(lacerate, "DOT", "Lacerate: Minaccia e sanguinamento")
                end
                if swipe then AddCandidate(swipe, "AOE", "Swipe: Minaccia ad area", { noRangeCheck = true }) end
                if maul and ctx.power >= 35 then AddCandidate(maul, "RAGE", "Maul: Scarica rabbia") end
            elseif ctx.powerType == 3 then -- Cat / Feral DPS
                if savageRoar and ctx.comboPoints >= 1 and not UnitHasAuraNamed("player", { "Savage Roar", "Ruggito Selvaggio" }, false, 1.5) then
                    AddCandidate(savageRoar, "BUFF", "Savage Roar: +30% danni fisici", { noRangeCheck = true })
                end
                if faerieFire and not UnitHasDebuffNamed("target", { "Faerie Fire", "Fuoco Fatato" }) then
                    AddCandidate(faerieFire, "DEBUFF", "Faerie Fire: Riduci armatura")
                end
                if rake and not UnitHasDebuffNamed("target", { "Rake", "Graffio" }, true, 1.5) then
                    AddCandidate(rake, "DOT", "Rake: Sanguinamento")
                end
                if ctx.comboPoints >= 4 then
                    if rip and ctx.targetHp > 25 and not UnitHasDebuffNamed("target", { "Rip", "Squarcio" }, true, 1.5) then
                        AddCandidate(rip, "FINISHER", "Rip: Sanguinamento ad alto danno")
                    elseif ferocious then
                        AddCandidate(ferocious, "FINISHER", "Ferocious Bite")
                    end
                end
                if mangleCat then AddCandidate(mangleCat, "BUILDER", "Mangle (Cat)")
                elseif shred and ctx.isStealthed then AddCandidate(shred, "STEALTH", "Shred", { requireUsable = true })
                elseif claw then AddCandidate(claw, "BUILDER", "Claw: Accumula combo") end
            else -- Caster / Balance / Resto solo
                if insectSwarm and not UnitHasDebuffNamed("target", { "Insect Swarm", "Sciame d'Insetti" }, true, 1.5) then
                    AddCandidate(insectSwarm, "DOT", "Insect Swarm")
                end
                if moonfire and not UnitHasDebuffNamed("target", { "Moonfire", "Fuoco Lunare" }, true, 1.5) then
                    AddCandidate(moonfire, "DOT", "Moonfire")
                end
                if UnitHasAuraNamed("player", { "Eclipse (Lunar)", "Eclissi (Lunare)" }) and starfire then
                    AddCandidate(starfire, "ECLIPSE", "Starfire su Eclissi Lunare!")
                elseif UnitHasAuraNamed("player", { "Eclipse (Solar)", "Eclissi (Solare)" }) and wrath then
                    AddCandidate(wrath, "ECLIPSE", "Wrath su Eclissi Solare!")
                else
                    if wrath then AddCandidate(wrath, "NUKE", "Wrath") end
                    if starfire then AddCandidate(starfire, "NUKE", "Starfire") end
                end
            end
        end

    ---------------------------------------------------------------------------
    -- 9. SHAMAN ROTATION (Elemental, Enhancement, Restoration)
    ---------------------------------------------------------------------------
    elseif cls == "SHAMAN" then
        local flameShock  = FindBestSpellInRanks({ 8050, 8052, 8053, 10447, 10448, 29228, 25457, 49233 }, { "Flame Shock", "Folgore del Fuoco" })
        local earthShock  = FindBestSpellInRanks({ 8042, 8044, 8045, 8046, 10412, 10413, 10414, 25454, 49231 }, { "Earth Shock", "Folgore della Terra" })
        local lavaBurst   = FindBestSpellInRanks({ 51505, 60043 }, { "Lava Burst", "Getto di Lava" })
        local chainLight  = FindBestSpellInRanks({ 421, 930, 2860, 10605, 25442, 49271 }, { "Chain Lightning", "Catena di Fulmini" })
        local lightning   = FindBestSpellInRanks({ 403, 529, 548, 915, 943, 6041, 10391, 10392, 25449, 49238 }, { "Lightning Bolt", "Dardo Fulminante" })
        local stormstrike = FindBestSpellInRanks({ 17364 }, { "Stormstrike", "Assalto della Tempesta" })
        local lavaLash    = FindBestSpellInRanks({ 60103 }, { "Lava Lash", "Frustata di Lava" })

        if canAttack then
            if ctx.tabIdx == 2 and (stormstrike or lavaLash) then -- Enhancement
                if stormstrike then AddCandidate(stormstrike, "BURST", "Stormstrike: Danno doppio con armi") end
                if flameShock and not UnitHasDebuffNamed("target", { "Flame Shock", "Folgore del Fuoco" }, true, 1.5) then
                    AddCandidate(flameShock, "DOT", "Flame Shock")
                end
                if earthShock then AddCandidate(earthShock, "SHOCK", "Earth Shock") end
                if lavaLash then AddCandidate(lavaLash, "OFFHAND", "Lava Lash") end
                if lightning then AddCandidate(lightning, "NUKE", "Lightning Bolt") end
            else -- Elemental / Resto solo
                if flameShock and not UnitHasDebuffNamed("target", { "Flame Shock", "Folgore del Fuoco" }, true, 1.5) then
                    AddCandidate(flameShock, "DOT", "Flame Shock")
                end
                if lavaBurst and UnitHasDebuffNamed("target", { "Flame Shock", "Folgore del Fuoco" }, true) then
                    AddCandidate(lavaBurst, "CRIT", "Lava Burst garantito critico su Flame Shock!")
                end
                if chainLight then AddCandidate(chainLight, "BURST", "Chain Lightning") end
                if earthShock and not lavaBurst then AddCandidate(earthShock, "SHOCK", "Earth Shock") end
                if lightning then AddCandidate(lightning, "NUKE", "Lightning Bolt") end
            end
        end

    ---------------------------------------------------------------------------
    -- 10. DEATH KNIGHT ROTATION (Blood, Frost, Unholy)
    ---------------------------------------------------------------------------
    elseif cls == "DEATHKNIGHT" then
        local icyTouch     = FindBestSpellInRanks({ 45477, 49896, 49903, 49904, 49909 }, { "Icy Touch", "Tocco Ghiacciato" })
        local plagueStrike = FindBestSpellInRanks({ 45462, 49917, 49918, 49919, 49920, 49921 }, { "Plague Strike", "Assalto della Piaga" })
        local deathStrike  = FindBestSpellInRanks({ 49998, 49999, 45463, 49923, 49924 }, { "Death Strike", "Assalto della Morte" })
        local scourgeStrike = FindBestSpellInRanks({ 55090, 55265, 55270, 55271 }, { "Scourge Strike", "Assalto del Flagello" })
        local howlingBlast = FindBestSpellInRanks({ 49184, 51409, 51410, 51411 }, { "Howling Blast", "Rafficata Ululante" })
        local heartStrike  = FindBestSpellInRanks({ 55050, 55258, 55259, 55260, 55261, 55262 }, { "Heart Strike", "Assalto al Cuore" })
        local bloodStrike  = FindBestSpellInRanks({ 45902, 49926, 49927, 49928, 49929, 49930 }, { "Blood Strike", "Assalto del Sangue" })
        local obliterate   = FindBestSpellInRanks({ 49020, 51423, 51424, 51425 }, { "Obliterate", "Disintegrazione" })
        local frostStrike  = FindBestSpellInRanks({ 49143, 51416, 51417, 51418, 51419, 55268 }, { "Frost Strike", "Assalto del Gelo" })
        local deathCoil    = FindBestSpellInRanks({ 47541, 49892, 49893, 49894, 49895 }, { "Death Coil", "Spira Mortale" })

        if canAttack then
            if (ctx.role == "TANK" or ctx.selfHpPct < 0.65) and deathStrike then
                AddCandidate(deathStrike, "SURVIVE", "Death Strike: Cura & Runic")
            end
            if icyTouch and not UnitHasDebuffNamed("target", { "Frost Fever", "Febbre del Gelo" }, true, 1.5) then
                AddCandidate(icyTouch, "DISEASE", "Icy Touch: Applica Febbre del Gelo")
            end
            if plagueStrike and not UnitHasDebuffNamed("target", { "Blood Plague", "Piaga del Sangue" }, true, 1.5) then
                AddCandidate(plagueStrike, "DISEASE", "Plague Strike: Applica Piaga del Sangue")
            end
            if ctx.tabIdx == 3 and scourgeStrike then
                AddCandidate(scourgeStrike, "BURST", "Scourge Strike")
            elseif ctx.tabIdx == 2 and howlingBlast and UnitHasAuraNamed("player", { "Freezing Fog", "Nebbia Gelida" }) then
                AddCandidate(howlingBlast, "PROC", "Howling Blast gratuito!")
            elseif obliterate then
                AddCandidate(obliterate, "BURST", "Obliterate")
            end
            if heartStrike then
                AddCandidate(heartStrike, "CLEAVE", "Heart Strike")
            elseif bloodStrike then
                AddCandidate(bloodStrike, "RUNE", "Blood Strike")
            end
            if frostStrike and ctx.power >= 40 then
                AddCandidate(frostStrike, "DUMP", "Frost Strike")
            elseif deathCoil and ctx.power >= 40 then
                AddCandidate(deathCoil, "DUMP", "Death Coil")
            end
        end
    end

    -- Sort candidates cleanly:
    -- 1. Ready, usable, enough resource, AND in range (ordered by spec priority)
    -- 2. Ready, usable, enough resource, out of range (if melee waiting to close distance)
    -- 3. On cooldown (usable & in range), ordered by SHORTEST remaining timer (shows live timer!)
    -- 4. Ready or waiting but out of resource/range
    table.sort(list, function(a, b)
        local aInRange = (a.inRange ~= 0 and a.inRange ~= false)
        local bInRange = (b.inRange ~= 0 and b.inRange ~= false)
        local aPlayable = a.isReady and a.usable and not a.noMana and aInRange
        local bPlayable = b.isReady and b.usable and not b.noMana and bInRange

        if aPlayable and not bPlayable then return true end
        if not aPlayable and bPlayable then return false end
        if aPlayable and bPlayable then return a.order < b.order end

        local aWaitingCD = (not a.isReady) and a.usable and not a.noMana and aInRange
        local bWaitingCD = (not b.isReady) and b.usable and not b.noMana and bInRange
        if aWaitingCD and not bWaitingCD then return true end
        if not aWaitingCD and bWaitingCD then return false end
        if aWaitingCD and bWaitingCD then
            if math.abs((a.remaining or 0) - (b.remaining or 0)) > 0.15 then
                return (a.remaining or 0) < (b.remaining or 0)
            end
            return a.order < b.order
        end

        if a.isReady and not b.isReady then return true end
        if not a.isReady and b.isReady then return false end

        if math.abs((a.remaining or 0) - (b.remaining or 0)) > 0.15 then
            return (a.remaining or 0) < (b.remaining or 0)
        end

        return a.order < b.order
    end)

    return list
end

-------------------------------------------------------------------------------
-- UI Frame Construction (Draggable, customizable HUD)
-------------------------------------------------------------------------------
local rootFrame = CreateFrame("Frame", "NKRotationFrame", UIParent, "BackdropTemplate")
rootFrame:SetSize(96, 62)
rootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
rootFrame:SetClampedToScreen(true)
rootFrame:SetMovable(true)
rootFrame:EnableMouse(false)
rootFrame:SetFrameStrata("HIGH")
rootFrame:SetFrameLevel(50)

rootFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
rootFrame:SetBackdropColor(0, 0, 0, 0)
rootFrame:SetBackdropBorderColor(0, 0, 0, 0)

-- Drag Title Bar (Visible when unlocked)
local dragTitle = rootFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dragTitle:SetPoint("BOTTOM", rootFrame, "TOP", 0, 3)
dragTitle:SetText("|cffffd100[Rotazione Spell]|r (Trascina)")
dragTitle:Hide()

rootFrame:RegisterForDrag("LeftButton")
rootFrame:SetScript("OnDragStart", function(self)
    if not IsRotationLocked() then
        self:StartMoving()
    end
end)
rootFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    local s = GetSettings()
    s.rotationPos = { point = point, relPoint = relPoint, x = x, y = y }
end)

-- Main / Primary Action Slot (Large 46x46)
local mainSlot = CreateFrame("Frame", nil, rootFrame, "BackdropTemplate")
mainSlot:SetSize(46, 46)
mainSlot:SetPoint("LEFT", rootFrame, "LEFT", 4, 4)
mainSlot:EnableMouse(false)
mainSlot:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 16, edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
mainSlot:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
mainSlot:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)

local mainIcon = mainSlot:CreateTexture(nil, "ARTWORK")
mainIcon:SetPoint("TOPLEFT", mainSlot, "TOPLEFT", 2, -2)
mainIcon:SetPoint("BOTTOMRIGHT", mainSlot, "BOTTOMRIGHT", -2, 2)
mainIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
mainSlot.icon = mainIcon

local mainCooldown = CreateFrame("Cooldown", nil, mainSlot, "CooldownFrameTemplate")
mainCooldown:SetPoint("TOPLEFT", mainSlot, "TOPLEFT", 2, -2)
mainCooldown:SetPoint("BOTTOMRIGHT", mainSlot, "BOTTOMRIGHT", -2, 2)
if mainCooldown.SetDrawEdge then mainCooldown:SetDrawEdge(true) end
if mainCooldown.SetSwipeColor then mainCooldown:SetSwipeColor(0, 0, 0, 0.72) end
if mainCooldown.SetHideCountdownNumbers then mainCooldown:SetHideCountdownNumbers(true) end
mainSlot.cooldown = mainCooldown

local mainTextOverlay = CreateFrame("Frame", nil, mainSlot)
mainTextOverlay:SetAllPoints(mainSlot)
mainTextOverlay:SetFrameLevel(mainCooldown:GetFrameLevel() + 8)

local mainKeybind = mainTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
mainKeybind:SetPoint("TOPRIGHT", mainTextOverlay, "TOPRIGHT", -3, -3)
mainKeybind:SetTextColor(1.0, 1.0, 1.0, 1.0)
mainSlot.keybind = mainKeybind

local mainTimerText = mainTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
mainTimerText:SetPoint("CENTER", mainTextOverlay, "CENTER", 0, 0)
local tFont = mainTimerText:GetFont()
if tFont then
    mainTimerText:SetFont(tFont, 15, "OUTLINE")
end
mainTimerText:SetTextColor(1.0, 0.95, 0.2, 1.0)
mainTimerText:Hide()
mainSlot.timerText = mainTimerText

local mainBadge = rootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mainBadge:SetPoint("TOP", mainSlot, "BOTTOM", 0, -2)
mainBadge:SetTextColor(1.0, 0.85, 0.2, 1.0)

-- Secondary / Queue Action Slot (Smaller 32x32)
local queueSlot = CreateFrame("Frame", nil, rootFrame, "BackdropTemplate")
queueSlot:SetSize(32, 32)
queueSlot:SetPoint("LEFT", mainSlot, "RIGHT", 8, 0)
queueSlot:EnableMouse(false)
queueSlot:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 16, edgeSize = 1.5,
    insets = { left = 1.5, right = 1.5, top = 1.5, bottom = 1.5 }
})
queueSlot:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
queueSlot:SetBackdropBorderColor(0.45, 0.45, 0.5, 0.85)

local queueIcon = queueSlot:CreateTexture(nil, "ARTWORK")
queueIcon:SetPoint("TOPLEFT", queueSlot, "TOPLEFT", 1.5, -1.5)
queueIcon:SetPoint("BOTTOMRIGHT", queueSlot, "BOTTOMRIGHT", -1.5, 1.5)
queueIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
queueSlot.icon = queueIcon

local queueCooldown = CreateFrame("Cooldown", nil, queueSlot, "CooldownFrameTemplate")
queueCooldown:SetPoint("TOPLEFT", queueSlot, "TOPLEFT", 1.5, -1.5)
queueCooldown:SetPoint("BOTTOMRIGHT", queueSlot, "BOTTOMRIGHT", -1.5, 1.5)
if queueCooldown.SetDrawEdge then queueCooldown:SetDrawEdge(true) end
if queueCooldown.SetSwipeColor then queueCooldown:SetSwipeColor(0, 0, 0, 0.72) end
if queueCooldown.SetHideCountdownNumbers then queueCooldown:SetHideCountdownNumbers(true) end
queueSlot.cooldown = queueCooldown

local queueTextOverlay = CreateFrame("Frame", nil, queueSlot)
queueTextOverlay:SetAllPoints(queueSlot)
queueTextOverlay:SetFrameLevel(queueCooldown:GetFrameLevel() + 8)

local queueKeybind = queueTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
queueKeybind:SetPoint("TOPRIGHT", queueTextOverlay, "TOPRIGHT", -2, -2)
queueKeybind:SetTextColor(0.9, 0.9, 0.9, 1.0)
queueSlot.keybind = queueKeybind

local queueTimerText = queueTextOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
queueTimerText:SetPoint("CENTER", queueTextOverlay, "CENTER", 0, 0)
queueTimerText:SetTextColor(1.0, 0.95, 0.2, 1.0)
queueTimerText:Hide()
queueSlot.timerText = queueTimerText

-------------------------------------------------------------------------------
-- Update Loop
-------------------------------------------------------------------------------
local lastUiScale, lastUiAlpha, lastUiLocked, lastUiQueueMode = nil, nil, nil, nil

local function FormatCooldownTimer(rem)
    if not rem or rem <= 0.15 then return "" end
    if rem >= 60 then
        return string.format("%dm", math.ceil(rem / 60))
    elseif rem >= 10 then
        return string.format("%ds", math.ceil(rem))
    else
        return string.format("%.1fs", rem)
    end
end

local function ApplyCooldownOrStateVisual(iconTex, cdFrame, timerFs, slotFrame, entry, isSecondary)
    if not entry.isReady and entry.remaining and entry.remaining > 0.15 then
        local dur = math.max(entry.duration or 0, entry.remaining, 1.5)
        local now = (GetTime and SafeCall(GetTime)) or 0
        local start = (now + entry.remaining) - dur
        if start > 0 and dur > 0 then
            cdFrame:SetCooldown(start, dur)
        else
            cdFrame:Clear()
        end
        iconTex:SetVertexColor(0.55, 0.55, 0.55)
        slotFrame:SetBackdropBorderColor(0.95, 0.55, 0.15, 0.95)
        timerFs:SetText(FormatCooldownTimer(entry.remaining))
        timerFs:Show()
    else
        cdFrame:Clear()
        timerFs:SetText("")
        timerFs:Hide()
        if entry.inRange == 0 or entry.inRange == false then
            iconTex:SetVertexColor(1.0, 0.4, 0.4)
            slotFrame:SetBackdropBorderColor(1.0, 0.25, 0.25, 1.0)
        elseif entry.noMana then
            iconTex:SetVertexColor(0.4, 0.6, 1.0)
            slotFrame:SetBackdropBorderColor(0.3, 0.6, 1.0, 0.95)
        else
            iconTex:SetVertexColor(1.0, 1.0, 1.0)
            if isSecondary then
                slotFrame:SetBackdropBorderColor(0.45, 0.45, 0.5, 0.85)
            else
                slotFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            end
        end
    end
end

local function UpdateRotationUI()
    if not IsRotationEnabled() then
        if rootFrame:IsShown() then rootFrame:Hide() end
        return
    end

    local s = GetSettings()
    if s.rotationPos and not rootFrame.posLoaded then
        rootFrame.posLoaded = true
        rootFrame:ClearAllPoints()
        rootFrame:SetPoint(s.rotationPos.point, UIParent, s.rotationPos.relPoint, s.rotationPos.x, s.rotationPos.y)
    end

    local isLocked = IsRotationLocked()
    if isLocked ~= lastUiLocked then
        lastUiLocked = isLocked
        if isLocked then
            dragTitle:Hide()
            rootFrame:EnableMouse(false)
            rootFrame:SetBackdropColor(0, 0, 0, 0)
            rootFrame:SetBackdropBorderColor(0, 0, 0, 0)
        else
            dragTitle:Show()
            rootFrame:EnableMouse(true)
            rootFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.75)
            rootFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)
        end
    end

    local scale = GetRotationScale()
    if scale ~= lastUiScale then
        lastUiScale = scale
        rootFrame:SetScale(scale)
    end
    local alpha = GetRotationAlpha()
    if alpha ~= lastUiAlpha then
        lastUiAlpha = alpha
        rootFrame:SetAlpha(alpha)
    end

    local ctx = GetPlayerCombatContext()
    local mode = GetRotationMode()

    local shouldShow = false
    if not isLocked then
        shouldShow = true -- Always show while moving/configuring
    elseif mode == "always" then
        shouldShow = true
    elseif mode == "target" then
        shouldShow = ctx.hasTarget and not ctx.targetDead
    else -- "combat" (default)
        shouldShow = ctx.inCombat or (ctx.hasTarget and ctx.targetHostile and not ctx.targetDead)
    end

    if not shouldShow then
        if rootFrame:IsShown() then rootFrame:Hide() end
        return
    end

    if not rootFrame:IsShown() then
        rootFrame:Show()
    end

    local candidates = BuildRotation(ctx)
    local first = candidates[1]
    local second = candidates[2]

    if first then
        local tex = first.icon
        if not tex or tex == "" or tex == 0 then
            tex = "Interface\\Icons\\INV_Misc_QuestionMark"
        end
        mainIcon:SetTexture(tex)
        mainIcon:Show()
        mainBadge:SetText(first.badge or "")

        if first.keybind and first.keybind ~= "" then
            mainKeybind:SetText(first.keybind)
            mainKeybind:Show()
        else
            mainKeybind:Hide()
        end

        -- Cooldown / Waiting Timer indicator (always show timer if waiting on cooldown!)
        ApplyCooldownOrStateVisual(mainIcon, mainCooldown, mainTimerText, mainSlot, first, false)
        mainSlot:Show()
    else
        mainIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        mainIcon:SetVertexColor(0.8, 0.8, 0.8)
        mainSlot:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
        mainBadge:SetText("ATTESA")
        mainKeybind:Hide()
        mainCooldown:Clear()
        mainTimerText:SetText("")
        mainTimerText:Hide()
        mainSlot:Show()
    end

    -- Queue slot (2nd upcoming spell)
    local showQueueNow = IsQueueVisible() and second ~= nil
    if showQueueNow then
        if lastUiQueueMode ~= true then
            lastUiQueueMode = true
            mainSlot:ClearAllPoints()
            mainSlot:SetPoint("LEFT", rootFrame, "LEFT", 4, 4)
            queueSlot:Show()
            rootFrame:SetWidth(96)
        end
        queueIcon:SetTexture(second.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        if second.keybind and second.keybind ~= "" then
            queueKeybind:SetText(second.keybind)
            queueKeybind:Show()
        else
            queueKeybind:Hide()
        end
        ApplyCooldownOrStateVisual(queueIcon, queueCooldown, queueTimerText, queueSlot, second, true)
    else
        if lastUiQueueMode ~= false then
            lastUiQueueMode = false
            mainSlot:ClearAllPoints()
            mainSlot:SetPoint("CENTER", rootFrame, "CENTER", 0, 4)
            queueSlot:Hide()
            rootFrame:SetWidth(56)
        end
    end
end

-------------------------------------------------------------------------------
-- Event Wiring & Throttled OnUpdate Ticker
-------------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
SafeRegisterEvent(evFrame, "PLAYER_LOGIN")
SafeRegisterEvent(evFrame, "PLAYER_TARGET_CHANGED")
SafeRegisterEvent(evFrame, "PLAYER_REGEN_DISABLED")
SafeRegisterEvent(evFrame, "PLAYER_REGEN_ENABLED")
SafeRegisterEvent(evFrame, "UNIT_POWER_UPDATE")
SafeRegisterEvent(evFrame, "ACTIONBAR_SLOT_CHANGED")
SafeRegisterEvent(evFrame, "UPDATE_BINDINGS")
SafeRegisterEvent(evFrame, "SPELL_UPDATE_COOLDOWN")
SafeRegisterEvent(evFrame, "SPELL_UPDATE_USABLE")
SafeRegisterEvent(evFrame, "SPELLS_CHANGED")
SafeRegisterEvent(evFrame, "LEARNED_SPELL_IN_TAB")
SafeRegisterEvent(evFrame, "CHARACTER_POINTS_CHANGED")
SafeRegisterEvent(evFrame, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(evFrame, "UNIT_SPELLCAST_SENT")
SafeRegisterEvent(evFrame, "UNIT_SPELLCAST_SUCCEEDED")
SafeRegisterEvent(evFrame, "UNIT_SPELLCAST_START")
SafeRegisterEvent(evFrame, "UNIT_AURA")

evFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5)
    local now = (GetTime and SafeCall(GetTime)) or 0
    if type(now) ~= "number" then now = 0 end

    if event == "UNIT_SPELLCAST_SENT" and IsAccessible(arg1) and arg1 == "player" then
        local sentID = (IsAccessible(arg4) and type(arg4) == "number" and arg4)
            or (IsAccessible(arg3) and type(arg3) == "number" and arg3)
            or nil
        if sentID then
            lastSentSpellID = sentID
            lastSentTime = now
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and IsAccessible(arg1) and arg1 == "player" then
        local spellName, spellID = nil, nil
        if IsAccessible(arg3) and type(arg3) == "number" then
            -- Modern Retail client (1.60 / 11.0): arg1=unit ("player"), arg2=castGUID, arg3=spellID
            spellID = arg3
            spellName = GetSpellNameCompat(spellID)
        elseif IsAccessible(arg2) and type(arg2) == "string" and (type(arg3) ~= "number") then
            -- Legacy 3.3.5 / Classic signature: arg1=unit ("player"), arg2=spellName, arg3=spellRank, arg4=lineID, arg5=spellID
            spellName = arg2
            if IsAccessible(arg5) and type(arg5) == "number" then
                spellID = arg5
            elseif IsAccessible(arg4) and type(arg4) == "number" then
                spellID = arg4
            end
        elseif IsAccessible(arg2) and type(arg2) == "number" then
            spellID = arg2
            spellName = GetSpellNameCompat(spellID)
        end

        if not spellID and lastSentSpellID and (now - lastSentTime) < 1.5 then
            spellID = lastSentSpellID
        end
        if not spellName and spellID then
            spellName = GetSpellNameCompat(spellID)
        end

        lastCastSpellID = spellID
        lastCastTime = now
        if spellName then lastCastName = spellName end
        if spellID and FP.RecordSpellCastCooldown then
            FP.RecordSpellCastCooldown(spellID)
        end

        if IsJudgementSpell(spellName, spellID) then
            activeSealGraceUntil = 0
            pendingJudgementVerifyAt = now + 0.45
            if sealConsumedByJudgement ~= false then
                combatTrackedSealUntil = 0
                lastConfirmedSealUntil = 0
            end
        elseif IsPaladinSealSpellOrBuff(spellName, spellID) then
            activeSealGraceUntil = now + 3.0
            combatTrackedSealUntil = now + 30.0
        end
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        local s = GetSettings()
        if not s.rotationSingleIconV3 then
            s.rotationSingleIconV3 = true
            s.rotationShowQueue = false
        end
        activeSealGraceUntil = 0
        combatTrackedSealUntil = 0
        lastConfirmedSealUntil = 0
    end

    if event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
        InvalidateKeybindCache()
    end

    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        InvalidateRotationCaches()
        InvalidateKeybindCache()
    end
    pcall(UpdateRotationUI)
end)

local elapsedSum = 0
evFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSum = elapsedSum + (elapsed or 0)
    if elapsedSum >= 0.1 then -- Responsive 10 FPS rotation check
        elapsedSum = 0
        pcall(UpdateRotationUI)
    end
end)

-------------------------------------------------------------------------------
-- Public API & Commands
-------------------------------------------------------------------------------
function FP:ToggleRotationAdvisor(forceState)
    local s = GetSettings()
    if forceState ~= nil then
        s.enableRotationAdvisor = forceState
    else
        s.enableRotationAdvisor = not (s.enableRotationAdvisor ~= false)
    end
    UpdateRotationUI()
    local st = s.enableRotationAdvisor and "|cff00ff00ATTIVATO|r" or "|cffff0000DISATTIVATO|r"
    FP:Print("Consigliere Rotazione Spell: " .. st)
end

function FP:SetRotationAdvisorLocked(isLocked)
    local s = GetSettings()
    s.rotationLocked = isLocked
    UpdateRotationUI()
    local st = s.rotationLocked and "|cff00ff00BLOCCATO|r" or "|cffffd100SBLOCCATO (Trascina per spostare)|r"
    FP:Print("Rotazione Spell: " .. st)
end

function FP:ResetRotationAdvisorPos()
    local s = GetSettings()
    s.rotationPos = nil
    rootFrame.posLoaded = false
    rootFrame:ClearAllPoints()
    rootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    UpdateRotationUI()
    FP:Print("Posizione Rotazione Spell reimpostata al centro.")
end

function FP:RefreshRotationAdvisor()
    UpdateRotationUI()
end

function FP:DumpRotationDebug()
    local ctx = GetPlayerCombatContext()
    local cands = BuildRotation(ctx)
    local now = (GetTime and SafeCall(GetTime)) or 0
    FP:Print(string.format("|cffffd100[Rotation Debug]|r class=%s tab=%s role=%s shield=%s combat=%s speed=%.2f",
        tostring(ctx.classTag), tostring(ctx.tabIdx), tostring(ctx.role), tostring(ctx.isShieldEquipped), tostring(ctx.inCombat), ctx.mainSpeed or 0))
    FP:Print(string.format("  sealRestricted=%s slots=%s/%s live=%s combatTrack=%.1fs grace=%.1fs consumed=%s",
        tostring(lastSealDebug.aurasRestricted), tostring(lastSealDebug.readableSlots), tostring(lastSealDebug.totalSlots),
        tostring(lastSealDebug.matchedLive), math.max(0, combatTrackedSealUntil - now), math.max(0, activeSealGraceUntil - now), tostring(sealConsumedByJudgement)))
    for i = 1, math.min(3, #cands) do
        local c = cands[i]
        FP:Print(string.format("  #%d: %s (%s) ready=%s rem=%.1f dur=%.1f usable=%s noMana=%s range=%s",
            i, tostring(c.name), tostring(c.spellID), tostring(c.isReady), c.remaining or 0, c.duration or 0,
            tostring(c.usable), tostring(c.noMana), tostring(c.inRange)))
    end
end
