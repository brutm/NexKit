-- NexusKit - UI/ReagentTracker.lua
-- Skill-up reagent cache + Loot / Profession Book / Bag highlighting & manual reagent tracking
local addonName, FP = ...

local ACCENT  = { r = 0, g = 1, b = 0.59 }
local TRACKED = { r = 0.25, g = 0.90, b = 1.0 }
local QUEST_KEEP = { r = 1.00, g = 0.68, b = 0.12 }
local SKILL_COLORS = {
    optimal = { r = 1.00, g = 0.55, b = 0.20 },
    medium  = { r = 1.00, g = 0.85, b = 0.15 },
    easy    = { r = 0.20, g = 0.95, b = 0.45 },
}

local DIFF_PRIORITY = { optimal = 3, medium = 2, easy = 1 }

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function NormalizeName(name)
    if not IsSafeStr(name) then return nil end
    return string.lower((name:match("^%s*(.-)%s*$") or ""))
end

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsHighlightEnabled()
    return GetSettings().profHighlightReagents ~= false
end

local function IsTrackedHudEnabled()
    return GetSettings().profShowTrackedHud ~= false
end

local function IsQuestKeepEnabled()
    return GetSettings().warnKeepQuestLoot ~= false
end

local function IsBagTrackButtonsEnabled()
    return GetSettings().profBagTrackButtons ~= false
end

local function EnsureCharTables()
    if type(NexusKitCharDB) ~= "table" then return nil end
    if type(NexusKitCharDB.profSkillReagentsByProf) ~= "table" then
        NexusKitCharDB.profSkillReagentsByProf = {}
    end
    if type(NexusKitCharDB.profAllReagentsByProf) ~= "table" then
        NexusKitCharDB.profAllReagentsByProf = {}
    end
    if type(NexusKitCharDB.trackedReagents) ~= "table" then
        NexusKitCharDB.trackedReagents = {}
    end
    return NexusKitCharDB
end

local function GetItemInfoCompat(item)
    if C_Item and C_Item.GetItemInfo then
        return pcall(C_Item.GetItemInfo, item)
    elseif GetItemInfo then
        return pcall(GetItemInfo, item)
    end
    return false
end

local function GetSafeItemInfo(item)
    if not item then return nil end
    local ok, name, link, quality, iLevel, reqLevel, itemType, itemSubType, stackCount, equipLoc, texture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfoCompat(item)
    if not ok or not name then return nil end
    return {
        name              = name,
        link              = link,
        quality           = quality,
        iLevel            = iLevel,
        reqLevel          = reqLevel,
        itemType          = itemType,
        itemSubType       = itemSubType,
        stackCount        = stackCount,
        equipLoc          = equipLoc,
        texture           = texture,
        sellPrice         = sellPrice,
        classID           = classID,
        subclassID        = subclassID,
        bindType          = bindType,
        expacID           = expacID,
        setID             = setID,
        isCraftingReagent = (isCraftingReagent == true),
    }
end

local function GetItemIconCompat(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemIconByID and IsSafeNum(item) then
        local ok, tex = pcall(C_Item.GetItemIconByID, item)
        if ok and tex then return tex end
    elseif GetItemIcon and IsSafeNum(item) then
        local ok, tex = pcall(GetItemIcon, item)
        if ok and tex then return tex end
    end
    local info = GetSafeItemInfo(item)
    return info and info.texture or nil
end

local function GetItemCountCompat(item, includeBank)
    if not item then return 0 end
    if C_Item and C_Item.GetItemCount then
        local ok, c = pcall(C_Item.GetItemCount, item, includeBank)
        if ok and IsSafeNum(c) then return c end
    elseif GetItemCount then
        local ok, c = pcall(GetItemCount, item, includeBank)
        if ok and IsSafeNum(c) then return c end
    end
    return 0
end

local function ExtractItemIDFromLink(link)
    if not IsSafeStr(link) then return nil end
    local idStr = link:match("item:(%d+)")
    local id = idStr and tonumber(idStr)
    if IsSafeNum(id) and id > 0 then return id end
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, instantID = pcall(C_Item.GetItemInfoInstant, link)
        if ok and IsSafeNum(instantID) and instantID > 0 then return instantID end
    end
    return nil
end

local function MakeTrackKey(itemID, itemName)
    if IsSafeNum(itemID) and itemID > 0 then
        return tostring(itemID)
    end
    local low = NormalizeName(itemName)
    if low and low ~= "" then
        return "name:" .. low
    end
    return nil
end

-------------------------------------------------------------------------------
-- Cache & Tracking Queries
-------------------------------------------------------------------------------
local lastBagSnapshot = {}

function FP:UpdateSkillUpReagentsCache(snapshot)
    if type(snapshot) ~= "table" or not IsSafeStr(snapshot.profName) then return end
    local db = EnsureCharTables()
    if not db then return end

    local byKey = {}
    local allByKey = db.profAllReagentsByProf[snapshot.profName]
    if type(allByKey) ~= "table" then
        allByKey = {}
    end

    for _, recipe in ipairs(snapshot.recipes or {}) do
        if type(recipe) == "table" then
            for _, r in ipairs(recipe.reagents or {}) do
                local key = MakeTrackKey(r.itemID, r.name)
                if key then
                    if not allByKey[key] then
                        allByKey[key] = {
                            itemID = IsSafeNum(r.itemID) and r.itemID or nil,
                            name   = IsSafeStr(r.name) and r.name or key,
                        }
                    elseif IsSafeStr(r.name) then
                        allByKey[key].name = r.name
                    end
                    if recipe.diffKey and DIFF_PRIORITY[recipe.diffKey] then
                        local entry = byKey[key]
                        if not entry then
                            entry = {
                                itemID   = IsSafeNum(r.itemID) and r.itemID or nil,
                                name     = IsSafeStr(r.name) and r.name or key,
                                bestDiff = recipe.diffKey,
                                recipes  = {},
                            }
                            byKey[key] = entry
                        elseif (DIFF_PRIORITY[recipe.diffKey] or 0) > (DIFF_PRIORITY[entry.bestDiff] or 0) then
                            entry.bestDiff = recipe.diffKey
                        end
                        if IsSafeStr(recipe.name) and #entry.recipes < 4 then
                            local seen = false
                            for _, rn in ipairs(entry.recipes) do
                                if rn == recipe.name then seen = true break end
                            end
                            if not seen then
                                entry.recipes[#entry.recipes + 1] = recipe.name
                            end
                        end
                    end
                end
            end
        end
    end

    db.profSkillReagentsByProf[snapshot.profName] = byKey
    db.profAllReagentsByProf[snapshot.profName] = allByKey
    if self.RefreshReagentTrackerUI then
        self:RefreshReagentTrackerUI()
    end
end

local function IsKnownRecipeReagent(itemID, itemName)
    local db = NexusKitCharDB
    if type(db) ~= "table" then return false end
    local idKey = (IsSafeNum(itemID) and itemID > 0) and tostring(itemID) or nil
    local lowName = NormalizeName(itemName)
    for _, storeKey in ipairs({ "profAllReagentsByProf", "profSkillReagentsByProf" }) do
        local byProf = db[storeKey]
        if type(byProf) == "table" then
            for _, tbl in pairs(byProf) do
                if type(tbl) == "table" then
                    if (idKey and tbl[idKey]) or (lowName and tbl["name:" .. lowName]) then
                        return true
                    end
                    if lowName then
                        for _, entry in pairs(tbl) do
                            if type(entry) == "table" and NormalizeName(entry.name) == lowName then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

function FP:RefreshAllLearnedRecipeReagents()
    local db = EnsureCharTables()
    if not db then return end

    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeSchematic then
        local profInfo = C_TradeSkillUI.GetChildProfessionInfo and C_TradeSkillUI.GetChildProfessionInfo()
        if not profInfo or not IsSafeStr(profInfo.professionName) then
            profInfo = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
        end
        local profName = (profInfo and IsSafeStr(profInfo.professionName) and profInfo.professionName) or nil
        local okIDs, recipeIDs = pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if profName and okIDs and type(recipeIDs) == "table" and #recipeIDs > 0 then
            local tbl = db.profAllReagentsByProf[profName]
            if type(tbl) ~= "table" then
                tbl = {}
                db.profAllReagentsByProf[profName] = tbl
            end
            for _, rID in ipairs(recipeIDs) do
                if IsSafeNum(rID) then
                    local okSch, sch = pcall(C_TradeSkillUI.GetRecipeSchematic, rID, false)
                    if okSch and type(sch) == "table" and type(sch.reagentSlotSchematics) == "table" then
                        for _, slotSch in ipairs(sch.reagentSlotSchematics) do
                            if type(slotSch) == "table" and type(slotSch.reagents) == "table" then
                                for _, r in ipairs(slotSch.reagents) do
                                    local rIDNum = type(r) == "table" and ((IsSafeNum(r.itemID) and r.itemID) or (type(r.reagent) == "table" and IsSafeNum(r.reagent.itemID) and r.reagent.itemID)) or nil
                                    if rIDNum and rIDNum > 0 then
                                        local key = tostring(rIDNum)
                                        if not tbl[key] then
                                            local okInfo, iName = GetItemInfoCompat(rIDNum)
                                            tbl[key] = {
                                                itemID = rIDNum,
                                                name   = (okInfo and IsSafeStr(iName)) and iName or key,
                                            }
                                        elseif tbl[key].name == key then
                                            local okInfo, iName = GetItemInfoCompat(rIDNum)
                                            if okInfo and IsSafeStr(iName) then
                                                tbl[key].name = iName
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return
        end
    end

    if GetTradeSkillLine and GetNumTradeSkills and GetTradeSkillNumReagents and GetTradeSkillReagentInfo then
        local profName = GetTradeSkillLine()
        local num = GetNumTradeSkills()
        if IsSafeStr(profName) and IsSafeNum(num) and num > 0 then
            local tbl = db.profAllReagentsByProf[profName]
            if type(tbl) ~= "table" then
                tbl = {}
                db.profAllReagentsByProf[profName] = tbl
            end
            for idx = 1, num do
                local _, rType = GetTradeSkillInfo(idx)
                if rType ~= "header" then
                    local nR = GetTradeSkillNumReagents(idx) or 0
                    for r = 1, nR do
                        local rName = GetTradeSkillReagentInfo(idx, r)
                        local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
                        local rID = ExtractItemIDFromLink(rLink)
                        local key = MakeTrackKey(rID, rName)
                        if key and not tbl[key] then
                            tbl[key] = {
                                itemID = IsSafeNum(rID) and rID or nil,
                                name   = IsSafeStr(rName) and rName or key,
                            }
                        end
                    end
                end
            end
        end
    end
end

function FP:GetSkillUpReagentInfo(itemID, itemName)
    local db = NexusKitCharDB and NexusKitCharDB.profSkillReagentsByProf
    if type(db) ~= "table" then return nil end

    local idKey = (IsSafeNum(itemID) and itemID > 0) and tostring(itemID) or nil
    local lowName = NormalizeName(itemName)
    local bestDiff = nil
    local bestPri = 0
    local profList = {}
    local recipeList = {}
    local seenRec = {}

    for profName, tbl in pairs(db) do
        if type(tbl) == "table" then
            local hit = (idKey and tbl[idKey]) or (lowName and tbl["name:" .. lowName]) or nil
            if not hit and lowName then
                for _, entry in pairs(tbl) do
                    if type(entry) == "table" and NormalizeName(entry.name) == lowName then
                        hit = entry
                        break
                    end
                end
            end
            if hit then
                profList[#profList + 1] = profName
                local pri = DIFF_PRIORITY[hit.bestDiff] or 0
                if pri > bestPri then
                    bestPri = pri
                    bestDiff = hit.bestDiff
                end
                for _, rName in ipairs(hit.recipes or {}) do
                    if not seenRec[rName] and #recipeList < 5 then
                        seenRec[rName] = true
                        recipeList[#recipeList + 1] = rName
                    end
                end
            end
        end
    end

    if #profList == 0 then return nil end
    return {
        bestDiff = bestDiff or "easy",
        profs    = profList,
        recipes  = recipeList,
    }
end

local function FindTrackedEntry(itemID, itemName)
    local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents
    if type(tracked) ~= "table" then return nil, nil end

    if IsSafeNum(itemID) and itemID > 0 then
        local idKey = tostring(itemID)
        if tracked[idKey] then
            return idKey, tracked[idKey]
        end
        -- Upgrade any name-only tracked entry automatically once its itemID is observed
        local low = NormalizeName(itemName)
        if not low then
            local ok, name = GetItemInfoCompat(itemID)
            if ok then low = NormalizeName(name) end
        end
        if low and tracked["name:" .. low] then
            local rec = tracked["name:" .. low]
            tracked["name:" .. low] = nil
            rec.key = idKey
            rec.itemID = itemID
            tracked[idKey] = rec
            return idKey, rec
        end
    end

    local low = NormalizeName(itemName)
    if low then
        if tracked["name:" .. low] then
            return "name:" .. low, tracked["name:" .. low]
        end
        for k, rec in pairs(tracked) do
            if type(rec) == "table" and NormalizeName(rec.name) == low then
                return k, rec
            end
        end
    end
    return nil, nil
end

function FP:IsReagentTracked(itemID, itemName)
    local _, entry = FindTrackedEntry(itemID, itemName)
    return entry ~= nil
end

function FP:ToggleTrackReagent(itemID, itemName, icon, itemLink, silent, targetCount)
    local db = EnsureCharTables()
    if not db then return false end

    local existingKey, existing = FindTrackedEntry(itemID, itemName)
    local L = self.L or {}
    if existingKey then
        if targetCount ~= nil then
            if targetCount > 0 then
                existing.target = targetCount
                local bags = existing.itemID and GetItemCountCompat(existing.itemID, false) or 0
                existing.alerted = (bags >= targetCount)
                if not silent then
                    local itemDisp = existing.link or (existing.name and ("[" .. existing.name .. "]")) or tostring(existingKey)
                    self:Print(string.format(L["REAGENT_TARGET_SET"] or "Obiettivo per %s impostato a %d.", itemDisp, targetCount))
                end
            else
                existing.target = nil
                existing.alerted = nil
                if not silent then
                    local itemDisp = existing.link or (existing.name and ("[" .. existing.name .. "]")) or tostring(existingKey)
                    self:Print(string.format(L["REAGENT_TARGET_REMOVED"] or "Obiettivo per %s rimosso.", itemDisp))
                end
            end
            self:RefreshReagentTrackerUI()
            if self.RefreshHighlights then pcall(function() self:RefreshHighlights() end) end
            return true
        end

        local removedName = (existing and existing.name) or itemName or tostring(existingKey)
        db.trackedReagents[existingKey] = nil
        if not silent then
            self:Print(string.format(L["REAGENT_UNTRACKED"] or "Stopped tracking reagent: %s", removedName))
        end
        self:RefreshReagentTrackerUI()
        if self.RefreshHighlights then pcall(function() self:RefreshHighlights() end) end
        return false
    end

    local resolvedID = IsSafeNum(itemID) and itemID or ExtractItemIDFromLink(itemLink)
    local resolvedName = IsSafeStr(itemName) and itemName or nil
    local resolvedIcon = icon
    local resolvedLink = IsSafeStr(itemLink) and itemLink or nil

    if resolvedID then
        local ok, iName, iLink, _, _, _, _, _, _, _, iTex = GetItemInfoCompat(resolvedID)
        if ok then
            resolvedName = resolvedName or (IsSafeStr(iName) and iName)
            resolvedLink = resolvedLink or (IsSafeStr(iLink) and iLink)
            resolvedIcon = resolvedIcon or iTex
        end
        resolvedIcon = resolvedIcon or GetItemIconCompat(resolvedID)
    end

    local key = MakeTrackKey(resolvedID, resolvedName)
    if not key then return false end

    local hasTarget = (targetCount and targetCount > 0)
    db.trackedReagents[key] = {
        key     = key,
        itemID  = resolvedID,
        name    = resolvedName or ("Item #" .. tostring(resolvedID or key)),
        icon    = resolvedIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
        link    = resolvedLink,
        target  = hasTarget and targetCount or nil,
        alerted = false,
    }
    if resolvedID then
        local curBags = GetItemCountCompat(resolvedID, false)
        lastBagSnapshot[key] = curBags
        if hasTarget and curBags >= targetCount then
            db.trackedReagents[key].alerted = true
        end
    end
    if not silent then
        local itemDisp = db.trackedReagents[key].link or db.trackedReagents[key].name
        if hasTarget then
            self:Print(string.format(L["REAGENT_TRACKED_WITH_TARGET"] or "Now tracking reagent: %s (Target: %d)", itemDisp, targetCount))
        else
            self:Print(string.format(L["REAGENT_TRACKED"] or "Now tracking reagent: %s", itemDisp))
        end
    end
    self:RefreshReagentTrackerUI()
    if self.RefreshHighlights then pcall(function() self:RefreshHighlights() end) end
    return true
end

function FP:SetTrackReagentFromInput(input)
    local L = self.L or {}
    local raw = tostring(input or ""):match("^%s*(.-)%s*$")
    if raw == "" then
        local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents or {}
        local names = {}
        for _, rec in pairs(tracked) do
            if type(rec) == "table" then
                local cnt = rec.itemID and GetItemCountCompat(rec.itemID, false) or 0
                if rec.target and rec.target > 0 then
                    names[#names + 1] = string.format("%s (%d/%d)", rec.name or "?", cnt, rec.target)
                else
                    names[#names + 1] = string.format("%s (%d)", rec.name or "?", cnt)
                end
            end
        end
        if #names > 0 then
            self:Print((L["REAGENT_TRACK_LIST"] or "Tracked reagents: ") .. table.concat(names, ", "))
        else
            self:Print(L["REAGENT_TRACK_USAGE"] or "Usage: /nk track [Item Link or Name]  |  /nk track clear")
        end
        return
    end

    if raw:lower() == "debug" or raw:lower() == "diag" then
        if self.PrintReagentDiagnostics then
            self:PrintReagentDiagnostics()
        end
        return
    end

    if raw:lower() == "clear" or raw:lower() == "reset" or raw:lower() == "off" then
        local db = EnsureCharTables()
        if db then
            if wipe then
                wipe(db.trackedReagents)
            else
                db.trackedReagents = {}
            end
        end
        self:RefreshReagentTrackerUI()
        if self.RefreshHighlights then pcall(function() self:RefreshHighlights() end) end
        self:Print(L["REAGENT_TRACK_CLEARED"] or "Cleared all tracked reagents.")
        return
    end

    -- Parse trailing target number if provided: e.g. "Light Feather 20", "[Piuma Leggera] 10", "17056 50"
    local targetCount = nil
    local itemPart, countPart = raw:match("^(.-)%s+(%d+)$")
    if itemPart and countPart then
        local trimmedItem = itemPart:match("^%s*(.-)%s*$")
        if trimmedItem and trimmedItem ~= "" then
            raw = trimmedItem
            targetCount = tonumber(countPart)
        end
    end

    local linkID = ExtractItemIDFromLink(raw)
    if linkID then
        self:ToggleTrackReagent(linkID, nil, nil, raw, false, targetCount)
        return
    end

    local numID = tonumber(raw)
    if IsSafeNum(numID) and numID > 0 then
        self:ToggleTrackReagent(numID, nil, nil, nil, false, targetCount)
        return
    end

    -- Lookup itemID by name in special class reagents, cached skill-up reagents, or player bags
    local foundID = nil
    local lowRaw = NormalizeName(raw)

    local SPECIAL_NAMES = {
        ["light feather"] = 17056, ["piuma leggera"] = 17056, ["feather"] = 17056, ["piuma"] = 17056,
        ["shiny fish scales"] = 17057, ["scaglie di pesce lucenti"] = 17057,
        ["fish oil"] = 17058, ["olio di pesce"] = 17058,
        ["arcane powder"] = 17020, ["polvere arcana"] = 17020,
        ["rune of teleportation"] = 17031, ["runa del teletrasporto"] = 17031,
        ["rune of portals"] = 17032, ["runa dei portali"] = 17032,
        ["wild berries"] = 17028, ["bacche selvatiche"] = 17028,
        ["wild thornroot"] = 17029, ["radice di spina selvatica"] = 17029,
        ["symbol of divinity"] = 17033, ["simbolo della divinita"] = 17033,
        ["symbol of kings"] = 21177, ["simbolo dei re"] = 21177,
        ["sacred candle"] = 17026, ["candela consacrata"] = 17026,
        ["holy candle"] = 17055, ["candela benedetta"] = 17055,
        ["soul shard"] = 6265, ["frammento d'anima"] = 6265,
        ["flash powder"] = 5140, ["polvere accecante"] = 5140,
    }
    if lowRaw and SPECIAL_NAMES[lowRaw] then
        foundID = SPECIAL_NAMES[lowRaw]
    end

    if not foundID then
        local byProf = NexusKitCharDB and NexusKitCharDB.profSkillReagentsByProf or {}
        for _, tbl in pairs(byProf) do
            if type(tbl) == "table" then
                for _, e in pairs(tbl) do
                    if type(e) == "table" and NormalizeName(e.name) == lowRaw and IsSafeNum(e.itemID) then
                        foundID = e.itemID
                        raw = e.name
                        break
                    end
                end
            end
            if foundID then break end
        end
    end

    -- Check items currently in player bags
    if not foundID and ReadContainerSlotItem then
        for bag = 0, 4 do
            local numSlots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
                or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
            for slot = 1, numSlots do
                local sID, sLink, sName = ReadContainerSlotItem(bag, slot)
                if sID and sName and (NormalizeName(sName) == lowRaw or sName:lower():find(lowRaw, 1, true)) then
                    foundID = sID
                    raw = sName
                    break
                end
            end
            if foundID then break end
        end
    end

    self:ToggleTrackReagent(foundID, raw, nil, nil, false, targetCount)
end

-------------------------------------------------------------------------------
-- Shared Slot Overlay Builder (all overlays live on UIParent hosts, zero Blizzard parenting)
-------------------------------------------------------------------------------
local function IsForbiddenObj(obj)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then
        return true
    end
    return (obj.IsForbidden and obj:IsForbidden()) and true or false
end

local function CreateSolidTexture(parent, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    if t.SetColorTexture then
        t:SetColorTexture(1, 1, 1, 1)
    else
        t:SetTexture(1, 1, 1, 1)
    end
    return t
end

local function BuildSolidTrackButton(btn, w, h)
    btn:SetSize(w or 16, h or 16)
    btn:EnableMouse(true)

    local bg = CreateSolidTexture(btn, "BACKGROUND")
    bg:SetAllPoints(btn)
    btn.nkBg = bg

    local function MakeB(p1, p2, bw, bh)
        local b = CreateSolidTexture(btn, "BORDER")
        b:SetPoint(p1, btn, p1, 0, 0)
        b:SetPoint(p2, btn, p2, 0, 0)
        if bw then b:SetWidth(bw) end
        if bh then b:SetHeight(bh) end
        return b
    end
    btn.nkBTop = MakeB("TOPLEFT", "TOPRIGHT", nil, 1)
    btn.nkBBot = MakeB("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    btn.nkBLeft = MakeB("TOPLEFT", "BOTTOMLEFT", 1, nil)
    btn.nkBRight = MakeB("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

    local symbol = btn:CreateFontString(nil, "OVERLAY")
    symbol:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    symbol:SetPoint("CENTER", btn, "CENTER", 0, 0)
    symbol:SetJustifyH("CENTER")
    symbol:SetJustifyV("MIDDLE")
    symbol:SetText("+")
    symbol:SetTextColor(0, 1, 0.6, 1)
    btn.symbol = symbol
end

local function ApplySolidButtonColors(btn, isTracked, hovered)
    if not btn then return end
    local function SetCol(t, r, g, b, a)
        if not t then return end
        if t.SetColorTexture then t:SetColorTexture(r, g, b, a) else t:SetTexture(r, g, b, a) end
    end
    if isTracked then
        btn.symbol:SetText("-")
        if hovered then
            SetCol(btn.nkBg, 0.28, 0.08, 0.12, 0.98)
            SetCol(btn.nkBTop, 1.0, 0.35, 0.40, 1)
            SetCol(btn.nkBBot, 1.0, 0.35, 0.40, 1)
            SetCol(btn.nkBLeft, 1.0, 0.35, 0.40, 1)
            SetCol(btn.nkBRight, 1.0, 0.35, 0.40, 1)
            btn.symbol:SetTextColor(1.0, 0.50, 0.45, 1)
        else
            SetCol(btn.nkBg, 0.06, 0.18, 0.26, 0.96)
            SetCol(btn.nkBTop, TRACKED.r, TRACKED.g, TRACKED.b, 1)
            SetCol(btn.nkBBot, TRACKED.r, TRACKED.g, TRACKED.b, 1)
            SetCol(btn.nkBLeft, TRACKED.r, TRACKED.g, TRACKED.b, 1)
            SetCol(btn.nkBRight, TRACKED.r, TRACKED.g, TRACKED.b, 1)
            btn.symbol:SetTextColor(0.55, 0.95, 1.0, 1)
        end
    else
        btn.symbol:SetText("+")
        if hovered then
            SetCol(btn.nkBg, 0.08, 0.28, 0.18, 0.98)
            SetCol(btn.nkBTop, 0.00, 1.00, 0.60, 1)
            SetCol(btn.nkBBot, 0.00, 1.00, 0.60, 1)
            SetCol(btn.nkBLeft, 0.00, 1.00, 0.60, 1)
            SetCol(btn.nkBRight, 0.00, 1.00, 0.60, 1)
            btn.symbol:SetTextColor(0.35, 1.00, 0.70, 1)
        else
            SetCol(btn.nkBg, 0.04, 0.10, 0.16, 0.94)
            SetCol(btn.nkBTop, 0.00, 0.95, 0.55, 1)
            SetCol(btn.nkBBot, 0.00, 0.95, 0.55, 1)
            SetCol(btn.nkBLeft, 0.00, 0.95, 0.55, 1)
            SetCol(btn.nkBRight, 0.00, 0.95, 0.55, 1)
            btn.symbol:SetTextColor(0.00, 1.00, 0.60, 1)
        end
    end
end

local function HideSlotOverlay(ov)
    if not ov then return end
    ov.itemID = nil
    ov.itemName = nil
    ov.itemIcon = nil
    ov.itemLink = nil
    ov.isTracked = false
    ov.targetRef = nil
    ov.windowRef = nil
    if ov.glow then ov.glow:Hide() end
    if ov.badge then ov.badge:Hide() end
    if ov.badgeBg then ov.badgeBg:Hide() end
    if ov.trackBtn then
        ov.trackBtn.hovered = false
        ov.trackBtn:Hide()
    end
    ov:Hide()
end

local function ApplyTrackButtonVisual(ov)
    local btn = ov and ov.trackBtn
    if not btn then return end
    ApplySolidButtonColors(btn, ov.isTracked, btn.hovered)
end

local function CreateSlotOverlay(hostFrame, iconSize, showTrackBtn, showBadge)
    local ov = CreateFrame("Frame", nil, hostFrame, "BackdropTemplate")
    ov:EnableMouse(false)
    ov:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    ov:SetBackdropBorderColor(0, 0, 0, 0)

    local glow = ov:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER", ov, "CENTER", 0, 0)
    local gSize = math.floor((iconSize or 36) * 1.55)
    glow:SetSize(gSize, gSize)
    glow:Hide()
    ov.glow = glow

    if showTrackBtn then
        local btn = CreateFrame("Button", nil, hostFrame)
        BuildSolidTrackButton(btn, 16, 16)
        btn:SetSize(16, 16)
        btn:SetFrameStrata("DIALOG")
        btn:SetFrameLevel(60)
        btn:RegisterForClicks("LeftButtonUp")
        btn.ownerOverlay = ov

        btn:SetScript("OnClick", function(self)
            local targetOv = self.ownerOverlay or ov
            if targetOv and (targetOv.itemID or IsSafeStr(targetOv.itemName)) then
                FP:ToggleTrackReagent(targetOv.itemID, targetOv.itemName, targetOv.itemIcon, targetOv.itemLink)
                if FP.RefreshBagOverlays then FP:RefreshBagOverlays() end
                if FP.RefreshProfSlotOverlays then FP:RefreshProfSlotOverlays() end
            end
        end)
        btn:SetScript("OnEnter", function(self)
            self.hovered = true
            local targetOv = self.ownerOverlay or ov
            if targetOv then ApplyTrackButtonVisual(targetOv) end
            if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
            local L = FP.L or {}
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if targetOv and IsSafeStr(targetOv.itemLink) then
                GameTooltip:SetHyperlink(targetOv.itemLink)
            elseif targetOv and IsSafeStr(targetOv.itemName) then
                GameTooltip:SetText(targetOv.itemName, 1, 1, 1)
            else
                GameTooltip:SetText(L["REAGENT_TRACK_BTN_TITLE"] or "Traccia Reagente", TRACKED.r, TRACKED.g, TRACKED.b)
            end

            GameTooltip:AddLine(" ")
            if targetOv and targetOv.isTracked then
                GameTooltip:AddLine("|cff40e0ff[NexusKit - Reagente Tracciato]|r", 0.25, 0.88, 1, false)
                GameTooltip:AddLine(L["REAGENT_TRACK_BTN_ACTIVE"] or "Clicca per rimuovere dal tracking.", 0.85, 0.92, 1, true)
            else
                if targetOv and targetOv.skillInfo then
                    local recipeName = targetOv.skillInfo.recipeName or ""
                    local diff = targetOv.skillInfo.bestDiff or ""
                    GameTooltip:AddLine("|cffffaa20[NexusKit - Utile per Professione]|r " .. recipeName .. (diff ~= "" and (" (" .. diff .. ")") or ""), 1.0, 0.67, 0.12, false)
                elseif targetOv and targetOv.keepInfo then
                    GameTooltip:AddLine("|cffffd100[NexusKit - Oggetto Missione]|r Da conservare per future missioni.", 1.0, 0.82, 0.0, false)
                else
                    GameTooltip:AddLine("|cff44ee66[NexusKit - Materiale / Reagente]|r", 0.27, 0.93, 0.4, false)
                end
                GameTooltip:AddLine(L["REAGENT_TRACK_BTN_IDLE"] or "Clicca [+] per tracciare nelle borse e nel bottino.", 0.85, 1, 0.90, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self.hovered = false
            local targetOv = self.ownerOverlay or ov
            if targetOv then ApplyTrackButtonVisual(targetOv) end
            if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
                GameTooltip:Hide()
            end
        end)
        ov.trackBtn = btn
    end

    ov:Hide()
    return ov
end

local STRATA_RANK = {
    BACKGROUND = 1,
    LOW = 2,
    MEDIUM = 3,
    HIGH = 4,
    DIALOG = 5,
    FULLSCREEN = 6,
    FULLSCREEN_DIALOG = 7,
    TOOLTIP = 8,
}

local function PickHigherStrata(a, b)
    local ra = STRATA_RANK[a or ""] or 0
    local rb = STRATA_RANK[b or ""] or 0
    if ra >= rb and ra > 0 then return a end
    if rb > 0 then return b end
    return "HIGH"
end

local function IsRegionVisible(region)
    if not region or IsForbiddenObj(region) then return false end
    if region.IsVisible then
        local ok, vis = pcall(region.IsVisible, region)
        if ok and vis ~= nil then return vis and true or false end
    end
    if region.IsShown then
        local ok, shown = pcall(region.IsShown, region)
        if not ok or not shown then return false end
        local parent = region.GetParent and region:GetParent()
        if parent and parent.IsVisible then
            local okP, pVis = pcall(parent.IsVisible, parent)
            if okP then return pVis and true or false end
        end
        return true
    end
    return false
end

local function PositionFrameOverTarget(frame, hostFrame, targetRegion, parentWindow, levelOffset, minLevel)
    if not frame or not hostFrame or IsForbiddenObj(targetRegion) or not IsRegionVisible(targetRegion) then
        return false
    end

    local strata = "DIALOG"
    local lvl = 45

    if hostFrame ~= UIParent then
        hostFrame:SetFrameStrata(strata)
        hostFrame:SetFrameLevel(40)
        if not hostFrame:IsShown() then
            hostFrame:Show()
        end
    end

    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(lvl)

    local rw = targetRegion.GetWidth and targetRegion:GetWidth()
    local rh = targetRegion.GetHeight and targetRegion:GetHeight()
    local w = (IsSafeNum(rw) and rw > 10) and rw or 36
    local h = (IsSafeNum(rh) and rh > 10) and rh or 36

    frame:ClearAllPoints()
    frame:SetAllPoints(targetRegion)

    return true, w, h, strata, lvl
end

local function SyncOverlayToTarget(ov, hostFrame, targetRegion, parentWindow)
    local ok, w, h, strata, lvl = PositionFrameOverTarget(ov, hostFrame, targetRegion, parentWindow, 22, 24)
    if not ok then
        return false
    end
    if ov.glow then
        local gSize = math.floor(math.max(w, h) * 1.55)
        ov.glow:SetSize(gSize, gSize)
    end
    if ov.trackBtn then
        ov.trackBtn:SetSize(16, 16)
        ov.trackBtn:ClearAllPoints()
        ov.trackBtn:SetPoint("TOPRIGHT", targetRegion, "TOPRIGHT", -1, -1)
        ov.trackBtn:SetFrameStrata("DIALOG")
        ov.trackBtn:SetFrameLevel(65)
    end
    ov.targetRef = targetRegion
    ov.windowRef = parentWindow
    return true
end

local function ApplyReagentOverlayState(ov, itemID, itemName, itemIcon, itemLink, showBtn)
    if not ov then return end
    ov.itemID = IsSafeNum(itemID) and itemID or nil
    ov.itemName = IsSafeStr(itemName) and itemName or nil
    ov.itemIcon = itemIcon
    ov.itemLink = IsSafeStr(itemLink) and itemLink or nil

    local isTracked = FP:IsReagentTracked(ov.itemID, ov.itemName)
    local keepInfo = (IsQuestKeepEnabled() and FP.GetQuestKeepInfo) and FP:GetQuestKeepInfo(ov.itemID, ov.itemName) or nil
    local skillInfo = IsHighlightEnabled() and FP:GetSkillUpReagentInfo(ov.itemID, ov.itemName) or nil
    ov.isTracked = isTracked
    ov.keepInfo = keepInfo
    ov.skillInfo = skillInfo

    -- Text badges ("SKILL", "TRACK", "QUEST") are permanently hidden per user request;
    -- hints are delivered via clean tooltip when hovering the slot/button.
    if ov.badge then ov.badge:Hide() end
    if ov.badgeBg then ov.badgeBg:Hide() end

    local currentStrata = ov:GetFrameStrata() or "HIGH"
    local currentLevel = ov:GetFrameLevel() or 20

    if isTracked then
        ov:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.95)
        ov.glow:SetVertexColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.85)
        ov.glow:Show()
        ov:Show()
    elseif keepInfo then
        ov:SetBackdropBorderColor(QUEST_KEEP.r, QUEST_KEEP.g, QUEST_KEEP.b, 0.96)
        ov.glow:SetVertexColor(QUEST_KEEP.r, QUEST_KEEP.g, QUEST_KEEP.b, 0.82)
        ov.glow:Show()
        ov:Show()
    elseif skillInfo then
        local col = SKILL_COLORS[skillInfo.bestDiff] or ACCENT
        ov:SetBackdropBorderColor(col.r, col.g, col.b, 0.95)
        ov.glow:SetVertexColor(col.r, col.g, col.b, 0.80)
        ov.glow:Show()
        ov:Show()
    else
        ov:SetBackdropBorderColor(0, 0, 0, 0)
        ov.glow:Hide()
        ov:Hide()
    end

    if ov.trackBtn then
        if showBtn and (ov.itemID or ov.itemName) then
            ApplyTrackButtonVisual(ov)
            ov.trackBtn:SetFrameStrata("DIALOG")
            ov.trackBtn:SetFrameLevel(60)
            ov.trackBtn:Show()
        else
            ov.trackBtn.hovered = false
            ov.trackBtn:Hide()
        end
    end
end

local function CreateOverlayHost(name, poolTbl, onVisibleTick)
    local host = CreateFrame("Frame", name, UIParent)
    host:SetAllPoints(UIParent)
    host:EnableMouse(false)
    host:SetFrameStrata("DIALOG")
    host.accum = 0
    host:SetScript("OnUpdate", function(self, elapsed)
        self.accum = self.accum + elapsed
        if self.accum < 0.05 then return end
        self.accum = 0
        for _, ov in ipairs(poolTbl) do
            if ov:IsShown() or (ov.trackBtn and ov.trackBtn:IsShown()) then
                local tr = ov.targetRef
                local wr = ov.windowRef
                if not tr or not wr or (wr.IsShown and not wr:IsShown()) or (tr.IsVisible and not tr:IsVisible()) then
                    HideSlotOverlay(ov)
                else
                    if not SyncOverlayToTarget(ov, self, tr, wr) then
                        HideSlotOverlay(ov)
                    end
                end
            end
        end
        if onVisibleTick then
            onVisibleTick(self)
        end
    end)
    host:Hide()
    return host
end

-------------------------------------------------------------------------------
-- 1. Loot Window Overlays (Midnight ScrollBox + Classic LootButton1..4)
-------------------------------------------------------------------------------
local lootOvPool = {}
local lootOverlayHost
lootOverlayHost = CreateOverlayHost("NexusKitLootOverlayHost", lootOvPool, function(self)
    if not LootFrame or not LootFrame:IsShown() then
        self:Hide()
        return
    end
    if LootFrame.ScrollBox and not IsForbiddenObj(LootFrame.ScrollBox) and LootFrame.ScrollBox.GetScrollPercentage then
        local ok, pct = pcall(LootFrame.ScrollBox.GetScrollPercentage, LootFrame.ScrollBox)
        if ok and IsSafeNum(pct) and self.lastScrollPct ~= pct then
            self.lastScrollPct = pct
            FP:RefreshLootOverlays()
        end
    end
end)

local function UpdateLootElementOverlay(poolIdx, elem, slotIndex)
    if not elem or IsForbiddenObj(elem) then return false end
    if not IsSafeNum(slotIndex) or slotIndex <= 0 or not GetLootSlotInfo then
        return false
    end

    local okInfo, icon, name = pcall(GetLootSlotInfo, slotIndex)
    local linkOk, link = pcall(GetLootSlotLink, slotIndex)
    local isItemSlot = true
    if GetLootSlotType and Enum and Enum.LootSlotType and Enum.LootSlotType.Item then
        local okT, slotType = pcall(GetLootSlotType, slotIndex)
        if okT and slotType ~= Enum.LootSlotType.Item then
            isItemSlot = false
        end
    elseif not (linkOk and IsSafeStr(link)) then
        isItemSlot = false
    end

    if not okInfo or not IsSafeStr(name) or not isItemSlot then
        return false
    end

    local iconTarget = elem.Item or elem.IconTexture or _G[(elem.GetName and elem:GetName() or "") .. "IconTexture"] or elem
    if IsForbiddenObj(iconTarget) or not iconTarget:IsVisible() then
        return false
    end

    local ov = lootOvPool[poolIdx]
    if not ov then
        ov = CreateSlotOverlay(lootOverlayHost, 36, true, true)
        lootOvPool[poolIdx] = ov
    end
    if not SyncOverlayToTarget(ov, lootOverlayHost, iconTarget, LootFrame) then
        HideSlotOverlay(ov)
        return false
    end

    local itemID = linkOk and ExtractItemIDFromLink(link) or nil
    ApplyReagentOverlayState(ov, itemID, name, icon, linkOk and link or nil, true)
    return true
end

function FP:RefreshLootOverlays()
    if not LootFrame or IsForbiddenObj(LootFrame) or not LootFrame:IsShown() then
        for _, ov in ipairs(lootOvPool) do
            HideSlotOverlay(ov)
        end
        lootOverlayHost:Hide()
        return
    end

    local used = 0
    if LootFrame.ScrollBox and not IsForbiddenObj(LootFrame.ScrollBox) and LootFrame.ScrollBox.ForEachFrame then
        pcall(LootFrame.ScrollBox.ForEachFrame, LootFrame.ScrollBox, function(frame, elementData)
            if not IsForbiddenObj(frame) and frame:IsVisible() then
                local slot = (frame.GetSlotIndex and frame:GetSlotIndex())
                    or (elementData and (elementData.slotIndex or elementData.index))
                    or frame.slot
                if UpdateLootElementOverlay(used + 1, frame, slot) then
                    used = used + 1
                end
            end
        end)
    else
        local numButtons = LOOTFRAME_NUMBUTTONS or 4
        for i = 1, numButtons do
            local btn = _G["LootButton" .. i]
            if btn and not IsForbiddenObj(btn) and btn:IsShown() then
                if UpdateLootElementOverlay(used + 1, btn, btn.slot or i) then
                    used = used + 1
                end
            end
        end
    end

    for i = used + 1, #lootOvPool do
        HideSlotOverlay(lootOvPool[i])
    end
    if used > 0 then
        lootOverlayHost:Show()
    else
        lootOverlayHost:Hide()
    end
end

-------------------------------------------------------------------------------
-- 2. Blizzard Profession Book Overlays (ProfessionsFrame + TradeSkillFrame)
-------------------------------------------------------------------------------
local profOvPool = {}
local profOverlayHost = CreateOverlayHost("NexusKitProfOverlayHost", profOvPool, function(self)
    local modernShown = ProfessionsFrame and ProfessionsFrame:IsShown()
    local classicShown = TradeSkillFrame and TradeSkillFrame:IsShown()
    local craftShown = CraftFrame and CraftFrame:IsShown()
    if not modernShown and not classicShown and not craftShown then
        self:Hide()
    end
end)
local hookedSchematicForms = {}

local function ExtractReagentItemIDFromEntry(entry)
    if type(entry) ~= "table" then return nil end
    if IsSafeNum(entry.itemID) and entry.itemID > 0 then
        return entry.itemID
    end
    if type(entry.reagent) == "table" and IsSafeNum(entry.reagent.itemID) and entry.reagent.itemID > 0 then
        return entry.reagent.itemID
    end
    if IsSafeNum(entry.reagentID) and entry.reagentID > 0 then
        return entry.reagentID
    end
    if entry.GetItemID then
        local ok, id = pcall(entry.GetItemID, entry)
        if ok and IsSafeNum(id) and id > 0 then
            return id
        end
    end
    return nil
end

local function CleanReagentSlotName(raw)
    if not IsSafeStr(raw) then return nil end
    local s = raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("^%s*%d+%s*/%s*%d+%s*", "")
    s = s:gsub("%s*%[%d+%]%s*$", "")
    s = s:gsub("%s*%(%d+%)%s*$", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    return s
end

local function BuildRecipeReagentLookup(form)
    local bySlotIdx = {}
    local ordered = {}
    if not form or IsForbiddenObj(form) then return bySlotIdx, ordered end

    local sch
    local tx = form.transaction
    if form.GetTransaction then
        local okT, tVal = pcall(form.GetTransaction, form)
        if okT and tVal then
            tx = tVal
        end
    end
    if type(tx) == "table" and not IsForbiddenObj(tx) and tx.GetRecipeSchematic then
        local okTx, txSch = pcall(tx.GetRecipeSchematic, tx)
        if okTx and type(txSch) == "table" then
            sch = txSch
        end
    end
    if not sch and C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then
        local recipeID
        if type(tx) == "table" and not IsForbiddenObj(tx) and tx.GetRecipeID then
            local okR, rid = pcall(tx.GetRecipeID, tx)
            if okR and IsSafeNum(rid) and rid > 0 then recipeID = rid end
        end
        if not recipeID and form.GetRecipeInfo then
            local okRI, rInfo = pcall(form.GetRecipeInfo, form)
            if okRI and type(rInfo) == "table" and IsSafeNum(rInfo.recipeID) and rInfo.recipeID > 0 then
                recipeID = rInfo.recipeID
            end
        end
        if not recipeID and IsSafeNum(form.recipeID) and form.recipeID > 0 then
            recipeID = form.recipeID
        end
        if not recipeID and type(form.currentRecipeInfo) == "table" and IsSafeNum(form.currentRecipeInfo.recipeID) then
            recipeID = form.currentRecipeInfo.recipeID
        end
        if not recipeID and ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.RecipeList then
            local rList = ProfessionsFrame.CraftingPage.RecipeList
            if not IsForbiddenObj(rList) and rList.GetSelectedRecipeID then
                local okSel, rid = pcall(rList.GetSelectedRecipeID, rList)
                if okSel and IsSafeNum(rid) and rid > 0 then recipeID = rid end
            end
        end
        if IsSafeNum(recipeID) and recipeID > 0 then
            local isRecraft = false
            if form.GetIsRecraft then
                local okRec, rVal = pcall(form.GetIsRecraft, form)
                if okRec and rVal == true then
                    isRecraft = true
                end
            end
            local okSch, apiSch = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, isRecraft)
            if okSch and type(apiSch) == "table" then
                sch = apiSch
            end
        end
    end

    if type(sch) == "table" and type(sch.reagentSlotSchematics) == "table" then
        for idx, slotSch in ipairs(sch.reagentSlotSchematics) do
            if type(slotSch) == "table" and type(slotSch.reagents) == "table" then
                local foundID
                for _, r in ipairs(slotSch.reagents) do
                    foundID = ExtractReagentItemIDFromEntry(r)
                    if foundID then break end
                end
                if foundID then
                    local sIdx = IsSafeNum(slotSch.slotIndex) and slotSch.slotIndex or idx
                    bySlotIdx[sIdx] = foundID
                    ordered[#ordered + 1] = foundID
                end
            end
        end
    end
    return bySlotIdx, ordered
end

local function ResolveModernReagentSlotInfo(slot, bySlotIdx, fallbackOrderedID)
    if not slot or IsForbiddenObj(slot) then return nil, nil, nil, nil end
    local itemID, name, icon, link
    if slot.GetReagentSlotSchematic then
        local ok, sch = pcall(slot.GetReagentSlotSchematic, slot)
        if ok and type(sch) == "table" then
            if type(sch.reagents) == "table" then
                for _, r in ipairs(sch.reagents) do
                    itemID = ExtractReagentItemIDFromEntry(r)
                    if itemID then break end
                end
            end
            if not itemID then
                itemID = ExtractReagentItemIDFromEntry(sch)
            end
        end
    end
    if not itemID and type(slot.reagentSlotSchematic) == "table" then
        local sch = slot.reagentSlotSchematic
        if type(sch.reagents) == "table" then
            for _, r in ipairs(sch.reagents) do
                itemID = ExtractReagentItemIDFromEntry(r)
                if itemID then break end
            end
        end
        if not itemID then itemID = ExtractReagentItemIDFromEntry(sch) end
    end
    if not itemID and slot.GetReagent then
        local ok, reg = pcall(slot.GetReagent, slot)
        if ok then
            if IsSafeNum(reg) and reg > 0 then
                itemID = reg
            elseif type(reg) == "table" then
                itemID = ExtractReagentItemIDFromEntry(reg)
            end
        end
    end
    if not itemID then
        itemID = ExtractReagentItemIDFromEntry(slot)
    end
    local btn = slot.Button or slot.Item or slot
    if not itemID and not IsForbiddenObj(btn) then
        if btn.GetItemID then
            local ok, id = pcall(btn.GetItemID, btn)
            if ok and IsSafeNum(id) and id > 0 then itemID = id end
        end
        if not itemID and btn.GetItem then
            local ok, id = pcall(btn.GetItem, btn)
            if ok then
                if IsSafeNum(id) and id > 0 then
                    itemID = id
                elseif type(id) == "table" then
                    itemID = ExtractReagentItemIDFromEntry(id)
                end
            end
        end
        if not itemID and btn.GetReagent then
            local ok, reg = pcall(btn.GetReagent, btn)
            if ok then
                itemID = (IsSafeNum(reg) and reg > 0 and reg) or ExtractReagentItemIDFromEntry(reg)
            end
        end
        if not itemID then
            itemID = ExtractReagentItemIDFromEntry(btn) or (IsSafeNum(btn.item) and btn.item > 0 and btn.item) or nil
        end
    end
    if not IsForbiddenObj(btn) and btn.GetItemLink then
        local ok, l = pcall(btn.GetItemLink, btn)
        if ok and IsSafeStr(l) then link = l end
    end
    if not itemID and link then
        itemID = ExtractItemIDFromLink(link)
    end
    if not itemID and type(bySlotIdx) == "table" then
        local sIdx
        if slot.GetSlotIndex then
            local okS, v = pcall(slot.GetSlotIndex, slot)
            if okS and IsSafeNum(v) then sIdx = v end
        end
        sIdx = sIdx or (IsSafeNum(slot.slotIndex) and slot.slotIndex) or nil
        if sIdx and IsSafeNum(bySlotIdx[sIdx]) then
            itemID = bySlotIdx[sIdx]
        elseif IsSafeNum(fallbackOrderedID) then
            itemID = fallbackOrderedID
        end
    end
    local nameRegion = slot.Name or slot.Text
    if nameRegion and not IsForbiddenObj(nameRegion) and nameRegion.GetText then
        local okN, rawText = pcall(nameRegion.GetText, nameRegion)
        if okN then
            local clean = CleanReagentSlotName(rawText)
            if clean then name = clean end
        end
    end
    if not itemID and name then
        local okByName, iName, iLink, _, _, _, _, _, _, _, iTex = GetItemInfoCompat(name)
        if okByName and IsSafeStr(iLink) then
            itemID = ExtractItemIDFromLink(iLink)
            link = link or iLink
            name = IsSafeStr(iName) and iName or name
            icon = icon or iTex
        end
    end
    if itemID then
        local ok, iName, iLink, _, _, _, _, _, _, _, iTex = GetItemInfoCompat(itemID)
        if ok then
            name = IsSafeStr(iName) and iName or name
            link = link or (IsSafeStr(iLink) and iLink or nil)
            icon = icon or iTex
        end
        icon = icon or GetItemIconCompat(itemID)
    elseif name and not IsForbiddenObj(btn) then
        local texRegion = btn.Icon or btn.icon
        if texRegion and not IsForbiddenObj(texRegion) and texRegion.GetTexture then
            local okT, tex = pcall(texRegion.GetTexture, texRegion)
            if okT and tex then icon = tex end
        end
    end
    return itemID, name, icon, link
end

local function HookSchematicFormObj(form)
    -- Refreshed safely via profWatchFrame ticker and native WoW events without hooking methods
end

local function CollectModernSchematicSlots(form)
    local slots = {}
    local seenSlots = {}
    local function AddSlot(s)
        if s and type(s) == "table" and not IsForbiddenObj(s) and not seenSlots[s] then
            if s.IsVisible and s:IsVisible() then
                seenSlots[s] = true
                slots[#slots + 1] = s
            end
        end
    end
    if form.reagentSlotPool and form.reagentSlotPool.EnumerateActive then
        for slot in form.reagentSlotPool:EnumerateActive() do
            AddSlot(slot)
        end
    end
    if type(form.reagentSlots) == "table" then
        for _, v in pairs(form.reagentSlots) do
            if type(v) == "table" then
                if v.Button or v.GetReagentSlotSchematic or v.Name then
                    AddSlot(v)
                else
                    for _, sub in pairs(v) do
                        if type(sub) == "table" and (sub.Button or sub.GetReagentSlotSchematic or sub.Name) then
                            AddSlot(sub)
                        end
                    end
                end
            end
        end
    end
    if type(form.Reagents) == "table" then
        if form.Reagents.GetChildren then
            local okC, children = pcall(function() return { form.Reagents:GetChildren() } end)
            if okC and type(children) == "table" then
                for _, ch in ipairs(children) do AddSlot(ch) end
            end
        else
            for _, v in ipairs(form.Reagents) do AddSlot(v) end
        end
    end
    if #slots == 0 and form.GetChildren then
        local visited = {}
        local function Scan(node, depth)
            if depth > 3 or not node or visited[node] or IsForbiddenObj(node) or not node.GetChildren then return end
            visited[node] = true
            local okC, children = pcall(function() return { node:GetChildren() } end)
            if not okC or type(children) ~= "table" then return end
            for _, ch in ipairs(children) do
                if not IsForbiddenObj(ch) then
                    if ch.GetReagentSlotSchematic or ch.GetReagent or ch.reagentSlotSchematic or (ch.Button and ch.Name) then
                        AddSlot(ch)
                    elseif ch.GetChildren and depth < 3 then
                        Scan(ch, depth + 1)
                    end
                end
            end
        end
        Scan(form, 1)
    end
    return slots
end

local tsReagentBtns = {}
local craftReagentBtns = {}

local function UpdateBlizzardReagentButtons()
    if TradeSkillFrame and TradeSkillFrame:IsShown() and GetTradeSkillSelectionIndex and GetTradeSkillNumReagents then
        local idx = GetTradeSkillSelectionIndex()
        local numR = (idx and idx > 0 and GetTradeSkillNumReagents(idx)) or 0
        for r = 1, 8 do
            local parentBtn = _G["TradeSkillReagent" .. r]
            if parentBtn then
                local tBtn = tsReagentBtns[r]
                if not tBtn then
                    tBtn = CreateFrame("Button", "NexKitTSReagentBtn" .. r, UIParent)
                    BuildSolidTrackButton(tBtn, 20, 20)
                    tBtn:SetFrameStrata("HIGH")
                    tBtn:SetFrameLevel(parentBtn:GetFrameLevel() + 5)
                    tBtn:RegisterForClicks("LeftButtonUp")
                    tBtn:SetScript("OnClick", function(self)
                        if self.itemID or IsSafeStr(self.itemName) then
                            FP:ToggleTrackReagent(self.itemID, self.itemName, self.itemIcon, self.itemLink)
                            UpdateBlizzardReagentButtons()
                        end
                    end)
                    tBtn:SetScript("OnEnter", function(self)
                        self.hovered = true
                        ApplySolidButtonColors(self, self.isTracked, true)
                        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
                            local L = FP.L or {}
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetText(L["REAGENT_TRACK_BTN_TITLE"] or "Track Reagent", TRACKED.r, TRACKED.g, TRACKED.b)
                            if IsSafeStr(self.itemLink) then GameTooltip:AddLine(self.itemLink, 1, 1, 1, true)
                            elseif IsSafeStr(self.itemName) then GameTooltip:AddLine(self.itemName, 1, 1, 1, true) end
                            if self.isTracked then
                                GameTooltip:AddLine("Tracked: click to stop tracking.", 0.85, 0.92, 1, true)
                            else
                                GameTooltip:AddLine("Click to track this reagent.", 0.85, 1, 0.90, true)
                            end
                            GameTooltip:Show()
                        end
                    end)
                    tBtn:SetScript("OnLeave", function(self)
                        self.hovered = false
                        ApplySolidButtonColors(self, self.isTracked, false)
                        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
                    end)
                    tsReagentBtns[r] = tBtn
                end

                if r <= numR and parentBtn:IsShown() and parentBtn:IsVisible() then
                    local rName, rTex = GetTradeSkillReagentInfo(idx, r)
                    local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    tBtn.itemID = rID
                    tBtn.itemName = rName
                    tBtn.itemIcon = rTex or (rID and GetItemIconCompat(rID))
                    tBtn.itemLink = rLink
                    local isTracked = FP:IsReagentTracked(rID, rName)
                    tBtn.isTracked = isTracked
                    ApplySolidButtonColors(tBtn, isTracked, false)
                    local pRight = parentBtn.GetLeft and parentBtn:GetLeft()
                    local pTop = parentBtn.GetTop and parentBtn:GetTop()
                    if pRight and pTop then
                        local scale = parentBtn:GetEffectiveScale() / UIParent:GetEffectiveScale()
                        tBtn:ClearAllPoints()
                        tBtn:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (pRight + 20) * scale, pTop * scale)
                        tBtn:Show()
                    else
                        tBtn:Hide()
                    end
                else
                    tBtn:Hide()
                end
            end
        end
    else
        for _, b in pairs(tsReagentBtns) do b:Hide() end
    end

    if CraftFrame and CraftFrame:IsShown() and GetCraftSelectionIndex and GetCraftNumReagents then
        local idx = GetCraftSelectionIndex()
        local numR = (idx and idx > 0 and GetCraftNumReagents(idx)) or 0
        for r = 1, 8 do
            local parentBtn = _G["CraftReagent" .. r]
            if parentBtn then
                local tBtn = craftReagentBtns[r]
                if not tBtn then
                    tBtn = CreateFrame("Button", "NexKitCraftReagentBtn" .. r, UIParent)
                    BuildSolidTrackButton(tBtn, 20, 20)
                    tBtn:SetFrameStrata("HIGH")
                    tBtn:SetFrameLevel(parentBtn:GetFrameLevel() + 5)
                    tBtn:RegisterForClicks("LeftButtonUp")
                    tBtn:SetScript("OnClick", function(self)
                        if self.itemID or IsSafeStr(self.itemName) then
                            FP:ToggleTrackReagent(self.itemID, self.itemName, self.itemIcon, self.itemLink)
                            UpdateBlizzardReagentButtons()
                        end
                    end)
                    tBtn:SetScript("OnEnter", function(self)
                        self.hovered = true
                        ApplySolidButtonColors(self, self.isTracked, true)
                        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
                            local L = FP.L or {}
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetText(L["REAGENT_TRACK_BTN_TITLE"] or "Track Reagent", TRACKED.r, TRACKED.g, TRACKED.b)
                            if IsSafeStr(self.itemLink) then GameTooltip:AddLine(self.itemLink, 1, 1, 1, true)
                            elseif IsSafeStr(self.itemName) then GameTooltip:AddLine(self.itemName, 1, 1, 1, true) end
                            if self.isTracked then
                                GameTooltip:AddLine("Tracked: click to stop tracking.", 0.85, 0.92, 1, true)
                            else
                                GameTooltip:AddLine("Click to track this reagent.", 0.85, 1, 0.90, true)
                            end
                            GameTooltip:Show()
                        end
                    end)
                    tBtn:SetScript("OnLeave", function(self)
                        self.hovered = false
                        ApplySolidButtonColors(self, self.isTracked, false)
                        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
                    end)
                    craftReagentBtns[r] = tBtn
                end

                if r <= numR and parentBtn:IsShown() and parentBtn:IsVisible() then
                    local rName, rTex = GetCraftReagentInfo(idx, r)
                    local rLink = GetCraftReagentItemLink and GetCraftReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    tBtn.itemID = rID
                    tBtn.itemName = rName
                    tBtn.itemIcon = rTex or (rID and GetItemIconCompat(rID))
                    tBtn.itemLink = rLink
                    local isTracked = FP:IsReagentTracked(rID, rName)
                    tBtn.isTracked = isTracked
                    ApplySolidButtonColors(tBtn, isTracked, false)
                    local pRight = parentBtn.GetLeft and parentBtn:GetLeft()
                    local pTop = parentBtn.GetTop and parentBtn:GetTop()
                    if pRight and pTop then
                        local scale = parentBtn:GetEffectiveScale() / UIParent:GetEffectiveScale()
                        tBtn:ClearAllPoints()
                        tBtn:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (pRight + 20) * scale, pTop * scale)
                        tBtn:Show()
                    else
                        tBtn:Hide()
                    end
                else
                    tBtn:Hide()
                end
            end
        end
    else
        for _, b in pairs(craftReagentBtns) do b:Hide() end
    end
end

local tsTrackAllBtn = nil
local function EnsureTradeSkillTrackAllButton()
    if not TradeSkillFrame then return end
    if not tsTrackAllBtn then
        tsTrackAllBtn = CreateFrame("Button", "NexKitTradeSkillTrackAllBtn", UIParent, "BackdropTemplate")
        tsTrackAllBtn:SetSize(125, 22)
        tsTrackAllBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tsTrackAllBtn:SetBackdropColor(0.08, 0.12, 0.16, 0.94)
        tsTrackAllBtn:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.85)
        local lbl = tsTrackAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetText("+ Traccia Reagenti")
        lbl:SetTextColor(TRACKED.r, TRACKED.g, TRACKED.b, 1)
        tsTrackAllBtn.label = lbl
        tsTrackAllBtn:SetFrameStrata("HIGH")

        tsTrackAllBtn:SetScript("OnClick", function()
            if not GetTradeSkillSelectionIndex or not GetTradeSkillNumReagents then return end
            local idx = GetTradeSkillSelectionIndex()
            local numR = (idx and idx > 0 and GetTradeSkillNumReagents(idx)) or 0
            if numR == 0 then return end
            local anyAdded = false
            for r = 1, numR do
                local rName, rTex = GetTradeSkillReagentInfo(idx, r)
                local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
                local rID = ExtractItemIDFromLink(rLink)
                if not FP:IsReagentTracked(rID, rName) then
                    FP:ToggleTrackReagent(rID, rName, rTex or (rID and GetItemIconCompat(rID)), rLink, true)
                    anyAdded = true
                end
            end
            if not anyAdded then
                for r = 1, numR do
                    local rName = GetTradeSkillReagentInfo(idx, r)
                    local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    FP:ToggleTrackReagent(rID, rName, nil, rLink, true)
                end
                FP:Print("NexusKit: Rimossi reagenti dal tracking.")
            else
                FP:Print("NexusKit: Reagenti aggiunti al tracking!")
            end
            FP:RefreshReagentTrackerUI()
            UpdateBlizzardReagentButtons()
        end)
    end

    if TradeSkillFrame:IsShown() and TradeSkillFrame:IsVisible() then
        local anchorRef = TradeSkillCreateAllButton or TradeSkillCreateButton or TradeSkillCancelButton
        local aLeft = anchorRef and anchorRef.GetLeft and anchorRef:GetLeft()
        local aBot = anchorRef and anchorRef.GetBottom and anchorRef:GetBottom()
        if aLeft and aBot then
            local scale = anchorRef:GetEffectiveScale() / UIParent:GetEffectiveScale()
            tsTrackAllBtn:ClearAllPoints()
            tsTrackAllBtn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (aLeft - 130) * scale, aBot * scale)
            tsTrackAllBtn:Show()
        else
            local fLeft = TradeSkillFrame.GetLeft and TradeSkillFrame:GetLeft()
            local fBot = TradeSkillFrame.GetBottom and TradeSkillFrame:GetBottom()
            if fLeft and fBot then
                local scale = TradeSkillFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
                tsTrackAllBtn:ClearAllPoints()
                tsTrackAllBtn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (fLeft + 20) * scale, (fBot + 42) * scale)
                tsTrackAllBtn:Show()
            else
                tsTrackAllBtn:Hide()
            end
        end
    else
        tsTrackAllBtn:Hide()
    end
end

local craftTrackAllBtn = nil
local function EnsureCraftTrackAllButton()
    if not CraftFrame then return end
    if not craftTrackAllBtn then
        craftTrackAllBtn = CreateFrame("Button", "NexKitCraftTrackAllBtn", UIParent, "BackdropTemplate")
        craftTrackAllBtn:SetSize(125, 22)
        craftTrackAllBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        craftTrackAllBtn:SetBackdropColor(0.08, 0.12, 0.16, 0.94)
        craftTrackAllBtn:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.85)
        local lbl = craftTrackAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetText("+ Traccia Reagenti")
        lbl:SetTextColor(TRACKED.r, TRACKED.g, TRACKED.b, 1)
        craftTrackAllBtn.label = lbl
        craftTrackAllBtn:SetFrameStrata("HIGH")

        craftTrackAllBtn:SetScript("OnClick", function()
            if not GetCraftSelectionIndex or not GetCraftNumReagents then return end
            local idx = GetCraftSelectionIndex()
            local numR = (idx and idx > 0 and GetCraftNumReagents(idx)) or 0
            if numR == 0 then return end
            local anyAdded = false
            for r = 1, numR do
                local rName, rTex = GetCraftReagentInfo(idx, r)
                local rLink = GetCraftReagentItemLink and GetCraftReagentItemLink(idx, r)
                local rID = ExtractItemIDFromLink(rLink)
                if not FP:IsReagentTracked(rID, rName) then
                    FP:ToggleTrackReagent(rID, rName, rTex or (rID and GetItemIconCompat(rID)), rLink, true)
                    anyAdded = true
                end
            end
            if not anyAdded then
                for r = 1, numR do
                    local rName = GetCraftReagentInfo(idx, r)
                    local rLink = GetCraftReagentItemLink and GetCraftReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    FP:ToggleTrackReagent(rID, rName, nil, rLink, true)
                end
                FP:Print("NexusKit: Rimossi reagenti dal tracking.")
            else
                FP:Print("NexusKit: Reagenti aggiunti al tracking!")
            end
            FP:RefreshReagentTrackerUI()
            UpdateBlizzardReagentButtons()
        end)
    end

    if CraftFrame:IsShown() and CraftFrame:IsVisible() then
        local anchorRef = CraftCreateButton or CraftCancelButton
        local aLeft = anchorRef and anchorRef.GetLeft and anchorRef:GetLeft()
        local aBot = anchorRef and anchorRef.GetBottom and anchorRef:GetBottom()
        if aLeft and aBot then
            local scale = anchorRef:GetEffectiveScale() / UIParent:GetEffectiveScale()
            craftTrackAllBtn:ClearAllPoints()
            craftTrackAllBtn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (aLeft - 130) * scale, aBot * scale)
            craftTrackAllBtn:Show()
        else
            local fLeft = CraftFrame.GetLeft and CraftFrame:GetLeft()
            local fBot = CraftFrame.GetBottom and CraftFrame:GetBottom()
            if fLeft and fBot then
                local scale = CraftFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
                craftTrackAllBtn:ClearAllPoints()
                craftTrackAllBtn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (fLeft + 20) * scale, (fBot + 42) * scale)
                craftTrackAllBtn:Show()
            else
                craftTrackAllBtn:Hide()
            end
        end
    else
        craftTrackAllBtn:Hide()
    end
end

function FP:RefreshProfSlotOverlays()
    EnsureTradeSkillTrackAllButton()
    EnsureCraftTrackAllButton()
    UpdateBlizzardReagentButtons()
    local used = 0
    local seenTargets = {}
    local forms = {}
    if ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm then
        forms[#forms + 1] = ProfessionsFrame.CraftingPage.SchematicForm
    end
    if ProfessionsFrame and ProfessionsFrame.OrdersPage and ProfessionsFrame.OrdersPage.OrderView
        and ProfessionsFrame.OrdersPage.OrderView.OrderDetails
        and ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm then
        forms[#forms + 1] = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm
    end

    for _, form in ipairs(forms) do
        if form and not IsForbiddenObj(form) and form:IsShown() then
            HookSchematicFormObj(form)
            local bySlotIdx, orderedIDs = BuildRecipeReagentLookup(form)
            local slots = CollectModernSchematicSlots(form)
            for idx, slot in ipairs(slots) do
                local targetBtn = (slot and not IsForbiddenObj(slot) and (slot.Button or slot.Item or slot.Icon or slot)) or nil
                if targetBtn and not IsForbiddenObj(targetBtn) and not seenTargets[targetBtn] and targetBtn:IsVisible() then
                    local itemID, itemName, icon, link = ResolveModernReagentSlotInfo(slot, bySlotIdx, orderedIDs[idx])
                    -- Only bind name-only slots when they resemble an actual reagent line or have an icon, skipping empty optional slots
                    local hasVisualReagent = itemID or (IsSafeStr(itemName) and (icon ~= nil or IsKnownRecipeReagent(nil, itemName) or FP:IsReagentTracked(nil, itemName)))
                    if hasVisualReagent then
                        seenTargets[targetBtn] = true
                        used = used + 1
                        local ov = profOvPool[used]
                        if not ov then
                            ov = CreateSlotOverlay(profOverlayHost, 36, true, false)
                            profOvPool[used] = ov
                        end
                        if SyncOverlayToTarget(ov, profOverlayHost, targetBtn, ProfessionsFrame) then
                            ApplyReagentOverlayState(ov, itemID, itemName, icon, link, true)
                        else
                            HideSlotOverlay(ov)
                        end
                    end
                end
            end
        end
    end

    if TradeSkillFrame and not IsForbiddenObj(TradeSkillFrame) and TradeSkillFrame:IsShown() and GetTradeSkillSelectionIndex and GetTradeSkillNumReagents then
        local idx = GetTradeSkillSelectionIndex()
        local numR = (idx and idx > 0 and GetTradeSkillNumReagents(idx)) or 0
        for r = 1, math.min(8, numR) do
            local btn = _G["TradeSkillReagent" .. r]
            if btn and not IsForbiddenObj(btn) and IsRegionVisible(btn) then
                local iconTarget = _G["TradeSkillReagent" .. r .. "IconTexture"] or btn
                if iconTarget and not IsForbiddenObj(iconTarget) then
                    used = used + 1
                    local ov = profOvPool[used]
                    if not ov then
                        ov = CreateSlotOverlay(profOverlayHost, 34, true, false)
                        profOvPool[used] = ov
                    end
                    local rName, rTex = GetTradeSkillReagentInfo and GetTradeSkillReagentInfo(idx, r)
                    local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    local rIcon = rTex or (rID and GetItemIconCompat(rID)) or nil
                    if SyncOverlayToTarget(ov, profOverlayHost, iconTarget, TradeSkillFrame) then
                        ApplyReagentOverlayState(ov, rID, rName, rIcon, rLink, true)
                    else
                        HideSlotOverlay(ov)
                    end
                end
            end
        end
    end

    if CraftFrame and not IsForbiddenObj(CraftFrame) and CraftFrame:IsShown() and GetCraftSelectionIndex and GetCraftNumReagents then
        local idx = GetCraftSelectionIndex()
        local numR = (idx and idx > 0 and GetCraftNumReagents(idx)) or 0
        for r = 1, math.min(8, numR) do
            local btn = _G["CraftReagent" .. r]
            if btn and not IsForbiddenObj(btn) and IsRegionVisible(btn) then
                local iconTarget = _G["CraftReagent" .. r .. "IconTexture"] or btn
                if iconTarget and not IsForbiddenObj(iconTarget) then
                    used = used + 1
                    local ov = profOvPool[used]
                    if not ov then
                        ov = CreateSlotOverlay(profOverlayHost, 34, true, false)
                        profOvPool[used] = ov
                    end
                    local rName, rTex = GetCraftReagentInfo and GetCraftReagentInfo(idx, r)
                    local rLink = GetCraftReagentItemLink and GetCraftReagentItemLink(idx, r)
                    local rID = ExtractItemIDFromLink(rLink)
                    local rIcon = rTex or (rID and GetItemIconCompat(rID)) or nil
                    if SyncOverlayToTarget(ov, profOverlayHost, iconTarget, CraftFrame) then
                        ApplyReagentOverlayState(ov, rID, rName, rIcon, rLink, true)
                    else
                        HideSlotOverlay(ov)
                    end
                end
            end
        end
    end

    for i = used + 1, #profOvPool do
        HideSlotOverlay(profOvPool[i])
    end
    if used > 0 then
        profOverlayHost:Show()
    else
        profOverlayHost:Hide()
    end
end

-------------------------------------------------------------------------------
-- 3. Bag Slot Overlays
-------------------------------------------------------------------------------
local EnsureHooks
local bagOvPool = {}

local function IsValidVisibleFrame(f)
    return f and not IsForbiddenObj(f) and f.IsVisible and f:IsVisible()
end

local function IsAnyBagFrameVisible()
    if ContainerFrameCombinedBags and not IsForbiddenObj(ContainerFrameCombinedBags) and ContainerFrameCombinedBags:IsShown() then
        return true
    end
    local numContainers = NUM_CONTAINER_FRAMES or 13
    for i = 1, numContainers do
        local cf = _G["ContainerFrame" .. i]
        if cf and not IsForbiddenObj(cf) and cf:IsShown() then
            return true
        end
    end
    if ContainerFrameContainer and type(ContainerFrameContainer.ContainerFrames) == "table" then
        for _, cf in ipairs(ContainerFrameContainer.ContainerFrames) do
            if cf and not IsForbiddenObj(cf) and cf:IsShown() then
                return true
            end
        end
    end
    return false
end

local function ForEachVisibleBagFrame(fn)
    local seen = {}
    local function Check(cf)
        if cf and not IsForbiddenObj(cf) and cf:IsShown() and not seen[cf] then
            seen[cf] = true
            fn(cf)
        end
    end
    Check(ContainerFrameCombinedBags)
    local numContainers = NUM_CONTAINER_FRAMES or 13
    for i = 1, numContainers do
        Check(_G["ContainerFrame" .. i])
    end
    if ContainerFrameContainer and type(ContainerFrameContainer.ContainerFrames) == "table" then
        for _, cf in ipairs(ContainerFrameContainer.ContainerFrames) do
            Check(cf)
        end
    end
end

local bagOverlayHost = CreateOverlayHost("NexusKitBagOverlayHost", bagOvPool)

local function SafeCallNum(obj, method)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj)
    if ok and IsSafeNum(val) then return val end
    return nil
end

local BAG_FALLBACK_REAGENT_IDS = {
    -- Drinks / Food / Cooking Ingredients
    [159] = true,   -- Refreshing Spring Water
    [723] = true,   -- Goretusk Liver
    [729] = true,   -- Stringy Vulture Meat
    [730] = true,   -- Murloc Eye
    [731] = true,   -- Goretusk Snout
    [769] = true,   -- Chunk of Boar Meat
    [1015] = true,  -- Lean Wolf Flank
    [1080] = true,  -- Tough Condor Meat
    [1179] = true,  -- Ice Cold Milk
    [1468] = true,  -- Murloc Fin
    [2596] = true,  -- Skin of Dwarven Stout
    [2672] = true,  -- Stringy Wolf Meat
    [2673] = true,  -- Coyote Meat
    [2674] = true,  -- Crawler Claw
    [2675] = true,  -- Crawler Meat
    [2677] = true,  -- Boar Ribs
    [2678] = true,  -- Mild Spices
    [2692] = true,  -- Hot Spices
    [2886] = true,  -- Crag Boar Rib
    [2894] = true,  -- Rhapsody Malt
    [3173] = true,  -- Bear Meat
    [3713] = true,  -- Soothing Spices
    [3730] = true,  -- Big Bear Meat
    [4536] = true,  -- Shiny Red Apple
    [5503] = true,  -- Clam Meat
    [5504] = true,  -- Tangy Clam Meat
    [6289] = true,  -- Longjaw Mud Snapper
    [6291] = true,  -- Raw Brilliant Smallfish
    [6303] = true,  -- Raw Slitherskin Mackerel
    [6308] = true,  -- Raw Bristle Whisker Catfish
    [6317] = true,  -- Raw Loch Frenzy
    [6889] = true,  -- Small Egg
    [7974] = true,  -- Zesty Clam Meat
    [12203] = true, -- Red Wolf Meat
    [12208] = true, -- Tender Wolf Meat

    -- Cloths
    [2589] = true,  -- Linen Cloth
    [2592] = true,  -- Wool Cloth
    [4306] = true,  -- Silk Cloth
    [4338] = true,  -- Mageweave Cloth
    [14047] = true, -- Runecloth
    [14048] = true, -- Felcloth

    -- Leathers & Hides
    [2934] = true,  -- Ruined Leather Scraps
    [2318] = true,  -- Light Leather
    [2319] = true,  -- Medium Leather
    [4234] = true,  -- Heavy Leather
    [4304] = true,  -- Thick Leather
    [8170] = true,  -- Rugged Leather
    [783]  = true,  -- Light Hide
    [4232] = true,  -- Medium Hide
    [4235] = true,  -- Heavy Hide
    [8169] = true,  -- Thick Hide

    -- Ores, Stones & Bars
    [2770] = true,  -- Copper Ore
    [2771] = true,  -- Tin Ore
    [2775] = true,  -- Silver Ore
    [2772] = true,  -- Iron Ore
    [2776] = true,  -- Gold Ore
    [3858] = true,  -- Mithril Ore
    [7911] = true,  -- Truesilver Ore
    [10620] = true, -- Thorium Ore
    [2840] = true,  -- Copper Bar
    [3576] = true,  -- Tin Bar
    [2841] = true,  -- Bronze Bar
    [2842] = true,  -- Silver Bar
    [3575] = true,  -- Iron Bar
    [3859] = true,  -- Steel Bar
    [3577] = true,  -- Gold Bar
    [3860] = true,  -- Mithril Bar
    [6037] = true,  -- Truesilver Bar
    [12359] = true, -- Thorium Bar
    [2835] = true,  -- Rough Stone
    [2836] = true,  -- Coarse Stone
    [2838] = true,  -- Heavy Stone
    [7912] = true,  -- Solid Stone
    [12365] = true, -- Dense Stone

    -- Herbs
    [765]  = true,  -- Silverleaf
    [2447] = true,  -- Peacebloom
    [2449] = true,  -- Earthroot
    [785]  = true,  -- Mageroyal
    [2450] = true,  -- Briarthorn
    [2453] = true,  -- Bruiseweed
    [3820] = true,  -- Stranglekelp
    [3355] = true,  -- Wild Steelbloom
    [3369] = true,  -- Grave Moss
    [3356] = true,  -- Kingsblood
    [3357] = true,  -- Liferoot
    [3818] = true,  -- Fadeleaf
    [3821] = true,  -- Goldthorn
    [3358] = true,  -- Khadgar's Whisker
    [3819] = true,  -- Wintersbite
    [4625] = true,  -- Firebloom
    [8831] = true,  -- Purple Lotus
    [8836] = true,  -- Arthas' Tears
    [8838] = true,  -- Sungrass
    [8839] = true,  -- Blindweed
    [8845] = true,  -- Ghost Mushroom
    [8846] = true,  -- Gromsblood
    [13464] = true, -- Golden Sansam
    [13463] = true, -- Dreamfoil
    [13465] = true, -- Mountain Silversage
    [13466] = true, -- Plaguebloom
    [13468] = true, -- Black Lotus

    -- Threads, Flux, Vials & Vendor Reagents
    [2320] = true,  -- Coarse Thread
    [2321] = true,  -- Fine Thread
    [4291] = true,  -- Silken Thread
    [8343] = true,  -- Heavy Silken Thread
    [14341] = true, -- Rune Thread
    [2604] = true,  -- Bleach
    [2880] = true,  -- Weak Flux
    [3466] = true,  -- Strong Flux
    [3371] = true,  -- Empty Vial
    [3372] = true,  -- Leaded Vial
    [8925] = true,  -- Crystal Vial
    [3857] = true,  -- Coal

    -- Gems & Pearls
    [774]  = true,  -- Malachite
    [818]  = true,  -- Tigerseye
    [1210] = true,  -- Shadowgem
    [1206] = true,  -- Moss Agate
    [1705] = true,  -- Lesser Moonstone
    [7971] = true,  -- Jade
    [7909] = true,  -- Citrine
    [7910] = true,  -- Aquamarine
    [7972] = true,  -- Star Ruby

    -- Class & Spell Reagents (Mage, Priest, Shaman, Druid, Paladin, Warlock, Rogue, etc.)
    [17056] = true, -- Light Feather (Piuma Leggera - Mage Slow Fall, Priest Levitate)
    [17057] = true, -- Shiny Fish Scales (Scaglie di Pesce Lucenti - Shaman Water Walking)
    [17058] = true, -- Fish Oil (Olio di Pesce - Shaman Water Breathing)
    [17020] = true, -- Arcane Powder (Polvere Arcana - Mage Arcane Brilliance)
    [17031] = true, -- Rune of Teleportation (Runa del Teletrasporto - Mage Portals)
    [17032] = true, -- Rune of Portals (Runa dei Portali - Mage Portals)
    [17028] = true, -- Wild Berries (Bacche Selvatiche - Druid Gift of the Wild)
    [17029] = true, -- Wild Thornroot (Radice di Spina Selvatica - Druid Gift of the Wild)
    [17033] = true, -- Symbol of Divinity (Simbolo della Divinità - Paladin Rebirth)
    [21177] = true, -- Symbol of Kings (Simbolo dei Re - Paladin Greater Blessings)
    [17026] = true, -- Sacred Candle (Candela Consacrata - Priest Prayer of Fortitude)
    [17055] = true, -- Holy Candle (Candela Benedetta - Priest Prayer of Shadow Protection)
    [5565]  = true, -- Soul Shard (Frammento d'Anima - Warlock)
    [6265]  = true, -- Soul Shard (Frammento d'Anima - Warlock)
    [16583] = true, -- Demonic Figurine (Statuetta Demoniaca - Warlock Doomguard)
    [5140]  = true, -- Flash Powder (Polvere Accecante - Rogue Vanish)
    [5139]  = true, -- Dust of Deterioration (Polvere di Deterioramento - Rogue Poisons)
    [8924]  = true, -- Dust of Decay (Polvere del Decadimento - Rogue Poisons)
    [8923]  = true, -- Essence of Pain (Essenza del Dolore - Rogue Poisons)
    [4470]  = true, -- Simple Wood (Legna Semplice - Campfire)
    [4471]  = true, -- Flint and Tinder (Pietra Focaia ed Esca - Campfire)
    [5060]  = true, -- Linen Bandage (Bende di Lino)
    [3530]  = true, -- Heavy Linen Bandage (Bende di Lino Pesanti)
    [3531]  = true, -- Wool Bandage (Bende di Lana)
    [6450]  = true, -- Silk Bandage (Bende di Seta)
    [8544]  = true, -- Mageweave Bandage (Bende di Magitessuto)
    [14529] = true, -- Runecloth Bandage (Bende di Runatessuto)
}

local function IsBagTrackableReagent(itemID, link, name, isTracked, isKeep, isSkill, quality)
    if not IsSafeNum(itemID) or itemID <= 0 then
        return false
    end

    -- 1. Explicit exclusions: Hearthstone (6948)
    if itemID == 6948 then
        return false
    end

    -- 2. If already tracked, keep, or skill reagent, always trackable
    if isTracked or isKeep or isSkill then
        return true
    end

    -- 3. Known recipe reagent for player's learned professions
    if IsKnownRecipeReagent(itemID, name) then
        return true
    end

    -- 4. Fallback reagents (cloth, meat, herbs, ore, leather, spices, etc.)
    if BAG_FALLBACK_REAGENT_IDS[itemID] then
        return true
    end

    -- 5. Query item info (sync via C_Item.GetItemInfoInstant or GetSafeItemInfo)
    local classID, equipLoc
    if C_Item and C_Item.GetItemInfoInstant then
        local okInst, _, _, _, eqLoc, _, cID = pcall(C_Item.GetItemInfoInstant, itemID)
        if okInst then
            classID = cID
            equipLoc = eqLoc
        end
    end

    local info = GetSafeItemInfo(link or itemID)
    if info then
        classID = classID or info.classID
        equipLoc = equipLoc or info.equipLoc
        quality = quality or info.quality
    end

    -- Exclude gear: weapons (class 2), armor (class 4), containers (class 1), keys (class 13)
    if classID == 2 or classID == 4 or classID == 1 or classID == 13 then
        return false
    end
    if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP" then
        return false
    end

    -- Exclude junk (grey quality 0) unless it's a known recipe or fallback reagent
    if (quality == 0 or (info and info.quality == 0)) and not BAG_FALLBACK_REAGENT_IDS[itemID] and not IsKnownRecipeReagent(itemID, name) then
        return false
    end

    return true
end

local function ExtractBagSlotFromItemLocation(loc)
    if type(loc) ~= "table" or IsForbiddenObj(loc) then return nil, nil end
    local bag, slot
    if loc.GetBagAndSlot then
        local okLoc, bL, sL = pcall(loc.GetBagAndSlot, loc)
        if okLoc then
            if IsSafeNum(bL) and bL >= 0 then bag = bL end
            if IsSafeNum(sL) and sL > 0 then slot = sL end
        end
    end
    if not bag and IsSafeNum(loc.bagID) and loc.bagID >= 0 then bag = loc.bagID end
    if not slot and IsSafeNum(loc.slotIndex) and loc.slotIndex > 0 then slot = loc.slotIndex end
    return bag, slot
end

local function ReadElementBagAndSlot(ed, bag, slot)
    if type(ed) ~= "table" or IsForbiddenObj(ed) then return bag, slot end
    if not bag then
        bag = (IsSafeNum(ed.bagID) and ed.bagID >= 0 and ed.bagID)
            or (IsSafeNum(ed.bagIndex) and ed.bagIndex >= 0 and ed.bagIndex)
            or (IsSafeNum(ed.bag) and ed.bag >= 0 and ed.bag)
            or SafeCallNum(ed, "GetBagID")
            or nil
        if bag and bag < 0 then bag = nil end
    end
    if not slot then
        slot = (IsSafeNum(ed.slotIndex) and ed.slotIndex > 0 and ed.slotIndex)
            or (IsSafeNum(ed.slotID) and ed.slotID > 0 and ed.slotID)
            or (IsSafeNum(ed.slot) and ed.slot > 0 and ed.slot)
            or SafeCallNum(ed, "GetSlotIndex")
            or SafeCallNum(ed, "GetID")
            or nil
        if slot and slot <= 0 then slot = nil end
    end
    if (not bag or not slot) and ed.itemLocation then
        local bL, sL = ExtractBagSlotFromItemLocation(ed.itemLocation)
        if not bag and bL then bag = bL end
        if not slot and sL then slot = sL end
    end
    return bag, slot
end

local function GetBagAndSlotFromButton(itemBtn, parentWindow)
    local bag = SafeCallNum(itemBtn, "GetBagID")
    if bag and bag < 0 then bag = nil end
    -- Retail combined bag buttons can report GetID() == 0; normalize <= 0 so fallbacks still run
    local slot = SafeCallNum(itemBtn, "GetID")
    if slot and slot <= 0 then slot = nil end

    if not bag then
        for _, k in ipairs({ "bagID", "BagID", "bag", "bagIndex" }) do
            if IsSafeNum(itemBtn[k]) and itemBtn[k] >= 0 then bag = itemBtn[k] break end
        end
    end
    if not slot then
        for _, k in ipairs({ "slotID", "slotIndex", "slot" }) do
            if IsSafeNum(itemBtn[k]) and itemBtn[k] > 0 then slot = itemBtn[k] break end
        end
    end
    if (not bag or not slot) and itemBtn.GetSlotAndBagID then
        local okSB, s2, b2 = pcall(itemBtn.GetSlotAndBagID, itemBtn)
        if okSB then
            if not slot and IsSafeNum(s2) and s2 > 0 then slot = s2 end
            if not bag and IsSafeNum(b2) and b2 >= 0 then bag = b2 end
        end
    end
    if (not bag or not slot) and itemBtn.GetItemLocation then
        local okIL, loc = pcall(itemBtn.GetItemLocation, itemBtn)
        if okIL then
            local bL, sL = ExtractBagSlotFromItemLocation(loc)
            if not bag and bL then bag = bL end
            if not slot and sL then slot = sL end
        end
    end
    if (not bag or not slot) and itemBtn.GetElementData then
        local okED, ed = pcall(itemBtn.GetElementData, itemBtn)
        if okED and type(ed) == "table" then
            bag, slot = ReadElementBagAndSlot(ed, bag, slot)
            if (not bag or not slot) and type(ed.data) == "table" then
                bag, slot = ReadElementBagAndSlot(ed.data, bag, slot)
            end
            if (not bag or not slot) and type(ed.itemData) == "table" then
                bag, slot = ReadElementBagAndSlot(ed.itemData, bag, slot)
            end
        end
    end
    if not bag and itemBtn.GetParent then
        local okP, p = pcall(itemBtn.GetParent, itemBtn)
        if okP and p and not IsForbiddenObj(p) and p ~= ContainerFrameCombinedBags and p ~= UIParent then
            local pBag = SafeCallNum(p, "GetBagID") or SafeCallNum(p, "GetID")
            if pBag and pBag >= 0 then bag = pBag end
        end
    end
    if not bag and parentWindow and parentWindow ~= ContainerFrameCombinedBags then
        local pBag = SafeCallNum(parentWindow, "GetBagID") or SafeCallNum(parentWindow, "GetID")
        if pBag and pBag >= 0 then bag = pBag end
    end
    return bag, slot
end

local function ReadContainerSlotItem(bag, slot)
    local itemID, link, name, icon, quality
    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if ok and type(info) == "table" then
            itemID = IsSafeNum(info.itemID) and info.itemID or nil
            link = IsSafeStr(info.hyperlink) and info.hyperlink or nil
            name = IsSafeStr(info.itemName) and info.itemName or nil
            icon = info.iconFileID
            quality = IsSafeNum(info.quality) and info.quality or nil
        end
    end
    if not itemID and C_Container and C_Container.GetContainerItemID then
        local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok and IsSafeNum(id) then itemID = id end
    elseif not itemID and GetContainerItemID then
        local ok, id = pcall(GetContainerItemID, bag, slot)
        if ok and IsSafeNum(id) then itemID = id end
    end
    if not link and C_Container and C_Container.GetContainerItemLink then
        local ok, l = pcall(C_Container.GetContainerItemLink, bag, slot)
        if ok and IsSafeStr(l) then link = l end
    elseif not link and GetContainerItemLink then
        local ok, l = pcall(GetContainerItemLink, bag, slot)
        if ok and IsSafeStr(l) then link = l end
    end
    if (not icon or not quality) and GetContainerItemInfo then
        local okL, tex, _, _, q, _, _, itemLink = pcall(GetContainerItemInfo, bag, slot)
        if okL then
            icon = icon or tex
            quality = quality or (IsSafeNum(q) and q or nil)
            link = link or (IsSafeStr(itemLink) and itemLink or nil)
        end
    end
    return itemID, link, name, icon, quality
end

local function PopulateBagOverlayForItem(itemBtn, parentWindow, itemID, link, name, icon, quality, usedRef)
    if not itemBtn or IsForbiddenObj(itemBtn) or not (itemBtn.IsVisible and itemBtn:IsVisible()) then return end
    if not itemID and IsSafeStr(link) then
        itemID = ExtractItemIDFromLink(link)
    end
    if not itemID or itemID <= 0 then return end

    if not name or not icon then
        local okInfo, iName, iLink, iQual, _, _, _, _, _, _, iTex = GetItemInfoCompat(link or itemID)
        if okInfo then
            if not name and IsSafeStr(iName) then name = iName end
            if not link and IsSafeStr(iLink) then link = iLink end
            if not quality and IsSafeNum(iQual) then quality = iQual end
            if not icon then icon = iTex end
        end
    end

    local isTracked = FP:IsReagentTracked(itemID, name)
    local isKeep = IsQuestKeepEnabled() and FP.GetQuestKeepInfo and (FP:GetQuestKeepInfo(itemID, name) ~= nil)
    local isSkill = IsHighlightEnabled() and (FP:GetSkillUpReagentInfo(itemID, name) ~= nil)
    local showBtn = IsBagTrackButtonsEnabled() and IsBagTrackableReagent(itemID, link, name, isTracked, isKeep, isSkill, quality)
    if not isTracked and not isKeep and not isSkill and not showBtn then return end

    usedRef[1] = usedRef[1] + 1
    local ov = bagOvPool[usedRef[1]]
    if not ov then
        ov = CreateSlotOverlay(bagOverlayHost, 36, true, true)
        bagOvPool[usedRef[1]] = ov
    end
    if SyncOverlayToTarget(ov, bagOverlayHost, itemBtn, parentWindow) then
        ApplyReagentOverlayState(ov, itemID, name, icon, link, showBtn)
    else
        HideSlotOverlay(ov)
    end
end

local function CollectButtonsFromContainer(win, Add)
    if not win or IsForbiddenObj(win) or not (win.IsShown and win:IsShown()) then return end

    -- 1. EnumerateValidItems (Standard Blizzard modern container iterator)
    if win.EnumerateValidItems then
        pcall(function()
            for btn in win:EnumerateValidItems() do
                Add(btn, win)
            end
        end)
    end

    -- 2. itemButtonPool (ObjectPool / FramePool in modern Blizzard ContainerFrame)
    if win.itemButtonPool and win.itemButtonPool.EnumerateActive then
        pcall(function()
            for btn, _ in win.itemButtonPool:EnumerateActive() do
                Add(btn, win)
            end
        end)
    end

    -- 3. Items array/table
    if type(win.Items) == "table" then
        for _, btn in ipairs(win.Items) do
            Add(btn, win)
        end
    end

    -- 4. ScrollBox items (Combined bags or modern container frames with scroll box)
    if win.ScrollBox and win.ScrollBox.GetFrames then
        pcall(function()
            local frames = win.ScrollBox:GetFrames()
            if type(frames) == "table" then
                for _, btn in ipairs(frames) do
                    Add(btn, win)
                end
            end
        end)
    end

    -- 5. Global indexed names (Legacy Classic / standard ContainerFrame Item buttons)
    local winName = win.GetName and win:GetName()
    if winName then
        local maxSlots = tonumber(win.size) or 140
        for idx = 1, maxSlots do
            local btn = _G[winName .. "Item" .. idx]
            if btn then
                Add(btn, win)
            end
        end
    end

    -- 6. Direct child scan fallback (guarantees third-party bag addons and custom frames work)
    local function ScanChildren(parent, depth)
        if depth > 4 or not parent or IsForbiddenObj(parent) then return end
        if parent.GetChildren then
            local okC, kids = pcall(function() return { parent:GetChildren() } end)
            if okC and type(kids) == "table" then
                for _, k in ipairs(kids) do
                    if k and not IsForbiddenObj(k) then
                        local isItem = false
                        if k.GetBagID or k.GetSlotAndBagID or k.GetElementData or k.GetItemLocation or k.GetItemID or k.GetItem then
                            isItem = true
                        elseif k.hasItem ~= nil or k.emptyBackgroundTexture ~= nil then
                            isItem = true
                        elseif k.GetName then
                            local kn = tostring(k:GetName() or "")
                            if kn:find("Item%d+$") then isItem = true end
                        end
                        if isItem then
                            Add(k, win)
                        else
                            ScanChildren(k, depth + 1)
                        end
                    end
                end
            end
        end
    end
    ScanChildren(win, 1)
end

local function GetVisibleBagButtons()
    local list = {}
    local seen = {}
    local function Add(btn, win)
        if btn and not IsForbiddenObj(btn) and not seen[btn] then
            local isVis = (btn.IsVisible and btn:IsVisible()) or (btn.IsShown and btn:IsShown())
            if isVis then
                seen[btn] = true
                list[#list + 1] = { btn = btn, win = win }
            end
        end
    end

    ForEachVisibleBagFrame(function(cf)
        CollectButtonsFromContainer(cf, Add)
    end)

    return list
end

local function BuildBagSlotFrameIndex()
    local map = {}
    local total = 0
    local btns = GetVisibleBagButtons()
    for _, entry in ipairs(btns) do
        local b = entry.btn
        local w = entry.win
        local bag, slot = GetBagAndSlotFromButton(b, w)
        if IsSafeNum(bag) and IsSafeNum(slot) then
            local key = bag .. ":" .. slot
            if not map[key] then
                map[key] = { btn = b, win = w }
                total = total + 1
            end
        end
    end
    return map, total
end

function FP:RefreshBagOverlays()
    if InCombatLockdown and InCombatLockdown() then return end

    if not IsAnyBagFrameVisible() then
        bagOverlayHost:Hide()
        for _, ov in ipairs(bagOvPool) do
            HideSlotOverlay(ov)
        end
        return
    end

    local bagButtons = GetVisibleBagButtons()
    local used = 0

    for _, entry in ipairs(bagButtons) do
        local itemBtn = entry.btn
        local win = entry.win
        local bag, slot = GetBagAndSlotFromButton(itemBtn, win)
        local itemID, link, name, icon, quality

        if IsSafeNum(bag) and bag >= 0 and IsSafeNum(slot) and slot > 0 then
            itemID, link, name, icon, quality = ReadContainerSlotItem(bag, slot)
        end

        if not itemID and itemBtn.GetItemID then
            local ok, id = pcall(itemBtn.GetItemID, itemBtn)
            if ok and IsSafeNum(id) and id > 0 then itemID = id end
        end
        if not itemID and itemBtn.GetItem then
            local ok, id = pcall(itemBtn.GetItem, itemBtn)
            if ok and IsSafeNum(id) and id > 0 then itemID = id end
        end
        if not link and itemBtn.GetItemLink then
            local ok, l = pcall(itemBtn.GetItemLink, itemBtn)
            if ok and IsSafeStr(l) then link = l end
        end
        if not itemID and IsSafeStr(link) then
            itemID = ExtractItemIDFromLink(link)
        end

        if itemID or IsSafeStr(name) then
            local info = GetSafeItemInfo(link or itemID)
            if info then
                name = name or info.name
                link = link or info.link
                quality = quality or info.quality
                icon = icon or info.texture
            end

            local isTracked = FP:IsReagentTracked(itemID, name)
            local isKeep = IsQuestKeepEnabled() and FP.GetQuestKeepInfo and (FP:GetQuestKeepInfo(itemID, name) ~= nil)
            local isSkill = IsHighlightEnabled() and (FP:GetSkillUpReagentInfo(itemID, name) ~= nil)
            local isTrackable = IsBagTrackableReagent(itemID, link, name, isTracked, isKeep, isSkill, quality)
            local showBtn = IsBagTrackButtonsEnabled() and isTrackable

            -- ONLY create/show overlay for valid reagents, tracked items, quest keeps, or skill reagents!
            -- Non-reagents (swords, shields, hearthstone, armor, food, potions, junk) are completely skipped.
            if isTrackable and (isTracked or isKeep or isSkill or showBtn) then
                used = used + 1
                local ov = bagOvPool[used]
                if not ov then
                    ov = CreateSlotOverlay(bagOverlayHost, 36, true, false)
                    bagOvPool[used] = ov
                end

                ov.targetRef = itemBtn
                ov.windowRef = win

                local okSync = SyncOverlayToTarget(ov, bagOverlayHost, itemBtn, win)
                if okSync then
                    ApplyReagentOverlayState(ov, itemID, name, icon, link, showBtn)
                else
                    HideSlotOverlay(ov)
                    used = used - 1
                end
            end
        end
    end

    for i = used + 1, #bagOvPool do
        HideSlotOverlay(bagOvPool[i])
    end
    bagOverlayHost.lastUsed = used
    if used > 0 then
        bagOverlayHost:Show()
    else
        bagOverlayHost:Hide()
    end
end

-------------------------------------------------------------------------------
-- 4. Tooltip Annotations
-------------------------------------------------------------------------------
local function AppendQuestKeepTooltipLines(tooltip, keepInfo, L)
    if not tooltip or not keepInfo or not keepInfo.quests or #keepInfo.quests == 0 then return end
    tooltip:AddLine(L["QUEST_KEEP_TIP_HEADER"] or "|cffffb020[NexusKit - Do Not Sell!]|r Needed for quests:",
        1.0, 0.72, 0.18, true)

    local totalHave = keepInfo.totalCount or keepInfo.bagCount or 0
    local shown = 0
    for _, q in ipairs(keepInfo.quests) do
        shown = shown + 1
        if shown > 4 then
            tooltip:AddLine(string.format(L["QUEST_KEEP_TIP_MORE"] or "  + %d more...", #keepInfo.quests - 4),
                0.85, 0.78, 0.55, false)
            break
        end

        local tag
        if q.inLog then
            tag = L["QUEST_KEEP_TAG_ACTIVE"] or "Active"
        elseif q.sameZone then
            tag = L["QUEST_KEEP_TAG_SAME_ZONE"] or "Same zone"
        else
            tag = "Lvl " .. tostring(q.level or "?")
        end

        local zonePart = (q.zoneName and q.zoneName ~= "") and (" (" .. q.zoneName .. ")") or ""
        local need = q.count or 1
        local done = totalHave >= need
        local suffix = done and (" " .. (L["QUEST_KEEP_TIP_ENOUGH"] or "(Ready)")) or ""
        local line = string.format("  [%s | Lvl %d] %s%s — %d/%d%s",
            tag, q.level or 1, q.title or "Quest", zonePart, totalHave, need, suffix)
        if done then
            tooltip:AddLine(line, 0.55, 0.98, 0.55, true)
        else
            tooltip:AddLine(line, 1.0, 0.90, 0.65, true)
        end
    end
end

local function AppendReagentTooltipLines(tooltip, itemID, itemName)
    if not tooltip or not (IsSafeNum(itemID) or IsSafeStr(itemName)) then return end
    local L = FP.L or {}
    local keepInfo = (IsQuestKeepEnabled() and FP.GetQuestKeepInfo) and FP:GetQuestKeepInfo(itemID, itemName) or nil
    if keepInfo then
        AppendQuestKeepTooltipLines(tooltip, keepInfo, L)
    end
    local skillInfo = IsHighlightEnabled() and FP:GetSkillUpReagentInfo(itemID, itemName) or nil
    if skillInfo then
        local _, _, _, hex = FP:GetAccentColor()
        local recStr = (#skillInfo.recipes > 0) and (" (" .. table.concat(skillInfo.recipes, ", ") .. ")") or ""
        local tipFmt = (L["REAGENT_TIP_SKILL"] or "|cff00ff96[NexusKit Skill-Up]|r %s%s"):gsub("|cff00ff96", "|cff" .. hex)
        tooltip:AddLine(string.format(tipFmt, table.concat(skillInfo.profs, ", "), recStr), 0.75, 1.0, 0.82, true)
    end
    if FP:IsReagentTracked(itemID, itemName) then
        local bags = itemID and GetItemCountCompat(itemID, false) or 0
        local total = itemID and GetItemCountCompat(itemID, true) or bags
        local cntStr = (total > bags) and string.format("%d (+%d bank)", bags, total - bags) or tostring(bags)
        tooltip:AddLine(string.format(L["REAGENT_TIP_TRACKED"] or "|cff40e0ff[NexKit Tracked]|r In bags: %s", cntStr),
            0.55, 0.92, 1.0, true)
        tooltip:AddLine("|cff88ccffAlt+Click to untrack|r", 0.70, 0.85, 1.0, true)
    else
        tooltip:AddLine("|cff88ccffAlt+Click or click [+] to track reagent|r", 0.60, 0.82, 0.90, true)
    end
end

local tooltipHooked = false
local function EnsureTooltipHooks()
    if tooltipHooked then return end
    tooltipHooked = true
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
            if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
            local id = data and IsSafeNum(data.id) and data.id or nil
            local name
            if tooltip.GetItem then
                local ok, iName, iLink = pcall(tooltip.GetItem, tooltip)
                if ok then
                    name = IsSafeStr(iName) and iName or nil
                    if not id and IsSafeStr(iLink) then
                        id = ExtractItemIDFromLink(iLink)
                    end
                end
            end
            AppendReagentTooltipLines(tooltip, id, name)
        end)
    else
        for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
            if tt and tt.HookScript then
                tt:HookScript("OnTooltipSetItem", function(tooltip)
                    if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
                    local ok, iName, iLink = pcall(tooltip.GetItem, tooltip)
                    if ok then
                        local id = IsSafeStr(iLink) and ExtractItemIDFromLink(iLink) or nil
                        AppendReagentTooltipLines(tooltip, id, IsSafeStr(iName) and iName or nil)
                    end
                end)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- 5. Floating Tracked Reagents HUD
-------------------------------------------------------------------------------
local hud = CreateFrame("Frame", "NexusKitReagentHUD", UIParent, "BackdropTemplate")
hud:SetSize(256, 54)
hud:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -220)
if hud.SetDontSavePosition then hud:SetDontSavePosition(true) end
hud:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})
hud:SetBackdropColor(0.05, 0.07, 0.10, 0.92)
hud:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.72)
hud:SetMovable(true)
hud:EnableMouse(true)
hud:SetClampedToScreen(true)
hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", function(self)
    local s = GetSettings()
    local locked = s.reagentHudLocked
    if locked == nil then locked = s.locked ~= false end
    if locked then return end
    self.isDragging = true
    self:StartMoving()
end)
hud:SetScript("OnDragStop", function(self)
    self.isDragging = false
    self:StopMovingOrSizing()
    if NexusKitDB and NexusKitDB.settings then
        local ux, uy = UIParent:GetCenter()
        local fx, fy = self:GetCenter()
        if ux and uy and fx and fy then
            NexusKitDB.settings.reagentHudPos = { x = fx - ux, y = fy - uy }
        end
    end
end)
hud:Hide()

hud.headerBg = hud:CreateTexture(nil, "BACKGROUND", nil, 1)
hud.headerBg:SetPoint("TOPLEFT", 1, -1)
hud.headerBg:SetPoint("TOPRIGHT", -1, -1)
hud.headerBg:SetHeight(23)
hud.headerBg:SetColorTexture(TRACKED.r * 0.22, TRACKED.g * 0.22, TRACKED.b * 0.30, 0.55)

hud.divider = hud:CreateTexture(nil, "ARTWORK")
hud.divider:SetPoint("TOPLEFT", 1, -24)
hud.divider:SetPoint("TOPRIGHT", -1, -24)
hud.divider:SetHeight(1)
hud.divider:SetColorTexture(TRACKED.r, TRACKED.g, TRACKED.b, 0.45)

local hudTitle = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hudTitle:SetPoint("TOPLEFT", 10, -6)
hudTitle:SetTextColor(TRACKED.r, TRACKED.g, TRACKED.b, 1)

local hudClearBtn = CreateFrame("Button", nil, hud, "BackdropTemplate")
hudClearBtn:SetSize(40, 16)
hudClearBtn:SetPoint("TOPRIGHT", -6, -4)
hudClearBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
hudClearBtn:SetBackdropColor(0.14, 0.08, 0.11, 0.88)
hudClearBtn:SetBackdropBorderColor(0.55, 0.36, 0.42, 0.85)
local hudClearLbl = hudClearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hudClearLbl:SetPoint("CENTER", 0, 0)
local cFn = hudClearLbl:GetFont()
if cFn then hudClearLbl:SetFont(cFn, 9) end
hudClearLbl:SetTextColor(0.92, 0.82, 0.85, 1)
hudClearLbl:SetText("Clear")
hudClearBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.24, 0.11, 0.15, 0.95)
    self:SetBackdropBorderColor(0.95, 0.45, 0.52, 1)
    hudClearLbl:SetTextColor(1, 1, 1, 1)
end)
hudClearBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.14, 0.08, 0.11, 0.88)
    self:SetBackdropBorderColor(0.55, 0.36, 0.42, 0.85)
    hudClearLbl:SetTextColor(0.92, 0.82, 0.85, 1)
end)
hudClearBtn:SetScript("OnClick", function()
    FP:SetTrackReagentFromInput("clear")
end)

local hudLockBtn = CreateFrame("Button", nil, hud)
hudLockBtn:SetSize(16, 16)
hudLockBtn:SetPoint("TOPRIGHT", hudClearBtn, "TOPLEFT", -4, 0)
hudLockBtn:SetHighlightTexture("Interface\\Buttons\\LockButton-Highlight")
if FP.CropButtonTextures then FP:CropButtonTextures(hudLockBtn, 0.15) end

local function UpdateHudLockVisual()
    local s = GetSettings()
    local locked = s.reagentHudLocked
    if locked == nil then locked = s.locked ~= false end
    if locked then
        hudLockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
    else
        hudLockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    end
end

hudLockBtn:SetScript("OnClick", function()
    local s = GetSettings()
    local cur = s.reagentHudLocked
    if cur == nil then cur = s.locked ~= false end
    s.reagentHudLocked = not cur
    UpdateHudLockVisual()
    if s.reagentHudLocked then
        FP:Print("NexusKit: Finestra Reagenti Tracciati bloccata.")
    else
        FP:Print("NexusKit: Finestra Reagenti Tracciati sbloccata (trascinala per spostarla).")
    end
end)

hudLockBtn:SetScript("OnEnter", function(self)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local s = GetSettings()
        local locked = s.reagentHudLocked
        if locked == nil then locked = s.locked ~= false end
        if locked then
            GameTooltip:SetText("Finestra Reagenti: Bloccata", 1, 0.82, 0)
            GameTooltip:AddLine("Clicca per sbloccare e trascinare la finestra.", 0.85, 0.85, 0.85, true)
        else
            GameTooltip:SetText("Finestra Reagenti: Sbloccata", 0.4, 0.9, 1)
            GameTooltip:AddLine("Trascina con il tasto sinistro per spostare.\nClicca per bloccare la posizione.", 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end
end)
hudLockBtn:SetScript("OnLeave", function()
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        GameTooltip:Hide()
    end
end)

local hudRows = {}

StaticPopupDialogs["NEXUSKIT_SET_REAGENT_TARGET"] = {
    text = "Imposta quantita desiderata per %s:\n(Inserisci 0 per disattivare l'obiettivo)",
    button1 = ACCEPT or "Accetta",
    button2 = CANCEL or "Annulla",
    hasEditBox = 1,
    maxLetters = 5,
    OnShow = function(self)
        local name = (self.GetName and self:GetName()) or ""
        local eb = self.editBox or (name ~= "" and _G[name .. "EditBox"])
        if eb then
            local data = self.data
            local cur = (data and data.target) or 0
            eb:SetText(cur > 0 and tostring(cur) or "")
            eb:SetFocus()
            eb:HighlightText()
        end
    end,
    OnAccept = function(self)
        local name = (self.GetName and self:GetName()) or ""
        local eb = self.editBox or (name ~= "" and _G[name .. "EditBox"])
        local text = (eb and eb:GetText()) or ""
        local num = tonumber(text:match("(%d+)")) or 0
        local data = self.data
        if data then
            local L = FP.L or {}
            local itemDisp = data.link or (data.name and ("[" .. data.name .. "]")) or "Reagente"
            if num > 0 then
                data.target = num
                local bags = data.itemID and GetItemCountCompat(data.itemID, false) or 0
                data.alerted = (bags >= num)
                FP:Print(string.format(L["REAGENT_TARGET_SET"] or "Obiettivo per %s impostato a %d.", itemDisp, num))
            else
                data.target = nil
                data.alerted = nil
                FP:Print(string.format(L["REAGENT_TARGET_REMOVED"] or "Obiettivo per %s rimosso.", itemDisp))
            end
            FP:RefreshTrackedReagentsHUD()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = (parent.GetName and parent:GetName()) or ""
        local btn = parent.button1 or (name ~= "" and _G[name .. "Button1"])
        if btn and btn:IsEnabled() then
            btn:Click()
        else
            parent:Hide()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

function FP:TriggerReagentTargetReachedAlert(rec, bags)
    if not rec or not rec.target then return end
    local L = self.L or {}

    -- 1. Chime / Alert Sound
    local played = false
    if SOUNDKIT and SOUNDKIT.UI_QUEST_COMPLETE then
        played = pcall(PlaySound, SOUNDKIT.UI_QUEST_COMPLETE, "Master")
    end
    if not played then
        pcall(PlaySound, 878, "Master")
    end

    -- 2. Screen warning banner
    local itemName = rec.name or "Reagente"
    local bannerHeader = L["REAGENT_TARGET_REACHED_BANNER"] or "Obiettivo Reagenti Raggiunto!"
    local bannerMsg = string.format("|cff00ff00%s|r\n%s: %d / %d", bannerHeader, itemName, bags, rec.target)
    if RaidNotice_AddMessage and RaidWarningFrame then
        pcall(RaidNotice_AddMessage, RaidWarningFrame, bannerMsg, ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] or { r = 0, g = 1, b = 0.59 })
    elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
        pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, string.format("%s %s (%d/%d)", bannerHeader, itemName, bags, rec.target), 0, 1, 0.59, 1, 4)
    end

    -- 3. Chat notification
    local itemDisp = rec.link or (rec.name and ("[" .. rec.name .. "]")) or itemName
    self:Print(string.format(L["REAGENT_TARGET_REACHED_CHAT"] or "|cff00ff00[NexKit Reagenti]|r Obiettivo completato! Hai raccolto %d/%d di %s!", bags, rec.target, itemDisp))
end

local function GetOrCreateHudRow(index)
    local row = hudRows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, hud)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", 6, -28 - ((index - 1) * 21))
    row:SetPoint("TOPRIGHT", -6, -28 - ((index - 1) * 21))
    row:EnableMouse(true)
    row:EnableMouseWheel(true)
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function()
        local s = GetSettings()
        local locked = s.reagentHudLocked
        if locked == nil then locked = s.locked ~= false end
        if not locked then
            hud.isDragging = true
            hud:StartMoving()
        end
    end)
    row:SetScript("OnDragStop", function()
        hud.isDragging = false
        hud:StopMovingOrSizing()
        if NexusKitDB and NexusKitDB.settings then
            local ux, uy = UIParent:GetCenter()
            local fx, fy = hud:GetCenter()
            if ux and uy and fx and fy then
                NexusKitDB.settings.reagentHudPos = { x = fx - ux, y = fy - uy }
            end
        end
    end)

    row:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and self.entry then
            local rec = self.entry
            if FP.L and FP.L["REAGENT_TARGET_POPUP_TEXT"] then
                StaticPopupDialogs["NEXUSKIT_SET_REAGENT_TARGET"].text = FP.L["REAGENT_TARGET_POPUP_TEXT"]
            end
            local popup = StaticPopup_Show("NEXUSKIT_SET_REAGENT_TARGET", rec.name or "Reagente", nil, rec)
            if popup then
                popup.data = rec
                local name = (popup.GetName and popup:GetName()) or ""
                local eb = popup.editBox or (name ~= "" and _G[name .. "EditBox"])
                if eb then
                    local cur = rec.target or 0
                    eb:SetText(cur > 0 and tostring(cur) or "")
                    eb:SetFocus()
                    eb:HighlightText()
                end
            end
        end
    end)

    row:SetScript("OnMouseWheel", function(self, delta)
        if not self.entry then return end
        local rec = self.entry
        local step = IsShiftKeyDown() and 5 or 1
        local cur = rec.target or 0
        local nextVal = cur + (delta > 0 and step or -step)
        if nextVal <= 0 then
            rec.target = nil
            rec.alerted = nil
        else
            rec.target = nextVal
            local bags = rec.itemID and GetItemCountCompat(rec.itemID, false) or 0
            rec.alerted = (bags >= nextVal)
        end
        FP:RefreshTrackedReagentsHUD()
        if GameTooltip and GameTooltip:IsOwned(self) then
            local onEnter = self:GetScript("OnEnter")
            if onEnter then onEnter(self) end
        end
    end)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(TRACKED.r, TRACKED.g, TRACKED.b, 0.12)
    row.bg:Hide()

    row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.iconFrame:SetSize(18, 18)
    row.iconFrame:SetPoint("LEFT", 2, 0)
    row.iconFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row.iconFrame:SetBackdropColor(0.03, 0.04, 0.06, 1)
    row.iconFrame:SetBackdropBorderColor(TRACKED.r * 0.70, TRACKED.g * 0.70, TRACKED.b * 0.70, 0.70)

    local ico = row.iconFrame:CreateTexture(nil, "ARTWORK")
    ico:SetPoint("TOPLEFT", 1, -1)
    ico:SetPoint("BOTTOMRIGHT", -1, 1)
    ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = ico

    local rem = CreateFrame("Button", nil, row)
    rem:SetSize(15, 15)
    rem:SetPoint("RIGHT", -1, 0)
    local remTxt = rem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    remTxt:SetPoint("CENTER", 0, 0)
    remTxt:SetText("x")
    remTxt:SetTextColor(0.85, 0.45, 0.45, 1)
    rem:SetScript("OnEnter", function()
        remTxt:SetTextColor(1, 0.25, 0.25, 1)
        row.bg:Show()
    end)
    rem:SetScript("OnLeave", function()
        remTxt:SetTextColor(0.85, 0.45, 0.45, 1)
        if not row.isComplete then
            row.bg:Hide()
        end
    end)
    rem:SetScript("OnClick", function()
        if row.entry then
            FP:ToggleTrackReagent(row.entry.itemID, row.entry.name, row.entry.icon, row.entry.link)
        end
    end)

    local cnt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cnt:SetPoint("RIGHT", rem, "LEFT", -5, 0)
    cnt:SetJustifyH("RIGHT")
    cnt:SetTextColor(1, 1, 1, 1)
    row.count = cnt

    local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameFs:SetPoint("LEFT", row.iconFrame, "RIGHT", 6, 0)
    nameFs:SetPoint("RIGHT", cnt, "LEFT", -6, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    nameFs:SetTextColor(0.92, 0.95, 0.99, 1)
    row.name = nameFs

    row:SetScript("OnEnter", function(self)
        if self.isComplete then
            self.bg:SetColorTexture(0, 0.9, 0.4, 0.28)
        else
            self.bg:SetColorTexture(TRACKED.r, TRACKED.g, TRACKED.b, 0.15)
        end
        self.bg:Show()

        if not self.entry then return end
        local rec = self.entry
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local okTip = false
        if rec.link and GameTooltip.SetHyperlink then
            okTip = pcall(GameTooltip.SetHyperlink, GameTooltip, rec.link)
        end
        if not okTip and rec.itemID and GameTooltip.SetItemByID then
            okTip = pcall(GameTooltip.SetItemByID, GameTooltip, rec.itemID)
        end
        if not okTip then
            GameTooltip:SetText(rec.name or "?")
        end

        local L = FP.L or {}
        GameTooltip:AddLine(" ")
        local bags = rec.itemID and GetItemCountCompat(rec.itemID, false) or 0
        if rec.target and rec.target > 0 then
            local statusStr = (bags >= rec.target) and "|cff00ff00[COMPLETO]|r" or string.format("|cff40e0ff(%d mancanti)|r", rec.target - bags)
            GameTooltip:AddDoubleLine(L["REAGENT_HUD_TIP_TARGET"] or "Obiettivo:", string.format("%d  %s", rec.target, statusStr), 0.75, 0.75, 0.75, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine(L["REAGENT_HUD_TIP_TARGET"] or "Obiettivo:", "|cff8899aa" .. (L["REAGENT_HUD_TIP_NONE"] or "Nessuno") .. "|r", 0.75, 0.75, 0.75, 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("|cff00ff96" .. (L["REAGENT_HUD_TIP_RCLICK"] or "Click destro: Imposta quantita desiderata") .. "|r", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cff40e0ff" .. (L["REAGENT_HUD_TIP_WHEEL"] or "Rotellina: Modifica obiettivo (+1 / -1, Shift: +5)") .. "|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function(self)
        if not self.isComplete then
            self.bg:Hide()
        else
            self.bg:SetColorTexture(0, 0.8, 0.35, 0.14)
            self.bg:Show()
        end
        if GameTooltip and GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)

    hudRows[index] = row
    return row
end

function FP:RefreshTrackedReagentsHUD()
    UpdateHudLockVisual()
    if not hud.isDragging then
        local pos = GetSettings().reagentHudPos
        if type(pos) == "table" and IsSafeNum(pos.x) and IsSafeNum(pos.y) then
            hud:ClearAllPoints()
            hud:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
        end
    end

    local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents
    if type(tracked) ~= "table" or not IsTrackedHudEnabled() then
        hud:Hide()
        return
    end

    local list = {}
    for _, rec in pairs(tracked) do
        if type(rec) == "table" then
            list[#list + 1] = rec
        end
    end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)

    if #list == 0 then
        hud:Hide()
        return
    end

    local L = self.L or {}
    hudTitle:SetText(L["REAGENT_HUD_TITLE"] or "Tracked Reagents")
    hudClearLbl:SetText(L["REAGENT_HUD_CLEAR"] or "Clear")
    if self.FitButtonToText then
        self:FitButtonToText(hudClearBtn, 40, 12, hudClearLbl, 76)
    end

    for i, rec in ipairs(list) do
        local row = GetOrCreateHudRow(i)
        row.entry = rec
        row.icon:SetTexture(rec.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.name:SetText(rec.name or "?")
        local bags = rec.itemID and GetItemCountCompat(rec.itemID, false) or 0
        local total = rec.itemID and GetItemCountCompat(rec.itemID, true) or bags

        local hasTarget = (rec.target and rec.target > 0)
        local isComplete = hasTarget and (bags >= rec.target)
        row.isComplete = isComplete

        if hasTarget then
            if isComplete then
                if not rec.alerted then
                    rec.alerted = true
                    FP:TriggerReagentTargetReachedAlert(rec, bags)
                end
            else
                rec.alerted = false
            end
        else
            rec.alerted = nil
        end

        if hasTarget then
            if isComplete then
                if total > bags then
                    row.count:SetText(string.format("|cff00ff00%d/%d|r |cff8899aa(+%d)|r |cff00ff00(OK)|r", bags, rec.target, total - bags))
                else
                    row.count:SetText(string.format("|cff00ff00%d/%d (OK)|r", bags, rec.target))
                end
                row.iconFrame:SetBackdropBorderColor(0, 1, 0.45, 0.95)
                row.bg:SetColorTexture(0, 0.8, 0.35, 0.14)
                row.bg:Show()
            else
                if total > bags then
                    row.count:SetText(string.format("|cff40e0ff%d|r|cff8899aa/%d (+%d)|r", bags, rec.target, total - bags))
                else
                    row.count:SetText(string.format("|cff40e0ff%d|r|cff8899aa/%d|r", bags, rec.target))
                end
                row.iconFrame:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.85)
                row.bg:Hide()
            end
        else
            if total > bags then
                row.count:SetText(string.format("|cff40e0ff%d|r |cff8899aa(+%d)|r", bags, total - bags))
            elseif bags > 0 then
                row.count:SetText("|cff40e0ff" .. bags .. "|r")
            else
                row.count:SetText("|cff8899aa0|r")
            end
            if bags > 0 then
                row.iconFrame:SetBackdropBorderColor(TRACKED.r, TRACKED.g, TRACKED.b, 0.85)
            else
                row.iconFrame:SetBackdropBorderColor(0.35, 0.40, 0.48, 0.60)
            end
            row.bg:Hide()
        end
        row:Show()
    end

    for i = #list + 1, #hudRows do
        hudRows[i].entry = nil
        hudRows[i].isComplete = false
        hudRows[i]:Hide()
    end

    hud:SetHeight(33 + (#list * 21))
    hud:Show()
end

function FP:RefreshReagentTrackerUI()
    self:RefreshTrackedReagentsHUD()
    self:RefreshLootOverlays()
    self:RefreshProfSlotOverlays()
    self:RefreshBagOverlays()
end

-------------------------------------------------------------------------------
-- Events & Blizzard Frame Hooks
-------------------------------------------------------------------------------
local function SafeAfter(delay, fn)
    if FP and FP.After then
        FP:After(delay, fn)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(delay, fn)
    else
        fn()
    end
end

local bagRefreshQueued = false
local function ScheduleBagOverlayRefresh()
    if bagRefreshQueued then return end
    bagRefreshQueued = true
    SafeAfter(0.02, function()
        bagRefreshQueued = false
        FP:RefreshBagOverlays()
    end)
end

local function ScheduleBagShowRefreshes()
    ScheduleBagOverlayRefresh()
    for _, delay in ipairs({ 0.15, 0.40 }) do
        SafeAfter(delay, function()
            if IsAnyBagFrameVisible() then
                FP:RefreshBagOverlays()
            end
        end)
    end
end

local hookFlags = { tooltip = false, loot = false, combinedBags = false, containerFn = false, bagFuncs = false, eventReg = false, profHooks = false, tradeHooks = false, craftHooks = false, containerClicks = false, containers = {} }

local function ScheduleProfOverlayRefresh()
    FP:RefreshProfSlotOverlays()
    SafeAfter(0.05, function() FP:RefreshProfSlotOverlays() end)
    SafeAfter(0.15, function() FP:RefreshProfSlotOverlays() end)
end

local function HookBlizzardRecipeButtons()
    -- Reagents are tracked cleanly via non-tainting overlay buttons and the Track All button
end

local lastAltTrackTime = 0
local function HandleAltTrackAction(itemID, name, icon, link)
    local now = (GetTime and GetTime()) or 0
    if (now - lastAltTrackTime) < 0.20 then return end
    lastAltTrackTime = now

    FP:ToggleTrackReagent(itemID, name, icon, link)
    if FP.RefreshBagOverlays then FP:RefreshBagOverlays() end
    if FP.RefreshTrackedReagentsHUD then FP:RefreshTrackedReagentsHUD() end
    if FP.RefreshProfSlotOverlays then FP:RefreshProfSlotOverlays() end
end

local function HookContainerItemClicks()
    if hookFlags.containerClicks then return end
    hookFlags.containerClicks = true

    -- Hook 1: ContainerFrameItemButton_OnModifiedClick (Standard Blizzard bag slot modified clicks)
    if type(ContainerFrameItemButton_OnModifiedClick) == "function" then
        hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
            if InCombatLockdown and InCombatLockdown() then return end
            if not self or IsForbiddenObj(self) then return end
            if button and button ~= "LeftButton" then return end
            if not (IsAltKeyDown and IsAltKeyDown()) then return end
            if (IsShiftKeyDown and IsShiftKeyDown()) or (IsControlKeyDown and IsControlKeyDown()) then return end

            local bag, slot = GetBagAndSlotFromButton(self)
            local itemID, link, name, icon
            if IsSafeNum(bag) and bag >= 0 and IsSafeNum(slot) and slot > 0 then
                itemID, link, name, icon = ReadContainerSlotItem(bag, slot)
            end
            if not itemID and self.GetItemID then
                local ok, id = pcall(self.GetItemID, self)
                if ok and IsSafeNum(id) and id > 0 then itemID = id end
            end
            if not link and self.GetItemLink then
                local ok, l = pcall(self.GetItemLink, self)
                if ok and IsSafeStr(l) then link = l end
            end
            if not itemID and IsSafeStr(link) then
                itemID = ExtractItemIDFromLink(link)
            end
            if itemID or IsSafeStr(name) then
                HandleAltTrackAction(itemID, name, icon, link)
            end
        end)
    end

    -- Hook 2: HandleModifiedItemClick (Global handler for links, merchant, profession, bank items)
    if type(HandleModifiedItemClick) == "function" then
        hooksecurefunc("HandleModifiedItemClick", function(link, itemLocation)
            if InCombatLockdown and InCombatLockdown() then return end
            if not (IsAltKeyDown and IsAltKeyDown()) then return end
            if (IsShiftKeyDown and IsShiftKeyDown()) or (IsControlKeyDown and IsControlKeyDown()) then return end

            local itemID, name, icon
            if itemLocation and type(itemLocation) == "table" and not IsForbiddenObj(itemLocation) then
                local bag, slot = ExtractBagSlotFromItemLocation(itemLocation)
                if IsSafeNum(bag) and IsSafeNum(slot) then
                    itemID, link, name, icon = ReadContainerSlotItem(bag, slot)
                end
            end
            if not itemID and IsSafeStr(link) then
                itemID = ExtractItemIDFromLink(link)
            end
            if itemID or IsSafeStr(name) then
                HandleAltTrackAction(itemID, name, icon, link)
            end
        end)
    end
end

local function EnsureProfHooks()
    -- Trade skill updates are driven by native WoW events and profWatchFrame ticker
end

EnsureHooks = function()
    if not hookFlags.tooltip then
        hookFlags.tooltip = true
        EnsureTooltipHooks()
    end
    if not hookFlags.containerClicks then
        HookContainerItemClicks()
    end
end

local function GetOpenBagsSignature()
    local sig = ""
    if ContainerFrameCombinedBags and not IsForbiddenObj(ContainerFrameCombinedBags) and ContainerFrameCombinedBags:IsShown() then
        sig = sig .. "C1:"
    end
    local numC = NUM_CONTAINER_FRAMES or 13
    for i = 1, numC do
        local cf = _G["ContainerFrame" .. i]
        if cf and not IsForbiddenObj(cf) and cf:IsShown() then
            sig = sig .. i .. ":"
        end
    end
    if ContainerFrameContainer and type(ContainerFrameContainer.ContainerFrames) == "table" then
        for idx, cf in ipairs(ContainerFrameContainer.ContainerFrames) do
            if cf and not IsForbiddenObj(cf) and cf:IsShown() then
                sig = sig .. "CC" .. idx .. ":"
            end
        end
    end
    return sig
end

-- Fallback watcher guarantees bag overlays stay current without hooking secure container frames
local bagWatchFrame = CreateFrame("Frame")
bagWatchFrame.accum = 0
bagWatchFrame.lastSig = ""
bagWatchFrame:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown and InCombatLockdown() then return end
    self.accum = self.accum + elapsed
    if self.accum < 0.05 then return end
    self.accum = 0
    local sig = GetOpenBagsSignature()
    if sig ~= self.lastSig then
        self.lastSig = sig
        if sig == "" then
            bagOverlayHost:Hide()
            for _, ov in ipairs(bagOvPool) do
                HideSlotOverlay(ov)
            end
        else
            FP:RefreshBagOverlays()
        end
    elseif sig ~= "" and (bagOverlayHost.lastUsed or 0) == 0 then
        FP:RefreshBagOverlays()
    end
end)

-- Active ONLY while ProfessionsFrame, TradeSkillFrame or CraftFrame is visible so selected-recipe switches never leave stale overlays
local profWatchFrame = CreateFrame("Frame")
profWatchFrame.accum = 0
profWatchFrame.wasOpen = false
profWatchFrame.lastSig = nil
profWatchFrame:SetScript("OnUpdate", function(self, elapsed)
    self.accum = self.accum + elapsed
    if self.accum < 0.25 then return end
    self.accum = 0
    local modernOpen = ProfessionsFrame and not IsForbiddenObj(ProfessionsFrame) and ProfessionsFrame:IsVisible()
    local classicOpen = TradeSkillFrame and not IsForbiddenObj(TradeSkillFrame) and TradeSkillFrame:IsVisible()
    local craftOpen = CraftFrame and not IsForbiddenObj(CraftFrame) and CraftFrame:IsVisible()
    if not modernOpen and not classicOpen and not craftOpen then
        if self.wasOpen then
            self.wasOpen = false
            self.lastSig = nil
            profOverlayHost:Hide()
        end
        return
    end

    local form = modernOpen and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    local formShown = (form and not IsForbiddenObj(form) and form:IsVisible()) and true or false
    local selID = 0
    local poolCount = 0
    if formShown then
        if IsSafeNum(form.recipeID) then
            selID = form.recipeID
        elseif form.GetRecipeInfo then
            local okRI, rInfo = pcall(form.GetRecipeInfo, form)
            if okRI and type(rInfo) == "table" and IsSafeNum(rInfo.recipeID) then selID = rInfo.recipeID end
        end
        if form.reagentSlotPool and form.reagentSlotPool.GetNumActive then
            local okP, n = pcall(form.reagentSlotPool.GetNumActive, form.reagentSlotPool)
            if okP and IsSafeNum(n) then poolCount = n end
        end
    elseif classicOpen and GetTradeSkillSelectionIndex then
        local okS, s = pcall(GetTradeSkillSelectionIndex)
        if okS and IsSafeNum(s) then selID = s end
    elseif craftOpen and GetCraftSelectionIndex then
        local okS, s = pcall(GetCraftSelectionIndex)
        if okS and IsSafeNum(s) then selID = s end
    end
    local sig = (formShown and "1:" or "0:") .. (craftOpen and "c:" or "t:") .. tostring(selID) .. ":" .. tostring(poolCount)
    if not self.wasOpen or not profOverlayHost:IsShown() or self.lastSig ~= sig then
        self.wasOpen = true
        self.lastSig = sig
        EnsureProfHooks()
        FP:RefreshProfSlotOverlays()
    end
end)

local lastMerchantWarn = -10
local function AnnounceMerchantQuestKeepItems()
    if not IsQuestKeepEnabled() or not FP.ScanBagsForQuestKeepItems then return end
    local now = (GetTime and GetTime()) or 0
    if (now - lastMerchantWarn) < 1.5 then return end

    local items = FP:ScanBagsForQuestKeepItems()
    if not items or #items == 0 then return end
    lastMerchantWarn = now

    local L = FP.L or {}
    local parts = {}
    local limit = math.min(#items, 5)
    for i = 1, limit do
        local rec = items[i]
        local q = rec.keepInfo and rec.keepInfo.primary
        local label = rec.itemLink or ("[" .. (rec.itemName or tostring(rec.itemID)) .. "]")
        local qty = (rec.keepInfo and rec.keepInfo.bagCount) or 1
        if q then
            table.insert(parts, string.format("%s x%d -> %s (Lvl %d)", label, qty, q.title or "Quest", q.level or 1))
        end
    end
    if #items > limit then
        table.insert(parts, string.format("+%d", #items - limit))
    end
    if #parts > 0 and FP.Print then
        FP:Print("|cffffb020" .. string.format(L["QUEST_KEEP_MERCHANT_WARN"] or "Do not sell quest items in bags: %s", table.concat(parts, ", ")) .. "|r")
    end
end

local evFrame = CreateFrame("Frame")
local function SafeRegisterReagentEvent(evt)
    pcall(evFrame.RegisterEvent, evFrame, evt)
end

SafeRegisterReagentEvent("ADDON_LOADED")
SafeRegisterReagentEvent("PLAYER_LOGIN")
SafeRegisterReagentEvent("PLAYER_ENTERING_WORLD")
SafeRegisterReagentEvent("LOOT_OPENED")
SafeRegisterReagentEvent("LOOT_READY")
SafeRegisterReagentEvent("LOOT_SLOT_CHANGED")
SafeRegisterReagentEvent("LOOT_SLOT_CLEARED")
SafeRegisterReagentEvent("LOOT_CLOSED")
SafeRegisterReagentEvent("BAG_UPDATE")
SafeRegisterReagentEvent("BAG_UPDATE_DELAYED")
SafeRegisterReagentEvent("BAG_CONTAINER_UPDATE")
SafeRegisterReagentEvent("CHAT_MSG_LOOT")
SafeRegisterReagentEvent("BAG_SLOT_FLAGS_UPDATED")
SafeRegisterReagentEvent("BAG_OPEN")
SafeRegisterReagentEvent("BAG_CLOSED")
SafeRegisterReagentEvent("UI_SCALE_CHANGED")
SafeRegisterReagentEvent("DISPLAY_SIZE_CHANGED")
SafeRegisterReagentEvent("CINEMATIC_STOP")
SafeRegisterReagentEvent("UNIT_EXITED_VEHICLE")
SafeRegisterReagentEvent("PLAYER_REGEN_ENABLED")
SafeRegisterReagentEvent("MERCHANT_SHOW")
SafeRegisterReagentEvent("QUEST_LOG_UPDATE")
SafeRegisterReagentEvent("GET_ITEM_INFO_RECEIVED")
SafeRegisterReagentEvent("TRADE_SKILL_SHOW")
SafeRegisterReagentEvent("TRADE_SKILL_LIST_UPDATE")
SafeRegisterReagentEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
SafeRegisterReagentEvent("TRADE_SKILL_CLOSE")
SafeRegisterReagentEvent("CRAFT_SHOW")
SafeRegisterReagentEvent("CRAFT_UPDATE")
SafeRegisterReagentEvent("CRAFT_CLOSE")
SafeRegisterReagentEvent("NEW_RECIPE_LEARNED")

evFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_Professions" or arg1 == "Blizzard_TradeSkillUI" or arg1 == "Blizzard_CraftUI" then
            EnsureProfHooks()
            if FP.RefreshAllLearnedRecipeReagents then FP:RefreshAllLearnedRecipeReagents() end
            ScheduleProfOverlayRefresh()
        elseif not hookFlags.combinedBags or not hookFlags.bagFuncs or arg1 == "Blizzard_ContainerUI" or arg1 == "Blizzard_LootUI" or arg1 == "Blizzard_UIPanels_Game" then
            EnsureHooks()
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        EnsureCharTables()
        EnsureHooks()
        FP:RefreshTrackedReagentsHUD()
        SafeAfter(0.25, function()
            EnsureHooks()
            if IsAnyBagFrameVisible() then FP:RefreshBagOverlays() end
        end)
    elseif event == "BAG_OPEN" or event == "BAG_CLOSED" then
        EnsureHooks()
        ScheduleBagShowRefreshes()
    elseif event == "BAG_UPDATE" or event == "BAG_CONTAINER_UPDATE" or event == "BAG_SLOT_FLAGS_UPDATED" or event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" or event == "CINEMATIC_STOP" or event == "UNIT_EXITED_VEHICLE" or event == "PLAYER_REGEN_ENABLED" then
        if FP.RefreshTrackedReagentsHUD then
            FP:RefreshTrackedReagentsHUD()
        end
        if IsAnyBagFrameVisible() then
            ScheduleBagShowRefreshes()
        end
    elseif event == "CHAT_MSG_LOOT" then
        if FP.RefreshTrackedReagentsHUD then
            FP:RefreshTrackedReagentsHUD()
        end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" or event == "NEW_RECIPE_LEARNED"
        or event == "CRAFT_SHOW" or event == "CRAFT_UPDATE" then
        EnsureProfHooks()
        if FP.RefreshAllLearnedRecipeReagents then FP:RefreshAllLearnedRecipeReagents() end
        ScheduleProfOverlayRefresh()
        if IsAnyBagFrameVisible() then
            ScheduleBagOverlayRefresh()
        end
    elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
        profOverlayHost:Hide()
    elseif event == "LOOT_OPENED" or event == "LOOT_READY" or event == "LOOT_SLOT_CHANGED" or event == "LOOT_SLOT_CLEARED" then
        EnsureHooks()
        FP:RefreshLootOverlays()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.03, function() FP:RefreshLootOverlays() end)
        end
    elseif event == "LOOT_CLOSED" then
        FP:RefreshLootOverlays()
    elseif event == "MERCHANT_SHOW" then
        EnsureHooks()
        ScheduleBagOverlayRefresh()
        AnnounceMerchantQuestKeepItems()
    elseif event == "QUEST_LOG_UPDATE" then
        if FP.InvalidateQuestKeepCache then FP:InvalidateQuestKeepCache() end
        ScheduleBagOverlayRefresh()
    elseif event == "BAG_UPDATE_DELAYED" then
        -- Resolve any name-only tracked reagents from current bags
        local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents
        if type(tracked) == "table" and C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
            local maxBag = math.max(
                IsSafeNum(NUM_TOTAL_EQUIPPED_BAG_SLOTS) and NUM_TOTAL_EQUIPPED_BAG_SLOTS or 0,
                IsSafeNum(NUM_BAG_SLOTS) and NUM_BAG_SLOTS or 4,
                (Enum and Enum.BagIndex and IsSafeNum(Enum.BagIndex.ReagentBag) and Enum.BagIndex.ReagentBag) or 0
            )
            for bag = 0, maxBag do
                local okSlots, n = pcall(C_Container.GetContainerNumSlots, bag)
                if okSlots and IsSafeNum(n) then
                    for slot = 1, n do
                        local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
                        if okI and type(info) == "table" and IsSafeNum(info.itemID) and IsSafeStr(info.itemName) then
                            FindTrackedEntry(info.itemID, info.itemName)
                        end
                    end
                end
            end
        end
        FP:RefreshTrackedReagentsHUD()
        FP:RefreshBagOverlays()
        FP:RefreshProfSlotOverlays()
    elseif event == "GET_ITEM_INFO_RECEIVED" and IsSafeNum(arg1) then
        local tracked = NexusKitCharDB and NexusKitCharDB.trackedReagents
        if type(tracked) == "table" and tracked[tostring(arg1)] then
            local rec = tracked[tostring(arg1)]
            local ok, iName, iLink, _, _, _, _, _, _, _, iTex = GetItemInfoCompat(arg1)
            if ok and IsSafeStr(iName) then
                rec.name = iName
                rec.link = IsSafeStr(iLink) and iLink or rec.link
                rec.icon = iTex or rec.icon
                FP:RefreshTrackedReagentsHUD()
            end
        end
        if IsAnyBagFrameVisible() or bagOverlayHost.hasUncachedItems then
            ScheduleBagOverlayRefresh()
        end
        if (ProfessionsFrame and not IsForbiddenObj(ProfessionsFrame) and ProfessionsFrame:IsVisible())
            or (TradeSkillFrame and not IsForbiddenObj(TradeSkillFrame) and TradeSkillFrame:IsVisible()) then
            FP:RefreshProfSlotOverlays()
        end
    end
end)

function FP:PrintReagentDiagnostics()
    local function p(msg) if FP.Print then FP:Print(msg) else print(msg) end end
    local combinedExists = ContainerFrameCombinedBags and true or false
    local combinedShown = (combinedExists and not IsForbiddenObj(ContainerFrameCombinedBags) and ContainerFrameCombinedBags:IsShown()) and true or false
    local anyBag = IsAnyBagFrameVisible()
    local bagBtnsEnabled = IsBagTrackButtonsEnabled()
    p(string.format("|cff40e0ff[NK Bag Debug]|r enabled=%s anyBag=%s combinedExists=%s combinedShown=%s",
        tostring(bagBtnsEnabled), tostring(anyBag), tostring(combinedExists), tostring(combinedShown)))

    if combinedShown then
        local hasSB = (ContainerFrameCombinedBags.ScrollBox ~= nil) and true or false
        local hasItems = (type(ContainerFrameCombinedBags.Items) == "table") and true or false
        local hasEnum = (ContainerFrameCombinedBags.EnumerateValidItems ~= nil) and true or false
        local hasPool = (ContainerFrameCombinedBags.itemButtonPool ~= nil) and true or false
        p(string.format("  ScrollBox=%s Items=%s EnumValid=%s Pool=%s", tostring(hasSB), tostring(hasItems), tostring(hasEnum), tostring(hasPool)))

        local allBtns = GetVisibleBagButtons()
        p(string.format("  CollectedVisibleBagButtons=%d", #allBtns))
        for i = 1, math.min(5, #allBtns) do
            local b = allBtns[i].btn
            local bg, sl = GetBagAndSlotFromButton(b, allBtns[i].win)
            local hasBagID = b.GetBagID and true or false
            local hasGetID = b.GetID and true or false
            local hasSBID = b.GetSlotAndBagID and true or false
            local hasED = b.GetElementData and true or false
            local hasIL = b.GetItemLocation and true or false
            local hasHI = (b.hasItem ~= nil) and true or false
            local bName = (b.GetName and b:GetName()) or "nil"
            p(string.format("    [%d] name=%s bag=%s slot=%s BagID=%s GetID=%s SBID=%s ED=%s IL=%s hasItem=%s",
                i, tostring(bName), tostring(bg), tostring(sl),
                tostring(hasBagID), tostring(hasGetID), tostring(hasSBID),
                tostring(hasED), tostring(hasIL), tostring(hasHI)))
        end
    elseif anyBag then
        local allBtns = GetVisibleBagButtons()
        p(string.format("  VisibleBagButtons=%d", #allBtns))
    end

    -- Show frame map info
    if anyBag and C_Container and C_Container.GetContainerNumSlots then
        local frameMap, mappedTotal = BuildBagSlotFrameIndex()
        local mapped = 0
        local unmapped = 0
        local totalItems = 0
        local smallEggLine = nil
        local maxBag = math.max(
            IsSafeNum(NUM_TOTAL_EQUIPPED_BAG_SLOTS) and NUM_TOTAL_EQUIPPED_BAG_SLOTS or 0,
            IsSafeNum(NUM_BAG_SLOTS) and NUM_BAG_SLOTS or 4,
            (Enum and Enum.BagIndex and IsSafeNum(Enum.BagIndex.ReagentBag) and Enum.BagIndex.ReagentBag) or 0
        )
        for bag = 0, maxBag do
            local okS, nSlots = pcall(C_Container.GetContainerNumSlots, bag)
            if okS and IsSafeNum(nSlots) then
                for slot = 1, nSlots do
                    local id, link, name, _, quality = ReadContainerSlotItem(bag, slot)
                    if id then
                        totalItems = totalItems + 1
                        local key = bag .. ":" .. slot
                        local entry = frameMap[key]
                        if entry and entry.btn then
                            mapped = mapped + 1
                        else
                            unmapped = unmapped + 1
                        end
                        if id == 6889 then
                            local tr = IsBagTrackableReagent(id, link, name, FP:IsReagentTracked(id), false, false, quality)
                            local btnName = (entry and entry.btn and entry.btn.GetName and entry.btn:GetName()) or "nil"
                            smallEggLine = string.format("  |cffffcc00SmallEgg(6889)|r @ %s: mapped=%s btn=%s trackable=%s",
                                key, tostring(entry ~= nil), tostring(btnName), tostring(tr))
                        end
                    end
                end
            end
        end
        p(string.format("  |cff00ff96API scan|r: frameIndex=%d totalItems=%d mapped=%d unmapped=%d",
            mappedTotal or 0, totalItems, mapped, unmapped))
        if smallEggLine then p(smallEggLine) end
    end

    local bagUsed = 0
    for _, ov in ipairs(bagOvPool) do
        if ov and ov:IsShown() then bagUsed = bagUsed + 1 end
    end
    p(string.format("  bagOverlays=%d hostShown=%s", bagUsed, tostring(bagOverlayHost:IsShown())))

    local profShown = ((ProfessionsFrame and not IsForbiddenObj(ProfessionsFrame) and ProfessionsFrame:IsShown())
        or (TradeSkillFrame and not IsForbiddenObj(TradeSkillFrame) and TradeSkillFrame:IsShown())) and true or false
    local form = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    local formShown = (form and not IsForbiddenObj(form) and form:IsShown()) and true or false
    local profUsed = 0
    for _, ov in ipairs(profOvPool) do
        if ov and ov:IsShown() then profUsed = profUsed + 1 end
    end
    p(string.format("|cff40e0ff[NK Prof Debug]|r profShown=%s formShown=%s profOverlays=%d hostShown=%s",
        tostring(profShown), tostring(formShown), profUsed, tostring(profOverlayHost:IsShown())))
end
