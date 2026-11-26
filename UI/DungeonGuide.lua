-------------------------------------------------------------------------------
-- NexusKit - UI/DungeonGuide.lua
-- Contextual Dungeon & Raid Boss Tactics Frame (WoW Forever Lv 1-60):
-- Enlarged readable layout, level-range filter pills, live search across
-- dungeons/raids, bosses & notable gear drops, plus auto-open inside instances.
-------------------------------------------------------------------------------
local addonName, FP = ...

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local FRAME_W = 880
local FRAME_H = 600
local COLLAPSED_H = 30
local LIST_W = 280
local ROW_H = 38
local ROW_GAP = 4

local LEVEL_FILTERS = {
    { id = "all",   labelKey = "DUNGEON_LVL_ALL",  fallback = "All",     w = 64 },
    { id = "13-25", text = "13-25", w = 78 },
    { id = "26-40", text = "26-40", w = 78 },
    { id = "41-55", text = "41-55", w = 78 },
    { id = "56-60", text = "56-60", w = 78 },
    { id = "raid",  labelKey = "DUNGEON_LVL_RAID", fallback = "Raid 60", w = 96 },
}

local ROLE_STYLES = {
    {
        key = "summary",
        labelKey = "DUNGEON_ROLE_SUMMARY",
        fallback = "KEY MECHANICS",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        col = { 1.00, 0.82, 0.22 },
    },
    {
        key = "tank",
        labelKey = "DUNGEON_ROLE_TANK",
        fallback = "TANK",
        icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
        col = { 0.35, 0.72, 1.00 },
    },
    {
        key = "heal",
        labelKey = "DUNGEON_ROLE_HEAL",
        fallback = "HEALER",
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        col = { 0.25, 0.95, 0.55 },
    },
    {
        key = "dps",
        labelKey = "DUNGEON_ROLE_DPS",
        fallback = "DPS",
        icon = "Interface\\Icons\\Ability_DualWield",
        col = { 1.00, 0.45, 0.35 },
    },
}

local DROPS_STYLE = {
    key = "drops",
    labelKey = "DUNGEON_ROLE_DROPS",
    fallback = "NOTABLE DROPS / GEAR",
    icon = "Interface\\Icons\\INV_Box_01",
    col = { 0.78, 0.52, 1.00 },
}

local QUESTS_STYLE = {
    key = "quests",
    labelKey = "DUNGEON_ROLE_QUESTS",
    fallback = "DUNGEON QUESTS",
    icon = "Interface\\Icons\\INV_Misc_Note_01",
    col = { 1.00, 0.80, 0.28 },
}

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsGuideAutoEnabled()
    return GetSettings().enableDungeonGuide ~= false
end

local function IsGuideLocked()
    return GetSettings().locked == true
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local res = { pcall(fn, ...) }
    if not res[1] then return nil end
    for i = 2, #res do
        if issecretvalue and issecretvalue(res[i]) then
            res[i] = nil
        end
    end
    return unpack(res, 2)
end

local function SafeRegisterEvent(f, evt)
    pcall(f.RegisterEvent, f, evt)
end

local function TrimQuery(str)
    if type(str) ~= "string" then return "" end
    return str:match("^%s*(.-)%s*$") or ""
end

local function PlainContainsFold(haystack, needle)
    if not IsSafeStr(haystack) or not IsSafeStr(needle) then return false end
    return string.find(string.lower(haystack), string.lower(needle), 1, true) ~= nil
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
local activeGuide = nil
local selectedBossIdx = 1
local targetedBossIdx = nil
local manualBrowseMode = false
local isCollapsed = false
local currentInstanceRunKey = nil
local lastInstanceRunKey = nil
local dismissedRunKey = nil
local openedRunKeys = {}
local defeatedBossMap = {}

local searchQuery = ""
local activeLevelFilter = "all"
local currentSearchResults = {}
local selectedSearchIndex = nil
local selectedSearchKind = nil
local selectedSearchQuestName = nil

-------------------------------------------------------------------------------
-- Main Floating Window
-------------------------------------------------------------------------------
local frame = CreateFrame("Frame", "NexusKitDungeonFrame", UIParent, "BackdropTemplate")
frame:SetSize(FRAME_W, FRAME_H)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
if frame.SetDontSavePosition then
    frame:SetDontSavePosition(true)
end
frame:SetFrameStrata("MEDIUM")
frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
frame:SetBackdropColor(0.05, 0.06, 0.09, 0.97)
frame:SetBackdropBorderColor(0.28, 0.32, 0.40, 1)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
_G["NexusKitDungeonFrame"] = frame
if type(UISpecialFrames) == "table" then
    local exists = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "NexusKitDungeonFrame" then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(UISpecialFrames, "NexusKitDungeonFrame")
    end
end

-------------------------------------------------------------------------------
-- Persistent Defeated Boss State
-------------------------------------------------------------------------------
local function GetDefeatedKey(guideId, bossName)
    local gId = guideId or (activeGuide and activeGuide.id) or "UNKNOWN"
    return tostring(gId) .. ":" .. string.lower(bossName or "")
end

local function GetPersistentDefeatedTable()
    if type(NexusKitCharDB) ~= "table" then return nil end
    if not NexusKitCharDB.defeatedBosses then
        NexusKitCharDB.defeatedBosses = {}
    end
    local runKey = currentInstanceRunKey or lastInstanceRunKey or (activeGuide and activeGuide.id) or "global"
    if not NexusKitCharDB.defeatedBosses[runKey] then
        NexusKitCharDB.defeatedBosses[runKey] = {}
    end
    return NexusKitCharDB.defeatedBosses[runKey]
end

local function IsBossDefeated(guide, boss)
    if not guide or not boss then return false end
    local bKey = GetDefeatedKey(guide.id, boss.name)
    if defeatedBossMap[bKey] then return true end
    local pTable = GetPersistentDefeatedTable()
    if pTable and pTable[bKey] then
        defeatedBossMap[bKey] = true
        return true
    end
    return false
end

local function SetBossDefeated(guide, boss, isDefeated)
    if not guide or not boss then return end
    local bKey = GetDefeatedKey(guide.id, boss.name)
    defeatedBossMap[bKey] = isDefeated and true or nil
    local pTable = GetPersistentDefeatedTable()
    if pTable then
        pTable[bKey] = isDefeated and true or nil
    end
    if frame and frame:IsShown() and FP.RefreshDungeonGuide then
        FP:RefreshDungeonGuide()
    end
end

local function ToggleBossDefeated(guide, boss)
    local cur = IsBossDefeated(guide, boss)
    SetBossDefeated(guide, boss, not cur)
end

local function SaveDungeonPosition()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local left, top = frame:GetLeft(), frame:GetTop()
    if IsSafeNum(left) and IsSafeNum(top) then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        NexusKitDB.settings.dungeonPos = { x = left, y = top }
    end
end

local function ApplyDungeonPosition()
    local pos = GetSettings().dungeonPos
    if type(pos) == "table" and IsSafeNum(pos.x) and IsSafeNum(pos.y) then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    else
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    end
end

frame:SetScript("OnDragStart", function(self)
    if not IsGuideLocked() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveDungeonPosition()
end)

-------------------------------------------------------------------------------
-- Window Title Header
-------------------------------------------------------------------------------
local function BuildWindowHeader()
    local headerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    headerBg:SetPoint("TOPLEFT", 3, -3)
    headerBg:SetPoint("TOPRIGHT", -3, -3)
    headerBg:SetHeight(28)
    headerBg:SetColorTexture(0.10, 0.12, 0.18, 0.95)

    local hLine = frame:CreateTexture(nil, "BORDER")
    hLine:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 0, 0)
    hLine:SetPoint("TOPRIGHT", headerBg, "BOTTOMRIGHT", 0, 0)
    hLine:SetHeight(1)
    hLine:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.45)

    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(20, 20)
    logo:SetPoint("TOPLEFT", 10, -6)
    logo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

    local tText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tText:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    tText:SetPoint("RIGHT", frame, "RIGHT", -96, 0)
    tText:SetJustifyH("LEFT")
    tText:SetWordWrap(false)
    tText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

    local cBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    cBtn:SetSize(20, 20)
    cBtn:SetPoint("TOPRIGHT", -5, -5)

    local mBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    mBtn:SetSize(18, 18)
    mBtn:SetPoint("RIGHT", cBtn, "LEFT", -3, 0)
    mBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    mBtn:SetBackdropColor(0.12, 0.14, 0.20, 0.95)
    mBtn:SetBackdropBorderColor(0.30, 0.34, 0.44, 0.95)
    local minLbl = mBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLbl:SetPoint("CENTER", 0, 1)
    minLbl:SetText("-")
    mBtn.label = minLbl

    local lBtn = CreateFrame("Button", nil, frame)
    lBtn:SetSize(19, 19)
    lBtn:SetPoint("RIGHT", mBtn, "LEFT", -4, 0)
    lBtn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")

    return hLine, tText, cBtn, mBtn, lBtn
end

local headerLine, titleText, closeBtn, minBtn, lockBtn = BuildWindowHeader()

local function UpdateLockIcon()
    if IsGuideLocked() then
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
        lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-Locked-Down")
    else
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
        lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-Unlocked-Down")
    end
    if FP.CropButtonTextures then
        FP:CropButtonTextures(lockBtn, 0.15)
    end
end

lockBtn:SetScript("OnClick", function()
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings.locked = not NexusKitDB.settings.locked
        UpdateLockIcon()
        if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
        if FP.RefreshTracker then FP:RefreshTracker() end
    end
end)

-------------------------------------------------------------------------------
-- Body Container + Search Bar + Level Filter Pills
-------------------------------------------------------------------------------
local bodyFrame = CreateFrame("Frame", nil, frame)
bodyFrame:SetPoint("TOPLEFT", 12, -37)
bodyFrame:SetPoint("BOTTOMRIGHT", -12, 12)

local function BuildSearchControls()
    local searchWrap = CreateFrame("Frame", nil, bodyFrame, "BackdropTemplate")
    searchWrap:SetSize(338, 28)
    searchWrap:SetPoint("TOPLEFT", 0, 0)
    searchWrap:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    searchWrap:SetBackdropColor(0.08, 0.10, 0.15, 0.96)
    searchWrap:SetBackdropBorderColor(0.28, 0.33, 0.43, 0.95)

    local sIcon = searchWrap:CreateTexture(nil, "ARTWORK")
    sIcon:SetSize(16, 16)
    sIcon:SetPoint("LEFT", 8, 0)
    sIcon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    sIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local clrBtn = CreateFrame("Button", nil, searchWrap, "BackdropTemplate")
    clrBtn:SetSize(20, 20)
    clrBtn:SetPoint("RIGHT", -5, 0)
    clrBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    clrBtn:SetBackdropColor(0.15, 0.18, 0.25, 0.95)
    clrBtn:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.9)
    clrBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText((FP.L and FP.L["DUNGEON_SEARCH_CLEAR"]) or "Clear", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    clrBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.9)
        if GameTooltip then GameTooltip:Hide() end
    end)
    local xLbl = clrBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLbl:SetPoint("CENTER", 0, 0)
    xLbl:SetText("x")
    xLbl:SetTextColor(0.90, 0.92, 0.96, 1)
    clrBtn:Hide()

    local sBox = CreateFrame("EditBox", "NexusKitDungeonSearchBox", searchWrap)
    sBox:SetAutoFocus(false)
    sBox:SetFontObject("GameFontHighlight")
    sBox:SetPoint("LEFT", sIcon, "RIGHT", 7, 0)
    sBox:SetPoint("RIGHT", clrBtn, "LEFT", -6, 0)
    sBox:SetHeight(24)
    sBox:SetTextColor(0.96, 0.98, 1.00, 1)
    sBox:SetMaxLetters(64)

    local sHolder = searchWrap:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sHolder:SetPoint("LEFT", sBox, "LEFT", 1, 0)
    sHolder:SetPoint("RIGHT", sBox, "RIGHT", -2, 0)
    sHolder:SetJustifyH("LEFT")
    sHolder:SetWordWrap(false)
    sHolder:SetTextColor(0.55, 0.62, 0.72, 0.95)

    sBox:SetScript("OnEditFocusGained", function()
        searchWrap:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
    end)
    sBox:SetScript("OnEditFocusLost", function()
        searchWrap:SetBackdropBorderColor(0.28, 0.33, 0.43, 0.95)
    end)

    return sBox, sHolder, clrBtn
end

local searchBox, searchPlaceholder, clearSearchBtn = BuildSearchControls()

local function BuildLevelPills()
    local pills = {}
    local prevAnchor = nil
    for i = #LEVEL_FILTERS, 1, -1 do
        local def = LEVEL_FILTERS[i]
        local b = CreateFrame("Button", nil, bodyFrame, "BackdropTemplate")
        b:SetSize(def.w, 28)
        if not prevAnchor then
            b:SetPoint("TOPRIGHT", bodyFrame, "TOPRIGHT", 0, 0)
        else
            b:SetPoint("RIGHT", prevAnchor, "LEFT", -4, 0)
        end
        b:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER", 0, 0)
        b.label = lbl
        b.filterDef = def
        prevAnchor = b
        pills[i] = b
    end
    return pills
end

local levelPills = BuildLevelPills()

local function RefreshLevelPillStyles()
    local L = FP.L or {}
    for _, b in ipairs(levelPills) do
        local def = b.filterDef
        local active = (def.id == activeLevelFilter)
        local txt = def.labelKey and (L[def.labelKey] or def.fallback) or def.text
        b.label:SetText(txt)
        if active then
            b:SetBackdropColor(ACCENT.r * 0.22, ACCENT.g * 0.22, ACCENT.b * 0.22, 0.98)
            b:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            b.label:SetTextColor(1, 1, 1, 1)
        else
            b:SetBackdropColor(0.10, 0.12, 0.18, 0.94)
            b:SetBackdropBorderColor(0.26, 0.30, 0.40, 0.92)
            b.label:SetTextColor(0.74, 0.80, 0.90, 1)
        end
    end
end

-------------------------------------------------------------------------------
-- Instance Selector Row + Overview Banner
-------------------------------------------------------------------------------
local kindPill = CreateFrame("Frame", nil, bodyFrame, "BackdropTemplate")
kindPill:SetSize(246, 30)
kindPill:SetPoint("TOPRIGHT", 0, -34)
kindPill:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
kindPill:SetBackdropColor(0.10, 0.12, 0.18, 0.95)
kindPill:SetBackdropBorderColor(0.28, 0.32, 0.42, 0.95)

local kindBadge = kindPill:CreateFontString(nil, "OVERLAY", "GameFontNormal")
kindBadge:SetPoint("LEFT", 10, 0)
kindBadge:SetPoint("RIGHT", -10, 0)
kindBadge:SetJustifyH("CENTER")
kindBadge:SetWordWrap(false)

local instBtn = CreateFrame("Button", nil, bodyFrame, "BackdropTemplate")
instBtn:SetHeight(30)
instBtn:SetPoint("TOPLEFT", 0, -34)
instBtn:SetPoint("RIGHT", kindPill, "LEFT", -8, 0)
instBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
instBtn:SetBackdropColor(0.11, 0.14, 0.20, 0.96)
instBtn:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.95)

local instAccent = instBtn:CreateTexture(nil, "OVERLAY")
instAccent:SetSize(3, 30)
instAccent:SetPoint("LEFT", 0, 0)
instAccent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)

local instBtnText = instBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
instBtnText:SetPoint("LEFT", 12, 0)
instBtnText:SetPoint("RIGHT", -96, 0)
instBtnText:SetJustifyH("LEFT")
instBtnText:SetWordWrap(false)

local instCountText = instBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
instCountText:SetPoint("RIGHT", -24, 0)
instCountText:SetJustifyH("RIGHT")
instCountText:SetTextColor(0.68, 0.76, 0.88, 1)

local instArrow = instBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
instArrow:SetPoint("RIGHT", -9, 0)
instArrow:SetText("v")

instBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.15, 0.19, 0.27, 0.98)
    self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
end)
instBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.11, 0.14, 0.20, 0.96)
    self:SetBackdropBorderColor(0.32, 0.36, 0.46, 0.95)
end)

local overviewBox = CreateFrame("Frame", nil, bodyFrame, "BackdropTemplate")
overviewBox:SetHeight(48)
overviewBox:SetPoint("TOPLEFT", instBtn, "BOTTOMLEFT", 0, -6)
overviewBox:SetPoint("RIGHT", bodyFrame, "RIGHT", 0, 0)
overviewBox:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
overviewBox:SetBackdropColor(0.08, 0.10, 0.15, 0.92)
overviewBox:SetBackdropBorderColor(0.22, 0.26, 0.34, 0.92)

local ovAccent = overviewBox:CreateTexture(nil, "OVERLAY")
ovAccent:SetWidth(3)
ovAccent:SetPoint("TOPLEFT", 0, 0)
ovAccent:SetPoint("BOTTOMLEFT", 0, 0)
ovAccent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)

local overviewText = overviewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
overviewText:SetPoint("TOPLEFT", 12, -5)
overviewText:SetJustifyH("LEFT")
overviewText:SetJustifyV("MIDDLE")
overviewText:SetWordWrap(true)

local entranceBtn = CreateFrame("Button", "NexusKitDungeonEntranceBtn", overviewBox, "BackdropTemplate")
entranceBtn:SetSize(160, 32)
entranceBtn:SetPoint("RIGHT", overviewBox, "RIGHT", -8, 0)
entranceBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
entranceBtn:SetBackdropColor(0.12, 0.16, 0.24, 0.95)
entranceBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)

local entIcon = entranceBtn:CreateTexture(nil, "ARTWORK")
entIcon:SetSize(18, 18)
entIcon:SetPoint("LEFT", 6, 0)
entIcon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalIronForge")

local entTxt = entranceBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
entTxt:SetPoint("LEFT", entIcon, "RIGHT", 5, 0)
entTxt:SetPoint("RIGHT", -4, 0)
entTxt:SetJustifyH("LEFT")
entTxt:SetText("🧭 Freccia Entrata")
entTxt:SetTextColor(1, 0.92, 0.45, 1)

entranceBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.18, 0.24, 0.36, 1)
    self:SetBackdropBorderColor(1, 1, 1, 1)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Guida all'Entrata (Freccia 3D)", 1, 0.82, 0)
        local ent = activeGuide and FP.GetDungeonEntrance and FP:GetDungeonEntrance(activeGuide.id)
        if ent then
            if ent.zoneName then
                GameTooltip:AddLine("Zona: |cffffffff" .. ent.zoneName .. "|r", 0.9, 0.9, 0.9)
            end
            if ent.x and ent.y then
                GameTooltip:AddLine(string.format("Coordinate: |cff00ff96%.1f, %.1f|r", ent.x, ent.y), 0.8, 0.8, 0.8)
            end
            if ent.desc and ent.desc ~= "" then
                GameTooltip:AddLine("Dettagli: |cffffd100" .. ent.desc .. "|r", 1, 1, 1, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff96Clicca per attivare la freccia 3D e impostare il waypoint!|r", 0.2, 1, 0.2)
        else
            GameTooltip:AddLine("Coordinate ingresso non disponibili.", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end
end)
entranceBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.16, 0.24, 0.95)
    self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
end)
entranceBtn:SetScript("OnClick", function(self)
    if not activeGuide then return end
    local ent = FP.GetDungeonEntrance and FP:GetDungeonEntrance(activeGuide.id)
    if ent and ent.x and ent.y and FP.SetCustomWaypoint then
        local label = "Entrata " .. (activeGuide.name or "Dungeon")
        FP:SetCustomWaypoint(ent.x, ent.y, label, ent.mapID)
        if WorldMapFrame and WorldMapFrame.SetMapID and ent.mapID then
            pcall(WorldMapFrame.SetMapID, WorldMapFrame, ent.mapID)
        end
        local locStr = ent.zoneName and string.format("%s (%.1f, %.1f)", ent.zoneName, ent.x, ent.y) or string.format("%.1f, %.1f", ent.x, ent.y)
        FP:Print("Freccia 3D attivata verso l'entrata di " .. (activeGuide.name or "Dungeon") .. " a " .. locStr .. "!")
    else
        FP:Print("Coordinate entrata non disponibili per questo dungeon.")
    end
end)

overviewText:SetPoint("BOTTOMRIGHT", entranceBtn, "LEFT", -10, 0)

-------------------------------------------------------------------------------
-- Left Sidebar: Bosses or Search Results
-------------------------------------------------------------------------------
local listFrame = CreateFrame("Frame", nil, bodyFrame, "BackdropTemplate")
listFrame:SetWidth(LIST_W)
listFrame:SetPoint("TOPLEFT", overviewBox, "BOTTOMLEFT", 0, -8)
listFrame:SetPoint("BOTTOMLEFT", bodyFrame, "BOTTOMLEFT", 0, 0)
listFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
listFrame:SetBackdropColor(0.07, 0.08, 0.12, 0.92)
listFrame:SetBackdropBorderColor(0.22, 0.25, 0.33, 0.95)

local function BuildListHeader()
    local listHdrBg = listFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    listHdrBg:SetPoint("TOPLEFT", 1, -1)
    listHdrBg:SetPoint("TOPRIGHT", -1, -1)
    listHdrBg:SetHeight(24)
    listHdrBg:SetColorTexture(0.11, 0.13, 0.19, 0.95)

    local listHdrLine = listFrame:CreateTexture(nil, "BORDER")
    listHdrLine:SetPoint("TOPLEFT", listHdrBg, "BOTTOMLEFT", 0, 0)
    listHdrLine:SetPoint("TOPRIGHT", listHdrBg, "BOTTOMRIGHT", 0, 0)
    listHdrLine:SetHeight(1)
    listHdrLine:SetColorTexture(0.24, 0.28, 0.36, 0.90)

    local hdrTxt = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdrTxt:SetPoint("LEFT", listHdrBg, "LEFT", 9, 0)
    hdrTxt:SetPoint("RIGHT", listHdrBg, "RIGHT", -9, 0)
    hdrTxt:SetJustifyH("LEFT")
    hdrTxt:SetTextColor(0.80, 0.86, 0.96, 1)
    return hdrTxt
end

local listHdrText = BuildListHeader()

local bossScroll = CreateFrame("ScrollFrame", "NexusKitDungeonBossScroll", listFrame, "UIPanelScrollFrameTemplate")
bossScroll:SetPoint("TOPLEFT", 5, -29)
bossScroll:SetPoint("BOTTOMRIGHT", -24, 5)
local bossScrollChild = CreateFrame("Frame", nil, bossScroll)
bossScrollChild:SetSize(LIST_W - 29, 1)
bossScroll:SetScrollChild(bossScrollChild)

local emptySearchText = listFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
emptySearchText:SetPoint("LEFT", 16, 0)
emptySearchText:SetPoint("RIGHT", -24, 0)
emptySearchText:SetJustifyH("CENTER")
emptySearchText:SetWordWrap(true)
emptySearchText:SetTextColor(0.65, 0.72, 0.82, 1)
emptySearchText:Hide()

-------------------------------------------------------------------------------
-- Right Detail Pane: Header + Action Footer + Scrollable Role & Drops Cards
-------------------------------------------------------------------------------
local detailFrame = CreateFrame("Frame", nil, bodyFrame, "BackdropTemplate")
detailFrame:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 8, 0)
detailFrame:SetPoint("BOTTOMRIGHT", bodyFrame, "BOTTOMRIGHT", 0, 0)
detailFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
detailFrame:SetBackdropColor(0.07, 0.09, 0.13, 0.94)
detailFrame:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.95)

local function BuildDetailChrome()
    local detailHdrBg = detailFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    detailHdrBg:SetPoint("TOPLEFT", 1, -1)
    detailHdrBg:SetPoint("TOPRIGHT", -1, -1)
    detailHdrBg:SetHeight(50)
    detailHdrBg:SetColorTexture(0.10, 0.13, 0.19, 0.95)

    local dHdrLine = detailFrame:CreateTexture(nil, "BORDER")
    dHdrLine:SetPoint("TOPLEFT", detailHdrBg, "BOTTOMLEFT", 0, 0)
    dHdrLine:SetPoint("TOPRIGHT", detailHdrBg, "BOTTOMRIGHT", 0, 0)
    dHdrLine:SetHeight(1)
    dHdrLine:SetColorTexture(0.25, 0.29, 0.38, 0.95)

    local bHdr = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    bHdr:SetPoint("TOPLEFT", 14, -6)
    bHdr:SetPoint("RIGHT", detailFrame, "RIGHT", -150, 0)
    bHdr:SetJustifyH("LEFT")
    bHdr:SetWordWrap(false)

    local bSt = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bSt:SetPoint("TOPLEFT", bHdr, "BOTTOMLEFT", 0, -2)
    bSt:SetPoint("RIGHT", detailFrame, "RIGHT", -150, 0)
    bSt:SetJustifyH("LEFT")
    bSt:SetWordWrap(false)

    local fLine = detailFrame:CreateTexture(nil, "BORDER")
    fLine:SetPoint("BOTTOMLEFT", 1, 36)
    fLine:SetPoint("BOTTOMRIGHT", -1, 36)
    fLine:SetHeight(1)
    fLine:SetColorTexture(0.22, 0.26, 0.34, 0.90)

    return dHdrLine, bHdr, bSt, fLine
end

local detailHdrLine, bossHeader, bossStatus, footerLine = BuildDetailChrome()

local function CreateSmallActionBtn(parent, w, labelFallback, isAccent)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, 25)
    b:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b.isAccent = isAccent
    local function SetNormalColors(self)
        if self.isAccent then
            self:SetBackdropColor(ACCENT.r * 0.16, ACCENT.g * 0.16, ACCENT.b * 0.16, 0.96)
            self:SetBackdropBorderColor(ACCENT.r * 0.85, ACCENT.g * 0.85, ACCENT.b * 0.85, 0.95)
        else
            self:SetBackdropColor(0.12, 0.15, 0.21, 0.96)
            self:SetBackdropBorderColor(0.30, 0.34, 0.44, 0.95)
        end
    end
    SetNormalColors(b)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.22, 0.30, 0.98)
        self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    end)
    b:SetScript("OnLeave", SetNormalColors)
    b.refreshStyle = SetNormalColors

    local lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("CENTER", 0, 0)
    lbl:SetText(labelFallback)
    b.label = lbl
    return b
end

local bossDefeatedToggleBtn = CreateSmallActionBtn(detailFrame, 138, "Segna Sconfitto", false)
bossDefeatedToggleBtn:SetPoint("TOPRIGHT", detailFrame, "TOPRIGHT", -12, -10)
bossDefeatedToggleBtn:SetHeight(28)
bossDefeatedToggleBtn:SetScript("OnClick", function()
    if activeGuide and activeGuide.bosses and activeGuide.bosses[selectedBossIdx] then
        ToggleBossDefeated(activeGuide, activeGuide.bosses[selectedBossIdx])
    end
end)
bossDefeatedToggleBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.18, 0.22, 0.30, 0.98)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText("Stato Scontro Boss", 1, 1, 1)
        GameTooltip:AddLine("Clicca per contrassegnare questo boss come sconfitto o non sconfitto per questa run.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end
end)
bossDefeatedToggleBtn:SetScript("OnLeave", function(self)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
    if self.refreshStyle then self:refreshStyle() end
end)

local prevBtn = CreateSmallActionBtn(detailFrame, 88, "< Prev", false)
prevBtn:SetPoint("BOTTOMLEFT", 12, 6)

local nextBtn = CreateSmallActionBtn(detailFrame, 88, "Next >", false)
nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)

local announceBtn = CreateSmallActionBtn(detailFrame, 176, "Send to Chat", true)
announceBtn:SetPoint("BOTTOMRIGHT", -12, 6)

local footerCounter = detailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
footerCounter:SetPoint("LEFT", nextBtn, "RIGHT", 8, 0)
footerCounter:SetPoint("RIGHT", announceBtn, "LEFT", -8, 0)
footerCounter:SetJustifyH("CENTER")
footerCounter:SetTextColor(0.75, 0.80, 0.90, 1)

local detailScroll = CreateFrame("ScrollFrame", "NexusKitDungeonDetailScroll", detailFrame, "UIPanelScrollFrameTemplate")
detailScroll:SetPoint("TOPLEFT", detailHdrLine, "BOTTOMLEFT", 10, -8)
detailScroll:SetPoint("BOTTOMRIGHT", footerLine, "TOPRIGHT", -24, 6)

local INIT_CARD_W = FRAME_W - 24 - LIST_W - 8 - 38
local detailChild = CreateFrame("Frame", nil, detailScroll)
detailChild:SetSize(INIT_CARD_W, 1)
detailScroll:SetScrollChild(detailChild)

local function BuildCardWidget(parent, st)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.05, 0.06, 0.09, 0.92)
    card:SetBackdropBorderColor(st.col[1] * 0.45, st.col[2] * 0.45, st.col[3] * 0.45, 0.80)

    local leftBar = card:CreateTexture(nil, "OVERLAY")
    leftBar:SetWidth(4)
    leftBar:SetPoint("TOPLEFT", 1, -1)
    leftBar:SetPoint("BOTTOMLEFT", 1, 1)
    leftBar:SetColorTexture(st.col[1], st.col[2], st.col[3], 0.95)

    local hdrStrip = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    hdrStrip:SetHeight(26)
    hdrStrip:SetPoint("TOPLEFT", 5, -1)
    hdrStrip:SetPoint("TOPRIGHT", -1, -1)
    hdrStrip:SetColorTexture(st.col[1] * 0.14, st.col[2] * 0.14, st.col[3] * 0.14, 0.88)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 10, -5)
    icon:SetTexture(st.icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local tag = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tag:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    tag:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    tag:SetJustifyH("LEFT")
    tag:SetTextColor(st.col[1], st.col[2], st.col[3], 1)

    local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -32)
    body:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)

    return { style = st, card = card, tag = tag, body = body }
end

local roleCards = {}
for i, st in ipairs(ROLE_STYLES) do
    roleCards[i] = BuildCardWidget(detailChild, st)
end
local dropsCard = BuildCardWidget(detailChild, DROPS_STYLE)
local questsCard = BuildCardWidget(detailChild, QUESTS_STYLE)

-------------------------------------------------------------------------------
-- Instance Picker Popup (Filtered by activeLevelFilter)
-------------------------------------------------------------------------------
local picker = CreateFrame("Frame", "NexusKitDungeonPicker", frame, "BackdropTemplate")
picker:SetSize(480, 440)
picker:SetPoint("TOPLEFT", instBtn, "BOTTOMLEFT", 0, -2)
picker:SetFrameStrata(frame:GetFrameStrata())
picker:SetFrameLevel(frame:GetFrameLevel() + 25)
picker:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
picker:SetBackdropColor(0.05, 0.06, 0.09, 0.98)
picker:SetBackdropBorderColor(0.32, 0.36, 0.45, 1)
picker:EnableMouse(true)
picker:Hide()

local pickerCloser = CreateFrame("Button", "NexusKitDungeonPickerCloser", frame)
pickerCloser:SetFrameStrata(frame:GetFrameStrata())
pickerCloser:SetFrameLevel(math.max(1, frame:GetFrameLevel() + 24))
pickerCloser:SetAllPoints(UIParent)
pickerCloser:EnableMouse(true)
pickerCloser:RegisterForClicks("LeftButtonDown", "RightButtonDown")
pickerCloser:SetScript("OnClick", function()
    picker:Hide()
end)
pickerCloser:Hide()

local function HandlePickerMouseWheel(delta)
    if not pickerScroll then return end
    local cur = pickerScroll:GetVerticalScroll() or 0
    local step = 56
    local maxScroll = pickerScroll:GetVerticalScrollRange() or 0
    local newScroll = math.max(0, math.min(maxScroll, cur - (delta * step)))
    pickerScroll:SetVerticalScroll(newScroll)
end

picker:EnableMouseWheel(true)
picker:SetScript("OnMouseWheel", function(_, delta) HandlePickerMouseWheel(delta) end)

local pickerScroll = CreateFrame("ScrollFrame", "NexusKitDungeonPickerScroll", picker, "UIPanelScrollFrameTemplate")
pickerScroll:SetPoint("TOPLEFT", 8, -8)
pickerScroll:SetPoint("BOTTOMRIGHT", -28, 8)
pickerScroll:EnableMouseWheel(true)
pickerScroll:SetScript("OnMouseWheel", function(_, delta) HandlePickerMouseWheel(delta) end)
local pickerChild = CreateFrame("Frame", nil, pickerScroll)
pickerChild:SetSize(440, 1)
pickerScroll:SetScrollChild(pickerChild)

local pickerRows = {}
local function GetOrCreatePickerRow(idx)
    if pickerRows[idx] then return pickerRows[idx] end
    local r = CreateFrame("Button", nil, pickerChild, "BackdropTemplate")
    r:SetHeight(26)
    r:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    r:EnableMouseWheel(true)
    r:SetScript("OnMouseWheel", function(_, delta) HandlePickerMouseWheel(delta) end)
    local txt = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("LEFT", 10, 0)
    txt:SetPoint("RIGHT", -10, 0)
    txt:SetJustifyH("LEFT")
    txt:SetWordWrap(false)
    r.text = txt
    r:SetScript("OnEnter", function(self)
        if not self.isHeader then
            self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
        end
    end)
    r:SetScript("OnLeave", function(self)
        if not self.isHeader then
            local sel = (activeGuide and self.guideID == activeGuide.id)
            self:SetBackdropBorderColor(sel and ACCENT.r or 0.18, sel and ACCENT.g or 0.21, sel and ACCENT.b or 0.27, sel and 0.95 or 0.55)
        end
    end)
    r:SetScript("OnClick", function(self)
        if self.isHeader or not self.guideID then return end
        local g = FP.DUNGEON_GUIDES and FP.DUNGEON_GUIDES[self.guideID]
        if g then
            activeGuide = g
            selectedBossIdx = 1
            targetedBossIdx = nil
            selectedSearchIndex = nil
            selectedSearchKind = nil
            selectedSearchQuestName = nil
            searchQuery = ""
            searchBox:SetText("")
            searchBox:ClearFocus()
            manualBrowseMode = true
            picker:Hide()
            bossScroll:SetVerticalScroll(0)
            detailScroll:SetVerticalScroll(0)
            FP:RefreshDungeonGuide()
        end
    end)
    pickerRows[idx] = r
    return r
end

local function PopulateInstancePicker()
    local L = FP.L or {}
    local list = (FP.GetSortedDungeonList and FP:GetSortedDungeonList(activeLevelFilter)) or {}
    local entries = {}
    local lastGroup = nil
    for _, g in ipairs(list) do
        local isNew = g.isNew and true or false
        local kind = g.kind or "party"
        local grpKey = (isNew and "fw_" or "cl_") .. kind
        if grpKey ~= lastGroup then
            lastGroup = grpKey
            local hdrText
            if isNew then
                hdrText = (kind == "raid")
                    and (L["DUNGEON_GRP_FW_RAID"] or "WoW Forever Raids (60)")
                    or  (L["DUNGEON_GRP_FW_PARTY"] or "WoW Forever Dungeons (13-60)")
            else
                hdrText = (kind == "raid")
                    and (L["DUNGEON_GRP_C_RAID"] or "Classic Raids (60)")
                    or  (L["DUNGEON_GRP_C_PARTY"] or "Classic Dungeons (13-60)")
            end
            entries[#entries + 1] = { isHeader = true, label = hdrText }
        end
        local name = FP.GetDungeonDisplayName and FP:GetDungeonDisplayName(g) or g.name
        local lvl = (g.minLvl == g.maxLvl) and tostring(g.minLvl) or (tostring(g.minLvl) .. "-" .. tostring(g.maxLvl))
        entries[#entries + 1] = {
            isHeader = false,
            guideID = g.id,
            isNew = isNew,
            label = string.format("[%s] %s", lvl, name),
        }
    end

    local y = 0
    for idx, e in ipairs(entries) do
        local row = GetOrCreatePickerRow(idx)
        row.isHeader = e.isHeader
        row.guideID = e.guideID
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", pickerChild, "TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", pickerChild, "RIGHT", 0, 0)
        row.text:SetText(e.label)
        if e.isHeader then
            row:SetBackdropColor(0.08, 0.10, 0.14, 0.65)
            row:SetBackdropBorderColor(0, 0, 0, 0)
            row.text:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        else
            local sel = (activeGuide and e.guideID == activeGuide.id)
            row:SetBackdropColor(sel and (ACCENT.r * 0.18) or 0.10, sel and (ACCENT.g * 0.18) or 0.12, sel and (ACCENT.b * 0.18) or 0.16, 0.94)
            row:SetBackdropBorderColor(sel and ACCENT.r or 0.18, sel and ACCENT.g or 0.21, sel and ACCENT.b or 0.27, sel and 0.95 or 0.55)
            row.text:SetTextColor(sel and 1 or 0.92, sel and 1 or 0.94, sel and 1 or 0.97, 1)
        end
        row:Show()
        y = y + 28
    end
    for i = #entries + 1, #pickerRows do
        pickerRows[i]:Hide()
    end
    pickerChild:SetHeight(math.max(1, y))
end

picker:HookScript("OnShow", function(self)
    self:SetFrameStrata(frame:GetFrameStrata())
    self:SetFrameLevel(frame:GetFrameLevel() + 25)
    pickerCloser:SetFrameStrata(frame:GetFrameStrata())
    pickerCloser:SetFrameLevel(math.max(1, frame:GetFrameLevel() + 24))
    pickerCloser:Show()
end)

picker:HookScript("OnHide", function()
    pickerCloser:Hide()
end)

instBtn:SetScript("OnClick", function()
    if picker:IsShown() then
        picker:Hide()
    else
        PopulateInstancePicker()
        if pickerScroll then
            pickerScroll:SetVerticalScroll(0)
        end
        picker:Show()
    end
end)

frame:HookScript("OnHide", function()
    picker:Hide()
    pickerCloser:Hide()
    if currentInstanceRunKey then
        dismissedRunKey = currentInstanceRunKey
    end
end)



-------------------------------------------------------------------------------
-- Dual-Mode Sidebar Row Pool (Boss List / Live Search Results)
-------------------------------------------------------------------------------
local bossButtons = {}
local function GetOrCreateBossBtn(idx)
    if bossButtons[idx] then return bossButtons[idx] end
    local b = CreateFrame("Button", nil, bossScrollChild, "BackdropTemplate")
    b:SetHeight(ROW_H)
    b:SetPoint("TOPLEFT", bossScrollChild, "TOPLEFT", 0, -((idx - 1) * (ROW_H + ROW_GAP)))
    b:SetPoint("RIGHT", bossScrollChild, "RIGHT", 0, 0)
    b:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local stripe = b:CreateTexture(nil, "OVERLAY")
    stripe:SetWidth(3)
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("BOTTOMLEFT", 1, 1)
    b.stripe = stripe

    local mainTxt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainTxt:SetPoint("TOPLEFT", 10, -5)
    mainTxt:SetPoint("RIGHT", -6, 0)
    mainTxt:SetJustifyH("LEFT")
    mainTxt:SetWordWrap(false)
    b.label = mainTxt

    local subTxt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subTxt:SetPoint("BOTTOMLEFT", 10, 4)
    subTxt:SetPoint("RIGHT", -6, 0)
    subTxt:SetJustifyH("LEFT")
    subTxt:SetWordWrap(false)
    b.subLabel = subTxt

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    b:SetScript("OnEnter", function(self)
        local active = self.searchIndex
            and (self.searchIndex == selectedSearchIndex)
            or  (self.bossIndex and self.bossIndex == selectedBossIdx)
        if not active then
            self:SetBackdropBorderColor(ACCENT.r * 0.75, ACCENT.g * 0.75, ACCENT.b * 0.75, 0.9)
        end
        if self.bossIndex and activeGuide and activeGuide.bosses and GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            local bData = activeGuide.bosses[self.bossIndex]
            if bData then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local isDef = IsBossDefeated(activeGuide, bData)
                GameTooltip:SetText(bData.name or "Boss", 1, 1, 1)
                if isDef then
                    GameTooltip:AddLine((FP.L and FP.L["DUNGEON_BOSS_DEFEATED"]) or "Sconfitto in questa run", 0.33, 0.93, 0.47)
                else
                    GameTooltip:AddLine("Non ancora sconfitto", 0.90, 0.75, 0.20)
                end
                GameTooltip:AddLine("Tasto Destro / Shift-Click: Segna come sconfitto / non sconfitto", 0.70, 0.70, 0.70)
                GameTooltip:Show()
            end
        end
    end)
    b:SetScript("OnLeave", function(self)
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
        local active = self.searchIndex
            and (self.searchIndex == selectedSearchIndex)
            or  (self.bossIndex and self.bossIndex == selectedBossIdx)
        if not active then
            local targeted = (not self.searchIndex and self.bossIndex == targetedBossIdx)
            self:SetBackdropBorderColor(
                targeted and 1.00 or 0.20,
                targeted and 0.72 or 0.22,
                targeted and 0.18 or 0.29,
                targeted and 0.95 or 0.78
            )
        end
    end)
    b:SetScript("OnClick", function(self, button)
        if (button == "RightButton" or (IsShiftKeyDown and IsShiftKeyDown())) and self.bossIndex and activeGuide and activeGuide.bosses then
            local bData = activeGuide.bosses[self.bossIndex]
            if bData then
                ToggleBossDefeated(activeGuide, bData)
                return
            end
        end
        if self.searchResult then
            local r = self.searchResult
            activeGuide = r.guide
            selectedBossIdx = r.bossIdx or 1
            targetedBossIdx = nil
            selectedSearchIndex = self.searchIndex
            selectedSearchKind = r.kind
            selectedSearchQuestName = (r.kind == "quest" and r.quest) and r.quest.name or nil
            manualBrowseMode = true
            detailScroll:SetVerticalScroll(0)
            FP:RefreshDungeonGuide()
        elseif self.bossIndex then
            selectedBossIdx = self.bossIndex
            selectedSearchIndex = nil
            selectedSearchKind = nil
            selectedSearchQuestName = nil
            detailScroll:SetVerticalScroll(0)
            FP:RefreshDungeonGuide()
        end
    end)
    bossButtons[idx] = b
    return b
end

local function SetRowTwoLineMode(row, twoLines)
    row.label:ClearAllPoints()
    if twoLines then
        row.label:SetPoint("TOPLEFT", 10, -4)
        row.label:SetPoint("RIGHT", -6, 0)
        row.subLabel:Show()
    else
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetPoint("RIGHT", -6, 0)
        row.subLabel:SetText("")
        row.subLabel:Hide()
    end
end

local function FormatSearchRowContent(r, L)
    local g = r.guide
    local instName = (FP.GetDungeonDisplayName and FP:GetDungeonDisplayName(g)) or g.name or ""
    local lvl = (g.minLvl == g.maxLvl) and tostring(g.minLvl or 60) or (tostring(g.minLvl or 1) .. "-" .. tostring(g.maxLvl or 60))
    if r.kind == "loot" and r.item then
        local tag = L["DUNGEON_MATCH_DROP"] or "Drop"
        local slot = IsSafeStr(r.item.slot) and (" (" .. r.item.slot .. ")") or ""
        local bossName = (r.boss and r.boss.name) or "Boss"
        return "|cff40ff99[" .. tag .. "]|r " .. (r.item.name or "?") .. "|cff9fb2cc" .. slot .. "|r",
               bossName .. "  •  " .. instName .. " (Lvl " .. lvl .. ")",
               0.25, 1.00, 0.60
    elseif r.kind == "boss" and r.boss then
        local tag = L["DUNGEON_MATCH_BOSS"] or "Boss"
        return "|cffffb020[" .. tag .. "]|r " .. (r.boss.name or "Boss"),
               instName .. "  (Lvl " .. lvl .. ")",
               1.00, 0.72, 0.18
    elseif r.kind == "quest" and r.quest then
        local q = r.quest
        local tag = L["DUNGEON_MATCH_QUEST"] or "Quest"
        local facTag = ""
        if q.faction == "Alliance" then
            facTag = "|cff4da6ff[A]|r "
        elseif q.faction == "Horde" then
            facTag = "|cffff5544[H]|r "
        end
        local logTag = ""
        if q.inLog then
            local statusStr = q.isComplete and (L["DUNGEON_QUEST_READY"] or "Ready to turn in") or (L["DUNGEON_QUEST_IN_LOG"] or "In Quest Log")
            logTag = "  |cff55ee77[" .. statusStr .. "]|r"
        end
        local qLvl = q.level and tostring(q.level) or lvl
        return "|cffffcc47[" .. tag .. "]|r " .. facTag .. (q.name or "?") .. logTag,
               instName .. "  (Lvl " .. qLvl .. ")",
               1.00, 0.80, 0.28
    else
        local isRaid = (r.kind == "raid")
        local tag = isRaid and (L["DUNGEON_MATCH_RAID"] or "Raid") or (L["DUNGEON_MATCH_DUNGEON"] or "Dungeon")
        local numB = (g.bosses and #g.bosses) or 0
        return "|cff33e6ff[" .. tag .. "]|r " .. instName,
               "Lvl " .. lvl .. "  •  " .. tostring(numB) .. " boss",
               0.20, 0.90, 1.00
    end
end

local function PopulateSidebarBossList(bosses, L)
    emptySearchText:Hide()
    listHdrText:SetText(string.format(L["DUNGEON_BOSSES_HDR"] or "BOSSES (%d)", #bosses))

    for i, b in ipairs(bosses) do
        local row = GetOrCreateBossBtn(i)
        row.bossIndex = i
        row.searchIndex = nil
        row.searchResult = nil
        SetRowTwoLineMode(row, false)

        local prefix = b.wing and ("[" .. b.wing .. "] ") or (i .. ". ")
        local isDead = IsBossDefeated(activeGuide, b)
        local isSelected = (i == selectedBossIdx)
        local isTargeted = (i == targetedBossIdx)

        local labelStr = prefix .. (b.name or "Boss")
        if isDead then
            labelStr = "|cff55ee77[OK]|r " .. labelStr
        end
        row.label:SetText(labelStr)

        if isSelected then
            row:SetBackdropColor(ACCENT.r * 0.19, ACCENT.g * 0.19, ACCENT.b * 0.19, 0.96)
            row:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
            row.stripe:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            row.stripe:Show()
            row.label:SetTextColor(1, 1, 1, 1)
        elseif isTargeted then
            row:SetBackdropColor(0.22, 0.16, 0.05, 0.92)
            row:SetBackdropBorderColor(1.00, 0.72, 0.18, 0.95)
            row.stripe:SetColorTexture(1.00, 0.72, 0.18, 1)
            row.stripe:Show()
            row.label:SetTextColor(1.00, 0.92, 0.65, 1)
        else
            row:SetBackdropColor(0.10, 0.12, 0.16, 0.88)
            row:SetBackdropBorderColor(0.20, 0.22, 0.29, 0.78)
            if isDead then
                row.stripe:SetColorTexture(0.33, 0.93, 0.47, 0.8)
                row.stripe:Show()
            else
                row.stripe:Hide()
            end
            row.label:SetTextColor(isDead and 0.65 or 0.86, isDead and 0.82 or 0.89, isDead and 0.68 or 0.94, 1)
        end
        row:Show()
    end
    for i = #bosses + 1, #bossButtons do
        bossButtons[i]:Hide()
    end
    bossScrollChild:SetHeight(math.max(1, #bosses * (ROW_H + ROW_GAP)))
end

local function PopulateSidebarSearchResults(results, L)
    listHdrText:SetText(string.format(L["DUNGEON_SEARCH_RESULTS_HDR"] or "RESULTS (%d)", #results))
    if #results == 0 then
        for i = 1, #bossButtons do
            bossButtons[i]:Hide()
        end
        bossScrollChild:SetHeight(1)
        emptySearchText:SetText(L["DUNGEON_NO_RESULTS"] or "No dungeon, boss or gear drop matched.")
        emptySearchText:Show()
        return
    end
    emptySearchText:Hide()

    for i, res in ipairs(results) do
        local row = GetOrCreateBossBtn(i)
        row.bossIndex = nil
        row.searchIndex = i
        row.searchResult = res
        SetRowTwoLineMode(row, true)

        local l1, l2, sr, sg, sb = FormatSearchRowContent(res, L)
        row.label:SetText(l1)
        row.subLabel:SetText(l2)

        local isSelected = (i == selectedSearchIndex)
            or (not selectedSearchIndex and activeGuide and res.guide == activeGuide and res.bossIdx == selectedBossIdx)
        if isSelected then
            row:SetBackdropColor(ACCENT.r * 0.20, ACCENT.g * 0.20, ACCENT.b * 0.20, 0.96)
            row:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
            row.stripe:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            row.label:SetTextColor(1, 1, 1, 1)
            row.subLabel:SetTextColor(0.84, 0.90, 0.98, 1)
        else
            row:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
            row:SetBackdropBorderColor(0.20, 0.22, 0.29, 0.80)
            row.stripe:SetColorTexture(sr, sg, sb, 0.85)
            row.label:SetTextColor(0.92, 0.95, 0.99, 1)
            row.subLabel:SetTextColor(0.64, 0.72, 0.84, 1)
        end
        row.stripe:Show()
        row:Show()
    end
    for i = #results + 1, #bossButtons do
        bossButtons[i]:Hide()
    end
    bossScrollChild:SetHeight(math.max(1, #results * (ROW_H + ROW_GAP)))
end

local dropRows = {}
local activeHoverDropRow = nil

local function HideDropRows()
    activeHoverDropRow = nil
    for _, r in ipairs(dropRows) do
        r.item = nil
        r:Hide()
    end
end

local function SetDropRowVisual(row, hovered)
    if hovered then
        row:SetBackdropColor(0.14, 0.16, 0.25, 0.92)
        row:SetBackdropBorderColor(DROPS_STYLE.col[1], DROPS_STYLE.col[2], DROPS_STYLE.col[3], 0.95)
    elseif row.isMatch then
        row:SetBackdropColor(0.06, 0.18, 0.12, 0.72)
        row:SetBackdropBorderColor(0.25, 0.95, 0.55, 0.55)
    else
        row:SetBackdropColor(0.08, 0.09, 0.14, 0.45)
        row:SetBackdropBorderColor(0.22, 0.25, 0.34, 0.30)
    end
end

local function GetDropQualityColor(quality)
    if IsSafeNum(quality) and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local c = ITEM_QUALITY_COLORS[quality]
        if c.hex then
            return c.hex, c.r, c.g, c.b
        end
        return string.format("|cff%02x%02x%02x", math.floor((c.r or 1) * 255), math.floor((c.g or 1) * 255), math.floor((c.b or 1) * 255)), c.r, c.g, c.b
    end
    return "|cffffd966", 1.00, 0.85, 0.40
end

local function FormatDropRowText(item, isMatch)
    local iName = (item and item.name) or ""
    local iSlot = (item and IsSafeStr(item.slot)) and ("  |cff9aa8bd(" .. item.slot .. ")|r") or ""
    if isMatch then
        return "|cff40ff99> " .. iName .. "|r" .. (IsSafeStr(item and item.slot) and ("  |cffb8ffe0(" .. item.slot .. ")|r") or "")
    end
    local qHex = GetDropQualityColor(item and item.quality)
    return qHex .. iName .. "|r" .. iSlot
end

local function ShowDropRowTooltip(row)
    if not row or not row.item then return end
    if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
    local item = row.item
    if FP.EnrichBossDrop then
        FP:EnrichBossDrop(item)
    end
    if item.icon and row.icon then
        row.icon:SetTexture(item.icon)
    end
    if row.text then
        row.text:SetText(FormatDropRowText(item, row.isMatch))
    end

    activeHoverDropRow = row
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT", 6, 0)
    GameTooltip:ClearLines()

    local L = FP.L or {}
    local loadedLive = false
    if IsSafeStr(item.link) then
        local okH = pcall(GameTooltip.SetHyperlink, GameTooltip, item.link)
        if okH and GameTooltip:NumLines() and GameTooltip:NumLines() > 0 then
            loadedLive = true
        end
    elseif IsSafeNum(item.itemID) then
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, item.itemID)
        end
        local okI = pcall(GameTooltip.SetItemByID, GameTooltip, item.itemID)
        if okI and GameTooltip:NumLines() and GameTooltip:NumLines() > 0 then
            loadedLive = true
        end
    end

    if loadedLive and _G["GameTooltipTextLeft1"] and _G["GameTooltipTextLeft1"].GetText then
        local t1 = _G["GameTooltipTextLeft1"]:GetText()
        if not IsSafeStr(t1)
            or (RETRIEVING_ITEM_INFO and t1 == RETRIEVING_ITEM_INFO)
            or string.find(string.lower(t1), "retrieving", 1, true) then
            loadedLive = false
        end
    end

    if loadedLive then
        if IsShiftKeyDown and IsShiftKeyDown() and GameTooltip_ShowCompareItem then
            pcall(GameTooltip_ShowCompareItem, GameTooltip)
        end
        GameTooltip:AddLine(" ")
        local srcLine = (row.bossName and row.instName) and (row.bossName .. " - " .. row.instName) or (row.bossName or row.instName)
        if IsSafeStr(srcLine) then
            GameTooltip:AddDoubleLine(L["DUNGEON_DROP_SOURCE"] or "Drop Source", srcLine, 0.65, 0.72, 0.82, 0.55, 0.85, 1.0)
        end
        if IsSafeStr(item.link) then
            GameTooltip:AddLine(L["DUNGEON_DROP_CLICK_HINT"] or "Shift+Click: Link  |  Ctrl+Click: Preview", 0.58, 0.64, 0.74, true)
        end
        GameTooltip:Show()
        return
    end

    GameTooltip:ClearLines()
    local _, r, g, b = GetDropQualityColor(item.quality)
    GameTooltip:SetText(item.name or "Item", r, g, b)

    if IsSafeStr(item.slot) or IsSafeStr(item.armorType) then
        GameTooltip:AddDoubleLine(item.slot or "", item.armorType or "", 1, 1, 1, 1, 1, 1)
    end
    if IsSafeNum(item.armor) then
        GameTooltip:AddLine(string.format("%d %s", item.armor, ARMOR or "Armor"), 1, 1, 1)
    end
    if type(item.stats) == "table" then
        for _, stLine in ipairs(item.stats) do
            if IsSafeStr(stLine) then
                GameTooltip:AddLine(stLine, 1, 1, 1)
            end
        end
    end
    if IsSafeNum(item.reqLvl) and item.reqLvl > 0 then
        local reqFmt = ITEM_MIN_LEVEL or "Requires Level %d"
        GameTooltip:AddLine(string.format(reqFmt, item.reqLvl), 1, 1, 1)
    end
    if type(item.equip) == "table" then
        for _, eqLine in ipairs(item.equip) do
            if IsSafeStr(eqLine) then
                GameTooltip:AddLine((ITEM_SPELL_TRIGGER_ONEQUIP or "Equip:") .. " " .. eqLine, 0.12, 1.0, 0.12, true)
            end
        end
    end
    if type(item.use) == "table" then
        for _, uLine in ipairs(item.use) do
            if IsSafeStr(uLine) then
                GameTooltip:AddLine((ITEM_SPELL_TRIGGER_ONUSE or "Use:") .. " " .. uLine, 0.12, 1.0, 0.12, true)
            end
        end
    end

    GameTooltip:AddLine(" ")
    local srcLine = (row.bossName and row.instName) and (row.bossName .. " - " .. row.instName) or (row.bossName or row.instName)
    if IsSafeStr(srcLine) then
        GameTooltip:AddDoubleLine(L["DUNGEON_DROP_SOURCE"] or "Drop Source", srcLine, 0.65, 0.72, 0.82, 0.55, 0.85, 1.0)
    end
    if IsSafeNum(item.itemID) then
        GameTooltip:AddLine(L["DUNGEON_DROP_LOADING"] or "Loading live server item stats...", 0.90, 0.82, 0.35, true)
    elseif not (IsSafeNum(item.armor) or type(item.stats) == "table" or type(item.equip) == "table" or type(item.use) == "table") then
        GameTooltip:AddLine(L["DUNGEON_DROP_CUSTOM_NOTE"] or "Live stats appear when cached from the server or Encounter Journal.", 0.68, 0.74, 0.84, true)
    end
    GameTooltip:Show()
end

local function GetOrCreateDropRow(idx)
    if dropRows[idx] then return dropRows[idx] end
    local r = CreateFrame("Button", nil, dropsCard.card, "BackdropTemplate")
    r:SetHeight(22)
    r:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    r:RegisterForClicks("LeftButtonUp")

    local ic = r:CreateTexture(nil, "ARTWORK")
    ic:SetSize(16, 16)
    ic:SetPoint("LEFT", 6, 0)
    ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.icon = ic

    local txt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    txt:SetPoint("LEFT", ic, "RIGHT", 7, 0)
    txt:SetPoint("RIGHT", r, "RIGHT", -8, 0)
    txt:SetJustifyH("LEFT")
    txt:SetWordWrap(false)
    r.text = txt

    r:SetScript("OnEnter", function(self)
        SetDropRowVisual(self, true)
        ShowDropRowTooltip(self)
    end)
    r:SetScript("OnLeave", function(self)
        if activeHoverDropRow == self then
            activeHoverDropRow = nil
        end
        SetDropRowVisual(self, false)
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
    end)
    r:SetScript("OnClick", function(self)
        local item = self.item
        if not item or not IsSafeStr(item.link) then return end
        if IsModifiedClick and IsModifiedClick("CHATLINK") then
            if ChatEdit_InsertLink then ChatEdit_InsertLink(item.link) end
        elseif IsModifiedClick and IsModifiedClick("DRESSUP") then
            if DressUpItemLink then DressUpItemLink(item.link) end
        elseif IsShiftKeyDown and IsShiftKeyDown() and ChatEdit_InsertLink then
            ChatEdit_InsertLink(item.link)
        elseif IsControlKeyDown and IsControlKeyDown() and DressUpItemLink then
            DressUpItemLink(item.link)
        end
    end)

    dropRows[idx] = r
    return r
end

local function LayoutDropsCard(yOff, cardWidth, drops, query, bossName, instName, L)
    dropsCard.tag:SetText(L[DROPS_STYLE.labelKey] or DROPS_STYLE.fallback)
    if type(drops) ~= "table" or #drops == 0 then
        HideDropRows()
        dropsCard.card:Hide()
        return yOff
    end

    dropsCard.body:SetText("")
    dropsCard.body:Hide()
    dropsCard.card:ClearAllPoints()
    dropsCard.card:SetPoint("TOPLEFT", detailChild, "TOPLEFT", 0, -yOff)
    dropsCard.card:SetWidth(cardWidth)

    local q = TrimQuery(query)
    local DROP_ROW_H = 22
    local DROP_ROW_GAP = 2
    for i, item in ipairs(drops) do
        local row = GetOrCreateDropRow(i)
        if FP.EnrichBossDrop then
            FP:EnrichBossDrop(item)
        end
        row.item = item
        row.bossName = bossName
        row.instName = instName
        row.isMatch = (q ~= "") and (PlainContainsFold(item.name or "", q) or (#q >= 3 and PlainContainsFold(item.slot or "", q)))
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", dropsCard.card, "TOPLEFT", 10, -(30 + (i - 1) * (DROP_ROW_H + DROP_ROW_GAP)))
        row:SetPoint("RIGHT", dropsCard.card, "RIGHT", -10, 0)
        row:SetHeight(DROP_ROW_H)
        row.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Box_01")
        row.text:SetText(FormatDropRowText(item, row.isMatch))
        SetDropRowVisual(row, false)
        row:Show()
    end

    for i = #drops + 1, #dropRows do
        dropRows[i].item = nil
        dropRows[i]:Hide()
    end

    local cardH = 34 + (#drops * (DROP_ROW_H + DROP_ROW_GAP)) + 4
    dropsCard.card:SetHeight(cardH)
    dropsCard.card:Show()
    return yOff + cardH + 8
end

local function BuildQuestsCardText(quests, query, highlightQuestName, L)
    if type(quests) ~= "table" or #quests == 0 then
        return "|cff9fb2cc" .. (L["DUNGEON_QUEST_NONE"] or "No curated quests for this instance yet. Active dungeon or raid quests in your Quest Log will appear automatically.") .. "|r"
    end
    local qTrim = TrimQuery(query)
    local hlFold = IsSafeStr(highlightQuestName) and string.lower(highlightQuestName) or nil
    local lines = {}
    for _, q in ipairs(quests) do
        local qName = q.name or "?"
        local facBadge = "|cffcccccc[All]|r "
        if q.faction == "Alliance" then
            facBadge = "|cff4da6ff[A]|r "
        elseif q.faction == "Horde" then
            facBadge = "|cffff5544[H]|r "
        end
        local lvlBadge = q.level and ("[" .. tostring(q.level) .. "] ") or ""
        local statusBadge = ""
        if q.inLog then
            local statusStr = q.isComplete and (L["DUNGEON_QUEST_READY"] or "Ready to turn in") or (L["DUNGEON_QUEST_IN_LOG"] or "In Quest Log")
            statusBadge = "  |cff55ee77[" .. statusStr .. "]|r"
        end
        local dispGiver = (FP.LocalizeQuestInstruction and FP:LocalizeQuestInstruction(q.giver)) or q.giver
        local dispPrereq = (FP.LocalizeQuestInstruction and FP:LocalizeQuestInstruction(q.prereq)) or q.prereq
        local giverStr = IsSafeStr(dispGiver) and ("  |cff9aa8bd- " .. dispGiver .. "|r") or ""
        local prereqStr = IsSafeStr(dispPrereq) and ("  |cff8898b0(" .. (L["DUNGEON_QUEST_PREREQ"] or "Prerequisito") .. ": " .. dispPrereq .. ")|r") or ""

        local isMatched = false
        if hlFold and string.lower(qName) == hlFold then
            isMatched = true
        elseif qTrim ~= "" then
            if PlainContainsFold(qName, qTrim)
                or (#qTrim >= 3 and (
                    PlainContainsFold(dispGiver or "", qTrim)
                    or PlainContainsFold(q.giverRaw or "", qTrim)
                    or PlainContainsFold(dispPrereq or "", qTrim)
                    or PlainContainsFold(q.prereqRaw or "", qTrim)
                )) then
                isMatched = true
            end
        end

        if isMatched then
            lines[#lines + 1] = "|cff40ff99> |r" .. facBadge .. "|cff40ff99" .. lvlBadge .. qName .. "|r" .. statusBadge .. giverStr .. prereqStr
        else
            lines[#lines + 1] = "|cffffd966• |r" .. facBadge .. "|cff9fb2cc" .. lvlBadge .. "|r|cffffffff" .. qName .. "|r" .. statusBadge .. giverStr .. prereqStr
        end
    end
    return table.concat(lines, "\n")
end

local function LayoutCard(rc, yOff, cardWidth, tagText, bodyText)
    rc.tag:SetText(tagText)
    if bodyText ~= "" then
        rc.card:ClearAllPoints()
        rc.card:SetPoint("TOPLEFT", detailChild, "TOPLEFT", 0, -yOff)
        rc.card:SetWidth(cardWidth)
        rc.body:SetWidth(cardWidth - 26)
        rc.body:SetText(bodyText)
        rc.body:SetTextColor(0.95, 0.97, 0.99, 1)
        local textH = math.max(18, rc.body:GetStringHeight() or 28)
        local cardH = 44 + textH
        rc.card:SetHeight(cardH)
        rc.card:Show()
        return yOff + cardH + 8
    end
    rc.card:Hide()
    return yOff
end

-------------------------------------------------------------------------------
-- Collapse / Close / Navigation / Search & Filter Wiring
-------------------------------------------------------------------------------
local function ApplyCollapseLayout()
    if isCollapsed then
        bodyFrame:Hide()
        picker:Hide()
        frame:SetHeight(COLLAPSED_H)
        minBtn.label:SetText("+")
    else
        frame:SetHeight(FRAME_H)
        bodyFrame:Show()
        minBtn.label:SetText("-")
    end
end

minBtn:SetScript("OnClick", function()
    isCollapsed = not isCollapsed
    ApplyCollapseLayout()
    FP:RefreshDungeonGuide()
end)

closeBtn:SetScript("OnClick", function()
    manualBrowseMode = false
    if currentInstanceRunKey then
        dismissedRunKey = currentInstanceRunKey
    end
    picker:Hide()
    frame:Hide()
end)

local function SendGuideAnnouncement()
    if not activeGuide or not activeGuide.bosses then return end
    local boss = activeGuide.bosses[selectedBossIdx]
    if not boss then return end
    local summary = FP.GetBossGuideText and FP:GetBossGuideText(boss, "summary") or ""
    local tank = FP.GetBossGuideText and FP:GetBossGuideText(boss, "tank") or ""
    local line1 = string.format("[NexusKit] %s: %s", boss.name or "Boss", summary)
    local line2 = (tank ~= "") and ("[Tank] " .. tank) or nil

    local chan = nil
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        chan = "INSTANCE_CHAT"
    elseif IsInRaid and IsInRaid() then
        chan = "RAID"
    elseif IsInGroup and IsInGroup() then
        chan = "PARTY"
    end

    if chan then
        local sendFn = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
        if sendFn then
            pcall(sendFn, line1, chan)
            if line2 then pcall(sendFn, line2, chan) end
            return
        end
    end
    FP:Print(line1)
    if line2 then FP:Print(line2) end
end

announceBtn:SetScript("OnClick", SendGuideAnnouncement)

prevBtn:SetScript("OnClick", function()
    if not activeGuide or not activeGuide.bosses or #activeGuide.bosses == 0 then return end
    selectedBossIdx = ((selectedBossIdx - 2) % #activeGuide.bosses) + 1
    selectedSearchIndex = nil
    selectedSearchKind = nil
    selectedSearchQuestName = nil
    detailScroll:SetVerticalScroll(0)
    FP:RefreshDungeonGuide()
end)

nextBtn:SetScript("OnClick", function()
    if not activeGuide or not activeGuide.bosses or #activeGuide.bosses == 0 then return end
    selectedBossIdx = (selectedBossIdx % #activeGuide.bosses) + 1
    selectedSearchIndex = nil
    selectedSearchKind = nil
    selectedSearchQuestName = nil
    detailScroll:SetVerticalScroll(0)
    FP:RefreshDungeonGuide()
end)

searchBox:SetScript("OnTextChanged", function(self)
    local raw = self:GetText() or ""
    local trimmed = TrimQuery(raw)
    searchPlaceholder:SetShown(raw == "")
    clearSearchBtn:SetShown(raw ~= "")
    if trimmed ~= searchQuery then
        searchQuery = trimmed
        selectedSearchIndex = nil
        selectedSearchKind = nil
        selectedSearchQuestName = nil
        bossScroll:SetVerticalScroll(0)
        FP:RefreshDungeonGuide()
    end
end)

searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    if searchQuery ~= "" and #currentSearchResults > 0 then
        local r = currentSearchResults[1]
        activeGuide = r.guide
        selectedBossIdx = r.bossIdx or 1
        targetedBossIdx = nil
        selectedSearchIndex = 1
        selectedSearchKind = r.kind
        selectedSearchQuestName = (r.kind == "quest" and r.quest) and r.quest.name or nil
        manualBrowseMode = true
        detailScroll:SetVerticalScroll(0)
        FP:RefreshDungeonGuide()
    end
end)

clearSearchBtn:SetScript("OnClick", function()
    searchQuery = ""
    selectedSearchIndex = nil
    selectedSearchKind = nil
    selectedSearchQuestName = nil
    searchBox:SetText("")
    searchBox:ClearFocus()
    bossScroll:SetVerticalScroll(0)
    FP:RefreshDungeonGuide()
end)

for _, pill in ipairs(levelPills) do
    pill:SetScript("OnClick", function(self)
        local newFilter = self.filterDef.id
        if activeLevelFilter == newFilter then return end
        activeLevelFilter = newFilter
        selectedSearchIndex = nil
        selectedSearchKind = nil
        selectedSearchQuestName = nil
        if searchQuery == "" and FP.MatchesLevelFilter and FP.GetSortedDungeonList then
            if not activeGuide or not FP:MatchesLevelFilter(activeGuide, activeLevelFilter) then
                local matching = FP:GetSortedDungeonList(activeLevelFilter)
                if matching and #matching > 0 then
                    activeGuide = matching[1]
                    selectedBossIdx = 1
                    targetedBossIdx = nil
                    manualBrowseMode = true
                end
            end
        end
        if picker:IsShown() then
            PopulateInstancePicker()
        end
        bossScroll:SetVerticalScroll(0)
        detailScroll:SetVerticalScroll(0)
        FP:RefreshDungeonGuide()
    end)
end

-------------------------------------------------------------------------------
-- Main Refresh
-------------------------------------------------------------------------------
function FP:RefreshDungeonGuide()
    local L = FP.L or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

    local sorted = (self.GetSortedDungeonList and self:GetSortedDungeonList(activeLevelFilter)) or {}
    if not activeGuide then
        local allList = (self.GetSortedDungeonList and self:GetSortedDungeonList()) or {}
        if #allList > 0 then
            activeGuide = self:GetDungeonGuide(36) or allList[1]
        end
    end
    if not activeGuide then return end

    UpdateLockIcon()
    RefreshLevelPillStyles()
    searchPlaceholder:SetText(L["DUNGEON_SEARCH_PLACEHOLDER"] or "Search dungeon, boss, quest or gear...")
    local curRaw = searchBox:GetText() or ""
    searchPlaceholder:SetShown(curRaw == "")
    clearSearchBtn:SetShown(curRaw ~= "")

    headerLine:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.45)
    instAccent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
    ovAccent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
    titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    instArrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    prevBtn:refreshStyle()
    nextBtn:refreshStyle()
    announceBtn:refreshStyle()

    local bosses = activeGuide.bosses or {}
    if selectedBossIdx < 1 or selectedBossIdx > #bosses then
        selectedBossIdx = 1
    end
    local boss = bosses[selectedBossIdx]

    local dispName = self.GetDungeonDisplayName and self:GetDungeonDisplayName(activeGuide) or activeGuide.name
    if isCollapsed and boss then
        titleText:SetText((L["DUNGEON_GUIDE_TITLE"] or "Boss Tactics") .. ": " .. (boss.name or dispName))
    else
        titleText:SetText(L["DUNGEON_GUIDE_TITLE"] or "Boss Tactics")
    end
    instBtnText:SetText(dispName)
    instBtnText:SetTextColor(1, 1, 1, 1)
    instCountText:SetText(string.format(L["DUNGEON_FILTER_COUNT"] or "%d found", #sorted))

    local lvlStr = (activeGuide.minLvl == activeGuide.maxLvl)
        and ("Lvl " .. tostring(activeGuide.minLvl or 60))
        or ("Lvl " .. tostring(activeGuide.minLvl or 1) .. "-" .. tostring(activeGuide.maxLvl or 60))
    local typeStr = (activeGuide.kind == "raid") and (L["DUNGEON_KIND_RAID"] or "Raid") or (L["DUNGEON_KIND_PARTY"] or "Dungeon")
    local fwPrefix = activeGuide.isNew and "|cff33e6ffForever|r  |  " or ""
    kindBadge:SetText(fwPrefix .. typeStr .. "  |  " .. lvlStr)
    kindBadge:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

    local ovText = self.GetBossGuideText and self:GetBossGuideText(activeGuide, "overview") or ""
    overviewText:SetText(ovText)

    if searchQuery ~= "" and self.SearchBossGuides then
        currentSearchResults = self:SearchBossGuides(searchQuery, activeLevelFilter)
        PopulateSidebarSearchResults(currentSearchResults, L)
    else
        currentSearchResults = {}
        PopulateSidebarBossList(bosses, L)
    end

    prevBtn.label:SetText(L["DUNGEON_BTN_PREV"] or "< Prev")
    nextBtn.label:SetText(L["DUNGEON_BTN_NEXT"] or "Next >")
    announceBtn.label:SetText(L["DUNGEON_BTN_ANNOUNCE"] or "Send to Chat")
    if self.FitButtonToText then
        self:FitButtonToText(prevBtn, 84, 22, prevBtn.label, 128)
        self:FitButtonToText(nextBtn, 84, 22, nextBtn.label, 128)
        self:FitButtonToText(announceBtn, 160, 24, announceBtn.label, 220)
    end
    footerCounter:SetText(string.format("%d / %d", (#bosses > 0) and selectedBossIdx or 0, #bosses))

    local quests = (self.GetDungeonQuests and self:GetDungeonQuests(activeGuide)) or {}
    local questsTitle = (#quests > 0)
        and string.format("%s (%d)", L[QUESTS_STYLE.labelKey] or QUESTS_STYLE.fallback, #quests)
        or (L[QUESTS_STYLE.labelKey] or QUESTS_STYLE.fallback)
    local questsText = BuildQuestsCardText(quests, searchQuery, selectedSearchQuestName, L)

    if boss then
        local wingTag = boss.wing and ("  [" .. boss.wing .. "]") or ""
        bossHeader:SetText((boss.name or "Boss") .. wingTag)
        bossHeader:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

        local isDef = IsBossDefeated(activeGuide, boss)
        if isDef then
            bossStatus:SetText("|cff55ee77" .. (L["DUNGEON_BOSS_DEFEATED"] or "Sconfitto in questa run") .. "|r  •  " .. dispName .. " (" .. lvlStr .. ")")
            bossDefeatedToggleBtn.label:SetText("|cff55ee77[OK] Sconfitto|r")
            bossDefeatedToggleBtn:SetBackdropBorderColor(0.33, 0.93, 0.47, 0.95)
            bossDefeatedToggleBtn:SetBackdropColor(0.08, 0.22, 0.12, 0.95)
        elseif targetedBossIdx == selectedBossIdx then
            bossStatus:SetText("|cffffb020" .. (L["DUNGEON_BOSS_TARGETED"] or "Bersaglio attuale") .. "|r  •  " .. dispName .. " (" .. lvlStr .. ")")
            bossDefeatedToggleBtn.label:SetText("|cffffcc44Segna Sconfitto|r")
            bossDefeatedToggleBtn:SetBackdropBorderColor(0.30, 0.34, 0.44, 0.95)
            bossDefeatedToggleBtn:SetBackdropColor(0.12, 0.15, 0.21, 0.96)
        else
            bossStatus:SetText(string.format("%s (%d/%d)  •  %s (%s)", L["DUNGEON_BOSS_INDEX"] or "Encounter", selectedBossIdx, #bosses, dispName, lvlStr))
            bossStatus:SetTextColor(0.72, 0.78, 0.88, 1)
            bossDefeatedToggleBtn.label:SetText("|cffffcc44Segna Sconfitto|r")
            bossDefeatedToggleBtn:SetBackdropBorderColor(0.30, 0.34, 0.44, 0.95)
            bossDefeatedToggleBtn:SetBackdropColor(0.12, 0.15, 0.21, 0.96)
        end
        bossDefeatedToggleBtn:Show()

        local yOff = 0
        local sw = detailScroll:GetWidth()
        local cardWidth = (IsSafeNum(sw) and sw > 80) and (sw - 4) or INIT_CARD_W
        detailChild:SetWidth(cardWidth)

        if selectedSearchKind == "quest" then
            yOff = LayoutCard(questsCard, yOff, cardWidth, questsTitle, questsText)
        end

        for _, rc in ipairs(roleCards) do
            local msg = (self.GetBossGuideText and self:GetBossGuideText(boss, rc.style.key)) or ""
            yOff = LayoutCard(rc, yOff, cardWidth, L[rc.style.labelKey] or rc.style.fallback, msg)
        end

        local drops = (self.GetBossDrops and self:GetBossDrops(activeGuide, boss)) or {}
        yOff = LayoutDropsCard(yOff, cardWidth, drops, searchQuery, boss.name, activeGuide.name, L)

        if selectedSearchKind ~= "quest" then
            yOff = LayoutCard(questsCard, yOff, cardWidth, questsTitle, questsText)
        end

        detailChild:SetHeight(math.max(1, yOff))
    else
        bossHeader:SetText(dispName)
        bossStatus:SetText(lvlStr)
        bossDefeatedToggleBtn:Hide()
        for _, rc in ipairs(roleCards) do rc.card:Hide() end
        HideDropRows()
        dropsCard.card:Hide()
        local sw = detailScroll:GetWidth()
        local cardWidth = (IsSafeNum(sw) and sw > 80) and (sw - 4) or INIT_CARD_W
        detailChild:SetWidth(cardWidth)
        local yOff = LayoutCard(questsCard, 0, cardWidth, questsTitle, questsText)
        detailChild:SetHeight(math.max(1, yOff))
    end

    ApplyCollapseLayout()
end

-------------------------------------------------------------------------------
-- Zone / Target / Encounter Auto-Detection
-------------------------------------------------------------------------------
local function UpdateCurrentInstanceState(isZoneTransition)
    local inInstance, instanceType = SafeCall(IsInInstance)
    local isDungeonOrRaid = inInstance and (instanceType == "party" or instanceType == "raid")

    if isDungeonOrRaid then
        local instName, _, _, _, _, _, _, instanceID = SafeCall(GetInstanceInfo)
        local guide = FP.GetDungeonGuide and FP:GetDungeonGuide(instanceID, instName)
        local runKey = tostring(instanceID or 0) .. ":" .. tostring(instName or "")

        local isNewInstance = (lastInstanceRunKey ~= runKey)
        currentInstanceRunKey = runKey
        if isNewInstance then
            lastInstanceRunKey = runKey
            targetedBossIdx = nil
            dismissedRunKey = nil
            defeatedBossMap = {}
            local pTable = GetPersistentDefeatedTable()
            if pTable then
                for k, v in pairs(pTable) do
                    defeatedBossMap[k] = v
                end
            end
        end

        if guide then
            activeGuide = guide
            manualBrowseMode = false

            local guideId = tostring((guide and guide.id) or runKey)
            local charDB = (type(NexusKitCharDB) == "table" and NexusKitCharDB) or {}
            local seenTable = charDB.seenDungeonGuides or {}
            local isFirstTimeEver = not seenTable[guideId] and not seenTable[runKey]
            local firstTimeOnly = GetSettings().dungeonGuideFirstTimeOnly ~= false

            local shouldOpen = isZoneTransition and isNewInstance and IsGuideAutoEnabled()
                and not openedRunKeys[runKey] and (dismissedRunKey ~= runKey)

            if shouldOpen and firstTimeOnly and not isFirstTimeEver then
                shouldOpen = false
            end

            -- Auto-open only once (or first time only if configured) at the start of entering
            if shouldOpen then
                openedRunKeys[runKey] = true
                if charDB.seenDungeonGuides then
                    charDB.seenDungeonGuides[guideId] = true
                    charDB.seenDungeonGuides[runKey] = true
                end
                ApplyDungeonPosition()
                FP:RefreshDungeonGuide()
                frame:Show()
                FP:RefreshDungeonGuide()
            elseif frame:IsShown() then
                FP:RefreshDungeonGuide()
            end
        elseif isZoneTransition and not manualBrowseMode then
            frame:Hide()
        end
    else
        currentInstanceRunKey = nil
        targetedBossIdx = nil
        -- Note: keep lastInstanceRunKey, openedRunKeys, and defeatedBossMap intact
        -- so corpse runs / stepping outside briefly do not trigger spurious popups
        if not manualBrowseMode and frame:IsShown() then
            frame:Hide()
        end
    end
end

function FP:ResetDungeonGuideSeen()
    openedRunKeys = {}
    lastInstanceRunKey = nil
    if NexusKitCharDB then
        NexusKitCharDB.seenDungeonGuides = {}
        NexusKitCharDB.defeatedBosses = {}
    end
    defeatedBossMap = {}
    if frame and frame:IsShown() then
        FP:RefreshDungeonGuide()
    end
end

local function CheckTargetedOrEngagedBoss(unitOrName)
    if not activeGuide or not FP.FindMatchingBossIndex then return end
    local matchName = unitOrName
    if not IsSafeStr(matchName) and UnitExists and SafeCall(UnitExists, "target") == true then
        local n = SafeCall(UnitName, "target")
        if IsSafeStr(n) then matchName = n end
    end
    if not IsSafeStr(matchName) then return end

    local idx = FP:FindMatchingBossIndex(activeGuide, matchName)
    if idx then
        targetedBossIdx = idx
        selectedBossIdx = idx
        if UnitExists and SafeCall(UnitExists, "target") == true and UnitIsDead and SafeCall(UnitIsDead, "target") == true then
            local b = activeGuide.bosses and activeGuide.bosses[idx]
            if b then
                SetBossDefeated(activeGuide, b, true)
            end
        end
        -- Never force auto-open on targeting! Only refresh if the guide is already open:
        if frame:IsShown() then
            FP:RefreshDungeonGuide()
        end
    elseif targetedBossIdx ~= nil then
        targetedBossIdx = nil
        if frame:IsShown() then
            FP:RefreshDungeonGuide()
        end
    end
end

local SCAN_UNITS = { "target", "mouseover", "focus", "boss1", "boss2", "boss3", "boss4", "party1target", "party2target", "party3target", "party4target" }

local function ScanUnitsForDeadBosses()
    if not activeGuide or not activeGuide.bosses or not FP.FindMatchingBossIndex then return end
    for _, u in ipairs(SCAN_UNITS) do
        if UnitExists and SafeCall(UnitExists, u) == true then
            local isDead = UnitIsDead and SafeCall(UnitIsDead, u) == true
            if not isDead and UnitHealth then
                local hp = SafeCall(UnitHealth, u)
                if IsSafeNum(hp) and hp == 0 and UnitIsPlayer and SafeCall(UnitIsPlayer, u) == false then
                    isDead = true
                end
            end
            if isDead then
                local uName = SafeCall(UnitName, u)
                if IsSafeStr(uName) then
                    local idx = FP:FindMatchingBossIndex(activeGuide, uName)
                    if idx and activeGuide.bosses[idx] then
                        SetBossDefeated(activeGuide, activeGuide.bosses[idx], true)
                    end
                end
            end
        end
    end
end

function FP:OnDungeonGuideSettingChanged()
    if IsGuideAutoEnabled() then
        UpdateCurrentInstanceState(true)
    elseif not manualBrowseMode and frame:IsShown() then
        picker:Hide()
        frame:Hide()
    end
end

function FP:ToggleDungeonGuide(arg)
    local q = type(arg) == "string" and TrimQuery(arg) or ""
    if q ~= "" and self.GetDungeonGuide then
        local g = self:GetDungeonGuide(tonumber(q), q)
        if g then
            activeGuide = g
            activeLevelFilter = "all"
            searchQuery = ""
            selectedSearchIndex = nil
            searchBox:SetText("")
            selectedBossIdx = 1
            targetedBossIdx = nil
            manualBrowseMode = true
            ApplyDungeonPosition()
            frame:Show()
            self:RefreshDungeonGuide()
            return
        end
    end

    if frame:IsShown() then
        manualBrowseMode = false
        if currentInstanceRunKey then
            dismissedRunKey = currentInstanceRunKey
        end
        picker:Hide()
        frame:Hide()
    else
        dismissedRunKey = nil
        manualBrowseMode = true
        ApplyDungeonPosition()
        UpdateCurrentInstanceState(false)
        manualBrowseMode = true
        frame:Show()
        self:RefreshDungeonGuide()
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
SafeRegisterEvent(evFrame, "PLAYER_LOGIN")
SafeRegisterEvent(evFrame, "PLAYER_ENTERING_WORLD")
SafeRegisterEvent(evFrame, "ZONE_CHANGED_NEW_AREA")
SafeRegisterEvent(evFrame, "UNIT_HEALTH")
SafeRegisterEvent(evFrame, "LOOT_OPENED")
SafeRegisterEvent(evFrame, "PLAYER_TARGET_CHANGED")
SafeRegisterEvent(evFrame, "ENCOUNTER_START")
SafeRegisterEvent(evFrame, "ENCOUNTER_END")
SafeRegisterEvent(evFrame, "QUEST_LOG_UPDATE")
SafeRegisterEvent(evFrame, "GET_ITEM_INFO_RECEIVED")
SafeRegisterEvent(evFrame, "MODIFIER_STATE_CHANGED")

evFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ApplyDungeonPosition()
        UpdateCurrentInstanceState(false)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        UpdateCurrentInstanceState(true)
    elseif event == "UNIT_HEALTH" then
        local unit = select(1, ...)
        if (currentInstanceRunKey or frame:IsShown()) and type(unit) == "string"
            and (unit == "target" or unit == "mouseover" or unit == "focus" or unit:find("^boss") or unit:find("target$")) then
            ScanUnitsForDeadBosses()
        end
    elseif event == "LOOT_OPENED" then
        if currentInstanceRunKey or frame:IsShown() then
            ScanUnitsForDeadBosses()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if currentInstanceRunKey or frame:IsShown() then
            CheckTargetedOrEngagedBoss(nil)
            ScanUnitsForDeadBosses()
        end
    elseif event == "ENCOUNTER_START" then
        local encounterName = select(2, ...)
        if currentInstanceRunKey and IsSafeStr(encounterName) then
            CheckTargetedOrEngagedBoss(encounterName)
        end
    elseif event == "ENCOUNTER_END" then
        local encounterName = select(2, ...)
        local success = select(5, ...)
        if IsSafeStr(encounterName) and success == 1 and activeGuide and FP.FindMatchingBossIndex then
            local idx = FP:FindMatchingBossIndex(activeGuide, encounterName)
            if idx and activeGuide.bosses and activeGuide.bosses[idx] then
                SetBossDefeated(activeGuide, activeGuide.bosses[idx], true)
            end
        end
    elseif event == "QUEST_LOG_UPDATE" then
        if frame:IsShown() then
            FP:RefreshDungeonGuide()
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        local arg1 = select(1, ...)
        if IsSafeNum(arg1) and frame:IsShown() then
            for _, row in ipairs(dropRows) do
                if row:IsShown() and row.item and row.item.itemID == arg1 then
                    if FP.EnrichBossDrop then
                        FP:EnrichBossDrop(row.item)
                    end
                    row.icon:SetTexture(row.item.icon or "Interface\\Icons\\INV_Box_01")
                    row.text:SetText(FormatDropRowText(row.item, row.isMatch))
                end
            end
            if activeHoverDropRow and activeHoverDropRow:IsShown()
                and activeHoverDropRow.item and activeHoverDropRow.item.itemID == arg1 then
                ShowDropRowTooltip(activeHoverDropRow)
            end
        end
    elseif event == "MODIFIER_STATE_CHANGED" then
        if frame:IsShown() and activeHoverDropRow and activeHoverDropRow:IsShown()
            and GameTooltip and GameTooltip:IsShown() and GameTooltip.IsOwned and GameTooltip:IsOwned(activeHoverDropRow) then
            ShowDropRowTooltip(activeHoverDropRow)
        end
    end
end)
