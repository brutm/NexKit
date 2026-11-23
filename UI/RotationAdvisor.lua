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
local function IsAccessible(v)
    if v == nil then return false end
    if issecretvalue and issecretvalue(v) then return false end
    return true
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = { pcall(fn, ...) }
    if not results[1] then return nil end
    for i = 2, #results do
        if issecretvalue and issecretvalue(results[i]) then
            results[i] = nil
        end
    end
    return unpack(results, 2)
end

local function SafeBoolean(val, fallback)
    if val == nil then return fallback end
    if issecretvalue and issecretvalue(val) then return fallback end
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
local spellbookLoaded = false

local function RebuildSpellbookCache()
    spellbookByName = {}
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
    local start, dur, enable = 0, 0, 1
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = SafeCall(C_Spell.GetSpellCooldown, spellID)
        if cd and type(cd) == "table" and IsAccessible(cd.startTime) and IsAccessible(cd.duration) then
            start = cd.startTime or 0
            dur = cd.duration or 0
            enable = cd.isEnabled and 1 or 0
        end
    elseif GetSpellCooldown then
        local s, d, en = SafeCall(GetSpellCooldown, spellID)
        if IsAccessible(s) and IsAccessible(d) then
            start = s or 0
            dur = d or 0
            enable = en or 1
        end
    end

    local now = GetTime and GetTime() or 0
    local remaining = 0
    if dur > 1.5 then -- Ignore global cooldown (1.0s - 1.5s)
        remaining = math.max(0, (start + dur) - now)
    end
    local isReady = (remaining <= 0.2)
    return remaining, dur, isReady
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

local function UnitHasAuraNamed(unit, spellNames)
    if not unit or not SafeBoolean(UnitExists(unit), false) or not spellNames then return false end
    if type(spellNames) == "string" then spellNames = { spellNames } end

    for i = 1, 40 do
        local name, spellId = nil, nil
        if UnitBuff then
            local ok, bName, _, _, _, _, _, _, _, _, sid = pcall(UnitBuff, unit, i)
            if ok and IsAccessible(bName) then name = bName end
            if ok and IsAccessible(sid) then spellId = sid end
        end
        if not name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if ok and type(a) == "table" then
                if IsAccessible(a.name) then name = a.name end
                if IsAccessible(a.spellId) then spellId = a.spellId end
            end
        end
        if name then
            local lowName = string.lower(name)
            for _, targetName in ipairs(spellNames) do
                if type(targetName) == "number" and spellId == targetName then
                    return true
                elseif type(targetName) == "string" then
                    local lowTarget = string.lower(targetName)
                    if lowName == lowTarget or lowName:find(lowTarget, 1, true) then
                        return true
                    end
                end
            end
        elseif i > 8 then
            break
        end
    end
    return false
end

local function UnitHasDebuffNamed(unit, spellNames)
    if not unit or not SafeBoolean(UnitExists(unit), false) or not spellNames then return false end
    if type(spellNames) == "string" then spellNames = { spellNames } end

    for i = 1, 40 do
        local name, spellId = nil, nil
        if UnitDebuff then
            local ok, dName, _, _, _, _, _, _, _, _, sid = pcall(UnitDebuff, unit, i)
            if ok and IsAccessible(dName) then name = dName end
            if ok and IsAccessible(sid) then spellId = sid end
        end
        if not name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if ok and type(a) == "table" then
                if IsAccessible(a.name) then name = a.name end
                if IsAccessible(a.spellId) then spellId = a.spellId end
            end
        end
        if name then
            local lowName = string.lower(name)
            for _, targetName in ipairs(spellNames) do
                if type(targetName) == "number" and spellId == targetName then
                    return true
                elseif type(targetName) == "string" then
                    local lowTarget = string.lower(targetName)
                    if lowName == lowTarget or lowName:find(lowTarget, 1, true) then
                        return true
                    end
                end
            end
        elseif i > 8 then
            break
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Action Bar Keybind Finder Helper
-------------------------------------------------------------------------------
local function GetKeybindForSpell(spellID)
    if not spellID then return nil end
    local spellName = GetSpellNameCompat(spellID)
    if not spellName or spellName == "" then return nil end

    for slot = 1, 120 do
        local actionType, id, subType = GetActionInfo(slot)
        local match = false
        if actionType == "spell" then
            if id == spellID then
                match = true
            else
                local name = GetSpellNameCompat(id)
                if name and name == spellName then match = true end
            end
        elseif actionType == "macro" and id then
            local mSpell = GetMacroSpell and GetMacroSpell(id)
            if mSpell and (mSpell == spellID or GetSpellNameCompat(mSpell) == spellName) then
                match = true
            end
        end

        if match then
            local actionName = nil
            if slot <= 12 then
                actionName = "ACTIONBUTTON" .. slot
            elseif slot >= 13 and slot <= 24 then
                actionName = "ACTIONBUTTON" .. (slot - 12)
            elseif slot >= 25 and slot <= 36 then
                actionName = "MULTIACTIONBAR3BUTTON" .. (slot - 24) -- Right Action Bar
            elseif slot >= 37 and slot <= 48 then
                actionName = "MULTIACTIONBAR4BUTTON" .. (slot - 36) -- Right Action Bar 2
            elseif slot >= 49 and slot <= 60 then
                actionName = "MULTIACTIONBAR2BUTTON" .. (slot - 48) -- Bottom Right Action Bar
            elseif slot >= 61 and slot <= 72 then
                actionName = "MULTIACTIONBAR1BUTTON" .. (slot - 60) -- Bottom Left Action Bar
            end

            if actionName then
                local key = GetBindingKey(actionName)
                if key and key ~= "" then
                    key = key:gsub("CTRL%-", "C-"):gsub("ALT%-", "A-"):gsub("SHIFT%-", "S-"):gsub("BUTTON", "M")
                    return key
                end
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Rotation Engine: Spec & Context Detectors
-------------------------------------------------------------------------------
local function GetPlayerCombatContext()
    local classTag = select(2, UnitClass("player")) or "WARRIOR"
    local rawLvl = SafeCall(UnitLevel, "player")
    local level = (IsAccessible(rawLvl) and type(rawLvl) == "number" and rawLvl) or 1
    local tabIdx = 1
    local tabPts = 0

    if type(GetNumTalentTabs) == "function" and type(GetTalentTabInfo) == "function" then
        local rawNumTabs = SafeCall(GetNumTalentTabs)
        local numTabs = (IsAccessible(rawNumTabs) and tonumber(rawNumTabs)) or 0
        for t = 1, numTabs do
            local _, _, pointsSpent = SafeCall(GetTalentTabInfo, t)
            if IsAccessible(pointsSpent) and type(pointsSpent) == "number" and pointsSpent > tabPts then
                tabPts = pointsSpent
                tabIdx = t
            end
        end
    end

    local isShieldEquipped = false
    local offhandID = GetInventoryItemID and SafeCall(GetInventoryItemID, "player", 17)
    if offhandID then
        if GetItemInfoInstant then
            local _, _, _, itemEquipLoc, _, classID, subclassID = SafeCall(GetItemInfoInstant, offhandID)
            if itemEquipLoc == "INVTYPE_SHIELD" or (classID == 4 and subclassID == 6) then
                isShieldEquipped = true
            end
        end
        if not isShieldEquipped and C_Item and C_Item.GetItemInventoryTypeByID then
            local invType = SafeCall(C_Item.GetItemInventoryTypeByID, offhandID)
            if invType == 14 or (Enum and Enum.InventoryType and invType == Enum.InventoryType.IndexShieldType) then
                isShieldEquipped = true
            end
        end
        if not isShieldEquipped and GetItemInfo then
            local _, _, _, _, _, _, _, _, itemEquipLoc = SafeCall(GetItemInfo, offhandID)
            if itemEquipLoc == "INVTYPE_SHIELD" then
                isShieldEquipped = true
            end
        end
        if not isShieldEquipped and GetInventoryItemLink then
            local link = SafeCall(GetInventoryItemLink, "player", 17)
            if link and (link:find("INVTYPE_SHIELD") or link:find("Shield") or link:find("Scudo")) then
                isShieldEquipped = true
            end
        end
    end

    local inCombat = SafeBoolean(InCombatLockdown and InCombatLockdown(), false)
    local hasTarget = SafeBoolean(UnitExists("target"), false)
    local targetHostile = hasTarget and SafeBoolean(UnitCanAttack("player", "target"), false)
    local targetDead = hasTarget and (SafeBoolean(UnitIsDead("target"), false) or SafeBoolean(UnitIsGhost("target"), false))

    local targetHp = 100
    if hasTarget and not targetDead and UnitHealth and UnitHealthMax then
        local hp = SafeCall(UnitHealth, "target") or 1
        local maxHp = SafeCall(UnitHealthMax, "target") or 1
        if IsAccessible(hp) and IsAccessible(maxHp) and maxHp > 0 then
            targetHp = math.floor((hp / maxHp) * 100)
        end
    end

    local powerType = UnitPowerType("player") or 0
    local rawPower = SafeCall(UnitPower, "player") or 0
    local power = (IsAccessible(rawPower) and type(rawPower) == "number" and rawPower) or 0
    local comboPoints = (GetComboPoints and SafeCall(GetComboPoints, "player", "target")) or 0

    return {
        classTag = classTag,
        level = level,
        tabIdx = tabIdx,
        tabPts = tabPts,
        isShieldEquipped = isShieldEquipped,
        inCombat = inCombat,
        hasTarget = hasTarget,
        targetHostile = targetHostile,
        targetDead = targetDead,
        targetHp = targetHp,
        powerType = powerType,
        power = power,
        comboPoints = comboPoints,
    }
end

-------------------------------------------------------------------------------
-- Class Rotation Rules
-------------------------------------------------------------------------------
local function FindBestSpellInRanks(rankList, aliases)
    if not spellbookLoaded then
        RebuildSpellbookCache()
    end
    if type(rankList) ~= "table" then rankList = {} end

    -- 1. Try direct rank spell IDs
    for i = #rankList, 1, -1 do
        local sid = rankList[i]
        if IsSpellKnownCompat(sid) then
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
                return castID
            end
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Real-time Cast & Sequence Tracking
-------------------------------------------------------------------------------
local lastCastSpellID = nil
local lastCastTime = 0
local lastCastName = nil
local activeSealName = nil
local activeSealTime = 0

local PALADIN_SEAL_SPELLS = {
    [21084] = true, [20287] = true, [20288] = true, [20289] = true, [20290] = true,
    [20291] = true, [20292] = true, [20293] = true, [27155] = true, -- Seal of Righteousness
    [20375] = true, [20915] = true, [20918] = true, [20919] = true, [20920] = true, [27170] = true, -- Seal of Command
    [20165] = true, [20356] = true, [20357] = true, [27166] = true, -- Seal of Wisdom
    [20305] = true, [20306] = true, [20307] = true, [20308] = true, [20162] = true, [20309] = true, [27158] = true, -- Seal of the Crusader
    [20166] = true, [20332] = true, [20333] = true, [20334] = true, [27160] = true, -- Seal of Light
    [20164] = true, [10324] = true, [10325] = true, [10326] = true, -- Seal of Justice
}

local function IsPaladinSealActive()
    -- 1. Check real-time cast memory (lasts 30s)
    local now = GetTime and GetTime() or 0
    if activeSealName and (now - activeSealTime < 30) then
        return true
    end

    -- 2. Check player buffs via UnitBuff / C_UnitAuras
    for i = 1, 40 do
        local name, icon, sid = nil, nil, nil
        if UnitBuff then
            local ok, bName, _, bIcon, _, _, _, _, _, _, bSid = pcall(UnitBuff, "player", i)
            if ok and IsAccessible(bName) then name = bName end
            if ok and IsAccessible(bSid) then sid = bSid end
            if ok and IsAccessible(bIcon) then icon = bIcon end
        end
        if not name and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if ok and type(a) == "table" then
                if IsAccessible(a.name) then name = a.name end
                if IsAccessible(a.spellId) then sid = a.spellId end
                if IsAccessible(a.icon) then icon = a.icon end
            end
        end

        if name then
            local low = string.lower(name)
            if low:find("seal") or low:find("sigillo") or low:find("rettitudine") or low:find("righteous")
                or low:find("crusader") or low:find("crociato") or low:find("command") or low:find("comando")
                or low:find("wisdom") or low:find("saggezza") or low:find("justice") or low:find("giustizia")
                or low:find("light") or low:find("luce") then
                return true
            end
        end
        if sid and PALADIN_SEAL_SPELLS and PALADIN_SEAL_SPELLS[sid] then
            return true
        end
        if icon and type(icon) == "string" then
            local lowIcon = string.lower(icon)
            if lowIcon:find("thunderbolt") or lowIcon:find("righteousnessaura") or lowIcon:find("sealof") then
                return true
            end
        end
        if not name and i > 8 then
            break
        end
    end
    return false
end

local function BuildRotation(ctx)
    local list = {}
    local cls = ctx.classTag

    local function AddCandidate(spellID, badge, reason)
        if not spellID then return end
        local remaining, dur, isReady = GetSpellCooldownCompat(spellID)
        local usable, noMana = IsSpellUsableCompat(spellID)
        local inRange = IsSpellInRangeCompat(spellID, "target")
        local keybind = GetKeybindForSpell(spellID)
        local name = GetSpellNameCompat(spellID) or "Spell"
        local icon = GetSpellTextureCompat(spellID) or "Interface\\Icons\\INV_Misc_QuestionMark"

        -- Check if this spell was just cast in the last 1.8 seconds (skip immediately to advance sequence)
        local now = GetTime and GetTime() or 0
        local wasJustCast = false
        if lastCastSpellID and lastCastSpellID == spellID then
            if (now - lastCastTime) < 1.8 then
                wasJustCast = true
            end
        elseif lastCastName and name and (string.lower(lastCastName) == string.lower(name)) then
            if (now - lastCastTime) < 1.8 then
                wasJustCast = true
            end
        end

        list[#list + 1] = {
            spellID     = spellID,
            name        = name,
            icon        = icon,
            isReady     = isReady and not wasJustCast,
            remaining   = wasJustCast and math.max(remaining, 1.5) or remaining,
            duration    = dur,
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

    ---------------------------------------------------------------------------
    -- 1. PALADIN ROTATION
    ---------------------------------------------------------------------------
    if cls == "PALADIN" then
        local isProt = (ctx.tabIdx == 2) or (ctx.isShieldEquipped == true)
        local isRet  = (ctx.tabIdx == 3)
        local isHoly = (ctx.tabIdx == 1 and not isProt)

        -- Seal spell candidates
        local sealRighteous = FindBestSpellInRanks({ 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293, 27155 }, { "Seal of Righteousness", "Sigillo dell'Integrità", "Sigillo di Rettitudine" })
        local sealCommand   = FindBestSpellInRanks({ 20375, 20915, 20918, 20919, 20920, 27170 }, { "Seal of Command", "Sigillo del Comando" })
        local sealWisdom    = FindBestSpellInRanks({ 20165, 20356, 20357, 27166 }, { "Seal of Wisdom", "Sigillo della Saggezza" })
        local sealCrusader  = FindBestSpellInRanks({ 20305, 20306, 20307, 20308, 20162, 20309, 27158 }, { "Seal of the Crusader", "Sigillo del Crociato" })

        local activeSeal = IsPaladinSealActive()

        local holyShield = FindBestSpellInRanks({ 20925, 20927, 20928, 27179 }, { "Holy Shield", "Scudo Sacro" })
        local judgement  = FindBestSpellInRanks({ 20271 }, { "Judgement", "Giudizio" })
        local consecrate = FindBestSpellInRanks({ 26573, 20116, 20922, 20923, 20924, 27173 }, { "Consecration", "Consacrazione" })
        local hammerOfWrath = FindBestSpellInRanks({ 24275, 24274, 24239, 27180 }, { "Hammer of Wrath", "Martello dell'Ira" })
        local exorcism   = FindBestSpellInRanks({ 879, 5614, 5615, 10312, 10313, 10314, 27138 }, { "Exorcism", "Esorcismo" })
        local hammerOfJustice = FindBestSpellInRanks({ 853, 5588, 5589, 10308 }, { "Hammer of Justice", "Martello della Giustizia" })
        local avengersShield = FindBestSpellInRanks({ 31589, 32699, 32700 }, { "Avenger's Shield", "Scudo del Vendicatore" })

        -- 0. Seal Activation (If missing, always top priority)
        if not activeSeal then
            local preferredSeal = (isRet and sealCommand) or (isHoly and sealWisdom) or sealRighteous or sealCrusader
            if preferredSeal then
                AddCandidate(preferredSeal, "SIGILLO", "Attiva il Sigillo per il combattimento")
            end
        end

        if isProt then
            -- Protection Paladin Priority:
            -- 1. Holy Shield (keep up 30% block + Holy reflection)
            if holyShield and ctx.isShieldEquipped and not UnitHasAuraNamed("player", { "Holy Shield", "Scudo Sacro", 20925, 20927, 20928, 27179 }) then
                AddCandidate(holyShield, "DIFESA", "Holy Shield: Mantieni attivo il 30% di parata & danno sacro")
            end
            -- 2. Avenger's Shield (pull / ranged silence / burst)
            if avengersShield and ctx.hasTarget and ctx.targetHostile and not ctx.targetDead then
                AddCandidate(avengersShield, "PULL/BURST", "Scudo del Vendicatore: Danno sacro a rimbalzo")
            end
            -- 3. Hammer of Wrath (Execute < 20% HP)
            if hammerOfWrath and ctx.targetHp <= 20 and ctx.hasTarget and not ctx.targetDead then
                AddCandidate(hammerOfWrath, "ESECUZIONE", "Hammer of Wrath: Bersaglio < 20% salute")
            end
            -- 4. Judgement (if active seal - shown live with countdown timer even if waiting)
            if judgement and activeSeal then
                AddCandidate(judgement, "GIUDIZIO", "Judgement: Scarica il sigillo sul bersaglio")
            end
            -- 5. Consecration (AoE / Tank Threat)
            if consecrate and ctx.power >= 135 and (ctx.inCombat or (ctx.hasTarget and ctx.targetHostile and not ctx.targetDead)) then
                AddCandidate(consecrate, "MINACCIA", "Consacrazione: Minaccia ad area sul terreno")
            end
            -- 6. Hammer of Justice (Stun / Control)
            if hammerOfJustice and ctx.hasTarget and ctx.targetHostile and not ctx.targetDead then
                AddCandidate(hammerOfJustice, "STUN", "Martello della Giustizia: Stordisce il bersaglio")
            end
            -- 7. Exorcism if Demon/Undead
            local cType = UnitCreatureType("target")
            if exorcism and (cType == "Undead" or cType == "Non Morto" or cType == "Demon" or cType == "Demone") then
                AddCandidate(exorcism, "BURST", "Esorcismo: Danno sacro istantaneo contro Non Morti e Demoni")
            end
        elseif isRet then
            -- Retribution Paladin Priority:
            if hammerOfWrath and ctx.targetHp <= 20 and ctx.hasTarget and not ctx.targetDead then
                AddCandidate(hammerOfWrath, "ESECUZIONE", "Hammer of Wrath: Esecuzione < 20%")
            end
            local bestSeal = sealCommand or sealRighteous
            if bestSeal and not activeSeal then
                AddCandidate(bestSeal, "SIGILLO", "Sigillo del Comando: Danno burst su colpo")
            end
            if judgement and activeSeal then
                AddCandidate(judgement, "GIUDIZIO", "Giudizio sul bersaglio")
            end
            if consecrate and ctx.power >= 250 and (ctx.inCombat or (ctx.hasTarget and ctx.targetHostile and not ctx.targetDead)) then
                AddCandidate(consecrate, "AOE", "Consacrazione")
            end
            if hammerOfJustice and ctx.hasTarget and ctx.targetHostile and not ctx.targetDead then
                AddCandidate(hammerOfJustice, "STUN", "Martello della Giustizia")
            end
        else
            -- Holy / General Paladin:
            local holyShock = FindBestSpellInRanks({ 20473, 20929, 20930, 27174 })
            if holyShock and ctx.hasTarget and not ctx.targetDead then AddCandidate(holyShock, "SHOCK", "Holy Shock istantaneo") end
            if judgement and activeSeal then AddCandidate(judgement, "GIUDIZIO", "Giudizio") end
            if not activeSeal and (sealWisdom or sealRighteous) then
                AddCandidate(sealWisdom or sealRighteous, "SIGILLO", "Sigillo per mana / danno")
            end
        end

    ---------------------------------------------------------------------------
    -- 2. WARRIOR ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "WARRIOR" then
        local isProt = (ctx.tabIdx == 3) or ctx.isShieldEquipped
        local execute = FindBestSpellInRanks({ 5308, 20658, 20660, 20661, 20662, 25236 })
        local shieldSlam = FindBestSpellInRanks({ 23922, 23923, 23924, 23925, 25258 })
        local revenge = FindBestSpellInRanks({ 6572, 6574, 7379, 11600, 11601, 25288 })
        local shieldBlock = FindBestSpellInRanks({ 2565 })
        local sunder = FindBestSpellInRanks({ 7386, 7405, 8380, 11596, 11597, 25225 })
        local mortalStrike = FindBestSpellInRanks({ 12294, 21551, 21552, 21553, 25248 })
        local bloodthirst = FindBestSpellInRanks({ 23881, 23892, 23893, 23894, 25251 })
        local overpower = FindBestSpellInRanks({ 7384, 7887, 11584, 11585 })
        local rend = FindBestSpellInRanks({ 772, 6546, 6547, 6548, 11572, 11573, 11574, 25208 })
        local heroicStrike = FindBestSpellInRanks({ 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286 })

        if ctx.targetHp <= 20 and execute and ctx.power >= 15 then
            AddCandidate(execute, "EXECUTE", "Execute: Bersaglio sotto al 20% salute!")
        end

        if isProt then
            if shieldBlock and ctx.power >= 10 and not UnitHasAuraNamed("player", { "Shield Block", "Blocco con lo Scudo" }) then
                AddCandidate(shieldBlock, "MITIGATION", "Shield Block: Attiva il blocco garantito")
            end
            if shieldSlam and ctx.power >= 20 and ctx.isShieldEquipped then
                AddCandidate(shieldSlam, "THREAT", "Shield Slam: Massima generazione di minaccia")
            end
            if revenge and ctx.power >= 5 then
                AddCandidate(revenge, "PROC", "Revenge: Danno economico e stun/minaccia")
            end
            if sunder and ctx.power >= 12 then
                AddCandidate(sunder, "DEBUFF", "Sunder Armor: Riduci l'armatura e accumula minaccia")
            end
        else
            if mortalStrike and ctx.power >= 30 then
                AddCandidate(mortalStrike, "BURST", "Mortal Strike su ricarica")
            end
            if bloodthirst and ctx.power >= 30 then
                AddCandidate(bloodthirst, "BURST", "Bloodthirst su ricarica")
            end
            if rend and ctx.power >= 10 and not UnitHasDebuffNamed("target", { "Rend", "Lacerazione" }) then
                AddCandidate(rend, "DOT", "Rend: Applica sanguinamento")
            end
        end

        if ctx.power >= 45 and heroicStrike then
            AddCandidate(heroicStrike, "DUMP", "Heroic Strike: Scarica l'eccesso di rabbia")
        end

    ---------------------------------------------------------------------------
    -- 3. MAGE ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "MAGE" then
        local frostbolt = FindBestSpellInRanks({ 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 })
        local fireball  = FindBestSpellInRanks({ 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 })
        local fireBlast = FindBestSpellInRanks({ 2136, 2137, 2138, 8412, 8413, 10197, 10199, 10200 })
        local coneOfCold = FindBestSpellInRanks({ 120, 8492, 10159, 10160, 10161, 25311 })

        if ctx.targetHp <= 15 and fireBlast then
            AddCandidate(fireBlast, "FINISHER", "Fire Blast: Colpo istantaneo di grazia")
        end
        if ctx.tabIdx == 2 and fireball then
            AddCandidate(fireball, "NUKE", "Fireball: Danno elevato")
        elseif frostbolt then
            AddCandidate(frostbolt, "NUKE", "Frostbolt: Rallenta e infligge danno")
        end
        if fireBlast then
            AddCandidate(fireBlast, "INSTANT", "Fire Blast istantaneo")
        end

    ---------------------------------------------------------------------------
    -- 4. ROGUE ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "ROGUE" then
        local sliceAndDice = FindBestSpellInRanks({ 5171, 6774 })
        local eviscerate   = FindBestSpellInRanks({ 2098, 6747, 8623, 8624, 11299, 11300, 11301, 26865 })
        local sinister     = FindBestSpellInRanks({ 1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294, 26861 })
        local riposte      = FindBestSpellInRanks({ 14251 })

        local hasSnD = UnitHasAuraNamed("player", { "Slice and Dice", "Affettamento" })

        if riposte and ctx.power >= 10 then
            AddCandidate(riposte, "PROC", "Riposte: Disarma il nemico")
        end
        if ctx.comboPoints >= 1 and not hasSnD and sliceAndDice and ctx.power >= 25 then
            AddCandidate(sliceAndDice, "BUFF", "Slice and Dice: +30% velocità d'attacco")
        end
        if (ctx.comboPoints >= 4 or (ctx.targetHp <= 20 and ctx.comboPoints >= 2)) and eviscerate and ctx.power >= 35 then
            AddCandidate(eviscerate, "FINISHER", "Eviscerate: Consuma i punti combo")
        end
        if sinister and ctx.power >= 40 then
            AddCandidate(sinister, "BUILDER", "Sinister Strike: Genera punti combo")
        end

    ---------------------------------------------------------------------------
    -- 5. WARLOCK ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "WARLOCK" then
        local agony      = FindBestSpellInRanks({ 980, 1014, 6217, 11711, 11712, 11713, 27218 })
        local corruption = FindBestSpellInRanks({ 172, 6222, 6223, 7648, 11671, 11672, 25311 })
        local immolate   = FindBestSpellInRanks({ 348, 707, 1094, 2941, 11665, 11667, 11668, 27215 })
        local shadowbolt = FindBestSpellInRanks({ 686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307 })
        local drainSoul  = FindBestSpellInRanks({ 1120, 8288, 8289, 11675 })

        if ctx.targetHp <= 20 and drainSoul then
            AddCandidate(drainSoul, "SHARD", "Drain Soul: Frammento d'anima sotto il 20%")
        end
        if agony and not UnitHasDebuffNamed("target", { "Curse of Agony", "Maledizione dell'Agonia" }) then
            AddCandidate(agony, "DOT", "Curse of Agony: Danno prolungato")
        end
        if corruption and not UnitHasDebuffNamed("target", { "Corruption", "Corruzione" }) then
            AddCandidate(corruption, "DOT", "Corruption: Danno continuo d'Ombra")
        end
        if immolate and not UnitHasDebuffNamed("target", { "Immolate", "Immolazione" }) then
            AddCandidate(immolate, "DOT", "Immolate: Danno da fuoco")
        end
        if shadowbolt then
            AddCandidate(shadowbolt, "NUKE", "Shadow Bolt: Danno d'ombra principale")
        end

    ---------------------------------------------------------------------------
    -- 6. PRIEST ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "PRIEST" then
        local swp = FindBestSpellInRanks({ 589, 594, 970, 992, 2767, 10892, 10893, 10894, 25368 })
        local mindBlast = FindBestSpellInRanks({ 8092, 8102, 8103, 8104, 10945, 10946, 10947, 25375 })
        local mindFlay  = FindBestSpellInRanks({ 15407, 17311, 17312, 17313, 17314, 18807 })
        local smite     = FindBestSpellInRanks({ 585, 591, 598, 984, 1004, 6060, 10933, 10934 })

        if swp and not UnitHasDebuffNamed("target", { "Shadow Word: Pain", "Parola d'Ombra: Dolore" }) then
            AddCandidate(swp, "DOT", "Shadow Word: Pain")
        end
        if mindBlast then AddCandidate(mindBlast, "BURST", "Mind Blast") end
        if mindFlay then AddCandidate(mindFlay, "CHANNEL", "Mind Flay") elseif smite then AddCandidate(smite, "NUKE", "Smite") end

    ---------------------------------------------------------------------------
    -- 7. HUNTER ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "HUNTER" then
        local mark   = FindBestSpellInRanks({ 1130, 14323, 14324, 14325 })
        local sting  = FindBestSpellInRanks({ 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295 })
        local arcane = FindBestSpellInRanks({ 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287 })
        local aimed  = FindBestSpellInRanks({ 19434, 20900, 20901, 20902, 20903, 20904, 27065 })
        local multi  = FindBestSpellInRanks({ 2643, 14288, 14289, 14290, 25294 })

        if mark and not UnitHasDebuffNamed("target", { "Hunter's Mark", "Marchio del Cacciatore" }) then
            AddCandidate(mark, "MARK", "Hunter's Mark: +Ranged Attack Power")
        end
        if sting and not UnitHasDebuffNamed("target", { "Serpent Sting", "Morso del Serpente" }) then
            AddCandidate(sting, "DOT", "Serpent Sting: Veleno continuativo")
        end
        if aimed then AddCandidate(aimed, "BURST", "Aimed Shot") end
        if multi then AddCandidate(multi, "BURST", "Multi-Shot") end
        if arcane then AddCandidate(arcane, "INSTANT", "Arcane Shot") end

    ---------------------------------------------------------------------------
    -- 8. DRUID ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "DRUID" then
        local faerieFire = FindBestSpellInRanks({ 770, 778, 9749, 9907, 16857, 17390, 17391, 17392 })
        local moonfire   = FindBestSpellInRanks({ 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 })
        local wrath      = FindBestSpellInRanks({ 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912 })
        local maul       = FindBestSpellInRanks({ 6807, 6808, 6809, 6810, 779, 780, 9745, 9880, 9881 })
        local claw       = FindBestSpellInRanks({ 1082, 3029, 5201, 9849, 9850 })
        local rip        = FindBestSpellInRanks({ 1079, 9492, 9493, 9752, 9894, 9896 })

        if faerieFire and not UnitHasDebuffNamed("target", { "Faerie Fire", "Fuoco Fatato" }) then
            AddCandidate(faerieFire, "DEBUFF", "Faerie Fire: Riduci armatura")
        end
        if ctx.powerType == 1 and maul and ctx.power >= 15 then -- Bear
            AddCandidate(maul, "THREAT", "Maul: Attacco del Custode")
        elseif ctx.powerType == 3 then -- Cat
            if ctx.comboPoints >= 4 and rip and ctx.power >= 30 then
                AddCandidate(rip, "FINISHER", "Rip: Sanguinamento potente")
            elseif claw and ctx.power >= 40 then
                AddCandidate(claw, "BUILDER", "Claw: Accumula combo")
            end
        else
            if moonfire and not UnitHasDebuffNamed("target", { "Moonfire", "Fuoco Lunare" }) then
                AddCandidate(moonfire, "DOT", "Moonfire")
            end
            if wrath then AddCandidate(wrath, "NUKE", "Wrath") end
        end

    ---------------------------------------------------------------------------
    -- 9. SHAMAN ROTATION
    ---------------------------------------------------------------------------
    elseif cls == "SHAMAN" then
        local flameShock = FindBestSpellInRanks({ 8050, 8052, 8053, 10447, 10448, 29228 })
        local earthShock = FindBestSpellInRanks({ 8042, 8044, 8045, 8046, 10412, 10413, 10414 })
        local lightning  = FindBestSpellInRanks({ 403, 529, 548, 915, 943, 6041, 10391, 10392 })
        local stormstrike = FindBestSpellInRanks({ 17364 })

        if stormstrike then AddCandidate(stormstrike, "BURST", "Stormstrike: Danno doppio con armi") end
        if flameShock and not UnitHasDebuffNamed("target", { "Flame Shock", "Folgore del Fuoco" }) then
            AddCandidate(flameShock, "DOT", "Flame Shock")
        end
        if earthShock then AddCandidate(earthShock, "INTERRUPT", "Earth Shock") end
        if lightning then AddCandidate(lightning, "NUKE", "Lightning Bolt") end
    end

    -- Sort candidates:
    -- 1. Spells that are ready & usable (isReady and usable and not noMana) in order of priority (order)
    -- 2. Spells that are ready but waiting on mana or range in order of priority
    -- 3. Spells on cooldown, ordered by shortest remaining cooldown so the user knows what's coming
    table.sort(list, function(a, b)
        local aReady = a.isReady and a.usable and not a.noMana
        local bReady = b.isReady and b.usable and not b.noMana

        if aReady and not bReady then return true end
        if not aReady and bReady then return false end

        if aReady and bReady then
            return a.order < b.order
        end

        if a.isReady and not b.isReady then return true end
        if not a.isReady and b.isReady then return false end

        if a.remaining ~= b.remaining then
            return a.remaining < b.remaining
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
if mainCooldown.SetSwipeColor then mainCooldown:SetSwipeColor(0, 0, 0, 0.75) end
mainSlot.cooldown = mainCooldown

local mainKeybind = mainSlot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
mainKeybind:SetPoint("TOPRIGHT", mainSlot, "TOPRIGHT", -3, -3)
mainKeybind:SetTextColor(1.0, 1.0, 1.0, 1.0)
mainSlot.keybind = mainKeybind

local mainTimerText = mainSlot:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
mainTimerText:SetPoint("CENTER", mainSlot, "CENTER", 0, 0)
local tFont = mainTimerText:GetFont()
if tFont then
    mainTimerText:SetFont(tFont, 16, "OUTLINE")
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

local queueKeybind = queueSlot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
queueKeybind:SetPoint("TOPRIGHT", queueSlot, "TOPRIGHT", -2, -2)
queueKeybind:SetTextColor(0.9, 0.9, 0.9, 1.0)
queueSlot.keybind = queueKeybind

-------------------------------------------------------------------------------
-- Update Loop
-------------------------------------------------------------------------------
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

    local scale = GetRotationScale()
    rootFrame:SetScale(scale)
    rootFrame:SetAlpha(GetRotationAlpha())

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

    rootFrame:Show()

    local candidates = BuildRotation(ctx)
    local first = candidates[1]
    local second = candidates[2]

    if first then
        mainIcon:SetTexture(first.icon)
        mainBadge:SetText(first.badge or "")

        if first.keybind and first.keybind ~= "" then
            mainKeybind:SetText(first.keybind)
            mainKeybind:Show()
        else
            mainKeybind:Hide()
        end

        -- Cooldown indicator
        if not first.isReady and first.remaining > 0 then
            local dur = first.duration or 10
            local start = (GetTime() + first.remaining) - dur
            mainCooldown:SetCooldown(start, dur)
            mainIcon:SetVertexColor(0.55, 0.55, 0.55)
            mainSlot:SetBackdropBorderColor(0.85, 0.5, 0.2, 0.95)

            if first.remaining >= 60 then
                mainTimerText:SetText(string.format("%dm", math.ceil(first.remaining / 60)))
            elseif first.remaining >= 10 then
                mainTimerText:SetText(string.format("%ds", math.ceil(first.remaining)))
            elseif first.remaining > 0.3 then
                mainTimerText:SetText(string.format("%.1fs", first.remaining))
            else
                mainTimerText:SetText("")
            end
            mainTimerText:Show()
        else
            mainCooldown:Clear()
            mainTimerText:SetText("")
            mainTimerText:Hide()
            -- Out of range check
            if first.inRange == 0 then
                mainIcon:SetVertexColor(1.0, 0.4, 0.4) -- Red tint if out of range
                mainSlot:SetBackdropBorderColor(1.0, 0.25, 0.25, 1.0)
            elseif first.noMana then
                mainIcon:SetVertexColor(0.4, 0.6, 1.0) -- Blue tint if no resource
                mainSlot:SetBackdropBorderColor(0.3, 0.6, 1.0, 0.95)
            else
                mainIcon:SetVertexColor(1.0, 1.0, 1.0)
                mainSlot:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            end
        end
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
    if IsQueueVisible() and second then
        mainSlot:ClearAllPoints()
        mainSlot:SetPoint("LEFT", rootFrame, "LEFT", 4, 4)
        queueIcon:SetTexture(second.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        if second.keybind and second.keybind ~= "" then
            queueKeybind:SetText(second.keybind)
            queueKeybind:Show()
        else
            queueKeybind:Hide()
        end
        queueSlot:Show()
        rootFrame:SetWidth(96)
    else
        mainSlot:ClearAllPoints()
        mainSlot:SetPoint("CENTER", rootFrame, "CENTER", 0, 4)
        queueSlot:Hide()
        rootFrame:SetWidth(56)
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
SafeRegisterEvent(evFrame, "UNIT_SPELLCAST_SUCCEEDED")
SafeRegisterEvent(evFrame, "UNIT_SPELLCAST_START")
SafeRegisterEvent(evFrame, "UNIT_AURA")

evFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5)
    if (event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_START") and arg1 == "player" then
        local spellName, spellID = nil, nil
        if type(arg2) == "string" and not tonumber(arg2) then
            -- Legacy 3.3.5 / Classic signature: arg1=unit ("player"), arg2=spellName, arg3=spellRank, arg4=lineID, arg5=spellID
            spellName = arg2
            spellID = arg5
        else
            -- Retail: arg1=unit ("player"), arg2=castGUID, arg3=spellID
            spellID = arg3
            spellName = GetSpellNameCompat(spellID)
        end

        lastCastSpellID = spellID
        lastCastTime = GetTime and GetTime() or 0
        if spellName then
            lastCastName = spellName
            local low = string.lower(spellName)
            if (spellID and PALADIN_SEAL_SPELLS and PALADIN_SEAL_SPELLS[spellID])
                or low:find("seal") or low:find("sigillo") or low:find("rettitudine") or low:find("righteous")
                or low:find("crusader") or low:find("crociato") or low:find("command") or low:find("comando")
                or low:find("wisdom") or low:find("saggezza") or low:find("justice") or low:find("giustizia")
                or low:find("light") or low:find("luce") then
                activeSealName = spellName
                activeSealTime = lastCastTime
            elseif low:find("judgement") or low:find("giudizio") then
                activeSealName = nil
                activeSealTime = 0
            end
        end
    end

    if event == "PLAYER_LOGIN" then
        local s = GetSettings()
        if not s.rotationSingleIconMigrated then
            s.rotationSingleIconMigrated = true
            s.rotationShowQueue = false
        end
    end

    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LOGIN" then
        spellbookLoaded = false
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
