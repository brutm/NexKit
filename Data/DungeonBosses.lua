-------------------------------------------------------------------------------
-- NexusKit - Data/DungeonBosses.lua
-- WoW Forever (Levels 1-60) Dungeon & Raid Boss Tactics Database.
-- Covers Classic (1-60) and WoW Forever new Dungeons & Raids (max level 60).
-- Indexed by canonical InstanceMapID or normalized instance name/alias matching.
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function UseItalian()
    if FP.GetEffectiveLocale then
        return FP:GetEffectiveLocale() == "itIT"
    end
    if FP.activeLocale then
        return FP.activeLocale == "itIT"
    end
    return (GetLocale and GetLocale() == "itIT") or false
end

local function B(name, sEn, sIt, tEn, tIt, hEn, hIt, dEn, dIt, wing, aliases)
    return {
        name = name,
        wing = wing,
        aliases = aliases,
        summary = { en = sEn, it = sIt },
        tank = { en = tEn, it = tIt },
        heal = { en = hEn, it = hIt },
        dps = { en = dEn, it = dIt },
    }
end

FP.DUNGEON_GUIDES = {
    ---------------------------------------------------------------------------
    -- CLASSIC DUNGEONS (Levels 13-60)
    ---------------------------------------------------------------------------
    [389] = {
        id = 389, kind = "party", expansion = 1, minLvl = 13, maxLvl = 18,
        name = "Ragefire Chasm", nameIt = "Baratro di Ragefire",
        overview = {
            en = "Tight lava ledges; watch Earthborer knockbacks and patrolling troggs near ramps.",
            it = "Passerelle strette sulla lava; attento ai mob patroller e a non cadere nei pull sulle rampe.",
        },
        bosses = {
            B("Oggleflint",
                "Orc warrior with 2 trogg adds and frontal Cleave.",
                "Guerriero orchesco con 2 add e Cleave frontale.",
                "Face Oggleflint away from party.", "Giralo di schiena al gruppo per il Cleave.",
                "Steady healing while adds die.", "Cura costante finché non cadono gli add.",
                "Kill the 2 Ragefire Troggs first.", "Elimina prima i 2 Trogg, poi il boss."),
            B("Taragaman the Hungerer",
                "Fire Nova AoE and Uppercut knockback near lava edges.",
                "Lancia Fire Nova ad area e Uppercut che sbalza: rischio lava.",
                "Tank with back against rock wall away from lava.", "Tanka con la schiena alla roccia lontano dalla lava.",
                "Stand safe on platform; top party after Fire Nova.", "Stai sulla piattaforma sicura e rialza dopo Fire Nova.",
                "Avoid standing between boss and lava.", "Non posizionarti tra il boss e la lava."),
            B("Jergosh the Invoker",
                "Caster boss with Immolate and Curse of Weakness.",
                "Boss caster con Immolate e Maledizione della Debolezza.",
                "Interrupt or pull back cleanly; watch side room patrols.", "Pulla indietro in sicurezza lontano dai patroller vicini.",
                "Heal through Immolate DoT on tank/DPS.", "Cura il DoT di Immolate su tank e DPS.",
                "Interrupt casts and stay clear of patrols.", "Interrompi i cast e fai attenzione ai patroller."),
            B("Bazzalan",
                "Poisonous Sinister Strike and Deadly Poison melee boss.",
                "Boss melee rapido con Poison e Sinister Strike.",
                "Hold steady threat; face away from casters.", "Mantieni aggro saldo lontano dai caster.",
                "Cure Poison if available and heal tank.", "Rimuovi Veleno se puoi e tieni su il tank.",
                "Full single-target burn.", "Focus completo sul boss."),
        },
    },
    [43] = {
        id = 43, kind = "party", expansion = 1, minLvl = 17, maxLvl = 24,
        name = "Wailing Caverns", nameIt = "Caverne dei Lamenti",
        overview = {
            en = "4 Fanglords must die before the Disciple escort event spawns Mutanus. Mind Raptors & Druids healing!",
            it = "Uccidi tutti e 4 i Fanglord per avviare la scorta finale di Mutanus. Interrompi sempre Healing Touch dei Druidi!",
        },
        bosses = {
            B("Lady Anacondra",
                "First Fanglord. Casts Healing Touch and Druid Sleep.",
                "Primo Fanglord. Lancia Healing Touch e Sleep sui giocatori.",
                "Pull away from adjacent Raptor/Deviate packs.", "Pulla lontano dai pack di Raptor e Deviate vicini.",
                "Dispel/top tank quickly if slept.", "Rialza il tank se vieni addormentato.",
                "Always interrupt Healing Touch & Lightning Bolt.", "Interrompi sempre Healing Touch e Lightning Bolt."),
            B("Lord Cobrahn",
                "Transforms into serpent at low HP; poisons & Druidic Slumber.",
                "Si trasforma in serpente a bassa vita; veleni e Sleep.",
                "Hold aggro across serpent phase transition.", "Mantieni aggro quando si trasforma in serpente.",
                "Dispel Poison / Slumber; moderate spike damage.", "Cura i veleni e tieni pronto un dispell su Sleep.",
                "Interrupt Healing Touch; burst serpent form.", "Interrompi Healing Touch; burst in forma serpente."),
            B("Kresh",
                "Optional snapping turtle patrolling the river; high armor.",
                "Tartaruga opzionale sul fiume; armatura molto alta.",
                "Straightforward tank & spank near river bank.", "Tank classico lungo la riva.",
                "Light healing needed; slow damage boss.", "Cura leggera, scontro lungo per la sua armatura.",
                "Spell/bleed damage shines; avoid extra river adds.", "Danni magici molto efficaci; evita pull sul fiume."),
            B("Lord Pythas",
                "Second Fanglord on the upper ledge; Sleep, Healing Touch & Thunderclap.",
                "Fanglord sulla sporgenza alta; Sleep, Healing Touch e Thunderclap.",
                "Clear ledge trash first; hold boss & adds.", "Pulisci prima la sporgenza; gestisci eventuali add.",
                "Stay out of Thunderclap melee range.", "Stai fuori portata melee per evitare Thunderclap.",
                "Interrupt Healing Touch immediately.", "Interrompi subito Healing Touch."),
            B("Skum",
                "Thunder Lizard with Chained Bolt (chain lightning) and heavy melee.",
                "Lucertola del Tuono con Chained Bolt a catena e colpi melee forti.",
                "Face away and keep healthy against nature bursts.", "Mantieni vita alta contro i picchi Nature.",
                "Spread slightly so Chained Bolt doesn't bounce.", "Spaziati leggermente per limitare il rimbalzo di Chained Bolt.",
                "Spread out and burn cleanly.", "Spaziati leggermente ed elimina il boss."),
            B("Lord Serpentis",
                "Last Fanglord in top chamber; Lightning Bolt & Healing Touch.",
                "Ultimo Fanglord nella sala alta; Lightning Bolt e Healing Touch.",
                "Keep room clear before pulling; tank in center.", "Pulisci prima la stanza; tanka al centro.",
                "Watch Sleep on party/healer.", "Pronto a curare subito dopo Sleep.",
                "Mandatory Healing Touch interrupts.", "Interrompi obbligatoriamente Healing Touch."),
            B("Verdan the Everliving",
                "Massive bog beast hitting very hard (Grasping Vines root + knockback).",
                "Gigante vegetale con colpi pesantissimi e Grasping Vines.",
                "Use defensive cooldowns; top priority tank healing.", "Usa cooldown difensivi: colpi melee molto pesanti.",
                "Focus heavy single-target heals on tank.", "Cura pesante sul tank per tutta la durata.",
                "Do not pull aggro; let tank build threat first.", "Non rubare aggro all'inizio; lascia salire il tank."),
            B("Mutanus the Devourer",
                "Final boss after escorting Muyoh through waves. Fears, sleeps & hits hard.",
                "Boss finale dopo la scorta finale. Lancia Fear, Sleep e colpi pesanti.",
                "Drink/mana up before waking Naralex; keep Mutanus off escort NPC.", "Riprendi mana prima dell'ultima onda; proteggi l'NPC.",
                "Keep escort NPC alive on waves, then heavy tank healing.", "Tieni vivo l'NPC durante le onde poi focus sul tank.",
                "Clear wave adds fast before boss arrives.", "Elimina rapidamente le onde di add prima dell'arrivo di Mutanus."),
        },
    },
    [36] = {
        id = 36, kind = "party", expansion = 1, minLvl = 17, maxLvl = 26,
        name = "The Deadmines", nameIt = "Le Miniere della Morte",
        overview = {
            en = "Goblin Engineering doors trigger patrols! Watch patrolling Defias/Goblins behind you in the cove.",
            it = "Le porte esplosive attirano mob; nella grotta finale attento alle pattuglie dietro la rampa della nave.",
        },
        bosses = {
            B("Rhahk'Zor",
                "Hard-hitting ogre flanked by 2 Defias guards; Rhahk'Zor Slam.",
                "Ogre con colpi forti e 2 guardie; lancia Rhahk'Zor Slam.",
                "Pull back away from miners; tank against wall.", "Pulla indietro dai minatori; tanka vicino al muro.",
                "Heavy opening damage until the 2 guards drop.", "Danno iniziale alto finché non muoiono le 2 guardie.",
                "Kill both guards first, then burn Rhahk'Zor.", "Uccidi prima le 2 guardie, poi Rhahk'Zor."),
            B("Miner Johnson",
                "Rare Defias miner spawn near side tunnel; Pierce Armor.",
                "Boss raro nella galleria laterale; riduce l'armatura.",
                "Hold aggro through Pierce Armor armor reduction.", "Tieni aggro anche con il debuff su armatura.",
                "Extra heals on tank when Pierce Armor lands.", "Cura extra quando entra Pierce Armor.",
                "Simple bonus boss burn.", "Boss opzionale veloce."),
            B("Sneed",
                "Two phases: Sneed's Shredder first, then Goblin Sneed pops out with Fear.",
                "Due fasi: prima Sneed's Shredder, poi esce Sneed con Terrify/Disarm.",
                "Hold Shredder, then quickly pick up Goblin Sneed when it explodes.", "Tanka il Shredder, poi riprendi subito il goblin quando esce.",
                "Watch healer threat during phase transition.", "Occhio all'aggro delle cure al cambio fase.",
                "Clear surrounding lumber room before pull; watch Fear.", "Pulisci prima la sala legname; attento al Fear finale."),
            B("Gilnid",
                "Molten Metal DoT + Melt Ore. Foundry guards patrol near stairs.",
                "Lancia Molten Metal e Melt Ore. Attento ai patroller nella fonderia.",
                "Fight on top/side clear spot away from wandering patrols.", "Tanka lontano dalle scale e dai patroller della fonderia.",
                "Heal through Molten Metal DoT.", "Cura il DoT di Molten Metal.",
                "Clear foundry trash first so adds don't join.", "Pulisci bene i mob della fonderia prima del pull."),
            B("Mr. Smite",
                "Stuns whole party twice (at 66% and 33%) to swap weapons at chest; huge slow swings in Phase 3!",
                "Stordisce tutti al 66% e 33% per cambiare arma al baule; colpi enormi in Fase 3!",
                "Re-establish threat after each stun; pop wall/defensives in Axe phase.", "Riprendi aggro dopo ogni stun; usa difensivi in Fase 3 (Ascia).",
                "Top tank before 66%/33% stuns so he survives burst after stun.", "Tieni il tank al 100% prima del 66% e 33% per reggere lo stun.",
                "Clear patrol adds on the ship ramps before pulling Smite.", "Pulisci i patroller sulla nave prima di pullare Mr. Smite."),
            B("Captain Greenskin",
                "Appears with 2 pirates; Cleave and Poisoned Harpoon.",
                "Ingaggio con 2 pirati; lancia Cleave e Poisoned Harpoon.",
                "Face Greenskin away from group; pick up both pirate adds.", "Giralo di schiena al gruppo e prendi i 2 pirati.",
                "Cleanse Poison if possible; heal opening cleave.", "Cura il veleno se disponibile.",
                "Focus the 2 pirate adds first, then Greenskin.", "Uccidi prima i 2 pirati, poi Greenskin."),
            B("Edwin VanCleef",
                "Final boss! Starts with 2 stealth guards and summons 2 MORE guards at 50% HP.",
                "Boss finale! Parte con 2 guardie e ne evoca altre 2 al 50% HP.",
                "Pick up all 4 guards cleanly; keep VanCleef facing away.", "Prendi subito le guardie iniziali e quelle evocate al 50% HP.",
                "Expect heavy spike damage at 100% and 50% HP.", "Picchi di danno all'apertura e al 50% con i nuovi add.",
                "Kill guards at 100% and switch to newly spawned guards at 50%!", "Uccidi le guardie all'inizio e passa subito a quelle evocate al 50%!"),
            B("Cookie",
                "Murloc cook below deck; casts Cookie's Cooking (party heal) and Acid Splash.",
                "Murloc cuoco sottocoperta; lancia Cookie's Cooking (cura) e Acid Splash.",
                "Hold cleanly on ship's lower deck.", "Tanka sul ponte inferiore.",
                "Top poison damage if needed.", "Cura leggera su Acid Splash.",
                "MUST interrupt Cookie's Cooking heal!", "INTERROMPI Cookie's Cooking o si cura!"),
        },
    },
    [33] = {
        id = 33, kind = "party", expansion = 1, minLvl = 22, maxLvl = 30,
        name = "Shadowfang Keep", nameIt = "Forte di Zannascura",
        overview = {
            en = "Watch Shadowfang Moonrage Worgens (immunities/casts) and clear courtyard wolves cleanly.",
            it = "Attenzione ai Worgen incantatori e ai lupi nel cortile; alcuni caster fanno molto danno ombra.",
        },
        bosses = {
            B("Rethilgore",
                "Soul Drain channels life back from target; clear courtyard wolves first.",
                "Assorbe vita con Soul Drain; pulisci i lupi vicino alla prigione.",
                "Tank near doorway after freeing prisoner.", "Tanka vicino all'ingresso della cella.",
                "Heal through Soul Drain.", "Cura il danno di Soul Drain.",
                "Interrupt Soul Drain if possible.", "Interrompi Soul Drain se puoi."),
            B("Razorclaw the Butcher",
                "Heavy melee bleed/cleave worgen in dining hall.",
                "Worgen melee pesante nella sala da pranzo.",
                "Clear cooks/guards first; keep back to wall.", "Pulisci prima cuochi e guardie; schiena al muro.",
                "Steady tank heals.", "Cura costante sul tank.",
                "Avoid standing in front (cleave).", "Non stare davanti al boss."),
            B("Baron Silverlaine",
                "Curses tank with Veil of Shadow (-75% healing received!).",
                "Applica Veil of Shadow (-75% cure ricevute sul tank!).",
                "Use defensive cooldown if Veil of Shadow isn't decursed.", "Usa difensivi se non puoi rimuovere Veil of Shadow.",
                "DECURSE Veil of Shadow immediately! Otherwise heals do almost nothing.", "RIMUOVI LA MALEDIZIONE Veil of Shadow subito (-75% cure)!",
                "Decurse if mage/druid; burn fast.", "Rimuovi la maledizione se sei Mago/Druido."),
            B("Commander Springvale",
                "Paladin boss with 2 guards; casts Holy Light heals & Hammer of Justice stun.",
                "Paladino non morto con 2 guardie; si cura con Holy Light.",
                "Tank near doorway; pick up both guards.", "Prendi boss e guardie vicino alla porta.",
                "Heal through Hammer stun windows.", "Tieni alto il tank durante Hammer of Justice.",
                "Kill guards first and MUST interrupt Holy Light!", "Uccidi le guardie e INTERROMPI sempre Holy Light!"),
            B("Odo the Blindwatcher",
                "Howling Rage buffs his size/damage; comes with 2 wolves.",
                "Entra in Howling Rage aumentando danni e taglia; 2 lupi.",
                "Prepare cooldown for Howling Rage buff.", "Usa difensivi quando attiva Howling Rage.",
                "Heal heavy melee swings during Howling Rage.", "Cura pesante durante Howling Rage.",
                "Kill wolves first, burn boss before Rage spirals.", "Elimina prima i lupi, poi burst sul boss."),
            B("Fenrus the Devourer",
                "Toxic Saliva DoT; spawns 4 Voidwalkers upon death!",
                "Veleno ad area e alla morte evoca 4 Voidwalker!",
                "Hold threat on Fenrus, then grab the 4 Voidwalkers on death.", "Prendi subito i 4 Voidwalker quando Fenrus muore.",
                "Keep healing after boss dies until Voidwalkers drop.", "Continua a curare alla morte del boss per i 4 add!",
                "Don't go AFK at 0%: AoE down the 4 Voidwalkers.", "Non rilassarti allo 0%: uccidi i 4 Voidwalker evocati."),
            B("Wolf Master Nandos",
                "4 wolves in stable before stairs; pull wolves separately first!",
                "4 lupi nella stalla; pullali a gruppi prima del boss.",
                "Clear wolves sequentially so you don't tank 5 mobs.", "Pulisci i lupi gradualmente prima di pullare Nandos.",
                "Heavy tank damage if extra wolves are still alive.", "Danno elevato se restano lupi vivi.",
                "Single-target wolves one by one, then Nandos.", "Uccidi i lupi uno per uno, poi Nandos."),
            B("Archmage Arugal",
                "Teleports across room, casts Void Bolt (heavy shadow) & Mind Control (Arugal's Curse).",
                "Si teletrasporta su tre pedane, lancia Void Bolt e Mind Control.",
                "Line-of-sight or chase teleports; hold aggro on return.", "Inseguilo sui teletrasporti (o usa LoS sui pilastri).",
                "Dispel/CC Mind Controlled allies & spot-heal Shadow Bolts.", "Cura i Void Bolt e controlla chi subisce Mind Control.",
                "CC/kite Mind Controlled teammate; burn boss quickly and LoS casts.", "CC su alleati sotto Mind Control; usa LoS e burst rapido."),
        },
    },
    [48] = {
        id = 48, kind = "party", expansion = 1, minLvl = 24, maxLvl = 32,
        name = "Blackfathom Deeps", nameIt = "Abissi di Blackfathom",
        overview = {
            en = "Watch lighting all 4 candles around Kelris's altar AT ONCE — wait until ready or kill one pack at a time!",
            it = "Non accendere tutte e 4 le candele dell'altare di Kelris insieme: una alla volta o pulli 4 gruppi!",
        },
        bosses = {
            B("Ghamoo-ra",
                "Giant turtle; Trample AoE and high armor.",
                "Tartaruga gigante con Trample ad area e alta armatura.",
                "Hold safely near shore.", "Tanka vicino alla riva.",
                "Stand outside Trample range.", "Stai fuori portata da Trample.",
                "Magic damage melts it fastest.", "Danni magici molto efficaci."),
            B("Lady Sarevess",
                "Naga frost/slow caster with 2 Naga guards; Forked Lightning.",
                "Naga con Frost Nova, Slow e 2 guardie; Forked Lightning.",
                "Face away from party (Forked Lightning cone).", "Girala lontano dal gruppo per evitare Forked Lightning.",
                "Dispel frost/magic if possible.", "Rimuovi eventuali Freeze/Magia.",
                "Kill guards first; interrupt Slow/Frostbolt.", "Uccidi le guardie e interrompi i cast."),
            B("Gelihast",
                "Murloc boss with Curse of Blackfathom (-stats) and Net.",
                "Boss Murloc con maledizione e Net.",
                "Clear murloc beach carefully so extras don't flee into more.", "Pulisci la spiaggia senza far scappare i murloc negli altri pack.",
                "Decurse Curse of Blackfathom if possible.", "Rimuovi maledizioni se disponibile.",
                "Kill runners quickly!", "Uccidi subito i mob in fuga!"),
            B("Twilight Lord Kelris",
                "Mind Blast shadow bursts + Sleep on random player.",
                "Lancia Mind Blast molto forti e addormenta un giocatore.",
                "Pick up threat immediately if slept and aggro drops.", "Riprendi aggro subito se vieni addormentato.",
                "Heal Mind Blast spikes carefully.", "Cura i picchi di Mind Blast.",
                "Interrupt Mind Blast! Do NOT light all 4 candles at once after him.", "Interrompi Mind Blast! Poi accendi le 4 candele UNA alla volta!"),
            B("Aku'mai",
                "Hydra final boss; Poison Cloud AoE, Frenzied Rage at 30%.",
                "Idra finale con Poison Cloud a terra ed Enrage al 30%.",
                "Move out of Poison Cloud; save cooldowns for 30% frenzy.", "Spostati dalla nuvola di veleno; usa difensivi al 30%.",
                "Heavy tank heals at 30% Frenzied Rage; cleanse poison.", "Cura pesante dal 30% (Enrage) e pulisci veleni.",
                "Save burst cooldowns for 30% Frenzy!", "Tieni i burst cooldown per il 30%!"),
        },
    },
    [34] = {
        id = 34, kind = "party", expansion = 1, minLvl = 24, maxLvl = 32,
        name = "The Stockade", nameIt = "Le Segrete di Roccavento",
        aliases = { "Stockades", "The Stockades", "Stockade", "Segrete", "Le Segrete", "Stormwind Stockade" },
        overview = {
            en = "Humanoids flee at low HP into adjacent cells — pull every room back into hallways!",
            it = "Tutti i prigionieri scappano a poca vita attirando altre celle: pulla SEMPRE nel corridoio!",
        },
        bosses = {
            B("Targorr the Dread",
                "Thrash extra-attack bursts; pull into main hallway.",
                "Attacchi multipli (Thrash); pulla fuori dalla cella.",
                "Pull out to hallway; watch nearby patrolling prisoners.", "Pulla nel corridoio principale.",
                "Expect sudden double/triple hits from Thrash.", "Attento ai colpi improvvisi di Thrash.",
                "Burn fast and slow/stun at low HP so mobs can't run.", "Rallenta/stordisci gli add a bassa vita!"),
            B("Kam Deepfury",
                "Warrior prisoner with Shield Slam stun and guards.",
                "Boss con Shield Slam stun e guardie.",
                "Tank with group safely in hallway.", "Tanka nel corridoio lontano da altre celle.",
                "Keep tank topped around Shield Slam stun.", "Tieni alto il tank contro Shield Slam.",
                "Kill adds first, burn boss.", "Elimina gli add poi il boss."),
            B("Bazil Thredd",
                "Deep wing leader; Smoke Bomb AoE stun.",
                "Capo dell'ala centrale; lancia Smoke Bomb stunnando in area.",
                "Hold steady threat despite Smoke Bomb stun.", "Tieni aggro dopo Smoke Bomb.",
                "Stand outside melee Smoke Bomb radius.", "Stai fuori dal raggio melee di Smoke Bomb.",
                "Range avoids Smoke Bomb stun cleanly.", "I ranged possono stare fuori da Smoke Bomb."),
            B("Dextren Ward",
                "Casts Intimidating Shout (AoE Fear) — clear nearby rooms first!",
                "Lancia Intimidating Shout (Fear ad area)! Pulisci i corridoi prima!",
                "CRITICAL: clear hallway/adjacent rooms or Fear pulls extra packs!", "FONDAMENTALE: pulisci i corridoi vicini prima o il Fear pulla tutto!",
                "Stand far away to outrange Fear.", "Stai più lontano possibile per evitare il Fear.",
                "Kill adds cleanly; avoid fearing into unpulled cells.", "Uccidi gli add ed evita che il Fear mandi nelle celle vicine."),
        },
    },
    [90] = {
        id = 90, kind = "party", expansion = 1, minLvl = 29, maxLvl = 38,
        name = "Gnomeregan", nameIt = "Gnomeregan",
        overview = {
            en = "Kill Alarm-o-Bots IMMEDIATELY! Falling off upper ramps pulls extra floors; dismiss pets before jumping!",
            it = "Uccidi SUBITO gli Alarm-o-Bot! Se salti dai piani superiori congela/congeda il pet o pulli tutto il piano!",
        },
        bosses = {
            B("Grubbis",
                "Triggered by talking to Blastmaster Emi Shortfuse; spawns trogg waves then Grubbis + Chomper.",
                "Evento parlando con Blastmaster Emi; ondate di trogg poi Grubbis e il basilisco Chomper.",
                "Pick up wave adds and then tank Grubbis + Chomper together.", "Prendi le ondate poi tanka Grubbis e Chomper.",
                "Steady heals across waves and double-boss pull.", "Cura continua tra ondate e doppi boss.",
                "AoE trogg waves, then kill Chomper -> Grubbis.", "AoE sulle ondate poi elimina prima Chomper."),
            B("Viscous Fallout",
                "Toxic Sludge AoE on death / hits; high Poison damage.",
                "Veleno Toxic Volley/Sludge ad area.",
                "Clear surrounding Irradiated Slimes first.", "Pulisci prima le melme circostanti.",
                "Cleanse Poison; heal group AoE damage.", "Cura il danno di gruppo da veleno e purifica.",
                "Watch poison debuffs and clear room first.", "Attento alle pozze e ai debuff veleno."),
            B("Electrocutioner 6000",
                "Chain Lightning + Shock; drops workshop key.",
                "Lancia Chain Lightning e Shock; droppa la chiave dell'officina.",
                "Tank alone cleanly on platform.", "Tanka pulito sulla piattaforma.",
                "Spread out so Chain Lightning doesn't bounce.", "Spaziati per non far rimbalzare Chain Lightning.",
                "Spread out and interrupt casts.", "Spaziati e interrompi i cast."),
            B("Crowd Pummeler 9-60",
                "Massive Arcing Smash frontal cleave and Knockback.",
                "Enorme meccanismo con Arcing Smash frontale e Knockback.",
                "Tank with back to wall; face strictly away from group.", "Schiena al muro e boss girato via dal gruppo.",
                "Stay behind and far back.", "Stai dietro e lontano dal cono frontale.",
                "Never stand in front of Pummeler.", "Non stare mai davanti al boss."),
            B("Mekgineer Thermaplugg",
                "Final boss! Walking Bombs continuously exit pillars — assign 1 player to click Pillar Buttons to close hatches!",
                "Boss finale! Escono Bombe dalle colonne: qualcuno deve cliccare i bottoni sulle colonne (o distruggere le bombe)!",
                "Keep Thermaplugg away from center edge; move from active bombs.", "Sposta il boss dalle bombe ed evita i pilastri aperti.",
                "Heal Knockback + Fire/Bomb splashes.", "Cura sbalzi e possibili esplosioni di bombe.",
                "Click lit Pillar Buttons OR destroy Walking Bombs before they explode!", "Clicca i bottoni accesi sulle colonne o distruggi subito le Walking Bombs!"),
        },
    },
    [47] = {
        id = 47, kind = "party", expansion = 1, minLvl = 29, maxLvl = 38,
        name = "Razorfen Kraul", nameIt = "Lamaspina",
        overview = {
            en = "Watch patrolling Boars & Spirit Totems. Quilboar summon guards and flee at low HP.",
            it = "Distruggi sempre gli Spirit Totem dei Quilboar e ferma i mob in fuga!",
        },
        bosses = {
            B("Aggem Thorncurse",
                "Summons Battle Boar adds and casts Battle Shout.",
                "Evoca cinghiali di supporto e lancia Battle Shout.",
                "Pick up summoned boars.", "Prendi i cinghiali evocati.",
                "Moderate healing.", "Cura moderata.",
                "Burn boars down or cleave cleanly.", "Elimina i cinghiali o fai cleave."),
            B("Death Speaker Jargba",
                "Mind Controls a party member (Dominate Mind).",
                "Lancia Dominate Mind (Mind Control su un giocatore).",
                "Hold threat; CC controlled player rather than killing them.", "CC (Poly/Fear/Stun) sul giocatore controllato, non ucciderlo.",
                "Heal through shadow bolts / MC swaps.", "Cura Shadow Bolt e cambi aggro dopo il Mind Control.",
                "Interrupt Mind Control / Shadow Bolt if possible!", "Interrompi Dominate Mind / Shadow Bolt se possibile!"),
            B("Overlord Ramtusk",
                "Surrounded by guards; clear room and watch Battle Stomp knockback.",
                "Circondato da guardie; lancia Thunderclap/Battle Stomp.",
                "Pull guards carefully before engaging Ramtusk.", "Pulisci la sala prima di ingaggiare.",
                "Heal group stomp damage.", "Cura dopo lo stomp.",
                "Kill guards first.", "Uccidi prima le guardie."),
            B("Agathelos the Raging",
                "Rushes/charges random player, then enters Frenzy at low HP.",
                "Carica bersagli casuali e va in Frenzy a bassa vita.",
                "Pick up quickly after Charge; use defensives during Frenzy.", "Riprendi aggro dopo la carica; difensivi nel Frenzy.",
                "Spot-heal charged player; heavy tank healing in Frenzy.", "Cura chi viene caricato poi focus tank in Frenzy.",
                "Keep distance so charges are obvious; burn Frenzy.", "Stai distante e finiscilo in Frenzy."),
            B("Charlga Razorflank",
                "Final boss! Summons Windfury Totem & Roots + Mana Burn + Chain Lightning.",
                "Boss finale! Piazza Totem, blocca con Root, Chain Lightning e Mana Burn.",
                "Pull away from side ridge packs; keep on top.", "Tanka al centro lontano dai pack vicini.",
                "Healers: stay max range to avoid Mana Burn & Chain Lightning.", "Healer: stai a max range per evitare Mana Burn e Chain Lightning!",
                "Destroy totems immediately and interrupt Chain Lightning / Renew!", "Distruggi subito i totem e interrompi Renew / Chain Lightning!"),
        },
    },
    [189] = {
        id = 189, kind = "party", expansion = 1, minLvl = 26, maxLvl = 45,
        name = "Scarlet Monastery", nameIt = "Monastero Scarlatto",
        overview = {
            en = "4 wings (GY/Lib/Arm/Cath). Interrupt Scarlet Monks/Chaplains Healing & watch Mograine pulling entire Cathedral!",
            it = "4 ali (Cimitero/Libreria/Armeria/Cattedrale). In Cattedrale PULISCI tutta la sala prima di pullare Mograine o aggri l'intera chiesa!",
        },
        bosses = {
            B("Interrogator Vishas",
                "Shadow Word: Pain and heavy hits; easy Graveyard boss.",
                "Shadow Word: Pain e colpi fisici; primo boss del Cimitero.",
                "Tank cleanly in torture room.", "Tanka nella sala.",
                "Dispel SW:Pain if available.", "Dispel SW:Pain se puoi.",
                "Simple burn.", "DPS diretto.", "GY"),
            B("Bloodmage Thalnos",
                "Graveyard end boss; Fire Nova, Flame Spike AoE & Shadow Bolt.",
                "Boss finale Cimitero; Fire Nova, Flame Spike a terra e Shadow Bolt.",
                "Move out of Flame Spike fire circles.", "Spostati dai cerchi di fuoco di Flame Spike.",
                "Group damage from Fire Nova; stay out of Flame Spike.", "Cura l'AoE di Fire Nova ed esci dalle fiamme.",
                "Move out of fire AoE and interrupt Shadow Bolts.", "Esci dalle fiamme e interrompi Shadow Bolt.", "GY"),
            B("Houndmaster Loksey",
                "Library boss with Bloodlust & 3 tracking hounds.",
                "Boss Libreria con Bloodlust e 3 segugi.",
                "Clear hallway hounds first, then pick up his 3 dogs.", "Pulisci prima la stanza poi prendi i 3 cani.",
                "Heavy opening burst during Bloodlust.", "Danno iniziale alto quando va in Bloodlust.",
                "Kill his 3 hounds first, then burn Loksey.", "Uccidi prima i 3 segugi, poi Loksey.", "Lib"),
            B("Arcanist Doan",
                "Library end boss! Arcane Bubble + Detonation AoE at 50% HP (~1k AoE dmg) + Polymorph.",
                "Boss finale Libreria! Al 50% HP fa Bolla immune + Arcane Explosion gigante + Polymorph!",
                "Pull toward entrance so casters can LoS / run out of room at 50% Explosion!", "Pulla vicino alla porta per uscire/LoS durante l'esplosione al 50%!",
                "Run out/LoS during Arcane Bubble cast! Dispel Silence/Polymorph.", "Esci dalla stanza o usa LoS quando carica l'esplosione! Rimuovi Polymorph.",
                "Interrupt Polymorph/Arcane Bolt; RUN OUT when he bubbles ('Burn in righteous fire!')!", "Interrompi Polymorph; SCAPPA FUORI quando attiva la bolla immune!", "Lib"),
            B("Herod",
                "Armory boss! 'BLADES OF LIGHT!' = Whirlwind immune to spells/CC (runs around spinning!). Trainees rush in on death.",
                "Boss Armeria! Grida 'Blades of Light' e parte in Whirlwind immune (scappa dal vortice!). Alla morte arrivano molti adepti.",
                "Run out of Whirlwind; re-taunt immediately after spin ends; grab Trainee wave on kill.", "Allontanati durante il Whirlwind, poi riprendi aggro; preparati agli adepti alla fine.",
                "Move out during Whirlwind and keep tank alive; ready for final AoE wave.", "Stai distante dal Whirlwind e pronto per l'ondata finale.",
                "Melee MUST run out during Whirlwind! AoE the Scarlet Trainees after he dies.", "Melee SCAPPA durante Whirlwind! Poi AoE sugli adepti appena muore Herod.", "Arm"),
            B("High Inquisitor Fairbanks",
                "Hidden behind lever room in Cathedral; Penance & Curse of Blood.",
                "Nascosto dietro leva in Cattedrale; Penance e Curse of Blood.",
                "Optional boss behind secret wall; hold steady.", "Boss opzionale dietro il muro segreto.",
                "Dispel Magic/Curse if needed.", "Cura Penance e rimuovi maledizioni.",
                "Simple burn.", "DPS diretto.", "Cath"),
            B("Scarlet Commander Mograine",
                "Cathedral Phase 1! CLEAR WHOLE CATHEDRAL FIRST or pulling him pulls every mob! Hits hard with Crusader Strike.",
                "Cattedrale Fase 1! PULISCI TUTTA LA SALA PRIMA o pullando lui arriva tutta la cattedrale!",
                "Clear all Cathedral alcoves first! Hold Mograine cleanly away from altar.", "Pulisci prima tutta la cattedrale! Tanka lontano dall'altare.",
                "Conserve mana for Phase 2 (Whitemane spawns after Mograine dies!).", "Risparmia mana per la Fase 2 con Whitemane!",
                "Drop Mograine cleanly; prepare interrupts for Whitemane.", "Abbatti Mograine e tieni pronti gli interrupt per Whitemane.", "Cath"),
            B("High Inquisitor Whitemane",
                "Cathedral Phase 2! Runs out, puts everyone to Deep Sleep at ~50% HP, and RESURRECTS Mograine with full health!",
                "Cattedrale Fase 2! Al ~50% addormenta tutto il gruppo e RESUSCITA Mograine! Poi entrambi vanno gestiti.",
                "Tank BOTH Whitemane & resurrected Mograine after Sleep ends!", "Riprendi ENTRAMBI (Mograine risorto + Whitemane) dopo lo Sleep!",
                "Prepare to spam-heal tank once Deep Sleep ends; two bosses hit simultaneously.", "Appena finisce Deep Sleep cura pesante su tutto: picchiano in due!",
                "MUST interrupt Whitemane's Smite & Heal! Focus Whitemane down FIRST once Sleep breaks.", "INTERROMPI sempre Smite e Heal di Whitemane! Uccidi Whitemane PRIMA di Mograine dopo il Sleep!", "Cath"),
        },
    },
    [129] = {
        id = 129, kind = "party", expansion = 1, minLvl = 37, maxLvl = 46,
        name = "Razorfen Downs", nameIt = "Sotterranei di Lamaspina",
        overview = {
            en = "Beware Frost/Shadowcasters and the massive skeleton spiral staircase before Amnennar.",
            it = "Attento alla spirale d'ossa con molti non-morti (usa Frost/Fire AoE) prima del boss finale.",
        },
        bosses = {
            B("Tuten'kash",
                "Gong event summons spider waves, then Tuten'kash (Web Spray root + Curse of Tuten'kash).",
                "Suonando il gong arrivano ondate di ragni e poi Tuten'kash (Ragnatela e Maledizione).",
                "Grab spider waves, then face boss away.", "Gestisci le ondate poi tanka il boss.",
                "Decurse if possible; watch AoE spider poison.", "Rimuovi maledizione/veleno se disponibile.",
                "AoE spider waves before Tuten'kash arrives.", "AoE sulle ondate prima di Tuten'kash."),
            B("Mordresh Fire Eye",
                "Lich caster casting Fireball Volley & summoning Skeletons.",
                "Lich con Fireball Volley ad area ed evocazione scheletri.",
                "Clear upper bone spiral carefully; pull Mordresh back.", "Pulisci bene la spirale prima; pulla indietro.",
                "Group heals after Fireball Volley.", "Cure di gruppo dopo Fireball Volley.",
                "Interrupt Fireballs & kill summoned skeletons.", "Interrompi le palle di fuoco e uccidi gli scheletri."),
            B("Amnennar the Coldbringer",
                "Final Lich boss! Frostbolt, Frost Nova and repeatedly summons Frost Spectres.",
                "Boss Lich finale! Lancia Frostbolt, Frost Nova ed evoca Spettri.",
                "Keep Amnennar near doorway; pick up Frost Spectres if possible.", "Tanka vicino all'ingresso e raccogli gli Spettri.",
                "Avoid standing in melee Frost Nova; cleanse slows.", "Stai fuori da Frost Nova; cura i picchi sul tank.",
                "Kill summoned Frost Spectres quickly so healer isn't overwhelmed!", "Elimina subito gli Spettri evocati e interrompi i Frostbolt!"),
        },
    },
    [70] = {
        id = 70, kind = "party", expansion = 1, minLvl = 41, maxLvl = 51,
        name = "Uldaman", nameIt = "Uldaman",
        overview = {
            en = "Clear all Stonekeepers before Archaedas wakes golems; Archaedas hits Lv47 — don't enter under Lv42 tank!",
            it = "Pulisci prima le stanze con i Golem; Archaedas è Lv47 e manda ondate crescenti di Earthen!",
        },
        bosses = {
            B("Revelosh",
                "Lightning Bolt + Chain Lightning; drops Staff/Amulet quest items.",
                "Lancia Lightning Bolt e Chain Lightning.",
                "Hold boss cleanly in hall.", "Tanka nella sala.",
                "Spread out for Chain Lightning.", "Spaziati per evitare rimbalzi di Chain Lightning.",
                "Interrupt Lightning Bolts and spread slightly.", "Spaziati e interrompi i cast."),
            B("Ironaya",
                "Giant female Titanic watcher; Arcing Smash frontal cleave + Knock Away.",
                "Guardiana gigante con Arcing Smash frontale e Knock Away.",
                "Back against wall so Knock Away doesn't reset threat range.", "Schiena al muro contro Knock Away; boss girato via dal gruppo.",
                "Stand safely behind boss.", "Stai dietro il boss lontano dal cleave.",
                "Do not stand in front!", "Mai davanti al boss!"),
            B("Obsidian Sentinel",
                "Splits/splinters into small Obsidian shards as HP drops — AoE shards!",
                "Genera frammenti di ossidiana al calare della vita.",
                "Pick up split shard adds.", "Tieni i piccoli frammenti generati.",
                "Moderate AoE/tank healing.", "Cura leggera sugli add.",
                "AoE shards down cleanly.", "AoE sui piccoli frammenti."),
            B("Archaedas",
                "Final boss! Wakes Earthen Guardians continuously (66% Vault Wardens, 33% massive Vault Guardians!).",
                "Boss finale! Risveglia Golem man mano: al 66% Wardens e al 33% enormi Guardiani!",
                "Keep threat on Archaedas & pick up woken Earthen adds as best as possible.", "Tieni Archaedas e riprendi i Guardiani al 66% e 33%.",
                "Expect heavy multi-target damage below 33% HP!", "Cura molto pesante sotto il 33% quando arrivano i grandi Guardiani!",
                "BURN Archaedas fast below 33% (ignore big Guardians and finish boss!) unless falling behind.", "AoE gli add leggeri, poi BURST TOTALE su Archaedas sotto il 33%!", nil, { "archaedas" }),
        },
    },
    [209] = {
        id = 209, kind = "party", expansion = 1, minLvl = 42, maxLvl = 50,
        name = "Zul'Farrak", nameIt = "Zul'Farrak",
        overview = {
            en = "Huge pyramid wave event: help NPCs kill waves cleanly, then talk to Sergeant Bly before leaving!",
            it = "Evento della Piramide enorme: aiuta gli NPC nelle ondate dalla cima delle scale, poi non uscire prima di parlare con Bly!",
        },
        bosses = {
            B("Witch Doctor Zum'rah",
                "Opens graves summoning zombies and casts Healing Wave & Shadow Bolt Volley.",
                "Evoca zombi dalle tombe e lancia Healing Wave + Shadow Bolt Volley.",
                "Pull back to clear area; pick up risen zombies.", "Pulla leggermente indietro e raccogli gli zombi.",
                "Cleanse disease/magic; group heals on Volley.", "Cure di gruppo su Volley.",
                "MUST interrupt Healing Wave! Destroy Wards and AoE zombies.", "INTERROMPI Healing Wave! Distruggi i totem e AoE sugli zombi."),
            B("Pyramid Event (Nekrum / Sezz'ziz)",
                "Wait on TOP of pyramid steps! Kill 2 minibosses when trolls thin out; talk to Sergeant Bly after.",
                "Resta IN CIMA alle scale! Gli NPC ti aiutano sulle ondate; finisci Nekrum e Sezz'ziz.",
                "Hold choke point on pyramid stairs; guard healer from casters.", "Difendi la cima delle scale; proteggi il curatore.",
                "Stay near top; watch mana across long waves!", "Stai in alto e gestisci bene il mana sulle ondate lunghe!",
                "Focus Shadowpriest Sezz'ziz (heals) & blow up waves on stairs.", "Elimina Sezz'ziz (cura!) appena possibile e AoE sulle scale.", nil, { "nekrum", "sezz'ziz", "bly" }),
            B("Gahz'rilla",
                "Summoned by Gong quest; Icicle Freeze & MASSIVE Slam knockup + fall damage!",
                "Evocata col Gong! Sbalza altissimo in aria (danno da caduta!) e congela.",
                "Fight in shallow center water away from stone pillars.", "Tanka al centro dell'acqua bassa.",
                "Top tank/group quickly after high Slam fall damage!", "Cura subito chi cade dallo sbalzo altissimo in aria!",
                "Expect big air knockups — watch your HP when landing!", "Attento allo sbalzo altissimo e al danno da caduta!"),
            B("Chief Ukorz Sandscalp",
                "Final troll boss alongside Ruuzlu; Cleave & Frenzy.",
                "Boss finale insieme a Ruuzlu; Cleave e Frenzy.",
                "Tank both facing away from group.", "Prendi entrambi e girali via dal gruppo.",
                "Moderate healing; watch Frenzy.", "Cura l'aumento di danno in Frenzy.",
                "Kill Ruuzlu first, then Chief Ukorz.", "Uccidi prima Ruuzlu, poi Chief Ukorz."),
        },
    },
    [349] = {
        id = 349, kind = "party", expansion = 1, minLvl = 46, maxLvl = 55,
        name = "Maraudon", nameIt = "Maraudon",
        overview = {
            en = "Bring Nature/Poison cleanses! Princess Theradras hits hard and knocks whole party back.",
            it = "Porta rimozione Veleno/Malattia! Princess Theradras sbalza spesso e fa molto danno Nature.",
        },
        bosses = {
            B("Noxxion",
                "Poison Volley + splits into 5 Noxxion's Spawns twice!",
                "Veleno ad area e si divide in 5 piccoli elementali per due volte!",
                "Gather the 5 split adds for AoE.", "Raggruppa i 5 add quando si divide.",
                "Cleanse Poison repeatedly!", "Pulisci spesso il Veleno!",
                "AoE down the 5 split adds quickly.", "AoE veloce sui 5 add divisi.", "Orange"),
            B("Razorlash",
                "Melee cleave lasher; easy tank & spank.",
                "Pianta melee con Cleave.",
                "Face away from party.", "Gira via dal gruppo.",
                "Steady tank heals.", "Cura costante sul tank.",
                "Burn boss cleanly.", "DPS diretto.", "Orange"),
            B("Celebras the Cursed",
                "Corrupt Forces spawns 3 treants + Wrath/Entangling Roots.",
                "Evoca 3 alberelli e lancia Wrath/Entangling Roots.",
                "Pick up treants; tank away from patrollers.", "Prendi i 3 alberelli.",
                "Dispel Roots if helpful.", "Rimuovi Root se possibile.",
                "Interrupt Wrath & clear treants.", "Interrompi Wrath ed elimina i treant.", "Purple"),
            B("Landslide",
                "Massive stone giant; Stomp stun + Knocks Away + spawns 2 Rubble adds.",
                "Gigante di roccia con Stomp stun, Knock Away ed evoca 2 golem Rubble.",
                "Tank with back against wall against Knock Away!", "Schiena al muro contro Knock Away; prendi gli add Rubble.",
                "Stay out of AoE stomp range.", "Stai lontano dallo Stomp stunnante.",
                "Stay ranged if possible; kill Rubble adds.", "Stai distante dallo Stomp e uccidi i Rubble.", "Inner"),
            B("Tinkerer Gizlock",
                "Goblin shooting Bomb AoE & Goblin Dragon Gun cone!",
                "Goblin con lanciafiamme conico e bombe ad area!",
                "Face Gizlock strictly away from party (Dragon Gun cone hurts!).", "Giralo completamente via dal gruppo (cono infuocato forte!).",
                "Move out of thrown Bombs.", "Evita le bombe lanciate.",
                "Never stand in front (cone) and avoid bombs.", "Mai davanti al cono di fuoco ed evita le bombe.", "Inner"),
            B("Rotgrip",
                "Giant alligator in pool; Puncture bleed + Fatal Bite.",
                "Coccodrillo gigante nell'acqua; sanguinamento e morso pesante.",
                "Tank near shore.", "Tanka vicino alla riva.",
                "Heal bleed DoT on tank.", "Cura il sanguinamento.",
                "Burn down cleanly.", "DPS diretto.", "Inner"),
            B("Princess Theradras",
                "Final boss! Repulsive Gaze (Fear) + Dust Field (knockback + threat wipe!) + Boulder.",
                "Boss finale! Dust Field sbalza e AZZERA aggro; Repulsive Gaze manda in Fear!",
                "Re-taunt/rebuild threat immediately after every Dust Field knockback!", "Riprendi IMMEDIATAMENTE aggro dopo ogni Dust Field (azzera threat)!",
                "Stay back from Dust Field vortex; expect threat drops & Fear.", "Stai a max range fuori da Dust Field; cura il tank al rientro!",
                "Pause 2 sec after Dust Field so tank regains aggro! Ranged avoids vortex.", "Fermati 2 sec dopo Dust Field così il tank riprende aggro!", "Inner"),
        },
    },
    [109] = {
        id = 109, kind = "party", expansion = 1, minLvl = 50, maxLvl = 60,
        name = "Temple of Atal'Hakkar", nameIt = "Tempio Sommerso",
        overview = {
            en = "Kill ALL 6 balcony Troll minibosses to unlock Shade of Eranikus's shield in center!",
            it = "Uccidi tutti e 6 i troll sui balconi superiori per sbloccare la barriera al centro di Jammal'an / Eranikus!",
        },
        bosses = {
            B("Jammal'an the Prophet",
                "Uses Healing Wave, Flamestrike, Hex (turns player into zombie/frog -> kill Hex totem!), alongside Ogom.",
                "Lancia Healing Wave, Flamestrike e Hex (+ Ogom il Wretched).",
                "Hold BOTH Jammal'an & Ogom; move out of Flamestrike.", "Tanka sia Jammal'an sia Ogom; esci da Flamestrike.",
                "Dispel Shadow Word: Pain / Curse of Weakness.", "Dispel DoT e maledizioni.",
                "Kill Ogom first (or interrupt Jammal'an heals & destroy Earthgrab/Hex totems!). Wait out Hexed player!", "Uccidi prima Ogom, poi Jammal'an (INTERROMPI Healing Wave e distruggi i totem)!", nil, { "jammal", "ogom" }),
            B("Dragon Trio (Dreamscythe / Morphaz)",
                "Wing/Acid breath cones + Knockback & Sleeping Fog.",
                "Soffio acido conico davanti + Knockback dietro + nebbia soporifera.",
                "Tank drakes strictly sideways! Never face party; watch tail swipe.", "Posiziona i draghi di fianco al gruppo (soffio davanti, coda dietro).",
                "Stay strictly at their FLANK (side), never head or tail!", "Stai ESATTAMENTE sul fianco: niente soffio né spazzata di coda!",
                "Stand on their side! Focus one dragon at a time.", "Stai sul fianco del drago! Focus su uno alla volta.", nil, { "dreamscythe", "weaver", "morphaz", "hazzas" }),
            B("Shade of Eranikus",
                "Massive green dragon! Deep Slumber sleeps target and WIPES threat on slept tank!",
                "Drago finale! Deep Slumber addormenta e AZZERA aggro sul bersaglio!",
                "Pull all trash out of Eranikus room BEFORE pull (pulls whole room otherwise!). Re-taunt after Sleep!", "PULISCI tutta la stanza prima (altrimenti aggra tutti i draghi)! Riprendi aggro dopo Deep Slumber!",
                "Tank healing spikes; be ready if Sleep hits tank and DPS takes a hit.", "Stai pronto se Deep Slumber colpisce il tank.",
                "Stay on flank (head Acid Breath + tail knockback); stop DPS if tank gets slept!", "Stai sul fianco! Fermati un attimo se il tank viene addormentato!"),
        },
    },
    [230] = {
        id = 230, kind = "party", expansion = 1, minLvl = 52, maxLvl = 60,
        name = "Blackrock Depths", nameIt = "Sotterranei di Roccianera",
        overview = {
            en = "Massive dungeon! Watch Shadowforge Torch mechanics in Lyceum (kill Torchbearers fast to open final gates).",
            it = "Dungeon enorme! Nel Liceo uccidi subito i portatori di torce e usale sui 2 bracieri entro il tempo limite!",
        },
        bosses = {
            B("General Angerforge",
                "Summons adds around 40% HP; Enrage & Sunder Armor.",
                "Evoca molti soldati intorno al 40% HP.",
                "Pull back to doorway/alcove; gather adds at 40%.", "Tanka vicino all'alcova e raccogli gli add al 40%.",
                "Heavy spike at 40% when soldiers spawn.", "Picco di cure al 40% quando arrivano i soldati.",
                "Kill adds or cleave cleanly at 40%, finish Angerforge.", "Gestisci gli add al 40% poi finisci Angerforge."),
            B("Golem Lord Argelmach",
                "2 giant Golem guards + Chain Lightning + Shock.",
                "2 grandi Golem guardiani + Chain Lightning.",
                "Pick up golems cleanly away from hallway respawn.", "Prendi golem e boss pulito.",
                "Spread out for Chain Lightning.", "Spaziati per evitare Chain Lightning.",
                "Focus golems first, then spread on Argelmach.", "Uccidi prima i golem, poi spaziati sul boss."),
            B("The Seven (Chest Event)",
                "Speak to Doom'rel to fight 7 Dwarf ghosts one after another.",
                "Parla a Doom'rel per sfidare i 7 fantasmi nani in sequenza.",
                "Watch Aggro swaps cleanly as each ghost activates.", "Tieni aggro su ogni fantasma man mano che si attiva.",
                "Regen/drink whenever possible between waves!", "Gestisci il mana sulle 7 fasi consecutive!",
                "Interrupt casters (Hate'rel / Seeth'rel) & focus active ghost.", "Interrompi i caster e concentrati sul fantasma attivo.", nil, { "doom'rel", "seven" }),
            B("Magmus",
                "Flaming Statues fire lines across room + Fiery Burst knockback.",
                "Statue sputano fiamme lungo la stanza + Knockback.",
                "Tank near doorway corner OR between flame jets away from statues!", "Posizionalo nell'angolo della porta/tra i getti di fuoco.",
                "Stay out of statue fire lanes!", "Resta fuori dalle linee di fuoco delle statue!",
                "Stand in safe pockets away from flame jets and avoid pulling aggro.", "Stai negli spazi sicuri tra le fiamme."),
            B("Emperor Dagran Thaurissan",
                "Final boss! KEEP PRINCESS MOIRA BRONZEBEARD ALIVE if doing quest (do NOT AoE near her — she heals him!). Avatar of Flame = immune/giant phase, kite!",
                "Boss finale! NON uccidere Principessa Moira se hai la quest (tienila lontana o interrompi le sue cure!). Avatar of Flame = fase enorme, kitalo!",
                "Tank Emperor away from Moira; kite or cooldown during Avatar of Flame!", "Tanka l'Imperatore lontano da Moira; kitalo/usa difensivi in Avatar of Flame!",
                "Keep tank alive during Ironfoe/Avatar burst; watch Hand of Thaurissan stun.", "Cura pesante durante Avatar of Flame e lo stun.",
                "Interrupt Princess Moira's heals if needed without killing her! Kite during Avatar of Flame.", "Interrompi le cure di Moira senza ucciderla (se hai quest); kitalo quando diventa gigante!", nil, { "thaurissan", "moira" }),
        },
    },
    [229] = {
        id = 229, kind = "party", expansion = 1, minLvl = 55, maxLvl = 60,
        name = "Blackrock Spire", nameIt = "Bastioni di Roccianera",
        overview = {
            en = "Shares ID 229 for Lower (LBRS) & Upper (UBRS). Clear Rookery eggs carefully & watch UBRS Flamebreakers!",
            it = "Condivide Lower (LBRS) e Upper (UBRS). Non toccare le uova draconiche a caso in UBRS!",
        },
        bosses = {
            B("Highlord Omokk",
                "Hard-hitting ogre with War Stomp & Knock Away.",
                "Ogre con War Stomp e Knock Away.",
                "Back to wall; clear room adds first.", "Schiena al muro dopo aver pulito la sala.",
                "Spot heal after Knock Away.", "Cura dopo Knock Away.",
                "Do not out-threat after Knock Away!", "Occhio all'aggro dopo Knock Away!", "LBRS"),
            B("Mother Smolderweb",
                "Summons spiders on death; Poison Spit.",
                "Sputa veleno ed evoca ragnetti alla morte.",
                "Pick up spawned spiders on death.", "Prendi i ragni alla morte.",
                "Cleanse Poison.", "Pulisci i veleni.",
                "AoE spiders after she dies.", "AoE sui ragni alla morte.", "LBRS"),
            B("Overlord Wyrmthalak",
                "Final LBRS boss! Summons 2 Elite Dragonkin guards at ~50% HP!",
                "Boss finale LBRS! Evoca 2 guardie Dragonkin Élite al ~50% HP!",
                "Hold Wyrmthalak in center corridor; pick up both 50% adds (or CC one).", "Prendi o fai CC alle 2 guardie Dragonkin che arrivano al 50%.",
                "Heavy spike damage at 50% HP.", "Cure pesanti quando escono le 2 guardie al 50%.",
                "CC or burst the 2 Elite Dragonkin adds at 50% ASAP!", "CC o burst immediato sulle 2 guardie al 50%!", "LBRS"),
            B("Pyroguard Emberseer",
                "First UBRS room! Kill channelers, then kite/spread against Fire Nova & Flame Buffet.",
                "Prima sala UBRS! Uccidi i canalizzatori poi spaziati contro Fire Nova.",
                "Tank facing away in middle after adds drop.", "Tanka al centro dopo i canalizzatori.",
                "Spread & heal Fire AoE.", "Cura Fire Nova ad area.",
                "Avoid clustering for Fire AoE.", "Spaziati dal fuoco ad area.", "UBRS"),
            B("Warchief Rend Blackhand",
                "Arena waves first, then rides dragon Gyth! Kill Gyth (fire breath), then Rend (Whirlwind + Mortal Strike).",
                "Ondate nell'arena, poi arriva in groppa a Gyth! Prima uccidi il drago Gyth, poi Rend (Whirlwind).",
                "Kill Gyth facing away from raid, then tank Rend; watch Mortal Strike!", "Tanka prima Gyth girato via, poi Rend (attenzione a Mortal Strike!).",
                "Save mana on arena waves; heavy tank healing through Rend's Mortal Strike!", "Gestisci il mana sulle ondate; cura forte sotto Mortal Strike!",
                "Wait out Gyth breath on sides, then run out of Rend's Whirlwind.", "Stai di lato a Gyth; evita il Whirlwind di Rend.", "UBRS", { "gyth", "rend" }),
            B("The Beast",
                "Massive Core Hound: Fear + huge Knockup + Flamebreak!",
                "Segugio gigante: Fear ad area + sbalzo fortissimo!",
                "Tank with back against wall on side of bridge/room!", "Schiena al muro contro lo sbalzo! Stai pronto dopo il Fear.",
                "Keep everyone topped from Flamebreak & fall damage.", "Cura cadute e fiamme ad area.",
                "Max range to dodge Fear & avoid flying off ledges.", "Max range per evitare Fear e sbalzi.", "UBRS"),
            B("General Drakkisath",
                "Final UBRS boss! Conflagrate stuns/threat-drops tank & deals massive fire dmg + 2 Chromatic guards!",
                "Boss finale UBRS! Conflagrate stordisce e azzera threat sul tank; ha 2 guardie draconiche!",
                "Kite Drakkisath far back OR off-tank/CC guards; 2 tanks swap when Conflagrate hits!", "Kiting/CC sulle guardie; 2 tank si scambiano quando entra Conflagrate sul primo tank!",
                "Heavy tank heals on tank not Conflagrated; stand max range.", "Cura pesante sul tank attivo; max range.",
                "Kill/CC 2 Chromatic Guards first (kite boss with Hunter if kiting!), then burn General.", "Uccidi/CC le 2 guardie (o kite del boss con Hunter), poi focus sul Generale!", "UBRS"),
        },
    },
    [429] = {
        id = 429, kind = "party", expansion = 1, minLvl = 55, maxLvl = 60,
        name = "Dire Maul", nameIt = "Maglio Infausto",
        overview = {
            en = "3 wings (East/West/North). In DM North you can skip Guards for Tribute Run buffs & extra chest loot!",
            it = "3 ali (Est/Ovest/Nord). In Nord puoi saltare le Guardie (Tribute Run) per avere i buff e un forziere bonus alla fine!",
        },
        bosses = {
            B("Alzzin the Wildshaper",
                "DM East final boss! Shapeshifts (Tree/Dire Wolf) + summons Imps at 50% when wall breaks.",
                "Boss finale DM Est! Cambia forma (Albero/Lupo) e al 50% apre il muro con molti Imp!",
                "Pick up pack of non-elite Imps when wall explodes.", "Prendi gli Imp che escono dal muro a metà scontro.",
                "Dispel Wither / Poison; watch shapeshift burst.", "Pulisci veleni/maledizioni; attento ai picchi in forma Lupo.",
                "AoE the Imp swarm quickly!", "AoE immediato sullo sciame di Imp!", "East"),
            B("Immol'thar",
                "DM West! Destroy all 5 Pylons around prison to unlock shield; spawns Eye of Immol'thar.",
                "DM Ovest! Distruggi tutti e 5 i piloni per aprire la gabbia; evoca Eye of Immol'thar.",
                "Hold Immol'thar steadily; watch Portal of Infinity player teleports.", "Mantieni aggro saldo anche quando teletrasporta giocatori.",
                "Top teleported players & heal heavy Trample.", "Cura subito chi viene teletrasportato.",
                "Burn Eye of Immol'thar spawns cleanly.", "Distruggi subito gli Eye of Immol'thar!", "West"),
            B("Prince Tortheldrin",
                "DM West final boss! Counterspell + Arcane Blast + Knockback threat drop.",
                "Boss finale DM Ovest! Counterspell, Arcane Blast e Knockback.",
                "Re-taunt after Knockback threat drop.", "Riprendi subito aggro dopo il Knockback.",
                "Bait Counterspell with fake cast or stay max range!", "Fai fake-cast contro Counterspell e resta a distanza.",
                "Watch threat after Knockback!", "Occhio all'aggro dopo il Knockback.", "West"),
            B("King Gordok",
                "DM North Tribute final boss! Paired with Cho'Rush the Observer (CC Cho'Rush if Tribute, or kill if not!).",
                "Boss finale DM Nord! Accompagnato da Cho'Rush (in Tribute Run NON uccidere le guardie prima, ma puoi uccidere/CC Cho'Rush!).",
                "Tank Gordok (hits very hard with Mortal Strike + Charge); keep back to wall.", "Tanka Gordok con schiena al muro (Mortal Strike pesantissimo!).",
                "Heavy single-target tank healing; CC/interrupt Cho'Rush!", "Cure fortissime sul tank per Mortal Strike; controlla Cho'Rush!",
                "Wait out Gordok's War Stomp; keep Cho'Rush CC'd or interrupted (he heals/nukes!).", "Tieni Cho'Rush sotto CC o interrompi le sue cure/cast; focus Gordok!", "North"),
        },
    },
    [329] = {
        id = 329, kind = "party", expansion = 1, minLvl = 58, maxLvl = 60,
        name = "Stratholme", nameIt = "Stratholme",
        overview = {
            en = "Live Side (Scarlet Bastion) vs Undead Side (Scourge). Watch Eye of Naxxramas scouts — kill before they scream!",
            it = "Lato Vivo (Scarlatto) vs Lato Morto (Flagello). Uccidi subito gli Eye of Naxxramas prima che evochino gargoyle!",
        },
        bosses = {
            B("Cannon Master Willey",
                "Spawns endless Rifleman waves! Pick up dropped Cannonballs to fire the 2 Cannons at adds.",
                "Evoca ondate infinite di fucilieri! Raccogli le palle e spara con i cannoni contro gli add.",
                "Tank Willey near rear pillars; grab Riflemen if cannons miss.", "Tanka Willey vicino ai pilastri e copri i fucilieri.",
                "Avoid cannon knockback and heal adds damage.", "Cura i colpi dei fucilieri.",
                "1 player picks up Cannonballs & fires Cannons to wipe adds while others burn Willey.", "1 giocatore usa i cannoni sugli add mentre gli altri uccidono Willey.", "Live"),
            B("Balnazzar",
                "Live Side final boss! Disguised as Grand Crusader Dathrohan; Mind Control + Sleep + Psychic Scream.",
                "Boss finale Lato Vivo! Inizia come Dathrohan poi si rivela: Mind Control, Sleep e Fear!",
                "Keep threat across Dathrohan->Balnazzar transition; tank near throne wall.", "Mantieni aggro al cambio fase in Demone; schiena al muro.",
                "Dispel Dominate Mind/Sleep & heal AoE Shadow Shock!", "Rimuovi Sleep/Magia e cura dopo il Fear.",
                "CC Mind Controlled teammates (do not kill!); spread for Fear.", "CC su chi subisce Mind Control; stai a distanza dal Fear.", "Live"),
            B("Ramstein the Gorger",
                "Hits like a truck + AoE Knockout stun! Followed by Mindless Undead wave right after!",
                "Colpi pesantissimi e stun AoE! Subito dopo la morte arrivano ondate di scheletri.",
                "Back to corner; cooldowns for heavy melee. Gather skeleton wave right after!", "Schiena al muro e difensivi; poi raccogli gli scheletri all'esterno.",
                "Heavy tank heals on Ramstein + AoE healing for skeleton swarm.", "Cure forti su Ramstein e AoE sugli scheletri seguenti.",
                "Watch threat; AoE skeletons after Ramstein, then regen before Baron.", "Attento all'aggro; AoE sugli scheletri poi recupera mana!", "UD"),
            B("Baron Rivendare",
                "Undead final boss (45-min timer target)! Death Pact heals him if skeletons survive + Unholy Aura.",
                "Boss finale Lato Morto! Evoca 6 scheletri e usa Death Pact per curarsi se restano vivi!",
                "Tank steadily in room center; watch Death Pact skeleton spawns.", "Tanka al centro; muoviti leggermente per raccogliere gli scheletri.",
                "Strong raid/party healing vs permanent Unholy Aura Shadow DoT!", "Cura costante sul gruppo contro l'aura Shadow continua.",
                "KILL SUMMONED SKELETONS IMMEDIATELY so he can't Death Pact heal himself!", "UCCIDI SUBITO gli scheletri evocati o Baron li assorbe con Death Pact per curarsi!", "UD"),
        },
    },
    [289] = {
        id = 289, kind = "party", expansion = 1, minLvl = 58, maxLvl = 60,
        name = "Scholomance", nameIt = "Scholomance",
        overview = {
            en = "Watch Summoner/Necromancer rooms and Darkmaster Gandling's 6 side rooms (MUST clear all 6 rooms first!).",
            it = "Pulisci tutte e 6 le stanze dei mini-boss prima di Gandling; lui teletrasporta singoli giocatori dentro le celle!",
        },
        bosses = {
            B("Kirtonos the Herald",
                "Summoned on porch with Blood of Innocents; Gargoyle form has Knockback near cliff!",
                "Evocato con Sangue degli Innocenti; forma Gargoyle sbalza giù dal balcone!",
                "Tank inside doorway or facing strictly away from balcony drop!", "Tanka dentro l'arco o girato lontano dal dirupo del balcone!",
                "Heavy tank heals through Wing Flap & Shadow Bolt.", "Cura pesante su tank e colpi ombra.",
                "Do not stand near balcony ledge!", "Stai lontano dal bordo del balcone!"),
            B("Jandice Barov",
                "Creates 15 illusions! Only ONE takes real damage / lacks immunity; AoE reveals real Jandice.",
                "Crea molte illusioni! L'originale è l'unica con nome/bersaglio vero (gli add esplodono).",
                "Tag real Jandice or pick up illusions carefully.", "Segna la vera Jandice e raccogli le illusioni.",
                "Watch AoE damage if all illusions are AoE'd at once.", "Attento al danno di gruppo quando muoiono le illusioni.",
                "Use AoE/tab-target to find & focus the real Jandice!", "Trova la vera Jandice (puoi usare un raid mark sopra) e fai focus su di lei!"),
            B("Rattlegore",
                "Hits VERY hard with War Stomp & Knock Away; drops Viewing Room Key.",
                "Colpisce durissimo con War Stomp e Knock Away; droppa la chiave.",
                "Tank with back against stone pillar in cellar.", "Schiena al pilastro contro Knock Away.",
                "Expect heavy tank damage.", "Cura costante pesante sul tank.",
                "Slow/steady threat.", "Attento al threat dopo gli stun."),
            B("Ras Frostwhisper",
                "Fear, Frost Armor & Freeze AoE!",
                "Lancia Fear, Frostbolt Volley e Freeze!",
                "Tank near doorway after clearing lab ghosts.", "Tanka vicino all'ingresso del laboratorio.",
                "Dispel Freeze/Frost slows; spot-heal after Fear.", "Rimuovi Freeze e cura dopo il Fear.",
                "Watch Frost Nova slows and burst cleanly.", "Interrompi e brucia velocemente."),
            B("Darkmaster Gandling",
                "Final boss! Teleports 1 player into one of 6 side rooms (kill small skeletons inside to reopen portal!).",
                "Boss finale! Teletrasporta 1 giocatore in una delle 6 stanze laterali (uccidi gli scheletri dentro per riaprire il portale!).",
                "Hold Gandling steadily while teammate clears their locked room.", "Tieni Gandling al centro mentre chi è stato teletrasportato esce.",
                "Heal remaining party while 1 DPS/healer clears room (self-sustain inside if healed!).", "Attento se vieni teletrasportato tu: uccidi i 3 scheletri piccoli per uscire!",
                "If teleported into a locked room, quickly kill the weak skeletons inside to reopen the door!", "Se vieni teletrasportato in una stanza chiusa, uccidi gli scheletri dentro per riaprire la porta!"),
        },
    },

    ---------------------------------------------------------------------------
    -- CLASSIC RAIDS (Level 60)
    ---------------------------------------------------------------------------
    [249] = {
        id = 249, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Onyxia's Lair", nameIt = "Antro di Onyxia",
        overview = {
            en = "Stay off Whelp caves (edges)! P1/P3: NEVER stand in front OR behind tail! P2: spread around sides for Deep Breath.",
            it = "MAI finire nelle caverne delle uova ai lati! F1/F3: mai davanti al muso né dietro alla coda! F2: sparpagliati ai lati per Deep Breath!",
        },
        bosses = {
            B("Onyxia",
                "P1: Tank north facing wall. P2 (65%): Air phase — kill Whelps & dodge Deep Breath! P3 (40%): Fear + lava cracks!",
                "P1: Tank a nord girata al muro. P2 (65%): Vola — uccidi Whelps ed evita Deep Breath! P3 (40%): Fear + eruzioni lava!",
                "P1/P3: Point Onyxia strictly NORTH; stance-dance / Fear Ward Bellowing Roar in P3!", "P1/P3: Gira il muso sempre a NORD; usa Fear Ward / Berserker Rage su Fear in P3!",
                "Stay STRICTLY on flanks (east/west walls). Watch raid HP on Fireballs/Deep Breath in P2.", "Stai SEMPRE sui fianchi (Est/Ovest)! Cure forti in F2 e F3!",
                "P1: Slow DPS to match tank threat! P2: DoTs + ranged burn & Whelps. P3: Beware Fear threat drops!", "F1: Controlla l'aggro! F2: Ranged sul boss + Whelps. F3: Attento al Fear che azzera posizione!"),
        },
    },
    [309] = {
        id = 309, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Zul'Gurub", nameIt = "Zul'Gurub",
        overview = {
            en = "20-player raid. Kill High Priests to weaken Hakkar's Blood Siphon phase; mind Bloodlord Mandokir's Gaze!",
            it = "Raid da 20. Uccidi i Sommi Sacerdoti per indebolire Hakkar; attento allo Sguardo di Mandokir!",
        },
        bosses = {
            B("High Priestess Jeklik",
                "P1 Bat: Charge/Silence + Bombs. P2 Caster: summons Bats & casts Great Heal!",
                "P1 Pipistrello: Silence + Bomba. P2 Caster: evoca Pipistrelli e lancia Great Heal!",
                "Tank facing away; move out of Fire Bomb pools in P2.", "Spostati dalle bombe di fuoco in F2.",
                "Stay out of Silence range in P1; heal bomb splashes.", "Stai fuori portata Silence in F1.",
                "P2: MUST maintain 100% kick rotation on Great Heal!", "F2: Rotazione fissa di interrupt su Great Heal obbligatoria!"),
            B("High Priest Venoxis",
                "4 Serpent adds + Poison Cloud + Holy Fire in Caster form, deadly melee in Snake form.",
                "4 serpenti + Nuvole di veleno + Holy Fire; in forma Serpente colpi melee enormi.",
                "Kite/move out of Poison Clouds in Snake phase.", "Muoviti fuori dalle nuvole verdi in forma Serpente.",
                "Spread out & dispel Poison / Holy Fire!", "Spaziati e rimuovi Veleno / Holy Fire!",
                "CC/burn the 4 Serpent adds first; avoid Holy Nova knockback.", "CC o uccidi prima i 4 serpenti."),
            B("Bloodlord Mandokir",
                "Rides Ohgan! Threatening Gaze: STOP ALL ATTACKS/CASTS on watched player or he charges & one-shots + levels up!",
                "Sguardo (Threatening Gaze): CHI È GUARDATO DEVE FERMARE TUTTI GLI ATTACCHI/CAST o Mandokir carica e one-shotta!",
                "Kill/off-tank raptor Ohgan cleanly; swap tanks if Mortal Strike stacks.", "Off-tank su Ohgan (ucciderlo lo manda in Frenzy, tienilo vivo o preparati).",
                "Never cast a heal on Mandokir's Gaze target unless safe (wait — STOP attacking/casting if YOU have Gaze!).", "Se hai Threatening Gaze su di te, FERMA OGNI AZIONE fino alla fine!",
                "STOP ATTACKING / STOP PETS if you get Threatening Gaze (boss gains damage every kill!).", "FERMA SUBITO OGNI ATTACCO E PET se ricevi Threatening Gaze!"),
            B("High Priest Thekal",
                "MUST kill Thekal, Lor'Khan & Zath WITHIN ~10 SECONDS of each other or they resurrect!",
                "Devi uccidere Thekal, Lor'Khan e Zath TUTTI ENTRO 10 SECONDI o si resuscitano! Poi Phase 2 Tigre.",
                "Hold bosses separated/tanked cleanly; in P2 tank Tiger facing away (Force Punch).", "Tieni i 3 boss separati; in F2 tanka la Tigre con schiena al muro.",
                "Focus Lor'Khan interrupts + tank healing in P2.", "Cure forti in F2 contro l'alta velocità della Tigre.",
                "Balance HP on all 3 down to ~5%, interrupt Lor'Khan heals, then AoE all 3 down together!", "Porta tutti e 3 al ~5%, interrompi Lor'Khan, poi abbattili insieme!"),
            B("Hakkar",
                "Mind Control + Corrupted Blood AoE + Blood Siphon every 90s (pull a Son of Hakkar right BEFORE Siphon so raid gets Poison debuff instead of healing Hakkar!).",
                "Blood Siphon ogni 90s: uccidi un Figlio di Hakkar PRIMA del Siphon così Hakkar beve veleno invece di curarsi!",
                "Swap tanks on Mind Control! Drag Son of Hakkar to raid 10s before Siphon.", "Scambio tank su Mind Control! Porta un Figlio di Hakkar prima del Siphon!",
                "Sheep/CC Mind Controlled players; top Corrupted Blood players.", "Cura Corrupted Blood e CC su chi subisce Mind Control.",
                "Spread for Corrupted Blood! Poison yourself via Son of Hakkar cloud right before 90s Blood Siphon!", "Spaziati! Prendi il debuff veleno del Figlio di Hakkar pochi secondi prima di Blood Siphon!"),
        },
    },
    [409] = {
        id = 409, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Molten Core", nameIt = "Nucleo Ardente",
        overview = {
            en = "40-player raid. Bring Tranq Shot (Magmadar), heavy Decurse/Dispel (Lucifron/Gehennas/Shazzrah), and Fire Resist for Ragnaros.",
            it = "Raid da 40. Porta Tranq Shot (Magmadar), tanti Decurse/Dispel (Lucifron/Gehennas) e Fire Resistance su Ragnaros!",
        },
        bosses = {
            B("Lucifron",
                "2 Flamewaker Protectors + Impending Doom (2k magic dmg after 10s) + Lucifron's Curse (double mana cost!).",
                "2 Guardie + Impending Doom (Magia) + Maledizione (+100% costo mana!).",
                "MT on Lucifron, OT on the 2 Protectors (Mind Control risk!).", "MT su Lucifron, OT sulle 2 guardie (occhio a Mind Control).",
                "DISPEL Magic (Impending Doom) & DECURSE continuously!", "DISPEL Magia e DECURSE continui su tutto il raid!",
                "Kill the 2 Protectors first; help Decurse if Mage/Druid.", "Uccidi prima le 2 guardie; aiuta con Decurse!"),
            B("Magmadar",
                "Frenzy (MUST Tranquilizing Shot!), Lava Bomb fire pools, and AoE Fear every 30s.",
                "Frenzy (Tranq Shot obbligatorio!), bombe di lava e Fear ogni 30s!",
                "MT uses Fear Ward / Berserker Rage to avoid spinning boss!", "Usa Fear Ward / Berserker Rage per non farti mandare in Fear!",
                "Move out of Lava Bomb fire; max-range healers avoid Fear.", "Stai fuori dalle bombe di fuoco e a max range dal Fear.",
                "Hunters: MUST Tranquilizing Shot Frenzy instantly! Move out of fire pools.", "Cacciatori: TRANQ SHOT immediato su Frenzy! Esci dal fuoco."),
            B("Garr",
                "8 Firesworn adds! Keep 4 Banished by Warlocks, off-tank the rest; adds EXPLODE on death.",
                "8 add Firesworn! Tieni i primi in Banish (Warlock), gli altri su OT; esplodono alla morte.",
                "Hold Garr apart from off-tanked Firesworn.", "MT su Garr, gli OT prendono gli add non bannati.",
                "Watch explosion spikes when Firesworn die.", "Cura i picchi quando esplodono gli add.",
                "Kill unassigned Firesworn one by one away from raid, then Garr, then banished adds.", "Uccidi un add alla volta lontano dal raid, poi Garr, poi gli add in Banish."),
            B("Baron Geddon",
                "Living Bomb: player turns into bomb & explodes after 8s! Run to designated bomb spot AWAY from raid!",
                "Living Bomb: chi ha il debuff DEVE CORRERE VIA DAL RAID e poi tornare! Inferno AoE ogni ~30s!",
                "Keep near safe alcove; run out of Inferno if melee safe.", "Tanka in sicurezza lontano dalle bombe.",
                "Dispels Ignite Mana (burns mana users!); heal Living Bomb runner when they explode!", "Dispel Ignite Mana e cura chi esplode con Living Bomb!",
                "Melee runs OUT during Inferno AoE. Living Bomb target: RUN AWAY from raid ASAP!", "Melee scappa da Inferno! Chi ha Living Bomb CORRA LONTANO dal gruppo!"),
            B("Majordomo Executus",
                "8 guards (4 Priests, 4 Elites)! Reflects Magic/Melee shields every 15s — DO NOT hit during wrong shield!",
                "8 guardie! Ogni 15s alterna Scudo Riflettente Magia o Melee — NON colpire sullo scudo sbagliato!",
                "4 Sheep on Priests + OT on remaining Elites + MT tanks Elites sequentially.", "4 Pecore sui Sacerdoti, gli OT tengono gli Elites.",
                "Heavy multi-tank healing at pull; eases once first 2 Elites die.", "Cura pesante sui tanti tank all'inizio.",
                "STOP CASTING on Magic Reflection Shield! STOP MELEE on Damage Shield! Kill Elites -> Sheep!", "FERMA MAGIE su Scudo Magico! FERMA MELEE su Scudo Fisico! Prima Elites poi Pecore."),
            B("Ragnaros",
                "Final MC boss! Melee Knockback (Wrath of Ragnaros) + Submerge at 3 min -> 8 Sons of Flame (drain mana)!",
                "Boss finale! Sbalzo melee (Wrath of Ragnaros) + al min 3 si immerge ed escono 8 Sons of Flame!",
                "2 Fire-Resist tanks swap aggro on Wrath of Ragnaros knockbacks against rock walls!", "2 Tank con Resistenza Fuoco si alternano dopo Wrath of Ragnaros con schiena alla roccia!",
                "Spread around outer lava ring (>10yd from Fireball/Lava Splash); heal knockback damage.", "Spaziati lungo l'anello esterno per non moltiplicare i danni Fire!",
                "Melee runs out right BEFORE 25s Wrath timer! Submerge: Banish/stun & AoE Sons of Flame immediately!", "Melee esci prima dello sbalzo Wrath! In immersione distruggi subito i Sons of Flame!"),
        },
    },
    [469] = {
        id = 469, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Blackwing Lair", nameIt = "Fortezza dell'Ala Nera",
        overview = {
            en = "MUST EQUIP ONYXIA SCALE CLOAK on Firemaw, Ebonroc, Flamegor & Nefarian (Shadow Flame one-shots without it!).",
            it = "INDISPENSABILE: indossa l'Onyxia Scale Cloak su Firemaw, Ebonroc, Flamegor e Nefarian (o Shadow Flame one-shotta)!",
        },
        bosses = {
            B("Razorgore the Untamed",
                "Phase 1: Mind Control Orb to destroy all 30 Eggs while raid kites adds! Phase 2: Conflagration.",
                "P1: Usa l'Orb per distruggere tutte le 30 uova mentre il raid kità gli add! P2: Burn boss.",
                "Pick up Dragonkin/Legionnaires; protect Orb controller!", "Tieni lontani gli add da chi controlla l'Orb; in F2 scambio su Conflagration.",
                "Kite/heal Orb controller; beware P1 healing aggro!", "Attento all'aggro delle cure in F1 finché l'Orbista rompe le uova!",
                "CC/kite mobs around corners (kill only Mages if needed) until all Eggs break!", "Kità/CC i mob attorno ai pilastri senza ucciderli troppo in fretta finché cadono le uova!"),
            B("Vaelastrasz the Corrupt",
                "Infinite energy/mana buff (Essence of the Red) + 100% threat nuke race! Burning Adrenaline explodes in 20s.",
                "Energia e mana infiniti! Gara DPS pura. Burning Adrenaline uccide dopo 20s: corri fuori dal raid!",
                "Heavy tank swaps every ~45s as Burning Adrenaline kills current tank.", "Scambio tank programmato ogni ~45s quando il MT prende Burning Adrenaline.",
                "Spam unlimited max-rank heals! Burning Adrenaline targets have instant casts for 20s.", "Spamma cure al massimo grado (mana infinito)!",
                "WAIT 3s at pull, watch threat meters closely! Run to wall if Burning Adrenaline hits you!", "ASPETTA 3s all'inizio e controlla l'aggro! Con Burning Adrenaline corri lontano prima di esplodere!"),
            B("Broodlord Lashlayer",
                "Mortal Strike + Knock Away (50% threat drop) + Blast Wave!",
                "Mortal Strike + Knock Away (riduce aggro del 50%) + Blast Wave!",
                "Tank in corner; OTs stay #2 on threat for Knock Away drops!", "Tanka nell'angolo; 2-3 OT subito pronti per i cali di aggro!",
                "Huge tank spike heals around Mortal Strike!", "Cura pesantissima sul tank durante Mortal Strike!",
                "Watch threat very carefully after Knock Away!", "Controlla costantemente l'aggro dopo i Knock Away!"),
            B("Drakes (Firemaw / Ebonroc / Flamegor)",
                "Wear Onyxia Scale Cloak! Firemaw stacks Flame Buffet (LoS behind wall at 5+ stacks!). Flamegor needs Tranq Shot!",
                "Indossa Onyxia Scale Cloak! Su Firemaw nasconditi dietro il muro a 4-5 stack di Flame Buffet; su Flamegor usa Tranq Shot!",
                "Tank swap on Wing Buffet / Shadow of Ebonroc (stop hitting boss healing on Ebonroc!).", "Scambio tank su Wing Buffet / Shadow of Ebonroc! Tanka sul bordo per permettere il LoS!",
                "Hiding healers take turns LoS-resetting Flame Buffet stacks on Firemaw.", "Alternati in LoS dietro l'angolo per azzerare gli stack di Flame Buffet!",
                "LoS stacks cleanly on Firemaw; Hunters Tranq Shot Flamegor; don't pull during Wing Buffet!", "Usa LoS su Firemaw; Tranq Shot su Flamegor; occhio al Wing Buffet!"),
            B("Chromaggus",
                "2 random Brood Afflictions + 2 Breaths! EVERYBODY carries Hourglass Sand (or Cleansing!). Dispel Bronzes/Magic/Poison/Curse/Disease!",
                "2 Soffi + 5 Afflizioni colorate: Dispel immediato e usa Hourglass Sand se stunnato (Bronze)!",
                "Tank in side corner so raid LoS-dodges every Breath!", "Tanka in angolo per permettere al raid di evitare i Soffi in LoS!",
                "Massive dispel priority (Poison/Disease/Curse/Magic); LoS every Breath!", "DISPEL totale su tutti e nasconditi in LoS prima di ogni Soffio!",
                "LoS EVERY Breath (timer bars), DPS in between, Tranq Shot Enrage!", "Nasconditi in LoS ad ogni Soffio! Tranq Shot sull'Enrage!"),
            B("Nefarian",
                "Wear Onyxia Scale Cloak! P1: Kill 42 Drakonids. P2: Lands (Shadow Flame!). Class Calls every 30s! P3 (20%): Bone Constructs!",
                "Indossa Onyxia Scale Cloak! P1: 42 add. P2: Atterra (Shadow Flame!) + Class Call ogni 30s! P3 (20%): Scheletri!",
                "Stance-dance Fear! Facing away from raid; pick up Bone Constructs at 20% in P3.", "Gestisci il Fear e orienta il drago lontano dal raid; prendi gli scheletri al 20%!",
                "Watch Priest Call (STOP direct heals on Priests -> Renew/Shield only!) & Paladin/Shaman calls!", "ATTENZIONE Class Call Prete (le cure dirette applicano danno mortale — solo HoT/Scudi)!",
                "Respect Class Calls (Mage Polymorph decurse, Hunter unequip bow right before, Warrior Berserker!). AoE skeletons at 20%!", "Rispetta ogni Class Call (Mago decurse, Cacciatore togli arco prima della chiamata, ecc.) e AoE al 20%!"),
        },
    },
    [509] = {
        id = 509, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Ruins of Ahn'Qiraj", nameIt = "Rovine di Ahn'Qiraj (AQ20)",
        overview = {
            en = "20-player raid. Mind General Rajaxx waves and clicking Crystals during Ossirian!",
            it = "Raid da 20. Gestisci le ondate di Rajaxx e i Cristalli su Ossirian!",
        },
        bosses = {
            B("Kurinnaxx",
                "Mortal Wound stacks (5x = unhealable!) + Sand Trap explosions!",
                "Stack Mortal Wound sul tank + Trappole di Sabbia esplosive!",
                "2 tanks swap every 4-5 Mortal Wound stacks; kite out of Sand Traps!", "Scambio di 2 tank ogni 4-5 stack di Mortal Wound; spostati dalle trappole!",
                "Stay away from melee Sand Traps; heavy tank healing on swap.", "Stai distante dalle Trappole di Sabbia.",
                "Step clear of Sand Traps immediately before they explode + silence!", "Esci subito dalle Trappole di Sabbia!"),
            B("Moam",
                "Drains mana then triggers Arcane Explosion at 100% mana; summons Mana Fiends every 90s.",
                "Assorbe mana ed esplode a 100% mana; evoca Mana Fiends ogni 90s!",
                "Hold Moam steadily; pick up Mana Fiends if not banished.", "Mantieni Moam e copri eventuali Fiend non bannati.",
                "Watch mana drain / Banish Fiends.", "Gestisci il mana ridotto dal boss.",
                "Burn fast; Warlocks Banish 3 Mana Fiends (or burn 1 by 1)! Drain his mana with Viper Sting/Mana Burn!", "Banish sui Mana Fiends (Warlock); drena il mana di Moam (Viper Sting/Mana Burn) o burst!"),
            B("Buru the Gorger",
                "Immune to damage until Egg explodes under him! Kite boss over Eggs -> burn exposed brain at <20%!",
                "Immune finché non rompi un uovo sotto di lui! Kitalo sopra le uova -> poi sotto al 20% burst finale!",
                "Keep chasing target clear; in Phase 2 tank & burn!", "In Fase 2 (<20%) prendi aggro e brucia tutto.",
                "Heal whoever Buru targets to kite; Phase 2 raid poison AoE!", "Cura chi viene inseguito e poi cure di gruppo in Fase 2.",
                "Soften Eggs to ~10% HP and pop them right AS Buru walks over them!", "Abbassa le uova al 10% e falle esplodere mentre Buru ci passa sopra!"),
            B("Ossirian the Unscarred",
                "Starts Supreme (+300% dmg -> ONE-SHOTS tanks!). Pull near Crystal #1; ALWAYS keep a Crystal active on him!",
                "Senza Cristallo è in Supreme (one-shotta i tank)! Clicca i Cristalli vicino al boss prima che svanisca il debuff!",
                "Drag Ossirian straight from active Crystal to the next Crystal before Supreme returns!", "Sposta il boss da un Cristallo all'altro senza mai far tornare Supreme!",
                "Expect heavy curse/whirlwind/sand damage; dispel Enveloping Winds healer quickly!", "Cura i vortici e il tank quando perde lo scudo del cristallo.",
                "Watch assigned Crystal rotation; pump matching spell school weakness on him!", "Clicca il cristallo a rotazione quando serve e sfrutta la debolezza elementale!"),
        },
    },
    [531] = {
        id = 531, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Temple of Ahn'Qiraj", nameIt = "Tempio di Ahn'Qiraj (AQ40)",
        overview = {
            en = "40-player raid. Needs Nature Resist gear for Princess Huhuran & Frost/Poison tools for Viscidus.",
            it = "Raid da 40. Serve Nature Resist su Huhuran e molte cure/danni Frost su Viscidus.",
        },
        bosses = {
            B("The Prophet Skeram",
                "Blinks around & splits into 2 clones at 75%/50%/25%! Interrupt Arcane Explosion & CC Mind Controls!",
                "Si sdoppia al 75%/50%/25%! Interrompi Arcane Explosion e fai CC sui Mind Control!",
                "Pick up Skeram after every Blink; split tanks for 75%/50%/25% clones.", "Riprendi subito Skeram dopo ogni Blink; separa i cloni!",
                "Stay max range >20yd; heal after Earth Shock.", "Stai oltre 20m dai cloni.",
                "Interrupt Arcane Explosion ALWAYS, Polymorph/Fear MC'd players immediately!", "Interrompi SEMPRE Arcane Explosion e controlla chi ha Mind Control!"),
            B("Battleguard Sartura",
                "3 Royal Guards + non-stop Whirlwind (threat reset after every WW!) -> Stun lock!",
                "3 Guardie Reali + Whirlwind continui con perdita aggro -> vanno stunnati!",
                "Spread tanks across Sartura + 3 Guards; re-taunt/stun out of Whirlwinds!", "Tieni separati Sartura e 3 Guardie; riprendi aggro dopo ogni Whirlwind!",
                "Huge spike heals on random Whirlwind targets!", "Cure rapide su chi viene colpito da Whirlwind.",
                "Kill 3 Guards first with Stun rotations, then Sartura (avoid Whirlwind & Hard Enrage at 20%!).", "Stun a rotazione sulle 3 Guardie prima, poi Sartura!"),
            B("Princess Huhuran",
                "Nature Resist check! Poison Bolt Volley at 30% Berserk hits nearest 15 players!",
                "Test Nature Resistance! Sotto al 30% colpisce i 15 giocatori più vicini con Poison Volley!",
                "Tank swap on Wyvern Sting / Acid Spit stacks!", "Scambio tank sugli stack di Acid Spit!",
                "Remove Wyvern Sting only carefully (puts target to sleep/dot); HUGE raid healing at <30%!", "Cure pesantissime di gruppo sotto il 30%; gestisci Wyvern Sting!",
                "15 Nature-Resist soakers stand closest at 30%! Hunters Tranq Shot Frenzy & burn at 30%!", "I 15 con Nature Resist stanno davanti al 30%! Tranq Shot sul Frenzy e burst finale!"),
            B("Twin Emperors",
                "Vek'lor (Caster immune to physical) & Vek'nilash (Melee immune to magic) MUST stay >60yd apart & swap every ~35s!",
                "Vek'lor (immune fisico) e Vek'nilash (immune magie): devono restare a >60m o si curano a vicenda! Teletrasporto ogni ~35s.",
                "MT tanks Vek'nilash on one side, Warlock tank holds Vek'lor on the other; swap positions cleanly on Teleport!", "Guerriero su Vek'nilash, Warlock con Shadow Resist su Vek'lor: riprendete subito il boss al teletrasporto!",
                "Keep tanks topped across every Teleport threat reset & Unbalancing Strike!", "Cura pesante sui tank subito dopo ogni teletrasporto!",
                "Melee stays on Vek'nilash ONLY; Casters nuke Vek'lor ONLY! Kill mutated scarabs!", "Melee SOLO su Vek'nilash, Caster SOLO su Vek'lor! Distruggi i bug mutati!"),
            B("C'Thun",
                "P1: Spread >10yd around room (Eye Beam chains!) + dodge Dark Glare 180° laser! P2: Kill Tentacles -> jump inside stomach -> weaken C'Thun!",
                "P1: Spaziati >10m (Eye Beam rimbalza!) ed evita il raggio Dark Glare! P2: Uccidi i Tentacoli -> entra nello stomaco!",
                "Keep melee tentacle threat/interrupted cleanly in P2.", "In F2 interrompi e tanka subito i Giant Claw Tentacles.",
                "Enter room staggered so Eye Beam doesn't chain-wipe on pull! Heal stomach players up to ~40% exit.", "Entra nella stanza in ordine! Cura gli addetti allo stomaco prima che muoiano dentro.",
                "P1: NEVER stack <10yd! P2: Kill Tentacles FIRST, jump in stomach to kill Flesh Tentacles -> BURN Weakened C'Thun!", "F1: MAI stare a meno di 10m! F2: Tentacoli prima, poi uccidi quelli nello stomaco per indebolire C'Thun!"),
        },
    },
    [533] = {
        id = 533, kind = "raid", expansion = 1, minLvl = 60, maxLvl = 60,
        name = "Naxxramas", nameIt = "Naxxramas",
        overview = {
            en = "4 Quarters + Frostwyrm Lair. Bring Frost Resist (Sapphiron), Priests (Razuvious MC), and Decurses (Noth/Sapphiron).",
            it = "4 Ala + Sapphiron/KT. Serve Frost Resist (Sapphiron), 2 Preti con Mind Control (Razuvious) e molti Decurse!",
        },
        bosses = {
            B("Anub'Rekhan",
                "Impale line + Locust Swarm (kited around outer ring while clearing Crypt Guards).",
                "Impale in linea + Locust Swarm (va kitato lungo il perimetro!).",
                "Tank on edge; kite Anub'Rekhan around outer perimeter during Locust Swarm!", "Kitalo lungo il bordo esterno della sala durante Locust Swarm!",
                "Spread >8yd for Impale; heal kiting tank cleanly.", "Spaziati per evitare Impale multipli.",
                "Kill Crypt Guards + Scarabs fast; spread out for Impale.", "Elimina Crypt Guards e Scarabs velocemente; spaziati."),
            B("Grand Widow Faerlina",
                "Poison Volley + Rain of Fire; use Priest Mind Control on Worshippers -> sacrifice one to cancel her Enrage!",
                "Pioggia di Fuoco e Frenzy: usa Mind Control sul Worshipper e sacrificalo su di lei per togliere l'Enrage!",
                "Hold Faerlina + Followers cleanly.", "Tanka Faerlina lontano dalle piogge di fuoco.",
                "Dispel Poison Volley; heavy raid healing if Frenzy isn't cancelled quickly.", "Pulisci veleni e sposta da Rain of Fire.",
                "Priests Mind Control Worshipper -> cast Widow's Embrace on Faerlina when she Frenzies!", "Usa Mind Control su un Worshipper per annullare il Frenzy al momento giusto!"),
            B("Maexxna",
                "Web Wrap (frees player on wall) + Web Spray STUNS ENTIRE RAID for 6s every 40s + 30% Frenzy!",
                "Ogni 40s blocca TUTTO il raid per 6s (Web Spray) mentre picchia il tank + 30% Frenzy!",
                "Pop defensive cooldown + HoTs BEFORE every 40s Web Spray stun!", "Usa difensivi e scudi un attimo PRIMA di ogni Web Spray di 40s!",
                "Pre-HoT & Power Word: Shield MT before EVERY Web Spray! Top tank right after.", "Pre-HoT e Scudi sul tank prima di OGNI Web Spray! Rialza al termine.",
                "Break Web Wrapped players off walls immediately; AoE Spiderlings; save CDs for 30%!", "Libera subito chi viene imprigionato sul muro; AoE sui ragnetti!"),
            B("Heigan the Unclean",
                "SAFETY DANCE! Teleports onto platform -> 4 Plague Wave zones erupt sequentially 1 -> 2 -> 3 -> 4 -> 3 -> 2 -> 1!",
                "LA DANZA DI HEIGAN! Eruzioni di veleno nelle 4 zone 1 -> 2 -> 3 -> 4 -> 3 -> 2 -> 1!",
                "Lead melee safely along the exact 4-zone Safety Dance pattern!", "Guida il tank/melee sul ritmo esatto 1-2-3-4-3-2-1!",
                "Focus on staying ALIVE in safe zones (dead players can't DPS; platform is safe during Dance!).", "Priorità assoluta restare VIVI nella danza delle 4 zone!",
                "Do NOT step into green Plague eruptions — follow tank cleanly on the Dance!", "Segui il tank passo dopo passo nella sequenza sicura delle 4 zone!"),
            B("Loatheb",
                "Corrupted Mind = healers can only cast ONCE per 60s! Inevitable Doom unhealable ticks + Spores grant +50% Crit!",
                "Corrupted Mind: i curatori possono curare SOLO 1 VOLTA ogni 60s! Spores danno +50% Crit ai DPS!",
                "Tank self-cooldowns & Healthstones/Consumables! 1 heal at a time.", "Usa pozioni/Healthstone/difensivi: pochissime cure disponibili.",
                "Strict healing rotation (1 healer every 10-15s because of 60s lockout)!", "Rotazione stretta dei curatori (1 solo cast ogni 60s per curatore)!",
                "Group 5 players per Spore (kills spore -> +50% Crit!) & bring Shadow Protection Pots + Bandages!", "Prendi le Spore (+50% Crit) a gruppi di 5 e usa Shadow Protection Pot!"),
            B("Instructor Razuvious",
                "One-shots player tanks! 2 Priests use Mind Control on Death Knight Understudies to Bone Barrier & tank him!",
                "One-shotta qualsiasi tank giocatore! 2 Preti controllano gli Understudy con Mind Control e usano Bone Barrier per tankarlo!",
                "Priests: alternate Mind Control on Understudies -> Taunt + Bone Barrier continuously!", "Preti in Mind Control sugli Understudy: alternate Taunt + Bone Barrier!",
                "Heal Mind-Controlled Understudies & watch Shout AoE mana burn!", "Cura gli Understudy controllati e gestisci il mana.",
                "Stay clear of Disrupting Shout if mana user; burn safely.", "Stai fuori da Disrupting Shout se usi mana!"),
            B("Patchwerk",
                "Pure Tank/Healer DPS check! Hateful Strike hits highest-HP melee in range (~7k physical every 1.2s)!",
                "Test puro per Tank e Healer! Hateful Strike colpisce ogni 1.2s il melee/OT con più vita vicino a lui!",
                "1 MT + 2-3 high-HP Hateful Soak OTs! Keep Soak OTs topped above DPS!", "1 MT + 2-3 OT in cima alla vita per assorbire Hateful Strike!",
                "Assign dedicated spam-healers per Hateful Soak tank — NEVER let them fall behind!", "Cura continua dedicata su ogni Tank di Hateful Strike!",
                "Stay UNDER Hateful tank threat/HP (dip into slime slightly at pull if needed? Watch threat!).", "Massimo DPS senza rubare aggro e senza farti colpire da Hateful Strike!"),
            B("Thaddius",
                "P1: Kill Stalagg & Feugen together on platforms, then jump across gap to Thaddius! P2: POLARITY SHIFT (+ North / - South)!",
                "P1: Uccidi Stalagg e Feugen insieme poi salta al boss! P2: POLARITY SHIFT (+ a sinistra / - a destra)!",
                "MT stands opposite raid side depending on Thaddius polarity / stable spot.", "Posiziona Thaddius fisso al centro; tieni stabili i due gruppi.",
                "Heal jump fall/shock + stay with your SAME Polarity group!", "Raggruppati SOLO con giocatori della tua stessa carica (+ o -)!",
                "CHECK POLARITY DEBUFF IMMEDIATELY: all '+' stack together one side, all '-' stack opposite side! Huge damage boost per ally!", "GUARDA IL TUO SEGNO (+/-): TUTTI '+' da un lato e '-' dall'altro o fai esplodere il raid!"),
            B("Sapphiron",
                "Wear Frost Resist! Air Phase: Frost Bomb drops — HIDE BEHIND ICE BLOCKED PLAYERS before Bomb hits!",
                "Indossa Frost Resist! Fase Volo: congelando alcuni giocatori crea blocchi di ghiaccio: NASCONDITI DIETRO I BLOCCHI!",
                "Position Sapphiron cleanly in center; keep Frost Aura up.", "Tanka al centro; assicurati di avere Frost Resist / Aura.",
                "DECURSE Life Drain immediately! In Air Phase HIDE behind Ice Blocks or die!", "DECURSE Life Drain subito! In volo NASCONDITI dietro i blocchi di ghiaccio!",
                "Move out of Blizzard! In Air Phase run behind an Ice Block before Frost Bomb detonates!", "Esci dalle Blizzard; quando vola nasconditi dietro i blocchi di ghiaccio!"),
            B("Kel'Thuzad",
                "Final boss! P1: Waves (Soldiers/Banshees/Aboms). P2: Kick Frostbolt + spread >10yd (Frost Blast!) + Mind Control + Void Zones! P3 (40%): Crypt Lords!",
                "Boss finale Naxx! P1: Ondate. P2: Interrompi Frostbolt, spaziati >10m (Frost Blast!), esci da Void Zone! P3 (40%): Scarabei!",
                "2 tanks swap on Mind Control / pick up Guardians at 40% P3 (Shackle 2-3 Crypt Lords!).", "Scambia su Mind Control; al 40% (P3) prendi gli scarabei rimanenti dopo gli Shackle!",
                "HEAL FROST BLAST TARGETS IMMEDIATELY (4s >100% HP needed!) & NEVER stack within 10yd!", "Cura IMMEDIATAMENTE i bersagli di Frost Blast! Mai stare a <10m tra giocatori!",
                "Strict >10yd spread! KICK single-target Frostbolts on MT! Move out of red Void Zones & CC Mind Controls!", "Spaziati sempre >10m! INTERROMPI i Frostbolt singoli ed esci subito dalle Void Zone rosse!"),
        },
    },

    ---------------------------------------------------------------------------
    -- WOW FOREVER NEW DUNGEONS (Levels 13-60)
    ---------------------------------------------------------------------------
    ["FOREVER_HALL_OF_THANES"] = {
        id = "FOREVER_HALL_OF_THANES", kind = "party", expansion = 1, isNew = true, minLvl = 13, maxLvl = 18,
        name = "The Hall of Thanes", nameIt = "Sala dei Thane",
        aliases = { "hall of thanes", "old ironforge" },
        overview = {
            en = "WoW Forever dungeon beneath Old Ironforge (13-18). Keep interrupts ready, pull back out of tight rooms, and clear adds fast.",
            it = "Dungeon WoW Forever sotto Vecchia Forgiardente (13-18). Tieni pronte le interruzioni, pulla indietro e pulisci subito gli add.",
        },
        bosses = {
            B("Faldrim Anvilmar",
                "Tank faces him away! Applies Anvilmar's Curse (-20% attack/cast speed per stack, dispel at 3+) and casts Mind Blast (KICK!).",
                "Il Tank lo gira di spalle! Applica Anvilmar's Curse (-20% velocita per stack, dispa a 3+) e lancia Mind Blast (INTERROMPI!).",
                "Face Faldrim away from group and keep steady aggro during dispels.", "Giralo lontano dal gruppo e mantieni aggro durante i dispel.",
                "DISPEL Anvilmar's Curse at 3+ stacks! Spot-heal Mind Blast hits if un-kicked.", "DISPA Anvilmar's Curse a 3+ stack! Cura i colpi di Mind Blast se non interrotti.",
                "INTERRUPT Mind Blast on cooldown and burst cleanly.", "INTERROMPI Mind Blast a ricarica e fai danno pulito."),
            B("Magmatus",
                "Fire elemental with 360-degree Combust AoE + companion Dark Iron Engineers throwing dodgeable dynamite!",
                "Elementale di fuoco con Combust AoE a 360 gradi + Ingegneri Ferroscuro che lanciano dinamite schivabile!",
                "Turn boss away and move out of dynamite zones cleanly.", "Gira il boss lontano ed esci dalle zone della dinamite.",
                "Top off group after Combust pulses and watch melee taking AoE.", "Tieni alto il gruppo dopo Combust e controlla i melee nell'AoE.",
                "Kill Dark Iron Engineers FIRST -> dodge dynamite -> melee step out on Combust cast!", "Uccidi PRIMA gli Ingegneri -> schiva la dinamite -> i melee escono su Combust!"),
            B("Plunder",
                "Heavy charges and knockbacks! Pull back into narrow tunnel space to block knockback scatter.",
                "Cariche e respingimenti pesanti! Pullalo indietro nello stretto tunnel per evitare sbalzi.",
                "Pull Plunder back into a tunnel/wall so knockbacks don't push players into trash.", "Portalo contro muro/tunnel cosi i knockback non mandano gente sui mob.",
                "Keep tank topped after charge bursts; avoid standing behind/wide.", "Tieni alto il tank dopo le cariche e stai riparato dal knockback.",
                "Stay out of charge path and avoid pulling extra packs on knockbacks.", "Evita la linea di carica e non aggroare altri mob sui knockback."),
            B("Durgen Dirgehammer",
                "Final boss! Spawns 2 stone golem adds mid-fight + AoE Fear + stacking tank bleeds.",
                "Boss finale! Evoca 2 golem di pietra a meta fight + Fear AoE + sanguinamenti accumulabili sul tank.",
                "Clear nearby trash BEFORE pulling (AoE Fear!), pick up 2 golems, save wall for post-Fear bleeds.", "Pulisci i mob vicini prima del pull (Fear AoE!), prendi i 2 golem e usa difensive dopo il Fear.",
                "Prepare cooldowns/LoS vs Fear & heavy heals for stacking bleeds on tank.", "Gestisci il Fear e cura pesantemente il tank con gli stack di bleed.",
                "SWITCH TO THE 2 STONE GOLEMS immediately when spawned, then finish Durgen!", "CAMBIA SUI 2 GOLEM DI PIETRA appena appaiono, poi finisci Durgen!"),
        },
    },
    ["FOREVER_RUINS_OF_LORDAERON"] = {
        id = "FOREVER_RUINS_OF_LORDAERON", kind = "party", expansion = 1, isNew = true, minLvl = 15, maxLvl = 20,
        name = "Ruins of Lordaeron", nameIt = "Rovine di Lordaeron",
        aliases = { "ruins of lordaeron", "lordaeron" },
        overview = {
            en = "WoW Forever dungeon in Tirisfal Glades (15-20). Open-air layout: watch patrols, interrupt Drain Life, and keep healer mana steady.",
            it = "Dungeon WoW Forever a Radure di Tirisfal (15-20). Area aperta: occhio alle pattuglie, interrompi Drain Life e gestisci il mana.",
        },
        bosses = {
            B("Witherfang",
                "Diseased undead hound leading courtyard packs; spreads heavy disease/bleed pressure on tank.",
                "Segugio non-morto malato del cortile; applica malattie e sanguinamenti costanti sul tank.",
                "Pull out of patrol paths and keep active mitigation rolling.", "Pullalo fuori dalle pattuglie e mantieni mitigation attiva.",
                "Cleanse disease debuffs and stabilize bleed ticks.", "Rimuovi le malattie e stabilizza i danni da bleed.",
                "Kill surrounding trash first, then burn Witherfang cleanly.", "Pulisci prima i mob attorno, poi brucia Witherfang."),
            B("The Baron",
                "Undead nobleman using Drain Life and AoE Frost Nova roots.",
                "Nobile non-morto con Drain Life e Frost Nova AoE che immobilizza.",
                "Hold steady in clear area; kick Drain Life if in melee.", "Tienilo in zona pulita; interrompi Drain Life appena parte.",
                "Dispel/Free Frost Nova if needed and keep group topped.", "Dispa Frost Nova se serve e tieni su il gruppo.",
                "INTERRUPT Drain Life immediately every cast!", "INTERROMPI subito ogni lancio di Drain Life!"),
            B("Viktor the Vile",
                "Event boss spawned via the fireplace! Rapid back-to-back undead waves drain healer mana before Viktor spawns.",
                "Boss evento evocato dal camino! Ondate rapide di non-morti che mettono alla prova il mana del curatore prima di Viktor.",
                "Pick up each wave fast before mobs reach the healer; hold position near doorway.", "Prendi subito ogni ondata prima che arrivi al curatore.",
                "PACE YOUR MANA across the waves! Use drinks/pots between brief lulls.", "DOSA IL MANA tra le ondate! Sfrutta ogni pausa tra i spawn.",
                "Burst waves down cleanly and stay in range of tank/healer.", "Abbatti in fretta le ondate restando in raggio del tank e curatore."),
            B("The Abandoned",
                "Haunted remnant patrol encounter in the ruins; deals shadow pulses and adds pressure.",
                "Incontro spettrale nelle rovine; infligge impulsi d'ombra e pressione sul gruppo.",
                "Pick up quickly and face away from casters.", "Prendilo subito e tienilo girato lontano dai caster.",
                "Heal steady shadow ticks on party.", "Cura i danni periodici d'ombra sul gruppo.",
                "Interrupt shadow casts and focus down cleanly.", "Interrompi i lanci d'ombra e concentrati sul bersaglio."),
            B("Bjork",
                "Brute physical encounter with heavy melee hits and rear-cleave/knockback.",
                "Bruto fisico con colpi pesanti in mischia e cleave/knockback.",
                "Tank him WITH YOUR BACK TO A WALL or safe flat ground away from edges/other packs.", "Tankalo con le spalle al muro o in spazio sicuro lontano da altre pattuglie.",
                "Focus single-target tank healing through heavy melee hits.", "Focus totale sulle cure al tank contro i colpi fisici pesanti.",
                "Never stand in front/cleave cone and watch knockback positioning.", "Mai davanti al cono di cleave e attenzione alla posizione sui sbalzi."),
            B("Rath'mael",
                "Final southwest caster boss! Channels Flamestrike (INTERRUPT!) and pulses constant unavoidable AoE damage.",
                "Boss caster finale a sud-ovest! Lancia Flamestrike (INTERROMPI!) ed emette un'AoE costante inevitabile.",
                "Hold boss steady for melee interrupts; save stun/kick for Flamestrike.", "Tieni fermo il boss per facilitare le interruzioni su Flamestrike.",
                "Heavy sustained AoE healing fight! Keep everyone topped against constant aura pulses.", "Fight ad alta cura AoE costante! Tieni sempre alto tutto il party.",
                "KICK/STUN Flamestrike immediately and burn him fast before healer OOMs!", "INTERROMPI/STUNNA subito Flamestrike e uccidilo prima che finisca il mana!"),
        },
    },
    ["FOREVER_EXCAVATION_SITE"] = {
        id = "FOREVER_EXCAVATION_SITE", kind = "party", expansion = 1, isNew = true, minLvl = 24, maxLvl = 29,
        name = "Excavation Site: Wetlands", nameIt = "Sito di Scavo: Paludi Grigie",
        aliases = { "excavation site", "whelgar", "excavation site wetlands", "wetlands excavation" },
        overview = {
            en = "WoW Forever dungeon above Whelgar's Excavation in Wetlands (24-29). Pull bosses onto dry clear ground and interrupt Wild Regeneration.",
            it = "Dungeon WoW Forever sopra lo Scavo di Whelgar nelle Paludi Grigie (24-29). Pulla su terreno asciutto/pulito e interrompi Wild Regeneration.",
        },
        bosses = {
            B("Saltspine",
                "Massive crocolisk patrol! Pull him completely OUT of the water onto dry land to avoid Dust Storm/water penalties, and watch stacking diseases.",
                "Enorme coccodrillo di pattuglia! Pullalo COMPLETAMENTE fuori dall'acqua su terraferma e controlla le malattie accumulabili.",
                "Pull Saltspine onto dry land right away before engaging fully.", "Portalo subito fuori dall'acqua su terra asciutta prima del fight.",
                "Cleanse stacking crocolisk disease off tank and heal burst bites.", "Rimuovi le malattie accumulabili sul tank.",
                "Wait until tank pulls him on dry ground, then dodge Dust Storm and burn.", "Aspetta che il tank lo porti a terra, evita Dust Storm e fai danno."),
            B("Shadetooth",
                "Raptor boss near tall grass! Pull FAR AWAY from tall grass so Terrifying Roar fear doesn't push players into hidden raptors; late-fight Enrage.",
                "Boss raptor vicino all'erba alta! Pullalo LONTANO dall'erba cosi il Fear non manda il gruppo nei raptor nascosti; Enrage finale.",
                "Pull Shadetooth into a cleared dry spot far from tall grass! Use defensives on late Enrage.", "Portalo in spazio aperto lontano dall'erba alta! Tieni difensive per l'Enrage finale.",
                "CC/heal through Thicket Hunters and prepare cooldowns for his low-HP Enrage.", "Gestisci gli add Thicket Hunters e tieni cure extra per l'Enrage finale.",
                "CC Thicket Hunters first -> burn Shadetooth away from tall grass!", "Fai CC sui Thicket Hunters -> poi brucia Shadetooth lontano dall'erba!"),
            B("Highland Horror",
                "Optional boss! Casts massive Wild Regeneration self-heal (INTERRUPT!) - dragging him over active campfires counters regeneration.",
                "Boss opzionale! Lancia l'auto-cura Wild Regeneration (INTERROMPI!) - portarlo sui falo accesi contrasta la rigenerazione.",
                "Drag Highland Horror across lit campfires nearby and prepare kicks for Wild Regeneration.", "Trascinalo sui falo accesi nella zona e tieniti pronto a interrompere Wild Regeneration.",
                "Keep party stable during melee hits and help watch campfire positioning.", "Mantieni stabile il gruppo e segui il posizionamento sui falo.",
                "INTERRUPT Wild Regeneration immediately or DPS race resets!", "INTERROMPI subito Wild Regeneration o recupera tutta la vita!"),
            B("Relic Guardian",
                "Final Titan construct! Ranged/Healers stand >10yd out from pulses; throttle DPS after knockback for tank threat.",
                "Costrutto Titano finale! Ranged e Healer a >10m dagli impulsi; frena il DPS dopo i knockback per l'aggro del tank.",
                "Anchor in open center and pick threat right back up after each knockback.", "Posizionalo al centro e riprendi subito aggro dopo ogni knockback.",
                "Stand >10 yards out from melee pulses and keep tank topped.", "Stai a oltre 10 metri dagli impulsi e tieni alto il tank.",
                "Ranged stand >10yd; pause DPS briefly after knockback so tank regains threat!", "Ranged a >10m; rallenta un attimo il DPS dopo il knockback per evitare over-aggro!"),
        },
    },
    ["FOREVER_CITY_OF_DALARAN"] = {
        id = "FOREVER_CITY_OF_DALARAN", kind = "party", expansion = 1, isNew = true, minLvl = 28, maxLvl = 33,
        name = "City of Dalaran", nameIt = "Citta di Dalaran",
        aliases = { "city of dalaran", "dalaran", "dalaran sewers" },
        overview = {
            en = "WoW Forever dungeon in Alterac Mountains entered via Dalaran Sewers (28-33). Bring interrupts, magic dispels, and loose spread.",
            it = "Dungeon WoW Forever nelle Fogne di Dalaran ad Alterac (28-33). Porta interruzioni, dispel magici e stai spaziato.",
        },
        bosses = {
            B("Atrexis the Grave Knight",
                "Summons quick skeleton swarms and buffs himself with Unholy Frenzy (DISPEL/PURGE!).",
                "Evoca sciami di scheletri e si potenzia con Unholy Frenzy (DISPA/RIMUOVI!).",
                "Snap-aggro skeleton swarms cleanly and pop defensives if Unholy Frenzy isn't dispelled.", "Prendi subito gli scheletri evocati e usa difensive se Unholy Frenzy rimane attivo.",
                "Purge/Dispel Unholy Frenzy if able and heal heavy spike hits on tank.", "Rimuovi Unholy Frenzy se puoi e cura i picchi sul tank.",
                "AoE skeleton swarms down fast -> Purge Unholy Frenzy -> burn Atrexis!", "Fai AoE subito sugli scheletri -> rimuovi Unholy Frenzy -> brucia Atrexis!"),
            B("Arcane Anomaly",
                "Arcane elemental firing tracked Focal Blast beams/lines across the room.",
                "Elementale arcano che spara raggi Focal Blast attraverso la stanza.",
                "Hold still near edge/center so ranged can dodge tracking lines easily.", "Tienilo fermo cosi il gruppo schiva facilmente i raggi.",
                "Stay out of Focal Blast trajectory and top off arcane splash.", "Stai fuori dalla traiettoria di Focal Blast e cura gli splash arcani.",
                "Dodge Focal Blast tracking lines and interrupt arcane casts where possible.", "Schiva i raggi Focal Blast e interrompi i lanci arcani possibili."),
            B("Mana Devourer",
                "Drains caster mana rapidly! Burn fast before healers/casters go dry.",
                "Prosciuga rapidamente il mana dei caster! Uccidilo in fretta prima di restare a secco.",
                "Position cleanly for full uptime from physical and caster DPS.", "Posizionalo bene per massimo uptime DPS.",
                "Conserve mana early / use potions & cooldowns before mana drops.", "Risparmia mana all'inizio e usa pozioni/cooldown prima di prosciugarti.",
                "Full burn race! Casters watch mana bars and interrupt drain casts if kickable.", "Burn totale! I caster controllino il mana e interrompano quando possibile."),
            B("Fel Ancient",
                "Corrupted ancient guarding Dalaran's ruined gardens; heavy melee slams and fel/nature debuffs.",
                "Antico corrotto nei giardini in rovina di Dalaran; colpi pesanti e debuff fel/natura.",
                "Face Fel Ancient away from party and mitigate heavy slams.", "Gira il boss lontano dal gruppo e mitiga gli schianti pesanti.",
                "Dispel corruption debuffs and keep tank high against melee slams.", "Dispa i debuff corrotti e tieni alto il tank.",
                "Avoid frontal slams and focus down any summoned sprouts/adds.", "Evita gli schianti frontali e pulisci eventuali add."),
            B("Arcanic Enigma",
                "Spawns Mana Phantoms (SWAP!) and casts Manamorph on party members (DISPEL MANDATORY!).",
                "Evoca Mana Phantoms (CAMBIA TARGET!) e lancia Manamorph sul gruppo (DISPEL OBBLIGATORIO!).",
                "Hold boss steady; be ready to taunt Mana Phantoms off casters.", "Tieni fermo il boss e tauntali i Mana Phantoms dai caster.",
                "DISPEL Manamorph immediately! Watch healing while targets are morphed.", "DISPA SUBITO Manamorph! Attenzione ai bersagli trasformati.",
                "KILL MANA PHANTOMS immediately when spawned, then resume boss.", "UCCIDI SUBITO i Mana Phantoms appena appaiono, poi torna sul boss."),
            B("Unstable Sentinel",
                "Arcane guardian with pulsing AoE bursts and knockbacks; watch platform/room boundaries.",
                "Sentinella arcana con esplosioni AoE periodiche e knockback; attento ai bordi della sala.",
                "Tank with back toward safe wall so knockback doesn't pull extra patrols.", "Tankalo con le spalle a un muro sicuro per non finire su altri mob.",
                "Stay ranged from melee arcane pulses and top off splash damage.", "Resta a distanza dagli impulsi arcani e cura lo splash.",
                "Move out on overload/AoE pulses if melee; keep ranged pressure steady.", "Allontanati dagli impulsi se melee; mantieni danno costante da lontano."),
            B("Shade of the Archmage",
                "Final boss! Spread loosely (chain Arc/Frost AoE), dodge moving orb lines, and DO NOT pull him out of his chamber (resets!).",
                "Boss finale! Stai spaziato (AoE a catena), schiva le sfere in movimento e NON portarlo fuori dalla sua sala (si resetta!).",
                "KEEP BOSS INSIDE HIS CHAMBER! Pulling out of the room resets the fight.", "TIENI IL BOSS DENTRO LA SUA SALA! Uscire dalla stanza resetta il combattimento.",
                "Spread loosely inside the chamber, dodge moving orbs, and heal Frost/Arcane hits.", "Spaziati nella sala, schiva le sfere e cura i colpi Arcani/Gelo.",
                "Stay inside the chamber, spread out to avoid chain AoEs, and dodge moving orb lines!", "Resta dentro la sala, spaziati per evitare AoE a catena e schiva le sfere!"),
            B("Lyn the Ignored",
                "Hidden/optional encounter in Dalaran; rapid cast volleys and adds require interrupts and focus.",
                "Incontro opzionale/nascosto a Dalaran; raffiche di incantesimi e add richiedono interruzioni e focus.",
                "Pick up quickly inside her alcove/room and face away.", "Prendila subito nella sua area e tienila girata.",
                "Dispel debuffs and heal focused spell bursts.", "Dispa i debuff e cura le raffiche magiche.",
                "Keep kick rotation up on her casts and clear any extra adds first.", "Mantieni rotazione di kick sui suoi lanci ed elimina subito gli add."),
        },
    },
    ["FOREVER_DROWNED_CITY"] = {
        id = "FOREVER_DROWNED_CITY", kind = "party", expansion = 1, isNew = true, minLvl = 35, maxLvl = 40,
        name = "The Drowned City", nameIt = "La Citta Sommersa",
        aliases = { "drowned city", "the drowned city" },
        overview = {
            en = "WoW Forever sunken dungeon west of Grom'gol in Stranglethorn Vale (35-40). Kill totems, watch water platforms, and dispel curses.",
            it = "Dungeon sommerso WoW Forever a ovest di Grom'gol a Stranglethorn Vale (35-40). Distruggi i totem, controlla le piattaforme e dispa le maledizioni.",
        },
        bosses = {
            B("Zul'Alai",
                "Undead troll voodoo boss! Places empowering totems (DESTROY!) and applies nasty curses.",
                "Boss troll voodoo non-morto! Piazza totem che lo potenziano (DISTRUGGI!) e lancia maledizioni pesanti.",
                "Pull slightly away from dropped totems while DPS snipes them.", "Spostalo leggermente dai totem piazzati mentre il DPS li distrugge.",
                "DECURSE quickly! Prepare for spike strikes if a totem stays alive.", "RIMUOVI LE MALEDIZIONI subito! Occhio ai picchi se resta un totem attivo.",
                "KILL TOTEMS IMMEDIATELY when dropped, decurse if able, then burn Zul'Alai.", "DISTRUGGI SUBITO I TOTEM appena appaiono, poi torna su Zul'Alai."),
            B("Var'Taka",
                "Brinescale naga commander mixing Frost/Nature spells with melee cleaves and naga adds.",
                "Comandante naga Brinescale che unisce magie Gelo/Natura, cleave in mischia e add naga.",
                "Face Var'Taka away from party (cleave!) and pick up naga adds fast.", "Giralo lontano dal gruppo (cleave!) e prendi subito i naga evocati.",
                "Dispel Frost/Nature debuffs and keep party clear of frontal cone.", "Dispa Gelo/Natura e resta fuori dal cono frontale.",
                "Kill minor naga adds first, interrupt Frost/Nature casts, and stay behind him.", "Uccidi prima i naga minori, interrompi i lanci e stai sempre alle sue spalle."),
            B("Captain Dreadrise",
                "Undead pirate captain summoning corsair adds alongside heavy sustained melee hits.",
                "Capitano pirata non-morto che evoca corsari extra oltre a infliggere colpi fisici sostenuti.",
                "Gather corsair adds promptly; manage defensives on heavy single-target bursts.", "Raccogli subito i corsari evocati; usa difensive sui picchi fisici.",
                "Watch tank spike damage whenever Dreadrise & corsair adds hit together.", "Attenzione ai picchi di danno sul tank quando picchia insieme ai corsari.",
                "Burn summoned corsair adds cleanly so tank isn't overwhelmed, then kill Captain.", "Fai fuori subito i corsari evocati per alleggerire il tank, poi chiudi sul Capitano."),
            B("Deathless Marrow",
                "Skeletal guardian encounter (Deathless Guardians): watch bone/frost bursts and add spawns.",
                "Incontro scheletrico (Deathless Guardians): attenzione alle esplosioni d'ossa/gelo e agli add.",
                "Hold guardians cleanly grouped for cleave; interrupt key casts if possible.", "Tieni i guardiani ben raggruppati; interrompi se necessario.",
                "Top off party after AoE pulses and keep tank stable.", "Cura tutto il gruppo dopo gli impulsi AoE e tieni stabile il tank.",
                "Focus target priority if multiple guardians activate -> cleave cleanly.", "Segui la priorita di focus se ci sono piu guardiani attivi -> cleave pulito."),
            B("Primeval Elemental",
                "Ancient water/earth elemental surging with elemental AoE and knockbacks in flooded ruins.",
                "Antico elementale di acqua/terra con AoE elementali e sbalzi tra le rovine sommerse.",
                "Position squarely on safe dry ledge/platform so knockbacks stay safe.", "Posizionalo su terreno/piattaforma sicura per evitare cadute sui knockback.",
                "Heal elemental AoE splashes and watch knockback LoS.", "Cura gli splash AoE elementali e controlla la linea di vista sui sbalzi.",
                "Interrupt water/elemental bolts and stay positioned safely away from water drops.", "Interrompi i dardi elementali e resta in zona sicura."),
            B("Min'loth the Serpent",
                "Final sea serpent boss! Heavy tail-swipes + flooding/water hazards force repositioning onto safe platforms!",
                "Boss serpente marino finale! Colpi di coda + allagamenti/acque pericolose obbligano a spostarsi sulle piattaforme sicure!",
                "Keep head pointed away from raid/platform steps; guide group cleanly during flooding shifts.", "Tieni la testa girata dal gruppo; guida il posizionamento quando cambia l'acqua/piattaforma.",
                "Follow platform moves immediately! Never stand in dangerous flooding ticks while casting.", "Segui subito gli spostamenti sulle piattaforme! Mai restare nell'acqua pericolosa.",
                "Stay out of Tail Swipe behind/head cleave in front -> MOVE onto safe raised platforms during floods!", "Evita la coda dietro e il morso davanti -> SALI subito sulle piattaforme sicure durante gli allagamenti!"),
        },
    },
    ["FOREVER_KROLDOK_STRONGHOLD"] = {
        id = "FOREVER_KROLDOK_STRONGHOLD", kind = "party", expansion = 1, isNew = true, minLvl = 40, maxLvl = 45,
        name = "Krol'dok Stronghold", nameIt = "Roccaforte di Krol'dok",
        aliases = { "kroldok", "krol'dok", "kroldok stronghold" },
        overview = {
            en = "WoW Forever fortified ogre stronghold in The Riverglades (40-45). Interrupt Twilight casters and adapt to Overseer Mugg's weapon swaps!",
            it = "Roccaforte ogre fortificata WoW Forever a Riverglades (40-45). Interrompi i caster Twilight e adattati ai cambi arma di Overseer Mugg!",
        },
        bosses = {
            B("Slavecrusher Grox",
                "Brute ogre slaver with heavy crushing slams and knockdowns.",
                "Ogre schiavista brutale con schianti pesanti e atterramenti.",
                "Face Grox away from party and mitigate crushing slams.", "Gira Grox lontano dal gruppo e mitiga gli schianti pesanti.",
                "Keep tank high ahead of crushing slams; watch threat after knockdowns.", "Tieni sempre alto il tank prima degli schianti e attento all'aggro dopo knockdown.",
                "Stay behind Grox and throttle briefly if knocked back/down.", "Stai dietro Grox e controlla la minaccia dopo gli atterramenti."),
            B("Twilight Commander Zarmok",
                "Twilight Hammer commander casting shadow/fire bursts and commanding cultist adds.",
                "Comandante del Martello del Crepuscolo con raffiche ombra/fuoco e add cultisti.",
                "Keep Zarmok away from casters; gather any Twilight adds cleanly.", "Tieni Zarmok lontano dai caster; raccogli gli add Twilight.",
                "Dispel Shadow/Magic debuffs and heal burst casts.", "Dispa i debuff Ombra/Magia e cura le raffiche.",
                "KICK Zarmok's shadow/fire casts on cooldown and burn adds first!", "INTERROMPI i lanci di Zarmok a ricarica ed elimina prima gli add!"),
            B("War Handler Ashka",
                "Beast-handler ogre paired with war-beasts (also tracked as Tunk / Handler Ashka variants). Kill or CC beasts quickly!",
                "Domatore di bestie con belve da guerra. Elimina o fai CC sulle bestie rapidamente!",
                "Tank Ashka + active beast cleanly or let DPS burn/CC the beast first.", "Tieni Ashka e la belva o lascia che il DPS elimini/faccia CC sulla belva.",
                "Heavy initial damage when boss + beast hit together - pre-HoT/shield tank on pull!", "Danno iniziale alto con boss + belva insieme: prepara cure/scudi al pull!",
                "CC or burst down the war-beast FIRST, then finish War Handler Ashka!", "Fai CC o uccidi PRIMA la belva da guerra, poi chiudi su Ashka!"),
            B("Zalfan Moonshadow",
                "Shadowy assassin/caster boss inside the stronghold; watch ambushes, stealth/shadow bursts, and debuffs.",
                "Assassina/caster d'ombra nella roccaforte; attenzione a imboscate, picchi d'ombra e debuff.",
                "Hold steady in cleared ground so ambushes don't pull extra patrols.", "Resta in spazio pulito cosi gli ambush non aggroano altri mob.",
                "Keep light group heals ready and cleanse shadow/poison debuffs.", "Tieni cure rapide pronte e rimuovi debuff ombra/veleno.",
                "Interrupt shadow casts and focus cleanly if boss dashes/blinks.", "Interrompi i lanci d'ombra e riprendi subito il target se si sposta."),
            B("Nar'gurk",
                "Massive ogre enforcer with sweeping cleaves and heavy rage spikes.",
                "Enorme ogre picchiatore con cleave ampi e picchi di rabbia.",
                "Face Nar'gurk squarely away from melee/ranged; save wall/CDs for enrage.", "Tienilo girato lontano dal gruppo; conserva difensive per l'enrage.",
                "Heavy single-target heals when Nar'gurk enrages.", "Cure forti sul tank durante l'enrage di Nar'gurk.",
                "NEVER stand in front (cleave) and soothe/burn quickly during rage.", "MAI stare davanti (cleave) e brucia veloce durante l'enrage."),
            B("Bossman Toof",
                "Cunning ogre boss commanding scrapper/guard adds in the arena.",
                "Boss ogre astuto che comanda sgherri nell'arena.",
                "Clear arena edge packs before pull; pick up guard adds cleanly.", "Pulisci i bordi dell'arena prima del pull; raccogli gli add.",
                "Spot-heal random targeted hits and keep tank stable.", "Cura eventuali colpi su bersagli casuali e stabilizza il tank.",
                "Burn guard adds down fast before focusing Bossman Toof.", "Uccidi subito gli sgherri evocati, poi concentrati su Toof."),
            B("Overseer Mugg",
                "Final boss (Overlord/Overseer Mugg)! Dynamically swaps weapons to shift attack speed, cleaves, and special attacks across phases!",
                "Boss finale (Overlord/Overseer Mugg)! Cambia arma dinamicamente modificando velocita d'attacco, cleave e abilita tra le fasi!",
                "ADAPT TO EACH WEAPON SWAP: save heavy mitigation for slow heavy-hitting phases, watch threat/cleave repositioning.", "ADATTATI AL CAMBIO ARMA: conserva difensive per le armi lente pesanti e aggiorna posizione sui cleave.",
                "Adjust heal cadence per weapon phase - anticipate heavy tank spike swings.", "Adatta le cure alla fase dell'arma: anticipa i colpi pesanti al tank.",
                "React to weapon swaps (move out on whirlwind/cleave weapons, burn cleanly)!", "Reagisci ai cambi arma (esci da cleave/turbine, mantieni danno costante)!"),
        },
    },
    ["FOREVER_ALCAZ_PRISON"] = {
        id = "FOREVER_ALCAZ_PRISON", kind = "party", expansion = 1, isNew = true, minLvl = 48, maxLvl = 53,
        name = "Alcaz Prison", nameIt = "Prigione di Alcaz",
        aliases = { "alcaz", "alcaz prison", "alcaz island" },
        overview = {
            en = "WoW Forever prison dungeon on Alcaz Island, Dustwallow Marsh (48-53). Tight corridors mixing Defias rogues & Naga water-callers: use CC!",
            it = "Dungeon prigione WoW Forever a Isola di Alcaz, Acquemorte (48-53). Corridoi stretti tra Defias e Naga: usa i Crowd Control!",
        },
        bosses = {
            B("Overseer Wrex",
                "Iron-fisted prison warden patrolling the cell blocks with heavy strikes and stun/control pressure.",
                "Guardiano della prigione nei blocchi celle con colpi pesanti e controllo sul gruppo.",
                "Pull Wrex back into a cleared cell hall away from patrolling guards.", "Pullalo in un corridoio pulito lontano dalle guardie di pattuglia.",
                "Keep tank topped and dispel/heal stun victims quickly.", "Tieni alto il tank e cura subito chi subisce stordimenti.",
                "Clear cell patrols first and burn Wrex cleanly without pulling next block.", "Pulisci prima le pattuglie e uccidi Wrex senza aggroare le celle vicine."),
            B("Tidemistress Ca'zass",
                "Highborne-allied Naga siren casting heavy Frost/Water spells and summoning tide adds.",
                "Sirena Naga con forti magie Acqua/Gelo e evocazione di add marini.",
                "Pull away from water casters if needed and pick up summoned adds fast.", "Posizionala lontano e prendi subito gli add marini evocati.",
                "Dispel Frost/Magic debuffs and heal group splash damage.", "Dispa debuff Gelo/Magia e cura lo splash sul gruppo.",
                "INTERRUPT Ca'zass's frost/water casts and cleave/focus adds promptly!", "INTERROMPI i lanci d'acqua/gelo e fai fuori subito gli add!"),
            B("Katerina the Cleaner",
                "Deadly Defias assassin/enforcer with fast dual-wield bleeds, poisons, and stealth/evasion tricks.",
                "Assassina Defias letale con doppie lame, sanguinamenti, veleni ed evasione.",
                "Keep Katerina faced away; use cooldowns if poisons/bleeds stack high.", "Tienila girata; usa difensive se accumula veleni e bleed.",
                "DISPEL POISONS quickly and watch burst combos on melee/healer.", "DISPA I VELENI subito e attento alle combo su melee/curatore.",
                "Burn cleanly when evasion drops and keep bleeds/poisons controlled.", "Fai danno pieno quando scade evasion e tieni sotto controllo i veleni."),
            B("The Questioner",
                "Cruel prison interrogator applying tormenting DoTs, fears, or incapacitates inside tight rooms.",
                "Interrogatore spietato che applica DoT, fear e controlli nelle stanze strette.",
                "Hold inside cleared chamber so fears cannot send players into extra cells.", "Combatti in stanza pulita cosi eventuali fear non aggroano altre celle.",
                "Aggressive dispels + steady DoT healing across the party.", "Dispel aggressivi e cure costanti sui DoT del gruppo.",
                "Interrupt torment casts on cooldown and burn down rapidly.", "Interrompi i lanci di tormento a ricarica e brucialo in fretta."),
            B("Blazeroar",
                "Final fiery powerhouse guarding Alcaz's heart! Heavy fire AoE bursts, knockbacks, and brutal tank damage.",
                "Boss finale infuocato nel cuore di Alcaz! Esplosioni di fuoco AoE, knockback e danno pesante sul tank.",
                "Tank with back to solid wall; use Fire Resist / mitigation for heavy bursts.", "Tankalo con le spalle a un muro solido; mitiga i picchi di fuoco.",
                "Pre-heal group fire bursts and keep tank full through fiery cleaves.", "Prepara cure AoE di gruppo sul fuoco e tieni pieno il tank.",
                "Spread slightly to limit fire splash, dodge fire patches, and execute cleanly!", "Spaziati leggermente per lo splash di fuoco, evita le zone infuocate ed esegui pulito!"),
        },
    },
    ["FOREVER_BLACKMAW_HOLD"] = {
        id = "FOREVER_BLACKMAW_HOLD", kind = "party", expansion = 1, isNew = true, minLvl = 55, maxLvl = 60,
        name = "Blackmaw Hold", nameIt = "Rocca di Fauci Nere",
        aliases = { "blackmaw", "blackmaw hold" },
        overview = {
            en = "Massive BRD-scale WoW Forever Level 55-60 dungeon behind the Azshara gates. Heavy Nature/Shadow damage & curse dispels required!",
            it = "Enorme dungeon WoW Forever livello 55-60 stile BRD dietro i cancelli di Azshara. Danni Natura/Ombra pesanti: servi dispel e decurse!",
        },
        bosses = {
            B("Withermaw",
                "Corrupted beast/furbolg monstrosity spreading decay DoTs and heavy physical bites.",
                "Mostruosita corrotta che diffonde DoT di decadimento e morsi fisici pesanti.",
                "Keep Withermaw turned from melee and cycle defensives on heavy bites.", "Tienilo girato lontano dai melee e usa difensive sui morsi.",
                "Cleanse disease/poison decay debuffs and heal spiked tank bites.", "Pulisci i debuff di decadimento e cura i picchi sul tank.",
                "Single-target burn cleanly; watch aggro after any threat drops.", "Danno singolo pulito; controlla l'aggro dopo eventuali reset."),
            B("Impaan the Imprisoner",
                "Void/Shadow jailer summoning shackles/prisons and shadow adds.",
                "Carceriere d'Ombra che evoca catene/prigioni e add ombra.",
                "Keep boss near doorway/wall and grab any summoned shadow adds.", "Tienilo in zona sicura e raccogli subito gli add ombra.",
                "DISPEL shadow shackles/curses quickly so party stays mobile!", "DISPA subito prigioni/maledizioni cosi il party resta libero!",
                "Break shackles / swap to shadow adds immediately -> interrupt shadow casts!", "Rompi prigioni / uccidi subito gli add ombra -> interrompi i lanci!"),
            B("Elder Shaman Bloodmane",
                "Corrupted furbolg shaman dropping powerful totems and chain lightning/nature bursts!",
                "Sciamano furbolg corrotto che piazza totem potenti e lancia scariche di fulmini/natura!",
                "Reposition away from hostile totems; interrupt Chain Lightning if in range.", "Spostati dai totem ostili; interrompi Chain Lightning se puoi.",
                "Spread >10yd against Chain Lightning! Heavy Decurse/Nature dispel fight.", "Spaziati >10m per Chain Lightning! Dispa/Decursa pesantemente.",
                "SNIPE TOTEMS FIRST, spread out for Chain Lightning, and KICK heals/bolts!", "DISTRUGGI SUBITO I TOTEM, spaziati per Chain Lightning e INTERROMPI le cure!"),
            B("Bonesnout the Unbroken",
                "Armored war-boar/furbolg charger with high armor, charges, and knockbacks.",
                "Cinghiale/guerriero corazzato con alta armatura, cariche e sbalzi.",
                "Keep back to wall and maintain solid threat against armored hits.", "Spalle al muro e aggro solido contro colpi pesanti.",
                "Keep everyone above half HP in case of sudden charge hits.", "Tieni tutto il gruppo sopra meta vita contro cariche improvvise.",
                "Watch charge lines and maximize armor penetration / magic burst.", "Evita la traiettoria di carica e sfrutta danno magico o debuff armatura."),
            B("Varrox Bleakhoof",
                "Corrupted champion combining heavy melee cleaves with void shockwaves.",
                "Campione corrotto che unisce cleave pesanti in mischia a onde d'urto del vuoto.",
                "Point Varrox firmly away from group; sidestep directional shockwaves.", "Gira Varrox lontano dal gruppo e schiva le onde direzionali.",
                "Keep tank high before shockwave combos and watch melee positioning.", "Tieni alto il tank prima delle onde d'urto.",
                "Stay cleanly behind his flank and dodge frontal/void shockwaves!", "Resta sul fianco/retro e schiva tutte le onde del vuoto!"),
            B("Blackmaw Behemoth",
                "Colossal Void-corrupted furbolg horror! Massive ground slams, raidwide void tremors, and spawned shadow adds.",
                "Colosso furbolg corrotto dal Vuoto! Schianti enormi al suolo, tremori AoE e add d'ombra evocati.",
                "Anchor center, absorb massive slams with cooldowns, and pick up shadow adds.", "Ancorati al centro, assorbi gli schianti coi cooldown e prendi gli add.",
                "Huge AoE heal checks on Void Tremors + heavy tank burst! Decurse rapidly.", "Grandi cure AoE sui tremori del Vuoto + cure forti sul tank!",
                "AoE/Focus shadow adds fast and dodge ground slam rings!", "Elimina subito gli add ombra e schiva i cerchi degli schianti!"),
            B("Unbound Spirit",
                "Final spectral Void boss of Blackmaw Hold! Phases of incorporeal shadow bursts, curses, and spirit spawns.",
                "Boss spettrale finale del Vuoto a Blackmaw Hold! Fasi di esplosioni d'ombra, maledizioni e spiriti evocati.",
                "Track threat cleanly across spirit/incorporeal shifts; pull spirits together.", "Gestisci l'aggro nei cambi fase e raggruppa gli spiriti.",
                "DISPEL/DECURSE relentlessly and stabilize party through void phase bursts.", "DISPA/DECURSA senza sosta e stabilizza il gruppo nelle fasi d'ombra.",
                "Kill manifested spirits immediately -> resume full burn during vulnerable phases!", "Uccidi subito gli spiriti evocati -> danno massimo nelle fasi vulnerabili!"),
        },
    },
    ["FOREVER_SHAPERS_TERRACE"] = {
        id = "FOREVER_SHAPERS_TERRACE", kind = "party", expansion = 1, isNew = true, minLvl = 58, maxLvl = 60,
        name = "Shaper's Terrace", nameIt = "Terrazza del Plasmatore",
        aliases = { "shapers terrace", "shaper's terrace", "shaper terrace", "shapers' terrace" },
        overview = {
            en = "Pre-raid Lv 58-60 Titan crucible overlooking Un'Goro Crater! Tip: Un'Goro Red/Blue/Green/Yellow Power Crystals interact with Titan consoles inside.",
            it = "Crogiolo dei Titani pre-raid Lv 58-60 sopra Un'Goro Crater! Tip: i Cristalli del Potere Rosso/Blu/Verde/Giallo di Un'Goro attivano console dentro.",
        },
        bosses = {
            B("Titanosaur",
                "Colossal devilsaur stomping the entry terrace; massive stomp AoE and heavy crushing bites.",
                "Enorme devilsaur all'ingresso della terrazza; calpestamenti AoE pesanti e morsi devastanti.",
                "Use heavy mitigation on crushing bites and hold far from terrace ledge.", "Usa difensive pesanti sui morsi e tienilo lontano dai bordi.",
                "Heavy tank burst heals + quick AoE recovery after earth-shaking stomps.", "Cure pesanti sul tank + recupero veloce dopo gli stomp AoE.",
                "Stay out from under feet during stomps and burn cleanly.", "Allontanati durante i calpestamenti e fai danno costante."),
            B("Ravasaur Hunters",
                "Coordinated pack encounter! Uses stealth/pounces and bleeds - use CC and kill one target at a time.",
                "Branco coordinato di ravasauri! Usano balzi e sanguinamenti: usa CC e uccidine uno alla volta.",
                "Stack active targets together; watch threat if hunters pounce on backline.", "Tieni insieme i target attivi; recupera subito se saltano sulle retrovie.",
                "Expect multi-target bleed pressure until the first hunter dies.", "Pressione multi-target da bleed finche non muore il primo.",
                "MARK SKULL -> BURST ONE AT A TIME, trap/CC extras!", "SEGNA SKULL -> BRUCIA UNO ALLA VOLTA, fai CC sugli altri!"),
            B("Thunderhoof",
                "Lightning-infused primeval beast charging across the terrace with Thunderstomp bursts.",
                "Bestia primordiale carica di fulmini che carica sulla terrazza con Thunderstomp.",
                "Pull away from edges and maintain threat after charges.", "Tienilo lontano dai bordi e mantieni aggro dopo le cariche.",
                "Spread slightly against lightning shocks and heal tank spikes.", "Spaziati leggermente dalle scosse e cura i picchi sul tank.",
                "Dodge charge paths and spread during storm/lightning bursts.", "Schiva le cariche e spaziati durante le scariche di fulmini."),
            B("Venomridge",
                "Deadly toxic beast spraying poison clouds and stacking armor-melting venom.",
                "Bestia tossica che spruzza nubi velenose e accumula veleno che scioglie l'armatura.",
                "Move Venomridge OUT of green poison pools immediately so melee has room.", "Sposta SUBITO Venomridge fuori dalle pozze verdi di veleno!",
                "POISON DISPELS nonstop! Keep everyone out of toxic clouds.", "DISPEL VELENI senza sosta! Tutti fuori dalle nubi tossiche.",
                "Never stand in green poison clouds and help cleanse/decurse if able.", "Mai stare nelle nubi verdi e aiuta coi dispel veleno se puoi."),
            B("Direhorn Matriarch",
                "Armored triceratops matriarch with frontal Horn Charge + spell-reflect or tough hide phases!",
                "Matriarca direhorn corazzata con carica frontale + fasi di scudo/riflesso!",
                "Aim frontal gore/charge safely into terrain; kite/mitigate enraged charges.", "Indirizza le cariche lontano dal gruppo e mitiga i colpi pesanti.",
                "Heal tank spikes and watch ranged taking reflect damage if active.", "Cura i picchi del tank e attento ai riflessi magici sui caster.",
                "STOP CASTING if spell-reflect shield is up; dodge frontal Horn Charge!", "FERMA I CAST se attiva scudo riflettente e schiva le cariche frontali!"),
            B("Cinder",
                "Volcanic/firebound beast encounter (Cynder); leaves burning magma patches and breathes fire cones.",
                "Bestia vulcanica infuocata (Cynder); lascia pozze di magma e soffia coni di fuoco.",
                "Face Cinder away from group (Fire Breath!) and kite out of magma pools.", "Giralo lontano dal party (Soffio di Fuoco!) e spostalo dal magma.",
                "Spot-heal fire splashes and keep moving out of lava zones.", "Cura gli splash di fuoco ed esci sempre dalle pozze di lava.",
                "Stay on flanks/rear (never in front breath cone!) and dodge magma.", "Resta sui fianchi/retro (mai davanti al soffio!) e schiva il magma."),
            B("King Op",
                "Massive primeval gorilla ruler unleashing ground slams, rock throws, and berserk rages.",
                "Enorme gorilla primordiale con schianti al suolo, lanci di rocce e frenesia.",
                "Save heavy tank cooldowns for King Op's berserk phase.", "Conserva cooldown difensivi pesanti per la fase berserk di King Op.",
                "Keep party topped against thrown rocks/slam AoE and focus tank in berserk.", "Tieni su il party da rocce/schianti e cura forte il tank in berserk.",
                "Dodge thrown boulders / ground rings -> pop cooldowns during berserk burn!", "Schiva rocce e cerchi a terra -> spara i cooldown in fase berserk!"),
            B("Snowtalon",
                "Frost-adapted raptor alpha from higher cliffs; Frost pounces, slows, and cold AoE bursts.",
                "Raptor alpha del gelo delle rupi alte; balzi congelanti, rallentamenti e raffiche di freddo.",
                "Keep firm threat; turn away and break frost slows quickly.", "Mantieni aggro saldo e rompi i rallentamenti se necessario.",
                "Dispel frost debuffs/roots and heal cold AoE damage.", "Dispa radici/gelo e cura i danni AoE freddi.",
                "Spread slightly on frost bursts and focus down quickly.", "Spaziati leggermente sulle esplosioni di gelo e uccidilo in fretta."),
            B("Bolt",
                "High-speed electric/titan hunter! Blinking dashes, shock targets, and fast physical burst.",
                "Cacciatore elettrico/titano velocissimo! Scatti rapidi, scosse e burst fisico veloce.",
                "Re-face quickly whenever Bolt dashes; keep instant-threat tools ready.", "Riposizionalo subito dopo ogni scatto usando provocazioni/istantanei.",
                "Keep fast spot-heals ready if Bolt blinks onto a ranged target.", "Tieniti pronto a cure rapide se salta su un ranged.",
                "React fast to target swaps/dashes and stay spread for chain shocks.", "Reagisci subito agli scatti e resta un po' spaziato dalle scosse."),
            B("Vitrix",
                "Volatile Titan/biological crystal construct! Watch energy beams, crystal spawns, and group-wide pulses.",
                "Costrutto cristallino dei Titani! Attenzione a raggi energetici, cristalli evocati e impulsi sul party.",
                "Position squarely for clear line-of-sight around spawned crystals.", "Posizionalo pulito mantenendo linea di vista libera attorno ai cristalli.",
                "Top party after crystal pulses and keep mobile around beams.", "Tieni alto il party dopo gli impulsi e schiva i raggi.",
                "DESTROY/ACTIVATE spawned crystals per mechanics and dodge Titan energy beams!", "DISTRUGGI i cristalli evocati e schiva i raggi energetici dei Titani!"),
            B("Nanaya",
                "Final pinnacle encounter of Shaper's Terrace! Tests coordination, movement, dispels, and sustained execution.",
                "Boss finale di Shaper's Terrace! Mette alla prova coordinazione, movimento, dispel ed esecuzione costante.",
                "Clean positioning, disciplined cooldown timing on heavy bursts, and tight add pickup.", "Posizionamento pulito, gestione disciplinata dei difensivi e presa rapida di eventuali add.",
                "Pace mana for multi-phase bursts, dispel debuffs fast, and follow movement cues.", "Gestisci il mana tra le fasi, dispa veloce e segui gli spostamenti.",
                "Prioritize adds -> execute movement mechanics -> save major offensive CDs for final burn!", "Priorita agli add -> esegui i movimenti -> tieni i cooldown offensivi per il burn finale!"),
        },
    },

    ---------------------------------------------------------------------------
    -- WOW FOREVER NEW RAIDS (Level 60)
    ---------------------------------------------------------------------------
    ["FOREVER_BARROW_DEEPS"] = {
        id = "FOREVER_BARROW_DEEPS", kind = "raid", expansion = 1, isNew = true, minLvl = 60, maxLvl = 60,
        name = "The Barrow Deeps (10p)", nameIt = "Profondita dei Tumuli (10g)",
        aliases = { "barrow deeps", "the barrow deeps" },
        overview = {
            en = "WoW Forever Lv 60 10-player raid underneath Hyjal/Winterspring/Blackmaw (8 bosses). Non-linear caverns with Warden & Druidic mechanics!",
            it = "Raid WoW Forever Lv 60 da 10 giocatori sotto Hyjal/Winterspring/Blackmaw (8 boss). Caverne non lineari con meccaniche di Guardiani e Druidi!",
        },
        bosses = {
            B("Chillhowl",
                "Subterranean frost beast / Deepscar guardian! Watch chilling cavern bursts, ice patches, and tight cave positioning.",
                "Bestia del gelo sotterranea! Attenzione a raffiche gelide, chiazze di ghiaccio e spazi stretti in caverna.",
                "Hold boss steady away from cave choke points; prepare defensives for frost breath/bursts.", "Tienilo lontano dagli stretti passaggi; usa difensive sui picchi di gelo.",
                "Dispel frost debuffs and heal raid-wide chilling pulses.", "Dispa i debuff gelidi e cura gli impulsi freddi sul raid.",
                "Stay out of frost patches, watch breath cone, and burn cleanly.", "Evita le zone di ghiaccio, attento al cono frontale e fai danno pulito."),
            B("Elder Tangleclaw",
                "Corrupted Druid of the Claw elder! Bears heavy physical bleeds, claw swipes, and root/entangle mechanics.",
                "Anziano Druido dell'Unghia corrotto! Colpi da orso, sanguinamenti pesanti e radici.",
                "Face away from raid (Swipe!) and rotate tank mitigation during enrages.", "Giralo dal raid (Swipe!) e alterna difensive durante gli enrage.",
                "Keep tank high through bleed stacks; dispel/free entangled players fast.", "Tieni alto il tank coi bleed e libera subito chi finisce nelle radici.",
                "Switch immediately to break Entangling Roots on healers/raid -> stay behind boss!", "Rompi subito le radici sui compagni -> resta sempre dietro al boss!"),
            B("Khalith the Dreadspinner",
                "Deep cavern spider matriarch! Web wraps, heavy poison stacks, and spiderling waves.",
                "Matriarca ragno delle caverne profonde! Ragnatele, veleni accumulabili e sciami di ragni.",
                "Pick up spiderling waves cleanly and keep boss faced away from ranged.", "Raccogli subito i piccoli ragni e tieni il boss girato.",
                "AGGRESSIVE POISON DISPELS + heal web-wrapped targets immediately!", "DISPA I VELENI senza sosta e cura subito chi finisce avvolto nella ragnatela!",
                "BREAK WEB WRAPS IMMEDIATELY on allies -> AoE spiderlings -> burn Khalith!", "LIBERA SUBITO gli alleati dalle ragnatele -> AoE sui ragnetti -> focus su Khalith!"),
            B("Well of Sorrow",
                "Corrupted subterranean energy font! Manage corruption stacks, shadow pools, and spawned echoes.",
                "Fonte corrotta sotterranea! Gestisci stack di corruzione, pozze d'ombra ed echi.",
                "Position smoothly around safe perimeter away from corrupted pools.", "Posiziona il fight sul perimetro sicuro lontano dalle pozze corrotte.",
                "Monitor corruption stack levels across raid; cleanse & heal shadow ticks.", "Controlla gli stack di corruzione sul raid; dispa e cura i tick d'ombra.",
                "Swap to manifested echoes fast and avoid standing in shadow/sorrow zones!", "Cambia subito sugli echi evocati ed esci dalle pozze d'ombra!"),
            B("Amethrax",
                "Ancient subterranean crystal/nightmare aberration! Watch crystal resonance bursts and line-of-sight hazards.",
                "Antica aberrazione dei tumuli! Attenzione alle risonanze cristalline e ai rischi di linea di vista.",
                "Keep Amethrax anchored where healers keep clear LoS around pillars.", "Ancora Amethrax in posizione comoda per la linea di vista dei curatori.",
                "Track raid LoS during resonance waves and pre-heal heavy AoE bursts.", "Controlla la linea di vista durante le onde e prepara cure AoE.",
                "Respect crystal resonance warnings / LoS cues and focus any crystal adds!", "Segui gli avvisi di risonanza/LoS e distruggi eventuali cristalli!"),
            B("Del'lynar Songwood",
                "Fallen Watcher / woodland protector! Nature/Moonfire spells, interrupts, and spirit spawns.",
                "Guardiana caduta! Magie Natura/Fuoco Lunare, interruzioni ed evocazioni di spiriti.",
                "Keep steady position; pick up summoned wisps/protectors rapidly.", "Mantieni posizione salda; prendi subito eventuali spiriti evocati.",
                "Dispel Moonfire/Nature DoTs and heal spiky arcane/nature casts.", "Dispa Fuoco Lunare/Natura e cura i picchi magici.",
                "Assign KICK rotation for nature/arcane casts and clear summoned wisps immediately!", "Organizza rotazione di KICK sui lanci ed elimina subito gli spiriti!"),
            B("Ravus & Darlissa",
                "Twin boss encounter! Coordinate two tanks/off-tanks cleanly and watch shared abilities or twin enraged phase.",
                "Incontro doppio! Coordina due tank puliti e attenzione ad abilita condivise o enrage del superstite.",
                "2 TANKS split Ravus and Darlissa cleanly per tactic; communicate kill sync/swaps!", "2 TANK dividono Ravus e Darlissa; coordinate kill simultanea o scambi!",
                "Watch BOTH tanks closely and prepare spike heals on dual-ability overlaps.", "Tieni d'occhio ENTRAMBI i tank e prepara cure sulle sovrapposizioni.",
                "Match DPS split or burn priority per RL call - watch if one enrages on partner death!", "Segui split/focus del RL - attenzione a eventuale enrage alla morte del primo!"),
            B("Sonya Darkhallow",
                "Final boss of The Barrow Deeps! Multi-phase Warden/Shadow encounter testing positioning, dispels, adds, and tight 10p execution.",
                "Boss finale di Profondita dei Tumuli! Incontro multi-fase che testa posizionamento, dispel, add ed esecuzione precisa da 10.",
                "Clean phase transitions, disciplined defensive CDs on shadow bursts, fast add pickup.", "Transizioni di fase pulite, difensive disciplinate e presa immediata degli add.",
                "Save mana/major cooldowns for final phase; fast dispels and group positioning.", "Conserva mana/cooldown maggiori per l'ultima fase; dispel rapidi.",
                "Zero wasted deaths: execute phase positioning, burn adds instantly, save CDs for finale!", "Zero errori: rispetta i movimenti di fase, sciogli subito gli add e usa i CD sul finale!"),
        },
    },
    ["FOREVER_HYJAL_SUMMIT"] = {
        id = "FOREVER_HYJAL_SUMMIT", kind = "raid", expansion = 1, isNew = true, minLvl = 60, maxLvl = 60,
        name = "Hyjal Summit (20p)", nameIt = "Vetta di Hyjal (20g)",
        aliases = { "hyjal summit", "mount hyjal", "nordrassil" },
        overview = {
            en = "WoW Forever Lv 60 20-player raid atop Mount Hyjal (13 bosses). Non-linear mountain & cavern ruins after Bandalar; heavy dispels & multi-tank swaps!",
            it = "Raid WoW Forever Lv 60 da 20 giocatori sulla Vetta di Hyjal (13 boss). Percorso non lineare dopo Bandalar; servono forti dispel e scambi tank!",
        },
        bosses = {
            B("Bandalar",
                "Opening guardian of Hyjal Summit! Unlocks non-linear mountain branches once defeated.",
                "Guardiano iniziale di Hyjal Summit! Sblocca i percorsi non lineari della vetta una volta sconfitto.",
                "Anchor cleanly in entry clearing; establish solid multi-tank threat and defensive rhythm.", "Ancoralo nello spiazzo iniziale; stabilisci aggro e rotazione difensiva.",
                "Monitor heavy physical tank pressure and raid-wide AoE pulses.", "Controlla la pressione sul tank e cura gli impulsi AoE sul raid.",
                "Clean opener! Watch positioning/ground hazards and maintain high uptime.", "Incontro d'apertura! Evita pericoli a terra e mantieni danno costante."),
            B("Time-Lost Battalion",
                "Multi-unit wave/squad encounter! Requires crisp multi-tanking, CC, and target prioritization.",
                "Incontro multi-bersaglio a battaglione! Richiede multi-tank preciso, CC e priorita sui target.",
                "Assign specific tanks per elite lieutenant; pick up waves cleanly without caster aggro.", "Assegna i tank sui luogotenenti; prendi subito le ondate dai caster.",
                "Watch heavy incoming multi-tank healing + emergency peels.", "Cure intense su piu tank contemporaneamente + supporto rapido.",
                "FOLLOW SKULL/X MARKS strictly, use CC where called, and interrupt battalion casters!", "SEGUI RIGOROSAMENTE I MARK (Skull/X), usa i CC e interrompi i caster!"),
            B("Old Gloomlurker",
                "Ancient lurker in Hyjal's shadowy depths; heavy ambushes, poisons/curses, and brutal bursts.",
                "Antico predatore delle profondita ombrose di Hyjal; imboscate, veleni/maledizioni e picchi brutali.",
                "Hold steady in cleared zone; watch sudden threat shifts or heavy bleed spikes.", "Tienilo fermo in zona pulita; attento a reset minaccia o bleed forti.",
                "Fast poison/curse dispels and spiked single-target healing.", "Dispel rapidi di veleni/maledizioni e cure reattive sui picchi.",
                "Spread cleanly if targeted by ambushes/pounces and maximize steady burn.", "Spaziati bene contro eventuali balzi e brucia costantemente."),
            B("Kathris the Haunted",
                "Tormented spirit encounter blending Shadow DoTs, fear/panic mechanics, and spectral adds.",
                "Spirito tormentato con DoT d'Ombra, fear/panico e add spettrali.",
                "Tank safely away from hazards; taunt/grab spectral adds immediately.", "Tanka lontano dai pericoli; prendi subito gli add spettrali.",
                "Decurse/Dispel relentlessly! Keep raid topped prior to shadow/fear bursts.", "Dispa/Decursa senza sosta! Tieni alto il raid prima di ombre/fear.",
                "KILL SPECTRAL ADDS FAST -> keep spread against shadow AoEs -> kick shadow casts!", "UCCIDI SUBITO gli add spettrali -> spaziati dall'AoE -> interrompi i cast!"),
            B("Elder Minderel",
                "Corrupted Hyjal archdruid/elder! Nature storms, healing casts, and summoned treant/lasher waves.",
                "Arcidruido/Anziano corrotto di Hyjal! Tempeste di natura, cure e ondate di treant.",
                "Maintain steady position; gather treant/lasher spawns cleanly for AoE.", "Tieni posizione salda; raggruppa subito i treant per l'AoE.",
                "Heavy Nature dispel checks + intense raid healing during Nature storms.", "Dispel Natura intensi + grandi cure AoE durante le tempeste.",
                "INTERRUPT Elder Minderel's heals IMMEDIATELY and burn treants/lashers on spawn!", "INTERROMPI SUBITO le cure di Minderel e sciogli subito i treant evocati!"),
            B("Council of Thorns",
                "Multi-boss Druidic/Corrupted Council! Multiple dangerous casters/bruisers active simultaneously.",
                "Consiglio multi-boss corrotto! Piu boss caster/fisici attivi contemporaneamente.",
                "Assign dedicated tanks per Council member; keep physicals and casters properly split or stacked per RL.", "Assegna un tank per ciascun membro del Consiglio secondo chiamata RL.",
                "Track ALL assigned tanks simultaneously and prioritize dangerous debuff dispels!", "Tieni d'occhio TUTTI i tank insieme e dispa subito i debuff critici!",
                "STRICT INTERRUPT ASSIGNMENTS + focus kill order without breaking CCs!", "ASSEGNAZIONI DI KICK RIGIDE + focus sull'ordine di uccisione senza rompere i CC!"),
            B("The Wild King",
                "Primal Hyjal beast-king! Ferocious melee cleaves, summoned pack beasts, and savage enrage windows.",
                "Re selvaggio primordiale di Hyjal! Cleave feroci, bestie evocate e fasi di rabbia feroce.",
                "Keep beast-king turned cleanly; off-tank gathers summoned pack beasts instantly.", "Tieni girato il re; l'off-tank raccoglie subito le bestie evocate.",
                "Coordinate external tank defensives during savage enrages!", "Coordina cooldown esterni sul tank durante le fasi enrage!",
                "Never cleave/front-stand -> burst pack beasts -> soothe/burn through enrages!", "Mai stare davanti -> uccidi le bestie evocate -> gestisci l'enrage!"),
            B("Ancient of Decay",
                "Massive blighted tree ancient! Toxic spore clouds, disease/poison auras, and explosive sapling adds.",
                "Enorme antico marcio! Nubi di spore tossiche, auree di malattia/veleno e germogli esplosivi.",
                "Kite out of lingering decay/spore zones cleanly while holding tight aggro.", "Spostalo con ordine fuori dalle nubi di spore mantenendo l'aggro.",
                "Massive Disease/Poison dispel demand + constant aura healing on raid.", "Enorme richiesta di dispel Malattie/Veleni + cure costanti sull'aura.",
                "Kite/kill exploding saplings BEFORE they reach raid; dodge green decay pools!", "Elimina/rallenta i germogli prima che esplodano sul raid; evita pozze verdi!"),
            B("Sylvestris Dusksong",
                "Corrupted dusk sentinel/archer! Sniping shots, shadow traps, and coordinated movement checks.",
                "Sentinella/arciera del crepuscolo corrotta! Tiri mirati, trappole d'ombra e prove di movimento.",
                "Hold clean spacing away from dark traps; communicate rapid threat pickups.", "Tieni spazio pulito lontano dalle trappole; gestione rapida di aggro.",
                "Spot-heal sniped raid targets quickly and keep mobile out of shadow traps.", "Cura subito i bersagli colpiti dai tiri mirati e schiva le trappole.",
                "Stay out of dark ground traps, spread for multi-shot volleys, and swap to any adds.", "Evita le trappole scure, spaziati dalle raffiche e cambia subito su eventuali add."),
            B("Gharalis the Abyssal",
                "Abyssal elemental/void horror! Heavy Shadow/Fire blasts, meteor/abyssal impacts, and infernal/void adds.",
                "Orrore abissale/vuoto! Esplosioni Ombra/Fuoco, impatti di meteore e add abissali.",
                "Swap tanks on debuffs/impacts; off-tank snaps abyssal/void adds fast.", "Scambia i tank sui debuff; l'off-tank prende subito gli add abissali.",
                "Prepare major raid cooldowns for heavy abyssal impacts & splash damage.", "Tieni pronti i cooldown raid per gli impatti abissali pesanti.",
                "Move immediately out of impact circles -> burn abyssal adds -> dodge fire/shadow waves!", "Esci subito dai cerchi d'impatto -> uccidi gli add abissali -> schiva le onde!"),
            B("Anara Chillwind",
                "Deadly frost-witch / chillwind commander! Ice tombs, freezing winds, and raid-wide frost pulses.",
                "Comandante del vento gelido! Tombe di ghiaccio, venti congelanti e impulsi gelidi.",
                "Maintain stable anchor so raid knows safe wind angles; save cooldowns for chill spikes.", "Tieni ancora stabile per gli angoli del vento; conserva difensive sui picchi.",
                "Dispel frost debuffs quickly and focus-heal targets caught in ice/frost combos.", "Dispa veloce il gelo e cura chi finisce nelle combo di ghiaccio.",
                "BREAK ICE TOMBS/BLOCKS IMMEDIATELY if allies freeze and spread for frost bursts!", "ROMPI SUBITO eventuali tombe di ghiaccio sugli alleati e spaziati dal gelo!"),
            B("Tracker Stillwind",
                "Elusive high-mountain hunter encounter! Traps, pet/beast allies, kite checks, and lethal aimed bursts.",
                "Cacciatore elusivo delle alte cime! Trappole, bestie alleate e tiri letali.",
                "Manage pet + hunter cleanly between tanks; clear traps safely.", "Dividi bestia e cacciatore tra i tank; evita le trappole.",
                "Top marked/targeted raid members instantly before lethal aimed bursts land!", "Tieni pieni i bersagli marcati prima che arrivino i tiri letali!",
                "Burn companion beast first if called, dodge floor traps, and soak/avoid marked shots!", "Uccidi la bestia se chiamata, evita trappole a terra e gestisci i tiri marcati!"),
            B("Nythus the Dreadbound",
                "Final 20-player boss of Hyjal Summit! Ultimate execution check combining multi-phase positioning, add waves, heavy dispels, and tank swaps.",
                "Boss finale da 20 di Hyjal Summit! Prova definitiva di coordinazione tra fasi, ondate di add, dispel pesanti e scambi tank.",
                "Crisp 2-3 tank swap communication, disciplined defensive walls, zero missed add pickups.", "Scambi tank precisi, uso disciplinato delle difensive e raccolta immediata degli add.",
                "Synchronize raid-wide healing CDs across phases; instant dispels and strict mana pacing.", "Sincronizza i cooldown raid tra le fasi; dispel istantanei e gestione mana rigorosa.",
                "Execute every phase mechanic cleanly, melt priority adds immediately, save Bloodlust/Heroism & CDs for final burn!", "Esegui ogni meccanica di fase, sciogli subito gli add prioritari e tieni i cooldown maggiori per il burn finale!"),
        },
    },
}

-------------------------------------------------------------------------------
-- Notable Boss Drops / Gear Database (Classic 1-60 + Verified WoW Forever)
-------------------------------------------------------------------------------
local CURATED_BOSS_DROPS = {
    -- Ragefire Chasm [389]
    ["389|taragaman the hungerer"] = { "Crystalline Cuffs (Cloth Wrist)", "Subterranean Cape (Back)" },
    ["389|jergosh the invoker"]    = { "Robe of Evocation (Cloth Chest)", "Cursed Felblade (1H Sword)", "Chanting Blade (Dagger)" },
    -- Wailing Caverns [43]
    ["43|lady anacondra"]          = { "Belt of the Fang (Leather Waist)", "Snakeskin Bag (Container)" },
    ["43|lord cobrahn"]            = { "Leggings of the Fang (Leather Legs)", "Cobrahn's Grasp (Mail Waist)" },
    ["43|kresh"]                   = { "Worn Turtle Shell Shield (Shield)", "Kresh's Back (Shield)" },
    ["43|lord pythas"]             = { "Stinging Viper (1H Mace)", "Armor of the Fang (Leather Chest)" },
    ["43|lord serpentis"]          = { "Gloves of the Fang (Leather Hands)", "Serpent's Shoulders (Leather Shoulder)", "Venomstrike (Bow)" },
    ["43|verdan the everliving"]   = { "Living Root (Staff)", "Seedcloud Buckler (Shield)", "Sporid Cape (Back)" },
    ["43|mutanus the devourer"]    = { "Slime-Encrusted Pads (Mail Shoulder)", "Deep Fathom Ring (Finger)", "Mutant Scale Breastplate (Mail Chest)" },
    -- The Deadmines [36]
    ["36|rhahk'zor"]               = { "Rhahk'Zor's Hammer (2H Mace)" },
    ["36|miner johnson"]           = { "Miner's Cape (Back)" },
    ["36|sneed"]                   = { "Buzzer Blade (Dagger)", "Gnomebot Operating Boots (Leather Feet)" },
    ["36|gilnid"]                  = { "Lavishly Jeweled Ring (Finger)", "Smelting Pants (Cloth Legs)" },
    ["36|mr. smite"]               = { "Smite's Mighty Hammer (2H Mace)", "Thief's Blade (1H Sword)", "Smite's Reaver (1H Axe)" },
    ["36|captain greenskin"]       = { "Impaling Harpoon (Polearm)", "Gold-Plated Buckler (Shield)" },
    ["36|edwin vancleef"]          = { "Cruel Barb (1H Sword)", "Blackened Defias Armor (Leather Chest)", "Cape of the Brotherhood (Back)", "Corsair's Overshirt (Cloth Chest)" },
    ["36|cookie"]                  = { "Cookie's Stirring Rod (Wand)", "Cookie's Tenderizer (1H Mace)" },
    -- Shadowfang Keep [33]
    ["33|baron silverlaine"]       = { "Baron's Scepter (1H Mace)", "Silverlaine's Family Seal (Finger)" },
    ["33|commander springvale"]    = { "Commander's Crest (Shield)", "Arced War Axe (2H Axe)" },
    ["33|odo the blindwatcher"]    = { "Odo's Ley Staff (Staff)", "Girdle of the Blindwatcher (Leather Waist)" },
    ["33|fenrus the devourer"]     = { "Black Wolf Bracers (Leather Wrist)", "Feet of the Lynx (Leather Feet)" },
    ["33|wolf master nandos"]      = { "Feline Mantle (Cloth Shoulder)", "Wolfclaw Gloves (Mail Hands)" },
    ["33|archmage arugal"]         = { "Robes of Arugal (Cloth Chest)", "Belt of Arugal (Cloth Waist)", "Meteor Shard (Dagger)" },
    -- Blackfathom Deeps [48]
    ["48|ghamoo-ra"]               = { "Ghamoo-Ra's Bind (Cloth Wrist)", "Tortoise Armor (Mail Chest)" },
    ["48|lady sarevess"]           = { "Blackfathom Choker (Neck)", "Naga Battle Gloves (Mail Hands)", "Bite of Serra'kis (Dagger)" },
    ["48|twilight lord kelris"]    = { "Rod of the Sleepwalker (Staff)", "Graveyard Robe (Cloth Chest)" },
    ["48|aku'mai"]                 = { "Leech Pants (Cloth Legs)", "Moss Cinch (Leather Waist)", "Strike of the Hydra (2H Sword)" },
    -- The Stockade [34]
    ["34|kam deepfury"]            = { "Iron Knuckles (Fist)", "Kam's Walking Stick (Staff)" },
    -- Gnomeregan [90]
    ["90|viscous fallout"]         = { "Acidic Walkers (Cloth Feet)", "Hydrocane (Staff)" },
    ["90|electrocutioner 6000"]    = { "Electrocutioner Leg (1H Sword)", "Gizmotron Megachopper (2H Axe)" },
    ["90|crowd pummeler 9-60"]     = { "Manual Crowd Pummeler (2H Mace)" },
    ["90|mekgineer thermaplugg"]   = { "Thermaplugg's Left Arm (2H Axe)", "Electromagnetic Gigaflux Reactivator (Cloth Head)", "Charged Gear (Finger)" },
    -- Razorfen Kraul [47]
    ["47|death speaker jargba"]    = { "Death Speaker Mantle (Cloth Shoulder)", "Death Speaker Scepter (1H Mace)" },
    ["47|overlord ramtusk"]        = { "Corpsemaker (2H Axe)", "Tusked Shoulderpads (Mail Shoulder)" },
    ["47|agathelos the raging"]    = { "Swinetusk Shank (Dagger)", "Tusken Helm (Mail Head)" },
    ["47|charlga razorflank"]      = { "Pronged Reaver (1H Sword)", "Brambleweed Leggings (Leather Legs)", "Heart of Agamaggan (Shield)" },
    -- Scarlet Monastery [189]
    ["189|interrogator vishas"]    = { "Torturing Poker (1H Mace)", "Bloodstained Gloves (Leather Hands)" },
    ["189|bloodmage thalnos"]      = { "Orb of the Forgotten Seer (Off-hand)", "Bloodmage Mantle (Cloth Shoulder)" },
    ["189|houndmaster loksey"]     = { "Dog Whistle (Trinket)", "Dog Training Gloves (Leather Hands)", "Loksey's Training Stick (Staff)" },
    ["189|arcanist doan"]          = { "Illusionary Rod (Staff)", "Mantle of Doan (Cloth Shoulder)", "Robe of Doan (Cloth Chest)" },
    ["189|herod"]                  = { "Ravager (2H Axe)", "Herod's Shoulder (Mail Shoulder)", "Raging Berserker's Helm (Mail Head)", "Scarlet Leggings (Mail Legs)" },
    ["189|scarlet commander mograine"] = { "Mograine's Might (2H Mace)", "Aegis of the Scarlet Commander (Shield)", "Gauntlets of Divinity (Mail Hands)" },
    ["189|high inquisitor whitemane"]  = { "Whitemane's Chapeau (Cloth Head)", "Triune Amulet (Neck)", "Hypnotic Blade (Dagger)" },
    -- Razorfen Downs [129]
    ["129|tuten'kash"]             = { "Bonefingers (Leather Hands)", "Carapace of Tuten'kash (Plate Chest)" },
    ["129|mordresh fire eye"]      = { "Gloweye Binding (Cloth Waist)", "Deathchill Armor (Plate Chest)", "Eye of Flame (Wand)" },
    ["129|amnennar the coldbringer"] = { "Coldrage Dagger (Dagger)", "Robes of the Lich (Cloth Chest)", "Icemetal Barbute (Plate Head)" },
    -- Uldaman [70]
    ["70|revelosh"]                = { "Revelosh's Spaulders (Cloth Shoulder)", "Revelosh's Armguards (Mail Wrist)" },
    ["70|ironaya"]                 = { "Ironshod Bludgeon (2H Mace)", "Legguards of the Vault (Plate Legs)" },
    ["70|obsidian sentinel"]       = { "Obsidian Cleaver (2H Axe)", "Stonevault Shiv (Dagger)" },
    ["70|archaedas"]               = { "The Rockpounder (2H Mace)", "Stoneslayer (2H Sword)", "Archaedic Stone (Finger)" },
    -- Zul'Farrak [209]
    ["209|witch doctor zum'rah"]   = { "Zum'rah's Vexing Cane (Staff)", "Jumanza Grips (Cloth Hands)" },
    ["209|gahz'rilla"]             = { "Gahz'rilla Fang (Dagger)", "Bad Mojo Mask (Cloth Head)", "Gahz'rilla Scale Armor (Mail Chest)" },
    ["209|chief ukorz sandscalp"]  = { "Big Bad Pauldrons (Plate Shoulder)", "Embrace of the Lycan (Leather Head)", "Jang'thraze the Protector (1H Sword)" },
    -- Maraudon [349]
    ["349|noxxion"]                = { "Noxxion's Shackles (Plate Wrist)", "Heart of Noxxion (Trinket)" },
    ["349|celebras the cursed"]    = { "Grovekeeper's Drape (Back)", "Phytoskin Spaulders (Leather Shoulder)" },
    ["349|landslide"]              = { "Helm of the Mountain (Plate Head)", "Fist of Stone (1H Mace)" },
    ["349|tinkerer gizlock"]       = { "Gizlock's Hypertech Buckler (Shield)", "Megashot Rifle (Gun)" },
    ["349|rotgrip"]                = { "Albacore Dirk (Dagger)", "Brutal Hauberk (Mail Chest)" },
    ["349|princess theradras"]     = { "Blade of Eternal Darkness (Dagger)", "Blackstone Ring (Finger)", "Charstone Dirk (Dagger)", "Elemental Rockridge Leggings (Plate Legs)" },
    -- Temple of Atal'Hakkar [109]
    ["109|jammal'an the prophet"]  = { "Vestments of the Atal'ai Prophet (Cloth Chest)", "Kilt of the Atal'ai Prophet (Cloth Legs)" },
    ["109|shade of eranikus"]      = { "Fang of the Crystal Spider (Dagger)", "Drakestone (Off-hand)", "Dragon's Call (1H Sword)" },
    -- Blackrock Depths [230]
    ["230|general angerforge"]     = { "Hand of Justice (Trinket)", "Force of Will (Trinket)", "Guiding Stave of Wisdom (Staff)" },
    ["230|golem lord argelmach"]   = { "Omnicast Boots (Cloth Feet)", "Second Wind (Trinket)", "Lumba's Band (Finger)" },
    ["230|the seven (chest event)"] = { "Impervious Giant (1H Mace)", "The Hammer of Grace (1H Mace)", "Dregmetal Spaulders (Plate Shoulder)" },
    ["230|magmus"]                 = { "Golem Skull Helm (Plate Head)", "Lavacrest Leggings (Plate Legs)", "Magmus Stone (Off-hand)" },
    ["230|emperor dagran thaurissan"] = { "Ironfoe (1H Mace)", "Hand of Justice (Trinket)", "Imperial Jewel (Neck)", "Dreadforge Retaliator (2H Axe)", "Robes of the Royal Crown (Cloth Chest)" },
    -- Blackrock Spire [229]
    ["229|highlord omokk"]         = { "Slamshot Shoulders (Leather Shoulder)", "Plate of the Shaman King (Plate Chest)", "Fist of Omokk (2H Mace)" },
    ["229|mother smolderweb"]      = { "Wildheart Boots (Leather Feet)", "Smolderweb's Eye (Neck)", "Venomspitter (Crossbow)" },
    ["229|overlord wyrmthalak"]    = { "Blackcrow (Crossbow)", "Heart of the Wyrmthalak (Neck)", "Tristam Legguards (Mail Legs)" },
    ["229|pyroguard emberseer"]    = { "Volcanic Hammer (1H Mace)", "Emberfury Talisman (Neck)", "Searing Needle (Dagger)" },
    ["229|warchief rend blackhand"] = { "Dal'Rend's Sacred Charge (1H Sword)", "Dal'Rend's Tribal Guardian (1H Sword)", "Felstriker (Dagger)", "Blackhand Doomsaw (Polearm)" },
    ["229|the beast"]              = { "Finkle's Skinner (Dagger)", "The Beast's Fur (Back)", "Boreal Mantle (Cloth Shoulder)" },
    ["229|general drakkisath"]     = { "Draconian Deflector (Shield)", "Painweaver Band (Finger)", "Chromatic Carapace (Quest Item)", "Brigam Girdle (Plate Waist)" },
    -- Dire Maul [429]
    ["429|alzzin the wildshaper"]  = { "Energetic Rod (Staff)", "Gordok's Handwraps (Leather Hands)", "Razor Gauntlets (Mail Hands)" },
    ["429|immol'thar"]             = { "Vigilance Charm (Trinket)", "Tome of Knowledge (Off-hand)", "Bile-Etched Spaulders (Leather Shoulder)" },
    ["429|prince tortheldrin"]     = { "Mindtap Talisman (Trinket)", "Eldritch Reinforced Legplates (Plate Legs)", "Stoneshatter (1H Mace)" },
    ["429|king gordok"]            = { "Tarnished Elven Ring (Finger)", "Gordok's Nose Ring (Finger)", "Barbarous Blade (2H Sword)", "Treant's Bane (2H Axe)" },
    -- Stratholme [329]
    ["329|cannon master willey"]   = { "Master Cannoneer Boots (Mail Feet)", "Willey's Portable Howitzer (Gun)" },
    ["329|balnazzar"]              = { "Star of Mystaria (Neck)", "Grand Crusader's Helm (Plate Head)", "Demonshear (2H Sword)" },
    ["329|ramstein the gorger"]    = { "Ramstein's Lightning Bolts (Trinket)", "Crest of Retribution (Shield)" },
    ["329|baron rivendare"]        = { "Deathcharger's Reins (Mount)", "Runeblade of Baron Rivendare (2H Sword)", "Cape of the Black Baron (Back)", "Skullforge Reaver (1H Sword)" },
    -- Scholomance [289]
    ["289|kirtonos the herald"]    = { "Mirah's Song (1H Sword Quest)", "Dawnspire Cord (Cloth Waist)", "Heart of the Fiend (Shield)" },
    ["289|jandice barov"]          = { "Phantasmal Cloak (Back)", "Frightalon (Leather Feet)", "Barovian Family Sword (1H Sword)" },
    ["289|rattlegore"]             = { "Rattlegore Bone Warshield (Shield)", "Corpselight Greaves (Mail Feet)" },
    ["289|ras frostwhisper"]       = { "Freezing Lich Robes (Cloth Chest)", "Alanna's Embrace (Cloth Chest)", "Bonecreeper Stylus (Wand)" },
    ["289|darkmaster gandling"]    = { "Headmaster's Charge (Staff)", "Witchblade (Dagger)", "Ring of Demonic Guile (Finger)", "Silent Fang (1H Sword)" },
    -- Onyxia [249]
    ["249|onyxia"]                 = { "Vis'kag the Bloodletter (1H Sword)", "Deathbringer (1H Axe)", "Head of Onyxia (Quest/Neck/Trinket)", "Shard of the Scale (Trinket)", "Tier 2 Helms" },
    -- Zul'Gurub [309]
    ["309|high priestess jeklik"]  = { "Jeklik's Crusher (2H Mace)", "Jeklik's Opaline Talisman (Neck)" },
    ["309|high priest venoxis"]    = { "Fang of Venoxis (Dagger)", "Runed Bloodstained Hauberk (Plate Chest)" },
    ["309|bloodlord mandokir"]     = { "Swift Razzashi Raptor (Mount)", "Warblade of the Hakkari (1H Sword)", "Primalist's Seal (Finger)" },
    ["309|high priest thekal"]     = { "Swift Zulian Tiger (Mount)", "Thekal's Grasp (Fist)", "Zulian Slicer (1H Sword)" },
    ["309|hakkar"]                 = { "Zin'rokh, Destroyer of Worlds (2H Sword)", "Heart of Hakkar (Trinket/Buff)", "Cloak of Consumption (Back)", "Touch of Chaos (Wand)" },
    -- Molten Core [409]
    ["409|lucifron"]               = { "Choker of Enlightenment (Neck)", "Tier 1 Boots", "Sabatons of the Flamewalker (Mail Feet)" },
    ["409|magmadar"]               = { "Eskhandar's Right Claw (Fist)", "Striker's Mark (Bow)", "Earthshaker (2H Mace)", "Tier 1 Legs" },
    ["409|garr"]                   = { "Bindings of the Windseeker (Right - Thunderfury)", "Aurastone Hammer (1H Mace)", "Drillborer Disk (Shield)", "Tier 1 Helms" },
    ["409|baron geddon"]           = { "Bindings of the Windseeker (Left - Thunderfury)", "Talisman of Ephemeral Power (Trinket)", "Seal of the Archmagus (Finger)" },
    ["409|majordomo executus"]     = { "Cauterizing Band (Finger)", "Core Forged Greaves (Plate Feet)", "The Eye of Divinity (Priest Quest)", "Ancient Petrified Leaf (Hunter Quest)" },
    ["409|ragnaros"]               = { "Eye of Sulfuras (Legendary Mace)", "Perdition's Blade (Dagger)", "Bonereaver's Edge (2H Sword)", "Spinal Reaper (2H Axe)", "Onslaught Girdle (Plate Waist)", "Tier 2 Legs" },
    -- Blackwing Lair [469]
    ["469|razorgore the untamed"]  = { "The Untamed Blade (2H Sword)", "Mantle of the Blackwing Cabal (Cloth Shoulder)", "Spinehatter (1H Mace)", "Tier 2 Bracers" },
    ["469|vaelastrasz the corrupt"] = { "Dragonfang Blade (Dagger)", "Helm of Endless Rage (Plate Head)", "Red Dragonscale Protector (Shield)", "Tier 2 Belts" },
    ["469|broodlord lashlayer"]    = { "Maladath, Runed Blade of the Black Flight (1H Sword)", "Black Brood Pauldrons (Leather Shoulder)", "Lifegiving Gem (Trinket)", "Tier 2 Boots" },
    ["469|drakes (firemaw / ebonroc / flamegor)"] = { "Drake Fang Talisman (Trinket)", "Rejuvenating Gem (Trinket)", "Styleen's Impeding Scarab (Trinket)", "Shadow Wing Focus Staff (Staff)", "Tier 2 Gloves/Shoulders" },
    ["469|chromaggus"]             = { "Ashjre'thul, Crossbow of Smiting (Crossbow)", "Chromatically Tempered Sword (1H Sword)", "Claw of Chromaggus (1H Mace)", "Elementium Reinforced Bulwark (Shield)", "Tier 2 Shoulders" },
    ["469|nefarian"]               = { "Ashkandi, Greatsword of the Brotherhood (2H Sword)", "Crul'shorukh, Edge of Chaos (1H Axe)", "Mish'undare, Circlet of the Mind Flayer (Cloth Head)", "Staff of the Shadow Flame (Staff)", "Neltharion's Tear (Trinket)", "Tier 2 Chests" },
    -- Ruins of Ahn'Qiraj [509]
    ["509|kurinnaxx"]              = { "Sandstalker Ankleguards (Mail Feet)", "Toughened Silithid Hide Gloves (Leather Hands)" },
    ["509|moam"]                   = { "Eye of Moam (Trinket)", "Gavel of Infinite Wisdom (1H Mace)" },
    ["509|buru the gorger"]        = { "Slimy Ichor Leggings (Leather Legs)", "Fetish of Chitinous Spikes (Trinket)" },
    ["509|ossirian the unscarred"] = { "Crossbow of Imminent Doom (Crossbow)", "Bracers of Brutality (Plate Wrist)", "Sandstorm Cloak (Back)", "Head of Ossirian (Quest Ring/Neck)" },
    -- Temple of Ahn'Qiraj [531]
    ["531|the prophet skeram"]     = { "Cloak of Concentrated Hatred (Back)", "Staff of the Qiraji Prophets (Staff)", "Pendant of the Qiraji Guardian (Neck)" },
    ["531|battleguard sartura"]    = { "Badge of the Swarmguard (Trinket)", "Silithid Claw (Fist)", "Creeping Vine Helm (Leather Head)" },
    ["531|princess huhuran"]       = { "Huhuran's Stinger (Bow)", "Wasphide Gauntlets (Leather Hands)", "Cloak of the Golden Hive (Back)" },
    ["531|twin emperors"]          = { "Kalimdor's Revenge (2H Sword)", "Royal Scepter of Vek'lor (1H Mace)", "Amulet of Vek'nilash (Neck)", "Gloves of the Messiah (Cloth Hands)" },
    ["531|c'thun"]                 = { "Dark Edge of Insanity (2H Axe)", "Death's Sting (Dagger)", "Cloak of Clarity (Back)", "Mark of C'Thun (Neck)", "Eye of C'Thun (Quest Ring)" },
    -- Naxxramas [533]
    ["533|anub'rekhan"]            = { "Touch of Frost (Finger)", "The Plague Bearer (Shield)", "Cryptfiend Silk Cloak (Back)" },
    ["533|grand widow faerlina"]   = { "Widow's Remorse (1H Sword)", "Icebane Pauldrons (Plate Shoulder)" },
    ["533|maexxna"]                = { "Maexxna's Fang (Dagger)", "Kiss of the Spider (Trinket)", "Wraith Blade (1H Sword)" },
    ["533|heigan the unclean"]     = { "Noth's Frigid Heart (Off-hand)", "Preceptor's Hat (Cloth Head)", "Necro-Knight's Garb (Cloth Chest)" },
    ["533|loatheb"]                = { "Brimstone Staff (Staff)", "Ring of Spiritual Fervor (Finger)", "The Eye of Diminution (Trinket)" },
    ["533|instructor razuvious"]   = { "Girdle of the Mentor (Plate Waist)", "Wand of the Whispering Dead (Wand)", "Veil of Eclipse (Back)" },
    ["533|patchwerk"]              = { "The Castigator (1H Mace)", "Severance (2H Axe)", "Band of Reanimation (Finger)", "Cloak of Suturing (Back)" },
    ["533|thaddius"]               = { "The Soul Harvester's Bindings (Cloth Wrist)", "Eye of Nerub (Polearm)", "Spire of Twilight (1H Mace)" },
    ["533|sapphiron"]              = { "Slayer's Crest (Trinket)", "The Restrained Essence of Sapphiron (Trinket)", "Shroud of Dominion (Back)", "Claw of the Frost Wyrm (Fist)" },
    ["533|kel'thuzad"]             = { "Gressil, Dawn of Ruin (1H Sword)", "The Hungering Cold (1H Sword)", "Might of Menethil (2H Mace)", "Kingsfall (Dagger)", "Nerubian Slavemaker (Crossbow)" },
    -- WoW Forever: The Hall of Thanes
    ["FOREVER_HALL_OF_THANES|faldrim anvilmar"]   = { "Ephemeral Choker (Neck)", "Aetherwisp Bracers (Cloth Wrist)", "Spiritwraith Drape (Back)" },
    ["FOREVER_HALL_OF_THANES|magmatus"]           = { "Fang of Magmatus (Dagger)", "Kindlegem Girdle (Leather Waist)", "Flamefist Grips (Leather Hands)" },
    ["FOREVER_HALL_OF_THANES|plunder"]            = { "Golemheart Stave (Staff)", "Golemguard Chest (Mail Chest)", "Treads of the Protector Golem (Mail Feet)" },
    ["FOREVER_HALL_OF_THANES|durgen dirgehammer"] = { "Durgen's Crescent Axe (1H Axe)", "Robes of the Disgraced Thane (Cloth Chest)", "Direhammer Leggings (Leather Legs)" },
    -- WoW Forever: Ruins of Lordaeron
    ["FOREVER_RUINS_OF_LORDAERON|the abandoned"]  = { "Rotmender's Leggings (Cloth Legs)" },
    ["FOREVER_RUINS_OF_LORDAERON|rath'mael"]      = { "Rotmender's Treads (Cloth Feet)" },
    -- WoW Forever: Excavation Site: Wetlands
    ["FOREVER_EXCAVATION_SITE|saltspine"]         = { "Glinteye Slippers (Cloth Feet)", "Saltscale Girdle (Mail Waist)", "Supple Bellyskin Leggings (Leather Legs)" },
    ["FOREVER_EXCAVATION_SITE|shadetooth"]        = { "Raptorclaw Greaves (Mail Feet)", "Raptor's Gaze (Neck)", "Garb of Florid Feathers (Cloth Chest)" },
    ["FOREVER_EXCAVATION_SITE|relic guardian"]    = { "Ring of Power Regulation (Finger)", "Golemsight Long Gun (Gun)", "Reliquary Mantle (Cloth Shoulder)" },
    -- WoW Forever: City of Dalaran
    ["FOREVER_CITY_OF_DALARAN|atrexis the grave knight"] = { "Graveweave Bindings (Cloth Wrist)", "Bonebinder's Signet (Finger)" },
    ["FOREVER_CITY_OF_DALARAN|mana devourer"]     = { "Spine of the Devourer (Staff)", "Manascale Treads (Mail Feet)" },
    ["FOREVER_CITY_OF_DALARAN|unstable sentinel"] = { "Guardian's Dualblade (1H Sword)", "Refractory Scaleguards (Mail Wrist)" },
    ["FOREVER_CITY_OF_DALARAN|shade of the archmage"] = { "Ponderous Orb (Off-hand)", "Violet Sorcerer's Mantle (Cloth Shoulder)", "Archmagister's Faceted Pendant (Neck)" },
}

for guideID, guide in pairs(FP.DUNGEON_GUIDES) do
    if type(guide) == "table" and type(guide.bosses) == "table" then
        for _, boss in ipairs(guide.bosses) do
            local key = tostring(guideID) .. "|" .. string.lower(boss.name or "")
            local drops = CURATED_BOSS_DROPS[key]
            if drops then
                boss.drops = drops
            end
        end
    end
end

local function Q(name, lvl, fac, giver, prereq)
    local f = "Both"
    if fac == "A" or fac == "Alliance" then
        f = "Alliance"
    elseif fac == "H" or fac == "Horde" then
        f = "Horde"
    end
    return {
        name = name,
        level = lvl,
        faction = f,
        giver = giver,
        prereq = prereq,
    }
end

-------------------------------------------------------------------------------
-- Localized Dungeon Quest Givers & Directions (itIT)
-- Keeps Quest Titles, NPC Names, and Cities/Zones in English,
-- but translates directional explanations, hints, and drop sources into Italian.
-------------------------------------------------------------------------------
local QUEST_INSTRUCTIONS_IT = {
    -- Custom / Forever & Classic Givers with directions/explanations
    ["Afadra Dunwall (Above Old Ironforge entrance)"] = "Afadra Dunwall (Sopra l'ingresso di Old Ironforge)",
    ["Thom Filch (Outside Old Ironforge entrance)"] = "Thom Filch (Fuori dall'ingresso di Old Ironforge)",
    ["Earth Seer Farsen (Dun Morogh hillside)"] = "Earth Seer Farsen (Lungo la collina di Dun Morogh)",
    ["Ghostly Attendant (Inside West Wing)"] = "Ghostly Attendant (Dentro l'Ala Ovest)",
    ["Stone tablet (Final boss room)"] = "Tavoletta di pietra (Stanza del boss finale)",
    ["Drop inside Ruins of Lordaeron"] = "Bottino dentro Ruins of Lordaeron",
    ["Captain Truman (Inside Ruins of Lordaeron)"] = "Captain Truman (Dentro Ruins of Lordaeron)",
    ["Inside The Deadmines (Forever)"] = "Dentro The Deadmines (Forever)",
    ["Interactable crest inside dungeon"] = "Stemma interagibile dentro l'istanza",

    ["Andrew Brownell (Outside RFD)"] = "Andrew Brownell (Fuori da RFD)",
    ["Argent Guard Thaelrid (Inside BFD)"] = "Argent Guard Thaelrid (Dentro BFD)",
    ["Belnistrasz (Inside RFD)"] = "Belnistrasz (Dentro RFD)",
    ["Heralath Fallowbrook (Inside RFK)"] = "Heralath Fallowbrook (Dentro RFK)",
    ["Willix the Importer (Inside RFK)"] = "Willix the Importer (Dentro RFK)",
    ["Kernobee (Inside Gnomeregan)"] = "Kernobee (Dentro Gnomeregan)",
    ["Marshal Windsor (Inside BRD)"] = "Marshal Windsor (Dentro BRD)",
    ["Awbee (Inside UBRS)"] = "Awbee (Dentro UBRS)",
    ["Willow (Inside Maraudon Purple)"] = "Willow (Dentro Maraudon Viola)",
    ["Kandrostrasz (Inside AQ40 - Tier 2.5)"] = "Kandrostrasz (Dentro AQ40 - Tier 2.5)",
    ["Ebru (Above Wailing Caverns)"] = "Ebru (Sopra le Wailing Caverns)",
    ["Nalpak (Above Wailing Caverns)"] = "Nalpak (Sopra le Wailing Caverns)",

    -- Drops and turn-ins
    ["Drop: Mutanus -> Falla Sagewind (Ratchet)"] = "Bottino: Mutanus -> Falla Sagewind (Ratchet)",
    ["Drop: Edwin VanCleef -> Baros Alexston (Stormwind)"] = "Bottino: Edwin VanCleef -> Baros Alexston (Stormwind)",
    ["Drop: C'Thun -> Baristolth (Cenarion Hold)"] = "Bottino: C'Thun -> Baristolth (Cenarion Hold)",
    ["Abominable Head drop -> Master Apothecary Faranell"] = "Bottino Testa Abominevole -> Master Apothecary Faranell",
    ["Strange Water Globe drop -> Je'neu Sancrea"] = "Bottino Globo d'Acqua Insolito -> Je'neu Sancrea",
    ["Shattered Necklace drop inside Uldaman"] = "Bottino Collana Infranta dentro Uldaman",
    ["Small Scroll drop (Tuten'kash) -> Varimathras"] = "Bottino Piccola Pergamena (Tuten'kash) -> Varimathras",
    ["Scarshield Quartermaster drop (BWL Attunement)"] = "Bottino Scarshield Quartermaster (Sintonizzazione BWL)",
    ["Scarshield Quartermaster (BWL Attunement)"] = "Scarshield Quartermaster (Sintonizzazione BWL)",

    -- Keys and Attunements
    ["Archmage Angela Dosantos (Light's Hope - Attunement)"] = "Archmage Angela Dosantos (Light's Hope - Sintonizzazione)",
    ["Marshal Windsor (A) / Rexxar (H) - Onyxia Attunement"] = "Marshal Windsor (A) / Rexxar (H) - Sintonizzazione Onyxia",
    ["Ashlam Valorforge (A) / Derrington (H) - Scholo Key"] = "Ashlam Valorforge (A) / Derrington (H) - Chiave Scholomance",
    ["Azj'Tordin (Feathermoon / Mojache - Crescent Key)"] = "Azj'Tordin (Feathermoon / Mojache - Chiave Mezzaluna)",
    ["Cavindra (Maraudon Entrance - Scepter Key)"] = "Cavindra (Ingresso Maraudon - Chiave dello Scettro)",
    ["Franclorn Forgewright (Ghost at BRD - Shadowforge Key)"] = "Franclorn Forgewright (Fantasma a BRD - Chiave Shadowforge)",
    ["Vaelan (LBRS Balcony - UBRS Key)"] = "Vaelan (Balconata LBRS - Sigillo/Chiave UBRS)",

    -- Post-boss / Locations / Classes
    ["The Discs of Norgannon (After Archaedas)"] = "I Dischi di Norgannon (Dopo Archaedas)",
    ["Zaetar's Spirit (After Princess Theradras)"] = "Zaetar's Spirit (Dopo Princess Theradras)",
    ["Blood-Stained Letter (Graveyard area)"] = "Lettera Macchiata di Sangue (Zona Cimitero)",
    ["Captain Kromcrush (Dire Maul North - Tribute)"] = "Captain Kromcrush (Dire Maul North - Corsa del Tributo)",
    ["Cenarion Hold Scarab / Idol turn-ins"] = "Consegna Scarabei / Idoli a Cenarion Hold",
    ["Doan Karhan (The Barrens, Warlock)"] = "Doan Karhan (The Barrens, Stregone)",
    ["Jordan Stilwell (Dun Morogh, Paladin)"] = "Jordan Stilwell (Dun Morogh, Paladino)",
    ["Grime-Encrusted Objects inside Gnomeregan"] = "Oggetti Incrostati dentro Gnomeregan",
    ["Master Craftsman Omarion (Military Quarter)"] = "Master Craftsman Omarion (Ala Militare)",
    ["Nat Pagle (Dustwallow Marsh - Summon Gahz'ranka)"] = "Nat Pagle (Dustwallow Marsh - Evoca Gahz'ranka)",
    ["Loremaster Dibbs (Southshore chain)"] = "Loremaster Dibbs (Serie di missioni a Southshore)",
    ["Head of Nefarian -> Bolvar (A) / Thrall (H)"] = "Testa di Nefarian -> Bolvar (A) / Thrall (H)",
    ["Head of Onyxia -> Bolvar Fordragon (Stormwind)"] = "Testa di Onyxia -> Bolvar Fordragon (Stormwind)",
    ["Head of Onyxia -> Thrall (Orgrimmar)"] = "Testa di Onyxia -> Thrall (Orgrimmar)",
    ["Duke Hydraxis (Azshara - Aqual Quintessence)"] = "Duke Hydraxis (Azshara - Quintessenza dell'Acqua)",
    ["Lokhtos Darkbargainer (BRD - Sulfuron Hammer)"] = "Lokhtos Darkbargainer (BRD - Martello di Sulfuron)",
    ["Essence of Eranikus -> Itharius (Swamp of Sorrows)"] = "Essenza di Eranikus -> Itharius (Swamp of Sorrows)",
    ["Warden Haro (AQ40 Regalia)"] = "Warden Haro (Insegne AQ40)",
    ["Windcaller Yessendra (AQ40 Armaments)"] = "Windcaller Yessendra (Armamenti AQ40)",

    -- Prereqs
    ["Map drop at Ironband's Compound"] = "Mappa droppata a Ironband's Compound",
    ["Onyxia Attunement"] = "Sintonizzazione Onyxia",
    ["BWL Attunement"] = "Sintonizzazione BWL",
    ["Southshore chain"] = "Serie di missioni a Southshore",
}

function FP:LocalizeQuestInstruction(str, targetLocale)
    if not str or str == "" then return str end
    local isIt = false
    if targetLocale then
        isIt = (targetLocale == "itIT")
    elseif UseItalian then
        isIt = UseItalian()
    elseif FP.GetEffectiveLocale then
        isIt = (FP:GetEffectiveLocale() == "itIT")
    end

    if not isIt then
        return str
    end

    if QUEST_INSTRUCTIONS_IT[str] then
        return QUEST_INSTRUCTIONS_IT[str]
    end

    -- Dynamic fallback substitutions for directions / locations
    local s = str
    s = s:gsub("%(Above (.-) entrance%)", "(Sopra l'ingresso di %1)")
    s = s:gsub("%(Outside (.-) entrance%)", "(Fuori dall'ingresso di %1)")
    s = s:gsub("%(Inside (.-)%)", "(Dentro %1)")
    s = s:gsub("%(Outside (.-)%)", "(Fuori da %1)")
    s = s:gsub("%(Above (.-)%)", "(Sopra %1)")
    s = s:gsub("%(After (.-)%)", "(Dopo %1)")
    s = s:gsub("%((.-) hillside%)", "(Lungo la collina di %1)")
    s = s:gsub("Final boss room", "Stanza del boss finale")
    s = s:gsub("Drop inside (.-)", "Bottino dentro %1")
    s = s:gsub("drop at (.-)", "droppato a %1")
    s = s:gsub("Map drop at (.-)", "Mappa droppata a %1")
    s = s:gsub("%(Paladin%)", "(Paladino)")
    s = s:gsub("%(Warlock%)", "(Stregone)")
    return s
end

local CURATED_DUNGEON_QUESTS = {
    -- Classic Dungeons (1-60)
    [389] = { -- Ragefire Chasm
        Q("Hidden Enemies", 12, "H", "Thrall (Orgrimmar)"),
        Q("Testing an Enemy's Strength", 15, "H", "Rahauro (Thunder Bluff)"),
        Q("Searching for the Lost Satchel", 16, "H", "Rahauro (Thunder Bluff)"),
        Q("Slaying the Beast", 16, "H", "Neeru Fireblade (Orgrimmar)"),
        Q("The Power to Destroy...", 16, "H", "Varimathras (Undercity)"),
    },
    [43] = { -- Wailing Caverns
        Q("Deviate Hides", 17, "B", "Nalpak (Above Wailing Caverns)"),
        Q("Deviate Eradication", 21, "B", "Ebru (Above Wailing Caverns)"),
        Q("Smart Drinks", 18, "B", "Mebok Mizzyrix (Ratchet)"),
        Q("Trouble at the Docks", 18, "B", "Crane Operator Bigglefuzz (Ratchet)"),
        Q("Serpentbloom", 18, "H", "Apothecary Zamah (Thunder Bluff)"),
        Q("Leaders of the Fang", 22, "H", "Nara Wildmane (Thunder Bluff)"),
        Q("The Glowing Shard", 22, "B", "Drop: Mutanus -> Falla Sagewind (Ratchet)"),
    },
    [36] = { -- The Deadmines
        Q("Red Silk Bandanas", 17, "A", "Scout Riell (Sentinel Hill, Westfall)"),
        Q("Collecting Memories", 18, "A", "Wilder Thistlenettle (Stormwind)"),
        Q("Destruction in Deadmines", 19, "A", "Inside The Deadmines (Forever)"),
        Q("Oh Brother...", 20, "A", "Wilder Thistlenettle (Stormwind)"),
        Q("Underground Assault", 20, "A", "Shoni the Shilent (Stormwind)"),
        Q("The Defias Brotherhood", 22, "A", "Gryan Stoutmantle (Sentinel Hill)"),
        Q("The Unsent Letter", 22, "A", "Drop: Edwin VanCleef -> Baros Alexston (Stormwind)"),
    },
    [33] = { -- Shadowfang Keep
        Q("Arugal Must Die", 24, "H", "Dalar Dawnweaver (The Sepulcher)"),
        Q("Deathstalkers in Shadowfang", 25, "H", "High Executor Hadrec (The Sepulcher)"),
        Q("The Book of Ur", 26, "H", "Keeper Bel'dugur (Undercity)"),
        Q("The Test of Righteousness", 24, "A", "Jordan Stilwell (Dun Morogh, Paladin)"),
        Q("The Orb of Soran'ruk", 25, "B", "Doan Karhan (The Barrens, Warlock)"),
    },
    [48] = { -- Blackfathom Deeps
        Q("Researching the Corruption", 24, "A", "Gershala Nightwhisper (Auberdine)"),
        Q("In Search of Thaelrid", 24, "A", "Argent Guard Thaelrid (Darnassus)"),
        Q("Knowledge in the Deeps", 24, "A", "Gerrig Bonegrip (Ironforge)"),
        Q("Twilight Falls", 25, "A", "Argent Guard Manados (Darnassus)"),
        Q("Blackfathom Villainy", 27, "B", "Argent Guard Thaelrid (Inside BFD)"),
        Q("Allegiance to the Old Gods", 26, "H", "Je'neu Sancrea (Zoram'gar Outpost)"),
        Q("Amongst the Ruins", 27, "H", "Je'neu Sancrea (Zoram'gar Outpost)"),
        Q("Baron Aquanis", 27, "H", "Strange Water Globe drop -> Je'neu Sancrea"),
    },
    [34] = { -- The Stockade
        Q("What Comes Around...", 25, "A", "Guard Berton (Lakeshire)"),
        Q("Crime and Punishment", 26, "A", "Councilman Millstipe (Darkshire)"),
        Q("Quell The Uprising", 26, "A", "Warden Thelwater (Stormwind)"),
        Q("The Color of Blood", 26, "A", "Nikova Raskol (Stormwind)"),
        Q("The Fury Runs Deep", 27, "A", "Motley Garmason (Wetlands)", "The Dark Iron War"),
        Q("Bazil Thredd", 29, "A", "Warden Thelwater (Stormwind)", "An Audience with the King"),
    },
    [90] = { -- Gnomeregan
        Q("Save Techbot's Brain!", 26, "A", "Tinkmaster Overspark (Ironforge)"),
        Q("Gnogaine", 29, "B", "Ozzie Togglevolt (Kharanos)"),
        Q("Data Rescue", 30, "A", "Master Mechanic Castpipe (Ironforge)"),
        Q("Essential Artificials", 30, "A", "Klockmort Spannerspan (Ironforge)"),
        Q("Gyrodrillmatic Excavationators", 30, "A", "Shoni the Shilent (Stormwind)"),
        Q("A Fine Mess", 30, "B", "Kernobee (Inside Gnomeregan)"),
        Q("The Sparklematic 5200!", 30, "B", "Grime-Encrusted Objects inside Gnomeregan"),
        Q("The Only Cure is More Green Glow", 30, "B", "Ozzie Togglevolt (Kharanos)"),
        Q("The Grand Betrayal", 35, "A", "High Tinker Mekkatorque (Ironforge)"),
        Q("Chief Engineer Scooty", 30, "H", "Sovik (Orgrimmar) -> Booty Bay"),
        Q("Rig Wars", 35, "H", "Nogg (Orgrimmar)"),
    },
    [47] = { -- Razorfen Kraul
        Q("Blueleaf Tubers", 26, "B", "Mebok Mizzyrix (Ratchet)"),
        Q("Mortality Wanes", 30, "B", "Heralath Fallowbrook (Inside RFK)"),
        Q("Willix the Importer", 30, "B", "Willix the Importer (Inside RFK)"),
        Q("Going, Going, Guano!", 33, "H", "Master Apothecary Faranell (Undercity)"),
        Q("A Vengeful Fate", 34, "H", "Auld Stonespire (Thunder Bluff)"),
        Q("Crone of the Kraul", 34, "B", "Falfindel Waywarder (Thalanaar)"),
    },
    [189] = { -- Scarlet Monastery
        Q("Vorrel's Revenge", 33, "H", "Vorrel Sengutz (SM Graveyard)"),
        Q("Hearts of Zeal", 33, "H", "Master Apothecary Faranell (Undercity)"),
        Q("Test of Lore", 36, "H", "Dorn Plainstalker (Thousand Needles)"),
        Q("Compendium of the Fallen", 38, "H", "Sage Truthseeker (Thunder Bluff)"),
        Q("Mythology of the Titans", 38, "A", "Librarian Mae Paledust (Ironforge)"),
        Q("In the Name of the Light", 40, "A", "Raleigh the Devout (Southshore)"),
        Q("Into The Scarlet Monastery", 42, "H", "Varimathras (Undercity)"),
    },
    [129] = { -- Razorfen Downs
        Q("A Host of Evil", 35, "H", "Andrew Brownell (Outside RFD)"),
        Q("An Unholy Alliance", 36, "H", "Small Scroll drop (Tuten'kash) -> Varimathras"),
        Q("Extinguishing the Idol", 37, "B", "Belnistrasz (Inside RFD)"),
        Q("Bring the End", 42, "H", "Andrew Brownell (Outside RFD)"),
        Q("Bring the Light", 42, "A", "Archbishop Benedictus (Stormwind)"),
    },
    [70] = { -- Uldaman
        Q("Power Stones", 36, "B", "Rigglefuzz (Badlands)"),
        Q("Solution to Doom", 40, "B", "Theldurin the Lost (Badlands)"),
        Q("The Shattered Necklace", 41, "B", "Shattered Necklace drop inside Uldaman"),
        Q("Uldaman Reagent Run", 42, "B", "Ghak Healtouch (A) / Jarkal Mossmeld (H)"),
        Q("Reclaimed Treasures", 43, "A", "Krom Stoutarm (Ironforge)"),
        Q("The Lost Tablets of Will", 45, "A", "Advisor Belgrum (Ironforge)"),
        Q("The Platinum Discs", 47, "B", "The Discs of Norgannon (After Archaedas)"),
    },
    [209] = { -- Zul'Farrak
        Q("Scarab Shells", 45, "B", "Tran'rek (Gadgetzan)"),
        Q("Troll Temper", 45, "B", "Trenton Lighthammer (Gadgetzan)"),
        Q("Tiara of the Deep", 46, "B", "Tabetha (Dustwallow Marsh)"),
        Q("Gahz'rilla", 46, "B", "Wizzle Brassbolts (Shimmering Flats)"),
        Q("Divino-matic Rod", 47, "B", "Chief Engineer Bilgewhizzle (Gadgetzan)"),
        Q("Nekrum's Medallion", 47, "B", "Gryphon Master Talonaxe (The Hinterlands)", "The Spider God"),
        Q("The Prophecy of Mosh'aru", 47, "B", "Yeh'kinya (Steamwheedle Port)"),
    },
    [349] = { -- Maraudon
        Q("Vyletongue Corruption", 47, "B", "Talendria (A) / Vark (H)"),
        Q("Twisted Evils", 47, "B", "Willow (Inside Maraudon Purple)"),
        Q("Shadowshard Fragments", 47, "B", "Archmage Tervosh (A) / Uthel'nay (H)"),
        Q("Legends of Maraudon", 49, "B", "Cavindra (Maraudon Entrance - Scepter Key)"),
        Q("Corruption of Earth and Seed", 51, "B", "Keeper Marandis (A) / Selendra (H)"),
        Q("Seed of Life", 51, "B", "Zaetar's Spirit (After Princess Theradras)"),
    },
    [109] = { -- Temple of Atal'Hakkar
        Q("Into The Temple of Atal'Hakkar", 50, "A", "Brohann Caskbelly (Stormwind)"),
        Q("The Temple of Atal'Hakkar", 50, "H", "Fel'zerul (Stonard)"),
        Q("Into the Depths", 51, "B", "Marvon Rivetseeker (Tanaris)", "The Stone Circle"),
        Q("Secret of the Circle", 51, "B", "Marvon Rivetseeker (Tanaris)", "The Stone Circle"),
        Q("Jammal'an the Prophet", 53, "B", "Atal'ai Exile (The Hinterlands)"),
        Q("The God Hakkar", 53, "B", "Yeh'kinya (Steamwheedle Port)", "Screecher Spirits"),
        Q("Eranikus, Tyrant of the Dream", 55, "B", "Essence of Eranikus -> Itharius (Swamp of Sorrows)"),
    },
    [230] = { -- Blackrock Depths
        Q("Commander Gor'shak", 52, "H", "Warlord Goretooth (Kargath)"),
        Q("Dark Iron Legacy", 52, "B", "Franclorn Forgewright (Ghost at BRD - Shadowforge Key)"),
        Q("Ribbly Screwspigot", 53, "B", "Yuka Screwspigot (Burning Steppes)"),
        Q("The Love Potion", 54, "B", "Mistress Nagmara (Grim Guzzler)"),
        Q("Disharmony of Fire", 56, "H", "Thunderheart (Kargath)"),
        Q("Incendius!", 56, "A", "Jalinda Sprig (Morgan's Vigil)"),
        Q("A Taste of Flame", 58, "B", "Cyrus Therepentous (Burning Steppes)"),
        Q("Jail Break!", 58, "A", "Marshal Windsor (Inside BRD)", "Onyxia Attunement"),
        Q("Kharan Mighthammer", 59, "A", "King Magni Bronzebeard (Ironforge)"),
        Q("The Royal Rescue", 59, "A", "King Magni Bronzebeard (Ironforge)"),
        Q("Attunement to the Core", 60, "B", "Lothos Riftwaker (Blackrock Mountain)"),
    },
    [229] = { -- Blackrock Spire
        Q("Put Her Down", 59, "A", "Helendis Riverhorn (Morgan's Vigil)"),
        Q("Mother's Milk", 59, "B", "Ragged John (Burning Steppes)"),
        Q("The Matron Protectorate", 60, "B", "Awbee (Inside UBRS)"),
        Q("Warlord's Command", 60, "H", "Warlord Goretooth (Kargath)"),
        Q("For The Horde!", 60, "H", "Thrall (Orgrimmar)", "Onyxia Attunement"),
        Q("Seal of Ascension", 60, "B", "Vaelan (LBRS Balcony - UBRS Key)"),
        Q("Maxwell's Mission", 60, "B", "Marshal Maxwell (Morgan's Vigil)"),
        Q("General Drakkisath's Demise", 60, "B", "Marshal Maxwell (Morgan's Vigil)"),
        Q("Blackhand's Command", 60, "B", "Scarshield Quartermaster drop (BWL Attunement)"),
    },
    [429] = { -- Dire Maul
        Q("Lethtendris's Web", 57, "B", "Latronicus Moonspear (Feathermoon / Mojache)"),
        Q("Pusillin and the Elder Azj'Tordin", 58, "B", "Azj'Tordin (Feathermoon / Mojache - Crescent Key)"),
        Q("Elven Legends", 60, "B", "Scholar Runethorn (Feralas)"),
        Q("Shards of the Felvine", 60, "B", "Rabine Saturna (Moonglade)"),
        Q("The Madness Within", 60, "B", "Shen'dralar Ancient (Dire Maul West)"),
        Q("Free Knot!", 60, "B", "Knot Thimblejack (Dire Maul North)"),
        Q("Unfinished Gordok Business", 60, "B", "Captain Kromcrush (Dire Maul North - Tribute)"),
    },
    [329] = { -- Stratholme
        Q("The Flesh Does Not Lie", 60, "B", "Betina Bigglezink (Light's Hope Chapel)"),
        Q("The Active Agent", 60, "B", "Betina Bigglezink (Light's Hope Chapel)"),
        Q("Houses of the Holy", 60, "B", "Leonid Barthalomew (Light's Hope Chapel)"),
        Q("The Archivist", 60, "B", "Duke Nicholas Zverenhoff (Light's Hope Chapel)"),
        Q("Above and Beyond", 60, "B", "Duke Nicholas Zverenhoff (Baron Rivendare)"),
        Q("The Great Fras Siabi", 60, "B", "Smokey LaRue (Light's Hope Chapel)"),
        Q("The Restless Souls", 60, "B", "Caretaker Alen (Light's Hope Chapel)"),
        Q("Of Love and Family", 60, "B", "Tirion Fordring (Eastern Plaguelands)"),
    },
    [289] = { -- Scholomance
        Q("Skeleton Key", 60, "B", "Ashlam Valorforge (A) / Derrington (H) - Scholo Key"),
        Q("Plagued Hatchlings", 60, "B", "Betina Bigglezink (Light's Hope Chapel)"),
        Q("Dawn's Gambit", 60, "B", "Betina Bigglezink (Light's Hope Chapel)"),
        Q("Barov Family Fortune", 60, "B", "Weldon Barov (A) / Alexi Barov (H)"),
        Q("Doctor Theolen Krastinov, the Butcher", 60, "B", "Eva Sarkoff (Caer Darrow)"),
        Q("Krastinov's Bag of Horrors", 60, "B", "Eva Sarkoff (Caer Darrow)"),
        Q("Kirtonos the Herald", 60, "B", "Eva Sarkoff (Caer Darrow)"),
        Q("The Lich, Ras Frostwhisper", 60, "B", "Magistrate Marduke (Caer Darrow)"),
    },
    -- Classic Raids (60)
    [249] = { -- Onyxia's Lair
        Q("Drakefire Amulet", 60, "B", "Marshal Windsor (A) / Rexxar (H) - Onyxia Attunement"),
        Q("Victory for the Alliance", 60, "A", "Head of Onyxia -> Bolvar Fordragon (Stormwind)"),
        Q("For All To See", 60, "H", "Head of Onyxia -> Thrall (Orgrimmar)"),
    },
    [309] = { -- Zul'Gurub
        Q("The Heart of Hakkar", 60, "B", "Molthor (Yojamba Isle)"),
        Q("A Collection of Heads", 60, "B", "Exzhal (Yojamba Isle)"),
        Q("Zanza's Potent Potables", 60, "B", "Rin'wosho the Trader (Yojamba Isle)"),
        Q("The Fall of Jin'do", 60, "B", "Molthor (Yojamba Isle)"),
        Q("Nat's Measuring Tape", 60, "B", "Nat Pagle (Dustwallow Marsh - Summon Gahz'ranka)"),
    },
    [409] = { -- Molten Core
        Q("Attunement to the Core", 60, "B", "Lothos Riftwaker (Blackrock Mountain)"),
        Q("The Molten Core", 60, "B", "Duke Hydraxis (Azshara - Aqual Quintessence)"),
        Q("Hands of the Enemy", 60, "B", "Duke Hydraxis (Azshara)"),
        Q("A Hero's Reward", 60, "B", "Duke Hydraxis (Azshara - Ragnaros)"),
        Q("A Binding Contract", 60, "B", "Lokhtos Darkbargainer (BRD - Sulfuron Hammer)"),
        Q("Thunderaan the Windseeker", 60, "B", "Highlord Demitrian (Silithus - Thunderfury)"),
    },
    [469] = { -- Blackwing Lair
        Q("Blackhand's Command", 60, "B", "Scarshield Quartermaster (BWL Attunement)"),
        Q("The Only Prescription", 60, "B", "Master Elemental Shaper Krixix (Elementium)"),
        Q("The Lord of Blackrock", 60, "B", "Head of Nefarian -> Bolvar (A) / Thrall (H)"),
    },
    [509] = { -- Ruins of Ahn'Qiraj
        Q("Secrets of the Qiraji", 60, "B", "Cenarion Hold Scarab / Idol turn-ins"),
        Q("The Fall of Ossirian", 60, "B", "Commander Mar'alith (Cenarion Hold)"),
    },
    [531] = { -- Temple of Ahn'Qiraj
        Q("Imperial Qiraji Armaments", 60, "B", "Windcaller Yessendra (AQ40 Armaments)"),
        Q("Imperial Qiraji Regalia", 60, "B", "Warden Haro (AQ40 Regalia)"),
        Q("Mortal Champions", 60, "B", "Kandrostrasz (Inside AQ40 - Tier 2.5)"),
        Q("The Eye of C'Thun", 60, "B", "Drop: C'Thun -> Baristolth (Cenarion Hold)"),
        Q("The Savior of Kalimdor", 60, "B", "Baristolth of the Shifting Sands (Cenarion Hold)"),
    },
    [533] = { -- Naxxramas
        Q("The Dread Citadel - Naxxramas", 60, "B", "Archmage Angela Dosantos (Light's Hope - Attunement)"),
        Q("Echoes of War", 60, "B", "Commander Eligor Dawnbringer (Light's Hope Chapel)"),
        Q("Omarion's Handbook", 60, "B", "Master Craftsman Omarion (Military Quarter)"),
        Q("The Fate of Ramaladni", 60, "B", "Commander Eligor Dawnbringer (Light's Hope Chapel)"),
        Q("The Fall of Kel'Thuzad", 60, "B", "Father Inigo Montoy (Light's Hope Chapel)"),
    },
    -- WoW Forever Verified Custom Dungeons
    ["FOREVER_HALL_OF_THANES"] = {
        Q("The Restless Dead", 15, "A", "Afadra Dunwall (Above Old Ironforge entrance)"),
        Q("Important Heirlooms", 15, "A", "Thom Filch (Outside Old Ironforge entrance)"),
        Q("Old Ironforge Incursion", 16, "A", "Earth Seer Farsen (Dun Morogh hillside)", "Map drop at Ironband's Compound"),
        Q("An Ancient Grudge", 16, "A", "Ghostly Attendant (Inside West Wing)"),
        Q("The Treaty of Understanding", 17, "A", "Stone tablet (Final boss room)"),
    },
    ["FOREVER_RUINS_OF_LORDAERON"] = {
        Q("Crest of Lordaeron", 17, "B", "Interactable crest inside dungeon"),
        Q("A Frightened Request", 17, "H", "Tabitha Heartweaver (The Sepulcher)"),
        Q("The Wrath of Rath'mael", 18, "H", "Deathguard Kristof (Brill)", "Rear Guard Patrol"),
        Q("The New Plague", 18, "H", "Apothecary Renferrel / Theodore Griffs"),
        Q("Light's Justice", 18, "H", "Morbin Lightbane (Undercity)"),
        Q("Unending Torment", 19, "H", "Abominable Head drop -> Master Apothecary Faranell"),
        Q("Bloodied Insignia", 17, "A", "Drop inside Ruins of Lordaeron"),
        Q("Abominable Creatures", 18, "A", "Captain Truman (Inside Ruins of Lordaeron)"),
        Q("Remember That I Love You", 18, "A", "Blood-Stained Letter (Graveyard area)"),
    },
    ["FOREVER_EXCAVATION_SITE"] = {
        Q("Changing Tastes", 26, "H", "Borstan (Orgrimmar 57.3, 53.3)"),
        Q("Open the Maw", 27, "H", "Deathstalker Agent (Wetlands 51.4, 59.2)", "Dragonmaw Rumors"),
    },
    ["FOREVER_CITY_OF_DALARAN"] = {
        Q("A Green Sample", 30, "A", "Shylamiir (Stormwind 31.5, 63.0)"),
        Q("Starving Arcane", 30, "A", "Image of Archmage Modera (Alterac / Lordamere)"),
        Q("Power Overwhelming", 31, "A", "High Sorcerer Andromath (Stormwind 48.9, 87.8)"),
        Q("Heart of Disruption", 32, "B", "Image of Archmage Modera", "An Alarming Request"),
        Q("Prison Break In", 30, "H", "Magus Wordeen Voidglare (Tarren Mill)"),
        Q("Key to the City", 30, "H", "Magus Wordeen Voidglare (Tarren Mill)"),
        Q("Stone Tokens", 30, "H", "Tarren Mill (Hillsbrad Foothills)"),
        Q("Dalaran Patrols", 30, "H", "Tarren Mill (Hillsbrad Foothills)"),
        Q("Bracers of Binding", 31, "H", "Tarren Mill (Hillsbrad Foothills)"),
        Q("Blood in the Streets", 31, "H", "Tarren Mill (Hillsbrad Foothills)"),
        Q("Source of Power", 31, "H", "Tarren Mill (Hillsbrad Foothills)"),
        Q("The Grave Knight", 32, "H", "Tarren Mill (Hillsbrad Foothills)"),
    },
    ["FOREVER_DROWNED_CITY"] = {
        Q("Shady Saltseers", 37, "B", "Krazek (Booty Bay)"),
        Q("Ancient Gurubashi Secrets", 38, "B", "Archmage Timear"),
        Q("The Saltseer Captain", 38, "B", "Krazek (Booty Bay)"),
        Q("Enemies in the Water", 37, "H", "Kin'weelay (Grom'gol Base Camp)"),
        Q("Mazu'kon's Idol", 38, "H", "Grom'gol Base Camp"),
        Q("Brother Nimetz", 37, "A", "Rebel Camp (Stranglethorn Vale)"),
        Q("An Acquaintance of Mine", 38, "A", "Loremaster Dibbs (Southshore chain)"),
    },
}

-------------------------------------------------------------------------------
-- Query, Level Filter & Gear Search Helpers
-------------------------------------------------------------------------------
local function NormalizeInstStr(s)
    if not IsSafeStr(s) then return "" end
    local low = string.lower(s)
    low = low:gsub("[:'`%-_,%.%(%)]+", " ")
    low = low:gsub("%s+", " ")
    return low:match("^%s*(.-)%s*$") or ""
end

local CURATED_ITEM_META = {}

local function RegCuratedItem(name, itemID, info)
    local key = NormalizeInstStr(name)
    if key == "" then return end
    local rec = CURATED_ITEM_META[key] or {}
    if IsSafeNum(itemID) and itemID > 0 then
        rec.itemID = itemID
    end
    if type(info) == "table" then
        for k, v in pairs(info) do
            rec[k] = v
        end
    end
    CURATED_ITEM_META[key] = rec
end

-- Verified Classic Dungeon & Raid Item IDs (resolved live via client/server item DB)
local function InitCuratedItemMeta()
    local ids = {
        -- Ragefire Chasm [389]
        { "Cursed Felblade", 14145 }, { "Crystalline Cuffs", 14148 }, { "Subterranean Cape", 14149 },
        { "Robe of Evocation", 14150 }, { "Chanting Blade", 14151 },
        -- Wailing Caverns [43]
        { "Belt of the Fang", 10412 }, { "Leggings of the Fang", 10410 }, { "Armor of the Fang", 6473 },
        { "Gloves of the Fang", 10413 }, { "Venomstrike", 6469 }, { "Living Root", 6631 },
        -- The Deadmines [36]
        { "Rhahk'Zor's Hammer", 5187 }, { "Cruel Barb", 5191 }, { "Thief's Blade", 5192 },
        { "Cape of the Brotherhood", 5193 }, { "Smite's Reaver", 5196 }, { "Cookie's Stirring Rod", 5198 },
        { "Impaling Harpoon", 5200 }, { "Smite's Mighty Hammer", 7230 }, { "Blackened Defias Armor", 10399 },
        { "Buzzer Blade", 2169 },
        -- Shadowfang Keep [33]
        { "Robes of Arugal", 6324 }, { "Meteor Shard", 6220 }, { "Odo's Ley Staff", 6318 },
        { "Feet of the Lynx", 1121 }, { "Commander's Crest", 6320 }, { "Arced War Axe", 3191 },
        -- Blackfathom Deeps [48]
        { "Strike of the Hydra", 6909 }, { "Rod of the Sleepwalker", 1155 },
        -- Gnomeregan [90]
        { "Electrocutioner Leg", 9446 }, { "Thermaplugg's Left Arm", 9459 },
        { "Hydrocane", 9452 }, { "Triprunner Dungarees", 9624 },
        -- Razorfen Kraul [47]
        { "Corpsemaker", 6687 },
        -- Scarlet Monastery [189]
        { "Ravager", 7717 }, { "Herod's Shoulder", 7718 }, { "Raging Berserker's Helm", 7719 },
        { "Whitemane's Chapeau", 7720 }, { "Triune Amulet", 7722 }, { "Illusionary Rod", 7713 },
        { "Hypnotic Blade", 7715 },
        -- Razorfen Downs [129]
        { "Coldrage Dagger", 10761 }, { "Robes of the Lich", 10762 },
        { "Deathchill Armor", 10764 }, { "Vanquisher's Sword", 10823 },
        -- Uldaman [70]
        { "Pendulum of Doom", 9425 }, { "Stoneslayer", 9418 }, { "Grimlok's Charge", 9416 },
        { "Archaedic Stone", 11118 }, { "The Shoveler", 9391 }, { "Ironshod Bludgeon", 9408 },
        -- Zul'Farrak [209]
        { "Jang'thraze the Protector", 9380 }, { "Sang'thraze the Deflector", 9379 },
        { "Sul'thraze the Lasher", 9372 }, { "Gahz'rilla Fang", 9467 }, { "Bad Mojo Mask", 9470 },
        -- Maraudon [349]
        { "Blackstone Ring", 17713 }, { "Blade of Eternal Darkness", 17780 }, { "Princess Theradras' Scepter", 17766 },
        -- Temple of Atal'Hakkar [109]
        { "Dragon's Call", 10847 },
        -- Blackrock Depths [230]
        { "Ironfoe", 11684 }, { "Hand of Justice", 11815 }, { "Savage Gladiator Chain", 11726 },
        -- Blackrock Spire [229]
        { "Dal'Rend's Sacred Charge", 12940 }, { "Dal'Rend's Tribal Guardian", 12939 },
        { "Felstriker", 12590 }, { "Briarwood Reed", 12930 }, { "Blackcrow", 12651 },
        -- Stratholme [329] & Scholomance [289]
        { "Cape of the Black Baron", 13340 }, { "Runeblade of Baron Rivendare", 13505 },
        { "Deathcharger's Reins", 13335 }, { "Righteous Orb", 12811 },
        { "Alanna's Embrace", 13314 }, { "Headmaster's Charge", 13937 },
        -- Classic Raids (60)
        { "Jin'do's Hexxer", 19890 }, { "Swift Zulian Tiger", 19902 }, { "Swift Razzashi Raptor", 19872 },
        { "Perdition's Blade", 18816 }, { "Bonereaver's Edge", 17076 }, { "Azuresong Mageblade", 17103 },
        { "Thunderfury, Blessed Blade of the Windseeker", 19019 }, { "Sulfuras, Hand of Ragnaros", 17182 },
        { "Mish'undare, Circlet of the Mind Flayer", 19375 }, { "Ashkandi, Greatsword of the Brotherhood", 19364 },
        { "Neltharion's Tear", 19379 }, { "Drake Fang Talisman", 19406 }, { "Rejuvenating Gem", 19395 },
        { "Crul'shorukh, Edge of Chaos", 19363 }, { "Lok'amir il Romathis", 19360 },
        { "Chromatic Boots", 19387 }, { "Maladath, Runed Blade of the Black Flight", 19351 },
        { "Dark Edge of Insanity", 21134 }, { "Fetish of the Sand Reaver", 21647 },
        { "Corrupted Ashbringer", 22691 }, { "Wraith Blade", 22807 },
        { "Kiss of the Spider", 22954 }, { "Gressil, Dawn of Ruin", 23054 },
    }
    for _, row in ipairs(ids) do
        RegCuratedItem(row[1], row[2])
    end

    -- Verified WoW Forever custom dungeon drop stats (used when custom items aren't yet in EJ/item cache)
    RegCuratedItem("Kindlegem Girdle", nil, {
        quality = 3, slot = "Waist", armorType = "Mail", reqLvl = 13, armor = 100,
        stats = { "+7 Stamina" },
    })
    RegCuratedItem("Golemguard Chest", nil, {
        quality = 3, slot = "Chest", armorType = "Mail", reqLvl = 13, armor = 178,
        stats = { "+6 Stamina" }, equip = { "+60 Armor" },
    })
    RegCuratedItem("Fang of Magmatus", nil, {
        quality = 3, slot = "Main Hand", armorType = "Dagger", reqLvl = 13,
        stats = { "+4 Intellect" }, equip = { "Increases damage and healing done by magical spells and effects." },
    })
    RegCuratedItem("Grip of Fear", nil, {
        quality = 3, slot = "Hands", armorType = "Mail", reqLvl = 17, armor = 119,
        stats = { "+6 Strength", "+6 Intellect" },
    })
    RegCuratedItem("Rotmender's Leggings", nil, {
        quality = 3, slot = "Legs", armorType = "Cloth", reqLvl = 17, armor = 35,
        stats = { "+5 Stamina" }, equip = { "Restores 4 mana per 5 sec." },
    })
    RegCuratedItem("Vilewalkers", nil, {
        quality = 3, slot = "Feet", armorType = "Mail", reqLvl = 17, armor = 131,
        stats = { "+7 Strength", "+5 Stamina" },
    })
    RegCuratedItem("Supple Bellyskin Leggings", nil, {
        quality = 3, slot = "Legs", armorType = "Leather", reqLvl = 26, armor = 92,
        stats = { "+6 Strength", "+14 Stamina" },
    })
    RegCuratedItem("Saltscale Girdle", nil, {
        quality = 3, slot = "Waist", armorType = "Mail", reqLvl = 26, armor = 124,
        stats = { "+9 Strength", "+9 Intellect" },
    })
    RegCuratedItem("Glinteye Slippers", nil, {
        quality = 3, slot = "Feet", armorType = "Cloth", reqLvl = 26, armor = 33,
        stats = { "+9 Stamina", "+6 Spirit" },
        equip = { "Increases damage and healing done by magical spells and effects by up to 7." },
    })
    RegCuratedItem("Archmagister's Faceted Pendant", nil, {
        quality = 3, slot = "Neck", stats = { "+6 Intellect" },
        equip = { "Increases attack power by 12." },
        use = { "Increases experience gained from Undead by 10% for 5 min." },
    })
    RegCuratedItem("Ponderous Orb", nil, {
        quality = 3, slot = "Held In Off-Hand", stats = { "+2 Intellect", "+8 Spirit" },
        equip = { "Increases healing done by spells and effects by up to 11, and damage done by up to 4." },
    })
    RegCuratedItem("Violet Sorcerer's Mantle", nil, {
        quality = 3, slot = "Shoulder", armorType = "Cloth", armor = 38,
        stats = { "+9 Intellect" }, equip = { "Increases spell penetration by 4." },
    })
end
InitCuratedItemMeta()

local EJ_NAME_ALIASES = {
    [36]  = { "The Deadmines", "Deadmines" },
    [109] = { "Sunken Temple", "Temple of Atal'Hakkar", "The Temple of Atal'Hakkar" },
    [229] = { "Blackrock Spire", "Lower Blackrock Spire", "Upper Blackrock Spire" },
    [189] = { "Scarlet Monastery", "Scarlet Halls" },
    [531] = { "Ahn'Qiraj Temple", "Temple of Ahn'Qiraj", "Ahn'Qiraj" },
    [509] = { "Ruins of Ahn'Qiraj", "Ahn'Qiraj Ruins" },
}

local ejLootCache = {}
local ejScanAttempted = {}

local function SafeCallNum(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if ok and IsSafeNum(v) then return v end
    return nil
end

local function FindEJInstanceForGuide(guide, isRaidHint)
    if not EJ_GetInstanceByIndex then return nil end
    local targets = {}
    if IsSafeStr(guide.name) then
        targets[NormalizeInstStr(guide.name)] = true
    end
    local aliases = EJ_NAME_ALIASES[guide.id]
    if type(aliases) == "table" then
        for _, a in ipairs(aliases) do
            local na = NormalizeInstStr(a)
            if na ~= "" then targets[na] = true end
        end
    end
    if next(targets) == nil then return nil end

    local raidFlags = isRaidHint and { true, false } or { false, true }
    local numTiers = SafeCallNum(EJ_GetNumTiers) or 1
    if numTiers < 1 then numTiers = 1 end

    -- Always scan Tier 1 (Classic) first, then remaining tiers (covers WoW Forever custom tier)
    local tierOrder = { 1 }
    for t = 2, math.min(numTiers, 14) do
        tierOrder[#tierOrder + 1] = t
    end

    for _, tierIdx in ipairs(tierOrder) do
        if EJ_SelectTier then
            pcall(EJ_SelectTier, tierIdx)
        end
        for _, isRaid in ipairs(raidFlags) do
            local idx = 1
            while idx <= 80 do
                local okI, id, name = pcall(EJ_GetInstanceByIndex, idx, isRaid)
                if not okI or not IsSafeNum(id) or id == 0 then break end
                if IsSafeStr(name) and targets[NormalizeInstStr(name)] then
                    return id
                end
                idx = idx + 1
            end
        end
        if not EJ_SelectTier then break end
    end
    return nil
end

local function TryCollectEJInstanceLoot(guide)
    if type(guide) ~= "table" then return nil end
    if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() then
        return nil
    end
    local getLootInfoFn = (C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex) or EJ_GetLootInfoByIndex
    if not (EJ_SelectInstance and EJ_GetEncounterInfoByIndex and EJ_SelectEncounter and EJ_GetNumLoot and getLootInfoFn) then
        return nil
    end
    local cacheKey = tostring(guide.id or guide.name or "")
    if ejLootCache[cacheKey] then
        return ejLootCache[cacheKey]
    end
    if ejScanAttempted[cacheKey] then
        return nil
    end
    ejScanAttempted[cacheKey] = true

    local prevTier = SafeCallNum(EJ_GetCurrentTier)
    local ejInstID = FindEJInstanceForGuide(guide, guide.kind == "raid")
    if not ejInstID then
        if prevTier and EJ_SelectTier then pcall(EJ_SelectTier, prevTier) end
        return nil
    end

    local okSel = pcall(EJ_SelectInstance, ejInstID)
    if not okSel then
        if prevTier and EJ_SelectTier then pcall(EJ_SelectTier, prevTier) end
        return nil
    end

    local byBoss = {}
    local byName = {}
    local encIdx = 1
    while encIdx <= 40 do
        local okE, eName, _, encID = pcall(EJ_GetEncounterInfoByIndex, encIdx, ejInstID)
        if not okE or not IsSafeStr(eName) then break end
        if IsSafeNum(encID) and encID > 0 and pcall(EJ_SelectEncounter, encID) then
            local okNL, numLoot = pcall(EJ_GetNumLoot)
            if okNL and IsSafeNum(numLoot) and numLoot > 0 then
                local items = {}
                local cap = math.min(numLoot, 60)
                for lIdx = 1, cap do
                    local okL, lInfo = pcall(getLootInfoFn, lIdx)
                    if okL and type(lInfo) == "table" and IsSafeStr(lInfo.name) then
                        local itemObj = {
                            name = lInfo.name,
                            slot = IsSafeStr(lInfo.slot) and lInfo.slot or "",
                            armorType = IsSafeStr(lInfo.armorType) and lInfo.armorType or nil,
                            link = IsSafeStr(lInfo.link) and lInfo.link or nil,
                            itemID = IsSafeNum(lInfo.itemID) and lInfo.itemID or nil,
                            icon = lInfo.icon,
                            quality = IsSafeNum(lInfo.itemQuality) and lInfo.itemQuality or (IsSafeNum(lInfo.quality) and lInfo.quality or nil),
                        }
                        if not itemObj.itemID and IsSafeStr(itemObj.link) then
                            itemObj.itemID = tonumber(itemObj.link:match("item:(%d+)"))
                        end
                        items[#items + 1] = itemObj
                        local nKey = NormalizeInstStr(lInfo.name)
                        if nKey ~= "" and not byName[nKey] then
                            byName[nKey] = itemObj
                        end
                    end
                end
                if #items > 0 then
                    byBoss[NormalizeInstStr(eName)] = items
                end
            end
        end
        encIdx = encIdx + 1
    end

    if prevTier and EJ_SelectTier then
        pcall(EJ_SelectTier, prevTier)
    end

    if next(byBoss) ~= nil or next(byName) ~= nil then
        local bundle = { byBoss = byBoss, byName = byName }
        ejLootCache[cacheKey] = bundle
        return bundle
    end
    return nil
end

local function EnrichDropEntry(entry, ejItem)
    if type(entry) ~= "table" or not IsSafeStr(entry.name) then return end
    local key = NormalizeInstStr(entry.name)
    local meta = CURATED_ITEM_META[key]

    if ejItem then
        if IsSafeNum(ejItem.itemID) and not IsSafeNum(entry.itemID) then entry.itemID = ejItem.itemID end
        if IsSafeStr(ejItem.link) and not IsSafeStr(entry.link) then entry.link = ejItem.link end
        if ejItem.icon and not entry.icon then entry.icon = ejItem.icon end
        if IsSafeNum(ejItem.quality) and not IsSafeNum(entry.quality) then entry.quality = ejItem.quality end
        if IsSafeStr(ejItem.slot) and entry.slot == "" then entry.slot = ejItem.slot end
        if IsSafeStr(ejItem.armorType) and not IsSafeStr(entry.armorType) then entry.armorType = ejItem.armorType end
    end

    if meta then
        if IsSafeNum(meta.itemID) and not IsSafeNum(entry.itemID) then entry.itemID = meta.itemID end
        if IsSafeNum(meta.quality) and not IsSafeNum(entry.quality) then entry.quality = meta.quality end
        if IsSafeStr(meta.slot) and entry.slot == "" then entry.slot = meta.slot end
        if IsSafeStr(meta.armorType) and not IsSafeStr(entry.armorType) then entry.armorType = meta.armorType end
        if meta.reqLvl then entry.reqLvl = entry.reqLvl or meta.reqLvl end
        if meta.armor then entry.armor = entry.armor or meta.armor end
        if meta.stats then entry.stats = entry.stats or meta.stats end
        if meta.equip then entry.equip = entry.equip or meta.equip end
        if meta.use then entry.use = entry.use or meta.use end
    end

    local queryTarget = entry.link or entry.itemID or entry.name
    local infoFn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if infoFn and queryTarget then
        local okG, _, iLink, iQual, iLvl, reqLvl, iType, iSub, _, iEquipLoc, iTex = pcall(infoFn, queryTarget)
        if okG and IsSafeStr(iLink) then
            entry.link = iLink
            if not IsSafeNum(entry.itemID) then
                entry.itemID = tonumber(iLink:match("item:(%d+)"))
            end
            if IsSafeNum(iQual) then entry.quality = iQual end
            if IsSafeNum(iLvl) then entry.ilvl = iLvl end
            if IsSafeNum(reqLvl) and reqLvl > 0 then entry.reqLvl = reqLvl end
            if iTex then entry.icon = iTex end
            if IsSafeStr(iSub) and not IsSafeStr(entry.armorType) and (iType == "Armor" or iType == "Weapon") then
                entry.armorType = iSub
            end
            if IsSafeStr(iEquipLoc) and iEquipLoc ~= "" and entry.slot == "" then
                entry.slot = _G[iEquipLoc] or entry.slot
            end
        elseif IsSafeNum(entry.itemID) and C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, entry.itemID)
        end
    end

    if not entry.icon and IsSafeNum(entry.itemID) then
        if C_Item and C_Item.GetItemIconByID then
            local okT, tex = pcall(C_Item.GetItemIconByID, entry.itemID)
            if okT and tex then entry.icon = tex end
        elseif GetItemIcon then
            local okT, tex = pcall(GetItemIcon, entry.itemID)
            if okT and tex then entry.icon = tex end
        end
    end
end

function FP:EnrichBossDrop(entry)
    EnrichDropEntry(entry, nil)
    return entry
end

function FP:GetBossDrops(guide, boss)
    local out = {}
    local seen = {}
    local byKey = {}
    if type(boss) == "table" and type(boss.drops) == "table" then
        for _, entry in ipairs(boss.drops) do
            if type(entry) == "string" and entry ~= "" then
                local iName, iSlot = entry:match("^(.-)%s*%(([^()]+)%)$")
                iName = iName or entry
                local key = NormalizeInstStr(iName)
                if key ~= "" and not seen[key] then
                    seen[key] = true
                    local row = { name = iName, slot = iSlot or "" }
                    byKey[key] = row
                    out[#out + 1] = row
                end
            elseif type(entry) == "table" and IsSafeStr(entry.name) then
                local key = NormalizeInstStr(entry.name)
                if key ~= "" and not seen[key] then
                    seen[key] = true
                    byKey[key] = entry
                    out[#out + 1] = entry
                end
            end
        end
    end

    local ejBundle = guide and TryCollectEJInstanceLoot(guide) or nil
    if type(ejBundle) == "table" then
        local ejList = (type(boss) == "table" and IsSafeStr(boss.name) and ejBundle.byBoss)
            and ejBundle.byBoss[NormalizeInstStr(boss.name)] or nil
        if type(ejList) == "table" then
            for _, item in ipairs(ejList) do
                local key = NormalizeInstStr(item.name)
                if key ~= "" then
                    if not seen[key] then
                        seen[key] = true
                        local row = {
                            name = item.name, slot = item.slot or "", armorType = item.armorType,
                            link = item.link, itemID = item.itemID, icon = item.icon, quality = item.quality,
                        }
                        byKey[key] = row
                        out[#out + 1] = row
                    else
                        EnrichDropEntry(byKey[key], item)
                    end
                end
            end
        end
    end

    for _, row in ipairs(out) do
        local key = NormalizeInstStr(row.name)
        local ejMatch = (type(ejBundle) == "table" and ejBundle.byName) and ejBundle.byName[key] or nil
        EnrichDropEntry(row, ejMatch)
    end
    return out
end

function FP:MatchesLevelFilter(guide, levelFilter)
    if type(guide) ~= "table" then return false end
    if not levelFilter or levelFilter == "" or levelFilter == "all" then
        return true
    end
    if levelFilter == "raid" then
        return guide.kind == "raid"
    end
    if guide.kind == "raid" then
        return false
    end
    local lo, hi = levelFilter:match("^(%d+)%-(%d+)$")
    lo, hi = tonumber(lo), tonumber(hi)
    if lo and hi then
        local gMin = guide.minLvl or 1
        local gMax = guide.maxLvl or 60
        return gMax >= lo and gMin <= hi
    end
    return true
end

function FP:GetBossGuideText(entry, fieldKey)
    if type(entry) ~= "table" then return "" end
    local field = entry[fieldKey]
    if type(field) == "table" then
        if UseItalian() and IsSafeStr(field.it) then
            return field.it
        end
        return (IsSafeStr(field.en) and field.en) or (IsSafeStr(field.it) and field.it) or ""
    elseif IsSafeStr(field) then
        return field
    end
    return ""
end

function FP:GetDungeonDisplayName(guide)
    if type(guide) ~= "table" then return "" end
    if UseItalian() and IsSafeStr(guide.nameIt) then
        return guide.nameIt
    end
    return guide.name or ""
end

function FP:GetDungeonGuide(instanceID, instanceName)
    if (IsSafeNum(instanceID) or IsSafeStr(instanceID)) and self.DUNGEON_GUIDES[instanceID] then
        return self.DUNGEON_GUIDES[instanceID]
    end
    if IsSafeStr(instanceName) and self.DUNGEON_GUIDES[instanceName] then
        return self.DUNGEON_GUIDES[instanceName]
    end
    if IsSafeNum(instanceID) then
        for _, g in pairs(self.DUNGEON_GUIDES) do
            if type(g) == "table" and type(g.mapIDs) == "table" then
                for _, mid in ipairs(g.mapIDs) do
                    if mid == instanceID then
                        return g
                    end
                end
            end
        end
    end
    if IsSafeStr(instanceName) then
        local low = NormalizeInstStr(instanceName)
        if low ~= "" then
            for _, g in pairs(self.DUNGEON_GUIDES) do
                if type(g) == "table" then
                    if NormalizeInstStr(g.name) == low or NormalizeInstStr(g.nameIt) == low then
                        return g
                    end
                    if type(g.aliases) == "table" then
                        for _, al in ipairs(g.aliases) do
                            if NormalizeInstStr(al) == low then
                                return g
                            end
                        end
                    end
                end
            end
            for _, g in pairs(self.DUNGEON_GUIDES) do
                if type(g) == "table" then
                    local gEn = NormalizeInstStr(g.name)
                    local gIt = NormalizeInstStr(g.nameIt)
                    if (gEn ~= "" and #gEn >= 4 and (low:find(gEn, 1, true) or gEn:find(low, 1, true)))
                        or (gIt ~= "" and #gIt >= 4 and (low:find(gIt, 1, true) or gIt:find(low, 1, true))) then
                        return g
                    end
                    if type(g.aliases) == "table" then
                        for _, al in ipairs(g.aliases) do
                            local normAl = NormalizeInstStr(al)
                            if normAl ~= "" and #normAl >= 4 and (low:find(normAl, 1, true) or normAl:find(low, 1, true)) then
                                return g
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

function FP:FindMatchingBossIndex(guide, unitName)
    if type(guide) ~= "table" or type(guide.bosses) ~= "table" or not IsSafeStr(unitName) then
        return nil
    end
    local low = NormalizeInstStr(unitName)
    if low == "" then return nil end

    for idx, boss in ipairs(guide.bosses) do
        local bName = NormalizeInstStr(boss.name)
        if bName ~= "" and (low == bName or low:find(bName, 1, true) or bName:find(low, 1, true)) then
            return idx
        end
        if type(boss.aliases) == "table" then
            for _, pat in ipairs(boss.aliases) do
                local normPat = NormalizeInstStr(pat)
                if normPat ~= "" and (low == normPat or low:find(normPat, 1, true) or normPat:find(low, 1, true)) then
                    return idx
                end
            end
        end
    end
    return nil
end

function FP:GetSortedDungeonList(levelFilter)
    local list = {}
    for _, guide in pairs(self.DUNGEON_GUIDES) do
        if type(guide) == "table" and self:MatchesLevelFilter(guide, levelFilter) then
            list[#list + 1] = guide
        end
    end
    table.sort(list, function(a, b)
        local ka, kb = (a.kind == "raid") and 2 or 1, (b.kind == "raid") and 2 or 1
        if ka ~= kb then return ka < kb end
        local na, nb = a.isNew and 1 or 2, b.isNew and 1 or 2
        if na ~= nb then return na < nb end
        local la, lb = a.minLvl or 0, b.minLvl or 0
        if la ~= lb then return la < lb end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

local function CollectLiveQuestLogEntries()
    local entries = {}
    local playerFac = "Both"
    if UnitFactionGroup then
        local okF, fac = pcall(UnitFactionGroup, "player")
        if okF and IsSafeStr(fac) then
            playerFac = fac
        end
    end

    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local okN, numEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
        if okN and IsSafeNum(numEntries) then
            local curHeader = ""
            for i = 1, numEntries do
                local okI, info = pcall(C_QuestLog.GetInfo, i)
                if okI and type(info) == "table" then
                    if info.isHeader then
                        curHeader = IsSafeStr(info.title) and info.title or ""
                    elseif IsSafeStr(info.title) and not info.isHidden then
                        local qid = IsSafeNum(info.questID) and info.questID or nil
                        local isDone = (info.isComplete == true)
                        if not isDone and qid and C_QuestLog.IsComplete then
                            local okC, done = pcall(C_QuestLog.IsComplete, qid)
                            if okC and done == true then isDone = true end
                        end
                        local tagName = nil
                        if qid and C_QuestLog.GetQuestTagInfo then
                            local okT, tagInfo = pcall(C_QuestLog.GetQuestTagInfo, qid)
                            if okT and type(tagInfo) == "table" and IsSafeStr(tagInfo.tagName) then
                                tagName = tagInfo.tagName
                            end
                        end
                        entries[#entries + 1] = {
                            title = info.title,
                            normTitle = NormalizeInstStr(info.title),
                            header = curHeader,
                            normHeader = NormalizeInstStr(curHeader),
                            level = IsSafeNum(info.level) and info.level or nil,
                            isComplete = isDone,
                            questID = qid,
                            tagName = tagName,
                            faction = playerFac,
                        }
                    end
                end
            end
        end
        return entries
    end

    if GetNumQuestLogEntries and GetQuestLogTitle then
        local okN, numEntries = pcall(GetNumQuestLogEntries)
        if okN and IsSafeNum(numEntries) then
            local curHeader = ""
            for i = 1, numEntries do
                local okQ, title, level, questTag, isHeader, _, isComplete, _, questID = pcall(GetQuestLogTitle, i)
                if okQ then
                    if isHeader then
                        curHeader = IsSafeStr(title) and title or ""
                    elseif IsSafeStr(title) then
                        entries[#entries + 1] = {
                            title = title,
                            normTitle = NormalizeInstStr(title),
                            header = curHeader,
                            normHeader = NormalizeInstStr(curHeader),
                            level = IsSafeNum(level) and level or nil,
                            isComplete = (isComplete == 1 or isComplete == true),
                            questID = IsSafeNum(questID) and questID or nil,
                            tagName = IsSafeStr(questTag) and questTag or nil,
                            faction = playerFac,
                        }
                    end
                end
            end
        end
    end
    return entries
end

local function BuildGuideNameTokens(guide)
    local tokens = {}
    local function AddTok(s)
        local n = NormalizeInstStr(s)
        if n ~= "" and #n >= 4 then
            tokens[#tokens + 1] = n
        end
    end
    AddTok(guide.name)
    AddTok(guide.nameIt)
    if type(guide.aliases) == "table" then
        for _, al in ipairs(guide.aliases) do
            AddTok(al)
        end
    end
    return tokens
end

local function DoesLiveEntryMatchGuide(entry, tokens)
    for _, tok in ipairs(tokens) do
        if entry.normHeader ~= "" and (entry.normHeader == tok or entry.normHeader:find(tok, 1, true) or tok:find(entry.normHeader, 1, true)) then
            return true
        end
        if entry.normTitle ~= "" and entry.normTitle:find(tok, 1, true) then
            return true
        end
    end
    return false
end

local function BuildQuestsForGuide(guide, liveEntries)
    if type(guide) ~= "table" then return {} end
    local out = {}
    local byNormName = {}
    local raw = CURATED_DUNGEON_QUESTS[guide.id] or {}
    for _, cq in ipairs(raw) do
        local normN = NormalizeInstStr(cq.name)
        local locGiver = (FP.LocalizeQuestInstruction and FP:LocalizeQuestInstruction(cq.giver)) or cq.giver
        local locPrereq = (FP.LocalizeQuestInstruction and FP:LocalizeQuestInstruction(cq.prereq)) or cq.prereq
        local copy = {
            name = cq.name,
            level = cq.level,
            faction = cq.faction or "Both",
            giver = locGiver,
            giverRaw = cq.giver,
            prereq = locPrereq,
            prereqRaw = cq.prereq,
            inLog = false,
            isComplete = false,
        }
        out[#out + 1] = copy
        if normN ~= "" then
            byNormName[normN] = copy
        end
    end

    if type(liveEntries) == "table" and #liveEntries > 0 then
        local tokens = BuildGuideNameTokens(guide)
        for _, le in ipairs(liveEntries) do
            local matched = byNormName[le.normTitle]
            if matched then
                matched.inLog = true
                matched.isComplete = le.isComplete
                matched.questID = le.questID
                if le.level and not matched.level then
                    matched.level = le.level
                end
            elseif DoesLiveEntryMatchGuide(le, tokens) then
                local custom = {
                    name = le.title,
                    level = le.level,
                    faction = le.faction or "Both",
                    giver = IsSafeStr(le.header) and le.header or nil,
                    inLog = true,
                    isComplete = le.isComplete,
                    questID = le.questID,
                    fromLog = true,
                }
                out[#out + 1] = custom
                if le.normTitle ~= "" then
                    byNormName[le.normTitle] = custom
                end
            end
        end
    end

    return out
end

function FP:GetDungeonQuests(guide)
    if type(guide) ~= "table" then return {} end
    local liveEntries = CollectLiveQuestLogEntries()
    return BuildQuestsForGuide(guide, liveEntries)
end

function FP:SearchBossGuides(query, levelFilter)
    local normQ = NormalizeInstStr(query)
    if normQ == "" then return {} end

    local results = {}
    local list = self:GetSortedDungeonList(levelFilter)
    local liveEntries = CollectLiveQuestLogEntries()
    for _, g in ipairs(list) do
        local gEn = NormalizeInstStr(g.name)
        local gIt = NormalizeInstStr(g.nameIt)
        local instMatch = (gEn ~= "" and gEn:find(normQ, 1, true)) or (gIt ~= "" and gIt:find(normQ, 1, true))
        if not instMatch and type(g.aliases) == "table" then
            for _, al in ipairs(g.aliases) do
                if NormalizeInstStr(al):find(normQ, 1, true) then
                    instMatch = true
                    break
                end
            end
        end
        if instMatch then
            results[#results + 1] = {
                kind = (g.kind == "raid") and "raid" or "dungeon",
                priority = 1,
                guide = g,
                bossIdx = 1,
            }
        end

        for idx, b in ipairs(g.bosses or {}) do
            local bNorm = NormalizeInstStr(b.name)
            local bossMatch = (bNorm ~= "" and bNorm:find(normQ, 1, true))
            if not bossMatch and type(b.aliases) == "table" then
                for _, al in ipairs(b.aliases) do
                    if NormalizeInstStr(al):find(normQ, 1, true) then
                        bossMatch = true
                        break
                    end
                end
            end
            if bossMatch then
                results[#results + 1] = {
                    kind = "boss",
                    priority = 2,
                    guide = g,
                    bossIdx = idx,
                    boss = b,
                }
            end

            local drops = self:GetBossDrops(g, b)
            for _, item in ipairs(drops) do
                local itemNorm = NormalizeInstStr(item.name)
                local slotNorm = NormalizeInstStr(item.slot)
                if (itemNorm ~= "" and itemNorm:find(normQ, 1, true))
                    or (#normQ >= 3 and slotNorm ~= "" and slotNorm:find(normQ, 1, true)) then
                    results[#results + 1] = {
                        kind = "loot",
                        priority = 4,
                        guide = g,
                        bossIdx = idx,
                        boss = b,
                        item = item,
                    }
                end
            end
        end

        local quests = BuildQuestsForGuide(g, liveEntries)
        for _, q in ipairs(quests) do
            local qNameNorm = NormalizeInstStr(q.name)
            local qGiverNorm = NormalizeInstStr(q.giver)
            local qGiverRawNorm = NormalizeInstStr(q.giverRaw)
            local qPreNorm = NormalizeInstStr(q.prereq)
            local qPreRawNorm = NormalizeInstStr(q.prereqRaw)
            if (qNameNorm ~= "" and qNameNorm:find(normQ, 1, true))
                or (#normQ >= 3 and (
                    (qGiverNorm ~= "" and qGiverNorm:find(normQ, 1, true))
                    or (qGiverRawNorm ~= "" and qGiverRawNorm:find(normQ, 1, true))
                    or (qPreNorm ~= "" and qPreNorm:find(normQ, 1, true))
                    or (qPreRawNorm ~= "" and qPreRawNorm:find(normQ, 1, true))
                )) then
                results[#results + 1] = {
                    kind = "quest",
                    priority = 3,
                    guide = g,
                    bossIdx = 1,
                    quest = q,
                }
            end
        end
    end

    table.sort(results, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.kind == "quest" and b.kind == "quest" then
            local qa = (a.quest and a.quest.inLog) and 0 or 1
            local qb = (b.quest and b.quest.inLog) and 0 or 1
            if qa ~= qb then return qa < qb end
        end
        local la, lb = a.guide.minLvl or 0, b.guide.minLvl or 0
        if la ~= lb then return la < lb end
        return (a.guide.name or "") < (b.guide.name or "")
    end)

    if #results > 100 then
        local capped = {}
        for i = 1, 100 do capped[i] = results[i] end
        return capped
    end
    return results
end

-------------------------------------------------------------------------------
-- Canonical Dungeon Entrance Coordinates & Portal Locations (All 37 Guides)
-------------------------------------------------------------------------------
local ENTRANCE_COORDS = {
    -- Classic Dungeons (1-60)
    [389] = { mapID = 1454, x = 52.5, y = 49.0, zone = "Orgrimmar", desc = "Cleft of Shadow (Spirale d'Ombra)" },
    [43]  = { mapID = 1413, x = 46.0, y = 36.2, zone = "The Barrens", desc = "Caverna nell'occhio della roccia sopra l'oasi" },
    [36]  = { mapID = 1436, x = 42.5, y = 71.7, zone = "Westfall", desc = "Sotterraneo del granaio a Moonbrook" },
    [33]  = { mapID = 1421, x = 44.8, y = 67.8, zone = "Silverpine Forest", desc = "Castello sopra il villaggio di Pyrewood" },
    [48]  = { mapID = 1440, x = 14.2, y = 13.8, zone = "Ashenvale", desc = "Tempio sommerso sulla Zoram Strand" },
    [34]  = { mapID = 1453, x = 50.4, y = 66.2, zone = "Stormwind City", desc = "Edificio lungo il canale tra Mage Quarter e Cattedrale" },
    [90]  = { mapID = 1426, x = 24.8, y = 39.6, zone = "Dun Morogh", desc = "Ascensore di New Tinkertown" },
    [47]  = { mapID = 1413, x = 41.0, y = 57.5, zone = "The Barrens", desc = "Rupi a sud dei Barrens (accampamento verrospino)" },
    [129] = { mapID = 1413, x = 45.6, y = 58.3, zone = "The Barrens", desc = "Colline a sud-est di RFK" },
    [189] = { mapID = 1420, x = 85.0, y = 32.0, zone = "Tirisfal Glades", desc = "Grande cattedrale nell'angolo nord-est" },
    [70]  = { mapID = 1418, x = 42.5, y = 13.5, zone = "Badlands", desc = "Scavi a nord delle Badlands" },
    [349] = { mapID = 1443, x = 29.0, y = 62.4, zone = "Desolace", desc = "Valle delle Lance (Valley of Spears)" },
    [209] = { mapID = 1444, x = 38.7, y = 20.0, zone = "Tanaris", desc = "Piramidi nel deserto a nord-ovest" },
    [109] = { mapID = 1435, x = 69.5, y = 53.6, zone = "Swamp of Sorrows", desc = "Centro del lago Sorrowmurk (sott'acqua)" },
    [230] = { mapID = 1428, x = 34.8, y = 85.3, zone = "Burning Steppes", desc = "Massiccio Roccianera (Blackrock Mountain)" },
    [229] = { mapID = 1428, x = 34.8, y = 85.3, zone = "Burning Steppes", desc = "Piani superiori di Blackrock Mountain" },
    [429] = { mapID = 1448, x = 59.0, y = 42.2, zone = "Feralas", desc = "Cortile centrale di Eldreth (E/W/N)" },
    [289] = { mapID = 1422, x = 69.1, y = 72.9, zone = "Western Plaguelands", desc = "Isola di Caer Darrow" },
    [329] = { mapID = 1423, x = 31.0, y = 14.0, zone = "Eastern Plaguelands", desc = "Cancello principale a nord-ovest" },
    [309] = { mapID = 1434, x = 52.2, y = 17.1, zone = "Stranglethorn Vale", desc = "Grande cancello trolls a nord-est di STV" },
    [509] = { mapID = 1451, x = 29.3, y = 93.2, zone = "Silithus", desc = "Portale del Muro dello Scarabeo" },
    [531] = { mapID = 1451, x = 29.3, y = 93.2, zone = "Silithus", desc = "Portale del Muro dello Scarabeo (Raid 40)" },
    [409] = { mapID = 1428, x = 34.8, y = 85.3, zone = "Burning Steppes", desc = "Lothos Riftwaker dentro Blackrock Mountain" },
    [469] = { mapID = 1428, x = 34.8, y = 85.3, zone = "Burning Steppes", desc = "Orb of Command nei corridoi di Blackrock Spire" },
    [249] = { mapID = 1445, x = 52.6, y = 76.2, zone = "Dustwallow Marsh", desc = "Grotta di Wyrmbog a sud" },
    [533] = { mapID = 1423, x = 39.4, y = 25.4, zone = "Eastern Plaguelands", desc = "Cittadella fluttuante sopra Plaguewood" },

    -- WoW Forever New Custom Dungeons (13-60)
    ["FOREVER_HALL_OF_THANES"]     = { mapID = 1455, x = 44.6, y = 51.0, zone = "Ironforge", desc = "Ingresso di Old Ironforge" },
    ["FOREVER_RUINS_OF_LORDAERON"] = { mapID = 1420, x = 61.8, y = 65.0, zone = "Tirisfal Glades", desc = "Cortile sopra Undercity" },
    ["FOREVER_EXCAVATION_SITE"]    = { mapID = 1437, x = 47.0, y = 56.0, zone = "Wetlands", desc = "Scavi di Whelgar" },
    ["FOREVER_CITY_OF_DALARAN"]    = { mapID = 1416, x = 16.3, y = 65.8, zone = "Alterac Mountains", desc = "Cratere della Cupola Viola di Dalaran" },
    ["FOREVER_DROWNED_CITY"]       = { mapID = 1434, x = 22.5, y = 65.0, zone = "Stranglethorn Vale", desc = "Al largo della costa occidentale di STV" },
    ["FOREVER_KROLDOK_STRONGHOLD"] = { mapID = 1447, x = 43.0, y = 37.0, zone = "Felwood", desc = "Meeting Stone lungo il sentiero" },
    ["FOREVER_ALCAZ_PRISON"]       = { mapID = 1445, x = 77.2, y = 17.5, zone = "Dustwallow Marsh", desc = "Isola di Alcaz a nord-est" },
    ["FOREVER_BLACKMAW_HOLD"]      = { mapID = 1447, x = 38.4, y = 32.6, zone = "Felwood", desc = "Accampamento Timbermaw a nord" },
    ["FOREVER_SHAPERS_TERRACE"]    = { mapID = 1449, x = 50.5, y = 81.0, zone = "Un'Goro Crater", desc = "Cratere a sud di Un'Goro" },
    ["FOREVER_BARROW_DEEPS"]       = { mapID = 1447, x = 62.0, y = 24.0, zone = "Hyjal", desc = "Tumuli sotterranei a nord di Hyjal" },
    ["FOREVER_HYJAL_SUMMIT"]       = { mapID = 1447, x = 68.6, y = 44.1, zone = "Hyjal", desc = "Cima di Nordrassil" },
}

function FP:GetDungeonEntrance(guideID)
    if not guideID then return nil end
    local ent = ENTRANCE_COORDS[guideID] or ENTRANCE_COORDS[tonumber(guideID)]
    if ent then
        return {
            mapID    = ent.mapID,
            x        = ent.x,
            y        = ent.y,
            zoneName = ent.zone,
            desc     = ent.desc,
        }
    end
    if self.ZONE_POIS then
        for mapID, list in pairs(self.ZONE_POIS) do
            if type(list) == "table" then
                for _, poi in ipairs(list) do
                    if poi.cat == "dungeon" and poi.guideID and tostring(poi.guideID) == tostring(guideID) then
                        return {
                            mapID    = mapID,
                            x        = poi.x,
                            y        = poi.y,
                            zoneName = poi.desc,
                            desc     = poi.name,
                        }
                    end
                end
            end
        end
    end
    return nil
end
