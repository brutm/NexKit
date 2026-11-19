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

local function IsSafeNum(v)
    return type(v) == "number" and v == v and v > -1e9 and v < 1e9
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
local readyNpcTitles = {}
local finishedObjectives = {}
local unfinishedObjectives = {}
local runtimeMobRoleCache = {}
local hasAnyIncompleteQuest = false
local stepAction = nil
local stepNpcLower = nil

local function FormatQuestTitle(s)
    if not Plain(s) then return nil end
    local cleaned = s:gsub("^%[%d+[%+%*]?%]%s*", "")
    cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
    return (cleaned ~= "") and cleaned or nil
end

local STOP_WORDS = {
    ["slain"] = true, ["killed"] = true, ["kill"] = true,
    ["collected"] = true, ["gather"] = true, ["destroy"] = true,
    ["ucciso"] = true, ["uccisi"] = true, ["raccogli"] = true, ["trova"] = true,
    ["level"] = true, ["the"] = true, ["and"] = true, ["for"] = true,
    ["with"] = true, ["from"] = true,
}

local MODIFIER_WORDS = {
    ["black"] = true, ["nero"] = true, ["neri"] = true,
    ["red"] = true, ["rosso"] = true, ["rossi"] = true,
    ["green"] = true, ["verde"] = true, ["verdi"] = true,
    ["blue"] = true, ["blu"] = true,
    ["white"] = true, ["bianco"] = true, ["bianchi"] = true,
    ["yellow"] = true, ["giallo"] = true, ["gialli"] = true,
    ["dark"] = true, ["scuro"] = true, ["oscur"] = true,
    ["light"] = true, ["chiaro"] = true,
    ["lesser"] = true, ["inferiore"] = true, ["minore"] = true,
    ["greater"] = true, ["superiore"] = true, ["maggiore"] = true,
    ["young"] = true, ["giovane"] = true,
    ["giant"] = true, ["gigante"] = true,
    ["wild"] = true, ["selvaggio"] = true,
    ["ancient"] = true, ["antico"] = true,
    ["elder"] = true, ["anziano"] = true,
    ["small"] = true, ["piccolo"] = true,
    ["big"] = true, ["grande"] = true,
    ["huge"] = true, ["enorme"] = true,
}

local CROSS_LANG_STEMS = {
    ["lupo"] = "wolf", ["wolf"] = "lupo",
    ["drago"] = "dragon", ["draghetto"] = "whelp", ["whelp"] = "draghetto",
    ["dragon"] = "drago",
    ["ragno"] = "spider", ["spider"] = "ragno",
    ["tarantola"] = "tarantula", ["tarantula"] = "tarantola",
    ["cinghiale"] = "boar", ["boar"] = "cinghiale",
    ["orso"] = "bear", ["bear"] = "orso",
    ["avvoltoio"] = "vulture", ["vulture"] = "avvoltoio",
    ["condor"] = "condor",
    ["aquila"] = "eagle", ["eagle"] = "aquila",
    ["coboldo"] = "kobold", ["kobold"] = "coboldo",
    ["scaglia"] = "scale", ["scale"] = "scaglia",
    ["scaglie"] = "scale",
    ["pelle"] = "pelt", ["pelli"] = "pelts", ["pelt"] = "pelle",
    ["carne"] = "meat", ["meat"] = "carne",
    ["osso"] = "bone", ["ossa"] = "bones", ["bone"] = "osso",
    ["dente"] = "tooth", ["denti"] = "teeth", ["tooth"] = "dente",
    ["pinna"] = "fin", ["pinne"] = "fins", ["fin"] = "pinna",
    ["artiglio"] = "claw", ["artigli"] = "claws", ["claw"] = "artiglio",
    ["nero"] = "black", ["black"] = "nero",
    ["rosso"] = "red", ["red"] = "rosso",
    ["verde"] = "green", ["green"] = "verde",
    ["blu"] = "blue", ["blue"] = "blu",
    ["sotterraneo"] = "underbelly", ["sotterranei"] = "underbelly", ["underbelly"] = "sotterraneo",
    ["gnoll"] = "gnoll", ["murloc"] = "murloc", ["orco"] = "orc", ["orc"] = "orco",
    ["uccidi"] = "kill", ["ucciso"] = "kill", ["uccisi"] = "kill",
    ["raccogli"] = "collect", ["trova"] = "find",
}

local function UnitMatchesObjective(lowerName, obj)
    if not Plain(lowerName) or lowerName == "" or not obj or not Plain(obj.text) then
        return false
    end
    local objLower = obj.text

    -- 1. Exact substring match in either direction
    if objLower:find(lowerName, 1, true) then
        return true
    end

    -- Clean objective text of numbers, progress like "0/6", and punctuation
    local cleanObj = objLower:gsub("%d+%s*/%s*%d+", " "):gsub("%d+", " "):gsub("[%p%c]", " ")

    -- 2. Forward matching: check each significant word of lowerName in cleanObj
    local matchCount = 0
    local totalSigWords = 0
    local hasSpecificMatch = false
    for word in lowerName:gmatch("%S+") do
        if #word >= 3 and not STOP_WORDS[word] then
            totalSigWords = totalSigWords + 1
            local stem4 = word:sub(1, math.min(#word, 4))
            local stem5 = (#word >= 5) and word:sub(1, math.min(#word, 5)) or stem4
            local trans = CROSS_LANG_STEMS[word] or CROSS_LANG_STEMS[stem5] or CROSS_LANG_STEMS[stem4]
            local matched = cleanObj:find(word, 1, true) or cleanObj:find(stem4, 1, true)
                or (trans and (cleanObj:find(trans, 1, true) or cleanObj:find(trans:sub(1, math.min(#trans, 4)), 1, true)))
            if matched then
                matchCount = matchCount + 1
                if not MODIFIER_WORDS[word] and not (trans and MODIFIER_WORDS[trans]) then
                    hasSpecificMatch = true
                end
            end
        end
    end

    if totalSigWords > 0 and matchCount > 0 and hasSpecificMatch then
        if totalSigWords == 1 and matchCount >= 1 then
            return true
        elseif totalSigWords == 2 and matchCount >= 2 then
            return true
        elseif totalSigWords >= 3 and matchCount >= 2 and (matchCount / totalSigWords >= 0.5) then
            return true
        end
    end

    -- 3. Reverse matching: check each significant word of cleanObj in lowerName
    local revMatch = 0
    local revSig = 0
    local revHasSpecific = false
    for word in cleanObj:gmatch("%S+") do
        if #word >= 3 and not STOP_WORDS[word] then
            revSig = revSig + 1
            local stem4 = word:sub(1, math.min(#word, 4))
            local stem5 = (#word >= 5) and word:sub(1, math.min(#word, 5)) or stem4
            local trans = CROSS_LANG_STEMS[word] or CROSS_LANG_STEMS[stem5] or CROSS_LANG_STEMS[stem4]
            local matched = lowerName:find(word, 1, true) or lowerName:find(stem4, 1, true)
                or (trans and (lowerName:find(trans, 1, true) or lowerName:find(trans:sub(1, math.min(#trans, 4)), 1, true)))
            if matched then
                revMatch = revMatch + 1
                if not MODIFIER_WORDS[word] and not (trans and MODIFIER_WORDS[trans]) then
                    revHasSpecific = true
                end
            end
        end
    end

    if revSig > 0 and revMatch > 0 and revHasSpecific then
        if revSig == 1 and revMatch >= 1 then
            return true
        elseif revSig == 2 and revMatch >= 2 then
            return true
        elseif revSig >= 3 and revMatch >= 2 and (revMatch / revSig >= 0.5) then
            return true
        end
    end

    return false
end

local function MatchesObjTable(lowerName, list)
    if not Plain(lowerName) or lowerName == "" or type(list) ~= "table" then
        return false, nil, nil
    end
    for _, item in ipairs(list) do
        if UnitMatchesObjective(lowerName, item) then
            return true, item.role, item.questTitle
        end
    end
    return false, nil, nil
end

local function RebuildQuestLookup()
    for k in pairs(readyQuestTitles) do readyQuestTitles[k] = nil end
    for k in pairs(readyQuestIds) do readyQuestIds[k] = nil end
    for k in pairs(incompleteQuestTitles) do incompleteQuestTitles[k] = nil end
    for k in pairs(incompleteQuestIds) do incompleteQuestIds[k] = nil end
    for k in pairs(readyNpcNames) do readyNpcNames[k] = nil end
    for k in pairs(readyNpcTitles) do readyNpcTitles[k] = nil end
    for i = #finishedObjectives, 1, -1 do finishedObjectives[i] = nil end
    for i = #unfinishedObjectives, 1, -1 do unfinishedObjectives[i] = nil end
    for k in pairs(runtimeMobRoleCache) do runtimeMobRoleCache[k] = nil end
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
    local origSelection = GetQuestLogSelection and SafeCall(GetQuestLogSelection)
    local numEntries = (GetNumQuestLogEntries and SafeCall(GetNumQuestLogEntries))
        or (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and SafeCall(C_QuestLog.GetNumQuestLogEntries)) or 0

    for i = 1, numEntries do
        if SelectQuestLogEntry then
            SafeCall(SelectQuestLogEntry, i)
        end

        local title, _, _, isHeader, _, isComplete, _, qid
        if GetQuestLogTitle then
            title, _, _, isHeader, _, isComplete, _, qid = SafeCall(GetQuestLogTitle, i)
        end
        if (not qid or qid <= 0) and C_QuestLog and C_QuestLog.GetInfo then
            local info = SafeCall(C_QuestLog.GetInfo, i)
            if type(info) == "table" then
                qid = info.questID
                title = info.title
                isHeader = info.isHeader
                isComplete = (info.readyForTurnIn == true)
            end
        end

        local link = GetQuestLink and SafeCall(GetQuestLink, i)
        local linkQid = link and link:match("quest:(%d+)")

        if not isHeader and Plain(title) and title ~= "" then
            qid = (type(qid) == "number" and qid > 0 and qid) or (linkQid and tonumber(linkQid)) or i
            local cleanTitle = FormatQuestTitle(title) or title

            local isReady = (isComplete == 1 or isComplete == true)
            if not isReady and C_QuestLog and C_QuestLog.ReadyForTurnIn then
                isReady = SafeCall(C_QuestLog.ReadyForTurnIn, qid) == true
            end
            if not isReady and C_QuestLog and C_QuestLog.IsComplete and not C_QuestLog.ReadyForTurnIn then
                isReady = SafeCall(C_QuestLog.IsComplete, qid) == true
            end

            local titleKey = CleanTitle(title)
            if titleKey ~= "" and #titleKey >= 3 then
                if isReady then
                    readyQuestTitles[titleKey] = cleanTitle
                else
                    incompleteQuestTitles[titleKey] = cleanTitle
                end
            end

            if isReady then
                readyIds[qid] = true
                readyQuestIds[qid] = cleanTitle
            else
                incompleteQuestIds[qid] = cleanTitle
                hasAnyIncompleteQuest = true
            end

            local numLeader = (GetNumQuestLeaderBoards and SafeCall(GetNumQuestLeaderBoards)) or 0
            if numLeader == 0 and GetNumQuestLeaderBoards then
                numLeader = SafeCall(GetNumQuestLeaderBoards, i) or 0
            end

            if numLeader > 0 and GetQuestLogLeaderBoard then
                for j = 1, numLeader do
                    local desc, objType, done = SafeCall(GetQuestLogLeaderBoard, j)
                    if not desc then
                        desc, objType, done = SafeCall(GetQuestLogLeaderBoard, j, i)
                    end
                    if Plain(desc) and desc ~= "" then
                        local descLower = string.lower(desc)
                        local cur, max = desc:match("(%d+)%s*/%s*(%d+)")
                        local isCompleteText = desc:find("%(Complete%)") or desc:find("%(Completata%)") or desc:find("%(Fertig%)") or desc:find("%(Terminée%)")
                        local counterDone = (cur and max and tonumber(cur) and tonumber(max) and tonumber(cur) >= tonumber(max))
                        local objDone = isReady or done == true or done == 1 or counterDone or (isCompleteText ~= nil)
                        local role = (objType == "item" and "LOOT") or "KILL"
                        if objDone then
                            finishedObjectives[#finishedObjectives + 1] = {
                                questId = qid,
                                questTitle = cleanTitle,
                                text = descLower,
                                role = role,
                            }
                        else
                            unfinishedObjectives[#unfinishedObjectives + 1] = {
                                questId = qid,
                                questTitle = cleanTitle,
                                text = descLower,
                                role = role,
                            }
                        end
                    end
                end
            elseif C_QuestLog and C_QuestLog.GetQuestObjectives then
                local objs = SafeCall(C_QuestLog.GetQuestObjectives, qid)
                if type(objs) == "table" then
                    for _, obj in ipairs(objs) do
                        if type(obj) == "table" and Plain(obj.text) and obj.text ~= "" then
                            local objLower = string.lower(obj.text)
                            local cur, max = objLower:match("(%d+)%s*/%s*(%d+)")
                            local counterDone = (cur and max and tonumber(cur) and tonumber(max) and tonumber(cur) >= tonumber(max))
                            local objDone = isReady or (obj.finished == true) or counterDone
                                or (type(obj.numRequired) == "number" and obj.numRequired > 0
                                    and type(obj.numFulfilled) == "number" and obj.numFulfilled >= obj.numRequired)
                            local role = (obj.type == "item" and "LOOT") or "KILL"
                            if objDone then
                                finishedObjectives[#finishedObjectives + 1] = {
                                    questId = qid,
                                    questTitle = cleanTitle,
                                    text = objLower,
                                    role = role,
                                }
                            else
                                unfinishedObjectives[#unfinishedObjectives + 1] = {
                                    questId = qid,
                                    questTitle = cleanTitle,
                                    text = objLower,
                                    role = role,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    if origSelection and origSelection > 0 and SelectQuestLogEntry then
        SafeCall(SelectQuestLogEntry, origSelection)
    end

    if FP.routes then
        for routeId, route in pairs(FP.routes) do
            if routeId ~= FP.QUEST_SYNC_ROUTE_ID and route.steps then
                for _, st in ipairs(route.steps) do
                    if st.action == "TURNIN" and st.questId and readyIds[st.questId] and Plain(st.npc) and st.npc ~= "" then
                        local npcClean = string.lower((st.npc:gsub("^%s*(.-)%s*$", "%1")))
                        readyNpcNames[npcClean] = true
                        readyNpcTitles[npcClean] = FormatQuestTitle(st.title) or FormatQuestTitle(st.questTitle)
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Unit classification (KILL / LOOT / TURNIN / ACCEPT / STEP_NPC / FRIENDLY_QUEST / OBJECTIVE)
-------------------------------------------------------------------------------
local ROLE_STYLES = {
    KILL = {
        icon = "Interface\\Icons\\Ability_DualWield",
        r = 1.0, g = 0.22, b = 0.22,
        tagKey = "HIGHLIGHT_KILL_TAG",
    },
    LOOT = {
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        r = 1.0, g = 0.70, b = 0.12,
        tagKey = "HIGHLIGHT_LOOT_TAG",
    },
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

local scanTooltip
local function GetScanTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "NexusKitScanTooltip", UIParent, "GameTooltipTemplate")
        scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return scanTooltip
end

local function InspectUnitTooltip(unit, lowerName)
    if not Plain(unit) or not (UnitExists and SafeCall(UnitExists, unit)) then
        return false, false, false, nil, nil
    end

    local lines = {}
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local data = SafeCall(C_TooltipInfo.GetUnit, unit)
        if type(data) == "table" and type(data.lines) == "table" and #data.lines > 0 then
            for lineIdx, line in ipairs(data.lines) do
                if lineIdx > 1 and type(line) == "table" and Plain(line.leftText) and line.leftText ~= "" then
                    lines[#lines + 1] = {
                        text = line.leftText,
                        lineType = line.type,
                        lineQid = (type(line.id) == "number" and line.id > 0) and line.id or nil,
                        completed = (line.completed == true),
                    }
                end
            end
        end
    end

    if #lines == 0 then
        return false, false, false, nil, nil
    end

    local hasReadyTitle = false
    local hasIncompleteObj = false
    local sawIncompleteTitle = false
    local sawObjLine = false
    local detectedRole = nil
    local detectedQuestTitle = nil
    local lastSeenTitle = nil

    local enumQuestTitle = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestTitle

    for _, line in ipairs(lines) do
        local raw = line.text
        local norm = CleanTitle(raw)
        local lineQid = line.lineQid
        local lineType = line.lineType
        local isQuestTitleLine = (enumQuestTitle ~= nil) and (lineType == enumQuestTitle)

        if lineQid and readyQuestIds[lineQid] then
            hasReadyTitle = true
            lastSeenTitle = (type(readyQuestIds[lineQid]) == "string") and readyQuestIds[lineQid] or raw
        elseif lineQid and incompleteQuestIds[lineQid] then
            sawIncompleteTitle = true
            lastSeenTitle = (type(incompleteQuestIds[lineQid]) == "string") and incompleteQuestIds[lineQid] or raw
        end

        if readyQuestTitles[norm] then
            hasReadyTitle = true
            lastSeenTitle = (type(readyQuestTitles[norm]) == "string") and readyQuestTitles[norm] or raw
        elseif incompleteQuestTitles[norm] then
            sawIncompleteTitle = true
            lastSeenTitle = (type(incompleteQuestTitles[norm]) == "string") and incompleteQuestTitles[norm] or raw
        elseif isQuestTitleLine then
            lastSeenTitle = FormatQuestTitle(raw) or raw
        end

        local cur, max = raw:match("(%d+)%s*/%s*(%d+)")
        local isCompleteText = raw:find("%(Complete%)") or raw:find("%(Completata%)") or raw:find("%(Fertig%)") or raw:find("%(Terminée%)")
        if cur and max then
            sawObjLine = true
            local nCur, nMax = tonumber(cur), tonumber(max)
            if nCur and nMax and nCur < nMax and not line.completed and not isCompleteText then
                hasIncompleteObj = true
                detectedQuestTitle = lastSeenTitle
                local rawLower = string.lower(raw)
                local isKill = rawLower:find("slain") or rawLower:find("uccis") or rawLower:find("kill") or rawLower:find("töt")
                local isLoot = rawLower:find("meat") or rawLower:find("pelt") or rawLower:find("fin") or rawLower:find("bone")
                    or rawLower:find("tooth") or rawLower:find("scale") or rawLower:find("feather") or rawLower:find("blood")
                    or rawLower:find("drop") or rawLower:find("collect") or rawLower:find("gather") or rawLower:find("carne")
                    or rawLower:find("pelle") or rawLower:find("pinna") or rawLower:find("dente") or rawLower:find("raccogl")

                if isKill then
                    detectedRole = "KILL"
                elseif isLoot then
                    detectedRole = "LOOT"
                else
                    for _, uo in ipairs(unfinishedObjectives) do
                        if uo.text and rawLower:find(uo.text, 1, true) then
                            detectedRole = uo.role
                            if not detectedQuestTitle then
                                detectedQuestTitle = uo.questTitle
                            end
                            break
                        end
                    end
                    detectedRole = detectedRole or "KILL"
                end
            end
        elseif isCompleteText then
            sawObjLine = true
        end
    end

    local hasCompletedOnlyObj = (not hasIncompleteObj) and (sawObjLine or (hasReadyTitle and not sawIncompleteTitle))
    return hasReadyTitle, hasIncompleteObj, hasCompletedOnlyObj, detectedRole, detectedQuestTitle or lastSeenTitle
end

local function ClassifyUnit(unit)
    if not Plain(unit) or not IsHighlightsEnabled() then return nil, nil end
    if SafeCall(UnitIsDead, unit) then return nil, nil end
    if SafeCall(UnitIsPlayer, unit) then return nil, nil end

    local canAttack = SafeCall(UnitCanAttack, "player", unit) == true
    local rawName = SafeCall(UnitName, unit)
    local lowerName = Plain(rawName) and string.lower((rawName:gsub("^%s*(.-)%s*$", "%1"))) or nil

    -- 1. Current step NPC exact match (friendly or neutral interactive NPC)
    if not canAttack and stepNpcLower and lowerName and lowerName == stepNpcLower then
        local stStep = FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
        local stTitle = stStep and (FormatQuestTitle(stStep.title) or FormatQuestTitle(stStep.text))
        if stepAction == "TURNIN" then
            return "TURNIN", stTitle
        elseif stepAction == "ACCEPT" then
            return "ACCEPT", stTitle
        else
            return "STEP_NPC", stTitle
        end
    end

    -- 2. Ready turn-in NPC from route metadata
    if not canAttack and lowerName and readyNpcNames[lowerName] then
        return "TURNIN", readyNpcTitles[lowerName]
    end

    -- 3. Friendly NPC Tooltip inspection
    if not canAttack then
        local hasReadyTitle, hasIncompleteObj, _, _, tipQuest = InspectUnitTooltip(unit, lowerName)
        if hasReadyTitle then
            return "TURNIN", tipQuest
        elseif hasIncompleteObj then
            return "OBJECTIVE", tipQuest
        end
        return nil, nil
    end

    -- 4. Attackable unit (kill / loot quest target)
    local isUnfinished, unfinRole, unfinQuest = false, nil, nil
    local isFinished, finRole = false, nil
    if lowerName then
        isUnfinished, unfinRole, unfinQuest = MatchesObjTable(lowerName, unfinishedObjectives)
        isFinished, finRole = MatchesObjTable(lowerName, finishedObjectives)
    end

    -- If this mob type matches a COMPLETED quest objective, and NO OTHER unfinished objective requires it:
    -- IT IS 100% COMPLETE! Never show any icon.
    if isFinished and not isUnfinished then
        return nil, nil
    end

    -- Direct Quest Log active objective match
    if isUnfinished then
        return (unfinRole or "KILL"), unfinQuest
    end

    -- Live Tooltip inspection
    local hasReadyTitle, hasIncompleteObj, hasCompletedOnlyObj, tipRole, tipQuest = InspectUnitTooltip(unit, lowerName)
    if hasCompletedOnlyObj and not hasIncompleteObj then
        return nil, nil
    end
    if hasIncompleteObj then
        return (tipRole or "KILL"), tipQuest
    end

    -- If finished in quest log or tooltip, definitely return nil
    if isFinished then
        return nil, nil
    end

    -- Active Route Step matching (ONLY if step quest is not complete, and mob is not already finished)
    if FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps and lowerName then
        local step = FP.activeRoute.steps[FP.currentStepIndex]
        if step and step.action == "COMPLETE" and Plain(step.text) then
            local stepQuestDone = step.questId and readyQuestIds[step.questId]
            if not stepQuestDone then
                local stepLower = string.lower(step.text)
                local dummyObj = { text = stepLower }
                if UnitMatchesObjective(lowerName, dummyObj) then
                    local isKill = stepLower:find("kill") or stepLower:find("slay") or stepLower:find("uccidi")
                    local stTitle = FormatQuestTitle(step.title) or (step.questId and type(incompleteQuestIds[step.questId]) == "string" and incompleteQuestIds[step.questId])
                    return (isKill and "KILL" or "LOOT"), stTitle
                end
            end
        end
    end

    return nil, nil
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

local defaultTags = {
    HIGHLIGHT_KILL_TAG = "Uccidi!",
    HIGHLIGHT_LOOT_TAG = "Raccogli!",
    HIGHLIGHT_TURNIN_TAG = "Consegna!",
    HIGHLIGHT_ACCEPT_TAG = "Accetta!",
    HIGHLIGHT_OBJECTIVE_TAG = "Obiettivo",
}

local function ApplyBadgeStyle(badge, role, showTextTag, questTitle)
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
            local mainTag = L[style.tagKey] or defaultTags[style.tagKey] or ""
            if questTitle and questTitle ~= "" then
                local displayTitle = questTitle
                if #displayTitle > 24 then
                    displayTitle = displayTitle:sub(1, 22) .. "…"
                end
                badge.tag:SetText(mainTag .. "\n|cffffd200" .. displayTitle .. "|r")
            else
                badge.tag:SetText(mainTag)
            end
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

    local host = (plate.UnitFrame and not IsForbiddenObj(plate.UnitFrame) and plate.UnitFrame) or plate
    if IsForbiddenObj(host) then return end

    local badge = plateBadges[plate]
    if not badge then
        badge = CreatePulsingBadge(host, 28, true)
        badge:EnableMouse(false)
        plateBadges[plate] = badge
    else
        if badge:GetParent() ~= host then
            badge:SetParent(host)
        end
    end

    badge.hostPlate = plate
    badge.unit = unit

    badge:ClearAllPoints()
    local raidIdx = unit and GetRaidTargetIndex and SafeCall(GetRaidTargetIndex, unit)
    if IsAccessible(raidIdx) and tonumber(raidIdx) and tonumber(raidIdx) > 0 then
        badge:SetPoint("BOTTOM", host, "TOP", 0, 22)
    else
        badge:SetPoint("BOTTOM", host, "TOP", 0, 8)
    end

    badge:SetFrameStrata("HIGH")
    badge:SetFrameLevel(math.max(100, (host.GetFrameLevel and host:GetFrameLevel() or 2) + 25))

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
    if not IsHighlightsEnabled() or not (UnitExists and UnitExists("target")) or SafeCall(UnitIsDead, "target") then
        if targetBadge then
            if targetBadge.anim then targetBadge.anim:Stop() end
            targetBadge.role = nil
            targetBadge.questTitle = nil
            targetBadge:Hide()
        end
        if not IsHighlightsEnabled() then
            ClearMarkedUnits({ "target" })
        end
        return
    end

    local role, questTitle = ClassifyUnit("target")
    SyncUnitRaidMarker("target", role, true)

    if not role then
        if targetBadge then
            if targetBadge.anim then targetBadge.anim:Stop() end
            targetBadge.role = nil
            targetBadge.questTitle = nil
            targetBadge:Hide()
        end
        return
    end

    if not targetBadge then
        targetBadge = CreatePulsingBadge(UIParent, 26, true)
        targetBadge:EnableMouse(true)
        targetBadge:SetScript("OnEnter", function(self)
            if self.role then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local style = ROLE_STYLES[self.role]
                local r, g, b = (style and style.r or 1), (style and style.g or 0.8), (style and style.b or 0)
                local L = FP.L or {}
                local tagText = (style and style.tagKey and (L[style.tagKey] or defaultTags[style.tagKey])) or "Obiettivo Quest"
                GameTooltip:AddLine(tagText, r, g, b)
                if self.questTitle and self.questTitle ~= "" then
                    GameTooltip:AddLine(self.questTitle, 1, 0.82, 0, true)
                end
                GameTooltip:Show()
            end
        end)
        targetBadge:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    targetBadge.role = role
    targetBadge.questTitle = questTitle

    targetBadge:ClearAllPoints()
    if TargetFrame and not IsForbiddenObj(TargetFrame) and TargetFrame:IsVisible() then
        if targetBadge:GetParent() ~= TargetFrame then
            targetBadge:SetParent(TargetFrame)
        end
        targetBadge:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", -15, -15)
        local tfStrata = (TargetFrame.GetFrameStrata and TargetFrame:GetFrameStrata()) or "MEDIUM"
        local tfLevel = (TargetFrame.GetFrameLevel and TargetFrame:GetFrameLevel()) or 10
        targetBadge:SetFrameStrata(tfStrata == "BACKGROUND" and "LOW" or tfStrata)
        targetBadge:SetFrameLevel(math.max(50, tfLevel + 25))
    else
        if targetBadge:GetParent() ~= UIParent then
            targetBadge:SetParent(UIParent)
        end
        targetBadge:SetFrameStrata("HIGH")
        targetBadge:SetPoint("TOP", UIParent, "TOP", 0, -110)
    end

    ApplyBadgeStyle(targetBadge, role, true, questTitle)
    targetBadge:Show()
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
SafeRegister(eventFrame, "PLAYER_ENTERING_WORLD")
SafeRegister(eventFrame, "QUEST_LOG_UPDATE")
SafeRegister(eventFrame, "UNIT_QUEST_LOG_CHANGED")
SafeRegister(eventFrame, "QUEST_TURNED_IN")
SafeRegister(eventFrame, "QUEST_ACCEPTED")
SafeRegister(eventFrame, "QUEST_WATCH_UPDATE")
SafeRegister(eventFrame, "BAG_UPDATE_DELAYED")
SafeRegister(eventFrame, "BAG_UPDATE")
SafeRegister(eventFrame, "CHAT_MSG_LOOT")
SafeRegister(eventFrame, "UNIT_INVENTORY_CHANGED")
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
SafeRegister(eventFrame, "UNIT_HEALTH")

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
        pcall(InspectInteractiveUnit, "target")
        pcall(UpdateAllNameplates)
    elseif event == "UNIT_HEALTH" and unit == "target" then
        if SafeCall(UnitIsDead, "target") then
            pcall(UpdateTargetBadge)
        end
    elseif event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE" or event == "QUEST_WATCH_UPDATE"
        or event == "CHAT_MSG_LOOT" or event == "UNIT_INVENTORY_CHANGED"
    then
        pcall(function() FP:RefreshHighlights() end)
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

-------------------------------------------------------------------------------
-- Diagnostic slash command: /nkmark or /nkdebug
-------------------------------------------------------------------------------
SLASH_NKMARK1 = "/nkmark"
SLASH_NKMARK2 = "/nkdebug"
SlashCmdList["NKMARK"] = function(msg)
    local targetExists = UnitExists and SafeCall(UnitExists, "target")
    print("|cff00ff96[NexKit Highlights]|r Diagnostica:")
    print(" - EnableHighlights:", IsHighlightsEnabled() and "|cff00ff00SI|r" or "|cffff4444NO|r")
    local countIncomplete = 0
    for _ in pairs(incompleteQuestTitles) do countIncomplete = countIncomplete + 1 end
    print(string.format(" - Missioni attive: %d | Obiettivi incompleti: %d | Obiettivi completati: %d",
        countIncomplete, #unfinishedObjectives, #finishedObjectives))
    for idx, obj in ipairs(unfinishedObjectives) do
        if idx <= 6 then
            print(string.format("   [%d] Q%s: %s (%s)", idx, tostring(obj.questId), tostring(obj.text), tostring(obj.role)))
        end
    end
    if targetExists then
        local name = UnitName("target")
        local role, questTitle = ClassifyUnit("target")
        local canAttack = UnitCanAttack and SafeCall(UnitCanAttack, "player", "target")
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and SafeCall(C_NamePlate.GetNamePlateForUnit, "target")
        local badge = plate and plateBadges[plate]
        print(string.format(" - Target: '%s' (Nemico/Attaccabile: %s)", tostring(name), canAttack and "|cffff4444SI|r" or "|cff00ff00NO|r"))
        print(" - Ruolo identificato:", role and ("|cff00ff00" .. role .. "|r") or "|cffff4444NIL (Non riconosciuto)|r", questTitle and ("|cffffd200[" .. questTitle .. "]|r") or "")
        print(" - NamePlate presente:", plate and "|cff00ff00SI|r" or "|cffff4444NO|r")
        if plate then
            print(" - Badge Nameplate:", (badge and badge:IsShown()) and "|cff00ff00VISIBILE (SOPRA LA TESTA)|r" or "|cffff4444NASCOSTO|r")
        end
    else
        print(" - Target: Nessun bersaglio selezionato (seleziona un mob/PNG e ripeti /nkmark)")
    end
    FP:RefreshHighlights()
end
