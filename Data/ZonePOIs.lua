-------------------------------------------------------------------------------
-- NexusKit - Data/ZonePOIs.lua
-- Classic (1-60) & WoW Forever Zone Discovery POIs (Flight Masters, Innkeepers,
-- Transports, Hub Services, and Dungeon/Raid Entrances) + Live API Merger.
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    return unpack(res, 2)
end

local function NormalizeStr(s)
    if not IsSafeStr(s) then return "" end
    local low = string.lower(s)
    low = low:gsub("[:'`%-_,%.%(%)]+", " ")
    low = low:gsub("%s+", " ")
    return low:match("^%s*(.-)%s*$") or ""
end

local function P(cat, name, fac, x, y, sub, guideID)
    local f = "Both"
    if fac == "A" or fac == "Alliance" then
        f = "Alliance"
    elseif fac == "H" or fac == "Horde" then
        f = "Horde"
    end
    return {
        cat = cat,
        name = name,
        faction = f,
        x = x,
        y = y,
        sub = sub,
        guideID = guideID,
    }
end

local CAPITAL_MAP_IDS = {
    [1453] = true, -- Stormwind City
    [1454] = true, -- Orgrimmar
    [1455] = true, -- Ironforge
    [1456] = true, -- Thunder Bluff
    [1457] = true, -- Darnassus
    [1458] = true, -- Undercity
}

local CURATED_ZONE_POIS = {
    -- =========================================================================
    -- KALIMDOR
    -- =========================================================================
    [1411] = { -- Durotar
        P("inn",       "Razor Hill Inn (Innkeeper Grosk)",            "H", 51.6, 41.6, "Razor Hill"),
        P("repair",    "Razor Hill Repair & Vendor",                  "H", 51.9, 40.9, "Razor Hill"),
        P("mailbox",   "Razor Hill Mailbox",                          "H", 51.5, 41.7, "Razor Hill"),
        P("transport", "Zeppelin Tower (Undercity / Grom'gol)",       "H", 50.8, 13.8, "Outside Orgrimmar Gates"),
    },
    [1412] = { -- Mulgore
        P("inn",       "Bloodhoof Village Inn (Innkeeper Kauth)",     "H", 46.6, 61.1, "Bloodhoof Village"),
        P("repair",    "Bloodhoof Village Repair & Vendor",           "H", 46.2, 58.2, "Bloodhoof Village"),
        P("mailbox",   "Bloodhoof Village Mailbox",                   "H", 46.8, 60.4, "Bloodhoof Village"),
    },
    [1413] = { -- The Barrens
        P("flight",    "Devrak (Wind Rider Master)",                  "H", 51.5, 30.3, "The Crossroads"),
        P("inn",       "Crossroads Inn (Boorand Plainswind)",         "H", 52.0, 29.9, "The Crossroads"),
        P("repair",    "Crossroads Repair & Vendor",                  "H", 51.1, 29.1, "The Crossroads"),
        P("mailbox",   "Crossroads Mailbox",                          "H", 52.3, 30.0, "The Crossroads"),
        P("flight",    "Omusa Thunderhorn (Wind Rider Master)",       "H", 44.5, 59.1, "Camp Taurajo"),
        P("inn",       "Camp Taurajo Inn (Innkeeper Byula)",          "H", 45.6, 59.0, "Camp Taurajo"),
        P("repair",    "Camp Taurajo Repair",                         "H", 45.1, 57.7, "Camp Taurajo"),
        P("flight",    "Bragok (Flight Master)",                      "B", 63.1, 37.2, "Ratchet"),
        P("inn",       "Ratchet Inn (Innkeeper Wiley)",               "B", 62.1, 39.4, "Ratchet"),
        P("transport", "Boat to Booty Bay",                           "B", 63.7, 38.6, "Ratchet Docks"),
        P("bank",      "Ratchet Bank",                                "B", 62.6, 37.5, "Ratchet"),
        P("mailbox",   "Ratchet Mailbox",                             "B", 62.3, 38.8, "Ratchet"),
        P("dungeon",   "Wailing Caverns (17-24)",                     "B", 46.0, 36.2, "Cave above lush oasis", 43),
        P("dungeon",   "Razorfen Kraul (29-38)",                      "B", 41.0, 57.5, "Southern Barrens", 47),
        P("dungeon",   "Razorfen Downs (37-46)",                      "B", 45.6, 58.3, "Southeast of RFK", 129),
    },
    [1438] = { -- Teldrassil
        P("inn",       "Dolanaar Inn (Innkeeper Keldamyr)",           "A", 55.6, 59.8, "Dolanaar"),
        P("repair",    "Dolanaar Repair & Vendor",                    "A", 55.9, 57.4, "Dolanaar"),
        P("mailbox",   "Dolanaar Mailbox",                            "A", 55.5, 59.2, "Dolanaar"),
        P("flight",    "Vesprystus (Hippogryph Master)",              "A", 58.4, 94.0, "Rut'theran Village"),
        P("transport", "Boat to Auberdine (Darkshore)",               "A", 54.9, 96.4, "Rut'theran Docks"),
    },
    [1439] = { -- Darkshore
        P("flight",    "Caylais Moonfeather (Hippogryph Master)",     "A", 36.3, 45.6, "Auberdine"),
        P("inn",       "Auberdine Inn (Innkeeper Shaussiy)",          "A", 37.0, 44.1, "Auberdine"),
        P("repair",    "Auberdine Repair & Vendor",                   "A", 37.5, 41.8, "Auberdine"),
        P("mailbox",   "Auberdine Mailbox",                           "A", 36.8, 44.0, "Auberdine"),
        P("transport", "Boats (Rut'theran / Menethil Harbor)",        "A", 32.8, 43.8, "Auberdine Pier"),
    },
    [1440] = { -- Ashenvale
        P("flight",    "Daelyshia (Hippogryph Master)",               "A", 34.4, 48.0, "Astranaar"),
        P("inn",       "Astranaar Inn (Innkeeper Kimlya)",            "A", 37.0, 49.3, "Astranaar"),
        P("repair",    "Astranaar Repair & Vendor",                   "A", 36.6, 49.9, "Astranaar"),
        P("mailbox",   "Astranaar Mailbox",                           "A", 37.3, 49.1, "Astranaar"),
        P("flight",    "Vhulgra (Wind Rider Master)",                 "H", 73.3, 61.7, "Splintertree Post"),
        P("inn",       "Splintertree Inn (Innkeeper Kaylisk)",        "H", 74.0, 60.6, "Splintertree Post"),
        P("repair",    "Splintertree Post Repair",                    "H", 73.1, 61.5, "Splintertree Post"),
        P("flight",    "Andruk (Wind Rider Master)",                  "H", 12.2, 33.8, "Zoram'gar Outpost"),
        P("repair",    "Zoram'gar Outpost Vendor & Repair",           "H", 11.7, 34.4, "Zoram'gar Outpost"),
        P("dungeon",   "Blackfathom Deeps (24-32)",                   "B", 14.2, 13.8, "Zoram Strand Temple", 48),
    },
    [1441] = { -- Thousand Needles
        P("flight",    "Nyse (Wind Rider Master)",                    "H", 45.1, 49.1, "Freewind Post"),
        P("inn",       "Freewind Post Inn (Innkeeper Adegwa)",        "H", 46.1, 51.5, "Freewind Post"),
        P("repair",    "Freewind Post Repair",                        "H", 45.9, 50.8, "Freewind Post"),
        P("repair",    "Mirage Raceway Repair & Vendor",              "B", 78.2, 74.5, "Shimmering Flats"),
    },
    [1442] = { -- Stonetalon Mountains
        P("flight",    "Teloren (Hippogryph Master)",                 "A", 36.4,  7.2, "Stonetalon Peak"),
        P("flight",    "Tharm (Wind Rider Master)",                   "H", 45.1, 59.9, "Sun Rock Retreat"),
        P("inn",       "Sun Rock Retreat Inn (Innkeeper Jayka)",      "H", 47.5, 62.1, "Sun Rock Retreat"),
        P("repair",    "Sun Rock Retreat Repair",                     "H", 46.0, 60.4, "Sun Rock Retreat"),
        P("mailbox",   "Sun Rock Retreat Mailbox",                    "H", 47.4, 61.6, "Sun Rock Retreat"),
    },
    [1443] = { -- Desolace
        P("flight",    "Baritanas Skyriver (Hippogryph Master)",      "A", 64.7, 10.5, "Nijel's Point"),
        P("inn",       "Nijel's Point Inn (Innkeeper Sikewa)",        "A", 66.3,  6.7, "Nijel's Point"),
        P("repair",    "Nijel's Point Repair & Vendor",               "A", 66.2,  7.5, "Nijel's Point"),
        P("flight",    "Thalon (Wind Rider Master)",                  "H", 21.6, 74.1, "Shadowprey Village"),
        P("inn",       "Shadowprey Village Inn (Innkeeper Sikewa)",   "H", 24.1, 68.3, "Shadowprey Village"),
        P("repair",    "Shadowprey Village Repair",                   "H", 25.0, 69.5, "Shadowprey Village"),
        P("dungeon",   "Maraudon (46-55)",                            "B", 29.0, 62.4, "Valley of Spears", 349),
    },
    [1444] = { -- Feralas
        P("flight",    "Fyldren Moonfeather (Hippogryph Master)",     "A", 30.2, 43.2, "Feathermoon Stronghold"),
        P("inn",       "Feathermoon Inn (Innkeeper Greul)",           "A", 30.9, 43.5, "Feathermoon Stronghold"),
        P("repair",    "Feathermoon Stronghold Repair",               "A", 30.6, 42.6, "Feathermoon Stronghold"),
        P("flight",    "Shyn (Wind Rider Master)",                    "H", 75.4, 44.3, "Camp Mojache"),
        P("inn",       "Camp Mojache Inn (Innkeeper Hoto)",           "H", 74.8, 45.1, "Camp Mojache"),
        P("repair",    "Camp Mojache Repair",                         "H", 74.7, 43.8, "Camp Mojache"),
        P("flight",    "Thyssiana (Hippogryph Master)",               "A", 89.5, 45.9, "Thalanaar"),
        P("dungeon",   "Dire Maul (55-60)",                           "B", 59.0, 42.2, "Eldreth Courtyard (E/W/N)", 429),
    },
    [1445] = { -- Dustwallow Marsh
        P("flight",    "Baldruc (Gryphon Master)",                    "A", 67.5, 51.3, "Theramore Isle"),
        P("inn",       "Theramore Inn (Innkeeper Janene)",            "A", 66.6, 45.2, "Theramore Isle"),
        P("repair",    "Theramore Isle Repair",                       "A", 66.4, 47.4, "Theramore Isle"),
        P("mailbox",   "Theramore Isle Mailbox",                      "A", 66.5, 45.4, "Theramore Isle"),
        P("transport", "Boat to Menethil Harbor (Wetlands)",          "A", 71.5, 56.5, "Theramore Docks"),
        P("flight",    "Shardi (Wind Rider Master)",                  "H", 35.6, 31.8, "Brackenwall Village"),
        P("inn",       "Brackenwall Inn (Innkeeper Sikossa)",         "H", 36.8, 32.4, "Brackenwall Village"),
        P("dungeon",   "Onyxia's Lair (60 Raid)",                     "B", 52.6, 76.2, "Wyrmbog Cave", 249),
        P("dungeon",   "Alcaz Prison (48-53)",                        "B", 77.2, 17.5, "Alcaz Island (Forever)", "FOREVER_ALCAZ_PRISON"),
    },
    [1446] = { -- Tanaris
        P("flight",    "Bera Stonehammer / Bulkrek (Flight Master)",  "B", 51.0, 29.3, "Gadgetzan (A/H)"),
        P("inn",       "Gadgetzan Inn (Innkeeper Fizzgrimble)",       "B", 52.5, 27.9, "Gadgetzan"),
        P("bank",      "Gadgetzan Bank",                              "B", 52.3, 28.9, "Gadgetzan"),
        P("auction",   "Gadgetzan Neutral Auction House",             "B", 51.7, 27.6, "Gadgetzan"),
        P("repair",    "Gadgetzan Repair & Vendor",                   "B", 51.7, 28.6, "Gadgetzan"),
        P("mailbox",   "Gadgetzan Mailbox",                           "B", 52.2, 27.9, "Gadgetzan"),
        P("transport", "Boat to Powderfuse Port (Riverglades)",       "B", 67.3, 22.8, "Steamwheedle Port Docks"),
        P("dungeon",   "Zul'Farrak (42-50)",                          "B", 38.7, 20.0, "Northwestern Tanaris", 209),
    },
    [1447] = { -- Azshara
        P("flight",    "Jarrodenus (Hippogryph Master)",              "A", 11.9, 77.6, "Talrendis Point"),
        P("flight",    "Kroum (Wind Rider Master)",                   "H", 22.0, 49.6, "Valormok"),
        P("repair",    "Talrendis / Valormok Field Repair",           "B", 11.6, 77.9, "Talrendis Point"),
        P("dungeon",   "Blackmaw Hold (55-60)",                       "B", 38.4, 32.6, "Northern Timbermaw Hold (Forever)", "FOREVER_BLACKMAW_HOLD"),
    },
    [1448] = { -- Felwood
        P("flight",    "Mishellena (Hippogryph Master)",              "A", 62.5, 24.2, "Talonbranch Glade"),
        P("flight",    "Brakkar (Wind Rider Master)",                 "H", 34.4, 53.8, "Bloodvenom Post"),
        P("repair",    "Emerald Sanctuary Vendor & Repair",           "B", 51.4, 82.0, "Southern Felwood"),
    },
    [1449] = { -- Un'Goro Crater
        P("flight",    "Gryfe (Flight Master)",                       "B", 45.3,  6.0, "Marshal's Refuge"),
        P("repair",    "Marshal's Refuge Repair & Vendor",            "B", 43.6,  8.6, "Marshal's Refuge"),
        P("mailbox",   "Marshal's Refuge Mailbox",                    "B", 44.2,  8.1, "Marshal's Refuge"),
        P("dungeon",   "Shaper's Terrace (58-60)",                    "B", 50.5, 81.0, "Southern Crater (Forever)", "FOREVER_SHAPERS_TERRACE"),
    },
    [1450] = { -- Moonglade
        P("flight",    "Sindrayl (Hippogryph Master)",                "A", 48.0, 67.4, "Lake Elune'ara"),
        P("flight",    "Faustron (Wind Rider Master)",                "H", 32.1, 66.5, "Moonglade"),
        P("flight",    "Silva Fil'naveth / Bunthen (Druid Flight)",   "B", 44.2, 45.4, "Nighthaven (Druid)"),
        P("repair",    "Nighthaven Vendor & Repair",                  "B", 51.8, 45.0, "Nighthaven"),
    },
    [1451] = { -- Silithus
        P("flight",    "Cloud Skydancer / Runk Windtamer (Flight)",   "B", 50.6, 34.5, "Cenarion Hold"),
        P("inn",       "Cenarion Hold Inn (Calandrath)",              "B", 51.8, 39.1, "Cenarion Hold"),
        P("repair",    "Cenarion Hold Repair & Vendor",               "B", 51.3, 37.8, "Cenarion Hold"),
        P("mailbox",   "Cenarion Hold Mailbox",                       "B", 51.5, 38.8, "Cenarion Hold"),
        P("dungeon",   "Ahn'Qiraj Gate (AQ20 & AQ40 Raids)",          "B", 29.3, 93.2, "Scarab Wall", 531),
    },
    [1452] = { -- Winterspring
        P("flight",    "Maethrya / Yugrek (Flight Master)",           "B", 61.4, 37.0, "Everlook (A/H)"),
        P("inn",       "Everlook Inn (Innkeeper Vizzie)",             "B", 61.3, 38.9, "Everlook"),
        P("bank",      "Everlook Bank",                               "B", 61.4, 37.6, "Everlook"),
        P("auction",   "Everlook Neutral Auction House",              "B", 60.9, 37.8, "Everlook"),
        P("repair",    "Everlook Repair & Vendor",                    "B", 61.6, 38.3, "Everlook"),
        P("mailbox",   "Everlook Mailbox",                            "B", 61.2, 38.5, "Everlook"),
    },
    [1454] = { -- Orgrimmar
        P("flight",    "Doras (Wind Rider Master)",                   "H", 45.2, 63.8, "Valley of Strength"),
        P("inn",       "Orgrimmar Inn (Innkeeper Gryshka)",           "H", 54.1, 68.4, "Valley of Strength"),
        P("bank",      "Bank of Orgrimmar",                           "H", 49.6, 69.2, "Valley of Strength"),
        P("auction",   "Orgrimmar Auction House",                     "H", 55.6, 63.8, "Valley of Strength"),
        P("mailbox",   "Orgrimmar Bank Mailbox",                      "H", 49.2, 69.8, "Valley of Strength"),
        P("repair",    "Valley of Honor Repair",                      "H", 79.8, 22.8, "Hall of the Brave"),
        P("dungeon",   "Ragefire Chasm (13-18)",                      "H", 52.5, 49.0, "Cleft of Shadow", 389),
    },
    [1456] = { -- Thunder Bluff
        P("flight",    "Tal (Wind Rider Master)",                     "H", 46.8, 50.0, "Central Mesa"),
        P("inn",       "Thunder Bluff Inn (Innkeeper Pala)",          "H", 45.8, 64.7, "Lower Rise"),
        P("bank",      "Thunder Bluff Bank",                          "H", 47.4, 58.6, "Lower Rise"),
        P("auction",   "Thunder Bluff Auction House",                 "H", 40.4, 51.8, "Lower Rise"),
        P("mailbox",   "Thunder Bluff Mailbox",                       "H", 46.8, 59.5, "Lower Rise"),
    },
    [1457] = { -- Darnassus
        P("inn",       "Darnassus Inn (Innkeeper Saelienne)",         "A", 67.4, 15.6, "Craftsmen's Terrace"),
        P("bank",      "Darnassus Bank",                              "A", 39.6, 42.3, "Temple Gardens"),
        P("auction",   "Darnassus Auction House",                     "A", 56.4, 52.8, "Tradesmen's Terrace"),
        P("mailbox",   "Darnassus Mailbox",                           "A", 39.4, 41.0, "Outside Bank"),
        P("transport", "Portal to Rut'theran Village",                "A", 30.4, 41.4, "Temple Gardens"),
    },

    -- =========================================================================
    -- EASTERN KINGDOMS
    -- =========================================================================
    [1416] = { -- Alterac Mountains
        P("dungeon",   "City of Dalaran (28-33)",                     "B", 16.3, 65.8, "Dalaran Crater (Forever)", "FOREVER_CITY_OF_DALARAN"),
    },
    [1417] = { -- Arathi Highlands
        P("flight",    "Cedrik Prose (Gryphon Master)",               "A", 45.7, 46.1, "Refuge Pointe"),
        P("repair",    "Refuge Pointe Repair & Vendor",               "A", 45.2, 47.4, "Refuge Pointe"),
        P("flight",    "Urda (Wind Rider Master)",                    "H", 73.1, 32.7, "Hammerfall"),
        P("inn",       "Hammerfall Inn (Innkeeper Adegwa)",           "H", 73.8, 32.6, "Hammerfall"),
        P("repair",    "Hammerfall Repair",                           "H", 74.1, 33.9, "Hammerfall"),
        P("mailbox",   "Hammerfall Mailbox",                          "H", 73.7, 32.8, "Hammerfall"),
    },
    [1418] = { -- Badlands
        P("flight",    "Gorrik (Wind Rider Master)",                  "H",  4.0, 44.8, "Kargath"),
        P("inn",       "Kargath Inn (Innkeeper Shul'kar)",            "H",  2.8, 45.9, "Kargath"),
        P("repair",    "Kargath Repair & Vendor",                     "H",  3.3, 47.6, "Kargath"),
        P("mailbox",   "Kargath Mailbox",                             "H",  3.0, 46.2, "Kargath"),
        P("dungeon",   "Uldaman (41-51)",                             "B", 42.5, 13.5, "Main Entrance", 70),
    },
    [1419] = { -- Blasted Lands
        P("flight",    "Alexandra Constantine (Gryphon Master)",      "A", 65.5, 24.4, "Nethergarde Keep"),
        P("repair",    "Nethergarde Keep Repair & Vendor",            "A", 64.6, 15.8, "Nethergarde Keep"),
    },
    [1420] = { -- Tirisfal Glades
        P("inn",       "Gallows' End Tavern (Innkeeper Renee)",       "H", 61.5, 52.1, "Brill"),
        P("repair",    "Brill Repair & Blacksmith",                   "H", 60.4, 51.7, "Brill"),
        P("mailbox",   "Brill Mailbox",                               "H", 61.3, 52.4, "Brill"),
        P("transport", "Zeppelin Tower (Orgrimmar / Grom'gol)",       "H", 60.7, 58.8, "North of Undercity"),
        P("dungeon",   "Ruins of Lordaeron (15-20)",                  "B", 61.8, 65.0, "Courtyard (Forever)", "FOREVER_RUINS_OF_LORDAERON"),
        P("dungeon",   "Scarlet Monastery (26-45)",                   "B", 85.0, 32.0, "GY / Lib / Arm / Cath", 189),
    },
    [1421] = { -- Silverpine Forest
        P("flight",    "Karos Razok (Bat Handler)",                   "H", 45.6, 42.6, "The Sepulcher"),
        P("inn",       "The Sepulcher Inn (Innkeeper Bates)",         "H", 43.2, 41.3, "The Sepulcher"),
        P("repair",    "The Sepulcher Repair & Vendor",               "H", 43.9, 41.0, "The Sepulcher"),
        P("mailbox",   "The Sepulcher Mailbox",                       "H", 43.5, 41.2, "The Sepulcher"),
        P("dungeon",   "Shadowfang Keep (22-30)",                     "B", 44.8, 67.8, "Above Pyrewood Village", 33),
    },
    [1422] = { -- Western Plaguelands
        P("flight",    "Bibilfaz Featherwhistle (Gryphon Master)",    "A", 42.9, 85.1, "Chillwind Camp"),
        P("repair",    "Chillwind Camp Vendor & Repair",              "A", 43.4, 84.4, "Chillwind Camp"),
        P("dungeon",   "Scholomance (58-60)",                         "B", 69.1, 72.9, "Caer Darrow Island", 289),
    },
    [1423] = { -- Eastern Plaguelands
        P("flight",    "Georgia / Khaelyn Steelwing (Flight Master)", "B", 81.2, 58.8, "Light's Hope Chapel (A/H)"),
        P("repair",    "Light's Hope Repair & Quartermaster",         "B", 81.5, 58.2, "Light's Hope Chapel"),
        P("mailbox",   "Light's Hope Chapel Mailbox",                 "B", 81.6, 59.5, "Light's Hope Chapel"),
        P("dungeon",   "Stratholme Main Gate (58-60)",                "B", 31.0, 14.0, "Front Entrance", 329),
        P("dungeon",   "Naxxramas (60 Raid)",                         "B", 39.4, 25.4, "Plaguewood Zigguart", 533),
    },
    [1424] = { -- Hillsbrad Foothills
        P("flight",    "Darla Harris (Gryphon Master)",               "A", 49.3, 52.3, "Southshore"),
        P("inn",       "Southshore Inn (Innkeeper Anderson)",         "A", 51.1, 58.9, "Southshore"),
        P("repair",    "Southshore Repair & Vendor",                  "A", 50.4, 57.1, "Southshore"),
        P("mailbox",   "Southshore Mailbox",                          "A", 50.9, 58.6, "Southshore"),
        P("flight",    "Zarise (Bat Handler)",                        "H", 60.1, 18.6, "Tarren Mill"),
        P("inn",       "Tarren Mill Inn (Innkeeper Shay)",            "H", 62.8, 19.0, "Tarren Mill"),
        P("repair",    "Tarren Mill Repair & Vendor",                 "H", 62.3, 20.4, "Tarren Mill"),
        P("mailbox",   "Tarren Mill Mailbox",                         "H", 62.6, 19.3, "Tarren Mill"),
    },
    [1425] = { -- The Hinterlands
        P("flight",    "Guthrum Thunderfist (Gryphon Master)",        "A", 11.1, 46.1, "Aerie Peak"),
        P("inn",       "Aerie Peak Inn (Innkeeper Thulfram)",         "A", 14.1, 41.5, "Aerie Peak"),
        P("repair",    "Aerie Peak Repair & Vendor",                  "A", 14.8, 44.6, "Aerie Peak"),
        P("flight",    "Gorkas (Wind Rider Master)",                  "H", 81.7, 81.8, "Revantusk Village"),
        P("inn",       "Revantusk Village Inn (Innkeeper Jovia)",     "H", 78.3, 81.4, "Revantusk Village"),
        P("repair",    "Revantusk Village Repair",                    "H", 79.1, 80.5, "Revantusk Village"),
    },
    [1426] = { -- Dun Morogh
        P("inn",       "Thunderbrew Distillery (Innkeeper Belm)",     "A", 47.4, 52.5, "Kharanos"),
        P("repair",    "Kharanos Repair & Blacksmith",                "A", 47.0, 52.0, "Kharanos"),
        P("mailbox",   "Kharanos Mailbox",                            "A", 47.5, 52.6, "Kharanos"),
        P("dungeon",   "Gnomeregan (29-38)",                          "B", 24.8, 39.6, "New Tinkertown", 90),
    },
    [1427] = { -- Searing Gorge
        P("flight",    "Lanie Reed / Grisha (Flight Master)",         "B", 37.9, 30.8, "Thorium Point (A/H)"),
        P("repair",    "Thorium Point Repair & Vendor",               "B", 38.6, 27.9, "Thorium Point"),
        P("dungeon",   "Blackrock Mountain (BRD / UBRS / MC / BWL)",  "B", 34.8, 85.3, "North Gate", 230),
    },
    [1428] = { -- Burning Steppes
        P("flight",    "Borgus Stoutarm (Gryphon Master)",            "A", 84.4, 68.2, "Morgan's Vigil"),
        P("repair",    "Morgan's Vigil Repair & Vendor",              "A", 84.8, 69.0, "Morgan's Vigil"),
        P("flight",    "Vahgruk (Wind Rider Master)",                 "H", 65.6, 24.2, "Flame Crest"),
        P("repair",    "Flame Crest Vendor & Repair",                 "H", 65.1, 23.8, "Flame Crest"),
        P("dungeon",   "Blackrock Mountain (BRD / UBRS / MC / BWL)",  "B", 29.4, 38.3, "South Gate", 230),
    },
    [1429] = { -- Elwynn Forest
        P("inn",       "Lion's Pride Inn (Innkeeper Farley)",         "A", 42.7, 65.6, "Goldshire"),
        P("repair",    "Goldshire Blacksmith & Repair",               "A", 41.8, 65.7, "Goldshire"),
        P("mailbox",   "Goldshire Mailbox",                           "A", 42.9, 65.8, "Goldshire"),
    },
    [1430] = { -- Deadwind Pass
        P("dungeon",   "Karazhan Landmark",                           "B", 46.9, 74.8, "Southern Deadwind Pass"),
    },
    [1431] = { -- Duskwood
        P("flight",    "Felicia Maline (Gryphon Master)",             "A", 77.5, 44.3, "Darkshire"),
        P("inn",       "Scarlet Raven Tavern (Innkeeper Trelayne)",   "A", 73.9, 44.4, "Darkshire"),
        P("repair",    "Darkshire Repair & Blacksmith",               "A", 73.3, 46.5, "Darkshire"),
        P("mailbox",   "Darkshire Mailbox",                           "A", 74.1, 44.8, "Darkshire"),
    },
    [1432] = { -- Loch Modan
        P("flight",    "Thorgrum Borrelson (Gryphon Master)",         "A", 33.9, 50.9, "Thelsamar"),
        P("inn",       "Stoutlager Inn (Innkeeper Hearthstove)",      "A", 35.5, 48.4, "Thelsamar"),
        P("repair",    "Thelsamar Repair & Vendor",                   "A", 35.2, 47.8, "Thelsamar"),
        P("mailbox",   "Thelsamar Mailbox",                           "A", 35.4, 48.6, "Thelsamar"),
    },
    [1433] = { -- Redridge Mountains
        P("flight",    "Ariena Stormfeather (Gryphon Master)",        "A", 30.6, 59.4, "Lakeshire"),
        P("inn",       "Lakeshire Inn (Innkeeper Brianna)",           "A", 26.5, 44.8, "Lakeshire"),
        P("repair",    "Lakeshire Repair & Blacksmith",               "A", 29.0, 47.4, "Lakeshire"),
        P("mailbox",   "Lakeshire Mailbox",                           "A", 27.1, 45.0, "Lakeshire"),
    },
    [1434] = { -- Stranglethorn Vale
        P("flight",    "Gyll / Gringer (Flight Master)",              "B", 27.3, 77.5, "Booty Bay (A/H)"),
        P("inn",       "Salty Sailor Tavern (Innkeeper Skindle)",     "B", 27.1, 77.3, "Booty Bay"),
        P("bank",      "Booty Bay Bank",                              "B", 26.6, 76.4, "Booty Bay"),
        P("auction",   "Booty Bay Neutral Auction House",             "B", 27.3, 77.5, "Booty Bay"),
        P("repair",    "Booty Bay Repair & Vendor",                   "B", 27.6, 77.4, "Booty Bay"),
        P("mailbox",   "Booty Bay Mailbox",                           "B", 27.0, 77.2, "Booty Bay"),
        P("transport", "Boat to Ratchet (The Barrens)",               "B", 25.9, 73.1, "Booty Bay Pier"),
        P("flight",    "Thysta (Wind Rider Master)",                  "H", 32.5, 29.4, "Grom'gol Base Camp"),
        P("inn",       "Grom'gol Inn (Innkeeper Thulbek)",            "H", 32.1, 29.2, "Grom'gol Base Camp"),
        P("repair",    "Grom'gol Base Camp Repair",                   "H", 32.1, 28.8, "Grom'gol Base Camp"),
        P("transport", "Zeppelin Tower (Orgrimmar / Undercity)",      "H", 31.4, 29.7, "Grom'gol Tower"),
        P("dungeon",   "Zul'Gurub (60 Raid)",                         "B", 52.2, 17.1, "Eastern STV", 309),
        P("dungeon",   "The Drowned City (35-40)",                    "B", 22.5, 65.0, "Off STV Coast (Forever)", "FOREVER_DROWNED_CITY"),
    },
    [1435] = { -- Swamp of Sorrows
        P("flight",    "Breyk (Wind Rider Master)",                   "H", 46.0, 54.6, "Stonard"),
        P("inn",       "Stonard Inn (Innkeeper Karakul)",             "H", 45.2, 56.8, "Stonard"),
        P("repair",    "Stonard Repair & Blacksmith",                 "H", 46.6, 56.1, "Stonard"),
        P("dungeon",   "Temple of Atal'Hakkar (50-60)",               "B", 69.5, 53.6, "Sorrowmurk Lake", 109),
    },
    [1436] = { -- Westfall
        P("flight",    "Thor (Gryphon Master)",                       "A", 56.6, 52.7, "Sentinel Hill"),
        P("inn",       "Sentinel Hill Inn (Innkeeper Heather)",       "A", 52.8, 53.6, "Sentinel Hill"),
        P("repair",    "Sentinel Hill Blacksmith & Repair",           "A", 53.6, 53.4, "Sentinel Hill"),
        P("mailbox",   "Sentinel Hill Mailbox",                       "A", 52.9, 53.4, "Sentinel Hill"),
        P("dungeon",   "The Deadmines (17-26)",                       "B", 42.5, 71.7, "Moonbrook", 36),
    },
    [1437] = { -- Wetlands
        P("flight",    "Shellei Brondir (Gryphon Master)",            "A",  9.5, 59.7, "Menethil Harbor"),
        P("inn",       "Deepwater Tavern (Innkeeper Helbrek)",        "A", 10.7, 61.0, "Menethil Harbor"),
        P("repair",    "Menethil Harbor Repair & Vendor",             "A",  9.9, 57.5, "Menethil Harbor"),
        P("mailbox",   "Menethil Harbor Mailbox",                     "A", 10.6, 60.5, "Menethil Harbor"),
        P("transport", "Boat to Theramore Isle",                      "A",  5.0, 63.5, "South Pier"),
        P("transport", "Boat to Auberdine (Darkshore)",               "A",  4.6, 57.1, "North Pier"),
        P("dungeon",   "Excavation Site: Wetlands (24-29)",           "B", 47.0, 56.0, "Whelgar's Excavation (Forever)", "FOREVER_EXCAVATION_SITE"),
    },
    [1453] = { -- Stormwind City (WotLK 3.x / WoW Forever post-Harbor canvas)
        P("flight",    "Dungar Longdrink (Gryphon Master)",           "A", 71.0, 72.5, "Trade District"),
        P("inn",       "The Gilded Rose (Innkeeper Allison)",         "A", 60.4, 75.3, "Trade District"),
        P("bank",      "Stormwind Bank",                              "A", 63.4, 80.2, "Trade District"),
        P("auction",   "Stormwind Auction House",                     "A", 61.2, 70.7, "Trade District"),
        P("mailbox",   "Stormwind Trade District Mailbox",            "A", 62.6, 78.4, "Outside Bank"),
        P("transport", "Deeprun Tram (to Ironforge)",                 "A", 69.6, 30.3, "Dwarven District"),
        P("dungeon",   "The Stockade (24-32)",                        "A", 50.4, 66.2, "Stormwind Canals", 34),
    },
    [1455] = { -- Ironforge
        P("flight",    "Gryth Thurden (Gryphon Master)",              "A", 55.6, 48.2, "The Great Forge"),
        P("inn",       "Stonefire Tavern (Innkeeper Firebrew)",       "A", 18.2, 51.4, "The Commons"),
        P("bank",      "Vault of Ironforge",                          "A", 35.4, 60.8, "The Commons"),
        P("auction",   "Ironforge Auction House",                     "A", 24.8, 74.8, "The Commons"),
        P("mailbox",   "Ironforge Bank Mailbox",                      "A", 33.4, 63.8, "The Commons"),
        P("transport", "Deeprun Tram (to Stormwind)",                 "A", 76.5, 51.2, "Tinker Town"),
        P("dungeon",   "Hall of Thanes (13-18)",                      "A", 44.6, 51.0, "Old Ironforge Entrance (Forever)", "FOREVER_HALL_OF_THANES"),
    },
    [1458] = { -- Undercity
        P("flight",    "Michael Garrett (Bat Handler)",               "H", 63.3, 48.5, "Trade Quarter"),
        P("inn",       "Undercity Inn (Innkeeper Norman)",            "H", 67.8, 38.6, "Trade Quarter"),
        P("bank",      "Undercity Bank",                              "H", 65.9, 44.2, "Trade Quarter"),
        P("auction",   "Undercity Auction House",                     "H", 60.8, 48.0, "Trade Quarter"),
        P("mailbox",   "Undercity Trade Mailbox",                     "H", 67.2, 39.2, "Trade Quarter"),
    },
}

-- Custom WoW Forever zones indexed by normalized zone name (works regardless of server uiMapID)
local CUSTOM_ZONE_POIS = {
    ["riverglades"] = {
        P("flight",    "Gretchen Mayberry (Gryphon Master)",          "A", 60.6, 81.6, "Farholde Keep"),
        P("inn",       "Farholde Keep Inn (Barracks Master Harlan)",  "A", 65.0, 84.0, "Farholde Keep"),
        P("flight",    "Grakna (Wind Rider Master)",                  "H", 59.6, 45.1, "Rog'mar"),
        P("inn",       "Rog'mar Inn (Innkeeper Toka)",                "H", 58.0, 45.0, "Rog'mar"),
        P("inn",       "Eastern Outpost Inn (Innkeeper Zizplink)",    "B", 79.0, 54.0, "Eastern Outpost"),
        P("transport", "Powderfuse Port (Boat to Steamwheedle)",      "B", 79.0, 52.3, "Powderfuse Port"),
        P("dungeon",   "Krol'dok Stronghold (40-45)",                 "B", 43.0, 37.0, "Meeting Stone ~39, 38", "FOREVER_KROLDOK_STRONGHOLD"),
    },
    ["zephras isle"] = {
        P("inn",       "Innkeeper Coriella Calmbreeze",               "B", 43.0, 43.0, "Zephras Isle"),
        P("inn",       "Innkeeper Donaal Downbreeze",                 "B", 62.0, 73.0, "Valanaar"),
        P("bank",      "Baelann Favorbreeze (Banker)",                "B", 58.0, 77.0, "Valanaar"),
        P("repair",    "Valanaar Vendors & Stable (Genn Fairweather)", "B", 54.0, 81.0, "Valanaar"),
    },
    ["mount hyjal"] = {
        P("flight",    "Tainted Foothills Flight Master",             "B", 55.1, 82.5, "Tainted Foothills"),
        P("flight",    "Summit of Eternity Flight Master",            "B", 68.6, 44.1, "Summit of Eternity"),
        P("dungeon",   "Hyjal Summit (60 Raid)",                      "B", 68.6, 44.1, "Nordrassil Peak", "FOREVER_HYJAL_SUMMIT"),
        P("dungeon",   "The Barrow Deeps (60 Raid)",                  "B", 62.0, 24.0, "Northern Hyjal", "FOREVER_BARROW_DEEPS"),
    },
    ["hyjal"] = {
        P("flight",    "Tainted Foothills Flight Master",             "B", 55.1, 82.5, "Tainted Foothills"),
        P("flight",    "Summit of Eternity Flight Master",            "B", 68.6, 44.1, "Summit of Eternity"),
        P("dungeon",   "Hyjal Summit (60 Raid)",                      "B", 68.6, 44.1, "Nordrassil Peak", "FOREVER_HYJAL_SUMMIT"),
        P("dungeon",   "The Barrow Deeps (60 Raid)",                  "B", 62.0, 24.0, "Northern Hyjal", "FOREVER_BARROW_DEEPS"),
    },
}

FP.ZONE_POIS = CURATED_ZONE_POIS

local function MakePOIKey(mapID, poi)
    return string.format("%s|%s|%s", tostring(mapID or 0), tostring(poi.cat or "poi"), NormalizeStr(poi.name))
end

local function EnsureDiscoveryTables()
    if type(NexusKitCharDB) ~= "table" then return nil end
    NexusKitCharDB.discoveredFlights = NexusKitCharDB.discoveredFlights or {}
    NexusKitCharDB.discoveredZonePOIs = NexusKitCharDB.discoveredZonePOIs or {}
    NexusKitCharDB.manualUndiscoveredPOIs = NexusKitCharDB.manualUndiscoveredPOIs or {}
    return NexusKitCharDB
end

local function GetCurrentBindNorm()
    if not GetBindLocation then return "" end
    local ok, loc = pcall(GetBindLocation)
    if ok and IsSafeStr(loc) then
        return NormalizeStr(loc)
    end
    return ""
end

local function IsMapPosExploredByFog(mapID, nx, ny)
    if not IsSafeNum(mapID) or not IsSafeNum(nx) or not IsSafeNum(ny) then return nil end
    if C_MapExplorationInfo and C_MapExplorationInfo.GetExploredAreaIDsAtPosition and CreateVector2D then
        local ok, areas = pcall(C_MapExplorationInfo.GetExploredAreaIDsAtPosition, mapID, CreateVector2D(nx, ny))
        if ok then
            if type(areas) == "table" and #areas > 0 then
                return true
            elseif areas == nil or (type(areas) == "table" and #areas == 0) then
                return false
            end
        end
    end
    return nil
end

local function GetMapInfoSafe(mapID)
    if not IsSafeNum(mapID) or mapID <= 0 or not C_Map or not C_Map.GetMapInfo then return nil end
    return SafeCall(C_Map.GetMapInfo, mapID)
end

local function ResolveCuratedBaseList(mapID)
    local direct = CURATED_ZONE_POIS[mapID]
    if direct then return direct end
    local info = GetMapInfoSafe(mapID)
    if info and IsSafeStr(info.name) then
        local norm = NormalizeStr(info.name)
        if CUSTOM_ZONE_POIS[norm] then
            return CUSTOM_ZONE_POIS[norm]
        end
    end
    return nil
end

local function ShouldIncludeFaction(poiFaction, playerFaction, showOpposite)
    if showOpposite then return true end
    if poiFaction == "Both" or not IsSafeStr(poiFaction) then return true end
    if not IsSafeStr(playerFaction) then return true end
    return poiFaction == playerFaction
end

local function GetCategorySettingEnabled(cat, s)
    if cat == "flight" then return s.zonePOIFlight ~= false end
    if cat == "inn" then return s.zonePOIInn ~= false end
    if cat == "transport" then return s.zonePOITransport ~= false end
    if cat == "dungeon" then return s.zonePOIDungeons ~= false end
    -- repair, mailbox, bank, auction belong to Hub Services
    return s.zonePOIServices ~= false
end

local function IsLiveFlightKnownState(st)
    if not IsSafeNum(st) then return false end
    if Enum and Enum.FlightPathState then
        return st == Enum.FlightPathState.Current or st == Enum.FlightPathState.Reachable
    end
    return st == 0 or st == 1
end

local function MarkPOINameVariantsFlight(name)
    local db = EnsureDiscoveryTables()
    if not db or not IsSafeStr(name) then return end
    local norm = NormalizeStr(name)
    if norm == "" then return end
    db.discoveredFlights["name|" .. norm] = true
    local short = norm:match("^([^,]+)")
    if short and short ~= "" then
        db.discoveredFlights["short|" .. NormalizeStr(short)] = true
    end
end

local function IsFlightRecorded(poi, key)
    local db = EnsureDiscoveryTables()
    if not db then return false end
    if db.manualUndiscoveredPOIs[key] then return false end
    if db.discoveredFlights[key] then return true end
    local normName = NormalizeStr(poi.name)
    if normName ~= "" and db.discoveredFlights["name|" .. normName] then return true end
    local normSub = NormalizeStr(poi.sub)
    if normSub ~= "" then
        for k in pairs(db.discoveredFlights) do
            if type(k) == "string" and k:sub(1, 6) == "short|" and k:sub(7) == normSub then
                return true
            end
        end
    end
    if normName ~= "" then
        local npcPrefix = normName:match("^(.-)%s*%(")
        if npcPrefix and npcPrefix ~= "" and db.discoveredFlights["name|" .. npcPrefix] then
            return true
        end
    end
    return false
end

local function CheckPlayerProximityDiscovery(mapID, pois)
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    local pMapID = SafeCall(C_Map.GetBestMapForUnit, "player")
    if not IsSafeNum(pMapID) or pMapID ~= mapID then return end
    local pos = SafeCall(C_Map.GetPlayerMapPosition, pMapID, "player")
    if not pos or not pos.GetXY then return end
    local px, py = pos:GetXY()
    if not IsSafeNum(px) or not IsSafeNum(py) or (px == 0 and py == 0) then return end

    local db = EnsureDiscoveryTables()
    if not db then return end

    for _, poi in ipairs(pois) do
        if poi.cat ~= "flight" then
            local key = MakePOIKey(mapID, poi)
            if not db.manualUndiscoveredPOIs[key] then
                local dx = (poi.x / 100) - px
                local dy = (poi.y / 100) - py
                if (dx * dx + dy * dy) <= (0.022 * 0.022) then
                    db.discoveredZonePOIs[key] = true
                end
            end
        end
    end
end

local function EvaluatePOIDiscovered(mapID, poi, isCapital, bindNorm)
    local db = EnsureDiscoveryTables()
    local key = poi.key
    if db and db.manualUndiscoveredPOIs[key] then
        return false
    end

    if poi.cat == "flight" then
        if IsLiveFlightKnownState(poi.liveFlightState) then
            if db then db.discoveredFlights[key] = true end
            return true
        end
        return IsFlightRecorded(poi, key)
    end

    if poi.cat == "inn" and bindNorm ~= "" then
        local nName = NormalizeStr(poi.name)
        local nSub = NormalizeStr(poi.sub)
        if (nSub ~= "" and (nSub:find(bindNorm, 1, true) or bindNorm:find(nSub, 1, true)))
            or (nName ~= "" and nName:find(bindNorm, 1, true)) then
            poi.isHearthstone = true
            if db then db.discoveredZonePOIs[key] = true end
            return true
        end
    end

    if db and db.discoveredZonePOIs[key] then
        return true
    end

    if not isCapital then
        local explored = IsMapPosExploredByFog(mapID, poi.x / 100, poi.y / 100)
        if explored == true then
            return true
        end
    end

    return false
end

local function InferLiveAreaPOICategory(info)
    local atlas = NormalizeStr(info and info.atlasName)
    local name = NormalizeStr(info and info.name)
    local desc = NormalizeStr(info and info.description)
    local combined = atlas .. " " .. name .. " " .. desc
    if combined:find("taxi", 1, true) or combined:find("flight", 1, true) or combined:find("gryphon", 1, true) or combined:find("wyvern", 1, true) then
        return "flight"
    elseif combined:find("inn", 1, true) or combined:find("tavern", 1, true) then
        return "inn"
    elseif combined:find("boat", 1, true) or combined:find("ship", 1, true) or combined:find("zeppelin", 1, true) or combined:find("tram", 1, true) or combined:find("portal", 1, true) then
        return "transport"
    elseif combined:find("dungeon", 1, true) or combined:find("raid", 1, true) then
        return "dungeon"
    end
    return nil
end

local function FindNearMatchingPOI(list, nx, ny, cat)
    for _, existing in ipairs(list) do
        local ex = existing.x / 100
        local ey = existing.y / 100
        local distSq = ((ex - nx) ^ 2) + ((ey - ny) ^ 2)
        if distSq <= (0.040 ^ 2) and (not cat or existing.cat == cat) then
            return existing
        end
    end
    return nil
end

function FP:GetZonePOIs(mapID, ignoreFilters)
    if not IsSafeNum(mapID) or mapID <= 0 then return {} end

    local info = GetMapInfoSafe(mapID)
    if info and IsSafeNum(info.mapType) then
        -- Skip Cosmic (0), World (1), Continent (2), and Dungeon interiors (4)
        if info.mapType == 0 or info.mapType == 1 or info.mapType == 2 or info.mapType == 4 then
            return {}
        end
    end

    local playerFaction = self.GetPlayerFaction and self:GetPlayerFaction() or nil
    local s = (NexusKitDB and NexusKitDB.settings) or {}
    local showOpposite = (s.zonePOIOppositeFaction == true)
    local onlyUndisc = (not ignoreFilters) and (s.zonePOIsOnlyUndiscovered == true)
    local isCapital = CAPITAL_MAP_IDS[mapID] == true
    local bindNorm = GetCurrentBindNorm()

    local rawList = {}
    local base = ResolveCuratedBaseList(mapID)
    if base then
        for _, item in ipairs(base) do
            rawList[#rawList + 1] = {
                cat = item.cat,
                name = item.name,
                faction = item.faction or "Both",
                x = item.x,
                y = item.y,
                sub = item.sub,
                guideID = item.guideID,
                key = MakePOIKey(mapID, item),
            }
        end
    end

    -- Merge live C_TaxiMap nodes (handles custom WoW Forever zones & verifies learned states!)
    if C_TaxiMap and C_TaxiMap.GetAllTaxiNodes then
        local okT, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, mapID)
        if okT and type(nodes) == "table" then
            for _, n in ipairs(nodes) do
                if type(n) == "table" and n.position and n.position.GetXY and IsSafeStr(n.name) then
                    local nx, ny = n.position:GetXY()
                    if IsSafeNum(nx) and IsSafeNum(ny) and nx > 0 and nx < 1 and ny > 0 and ny < 1 then
                        local match = FindNearMatchingPOI(rawList, nx, ny, "flight")
                        local nodeState = IsSafeNum(n.state) and n.state or nil
                        if match then
                            match.liveFlightState = nodeState
                            if IsLiveFlightKnownState(nodeState) then
                                MarkPOINameVariantsFlight(n.name)
                            end
                        else
                            local fac = "Both"
                            if n.factionGroup == 1 then
                                fac = "Alliance"
                            elseif n.factionGroup == 2 then
                                fac = "Horde"
                            end
                            local newFlight = {
                                cat = "flight",
                                name = n.name,
                                faction = fac,
                                x = nx * 100,
                                y = ny * 100,
                                sub = "Flight Master",
                                liveFlightState = nodeState,
                                isLive = true,
                            }
                            newFlight.key = MakePOIKey(mapID, newFlight)
                            rawList[#rawList + 1] = newFlight
                            if IsLiveFlightKnownState(nodeState) then
                                MarkPOINameVariantsFlight(n.name)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Merge live Blizzard/Forever AreaPOIs (transports, custom hubs, dungeons) if not already covered
    if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap and C_AreaPoiInfo.GetAreaPOIInfo then
        local okA, poiIDs = pcall(C_AreaPoiInfo.GetAreaPOIForMap, mapID)
        if okA and type(poiIDs) == "table" then
            for _, pid in ipairs(poiIDs) do
                local okI, pInfo = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, pid)
                if okI and type(pInfo) == "table" and pInfo.position and pInfo.position.GetXY and IsSafeStr(pInfo.name) then
                    local cat = InferLiveAreaPOICategory(pInfo)
                    if cat then
                        local nx, ny = pInfo.position:GetXY()
                        if IsSafeNum(nx) and IsSafeNum(ny) and nx > 0 and nx < 1 and ny > 0 and ny < 1 then
                            if not FindNearMatchingPOI(rawList, nx, ny, cat) then
                                local livePoi = {
                                    cat = cat,
                                    name = pInfo.name,
                                    faction = "Both",
                                    x = nx * 100,
                                    y = ny * 100,
                                    sub = IsSafeStr(pInfo.description) and pInfo.description or nil,
                                    isLive = true,
                                }
                                livePoi.key = MakePOIKey(mapID, livePoi)
                                rawList[#rawList + 1] = livePoi
                            end
                        end
                    end
                end
            end
        end
    end

    CheckPlayerProximityDiscovery(mapID, rawList)

    local out = {}
    for _, poi in ipairs(rawList) do
        poi.discovered = EvaluatePOIDiscovered(mapID, poi, isCapital, bindNorm)
        local include = true
        if not ignoreFilters then
            if not ShouldIncludeFaction(poi.faction, playerFaction, showOpposite) then
                include = false
            elseif not GetCategorySettingEnabled(poi.cat, s) then
                include = false
            elseif onlyUndisc and poi.discovered then
                include = false
            end
        end
        if include then
            out[#out + 1] = poi
        end
    end

    return out
end

function FP:GetZonePOIStats(mapID)
    local all = self:GetZonePOIs(mapID, true)
    local playerFaction = self.GetPlayerFaction and self:GetPlayerFaction() or nil
    local s = (NexusKitDB and NexusKitDB.settings) or {}
    local showOpposite = (s.zonePOIOppositeFaction == true)

    local total, undisc, undiscFlight, totalFlight, undiscInn, totalInn = 0, 0, 0, 0, 0, 0
    for _, poi in ipairs(all) do
        if ShouldIncludeFaction(poi.faction, playerFaction, showOpposite) and GetCategorySettingEnabled(poi.cat, s) then
            total = total + 1
            if not poi.discovered then undisc = undisc + 1 end
            if poi.cat == "flight" then
                totalFlight = totalFlight + 1
                if not poi.discovered then undiscFlight = undiscFlight + 1 end
            elseif poi.cat == "inn" then
                totalInn = totalInn + 1
                if not poi.discovered then undiscInn = undiscInn + 1 end
            end
        end
    end
    return {
        total = total,
        undiscovered = undisc,
        totalFlight = totalFlight,
        undiscFlight = undiscFlight,
        totalInn = totalInn,
        undiscInn = undiscInn,
    }
end

function FP:TogglePOIDiscovered(poi)
    if type(poi) ~= "table" or not IsSafeStr(poi.key) then return end
    local db = EnsureDiscoveryTables()
    if not db then return end

    local key = poi.key
    if poi.discovered then
        db.manualUndiscoveredPOIs[key] = true
        if poi.cat == "flight" then
            db.discoveredFlights[key] = nil
        else
            db.discoveredZonePOIs[key] = nil
        end
    else
        db.manualUndiscoveredPOIs[key] = nil
        if poi.cat == "flight" then
            db.discoveredFlights[key] = true
            MarkPOINameVariantsFlight(poi.name)
        else
            db.discoveredZonePOIs[key] = true
        end
    end

    if self.RefreshZonePOIs then
        self:RefreshZonePOIs()
    end
end

local function MarkNearestZonePOIDiscovered(cat, maxDist)
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    local pMapID = SafeCall(C_Map.GetBestMapForUnit, "player")
    if not IsSafeNum(pMapID) then return end
    local pos = SafeCall(C_Map.GetPlayerMapPosition, pMapID, "player")
    if not pos or not pos.GetXY then return end
    local px, py = pos:GetXY()
    if not IsSafeNum(px) or not IsSafeNum(py) or (px == 0 and py == 0) then return end

    local db = EnsureDiscoveryTables()
    if not db then return end

    local list = FP:GetZonePOIs(pMapID, true)
    local best, bestDistSq = nil, (maxDist or 0.045) ^ 2
    for _, poi in ipairs(list) do
        if not cat or poi.cat == cat then
            local dSq = ((poi.x / 100 - px) ^ 2) + ((poi.y / 100 - py) ^ 2)
            if dSq <= bestDistSq then
                bestDistSq = dSq
                best = poi
            end
        end
    end
    if best then
        db.manualUndiscoveredPOIs[best.key] = nil
        if best.cat == "flight" then
            db.discoveredFlights[best.key] = true
            MarkPOINameVariantsFlight(best.name)
        else
            db.discoveredZonePOIs[best.key] = true
        end
    end
end

local function RecordTaxiMapNodes()
    if not NumTaxiNodes or not TaxiNodeName then return end
    local okN, num = pcall(NumTaxiNodes)
    if not okN or not IsSafeNum(num) then return end
    EnsureDiscoveryTables()
    for i = 1, num do
        local nType = SafeCall(TaxiNodeGetType, i)
        if nType == "CURRENT" or nType == "REACHABLE" then
            local tName = SafeCall(TaxiNodeName, i)
            if IsSafeStr(tName) then
                MarkPOINameVariantsFlight(tName)
            end
        end
    end
    MarkNearestZonePOIDiscovered("flight", 0.05)
end

local discEv = CreateFrame("Frame")
local function RegDisc(e) pcall(discEv.RegisterEvent, discEv, e) end
RegDisc("TAXIMAP_OPENED")
RegDisc("UI_INFO_MESSAGE")
RegDisc("CONFIRM_BINDER")
RegDisc("HEARTHSTONE_BOUND")
RegDisc("MAIL_SHOW")
RegDisc("BANKFRAME_OPENED")
RegDisc("AUCTION_HOUSE_SHOW")
RegDisc("MERCHANT_SHOW")
RegDisc("GOSSIP_SHOW")
RegDisc("PLAYER_ENTERING_WORLD")

discEv:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "TAXIMAP_OPENED" then
        RecordTaxiMapNodes()
        if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
    elseif event == "UI_INFO_MESSAGE" then
        local msg = IsSafeStr(arg2) and arg2 or (IsSafeStr(arg1) and arg1 or nil)
        if msg then
            local newFlightStr = ERR_NEWTAXIPATH and string.lower(ERR_NEWTAXIPATH) or "new flight path"
            local low = string.lower(msg)
            if low:find("flight path", 1, true) or low:find("percorso di volo", 1, true) or low:find(newFlightStr, 1, true) then
                MarkNearestZonePOIDiscovered("flight", 0.05)
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end
        end
    elseif event == "CONFIRM_BINDER" or event == "HEARTHSTONE_BOUND" then
        MarkNearestZonePOIDiscovered("inn", 0.04)
        if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
    elseif event == "MAIL_SHOW" then
        MarkNearestZonePOIDiscovered("mailbox", 0.03)
    elseif event == "BANKFRAME_OPENED" then
        MarkNearestZonePOIDiscovered("bank", 0.04)
    elseif event == "AUCTION_HOUSE_SHOW" then
        MarkNearestZonePOIDiscovered("auction", 0.04)
    elseif event == "MERCHANT_SHOW" then
        MarkNearestZonePOIDiscovered("repair", 0.03)
    elseif event == "GOSSIP_SHOW" then
        MarkNearestZonePOIDiscovered("inn", 0.025)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local inInst = SafeCall(IsInInstance)
        if inInst then
            MarkNearestZonePOIDiscovered("dungeon", 0.06)
        end
    end
end)
