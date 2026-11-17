local addonName, FP = ...

-------------------------------------------------------------------------------
-- QuestRewards.lua – Smart Quest Reward Advisor (Max Money + Class/Spec)
-------------------------------------------------------------------------------

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local GetItemInfoCompat             = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetItemInfoInstantCompat      = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local GetItemStatsCompat            = (C_Item and C_Item.GetItemStats) or GetItemStats
local IsUsableItemCompat            = (C_Item and C_Item.IsUsableItem) or IsUsableItem
local RequestLoadItemDataByIDCompat = (C_Item and C_Item.RequestLoadItemDataByID) or nil

local BASE_STAT_WEIGHTS = {
    ITEM_MOD_STAMINA_SHORT             = 1.1,
    ITEM_MOD_CRIT_RATING_SHORT         = 1.7,
    ITEM_MOD_HIT_RATING_SHORT          = 1.7,
    ITEM_MOD_HASTE_RATING_SHORT        = 1.5,
    ITEM_MOD_MASTERY_RATING_SHORT      = 1.4,
    ITEM_MOD_VERSATILITY               = 1.3,
}

local INVTYPE_SLOTS = {
    INVTYPE_HEAD           = { 1 },
    INVTYPE_NECK           = { 2 },
    INVTYPE_SHOULDER       = { 3 },
    INVTYPE_BODY           = { 4 },
    INVTYPE_CHEST          = { 5 },
    INVTYPE_ROBE           = { 5 },
    INVTYPE_WAIST          = { 6 },
    INVTYPE_LEGS           = { 7 },
    INVTYPE_FEET           = { 8 },
    INVTYPE_WRIST          = { 9 },
    INVTYPE_HAND           = { 10 },
    INVTYPE_FINGER         = { 11, 12 },
    INVTYPE_TRINKET        = { 13, 14 },
    INVTYPE_CLOAK          = { 15 },
    INVTYPE_WEAPON         = { 16, 17 },
    INVTYPE_2HWEAPON       = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND  = { 17 },
    INVTYPE_HOLDABLE       = { 17 },
    INVTYPE_SHIELD         = { 17 },
    INVTYPE_RANGED         = { 18 },
    INVTYPE_RANGEDRIGHT    = { 18 },
    INVTYPE_THROWN         = { 18 },
}

local DUAL_WIELD_CLASSES = {
    WARRIOR     = true,
    ROGUE       = true,
    DEATHKNIGHT = true,
    SHAMAN      = true,
    HUNTER      = true,
    MONK        = true,
    DEMONHUNTER = true,
}

-- Complete class/spec definitions with localized fallback names & tailored stat/gear profiles
local CLASS_SPECS = {
    WARRIOR = {
        {
            key = "WARRIOR_ARMS", specID = 71, classicTab = 1, role = "MELEE", prefer2H = true, isDefault = true,
            names = { enUS = "Arms", itIT = "Armi", esES = "Armas", deDE = "Waffen", frFR = "Armes", ruRU = "Оружие" },
            weapons = { [0]=0.85, [1]=1.35, [4]=0.85, [5]=1.35, [6]=1.30, [7]=0.85, [8]=1.35, [13]=0.8, [15]=0.6, [2]=0.4, [3]=0.4, [18]=0.4 },
            stats = { ITEM_MOD_STRENGTH_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.6, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_CRIT_MELEE_RATING_SHORT = 2.0, ITEM_MOD_HIT_RATING_SHORT = 1.9, ITEM_MOD_HIT_MELEE_RATING_SHORT = 1.9, ITEM_MOD_AGILITY_SHORT = 1.4, ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 2.1, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.9, ITEM_MOD_STAMINA_SHORT = 1.5 },
        },
        {
            key = "WARRIOR_FURY", specID = 72, classicTab = 2, role = "MELEE", preferDual = true,
            names = { enUS = "Fury", itIT = "Furia", esES = "Furia", deDE = "Furor", frFR = "Fureur", ruRU = "Неистовство" },
            weapons = { [0]=1.2, [1]=1.15, [4]=1.2, [5]=1.15, [6]=1.0, [7]=1.2, [8]=1.15, [13]=1.15, [15]=0.8, [2]=0.4, [3]=0.4, [18]=0.4 },
            stats = { ITEM_MOD_STRENGTH_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_CRIT_MELEE_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_MELEE_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 1.8, ITEM_MOD_AGILITY_SHORT = 1.5, ITEM_MOD_EXPERTISE_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.5 },
        },
        {
            key = "WARRIOR_PROT", specID = 73, classicTab = 3, role = "TANK", allowShield = true, preferShield = true, forbid2H = true,
            names = { enUS = "Protection", itIT = "Protezione", esES = "Protección", deDE = "Schutz", frFR = "Protection", ruRU = "Защита" },
            weapons = { [0]=1.2, [4]=1.2, [7]=1.25, [13]=1.1, [15]=0.9, [2]=0.35, [3]=0.35, [18]=0.35 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.5, ITEM_MOD_STRENGTH_SHORT = 2.5, RESISTANCE0_NAME = 0.28, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 3.0, ITEM_MOD_DODGE_RATING_SHORT = 2.7, ITEM_MOD_PARRY_RATING_SHORT = 2.7, ITEM_MOD_BLOCK_RATING_SHORT = 2.8, ITEM_MOD_BLOCK_VALUE_SHORT = 2.0, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.8, ITEM_MOD_HIT_RATING_SHORT = 1.6, ITEM_MOD_AGILITY_SHORT = 1.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.2 },
        },
    },
    PALADIN = {
        {
            key = "PALADIN_HOLY", specID = 65, classicTab = 1, role = "HEALER", allowShield = true, allowHoldable = true, preferCaster = true, forbid2H = true,
            names = { enUS = "Holy", itIT = "Sacro", esES = "Sagrado", deDE = "Heilig", frFR = "Sacré", ruRU = "Свет" },
            weapons = { [4]=1.25, [7]=1.2, [0]=1.15, [6]=0.8 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.4, ITEM_MOD_SPELL_POWER_SHORT = 3.3, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 2.0, ITEM_MOD_SPIRIT_SHORT = 1.9, ITEM_MOD_MANA_REGENERATION_SHORT = 2.6, ITEM_MOD_POWER_REGEN0_SHORT = 2.6, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "PALADIN_PROT", specID = 66, classicTab = 2, role = "TANK", allowShield = true, preferShield = true, forbid2H = true,
            names = { enUS = "Protection", itIT = "Protezione", esES = "Protección", deDE = "Schutz", frFR = "Protection", ruRU = "Защита" },
            weapons = { [4]=1.25, [7]=1.25, [0]=1.15 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.5, ITEM_MOD_STRENGTH_SHORT = 2.6, RESISTANCE0_NAME = 0.28, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 2.9, ITEM_MOD_DODGE_RATING_SHORT = 2.6, ITEM_MOD_PARRY_RATING_SHORT = 2.6, ITEM_MOD_BLOCK_RATING_SHORT = 2.8, ITEM_MOD_BLOCK_VALUE_SHORT = 2.1, ITEM_MOD_SPELL_POWER_SHORT = 1.4, ITEM_MOD_INTELLECT_SHORT = 0.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1.2 },
        },
        {
            key = "PALADIN_RET", specID = 70, classicTab = 3, role = "MELEE", prefer2H = true, isDefault = true,
            names = { enUS = "Retribution", itIT = "Castigo", esES = "Reprensión", deDE = "Vergeltung", frFR = "Vindicte", ruRU = "Воздаяние" },
            weapons = { [1]=1.35, [5]=1.35, [8]=1.35, [6]=1.25, [0]=0.8, [4]=0.8, [7]=0.8 },
            stats = { ITEM_MOD_STRENGTH_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.6, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_CRIT_MELEE_RATING_SHORT = 2.0, ITEM_MOD_HIT_RATING_SHORT = 1.9, ITEM_MOD_HASTE_RATING_SHORT = 1.7, ITEM_MOD_AGILITY_SHORT = 1.1, ITEM_MOD_INTELLECT_SHORT = 0.6, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
    },
    HUNTER = {
        {
            key = "HUNTER_BM", specID = 253, classicTab = 1, role = "RANGED", preferRanged = true, isDefault = true,
            names = { enUS = "Beast Mastery", itIT = "Affinità Animale", esES = "Bestias", deDE = "Tierherrschaft", frFR = "Maîtrise des bêtes", ruRU = "Повелитель зверей" },
            weapons = { [2]=1.35, [3]=1.35, [18]=1.35, [6]=0.95, [10]=0.95, [0]=0.75, [1]=0.8, [7]=0.75, [8]=0.8, [13]=0.75, [15]=0.75 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 2.2, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_CRIT_RANGED_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 1.9, ITEM_MOD_INTELLECT_SHORT = 0.8, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
        {
            key = "HUNTER_MM", specID = 254, classicTab = 2, role = "RANGED", preferRanged = true,
            names = { enUS = "Marksmanship", itIT = "Precisione di Tiro", esES = "Puntería", deDE = "Treffsicherheit", frFR = "Précision", ruRU = "Стрельба" },
            weapons = { [2]=1.4, [3]=1.4, [18]=1.4, [6]=0.9, [10]=0.9, [0]=0.7, [1]=0.75, [7]=0.7, [8]=0.75, [13]=0.7, [15]=0.7 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 2.3, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.6, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_CRIT_RANGED_RATING_SHORT = 2.2, ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 2.0, ITEM_MOD_HIT_RATING_SHORT = 1.9, ITEM_MOD_INTELLECT_SHORT = 0.8, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "HUNTER_SURV", specID = 255, classicTab = 3, role = "RANGED",
            names = { enUS = "Survival", itIT = "Sopravvivenza", esES = "Supervivencia", deDE = "Überleben", frFR = "Survie", ruRU = "Выживание" },
            weapons = { [6]=1.25, [10]=1.2, [2]=1.25, [3]=1.25, [18]=1.25, [0]=0.85, [1]=0.9, [7]=0.85, [8]=0.9, [13]=0.85, [15]=0.85 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.8, ITEM_MOD_RANGED_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.4, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 1.9, ITEM_MOD_STAMINA_SHORT = 1.5, ITEM_MOD_INTELLECT_SHORT = 0.7 },
        },
    },
    ROGUE = {
        {
            key = "ROGUE_ASSASS", specID = 259, classicTab = 1, role = "MELEE", preferDual = true, preferDagger = true, forbid2H = true,
            names = { enUS = "Assassination", itIT = "Assassinio", esES = "Asesinato", deDE = "Meucheln", frFR = "Assassinat", ruRU = "Ликвидация" },
            weapons = { [15]=1.35, [7]=0.8, [4]=0.8, [13]=0.8, [0]=0.75, [2]=0.35, [3]=0.35, [18]=0.35 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 1.8, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.8, ITEM_MOD_STRENGTH_SHORT = 0.7, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "ROGUE_COMBAT", specID = 260, classicTab = 2, role = "MELEE", preferDual = true, forbid2H = true, isDefault = true,
            names = { enUS = "Outlaw / Combat", itIT = "Fuorilegge / Combattimento", esES = "Forajido / Combate", deDE = "Gesetzlosigkeit / Kampf", frFR = "Hors-la-loi / Combat", ruRU = "Головорез / Бой" },
            weapons = { [7]=1.25, [0]=1.2, [4]=1.2, [13]=1.2, [15]=0.85, [2]=0.35, [3]=0.35, [18]=0.35 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.6, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_EXPERTISE_RATING_SHORT = 2.0, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 2.0, ITEM_MOD_STRENGTH_SHORT = 0.8, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "ROGUE_SUB", specID = 261, classicTab = 3, role = "MELEE", preferDual = true, preferDagger = true, forbid2H = true,
            names = { enUS = "Subtlety", itIT = "Scaltrezza", esES = "Sutileza", deDE = "Täuschung", frFR = "Finesse", ruRU = "Скрытность" },
            weapons = { [15]=1.3, [7]=0.95, [4]=0.9, [13]=0.9, [0]=0.85, [2]=0.35, [3]=0.35, [18]=0.35 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.8, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.0, ITEM_MOD_STRENGTH_SHORT = 0.7, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
    },
    PRIEST = {
        {
            key = "PRIEST_DISC", specID = 256, classicTab = 1, role = "HEALER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Discipline", itIT = "Disciplina", esES = "Disciplina", deDE = "Disziplin", frFR = "Discipline", ruRU = "Послушание" },
            weapons = { [19]=1.2, [10]=1.2, [4]=1.1, [15]=1.05 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.5, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.2, ITEM_MOD_SPELL_POWER_SHORT = 3.2, ITEM_MOD_SPIRIT_SHORT = 2.2, ITEM_MOD_MANA_REGENERATION_SHORT = 2.5, ITEM_MOD_POWER_REGEN0_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 2.2, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "PRIEST_HOLY", specID = 257, classicTab = 2, role = "HEALER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Holy", itIT = "Sacro", esES = "Sagrado", deDE = "Heilig", frFR = "Sacré", ruRU = "Свет" },
            weapons = { [19]=1.2, [10]=1.2, [4]=1.1, [15]=1.05 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.4, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.3, ITEM_MOD_SPIRIT_SHORT = 2.7, ITEM_MOD_MANA_REGENERATION_SHORT = 2.6, ITEM_MOD_POWER_REGEN0_SHORT = 2.6, ITEM_MOD_HASTE_RATING_SHORT = 1.9, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 1.8, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "PRIEST_SHADOW", specID = 258, classicTab = 3, role = "CASTER", allowHoldable = true, preferCaster = true, isDefault = true,
            names = { enUS = "Shadow", itIT = "Ombra", esES = "Sombras", deDE = "Schatten", frFR = "Ombre", ruRU = "Тьма" },
            weapons = { [19]=1.25, [10]=1.2, [4]=1.05, [15]=1.1 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.6, ITEM_MOD_INTELLECT_SHORT = 3.1, ITEM_MOD_HIT_RATING_SHORT = 2.2, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.3, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_SPIRIT_SHORT = 1.5, ITEM_MOD_STAMINA_SHORT = 1.3, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 0.4 },
        },
    },
    DEATHKNIGHT = {
        {
            key = "DK_BLOOD", specID = 250, classicTab = 1, role = "TANK", prefer2H = true,
            names = { enUS = "Blood", itIT = "Sangue", esES = "Sangre", deDE = "Blut", frFR = "Sang", ruRU = "Кровь" },
            weapons = { [1]=1.3, [5]=1.3, [8]=1.3, [6]=1.25, [0]=0.8, [4]=0.8, [7]=0.8 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.5, ITEM_MOD_STRENGTH_SHORT = 3.0, RESISTANCE0_NAME = 0.28, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 2.8, ITEM_MOD_DODGE_RATING_SHORT = 2.6, ITEM_MOD_PARRY_RATING_SHORT = 2.6, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.9, ITEM_MOD_HIT_RATING_SHORT = 1.7, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.0 },
        },
        {
            key = "DK_FROST", specID = 251, classicTab = 2, role = "MELEE", preferDual = true,
            names = { enUS = "Frost", itIT = "Gelo", esES = "Escarcha", deDE = "Frost", frFR = "Givre", ruRU = "Лед" },
            weapons = { [0]=1.25, [4]=1.2, [7]=1.25, [1]=1.1, [5]=1.1, [8]=1.1, [6]=1.0 },
            stats = { ITEM_MOD_STRENGTH_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.0, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.9, ITEM_MOD_HASTE_RATING_SHORT = 1.8, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
        {
            key = "DK_UNHOLY", specID = 252, classicTab = 3, role = "MELEE", prefer2H = true, isDefault = true,
            names = { enUS = "Unholy", itIT = "Empietà", esES = "Profano", deDE = "Unheilig", frFR = "Impie", ruRU = "Нечестивость" },
            weapons = { [1]=1.35, [5]=1.35, [8]=1.35, [6]=1.25, [0]=0.8, [4]=0.8, [7]=0.8 },
            stats = { ITEM_MOD_STRENGTH_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.5, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_CRIT_RATING_SHORT = 1.9, ITEM_MOD_HIT_RATING_SHORT = 2.0, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.8, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
    },
    SHAMAN = {
        {
            key = "SHAMAN_ELE", specID = 262, classicTab = 1, role = "CASTER", allowShield = true, allowHoldable = true, preferCaster = true, forbid2H = true,
            names = { enUS = "Elemental", itIT = "Elementale", esES = "Elemental", deDE = "Elementar", frFR = "Élémentaire", ruRU = "Стихии" },
            weapons = { [4]=1.15, [15]=1.1, [0]=1.0, [10]=1.2, [13]=1.0 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_INTELLECT_SHORT = 3.4, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_SPIRIT_SHORT = 1.0, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "SHAMAN_ENH", specID = 263, classicTab = 2, role = "MELEE", preferDual = true, isDefault = true,
            names = { enUS = "Enhancement", itIT = "Potenziamento", esES = "Mejora", deDE = "Verstärkung", frFR = "Amélioration", ruRU = "Совершенствование" },
            weapons = { [0]=1.25, [4]=1.25, [13]=1.25, [1]=1.05, [5]=1.05, [15]=0.75, [10]=0.75 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.2, ITEM_MOD_STRENGTH_SHORT = 2.8, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.4, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.9, ITEM_MOD_HASTE_RATING_SHORT = 1.8, ITEM_MOD_INTELLECT_SHORT = 1.1, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
        {
            key = "SHAMAN_RESTO", specID = 264, classicTab = 3, role = "HEALER", allowShield = true, allowHoldable = true, preferCaster = true, forbid2H = true,
            names = { enUS = "Restoration", itIT = "Rigenerazione", esES = "Restauración", deDE = "Wiederherstellung", frFR = "Restauration", ruRU = "Исцеление" },
            weapons = { [4]=1.2, [15]=1.1, [0]=1.0, [10]=1.2, [13]=1.0 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.4, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.3, ITEM_MOD_MANA_REGENERATION_SHORT = 2.8, ITEM_MOD_POWER_REGEN0_SHORT = 2.8, ITEM_MOD_SPIRIT_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_CRIT_RATING_SHORT = 1.9, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 1.7, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
    },
    MAGE = {
        {
            key = "MAGE_ARCANE", specID = 62, classicTab = 1, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Arcane", itIT = "Arcano", esES = "Arcano", deDE = "Arkan", frFR = "Arcanes", ruRU = "Тайная магия" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.1, [15]=1.05 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_HASTE_RATING_SHORT = 2.2, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_SPIRIT_SHORT = 1.0, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "MAGE_FIRE", specID = 63, classicTab = 2, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Fire", itIT = "Fuoco", esES = "Fuego", deDE = "Feuer", frFR = "Feu", ruRU = "Огонь" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.1, [15]=1.05 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_INTELLECT_SHORT = 3.4, ITEM_MOD_CRIT_RATING_SHORT = 2.5, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 2.5, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_HASTE_RATING_SHORT = 1.8, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "MAGE_FROST", specID = 64, classicTab = 3, role = "CASTER", allowHoldable = true, preferCaster = true, isDefault = true,
            names = { enUS = "Frost", itIT = "Gelo", esES = "Escarcha", deDE = "Frost", frFR = "Givre", ruRU = "Лед" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.1, [15]=1.05 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.5, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
    },
    WARLOCK = {
        {
            key = "WARLOCK_AFF", specID = 265, classicTab = 1, role = "CASTER", allowHoldable = true, preferCaster = true, isDefault = true,
            names = { enUS = "Affliction", itIT = "Afflizione", esES = "Aflicción", deDE = "Gebrechen", frFR = "Affliction", ruRU = "Колдовство" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.05, [15]=1.05 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.6, ITEM_MOD_INTELLECT_SHORT = 3.2, ITEM_MOD_HASTE_RATING_SHORT = 2.2, ITEM_MOD_HIT_RATING_SHORT = 2.2, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_STAMINA_SHORT = 1.6, ITEM_MOD_SPIRIT_SHORT = 1.0 },
        },
        {
            key = "WARLOCK_DEMO", specID = 266, classicTab = 2, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Demonology", itIT = "Demonologia", esES = "Demonología", deDE = "Dämonologie", frFR = "Démonologie", ruRU = "Демонология" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.05, [15]=1.05 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.6, ITEM_MOD_INTELLECT_SHORT = 3.2, ITEM_MOD_STAMINA_SHORT = 1.8, ITEM_MOD_SPIRIT_SHORT = 1.2, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_CRIT_RATING_SHORT = 1.9, ITEM_MOD_HIT_RATING_SHORT = 2.1 },
        },
        {
            key = "WARLOCK_DESTRO", specID = 267, classicTab = 3, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Destruction", itIT = "Distruzione", esES = "Destrucción", deDE = "Zerstörung", frFR = "Destruction", ruRU = "Разрушение" },
            weapons = { [19]=1.25, [10]=1.2, [7]=1.05, [15]=1.05 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.6, ITEM_MOD_INTELLECT_SHORT = 3.3, ITEM_MOD_CRIT_RATING_SHORT = 2.4, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 2.4, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_STAMINA_SHORT = 1.5 },
        },
    },
    MONK = {
        {
            key = "MONK_BREW", specID = 268, role = "TANK",
            names = { enUS = "Brewmaster", itIT = "Mastro Birraio", esES = "Maestro cervecero", deDE = "Braumeister", frFR = "Maître brasseur", ruRU = "Хмелевар" },
            weapons = { [6]=1.2, [10]=1.2, [0]=1.1, [4]=1.1, [7]=1.1, [13]=1.1 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.4, ITEM_MOD_AGILITY_SHORT = 3.3, RESISTANCE0_NAME = 0.25, ITEM_MOD_DODGE_RATING_SHORT = 2.4, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 1.9 },
        },
        {
            key = "MONK_MIST", specID = 270, role = "HEALER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Mistweaver", itIT = "Misticismo", esES = "Tejedor de niebla", deDE = "Nebelwirker", frFR = "Tisse-brume", ruRU = "Ткач туманов" },
            weapons = { [10]=1.2, [4]=1.1, [7]=1.05 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.4, ITEM_MOD_SPELL_POWER_SHORT = 3.4, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
        {
            key = "MONK_WW", specID = 269, role = "MELEE", preferDual = true, isDefault = true,
            names = { enUS = "Windwalker", itIT = "Impeto", esES = "Viajero del viento", deDE = "Windläufer", frFR = "Marche-vent", ruRU = "Танцующий с ветром" },
            weapons = { [13]=1.25, [0]=1.15, [4]=1.15, [7]=1.15, [6]=1.1, [10]=1.1 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.4, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 1.9, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
    },
    DRUID = {
        {
            key = "DRUID_BALANCE", specID = 102, classicTab = 1, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Balance", itIT = "Equilibrio", esES = "Equilibrio", deDE = "Gleichgewicht", frFR = "Équilibre", ruRU = "Баланс" },
            weapons = { [10]=1.2, [4]=1.1, [15]=1.05, [13]=1.0 },
            stats = { ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_INTELLECT_SHORT = 3.5, ITEM_MOD_HIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_SPELL_RATING_SHORT = 2.2, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_SPIRIT_SHORT = 1.3, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "DRUID_FERAL", specID = 103, classicTab = 2, role = "MELEE", prefer2H = true, isDefault = true,
            names = { enUS = "Feral", itIT = "Aggressore Ferino", esES = "Feral", deDE = "Wildheit", frFR = "Farouche", ruRU = "Сила зверя" },
            weapons = { [6]=1.25, [10]=1.25, [5]=1.2, [4]=0.85, [15]=0.8, [13]=0.85 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_STRENGTH_SHORT = 2.2, ITEM_MOD_FERAL_ATTACK_POWER_SHORT = 2.6, ITEM_MOD_ATTACK_POWER_SHORT = 2.0, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HIT_RATING_SHORT = 2.0, ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.6 },
        },
        {
            key = "DRUID_GUARDIAN", specID = 104, role = "TANK", prefer2H = true,
            names = { enUS = "Guardian", itIT = "Guardiano", esES = "Guardián", deDE = "Wächter", frFR = "Gardien", ruRU = "Страж" },
            weapons = { [6]=1.25, [10]=1.25, [5]=1.2, [4]=0.85, [15]=0.8, [13]=0.85 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.6, ITEM_MOD_AGILITY_SHORT = 3.3, RESISTANCE0_NAME = 0.30, ITEM_MOD_DODGE_RATING_SHORT = 2.7, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 2.7, ITEM_MOD_STRENGTH_SHORT = 1.8, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.8 },
        },
        {
            key = "DRUID_RESTO", specID = 105, classicTab = 3, role = "HEALER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Restoration", itIT = "Rigenerazione", esES = "Restauración", deDE = "Wiederherstellung", frFR = "Restauration", ruRU = "Исцеление" },
            weapons = { [10]=1.2, [4]=1.15, [15]=1.05, [13]=1.0 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.5, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.5, ITEM_MOD_SPELL_POWER_SHORT = 3.3, ITEM_MOD_SPIRIT_SHORT = 2.5, ITEM_MOD_MANA_REGENERATION_SHORT = 2.5, ITEM_MOD_POWER_REGEN0_SHORT = 2.5, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_CRIT_RATING_SHORT = 1.9, ITEM_MOD_STAMINA_SHORT = 1.2 },
        },
    },
    DEMONHUNTER = {
        {
            key = "DH_HAVOC", specID = 577, role = "MELEE", preferDual = true, forbid2H = true, isDefault = true,
            names = { enUS = "Havoc", itIT = "Rovina", esES = "Devastación", deDE = "Verwüstung", frFR = "Dévastation", ruRU = "Истребление" },
            weapons = { [9]=1.35, [0]=1.15, [7]=1.15, [13]=1.15 },
            stats = { ITEM_MOD_AGILITY_SHORT = 3.7, ITEM_MOD_ATTACK_POWER_SHORT = 1.9, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 2.4, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_HASTE_RATING_SHORT = 1.9, ITEM_MOD_STAMINA_SHORT = 1.4 },
        },
        {
            key = "DH_VENGEANCE", specID = 581, role = "TANK", preferDual = true, forbid2H = true,
            names = { enUS = "Vengeance", itIT = "Vendetta", esES = "Venganza", deDE = "Rachsucht", frFR = "Vengeance", ruRU = "Месть" },
            weapons = { [9]=1.35, [0]=1.15, [7]=1.15, [13]=1.15 },
            stats = { ITEM_MOD_STAMINA_SHORT = 3.5, ITEM_MOD_AGILITY_SHORT = 3.3, RESISTANCE0_NAME = 0.28, ITEM_MOD_HASTE_RATING_SHORT = 2.1, ITEM_MOD_VERSATILITY = 2.0 },
        },
    },
    EVOKER = {
        {
            key = "EVOKER_DEV", specID = 1467, role = "CASTER", allowHoldable = true, preferCaster = true, isDefault = true,
            names = { enUS = "Devastation", itIT = "Devastazione", esES = "Devastación", deDE = "Verheerung", frFR = "Dévastation", ruRU = "Опустошение" },
            weapons = { [10]=1.2, [4]=1.1, [7]=1.1, [15]=1.05, [0]=1.0 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.5, ITEM_MOD_CRIT_RATING_SHORT = 2.2, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "EVOKER_PRES", specID = 1468, role = "HEALER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Preservation", itIT = "Conservazione", esES = "Preservación", deDE = "Bewahrung", frFR = "Préservation", ruRU = "Хранитель" },
            weapons = { [10]=1.2, [4]=1.1, [7]=1.1, [15]=1.05, [0]=1.0 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 3.4, ITEM_MOD_SPELL_POWER_SHORT = 3.4, ITEM_MOD_CRIT_RATING_SHORT = 2.1, ITEM_MOD_HASTE_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
        {
            key = "EVOKER_AUG", specID = 1473, role = "CASTER", allowHoldable = true, preferCaster = true,
            names = { enUS = "Augmentation", itIT = "Fortificazione", esES = "Aumento", deDE = "Verstärkung", frFR = "Augmentation", ruRU = "Насыщатель" },
            weapons = { [10]=1.2, [4]=1.1, [7]=1.1, [15]=1.05, [0]=1.0 },
            stats = { ITEM_MOD_INTELLECT_SHORT = 3.6, ITEM_MOD_SPELL_POWER_SHORT = 3.4, ITEM_MOD_HASTE_RATING_SHORT = 2.2, ITEM_MOD_CRIT_RATING_SHORT = 2.0, ITEM_MOD_STAMINA_SHORT = 1.3 },
        },
    },
}

local SPEC_BY_KEY = {}
local SPEC_ID_TO_KEY = {}
local CLASSIC_TAB_TO_KEY = {}
local DEFAULT_SPEC_BY_CLASS = {}

for classTag, list in pairs(CLASS_SPECS) do
    CLASSIC_TAB_TO_KEY[classTag] = {}
    for _, spec in ipairs(list) do
        spec.classTag = classTag
        SPEC_BY_KEY[spec.key] = spec
        if spec.specID then
            SPEC_ID_TO_KEY[spec.specID] = spec.key
        end
        if spec.classicTab then
            CLASSIC_TAB_TO_KEY[classTag][spec.classicTab] = spec.key
        end
        if spec.isDefault or not DEFAULT_SPEC_BY_CLASS[classTag] then
            DEFAULT_SPEC_BY_CLASS[classTag] = spec.key
        end
    end
end

local function IsForbiddenObj(obj)
    return not obj or (obj.IsForbidden and obj:IsForbidden())
end

local function GetArmorWeightsForClass(classTag)
    local lvl = (UnitLevel and UnitLevel("player")) or 1
    if classTag == "WARRIOR" or classTag == "PALADIN" or classTag == "DEATHKNIGHT" then
        return (lvl >= 40) and { [4] = 74, [3] = 36 } or { [4] = 70, [3] = 58 }
    elseif classTag == "HUNTER" or classTag == "SHAMAN" then
        return (lvl >= 40) and { [3] = 72, [2] = 34 } or { [3] = 68, [2] = 54 }
    elseif classTag == "EVOKER" then
        return { [3] = 72, [2] = 38 }
    elseif classTag == "ROGUE" or classTag == "DRUID" or classTag == "MONK" or classTag == "DEMONHUNTER" then
        return { [2] = 68 }
    end
    return { [1] = 68 }
end

local function ReadTalentTabInfo(tabIdx)
    if type(GetTalentTabInfo) ~= "function" then return nil, 0 end
    local a, b, c, _, e = GetTalentTabInfo(tabIdx)
    if type(a) == "number" and type(b) == "string" then
        return b, tonumber(e) or 0
    elseif type(a) == "string" then
        return a, tonumber(c) or 0
    end
    return nil, 0
end

local function GetSpecDisplayName(specKey)
    local spec = SPEC_BY_KEY[specKey]
    if not spec then return tostring(specKey or "Spec") end

    local activeLoc = (FP.GetResolvedLocale and FP:GetResolvedLocale())
        or (FP.ResolveLocaleCode and NexusKitDB and NexusKitDB.settings and FP:ResolveLocaleCode(NexusKitDB.settings.locale))
        or "enUS"
    local clientLoc = (GetLocale and GetLocale()) or "enUS"
    local useBlizzName = (not NexusKitDB or not NexusKitDB.settings or not NexusKitDB.settings.locale or NexusKitDB.settings.locale == "auto" or activeLoc == clientLoc)

    if useBlizzName and spec.specID then
        local getByID = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID) or GetSpecializationInfoByID
        if type(getByID) == "function" then
            local ok, _, name = pcall(getByID, spec.specID)
            if ok and type(name) == "string" and name ~= "" then
                return name
            end
        end
    end

    if useBlizzName and spec.classicTab and spec.classTag == select(2, UnitClass("player")) then
        local tabName = ReadTalentTabInfo(spec.classicTab)
        if type(tabName) == "string" and tabName ~= "" then
            return tabName
        end
    end

    return (spec.names and (spec.names[activeLoc] or spec.names["enUS"])) or spec.key
end

local function DetectAutoSpecKey(classTag)
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local getSpecInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    if type(getSpec) == "function" and type(getSpecInfo) == "function" then
        local idx = getSpec()
        if idx then
            local specID = getSpecInfo(idx)
            if specID and SPEC_ID_TO_KEY[specID] then
                return SPEC_ID_TO_KEY[specID]
            end
        end
    end

    if type(GetNumTalentTabs) == "function" then
        local bestPts, bestTab = 0, nil
        local numTabs = GetNumTalentTabs() or 0
        for t = 1, numTabs do
            local _, pts = ReadTalentTabInfo(t)
            if pts > bestPts then
                bestPts = pts
                bestTab = t
            end
        end
        if bestTab and CLASSIC_TAB_TO_KEY[classTag] and CLASSIC_TAB_TO_KEY[classTag][bestTab] then
            return CLASSIC_TAB_TO_KEY[classTag][bestTab]
        end
    end

    return DEFAULT_SPEC_BY_CLASS[classTag] or "WARRIOR_ARMS"
end

local function BuildSpecProfile(classTag, specDef, isAuto)
    local mergedWeights = {}
    for k, v in pairs(BASE_STAT_WEIGHTS) do
        mergedWeights[k] = v
    end
    for k, v in pairs(specDef.stats or {}) do
        mergedWeights[k] = v
    end

    return {
        classTag      = classTag,
        specKey       = specDef.key,
        specName      = GetSpecDisplayName(specDef.key),
        isAuto        = isAuto == true,
        role          = specDef.role,
        armorWeights  = GetArmorWeightsForClass(classTag),
        weaponWeights = specDef.weapons or {},
        statWeights   = mergedWeights,
        allowShield   = specDef.allowShield == true,
        preferShield  = specDef.preferShield == true,
        allowHoldable = specDef.allowHoldable == true,
        preferCaster  = specDef.preferCaster == true,
        forbid2H      = specDef.forbid2H == true,
        prefer2H      = specDef.prefer2H == true,
        preferDual    = specDef.preferDual == true,
    }
end

local function ResolveActiveRewardProfile()
    local classDisplay, classTag = UnitClass("player")
    classTag = classTag or "WARRIOR"
    local settings = NexusKitDB and NexusKitDB.settings
    local byClass = settings and settings.rewardSpecByClass
    local chosen = (type(byClass) == "table" and byClass[classTag]) or "AUTO"

    local specKey = chosen
    local isAuto = (not specKey or specKey == "AUTO" or not SPEC_BY_KEY[specKey] or SPEC_BY_KEY[specKey].classTag ~= classTag)
    if isAuto then
        specKey = DetectAutoSpecKey(classTag)
    end

    local specDef = SPEC_BY_KEY[specKey] or SPEC_BY_KEY[DEFAULT_SPEC_BY_CLASS[classTag]] or SPEC_BY_KEY["WARRIOR_ARMS"]
    local profile = BuildSpecProfile(classTag, specDef, isAuto)
    profile.classDisplay = classDisplay or classTag
    return profile
end

function FP:GetRewardSpecOptions()
    local L = FP.L or {}
    local _, classTag = UnitClass("player")
    classTag = classTag or "WARRIOR"
    local autoKey = DetectAutoSpecKey(classTag)
    local autoName = GetSpecDisplayName(autoKey)

    local opts = {
        {
            key = "AUTO",
            text = string.format(L["REWARD_SPEC_AUTO"] or "Auto (%s)", autoName),
            shortText = string.format(L["REWARD_SPEC_AUTO"] or "Auto (%s)", autoName),
        },
    }
    for _, spec in ipairs(CLASS_SPECS[classTag] or {}) do
        local nm = GetSpecDisplayName(spec.key)
        table.insert(opts, {
            key = spec.key,
            text = nm,
            shortText = nm,
        })
    end
    return opts
end

function FP:GetRewardSpecSelection()
    local prof = ResolveActiveRewardProfile()
    local L = FP.L or {}
    local label = prof.isAuto and string.format(L["REWARD_SPEC_AUTO"] or "Auto (%s)", prof.specName) or prof.specName
    return prof.isAuto and "AUTO" or prof.specKey, label, prof.specName
end

function FP:SetRewardTargetSpec(specKey)
    local _, classTag = UnitClass("player")
    classTag = classTag or "WARRIOR"
    if NexusKitDB and NexusKitDB.settings then
        if type(NexusKitDB.settings.rewardSpecByClass) ~= "table" then
            NexusKitDB.settings.rewardSpecByClass = {}
        end
        NexusKitDB.settings.rewardSpecByClass[classTag] = specKey or "AUTO"
    end
    if self.RefreshQuestRewardHighlights then
        self:RefreshQuestRewardHighlights()
    end
    if self.RefreshSettingsUI then
        self:RefreshSettingsUI()
    end
end

-------------------------------------------------------------------------------
-- Item Analysis & Money Formatting
-------------------------------------------------------------------------------
local function FormatSellValue(copper)
    if not copper or copper <= 0 then return "0c" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("%dg %ds", g, s)
    elseif s > 0 then
        return string.format("%ds %dc", s, c)
    end
    return string.format("%dc", c)
end

local CASTER_STAT_KEYS = {
    "ITEM_MOD_INTELLECT_SHORT",
    "ITEM_MOD_SPIRIT_SHORT",
    "ITEM_MOD_SPELL_POWER_SHORT",
    "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
    "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    "ITEM_MOD_MANA_REGENERATION_SHORT",
    "ITEM_MOD_POWER_REGEN0_SHORT",
    "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    "ITEM_MOD_HASTE_SPELL_RATING_SHORT",
}

local PHYS_STAT_KEYS = {
    "ITEM_MOD_STRENGTH_SHORT",
    "ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_ATTACK_POWER_SHORT",
    "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    "ITEM_MOD_FERAL_ATTACK_POWER_SHORT",
    "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
    "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
    "ITEM_MOD_CRIT_RANGED_RATING_SHORT",
}

local TANK_STAT_KEYS = {
    "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT",
    "ITEM_MOD_BLOCK_VALUE_SHORT",
}

local function SumKeys(stats, keyList)
    local total = 0
    for _, k in ipairs(keyList) do
        local v = stats[k]
        if type(v) == "number" and v > 0 then
            total = total + v
        end
    end
    return total
end

local function SafeGetItemInfo(item)
    if not item then return nil end
    if GetItemInfoCompat then
        local ok, a, b, c, d, e, f, g, h, i, j, k, l, m = pcall(GetItemInfoCompat, item)
        if ok and a then return a, b, c, d, e, f, g, h, i, j, k, l, m end
    end
    if GetItemInfo and GetItemInfo ~= GetItemInfoCompat then
        local ok, a, b, c, d, e, f, g, h, i, j, k, l, m = pcall(GetItemInfo, item)
        if ok and a then return a, b, c, d, e, f, g, h, i, j, k, l, m end
    end
    return nil
end

local function SafeGetItemInfoInstant(item)
    if not item then return nil end
    if GetItemInfoInstantCompat then
        local ok, a, b, c, d, e, f, g = pcall(GetItemInfoInstantCompat, item)
        if ok and a then return a, b, c, d, e, f, g end
    end
    if GetItemInfoInstant and GetItemInfoInstant ~= GetItemInfoInstantCompat then
        local ok, a, b, c, d, e, f, g = pcall(GetItemInfoInstant, item)
        if ok and a then return a, b, c, d, e, f, g end
    end
    return nil
end

local function SafeGetItemStats(link)
    if not link then return nil end
    if GetItemStatsCompat then
        local ok, stats = pcall(GetItemStatsCompat, link)
        if ok and type(stats) == "table" then return stats end
    end
    if GetItemStats and GetItemStats ~= GetItemStatsCompat then
        local ok, stats = pcall(GetItemStats, link)
        if ok and type(stats) == "table" then return stats end
    end
    return nil
end

local function SafeIsUsableItem(link)
    if not link then return nil end
    if IsUsableItemCompat then
        local ok, usable = pcall(IsUsableItemCompat, link)
        if ok then return usable end
    end
    if IsUsableItem and IsUsableItem ~= IsUsableItemCompat then
        local ok, usable = pcall(IsUsableItem, link)
        if ok then return usable end
    end
    return nil
end

local function ScoreItemForProfile(link, profile)
    if not link then return nil end

    local _, _, quality, itemLevel, itemMinLevel, _, _, _, itemEquipLoc, _, _, classID, subclassID = SafeGetItemInfo(link)
    if not classID or not subclassID or not itemEquipLoc or itemEquipLoc == "" then
        local _, _, _, instEquip, _, instClass, instSub = SafeGetItemInfoInstant(link)
        classID = classID or instClass
        subclassID = subclassID or instSub
        if not itemEquipLoc or itemEquipLoc == "" then itemEquipLoc = instEquip or "" end
    end

    if not itemEquipLoc or itemEquipLoc == "" or itemEquipLoc == "INVTYPE_BAG" then
        return nil
    end

    local score = 0
    if classID == 4 or itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_NECK"
        or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_HOLDABLE" then
        if itemEquipLoc == "INVTYPE_CLOAK" or itemEquipLoc == "INVTYPE_NECK"
            or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_TRINKET" or subclassID == 0 then
            score = score + 52
        elseif subclassID == 6 or itemEquipLoc == "INVTYPE_SHIELD" then
            if not profile.allowShield then return nil end
            score = score + (profile.preferShield and 80 or 58)
        elseif itemEquipLoc == "INVTYPE_HOLDABLE" then
            if not profile.allowHoldable then return nil end
            score = score + 56
        else
            local armorBonus = subclassID and profile.armorWeights[subclassID]
            if not armorBonus then return nil end
            score = score + armorBonus
        end
    elseif classID == 2 then
        local wWeight = subclassID and profile.weaponWeights[subclassID]
        if not wWeight then return nil end
        if profile.forbid2H and itemEquipLoc == "INVTYPE_2HWEAPON" then
            return nil
        end
        if itemEquipLoc == "INVTYPE_2HWEAPON" and profile.classTag == "ROGUE" then
            return nil
        end
        if itemEquipLoc == "INVTYPE_WEAPONOFFHAND" and not DUAL_WIELD_CLASSES[profile.classTag] then
            return nil
        end
        if itemEquipLoc == "INVTYPE_2HWEAPON" and profile.prefer2H then
            wWeight = wWeight * 1.12
        end
        score = score + (46 * wWeight)
    else
        return nil
    end

    local stats = SafeGetItemStats(link)
    local statScore = 0
    if type(stats) == "table" then
        local casterSum = SumKeys(stats, CASTER_STAT_KEYS)
        local physSum = SumKeys(stats, PHYS_STAT_KEYS)
        local tankSum = SumKeys(stats, TANK_STAT_KEYS)

        if profile.preferCaster then
            if classID == 2 and subclassID ~= 19 and casterSum == 0 then
                return nil
            end
            if (physSum > 0 or tankSum > 0) and casterSum == 0 then
                return nil
            end
        else
            if casterSum > 0 and physSum == 0 and tankSum == 0 then
                return nil
            end
        end

        for statKey, val in pairs(stats) do
            if type(val) == "number" then
                if statKey == "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" and profile.preferCaster and subclassID ~= 19 then
                    -- Ignore melee weapon DPS for casters/healers (except wands)
                elseif statKey == "ITEM_MOD_DAMAGE_PER_SECOND_SHORT" and profile.preferCaster and subclassID == 19 then
                    statScore = statScore + (val * 1.1)
                else
                    local w = profile.statWeights[statKey]
                    if w then
                        statScore = statScore + (val * w)
                    end
                end
            end
        end
    elseif profile.preferCaster and classID == 2 and subclassID ~= 19 and subclassID ~= 10 then
        return nil
    end

    score = score + statScore + ((itemLevel or 1) * 1.5) + ((quality or 1) * 4)

    -- Soft penalty for temporarily unusable items (e.g., untrained weapon skill or 1-3 lvls ahead)
    local usable = SafeIsUsableItem(link)
    if usable == false then
        local pLvl = (UnitLevel and UnitLevel("player")) or 1
        if itemMinLevel and itemMinLevel > pLvl + 6 then
            return nil
        end
        score = score - 10
    end

    return score, itemEquipLoc
end

local function EvaluateUpgradeCandidate(link, profile)
    local candScore, itemEquipLoc = ScoreItemForProfile(link, profile)
    if not candScore or candScore <= 0 then return nil end

    local slots = itemEquipLoc and INVTYPE_SLOTS[itemEquipLoc]
    if itemEquipLoc == "INVTYPE_WEAPON" and not (DUAL_WIELD_CLASSES[profile.classTag] and profile.preferDual) then
        slots = { 16 }
    end
    if not slots or not GetInventoryItemLink then
        return candScore, true, false, itemEquipLoc
    end

    local lowestEquipped = nil
    local hasEmpty = false
    for _, slotID in ipairs(slots) do
        local eqLink = GetInventoryItemLink("player", slotID)
        if not eqLink and slotID == 17 then
            local mhLink = GetInventoryItemLink("player", 16)
            if mhLink then
                local _, _, _, _, _, _, _, _, mhEquipLoc = SafeGetItemInfo(mhLink)
                if mhEquipLoc == "INVTYPE_2HWEAPON" then
                    eqLink = mhLink
                end
            end
        end
        if not eqLink then
            lowestEquipped = 0
            hasEmpty = true
            break
        end
        local eqScore = ScoreItemForProfile(eqLink, profile) or 0
        if not lowestEquipped or eqScore < lowestEquipped then
            lowestEquipped = eqScore
        end
    end

    local delta = candScore - (lowestEquipped or 0)
    local isUpgrade = hasEmpty or (delta > 0)
    local rankScore = candScore + (isUpgrade and (delta * 0.65 + (hasEmpty and 35 or 20)) or (delta * 0.25))
    return rankScore, isUpgrade, hasEmpty, itemEquipLoc, candScore
end

local function EvaluateOffSpecForClass(link, activeProfile)
    if not link or not activeProfile then return nil, nil end
    local specs = CLASS_SPECS[activeProfile.classTag]
    if not specs then return nil, nil end

    local bestScore = nil
    local matchedNames = {}
    for _, specDef in ipairs(specs) do
        if specDef.key ~= activeProfile.specKey then
            local otherProfile = BuildSpecProfile(activeProfile.classTag, specDef, false)
            local s = ScoreItemForProfile(link, otherProfile)
            if s and s > 0 then
                table.insert(matchedNames, otherProfile.specName)
                if not bestScore or s > bestScore then
                    bestScore = s
                end
            end
        end
    end
    if #matchedNames == 0 then return nil, nil end
    return bestScore, table.concat(matchedNames, " / ")
end

-------------------------------------------------------------------------------
-- Taint-Free Button Lookup, Visual Icon Badges & Inline Spec Selector
-------------------------------------------------------------------------------
local ICON_ASSETS = {
    CLASS_ATLAS   = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
    CLASS_FALLBACK = "Interface\\Icons\\INV_Misc_ArmorKit_17",
    COINS         = "Interface\\Icons\\INV_Misc_Coin_01",
    UPGRADE_CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready",
}

local FALLBACK_CLASS_TCOORDS = {
    WARRIOR     = { 0.00, 0.25, 0.00, 0.25 },
    MAGE        = { 0.25, 0.50, 0.00, 0.25 },
    ROGUE       = { 0.50, 0.75, 0.00, 0.25 },
    DRUID       = { 0.75, 1.00, 0.00, 0.25 },
    HUNTER      = { 0.00, 0.25, 0.25, 0.50 },
    SHAMAN      = { 0.25, 0.50, 0.25, 0.50 },
    PRIEST      = { 0.50, 0.75, 0.25, 0.50 },
    WARLOCK     = { 0.75, 1.00, 0.25, 0.50 },
    PALADIN     = { 0.00, 0.25, 0.50, 0.75 },
    DEATHKNIGHT = { 0.25, 0.50, 0.50, 0.75 },
}

local REWARD_TIER_STYLES = {
    BEST_SPEC     = { r = 0.15, g = 0.96, b = 0.52, borderA = 0.96, bgA = 0.16, glowA = 0.80, badgeSize = 18 },
    SPEC_USABLE   = { r = 0.22, g = 0.86, b = 0.72, borderA = 0.78, bgA = 0.09, glowA = 0.45, badgeSize = 16 },
    CLASS_OFFSPEC = { r = 0.38, g = 0.78, b = 1.00, borderA = 0.74, bgA = 0.08, glowA = 0.38, badgeSize = 15 },
    VENDOR        = { r = 1.00, g = 0.84, b = 0.14, borderA = 0.92, bgA = 0.15, glowA = 0.75, badgeSize = 17 },
}

local function ApplyClassCrestTexture(tex, classTag)
    local tc = (type(CLASS_ICON_TCOORDS) == "table" and CLASS_ICON_TCOORDS[classTag]) or FALLBACK_CLASS_TCOORDS[classTag]
    if tc then
        tex:SetTexture(ICON_ASSETS.CLASS_ATLAS)
        local u0, u1, v0, v1 = tc[1], tc[2], tc[3], tc[4]
        local padU = (u1 - u0) * 0.06
        local padV = (v1 - v0) * 0.06
        tex:SetTexCoord(u0 + padU, u1 - padU, v0 + padV, v1 - padV)
    else
        tex:SetTexture(ICON_ASSETS.CLASS_FALLBACK)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Layered 1px color frame avoids BackdropTemplate edge clipping under fractional UI scales
local function CreateFramedIconBadge(parent, size, withUpMark)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(size, size)
    b:EnableMouse(false)

    local rim = b:CreateTexture(nil, "BACKGROUND")
    rim:SetAllPoints()
    rim:SetTexture("Interface\\Buttons\\WHITE8x8")
    b.rim = rim

    local bg = b:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.05, 0.05, 0.07, 0.96)
    b.bg = bg

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon = icon

    if withUpMark then
        local upMark = b:CreateTexture(nil, "OVERLAY")
        upMark:SetSize(11, 11)
        upMark:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
        upMark:SetTexture(ICON_ASSETS.UPGRADE_CHECK)
        upMark:Hide()
        b.upMark = upMark
    end

    b:Hide()
    return b
end

local rewardOverlays = {}
local rewardOverlayHost = CreateFrame("Frame", "NexusKitRewardOverlayHost", UIParent)
rewardOverlayHost:SetAllPoints(UIParent)
rewardOverlayHost:EnableMouse(false)
rewardOverlayHost:Hide()

local specSelectorBtn = CreateFrame("Button", "NexusKitRewardSpecSelector", rewardOverlayHost, "BackdropTemplate")
specSelectorBtn:SetSize(142, 19)
specSelectorBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
specSelectorBtn:SetBackdropColor(0.11, 0.08, 0.05, 0.94)
specSelectorBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
specSelectorBtn:Hide()

local specClassIcon = specSelectorBtn:CreateTexture(nil, "ARTWORK")
specClassIcon:SetSize(12, 12)
specClassIcon:SetPoint("LEFT", 5, 0)
specSelectorBtn.classIcon = specClassIcon

local specBtnText = specSelectorBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
specBtnText:SetPoint("LEFT", specClassIcon, "RIGHT", 4, 0)
specBtnText:SetPoint("RIGHT", -14, 0)
specBtnText:SetJustifyH("LEFT")
specBtnText:SetWordWrap(false)
local sfName = specBtnText:GetFont()
if sfName then specBtnText:SetFont(sfName, 10, "") end
specSelectorBtn.text = specBtnText

local specBtnArrow = specSelectorBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
specBtnArrow:SetPoint("RIGHT", -5, 0)
specBtnArrow:SetText("v")
specBtnArrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
specSelectorBtn.arrow = specBtnArrow

specSelectorBtn:SetScript("OnClick", function(self)
    if not FP.ShowPopupMenu then return end
    local selectedKey = FP:GetRewardSpecSelection()
    local items = {}
    for _, opt in ipairs(FP:GetRewardSpecOptions()) do
        table.insert(items, {
            text = opt.text,
            checked = (opt.key == selectedKey),
            func = function()
                FP:SetRewardTargetSpec(opt.key)
            end,
        })
    end
    FP:ShowPopupMenu(self, "TOPRIGHT", "BOTTOMRIGHT", 0, -2, 200, items)
end)

specSelectorBtn:SetScript("OnEnter", function(self)
    if not GameTooltip or IsForbiddenObj(GameTooltip) then return end
    local L = FP.L or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SETTING_REWARD_SPEC"] or "Quest reward spec", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:AddLine(L["REWARD_SPEC_SELECTOR_TIP"] or "Click to choose which specialization of your class NexusKit optimizes quest rewards for.", 1, 1, 1, true)
    GameTooltip:Show()
end)

specSelectorBtn:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local function IsDescendantOf(frame, ancestor)
    local cur = frame
    for _ = 1, 10 do
        if not cur or IsForbiddenObj(cur) then return false end
        if cur == ancestor then return true end
        cur = cur.GetParent and cur:GetParent()
    end
    return false
end

local function GetActiveQuestRewardContext()
    if not QuestFrame or IsForbiddenObj(QuestFrame) or not QuestFrame:IsVisible() then
        return nil
    end

    local isReward = QuestFrameRewardPanel and not IsForbiddenObj(QuestFrameRewardPanel) and QuestFrameRewardPanel:IsVisible()
    local isDetail = (not isReward) and QuestFrameDetailPanel and not IsForbiddenObj(QuestFrameDetailPanel) and QuestFrameDetailPanel:IsVisible()
    if not isReward and not isDetail then
        return nil
    end

    local scrollFrame = isReward and QuestRewardScrollFrame or QuestDetailScrollFrame
    if scrollFrame and (IsForbiddenObj(scrollFrame) or not scrollFrame:IsVisible()) then
        scrollFrame = nil
    end

    local hasInfoRewards = QuestInfoRewardsFrame and not IsForbiddenObj(QuestInfoRewardsFrame)
        and QuestInfoRewardsFrame:IsVisible() and IsDescendantOf(QuestInfoRewardsFrame, QuestFrame)
    local container, chooseText, header, prefix

    if hasInfoRewards then
        container = QuestInfoRewardsFrame
        chooseText = QuestInfoRewardsFrame.ItemChooseText or QuestInfoItemChooseText
            or (isReward and QuestRewardItemChooseText or QuestDetailItemChooseText)
        header = QuestInfoRewardsFrame.Header
            or (isReward and (QuestRewardRewardTitleText or QuestRewardTitleText)
                or (QuestDetailRewardTitleText or QuestDetailTitleText))
    elseif isReward then
        container = (QuestRewardScrollChildFrame and not IsForbiddenObj(QuestRewardScrollChildFrame) and QuestRewardScrollChildFrame)
            or QuestFrameRewardPanel
        chooseText = QuestRewardItemChooseText
        header = QuestRewardRewardTitleText or QuestRewardTitleText
        prefix = "QuestRewardItem"
    else
        container = (QuestDetailScrollChildFrame and not IsForbiddenObj(QuestDetailScrollChildFrame) and QuestDetailScrollChildFrame)
            or QuestFrameDetailPanel
        chooseText = QuestDetailItemChooseText
        header = QuestDetailRewardTitleText or QuestDetailTitleText
        prefix = "QuestDetailItem"
    end

    return {
        isReward    = isReward,
        container   = container,
        scrollFrame = scrollFrame,
        chooseText  = chooseText,
        header      = header,
        prefix      = prefix,
        hasInfo     = hasInfoRewards,
    }
end

local function ClearRewardOverlays()
    for _, overlay in pairs(rewardOverlays) do
        overlay.hasData = false
        overlay.activeTier = nil
        overlay.activeIsMaxGold = false
        overlay.activeVendorPrice = 0
        overlay.activeOffSpecLabel = nil
        if overlay.classBadge then overlay.classBadge:Hide() end
        if overlay.coinBadge then overlay.coinBadge:Hide() end
        overlay:Hide()
    end
    specSelectorBtn:Hide()
    rewardOverlayHost:Hide()
end

function FP:ClearQuestRewardHighlights()
    ClearRewardOverlays()
end

local function IsMatchingChoiceBtn(btn, choiceIndex)
    return not IsForbiddenObj(btn) and btn:IsShown() and btn.type == "choice" and btn.GetID and btn:GetID() == choiceIndex
end

local function FindChoiceRewardButton(choiceIndex, ctx)
    if ctx and ctx.prefix then
        for i = 1, 20 do
            local btn = _G[ctx.prefix .. i]
            if IsMatchingChoiceBtn(btn, choiceIndex) then return btn end
        end
    end

    if ctx and ctx.hasInfo and QuestInfoRewardsFrame and not IsForbiddenObj(QuestInfoRewardsFrame) then
        if type(QuestInfoRewardsFrame.RewardButtons) == "table" then
            for _, btn in ipairs(QuestInfoRewardsFrame.RewardButtons) do
                if IsMatchingChoiceBtn(btn, choiceIndex) then return btn end
            end
        end

        if QuestInfoRewardsFrame.buttonPool and type(QuestInfoRewardsFrame.buttonPool.EnumerateActive) == "function" then
            for btn in QuestInfoRewardsFrame.buttonPool:EnumerateActive() do
                if IsMatchingChoiceBtn(btn, choiceIndex) then return btn end
            end
        end

        local children = { QuestInfoRewardsFrame:GetChildren() }
        for _, child in ipairs(children) do
            if IsMatchingChoiceBtn(child, choiceIndex) then return child end
        end
    end

    if ctx and ctx.container and not IsForbiddenObj(ctx.container) and ctx.container.GetChildren then
        local children = { ctx.container:GetChildren() }
        for _, child in ipairs(children) do
            if IsMatchingChoiceBtn(child, choiceIndex) then return child end
        end
    end

    for i = 1, 20 do
        for _, gName in ipairs({ "QuestRewardItem", "QuestDetailItem", "QuestInfoRewardsFrameQuestInfoItem", "QuestInfoItem" }) do
            local btn = _G[gName .. i]
            if IsMatchingChoiceBtn(btn, choiceIndex) then return btn end
        end
    end

    local fallbackName = (ctx and ctx.prefix) or (ctx and ctx.isReward and "QuestRewardItem" or "QuestDetailItem")
    if fallbackName then
        local fb = _G[fallbackName .. choiceIndex]
        if not IsForbiddenObj(fb) and fb:IsShown() and (not fb.type or fb.type == "choice") then
            return fb
        end
    end
    return nil
end

local function FindRewardButtonIcon(btn)
    if btn.Icon then return btn.Icon end
    if btn.icon then return btn.icon end
    if btn.IconTexture then return btn.IconTexture end
    local name = btn.GetName and btn:GetName()
    if name then
        local named = _G[name .. "IconTexture"] or _G[name .. "Icon"]
        if named then return named end
    end
    if btn.GetRegions then
        for _, region in ipairs({ btn:GetRegions() }) do
            if region and region.IsObjectType and region:IsObjectType("Texture") then
                local w, h = region:GetWidth() or 0, region:GetHeight() or 0
                if w >= 28 and w <= 48 and math.abs(w - h) <= 4 then
                    return region
                end
            end
        end
    end
    return nil
end

local function IsInsideScrollViewport(region, scrollFrame)
    if IsForbiddenObj(region) or not region:IsVisible() then return false end
    if not scrollFrame or IsForbiddenObj(scrollFrame) or not scrollFrame:IsVisible() then return true end
    local sTop, sBot = scrollFrame:GetTop(), scrollFrame:GetBottom()
    local rTop, rBot = region:GetTop(), region:GetBottom()
    if sTop and sBot and rTop and rBot then
        if rBot > (sTop + 2) or rTop < (sBot - 2) then
            return false
        end
    end
    return true
end

local function OnTooltipSetRewardItem(tooltip)
    if not tooltip or IsForbiddenObj(tooltip) or not tooltip:IsShown() then return end
    for btn, overlay in pairs(rewardOverlays) do
        if btn and not IsForbiddenObj(btn) and btn:IsShown() and btn:IsMouseOver() and overlay and overlay.hasData then
            local loc = FP.L or {}
            local tier = overlay.activeTier
            local vPrice = overlay.activeVendorPrice or 0
            local added = false

            if tier == "BEST_SPEC" then
                tooltip:AddLine(" ")
                local msg = string.format(loc["REWARD_SPEC_FOR_TIP"] or "Best match for %s", overlay.activeSpecName or "Spec")
                if overlay.activeIsUpgrade then
                    msg = msg .. " " .. (loc["REWARD_UPGRADE_TAG"] or "(Upgrade)")
                end
                tooltip:AddLine("|cff26f585NexusKit:|r " .. msg, 0.25, 1.0, 0.65, true)
                added = true
            elseif tier == "SPEC_USABLE" then
                tooltip:AddLine(" ")
                local msg = string.format(loc["REWARD_ALT_SPEC_TIP"] or "Also suitable for %s", overlay.activeSpecName or "Spec")
                if overlay.activeIsUpgrade then
                    msg = msg .. " " .. (loc["REWARD_UPGRADE_TAG"] or "(Upgrade)")
                end
                tooltip:AddLine("|cff38dbb8NexusKit:|r " .. msg, 0.35, 0.92, 0.80, true)
                added = true
            elseif tier == "CLASS_OFFSPEC" then
                tooltip:AddLine(" ")
                local specLabel = overlay.activeOffSpecLabel or overlay.activeClassName or "Spec"
                local msg = string.format(loc["REWARD_OFFSPEC_TIP"] or "Useful for off-spec: %s", specLabel)
                tooltip:AddLine("|cff61c7ffNexusKit:|r " .. msg, 0.40, 0.84, 1.0, true)
                added = true
            end

            if vPrice > 0 then
                if not added then tooltip:AddLine(" ") end
                local priceLine = string.format(loc["REWARD_SELL_VALUE_FMT"] or "Sell value: %s", FormatSellValue(vPrice))
                if overlay.activeIsMaxGold then
                    priceLine = priceLine .. " " .. (loc["REWARD_MAX_GOLD_TAG"] or "(Max Gold)")
                    tooltip:AddLine("|cffffd71fNexusKit:|r " .. priceLine, 1.0, 0.84, 0.12, true)
                else
                    tooltip:AddLine("|cffc8ccd4NexusKit:|r " .. priceLine, 0.85, 0.85, 0.88, true)
                end
                added = true
            end

            break
        end
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetRewardItem)
end

local function GetOrCreateRewardOverlay(btn)
    local overlay = rewardOverlays[btn]
    if overlay then return overlay end

    overlay = CreateFrame("Frame", nil, rewardOverlayHost, "BackdropTemplate")
    overlay:EnableMouse(false)
    overlay:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local iconGlow = overlay:CreateTexture(nil, "OVERLAY")
    iconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconGlow:SetBlendMode("ADD")
    overlay.iconGlow = iconGlow

    overlay.classBadge = CreateFramedIconBadge(overlay, 17, true)
    overlay.coinBadge  = CreateFramedIconBadge(overlay, 16, false)
    overlay.coinBadge.rim:SetVertexColor(1.00, 0.84, 0.14, 1.0)
    overlay.coinBadge.icon:SetTexture(ICON_ASSETS.COINS)
    overlay.coinBadge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    rewardOverlays[btn] = overlay
    return overlay
end

local function ApplyRewardOverlay(btn, info, ctx)
    local overlay = GetOrCreateRewardOverlay(btn)
    overlay.targetBtn = btn
    overlay.hasData = true
    overlay.activeTier = info.tier
    overlay.activeVendorPrice = info.vendorPrice or 0
    overlay.activeIsMaxGold = info.isMaxGold == true
    overlay.activeSpecName = info.specName
    overlay.activeOffSpecLabel = info.offSpecLabel
    overlay.activeClassName = info.classDisplay
    overlay.activeIsUpgrade = info.isUpgrade == true

    local hasClassBadge = (info.tier == "BEST_SPEC" or info.tier == "SPEC_USABLE" or info.tier == "CLASS_OFFSPEC")
    local hasCoinBadge = info.isMaxGold == true
    if not hasClassBadge and not hasCoinBadge then
        overlay.classBadge:Hide()
        overlay.coinBadge:Hide()
        overlay:Hide()
        return
    end

    local scrollFrame = ctx and ctx.scrollFrame
    if not IsInsideScrollViewport(btn, scrollFrame) then
        overlay.classBadge:Hide()
        overlay.coinBadge:Hide()
        overlay:Hide()
        return
    end

    local left = btn.GetLeft and btn:GetLeft()
    local right = btn.GetRight and btn:GetRight()
    local bottom = btn.GetBottom and btn:GetBottom()
    local top = btn.GetTop and btn:GetTop()
    if not left or not right or not bottom or not top then
        overlay.classBadge:Hide()
        overlay.coinBadge:Hide()
        overlay:Hide()
        return
    end

    local btnStrata = (btn.GetFrameStrata and btn:GetFrameStrata()) or "HIGH"
    local btnLevel = (btn.GetFrameLevel and btn:GetFrameLevel()) or 10
    rewardOverlayHost:SetFrameStrata(btnStrata)
    rewardOverlayHost:SetFrameLevel(btnLevel + 2)
    rewardOverlayHost:Show()

    local hScale = rewardOverlayHost:GetEffectiveScale() or 1
    local tScale = btn:GetEffectiveScale() or hScale
    local hLeft = rewardOverlayHost:GetLeft() or 0
    local hBottom = rewardOverlayHost:GetBottom() or 0

    local x = ((left * tScale) - (hLeft * hScale)) / hScale
    local y = ((bottom * tScale) - (hBottom * hScale)) / hScale
    local w = math.max(12, ((right - left) * tScale) / hScale)
    local h = math.max(12, ((top - bottom) * tScale) / hScale)

    overlay:SetFrameStrata(btnStrata)
    overlay:SetFrameLevel(btnLevel + 5)
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMLEFT", rewardOverlayHost, "BOTTOMLEFT", x - 1, y - 1)
    overlay:SetSize(w + 2, h + 2)

    local style = REWARD_TIER_STYLES[info.tier] or REWARD_TIER_STYLES.VENDOR
    local r, g, b = style.r, style.g, style.b
    overlay:SetBackdropColor(r * 0.14, g * 0.14, b * 0.14, style.bgA)
    overlay:SetBackdropBorderColor(r, g, b, style.borderA)

    local iconH = math.min(w, h)
    overlay.iconGlow:ClearAllPoints()
    overlay.iconGlow:SetPoint("CENTER", overlay, "LEFT", iconH * 0.5, 0)
    overlay.iconGlow:SetSize(iconH * 1.62, iconH * 1.62)
    overlay.iconGlow:SetVertexColor(r, g, b, style.glowA)
    overlay.iconGlow:Show()

    if hasClassBadge then
        local sz = style.badgeSize or 16
        overlay.classBadge:SetFrameStrata(btnStrata)
        overlay.classBadge:SetFrameLevel(btnLevel + 9)
        overlay.classBadge:SetSize(sz, sz)
        overlay.classBadge.rim:SetVertexColor(r, g, b, 1.0)
        ApplyClassCrestTexture(overlay.classBadge.icon, info.classTag)
        if overlay.classBadge.upMark then
            if info.isUpgrade == true and info.tier ~= "CLASS_OFFSPEC" then
                overlay.classBadge.upMark:Show()
            else
                overlay.classBadge.upMark:Hide()
            end
        end
        overlay.classBadge:ClearAllPoints()
        overlay.classBadge:SetPoint("TOPLEFT", overlay, "TOPLEFT", -1, 2)
        overlay.classBadge:Show()
    else
        overlay.classBadge:Hide()
    end

    if hasCoinBadge then
        overlay.coinBadge:SetFrameStrata(btnStrata)
        overlay.coinBadge:SetFrameLevel(btnLevel + 9)
        overlay.coinBadge:ClearAllPoints()
        overlay.coinBadge:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", -1, -2)
        overlay.coinBadge:Show()
    else
        overlay.coinBadge:Hide()
    end

    overlay:Show()
end

local function PositionSpecSelector(profile, ctx, firstChoiceBtn, secondChoiceBtn)
    if not ctx or not ctx.container or IsForbiddenObj(ctx.container) or not ctx.container:IsVisible() then
        specSelectorBtn:Hide()
        return
    end

    local checkRegion = firstChoiceBtn or ctx.chooseText or ctx.header or ctx.container
    if not IsInsideScrollViewport(checkRegion, ctx.scrollFrame) then
        specSelectorBtn:Hide()
        return
    end

    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    local L = FP.L or {}
    local _, _, specName = FP:GetRewardSpecSelection()
    local prefix = profile.isAuto and string.format(L["REWARD_SPEC_AUTO"] or "Auto (%s)", specName) or specName
    ApplyClassCrestTexture(specSelectorBtn.classIcon, profile.classTag)
    specSelectorBtn.text:SetText((L["REWARD_SPEC_HEADER"] or "Spec:") .. " " .. prefix)
    specSelectorBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
    specSelectorBtn.arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

    local strata = (ctx.container.GetFrameStrata and ctx.container:GetFrameStrata()) or "HIGH"
    local lvl = (ctx.container.GetFrameLevel and ctx.container:GetFrameLevel()) or 10
    rewardOverlayHost:SetFrameStrata(strata)
    rewardOverlayHost:SetFrameLevel(lvl + 2)
    rewardOverlayHost:Show()

    specSelectorBtn:SetFrameStrata(strata)
    specSelectorBtn:SetFrameLevel(lvl + 12)

    local desiredW = math.max(118, math.min(164, math.ceil((specSelectorBtn.text:GetStringWidth() or 86) + 38)))
    specSelectorBtn:SetWidth(desiredW)

    local chooseText = ctx.chooseText
    local header = ctx.header
    local targetFrame = (secondChoiceBtn and secondChoiceBtn:IsVisible()) and secondChoiceBtn
        or (header and header:IsVisible() and header)
        or (firstChoiceBtn and firstChoiceBtn:IsVisible() and firstChoiceBtn)
        or ctx.container

    local trLeft = targetFrame.GetLeft and targetFrame:GetLeft()
    local trRight = targetFrame.GetRight and targetFrame:GetRight()
    local trTop = targetFrame.GetTop and targetFrame:GetTop()
    local trBottom = targetFrame.GetBottom and targetFrame:GetBottom()

    if trLeft and trRight and trTop and trBottom then
        local hScale = rewardOverlayHost:GetEffectiveScale() or 1
        local tScale = targetFrame:GetEffectiveScale() or hScale
        local hLeft = rewardOverlayHost:GetLeft() or 0
        local hBottom = rewardOverlayHost:GetBottom() or 0

        local rx = ((trRight * tScale) - (hLeft * hScale)) / hScale
        local ty = ((trTop * tScale) - (hBottom * hScale)) / hScale
        local by = ((trBottom * tScale) - (hBottom * hScale)) / hScale

        specSelectorBtn:ClearAllPoints()
        if targetFrame == secondChoiceBtn then
            specSelectorBtn:SetPoint("BOTTOMRIGHT", rewardOverlayHost, "BOTTOMLEFT", rx, ty + 4)
        elseif targetFrame == header then
            specSelectorBtn:SetPoint("LEFT", rewardOverlayHost, "BOTTOMLEFT", rx + 14, (ty + by) * 0.5 - 10)
        else
            specSelectorBtn:SetPoint("TOPRIGHT", rewardOverlayHost, "BOTTOMLEFT", rx - 10, ty - 4)
        end
        specSelectorBtn:Show()
    else
        specSelectorBtn:Hide()
    end
end

-------------------------------------------------------------------------------
-- Refresh & Evaluation Driver
-------------------------------------------------------------------------------
local rewardRefreshTimer = false
local lastScrollVal = nil

local function HighlightBestRewards()
    ClearRewardOverlays()

    local settings = NexusKitDB and NexusKitDB.settings
    if settings and settings.highlightQuestRewards == false then return end

    local ctx = GetActiveQuestRewardContext()
    if not ctx or not GetNumQuestChoices then return end

    if ctx.scrollFrame and ctx.scrollFrame.GetVerticalScroll then
        lastScrollVal = ctx.scrollFrame:GetVerticalScroll()
    end

    local numChoices = GetNumQuestChoices() or 0
    if numChoices < 2 then return end

    local profile = ResolveActiveRewardProfile()
    local candidates = {}
    local maxVendorPrice, minVendorPrice = 0, nil
    local hasUncached = false
    local missingButtons = false

    for i = 1, numChoices do
        local link = GetQuestItemLink and GetQuestItemLink("choice", i)
        local stackCount, qItemID = 1, nil
        if type(GetQuestItemInfo) == "function" then
            local okQ, _, _, numItems, _, _, itemID = pcall(GetQuestItemInfo, "choice", i)
            if okQ then
                if type(numItems) == "number" and numItems > 1 then
                    stackCount = numItems
                end
                if type(itemID) == "number" and itemID > 0 then
                    qItemID = itemID
                end
            end
        end
        if not qItemID and type(link) == "string" then
            qItemID = tonumber(link:match("item:(%d+)"))
        end
        local queryItem = link or (qItemID and ("item:" .. qItemID)) or nil

        local sellPrice = 0
        if queryItem then
            local itemName, itemLink, _, _, _, _, _, _, _, _, vPrice = SafeGetItemInfo(queryItem)
            if not itemName then
                hasUncached = true
                if qItemID and RequestLoadItemDataByIDCompat then
                    pcall(RequestLoadItemDataByIDCompat, qItemID)
                end
            else
                link = link or itemLink
                sellPrice = (tonumber(vPrice) or 0) * stackCount
            end
        elseif qItemID and RequestLoadItemDataByIDCompat then
            hasUncached = true
            pcall(RequestLoadItemDataByIDCompat, qItemID)
        end

        if sellPrice > maxVendorPrice then
            maxVendorPrice = sellPrice
        end
        if minVendorPrice == nil or sellPrice < minVendorPrice then
            minVendorPrice = sellPrice
        end

        local rankScore, isUpgrade, isEmptySlot, equipLoc, candScore
        local offSpecScore, offSpecLabel
        if link then
            rankScore, isUpgrade, isEmptySlot, equipLoc, candScore = EvaluateUpgradeCandidate(link, profile)
            if not rankScore then
                offSpecScore, offSpecLabel = EvaluateOffSpecForClass(link, profile)
            end
        end

        local btn = FindChoiceRewardButton(i, ctx)
        if not btn then
            missingButtons = true
        end

        candidates[i] = {
            index        = i,
            btn          = btn,
            link         = link,
            vendorPrice  = sellPrice,
            rankScore    = rankScore,
            candScore    = candScore or rankScore,
            isUpgrade    = isUpgrade == true,
            isEmptySlot  = isEmptySlot == true,
            equipLoc     = equipLoc,
            offSpecScore = offSpecScore,
            offSpecLabel = offSpecLabel,
        }
    end

    local canMarkMaxGold = (maxVendorPrice > 0) and (minVendorPrice == nil or maxVendorPrice > minVendorPrice)

    local bestSpecIdx, bestSpecScore = nil, nil
    for i = 1, numChoices do
        local c = candidates[i]
        if c.rankScore and (not bestSpecScore or c.rankScore > bestSpecScore) then
            bestSpecScore = c.rankScore
            bestSpecIdx = i
        end
    end

    for i = 1, numChoices do
        local c = candidates[i]
        local isMaxGold = canMarkMaxGold and (c.vendorPrice == maxVendorPrice)
        local tier = nil

        if i == bestSpecIdx then
            tier = "BEST_SPEC"
        elseif c.rankScore then
            tier = "SPEC_USABLE"
        elseif c.offSpecScore then
            tier = "CLASS_OFFSPEC"
        elseif isMaxGold then
            tier = "VENDOR"
        end

        if c.btn then
            ApplyRewardOverlay(c.btn, {
                tier         = tier,
                vendorPrice  = c.vendorPrice,
                isMaxGold    = isMaxGold,
                specName     = profile.specName,
                offSpecLabel = c.offSpecLabel,
                classTag     = profile.classTag,
                classDisplay = profile.classDisplay,
                isUpgrade    = c.isUpgrade,
            }, ctx)
        end
    end

    PositionSpecSelector(profile, ctx, candidates[1] and candidates[1].btn, candidates[2] and candidates[2].btn)

    if (hasUncached or missingButtons) and C_Timer and C_Timer.After then
        C_Timer.After(hasUncached and 0.18 or 0.08, function()
            if QuestFrame and not IsForbiddenObj(QuestFrame) and QuestFrame:IsVisible() then
                HighlightBestRewards()
            end
        end)
    end
end

function FP:RefreshQuestRewardHighlights()
    HighlightBestRewards()
end

function FP:ScheduleQuestRewardRefresh(delay)
    if rewardRefreshTimer then return end
    if C_Timer and C_Timer.After then
        rewardRefreshTimer = true
        C_Timer.After(delay or 0.02, function()
            rewardRefreshTimer = false
            HighlightBestRewards()
        end)
    else
        HighlightBestRewards()
    end
end

-------------------------------------------------------------------------------
-- Scroll Sync, Blizzard Frame Hooks & Events
-------------------------------------------------------------------------------
rewardOverlayHost:SetScript("OnUpdate", function(self, elapsed)
    self.accum = (self.accum or 0) + elapsed
    if self.accum < 0.06 then return end
    self.accum = 0

    local ctx = GetActiveQuestRewardContext()
    if not ctx then
        ClearRewardOverlays()
        return
    end

    local sf = ctx.scrollFrame
    if sf and sf.GetVerticalScroll then
        local scroll = sf:GetVerticalScroll()
        if scroll ~= lastScrollVal then
            lastScrollVal = scroll
            HighlightBestRewards()
        end
    end
end)

local rewardHooks = { hookDone = false }

local function EnsureQuestRewardHooks()
    -- Event-driven: quest rewards refresh strictly via Blizzard quest events without touching QuestFrame scripts
end

local rewardEvFrame = CreateFrame("Frame")
local function SafeRegister(evt)
    pcall(rewardEvFrame.RegisterEvent, rewardEvFrame, evt)
end

SafeRegister("PLAYER_LOGIN")
SafeRegister("PLAYER_ENTERING_WORLD")
SafeRegister("QUEST_COMPLETE")
SafeRegister("QUEST_DETAIL")
SafeRegister("QUEST_PROGRESS")
SafeRegister("QUEST_GREETING")
SafeRegister("QUEST_FINISHED")
SafeRegister("GET_ITEM_INFO_RECEIVED")
SafeRegister("ITEM_DATA_LOAD_RESULT")
SafeRegister("PLAYER_EQUIPMENT_CHANGED")
SafeRegister("PLAYER_SPECIALIZATION_CHANGED")
SafeRegister("ACTIVE_TALENT_GROUP_CHANGED")
SafeRegister("CHARACTER_POINTS_CHANGED")

rewardEvFrame:SetScript("OnEvent", function(_, event)
    if event == "QUEST_FINISHED" then
        ClearRewardOverlays()
    elseif event == "QUEST_COMPLETE" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_GREETING" then
        FP:ScheduleQuestRewardRefresh(0.02)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if QuestFrame and not IsForbiddenObj(QuestFrame) and QuestFrame:IsVisible() then
            FP:ScheduleQuestRewardRefresh(0.02)
        end
    else
        if QuestFrame and not IsForbiddenObj(QuestFrame) and QuestFrame:IsVisible() then
            FP:ScheduleQuestRewardRefresh(0.02)
        end
    end
end)
