-------------------------------------------------------------------------------
-- NexusKit - Built-in Leveling Routes (20-40)
-- Optimal speedrun leveling routes for Horde and Alliance (Levels 20 to 40)
-- Classic WoW & WoW Forever compatible coordinates, map IDs and quest IDs
-------------------------------------------------------------------------------
local addonName, FP = ...

-------------------------------------------------------------------------------
-- HORDE 20-40 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "HORDE_20_40_OPTIMAL",
    title     = "Horde 20-40 Optimal Speedrun",
    faction   = "Horde",
    minLevel  = 20,
    maxLevel  = 40,
    steps = {
        ----------- Level 20-22: Stonetalon Mountains (mapID 1442) ---------------
        {
            id = 4001, action = "FLY", text = "Fly from Crossroads to Sun Rock Retreat in Stonetalon Mountains",
            mapID = 1413, x = 51.50, y = 30.30, minLevel = 20,
        },
        {
            id = 4002, action = "GOTO", text = "Arrive at Sun Rock Retreat, Stonetalon Mountains",
            mapID = 1442, x = 47.30, y = 62.10,
        },
        {
            id = 4003, action = "SET_HEARTH", text = "Set Hearthstone at Sun Rock Retreat Inn",
            mapID = 1442, x = 47.10, y = 62.00,
        },
        {
            id = 4004, action = "ACCEPT", text = "Accept 'Bloodfury Bloodline' from Grundig Darkcloud",
            mapID = 1442, x = 47.40, y = 61.80, questId = 1063,
        },
        {
            id = 4005, action = "ACCEPT", text = "Accept 'Deepmoss Spider Eggs' from Tammra Windtotem",
            mapID = 1442, x = 47.20, y = 64.20, questId = 1061,
        },
        {
            id = 4006, action = "ACCEPT", text = "Accept 'Bespangled Bow' from Tammra Windtotem",
            mapID = 1442, x = 47.20, y = 64.20, questId = 1067,
        },
        {
            id = 4007, action = "COMPLETE", text = "Collect 10 Deepmoss Spider Eggs from the Webbed Cave",
            mapID = 1442, x = 54.20, y = 72.80, questId = 1061, objectiveIndex = 1,
        },
        {
            id = 4008, action = "COMPLETE", text = "Kill Bloodfury Harpies in Charred Vale for Bloodfury Bloodline",
            mapID = 1442, x = 32.50, y = 66.80, questId = 1063, objectiveIndex = 1,
        },
        {
            id = 4009, action = "TURNIN", text = "Turn in 'Deepmoss Spider Eggs' to Tammra Windtotem",
            mapID = 1442, x = 47.20, y = 64.20, questId = 1061,
        },
        {
            id = 4010, action = "TURNIN", text = "Turn in 'Bloodfury Bloodline' to Grundig Darkcloud",
            mapID = 1442, x = 47.40, y = 61.80, questId = 1063,
        },
        {
            id = 4011, action = "GRIND", text = "Grind to level 22.0 on Venture Co. goblins in Windshear Crag",
            mapID = 1442, x = 58.40, y = 54.20, targetLevel = 22.0,
        },

        ----------- Level 22-25: Southern Barrens (mapID 1413) ---------------
        {
            id = 4012, action = "FLY", text = "Fly to Camp Taurajo in Southern Barrens",
            mapID = 1442, x = 45.10, y = 59.80,
        },
        {
            id = 4013, action = "GOTO", text = "Arrive at Camp Taurajo",
            mapID = 1413, x = 44.50, y = 59.10,
        },
        {
            id = 4014, action = "SET_HEARTH", text = "Set Hearthstone at Camp Taurajo Inn",
            mapID = 1413, x = 45.60, y = 59.00,
        },
        {
            id = 4015, action = "ACCEPT", text = "Accept 'Tribes at War' from Mangletooth",
            mapID = 1413, x = 44.60, y = 59.20, questId = 878,
        },
        {
            id = 4016, action = "ACCEPT", text = "Accept 'Betrayal from Within' from Mangletooth",
            mapID = 1413, x = 44.60, y = 59.20, questId = 879,
        },
        {
            id = 4017, action = "ACCEPT", text = "Accept 'Weapons of Choice' from Tatternack Steelforge",
            mapID = 1413, x = 44.90, y = 58.60, questId = 894,
        },
        {
            id = 4018, action = "ACCEPT", text = "Accept 'The Silithid Mound' from Korran",
            mapID = 1413, x = 44.70, y = 59.30, questId = 880,
        },
        {
            id = 4019, action = "COMPLETE", text = "Kill Bristleback Quilboar and collect 6 Bristleback Battle Plans",
            mapID = 1413, x = 43.10, y = 78.40, questId = 878, objectiveIndex = 1,
        },
        {
            id = 4020, action = "COMPLETE", text = "Loot Weapons from Quilboar: 1 Stabbing Sword, 1 Combat Wand, 1 Heavy Shield",
            mapID = 1413, x = 43.50, y = 79.20, questId = 894,
        },
        {
            id = 4021, action = "COMPLETE", text = "Explore the Silithid Mound in the south",
            mapID = 1413, x = 46.50, y = 86.80, questId = 880, objectiveIndex = 1,
        },
        {
            id = 4022, action = "TURNIN", text = "Turn in 'The Silithid Mound' to Korran",
            mapID = 1413, x = 44.70, y = 59.30, questId = 880,
        },
        {
            id = 4023, action = "TURNIN", text = "Turn in 'Tribes at War' to Mangletooth",
            mapID = 1413, x = 44.60, y = 59.20, questId = 878,
        },
        {
            id = 4024, action = "TURNIN", text = "Turn in 'Betrayal from Within' to Mangletooth",
            mapID = 1413, x = 44.60, y = 59.20, questId = 879,
        },
        {
            id = 4025, action = "TURNIN", text = "Turn in 'Weapons of Choice' to Tatternack Steelforge",
            mapID = 1413, x = 44.90, y = 58.60, questId = 894,
        },
        {
            id = 4026, action = "GRIND", text = "Grind to level 25.0 on Silithid Swarmers / Quilboar",
            mapID = 1413, x = 46.00, y = 84.00, targetLevel = 25.0,
        },

        ----------- Level 25-27: Thousand Needles (mapID 1441) ---------------
        {
            id = 4027, action = "GOTO", text = "Run south past the Great Lift into Thousand Needles",
            mapID = 1441, x = 31.40, y = 22.80,
        },
        {
            id = 4028, action = "GOTO", text = "Ascend the wooden elevators to Freewind Post",
            mapID = 1441, x = 42.10, y = 53.60,
        },
        {
            id = 4029, action = "SET_HEARTH", text = "Set Hearthstone at Freewind Post Inn",
            mapID = 1441, x = 42.00, y = 53.40,
        },
        {
            id = 4030, action = "ACCEPT", text = "Accept 'A Different Approach' from Montarr",
            mapID = 1441, x = 42.30, y = 52.80, questId = 1146,
        },
        {
            id = 4031, action = "ACCEPT", text = "Accept 'Pacify the Centaur' from Cliffwatcher Longhorn",
            mapID = 1441, x = 42.10, y = 53.50, questId = 4768,
        },
        {
            id = 4032, action = "ACCEPT", text = "Accept 'Alien Egg' from Hagar Lightninghoof",
            mapID = 1441, x = 42.20, y = 54.10, questId = 1147,
        },
        {
            id = 4033, action = "ACCEPT", text = "Accept 'Windcaller' from Elu",
            mapID = 1441, x = 41.80, y = 52.60, questId = 1149,
        },
        {
            id = 4034, action = "COMPLETE", text = "Kill Galak Centaur: 12 Scouts, 10 Wranglers, 6 Windcallers",
            mapID = 1441, x = 32.50, y = 35.80, questId = 4768,
        },
        {
            id = 4035, action = "COMPLETE", text = "Loot the Alien Egg from the nest at Whitereach Post",
            mapID = 1441, x = 21.40, y = 46.80, questId = 1147, objectiveIndex = 1,
        },
        {
            id = 4036, action = "TURNIN", text = "Turn in 'Pacify the Centaur' to Cliffwatcher Longhorn",
            mapID = 1441, x = 42.10, y = 53.50, questId = 4768,
        },
        {
            id = 4037, action = "TURNIN", text = "Turn in 'Alien Egg' to Hagar Lightninghoof",
            mapID = 1441, x = 42.20, y = 54.10, questId = 1147,
        },
        {
            id = 4038, action = "GRIND", text = "Grind to level 27.0 on Centaurs or Wyverns at Highperch",
            mapID = 1441, x = 28.50, y = 34.00, targetLevel = 27.0,
        },

        ----------- Level 27-30: Hillsbrad Foothills (mapID 1424) ---------------
        {
            id = 4039, action = "USE_HEARTH", text = "Hearth or fly to Orgrimmar, take Zeppelin to Undercity",
            mapID = 1454, x = 50.80, y = 13.80,
        },
        {
            id = 4040, action = "FLY", text = "Fly from Undercity to Tarren Mill in Hillsbrad Foothills",
            mapID = 1420, x = 63.80, y = 48.60,
        },
        {
            id = 4041, action = "GOTO", text = "Arrive at Tarren Mill, Hillsbrad Foothills",
            mapID = 1424, x = 60.20, y = 18.60,
        },
        {
            id = 4042, action = "SET_HEARTH", text = "Set Hearthstone at Tarren Mill Inn",
            mapID = 1424, x = 62.50, y = 20.80,
        },
        {
            id = 4043, action = "ACCEPT", text = "Accept 'Battle of Hillsbrad' from Darthalia",
            mapID = 1424, x = 61.80, y = 20.40, questId = 528,
        },
        {
            id = 4044, action = "ACCEPT", text = "Accept 'Elixir of Suffering' from Apothecary Lydon",
            mapID = 1424, x = 61.40, y = 19.20, questId = 496,
        },
        {
            id = 4045, action = "ACCEPT", text = "Accept 'Dangerous!' from the Wanted Board",
            mapID = 1424, x = 62.10, y = 19.80, questId = 505,
        },
        {
            id = 4046, action = "COMPLETE", text = "Kill 6 Hillsbrad Farmers and 6 Farmhands",
            mapID = 1424, x = 36.50, y = 44.80, questId = 528,
        },
        {
            id = 4047, action = "TURNIN", text = "Turn in 'Battle of Hillsbrad' to Darthalia",
            mapID = 1424, x = 61.80, y = 20.40, questId = 528,
        },
        {
            id = 4048, action = "ACCEPT", text = "Accept 'Battle of Hillsbrad (Part 2)' from Darthalia",
            mapID = 1424, x = 61.80, y = 20.40, questId = 529,
        },
        {
            id = 4049, action = "COMPLETE", text = "Kill 15 Hillsbrad Peasants and loot 15 Iron Claws",
            mapID = 1424, x = 32.80, y = 41.20, questId = 529, objectiveIndex = 1,
        },
        {
            id = 4050, action = "TURNIN", text = "Turn in 'Battle of Hillsbrad (Part 2)' to Darthalia",
            mapID = 1424, x = 61.80, y = 20.40, questId = 529,
        },
        {
            id = 4051, action = "GRIND", text = "Grind to level 30.0 on Syndicate rogues in Durnholde Keep",
            mapID = 1424, x = 74.20, y = 42.60, targetLevel = 30.0,
        },
        {
            id = 4052, action = "TRAIN", text = "Fly to Undercity and train class skills (level 30)",
            mapID = 1458, x = 64.20, y = 48.00, minLevel = 30,
        },

        ----------- Level 30-33: Shimmering Flats (mapID 1441) ---------------
        {
            id = 4053, action = "GOTO", text = "Travel to Shimmering Flats (Mirage Raceway) in Thousand Needles",
            mapID = 1441, x = 80.50, y = 75.80,
        },
        {
            id = 4054, action = "ACCEPT", text = "Accept 'Rocket Car Parts' from Kravel Koalbeard",
            mapID = 1441, x = 80.60, y = 75.90, questId = 1104,
        },
        {
            id = 4055, action = "ACCEPT", text = "Accept 'Salt Flat Venom' from Fizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.20, questId = 1111,
        },
        {
            id = 4056, action = "ACCEPT", text = "Accept 'Hardened Shells' from Wizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.00, questId = 1112,
        },
        {
            id = 4057, action = "ACCEPT", text = "Accept 'Load Lightening' from Pozzik",
            mapID = 1441, x = 78.00, y = 77.30, questId = 1110,
        },
        {
            id = 4058, action = "COMPLETE", text = "Collect 30 Rocket Car Parts from scattered scrap",
            mapID = 1441, x = 82.40, y = 68.20, questId = 1104, objectiveIndex = 1,
        },
        {
            id = 4059, action = "COMPLETE", text = "Kill Basilisks, Scorpids, and Vultures across the Salt Flats",
            mapID = 1441, x = 84.50, y = 74.00, questId = 1111,
        },
        {
            id = 4060, action = "COMPLETE", text = "Loot 9 Hardened Tortoise Shells from Saltstone Turtles",
            mapID = 1441, x = 86.20, y = 66.50, questId = 1112, objectiveIndex = 1,
        },
        {
            id = 4061, action = "TURNIN", text = "Turn in 'Rocket Car Parts' to Kravel Koalbeard",
            mapID = 1441, x = 80.60, y = 75.90, questId = 1104,
        },
        {
            id = 4062, action = "TURNIN", text = "Turn in 'Salt Flat Venom' to Fizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.20, questId = 1111,
        },
        {
            id = 4063, action = "TURNIN", text = "Turn in 'Hardened Shells' to Wizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.00, questId = 1112,
        },
        {
            id = 4064, action = "TURNIN", text = "Turn in 'Load Lightening' to Pozzik",
            mapID = 1441, x = 78.00, y = 77.30, questId = 1110,
        },
        {
            id = 4065, action = "GRIND", text = "Grind to level 33.0 on Saltstone basilisks/scorpids",
            mapID = 1441, x = 83.00, y = 72.00, targetLevel = 33.0,
        },

        ----------- Level 33-36: Arathi Highlands (mapID 1417) ---------------
        {
            id = 4066, action = "FLY", text = "Fly to Hammerfall in Arathi Highlands",
            mapID = 1417, x = 73.10, y = 32.70,
        },
        {
            id = 4067, action = "SET_HEARTH", text = "Set Hearthstone at Hammerfall Inn",
            mapID = 1417, x = 73.80, y = 33.90,
        },
        {
            id = 4068, action = "ACCEPT", text = "Accept 'Hammerfall' from Gor'mul",
            mapID = 1417, x = 73.50, y = 33.00, questId = 683,
        },
        {
            id = 4069, action = "ACCEPT", text = "Accept 'Witherbark Cages' from Tor'gan",
            mapID = 1417, x = 74.00, y = 34.50, questId = 684,
        },
        {
            id = 4070, action = "ACCEPT", text = "Accept 'The Real Threat' from Kelek Skyseeker",
            mapID = 1417, x = 73.20, y = 32.60, questId = 678,
        },
        {
            id = 4071, action = "COMPLETE", text = "Inspect the 3 Witherbark Cages at the troll village",
            mapID = 1417, x = 68.40, y = 77.20, questId = 684,
        },
        {
            id = 4072, action = "COMPLETE", text = "Kill 8 Highland Fleshstalkers and 10 Highland Scytheclaws",
            mapID = 1417, x = 62.00, y = 48.00, questId = 678,
        },
        {
            id = 4073, action = "TURNIN", text = "Turn in 'Witherbark Cages' to Tor'gan",
            mapID = 1417, x = 74.00, y = 34.50, questId = 684,
        },
        {
            id = 4074, action = "TURNIN", text = "Turn in 'The Real Threat' to Kelek Skyseeker",
            mapID = 1417, x = 73.20, y = 32.60, questId = 678,
        },
        {
            id = 4075, action = "GRIND", text = "Grind to level 36.0 on Witherbark Trolls or Syndicate members",
            mapID = 1417, x = 67.00, y = 75.00, targetLevel = 36.0,
        },

        ----------- Level 36-38: Desolace (mapID 1443) ---------------
        {
            id = 4076, action = "FLY", text = "Fly to Shadowprey Village in Desolace",
            mapID = 1443, x = 24.20, y = 71.90,
        },
        {
            id = 4077, action = "SET_HEARTH", text = "Set Hearthstone at Shadowprey Village",
            mapID = 1443, x = 24.00, y = 72.50,
        },
        {
            id = 4078, action = "ACCEPT", text = "Accept 'Gelkis Alliance' from Uthek the Wise",
            mapID = 1443, x = 36.40, y = 79.20, questId = 1367,
        },
        {
            id = 4079, action = "COMPLETE", text = "Kill Magram Centaur to raise Gelkis Clan reputation",
            mapID = 1443, x = 70.50, y = 72.80, questId = 1367, objectiveIndex = 1,
        },
        {
            id = 4080, action = "TURNIN", text = "Turn in 'Gelkis Alliance' to Uthek the Wise",
            mapID = 1443, x = 36.40, y = 79.20, questId = 1367,
        },
        {
            id = 4081, action = "ACCEPT", text = "Accept 'Stealing Supplies' from Uthek the Wise",
            mapID = 1443, x = 36.40, y = 79.20, questId = 1368,
        },
        {
            id = 4082, action = "COMPLETE", text = "Loot Magram Supply Sack from the Magram village",
            mapID = 1443, x = 71.80, y = 74.20, questId = 1368, objectiveIndex = 1,
        },
        {
            id = 4083, action = "TURNIN", text = "Turn in 'Stealing Supplies' to Uthek the Wise",
            mapID = 1443, x = 36.40, y = 79.20, questId = 1368,
        },
        {
            id = 4084, action = "GRIND", text = "Grind to level 38.0 on Magram Centaurs or Burning Blade cultists",
            mapID = 1443, x = 72.00, y = 73.00, targetLevel = 38.0,
        },

        ----------- Level 38-40: Stranglethorn Vale (mapID 1434) ---------------
        {
            id = 4085, action = "GOTO", text = "Take the Zeppelin from Orgrimmar/Undercity to Grom'gol Base Camp",
            mapID = 1434, x = 32.40, y = 27.60,
        },
        {
            id = 4086, action = "SET_HEARTH", text = "Set Hearthstone at Grom'gol Base Camp Inn",
            mapID = 1434, x = 32.20, y = 27.80,
        },
        {
            id = 4087, action = "ACCEPT", text = "Accept 'Hunt the Bloodscalp' from Nimboya",
            mapID = 1434, x = 32.10, y = 27.50, questId = 194,
        },
        {
            id = 4088, action = "GOTO", text = "Run northeast to Nesingwary's Expedition Camp",
            mapID = 1434, x = 35.60, y = 10.60,
        },
        {
            id = 4089, action = "ACCEPT", text = "Accept 'Tiger Mastery' from Ajeck Rouche",
            mapID = 1434, x = 35.70, y = 10.50, questId = 185,
        },
        {
            id = 4090, action = "ACCEPT", text = "Accept 'Panther Mastery' from Sir S. J. Erlingtorm",
            mapID = 1434, x = 35.60, y = 10.60, questId = 190,
        },
        {
            id = 4091, action = "ACCEPT", text = "Accept 'Raptor Mastery' from Hemet Nesingwary Jr.",
            mapID = 1434, x = 35.70, y = 10.80, questId = 195,
        },
        {
            id = 4092, action = "COMPLETE", text = "Kill 10 Young Tigers and 10 Young Panthers",
            mapID = 1434, x = 38.00, y = 15.00, questId = 185,
        },
        {
            id = 4093, action = "COMPLETE", text = "Kill 10 Stranglethorn Raptors",
            mapID = 1434, x = 34.00, y = 18.00, questId = 195, objectiveIndex = 1,
        },
        {
            id = 4094, action = "COMPLETE", text = "Collect 25 Bloodscalp Ears from Bloodscalp Trolls",
            mapID = 1434, x = 30.00, y = 17.00, questId = 194, objectiveIndex = 1,
        },
        {
            id = 4095, action = "TURNIN", text = "Turn in 'Tiger Mastery' to Ajeck Rouche",
            mapID = 1434, x = 35.70, y = 10.50, questId = 185,
        },
        {
            id = 4096, action = "TURNIN", text = "Turn in 'Panther Mastery' to Sir S. J. Erlingtorm",
            mapID = 1434, x = 35.60, y = 10.60, questId = 190,
        },
        {
            id = 4097, action = "TURNIN", text = "Turn in 'Raptor Mastery' to Hemet Nesingwary Jr.",
            mapID = 1434, x = 35.70, y = 10.80, questId = 195,
        },
        {
            id = 4098, action = "TURNIN", text = "Turn in 'Hunt the Bloodscalp' to Nimboya at Grom'gol",
            mapID = 1434, x = 32.10, y = 27.50, questId = 194,
        },
        {
            id = 4099, action = "GRIND", text = "Grind to level 40.0 on Bloodscalp Trolls near Zul'Kunda",
            mapID = 1434, x = 28.50, y = 14.50, targetLevel = 40.0,
        },
        {
            id = 4100, action = "TRAIN", text = "Ding 40! Return to your capital city to learn 60% Riding and purchase your first mount!",
            mapID = 1454, x = 60.50, y = 35.00, minLevel = 40,
        },
    },
})

-------------------------------------------------------------------------------
-- ALLIANCE 20-40 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "ALLIANCE_20_40_OPTIMAL",
    title     = "Alliance 20-40 Optimal Speedrun",
    faction   = "Alliance",
    minLevel  = 20,
    maxLevel  = 40,
    steps = {
        ----------- Level 20-23: Redridge Mountains (mapID 1433) ---------------
        {
            id = 3001, action = "FLY", text = "Fly from Stormwind to Lakeshire in Redridge Mountains",
            mapID = 1433, x = 30.60, y = 59.40, minLevel = 20,
        },
        {
            id = 3002, action = "SET_HEARTH", text = "Set Hearthstone at Lakeshire Inn",
            mapID = 1433, x = 26.50, y = 44.80,
        },
        {
            id = 3003, action = "ACCEPT", text = "Accept 'Solomon's Law' from Bailiff Conacher",
            mapID = 1433, x = 29.50, y = 47.10, questId = 92,
        },
        {
            id = 3004, action = "ACCEPT", text = "Accept 'The Shadowhide Pendant' from Deputy Feldon",
            mapID = 1433, x = 30.20, y = 47.80, questId = 125,
        },
        {
            id = 3005, action = "COMPLETE", text = "Kill Shadowhide Gnolls and loot the Shadowhide Pendant",
            mapID = 1433, x = 40.00, y = 55.00, questId = 125, objectiveIndex = 1,
        },
        {
            id = 3006, action = "TURNIN", text = "Turn in 'The Shadowhide Pendant' to Deputy Feldon",
            mapID = 1433, x = 30.20, y = 47.80, questId = 125,
        },
        {
            id = 3007, action = "TURNIN", text = "Turn in 'Solomon's Law' to Bailiff Conacher",
            mapID = 1433, x = 29.50, y = 47.10, questId = 92,
        },
        {
            id = 3008, action = "GRIND", text = "Grind to level 23.0 on Blackrock Orcs in Render's Valley",
            mapID = 1433, x = 60.50, y = 42.00, targetLevel = 23.0,
        },

        ----------- Level 23-26: Duskwood (mapID 1431) ---------------
        {
            id = 3009, action = "GOTO", text = "Travel southwest into Duskwood to Darkshire",
            mapID = 1431, x = 73.80, y = 44.50,
        },
        {
            id = 3010, action = "SET_HEARTH", text = "Set Hearthstone at Darkshire Inn",
            mapID = 1431, x = 73.80, y = 44.40,
        },
        {
            id = 3011, action = "ACCEPT", text = "Accept 'The Night Watch' from Commander Althea Ebonlocke",
            mapID = 1431, x = 73.60, y = 46.80, questId = 56,
        },
        {
            id = 3012, action = "ACCEPT", text = "Accept 'The Hermit' from Madame Eva",
            mapID = 1431, x = 75.80, y = 45.40, questId = 154,
        },
        {
            id = 3013, action = "COMPLETE", text = "Kill 8 Skeletal Warriors and 6 Skeletal Mages in Tranquil Gardens",
            mapID = 1431, x = 78.40, y = 35.80, questId = 56,
        },
        {
            id = 3014, action = "TURNIN", text = "Turn in 'The Hermit' to Abercrombie",
            mapID = 1431, x = 28.10, y = 31.60, questId = 154,
        },
        {
            id = 3015, action = "TURNIN", text = "Turn in 'The Night Watch' to Commander Althea Ebonlocke",
            mapID = 1431, x = 73.60, y = 46.80, questId = 56,
        },
        {
            id = 3016, action = "GRIND", text = "Grind to level 26.0 on Skeletal Fiends / Webwood Spiders",
            mapID = 1431, x = 70.00, y = 72.00, targetLevel = 26.0,
        },

        ----------- Level 26-29: Wetlands (mapID 1437) ---------------
        {
            id = 3017, action = "FLY", text = "Fly via Ironforge to Menethil Harbor in Wetlands",
            mapID = 1437, x = 9.50, y = 59.70,
        },
        {
            id = 3018, action = "SET_HEARTH", text = "Set Hearthstone at Menethil Harbor Inn",
            mapID = 1437, x = 10.60, y = 60.80,
        },
        {
            id = 3019, action = "ACCEPT", text = "Accept 'Young Crocolisk Skins' from James Halloran",
            mapID = 1437, x = 10.80, y = 59.60, questId = 279,
        },
        {
            id = 3020, action = "ACCEPT", text = "Accept 'Claws from the Deep' from Karl Boran",
            mapID = 1437, x = 10.20, y = 57.10, questId = 288,
        },
        {
            id = 3021, action = "COMPLETE", text = "Kill Young Crocolisks for 5 Young Crocolisk Skins",
            mapID = 1437, x = 24.50, y = 50.20, questId = 279, objectiveIndex = 1,
        },
        {
            id = 3022, action = "COMPLETE", text = "Kill 12 Bluegill Murlocs near the coastal marsh",
            mapID = 1437, x = 14.80, y = 41.50, questId = 288, objectiveIndex = 1,
        },
        {
            id = 3023, action = "TURNIN", text = "Turn in 'Young Crocolisk Skins' to James Halloran",
            mapID = 1437, x = 10.80, y = 59.60, questId = 279,
        },
        {
            id = 3024, action = "TURNIN", text = "Turn in 'Claws from the Deep' to Karl Boran",
            mapID = 1437, x = 10.20, y = 57.10, questId = 288,
        },
        {
            id = 3025, action = "GRIND", text = "Grind to level 29.0 on Dragonmaw Orcs near Angerfang Encampment",
            mapID = 1437, x = 46.20, y = 41.00, targetLevel = 29.0,
        },

        ----------- Level 29-32: Hillsbrad Foothills (mapID 1424) ---------------
        {
            id = 3026, action = "FLY", text = "Fly to Southshore in Hillsbrad Foothills",
            mapID = 1424, x = 49.30, y = 52.30,
        },
        {
            id = 3027, action = "SET_HEARTH", text = "Set Hearthstone at Southshore Inn",
            mapID = 1424, x = 50.80, y = 55.60,
        },
        {
            id = 3028, action = "ACCEPT", text = "Accept 'Costly Menace' from Darren Malvew",
            mapID = 1424, x = 50.40, y = 57.10, questId = 556,
        },
        {
            id = 3029, action = "ACCEPT", text = "Accept 'Syndicate Assassins' from Magistrate Henry Maleb",
            mapID = 1424, x = 50.50, y = 53.80, questId = 512,
        },
        {
            id = 3030, action = "COMPLETE", text = "Kill 8 Mountain Lions and 10 Hulking Mountain Lions",
            mapID = 1424, x = 46.50, y = 30.20, questId = 556,
        },
        {
            id = 3031, action = "COMPLETE", text = "Kill 12 Syndicate Footpads and 8 Syndicate Thieves",
            mapID = 1424, x = 54.00, y = 22.00, questId = 512,
        },
        {
            id = 3032, action = "TURNIN", text = "Turn in 'Costly Menace' to Darren Malvew",
            mapID = 1424, x = 50.40, y = 57.10, questId = 556,
        },
        {
            id = 3033, action = "TURNIN", text = "Turn in 'Syndicate Assassins' to Magistrate Henry Maleb",
            mapID = 1424, x = 50.50, y = 53.80, questId = 512,
        },
        {
            id = 3034, action = "GRIND", text = "Grind to level 32.0 on Hillsbrad yetis or Durnholde syndicate",
            mapID = 1424, x = 46.00, y = 25.00, targetLevel = 32.0,
        },

        ----------- Level 32-35: Shimmering Flats (mapID 1441) ---------------
        {
            id = 3035, action = "GOTO", text = "Take boat from Menethil to Theramore, run south to Mirage Raceway (Thousand Needles)",
            mapID = 1441, x = 80.50, y = 75.80,
        },
        {
            id = 3036, action = "ACCEPT", text = "Accept 'Rocket Car Parts' from Kravel Koalbeard",
            mapID = 1441, x = 80.60, y = 75.90, questId = 1104,
        },
        {
            id = 3037, action = "ACCEPT", text = "Accept 'Salt Flat Venom' from Fizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.20, questId = 1111,
        },
        {
            id = 3038, action = "ACCEPT", text = "Accept 'Hardened Shells' from Wizzle Brassbolts",
            mapID = 1441, x = 78.10, y = 77.00, questId = 1112,
        },
        {
            id = 3039, action = "COMPLETE", text = "Collect 30 Rocket Car Parts across the salt flats",
            mapID = 1441, x = 82.40, y = 68.20, questId = 1104, objectiveIndex = 1,
        },
        {
            id = 3040, action = "COMPLETE", text = "Kill Basilisks, Scorpids and Turtles for quest items",
            mapID = 1441, x = 84.50, y = 74.00, questId = 1111,
        },
        {
            id = 3041, action = "TURNIN", text = "Turn in all Mirage Raceway quests for huge XP chunk",
            mapID = 1441, x = 80.60, y = 75.90, questId = 1104,
        },
        {
            id = 3042, action = "GRIND", text = "Grind to level 35.0 on Salt Flats beasts",
            mapID = 1441, x = 83.00, y = 72.00, targetLevel = 35.0,
        },

        ----------- Level 35-37: Arathi Highlands (mapID 1417) ---------------
        {
            id = 3043, action = "FLY", text = "Fly to Refuge Pointe in Arathi Highlands",
            mapID = 1417, x = 45.80, y = 46.10,
        },
        {
            id = 3044, action = "ACCEPT", text = "Accept 'Northfold Manor' from Captain Nials",
            mapID = 1417, x = 45.60, y = 46.20, questId = 648,
        },
        {
            id = 3045, action = "COMPLETE", text = "Kill 10 Syndicate Highwaymen at Northfold Manor",
            mapID = 1417, x = 32.50, y = 28.00, questId = 648, objectiveIndex = 1,
        },
        {
            id = 3046, action = "TURNIN", text = "Turn in 'Northfold Manor' to Captain Nials",
            mapID = 1417, x = 45.60, y = 46.20, questId = 648,
        },
        {
            id = 3047, action = "GRIND", text = "Grind to level 37.0 on Witherbark Trolls or Syndicate members",
            mapID = 1417, x = 28.00, y = 60.00, targetLevel = 37.0,
        },

        ----------- Level 37-40: Stranglethorn Vale (mapID 1434) ---------------
        {
            id = 3048, action = "FLY", text = "Fly from Stormwind to Rebel Camp in northern Stranglethorn Vale",
            mapID = 1434, x = 37.60, y = 3.60,
        },
        {
            id = 3049, action = "GOTO", text = "Run south to Nesingwary's Expedition Camp",
            mapID = 1434, x = 35.60, y = 10.60,
        },
        {
            id = 3050, action = "ACCEPT", text = "Accept 'Tiger Mastery' from Ajeck Rouche",
            mapID = 1434, x = 35.70, y = 10.50, questId = 185,
        },
        {
            id = 3051, action = "ACCEPT", text = "Accept 'Panther Mastery' from Sir S. J. Erlingtorm",
            mapID = 1434, x = 35.60, y = 10.60, questId = 190,
        },
        {
            id = 3052, action = "ACCEPT", text = "Accept 'Raptor Mastery' from Hemet Nesingwary Jr.",
            mapID = 1434, x = 35.70, y = 10.80, questId = 195,
        },
        {
            id = 3053, action = "COMPLETE", text = "Kill 10 Young Tigers and 10 Young Panthers",
            mapID = 1434, x = 38.00, y = 15.00, questId = 185,
        },
        {
            id = 3054, action = "COMPLETE", text = "Kill 10 Stranglethorn Raptors",
            mapID = 1434, x = 34.00, y = 18.00, questId = 195, objectiveIndex = 1,
        },
        {
            id = 3055, action = "TURNIN", text = "Turn in Nesingwary hunting masteries",
            mapID = 1434, x = 35.70, y = 10.50, questId = 185,
        },
        {
            id = 3056, action = "GRIND", text = "Grind to level 40.0 on Kurzen jungle fighters or River Crocolisks",
            mapID = 1434, x = 44.00, y = 10.00, targetLevel = 40.0,
        },
        {
            id = 3057, action = "TRAIN", text = "Ding 40! Return to Stormwind/Ironforge to learn 60% Riding and buy your mount!",
            mapID = 1453, x = 70.00, y = 45.00, minLevel = 40,
        },
    },
})
