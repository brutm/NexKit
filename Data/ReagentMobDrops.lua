-- NexusKit - Data/ReagentMobDrops.lua
-- Database of mob keywords, creature families, and drop rules for tracked reagents.
local addonName, FP = ...
FP.ReagentMobDrops = FP.ReagentMobDrops or {}

local function IsSafeNum(v)
    return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

local function GetItemCountCompat(item)
    if not item then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, c = pcall(C_Item.GetItemCount, item, false)
        if ok and type(c) == "number" then return c end
    elseif GetItemCount then
        local ok, c = pcall(GetItemCount, item, false)
        if ok and type(c) == "number" then return c end
    end
    return 0
end

local function GetItemIconCompat(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemIconByID and type(item) == "number" then
        local ok, tex = pcall(C_Item.GetItemIconByID, item)
        if ok and tex then return tex end
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, icon = pcall(C_Item.GetItemInfoInstant, item)
        if ok and icon then return icon end
    end
    if GetItemInfoInstant then
        local ok, _, _, _, icon = pcall(GetItemInfoInstant, item)
        if ok and icon then return icon end
    end
    return nil
end

local REAGENT_MOB_MAP = {
    -- 1. Class Reagents & Consumables
    [17056] = { -- Light Feather / Piuma Leggera (Mage Slow Fall, Priest Levitate)
        patterns = {
            "harpy", "arpia", "vulture", "avvoltoio", "buzzard", "fire roc", "greater roc", "owlbeast", "gufigufo",
            "moonkin", "wildkin", "carrion bird", "carrion vulture", "falcon", "falco", "eagle", "aquila", "bird",
            "uccello", "seagull", "gabbiano", "fleshripper", "shrieker", "dreadbird", "corvo",
            "crow", "raven", "wind serpent", "serpente alato", "hippogryph", "ippogrifo",
            "gryphon", "grifone", "hawk", "poultry", "chicken", "gallina", "hawkstrider",
            "tallstrider", "condor", "screamer", "plumed", "feathered", "pennuto",
        },
    },
    [17057] = { -- Fish Oil / Olio di Pesce (Shaman Water Walking / Breathing)
        patterns = {
            "murloc", "naga", "siren", "sirena", "frenzy", "shark", "squalo", "crawler", "granchio",
            "makrura", "snapjaw", "tartaruga", "threshadon", "clam", "oyster", "fin", "pinna",
            "deepstrider", "tiderunner", "greymist", "saltscale", "wrathfin", "vilefin", "muckshell",
        },
    },
    [17058] = { -- Shiny Fish Scales / Scaglie di Pesce Brillanti (Shaman Water Walking)
        patterns = {
            "murloc", "naga", "frenzy", "snapjaw", "tartaruga", "makrura", "threshadon",
            "greymist", "saltscale", "wrathfin", "vilefin", "spinescale", "deepstrider",
        },
    },

    -- 2. Cloth (Stoffe)
    [2589] = { -- Linen Cloth / Stoffa di Lino
        patterns = {
            "defias", "kobold", "coboldo", "gnoll", "trogg", "bandit", "bandito", "peon",
            "quilboar", "verrospino", "human", "orco", "orc", "troll", "raider", "scout",
            "thief", "ladro", "brigand", "brigante", "pirate", "pirata", "dark iron", "syndicate",
            "sindacato", "rebel", "ribelle", "outrunner", "grunt", "cultist", "cultista", "footpad",
            "cutpurse", "tagliaborse", "smuggler", "contrabbandiere", "highwayman",
        },
    },
    [2592] = { -- Wool Cloth / Stoffa di Lana
        patterns = {
            "defias", "syndicate", "sindacato", "kolkar", "centaur", "centauro", "kurzen",
            "dark iron", "magram", "gelkis", "galak", "razormane", "bristleback", "dragonmaw",
            "ironband", "dun garok", "witherbark", "scarlet", "scarlatt", "troll", "dwarf",
            "nano", "dwarven", "infiltrator", "renegade", "rinnegato", "marauder",
            "shadowhide", "gnoll", "campomorto", "orc", "orco", "ogre",
        },
    },
    [4306] = { -- Silk Cloth / Stoffa di Seta
        patterns = {
            "syndicate", "scarlet", "scarlatt", "ogre", "troll", "bloodscalp", "skullsplitter",
            "crushridge", "ironmarch", "dunemaul", "firegut", "witherbark", "vilebranch",
            "spirestone", "smolderthorn", "naga", "centaur", "centauro", "wastewander",
        },
    },
    [4338] = { -- Mageweave Cloth / Tessuto di Magia
        patterns = {
            "ogre", "troll", "dunemaul", "wastewander", "sandfury", "woodpaw", "thistlefur",
            "spirestone", "firegut", "smolderthorn", "scarlet", "scarlatt", "cultist",
            "cultista", "undead", "non morto", "sorcerer", "stregone", "necromancer",
            "shadowforge", "bloodpelt", "hatecrest",
        },
    },
    [14047] = { -- Runecloth / Tessuto Runico
        patterns = {
            "cultist", "cultista", "scarlet", "scarlatt", "twilight", "crepuscol", "scourge",
            "flagello", "ghoul", "zombie", "skeleton", "scheletro", "deathknight",
            "cavaliere della morte", "blood elf", "elfo del sangue", "shadowforge", "firebrand",
            "spirestone", "darkvessel", "hexxer", "deathsworn", "vilebranch", "witch doctor",
        },
    },
    [14256] = { -- Felcloth / Stoffa Vile
        patterns = {
            "satyr", "satiro", "felhound", "demone", "demon", "infernale", "infernal",
            "doomguard", "dreadlord", "legion", "legione", "jaedenar", "hateflayer",
            "shadowstalker", "betrayer", "hellcaller", "wildspawn", "bleakheart",
        },
    },

    -- 3. Elementals & Essences (Elementali ed Essenze)
    [7076] = { -- Elemental Earth / Terra Elementale
        patterns = {
            "earth elemental", "elementale della terra", "rock elemental", "geoelemental",
            "golem", "rumbler", "colosso", "rockslide", "earth tremor", "shardling", "stonevault",
        },
    },
    [7078] = { -- Elemental Fire / Fuoco Elementale
        patterns = {
            "fire elemental", "elementale del fuoco", "blazing", "flame", "fiamma",
            "ember", "lava", "magma", "scald", "volcano", "pyro", "cinder", "searing",
        },
    },
    [7080] = { -- Elemental Water / Acqua Elementale
        patterns = {
            "water elemental", "elementale dell'acqua", "sea elemental", "wave", "onda",
            "tiderunner", "hydra", "idra", "surge", "torrent", "spray",
        },
    },
    [7082] = { -- Elemental Air / Aria Elementale
        patterns = {
            "air elemental", "elementale dell'aria", "dust devil", "cyclone", "vortice",
            "storm", "tempesta", "whirlwind", "wind", "gust", "zephyr",
        },
    },
    [12808] = { -- Essence of Water / Essenza d'Acqua
        patterns = { "water elemental", "toxic horror", "hydra", "idra", "elementale dell'acqua", "tiderunner" },
    },
    [12803] = { -- Essence of Fire / Essenza di Fuoco
        patterns = { "fire elemental", "flame", "blazing", "lava", "magma", "elementale del fuoco" },
    },
    [12804] = { -- Essence of Earth / Essenza di Terra
        patterns = { "earth elemental", "colosso", "golem", "rock", "elementale della terra" },
    },
    [12805] = { -- Essence of Air / Essenza d'Aria
        patterns = { "air elemental", "cyclone", "storm", "tempesta", "dust devil", "elementale dell'aria" },
    },
    [12807] = { -- Essence of Undeath / Essenza di Non Morte
        patterns = { "ghoul", "skeleton", "scheletro", "undead", "non morto", "wight", "wraith", "banshee", "shade", "ombra", "scourge" },
    },

    -- 4. Special Drops & Reagents
    [6889] = { -- Small Egg / Uovo Piccolo
        patterns = { "hawkstrider", "tallstrider", "moonkin", "owlbeast", "dragonhawk", "bird", "vulture", "buzzard", "fire roc", "greater roc", "gufigufo", "condor" },
    },
    [4611] = { -- Small Lustrous Pearl
        patterns = { "murloc", "makrura", "naga", "clam", "clam meat", "greymist", "saltscale" },
    },
    [5498] = { -- Iridescent Pearl
        patterns = { "murloc", "makrura", "naga", "clam", "crawler" },
    },
    [7971] = { -- Black Pearl
        patterns = { "naga", "makrura", "murloc", "clam", "giant clam" },
    },
    [13926] = { -- Golden Pearl
        patterns = { "naga", "makrura", "clam", "giant clam", "hatescale", "wrathfin" },
    },
}

local ANIMAL_KEYWORDS = {
    ["boar"]        = { "boar", "cinghiale", "porco", "swine" },
    ["cinghiale"]   = { "boar", "cinghiale", "porco", "swine" },
    ["wolf"]        = { "wolf", "lupo", "worg" },
    ["lupo"]        = { "wolf", "lupo", "worg" },
    ["bear"]        = { "bear", "orso" },
    ["orso"]        = { "bear", "orso" },
    ["spider"]      = { "spider", "ragno", "tarantula" },
    ["ragno"]       = { "spider", "ragno", "tarantula" },
    ["crocolisk"]   = { "crocolisk", "coccodrillo", "alligator" },
    ["coccodrillo"] = { "crocolisk", "coccodrillo", "alligator" },
    ["raptor"]      = { "raptor" },
    ["lion"]        = { "lion", "leone", "panther", "pantera", "tiger", "tigre", "cat", "gatto" },
    ["leone"]       = { "lion", "leone", "panther", "pantera", "tiger", "tigre", "cat", "gatto" },
    ["tiger"]       = { "tiger", "tigre", "panther", "pantera", "cat" },
    ["tigre"]       = { "tiger", "tigre", "panther", "pantera", "cat" },
    ["turtle"]      = { "turtle", "tartaruga", "snapjaw" },
    ["tartaruga"]   = { "turtle", "tartaruga", "snapjaw" },
    ["murloc"]      = { "murloc" },
    ["scorpid"]     = { "scorpid", "scorpione" },
    ["scorpione"]   = { "scorpid", "scorpione" },
    ["gorilla"]     = { "gorilla" },
    ["bat"]         = { "bat", "pipistrello" },
    ["pipistrello"] = { "bat", "pipistrello" },
    ["crab"]        = { "crab", "granchio", "crawler" },
    ["granchio"]    = { "crab", "granchio", "crawler" },
    ["stag"]        = { "stag", "cervo", "gazelle", "gazella" },
    ["cervo"]       = { "stag", "cervo", "gazelle", "gazella" },
    ["snake"]       = { "snake", "serpente", "adder", "cobra", "viper" },
    ["serpente"]    = { "snake", "serpente", "adder", "cobra", "viper" },
    ["yeti"]        = { "yeti" },
    ["ogre"]        = { "ogre" },
    ["feather"]     = { "harpy", "arpia", "vulture", "avvoltoio", "buzzard", "fire roc", "greater roc", "owlbeast", "gufigufo", "falcon", "eagle", "aquila", "bird" },
    ["piuma"]       = { "harpy", "arpia", "vulture", "avvoltoio", "buzzard", "fire roc", "greater roc", "owlbeast", "gufigufo", "falcon", "eagle", "aquila", "bird" },
}

local STOP_WORDS = {
    ["meat"] = true, ["carne"] = true,
    ["pelt"] = true, ["pelle"] = true,
    ["hide"] = true, ["cuoio"] = true,
    ["bone"] = true, ["osso"] = true, ["ossa"] = true,
    ["tooth"] = true, ["dente"] = true, ["denti"] = true,
    ["scale"] = true, ["scaglia"] = true, ["scaglie"] = true,
    ["tail"] = true, ["coda"] = true,
    ["wing"] = true, ["ala"] = true, ["ali"] = true,
    ["horn"] = true, ["corno"] = true, ["corna"] = true,
    ["blood"] = true, ["sangue"] = true,
    ["ichor"] = true, ["icore"] = true,
    ["venom"] = true, ["veleno"] = true,
    ["sac"] = true, ["sacca"] = true,
    ["eye"] = true, ["occhio"] = true, ["occhi"] = true,
    ["ribs"] = true, ["costine"] = true,
    ["flank"] = true, ["cosciotto"] = true,
    ["light"] = true, ["chiaro"] = true,
    ["dark"] = true, ["scuro"] = true,
    ["large"] = true, ["grande"] = true,
    ["small"] = true, ["piccolo"] = true,
    ["fresh"] = true, ["fresco"] = true,
    ["piece"] = true, ["pezzo"] = true,
}

local function MobMatchesPattern(mobName, pattern)
    if not mobName or not pattern or pattern == "" then return false end
    local escaped = pattern:gsub("([%%%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    if mobName:find("%f[%a]" .. escaped .. "%f[%A]") then
        return true
    end
    if mobName:find("%f[%a]" .. escaped .. "s%f[%A]") then
        return true
    end
    return false
end

local function IsHumanoidType(t)
    if not t then return false end
    return t:find("human") or t:find("uman") or t:find("mensch")
end

local function IsBeastType(t)
    if not t then return false end
    return t:find("beast") or t:find("best") or t:find("wildtier") or t:find("bête")
end

local function IsElementalType(t)
    if not t then return false end
    return t:find("element")
end

function FP:GetUnitTrackedReagent(unit, lowerMobName)
    if not lowerMobName or lowerMobName == "" then return nil end
    local db = NexKitCharDB or NexusKitCharDB
    if not (db and db.trackedReagents) then return nil end

    local creatureType = unit and UnitCreatureType and UnitCreatureType(unit)
    local lowerType = creatureType and string.lower(creatureType) or nil

    for key, rec in pairs(db.trackedReagents) do
        if type(rec) == "table" and (rec.name or rec.itemID) then
            local itemID = rec.itemID
            local targetCount = tonumber(rec.target)
            local curBags = itemID and GetItemCountCompat(itemID) or 0

            -- If a target goal was set and already achieved, do not highlight
            local isGoalReached = (targetCount and targetCount > 0 and curBags >= targetCount)
            if not isGoalReached then
                local isCategoryBlocked = false
                local isFeatherItem = (itemID == 17056) or (rec.name and (rec.name:lower():find("feather") or rec.name:lower():find("piuma")))
                local isClothItem = (itemID == 2589 or itemID == 2592 or itemID == 4306 or itemID == 4338 or itemID == 14047 or itemID == 14256)
                    or (rec.name and (rec.name:lower():find("cloth") or rec.name:lower():find("stoffa") or rec.name:lower():find("tessuto")))
                local isAnimalMeatOrPelt = rec.name and (rec.name:lower():find("meat") or rec.name:lower():find("carne") or rec.name:lower():find("pelt") or rec.name:lower():find("pelle") or rec.name:lower():find("hide") or rec.name:lower():find("cuoio"))
                local isElementalItem = (itemID == 7076 or itemID == 7078 or itemID == 7080 or itemID == 7082 or itemID == 12808 or itemID == 12803 or itemID == 12804 or itemID == 12805)

                if isFeatherItem and lowerType then
                    if IsHumanoidType(lowerType) then
                        local isHarpy = lowerMobName:find("harpy", 1, true) or lowerMobName:find("arpia", 1, true)
                        if not isHarpy then
                            isCategoryBlocked = true
                        end
                    elseif not IsBeastType(lowerType) then
                        isCategoryBlocked = true
                    end
                elseif isClothItem and lowerType then
                    if IsBeastType(lowerType) or lowerType:find("critter") or lowerType:find("creatura") or lowerType:find("mechanical") or lowerType:find("meccanico") then
                        isCategoryBlocked = true
                    end
                elseif isAnimalMeatOrPelt and lowerType then
                    if IsHumanoidType(lowerType) or IsElementalType(lowerType) or lowerType:find("mechanical") or lowerType:find("meccanico") then
                        isCategoryBlocked = true
                    end
                elseif isElementalItem and lowerType then
                    if IsBeastType(lowerType) or IsHumanoidType(lowerType) then
                        isCategoryBlocked = true
                    end
                end

                if not isCategoryBlocked then
                    local isMatch = false

                    -- 1. Check explicit itemID pattern list
                    if itemID and REAGENT_MOB_MAP[itemID] then
                        local pats = REAGENT_MOB_MAP[itemID].patterns
                        for _, p in ipairs(pats) do
                            if MobMatchesPattern(lowerMobName, p) then
                                isMatch = true
                                break
                            end
                        end
                    end

                    -- 2. Check dynamic animal/creature keywords from item name
                    if not isMatch and rec.name then
                        local cleanItemName = string.lower(rec.name:gsub("[%p%c]", " "))
                        for word in cleanItemName:gmatch("%S+") do
                            if ANIMAL_KEYWORDS[word] then
                                for _, p in ipairs(ANIMAL_KEYWORDS[word]) do
                                    if MobMatchesPattern(lowerMobName, p) then
                                        isMatch = true
                                        break
                                    end
                                end
                                if isMatch then break end
                            elseif #word >= 4 and not STOP_WORDS[word] then
                                if MobMatchesPattern(lowerMobName, word) then
                                    isMatch = true
                                    break
                                end
                            end
                        end
                    end

                    if isMatch then
                        local icon = rec.icon
                        if (not icon or icon == "Interface\\Icons\\INV_Misc_QuestionMark") and itemID then
                            icon = GetItemIconCompat(itemID) or icon
                        end
                        local tagText = (targetCount and targetCount > 0) and string.format("%d/%d", curBags, targetCount) or string.format("%d", curBags)
                        local fullTitle = rec.name .. ((targetCount and targetCount > 0) and string.format(" (%d/%d)", curBags, targetCount) or string.format(" (%d)", curBags))
                        return {
                            key = key,
                            itemID = itemID,
                            name = rec.name,
                            icon = icon or "Interface\\Icons\\INV_Misc_Bag_08",
                            curCount = curBags,
                            targetCount = targetCount,
                            tagText = tagText,
                            fullTitle = fullTitle,
                        }
                    end
                end
            end
        end
    end
    return nil
end
