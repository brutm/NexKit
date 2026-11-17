-------------------------------------------------------------------------------
-- NexusKit - Built-in Leveling Routes (40-60)
-- Optimal speedrun leveling routes for Horde and Alliance (Levels 40 to 60)
-- Classic WoW & WoW Forever compatible coordinates, map IDs and quest IDs
-------------------------------------------------------------------------------
local addonName, FP = ...

-------------------------------------------------------------------------------
-- HORDE 40-60 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "HORDE_40_60_OPTIMAL",
    title     = "Horde 40-60 Optimal Speedrun",
    faction   = "Horde",
    minLevel  = 40,
    maxLevel  = 60,
    steps = {
        ----------- Level 40-43: Mount & Badlands (mapID 1418) ---------------
        {
            id = 6001, action = "FLY", text = "Fly to Kargath in Badlands",
            mapID = 1418, x = 4.20, y = 44.80, minLevel = 40,
        },
        {
            id = 6002, action = "SET_HEARTH", text = "Set Hearthstone at Kargath Outpost Inn",
            mapID = 1418, x = 3.90, y = 44.60,
        },
        {
            id = 6003, action = "ACCEPT", text = "Accept 'Study of the Elements' from Lotwil Veriatus",
            mapID = 1418, x = 2.40, y = 36.10, questId = 708,
        },
        {
            id = 6004, action = "ACCEPT", text = "Accept 'Coyote Thieves' from Rigglefuzz",
            mapID = 1418, x = 42.10, y = 52.80, questId = 709,
        },
        {
            id = 6005, action = "ACCEPT", text = "Accept 'Broken Alliances' from Gorn",
            mapID = 1418, x = 3.60, y = 47.90, questId = 712,
        },
        {
            id = 6006, action = "COMPLETE", text = "Kill Rock Elementals for 10 Small Stone Shards",
            mapID = 1418, x = 16.50, y = 35.00, questId = 708, objectiveIndex = 1,
        },
        {
            id = 6007, action = "COMPLETE", text = "Kill Badlands Coyotes for 30 Coyote Gizzards",
            mapID = 1418, x = 38.00, y = 56.00, questId = 709, objectiveIndex = 1,
        },
        {
            id = 6008, action = "COMPLETE", text = "Kill Boss Tho'grun at the ogre mound for Tho'grun's Signet",
            mapID = 1418, x = 46.50, y = 13.80, questId = 712, objectiveIndex = 1,
        },
        {
            id = 6009, action = "TURNIN", text = "Turn in 'Study of the Elements' to Lotwil Veriatus",
            mapID = 1418, x = 2.40, y = 36.10, questId = 708,
        },
        {
            id = 6010, action = "TURNIN", text = "Turn in 'Coyote Thieves' to Rigglefuzz",
            mapID = 1418, x = 42.10, y = 52.80, questId = 709,
        },
        {
            id = 6011, action = "TURNIN", text = "Turn in 'Broken Alliances' to Gorn",
            mapID = 1418, x = 3.60, y = 47.90, questId = 712,
        },
        {
            id = 6012, action = "GRIND", text = "Grind to level 43.0 on Lesser Rock Elementals / Ogres",
            mapID = 1418, x = 24.00, y = 40.00, targetLevel = 43.0,
        },

        ----------- Level 43-45: Tanaris (mapID 1446) ---------------
        {
            id = 6013, action = "FLY", text = "Fly to Gadgetzan in Tanaris",
            mapID = 1446, x = 51.60, y = 26.80,
        },
        {
            id = 6014, action = "SET_HEARTH", text = "Set Hearthstone at Gadgetzan Inn",
            mapID = 1446, x = 51.80, y = 27.20,
        },
        {
            id = 6015, action = "ACCEPT", text = "Accept 'Wastewander Justice' from Chief Engineer Bilgewhizzle",
            mapID = 1446, x = 52.40, y = 28.50, questId = 1687,
        },
        {
            id = 6016, action = "ACCEPT", text = "Accept 'Water Pouch Bounty' from Spigot Operator Fizzwich",
            mapID = 1446, x = 52.60, y = 28.10, questId = 1690,
        },
        {
            id = 6017, action = "ACCEPT", text = "Accept 'More Wastewander Justice' from Chief Engineer Bilgewhizzle",
            mapID = 1446, x = 52.40, y = 28.50, questId = 1688,
        },
        {
            id = 6018, action = "COMPLETE", text = "Kill 10 Wastewander Rogues, 10 Bandits and 8 Thieves",
            mapID = 1446, x = 62.00, y = 32.00, questId = 1687,
        },
        {
            id = 6019, action = "COMPLETE", text = "Collect 5 Wastewander Water Pouches from bandits",
            mapID = 1446, x = 63.50, y = 30.50, questId = 1690, objectiveIndex = 1,
        },
        {
            id = 6020, action = "TURNIN", text = "Turn in 'Wastewander Justice' to Bilgewhizzle",
            mapID = 1446, x = 52.40, y = 28.50, questId = 1687,
        },
        {
            id = 6021, action = "TURNIN", text = "Turn in 'Water Pouch Bounty' to Fizzwich",
            mapID = 1446, x = 52.60, y = 28.10, questId = 1690,
        },
        {
            id = 6022, action = "GRIND", text = "Grind to level 45.0 on Dunemaul Ogres at the Southmoon Ruins",
            mapID = 1446, x = 40.50, y = 72.00, targetLevel = 45.0,
        },

        ----------- Level 45-47: Feralas (mapID 1444) ---------------
        {
            id = 6023, action = "FLY", text = "Fly to Camp Mojache in Feralas",
            mapID = 1444, x = 75.40, y = 44.30,
        },
        {
            id = 6024, action = "SET_HEARTH", text = "Set Hearthstone at Camp Mojache Inn",
            mapID = 1444, x = 75.20, y = 44.50,
        },
        {
            id = 6025, action = "ACCEPT", text = "Accept 'A New Cloak' from Jangdor Swiftstrider",
            mapID = 1444, x = 74.60, y = 42.80, questId = 2872,
        },
        {
            id = 6026, action = "ACCEPT", text = "Accept 'Gordunni Outpost' from Oran Snakewrithe",
            mapID = 1444, x = 75.80, y = 43.60, questId = 2873,
        },
        {
            id = 6027, action = "ACCEPT", text = "Accept 'The Ogres of Feralas' from Oran Snakewrithe",
            mapID = 1444, x = 75.80, y = 43.60, questId = 2874,
        },
        {
            id = 6028, action = "COMPLETE", text = "Kill 10 Gordunni Ogres, 10 Shamans, and 8 Brutes",
            mapID = 1444, x = 72.00, y = 56.00, questId = 2874,
        },
        {
            id = 6029, action = "COMPLETE", text = "Loot 10 Iridescent Beetle Eyes for A New Cloak",
            mapID = 1444, x = 70.00, y = 48.00, questId = 2872, objectiveIndex = 1,
        },
        {
            id = 6030, action = "TURNIN", text = "Turn in 'The Ogres of Feralas' to Oran Snakewrithe",
            mapID = 1444, x = 75.80, y = 43.60, questId = 2874,
        },
        {
            id = 6031, action = "TURNIN", text = "Turn in 'A New Cloak' to Jangdor Swiftstrider",
            mapID = 1444, x = 74.60, y = 42.80, questId = 2872,
        },
        {
            id = 6032, action = "GRIND", text = "Grind to level 47.0 on Gordunni Mauler / Shamans",
            mapID = 1444, x = 71.00, y = 55.00, targetLevel = 47.0,
        },

        ----------- Level 47-49: The Hinterlands (mapID 1425) ---------------
        {
            id = 6033, action = "FLY", text = "Fly via Undercity/Tarren Mill to Revantusk Village in The Hinterlands",
            mapID = 1425, x = 78.20, y = 81.30,
        },
        {
            id = 6034, action = "SET_HEARTH", text = "Set Hearthstone at Revantusk Village Inn",
            mapID = 1425, x = 78.00, y = 81.50,
        },
        {
            id = 6035, action = "ACCEPT", text = "Accept 'Snapjaws, Lord!' from Primal Torntusk",
            mapID = 1425, x = 78.30, y = 81.20, questId = 7815,
        },
        {
            id = 6036, action = "ACCEPT", text = "Accept 'Cannibalistic Cousins' from Torntusk",
            mapID = 1425, x = 78.10, y = 81.40, questId = 7816,
        },
        {
            id = 6037, action = "COMPLETE", text = "Kill Saltwater Snapjaws along the coast for 15 Snapjaw Flashes",
            mapID = 1425, x = 79.50, y = 72.00, questId = 7815, objectiveIndex = 1,
        },
        {
            id = 6038, action = "COMPLETE", text = "Kill 15 Vilebranch Trolls at Jintha'Alor / Agol'watha",
            mapID = 1425, x = 66.00, y = 68.00, questId = 7816, objectiveIndex = 1,
        },
        {
            id = 6039, action = "TURNIN", text = "Turn in 'Snapjaws, Lord!' to Primal Torntusk",
            mapID = 1425, x = 78.30, y = 81.20, questId = 7815,
        },
        {
            id = 6040, action = "TURNIN", text = "Turn in 'Cannibalistic Cousins' to Torntusk",
            mapID = 1425, x = 78.10, y = 81.40, questId = 7816,
        },
        {
            id = 6041, action = "GRIND", text = "Grind to level 49.0 on Silvermane stalkers / Vilebranch trolls",
            mapID = 1425, x = 60.00, y = 50.00, targetLevel = 49.0,
        },

        ----------- Level 49-51: Searing Gorge & Blasted Lands (mapID 1427 & 1419) ---------------
        {
            id = 6042, action = "FLY", text = "Fly to Thorium Point in Searing Gorge",
            mapID = 1427, x = 37.80, y = 30.90,
        },
        {
            id = 6043, action = "ACCEPT", text = "Accept 'Fiery Menace!' from Master Smith Burninate",
            mapID = 1427, x = 38.60, y = 28.50, questId = 3374,
        },
        {
            id = 6044, action = "ACCEPT", text = "Accept 'Incendosaurs? Whateverosaur is More Like It' from Hansel Heavyhands",
            mapID = 1427, x = 39.00, y = 27.80, questId = 3373,
        },
        {
            id = 6045, action = "COMPLETE", text = "Kill 20 Incendosaurs in the magma caves",
            mapID = 1427, x = 45.00, y = 48.00, questId = 3373, objectiveIndex = 1,
        },
        {
            id = 6046, action = "TURNIN", text = "Turn in 'Incendosaurs? Whateverosaur is More Like It'",
            mapID = 1427, x = 39.00, y = 27.80, questId = 3373,
        },
        {
            id = 6047, action = "GOTO", text = "Travel to Blasted Lands near the Dark Portal",
            mapID = 1419, x = 50.40, y = 14.20,
        },
        {
            id = 6048, action = "ACCEPT", text = "Accept 'The Basilisk's Bite' from Bloodmage Lynnore",
            mapID = 1419, x = 50.50, y = 14.30, questId = 2581,
        },
        {
            id = 6049, action = "ACCEPT", text = "Accept 'Vulture's Vigor' from Bloodmage Drazial",
            mapID = 1419, x = 50.60, y = 14.20, questId = 2583,
        },
        {
            id = 6050, action = "COMPLETE", text = "Kill Basilisks and Vultures in Blasted Lands for reagent turn-ins",
            mapID = 1419, x = 52.00, y = 35.00, questId = 2581,
        },
        {
            id = 6051, action = "TURNIN", text = "Turn in Blasted Lands beast reagents for massive XP boost",
            mapID = 1419, x = 50.50, y = 14.30, questId = 2581,
        },
        {
            id = 6052, action = "GRIND", text = "Grind to level 51.0 on Red Reavers and Felguard Invaders",
            mapID = 1419, x = 56.00, y = 48.00, targetLevel = 51.0,
        },

        ----------- Level 51-54: Un'Goro Crater (mapID 1449) ---------------
        {
            id = 6053, action = "GOTO", text = "Travel south from Tanaris into Un'Goro Crater",
            mapID = 1449, x = 71.30, y = 76.10,
        },
        {
            id = 6054, action = "ACCEPT", text = "Accept 'Alien Ecology' from Hol'anyee Marshal",
            mapID = 1449, x = 71.40, y = 76.00, questId = 4492,
        },
        {
            id = 6055, action = "ACCEPT", text = "Accept 'The Bone Collector' from Spark Nilminer",
            mapID = 1449, x = 71.50, y = 76.20, questId = 4493,
        },
        {
            id = 6056, action = "ACCEPT", text = "Accept 'Super Sticky Glue' from Torwa Pathfinder",
            mapID = 1449, x = 71.60, y = 76.00, questId = 4491,
        },
        {
            id = 6057, action = "COMPLETE", text = "Collect Power Crystals (Blue, Green, Red, Yellow) at the crystal pylons",
            mapID = 1449, x = 54.00, y = 56.00, questId = 4287,
        },
        {
            id = 6058, action = "COMPLETE", text = "Collect 25 Dinosaur Bones across the tar pits and plains",
            mapID = 1449, x = 65.00, y = 60.00, questId = 4493, objectiveIndex = 1,
        },
        {
            id = 6059, action = "COMPLETE", text = "Kill Pterodactyls for Alien Ecology skins",
            mapID = 1449, x = 45.00, y = 40.00, questId = 4492, objectiveIndex = 1,
        },
        {
            id = 6060, action = "TURNIN", text = "Turn in 'The Bone Collector' to Spark Nilminer",
            mapID = 1449, x = 71.50, y = 76.20, questId = 4493,
        },
        {
            id = 6061, action = "TURNIN", text = "Turn in 'Alien Ecology' to Hol'anyee Marshal",
            mapID = 1449, x = 71.40, y = 76.00, questId = 4492,
        },
        {
            id = 6062, action = "GRIND", text = "Grind to level 54.0 on Tar Lord elementals and Stegodons",
            mapID = 1449, x = 50.00, y = 55.00, targetLevel = 54.0,
        },

        ----------- Level 54-56: Felwood & Winterspring (mapID 1448 & 1452) ---------------
        {
            id = 6063, action = "FLY", text = "Fly to Bloodvenom Post in Felwood",
            mapID = 1448, x = 34.40, y = 53.80,
        },
        {
            id = 6064, action = "SET_HEARTH", text = "Set Hearthstone at Bloodvenom Post",
            mapID = 1448, x = 34.20, y = 54.00,
        },
        {
            id = 6065, action = "ACCEPT", text = "Accept 'Wild Guardians' from Trull Barehoof",
            mapID = 1448, x = 34.60, y = 53.40, questId = 4463,
        },
        {
            id = 6066, action = "COMPLETE", text = "Kill Angerclaw Bears and Felpaw Wolves",
            mapID = 1448, x = 42.00, y = 45.00, questId = 4463,
        },
        {
            id = 6067, action = "TURNIN", text = "Turn in 'Wild Guardians' to Trull Barehoof",
            mapID = 1448, x = 34.60, y = 53.40, questId = 4463,
        },
        {
            id = 6068, action = "GOTO", text = "Pass through Timbermaw Hold tunnel into Winterspring",
            mapID = 1452, x = 61.20, y = 38.60,
        },
        {
            id = 6069, action = "ACCEPT", text = "Accept 'Winterfall Activity' from Salfa at Timbermaw tunnel",
            mapID = 1452, x = 28.50, y = 34.80, questId = 8461,
        },
        {
            id = 6070, action = "GOTO", text = "Arrive at Everlook in central Winterspring",
            mapID = 1452, x = 61.20, y = 38.60,
        },
        {
            id = 6071, action = "ACCEPT", text = "Accept 'Are We There, Yeti?' from Umi Rumplesnicker",
            mapID = 1452, x = 60.80, y = 37.60, questId = 977,
        },
        {
            id = 6072, action = "COMPLETE", text = "Kill 10 Frostsaber Cats and loot 10 Pristine Yeti Horns",
            mapID = 1452, x = 67.00, y = 42.00, questId = 977, objectiveIndex = 1,
        },
        {
            id = 6073, action = "TURNIN", text = "Turn in 'Are We There, Yeti?' to Umi Rumplesnicker",
            mapID = 1452, x = 60.80, y = 37.60, questId = 977,
        },
        {
            id = 6074, action = "GRIND", text = "Grind to level 56.0 on Winterfall Ursa / Shamans in Winterspring",
            mapID = 1452, x = 68.00, y = 36.00, targetLevel = 56.0,
        },

        ----------- Level 56-58: Western Plaguelands (mapID 1422) ---------------
        {
            id = 6075, action = "FLY", text = "Fly via Undercity to The Bulwark on the border of Western Plaguelands",
            mapID = 1422, x = 83.10, y = 71.40,
        },
        {
            id = 6076, action = "SET_HEARTH", text = "Set Hearthstone at The Bulwark Innkeeper",
            mapID = 1422, x = 83.00, y = 71.60,
        },
        {
            id = 6077, action = "ACCEPT", text = "Accept 'Target: Felstone Field' from Shadow Priestess Vandis",
            mapID = 1422, x = 83.20, y = 71.50, questId = 5092,
        },
        {
            id = 6078, action = "COMPLETE", text = "Kill Cauldron Lord Bilemaw at Felstone Field and douse the cauldron",
            mapID = 1422, x = 38.00, y = 56.00, questId = 5092, objectiveIndex = 1,
        },
        {
            id = 6079, action = "TURNIN", text = "Turn in 'Target: Felstone Field' to Shadow Priestess Vandis",
            mapID = 1422, x = 83.20, y = 71.50, questId = 5092,
        },
        {
            id = 6080, action = "ACCEPT", text = "Accept 'Target: Dalson's Tears' from Shadow Priestess Vandis",
            mapID = 1422, x = 83.20, y = 71.50, questId = 5093,
        },
        {
            id = 6081, action = "COMPLETE", text = "Kill Cauldron Lord Malvinious at Dalson's Tears and douse the cauldron",
            mapID = 1422, x = 46.50, y = 52.00, questId = 5093, objectiveIndex = 1,
        },
        {
            id = 6082, action = "TURNIN", text = "Turn in 'Target: Dalson's Tears' to Shadow Priestess Vandis",
            mapID = 1422, x = 83.20, y = 71.50, questId = 5093,
        },
        {
            id = 6083, action = "GRIND", text = "Grind to level 58.0 on Undead Scourge at Sorrow Hill or Dalson's farm",
            mapID = 1422, x = 52.00, y = 78.00, targetLevel = 58.0,
        },

        ----------- Level 58-60: Eastern Plaguelands (mapID 1423) ---------------
        {
            id = 6084, action = "GOTO", text = "Travel east along the road into Eastern Plaguelands to Light's Hope Chapel",
            mapID = 1423, x = 81.50, y = 57.80,
        },
        {
            id = 6085, action = "SET_HEARTH", text = "Set Hearthstone at Light's Hope Chapel Inn",
            mapID = 1423, x = 81.60, y = 57.90,
        },
        {
            id = 6086, action = "ACCEPT", text = "Accept 'The Flesh Does Not Lie' from Betina Bigglezink",
            mapID = 1423, x = 81.40, y = 58.00, questId = 5262,
        },
        {
            id = 6087, action = "ACCEPT", text = "Accept 'The Active Agent' from Betina Bigglezink",
            mapID = 1423, x = 81.40, y = 58.00, questId = 5263,
        },
        {
            id = 6088, action = "ACCEPT", text = "Accept 'Zaeldron's Head' from Caretaker Alen",
            mapID = 1423, x = 81.80, y = 57.50, questId = 5268,
        },
        {
            id = 6089, action = "COMPLETE", text = "Kill Crypt Crawlers and Plague Fiends in Noxious Glade",
            mapID = 1423, x = 60.00, y = 60.00, questId = 5262, objectiveIndex = 1,
        },
        {
            id = 6090, action = "COMPLETE", text = "Kill Zaeldron at the Crypt of the Unforgiven and take his head",
            mapID = 1423, x = 54.00, y = 72.00, questId = 5268, objectiveIndex = 1,
        },
        {
            id = 6091, action = "TURNIN", text = "Turn in 'The Flesh Does Not Lie' to Betina Bigglezink",
            mapID = 1423, x = 81.40, y = 58.00, questId = 5262,
        },
        {
            id = 6092, action = "TURNIN", text = "Turn in 'Zaeldron's Head' to Caretaker Alen",
            mapID = 1423, x = 81.80, y = 57.50, questId = 5268,
        },
        {
            id = 6093, action = "GRIND", text = "Grind to level 60.0 on Scourge at Corin's Crossing / Tyr's Hand",
            mapID = 1423, x = 57.00, y = 65.00, targetLevel = 60.0,
        },
        {
            id = 6094, action = "GOTO", text = "Ding 60! Congratulations! Head to Orgrimmar / Undercity to prepare for Level 60 Raids & WoW Forever Dungeons!",
            mapID = 1454, x = 45.00, y = 65.00, minLevel = 60,
        },
    },
})

-------------------------------------------------------------------------------
-- ALLIANCE 40-60 OPTIMAL SPEEDRUN
-------------------------------------------------------------------------------
FP:RegisterRoute({
    routeId   = "ALLIANCE_40_60_OPTIMAL",
    title     = "Alliance 40-60 Optimal Speedrun",
    faction   = "Alliance",
    minLevel  = 40,
    maxLevel  = 60,
    steps = {
        ----------- Level 40-43: Mount & Badlands (mapID 1418) ---------------
        {
            id = 5001, action = "GOTO", text = "Travel to Badlands via Loch Modan mountain pass",
            mapID = 1418, x = 65.00, y = 43.00, minLevel = 40,
        },
        {
            id = 5002, action = "ACCEPT", text = "Accept 'Badlands Reagent Run' from Ghok Bashgu",
            mapID = 1418, x = 42.10, y = 52.80, questId = 710,
        },
        {
            id = 5003, action = "ACCEPT", text = "Accept 'Study of the Elements' from Lotwil Veriatus",
            mapID = 1418, x = 2.40, y = 36.10, questId = 708,
        },
        {
            id = 5004, action = "COMPLETE", text = "Kill Rock Elementals for 10 Small Stone Shards",
            mapID = 1418, x = 16.50, y = 35.00, questId = 708, objectiveIndex = 1,
        },
        {
            id = 5005, action = "TURNIN", text = "Turn in 'Study of the Elements' to Lotwil Veriatus",
            mapID = 1418, x = 2.40, y = 36.10, questId = 708,
        },
        {
            id = 5006, action = "GRIND", text = "Grind to level 43.0 on Lesser Rock Elementals in Badlands",
            mapID = 1418, x = 24.00, y = 40.00, targetLevel = 43.0,
        },

        ----------- Level 43-45: Tanaris (mapID 1446) ---------------
        {
            id = 5007, action = "FLY", text = "Fly via Theramore to Gadgetzan in Tanaris",
            mapID = 1446, x = 51.60, y = 26.80,
        },
        {
            id = 5008, action = "SET_HEARTH", text = "Set Hearthstone at Gadgetzan Inn",
            mapID = 1446, x = 51.80, y = 27.20,
        },
        {
            id = 5009, action = "ACCEPT", text = "Accept 'Wastewander Justice' from Chief Engineer Bilgewhizzle",
            mapID = 1446, x = 52.40, y = 28.50, questId = 1687,
        },
        {
            id = 5010, action = "ACCEPT", text = "Accept 'Water Pouch Bounty' from Spigot Operator Fizzwich",
            mapID = 1446, x = 52.60, y = 28.10, questId = 1690,
        },
        {
            id = 5011, action = "COMPLETE", text = "Kill 10 Wastewander Bandits, 10 Rogues and collect 5 Water Pouches",
            mapID = 1446, x = 62.00, y = 32.00, questId = 1687,
        },
        {
            id = 5012, action = "TURNIN", text = "Turn in 'Wastewander Justice' to Bilgewhizzle",
            mapID = 1446, x = 52.40, y = 28.50, questId = 1687,
        },
        {
            id = 5013, action = "TURNIN", text = "Turn in 'Water Pouch Bounty' to Fizzwich",
            mapID = 1446, x = 52.60, y = 28.10, questId = 1690,
        },
        {
            id = 5014, action = "GRIND", text = "Grind to level 45.0 on Southsea Pirates or Dunemaul Ogres",
            mapID = 1446, x = 72.00, y = 46.00, targetLevel = 45.0,
        },

        ----------- Level 45-47: Feralas (mapID 1444) ---------------
        {
            id = 5015, action = "FLY", text = "Fly via Thalanaar to Feathermoon Stronghold in Feralas",
            mapID = 1444, x = 30.60, y = 43.40,
        },
        {
            id = 5016, action = "SET_HEARTH", text = "Set Hearthstone at Feathermoon Stronghold Inn",
            mapID = 1444, x = 30.80, y = 43.60,
        },
        {
            id = 5017, action = "ACCEPT", text = "Accept 'The Hatecrest Threat' from Shandris Feathermoon",
            mapID = 1444, x = 30.50, y = 43.00, questId = 2862,
        },
        {
            id = 5018, action = "COMPLETE", text = "Kill 10 Hatecrest Sirens and 8 Wavecallers along the coast",
            mapID = 1444, x = 40.00, y = 45.00, questId = 2862,
        },
        {
            id = 5019, action = "TURNIN", text = "Turn in 'The Hatecrest Threat' to Shandris Feathermoon",
            mapID = 1444, x = 30.50, y = 43.00, questId = 2862,
        },
        {
            id = 5020, action = "GRIND", text = "Grind to level 47.0 on Gordunni Ogres in Feralas",
            mapID = 1444, x = 58.00, y = 68.00, targetLevel = 47.0,
        },

        ----------- Level 47-49: The Hinterlands (mapID 1425) ---------------
        {
            id = 5021, action = "FLY", text = "Fly via Southshore to Aerie Peak in The Hinterlands",
            mapID = 1425, x = 14.20, y = 45.60,
        },
        {
            id = 5022, action = "SET_HEARTH", text = "Set Hearthstone at Aerie Peak Inn",
            mapID = 1425, x = 14.00, y = 45.80,
        },
        {
            id = 5023, action = "ACCEPT", text = "Accept 'Witherbark Cages' from Falfindel",
            mapID = 1425, x = 14.50, y = 46.20, questId = 2875,
        },
        {
            id = 5024, action = "COMPLETE", text = "Kill Silvermane Stalkers and Witherbark Headhunters",
            mapID = 1425, x = 35.00, y = 52.00, questId = 2875,
        },
        {
            id = 5025, action = "TURNIN", text = "Turn in Hinterlands quests at Aerie Peak",
            mapID = 1425, x = 14.50, y = 46.20, questId = 2875,
        },
        {
            id = 5026, action = "GRIND", text = "Grind to level 49.0 on Vilebranch Trolls at Jintha'Alor steps",
            mapID = 1425, x = 60.00, y = 68.00, targetLevel = 49.0,
        },

        ----------- Level 49-51: Searing Gorge & Blasted Lands (mapID 1427 & 1419) ---------------
        {
            id = 5027, action = "FLY", text = "Fly to Thorium Point in Searing Gorge",
            mapID = 1427, x = 37.80, y = 30.90,
        },
        {
            id = 5028, action = "ACCEPT", text = "Accept 'Incendosaurs? Whateverosaur is More Like It'",
            mapID = 1427, x = 39.00, y = 27.80, questId = 3373,
        },
        {
            id = 5029, action = "COMPLETE", text = "Kill 20 Incendosaurs in the magma caves",
            mapID = 1427, x = 45.00, y = 48.00, questId = 3373, objectiveIndex = 1,
        },
        {
            id = 5030, action = "TURNIN", text = "Turn in 'Incendosaurs? Whateverosaur is More Like It'",
            mapID = 1427, x = 39.00, y = 27.80, questId = 3373,
        },
        {
            id = 5031, action = "GOTO", text = "Travel to Nethergarde Keep in Blasted Lands",
            mapID = 1419, x = 65.50, y = 18.20,
        },
        {
            id = 5032, action = "GRIND", text = "Grind to level 51.0 on Felguard and Cultists near the Dark Portal",
            mapID = 1419, x = 56.00, y = 50.00, targetLevel = 51.0,
        },

        ----------- Level 51-54: Un'Goro Crater (mapID 1449) ---------------
        {
            id = 5033, action = "GOTO", text = "Travel to Marshal's Stand in Un'Goro Crater",
            mapID = 1449, x = 44.00, y = 10.00,
        },
        {
            id = 5034, action = "ACCEPT", text = "Accept 'The Bone Collector' from Spark Nilminer",
            mapID = 1449, x = 71.50, y = 76.20, questId = 4493,
        },
        {
            id = 5035, action = "ACCEPT", text = "Accept 'Alien Ecology' from Hol'anyee Marshal",
            mapID = 1449, x = 71.40, y = 76.00, questId = 4492,
        },
        {
            id = 5036, action = "COMPLETE", text = "Collect Power Crystals (Blue, Green, Red, Yellow) across Un'Goro",
            mapID = 1449, x = 54.00, y = 56.00, questId = 4287,
        },
        {
            id = 5037, action = "COMPLETE", text = "Collect 25 Dinosaur Bones for Spark Nilminer",
            mapID = 1449, x = 65.00, y = 60.00, questId = 4493, objectiveIndex = 1,
        },
        {
            id = 5038, action = "TURNIN", text = "Turn in Un'Goro quests at Marshal's Stand",
            mapID = 1449, x = 71.50, y = 76.20, questId = 4493,
        },
        {
            id = 5039, action = "GRIND", text = "Grind to level 54.0 on Tar Lords and Stegodons",
            mapID = 1449, x = 50.00, y = 55.00, targetLevel = 54.0,
        },

        ----------- Level 54-56: Felwood & Winterspring (mapID 1448 & 1452) ---------------
        {
            id = 5040, action = "FLY", text = "Fly via Astranaar to Talonbranch Glade in Felwood",
            mapID = 1448, x = 62.50, y = 24.20,
        },
        {
            id = 5041, action = "ACCEPT", text = "Accept 'Cleansing Felwood' from Arathandris Silversky",
            mapID = 1448, x = 54.20, y = 86.80, questId = 4101,
        },
        {
            id = 5042, action = "GOTO", text = "Run through Timbermaw Hold into Winterspring",
            mapID = 1452, x = 28.50, y = 34.80,
        },
        {
            id = 5043, action = "GOTO", text = "Arrive at Everlook in central Winterspring",
            mapID = 1452, x = 61.20, y = 38.60,
        },
        {
            id = 5044, action = "ACCEPT", text = "Accept 'Are We There, Yeti?' from Umi Rumplesnicker",
            mapID = 1452, x = 60.80, y = 37.60, questId = 977,
        },
        {
            id = 5045, action = "COMPLETE", text = "Loot 10 Pristine Yeti Horns from Ice Thistle Yetis",
            mapID = 1452, x = 67.00, y = 42.00, questId = 977, objectiveIndex = 1,
        },
        {
            id = 5046, action = "TURNIN", text = "Turn in 'Are We There, Yeti?' to Umi Rumplesnicker",
            mapID = 1452, x = 60.80, y = 37.60, questId = 977,
        },
        {
            id = 5047, action = "GRIND", text = "Grind to level 56.0 on Winterfall Ursa / Shamans",
            mapID = 1452, x = 68.00, y = 36.00, targetLevel = 56.0,
        },

        ----------- Level 56-58: Western Plaguelands (mapID 1422) ---------------
        {
            id = 5048, action = "FLY", text = "Fly to Chillwind Camp in Western Plaguelands",
            mapID = 1422, x = 43.80, y = 84.40,
        },
        {
            id = 5049, action = "SET_HEARTH", text = "Set Hearthstone at Chillwind Camp",
            mapID = 1422, x = 43.60, y = 84.60,
        },
        {
            id = 5050, action = "ACCEPT", text = "Accept 'Target: Felstone Field' from High Executor Derrington",
            mapID = 1422, x = 43.70, y = 84.20, questId = 5092,
        },
        {
            id = 5051, action = "COMPLETE", text = "Kill Cauldron Lord Bilemaw at Felstone Field and douse the cauldron",
            mapID = 1422, x = 38.00, y = 56.00, questId = 5092, objectiveIndex = 1,
        },
        {
            id = 5052, action = "TURNIN", text = "Turn in 'Target: Felstone Field' at Chillwind Camp",
            mapID = 1422, x = 43.70, y = 84.20, questId = 5092,
        },
        {
            id = 5053, action = "GRIND", text = "Grind to level 58.0 on Undead Scourge at Sorrow Hill",
            mapID = 1422, x = 52.00, y = 78.00, targetLevel = 58.0,
        },

        ----------- Level 58-60: Eastern Plaguelands (mapID 1423) ---------------
        {
            id = 5054, action = "GOTO", text = "Travel to Light's Hope Chapel in Eastern Plaguelands",
            mapID = 1423, x = 81.50, y = 57.80,
        },
        {
            id = 5055, action = "SET_HEARTH", text = "Set Hearthstone at Light's Hope Chapel Inn",
            mapID = 1423, x = 81.60, y = 57.90,
        },
        {
            id = 5056, action = "ACCEPT", text = "Accept 'The Flesh Does Not Lie' from Betina Bigglezink",
            mapID = 1423, x = 81.40, y = 58.00, questId = 5262,
        },
        {
            id = 5057, action = "COMPLETE", text = "Kill Crypt Crawlers and Plague Fiends in Noxious Glade",
            mapID = 1423, x = 60.00, y = 60.00, questId = 5262, objectiveIndex = 1,
        },
        {
            id = 5058, action = "TURNIN", text = "Turn in 'The Flesh Does Not Lie' to Betina Bigglezink",
            mapID = 1423, x = 81.40, y = 58.00, questId = 5262,
        },
        {
            id = 5059, action = "GRIND", text = "Grind to level 60.0 on Scourge at Corin's Crossing or Tyr's Hand",
            mapID = 1423, x = 57.00, y = 65.00, targetLevel = 60.0,
        },
        {
            id = 5060, action = "GOTO", text = "Ding 60! Congratulations! Head to Stormwind / Ironforge to prepare for Level 60 Raids & WoW Forever Dungeons!",
            mapID = 1453, x = 55.00, y = 50.00, minLevel = 60,
        },
    },
})
