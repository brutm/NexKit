-- NexusKit - UI/BuffAdvisor.lua
-- Contextual Buff & Profession Tracking Advisor:
-- Reminds the player of missing/expiring class buffs, stances/auras, pets,
-- weapon enchants/poisons, and profession trackings (e.g. Find Minerals / Find Herbs).
local addonName, FP = ...

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
local MAX_SLOTS = 6
local SLOT_W = 58
local SLOT_H = 66
local SLOT_GAP = 6
local MIN_FRAME_W = 186
local FRAME_H = 104
local COMPACT_FRAME_H = SLOT_H + 10

local function GetBuffSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsTransparentBar()
    return GetBuffSettings().buffTransparentBar ~= false
end

local function GetExpiringThreshold()
    local val = tonumber(GetBuffSettings().buffExpiringSeconds) or 120
    if val < 30 then val = 30 elseif val > 300 then val = 300 end
    return val
end

-------------------------------------------------------------------------------
-- Safe WoW API compatibility & secret-value guards (Interface 16001 / Forever)
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

local function SafeRegisterEvent(f, eventName)
    pcall(f.RegisterEvent, f, eventName)
end

local function SafeRegisterUnitEvent(f, eventName, unit)
    local ok = pcall(f.RegisterUnitEvent, f, eventName, unit)
    if not ok then
        SafeRegisterEvent(f, eventName)
    end
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
        if IsAccessible(tex) then return tex end
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

local function IsSpellPassiveCompat(spellID)
    if not spellID then return false end
    if C_Spell and C_Spell.IsSpellPassive then
        local passive = SafeCall(C_Spell.IsSpellPassive, spellID)
        if IsAccessible(passive) then return passive == true end
    end
    if IsPassiveSpell then
        local passive = SafeCall(IsPassiveSpell, spellID)
        if IsAccessible(passive) then return passive == true end
    end
    return false
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

local function IsSpellUsableCompat(spellID)
    if not spellID then return true, false end
    if C_Spell and C_Spell.IsSpellUsable then
        local usable, noMana = SafeCall(C_Spell.IsSpellUsable, spellID)
        if IsAccessible(usable) then
            return usable == true, (IsAccessible(noMana) and noMana == true) or false
        end
    elseif IsUsableSpell then
        local usable, noMana = SafeCall(IsUsableSpell, spellID)
        if IsAccessible(usable) then
            return usable == true, (IsAccessible(noMana) and noMana == true) or false
        end
    end
    return true, false
end

local function GetItemInfoInstantCompat(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemInfoInstant then
        return SafeCall(C_Item.GetItemInfoInstant, itemID)
    elseif GetItemInfoInstant then
        return SafeCall(GetItemInfoInstant, itemID)
    end
    return nil
end

local function GetItemCountCompat(itemID)
    if not itemID then return 0 end
    if C_Item and C_Item.GetItemCount then
        return tonumber(SafeCall(C_Item.GetItemCount, itemID, false)) or 0
    elseif GetItemCount then
        return tonumber(SafeCall(GetItemCount, itemID, false)) or 0
    end
    return 0
end

local function GetItemNameCompat(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemNameByID then
        local n = SafeCall(C_Item.GetItemNameByID, itemID)
        if IsAccessible(n) and n ~= "" then return n end
    end
    if C_Item and C_Item.GetItemInfo then
        local n = SafeCall(C_Item.GetItemInfo, itemID)
        if IsAccessible(n) and n ~= "" then return n end
    elseif GetItemInfo then
        local n = SafeCall(GetItemInfo, itemID)
        if IsAccessible(n) and n ~= "" then return n end
    end
    return nil
end

local function GetItemIconCompat(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemIconByID then
        local tex = SafeCall(C_Item.GetItemIconByID, itemID)
        if IsAccessible(tex) then return tex end
    end
    if GetItemIcon then
        local tex = SafeCall(GetItemIcon, itemID)
        if IsAccessible(tex) then return tex end
    end
    local _, _, _, _, icon = GetItemInfoInstantCompat(itemID)
    if IsAccessible(icon) then return icon end
    return nil
end

local function IsAdvisorEnabled()
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.enableBuffAdvisor == false then
        return false
    end
    return true
end

-------------------------------------------------------------------------------
-- Spellbook & Context Snapshots (rebuilt cleanly per evaluation)
-------------------------------------------------------------------------------
local spellbookByName = {}
local spellbookLoaded = false

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
                    local sName, sSub = SafeCall(GetSpellBookItemName, s, bookType)
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

local function FindKnownSpell(rankIDs)
    if not spellbookLoaded then
        RebuildSpellbookCache()
    end
    if type(rankIDs) ~= "table" then return nil, nil end

    -- Scan highest rank down to lowest so we always cast the highest learned non-passive rank
    for i = #rankIDs, 1, -1 do
        local sid = rankIDs[i]
        if IsSpellKnownCompat(sid) and not IsSpellPassiveCompat(sid) then
            local name = GetSpellNameCompat(sid)
            return sid, name
        end
    end

    -- Locale name fallback in case custom Forever spellIDs differ from standard IDs
    for i = #rankIDs, 1, -1 do
        local baseName = GetSpellNameCompat(rankIDs[i])
        if baseName then
            local found = spellbookByName[string.lower(baseName)]
            if found then
                local castID = (type(found) == "number") and found or rankIDs[i]
                if not IsSpellPassiveCompat(castID) then
                    return castID, baseName
                end
            end
        end
    end

    return nil, nil
end

local function ScanPlayerAurasAndForms()
    local state = {
        activeIDs         = {},
        activeNames       = {},
        shapeshiftIDs     = {},
        shapeshiftNames   = {},
        shapeshiftEntries = {},
        shapeshiftIdx     = 0,
        numShapeshifts    = 0,
        restricted        = false,
    }

    local now = (GetTime and SafeCall(GetTime)) or 0
    local totalSlots = 0
    local readableSlots = 0

    local function RecordAura(spellId, name, duration, expirationTime)
        local remaining = nil
        local durVal = IsAccessible(duration) and tonumber(duration) or 0
        local expVal = IsAccessible(expirationTime) and tonumber(expirationTime) or 0
        if durVal and durVal > 0 and expVal and expVal > 0 then
            remaining = math.max(0, expVal - now)
        end
        local info = { remaining = remaining, duration = durVal }
        if IsAccessible(spellId) and type(spellId) == "number" then
            local prev = state.activeIDs[spellId]
            if not prev or not prev.remaining or (info.remaining and info.remaining > prev.remaining) then
                state.activeIDs[spellId] = info
            end
        end
        if IsAccessible(name) and type(name) == "string" and name ~= "" then
            local key = string.lower(name)
            local prev = state.activeNames[key]
            if not prev or not prev.remaining or (info.remaining and info.remaining > prev.remaining) then
                state.activeNames[key] = info
            end
        end
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 80 do
            local aura = SafeCall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not aura then break end
            totalSlots = totalSlots + 1
            if type(aura) == "table" then
                local hasReadable = IsAccessible(aura.spellId) or IsAccessible(aura.name)
                if hasReadable then
                    readableSlots = readableSlots + 1
                    RecordAura(aura.spellId, aura.name, aura.duration, aura.expirationTime)
                end
            end
        end
    elseif UnitBuff then
        for i = 1, 80 do
            local name, _, _, _, duration, expirationTime, _, _, _, spellId = SafeCall(UnitBuff, "player", i)
            if not IsAccessible(name) and not IsAccessible(spellId) then
                if name == nil and spellId == nil then break end
                totalSlots = totalSlots + 1
            else
                totalSlots = totalSlots + 1
                readableSlots = readableSlots + 1
                RecordAura(spellId, name, duration, expirationTime)
            end
        end
    end

    local globalSecret = (C_Secrets and C_Secrets.ShouldAurasBeSecret and SafeCall(C_Secrets.ShouldAurasBeSecret)) == true
    if globalSecret then
        state.restricted = true
    elseif totalSlots > 0 and readableSlots == 0 and InCombatLockdown and InCombatLockdown() then
        state.restricted = true
    end

    if GetShapeshiftForm then
        local rawForm = SafeCall(GetShapeshiftForm)
        state.shapeshiftIdx = (IsAccessible(rawForm) and tonumber(rawForm)) or 0
    end
    if GetNumShapeshiftForms and GetShapeshiftFormInfo then
        local rawNumForms = SafeCall(GetNumShapeshiftForms)
        local numForms = (IsAccessible(rawNumForms) and tonumber(rawNumForms)) or 0
        state.numShapeshifts = numForms
        for i = 1, numForms do
            local icon, active, castable, spellID = SafeCall(GetShapeshiftFormInfo, i)
            local sid = (IsAccessible(spellID) and type(spellID) == "number") and spellID or nil
            local sName = sid and GetSpellNameCompat(sid) or nil
            local isAct = (IsAccessible(active) and active == true) or (state.shapeshiftIdx > 0 and state.shapeshiftIdx == i)
            state.shapeshiftEntries[#state.shapeshiftEntries + 1] = {
                index    = i,
                active   = isAct,
                castable = (IsAccessible(castable) and castable == true) or false,
                spellID  = sid,
                name     = sName,
                icon     = IsAccessible(icon) and icon or nil,
            }
            if isAct and sid then
                state.shapeshiftIDs[sid] = true
                if sName then
                    state.shapeshiftNames[string.lower(sName)] = true
                end
            end
        end
    end

    return state
end

local function IsGroupActive(auraState, rankGroups)
    -- rankGroups can be a flat list of spellIDs or list of lists
    if type(rankGroups) ~= "table" then return false, nil end
    local bestInfo = nil

    local function CheckID(sid)
        if type(sid) ~= "number" then return false end
        if auraState.activeIDs[sid] then
            bestInfo = auraState.activeIDs[sid]
            return true
        end
        if auraState.shapeshiftIDs[sid] then
            bestInfo = { remaining = nil, duration = 0 }
            return true
        end
        local sName = GetSpellNameCompat(sid)
        if sName then
            local key = string.lower(sName)
            if auraState.activeNames[key] then
                bestInfo = auraState.activeNames[key]
                return true
            end
            if auraState.shapeshiftNames[key] then
                bestInfo = { remaining = nil, duration = 0 }
                return true
            end
        end
        if C_Secrets and C_Secrets.ShouldSpellAuraBeSecret then
            local sec = SafeCall(C_Secrets.ShouldSpellAuraBeSecret, sid)
            if sec then return false end
        end
        if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
            local aura = SafeCall(C_UnitAuras.GetPlayerAuraBySpellID, sid)
            if type(aura) == "table" and (IsAccessible(aura.spellId) or IsAccessible(aura.name)) then
                local rem = nil
                local dur = IsAccessible(aura.duration) and tonumber(aura.duration) or 0
                local exp = IsAccessible(aura.expirationTime) and tonumber(aura.expirationTime) or 0
                if dur > 0 and exp > 0 then
                    rem = math.max(0, exp - ((GetTime and SafeCall(GetTime)) or 0))
                end
                bestInfo = { remaining = rem, duration = dur }
                return true
            end
        end
        return false
    end

    for _, item in ipairs(rankGroups) do
        if type(item) == "table" then
            for _, sid in ipairs(item) do
                if CheckID(sid) then return true, bestInfo end
            end
        elseif CheckID(item) then
            return true, bestInfo
        end
    end
    return false, nil
end

-------------------------------------------------------------------------------
-- Minimap Tracking & Profession Detection
-------------------------------------------------------------------------------
local supportsMultiTracking = false

local function ReadTrackingEntry(idx)
    local fn = (C_Minimap and C_Minimap.GetTrackingInfo) or GetTrackingInfo
    if type(fn) ~= "function" then return nil end
    local r1, r2, r3, _, _, r6 = SafeCall(fn, idx)
    if type(r1) == "table" then
        local tex = (IsAccessible(r1.textureFileID) and r1.textureFileID)
            or (IsAccessible(r1.texture) and r1.texture)
            or (IsAccessible(r1.icon) and r1.icon)
            or nil
        return {
            index   = idx,
            name    = IsAccessible(r1.name) and r1.name or nil,
            texture = tex,
            active  = IsAccessible(r1.active) and (r1.active == true) or false,
            spellID = IsAccessible(r1.spellID) and r1.spellID or nil,
        }
    elseif IsAccessible(r1) then
        return {
            index   = idx,
            name    = r1,
            texture = IsAccessible(r2) and r2 or nil,
            active  = IsAccessible(r3) and (r3 == true) or false,
            spellID = IsAccessible(r6) and r6 or nil,
        }
    end
    return nil
end

local function ScanMinimapTracking(auraState)
    local entries = {}
    local activeCount = 0
    local numFn = (C_Minimap and C_Minimap.GetNumTrackingTypes) or GetNumTrackingTypes
    if type(numFn) == "function" then
        local total = tonumber(SafeCall(numFn)) or 0
        for i = 1, total do
            local entry = ReadTrackingEntry(i)
            if entry then
                entries[#entries + 1] = entry
                if entry.active then
                    activeCount = activeCount + 1
                end
            end
        end
    end

    if activeCount >= 2 then
        supportsMultiTracking = true
    end

    local activeTrackingTex = nil
    if GetTrackingTexture then
        local tex = SafeCall(GetTrackingTexture)
        if IsAccessible(tex) then activeTrackingTex = tex end
    end

    local function FindMatch(spellID, nameAliases, knownTextures)
        local targetName = GetSpellNameCompat(spellID)
        local targetNameLow = targetName and string.lower(targetName) or nil
        local targetTex = GetSpellTextureCompat(spellID)
        local targetTexStr = targetTex and tostring(targetTex) or nil

        local texSet = {}
        if type(knownTextures) == "table" then
            for _, t in ipairs(knownTextures) do
                texSet[t] = true
                texSet[tostring(t)] = true
            end
        end

        for _, entry in ipairs(entries) do
            local eNameLow = entry.name and string.lower(entry.name) or nil
            local eTexStr = entry.texture and tostring(entry.texture) or nil
            local matched = (entry.spellID and entry.spellID == spellID)
                or (targetNameLow and eNameLow and eNameLow == targetNameLow)
                or (targetTex and entry.texture and (entry.texture == targetTex or eTexStr == targetTexStr))
                or (entry.texture and (texSet[entry.texture] or texSet[eTexStr]))

            if not matched and eNameLow and type(nameAliases) == "table" then
                for _, alias in ipairs(nameAliases) do
                    if string.find(eNameLow, alias, 1, true) then
                        matched = true
                        break
                    end
                end
            end

            if matched then
                return true, entry.active == true, entry
            end
        end

        -- Fallback: pure Classic clients without C_Minimap.GetTrackingInfo list
        local knownDirect = IsSpellKnownCompat(spellID)
        if not knownDirect and targetNameLow then
            if not spellbookLoaded then RebuildSpellbookCache() end
            knownDirect = spellbookByName[targetNameLow] ~= nil
        end
        if knownDirect then
            local isActive = false
            if activeTrackingTex and targetTex and (activeTrackingTex == targetTex or tostring(activeTrackingTex) == targetTexStr) then
                isActive = true
            elseif IsGroupActive(auraState, { spellID }) then
                isActive = true
            end
            return true, isActive, nil
        end

        return false, false, nil
    end

    return {
        entries      = entries,
        activeCount  = activeCount,
        hasAnyActive = (activeCount > 0) or (activeTrackingTex ~= nil),
        FindMatch    = FindMatch,
    }
end

local PROF_SPELLS = {
    MINING         = { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161, 158754, 195122, 2656, 2580 },
    HERBALISM      = { 2366, 2368, 3570, 11993, 28695, 50300, 74519, 110413, 158745, 195114, 2383 },
    FISHING        = { 7620, 7731, 7732, 18248, 33095, 51294, 88868, 110410, 131474, 158743, 43308 },
    BLACKSMITHING  = { 2018, 3100, 3538, 9785, 29844, 51300 },
    ENCHANTING     = { 7411, 7412, 7413, 13920, 28029, 51313 },
    ALCHEMY        = { 2259, 3101, 3464, 11611, 28596, 51304 },
}

local SKILLLINE_TO_KEY = {
    [186] = "MINING",
    [182] = "HERBALISM",
    [356] = "FISHING",
    [164] = "BLACKSMITHING",
    [333] = "ENCHANTING",
    [171] = "ALCHEMY",
}

local function DetectPlayerProfessions()
    local profs = {}

    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local indices = { SafeCall(GetProfessions) }
        for k = 1, 6 do
            local idx = indices[k]
            if idx then
                local name, _, _, _, _, _, skillLine = SafeCall(GetProfessionInfo, idx)
                local key = skillLine and SKILLLINE_TO_KEY[skillLine]
                if key then
                    profs[key] = IsAccessible(name) and name or key
                end
            end
        end
    end

    -- Fallback: localized skill lines & spell checks
    local nameToKey = {}
    for pKey, ids in pairs(PROF_SPELLS) do
        local baseName = GetSpellNameCompat(ids[1])
        if baseName then
            nameToKey[string.lower(baseName)] = pKey
        end
        for _, sid in ipairs(ids) do
            if IsSpellKnownCompat(sid) then
                if not profs[pKey] then
                    profs[pKey] = GetSpellNameCompat(ids[1]) or pKey
                end
                break
            end
        end
    end

    if GetNumSkillLines and GetSkillLineInfo then
        local num = tonumber(SafeCall(GetNumSkillLines)) or 0
        for i = 1, num do
            local sName, isHeader = SafeCall(GetSkillLineInfo, i)
            if not isHeader and IsAccessible(sName) and sName ~= "" then
                local key = nameToKey[string.lower(sName)]
                if key and not profs[key] then
                    profs[key] = sName
                end
            end
        end
    end

    return profs
end

-------------------------------------------------------------------------------
-- Player Spec / Role & Equipment Helpers
-------------------------------------------------------------------------------
local function DetectRoleAndSpec()
    local classTag = select(2, UnitClass("player")) or "WARRIOR"
    local raceTag = select(2, UnitRace("player")) or ""
    local rawLvl = SafeCall(UnitLevel, "player")
    local level = (IsAccessible(rawLvl) and type(rawLvl) == "number" and rawLvl) or 1
    local role = "DAMAGER"
    local tabIdx = nil
    local tabPts = 0

    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    if type(getSpec) == "function" and type(getSpecInfo) == "function" then
        local idx = SafeCall(getSpec)
        if IsAccessible(idx) and idx then
            tabIdx = idx
            local _, _, _, _, specRole = SafeCall(getSpecInfo, idx)
            if IsAccessible(specRole) and (specRole == "TANK" or specRole == "HEALER" or specRole == "DAMAGER") then
                role = specRole
            end
        end
    elseif type(GetNumTalentTabs) == "function" and type(GetTalentTabInfo) == "function" then
        local rawNumTabs = SafeCall(GetNumTalentTabs)
        local numTabs = (IsAccessible(rawNumTabs) and tonumber(rawNumTabs)) or 0
        for t = 1, numTabs do
            local _, _, pointsSpent = SafeCall(GetTalentTabInfo, t)
            if IsAccessible(pointsSpent) and type(pointsSpent) == "number" and pointsSpent > tabPts then
                tabPts = pointsSpent
                tabIdx = t
            end
        end
        if tabPts >= 1 then
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

    local isShieldEquipped = false
    if GetInventoryItemID and GetItemInfo then
        local offhandID = SafeCall(GetInventoryItemID, "player", 17)
        if offhandID then
            local _, _, _, _, _, _, _, _, itemEquipLoc = SafeCall(GetItemInfo, offhandID)
            if itemEquipLoc == "INVTYPE_SHIELD" then
                isShieldEquipped = true
            end
        end
    end

    if (classTag == "PALADIN" and (tabIdx == 2 or isShieldEquipped))
        or (classTag == "WARRIOR" and (tabIdx == 3 or isShieldEquipped)) then
        role = "TANK"
    end

    local rawManaMax = SafeCall(UnitPowerMax, "player", 0)
    local rawManaCur = SafeCall(UnitPower, "player", 0)
    local manaMax = (IsAccessible(rawManaMax) and tonumber(rawManaMax)) or 0
    local manaCur = (IsAccessible(rawManaCur) and tonumber(rawManaCur)) or 0
    local manaPct = (manaMax > 0) and (manaCur / manaMax) or 1

    return {
        classTag = classTag,
        raceTag  = raceTag,
        level    = level,
        role     = role,
        tabIdx   = tabIdx,
        tabPts   = tabPts,
        isShieldEquipped = isShieldEquipped,
        manaMax  = manaMax,
        manaPct  = manaPct,
        isMounted = IsMounted and SafeCall(IsMounted) or false,
        isFlying  = IsFlying and SafeCall(IsFlying) or false,
        isStealthed = IsStealthed and SafeCall(IsStealthed) or false,
        isSwimming  = (IsSwimming and SafeCall(IsSwimming)) or (IsSubmerged and SafeCall(IsSubmerged)) or false,
        inCombat    = InCombatLockdown and InCombatLockdown() or false,
        inInstance  = (function()
            if IsInInstance then
                local inInst, instType = SafeCall(IsInInstance)
                return inInst == true and (instType == "party" or instType == "raid" or instType == "scenario")
            end
            return false
        end)(),
    }
end

local function InspectEquippedWeapons()
    local mhID = GetInventoryItemID and SafeCall(GetInventoryItemID, "player", 16)
    local ohID = GetInventoryItemID and SafeCall(GetInventoryItemID, "player", 17)

    local mhClass, mhSub
    if mhID then
        local _, _, _, _, _, cID, sID = GetItemInfoInstantCompat(mhID)
        mhClass, mhSub = cID, sID
    end
    local ohClass, ohSub
    if ohID then
        local _, _, _, _, _, cID, sID = GetItemInfoInstantCompat(ohID)
        ohClass, ohSub = cID, sID
    end

    local weaponClassID = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
    local fishingSubID = (Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole) or 20

    local hasMH, mhExpMs, _, _, hasOH, ohExpMs = false, 0, nil, nil, false, 0
    if GetWeaponEnchantInfo then
        local rMH, rMHExp, _, _, rOH, rOHExp = SafeCall(GetWeaponEnchantInfo)
        if IsAccessible(rMH) then hasMH = rMH == true end
        if IsAccessible(rMHExp) then mhExpMs = tonumber(rMHExp) or 0 end
        if IsAccessible(rOH) then hasOH = rOH == true end
        if IsAccessible(rOHExp) then ohExpMs = tonumber(rOHExp) or 0 end
    end

    local isFishingPole = (mhClass == weaponClassID and mhSub == fishingSubID)
    local mhIsWeapon = (mhID ~= nil and mhClass == weaponClassID and not isFishingPole)
    local ohIsWeapon = (ohID ~= nil and ohClass == weaponClassID and ohSub ~= fishingSubID)

    -- 4=1H Mace, 5=2H Mace, 10=Staff
    local mhIsBlunt = (mhSub == 4 or mhSub == 5 or mhSub == 10)
    -- 0=1H Axe, 1=2H Axe, 6=Polearm, 7=1H Sword, 8=2H Sword, 13=Fist, 15=Dagger
    local mhIsEdged = (mhSub == 0 or mhSub == 1 or mhSub == 6 or mhSub == 7 or mhSub == 8 or mhSub == 13 or mhSub == 15)

    return {
        isFishingPole = isFishingPole,
        mhIsWeapon    = mhIsWeapon,
        ohIsWeapon    = ohIsWeapon,
        mhIsBlunt     = mhIsBlunt,
        mhIsEdged     = mhIsEdged,
        hasMH         = hasMH,
        mhRemaining   = hasMH and (mhExpMs / 1000) or 0,
        hasOH         = hasOH,
        ohRemaining   = hasOH and (ohExpMs / 1000) or 0,
    }
end

-------------------------------------------------------------------------------
-- Rank Tables & Consumable Catalogs (Classic / TBC / Forever + Modern)
-------------------------------------------------------------------------------
local CLASS_SPELLS = {
    -- Mage
    ARCANE_INTELLECT = { 1459, 1460, 1461, 10156, 10157, 27126, 42995, 23028, 27127, 43002, 61024, 61316 },
    FROST_ARMOR      = { 168, 7300, 7301 },
    ICE_ARMOR        = { 7302, 7320, 10219, 10220, 27124, 43008 },
    MAGE_ARMOR       = { 6117, 22782, 22783, 27125, 43024 },
    MOLTEN_ARMOR     = { 30482, 43046 },

    -- Priest
    FORTITUDE        = { 1243, 1244, 1245, 2791, 10937, 10938, 25389, 48161, 21562, 21564, 27681, 48162 },
    INNER_FIRE       = { 588, 7128, 602, 1006, 10951, 10952, 25431, 48168 },
    DIVINE_SPIRIT    = { 14752, 14818, 14819, 27841, 48073, 27681, 32999, 48074 },
    SHADOW_PROT      = { 976, 10957, 10958, 25433, 48169, 27683, 39374, 48170 },
    SHADOWFORM       = { 15473, 232698 },

    -- Druid
    MARK_OF_WILD     = { 1126, 5232, 6756, 5234, 8907, 9884, 9885, 26990, 48469, 21849, 21850, 26991, 48470 },
    THORNS           = { 467, 782, 1075, 8914, 9756, 9910, 26992, 53307 },
    OMEN_OF_CLARITY  = { 16864 },
    MOONKIN_FORM     = { 24858 },

    -- Paladin (active toggleable auras & blessings; skip passive/cooldown IDs like 183435 / 31821)
    DEVOTION_AURA      = { 465, 10290, 643, 10291, 1032, 10292, 10293, 27149, 48942 },
    RETRIBUTION_AURA   = { 7294, 10298, 10299, 10300, 10301, 27150, 54043 },
    CONCENTRATION_AURA = { 19746, 317920 },
    SANCTITY_AURA      = { 20218 },
    CRUSADER_AURA      = { 32223 },
    OTHER_PAL_AURAS    = { 19876, 19895, 19896, 27151, 19888, 19897, 19898, 27152, 19891, 19899, 19900, 27153 },
    BLESSING_MIGHT   = { 19740, 19834, 19835, 19836, 19837, 19838, 25291, 27140, 25782, 25916, 27141 },
    BLESSING_WISDOM  = { 19742, 19850, 19852, 19853, 19854, 25290, 27142, 25894, 25918, 27143 },
    BLESSING_KINGS   = { 20217, 25898 },
    BLESSING_SANC    = { 20911, 20912, 20913, 20914, 27168, 25899, 27169 },
    BLESSING_OTHER   = { 1038, 25895, 19977, 19978, 19979, 27144, 25890, 27145 },
    RIGHTEOUS_FURY   = { 25780 },
    HOLY_SHIELD      = { 20925, 20927, 20928, 27179 },
    SEAL_RIGHTEOUSNESS = { 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293, 27155 },
    SEAL_COMMAND       = { 20375, 20915, 20918, 20919, 20920, 27170 },
    SEAL_CRUSADER      = { 20305, 20306, 20307, 20308, 20162, 20309, 27158 },
    SEAL_WISDOM        = { 20165, 20356, 20357, 27166 },
    SEAL_LIGHT         = { 20164, 20332, 20333, 20334, 27160 },
    SEAL_JUSTICE       = { 20166 },

    -- Warrior
    BATTLE_SHOUT     = { 6673, 5242, 6192, 11549, 11550, 11551, 25289, 2048, 47436 },
    COMMANDING_SHOUT = { 469, 47440 },
    BATTLE_STANCE    = { 2457, 386164 },
    DEF_STANCE       = { 71, 386208 },
    BERSERKER_STANCE = { 2458, 386196 },

    -- Hunter
    ASPECT_HAWK      = { 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044, 61846, 61847 },
    ASPECT_MONKEY    = { 13163 },
    ASPECT_CHEETAH   = { 5118, 186257 },
    ASPECT_PACK      = { 13159 },
    ASPECT_VIPER     = { 34074 },
    ASPECT_OTHER     = { 13161, 20043, 20190, 27045 },
    CALL_PET         = { 883 },
    REVIVE_PET       = { 982 },
    TRUESHOT_AURA    = { 19506, 20905, 20906, 27066 },

    -- Warlock
    DEMON_SKIN       = { 687, 696 },
    DEMON_ARMOR      = { 706, 1086, 11733, 11734, 11735, 27260, 47889 },
    FEL_ARMOR        = { 28176, 28189, 47893 },
    SUMMON_IMP       = { 688 },
    SUMMON_VOID      = { 697 },
    SUMMON_FELGUARD  = { 30146 },
    SOUL_LINK        = { 19028 },
    UNENDING_BREATH  = { 5697 },

    -- Shaman
    LIGHTNING_SHIELD = { 324, 325, 905, 945, 8134, 10431, 10432, 25469, 25472, 49281, 192106 },
    WATER_SHIELD     = { 24398, 33736, 52127, 57960 },
    EARTH_SHIELD     = { 974, 32593, 32594, 49284 },
    WINDFURY_WEAP    = { 8232, 8235, 10486, 16362, 25505, 58804, 33757 },
    FLAMETONGUE_WEAP = { 8024, 8027, 8030, 16339, 16341, 16342, 25489, 58790, 318038 },
    FROSTBRAND_WEAP  = { 8033, 8038, 10456, 16355, 16356, 25500 },
    ROCKBITER_WEAP   = { 8017, 8018, 8019, 10399, 16314, 16315, 16316, 25479, 25485 },
    DUAL_WIELD       = { 30798, 674 },

    -- Rogue (modern poison spells)
    ROGUE_POISON_SPELLS = {
        { 315584, 2823, 8679, 3408, 5761 },
    },

    -- Hero / Additional Retail classes (only suggested if player actually is that class & knows the spell)
    HORN_OF_WINTER   = { 57330 },
    DK_PRESENCES     = { 48263, 48266, 48265 },
    LEGACY_EMPEROR   = { 115921, 116781 },
    BRONZE_BLESSING  = { 364342, 381748 },
}

-- Highest tier first so best item in player's bags is chosen
local FISHING_LURES = { 34861, 6533, 7307, 6532, 6530, 6529 }
local SHARPENING_STONES = { 23529, 28420, 12404, 7964, 2871, 2863, 2862 }
local WEIGHTSTONES = { 28421, 23528, 12643, 7965, 3241, 3240, 3239 }
local WIZARD_OILS = { 22522, 20749, 20750, 22521, 20748, 20747, 20746, 20745, 20744 }
local ROGUE_POISON_ITEMS = {
    21927, 8928, 8927, 8926, 6950, 6949, 6947, -- Instant Poison
    22054, 22053, 20844, 8985, 8984, 2893, 2892, -- Deadly Poison
    22055, 10922, 10921, 10920, 10918, -- Wound Poison
    3776, 3775, -- Crippling Poison
}
local DUNGEON_ELIXIRS = {
    22831, 13452, 22824, 22823, 9155, 13445, 9088, 6373, 3390, 3389, 3388, 2458, 2454, 3382,
}

-------------------------------------------------------------------------------
-- Recommendation Engine
-------------------------------------------------------------------------------
local dismissedKeys = {}
local snoozedKeys = {}
local currentSuggestions = {}

local TRACKING_HINTS = {
    MINING = {
        aliases  = { "mineral", "erz", "gisement", "minerai", "giaciment", "минерал", "руд" },
        textures = { 136025, 134708, 136248, 4620675, "Interface\\Icons\\Spell_Nature_Earthquake", "Interface\\Icons\\INV_Pick_02" },
    },
    HERBALISM = {
        aliases  = { "herb", "erb", "kräut", "plantes", "hierb", "трав" },
        textures = { 133939, 136065, 136246, 4620673, "Interface\\Icons\\INV_Misc_Flower_02" },
    },
    FISHING = {
        aliases  = { "fish", "pesc", "fisch", "poisson", "peces", "рыб" },
        textures = { 133888, 136245, "Interface\\Icons\\INV_Misc_Fish_02" },
    },
}

local function PickBestBagItem(itemList)
    for _, itemID in ipairs(itemList) do
        if GetItemCountCompat(itemID) > 0 then
            return itemID
        end
    end
    return nil
end

local function ShouldRecommendExpiring(info, minDurRequired)
    if not info or not info.remaining then return false end
    local minD = minDurRequired or 120
    if info.duration and info.duration < minD then
        return false
    end
    local thr = GetExpiringThreshold()
    if info.duration and info.duration > 0 and thr >= info.duration then
        thr = math.max(30, info.duration * 0.5)
    end
    return info.remaining > 0 and info.remaining <= thr
end

local function EvaluateRecommendations()
    local L = FP.L or {}
    local out = {}

    if not IsAdvisorEnabled() then return out end
    if UnitIsDeadOrGhost and SafeCall(UnitIsDeadOrGhost, "player") then return out end
    if UnitOnTaxi and SafeCall(UnitOnTaxi, "player") then return out end
    if UnitHasVehicleUI and SafeCall(UnitHasVehicleUI, "player") then return out end
    local s = GetBuffSettings()
    if s.buffHideResting and IsResting and SafeCall(IsResting) then return out end

    local ctx = DetectRoleAndSpec()
    local auras = ScanPlayerAurasAndForms()
    local tracking = ScanMinimapTracking(auras)
    local profs = DetectPlayerProfessions()
    local weap = InspectEquippedWeapons()

    local function PushSuggestion(entry)
        if not entry or not entry.key then return end
        if dismissedKeys[entry.key] or snoozedKeys[entry.key] then return end
        out[#out + 1] = entry
    end

    local function CheckBuffSuggestion(opts)
        if auras.restricted then return end
        if opts.skipIfStealthed and ctx.isStealthed then return end
        if opts.skipIfMounted and (ctx.isMounted or ctx.isFlying) then return end

        local active, activeInfo = IsGroupActive(auras, opts.satisfiedBy or { opts.ranks })
        local expiring = active and ShouldRecommendExpiring(activeInfo, opts.minDur)

        if active and not expiring and opts.key then
            snoozedKeys[opts.key] = nil
        end

        if not active or expiring then
            local sid, sName = FindKnownSpell(opts.ranks)
            if not sid then return end
            local usable, noResource = IsSpellUsableCompat(sid)
            local icon = GetSpellTextureCompat(sid) or "Interface\\Icons\\INV_Misc_QuestionMark"
            local displayName = sName or GetSpellNameCompat(sid) or "Buff"
            local remSec = expiring and math.ceil(activeInfo.remaining) or nil

            PushSuggestion({
                key        = opts.key,
                priority   = expiring and ((opts.priority or 50) + 5) or (opts.priority or 50),
                actionType = "spell",
                spellID    = sid,
                castSpell  = sid,
                name       = displayName,
                icon       = icon,
                usable     = usable,
                noResource = noResource,
                expiring   = remSec,
                badge      = remSec and (remSec .. "s") or (opts.badge or L["BUFF_BADGE_MISSING"] or "BUFF"),
                kind       = expiring and "expiring" or (opts.kind or "buff"),
                reason     = expiring
                    and string.format(L["BUFF_REASON_EXPIRING"] or "Buff expiring soon (%ds left)", remSec)
                    or (opts.reason or string.format(L["BUFF_REASON_CLASS_MISSING"] or "Recommended %s buff is missing", displayName)),
            })
        end
    end

    ---------------------------------------------------------------------------
    -- 1. Profession & Utility Tracking ("Find Minerals", "Find Herbs", etc.)
    ---------------------------------------------------------------------------
    local trackingEnabled = (s.buffCheckTracking ~= false)
    local hasPrimaryGathering = false

    local function TryAddTracking(spellID, opts)
        if not trackingEnabled then return false end
        local hints = opts.hintKey and TRACKING_HINTS[opts.hintKey] or nil
        local known, active, tEntry = tracking.FindMatch(
            spellID,
            hints and hints.aliases or nil,
            hints and hints.textures or nil
        )
        if not known and opts.forceIfProf and profs[opts.forceIfProf] then
            known = IsSpellKnownCompat(spellID) or (tEntry ~= nil)
        end
        if not known then return false end

        if opts.isGathering then
            hasPrimaryGathering = true
        end

        if active then
            if opts.key then
                snoozedKeys[opts.key] = nil
            end
            return true
        end

        if opts.secondaryOnly and not supportsMultiTracking and (tracking.hasAnyActive or hasPrimaryGathering) then
            return false
        end

        local name = (tEntry and tEntry.name) or GetSpellNameCompat(spellID) or opts.fallbackName
        local icon = (tEntry and tEntry.texture) or GetSpellTextureCompat(spellID) or "Interface\\Icons\\Spell_Nature_Earthquake"
        local profLabel = opts.profKey and (profs[opts.profKey] or opts.fallbackProf) or nil
        local reason = profLabel
            and string.format(L["BUFF_REASON_PROF_TRACKING"] or "Profession: %s (tracking inactive)", profLabel)
            or (L["BUFF_REASON_RACIAL_TRACKING"] or "Tracking is inactive")

        PushSuggestion({
            key           = opts.key,
            priority      = opts.priority or 10,
            actionType    = (tEntry and C_Minimap and C_Minimap.SetTracking) and "tracking" or "spell",
            trackingIndex = tEntry and tEntry.index or nil,
            spellID       = spellID,
            castSpell     = spellID,
            name          = name,
            icon          = icon,
            usable        = true,
            badge         = opts.badge or (L["BUFF_BADGE_FIND"] or "TRACK"),
            kind          = "tracking",
            reason        = reason,
        })
        return false
    end

    if profs.MINING or select(1, tracking.FindMatch(2580, TRACKING_HINTS.MINING.aliases, TRACKING_HINTS.MINING.textures)) then
        TryAddTracking(2580, {
            key = "TRACK_MINERALS", priority = 10, profKey = "MINING", forceIfProf = "MINING",
            hintKey = "MINING", fallbackName = "Find Minerals", fallbackProf = "Mining", isGathering = true,
        })
    end

    if profs.HERBALISM or select(1, tracking.FindMatch(2383, TRACKING_HINTS.HERBALISM.aliases, TRACKING_HINTS.HERBALISM.textures)) then
        TryAddTracking(2383, {
            key = "TRACK_HERBS", priority = 12, profKey = "HERBALISM", forceIfProf = "HERBALISM",
            hintKey = "HERBALISM", fallbackName = "Find Herbs", fallbackProf = "Herbalism", isGathering = true,
        })
    end

    -- Find Fish (only push if Fishing Pole equipped OR no higher-priority tracking active)
    if profs.FISHING then
        local fishKnown = select(1, tracking.FindMatch(43308, TRACKING_HINTS.FISHING.aliases, TRACKING_HINTS.FISHING.textures))
        if fishKnown then
            TryAddTracking(43308, {
                key = "TRACK_FISH", priority = weap.isFishingPole and 8 or 25,
                profKey = "FISHING", hintKey = "FISHING", fallbackName = "Find Fish", fallbackProf = "Fishing",
                secondaryOnly = not weap.isFishingPole,
            })
        end
        if s.buffCheckProfessionItems ~= false and weap.isFishingPole and not weap.hasMH then
            local lureID = PickBestBagItem(FISHING_LURES)
            if lureID then
                PushSuggestion({
                    key        = "PROF_FISHING_LURE",
                    priority   = 9,
                    actionType = "item",
                    itemID     = lureID,
                    targetSlot = 16,
                    name       = GetItemNameCompat(lureID) or "Fishing Lure",
                    icon       = GetItemIconCompat(lureID) or "Interface\\Icons\\INV_Misc_Orb_03",
                    usable     = true,
                    badge      = L["BUFF_BADGE_WEAPON"] or "LURE",
                    kind       = "profession",
                    reason     = L["BUFF_REASON_FISHING_LURE"] or "Fishing Pole equipped: apply lure",
                })
            end
        end
    end

    -- Dwarf Find Treasure (non-intrusive: only if no gathering tracker conflict)
    if select(1, tracking.FindMatch(2481)) then
        TryAddTracking(2481, {
            key = "TRACK_TREASURE", priority = 28, fallbackName = "Find Treasure", secondaryOnly = true,
        })
    end

    -- Hunter Track Beasts / Humanoids (only when no other tracking is active)
    if ctx.classTag == "HUNTER" and not tracking.hasAnyActive and not hasPrimaryGathering then
        local huntTrack = select(1, tracking.FindMatch(19883)) and 19883
            or (select(1, tracking.FindMatch(1494)) and 1494)
        if huntTrack then
            TryAddTracking(huntTrack, {
                key = "TRACK_HUNTER", priority = 30,
                fallbackName = (huntTrack == 19883) and "Track Humanoids" or "Track Beasts",
                secondaryOnly = true,
            })
        end
    end

    ---------------------------------------------------------------------------
    -- 2. Class Buffs, Auras, Aspects, Armors, Pets & Imbues
    ---------------------------------------------------------------------------
    local cls = ctx.classTag

    if s.buffCheckClass == false then
        -- Class buffs disabled in settings; skip section 2
    elseif cls == "MAGE" then
        CheckBuffSuggestion({
            key = "MAGE_INT", priority = 20, ranks = CLASS_SPELLS.ARCANE_INTELLECT,
            skipIfStealthed = true, minDur = 120,
        })
        -- Choose best Armor when none is active
        local hasArmor, armorInfo = IsGroupActive(auras, {
            CLASS_SPELLS.FROST_ARMOR, CLASS_SPELLS.ICE_ARMOR, CLASS_SPELLS.MAGE_ARMOR, CLASS_SPELLS.MOLTEN_ARMOR
        })
        if not auras.restricted and (not hasArmor or ShouldRecommendExpiring(armorInfo, 120)) then
            local armorRanks = CLASS_SPELLS.ICE_ARMOR
            if ctx.tabIdx == 2 and ctx.tabPts >= 10 and FindKnownSpell(CLASS_SPELLS.MOLTEN_ARMOR) then
                armorRanks = CLASS_SPELLS.MOLTEN_ARMOR
            elseif ctx.manaPct < 0.45 and FindKnownSpell(CLASS_SPELLS.MAGE_ARMOR) then
                armorRanks = CLASS_SPELLS.MAGE_ARMOR
            elseif not FindKnownSpell(CLASS_SPELLS.ICE_ARMOR) then
                if FindKnownSpell(CLASS_SPELLS.FROST_ARMOR) then
                    armorRanks = CLASS_SPELLS.FROST_ARMOR
                elseif FindKnownSpell(CLASS_SPELLS.MOLTEN_ARMOR) then
                    armorRanks = CLASS_SPELLS.MOLTEN_ARMOR
                elseif FindKnownSpell(CLASS_SPELLS.MAGE_ARMOR) then
                    armorRanks = CLASS_SPELLS.MAGE_ARMOR
                end
            end
            CheckBuffSuggestion({
                key = "MAGE_ARMOR", priority = 22, ranks = armorRanks,
                satisfiedBy = { CLASS_SPELLS.FROST_ARMOR, CLASS_SPELLS.ICE_ARMOR, CLASS_SPELLS.MAGE_ARMOR, CLASS_SPELLS.MOLTEN_ARMOR },
                minDur = 120,
            })
        end

    elseif cls == "PRIEST" then
        CheckBuffSuggestion({
            key = "PRIEST_FORT", priority = 20, ranks = CLASS_SPELLS.FORTITUDE, minDur = 120,
        })
        CheckBuffSuggestion({
            key = "PRIEST_INNER_FIRE", priority = 22, ranks = CLASS_SPELLS.INNER_FIRE, minDur = 120,
        })
        CheckBuffSuggestion({
            key = "PRIEST_SPIRIT", priority = 24, ranks = CLASS_SPELLS.DIVINE_SPIRIT, minDur = 120,
        })
        if ctx.inInstance then
            CheckBuffSuggestion({
                key = "PRIEST_SHADOW_PROT", priority = 28, ranks = CLASS_SPELLS.SHADOW_PROT, minDur = 120,
            })
        end
        if ctx.role ~= "HEALER" and not ctx.isMounted then
            CheckBuffSuggestion({
                key = "PRIEST_SHADOWFORM", priority = 25, ranks = CLASS_SPELLS.SHADOWFORM, skipIfMounted = true,
            })
        end

    elseif cls == "DRUID" then
        if not ctx.isStealthed then
            CheckBuffSuggestion({
                key = "DRUID_MOTW", priority = 20, ranks = CLASS_SPELLS.MARK_OF_WILD,
                skipIfStealthed = true, minDur = 120,
            })
            CheckBuffSuggestion({
                key = "DRUID_THORNS", priority = 24, ranks = CLASS_SPELLS.THORNS,
                skipIfStealthed = true, skipIfMounted = true, minDur = 120,
            })
        end
        CheckBuffSuggestion({
            key = "DRUID_OOC", priority = 26, ranks = CLASS_SPELLS.OMEN_OF_CLARITY, minDur = 120,
        })
        if ctx.tabIdx == 1 and ctx.tabPts >= 10 and not ctx.isMounted and auras.numShapeshifts > 0 and auras.shapeshiftIdx == 0 then
            CheckBuffSuggestion({
                key = "DRUID_MOONKIN", priority = 28, ranks = CLASS_SPELLS.MOONKIN_FORM, skipIfMounted = true,
            })
        end

    elseif cls == "PALADIN" then
        local allAuras = {
            CLASS_SPELLS.DEVOTION_AURA, CLASS_SPELLS.RETRIBUTION_AURA, CLASS_SPELLS.CONCENTRATION_AURA,
            CLASS_SPELLS.SANCTITY_AURA, CLASS_SPELLS.CRUSADER_AURA, CLASS_SPELLS.OTHER_PAL_AURAS,
        }
        local hasBarAura = (auras.numShapeshifts > 0 and auras.shapeshiftIdx > 0)
        local hasAnyAura = hasBarAura or ((not auras.restricted) and IsGroupActive(auras, allAuras))
        local onCrusader = IsGroupActive(auras, { CLASS_SPELLS.CRUSADER_AURA })

        local function FindAnyNonCrusaderAura()
            local preferredRanks = CLASS_SPELLS.DEVOTION_AURA
            if ctx.role ~= "TANK" and FindKnownSpell(CLASS_SPELLS.RETRIBUTION_AURA) then
                preferredRanks = CLASS_SPELLS.RETRIBUTION_AURA
            end
            local sid, sName = FindKnownSpell(preferredRanks)
            if not sid then
                sid, sName = FindKnownSpell(CLASS_SPELLS.DEVOTION_AURA)
            end
            if not sid then
                for _, st in ipairs(auras.shapeshiftEntries) do
                    if st.spellID and st.spellID ~= 32223 then
                        sid = st.spellID
                        sName = st.name or GetSpellNameCompat(sid)
                        break
                    end
                end
            end
            return sid, sName
        end

        if ctx.isMounted then
            if onCrusader then
                snoozedKeys["PALADIN_CRUSADER_MOUNT"] = nil
            end
            local crusID, crusName = FindKnownSpell(CLASS_SPELLS.CRUSADER_AURA)
            if crusID and not onCrusader and (not auras.restricted or auras.numShapeshifts > 0) then
                PushSuggestion({
                    key        = "PALADIN_CRUSADER_MOUNT",
                    priority   = 15,
                    actionType = "spell",
                    spellID    = crusID,
                    castSpell  = crusID,
                    name       = crusName or "Crusader Aura",
                    icon       = GetSpellTextureCompat(crusID) or "Interface\\Icons\\Spell_Holy_CrusaderAura",
                    usable     = true,
                    badge      = L["BUFF_BADGE_SWITCH"] or "SWAP",
                    kind       = "switch",
                    reason     = string.format(L["BUFF_REASON_MOUNTED_AURA"] or "Mounted: switch to %s for speed", crusName or "Crusader Aura"),
                })
            elseif not crusID and not hasAnyAura and (not auras.restricted or auras.numShapeshifts > 0) then
                local sid, sName = FindAnyNonCrusaderAura()
                if sid then
                    PushSuggestion({
                        key = "PALADIN_AURA", priority = 20, actionType = "spell",
                        spellID = sid, castSpell = sid, name = sName or "Aura",
                        icon = GetSpellTextureCompat(sid) or "Interface\\Icons\\Spell_Holy_DevotionAura",
                        usable = true, badge = L["BUFF_BADGE_MISSING"] or "BUFF", kind = "buff",
                        reason = string.format(L["BUFF_REASON_CLASS_MISSING"] or "Recommended %s buff is missing", sName or "Aura"),
                    })
                end
            end
        elseif not auras.restricted or auras.numShapeshifts > 0 then
            if hasAnyAura and not onCrusader then
                snoozedKeys["PALADIN_AURA"] = nil
            end
            if onCrusader or not hasAnyAura then
                local sid, sName = FindAnyNonCrusaderAura()
                if sid then
                    local crusName = GetSpellNameCompat(32223) or "Crusader Aura"
                    PushSuggestion({
                        key        = "PALADIN_AURA",
                        priority   = onCrusader and 14 or 20,
                        actionType = "spell",
                        spellID    = sid,
                        castSpell  = sid,
                        name       = sName or "Aura",
                        icon       = GetSpellTextureCompat(sid) or "Interface\\Icons\\Spell_Holy_DevotionAura",
                        usable     = true,
                        badge      = onCrusader and (L["BUFF_BADGE_SWITCH"] or "SWAP") or (L["BUFF_BADGE_MISSING"] or "BUFF"),
                        kind       = onCrusader and "switch" or "buff",
                        reason     = onCrusader
                            and string.format(L["BUFF_REASON_DISMOUNT_AURA"] or "Not mounted: switch off %s", crusName)
                            or string.format(L["BUFF_REASON_CLASS_MISSING"] or "Recommended %s buff is missing", sName or "Aura"),
                    })
                end
            end
        end

        local isProt = (ctx.role == "TANK") or (ctx.tabIdx == 2) or (ctx.isShieldEquipped == true)
            or (FindKnownSpell(CLASS_SPELLS.BLESSING_SANC) ~= nil)
            or (FindKnownSpell(CLASS_SPELLS.HOLY_SHIELD) ~= nil)

        local allBlessings = {
            CLASS_SPELLS.BLESSING_MIGHT, CLASS_SPELLS.BLESSING_WISDOM, CLASS_SPELLS.BLESSING_KINGS,
            CLASS_SPELLS.BLESSING_SANC, CLASS_SPELLS.BLESSING_OTHER,
        }
        local blessRanks = CLASS_SPELLS.BLESSING_MIGHT
        if (ctx.role == "HEALER" or (ctx.manaPct < 0.45 and not isProt)) and FindKnownSpell(CLASS_SPELLS.BLESSING_WISDOM) then
            blessRanks = CLASS_SPELLS.BLESSING_WISDOM
        elseif isProt and FindKnownSpell(CLASS_SPELLS.BLESSING_SANC) then
            blessRanks = CLASS_SPELLS.BLESSING_SANC
        elseif FindKnownSpell(CLASS_SPELLS.BLESSING_KINGS) and (isProt or ctx.level >= 40) then
            blessRanks = CLASS_SPELLS.BLESSING_KINGS
        elseif not FindKnownSpell(CLASS_SPELLS.BLESSING_MIGHT) and FindKnownSpell(CLASS_SPELLS.BLESSING_WISDOM) then
            blessRanks = CLASS_SPELLS.BLESSING_WISDOM
        end
        CheckBuffSuggestion({
            key = "PALADIN_BLESSING", priority = 22, ranks = blessRanks,
            satisfiedBy = allBlessings, minDur = 120,
        })

        -- Righteous Fury: recommended for Protection paladins (or in tank role, or shield equipped, or protection talents)
        if (isProt or ctx.role == "TANK") and FindKnownSpell(CLASS_SPELLS.RIGHTEOUS_FURY) then
            CheckBuffSuggestion({
                key = "PALADIN_RF", priority = 26, ranks = CLASS_SPELLS.RIGHTEOUS_FURY,
            })
        end

        -- Seal (Sigillo) check: recommend appropriate Seal if player has none active
        local allSeals = {
            CLASS_SPELLS.SEAL_RIGHTEOUSNESS, CLASS_SPELLS.SEAL_COMMAND, CLASS_SPELLS.SEAL_CRUSADER,
            CLASS_SPELLS.SEAL_WISDOM, CLASS_SPELLS.SEAL_LIGHT, CLASS_SPELLS.SEAL_JUSTICE,
        }
        local hasAnySeal = (not auras.restricted) and IsGroupActive(auras, allSeals)
        if not hasAnySeal and (ctx.inCombat or UnitExists("target")) then
            local preferredSeal = CLASS_SPELLS.SEAL_RIGHTEOUSNESS
            if not isProt and FindKnownSpell(CLASS_SPELLS.SEAL_COMMAND) then
                preferredSeal = CLASS_SPELLS.SEAL_COMMAND
            elseif ctx.role == "HEALER" and FindKnownSpell(CLASS_SPELLS.SEAL_WISDOM) then
                preferredSeal = CLASS_SPELLS.SEAL_WISDOM
            end
            local sealID, sealName = FindKnownSpell(preferredSeal)
            if not sealID then
                sealID, sealName = FindKnownSpell(CLASS_SPELLS.SEAL_RIGHTEOUSNESS)
            end
            if sealID then
                CheckBuffSuggestion({
                    key = "PALADIN_SEAL", priority = 24, ranks = { sealID },
                    satisfiedBy = allSeals, minDur = 5,
                })
            end
        end

    elseif cls == "WARRIOR" then
        local shoutRanks = (ctx.role == "TANK" and FindKnownSpell(CLASS_SPELLS.COMMANDING_SHOUT))
            and CLASS_SPELLS.COMMANDING_SHOUT or CLASS_SPELLS.BATTLE_SHOUT
        CheckBuffSuggestion({
            key = "WARRIOR_SHOUT", priority = 22, ranks = shoutRanks,
            satisfiedBy = { CLASS_SPELLS.BATTLE_SHOUT, CLASS_SPELLS.COMMANDING_SHOUT },
            minDur = 9999, -- 2-min rage shout: only warn when actually dropped
        })
        local hasStance = IsGroupActive(auras, { CLASS_SPELLS.BATTLE_STANCE, CLASS_SPELLS.DEF_STANCE, CLASS_SPELLS.BERSERKER_STANCE })
        if not auras.restricted and auras.numShapeshifts > 0 and auras.shapeshiftIdx == 0 and not hasStance and not ctx.isMounted then
            local stRanks = (ctx.role == "TANK" and FindKnownSpell(CLASS_SPELLS.DEF_STANCE))
                and CLASS_SPELLS.DEF_STANCE or CLASS_SPELLS.BATTLE_STANCE
            local sid, sName = FindKnownSpell(stRanks)
            if sid then
                PushSuggestion({
                    key = "WARRIOR_STANCE", priority = 18, actionType = "spell",
                    spellID = sid, castSpell = sid, name = sName or "Stance",
                    icon = GetSpellTextureCompat(sid) or "Interface\\Icons\\Ability_Warrior_OffensiveStance",
                    usable = true, badge = L["BUFF_BADGE_MISSING"] or "BUFF", kind = "buff",
                    reason = string.format(L["BUFF_REASON_CLASS_MISSING"] or "Recommended %s buff is missing", sName or "Stance"),
                })
            end
        end

    elseif cls == "HUNTER" then
        if not auras.restricted then
            local allAspects = {
                CLASS_SPELLS.ASPECT_HAWK, CLASS_SPELLS.ASPECT_MONKEY, CLASS_SPELLS.ASPECT_CHEETAH,
                CLASS_SPELLS.ASPECT_PACK, CLASS_SPELLS.ASPECT_VIPER, CLASS_SPELLS.ASPECT_OTHER,
            }
            local hasAspect = IsGroupActive(auras, allAspects)
            local onCheetah = IsGroupActive(auras, { CLASS_SPELLS.ASPECT_CHEETAH, CLASS_SPELLS.ASPECT_PACK })
            local onViper = IsGroupActive(auras, { CLASS_SPELLS.ASPECT_VIPER })

            local dpsRanks = FindKnownSpell(CLASS_SPELLS.ASPECT_HAWK) and CLASS_SPELLS.ASPECT_HAWK or CLASS_SPELLS.ASPECT_MONKEY
            local dpsID, dpsName = FindKnownSpell(dpsRanks)

            if ctx.inCombat and onCheetah and dpsID then
                PushSuggestion({
                    key = "HUNTER_ASPECT_SWAP", priority = 14, actionType = "spell",
                    spellID = dpsID, castSpell = dpsID, name = dpsName or "Aspect",
                    icon = GetSpellTextureCompat(dpsID) or "Interface\\Icons\\Spell_Nature_RavenForm",
                    usable = true, badge = L["BUFF_BADGE_SWITCH"] or "SWAP", kind = "switch",
                    reason = string.format(L["BUFF_REASON_COMBAT_ASPECT"] or "In combat: switch off %s to avoid daze", GetSpellNameCompat(5118) or "Cheetah"),
                })
            elseif onViper and ctx.manaPct >= 0.85 and dpsID then
                PushSuggestion({
                    key = "HUNTER_ASPECT_VIPER", priority = 20, actionType = "spell",
                    spellID = dpsID, castSpell = dpsID, name = dpsName or "Aspect",
                    icon = GetSpellTextureCompat(dpsID) or "Interface\\Icons\\Spell_Nature_RavenForm",
                    usable = true, badge = L["BUFF_BADGE_SWITCH"] or "SWAP", kind = "switch",
                    reason = string.format(L["BUFF_REASON_LOW_MANA_BUFF"] or "Full mana: switch back to %s", dpsName or "Hawk"),
                })
            elseif not hasAspect then
                local pickRanks = (ctx.manaPct < 0.25 and FindKnownSpell(CLASS_SPELLS.ASPECT_VIPER))
                    and CLASS_SPELLS.ASPECT_VIPER or dpsRanks
                CheckBuffSuggestion({
                    key = "HUNTER_ASPECT", priority = 20, ranks = pickRanks, satisfiedBy = allAspects,
                })
            end
        end

        if not ctx.isMounted and not ctx.isFlying then
            local callID, callName = FindKnownSpell(CLASS_SPELLS.CALL_PET)
            if callID then
                local petExists = UnitExists and SafeCall(UnitExists, "pet")
                local petDead = petExists and UnitIsDead and SafeCall(UnitIsDead, "pet")
                if petDead then
                    local revID, revName = FindKnownSpell(CLASS_SPELLS.REVIVE_PET)
                    if revID then
                        PushSuggestion({
                            key = "HUNTER_PET", priority = 16, actionType = "spell",
                            spellID = revID, castSpell = revID, name = revName or "Revive Pet",
                            icon = GetSpellTextureCompat(revID) or "Interface\\Icons\\Ability_Hunter_BeastSoothe",
                            usable = IsSpellUsableCompat(revID), badge = L["BUFF_BADGE_PET"] or "PET", kind = "pet",
                            reason = L["BUFF_REASON_PET_DEAD"] or "Your pet is dead: revive it",
                        })
                    end
                elseif not petExists then
                    PushSuggestion({
                        key = "HUNTER_PET", priority = 16, actionType = "spell",
                        spellID = callID, castSpell = callID, name = callName or "Call Pet",
                        icon = GetSpellTextureCompat(callID) or "Interface\\Icons\\Ability_Hunter_BeastCall",
                        usable = true, badge = L["BUFF_BADGE_PET"] or "PET", kind = "pet",
                        reason = L["BUFF_REASON_PET_MISSING"] or "Companion pet is not active",
                    })
                end
            end
        end

        CheckBuffSuggestion({
            key = "HUNTER_TRUESHOT", priority = 26, ranks = CLASS_SPELLS.TRUESHOT_AURA,
        })

    elseif cls == "WARLOCK" then
        local armorRanks = FindKnownSpell(CLASS_SPELLS.FEL_ARMOR) and CLASS_SPELLS.FEL_ARMOR
            or (FindKnownSpell(CLASS_SPELLS.DEMON_ARMOR) and CLASS_SPELLS.DEMON_ARMOR or CLASS_SPELLS.DEMON_SKIN)
        CheckBuffSuggestion({
            key = "WARLOCK_ARMOR", priority = 20, ranks = armorRanks,
            satisfiedBy = { CLASS_SPELLS.DEMON_SKIN, CLASS_SPELLS.DEMON_ARMOR, CLASS_SPELLS.FEL_ARMOR },
            minDur = 120,
        })

        if not ctx.isMounted and not ctx.isFlying then
            local petExists = UnitExists and SafeCall(UnitExists, "pet")
            local petDead = petExists and UnitIsDead and SafeCall(UnitIsDead, "pet")
            if not petExists or petDead then
                local petRanks = FindKnownSpell(CLASS_SPELLS.SUMMON_FELGUARD) and CLASS_SPELLS.SUMMON_FELGUARD
                    or (FindKnownSpell(CLASS_SPELLS.SUMMON_VOID) and CLASS_SPELLS.SUMMON_VOID or CLASS_SPELLS.SUMMON_IMP)
                local pid, pName = FindKnownSpell(petRanks)
                if pid then
                    local usable, noRes = IsSpellUsableCompat(pid)
                    PushSuggestion({
                        key = "WARLOCK_PET", priority = 18, actionType = "spell",
                        spellID = pid, castSpell = pid, name = pName or "Summon",
                        icon = GetSpellTextureCompat(pid) or "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
                        usable = usable, noResource = noRes, badge = L["BUFF_BADGE_PET"] or "PET", kind = "pet",
                        reason = L["BUFF_REASON_PET_MISSING"] or "Companion pet is not active",
                    })
                end
            elseif FindKnownSpell(CLASS_SPELLS.SOUL_LINK) then
                CheckBuffSuggestion({ key = "WARLOCK_SOUL_LINK", priority = 24, ranks = CLASS_SPELLS.SOUL_LINK })
            end
        end

        if ctx.isSwimming then
            CheckBuffSuggestion({
                key = "WARLOCK_BREATH", priority = 28, ranks = CLASS_SPELLS.UNENDING_BREATH, minDur = 120,
            })
        end

    elseif cls == "SHAMAN" then
        local allShields = { CLASS_SPELLS.LIGHTNING_SHIELD, CLASS_SPELLS.WATER_SHIELD, CLASS_SPELLS.EARTH_SHIELD }
        local shieldRanks = ((ctx.role == "HEALER" or ctx.manaPct < 0.50) and FindKnownSpell(CLASS_SPELLS.WATER_SHIELD))
            and CLASS_SPELLS.WATER_SHIELD or CLASS_SPELLS.LIGHTNING_SHIELD
        CheckBuffSuggestion({
            key = "SHAMAN_SHIELD", priority = 20, ranks = shieldRanks, satisfiedBy = allShields, minDur = 120,
        })

        -- Weapon imbue (MH, plus OH when dual-wielding an OH weapon)
        local pickImbueRanks = CLASS_SPELLS.ROCKBITER_WEAP
        if ctx.role == "DAMAGER" and ctx.tabIdx ~= 1 and FindKnownSpell(CLASS_SPELLS.WINDFURY_WEAP) then
            pickImbueRanks = CLASS_SPELLS.WINDFURY_WEAP
        elseif FindKnownSpell(CLASS_SPELLS.FLAMETONGUE_WEAP) and (ctx.tabIdx == 1 or ctx.role == "HEALER" or not FindKnownSpell(CLASS_SPELLS.WINDFURY_WEAP)) then
            pickImbueRanks = CLASS_SPELLS.FLAMETONGUE_WEAP
        end

        local expThr = GetExpiringThreshold()
        if weap.mhIsWeapon and (not weap.hasMH or (weap.mhRemaining > 0 and weap.mhRemaining <= expThr)) then
            local wid, wName = FindKnownSpell(pickImbueRanks)
            if wid then
                local rem = weap.hasMH and math.ceil(weap.mhRemaining) or nil
                PushSuggestion({
                    key = "SHAMAN_MH_IMBUE", priority = 22, actionType = "spell",
                    spellID = wid, castSpell = wid, name = wName or "Weapon Imbue",
                    icon = GetSpellTextureCompat(wid) or "Interface\\Icons\\Spell_Nature_RockBiter",
                    usable = IsSpellUsableCompat(wid),
                    badge = rem and (rem .. "s") or (L["BUFF_BADGE_WEAPON"] or "WEAP"),
                    kind = rem and "expiring" or "weapon",
                    reason = rem
                        and string.format(L["BUFF_REASON_EXPIRING"] or "Buff expiring soon (%ds left)", rem)
                        or (L["BUFF_REASON_WEAPON_MISSING"] or "No active weapon enchant / poison"),
                })
            end
        elseif weap.ohIsWeapon and FindKnownSpell(CLASS_SPELLS.DUAL_WIELD)
            and (not weap.hasOH or (weap.ohRemaining > 0 and weap.ohRemaining <= expThr))
        then
            local ohRanks = FindKnownSpell(CLASS_SPELLS.FLAMETONGUE_WEAP) and CLASS_SPELLS.FLAMETONGUE_WEAP or pickImbueRanks
            local wid, wName = FindKnownSpell(ohRanks)
            if wid then
                PushSuggestion({
                    key = "SHAMAN_OH_IMBUE", priority = 24, actionType = "spell",
                    spellID = wid, castSpell = wid, name = wName or "OH Imbue",
                    icon = GetSpellTextureCompat(wid) or "Interface\\Icons\\Spell_Fire_FlameTounge",
                    usable = IsSpellUsableCompat(wid),
                    badge = L["BUFF_BADGE_WEAPON"] or "WEAP", kind = "weapon",
                    reason = L["BUFF_REASON_WEAPON_MISSING"] or "No active weapon enchant / poison",
                })
            end
        end

    elseif cls == "ROGUE" then
        -- Support both Retail buff-style poison spells and Classic/TBC bag poison items
        local hasModernPoisonSpell = FindKnownSpell(CLASS_SPELLS.ROGUE_POISON_SPELLS[1])
        if hasModernPoisonSpell then
            CheckBuffSuggestion({
                key = "ROGUE_POISON_SPELL", priority = 22, ranks = CLASS_SPELLS.ROGUE_POISON_SPELLS[1], minDur = 120,
            })
        elseif weap.mhIsWeapon or weap.ohIsWeapon then
            local bagPoisonID = PickBestBagItem(ROGUE_POISON_ITEMS)
            if bagPoisonID then
                local expThr = GetExpiringThreshold()
                local needMH = weap.mhIsWeapon and (not weap.hasMH or (weap.mhRemaining > 0 and weap.mhRemaining <= expThr))
                local needOH = weap.ohIsWeapon and (not weap.hasOH or (weap.ohRemaining > 0 and weap.ohRemaining <= expThr))
                if needMH or needOH then
                    local slotTarget = needMH and 16 or 17
                    local pName = GetItemNameCompat(bagPoisonID) or "Poison"
                    PushSuggestion({
                        key = "ROGUE_POISON_ITEM", priority = 22, actionType = "item",
                        itemID = bagPoisonID, targetSlot = slotTarget, name = pName,
                        icon = GetItemIconCompat(bagPoisonID) or "Interface\\Icons\\Ability_Poisons",
                        usable = true, badge = L["BUFF_BADGE_WEAPON"] or "WEAP", kind = "weapon",
                        reason = L["BUFF_REASON_WEAPON_MISSING"] or "No active weapon enchant / poison",
                    })
                end
            end
        end

    elseif cls == "DEATHKNIGHT" then
        CheckBuffSuggestion({ key = "DK_HORN", priority = 22, ranks = CLASS_SPELLS.HORN_OF_WINTER })
        if auras.numShapeshifts > 0 and auras.shapeshiftIdx == 0 then
            CheckBuffSuggestion({
                key = "DK_PRESENCE", priority = 20, ranks = { 48266, 48263, 48265 },
                satisfiedBy = CLASS_SPELLS.DK_PRESENCES,
            })
        end

    elseif cls == "MONK" then
        CheckBuffSuggestion({ key = "MONK_LEGACY", priority = 22, ranks = CLASS_SPELLS.LEGACY_EMPEROR, minDur = 120 })

    elseif cls == "EVOKER" then
        CheckBuffSuggestion({ key = "EVOKER_BRONZE", priority = 22, ranks = CLASS_SPELLS.BRONZE_BLESSING, minDur = 120 })
    end

    ---------------------------------------------------------------------------
    -- 3. Profession-crafted Weapon Consumables & Instance Elixirs
    ---------------------------------------------------------------------------
    if s.buffCheckProfessionItems ~= false then
    -- Blacksmithing stones / Enchanting oils ONLY if weapon has no imbue/poison yet
    if weap.mhIsWeapon and not weap.hasMH and cls ~= "SHAMAN" and cls ~= "ROGUE" and not ctx.isMounted then
        local isPureCaster = (cls == "MAGE" or cls == "PRIEST" or cls == "WARLOCK")
        if isPureCaster then
            local oilID = PickBestBagItem(WIZARD_OILS)
            if oilID and (profs.ENCHANTING or ctx.inInstance) then
                PushSuggestion({
                    key = "PROF_WIZARD_OIL", priority = 34, actionType = "item",
                    itemID = oilID, targetSlot = 16, name = GetItemNameCompat(oilID) or "Wizard Oil",
                    icon = GetItemIconCompat(oilID) or "Interface\\Icons\\INV_Potion_105",
                    usable = true, badge = L["BUFF_BADGE_WEAPON"] or "OIL", kind = "profession",
                    reason = L["BUFF_REASON_WEAPON_MISSING"] or "No active weapon enchant / poison",
                })
            end
        else
            local stoneID = nil
            if weap.mhIsEdged then
                stoneID = PickBestBagItem(SHARPENING_STONES)
            elseif weap.mhIsBlunt then
                stoneID = PickBestBagItem(WEIGHTSTONES)
            end
            if stoneID and (profs.BLACKSMITHING or ctx.inInstance) then
                PushSuggestion({
                    key = "PROF_SHARPENING", priority = 34, actionType = "item",
                    itemID = stoneID, targetSlot = 16, name = GetItemNameCompat(stoneID) or "Stone",
                    icon = GetItemIconCompat(stoneID) or "Interface\\Icons\\INV_Stone_SharpeningStone_01",
                    usable = true, badge = L["BUFF_BADGE_WEAPON"] or "WEAP", kind = "profession",
                    reason = L["BUFF_REASON_WEAPON_MISSING"] or "No active weapon enchant / poison",
                })
            end
        end
    end

    -- Alchemy / Dungeon Elixir reminder (strictly inside instances so open-world questing stays quiet)
    if ctx.inInstance and not auras.restricted then
        local elixirID = PickBestBagItem(DUNGEON_ELIXIRS)
        if elixirID then
            local eName = GetItemNameCompat(elixirID)
            local alreadyHas = eName and auras.activeNames[string.lower(eName)]
            if not alreadyHas then
                PushSuggestion({
                    key = "PROF_DUNGEON_ELIXIR", priority = 38, actionType = "item",
                    itemID = elixirID, name = eName or "Elixir",
                    icon = GetItemIconCompat(elixirID) or "Interface\\Icons\\INV_Potion_39",
                    usable = true, badge = L["BUFF_BADGE_MISSING"] or "BUFF", kind = "profession",
                    reason = L["BUFF_REASON_ELIXIR_DUNGEON"] or "In instance: Elixir available in bags",
                })
            end
        end
    end
    end -- if s.buffCheckProfessionItems ~= false

    table.sort(out, function(a, b)
        if (a.priority or 50) ~= (b.priority or 50) then
            return (a.priority or 50) < (b.priority or 50)
        end
        return (a.name or "") < (b.name or "")
    end)

    return out
end

-------------------------------------------------------------------------------
-- Floating Reminder Bar UI (NexusKitBuffFrame)
-------------------------------------------------------------------------------
local buffFrame = CreateFrame("Frame", "NexusKitBuffFrame", UIParent, "BackdropTemplate")
buffFrame:SetSize(MIN_FRAME_W, COMPACT_FRAME_H)
buffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -370, -40)
if buffFrame.SetDontSavePosition then
    buffFrame:SetDontSavePosition(true)
end
buffFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
buffFrame:SetBackdropColor(0, 0, 0, 0)
buffFrame:SetBackdropBorderColor(0, 0, 0, 0)
buffFrame.lastTransparentMode = true
buffFrame:SetClampedToScreen(true)
buffFrame:SetMovable(true)
buffFrame:EnableMouse(true)
buffFrame:RegisterForDrag("LeftButton")
buffFrame:SetFrameStrata("MEDIUM")
buffFrame:Hide()

local pendingRefresh = false

local function IsBuffFrameLocked()
    return (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locked) and true or false
end

local function SaveBuffPosition()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local left, top = buffFrame:GetLeft(), buffFrame:GetTop()
    if left and top then
        buffFrame:ClearAllPoints()
        buffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        NexusKitDB.settings.buffPos = { x = left, y = top }
    end
end

local function AnchorBuffFrameDefault(frameH)
    if InCombatLockdown() then return end
    local savedPos = NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.buffPos
    if savedPos and savedPos.x and savedPos.y then
        buffFrame:ClearAllPoints()
        buffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedPos.x, savedPos.y)
        return
    end

    local h = frameH or COMPACT_FRAME_H
    local tracker = _G["NexusKitTrackerFrame"]
    if tracker and tracker.IsShown and tracker:IsShown() then
        buffFrame:ClearAllPoints()
        local trackerTop = tracker:GetTop() or 0
        local screenTop = (UIParent and UIParent:GetTop()) or 1000
        if trackerTop > (screenTop - h - 20) then
            buffFrame:SetPoint("TOPRIGHT", tracker, "BOTTOMRIGHT", 0, -6)
        else
            buffFrame:SetPoint("BOTTOMRIGHT", tracker, "TOPRIGHT", 0, 6)
        end
    else
        buffFrame:ClearAllPoints()
        buffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -370, -40)
    end
end

buffFrame:SetScript("OnEnter", function(self)
    if IsTransparentBar() and not IsBuffFrameLocked() then
        self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
    end
end)

buffFrame:SetScript("OnLeave", function(self)
    if IsTransparentBar() then
        self:SetBackdropBorderColor(0, 0, 0, 0)
    end
end)

buffFrame:SetScript("OnDragStart", function(self)
    if not IsBuffFrameLocked() and not InCombatLockdown() then
        self:StartMoving()
    end
end)

buffFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not InCombatLockdown() then
        SaveBuffPosition()
    end
end)

-- Header strip
local headerTitle = buffFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerTitle:SetPoint("TOPLEFT", 8, -7)
headerTitle:SetPoint("RIGHT", buffFrame, "RIGHT", -52, 0)
headerTitle:SetJustifyH("LEFT")
headerTitle:SetWordWrap(false)
headerTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

local lockBtn = CreateFrame("Button", nil, buffFrame)
lockBtn:SetSize(19, 19)
lockBtn:SetPoint("TOPRIGHT", -22, -3)
lockBtn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")

local function UpdateBuffLockVisual()
    if IsBuffFrameLocked() then
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
        lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-Locked-Down")
    else
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
        lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-Unlocked-Down")
    end
    if FP.CropButtonTextures then
        FP:CropButtonTextures(lockBtn, 0.15)
    end
end

lockBtn:SetScript("OnClick", function()
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings.locked = not NexusKitDB.settings.locked
        UpdateBuffLockVisual()
        if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
        if FP.RefreshTracker then FP:RefreshTracker() end
    end
end)

local closeBtn = CreateFrame("Button", nil, buffFrame, "UIPanelCloseButton")
closeBtn:SetSize(17, 17)
closeBtn:SetPoint("TOPRIGHT", -3, -4)
closeBtn:SetScript("OnClick", function()
    for _, item in ipairs(currentSuggestions) do
        if item.key then
            snoozedKeys[item.key] = true
        end
    end
    FP:RefreshBuffAdvisor()
end)

-- Slot button pool (SecureActionButtonTemplate so single left-click casts buffs/items)
local slotPool = {}

local KIND_BORDER_COLORS = {
    tracking   = { 1.00, 0.84, 0.12 },
    expiring   = { 1.00, 0.52, 0.12 },
    switch     = { 1.00, 0.62, 0.12 },
    pet        = { 0.35, 0.85, 1.00 },
    weapon     = { 0.78, 0.52, 1.00 },
    profession = { 1.00, 0.84, 0.12 },
    buff       = { 0.00, 1.00, 0.59 },
}

local function UpdateSlotVisuals(slot, item)
    local L = FP.L or {}
    slot.itemData = item
    slot.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    local col = KIND_BORDER_COLORS[item.kind] or KIND_BORDER_COLORS.buff
    slot.iconBox:SetBackdropBorderColor(col[1], col[2], col[3], 0.95)
    slot.badgeBg:SetColorTexture(0.03, 0.04, 0.07, 0.86)
    slot.badgeText:SetTextColor(col[1], col[2], col[3], 1)
    slot.badgeText:SetText(item.badge or "")
    slot.caption:SetText(item.name or "")

    if item.noResource then
        slot.icon:SetDesaturated(true)
        slot.icon:SetAlpha(0.65)
    else
        slot.icon:SetDesaturated(false)
        slot.icon:SetAlpha(1.0)
    end
end

local function GetOrCreateSlot(index)
    if slotPool[index] then
        return slotPool[index]
    end

    local btn = CreateFrame("Button", "NexusKitBuffSlot" .. index, buffFrame, "SecureActionButtonTemplate")
    btn:SetSize(SLOT_W, SLOT_H)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetAttribute("useOnKeyDown", false)
    btn:Hide()

    local iconBox = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    iconBox:SetSize(34, 34)
    iconBox:SetPoint("TOP", btn, "TOP", 0, -2)
    iconBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    iconBox:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
    btn.iconBox = iconBox

    local icon = iconBox:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local highlight = iconBox:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetPoint("TOPLEFT", 3, -3)
    highlight:SetPoint("BOTTOMRIGHT", -3, 3)
    highlight:SetColorTexture(1, 1, 1, 0.22)

    local badgeBg = iconBox:CreateTexture(nil, "OVERLAY")
    badgeBg:SetHeight(12)
    badgeBg:SetPoint("BOTTOMLEFT", 3, 2)
    badgeBg:SetPoint("BOTTOMRIGHT", -3, 2)
    btn.badgeBg = badgeBg

    local badgeText = iconBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badgeText:SetPoint("CENTER", badgeBg, "CENTER", 0, 0)
    local bFont, bSize, bFlags = badgeText:GetFont()
    if bFont then
        badgeText:SetFont(bFont, math.max(8, (bSize or 10) - 1), "OUTLINE")
    end
    btn.badgeText = badgeText

    local caption = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    caption:SetPoint("TOP", iconBox, "BOTTOM", 0, -2)
    caption:SetPoint("LEFT", btn, "LEFT", 0, 0)
    caption:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
    caption:SetHeight(22)
    caption:SetJustifyH("CENTER")
    caption:SetJustifyV("TOP")
    caption:SetWordWrap(true)
    if caption.SetMaxLines then
        caption:SetMaxLines(2)
    end
    local cFont = caption:GetFont()
    if cFont then
        caption:SetFont(cFont, 9, "OUTLINE")
    end
    caption:SetShadowColor(0, 0, 0, 0.95)
    caption:SetShadowOffset(1, -1)
    btn.caption = caption

    -- Gentle border pulse to draw attention without visual noise
    local anim = iconBox:CreateAnimationGroup()
    anim:SetLooping("REPEAT")
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.72)
    fadeOut:SetDuration(1.1)
    fadeOut:SetOrder(1)
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.72)
    fadeIn:SetToAlpha(1.0)
    fadeIn:SetDuration(1.1)
    fadeIn:SetOrder(2)
    btn.pulseAnim = anim
    anim:Play()

    btn:SetScript("PostClick", function(self, mouseButton)
        local item = self.itemData
        if not item then return end
        if mouseButton == "RightButton" then
            dismissedKeys[item.key] = true
            FP:ScheduleBuffAdvisorRefresh(0.05)
            return
        end
        if mouseButton == "LeftButton" and item.actionType == "tracking" and item.trackingIndex then
            if InCombatLockdown and InCombatLockdown() then return end
            if C_Minimap and C_Minimap.SetTracking then
                SafeCall(C_Minimap.SetTracking, item.trackingIndex, true)
            elseif SetTracking then
                SafeCall(SetTracking, item.trackingIndex, true)
            end
            FP:ScheduleBuffAdvisorRefresh(0.05)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        local item = self.itemData
        if not item or not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
        local L = FP.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local col = KIND_BORDER_COLORS[item.kind] or KIND_BORDER_COLORS.buff
        GameTooltip:SetText(item.name or "Buff", col[1], col[2], col[3])
        if item.reason then
            GameTooltip:AddLine(item.reason, 1, 1, 1, true)
        end
        GameTooltip:AddLine(" ", 1, 1, 1)
        if InCombatLockdown() then
            GameTooltip:AddLine(L["BUFF_CLICK_COMBAT_LOCK"] or "In combat: click disabled until combat ends", 1.0, 0.55, 0.35, true)
        else
            GameTooltip:AddLine(L["BUFF_CLICK_ACTIVATE"] or "Left-click: Activate / Cast", 0.25, 1.0, 0.65, true)
        end
        GameTooltip:AddLine(L["BUFF_RIGHT_CLICK_SNOOZE"] or "Right-click: Hide for this session", 0.72, 0.76, 0.82, true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    slotPool[index] = btn
    return btn
end

local function ConfigureSlotAction(slot, item)
    -- Only mutate SecureActionButtonTemplate attributes outside combat lockdown
    if InCombatLockdown() then return end

    slot:SetAttribute("type", nil)
    slot:SetAttribute("type1", nil)
    slot:SetAttribute("unit", nil)
    slot:SetAttribute("unit1", nil)
    slot:SetAttribute("spell", nil)
    slot:SetAttribute("spell1", nil)
    slot:SetAttribute("item", nil)
    slot:SetAttribute("item1", nil)
    slot:SetAttribute("macrotext", nil)
    slot:SetAttribute("macrotext1", nil)
    slot:SetAttribute("target-slot", nil)
    slot:SetAttribute("target-slot1", nil)

    if item.actionType == "spell" and item.castSpell then
        slot:SetAttribute("type1", "spell")
        slot:SetAttribute("unit1", "player")
        slot:SetAttribute("spell1", item.castSpell)
    elseif item.actionType == "item" and item.itemID then
        if item.targetSlot then
            -- Use secure macro so temporary stones/oils/poisons/lures apply directly to MH/OH slot
            slot:SetAttribute("type1", "macro")
            slot:SetAttribute("macrotext1", "/use item:" .. tostring(item.itemID) .. "\n/use " .. tostring(item.targetSlot))
        else
            slot:SetAttribute("type1", "item")
            slot:SetAttribute("item1", "item:" .. tostring(item.itemID))
        end
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
local function ApplyBuffFrameAppearance()
    local transparent = IsTransparentBar()
    if buffFrame.lastTransparentMode ~= transparent then
        buffFrame.lastTransparentMode = transparent
        if transparent then
            buffFrame:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
        else
            buffFrame:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12,
                insets   = { left = 3, right = 3, top = 3, bottom = 3 },
            })
        end
    end

    if transparent then
        buffFrame:SetBackdropColor(0, 0, 0, 0)
        buffFrame:SetBackdropBorderColor(0, 0, 0, 0)
        headerTitle:Hide()
        lockBtn:Hide()
        closeBtn:Hide()
        return COMPACT_FRAME_H, -5, true
    end

    buffFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.90)
    buffFrame:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
    headerTitle:Show()
    lockBtn:Show()
    closeBtn:Show()
    return FRAME_H, -28, false
end

function FP:ApplyBuffAdvisorScale()
    local scale = tonumber(GetBuffSettings().buffScale) or 1.0
    if scale < 0.70 then scale = 0.70 elseif scale > 1.50 then scale = 1.50 end
    if buffFrame and buffFrame.SetScale and not InCombatLockdown() then
        buffFrame:SetScale(scale)
    end
end

function FP:RefreshBuffAdvisor()
    local L = FP.L or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    headerTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    headerTitle:SetText(L["BUFF_ADVISOR_TITLE"] or "Buffs & Tracking")
    UpdateBuffLockVisual()
    self:ApplyBuffAdvisorScale()

    local frameH, slotTopY, transparent = ApplyBuffFrameAppearance()

    if not IsAdvisorEnabled() then
        currentSuggestions = {}
        if not InCombatLockdown() then
            buffFrame:Hide()
        else
            pendingRefresh = true
        end
        return
    end

    currentSuggestions = EvaluateRecommendations()

    -- Defer structural Show/Hide/Size/SetAttribute mutations cleanly if locked down in combat
    if InCombatLockdown() then
        pendingRefresh = true
        if buffFrame:IsShown() then
            local byKey = {}
            for _, item in ipairs(currentSuggestions) do
                byKey[item.key] = item
            end
            for i = 1, MAX_SLOTS do
                local slot = slotPool[i]
                if slot and slot:IsShown() and slot.itemData then
                    local updated = byKey[slot.itemData.key]
                    if updated then
                        UpdateSlotVisuals(slot, updated)
                    end
                end
            end
        end
        return
    end

    pendingRefresh = false
    local visibleCount = math.min(MAX_SLOTS, #currentSuggestions)
    if visibleCount <= 0 then
        for i = 1, MAX_SLOTS do
            if slotPool[i] then
                slotPool[i].itemData = nil
                slotPool[i]:Hide()
            end
        end
        buffFrame:Hide()
        return
    end

    local rowW = visibleCount * SLOT_W + math.max(0, visibleCount - 1) * SLOT_GAP
    local frameW = transparent and math.max(90, rowW + 24) or math.max(MIN_FRAME_W, rowW + 16)
    buffFrame:SetSize(frameW, frameH)
    AnchorBuffFrameDefault(frameH)

    local startX = math.floor((frameW - rowW) / 2)
    for i = 1, visibleCount do
        local item = currentSuggestions[i]
        local slot = GetOrCreateSlot(i)
        UpdateSlotVisuals(slot, item)
        ConfigureSlotAction(slot, item)
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", buffFrame, "TOPLEFT", startX + (i - 1) * (SLOT_W + SLOT_GAP), slotTopY)
        slot:Show()
    end

    for i = visibleCount + 1, #slotPool do
        slotPool[i].itemData = nil
        slotPool[i]:Hide()
    end

    buffFrame:Show()
end

function FP:ResetBuffAdvisorPosition()
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings.buffPos = nil
    end
    self:RefreshBuffAdvisor()
end

function FP:ToggleBuffAdvisor()
    local L = FP.L or {}
    for k in pairs(dismissedKeys) do
        dismissedKeys[k] = nil
    end
    for k in pairs(snoozedKeys) do
        snoozedKeys[k] = nil
    end
    spellbookLoaded = false
    self:RefreshBuffAdvisor()

    if #currentSuggestions == 0 then
        FP:Print(L["BUFF_ALL_GOOD"] or "All recommended buffs & profession trackings are active.")
    else
        FP:Print(string.format(L["BUFF_SHOWN_COUNT"] or "Buff Advisor: %d active reminder(s) shown.", #currentSuggestions))
    end
end

-------------------------------------------------------------------------------
-- Throttled Event Watcher, Instant Toggle Hooks & Expiring-Buff Ticker
-------------------------------------------------------------------------------
local refreshTimer = nil
local refreshDueAt = 0

function FP:ScheduleBuffAdvisorRefresh(delay)
    local d = delay or 0.05
    if C_Timer and C_Timer.NewTimer then
        local now = (GetTime and SafeCall(GetTime)) or 0
        local targetDue = now + d
        if refreshTimer and targetDue >= (refreshDueAt - 0.01) then
            return
        end
        if refreshTimer then
            refreshTimer:Cancel()
            refreshTimer = nil
        end
        refreshDueAt = targetDue
        refreshTimer = C_Timer.NewTimer(d, function()
            refreshTimer = nil
            refreshDueAt = 0
            FP:RefreshBuffAdvisor()
        end)
    else
        refreshTimer = nil
        refreshDueAt = 0
        FP:RefreshBuffAdvisor()
    end
end

local function OnInstantAuraOrTrackingEvent()
    FP:ScheduleBuffAdvisorRefresh(0.02)
end

local eventFrame = CreateFrame("Frame")
SafeRegisterEvent(eventFrame, "PLAYER_LOGIN")
SafeRegisterEvent(eventFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterUnitEvent(eventFrame, "UNIT_AURA", "player")
SafeRegisterEvent(eventFrame, "PLAYER_AURAS_CHANGED")
SafeRegisterUnitEvent(eventFrame, "UNIT_PET", "player")
SafeRegisterUnitEvent(eventFrame, "UNIT_POWER_UPDATE", "player")
SafeRegisterUnitEvent(eventFrame, "UNIT_INVENTORY_CHANGED", "player")
SafeRegisterEvent(eventFrame, "MINIMAP_UPDATE_TRACKING")
SafeRegisterEvent(eventFrame, "TRACKING_TARGET_CHANGED")
SafeRegisterEvent(eventFrame, "SPELLS_CHANGED")
SafeRegisterEvent(eventFrame, "LEARNED_SPELL_IN_TAB")
SafeRegisterEvent(eventFrame, "SKILL_LINES_CHANGED")
SafeRegisterEvent(eventFrame, "BAG_UPDATE_DELAYED")
SafeRegisterEvent(eventFrame, "PLAYER_MOUNT_DISPLAY_CHANGED")
SafeRegisterEvent(eventFrame, "UPDATE_SHAPESHIFT_FORM")
SafeRegisterEvent(eventFrame, "UPDATE_SHAPESHIFT_FORMS")
SafeRegisterEvent(eventFrame, "PLAYER_LEVEL_UP")
SafeRegisterEvent(eventFrame, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(eventFrame, "ACTIVE_TALENT_GROUP_CHANGED")
SafeRegisterEvent(eventFrame, "SPECIALIZATION_CHANGED")
SafeRegisterEvent(eventFrame, "PLAYER_ALIVE")
SafeRegisterEvent(eventFrame, "PLAYER_UNGHOST")
SafeRegisterEvent(eventFrame, "PLAYER_DEAD")
SafeRegisterEvent(eventFrame, "PLAYER_UPDATE_RESTING")
SafeRegisterEvent(eventFrame, "PLAYER_REGEN_DISABLED")
SafeRegisterEvent(eventFrame, "PLAYER_REGEN_ENABLED")

local lastPowerCheck = 0
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "SKILL_LINES_CHANGED" then
        spellbookLoaded = false
        FP:ScheduleBuffAdvisorRefresh(0.10)
    elseif event == "UNIT_POWER_UPDATE" then
        local now = (GetTime and SafeCall(GetTime)) or 0
        if (now - lastPowerCheck) < 1.2 then return end
        lastPowerCheck = now
        FP:ScheduleBuffAdvisorRefresh(0.25)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingRefresh then
            pendingRefresh = false
        end
        FP:ScheduleBuffAdvisorRefresh(0.08)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        spellbookLoaded = false
        FP:ApplyBuffAdvisorScale()
        FP:ScheduleBuffAdvisorRefresh(0.45)
    elseif event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED"
        or event == "MINIMAP_UPDATE_TRACKING" or event == "TRACKING_TARGET_CHANGED"
        or event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS"
        or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        OnInstantAuraOrTrackingEvent()
    else
        FP:ScheduleBuffAdvisorRefresh(0.12)
    end
end)

-- Lightweight ticker to detect <90s expiring buffs or weapon enchant expiry cleanly
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(8, function()
        if IsAdvisorEnabled() then
            FP:RefreshBuffAdvisor()
        end
    end)
end
