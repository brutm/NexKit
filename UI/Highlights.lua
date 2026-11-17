local addonName, FP = ...

-------------------------------------------------------------------------------
-- Highlights.lua – Overhead nameplate & target badges for quest NPCs & mobs
-------------------------------------------------------------------------------

local function Plain(v)
    return type(v) == "string" and not (issecretvalue and issecretvalue(v))
end

local function IsAccessible(v)
    if v == nil then return false end
    if issecretvalue and issecretvalue(v) then return false end
    return true
end

local function IsForbiddenObj(obj)
    return not obj or (obj.IsForbidden and obj:IsForbidden())
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then
        return a, b, c
    end
    return nil
end

local function IsHighlightsEnabled()
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.enableHighlights == false then
        return false
    end
    return true
end

local function CleanTitle(s)
    if not Plain(s) then return "" end
    local cleaned = s:gsub("^%[%d+[%+%*]?%]%s*", "")
    cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
    return string.lower(cleaned)
end

-------------------------------------------------------------------------------
-- Active quest & NPC lookup cache
-------------------------------------------------------------------------------
local readyQuestTitles = {}
local readyQuestIds = {}
local incompleteQuestTitles = {}
local incompleteQuestIds = {}
local readyNpcNames = {}
local finishedObjTexts = {}
local unfinishedObjTexts = {}
local hasAnyIncompleteQuest = false
local stepAction = nil
local stepNpcLower = nil

local function UnitMatchesObjectiveText(lowerName, objText)
    if not Plain(lowerName) or lowerName == "" or not Plain(objText) or objText == "" then
        return false
    end
    if objText:find(lowerName, 1, true) then
        return true
    end
    local matchedWords = 0
    for word in lowerName:gmatch("%S+") do
        if #word >= 4 then
            local stem = (#word >= 6) and word:sub(1, #word - 2) or word:sub(1, math.max(3, #word - 1))
            if not objText:find(stem, 1, true) then
                return false
            end
            matchedWords = matchedWords + 1
        end
    end
    return matchedWords > 0
end

local function UnitMatchesObjList(lowerName, list)
    if not Plain(lowerName) or lowerName == "" or type(list) ~= "table" then return false end
    for _, objText in ipairs(list) do
        if UnitMatchesObjectiveText(lowerName, objText) then
            return true
        end
    end
    return false
end

local function RebuildQuestLookup()
    for k in pairs(readyQuestTitles) do readyQuestTitles[k] = nil end
    for k in pairs(readyQuestIds) do readyQuestIds[k] = nil end
    for k in pairs(incompleteQuestTitles) do incompleteQuestTitles[k] = nil end
    for k in pairs(incompleteQuestIds) do incompleteQuestIds[k] = nil end
    for k in pairs(readyNpcNames) do readyNpcNames[k] = nil end
    for i = #finishedObjTexts, 1, -1 do finishedObjTexts[i] = nil end
    for i = #unfinishedObjTexts, 1, -1 do unfinishedObjTexts[i] = nil end
    hasAnyIncompleteQuest = false

    stepAction = nil
    stepNpcLower = nil
    if FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps then
        local step = FP.activeRoute.steps[FP.currentStepIndex]
        if step then
            stepAction = step.action
            if Plain(step.npc) and step.npc ~= "" then
                stepNpcLower = string.lower((step.npc:gsub("^%s*(.-)%s*$", "%1")))
            end
        end
    end

    local readyIds = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local count = SafeCall(C_QuestLog.GetNumQuestLogEntries) or 0
        for i = 1, count do
            local info = SafeCall(C_QuestLog.GetInfo, i)
            if type(info) == "table" and not info.isHeader and info.questID and info.questID > 0 then
                local qid = info.questID
                local isReady
                if FP.IsQuestReadyForTurnIn then
                    isReady = FP:IsQuestReadyForTurnIn(qid, info.readyForTurnIn == true)
                else
                    isReady = (info.readyForTurnIn == true)
                    if not isReady and C_QuestLog.ReadyForTurnIn then
                        isReady = SafeCall(C_QuestLog.ReadyForTurnIn, qid) == true
                    end
                    if not isReady and C_QuestLog.IsComplete and not C_QuestLog.ReadyForTurnIn then
                        isReady = SafeCall(C_QuestLog.IsComplete, qid) == true
                    end
                end
                local titleKey = CleanTitle(info.title)
                if titleKey ~= "" and #titleKey >= 3 then
                    if isReady then
                        readyQuestTitles[titleKey] = true
                    else
                        incompleteQuestTitles[titleKey] = true
                    end
                end
                if isReady then
                    readyIds[qid] = true
                    readyQuestIds[qid] = true
                else
                    incompleteQuestIds[qid] = true
                    hasAnyIncompleteQuest = true
                end

                if C_QuestLog.GetQuestObjectives then
                    local objs = SafeCall(C_QuestLog.GetQuestObjectives, qid)
                    if type(objs) == "table" then
                        for _, obj in ipairs(objs) do
                            if type(obj) == "table" and Plain(obj.text) and obj.text ~= "" then
                                local objLower = string.lower(obj.text)
                                local objDone = isReady or (obj.finished == true)
                                    or (type(obj.numRequired) == "number" and obj.numRequired > 0
                                        and type(obj.numFulfilled) == "number" and obj.numFulfilled >= obj.numRequired)
                                if objDone then
                                    finishedObjTexts[#finishedObjTexts + 1] = objLower
                                else
                                    unfinishedObjTexts[#unfinishedObjTexts + 1] = objLower
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        local count = GetNumQuestLogEntries() or 0
        for i = 1, count do
            local title, _, _, isHeader, _, isComplete, _, qid = GetQuestLogTitle(i)
            if not isHeader and qid and qid > 0 then
                local isReady
                if FP.IsQuestReadyForTurnIn then
                    isReady = FP:IsQuestReadyForTurnIn(qid, isComplete == 1 or isComplete == true)
                else
                    isReady = (isComplete == 1 or isComplete == true)
                end
                local titleKey = CleanTitle(title)
                if titleKey ~= "" and #titleKey >= 3 then
                    if isReady then
                        readyQuestTitles[titleKey] = true
                    else
                        incompleteQuestTitles[titleKey] = true
                    end
                end
                if isReady then
                    readyIds[qid] = true
                    readyQuestIds[qid] = true
                else
                    incompleteQuestIds[qid] = true
                    hasAnyIncompleteQuest = true
                end

                if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
                    local numLeader = GetNumQuestLeaderBoards(i) or 0
                    for j = 1, numLeader do
                        local desc, _, done = GetQuestLogLeaderBoard(j, i)
                        if Plain(desc) and desc ~= "" then
                            local descLower = string.lower(desc)
                            if isReady or done == true or done == 1 then
                                finishedObjTexts[#finishedObjTexts + 1] = descLower
                            else
                                unfinishedObjTexts[#unfinishedObjTexts + 1] = descLower
                            end
                        end
                    end
                end
            end
        end
    end

    if FP.routes then
        for routeId, route in pairs(FP.routes) do
            if routeId ~= FP.QUEST_SYNC_ROUTE_ID and route.steps then
                for _, st in ipairs(route.steps) do
                    if st.action == "TURNIN" and st.questId and readyIds[st.questId] and Plain(st.npc) and st.npc ~= "" then
                        readyNpcNames[string.lower((st.npc:gsub("^%s*(.-)%s*$", "%1")))] = true
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Unit classification (TURNIN / ACCEPT / STEP_NPC / FRIENDLY_QUEST / OBJECTIVE)
-------------------------------------------------------------------------------
local ROLE_STYLES = {
    TURNIN = {
        icon = "Interface\\GossipFrame\\ActiveQuestIcon",
        r = 1.0, g = 0.84, b = 0.12,
        tagKey = "HIGHLIGHT_TURNIN_TAG",
    },
    ACCEPT = {
        icon = "Interface\\GossipFrame\\AvailableQuestIcon",
        r = 1.0, g = 0.84, b = 0.12,
        tagKey = "HIGHLIGHT_ACCEPT_TAG",
    },
    STEP_NPC = {
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        r = 0.0, g = 1.0, b = 0.59,
        tagKey = nil,
    },
    FRIENDLY_QUEST = {
        icon = "Interface\\GossipFrame\\ActiveQuestIcon",
        r = 0.25, g = 0.95, b = 0.55,
        tagKey = nil,
    },
    OBJECTIVE = {
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        r = 0.15, g = 1.0, b = 0.55,
        tagKey = "HIGHLIGHT_OBJECTIVE_TAG",
    },
}

local function InspectUnitTooltip(unit, lowerName)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return false, false, false end
    local data = SafeCall(C_TooltipInfo.GetUnit, unit)
    if type(data) ~= "table" or type(data.lines) ~= "table" then
        return false, false, false
    end

    local hasReadyTitle = false
    local hasIncompleteObj = false
    local sawIncompleteTitle = false
    local sawObjLine = false
    local enumQuestTitle = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestTitle
    local enumQuestObj = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective

    for lineIdx, line in ipairs(data.lines) do
        if lineIdx > 1 and type(line) == "table" then
            local lineType = line.type
            local lineQid = (type(line.id) == "number" and line.id > 0) and line.id or nil
            local isQuestTitleLine = (enumQuestTitle ~= nil) and (lineType == enumQuestTitle)
            local isQuestObjLine = (enumQuestObj ~= nil) and (lineType == enumQuestObj)

            -- Only treat explicit quest tooltip lines as quest turn-in / objective matches;
            -- never match generic NPC faction, zone, or title lines (e.g. "Stormwind", "Westfall").
            if lineQid and readyQuestIds[lineQid] and (isQuestTitleLine or not enumQuestTitle) then
                hasReadyTitle = true
            elseif lineQid and incompleteQuestIds[lineQid] and (isQuestTitleLine or not enumQuestObj) then
                sawIncompleteTitle = true
            end

            if Plain(line.leftText) then
                local raw = line.leftText
                local norm = CleanTitle(raw)

                if isQuestTitleLine then
                    if readyQuestTitles[norm] or (lineQid and readyQuestIds[lineQid]) then
                        hasReadyTitle = true
                    elseif incompleteQuestTitles[norm] or (lineQid and incompleteQuestIds[lineQid]) then
                        sawIncompleteTitle = true
                    end
                elseif isQuestObjLine then
                    sawObjLine = true
                    local lineCompleted = (line.completed == true)
                    local cur, max = raw:match("(%d+)%s*/%s*(%d+)")
                    if cur and max then
                        local nCur, nMax = tonumber(cur), tonumber(max)
                        if nCur and nMax then
                            if nCur < nMax and not lineCompleted then
                                hasIncompleteObj = true
                            end
                        elseif not lineCompleted then
                            hasIncompleteObj = true
                        end
                    elseif not lineCompleted then
                        hasIncompleteObj = true
                    end
                elseif not enumQuestObj and lineIdx >= 3 then
                    local cur, max = raw:match("(%d+)%s*/%s*(%d+)")
                    if cur and max then
                        sawObjLine = true
                        local nCur, nMax = tonumber(cur), tonumber(max)
                        if nCur and nMax and nCur < nMax and line.completed ~= true then
                            hasIncompleteObj = true
                        end
                    end
                end
            end
        end
    end

    -- Fallback when tooltip shows only an active incomplete QuestTitle line without individual objective counters
    if not hasIncompleteObj and sawIncompleteTitle and not sawObjLine and not hasReadyTitle then
        if not (lowerName and UnitMatchesObjList(lowerName, finishedObjTexts) and not UnitMatchesObjList(lowerName, unfinishedObjTexts)) then
            hasIncompleteObj = true
        end
    end

    local hasCompletedOnlyObj = (not hasIncompleteObj) and (sawObjLine or (hasReadyTitle and not sawIncompleteTitle))
    return hasReadyTitle, hasIncompleteObj, hasCompletedOnlyObj
end

local function ClassifyUnit(unit)
    if not Plain(unit) or not IsHighlightsEnabled() then return nil end
    if SafeCall(UnitIsDead, unit) then return nil end
    if SafeCall(UnitIsPlayer, unit) then return nil end

    local canAttack = SafeCall(UnitCanAttack, "player", unit) == true
    local rawName = SafeCall(UnitName, unit)
    local lowerName = Plain(rawName) and string.lower((rawName:gsub("^%s*(.-)%s*$", "%1"))) or nil

    -- 1. Current step NPC exact match (friendly or neutral interactive NPC)
    if not canAttack and stepNpcLower and lowerName and lowerName == stepNpcLower then
        if stepAction == "TURNIN" then
            return "TURNIN"
        elseif stepAction == "ACCEPT" then
            return "ACCEPT"
        else
            return "STEP_NPC"
        end
    end

    -- 2. Ready turn-in NPC from route metadata
    if not canAttack and lowerName and readyNpcNames[lowerName] then
        return "TURNIN"
    end

    -- 3. Active quest API + Tooltip inspection
    local related = (type(UnitIsRelatedToActiveQuest) == "function")
        and (SafeCall(UnitIsRelatedToActiveQuest, unit) == true)
    local hasReadyTitle, hasIncompleteObj, hasCompletedOnlyObj = InspectUnitTooltip(unit, lowerName)

    if not canAttack then
        if hasReadyTitle then
            return "TURNIN"
        elseif related then
            return "FRIENDLY_QUEST"
        end
    else
        if hasIncompleteObj then
            return "OBJECTIVE"
        elseif hasCompletedOnlyObj then
            return nil
        elseif related and hasAnyIncompleteQuest then
            if lowerName and UnitMatchesObjList(lowerName, finishedObjTexts)
                and not UnitMatchesObjList(lowerName, unfinishedObjTexts) then
                return nil
            end
            return "OBJECTIVE"
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Visual pulsing badge builder (shared by nameplate badges & target badge)
-------------------------------------------------------------------------------
local function CreatePulsingBadge(parent, size, showTag)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetSize(size, size)

    local halo = badge:CreateTexture(nil, "BACKGROUND")
    halo:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    halo:SetBlendMode("ADD")
    halo:SetSize(size * 1.75, size * 1.75)
    halo:SetPoint("CENTER")
    badge.halo = halo

    local ring = badge:CreateTexture(nil, "BORDER")
    ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    ring:SetBlendMode("ADD")
    ring:SetSize(size * 1.45, size * 1.45)
    ring:SetPoint("CENTER")
    badge.ring = ring

    local icon = badge:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size * 0.78, size * 0.78)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)
    badge.icon = icon

    if showTag then
        local tag = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tag:SetPoint("BOTTOM", badge, "TOP", 0, 2)
        tag:SetJustifyH("CENTER")
        badge.tag = tag
    end

    local ag = halo:CreateAnimationGroup()
    local s1 = ag:CreateAnimation("Scale")
    s1:SetScaleFrom(0.85, 0.85)
    s1:SetScaleTo(1.38, 1.38)
    s1:SetDuration(1.0)
    s1:SetSmoothing("OUT")
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0.95)
    a1:SetToAlpha(0.15)
    a1:SetDuration(1.0)
    a1:SetSmoothing("OUT")
    ag:SetLooping("REPEAT")
    badge.anim = ag

    badge:Hide()
    return badge
end

local function ApplyBadgeStyle(badge, role, showTextTag)
    local style = ROLE_STYLES[role]
    if not style then
        if badge.anim then badge.anim:Stop() end
        badge:Hide()
        return
    end

    badge.icon:SetTexture(style.icon)
    if type(style.icon) == "string" and style.icon:find("^Interface\\Icons\\") then
        badge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        badge.icon:SetTexCoord(0, 1, 0, 1)
    end
    badge.halo:SetVertexColor(style.r, style.g, style.b, 0.9)
    badge.ring:SetVertexColor(style.r, style.g, style.b, 0.85)

    if badge.tag then
        local L = FP.L or {}
        if showTextTag and style.tagKey then
            badge.tag:SetText(L[style.tagKey] or "")
            badge.tag:SetTextColor(style.r, style.g, style.b, 1)
            badge.tag:Show()
        else
            badge.tag:Hide()
        end
    end

    badge:Show()
    if badge.anim and not badge.anim:IsPlaying() then
        badge.anim:Play()
    end
end

-------------------------------------------------------------------------------
-- Native 3D Raid Target Marker (e.g. Red Cross "X" over Turn-In NPC heads)
-------------------------------------------------------------------------------
local RAID_MARKER_STAR  = 1 -- Gold Star for Accept step NPCs
local RAID_MARKER_CROSS = 7 -- Red Cross ("X") for Turn-In NPCs

local activeRaidMarks = {} -- [markerIdx] = { key = unitKey, time = GetTime() }

local function CanAutoMarkNpc()
    if not IsHighlightsEnabled() then return false end
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.enableRaidMarkers == false then
        return false
    end
    if type(SetRaidTarget) ~= "function" or type(GetRaidTargetIndex) ~= "function" then
        return false
    end
    local inRaid = IsInRaid and SafeCall(IsInRaid)
    if inRaid then
        local leader = UnitIsGroupLeader and SafeCall(UnitIsGroupLeader, "player")
        local assist = UnitIsGroupAssistant and SafeCall(UnitIsGroupAssistant, "player")
        if not leader and not assist then
            return false
        end
    end
    -- Respect dungeon/raid kill-order markers when grouped inside instances
    local inGroup = IsInGroup and SafeCall(IsInGroup)
    if inGroup and IsInInstance then
        local inInst, instType = SafeCall(IsInInstance)
        if inInst and (instType == "party" or instType == "raid" or instType == "scenario") then
            return false
        end
    end
    return true
end

local function GetSafeUnitKey(unit)
    local guid = UnitGUID and SafeCall(UnitGUID, unit)
    if Plain(guid) and guid ~= "" then
        return guid, nil
    end
    local rawName = UnitName and SafeCall(UnitName, unit)
    if Plain(rawName) and rawName ~= "" then
        local trimmed = string.lower((rawName:gsub("^%s*(.-)%s*$", "%1")))
        return "name:" .. trimmed, trimmed
    end
    return nil, nil
end

local function SyncUnitRaidMarker(unit, role, isDirectUnit)
    -- Disabled in Midnight 12.x / 16001: automated SetRaidTarget calls from addon
    -- event/nameplate handlers are blocked by Blizzard security (ADDON_ACTION_BLOCKED).
    -- Overhead pulsing badges remain active without modifying raid target icons.
    return
end

local function ClearMarkedUnits(units)
    for idx in pairs(activeRaidMarks) do
        activeRaidMarks[idx] = nil
    end
end

-------------------------------------------------------------------------------
-- Nameplate overlay tracking
-------------------------------------------------------------------------------
local activePlates = {} -- unitToken -> plate frame
local plateBadges = {}  -- plate frame -> badge frame

local function HidePlateBadge(plate)
    local badge = plate and plateBadges[plate]
    if badge then
        if badge.anim then badge.anim:Stop() end
        badge.hostPlate = nil
        badge.unit = nil
        badge:Hide()
    end
end

local function RepositionPlateBadge(badge, plate, unit)
    if not badge or not plate or IsForbiddenObj(plate) or not (plate.IsVisible and plate:IsVisible()) then
        if badge and badge.anim then badge.anim:Stop() end
        if badge then badge:Hide() end
        return false
    end
    local left = plate.GetLeft and plate:GetLeft()
    local right = plate.GetRight and plate:GetRight()
    local top = plate.GetTop and plate:GetTop()
    if not IsSafeNum(left) or not IsSafeNum(right) or not IsSafeNum(top) then
        if badge.anim then badge.anim:Stop() end
        badge:Hide()
        return false
    end
    local hScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local pScale = (plate.GetEffectiveScale and plate:GetEffectiveScale()) or hScale
    local cx = (((left + right) * 0.5) * pScale) / hScale
    local ty = (top * pScale) / hScale

    local raidIdx = unit and GetRaidTargetIndex and SafeCall(GetRaidTargetIndex, unit)
    badge:ClearAllPoints()
    if IsAccessible(raidIdx) and tonumber(raidIdx) and tonumber(raidIdx) > 0 then
        badge:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx - 36, ty + 6)
    else
        badge:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, ty + 16)
    end
    return true
end

local function UpdatePlateForUnit(unit)
    if not Plain(unit) or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return end
    local plate = SafeCall(C_NamePlate.GetNamePlateForUnit, unit)
    if not plate or IsForbiddenObj(plate) then return end

    activePlates[unit] = plate

    local role = ClassifyUnit(unit)
    SyncUnitRaidMarker(unit, role, false)

    if not role then
        HidePlateBadge(plate)
        return
    end

    -- Parent badge to UIParent using screen coordinates (never anchor to Blizzard NamePlate) so secure frame tree remains 100% untainted
    local badge = plateBadges[plate]
    if not badge then
        badge = CreatePulsingBadge(UIParent, 26, true)
        badge:EnableMouse(false)
        badge.accum = 0
        badge:SetScript("OnUpdate", function(self, elapsed)
            self.accum = (self.accum or 0) + elapsed
            if self.accum < 0.04 then return end
            self.accum = 0
            local p = self.hostPlate
            if not RepositionPlateBadge(self, p, self.unit) then
                self:Hide()
            end
        end)
        plateBadges[plate] = badge
    end
    badge.hostPlate = plate
    badge.unit = unit

    local strata = (plate.GetFrameStrata and plate:GetFrameStrata()) or "BACKGROUND"
    badge:SetFrameStrata(strata)
    badge:SetFrameLevel(math.max(10, (plate.GetFrameLevel and plate:GetFrameLevel() or 2) + 8))

    if not RepositionPlateBadge(badge, plate, unit) then
        HidePlateBadge(plate)
        return
    end

    -- Show text tag above Turn-In / Accept NPCs; keep enemy objectives clean icon + glow
    local showText = (role == "TURNIN" or role == "ACCEPT")
    ApplyBadgeStyle(badge, role, showText)
    badge:Show()
end

local function UpdateAllNameplates()
    if not IsHighlightsEnabled() then
        local unitsToClear = {}
        for unit, plate in pairs(activePlates) do
            HidePlateBadge(plate)
            unitsToClear[#unitsToClear + 1] = unit
        end
        ClearMarkedUnits(unitsToClear)
        ClearMarkedUnits({ "target", "mouseover", "softinteract", "npc" })
        return
    end
    for unit in pairs(activePlates) do
        UpdatePlateForUnit(unit)
    end
end

-------------------------------------------------------------------------------
-- TargetFrame highlight badge (works even when Shift+V friendly plates are OFF)
-------------------------------------------------------------------------------
local targetBadge

local function InspectInteractiveUnit(unit)
    if not Plain(unit) or not (UnitExists and SafeCall(UnitExists, unit)) then return end
    local role = ClassifyUnit(unit)
    SyncUnitRaidMarker(unit, role, true)
end

local function UpdateTargetBadge()
    if not IsHighlightsEnabled() or not (UnitExists and UnitExists("target")) then
        if targetBadge then
            if targetBadge.anim then targetBadge.anim:Stop() end
            targetBadge:Hide()
        end
        if not IsHighlightsEnabled() then
            ClearMarkedUnits({ "target" })
        end
        return
    end

    local role = ClassifyUnit("target")
    SyncUnitRaidMarker("target", role, true)

    if not role then
        if targetBadge then
            if targetBadge.anim then targetBadge.anim:Stop() end
            targetBadge:Hide()
        end
        return
    end

    if not targetBadge then
        targetBadge = CreatePulsingBadge(UIParent, 24, true)
        targetBadge:EnableMouse(false)
    end

    targetBadge:ClearAllPoints()
    if TargetFrame and not IsForbiddenObj(TargetFrame) and TargetFrame:IsVisible() then
        local tfStrata = (TargetFrame.GetFrameStrata and TargetFrame:GetFrameStrata()) or "MEDIUM"
        local tfLevel = (TargetFrame.GetFrameLevel and TargetFrame:GetFrameLevel()) or 10
        targetBadge:SetFrameStrata(tfStrata == "BACKGROUND" and "LOW" or tfStrata)
        targetBadge:SetFrameLevel(math.max(20, tfLevel + 12))

        local tfRight = TargetFrame.GetRight and TargetFrame:GetRight()
        local tfTop = TargetFrame.GetTop and TargetFrame:GetTop()
        if IsSafeNum(tfRight) and IsSafeNum(tfTop) then
            local tfScale = (TargetFrame.GetEffectiveScale and TargetFrame:GetEffectiveScale()) or 1
            local uiScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
            local x = (tfRight * tfScale) / uiScale
            local y = (tfTop * tfScale) / uiScale
            targetBadge:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 10, y - 26)
        else
            targetBadge:SetPoint("TOP", UIParent, "TOP", 0, -110)
        end
    else
        targetBadge:SetFrameStrata("HIGH")
        targetBadge:SetPoint("TOP", UIParent, "TOP", 0, -110)
    end

    ApplyBadgeStyle(targetBadge, role, true)
end

-------------------------------------------------------------------------------
-- Public refresh & Event wiring
-------------------------------------------------------------------------------
function FP:RefreshHighlights()
    RebuildQuestLookup()
    UpdateAllNameplates()
    UpdateTargetBadge()
    InspectInteractiveUnit("mouseover")
    InspectInteractiveUnit("softinteract")
    InspectInteractiveUnit("npc")
end

local function SafeRegister(f, evt)
    pcall(f.RegisterEvent, f, evt)
end

local eventFrame = CreateFrame("Frame")
SafeRegister(eventFrame, "PLAYER_LOGIN")
SafeRegister(eventFrame, "QUEST_LOG_UPDATE")
SafeRegister(eventFrame, "UNIT_QUEST_LOG_CHANGED")
SafeRegister(eventFrame, "QUEST_TURNED_IN")
SafeRegister(eventFrame, "QUEST_ACCEPTED")
SafeRegister(eventFrame, "NAME_PLATE_UNIT_ADDED")
SafeRegister(eventFrame, "NAME_PLATE_UNIT_REMOVED")
SafeRegister(eventFrame, "PLAYER_TARGET_CHANGED")
SafeRegister(eventFrame, "PLAYER_SOFT_INTERACT_CHANGED")
SafeRegister(eventFrame, "GOSSIP_SHOW")
SafeRegister(eventFrame, "QUEST_GREETING")
SafeRegister(eventFrame, "QUEST_PROGRESS")
SafeRegister(eventFrame, "QUEST_COMPLETE")
SafeRegister(eventFrame, "QUEST_DETAIL")
SafeRegister(eventFrame, "PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        pcall(UpdatePlateForUnit, unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if Plain(unit) and activePlates[unit] then
            HidePlateBadge(activePlates[unit])
            activePlates[unit] = nil
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        pcall(UpdateTargetBadge)
    elseif event == "PLAYER_REGEN_ENABLED" then
        pcall(function() FP:RefreshHighlights() end)
    elseif event == "PLAYER_SOFT_INTERACT_CHANGED" then
        pcall(InspectInteractiveUnit, "softinteract")
    elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_PROGRESS"
        or event == "QUEST_COMPLETE" or event == "QUEST_DETAIL"
    then
        pcall(InspectInteractiveUnit, "npc")
        pcall(InspectInteractiveUnit, "target")
    elseif event == "QUEST_TURNED_IN" or event == "QUEST_ACCEPTED"
        or event == "QUEST_LOG_UPDATE" or (event == "UNIT_QUEST_LOG_CHANGED" and unit == "player")
    then
        pcall(function() FP:RefreshHighlights() end)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.15, function()
                pcall(function() FP:RefreshHighlights() end)
            end)
        end
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        return
    else
        pcall(function() FP:RefreshHighlights() end)
    end
end)

if FP.RegisterStepChangedCallback then
    FP:RegisterStepChangedCallback(function()
        pcall(function() FP:RefreshHighlights() end)
    end)
end
