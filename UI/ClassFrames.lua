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

local function SafeBoolean(val, fallback)
    if val == nil then return fallback end
    if issecretvalue and issecretvalue(val) then return fallback end
    local ok, res = pcall(function()
        if val then return true else return false end
    end)
    if ok then
        return res
    end
    return fallback
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

local CLASS_CIRCLE_TEXTURE = "Interface\\TargetingFrame\\UI-Classes-Circles"
local CLASS_CREATE_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

local function GetUnitClassColor(unit)
    if not unit then return nil, nil end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or SafeBoolean(exists, false) ~= true then return nil, nil end

    local isPartyOrPlayer = (unit == "player") or (type(unit) == "string" and unit:match("^party%d+$") ~= nil)
    if not isPartyOrPlayer then
        local okP, isPlayer = pcall(UnitIsPlayer, unit)
        if not okP or SafeBoolean(isPlayer, false) ~= true then
            return nil, nil
        end
    end

    local ok, locClass, class = pcall(UnitClass, unit)
    if not ok then return nil, nil end
    if issecretvalue and (issecretvalue(class) or issecretvalue(locClass)) then return nil, nil end
    if not class or class == "" then
        if locClass and LOCALIZED_CLASS_MAP[locClass] then
            class = LOCALIZED_CLASS_MAP[locClass]
        else
            return nil, nil
        end
    end

    if type(class) ~= "string" or class == "" then return nil, nil end

    class = string.upper(class)
    local color = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
        or (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or { r = 0.8, g = 0.8, b = 0.8 }
    return color, class
end

local function ApplyClassIconToPortrait(portrait, class)
    if not portrait or not class then return end
    class = string.upper(class)
    if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then
        portrait:SetTexture(CLASS_CIRCLE_TEXTURE)
        portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
    elseif FALLBACK_CLASS_COORDS[class] then
        portrait:SetTexture(CLASS_CREATE_TEXTURE)
        portrait:SetTexCoord(unpack(FALLBACK_CLASS_COORDS[class]))
    end
end

local function ApplyClassTextureToIcon(icon, class)
    if not icon or not class then return end
    ApplyClassIconToPortrait(icon, class)
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
        -- 1. Modern WoW Specialization API (Retail, The War Within 11.0+, etc.)
        local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
        local getSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
        if type(getSpec) == "function" and type(getSpecInfo) == "function" then
            local ok, specIndex = pcall(getSpec)
            if ok and specIndex and type(specIndex) == "number" and specIndex > 0 then
                local okInfo, _, name = pcall(getSpecInfo, specIndex)
                if okInfo and name and type(name) == "string" and name ~= "" then
                    return name, nil
                end
            end
        end

        -- 2. Classic Talent Tabs API (Classic Era, TBC, WotLK)
        if type(GetTalentTabInfo) == "function" then
            local maxPoints = -1
            local topName = nil
            local p = {}
            local rawNum = (type(GetNumTalentTabs) == "function") and GetNumTalentTabs() or 3
            local numTabs = tonumber(rawNum) or 3
            for tab = 1, numTabs do
                local ok, _, name, _, _, points = pcall(GetTalentTabInfo, tab)
                if ok then
                    points = tonumber(points) or 0
                    p[#p + 1] = points
                    if points > maxPoints then
                        maxPoints = points
                        topName = name
                    end
                end
            end
            local pts = (#p > 0) and table.concat(p, "/") or nil
            if maxPoints <= 0 then
                return nil, pts
            end
            return topName, pts
        end
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
    pcall(function()
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

        local levelStr = "??"
        if level then
            local okLvl, isPos = pcall(function() return level > 0 end)
            if okLvl and isPos then
                levelStr = "Livello " .. tostring(level)
            end
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

            if race then
                GameTooltip:AddLine(string.format("|cffaaaaaa%s %s|r", levelStr, race), 0.8, 0.8, 0.8)
            else
                GameTooltip:AddLine(string.format("|cffaaaaaa%s|r", levelStr), 0.8, 0.8, 0.8)
            end
        else
            local creatureType = UnitCreatureType and UnitCreatureType(unit)
            if creatureType then
                GameTooltip:AddLine(string.format("|cffaaaaaa%s %s|r", levelStr, creatureType), 0.8, 0.8, 0.8)
            else
                GameTooltip:AddLine(string.format("|cffaaaaaa%s|r", levelStr), 0.8, 0.8, 0.8)
            end
        end

        GameTooltip:Show()
        currentTooltipOwner = owner
        currentTooltipUnit = unit
    end)
end

local function HandleInspectReady(guid)
    local actualGuid = guid or lastInspectTargetGUID
    if not actualGuid then return end
    if lastInspectTargetGUID and actualGuid ~= lastInspectTargetGUID then return end
    lastInspectTargetGUID = nil

    local topName = nil
    local pts = nil

    -- 1. Modern WoW Inspect Specialization (Retail, TWW 11.0+)
    if GetInspectSpecialization and GetSpecializationInfoByID then
        local ok, specID = pcall(GetInspectSpecialization, currentTooltipUnit or "target")
        if ok and specID and type(specID) == "number" and specID > 0 then
            local okInfo, _, name = pcall(GetSpecializationInfoByID, specID)
            if okInfo and name and type(name) == "string" and name ~= "" then
                topName = name
            end
        end
    end

    -- 2. Classic Talent Tabs Inspect (Classic Era, TBC, WotLK)
    if not topName and type(GetTalentTabInfo) == "function" then
        local rawNum = (type(GetNumTalentTabs) == "function") and GetNumTalentTabs(true) or 3
        local numTabs = tonumber(rawNum) or 3
        local maxPoints = -1
        local p = {}
        for tab = 1, numTabs do
            local ok, _, name, _, _, points = pcall(GetTalentTabInfo, tab, true)
            if ok then
                points = tonumber(points) or 0
                p[#p + 1] = points
                if points > maxPoints then
                    maxPoints = points
                    topName = name
                end
            end
        end
        if #p > 0 then
            pts = table.concat(p, "/")
        end
        if maxPoints <= 0 then
            topName = nil
        end
    end

    cachedPlayerSpecs[actualGuid] = {
        specName = topName,
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

-- Permanent Buffs & Debuffs to the RIGHT of the Party Frame (ALWAYS visible without mouse hover!)
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
        -- Positioned to the RIGHT of the party frame (anchored TOPLEFT to frame's TOPRIGHT, 6px offset)
        container:SetSize(190, 44)
        container:SetPoint("TOPLEFT", frame, "TOPRIGHT", 6, -2)
        container:SetFrameStrata("MEDIUM")
        container:SetFrameLevel(45)
        frame.nkPermanentAuras = container

        -- Row 1: Debuffs (up to 4 debuffs, 18x18, dispel borders)
        container.debuffSlots = {}
        for d = 1, 4 do
            local btn = CreateFrame("Button", nil, container)
            btn:SetSize(18, 18)
            btn:SetPoint("TOPLEFT", container, "TOPLEFT", (d - 1) * 21, 0)

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
                GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            container.debuffSlots[d] = btn
        end

        -- Row 2: Buffs (up to 8 buffs, 16x16)
        container.buffSlots = {}
        for b = 1, 8 do
            local btn = CreateFrame("Button", nil, container)
            btn:SetSize(16, 16)
            btn:SetPoint("TOPLEFT", container, "TOPLEFT", (b - 1) * 19, -21)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(btn)
            btn.icon = icon

            local border = btn:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            border:SetTexCoord(0, 1, 0, 1)
            border:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
            border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.border = border

            local countFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.countFs = countFs

            btn:SetScript("OnEnter", function(self)
                if not self.unit or not self.auraIndex then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            container.buffSlots[b] = btn
        end
    end

    container:Show()

    local debuffs = GetPartyUnitDebuffs(unit)
    local buffs = GetPartyUnitBuffs(unit)

    local numDebuffs = math.min(#debuffs, 4)
    local numBuffs = math.min(#buffs, 8)

    -- If no debuffs are present, vertically center buffs at Y = -11; if debuffs exist, place on Row 2 at Y = -21
    local buffYOffset = (numDebuffs > 0) and -21 or -11

    -- 1. Display Debuffs (dispellable ones first with bright dispel color)
    for d = 1, 4 do
        local btn = container.debuffSlots[d]
        if d <= numDebuffs then
            local debuff = debuffs[d]
            btn.unit = unit
            btn.auraIndex = debuff.index
            btn.icon:SetTexture(debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            btn.border:SetVertexColor(col.r, col.g, col.b, 1)
            btn.border:Show()
            if debuff.count and debuff.count > 1 then
                btn.countFs:SetText(debuff.count)
                btn.countFs:Show()
            else
                btn.countFs:Hide()
            end
            btn:Show()
        else
            btn:Hide()
        end
    end

    -- 2. Display Buffs (player's own buffs in golden yellow, others subtle)
    for b = 1, 8 do
        local btn = container.buffSlots[b]
        if b <= numBuffs then
            local buff = buffs[b]
            btn.unit = unit
            btn.auraIndex = buff.index
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", container, "TOPLEFT", (b - 1) * 19, buffYOffset)
            btn.icon:SetTexture(buff.icon)
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
        else
            btn:Hide()
        end
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

    local exists = false
    if unit and UnitExists then
        local okE, ex = pcall(UnitExists, unit)
        if okE then exists = SafeBoolean(ex, false) end
    end
    if not exists then
        if frame.nkClassBadge then frame.nkClassBadge:Hide() end
        if frame.nkPermanentAuras then frame.nkPermanentAuras:Hide() end
        return
    end

    -- Hide old floating badge if any
    if frame.nkClassBadge then
        frame.nkClassBadge:Hide()
    end

    local color, class = GetUnitClassColor(unit)
    if not color or not class then
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

    local frameName = frame.GetName and frame:GetName()

    -- 1. Class Icon on Portrait (Replaces 3D model portrait with circular class icon, like Leatrix Plus / EasyFrames)
    local portrait = frame.portrait or (frameName and _G[frameName .. "Portrait"])
    if portrait then
        ApplyClassIconToPortrait(portrait, class)
        local isConn = true
        if UnitIsConnected then
            local okC, conn = pcall(UnitIsConnected, unit)
            if okC then isConn = SafeBoolean(conn, true) end
        end
        if isConn then
            portrait:SetVertexColor(1, 1, 1, 1)
        else
            portrait:SetVertexColor(0.5, 0.5, 0.5, 1)
        end
    end

    -- 2. Class-color Party Member Healthbar & lockColor = true to prevent Blizzard resets
    local healthbar = frame.healthbar or (frameName and _G[frameName .. "HealthBar"])
    if healthbar and healthbar.SetStatusBarColor then
        healthbar.lockColor = true
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
                    self.lockColor = true
                    self:SetStatusBarColor(c.r, c.g, c.b)
                    self.nkIsSettingColor = false
                end
            end)
        end
    end

    -- 3. Class-color Party Member Name text
    local nameFs = frame.name or (frameName and _G[frameName .. "Name"])
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

    -- 4. Update Party Auras (Permanently visible: Buffs & Debuffs to the right of frame)
    pcall(UpdatePartyAuras, frame)
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

-------------------------------------------------------------------------------
-- 1c. Raid-Style Grid Party Frames (Grid / Incursione Stile)
-------------------------------------------------------------------------------
local function IsGridPartyEnabled()
    return IsClassFeaturesEnabled() and GetSettings().useGridPartyFrames ~= false
end

local GRID_UNITS = { "player", "party1", "party2", "party3", "party4" }
local gridMembers = {}
local gridContainer = CreateFrame("Frame", "NexusKitPartyGrid", UIParent)
gridContainer:SetSize(114, 240)
gridContainer:SetClampedToScreen(true)
gridContainer:SetMovable(true)
gridContainer:SetPoint("LEFT", UIParent, "LEFT", 30, 40)
gridContainer:Hide()

local dragBar = CreateFrame("Frame", nil, gridContainer, "BackdropTemplate")
dragBar:SetSize(114, 18)
dragBar:SetPoint("BOTTOMLEFT", gridContainer, "TOPLEFT", 0, 2)
dragBar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
dragBar:SetBackdropColor(0.08, 0.08, 0.08, 0.88)
dragBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

local dragText = dragBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dragText:SetPoint("CENTER", dragBar, "CENTER", 0, 0)
dragText:SetText("Griglia Party [Sposta]")
dragText:SetTextColor(0, 1, 0.6, 1)

dragBar:EnableMouse(true)
dragBar:RegisterForDrag("LeftButton")
dragBar:SetScript("OnDragStart", function()
    gridContainer:StartMoving()
end)
dragBar:SetScript("OnDragStop", function()
    gridContainer:StopMovingOrSizing()
    local point, _, relPoint, x, y = gridContainer:GetPoint()
    local s = GetSettings()
    s.gridPartyPos = { point = point, relPoint = relPoint, x = x, y = y }
end)
dragBar:Hide()

local function CheckUnitRange(unit)
    if not unit then return false end
    if UnitExists then
        local okE, exists = pcall(UnitExists, unit)
        if not okE or SafeBoolean(exists, false) ~= true then return false end
    end
    if UnitIsUnit then
        local okU, isSelf = pcall(UnitIsUnit, unit, "player")
        if okU and SafeBoolean(isSelf, false) == true then return true end
    end
    if CheckInteractDistance then
        local okD, inDist = pcall(CheckInteractDistance, unit, 4)
        if okD then
            local b = SafeBoolean(inDist, nil)
            if b ~= nil then return b end
        end
    end
    if UnitInRange then
        local okR, inRange, checked = pcall(UnitInRange, unit)
        if okR then
            local isChecked = SafeBoolean(checked, false)
            if isChecked then
                return SafeBoolean(inRange, true)
            end
        end
    end
    return true
end

for i = 1, 5 do
    local unit = GRID_UNITS[i]
    local btn = CreateFrame("Button", "NKPartyGridMember" .. i, gridContainer, "SecureUnitButtonTemplate")
    btn:SetSize(114, 44)
    btn:SetAttribute("type1", "target")
    btn:SetAttribute("unit", unit)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn.unit = unit

    btn:SetPoint("TOPLEFT", gridContainer, "TOPLEFT", 0, -((i - 1) * 47))

    -- 1px cell border
    local border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    border:SetAllPoints(btn)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0.12, 0.12, 0.12, 0.95)
    btn.border = border

    -- Threat / Aggro Border (Red)
    local threatBorder = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    threatBorder:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    threatBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    threatBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    threatBorder:SetBackdropBorderColor(1.0, 0.1, 0.1, 1.0)
    threatBorder:Hide()
    btn.threatBorder = threatBorder

    -- Target Highlight Border (Gold/White)
    local targetBorder = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    targetBorder:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    targetBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    targetBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1.5,
    })
    targetBorder:SetBackdropBorderColor(1.0, 0.95, 0.6, 0.95)
    targetBorder:Hide()
    btn.targetBorder = targetBorder

    -- Health Bar
    local hpBar = CreateFrame("StatusBar", nil, btn)
    hpBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    hpBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 6)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    btn.hpBar = hpBar

    -- Darkened background for missing health deficit
    local hpBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints(hpBar)
    hpBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    hpBg:SetVertexColor(0.1, 0.1, 0.1, 0.88)
    btn.hpBg = hpBg

    -- Power Bar (bottom)
    local powerBar = CreateFrame("StatusBar", nil, btn)
    powerBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 1, 1)
    powerBar:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    powerBar:SetHeight(5)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    powerBar:SetMinMaxValues(0, 1)
    powerBar:SetValue(1)
    btn.powerBar = powerBar

    local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(powerBar)
    powerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    powerBg:SetVertexColor(0.05, 0.05, 0.05, 0.9)
    btn.powerBg = powerBg

    -- Name Text (Crisp white with shadow)
    local nameText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("TOPLEFT", hpBar, "TOPLEFT", 4, -3)
    nameText:SetShadowOffset(1, -1)
    nameText:SetJustifyH("LEFT")
    btn.nameText = nameText

    -- Health Deficit / Status Text
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -4, -3)
    hpText:SetShadowOffset(1, -1)
    hpText:SetJustifyH("RIGHT")
    btn.hpText = hpText

    -- HoT / Buff Icons (3 slots in the center row)
    btn.buffSlots = {}
    for b = 1, 3 do
        local bBtn = CreateFrame("Button", nil, hpBar)
        bBtn:SetSize(15, 15)
        bBtn:SetPoint("CENTER", hpBar, "CENTER", (b - 2) * 17, -3)

        local icon = bBtn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(bBtn)
        bBtn.icon = icon

        local bBorder = bBtn:CreateTexture(nil, "OVERLAY")
        bBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        bBorder:SetTexCoord(0, 1, 0, 1)
        bBorder:SetPoint("TOPLEFT", bBtn, "TOPLEFT", -2, 2)
        bBorder:SetPoint("BOTTOMRIGHT", bBtn, "BOTTOMRIGHT", 2, -2)
        bBorder:SetVertexColor(0.4, 0.4, 0.4, 0.6)
        bBtn.border = bBorder

        local countFs = bBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countFs:SetPoint("BOTTOMRIGHT", bBtn, "BOTTOMRIGHT", 2, -1)
        bBtn.countFs = countFs

        bBtn:SetScript("OnEnter", function(self)
            if not self.unit or not self.auraIndex then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
            GameTooltip:Show()
        end)
        bBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bBtn:Hide()

        btn.buffSlots[b] = bBtn
    end

    -- Debuff Icons (2 slots in top right)
    btn.debuffSlots = {}
    for d = 1, 2 do
        local dBtn = CreateFrame("Button", nil, hpBar)
        dBtn:SetSize(16, 16)
        dBtn:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -((d - 1) * 18 + 2), -2)

        local icon = dBtn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(dBtn)
        dBtn.icon = icon

        local dBorder = dBtn:CreateTexture(nil, "OVERLAY")
        dBorder:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        dBorder:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        dBorder:SetPoint("TOPLEFT", dBtn, "TOPLEFT", -2, 2)
        dBorder:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", 2, -2)
        dBtn.border = dBorder

        local countFs = dBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countFs:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", 2, -1)
        dBtn.countFs = countFs

        dBtn:SetScript("OnEnter", function(self)
            if not self.unit or not self.auraIndex then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
            GameTooltip:Show()
        end)
        dBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        dBtn:Hide()

        btn.debuffSlots[d] = dBtn
    end

    btn:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) then
            ShowPortraitTooltip(self, self.unit)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if currentTooltipOwner == self then
            currentTooltipOwner = nil
            currentTooltipUnit = nil
        end
        GameTooltip:Hide()
    end)
    btn:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and not (InCombatLockdown and InCombatLockdown()) then
            local u = self.unit
            if u and UnitExists(u) then
                if u == "player" and PlayerFrameDropDown then
                    ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor")
                else
                    local num = u:match("^party(%d+)$")
                    local dd = num and _G["PartyMemberFrame" .. num .. "DropDown"]
                    if dd then
                        ToggleDropDownMenu(1, nil, dd, "cursor")
                    end
                end
            end
        end
    end)

    gridMembers[i] = btn
end

local function UpdateGridMember(btn)
    if not btn then return end
    local unit = btn.unit
    local exists = false
    if unit and UnitExists then
        local okE, ex = pcall(UnitExists, unit)
        if okE then exists = SafeBoolean(ex, false) end
    end
    if not exists then
        btn:Hide()
        return
    end

    btn:Show()

    local color, class = GetUnitClassColor(unit)
    color = color or { r = 0.6, g = 0.6, b = 0.6 }

    local name = UnitName(unit) or unit
    if #name > 11 then
        name = string.sub(name, 1, 9) .. ".."
    end
    btn.nameText:SetText(name)

    local hp = (UnitHealth and UnitHealth(unit)) or 0
    local maxHp = (UnitHealthMax and UnitHealthMax(unit)) or 1

    local isSafeHp = true
    if issecretvalue and issecretvalue(hp) then isSafeHp = false end
    if issecretvalue and issecretvalue(maxHp) then isSafeHp = false end
    if isSafeHp then
        local okDiff = pcall(function() return maxHp - hp end)
        if not okDiff then isSafeHp = false end
    end
    if not isSafeHp then
        hp = 1
        maxHp = 1
    end
    if maxHp <= 0 then maxHp = 1 end

    btn.hpBar:SetMinMaxValues(0, maxHp)
    btn.hpBar:SetValue(hp)

    local isDead = false
    local isGhost = false
    if UnitIsGhost then
        local okG, ghost = pcall(UnitIsGhost, unit)
        if okG then isGhost = SafeBoolean(ghost, false) end
    end
    if UnitIsDead then
        local okD, dead = pcall(UnitIsDead, unit)
        if okD then isDead = SafeBoolean(dead, false) end
    end
    if isGhost then isDead = true end

    local isConnected = true
    if UnitIsConnected then
        local okC, conn = pcall(UnitIsConnected, unit)
        if okC then isConnected = SafeBoolean(conn, true) end
    end

    if not isConnected then
        btn.hpBar:SetStatusBarColor(0.4, 0.4, 0.4)
        btn.hpBg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
        btn.hpText:SetText("|cff888888Off|r")
    elseif isDead then
        btn.hpBar:SetStatusBarColor(0.25, 0.25, 0.25)
        btn.hpBg:SetVertexColor(0.1, 0.1, 0.1, 0.9)
        btn.hpText:SetText(isGhost and "|cffaaaaaaFantasma|r" or "|cffff2020Morto|r")
    else
        btn.hpBar:SetStatusBarColor(color.r, color.g, color.b)
        btn.hpBg:SetVertexColor(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.9)
        local deficit = (isSafeHp and (maxHp - hp)) or 0
        if isSafeHp and deficit > 0 then
            if deficit >= 1000 then
                btn.hpText:SetText(string.format("-%.1fk", deficit / 1000))
            else
                btn.hpText:SetText(string.format("-%d", deficit))
            end
            btn.hpText:SetTextColor(1.0, 0.35, 0.35, 1.0)
        else
            btn.hpText:SetText("")
        end
    end

    local power = (UnitPower and UnitPower(unit)) or 0
    local maxPower = (UnitPowerMax and UnitPowerMax(unit)) or 1
    local isSafePower = true
    if issecretvalue and issecretvalue(power) then isSafePower = false end
    if issecretvalue and issecretvalue(maxPower) then isSafePower = false end
    if isSafePower then
        local okDiff = pcall(function() return maxPower - power end)
        if not okDiff then isSafePower = false end
    end
    if not isSafePower then
        power = 0
        maxPower = 1
    end
    if maxPower <= 0 then maxPower = 1 end

    btn.powerBar:SetMinMaxValues(0, maxPower)
    btn.powerBar:SetValue(power)

    local powerType = (UnitPowerType and UnitPowerType(unit)) or 0
    if powerType == 0 then
        btn.powerBar:SetStatusBarColor(0.18, 0.45, 0.95)
    elseif powerType == 1 then
        btn.powerBar:SetStatusBarColor(0.92, 0.2, 0.2)
    elseif powerType == 3 then
        btn.powerBar:SetStatusBarColor(0.95, 0.85, 0.15)
    elseif powerType == 6 then
        btn.powerBar:SetStatusBarColor(0.0, 0.82, 1.0)
    else
        btn.powerBar:SetStatusBarColor(0.5, 0.5, 0.5)
    end

    -- Threat / Aggro Border (Red)
    local threat = nil
    if UnitThreatSituation then
        local okT, tVal = pcall(UnitThreatSituation, unit)
        if okT and tVal and (not issecretvalue or not issecretvalue(tVal)) then
            threat = tVal
        end
    end
    if threat and threat >= 3 then
        btn.threatBorder:Show()
        btn.threatBorder:SetBackdropBorderColor(1.0, 0.1, 0.1, 1.0)
    elseif threat and threat >= 2 then
        btn.threatBorder:Show()
        btn.threatBorder:SetBackdropBorderColor(1.0, 0.6, 0.0, 1.0)
    else
        btn.threatBorder:Hide()
    end

    -- Target Highlight Border
    local isTarget = false
    if UnitIsUnit then
        local okT, same = pcall(UnitIsUnit, unit, "target")
        if okT then isTarget = SafeBoolean(same, false) end
    end
    if isTarget then
        btn.targetBorder:Show()
    else
        btn.targetBorder:Hide()
    end

    -- Range Check / Fading
    local inRange = CheckUnitRange(unit)
    btn:SetAlpha(inRange and 1.0 or 0.55)

    -- Auras (Buffs & HoTs)
    local buffs = GetPartyUnitBuffs(unit)
    for b = 1, 3 do
        local bBtn = btn.buffSlots[b]
        if b <= #buffs then
            local buff = buffs[b]
            bBtn.unit = unit
            bBtn.auraIndex = buff.index
            bBtn.icon:SetTexture(buff.icon)
            if buff.isPlayerBuff then
                bBtn.border:SetVertexColor(1.0, 0.85, 0.0, 0.95)
            else
                bBtn.border:SetVertexColor(0.4, 0.4, 0.4, 0.6)
            end
            if buff.count and buff.count > 1 then
                bBtn.countFs:SetText(buff.count)
                bBtn.countFs:Show()
            else
                bBtn.countFs:Hide()
            end
            bBtn:Show()
        else
            bBtn:Hide()
        end
    end

    -- Debuffs (Top right)
    local debuffs = GetPartyUnitDebuffs(unit)
    for d = 1, 2 do
        local dBtn = btn.debuffSlots[d]
        if d <= #debuffs then
            local debuff = debuffs[d]
            dBtn.unit = unit
            dBtn.auraIndex = debuff.index
            dBtn.icon:SetTexture(debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            dBtn.border:SetVertexColor(col.r, col.g, col.b, 1)
            if debuff.count and debuff.count > 1 then
                dBtn.countFs:SetText(debuff.count)
                dBtn.countFs:Show()
            else
                dBtn.countFs:Hide()
            end
            dBtn:Show()
        else
            dBtn:Hide()
        end
    end
end

local function UpdatePartyGrid()
    if not IsGridPartyEnabled() then
        if gridContainer:IsShown() then gridContainer:Hide() end
        return
    end

    local inGrp = (IsInGroup and IsInGroup())
        or (GetNumGroupMembers and GetNumGroupMembers() > 0)
        or (GetNumPartyMembers and GetNumPartyMembers() > 0)

    local showSolo = GetSettings().gridPartyShowSolo == true
    if not inGrp and not showSolo then
        if gridContainer:IsShown() then gridContainer:Hide() end
        return
    end

    gridContainer:Show()

    local scale = GetSettings().gridPartyScale or 1.0
    gridContainer:SetScale(scale)

    local s = GetSettings()
    if s.gridPartyPos and not gridContainer.posLoaded then
        gridContainer.posLoaded = true
        gridContainer:ClearAllPoints()
        gridContainer:SetPoint(s.gridPartyPos.point, UIParent, s.gridPartyPos.relPoint, s.gridPartyPos.x, s.gridPartyPos.y)
    end

    if s.gridPartyLocked ~= false then
        dragBar:Hide()
        gridContainer:EnableMouse(false)
    else
        dragBar:Show()
        gridContainer:EnableMouse(true)
    end

    local activeCount = 0
    for i = 1, 5 do
        local btn = gridMembers[i]
        local unit = btn.unit
        local exists = false
        if unit and UnitExists then
            local okE, ex = pcall(UnitExists, unit)
            if okE then exists = SafeBoolean(ex, false) end
        end
        if not inGrp and showSolo and i > 1 then
            exists = false
        end
        if exists then
            UpdateGridMember(btn)
            activeCount = activeCount + 1
        else
            btn:Hide()
        end
    end

    gridContainer:SetHeight(math.max(44, activeCount * 47))

    if not (InCombatLockdown and InCombatLockdown()) then
        for i = 1, 4 do
            local f = _G["PartyMemberFrame" .. i]
            if f and f:IsShown() then
                f:Hide()
            end
        end
    end
end

local function UpdateAllPartyMembers()
    if IsGridPartyEnabled() then
        UpdatePartyGrid()
    else
        if gridContainer and gridContainer:IsShown() then
            gridContainer:Hide()
        end
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame then
                local u = frame.unit or ("party" .. i)
                if UnitExists(u) and not (InCombatLockdown and InCombatLockdown()) and not frame:IsShown() then
                    frame:Show()
                end
                UpdatePartyMember(frame)
            end
        end
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

    if SetPortraitTexture then
        hooksecurefunc("SetPortraitTexture", function(portrait, unit)
            if not IsClassFeaturesEnabled() or not portrait or not unit then return end
            if type(unit) == "string" and unit:match("^party%d+$") and UnitExists(unit) then
                local color, class = GetUnitClassColor(unit)
                if class then
                    ApplyClassIconToPortrait(portrait, class)
                end
            end
        end)
    end

    if UnitFramePortrait_Update then
        hooksecurefunc("UnitFramePortrait_Update", function(self)
            if not IsClassFeaturesEnabled() or not self then return end
            local unit = self.unit
            if unit and type(unit) == "string" and unit:match("^party%d+$") and UnitExists(unit) then
                local portrait = self.portrait or (self.GetName and _G[self:GetName() .. "Portrait"])
                if portrait then
                    local color, class = GetUnitClassColor(unit)
                    if class then
                        ApplyClassIconToPortrait(portrait, class)
                    end
                end
            end
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
                    if IsGridPartyEnabled() and not (InCombatLockdown and InCombatLockdown()) then
                        self:Hide()
                        return
                    end
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
            if not IsClassFeaturesEnabled() or not frame then return end
            -- Hide Blizzard's duplicate hover debuffs to keep the permanent row clean
            local frameName = frame.GetName and frame:GetName()
            if frameName then
                for d = 1, 4 do
                    local bDebuff = _G[frameName .. "Debuff" .. d]
                    if bDebuff then bDebuff:Hide() end
                end
            end
            UpdatePartyAuras(frame)
        end)
    end
    if UnitFrameHealthBar_Update then
        hooksecurefunc("UnitFrameHealthBar_Update", function(bar, unit)
            local actualUnit = unit or (bar and bar.unit) or (bar and bar.GetParent and bar:GetParent() and bar:GetParent().unit)
            if not IsClassFeaturesEnabled() or not actualUnit or not UnitExists(actualUnit) then return end
            if actualUnit == "target" then
                UpdateTargetFrame()
            elseif type(actualUnit) == "string" and actualUnit:match("^party%d+$") then
                local num = actualUnit:match("^party(%d+)$")
                local f = _G["PartyMemberFrame" .. num]
                if f then UpdatePartyMember(f) end
            end
        end)
    end
    if HealthBar_OnValueChanged then
        hooksecurefunc("HealthBar_OnValueChanged", function(bar, value)
            local actualUnit = (bar and bar.unit) or (bar and bar.GetParent and bar:GetParent() and bar:GetParent().unit)
            if not IsClassFeaturesEnabled() or not actualUnit or not UnitExists(actualUnit) then return end
            if actualUnit == "target" then
                UpdateTargetFrame()
            elseif type(actualUnit) == "string" and actualUnit:match("^party%d+$") then
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
SafeRegisterEvent(evFrame, "UNIT_POWER_UPDATE")
SafeRegisterEvent(evFrame, "UNIT_MANA")
SafeRegisterEvent(evFrame, "UNIT_ENERGY")
SafeRegisterEvent(evFrame, "UNIT_RAGE")
SafeRegisterEvent(evFrame, "UNIT_THREAT_SITUATION_UPDATE")
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
            if IsGridPartyEnabled() then
                UpdatePartyGrid()
            end
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
                if IsGridPartyEnabled() then
                    UpdatePartyGrid()
                else
                    local num = arg1:match("^party(%d+)$")
                    local f = _G["PartyMemberFrame" .. num]
                    if f then UpdatePartyMember(f) end
                end
            end
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            if arg1 == "target" then
                UpdateTargetFrame()
            elseif arg1 and (arg1:match("^party%d+$") or arg1 == "player") then
                if IsGridPartyEnabled() then
                    UpdatePartyGrid()
                else
                    local num = arg1:match("^party(%d+)$")
                    local f = num and _G["PartyMemberFrame" .. num]
                    if f then UpdatePartyMember(f) end
                end
            elseif arg1 and arg1:match("^nameplate%d+$") then
                UpdateNameplateUnit(arg1)
            end
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MANA" or event == "UNIT_ENERGY" or event == "UNIT_RAGE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
            if IsGridPartyEnabled() and arg1 and (arg1:match("^party%d+$") or arg1 == "player") then
                UpdatePartyGrid()
            end
        elseif event == "UNIT_AURA" then
            if arg1 then
                if IsGridPartyEnabled() and (arg1:match("^party%d+$") or arg1 == "player") then
                    UpdatePartyGrid()
                elseif arg1:match("^party%d+$") then
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

-- Lightweight polling ticker while in party (refreshes party frames every 0.25s so class info, colors, portraits, range, and permanent auras are NEVER delayed or lost)
local partyElapsed = 0
evFrame:SetScript("OnUpdate", function(self, elapsed)
    partyElapsed = partyElapsed + (elapsed or 0)
    if partyElapsed >= 0.25 then
        partyElapsed = 0
        if IsClassFeaturesEnabled() then
            local inGroup = (IsInGroup and IsInGroup())
                or (GetNumGroupMembers and GetNumGroupMembers() > 0)
                or (GetNumPartyMembers and GetNumPartyMembers() > 0)
            local showSolo = GetSettings().gridPartyShowSolo == true
            if inGroup or showSolo then
                UpdateAllPartyMembers()
            end
        end
    end
end)

-- Immediate initialization if already in-game (e.g. after /reload)
if IsLoggedIn and IsLoggedIn() then
    HookBlizzardUnitFrames()
    UpdateAllPartyMembers()
    UpdateTargetFrame()
end

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

function FP:RefreshPartyGridLock()
    local s = GetSettings()
    if dragBar then
        if s.gridPartyLocked ~= false then
            dragBar:Hide()
            gridContainer:EnableMouse(false)
        else
            dragBar:Show()
            gridContainer:EnableMouse(true)
        end
    end
end

function FP:SetPartyGridScale(scale)
    if gridContainer and scale then
        gridContainer:SetScale(scale)
    end
end

function FP:DumpPartyStatus()
    local enabled = IsClassFeaturesEnabled()
    local gridEnabled = IsGridPartyEnabled()
    local inGrp = (IsInGroup and IsInGroup()) or (GetNumGroupMembers and GetNumGroupMembers() > 0) or (GetNumPartyMembers and GetNumPartyMembers() > 0) or false
    local nMembers = (GetNumGroupMembers and GetNumGroupMembers()) or (GetNumPartyMembers and GetNumPartyMembers()) or 0
    FP:Print(string.format("ClassFrames: %s | Style: %s | InGroup: %s | Members: %d",
        enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r",
        gridEnabled and "|cff00ff96GRIGLIA|r" or "|cffffaa00CLASSICO|r",
        tostring(inGrp), nMembers))
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            local u = f.unit or ("party" .. i)
            local exists = UnitExists(u)
            local name = UnitName(u) or "n/a"
            local _, engClass = UnitClass(u)
            local aurasShown = (f.nkPermanentAuras and f.nkPermanentAuras:IsShown()) and true or false
            FP:Print(string.format("  Party%d: shown=%s unit=%s exists=%s name=%s class=%s auras=%s",
                i, tostring(f:IsShown()), u, tostring(exists), name, tostring(engClass), tostring(aurasShown)))
        end
    end
end

SLASH_NKPARTY1 = "/nkparty"
SlashCmdList["NKPARTY"] = function(msg)
    msg = (msg and msg:lower():match("^%s*(.-)%s*$")) or ""
    if msg == "grid" or msg == "classic" then
        SLASH_NKGRID1 = "/nkgrid"
        SlashCmdList["NKGRID"](msg)
    else
        FP:DumpPartyStatus()
        FP:Print("Comandi Party: |cff00ff96/nkgrid|r (alterna Griglia/Classico), |cff00ff96/nkgrid unlock|r (sblocca per spostare), |cff00ff96/nkgrid solo|r (test da solo)")
    end
end

SLASH_NKGRID1 = "/nkgrid"
SlashCmdList["NKGRID"] = function(msg)
    msg = (msg and msg:lower():match("^%s*(.-)%s*$")) or ""
    local s = GetSettings()
    if msg == "unlock" then
        s.gridPartyLocked = false
        FP:RefreshPartyGridLock()
        FP:Print("Griglia Party: |cff00ff00SBLOCCATA|r (trascina la barra in cima per spostarla)")
    elseif msg == "lock" then
        s.gridPartyLocked = true
        FP:RefreshPartyGridLock()
        FP:Print("Griglia Party: |cffffaa00BLOCCATA|r")
    elseif msg == "solo" then
        s.gridPartyShowSolo = not (s.gridPartyShowSolo == true)
        FP:Print("Griglia Party (Anteprima Solo): " .. (s.gridPartyShowSolo and "|cff00ff00ATTIVA|r" or "|cffff0000DISATTIVA|r"))
        UpdateAllPartyMembers()
    elseif msg == "classic" then
        s.useGridPartyFrames = false
        FP:Print("Stile Party: |cffffaa00CLASSICO BLIZZARD|r")
        UpdateAllPartyMembers()
    elseif msg == "grid" then
        s.useGridPartyFrames = true
        FP:Print("Stile Party: |cff00ff00GRIGLIA (Incursione)|r")
        UpdateAllPartyMembers()
    else
        s.useGridPartyFrames = not (s.useGridPartyFrames ~= false)
        FP:Print("Stile Party alternato a: " .. (s.useGridPartyFrames and "|cff00ff00GRIGLIA (Incursione)|r" or "|cffffaa00CLASSICO BLIZZARD|r"))
        UpdateAllPartyMembers()
    end
end
