-- NexusKit  –  Core/AutoSync.lua
-- Automatic step-completion engine.  Monitors game events and advances
-- the active route to the first incomplete, filter-passing step.
local _, FP = ...

FP.OnStepChangedCallbacks = FP.OnStepChangedCallbacks or {}

------------------------------------------------------------------------
-- Quest-state wrappers (with fallback for older/custom APIs)
------------------------------------------------------------------------

--- Is the quest flagged completed (i.e. turned in)?
function FP:IsQuestDone(questId)
    if not questId then return false end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questId) == true
    end
    if IsQuestFlaggedCompleted then
        return IsQuestFlaggedCompleted(questId) == true
    end
    return false
end

--- Is the quest currently in the player's quest log?
function FP:IsQuestInLog(questId)
    if not questId then return false end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local idx = C_QuestLog.GetLogIndexForQuestID(questId)
        return idx ~= nil and idx > 0
    end
    if GetQuestLogIndexByID then
        local idx = GetQuestLogIndexByID(questId)
        return idx ~= nil and idx > 0
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() do
            local _, _, _, _, _, _, _, id = GetQuestLogTitle(i)
            if id == questId then return true end
        end
    end
    return false
end

--- Safe check for a single objective table/struct
local function IsSingleObjectiveFinished(obj)
    if type(obj) ~= "table" then return false end
    if type(obj.numRequired) == "number" and obj.numRequired > 0
        and type(obj.numFulfilled) == "number"
        and obj.numFulfilled < obj.numRequired then
        return false
    end
    return obj.finished == true
end

--- Summarize all objectives for a quest (returns total, finished, firstPending, lines, reqTotal, reqDone)
function FP:GetQuestObjectivesSummary(questId)
    local total, finished = 0, 0
    local reqTotal, reqDone = 0, 0
    local firstPending = nil
    local lines = {}

    if not questId then
        return total, finished, firstPending, lines, reqTotal, reqDone
    end

    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objs = pcall(C_QuestLog.GetQuestObjectives, questId)
        if ok and type(objs) == "table" then
            for _, obj in ipairs(objs) do
                total = total + 1
                local isOptional = (type(obj) == "table" and obj.optional == true)
                if not isOptional then
                    reqTotal = reqTotal + 1
                end
                local done = IsSingleObjectiveFinished(obj)
                local txt = (type(obj) == "table" and type(obj.text) == "string"
                    and (not issecretvalue or not issecretvalue(obj.text))) and obj.text or nil
                if done then
                    finished = finished + 1
                    if not isOptional then
                        reqDone = reqDone + 1
                    end
                elseif not firstPending and txt then
                    firstPending = txt
                end
                if txt then
                    lines[#lines + 1] = txt
                end
            end
            return total, finished, firstPending, lines, reqTotal, reqDone
        end
    end

    if GetQuestLogIndexByID and GetQuestLogLeaderBoard then
        local logIdx = GetQuestLogIndexByID(questId)
        if logIdx and logIdx > 0 then
            local num = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(logIdx)) or 0
            for i = 1, num do
                local desc, _, done = GetQuestLogLeaderBoard(i, logIdx)
                total = total + 1
                reqTotal = reqTotal + 1
                if done == true or done == 1 then
                    finished = finished + 1
                    reqDone = reqDone + 1
                elseif not firstPending and type(desc) == "string" then
                    firstPending = desc
                end
                if type(desc) == "string" then
                    lines[#lines + 1] = desc
                end
            end
        end
    end

    return total, finished, firstPending, lines, reqTotal, reqDone
end

--- Unified ready-for-turn-in check that avoids false positives on active quests with unfinished objectives
function FP:IsQuestReadyForTurnIn(questId, infoReady)
    if not questId then return false end

    local total, finished, _, _, reqTotal, reqDone = self:GetQuestObjectivesSummary(questId)
    local hasUnfinishedRequired = (reqTotal > 0 and reqDone < reqTotal)

    if infoReady == true and not hasUnfinishedRequired then
        return true
    end

    if C_QuestLog and C_QuestLog.ReadyForTurnIn then
        local ok, r = pcall(C_QuestLog.ReadyForTurnIn, questId)
        if ok and r == true and not hasUnfinishedRequired then
            return true
        end
    elseif not hasUnfinishedRequired and C_QuestLog and C_QuestLog.IsComplete then
        local ok, c = pcall(C_QuestLog.IsComplete, questId)
        if ok and c == true then
            return true
        end
    end

    if reqTotal > 0 and reqDone == reqTotal then
        return true
    elseif reqTotal == 0 and total > 0 and finished == total then
        return true
    end

    return false
end

--- Is a specific objective (or all objectives when objIndex is nil) complete?
function FP:IsObjectiveComplete(questId, objIndex)
    if not questId then return false end
    if not objIndex then
        local total, finished, _, _, reqTotal, reqDone = self:GetQuestObjectivesSummary(questId)
        if reqTotal > 0 then
            return reqDone == reqTotal
        end
        return total > 0 and finished == total
    end
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questId)
        if ok and type(objectives) == "table" then
            return IsSingleObjectiveFinished(objectives[objIndex])
        end
    end
    if GetQuestLogIndexByID and GetQuestLogLeaderBoard then
        local logIdx = GetQuestLogIndexByID(questId)
        if logIdx and logIdx > 0 then
            local _, _, finished = GetQuestLogLeaderBoard(objIndex, logIdx)
            return finished == true or finished == 1
        end
    end
    return false
end

------------------------------------------------------------------------
-- Race / Class normalization & filter check
------------------------------------------------------------------------
local function NormalizeRaceToken(r)
    if not r then return "" end
    local up = tostring(r):upper():gsub("%s+", "")
    if up == "SCOURGE" then
        return "UNDEAD"
    end
    return up
end

local function NormalizeClassToken(c)
    if not c then return "" end
    return tostring(c):upper():gsub("%s+", "")
end

function FP:PassesFilter(step)
    if not step then return false end

    -- Class filter
    if step.classes then
        local pc = NormalizeClassToken(self:GetPlayerClass())
        local match = false
        for _, c in ipairs(step.classes) do
            if NormalizeClassToken(c) == pc then
                match = true
                break
            end
        end
        if not match then return false end
    end

    -- Race filter (supports both "SCOURGE" and "UNDEAD", case-insensitive)
    if step.races then
        local pr = NormalizeRaceToken(self:GetPlayerRace())
        local match = false
        for _, r in ipairs(step.races) do
            if NormalizeRaceToken(r) == pr then
                match = true
                break
            end
        end
        if not match then return false end
    end

    -- Level filter (skip steps whose min level is above player's current level)
    if step.minLevel and self:GetPlayerLevel() < step.minLevel then
        return false
    end

    return true
end

------------------------------------------------------------------------
-- Euclidean distance helper (map-normalised coords: 0-100 range)
------------------------------------------------------------------------
local function PlayerMapDistance(mapID, sx, sy)
    if not mapID or not sx or not sy then return math.huge end
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then
        return math.huge
    end
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if playerMapID ~= mapID then
        return math.huge
    end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return math.huge end
    local px, py = pos:GetXY()
    if not px or (px == 0 and py == 0) then return math.huge end
    -- WoW map position is [0,1]; step coords are [0,100]
    local dx = (px * 100) - sx
    local dy = (py * 100) - sy
    return math.sqrt(dx * dx + dy * dy)
end

------------------------------------------------------------------------
-- Step-complete predicates – P(s_i)
------------------------------------------------------------------------
local NAV_OR_HEURISTIC_ACTIONS = {
    GOTO       = true,
    FLY        = true,
    TRAIN      = true,
    SET_HEARTH = true,
    USE_HEARTH = true,
}

function FP:IsStepComplete(step)
    if not step then return false end

    -- Manual or latched completion stored in CharDB
    if NexusKitCharDB and NexusKitCharDB.completedSteps and NexusKitCharDB.completedSteps[step.id] then
        return true
    end

    -- Optional step skipped if player exceeds maxSkipLevel
    local autoSkipByLevel = not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.autoSkipByLevel == false)
    if autoSkipByLevel and step.isOptional and step.maxSkipLevel and self:GetPlayerLevel() > step.maxSkipLevel then
        return true
    end

    local action = step.action

    if action == "ACCEPT" then
        return self:IsQuestDone(step.questId) or self:IsQuestInLog(step.questId)

    elseif action == "COMPLETE" then
        if self:IsQuestDone(step.questId) then return true end
        return self:IsObjectiveComplete(step.questId, step.objectiveIndex)

    elseif action == "TURNIN" then
        return self:IsQuestDone(step.questId)

    elseif action == "GRIND" then
        if not step.targetLevel then return false end
        local lvl = self:GetPlayerLevel() + self:GetPlayerXPPercent()
        return lvl >= step.targetLevel

    elseif action == "GOTO" then
        if PlayerMapDistance(step.mapID, step.x, step.y) <= 1.5 then
            if NexusKitCharDB and NexusKitCharDB.completedSteps then
                NexusKitCharDB.completedSteps[step.id] = true
            end
            return true
        end
        return false

    elseif action == "FLY" then
        if PlayerMapDistance(step.mapID, step.x, step.y) <= 2.0 then
            if NexusKitCharDB and NexusKitCharDB.completedSteps then
                NexusKitCharDB.completedSteps[step.id] = true
            end
            return true
        end
        return false

    elseif action == "TRAIN" then
        if step.isDynamicTrain then
            if FP.GetClassTrainerNeed then
                return FP:GetClassTrainerNeed(false) == nil
            end
            return true
        end
        local refLevel = step.minLevel or step.targetLevel
        local playerLevel = self:GetPlayerLevel()
        if refLevel and playerLevel >= (refLevel + 3) then
            return true
        end
        local scan = NexusKitCharDB and NexusKitCharDB.trainerScan
        if refLevel and playerLevel >= refLevel and scan and scan.level and scan.level >= refLevel and (scan.totalAvail or 0) == 0 then
            return true
        end
        return false
    elseif action == "SET_HEARTH" then
        if step.mapID and step.x and step.y and PlayerMapDistance(step.mapID, step.x, step.y) <= 2.5 then
            if NexusKitCharDB and NexusKitCharDB.completedSteps then
                NexusKitCharDB.completedSteps[step.id] = true
            end
            return true
        end
        local refLevel = step.minLevel or step.targetLevel
        if refLevel and self:GetPlayerLevel() >= (refLevel + 3) then
            return true
        end
        return false

    elseif action == "USE_HEARTH" then
        if step.mapID and step.x and step.y and PlayerMapDistance(step.mapID, step.x, step.y) <= 20.0 then
            if NexusKitCharDB and NexusKitCharDB.completedSteps then
                NexusKitCharDB.completedSteps[step.id] = true
            end
            return true
        end
        local refLevel = step.minLevel or step.targetLevel
        if refLevel and self:GetPlayerLevel() >= (refLevel + 3) then
            return true
        end
        return false
    end

    return false
end

------------------------------------------------------------------------
-- Find active step:  i* = min{ i : filter passes AND not complete }
-- Includes catch-up guard so old GOTO/FLY/HEARTH/TRAIN steps behind an
-- already-completed or active quest do not stall mid-route catch-up.
------------------------------------------------------------------------
function FP:FindActiveStep()
    local route = self.activeRoute
    if not route or not route.steps then return nil, nil end

    -- Find highest step index that has verified quest/manual completion proof
    local lastConfirmedIdx = 0
    for j, s in ipairs(route.steps) do
        if self:PassesFilter(s) then
            local hasProof = false
            if NexusKitCharDB and NexusKitCharDB.completedSteps and NexusKitCharDB.completedSteps[s.id] then
                hasProof = true
            elseif s.questId and (self:IsQuestDone(s.questId) or self:IsQuestInLog(s.questId)) then
                hasProof = true
            end
            if hasProof then
                lastConfirmedIdx = j
            end
        end
    end

    for i, step in ipairs(route.steps) do
        if self:PassesFilter(step) then
            local behindProgress = (i < lastConfirmedIdx)
                and (NAV_OR_HEURISTIC_ACTIONS[step.action] or step.isOptional)
            if not behindProgress and not self:IsStepComplete(step) then
                return step, i
            end
        end
    end

    return nil, nil -- route is complete
end

------------------------------------------------------------------------
-- Step-changed callback dispatcher
------------------------------------------------------------------------
function FP:RegisterStepChangedCallback(fn)
    if type(fn) ~= "function" then return end
    for _, existing in ipairs(self.OnStepChangedCallbacks) do
        if existing == fn then return end
    end
    table.insert(self.OnStepChangedCallbacks, fn)
end

function FP:OnStepChanged(newStep, newIndex)
    for _, cb in ipairs(self.OnStepChangedCallbacks) do
        if type(cb) == "function" then
            cb(newStep, newIndex)
        end
    end
end

------------------------------------------------------------------------
-- Update engine with 0.2 s debounce
------------------------------------------------------------------------
local pendingUpdate = false
local wasRouteComplete = false

function FP:UpdateCurrentStep()
    if pendingUpdate then return end
    pendingUpdate = true

    FP:After(0.2, function()
        pendingUpdate = false

        if FP.activeRoute and FP.QUEST_SYNC_ROUTE_ID
            and FP.activeRoute.routeId == FP.QUEST_SYNC_ROUTE_ID
            and FP.RebuildQuestSyncRoute then
            local route = FP:RebuildQuestSyncRoute()
            FP.activeRoute = route
            local hasSteps = route and route.steps and #route.steps > 0
            FP.currentStepIndex = hasSteps and 1 or nil
            if NexusKitCharDB then
                NexusKitCharDB.currentStepIdx = FP.currentStepIndex or 1
            end
            local topStep = hasSteps and route.steps[1] or nil
            if topStep and topStep.questId and not (topStep.mapID and topStep.x and topStep.y)
                and not (InCombatLockdown and InCombatLockdown()) then
                if FP.SetSuperTrackedQuestSafe then
                    FP:SetSuperTrackedQuestSafe(topStep.questId)
                end
            end
            FP:OnStepChanged(topStep, FP.currentStepIndex)
            return
        end

        local step, idx = FP:FindActiveStep()
        local changed = (idx ~= FP.currentStepIndex)

        FP.currentStepIndex = idx
        if NexusKitCharDB then
            NexusKitCharDB.currentStepIdx = idx or 1
        end

        if changed or not step then
            FP:OnStepChanged(step, idx)
        end

        if not step and FP.activeRoute then
            if not wasRouteComplete then
                wasRouteComplete = true
                FP:Print(FP.L["ROUTE_COMPLETE"] or "Route complete!")

                local curId = FP.activeRoute.routeId
                local nextId = nil
                if curId == "ALLIANCE_1_20_OPTIMAL" then
                    nextId = "ALLIANCE_20_40_OPTIMAL"
                elseif curId == "ALLIANCE_20_40_OPTIMAL" then
                    nextId = "ALLIANCE_40_60_OPTIMAL"
                elseif curId == "HORDE_1_20_OPTIMAL" then
                    nextId = "HORDE_20_40_OPTIMAL"
                elseif curId == "HORDE_20_40_OPTIMAL" then
                    nextId = "HORDE_40_60_OPTIMAL"
                end

                if nextId and FP.routes and FP.routes[nextId] then
                    local nextTitle = FP.routes[nextId].title or nextId
                    local msg = string.format(FP.L["ROUTE_ADVANCING"] or "Advancing to next route: %s", nextTitle)
                    FP:Print(msg)
                    FP:SetActiveRoute(nextId)
                end
            end
        else
            wasRouteComplete = false
        end
    end)
end

------------------------------------------------------------------------
-- Manual skip / mark complete
------------------------------------------------------------------------
function FP:MarkStepComplete(stepId)
    if not stepId then return end
    if self.activeRoute and self.QUEST_SYNC_ROUTE_ID
        and self.activeRoute.routeId == self.QUEST_SYNC_ROUTE_ID then
        for _, s in ipairs(self.activeRoute.steps or {}) do
            if s.id == stepId then
                if s.isDynamicTrain and NexusKitCharDB then
                    NexusKitCharDB.skippedTrainKey = s.trainKey
                elseif s.questId and self.skippedSyncQuests then
                    self.skippedSyncQuests[s.questId] = true
                end
                break
            end
        end
        self:UpdateCurrentStep()
        return
    end
    if not NexusKitCharDB then return end
    NexusKitCharDB.completedSteps[stepId] = true
    self:UpdateCurrentStep()
end

------------------------------------------------------------------------
-- Set active route
------------------------------------------------------------------------
function FP:SetActiveRoute(routeId)
    wasRouteComplete = false

    if not routeId or routeId == false then
        self.activeRoute      = nil
        self.currentStepIndex = nil
        if NexusKitCharDB then
            NexusKitCharDB.activeRouteId  = false
            NexusKitCharDB.currentStepIdx = 1
        end
        self:OnStepChanged(nil, nil)
        return
    end

    local route = self.routes[routeId]
    if not route then
        self:Print(string.format(FP.L["IMPORT_ERROR"], "Route not found: " .. tostring(routeId)))
        return
    end

    self.activeRoute      = route
    self.currentStepIndex = nil -- force OnStepChanged after sync

    if NexusKitCharDB then
        NexusKitCharDB.activeRouteId  = routeId
        NexusKitCharDB.currentStepIdx = 1
    end

    self:UpdateCurrentStep()
end

------------------------------------------------------------------------
-- Event registration
------------------------------------------------------------------------
local syncFrame = CreateFrame("Frame", "NexusKitSyncFrame")
syncFrame:RegisterEvent("QUEST_ACCEPTED")
syncFrame:RegisterEvent("QUEST_TURNED_IN")
syncFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
syncFrame:RegisterEvent("PLAYER_XP_UPDATE")
syncFrame:RegisterEvent("PLAYER_LEVEL_UP")
syncFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
syncFrame:RegisterEvent("QUEST_LOG_UPDATE")
syncFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
pcall(syncFrame.RegisterEvent, syncFrame, "QUEST_POI_UPDATE")
pcall(syncFrame.RegisterEvent, syncFrame, "TRAINER_SHOW")
pcall(syncFrame.RegisterEvent, syncFrame, "TRAINER_UPDATE")
pcall(syncFrame.RegisterEvent, syncFrame, "TRAINER_CLOSED")
pcall(syncFrame.RegisterEvent, syncFrame, "LEARNED_SPELL_IN_TAB")
pcall(syncFrame.RegisterEvent, syncFrame, "SPELLS_CHANGED")
pcall(syncFrame.RegisterEvent, syncFrame, "CONFIRM_BINDER")
pcall(syncFrame.RegisterEvent, syncFrame, "HEARTHSTONE_BOUND")
syncFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
syncFrame:RegisterEvent("PLAYER_MONEY")

syncFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "CONFIRM_BINDER" or event == "HEARTHSTONE_BOUND" then
        local curStep = FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
        if curStep and curStep.action == "SET_HEARTH" then
            if NexusKitCharDB and NexusKitCharDB.completedSteps then
                NexusKitCharDB.completedSteps[curStep.id] = true
            end
            FP:UpdateCurrentStep()
            return
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            local spellName = spellID
            if type(spellID) == "number" and GetSpellInfo then
                spellName = GetSpellInfo(spellID)
            end
            if spellID == 8690 or spellID == 556 or spellName == "Hearthstone" or spellName == "Pietra del Ritorno" then
                local curStep = FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
                if curStep and curStep.action == "USE_HEARTH" then
                    if NexusKitCharDB and NexusKitCharDB.completedSteps then
                        NexusKitCharDB.completedSteps[curStep.id] = true
                    end
                    FP:UpdateCurrentStep()
                    return
                end
            end
        end
        return
    end

    if event == "UNIT_QUEST_LOG_CHANGED" then
        local unit = ...
        if unit ~= "player" then return end
    end

    if event == "PLAYER_MONEY" then
        local scan = NexusKitCharDB and NexusKitCharDB.trainerScan
        if not scan or (scan.totalAvail or 0) == 0 or (scan.affordableAvail or 0) > 0 then
            return
        end
        local money = GetMoney and GetMoney() or 0
        if money < (scan.cheapestCost or 0) then
            return
        end
        scan.affordableAvail = 1
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        if FP.ScanOpenClassTrainer then
            if not FP:ScanOpenClassTrainer() then
                return
            end
        end
    elseif event == "TRAINER_CLOSED" or event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED" or event == "PLAYER_LEVEL_UP" then
        if FP.InvalidateTrainerSpellbookCache then
            FP:InvalidateTrainerSpellbookCache()
        end
    end

    if FP.InvalidateQuestPOICache then
        FP:InvalidateQuestPOICache()
    end

    if not FP.activeRoute then return end

    if (event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_LIST_CHANGED" or event == "QUEST_POI_UPDATE")
        and not (FP.IsQuestSyncActive and FP:IsQuestSyncActive()) then
        return
    end

    FP:UpdateCurrentStep()
end)
