local addonName, FP = ...

-------------------------------------------------------------------------------
-- Waypoints.lua – Directional arrow + map pin system for NexusKit
-------------------------------------------------------------------------------

local atan2 = math.atan2 or math.atan
local TWO_PI = 2 * math.pi

-- State (target coordinates stored normalized in [0, 1])
local waypointMapID, waypointX, waypointY, waypointTitle
local waypointAction, waypointQuestID
local proxState = { allow = false, accum = 0, lastAt = 0, qid = nil, mapID = nil, x = nil, y = nil }
local isInternalWaypointSync = false
local lastRouteStepIndex = nil
local UPDATE_INTERVAL = 0.033 -- ~30 FPS
local elapsed_accum = 0
local lastSyncTrigger = 0

local function GetNavSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsPlayerInDungeon()
    if not IsInInstance then return false end
    local ok, inInst, instType = pcall(IsInInstance)
    if not ok or not inInst then return false end
    return instType ~= nil and instType ~= "none"
end

local function IsTrajectoriesEnabled()
    return (GetNavSettings().showTrajectories ~= false) and not IsPlayerInDungeon()
end

local function IsMapPinsEnabled()
    local s = GetNavSettings()
    return s.enableHighlights ~= false and s.enableMapPins ~= false
end

local function IsMinimapTrajectoriesEnabled()
    return (GetNavSettings().showMinimapTrajectories ~= false) and not IsPlayerInDungeon()
end

local function IsMinimapPinEnabled()
    local s = GetNavSettings()
    return (s.showMinimapPin == true or s.showMinimapTrajectories ~= false) and not IsPlayerInDungeon()
end

local function IsCrossZoneProjEnabled()
    return GetNavSettings().crossZoneProjection ~= false
end

local function ShouldHideArrow()
    if IsPlayerInDungeon() then
        return true
    end
    return GetNavSettings().arrowHideInCombat == true
        and UnitAffectingCombat and UnitAffectingCombat("player") == true
end

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function GetPlayerPosNorm()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then
        return nil, nil, nil
    end
    local pMapID = C_Map.GetBestMapForUnit("player")
    if not IsSafeNum(pMapID) or pMapID <= 0 then
        return nil, nil, nil
    end
    local pos = C_Map.GetPlayerMapPosition(pMapID, "player")
    if pos and pos.GetXY then
        local px, py = pos:GetXY()
        if IsSafeNum(px) and IsSafeNum(py) and (px ~= 0 or py ~= 0) then
            return pMapID, px, py
        end
    end
    return pMapID, nil, nil
end

local function FindRouteCoordFallback(questID, isReady)
    if not questID then return nil end
    if FP.FindNearestRouteCoordFallback then
        local pMapID, px, py = GetPlayerPosNorm()
        local fm, fx, fy = FP:FindNearestRouteCoordFallback(questID, isReady, pMapID, px and (px * 100), py and (py * 100))
        if fm and fx and fy then
            return fm, fx / 100, fy / 100, isReady and "TURNIN" or "COMPLETE"
        end
    end
    if not FP.routes then return nil end
    local completeHit
    for routeId, route in pairs(FP.routes) do
        if routeId ~= FP.QUEST_SYNC_ROUTE_ID and route.steps then
            for _, s in ipairs(route.steps) do
                if s.questId == questID and s.mapID and s.x and s.y then
                    if isReady and s.action == "TURNIN" then
                        return s.mapID, s.x / 100, s.y / 100, s.action
                    elseif s.action == "COMPLETE" then
                        completeHit = completeHit or { s.mapID, s.x / 100, s.y / 100, s.action }
                    end
                end
            end
        end
    end
    if not isReady and completeHit then
        return completeHit[1], completeHit[2], completeHit[3], completeHit[4]
    end
    return nil
end

local mapNameCache = {}
local function GetCachedMapName(mapID)
    if not IsSafeNum(mapID) or mapID <= 0 then return nil end
    if mapNameCache[mapID] ~= nil then
        return mapNameCache[mapID] ~= false and mapNameCache[mapID] or nil
    end
    local name = false
    if C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if ok and type(info) == "table" and type(info.name) == "string"
            and (not issecretvalue or not issecretvalue(info.name)) and info.name ~= "" then
            name = info.name
        end
    end
    mapNameCache[mapID] = name
    return name ~= false and name or nil
end

local staticPVec = (CreateVector2D and CreateVector2D(0.5, 0.5)) or { x = 0.5, y = 0.5 }
local staticTVec = (CreateVector2D and CreateVector2D(0, 0)) or { x = 0, y = 0 }

local function ProjectTargetToPlayerMap(playerMapID, targetMapID, targetX, targetY)
    if not C_Map or not IsSafeNum(playerMapID) or not IsSafeNum(targetMapID)
        or not IsSafeNum(targetX) or not IsSafeNum(targetY) then
        return nil, nil
    end
    if C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos then
        if staticTVec.SetXY then
            staticTVec:SetXY(targetX, targetY)
        else
            staticTVec.x = targetX
            staticTVec.y = targetY
        end
        local okP, pCont = pcall(C_Map.GetWorldPosFromMapPos, playerMapID, staticPVec)
        local okT, tCont, tWorld = pcall(C_Map.GetWorldPosFromMapPos, targetMapID, staticTVec)
        if okP and okT and pCont and tCont and tWorld and pCont == tCont then
            local okProj, _, mapPos = pcall(C_Map.GetMapPosFromWorldPos, tCont, tWorld, playerMapID)
            if okProj and mapPos and mapPos.GetXY then
                local projX, projY = mapPos:GetXY()
                if IsSafeNum(projX) and IsSafeNum(projY) then
                    return projX, projY
                end
            end
        end
    end
    -- Fallback for zone-to-continent projection when GetWorldPosFromMapPos rejects continent center
    if C_Map.GetMapRectOnMap then
        local okR, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, targetMapID, playerMapID)
        if okR and IsSafeNum(minX) and IsSafeNum(maxX) and IsSafeNum(minY) and IsSafeNum(maxY)
            and maxX > minX and maxY > minY and not (minX == 0 and maxX == 0) then
            return minX + (maxX - minX) * targetX, minY + (maxY - minY) * targetY
        end
    end
    return nil, nil
end

local function IsQuestReadyCompat(questID)
    if not questID then return false end
    if FP.IsQuestReadyForTurnIn then
        return FP:IsQuestReadyForTurnIn(questID)
    end
    if C_QuestLog then
        if C_QuestLog.ReadyForTurnIn then
            local ok, r = pcall(C_QuestLog.ReadyForTurnIn, questID)
            if ok and r then return true end
        elseif C_QuestLog.IsComplete then
            local ok, r = pcall(C_QuestLog.IsComplete, questID)
            if ok and r then return true end
        end
    end
    return false
end

local function GetQuestTitleCompat(questID)
    if not questID then return nil end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and type(title) == "string" and (not issecretvalue or not issecretvalue(title)) and title ~= "" then
            return title
        end
    end
    if GetQuestLogIndexByID and GetQuestLogTitle then
        local idx = GetQuestLogIndexByID(questID)
        if idx and idx > 0 then
            local title = GetQuestLogTitle(idx)
            if type(title) == "string" and title ~= "" then
                return title
            end
        end
    end
    return nil
end

local function StripWaypointTags(text)
    if type(text) ~= "string" then return "" end
    local s = text
    while true do
        local stripped = s:gsub("^%b[]%s*", "")
        if stripped == s then break end
        s = stripped
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ResolveStepWaypointTitle(step, fallbackTitle)
    if step and type(step.pinTitle) == "string" and step.pinTitle ~= "" then
        return step.pinTitle
    end
    if step and type(step.questTitle) == "string" and step.questTitle ~= "" then
        return (step.questTitle:gsub("^%[%d+[%+%*]?%]%s*", ""))
    end
    if step and step.questId and step.questId > 0 then
        local qTitle = GetQuestTitleCompat(step.questId)
        if qTitle and qTitle ~= "" then
            return (qTitle:gsub("^%[%d+[%+%*]?%]%s*", ""))
        end
    end
    if fallbackTitle and fallbackTitle ~= "" then
        local clean = StripWaypointTags(fallbackTitle)
        if clean ~= "" then return clean end
    end
    if step and step.text and step.text ~= "" then
        local clean = StripWaypointTags(step.text)
        return (clean ~= "" and clean) or step.text
    end
    return ""
end

local function ResolveQuestCoordsOnMap(questID, mapID, allowTransit)
    if not questID or not IsSafeNum(mapID) or not C_QuestLog then return nil, nil end
    if FP.PickNearestMapPOI then
        local pMapID, px, py = GetPlayerPosNorm()
        local nx100, ny100 = FP:PickNearestMapPOI(questID, mapID, allowTransit, pMapID, px and (px * 100), py and (py * 100))
        if nx100 and ny100 then
            return nx100 / 100, ny100 / 100
        end
    elseif C_QuestLog.GetQuestsOnMap then
        local ok, list = pcall(C_QuestLog.GetQuestsOnMap, mapID)
        if ok and type(list) == "table" then
            local fallbackX, fallbackY
            for _, info in ipairs(list) do
                if info and info.questID == questID and IsSafeNum(info.x) and IsSafeNum(info.y)
                    and (info.x ~= 0 or info.y ~= 0) then
                    if info.isMapIndicatorQuest ~= true then
                        return info.x, info.y
                    elseif not fallbackX then
                        fallbackX, fallbackY = info.x, info.y
                    end
                end
            end
            if fallbackX and allowTransit then
                return fallbackX, fallbackY
            end
        end
    end
    if C_QuestLog.GetNextWaypoint then
        local ok, nm, nx, ny = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and nm == mapID and IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
            return nx, ny
        end
    end
    if C_QuestLog.GetNextWaypointForMap then
        local designatedMapID
        if GetQuestUiMapID then
            local qOk, qm = pcall(GetQuestUiMapID, questID, true)
            if qOk and IsSafeNum(qm) and qm > 0 then
                designatedMapID = qm
            end
        end
        if allowTransit or designatedMapID == mapID then
            local ok, nx, ny = pcall(C_QuestLog.GetNextWaypointForMap, questID, mapID)
            if ok and IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
                return nx, ny
            end
        end
    end
    return nil, nil
end

local function ResolveQuestTargetByID(questID, preferredMapID)
    if not questID or questID <= 0 then return nil end
    local isReady = IsQuestReadyCompat(questID)
    local rawTitle = GetQuestTitleCompat(questID)
    local title = (rawTitle and rawTitle ~= "" and rawTitle:gsub("^%[%d+[%+%*]?%]%s*", "")) or ("Quest " .. tostring(questID))
    local action = isReady and "TURNIN" or "COMPLETE"

    -- Curated Hidden / Riddle Quest POI (Hilary's Necklace, Captain Sanders, Cortello, etc.) - TIER 0 Priority
    if not isReady and FP.GetHiddenQuestData then
        local hData = FP:GetHiddenQuestData(questID, rawTitle)
        if hData and IsSafeNum(hData.mapID) and IsSafeNum(hData.x) and IsSafeNum(hData.y) then
            return hData.mapID, hData.x / 100, hData.y / 100, (hData.title or title), action, isReady
        end
    end

    if FP.ResolveQuestDestination then
        local wMapID, wx, wy = FP:ResolveQuestDestination(questID, nil, isReady, { preferredMapID = preferredMapID })
        if wMapID and wx and wy then
            return wMapID, wx / 100, wy / 100, title, action, isReady
        end
    end

    if GetQuestUiMapID then
        local ok, qm = pcall(GetQuestUiMapID, questID, true)
        if not (ok and IsSafeNum(qm) and qm > 0) then
            ok, qm = pcall(GetQuestUiMapID, questID)
        end
        if ok and IsSafeNum(qm) and qm > 0 then
            local nx, ny = ResolveQuestCoordsOnMap(questID, qm, true)
            if nx and ny then
                return qm, nx, ny, title, action, isReady
            end
        end
    end

    local checkMap = preferredMapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if IsSafeNum(checkMap) then
        local nx, ny = ResolveQuestCoordsOnMap(questID, checkMap, false)
        if nx and ny then
            return checkMap, nx, ny, title, action, isReady
        end
    end

    if C_QuestLog and C_QuestLog.GetNextWaypoint then
        local ok, nm, nx, ny = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and IsSafeNum(nm) and IsSafeNum(nx) and IsSafeNum(ny) and (nx ~= 0 or ny ~= 0) then
            return nm, nx, ny, title, action, isReady
        end
    end

    if IsSafeNum(checkMap) and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, checkMap)
        local parentMapID = ok and type(info) == "table" and info.parentMapID or nil
        if IsSafeNum(parentMapID) and parentMapID > 0 then
            local nx, ny = ResolveQuestCoordsOnMap(questID, parentMapID, false)
            if nx and ny then
                return parentMapID, nx, ny, title, action, isReady
            end
        end
    end

    local fm, fx, fy, fa = FindRouteCoordFallback(questID, isReady)
    if fm and fx and fy then
        return fm, fx, fy, title, fa or action, isReady
    end

    return nil, nil, nil, title, action, isReady
end

-- Conversion factor: map-normalised distance [0,1] -> approximate yards
local YARDS_PER_UNIT = 4167

-------------------------------------------------------------------------------
-- Arrow, Custom Waypoint HUD & Real-time Coordinates Frames
-------------------------------------------------------------------------------
local ARROW_BOX_WIDTH          = 340
local ARROW_BOX_HEIGHT_FULL    = 122
local ARROW_BOX_HEIGHT_COMPACT = 54
local CUSTOM_COLOR_R, CUSTOM_COLOR_G, CUSTOM_COLOR_B = 1.0, 0.28, 0.96

local customWp = { mapID = nil, x = nil, y = nil, title = nil }

local function ApplyOutlineFont(fs, minSize)
    if not fs or not fs.GetFont or not fs.SetFont then return end
    local fName, fSize = fs:GetFont()
    if fName then
        fs:SetFont(fName, math.max(minSize or 11, fSize or minSize or 11), "OUTLINE")
    end
    if fs.SetShadowOffset then
        fs:SetShadowOffset(1, -1)
    end
    if fs.SetShadowColor then
        fs:SetShadowColor(0, 0, 0, 0.95)
    end
end

local function IsPlayerCoordsEnabled()
    return not (NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.showPlayerCoords == false)
end

local function IsArrowLocked()
    return NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.arrowLocked == true
end

local function SetHudHoverVisual(frame, hovering, isCustom)
    if not frame then return end
    -- Always keep HUD frames on a transparent background (no dark box);
    -- show only a light outline when hovering an unlocked frame for dragging.
    frame:SetBackdropColor(0, 0, 0, 0)
    if hovering and not IsArrowLocked() then
        if isCustom then
            frame:SetBackdropBorderColor(1.0, 0.35, 1.0, 0.45)
        else
            local r, g, b = FP:GetAccentColor()
            frame:SetBackdropBorderColor(r, g, b, 0.40)
        end
    else
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

local function SaveHudPosition(frame, dbKey)
    if not (frame and NexusKitDB and NexusKitDB.settings) then return end
    local ux, uy = UIParent:GetCenter()
    local fx, fy = frame:GetCenter()
    if ux and uy and fx and fy then
        local s = frame:GetScale() or 1
        NexusKitDB.settings[dbKey] = {
            x = fx * s - ux,
            y = fy * s - uy,
        }
    end
end

local function ApplyHudPosition(frame, dbKey, defPoint, defRelPoint, defX, defY)
    if not frame then return end
    local pos = NexusKitDB and NexusKitDB.settings and NexusKitDB.settings[dbKey]
    if pos and type(pos.x) == "number" and type(pos.y) == "number" then
        local s = frame:GetScale() or 1
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", pos.x / s, pos.y / s)
    elseif defPoint then
        frame:ClearAllPoints()
        frame:SetPoint(defPoint, UIParent, defRelPoint or defPoint, defX or 0, defY or 0)
    end
end

local arrowLockButtons = {}
local arrow, customArrow, coordsFrame

local function AttachArrowLockButton(parentFrame)
    local btn = CreateFrame("Button", nil, parentFrame)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -4, -4)
    btn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")

    btn:SetScript("OnClick", function(self)
        if not (NexusKitDB and NexusKitDB.settings) then return end
        NexusKitDB.settings.arrowLocked = not IsArrowLocked()
        FP:RefreshArrowLockVisual()
        if GameTooltip and GameTooltip:IsOwned(self) then
            local L = FP.L or {}
            local r, g, b = FP:GetAccentColor()
            GameTooltip:SetText(L["TRACKER_TITLE"] or "NexusKit", r, g, b)
            if IsArrowLocked() then
                GameTooltip:AddLine(L["ARROW_UNLOCK_TOOLTIP"] or "Locked: click to unlock and move indicator.", 1, 1, 1, true)
            else
                GameTooltip:AddLine(L["ARROW_LOCK_TOOLTIP"] or "Unlocked: drag to move. Click lock to fix position.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        if GameTooltip then
            local L = FP.L or {}
            local r, g, b = FP:GetAccentColor()
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(L["TRACKER_TITLE"] or "NexusKit", r, g, b)
            if IsArrowLocked() then
                GameTooltip:AddLine(L["ARROW_UNLOCK_TOOLTIP"] or "Locked: click to unlock and move indicator.", 1, 1, 1, true)
            else
                GameTooltip:AddLine(L["ARROW_LOCK_TOOLTIP"] or "Unlocked: drag to move. Click lock to fix position.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetAlpha(IsArrowLocked() and 0.35 or 0.95)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    arrowLockButtons[#arrowLockButtons + 1] = btn
    return btn
end

local function CreateDirectionalArrowHUD(frameName, defX, defY, dbKey, isCustom)
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(ARROW_BOX_WIDTH, ARROW_BOX_HEIGHT_FULL)
    frame:SetPoint("CENTER", UIParent, "CENTER", defX, defY)
    if frame.SetDontSavePosition then
        frame:SetDontSavePosition(true)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame.isCustom = isCustom
    frame.dbKey = dbKey
    frame.defX = defX
    frame.defY = defY

    SetHudHoverVisual(frame, false, isCustom)
    frame.lockBtn = AttachArrowLockButton(frame)

    if isCustom then
        local closeBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        closeBtn:SetSize(18, 18)
        closeBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
        closeBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        closeBtn:SetBackdropColor(0.14, 0.04, 0.18, 0.85)
        closeBtn:SetBackdropBorderColor(0.95, 0.30, 0.95, 0.85)
        local xLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        xLbl:SetPoint("CENTER", 0, 1)
        xLbl:SetText("x")
        xLbl:SetTextColor(1, 0.65, 1, 1)
        closeBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.45, 0.10, 0.25, 0.95)
            xLbl:SetTextColor(1, 1, 1, 1)
            if GameTooltip then
                local L = FP.L or {}
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetText(L["CUSTOM_WAYPOINT_TAG"] or "Custom Waypoint", 1, 0.35, 1)
                GameTooltip:AddLine(L["CUSTOM_ARROW_TOOLTIP"] or "Right-click or /nk clear to remove this waypoint.", 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        closeBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.14, 0.04, 0.18, 0.85)
            xLbl:SetTextColor(1, 0.65, 1, 1)
            if GameTooltip then GameTooltip:Hide() end
        end)
        closeBtn:SetScript("OnClick", function()
            if FP.ClearCustomWaypoint then FP:ClearCustomWaypoint() end
        end)
        frame.closeBtn = closeBtn

        local badge = frame:CreateTexture(nil, "OVERLAY")
        badge:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_3")
        badge:SetSize(13, 13)
        badge:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -5)
        frame.badgeIcon = badge
    end

    frame:SetScript("OnDragStart", function(self)
        if not IsArrowLocked() then
            self.isDragging = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isDragging = false
        self.suppressClickUntil = (GetTime and GetTime() or 0) + 0.2
        SaveHudPosition(self, self.dbKey)
        ApplyHudPosition(self, self.dbKey, "CENTER", "CENTER", self.defX, self.defY)
    end)
    frame:SetScript("OnEnter", function(self)
        SetHudHoverVisual(self, true, self.isCustom)
        if GameTooltip and FP.L then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            if self.isCustom then
                GameTooltip:SetText((FP.L["CUSTOM_WAYPOINT_TAG"] or "Custom Waypoint"), 1, 0.35, 1)
                if customWp.title and customWp.title ~= "" then
                    GameTooltip:AddLine(customWp.title, 1, 1, 1, true)
                end
                GameTooltip:AddLine(FP.L["CUSTOM_ARROW_TOOLTIP"] or "Left-click: open map | Right-click or /nk clear: remove | Drag when unlocked.", 0.9, 0.85, 1, true)
            else
                local r, g, b = FP:GetAccentColor()
                GameTooltip:SetText(FP.L["TRACKER_TITLE"] or "NexusKit", r, g, b)
                GameTooltip:AddLine(FP.L["ARROW_TOOLTIP"] or "Click to refresh map waypoint. Drag to move.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        SetHudHoverVisual(self, false, self.isCustom)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    local glow = frame:CreateTexture(nil, "BORDER")
    glow:SetTexture("Interface\\AddOns\\" .. (addonName or "NexKit") .. "\\Media\\ArrowGlow.tga")
    glow:SetBlendMode("ADD")
    glow:SetSize(86, 86)
    glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    glow:SetAlpha(0.22)
    frame.arrowGlow = glow

    local tex = frame:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\AddOns\\" .. (addonName or "NexKit") .. "\\Media\\Arrow.tga")
    tex:SetSize(74, 74)
    tex:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.arrowTex = tex

    local titleFs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyOutlineFont(titleFs, 12)
    titleFs:SetPoint("TOP", frame, "TOP", isCustom and 2 or 0, -4)
    if isCustom then
        titleFs:SetTextColor(1, 0.38, 1, 1)
        titleFs:SetWidth(ARROW_BOX_WIDTH - 86)
    else
        local hr, hg, hb = FP:GetHudTextColor()
        titleFs:SetTextColor(hr, hg, hb, 1)
        titleFs:SetWidth(ARROW_BOX_WIDTH - 66)
    end
    titleFs:SetWordWrap(false)
    frame.titleText = titleFs

    local distFs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyOutlineFont(distFs, 12)
    distFs:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
    distFs:SetTextColor(1, 1, 1, 1)
    frame.distText = distFs

    local zoneFs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyOutlineFont(zoneFs, 11)
    zoneFs:SetPoint("TOP", titleFs, "BOTTOM", 0, -6)
    zoneFs:SetTextColor(0.95, 0.80, 0.2, 1)
    frame.zoneText = zoneFs

    frame:Hide()
    return frame
end

arrow = CreateDirectionalArrowHUD("NexusKitArrowFrame", 0, 200, "arrowPos", false)
customArrow = CreateDirectionalArrowHUD("NexusKitCustomArrowFrame", -360, 200, "customArrowPos", true)

local arrowTexture = arrow.arrowTex
local titleText    = arrow.titleText
local distText     = arrow.distText
local zoneText     = arrow.zoneText

local function ApplyArrowPosition()
    ApplyHudPosition(arrow, "arrowPos", "CENTER", "CENTER", 0, 200)
end

local function ApplyCustomArrowPosition()
    ApplyHudPosition(customArrow, "customArrowPos", "CENTER", "CENTER", -270, 200)
end

function FP:RefreshArrowLockVisual()
    local locked = IsArrowLocked()
    arrow:EnableMouse(not locked)
    customArrow:EnableMouse(not locked)
    for _, btn in ipairs(arrowLockButtons) do
        if locked then
            btn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
            btn:SetAlpha(0.35)
        else
            btn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
            btn:SetAlpha(0.95)
        end
        if FP.CropButtonTextures then
            FP:CropButtonTextures(btn, 0.15)
        end
    end
    if locked then
        SetHudHoverVisual(arrow, false, false)
        SetHudHoverVisual(customArrow, false, true)
    end
end

arrow:SetScript("OnMouseUp", function(self, button)
    local now = GetTime and GetTime() or 0
    if button == "LeftButton" and not self.isDragging and now > (self.suppressClickUntil or 0) and waypointMapID then
        FP:UpdateMapPin(waypointMapID, waypointX, waypointY, waypointTitle, waypointAction)
        if not (InCombatLockdown and InCombatLockdown()) and WorldMapFrame and not WorldMapFrame:IsShown() and ToggleWorldMap then
            ToggleWorldMap()
        end
    end
end)

customArrow:SetScript("OnMouseUp", function(self, button)
    local now = GetTime and GetTime() or 0
    if self.isDragging or now <= (self.suppressClickUntil or 0) then return end
    if button == "RightButton" then
        if FP.ClearCustomWaypoint then FP:ClearCustomWaypoint() end
    elseif button == "LeftButton" and customWp.mapID then
        if not (InCombatLockdown and InCombatLockdown()) then
            if C_Map and C_Map.OpenWorldMap and IsSafeNum(customWp.mapID) then
                pcall(C_Map.OpenWorldMap, customWp.mapID)
            elseif WorldMapFrame then
                if not WorldMapFrame:IsShown() and ToggleWorldMap then
                    ToggleWorldMap()
                end
                if WorldMapFrame.SetMapID and IsSafeNum(customWp.mapID) then
                    pcall(WorldMapFrame.SetMapID, WorldMapFrame, customWp.mapID)
                end
            end
        end
        if FP.RepositionMapPin then FP:RepositionMapPin() end
    end
end)

-- Real-time Player Coordinates HUD Frame (transparent background, outlined text)
coordsFrame = CreateFrame("Frame", "NexusKitCoordsFrame", UIParent, "BackdropTemplate")
coordsFrame:SetSize(210, 24)
coordsFrame:SetPoint("TOP", UIParent, "TOP", 0, -28)
if coordsFrame.SetDontSavePosition then
    coordsFrame:SetDontSavePosition(true)
end
coordsFrame:SetFrameStrata("MEDIUM")
coordsFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
coordsFrame:SetBackdropColor(0, 0, 0, 0)
coordsFrame:SetBackdropBorderColor(0, 0, 0, 0)
coordsFrame:SetMovable(true)
coordsFrame:EnableMouse(true)
coordsFrame:SetClampedToScreen(true)
coordsFrame:RegisterForDrag("LeftButton")

local coordsText = coordsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ApplyOutlineFont(coordsText, 12)
coordsText:SetPoint("CENTER", coordsFrame, "CENTER", 0, 0)
coordsText:SetTextColor(1, 1, 1, 1)
coordsFrame.text = coordsText

coordsFrame:SetScript("OnDragStart", function(self)
    if not IsArrowLocked() then
        self.isDragging = true
        self:StartMoving()
    end
end)
coordsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.isDragging = false
    self.suppressClickUntil = (GetTime and GetTime() or 0) + 0.2
    SaveHudPosition(self, "coordsPos")
    ApplyHudPosition(self, "coordsPos", "TOP", "TOP", 0, -28)
end)
coordsFrame:SetScript("OnMouseUp", function(self, button)
    local now = GetTime and GetTime() or 0
    if self.isDragging or now <= (self.suppressClickUntil or 0) then return end
    if button == "RightButton" then
        if customWp.mapID and FP.ClearCustomWaypoint then
            FP:ClearCustomWaypoint()
        end
    elseif button == "LeftButton" then
        if ChatFrameUtil and ChatFrameUtil.OpenChat then
            pcall(ChatFrameUtil.OpenChat, "/nk way ")
        elseif ChatFrame_OpenChat then
            pcall(ChatFrame_OpenChat, "/nk way ")
        end
    end
end)
coordsFrame:SetScript("OnEnter", function(self)
    local r, g, b = FP:GetAccentColor()
    if not IsArrowLocked() then
        self:SetBackdropBorderColor(r, g, b, 0.35)
    end
    if GameTooltip and FP.L then
        local L = FP.L
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["TRACKER_TITLE"] or "NexusKit", r, g, b)
        if customWp.mapID and customWp.x and customWp.y then
            local wpZone = GetCachedMapName(customWp.mapID) or ""
            GameTooltip:AddLine(string.format("%s: %s (%.1f, %.1f%s)",
                L["CUSTOM_WAYPOINT_TAG"] or "Custom Waypoint",
                customWp.title or "", customWp.x * 100, customWp.y * 100,
                wpZone ~= "" and (" - " .. wpZone) or ""), 1, 0.38, 1, true)
        end
        GameTooltip:AddLine(L["COORDS_TOOLTIP"] or "Left-click: type /nk way <x> <y> | Right-click: clear custom waypoint | Drag when unlocked.", 0.9, 0.95, 0.9, true)
        GameTooltip:Show()
    end
end)
coordsFrame:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0, 0, 0, 0)
    if GameTooltip then GameTooltip:Hide() end
end)

local coordsAccum = 0
coordsFrame:SetScript("OnUpdate", function(self, elapsed)
    if not IsPlayerCoordsEnabled() then
        self:Hide()
        return
    end
    coordsAccum = coordsAccum + elapsed
    if coordsAccum < 0.10 then return end
    coordsAccum = 0

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local zoneName
    if IsSafeNum(mapID) then
        zoneName = GetCachedMapName(mapID)
    end
    if not zoneName and GetMinimapZoneText then
        local okZ, zTxt = pcall(GetMinimapZoneText)
        if okZ and type(zTxt) == "string" and (not issecretvalue or not issecretvalue(zTxt)) and zTxt ~= "" then
            zoneName = zTxt
        end
    end
    zoneName = zoneName or (FP.L and FP.L["UNKNOWN_ZONE"] or "World")

    local px, py
    if IsSafeNum(mapID) and C_Map and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos and pos.GetXY then
            px, py = pos:GetXY()
        end
    end

    local _, _, _, hex = FP:GetAccentColor()
    local coordStr
    if IsSafeNum(px) and IsSafeNum(py) and (px ~= 0 or py ~= 0) then
        coordStr = string.format("|cff%s%s:|r  |cffffffff%.1f, %.1f|r", hex, zoneName, px * 100, py * 100)
    else
        coordStr = string.format("|cff%s%s:|r  |cff8899aa--.-, --.-|r", hex, zoneName)
    end
    if customWp.mapID then
        coordStr = coordStr .. "  |cffff59ff[WP]|r"
    end

    if self.lastStr ~= coordStr then
        self.lastStr = coordStr
        coordsText:SetText(coordStr)
        local targetW = math.max(150, math.min(360, math.ceil((coordsText:GetStringWidth() or 120) + 22)))
        if math.abs((self:GetWidth() or 0) - targetW) > 1 then
            self:SetWidth(targetW)
        end
    end
end)

arrow:RegisterEvent("PLAYER_LOGIN")
arrow:RegisterEvent("QUEST_LOG_UPDATE")
arrow:RegisterEvent("PLAYER_REGEN_DISABLED")
arrow:RegisterEvent("PLAYER_REGEN_ENABLED")
arrow:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if NexusKitCharDB and type(NexusKitCharDB.customWaypoint) == "table" then
            local cw = NexusKitCharDB.customWaypoint
            local t = cw.title or ""
            if t:find("Collana", 1, true) or t:find("Necklace", 1, true) or t:find("Hilary", 1, true)
                or (cw.mapID == 1433 and IsSafeNum(cw.x) and math.abs(cw.x - 0.478) < 0.05) then
                NexusKitCharDB.customWaypoint = nil
                customWp.mapID = nil
                customWp.x = nil
                customWp.y = nil
                customWp.title = nil
            elseif IsSafeNum(cw.mapID) and IsSafeNum(cw.x) and IsSafeNum(cw.y) then
                customWp.mapID = cw.mapID
                customWp.x = cw.x
                customWp.y = cw.y
                customWp.title = cw.title
            end
        end
        FP:ApplyArrowScale()
        FP:RefreshArrowLockVisual()
        if FP.RefreshCoordsUI then FP:RefreshCoordsUI() end
        if FP.RefreshCustomWaypointUI then FP:RefreshCustomWaypointUI() end
        if FP.InitWorldMapHooks then FP:InitWorldMapHooks() end
    elseif event == "QUEST_LOG_UPDATE" then
        if FP.RepositionMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
            FP:RepositionMapPin()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if ShouldHideArrow() then
            arrow:Hide()
            customArrow:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not ShouldHideArrow() then
            if waypointMapID and waypointX and waypointY then
                arrow:Show()
            end
            if customWp.mapID and customWp.x and customWp.y then
                customArrow:Show()
            end
        end
    end
end)

-------------------------------------------------------------------------------
-- Helpers & Shared Pulsing Ring Builder
-------------------------------------------------------------------------------
local PIN_ACTION_ICONS = {
    TURNIN     = "Interface\\GossipFrame\\ActiveQuestIcon",
    ACCEPT     = "Interface\\GossipFrame\\AvailableQuestIcon",
    COMPLETE   = "Interface\\Icons\\INV_Misc_Map_01",
    GRIND      = "Interface\\Icons\\Ability_Warrior_Revenge",
    GOTO       = "Interface\\Icons\\INV_Misc_Map_01",
    TRAIN      = "Interface\\Icons\\INV_Misc_Book_09",
    SET_HEARTH = "Interface\\Icons\\INV_Misc_Rune_01",
    USE_HEARTH = "Interface\\Icons\\INV_Misc_Rune_01",
    FLY        = "Interface\\Icons\\Ability_Druid_FlightForm",
}

local function ApplyPinIconTexture(tex, iconPath)
    if not tex then return end
    local path = iconPath or PIN_ACTION_ICONS.GOTO
    tex:SetTexture(path)
    if type(path) == "string" and path:find("^Interface\\Icons\\") then
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        tex:SetTexCoord(0, 1, 0, 1)
    end
end

local function AttachPingRing(frame, ringSize)
    local ping = frame:CreateTexture(nil, "BACKGROUND")
    ping:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    ping:SetBlendMode("ADD")
    ping:SetSize(ringSize, ringSize)
    ping:SetPoint("CENTER")
    ping:SetVertexColor(0, 1, 0.59, 0.9)

    local ag = ping:CreateAnimationGroup()
    local s1 = ag:CreateAnimation("Scale")
    s1:SetScaleFrom(0.65, 0.65)
    s1:SetScaleTo(1.85, 1.85)
    s1:SetDuration(1.3)
    s1:SetSmoothing("OUT")
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0.9)
    a1:SetToAlpha(0.0)
    a1:SetDuration(1.3)
    a1:SetSmoothing("OUT")
    ag:SetLooping("REPEAT")

    frame.pingRing = ping
    frame.pingAnim = ag
    return ping, ag
end

local function SetPingRingColor(frame, action)
    if not (frame and frame.pingRing) then return end
    if action == "TURNIN" or action == "ACCEPT" then
        frame.pingRing:SetVertexColor(1, 0.84, 0.12, 0.95)
    elseif action == "TRAIN" then
        frame.pingRing:SetVertexColor(0.35, 0.78, 1.0, 0.95)
    else
        frame.pingRing:SetVertexColor(0, 1, 0.59, 0.9)
    end
end

local mapDimensionsCache = {}
local function GetMapWorldDimensions(mapID)
    if not mapID or mapID <= 0 then
        return YARDS_PER_UNIT, YARDS_PER_UNIT
    end
    local cached = mapDimensionsCache[mapID]
    if cached then
        return cached[1], cached[2]
    end
    if C_Map and C_Map.GetMapWorldSize then
        local ok, w, h = pcall(C_Map.GetMapWorldSize, mapID)
        if ok and type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then
            mapDimensionsCache[mapID] = { w, h }
            return w, h
        end
    end
    return YARDS_PER_UNIT, YARDS_PER_UNIT
end

-------------------------------------------------------------------------------
-- Minimap Pulsing Pins (Quest + Independent Custom Waypoint)
-------------------------------------------------------------------------------
local ZOOM_RADIUS_YARDS = { [0] = 233, [1] = 200, [2] = 166, [3] = 133, [4] = 100, [5] = 66 }
local minimapPin, customMinimapPin, minimapDotsHost
local minimapDots, customMinimapDots = {}, {}
local minimapTrailLine, customMinimapTrailLine

local function EnsureMinimapDotsHost()
    if not Minimap then return nil end
    if not minimapDotsHost then
        minimapDotsHost = CreateFrame("Frame", "NexusKitMinimapDotsHost", UIParent)
        minimapDotsHost:EnableMouse(false)
        minimapDotsHost:Hide()
    end
    minimapDotsHost:SetFrameStrata((Minimap.GetFrameStrata and Minimap:GetFrameStrata()) or "MEDIUM")
    minimapDotsHost:SetFrameLevel(math.max(10, (Minimap:GetFrameLevel() or 2) + 12))
    minimapDotsHost:ClearAllPoints()
    minimapDotsHost:SetAllPoints(Minimap)
    return minimapDotsHost
end

local function CreateMinimapPinFrame(name, levelOffset, isCustom)
    if not Minimap then return nil end
    -- Parent to UIParent (never to Blizzard's Minimap) so Minimap child tree remains untainted
    local pin = CreateFrame("Frame", name, UIParent)
    pin:SetSize(19, 19)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(math.max(14, (Minimap:GetFrameLevel() or 2) + levelOffset + 6))
    pin:EnableMouse(true)

    AttachPingRing(pin, 30)

    local tex = pin:CreateTexture(nil, "OVERLAY")
    ApplyPinIconTexture(tex, isCustom and "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" or PIN_ACTION_ICONS.GOTO)
    tex:SetAllPoints()
    pin.tex = tex

    pin:SetScript("OnEnter", function(self)
        if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
        local L = FP.L or {}
        if isCustom then
            if customWp.mapID then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText(L["CUSTOM_WAYPOINT_TAG"] or "Custom Waypoint", 1, 0.38, 1)
                if customWp.title and customWp.title ~= "" then
                    GameTooltip:AddLine(customWp.title, 1, 1, 1, true)
                end
                GameTooltip:AddLine(string.format("%.1f, %.1f", (customWp.x or 0) * 100, (customWp.y or 0) * 100), 0.9, 0.85, 1)
                if self.yardsText then
                    GameTooltip:AddLine(self.yardsText, 0.85, 0.80, 0.95)
                end
                GameTooltip:AddLine(L["CUSTOM_ARROW_TOOLTIP"] or "Right-click or /nk clear to remove.", 1, 0.65, 1, true)
                GameTooltip:Show()
            end
        elseif waypointTitle and waypointTitle ~= "" then
            local r, g, b = FP:GetAccentColor()
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L["TRACKER_TITLE"] or "NexusKit", r, g, b)
            GameTooltip:AddLine(waypointTitle, 1, 1, 1, true)
            if self.yardsText then
                GameTooltip:AddLine(self.yardsText, 0.8, 0.9, 0.8)
            end
            GameTooltip:Show()
        end
    end)
    pin:SetScript("OnLeave", function()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
    end)
    if isCustom then
        pin:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" and FP.ClearCustomWaypoint then
                FP:ClearCustomWaypoint()
            end
        end)
    end
    pin:Hide()
    return pin
end

local function EnsureMinimapTrailLine(isCustom)
    local host = EnsureMinimapDotsHost()
    if not host then return nil end
    local line = isCustom and customMinimapTrailLine or minimapTrailLine
    if line then return line end
    if host.CreateLine then
        line = host:CreateLine(nil, "ARTWORK", nil, 1)
        if line.SetColorTexture then
            line:SetColorTexture(1, 1, 1, 1)
        else
            line:SetTexture("Interface\\Buttons\\WHITE8x8")
        end
    else
        line = host:CreateTexture(nil, "ARTWORK", nil, 1)
        line:SetTexture("Interface\\Buttons\\WHITE8x8")
        line.isFallbackTex = true
    end
    line:Hide()
    if isCustom then
        customMinimapTrailLine = line
    else
        minimapTrailLine = line
    end
    return line
end

local function HideMinimapIndicator(pin, dotsPool, isCustom)
    if pin then
        if pin.pingAnim then pin.pingAnim:Stop() end
        pin:Hide()
    end
    local line = isCustom and customMinimapTrailLine or minimapTrailLine
    if line then
        line:Hide()
    end
    for _, dot in ipairs(dotsPool) do
        dot:Hide()
    end
end

local function HideMinimapPin()
    HideMinimapIndicator(minimapPin, minimapDots, false)
    if minimapDotsHost and (not customMinimapPin or not customMinimapPin:IsShown()) and (not customMinimapTrailLine or not customMinimapTrailLine:IsShown()) then
        minimapDotsHost:Hide()
    end
end

local function HideCustomMinimapPin()
    HideMinimapIndicator(customMinimapPin, customMinimapDots, true)
    if minimapDotsHost and (not minimapPin or not minimapPin:IsShown()) and (not minimapTrailLine or not minimapTrailLine:IsShown()) then
        minimapDotsHost:Hide()
    end
end

local function UpdateMinimapTrail(dotsPool, isCustom, targetX, targetY, r, g, b)
    local line = EnsureMinimapTrailLine(isCustom)
    if not IsMinimapTrajectoriesEnabled() or not Minimap or not Minimap:IsVisible() then
        if line then line:Hide() end
        for _, dot in ipairs(dotsPool) do
            dot:Hide()
        end
        return
    end

    local host = EnsureMinimapDotsHost()
    if not host then return end

    local distPx = math.sqrt(targetX * targetX + targetY * targetY)
    if distPx < 18 then
        if line then line:Hide() end
        for _, dot in ipairs(dotsPool) do
            dot:Hide()
        end
        return
    end

    -- Draw continuous trail line connecting player center (0, 0) to waypoint target
    if line then
        local lineAlpha = 0.55
        if not line.isFallbackTex then
            line:ClearAllPoints()
            line:SetThickness(2.2)
            if line.SetColorTexture then
                line:SetColorTexture(r, g, b, lineAlpha)
                line:SetVertexColor(1, 1, 1, 1)
            else
                line:SetVertexColor(r, g, b, lineAlpha)
            end
            line:SetStartPoint("CENTER", host, 0, 0)
            line:SetEndPoint("CENTER", host, targetX, targetY)
        else
            line:ClearAllPoints()
            line:SetSize(distPx, 2.2)
            line:SetPoint("CENTER", host, "CENTER", targetX * 0.5, targetY * 0.5)
            line:SetVertexColor(r, g, b, lineAlpha)
            if line.SetRotation then
                local rotFn = math.atan2 or atan2
                if rotFn then line:SetRotation(rotFn(targetY, targetX)) end
            end
        end
        line:Show()
    end

    -- Animated directional breadcrumb dots flowing along the route
    local count = math.min(7, math.max(2, math.floor((distPx - 14) / 10)))
    local now = (GetTime and GetTime()) or 0

    for i = 1, count do
        local dot = dotsPool[i]
        if not dot then
            dot = host:CreateTexture(nil, "OVERLAY")
            dot:SetTexture("Interface\\Buttons\\WHITE8x8")
            dot:SetSize(4, 4)
            dotsPool[i] = dot
        end
        local t = (10 + (distPx - 20) * (i / (count + 1))) / distPx
        local wave = 0.50 + 0.50 * (0.5 + 0.5 * math.sin((now * 4.5) - (i * 0.85)))
        dot:SetVertexColor(r, g, b, math.min(0.95, wave))
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", host, "CENTER", targetX * t, targetY * t)
        dot:Show()
    end

    for i = count + 1, #dotsPool do
        dotsPool[i]:Hide()
    end
    host:Show()
end

local function UpdateMinimapIndicatorForTarget(pin, dotsPool, isCustom, playerMapID, px, py, targetX, targetY, facing, yards, iconTex, ringR, ringG, ringB, dotR, dotG, dotB)
    if not pin or not Minimap or not Minimap:IsVisible() then return end

    local mapW, mapH = GetMapWorldDimensions(playerMapID)
    local eastYards = (targetX - px) * mapW
    local northYards = (py - targetY) * mapH

    local rotX, rotY = eastYards, northYards
    local rotateMM = GetCVar and (GetCVar("rotateMinimap") == "1")
    if rotateMM and facing then
        local cosF = math.cos(facing)
        local sinF = math.sin(facing)
        rotX = eastYards * cosF + northYards * sinF
        rotY = -eastYards * sinF + northYards * cosF
    end

    local radiusYards
    if C_Minimap and C_Minimap.GetViewRadius then
        local ok, r = pcall(C_Minimap.GetViewRadius)
        if ok and type(r) == "number" and r > 0 then
            radiusYards = r
        end
    end
    if not radiusYards then
        local z = (Minimap.GetZoom and Minimap:GetZoom()) or 0
        radiusYards = ZOOM_RADIUS_YARDS[z] or 166
    end

    local halfW = (Minimap:GetWidth() or 140) / 2
    local halfH = (Minimap:GetHeight() or 140) / 2
    local normX = rotX / radiusYards
    local normY = rotY / radiusYards
    local radDist = math.sqrt(normX * normX + normY * normY)
    if radDist > 0.92 then
        normX = (normX / radDist) * 0.92
        normY = (normY / radDist) * 0.92
    end

    local targetPxX = normX * halfW
    local targetPxY = normY * halfH

    local s = GetNavSettings()
    if s.showMinimapPin ~= false then
        ApplyPinIconTexture(pin.tex, iconTex)
        if pin.pingRing then
            pin.pingRing:SetVertexColor(ringR, ringG, ringB, 0.95)
        end
        pin.yardsText = yards and string.format(FP.L["DISTANCE_YARDS"] or "%d yards", yards) or nil

        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", targetPxX, targetPxY)
        pin:Show()
        if pin.pingAnim and not pin.pingAnim:IsPlaying() then
            pin.pingAnim:Play()
        end
    else
        if pin.pingAnim then pin.pingAnim:Stop() end
        pin:Hide()
    end

    UpdateMinimapTrail(dotsPool, isCustom, targetPxX, targetPxY, dotR, dotG, dotB)
end

local function UpdateMinimapPin(playerMapID, px, py, facing, yards)
    if not IsMinimapPinEnabled() or not Minimap or not Minimap:IsVisible() or not waypointMapID or playerMapID ~= waypointMapID then
        HideMinimapPin()
        return
    end
    if not minimapPin then
        minimapPin = CreateMinimapPinFrame("NexusKitMinimapPin", 12, false)
    end
    if not minimapPin then return end

    local ringR, ringG, ringB = 0, 1, 0.59
    if waypointAction == "TURNIN" or waypointAction == "ACCEPT" then
        ringR, ringG, ringB = 1, 0.84, 0.12
    end
    UpdateMinimapIndicatorForTarget(
        minimapPin, minimapDots, false, playerMapID, px, py, waypointX, waypointY, facing, yards,
        PIN_ACTION_ICONS[waypointAction or "GOTO"] or PIN_ACTION_ICONS.GOTO,
        ringR, ringG, ringB, 0.05, 1.0, 0.62
    )
end

local function UpdateCustomMinimapPin(playerMapID, px, py, facing, yards)
    if not IsMinimapPinEnabled() or not Minimap or not Minimap:IsVisible() or not customWp.mapID or playerMapID ~= customWp.mapID then
        HideCustomMinimapPin()
        return
    end
    if not customMinimapPin then
        customMinimapPin = CreateMinimapPinFrame("NexusKitCustomMinimapPin", 13, true)
    end
    if not customMinimapPin then return end

    UpdateMinimapIndicatorForTarget(
        customMinimapPin, customMinimapDots, true, playerMapID, px, py, customWp.x, customWp.y, facing, yards,
        "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
        CUSTOM_COLOR_R, CUSTOM_COLOR_G, CUSTOM_COLOR_B,
        CUSTOM_COLOR_R, CUSTOM_COLOR_G, CUSTOM_COLOR_B
    )
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
function FP:ApplyArrowScale()
    local s = 1
    if NexusKitDB and NexusKitDB.settings and NexusKitDB.settings.arrowScale then
        s = NexusKitDB.settings.arrowScale
    end
    arrow:SetScale(s)
    customArrow:SetScale(s)
    ApplyArrowPosition()
    ApplyCustomArrowPosition()
end

function FP:RefreshCoordsUI()
    if not coordsFrame then return end
    ApplyHudPosition(coordsFrame, "coordsPos", "TOP", "TOP", 0, -28)
    coordsFrame.lastStr = nil
    if IsPlayerCoordsEnabled() then
        coordsFrame:Show()
    else
        coordsFrame:Hide()
    end
end

function FP:RefreshCustomWaypointUI()
    self:ApplyArrowScale()
    self:RefreshArrowLockVisual()
    if customWp.mapID and customWp.x and customWp.y then
        if ShouldHideArrow() then
            customArrow:Hide()
        else
            customArrow:Show()
        end
    else
        customArrow:Hide()
        HideCustomMinimapPin()
    end
    if not IsMinimapPinEnabled() or IsPlayerInDungeon() then
        HideCustomMinimapPin()
    end
    self:RefreshCoordsUI()
    if self.RepositionMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
        self:RepositionMapPin()
    end
end

function FP:RefreshWaypointsUI()
    self:ApplyArrowScale()
    self:RefreshArrowLockVisual()
    local hr, hg, hb = FP:GetHudTextColor()
    if titleText then
        titleText:SetTextColor(hr, hg, hb, 1)
    end
    if pinFrame and pinFrame.label then
        pinFrame.label:SetTextColor(hr, hg, hb, 1)
    end
    if waypointMapID then
        zoneText:SetText(FP.L["DIFFERENT_ZONE"] or "Different Zone")
        if ShouldHideArrow() then
            arrow:Hide()
        elseif waypointX and waypointY then
            arrow:Show()
        end
    end
    if not IsMinimapPinEnabled() or IsPlayerInDungeon() then
        HideMinimapPin()
        HideCustomMinimapPin()
    end
    self:RefreshCoordsUI()
    self:RefreshCustomWaypointUI()
    if self.RepositionMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
        self:RepositionMapPin()
    end
end

local function GetDistanceColor(d100, isCustom)
    if isCustom then
        if d100 > 20 then
            return 0.78, 0.30, 1.0 -- deep violet
        elseif d100 > 5 then
            return 1.0, 0.34, 0.96 -- bright magenta
        end
        return 1.0, 0.64, 1.0      -- hot pink-magenta
    end
    if d100 > 20 then
        return 1.0, 0.24, 0.24     -- red
    elseif d100 > 5 then
        return 1.0, 0.94, 0.22     -- gold
    end
    return 0.22, 1.0, 0.44         -- green
end

local function SetDistanceColor(tex, d100, isCustom, glowTex)
    local r, g, b = GetDistanceColor(d100, isCustom)
    tex:SetVertexColor(r, g, b, 1)
    if glowTex then
        local glowAlpha = (d100 <= 1.5)
            and (0.28 + 0.18 * (0.5 + 0.5 * math.sin((GetTime and GetTime() or 0) * 5.0)))
            or (d100 <= 5 and 0.26 or 0.18)
        glowTex:SetVertexColor(r, g, b, 1)
        glowTex:SetAlpha(glowAlpha)
    end
end

-------------------------------------------------------------------------------
-- OnUpdate – shared directional arrow logic (throttled to ~30 FPS)
-------------------------------------------------------------------------------
local function ComputeArrowState(targetMapID, targetX, targetY)
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then
        return "unavailable"
    end
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not IsSafeNum(playerMapID) then
        return "unavailable"
    end

    local effX, effY = targetX, targetY
    local crossZoneName = nil
    if playerMapID ~= targetMapID then
        local projX, projY
        if IsCrossZoneProjEnabled() then
            projX, projY = ProjectTargetToPlayerMap(playerMapID, targetMapID, targetX, targetY)
        end
        if projX and projY then
            effX, effY = projX, projY
            crossZoneName = GetCachedMapName(targetMapID)
        else
            return "diff_zone", playerMapID, nil, nil, nil, nil, nil, nil, GetCachedMapName(targetMapID)
        end
    end

    local pos = C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not pos then return "unavailable" end

    local px, py = pos:GetXY()
    if not IsSafeNum(px) or not IsSafeNum(py) or (px == 0 and py == 0) then
        return "unavailable"
    end

    local dx = effX - px
    local dy = py - effY
    local alphaTarget = atan2(-dx, dy)
    local rawFacing = GetPlayerFacing and GetPlayerFacing() or 0
    local facing = IsSafeNum(rawFacing) and rawFacing or 0
    local theta = (alphaTarget - facing) % TWO_PI

    local dNorm = math.sqrt(dx * dx + dy * dy)
    local d100 = dNorm * 100
    local mapW, mapH = GetMapWorldDimensions(playerMapID)
    local yards = math.floor(math.sqrt((dx * mapW) ^ 2 + (dy * mapH) ^ 2) + 0.5)

    return "active", playerMapID, px, py, theta, facing, d100, yards, crossZoneName
end

local function UpdateDirectionalArrowFrame(hud, targetMapID, targetX, targetY, labelText, isCustom)
    local hideMinimap = isCustom and HideCustomMinimapPin or HideMinimapPin
    local updateMinimap = isCustom and UpdateCustomMinimapPin or UpdateMinimapPin

    hud.titleText:SetText(labelText or "")
    hud.titleText:Show()

    local state, playerMapID, px, py, theta, facing, d100, yards, zoneLabel =
        ComputeArrowState(targetMapID, targetX, targetY)

    if state == "unavailable" then
        hideMinimap()
        hud.arrowTex:Hide()
        if hud.arrowGlow then hud.arrowGlow:Hide() end
        hud.distText:Hide()
        hud.zoneText:Hide()
        return false, nil, nil
    end

    if state == "diff_zone" then
        hideMinimap()
        if math.abs((hud:GetHeight() or 0) - ARROW_BOX_HEIGHT_COMPACT) > 1 then
            hud:SetHeight(ARROW_BOX_HEIGHT_COMPACT)
        end
        hud.arrowTex:Hide()
        if hud.arrowGlow then hud.arrowGlow:Hide() end
        hud.distText:Hide()
        local diffText = FP.L["DIFFERENT_ZONE"] or "Different Zone"
        hud.zoneText:SetText(zoneLabel and (diffText .. " (" .. zoneLabel .. ")") or diffText)
        hud.zoneText:Show()
        hud:Show()
        return true, zoneLabel, nil
    end

    if math.abs((hud:GetHeight() or 0) - ARROW_BOX_HEIGHT_FULL) > 1 then
        hud:SetHeight(ARROW_BOX_HEIGHT_FULL)
    end
    hud.arrowTex:Show()
    if hud.arrowGlow then hud.arrowGlow:Show() end
    hud.distText:Show()
    hud.zoneText:Hide()

    local displayTheta = theta
    if d100 <= 0.25 and hud.lastTheta then
        displayTheta = hud.lastTheta
    else
        hud.lastTheta = theta
    end
    hud.arrowTex:SetRotation(displayTheta)
    SetDistanceColor(hud.arrowTex, d100, isCustom, hud.arrowGlow)

    if not zoneLabel and d100 <= 1.5 then
        hud.distText:SetText(FP.L["WAYPOINT_ARRIVED"] or "You have arrived!")
        if isCustom then
            hud.distText:SetTextColor(1, 0.62, 1, 1)
        else
            hud.distText:SetTextColor(0.2, 1, 0.4, 1)
        end
    elseif zoneLabel then
        hud.distText:SetText(string.format((FP.L["DISTANCE_YARDS"] or "%d yards") .. " (%s)", yards, zoneLabel))
        hud.distText:SetTextColor(isCustom and 1 or 1, isCustom and 0.72 or 0.88, isCustom and 1 or 0.45, 1)
    else
        hud.distText:SetFormattedText(FP.L["DISTANCE_YARDS"] or "%d yards", yards)
        hud.distText:SetTextColor(1, 1, 1, 1)
    end

    if zoneLabel then
        hideMinimap()
    else
        updateMinimap(playerMapID, px, py, facing, yards)
    end

    return true, zoneLabel, d100
end

arrow:SetScript("OnUpdate", function(self, elapsed)
    elapsed_accum = elapsed_accum + elapsed
    if elapsed_accum < UPDATE_INTERVAL then return end
    elapsed_accum = 0

    if not waypointMapID or not waypointX or not waypointY or ShouldHideArrow() then
        if IsPlayerInDungeon() then HideMinimapPin() end
        self:Hide()
        return
    end

    local ok, crossZoneName, d100 = UpdateDirectionalArrowFrame(self, waypointMapID, waypointX, waypointY, waypointTitle, false)
    if not ok or not d100 then return end

    -- Auto-advance GOTO / FLY steps when arriving within completion threshold on same map
    if not crossZoneName and ((waypointAction == "GOTO" and d100 <= 1.5) or (waypointAction == "FLY" and d100 <= 2.0)) then
        local now = GetTime and GetTime() or 0
        if (now - lastSyncTrigger) >= 0.5 then
            lastSyncTrigger = now
            if FP.UpdateCurrentStep then
                FP:UpdateCurrentStep()
            end
        end
    end
end)

customArrow:SetScript("OnUpdate", function(self, elapsed)
    self.accum = (self.accum or 0) + elapsed
    if self.accum < UPDATE_INTERVAL then return end
    self.accum = 0

    if not customWp.mapID or not customWp.x or not customWp.y or ShouldHideArrow() then
        if IsPlayerInDungeon() then HideCustomMinimapPin() end
        self:Hide()
        return
    end

    UpdateDirectionalArrowFrame(self, customWp.mapID, customWp.x, customWp.y, customWp.title, true)
end)

-------------------------------------------------------------------------------
-- Map Pins, Zone Pings & Quest Trajectories on WorldMapFrame
-------------------------------------------------------------------------------
local pinFrame
local extraPins = {}
local worldMapHooked = false
local trailLayer
local trailLines = {}
local trailDots = {}
local lastTrailPlayerX, lastTrailPlayerY
local trailTickAccum = 0
local trailPosAccum = 0

local ORDER_BADGE_CANDIDATES = {
    { 19,  16, 0 },  { 19, -16, 1 },  { -19,  16, 2 }, { -19, -16, 3 },
    { 24,   0, 2 },  { -24,  0, 3 },  {   0,  22, 2 }, {   0, -22, 3 },
    { 26,  20, 12 }, { 26, -20, 13 }, { -26,  20, 14 }, { -26, -20, 15 },
    { 31,   0, 14 }, { -31,  0, 14 }, {   0,  29, 14 }, {   0, -29, 15 },
}

local function PointToSegmentDistSq(px, py, x1, y1, x2, y2)
    local vx, vy = x2 - x1, y2 - y1
    local l2 = vx * vx + vy * vy
    if l2 <= 1e-6 then
        local dx, dy = px - x1, py - y1
        return dx * dx + dy * dy
    end
    local t = ((px - x1) * vx + (py - y1) * vy) / l2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    local dx = px - (x1 + t * vx)
    local dy = py - (y1 + t * vy)
    return dx * dx + dy * dy
end

local function CreatePinOrderBadge(pin)
    local badge = CreateFrame("Frame", nil, pin, "BackdropTemplate")
    badge:SetSize(15, 15)
    badge:SetPoint("CENTER", pin, "CENTER", 19, 16)
    badge:SetFrameLevel(pin:GetFrameLevel() + 4)
    badge:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    badge:SetBackdropColor(0.04, 0.06, 0.09, 0.94)
    badge:SetBackdropBorderColor(0, 1, 0.59, 0.9)

    local num = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    num:SetPoint("CENTER", 0, 0)
    local fontName, fontSize = num:GetFont()
    if fontName and fontSize then
        num:SetFont(fontName, math.max(9, fontSize - 2), "OUTLINE")
    end
    badge.text = num
    badge:Hide()
    return badge
end

local function SetPinOrderNumber(pin, orderIdx, isPrimary, offX, offY)
    if not pin or not pin.orderBadge then return end
    if not orderIdx or not IsTrajectoriesEnabled() then
        pin.orderBadge:Hide()
        return
    end
    pin.orderBadge:SetSize((orderIdx >= 10) and 19 or 15, 15)
    pin.orderBadge:ClearAllPoints()
    pin.orderBadge:SetPoint("CENTER", pin, "CENTER", offX or 19, offY or 16)
    pin.orderBadge.text:SetText(tostring(orderIdx))
    if isPrimary then
        pin.orderBadge:SetBackdropBorderColor(0, 1, 0.59, 1)
        pin.orderBadge.text:SetTextColor(0, 1, 0.59, 1)
    elseif pin.isReady then
        pin.orderBadge:SetBackdropBorderColor(1, 0.84, 0.12, 0.95)
        pin.orderBadge.text:SetTextColor(1, 0.84, 0.12, 1)
    else
        pin.orderBadge:SetBackdropBorderColor(0.30, 0.88, 1.0, 0.95)
        pin.orderBadge.text:SetTextColor(0.45, 0.92, 1.0, 1)
    end
    pin.orderBadge:Show()
end

local function PlaceStopOrderBadges(stops, activeExtraPins, playerX, playerY, customX, customY, hasCustomSeg, w, h)
    if not stops or #stops == 0 or not w or not h then return end

    local segments = {}
    if playerX and playerY and stops[1] then
        segments[#segments + 1] = { playerX * w, playerY * h, stops[1].x * w, stops[1].y * h }
    end
    for k = 1, #stops - 1 do
        segments[#segments + 1] = { stops[k].x * w, stops[k].y * h, stops[k + 1].x * w, stops[k + 1].y * h }
    end
    if hasCustomSeg and playerX and playerY and customX and customY then
        segments[#segments + 1] = { playerX * w, playerY * h, customX * w, customY * h }
    end

    local obstacles = {}
    if playerX and playerY then
        obstacles[#obstacles + 1] = { x = playerX * w, y = playerY * h, r = 26, weight = 6 }
    end
    for _, st in ipairs(stops) do
        obstacles[#obstacles + 1] = { x = st.x * w, y = st.y * h, r = 26, weight = 8 }
    end
    for _, ep in ipairs(activeExtraPins or {}) do
        if ep.x and ep.y then
            obstacles[#obstacles + 1] = { x = ep.x * w, y = ep.y * h, r = 24, weight = 7 }
        end
    end

    local hasPrimaryLabel = pinFrame and pinFrame.label and (pinFrame.label:GetText() or "") ~= ""
    local placed = {}

    for orderIdx, stop in ipairs(stops) do
        if stop.pin then
            stop.pin.orderIndex = orderIdx
            local sx, sy = stop.x * w, stop.y * h
            local isPrimaryPin = (stop.pin == pinFrame) and hasPrimaryLabel
            local bestDx, bestDy, bestPen = 19, 16, nil

            for _, cand in ipairs(ORDER_BADGE_CANDIDATES) do
                local dx, dy, pref = cand[1], cand[2], cand[3]
                local bx, by = sx + dx, sy - dy
                local pen = pref

                if bx < 10 then pen = pen + (10 - bx) * 20
                elseif bx > w - 10 then pen = pen + (bx - (w - 10)) * 20 end
                if by < 10 then pen = pen + (10 - by) * 20
                elseif by > h - 10 then pen = pen + (by - (h - 10)) * 20 end

                if isPrimaryPin and dy < -10 and math.abs(dx) < 55 then
                    pen = pen + 35
                end

                for _, obs in ipairs(obstacles) do
                    local odx, ody = obs.x - sx, obs.y - sy
                    if (odx * odx + ody * ody) > 9 then
                        local d = math.sqrt((bx - obs.x) ^ 2 + (by - obs.y) ^ 2)
                        if d < obs.r then
                            pen = pen + (obs.r - d) * obs.weight
                        end
                    end
                end

                for _, seg in ipairs(segments) do
                    local d = math.sqrt(PointToSegmentDistSq(bx, by, seg[1], seg[2], seg[3], seg[4]))
                    if d < 16 then
                        pen = pen + (16 - d) * 9
                    end
                end

                for _, pb in ipairs(placed) do
                    local d = math.sqrt((bx - pb.x) ^ 2 + (by - pb.y) ^ 2)
                    if d < 22 then
                        pen = pen + (22 - d) * 14
                    end
                end

                if not bestPen or pen < bestPen then
                    bestPen = pen
                    bestDx = dx
                    bestDy = dy
                end
            end

            placed[#placed + 1] = { x = sx + bestDx, y = sy - bestDy }
            SetPinOrderNumber(stop.pin, orderIdx, orderIdx == 1, bestDx, bestDy)
        end
    end
end

local function IsForbiddenObj(obj)
    return not obj or (obj.IsForbidden and obj:IsForbidden())
end

local function GetWorldMapCanvas()
    if not WorldMapFrame or IsForbiddenObj(WorldMapFrame) then return nil, nil end
    local scroll = WorldMapFrame.ScrollContainer
    local canvas = (WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas())
        or (scroll and (scroll.Child or (scroll.GetScrollChild and scroll:GetScrollChild())))
        or scroll
    return canvas, scroll
end

-- WorldMap overlay hierarchy lives strictly on UIParent (clipped to ScrollContainer bounds),
-- never parented onto Blizzard's ScrollContainer/Canvas so zoom & pan stay 1:1 with zero taint.
local mapOverlayRoot = CreateFrame("Frame", "NexusKitWorldMapOverlay", UIParent)
mapOverlayRoot:SetClipsChildren(true)
mapOverlayRoot:EnableMouse(false)
mapOverlayRoot:Hide()

local mapCanvasProxy = CreateFrame("Frame", nil, mapOverlayRoot)
mapCanvasProxy:EnableMouse(false)

local mapGeoCache = {}
local zoomRedrawTimer = nil
local pendingMapRefreshTimer = nil

local OVERLAY_NEXT_STRATA = {
    BACKGROUND        = "LOW",
    LOW               = "MEDIUM",
    MEDIUM            = "HIGH",
    HIGH              = "DIALOG",
    DIALOG            = "FULLSCREEN",
    FULLSCREEN        = "FULLSCREEN_DIALOG",
    FULLSCREEN_DIALOG = "FULLSCREEN_DIALOG",
}

local function ResetMapGeoCache()
    for k in pairs(mapGeoCache) do
        mapGeoCache[k] = nil
    end
end

local function ScheduleDeferredMapRefresh(delay)
    if C_Timer and C_Timer.NewTimer then
        if pendingMapRefreshTimer then
            pendingMapRefreshTimer:Cancel()
        end
        pendingMapRefreshTimer = C_Timer.NewTimer(delay or 0.03, function()
            pendingMapRefreshTimer = nil
            if WorldMapFrame and not IsForbiddenObj(WorldMapFrame) and WorldMapFrame:IsShown() and FP.RepositionMapPin then
                FP:RepositionMapPin()
            end
        end)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay or 0.03, function()
            if WorldMapFrame and not IsForbiddenObj(WorldMapFrame) and WorldMapFrame:IsShown() and FP.RepositionMapPin then
                FP:RepositionMapPin()
            end
        end)
    end
end

local function SyncMapProxyGeometry()
    if not WorldMapFrame or IsForbiddenObj(WorldMapFrame) or not WorldMapFrame:IsShown() then
        return false, false, nil, nil
    end
    local canvas, scroll = GetWorldMapCanvas()
    local clipRegion = (scroll and not IsForbiddenObj(scroll) and scroll:IsVisible()) and scroll or WorldMapFrame
    if not canvas or IsForbiddenObj(canvas) or not canvas:IsVisible() then
        return false, false, nil, nil
    end

    local sLeft, sRight = clipRegion:GetLeft(), clipRegion:GetRight()
    local sBottom, sTop = clipRegion:GetBottom(), clipRegion:GetTop()
    local cLeft, cRight = canvas:GetLeft(), canvas:GetRight()
    local cBottom, cTop = canvas:GetBottom(), canvas:GetTop()
    if not IsSafeNum(sLeft) or not IsSafeNum(sRight) or not IsSafeNum(sBottom) or not IsSafeNum(sTop) then
        return false, false, nil, nil
    end

    local uiEff = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local sEff = (clipRegion.GetEffectiveScale and clipRegion:GetEffectiveScale()) or uiEff
    local cEff = (canvas.GetEffectiveScale and canvas:GetEffectiveScale()) or uiEff

    local rootX = (sLeft * sEff) / uiEff
    local rootY = (sBottom * sEff) / uiEff
    local rootW = math.max(1, ((sRight - sLeft) * sEff) / uiEff)
    local rootH = math.max(1, ((sTop - sBottom) * sEff) / uiEff)

    local proxyX, proxyY, proxyW, proxyH
    if IsSafeNum(cLeft) and IsSafeNum(cRight) and IsSafeNum(cBottom) and IsSafeNum(cTop) then
        proxyX = (cLeft * cEff) / uiEff
        proxyY = (cBottom * cEff) / uiEff
        proxyW = math.max(1, ((cRight - cLeft) * cEff) / uiEff)
        proxyH = math.max(1, ((cTop - cBottom) * cEff) / uiEff)
    end

    -- Fallback / reconciliation with ScrollContainer zoom & scroll if child rect hasn't updated or scaled
    if scroll and not IsForbiddenObj(scroll) then
        local z = scroll.GetCanvasScale and scroll:GetCanvasScale()
        if IsSafeNum(z) and z > 0 then
            if not proxyW or not proxyH or (z > 1.03 and math.abs(proxyW - rootW) < 2 and math.abs(proxyH - rootH) < 2) then
                local cw, ch = canvas:GetWidth(), canvas:GetHeight()
                if IsSafeNum(cw) and IsSafeNum(ch) and cw > 1 and ch > 1 then
                    proxyW = math.max(1, ((cw * sEff) / uiEff) * z)
                    proxyH = math.max(1, ((ch * sEff) / uiEff) * z)
                else
                    proxyW = math.max(1, rootW * z)
                    proxyH = math.max(1, rootH * z)
                end
                proxyX = nil
                proxyY = nil
            end
        end

        if proxyW and proxyH then
            local nx = scroll.GetNormalizedHorizontalScroll and scroll:GetNormalizedHorizontalScroll()
            if not IsSafeNum(nx) and scroll.GetHorizontalScroll and scroll.GetHorizontalScrollRange then
                local rng = scroll:GetHorizontalScrollRange()
                local cur = scroll:GetHorizontalScroll()
                if IsSafeNum(rng) and IsSafeNum(cur) then
                    nx = (rng > 0) and (cur / rng) or 0
                end
            end
            local ny = scroll.GetNormalizedVerticalScroll and scroll:GetNormalizedVerticalScroll()
            if not IsSafeNum(ny) and scroll.GetVerticalScroll and scroll.GetVerticalScrollRange then
                local rng = scroll:GetVerticalScrollRange()
                local cur = scroll:GetVerticalScroll()
                if IsSafeNum(rng) and IsSafeNum(cur) then
                    ny = (rng > 0) and (cur / rng) or 0
                end
            end
            if IsSafeNum(nx) and (not proxyX or (proxyW > rootW + 2 and nx > 0.02 and math.abs(proxyX - rootX) < 1)) then
                proxyX = (proxyW > rootW) and (rootX - nx * (proxyW - rootW)) or (rootX + (rootW - proxyW) * 0.5)
            elseif not proxyX then
                proxyX = (proxyW > rootW) and rootX or (rootX + (rootW - proxyW) * 0.5)
            end
            if IsSafeNum(ny) and (not proxyY or (proxyH > rootH + 2 and ny > 0.02 and math.abs(proxyY - (rootY + rootH - proxyH)) < 1)) then
                proxyY = (proxyH > rootH) and (rootY + rootH - proxyH + ny * (proxyH - rootH)) or (rootY + (rootH - proxyH) * 0.5)
            elseif not proxyY then
                proxyY = (proxyH > rootH) and (rootY + rootH - proxyH) or (rootY + (rootH - proxyH) * 0.5)
            end
        end
    end

    if not proxyX or not proxyY or not proxyW or not proxyH then
        return false, false, nil, nil
    end

    -- Place overlay one strata tier above WorldMapFrame (HIGH -> DIALOG, etc.) and high frame level
    -- so Blizzard's PinFrameLevelsManager (2000+), BorderFrame, or toplevel Raise() never cover pins/trails,
    -- while keeping GameTooltip ("TOOLTIP" strata) above our pins.
    local baseStrata = (clipRegion.GetFrameStrata and clipRegion:GetFrameStrata())
        or (WorldMapFrame.GetFrameStrata and WorldMapFrame:GetFrameStrata())
        or "HIGH"
    local strata = OVERLAY_NEXT_STRATA[baseStrata] or "DIALOG"
    local lvl = math.max(3500, (canvas.GetFrameLevel and canvas:GetFrameLevel() or 50) + 3500)

    local sizeChanged = not mapGeoCache.proxyW
        or math.abs(proxyW - mapGeoCache.proxyW) > 0.05
        or math.abs(proxyH - mapGeoCache.proxyH) > 0.05
    local moved = sizeChanged
        or not mapGeoCache.proxyX
        or math.abs(proxyX - mapGeoCache.proxyX) > 0.05
        or math.abs(proxyY - mapGeoCache.proxyY) > 0.05
        or math.abs(rootX - mapGeoCache.rootX) > 0.05
        or math.abs(rootY - mapGeoCache.rootY) > 0.05
        or math.abs(rootW - mapGeoCache.rootW) > 0.05
        or math.abs(rootH - mapGeoCache.rootH) > 0.05
        or mapGeoCache.strata ~= strata
        or mapGeoCache.lvl ~= lvl

    if moved then
        mapOverlayRoot:SetFrameStrata(strata)
        mapOverlayRoot:SetFrameLevel(lvl)
        mapOverlayRoot:ClearAllPoints()
        mapOverlayRoot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", rootX, rootY)
        mapOverlayRoot:SetSize(rootW, rootH)

        mapCanvasProxy:SetFrameStrata(strata)
        mapCanvasProxy:SetFrameLevel(lvl + 2)
        mapCanvasProxy:ClearAllPoints()
        mapCanvasProxy:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", proxyX, proxyY)
        mapCanvasProxy:SetSize(proxyW, proxyH)

        if trailLayer then
            trailLayer:SetFrameStrata(strata)
            trailLayer:SetFrameLevel(lvl + 10)
        end

        mapGeoCache.rootX, mapGeoCache.rootY = rootX, rootY
        mapGeoCache.rootW, mapGeoCache.rootH = rootW, rootH
        mapGeoCache.proxyX, mapGeoCache.proxyY = proxyX, proxyY
        mapGeoCache.proxyW, mapGeoCache.proxyH = proxyW, proxyH
        mapGeoCache.strata, mapGeoCache.lvl = strata, lvl
    end

    return true, sizeChanged, proxyW, proxyH
end

local function PositionPinOnCanvas(pin, proxyParent, w, h, normX, normY, levelOffset)
    if not pin or not proxyParent or not w or not h then return end
    if pin:GetParent() ~= proxyParent then
        pin:SetParent(proxyParent)
    end
    local strata = proxyParent.GetFrameStrata and proxyParent:GetFrameStrata()
    local lvl = ((proxyParent.GetFrameLevel and proxyParent:GetFrameLevel()) or 120) + (levelOffset or 40)
    if strata then
        pin:SetFrameStrata(strata)
    end
    pin:SetFrameLevel(lvl)
    if pin.orderBadge then
        if strata then pin.orderBadge:SetFrameStrata(strata) end
        pin.orderBadge:SetFrameLevel(lvl + 4)
    end
    pin:SetScale(1)
    pin.canvasNormX = normX
    pin.canvasNormY = normY
    pin.canvasLevelOffset = levelOffset or 40
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", proxyParent, "TOPLEFT", normX * w, -(normY * h))
end

local function HideTrails()
    if trailLayer then
        trailLayer:Hide()
    end
    for _, line in ipairs(trailLines) do
        line:Hide()
    end
    for _, dot in ipairs(trailDots) do
        dot:Hide()
    end
end

local function EnsureTrailLayer(proxyParent)
    local strata = proxyParent and proxyParent.GetFrameStrata and proxyParent:GetFrameStrata()
    local level = ((proxyParent and proxyParent:GetFrameLevel()) or 122) + 8

    if not trailLayer then
        trailLayer = CreateFrame("Frame", "NexusKitMapTrailLayer", proxyParent)
        trailLayer:EnableMouse(false)
        trailLayer:Hide()
    elseif trailLayer:GetParent() ~= proxyParent then
        trailLayer:SetParent(proxyParent)
    end

    if strata then
        trailLayer:SetFrameStrata(strata)
    end
    trailLayer:SetScale(1)
    trailLayer:ClearAllPoints()
    trailLayer:SetAllPoints(proxyParent)
    trailLayer:SetFrameLevel(level)
    return trailLayer
end

local customMapPin

local function RescaleTrailsOnCanvas(w, h)
    if not trailLayer or not trailLayer:IsShown() or not w or not h then return end
    for _, line in ipairs(trailLines) do
        if line:IsShown() and line.fp_nx1 then
            local px1, py1 = line.fp_nx1 * w, -(line.fp_ny1 * h)
            local px2, py2 = line.fp_nx2 * w, -(line.fp_ny2 * h)
            if not line.isFallbackTex then
                line:ClearAllPoints()
                line:SetStartPoint("TOPLEFT", trailLayer, px1, py1)
                line:SetEndPoint("TOPLEFT", trailLayer, px2, py2)
            else
                local dx, dy = px2 - px1, py2 - py1
                local dist = math.sqrt(dx * dx + dy * dy)
                line:ClearAllPoints()
                line:SetSize(math.max(1, dist), line.fp_thick or 2)
                line:SetPoint("CENTER", trailLayer, "TOPLEFT", (px1 + px2) * 0.5, (py1 + py2) * 0.5)
                if line.SetRotation then
                    line:SetRotation(atan2(dy, dx))
                end
            end
        end
    end
    for _, dot in ipairs(trailDots) do
        if dot:IsShown() and dot.fp_nx then
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", trailLayer, "TOPLEFT", dot.fp_nx * w, -(dot.fp_ny * h))
        end
    end
end

mapOverlayRoot:SetScript("OnUpdate", function(self, elapsed)
    if not WorldMapFrame or IsForbiddenObj(WorldMapFrame) or not WorldMapFrame:IsShown() then
        self:Hide()
        return
    end
    local ok, sizeChanged, w, h = SyncMapProxyGeometry()
    if not ok then
        return
    end

    if sizeChanged and w and h then
        if pinFrame and pinFrame:IsShown() and pinFrame.canvasNormX and pinFrame.canvasNormY then
            PositionPinOnCanvas(pinFrame, mapCanvasProxy, w, h, pinFrame.canvasNormX, pinFrame.canvasNormY, pinFrame.canvasLevelOffset)
        end
        if customMapPin and customMapPin:IsShown() and customMapPin.canvasNormX and customMapPin.canvasNormY then
            PositionPinOnCanvas(customMapPin, mapCanvasProxy, w, h, customMapPin.canvasNormX, customMapPin.canvasNormY, customMapPin.canvasLevelOffset)
        end
        for _, ep in ipairs(extraPins) do
            if ep:IsShown() and ep.canvasNormX and ep.canvasNormY then
                PositionPinOnCanvas(ep, mapCanvasProxy, w, h, ep.canvasNormX, ep.canvasNormY, ep.canvasLevelOffset)
            end
        end
        RescaleTrailsOnCanvas(w, h)
        if C_Timer and C_Timer.NewTimer then
            if zoomRedrawTimer then zoomRedrawTimer:Cancel() end
            zoomRedrawTimer = C_Timer.NewTimer(0.05, function()
                zoomRedrawTimer = nil
                if WorldMapFrame and not IsForbiddenObj(WorldMapFrame) and WorldMapFrame:IsShown() and FP.RepositionMapPin then
                    FP:RepositionMapPin()
                end
            end)
        end
    end

    trailTickAccum = trailTickAccum + elapsed
    if trailTickAccum >= 0.04 and trailLayer and trailLayer:IsShown() then
        trailTickAccum = 0
        local now = (GetTime and GetTime()) or 0
        for _, dot in ipairs(trailDots) do
            if dot:IsShown() then
                if dot.isPrimary then
                    local wave = 0.40 + 0.60 * (0.5 + 0.5 * math.sin((now * 4.5) - ((dot.phase or 0) * 6.0)))
                    dot:SetAlpha(wave)
                else
                    dot:SetAlpha(0.70)
                end
            end
        end
    end

    trailPosAccum = trailPosAccum + elapsed
    if trailPosAccum >= 0.25 then
        trailPosAccum = 0
        local currentMapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
        if IsSafeNum(currentMapID) and C_Map and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
            if pos then
                local px, py = pos:GetXY()
                if IsSafeNum(px) and IsSafeNum(py) and px > 0 and px < 1 and py > 0 and py < 1 then
                    if not lastTrailPlayerX or math.abs(px - lastTrailPlayerX) > 0.004 or math.abs(py - lastTrailPlayerY) > 0.004 then
                        FP:RepositionMapPin()
                    end
                end
            end
        end
    end
end)

local function AcquireTrailLine(index, layer)
    local line = trailLines[index]
    if line then
        if line:GetParent() ~= layer then line:SetParent(layer) end
        return line
    end
    if layer.CreateLine then
        line = layer:CreateLine(nil, "ARTWORK", nil, 1)
        if line.SetColorTexture then
            line:SetColorTexture(1, 1, 1, 1)
        else
            line:SetTexture("Interface\\Buttons\\WHITE8x8")
        end
    else
        line = layer:CreateTexture(nil, "ARTWORK", nil, 1)
        line:SetTexture("Interface\\Buttons\\WHITE8x8")
        line.isFallbackTex = true
    end
    trailLines[index] = line
    return line
end

local function AcquireTrailDot(index, layer)
    local dot = trailDots[index]
    if dot then
        if dot:GetParent() ~= layer then dot:SetParent(layer) end
        return dot
    end
    dot = layer:CreateTexture(nil, "OVERLAY", nil, 2)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")
    trailDots[index] = dot
    return dot
end

local function DrawTrajectorySegment(layer, w, h, cScale, x1, y1, x2, y2, r, g, b, isPrimary, lineIdxRef, dotIdxRef)
    local px1, py1 = x1 * w, -(y1 * h)
    local px2, py2 = x2 * w, -(y2 * h)
    local dx, dy = px2 - px1, py2 - py1
    local dist = math.sqrt(dx * dx + dy * dy)
    local scale = (IsSafeNum(cScale) and cScale > 0) and cScale or 1
    if (dist * scale) < 6 or dist < 2 then return end

    local visualScale = math.max(0.40, math.min(1.65, 1.0 / scale))
    local lineIdx = lineIdxRef[1] + 1
    lineIdxRef[1] = lineIdx
    local line = AcquireTrailLine(lineIdx, layer)
    local thick = math.max(1.5, (isPrimary and 3.0 or 2.0) * visualScale)
    local lineAlpha = isPrimary and 0.78 or 0.50
    line.fp_nx1 = x1
    line.fp_ny1 = y1
    line.fp_nx2 = x2
    line.fp_ny2 = y2
    line.fp_thick = thick

    if not line.isFallbackTex then
        line:ClearAllPoints()
        line:SetThickness(thick)
        if line.SetColorTexture then
            line:SetColorTexture(r, g, b, lineAlpha)
            line:SetVertexColor(1, 1, 1, 1)
        else
            line:SetVertexColor(r, g, b, lineAlpha)
        end
        line:SetStartPoint("TOPLEFT", layer, px1, py1)
        line:SetEndPoint("TOPLEFT", layer, px2, py2)
    else
        line:ClearAllPoints()
        line:SetSize(dist, thick)
        line:SetPoint("CENTER", layer, "TOPLEFT", (px1 + px2) * 0.5, (py1 + py2) * 0.5)
        line:SetVertexColor(r, g, b, lineAlpha)
        if line.SetRotation then
            line:SetRotation(atan2(dy, dx))
        end
    end
    line:Show()

    local startPad = 14 * visualScale
    local endPad = 16 * visualScale
    local usable = dist - startPad - endPad
    if usable >= (10 * visualScale) then
        local spacing = (isPrimary and 16 or 22) * visualScale
        local dotCount = math.min(28, math.max(1, math.floor(usable / spacing)))
        local dotSize = math.max(2.5, (isPrimary and 5 or 4) * visualScale)
        for s = 1, dotCount do
            local dotIdx = dotIdxRef[1] + 1
            dotIdxRef[1] = dotIdx
            local dot = AcquireTrailDot(dotIdx, layer)
            local frac = (startPad + usable * (s / (dotCount + 1))) / dist
            dot:SetSize(dotSize, dotSize)
            dot:SetVertexColor(r, g, b, isPrimary and 0.95 or 0.72)
            dot.isPrimary = isPrimary
            dot.phase = s / (dotCount + 1)
            dot.fp_nx = x1 + (x2 - x1) * frac
            dot.fp_ny = y1 + (y2 - y1) * frac
            dot.fp_size = dotSize
            dot:ClearAllPoints()
            dot:SetPoint("CENTER", layer, "TOPLEFT", px1 + dx * frac, py1 + dy * frac)
            dot:Show()
        end
    end
end

local function GetWatchedQuestIDSet()
    local watched = {}
    if C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
        local ok, n = pcall(C_QuestLog.GetNumQuestWatches)
        if ok and type(n) == "number" then
            for i = 1, n do
                local qOk, qid = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
                if qOk and qid and qid > 0 then
                    watched[qid] = true
                end
            end
        end
    elseif GetNumQuestWatches and GetQuestIndexForWatch and GetQuestLogTitle then
        local n = GetNumQuestWatches() or 0
        for i = 1, n do
            local logIdx = GetQuestIndexForWatch(i)
            if logIdx and logIdx > 0 then
                local _, _, _, _, _, _, _, qid = GetQuestLogTitle(logIdx)
                if qid and qid > 0 then
                    watched[qid] = true
                end
            end
        end
    end
    return watched
end

local function HideExtraZonePins()
    for _, ep in ipairs(extraPins) do
        if ep.pingAnim then ep.pingAnim:Stop() end
        if ep.orderBadge then ep.orderBadge:Hide() end
        if ep.tex then ep.tex:Hide() end
        ep.stepData = nil
        ep:SetSize(20, 20)
        ep.canvasNormX = nil
        ep.canvasNormY = nil
        ep:Hide()
    end
end

local function GetOrCreateExtraPin(index, parent)
    local ep = extraPins[index]
    if ep then return ep end

    ep = CreateFrame("Button", "NexusKitZonePin" .. index, parent)
    ep:SetSize(20, 20)
    ep:EnableMouse(true)
    ep:RegisterForClicks("LeftButtonUp")

    AttachPingRing(ep, 28)

    -- Leave Blizzard's native World Map icon visible underneath; ring + badge + tooltip frame it
    local tex = ep:CreateTexture(nil, "OVERLAY")
    ApplyPinIconTexture(tex, PIN_ACTION_ICONS.COMPLETE)
    tex:SetAllPoints()
    tex:Hide()
    ep.tex = tex

    ep.orderBadge = CreatePinOrderBadge(ep)

    ep:SetScript("OnClick", function(self)
        if self.questID and self.questID > 0 then
            FP:FocusQuestByID(self.questID, true)
        elseif self.stepData and FP.FocusTrackerStep then
            FP:FocusTrackerStep(self.stepData)
        end
    end)

    ep:SetScript("OnEnter", function(self)
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) and self.questTitle and self.questTitle ~= "" then
            local L = FP.L or {}
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.stepData and self.stepData.action == "TRAIN" then
                GameTooltip:SetText(self.questTitle, 0.45, 0.85, 1.0)
            else
                GameTooltip:SetText(self.questTitle, self.isReady and 1 or 0, self.isReady and 0.84 or 1, self.isReady and 0.12 or 0.59)
            end
            if self.orderIndex then
                GameTooltip:AddLine(string.format(L["TRAJ_STEP_ORDER"] or "Path step #%d", self.orderIndex), 0.35, 0.90, 1.0)
            end
            if self.objLines then
                for _, line in ipairs(self.objLines) do
                    GameTooltip:AddLine(" - " .. tostring(line), 0.9, 0.9, 0.9, true)
                end
            end
            local r, g, b = FP:GetAccentColor()
            if self.stepData and self.stepData.action == "TRAIN" then
                GameTooltip:AddLine(L["TRAJ_TRAIN_CLICK_TIP"] or "Click pin to set arrow to this trainer.", r, g, b, true)
            else
                GameTooltip:AddLine(L["TRAJ_PIN_CLICK_TIP"] or "Click pin to target this quest and update trajectory.", r, g, b, true)
            end
            GameTooltip:Show()
        end
    end)
    ep:SetScript("OnLeave", function()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
    end)

    extraPins[index] = ep
    return ep
end

local ProjectPinCoordsToMap

local function AppendDynamicTrainStopToMap(proxyParent, currentMapID, w, h, activeExtraPins, stops, activePin)
    if not (FP.activeRoute and FP.activeRoute.steps and ProjectPinCoordsToMap) then return end
    if #stops >= 8 then return end
    if activePin and activePin:IsShown() and activePin.action == "TRAIN" then
        return
    end

    for _, s in ipairs(FP.activeRoute.steps) do
        if s.isDynamicTrain and s.mapID and s.x and s.y then
            local nx = (s.x > 1 or s.y > 1) and (s.x / 100) or s.x
            local ny = (s.x > 1 or s.y > 1) and (s.y / 100) or s.y
            local px, py = ProjectPinCoordsToMap(currentMapID, s.mapID, nx, ny)
            if px and py and px > 0.02 and px < 0.98 and py > 0.02 and py < 0.98 then
                local ep = GetOrCreateExtraPin(#activeExtraPins + 1, proxyParent)
                ep:ClearAllPoints()
                ep:SetPoint("CENTER", proxyParent, "TOPLEFT", px * w, -py * h)
                ep:SetSize(22, 22)
                if ep.tex then
                    ApplyPinIconTexture(ep.tex, PIN_ACTION_ICONS.TRAIN)
                    ep.tex:Show()
                end
                ep.questID = nil
                ep.stepData = s
                ep.questTitle = s.pinTitle or s.text
                ep.objLines = s.objectivesList
                ep.isReady = true
                ep.x = px
                ep.y = py
                ep.canvasNormX = px
                ep.canvasNormY = py
                SetPingRingColor(ep, "TRAIN")
                if ep.pingAnim then ep.pingAnim:Play() end
                ep:Show()
                activeExtraPins[#activeExtraPins + 1] = ep
                stops[#stops + 1] = {
                    x = px,
                    y = py,
                    pin = ep,
                    action = "TRAIN",
                    isReady = true,
                }
            end
            break
        end
    end
end

ProjectPinCoordsToMap = function(viewMapID, pinMapID, normX, normY)
    if not IsSafeNum(viewMapID) or not IsSafeNum(pinMapID)
        or not IsSafeNum(normX) or not IsSafeNum(normY) then
        return nil, nil
    end
    local px, py
    if viewMapID == pinMapID then
        px, py = normX, normY
    elseif IsCrossZoneProjEnabled() then
        px, py = ProjectTargetToPlayerMap(viewMapID, pinMapID, normX, normY)
    end
    if px and py and px >= 0 and px <= 1 and py >= 0 and py <= 1 then
        return px, py
    end
    return nil, nil
end

local function UpdateExtraZonePinsAndTrails(proxyParent, currentMapID, w, h)
    HideExtraZonePins()
    SetPinOrderNumber(pinFrame, nil, false)

    local highlightsOn = IsMapPinsEnabled()
    local trailsOn = IsTrajectoriesEnabled()

    local primaryHasBlizzardPOI = false
    local mapQuests
    if proxyParent and currentMapID and C_QuestLog and C_QuestLog.GetQuestsOnMap then
        local ok, res = pcall(C_QuestLog.GetQuestsOnMap, currentMapID)
        if ok and type(res) == "table" then
            mapQuests = {}
            for _, info in ipairs(res) do
                mapQuests[#mapQuests + 1] = info
            end
        end
    end
    if proxyParent and currentMapID and C_TaskQuest and C_TaskQuest.GetQuestsOnMap then
        local ok, tRes = pcall(C_TaskQuest.GetQuestsOnMap, currentMapID)
        if ok and type(tRes) == "table" and #tRes > 0 then
            mapQuests = mapQuests or {}
            for _, info in ipairs(tRes) do
                mapQuests[#mapQuests + 1] = info
            end
        end
    end

    local primaryShown = pinFrame and pinFrame:IsShown() and pinFrame.shownMapID == currentMapID
        and pinFrame.canvasNormX and pinFrame.canvasNormY

    if mapQuests and primaryShown then
        for _, info in ipairs(mapQuests) do
            local qid = type(info) == "table" and (info.questID or info.questId) or nil
            if type(info) == "table" and IsSafeNum(info.x) and IsSafeNum(info.y) and (info.x ~= 0 or info.y ~= 0) then
                local closeCoords = math.abs(pinFrame.canvasNormX - info.x) < 0.015
                    and math.abs(pinFrame.canvasNormY - info.y) < 0.015
                local sameQuestClose = waypointQuestID and qid == waypointQuestID
                    and math.abs(pinFrame.canvasNormX - info.x) < 0.025
                    and math.abs(pinFrame.canvasNormY - info.y) < 0.025
                if closeCoords or sameQuestClose then
                    primaryHasBlizzardPOI = true
                    break
                end
            end
        end
    end

    if pinFrame and pinFrame.tex then
        local act = pinFrame.action
        local keepCustomIcon = (act == "ACCEPT" or act == "TRAIN" or act == "FLY" or act == "SET_HEARTH" or act == "USE_HEARTH")
        if primaryHasBlizzardPOI and not keepCustomIcon then
            pinFrame.tex:Hide()
        else
            pinFrame.tex:Show()
        end
    end

    if not proxyParent or not currentMapID or (not highlightsOn and not trailsOn) then
        HideTrails()
        return
    end

    local pinByQuestID = {}
    local activeExtraPins = {}

    if mapQuests then
        local pMapID, px, py = GetPlayerPosNorm()
        local refMap = pMapID or currentMapID
        local refX100 = (px and px * 100) or 50
        local refY100 = (py and py * 100) or 50

        -- Keep one best (non-indicator, closest) POI per questID so multi-area quests never spawn duplicate trail stops
        local bestByQuestID = {}
        for _, info in ipairs(mapQuests) do
            local qid = type(info) == "table" and (info.questID or info.questId) or nil
            if type(info) == "table" and IsSafeNum(qid) and IsSafeNum(info.x) and IsSafeNum(info.y)
                and (info.x ~= 0 or info.y ~= 0) then
                local isInd = (info.isMapIndicatorQuest == true)
                local skipSameAsPrimary = primaryShown and (
                    (math.abs(pinFrame.canvasNormX - info.x) < 0.015 and math.abs(pinFrame.canvasNormY - info.y) < 0.015)
                    or (waypointQuestID and qid == waypointQuestID)
                )
                if not skipSameAsPrimary then
                    local distScore
                    if FP.ComputeWorldDistanceYards then
                        distScore = FP:ComputeWorldDistanceYards(refMap, refX100, refY100, currentMapID, info.x * 100, info.y * 100)
                    end
                    if not distScore then
                        local dx = (info.x * 100) - refX100
                        local dy = (info.y * 100) - refY100
                        distScore = math.sqrt(dx * dx + dy * dy) * 30
                    end
                    local prev = bestByQuestID[qid]
                    if not prev or (prev.isInd and not isInd) or (prev.isInd == isInd and distScore < prev.dist) then
                        bestByQuestID[qid] = {
                            questID = qid,
                            x       = info.x,
                            y       = info.y,
                            isInd   = isInd,
                            dist    = distScore,
                        }
                    end
                end
            end
        end

        local bestList = {}
        for _, entry in pairs(bestByQuestID) do
            bestList[#bestList + 1] = entry
        end
        table.sort(bestList, function(a, b)
            if math.abs((a.dist or 0) - (b.dist or 0)) > 1 then
                return (a.dist or 0) < (b.dist or 0)
            end
            return a.questID < b.questID
        end)

        local pinIdx = 0
        for _, entry in ipairs(bestList) do
            pinIdx = pinIdx + 1
            if pinIdx > 15 then break end

            local qid = entry.questID
            local isReady = IsQuestReadyCompat(qid)
            local qTitle = GetQuestTitleCompat(qid)

            local objLines = {}
            if C_QuestLog.GetQuestObjectives then
                local oOk, objs = pcall(C_QuestLog.GetQuestObjectives, qid)
                if oOk and type(objs) == "table" then
                    for _, obj in ipairs(objs) do
                        if obj and obj.text and not obj.finished then
                            objLines[#objLines + 1] = obj.text
                        end
                    end
                end
            end

            local ep = GetOrCreateExtraPin(pinIdx, proxyParent)
            ep.questID = qid
            ep.x = entry.x
            ep.y = entry.y
            ep.isReady = isReady
            ep.orderIndex = nil
            ep.questTitle = qTitle or ("Quest " .. qid)
            ep.objLines = objLines

            local actionType = isReady and "TURNIN" or "COMPLETE"
            if ep.tex then ep.tex:Hide() end
            SetPingRingColor(ep, actionType)

            PositionPinOnCanvas(ep, proxyParent, w, h, entry.x, entry.y, 24)
            if highlightsOn then
                ep:Show()
                if ep.pingAnim and not ep.pingAnim:IsPlaying() then
                    ep.pingAnim:Play()
                end
            end

            pinByQuestID[qid] = ep
            activeExtraPins[#activeExtraPins + 1] = ep
        end
    end

    if not trailsOn then
        HideTrails()
        SetPinOrderNumber(pinFrame, nil, false)
        return
    end

    -- Detect player position on displayed map (works on both zone maps and parent continent maps)
    local playerX, playerY
    if IsSafeNum(currentMapID) and C_Map and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        if pos then
            local px, py = pos:GetXY()
            if IsSafeNum(px) and IsSafeNum(py) and px > 0 and px < 1 and py > 0 and py < 1 then
                playerX, playerY = px, py
                lastTrailPlayerX, lastTrailPlayerY = px, py
            end
        end
    end

    -- Build ordered trajectory stops on currentMapID
    local stops = {}
    local function AddStopIfDistinct(x, y, questID, isReady, pinObj)
        if not x or not y then return false end
        for _, existing in ipairs(stops) do
            if math.abs(existing.x - x) < 0.008 and math.abs(existing.y - y) < 0.008 then
                return false
            end
        end
        stops[#stops + 1] = {
            x       = x,
            y       = y,
            questID = questID,
            isReady = isReady and true or false,
            pin     = pinObj,
        }
        return true
    end

    -- Stop #1: Primary active target if it projects onto currentMapID
    if pinFrame and pinFrame:IsShown() and pinFrame.shownMapID == currentMapID
        and pinFrame.canvasNormX and pinFrame.canvasNormY then
        pinFrame.isReady = (pinFrame.action == "TURNIN")
        AddStopIfDistinct(pinFrame.canvasNormX, pinFrame.canvasNormY, waypointQuestID, pinFrame.isReady, pinFrame)
    elseif FP.selectedQuestID and pinByQuestID[FP.selectedQuestID] then
        local sep = pinByQuestID[FP.selectedQuestID]
        AddStopIfDistinct(sep.x, sep.y, sep.questID, sep.isReady, sep)
    end

    local isGuideSequence = FP.activeRoute and FP.activeRoute.routeId ~= FP.QUEST_SYNC_ROUTE_ID
        and FP.currentStepIndex and (not FP.selectedQuestID or (FP.activeRoute.steps[FP.currentStepIndex] and FP.activeRoute.steps[FP.currentStepIndex].questId == FP.selectedQuestID))

    if isGuideSequence and FP.activeRoute.steps then
        local steps = FP.activeRoute.steps
        for scan = FP.currentStepIndex, math.min(#steps, FP.currentStepIndex + 12) do
            local s = steps[scan]
            if s and s.mapID == currentMapID and s.x and s.y and (not FP.PassesFilter or FP:PassesFilter(s)) then
                local nx, ny = (s.x > 1 or s.y > 1) and (s.x / 100) or s.x, (s.x > 1 or s.y > 1) and (s.y / 100) or s.y
                local matchPin = (s.questId and pinByQuestID[s.questId]) or nil
                AddStopIfDistinct(nx, ny, s.questId, s.action == "TURNIN", matchPin)
                if #stops >= 8 then break end
            end
        end
    else
        -- Nearest-neighbor chain over watched / active / zone quests starting from Stop #1 (or player)
        local watched = GetWatchedQuestIDSet()
        local pool = {}
        local seenPins = {}

        local function EnqueuePinCandidate(ep)
            if not ep or seenPins[ep] then return end
            seenPins[ep] = true
            pool[#pool + 1] = ep
        end

        for qid in pairs(watched) do
            if pinByQuestID[qid] then
                EnqueuePinCandidate(pinByQuestID[qid])
            else
                local wx, wy = ResolveQuestCoordsOnMap(qid, currentMapID)
                if wx and wy then
                    pool[#pool + 1] = {
                        x       = wx,
                        y       = wy,
                        questID = qid,
                        isReady = IsQuestReadyCompat(qid),
                    }
                end
            end
        end

        for _, ep in ipairs(activeExtraPins) do
            EnqueuePinCandidate(ep)
        end

        AppendDynamicTrainStopToMap(proxyParent, currentMapID, w, h, activeExtraPins, stops, pinFrame)

        local curX = (#stops > 0 and stops[#stops].x) or playerX or 0.5
        local curY = (#stops > 0 and stops[#stops].y) or playerY or 0.5

        while #stops < 8 and #pool > 0 do
            local bestIdx, bestScore = nil, nil
            for idx, cand in ipairs(pool) do
                local dx, dy = cand.x - curX, cand.y - curY
                local dist = math.sqrt(dx * dx + dy * dy)
                if watched[cand.questID] then dist = dist * 0.75 end
                if cand.isReady then dist = dist * 0.85 end
                if not bestScore or dist < bestScore then
                    bestScore = dist
                    bestIdx = idx
                end
            end
            if not bestIdx then break end
            local picked = table.remove(pool, bestIdx)
            local added = AddStopIfDistinct(picked.x, picked.y, picked.questID, picked.isReady, picked.questID and pinByQuestID[picked.questID] or nil)
            if added then
                curX, curY = picked.x, picked.y
            end
        end
    end

    local customX, customY = ProjectPinCoordsToMap(currentMapID, customWp.mapID, customWp.x, customWp.y)
    local hasCustomSeg = customX and customY and playerX and playerY

    if (#stops == 0 or (not playerX and #stops < 2)) and not hasCustomSeg then
        HideTrails()
        if stops[1] and stops[1].pin then
            PlaceStopOrderBadges({ stops[1] }, activeExtraPins, playerX, playerY, customX, customY, false, w, h)
        end
        return
    end

    local layer = EnsureTrailLayer(proxyParent)
    local lineIdxRef = { 0 }
    local dotIdxRef = { 0 }

    -- Leg 1: Player -> Stop #1 (bright emerald)
    if playerX and playerY and stops[1] then
        DrawTrajectorySegment(layer, w, h, 1, playerX, playerY, stops[1].x, stops[1].y, 0, 1, 0.59, true, lineIdxRef, dotIdxRef)
    end

    -- Subsequent legs: Stop #k -> Stop #k+1 (gold for turn-in, cyan for quest objective)
    for k = 1, #stops - 1 do
        local a = stops[k]
        local b = stops[k + 1]
        local lr, lg, lb = 0.30, 0.88, 1.0
        if b.isReady then
            lr, lg, lb = 1.0, 0.84, 0.15
        end
        local isPrimarySub = (not playerX and k == 1)
        DrawTrajectorySegment(layer, w, h, 1, a.x, a.y, b.x, b.y, lr, lg, lb, isPrimarySub, lineIdxRef, dotIdxRef)
    end

    -- Custom Waypoint trajectory: Player -> Custom Waypoint (distinct bright magenta)
    if hasCustomSeg then
        DrawTrajectorySegment(layer, w, h, 1, playerX, playerY, customX, customY, CUSTOM_COLOR_R, CUSTOM_COLOR_G, CUSTOM_COLOR_B, true, lineIdxRef, dotIdxRef)
    end

    for i = lineIdxRef[1] + 1, #trailLines do
        trailLines[i]:Hide()
    end
    for i = dotIdxRef[1] + 1, #trailDots do
        trailDots[i]:Hide()
    end

    PlaceStopOrderBadges(stops, activeExtraPins, playerX, playerY, customX, customY, hasCustomSeg, w, h)

    if lineIdxRef[1] > 0 then
        layer:Show()
    else
        layer:Hide()
    end
end

local function EnsureWorldMapHooks()
    -- Read-only polling via questSelectionFrame replaces hooks to guarantee zero taint
    worldMapHooked = true
end

function FP:InitWorldMapHooks()
    EnsureWorldMapHooks()
end

local function EnsurePinFrame()
    if pinFrame then return end
    pinFrame = CreateFrame("Frame", "NexusKitMapPin", mapCanvasProxy)
    pinFrame:SetSize(24, 24)
    pinFrame:EnableMouse(true)

    AttachPingRing(pinFrame, 36)

    local tex = pinFrame:CreateTexture(nil, "OVERLAY")
    ApplyPinIconTexture(tex, PIN_ACTION_ICONS.GOTO)
    tex:SetAllPoints()
    pinFrame.tex = tex

    pinFrame.orderBadge = CreatePinOrderBadge(pinFrame)

    local label = pinFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ApplyOutlineFont(label, 10)
    label:SetPoint("TOP", pinFrame, "BOTTOM", 0, -2)
    local hr, hg, hb = FP:GetHudTextColor()
    label:SetTextColor(hr, hg, hb, 1)
    label:SetJustifyH("CENTER")
    label:SetWidth(320)
    label:SetWordWrap(false)
    pinFrame.label = label

    pinFrame:SetScript("OnEnter", function(self)
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) and self.title and self.title ~= "" then
            local ar, ag, ab = FP:GetAccentColor()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(FP.L["TRACKER_TITLE"] or "NexusKit", ar, ag, ab)
            GameTooltip:AddLine(self.title, 1, 1, 1, true)
            if FP.selectedQuestID then
                GameTooltip:AddLine(FP.L["TRAJ_ACTIVE_TAG"] or "[Selected Trajectory]", 0.35, 0.90, 1.0)
            end
            GameTooltip:Show()
        end
    end)
    pinFrame:SetScript("OnLeave", function()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
    end)

    pinFrame:Hide()
end

function FP:UpdateMapPin(mapID, normX, normY, title, action)
    if not WorldMapFrame then return end
    EnsurePinFrame()
    EnsureWorldMapHooks()

    pinFrame.mapID = mapID
    pinFrame.x = normX
    pinFrame.y = normY
    pinFrame.title = title or ""
    pinFrame.action = action or "GOTO"
    pinFrame.isReady = (pinFrame.action == "TURNIN")
    ApplyPinIconTexture(pinFrame.tex, PIN_ACTION_ICONS[pinFrame.action] or PIN_ACTION_ICONS.GOTO)
    SetPingRingColor(pinFrame, pinFrame.action)
    local hr, hg, hb = FP:GetHudTextColor()
    pinFrame.label:SetTextColor(hr, hg, hb, 1)
    pinFrame.label:SetText(title or "")

    FP:RepositionMapPin()
end

local function HidePrimaryMapPin(clearTarget)
    if pinFrame then
        if pinFrame.pingAnim then pinFrame.pingAnim:Stop() end
        if pinFrame.orderBadge then pinFrame.orderBadge:Hide() end
        pinFrame.shownMapID = nil
        pinFrame.canvasNormX = nil
        pinFrame.canvasNormY = nil
        pinFrame:Hide()
        if clearTarget then
            pinFrame.mapID = nil
        end
    end
end

local function HideCustomMapPin()
    if customMapPin then
        if customMapPin.pingAnim then customMapPin.pingAnim:Stop() end
        customMapPin.canvasNormX = nil
        customMapPin.canvasNormY = nil
        customMapPin:Hide()
    end
end

local function EnsureCustomMapPin()
    if customMapPin then return customMapPin end
    customMapPin = CreateFrame("Button", "NexusKitCustomMapPin", mapCanvasProxy)
    customMapPin:SetSize(20, 20)
    customMapPin:EnableMouse(true)
    customMapPin:RegisterForClicks("RightButtonUp")

    AttachPingRing(customMapPin, 30)
    if customMapPin.pingRing then
        customMapPin.pingRing:SetVertexColor(CUSTOM_COLOR_R, CUSTOM_COLOR_G, CUSTOM_COLOR_B, 0.95)
    end

    local tex = customMapPin:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_3")
    tex:SetTexCoord(0, 1, 0, 1)
    tex:SetAllPoints()
    customMapPin.tex = tex

    customMapPin:SetScript("OnClick", function(_, button)
        if button == "RightButton" and FP.ClearCustomWaypoint then
            FP:ClearCustomWaypoint()
        end
    end)
    customMapPin:SetScript("OnEnter", function(self)
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) and customWp.mapID then
            local L = FP.L or {}
            local zName = GetCachedMapName(customWp.mapID) or ""
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["CUSTOM_WAYPOINT_TAG"] or "Custom Waypoint", 1, 0.38, 1)
            if customWp.title and customWp.title ~= "" then
                GameTooltip:AddLine(customWp.title, 1, 1, 1, true)
            end
            GameTooltip:AddLine(string.format("%s (%.1f, %.1f)", zName, (customWp.x or 0) * 100, (customWp.y or 0) * 100), 0.9, 0.85, 1)
            GameTooltip:AddLine(L["CUSTOM_ARROW_TOOLTIP"] or "Right-click or /nk clear to remove this waypoint.", 1, 0.65, 1, true)
            GameTooltip:Show()
        end
    end)
    customMapPin:SetScript("OnLeave", function()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
    end)
    customMapPin:Hide()
    return customMapPin
end

function FP:RepositionMapPin()
    local okGeo, _, w, h = SyncMapProxyGeometry()
    if not okGeo or not w or not h then
        mapOverlayRoot:Hide()
        HidePrimaryMapPin(false)
        HideCustomMapPin()
        HideExtraZonePins()
        HideTrails()
        if self.HideZonePOIs then self:HideZonePOIs() end
        if WorldMapFrame and not IsForbiddenObj(WorldMapFrame) and WorldMapFrame:IsShown() then
            ScheduleDeferredMapRefresh(0.05)
        end
        return
    end

    mapOverlayRoot:Show()
    local currentMapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()

    if pinFrame and pinFrame.mapID and pinFrame.x and pinFrame.y and IsSafeNum(currentMapID) then
        local pinX, pinY = ProjectPinCoordsToMap(currentMapID, pinFrame.mapID, pinFrame.x, pinFrame.y)
        if pinX and pinY then
            PositionPinOnCanvas(pinFrame, mapCanvasProxy, w, h, pinX, pinY, 40)
            pinFrame.shownMapID = currentMapID
            pinFrame:Show()
            if pinFrame.pingAnim and not pinFrame.pingAnim:IsPlaying() then
                pinFrame.pingAnim:Play()
            end
        else
            HidePrimaryMapPin(false)
        end
    else
        HidePrimaryMapPin(false)
    end

    if customWp.mapID and customWp.x and customWp.y and IsSafeNum(currentMapID) then
        local cPinX, cPinY = ProjectPinCoordsToMap(currentMapID, customWp.mapID, customWp.x, customWp.y)
        if cPinX and cPinY then
            local cp = EnsureCustomMapPin()
            PositionPinOnCanvas(cp, mapCanvasProxy, w, h, cPinX, cPinY, 60)
            cp:Show()
            if cp.pingAnim and not cp.pingAnim:IsPlaying() then
                cp.pingAnim:Play()
            end
        else
            HideCustomMapPin()
        end
    else
        HideCustomMapPin()
    end

    UpdateExtraZonePinsAndTrails(mapCanvasProxy, currentMapID, w, h)
    if self.RenderZonePOIsOnMap then
        self:RenderZonePOIsOnMap(mapCanvasProxy, currentMapID, w, h, mapOverlayRoot)
    end
end

function FP:HideMapPin()
    HidePrimaryMapPin(true)
    if WorldMapFrame and WorldMapFrame:IsShown() then
        self:RepositionMapPin()
    else
        HideCustomMapPin()
        HideExtraZonePins()
        HideTrails()
        if self.HideZonePOIs then self:HideZonePOIs() end
    end
end

-------------------------------------------------------------------------------
-- Public API  (accepts x, y in [0, 100] map percentage scale)
-------------------------------------------------------------------------------
function FP:SetWaypoint(mapID, x, y, title, action, questID, keepBlizzardTrack, allowProximity)
    if not mapID or not x or not y then
        self:ClearWaypoint()
        return
    end

    -- Convert [0, 100] step coordinates into normalized [0, 1]
    local normX = (x > 1 or y > 1) and (x / 100) or x
    local normY = (x > 1 or y > 1) and (y / 100) or y

    waypointMapID = mapID
    waypointX = normX
    waypointY = normY
    waypointTitle = title or ""
    waypointAction = action
    waypointQuestID = questID

    proxState.allow = (allowProximity == true)
        or (IsSafeNum(questID) and questID > 0 and (action == "COMPLETE" or action == "TURNIN")
            and ((self.IsQuestSyncActive and self:IsQuestSyncActive()) or self.selectedQuestID == questID))
    if proxState.qid ~= questID then
        proxState.qid = questID
        proxState.mapID = nil
        proxState.x = nil
        proxState.y = nil
        proxState.lastAt = (GetTime and GetTime()) or 0
    end

    self:ApplyArrowScale()
    self:RefreshArrowLockVisual()
    if ShouldHideArrow() then
        arrow:Hide()
        HideMinimapPin()
    else
        arrow:Show()
    end

    self:UpdateMapPin(mapID, normX, normY, title, action)
end

function FP:ClearWaypoint()
    waypointMapID = nil
    waypointX = nil
    waypointY = nil
    waypointTitle = nil
    waypointAction = nil
    waypointQuestID = nil
    proxState.allow = false
    proxState.qid = nil
    proxState.mapID = nil
    proxState.x = nil
    proxState.y = nil
    arrow:Hide()
    HideMinimapPin()

    self:HideMapPin()
end

-------------------------------------------------------------------------------
-- Independent Custom Coordinate Waypoint & Real-time Coordinates Toggle
-------------------------------------------------------------------------------
local function ParseCustomWaypointArgs(input)
    local s = tostring(input or ""):match("^%s*(.-)%s*$")
    if s == "" then return "usage" end

    local low = s:lower()
    if low == "clear" or low == "off" or low == "reset" or low == "none" or low == "stop" then
        return "clear"
    end

    -- Turn ", " separators into space and decimal commas "42,5" into "42.5"
    s = s:gsub(",%s+", " "):gsub("(%d),(%d)", "%1.%2")

    local mapStr, xStr, yStr, label = s:match("^#(%d+)[:%s]+([%d%.]+)[%s,]+([%d%.]+)%s*(.*)$")
    if not xStr then
        local m2, x2, y2, l2 = s:match("^(%d+)%s+([%d%.]+)[%s,]+([%d%.]+)%s*(.*)$")
        if m2 and tonumber(m2) and tonumber(m2) >= 100 then
            mapStr, xStr, yStr, label = m2, x2, y2, l2
        end
    end
    if not xStr then
        xStr, yStr, label = s:match("^([%d%.]+)[%s,]+([%d%.]+)%s*(.*)$")
    end

    local x = tonumber(xStr)
    local y = tonumber(yStr)
    if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
        return "usage"
    end

    local explicitMap = mapStr and tonumber(mapStr) or nil
    label = (label or ""):match("^%s*(.-)%s*$")
    if label == "" then label = nil end
    return "set", x, y, label, explicitMap
end

function FP:SetCustomWaypoint(x, y, title, mapID)
    if not IsSafeNum(x) or not IsSafeNum(y) then
        self:Print(self.L["CUSTOM_WAYPOINT_USAGE"] or "Usage: /nk way <x> <y> [label]")
        return false
    end

    local targetMapID = IsSafeNum(mapID) and mapID
        or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
    if not IsSafeNum(targetMapID) then
        self:Print(self.L["CUSTOM_WAYPOINT_USAGE"] or "Unable to detect current map for coordinates.")
        return false
    end

    local normX = (x > 1 or y > 1) and (x / 100) or x
    local normY = (x > 1 or y > 1) and (y / 100) or y
    normX = math.max(0, math.min(1, normX))
    normY = math.max(0, math.min(1, normY))

    local displayTitle
    if title and title ~= "" then
        displayTitle = string.format("%s (%.1f, %.1f)", title, normX * 100, normY * 100)
    else
        displayTitle = string.format("%.1f, %.1f", normX * 100, normY * 100)
    end

    customWp.mapID = targetMapID
    customWp.x = normX
    customWp.y = normY
    customWp.title = displayTitle

    if NexusKitCharDB then
        NexusKitCharDB.customWaypoint = {
            mapID = targetMapID,
            x = normX,
            y = normY,
            title = displayTitle,
        }
    end

    customArrow.accum = UPDATE_INTERVAL
    self:RefreshCustomWaypointUI()

    local zoneName = GetCachedMapName(targetMapID) or ""
    self:Print(string.format(self.L["CUSTOM_WAYPOINT_SET"] or "|cffff59ff[WP]|r %s (%s)", displayTitle, zoneName))
    return true
end

function FP:SetCustomWaypointFromInput(input)
    local mode, x, y, label, mapID = ParseCustomWaypointArgs(input)
    if mode == "clear" then
        self:ClearCustomWaypoint()
    elseif mode == "set" then
        self:SetCustomWaypoint(x, y, label, mapID)
    else
        self:Print(self.L["CUSTOM_WAYPOINT_USAGE"] or "Usage: /nk way <x> <y> [label]  (e.g. /nk way 45.2 63.8)  or /nk clear")
    end
end

function FP:ClearCustomWaypoint(silent)
    local hadCustom = customWp.mapID ~= nil
    customWp.mapID = nil
    customWp.x = nil
    customWp.y = nil
    customWp.title = nil
    if NexusKitCharDB then
        NexusKitCharDB.customWaypoint = nil
    end
    customArrow:Hide()
    HideCustomMinimapPin()
    HideCustomMapPin()
    self:RefreshCoordsUI()
    if self.RepositionMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
        self:RepositionMapPin()
    end
    if not silent and hadCustom then
        self:Print(self.L["CUSTOM_WAYPOINT_CLEARED"] or "Custom waypoint cleared.")
    end
end

function FP:TogglePlayerCoords()
    if not (NexusKitDB and NexusKitDB.settings) then return end
    local enabled = not IsPlayerCoordsEnabled()
    NexusKitDB.settings.showPlayerCoords = enabled
    self:RefreshCoordsUI()
    if self.RefreshSettingsUI then
        self:RefreshSettingsUI()
    end
    self:Print(enabled
        and (self.L["COORDS_ENABLED"] or "Real-time coordinates enabled.")
        or (self.L["COORDS_DISABLED"] or "Real-time coordinates disabled."))
end

function FP:SetSuperTrackedQuestSafe(questID)
    if not questID or questID <= 0 then return end
    self.selectedQuestID = questID
end

function FP:ClearSelectedQuestOverride()
    self.selectedQuestID = nil
end

function FP:FocusQuestByID(questID, keepBlizzardTrack)
    if not questID or questID <= 0 then return false end
    self.selectedQuestID = questID

    if self.IsQuestSyncActive and self:IsQuestSyncActive() and self.RebuildQuestSyncRoute then
        self:RebuildQuestSyncRoute()
        local route = self.activeRoute
        if route and route.steps then
            for i, s in ipairs(route.steps) do
                if s.questId == questID then
                    self.currentStepIndex = i
                    lastRouteStepIndex = i
                    if self.RefreshTracker then self:RefreshTracker() end
                    if s.mapID and s.x and s.y then
                        self:SetWaypoint(s.mapID, s.x, s.y, ResolveStepWaypointTitle(s), s.action, questID, keepBlizzardTrack, true)
                        return true
                    end
                end
            end
        end
    end

    local mapID, nx, ny, title, action = ResolveQuestTargetByID(questID)
    if mapID and nx and ny then
        self:SetWaypoint(mapID, nx, ny, title, action, questID, keepBlizzardTrack, true)
        return true
    end
    self:RepositionMapPin()
    return false
end

function FP:FocusTrackerStep(step)
    if not step then return end
    self.selectedQuestID = step.questId
    local inLog = step.questId and self.IsQuestInLog and self:IsQuestInLog(step.questId)
    if inLog then
        self:SetSuperTrackedQuestSafe(step.questId)
    end
    if self.IsQuestSyncActive and self:IsQuestSyncActive() and step.questId then
        if self:FocusQuestByID(step.questId, inLog) then
            return
        end
        if not (step.mapID and step.x and step.y) then
            self:ClearWaypoint()
            return
        end
    end
    if step.mapID and step.x and step.y then
        self:SetWaypoint(step.mapID, step.x, step.y, ResolveStepWaypointTitle(step), step.action, step.questId, inLog)
    elseif step.questId then
        self:FocusQuestByID(step.questId, inLog)
    end
end

-------------------------------------------------------------------------------
-- Step-changed & Selected-Quest Reactive Wiring
-------------------------------------------------------------------------------
local function OnStepChanged(step)
    if not step and FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps then
        step = FP.activeRoute.steps[FP.currentStepIndex]
    end

    -- Clear external selected-quest override when step index genuinely advances or quest leaves log
    local stepChanged = (FP.currentStepIndex ~= lastRouteStepIndex)
    lastRouteStepIndex = FP.currentStepIndex

    if FP.selectedQuestID then
        local stillInLog = FP.IsQuestInLog and FP:IsQuestInLog(FP.selectedQuestID)
        local alreadyDone = FP.IsQuestDone and FP:IsQuestDone(FP.selectedQuestID)
        if not stillInLog or alreadyDone then
            FP.selectedQuestID = nil
        elseif not stepChanged or (FP.IsQuestSyncActive and FP:IsQuestSyncActive()) then
            if FP:FocusQuestByID(FP.selectedQuestID, true) then
                return
            end
            if FP.activeRoute and FP.currentStepIndex and FP.activeRoute.steps then
                step = FP.activeRoute.steps[FP.currentStepIndex] or step
            end
        else
            FP.selectedQuestID = nil
        end
    end

    if not step then
        FP:ClearWaypoint()
        return
    end

    if step.mapID and step.x and step.y then
        local isSync = FP.IsQuestSyncActive and FP:IsQuestSyncActive()
        FP:SetWaypoint(step.mapID, step.x, step.y, ResolveStepWaypointTitle(step), step.action, step.questId, nil, isSync)
    elseif step.questId then
        local mapID, nx, ny, title, action = ResolveQuestTargetByID(step.questId)
        if mapID and nx and ny then
            FP:SetWaypoint(mapID, nx, ny, ResolveStepWaypointTitle(step, title), action or step.action, step.questId, nil, true)
        else
            FP:ClearWaypoint()
        end
    else
        FP:ClearWaypoint()
    end
end

if FP.RegisterStepChangedCallback then
    FP:RegisterStepChangedCallback(OnStepChanged)
else
    FP.OnStepChangedCallbacks = FP.OnStepChangedCallbacks or {}
    table.insert(FP.OnStepChangedCallbacks, OnStepChanged)
end

local function ReevaluateActiveQuestProximity(force)
    local qid = waypointQuestID
    if not qid or qid <= 0 or not proxState.allow or not FP.ResolveQuestDestination then
        return
    end
    if waypointAction ~= "COMPLETE" and waypointAction ~= "TURNIN" then
        return
    end
    if FP.IsQuestInLog and not FP:IsQuestInLog(qid) then
        return
    end

    local playerMapID, px, py = GetPlayerPosNorm()
    if not playerMapID or not px or not py then
        return
    end

    local now = (GetTime and GetTime()) or 0
    if not force and proxState.qid == qid and proxState.mapID == playerMapID and proxState.x and proxState.y then
        local movedSq = ((px - proxState.x) ^ 2) + ((py - proxState.y) ^ 2)
        if movedSq < (0.0035 ^ 2) and (now - (proxState.lastAt or 0)) < 2.0 then
            return
        end
    end

    proxState.qid = qid
    proxState.mapID = playerMapID
    proxState.x = px
    proxState.y = py
    proxState.lastAt = now

    local isReady = IsQuestReadyCompat(qid)
    local wMapID, wx100, wy100 = FP:ResolveQuestDestination(qid, {
        mapID = playerMapID,
        px    = px * 100,
        py    = py * 100,
    }, isReady, {
        livePoll        = true,
        prevMapID       = waypointMapID,
        prevX           = waypointX and (waypointX * 100) or nil,
        prevY           = waypointY and (waypointY * 100) or nil,
        hysteresisPct   = 0.15,
        hysteresisYards = 35,
    })

    if not wMapID or not wx100 or not wy100 then
        return
    end

    local changed = (wMapID ~= waypointMapID)
        or not waypointX or not waypointY
        or math.abs((wx100 / 100) - waypointX) > 0.004
        or math.abs((wy100 / 100) - waypointY) > 0.004
    if not changed then
        return
    end

    local newTitle = waypointTitle
    if FP.IsQuestSyncActive and FP:IsQuestSyncActive() and FP.activeRoute and FP.activeRoute.steps then
        if wMapID ~= waypointMapID and FP.RebuildQuestSyncRoute then
            if FP.InvalidateQuestPOICache then FP:InvalidateQuestPOICache() end
            FP:RebuildQuestSyncRoute()
        end
        for idx, s in ipairs(FP.activeRoute.steps) do
            if s.questId == qid then
                s.mapID = wMapID
                s.x = wx100
                s.y = wy100
                newTitle = ResolveStepWaypointTitle(s, newTitle)
                if FP.selectedQuestID == qid or idx == 1 then
                    FP.currentStepIndex = idx
                    lastRouteStepIndex = idx
                end
                break
            end
        end
        if FP.RefreshTracker then FP:RefreshTracker() end
    end

    FP:SetWaypoint(wMapID, wx100, wy100, newTitle, waypointAction, qid, true, true)
end

local questSelectionFrame = CreateFrame("Frame")
questSelectionFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
questSelectionFrame:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
questSelectionFrame:RegisterEvent("QUEST_LOG_UPDATE")
questSelectionFrame:RegisterEvent("PLAYER_LOGIN")
questSelectionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questSelectionFrame:RegisterEvent("ZONE_CHANGED")
questSelectionFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
questSelectionFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pcall(questSelectionFrame.RegisterEvent, questSelectionFrame, "QUEST_POI_UPDATE")

local selectedQuestHooked = false
local function EnsureQuestLogSelectionHook()
    -- Read-only polling via questSelectionFrame replaces hooks to guarantee zero taint
    selectedQuestHooked = true
end

local lastWorldMapShown = false
local lastObservedMapID = nil
local lastObservedSelQuest = nil
local qSelAccum = 0
questSelectionFrame:SetScript("OnUpdate", function(_, elapsed)
    qSelAccum = qSelAccum + elapsed
    if qSelAccum < 0.12 then return end
    qSelAccum = 0
    local wmShown = WorldMapFrame and not IsForbiddenObj(WorldMapFrame) and WorldMapFrame:IsShown() or false
    if wmShown ~= lastWorldMapShown then
        lastWorldMapShown = wmShown
        ResetMapGeoCache()
        if wmShown then
            FP:RepositionMapPin()
            ScheduleDeferredMapRefresh(0.03)
        else
            mapOverlayRoot:Hide()
            HideExtraZonePins()
            HideTrails()
            if FP.HideZonePOIs then FP:HideZonePOIs() end
        end
    end

    if wmShown and WorldMapFrame.GetMapID then
        local curMap = WorldMapFrame:GetMapID()
        if curMap ~= lastObservedMapID then
            lastObservedMapID = curMap
            ResetMapGeoCache()
            FP:RepositionMapPin()
            ScheduleDeferredMapRefresh(0.03)
        end
    end

    if not InCombatLockdown or not InCombatLockdown() then
        if C_QuestLog and C_QuestLog.GetSelectedQuest then
            local selQ = C_QuestLog.GetSelectedQuest()
            if selQ and selQ > 0 and selQ ~= lastObservedSelQuest then
                lastObservedSelQuest = selQ
                local mapOpen = WorldMapFrame and WorldMapFrame:IsShown()
                local logOpen = QuestLogFrame and QuestLogFrame:IsShown()
                if mapOpen or logOpen then
                    FP:FocusQuestByID(selQ, true)
                end
            end
        end
    end

    if not waypointQuestID or not proxState.allow then return end
    proxState.accum = proxState.accum + elapsed
    if proxState.accum < 0.75 then return end
    proxState.accum = 0
    ReevaluateActiveQuestProximity(false)
end)

questSelectionFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        EnsureQuestLogSelectionHook()
        EnsureWorldMapHooks()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        if FP.InvalidateQuestPOICache then FP:InvalidateQuestPOICache() end
        ReevaluateActiveQuestProximity(true)
        if not IsTrajectoriesEnabled() then
            HideTrails()
            SetPinOrderNumber(pinFrame, nil, false)
        end
        if not IsMinimapTrajectoriesEnabled() then
            if minimapTrailLine then minimapTrailLine:Hide() end
            if customMinimapTrailLine then customMinimapTrailLine:Hide() end
            for _, dot in ipairs(minimapDots) do dot:Hide() end
            for _, dot in ipairs(customMinimapDots) do dot:Hide() end
            if minimapDotsHost and (not minimapPin or not minimapPin:IsShown()) and (not customMinimapPin or not customMinimapPin:IsShown()) then
                minimapDotsHost:Hide()
            end
        end
        if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
        if WorldMapFrame and WorldMapFrame:IsShown() and FP.RepositionMapPin then
            FP:RepositionMapPin()
        end
        return
    end

    if event == "SUPER_TRACKING_CHANGED" then
        if isInternalWaypointSync then return end
        local qid = C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
        if qid and qid > 0 then
            FP:FocusQuestByID(qid, true)
        elseif FP.RepositionMapPin and WorldMapFrame and WorldMapFrame:IsShown() then
            FP:RepositionMapPin()
        end
    elseif event == "QUEST_WATCH_LIST_CHANGED" or event == "QUEST_LOG_UPDATE" or event == "QUEST_POI_UPDATE" then
        if FP.InvalidateQuestPOICache then FP:InvalidateQuestPOICache() end
        if FP.selectedQuestID then
            local stillInLog = FP.IsQuestInLog and FP:IsQuestInLog(FP.selectedQuestID)
            local alreadyDone = FP.IsQuestDone and FP:IsQuestDone(FP.selectedQuestID)
            if not stillInLog or alreadyDone then
                FP.selectedQuestID = nil
            elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_POI_UPDATE" then
                FP:FocusQuestByID(FP.selectedQuestID, true)
            end
        elseif event == "QUEST_POI_UPDATE" and not waypointMapID and FP.activeRoute and FP.currentStepIndex then
            local activeStep = FP.activeRoute.steps and FP.activeRoute.steps[FP.currentStepIndex]
            if activeStep then
                OnStepChanged(activeStep)
            end
        else
            ReevaluateActiveQuestProximity(true)
        end
        if FP.RefreshWaypointsUI then FP:RefreshWaypointsUI() end
        if WorldMapFrame and WorldMapFrame:IsShown() and FP.RepositionMapPin then
            FP:RepositionMapPin()
        end
    end
end)
