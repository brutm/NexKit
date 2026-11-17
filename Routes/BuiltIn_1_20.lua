-------------------------------------------------------------------------------
-- NexusKit - Built-in Leveling Routes (1-20)
-- Comprehensive demo routes for Alliance and Horde factions
-- Uses Classic WoW quest IDs, map IDs, and [0-100] coordinates
-------------------------------------------------------------------------------
local addonName, FP = ...

-------------------------------------------------------------------------------
-- ALLIANCE 1-20 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "ALLIANCE_1_20_OPTIMAL",
    title     = "Alliance 1-20 Optimal Speedrun",
    faction   = "Alliance",
    minLevel  = 1,
    maxLevel  = 20,
    steps = {
        ----------- Race-specific Start 1-5: Human (Elwynn Forest, mapID 1429)
        {
            id = 1001, action = "ACCEPT", text = "Accept 'A Threat Within' from Deputy Willem",
            mapID = 1429, x = 48.17, y = 42.94, questId = 783,
            races = {"HUMAN"},
        },
        {
            id = 1002, action = "COMPLETE", text = "Talk to Marshal McBride inside Northshire Abbey",
            mapID = 1429, x = 48.92, y = 41.61, questId = 783, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1003, action = "TURNIN", text = "Turn in 'A Threat Within' to Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 783,
            races = {"HUMAN"},
        },
        {
            id = 1004, action = "ACCEPT", text = "Accept 'Kobold Camp Cleanup' from Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 7,
            races = {"HUMAN"},
        },
        {
            id = 1005, action = "ACCEPT", text = "Accept 'Eagan Peltskinner' from Deputy Willem",
            mapID = 1429, x = 48.17, y = 42.94, questId = 5261,
            races = {"HUMAN"},
        },
        {
            id = 1006, action = "TURNIN", text = "Turn in 'Eagan Peltskinner' to Eagan Peltskinner",
            mapID = 1429, x = 48.94, y = 40.16, questId = 5261,
            races = {"HUMAN"},
        },
        {
            id = 1007, action = "ACCEPT", text = "Accept 'Wolves Across the Border' from Eagan",
            mapID = 1429, x = 48.94, y = 40.16, questId = 33,
            races = {"HUMAN"},
        },
        {
            id = 1008, action = "COMPLETE", text = "Kill 10 Kobold Vermin north of the Abbey",
            mapID = 1429, x = 51.43, y = 41.80, questId = 7, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1009, action = "COMPLETE", text = "Kill Timber Wolves for 8 Tough Wolf Meat",
            mapID = 1429, x = 50.12, y = 39.68, questId = 33, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1010, action = "TURNIN", text = "Turn in 'Wolves Across the Border' to Eagan",
            mapID = 1429, x = 48.94, y = 40.16, questId = 33,
            races = {"HUMAN"},
        },
        {
            id = 1011, action = "TURNIN", text = "Turn in 'Kobold Camp Cleanup' to Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 7,
            races = {"HUMAN"},
        },
        {
            id = 1012, action = "ACCEPT", text = "Accept 'Investigate Echo Ridge' from Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 15,
            races = {"HUMAN"},
        },
        {
            id = 1013, action = "COMPLETE", text = "Kill 10 Kobold Workers near Echo Ridge Mine",
            mapID = 1429, x = 52.38, y = 35.24, questId = 15, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1014, action = "TURNIN", text = "Turn in 'Investigate Echo Ridge' to Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 15,
            races = {"HUMAN"},
        },
        {
            id = 1015, action = "ACCEPT", text = "Accept 'Skirmish at Echo Ridge' from Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 21,
            races = {"HUMAN"},
        },
        {
            id = 1016, action = "ACCEPT", text = "Accept 'Brotherhood of Thieves' from Deputy Willem",
            mapID = 1429, x = 48.17, y = 42.94, questId = 18,
            races = {"HUMAN"},
        },
        {
            id = 1017, action = "COMPLETE", text = "Kill Defias across the river for 12 Red Burlap Bandanas",
            mapID = 1429, x = 54.80, y = 46.52, questId = 18, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1018, action = "COMPLETE", text = "Kill 12 Kobold Laborers inside Echo Ridge Mine",
            mapID = 1429, x = 53.10, y = 34.80, questId = 21, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1019, action = "TURNIN", text = "Turn in 'Brotherhood of Thieves' to Deputy Willem",
            mapID = 1429, x = 48.17, y = 42.94, questId = 18,
            races = {"HUMAN"},
        },
        {
            id = 1020, action = "ACCEPT", text = "Accept 'Milly Osworth' from Deputy Willem",
            mapID = 1429, x = 48.17, y = 42.94, questId = 3903,
            races = {"HUMAN"},
        },
        {
            id = 1021, action = "TURNIN", text = "Turn in 'Skirmish at Echo Ridge' to Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 21,
            races = {"HUMAN"},
        },
        {
            id = 1022, action = "ACCEPT", text = "Accept 'Report to Goldshire' from Marshal McBride",
            mapID = 1429, x = 48.92, y = 41.61, questId = 54,
            races = {"HUMAN"},
        },
        {
            id = 1023, action = "TURNIN", text = "Turn in 'Milly Osworth' to Milly Osworth",
            mapID = 1429, x = 50.67, y = 39.33, questId = 3903,
            races = {"HUMAN"},
        },
        {
            id = 1024, action = "ACCEPT", text = "Accept 'Milly's Harvest' from Milly Osworth",
            mapID = 1429, x = 50.67, y = 39.33, questId = 3904,
            races = {"HUMAN"},
        },
        {
            id = 1025, action = "COMPLETE", text = "Collect 8 crates of Milly's Harvest from the vineyard",
            mapID = 1429, x = 54.22, y = 46.84, questId = 3904, objectiveIndex = 1,
            races = {"HUMAN"},
        },
        {
            id = 1026, action = "TURNIN", text = "Turn in 'Milly's Harvest' to Milly Osworth",
            mapID = 1429, x = 50.67, y = 39.33, questId = 3904,
            races = {"HUMAN"},
        },
        {
            id = 1027, action = "GRIND", text = "Grind to level 5.5 on Kobolds/Defias if needed",
            mapID = 1429, x = 50.00, y = 45.00, targetLevel = 5.5,
            races = {"HUMAN"},
        },

        ----------- Race-specific Start 1-5: Dwarf / Gnome (Dun Morogh, mapID 1426)
        {
            id = 1099, action = "ACCEPT", text = "Accept 'Dwarven Outfitters' from Sten Stoutarm (Coldridge Valley)",
            mapID = 1426, x = 29.92, y = 71.24, questId = 179,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1100, action = "COMPLETE", text = "Kill Wolves for Tough Wolf Meat in Coldridge Valley",
            mapID = 1426, x = 32.40, y = 75.90, questId = 179, objectiveIndex = 1,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1101, action = "TURNIN", text = "Turn in 'Dwarven Outfitters' to Sten Stoutarm",
            mapID = 1426, x = 29.92, y = 71.24, questId = 179,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1102, action = "ACCEPT", text = "Accept 'Coldridge Valley Mail Delivery' from Sten Stoutarm",
            mapID = 1426, x = 29.92, y = 71.24, questId = 233,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1103, action = "TURNIN", text = "Turn in 'Coldridge Valley Mail Delivery' to Talin Keeneye",
            mapID = 1426, x = 22.62, y = 71.84, questId = 233,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1104, action = "ACCEPT", text = "Accept 'The Boar Hunter' from Talin Keeneye",
            mapID = 1426, x = 22.62, y = 71.84, questId = 183,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1105, action = "COMPLETE", text = "Kill 12 Small Crag Boars",
            mapID = 1426, x = 25.10, y = 66.30, questId = 183, objectiveIndex = 1,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1106, action = "TURNIN", text = "Turn in 'The Boar Hunter' to Talin Keeneye",
            mapID = 1426, x = 22.62, y = 71.84, questId = 183,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1107, action = "GRIND", text = "Grind to level 5.5 in Coldridge Valley",
            mapID = 1426, x = 27.00, y = 74.00, targetLevel = 5.5,
            races = {"DWARF", "GNOME"},
        },
        {
            id = 1108, action = "GOTO", text = "Travel to Ironforge and take the Deeprun Tram to Stormwind",
            mapID = 1426, x = 53.50, y = 34.80,
            races = {"DWARF", "GNOME"},
        },

        ----------- Race-specific Start 1-5: Night Elf (Shadowglen, Teldrassil, mapID 1438)
        {
            id = 1201, action = "ACCEPT", text = "Accept 'The Balance of Nature' from Conservator Ilthalaine",
            mapID = 1438, x = 58.00, y = 43.60, questId = 456,
            races = {"NIGHTELF"},
        },
        {
            id = 1202, action = "COMPLETE", text = "Kill 7 Young Nightsabers and 4 Mangy Nightsabers",
            mapID = 1438, x = 58.50, y = 42.00, questId = 456, objectiveIndex = 1,
            races = {"NIGHTELF"},
        },
        {
            id = 1203, action = "TURNIN", text = "Turn in 'The Balance of Nature' to Conservator Ilthalaine",
            mapID = 1438, x = 58.00, y = 43.60, questId = 456,
            races = {"NIGHTELF"},
        },
        {
            id = 1204, action = "ACCEPT", text = "Accept 'The Balance of Nature (Part 2)'",
            mapID = 1438, x = 58.00, y = 43.60, questId = 457,
            races = {"NIGHTELF"},
        },
        {
            id = 1205, action = "COMPLETE", text = "Kill 7 Young Thistle Boars",
            mapID = 1438, x = 57.20, y = 44.80, questId = 457, objectiveIndex = 1,
            races = {"NIGHTELF"},
        },
        {
            id = 1206, action = "TURNIN", text = "Turn in 'The Balance of Nature (Part 2)'",
            mapID = 1438, x = 58.00, y = 43.60, questId = 457,
            races = {"NIGHTELF"},
        },
        {
            id = 1207, action = "ACCEPT", text = "Accept 'The Woodland Protector' from Tarindrella",
            mapID = 1438, x = 57.60, y = 42.00, questId = 458,
            races = {"NIGHTELF"},
        },
        {
            id = 1208, action = "TURNIN", text = "Turn in 'The Woodland Protector' to Tarindrella",
            mapID = 1438, x = 57.60, y = 42.00, questId = 458,
            races = {"NIGHTELF"},
        },
        {
            id = 1209, action = "ACCEPT", text = "Accept 'A Good Friend' from Iverron",
            mapID = 1438, x = 56.40, y = 43.60, questId = 459,
            races = {"NIGHTELF"},
        },
        {
            id = 1210, action = "COMPLETE", text = "Find Hyacinth Mushrooms for Iverron",
            mapID = 1438, x = 55.40, y = 44.20, questId = 459, objectiveIndex = 1,
            races = {"NIGHTELF"},
        },
        {
            id = 1211, action = "TURNIN", text = "Turn in 'A Good Friend' to Iverron",
            mapID = 1438, x = 56.40, y = 43.60, questId = 459,
            races = {"NIGHTELF"},
        },
        {
            id = 1212, action = "ACCEPT", text = "Accept 'Crown of the Earth' from Corithras Moonrage",
            mapID = 1438, x = 57.40, y = 41.80, questId = 487,
            races = {"NIGHTELF"},
        },
        {
            id = 1213, action = "COMPLETE", text = "Fill Crystal Phial at the Shadowglen Moonwell",
            mapID = 1438, x = 59.80, y = 33.40, questId = 487, objectiveIndex = 1,
            races = {"NIGHTELF"},
        },
        {
            id = 1214, action = "TURNIN", text = "Turn in 'Crown of the Earth' to Corithras Moonrage",
            mapID = 1438, x = 57.40, y = 41.80, questId = 487,
            races = {"NIGHTELF"},
        },
        {
            id = 1215, action = "GOTO", text = "Take the boat from Rut'theran Village to Auberdine, then Menethil Harbor -> Ironforge -> Stormwind",
            mapID = 1438, x = 58.40, y = 94.00,
            races = {"NIGHTELF"},
        },

        ----------- Transition to Goldshire (Shared 6-20) ---------------
        {
            id = 1028, action = "GOTO", text = "Run to Goldshire in Elwynn Forest",
            mapID = 1429, x = 42.10, y = 65.93,
        },
        {
            id = 1029, action = "SET_HEARTH", text = "Set Hearthstone at Goldshire Inn",
            mapID = 1429, x = 42.70, y = 65.63, minLevel = 5,
        },
        {
            id = 1030, action = "TURNIN", text = "Turn in 'Report to Goldshire' to Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 54,
            races = {"HUMAN"},
        },
        {
            id = 1031, action = "TRAIN", text = "Train Warrior skills at Goldshire (level 6)",
            mapID = 1429, x = 41.09, y = 65.77, minLevel = 6,
            classes = {"WARRIOR"},
        },
        {
            id = 1032, action = "TRAIN", text = "Train Mage skills at Goldshire Inn (level 6)",
            mapID = 1429, x = 43.25, y = 66.20, minLevel = 6,
            classes = {"MAGE"},
        },
        {
            id = 1033, action = "TRAIN", text = "Train Rogue skills at Goldshire Inn (level 6)",
            mapID = 1429, x = 43.87, y = 65.94, minLevel = 6,
            classes = {"ROGUE"},
        },
        {
            id = 1034, action = "TRAIN", text = "Train Warlock skills in Goldshire basement (level 6)",
            mapID = 1429, x = 44.39, y = 66.25, minLevel = 6,
            classes = {"WARLOCK"},
        },

        ----------- Goldshire / Elwynn Quests ---------------
        {
            id = 1035, action = "ACCEPT", text = "Accept 'The Fargodeep Mine' from Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 62,
        },
        {
            id = 1036, action = "ACCEPT", text = "Accept 'Gold Dust Exchange' from Remy \"Two Times\"",
            mapID = 1429, x = 42.14, y = 67.25, questId = 47,
        },
        {
            id = 1037, action = "GOTO", text = "Go to Fargodeep Mine south of Goldshire",
            mapID = 1429, x = 39.82, y = 81.52,
        },
        {
            id = 1038, action = "COMPLETE", text = "Kill Kobolds for 10 Gold Dust",
            mapID = 1429, x = 39.82, y = 81.52, questId = 47, objectiveIndex = 1,
        },
        {
            id = 1039, action = "COMPLETE", text = "Scout inside Fargodeep Mine for Marshal Dughan",
            mapID = 1429, x = 39.82, y = 81.52, questId = 62, objectiveIndex = 1,
        },
        {
            id = 1040, action = "TURNIN", text = "Turn in 'Gold Dust Exchange' to Remy \"Two Times\"",
            mapID = 1429, x = 42.14, y = 67.25, questId = 47,
        },
        {
            id = 1041, action = "TURNIN", text = "Turn in 'The Fargodeep Mine' to Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 62,
        },
        {
            id = 1042, action = "ACCEPT", text = "Accept 'The Jasperlode Mine' from Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 76,
        },
        {
            id = 1043, action = "ACCEPT", text = "Accept 'Westbrook Garrison Needs Help!' from Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 239,
        },
        {
            id = 1044, action = "GOTO", text = "Go to Jasperlode Mine northeast of Goldshire",
            mapID = 1429, x = 60.83, y = 50.23,
        },
        {
            id = 1045, action = "COMPLETE", text = "Explore Jasperlode Mine",
            mapID = 1429, x = 60.83, y = 50.23, questId = 76, objectiveIndex = 1,
        },
        {
            id = 1046, action = "TURNIN", text = "Turn in 'The Jasperlode Mine' to Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 76,
        },
        {
            id = 1047, action = "GOTO", text = "Go to Westbrook Garrison southwest of Goldshire",
            mapID = 1429, x = 24.24, y = 74.45,
        },
        {
            id = 1048, action = "TURNIN", text = "Turn in 'Westbrook Garrison Needs Help!' to Deputy Rainer",
            mapID = 1429, x = 24.24, y = 74.45, questId = 239,
        },
        {
            id = 1049, action = "ACCEPT", text = "Accept 'Riverpaw Gnoll Bounty' from Deputy Rainer",
            mapID = 1429, x = 24.24, y = 74.45, questId = 11,
        },
        {
            id = 1050, action = "COMPLETE", text = "Kill Riverpaw Gnolls for 8 Painted Gnoll Armbands",
            mapID = 1429, x = 22.18, y = 78.30, questId = 11, objectiveIndex = 1,
        },
        {
            id = 1051, action = "TURNIN", text = "Turn in 'Riverpaw Gnoll Bounty' to Deputy Rainer",
            mapID = 1429, x = 24.24, y = 74.45, questId = 11,
        },
        {
            id = 1052, action = "TRAIN", text = "Train Warrior skills at Goldshire / Stormwind (level 10)",
            mapID = 1429, x = 41.09, y = 65.77, minLevel = 10,
            classes = {"WARRIOR"},
        },
        {
            id = 1053, action = "TRAIN", text = "Train Hunter skills and complete Pet quest (level 10)",
            mapID = 1453, x = 61.60, y = 15.20, minLevel = 10,
            classes = {"HUNTER"},
        },
        {
            id = 1054, action = "TRAIN", text = "Train Mage skills in Goldshire / Stormwind (level 10)",
            mapID = 1429, x = 43.25, y = 66.20, minLevel = 10,
            classes = {"MAGE"},
        },
        {
            id = 1055, action = "TRAIN", text = "Train Rogue skills in Goldshire / Stormwind (level 10)",
            mapID = 1429, x = 43.87, y = 65.94, minLevel = 10,
            classes = {"ROGUE"},
        },
        {
            id = 1056, action = "GRIND", text = "Grind to level 10.0 on Murlocs/Gnolls near Goldshire",
            mapID = 1429, x = 35.50, y = 72.00, targetLevel = 10.0,
        },

        ----------- Transition to Westfall (mapID 1436) ---------------
        {
            id = 1057, action = "ACCEPT", text = "Accept 'Report to Gryan Stonemantle' from Marshal Dughan",
            mapID = 1429, x = 42.10, y = 65.93, questId = 109,
        },
        {
            id = 1058, action = "GOTO", text = "Travel west across the bridge into Westfall to Sentinel Hill",
            mapID = 1436, x = 56.33, y = 47.52,
        },
        {
            id = 1059, action = "SET_HEARTH", text = "Set Hearthstone at Sentinel Hill Inn",
            mapID = 1436, x = 52.81, y = 53.58, minLevel = 10,
        },
        {
            id = 1060, action = "TURNIN", text = "Turn in 'Report to Gryan Stonemantle' to Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 109,
        },
        {
            id = 1061, action = "ACCEPT", text = "Accept 'The People's Militia' from Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 12,
        },
        {
            id = 1062, action = "ACCEPT", text = "Accept 'Red Leather Bandanas' from Scout Galiaan",
            mapID = 1436, x = 56.55, y = 47.11, questId = 153,
        },
        {
            id = 1063, action = "ACCEPT", text = "Accept 'Patrolling Westfall' from Captain Danuvin",
            mapID = 1436, x = 56.42, y = 47.62, questId = 102,
            isOptional = true, maxSkipLevel = 15,
        },
        {
            id = 1064, action = "COMPLETE", text = "Kill Defias for 15 Red Leather Bandanas",
            mapID = 1436, x = 49.12, y = 43.50, questId = 153, objectiveIndex = 1,
        },
        {
            id = 1065, action = "COMPLETE", text = "Kill 15 Defias Trappers and 15 Defias Smugglers",
            mapID = 1436, x = 44.20, y = 55.60, questId = 12,
        },
        {
            id = 1066, action = "TURNIN", text = "Turn in 'Red Leather Bandanas' to Scout Galiaan",
            mapID = 1436, x = 56.55, y = 47.11, questId = 153,
        },
        {
            id = 1067, action = "TURNIN", text = "Turn in 'The People's Militia' to Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 12,
        },
        {
            id = 1068, action = "ACCEPT", text = "Accept 'The People's Militia (Part 2)' from Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 13,
        },
        {
            id = 1069, action = "ACCEPT", text = "Accept 'The Defias Brotherhood' from Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 65,
            isOptional = true, maxSkipLevel = 18,
        },
        {
            id = 1070, action = "ACCEPT", text = "Accept 'Westfall Stew' from Verna Furlbrow",
            mapID = 1436, x = 59.83, y = 19.26, questId = 38,
        },
        {
            id = 1071, action = "ACCEPT", text = "Accept 'Poor Old Blanchy' from Verna Furlbrow",
            mapID = 1436, x = 59.83, y = 19.26, questId = 151,
            isOptional = true, maxSkipLevel = 15,
        },
        {
            id = 1072, action = "COMPLETE", text = "Collect Westfall Stew ingredients (Snouts, Livers, Okra, Eyes)",
            mapID = 1436, x = 48.20, y = 38.90, questId = 38,
        },
        {
            id = 1073, action = "COMPLETE", text = "Kill Defias Highwaymen and Pathstalkers",
            mapID = 1436, x = 39.50, y = 51.30, questId = 13,
        },
        {
            id = 1074, action = "TURNIN", text = "Turn in 'Westfall Stew' to Verna Furlbrow",
            mapID = 1436, x = 59.83, y = 19.26, questId = 38,
        },
        {
            id = 1075, action = "USE_HEARTH", text = "Use Hearthstone back to Sentinel Hill",
            mapID = 1436, x = 52.81, y = 53.58, minLevel = 12, itemID = 6948,
        },
        {
            id = 1076, action = "TURNIN", text = "Turn in 'The People's Militia (Part 2)' to Gryan Stonemantle",
            mapID = 1436, x = 56.33, y = 47.52, questId = 13,
        },
        {
            id = 1077, action = "GRIND", text = "Grind to level 15.0 on Defias near Moonbrook",
            mapID = 1436, x = 42.00, y = 68.30, targetLevel = 15.0,
        },

        ----------- Level 15 - Redridge Mountains (mapID 1433) ---------------
        {
            id = 1078, action = "TRAIN", text = "Train class skills in Stormwind (level 14)",
            mapID = 1453, x = 62.50, y = 72.10, minLevel = 14,
            classes = {"WARRIOR", "MAGE", "ROGUE", "WARLOCK", "PRIEST", "PALADIN", "HUNTER", "DRUID"},
        },
        {
            id = 1079, action = "FLY", text = "Fly from Sentinel Hill to Lakeshire (Redridge)",
            mapID = 1436, x = 56.56, y = 52.65,
        },
        {
            id = 1080, action = "GOTO", text = "Arrive in Lakeshire, Redridge Mountains",
            mapID = 1433, x = 30.59, y = 59.41,
        },
        {
            id = 1098, action = "TURNIN", text = "Turn in 'The Defias Brotherhood' to Wiley the Black",
            mapID = 1433, x = 26.50, y = 45.30, questId = 65,
            isOptional = true, maxSkipLevel = 22,
        },
        {
            id = 1081, action = "ACCEPT", text = "Accept 'Encroaching Gnolls' from Deputy Feldon",
            mapID = 1433, x = 30.59, y = 59.41, questId = 244,
        },
        {
            id = 1082, action = "ACCEPT", text = "Accept 'Assessing the Threat' from Magistrate Solomon",
            mapID = 1433, x = 29.99, y = 44.44, questId = 246,
        },
        {
            id = 1083, action = "ACCEPT", text = "Accept 'The Price of Shoes' from Verner Osgood",
            mapID = 1433, x = 31.06, y = 47.31, questId = 118,
            isOptional = true, maxSkipLevel = 20,
        },
        {
            id = 1084, action = "COMPLETE", text = "Kill 10 Redridge Mongrels and 6 Poachers",
            mapID = 1433, x = 36.20, y = 63.10, questId = 246,
        },
        {
            id = 1085, action = "COMPLETE", text = "Report to Guard Parker at Three Corners",
            mapID = 1433, x = 15.30, y = 71.40, questId = 244, objectiveIndex = 1,
        },
        {
            id = 1086, action = "TURNIN", text = "Turn in 'Encroaching Gnolls' to Guard Parker",
            mapID = 1433, x = 15.30, y = 71.40, questId = 244,
        },
        {
            id = 1087, action = "TURNIN", text = "Turn in 'Assessing the Threat' to Magistrate Solomon",
            mapID = 1433, x = 29.99, y = 44.44, questId = 246,
        },
        {
            id = 1088, action = "ACCEPT", text = "Accept 'Shadow Magic' from Marshal Marris",
            mapID = 1433, x = 33.50, y = 49.00, questId = 115,
        },
        {
            id = 1089, action = "ACCEPT", text = "Accept 'Wanted: Lieutenant Fangore' (wanted poster)",
            mapID = 1433, x = 26.98, y = 46.51, questId = 180,
            isOptional = true, maxSkipLevel = 20,
        },
        {
            id = 1090, action = "COMPLETE", text = "Kill Shadowhide Gnolls and collect 3 Midnight Orbs",
            mapID = 1433, x = 79.60, y = 48.00, questId = 115, objectiveIndex = 1,
        },
        {
            id = 1091, action = "COMPLETE", text = "Kill Lieutenant Fangore for Fangore's Paw",
            mapID = 1433, x = 80.10, y = 39.30, questId = 180, objectiveIndex = 1,
            isOptional = true, maxSkipLevel = 20,
        },
        {
            id = 1092, action = "TURNIN", text = "Turn in 'Shadow Magic' to Marshal Marris",
            mapID = 1433, x = 33.50, y = 49.00, questId = 115,
        },
        {
            id = 1093, action = "GRIND", text = "Grind to level 18.0 on Gnolls and Blackrock Orcs",
            mapID = 1433, x = 35.00, y = 25.00, targetLevel = 18.0,
        },
        {
            id = 1094, action = "TRAIN", text = "Train Rogue Poison quest & skills in Stormwind (level 20)",
            mapID = 1453, x = 75.80, y = 59.80, minLevel = 20,
            classes = {"ROGUE"},
        },
        {
            id = 1095, action = "TRAIN", text = "Train Warrior skills in Stormwind (level 20)",
            mapID = 1453, x = 78.60, y = 45.70, minLevel = 20,
            classes = {"WARRIOR"},
        },
        {
            id = 1096, action = "TRAIN", text = "Train class skills in Stormwind (level 20)",
            mapID = 1453, x = 49.60, y = 87.20, minLevel = 20,
            classes = {"MAGE", "WARLOCK", "PRIEST", "PALADIN"},
        },
        {
            id = 1097, action = "GRIND", text = "Grind to level 20.0 on Blackrock Orcs east of Lakeshire",
            mapID = 1433, x = 61.40, y = 37.80, targetLevel = 20.0,
        },
    },
})

-------------------------------------------------------------------------------
-- HORDE 1-20 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "HORDE_1_20_OPTIMAL",
    title     = "Horde 1-20 Optimal Speedrun",
    faction   = "Horde",
    minLevel  = 1,
    maxLevel  = 20,
    steps = {
        ----------- Race-specific Start 1-5: Orc / Troll (Durotar, mapID 1411)
        {
            id = 2001, action = "ACCEPT", text = "Accept 'Your Place In The World' from Kaltunk",
            mapID = 1411, x = 43.30, y = 68.53, questId = 4641,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2002, action = "COMPLETE", text = "Speak with Gornek in Valley of Trials",
            mapID = 1411, x = 42.06, y = 68.32, questId = 4641, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2003, action = "TURNIN", text = "Turn in 'Your Place In The World' to Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 4641,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2004, action = "ACCEPT", text = "Accept 'Cutting Teeth' from Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 788,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2005, action = "COMPLETE", text = "Kill 10 Mottled Boars",
            mapID = 1411, x = 44.50, y = 66.10, questId = 788, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2006, action = "TURNIN", text = "Turn in 'Cutting Teeth' to Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 788,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2007, action = "ACCEPT", text = "Accept 'Sarkoth' from Hana'zua",
            mapID = 1411, x = 40.58, y = 62.57, questId = 790,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2008, action = "COMPLETE", text = "Kill Sarkoth the scorpid and loot Sarkoth's Mangled Claw",
            mapID = 1411, x = 40.93, y = 60.60, questId = 790, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2009, action = "TURNIN", text = "Turn in 'Sarkoth' to Hana'zua",
            mapID = 1411, x = 40.58, y = 62.57, questId = 790,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2010, action = "ACCEPT", text = "Accept 'Sarkoth (Part 2)' from Hana'zua",
            mapID = 1411, x = 40.58, y = 62.57, questId = 804,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2011, action = "TURNIN", text = "Turn in 'Sarkoth (Part 2)' to Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 804,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2012, action = "ACCEPT", text = "Accept 'Sting of the Scorpid' from Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 789,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2013, action = "ACCEPT", text = "Accept 'Vile Familiars' from Zureetha Fargaze",
            mapID = 1411, x = 42.78, y = 69.30, questId = 792,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2014, action = "ACCEPT", text = "Accept 'Galgar's Cactus Apple Surprise' from Galgar",
            mapID = 1411, x = 42.90, y = 67.22, questId = 4402,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2015, action = "COMPLETE", text = "Collect 10 Cactus Apples around the valley",
            mapID = 1411, x = 45.60, y = 63.40, questId = 4402, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2016, action = "COMPLETE", text = "Kill Scorpids for 10 Scorpid Worker Tails",
            mapID = 1411, x = 45.10, y = 61.50, questId = 789, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2017, action = "COMPLETE", text = "Kill 12 Vile Familiars outside the cave",
            mapID = 1411, x = 47.22, y = 57.10, questId = 792, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2018, action = "TURNIN", text = "Turn in 'Galgar's Cactus Apple Surprise' to Galgar",
            mapID = 1411, x = 42.90, y = 67.22, questId = 4402,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2019, action = "TURNIN", text = "Turn in 'Sting of the Scorpid' to Gornek",
            mapID = 1411, x = 42.06, y = 68.32, questId = 789,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2020, action = "TURNIN", text = "Turn in 'Vile Familiars' to Zureetha Fargaze",
            mapID = 1411, x = 42.78, y = 69.30, questId = 792,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2021, action = "ACCEPT", text = "Accept 'Burning Blade Medallion' from Zureetha Fargaze",
            mapID = 1411, x = 42.78, y = 69.30, questId = 794,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2022, action = "COMPLETE", text = "Kill Yarrog Baneshadow in the cave for Burning Blade Medallion",
            mapID = 1411, x = 47.22, y = 54.30, questId = 794, objectiveIndex = 1,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2023, action = "TURNIN", text = "Turn in 'Burning Blade Medallion' to Zureetha Fargaze",
            mapID = 1411, x = 42.78, y = 69.30, questId = 794,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2024, action = "ACCEPT", text = "Accept 'Report to Sen'jin Village' from Zureetha Fargaze",
            mapID = 1411, x = 42.78, y = 69.30, questId = 805,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2025, action = "GRIND", text = "Grind to level 5.5 on Scorpids/Boars if needed",
            mapID = 1411, x = 44.00, y = 64.00, targetLevel = 5.5,
            races = {"ORC", "TROLL"},
        },

        ----------- Race-specific Start 1-5: Undead (Tirisfal Glades, mapID 1420)
        {
            id = 2097, action = "ACCEPT", text = "Accept 'Rude Awakening' from Undertaker Mordo (Deathknell)",
            mapID = 1420, x = 30.24, y = 71.64, questId = 363,
            races = {"UNDEAD"},
        },
        {
            id = 2098, action = "COMPLETE", text = "Speak with Shadow Priest Sarvis in the chapel",
            mapID = 1420, x = 31.68, y = 65.62, questId = 363, objectiveIndex = 1,
            races = {"UNDEAD"},
        },
        {
            id = 2099, action = "TURNIN", text = "Turn in 'Rude Awakening' to Shadow Priest Sarvis",
            mapID = 1420, x = 31.68, y = 65.62, questId = 363,
            races = {"UNDEAD"},
        },
        {
            id = 2100, action = "ACCEPT", text = "Accept 'The Mindless Ones' from Shadow Priest Sarvis",
            mapID = 1420, x = 31.68, y = 65.62, questId = 364,
            races = {"UNDEAD"},
        },
        {
            id = 2101, action = "COMPLETE", text = "Kill 8 Mindless Zombies and 8 Wretched Zombies",
            mapID = 1420, x = 32.50, y = 60.10, questId = 364,
            races = {"UNDEAD"},
        },
        {
            id = 2102, action = "TURNIN", text = "Turn in 'The Mindless Ones' to Shadow Priest Sarvis",
            mapID = 1420, x = 31.68, y = 65.62, questId = 364,
            races = {"UNDEAD"},
        },
        {
            id = 2103, action = "ACCEPT", text = "Accept 'Rattling the Rattlecages' from Novice Elreth",
            mapID = 1420, x = 31.92, y = 66.32, questId = 3901,
            races = {"UNDEAD"},
        },
        {
            id = 2104, action = "COMPLETE", text = "Kill 12 Rattlecage Skeletons",
            mapID = 1420, x = 29.80, y = 58.30, questId = 3901, objectiveIndex = 1,
            races = {"UNDEAD"},
        },
        {
            id = 2105, action = "TURNIN", text = "Turn in 'Rattling the Rattlecages' to Novice Elreth",
            mapID = 1420, x = 31.92, y = 66.32, questId = 3901,
            races = {"UNDEAD"},
        },
        {
            id = 2106, action = "GOTO", text = "Travel to Brill and take the Zeppelin to Orgrimmar",
            mapID = 1420, x = 60.82, y = 52.12,
            races = {"UNDEAD"},
        },

        ----------- Race-specific Start 1-5: Tauren (Mulgore, mapID 1412)
        {
            id = 2107, action = "ACCEPT", text = "Accept 'The Hunt Begins' from Grull Hawkwind (Camp Narache)",
            mapID = 1412, x = 44.95, y = 76.04, questId = 747,
            races = {"TAUREN"},
        },
        {
            id = 2108, action = "COMPLETE", text = "Kill Plainstriders for 7 Meat and 7 Feathers",
            mapID = 1412, x = 48.10, y = 72.30, questId = 747,
            races = {"TAUREN"},
        },
        {
            id = 2109, action = "TURNIN", text = "Turn in 'The Hunt Begins' to Grull Hawkwind",
            mapID = 1412, x = 44.95, y = 76.04, questId = 747,
            races = {"TAUREN"},
        },
        {
            id = 2110, action = "ACCEPT", text = "Accept 'The Hunt Continues' from Grull Hawkwind",
            mapID = 1412, x = 44.95, y = 76.04, questId = 750,
            races = {"TAUREN"},
        },
        {
            id = 2111, action = "COMPLETE", text = "Kill Mountain Cougars for 10 Cougar Pelts",
            mapID = 1412, x = 49.30, y = 68.50, questId = 750, objectiveIndex = 1,
            races = {"TAUREN"},
        },
        {
            id = 2112, action = "TURNIN", text = "Turn in 'The Hunt Continues' to Grull Hawkwind",
            mapID = 1412, x = 44.95, y = 76.04, questId = 750,
            races = {"TAUREN"},
        },
        {
            id = 2113, action = "ACCEPT", text = "Accept 'The Battleboars' from Chief Hawkwind",
            mapID = 1412, x = 44.55, y = 77.06, questId = 780,
            races = {"TAUREN"},
        },
        {
            id = 2114, action = "COMPLETE", text = "Kill Battleboars at Brambleblade Ravine for flanks and snouts",
            mapID = 1412, x = 54.30, y = 80.20, questId = 780,
            races = {"TAUREN"},
        },
        {
            id = 2115, action = "TURNIN", text = "Turn in 'The Battleboars' to Chief Hawkwind",
            mapID = 1412, x = 44.55, y = 77.06, questId = 780,
            races = {"TAUREN"},
        },
        {
            id = 2116, action = "GOTO", text = "Travel to Bloodhoof Village and east into The Barrens / Durotar",
            mapID = 1412, x = 47.52, y = 58.85,
            races = {"TAUREN"},
        },

        ----------- Transition to Razor Hill (Shared 6-20) ---------------
        {
            id = 2026, action = "GOTO", text = "Run to Razor Hill in Durotar",
            mapID = 1411, x = 51.96, y = 41.72,
        },
        {
            id = 2027, action = "SET_HEARTH", text = "Set Hearthstone at Razor Hill Inn",
            mapID = 1411, x = 51.58, y = 41.58, minLevel = 5,
        },
        {
            id = 2028, action = "TRAIN", text = "Train Warrior skills at Razor Hill (level 6)",
            mapID = 1411, x = 54.18, y = 42.50, minLevel = 6,
            classes = {"WARRIOR"},
        },
        {
            id = 2029, action = "TRAIN", text = "Train Hunter skills at Razor Hill (level 6)",
            mapID = 1411, x = 51.85, y = 43.49, minLevel = 6,
            classes = {"HUNTER"},
        },
        {
            id = 2030, action = "TRAIN", text = "Train Shaman skills at Razor Hill (level 6)",
            mapID = 1411, x = 54.39, y = 42.42, minLevel = 6,
            classes = {"SHAMAN"},
        },
        {
            id = 2031, action = "TRAIN", text = "Train Rogue skills at Razor Hill (level 6)",
            mapID = 1411, x = 52.00, y = 43.70, minLevel = 6,
            classes = {"ROGUE"},
        },

        ----------- Razor Hill / Durotar Quests ---------------
        {
            id = 2032, action = "ACCEPT", text = "Accept 'Dark Storms' from Orgnil Soulscar",
            mapID = 1411, x = 52.26, y = 43.33, questId = 806,
        },
        {
            id = 2033, action = "ACCEPT", text = "Accept 'Vanquish the Betrayers' from Gar'Thok",
            mapID = 1411, x = 51.96, y = 43.49, questId = 784,
        },
        {
            id = 2034, action = "ACCEPT", text = "Accept 'Encroachment' from Gar'Thok",
            mapID = 1411, x = 51.96, y = 43.49, questId = 837,
        },
        {
            id = 2035, action = "GOTO", text = "Go to Tiragarde Keep southeast of Razor Hill",
            mapID = 1411, x = 59.10, y = 58.20,
        },
        {
            id = 2036, action = "COMPLETE", text = "Kill Kul Tiras Sailors, Marines, and Lieutenant Benedict",
            mapID = 1411, x = 59.10, y = 58.20, questId = 784,
        },
        {
            id = 2037, action = "TURNIN", text = "Turn in 'Vanquish the Betrayers' to Gar'Thok",
            mapID = 1411, x = 51.96, y = 43.49, questId = 784,
        },
        {
            id = 2038, action = "TURNIN", text = "Turn in 'Report to Sen'jin Village' to Master Gadrin",
            mapID = 1411, x = 55.97, y = 74.72, questId = 805,
            races = {"ORC", "TROLL"},
        },
        {
            id = 2039, action = "ACCEPT", text = "Accept 'Zalazane' from Master Gadrin",
            mapID = 1411, x = 55.97, y = 74.72, questId = 826,
        },
        {
            id = 2040, action = "ACCEPT", text = "Accept 'Minshina's Skull' from Master Gadrin",
            mapID = 1411, x = 55.97, y = 74.72, questId = 808,
        },
        {
            id = 2041, action = "GOTO", text = "Cross the water to Echo Isles",
            mapID = 1411, x = 67.10, y = 74.80,
        },
        {
            id = 2042, action = "COMPLETE", text = "Find Minshina's Skull on Echo Isles",
            mapID = 1411, x = 67.50, y = 87.60, questId = 808, objectiveIndex = 1,
        },
        {
            id = 2043, action = "COMPLETE", text = "Kill Zalazane on the southern Echo Isle",
            mapID = 1411, x = 67.40, y = 86.50, questId = 826, objectiveIndex = 1,
        },
        {
            id = 2044, action = "TURNIN", text = "Turn in 'Minshina's Skull' to Master Gadrin",
            mapID = 1411, x = 55.97, y = 74.72, questId = 808,
        },
        {
            id = 2045, action = "TURNIN", text = "Turn in 'Zalazane' to Master Gadrin",
            mapID = 1411, x = 55.97, y = 74.72, questId = 826,
        },
        {
            id = 2046, action = "GOTO", text = "Go to Skull Rock cave north of Razor Hill for Dark Storms",
            mapID = 1411, x = 55.00, y = 9.50,
        },
        {
            id = 2047, action = "COMPLETE", text = "Kill Fizzle Darkstorm for Fizzle's Claw",
            mapID = 1411, x = 55.00, y = 9.50, questId = 806, objectiveIndex = 1,
        },
        {
            id = 2048, action = "COMPLETE", text = "Kill Razormane Quilboar, Scouts, Dustrunners, and Battleguards",
            mapID = 1411, x = 46.20, y = 29.10, questId = 837,
        },
        {
            id = 2049, action = "USE_HEARTH", text = "Use Hearthstone back to Razor Hill",
            mapID = 1411, x = 51.58, y = 41.58, minLevel = 8, itemID = 6948,
        },
        {
            id = 2050, action = "TURNIN", text = "Turn in 'Dark Storms' to Orgnil Soulscar",
            mapID = 1411, x = 52.26, y = 43.33, questId = 806,
        },
        {
            id = 2051, action = "TURNIN", text = "Turn in 'Encroachment' to Gar'Thok",
            mapID = 1411, x = 51.96, y = 43.49, questId = 837,
        },
        {
            id = 2052, action = "TRAIN", text = "Train Hunter skills and complete Pet quest (level 10)",
            mapID = 1411, x = 51.85, y = 43.49, minLevel = 10,
            classes = {"HUNTER"},
        },
        {
            id = 2053, action = "TRAIN", text = "Train Warrior skills at Razor Hill (level 10)",
            mapID = 1411, x = 54.18, y = 42.50, minLevel = 10,
            classes = {"WARRIOR"},
        },
        {
            id = 2054, action = "TRAIN", text = "Train Shaman skills at Razor Hill (level 10)",
            mapID = 1411, x = 54.39, y = 42.42, minLevel = 10,
            classes = {"SHAMAN"},
        },
        {
            id = 2055, action = "GRIND", text = "Grind to level 10.0 on Razormane Quilboar west of Razor Hill",
            mapID = 1411, x = 46.50, y = 53.00, targetLevel = 10.0,
        },

        ----------- Transition to The Barrens (mapID 1413) ---------------
        {
            id = 2056, action = "GOTO", text = "Travel west into The Barrens to The Crossroads",
            mapID = 1413, x = 51.53, y = 30.34,
        },
        {
            id = 2057, action = "SET_HEARTH", text = "Set Hearthstone at The Crossroads Inn",
            mapID = 1413, x = 51.99, y = 29.89, minLevel = 10,
        },
        {
            id = 2058, action = "ACCEPT", text = "Accept 'Raptor Thieves' from Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 869,
        },
        {
            id = 2059, action = "ACCEPT", text = "Accept 'Plainstrider Menace' from Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 844,
        },
        {
            id = 2060, action = "ACCEPT", text = "Accept 'The Zhevra' from Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 845,
        },
        {
            id = 2061, action = "ACCEPT", text = "Accept 'Supplies for the Crossroads' from Thork",
            mapID = 1413, x = 51.50, y = 30.86, questId = 5041,
        },
        {
            id = 2062, action = "ACCEPT", text = "Accept 'Disrupt the Attacks' from Thork",
            mapID = 1413, x = 51.50, y = 30.86, questId = 871,
        },
        {
            id = 2063, action = "COMPLETE", text = "Kill Plainstriders for 7 Plainstrider Beaks",
            mapID = 1413, x = 51.10, y = 36.20, questId = 844, objectiveIndex = 1,
        },
        {
            id = 2064, action = "COMPLETE", text = "Kill Zhevra and collect 4 Zhevra Hooves",
            mapID = 1413, x = 48.30, y = 39.10, questId = 845, objectiveIndex = 1,
        },
        {
            id = 2065, action = "TURNIN", text = "Turn in 'Plainstrider Menace' to Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 844,
        },
        {
            id = 2066, action = "TURNIN", text = "Turn in 'The Zhevra' to Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 845,
        },
        {
            id = 2067, action = "COMPLETE", text = "Kill 8 Razormane Water Seekers, 8 Thornweavers, 4 Hunters",
            mapID = 1413, x = 54.00, y = 25.50, questId = 871,
        },
        {
            id = 2068, action = "COMPLETE", text = "Collect Crossroads' Supply Crates at Thorn Hill",
            mapID = 1413, x = 55.30, y = 26.80, questId = 5041, objectiveIndex = 1,
        },
        {
            id = 2069, action = "TURNIN", text = "Turn in 'Disrupt the Attacks' to Thork",
            mapID = 1413, x = 51.50, y = 30.86, questId = 871,
        },
        {
            id = 2070, action = "TURNIN", text = "Turn in 'Supplies for the Crossroads' to Thork",
            mapID = 1413, x = 51.50, y = 30.86, questId = 5041,
        },
        {
            id = 2071, action = "COMPLETE", text = "Kill Sunscale Raptors and loot 12 Raptor Heads",
            mapID = 1413, x = 57.20, y = 26.50, questId = 869, objectiveIndex = 1,
        },
        {
            id = 2072, action = "TURNIN", text = "Turn in 'Raptor Thieves' to Sergra Darkthorn",
            mapID = 1413, x = 52.26, y = 31.02, questId = 869,
        },
        {
            id = 2073, action = "ACCEPT", text = "Accept 'The Forgotten Pools' from Tonga Runetotem",
            mapID = 1413, x = 52.24, y = 31.90, questId = 870,
            isOptional = true, maxSkipLevel = 18,
        },
        {
            id = 2074, action = "COMPLETE", text = "Swim to the bubbling fissure at The Forgotten Pools",
            mapID = 1413, x = 45.00, y = 22.50, questId = 870, objectiveIndex = 1,
            isOptional = true, maxSkipLevel = 18,
        },
        {
            id = 2075, action = "TURNIN", text = "Turn in 'The Forgotten Pools' to Tonga Runetotem",
            mapID = 1413, x = 52.24, y = 31.90, questId = 870,
            isOptional = true, maxSkipLevel = 18,
        },
        {
            id = 2076, action = "GRIND", text = "Grind to level 14.0 on Centaur near the oasis",
            mapID = 1413, x = 44.60, y = 45.00, targetLevel = 14.0,
        },
        {
            id = 2077, action = "FLY", text = "Fly from The Crossroads to Orgrimmar to train skills",
            mapID = 1413, x = 51.50, y = 30.30,
        },
        {
            id = 2078, action = "TRAIN", text = "Train class skills in Orgrimmar (level 14)",
            mapID = 1454, x = 75.50, y = 34.00, minLevel = 14,
            classes = {"WARRIOR", "SHAMAN", "HUNTER", "ROGUE", "MAGE", "WARLOCK", "PRIEST"},
        },
        {
            id = 2079, action = "ACCEPT", text = "Accept 'Centaur Bracers' from Regthar Deathgate",
            mapID = 1413, x = 45.34, y = 28.42, questId = 855,
        },
        {
            id = 2080, action = "ACCEPT", text = "Accept 'Kolkar Leaders' from Regthar Deathgate",
            mapID = 1413, x = 45.34, y = 28.42, questId = 850,
        },
        {
            id = 2081, action = "COMPLETE", text = "Kill Centaur and collect 15 Centaur Bracers",
            mapID = 1413, x = 42.10, y = 33.80, questId = 855, objectiveIndex = 1,
        },
        {
            id = 2082, action = "COMPLETE", text = "Kill Barak Kodobane for Kodobane's Head",
            mapID = 1413, x = 42.50, y = 35.10, questId = 850, objectiveIndex = 1,
        },
        {
            id = 2083, action = "TURNIN", text = "Turn in 'Centaur Bracers' to Regthar Deathgate",
            mapID = 1413, x = 45.34, y = 28.42, questId = 855,
        },
        {
            id = 2084, action = "TURNIN", text = "Turn in 'Kolkar Leaders' to Regthar Deathgate",
            mapID = 1413, x = 45.34, y = 28.42, questId = 850,
        },
        {
            id = 2085, action = "ACCEPT", text = "Accept 'Consumed by Hatred' from Mankrik",
            mapID = 1413, x = 51.95, y = 31.57, questId = 899,
        },
        {
            id = 2086, action = "COMPLETE", text = "Kill Bristleback Quilboar for 60 Bristleback Quilboar Tusks",
            mapID = 1413, x = 41.20, y = 47.80, questId = 899, objectiveIndex = 1,
        },
        {
            id = 2087, action = "USE_HEARTH", text = "Use Hearthstone back to The Crossroads",
            mapID = 1413, x = 51.99, y = 29.89, minLevel = 15, itemID = 6948,
        },
        {
            id = 2088, action = "TURNIN", text = "Turn in 'Consumed by Hatred' to Mankrik",
            mapID = 1413, x = 51.95, y = 31.57, questId = 899,
        },
        {
            id = 2089, action = "GRIND", text = "Grind to level 18.0 on Harpies/Centaur northwest of Crossroads",
            mapID = 1413, x = 39.10, y = 23.40, targetLevel = 18.0,
        },
        {
            id = 2090, action = "ACCEPT", text = "Accept 'Harpy Raiders' from Darsok Swiftdagger",
            mapID = 1413, x = 51.56, y = 30.54, questId = 867,
        },
        {
            id = 2091, action = "COMPLETE", text = "Kill Witchwing Harpies in the Dry Hills for 8 Talons",
            mapID = 1413, x = 38.60, y = 18.90, questId = 867, objectiveIndex = 1,
        },
        {
            id = 2092, action = "TURNIN", text = "Turn in 'Harpy Raiders' to Darsok Swiftdagger",
            mapID = 1413, x = 51.56, y = 30.54, questId = 867,
        },
        {
            id = 2093, action = "ACCEPT", text = "Accept 'Harpy Lieutenants' from Darsok Swiftdagger",
            mapID = 1413, x = 51.56, y = 30.54, questId = 875,
        },
        {
            id = 2094, action = "COMPLETE", text = "Kill Witchwing Slayers for 6 Harpy Lieutenant Rings",
            mapID = 1413, x = 37.30, y = 14.20, questId = 875, objectiveIndex = 1,
        },
        {
            id = 2095, action = "TURNIN", text = "Turn in 'Harpy Lieutenants' to Darsok Swiftdagger",
            mapID = 1413, x = 51.56, y = 30.54, questId = 875,
        },
        {
            id = 2096, action = "TRAIN", text = "Train class skills in Orgrimmar (level 20)",
            mapID = 1454, x = 75.50, y = 34.00, minLevel = 20,
            classes = {"WARRIOR", "SHAMAN", "HUNTER", "ROGUE", "MAGE", "WARLOCK", "PRIEST"},
        },
        {
            id = 2117, action = "GRIND", text = "Grind to level 20.0 near Camp Taurajo road",
            mapID = 1413, x = 44.50, y = 56.20, targetLevel = 20.0,
        },
    },
})
