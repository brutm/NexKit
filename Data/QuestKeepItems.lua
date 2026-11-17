-------------------------------------------------------------------------------
-- NexusKit - Data/QuestKeepItems.lua
-- Database and live Quest Log matcher for vendible / non-quest-tagged items
-- required by current, same-zone, or upcoming leveling quests (Levels 1-60).
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function IsSafeNum(v)
    return type(v) == "number" and not IsSecret(v)
end

local function IsSafeStr(v)
    return type(v) == "string" and not IsSecret(v) and v ~= ""
end

local function NormalizeName(name)
    if not IsSafeStr(name) then return nil end
    return string.lower((name:match("^%s*(.-)%s*$") or ""))
end

local function GetContinentForMap(mapID)
    if not IsSafeNum(mapID) or mapID <= 0 or not C_Map or not C_Map.GetMapInfo then
        return nil
    end
    local cur = mapID
    for _ = 1, 4 do
        local ok, info = pcall(C_Map.GetMapInfo, cur)
        if not ok or type(info) ~= "table" then break end
        if Enum and Enum.UIMapType and info.mapType == Enum.UIMapType.Continent then
            return cur
        elseif not (Enum and Enum.UIMapType) and info.mapType == 2 then
            return cur
        end
        if IsSafeNum(info.parentMapID) and info.parentMapID > 0 and info.parentMapID ~= cur then
            cur = info.parentMapID
        else
            break
        end
    end
    return nil
end

local function GetLocalizedZoneName(mapID, fallback)
    if IsSafeNum(mapID) and mapID > 0 and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if ok and type(info) == "table" and IsSafeStr(info.name) then
            return info.name
        end
    end
    return fallback or ""
end

local function GetLocalizedQuestTitle(questId, fallback)
    if IsSafeNum(questId) and questId > 0 and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questId)
        if ok and IsSafeStr(title) then
            return title
        end
    end
    return fallback or ("Quest #" .. tostring(questId or "?"))
end

local function IsQuestCompleted(questId)
    if not IsSafeNum(questId) or questId <= 0 then return false end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questId)
        if ok and type(done) == "boolean" then
            return done
        end
    elseif IsQuestFlaggedCompleted then
        local ok, done = pcall(IsQuestFlaggedCompleted, questId)
        if ok and type(done) == "boolean" then
            return done
        end
    end
    return false
end

local function IsQuestInLog(questId)
    if not IsSafeNum(questId) or questId <= 0 then return false end
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, onQuest = pcall(C_QuestLog.IsOnQuest, questId)
        if ok and type(onQuest) == "boolean" then
            return onQuest
        end
    elseif GetQuestLogIndexByID then
        local ok, idx = pcall(GetQuestLogIndexByID, questId)
        if ok and IsSafeNum(idx) and idx > 0 then
            return true
        end
    end
    return false
end

local function GetItemCountCompat(item, includeBank)
    if not item then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, cnt = pcall(C_Item.GetItemCount, item, includeBank)
        if ok and IsSafeNum(cnt) then return cnt end
    elseif GetItemCount then
        local ok, cnt = pcall(GetItemCount, item, includeBank)
        if ok and IsSafeNum(cnt) then return cnt end
    end
    return 0
end

-------------------------------------------------------------------------------
-- Curated Classic Leveling Quest-Keep Database (vendible / white / grey items)
-------------------------------------------------------------------------------
FP.QUEST_KEEP_ITEMS = {
    -- Alliance Low-Level (Elwynn, Dun Morogh, Loch Modan, Westfall, Redridge, Duskwood)
    [159] = {
        en = "Refreshing Spring Water",
        quests = {
            { questId = 16, name = "Give Gerard a Drink", level = 1, mapID = 1429, zone = "Elwynn Forest", faction = "Alliance", count = 1 },
        },
    },
    [750] = {
        en = "Tough Wolf Meat",
        quests = {
            { questId = 33, name = "Wolves Across the Border", level = 2, mapID = 1429, zone = "Elwynn Forest", faction = "Alliance", count = 8 },
            { questId = 179, name = "Dwarven Outfitters", level = 2, mapID = 1426, zone = "Dun Morogh", faction = "Alliance", count = 8 },
        },
    },
    [772] = {
        en = "Large Candle",
        quests = {
            { questId = 60, name = "Kobold Candles", level = 7, mapID = 1429, zone = "Elwynn Forest", faction = "Alliance", count = 8 },
        },
    },
    [2886] = {
        en = "Crag Boar Rib",
        quests = {
            { questId = 384, name = "Beer Basted Boar Ribs", level = 7, mapID = 1426, zone = "Dun Morogh", faction = "Alliance", count = 6 },
        },
    },
    [3172] = {
        en = "Boar Intestines",
        quests = {
            { questId = 418, name = "Thelsamar Blood Sausages", level = 12, mapID = 1432, zone = "Loch Modan", faction = "Alliance", count = 3 },
        },
    },
    [3173] = {
        en = "Bear Meat",
        quests = {
            { questId = 418, name = "Thelsamar Blood Sausages", level = 12, mapID = 1432, zone = "Loch Modan", faction = "Alliance", count = 3 },
        },
    },
    [3174] = {
        en = "Spider Ichor",
        quests = {
            { questId = 418, name = "Thelsamar Blood Sausages", level = 12, mapID = 1432, zone = "Loch Modan", faction = "Alliance", count = 3 },
        },
    },
    [723] = {
        en = "Goretusk Liver",
        quests = {
            { questId = 22, name = "Goretusk Liver Pie", level = 12, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 8 },
        },
    },
    [731] = {
        en = "Goretusk Snout",
        quests = {
            { questId = 38, name = "Westfall Stew", level = 13, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 3 },
        },
    },
    [729] = {
        en = "Stringy Vulture Meat",
        quests = {
            { questId = 38, name = "Westfall Stew", level = 13, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 3 },
        },
    },
    [730] = {
        en = "Murloc Eye",
        quests = {
            { questId = 38, name = "Westfall Stew", level = 13, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 3 },
        },
    },
    [732] = {
        en = "Okra",
        quests = {
            { questId = 38, name = "Westfall Stew", level = 13, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 3 },
        },
    },
    [1274] = {
        en = "Hops",
        quests = {
            { questId = 117, name = "Thunderbrew Lager", level = 15, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 5 },
        },
    },
    [1262] = {
        en = "Keg of Thunderbrew Lager",
        quests = {
            { questId = 116, name = "Dry Times", level = 15, mapID = 1433, zone = "Redridge Mountains", faction = "Alliance", count = 1 },
        },
    },
    [814] = {
        en = "Flask of Oil",
        quests = {
            { questId = 103, name = "Keeper of the Flame", level = 16, mapID = 1436, zone = "Westfall", faction = "Alliance", count = 5 },
        },
    },
    [2296] = {
        en = "Great Goretusk Snout",
        quests = {
            { questId = 92, name = "Redridge Goulash", level = 18, mapID = 1433, zone = "Redridge Mountains", faction = "Alliance", count = 5 },
        },
    },
    [1080] = {
        en = "Tough Condor Meat",
        quests = {
            { questId = 92, name = "Redridge Goulash", level = 18, mapID = 1433, zone = "Redridge Mountains", faction = "Alliance", count = 5 },
        },
    },
    [1081] = {
        en = "Crisp Spider Meat",
        quests = {
            { questId = 92, name = "Redridge Goulash", level = 18, mapID = 1433, zone = "Redridge Mountains", faction = "Alliance", count = 5 },
        },
    },
    [1468] = {
        en = "Murloc Fin",
        quests = {
            { questId = 150, name = "Murloc Poachers", level = 20, mapID = 1433, zone = "Redridge Mountains", faction = "Alliance", count = 8 },
        },
    },
    [1015] = {
        en = "Lean Wolf Flank",
        quests = {
            { questId = 90, name = "Seasoned Wolf Kabobs", level = 25, mapID = 1431, zone = "Duskwood", faction = "Alliance", count = 10 },
        },
    },
    [4371] = {
        en = "Bronze Tube",
        quests = {
            { questId = 181, name = "Look To The Stars", level = 25, mapID = 1431, zone = "Duskwood", faction = "Alliance", count = 1 },
        },
    },

    -- Horde Early & Mid-Level (Tirisfal, Mulgore, The Barrens, Ashenvale, Arathi)
    [2876] = {
        en = "Duskbat Pelt",
        quests = {
            { questId = 375, name = "The Chill of Death", level = 8, mapID = 1420, zone = "Tirisfal Glades", faction = "Horde", count = 5 },
        },
    },
    [4740] = {
        en = "Plainstrider Feather",
        quests = {
            { questId = 747, name = "The Hunt Begins", level = 3, mapID = 1412, zone = "Mulgore", faction = "Horde", count = 7 },
        },
    },
    [5086] = {
        en = "Zhevra Hooves",
        quests = {
            { questId = 845, name = "The Zhevra", level = 13, mapID = 1413, zone = "The Barrens", faction = "Horde", count = 4 },
        },
    },
    [5062] = {
        en = "Raptor Head",
        quests = {
            { questId = 869, name = "Raptor Thieves", level = 13, mapID = 1413, zone = "The Barrens", faction = "Horde", count = 12 },
        },
    },
    [5075] = {
        en = "Blood Shard",
        quests = {
            { questId = 5052, name = "Blood Shards of Agamaggan", level = 14, mapID = 1413, zone = "The Barrens", faction = "Horde", count = 1 },
        },
    },
    [4369] = {
        en = "Deadly Blunderbuss",
        quests = {
            { questId = 6571, name = "Warsong Supplies", level = 25, mapID = 1440, zone = "Ashenvale", faction = "Horde", count = 1 },
        },
    },
    [4513] = {
        en = "Raptor Heart",
        quests = {
            { questId = 701, name = "Guile of the Raptor", level = 37, mapID = 1417, zone = "Arathi Highlands", faction = "Horde", count = 12 },
        },
    },

    -- Hillsbrad Foothills (30-36)
    [3712] = {
        en = "Turtle Meat",
        quests = {
            { questId = 555,  name = "Soothing Turtle Bisque", level = 31, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Alliance", count = 10 },
            { questId = 7321, name = "Soothing Turtle Bisque", level = 31, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Horde",    count = 10 },
        },
    },
    [3720] = {
        en = "Yeti Fur",
        quests = {
            { questId = 565, name = "Bartolo's Yeti Fur Cloak", level = 34, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Alliance", count = 10 },
        },
    },
    [3719] = {
        en = "Hillman's Cloak",
        quests = {
            { questId = 565, name = "Bartolo's Yeti Fur Cloak", level = 34, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Alliance", count = 1 },
        },
    },
    [2997] = {
        en = "Bolt of Woolen Cloth",
        quests = {
            { questId = 565, name = "Bartolo's Yeti Fur Cloak", level = 34, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Alliance", count = 1 },
        },
    },
    [2321] = {
        en = "Fine Thread",
        quests = {
            { questId = 565, name = "Bartolo's Yeti Fur Cloak", level = 34, mapID = 1424, zone = "Hillsbrad Foothills", faction = "Alliance", count = 1 },
        },
    },

    -- Stranglethorn Vale (33-42)
    [3918] = {
        en = "Singing Crystal Shard",
        quests = {
            { questId = 605, name = "Singing Blue Shards", level = 35, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 10 },
        },
    },
    [4278] = {
        en = "Lesser Bloodstone Ore",
        quests = {
            { questId = 627, name = "Favor for Krazek", level = 37, mapID = 1434, zone = "Stranglethorn Vale", faction = "Alliance", count = 4 },
        },
    },
    [2725] = { en = "Green Hills of Stranglethorn - Page 1",  quests = { { questId = 339, name = "Chapter I",   level = 36, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2728] = { en = "Green Hills of Stranglethorn - Page 4",  quests = { { questId = 339, name = "Chapter I",   level = 36, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2730] = { en = "Green Hills of Stranglethorn - Page 6",  quests = { { questId = 339, name = "Chapter I",   level = 36, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2732] = { en = "Green Hills of Stranglethorn - Page 8",  quests = { { questId = 339, name = "Chapter I",   level = 36, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2734] = { en = "Green Hills of Stranglethorn - Page 10", quests = { { questId = 340, name = "Chapter II",  level = 38, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2735] = { en = "Green Hills of Stranglethorn - Page 11", quests = { { questId = 340, name = "Chapter II",  level = 38, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2738] = { en = "Green Hills of Stranglethorn - Page 14", quests = { { questId = 340, name = "Chapter II",  level = 38, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2740] = { en = "Green Hills of Stranglethorn - Page 16", quests = { { questId = 340, name = "Chapter II",  level = 38, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2742] = { en = "Green Hills of Stranglethorn - Page 18", quests = { { questId = 341, name = "Chapter III", level = 40, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2744] = { en = "Green Hills of Stranglethorn - Page 20", quests = { { questId = 341, name = "Chapter III", level = 40, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2745] = { en = "Green Hills of Stranglethorn - Page 21", quests = { { questId = 341, name = "Chapter III", level = 40, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2748] = { en = "Green Hills of Stranglethorn - Page 24", quests = { { questId = 341, name = "Chapter III", level = 40, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2749] = { en = "Green Hills of Stranglethorn - Page 25", quests = { { questId = 342, name = "Chapter IV",  level = 42, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2750] = { en = "Green Hills of Stranglethorn - Page 26", quests = { { questId = 342, name = "Chapter IV",  level = 42, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },
    [2751] = { en = "Green Hills of Stranglethorn - Page 27", quests = { { questId = 342, name = "Chapter IV",  level = 42, mapID = 1434, zone = "Stranglethorn Vale", faction = "Both", count = 1 } } },

    -- Badlands (36-45)
    [4611] = {
        en = "Blue Pearl",
        quests = {
            { questId = 705, name = "Pearl Diving", level = 37, mapID = 1418, zone = "Badlands", faction = "Both", count = 9 },
        },
    },
    [3829] = {
        en = "Frost Oil",
        quests = {
            { questId = 713, name = "Coolant Heads Prevail", level = 37, mapID = 1418, zone = "Badlands", faction = "Both", count = 1 },
        },
    },
    [4389] = {
        en = "Gyrochronatom",
        quests = {
            { questId = 714, name = "Gyro... What?", level = 37, mapID = 1418, zone = "Badlands", faction = "Both", count = 1 },
        },
    },
    [929] = {
        en = "Healing Potion",
        quests = {
            { questId = 715, name = "Liquid Stone", level = 37, mapID = 1418, zone = "Badlands", faction = "Both", count = 1 },
        },
    },
    [3823] = {
        en = "Lesser Invisibility Potion",
        quests = {
            { questId = 715, name = "Liquid Stone", level = 37, mapID = 1418, zone = "Badlands", faction = "Both", count = 1 },
        },
    },
    [2868] = {
        en = "Patterned Bronze Bracers",
        quests = {
            { questId = 716, name = "Stone Is Better than Cloth", level = 42, mapID = 1418, zone = "Badlands", faction = "Both", count = 1 },
        },
    },
    [3404] = {
        en = "Buzzard Wing",
        quests = {
            { questId = 703, name = "Barbecued Buzzard Wings", level = 40, mapID = 1418, zone = "Badlands", faction = "Both", count = 4 },
        },
    },

    -- Tanaris, Feralas, Un'Goro Crater (43-55)
    [8483] = {
        en = "Wastewander Water Pouch",
        quests = {
            { questId = 1707, name = "Water Pouch Bounty", level = 44, mapID = 1446, zone = "Tanaris", faction = "Both", count = 5 },
        },
    },
    [7974] = {
        en = "Zesty Clam Meat",
        quests = {
            { questId = 6610, name = "Clamlette Surprise", level = 45, mapID = 1446, zone = "Tanaris", faction = "Both", count = 10 },
        },
    },
    [12207] = {
        en = "Giant Egg",
        quests = {
            { questId = 6610, name = "Clamlette Surprise", level = 45, mapID = 1446, zone = "Tanaris", faction = "Both", count = 12 },
        },
    },
    [3825] = {
        en = "Elixir of Fortitude",
        quests = {
            { questId = 3842, name = "A Short Incubation", level = 47, mapID = 1441, zone = "Thousand Needles", faction = "Alliance", count = 2 },
        },
    },
    [11018] = {
        en = "Un'Goro Soil",
        quests = {
            { questId = 3764, name = "Un'Goro Soil", level = 50, mapID = 1449, zone = "Un'Goro Crater", faction = "Alliance", count = 20 },
            { questId = 3761, name = "Un'Goro Soil", level = 50, mapID = 1449, zone = "Un'Goro Crater", faction = "Horde",    count = 20 },
        },
    },
    [11040] = {
        en = "Morrowgrain",
        quests = {
            { questId = 3791, name = "The Mystery of Morrowgrain", level = 52, mapID = 1444, zone = "Feralas",     faction = "Alliance", count = 10 },
            { questId = 3786, name = "Morrowgrain Research",       level = 50, mapID = 1412, zone = "Thunder Bluff", faction = "Horde",  count = 10 },
        },
    },
    [11184] = {
        en = "Blue Power Crystal",
        quests = {
            { questId = 4284, name = "Crystals of Power", level = 53, mapID = 1449, zone = "Un'Goro Crater", faction = "Both", count = 7 },
        },
    },
    [11185] = {
        en = "Green Power Crystal",
        quests = {
            { questId = 4284, name = "Crystals of Power", level = 53, mapID = 1449, zone = "Un'Goro Crater", faction = "Both", count = 7 },
        },
    },
    [11186] = {
        en = "Red Power Crystal",
        quests = {
            { questId = 4284, name = "Crystals of Power", level = 53, mapID = 1449, zone = "Un'Goro Crater", faction = "Both", count = 7 },
        },
    },
    [11188] = {
        en = "Yellow Power Crystal",
        quests = {
            { questId = 4284, name = "Crystals of Power", level = 53, mapID = 1449, zone = "Un'Goro Crater", faction = "Both", count = 7 },
        },
    },

    -- Blasted Lands, Felwood, Winterspring, Eastern Plaguelands (50-60)
    [8391] = {
        en = "Snickerfang Jowl",
        quests = {
            { questId = 2581, name = "Snickerfang Jowls", level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 3 },
            { questId = 2603, name = "Vulture's Vigor",   level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 2 },
        },
    },
    [8392] = {
        en = "Blasted Boar Lung",
        quests = {
            { questId = 2583, name = "A Boar's Vitality", level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 3 },
            { questId = 2581, name = "Snickerfang Jowls", level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 2 },
        },
    },
    [8393] = {
        en = "Scorpok Pincer",
        quests = {
            { questId = 2585, name = "The Decisive Striker", level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 3 },
            { questId = 2583, name = "A Boar's Vitality",    level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 2 },
        },
    },
    [8394] = {
        en = "Basilisk Brain",
        quests = {
            { questId = 2601, name = "The Basilisk's Bite", level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 10 },
            { questId = 2583, name = "A Boar's Vitality",   level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 1 },
        },
    },
    [8396] = {
        en = "Vulture Gizzard",
        quests = {
            { questId = 2603, name = "Vulture's Vigor",      level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 10 },
            { questId = 2601, name = "The Basilisk's Bite",  level = 50, mapID = 1419, zone = "Blasted Lands", faction = "Both", count = 2 },
        },
    },
    [12367] = {
        en = "Pristine Yeti Horn",
        quests = {
            { questId = 977, name = "Are We There, Yeti?", level = 58, mapID = 1452, zone = "Winterspring", faction = "Both", count = 2 },
        },
    },
    [21377] = {
        en = "Deadwood Headdress Feather",
        quests = {
            { questId = 8466, name = "Feathers for Grazle", level = 52, mapID = 1448, zone = "Felwood", faction = "Both", count = 5, repeatable = true },
        },
    },
    [21383] = {
        en = "Winterfall Spirit Beads",
        quests = {
            { questId = 8469, name = "Beads for Salfa", level = 56, mapID = 1452, zone = "Winterspring", faction = "Both", count = 5, repeatable = true },
        },
    },
    [22525] = {
        en = "Crypt Fiend Parts",
        quests = {
            { questId = 9124, name = "Crypt Fiend Parts", level = 58, mapID = 1423, zone = "Eastern Plaguelands", faction = "Both", count = 30, repeatable = true },
        },
    },
    [22526] = {
        en = "Bone Fragments",
        quests = {
            { questId = 9127, name = "Bone Fragments", level = 58, mapID = 1423, zone = "Eastern Plaguelands", faction = "Both", count = 30, repeatable = true },
        },
    },
    [22527] = {
        en = "Core of Elements",
        quests = {
            { questId = 9129, name = "Core of Elements", level = 60, mapID = 1423, zone = "Eastern Plaguelands", faction = "Both", count = 30, repeatable = true },
        },
    },
    [22528] = {
        en = "Dark Iron Scraps",
        quests = {
            { questId = 9132, name = "Dark Iron Scraps", level = 60, mapID = 1423, zone = "Eastern Plaguelands", faction = "Both", count = 30, repeatable = true },
        },
    },
    [22529] = {
        en = "Savage Frond",
        quests = {
            { questId = 9137, name = "Savage Fronds", level = 60, mapID = 1423, zone = "Eastern Plaguelands", faction = "Both", count = 30, repeatable = true },
        },
    },

    -- Darkmoon Faire Grey/White Beast Drops
    [5134] = {
        en = "Small Furry Paw",
        quests = {
            { questId = 7899, name = "Small Furry Paws", level = 1, mapID = 0, zone = "Darkmoon Faire", faction = "Both", count = 5, repeatable = true, event = "Darkmoon" },
        },
    },
    [4582] = {
        en = "Soft Bushy Tail",
        quests = {
            { questId = 7901, name = "Soft Bushy Tails", level = 10, mapID = 0, zone = "Darkmoon Faire", faction = "Both", count = 5, repeatable = true, event = "Darkmoon" },
        },
    },
    [5117] = {
        en = "Vibrant Plume",
        quests = {
            { questId = 7902, name = "Vibrant Plumes", level = 20, mapID = 0, zone = "Darkmoon Faire", faction = "Both", count = 5, repeatable = true, event = "Darkmoon" },
        },
    },
    [11404] = {
        en = "Evil Bat Eye",
        quests = {
            { questId = 7903, name = "Evil Bat Eyes", level = 40, mapID = 0, zone = "Darkmoon Faire", faction = "Both", count = 10, repeatable = true, event = "Darkmoon" },
        },
    },
    [19933] = {
        en = "Glowing Scorpid Blood",
        quests = {
            { questId = 8223, name = "More Glowing Scorpid Blood", level = 40, mapID = 0, zone = "Darkmoon Faire", faction = "Both", count = 10, repeatable = true, event = "Darkmoon" },
        },
    },
}

-------------------------------------------------------------------------------
-- Name-index + Live Quest Log Cache
-------------------------------------------------------------------------------
local keepByNormName = {}
for itemID, entry in pairs(FP.QUEST_KEEP_ITEMS) do
    local norm = NormalizeName(entry.en)
    if norm and not keepByNormName[norm] then
        keepByNormName[norm] = itemID
    end
end

local activeLogByName = {}
local activeLogLastBuild = -1

local function RegisterKeepItemName(itemID, itemName)
    if not IsSafeNum(itemID) or not IsSafeStr(itemName) then return end
    if FP.QUEST_KEEP_ITEMS[itemID] then
        local norm = NormalizeName(itemName)
        if norm and not keepByNormName[norm] then
            keepByNormName[norm] = itemID
        end
    end
end

local function RebuildActiveLogIndex()
    local now = (GetTime and GetTime()) or 0
    if activeLogLastBuild >= 0 and (now - activeLogLastBuild) < 0.8 then
        return activeLogByName
    end
    activeLogLastBuild = now
    for k in pairs(activeLogByName) do
        activeLogByName[k] = nil
    end

    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local okNum, numEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
        if okNum and IsSafeNum(numEntries) then
            for i = 1, numEntries do
                local okInfo, info = pcall(C_QuestLog.GetInfo, i)
                if okInfo and type(info) == "table" and not info.isHeader
                    and IsSafeNum(info.questID) and IsSafeStr(info.title) then
                    local okObjs, objs = pcall(C_QuestLog.GetQuestObjectives, info.questID)
                    if okObjs and type(objs) == "table" then
                        for _, obj in ipairs(objs) do
                            if type(obj) == "table" and not obj.finished and obj.type == "item" and IsSafeStr(obj.text) then
                                local objItem = obj.text:match("^(.-)%s*:%s*%d+%s*/%s*%d+") or obj.text:gsub("%s*%d+%s*/%s*%d+.*$", "")
                                local norm = NormalizeName(objItem)
                                if norm and norm ~= "" then
                                    activeLogByName[norm] = activeLogByName[norm] or {}
                                    table.insert(activeLogByName[norm], {
                                        questId = info.questID,
                                        title   = info.title,
                                        level   = IsSafeNum(info.level) and info.level or (UnitLevel("player") or 1),
                                        count   = (IsSafeNum(obj.numRequired) and obj.numRequired > 0) and obj.numRequired or 1,
                                        have    = IsSafeNum(obj.numFulfilled) and obj.numFulfilled or 0,
                                        zone    = "",
                                        mapID   = 0,
                                        inLog   = true,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return activeLogByName
end

--- Clear cached active-quest-log item mappings after quest state changes.
function FP:InvalidateQuestKeepCache()
    activeLogLastBuild = -1
end

local function ShouldIncludeQuestEntry(q, playerFaction, playerLevel, playerMapID, playerParentMapID, inLog)
    if not q or not IsSafeNum(q.questId) then return false end
    if q.faction and q.faction ~= "Both" and playerFaction and q.faction ~= playerFaction then
        return false
    end
    if not q.repeatable and IsQuestCompleted(q.questId) then
        return false
    end
    if inLog then
        return true
    end

    local qLvl = q.level or 1
    local sameZone = (IsSafeNum(q.mapID) and q.mapID > 0 and (q.mapID == playerMapID or q.mapID == playerParentMapID))
    if sameZone then
        -- Warn for same-zone quests unless far outleveled
        return (qLvl >= playerLevel - 8) or (playerLevel <= 12)
    end

    if q.event == "Darkmoon" then
        return (playerLevel >= qLvl - 2) and (playerLevel <= qLvl + 14)
    end

    -- Upcoming level / adjacent-zone window
    return (qLvl >= playerLevel - 3) and (qLvl <= playerLevel + 14)
end

--- Return structured quest-keep advice for an item if it should not be vendored.
--- @param itemID number|nil
--- @param itemName string|nil
--- @return table|nil
function FP:GetQuestKeepInfo(itemID, itemName)
    local s = NexusKitDB and NexusKitDB.settings
    if s and s.warnKeepQuestLoot == false then return nil end

    local resolvedID = IsSafeNum(itemID) and itemID or nil
    if resolvedID and IsSafeStr(itemName) then
        RegisterKeepItemName(resolvedID, itemName)
    end
    if not resolvedID and IsSafeStr(itemName) then
        resolvedID = keepByNormName[NormalizeName(itemName) or ""]
    end

    local dbEntry = resolvedID and FP.QUEST_KEEP_ITEMS[resolvedID] or nil
    local normName = NormalizeName(itemName) or (dbEntry and NormalizeName(dbEntry.en)) or nil
    local activeList = normName and RebuildActiveLogIndex()[normName] or nil
    if not dbEntry and (not activeList or #activeList == 0) then
        return nil
    end

    local playerFaction = self.GetPlayerFaction and self:GetPlayerFaction() or UnitFactionGroup("player")
    local playerLevel = self.GetPlayerLevel and self:GetPlayerLevel() or (UnitLevel("player") or 1)
    local playerMapID = (C_Map and C_Map.GetBestMapForUnit) and select(2, pcall(C_Map.GetBestMapForUnit, "player")) or nil
    local playerParentMapID = nil
    if IsSafeNum(playerMapID) and C_Map and C_Map.GetMapInfo then
        local okP, mInfo = pcall(C_Map.GetMapInfo, playerMapID)
        if okP and type(mInfo) == "table" and IsSafeNum(mInfo.parentMapID) and mInfo.parentMapID > 0 then
            playerParentMapID = mInfo.parentMapID
        end
    end

    local bagCount = resolvedID and GetItemCountCompat(resolvedID, false) or 0
    local totalCount = resolvedID and GetItemCountCompat(resolvedID, true) or bagCount

    local matches = {}
    local seenQuests = {}
    local playerCont = GetContinentForMap(playerMapID)

    if dbEntry and type(dbEntry.quests) == "table" then
        for _, q in ipairs(dbEntry.quests) do
            local inLog = IsQuestInLog(q.questId)
            if ShouldIncludeQuestEntry(q, playerFaction, playerLevel, playerMapID, playerParentMapID, inLog) then
                seenQuests[q.questId] = true
                local sameZone = IsSafeNum(q.mapID) and q.mapID > 0 and (q.mapID == playerMapID or q.mapID == playerParentMapID)
                local sameCont = (not playerCont) or (not IsSafeNum(q.mapID)) or q.mapID <= 0 or (GetContinentForMap(q.mapID) == playerCont)
                table.insert(matches, {
                    questId    = q.questId,
                    title      = GetLocalizedQuestTitle(q.questId, q.name),
                    level      = q.level or 1,
                    zoneName   = GetLocalizedZoneName(q.mapID, q.zone),
                    mapID      = q.mapID or 0,
                    count      = q.count or 1,
                    inLog      = inLog,
                    sameZone   = sameZone,
                    sameCont   = sameCont,
                    repeatable = q.repeatable == true,
                    event      = q.event,
                })
            end
        end
    end

    if activeList then
        for _, aq in ipairs(activeList) do
            if not seenQuests[aq.questId] then
                seenQuests[aq.questId] = true
                table.insert(matches, {
                    questId  = aq.questId,
                    title    = aq.title,
                    level    = aq.level or playerLevel,
                    zoneName = GetLocalizedZoneName(playerMapID, aq.zone),
                    mapID    = playerMapID or 0,
                    count    = aq.count or 1,
                    inLog    = true,
                    sameZone = true,
                    sameCont = true,
                })
            end
        end
    end

    if #matches == 0 then
        return nil
    end

    table.sort(matches, function(a, b)
        if a.inLog ~= b.inLog then return a.inLog end
        if a.sameZone ~= b.sameZone then return a.sameZone end
        if a.sameCont ~= b.sameCont then return a.sameCont end
        if a.level ~= b.level then return a.level < b.level end
        return (a.questId or 0) < (b.questId or 0)
    end)

    return {
        itemID     = resolvedID,
        bagCount   = bagCount,
        totalCount = totalCount,
        quests     = matches,
        primary    = matches[1],
    }
end

--- Scan carried bags for items needed by active, same-zone, or upcoming quests.
--- @return table[]
function FP:ScanBagsForQuestKeepItems()
    local results = {}
    local seen = {}
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then
        return results
    end

    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local okSlots, n = pcall(C_Container.GetContainerNumSlots, bag)
        if okSlots and IsSafeNum(n) then
            for slot = 1, n do
                local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                if okI and type(info) == "table" and IsSafeNum(info.itemID) then
                    local key = tostring(info.itemID)
                    if not seen[key] then
                        seen[key] = true
                        local keepInfo = self:GetQuestKeepInfo(info.itemID, info.itemName)
                        if keepInfo then
                            table.insert(results, {
                                itemID   = info.itemID,
                                itemName = info.itemName,
                                itemLink = info.hyperlink,
                                keepInfo = keepInfo,
                            })
                        end
                    end
                end
            end
        end
    end
    return results
end
