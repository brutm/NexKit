local addonName, FP = ...

-------------------------------------------------------------------------------
-- ImporterFrame.lua – Route import dialog for NexusKit
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Main frame
-------------------------------------------------------------------------------
local importer = CreateFrame("Frame", "NexusKitImporterFrame", UIParent, "BackdropTemplate")
importer:SetSize(480, 340)
importer:SetPoint("CENTER")
importer:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
importer:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
importer:SetBackdropBorderColor(0.25, 0.25, 0.30, 1)
importer:SetMovable(true)
importer:EnableMouse(true)
importer:SetClampedToScreen(true)
importer:RegisterForDrag("LeftButton")
importer:SetScript("OnDragStart", importer.StartMoving)
importer:SetScript("OnDragStop", importer.StopMovingOrSizing)
importer:SetFrameStrata("DIALOG")
importer:SetToplevel(true)
importer:Hide()

importer:EnableKeyboard(true)
importer:SetScript("OnKeyDown", function(self, key)
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

-------------------------------------------------------------------------------
-- Title & Close button
-------------------------------------------------------------------------------
local titleText = importer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -12)
if FP.GetAccentColor then
    local r, g, b = FP:GetAccentColor()
    titleText:SetTextColor(r, g, b, 1)
else
    titleText:SetTextColor(1.0, 0.82, 0.0, 1)
end

local closeBtn = CreateFrame("Button", nil, importer, "UIPanelCloseButton")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    importer:Hide()
end)

-------------------------------------------------------------------------------
-- Scroll frame + EditBox for pasting import strings
-------------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", "NexusKitImportScroll", importer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -42)
scrollFrame:SetPoint("BOTTOMRIGHT", -36, 72)

local editBox = CreateFrame("EditBox", "NexusKitImportEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(scrollFrame:GetWidth() or 420)
editBox:SetTextInsets(4, 4, 4, 4)
editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

local placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
placeholder:SetPoint("TOPLEFT", 6, -6)
placeholder:SetJustifyH("LEFT")

local function UpdatePlaceholder()
    local txt = editBox:GetText() or ""
    if txt == "" and not editBox:HasFocus() then
        placeholder:Show()
    else
        placeholder:Hide()
    end
end

editBox:SetScript("OnTextChanged", UpdatePlaceholder)
editBox:SetScript("OnEditFocusGained", UpdatePlaceholder)
editBox:SetScript("OnEditFocusLost", UpdatePlaceholder)

scrollFrame:SetScrollChild(editBox)
scrollFrame:SetScript("OnSizeChanged", function(_, w)
    editBox:SetWidth(math.max(100, w - 4))
end)

local editBg = CreateFrame("Frame", nil, importer, "BackdropTemplate")
editBg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -4, 4)
editBg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 20, -4)
editBg:SetFrameLevel(importer:GetFrameLevel())
editBg:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
editBg:SetBackdropColor(0.04, 0.04, 0.06, 1)
editBg:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

-------------------------------------------------------------------------------
-- Error / success label
-------------------------------------------------------------------------------
local statusText = importer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statusText:SetPoint("BOTTOMLEFT", 16, 48)
statusText:SetPoint("BOTTOMRIGHT", -16, 48)
statusText:SetJustifyH("LEFT")
statusText:SetWordWrap(true)
statusText:SetMaxLines(2)
statusText:SetText("")

local function ShowError(msg)
    statusText:SetTextColor(1, 0.2, 0.2, 1)
    statusText:SetText(msg)
end

local function ShowSuccess(msg)
    statusText:SetTextColor(0.2, 1, 0.4, 1)
    statusText:SetText(msg)
end

local function ClearStatus()
    statusText:SetText("")
end

-------------------------------------------------------------------------------
-- Import & Cancel buttons
-------------------------------------------------------------------------------
local importBtn = CreateFrame("Button", nil, importer, "UIPanelButtonTemplate")
importBtn:SetSize(110, 26)
importBtn:SetPoint("BOTTOMRIGHT", -16, 14)
importBtn:SetScript("OnClick", function()
    local L = FP.L or {}
    ClearStatus()

    local text = editBox:GetText()
    if not text or text:match("^%s*$") then
        ShowError(L["IMPORT_ERROR_EMPTY"] or "Please paste an NK1: route string.")
        return
    end

    local result, err = FP:ParseImportString(text)
    if not result then
        ShowError(string.format(L["IMPORT_ERROR"] or "Import failed: %s", tostring(err)))
        return
    end

    local importOk, importErr = FP:ImportRoute(result)
    if not importOk then
        ShowError(string.format(L["IMPORT_ERROR"] or "Import failed: %s", tostring(importErr or "Unknown error")))
        return
    end

    local stepCount = result.steps and #result.steps or 0
    local routeName = result.title or result.routeId
    local successMsg = string.format(
        L["IMPORT_SUCCESS"] or "Route \"%s\" imported successfully (%d steps).",
        tostring(routeName),
        stepCount
    )
    ShowSuccess(successMsg)

    if FP.Print then
        FP:Print(successMsg)
    end

    if FP.After then
        FP:After(1.2, function()
            editBox:SetText("")
            ClearStatus()
            importer:Hide()
        end)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(1.2, function()
            editBox:SetText("")
            ClearStatus()
            importer:Hide()
        end)
    else
        editBox:SetText("")
        ClearStatus()
        importer:Hide()
    end
end)

local cancelBtn = CreateFrame("Button", nil, importer, "UIPanelButtonTemplate")
cancelBtn:SetSize(90, 26)
cancelBtn:SetPoint("RIGHT", importBtn, "LEFT", -8, 0)
cancelBtn:SetScript("OnClick", function()
    editBox:SetText("")
    ClearStatus()
    importer:Hide()
end)

-------------------------------------------------------------------------------
-- Localization sync
-------------------------------------------------------------------------------
function FP:RefreshImporterUI()
    local L = FP.L or {}
    if FP.GetAccentColor then
        local r, g, b = FP:GetAccentColor()
        titleText:SetTextColor(r, g, b, 1)
    end
    titleText:SetText(L["IMPORT_TITLE"] or "Import Route Pack")
    importBtn:SetText(L["IMPORT_BUTTON"] or "Import")
    cancelBtn:SetText(L["CANCEL"] or "Cancel")
    if self.FitButtonToText then
        self:FitButtonToText(importBtn, 110, 24, nil, 210)
        self:FitButtonToText(cancelBtn, 90, 24, nil, 190)
    end
    placeholder:SetText(L["IMPORT_EDIT_PLACEHOLDER"] or "Paste NK1: import string here...")
    UpdatePlaceholder()
end

importer:SetScript("OnShow", function()
    FP:RefreshImporterUI()
    ClearStatus()
    editBox:SetFocus()
end)

-------------------------------------------------------------------------------
-- Toggle helpers (used by slash command /nk import and Settings UI)
-------------------------------------------------------------------------------
function FP:ToggleImporterFrame()
    if importer:IsShown() then
        importer:Hide()
    else
        importer:Show()
    end
end

function FP:ToggleImporter()
    self:ToggleImporterFrame()
end

function FP:ShowImporter()
    importer:Show()
end

function FP:HideImporter()
    importer:Hide()
end
