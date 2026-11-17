-------------------------------------------------------------------------------
-- NexKit - Data/HiddenQuestPOIs.lua
-- Database of hidden quests, riddles, treasure hunts, and missing-POI quests
-- in World of Warcraft Classic (Interface 16001 / 11505).
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function UseItalian()
    if FP.GetEffectiveLocale then
        return FP:GetEffectiveLocale() == "itIT"
    end
    return false
end

-------------------------------------------------------------------------------
-- Curated Hidden / Riddle / Unmarked Classic Quests
-------------------------------------------------------------------------------
FP.HIDDEN_QUEST_POIS = {
    ---------------------------------------------------------------------------
    -- Westfall: Captain Sanders' Hidden Treasure (Full Chain)
    ---------------------------------------------------------------------------
    [136] = { -- Captain Sanders' Hidden Treasure (Part 1 - Map from Murlocs)
        mapID = 1436, x = 25.9, y = 47.8,
        target = "Captain Sanders' Footlocker",
        targetIt = "Baule di Capitan Sanders",
        descEn = "On the western beach next to a rusty anchor and shipwreck, south of Gold Coast Quarry.",
        descIt = "Sulla spiaggia a ovest accanto a un'ancora arrugginita e a un relitto, a sud di Gold Coast Quarry.",
        hint = "Westfall (25.9, 47.8)",
    },
    [138] = { -- Captain Sanders' Hidden Treasure (Part 2 - Old Barrel)
        mapID = 1436, x = 40.6, y = 47.8,
        target = "Old Barrel",
        targetIt = "Vecchio Barile",
        descEn = "Inside broken barrel by the stone chimney ruin near the road, due east up the cliffs from the beach.",
        descIt = "Nel vecchio barile rotto vicino ai ruderi del camino a bordo strada, dritto a est su per le scogliere.",
        hint = "Westfall (40.6, 47.8)",
    },
    [139] = { -- Captain Sanders' Hidden Treasure (Part 3 - Old Jug)
        mapID = 1436, x = 40.6, y = 17.1,
        target = "Old Jug",
        targetIt = "Vecchia Brocca d'Acqua",
        descEn = "At the base of the lone windmill on the northern coastal bluffs of Westfall.",
        descIt = "Ai piedi del mulino a vento solitario sulle scogliere costiere a nord di Westfall.",
        hint = "Westfall (40.6, 17.1)",
    },
    [140] = { -- Captain Sanders' Hidden Treasure (Part 4 - The Chest)
        mapID = 1436, x = 26.0, y = 17.0,
        target = "Captain Sanders' Chest",
        targetIt = "Scrigno del Tesoro di Capitan Sanders",
        descEn = "Locked chest on the small offshore island in northwest Westfall (swim west from the windmill).",
        descIt = "Scrigno chiuso a chiave sul piccolo isolotto a nord-ovest di Westfall (nuota a ovest dal mulino).",
        hint = "Westfall (26.0, 17.0)",
    },

    ---------------------------------------------------------------------------
    -- Westfall: Miscellaneous Hidden Items
    ---------------------------------------------------------------------------
    [151] = { -- The Forgotten Heirloom
        mapID = 1436, x = 37.8, y = 52.8,
        target = "Furlbrow's Cupboard",
        targetIt = "Armadio di Furlbrow",
        descEn = "Inside the ruined farmhouse cupboard at Furlbrow's Pumpkin Farm.",
        descIt = "Nell'armadio dentro la fattoria diroccata di Furlbrow.",
        hint = "Westfall (37.8, 52.8)",
    },
    [263] = { -- A Threat Within Furlbrow's Farm
        mapID = 1436, x = 37.8, y = 52.8,
        target = "Furlbrow's Deed",
        targetIt = "Atto di Proprietà di Furlbrow",
        descEn = "Overturned wagon at Furlbrow's Pumpkin Farm.",
        descIt = "Nel carro rovesciato alla fattoria delle zucche di Furlbrow.",
        hint = "Westfall (37.8, 52.8)",
    },
    [153] = { -- Poor Old Blanchy
        mapID = 1436, x = 56.0, y = 31.0,
        target = "Handful of Oats",
        targetIt = "Manciata d'Avena",
        descEn = "Sacks of oats scattered on the ground around Saldean's Farm.",
        descIt = "Sacchi di avena sparsi a terra intorno alla fattoria Saldean.",
        hint = "Westfall (56.0, 31.0)",
    },

    ---------------------------------------------------------------------------
    -- Cortello's Riddle (Full Chain: Stranglethorn -> Swamp -> Dustwallow -> Hinterlands)
    ---------------------------------------------------------------------------
    [622] = { -- Cortello's Riddle (Part 1 - Swamp of Sorrows)
        mapID = 1435, x = 22.9, y = 48.4,
        target = "Under the Bridge",
        targetIt = "Sotto il Ponte di Legno",
        descEn = "Hidden chest submerged under the wooden bridge connecting Deadwind Pass & Swamp of Sorrows.",
        descIt = "Baule nascosto sotto il ponte di legno tra Valico Ventomorto e la Palude dei Dolori.",
        hint = "Swamp of Sorrows (22.9, 48.4)",
    },
    [623] = { -- Cortello's Riddle (Part 2 - Dustwallow Marsh)
        mapID = 1445, x = 31.8, y = 66.1,
        target = "Raptor Cave Chest",
        targetIt = "Baule nella Grotta dei Raptor",
        descEn = "Inside the raptor cave at the southern end of the Bloodfen raptor area.",
        descIt = "Dentro la caverna dei raptor all'estremità sud dell'area di Bloodfen.",
        hint = "Dustwallow Marsh (31.8, 66.1)",
    },
    [624] = { -- Cortello's Riddle (Part 3 - The Hinterlands)
        mapID = 1425, x = 80.7, y = 46.9,
        target = "Waterfall Treasure",
        targetIt = "Tesoro sotto la Cascata",
        descEn = "Behind the roaring waterfall overlooking the sea in eastern Hinterlands.",
        descIt = "Dietro la grande cascata che dà sul mare a est delle Entroterre.",
        hint = "The Hinterlands (80.7, 46.9)",
    },

    ---------------------------------------------------------------------------
    -- Tanaris: Message in a Bottle
    ---------------------------------------------------------------------------
    [2875] = { -- Message in a Bottle (Part 1)
        mapID = 1446, x = 52.8, y = 88.5,
        target = "Half-Buried Shipwreck",
        targetIt = "Relitto Insabbiato",
        descEn = "Half-buried shipwreck on Southbreak Shore, southeast Tanaris.",
        descIt = "Relitto mezza affondato sulla Costa della Riva Sud, sud-est di Tanaris.",
        hint = "Tanaris (52.8, 88.5)",
    },
    [2876] = { -- Message in a Bottle (Part 2)
        mapID = 1446, x = 58.0, y = 95.8,
        target = "Land's End Beach Camp",
        targetIt = "Accampamento della Fine del Mondo",
        descEn = "Isolated beach camp at the southernmost tip of Tanaris (swim south).",
        descIt = "Accampamento sulla spiaggia all'estremo sud di Tanaris (nuota verso sud).",
        hint = "Tanaris (58.0, 95.8)",
    },

    ---------------------------------------------------------------------------
    -- Loch Modan: Sunken Items
    ---------------------------------------------------------------------------
    [267] = { -- The Lost Tools
        mapID = 1432, x = 46.5, y = 13.5,
        target = "Ironband's Toolbox",
        targetIt = "Cassa degli Attrezzi",
        descEn = "Sunken toolbox underwater in the lake near northern shore.",
        descIt = "Cassa degli attrezzi sommersa sott'acqua nella parte nord del lago.",
        hint = "Loch Modan (46.5, 13.5)",
    },
    [309] = { -- The Sunken Chest
        mapID = 1432, x = 36.8, y = 18.2,
        target = "Sunken Lockbox",
        targetIt = "Baule Sommerso",
        descEn = "Underwater locked chest by the submerged ruins of the pavilion in the lake.",
        descIt = "Baule chiuso a chiave sott'acqua vicino ai ruderi del padiglione nel lago.",
        hint = "Loch Modan (36.8, 18.2)",
    },
    [716] = { -- The Lost Ingots
        mapID = 1432, x = 36.8, y = 18.2,
        target = "Sunken Barrel",
        targetIt = "Barile di Lingotti Sommerso",
        descEn = "Sunken barrel in the lake near the submerged pavilion.",
        descIt = "Barile affondato nel lago vicino al padiglione sommerso.",
        hint = "Loch Modan (36.8, 18.2)",
    },

    ---------------------------------------------------------------------------
    -- Darkshore: Beached Sea Creatures & Caves
    ---------------------------------------------------------------------------
    [4735] = { -- Beached Sea Creature (Bones)
        mapID = 1439, x = 53.2, y = 18.1,
        target = "Giant Sea Creature Bones",
        targetIt = "Ossa della Creatura Marina",
        descEn = "Giant bones on northern Darkshore beach.",
        descIt = "Enormi ossa sulla spiaggia a nord di Rivaoscura.",
        hint = "Darkshore (53.2, 18.1)",
    },
    [4728] = { -- Sea Turtle Remains
        mapID = 1439, x = 53.0, y = 27.6,
        target = "Sea Turtle Remains",
        targetIt = "Resti di Tartaruga Marina",
        descEn = "Turtle skeleton on the shore north of Auberdine.",
        descIt = "Scheletro di tartaruga sulla riva a nord di Auberdine.",
        hint = "Darkshore (53.0, 27.6)",
    },
    [4727] = { -- Beached Sea Monster
        mapID = 1439, x = 42.0, y = 50.8,
        target = "Beached Sea Monster",
        targetIt = "Mostro Marino Spiaggiato",
        descEn = "Sea monster remains on the shore south of Auberdine.",
        descIt = "Resti di mostro marino sulla riva a sud di Auberdine.",
        hint = "Darkshore (42.0, 50.8)",
    },
    [4725] = { -- Skeletal Sea Turtle
        mapID = 1439, x = 37.0, y = 62.0,
        target = "Skeletal Sea Turtle",
        targetIt = "Tartaruga Marina Scheletrica",
        descEn = "Turtle shell remains near Ameth'Aran coast.",
        descIt = "Carapace di tartaruga sulla spiaggia vicino ad Ameth'Aran.",
        hint = "Darkshore (37.0, 62.0)",
    },
    [4722] = { -- Plesiosaur Remains
        mapID = 1439, x = 36.4, y = 76.2,
        target = "Plesiosaur Remains",
        targetIt = "Resti di Plesiosauro",
        descEn = "Huge spine on the southern shore near Master's Glaive.",
        descIt = "Enorme colonna vertebrale sulla costa a sud vicino al Falcione del Maestro.",
        hint = "Darkshore (36.4, 76.2)",
    },
    [954] = { -- A Lost Master
        mapID = 1439, x = 43.7, y = 76.3,
        target = "Volcor (Cave)",
        targetIt = "Volcor (Caverna)",
        descEn = "Volcor inside the cultist cave overlooking Master's Glaive.",
        descIt = "Volcor dentro la caverna dei cultisti sopra il Falcione del Maestro.",
        hint = "Darkshore (43.7, 76.3)",
    },

    ---------------------------------------------------------------------------
    -- Wetlands: Sunken Ships & Lost Iron
    ---------------------------------------------------------------------------
    [464] = { -- The Third Fleet
        mapID = 1437, x = 13.8, y = 40.2,
        target = "Sunken Shipwreck",
        targetIt = "Relitto Sommerso",
        descEn = "Sunken shipwrecks off the western Wetlands coast.",
        descIt = "Relitti delle navi affondate al largo della costa delle Paludi.",
        hint = "Wetlands (13.8, 40.2)",
    },
    [474] = { -- Lightforge Iron
        mapID = 1437, x = 10.5, y = 59.8,
        target = "Waterlogged Chest",
        targetIt = "Baule Inondato",
        descEn = "Waterlogged chest in sunken wreckage near southern coast.",
        descIt = "Baule inondato nel relitto subacqueo vicino alla costa a sud.",
        hint = "Wetlands (10.5, 59.8)",
    },

    ---------------------------------------------------------------------------
    -- Un'Goro Crater: Linken's Chain & Mechanical Gorilla
    ---------------------------------------------------------------------------
    [4022] = { -- It's a Secret to Everybody (Linken)
        mapID = 1449, x = 63.2, y = 68.6,
        target = "Submerged Boat",
        targetIt = "Barca Sommersa",
        descEn = "Submerged rowboat in the eastern hot spring pool.",
        descIt = "Barca a remi sommersa nella pozza termale a est.",
        hint = "Un'Goro Crater (63.2, 68.6)",
    },
    [4024] = { -- Meet at the Grave (Gaeriyan)
        mapID = 1446, x = 53.7, y = 28.8,
        target = "Gaeriyan's Grave",
        targetIt = "Tomba di Gaeriyan",
        descEn = "You MUST be a GHOST (die first!) to talk to Gaeriyan at the graveyard north of Gadgetzan.",
        descIt = "Devi essere FANTASMA (muori prima!) per parlare con Gaeriyan al cimitero a nord di Gadgetzan.",
        hint = "Tanaris (53.7, 28.8) [FANTASMA]",
    },
    [4492] = { -- Chasing A-Me 01
        mapID = 1449, x = 63.8, y = 16.0,
        target = "A-Me 01 (Mechanical Ape)",
        targetIt = "A-Me 01 (Scimmia Meccanica)",
        descEn = "Damaged mechanical gorilla inside the deepest room of the gorilla cave.",
        descIt = "Gorilla meccanico danneggiato nella stanza più profonda della grotta dei gorilla.",
        hint = "Un'Goro Crater (63.8, 16.0)",
    },
    [4495] = { -- Super Sticky Glue
        mapID = 1449, x = 71.0, y = 76.0,
        target = "Tar Pits",
        targetIt = "Pozze di Catrame",
        descEn = "Gather tar from bubbling tar pits in southeast Un'Goro.",
        descIt = "Raccogli catrame dalle pozze ribollenti nel sud-est di Un'Goro.",
        hint = "Un'Goro Crater (71.0, 76.0)",
    },

    ---------------------------------------------------------------------------
    -- Stonetalon / Dustwallow / Swamp
    ---------------------------------------------------------------------------
    [982] = { -- Deepmoss Spider Eggs
        mapID = 1442, x = 58.5, y = 76.5,
        target = "Spider Egg Clutches",
        targetIt = "Uova di Ragno",
        descEn = "Glowing egg sacs hanging under webbed trees in Webwinder Path.",
        descIt = "Sacche di uova luminose appese sotto gli alberi ragnatelati.",
        hint = "Stonetalon Mountains (58.5, 76.5)",
    },
    [1136] = { -- The Hermit of Swamplight Manor
        mapID = 1445, x = 55.4, y = 26.2,
        target = "Jarl's Shack",
        targetIt = "Capanna di Jarl",
        descEn = "Lonely shack on the swamp island in central Dustwallow.",
        descIt = "Capanna isolata sull'isolotto della palude al centro di Acquemorte.",
        hint = "Dustwallow Marsh (55.4, 26.2)",
    },
    [1205] = { -- The Missing Diplomat (Private Hendel)
        mapID = 1445, x = 45.4, y = 56.6,
        target = "Private Hendel",
        targetIt = "Soldato Hendel",
        descEn = "Guarding the southern sentry camp in Dustwallow Marsh.",
        descIt = "Di guardia all'accampamento di sentinelle a sud di Acquemorte.",
        hint = "Dustwallow Marsh (45.4, 56.6)",
    },
    [1068] = { -- In Search of the Temple
        mapID = 1435, x = 69.5, y = 53.6,
        target = "Sunken Temple (Exterior)",
        targetIt = "Tempio Sommerso (Esterno)",
        descEn = "Submerged ruins in the center of Lake Sorrowmurk.",
        descIt = "Rovine sommerse al centro del lago Sorrowmurk.",
        hint = "Swamp of Sorrows (69.5, 53.6)",
    },

    ---------------------------------------------------------------------------
    -- Cozy Sleeping Bag (Sacco a Pelo Accogliente) - SoD & WoW Forever
    ---------------------------------------------------------------------------
    [79008] = { -- ...and that note you found (Step 1)
        mapID = 1413, x = 46.3, y = 73.9, -- Alliance destination: The Barrens
        target = "Burned-Out Remains (Burnt Tower)",
        targetIt = "Resti Bruciati (Torre a sud di Taurajo)",
        descEn = "Travel to The Barrens! Search the burned scouting tower south of Camp Taurajo.",
        descIt = "Raggiungi le Savane (The Barrens)! Trova la torre di vedetta bruciata a sud di Camp Taurajo ed esamina le macerie a terra.",
        hint = "The Barrens (46.3, 73.9)",
    },
    [79009] = { -- Stepping Stones (Step 2)
        mapID = 1442, x = 40.8, y = 52.6,
        target = "Pocket Litter (Abandoned Camp)",
        targetIt = "Spazzatura Tascabile (Accampamento)",
        descEn = "Climb the mountain trail (starts at 50.9, 52.3 NE of Sun Rock) to the abandoned camp. Inspect Pocket Litter on the crate!",
        descIt = "Sali il sentiero nascosto (a 50.9, 52.3 a nord-est di Sun Rock Retreat) fino all'accampamento sui monti. Clicca la Spazzatura Tascabile sulla cassa!",
        hint = "Stonetalon Mountains (40.8, 52.6)",
    },
    [79010] = { -- Scramble (Step 3)
        mapID = 1442, x = 39.6, y = 49.9,
        target = "Mound of Dirt (Ledge Gap)",
        targetIt = "Mucchio di Terra (Cengia Rocciosa)",
        descEn = "North of the camp along the cliff edge. Jump across the gap onto the ledge and click the Mound of Dirt.",
        descIt = "A nord dell'accampamento lungo la rupe. Salta il crepaccio sulla sporgenza di roccia ed esamina il Mucchio di Terra.",
        hint = "Stonetalon Mountains (39.6, 49.9)",
    },
    [79011] = { -- Wet Job (Step 4)
        mapID = 1432, x = 49.4, y = 12.9,
        target = "Carved Figurine (Stonewrought Dam)",
        targetIt = "Statuetta Scolpita (Diga Stonewrought)",
        descEn = "On Stonewrought Dam in northern Loch Modan. Jump down onto the stone carved heads facing Wetlands and click the Carved Figurine.",
        descIt = "Sulla diga Stonewrought a nord di Loch Modan. Calati sulle teste di pietra scolpite sul lato verso le Wetlands e clicca la Statuetta Scolpita.",
        hint = "Loch Modan (49.4, 12.9)",
    },
    [79012] = { -- Eagle's Fist (Step 5)
        mapID = 1424, x = 87.3, y = 49.6,
        target = "Messenger Bag (Thoradin's Wall)",
        targetIt = "Borsa da Messaggero (Muraglia di Thoradin)",
        descEn = "Climb onto Thoradin's Wall via the cart on Hillsbrad side. Enter the inner wall breach to find the hanging Messenger Bag.",
        descIt = "Sali sulla Muraglia di Thoradin usando il carro rotto sul versante di Hillsbrad. Entra nella breccia per trovare la Borsa da Messaggero appesa.",
        hint = "Hillsbrad Foothills (87.3, 49.6)",
    },
    [79013] = { -- This Must Be The Place (Step 6)
        mapID = 1424, x = 87.3, y = 49.6,
        target = "Hastily Rolled-Up Satchel (Cozy Sleeping Bag)",
        targetIt = "Sacca Arrotolata (Sacco a Pelo Accogliente)",
        descEn = "Right beside the messenger bag on Thoradin's Wall, click the Satchel to claim your Cozy Sleeping Bag and Student Fodder!",
        descIt = "Accanto alla borsa da messaggero sulla Muraglia di Thoradin, clicca la Sacca Arrotolata per ricevere il tuo Sacco a Pelo Accogliente!",
        hint = "Hillsbrad Foothills (87.3, 49.6)",
    },

    ---------------------------------------------------------------------------
    -- Redridge Mountains
    ---------------------------------------------------------------------------
    [3741] = { -- Hilary's Necklace
        mapID = 1433, x = 25.9, y = 54.2,
        target = "Glinting Mud (Hilary's Necklace)",
        targetIt = "Fango Luccicante (Collana di Hilary)",
        descEn = "At the bottom of Lake Everstill just south-east of the Lakeshire docks (25.9, 54.2 / 23.0, 54.0).",
        descIt = "Sul fondale del Lago Placidus a sud-est del molo di Borgolago (25.9, 54.2 / 23.0, 54.0).",
        hint = "Redridge Mountains (25.9, 54.2)",
    },
    [123] = { -- Hilary's Necklace (Legacy alias)
        mapID = 1433, x = 25.9, y = 54.2,
        target = "Glinting Mud (Hilary's Necklace)",
        targetIt = "Fango Luccicante (Collana di Hilary)",
        descEn = "At the bottom of Lake Everstill just south-east of the Lakeshire docks (25.9, 54.2 / 23.0, 54.0).",
        descIt = "Sul fondale del Lago Placidus a sud-est del molo di Borgolago (25.9, 54.2 / 23.0, 54.0).",
        hint = "Redridge Mountains (25.9, 54.2)",
    },
    [125] = { -- The Lost Tools (Foreman Oslow)
        mapID = 1433, x = 41.5, y = 54.7,
        target = "Sunken Chest (Oslow's Toolbox)",
        targetIt = "Cassa Sommersa (Attrezzi di Oslow)",
        descEn = "Sunken chest at the bottom of Lake Everstill (41.5, 54.7).",
        descIt = "Cassa sommersa sul fondale del Lago Placidus (41.5, 54.7).",
        hint = "Redridge Mountains (41.5, 54.7)",
    },

    ---------------------------------------------------------------------------
    -- Elwynn Forest
    ---------------------------------------------------------------------------
    [88] = { -- Princess Must Die!
        mapID = 1429, x = 38.2, y = 84.8,
        target = "Princess (The Prize Pig)",
        targetIt = "Principessa (Il Maialone Premiato)",
        descEn = "Rooting around the Brackwell Pumpkin Patch.",
        descIt = "Gira nel campo di zucche di Brackwell a sud di Elwynn.",
        hint = "Elwynn Forest (38.2, 84.8)",
    },

    ---------------------------------------------------------------------------
    -- Wetlands
    ---------------------------------------------------------------------------
    [637] = { -- Sully Balloo's Letter
        mapID = 1437, x = 47.0, y = 11.2,
        target = "Sunken Wreckage (Thandol Span)",
        targetIt = "Relitto Sommerso (Sotto il Ponte di Thandol)",
        descEn = "Underwater wreckage deep below the broken Thandol Span bridge connecting Wetlands to Arathi.",
        descIt = "Relitto subacqueo in profondità sotto il ponte crollato di Thandol tra le Paludi e Arathi.",
        hint = "Wetlands (47.0, 11.2)",
    },

    ---------------------------------------------------------------------------
    -- The Barrens
    ---------------------------------------------------------------------------
    [899] = { -- Lost in Battle (Mankrik's Wife)
        mapID = 1413, x = 49.2, y = 50.4,
        target = "Beaten Corpse (Mankrik's Wife)",
        targetIt = "Corpo Martoriato (Moglie di Mankrik)",
        descEn = "Beaten corpse south of the Crossroads near the river.",
        descIt = "Corpo martoriato a sud del Crocevia vicino al fiume.",
        hint = "The Barrens (49.2, 50.4)",
    },
    [4921] = { -- Lost in Battle (Horde variant)
        mapID = 1413, x = 49.2, y = 50.4,
        target = "Beaten Corpse (Mankrik's Wife)",
        targetIt = "Corpo Martoriato (Moglie di Mankrik)",
        descEn = "Beaten corpse south of the Crossroads near the river.",
        descIt = "Corpo martoriato a sud del Crocevia vicino al fiume.",
        hint = "The Barrens (49.2, 50.4)",
    },
    [848] = { -- The Stolen Silver
        mapID = 1413, x = 58.0, y = 53.8,
        target = "Stolen Silver Chest",
        targetIt = "Cassa dell'Argento Rubato",
        descEn = "Inside a raptor nest on the high hills north of Northwatch Hold.",
        descIt = "Dentro un nido di raptor sulle alture a nord del Forte di Guardanord.",
        hint = "The Barrens (58.0, 53.8)",
    },
    [894] = { -- Samophlange
        mapID = 1413, x = 52.4, y = 11.6,
        target = "Control Console",
        targetIt = "Console dei Comandi",
        descEn = "Sludge Fen control console near the oil drills.",
        descIt = "Console di controllo alla Palude Melmosa (Sludge Fen) vicino alle trivelle.",
        hint = "The Barrens (52.4, 11.6)",
    },
    [902] = { -- Manual of the Samophlange
        mapID = 1413, x = 52.4, y = 11.6,
        target = "Control Console",
        targetIt = "Console dei Comandi",
        descEn = "Sludge Fen control console valves.",
        descIt = "Valvole della console di controllo a Sludge Fen.",
        hint = "The Barrens (52.4, 11.6)",
    },
    [819] = { -- Chen's Empty Keg
        mapID = 1413, x = 55.5, y = 43.0,
        target = "Brewmaster Drohn",
        targetIt = "Mastro Birraio Drohn",
        descEn = "Turn in to Brewmaster Drohn in Ratchet.",
        descIt = "Consegna a Mastro Birraio Drohn a Ratchet.",
        hint = "The Barrens (55.5, 43.0)",
    },

    ---------------------------------------------------------------------------
    -- Tanaris
    ---------------------------------------------------------------------------
    [2877] = { -- Cuergo's Gold (Pirate's Treasure Map)
        mapID = 1446, x = 61.0, y = 68.0,
        target = "Buried Treasure Chest",
        targetIt = "Scrigno del Tesoro Sepolto",
        descEn = "Buried chest under palm trees on Land's End Beach in southern Tanaris.",
        descIt = "Scrigno sepolto sotto le palme sulla Spiaggia del Capo del Mondo nel sud di Tanaris.",
        hint = "Tanaris (61.0, 68.0)",
    },
    [2878] = { -- Cuergo's Gold (Turn-in)
        mapID = 1446, x = 61.0, y = 68.0,
        target = "Buried Treasure Chest",
        targetIt = "Scrigno del Tesoro Sepolto",
        descEn = "Buried chest on Land's End Beach in southern Tanaris.",
        descIt = "Scrigno sepolto sulla Spiaggia del Capo del Mondo nel sud di Tanaris.",
        hint = "Tanaris (61.0, 68.0)",
    },

    ---------------------------------------------------------------------------
    -- Season of Discovery & WoW Forever Secrets
    ---------------------------------------------------------------------------
    [99001] = { -- Grizzby's Mercenary Contracts
        mapID = 1413, x = 62.2, y = 39.4,
        target = "Grizzby (Ratchet Inn)",
        targetIt = "Grizzby (Locanda di Ratchet)",
        descEn = "Inside the Ratchet inn by the counter.",
        descIt = "Dentro la locanda di Ratchet accanto al bancone.",
        hint = "The Barrens (62.2, 39.4)",
    },
    [99002] = { -- Highway Robbery
        mapID = 1443, x = 56.3, y = 49.8,
        target = "Extinguished Campfire",
        targetIt = "Fuoco da Campo Spento (Kormek)",
        descEn = "Extinguished campfire near Kormek's Hut in central Desolace.",
        descIt = "Fuoco da campo spento vicino alla capanna di Kormek al centro di Desolace.",
        hint = "Desolace (56.3, 49.8)",
    },
}

-------------------------------------------------------------------------------
-- Helper: Get Hidden Quest POI Data
-------------------------------------------------------------------------------
function FP:GetHiddenQuestData(questID, questTitle, questText)
    local isIt = UseItalian()
    local qNum = tonumber(questID)
    if (not questTitle or questTitle == "") and C_QuestLog and C_QuestLog.GetTitleForQuestID and IsSafeNum(qNum) then
        local ok, t = pcall(C_QuestLog.GetTitleForQuestID, qNum)
        if ok and IsSafeStr(t) then questTitle = t end
    end
    local lower = IsSafeStr(questTitle) and questTitle:lower() or ""
    local txtLower = IsSafeStr(questText) and questText:lower() or ""

    -- 1. Direct QuestID Match
    if IsSafeNum(qNum) and self.HIDDEN_QUEST_POIS[qNum] then
        local d = self.HIDDEN_QUEST_POIS[qNum]
        -- Handle dynamic faction for Cozy Sleeping Bag Step 1
        if qNum == 79008 then
            local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
            if faction == "Horde" then
                return {
                    questID  = qNum,
                    mapID    = 1436,
                    x        = 37.3,
                    y        = 50.7,
                    title    = isIt and "Resti Bruciati (Carro ad Alexston Farmstead)" or "Burned-Out Remains (Alexston Farmstead)",
                    desc     = isIt and "Raggiungi le Marche Occidentali (Westfall)! Trova il carro bruciato alla fattoria Alexston ed esamina i resti bruciati." or "Travel to Westfall! Locate the burned-out wagon at Alexston Farmstead and search the scorched debris.",
                    hint     = "Westfall (37.3, 50.7)",
                    isRiddle = true,
                }
            end
        end
        return {
            questID  = qNum,
            mapID    = d.mapID,
            x        = d.x,
            y        = d.y,
            title    = (isIt and d.targetIt) or d.target,
            desc     = (isIt and d.descIt) or d.descEn,
            hint     = d.hint,
            isRiddle = true,
        }
    end

    -- 2. Title & Text pattern matching
    if lower ~= "" or txtLower ~= "" then
        -- A. Cozy Sleeping Bag: Step 1 (...and that note you found)
        if lower:find("note you found", 1, true)
            or lower:find("that note", 1, true)
            or lower:find("quella nota", 1, true)
            or lower:find("quel biglietto", 1, true)
            or txtLower:find("terra gemella", 1, true)
            or txtLower:find("twin land", 1, true)
            or txtLower:find("resti carbonizzati", 1, true)
            or txtLower:find("charred remains", 1, true)
            or txtLower:find("biglietto bruciacchiato", 1, true)
            or (txtLower:find("non tutto", 1, true) and txtLower:find("brucia", 1, true))
        then
            local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
            if faction == "Horde" then
                return {
                    questID  = 79008,
                    mapID    = 1436,
                    x        = 37.3,
                    y        = 50.7,
                    title    = isIt and "Resti Bruciati (Carro ad Alexston Farmstead)" or "Burned-Out Remains (Alexston Farmstead)",
                    desc     = isIt and "Raggiungi le Marche Occidentali (Westfall)! Trova il carro bruciato alla fattoria Alexston ed esamina i resti bruciati." or "Travel to Westfall! Locate the burned-out wagon at Alexston Farmstead and search the scorched debris.",
                    hint     = "Westfall (37.3, 50.7)",
                    isRiddle = true,
                }
            else
                return {
                    questID  = 79008,
                    mapID    = 1413,
                    x        = 46.3,
                    y        = 73.9,
                    title    = isIt and "Resti Bruciati (Torre a sud di Taurajo)" or "Burned-Out Remains (Burnt Tower)",
                    desc     = isIt and "Raggiungi le Savane (The Barrens)! Trova la torre di vedetta bruciata a sud di Camp Taurajo ed esamina le macerie a terra." or "Travel to The Barrens! Search the burned scouting tower south of Camp Taurajo.",
                    hint     = "The Barrens (46.3, 73.9)",
                    isRiddle = true,
                }
            end
        end

        -- B. Cozy Sleeping Bag: Step 2 (Stepping Stones)
        if lower:find("stepping stones", 1, true)
            or lower:find("pietre di passaggio", 1, true)
            or txtLower:find("pocket litter", 1, true)
            or txtLower:find("spazzatura tascabile", 1, true)
        then
            local d = self.HIDDEN_QUEST_POIS[79009]
            if d then
                return {
                    questID  = 79009,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- C. Cozy Sleeping Bag: Step 3 (Scramble)
        if lower:find("scramble", 1, true)
            or lower:find("arrampicata", 1, true)
            or txtLower:find("mucchio di terra", 1, true)
            or txtLower:find("mound of dirt", 1, true)
        then
            local d = self.HIDDEN_QUEST_POIS[79010]
            if d then
                return {
                    questID  = 79010,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- D. Cozy Sleeping Bag: Step 4 (Wet Job)
        if lower:find("wet job", 1, true)
            or lower:find("lavoro bagnato", 1, true)
            or txtLower:find("carved figurine", 1, true)
            or txtLower:find("statuetta scolpita", 1, true)
            or (txtLower:find("dam", 1, true) and txtLower:find("wetlands", 1, true))
        then
            local d = self.HIDDEN_QUEST_POIS[79011]
            if d then
                return {
                    questID  = 79011,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- E. Cozy Sleeping Bag: Step 5 (Eagle's Fist)
        if lower:find("eagle's fist", 1, true)
            or lower:find("eagles fist", 1, true)
            or lower:find("pugno dell'aquila", 1, true)
            or txtLower:find("messenger bag", 1, true)
            or txtLower:find("borsa da messaggero", 1, true)
        then
            local d = self.HIDDEN_QUEST_POIS[79012]
            if d then
                return {
                    questID  = 79012,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- F. Cozy Sleeping Bag: Step 6 (This Must Be The Place)
        if lower:find("this must be the place", 1, true)
            or lower:find("questo deve essere il posto", 1, true)
            or txtLower:find("sleeping bag", 1, true)
            or txtLower:find("sacco a pelo", 1, true)
        then
            local d = self.HIDDEN_QUEST_POIS[79013]
            if d then
                return {
                    questID  = 79013,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- G. Captain Sanders' Hidden Treasure (Full Chain disambiguation)
        if lower:find("sanders", 1, true) then
            local targetID = 138 -- default to part 2
            if txtLower:find("barile", 1, true) or txtLower:find("barrel", 1, true) or txtLower:find("camino", 1, true) or txtLower:find("chimney", 1, true) then
                targetID = 138
            elseif txtLower:find("brocca", 1, true) or txtLower:find("jug", 1, true) or txtLower:find("mulino", 1, true) or txtLower:find("windmill", 1, true) then
                targetID = 139
            elseif txtLower:find("scrigno", 1, true) or txtLower:find("chest", 1, true) or txtLower:find("isola", 1, true) or txtLower:find("island", 1, true) or txtLower:find("tesoro", 1, true) then
                targetID = 140
            elseif txtLower:find("baule", 1, true) or txtLower:find("footlocker", 1, true) or txtLower:find("murloc", 1, true) or txtLower:find("relitto", 1, true) or txtLower:find("wreck", 1, true) or txtLower:find("ancora", 1, true) or txtLower:find("anchor", 1, true) then
                targetID = 136
            end
            local d = self.HIDDEN_QUEST_POIS[targetID]
            if d then
                return {
                    questID  = targetID,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = (isIt and d.targetIt) or d.target,
                    desc     = (isIt and d.descIt) or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- H. Cortello's Riddle (Full Chain disambiguation)
        if lower:find("cortello", 1, true) then
            local targetID = 622
            if txtLower:find("palude", 1, true) or txtLower:find("sorrows", 1, true) or txtLower:find("caverna", 1, true) or txtLower:find("cave", 1, true) then
                targetID = 623
            elseif txtLower:find("dustwallow", 1, true) or txtLower:find("cascata", 1, true) or txtLower:find("waterfall", 1, true) then
                targetID = 624
            end
            local d = self.HIDDEN_QUEST_POIS[targetID]
            if d then
                return {
                    questID  = targetID,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = (isIt and d.targetIt) or d.target,
                    desc     = (isIt and d.descIt) or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- I. Mankrik's Wife (Lost in Battle)
        if lower:find("lost in battle", 1, true)
            or lower:find("persa in battaglia", 1, true)
            or lower:find("mankrik", 1, true)
            or txtLower:find("beaten corpse", 1, true)
            or txtLower:find("corpo martoriato", 1, true)
        then
            local d = self.HIDDEN_QUEST_POIS[899]
            if d then
                return {
                    questID  = 899,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- J. Hilary's Necklace (Redridge)
        if lower:find("hilary", 1, true)
            or (lower:find("necklace", 1, true) and (txtLower:find("lake", 1, true) or txtLower:find("redridge", 1, true) or txtLower:find("crestarossa", 1, true)))
            or (lower:find("collana", 1, true) and (txtLower:find("lago", 1, true) or txtLower:find("crestarossa", 1, true)))
        then
            local d = self.HIDDEN_QUEST_POIS[3741] or self.HIDDEN_QUEST_POIS[123]
            if d then
                return {
                    questID  = 3741,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- J2. The Lost Tools (Redridge)
        if lower:find("lost tools", 1, true) or lower:find("attrezzi perduti", 1, true) or (lower:find("oslow", 1, true) and txtLower:find("chest", 1, true)) then
            local d = self.HIDDEN_QUEST_POIS[125]
            if d then
                return {
                    questID  = 125,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- K. Sully Balloo's Letter (Wetlands)
        if lower:find("sully", 1, true) or lower:find("balloo", 1, true) or txtLower:find("thandol", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[637]
            if d then
                return {
                    questID  = 637,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- L. Samophlange & Manual
        if lower:find("samophlange", 1, true) then
            local targetID = (lower:find("manual", 1, true) or lower:find("manuale", 1, true)) and 902 or 894
            local d = self.HIDDEN_QUEST_POIS[targetID]
            if d then
                return {
                    questID  = targetID,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- M. The Stolen Silver
        if lower:find("stolen silver", 1, true) or lower:find("argento rubato", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[848]
            if d then
                return {
                    questID  = 848,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- N. Cuergo's Gold
        if lower:find("cuergo", 1, true) or lower:find("pirate's treasure", 1, true) or lower:find("mappa del tesoro", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[2877]
            if d then
                return {
                    questID  = 2877,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- O. Princess Must Die!
        if lower:find("princess must die", 1, true) or lower:find("principessa deve morire", 1, true) or lower:find("principessa", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[88]
            if d then
                return {
                    questID  = 88,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- P. Grizzby & Highway Robbery
        if lower:find("grizzby", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[99001]
            if d then
                return {
                    questID  = 99001,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end
        if lower:find("highway robbery", 1, true) or lower:find("rapina", 1, true) then
            local d = self.HIDDEN_QUEST_POIS[99002]
            if d then
                return {
                    questID  = 99002,
                    mapID    = d.mapID, x = d.x, y = d.y,
                    title    = isIt and d.targetIt or d.target,
                    desc     = isIt and d.descIt or d.descEn,
                    hint     = d.hint, isRiddle = true,
                }
            end
        end

        -- Q. General Title Keyword scan
        for qid, d in pairs(self.HIDDEN_QUEST_POIS) do
            if (lower:find("blanchy", 1, true) and qid == 153)
                or (lower:find("heirloom", 1, true) and qid == 151)
                or (lower:find("cimelio", 1, true) and qid == 151)
                or (lower:find("tools", 1, true) and qid == 267)
                or (lower:find("attrezzi", 1, true) and qid == 267)
                or (lower:find("sunken chest", 1, true) and qid == 309)
                or (lower:find("baule sommerso", 1, true) and qid == 309)
                or (lower:find("bottle", 1, true) and (qid == 2875 or qid == 2876))
                or (lower:find("bottiglia", 1, true) and (qid == 2875 or qid == 2876))
                or (lower:find("secret to everybody", 1, true) and qid == 4022)
                or (lower:find("linken", 1, true) and qid == 4022)
                or (lower:find("gaeriyan", 1, true) and qid == 4024)
                or (lower:find("a-me", 1, true) and qid == 4492)
                or (lower:find("chen", 1, true) and qid == 819)
                or (lower:find("beached", 1, true) and (qid == 4735 or qid == 4728 or qid == 4727 or qid == 4725 or qid == 4722))
                or (lower:find("spiaggiat", 1, true) and (qid == 4735 or qid == 4728 or qid == 4727 or qid == 4725 or qid == 4722))
            then
                return {
                    questID  = qid,
                    mapID    = d.mapID,
                    x        = d.x,
                    y        = d.y,
                    title    = (isIt and d.targetIt) or d.target,
                    desc     = (isIt and d.descIt) or d.descEn,
                    hint     = d.hint,
                    isRiddle = true,
                }
            end
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Helper: Check if a Quest Belongs to a Dungeon
-------------------------------------------------------------------------------
function FP:GetDungeonForQuest(questID, questTitle)
    if not self.DUNGEON_GUIDES then return nil end

    local normTitle = IsSafeStr(questTitle) and questTitle:lower():gsub("[%p%s]", "") or ""

    for guideID, guide in pairs(self.DUNGEON_GUIDES) do
        if type(guide) == "table" then
            -- 1. Check curated quests list
            if FP.CURATED_DUNGEON_QUESTS and FP.CURATED_DUNGEON_QUESTS[guideID] then
                for _, cq in ipairs(FP.CURATED_DUNGEON_QUESTS[guideID]) do
                    if (IsSafeNum(questID) and cq.questID == questID)
                        or (normTitle ~= "" and cq.name and cq.name:lower():gsub("[%p%s]", "") == normTitle)
                    then
                        return guide
                    end
                end
            end

            -- 2. Check dungeon name / alias match in quest title
            local dName = (guide.name or ""):lower():gsub("[%p%s]", "")
            local dNameIt = (guide.nameIt or ""):lower():gsub("[%p%s]", "")
            if normTitle ~= "" then
                if dName ~= "" and normTitle:find(dName, 1, true) then
                    return guide
                end
                if dNameIt ~= "" and normTitle:find(dNameIt, 1, true) then
                    return guide
                end
                if type(guide.aliases) == "table" then
                    for _, al in ipairs(guide.aliases) do
                        local aNorm = al:lower():gsub("[%p%s]", "")
                        if aNorm ~= "" and normTitle:find(aNorm, 1, true) then
                            return guide
                        end
                    end
                end
            end
        end
    end

    return nil
end
