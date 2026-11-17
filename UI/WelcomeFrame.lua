-- NexusKit - UI/WelcomeFrame.lua
-- First-time Welcome & Commands Guide (/nk help | [?] in Settings)
local addonName, FP = ...

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local welcomeFrame = CreateFrame("Frame", "NexusKitWelcomeFrame", UIParent, "BackdropTemplate")
welcomeFrame:SetSize(470, 490)
welcomeFrame:SetPoint("CENTER")
welcomeFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
welcomeFrame:SetBackdropColor(0.07, 0.08, 0.11, 0.97)
welcomeFrame:SetBackdropBorderColor(0.25, 0.27, 0.32, 1)
welcomeFrame:SetMovable(true)
welcomeFrame:EnableMouse(true)
welcomeFrame:SetClampedToScreen(true)
welcomeFrame:RegisterForDrag("LeftButton")
welcomeFrame:SetScript("OnDragStart", welcomeFrame.StartMoving)
welcomeFrame:SetScript("OnDragStop", welcomeFrame.StopMovingOrSizing)
welcomeFrame:SetFrameStrata("DIALOG")
welcomeFrame:SetToplevel(true)
welcomeFrame:Hide()

welcomeFrame:EnableKeyboard(true)
welcomeFrame:SetScript("OnKeyDown", function(self, key)
    local inCombat = InCombatLockdown and InCombatLockdown()
    if key == "ESCAPE" then
        self:Hide()
        if not inCombat and self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(false)
        end
    elseif not inCombat and self.SetPropagateKeyboardInput then
        self:SetPropagateKeyboardInput(true)
    end
end)

local headerLogo = welcomeFrame:CreateTexture(nil, "ARTWORK")
headerLogo:SetSize(21, 21)
headerLogo:SetPoint("TOPLEFT", 14, -12)
headerLogo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

local titleText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("LEFT", headerLogo, "RIGHT", 8, 0)
titleText:SetPoint("RIGHT", welcomeFrame, "RIGHT", -36, 0)
titleText:SetJustifyH("LEFT")
titleText:SetWordWrap(false)
titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

local closeBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelCloseButton")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    welcomeFrame:Hide()
end)

local introText = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
introText:SetPoint("TOPLEFT", 16, -44)
introText:SetPoint("TOPRIGHT", -16, -44)
introText:SetJustifyH("LEFT")
introText:SetWordWrap(true)
introText:SetTextColor(0.86, 0.89, 0.94, 1)

local bodyBox = CreateFrame("Frame", nil, welcomeFrame, "BackdropTemplate")
bodyBox:SetPoint("TOPLEFT", 14, -76)
bodyBox:SetPoint("BOTTOMRIGHT", -14, 74)
bodyBox:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
bodyBox:SetBackdropColor(0.05, 0.05, 0.08, 0.88)
bodyBox:SetBackdropBorderColor(0.20, 0.22, 0.27, 0.9)

local scrollFrame = CreateFrame("ScrollFrame", "NexusKitWelcomeScroll", bodyBox, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(400, 1)
scrollFrame:SetScrollChild(scrollChild)

local function CreateGuideSection(parent)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.09, 0.10, 0.14, 0.85)
    card:SetBackdropBorderColor(0.20, 0.24, 0.30, 0.85)
    card:SetWidth(398)

    local hdr = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 10, -8)
    hdr:SetPoint("TOPRIGHT", -10, -8)
    hdr:SetJustifyH("LEFT")
    hdr:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    card.header = hdr

    local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -5)
    body:SetWidth(378)
    body:SetJustifyH("LEFT")
    body:SetWordWrap(true)
    if body.SetSpacing then
        body:SetSpacing(3)
    end
    body:SetTextColor(0.90, 0.92, 0.95, 1)
    card.body = body

    return card
end

local secUI = CreateGuideSection(scrollChild)
local secFeatures = CreateGuideSection(scrollChild)
local secCmds = CreateGuideSection(scrollChild)
local secDonate = CreateGuideSection(scrollChild)

local cbDontShow = CreateFrame("CheckButton", nil, welcomeFrame)
cbDontShow:SetSize(22, 22)
cbDontShow:SetPoint("BOTTOMLEFT", 14, 44)
cbDontShow:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
cbDontShow:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
cbDontShow:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
cbDontShow:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

local cbDontShowLabel = cbDontShow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
cbDontShowLabel:SetPoint("LEFT", cbDontShow, "RIGHT", 6, 0)
cbDontShowLabel:SetJustifyH("LEFT")
cbDontShowLabel:SetTextColor(0.85, 0.88, 0.92, 1)

local openSettingsBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
openSettingsBtn:SetSize(136, 24)
openSettingsBtn:SetPoint("BOTTOMLEFT", 14, 14)

local donateBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
donateBtn:SetSize(146, 24)
donateBtn:SetPoint("LEFT", openSettingsBtn, "RIGHT", 10, 0)

local gotItBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
gotItBtn:SetSize(136, 24)
gotItBtn:SetPoint("BOTTOMRIGHT", -14, 14)

local printedFirstReminder = false
local openedAutomatically = false

local function PersistWelcomeCheckbox()
    if type(NexusKitDB) == "table" then
        NexusKitDB.seenWelcome = cbDontShow:GetChecked() and true or false
    end
end

cbDontShow:SetScript("OnClick", function()
    PersistWelcomeCheckbox()
end)

openSettingsBtn:SetScript("OnClick", function()
    PersistWelcomeCheckbox()
    welcomeFrame:Hide()
    if FP.ToggleSettingsFrame then
        FP:ToggleSettingsFrame()
    end
end)

donateBtn:SetScript("OnClick", function()
    if FP.ShowDonateDialog then
        FP:ShowDonateDialog()
    end
end)

gotItBtn:SetScript("OnClick", function()
    PersistWelcomeCheckbox()
    welcomeFrame:Hide()
end)

welcomeFrame:SetScript("OnHide", function()
    PersistWelcomeCheckbox()
    if openedAutomatically and not printedFirstReminder then
        printedFirstReminder = true
        local L = FP.L or {}
        if FP.Print then
            FP:Print(L["HELP_CHAT_REMINDER"] or "Tip: type /nk help anytime to reopen the commands guide.")
        end
    end
    openedAutomatically = false
end)

local function LayoutSectionCard(card, prevCard, titleStr, bodyStr)
    local _, _, _, hex = FP:GetAccentColor()
    card.header:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    card.header:SetText(titleStr or "")
    card.body:SetText((bodyStr or ""):gsub("|cff00ff96", "|cff" .. hex))
    card:ClearAllPoints()
    if not prevCard then
        card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    else
        card:SetPoint("TOPLEFT", prevCard, "BOTTOMLEFT", 0, -8)
    end
    local hHdr = math.ceil(card.header:GetStringHeight() or 14)
    local hBody = math.ceil(card.body:GetStringHeight() or 40)
    local totalH = 8 + hHdr + 5 + hBody + 10
    card:SetHeight(math.max(44, totalH))
    return totalH
end

function FP:RefreshWelcomeUI()
    local L = FP.L or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    titleText:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    local ver = FP.VERSION and (" v" .. tostring(FP.VERSION)) or ""
    titleText:SetText((L["HELP_TITLE"] or "NexKit - Welcome & Commands") .. ver)
    introText:SetText(L["HELP_INTRO"] or "Welcome! Quick guide to NexKit buttons, smart features, and slash commands.")
    cbDontShowLabel:SetText(L["HELP_DONT_SHOW_AGAIN"] or "Don't show automatically on login")
    openSettingsBtn:SetText(L["HELP_OPEN_SETTINGS"] or "Open Settings")
    donateBtn:SetText(L["DONATE_BTN"] or "Donate")
    gotItBtn:SetText(L["HELP_GOT_IT"] or "Got it!")
    if self.FitButtonToText then
        self:FitButtonToText(openSettingsBtn, 136, 24, nil, 180)
        self:FitButtonToText(donateBtn, 146, 24, nil, 180)
        self:FitButtonToText(gotItBtn, 136, 24, nil, 180)
    end

    local h1 = LayoutSectionCard(
        secUI, nil,
        L["HELP_SEC_UI"] or "Tracker Buttons",
        L["HELP_UI_ITEMS"] or "- Sync Quests: Syncs tracker with active Quest Log.\n- Anvil icon: Opens/closes Profession Skill Advisor.\n- Gear icon: Opens 4-tab Settings window.\n- Lock / Minimize & Right-click: Lock/collapse or quick toggles."
    )
    local h2 = LayoutSectionCard(
        secFeatures, secUI,
        L["HELP_SEC_FEATURES"] or "Smart Features",
        L["HELP_FEAT_ITEMS"] or "- Arrow & Trajectories: Distance yards, map/minimap pins & route lines.\n- Red X & Rewards: Marks turn-ins with X and tags best rewards (SPEC/GOLD).\n- Buff & Tracking Bar: Reminds missing buffs, weapon oils & mineral/herb tracking."
    )
    local h3 = LayoutSectionCard(
        secCmds, secFeatures,
        L["HELP_SEC_CMDS"] or "Slash Commands (/nk)",
        L["HELP_CMD_ITEMS"] or "/nk help - Reopen this guide\n/nk config - Settings window\n/nk sync - Toggle Quest Log Sync\n/nk prof - Toggle Profession Advisor\n/nk buffs - Check Buff & Tracking Advisor\n/nk donate - Support the addon\n/nk import - Import custom route\n/nk toggle - Show / hide tracker\n/nk reset - Reset character progress\n/nk lang <code> - Switch language"
    )
    local h4 = LayoutSectionCard(
        secDonate, secCmds,
        L["HELP_SEC_DONATE"] or "Support & Legal (GPLv3)",
        L["HELP_DONATE_ITEMS"] or "- NexKit is free & open-source software.\n- Type /nk donate or support via Ko-fi.\n- All rights reserved under GNU GPL v3."
    )

    scrollChild:SetHeight(math.max(100, h1 + h2 + h3 + h4 + 30))
end

-------------------------------------------------------------------------------
-- Dedicated In-Game Donation & Support Dialog
-------------------------------------------------------------------------------
local donateDialog
function FP:ShowDonateDialog(customUrl)
    local L = FP.L or {}
    local url = customUrl or L["DONATE_URL"] or "https://ko-fi.com/kh4dgar"

    if not donateDialog then
        donateDialog = CreateFrame("Frame", "NexKitDonateDialog", UIParent, "BackdropTemplate")
        donateDialog:SetSize(450, 195)
        donateDialog:SetPoint("CENTER")
        donateDialog:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        donateDialog:SetBackdropColor(0.07, 0.08, 0.11, 0.98)
        donateDialog:SetBackdropBorderColor(0.25, 0.27, 0.32, 1)
        donateDialog:SetMovable(true)
        donateDialog:EnableMouse(true)
        donateDialog:SetClampedToScreen(true)
        donateDialog:RegisterForDrag("LeftButton")
        donateDialog:SetScript("OnDragStart", donateDialog.StartMoving)
        donateDialog:SetScript("OnDragStop", donateDialog.StopMovingOrSizing)
        donateDialog:SetFrameStrata("DIALOG")
        donateDialog:SetToplevel(true)

        local dTitle = donateDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        dTitle:SetPoint("TOP", 0, -14)
        dTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        donateDialog.title = dTitle

        local dClose = CreateFrame("Button", nil, donateDialog, "UIPanelCloseButton")
        dClose:SetSize(24, 24)
        dClose:SetPoint("TOPRIGHT", -4, -4)
        dClose:SetScript("OnClick", function() donateDialog:Hide() end)

        local dDesc = donateDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dDesc:SetPoint("TOPLEFT", 18, -42)
        dDesc:SetPoint("TOPRIGHT", -18, -42)
        dDesc:SetJustifyH("CENTER")
        dDesc:SetWordWrap(true)
        dDesc:SetTextColor(0.88, 0.90, 0.94, 1)
        donateDialog.desc = dDesc

        local dHint = donateDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dHint:SetPoint("TOP", dDesc, "BOTTOM", 0, -10)
        dHint:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        donateDialog.hint = dHint

        local boxBg = CreateFrame("Frame", nil, donateDialog, "BackdropTemplate")
        boxBg:SetSize(380, 26)
        boxBg:SetPoint("TOP", dHint, "BOTTOM", 0, -6)
        boxBg:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        boxBg:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
        boxBg:SetBackdropBorderColor(0.30, 0.35, 0.42, 1)

        local editBox = CreateFrame("EditBox", nil, boxBg)
        editBox:SetSize(364, 22)
        editBox:SetPoint("CENTER", 0, 0)
        editBox:SetFontObject("GameFontHighlight")
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() donateDialog:Hide() end)
        editBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
        end)
        editBox:SetScript("OnMouseUp", function(self)
            self:HighlightText()
        end)
        donateDialog.editBox = editBox

        local dCloseBtn = CreateFrame("Button", nil, donateDialog, "UIPanelButtonTemplate")
        dCloseBtn:SetSize(120, 24)
        dCloseBtn:SetPoint("BOTTOM", 0, 14)
        dCloseBtn:SetScript("OnClick", function() donateDialog:Hide() end)
        donateDialog.closeBtn = dCloseBtn
    end

    donateDialog.title:SetText(L["DONATE_TITLE"] or "Support NexKit Development")
    donateDialog.desc:SetText(L["DONATE_DESC"] or "NexKit is free & open-source software for WoW Forever. If you enjoy using it, consider supporting ongoing updates with a donation!")
    donateDialog.hint:SetText(L["DONATE_COPY_HINT"] or "Press Ctrl+C to copy the donation link:")
    donateDialog.closeBtn:SetText(L["CLOSE"] or "Close")
    donateDialog.editBox:SetText(url)
    donateDialog:Show()
    donateDialog.editBox:SetFocus()
    donateDialog.editBox:HighlightText()
end

function FP:ShowWelcomeFrame(isAutoFirstRun)
    openedAutomatically = isAutoFirstRun and true or false
    if isAutoFirstRun then
        cbDontShow:SetChecked(true)
    else
        cbDontShow:SetChecked(NexusKitDB and NexusKitDB.seenWelcome == true)
    end
    welcomeFrame:Show()
    self:RefreshWelcomeUI()
    scrollFrame:SetVerticalScroll(0)
end

function FP:ToggleWelcomeFrame()
    if welcomeFrame:IsShown() then
        welcomeFrame:Hide()
    else
        self:ShowWelcomeFrame(false)
    end
end

local loginCheckDone = false
local welcomeEventFrame = CreateFrame("Frame")
welcomeEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
welcomeEventFrame:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_ENTERING_WORLD" or loginCheckDone then return end
    loginCheckDone = true
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    if NexusKitDB and not NexusKitDB.seenWelcome then
        local function TryAutoShow()
            if NexusKitDB and not NexusKitDB.seenWelcome and not (InCombatLockdown and InCombatLockdown()) then
                FP:ShowWelcomeFrame(true)
            end
        end
        if FP.After then
            FP:After(1.2, TryAutoShow)
        elseif C_Timer and C_Timer.After then
            C_Timer.After(1.2, TryAutoShow)
        else
            TryAutoShow()
        end
    end
end)
