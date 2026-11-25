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
    return (v and v ~= "" and v ~= "@project-version@") and v or "0.3.6"
end

FP.VERSION      = GetAddonVersion()
FP.LOGO_TEXTURE = "Interface\\AddOns\\" .. (addonName or "NexusKit") .. "\\Media\\Logo.tga"

------------------------------------------------------------------------
-- Shared Safe WoW API & Secret-Value Compatibility Layer (Classic / 16001 / Retail)
------------------------------------------------------------------------
local function IsSecret(v)
    return (issecretvalue and issecretvalue(v)) or (issecret and issecret(v)) or false
end

local function IsAccessible(v)
    return v ~= nil and not IsSecret(v)
end

local function IsSafeNum(v)
    return type(v) == "number" and not IsSecret(v) and v == v and v > -1e12 and v < 1e12
end

local function IsSafeStr(v)
    return type(v) == "string" and not IsSecret(v) and v ~= ""
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

local function SafeNumber(val, fallback)
    if val == nil or IsSecret(val) then return fallback end
    local ok, res = pcall(function()
        if type(val) == "number" and val == val then return val end
        return fallback
    end)
    if ok then return res end
    return fallback
end

local function SafeRegisterEvent(f, eventName)
    if f and f.RegisterEvent then
        pcall(f.RegisterEvent, f, eventName)
    end
end

local function SafeRegisterUnitEvent(f, eventName, unit)
    if f and f.RegisterUnitEvent then
        local ok = pcall(f.RegisterUnitEvent, f, eventName, unit)
        if ok then return end
    end
    SafeRegisterEvent(f, eventName)
end

local function GetSpellNameCompat(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local name = SafeCall(C_Spell.GetSpellName, spellID)
        if IsSafeStr(name) then return name end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = SafeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and IsSafeStr(info.name) then return info.name end
    end
    if GetSpellInfo then
        local name = SafeCall(GetSpellInfo, spellID)
        if IsSafeStr(name) then return name end
    end
    return nil
end

local function GetSpellTextureCompat(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = SafeCall(C_Spell.GetSpellTexture, spellID)
        if IsAccessible(tex) then return tex end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = SafeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and IsAccessible(info.iconID) and info.iconID then
            return info.iconID
        end
    end
    if GetSpellTexture then
        local tex = SafeCall(GetSpellTexture, spellID)
        if IsAccessible(tex) then return tex end
    end
    if GetSpellInfo then
        local _, _, tex = SafeCall(GetSpellInfo, spellID)
        if IsAccessible(tex) then return tex end
    end
    return nil
end

local function IsSpellKnownCompat(spellID)
    if not spellID then return false end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local known = SafeCall(C_SpellBook.IsSpellKnown, spellID)
        if IsAccessible(known) and known then return true end
        if Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player then
            known = SafeCall(C_SpellBook.IsSpellKnown, spellID, Enum.SpellBookSpellBank.Player)
            if IsAccessible(known) and known then return true end
        end
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

local function IsSpellPassiveCompat(spellID)
    if not spellID then return false end
    if C_Spell and C_Spell.IsSpellPassive then
        local p = SafeCall(C_Spell.IsSpellPassive, spellID)
        if IsAccessible(p) then return p == true end
    end
    if IsPassiveSpell then
        local p = SafeCall(IsPassiveSpell, spellID)
        if IsAccessible(p) then return p == true end
    end
    return false
end

local function IsSpellUsableCompat(spellID)
    if not spellID then return true, false end
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

local function GetSpellCooldownCompat(spellID)
    if not spellID then return 0, 0, true end
    local start, dur = 0, 0
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = SafeCall(C_Spell.GetSpellCooldown, spellID)
        if type(cd) == "table" and IsSafeNum(cd.startTime) and IsSafeNum(cd.duration) then
            start = cd.startTime or 0
            dur = cd.duration or 0
        end
    elseif GetSpellCooldown then
        local s, d = SafeCall(GetSpellCooldown, spellID)
        if IsSafeNum(s) and IsSafeNum(d) then
            start = s or 0
            dur = d or 0
        end
    end
    local now = (GetTime and SafeCall(GetTime)) or 0
    local remaining = 0
    if dur > 1.5 and IsSafeNum(now) then
        remaining = math.max(0, (start + dur) - now)
    end
    return remaining, dur, (remaining <= 0.2)
end

local function ReadTalentTabCompat(tabIdx, isInspect)
    if type(GetTalentTabInfo) ~= "function" then return nil, 0 end
    local a, b, c, _, e = SafeCall(GetTalentTabInfo, tabIdx, isInspect)
    if type(a) == "table" then
        local tName = IsSafeStr(a.name) and a.name or nil
        local tPts = SafeNumber(a.pointsSpent or a.numPointsSpent, 0)
        return tName, tPts
    elseif IsSafeNum(a) and IsSafeStr(b) then
        return b, SafeNumber(e, 0)
    elseif IsSafeStr(a) then
        return a, SafeNumber(c, 0)
    end
    return nil, 0
end

local cachedTalents = nil

function FP:InvalidateTalentCache()
    cachedTalents = nil
end

function FP:GetPlayerTalents()
    if cachedTalents then
        return cachedTalents
    end
    local map = {}

    if type(GetNumTalentTabs) == "function" and type(GetNumTalents) == "function" and type(GetTalentInfo) == "function" then
        local numTabs = SafeNumber(SafeCall(GetNumTalentTabs), 3)
        if numTabs < 1 or numTabs > 4 then numTabs = 3 end
        for t = 1, numTabs do
            local numTalents = SafeNumber(SafeCall(GetNumTalents, t), 0)
            for i = 1, math.min(numTalents, 60) do
                local r1, _, _, _, r5 = SafeCall(GetTalentInfo, t, i)
                if type(r1) == "table" then
                    local tName = r1.name
                    local tRank = SafeNumber(r1.currentRank or r1.rank or r1.activeRank, 0)
                    if IsSafeStr(tName) and tRank > 0 then
                        map[string.lower(tName)] = tRank
                    end
                elseif IsSafeStr(r1) then
                    local tRank = SafeNumber(r5, 0)
                    if tRank > 0 then
                        map[string.lower(r1)] = tRank
                    end
                end
            end
        end
    end

    if next(map) == nil and C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo then
        local cfgID = SafeCall(C_ClassTalents.GetActiveConfigID)
        local cfgInfo = IsSafeNum(cfgID) and SafeCall(C_Traits.GetConfigInfo, cfgID) or nil
        if type(cfgInfo) == "table" and type(cfgInfo.treeIDs) == "table" and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo then
            for _, treeID in ipairs(cfgInfo.treeIDs) do
                local nodes = SafeCall(C_Traits.GetTreeNodes, treeID)
                if type(nodes) == "table" then
                    for _, nodeID in ipairs(nodes) do
                        local node = SafeCall(C_Traits.GetNodeInfo, cfgID, nodeID)
                        if type(node) == "table" and IsSafeNum(node.activeRank) and node.activeRank > 0 and node.activeEntry and IsSafeNum(node.activeEntry.entryID) then
                            local entry = C_Traits.GetEntryInfo and SafeCall(C_Traits.GetEntryInfo, cfgID, node.activeEntry.entryID)
                            local defID = type(entry) == "table" and entry.definitionID
                            if IsSafeNum(defID) and C_Traits.GetDefinitionInfo then
                                local def = SafeCall(C_Traits.GetDefinitionInfo, defID)
                                local dName = type(def) == "table" and def.overrideName or (C_Spell and C_Spell.GetSpellName and IsSafeNum(type(def) == "table" and def.spellID) and SafeCall(C_Spell.GetSpellName, def.spellID))
                                if IsSafeStr(dName) then
                                    map[string.lower(dName)] = node.activeRank
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    cachedTalents = map
    return cachedTalents
end

function FP:HasPlayerTalent(...)
    local map = self:GetPlayerTalents()
    local n = select("#", ...)
    for i = 1, n do
        local name = select(i, ...)
        if type(name) == "string" and name ~= "" then
            local low = string.lower(name)
            if map[low] and map[low] > 0 then
                return map[low]
            end
            for k, r in pairs(map) do
                if r > 0 and k:find(low, 1, true) then
                    return r
                end
            end
        end
    end
    return false
end

local function IsPlayerShieldEquipped()
    local offhandID = GetInventoryItemID and SafeCall(GetInventoryItemID, "player", 17)
    if not IsSafeNum(offhandID) then return false end
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, itemEquipLoc, _, classID, subclassID = SafeCall(C_Item.GetItemInfoInstant, offhandID)
        if itemEquipLoc == "INVTYPE_SHIELD" or (classID == 4 and subclassID == 6) then
            return true
        end
    elseif GetItemInfoInstant then
        local _, _, _, itemEquipLoc, _, classID, subclassID = SafeCall(GetItemInfoInstant, offhandID)
        if itemEquipLoc == "INVTYPE_SHIELD" or (classID == 4 and subclassID == 6) then
            return true
        end
    end
    if C_Item and C_Item.GetItemInventoryTypeByID then
        local invType = SafeCall(C_Item.GetItemInventoryTypeByID, offhandID)
        if invType == 14 or (Enum and Enum.InventoryType and invType == Enum.InventoryType.IndexShieldType) then
            return true
        end
    end
    if GetInventoryItemLink then
        local link = SafeCall(GetInventoryItemLink, "player", 17)
        if IsSafeStr(link) and (link:find("INVTYPE_SHIELD") or link:find("Shield") or link:find("Scudo")) then
            return true
        end
    end
    return false
end

function FP:GetPlayerSpecInfo()
    local classTag = (UnitClass and select(2, SafeCall(UnitClass, "player"))) or "WARRIOR"
    local tabIdx = nil
    local tabPts = 0
    local totalPts = 0
    local specID = nil
    local specName = nil
    local role = "DAMAGER"
    local ptsStr = nil
    local tabs = nil

    -- 1. Check Classic/Forever 3-tree talent distribution FIRST so hybrid/1.60.1 builds are never shadowed by GetSpecialization stubs
    if type(GetTalentTabInfo) == "function" then
        local rawNumTabs = (type(GetNumTalentTabs) == "function") and SafeCall(GetNumTalentTabs) or 3
        local numTabs = SafeNumber(rawNumTabs, 3)
        if numTabs < 1 or numTabs > 4 then numTabs = 3 end
        local p = {}
        local bestPts = -1
        for t = 1, numTabs do
            local name, points = ReadTalentTabCompat(t)
            points = points or 0
            p[#p + 1] = points
            totalPts = totalPts + points
            if points > bestPts then
                bestPts = points
                tabIdx = t
                if name then specName = name end
            end
        end
        tabs = p
        if #p > 0 then ptsStr = table.concat(p, "/") end
        tabPts = math.max(0, bestPts)
        if totalPts <= 0 then
            tabIdx = nil
            specName = nil
        else
            if (classTag == "WARRIOR" and tabIdx == 3) or (classTag == "PALADIN" and tabIdx == 2) then
                role = "TANK"
            elseif (classTag == "PRIEST" and (tabIdx == 1 or tabIdx == 2))
                or (classTag == "PALADIN" and tabIdx == 1)
                or (classTag == "SHAMAN" and tabIdx == 3)
                or (classTag == "DRUID" and tabIdx == 3)
            then
                role = "HEALER"
            end
        end
    end

    -- 2. Modern Retail specialization API fallback (when Classic tabs have 0 points or don't exist)
    if not tabIdx or totalPts <= 0 then
        local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
        local getSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
        if type(getSpec) == "function" and type(getSpecInfo) == "function" then
            local idx = SafeCall(getSpec)
            if IsSafeNum(idx) and idx >= 1 and idx <= 4 then
                tabIdx = idx
                local sID, sName, _, _, sRole = SafeCall(getSpecInfo, idx)
                if IsSafeNum(sID) then specID = sID end
                if IsSafeStr(sName) then specName = sName end
                if IsSafeStr(sRole) and (sRole == "TANK" or sRole == "HEALER" or sRole == "DAMAGER") then
                    role = sRole
                end
            end
        end
    end

    local isShieldEquipped = IsPlayerShieldEquipped()
    if UnitGroupRolesAssigned then
        local grpRole = SafeCall(UnitGroupRolesAssigned, "player")
        if grpRole == "TANK" or grpRole == "HEALER" then
            role = grpRole
        end
    end

    local talents = self:GetPlayerTalents()

    return {
        classTag         = classTag,
        tabIdx           = tabIdx or 1,
        tabPts           = tabPts,
        totalPts         = totalPts,
        tabs             = tabs,
        talents          = talents,
        specID           = specID,
        specName         = specName,
        role             = role,
        ptsStr           = ptsStr,
        isShieldEquipped = isShieldEquipped,
    }
end

------------------------------------------------------------------------
-- Shared Dispel Capability Resolver & Action Bar Keybind Cache
------------------------------------------------------------------------
local DISPEL_COLORS = {
    Magic   = { r = 0.20, g = 0.65, b = 1.00 },
    Curse   = { r = 0.70, g = 0.25, b = 1.00 },
    Disease = { r = 0.85, g = 0.48, b = 0.12 },
    Poison  = { r = 0.10, g = 0.85, b = 0.20 },
    none    = { r = 0.85, g = 0.15, b = 0.15 },
}

local keybindCache = {}
local actionSlotCache = {}
local dispelCache = nil

function FP:InvalidateSpellKeybindCache()
    for k in pairs(keybindCache) do
        keybindCache[k] = nil
    end
    for k in pairs(actionSlotCache) do
        actionSlotCache[k] = nil
    end
end

function FP:InvalidateDispelCache()
    dispelCache = nil
end

local function ScanActionBarForSpell(spellID)
    if not spellID then return nil, nil end
    if keybindCache[spellID] ~= nil then
        local kb = (keybindCache[spellID] ~= false) and keybindCache[spellID] or nil
        local sl = (actionSlotCache[spellID] ~= false) and actionSlotCache[spellID] or nil
        return kb, sl
    end

    local spellName = GetSpellNameCompat(spellID)
    if not IsSafeStr(spellName) or not GetActionInfo then
        keybindCache[spellID] = false
        actionSlotCache[spellID] = false
        return nil, nil
    end

    local firstMatchedSlot = nil
    for slot = 1, 120 do
        local actionType, id, subType = SafeCall(GetActionInfo, slot)
        local matched = false
        if actionType == "spell" and type(id) == "number" and subType ~= "assistedcombat" then
            if id == spellID then
                matched = true
            else
                local name = GetSpellNameCompat(id)
                if name and name == spellName then
                    matched = true
                end
            end
        elseif actionType == "macro" and type(id) == "number" and GetMacroSpell then
            local mSpell = SafeCall(GetMacroSpell, id)
            if type(mSpell) == "number" and (mSpell == spellID or GetSpellNameCompat(mSpell) == spellName) then
                matched = true
            end
        end

        if matched then
            if not firstMatchedSlot then firstMatchedSlot = slot end
            local actionName = nil
            if slot <= 12 then
                actionName = "ACTIONBUTTON" .. slot
            elseif slot <= 24 then
                actionName = "ACTIONBUTTON" .. (slot - 12)
            elseif slot <= 36 then
                actionName = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
            elseif slot <= 48 then
                actionName = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
            elseif slot <= 60 then
                actionName = "MULTIACTIONBAR2BUTTON" .. (slot - 48)
            elseif slot <= 72 then
                actionName = "MULTIACTIONBAR1BUTTON" .. (slot - 60)
            elseif slot <= 120 then
                actionName = "ACTIONBUTTON" .. (((slot - 1) % 12) + 1)
            end

            if actionName and GetBindingKey then
                local key = SafeCall(GetBindingKey, actionName)
                if IsSafeStr(key) then
                    key = key:gsub("CTRL%-", "C-"):gsub("ALT%-", "A-"):gsub("SHIFT%-", "S-"):gsub("BUTTON", "M")
                    keybindCache[spellID] = key
                    actionSlotCache[spellID] = slot
                    return key, slot
                end
            end
        end
    end

    keybindCache[spellID] = false
    actionSlotCache[spellID] = firstMatchedSlot or false
    return nil, firstMatchedSlot
end

function FP:GetSpellKeybind(spellID)
    local key = ScanActionBarForSpell(spellID)
    return key
end

function FP:GetSpellActionSlot(spellID)
    local _, slot = ScanActionBarForSpell(spellID)
    return slot
end

local observedSpellBaseCD = {}
local castCooldownExpiresAt = {}
local castCooldownDurations = {}

local FALLBACK_BASE_COOLDOWNS = {
    [680]   = 10.0, [10332] = 10.0, -- Holy Strike (WoW Forever)
    [20271] = 8.0, [53408] = 8.0, [53407] = 8.0, [440677] = 8.0, -- Judgement
    [35395] = 4.0, [53385] = 10.0, -- Crusader Strike / Divine Storm
    [26573] = 8.0, [20116] = 8.0, [20922] = 8.0, [20923] = 8.0, [20924] = 8.0, [27173] = 8.0, [48819] = 8.0, -- Consecration
    [20925] = 10.0, [20927] = 10.0, [20928] = 10.0, [27179] = 10.0, [48952] = 8.0, -- Holy Shield
    [31935] = 15.0, [31589] = 15.0, [32699] = 15.0, [32700] = 15.0, [48827] = 30.0, -- Avenger's Shield
    [53600] = 6.0, [61411] = 6.0, [53595] = 6.0, -- Shield / Hammer of Righteousness
    [24275] = 6.0, [24274] = 6.0, [24239] = 6.0, [27180] = 6.0, [48806] = 6.0, -- Hammer of Wrath
    [879]   = 15.0, [5614]  = 15.0, [5615]  = 15.0, [10312] = 15.0, [10313] = 15.0, [10314] = 15.0, [27138] = 15.0, [48801] = 15.0, -- Exorcism
    [853]   = 60.0, [5588]  = 60.0, [5589]  = 60.0, [10308] = 60.0, -- Hammer of Justice
    [20473] = 6.0, [20929] = 6.0, [20930] = 6.0, [27174] = 6.0, [48825] = 6.0, -- Holy Shock
    [23922] = 6.0, [23923] = 6.0, [23924] = 6.0, [23925] = 6.0, [25258] = 6.0, [47488] = 6.0, -- Shield Slam
    [12294] = 6.0, [21551] = 6.0, [21552] = 6.0, [21553] = 6.0, [25248] = 6.0, [30330] = 6.0, [47486] = 6.0, -- Mortal Strike
    [23881] = 4.0, [23892] = 4.0, [23893] = 4.0, [23894] = 4.0, [25251] = 4.0, [30335] = 4.0, -- Bloodthirst
    [6572]  = 5.0, [6574]  = 5.0, [7379]  = 5.0, [11600] = 5.0, [11601] = 5.0, [25288] = 5.0, [57823] = 5.0, -- Revenge
    [7384]  = 5.0, [7887]  = 5.0, [11584] = 5.0, [11585] = 5.0, [46968] = 20.0, -- Overpower / Shockwave
    [6343]  = 6.0, [8198]  = 6.0, [8204]  = 6.0, [8205]  = 6.0, [11580] = 6.0, [11581] = 6.0, [25264] = 6.0, [47502] = 6.0, -- Thunder Clap
    [1680]  = 8.0, [2565]  = 5.0, -- Whirlwind / Shield Block
    [2136]  = 8.0, [2137]  = 8.0, [2138]  = 8.0, [8412]  = 8.0, [8413]  = 8.0, [10197] = 8.0, [10199] = 8.0, [10200] = 8.0, [27079] = 8.0, [42873] = 8.0, -- Fire Blast
    [44572] = 30.0, [44425] = 3.0, [44780] = 3.0, [44781] = 3.0, -- Deep Freeze / Arcane Barrage
    [14251] = 6.0, -- Riposte
    [17962] = 10.0, [50796] = 12.0, [59170] = 12.0, [59171] = 12.0, [59172] = 12.0, -- Conflagrate / Chaos Bolt
    [17877] = 15.0, [18867] = 15.0, [18868] = 15.0, [18869] = 15.0, [18870] = 15.0, [18871] = 15.0, [27263] = 15.0, [30546] = 15.0, [47827] = 15.0, -- Shadowburn
    [48181] = 8.0, [59161] = 8.0, [59163] = 8.0, [59164] = 8.0, -- Haunt
    [8092]  = 8.0, [8102]  = 8.0, [8103]  = 8.0, [8104]  = 8.0, [10945] = 8.0, [10946] = 8.0, [10947] = 8.0, [25375] = 8.0, [48127] = 8.0, -- Mind Blast
    [32379] = 12.0, [32996] = 12.0, [48158] = 12.0, [47540] = 12.0, [53005] = 12.0, [53006] = 12.0, [53007] = 12.0, -- SW:D / Penance
    [44041] = 30.0, [44043] = 30.0, [44044] = 30.0, [44045] = 30.0, [44046] = 30.0, [44047] = 30.0, -- Chastise
    [53351] = 15.0, [61005] = 15.0, [61006] = 15.0, [53209] = 10.0, [53301] = 6.0, [60051] = 6.0, [60052] = 6.0, [60053] = 6.0, -- Kill Shot / Chimera / Explosive
    [3674]  = 30.0, [63668] = 30.0, [63669] = 30.0, [63670] = 30.0, -- Black Arrow
    [33878] = 6.0, [33986] = 6.0, [33987] = 6.0, [48564] = 6.0, [78674] = 15.0, -- Mangle (Bear) / Starsurge
    [17364] = 8.0, [60103] = 6.0, [51505] = 8.0, [60043] = 8.0, [49184] = 8.0, -- Stormstrike / Lava Lash / Lava Burst / Howling Blast
}

local FALLBACK_NAME_COOLDOWNS = {
    ["holy strike"]             = 10.0, ["colpo sacro"]           = 10.0, ["assalto sacro"]           = 10.0,
    ["judgement"]               = 8.0,  ["judgment"]              = 8.0,  ["giudizio"]                = 8.0,
    ["consecration"]            = 8.0,  ["consacrazione"]         = 8.0,
    ["holy shield"]             = 10.0, ["scudo sacro"]           = 10.0,
    ["crusader strike"]         = 4.0,  ["assalto del crociato"]  = 4.0,
    ["avenger's shield"]        = 15.0, ["scudo del vendicatore"] = 15.0,
    ["hammer of wrath"]         = 6.0,  ["martello dell'ira"]     = 6.0,
    ["exorcism"]                = 15.0, ["esorcismo"]             = 15.0,
    ["holy shock"]              = 6.0,  ["folgore sacra"]         = 6.0,
    ["divine storm"]            = 10.0, ["tempesta divina"]       = 10.0,
    ["shield of righteousness"] = 6.0,  ["hammer of the righteous"] = 6.0,
    ["hammer of justice"]       = 60.0, ["martello della giustizia"] = 60.0,
    ["shield slam"]             = 6.0,  ["mortal strike"]         = 6.0,  ["bloodthirst"]             = 4.0,
    ["revenge"]                 = 5.0,  ["overpower"]             = 5.0,  ["whirlwind"]               = 8.0,
    ["thunder clap"]            = 6.0,  ["shockwave"]             = 20.0, ["shield block"]            = 5.0,
    ["spearing strike"]         = 20.0, ["colpo perforante"]      = 20.0,
    ["shank"]                   = 6.0,  ["riposte"]               = 6.0,
    ["fire blast"]              = 8.0,  ["deep freeze"]           = 30.0, ["arcane barrage"]          = 3.0,
    ["conflagrate"]             = 10.0, ["chaos bolt"]            = 12.0, ["shadowburn"]              = 15.0,
    ["haunt"]                   = 8.0,  ["drain hope"]            = 10.0,
    ["mind blast"]              = 8.0,  ["shadow word: death"]    = 12.0, ["holy fire"]               = 10.0,
    ["penance"]                 = 12.0, ["chastise"]              = 30.0, ["castigo"]                 = 30.0,
    ["stormstrike"]             = 8.0,  ["lava burst"]            = 8.0,  ["lava lash"]               = 6.0,
    ["chain lightning"]         = 6.0,  ["flame shock"]           = 6.0,  ["earth shock"]             = 6.0,
    ["kill shot"]               = 15.0, ["chimera shot"]          = 10.0, ["explosive shot"]          = 6.0,
    ["black arrow"]             = 30.0, ["sniper shot"]           = 10.0, ["strider kick"]            = 6.0,
    ["aimed shot"]              = 10.0, ["multi-shot"]            = 10.0, ["arcane shot"]             = 6.0,
    ["mongoose bite"]           = 5.0,  ["raptor strike"]         = 6.0,
    ["mangle (bear)"]           = 6.0,  ["mangle (cat)"]          = 6.0,  ["starsurge"]               = 15.0,
    ["faerie fire"]             = 6.0,  ["howling blast"]         = 8.0,
}

local function CacheObservedCooldown(spellID, spellName, dur)
    if type(dur) ~= "number" or dur <= 1.5 then return end
    if IsSafeNum(spellID) then observedSpellBaseCD[spellID] = dur end
    if IsSafeStr(spellName) then observedSpellBaseCD[string.lower(spellName)] = dur end
end

local function ReadCooldownForID(queryID, spellName, now)
    if not queryID then return 0, 0 end
    if C_Spell and C_Spell.GetSpellCooldown then
        local cd = SafeCall(C_Spell.GetSpellCooldown, queryID)
        if type(cd) == "table" and IsSafeNum(cd.startTime) and IsSafeNum(cd.duration) then
            local s = cd.startTime or 0
            local d = cd.duration or 0
            local onGCDKnown = IsAccessible(cd.isOnGCD) and (type(cd.isOnGCD) == "boolean")
            local isReal = (onGCDKnown and cd.isOnGCD == false and d > 0)
                or ((not onGCDKnown or cd.isOnGCD == nil) and d > 1.5)
            if isReal and s > 0 then
                CacheObservedCooldown(queryID, spellName, d)
                return math.max(0, (s + d) - now), d
            end
        end
    elseif GetSpellCooldown then
        local s, d = SafeCall(GetSpellCooldown, queryID)
        if IsSafeNum(s) and IsSafeNum(d) and d > 1.5 and s > 0 then
            CacheObservedCooldown(queryID, spellName, d)
            return math.max(0, (s + d) - now), d
        end
    end
    return 0, 0
end

local function RecordSpellCastCooldown(spellID, spellNameArg)
    if not IsSafeNum(spellID) and not IsSafeStr(spellNameArg) then return end
    local now = (GetTime and SafeCall(GetTime)) or 0
    if not IsSafeNum(now) then return end

    local sName = IsSafeStr(spellNameArg) and spellNameArg or (IsSafeNum(spellID) and GetSpellNameCompat(spellID))
    local lowName = IsSafeStr(sName) and string.lower(sName) or nil

    local dur = (IsSafeNum(spellID) and observedSpellBaseCD[spellID])
        or (lowName and observedSpellBaseCD[lowName])
    if not dur and IsSafeNum(spellID) and GetSpellBaseCooldown then
        local baseMs = SafeCall(GetSpellBaseCooldown, spellID)
        if IsSafeNum(baseMs) and baseMs > 1500 then
            dur = baseMs / 1000
        end
    end
    if not dur and IsSafeNum(spellID) then
        dur = FALLBACK_BASE_COOLDOWNS[spellID]
    end
    if not dur and lowName then
        dur = FALLBACK_NAME_COOLDOWNS[lowName]
    end
    if dur and dur > 1.5 then
        if IsSafeNum(spellID) then
            castCooldownExpiresAt[spellID] = now + dur
            castCooldownDurations[spellID] = dur
        end
        if lowName then
            castCooldownExpiresAt[lowName] = now + dur
            castCooldownDurations[lowName] = dur
        end
    end
end

local function GetAccurateSpellCooldown(spellID, extraArg)
    if type(spellID) == "table" then spellID = extraArg end
    if not spellID then return 0, 0, true, nil end

    local now = (GetTime and SafeCall(GetTime)) or 0
    if not IsSafeNum(now) then now = 0 end

    local queryID = spellID
    if C_Spell and C_Spell.GetOverrideSpell then
        local ov = SafeCall(C_Spell.GetOverrideSpell, spellID)
        if IsSafeNum(ov) and ov > 0 then queryID = ov end
    elseif FindSpellOverrideByID then
        local ov = SafeCall(FindSpellOverrideByID, spellID)
        if IsSafeNum(ov) and ov > 0 then queryID = ov end
    end

    local spellName = GetSpellNameCompat(spellID)
    local lowName = IsSafeStr(spellName) and string.lower(spellName) or nil

    local durationObj = nil
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local okObj, obj = pcall(C_Spell.GetSpellCooldownDuration, queryID, true)
        if okObj and obj then durationObj = obj end
    end

    local remaining, dur = ReadCooldownForID(queryID, spellName, now)
    if remaining <= 0 and queryID ~= spellID then
        remaining, dur = ReadCooldownForID(spellID, spellName, now)
    end

    -- Fallback by spell name (handles custom/rank spellID differences)
    if remaining <= 0 and GetSpellCooldown and IsSafeStr(spellName) then
        local s, d = SafeCall(GetSpellCooldown, spellName)
        if IsSafeNum(s) and IsSafeNum(d) and d > 1.5 and s > 0 then
            remaining = math.max(0, (s + d) - now)
            dur = d
            CacheObservedCooldown(spellID, spellName, d)
        end
    end

    -- Charge-based abilities: if 0 charges remain, expose recharge timer
    if C_Spell and C_Spell.GetSpellCharges then
        local ch = SafeCall(C_Spell.GetSpellCharges, queryID)
        if type(ch) == "table" and IsSafeNum(ch.currentCharges) and IsSafeNum(ch.maxCharges) and ch.maxCharges > 1 then
            if ch.currentCharges == 0 and IsSafeNum(ch.cooldownStartTime) and IsSafeNum(ch.cooldownDuration) and ch.cooldownDuration > 0 then
                local chRem = math.max(0, (ch.cooldownStartTime + ch.cooldownDuration) - now)
                if chRem > remaining then
                    remaining = chRem
                    dur = ch.cooldownDuration
                end
            end
        end
    end

    -- Action bar fallback (reads exact bar button cooldown if spell query yielded 0)
    if remaining <= 0 and GetActionCooldown then
        local slot = FP:GetSpellActionSlot(spellID)
        if slot then
            local s, d = SafeCall(GetActionCooldown, slot)
            if IsSafeNum(s) and IsSafeNum(d) and d > 1.5 and s > 0 then
                remaining = math.max(0, (s + d) - now)
                dur = d
                CacheObservedCooldown(spellID, spellName, d)
            end
        end
    end

    -- Combat secret-value fallback: check Cast cooldown tracker and DurationObject:IsZero()
    if remaining <= 0 then
        local exp = castCooldownExpiresAt[queryID] or castCooldownExpiresAt[spellID] or (lowName and castCooldownExpiresAt[lowName])
        local cDur = castCooldownDurations[queryID] or castCooldownDurations[spellID] or (lowName and castCooldownDurations[lowName])
        if exp and exp > now then
            remaining = exp - now
            dur = cDur or remaining
        elseif exp and exp <= now then
            castCooldownExpiresAt[spellID] = nil
            castCooldownExpiresAt[queryID] = nil
            if lowName then castCooldownExpiresAt[lowName] = nil end
        end
    else
        if IsSafeNum(spellID) then
            castCooldownExpiresAt[spellID] = now + remaining
            castCooldownDurations[spellID] = dur
        end
        if lowName then
            castCooldownExpiresAt[lowName] = now + remaining
            castCooldownDurations[lowName] = dur
        end
    end

    local isReady = (remaining <= 0.15)
    if isReady and durationObj and durationObj.IsZero then
        local okZ, z = pcall(durationObj.IsZero, durationObj)
        if okZ and IsAccessible(z) and z == false then
            isReady = false
        end
    end

    return remaining, dur, isReady, durationObj
end

local function IsSpellHelpfulCompat(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.IsSpellHelpful then
        local ok = SafeCall(C_Spell.IsSpellHelpful, spellID)
        if IsAccessible(ok) then return ok == true end
    elseif IsHelpfulSpell then
        local ok = SafeCall(IsHelpfulSpell, spellID)
        if IsAccessible(ok) then return ok == true end
    end
    return nil
end

local function CollectSpellbookMap()
    local byName = {}
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
                        and IsSafeNum(itemInfo.spellID)
                        and IsSafeStr(itemInfo.name)
                    then
                        byName[string.lower(itemInfo.name)] = itemInfo.spellID
                    end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
        local bookType = BOOKTYPE_SPELL or "spell"
        local numTabs = SafeCall(GetNumSpellTabs) or 0
        for t = 1, numTabs do
            local _, _, offset, numSlots, _, offSpecID = SafeCall(GetSpellTabInfo, t)
            if (not offSpecID or offSpecID == 0) and IsSafeNum(offset) and IsSafeNum(numSlots) then
                for s = offset + 1, offset + numSlots do
                    local sName = SafeCall(GetSpellBookItemName, s, bookType)
                    local sType, sid = nil, nil
                    if GetSpellBookItemInfo then
                        sType, sid = SafeCall(GetSpellBookItemInfo, s, bookType)
                    end
                    if IsSafeStr(sName) and (sType == "SPELL" or sType == nil) then
                        local key = string.lower(sName)
                        if IsSafeNum(sid) then
                            byName[key] = sid
                        elseif not byName[key] then
                            byName[key] = true
                        end
                    end
                end
            end
        end
    end
    return byName
end

function FP:GetPlayerDispelInfo()
    if dispelCache then
        return dispelCache
    end

    local spec = self:GetPlayerSpecInfo()
    local cls = (spec and spec.classTag) or (UnitClass and select(2, SafeCall(UnitClass, "player"))) or "WARRIOR"
    local hasModernSpecs = (C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function")
    local sbMap = nil

    local function FindKnownDispel(spellID, aliases)
        if spellID and IsSpellKnownCompat(spellID) then
            return spellID
        end
        if aliases then
            if not sbMap then sbMap = CollectSpellbookMap() end
            for _, alias in ipairs(aliases) do
                local hit = sbMap[string.lower(alias)]
                if hit then
                    return (type(hit) == "number") and hit or spellID
                end
            end
        end
        return nil
    end

    local schools = {}
    local spellsBySchool = {}
    local function RegisterSchoolSpell(schoolList, sid, fallbackName)
        if not sid then return end
        local name = GetSpellNameCompat(sid) or fallbackName or "Dispel"
        local icon = GetSpellTextureCompat(sid) or "Interface\\Icons\\Spell_Holy_DispelMagic"
        local info = { spellID = sid, name = name, icon = icon }
        for _, sc in ipairs(schoolList) do
            schools[sc] = true
            if not spellsBySchool[sc] then
                spellsBySchool[sc] = info
            end
        end
    end

    if cls == "PALADIN" then
        local cleanse = FindKnownDispel(4987, { "Cleanse", "Purificazione", "Reinigung des Glaubens", "Limpiar", "Epuration", "Очищение" })
        if cleanse then
            RegisterSchoolSpell({ "Magic", "Poison", "Disease" }, cleanse, "Cleanse")
        end
        local cleanseTox = FindKnownDispel(213644, { "Cleanse Toxins", "Purificazione dalle Tossine" })
        if cleanseTox then
            RegisterSchoolSpell({ "Poison", "Disease" }, cleanseTox, "Cleanse Toxins")
        end
        local purify = FindKnownDispel(1152, { "Purify", "Purifica", "Läutern" })
        if purify then
            RegisterSchoolSpell({ "Poison", "Disease" }, purify, "Purify")
        end
    elseif cls == "PRIEST" then
        local purify = FindKnownDispel(527, { "Dispel Magic", "Purify", "Dissoluzione Magica", "Purificazione" })
        if not purify then
            purify = FindKnownDispel(988)
        end
        if purify then
            if hasModernSpecs and IsSpellKnownCompat(390632) then
                RegisterSchoolSpell({ "Magic", "Disease" }, purify, "Purify")
            else
                RegisterSchoolSpell({ "Magic" }, purify, "Dispel Magic")
            end
        end
        local purifyDis = FindKnownDispel(213634, { "Purify Disease" })
        local abolishDis = FindKnownDispel(552, { "Abolish Disease", "Abolisci Malattia" })
        local cureDis = (not hasModernSpecs or IsSpellHelpfulCompat(528) == true) and FindKnownDispel(528, { "Cure Disease", "Cura Malattia" }) or nil
        local disSpell = purifyDis or abolishDis or cureDis
        if disSpell then
            RegisterSchoolSpell({ "Disease" }, disSpell, "Cure Disease")
        end
        if not spellsBySchool["Magic"] then
            local mass = FindKnownDispel(32375, { "Mass Dispel", "Dissoluzione di Massa" })
            if mass then
                RegisterSchoolSpell({ "Magic" }, mass, "Mass Dispel")
            end
        end
    elseif cls == "MAGE" then
        local decurse = FindKnownDispel(475, { "Remove Curse", "Remove Lesser Curse", "Rimozione Maledizione", "Fluch aufheben" })
        if decurse then
            RegisterSchoolSpell({ "Curse" }, decurse, "Remove Curse")
        end
    elseif cls == "DRUID" then
        local natCure = FindKnownDispel(88423, { "Nature's Cure", "Cura della Natura" })
        if natCure then
            RegisterSchoolSpell({ "Magic", "Curse", "Poison" }, natCure, "Nature's Cure")
        end
        local remCurse = FindKnownDispel(2782, { "Remove Corruption", "Remove Curse", "Rimozione Corruzione", "Rimozione Maledizione" })
        local abolPoi = FindKnownDispel(2893, { "Abolish Poison", "Abolisci Veleno" })
        local curePoi = FindKnownDispel(8946, { "Cure Poison", "Cura Veleno" })
        if remCurse then
            if hasModernSpecs and not abolPoi and not curePoi then
                RegisterSchoolSpell({ "Curse", "Poison" }, remCurse, "Remove Corruption")
            else
                RegisterSchoolSpell({ "Curse" }, remCurse, "Remove Curse")
            end
        end
        local poiSpell = abolPoi or curePoi
        if poiSpell then
            RegisterSchoolSpell({ "Poison" }, poiSpell, "Cure Poison")
        end
    elseif cls == "SHAMAN" then
        local purifySpirit = FindKnownDispel(77130, { "Purify Spirit", "Purificazione dello Spirito" })
        if purifySpirit then
            RegisterSchoolSpell({ "Magic", "Curse" }, purifySpirit, "Purify Spirit")
        end
        local cleanseSpirit = FindKnownDispel(51886, { "Cleanse Spirit", "Purifica Spirito" })
        if cleanseSpirit then
            if not hasModernSpecs then
                RegisterSchoolSpell({ "Curse", "Poison", "Disease" }, cleanseSpirit, "Cleanse Spirit")
            else
                RegisterSchoolSpell({ "Curse" }, cleanseSpirit, "Cleanse Spirit")
            end
        end
        local curePoi = FindKnownDispel(526, { "Cure Toxins", "Cure Poison", "Cura Tossine", "Cura Veleno" })
        if curePoi then
            local pName = GetSpellNameCompat(curePoi) or ""
            if pName:lower():find("toxin") or pName:lower():find("tossin") then
                RegisterSchoolSpell({ "Poison", "Disease" }, curePoi, "Cure Toxins")
            else
                RegisterSchoolSpell({ "Poison" }, curePoi, "Cure Poison")
            end
        end
        local cureDis = FindKnownDispel(2870, { "Cure Disease", "Cura Malattia" })
        if cureDis then
            RegisterSchoolSpell({ "Disease" }, cureDis, "Cure Disease")
        end
    elseif cls == "MONK" then
        local detoxMW = FindKnownDispel(115450, { "Detox" })
        if detoxMW then
            RegisterSchoolSpell({ "Magic", "Poison", "Disease" }, detoxMW, "Detox")
        end
        local detoxOther = FindKnownDispel(218164, { "Detox" })
        if detoxOther then
            RegisterSchoolSpell({ "Poison", "Disease" }, detoxOther, "Detox")
        end
    elseif cls == "EVOKER" then
        local nat = FindKnownDispel(360823, { "Naturalize" })
        if nat then RegisterSchoolSpell({ "Magic", "Poison" }, nat, "Naturalize") end
        local exp = FindKnownDispel(365585, { "Expunge" })
        if exp then RegisterSchoolSpell({ "Poison" }, exp, "Expunge") end
    elseif cls == "WARLOCK" then
        local petAlive = UnitExists and SafeBoolean(SafeCall(UnitExists, "pet"), false)
            and not (UnitIsDead and SafeBoolean(SafeCall(UnitIsDead, "pet"), false))
        if petAlive then
            local singe = FindKnownDispel(89808, { "Singe Magic", "Brucia Magia" }) or FindKnownDispel(119905)
            if singe then
                RegisterSchoolSpell({ "Magic" }, singe, "Singe Magic")
            else
                for _, dId in ipairs({ 27277, 27276, 19736, 19734, 19731, 19505 }) do
                    if IsSpellKnownCompat(dId) and IsSpellHelpfulCompat(dId) == true then
                        RegisterSchoolSpell({ "Magic" }, dId, "Devour Magic")
                        break
                    end
                end
            end
        end
    end

    dispelCache = {
        classTag       = cls,
        schools        = schools,
        spellsBySchool = spellsBySchool,
        canDispelAny   = (next(schools) ~= nil),
    }
    return dispelCache
end

local sharedCacheFrame = CreateFrame("Frame")
SafeRegisterEvent(sharedCacheFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(sharedCacheFrame, "SPELLS_CHANGED")
SafeRegisterEvent(sharedCacheFrame, "LEARNED_SPELL_IN_TAB")
SafeRegisterEvent(sharedCacheFrame, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(sharedCacheFrame, "CHARACTER_POINTS_CHANGED")
SafeRegisterEvent(sharedCacheFrame, "ACTIVE_TALENT_GROUP_CHANGED")
SafeRegisterEvent(sharedCacheFrame, "PLAYER_SPECIALIZATION_CHANGED")
SafeRegisterEvent(sharedCacheFrame, "TRAIT_CONFIG_UPDATED")
SafeRegisterEvent(sharedCacheFrame, "ACTIONBAR_SLOT_CHANGED")
SafeRegisterEvent(sharedCacheFrame, "UPDATE_BINDINGS")
SafeRegisterUnitEvent(sharedCacheFrame, "UNIT_PET", "player")
sharedCacheFrame:SetScript("OnEvent", function(_, event)
    if event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
        FP:InvalidateSpellKeybindCache()
    elseif event == "PLAYER_ENTERING_WORLD" then
        FP:InvalidateSpellKeybindCache()
        FP:InvalidateDispelCache()
        FP:InvalidateTalentCache()
    else
        FP:InvalidateDispelCache()
        FP:InvalidateTalentCache()
    end
end)

FP.DISPEL_COLORS         = DISPEL_COLORS
FP.IsSecret              = IsSecret
FP.IsAccessible          = IsAccessible
FP.IsSafeNum             = IsSafeNum
FP.IsSafeStr             = IsSafeStr
FP.SafeCall              = SafeCall
FP.SafeBoolean           = SafeBoolean
FP.SafeNumber            = SafeNumber
FP.SafeRegisterEvent     = SafeRegisterEvent
FP.SafeRegisterUnitEvent = SafeRegisterUnitEvent
FP.GetSpellName          = GetSpellNameCompat
FP.GetSpellTexture       = GetSpellTextureCompat
FP.IsSpellKnown          = IsSpellKnownCompat
FP.IsSpellPassive        = IsSpellPassiveCompat
FP.IsSpellUsable         = IsSpellUsableCompat
FP.GetSpellCooldown      = GetAccurateSpellCooldown
FP.RecordSpellCastCooldown = RecordSpellCastCooldown
FP.ReadTalentTabCompat   = ReadTalentTabCompat
FP.IsPlayerShieldEquipped = IsPlayerShieldEquipped

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
    return UnitFactionGroup and SafeCall(UnitFactionGroup, "player") or nil
end

function FP:GetPlayerClass()
    if not UnitClass then return "WARRIOR" end
    return select(2, SafeCall(UnitClass, "player")) or "WARRIOR"
end

function FP:GetPlayerRace()
    if not UnitRace then return nil end
    return select(2, SafeCall(UnitRace, "player"))
end

function FP:GetPlayerLevel()
    return SafeNumber(UnitLevel and SafeCall(UnitLevel, "player"), 1)
end

function FP:GetPlayerXPPercent()
    local maxXP = SafeNumber(UnitXPMax and SafeCall(UnitXPMax, "player"), 0)
    if maxXP <= 0 then return 0 end
    local curXP = SafeNumber(UnitXP and SafeCall(UnitXP, "player"), 0)
    return curXP / maxXP
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
    if self.RefreshClassFrames then self:RefreshClassFrames() end
    if self.RefreshDispelAlert then self:RefreshDispelAlert() end
    if self.RefreshRotationAdvisor then self:RefreshRotationAdvisor() end
    if self.RefreshTodoHUD then self:RefreshTodoHUD() end
    if self.RefreshTodoListUI then self:RefreshTodoListUI() end
    if self.RefreshQuestStarterAlert then self:RefreshQuestStarterAlert() end
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
        useGridPartyFrames      = true,
        gridPartyLocked         = true,
        gridPartyShowSolo       = false,
        gridPartyScale          = 1.0,
        gridPartyPos            = nil,

        -- Spell Rotation Advisor
        enableRotationAdvisor   = true,
        rotationLocked          = true,
        rotationScale           = 1.0,
        rotationAlpha           = 1.0,
        rotationMode            = "always",
        rotationShowQueue       = false,
        rotationPos             = nil,

        -- Dispel Alert HUD
        enableDispelAlert       = true,
        dispelAlertSound        = true,
        dispelAlertSoundPreset  = "readycheck",
        dispelAlertLocked       = true,
        dispelAlertScale        = 1.0,
        dispelAlertPosPreset    = "TOPRIGHT",
        dispelAlertPos          = nil,
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
    elseif cmd == "rot" or cmd == "rota" or cmd == "rotation" then
        local sub = rest and rest:match("^(%S+)")
        sub = sub and sub:lower() or ""
        if sub == "lock" or sub == "unlock" then
            local isLocked = (sub == "lock")
            if sub == "lock" and NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.rotationLocked == true then
                isLocked = false
            end
            if FP.SetRotationAdvisorLocked then
                FP:SetRotationAdvisorLocked(isLocked)
            end
        elseif sub == "reset" then
            if FP.ResetRotationAdvisorPos then
                FP:ResetRotationAdvisorPos()
            end
        elseif sub == "debug" then
            if FP.DumpRotationDebug then
                FP:DumpRotationDebug()
            end
        elseif sub == "always" or sub == "combat" or sub == "target" then
            if NexusKitDB and NexusKitDB.settings then
                NexusKitDB.settings.rotationMode = sub
                if FP.RefreshRotationAdvisor then FP:RefreshRotationAdvisor() end
                if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
                FP:Print("Rotation Advisor mode: " .. sub)
            end
        else
            if FP.ToggleRotationAdvisor then
                FP:ToggleRotationAdvisor()
            end
        end
    elseif cmd == "dispel" or cmd == "cleanse" or cmd == "decurse" then
        local sub, arg = (rest or ""):match("^(%S+)%s*(.-)$")
        sub = sub and sub:lower() or ""
        arg = Trim(arg or ""):lower()
        if sub == "lock" or sub == "unlock" then
            local locked = (sub == "lock")
            if sub == "lock" and NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.dispelAlertLocked == true then
                locked = false
            end
            if FP.SetDispelAlertLocked then
                FP:SetDispelAlertLocked(locked)
            end
        elseif sub == "reset" then
            if FP.ResetDispelAlertPos then
                FP:ResetDispelAlertPos()
            end
        elseif sub == "pos" and arg ~= "" then
            local map = { topright = "TOPRIGHT", tr = "TOPRIGHT", topleft = "TOPLEFT", tl = "TOPLEFT", top = "TOPCENTER", center = "CENTER" }
            local key = map[arg]
            if key and FP.SetDispelAlertPosPreset then
                FP:SetDispelAlertPosPreset(key)
            else
                FP:Print("Uso: /nk dispel pos <topright|topleft|top|center>")
            end
        elseif sub == "sound" then
            if arg ~= "" and FP.SetDispelAlertSoundPreset then
                FP:SetDispelAlertSoundPreset(arg)
            elseif NexusKitDB and NexusKitDB.settings then
                NexusKitDB.settings.dispelAlertSound = not (NexusKitDB.settings.dispelAlertSound ~= false)
                local st = NexusKitDB.settings.dispelAlertSound and "|cff00ff00ATTIVO|r" or "|cffff0000DISATTIVO|r"
                FP:Print("Suono Avviso Dispel: " .. st)
            end
        elseif sub == "test" then
            if FP.TriggerDispelAlertTest then
                FP:TriggerDispelAlertTest()
            end
        else
            if FP.ToggleDispelAlert then
                FP:ToggleDispelAlert()
            end
        end
    elseif cmd == "taintlog" then
        local cur = (GetCVar and GetCVar("taintLog")) or "0"
        local nextVal = (cur == "0") and "2" or "0"
        pcall(SetCVar, "taintLog", nextVal)
        FP:Print("taintLog CVar: " .. nextVal)
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
        -- Turn off heavy diagnostic taintLog if previously enabled by old versions
        if NexusKitDB and NexusKitDB.settings and not NexusKitDB.settings._migratedTaintLogOff then
            NexusKitDB.settings._migratedTaintLogOff = true
            pcall(SetCVar, "taintLog", "0")
        end
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

        if FP.RefreshPartyGridLock then
            FP:RefreshPartyGridLock()
        end

        -- Enforce single-icon dynamic progression for Rotation Advisor by default
        if NexusKitDB and NexusKitDB.settings and not NexusKitDB.settings.rotationSingleIconV3 then
            NexusKitDB.settings.rotationSingleIconV3 = true
            NexusKitDB.settings.rotationShowQueue = false
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
        if blockedAddon == addonName or blockedAddon == "NexusKit" or blockedAddon == "NexKit" then
            local blockedFunc = tostring(arg2 or "nil")
            local stack = (debugstack and debugstack(2, 6, 6)) or ""
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff2040[NexusKit Diagnostica]|r %s! Addon: %s | Action: %s", event, blockedAddon, blockedFunc))
                if stack ~= "" then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffa040[Stack]:|r " .. stack:gsub("\n", " -> "))
                end
            end
        end
    end
end)
