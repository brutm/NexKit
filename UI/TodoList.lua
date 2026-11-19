-- NexusKit - UI/TodoList.lua
-- In-game player personal To-Do list, goals, and reminders module.
-- Allows players to create, organize, check off, reopen from archive, and track tasks on screen.
local addonName, FP = ...

local ACCENT = { r = 0, g = 1, b = 0.59 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local currentScope = "char" -- "char" or "global"
local currentFilter = "all" -- "all", "active", "done"

-------------------------------------------------------------------------------
-- DB Helpers
-------------------------------------------------------------------------------
local function EnsureTodoTables()
    if type(NexusKitCharDB) ~= "table" then
        _G.NexusKitCharDB = _G.NexusKitCharDB or {}
    end
    if type(NexusKitCharDB.todoList) ~= "table" then
        NexusKitCharDB.todoList = {}
    end

    if type(NexusKitDB) ~= "table" then
        _G.NexusKitDB = _G.NexusKitDB or {}
    end
    if type(NexusKitDB.todoListGlobal) ~= "table" then
        NexusKitDB.todoListGlobal = {}
    end
    if type(NexusKitDB.settings) ~= "table" then
        NexusKitDB.settings = {}
    end
end

local function GetTodoList(scope)
    EnsureTodoTables()
    if scope == "global" then
        return NexusKitDB.todoListGlobal
    end
    return NexusKitCharDB.todoList
end

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

-------------------------------------------------------------------------------
-- Main UI Frame
-------------------------------------------------------------------------------
local todoFrame = CreateFrame("Frame", "NexusKitTodoFrame", UIParent, "BackdropTemplate")
todoFrame:SetSize(430, 500)
todoFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
todoFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
todoFrame:SetBackdropColor(0.06, 0.08, 0.12, 0.96)
todoFrame:SetBackdropBorderColor(0.22, 0.25, 0.30, 1)
todoFrame:SetFrameStrata("HIGH")
todoFrame:SetMovable(true)
todoFrame:EnableMouse(true)
todoFrame:SetClampedToScreen(true)
todoFrame:RegisterForDrag("LeftButton")
todoFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
todoFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
todoFrame:Hide()

_G["NexusKitTodoFrame"] = todoFrame
if type(UISpecialFrames) == "table" then
    local found = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "NexusKitTodoFrame" then found = true break end
    end
    if not found then table.insert(UISpecialFrames, "NexusKitTodoFrame") end
end

-- Header Background
local headerBg = todoFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
headerBg:SetPoint("TOPLEFT", 4, -4)
headerBg:SetPoint("TOPRIGHT", -4, -4)
headerBg:SetHeight(28)
headerBg:SetColorTexture(ACCENT.r * 0.18, ACCENT.g * 0.18, ACCENT.b * 0.18, 0.55)

local headerDiv = todoFrame:CreateTexture(nil, "ARTWORK")
headerDiv:SetPoint("TOPLEFT", 4, -32)
headerDiv:SetPoint("TOPRIGHT", -4, -32)
headerDiv:SetHeight(1)
headerDiv:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.40)

local titleFs = todoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleFs:SetPoint("TOPLEFT", 12, -10)
titleFs:SetText("|cff00ff96NexusKit|r — " .. ((FP.L and FP.L["TODO_TITLE"]) or "To-Do List & Goals"))
titleFs:SetTextColor(1, 1, 1, 1)

local closeBtn = CreateFrame("Button", nil, todoFrame, "UIPanelCloseButton")
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", -5, -6)
closeBtn:SetScript("OnClick", function() todoFrame:Hide() end)

-------------------------------------------------------------------------------
-- Scope Tabs (Personaggio vs Account)
-------------------------------------------------------------------------------
local tabChar = CreateFrame("Button", nil, todoFrame, "BackdropTemplate")
local tabGlobal = CreateFrame("Button", nil, todoFrame, "BackdropTemplate")

local function StyleScopeTab(btn, label, active)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    if active then
        btn:SetBackdropColor(ACCENT.r * 0.25, ACCENT.g * 0.25, ACCENT.b * 0.25, 0.90)
        btn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.90)
        btn.text:SetTextColor(1, 1, 1, 1)
    else
        btn:SetBackdropColor(0.10, 0.12, 0.16, 0.80)
        btn:SetBackdropBorderColor(0.25, 0.28, 0.35, 0.70)
        btn.text:SetTextColor(0.70, 0.75, 0.80, 1)
    end
end

local function CreateScopeTab(btn, text, isFirst)
    btn:SetSize(110, 22)
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText(text)
    btn.text = fs
    btn:SetScript("OnEnter", function(self)
        if (self == tabChar and currentScope ~= "char") or (self == tabGlobal and currentScope ~= "global") then
            self:SetBackdropBorderColor(ACCENT.r * 0.7, ACCENT.g * 0.7, ACCENT.b * 0.7, 0.8)
            self.text:SetTextColor(1, 1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        local isAct = (self == tabChar and currentScope == "char") or (self == tabGlobal and currentScope == "global")
        StyleScopeTab(self, text, isAct)
    end)
end

CreateScopeTab(tabChar, (FP.L and FP.L["TODO_TAB_CHAR"]) or "Character", true)
tabChar:SetPoint("TOPLEFT", 12, -40)
tabChar:SetScript("OnClick", function()
    currentScope = "char"
    FP:RefreshTodoListUI()
end)

CreateScopeTab(tabGlobal, (FP.L and FP.L["TODO_TAB_GLOBAL"]) or "Account", false)
tabGlobal:SetPoint("LEFT", tabChar, "RIGHT", 6, 0)
tabGlobal:SetScript("OnClick", function()
    currentScope = "global"
    FP:RefreshTodoListUI()
end)

-------------------------------------------------------------------------------
-- Filter Buttons (Tutte | Attive | Archivio / Fatte)
-------------------------------------------------------------------------------
local filterBtns = {}
local function CreateFilterBtn(key, label, pointTo, xOff)
    local btn = CreateFrame("Button", nil, todoFrame, "BackdropTemplate")
    btn:SetSize(80, 20)
    btn:SetPoint("LEFT", pointTo, "RIGHT", xOff or 4, 0)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText(label)
    btn.text = fs
    btn:SetScript("OnClick", function()
        currentFilter = key
        FP:RefreshTodoListUI()
    end)
    filterBtns[key] = btn
    return btn
end

local fAll = CreateFilterBtn("all", (FP.L and FP.L["TODO_FILTER_ALL"]) or "All", tabGlobal, 12)
local fActive = CreateFilterBtn("active", (FP.L and FP.L["TODO_FILTER_ACTIVE"]) or "To-Do", fAll, 4)
local fDone = CreateFilterBtn("done", (FP.L and FP.L["TODO_FILTER_DONE"]) or "Archive", fActive, 4)

local function UpdateFilterButtonsVisual()
    for k, btn in pairs(filterBtns) do
        local active = (currentFilter == k)
        if active then
            btn:SetBackdropColor(0.18, 0.28, 0.35, 0.90)
            btn:SetBackdropBorderColor(0.40, 0.85, 1.0, 0.95)
            btn.text:SetTextColor(0.40, 0.85, 1.0, 1)
        else
            btn:SetBackdropColor(0.08, 0.10, 0.14, 0.70)
            btn:SetBackdropBorderColor(0.20, 0.24, 0.30, 0.60)
            btn.text:SetTextColor(0.65, 0.70, 0.75, 0.9)
        end
    end
end

-------------------------------------------------------------------------------
-- Add Task Input Bar
-------------------------------------------------------------------------------
local inputBar = CreateFrame("Frame", nil, todoFrame, "BackdropTemplate")
inputBar:SetHeight(28)
inputBar:SetPoint("TOPLEFT", 12, -68)
inputBar:SetPoint("TOPRIGHT", -12, -68)
inputBar:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
inputBar:SetBackdropColor(0.04, 0.05, 0.07, 0.95)
inputBar:SetBackdropBorderColor(0.22, 0.25, 0.32, 0.85)

local addBtn = CreateFrame("Button", nil, inputBar, "BackdropTemplate")
addBtn:SetSize(72, 22)
addBtn:SetPoint("RIGHT", -3, 0)
addBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
addBtn:SetBackdropColor(ACCENT.r * 0.22, ACCENT.g * 0.22, ACCENT.b * 0.22, 0.95)
addBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)

local addBtnTxt = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
addBtnTxt:SetPoint("CENTER", 0, 0)
addBtnTxt:SetText("+ " .. ((FP.L and FP.L["TODO_ADD"]) or "Add"))
addBtnTxt:SetTextColor(1, 1, 1, 1)

addBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(ACCENT.r * 0.35, ACCENT.g * 0.35, ACCENT.b * 0.35, 1)
    addBtnTxt:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
end)
addBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(ACCENT.r * 0.22, ACCENT.g * 0.22, ACCENT.b * 0.22, 0.95)
    addBtnTxt:SetTextColor(1, 1, 1, 1)
end)

local editBox = CreateFrame("EditBox", nil, inputBar)
editBox:SetFontObject("GameFontHighlightSmall")
editBox:SetPoint("LEFT", 8, 0)
editBox:SetPoint("RIGHT", addBtn, "LEFT", -6, 0)
editBox:SetHeight(20)
editBox:SetAutoFocus(false)
editBox:SetMaxLetters(120)

local placeholder = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
placeholder:SetPoint("LEFT", editBox, "LEFT", 0, 0)
placeholder:SetText((FP.L and FP.L["TODO_INPUT_HINT"]) or "Type a task or note and press Enter...")
placeholder:SetTextColor(0.50, 0.55, 0.60, 0.85)

editBox:SetScript("OnTextChanged", function(self)
    local txt = self:GetText() or ""
    if txt == "" then
        placeholder:Show()
    else
        placeholder:Hide()
    end
end)

local function SubmitNewTask()
    local raw = editBox:GetText() or ""
    local txt = raw:match("^%s*(.-)%s*$")
    if not txt or txt == "" then return end

    FP:AddTodoTask(txt, currentScope)
    editBox:SetText("")
    editBox:ClearFocus()
end

editBox:SetScript("OnEnterPressed", SubmitNewTask)
editBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)
addBtn:SetScript("OnClick", SubmitNewTask)

-------------------------------------------------------------------------------
-- Scrollable Task List
-------------------------------------------------------------------------------
local scrollFrame = CreateFrame("ScrollFrame", "NexusKitTodoScrollFrame", todoFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 12, -104)
scrollFrame:SetPoint("BOTTOMRIGHT", -32, 42)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(scrollFrame:GetWidth() or 386, 1)
scrollFrame:SetScrollChild(scrollChild)

local emptyFs = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
emptyFs:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
emptyFs:SetText((FP.L and FP.L["TODO_EMPTY"]) or "No tasks yet.\nType a task above to get started!")
emptyFs:SetJustifyH("CENTER")
emptyFs:Hide()

local taskRows = {}
local currentlyEditingRow = nil

local function CancelEditingRow(row)
    if not row or not row.isEditing then return end
    row.isEditing = false
    if currentlyEditingRow == row then
        currentlyEditingRow = nil
    end
    if row.inlineEditBox then
        row.inlineEditBox:Hide()
    end
    if row.textFs then
        row.textFs:Show()
    end
    if row.task and row.task.done and row.strikeLine then
        row.strikeLine:Show()
    end
    FP:RefreshTodoListUI()
end

local function SaveAndStopEditingRow(row)
    if not row or not row.isEditing then return end
    row.isEditing = false
    if currentlyEditingRow == row then
        currentlyEditingRow = nil
    end
    local newText = row.inlineEditBox and row.inlineEditBox:GetText()
    if row.inlineEditBox then
        row.inlineEditBox:Hide()
    end
    if row.textFs then
        row.textFs:Show()
    end
    if row.task and newText and newText:match("%S") then
        FP:EditTodoTask(row.task.id, currentScope, newText)
    else
        FP:RefreshTodoListUI()
    end
end

local function StartEditingRow(row)
    if not row or not row.task then return end
    if currentlyEditingRow and currentlyEditingRow ~= row then
        SaveAndStopEditingRow(currentlyEditingRow)
    end
    currentlyEditingRow = row
    row.isEditing = true
    if row.textFs then row.textFs:Hide() end
    if row.strikeLine then row.strikeLine:Hide() end
    if row.inlineEditBox then
        row.inlineEditBox:SetText(row.task.text or "")
        row.inlineEditBox:Show()
        row.inlineEditBox:SetFocus()
        row.inlineEditBox:HighlightText()
    end
end

local function GetOrCreateTaskRow(index)
    local row = taskRows[index]
    if row then return row end

    row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    row:SetHeight(26)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 28))
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.09, 0.11, 0.15, 0.85)
    row:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.70)
    row:EnableMouse(true)

    -- Checkbox Button
    local checkBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
    checkBtn:SetSize(16, 16)
    checkBtn:SetPoint("LEFT", 6, 0)
    checkBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    checkBtn:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
    checkBtn:SetBackdropBorderColor(0.35, 0.40, 0.50, 0.85)

    -- Native Blizzard Glowing Checkmark texture
    local checkMark = checkBtn:CreateTexture(nil, "OVERLAY")
    checkMark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkMark:SetSize(18, 18)
    checkMark:SetPoint("CENTER", 0, 0)
    checkMark:Hide()
    row.checkMark = checkMark
    row.checkBtn = checkBtn

    -- Delete ("x") button
    local delBtn = CreateFrame("Button", nil, row)
    delBtn:SetSize(16, 16)
    delBtn:SetPoint("RIGHT", -4, 0)
    local delTxt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    delTxt:SetPoint("CENTER", 0, 0)
    delTxt:SetText("x")
    delTxt:SetTextColor(0.70, 0.40, 0.40, 1)
    delBtn.txt = delTxt
    delBtn:SetScript("OnEnter", function(self)
        delTxt:SetTextColor(1, 0.2, 0.2, 1)
        row:SetBackdropColor(0.16, 0.08, 0.10, 0.90)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText((FP.L and FP.L["TODO_DEL_TIP"]) or "Elimina promemoria")
        GameTooltip:Show()
    end)
    delBtn:SetScript("OnLeave", function()
        delTxt:SetTextColor(0.70, 0.40, 0.40, 1)
        if row.task and row.task.done then
            row:SetBackdropColor(0.06, 0.08, 0.07, 0.75)
        else
            row:SetBackdropColor(0.09, 0.11, 0.15, 0.85)
        end
        GameTooltip:Hide()
    end)
    delBtn:SetScript("OnClick", function()
        if row.task then
            FP:DeleteTodoTask(row.task.id, currentScope)
        end
    end)
    row.delBtn = delBtn

    -- Move Up Button (Blizzard ScrollBar Up Arrow texture)
    local upBtn = CreateFrame("Button", nil, row)
    upBtn:SetSize(16, 16)
    upBtn:SetPoint("RIGHT", delBtn, "LEFT", -2, 0)
    upBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    upBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    upBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    upBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText((FP.L and FP.L["TODO_MOVE_UP"]) or "Sposta su (Priorita piu alta)")
        GameTooltip:Show()
    end)
    upBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    upBtn:SetScript("OnClick", function()
        if row.task then
            FP:MoveTodoTask(row.task.id, currentScope, -1)
        end
    end)
    row.upBtn = upBtn

    -- Move Down Button (Blizzard ScrollBar Down Arrow texture)
    local dnBtn = CreateFrame("Button", nil, row)
    dnBtn:SetSize(16, 16)
    dnBtn:SetPoint("RIGHT", upBtn, "LEFT", -1, 0)
    dnBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    dnBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    dnBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    dnBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText((FP.L and FP.L["TODO_MOVE_DOWN"]) or "Sposta giu")
        GameTooltip:Show()
    end)
    dnBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    dnBtn:SetScript("OnClick", function()
        if row.task then
            FP:MoveTodoTask(row.task.id, currentScope, 1)
        end
    end)
    row.dnBtn = dnBtn

    -- Edit Button (Blizzard Note/Pencil texture)
    local editBtn = CreateFrame("Button", nil, row)
    editBtn:SetSize(16, 16)
    editBtn:SetPoint("RIGHT", dnBtn, "LEFT", -1, 0)
    editBtn:SetNormalTexture("Interface\\FriendsFrame\\UI-FriendsFrame-Note")
    editBtn:SetPushedTexture("Interface\\FriendsFrame\\UI-FriendsFrame-Note")
    editBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    editBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText((FP.L and FP.L["TODO_EDIT_TIP"]) or "Modifica nota (oppure tasto destro)")
        GameTooltip:Show()
    end)
    editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    editBtn:SetScript("OnClick", function()
        StartEditingRow(row)
    end)
    row.editBtn = editBtn

    -- Task text
    local textFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textFs:SetPoint("LEFT", checkBtn, "RIGHT", 8, 0)
    textFs:SetPoint("RIGHT", editBtn, "LEFT", -4, 0)
    textFs:SetJustifyH("LEFT")
    textFs:SetWordWrap(false)
    row.textFs = textFs

    -- Inline EditBox
    local inlineEditBox = CreateFrame("EditBox", nil, row, "BackdropTemplate")
    inlineEditBox:SetPoint("LEFT", checkBtn, "RIGHT", 6, 0)
    inlineEditBox:SetPoint("RIGHT", editBtn, "LEFT", -4, 0)
    inlineEditBox:SetHeight(18)
    inlineEditBox:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    inlineEditBox:SetBackdropColor(0.04, 0.06, 0.09, 0.98)
    inlineEditBox:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
    inlineEditBox:SetFontObject("GameFontHighlightSmall")
    inlineEditBox:SetAutoFocus(false)
    inlineEditBox:SetTextInsets(4, 4, 0, 0)
    inlineEditBox:SetMaxLetters(140)
    inlineEditBox:Hide()

    inlineEditBox:SetScript("OnEnterPressed", function()
        SaveAndStopEditingRow(row)
    end)
    inlineEditBox:SetScript("OnEscapePressed", function()
        CancelEditingRow(row)
    end)
    inlineEditBox:SetScript("OnEditFocusLost", function()
        if row.isEditing then
            SaveAndStopEditingRow(row)
        end
    end)
    row.inlineEditBox = inlineEditBox

    -- Strikethrough horizontal line across completed tasks
    local strikeLine = row:CreateTexture(nil, "OVERLAY", nil, 3)
    strikeLine:SetHeight(1)
    strikeLine:SetColorTexture(0.55, 0.60, 0.65, 0.90)
    strikeLine:Hide()
    row.strikeLine = strikeLine

    local function ToggleDone()
        if row.task then
            FP:ToggleTodoTaskDone(row.task.id, currentScope)
        end
    end
    checkBtn:SetScript("OnClick", ToggleDone)

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            StartEditingRow(self)
        else
            ToggleDone()
        end
    end)

    row:SetScript("OnEnter", function(self)
        if self.task and self.task.done then
            self:SetBackdropColor(0.09, 0.16, 0.12, 0.95)
        else
            self:SetBackdropColor(0.14, 0.18, 0.25, 0.95)
        end
        if self.task and self.task.created then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.task.text or "Promemoria", 1, 1, 1, 1, true)
            GameTooltip:AddLine(string.format("Creato: %s", self.task.created), 0.65, 0.65, 0.65)
            if self.task.edited then
                GameTooltip:AddLine(string.format("Modificato: %s", self.task.edited), 0.55, 0.55, 0.55)
            end
            if self.task.done then
                GameTooltip:AddLine("Stato: |cff00ff00Completato (Tagliato)|r", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cff40e0ffClick sinistro|r: riprendi promemoria.", 0.5, 0.8, 0.9)
            else
                GameTooltip:AddLine("Stato: |cff40e0ffIn corso (Da fare)|r", 0.7, 0.7, 0.7)
                GameTooltip:AddLine("|cff40e0ffClick sinistro|r: completa promemoria.", 0.5, 0.8, 0.9)
            end
            GameTooltip:AddLine("|cffffff00Click destro o icona nota|r: modifica testo.", 0.9, 0.85, 0.4)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        if self.task and self.task.done then
            self:SetBackdropColor(0.06, 0.08, 0.07, 0.75)
        else
            self:SetBackdropColor(0.09, 0.11, 0.15, 0.85)
        end
        if GameTooltip and GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)

    taskRows[index] = row
    return row
end

-------------------------------------------------------------------------------
-- Bottom Toolbar
-------------------------------------------------------------------------------
local bottomDiv = todoFrame:CreateTexture(nil, "ARTWORK")
bottomDiv:SetPoint("BOTTOMLEFT", 4, 38)
bottomDiv:SetPoint("BOTTOMRIGHT", -4, 38)
bottomDiv:SetHeight(1)
bottomDiv:SetColorTexture(0.20, 0.24, 0.30, 0.70)

local statusFs = todoFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
statusFs:SetPoint("BOTTOMLEFT", 12, 12)
statusFs:SetText("0 attive, 0 completate")

local hudCheckBtn = CreateFrame("CheckButton", nil, todoFrame, "UICheckButtonTemplate")
hudCheckBtn:SetSize(20, 20)
hudCheckBtn:SetPoint("LEFT", statusFs, "RIGHT", 16, 0)
local hudCheckLbl = hudCheckBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hudCheckLbl:SetPoint("LEFT", hudCheckBtn, "RIGHT", 2, 0)
hudCheckLbl:SetText((FP.L and FP.L["TODO_SHOW_HUD"]) or "On-screen HUD")

hudCheckBtn:SetScript("OnClick", function(self)
    local s = GetSettings()
    s.showTodoHud = self:GetChecked() and true or false
    if FP.RefreshTodoHUD then FP:RefreshTodoHUD() end
end)

local clearDoneBtn = CreateFrame("Button", nil, todoFrame, "BackdropTemplate")
clearDoneBtn:SetSize(120, 20)
clearDoneBtn:SetPoint("BOTTOMRIGHT", -12, 10)
clearDoneBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
clearDoneBtn:SetBackdropColor(0.14, 0.08, 0.10, 0.85)
clearDoneBtn:SetBackdropBorderColor(0.50, 0.30, 0.35, 0.80)
local clearDoneTxt = clearDoneBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
clearDoneTxt:SetPoint("CENTER", 0, 0)
clearDoneTxt:SetText((FP.L and FP.L["TODO_CLEAR_DONE"]) or "Svuota archivio")
clearDoneTxt:SetTextColor(0.9, 0.8, 0.85, 1)

clearDoneBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.25, 0.10, 0.12, 0.95)
    clearDoneTxt:SetTextColor(1, 1, 1, 1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText((FP.L and FP.L["TODO_CLEAR_DONE_TIP"]) or "Elimina definitivamente i promemoria completati dall'archivio.")
    GameTooltip:Show()
end)
clearDoneBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.14, 0.08, 0.10, 0.85)
    clearDoneTxt:SetTextColor(0.9, 0.8, 0.85, 1)
    GameTooltip:Hide()
end)
clearDoneBtn:SetScript("OnClick", function()
    FP:ClearDoneTodoTasks(currentScope)
end)

-------------------------------------------------------------------------------
-- Floating Mini-HUD (Promemoria a Schermo / To-Do Notes)
-------------------------------------------------------------------------------
local todoHud = CreateFrame("Frame", "NexusKitTodoHUD", UIParent, "BackdropTemplate")
todoHud:SetSize(236, 48)
todoHud:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -320)
if todoHud.SetDontSavePosition then todoHud:SetDontSavePosition(true) end
todoHud:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
todoHud:SetBackdropColor(0.05, 0.07, 0.10, 0.92)
todoHud:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.70)
todoHud:SetMovable(true)
todoHud:EnableMouse(true)
todoHud:SetClampedToScreen(true)

local function SaveHudPosition()
    if NexusKitDB and NexusKitDB.settings then
        local ux, uy = UIParent:GetCenter()
        local fx, fy = todoHud:GetCenter()
        if ux and uy and fx and fy then
            NexusKitDB.settings.todoHudPos = { x = fx - ux, y = fy - uy }
        end
    end
end

todoHud:RegisterForDrag("LeftButton")
todoHud:SetScript("OnDragStart", function(self)
    local s = GetSettings()
    if s.todoHudLocked == true then return end
    self.isDragging = true
    self:StartMoving()
end)
todoHud:SetScript("OnDragStop", function(self)
    self.isDragging = false
    self:StopMovingOrSizing()
    SaveHudPosition()
end)
todoHud:Hide()

todoHud.headerBg = todoHud:CreateTexture(nil, "BACKGROUND", nil, 1)
todoHud.headerBg:SetPoint("TOPLEFT", 1, -1)
todoHud.headerBg:SetPoint("TOPRIGHT", -1, -1)
todoHud.headerBg:SetHeight(20)
todoHud.headerBg:SetColorTexture(ACCENT.r * 0.18, ACCENT.g * 0.18, ACCENT.b * 0.18, 0.55)

local hudTitle = todoHud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hudTitle:SetPoint("TOPLEFT", 8, -4)
hudTitle:SetText((FP.L and FP.L["TODO_HUD_TITLE"]) or "To-Do Notes")
hudTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

-- Options Button (Native Blizzard UI-OptionsButton cog)
local hudOpenBtn = CreateFrame("Button", nil, todoHud)
hudOpenBtn:SetSize(14, 14)
hudOpenBtn:SetPoint("TOPRIGHT", -4, -3)
hudOpenBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
hudOpenBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
hudOpenBtn:SetScript("OnClick", function()
    FP:ToggleTodoList()
end)
hudOpenBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Apri To-Do List")
    GameTooltip:Show()
end)
hudOpenBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Lock/Unlock Padlock Button
local hudLockBtn = CreateFrame("Button", nil, todoHud)
hudLockBtn:SetSize(14, 14)
hudLockBtn:SetPoint("TOPRIGHT", hudOpenBtn, "TOPLEFT", -3, 0)
hudLockBtn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")
if FP.CropButtonTextures then FP:CropButtonTextures(hudLockBtn, 0.15) end

local function UpdateHudLockVisual()
    local s = GetSettings()
    local locked = s.todoHudLocked == true
    if locked then
        hudLockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
    else
        hudLockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    end
end

hudLockBtn:SetScript("OnClick", function()
    local s = GetSettings()
    s.todoHudLocked = not (s.todoHudLocked == true)
    UpdateHudLockVisual()
    if s.todoHudLocked then
        FP:Print("NexusKit: Finestra Promemoria To-Do bloccata.")
    else
        FP:Print("NexusKit: Finestra Promemoria To-Do sbloccata (trascinala con il tasto sinistro per spostarla).")
    end
end)
hudLockBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local s = GetSettings()
    if s.todoHudLocked == true then
        GameTooltip:SetText("Finestra To-Do Notes: Bloccata", 1, 0.82, 0)
        GameTooltip:AddLine("Clicca per sbloccare e trascinare la finestra.", 0.85, 0.85, 0.85, true)
    else
        GameTooltip:SetText("Finestra To-Do Notes: Sbloccata", 0.4, 0.9, 1)
        GameTooltip:AddLine("Trascina con il tasto sinistro per spostare.\nClicca per bloccare la posizione.", 0.85, 0.85, 0.85, true)
    end
    GameTooltip:Show()
end)
hudLockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local hudRows = {}
local function GetOrCreateHudRow(idx)
    local r = hudRows[idx]
    if r then return r end

    r = CreateFrame("Button", nil, todoHud)
    r:SetHeight(18)
    r:SetPoint("TOPLEFT", 6, -24 - ((idx - 1) * 19))
    r:SetPoint("TOPRIGHT", -6, -24 - ((idx - 1) * 19))
    r:EnableMouse(true)
    r:RegisterForDrag("LeftButton")

    -- Drag support on rows so user can move the HUD by clicking and dragging anywhere
    r:SetScript("OnDragStart", function()
        local s = GetSettings()
        if s.todoHudLocked == true then return end
        todoHud.isDragging = true
        todoHud:StartMoving()
    end)
    r:SetScript("OnDragStop", function()
        todoHud.isDragging = false
        todoHud:StopMovingOrSizing()
        SaveHudPosition()
    end)

    -- Bullet as a solid colored 4x4 square dot
    local bullet = r:CreateTexture(nil, "ARTWORK")
    bullet:SetSize(4, 4)
    bullet:SetPoint("LEFT", 3, 0)
    bullet:SetColorTexture(ACCENT.r, ACCENT.g, ACCENT.b, 0.95)
    r.bullet = bullet

    local txt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", bullet, "RIGHT", 6, 0)
    txt:SetPoint("RIGHT", r, "RIGHT", -2, 0)
    txt:SetJustifyH("LEFT")
    txt:SetWordWrap(false)
    r.txt = txt

    r:SetScript("OnClick", function(self)
        if self.task then
            FP:ToggleTodoTaskDone(self.task.id, self.task.scope or "char")
        end
    end)
    r:SetScript("OnEnter", function(self)
        if self.task then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.task.text or "Promemoria", 1, 1, 1, 1, true)
            GameTooltip:AddLine("Clicca per contrassegnare come completato (spostato in archivio).", 0, 1, 0.59)
            GameTooltip:AddLine("Trascina per spostare la finestra.", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end)
    r:SetScript("OnLeave", function(self)
        if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)

    hudRows[idx] = r
    return r
end

function FP:RefreshTodoHUD()
    UpdateHudLockVisual()
    if not todoHud.isDragging then
        local pos = GetSettings().todoHudPos
        if type(pos) == "table" and pos.x and pos.y then
            todoHud:ClearAllPoints()
            todoHud:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
        end
    end

    local show = GetSettings().showTodoHud == true
    if not show then
        todoHud:Hide()
        return
    end

    EnsureTodoTables()
    local activeTasks = {}
    for _, t in ipairs(NexusKitCharDB.todoList or {}) do
        if not t.done then
            activeTasks[#activeTasks + 1] = { id = t.id, text = t.text, scope = "char" }
        end
    end
    for _, t in ipairs(NexusKitDB.todoListGlobal or {}) do
        if not t.done then
            activeTasks[#activeTasks + 1] = { id = t.id, text = "[Acc] " .. t.text, scope = "global" }
        end
    end

    if #activeTasks == 0 then
        todoHud:Hide()
        return
    end

    local maxRows = math.min(#activeTasks, 6)
    for i = 1, maxRows do
        local r = GetOrCreateHudRow(i)
        r.task = activeTasks[i]
        r.txt:SetText(activeTasks[i].text or "")
        r:Show()
    end
    for i = maxRows + 1, #hudRows do
        hudRows[i].task = nil
        hudRows[i]:Hide()
    end

    todoHud:SetHeight(28 + (maxRows * 19))
    todoHud:Show()
end

-------------------------------------------------------------------------------
-- Refresh UI Function
-------------------------------------------------------------------------------
function FP:RefreshTodoListUI()
    EnsureTodoTables()
    StyleScopeTab(tabChar, (self.L and self.L["TODO_TAB_CHAR"]) or "Character", currentScope == "char")
    StyleScopeTab(tabGlobal, (self.L and self.L["TODO_TAB_GLOBAL"]) or "Account", currentScope == "global")
    UpdateFilterButtonsVisual()

    local s = GetSettings()
    hudCheckBtn:SetChecked(s.showTodoHud == true)

    local list = GetTodoList(currentScope)
    local filtered = {}
    local activeCount = 0
    local doneCount = 0

    for _, t in ipairs(list) do
        if t.done then
            doneCount = doneCount + 1
        else
            activeCount = activeCount + 1
        end

        local match = false
        if currentFilter == "all" then
            match = true
        elseif currentFilter == "active" and not t.done then
            match = true
        elseif currentFilter == "done" and t.done then
            match = true
        end

        if match then
            filtered[#filtered + 1] = t
        end
    end

    statusFs:SetText(string.format("%d attive, %d completate", activeCount, doneCount))

    if #filtered == 0 then
        emptyFs:Show()
    else
        emptyFs:Hide()
    end

    for i, t in ipairs(filtered) do
        local row = GetOrCreateTaskRow(i)
        row.task = t
        if row.isEditing then
            row.isEditing = false
            if row.inlineEditBox then row.inlineEditBox:Hide() end
            row.textFs:Show()
        end
        row.textFs:SetText(t.text or "?")

        if t.done then
            row.checkMark:Show()
            row.checkBtn:SetBackdropBorderColor(0, 1, 0.59, 1)
            row.checkBtn:SetBackdropColor(0, 0.35, 0.18, 0.9)
            row.textFs:SetTextColor(0.55, 0.58, 0.62, 0.85)
            row:SetBackdropColor(0.06, 0.08, 0.07, 0.75)

            -- Strikethrough horizontal line across completed task
            row.strikeLine:ClearAllPoints()
            row.strikeLine:SetPoint("LEFT", row.textFs, "LEFT", 0, 0)
            local strWidth = row.textFs:GetStringWidth() or 0
            local maxW = (row.textFs:GetWidth() or 200)
            local w = math.min(strWidth, maxW)
            if w > 0 then
                row.strikeLine:SetWidth(w)
                row.strikeLine:Show()
            else
                row.strikeLine:Hide()
            end
        else
            row.checkMark:Hide()
            row.checkBtn:SetBackdropBorderColor(0.35, 0.40, 0.50, 0.85)
            row.checkBtn:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
            row.textFs:SetTextColor(0.95, 0.96, 0.98, 1)
            row:SetBackdropColor(0.09, 0.11, 0.15, 0.85)
            row.strikeLine:Hide()
        end
        row:Show()
    end

    for i = #filtered + 1, #taskRows do
        taskRows[i].task = nil
        taskRows[i]:Hide()
    end

    local totalHeight = math.max(1, #filtered * 28)
    scrollChild:SetHeight(totalHeight)

    self:RefreshTodoHUD()
end

-------------------------------------------------------------------------------
-- Controller Actions
-------------------------------------------------------------------------------
function FP:ToggleTodoList(show)
    if show == nil then
        if todoFrame:IsShown() then
            todoFrame:Hide()
        else
            todoFrame:Show()
            self:RefreshTodoListUI()
        end
    elseif show then
        todoFrame:Show()
        self:RefreshTodoListUI()
    else
        todoFrame:Hide()
    end
end

function FP:AddTodoTask(text, scope)
    if not text or text == "" then return end
    EnsureTodoTables()
    local list = GetTodoList(scope or currentScope)
    local newId = (GetTime and math.floor(GetTime() * 1000)) or (#list + 1)
    local curTime = (date and date("%d/%m %H:%M")) or "Oggi"

    local task = {
        id      = newId,
        text    = text,
        done    = false,
        created = curTime,
    }
    table.insert(list, 1, task)

    pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856, "Master")
    self:RefreshTodoListUI()
end

function FP:EditTodoTask(id, scope, newText)
    EnsureTodoTables()
    if not id or not newText then return end
    newText = newText:match("^%s*(.-)%s*$") or ""
    if newText == "" then return end

    local list = GetTodoList(scope or currentScope)
    for _, t in ipairs(list) do
        if t.id == id then
            t.text = newText
            t.edited = (date and date("%d/%m %H:%M")) or "Adesso"
            pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856, "Master")
            break
        end
    end
    self:RefreshTodoListUI()
    self:RefreshTodoHUD()
end

function FP:ToggleTodoTaskDone(id, scope)
    EnsureTodoTables()
    local list = GetTodoList(scope or currentScope)
    for _, t in ipairs(list) do
        if t.id == id then
            t.done = not t.done
            if t.done then
                pcall(PlaySound, SOUNDKIT.UI_QUEST_COMPLETE or 878, "Master")
            else
                pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857, "Master")
            end
            break
        end
    end
    self:RefreshTodoListUI()
end

function FP:DeleteTodoTask(id, scope)
    EnsureTodoTables()
    local list = GetTodoList(scope or currentScope)
    for i, t in ipairs(list) do
        if t.id == id then
            table.remove(list, i)
            pcall(PlaySound, 856, "Master")
            break
        end
    end
    self:RefreshTodoListUI()
end

function FP:MoveTodoTask(id, scope, direction)
    EnsureTodoTables()
    local list = GetTodoList(scope or currentScope)
    local idx = nil
    for i, t in ipairs(list) do
        if t.id == id then idx = i break end
    end
    if not idx then return end

    local targetIdx = idx + direction
    if targetIdx >= 1 and targetIdx <= #list then
        local item = table.remove(list, idx)
        table.insert(list, targetIdx, item)
        self:RefreshTodoListUI()
    end
end

function FP:ClearDoneTodoTasks(scope)
    EnsureTodoTables()
    local list = GetTodoList(scope or currentScope)
    for i = #list, 1, -1 do
        if list[i].done then
            table.remove(list, i)
        end
    end
    pcall(PlaySound, 856, "Master")
    self:RefreshTodoListUI()
end

-------------------------------------------------------------------------------
-- Event Registration & Auto-Login Initialization
-------------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evFrame:SetScript("OnEvent", function(self, event)
    EnsureTodoTables()
    if FP.RefreshTodoHUD then
        FP:RefreshTodoHUD()
    end
end)
