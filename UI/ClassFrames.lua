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
    if (issecretvalue and issecretvalue(val)) or (issecret and issecret(val)) then return fallback end
    local ok, res = pcall(function()
        if val then return true else return false end
    end)
    if ok then
        return res
    end
    return fallback
end

local function SafeNumber(val, fallback)
    if val == nil then return fallback end
    if (issecretvalue and issecretvalue(val)) or (issecret and issecret(val)) then return fallback end
    local ok, res = pcall(function()
        if type(val) == "number" and val == val then return val else return fallback end
    end)
    if ok then
        return res
    end
    return fallback
end

local function IsSafeStr(v)
    return type(v) == "string" and not ((issecretvalue and issecretvalue(v)) or (issecret and issecret(v))) and v ~= ""
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = { pcall(fn, ...) }
    if not results[1] then return nil end
    for i = 2, #results do
        if (issecretvalue and issecretvalue(results[i])) or (issecret and issecret(results[i])) then
            results[i] = nil
        end
    end
    return unpack(results, 2)
end

local function SafeUnitExists(unit)
    return unit and UnitExists and SafeBoolean(SafeCall(UnitExists, unit), false) or false
end

local function SafeUnitIsPlayer(unit)
    return unit and UnitIsPlayer and SafeBoolean(SafeCall(UnitIsPlayer, unit), false) or false
end

local function SafeUnitIsUnit(a, b)
    return a and b and UnitIsUnit and SafeBoolean(SafeCall(UnitIsUnit, a, b), false) or false
end

local function SafeUnitName(unit)
    if not unit or not UnitName then return nil end
    local n = SafeCall(UnitName, unit)
    return IsSafeStr(n) and n or nil
end

local function SafeUnitGUID(unit)
    if not unit or not UnitGUID then return nil end
    local g = SafeCall(UnitGUID, unit)
    return IsSafeStr(g) and g or nil
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

local function ReadTalentTabCompat(tab, isInspect)
    if FP.ReadTalentTabCompat then
        return FP.ReadTalentTabCompat(tab, isInspect)
    end
    if type(GetTalentTabInfo) ~= "function" then return nil, 0 end
    local a, b, c, _, e = SafeCall(GetTalentTabInfo, tab, isInspect)
    if type(a) == "number" and IsSafeStr(b) then
        return b, SafeNumber(e, 0)
    elseif IsSafeStr(a) then
        return a, SafeNumber(c, 0)
    end
    return nil, 0
end

local function GetUnitSpecInfo(unit)
    if not SafeUnitExists(unit) or not SafeUnitIsPlayer(unit) then return nil, nil end

    if SafeUnitIsUnit(unit, "player") then
        -- 1. Modern WoW Specialization API (Retail, 1.60.1 / 11.0+, etc.)
        local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
        local getSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
        if type(getSpec) == "function" and type(getSpecInfo) == "function" then
            local specIndex = SafeCall(getSpec)
            if type(specIndex) == "number" and specIndex > 0 then
                local _, name = SafeCall(getSpecInfo, specIndex)
                if IsSafeStr(name) then
                    return name, nil
                end
            end
        end

        -- 2. Classic Talent Tabs API (supports both 3-return and 5-return signatures)
        if type(GetTalentTabInfo) == "function" then
            local maxPoints = -1
            local topName = nil
            local p = {}
            local numTabs = SafeNumber((type(GetNumTalentTabs) == "function") and SafeCall(GetNumTalentTabs) or 3, 3)
            if numTabs < 1 or numTabs > 4 then numTabs = 3 end
            for tab = 1, numTabs do
                local name, points = ReadTalentTabCompat(tab)
                points = points or 0
                p[#p + 1] = points
                if points > maxPoints then
                    maxPoints = points
                    topName = name
                end
            end
            local pts = (#p > 0) and table.concat(p, "/") or nil
            if maxPoints <= 0 then
                return nil, pts
            end
            return topName, pts
        end
    else
        local guid = SafeUnitGUID(unit)
        if guid and cachedPlayerSpecs[guid] then
            return cachedPlayerSpecs[guid].specName, cachedPlayerSpecs[guid].pts
        end
    end
    return nil, nil
end

local function RequestInspectUnit(unit)
    if not SafeUnitExists(unit) or not SafeUnitIsPlayer(unit) then return end
    if SafeUnitIsUnit(unit, "player") then return end
    if not CanInspect or not SafeBoolean(SafeCall(CanInspect, unit, false), false) then return end
    if InCombatLockdown and InCombatLockdown() then return end

    local now = (GetTime and SafeCall(GetTime)) or 0
    if (now - lastInspectTime) < 1.0 then return end

    local guid = SafeUnitGUID(unit)
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
    local actualGuid = IsSafeStr(guid) and guid or lastInspectTargetGUID
    if not IsSafeStr(actualGuid) then return end
    if lastInspectTargetGUID and actualGuid ~= lastInspectTargetGUID then return end
    lastInspectTargetGUID = nil

    local topName = nil
    local pts = nil

    -- 1. Modern WoW Inspect Specialization (Retail, TWW 11.0+)
    if GetInspectSpecialization and GetSpecializationInfoByID then
        local specID = SafeCall(GetInspectSpecialization, currentTooltipUnit or "target")
        if type(specID) == "number" and specID > 0 then
            local _, name = SafeCall(GetSpecializationInfoByID, specID)
            if IsSafeStr(name) then
                topName = name
            end
        end
    end

    -- 2. Classic Talent Tabs Inspect (Classic Era, TBC, WotLK)
    if not topName and type(GetTalentTabInfo) == "function" then
        local numTabs = SafeNumber((type(GetNumTalentTabs) == "function") and SafeCall(GetNumTalentTabs, true) or 3, 3)
        if numTabs < 1 or numTabs > 4 then numTabs = 3 end
        local maxPoints = -1
        local p = {}
        for tab = 1, numTabs do
            local name, points = ReadTalentTabCompat(tab, true)
            points = points or 0
            p[#p + 1] = points
            if points > maxPoints then
                maxPoints = points
                topName = name
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
        pts      = pts,
        time     = (GetTime and SafeCall(GetTime)) or 0,
    }

    if ClearInspectPlayer then
        pcall(ClearInspectPlayer)
    end

    if currentTooltipOwner and currentTooltipUnit and SafeUnitExists(currentTooltipUnit) then
        if SafeUnitGUID(currentTooltipUnit) == actualGuid and GameTooltip:IsShown() then
            ShowPortraitTooltip(currentTooltipOwner, currentTooltipUnit)
        end
    end
end

-------------------------------------------------------------------------------
-- Party Member Dispel & Buff Detection
-------------------------------------------------------------------------------
local function GetPlayerDispelCapabilities()
    if FP.GetPlayerDispelInfo then
        local info = FP:GetPlayerDispelInfo()
        if info and info.schools then
            return info.schools, info.classTag
        end
    end
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
    -- Paladin (combat / external cooldowns & HoTs)
    ["Blessing of Protection"] = true, ["Benedizione della Protezione"] = true,
    ["Hand of Protection"] = true, ["Mano della Protezione"] = true,
    ["Blessing of Freedom"] = true, ["Benedizione della Libertà"] = true,
    ["Hand of Freedom"] = true, ["Mano della Libertà"] = true,
    ["Blessing of Sacrifice"] = true, ["Benedizione del Sacrificio"] = true,
    ["Hand of Sacrifice"] = true, ["Mano del Sacrificio"] = true,
    ["Hand of Salvation"] = true, ["Mano della Salvezza"] = true,
    ["Sacred Shield"] = true, ["Scudo Sacro"] = true,
    ["Beacon of Light"] = true, ["Faro di Luce"] = true,
    ["Holy Shield"] = true, ["Scudo Benedetto"] = true,
    ["Divine Shield"] = true, ["Scudo Divino"] = true,
    ["Divine Protection"] = true, ["Protezione Divina"] = true,
    ["Avenging Wrath"] = true, ["Ira Vendicatrice"] = true,
    -- Priest
    ["Renew"] = true, ["Rinnovamento"] = true,
    ["Power Word: Shield"] = true, ["Parola del Potere: Scudo"] = true,
    ["Fear Ward"] = true, ["Difesa dalla Paura"] = true,
    ["Pain Suppression"] = true, ["Soppressione del Dolore"] = true,
    ["Guardian Spirit"] = true, ["Spirito Guardiano"] = true,
    ["Power Infusion"] = true, ["Infusione di Potere"] = true,
    ["Prayer of Mending"] = true, ["Preghiera di Guarigione"] = true,
    -- Druid
    ["Rejuvenation"] = true, ["Ringiovanimento"] = true,
    ["Regrowth"] = true, ["Ricrescita"] = true,
    ["Lifebloom"] = true, ["Fiore di Vita"] = true,
    ["Wild Growth"] = true, ["Crescita Rigogliosa"] = true,
    ["Innervate"] = true, ["Innervazione"] = true,
    ["Barkskin"] = true, ["Pelledura"] = true,
    -- Shaman
    ["Earth Shield"] = true, ["Scudo di Terra"] = true,
    ["Riptide"] = true, ["Risacca"] = true,
    ["Bloodlust"] = true, ["Brama di Sangue"] = true,
    ["Heroism"] = true, ["Eroismo"] = true,
    -- Warrior
    ["Battle Shout"] = true, ["Urlo di Battaglia"] = true,
    ["Commanding Shout"] = true, ["Urlo di Comando"] = true,
    ["Shield Wall"] = true, ["Muro di Scudi"] = true,
    ["Last Stand"] = true, ["Ultima Difesa"] = true,
    -- Hunter / Rogue / Mage / DK
    ["Misdirection"] = true, ["Depistaggio"] = true,
    ["Tricks of the Trade"] = true, ["Trucchi del Mestiere"] = true,
    ["Time Warp"] = true, ["Distorsione Temporale"] = true,
    ["Ice Barrier"] = true, ["Barriera di Ghiaccio"] = true,
}

-- DBM-style noise filter: never clutter party/raid frames with passive toggles, auras, stances, trackers or food
local IGNORED_PASSIVE_BUFFS = {
    -- Gathering & Hunter tracking toggles
    ["Find Minerals"] = true, ["Trova Minerali"] = true,
    ["Find Herbs"] = true, ["Trova Erbe"] = true,
    ["Find Treasure"] = true, ["Trova Tesori"] = true,
    ["Find Fish"] = true, ["Trova Pesci"] = true,
    ["Track Beasts"] = true, ["Traccia Bestie"] = true,
    ["Track Humanoids"] = true, ["Traccia Umanoidi"] = true,
    ["Track Undead"] = true, ["Traccia Non Morti"] = true,
    ["Track Demons"] = true, ["Traccia Demoni"] = true,
    ["Track Giants"] = true, ["Traccia Giganti"] = true,
    ["Track Dragonkin"] = true, ["Traccia Dragoidi"] = true,
    ["Track Elementals"] = true, ["Traccia Elementali"] = true,
    ["Track Hidden"] = true, ["Traccia Nascosti"] = true,
    ["Sense Undead"] = true, ["Percezione dei Non Morti"] = true,
    ["Sense Demons"] = true, ["Percezione dei Demoni"] = true,
    -- Paladin Auras, Seals & Righteous Fury
    ["Devotion Aura"] = true, ["Aura di Devozione"] = true,
    ["Retribution Aura"] = true, ["Aura di Ritorsione"] = true,
    ["Concentration Aura"] = true, ["Aura di Concentrazione"] = true,
    ["Shadow Resistance Aura"] = true, ["Aura di Resistenza all'Ombra"] = true,
    ["Frost Resistance Aura"] = true, ["Aura di Resistenza al Gelo"] = true,
    ["Fire Resistance Aura"] = true, ["Aura di Resistenza al Fuoco"] = true,
    ["Sanctity Aura"] = true, ["Aura di Santità"] = true,
    ["Crusader Aura"] = true, ["Aura del Crociato"] = true,
    ["Righteous Fury"] = true, ["Furia Giusta"] = true,
    ["Seal of Righteousness"] = true, ["Sigillo di Rettitudine"] = true,
    ["Seal of Command"] = true, ["Sigillo del Comando"] = true,
    ["Seal of Light"] = true, ["Sigillo di Luce"] = true,
    ["Seal of Wisdom"] = true, ["Sigillo di Saggezza"] = true,
    ["Seal of Justice"] = true, ["Sigillo di Giustizia"] = true,
    ["Seal of the Crusader"] = true, ["Sigillo del Crociato"] = true,
    ["Seal of Vengeance"] = true, ["Sigillo della Vendetta"] = true,
    ["Seal of Corruption"] = true, ["Sigillo della Corruzione"] = true,
    ["Seal of Blood"] = true, ["Sigillo del Sangue"] = true,
    ["Seal of the Martyr"] = true, ["Sigillo del Martire"] = true,
    -- Warrior Stances & DK Presences
    ["Battle Stance"] = true, ["Postura da Battaglia"] = true,
    ["Defensive Stance"] = true, ["Postura Difensiva"] = true,
    ["Berserker Stance"] = true, ["Postura Berserker"] = true,
    ["Blood Presence"] = true, ["Presenza del Sangue"] = true,
    ["Frost Presence"] = true, ["Presenza del Gelo"] = true,
    ["Unholy Presence"] = true, ["Presenza Empia"] = true,
    -- Druid Forms & Hunter Aspects
    ["Bear Form"] = true, ["Forma d'Orso"] = true,
    ["Dire Bear Form"] = true, ["Forma d'Orso Feroce"] = true,
    ["Cat Form"] = true, ["Forma Felina"] = true,
    ["Travel Form"] = true, ["Forma di Viaggio"] = true,
    ["Aquatic Form"] = true, ["Forma Acquatica"] = true,
    ["Moonkin Form"] = true, ["Forma di Lunagufo"] = true,
    ["Tree of Life"] = true, ["Albero della Vita"] = true,
    ["Flight Form"] = true, ["Forma di Volo"] = true,
    ["Swift Flight Form"] = true, ["Forma di Volo Rapida"] = true,
    ["Aspect of the Hawk"] = true, ["Aspetto del Falco"] = true,
    ["Aspect of the Dragonhawk"] = true, ["Aspetto del Dragofalco"] = true,
    ["Aspect of the Monkey"] = true, ["Aspetto della Scimmia"] = true,
    ["Aspect of the Cheetah"] = true, ["Aspetto del Ghepardo"] = true,
    ["Aspect of the Pack"] = true, ["Aspetto del Branco"] = true,
    ["Aspect of the Beast"] = true, ["Aspetto della Bestia"] = true,
    ["Aspect of the Wild"] = true, ["Aspetto della Natura"] = true,
    ["Aspect of the Viper"] = true, ["Aspetto della Vipera"] = true,
    ["Trueshot Aura"] = true, ["Aura di Precisione"] = true,
    -- Self armors / forms / shields / long non-combat buffs
    ["Shadowform"] = true, ["Forma d'Ombra"] = true,
    ["Inner Fire"] = true, ["Fuoco Interiore"] = true,
    ["Frost Armor"] = true, ["Armatura del Gelo"] = true,
    ["Ice Armor"] = true, ["Armatura di Ghiaccio"] = true,
    ["Mage Armor"] = true, ["Armatura del Mago"] = true,
    ["Molten Armor"] = true, ["Armatura Fusa"] = true,
    ["Demon Armor"] = true, ["Armatura Demoniaca"] = true,
    ["Demon Skin"] = true, ["Pelle di Demone"] = true,
    ["Fel Armor"] = true, ["Armatura Vile"] = true,
    ["Soul Link"] = true, ["Legame dell'Anima"] = true,
    ["Lightning Shield"] = true, ["Scudo di Fulmini"] = true,
    ["Water Shield"] = true, ["Scudo d'Acqua"] = true,
    ["Ghost Wolf"] = true, ["Lupo Spettrale"] = true,
    ["Stealth"] = true, ["Furtività"] = true,
    ["Prowl"] = true, ["Agguato"] = true,
    ["Shadowmeld"] = true, ["Fondersi nell'Ombra"] = true,
    ["Well Fed"] = true, ["Ben Nutrito"] = true,
    ["Food"] = true, ["Cibo"] = true,
    ["Drink"] = true, ["Bevanda"] = true,
    ["Refreshment"] = true, ["Ristoro"] = true,
    ["Honorless Target"] = true, ["Bersaglio senza Onore"] = true,
    ["Ghost"] = true, ["Fantasma"] = true,
}

local IGNORED_PASSIVE_IDS = {
    [2580] = true,  -- Find Minerals
    [2383] = true,  -- Find Herbs
    [2481] = true,  -- Find Treasure
    [43308] = true, -- Find Fish
    [1494] = true,  -- Track Beasts
    [19878] = true, -- Track Demons
    [19879] = true, -- Track Dragonkin
    [19880] = true, -- Track Elementals
    [19882] = true, -- Track Giants
    [19883] = true, -- Track Humanoids
    [19884] = true, -- Track Undead
    [19885] = true, -- Track Hidden
    [5500] = true,  -- Sense Demons
    [5502] = true,  -- Sense Undead
    [25780] = true, -- Righteous Fury
    [19746] = true, -- Concentration Aura
    [20218] = true, -- Sanctity Aura
    [32223] = true, -- Crusader Aura
}

-- DBM-style priority whitelist:
-- 100 = Major Immunities, Tank/Personal Defensives & Raid Bloodlust/Heroism
--  90 = External Saves, Absorbs & CC/Threat Utility
--  80 = Healer HoTs & Active Tank Mitigations
--  65 = Encounter / Raid Shouts & Major Offensive Cooldowns
local IMPORTANT_COMBAT_BUFFS = {
    -- Tier 1 (100): Immunities, Major Defensives & Heroism/Bloodlust
    ["Divine Shield"] = { prio = 100, cat = "DEFENSIVE" }, ["Scudo Divino"] = { prio = 100, cat = "DEFENSIVE" },
    ["Divine Protection"] = { prio = 100, cat = "DEFENSIVE" }, ["Protezione Divina"] = { prio = 100, cat = "DEFENSIVE" },
    ["Blessing of Protection"] = { prio = 100, cat = "DEFENSIVE" }, ["Benedizione della Protezione"] = { prio = 100, cat = "DEFENSIVE" },
    ["Hand of Protection"] = { prio = 100, cat = "DEFENSIVE" }, ["Mano della Protezione"] = { prio = 100, cat = "DEFENSIVE" },
    ["Shield Wall"] = { prio = 100, cat = "DEFENSIVE" }, ["Muro di Scudi"] = { prio = 100, cat = "DEFENSIVE" },
    ["Last Stand"] = { prio = 100, cat = "DEFENSIVE" }, ["Ultima Difesa"] = { prio = 100, cat = "DEFENSIVE" },
    ["Ice Block"] = { prio = 100, cat = "DEFENSIVE" }, ["Blocco di Ghiaccio"] = { prio = 100, cat = "DEFENSIVE" },
    ["Dispersion"] = { prio = 100, cat = "DEFENSIVE" }, ["Dispersione"] = { prio = 100, cat = "DEFENSIVE" },
    ["Pain Suppression"] = { prio = 100, cat = "DEFENSIVE" }, ["Soppressione del Dolore"] = { prio = 100, cat = "DEFENSIVE" },
    ["Guardian Spirit"] = { prio = 100, cat = "DEFENSIVE" }, ["Spirito Guardiano"] = { prio = 100, cat = "DEFENSIVE" },
    ["Barkskin"] = { prio = 100, cat = "DEFENSIVE" }, ["Pelledura"] = { prio = 100, cat = "DEFENSIVE" },
    ["Survival Instincts"] = { prio = 100, cat = "DEFENSIVE" }, ["Istinto di Sopravvivenza"] = { prio = 100, cat = "DEFENSIVE" },
    ["Anti-Magic Shell"] = { prio = 100, cat = "DEFENSIVE" }, ["Scudo Antimagia"] = { prio = 100, cat = "DEFENSIVE" },
    ["Icebound Fortitude"] = { prio = 100, cat = "DEFENSIVE" }, ["Fermezza Glaciale"] = { prio = 100, cat = "DEFENSIVE" },
    ["Vampiric Blood"] = { prio = 100, cat = "DEFENSIVE" }, ["Sangue Vampirico"] = { prio = 100, cat = "DEFENSIVE" },
    ["Deterrence"] = { prio = 100, cat = "DEFENSIVE" }, ["Deterrenza"] = { prio = 100, cat = "DEFENSIVE" },
    ["Evasion"] = { prio = 100, cat = "DEFENSIVE" }, ["Evasione"] = { prio = 100, cat = "DEFENSIVE" },
    ["Cloak of Shadows"] = { prio = 100, cat = "DEFENSIVE" }, ["Manto d'Ombra"] = { prio = 100, cat = "DEFENSIVE" },
    ["Ardent Defender"] = { prio = 100, cat = "DEFENSIVE" }, ["Difensore Ardente"] = { prio = 100, cat = "DEFENSIVE" },
    ["Bloodlust"] = { prio = 100, cat = "DEFENSIVE" }, ["Brama di Sangue"] = { prio = 100, cat = "DEFENSIVE" },
    ["Heroism"] = { prio = 100, cat = "DEFENSIVE" }, ["Eroismo"] = { prio = 100, cat = "DEFENSIVE" },
    ["Time Warp"] = { prio = 100, cat = "DEFENSIVE" }, ["Distorsione Temporale"] = { prio = 100, cat = "DEFENSIVE" },
    ["Limited Invulnerability Potion"] = { prio = 100, cat = "DEFENSIVE" },
    ["Pozione d'Invulnerabilità Limitata"] = { prio = 100, cat = "DEFENSIVE" },

    -- Tier 2 (90-95): Externals, Absorbs & Saves
    ["Blessing of Sacrifice"] = { prio = 95, cat = "EXTERNAL" }, ["Benedizione del Sacrificio"] = { prio = 95, cat = "EXTERNAL" },
    ["Hand of Sacrifice"] = { prio = 95, cat = "EXTERNAL" }, ["Mano del Sacrificio"] = { prio = 95, cat = "EXTERNAL" },
    ["Blessing of Freedom"] = { prio = 92, cat = "EXTERNAL" }, ["Benedizione della Libertà"] = { prio = 92, cat = "EXTERNAL" },
    ["Hand of Freedom"] = { prio = 92, cat = "EXTERNAL" }, ["Mano della Libertà"] = { prio = 92, cat = "EXTERNAL" },
    ["Hand of Salvation"] = { prio = 90, cat = "EXTERNAL" }, ["Mano della Salvezza"] = { prio = 90, cat = "EXTERNAL" },
    ["Power Word: Shield"] = { prio = 90, cat = "EXTERNAL" }, ["Parola del Potere: Scudo"] = { prio = 90, cat = "EXTERNAL" },
    ["Fear Ward"] = { prio = 90, cat = "EXTERNAL" }, ["Difesa dalla Paura"] = { prio = 90, cat = "EXTERNAL" },
    ["Innervate"] = { prio = 90, cat = "EXTERNAL" }, ["Innervazione"] = { prio = 90, cat = "EXTERNAL" },
    ["Power Infusion"] = { prio = 90, cat = "EXTERNAL" }, ["Infusione di Potere"] = { prio = 90, cat = "EXTERNAL" },
    ["Spell Reflection"] = { prio = 90, cat = "EXTERNAL" }, ["Riflesso dell'Incantesimo"] = { prio = 90, cat = "EXTERNAL" },
    ["Frenzied Regeneration"] = { prio = 90, cat = "EXTERNAL" }, ["Rigenerazione Furiosa"] = { prio = 90, cat = "EXTERNAL" },
    ["Ice Barrier"] = { prio = 90, cat = "EXTERNAL" }, ["Barriera di Ghiaccio"] = { prio = 90, cat = "EXTERNAL" },
    ["Intervene"] = { prio = 90, cat = "EXTERNAL" }, ["Intervento"] = { prio = 90, cat = "EXTERNAL" },
    ["Free Action Potion"] = { prio = 90, cat = "EXTERNAL" }, ["Pozione d'Azione Libera"] = { prio = 90, cat = "EXTERNAL" },

    -- Tier 3 (80): Healer HoTs & Tank Maintenance Buffs
    ["Renew"] = { prio = 80, cat = "HOT" }, ["Rinnovamento"] = { prio = 80, cat = "HOT" },
    ["Prayer of Mending"] = { prio = 82, cat = "HOT" }, ["Preghiera di Guarigione"] = { prio = 82, cat = "HOT" },
    ["Rejuvenation"] = { prio = 80, cat = "HOT" }, ["Ringiovanimento"] = { prio = 80, cat = "HOT" },
    ["Regrowth"] = { prio = 80, cat = "HOT" }, ["Ricrescita"] = { prio = 80, cat = "HOT" },
    ["Lifebloom"] = { prio = 82, cat = "HOT" }, ["Fiore di Vita"] = { prio = 82, cat = "HOT" },
    ["Wild Growth"] = { prio = 82, cat = "HOT" }, ["Crescita Rigogliosa"] = { prio = 82, cat = "HOT" },
    ["Earth Shield"] = { prio = 85, cat = "HOT" }, ["Scudo di Terra"] = { prio = 85, cat = "HOT" },
    ["Riptide"] = { prio = 80, cat = "HOT" }, ["Risacca"] = { prio = 80, cat = "HOT" },
    ["Sacred Shield"] = { prio = 85, cat = "HOT" }, ["Scudo Sacro"] = { prio = 85, cat = "HOT" },
    ["Beacon of Light"] = { prio = 85, cat = "HOT" }, ["Faro di Luce"] = { prio = 85, cat = "HOT" },
    ["Holy Shield"] = { prio = 80, cat = "HOT" }, ["Scudo Benedetto"] = { prio = 80, cat = "HOT" },
    ["Shield Block"] = { prio = 82, cat = "HOT" }, ["Blocco con Scudo"] = { prio = 82, cat = "HOT" },
    ["Inspiration"] = { prio = 78, cat = "HOT" }, ["Ispirazione"] = { prio = 78, cat = "HOT" },
    ["Ancestral Fortitude"] = { prio = 78, cat = "HOT" }, ["Fermezza Ancestrale"] = { prio = 78, cat = "HOT" },
    ["Abolish Poison"] = { prio = 78, cat = "HOT" }, ["Abolizione del Veleno"] = { prio = 78, cat = "HOT" },
    ["Abolish Disease"] = { prio = 78, cat = "HOT" }, ["Abolizione della Malattia"] = { prio = 78, cat = "HOT" },

    -- Tier 4 (65): Shouts, Threat Redirects & Major Active Cooldowns
    ["Battle Shout"] = { prio = 65, cat = "COMBAT" }, ["Urlo di Battaglia"] = { prio = 65, cat = "COMBAT" },
    ["Commanding Shout"] = { prio = 65, cat = "COMBAT" }, ["Urlo di Comando"] = { prio = 65, cat = "COMBAT" },
    ["Misdirection"] = { prio = 72, cat = "COMBAT" }, ["Depistaggio"] = { prio = 72, cat = "COMBAT" },
    ["Tricks of the Trade"] = { prio = 72, cat = "COMBAT" }, ["Trucchi del Mestiere"] = { prio = 72, cat = "COMBAT" },
    ["Avenging Wrath"] = { prio = 70, cat = "COMBAT" }, ["Ira Vendicatrice"] = { prio = 70, cat = "COMBAT" },
    ["Tranquility"] = { prio = 75, cat = "COMBAT" }, ["Tranquillità"] = { prio = 75, cat = "COMBAT" },
    ["Divine Hymn"] = { prio = 75, cat = "COMBAT" }, ["Inno Divino"] = { prio = 75, cat = "COMBAT" },
    ["Hymn of Hope"] = { prio = 75, cat = "COMBAT" }, ["Inno della Speranza"] = { prio = 75, cat = "COMBAT" },
    ["Divine Plea"] = { prio = 65, cat = "COMBAT" }, ["Supplica Divina"] = { prio = 65, cat = "COMBAT" },
    ["Evocation"] = { prio = 65, cat = "COMBAT" }, ["Evocazione"] = { prio = 65, cat = "COMBAT" },
    ["Berserk"] = { prio = 68, cat = "COMBAT" },
    ["Recklessness"] = { prio = 68, cat = "COMBAT" }, ["Temerarietà"] = { prio = 68, cat = "COMBAT" },
    ["Death Wish"] = { prio = 68, cat = "COMBAT" }, ["Desiderio di Morte"] = { prio = 68, cat = "COMBAT" },
    ["Bestial Wrath"] = { prio = 68, cat = "COMBAT" }, ["Ira Bestiale"] = { prio = 68, cat = "COMBAT" },
    ["Rapid Fire"] = { prio = 65, cat = "COMBAT" }, ["Fuoco Rapido"] = { prio = 65, cat = "COMBAT" },
    ["Adrenaline Rush"] = { prio = 68, cat = "COMBAT" }, ["Scarica di Adrenalina"] = { prio = 68, cat = "COMBAT" },
    ["Icy Veins"] = { prio = 65, cat = "COMBAT" }, ["Vene Gelide"] = { prio = 65, cat = "COMBAT" },
    ["Arcane Power"] = { prio = 65, cat = "COMBAT" }, ["Potere Arcano"] = { prio = 65, cat = "COMBAT" },
    ["Stampeding Roar"] = { prio = 72, cat = "COMBAT" }, ["Ruggito Impetuoso"] = { prio = 72, cat = "COMBAT" },
    ["Sprint"] = { prio = 65, cat = "COMBAT" }, ["Scatto"] = { prio = 65, cat = "COMBAT" },
    ["Dash"] = { prio = 65, cat = "COMBAT" }, ["Scatto Felino"] = { prio = 65, cat = "COMBAT" },
}

local IMPORTANT_COMBAT_IDS = {
    [642]   = { prio = 100, cat = "DEFENSIVE" }, -- Divine Shield
    [498]   = { prio = 100, cat = "DEFENSIVE" }, -- Divine Protection
    [1022]  = { prio = 100, cat = "DEFENSIVE" }, -- Blessing/Hand of Protection
    [871]   = { prio = 100, cat = "DEFENSIVE" }, -- Shield Wall
    [12975] = { prio = 100, cat = "DEFENSIVE" }, -- Last Stand
    [45438] = { prio = 100, cat = "DEFENSIVE" }, -- Ice Block
    [47585] = { prio = 100, cat = "DEFENSIVE" }, -- Dispersion
    [33206] = { prio = 100, cat = "DEFENSIVE" }, -- Pain Suppression
    [47788] = { prio = 100, cat = "DEFENSIVE" }, -- Guardian Spirit
    [22812] = { prio = 100, cat = "DEFENSIVE" }, -- Barkskin
    [61336] = { prio = 100, cat = "DEFENSIVE" }, -- Survival Instincts
    [48707] = { prio = 100, cat = "DEFENSIVE" }, -- Anti-Magic Shell
    [48792] = { prio = 100, cat = "DEFENSIVE" }, -- Icebound Fortitude
    [55233] = { prio = 100, cat = "DEFENSIVE" }, -- Vampiric Blood
    [2825]  = { prio = 100, cat = "DEFENSIVE" }, -- Bloodlust
    [32182] = { prio = 100, cat = "DEFENSIVE" }, -- Heroism
    [80353] = { prio = 100, cat = "DEFENSIVE" }, -- Time Warp
    [6940]  = { prio = 95,  cat = "EXTERNAL" },  -- Hand/Blessing of Sacrifice
    [1044]  = { prio = 92,  cat = "EXTERNAL" },  -- Hand/Blessing of Freedom
    [1038]  = { prio = 90,  cat = "EXTERNAL" },  -- Hand of Salvation
    [6346]  = { prio = 90,  cat = "EXTERNAL" },  -- Fear Ward
    [29166] = { prio = 90,  cat = "EXTERNAL" },  -- Innervate
    [10060] = { prio = 90,  cat = "EXTERNAL" },  -- Power Infusion
    [23920] = { prio = 90,  cat = "EXTERNAL" },  -- Spell Reflection
    [20925] = { prio = 80,  cat = "HOT" },       -- Holy Shield
    [53601] = { prio = 85,  cat = "HOT" },       -- Sacred Shield
    [53563] = { prio = 85,  cat = "HOT" },       -- Beacon of Light
    [974]   = { prio = 85,  cat = "HOT" },       -- Earth Shield
    [33763] = { prio = 82,  cat = "HOT" },       -- Lifebloom
    [48438] = { prio = 82,  cat = "HOT" },       -- Wild Growth
    [33076] = { prio = 82,  cat = "HOT" },       -- Prayer of Mending
    [61295] = { prio = 80,  cat = "HOT" },       -- Riptide
    [2565]  = { prio = 82,  cat = "HOT" },       -- Shield Block
    [31884] = { prio = 70,  cat = "COMBAT" },    -- Avenging Wrath
    [34477] = { prio = 72,  cat = "COMBAT" },    -- Misdirection
    [57934] = { prio = 72,  cat = "COMBAT" },    -- Tricks of the Trade
}

local function IsSecretVal(v)
    return v ~= nil and (((issecretvalue and issecretvalue(v)) or (issecret and issecret(v))) == true)
end

local function IsAccessibleVal(v)
    return v ~= nil and not IsSecretVal(v)
end

local function SafeSetAuraTexture(tex, rawIcon, fallbackIcon)
    if not tex then return end
    local okTex = false
    if IsSecretVal(rawIcon) then
        okTex = pcall(tex.SetTexture, tex, rawIcon)
    elseif rawIcon ~= nil then
        okTex = pcall(tex.SetTexture, tex, rawIcon)
    end
    if not okTex then
        tex:SetTexture(fallbackIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

local function ApplyAuraSlotCooldown(cdFrame, auraEntry)
    if not cdFrame then return end
    local dur = (auraEntry and tonumber(auraEntry.duration)) or 0
    local expTime = (auraEntry and tonumber(auraEntry.expirationTime)) or 0
    if dur > 0 and expTime > 0 then
        local startTime = expTime - dur
        if startTime >= 0 then
            local now = (GetTime and GetTime()) or 0
            if expTime > now then
                local okCd = pcall(cdFrame.SetCooldown, cdFrame, startTime, dur)
                if okCd then
                    cdFrame:Show()
                    return
                end
            end
        end
    end
    if auraEntry and auraEntry.durationObj and cdFrame.SetCooldownFromDurationObject then
        local okObj = pcall(cdFrame.SetCooldownFromDurationObject, cdFrame, auraEntry.durationObj)
        if okObj then
            cdFrame:Show()
            return
        end
    end
    pcall(cdFrame.Clear, cdFrame)
    cdFrame:Hide()
end

local function SafeReadDebuffAura(unit, aura)
    local okI, rawInstanceID = pcall(function() return aura.auraInstanceID end)
    if not okI then rawInstanceID = nil end
    local okN, rawName = pcall(function() return aura.name end)
    if not okN then rawName = nil end
    local okIc, rawIcon = pcall(function() return aura.icon end)
    if not okIc then rawIcon = nil end
    local okC, rawApps = pcall(function() return aura.applications end)
    if not okC then rawApps = nil end
    local okD, rawDispel = pcall(function() return aura.dispelName end)
    if not okD then rawDispel = nil end
    local okDu, rawDur = pcall(function() return aura.duration end)
    if not okDu then rawDur = nil end
    local okEx, rawExp = pcall(function() return aura.expirationTime end)
    if not okEx then rawExp = nil end
    local okS, rawSpell = pcall(function() return aura.spellId end)
    if not okS then rawSpell = nil end

    local durObj = nil
    if C_UnitAuras and C_UnitAuras.GetAuraDuration and unit and rawInstanceID ~= nil then
        local okDO, resDO = pcall(C_UnitAuras.GetAuraDuration, unit, rawInstanceID)
        if okDO and resDO ~= nil then
            durObj = resDO
        end
    end

    return {
        rawInstanceID  = rawInstanceID,
        safeInstanceID = IsAccessibleVal(rawInstanceID) and rawInstanceID or nil,
        safeName       = IsSafeStr(rawName) and rawName or "Debuff",
        rawIcon        = rawIcon,
        icon           = IsAccessibleVal(rawIcon) and rawIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
        count          = SafeNumber(rawApps, 0),
        safeType       = IsSafeStr(rawDispel) and rawDispel or nil,
        dispelIsSecret = IsSecretVal(rawDispel) and true or false,
        duration       = SafeNumber(rawDur, 0),
        expirationTime = SafeNumber(rawExp, 0),
        durationObj    = durObj,
        spellId        = SafeNumber(rawSpell, nil),
    }
end

local function GetPartyUnitDebuffs(unit)
    local debuffs = {}
    if not unit then return debuffs end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or SafeBoolean(exists, false) ~= true then return debuffs end
    local dispels, playerClass = GetPlayerDispelCapabilities()
    local fallbackSchool = (dispels and dispels["Magic"]) and "Magic" or (next(dispels or {}) or "Magic")

    -- Collect combat-safe dispellable instance IDs from Midnight native filter first
    local knownDebuffSchools = FP.nkKnownDebuffSchools
    if not knownDebuffSchools then
        knownDebuffSchools = {}
        FP.nkKnownDebuffSchools = knownDebuffSchools
    end
    local filterDispellableIDs = {}
    local filterEntries = {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 16 do
            local okF, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL|RAID_PLAYER_DISPELLABLE")
            if not okF or type(aura) ~= "table" then break end
            local f = SafeReadDebuffAura(unit, aura)
            if not (f.safeInstanceID and filterDispellableIDs[f.safeInstanceID]) then
                local dSchool = nil
                if not f.dispelIsSecret then
                    if f.safeInstanceID then
                        knownDebuffSchools[f.safeInstanceID] = f.safeType or false
                    end
                    if f.safeType and dispels and dispels[f.safeType] then
                        dSchool = f.safeType
                    elseif not f.safeType then
                        FP.nkRaidDispelFilterBroken = true
                    end
                else
                    local cached = f.safeInstanceID and knownDebuffSchools[f.safeInstanceID] or nil
                    if cached and cached ~= false and dispels and dispels[cached] then
                        dSchool = cached
                    elseif cached ~= false and not FP.nkRaidDispelFilterBroken then
                        dSchool = fallbackSchool
                    end
                end
                if dSchool then
                    if f.safeInstanceID then
                        filterDispellableIDs[f.safeInstanceID] = dSchool
                    end
                    filterEntries[#filterEntries + 1] = {
                        index = i,
                        auraFilter = "HARMFUL|RAID_PLAYER_DISPELLABLE",
                        rawInstanceID = f.rawInstanceID,
                        name = f.safeName,
                        icon = f.icon,
                        rawIcon = f.rawIcon,
                        count = f.count,
                        dispelType = dSchool,
                        canDispel = true,
                        duration = f.duration,
                        expirationTime = f.expirationTime,
                        durationObj = f.durationObj,
                        spellId = f.spellId,
                    }
                end
            end
        end
    end

    local anyCanDispelFound = false
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 16 do
            local okC, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not okC or type(aura) ~= "table" then break end
            local f = SafeReadDebuffAura(unit, aura)
            if not f.dispelIsSecret and f.safeInstanceID then
                knownDebuffSchools[f.safeInstanceID] = f.safeType or false
            end
            local cached = f.safeInstanceID and knownDebuffSchools[f.safeInstanceID] or nil
            local safeType = f.safeType or (cached and cached ~= false and cached or nil)
            local canDispel = (safeType ~= nil and dispels and dispels[safeType] == true) or false
            if not canDispel and f.dispelIsSecret and f.safeInstanceID and filterDispellableIDs[f.safeInstanceID] then
                canDispel = true
                safeType = safeType or filterDispellableIDs[f.safeInstanceID]
            elseif not canDispel and f.dispelIsSecret and cached ~= false and not FP.nkRaidDispelFilterBroken and f.rawInstanceID ~= nil and C_UnitAuras.IsAuraFilteredOutByInstanceID then
                local okFo, fo = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, f.rawInstanceID, "HARMFUL|RAID_PLAYER_DISPELLABLE")
                if okFo and not IsSecretVal(fo) and fo == false then
                    canDispel = true
                    safeType = safeType or fallbackSchool
                end
            end
            if canDispel then anyCanDispelFound = true end
            debuffs[#debuffs + 1] = {
                index = i,
                auraFilter = "HARMFUL",
                rawInstanceID = f.rawInstanceID,
                name = f.safeName,
                icon = f.icon,
                rawIcon = f.rawIcon,
                count = f.count,
                dispelType = safeType or "none",
                canDispel = canDispel,
                duration = f.duration,
                expirationTime = f.expirationTime,
                durationObj = f.durationObj,
                spellId = f.spellId,
            }
        end
    elseif UnitDebuff then
        for i = 1, 16 do
            local okD, dName, dIcon, dCount, dDispel, dDur, dExp, _, _, _, dSpellId = pcall(UnitDebuff, unit, i)
            if not okD or not dName then break end
            local safeType = IsSafeStr(dDispel) and dDispel or nil
            local canDispel = (safeType ~= nil and dispels and dispels[safeType] == true) or false
            if canDispel then anyCanDispelFound = true end
            debuffs[#debuffs + 1] = {
                index = i,
                name = IsSafeStr(dName) and dName or "Debuff",
                icon = IsAccessibleVal(dIcon) and dIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                rawIcon = dIcon,
                count = SafeNumber(dCount, 0),
                dispelType = safeType or "none",
                canDispel = canDispel,
                duration = SafeNumber(dDur, 0),
                expirationTime = SafeNumber(dExp, 0),
                spellId = SafeNumber(dSpellId, nil),
            }
        end
    end

    if not anyCanDispelFound and #filterEntries > 0 then
        for idx = #filterEntries, 1, -1 do
            table.insert(debuffs, 1, filterEntries[idx])
        end
    end

    -- Sort debuffs: dispellable debuffs FIRST
    pcall(function()
        table.sort(debuffs, function(a, b)
            local aDisp = SafeBoolean(a.canDispel, false)
            local bDisp = SafeBoolean(b.canDispel, false)
            if aDisp and not bDisp then return true end
            if not aDisp and bDisp then return false end
            return (a.index or 0) < (b.index or 0)
        end)
    end)

    return debuffs
end

local function SafeReadBuffAura(aura, unit)
    local okN, rawName = pcall(function() return aura.name end)
    if not okN then rawName = nil end
    local okIc, rawIcon = pcall(function() return aura.icon end)
    if not okIc then rawIcon = nil end
    local okC, rawApps = pcall(function() return aura.applications end)
    if not okC then rawApps = nil end
    local okDu, rawDur = pcall(function() return aura.duration end)
    if not okDu then rawDur = nil end
    local okEx, rawExp = pcall(function() return aura.expirationTime end)
    if not okEx then rawExp = nil end
    local okSr, rawSrc = pcall(function() return aura.sourceUnit end)
    if not okSr then rawSrc = nil end
    local okS, rawSpell = pcall(function() return aura.spellId end)
    if not okS then rawSpell = nil end
    local okPlr, isPlrAura = pcall(function() return aura.isFromPlayerOrPlayerPet end)
    if not okPlr then isPlrAura = nil end
    local okInst, rawInstId = pcall(function() return aura.auraInstanceID end)
    if not okInst then rawInstId = nil end

    local durObj = nil
    if C_UnitAuras and C_UnitAuras.GetAuraDuration and unit and rawInstId ~= nil then
        local okDO, resDO = pcall(C_UnitAuras.GetAuraDuration, unit, rawInstId)
        if okDO and resDO ~= nil then
            durObj = resDO
        end
    end

    local safeName = IsSafeStr(rawName) and rawName or nil
    local safeSrc = IsSafeStr(rawSrc) and rawSrc or nil
    local isPlayerBuff = false
    if IsAccessibleVal(isPlrAura) and isPlrAura == true then
        isPlayerBuff = true
    elseif safeSrc == "player" or (safeSrc == nil and safeName and PLAYER_BUFF_SPELLS and PLAYER_BUFF_SPELLS[safeName]) then
        isPlayerBuff = true
    end

    return {
        readableName   = safeName,
        safeName       = safeName or "Buff",
        rawIcon        = rawIcon,
        icon           = IsAccessibleVal(rawIcon) and rawIcon or nil,
        count          = SafeNumber(rawApps, 0),
        duration       = SafeNumber(rawDur, 0),
        expirationTime = SafeNumber(rawExp, 0),
        durationObj    = durObj,
        source         = safeSrc,
        isPlayerBuff   = isPlayerBuff,
        spellId        = SafeNumber(rawSpell, nil),
        rawInstanceID  = rawInstId,
    }
end

-- Remembers pre-combat aura classifications by auraInstanceID so Secret Values in combat
-- neither resurrect passive clutter (e.g. Auras / Find Minerals) nor drop active combat buffs.
local knownAuraMetaByUnit = {}

local function ClassifyDBMBuff(unit, f, filterPrio, filterCat)
    local rName = f.readableName
    local sid = f.spellId
    local instKey = IsAccessibleVal(f.rawInstanceID) and f.rawInstanceID or nil
    local unitMeta = unit and knownAuraMetaByUnit[unit]
    if not unitMeta and unit then
        unitMeta = {}
        knownAuraMetaByUnit[unit] = unitMeta
    end

    if rName ~= nil then
        -- Always discard passive trackers, auras, stances, forms & food unless flagged as a major defensive external
        if (filterPrio or 0) < 95 then
            if IGNORED_PASSIVE_BUFFS[rName] or (sid and IGNORED_PASSIVE_IDS[sid]) then
                if unitMeta and instKey then unitMeta[instKey] = { ignored = true } end
                return nil, nil
            end
        end

        local match = IMPORTANT_COMBAT_BUFFS[rName] or (sid and IMPORTANT_COMBAT_IDS[sid])
        if match then
            local prio = math.max(filterPrio or 0, match.prio)
            local cat = (filterPrio and filterPrio >= 95 and filterCat) or match.cat
            if unitMeta and instKey then unitMeta[instKey] = { prio = prio, cat = cat } end
            return prio, cat
        end

        local dur = f.duration or 0
        if dur > 0 and dur <= 125 then
            local prio = math.max(filterPrio or 0, 60)
            local cat = filterCat or "COMBAT"
            if unitMeta and instKey then unitMeta[instKey] = { prio = prio, cat = cat } end
            return prio, cat
        end
        if (filterPrio or 0) >= 95 then
            local cat = filterCat or "DEFENSIVE"
            if unitMeta and instKey then unitMeta[instKey] = { prio = filterPrio, cat = cat } end
            return filterPrio, cat
        end
        if unitMeta and instKey then unitMeta[instKey] = { ignored = true } end
        return nil, nil
    end

    -- In combat (Midnight Secret Values): respect pre-combat knowledge first
    local cached = unitMeta and instKey and unitMeta[instKey]
    if cached then
        if cached.ignored and (filterPrio or 0) < 95 then
            return nil, nil
        end
        if cached.prio then
            return math.max(filterPrio or 0, cached.prio), cached.cat or filterCat or "COMBAT"
        end
    end

    -- Fallback if duration is still numeric while name is masked
    local dur = f.duration or 0
    if dur > 0 and dur <= 125 then
        return math.max(filterPrio or 0, 60), filterCat or "COMBAT"
    end

    -- Trust Blizzard's Midnight C-side combat/defensive aura filters
    if (filterPrio or 0) >= 75 then
        return filterPrio, filterCat or "COMBAT"
    end

    if C_UnitAuras and C_UnitAuras.IsAuraFilteredOutByInstanceID and f.rawInstanceID ~= nil then
        local okF1, outBig = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, f.rawInstanceID, "HELPFUL|BIG_DEFENSIVE")
        if okF1 and IsAccessibleVal(outBig) and outBig == false then
            return 100, "DEFENSIVE"
        end
        local okF2, outExt = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, f.rawInstanceID, "HELPFUL|EXTERNAL_DEFENSIVE")
        if okF2 and IsAccessibleVal(outExt) and outExt == false then
            return 95, "EXTERNAL"
        end
        local okF3, outImp = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, f.rawInstanceID, "HELPFUL|IMPORTANT")
        if okF3 and IsAccessibleVal(outImp) and outImp == false then
            return 80, "COMBAT"
        end
        local okF4, outRaid = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, f.rawInstanceID, "HELPFUL|RAID_IN_COMBAT")
        if okF4 and IsAccessibleVal(outRaid) and outRaid == false then
            return 75, "COMBAT"
        end
    end

    return nil, nil
end

local function GetPartyUnitBuffs(unit)
    local buffs = {}
    if not unit then return buffs end
    local okE, exists = pcall(UnitExists, unit)
    if not okE or SafeBoolean(exists, false) ~= true then return buffs end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local seenInst = {}
        local seenByKey = {}
        local function CollectFiltered(auraFilter, filterPrio, filterCat)
            for i = 1, 32 do
                local okC, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, auraFilter)
                if not okC or type(aura) ~= "table" then break end
                local f = SafeReadBuffAura(aura, unit)
                if IsSecretVal(f.rawIcon) or f.rawIcon ~= nil or f.icon ~= nil then
                    local instKey = IsAccessibleVal(f.rawInstanceID) and f.rawInstanceID or nil
                    local nameKey = (not instKey and f.readableName) and f.readableName or nil
                    if (instKey and seenInst[instKey]) or (nameKey and seenByKey[nameKey]) then
                        -- Already collected in a higher-priority Midnight filter pass
                    else
                        local prio, cat = ClassifyDBMBuff(unit, f, filterPrio, filterCat)
                        if prio then
                            if instKey then seenInst[instKey] = true end
                            if nameKey then seenByKey[nameKey] = true end
                            buffs[#buffs + 1] = {
                                index = i,
                                auraFilter = auraFilter,
                                rawInstanceID = f.rawInstanceID,
                                name = f.safeName,
                                readableName = f.readableName,
                                icon = f.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                                rawIcon = f.rawIcon,
                                count = f.count,
                                duration = f.duration,
                                expirationTime = f.expirationTime,
                                durationObj = f.durationObj,
                                source = f.source,
                                isPlayerBuff = f.isPlayerBuff,
                                spellId = f.spellId,
                                priority = prio,
                                dbmCat = cat,
                            }
                        end
                    end
                end
            end
        end

        CollectFiltered("HELPFUL|BIG_DEFENSIVE", 100, "DEFENSIVE")
        CollectFiltered("HELPFUL|EXTERNAL_DEFENSIVE", 95, "EXTERNAL")
        CollectFiltered("HELPFUL|IMPORTANT", 80, "COMBAT")
        CollectFiltered("HELPFUL|RAID_IN_COMBAT", 75, "COMBAT")
        CollectFiltered("HELPFUL|PLAYER|RAID_IN_COMBAT", 75, "HOT")
        CollectFiltered("HELPFUL", 0, nil)
    elseif UnitBuff then
        for i = 1, 32 do
            local okB, bName, bIcon, bCount, _, bDur, bExp, bSrc, _, _, bSpellId = pcall(UnitBuff, unit, i)
            if not okB or not bName then break end
            local safeName = IsSafeStr(bName) and bName or nil
            local safeSrc = IsSafeStr(bSrc) and bSrc or nil
            local isPlayerBuff = (safeSrc == "player") or (safeSrc == nil and safeName and PLAYER_BUFF_SPELLS and PLAYER_BUFF_SPELLS[safeName]) or false
            if IsAccessibleVal(bIcon) or bIcon ~= nil then
                buffs[#buffs + 1] = {
                    index = i,
                    name = safeName or "Buff",
                    icon = IsAccessibleVal(bIcon) and bIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    rawIcon = bIcon,
                    count = SafeNumber(bCount, 0),
                    duration = SafeNumber(bDur, 0),
                    expirationTime = SafeNumber(bExp, 0),
                    source = safeSrc,
                    isPlayerBuff = isPlayerBuff,
                    spellId = SafeNumber(bSpellId, nil),
                }
            end
        end
    end

    -- Legacy UnitBuff fallback: run the same DBM importance filter
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) and #buffs > 0 then
        local filtered = {}
        for _, entry in ipairs(buffs) do
            entry.readableName = (entry.name ~= "Buff") and entry.name or nil
            local prio, cat = ClassifyDBMBuff(unit, entry, 0, nil)
            if prio then
                entry.priority = prio
                entry.dbmCat = cat
                filtered[#filtered + 1] = entry
            end
        end
        buffs = filtered
    end

    -- Sort buffs by DBM importance tier first, then player's own buffs, then aura index
    pcall(function()
        table.sort(buffs, function(a, b)
            local ap = a.priority or 0
            local bp = b.priority or 0
            if ap ~= bp then return ap > bp end
            local aMine = SafeBoolean(a.isPlayerBuff, false)
            local bMine = SafeBoolean(b.isPlayerBuff, false)
            if aMine and not bMine then return true end
            if not aMine and bMine then return false end
            return (a.index or 0) < (b.index or 0)
        end)
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
            local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
            btn:SetSize(16, 16)
            btn:SetPoint("TOPLEFT", container, "TOPLEFT", (b - 1) * 19, -21)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            btn:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
            btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", 1, -1)
            icon:SetPoint("BOTTOMRIGHT", -1, 1)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            local countFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.countFs = countFs

            btn:SetScript("OnEnter", function(self)
                if not self.unit or not self.auraIndex then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(GameTooltip.SetUnitBuff, GameTooltip, self.unit, self.auraIndex)
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
            SafeSetAuraTexture(btn.icon, debuff.rawIcon, debuff.icon)
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
            SafeSetAuraTexture(btn.icon, buff.rawIcon, buff.icon)
            if btn.SetBackdropBorderColor then
                if buff.isPlayerBuff then
                    btn:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.95)
                else
                    btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
                end
            elseif btn.border then
                btn.border:Hide()
            end
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

    -- 1. Normal Portrait (Keep 2D/3D character face, update online status)
    local portrait = frame.portrait or (frameName and _G[frameName .. "Portrait"])
    if portrait then
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
            local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
            btn:SetSize(14, 14)
            btn:SetPoint("LEFT", container, "LEFT", (s - 1) * 16, 0)
            btn:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", 1, -1)
            icon:SetPoint("BOTTOMRIGHT", -1, 1)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            local countFs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countFs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
            btn.countFs = countFs

            btn:SetScript("OnEnter", function(self)
                if not self.unit or not self.auraIndex then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.isDebuff then
                    pcall(GameTooltip.SetUnitDebuff, GameTooltip, self.unit, self.auraIndex)
                else
                    pcall(GameTooltip.SetUnitBuff, GameTooltip, self.unit, self.auraIndex)
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
            SafeSetAuraTexture(btn.icon, debuff.rawIcon, debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            if btn.SetBackdropBorderColor then
                btn:SetBackdropBorderColor(col.r, col.g, col.b, 1)
            elseif btn.border then
                btn.border:SetVertexColor(col.r, col.g, col.b, 1)
                btn.border:Show()
            end
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
            SafeSetAuraTexture(btn.icon, buff.rawIcon, buff.icon)
            if btn.SetBackdropBorderColor then
                if buff.isPlayerBuff then
                    btn:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.95)
                else
                    btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
                end
            elseif btn.border then
                btn.border:Hide()
            end
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

        -- 4. Compact frames have native Blizzard auras; custom aura injection is omitted on compact frames to prevent taint
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
gridContainer:EnableMouse(false)
gridContainer:SetPoint("LEFT", UIParent, "LEFT", 30, 40)
gridContainer:Hide()

-- Unprotected mover overlay (parented to UIParent with ZERO SecureUnitButtonTemplate children)
-- so dragging NEVER calls StartMoving/StopMovingOrSizing on NexusKitPartyGrid itself.
local gridMover = CreateFrame("Frame", "NKPartyGridMover", UIParent, "BackdropTemplate")
gridMover:SetSize(114, 44)
gridMover:SetPoint("TOPLEFT", gridContainer, "TOPLEFT", 0, 0)
gridMover:SetFrameStrata("DIALOG")
gridMover:SetFrameLevel(40)
gridMover:SetClampedToScreen(true)
gridMover:SetMovable(true)
gridMover:EnableMouse(true)
gridMover:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1.5,
})
gridMover:SetBackdropColor(0.0, 0.85, 0.55, 0.14)
gridMover:SetBackdropBorderColor(0.0, 0.90, 0.58, 0.92)
gridMover:Hide()

local function SyncGridMoverToContainer()
    if InCombatLockdown and InCombatLockdown() then return end
    if gridMover.nkDragging then return end
    gridMover:ClearAllPoints()
    gridMover:SetSize(gridContainer:GetWidth() or 114, gridContainer:GetHeight() or 44)
    gridMover:SetScale(gridContainer:GetScale() or 1.0)
    gridMover:SetPoint("TOPLEFT", gridContainer, "TOPLEFT", 0, 0)
end

local function CommitGridMoverPosition()
    if gridMover.nkDragging then
        gridMover:SetScript("OnUpdate", nil)
        gridMover.nkDragging = false
        pcall(gridMover.StopMovingOrSizing, gridMover)
    end
    if InCombatLockdown and InCombatLockdown() then return end
    local left, top = gridMover:GetLeft(), gridMover:GetTop()
    if left and top then
        local s = GetSettings()
        s.gridPartyPos = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
        gridContainer.posLoaded = true
        gridContainer:ClearAllPoints()
        gridContainer:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        SyncGridMoverToContainer()
    end
end

gridMover:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local startL, startT = self:GetLeft(), self:GetTop()
    if startL and startT then
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", startL, startT)
    end
    self.nkDragging = true
    self:StartMoving()
    self:SetScript("OnUpdate", function(mv)
        if InCombatLockdown and InCombatLockdown() then
            mv:SetScript("OnUpdate", nil)
            mv.nkDragging = false
            pcall(mv.StopMovingOrSizing, mv)
            mv:Hide()
            return
        end
        local l, t = mv:GetLeft(), mv:GetTop()
        if l and t then
            gridContainer:ClearAllPoints()
            gridContainer:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
        end
    end)
end)
gridMover:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        CommitGridMoverPosition()
    end
end)
gridMover:SetScript("OnHide", function(self)
    if self.nkDragging then
        self:SetScript("OnUpdate", nil)
        self.nkDragging = false
        pcall(self.StopMovingOrSizing, self)
    end
end)

-- Pure C++ 4-edge texture overlay so Blizzard's ColorCurve secret RGBA values can tint borders
-- via Texture:SetVertexColor() without running Backdrop.lua Lua comparisons.
local function CreateEdgeBorderOverlay(parent, thickness, outset, frameLevel)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", -outset, outset)
    holder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", outset, -outset)
    holder:SetFrameLevel(frameLevel)
    local t = holder:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    t:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    t:SetHeight(thickness)
    local b = holder:CreateTexture(nil, "OVERLAY")
    b:SetTexture("Interface\\Buttons\\WHITE8x8")
    b:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    b:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    b:SetHeight(thickness)
    local l = holder:CreateTexture(nil, "OVERLAY")
    l:SetTexture("Interface\\Buttons\\WHITE8x8")
    l:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    l:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
    l:SetWidth(thickness)
    local r = holder:CreateTexture(nil, "OVERLAY")
    r:SetTexture("Interface\\Buttons\\WHITE8x8")
    r:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    r:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    r:SetWidth(thickness)
    holder.edges = { t, b, l, r }
    holder:Hide()
    return holder
end

local function ApplySecretBorderColor(overlay, colorObj)
    if not overlay then return end
    if colorObj and colorObj.GetRGBA then
        for _, edge in ipairs(overlay.edges) do
            pcall(edge.SetVertexColor, edge, colorObj:GetRGBA())
        end
        overlay:Show()
    else
        overlay:Hide()
    end
end

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
    -- Note: Never call CheckInteractDistance(unit, 4) automatically on unit frames:
    -- in WoW 12.0 / Midnight it is a protected/restricted API that triggers ADDON_ACTION_BLOCKED.
    if UnitInRange then
        local okR, inRange, checked = pcall(UnitInRange, unit)
        if okR then
            local isChecked = SafeBoolean(checked, nil)
            if isChecked == true then
                return SafeBoolean(inRange, true)
            elseif isChecked == nil then
                -- Classic / Midnight fallback if 2nd return value is omitted or secret
                return SafeBoolean(inRange, true)
            end
        end
    end
    return true
end

local function ConfigureGridDispelBinding(btn)
    if not btn or (InCombatLockdown and InCombatLockdown()) then return end
    local dispelInfo = FP.GetPlayerDispelInfo and FP:GetPlayerDispelInfo()
    local pickedSpell = nil
    if dispelInfo and dispelInfo.spellsBySchool then
        pickedSpell = dispelInfo.spellsBySchool["Magic"]
        if not pickedSpell then
            local _, firstSpell = next(dispelInfo.spellsBySchool)
            pickedSpell = firstSpell
        end
    end
    if pickedSpell and pickedSpell.name then
        pcall(btn.SetAttribute, btn, "shift-type1", "spell")
        pcall(btn.SetAttribute, btn, "shift-spell1", pickedSpell.name)
    else
        pcall(btn.SetAttribute, btn, "shift-type1", nil)
        pcall(btn.SetAttribute, btn, "shift-spell1", nil)
    end
end

local function RefreshAllGridDispelBindings()
    if InCombatLockdown and InCombatLockdown() then return end
    for i = 1, 5 do
        if gridMembers[i] then
            ConfigureGridDispelBinding(gridMembers[i])
        end
    end
end

for i = 1, 5 do
    local unit = GRID_UNITS[i]
    local btn = CreateFrame("Button", "NKPartyGridMember" .. i, gridContainer, "SecureUnitButtonTemplate")
    btn:SetSize(114, 44)
    btn:SetAttribute("type1", "target")
    btn:SetAttribute("unit", unit)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn.unit = unit
    ConfigureGridDispelBinding(btn)

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

    -- Dispellable Debuff Glow Border (Bright school color around grid member)
    local dispelBorder = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    dispelBorder:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
    dispelBorder:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    dispelBorder:SetFrameLevel(btn:GetFrameLevel() + 6)
    dispelBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2.5,
    })
    dispelBorder:SetBackdropBorderColor(0.20, 0.65, 1.00, 1.00)
    dispelBorder:Hide()
    btn.dispelBorder = dispelBorder

    btn.secretDispelLayers = {}
    for dl = 1, 4 do
        btn.secretDispelLayers[dl] = CreateEdgeBorderOverlay(btn, 2.5, 2, btn:GetFrameLevel() + 7 + dl)
    end

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

    -- Character Level Text (Bottom-left above power bar, clear of name/buffs/debuffs)
    local levelText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("BOTTOMLEFT", hpBar, "BOTTOMLEFT", 3, 2)
    local lFont = levelText:GetFont()
    if lFont then levelText:SetFont(lFont, 9, "OUTLINE") end
    levelText:SetShadowOffset(1, -1)
    levelText:SetJustifyH("LEFT")
    btn.levelText = levelText

    -- Health Deficit / Status Text
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -4, -3)
    hpText:SetShadowOffset(1, -1)
    hpText:SetJustifyH("RIGHT")
    btn.hpText = hpText

    -- HoT / Buff Icons (3 slots in the center row; crisp 1px BackdropTemplate border, no black overlay)
    btn.buffSlots = {}
    for b = 1, 3 do
        local bBtn = CreateFrame("Button", nil, hpBar, "BackdropTemplate")
        bBtn:SetSize(16, 16)
        bBtn:SetPoint("CENTER", hpBar, "CENTER", (b - 2) * 18, -3)
        bBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        bBtn:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
        bBtn:SetBackdropBorderColor(0.45, 0.45, 0.50, 0.8)

        local icon = bBtn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", bBtn, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", bBtn, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        bBtn.icon = icon

        local cd = CreateFrame("Cooldown", nil, bBtn, "CooldownFrameTemplate")
        cd:SetPoint("TOPLEFT", bBtn, "TOPLEFT", 1, -1)
        cd:SetPoint("BOTTOMRIGHT", bBtn, "BOTTOMRIGHT", -1, 1)
        if cd.SetReverse then cd:SetReverse(true) end
        if cd.SetDrawEdge then cd:SetDrawEdge(true) end
        if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0.48) end
        if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
        cd:Hide()
        bBtn.cd = cd

        local overlay = CreateFrame("Frame", nil, bBtn)
        overlay:SetAllPoints(bBtn)
        overlay:SetFrameLevel(cd:GetFrameLevel() + 5)

        local countFs = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countFs:SetPoint("BOTTOMRIGHT", bBtn, "BOTTOMRIGHT", 2, -1)
        bBtn.countFs = countFs

        bBtn:SetScript("OnEnter", function(self)
            if not self.unit then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = false
            if self.rawInstanceID ~= nil and GameTooltip.SetUnitBuffByAuraInstanceID then
                ok = pcall(GameTooltip.SetUnitBuffByAuraInstanceID, GameTooltip, self.unit, self.rawInstanceID)
            end
            if not ok and self.auraIndex then
                pcall(GameTooltip.SetUnitBuff, GameTooltip, self.unit, self.auraIndex, self.auraFilter)
            end
            GameTooltip:Show()
        end)
        bBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        if bBtn.SetPropagateMouseClicks then pcall(bBtn.SetPropagateMouseClicks, bBtn, true) end
        bBtn:Hide()

        btn.buffSlots[b] = bBtn
    end

    -- Debuff Icons (2 slots in top right)
    btn.debuffSlots = {}
    for d = 1, 2 do
        local dBtn = CreateFrame("Button", nil, hpBar, "BackdropTemplate")
        dBtn:SetSize(16, 16)
        dBtn:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", -((d - 1) * 18 + 2), -2)
        dBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        dBtn:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
        dBtn:SetBackdropBorderColor(0.85, 0.2, 0.2, 1.0)

        local icon = dBtn:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", dBtn, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        dBtn.icon = icon

        local cd = CreateFrame("Cooldown", nil, dBtn, "CooldownFrameTemplate")
        cd:SetPoint("TOPLEFT", dBtn, "TOPLEFT", 1, -1)
        cd:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", -1, 1)
        if cd.SetReverse then cd:SetReverse(true) end
        if cd.SetDrawEdge then cd:SetDrawEdge(true) end
        if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0.48) end
        if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
        cd:Hide()
        dBtn.cd = cd

        local overlay = CreateFrame("Frame", nil, dBtn)
        overlay:SetAllPoints(dBtn)
        overlay:SetFrameLevel(cd:GetFrameLevel() + 5)

        local countFs = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countFs:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", 2, -1)
        dBtn.countFs = countFs
        dBtn.secretOverlay = CreateEdgeBorderOverlay(dBtn, 1.5, 0, overlay:GetFrameLevel() + 2)

        dBtn:SetScript("OnEnter", function(self)
            if not self.unit then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = false
            if self.rawInstanceID ~= nil and GameTooltip.SetUnitDebuffByAuraInstanceID then
                ok = pcall(GameTooltip.SetUnitDebuffByAuraInstanceID, GameTooltip, self.unit, self.rawInstanceID)
            end
            if not ok and self.auraIndex then
                pcall(GameTooltip.SetUnitDebuff, GameTooltip, self.unit, self.auraIndex, self.auraFilter)
            end
            GameTooltip:Show()
        end)
        dBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        if dBtn.SetPropagateMouseClicks then pcall(dBtn.SetPropagateMouseClicks, dBtn, true) end
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

local pendingCombatGridSync = false

local function UpdateGridMember(btn)
    if not btn then return end
    local unit = btn.unit
    local exists = SafeUnitExists(unit)
    local inCombat = InCombatLockdown and InCombatLockdown()
    if not exists then
        if not inCombat then
            btn:Hide()
        else
            pendingCombatGridSync = true
        end
        return
    end

    if not inCombat then
        btn:Show()
    elseif not btn:IsShown() then
        pendingCombatGridSync = true
        return
    end

    local color, class = GetUnitClassColor(unit)
    color = color or { r = 0.6, g = 0.6, b = 0.6 }

    local name = SafeUnitName(unit) or unit
    if type(name) == "string" and #name > 11 then
        name = string.sub(name, 1, 9) .. ".."
    end
    btn.nameText:SetText(tostring(name or unit))

    if btn.levelText then
        local lvl = UnitLevel and SafeNumber(SafeCall(UnitLevel, unit), 0) or 0
        if lvl > 0 then
            btn.levelText:SetText(string.format("|cffffd100%d|r", lvl))
            btn.levelText:Show()
        elseif lvl == -1 then
            btn.levelText:SetText("|cffff4040??|r")
            btn.levelText:Show()
        else
            btn.levelText:SetText("")
            btn.levelText:Hide()
        end
    end

    local hp = 0
    if UnitHealth then
        local ok, v = pcall(UnitHealth, unit)
        if ok and v then hp = v end
    end
    local maxHp = 1
    if UnitHealthMax then
        local ok, v = pcall(UnitHealthMax, unit)
        if ok and v then maxHp = v end
    end

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

    local power = 0
    if UnitPower then
        local ok, v = pcall(UnitPower, unit)
        if ok and v then power = v end
    end
    local maxPower = 1
    if UnitPowerMax then
        local ok, v = pcall(UnitPowerMax, unit)
        if ok and v then maxPower = v end
    end
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

    local powerType = 0
    if UnitPowerType then
        local ok, pt = pcall(UnitPowerType, unit)
        if ok then powerType = SafeNumber(pt, 0) end
    end
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
            local okNum, isNum = pcall(function() return type(tVal) == "number" and tVal >= 0 end)
            if okNum and isNum then
                threat = tVal
            end
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

    -- Auras (DBM-filtered Major Combat Buffs, Externals, Defensives & HoTs)
    local buffs = GetPartyUnitBuffs(unit)
    for b = 1, 3 do
        local bBtn = btn.buffSlots[b]
        if b <= #buffs then
            local buff = buffs[b]
            bBtn.unit = unit
            bBtn.auraIndex = buff.index
            bBtn.auraFilter = buff.auraFilter
            bBtn.rawInstanceID = buff.rawInstanceID
            SafeSetAuraTexture(bBtn.icon, buff.rawIcon, buff.icon)
            local prio = buff.priority or 0
            if prio >= 95 then
                -- Major Defensive / Immunity / External save (Bright Cyan DBM highlight)
                bBtn:SetBackdropBorderColor(0.15, 0.88, 1.0, 1.0)
            elseif buff.isPlayerBuff then
                -- Player's own HoT / External / CD (Gold)
                bBtn:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.95)
            elseif prio >= 78 then
                -- Healer HoT / Shield / Active Mitigation (Emerald)
                bBtn:SetBackdropBorderColor(0.25, 0.92, 0.45, 0.95)
            else
                -- Other active combat buff (Silver-Blue)
                bBtn:SetBackdropBorderColor(0.65, 0.78, 0.95, 0.85)
            end
            ApplyAuraSlotCooldown(bBtn.cd, buff)
            local bCount = SafeNumber(buff.count, 0)
            if bCount > 1 then
                bBtn.countFs:SetText(tostring(bCount))
                bBtn.countFs:Show()
            else
                bBtn.countFs:Hide()
            end
            bBtn:Show()
        else
            bBtn.unit = nil
            bBtn.auraIndex = nil
            bBtn.auraFilter = nil
            bBtn.rawInstanceID = nil
            if bBtn.cd then pcall(bBtn.cd.Clear, bBtn.cd); bBtn.cd:Hide() end
            bBtn:Hide()
        end
    end

    -- Debuffs (Top right) & Grid Dispel Glow
    local debuffs = GetPartyUnitDebuffs(unit)
    local firstDispellable = nil
    for d = 1, #debuffs do
        if debuffs[d].canDispel then
            firstDispellable = debuffs[d]
            break
        end
    end
    if btn.dispelBorder then
        if firstDispellable then
            local dCol = DISPEL_COLORS[firstDispellable.dispelType] or DISPEL_COLORS["Magic"]
            btn.dispelBorder:SetBackdropBorderColor(dCol.r, dCol.g, dCol.b, 1.0)
            btn.dispelBorder:Show()
        else
            btn.dispelBorder:Hide()
        end
        if btn.secretDispelLayers then
            for dl = 1, #btn.secretDispelLayers do btn.secretDispelLayers[dl]:Hide() end
        end
    end
    for d = 1, 2 do
        local dBtn = btn.debuffSlots[d]
        if d <= #debuffs then
            local debuff = debuffs[d]
            dBtn.unit = unit
            dBtn.auraIndex = debuff.index
            dBtn.auraFilter = debuff.auraFilter
            dBtn.rawInstanceID = debuff.rawInstanceID
            SafeSetAuraTexture(dBtn.icon, debuff.rawIcon, debuff.icon)
            local col = DISPEL_COLORS[debuff.dispelType] or DISPEL_COLORS["none"]
            dBtn:SetBackdropBorderColor(col.r, col.g, col.b, 1)
            if dBtn.secretOverlay then dBtn.secretOverlay:Hide() end
            ApplyAuraSlotCooldown(dBtn.cd, debuff)
            local dCount = SafeNumber(debuff.count, 0)
            if dCount > 1 then
                dBtn.countFs:SetText(tostring(dCount))
                dBtn.countFs:Show()
            else
                dBtn.countFs:Hide()
            end
            dBtn:Show()
        else
            dBtn.unit = nil
            dBtn.auraIndex = nil
            dBtn.auraFilter = nil
            dBtn.rawInstanceID = nil
            if dBtn.secretOverlay then dBtn.secretOverlay:Hide() end
            if dBtn.cd then pcall(dBtn.cd.Clear, dBtn.cd); dBtn.cd:Hide() end
            dBtn:Hide()
        end
    end
end

local function UpdatePartyGrid()
    local inCombat = InCombatLockdown and InCombatLockdown()
    if not IsGridPartyEnabled() then
        if gridContainer:IsShown() then
            if not inCombat then gridContainer:Hide() else pendingCombatGridSync = true end
        end
        return
    end

    local inGrp = (IsInGroup and SafeBoolean(SafeCall(IsInGroup), false))
        or (GetNumGroupMembers and SafeNumber(SafeCall(GetNumGroupMembers), 0) > 0)
        or (GetNumPartyMembers and SafeNumber(SafeCall(GetNumPartyMembers), 0) > 0)

    local s = GetSettings()
    local isLocked = (s.gridPartyLocked ~= false)
    if s.gridPartyPos and not gridContainer.posLoaded and not inCombat then
        gridContainer.posLoaded = true
        gridContainer:ClearAllPoints()
        gridContainer:SetPoint(s.gridPartyPos.point, UIParent, s.gridPartyPos.relPoint, s.gridPartyPos.x, s.gridPartyPos.y)
    end

    local showSolo = s.gridPartyShowSolo == true
    if not inGrp and not showSolo then
        if gridContainer:IsShown() then
            if not inCombat then gridContainer:Hide() else pendingCombatGridSync = true end
        end
        if not inCombat and gridMover then
            if isLocked then
                gridMover:Hide()
            else
                SyncGridMoverToContainer()
                gridMover:Show()
            end
        end
        return
    end

    if not inCombat then
        gridContainer:Show()
        local scale = s.gridPartyScale or 1.0
        gridContainer:SetScale(scale)

        if isLocked then
            gridMover:Hide()
        else
            SyncGridMoverToContainer()
            gridMover:Show()
        end
    elseif not gridContainer:IsShown() then
        pendingCombatGridSync = true
    end

    local activeCount = 0
    for i = 1, 5 do
        local btn = gridMembers[i]
        local unit = btn.unit
        local exists = SafeUnitExists(unit)
        if not inGrp and showSolo and i > 1 then
            exists = false
        end
        if exists then
            UpdateGridMember(btn)
            activeCount = activeCount + 1
        elseif not inCombat then
            btn:Hide()
        else
            pendingCombatGridSync = true
        end
    end

    if not inCombat then
        gridContainer:SetHeight(math.max(44, activeCount * 47))
        if not isLocked and gridMover:IsShown() then
            SyncGridMoverToContainer()
        end
        for i = 1, 4 do
            local f = _G["PartyMemberFrame" .. i]
            if f and f:IsShown() then
                f:Hide()
            end
        end
    else
        pendingCombatGridSync = true
    end
end

local function UpdateAllPartyMembers()
    local inCombat = InCombatLockdown and InCombatLockdown()
    if IsGridPartyEnabled() then
        UpdatePartyGrid()
    else
        if gridContainer and gridContainer:IsShown() then
            if not inCombat then
                gridContainer:Hide()
                if gridMover then gridMover:Hide() end
            else
                pendingCombatGridSync = true
            end
        elseif not inCombat and gridMover and gridMover:IsShown() then
            gridMover:Hide()
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
                    UpdateCompactPartyFrame(f, false)
                end
            end
        end
        if CompactRaidFrameContainer and CompactRaidFrameContainer:IsShown() and CompactRaidFrameContainer_ApplyToFrames then
            pcall(CompactRaidFrameContainer_ApplyToFrames, CompactRaidFrameContainer, "normal", function(f)
                if f then UpdateCompactPartyFrame(f, false) end
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

    if not IsClassFeaturesEnabled() or not SafeUnitIsPlayer(unit) then
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
            badge:SetSize(22, 22)
            badge:EnableMouse(false)

            local icon = badge:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(badge)
            badge.icon = icon

            local border = badge:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            border:SetSize(36, 36)
            border:SetPoint("CENTER", badge, "CENTER", 5.5, -4.5)
            badge.border = border

            host.nkClassBadge = badge
        end

        local baseLevel = (healthBar and healthBar.GetFrameLevel and healthBar:GetFrameLevel())
            or (host.GetFrameLevel and host:GetFrameLevel()) or 1
        badge:SetFrameLevel(baseLevel + 25)

        badge:ClearAllPoints()
        local nameShown = nameFs and nameFs.IsShown and nameFs:IsShown()
        local barShown = healthBar and healthBar.IsShown and healthBar:IsShown()
        local anchor = host
        if nameShown and barShown then
            local okT, nTop = pcall(nameFs.GetTop, nameFs)
            local okB, bTop = pcall(healthBar.GetTop, healthBar)
            if okT and okB and type(nTop) == "number" and type(bTop) == "number" then
                anchor = (nTop >= bTop) and nameFs or healthBar
            else
                anchor = nameFs
            end
        elseif nameShown then
            anchor = nameFs
        elseif barShown then
            anchor = healthBar
        end
        badge:SetPoint("BOTTOM", anchor, "TOP", 0, 4)

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
    if not SafeUnitExists(unit) then return end

    if not SafeUnitIsPlayer(unit) then
        -- For NPC / creature units, show tracked reagent drops in tooltip if any
        local uName = SafeUnitName(unit)
        if uName and FP.GetUnitTrackedReagent then
            local rInfo = FP:GetUnitTrackedReagent(unit, string.lower(uName))
            if rInfo then
                local n = tooltip:NumLines() or 0
                local tName = tooltip:GetName()
                local alreadyHas = false
                if tName then
                    for i = 1, n do
                        local line = _G[tName .. "TextLeft" .. i]
                        local txt = line and line.GetText and line:GetText()
                        if IsSafeStr(txt) and txt:find("Reagente", 1, true) then
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
                if IsSafeStr(text) and (text:find("Spec:", 1, true) or text:find("Specializzazione:", 1, true)) then
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
        if not SafeUnitIsUnit(unit, "player") then
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

    -- Normal portraits preserved (no class icon override)
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

    -- Note: CompactUnitFrame_Update* functions are intentionally NOT hooked.
    -- Hooking Blizzard's secure CompactUnitFrame execution stack taints internal raid frames,
    -- causing Blizzard's own CompactUnitFrame_UpdateAuras to fail with secret aura restrictions.
    -- Nameplates are updated independently via NAME_PLATE_UNIT_ADDED / UNIT_NAME_UPDATE without taint.
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
SafeRegisterEvent(evFrame, "SPELLS_CHANGED")
SafeRegisterEvent(evFrame, "PLAYER_REGEN_DISABLED")
SafeRegisterEvent(evFrame, "PLAYER_REGEN_ENABLED")

evFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    pcall(function()
        if event == "PLAYER_LOGIN" then
            HookBlizzardUnitFrames()
            RefreshAllGridDispelBindings()
            UpdateAllPartyMembers()
            UpdateTargetFrame()
        elseif event == "PLAYER_REGEN_DISABLED" then
            if gridMover then
                gridMover:SetScript("OnUpdate", nil)
                gridMover.nkDragging = false
                gridMover:Hide()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            RefreshAllGridDispelBindings()
            if FP.RefreshPartyGridLock then FP:RefreshPartyGridLock() end
            if pendingCombatGridSync then
                pendingCombatGridSync = false
                UpdateAllPartyMembers()
            end
        elseif event == "SPELLS_CHANGED" then
            RefreshAllGridDispelBindings()
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
            end
        elseif event == "INSPECT_READY" then
            HandleInspectReady(arg1)
        elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" then
            RefreshAllGridDispelBindings()
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
    if partyElapsed >= 0.5 then
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
    if InCombatLockdown and InCombatLockdown() then
        pendingCombatGridSync = true
        return
    end
    local s = GetSettings()
    if gridMover then
        if s.gridPartyLocked ~= false or not IsGridPartyEnabled() then
            gridMover:Hide()
        else
            SyncGridMoverToContainer()
            gridMover:Show()
        end
    end
end

function FP:SetPartyGridScale(scale)
    if gridContainer and scale then
        if InCombatLockdown and InCombatLockdown() then
            pendingCombatGridSync = true
            return
        end
        gridContainer:SetScale(scale)
    end
end

function FP:DumpPartyStatus()
    local enabled = IsClassFeaturesEnabled()
    local gridEnabled = IsGridPartyEnabled()
    local inGrp = (IsInGroup and SafeBoolean(SafeCall(IsInGroup), false))
        or (GetNumGroupMembers and SafeNumber(SafeCall(GetNumGroupMembers), 0) > 0)
        or (GetNumPartyMembers and SafeNumber(SafeCall(GetNumPartyMembers), 0) > 0) or false
    local nMembers = (GetNumGroupMembers and SafeNumber(SafeCall(GetNumGroupMembers), 0))
        or (GetNumPartyMembers and SafeNumber(SafeCall(GetNumPartyMembers), 0)) or 0
    FP:Print(string.format("ClassFrames: %s | Style: %s | InGroup: %s | Members: %d",
        enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r",
        gridEnabled and "|cff00ff96GRIGLIA|r" or "|cffffaa00CLASSICO|r",
        tostring(inGrp), nMembers))
    for i = 1, 4 do
        local f = _G["PartyMemberFrame" .. i]
        if f then
            local u = f.unit or ("party" .. i)
            local exists = SafeUnitExists(u)
            local name = SafeUnitName(u) or "n/a"
            local _, engClass = SafeCall(UnitClass, u)
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
