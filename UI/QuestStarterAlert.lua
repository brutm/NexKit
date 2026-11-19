-- NexusKit - UI/QuestStarterAlert.lua
-- Alerts the player whenever an item that begins a quest is looted into bags,
-- asking if they want to start the quest immediately.
local addonName, FP = ...

local ACCENT = { r = 0, g = 1, b = 0.59 }

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsAlertEnabled()
    return GetSettings().enableQuestStarterAlert ~= false
end

-- Scan Tooltip helper
local scanTip = CreateFrame("GameTooltip", "NexusKitQuestStarterScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Track alerted items in current session so we do not spam repeatedly for the same item
local alertedSessionItems = {}
local pendingAlertQueue = {}

-------------------------------------------------------------------------------
-- Detection: Is an item in bag a quest-starter item?
-------------------------------------------------------------------------------
local function IsItemQuestStarter(bag, slot, itemID)
    if not bag or not slot then return false end

    -- Check if starts a quest using C_TooltipInfo if present (10.x/11.x client engine)
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                local t = line.leftText
                if t and ITEM_STARTS_QUEST and (t:find(ITEM_STARTS_QUEST, 1, true) or t == ITEM_STARTS_QUEST) then
                    return true
                end
            end
        end
    end

    -- Fallback: scan lines of hidden tooltip
    scanTip:ClearLines()
    local ok = pcall(function()
        if C_Container and C_Container.GetContainerItemInfo then
            scanTip:SetBagItem(bag, slot)
        else
            scanTip:SetBagItem(bag, slot)
        end
    end)

    if ok then
        local numLines = scanTip:NumLines() or 0
        for i = 1, numLines do
            local line = _G["NexusKitQuestStarterScanTipTextLeft" .. i]
            if line then
                local text = line:GetText()
                if text and ITEM_STARTS_QUEST and (text:find(ITEM_STARTS_QUEST, 1, true) or text == ITEM_STARTS_QUEST) then
                    return true
                end
            end
        end
    end

    return false
end

-- Find current bag & slot for a given itemID in case the bags shifted
local function FindItemInBags(targetItemID)
    if not targetItemID then return nil, nil end
    local numBags = (NUM_BAG_SLOTS or 4)
    for bag = 0, numBags do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
            or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for slot = 1, numSlots do
            local itemID = (C_Container and C_Container.GetContainerItemID and C_Container.GetContainerItemID(bag, slot))
                or (GetContainerItemID and GetContainerItemID(bag, slot))
            if itemID == targetItemID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

-------------------------------------------------------------------------------
-- Alert Dialog Frame
-------------------------------------------------------------------------------
local alertFrame = CreateFrame("Frame", "NexusKitQuestStarterPopup", UIParent, "BackdropTemplate")
alertFrame:SetSize(390, 145)
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -220)
alertFrame:SetFrameStrata("DIALOG")
alertFrame:SetMovable(true)
alertFrame:EnableMouse(true)
alertFrame:SetClampedToScreen(true)
alertFrame:Hide()

alertFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
alertFrame:SetBackdropColor(0.05, 0.07, 0.10, 0.96)
alertFrame:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.90)

-- Accent line on top
local topAccent = alertFrame:CreateTexture(nil, "OVERLAY")
topAccent:SetHeight(2)
topAccent:SetPoint("TOPLEFT", 1, -1)
topAccent:SetPoint("TOPRIGHT", -1, -1)
topAccent:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 1)

-- Dragging support
local dragBar = CreateFrame("Frame", nil, alertFrame)
dragBar:SetPoint("TOPLEFT", 0, 0)
dragBar:SetPoint("TOPRIGHT", -26, 0)
dragBar:SetHeight(28)
dragBar:EnableMouse(true)
dragBar:RegisterForDrag("LeftButton")
dragBar:SetScript("OnDragStart", function() alertFrame:StartMoving() end)
dragBar:SetScript("OnDragStop", function() alertFrame:StopMovingOrSizing() end)

-- Title
local titleFs = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleFs:SetPoint("TOPLEFT", 12, -8)
titleFs:SetText("|cff00ff96NexusKit|r — " .. ((FP.L and FP.L["QUEST_STARTER_ALERT_TITLE"]) or "Nuova Missione"))
titleFs:SetTextColor(1, 1, 1, 1)

-- Close Button (X)
local closeBtn = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetSize(24, 24)
closeBtn:SetScript("OnClick", function()
    alertFrame:Hide()
    FP:ShowNextQuestStarterAlert()
end)

-- Item Icon Frame
local iconFrame = CreateFrame("Frame", nil, alertFrame, "BackdropTemplate")
iconFrame:SetSize(40, 40)
iconFrame:SetPoint("TOPLEFT", 14, -36)
iconFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
iconFrame:SetBackdropColor(0, 0, 0, 0.8)
iconFrame:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)

local itemTexture = iconFrame:CreateTexture(nil, "ARTWORK")
itemTexture:SetAllPoints(iconFrame)
itemTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Item Name / Link
local itemNameFs = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
itemNameFs:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
itemNameFs:SetPoint("TOPRIGHT", -12, -36)
itemNameFs:SetJustifyH("LEFT")
itemNameFs:SetWordWrap(false)

-- Prompt Description
local promptFs = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
promptFs:SetPoint("TOPLEFT", iconFrame, "BOTTOMRIGHT", 10, 18)
promptFs:SetPoint("TOPRIGHT", -12, -62)
promptFs:SetJustifyH("LEFT")
promptFs:SetTextColor(0.90, 0.92, 0.95, 1)
promptFs:SetText((FP.L and FP.L["QUEST_STARTER_ALERT_DESC"]) or "Hai raccolto un oggetto che avvia una missione!\nVuoi iniziare la missione adesso?")

-- Tooltip on item icon
iconFrame:EnableMouse(true)
iconFrame:SetScript("OnEnter", function(self)
    if alertFrame.currentItemLink then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(alertFrame.currentItemLink)
        GameTooltip:Show()
    end
end)
iconFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Button helper
local function CreatePopupButton(label, width, isAccent)
    local btn = CreateFrame("Button", nil, alertFrame, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local r, g, b = isAccent and ACCENT.r or 0.28, isAccent and ACCENT.g or 0.32, isAccent and ACCENT.b or 0.38
    btn:SetBackdropColor(isAccent and 0.08 or 0.10, isAccent and 0.16 or 0.12, isAccent and 0.12 or 0.16, 0.95)
    btn:SetBackdropBorderColor(r, g, b, 0.85)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("CENTER", 0, 0)
    txt:SetText(label)
    btn.textFs = txt

    btn:SetScript("OnEnter", function(self)
        if isAccent then
            self:SetBackdropColor(0.12, 0.25, 0.18, 1)
            self:SetBackdropBorderColor(0, 1, 0.59, 1)
        else
            self:SetBackdropColor(0.18, 0.20, 0.26, 1)
            self:SetBackdropBorderColor(0.5, 0.6, 0.7, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(isAccent and 0.08 or 0.10, isAccent and 0.16 or 0.12, isAccent and 0.12 or 0.16, 0.95)
        self:SetBackdropBorderColor(r, g, b, 0.85)
    end)

    return btn
end

-- Button 1: Start Quest
local startBtn = CreatePopupButton((FP.L and FP.L["QUEST_STARTER_ALERT_START"]) or "Inizia Missione", 150, true)
startBtn:SetPoint("BOTTOMLEFT", 14, 12)

-- Button 2: Later / Dismiss
local laterBtn = CreatePopupButton((FP.L and FP.L["QUEST_STARTER_ALERT_LATER"]) or "Piu tardi", 110, false)
laterBtn:SetPoint("BOTTOMRIGHT", -14, 12)

-------------------------------------------------------------------------------
-- Alert Actions
-------------------------------------------------------------------------------
startBtn:SetScript("OnClick", function()
    if InCombatLockdown and InCombatLockdown() then
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage("|cffff4444[NexusKit]|r Non puoi avviare la missione in combattimento.", 1, 0.3, 0.3)
        end
        return
    end

    local itemID = alertFrame.currentItemID
    local bag = alertFrame.currentBag
    local slot = alertFrame.currentSlot

    -- Verify item position or re-locate in bags
    local foundBag, foundSlot = FindItemInBags(itemID)
    if foundBag and foundSlot then
        bag, slot = foundBag, foundSlot
    end

    if bag and slot then
        local useFn = (C_Container and C_Container.UseContainerItem) or UseContainerItem
        if useFn then
            pcall(useFn, bag, slot)
        end
    end

    alertFrame:Hide()
    FP:ShowNextQuestStarterAlert()
end)

laterBtn:SetScript("OnClick", function()
    alertFrame:Hide()
    FP:ShowNextQuestStarterAlert()
end)

-------------------------------------------------------------------------------
-- Displaying Alerts
-------------------------------------------------------------------------------
function FP:ShowQuestStarterAlert(data)
    if not data or not data.itemID then return end

    alertFrame.currentItemID = data.itemID
    alertFrame.currentBag = data.bag
    alertFrame.currentSlot = data.slot
    alertFrame.currentItemLink = data.itemLink

    itemNameFs:SetText(data.itemLink or data.itemName or "Oggetto di Missione")
    itemTexture:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

    alertFrame:Show()
    pcall(PlaySound, SOUNDKIT.UI_QUEST_START or 876, "Master")
end

function FP:ShowNextQuestStarterAlert()
    if #pendingAlertQueue > 0 then
        local nextItem = table.remove(pendingAlertQueue, 1)
        self:ShowQuestStarterAlert(nextItem)
    end
end

function FP:QueueQuestStarterAlert(data)
    if not data or not data.itemID then return end
    if alertFrame:IsShown() then
        pendingAlertQueue[#pendingAlertQueue + 1] = data
    else
        self:ShowQuestStarterAlert(data)
    end
end

-------------------------------------------------------------------------------
-- Scan Bags for new quest starter items
-------------------------------------------------------------------------------
local initialScanDone = false

local function CheckAllBagsForQuestStarters(isInitial)
    if not IsAlertEnabled() then return end

    local numBags = (NUM_BAG_SLOTS or 4)
    for bag = 0, numBags do
        local numSlots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
            or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for slot = 1, numSlots do
            local itemID
            local icon
            local itemLink

            if C_Container and C_Container.GetContainerItemInfo then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    itemID = info.itemID
                    icon = info.iconFileID
                    itemLink = info.hyperlink
                end
            else
                itemID = GetContainerItemID and GetContainerItemID(bag, slot)
                icon = GetContainerItemInfo and select(1, GetContainerItemInfo(bag, slot))
                itemLink = GetContainerItemLink and GetContainerItemLink(bag, slot)
            end

            if itemID and not alertedSessionItems[itemID] then
                if isInitial then
                    -- On initial login, mark existing items as seen so we don't spam popups for old items already in bags
                    alertedSessionItems[itemID] = true
                else
                    if IsItemQuestStarter(bag, slot, itemID) then
                        alertedSessionItems[itemID] = true
                        local itemName = (GetItemInfo and select(1, GetItemInfo(itemID))) or "Oggetto Missione"
                        icon = icon or (GetItemInfo and select(10, GetItemInfo(itemID)))
                        itemLink = itemLink or (GetItemInfo and select(2, GetItemInfo(itemID)))

                        FP:QueueQuestStarterAlert({
                            bag      = bag,
                            slot     = slot,
                            itemID   = itemID,
                            itemName = itemName,
                            itemLink = itemLink,
                            icon     = icon,
                        })
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Event Registration & Dispatch
-------------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
local function SafeRegisterEvent(frame, evt)
    pcall(frame.RegisterEvent, frame, evt)
end

SafeRegisterEvent(evFrame, "PLAYER_LOGIN")
SafeRegisterEvent(evFrame, "BAG_UPDATE_DELAYED")
SafeRegisterEvent(evFrame, "CHAT_MSG_LOOT")

local bagUpdateTimer = nil

evFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(2.0, function()
            CheckAllBagsForQuestStarters(true)
            initialScanDone = true
        end)
    elseif event == "BAG_UPDATE_DELAYED" or event == "CHAT_MSG_LOOT" then
        if not initialScanDone then return end
        if bagUpdateTimer then return end
        bagUpdateTimer = C_Timer.After(0.4, function()
            bagUpdateTimer = nil
            CheckAllBagsForQuestStarters(false)
        end)
    end
end)
