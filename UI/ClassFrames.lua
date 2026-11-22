-- NexusKit - UI/ClassFrames.lua
-- Class colors, Class badges, Spec tooltips, Party Name colors, and Permanent Party Buffs/Debuffs.
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

local DISPEL_COLORS = {
    ["Magic"]   = { r = 0.2, g = 0.6, b = 1.0 },
    ["Curse"]   = { r = 0.6, g = 0.0, b = 1.0 },
    ["Disease"] = { r = 0.8, g = 0.4, b = 0.1 },
    ["Poison"]  = { r = 0.0, g = 0.8, b = 0.0 },
    ["none"]    = { r = 0.8, g = 0.0, b = 0.0 },
}

local function IsForbiddenObj(obj)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return true end
    return (obj.IsForbidden and obj:IsForbidden()) and true or false
end

local function GetSettings()
    local db = NexKitDB or NexusKitDB
    return (db and db.settings) or {}
end

local function IsClassFeaturesEnabled()
    return GetSettings().showClassColorsAndIcons ~= false
end

local LOCALIZED_CLASS_MAP = {
    -- Italian
    ["Guerriero"] = "WARRIOR", ["Guerriera"] = "WARRIOR",
    ["Mago"] = "MAGE", ["Maga"] = "MAGE",
    ["Ladro"] = "ROGUE", ["Ladra"] = "ROGUE",
    ["Druido"] = "DRUID", ["Druida"] = "DRUID",
    ["Cacciatore"] = "HUNTER", ["Cacciatrice"] = "HUNTER",
    ["Sciamano"] = "SHAMAN", ["Sciamana"] = "SHAMAN",
    ["Sacerdote"] = "PRIEST", ["Sacerdotessa"] = "PRIEST",
    ["Stregone"] = "WARLOCK", ["Stregona"] = "WARLOCK",
    ["Paladino"] = "PALADIN", ["Paladina"] = "PALADIN",
    -- German
    ["Krieger"] = "WARRIOR", ["Magier"] = "MAGE", ["Schurke"] = "ROGUE",
    ["Druide"] = "DRUID", ["Jäger"] = "HUNTER", ["Schamane"] = "SHAMAN",
    ["Priester"] = "PRIEST", ["Hexenmeister"] = "WARLOCK",
    -- French
    ["Guerrier"] = "WARRIOR", ["Mage"] = "MAGE", ["Voleur"] = "ROGUE",
    ["Druide"] = "DRUID", ["Chasseur"] = "HUNTER", ["Chaman"] = "SHAMAN",
    ["Prêtre"] = "PRIEST", ["Démoniste"] = "WARLOCK",
    -- Spanish
    ["Guerrero"] = "WARRIOR", ["Pícaro"] = "ROGUE",
    ["Cazador"] = "HUNTER", ["Chamán"] = "SHAMAN",
    ["Sacerdote"] = "PRIEST", ["Brujo"] = "WARLOCK",
    -- Russian
    ["Воин"] = "WARRIOR", ["Маг"] = "MAGE", ["Разбойник"] = "ROGUE",
    ["Друид"] = "DRUID", ["Охотник"] = "HUNTER", ["Шаман"] = "SHAMAN",
    ["Жрец"] = "PRIEST", ["Чернокнижник"] = "WARLOCK", ["Паладин"] = "PALADIN",
}

local function GetUnitClassColor(unit)
    if not unit or not UnitExists(unit) then return nil, nil end
    local isPartyOrPlayer = (unit == "player") or (unit:match("^party%d+$") ~= nil)
    if not isPartyOrPlayer and not UnitIsPlayer(unit) then
        return nil, nil
    end

    local ok, locClass, class = pcall(UnitClass, unit)
    if not ok then return nil, nil end

    if not class or class == "" then
        if locClass and LOCALIZED_CLASS_MAP[locClass] then
            class = LOCALIZED_CLASS_MAP[locClass]
        end
    end

    if not class or class == "" then return nil, nil end

    class = string.upper(class)
    local color = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
        or (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or { r = 0.8, g = 0.8, b = 0.8 }
    return color, class
end

local function ApplyClassTextureToIcon(icon, class)
    if not icon or not class then return end
    icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
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
    local actualGuid = guid or lastInspectTargetGUID
    if not actualGuid then return end
    if lastInspectTargetGUID and actualGuid ~= lastInspectTargetGUID then return end
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
    cachedPlayerSpecs[actualGuid] = {
        specName = (maxPoints > 0) and topName or nil,
        pts = pts,
        time = (GetTime and GetTime()) or 0,
    }

    if ClearInspectPlayer then
        pcall(ClearInspectPlayer)
    end

    if currentTooltipOwner and currentTooltipUnit and UnitExists(currentTooltipUnit) then
        if UnitGUID(currentTooltipUnit) == actualGuid and GameTooltip:IsShown() then
            ShowPortraitTooltip(currentTooltipOwner, currentTooltipUnit)
        end
    end
end

-------------------------------------------------------------------------------
-- Party Member Dispel & Buff Detection
-------------------------------------------------------------------------------
local function GetPlayerDispelCapabilities()
    local _, playerClass = UnitClass("player")
    local dispels = {}
    if playerClass == "PRIEST" then
        dispels["Magic"] = true
        dispels["Disease"] = true
    elseif playerClass == "PALADIN" then
        dispels["Magic"] = true
        dispels["Poison"] = true
        dispels["Disease"] = true
    elseif playerClass == "MAGE" then
        dispels["Curse"] = true
    elseif playerClass == "DRUID" then
        dispels["Curse"] = true
        dispels["Poison"] = true
    elseif playerClass == "SHAMAN" then
        dispels["Poison"] = true
        dispels["Disease"] = true
    elseif playerClass == "WARLOCK" then
        dispels["Magic"] = true
    end
    return dispels, playerClass
end

local PLAYER_BUFF_SPELLS = {
    -- Paladin
    ["Blessing of Might"] = true, ["Benedizione della Potenza"] = true,
    ["Blessing of Wisdom"] = true, ["Benedizione della Saggezza"] = true,
    ["Blessing of Kings"] = true, ["Benedizione dei Re"] = true,
    ["Blessing of Salvation"] = true, ["Benedizione della Salvezza"] = true,
    ["Blessing of Light"] = true, ["Benedizione della Luce"] = true,
    ["Blessing of Sanctuary"] = true, ["Benedizione del Rifugio"] = true,
    ["Blessing of Protection"] = true, ["Benedizione della Protezione"] = true,
    ["Blessing of Freedom"] = true, ["Benedizione della Libertà"] = true,
    ["Blessing of Sacrifice"] = true, ["Benedizione del Sacrificio"] = true,
    ["Devotion Aura"] = true, ["Aura di Devozione"] = true,
    ["Retribution Aura"] = true, ["Aura di Ritorsione"] = true,
    ["Concentration Aura"] = true, ["Aura di Concentrazione"] = true,
    ["Shadow Resistance Aura"] = true, ["Aura di Resistenza all'Ombra"] = true,
    ["Frost Resistance Aura"] = true, ["Aura di Resistenza al Gelo"] = true,
    ["Fire Resistance Aura"] = true, ["Aura di Resistenza al Fuoco"] = true,
    -- Priest
    ["Power Word: Fortitude"] = true, ["Parola del Potere: Fortezza"] = true,
    ["Shadow Protection"] = true, ["Protezione dall'Ombra"] = true,
    ["Divine Spirit"] = true, ["Spirito Divino"] = true,
    ["Renew"] = true, ["Rinnovamento"] = true,
    ["Power Word: Shield"] = true, ["Parola del Potere: Scudo"] = true,
    ["Fear Ward"] = true, ["Difesa dalla Paura"] = true,
    -- Mage
    ["Arcane Intellect"] = true, ["Intelletto Arcano"] = true,
    ["Arcane Brilliance"] = true, ["Brillantezza Arcana"] = true,
    ["Amplify Magic"] = true, ["Amplificazione Magica"] = true,
    ["Dampen Magic"] = true, ["Attenuazione Magica"] = true,
    -- Druid
    ["Mark of the Wild"] = true, ["Marchio Selvaggio"] = true,
    ["Gift of the Wild"] = true, ["Dono del Selvaggio"] = true,
    ["Thorns"] = true, ["Spine"] = true,
    ["Rejuvenation"] = true, ["Ringiovanimento"] = true,
    ["Regrowth"] = true, ["Ricrescita"] = true,
    -- Warrior
    ["Battle Shout"] = true, ["Urlo di Battaglia"] = true,
    -- Warlock
    ["Unending Breath"] = true, ["Respiro Inesauribile"] = true,
    ["Detect Invisibility"] = true, ["Individuazione dell'Invisibilità"] = true,
    ["Fire Shield"] = true, ["Scudo di Fuoco"] = true,
    -- Shaman
    ["Water Walking"] = true, ["Camminata sull'Acqua"] = true,
    ["Water Breathing"] = true, ["Respiro Acquatico"] = true,
}

local function GetPartyUnitDebuffs(unit)
    local debuffs = {}
    if not unit or not UnitExists(unit) then return debuffs end
    local dispels, playerClass = GetPlayerDispelCapabilities()

    for i = 1, 16 do
        local name, icon, count, dType, duration, expirationTime, spellId
        local found = false

        -- 1. Try native Classic UnitDebuff first (safe, fast, never triggers taint error)
        if UnitDebuff then
            local okD, dName, dIcon, dCount, dDispel, dDur, dExp, _, _, _, dSpellId = pcall(UnitDebuff, unit, i)
            if okD and dName then
                name, icon, count, dType, duration, expirationTime, spellId = dName, dIcon, dCount, dDispel, dDur, dExp, dSpellId
                found = true
            elseif okD and not dName then
                break -- End of debuffs
            end
        end

        -- 2. Fallback to C_UnitAuras.GetAuraDataByIndex (wrapped in pcall to protect against secret/taint restrictions)
        if not found and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local okC, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if okC and type(aura) == "table" and aura.name then
                name, icon, count, dType, duration, expirationTime, spellId = aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.spellId
                found = true
            elseif okC and not aura then
                break -- End of debuffs
            end
        end

        if not found then break end

        local canDispel = (dType and dispels[dType]) and true or false
        debuffs[#debuffs + 1] = {
            index = i,
            name = name,
            icon = icon,
            count = count or 0,
            dispelType = dType or "none",
            canDispel = canDispel,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            spellId = spellId,
        }
    end

    -- Sort debuffs: dispellable debuffs FIRST
    table.sort(debuffs, function(a, b)
        if a.canDispel and not b.canDispel then return true end
        if not a.canDispel and b.canDispel then return false end
        return a.index < b.index
    end)

    return debuffs
end

local function GetPartyUnitBuffs(unit)
    local buffs = {}
    if not unit or not UnitExists(unit) then return buffs end
    local _, playerClass = UnitClass("player")

    for i = 1, 32 do
        local name, icon, count, duration, expirationTime, source, spellId
        local found = false

        -- 1. Try native Classic UnitBuff first (safe, fast, never triggers taint error)
        if UnitBuff then
            local okB, bName, bIcon, bCount, _, bDur, bExp, bSrc, _, _, bSpellId = pcall(UnitBuff, unit, i)
            if okB and bName then
                name, icon, count, duration, expirationTime, source, spellId = bName, bIcon, bCount, bDur, bExp, bSrc, bSpellId
                found = true
            elseif okB and not bName then
                break -- End of buffs
            end
        end

        -- 2. Fallback to C_UnitAuras.GetAuraDataByIndex (wrapped in pcall to protect against secret/taint restrictions)
        if not found and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local okC, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if okC and type(aura) == "table" and aura.name then
                name, icon, count, duration, expirationTime, source, spellId = aura.name, aura.icon, aura.applications, aura.duration, aura.expirationTime, aura.sourceUnit, aura.spellId
                found = true
            elseif okC and not aura then
                break -- End of buffs
            end
        end

        if not found then break end

        local isPlayerBuff = (source == "player") or (source == nil and name and PLAYER_BUFF_SPELLS[name])
        buffs[#buffs + 1] = {
            index = i,
            name = name,
            icon = icon,
            count = count or 0,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            source = source,
            isPlayerBuff = isPlayerBuff,
            spellId = spellId,
        }
    end

    -- Sort buffs: player's own buffs FIRST, then other party buffs
    table.sort(buffs, function(a, b)
        if a.isPlayerBuff and not b.isPlayerBuff then return true end
        if not a.isPlayerBuff and b.isPlayerBuff then return false end
        return a.index < b.index
    end)

    return buffs
end

-- Permanent Buffs & Debuffs below the health/mana bar (ALWAYS visible without mouse hover!)
local function UpdatePartyAuras(frame)
    if not frame or IsForbiddenObj(frame) then return end
    if not IsClassFeaturesEnabled() then
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    local id = frame.GetID and frame:GetID()
    local unit = frame.unit or (id and ("party" .. id))
    if not unit or not UnitExists(unit) then
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    -- Hide Blizzard's built-in duplicate debuffs so they don't conflict or duplicate
    local frameName = frame.GetName and frame:GetName()
    if frameName then
        for d = 1, 4 do
            local bDebuff = _G[frameName .. "Debuff" .. d]
            if bDebuff then
                bDebuff:SetAlpha(0)
                bDebuff:Hide()
            end
        end
    end

    local container = frame.nkPermanentAuras
    if not container then
        container = CreateFrame("Frame", nil, frame)
        container:SetSize(160, 20)
        -- Positioned permanently below the health/mana bar (starting at X=44, Y=-2)
        -- This is the exact location where Blizzard shows buffs on hover, but ALWAYS visible without mouse hover!
        container:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 44, -2)
        container:SetFrameStrata("MEDIUM")
        container:SetFrameLevel(45)
        frame.nkPermanentAuras = container

        container.slots = {}
        for s = 1, 8 do
            local btn = CreateFrame("Button", nil, container)
            btn:SetSize(16, 16)
            btn:SetPoint("LEFT", container, "LEFT", (s - 1) * 19, 0)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(btn)
            btn.icon = icon

            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            border:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
            border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.border = border

            local countFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.countFs = countFs

            btn:SetScript("OnEnter", function(self)
                if not self.unit or not self.auraIndex then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.isDebuff then
                    GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
                else
                    GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            container.slots[s] = btn
        end
    end

    container:Show()

    local debuffs = GetPartyUnitDebuffs(unit)
    local buffs = GetPartyUnitBuffs(unit)

    local slotIndex = 1

    -- 1. Display Debuffs first (dispellable ones have bright dispel color, others have red border)
    for d = 1, math.min(#debuffs, 4) do
        if slotIndex <= 8 then
            local btn = container.slots[slotIndex]
            local debuff = debuffs[d]
            btn.unit = unit
            btn.auraIndex = debuff.index
            btn.isDebuff = true
            btn.icon:SetTexture(debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            btn.border:SetVertexColor(col.r, col.g, col.b, 1)
            btn.border:Show()
            if debuff.count and debuff.count > 1 then
                btn.countFs:SetText(debuff.count)
                btn.countFs:Show()
            else
                btn.countFs:Hide()
            end
            btn:Show()
            slotIndex = slotIndex + 1
        end
    end

    -- 2. Display Buffs immediately after (player buffs have golden border, other buffs have clean subtle border)
    for b = 1, #buffs do
        if slotIndex <= 8 then
            local btn = container.slots[slotIndex]
            local buff = buffs[b]
            btn.unit = unit
            btn.auraIndex = buff.index
            btn.isDebuff = false
            btn.icon:SetTexture(buff.icon)
            btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn.border:SetTexCoord(0, 1, 0, 1)
            if buff.isPlayerBuff then
                -- Highlight player's own buffs in golden yellow
                btn.border:SetVertexColor(1.0, 0.82, 0.0, 0.95)
            else
                -- Subtle clean border for group buffs
                btn.border:SetVertexColor(0.5, 0.5, 0.5, 0.6)
            end
            btn.border:Show()
            if buff.count and buff.count > 1 then
                btn.countFs:SetText(buff.count)
                btn.countFs:Show()
            else
                btn.countFs:Hide()
            end
            btn:Show()
            slotIndex = slotIndex + 1
        end
    end

    -- Hide remaining unused slots
    for s = slotIndex, 8 do
        container.slots[s]:Hide()
    end
end

local function UpdateAllPartyAuras()
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            UpdatePartyAuras(f)
        end
    end
end

-------------------------------------------------------------------------------
-- 1. Party Frames (PartyMemberFrame1..4)
-------------------------------------------------------------------------------
local function UpdatePartyMember(frame)
    if not frame or IsForbiddenObj(frame) then return end
    if not IsClassFeaturesEnabled() then
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    local unit = frame.unit
    if not unit or unit == "" then
        local id = frame.GetID and frame:GetID()
        if id and id > 0 then
            unit = "party" .. id
        else
            local num = frame:GetName() and frame:GetName():match("PartyMemberFrame(%d+)")
            if num then unit = "party" .. num end
        end
    end

    if not unit or not UnitExists(unit) then
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    local color, class = GetUnitClassColor(unit)
    if not color or not class then
        -- If player data is not yet cached by client, retry up to 10 times every 0.3s
        frame.nkRetryCount = (frame.nkRetryCount or 0) + 1
        if frame.nkRetryCount <= 10 and C_Timer and C_Timer.After then
            C_Timer.After(0.3, function()
                if frame and not IsForbiddenObj(frame) then
                    UpdatePartyMember(frame)
                end
            end)
        end
        return
    end
    frame.nkRetryCount = 0

    if color and class then
        -- 1. Class-color Party Member Name text (requested: "colore della classe dove c'è il nome nel party")
        local nameFs = _G[frame:GetName() .. "Name"] or frame.name
        if nameFs and nameFs.SetTextColor then
            nameFs.nkClassColor = color
            nameFs:SetTextColor(color.r, color.g, color.b)
            if not nameFs.nkColorHooked then
                nameFs.nkColorHooked = true
                hooksecurefunc(nameFs, "SetTextColor", function(self, r, g, b)
                    if self.nkIsSettingColor then return end
                    if not IsClassFeaturesEnabled() then return end
                    local c = self.nkClassColor
                    if c and (math.abs(r - c.r) > 0.01 or math.abs(g - c.g) > 0.01 or math.abs(b - c.b) > 0.01) then
                        self.nkIsSettingColor = true
                        self:SetTextColor(c.r, c.g, c.b)
                        self.nkIsSettingColor = false
                    end
                end)
            end
        end

        -- 2. Class-color Party Member Healthbar & prevent Blizzard resets
        local healthbar = frame.healthbar or _G[frame:GetName() .. "HealthBar"]
        if healthbar and healthbar.SetStatusBarColor then
            healthbar.nkClassColor = color
            healthbar:SetStatusBarColor(color.r, color.g, color.b)
            if not healthbar.nkColorHooked then
                healthbar.nkColorHooked = true
                hooksecurefunc(healthbar, "SetStatusBarColor", function(self, r, g, b)
                    if self.nkIsSettingColor then return end
                    if not IsClassFeaturesEnabled() then return end
                    local c = self.nkClassColor
                    if c and (math.abs(r - c.r) > 0.01 or math.abs(g - c.g) > 0.01 or math.abs(b - c.b) > 0.01) then
                        self.nkIsSettingColor = true
                        self:SetStatusBarColor(c.r, c.g, c.b)
                        self.nkIsSettingColor = false
                    end
                end)
            end
        end

        -- 3. Circular Class Badge Button with Spec Tooltip
        local badge = frame.nkClassBadge
        if not badge then
            badge = CreateFrame("Button", nil, frame)
            badge:SetSize(22, 22)
            badge:SetFrameStrata("HIGH")
            badge:SetFrameLevel(60)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(badge)
            badge.icon = icon

            local border = badge:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetSize(38, 38)
            border:SetPoint("CENTER", badge, "CENTER", 6, -5)
            badge.border = border

            badge:SetScript("OnEnter", function(self)
                if not IsClassFeaturesEnabled() then return end
                local u = self.unit
                if u and UnitExists(u) then
                    ShowPortraitTooltip(self, u)
                end
            end)
            badge:SetScript("OnLeave", function(self)
                if currentTooltipOwner == self then
                    currentTooltipOwner = nil
                    currentTooltipUnit = nil
                end
                GameTooltip:Hide()
            end)
            badge:SetScript("OnClick", function(self)
                local u = self.unit
                if u and UnitExists(u) and not (InCombatLockdown and InCombatLockdown()) then
                    pcall(TargetUnit, u)
                end
            end)

            frame.nkClassBadge = badge
        end

        local portrait = _G[frame:GetName() .. "Portrait"] or frame
        badge:ClearAllPoints()
        -- Anchor to TOPLEFT of portrait so it NEVER collides with Blizzard's Alliance/Horde PvP crest at BOTTOMLEFT!
        badge:SetPoint("TOPLEFT", portrait, "TOPLEFT", -4, 4)
        badge:SetFrameStrata("HIGH")
        badge:SetFrameLevel(60)

        badge.unit = unit
        ApplyClassTextureToIcon(badge.icon, class)
        badge:Show()

        -- 4. Update Party Auras (Permanently visible: Player Buffs + Dispellable Debuffs)
        pcall(UpdatePartyAuras, frame)
    else
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
    end
end

-------------------------------------------------------------------------------
-- 1b. Raid-Style / Compact Party Frames (CompactUnitFrame / CompactPartyFrame)
-------------------------------------------------------------------------------
local function UpdateCompactPartyAuras(frame)
    if not frame or IsForbiddenObj(frame) then return end
    local unit = frame.unit or frame.displayedUnit
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    if not IsClassFeaturesEnabled() then
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    local container = frame.nkPermanentAuras
    if not container then
        container = CreateFrame("Frame", nil, frame)
        container:SetSize(120, 16)
        container:SetPoint("LEFT", frame, "RIGHT", 4, 0)
        container:SetFrameLevel((frame:GetFrameLevel() or 1) + 25)
        frame.nkPermanentAuras = container

        container.slots = {}
        for s = 1, 6 do
            local btn = CreateFrame("Button", nil, container)
            btn:SetSize(14, 14)
            btn:SetPoint("LEFT", container, "LEFT", (s - 1) * 16, 0)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(btn)
            btn.icon = icon

            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            border:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
            border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.border = border

            local countFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.countFs = countFs

            btn:SetScript("OnEnter", function(self)
                if not self.unit or not self.auraIndex then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.isDebuff then
                    GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
                else
                    GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            container.slots[s] = btn
        end
    end

    container:Show()

    local debuffs = GetPartyUnitDebuffs(unit)
    local buffs = GetPartyUnitBuffs(unit)
    local slotIndex = 1

    -- 1. Debuffs first (dispellable ones highlighted)
    for d = 1, math.min(#debuffs, 3) do
        if slotIndex <= 6 then
            local btn = container.slots[slotIndex]
            local debuff = debuffs[d]
            btn.unit = unit
            btn.auraIndex = debuff.index
            btn.isDebuff = true
            btn.icon:SetTexture(debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            btn.border:SetVertexColor(col.r, col.g, col.b, 1)
            btn.border:Show()
            if debuff.count and debuff.count > 1 then
                btn.countFs:SetText(debuff.count)
                btn.countFs:Show()
            else
                btn.countFs:Hide()
            end
            btn:Show()
            slotIndex = slotIndex + 1
        end
    end

    -- 2. Buffs (player buffs in golden yellow)
    for b = 1, #buffs do
        if slotIndex <= 6 then
            local btn = container.slots[slotIndex]
            local buff = buffs[b]
            btn.unit = unit
            btn.auraIndex = buff.index
            btn.isDebuff = false
            btn.icon:SetTexture(buff.icon)
            btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            btn.border:SetTexCoord(0, 1, 0, 1)
            if buff.isPlayerBuff then
                btn.border:SetVertexColor(1.0, 0.82, 0.0, 0.95)
            else
                btn.border:SetVertexColor(0.5, 0.5, 0.5, 0.6)
            end
            btn.border:Show()
            if buff.count and buff.count > 1 then
                btn.countFs:SetText(buff.count)
                btn.countFs:Show()
            else
                btn.countFs:Hide()
            end
            btn:Show()
            slotIndex = slotIndex + 1
        end
    end

    for s = slotIndex, 6 do
        container.slots[s]:Hide()
    end
end

local function UpdateCompactPartyFrame(frame, includeAuras)
    if not frame or IsForbiddenObj(frame) then return end
    local unit = frame.unit or frame.displayedUnit
    if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    if not IsClassFeaturesEnabled() then
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    local color, class = GetUnitClassColor(unit)
    if color and class then
        -- 1. Class-color Compact HealthBar
        local healthBar = frame.healthBar or frame.HealthBar
        if healthBar and healthBar.SetStatusBarColor then
            healthBar:SetStatusBarColor(color.r, color.g, color.b)
        end

        -- 2. Class-color Compact Name Text
        local nameFs = frame.name or frame.Name
        if nameFs and nameFs.SetTextColor then
            nameFs:SetTextColor(color.r, color.g, color.b)
        end

        -- 3. Circular Class Badge Button with Spec Tooltip
        local badge = frame.nkClassBadge
        if not badge then
            badge = CreateFrame("Button", nil, frame)
            badge:SetSize(18, 18)
            badge:SetFrameLevel((frame:GetFrameLevel() or 1) + 25)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(badge)
            badge.icon = icon

            local border = badge:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetSize(32, 32)
            border:SetPoint("CENTER", badge, "CENTER", 5, -4)
            badge.border = border

            badge:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)

            badge:SetScript("OnEnter", function(self)
                if not IsClassFeaturesEnabled() then return end
                local u = self.unit
                if u and UnitExists(u) then
                    ShowPortraitTooltip(self, u)
                end
            end)
            badge:SetScript("OnLeave", function(self)
                if currentTooltipOwner == self then
                    currentTooltipOwner = nil
                    currentTooltipUnit = nil
                end
                GameTooltip:Hide()
            end)
            badge:SetScript("OnClick", function(self)
                local u = self.unit
                if u and UnitExists(u) and not (InCombatLockdown and InCombatLockdown()) then
                    pcall(TargetUnit, u)
                end
            end)

            frame.nkClassBadge = badge
        end

        badge.unit = unit
        ApplyClassTextureToIcon(badge.icon, class)
        badge:Show()

        -- 4. Permanent Auras (Buffs & Debuffs) - only updated when requested to prevent taint in name/health hooks
        if includeAuras then
            pcall(UpdateCompactPartyAuras, frame)
        end
    else
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
    end
end

local function UpdateAllPartyMembers()
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            UpdatePartyMember(frame)
        end
    end
    -- Raid-style / Compact party frames
    if CompactPartyFrame and CompactPartyFrame:IsShown() then
        for i = 1, 5 do
            local f = _G["CompactPartyFrameMember" .. i]
            if f then
                UpdateCompactPartyFrame(f, true)
            end
        end
    end
    if CompactRaidFrameContainer and CompactRaidFrameContainer:IsShown() and CompactRaidFrameContainer_ApplyToFrames then
        pcall(CompactRaidFrameContainer_ApplyToFrames, CompactRaidFrameContainer, "normal", function(f)
            if f then UpdateCompactPartyFrame(f, true) end
        end)
    end
end

-------------------------------------------------------------------------------
-- 2. Target Frame (Target PG: healthbar verde Blizzard, badge classe + tooltip)
-------------------------------------------------------------------------------
local function UpdateTargetFrame()
    if not TargetFrame or IsForbiddenObj(TargetFrame) then return end
    if not TargetFrame:IsShown() then
        if TargetFrame.nkClassBadge then TargetFrame.nkClassBadge:Hide() end
        return
    end

    local unit = TargetFrame.unit or "target"
    local healthbar = TargetFrameHealthBar or TargetFrame.healthbar

    -- Ensure TargetFrame healthbar is always Blizzard's default green (0, 1, 0)
    if healthbar and healthbar.SetStatusBarColor and UnitExists(unit) then
        healthbar:SetStatusBarColor(0.0, 1.0, 0.0)
    end

    if not IsClassFeaturesEnabled() then
        if TargetFrame.nkClassBadge then TargetFrame.nkClassBadge:Hide() end
        return
    end

    local color, class = GetUnitClassColor(unit)
    if color and class then
        local badge = TargetFrame.nkClassBadge
        if not badge then
            badge = CreateFrame("Button", nil, TargetFrame)
            badge:SetSize(22, 22)
            badge:SetFrameLevel(TargetFrame:GetFrameLevel() + 25)
            badge:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", -22, -10)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(badge)
            badge.icon = icon

            local border = badge:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetSize(38, 38)
            border:SetPoint("CENTER", badge, "CENTER", 6, -5)
            badge.border = border

            badge:SetScript("OnEnter", function(self)
                if not IsClassFeaturesEnabled() then return end
                if UnitExists("target") and UnitIsPlayer("target") then
                    ShowPortraitTooltip(self, "target")
                end
            end)
            badge:SetScript("OnLeave", function(self)
                if currentTooltipOwner == self then
                    currentTooltipOwner = nil
                    currentTooltipUnit = nil
                end
                GameTooltip:Hide()
            end)

            TargetFrame.nkClassBadge = badge
        end
        ApplyClassTextureToIcon(badge.icon, class)
        badge:Show()
    else
        if TargetFrame.nkClassBadge then
            TargetFrame.nkClassBadge:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- 3. Nameplates (Barra + Nome con colore di classe + Badge Circolare su ogni PG)
-------------------------------------------------------------------------------
local activePlayerPlates = {}

local function UpdateNameplateUnit(unit)
    if not unit or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate or IsForbiddenObj(plate) then return end

    local host = (plate.UnitFrame and not IsForbiddenObj(plate.UnitFrame) and plate.UnitFrame) or plate
    if IsForbiddenObj(host) then return end

    if not IsClassFeaturesEnabled() or not UnitIsPlayer(unit) then
        if host.nkClassBadge then host.nkClassBadge:Hide() end
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

        local nameFs = host.name or host.Name
        if nameFs and nameFs.SetTextColor then
            nameFs:SetTextColor(color.r, color.g, color.b)
        end

        local badge = host.nkClassBadge
        if not badge then
            badge = CreateFrame("Frame", nil, host)
            badge:SetSize(18, 18)
            badge:EnableMouse(false)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(badge)
            badge.icon = icon

            local border = badge:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetSize(32, 32)
            border:SetPoint("CENTER", badge, "CENTER", 5, -4)
            badge.border = border

            host.nkClassBadge = badge
        end

        local baseLevel = (healthBar and healthBar.GetFrameLevel and healthBar:GetFrameLevel())
            or (host.GetFrameLevel and host:GetFrameLevel()) or 1
        badge:SetFrameLevel(baseLevel + 25)

        badge:ClearAllPoints()
        if healthBar and healthBar:IsShown() then
            badge:SetPoint("RIGHT", healthBar, "LEFT", -3, 0)
        elseif nameFs and nameFs:IsShown() then
            badge:SetPoint("RIGHT", nameFs, "LEFT", -3, 0)
        else
            badge:SetPoint("LEFT", host, "LEFT", -16, 0)
        end

        ApplyClassTextureToIcon(badge.icon, class)
        badge:Show()
    else
        if host.nkClassBadge then host.nkClassBadge:Hide() end
        activePlayerPlates[plate] = nil
    end
end

local function RemoveNameplateUnit(unit)
    if not unit or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and not IsForbiddenObj(plate) then
        local host = (plate.UnitFrame and not IsForbiddenObj(plate.UnitFrame) and plate.UnitFrame) or plate
        if host and host.nkClassBadge then
            host.nkClassBadge:Hide()
        end
        activePlayerPlates[plate] = nil
    end
end

-------------------------------------------------------------------------------
-- Hooks & Event Wiring
-------------------------------------------------------------------------------
local function EnhanceUnitTooltip(tooltip, unitOverride)
    if not tooltip or not IsClassFeaturesEnabled() then return end
    local _, unit = tooltip:GetUnit()
    unit = unit or unitOverride
    if not unit or not UnitExists(unit) then return end

    if not UnitIsPlayer(unit) then
        -- For NPC / creature units, show tracked reagent drops in tooltip if any
        local uName = UnitName(unit)
        if uName and FP.GetUnitTrackedReagent then
            local rInfo = FP:GetUnitTrackedReagent(unit, string.lower(uName))
            if rInfo then
                local n = tooltip:NumLines() or 0
                local tName = tooltip:GetName()
                local alreadyHas = false
                if tName then
                    for i = 1, n do
                        local line = _G[tName .. "TextLeft" .. i]
                        if line and line:GetText() and line:GetText():find("Reagente", 1, true) then
                            alreadyHas = true
                            break
                        end
                    end
                end
                if not alreadyHas then
                    local countStr = ""
                    if rInfo.targetCount and rInfo.targetCount > 0 then
                        countStr = string.format(" (%d/%d)", rInfo.curCount or 0, rInfo.targetCount)
                    elseif rInfo.curCount and rInfo.curCount > 0 then
                        countStr = string.format(" (%d)", rInfo.curCount)
                    end
                    tooltip:AddLine(string.format("|cff40e0d0Reagente tracciato:|r |cffffffff%s|r|cffffd100%s|r", rInfo.name or "Reagente", countStr), 1, 1, 1)
                    tooltip:Show()
                end
            end
        end
        return
    end

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
        end)
    end
    if PartyMemberFrame_UpdateMemberHealth then
        hooksecurefunc("PartyMemberFrame_UpdateMemberHealth", function(frame)
            UpdatePartyMember(frame)
        end)
    end
    if PartyMemberFrame_UpdateArt then
        hooksecurefunc("PartyMemberFrame_UpdateArt", function(frame)
            UpdatePartyMember(frame)
        end)
    end
    if PartyMemberFrame_UpdateOnlineStatus then
        hooksecurefunc("PartyMemberFrame_UpdateOnlineStatus", function(frame)
            UpdatePartyMember(frame)
        end)
    end
    if PartyMemberFrameMixin then
        if type(PartyMemberFrameMixin.UpdateMember) == "function" then
            hooksecurefunc(PartyMemberFrameMixin, "UpdateMember", function(frame) UpdatePartyMember(frame) end)
        end
        if type(PartyMemberFrameMixin.UpdateHealth) == "function" then
            hooksecurefunc(PartyMemberFrameMixin, "UpdateHealth", function(frame) UpdatePartyMember(frame) end)
        end
        if type(PartyMemberFrameMixin.UpdateArt) == "function" then
            hooksecurefunc(PartyMemberFrameMixin, "UpdateArt", function(frame) UpdatePartyMember(frame) end)
        end
    end
    if PartyMemberBuffTooltip and not PartyMemberBuffTooltip.nkHooked then
        PartyMemberBuffTooltip.nkHooked = true
        PartyMemberBuffTooltip:HookScript("OnShow", function(self)
            if IsClassFeaturesEnabled() then
                self:Hide()
            end
        end)
    end
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            if f.HookScript and not f.nkShowHooked then
                f.nkShowHooked = true
                f:HookScript("OnShow", function(self)
                    UpdatePartyMember(self)
                end)
            end
            if f.HookScript and not f.nkEventHooked then
                f.nkEventHooked = true
                f:HookScript("OnEvent", function(self, event, ...)
                    UpdatePartyMember(self)
                end)
            end
            if type(f.UpdateMember) == "function" and not f.nkUpdateMemberHooked then
                f.nkUpdateMemberHooked = true
                hooksecurefunc(f, "UpdateMember", function(self) UpdatePartyMember(self) end)
            end
            if type(f.UpdateHealth) == "function" and not f.nkUpdateHealthHooked then
                f.nkUpdateHealthHooked = true
                hooksecurefunc(f, "UpdateHealth", function(self) UpdatePartyMember(self) end)
            end
        end
    end
    if PartyMemberFrame_OnEnter then
        hooksecurefunc("PartyMemberFrame_OnEnter", function(self)
            if not IsClassFeaturesEnabled() then return end
            local u = self.unit or (self.GetID and ("party" .. self:GetID()))
            if u and UnitExists(u) and UnitIsPlayer(u) then
                EnhanceUnitTooltip(GameTooltip, u)
            end
        end)
    end
    if PartyMemberFrame_UpdateDebuffs then
        hooksecurefunc("PartyMemberFrame_UpdateDebuffs", function(frame)
            if not IsClassFeaturesEnabled() then return end
            -- Hide Blizzard's duplicate hover debuffs to keep the permanent row clean
            for d = 1, 4 do
                local bDebuff = _G[frame:GetName() .. "Debuff" .. d]
                if bDebuff then bDebuff:Hide() end
            end
        end)
    end
    if UnitFrameHealthBar_Update then
        hooksecurefunc("UnitFrameHealthBar_Update", function(bar, unit)
            local actualUnit = unit or (bar and bar.unit) or (bar and bar:GetParent() and bar:GetParent().unit)
            if not IsClassFeaturesEnabled() or not actualUnit or not UnitExists(actualUnit) or not UnitIsPlayer(actualUnit) then return end
            if actualUnit == "target" then
                UpdateTargetFrame()
            elseif actualUnit:match("^party%d+$") then
                local num = actualUnit:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        end)
    end
    if TargetFrame_Update then
        hooksecurefunc("TargetFrame_Update", function()
            UpdateTargetFrame()
        end)
    end

    -- CompactUnitFrame (Raid-Style Party & Raid frames + Nameplates)
    -- Visual updates only (includeAuras = false) to prevent taint/secret restrictions in internal Blizzard hooks
    if CompactUnitFrame_UpdateName then
        hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
            if not frame or IsForbiddenObj(frame) then return end
            local unit = frame.unit or frame.displayedUnit
            if not unit then return end
            if unit:find("^nameplate%d+$") then
                UpdateNameplateUnit(unit)
            elseif unit:find("^party%d+$") or unit:find("^raid%d+$") or unit == "player" then
                UpdateCompactPartyFrame(frame, false)
            end
        end)
    end
    if CompactUnitFrame_UpdateHealth then
        hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
            if not frame or IsForbiddenObj(frame) then return end
            local unit = frame.unit or frame.displayedUnit
            if not unit then return end
            if unit:find("^nameplate%d+$") then
                UpdateNameplateUnit(unit)
            elseif unit:find("^party%d+$") or unit:find("^raid%d+$") or unit == "player" then
                UpdateCompactPartyFrame(frame, false)
            end
        end)
    end
    if CompactUnitFrame_UpdateHealthColor then
        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
            if not frame or IsForbiddenObj(frame) then return end
            local unit = frame.unit or frame.displayedUnit
            if not unit then return end
            if unit:find("^nameplate%d+$") then
                UpdateNameplateUnit(unit)
            elseif unit:find("^party%d+$") or unit:find("^raid%d+$") or unit == "player" then
                UpdateCompactPartyFrame(frame, false)
            end
        end)
    end
    if CompactUnitFrame_UpdateStatusText then
        hooksecurefunc("CompactUnitFrame_UpdateStatusText", function(frame)
            if not frame or IsForbiddenObj(frame) then return end
            local unit = frame.unit or frame.displayedUnit
            if not unit then return end
            if unit:find("^party%d+$") or unit:find("^raid%d+$") or unit == "player" then
                UpdateCompactPartyFrame(frame, false)
            end
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
SafeRegisterEvent(evFrame, "PARTY_LEADER_CHANGED")
SafeRegisterEvent(evFrame, "PARTY_MEMBER_ENABLE")
SafeRegisterEvent(evFrame, "PARTY_MEMBER_DISABLE")
SafeRegisterEvent(evFrame, "RAID_ROSTER_UPDATE")
SafeRegisterEvent(evFrame, "UNIT_CONNECTION")
SafeRegisterEvent(evFrame, "UNIT_PORTRAIT_UPDATE")
SafeRegisterEvent(evFrame, "ZONE_CHANGED_NEW_AREA")
SafeRegisterEvent(evFrame, "PLAYER_TARGET_CHANGED")
SafeRegisterEvent(evFrame, "NAME_PLATE_UNIT_ADDED")
SafeRegisterEvent(evFrame, "NAME_PLATE_UNIT_REMOVED")
SafeRegisterEvent(evFrame, "UNIT_NAME_UPDATE")
SafeRegisterEvent(evFrame, "UNIT_HEALTH")
SafeRegisterEvent(evFrame, "UNIT_MAXHEALTH")
SafeRegisterEvent(evFrame, "UNIT_AURA")
SafeRegisterEvent(evFrame, "INSPECT_READY")
SafeRegisterEvent(evFrame, "PLAYER_TALENT_UPDATE")
SafeRegisterEvent(evFrame, "CHARACTER_POINTS_CHANGED")

evFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    pcall(function()
        if event == "PLAYER_LOGIN" then
            HookBlizzardUnitFrames()
            UpdateAllPartyMembers()
            UpdateTargetFrame()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED"
            or event == "PARTY_LEADER_CHANGED" or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE"
            or event == "RAID_ROSTER_UPDATE" or event == "UNIT_CONNECTION" or event == "ZONE_CHANGED_NEW_AREA" then
            UpdateAllPartyMembers()
            UpdateTargetFrame()
        elseif event == "UNIT_PORTRAIT_UPDATE" then
            if arg1 and arg1:match("^party%d+$") then
                local num = arg1:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateTargetFrame()
            if UnitExists("target") and UnitIsPlayer("target") then
                UpdateNameplateUnit("target")
            end
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            UpdateNameplateUnit(arg1)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            RemoveNameplateUnit(arg1)
        elseif event == "UNIT_NAME_UPDATE" then
            if arg1 and arg1:match("^nameplate%d+$") then
                UpdateNameplateUnit(arg1)
            elseif arg1 and arg1:match("^party%d+$") then
                local num = arg1:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if arg1 == "target" then
                UpdateTargetFrame()
            elseif arg1 and arg1:match("^party%d+$") then
                local num = arg1:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            elseif arg1 and arg1:match("^nameplate%d+$") then
                UpdateNameplateUnit(arg1)
            end
        elseif event == "UNIT_AURA" then
            if arg1 then
                if arg1:match("^party%d+$") then
                    local num = arg1:match("^party(%d+)$")
                    local f = _G["PartyMemberFrame" .. num]
                    if f then pcall(UpdatePartyAuras, f) end
                end
                if CompactPartyFrame and CompactPartyFrame:IsShown() then
                    for i = 1, 5 do
                        local f = _G["CompactPartyFrameMember" .. i]
                        if f and (f.unit == arg1 or f.displayedUnit == arg1) then
                            pcall(UpdateCompactPartyAuras, f)
                        end
                    end
                end
                if CompactRaidFrameContainer and CompactRaidFrameContainer:IsShown() and CompactRaidFrameContainer_ApplyToFrames then
                    pcall(CompactRaidFrameContainer_ApplyToFrames, CompactRaidFrameContainer, "normal", function(f)
                        if f and (f.unit == arg1 or f.displayedUnit == arg1) then
                            pcall(UpdateCompactPartyAuras, f)
                        end
                    end)
                end
            end
        elseif event == "INSPECT_READY" then
            HandleInspectReady(arg1)
        elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" then
            if currentTooltipOwner and currentTooltipUnit and UnitIsUnit(currentTooltipUnit, "player") then
                ShowPortraitTooltip(currentTooltipOwner, currentTooltipUnit)
            end
        end
    end)
end)

-- Lightweight polling ticker while in party (refreshes party frames every 0.5s so class info, colors, badges and permanent auras are NEVER delayed or lost)
local partyElapsed = 0
evFrame:SetScript("OnUpdate", function(self, elapsed)
    partyElapsed = partyElapsed + (elapsed or 0)
    if partyElapsed >= 0.5 then
        partyElapsed = 0
        if IsClassFeaturesEnabled() then
            local inGroup = (IsInGroup and IsInGroup()) or (GetNumGroupMembers and GetNumGroupMembers() > 0)
            if inGroup then
                UpdateAllPartyMembers()
            end
        end
    end
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

function FP:DumpPartyStatus()
    local enabled = IsClassFeaturesEnabled()
    local inGrp = (IsInGroup and IsInGroup()) or false
    local nMembers = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    FP:Print(string.format("ClassFrames: %s | InGroup: %s | Members: %d", enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r", tostring(inGrp), nMembers))
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            local u = f.unit or ("party" .. i)
            local exists = UnitExists(u)
            local name = UnitName(u) or "n/a"
            local _, engClass = UnitClass(u)
            local badgeShown = (f.nkClassBadge and f.nkClassBadge:IsShown()) and true or false
            local aurasShown = (f.nkPermanentAuras and f.nkPermanentAuras:IsShown()) and true or false
            FP:Print(string.format("  Party%d: shown=%s unit=%s exists=%s name=%s class=%s badge=%s auras=%s",
                i, tostring(f:IsShown()), u, tostring(exists), name, tostring(engClass), tostring(badgeShown), tostring(aurasShown)))
        end
    end
end
