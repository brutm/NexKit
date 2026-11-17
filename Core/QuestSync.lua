-- NexusKit  –  Core/QuestSync.lua
-- Dynamic Quest Log synchronization engine.
-- Reads the player's active Quest Log (and on-screen tracked quests), detects the
-- current zone & map POIs, and prioritizes which quests to complete first.
local _, FP = ...

FP.QUEST_SYNC_ROUTE_ID = "__QUEST_SYNC__"
FP.skippedSyncQuests   = FP.skippedSyncQuests or {}

------------------------------------------------------------------------
-- Safe WoW API helpers (Interface 16001 / Classic-Midnight compatible)
------------------------------------------------------------------------
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = { pcall(fn, ...) }
    if not results[1] then return nil end
    return unpack(results, 2)
end

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function IsSafeNum(v)
    return type(v) == "number" and not IsSecret(v)
end

local function GetPlayerZoneContext()
    local mapID = C_Map and C_Map.GetBestMapForUnit and SafeCall(C_Map.GetBestMapForUnit, "player")
    if not IsSafeNum(mapID) then mapID = nil end
    local mapName = ""
    local parentMapID = nil
    if mapID and C_Map.GetMapInfo then
        local info = SafeCall(C_Map.GetMapInfo, mapID)
        if type(info) == "table" then
            if type(info.name) == "string" and not IsSecret(info.name) then
                mapName = info.name
            end
            if IsSafeNum(info.parentMapID) and info.parentMapID > 0 then
                parentMapID = info.parentMapID
            end
        end
    end
    local realZone = (GetRealZoneText and SafeCall(GetRealZoneText)) or ""
    if IsSecret(realZone) or type(realZone) ~= "string" then realZone = "" end
    local zoneText = (GetZoneText and SafeCall(GetZoneText)) or ""
    if IsSecret(zoneText) or type(zoneText) ~= "string" then zoneText = "" end

    local px, py
    if mapID and C_Map.GetPlayerMapPosition then
        local pos = SafeCall(C_Map.GetPlayerMapPosition, mapID, "player")
        if pos and pos.GetXY then
            local x, y = pos:GetXY()
            if IsSafeNum(x) and IsSafeNum(y) and (x ~= 0 or y ~= 0) then
                px = x * 100
                py = y * 100
            end
        end
    end

    return {
        mapID       = mapID,
        parentMapID = parentMapID,
        zoneName    = (mapName ~= "" and mapName) or (realZone ~= "" and realZone) or zoneText,
        realZone    = realZone,
        px          = px,
        py          = py,
    }
end

local liveCache = {
    poi       = {},
    poiStamp  = 0,
    meta      = {},
    children  = {},
}

function FP:InvalidateQuestPOICache()
    liveCache.poi = {}
    liveCache.poiStamp = 0
end

local function AppendUniqueCoordStep(list, step)
    for _, existing in ipairs(list) do
        if existing.mapID == step.mapID
            and math.abs(existing.x - step.x) < 0.25
            and math.abs(existing.y - step.y) < 0.25 then
            return
        end
    end
    list[#list + 1] = {
        mapID          = step.mapID,
        x              = step.x,
        y              = step.y,
        objectiveIndex = step.objectiveIndex,
    }
end

local function BuildRouteCoordFallback()
    local lookup = {}
    if not FP.routes then return lookup end

    for routeId, route in pairs(FP.routes) do
        if routeId ~= FP.QUEST_SYNC_ROUTE_ID and route.steps then
            for _, s in ipairs(route.steps) do
                if s.questId and s.mapID and s.x and s.y then
                    local entry = lookup[s.questId]
                    if not entry then
                        entry = {}
                        lookup[s.questId] = entry
                    end
                    -- Keep TURNIN, COMPLETE, and ACCEPT strictly separate so ready turn-ins never point back to quest-givers
                    if s.action == "TURNIN" then
                        entry.TURNIN = entry.TURNIN or {}
                        AppendUniqueCoordStep(entry.TURNIN, s)
                    elseif s.action == "COMPLETE" then
                        entry.COMPLETE = entry.COMPLETE or {}
                        AppendUniqueCoordStep(entry.COMPLETE, s)
                    elseif s.action == "ACCEPT" then
                        entry.ACCEPT = entry.ACCEPT or {}
                        AppendUniqueCoordStep(entry.ACCEPT, s)
                    end
                end
            end
        end
    end
    return lookup
end

local function AddPOIToBucket(pois, qid, x100, y100, isInd)
    local bucket = pois[qid]
    local entry = { x = x100, y = y100, isIndicator = isInd and true or false }
    if not bucket then
        pois[qid] = {
            x           = entry.x,
            y           = entry.y,
            isIndicator = entry.isIndicator,
            list        = { entry },
        }
        return
    end
    for _, existing in ipairs(bucket.list) do
        if math.abs(existing.x - entry.x) < 0.25 and math.abs(existing.y - entry.y) < 0.25
            and existing.isIndicator == entry.isIndicator then
            return
        end
    end
    bucket.list[#bucket.list + 1] = entry
    if bucket.isIndicator and not entry.isIndicator then
        bucket.x = entry.x
        bucket.y = entry.y
        bucket.isIndicator = false
    end
end

local function CollectMapPOIs(mapID, cache)
    if not IsSafeNum(mapID) or mapID <= 0 then return {} end
    if cache[mapID] then return cache[mapID] end

    local pois = {}
    if C_QuestLog and C_QuestLog.GetQuestsOnMap then
        local mapQuests = SafeCall(C_QuestLog.GetQuestsOnMap, mapID)
        if type(mapQuests) == "table" then
            for _, q in ipairs(mapQuests) do
                if type(q) == "table" and IsSafeNum(q.questID) and IsSafeNum(q.x) and IsSafeNum(q.y)
                    and (q.x ~= 0 or q.y ~= 0) then
                    AddPOIToBucket(pois, q.questID, q.x * 100, q.y * 100, q.isMapIndicatorQuest == true)
                end
            end
        end
    end
    if C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
        local taskQuests = SafeCall(C_TaskQuest.GetQuestsOnMap, mapID)
        if type(taskQuests) == "table" then
            for _, q in ipairs(taskQuests) do
                local tqid = type(q) == "table" and (q.questID or q.questId) or nil
                if IsSafeNum(tqid) and IsSafeNum(q.x) and IsSafeNum(q.y) and (q.x ~= 0 or q.y ~= 0) then
                    AddPOIToBucket(pois, tqid, q.x * 100, q.y * 100, false)
                end
            end
        end
    end
    cache[mapID] = pois
    return pois
end

local function GetMapInfoCached(mapID, metaCache)
    if not IsSafeNum(mapID) or mapID <= 0 then return nil end
    if metaCache and metaCache[mapID] ~= nil then
        return metaCache[mapID] ~= false and metaCache[mapID] or nil
    end
    local info = (C_Map and C_Map.GetMapInfo) and SafeCall(C_Map.GetMapInfo, mapID) or nil
    if type(info) ~= "table" then info = false end
    if metaCache then
        metaCache[mapID] = info
    end
    return info ~= false and info or nil
end

local function GetMapDisplayName(mapID, nameCache, metaCache)
    if not IsSafeNum(mapID) or mapID <= 0 then return nil end
    if nameCache[mapID] ~= nil then
        return nameCache[mapID] ~= false and nameCache[mapID] or nil
    end
    local name = false
    local info = GetMapInfoCached(mapID, metaCache)
    if info and type(info.name) == "string" and not IsSecret(info.name) and info.name ~= "" then
        name = info.name
    end
    nameCache[mapID] = name
    return name ~= false and name or nil
end

local function IsContinentOrWorldMap(mapID, metaCache)
    local info = GetMapInfoCached(mapID, metaCache)
    if not info or not IsSafeNum(info.mapType) then return false end
    if Enum and Enum.UIMapType then
        return info.mapType == Enum.UIMapType.Continent
            or info.mapType == Enum.UIMapType.World
            or info.mapType == Enum.UIMapType.Cosmic
    end
    return info.mapType <= 2
end

local function IsMicroOrSubzoneOf(childMapID, parentMapID, metaCache)
    if not IsSafeNum(childMapID) or not IsSafeNum(parentMapID) or childMapID == parentMapID then
        return false
    end
    local info = GetMapInfoCached(childMapID, metaCache)
    if not info or info.parentMapID ~= parentMapID then return false end
    local microType = (Enum and Enum.UIMapType and Enum.UIMapType.Micro) or 5
    return info.mapType == microType
end

local function FindAncestorContinent(mapID, metaCache)
    local cur = mapID
    for _ = 1, 4 do
        local info = GetMapInfoCached(cur, metaCache)
        if not info then break end
        if Enum and Enum.UIMapType and info.mapType == Enum.UIMapType.Continent then
            return cur
        elseif not (Enum and Enum.UIMapType) and info.mapType == 2 then
            return cur
        end
        if IsSafeNum(info.parentMapID) and info.parentMapID > 0 and info.parentMapID ~= cur then
            cur = info.parentMapID
        else
            break
        end
    end
    return nil
end

local function GetDesignatedQuestMapID(qid)
    if not GetQuestUiMapID then return nil end
    -- ignoreWaypoints = true bypasses intermediate flight/portal transit waypoints
    local qm = SafeCall(GetQuestUiMapID, qid, true)
    if not IsSafeNum(qm) or qm <= 0 then
        qm = SafeCall(GetQuestUiMapID, qid)
    end
    if IsSafeNum(qm) and qm > 0 then
        return qm
    end
    return nil
end

local function ConvertMapCoords100(fromMapID, toMapID, x100, y100)
    if not IsSafeNum(fromMapID) or not IsSafeNum(toMapID) or not IsSafeNum(x100) or not IsSafeNum(y100) then
        return nil, nil
    end
    if fromMapID == toMapID then return x100, y100 end
    local nx, ny = x100 / 100, y100 / 100
    if C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos then
        local tVec = CreateVector2D and CreateVector2D(nx, ny) or { x = nx, y = ny }
        local tCont, tWorld = SafeCall(C_Map.GetWorldPosFromMapPos, fromMapID, tVec)
        if tCont and tWorld then
            local _, mapPos = SafeCall(C_Map.GetMapPosFromWorldPos, tCont, tWorld, toMapID)
            if mapPos and mapPos.GetXY then
                local px, py = mapPos:GetXY()
                if IsSafeNum(px) and IsSafeNum(py) and px >= 0 and px <= 1 and py >= 0 and py <= 1 then
                    return px * 100, py * 100
                end
            end
        end
    end
    if C_Map and C_Map.GetMapRectOnMap then
        local minX, maxX, minY, maxY = SafeCall(C_Map.GetMapRectOnMap, toMapID, fromMapID)
        if IsSafeNum(minX) and IsSafeNum(maxX) and IsSafeNum(minY) and IsSafeNum(maxY)
            and maxX > minX and maxY > minY and not (minX == 0 and maxX == 0) then
            local zx = (nx - minX) / (maxX - minX)
            local zy = (ny - minY) / (maxY - minY)
            if zx >= 0 and zx <= 1 and zy >= 0 and zy <= 1 then
                return zx * 100, zy * 100
            end
        end
    end
    return nil, nil
end

local function ReadVecXY(vec)
    if not vec then return nil, nil end
    if vec.GetXY then
        local vx, vy = vec:GetXY()
        if IsSafeNum(vx) and IsSafeNum(vy) then return vx, vy end
    end
    if IsSafeNum(vec.x) and IsSafeNum(vec.y) then
        return vec.x, vec.y
    end
    return nil, nil
end

function FP:ComputeWorldDistanceYards(mapA, x100A, y100A, mapB, x100B, y100B, metaCache)
    if not IsSafeNum(mapA) or not IsSafeNum(x100A) or not IsSafeNum(y100A)
        or not IsSafeNum(mapB) or not IsSafeNum(x100B) or not IsSafeNum(y100B) then
        return nil
    end
    local nxA, nyA = x100A / 100, y100A / 100
    local nxB, nyB = x100B / 100, y100B / 100

    if C_Map and C_Map.GetWorldPosFromMapPos then
        local vA = CreateVector2D and CreateVector2D(nxA, nyA) or { x = nxA, y = nyA }
        local vB = CreateVector2D and CreateVector2D(nxB, nyB) or { x = nxB, y = nyB }
        local contA, wA = SafeCall(C_Map.GetWorldPosFromMapPos, mapA, vA)
        local contB, wB = SafeCall(C_Map.GetWorldPosFromMapPos, mapB, vB)
        if IsSafeNum(contA) and contA == contB then
            local ax, ay = ReadVecXY(wA)
            local bx, by = ReadVecXY(wB)
            if ax and ay and bx and by then
                local dx, dy = ax - bx, ay - by
                return math.sqrt(dx * dx + dy * dy)
            end
        end
    end

    if mapA == mapB then
        local mw, mh
        if C_Map and C_Map.GetMapWorldSize then
            mw, mh = SafeCall(C_Map.GetMapWorldSize, mapA)
        end
        if not IsSafeNum(mw) or mw <= 0 then mw = 3000 end
        if not IsSafeNum(mh) or mh <= 0 then mh = 2000 end
        local dx, dy = (nxA - nxB) * mw, (nyA - nyB) * mh
        return math.sqrt(dx * dx + dy * dy)
    end

    local mc = metaCache or liveCache.meta
    local contMapA = FindAncestorContinent(mapA, mc)
    local contMapB = FindAncestorContinent(mapB, mc)
    if contMapA and contMapA == contMapB then
        local cxA, cyA = ConvertMapCoords100(mapA, contMapA, x100A, y100A)
        local cxB, cyB = ConvertMapCoords100(mapB, contMapA, x100B, y100B)
        if cxA and cyA and cxB and cyB then
            local cw, ch
            if C_Map and C_Map.GetMapWorldSize then
                cw, ch = SafeCall(C_Map.GetMapWorldSize, contMapA)
            end
            if not IsSafeNum(cw) or cw <= 0 then cw = 15000 end
            if not IsSafeNum(ch) or ch <= 0 then ch = 10000 end
            local dx = ((cxA - cxB) / 100) * cw
            local dy = ((cyA - cyB) / 100) * ch
            return math.sqrt(dx * dx + dy * dy)
        end
    end

    return nil
end

local function AddDestCandidate(list, mapID, x100, y100, tier, targetMapID, isTransit)
    if not IsSafeNum(mapID) or mapID <= 0 or not IsSafeNum(x100) or not IsSafeNum(y100)
        or (x100 == 0 and y100 == 0) then
        return
    end
    for _, existing in ipairs(list) do
        if existing.mapID == mapID
            and math.abs(existing.x - x100) < 0.30
            and math.abs(existing.y - y100) < 0.30 then
            if tier < existing.tier then
                existing.tier = tier
                existing.isTransit = isTransit and true or false
                if targetMapID then existing.targetMapID = targetMapID end
            end
            return
        end
    end
    list[#list + 1] = {
        mapID       = mapID,
        x           = x100,
        y           = y100,
        tier        = tier,
        targetMapID = targetMapID,
        isTransit   = isTransit and true or false,
    }
end

local function AddBucketEntriesForMap(candidates, qid, mapID, poiCache, nonIndTier, indTier, resolvedTarget)
    if not IsSafeNum(mapID) or mapID <= 0 then return 0 end
    local pois = CollectMapPOIs(mapID, poiCache)
    local bucket = pois[qid]
    if not bucket or not bucket.list then return 0 end
    local genuineCount = 0
    for _, entry in ipairs(bucket.list) do
        if not entry.isIndicator then
            genuineCount = genuineCount + 1
            if nonIndTier then
                AddDestCandidate(candidates, mapID, entry.x, entry.y, nonIndTier, resolvedTarget or mapID, false)
            end
        elseif indTier then
            AddDestCandidate(candidates, mapID, entry.x, entry.y, indTier, resolvedTarget, true)
        end
    end
    return genuineCount
end

local function GetZoneChildrenCached(continentMapID, childrenCache)
    if not IsSafeNum(continentMapID) or continentMapID <= 0 or not C_Map or not C_Map.GetMapChildrenInfo then
        return nil
    end
    local children = childrenCache[continentMapID]
    if children == nil then
        local zoneType = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
        children = SafeCall(C_Map.GetMapChildrenInfo, continentMapID, zoneType, true) or false
        childrenCache[continentMapID] = children
    end
    return type(children) == "table" and children or nil
end

local function SelectBestDestCandidate(candidates, refMapID, refX, refY, preferMapID, targetMapID, metaCache, opts)
    if #candidates == 0 then return nil end

    local minTier = candidates[1].tier
    for i = 2, #candidates do
        if candidates[i].tier < minTier then
            minTier = candidates[i].tier
        end
    end

    local pool = {}
    local hasRef = IsSafeNum(refMapID) and IsSafeNum(refX) and IsSafeNum(refY)
    for _, c in ipairs(candidates) do
        if c.tier == minTier then
            if hasRef then
                c.distYards = FP:ComputeWorldDistanceYards(refMapID, refX, refY, c.mapID, c.x, c.y, metaCache)
            end
            pool[#pool + 1] = c
        end
    end
    if #pool == 0 then return nil end

    local best = pool[1]
    for i = 2, #pool do
        local c = pool[i]
        local bDist, cDist = best.distYards, c.distYards
        local better = false
        if cDist and bDist then
            if math.abs(cDist - bDist) > 1 then
                better = (cDist < bDist)
            elseif c.mapID == preferMapID and best.mapID ~= preferMapID then
                better = true
            elseif c.mapID == targetMapID and best.mapID ~= targetMapID and best.mapID ~= preferMapID then
                better = true
            end
        elseif cDist and not bDist then
            -- Same-continent finite distance always beats unreachable cross-continent/unknown distance
            better = true
        elseif not cDist and not bDist then
            if c.mapID == preferMapID and best.mapID ~= preferMapID then
                better = true
            elseif c.mapID == targetMapID and best.mapID ~= targetMapID and best.mapID ~= preferMapID then
                better = true
            end
        end
        if better then
            best = c
        end
    end

    -- Apply optional hysteresis when re-evaluating an active tracked target so boundaries never flicker
    if opts and IsSafeNum(opts.prevMapID) and IsSafeNum(opts.prevX) and IsSafeNum(opts.prevY) and best.distYards then
        local matchedPrev
        for _, c in ipairs(pool) do
            if c.mapID == opts.prevMapID
                and math.abs(c.x - opts.prevX) < 0.65
                and math.abs(c.y - opts.prevY) < 0.65
                and c.distYards then
                matchedPrev = c
                break
            end
        end
        if matchedPrev and matchedPrev ~= best then
            local pct = opts.hysteresisPct or 0.15
            local minYards = opts.hysteresisYards or 35
            local clearlyCloser = (best.distYards < matchedPrev.distYards * (1 - pct))
                and ((matchedPrev.distYards - best.distYards) >= minYards)
            if not clearlyCloser then
                best = matchedPrev
            end
        end
    end

    return best
end

local function ResolveContinentPOIToZone(qid, playerMapID, continentMapID, poiCache, metaCache, childrenCache, cx100, cy100, ctx)
    if not IsSafeNum(continentMapID) or continentMapID <= 0 then return nil, nil, nil end
    if not IsSafeNum(cx100) or not IsSafeNum(cy100) then
        local cPOIs = CollectMapPOIs(continentMapID, poiCache)
        if cPOIs[qid] then
            cx100, cy100 = cPOIs[qid].x, cPOIs[qid].y
        end
    end

    local candidates = {}

    -- 1. Evaluate all child zones with genuine POIs for this quest
    local children = GetZoneChildrenCached(continentMapID, childrenCache)
    if children then
        for _, child in ipairs(children) do
            if type(child) == "table" and IsSafeNum(child.mapID) then
                AddBucketEntriesForMap(candidates, qid, child.mapID, poiCache, 1, nil, child.mapID)
            end
        end
    end

    -- 2. Ask Blizzard which map lies under the continent coordinate (in case child POIs weren't populated yet)
    if IsSafeNum(cx100) and IsSafeNum(cy100) and C_Map and C_Map.GetMapInfoAtPosition then
        local hit = SafeCall(C_Map.GetMapInfoAtPosition, continentMapID, cx100 / 100, cy100 / 100)
        if type(hit) == "table" and IsSafeNum(hit.mapID) and hit.mapID > 0 and hit.mapID ~= continentMapID then
            local zoneID = hit.mapID
            local microType = (Enum and Enum.UIMapType and Enum.UIMapType.Micro) or 5
            if hit.mapType == microType and IsSafeNum(hit.parentMapID) and hit.parentMapID > 0 and hit.parentMapID ~= continentMapID then
                zoneID = hit.parentMapID
            end
            local found = AddBucketEntriesForMap(candidates, qid, zoneID, poiCache, 1, 3, zoneID)
            if found == 0 and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
                local nx, ny = SafeCall(C_QuestLog.GetNextWaypointForMap, qid, zoneID)
                if IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
                    AddDestCandidate(candidates, zoneID, nx * 100, ny * 100, 1, zoneID, false)
                    found = 1
                end
            end
            if found == 0 then
                local zx, zy = ConvertMapCoords100(continentMapID, zoneID, cx100, cy100)
                if zx and zy then
                    AddDestCandidate(candidates, zoneID, zx, zy, 2, zoneID, false)
                end
            end
        end
    end

    if #candidates > 0 then
        local refMapID = ctx and ctx.mapID or playerMapID
        local best = SelectBestDestCandidate(candidates, refMapID, ctx and ctx.px, ctx and ctx.py, playerMapID, nil, metaCache)
        if best then
            return best.mapID, best.x, best.y
        end
    end

    if IsSafeNum(cx100) and IsSafeNum(cy100) then
        return continentMapID, cx100, cy100
    end
    return nil, nil, nil
end

function FP:FindNearestRouteCoordFallback(questID, isReady, refMapID, refX100, refY100, coordFallback)
    if not IsSafeNum(questID) or questID <= 0 then return nil end
    local lookup = coordFallback or BuildRouteCoordFallback()
    local qEntry = lookup[questID]
    if not qEntry then return nil end

    local list = isReady and qEntry.TURNIN or qEntry.COMPLETE
    if not list or #list == 0 then return nil end

    local candidates = {}
    for _, step in ipairs(list) do
        local objDone = (not isReady) and step.objectiveIndex
            and self.IsObjectiveComplete and self:IsObjectiveComplete(questID, step.objectiveIndex)
        if not objDone then
            AddDestCandidate(candidates, step.mapID, step.x, step.y, 1, step.mapID, false)
        end
    end
    if #candidates == 0 and not isReady then
        for _, step in ipairs(list) do
            AddDestCandidate(candidates, step.mapID, step.x, step.y, 1, step.mapID, false)
        end
    end
    local best = SelectBestDestCandidate(candidates, refMapID, refX100, refY100, refMapID, nil, liveCache.meta)
    if best then
        return best.mapID, best.x, best.y
    end
    return nil
end

function FP:PickNearestMapPOI(questID, mapID, allowTransit, refMapID, refX100, refY100)
    if not IsSafeNum(questID) or not IsSafeNum(mapID) or mapID <= 0 then return nil, nil end
    if not IsSafeNum(refX100) or not IsSafeNum(refY100) then
        local ctx = GetPlayerZoneContext()
        refMapID = ctx.mapID or mapID
        refX100 = ctx.px
        refY100 = ctx.py
    end
    local candidates = {}
    AddBucketEntriesForMap(candidates, questID, mapID, {}, 1, allowTransit and 2 or nil, mapID)
    if #candidates == 0 then return nil, nil end
    local best = SelectBestDestCandidate(candidates, refMapID or mapID, refX100, refY100, mapID, mapID, liveCache.meta)
    if best then
        return best.x, best.y
    end
    return nil, nil
end

--- Resolves the nearest true destination (mapID, x100, y100, designatedMapID, isLocalTransit) for a Quest Log quest.
--- Compares all objective spots on the active map and sibling zones on the continent by world distance.
function FP:ResolveQuestDestination(qid, ctx, isReady, opts)
    if not IsSafeNum(qid) or qid <= 0 then return nil end
    ctx = ctx or GetPlayerZoneContext()
    opts = opts or {}

    -- Tier 0: Curated Hidden / Riddle Quest POI (Captain Sanders, Hilary's Necklace, Cortello, etc.)
    if not isReady and self.GetHiddenQuestData then
        local qTitle = (self.GetQuestTitleCompat and self:GetQuestTitleCompat(qid))
            or (FP.GetQuestTitleCompat and FP:GetQuestTitleCompat(qid))
        local hPoi = self:GetHiddenQuestData(qid, qTitle)
        if hPoi and IsSafeNum(hPoi.mapID) and IsSafeNum(hPoi.x) and IsSafeNum(hPoi.y) then
            return hPoi.mapID, hPoi.x, hPoi.y, hPoi.mapID, false
        end
    end

    local poiCache = opts.poiCache
    if not poiCache then
        if opts.livePoll then
            local now = (GetTime and GetTime()) or 0
            if (now - liveCache.poiStamp) > 2.0 then
                liveCache.poi = {}
                liveCache.poiStamp = now
            else
                if ctx.mapID then liveCache.poi[ctx.mapID] = nil end
                if opts.prevMapID then liveCache.poi[opts.prevMapID] = nil end
            end
            poiCache = liveCache.poi
        else
            poiCache = {}
        end
    end
    local metaCache = opts.metaCache or liveCache.meta
    local childrenCache = opts.childrenCache or liveCache.children
    local coordFallback = opts.coordFallback or BuildRouteCoordFallback()

    local playerMapID = opts.preferredMapID or ctx.mapID
    local parentMapID = ctx.parentMapID
    if opts.preferredMapID and opts.preferredMapID ~= ctx.mapID then
        local pInfo = GetMapInfoCached(opts.preferredMapID, metaCache)
        parentMapID = pInfo and pInfo.parentMapID or nil
    end
    local continentMapID = FindAncestorContinent(playerMapID, metaCache) or parentMapID
    local targetMapID = GetDesignatedQuestMapID(qid)
    local targetContinentID = targetMapID and FindAncestorContinent(targetMapID, metaCache) or nil

    local candidates = {}

    -- Tier 1: All genuine non-indicator POIs on player map (+ parent zone if in Micro subzone)
    local localGenuineCount = AddBucketEntriesForMap(candidates, qid, playerMapID, poiCache, 1, 3, targetMapID or playerMapID)
    if IsMicroOrSubzoneOf(playerMapID, parentMapID, metaCache) then
        localGenuineCount = localGenuineCount + AddBucketEntriesForMap(candidates, qid, parentMapID, poiCache, 1, 3, parentMapID)
    end

    -- Tier 1: All genuine non-indicator POIs on Blizzard's designated targetMapID
    if targetMapID and targetMapID ~= playerMapID and not IsContinentOrWorldMap(targetMapID, metaCache) then
        local tCount = AddBucketEntriesForMap(candidates, qid, targetMapID, poiCache, 1, nil, targetMapID)
        if tCount == 0 and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
            local nx, ny = SafeCall(C_QuestLog.GetNextWaypointForMap, qid, targetMapID)
            if IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
                AddDestCandidate(candidates, targetMapID, nx * 100, ny * 100, 1, targetMapID, false)
            end
        end
    end

    -- Tier 1: Scan all sibling zones on relevant continent(s) so multi-zone quests always pick closest zone
    local scannedConts = {}
    for _, contID in ipairs({ continentMapID, targetContinentID }) do
        if IsSafeNum(contID) and contID > 0 and not scannedConts[contID] then
            scannedConts[contID] = true
            local children = GetZoneChildrenCached(contID, childrenCache)
            if children then
                for _, child in ipairs(children) do
                    if type(child) == "table" and IsSafeNum(child.mapID) and child.mapID ~= playerMapID then
                        AddBucketEntriesForMap(candidates, qid, child.mapID, poiCache, 1, nil, child.mapID)
                    end
                end
            end
        end
    end
    if parentMapID and parentMapID ~= continentMapID and parentMapID ~= playerMapID
        and not IsContinentOrWorldMap(parentMapID, metaCache) then
        AddBucketEntriesForMap(candidates, qid, parentMapID, poiCache, 1, nil, parentMapID)
    end

    -- Tier 1/2: Global next waypoint (promote local waypoint to Tier 1 only when playerMapID already has genuine objectives)
    local localWpHold
    if C_QuestLog and C_QuestLog.GetNextWaypoint then
        local nm, nx, ny = SafeCall(C_QuestLog.GetNextWaypoint, qid)
        if IsSafeNum(nm) and IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
            if nm ~= playerMapID then
                if IsContinentOrWorldMap(nm, metaCache) then
                    local zm, zx, zy = ResolveContinentPOIToZone(qid, playerMapID, nm, poiCache, metaCache, childrenCache, nx * 100, ny * 100, ctx)
                    if zm and not IsContinentOrWorldMap(zm, metaCache) then
                        AddDestCandidate(candidates, zm, zx, zy, 1, zm, false)
                    elseif zm then
                        AddDestCandidate(candidates, zm, zx, zy, 3, targetMapID or zm, false)
                    end
                else
                    AddDestCandidate(candidates, nm, nx * 100, ny * 100, 1, nm, false)
                end
            elseif localGenuineCount > 0 then
                AddDestCandidate(candidates, nm, nx * 100, ny * 100, 1, targetMapID or nm, false)
            else
                localWpHold = { mapID = nm, x = nx * 100, y = ny * 100 }
            end
        end
    end

    -- Tier 1: Blizzard active Quest POI icon on the current POI map if valid & non-continent
    if QuestPOIGetIconInfo and C_QuestLog and C_QuestLog.GetMapForQuestPOIs then
        local poiMap = SafeCall(C_QuestLog.GetMapForQuestPOIs)
        if IsSafeNum(poiMap) and poiMap > 0 and not IsContinentOrWorldMap(poiMap, metaCache) then
            local completed, qpx, qpy = SafeCall(QuestPOIGetIconInfo, qid)
            if IsSafeNum(qpx) and IsSafeNum(qpy) and (qpx ~= 0 or qpy ~= 0)
                and (not isReady or completed) then
                local poiCont = FindAncestorContinent(poiMap, metaCache)
                if poiMap == playerMapID or poiMap == targetMapID or (continentMapID and poiCont == continentMapID) then
                    AddDestCandidate(candidates, poiMap, qpx * 100, qpy * 100, 1, targetMapID or poiMap, false)
                end
            end
        end
    end

    -- Tier 1.5: Curated Hidden / Riddle Quest POI (Captain Sanders, Cortello, Linken, etc.)
    local hPoi = self.GetHiddenQuestData and self:GetHiddenQuestData(qid)
    if hPoi and IsSafeNum(hPoi.mapID) and IsSafeNum(hPoi.x) and IsSafeNum(hPoi.y) then
        AddDestCandidate(candidates, hPoi.mapID, hPoi.x, hPoi.y, 1, hPoi.mapID, false)
    end

    -- Tier 2: Built-in / custom route step fallback & local waypoint hold & designated playerMapID
    local fbMap, fbX, fbY = self:FindNearestRouteCoordFallback(qid, isReady, ctx.mapID or playerMapID, ctx.px, ctx.py, coordFallback)
    if fbMap and fbX and fbY then
        AddDestCandidate(candidates, fbMap, fbX, fbY, 2, fbMap, false)
    end
    if localWpHold then
        AddDestCandidate(candidates, localWpHold.mapID, localWpHold.x, localWpHold.y, 2, targetMapID or localWpHold.mapID, false)
    end
    if targetMapID and targetMapID == playerMapID and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
        local nx, ny = SafeCall(C_QuestLog.GetNextWaypointForMap, qid, targetMapID)
        if IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
            AddDestCandidate(candidates, targetMapID, nx * 100, ny * 100, 2, targetMapID, false)
        end
    end

    -- Tier 3: Unresolved continent fallback & last-resort local indicator/transit waypoint
    if continentMapID then
        local cPOIs = CollectMapPOIs(continentMapID, poiCache)
        if cPOIs[qid] then
            AddDestCandidate(candidates, continentMapID, cPOIs[qid].x, cPOIs[qid].y, 3, targetMapID or continentMapID, false)
        end
    end
    if playerMapID and C_QuestLog and C_QuestLog.GetNextWaypointForMap then
        local nx, ny = SafeCall(C_QuestLog.GetNextWaypointForMap, qid, playerMapID)
        if IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
            AddDestCandidate(candidates, playerMapID, nx * 100, ny * 100, 3, targetMapID, true)
        end
    end

    local best = SelectBestDestCandidate(candidates, ctx.mapID, ctx.px, ctx.py, playerMapID, targetMapID, metaCache, opts)
    if best then
        local resolvedTarget = best.targetMapID
        if best.tier <= 2 and not IsContinentOrWorldMap(best.mapID, metaCache) then
            resolvedTarget = best.mapID
        end
        return best.mapID, best.x, best.y, resolvedTarget or targetMapID, best.isTransit
    end

    return nil, nil, nil, targetMapID, false
end

local function IsDungeonOrGroupQuest(questID, title, header, suggestedGroup)
    if suggestedGroup and suggestedGroup >= 2 then
        return true, false
    end

    if C_QuestLog and C_QuestLog.GetQuestTagInfo then
        local tagInfo = SafeCall(C_QuestLog.GetQuestTagInfo, questID)
        if type(tagInfo) == "table" then
            if Enum and Enum.QuestTag then
                if tagInfo.tagID == Enum.QuestTag.Dungeon or tagInfo.tagID == Enum.QuestTag.Raid
                    or tagInfo.tagID == Enum.QuestTag.Raid10 or tagInfo.tagID == Enum.QuestTag.Raid25 then
                    return true, true
                elseif tagInfo.tagID == Enum.QuestTag.Group or tagInfo.tagID == Enum.QuestTag.Elite then
                    return true, false
                end
            end
            if tagInfo.isElite then
                return true, false
            end
        end
    end

    local lowerTitle = (title or ""):lower()
    if lowerTitle:find("%(dungeon%)") or lowerTitle:find("%(spedizione%)")
        or lowerTitle:find("%(mazmorra%)") or lowerTitle:find("%(donjon%)")
        or lowerTitle:find("%(raid%)") then
        return true, true
    end
    if lowerTitle:find("%(group%)") or lowerTitle:find("%(gruppo%)") or lowerTitle:find("%(elite%)") then
        return true, false
    end

    local lowerHeader = (header or ""):lower()
    if lowerHeader:find("dungeon") or lowerHeader:find("deadmines") or lowerHeader:find("stockade")
        or lowerHeader:find("wailing caverns") or lowerHeader:find("shadowfang")
        or lowerHeader:find("gnomeregan") or lowerHeader:find("scarlet monastery")
        or lowerHeader:find("ragefire") or lowerHeader:find("blackfathom")
        or lowerHeader:find("drowned city") or lowerHeader:find("krol'dok") then
        return true, true
    end

    return false, false
end

local function ZoneNamesMatch(a, b)
    if not a or not b or a == "" or b == "" then return false end
    local la, lb = a:lower(), b:lower()
    if la == lb then return true end
    if #la >= 4 and #lb >= 4 and (la:find(lb, 1, true) or lb:find(la, 1, true)) then
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Scan Quest Log & Build Prioritized Dynamic Route
------------------------------------------------------------------------
function FP:RebuildQuestSyncRoute()
    local L = self.L or {}
    local ctx = GetPlayerZoneContext()
    local playerLevel = self:GetPlayerLevel()
    local coordFallback = BuildRouteCoordFallback()
    local poiCache = {}
    liveCache.poi = poiCache
    liveCache.poiStamp = (GetTime and GetTime()) or 0
    local metaCache = liveCache.meta
    local childrenCache = liveCache.children
    local mapNameCache = {}
    local resolveOpts = {
        poiCache      = poiCache,
        metaCache     = metaCache,
        childrenCache = childrenCache,
        coordFallback = coordFallback,
    }

    -- Collect POI coordinates on current map
    local onMapPOIs = CollectMapPOIs(ctx.mapID, poiCache)
    local zoneHasPOIs = (next(onMapPOIs) ~= nil)

    -- Collect quests from Quest Log
    local rawQuests = {}
    local currentHeader = ""

    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local count = SafeCall(C_QuestLog.GetNumQuestLogEntries) or 0
        for i = 1, count do
            local info = SafeCall(C_QuestLog.GetInfo, i)
            if type(info) == "table" then
                if info.isHeader then
                    currentHeader = (type(info.title) == "string" and not IsSecret(info.title) and info.title) or ""
                elseif IsSafeNum(info.questID) and info.questID > 0 and not info.isHidden then
                    local isOnMap = info.isOnMap == true
                    local hasLocalPOI = info.hasLocalPOI == true
                    if isOnMap or hasLocalPOI then
                        zoneHasPOIs = true
                    end
                    rawQuests[#rawQuests + 1] = {
                        questID        = info.questID,
                        title          = (type(info.title) == "string" and not IsSecret(info.title) and info.title) or ("Quest " .. info.questID),
                        level          = info.level or playerLevel,
                        suggestedGroup = info.suggestedGroup or 0,
                        isOnMap        = isOnMap,
                        hasLocalPOI    = hasLocalPOI,
                        readyForTurnIn = info.readyForTurnIn == true,
                        header         = currentHeader,
                    }
                end
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        local count = GetNumQuestLogEntries() or 0
        for i = 1, count do
            local title, level, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
            if isHeader then
                currentHeader = title or ""
            elseif questID and questID > 0 then
                rawQuests[#rawQuests + 1] = {
                    questID        = questID,
                    title          = title or ("Quest " .. questID),
                    level          = level or playerLevel,
                    suggestedGroup = 0,
                    isOnMap        = false,
                    hasLocalPOI    = false,
                    readyForTurnIn = (isComplete == 1 or isComplete == true),
                    header         = currentHeader,
                }
            end
        end
    end

    -- Score and enrich each quest
    local enriched = {}
    for _, q in ipairs(rawQuests) do
        local qid = q.questID
        local objTotal, objDone, firstPending, objLines = self:GetQuestObjectivesSummary(qid)
        local isReady = self:IsQuestReadyForTurnIn(qid, q.readyForTurnIn)

        -- Determine true destination zone/coords without confusing current-zone transit/accept nodes
        local wMapID, wx, wy, targetMapID, isTransitFallback = self:ResolveQuestDestination(qid, ctx, isReady, resolveOpts)
        local knownMapID = (wMapID and not IsContinentOrWorldMap(wMapID, metaCache)) and wMapID
            or (targetMapID and not IsContinentOrWorldMap(targetMapID, metaCache) and targetMapID)
            or wMapID or targetMapID

        local hasGenuineLocalPOI = (onMapPOIs[qid] ~= nil and not onMapPOIs[qid].isIndicator)
        local inZone
        if knownMapID ~= nil and ctx.mapID ~= nil and not IsContinentOrWorldMap(knownMapID, metaCache) then
            if knownMapID == ctx.mapID or IsMicroOrSubzoneOf(knownMapID, ctx.mapID, metaCache) then
                inZone = not isTransitFallback or hasGenuineLocalPOI or q.hasLocalPOI
            else
                inZone = false
            end
        elseif hasGenuineLocalPOI or q.hasLocalPOI or (q.isOnMap and not isTransitFallback) then
            inZone = true
        elseif isReady and zoneHasPOIs then
            inZone = false
        else
            inZone = ZoneNamesMatch(q.header, ctx.zoneName)
                or ZoneNamesMatch(q.header, ctx.realZone)
        end

        local isGroupOrDungeon, isDungeon = IsDungeonOrGroupQuest(qid, q.title, q.header, q.suggestedGroup)

        -- Distance estimate (same-map or cross-zone world distance)
        local dist100 = nil
        if wMapID and ctx.mapID and wMapID == ctx.mapID and ctx.px and ctx.py and wx and wy then
            local dx = wx - ctx.px
            local dy = wy - ctx.py
            dist100 = math.sqrt(dx * dx + dy * dy)
        elseif wMapID and ctx.mapID and ctx.px and ctx.py and wx and wy then
            local yards = self:ComputeWorldDistanceYards(ctx.mapID, ctx.px, ctx.py, wMapID, wx, wy, metaCache)
            if yards then
                dist100 = math.min(150, yards / 30)
            end
        elseif C_QuestLog and C_QuestLog.GetDistanceSqToQuest then
            local distSq, onCont = SafeCall(C_QuestLog.GetDistanceSqToQuest, qid)
            if IsSafeNum(distSq) and onCont then
                dist100 = math.min(150, math.sqrt(distSq) / 25)
            end
        end

        local isWatched = false
        if C_QuestLog and C_QuestLog.GetQuestWatchType then
            isWatched = (SafeCall(C_QuestLog.GetQuestWatchType, qid) ~= nil)
        end

        local settings = (NexusKitDB and NexusKitDB.settings) or {}
        local deprioritizeDungeons = (settings.syncDeprioritizeDungeons ~= false)
        local preferWatched = (settings.syncPreferWatched ~= false)

        -- Priority score (lower = do first)
        local score
        if self.skippedSyncQuests[qid] then
            score = 9000
        elseif isGroupOrDungeon and deprioritizeDungeons then
            if isReady and inZone then
                score = 4700
            elseif isReady then
                score = 4850
            elseif inZone then
                score = 5000
            else
                score = 5500
            end
        elseif isReady and inZone then
            score = 0
        elseif inZone then
            score = 1000
        elseif isReady then
            score = 2000
        else
            score = 3000
        end

        -- Sub-ordering inside tier
        score = score + math.min(400, (dist100 or 120) * 3)

        local diff = (q.level or playerLevel) - playerLevel
        if diff >= 3 then
            score = score + 250 + diff * 25 -- high/red quests later
        elseif diff <= -6 then
            score = score + 90 -- gray quests slightly after optimal green/yellow
        else
            score = score + math.max(0, q.level or playerLevel) * 2
        end

        local ratio = (objTotal > 0) and (objDone / objTotal) or (isReady and 1 or 0)
        score = score - math.floor(ratio * 80)

        if isWatched and preferWatched then
            score = score - 15
        end
        if not self.skippedSyncQuests[qid] and self.selectedQuestID and self.selectedQuestID == qid then
            score = score - 6000
        end

        -- Resolve display zone name (prefer destination zone map name when known for cross-zone turn-ins)
        local knownZoneName = knownMapID and GetMapDisplayName(knownMapID, mapNameCache, metaCache) or nil
        local displayHeader = (knownZoneName and knownZoneName ~= "") and knownZoneName or q.header

        -- Format user-facing label
        local tag
        if isReady then
            tag = L["SYNC_TAG_READY"] or "[Turn In]"
        elseif isDungeon then
            tag = L["SYNC_TAG_DUNGEON"] or "[Dungeon]"
        elseif isGroupOrDungeon then
            tag = L["SYNC_TAG_GROUP"] or "[Group]"
        elseif inZone then
            tag = L["SYNC_TAG_ZONE"] or "[Zone]"
        elseif displayHeader and displayHeader ~= "" then
            tag = "[" .. displayHeader .. "]"
        else
            tag = ""
        end

        local cleanTitle = q.title:gsub("^%[%d+[%+%*]?%]%s*", "")
        local stepText = string.format("%s [%d] %s", tag, q.level or playerLevel, cleanTitle)
        if not isReady and firstPending and firstPending ~= "" then
            stepText = stepText .. " - " .. firstPending
        elseif not isReady and displayHeader and displayHeader ~= "" and inZone == false then
            -- already has destination/header in tag if outside zone
        elseif isReady and displayHeader and displayHeader ~= "" then
            stepText = stepText .. " (" .. displayHeader .. ")"
        end

        enriched[#enriched + 1] = {
            id             = 900000 + qid,
            action         = isReady and "TURNIN" or "COMPLETE",
            text           = stepText,
            questTitle     = cleanTitle,
            mapID          = wMapID,
            targetMapID    = knownMapID,
            x              = wx,
            y              = wy,
            questId        = qid,
            questLevel     = q.level,
            questHeader    = q.header,
            objectivesList = objLines,
            inCurrentZone  = inZone,
            isDungeon      = isGroupOrDungeon,
            isReady        = isReady,
            score          = score,
        }
    end

    if self.BuildDynamicTrainStep then
        local trainStep = self:BuildDynamicTrainStep(ctx, liveCache and liveCache.meta)
        if trainStep then
            enriched[#enriched + 1] = trainStep
        end
    end

    table.sort(enriched, function(a, b)
        if a.score ~= b.score then
            return a.score < b.score
        end
        return (a.questId or 0) < (b.questId or 0)
    end)

    local route = self.routes[self.QUEST_SYNC_ROUTE_ID] or {
        routeId  = self.QUEST_SYNC_ROUTE_ID,
        faction  = "Both",
        minLevel = 1,
        maxLevel = 60,
        steps    = {},
    }
    route.title = L["SYNC_ROUTE_TITLE"] or "Quest Log Sync (Zone)"
    route.steps = enriched
    self.routes[self.QUEST_SYNC_ROUTE_ID] = route

    return route
end

------------------------------------------------------------------------
-- Toggle / Activate / Refresh Quest Sync mode
------------------------------------------------------------------------
function FP:IsQuestSyncActive()
    return self.activeRoute ~= nil and self.activeRoute.routeId == self.QUEST_SYNC_ROUTE_ID
end

function FP:EnableQuestSync()
    if self.skippedSyncQuests then
        for k in pairs(self.skippedSyncQuests) do
            self.skippedSyncQuests[k] = nil
        end
    end

    if self.activeRoute and self.activeRoute.routeId ~= self.QUEST_SYNC_ROUTE_ID then
        if NexusKitCharDB then
            NexusKitCharDB.previousRouteId = self.activeRoute.routeId
        end
    end

    local route = self:RebuildQuestSyncRoute()
    self:SetActiveRoute(self.QUEST_SYNC_ROUTE_ID)

    local count = (route and route.steps) and #route.steps or 0
    if count > 0 then
        self:Print(string.format(self.L["SYNC_ACTIVATED"] or "Quest Log Sync enabled (%d quests prioritized).", count))
    else
        self:Print(self.L["SYNC_NO_QUESTS"] or "No active quests in your Quest Log.")
    end
end

function FP:ToggleQuestSync()
    if self:IsQuestSyncActive() then
        local prev = NexusKitCharDB and NexusKitCharDB.previousRouteId
        if prev and prev ~= self.QUEST_SYNC_ROUTE_ID and self.routes[prev] then
            self:SetActiveRoute(prev)
        else
            local faction = self:GetPlayerFaction()
            if faction == "Alliance" and self.routes["ALLIANCE_1_20_OPTIMAL"] then
                self:SetActiveRoute("ALLIANCE_1_20_OPTIMAL")
            elseif faction == "Horde" and self.routes["HORDE_1_20_OPTIMAL"] then
                self:SetActiveRoute("HORDE_1_20_OPTIMAL")
            else
                self:SetActiveRoute(false)
            end
        end
    else
        self:EnableQuestSync()
    end
end
