-------------------------------------------------------------------------------
-- NexKit - UI/QuestHelper.lua
-- Quest Helper for Hidden / Riddle Quests and Dungeon Quest Tactic Shortcuts.
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function GetAccentColor()
    if FP.GetAccentColor then
        return FP:GetAccentColor()
    end
    return 0, 1, 0.59, "00ff96"
end

-------------------------------------------------------------------------------
-- Helper: Detect Currently Displayed Quest (ID, Title, Text)
-------------------------------------------------------------------------------
local function GetCurrentDisplayedQuest()
    local qid = nil
    local title = nil
    local text = nil

    -- 1. Try QuestMapFrame (WorldMapFrame side panel - modern Classic / WoW Forever)
    if QuestMapFrame_GetDetailQuestID then
        local ok, q = pcall(QuestMapFrame_GetDetailQuestID)
        if ok and IsSafeNum(q) and q > 0 then
            qid = q
        end
    end
    if (not qid or qid <= 0) and QuestMapFrame and QuestMapFrame.DetailsFrame then
        local q = QuestMapFrame.DetailsFrame.questID
        if IsSafeNum(q) and q > 0 then
            qid = q
        end
    end

    -- 2. Try C_QuestLog.GetSelectedQuest
    if (not qid or qid <= 0) and C_QuestLog and C_QuestLog.GetSelectedQuest then
        local ok, q = pcall(C_QuestLog.GetSelectedQuest)
        if ok and IsSafeNum(q) and q > 0 then
            qid = q
        end
    end

    -- 3. Try QuestLogPopupDetailFrame
    if (not qid or qid <= 0) and QuestLogPopupDetailFrame then
        local q = QuestLogPopupDetailFrame.questID
        if IsSafeNum(q) and q > 0 then
            qid = q
        end
    end

    -- 4. Try classic GetQuestLogSelection
    if (not qid or qid <= 0) and GetQuestLogSelection and GetQuestLogTitle then
        local ok, sel = pcall(GetQuestLogSelection)
        if ok and sel and sel > 0 then
            local ok2, qTitle, _, _, isHdr, _, _, _, id = pcall(GetQuestLogTitle, sel)
            if ok2 and not isHdr and id and id > 0 then
                qid = id
                title = qTitle
            end
        end
    end

    -- 5. Try GetQuestID (NPC dialog / QuestFrame)
    if (not qid or qid <= 0) and GetQuestID then
        local ok, id = pcall(GetQuestID)
        if ok and IsSafeNum(id) and id > 0 then
            qid = id
        end
    end

    -- 6. Retrieve Title from visible elements if not already known
    if not IsSafeStr(title) then
        if QuestLogQuestTitle and QuestLogQuestTitle.GetText then
            local t = QuestLogQuestTitle:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and QuestLogDetailTitleText and QuestLogDetailTitleText.GetText then
            local t = QuestLogDetailTitleText:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and QuestMapDetailsScrollFrame and QuestMapDetailsScrollFrame.Contents and QuestMapDetailsScrollFrame.Contents.Title and QuestMapDetailsScrollFrame.Contents.Title.GetText then
            local t = QuestMapDetailsScrollFrame.Contents.Title:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and QuestInfoTitleHeader and QuestInfoTitleHeader.GetText then
            local t = QuestInfoTitleHeader:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and QuestTitleText and QuestTitleText.GetText then
            local t = QuestTitleText:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and QuestLogPopupDetailFrame and QuestLogPopupDetailFrame.ScrollFrame and QuestLogPopupDetailFrame.ScrollFrame.Contents and QuestLogPopupDetailFrame.ScrollFrame.Contents.Title and QuestLogPopupDetailFrame.ScrollFrame.Contents.Title.GetText then
            local t = QuestLogPopupDetailFrame.ScrollFrame.Contents.Title:GetText()
            if IsSafeStr(t) then title = t end
        end
        if not IsSafeStr(title) and IsSafeNum(qid) and C_QuestLog and C_QuestLog.GetTitleForQuestID then
            local ok, t = pcall(C_QuestLog.GetTitleForQuestID, qid)
            if ok and IsSafeStr(t) then title = t end
        end
    end

    -- 7. Retrieve Objective / Description text snippet
    if QuestLogObjectivesText and QuestLogObjectivesText.GetText then
        local ot = QuestLogObjectivesText:GetText()
        if IsSafeStr(ot) then text = (text and (text .. " ") or "") .. ot end
    end
    if QuestLogQuestDescription and QuestLogQuestDescription.GetText then
        local dt = QuestLogQuestDescription:GetText()
        if IsSafeStr(dt) then text = (text and (text .. " ") or "") .. dt end
    end
    if QuestInfoObjectivesText and QuestInfoObjectivesText.GetText then
        local ot = QuestInfoObjectivesText:GetText()
        if IsSafeStr(ot) then text = (text and (text .. " ") or "") .. ot end
    end
    if QuestObjectivesText and QuestObjectivesText.GetText then
        local ot = QuestObjectivesText:GetText()
        if IsSafeStr(ot) then text = (text and (text .. " ") or "") .. ot end
    end
    if QuestInfoDescriptionText and QuestInfoDescriptionText.GetText then
        local dt = QuestInfoDescriptionText:GetText()
        if IsSafeStr(dt) then text = (text and (text .. " ") or "") .. dt end
    end
    if QuestDescriptionText and QuestDescriptionText.GetText then
        local dt = QuestDescriptionText:GetText()
        if IsSafeStr(dt) then text = (text and (text .. " ") or "") .. dt end
    end
    if QuestMapDetailsScrollFrame and QuestMapDetailsScrollFrame.Contents and QuestMapDetailsScrollFrame.Contents.DescriptionText and QuestMapDetailsScrollFrame.Contents.DescriptionText.GetText then
        local dt = QuestMapDetailsScrollFrame.Contents.DescriptionText:GetText()
        if IsSafeStr(dt) then text = (text and (text .. " ") or "") .. dt end
    end
    if QuestLogPopupDetailFrame and QuestLogPopupDetailFrame.ScrollFrame and QuestLogPopupDetailFrame.ScrollFrame.Contents and QuestLogPopupDetailFrame.ScrollFrame.Contents.DescriptionText and QuestLogPopupDetailFrame.ScrollFrame.Contents.DescriptionText.GetText then
        local dt = QuestLogPopupDetailFrame.ScrollFrame.Contents.DescriptionText:GetText()
        if IsSafeStr(dt) then text = (text and (text .. " ") or "") .. dt end
    end

    return qid, title, text
end

-------------------------------------------------------------------------------
-- Helper: Detect Active Quest Details View Container
-------------------------------------------------------------------------------
local function FindActiveQuestDetailContainer()
    -- 1. QuestMapFrame DetailsFrame (WorldMapFrame side panel)
    if QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame:IsShown() then
        local backBtn = QuestMapFrame.DetailsFrame.BackButton
        return QuestMapFrame.DetailsFrame, backBtn, "QUEST_MAP"
    end

    -- 2. QuestLogPopupDetailFrame (Standalone quest log detail popup)
    if QuestLogPopupDetailFrame and QuestLogPopupDetailFrame:IsShown() then
        return QuestLogPopupDetailFrame, nil, "POPUP"
    end

    -- 3. Classic QuestLogFrame (Default 'L' Quest Log)
    if QuestLogFrame and QuestLogFrame:IsShown() then
        return QuestLogFrame, QuestLogDetailScrollFrame or QuestLogFrame, "CLASSIC_LOG"
    end

    -- 4. Classic QuestLogDetailFrame
    if QuestLogDetailFrame and QuestLogDetailFrame:IsShown() then
        return QuestLogDetailFrame, nil, "CLASSIC_LOG"
    end

    -- 5. QuestFrame (NPC / World Object interaction dialog)
    if QuestFrame and QuestFrame:IsShown() then
        return QuestFrame, nil, "NPC_FRAME"
    end

    -- 6. QuestInfoFrame fallback
    if QuestInfoFrame and QuestInfoFrame:IsShown() then
        local p = QuestInfoFrame:GetParent() or QuestInfoFrame
        return p, nil, "INFO_FRAME"
    end

    return nil, nil, nil
end

-------------------------------------------------------------------------------
-- Create Floating Quest Helper Buttons Bar
-------------------------------------------------------------------------------
local helperBar = CreateFrame("Frame", "NexKitQuestHelperBar", UIParent)
helperBar:SetSize(340, 26)
helperBar:SetFrameStrata("DIALOG")
helperBar:SetFrameLevel(200)
helperBar:EnableMouse(false)
helperBar:Hide()

-- 1. Hidden / Riddle Quest Button (Compass Icon)
local riddleBtn = CreateFrame("Button", "NexKitRiddleQuestBtn", helperBar, "BackdropTemplate")
riddleBtn:SetSize(185, 24)
riddleBtn:SetPoint("LEFT", helperBar, "LEFT", 0, 0)
riddleBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
riddleBtn:SetBackdropColor(0.10, 0.14, 0.22, 0.96)
riddleBtn:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.95)

local rIcon = riddleBtn:CreateTexture(nil, "ARTWORK")
rIcon:SetSize(16, 16)
rIcon:SetPoint("LEFT", 5, 0)
rIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")

local rTxt = riddleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rTxt:SetPoint("LEFT", rIcon, "RIGHT", 5, 0)
rTxt:SetPoint("RIGHT", -4, 0)
rTxt:SetJustifyH("LEFT")
rTxt:SetText("🧭 Aiuto Quest: Freccia 3D")
rTxt:SetTextColor(1, 0.92, 0.45, 1)

-- 2. Dungeon Tactics Button (Portal / Castle Icon)
local dungeonBtn = CreateFrame("Button", "NexKitDungeonQuestBtn", helperBar, "BackdropTemplate")
dungeonBtn:SetSize(150, 24)
dungeonBtn:SetPoint("LEFT", riddleBtn, "RIGHT", 6, 0)
dungeonBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
dungeonBtn:SetBackdropColor(0.12, 0.10, 0.22, 0.96)
dungeonBtn:SetBackdropBorderColor(0.78, 0.52, 1.00, 0.95)

local dIcon = dungeonBtn:CreateTexture(nil, "ARTWORK")
dIcon:SetSize(16, 16)
dIcon:SetPoint("LEFT", 5, 0)
dIcon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalIronForge")

local dTxt = dungeonBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dTxt:SetPoint("LEFT", dIcon, "RIGHT", 5, 0)
dTxt:SetPoint("RIGHT", -4, 0)
dTxt:SetJustifyH("LEFT")
dTxt:SetText("🏰 Tattiche Boss")
dTxt:SetTextColor(0.85, 0.65, 1.00, 1)

-------------------------------------------------------------------------------
-- Tooltips & Clicks for Buttons
-------------------------------------------------------------------------------
riddleBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.18, 0.24, 0.38, 1)
    self:SetBackdropBorderColor(1, 1, 1, 1)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("NexKit - Aiuto Missione Nascosta", 1, 0.82, 0)
        local data = self.hData
        if data then
            GameTooltip:AddLine("Obiettivo: |cffffffff" .. (data.title or "Nascosto") .. "|r", 0.9, 0.9, 0.9)
            if data.desc then
                GameTooltip:AddLine("Indizio: |cffffd100" .. data.desc .. "|r", 1, 1, 1, true)
            end
            if data.hint then
                GameTooltip:AddLine("Posizione: |cff00ff96" .. data.hint .. "|r", 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff96Clicca per attivare la freccia 3D e centrare la mappa!|r", 0.2, 1, 0.2)
        end
        GameTooltip:Show()
    end
end)
riddleBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.10, 0.14, 0.22, 0.96)
    self:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.95)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
end)
riddleBtn:SetScript("OnClick", function(self)
    local data = self.hData
    if data and data.x and data.y and FP.SetCustomWaypoint then
        local label = data.title or "Obiettivo Missione"
        FP:SetCustomWaypoint(data.x, data.y, label, data.mapID)
        local loc = data.hint or string.format("%.1f, %.1f", data.x, data.y)
        FP:Print("Freccia 3D attivata verso [" .. label .. "] a " .. loc .. "!")
    end
end)

dungeonBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.20, 0.16, 0.36, 1)
    self:SetBackdropBorderColor(1, 1, 1, 1)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("NexKit - Tattiche Dungeon", 0.78, 0.52, 1.00)
        local g = self.dGuide
        if g then
            local lvl = (g.minLvl == g.maxLvl) and tostring(g.minLvl) or (tostring(g.minLvl) .. "-" .. tostring(g.maxLvl))
            GameTooltip:AddLine("Dungeon: |cffffffff" .. (g.name or "Dungeon") .. " (Liv. " .. lvl .. ")|r", 0.9, 0.9, 0.9)
            local numBosses = type(g.bosses) == "table" and #g.bosses or 0
            GameTooltip:AddLine("Boss con tattiche: |cff00ff96" .. numBosses .. "|r", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff96Clicca per aprire la Guida con tattiche e strategie dei boss!|r", 0.2, 1, 0.2)
        end
        GameTooltip:Show()
    end
end)
dungeonBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.10, 0.22, 0.96)
    self:SetBackdropBorderColor(0.78, 0.52, 1.00, 0.95)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
end)
dungeonBtn:SetScript("OnClick", function(self)
    local g = self.dGuide
    if g and FP.ToggleDungeonGuide then
        FP:ToggleDungeonGuide(g.id)
    end
end)

-------------------------------------------------------------------------------
-- Refresh / Anchor Helper Buttons
-------------------------------------------------------------------------------
local function RefreshQuestHelperButtons()
    if InCombatLockdown and InCombatLockdown() then
        helperBar:Hide()
        return
    end

    local container, anchorBtn, cType = FindActiveQuestDetailContainer()
    if not container or not container:IsShown() then
        helperBar:Hide()
        return
    end

    local qid, title, text = GetCurrentDisplayedQuest()
    local hData = FP.GetHiddenQuestData and FP:GetHiddenQuestData(qid, title, text)
    local dGuide = FP.GetDungeonForQuest and FP:GetDungeonForQuest(qid, title)

    if not hData and not dGuide then
        helperBar:Hide()
        return
    end

    -- Ensure helperBar stays permanently on UIParent to prevent Blizzard UI taint
    local cLeft = container.GetLeft and container:GetLeft()
    local cRight = container.GetRight and container:GetRight()
    local cTop = container.GetTop and container:GetTop()
    if not cLeft or not cRight or not cTop then
        helperBar:Hide()
        return
    end

    local uScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local cScale = (container.GetEffectiveScale and container:GetEffectiveScale()) or uScale

    local strata = (container.GetFrameStrata and container:GetFrameStrata()) or "DIALOG"
    local level = (container.GetFrameLevel and container:GetFrameLevel()) or 100
    helperBar:SetFrameStrata(strata)
    helperBar:SetFrameLevel(math.max(100, level + 15))

    -- Anchor strictly to UIParent with absolute screen coordinates so Blizzard frames are NEVER tainted
    helperBar:ClearAllPoints()
    if cType == "QUEST_MAP" then
        local x = ((cLeft * cScale) / uScale) + 88
        local y = ((cTop * cScale) / uScale) - 5
        helperBar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    elseif cType == "POPUP" or cType == "CLASSIC_LOG" then
        local x = ((cRight * cScale) / uScale) - 36
        local y = ((cTop * cScale) / uScale) - 34
        helperBar:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y)
    elseif cType == "NPC_FRAME" then
        local x = ((cRight * cScale) / uScale) - 36
        local y = ((cTop * cScale) / uScale) - 38
        helperBar:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y)
    else
        local x = ((cRight * cScale) / uScale) - 15
        local y = ((cTop * cScale) / uScale) - 10
        helperBar:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y)
    end

    local curX = 0
    if hData then
        riddleBtn.hData = hData
        riddleBtn:ClearAllPoints()
        riddleBtn:SetPoint("LEFT", helperBar, "LEFT", curX, 0)
        riddleBtn:Show()
        curX = curX + 190
    else
        riddleBtn:Hide()
    end

    if dGuide then
        dungeonBtn.dGuide = dGuide
        dungeonBtn:ClearAllPoints()
        dungeonBtn:SetPoint("LEFT", helperBar, "LEFT", curX, 0)
        dungeonBtn:Show()
        curX = curX + 155
    else
        dungeonBtn:Hide()
    end

    helperBar:SetWidth(math.max(10, curX))
    helperBar:Show()
end

-------------------------------------------------------------------------------
-- Hooks: Auto-refresh when viewing quests
-------------------------------------------------------------------------------
local timerPending = false
local function ScheduleHelperRefresh()
    if InCombatLockdown and InCombatLockdown() then return end
    if timerPending then return end
    timerPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.04, function()
            timerPending = false
            RefreshQuestHelperButtons()
        end)
    else
        timerPending = false
        RefreshQuestHelperButtons()
    end
end

-- Periodic state poll and Blizzard quest events refresh the helper bar safely without hooks



-- Event Watcher & Periodic State Poll
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("QUEST_LOG_UPDATE")
watcher:RegisterEvent("QUEST_DETAIL")
watcher:RegisterEvent("QUEST_COMPLETE")
watcher:RegisterEvent("QUEST_FINISHED")
watcher:RegisterEvent("QUEST_PROGRESS")
watcher:SetScript("OnEvent", function()
    ScheduleHelperRefresh()
end)

local lastCheckedQID, lastCheckedTitle, lastCheckedContainer = nil, nil, nil
local pollElapsed = 0
watcher:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown and InCombatLockdown() then
        if helperBar:IsShown() then helperBar:Hide() end
        return
    end

    pollElapsed = pollElapsed + elapsed
    if pollElapsed < 0.20 then return end
    pollElapsed = 0

    local container = FindActiveQuestDetailContainer()
    if container and container:IsShown() then
        local qid, title = GetCurrentDisplayedQuest()
        if qid ~= lastCheckedQID or title ~= lastCheckedTitle or container ~= lastCheckedContainer then
            lastCheckedQID = qid
            lastCheckedTitle = title
            lastCheckedContainer = container
            ScheduleHelperRefresh()
        end
    elseif helperBar:IsShown() or lastCheckedContainer ~= nil then
        helperBar:Hide()
        lastCheckedQID, lastCheckedTitle, lastCheckedContainer = nil, nil, nil
    end
end)
