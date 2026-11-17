-- NexusKit  –  Data/ClassTrainers.lua
-- Class Trainer coordinates, level-based class skill milestones, live trainer
-- & spellbook inspection, and dynamic route step builder for trajectories.
local _, FP = ...

-------------------------------------------------------------------------------
-- Safe API wrappers (Classic / WotLK / Forever / Retail-engine compatible)
-------------------------------------------------------------------------------
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return unpack(res, 2)
end

local function IsAccessible(v)
    return v ~= nil and not (issecretvalue and issecretvalue(v))
end

local function IsSafeNum(v)
    return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

local function GetSafeSpellName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = SafeCall(C_Spell.GetSpellInfo, spellID)
        if type(info) == "table" and IsAccessible(info.name) and info.name ~= "" then
            return info.name
        end
    end
    if GetSpellInfo then
        local name = SafeCall(GetSpellInfo, spellID)
        if IsAccessible(name) and name ~= "" then
            return name
        end
    end
    return nil
end

local function GetSafeSpellSubtext(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellSubtext then
        local sub = SafeCall(C_Spell.GetSpellSubtext, spellID)
        if IsAccessible(sub) and type(sub) == "string" then
            return sub
        end
    end
    if GetSpellSubtext then
        local sub = SafeCall(GetSpellSubtext, spellID)
        if IsAccessible(sub) and type(sub) == "string" then
            return sub
        end
    end
    return nil
end

local function IsSpellIDKnown(spellID)
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

local function ParseRankNumber(subText)
    if not IsAccessible(subText) or type(subText) ~= "string" or subText == "" then
        return nil
    end
    local num = subText:match("(%d+)")
    return num and tonumber(num) or nil
end

-------------------------------------------------------------------------------
-- Class Trainers Database (Classic / TBC / WotLK / WoW Forever mapIDs)
-- Stormwind (1453) uses WotLK 3.x / Forever post-Harbor canvas coordinates.
-------------------------------------------------------------------------------
local function T(mapID, x, y, faction, name, sub, classes, opts)
    local classSet = {}
    for _, c in ipairs(classes) do
        classSet[c] = true
    end
    return {
        mapID     = mapID,
        x         = x,
        y         = y,
        faction   = faction,
        name      = name,
        sub       = sub,
        classSet  = classSet,
        minLevel  = opts and opts.minLevel or nil,
        maxLevel  = opts and opts.maxLevel or nil,
        isCapital = opts and opts.isCapital or false,
    }
end

local CLASS_TRAINERS = {
    -- Alliance Capitals
    -- Stormwind City (1453, post-Harbor canvas)
    T(1453, 80.2, 60.0, "A", "Ilsa Corbin",           "Old Town - Command Center",     { "WARRIOR" },     { isCapital = true }),
    T(1453, 52.6, 45.2, "A", "Katherine the Pure",    "Cathedral Square",              { "PALADIN" },     { isCapital = true }),
    T(1453, 49.6, 45.0, "A", "Brother Joshua",        "Cathedral Square",              { "PRIEST" },      { isCapital = true }),
    T(1453, 67.5, 35.0, "A", "Einris Brightspear",    "Dwarven District",              { "HUNTER" },      { isCapital = true }),
    T(1453, 65.8, 30.8, "A", "Farseer Umbrua",        "Dwarven District",              { "SHAMAN" },      { isCapital = true }),
    T(1453, 77.6, 65.0, "A", "Osborne the Night Man", "Old Town - SI:7",               { "ROGUE" },       { isCapital = true }),
    T(1453, 49.6, 86.5, "A", "Larimaine Purdue",      "Mage Quarter - Wizard Sanctum", { "MAGE" },        { isCapital = true }),
    T(1453, 39.3, 85.4, "A", "Ursula Deline",         "Mage Quarter - Slaughtered Lamb", { "WARLOCK" },   { isCapital = true }),
    T(1453, 36.2, 64.1, "A", "Maldryn",               "The Park",                      { "DRUID" },       { isCapital = true }),

    -- Ironforge (1455)
    T(1455, 70.8, 90.6, "A", "Kelv Sternhammer",      "Military Ward - Hall of Arms",  { "WARRIOR" },     { isCapital = true }),
    T(1455, 23.2,  6.2, "A", "Brandur Ironhammer",    "Mystic Ward",                   { "PALADIN" },     { isCapital = true }),
    T(1455, 25.2,  9.2, "A", "High Priest Rohan",     "Mystic Ward",                   { "PRIEST" },      { isCapital = true }),
    T(1455, 26.2,  7.6, "A", "Bink",                  "Mystic Ward",                   { "MAGE" },        { isCapital = true }),
    T(1455, 70.8, 83.6, "A", "Regnus Thundergranite", "Military Ward - Hall of Arms",  { "HUNTER" },      { isCapital = true }),
    T(1455, 51.5, 15.0, "A", "Fenthwick",             "The Forlorn Cavern",            { "ROGUE" },       { isCapital = true }),
    T(1455, 50.8,  6.6, "A", "Briarthorn",            "The Forlorn Cavern",            { "WARLOCK" },     { isCapital = true }),
    T(1455, 55.2, 30.2, "A", "Farseer Javad",         "The Great Forge",               { "SHAMAN" },      { isCapital = true }),

    -- Darnassus (1457)
    T(1457, 57.4, 46.6, "A", "Sildanair",             "Warrior's Terrace",             { "WARRIOR" },     { isCapital = true }),
    T(1457, 40.3,  8.8, "A", "Jocaste",               "Cenarion Enclave",              { "HUNTER" },      { isCapital = true }),
    T(1457, 36.8, 21.8, "A", "Syurna",                "Cenarion Enclave",              { "ROGUE" },       { isCapital = true }),
    T(1457, 37.9, 82.7, "A", "Jandria",               "Temple of the Moon",            { "PRIEST" },      { isCapital = true }),
    T(1457, 35.2,  8.0, "A", "Mathrengyl Bearwalker", "Cenarion Enclave",              { "DRUID" },       { isCapital = true }),

    -- Moonglade (1450 - Druid hub)
    T(1450, 52.5, 40.5, "B", "Loganaar",              "Nighthaven",                    { "DRUID" }),

    -- Alliance Zones (Starter Lv 1-5 & Town Hubs)
    -- Elwynn Forest (1429)
    T(1429, 50.2, 42.2, "A", "Llane Beshere",         "Northshire Abbey",              { "WARRIOR" },     { maxLevel = 5 }),
    T(1429, 50.4, 42.1, "A", "Brother Sammuel",       "Northshire Abbey",              { "PALADIN" },     { maxLevel = 5 }),
    T(1429, 49.7, 39.4, "A", "Khelden Bremen",        "Northshire Abbey",              { "MAGE" },        { maxLevel = 5 }),
    T(1429, 50.4, 39.9, "A", "Jorik Kerridan",        "Northshire Valley",             { "ROGUE" },       { maxLevel = 5 }),
    T(1429, 49.8, 39.5, "A", "Priestess Anetta",      "Northshire Abbey",              { "PRIEST" },      { maxLevel = 5 }),
    T(1429, 49.9, 42.7, "A", "Drusilla La Salle",     "Northshire Abbey",              { "WARLOCK" },     { maxLevel = 5 }),
    T(1429, 41.1, 65.8, "A", "Lyria Du Lac",          "Goldshire",                     { "WARRIOR" }),
    T(1429, 41.1, 66.0, "A", "Brother Wilhelm",       "Goldshire",                     { "PALADIN" }),
    T(1429, 43.2, 66.2, "A", "Zaldimar Wefhellt",     "Goldshire Inn",                 { "MAGE" }),
    T(1429, 43.9, 65.9, "A", "Keryn Sylvius",         "Goldshire Inn",                 { "ROGUE" }),
    T(1429, 43.3, 65.7, "A", "Priestess Josetta",     "Goldshire Inn",                 { "PRIEST" }),
    T(1429, 44.4, 66.3, "A", "Maximillian Crowe",     "Goldshire Basement",            { "WARLOCK" }),

    -- Dun Morogh (1426)
    T(1426, 28.8, 67.2, "A", "Thran Khorman",         "Anvilmar",                      { "WARRIOR" },     { maxLevel = 5 }),
    T(1426, 28.8, 68.3, "A", "Bromos Grummner",       "Anvilmar",                      { "PALADIN" },     { maxLevel = 5 }),
    T(1426, 29.2, 67.5, "A", "Thorgas Grimson",       "Anvilmar",                      { "HUNTER" },      { maxLevel = 5 }),
    T(1426, 28.4, 67.5, "A", "Solm Hargrin",          "Anvilmar",                      { "ROGUE" },       { maxLevel = 5 }),
    T(1426, 28.6, 66.4, "A", "Branstock Khalder",     "Anvilmar",                      { "PRIEST" },      { maxLevel = 5 }),
    T(1426, 28.7, 66.4, "A", "Marryk Nurribit",       "Anvilmar",                      { "MAGE" },        { maxLevel = 5 }),
    T(1426, 28.7, 66.2, "A", "Sarok",                 "Anvilmar",                      { "WARLOCK" },     { maxLevel = 5 }),
    T(1426, 47.4, 52.6, "A", "Granis Swiftaxe",       "Kharanos",                      { "WARRIOR" }),
    T(1426, 47.6, 52.1, "A", "Azar Stronghammer",     "Kharanos",                      { "PALADIN" }),
    T(1426, 45.8, 53.0, "A", "Grif Wildheart",        "Kharanos",                      { "HUNTER" }),
    T(1426, 47.6, 52.6, "A", "Hogral Bakkan",         "Kharanos Inn",                  { "ROGUE" }),
    T(1426, 47.3, 52.2, "A", "Maxan Anvol",           "Kharanos Inn",                  { "PRIEST" }),
    T(1426, 47.5, 52.1, "A", "Magis Sparkmantle",     "Kharanos Inn",                  { "MAGE" }),
    T(1426, 47.3, 53.5, "A", "Alamar Grimm",          "Kharanos",                      { "WARLOCK" }),

    -- Teldrassil (1438)
    T(1438, 59.3, 41.1, "A", "Alyissia",              "Shadowglen",                    { "WARRIOR" },     { maxLevel = 5 }),
    T(1438, 58.7, 40.4, "A", "Ayanna Everstride",     "Shadowglen",                    { "HUNTER" },      { maxLevel = 5 }),
    T(1438, 59.7, 38.7, "A", "Frahun Shadewhisper",   "Shadowglen",                    { "ROGUE" },       { maxLevel = 5 }),
    T(1438, 59.9, 42.1, "A", "Shanda",                "Shadowglen",                    { "PRIEST" },      { maxLevel = 5 }),
    T(1438, 58.6, 40.3, "A", "Mardant Strongoak",     "Shadowglen",                    { "DRUID" },       { maxLevel = 5 }),
    T(1438, 56.2, 59.2, "A", "Kyra Windblade",        "Dolanaar",                      { "WARRIOR" }),
    T(1438, 56.7, 59.5, "A", "Dazalar",               "Dolanaar",                      { "HUNTER" }),
    T(1438, 56.4, 60.1, "A", "Jannok Breezesong",     "Dolanaar",                      { "ROGUE" }),
    T(1438, 55.6, 56.8, "A", "Laurna Morninglight",   "Dolanaar",                      { "PRIEST" }),
    T(1438, 55.9, 61.6, "A", "Kal",                   "Dolanaar",                      { "DRUID" }),

    -- Horde Capitals
    -- Orgrimmar (1454)
    T(1454, 79.8, 31.4, "H", "Sorek",                 "Valley of Honor - Hall of Brave", { "WARRIOR" },   { isCapital = true }),
    T(1454, 66.1, 18.5, "H", "Ormak Grimshot",        "Valley of Honor - Hunter Hall", { "HUNTER" },      { isCapital = true }),
    T(1454, 43.0, 53.5, "H", "Shenthul",              "Cleft of Shadow",               { "ROGUE" },       { isCapital = true }),
    T(1454, 35.6, 87.6, "H", "Ur'kyo",                "Valley of Spirits",             { "PRIEST" },      { isCapital = true }),
    T(1454, 38.8, 36.4, "H", "Kardris Dreamseeker",   "Valley of Wisdom",              { "SHAMAN" },      { isCapital = true }),
    T(1454, 38.7, 85.4, "H", "Deino",                 "Valley of Spirits",             { "MAGE" },        { isCapital = true }),
    T(1454, 48.0, 45.9, "H", "Grol'dar",              "Cleft of Shadow",               { "WARLOCK" },     { isCapital = true }),
    T(1454, 32.4, 35.8, "H", "Master Pyreanor",       "Valley of Wisdom",              { "PALADIN" },     { isCapital = true }),

    -- Thunder Bluff (1456)
    T(1456, 57.6, 87.2, "H", "Torm Ragetotem",        "Hunter Rise",                   { "WARRIOR" },     { isCapital = true }),
    T(1456, 58.0, 88.2, "H", "Kary Thunderhorn",      "Hunter Rise",                   { "HUNTER" },      { isCapital = true }),
    T(1456, 22.8, 19.6, "H", "Beram Skychaser",       "Spirit Rise",                   { "SHAMAN" },      { isCapital = true }),
    T(1456, 76.5, 27.2, "H", "Turak Runetotem",       "Elder Rise",                    { "DRUID" },       { isCapital = true }),

    -- Undercity (1458)
    T(1458, 47.3, 17.2, "H", "Baltus Fowler",         "War Quarter",                   { "WARRIOR" },     { isCapital = true }),
    T(1458, 83.9, 72.1, "H", "Carolyn Ward",          "Rogues' Quarter",               { "ROGUE" },       { isCapital = true }),
    T(1458, 49.1, 17.2, "H", "Aelthalyste",           "War Quarter",                   { "PRIEST" },      { isCapital = true }),
    T(1458, 85.1, 10.0, "H", "Kaelystia Hatebringer", "Magic Quarter",                 { "MAGE" },        { isCapital = true }),
    T(1458, 86.0, 15.6, "H", "Kaal Soulreaper",       "Magic Quarter",                 { "WARLOCK" },     { isCapital = true }),
    T(1458, 57.8, 90.4, "H", "Cyssa Dawnrose",        "Royal Quarter",                 { "PALADIN" },     { isCapital = true }),

    -- Horde Zones (Starter Lv 1-5 & Town Hubs)
    -- Durotar (1411)
    T(1411, 42.9, 69.4, "H", "Frang",                 "Valley of Trials",              { "WARRIOR" },     { maxLevel = 5 }),
    T(1411, 42.8, 69.3, "H", "Jen'shan",              "Valley of Trials",              { "HUNTER" },      { maxLevel = 5 }),
    T(1411, 41.3, 68.0, "H", "Rwag",                  "Valley of Trials",              { "ROGUE" },       { maxLevel = 5 }),
    T(1411, 42.4, 69.0, "H", "Shikrik",               "Valley of Trials",              { "SHAMAN" },      { maxLevel = 5 }),
    T(1411, 42.5, 69.0, "H", "Mai'ah",                "Valley of Trials",              { "MAGE" },        { maxLevel = 5 }),
    T(1411, 40.6, 68.5, "H", "Nartok",                "Valley of Trials",              { "WARLOCK" },     { maxLevel = 5 }),
    T(1411, 54.2, 42.5, "H", "Tarshaw Jaggedscar",    "Razor Hill",                    { "WARRIOR" }),
    T(1411, 51.9, 43.5, "H", "Thotar",                "Razor Hill",                    { "HUNTER" }),
    T(1411, 52.0, 43.7, "H", "Kaplak",                "Razor Hill",                    { "ROGUE" }),
    T(1411, 54.4, 42.4, "H", "Swart",                 "Razor Hill",                    { "SHAMAN" }),
    T(1411, 54.4, 41.2, "H", "Dhugru Gorelust",       "Razor Hill",                    { "WARLOCK" }),
    T(1411, 56.3, 75.1, "H", "Un'Thuwa",              "Sen'jin Village",               { "MAGE" }),
    T(1411, 54.3, 72.9, "H", "Tai'jin",               "Sen'jin Village",               { "PRIEST" }),

    -- Mulgore (1412)
    T(1412, 44.0, 76.1, "H", "Harutt Thunderhorn",    "Camp Narache",                  { "WARRIOR" },     { maxLevel = 5 }),
    T(1412, 44.3, 75.7, "H", "Lanka Farshot",         "Camp Narache",                  { "HUNTER" },      { maxLevel = 5 }),
    T(1412, 45.0, 76.0, "H", "Meela Dawnstrider",     "Camp Narache",                  { "SHAMAN" },      { maxLevel = 5 }),
    T(1412, 45.1, 76.0, "H", "Gart Mistrunner",       "Camp Narache",                  { "DRUID" },       { maxLevel = 5 }),
    T(1412, 49.5, 60.6, "H", "Krang Stonehoof",       "Bloodhoof Village",             { "WARRIOR" }),
    T(1412, 47.8, 55.7, "H", "Yaw Sharpmane",         "Bloodhoof Village",             { "HUNTER" }),
    T(1412, 48.4, 59.2, "H", "Narm Skychaser",        "Bloodhoof Village",             { "SHAMAN" }),
    T(1412, 48.5, 59.6, "H", "Gennia Runetotem",      "Bloodhoof Village",             { "DRUID" }),

    -- Tirisfal Glades (1420)
    T(1420, 32.7, 65.6, "H", "Dannal Stern",          "Deathknell",                    { "WARRIOR" },     { maxLevel = 5 }),
    T(1420, 32.5, 65.7, "H", "David Trias",           "Deathknell",                    { "ROGUE" },       { maxLevel = 5 }),
    T(1420, 31.1, 66.0, "H", "Dark Cleric Duesten",   "Deathknell",                    { "PRIEST" },      { maxLevel = 5 }),
    T(1420, 30.9, 66.1, "H", "Isabella",              "Deathknell",                    { "MAGE" },        { maxLevel = 5 }),
    T(1420, 30.9, 66.3, "H", "Maximillion",           "Deathknell",                    { "WARLOCK" },     { maxLevel = 5 }),
    T(1420, 61.9, 52.5, "H", "Austil de Mon",         "Brill",                         { "WARRIOR" }),
    T(1420, 61.8, 52.0, "H", "Marion Call",           "Brill",                         { "ROGUE" }),
    T(1420, 61.6, 52.2, "H", "Dark Cleric Beryl",     "Brill",                         { "PRIEST" }),
    T(1420, 61.9, 52.5, "H", "Cain Firesong",         "Brill",                         { "MAGE" }),
    T(1420, 61.6, 52.6, "H", "Rupert Boch",           "Brill",                         { "WARLOCK" }),

    -- Death Knight Acherus Trainer
    T(23,   83.2, 49.4, "B", "Amal'thazad",           "Acherus: The Ebon Hold",        { "DEATHKNIGHT" }, { minLevel = 55 }),
    T(1423, 83.2, 49.4, "B", "Amal'thazad",           "Acherus / Eastern Plaguelands", { "DEATHKNIGHT" }, { minLevel = 55, isCapital = true }),
}

-------------------------------------------------------------------------------
-- Curated Trainable Class Skills & Classic Rank Chains (zero talents/quests)
-- core  = { level = reqLvl, ids = { rank1, rank2, ... } }
-- ranks = { baseID = rank1ID, levels = { {lvl, id, rankNum}, ... } }
--         Note: `ranks` entries are checked ONLY when the character's
--         SpellBook shows Classic/TBC/WotLK numbered spell ranks!
-------------------------------------------------------------------------------
local function Core(lvl, ...)
    return { level = lvl, ids = { ... } }
end

local function Ranks(baseID, pairsList)
    local tiers = {}
    for _, item in ipairs(pairsList) do
        tiers[#tiers + 1] = { level = item[1], id = item[2], rank = item[3] }
    end
    return { baseID = baseID, tiers = tiers }
end

local CLASS_SKILL_DATA = {
    WARRIOR = {
        core = {
            Core(4,  100),                          -- Charge
            Core(4,  772),                          -- Rend
            Core(6,  6343),                         -- Thunder Clap
            Core(8,  1715),                         -- Hamstring
            Core(10, 355),                          -- Taunt
            Core(10, 7386),                         -- Sunder Armor
            Core(12, 7384),                         -- Overpower
            Core(14, 1160),                         -- Demoralizing Shout
            Core(14, 6572),                         -- Revenge
            Core(16, 694),                          -- Mocking Blow
            Core(16, 2565),                         -- Shield Block
            Core(18, 676),                          -- Disarm
            Core(20, 845),                          -- Cleave
            Core(20, 20230),                        -- Retaliation
            Core(22, 5246),                         -- Intimidating Shout
            Core(24, 5308),                         -- Execute
            Core(28, 871),                          -- Shield Wall
            Core(30, 1464),                         -- Slam
            Core(32, 18499),                        -- Berserker Rage
            Core(36, 1680),                         -- Whirlwind
            Core(38, 6552),                         -- Pummel
            Core(50, 1719),                         -- Recklessness
        },
        ranks = {
            Ranks(78,   { {8, 284, 2}, {16, 285, 3}, {24, 1608, 4}, {32, 11564, 5}, {40, 11565, 6}, {48, 11566, 7}, {56, 11567, 8} }), -- Heroic Strike
            Ranks(6673, { {12, 5242, 2}, {22, 6192, 3}, {32, 11549, 4}, {42, 11550, 5}, {52, 11551, 6} }),                              -- Battle Shout
            Ranks(772,  { {10, 6546, 2}, {20, 6547, 3}, {30, 6548, 4}, {40, 11572, 5}, {50, 11573, 6}, {60, 11574, 7} }),               -- Rend
            Ranks(5308, { {32, 20658, 2}, {40, 20660, 3}, {48, 20661, 4}, {56, 20662, 5} }),                                            -- Execute
        },
    },

    PALADIN = {
        core = {
            Core(4,  19740),                        -- Blessing of Might
            Core(4,  20271, 53408),                 -- Judgement / Judgement of Light
            Core(6,  498),                          -- Divine Protection
            Core(8,  853),                          -- Hammer of Justice
            Core(8,  1152),                         -- Purify
            Core(10, 633),                          -- Lay on Hands
            Core(10, 1022),                         -- Blessing / Hand of Protection
            Core(14, 19742),                        -- Blessing of Wisdom
            Core(16, 7294),                         -- Retribution Aura
            Core(16, 25780),                        -- Righteous Fury
            Core(18, 1044),                         -- Blessing / Hand of Freedom
            Core(20, 879),                          -- Exorcism
            Core(20, 19750),                        -- Flash of Light
            Core(22, 19746),                        -- Concentration Aura
            Core(22, 20164),                        -- Seal of Justice
            Core(24, 10326, 2878),                  -- Turn Evil / Turn Undead
            Core(28, 19876),                        -- Shadow Resistance Aura
            Core(30, 20165),                        -- Seal of Light
            Core(32, 19888),                        -- Frost Resistance Aura
            Core(34, 642),                          -- Divine Shield
            Core(36, 19891),                        -- Fire Resistance Aura
            Core(38, 20166),                        -- Seal of Wisdom
            Core(42, 4987),                         -- Cleanse
            Core(44, 24275),                        -- Hammer of Wrath
            Core(46, 6940),                         -- Blessing / Hand of Sacrifice
            Core(50, 2812),                         -- Holy Wrath
        },
        ranks = {
            Ranks(635,   { {6, 639, 2}, {14, 647, 3}, {22, 1026, 4}, {30, 1042, 5}, {38, 3472, 6}, {46, 10328, 7}, {54, 10329, 8}, {60, 25292, 9} }), -- Holy Light
            Ranks(19740, { {12, 19834, 2}, {22, 19835, 3}, {32, 19836, 4}, {42, 19837, 5}, {52, 19838, 6} }),                                          -- Blessing of Might
            Ranks(465,   { {10, 10290, 2}, {20, 643, 3}, {30, 10291, 4}, {40, 1032, 5}, {50, 10292, 6}, {60, 10293, 7} }),                             -- Devotion Aura
            Ranks(19750, { {26, 19939, 2}, {34, 19940, 3}, {42, 19941, 4}, {50, 19942, 5}, {58, 19943, 6} }),                                          -- Flash of Light
            Ranks(19742, { {24, 19850, 2}, {34, 19852, 3}, {44, 19853, 4}, {54, 19854, 5} }),                                                          -- Blessing of Wisdom
        },
    },

    HUNTER = {
        core = {
            Core(4,  1978),                         -- Serpent Sting
            Core(4,  13163),                        -- Aspect of the Monkey
            Core(6,  3044),                         -- Arcane Shot
            Core(6,  1130),                         -- Hunter's Mark
            Core(8,  5116),                         -- Concussive Shot
            Core(10, 13165),                        -- Aspect of the Hawk
            Core(12, 2974),                         -- Wing Clip
            Core(14, 1513),                         -- Scare Beast
            Core(16, 1495),                         -- Mongoose Bite
            Core(16, 13795),                        -- Immolation Trap
            Core(18, 2643),                         -- Multi-Shot
            Core(20, 5118),                         -- Aspect of the Cheetah
            Core(20, 1499),                         -- Freezing Trap
            Core(24, 1543),                         -- Flare (24/32)
            Core(28, 13809),                        -- Frost Trap
            Core(30, 5384),                         -- Feign Death
            Core(34, 13813),                        -- Explosive Trap
            Core(36, 3034),                         -- Viper Sting
            Core(40, 1510),                         -- Volley
        },
        ranks = {
            Ranks(1978,  { {10, 13549, 2}, {18, 13550, 3}, {26, 13551, 4}, {34, 13552, 5}, {42, 13553, 6}, {50, 13554, 7}, {58, 13555, 8} }), -- Serpent Sting
            Ranks(3044,  { {12, 14281, 2}, {20, 14282, 3}, {28, 14283, 4}, {36, 14284, 5}, {44, 14285, 6}, {52, 14286, 7}, {60, 14287, 8} }), -- Arcane Shot
            Ranks(13165, { {18, 14318, 2}, {28, 14319, 3}, {38, 14320, 4}, {48, 14321, 5}, {58, 14322, 6} }),                                 -- Aspect of the Hawk
        },
    },

    ROGUE = {
        core = {
            Core(4,  53),                           -- Backstab
            Core(6,  1776),                         -- Gouge
            Core(8,  5277),                         -- Evasion
            Core(10, 6770),                         -- Sap
            Core(10, 5171),                         -- Slice and Dice
            Core(12, 1766),                         -- Kick
            Core(14, 8647),                         -- Expose Armor
            Core(14, 703),                          -- Garrote
            Core(16, 2983),                         -- Sprint
            Core(16, 1966),                         -- Feint
            Core(18, 8676),                         -- Ambush
            Core(20, 1943),                         -- Rupture
            Core(22, 1856),                         -- Vanish
            Core(24, 1725),                         -- Distract
            Core(26, 1833),                         -- Cheap Shot
            Core(30, 408),                          -- Kidney Shot
            Core(34, 2094),                         -- Blind
        },
        ranks = {
            Ranks(1752, { {6, 1757, 2}, {14, 1758, 3}, {22, 1759, 4}, {30, 1760, 5}, {38, 8621, 6}, {46, 11293, 7}, {54, 11294, 8} }), -- Sinister Strike
            Ranks(2098, { {8, 6760, 2}, {16, 6761, 3}, {24, 6762, 4}, {32, 8623, 5}, {40, 8624, 6}, {48, 11299, 7}, {56, 11300, 8} }), -- Eviscerate
            Ranks(53,   { {12, 2589, 2}, {20, 2590, 3}, {28, 2591, 4}, {36, 8721, 5}, {44, 11279, 6}, {52, 11280, 7}, {60, 11281, 8} }), -- Backstab
        },
    },

    PRIEST = {
        core = {
            Core(4,  589),                          -- Shadow Word: Pain
            Core(6,  17),                           -- Power Word: Shield
            Core(8,  139),                          -- Renew
            Core(8,  586),                          -- Fade
            Core(10, 8092),                         -- Mind Blast
            Core(10, 2006),                         -- Resurrection
            Core(12, 588),                          -- Inner Fire
            Core(14, 8122),                         -- Psychic Scream
            Core(14, 528),                          -- Cure Disease
            Core(18, 527),                          -- Dispel Magic
            Core(20, 2061),                         -- Flash Heal
            Core(20, 14914),                        -- Holy Fire
            Core(30, 605),                          -- Mind Control
            Core(30, 596),                          -- Prayer of Healing
            Core(34, 1706),                         -- Levitate
            Core(40, 2060),                         -- Greater Heal
        },
        ranks = {
            Ranks(585,  { {6, 591, 2}, {14, 598, 3}, {22, 984, 4}, {30, 1004, 5}, {38, 6060, 6}, {46, 10933, 7}, {54, 10934, 8} }),   -- Smite
            Ranks(589,  { {10, 594, 2}, {18, 970, 3}, {26, 992, 4}, {34, 2767, 5}, {42, 10892, 6}, {50, 10893, 7}, {58, 10894, 8} }), -- Shadow Word: Pain
            Ranks(139,  { {14, 6074, 2}, {20, 6075, 3}, {26, 6076, 4}, {32, 6077, 5}, {38, 6078, 6}, {44, 10927, 7}, {50, 10928, 8}, {56, 10929, 9} }), -- Renew
            Ranks(1243, { {12, 1244, 2}, {24, 1245, 3}, {36, 2791, 4}, {48, 10937, 5}, {60, 10938, 6} }),                              -- Power Word: Fortitude
        },
    },

    SHAMAN = {
        core = {
            Core(4,  8042),                         -- Earth Shock
            Core(8,  324),                          -- Lightning Shield
            Core(10, 8024),                         -- Flametongue Weapon
            Core(10, 8050),                         -- Flame Shock
            Core(12, 2008),                         -- Ancestral Spirit
            Core(16, 526),                          -- Cure Poison / Cure Toxins
            Core(20, 8004),                         -- Lesser Healing Wave
            Core(20, 2645),                         -- Ghost Wolf
            Core(20, 8056),                         -- Frost Shock
            Core(22, 546),                          -- Water Walking
            Core(24, 2870, 51886),                  -- Cure Disease / Cleanse Spirit
            Core(26, 8033),                         -- Frostbrand Weapon
            Core(30, 8232),                         -- Windfury Weapon
            Core(30, 556),                          -- Astral Recall
            Core(32, 421),                          -- Chain Lightning
            Core(40, 1064),                         -- Chain Heal
        },
        ranks = {
            Ranks(403,  { {8, 529, 2}, {14, 548, 3}, {20, 915, 4}, {26, 943, 5}, {32, 6041, 6}, {38, 10391, 7}, {44, 10392, 8}, {50, 15207, 9}, {56, 15208, 10} }), -- Lightning Bolt
            Ranks(331,  { {6, 332, 2}, {12, 547, 3}, {18, 913, 4}, {24, 939, 5}, {32, 959, 6}, {40, 8005, 7}, {48, 10395, 8}, {56, 10396, 9} }),                     -- Healing Wave
            Ranks(8042, { {8, 8044, 2}, {14, 8045, 3}, {24, 8046, 4}, {36, 10412, 5}, {48, 10413, 6}, {60, 10414, 7} }),                                             -- Earth Shock
        },
    },

    MAGE = {
        core = {
            Core(4,  116),                          -- Frostbolt
            Core(4,  5504),                         -- Conjure Water
            Core(6,  2136),                         -- Fire Blast
            Core(8,  118),                          -- Polymorph
            Core(10, 122),                          -- Frost Nova
            Core(12, 130),                          -- Slow Fall
            Core(14, 1449),                         -- Arcane Explosion
            Core(18, 475),                          -- Remove Curse / Remove Lesser Curse
            Core(20, 1953),                         -- Blink
            Core(20, 1463),                         -- Mana Shield
            Core(20, 2120),                         -- Flamestrike
            Core(20, 12051),                        -- Evocation
            Core(22, 2948),                         -- Scorch
            Core(24, 2139),                         -- Counterspell
            Core(26, 120),                          -- Cone of Cold
            Core(30, 7302),                         -- Ice Armor
            Core(34, 6117),                         -- Mage Armor
        },
        ranks = {
            Ranks(133,  { {6, 143, 2}, {12, 145, 3}, {18, 3140, 4}, {24, 8400, 5}, {30, 8401, 6}, {36, 8402, 7}, {42, 10148, 8}, {48, 10149, 9}, {54, 10150, 10}, {60, 10151, 11} }), -- Fireball
            Ranks(116,  { {8, 205, 2}, {14, 837, 3}, {20, 7322, 4}, {26, 8406, 5}, {32, 8407, 6}, {38, 8408, 7}, {44, 10179, 8}, {50, 10180, 9}, {56, 10181, 10} }),                   -- Frostbolt
            Ranks(1459, { {14, 1460, 2}, {28, 1461, 3}, {42, 10156, 4}, {56, 10157, 5} }),                                                                                              -- Arcane Intellect
        },
    },

    WARLOCK = {
        core = {
            Core(4,  172),                          -- Corruption
            Core(4,  702),                          -- Curse of Weakness
            Core(6,  1454),                         -- Life Tap
            Core(8,  5782),                         -- Fear
            Core(8,  980),                          -- Curse of Agony
            Core(10, 6201),                         -- Create Healthstone
            Core(10, 1120),                         -- Drain Soul
            Core(12, 755),                          -- Health Funnel
            Core(14, 689),                          -- Drain Life
            Core(16, 5697),                         -- Unending Breath
            Core(18, 5676),                         -- Searing Pain
            Core(20, 706),                          -- Demon Armor
            Core(20, 5740),                         -- Rain of Fire
            Core(24, 5138),                         -- Drain Mana
            Core(30, 1098),                         -- Enslave Demon
            Core(48, 6353),                         -- Soul Fire
        },
        ranks = {
            Ranks(686, { {6, 695, 2}, {12, 705, 3}, {20, 1088, 4}, {28, 1106, 5}, {36, 7641, 6}, {44, 11659, 7}, {52, 11660, 8}, {60, 11661, 9} }), -- Shadow Bolt
            Ranks(172, { {14, 6222, 2}, {24, 6223, 3}, {34, 7648, 4}, {44, 11671, 5}, {54, 11672, 6} }),                                           -- Corruption
            Ranks(348, { {10, 707, 2}, {20, 1094, 3}, {30, 2941, 4}, {40, 11665, 5}, {50, 11667, 6}, {60, 11668, 7} }),                            -- Immolate
        },
    },

    DRUID = {
        core = {
            Core(4,  8921),                         -- Moonfire
            Core(6,  467),                          -- Thorns
            Core(8,  339),                          -- Entangling Roots
            Core(14, 5211),                         -- Bash
            Core(14, 8946),                         -- Cure Poison
            Core(16, 779),                          -- Swipe
            Core(18, 2637),                         -- Hibernate
            Core(20, 768),                          -- Cat Form
            Core(20, 1082),                         -- Claw
            Core(22, 5221),                         -- Shred
            Core(24, 1822),                         -- Rake
            Core(26, 770),                          -- Faerie Fire
            Core(30, 783),                          -- Travel Form
            Core(32, 22568),                        -- Ferocious Bite
            Core(36, 22842),                        -- Frenzied Regeneration
            Core(40, 29166),                        -- Innervate
        },
        ranks = {
            Ranks(5176, { {6, 5177, 2}, {14, 5178, 3}, {22, 5179, 4}, {30, 5180, 5}, {38, 6780, 6}, {46, 8905, 7}, {54, 9912, 8} }),               -- Wrath
            Ranks(5185, { {8, 5186, 2}, {14, 5187, 3}, {20, 5188, 4}, {26, 5189, 5}, {32, 6778, 6}, {38, 8903, 7}, {44, 9758, 8}, {50, 9888, 9} }), -- Healing Touch
            Ranks(1126, { {10, 5232, 2}, {20, 6756, 3}, {30, 5234, 4}, {40, 8907, 5}, {50, 9884, 6}, {60, 9885, 7} }),                              -- Mark of the Wild
            Ranks(8921, { {10, 8924, 2}, {16, 8925, 3}, {22, 8926, 4}, {28, 8927, 5}, {34, 8928, 6}, {40, 8929, 7}, {46, 9833, 8}, {52, 9834, 9} }), -- Moonfire
        },
    },

    DEATHKNIGHT = {
        core = {
            Core(56, 46584),                        -- Raise Dead
            Core(57, 47528),                        -- Mind Freeze
            Core(65, 57330),                        -- Horn of Winter
            Core(68, 48707),                        -- Anti-Magic Shell
        },
        ranks = {},
    },
}

-------------------------------------------------------------------------------
-- SpellBook Snapshot (auto-detects learned IDs, localized names, and ranks)
-------------------------------------------------------------------------------
local spellCache = {
    valid           = false,
    knownIDs        = {},
    highestRankName = {},
    hasRankedSpells = false,
}

function FP:InvalidateTrainerSpellbookCache()
    spellCache.valid = false
end

local function RecordSpellInCache(sid, sName, sSub)
    if IsSafeNum(sid) and sid > 0 then
        spellCache.knownIDs[sid] = true
    end
    if IsAccessible(sName) and type(sName) == "string" and sName ~= "" then
        local key = string.lower(sName)
        local rankNum = ParseRankNumber(sSub)
        if not rankNum and sid then
            rankNum = ParseRankNumber(GetSafeSpellSubtext(sid))
        end
        if rankNum and rankNum >= 1 then
            spellCache.hasRankedSpells = true
            local prev = spellCache.highestRankName[key] or 0
            if rankNum > prev then
                spellCache.highestRankName[key] = rankNum
            end
        elseif spellCache.highestRankName[key] == nil then
            spellCache.highestRankName[key] = 0
        end
    end
end

local function RebuildTrainerSpellbookCache()
    for k in pairs(spellCache.knownIDs) do spellCache.knownIDs[k] = nil end
    for k in pairs(spellCache.highestRankName) do spellCache.highestRankName[k] = nil end
    spellCache.hasRankedSpells = false

    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        local numLines = SafeCall(C_SpellBook.GetNumSpellBookSkillLines) or 0
        for l = 1, numLines do
            local lineInfo = SafeCall(C_SpellBook.GetSpellBookSkillLineInfo, l)
            if type(lineInfo) == "table" and not lineInfo.shouldHide and (not lineInfo.offSpecID or lineInfo.offSpecID == 0) then
                local offset = lineInfo.itemIndexOffset or 0
                local numSlots = lineInfo.numSpellBookItems or 0
                for s = offset + 1, offset + numSlots do
                    local info = SafeCall(C_SpellBook.GetSpellBookItemInfo, s, bank)
                    if type(info) == "table" and not info.isOffSpec then
                        RecordSpellInCache(info.spellID, info.name, info.subName)
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
                    local sid = nil
                    if GetSpellBookItemInfo then
                        local _, maybeID = SafeCall(GetSpellBookItemInfo, s, bookType)
                        sid = maybeID
                    end
                    RecordSpellInCache(sid, sName, sSub)
                end
            end
        end
    end

    spellCache.valid = true
end

local function EnsureSpellCache()
    if not spellCache.valid then
        RebuildTrainerSpellbookCache()
    end
end

local function IsEntryCoreLearned(entry, clearedLevels)
    if clearedLevels and entry.level <= clearedLevels then
        return true
    end
    for _, sid in ipairs(entry.ids) do
        if spellCache.knownIDs[sid] or IsSpellIDKnown(sid) then
            return true
        end
    end
    local primaryName = GetSafeSpellName(entry.ids[1])
    if primaryName then
        local known = spellCache.highestRankName[string.lower(primaryName)]
        if known ~= nil then
            return true
        end
    end
    return false
end

local function IsRankTierLearned(tiers, tierIdx, baseNameLower, clearedLevels)
    local tier = tiers[tierIdx]
    if clearedLevels and tier.level <= clearedLevels then
        return true
    end
    for j = tierIdx, #tiers do
        local sid = tiers[j].id
        if spellCache.knownIDs[sid] or IsSpellIDKnown(sid) then
            return true
        end
    end
    if baseNameLower then
        local knownRank = spellCache.highestRankName[baseNameLower]
        if knownRank and knownRank >= tier.rank then
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Live Class Trainer Scanner
-------------------------------------------------------------------------------
local function ReadTrainerServiceRow(idx)
    if not GetTrainerServiceInfo then return nil, nil, nil end
    local a, b, c = SafeCall(GetTrainerServiceInfo, idx)
    if type(a) == "table" then
        return a.name, a.subText or a.rank, a.category
    end
    return a, b, c
end

local function LooksLikeNonClassTrainer(numServices)
    if IsTradeskillTrainer then
        local res = SafeCall(IsTradeskillTrainer)
        if IsAccessible(res) then
            return res == true
        end
    end
    -- Fallback if API missing: inspect first few headers/names for Profession or Riding keywords
    local checkCount = math.min(numServices, 8)
    for i = 1, checkCount do
        local svcName, _, cat = ReadTrainerServiceRow(i)
        if IsAccessible(svcName) and type(svcName) == "string" then
            local low = svcName:lower()
            if cat == "header" and (low:find("apprentice") or low:find("journeyman") or low:find("riding")) then
                return true
            end
        end
    end
    return false
end

function FP:ScanOpenClassTrainer()
    if not GetNumTrainerServices then return false end
    local numServices = SafeCall(GetNumTrainerServices) or 0
    if not IsSafeNum(numServices) or numServices <= 0 then
        return false
    end
    if LooksLikeNonClassTrainer(numServices) then
        return false
    end

    local playerLevel = self:GetPlayerLevel()
    local playerMoney = (GetMoney and SafeCall(GetMoney)) or 0
    if not IsSafeNum(playerMoney) then playerMoney = 0 end

    local totalAvail = 0
    local affordableAvail = 0
    local cheapestCost = nil
    local nextReqLevel = nil
    local availNames = {}

    for i = 1, numServices do
        local svcName, subText, cat = ReadTrainerServiceRow(i)
        if cat == "available" or cat == "unavailable" then
            local reqLvl = GetTrainerServiceLevelReq and SafeCall(GetTrainerServiceLevelReq, i)
            if cat == "available" and (not IsSafeNum(reqLvl) or reqLvl <= playerLevel) then
                totalAvail = totalAvail + 1
                local cost = GetTrainerServiceCost and SafeCall(GetTrainerServiceCost, i)
                if not IsSafeNum(cost) then cost = 0 end
                if cost <= playerMoney then
                    affordableAvail = affordableAvail + 1
                end
                if not cheapestCost or cost < cheapestCost then
                    cheapestCost = cost
                end
                if IsAccessible(svcName) and type(svcName) == "string" and svcName ~= "" then
                    local label = svcName
                    if IsAccessible(subText) and type(subText) == "string" and subText ~= "" then
                        label = svcName .. " (" .. subText .. ")"
                    end
                    availNames[#availNames + 1] = label
                end
            elseif cat == "unavailable" and IsSafeNum(reqLvl) and reqLvl > playerLevel then
                if not nextReqLevel or reqLvl < nextReqLevel then
                    nextReqLevel = reqLvl
                end
            end
        end
    end

    if NexusKitCharDB then
        local prevCleared = NexusKitCharDB.trainerScan and NexusKitCharDB.trainerScan.clearedLevels or 0
        NexusKitCharDB.trainerScan = {
            level           = playerLevel,
            totalAvail      = totalAvail,
            affordableAvail = affordableAvail,
            cheapestCost    = cheapestCost or 0,
            availNames      = availNames,
            nextReqLevel    = nextReqLevel,
            clearedLevels   = (totalAvail == 0) and math.max(prevCleared, playerLevel) or prevCleared,
            scannedAt       = time and time() or 0,
        }
        if totalAvail == 0 then
            NexusKitCharDB.skippedTrainKey = nil
        end
    end

    spellCache.valid = false
    return true
end

-------------------------------------------------------------------------------
-- Trainer Need & Nearest Class Trainer Resolution
-------------------------------------------------------------------------------
function FP:GetClassTrainerNeed(ignoreSkip)
    local settings = NexusKitDB and NexusKitDB.settings
    if settings and settings.syncSuggestTrainers == false then
        return nil
    end

    local playerLevel = self:GetPlayerLevel()
    if not IsSafeNum(playerLevel) or playerLevel < 2 then
        return nil
    end

    local classTag = self:GetPlayerClass()
    local scan = NexusKitCharDB and NexusKitCharDB.trainerScan
    local clearedLevels = (scan and IsSafeNum(scan.clearedLevels)) and scan.clearedLevels or 0

    local missingNames = {}
    local minMissingLevel = nil

    -- 1. If we scanned a live Class Trainer at the current level, use its ground truth
    if scan and scan.level == playerLevel then
        if (scan.totalAvail or 0) == 0 then
            return nil
        end
        local money = (GetMoney and SafeCall(GetMoney)) or 0
        if not IsSafeNum(money) then money = 0 end
        if (scan.affordableAvail or 0) == 0 and (scan.cheapestCost or 0) > money then
            return nil
        end
        for _, label in ipairs(scan.availNames or {}) do
            missingNames[#missingNames + 1] = label
        end
        minMissingLevel = playerLevel
    -- 2. If live trainer cleared a lower level and reported next unavailable reqLevel, respect it
    elseif scan and (scan.totalAvail or 0) == 0 and IsSafeNum(scan.nextReqLevel) and playerLevel < scan.nextReqLevel then
        return nil
    -- 3. Otherwise inspect SpellBook against curated class milestones & classic ranks
    else
        local data = classTag and CLASS_SKILL_DATA[classTag]
        if not data then return nil end

        EnsureSpellCache()
        local seenLabels = {}

        for _, entry in ipairs(data.core or {}) do
            if entry.level <= playerLevel and not IsEntryCoreLearned(entry, clearedLevels) then
                local spellName = GetSafeSpellName(entry.ids[1])
                if spellName and not seenLabels[spellName] then
                    seenLabels[spellName] = true
                    missingNames[#missingNames + 1] = spellName
                    if not minMissingLevel or entry.level < minMissingLevel then
                        minMissingLevel = entry.level
                    end
                end
            end
        end

        -- Only evaluate Rank upgrades if this character's SpellBook shows numbered Classic ranks
        if spellCache.hasRankedSpells then
            local rankFormat = (self.L and self.L["SYNC_TRAIN_RANK_FMT"]) or "%s (R%d)"
            for _, chain in ipairs(data.ranks or {}) do
                local baseName = GetSafeSpellName(chain.baseID)
                local baseLower = baseName and string.lower(baseName) or nil
                -- Pick highest unlearned rank tier <= playerLevel per spell chain
                local bestUnlearnedTier = nil
                for i, tier in ipairs(chain.tiers) do
                    if tier.level <= playerLevel and not IsRankTierLearned(chain.tiers, i, baseLower, clearedLevels) then
                        bestUnlearnedTier = tier
                    end
                end
                if bestUnlearnedTier and baseName then
                    local label = string.format(rankFormat, baseName, bestUnlearnedTier.rank)
                    if not seenLabels[label] then
                        seenLabels[label] = true
                        missingNames[#missingNames + 1] = label
                        if not minMissingLevel or bestUnlearnedTier.level < minMissingLevel then
                            minMissingLevel = bestUnlearnedTier.level
                        end
                    end
                end
            end
        end
    end

    if #missingNames == 0 then
        return nil
    end

    local milestoneKey = string.format("%s:%d:%d", tostring(classTag or "?"), playerLevel, #missingNames)
    if not ignoreSkip and NexusKitCharDB and NexusKitCharDB.skippedTrainKey == milestoneKey then
        return nil
    end

    return {
        level           = playerLevel,
        minMissingLevel = minMissingLevel or playerLevel,
        count           = #missingNames,
        skills          = missingNames,
        milestoneKey    = milestoneKey,
    }
end

function FP:GetBestClassTrainer(refMapID, refX, refY, metaCache)
    local classTag = self:GetPlayerClass()
    local factionTag = UnitFactionGroup and UnitFactionGroup("player")
    local fCode = (factionTag == "Horde" and "H") or (factionTag == "Alliance" and "A") or nil
    local playerLevel = self:GetPlayerLevel()

    local best, bestScore = nil, nil
    for _, tr in ipairs(CLASS_TRAINERS) do
        local facOK = (tr.faction == "B") or not fCode or (tr.faction == fCode)
        local classOK = classTag and tr.classSet[classTag]
        local lvlOK = (not tr.minLevel or playerLevel >= tr.minLevel)
            and (not tr.maxLevel or playerLevel <= tr.maxLevel)
        if facOK and classOK and lvlOK then
            local yards = nil
            if refMapID and refX and refY and self.ComputeWorldDistanceYards then
                yards = self:ComputeWorldDistanceYards(refMapID, refX, refY, tr.mapID, tr.x, tr.y, metaCache)
            end

            local metric
            if tr.mapID == refMapID and yards then
                metric = yards
            elseif tr.mapID == refMapID then
                metric = 200
            elseif yards then
                -- Keep same-continent yard distance accurate; non-hub towns are naturally preferred if closer
                metric = yards + (tr.isCapital and 120 or 0)
            else
                -- Cross-continent / no player coords fallback: prefer major faction capital
                metric = tr.isCapital and 20000 or 30000
            end

            if not bestScore or metric < bestScore then
                bestScore = metric
                best = {
                    name      = tr.name,
                    sub       = tr.sub,
                    mapID     = tr.mapID,
                    x         = tr.x,
                    y         = tr.y,
                    distYards = yards,
                    isCapital = tr.isCapital,
                }
            end
        end
    end

    if best then
        local mapInfo = best.mapID and C_Map and C_Map.GetMapInfo and SafeCall(C_Map.GetMapInfo, best.mapID)
        best.zoneName = (type(mapInfo) == "table" and IsAccessible(mapInfo.name) and mapInfo.name) or best.sub or ""
    end
    return best
end

function FP:BuildDynamicTrainStep(ctx, metaCache)
    local need = self:GetClassTrainerNeed(false)
    if not need then return nil end

    ctx = ctx or {}
    local trainer = self:GetBestClassTrainer(ctx.mapID, ctx.px, ctx.py, metaCache)
    if not trainer then return nil end

    local L = self.L or {}
    local maxShown = 2
    local previewParts = {}
    for i = 1, math.min(#need.skills, maxShown) do
        previewParts[i] = need.skills[i]
    end
    local skillsText = table.concat(previewParts, ", ")
    if #need.skills > maxShown then
        skillsText = skillsText .. " " .. string.format(L["SYNC_TRAIN_MORE"] or "+%d", #need.skills - maxShown)
    end

    local zoneLabel = (trainer.zoneName and trainer.zoneName ~= "") and trainer.zoneName or (trainer.sub or "")
    local stepText = string.format(
        L["SYNC_TRAIN_STEP"] or "Train (Lv %d): %s — %s (%s)",
        need.level, skillsText, trainer.name, zoneLabel
    )

    -- Build clean tooltip objective lines (trainer NPC + unlearned spell names)
    local objLines = {
        string.format(L["SYNC_TRAIN_TIP_NPC"] or "Trainer: %s (%s)", trainer.name, zoneLabel),
    }
    local maxList = math.min(#need.skills, 7)
    for i = 1, maxList do
        objLines[#objLines + 1] = need.skills[i]
    end
    if #need.skills > maxList then
        objLines[#objLines + 1] = string.format(L["SYNC_TRAIN_MORE"] or "+%d more", #need.skills - maxList)
    end

    -- Score calibration relative to QuestSync bands:
    --   0..3000    = ready turn-ins / urgent local stops
    --   4700..5500 = in-zone & nearby quests
    --   9000       = dungeon quests
    local sameZone = (ctx.mapID and trainer.mapID == ctx.mapID)
    local yards = trainer.distYards
    local overdue = math.max(0, need.level - need.minMissingLevel)
    local distScore = yards and math.min(400, (yards / 15) * 3) or 250

    local score
    if sameZone or (yards and yards <= 550) then
        -- Right in town/zone with trainer: handle right alongside in-city turn-ins
        score = 350 + (yards and math.min(250, yards * 0.4) or 0)
    elseif overdue >= 4 or need.count >= 4 then
        score = 1600 + distScore
    elseif overdue >= 2 or need.count >= 2 then
        score = 3600 + distScore
    else
        -- Just leveled up while out questing: queue right after nearby in-zone quests
        score = 5200 + math.min(300, distScore)
    end

    return {
        id             = "__DYNAMIC_TRAIN__",
        action         = "TRAIN",
        isDynamicTrain = true,
        trainKey       = need.milestoneKey,
        minLevel       = need.minMissingLevel,
        targetLevel    = need.level,
        text           = stepText,
        pinTitle       = string.format(L["SYNC_TRAIN_PIN_TITLE"] or "Class Trainer: %s", trainer.name),
        questHeader    = L["SYNC_TRAIN_TIP_SKILLS"] or "Unlearned class skills for your level",
        questLevel     = need.level,
        objectivesList = objLines,
        mapID          = trainer.mapID,
        targetMapID    = trainer.mapID,
        x              = trainer.x,
        y              = trainer.y,
        trainerName    = trainer.name,
        trainerZone    = zoneLabel,
        unlearnedCount = need.count,
        score          = score,
    }
end
