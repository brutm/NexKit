local addonName, FP = ...

-------------------------------------------------------------------------------
-- TrackerFrame.lua – Main tracker window, Quest QoL & Settings UI
-------------------------------------------------------------------------------

local ACCENT       = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
local BG_COLOR     = { 0.08, 0.08, 0.12, 0.85 }
local BORDER_COLOR = { 0.25, 0.25, 0.30, 1 }
local DIM_ALPHA    = 0.50
local MAX_UPCOMING = 6

local GetItemIconCompat        = (C_Item and C_Item.GetItemIconByID) or GetItemIcon

-------------------------------------------------------------------------------
-- Reusable popup menu & dropdown (no UIDropDownMenuTemplate dependency)
-------------------------------------------------------------------------------
local popupDismiss = CreateFrame("Button", nil, UIParent)
popupDismiss:SetAllPoints(UIParent)
popupDismiss:SetFrameStrata("FULLSCREEN")
popupDismiss:SetFrameLevel(1)
popupDismiss:EnableMouse(true)
popupDismiss:Hide()

local sharedPopup = CreateFrame("Frame", "NexusKitPopupMenu", UIParent, "BackdropTemplate")
sharedPopup:SetFrameStrata("FULLSCREEN_DIALOG")
sharedPopup:SetFrameLevel(20)
sharedPopup:SetClampedToScreen(true)
sharedPopup:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
sharedPopup:SetBackdropColor(0.06, 0.06, 0.10, 0.96)
sharedPopup:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
sharedPopup:Hide()
sharedPopup.rows = {}

local function ClosePopupMenu()
    popupDismiss:Hide()
    sharedPopup:Hide()
    sharedPopup.owner = nil
end

popupDismiss:SetScript("OnClick", function()
    ClosePopupMenu()
end)
sharedPopup:SetScript("OnHide", function()
    popupDismiss:Hide()
end)

local function ShowPopupMenu(owner, anchorPoint, relPoint, xOff, yOff, width, items)
    if sharedPopup:IsShown() and sharedPopup.owner == owner then
        ClosePopupMenu()
        return
    end
    sharedPopup.owner = owner

    for _, r in ipairs(sharedPopup.rows) do
        r:Hide()
    end

    local rowH = 20
    local pad = 6
    local maxW = width or 180

    for i, item in ipairs(items) do
        local row = sharedPopup.rows[i]
        if not row then
            row = CreateFrame("Button", nil, sharedPopup)
            row:SetHeight(rowH)
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.18)
            hl:SetAllPoints()
            row.hl = hl

            local check = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            check:SetPoint("LEFT", 6, 0)
            check:SetWidth(14)
            check:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            row.check = check

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            label:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
            row.label = label

            sharedPopup.rows[i] = row
        end

        if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
        if row.hl then row.hl:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.18) end
        row.check:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        row:SetPoint("TOPLEFT", pad, -(pad + (i - 1) * rowH))
        row:SetPoint("TOPRIGHT", -pad, -(pad + (i - 1) * rowH))

        if item.isHeader then
            row:Disable()
            row.check:SetText("")
            row.label:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            row.label:SetText(item.text or "")
            row:SetScript("OnClick", nil)
        elseif item.isSeparator then
            row:Disable()
            row.check:SetText("")
            row.label:SetTextColor(0.35, 0.40, 0.48, 0.6)
            row.label:SetText("────────────────────────")
            row:SetScript("OnClick", nil)
        else
            local isChecked = false
            if type(item.checked) == "function" then
                isChecked = item.checked()
            else
                isChecked = item.checked and true or false
            end
            row.check:SetText(isChecked and "*" or "")
            row.label:SetText(item.text or "")

            if item.disabled then
                row:Disable()
                row.label:SetTextColor(0.5, 0.5, 0.5, 1)
            else
                row:Enable()
                row.label:SetTextColor(1, 1, 1, 1)
            end

            row:SetScript("OnClick", function()
                if item.func then item.func() end
                if not item.keepOpen then
                    ClosePopupMenu()
                else
                    local nowChecked = false
                    if type(item.checked) == "function" then
                        nowChecked = item.checked()
                    else
                        item.checked = not item.checked
                        nowChecked = item.checked
                    end
                    row.check:SetText(nowChecked and "*" or "")
                end
            end)
        end
        row:Show()
    end

    sharedPopup:SetSize(maxW, pad * 2 + math.max(1, #items) * rowH)
    sharedPopup:ClearAllPoints()
    if owner == "cursor" then
        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        sharedPopup:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale, cy / scale)
    else
        sharedPopup:SetPoint(anchorPoint or "TOPLEFT", owner, relPoint or "BOTTOMLEFT", xOff or 0, yOff or -2)
    end
    popupDismiss:Show()
    sharedPopup:Show()
end

function FP:ClosePopupMenu()
    ClosePopupMenu()
end

function FP:ShowPopupMenu(owner, anchorPoint, relPoint, xOff, yOff, width, items)
    ShowPopupMenu(owner, anchorPoint, relPoint, xOff, yOff, width, items)
end

local function CreateCustomDropdown(parent, width, buildItems)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 22)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    btn:SetBackdropBorderColor(0.28, 0.28, 0.34, 1)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -18, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    btn.text = text

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")
    arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    btn.arrow = arrow

    function btn:SetSelectedText(str)
        self.text:SetText(str or "")
    end

    btn:SetScript("OnClick", function(self)
        local items = buildItems()
        ShowPopupMenu(self, "TOPLEFT", "BOTTOMLEFT", 0, -2, math.max(width, 190), items)
    end)

    return btn
end

local ACTION_ICONS = {
    ACCEPT     = "Interface\\GossipFrame\\AvailableQuestIcon",
    TURNIN     = "Interface\\GossipFrame\\ActiveQuestIcon",
    COMPLETE   = "Interface\\Icons\\INV_Misc_Map_01",
    GRIND      = "Interface\\Icons\\Ability_Warrior_Revenge",
    GOTO       = "Interface\\Icons\\INV_Misc_Map_01",
    TRAIN      = "Interface\\Icons\\INV_Misc_Book_09",
    SET_HEARTH = "Interface\\Icons\\INV_Misc_Rune_01",
    USE_HEARTH = "Interface\\Icons\\INV_Misc_Rune_01",
    FLY        = "Interface\\Icons\\Ability_Druid_FlightForm",
}

local function SetActionIconTexture(tex, action)
    if not tex then return end
    local path = ACTION_ICONS[action] or ACTION_ICONS["GOTO"]
    tex:SetTexture(path)
    if type(path) == "string" and path:find("^Interface\\Icons\\") then
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

local ACTION_LOCALE_KEYS = {
    ACCEPT     = "ACCEPT_QUEST",
    COMPLETE   = "COMPLETE",
    TURNIN     = "TURNIN",
    GRIND      = "GRIND",
    TRAIN      = "TRAIN",
    SET_HEARTH = "SET_HEARTH",
    USE_HEARTH = "USE_HEARTH",
    FLY        = "FLY_TO",
    GOTO       = "GOTO",
}

local function GetLocalizedAction(action)
    local L = FP.L or {}
    local key = ACTION_LOCALE_KEYS[action]
    return (key and L[key]) or action or ""
end

local function UpdateLockVisual(lockBtn)
    local locked = NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locked
    if locked then
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
    else
        lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    end
    if FP.CropButtonTextures then
        FP:CropButtonTextures(lockBtn, 0.15)
    end
end

-------------------------------------------------------------------------------
-- Main tracker frame
-------------------------------------------------------------------------------
local DEFAULT_WIDTH    = 320
local DEFAULT_HEIGHT   = 270
local MIN_WIDTH        = 290
local MIN_HEIGHT       = 215
local MAX_WIDTH        = 520
local MAX_HEIGHT       = 580
local MINIMIZED_HEIGHT = 42

local minimized = false
local savedExpandedWidth = DEFAULT_WIDTH
local savedExpandedHeight = DEFAULT_HEIGHT

local tracker = CreateFrame("Frame", "NexusKitTrackerFrame", UIParent, "BackdropTemplate")
tracker:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
tracker:SetPoint("RIGHT", UIParent, "RIGHT", -40, 50)
if tracker.SetDontSavePosition then
    tracker:SetDontSavePosition(true)
end
tracker:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
tracker:SetBackdropColor(unpack(BG_COLOR))
tracker:SetBackdropBorderColor(unpack(BORDER_COLOR))
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:SetResizable(true)

local function ApplyResizeBounds(minH)
    if tracker.SetResizeBounds then
        tracker:SetResizeBounds(MIN_WIDTH, minH, MAX_WIDTH, MAX_HEIGHT)
    elseif tracker.SetMinResize then
        tracker:SetMinResize(MIN_WIDTH, minH)
        tracker:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
    end
end

ApplyResizeBounds(MIN_HEIGHT)
tracker:SetClampedToScreen(true)
tracker:RegisterForDrag("LeftButton")

local function PinTopLeftAnchor()
    local left, top = tracker:GetLeft(), tracker:GetTop()
    if left and top then
        tracker:ClearAllPoints()
        tracker:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
end

local function SaveTrackerGeometry()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local s = tracker:GetScale() or 1
    local left, top = tracker:GetLeft(), tracker:GetTop()
    if left and top then
        NexusKitDB.settings.trackerPos = {
            x = left * s,
            y = top * s,
        }
    end
    local w = tracker:GetWidth()
    local h = tracker:GetHeight()
    if w and w >= MIN_WIDTH then
        savedExpandedWidth = w
        NexusKitDB.settings.trackerWidth = w
    end
    if not minimized and h and h >= MIN_HEIGHT then
        savedExpandedHeight = h
        NexusKitDB.settings.trackerHeight = h
    end
    NexusKitDB.settings.trackerMinimized = minimized and true or false
end

local itemBtn, SyncItemButtonLayout

tracker:SetScript("OnDragStart", function(self)
    if not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locked) then
        if itemBtn and not (InCombatLockdown and InCombatLockdown()) then
            itemBtn:Hide()
        end
        self:StartMoving()
    end
end)
tracker:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    PinTopLeftAnchor()
    SaveTrackerGeometry()
    SyncItemButtonLayout()
end)

-- Resize handle
local resizer = CreateFrame("Button", nil, tracker)
resizer:SetSize(20, 20)
resizer:SetPoint("BOTTOMRIGHT", -2, 2)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizer:SetScript("OnMouseDown", function()
    if not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locked) then
        if itemBtn and not (InCombatLockdown and InCombatLockdown()) then
            itemBtn:Hide()
        end
        tracker:StartSizing("BOTTOMRIGHT")
    end
end)
resizer:SetScript("OnMouseUp", function()
    tracker:StopMovingOrSizing()
    PinTopLeftAnchor()
    SaveTrackerGeometry()
    FP:RefreshTracker()
    SyncItemButtonLayout()
end)

-------------------------------------------------------------------------------
-- Title bar
-------------------------------------------------------------------------------
local titleBar = CreateFrame("Frame", nil, tracker)
titleBar:SetHeight(30)
titleBar:SetPoint("TOPLEFT", 8, -5)
titleBar:SetPoint("TOPRIGHT", -8, -5)

local titleLogo = titleBar:CreateTexture(nil, "ARTWORK")
titleLogo:SetSize(20, 20)
titleLogo:SetPoint("LEFT", 1, 0)
titleLogo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

-- Settings gear button (~20% smaller)
local settingsBtn = CreateFrame("Button", nil, titleBar)
settingsBtn:SetSize(18, 18)
settingsBtn:SetPoint("RIGHT", -45, 0)
settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
settingsBtn:SetScript("OnClick", function()
    FP:ToggleSettingsFrame()
end)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", titleLogo, "RIGHT", 6, 0)
titleText:SetPoint("RIGHT", settingsBtn, "LEFT", -6, 0)
titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
titleText:SetJustifyH("LEFT")
titleText:SetWordWrap(false)

-- Minimize button (~20% smaller)
local minimizeBtn = CreateFrame("Button", nil, titleBar)
minimizeBtn:SetSize(22, 22)
minimizeBtn:SetPoint("RIGHT", -22, 0)
minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Highlight")
minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
if FP.CropButtonTextures then FP:CropButtonTextures(minimizeBtn, 0.15) end

-- Lock button (~20% smaller)
local lockBtn = CreateFrame("Button", nil, titleBar)
lockBtn:SetSize(22, 22)
lockBtn:SetPoint("RIGHT", 0, 0)
lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
lockBtn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")
if FP.CropButtonTextures then FP:CropButtonTextures(lockBtn, 0.15) end
lockBtn:SetScript("OnClick", function()
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings.locked = not NexusKitDB.settings.locked
        UpdateLockVisual(lockBtn)
        if FP.RefreshSettingsUI then
            FP:RefreshSettingsUI()
        end
        if FP.RefreshBuffAdvisor then
            FP:RefreshBuffAdvisor()
        end
    end
end)

-------------------------------------------------------------------------------
-- Content area & step rows
-------------------------------------------------------------------------------
local content = CreateFrame("Frame", nil, tracker)
content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -6)
content:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", -8, 40)
if content.SetClipsChildren then
    content:SetClipsChildren(true)
end

local syncBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
syncBtn:SetSize(96, 19)
syncBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
syncBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
syncBtn:SetBackdropColor(0.08, 0.11, 0.14, 0.9)
syncBtn:SetBackdropBorderColor(0.32, 0.35, 0.40, 0.9)

local syncBtnLabel = syncBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
syncBtnLabel:SetPoint("CENTER", 0, 0)
syncBtnLabel:SetText(FP.L["SYNC_BUTTON"] or "Sync Quests")
syncBtn.label = syncBtnLabel

local function UpdateSyncButtonVisual()
    local L = FP.L or {}
    local isSync = FP.IsQuestSyncActive and FP:IsQuestSyncActive()
    if isSync then
        syncBtnLabel:SetText(L["SYNC_ACTIVE_BUTTON"] or "Sync: ON")
        syncBtnLabel:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        syncBtn:SetBackdropColor(ACCENT.r * 0.14, ACCENT.g * 0.14, ACCENT.b * 0.14, 0.95)
        syncBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
    else
        syncBtnLabel:SetText(L["SYNC_BUTTON"] or "Sync Quests")
        syncBtnLabel:SetTextColor(0.85, 0.88, 0.92, 1)
        syncBtn:SetBackdropColor(0.08, 0.11, 0.14, 0.9)
        syncBtn:SetBackdropBorderColor(0.32, 0.35, 0.40, 0.9)
    end
    local textW = syncBtnLabel.GetStringWidth and syncBtnLabel:GetStringWidth() or 72
    syncBtn:SetWidth(math.max(88, math.ceil(textW + 16)))
end

syncBtn:SetScript("OnClick", function()
    if FP.ToggleQuestSync then
        FP:ToggleQuestSync()
    end
end)
syncBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    local L = FP.L or {}
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L["SYNC_BUTTON"] or "Sync Quests", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:AddLine(L["SYNC_TOOLTIP"] or "Sync with active Quest Log quests and prioritize by current zone.", 1, 1, 1, true)
    GameTooltip:Show()
end)
syncBtn:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local profBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
profBtn:SetSize(18, 18)
profBtn:SetPoint("RIGHT", syncBtn, "LEFT", -4, 0)
profBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
profBtn:SetBackdropColor(0.08, 0.11, 0.14, 0.9)
profBtn:SetBackdropBorderColor(0.32, 0.35, 0.40, 0.9)
profBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local profBtnIcon = profBtn:CreateTexture(nil, "ARTWORK")
profBtnIcon:SetPoint("TOPLEFT", 2, -2)
profBtnIcon:SetPoint("BOTTOMRIGHT", -2, 2)
profBtnIcon:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
profBtnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
profBtn.icon = profBtnIcon

local profBtnHi = profBtn:CreateTexture(nil, "HIGHLIGHT")
profBtnHi:SetAllPoints()
profBtnHi:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
profBtnHi:SetBlendMode("ADD")

function FP:UpdateProfessionButtonVisual()
    local isShown = self.IsProfessionAdvisorShown and self:IsProfessionAdvisorShown()
    if isShown then
        profBtn:SetBackdropColor(ACCENT.r * 0.16, ACCENT.g * 0.16, ACCENT.b * 0.16, 0.95)
        profBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
        profBtnIcon:SetVertexColor(1, 1, 1)
    else
        profBtn:SetBackdropColor(0.08, 0.11, 0.14, 0.9)
        profBtn:SetBackdropBorderColor(0.32, 0.35, 0.40, 0.9)
        profBtnIcon:SetVertexColor(0.90, 0.92, 0.95)
    end
end

profBtn:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        FP:ToggleSettingsFrame("prof")
    elseif FP.ToggleProfessionAdvisor then
        FP:ToggleProfessionAdvisor()
    end
end)
profBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    local L = FP.L or {}
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L["PROF_TITLE"] or "Profession Advisor", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:AddLine(L["PROF_TRACKER_BTN_TIP"] or "Left-click: Open/Close Profession Advisor\nRight-click: Profession settings", 1, 1, 1, true)
    GameTooltip:Show()
end)
profBtn:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local progressText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
progressText:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -3)
progressText:SetPoint("TOPRIGHT", profBtn, "TOPLEFT", -6, -3)
progressText:SetJustifyH("LEFT")
progressText:SetWordWrap(false)
progressText:SetTextColor(0.75, 0.75, 0.75, 1)

local stepRows = {}

local function CreateStepRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    local isCurrent = (index == 1)
    row:SetHeight(isCurrent and 54 or 28)
    row:RegisterForClicks("LeftButtonUp")

    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -26)
    else
        row:SetPoint("TOPLEFT", stepRows[index - 1], "BOTTOMLEFT", 0, -4)
    end
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(isCurrent and 24 or 18, isCurrent and 24 or 18)
    icon:SetPoint("TOPLEFT", 2, -2)
    row.icon = icon

    local text = row:CreateFontString(nil, "OVERLAY", isCurrent and "GameFontNormal" or "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 0)
    text:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(isCurrent)
    row.text = text

    row:EnableMouse(true)
    row:SetScript("OnClick", function(self)
        if self.stepData and FP.FocusTrackerStep then
            FP:FocusTrackerStep(self.stepData)
        end
    end)
    row:SetScript("OnEnter", function(self)
        if not self.stepData or not GameTooltip then return end
        local s = self.stepData
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(GetLocalizedAction(s.action), ACCENT.r, ACCENT.g, ACCENT.b)
        GameTooltip:AddLine(s.text or "", 1, 1, 1, true)
        if s.questHeader and s.questHeader ~= "" then
            local lvl = s.questLevel and ("[" .. tostring(s.questLevel) .. "] ") or ""
            GameTooltip:AddLine(lvl .. s.questHeader, 0.75, 0.85, 1.0)
        end
        if s.objectivesList and #s.objectivesList > 0 then
            for _, objText in ipairs(s.objectivesList) do
                GameTooltip:AddLine(" - " .. tostring(objText), 0.85, 0.85, 0.85, true)
            end
        end
        if s.mapID and s.x and s.y then
            GameTooltip:AddLine(string.format("(%.1f, %.1f)  Map %d", s.x, s.y, s.mapID), 0.7, 0.7, 0.7)
        end
        if s.isOptional then
            GameTooltip:AddLine(FP.L["OPTIONAL_TAG"] or "(Optional)", 0.9, 0.8, 0.2)
        end
        if s.action == "TRAIN" then
            GameTooltip:AddLine(FP.L["TRACKER_TRAIN_CLICK_TIP"] or "Click row to set arrow to class trainer.", ACCENT.r, ACCENT.g, ACCENT.b, true)
        else
            GameTooltip:AddLine(FP.L["TRACKER_ROW_CLICK_TIP"] or "Click row to follow this quest.", ACCENT.r, ACCENT.g, ACCENT.b, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    row:Hide()
    return row
end

for i = 1, 1 + MAX_UPCOMING do
    stepRows[i] = CreateStepRow(content, i)
end

-------------------------------------------------------------------------------
-- Bottom bar: Route dropdown + Quest Item SecureActionButton + Skip button
-------------------------------------------------------------------------------
local skipBtn = CreateFrame("Button", nil, tracker, "UIPanelButtonTemplate")
skipBtn:SetSize(64, 22)
skipBtn:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", -24, 8)
skipBtn:SetScript("OnClick", function()
    if FP.ClearSelectedQuestOverride then
        FP:ClearSelectedQuestOverride()
    end
    if FP.activeRoute and FP.currentStepIndex then
        local step = FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
        if step then
            FP:MarkStepComplete(step.id)
        end
    end
end)

-- Parent SecureActionButtonTemplate to UIParent (never to tracker) so moving/resizing/toggling tracker never taints combat lockdown
itemBtn = CreateFrame("Button", "NexusKitQuestItemBtn", UIParent, "SecureActionButtonTemplate")
itemBtn:SetSize(26, 26)
itemBtn:SetFrameStrata("MEDIUM")
itemBtn:SetAttribute("type", "item")
itemBtn:RegisterForClicks("AnyUp", "AnyDown")
itemBtn:Hide()

local itemBtnIcon = itemBtn:CreateTexture(nil, "ARTWORK")
itemBtnIcon:SetAllPoints()

local itemBtnBorder = itemBtn:CreateTexture(nil, "OVERLAY")
itemBtnBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
itemBtnBorder:SetBlendMode("ADD")
itemBtnBorder:SetSize(42, 42)
itemBtnBorder:SetPoint("CENTER")

local activeQuestItemID = nil
local pendingItemBtnSync = false

SyncItemButtonLayout = function()
    local showBtn = not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.showQuestItemBtn == false)
    if InCombatLockdown and InCombatLockdown() then
        pendingItemBtnSync = true
        return
    end
    pendingItemBtnSync = false
    if not activeQuestItemID or not showBtn or minimized or not tracker:IsShown() then
        itemBtn:Hide()
        return
    end
    local tScale = tracker:GetScale() or 1
    local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local sEff = (skipBtn.GetEffectiveScale and skipBtn:GetEffectiveScale()) or (uiScale * tScale)
    local sLeft = skipBtn:GetLeft()
    local sBottom = skipBtn:GetBottom()
    local sTop = skipBtn:GetTop()
    itemBtn:SetScale(tScale)
    itemBtn:SetFrameStrata(tracker:GetFrameStrata() or "MEDIUM")
    itemBtn:SetFrameLevel(math.max(10, (tracker:GetFrameLevel() or 2) + 4))
    itemBtn:ClearAllPoints()
    if sLeft and sBottom and sTop then
        local centerY = ((sBottom + sTop) * 0.5) * sEff / (uiScale * tScale)
        local rightX = (sLeft * sEff / (uiScale * tScale)) - 6
        itemBtn:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", rightX, centerY)
    else
        itemBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    itemBtn:Show()
end

local function UpdateItemButton(itemID)
    activeQuestItemID = itemID or nil
    local showBtn = not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.showQuestItemBtn == false)
    if not itemID or not showBtn then
        if not (InCombatLockdown and InCombatLockdown()) then
            itemBtn:Hide()
        else
            pendingItemBtnSync = true
        end
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        pendingItemBtnSync = true
        return
    end
    itemBtn:SetAttribute("type", "item")
    itemBtn:SetAttribute("item", "item:" .. tostring(itemID))
    local icon = GetItemIconCompat and GetItemIconCompat(itemID)
    if icon then
        itemBtnIcon:SetTexture(icon)
    else
        itemBtnIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    SyncItemButtonLayout()
end

-- Route selector dropdown
local dropdownFrame
local function BuildRouteDropdownItems()
    local L = FP.L or {}
    local playerFaction = UnitFactionGroup("player")
    local sortedRoutes = {}

    if FP.routes then
        for routeId, route in pairs(FP.routes) do
            if routeId ~= FP.QUEST_SYNC_ROUTE_ID then
                if not route.faction or route.faction == "Both" or route.faction == "Neutral" or route.faction == playerFaction then
                    table.insert(sortedRoutes, route)
                end
            end
        end
    end

    table.sort(sortedRoutes, function(a, b)
        return (a.title or a.routeId) < (b.title or b.routeId)
    end)

    local items = {}
    table.insert(items, {
        text = L["ROUTE_SELECT_NONE"] or "-- None --",
        checked = (FP.activeRoute == nil),
        func = function()
            FP:SetActiveRoute(false)
            dropdownFrame:SetSelectedText(L["ROUTE_SELECT_NONE"] or "-- None --")
        end,
    })

    if FP.EnableQuestSync then
        local syncTitle = L["SYNC_ROUTE_TITLE"] or "Quest Log Sync (Zone)"
        table.insert(items, {
            text = syncTitle,
            checked = FP.IsQuestSyncActive and FP:IsQuestSyncActive(),
            func = function()
                FP:EnableQuestSync()
                dropdownFrame:SetSelectedText(syncTitle)
            end,
        })
    end

    for _, route in ipairs(sortedRoutes) do
        table.insert(items, {
            text = route.title or route.routeId,
            checked = FP.activeRoute and FP.activeRoute.routeId == route.routeId,
            func = function()
                FP:SetActiveRoute(route.routeId)
                dropdownFrame:SetSelectedText(route.title or route.routeId)
            end,
        })
    end

    if #sortedRoutes == 0 then
        table.insert(items, {
            text = L["NO_ROUTES"] or "No routes available",
            disabled = true,
        })
    end
    return items
end

dropdownFrame = CreateCustomDropdown(tracker, 154, BuildRouteDropdownItems)
dropdownFrame:SetPoint("BOTTOMLEFT", tracker, "BOTTOMLEFT", 8, 8)

-------------------------------------------------------------------------------
-- Minimize toggle & saved geometry
-------------------------------------------------------------------------------
local function ApplyMinimizedState(collapse, skipSave)
    minimized = collapse and true or false
    if minimized then
        PinTopLeftAnchor()
        local curW = tracker:GetWidth()
        local curH = tracker:GetHeight()
        if curW and curW >= MIN_WIDTH then
            savedExpandedWidth = curW
        end
        if curH and curH >= MIN_HEIGHT then
            savedExpandedHeight = curH
        end
        content:Hide()
        skipBtn:Hide()
        if not InCombatLockdown() then itemBtn:Hide() end
        dropdownFrame:Hide()
        resizer:Hide()
        ApplyResizeBounds(MINIMIZED_HEIGHT)
        tracker:SetHeight(MINIMIZED_HEIGHT)
        minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
        minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Down")
        if FP.CropButtonTextures then FP:CropButtonTextures(minimizeBtn, 0.15) end
    else
        ApplyResizeBounds(MIN_HEIGHT)
        local targetW = math.max(MIN_WIDTH, math.min(MAX_WIDTH, savedExpandedWidth or DEFAULT_WIDTH))
        local targetH = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, savedExpandedHeight or DEFAULT_HEIGHT))
        tracker:SetSize(targetW, targetH)
        content:Show()
        skipBtn:Show()
        dropdownFrame:Show()
        resizer:Show()
        minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
        minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
        if FP.CropButtonTextures then FP:CropButtonTextures(minimizeBtn, 0.15) end
        FP:RefreshTracker()
    end
    if not skipSave then
        SaveTrackerGeometry()
    end
    SyncItemButtonLayout()
end

local function RestoreTrackerGeometry()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local settings = NexusKitDB.settings
    local s = tracker:GetScale() or 1

    if settings.trackerPos and settings.trackerPos.x and settings.trackerPos.y then
        tracker:ClearAllPoints()
        tracker:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", settings.trackerPos.x / s, settings.trackerPos.y / s)
    else
        PinTopLeftAnchor()
    end

    local w = settings.trackerWidth
    local h = settings.trackerHeight
    if type(w) ~= "number" or w < MIN_WIDTH then
        local curW = tracker:GetWidth() or DEFAULT_WIDTH
        w = math.max(DEFAULT_WIDTH, math.min(MAX_WIDTH, curW))
    else
        w = math.max(MIN_WIDTH, math.min(MAX_WIDTH, w))
    end
    if type(h) ~= "number" or h < MIN_HEIGHT then
        local curH = tracker:GetHeight() or DEFAULT_HEIGHT
        if curH < MIN_HEIGHT then
            h = DEFAULT_HEIGHT
        else
            h = math.min(MAX_HEIGHT, curH)
        end
    else
        h = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, h))
    end

    savedExpandedWidth = w
    savedExpandedHeight = h
    ApplyMinimizedState(settings.trackerMinimized == true, true)
    SaveTrackerGeometry()
end

minimizeBtn:SetScript("OnClick", function()
    ApplyMinimizedState(not minimized, false)
end)

-------------------------------------------------------------------------------
-- Scale & Refresh API
-------------------------------------------------------------------------------
function FP:ApplyTrackerScale()
    local s = 1
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.trackerScale then
        s = NexusKitDB.settings.trackerScale
    end
    tracker:SetScale(s)
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.trackerPos then
        local pos = NexusKitDB.settings.trackerPos
        if pos.x and pos.y then
            tracker:ClearAllPoints()
            tracker:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x / s, pos.y / s)
        end
    end
    SyncItemButtonLayout()
end

function FP:ToggleTrackerFrame(forceShow)
    if forceShow == true then
        tracker:Show()
    elseif forceShow == false then
        tracker:Hide()
    elseif tracker:IsShown() then
        tracker:Hide()
    else
        tracker:Show()
    end
    SyncItemButtonLayout()
    if FP.RefreshBuffAdvisor then
        FP:RefreshBuffAdvisor()
    end
end

function FP:RefreshTracker()
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    if dropdownFrame and dropdownFrame.arrow then
        dropdownFrame.arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    end
    if not minimized and (tracker:GetHeight() or 0) < MIN_HEIGHT then
        ApplyResizeBounds(MIN_HEIGHT)
        tracker:SetSize(
            math.max(MIN_WIDTH, tracker:GetWidth() or DEFAULT_WIDTH, savedExpandedWidth or DEFAULT_WIDTH),
            math.max(DEFAULT_HEIGHT, savedExpandedHeight or DEFAULT_HEIGHT)
        )
    end

    local L = FP.L or {}
    local isSync = FP.IsQuestSyncActive and FP:IsQuestSyncActive()
    skipBtn:SetText(L["SKIP_BUTTON"] or "Skip")
    if self.FitButtonToText then
        self:FitButtonToText(skipBtn, 64, 20, nil, 108)
    end
    SyncItemButtonLayout()
    UpdateLockVisual(lockBtn)
    UpdateSyncButtonVisual()
    self:UpdateProfessionButtonVisual()

    if not FP.activeRoute then
        titleText:SetText(L["TRACKER_TITLE"] or "NexusKit")
        progressText:SetText(L["NO_ACTIVE_ROUTE"] or "No active route. Select one below.")
        dropdownFrame:SetSelectedText(L["ROUTE_SELECT_LABEL"] or "Select Route")
        for i = 1, #stepRows do
            stepRows[i].stepData = nil
            stepRows[i]:Hide()
        end
        UpdateItemButton(nil)
        return
    end

    local route = FP.activeRoute
    local steps = route.steps or {}
    local idx = FP.currentStepIndex
    local total = #steps

    titleText:SetText(route.title or route.routeId or L["TRACKER_TITLE"] or "NexusKit")
    dropdownFrame:SetSelectedText(route.title or route.routeId)

    if not idx or not steps[idx] then
        if isSync then
            progressText:SetText(L["SYNC_NO_QUESTS"] or "No quests in log")
        else
            progressText:SetText(L["ROUTE_COMPLETE"] or "Route complete!")
        end
        for i = 1, #stepRows do
            stepRows[i].stepData = nil
            stepRows[i]:Hide()
        end
        UpdateItemButton(nil)
        return
    end

    progressText:SetFormattedText(L["STEP_COUNTER"] or "Step %d / %d", idx, total)

    -- Current step (row 1)
    local currentStep = steps[idx]
    local row1 = stepRows[1]
    local action = currentStep.action or "GOTO"
    SetActionIconTexture(row1.icon, action)
    local displayTxt = currentStep.text or ""
    if currentStep.isOptional then
        displayTxt = displayTxt .. " |cffffd100" .. (L["OPTIONAL_TAG"] or "(Optional)") .. "|r"
    end
    row1.text:SetText(displayTxt)
    row1.text:SetTextColor(1, 1, 1, 1)
    row1.icon:SetAlpha(1)
    row1.stepData = currentStep
    row1:Show()

    if not minimized then
        UpdateItemButton(currentStep.itemID)
    end

    -- Upcoming steps (up to configured count that fit inside content height)
    local settings = (NexusKitDB and NexusKitDB.settings) or {}
    local visibleUpcoming = math.floor(tonumber(settings.upcomingStepsCount) or 4)
    if visibleUpcoming < 1 then visibleUpcoming = 1 elseif visibleUpcoming > MAX_UPCOMING then visibleUpcoming = MAX_UPCOMING end
    local maxContentH = content:GetHeight()
    local rowIdx = 2
    local scanIdx = idx + 1
    while rowIdx <= (1 + visibleUpcoming) and scanIdx <= total do
        local neededBottom = 78 + (rowIdx - 1) * 30
        if maxContentH and maxContentH > 0 and neededBottom > maxContentH then
            break
        end
        local candidate = steps[scanIdx]
        if candidate and (not FP.PassesFilter or FP:PassesFilter(candidate)) then
            local row = stepRows[rowIdx]
            local cAction = candidate.action or "GOTO"
            SetActionIconTexture(row.icon, cAction)
            row.text:SetText(candidate.text or "")
            row.text:SetTextColor(0.72, 0.72, 0.72, 0.72)
            row.icon:SetAlpha(0.78)
            row.stepData = candidate
            row:Show()
            rowIdx = rowIdx + 1
        end
        scanIdx = scanIdx + 1
    end
    for r = rowIdx, #stepRows do
        stepRows[r].stepData = nil
        stepRows[r]:Hide()
    end
end

-------------------------------------------------------------------------------
-- Auto-Accept & Auto-TurnIn
-------------------------------------------------------------------------------
local function StepMatchesDisplayedQuest(step)
    if not step or not step.questId then return false end
    if GetQuestID then
        local qid = GetQuestID()
        if qid and qid > 0 then
            return qid == step.questId
        end
    end
    if GetTitleText then
        local title = GetTitleText()
        if type(title) == "string" and title ~= "" then
            local clean = title:gsub("^%[%d+[%+%*]?%]%s*", ""):lower():match("^%s*(.-)%s*$") or ""
            if clean ~= "" then
                if step.questTitle and step.questTitle:lower():find(clean, 1, true) then
                    return true
                end
                if step.text and step.text:lower():find(clean, 1, true) then
                    return true
                end
                return false
            end
        end
    end
    return true
end

local questEventFrame = CreateFrame("Frame")
questEventFrame:RegisterEvent("QUEST_DETAIL")
questEventFrame:RegisterEvent("QUEST_PROGRESS")
questEventFrame:RegisterEvent("QUEST_COMPLETE")
pcall(questEventFrame.RegisterEvent, questEventFrame, "GOSSIP_SHOW")
pcall(questEventFrame.RegisterEvent, questEventFrame, "QUEST_GREETING")

questEventFrame:SetScript("OnEvent", function(_, event)
    local settings = NexusKitDB and NexusKitDB.settings
    if not settings then return end

    local step = FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
    local inCombat = InCombatLockdown and InCombatLockdown()

    if event == "GOSSIP_SHOW" then
        if inCombat or (IsShiftKeyDown and IsShiftKeyDown()) or not step then return end
        if settings.autoTurnIn and step.action == "TURNIN" then
            if C_GossipInfo and C_GossipInfo.GetActiveQuests then
                local active = C_GossipInfo.GetActiveQuests()
                if type(active) == "table" then
                    for _, q in ipairs(active) do
                        if q.questID == step.questId or (q.title and step.questTitle and q.title:lower():find(step.questTitle:lower(), 1, true)) then
                            if C_GossipInfo.SelectActiveQuest then
                                C_GossipInfo.SelectActiveQuest(q.questID)
                            end
                            return
                        end
                    end
                end
            elseif GetNumGossipActiveQuests and SelectGossipActiveQuest then
                local count = GetNumGossipActiveQuests() or 0
                if count == 1 then
                    SelectGossipActiveQuest(1)
                    return
                end
            end
        end
        if settings.autoAccept and step.action == "ACCEPT" then
            if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
                local avail = C_GossipInfo.GetAvailableQuests()
                if type(avail) == "table" then
                    for _, q in ipairs(avail) do
                        if q.questID == step.questId or (q.title and step.questTitle and q.title:lower():find(step.questTitle:lower(), 1, true)) then
                            if C_GossipInfo.SelectAvailableQuest then
                                C_GossipInfo.SelectAvailableQuest(q.questID)
                            end
                            return
                        end
                    end
                end
            elseif GetNumGossipAvailableQuests and SelectGossipAvailableQuest then
                local count = GetNumGossipAvailableQuests() or 0
                if count == 1 then
                    SelectGossipAvailableQuest(1)
                    return
                end
            end
        end

    elseif event == "QUEST_GREETING" then
        if inCombat or (IsShiftKeyDown and IsShiftKeyDown()) or not step then return end
        if settings.autoTurnIn and step.action == "TURNIN" and GetNumActiveQuests and SelectActiveQuest then
            local count = GetNumActiveQuests() or 0
            if count == 1 then
                SelectActiveQuest(1)
                return
            end
        end
        if settings.autoAccept and step.action == "ACCEPT" and GetNumAvailableQuests and SelectAvailableQuest then
            local count = GetNumAvailableQuests() or 0
            if count == 1 then
                SelectAvailableQuest(1)
                return
            end
        end

    elseif event == "QUEST_DETAIL" then
        if not inCombat and settings.autoAccept and not IsShiftKeyDown() and step and step.action == "ACCEPT" and StepMatchesDisplayedQuest(step) then
            AcceptQuest()
        end

    elseif event == "QUEST_PROGRESS" then
        if not inCombat and settings.autoTurnIn and not IsShiftKeyDown() and step and step.action == "TURNIN" and StepMatchesDisplayedQuest(step) then
            if IsQuestCompletable and IsQuestCompletable() then
                CompleteQuest()
            end
        end

    elseif event == "QUEST_COMPLETE" then
        local numChoices = GetNumQuestChoices and GetNumQuestChoices() or 0
        if not inCombat and settings.autoTurnIn and not IsShiftKeyDown() and step and step.action == "TURNIN" and StepMatchesDisplayedQuest(step) then
            if numChoices <= 1 then
                if numChoices == 1 then
                    GetQuestReward(1)
                else
                    GetQuestReward()
                end
                return
            end
        end

        if FP.ScheduleQuestRewardRefresh then
            FP:ScheduleQuestRewardRefresh(0.02)
        end
    end
end)

-------------------------------------------------------------------------------
-- Right-click context menu
-------------------------------------------------------------------------------
tracker:SetScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
        local L = FP.L or {}
        local settings = NexusKitDB and NexusKitDB.settings or {}
        local function ToggleBoolSetting(key, cb)
            if NexusKitDB and NexusKitDB.settings then
                NexusKitDB.settings[key] = not (NexusKitDB.settings[key] ~= false)
                if cb then cb(NexusKitDB.settings[key]) end
                if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
            end
        end
        ShowPopupMenu("cursor", nil, nil, 0, 0, 245, {
            {
                text = L["SETTING_AUTO_ACCEPT"] or "Auto-accept quests",
                checked = settings.autoAccept ~= false,
                keepOpen = true,
                func = function() ToggleBoolSetting("autoAccept") end,
            },
            {
                text = L["SETTING_AUTO_TURNIN"] or "Auto-turn-in quests",
                checked = settings.autoTurnIn ~= false,
                keepOpen = true,
                func = function() ToggleBoolSetting("autoTurnIn") end,
            },
            {
                text = L["SETTING_HIGHLIGHTS"] or "Highlight quest NPCs & zones",
                checked = settings.enableHighlights ~= false,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("enableHighlights", function()
                        if FP.RefreshHighlights then FP:RefreshHighlights() end
                        if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
                    end)
                end,
            },
            {
                text = L["SETTING_TRAJECTORIES"] or "Show quest trajectories on map",
                checked = settings.showTrajectories ~= false,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("showTrajectories", function()
                        if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
                    end)
                end,
            },
            {
                text = L["SETTING_MINIMAP_TRAJECTORY"] or "Show trajectory on Minimap",
                checked = settings.showMinimapTrajectories ~= false,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("showMinimapTrajectories", function()
                        if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
                    end)
                end,
            },
            {
                text = L["SETTING_ZONE_POIS"] or "Show zone points of interest on map",
                checked = settings.showZonePOIs == true,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("showZonePOIs", function()
                        if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
                    end)
                end,
            },
            {
                text = L["SETTING_PROF_ADVISOR"] or "Profession Skill Advisor",
                checked = settings.enableProfessionAdvisor ~= false,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("enableProfessionAdvisor", function()
                        if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
                    end)
                end,
            },
            {
                text = L["SETTING_BUFF_ADVISOR"] or "Buff & tracking reminders",
                checked = settings.enableBuffAdvisor ~= false,
                keepOpen = true,
                func = function()
                    ToggleBoolSetting("enableBuffAdvisor", function()
                        if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
                    end)
                end,
            },
            {
                text = L["SETTINGS_TITLE"] or "NexusKit Settings",
                func = function() FP:ToggleSettingsFrame() end,
            },
            {
                text = L["HELP_BTN_TIP"] or "Guide & Commands (/nk help)",
                func = function()
                    if FP.ToggleWelcomeFrame then FP:ToggleWelcomeFrame() end
                end,
            },
            {
                text = L["IMPORT_TITLE"] or "Import Route Pack",
                func = function()
                    if FP.ToggleImporterFrame then FP:ToggleImporterFrame() end
                end,
            },
        })
    end
end)

-------------------------------------------------------------------------------
-- Settings Dialog Frame (4-tab configurable suite: /nk config | /nk settings)
-------------------------------------------------------------------------------
local settingsFrame = CreateFrame("Frame", "NexusKitSettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(476, 625)
settingsFrame:SetPoint("CENTER")
settingsFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
settingsFrame:SetBackdropColor(0.07, 0.08, 0.11, 0.96)
settingsFrame:SetBackdropBorderColor(0.25, 0.27, 0.32, 1)
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:SetClampedToScreen(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:Hide()
_G["NexusKitSettingsFrame"] = settingsFrame
if type(UISpecialFrames) == "table" then
    local exists = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "NexusKitSettingsFrame" then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(UISpecialFrames, "NexusKitSettingsFrame")
    end
end

local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
settingsTitle:SetPoint("TOP", 10, -14)
settingsTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

local settingsLogo = settingsFrame:CreateTexture(nil, "ARTWORK")
settingsLogo:SetSize(20, 20)
settingsLogo:SetPoint("RIGHT", settingsTitle, "LEFT", -6, 0)
settingsLogo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

local settingsClose = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
settingsClose:SetSize(24, 24)
settingsClose:SetPoint("TOPRIGHT", -4, -4)
settingsClose:SetScript("OnClick", function() settingsFrame:Hide() end)

local settingsHelpBtn = CreateFrame("Button", nil, settingsFrame, "BackdropTemplate")
settingsHelpBtn:SetSize(18, 18)
settingsHelpBtn:SetPoint("TOPLEFT", 14, -12)
settingsHelpBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
settingsHelpBtn:SetBackdropColor(0.08, 0.11, 0.14, 0.9)
settingsHelpBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.8)
local settingsHelpLbl = settingsHelpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
settingsHelpLbl:SetPoint("CENTER", 0, 0)
settingsHelpLbl:SetText("?")
settingsHelpLbl:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
settingsHelpBtn:SetScript("OnClick", function()
    if FP.ToggleWelcomeFrame then FP:ToggleWelcomeFrame() end
end)
settingsHelpBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    local L = FP.L or {}
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["HELP_BTN_TIP"] or "Guide & Commands (/nk help)", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:Show()
end)
settingsHelpBtn:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local settingsBody = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
settingsBody:SetPoint("TOPLEFT", 14, -74)
settingsBody:SetPoint("BOTTOMRIGHT", -14, 46)
settingsBody:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
settingsBody:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
settingsBody:SetBackdropBorderColor(0.20, 0.22, 0.27, 0.9)

local settingsScroll = CreateFrame("ScrollFrame", "NexusKitSettingsScroll", settingsBody, "UIPanelScrollFrameTemplate")
settingsScroll.scrollBarHideable = true
settingsScroll:SetPoint("TOPLEFT", 2, -4)
settingsScroll:SetPoint("BOTTOMRIGHT", -4, 4)

local settingsScrollChild = CreateFrame("Frame", nil, settingsScroll)
settingsScrollChild:SetSize(442, 497)
settingsScroll:SetScrollChild(settingsScrollChild)

local function GetLocaleDisplayName(entry)
    if entry.labelKey then
        return (FP.L and FP.L[entry.labelKey]) or entry.code
    end
    return entry.name or entry.code
end

local function SetBoolSetting(key, val)
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings[key] = val and true or false
    end
end

local function SetNumSetting(key, val)
    if NexusKitDB and NexusKitDB.settings then
        NexusKitDB.settings[key] = val
    end
end

local SETTINGS_TABS = {
    { id = "general", labelKey = "CFG_TAB_GENERAL",     fallback = "General" },
    { id = "nav",     labelKey = "CFG_TAB_NAVIGATION",  fallback = "Navigation" },
    { id = "prof",    labelKey = "CFG_TAB_PROFESSIONS", fallback = "Professions UI" },
    { id = "buffs",   labelKey = "CFG_TAB_BUFFS_UI",    fallback = "Buffs & UI" },
}

local SETTINGS_CONTROLS = {
    general = {
        { kind = "checkbox", key = "autoAccept", default = true, labelKey = "SETTING_AUTO_ACCEPT", tipKey = "SETTING_AUTO_ACCEPT_TIP", fallback = "Auto-accept quests" },
        { kind = "checkbox", key = "autoTurnIn", default = true, labelKey = "SETTING_AUTO_TURNIN", tipKey = "SETTING_AUTO_TURNIN_TIP", fallback = "Auto-turn-in quests" },
        {
            kind = "checkbox", key = "highlightQuestRewards", default = true,
            labelKey = "SETTING_REWARD_HIGHLIGHT", tipKey = "SETTING_REWARD_HIGHLIGHT_TIP", fallback = "Highlight best quest rewards",
            onChange = function(checked)
                if not checked and FP.ClearQuestRewardHighlights then
                    FP:ClearQuestRewardHighlights()
                elseif FP.RefreshQuestRewardHighlights then
                    FP:RefreshQuestRewardHighlights()
                end
            end,
        },
        {
            kind = "rewardSpec", key = "rewardSpec",
            labelKey = "SETTING_REWARD_SPEC", tipKey = "SETTING_REWARD_SPEC_TIP", fallback = "Quest reward spec",
        },
        {
            kind = "checkbox", key = "warnKeepQuestLoot", default = true,
            labelKey = "SETTING_WARN_KEEP_QUEST_LOOT", tipKey = "SETTING_WARN_KEEP_QUEST_LOOT_TIP", fallback = "Warn not to sell quest loot",
            onChange = function()
                if FP.RefreshReagentTrackerUI then FP:RefreshReagentTrackerUI() end
            end,
        },
        {
            kind = "checkbox", key = "syncDeprioritizeDungeons", default = true,
            labelKey = "SETTING_SYNC_NO_DUNGEON", tipKey = "SETTING_SYNC_NO_DUNGEON_TIP", fallback = "Sync: Put dungeons at the end",
            onChange = function()
                if NexusKitCharDB and NexusKitCharDB.syncActive and FP.RebuildQuestSyncRoute then
                    FP:RebuildQuestSyncRoute()
                end
            end,
        },
        {
            kind = "checkbox", key = "syncPreferWatched", default = true,
            labelKey = "SETTING_SYNC_PREFER_WATCHED", tipKey = "SETTING_SYNC_PREFER_WATCHED_TIP", fallback = "Sync: Prioritize tracked quests",
            onChange = function()
                if NexusKitCharDB and NexusKitCharDB.syncActive and FP.RebuildQuestSyncRoute then
                    FP:RebuildQuestSyncRoute()
                end
            end,
        },
        {
            kind = "checkbox", key = "syncSuggestTrainers", default = true,
            labelKey = "SETTING_SYNC_TRAINERS", tipKey = "SETTING_SYNC_TRAINERS_TIP", fallback = "Sync: Suggest class trainer by level",
            onChange = function()
                if FP.UpdateCurrentStep and FP.activeRoute then
                    FP:UpdateCurrentStep()
                end
            end,
        },
        {
            kind = "checkbox", key = "autoSkipByLevel", default = true,
            labelKey = "SETTING_AUTO_SKIP_LEVEL", tipKey = "SETTING_AUTO_SKIP_LEVEL_TIP", fallback = "Auto-skip outleveled route steps",
            onChange = function()
                if FP.UpdateCurrentStep then FP:UpdateCurrentStep() end
            end,
        },
        {
            kind = "checkbox", key = "showQuestItemBtn", default = true,
            labelKey = "SETTING_SHOW_QUEST_ITEM", tipKey = "SETTING_SHOW_QUEST_ITEM_TIP", fallback = "Show usable quest item button",
            onChange = function()
                if FP.RefreshTracker then FP:RefreshTracker() end
            end,
        },
        {
            kind = "slider", key = "upcomingStepsCount", default = 4, min = 1, max = 6, step = 1, integer = true, fmt = "%d",
            labelKey = "SETTING_UPCOMING_COUNT", tipKey = "SETTING_UPCOMING_COUNT_TIP", fallback = "Upcoming steps shown",
            onChange = function()
                if FP.RefreshTracker then FP:RefreshTracker() end
            end,
        },
        {
            kind = "checkbox", key = "enableQuestStarterAlert", default = true,
            labelKey = "SETTING_QUEST_STARTER_ALERT", tipKey = "SETTING_QUEST_STARTER_ALERT_TIP", fallback = "Quest-starter item alert",
        },
        {
            kind = "checkbox", key = "showClassColorsAndIcons", default = true,
            labelKey = "SETTING_CLASS_FRAMES", tipKey = "SETTING_CLASS_FRAMES_TIP", fallback = "Class colors & icons for PCs",
            onChange = function()
                if FP.RefreshClassFrames then FP:RefreshClassFrames() end
            end,
        },
        {
            kind = "locale", key = "locale", labelKey = "SETTING_LANGUAGE", fallback = "Language",
        },
    },
    nav = {
        {
            kind = "checkbox", key = "enableHighlights", default = true,
            labelKey = "SETTING_HIGHLIGHTS", tipKey = "SETTING_HIGHLIGHTS_TIP", fallback = "Highlight quest NPCs & zones",
            onChange = function()
                if FP.RefreshHighlights then FP:RefreshHighlights() end
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "enableRaidMarkers", default = true,
            labelKey = "SETTING_RAID_MARKERS", tipKey = "SETTING_RAID_MARKERS_TIP", fallback = "Mark turn-in NPCs with X icon",
            onChange = function()
                if FP.RefreshHighlights then FP:RefreshHighlights() end
            end,
        },
        {
            kind = "checkbox", key = "enableMapPins", default = true,
            labelKey = "SETTING_MAP_PINS", tipKey = "SETTING_MAP_PINS_TIP", fallback = "Show extra pins on World Map",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "showTrajectories", default = true,
            labelKey = "SETTING_TRAJECTORIES", tipKey = "SETTING_TRAJECTORIES_TIP", fallback = "Show quest trajectories on map",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "showMinimapTrajectories", default = true,
            labelKey = "SETTING_MINIMAP_TRAJECTORY", tipKey = "SETTING_MINIMAP_TRAJECTORY_TIP", fallback = "Show trajectory on Minimap",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "showMinimapPin", default = false,
            labelKey = "SETTING_MINIMAP_PIN", tipKey = "SETTING_MINIMAP_PIN_TIP", fallback = "Show objective pin on Minimap",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "showZonePOIs", default = false,
            labelKey = "SETTING_ZONE_POIS", tipKey = "SETTING_ZONE_POIS_TIP", fallback = "Show zone points of interest on map",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIsOnlyUndiscovered", default = false,
            labelKey = "SETTING_ZONE_POI_UNDISC", tipKey = "SETTING_ZONE_POI_UNDISC_TIP", fallback = "Only undiscovered zone POIs",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIFlight", default = true,
            labelKey = "SETTING_ZONE_POI_FLIGHT", tipKey = "SETTING_ZONE_POI_FLIGHT_TIP", fallback = "Flight Masters (Gryphons / Wind Riders)",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIInn", default = true,
            labelKey = "SETTING_ZONE_POI_INN", tipKey = "SETTING_ZONE_POI_INN_TIP", fallback = "Innkeepers (Hearthstone)",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOITransport", default = true,
            labelKey = "SETTING_ZONE_POI_TRANSPORT", tipKey = "SETTING_ZONE_POI_TRANSPORT_TIP", fallback = "Transports (Boats, Zeppelins, Tram, Portals)",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIServices", default = true,
            labelKey = "SETTING_ZONE_POI_SERVICES", tipKey = "SETTING_ZONE_POI_SERVICES_TIP", fallback = "Hub Services (Repair, Mailbox, Bank, Auction)",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIDungeons", default = true,
            labelKey = "SETTING_ZONE_POI_DUNGEONS", tipKey = "SETTING_ZONE_POI_DUNGEONS_TIP", fallback = "Dungeon & Raid Entrances",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "zonePOIOppositeFaction", default = false,
            labelKey = "ZONE_POI_OPP_FACTION", tipKey = "ZONE_POI_OPP_FACTION_TIP", fallback = "Show opposite faction POIs",
            onChange = function()
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end,
        },
        {
            kind = "checkbox", key = "crossZoneProjection", default = true,
            labelKey = "SETTING_CROSS_ZONE", tipKey = "SETTING_CROSS_ZONE_TIP", fallback = "Cross-zone continent guidance",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "arrowHideInCombat", default = false,
            labelKey = "SETTING_ARROW_HIDE_COMBAT", tipKey = "SETTING_ARROW_HIDE_COMBAT_TIP", fallback = "Hide navigation arrow in combat",
            onChange = function()
                if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
            end,
        },
        {
            kind = "checkbox", key = "showPlayerCoords", default = true,
            labelKey = "SETTING_PLAYER_COORDS", tipKey = "SETTING_PLAYER_COORDS_TIP", fallback = "Show real-time coordinates",
            onChange = function()
                if FP.RefreshCoordsUI then FP:RefreshCoordsUI() end
            end,
        },
        {
            kind = "slider", key = "arrowScale", default = 1.0, min = 0.50, max = 2.00, step = 0.05, fmt = "%.2fx",
            labelKey = "SETTING_ARROW_SCALE", tipKey = "SETTING_ARROW_SCALE_TIP", fallback = "Arrow scale",
            onChange = function()
                if FP.ApplyArrowScale then FP:ApplyArrowScale() end
            end,
        },
    },
    prof = {
        {
            kind = "checkbox", key = "enableProfessionAdvisor", default = true,
            labelKey = "SETTING_PROF_ADVISOR", tipKey = "SETTING_PROF_ADVISOR_TIP", fallback = "Profession Skill Advisor",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profAutoSelectHero", default = false,
            labelKey = "SETTING_PROF_AUTO_SELECT", tipKey = "SETTING_PROF_AUTO_SELECT_TIP", fallback = "Auto-select #1 recipe on open",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profIncludeMedium", default = true,
            labelKey = "SETTING_PROF_INCLUDE_MEDIUM", tipKey = "SETTING_PROF_INCLUDE_MEDIUM_TIP", fallback = "Include yellow skill-up recipes",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profIncludeEasy", default = true,
            labelKey = "SETTING_PROF_INCLUDE_EASY", tipKey = "SETTING_PROF_INCLUDE_EASY_TIP", fallback = "Include green skill-up recipes",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profPreferIntermediate", default = true,
            labelKey = "SETTING_PROF_INTERMEDIATE", tipKey = "SETTING_PROF_INTERMEDIATE_TIP", fallback = "Prefer crafts yielding reagents",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profDefaultCraftableOnly", default = false,
            labelKey = "SETTING_PROF_DEFAULT_CRAFT", tipKey = "SETTING_PROF_DEFAULT_CRAFT_TIP", fallback = "Start filtered to 'Craftable Now'",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "profHighlightReagents", default = true,
            labelKey = "SETTING_PROF_HIGHLIGHT_REAGENTS", tipKey = "SETTING_PROF_HIGHLIGHT_REAGENTS_TIP", fallback = "Highlight skill-up reagents in loot & bags",
            onChange = function()
                if FP.RefreshReagentTrackerUI then FP:RefreshReagentTrackerUI() end
            end,
        },
        {
            kind = "checkbox", key = "profShowTrackedHud", default = true,
            labelKey = "SETTING_PROF_TRACKED_HUD", tipKey = "SETTING_PROF_TRACKED_HUD_TIP", fallback = "Show tracked reagents HUD",
            onChange = function()
                if FP.RefreshReagentTrackerUI then FP:RefreshReagentTrackerUI() end
            end,
        },
        {
            kind = "checkbox", key = "reagentHudLocked", default = false,
            labelKey = "SETTING_PROF_HUD_LOCKED", tipKey = "SETTING_PROF_HUD_LOCKED_TIP", fallback = "Lock tracked reagents HUD",
            onChange = function()
                if FP.RefreshTrackedReagentsHUD then FP:RefreshTrackedReagentsHUD() end
            end,
        },
        {
            kind = "checkbox", key = "profBagTrackButtons", default = true,
            labelKey = "SETTING_PROF_BAG_TRACK_BTN", tipKey = "SETTING_PROF_BAG_TRACK_BTN_TIP", fallback = "Show '+' track button on bag reagents",
            onChange = function()
                if FP.RefreshReagentTrackerUI then FP:RefreshReagentTrackerUI() end
            end,
        },
        {
            kind = "slider", key = "profMaxResults", default = 30, min = 5, max = 50, step = 5, integer = true, fmt = "%d",
            labelKey = "SETTING_PROF_MAX_RESULTS", tipKey = "SETTING_PROF_MAX_RESULTS_TIP", fallback = "Max recipes listed",
            onChange = function()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end,
        },
        {
            kind = "slider", key = "profScale", default = 1.0, min = 0.70, max = 1.50, step = 0.05, fmt = "%.2fx",
            labelKey = "SETTING_PROF_SCALE", tipKey = "SETTING_PROF_SCALE_TIP", fallback = "Profession Advisor scale",
            onChange = function()
                if FP.ApplyProfessionScale then FP:ApplyProfessionScale() end
            end,
        },
    },
    buffs = {
        {
            kind = "checkbox", key = "enableBuffAdvisor", default = true,
            labelKey = "SETTING_BUFF_ADVISOR", tipKey = "SETTING_BUFF_ADVISOR_TIP", fallback = "Buff & tracking reminders",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "buffCheckClass", default = true,
            labelKey = "SETTING_BUFF_CLASS", tipKey = "SETTING_BUFF_CLASS_TIP", fallback = "Check class buffs, aspects & pets",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "buffCheckTracking", default = true,
            labelKey = "SETTING_BUFF_TRACKING", tipKey = "SETTING_BUFF_TRACKING_TIP", fallback = "Check gathering & utility tracking",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "buffCheckProfessionItems", default = true,
            labelKey = "SETTING_BUFF_PROF_ITEMS", tipKey = "SETTING_BUFF_PROF_ITEMS_TIP", fallback = "Check weapon oils, stones & lures",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "buffHideResting", default = false,
            labelKey = "SETTING_BUFF_HIDE_RESTING", tipKey = "SETTING_BUFF_HIDE_RESTING_TIP", fallback = "Hide Buff Advisor while resting",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "buffTransparentBar", default = true,
            labelKey = "SETTING_BUFF_TRANSPARENT", tipKey = "SETTING_BUFF_TRANSPARENT_TIP", fallback = "Transparent Buff bar (no window frame)",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "checkbox", key = "enableDungeonGuide", default = true,
            labelKey = "SETTING_DUNGEON_GUIDE", tipKey = "SETTING_DUNGEON_GUIDE_TIP", fallback = "Auto-open Boss Guide in dungeons & raids",
            onChange = function()
                if FP.OnDungeonGuideSettingChanged then FP:OnDungeonGuideSettingChanged() end
            end,
        },
        {
            kind = "checkbox", key = "dungeonGuideFirstTimeOnly", default = true,
            labelKey = "SETTING_DUNGEON_FIRST_TIME_ONLY", tipKey = "SETTING_DUNGEON_FIRST_TIME_ONLY_TIP", fallback = "Open only first time entering a dungeon",
            onChange = function()
                if FP.OnDungeonGuideSettingChanged then FP:OnDungeonGuideSettingChanged() end
            end,
        },
        {
            kind = "checkbox", key = "showMinimapButton", default = true,
            labelKey = "SETTING_MINIMAP_BTN", tipKey = "SETTING_MINIMAP_BTN_TIP", fallback = "Show Minimap icon",
            onChange = function()
                if FP.RefreshMinimapButton then FP:RefreshMinimapButton() end
            end,
        },
        {
            kind = "theme", key = "uiTheme", labelKey = "SETTING_UI_THEME", tipKey = "SETTING_UI_THEME_TIP", fallback = "Color theme",
        },
        {
            kind = "checkbox", key = "locked", default = false,
            labelKey = "SETTING_LOCK_FRAMES", tipKey = "SETTING_LOCK_FRAMES_TIP", fallback = "Lock frames",
            onChange = function(checked)
                SetBoolSetting("arrowLocked", checked)
                UpdateLockVisual(lockBtn)
                if FP.RefreshArrowLockVisual then FP:RefreshArrowLockVisual() end
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "slider", key = "buffExpiringSeconds", default = 120, min = 30, max = 300, step = 15, integer = true, fmt = "%ds",
            labelKey = "SETTING_BUFF_EXPIRING_SEC", tipKey = "SETTING_BUFF_EXPIRING_SEC_TIP", fallback = "Expiring buff warning threshold",
            onChange = function()
                if FP.RefreshBuffAdvisor then FP:RefreshBuffAdvisor() end
            end,
        },
        {
            kind = "slider", key = "buffScale", default = 1.0, min = 0.70, max = 1.50, step = 0.05, fmt = "%.2fx",
            labelKey = "SETTING_BUFF_SCALE", tipKey = "SETTING_BUFF_SCALE_TIP", fallback = "Buff Advisor scale",
            onChange = function()
                if FP.ApplyBuffAdvisorScale then FP:ApplyBuffAdvisorScale() end
            end,
        },
        {
            kind = "slider", key = "trackerScale", default = 1.0, min = 0.50, max = 2.00, step = 0.05, fmt = "%.2fx",
            labelKey = "SETTING_TRACKER_SCALE", tipKey = "SETTING_TRACKER_SCALE_TIP", fallback = "Tracker scale",
            onChange = function()
                FP:ApplyTrackerScale()
            end,
        },
    },
}

local isRefreshingSettings = false
local settingsWidgets = {}
local tabButtons = {}
local tabPanels = {}
local panelHeights = {}
local activeTabId = "general"

local function AttachSettingTooltip(widget, def)
    widget:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        local L = FP.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L[def.labelKey] or def.fallback, ACCENT.r, ACCENT.g, ACCENT.b)
        if def.tipKey and L[def.tipKey] and L[def.tipKey] ~= "" then
            GameTooltip:AddLine(L[def.tipKey], 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function CreateSettingCheckbox(parent, def, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(22, 22)
    cb:SetPoint("TOPLEFT", 14, yOffset)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    label:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    cb.label = label

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        SetBoolSetting(def.key, checked)
        if def.onChange then def.onChange(checked) end
        if not isRefreshingSettings and FP.RefreshSettingsUI then
            FP:RefreshSettingsUI()
        end
    end)
    AttachSettingTooltip(cb, def)
    return cb
end

local function CreateSettingSlider(parent, def, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 16, yOffset + 14)

    local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("TOPRIGHT", -16, yOffset + 14)

    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", 16, yOffset)
    slider:SetPoint("TOPRIGHT", -16, yOffset)
    slider:SetHeight(14)
    slider:SetOrientation("HORIZONTAL")
    slider:SetBackdrop({
        bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetMinMaxValues(def.min, def.max)
    slider:SetValueStep(def.step)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end
    slider:SetValue(def.default)
    slider.label = label
    slider.valText = valText

    slider:SetScript("OnValueChanged", function(self, value)
        if isRefreshingSettings then return end
        local step = def.step or 0.05
        local val
        if def.integer then
            val = math.floor(((value - def.min) / step) + 0.5) * step + def.min
            val = math.floor(val + 0.5)
        else
            val = math.floor(value / step + 0.5) * step
            val = math.floor(val * 100 + 0.5) / 100
        end
        if val < def.min then val = def.min elseif val > def.max then val = def.max end
        self.valText:SetFormattedText(def.fmt or "%.2fx", val)
        if self._lastVal ~= val then
            self._lastVal = val
            SetNumSetting(def.key, val)
            if def.onChange then def.onChange(val) end
            if not isRefreshingSettings and FP.RefreshSettingsUI then
                FP:RefreshSettingsUI()
            end
        end
    end)
    AttachSettingTooltip(slider, def)
    return slider
end

local function GetThemeDisplayName(entry)
    local L = FP.L or {}
    return (entry.labelKey and L[entry.labelKey]) or entry.fallback or entry.id
end

local function BuildDropdownItems(kind)
    if kind == "theme" then
        local current = (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.uiTheme) or "blizzard"
        local items = {}
        for _, entry in ipairs(FP.COLOR_THEMES or {}) do
            table.insert(items, {
                text    = GetThemeDisplayName(entry),
                checked = (current == entry.id),
                func    = function()
                    if FP.ApplyTheme then
                        FP:ApplyTheme(entry.id)
                    end
                end,
            })
        end
        return items
    elseif kind == "rewardSpec" then
        local selectedKey = FP.GetRewardSpecSelection and FP:GetRewardSpecSelection() or "AUTO"
        local items = {}
        local opts = FP.GetRewardSpecOptions and FP:GetRewardSpecOptions() or {}
        for _, opt in ipairs(opts) do
            table.insert(items, {
                text    = opt.text,
                checked = (selectedKey == opt.key),
                func    = function()
                    if FP.SetRewardTargetSpec then
                        FP:SetRewardTargetSpec(opt.key)
                    end
                end,
            })
        end
        return items
    end
    local current = (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.locale) or "auto"
    local items = {}
    for _, entry in ipairs(FP.SUPPORTED_LOCALES or {}) do
        table.insert(items, {
            text    = GetLocaleDisplayName(entry),
            checked = (current == entry.code),
            func    = function()
                if NexusKitDB and NexusKitDB.settings then
                    NexusKitDB.settings.locale = entry.code
                    FP:ApplyLocale(entry.code)
                end
            end,
        })
    end
    return items
end

local function CreateDropdownRow(parent, def, yOffset)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", 16, yOffset)
    holder:SetPoint("TOPRIGHT", -16, yOffset)
    holder:SetHeight(24)

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    holder.label = label

    local dropdown = CreateCustomDropdown(holder, 175, function()
        return BuildDropdownItems(def.kind)
    end)
    dropdown:SetPoint("RIGHT", 0, 0)
    holder.dropdown = dropdown
    AttachSettingTooltip(holder, def)
    return holder
end

local function UpdateTabVisuals()
    for _, tab in ipairs(SETTINGS_TABS) do
        local btn = tabButtons[tab.id]
        local panel = tabPanels[tab.id]
        local active = (tab.id == activeTabId)
        if panel then
            if active then panel:Show() else panel:Hide() end
        end
        if btn then
            if active then
                btn:SetBackdropColor(ACCENT.r * 0.16, ACCENT.g * 0.16, ACCENT.b * 0.16, 0.95)
                btn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
                btn.label:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            else
                btn:SetBackdropColor(0.11, 0.12, 0.16, 0.90)
                btn:SetBackdropBorderColor(0.26, 0.28, 0.34, 0.90)
                btn.label:SetTextColor(0.82, 0.84, 0.88, 1)
            end
        end
    end
    local activeH = panelHeights[activeTabId] or 497
    local bodyW = settingsBody:GetWidth() or 448
    if bodyW < 100 then bodyW = 448 end
    local viewH = (settingsBody:GetHeight() or 505) - 8
    if viewH < 100 then viewH = 497 end
    local needsScroll = activeH > viewH
    local sb = _G["NexusKitSettingsScrollScrollBar"] or settingsScroll.ScrollBar
    settingsScroll:ClearAllPoints()
    settingsScroll:SetPoint("TOPLEFT", 2, -4)
    settingsScroll:SetPoint("BOTTOMRIGHT", needsScroll and -24 or -4, 4)
    settingsScrollChild:SetSize(math.max(360, bodyW - (needsScroll and 26 or 6)), math.max(viewH, activeH))
    if sb then
        if needsScroll then sb:Show() else sb:Hide() end
    end
    settingsScroll:SetVerticalScroll(0)
end

local function SelectSettingsTab(tabId)
    if tabPanels[tabId] then
        activeTabId = tabId
        UpdateTabVisuals()
    end
end

local function PopulateTabControls(panel, tabId, widgetStore)
    local y = -12
    for _, def in ipairs(SETTINGS_CONTROLS[tabId] or {}) do
        if def.kind == "checkbox" then
            local widget = CreateSettingCheckbox(panel, def, y)
            widgetStore[#widgetStore + 1] = { def = def, widget = widget }
            y = y - 26
        elseif def.kind == "slider" then
            y = y - 16
            local widget = CreateSettingSlider(panel, def, y)
            widgetStore[#widgetStore + 1] = { def = def, widget = widget }
            y = y - 30
        elseif def.kind == "locale" or def.kind == "theme" or def.kind == "rewardSpec" then
            y = y - 4
            local widget = CreateDropdownRow(panel, def, y)
            widgetStore[#widgetStore + 1] = { def = def, widget = widget }
            y = y - 32
        end
    end
    return math.abs(y) + 12
end

for i, tab in ipairs(SETTINGS_TABS) do
    local btn = CreateFrame("Button", nil, settingsFrame, "BackdropTemplate")
    btn:SetSize(107, 24)
    btn:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 14 + (i - 1) * 113, -44)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 4, 0)
    lbl:SetPoint("RIGHT", -4, 0)
    lbl:SetJustifyH("CENTER")
    lbl:SetWordWrap(false)
    btn.label = lbl
    btn:SetScript("OnClick", function()
        SelectSettingsTab(tab.id)
    end)
    tabButtons[tab.id] = btn

    local panel = CreateFrame("Frame", nil, settingsScrollChild)
    panel:SetPoint("TOPLEFT", settingsScrollChild, "TOPLEFT", 0, 0)
    panel:SetPoint("TOPRIGHT", settingsScrollChild, "TOPRIGHT", 0, 0)
    panel:Hide()
    tabPanels[tab.id] = panel

    local contentH = PopulateTabControls(panel, tab.id, settingsWidgets)
    panel:SetHeight(contentH)
    panelHeights[tab.id] = contentH
end
UpdateTabVisuals()

-- Blizzard Options -> AddOns integration (Settings API in 10.0+/16001 + legacy fallback)
local blizzCategoryID
local blizzRootPanel
local blizzUiRefs = { buttons = {}, subHeaders = {}, subCategories = {}, subDesc = nil }

local BLIZZ_QUICK_ACTIONS = {
    { key = "MINIMAP_MENU_TRACKER", fallback = "Route Tracker",        fn = function() if FP.ToggleTrackerFrame then FP:ToggleTrackerFrame() end end },
    { key = "MINIMAP_MENU_PROF",    fallback = "Profession Advisor",   fn = function() if FP.ToggleProfessionAdvisor then FP:ToggleProfessionAdvisor() end end },
    { key = "MINIMAP_MENU_BUFFS",   fallback = "Buff & Tracking Advisor", fn = function() if FP.ToggleBuffAdvisor then FP:ToggleBuffAdvisor() end end },
    { key = "IMPORT_BUTTON",        fallback = "Import Route",         fn = function() if FP.ToggleImporterFrame then FP:ToggleImporterFrame() end end },
    { key = "CFG_RESET_DEFAULTS",   fallback = "Default Config",       fn = function() if FP.ResetSettingsToDefaults then FP:ResetSettingsToDefaults() end end },
    { key = "HELP_OPEN_SETTINGS",   fallback = "Open Settings",        fn = function() if FP.ToggleSettingsFrame then FP:ToggleSettingsFrame() end end },
}

local function RegisterBlizzardAddOnOptions()
    if blizzRootPanel then return end
    local L = FP.L or {}

    local root = CreateFrame("Frame", "NexusKitBlizzOptionsFrame")
    root:Hide()

    local logo = root:CreateTexture(nil, "ARTWORK")
    logo:SetSize(24, 24)
    logo:SetPoint("TOPLEFT", 16, -14)
    logo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", logo, "RIGHT", 8, 2)
    title:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    title:SetText(L["SETTINGS_TITLE"] or "NexusKit Settings")
    blizzUiRefs.rootTitle = title

    local subDesc = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subDesc:SetPoint("TOPLEFT", 16, -42)
    subDesc:SetTextColor(0.75, 0.78, 0.84, 1)
    subDesc:SetText(L["MINIMAP_MENU_TRACKER"] or "NexusKit")
    blizzUiRefs.subDesc = subDesc

    for idx, act in ipairs(BLIZZ_QUICK_ACTIONS) do
        local col = (idx - 1) % 3
        local row = math.floor((idx - 1) / 3)
        local b = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
        b:SetSize(198, 22)
        b:SetPoint("TOPLEFT", 16 + col * 206, -62 - row * 26)
        b:SetText(L[act.key] or act.fallback)
        if FP.FitButtonToText then
            FP:FitButtonToText(b, 198, 18, nil, 198)
        end
        b:SetScript("OnClick", act.fn)
        blizzUiRefs.buttons[#blizzUiRefs.buttons + 1] = { btn = b, key = act.key, fallback = act.fallback }
    end

    local rootBody = CreateFrame("Frame", nil, root)
    rootBody:SetPoint("TOPLEFT", 6, -118)
    rootBody:SetPoint("BOTTOMRIGHT", -6, 10)
    PopulateTabControls(rootBody, "general", settingsWidgets)

    root.OnRefresh = function()
        if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
    end
    root.OnDefault = function()
        if FP.ResetSettingsToDefaults then FP:ResetSettingsToDefaults() end
    end
    root:SetScript("OnShow", function()
        if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
    end)
    blizzRootPanel = root

    local subCanvases = {}
    for idx = 2, #SETTINGS_TABS do
        local tab = SETTINGS_TABS[idx]
        local sub = CreateFrame("Frame", "NexusKitBlizzOptions_" .. tab.id)
        sub:Hide()

        local h = sub:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h:SetPoint("TOPLEFT", 16, -14)
        h:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        h:SetText("NexusKit — " .. (L[tab.labelKey] or tab.fallback))
        blizzUiRefs.subHeaders[#blizzUiRefs.subHeaders + 1] = { header = h, tab = tab }

        local subBody = CreateFrame("Frame", nil, sub)
        subBody:SetPoint("TOPLEFT", 6, -46)
        subBody:SetPoint("BOTTOMRIGHT", -6, 10)
        PopulateTabControls(subBody, tab.id, settingsWidgets)

        sub.OnRefresh = function()
            if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
        end
        sub.OnDefault = function()
            if FP.ResetSettingsToDefaults then FP:ResetSettingsToDefaults() end
        end
        sub:SetScript("OnShow", function()
            if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
        end)

        subCanvases[#subCanvases + 1] = {
            id = tab.id,
            tab = tab,
            frame = sub,
            label = L[tab.labelKey] or tab.fallback,
        }
    end

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(root, "NexusKit")
        if category then
            Settings.RegisterAddOnCategory(category)
            if Settings.RegisterCanvasLayoutSubcategory then
                for _, entry in ipairs(subCanvases) do
                    local subCat = Settings.RegisterCanvasLayoutSubcategory(category, entry.frame, entry.label)
                    if subCat then
                        blizzUiRefs.subCategories[#blizzUiRefs.subCategories + 1] = {
                            cat = subCat,
                            frame = entry.frame,
                            tab = entry.tab,
                        }
                    end
                end
            end
            if category.GetID then
                blizzCategoryID = category:GetID()
            else
                blizzCategoryID = "NexusKit"
            end
        end
    elseif InterfaceOptions_AddCategory then
        root.name = "NexusKit"
        InterfaceOptions_AddCategory(root)
        for _, entry in ipairs(subCanvases) do
            entry.frame.name = entry.label
            entry.frame.parent = "NexusKit"
            InterfaceOptions_AddCategory(entry.frame)
            blizzUiRefs.subCategories[#blizzUiRefs.subCategories + 1] = {
                cat = nil,
                frame = entry.frame,
                tab = entry.tab,
            }
        end
    end

end

function FP:OpenBlizzardSettings()
    if InCombatLockdown and InCombatLockdown() then return end
    RegisterBlizzardAddOnOptions()
    if Settings and Settings.OpenToCategory and blizzCategoryID then
        pcall(Settings.OpenToCategory, blizzCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory and blizzRootPanel then
        pcall(InterfaceOptionsFrame_OpenToCategory, blizzRootPanel)
        pcall(InterfaceOptionsFrame_OpenToCategory, blizzRootPanel)
    end
end

local settingsImportBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
settingsImportBtn:SetSize(118, 24)
settingsImportBtn:SetPoint("BOTTOMLEFT", 14, 14)
settingsImportBtn:SetScript("OnClick", function()
    if FP.ToggleImporterFrame then FP:ToggleImporterFrame() end
end)

local settingsDefaultsBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
settingsDefaultsBtn:SetSize(130, 24)
settingsDefaultsBtn:SetPoint("BOTTOM", 0, 14)
settingsDefaultsBtn:SetScript("OnClick", function()
    if FP.ResetSettingsToDefaults then
        FP:ResetSettingsToDefaults()
    end
end)

local settingsResetBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
settingsResetBtn:SetSize(118, 24)
settingsResetBtn:SetPoint("BOTTOMRIGHT", -14, 14)
settingsResetBtn:SetScript("OnClick", function()
    if NexusKitCharDB and NexusKitCharDB.completedSteps then
        if wipe then
            wipe(NexusKitCharDB.completedSteps)
        else
            for k in pairs(NexusKitCharDB.completedSteps) do
                NexusKitCharDB.completedSteps[k] = nil
            end
        end
        NexusKitCharDB.currentStepIdx = 1
    end
    FP.currentStepIndex = nil
    if FP.UpdateCurrentStep then FP:UpdateCurrentStep() end
    FP:Print(FP.L["RESET_CONFIRM"])
end)

function FP:RefreshSettingsUI()
    local L = FP.L or {}
    local settings = (NexusKitDB and NexusKitDB.settings) or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

    settingsTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    settingsTitle:SetText(L["SETTINGS_TITLE"] or "NexusKit Settings")
    settingsHelpBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.8)
    settingsHelpLbl:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    if blizzUiRefs.rootTitle then
        blizzUiRefs.rootTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        blizzUiRefs.rootTitle:SetText(L["SETTINGS_TITLE"] or "NexusKit Settings")
    end
    if blizzUiRefs.subDesc then
        blizzUiRefs.subDesc:SetText(L["MINIMAP_MENU_TRACKER"] or "NexusKit")
    end
    for _, item in ipairs(blizzUiRefs.buttons) do
        item.btn:SetText(L[item.key] or item.fallback)
        if self.FitButtonToText then
            self:FitButtonToText(item.btn, 198, 18, nil, 198)
        end
    end
    for _, item in ipairs(blizzUiRefs.subHeaders) do
        item.header:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        item.header:SetText("NexusKit — " .. (L[item.tab.labelKey] or item.tab.fallback))
    end
    for _, item in ipairs(blizzUiRefs.subCategories) do
        local newLabel = L[item.tab.labelKey] or item.tab.fallback
        if item.frame then
            item.frame.name = newLabel
        end
        if item.cat then
            if item.cat.SetName then
                pcall(item.cat.SetName, item.cat, newLabel)
            end
            item.cat.name = newLabel
        end
    end
    for _, tab in ipairs(SETTINGS_TABS) do
        local btn = tabButtons[tab.id]
        if btn and btn.label then
            btn.label:SetText(L[tab.labelKey] or tab.fallback)
            if self.FitButtonToText then
                self:FitButtonToText(btn, 107, 10, btn.label, 107)
            end
        end
    end
    UpdateTabVisuals()

    settingsImportBtn:SetText(L["IMPORT_BUTTON"] or "Import Route")
    settingsDefaultsBtn:SetText(L["CFG_RESET_DEFAULTS"] or "Default Config")
    settingsResetBtn:SetText(L["RESET_BUTTON"] or "Reset Progress")
    if self.FitButtonToText then
        local footerW = (settingsFrame:GetWidth() or 476) - 28
        local maxCombined = footerW - 16
        local w1 = self:FitButtonToText(settingsImportBtn, 104, 24)
        local w2 = self:FitButtonToText(settingsDefaultsBtn, 118, 24)
        local w3 = self:FitButtonToText(settingsResetBtn, 118, 24)
        local sumW = w1 + w2 + w3
        if sumW > maxCombined and sumW > 0 then
            local ratio = maxCombined / sumW
            w1 = self:FitButtonToText(settingsImportBtn, 80, 18, nil, math.max(80, math.floor(w1 * ratio)))
            w2 = self:FitButtonToText(settingsDefaultsBtn, 90, 18, nil, math.max(90, math.floor(w2 * ratio)))
            w3 = self:FitButtonToText(settingsResetBtn, 100, 18, nil, math.max(100, maxCombined - w1 - w2))
        end
        local midX = 14 + w1 + math.max(8, math.floor((footerW - w1 - w2 - w3) * 0.5))
        settingsImportBtn:ClearAllPoints()
        settingsImportBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 14, 14)
        settingsDefaultsBtn:ClearAllPoints()
        settingsDefaultsBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", midX, 14)
        settingsResetBtn:ClearAllPoints()
        settingsResetBtn:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -14, 14)
    end

    isRefreshingSettings = true
    for _, item in ipairs(settingsWidgets) do
        local def = item.def
        local w = item.widget
        if def.kind == "checkbox" then
            w.label:SetText(L[def.labelKey] or def.fallback)
            local checked
            if def.default == false then
                checked = (settings[def.key] == true)
            else
                checked = (settings[def.key] ~= false)
            end
            w:SetChecked(checked)
        elseif def.kind == "slider" then
            w.label:SetText(L[def.labelKey] or def.fallback)
            local val = tonumber(settings[def.key])
            if not val then val = def.default end
            if val < def.min then val = def.min elseif val > def.max then val = def.max end
            w._lastVal = val
            w:SetValue(val)
            w.valText:SetFormattedText(def.fmt or "%.2fx", val)
        elseif def.kind == "locale" then
            w.label:SetText((L[def.labelKey] or def.fallback) .. ":")
            local currentLocale = settings.locale or "auto"
            local displayText = currentLocale
            for _, entry in ipairs(FP.SUPPORTED_LOCALES or {}) do
                if entry.code == currentLocale then
                    displayText = GetLocaleDisplayName(entry)
                    break
                end
            end
            w.dropdown:SetSelectedText(displayText)
            if w.dropdown.arrow then
                w.dropdown.arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            end
        elseif def.kind == "theme" then
            w.label:SetText((L[def.labelKey] or def.fallback) .. ":")
            local currentTheme = settings.uiTheme or "blizzard"
            local displayText = currentTheme
            for _, entry in ipairs(FP.COLOR_THEMES or {}) do
                if entry.id == currentTheme then
                    displayText = GetThemeDisplayName(entry)
                    break
                end
            end
            w.dropdown:SetSelectedText(displayText)
            if w.dropdown.arrow then
                w.dropdown.arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            end
        elseif def.kind == "rewardSpec" then
            w.label:SetText((L[def.labelKey] or def.fallback) .. ":")
            local displayText = ""
            if FP.GetRewardSpecSelection then
                local _, label = FP:GetRewardSpecSelection()
                displayText = label or ""
            end
            w.dropdown:SetSelectedText(displayText)
            if w.dropdown.arrow then
                w.dropdown.arrow:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            end
        end
    end
    isRefreshingSettings = false

    UpdateLockVisual(lockBtn)
    if FP.RefreshArrowLockVisual then FP:RefreshArrowLockVisual() end
end

settingsFrame:SetScript("OnShow", function()
    FP:RefreshSettingsUI()
end)

function FP:ToggleSettingsFrame(tabId)
    if tabId and tabPanels[tabId] then
        SelectSettingsTab(tabId)
        if not settingsFrame:IsShown() then
            settingsFrame:Show()
        else
            self:RefreshSettingsUI()
        end
        return
    end
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end

-------------------------------------------------------------------------------
-- Step-changed callback & combat lockdown handler
-------------------------------------------------------------------------------
if FP.RegisterStepChangedCallback then
    FP:RegisterStepChangedCallback(function()
        FP:RefreshTracker()
    end)
else
    FP.OnStepChangedCallbacks = FP.OnStepChangedCallbacks or {}
    table.insert(FP.OnStepChangedCallbacks, function()
        FP:RefreshTracker()
    end)
end

local combatWatcher = CreateFrame("Frame")
combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
combatWatcher:SetScript("OnEvent", function()
    if FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps then
        local step = FP.activeRoute.steps[FP.currentStepIndex]
        if step and step.itemID then
            UpdateItemButton(step.itemID)
        else
            UpdateItemButton(nil)
        end
    elseif pendingItemBtnSync then
        SyncItemButtonLayout()
    end
end)

-------------------------------------------------------------------------------
-- Initial display
-------------------------------------------------------------------------------
tracker:RegisterEvent("PLAYER_LOGIN")
tracker:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        FP:ApplyTrackerScale()
        RestoreTrackerGeometry()
        RegisterBlizzardAddOnOptions()
        FP:RefreshTracker()
    end
end)
