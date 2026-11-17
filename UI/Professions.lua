-- NexusKit - UI/Professions.lua
-- Profession Skill-Up Advisor: finds the best learned recipes to maximize
-- skill-ups while minimizing reagent consumption.
local addonName, FP = ...

local ACCENT = { r = 1.00, g = 0.82, b = 0.00 }
if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end

local DIFFICULTY_INFO = {
    optimal = { weight = 1.00, color = { 1.00, 0.50, 0.25 }, key = "PROF_DIFF_OPTIMAL", fallback = "Orange (High)" },
    medium  = { weight = 0.50, color = { 1.00, 0.85, 0.15 }, key = "PROF_DIFF_MEDIUM",  fallback = "Yellow (Medium)" },
    easy    = { weight = 0.20, color = { 0.30, 0.90, 0.35 }, key = "PROF_DIFF_EASY",    fallback = "Green (Low)" },
}

local QUALITY_WEIGHT = {
    [0] = 0.8,  -- Poor
    [1] = 1.0,  -- Common
    [2] = 2.6,  -- Uncommon
    [3] = 5.5,  -- Rare
    [4] = 12.0, -- Epic
}

local function GetProfSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsDifficultyAllowed(diffKey, s)
    if diffKey == "optimal" then return true end
    if diffKey == "medium" then return s.profIncludeMedium ~= false end
    if diffKey == "easy" then return s.profIncludeEasy ~= false end
    return false
end

-------------------------------------------------------------------------------
-- Compatibility wrappers (WoW Forever 16001 / Midnight / Classic)
-------------------------------------------------------------------------------
local function GetItemInfoCompat(item)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    elseif GetItemInfo then
        return GetItemInfo(item)
    end
    return nil
end

local function GetItemCountCompat(itemID, includeBank)
    if not itemID then return 0 end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, includeBank) or 0
    elseif GetItemCount then
        return GetItemCount(itemID, includeBank) or 0
    end
    return 0
end

local function GetItemIconCompat(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemID)
        if icon then return icon end
    end
    if GetItemIcon then
        local icon = GetItemIcon(itemID)
        if icon then return icon end
    end
    local _, _, _, _, _, _, _, _, _, tex = GetItemInfoCompat(itemID)
    return tex
end

local function RequestItemData(itemID)
    if not itemID then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

local function ResolveDifficultyKey(info)
    if not info then return nil end
    local rd = info.relativeDifficulty
    if rd ~= nil then
        if Enum and Enum.TradeskillRelativeDifficulty then
            if rd == Enum.TradeskillRelativeDifficulty.Optimal then return "optimal" end
            if rd == Enum.TradeskillRelativeDifficulty.Medium  then return "medium"  end
            if rd == Enum.TradeskillRelativeDifficulty.Easy    then return "easy"    end
            if rd == Enum.TradeskillRelativeDifficulty.Trivial then return "trivial" end
        end
        if rd == 0 then return "optimal" end
        if rd == 1 then return "medium"  end
        if rd == 2 then return "easy"    end
        if rd == 3 then return "trivial" end
    end
    if type(info.difficulty) == "string" then
        return string.lower(info.difficulty)
    end
    return nil
end

local function SafeGetTradeSkillAnchor()
    if ProfessionsFrame and ProfessionsFrame:IsShown() then
        return ProfessionsFrame
    end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then
        return TradeSkillFrame
    end
    if CraftFrame and CraftFrame:IsShown() then
        return CraftFrame
    end
    return nil
end

-------------------------------------------------------------------------------
-- Efficiency evaluation
-------------------------------------------------------------------------------
local pendingItemIDs = {}

local function ComputeReagentUnitWeight(itemID)
    local name, _, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfoCompat(itemID)
    if not name then
        pendingItemIDs[itemID] = true
        RequestItemData(itemID)
    end
    local q = tonumber(quality) or 1
    local weight = QUALITY_WEIGHT[q] or 1.0
    if vendorPrice and vendorPrice > 2500 then
        weight = weight + math.min(4.0, vendorPrice / 2500)
    end
    return name, q, weight
end

local function BuildItemReagentEntry(itemID, qtyReq)
    local req = math.max(1, tonumber(qtyReq) or 1)
    local haveBags = GetItemCountCompat(itemID, false)
    local haveTotal = GetItemCountCompat(itemID, true)
    local name, quality, unitWeight = ComputeReagentUnitWeight(itemID)
    return {
        itemID     = itemID,
        name       = name or ("Item #" .. tostring(itemID)),
        quality    = quality,
        required   = req,
        haveBags   = haveBags,
        haveTotal  = haveTotal,
        unitWeight = unitWeight,
    }
end

local function EvaluateModernRecipes(snapshot)
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetAllRecipeIDs()
    if type(recipeIDs) ~= "table" or #recipeIDs == 0 then
        return false
    end

    local profInfo = nil
    if C_TradeSkillUI.GetChildProfessionInfo then
        local ok, res = pcall(C_TradeSkillUI.GetChildProfessionInfo)
        if ok and type(res) == "table" and res.professionName and res.professionName ~= "" then
            profInfo = res
        end
    end
    if not profInfo and C_TradeSkillUI.GetBaseProfessionInfo then
        local ok, res = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
        if ok and type(res) == "table" and res.professionName and res.professionName ~= "" then
            profInfo = res
        end
    end

    if profInfo then
        snapshot.profName = profInfo.professionName or snapshot.profName
        snapshot.skillLevel = profInfo.skillLevel or 0
        snapshot.maxSkillLevel = profInfo.maxSkillLevel or 0
    elseif C_TradeSkillUI.GetTradeSkillLine then
        local ok, _, name, rank, maxRank = pcall(C_TradeSkillUI.GetTradeSkillLine)
        if ok and name then
            snapshot.profName = name
            snapshot.skillLevel = rank or 0
            snapshot.maxSkillLevel = maxRank or 0
        end
    end

    -- First pass: identify output items consumed as basic reagents by other recipes
    local schematicsByID = {}
    local usedAsReagent = {}
    local isBasicType = Enum and Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
    local function IsMandatoryReagentSlot(slot)
        return (slot.required == true)
            or (slot.required == nil and ((isBasicType and slot.reagentType == isBasicType) or (slot.reagentType == 1)))
    end

    for _, rid in ipairs(recipeIDs) do
        if C_TradeSkillUI.GetRecipeSchematic then
            local ok, sch = pcall(C_TradeSkillUI.GetRecipeSchematic, rid, false)
            if ok and type(sch) == "table" then
                schematicsByID[rid] = sch
                if type(sch.reagentSlotSchematics) == "table" then
                    for _, slot in ipairs(sch.reagentSlotSchematics) do
                        if IsMandatoryReagentSlot(slot) and type(slot.reagents) == "table" then
                            for _, r in ipairs(slot.reagents) do
                                if r and r.itemID then
                                    usedAsReagent[r.itemID] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Second pass: score all learned, non-trivial recipes
    local s = GetProfSettings()
    local preferInter = (s.profPreferIntermediate ~= false)
    for _, rid in ipairs(recipeIDs) do
        local info = C_TradeSkillUI.GetRecipeInfo and C_TradeSkillUI.GetRecipeInfo(rid)
        if info and info.learned and not info.isDummyRecipe and not info.disabled then
            local diffKey = ResolveDifficultyKey(info)
            local diffMeta = diffKey and IsDifficultyAllowed(diffKey, s) and DIFFICULTY_INFO[diffKey]
            if diffMeta then
                local sch = schematicsByID[rid]
                local reagents = {}
                local totalRawMats = 0
                local weightedCost = 0
                local craftableNow = math.huge

                if sch and type(sch.reagentSlotSchematics) == "table" then
                    for _, slot in ipairs(sch.reagentSlotSchematics) do
                        if IsMandatoryReagentSlot(slot) and type(slot.reagents) == "table" and #slot.reagents > 0 then
                            local chosenItemID = nil
                            local bestBags = -1
                            for _, r in ipairs(slot.reagents) do
                                if r and r.itemID then
                                    local bags = GetItemCountCompat(r.itemID, false)
                                    if bags > bestBags then
                                        bestBags = bags
                                        chosenItemID = r.itemID
                                    end
                                end
                            end
                            if chosenItemID then
                                local entry = BuildItemReagentEntry(chosenItemID, slot.quantityRequired or 1)
                                reagents[#reagents + 1] = entry
                                totalRawMats = totalRawMats + entry.required
                                weightedCost = weightedCost + (entry.required * entry.unitWeight)
                                local possible = math.floor(entry.haveBags / entry.required)
                                if possible < craftableNow then
                                    craftableNow = possible
                                end
                            end
                        end
                    end
                end

                if craftableNow == math.huge then
                    craftableNow = tonumber(info.numAvailable) or 0
                elseif type(info.numAvailable) == "number" and info.numAvailable >= 0 and info.numAvailable < craftableNow then
                    craftableNow = info.numAvailable
                end

                if weightedCost <= 0 then
                    weightedCost = 0.5
                end

                local numSkillUps = math.max(1, tonumber(info.numSkillUps) or 1)
                local expectedGain = diffMeta.weight * numSkillUps
                local rawCostPerSkill = weightedCost / expectedGain
                local matsPerSkill = totalRawMats / expectedGain
                local outItemID = sch and sch.outputItemID
                local isIntermediate = (outItemID and usedAsReagent[outItemID]) and true or false
                local effectiveScore = rawCostPerSkill * ((isIntermediate and preferInter) and 0.72 or 1.0)
                local icon = info.icon or (sch and sch.icon) or GetItemIconCompat(outItemID) or "Interface\\Icons\\INV_Misc_QuestionMark"

                snapshot.recipes[#snapshot.recipes + 1] = {
                    mode            = "modern",
                    recipeID        = rid,
                    rawInfo         = info,
                    name            = info.name or (sch and sch.name) or ("Recipe #" .. tostring(rid)),
                    icon            = icon,
                    diffKey         = diffKey,
                    diffMeta        = diffMeta,
                    numSkillUps     = numSkillUps,
                    reagents        = reagents,
                    totalRawMats    = totalRawMats,
                    weightedCost    = weightedCost,
                    rawCostPerSkill = rawCostPerSkill,
                    matsPerSkill    = matsPerSkill,
                    effectiveScore  = effectiveScore,
                    craftableNow    = craftableNow,
                    isIntermediate  = isIntermediate,
                    outputItemID    = outItemID,
                }
            end
        end
    end

    return true
end

local function EvaluateClassicRecipes(snapshot)
    if not (GetNumTradeSkills and GetTradeSkillInfo) then
        return false
    end

    local numSkills = GetNumTradeSkills() or 0
    if numSkills <= 0 then return false end

    if GetTradeSkillLine then
        local name, rank, maxRank = GetTradeSkillLine()
        if name then
            snapshot.profName = name
            snapshot.skillLevel = rank or 0
            snapshot.maxSkillLevel = maxRank or 0
        end
    end

    local usedAsReagent = {}
    for i = 1, numSkills do
        local _, skillType = GetTradeSkillInfo(i)
        if skillType ~= "header" and skillType ~= "subheader" and GetTradeSkillNumReagents then
            local numR = GetTradeSkillNumReagents(i) or 0
            for r = 1, numR do
                local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r)
                local rID = rLink and tonumber(rLink:match("item:(%d+)"))
                if rID then
                    usedAsReagent[rID] = true
                end
            end
        end
    end

    local s = GetProfSettings()
    local preferInter = (s.profPreferIntermediate ~= false)
    for i = 1, numSkills do
        local skillName, skillType, numAvailable = GetTradeSkillInfo(i)
        local diffKey = skillType and string.lower(skillType)
        local diffMeta = diffKey and IsDifficultyAllowed(diffKey, s) and DIFFICULTY_INFO[diffKey]
        if skillName and diffMeta then
            local reagents = {}
            local totalRawMats = 0
            local weightedCost = 0
            local craftableNow = math.huge
            local numR = (GetTradeSkillNumReagents and GetTradeSkillNumReagents(i)) or 0

            for r = 1, numR do
                local rName, _, rCount, pCount = GetTradeSkillReagentInfo(i, r)
                local rLink = GetTradeSkillReagentItemLink and GetTradeSkillReagentItemLink(i, r)
                local rID = rLink and tonumber(rLink:match("item:(%d+)"))
                if rID then
                    local entry = BuildItemReagentEntry(rID, rCount or 1)
                    if rName and rName ~= "" then
                        entry.name = rName
                    end
                    reagents[#reagents + 1] = entry
                    totalRawMats = totalRawMats + entry.required
                    weightedCost = weightedCost + (entry.required * entry.unitWeight)
                    local possible = math.floor(entry.haveBags / entry.required)
                    if possible < craftableNow then
                        craftableNow = possible
                    end
                else
                    local req = math.max(1, tonumber(rCount) or 1)
                    local have = tonumber(pCount) or 0
                    reagents[#reagents + 1] = {
                        itemID     = nil,
                        name       = rName or "Reagent",
                        quality    = 1,
                        required   = req,
                        haveBags   = have,
                        haveTotal  = have,
                        unitWeight = 1.0,
                    }
                    totalRawMats = totalRawMats + req
                    weightedCost = weightedCost + req
                    local possible = math.floor(have / req)
                    if possible < craftableNow then
                        craftableNow = possible
                    end
                end
            end

            if craftableNow == math.huge then
                craftableNow = tonumber(numAvailable) or 0
            end
            if weightedCost <= 0 then
                weightedCost = 0.5
            end

            local outLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i)
            local outID = outLink and tonumber(outLink:match("item:(%d+)"))
            local isIntermediate = (outID and usedAsReagent[outID]) and true or false
            local rawCostPerSkill = weightedCost / diffMeta.weight
            local matsPerSkill = totalRawMats / diffMeta.weight
            local effectiveScore = rawCostPerSkill * ((isIntermediate and preferInter) and 0.72 or 1.0)
            local icon = (GetTradeSkillIcon and GetTradeSkillIcon(i)) or GetItemIconCompat(outID) or "Interface\\Icons\\INV_Misc_QuestionMark"

            snapshot.recipes[#snapshot.recipes + 1] = {
                mode            = "classic",
                classicIndex    = i,
                name            = skillName,
                icon            = icon,
                diffKey         = diffKey,
                diffMeta        = diffMeta,
                numSkillUps     = 1,
                reagents        = reagents,
                totalRawMats    = totalRawMats,
                weightedCost    = weightedCost,
                rawCostPerSkill = rawCostPerSkill,
                matsPerSkill    = matsPerSkill,
                effectiveScore  = effectiveScore,
                craftableNow    = craftableNow,
                isIntermediate  = isIntermediate,
                outputItemID    = outID,
            }
        end
    end

    return true
end

local function CollectProfessionSnapshot()
    local snapshot = {
        profName      = nil,
        skillLevel    = 0,
        maxSkillLevel = 0,
        hasProfession = false,
        recipes       = {},
    }

    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        if EvaluateModernRecipes(snapshot) then
            snapshot.hasProfession = true
        end
    end
    if not snapshot.hasProfession then
        if EvaluateClassicRecipes(snapshot) then
            snapshot.hasProfession = true
        end
    end

    table.sort(snapshot.recipes, function(a, b)
        if math.abs(a.effectiveScore - b.effectiveScore) > 0.001 then
            return a.effectiveScore < b.effectiveScore
        end
        local aCan = a.craftableNow > 0
        local bCan = b.craftableNow > 0
        if aCan ~= bCan then
            return aCan
        end
        if math.abs(a.diffMeta.weight - b.diffMeta.weight) > 0.001 then
            return a.diffMeta.weight > b.diffMeta.weight
        end
        if a.totalRawMats ~= b.totalRawMats then
            return a.totalRawMats < b.totalRawMats
        end
        return (a.name or "") < (b.name or "")
    end)

    if snapshot.hasProfession and FP.UpdateSkillUpReagentsCache then
        FP:UpdateSkillUpReagentsCache(snapshot)
    end

    return snapshot
end

-------------------------------------------------------------------------------
-- Recipe Interaction Helpers (Select / Craft / Craft All)
-------------------------------------------------------------------------------
local function SelectRecipeInWindow(recipe)
    if not recipe or (InCombatLockdown and InCombatLockdown()) then return end
    if recipe.mode == "modern" and recipe.recipeID then
        -- Use C_TradeSkillUI.OpenRecipe C API rather than invoking Blizzard UI methods directly on ProfessionsFrame
        if C_TradeSkillUI and C_TradeSkillUI.OpenRecipe then
            pcall(C_TradeSkillUI.OpenRecipe, recipe.recipeID)
        end
    elseif recipe.mode == "classic" and recipe.classicIndex then
        if SelectTradeSkill then
            pcall(SelectTradeSkill, recipe.classicIndex)
        end
        if TradeSkillFrame_SetSelection then
            pcall(TradeSkillFrame_SetSelection, recipe.classicIndex)
        end
    end
end

local function CraftRecipeCount(recipe, count)
    if not recipe or (InCombatLockdown and InCombatLockdown()) then return end
    local qty = math.max(1, math.floor(tonumber(count) or 1))
    if recipe.mode == "modern" and recipe.recipeID and C_TradeSkillUI and C_TradeSkillUI.CraftRecipe then
        pcall(C_TradeSkillUI.CraftRecipe, recipe.recipeID, qty)
    elseif recipe.mode == "classic" and recipe.classicIndex and DoTradeSkill then
        SelectRecipeInWindow(recipe)
        pcall(DoTradeSkill, recipe.classicIndex, qty)
    end
end

-------------------------------------------------------------------------------
-- Formatting & Tooltip Helpers
-------------------------------------------------------------------------------
local function FormatDifficultyBadge(recipe)
    local L = FP.L or {}
    local meta = recipe.diffMeta
    local c = meta.color
    local hex = string.format("|cff%02x%02x%02x", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255))
    local label = L[meta.key] or meta.fallback
    local multi = (recipe.numSkillUps and recipe.numSkillUps > 1) and (" +" .. recipe.numSkillUps) or ""
    local inter = recipe.isIntermediate and (" |cff66d9ff" .. (L["PROF_INTERMEDIATE_TAG"] or "[Useful Mat]") .. "|r") or ""
    return hex .. label .. multi .. "|r" .. inter
end

local function Utf8Truncate(str, maxChars)
    if not str then return "" end
    local count = 0
    local i = 1
    local len = #str
    while i <= len do
        count = count + 1
        if count > maxChars then
            return str:sub(1, i - 1) .. ".."
        end
        local b = string.byte(str, i)
        if b < 128 then
            i = i + 1
        elseif b < 224 then
            i = i + 2
        elseif b < 240 then
            i = i + 3
        else
            i = i + 4
        end
    end
    return str
end

local function FormatReagentSummary(recipe)
    if not recipe.reagents or #recipe.reagents == 0 then
        return "-"
    end
    local parts = {}
    for idx, reg in ipairs(recipe.reagents) do
        if idx > 3 then
            parts[#parts + 1] = "..."
            break
        end
        local trackedMark = (FP.IsReagentTracked and FP:IsReagentTracked(reg.itemID, reg.name)) and "|cff40e0ff*|r" or ""
        local color = (reg.haveBags >= reg.required) and "|cff44ee66" or "|cffff6655"
        local shortName = Utf8Truncate(reg.name or "Mat", 15)
        parts[#parts + 1] = string.format("%s%s%s (%d/%d)|r", trackedMark, color, shortName, reg.haveBags, reg.required)
    end
    return table.concat(parts, ", ")
end

local function ShowRecipeTooltip(owner, recipe)
    if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) or not recipe then return end
    local L = FP.L or {}
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(recipe.name or "Recipe", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:AddLine(FormatDifficultyBadge(recipe), 1, 1, 1)
    GameTooltip:AddLine(string.format(L["PROF_TIP_SCORE"] or "Efficiency cost: %.1f units per +1 skill", recipe.rawCostPerSkill), 0.85, 0.90, 0.95)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["PROF_TIP_MATS"] or "Reagents (Bags / Need):", 1, 0.84, 0.12)
    for _, reg in ipairs(recipe.reagents or {}) do
        local ok = reg.haveBags >= reg.required
        local r, g, b = ok and 0.3 or 1.0, ok and 0.95 or 0.4, ok and 0.45 or 0.35
        local bankSuffix = ""
        if reg.haveTotal > reg.haveBags then
            bankSuffix = "  (" .. string.format(L["PROF_TIP_BANK"] or "Total incl. bank: %d", reg.haveTotal) .. ")"
        end
        local trackedTag = (FP.IsReagentTracked and FP:IsReagentTracked(reg.itemID, reg.name))
            and (" |cff40e0ff[" .. (L["REAGENT_BADGE_TRACK"] or "TRACK") .. "]|r") or ""
        GameTooltip:AddLine(string.format(" - %s: %d / %d%s%s", reg.name, reg.haveBags, reg.required, bankSuffix, trackedTag), r, g, b)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["PROF_TIP_CLICK"] or "Click row to select recipe; Craft / Craft All makes 1 or max.", 0.7, 0.85, 1.0, true)
    GameTooltip:AddLine(L["PROF_TIP_RIGHTCLICK"] or "Right-click recipe to track/untrack its reagents.", 0.25, 0.90, 1.0, true)
    GameTooltip:Show()
end

local reagentTrackMenu = CreateFrame("Frame", "NexusKitReagentPickPopup", UIParent, "BackdropTemplate")
reagentTrackMenu:SetFrameStrata("DIALOG")
reagentTrackMenu:SetSize(230, 80)
reagentTrackMenu:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
reagentTrackMenu:SetBackdropColor(0.05, 0.06, 0.09, 0.97)
reagentTrackMenu:SetBackdropBorderColor(0.25, 0.90, 1.0, 0.95)
reagentTrackMenu:SetClampedToScreen(true)
reagentTrackMenu:EnableMouse(true)
reagentTrackMenu:Hide()

local menuTitle = reagentTrackMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
menuTitle:SetPoint("TOPLEFT", 10, -8)
menuTitle:SetTextColor(0.25, 0.90, 1.0, 1)

local menuClose = CreateFrame("Button", nil, reagentTrackMenu)
menuClose:SetSize(16, 16)
menuClose:SetPoint("TOPRIGHT", -6, -6)
local menuCloseTxt = menuClose:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
menuCloseTxt:SetPoint("CENTER", 0, 0)
menuCloseTxt:SetText("x")
menuClose:SetScript("OnClick", function() reagentTrackMenu:Hide() end)

local menuBtns = {}
local function RefreshReagentTrackPopup()
    local recipe = reagentTrackMenu.recipe
    if not recipe or not recipe.reagents or #recipe.reagents == 0 then
        reagentTrackMenu:Hide()
        return
    end
    local L = FP.L or {}
    menuTitle:SetText(L["REAGENT_MENU_TITLE"] or "Track Recipe Reagents:")
    for i, reg in ipairs(recipe.reagents) do
        local btn = menuBtns[i]
        if not btn then
            btn = CreateFrame("Button", nil, reagentTrackMenu, "BackdropTemplate")
            btn:SetHeight(22)
            btn:SetPoint("TOPLEFT", 8, -26 - ((i - 1) * 24))
            btn:SetPoint("TOPRIGHT", -8, -26 - ((i - 1) * 24))
            btn:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            local ico = btn:CreateTexture(nil, "ARTWORK")
            ico:SetSize(16, 16)
            ico:SetPoint("LEFT", 5, 0)
            btn.icon = ico
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("LEFT", ico, "RIGHT", 6, 0)
            fs:SetPoint("RIGHT", -6, 0)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            btn.label = fs
            menuBtns[i] = btn
        end
        btn.reg = reg
        local tracked = FP.IsReagentTracked and FP:IsReagentTracked(reg.itemID, reg.name)
        btn.icon:SetTexture((reg.itemID and GetItemIconCompat(reg.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark")
        btn.label:SetText(string.format("%s%s (%d/%d)", tracked and "[x] " or "[+] ", reg.name or "?", reg.haveBags or 0, reg.required or 1))
        if tracked then
            btn:SetBackdropColor(0.06, 0.22, 0.28, 0.95)
            btn:SetBackdropBorderColor(0.25, 0.90, 1.0, 0.95)
            btn.label:SetTextColor(0.35, 0.95, 1.0, 1)
        else
            btn:SetBackdropColor(0.10, 0.12, 0.16, 0.90)
            btn:SetBackdropBorderColor(0.28, 0.30, 0.36, 0.85)
            btn.label:SetTextColor(0.95, 0.95, 0.95, 1)
        end
        btn:SetScript("OnClick", function(self)
            if FP.ToggleTrackReagent and self.reg then
                local rIcon = self.reg.itemID and GetItemIconCompat(self.reg.itemID) or nil
                FP:ToggleTrackReagent(self.reg.itemID, self.reg.name, rIcon, nil)
                RefreshReagentTrackPopup()
                if FP.RefreshProfessionAdvisor then FP:RefreshProfessionAdvisor() end
            end
        end)
        btn:Show()
    end
    for i = #recipe.reagents + 1, #menuBtns do
        menuBtns[i]:Hide()
    end
    reagentTrackMenu:SetHeight(34 + (#recipe.reagents * 24))
end

local function OpenReagentTrackPopup(owner, recipe)
    if not recipe or not recipe.reagents or #recipe.reagents == 0 then return end
    if reagentTrackMenu:IsShown() and reagentTrackMenu.recipe == recipe then
        reagentTrackMenu:Hide()
        return
    end
    reagentTrackMenu.recipe = recipe
    reagentTrackMenu:ClearAllPoints()
    if owner then
        reagentTrackMenu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 10, -2)
    else
        reagentTrackMenu:SetPoint("CENTER")
    end
    RefreshReagentTrackPopup()
    reagentTrackMenu:Show()
end

-------------------------------------------------------------------------------
-- Advisor Panel UI
-------------------------------------------------------------------------------
local profFrame = CreateFrame("Frame", "NexusKitProfFrame", UIParent, "BackdropTemplate")
profFrame:SetSize(372, 464)
profFrame:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
profFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
profFrame:SetBackdropColor(0.06, 0.07, 0.10, 0.96)
profFrame:SetBackdropBorderColor(0.22, 0.25, 0.30, 1)
profFrame:SetFrameStrata("HIGH")
profFrame:SetMovable(true)
profFrame:EnableMouse(true)
profFrame:SetClampedToScreen(true)
profFrame:RegisterForDrag("LeftButton")
_G["NexusKitProfFrame"] = profFrame
if type(UISpecialFrames) == "table" then
    local exists = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "NexusKitProfFrame" then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(UISpecialFrames, "NexusKitProfFrame")
    end
end

local userMovedProfFrame = false
local filterCraftableOnly = false
local autoSelectPending = false
local lastSnapshot = nil
local toggleButtons = {}
local dockBtn

profFrame:SetScript("OnDragStart", function(self)
    if GetProfSettings().locked then return end
    self.dragStartX, self.dragStartY = self:GetLeft(), self:GetTop()
    self:StartMoving()
end)
profFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local dx = math.abs((self:GetLeft() or 0) - (self.dragStartX or 0))
    local dy = math.abs((self:GetTop() or 0) - (self.dragStartY or 0))
    if dx > 4 or dy > 4 then
        userMovedProfFrame = true
    end
end)
profFrame:SetScript("OnHide", function()
    if reagentTrackMenu and reagentTrackMenu:IsShown() then
        reagentTrackMenu:Hide()
    end
    if FP.UpdateProfessionButtonVisual then
        FP:UpdateProfessionButtonVisual()
    end
end)
profFrame:SetScript("OnShow", function()
    if FP.UpdateProfessionButtonVisual then
        FP:UpdateProfessionButtonVisual()
    end
end)
profFrame:Hide()

function FP:IsProfessionAdvisorShown()
    return profFrame and profFrame:IsShown() and true or false
end

local headerTitle = profFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerTitle:SetPoint("TOPLEFT", 12, -10)
headerTitle:SetPoint("TOPRIGHT", -76, -10)
headerTitle:SetJustifyH("LEFT")
headerTitle:SetWordWrap(false)
headerTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

local closeBtn = CreateFrame("Button", nil, profFrame, "UIPanelCloseButton")
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function()
    profFrame:Hide()
end)

local profSettingsBtn = CreateFrame("Button", nil, profFrame)
profSettingsBtn:SetSize(15, 15)
profSettingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
local profSettingsTex = profSettingsBtn:CreateTexture(nil, "ARTWORK")
profSettingsTex:SetAllPoints()
profSettingsTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
profSettingsBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
profSettingsBtn:SetScript("OnClick", function()
    if FP.ToggleSettingsFrame then
        FP:ToggleSettingsFrame("prof")
    end
end)
profSettingsBtn:SetScript("OnEnter", function(self)
    if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
    local L = FP.L or {}
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(L["PROF_SETTINGS_TIP"] or "Profession Advisor Settings", ACCENT.r, ACCENT.g, ACCENT.b)
    GameTooltip:Show()
end)
profSettingsBtn:SetScript("OnLeave", function()
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
end)

dockBtn = CreateFrame("Button", nil, profFrame, "BackdropTemplate")
dockBtn:SetSize(15, 15)
dockBtn:SetPoint("RIGHT", profSettingsBtn, "LEFT", -4, 0)
dockBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
dockBtn:SetBackdropColor(0.08, 0.12, 0.14, 0.9)
dockBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.75)
local dockLbl = dockBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dockLbl:SetPoint("CENTER", 0, 0)
dockLbl:SetText("<>")
dockLbl:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
dockBtn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
        local L = FP.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L["PROF_DOCK_TIP"] or "Snap & dock cleanly next to Profession window", ACCENT.r, ACCENT.g, ACCENT.b)
        GameTooltip:Show()
    end
end)
dockBtn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.75)
    if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then GameTooltip:Hide() end
end)

-- Hero Card (#1 best skill / reagent ratio)
local heroCard = CreateFrame("Button", nil, profFrame, "BackdropTemplate")
heroCard:SetPoint("TOPLEFT", 10, -34)
heroCard:SetPoint("TOPRIGHT", -10, -34)
heroCard:SetHeight(92)
heroCard:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
heroCard:SetBackdropColor(ACCENT.r * 0.08, ACCENT.g * 0.12, ACCENT.b * 0.10, 0.95)
heroCard:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
heroCard:RegisterForClicks("LeftButtonUp", "RightButtonUp")
heroCard:SetScript("OnClick", function(self, button)
    if not self.recipe then return end
    if button == "RightButton" then
        OpenReagentTrackPopup(self, self.recipe)
    else
        SelectRecipeInWindow(self.recipe)
    end
end)
heroCard:SetScript("OnEnter", function(self)
    if self.recipe then ShowRecipeTooltip(self, self.recipe) end
end)
heroCard:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local heroBadge = heroCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
heroBadge:SetPoint("TOPLEFT", 8, -6)
heroBadge:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

local heroIcon = heroCard:CreateTexture(nil, "ARTWORK")
heroIcon:SetSize(26, 26)
heroIcon:SetPoint("TOPLEFT", 8, -24)

local heroName = heroCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
heroName:SetPoint("TOPLEFT", heroIcon, "TOPRIGHT", 8, 1)
heroName:SetJustifyH("LEFT")
heroName:SetWordWrap(false)
heroName:SetTextColor(1, 1, 1, 1)

local heroMeta = heroCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
heroMeta:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -2)
heroMeta:SetJustifyH("LEFT")
heroMeta:SetWordWrap(false)

local heroMats = heroCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
heroMats:SetPoint("TOPLEFT", heroIcon, "BOTTOMLEFT", 0, -10)
heroMats:SetPoint("RIGHT", heroCard, "RIGHT", -8, 0)
heroMats:SetJustifyH("LEFT")
heroMats:SetWordWrap(false)

local heroActionBtn = CreateFrame("Button", nil, heroCard, "UIPanelButtonTemplate")
heroActionBtn:SetSize(76, 20)
heroActionBtn:SetPoint("TOPRIGHT", heroCard, "TOPRIGHT", -8, -16)
heroName:SetPoint("RIGHT", heroActionBtn, "LEFT", -6, 0)
heroMeta:SetPoint("RIGHT", heroActionBtn, "LEFT", -6, 0)
heroActionBtn:SetScript("OnClick", function()
    local r = heroCard.recipe
    if not r then return end
    if r.craftableNow > 0 then
        CraftRecipeCount(r, 1)
    else
        SelectRecipeInWindow(r)
    end
end)

local heroCraftAllBtn = CreateFrame("Button", nil, heroCard, "UIPanelButtonTemplate")
heroCraftAllBtn:SetSize(76, 18)
heroCraftAllBtn:SetPoint("TOP", heroActionBtn, "BOTTOM", 0, -3)
heroCraftAllBtn:SetScript("OnClick", function()
    local r = heroCard.recipe
    if r and r.craftableNow > 0 then
        CraftRecipeCount(r, r.craftableNow)
    end
end)
heroCraftAllBtn:Hide()

-- Secondary callout ("Best with your current bags" when #1 isn't craftable now)
local nowBar = CreateFrame("Button", nil, profFrame, "BackdropTemplate")
nowBar:SetPoint("TOPLEFT", heroCard, "BOTTOMLEFT", 0, -6)
nowBar:SetPoint("TOPRIGHT", heroCard, "BOTTOMRIGHT", 0, -6)
nowBar:SetHeight(38)
nowBar:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
nowBar:SetBackdropColor(0.20, 0.16, 0.04, 0.90)
nowBar:SetBackdropBorderColor(1, 0.84, 0.12, 0.85)
nowBar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
nowBar:SetScript("OnClick", function(self, button)
    if not self.recipe then return end
    if button == "RightButton" then
        OpenReagentTrackPopup(self, self.recipe)
    else
        SelectRecipeInWindow(self.recipe)
    end
end)
nowBar:SetScript("OnEnter", function(self)
    if self.recipe then ShowRecipeTooltip(self, self.recipe) end
end)
nowBar:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
end)

local nowLabel = nowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nowLabel:SetPoint("TOPLEFT", 8, -4)
nowLabel:SetTextColor(1, 0.84, 0.12, 1)

local nowRecipeText = nowBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
nowRecipeText:SetPoint("TOPLEFT", nowLabel, "BOTTOMLEFT", 0, -2)
nowRecipeText:SetPoint("RIGHT", nowBar, "RIGHT", -138, 0)
nowRecipeText:SetJustifyH("LEFT")
nowRecipeText:SetWordWrap(false)
nowRecipeText:SetTextColor(1, 1, 1, 1)

local nowCraftAllBtn = CreateFrame("Button", nil, nowBar, "UIPanelButtonTemplate")
nowCraftAllBtn:SetSize(70, 20)
nowCraftAllBtn:SetPoint("RIGHT", nowBar, "RIGHT", -6, 0)
nowCraftAllBtn:SetScript("OnClick", function()
    if nowBar.recipe and nowBar.recipe.craftableNow > 0 then
        CraftRecipeCount(nowBar.recipe, nowBar.recipe.craftableNow)
    end
end)

local nowCraftBtn = CreateFrame("Button", nil, nowBar, "UIPanelButtonTemplate")
nowCraftBtn:SetSize(52, 20)
nowCraftBtn:SetPoint("RIGHT", nowCraftAllBtn, "LEFT", -4, 0)
nowCraftBtn:SetScript("OnClick", function()
    if nowBar.recipe then
        CraftRecipeCount(nowBar.recipe, 1)
    end
end)
nowBar:Hide()

-- Filter pills
local filterBar = CreateFrame("Frame", nil, profFrame)
filterBar:SetPoint("TOPLEFT", heroCard, "BOTTOMLEFT", 0, -6)
filterBar:SetPoint("TOPRIGHT", heroCard, "BOTTOMRIGHT", 0, -6)
filterBar:SetHeight(24)

local function CreateFilterPill(parent, xOffset, isCraftableMode)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(170, 22)
    btn:SetPoint("LEFT", parent, "LEFT", xOffset, 0)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER", 0, 0)
    btn.label = txt
    btn:SetScript("OnClick", function()
        filterCraftableOnly = isCraftableMode
        FP:RefreshProfessionAdvisor()
    end)
    return btn
end

local btnFilterAll = CreateFilterPill(filterBar, 0, false)
local btnFilterNow = CreateFilterPill(filterBar, 182, true)

local function UpdateFilterVisuals()
    local L = FP.L or {}
    btnFilterAll.label:SetText(L["PROF_FILTER_ALL"] or "All Recipes")
    btnFilterNow.label:SetText(L["PROF_FILTER_CRAFTABLE"] or "Craftable Now")
    if FP.FitButtonToText then
        local barW = (filterBar.GetWidth and filterBar:GetWidth()) or 352
        if not barW or barW < 200 then barW = 352 end
        local halfCap = math.floor((barW - 8) * 0.5)
        FP:FitButtonToText(btnFilterAll, 140, 18, btnFilterAll.label, halfCap)
        FP:FitButtonToText(btnFilterNow, 140, 18, btnFilterNow.label, halfCap)
        btnFilterNow:ClearAllPoints()
        btnFilterNow:SetPoint("LEFT", btnFilterAll, "RIGHT", 8, 0)
    end

    local activeBg = { ACCENT.r * 0.16, ACCENT.g * 0.16, ACCENT.b * 0.16, 0.95 }
    local idleBg = { 0.10, 0.11, 0.14, 0.9 }

    if not filterCraftableOnly then
        btnFilterAll:SetBackdropColor(unpack(activeBg))
        btnFilterAll:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
        btnFilterAll.label:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        btnFilterNow:SetBackdropColor(unpack(idleBg))
        btnFilterNow:SetBackdropBorderColor(0.30, 0.32, 0.36, 0.85)
        btnFilterNow.label:SetTextColor(0.80, 0.82, 0.86, 1)
    else
        btnFilterNow:SetBackdropColor(unpack(activeBg))
        btnFilterNow:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
        btnFilterNow.label:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        btnFilterAll:SetBackdropColor(unpack(idleBg))
        btnFilterAll:SetBackdropBorderColor(0.30, 0.32, 0.36, 0.85)
        btnFilterAll.label:SetTextColor(0.80, 0.82, 0.86, 1)
    end
end

-- Scrollable list of ranked recipes
local scrollFrame = CreateFrame("ScrollFrame", "NexusKitProfScroll", profFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", profFrame, "BOTTOMRIGHT", -28, 10)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(324, 1)
scrollFrame:SetScrollChild(scrollChild)

local emptyNotice = profFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
emptyNotice:SetPoint("TOPLEFT", 20, -140)
emptyNotice:SetPoint("TOPRIGHT", -20, -140)
emptyNotice:SetJustifyH("CENTER")
emptyNotice:SetWordWrap(true)
emptyNotice:SetTextColor(0.80, 0.82, 0.86, 1)
emptyNotice:Hide()

local ROW_HEIGHT = 64
local ROW_GAP = 4
local rowPool = {}

local function GetOrCreateRow(index)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    row:SetBackdropColor(0.10, 0.11, 0.15, 0.85)
    row:SetBackdropBorderColor(0.22, 0.24, 0.30, 0.85)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rank:SetPoint("TOPLEFT", 6, -6)
    rank:SetWidth(24)
    rank:SetJustifyH("LEFT")
    rank:SetTextColor(0.75, 0.78, 0.82, 1)
    row.rank = rank

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("TOPLEFT", 28, -6)
    row.icon = icon

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 1)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetTextColor(1, 1, 1, 1)
    row.nameText = nameText

    local subText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    subText:SetJustifyH("LEFT")
    subText:SetWordWrap(false)
    row.subText = subText

    local matText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matText:SetPoint("TOPLEFT", 6, -46)
    matText:SetPoint("RIGHT", -6, 0)
    matText:SetJustifyH("LEFT")
    matText:SetWordWrap(false)
    row.matText = matText

    local actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    actionBtn:SetSize(68, 19)
    actionBtn:SetPoint("TOPRIGHT", -6, -5)
    actionBtn:SetScript("OnClick", function()
        local r = row.recipe
        if not r then return end
        if r.craftableNow > 0 then
            CraftRecipeCount(r, 1)
        else
            SelectRecipeInWindow(r)
        end
    end)
    row.actionBtn = actionBtn
    nameText:SetPoint("RIGHT", actionBtn, "LEFT", -6, 0)
    subText:SetPoint("RIGHT", actionBtn, "LEFT", -6, 0)

    local craftAllBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    craftAllBtn:SetSize(68, 18)
    craftAllBtn:SetPoint("TOP", actionBtn, "BOTTOM", 0, -3)
    craftAllBtn:SetScript("OnClick", function()
        local r = row.recipe
        if r and r.craftableNow > 0 then
            CraftRecipeCount(r, r.craftableNow)
        end
    end)
    craftAllBtn:Hide()
    row.craftAllBtn = craftAllBtn

    row:SetScript("OnClick", function(self, button)
        if not self.recipe then return end
        if button == "RightButton" then
            OpenReagentTrackPopup(self, self.recipe)
        else
            SelectRecipeInWindow(self.recipe)
        end
    end)
    row:SetScript("OnEnter", function(self)
        if self.recipe then ShowRecipeTooltip(self, self.recipe) end
    end)
    row:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    rowPool[index] = row
    return row
end

-------------------------------------------------------------------------------
-- Docking & Toggle Buttons on Blizzard Profession Windows
-------------------------------------------------------------------------------
local function AnchorAdvisorTo(parentFrame)
    if userMovedProfFrame then return end
    local userScale = tonumber(GetProfSettings().profScale) or 1.0
    if userScale < 0.70 then userScale = 0.70 elseif userScale > 1.50 then userScale = 1.50 end

    profFrame:ClearAllPoints()
    if parentFrame and parentFrame:IsShown() then
        local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
        local pScale = (parentFrame.GetEffectiveScale and parentFrame:GetEffectiveScale()) or uiScale
        local pRightEff = (parentFrame:GetRight() or 0) * pScale
        local pLeftEff = (parentFrame:GetLeft() or 0) * pScale
        local pTopEff = (parentFrame:GetTop() or 0) * pScale
        local uiRightEff = ((UIParent and UIParent:GetRight()) or 1366) * uiScale
        local gapUI = (parentFrame == ProfessionsFrame) and 54 or 12
        local rawW = profFrame:GetWidth() or 372
        local availRight = (uiRightEff - pRightEff) / uiScale - gapUI - 6
        local availLeft = (pLeftEff / uiScale) - 12

        if pRightEff > 0 and pTopEff > 0 and availRight >= rawW * userScale then
            profFrame:SetScale(userScale)
            profFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ((pRightEff / uiScale) + gapUI) / userScale, (pTopEff / uiScale) / userScale)
        elseif pRightEff > 0 and pTopEff > 0 and availRight >= rawW * 0.56 then
            local fitScale = math.max(0.56, math.min(userScale, availRight / rawW))
            profFrame:SetScale(fitScale)
            profFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ((pRightEff / uiScale) + gapUI) / fitScale, (pTopEff / uiScale) / fitScale)
        elseif pLeftEff > 0 and pTopEff > 0 and not (FriendsFrame and FriendsFrame:IsShown()) and availLeft >= rawW * 0.65 then
            local fitScale = math.min(userScale, availLeft / rawW)
            profFrame:SetScale(fitScale)
            profFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", ((pLeftEff / uiScale) - 10) / fitScale, (pTopEff / uiScale) / fitScale)
        elseif FriendsFrame and FriendsFrame:IsShown() then
            local fScale = (FriendsFrame.GetEffectiveScale and FriendsFrame:GetEffectiveScale()) or uiScale
            local fLeftEff = (FriendsFrame:GetLeft() or 0) * fScale
            local fBottomEff = (FriendsFrame:GetBottom() or 0) * fScale
            local availBelow = (fBottomEff / uiScale) - 10
            local rawH = profFrame:GetHeight() or 464
            local fitScale = math.max(0.60, math.min(userScale, availBelow / rawH))
            profFrame:SetScale(fitScale)
            profFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (fLeftEff / uiScale) / fitScale, ((fBottomEff / uiScale) - 6) / fitScale)
        else
            local fitScale = math.min(userScale, 0.85)
            profFrame:SetScale(fitScale)
            profFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -12, -90)
        end
    else
        profFrame:SetScale(userScale)
        profFrame:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
    end
end

local toggleBtnHost
local function UpdateFloatingProfToggle(anchor)
    if not toggleBtnHost then return end
    if anchor and anchor:IsShown() then
        local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
        local aScale = (anchor.GetEffectiveScale and anchor:GetEffectiveScale()) or uiScale
        local rEff = anchor:GetRight() and (anchor:GetRight() * aScale) or 0
        local tEff = anchor:GetTop() and (anchor:GetTop() * aScale) or 0
        if rEff > 0 and tEff > 0 then
            toggleBtnHost:SetFrameStrata((anchor.GetFrameStrata and anchor:GetFrameStrata()) or "HIGH")
            toggleBtnHost:SetFrameLevel(math.max(10, (anchor:GetFrameLevel() or 5) + 12))
            toggleBtnHost:ClearAllPoints()
            toggleBtnHost:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", (rEff / uiScale) - 2, (tEff / uiScale) + 3)
            local L = FP.L or {}
            toggleBtnHost.label:SetText(L["PROF_OPEN_BTN"] or "Skill Advisor")
            if FP.FitButtonToText then
                FP:FitButtonToText(toggleBtnHost, 108, 22, toggleBtnHost.label, 165)
            end
            toggleBtnHost:Show()
            return
        end
    end
    toggleBtnHost:Hide()
end

dockBtn:SetScript("OnClick", function()
    userMovedProfFrame = false
    AnchorAdvisorTo(SafeGetTradeSkillAnchor())
end)

local dockSyncPending = false
local function ScheduleDockSync()
    if dockSyncPending then return end
    dockSyncPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.03, function()
            dockSyncPending = false
            local anchor = SafeGetTradeSkillAnchor()
            UpdateFloatingProfToggle(anchor)
            if profFrame:IsShown() and not userMovedProfFrame then
                AnchorAdvisorTo(anchor)
            end
        end)
    else
        dockSyncPending = false
    end
end

local function EnsureToggleOnBlizzardFrame(parentFrame)
    if not parentFrame then return end
    if not toggleBtnHost then
        toggleBtnHost = CreateFrame("Button", "NexusKitProfToggleBtn", UIParent, "BackdropTemplate")
        toggleBtnHost:SetSize(112, 22)
        toggleBtnHost:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        toggleBtnHost:SetBackdropColor(0.06, 0.12, 0.10, 0.94)
        toggleBtnHost:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)

        local lbl = toggleBtnHost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
        toggleBtnHost.label = lbl

        toggleBtnHost:SetScript("OnClick", function()
            local anchor = SafeGetTradeSkillAnchor()
            if profFrame:IsShown() then
                profFrame:Hide()
            else
                userMovedProfFrame = false
                AnchorAdvisorTo(anchor)
                FP:ShowProfessionAdvisor(true)
                ScheduleDockSync()
            end
        end)
        toggleBtnHost:SetScript("OnUpdate", function(self)
            local anchor = SafeGetTradeSkillAnchor()
            if not anchor or not anchor:IsShown() then
                self:Hide()
            end
        end)
        toggleBtnHost:Hide()
    end

    if not toggleButtons[parentFrame] then
        toggleButtons[parentFrame] = toggleBtnHost
    end
    UpdateFloatingProfToggle(SafeGetTradeSkillAnchor())
end

local uiPanelHooked = false
local function HookKnownProfessionFrames()
    if ProfessionsFrame then
        EnsureToggleOnBlizzardFrame(ProfessionsFrame)
    end
    if TradeSkillFrame then
        EnsureToggleOnBlizzardFrame(TradeSkillFrame)
    end
    if not uiPanelHooked then
        uiPanelHooked = true
        -- Dock position is refreshed via events and profFrame OnShow to guarantee zero taint
    end
end

-------------------------------------------------------------------------------
-- Render UI from evaluated recipes
-------------------------------------------------------------------------------
local function PopulateHeroCard(recipe)
    local L = FP.L or {}
    heroCard.recipe = recipe
    heroBadge:SetText(L["PROF_BEST_OVERALL"] or "#1 BEST SKILL / REAGENT")
    heroIcon:SetTexture(recipe.icon)
    heroName:SetText(recipe.name or "")
    local costStr = string.format(L["PROF_COST_FMT"] or "%.1f mats / skill", recipe.matsPerSkill)
    local canStr = string.format(L["PROF_CAN_CRAFT_FMT"] or "Can craft: %d", recipe.craftableNow)
    local canColor = (recipe.craftableNow > 0) and "|cff44ee66" or "|cffff7766"
    heroMeta:SetText(FormatDifficultyBadge(recipe) .. "  |cff99aabb•|r  " .. costStr .. "  |cff99aabb•|r  " .. canColor .. canStr .. "|r")
    heroMats:SetText(FormatReagentSummary(recipe))

    if recipe.craftableNow > 0 then
        heroActionBtn:SetText(L["PROF_BTN_CRAFT"] or "Craft")
        heroCraftAllBtn:SetText(L["PROF_BTN_CRAFT_ALL"] or "Craft All")
        if FP.FitButtonToText then
            local w1 = FP:FitButtonToText(heroActionBtn, 76, 16, nil, 94)
            local w2 = FP:FitButtonToText(heroCraftAllBtn, 76, 16, nil, 94)
            local synced = math.max(w1, w2)
            heroActionBtn:SetWidth(synced)
            heroCraftAllBtn:SetWidth(synced)
        end
        heroCraftAllBtn:Show()
    else
        heroActionBtn:SetText(L["PROF_BTN_SELECT"] or "Select")
        if FP.FitButtonToText then
            FP:FitButtonToText(heroActionBtn, 76, 16, nil, 94)
        end
        heroCraftAllBtn:Hide()
    end
    heroCard:Show()
end

function FP:ApplyProfessionScale()
    local scale = tonumber(GetProfSettings().profScale) or 1.0
    if scale < 0.70 then scale = 0.70 elseif scale > 1.50 then scale = 1.50 end
    if profFrame and profFrame.SetScale then
        profFrame:SetScale(scale)
    end
    local anchor = SafeGetTradeSkillAnchor()
    if anchor and not userMovedProfFrame then
        AnchorAdvisorTo(anchor)
    end
end

function FP:RefreshProfessionAdvisor()
    HookKnownProfessionFrames()
    local L = FP.L or {}
    if FP.SyncAccentTable then FP:SyncAccentTable(ACCENT) end
    headerTitle:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    heroBadge:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
    heroCard:SetBackdropColor(ACCENT.r * 0.08, ACCENT.g * 0.12, ACCENT.b * 0.10, 0.95)
    heroCard:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.85)
    dockBtn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.75)
    dockLbl:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)

    for _, btn in pairs(toggleButtons) do
        btn:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
        if btn.label then
            btn.label:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b, 1)
            btn.label:SetText(L["PROF_OPEN_BTN"] or "Skill Advisor")
            if self.FitButtonToText then
                self:FitButtonToText(btn, 108, 22, btn.label, 165)
            end
        end
    end

    if not profFrame:IsShown() then return end

    self:ApplyProfessionScale()
    UpdateFilterVisuals()

    local snap = CollectProfessionSnapshot()
    if snap.hasProfession and snap.profName then
        lastSnapshot = snap
    elseif lastSnapshot and not SafeGetTradeSkillAnchor() then
        snap = lastSnapshot
    end

    local titleBase = L["PROF_TITLE"] or "Profession Advisor"
    if snap.profName and snap.profName ~= "" then
        if snap.maxSkillLevel and snap.maxSkillLevel > 0 then
            headerTitle:SetText(string.format("%s: %s (%d/%d)", titleBase, snap.profName, snap.skillLevel or 0, snap.maxSkillLevel))
        else
            headerTitle:SetText(titleBase .. ": " .. snap.profName)
        end
    else
        headerTitle:SetText(titleBase)
    end

    local recipes = snap.recipes or {}
    if #recipes == 0 then
        heroCard:Hide()
        nowBar:Hide()
        filterBar:Hide()
        scrollFrame:Hide()
        for _, r in ipairs(rowPool) do r:Hide() end

        if not snap.hasProfession then
            local msg = L["PROF_NO_RECIPES"] or "Open a crafting profession window to see the best skill-up crafts."
            if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
                local p1, p2, _, _, p5 = GetProfessions()
                local detected = {}
                for _, idx in ipairs({ p1, p2, p5 }) do
                    if idx then
                        local ok, name, _, rank, maxRank = pcall(GetProfessionInfo, idx)
                        if ok and name and name ~= "" then
                            if rank and maxRank and maxRank > 0 then
                                detected[#detected + 1] = string.format("%s (%d/%d)", name, rank, maxRank)
                            else
                                detected[#detected + 1] = name
                            end
                        end
                    end
                end
                if #detected > 0 then
                    local _, _, _, hex = FP:GetAccentColor()
                    msg = msg .. "\n\n|cff" .. hex .. table.concat(detected, ", ") .. "|r"
                end
            end
            emptyNotice:SetText(msg)
        elseif snap.maxSkillLevel and snap.maxSkillLevel > 0 and snap.skillLevel >= snap.maxSkillLevel then
            emptyNotice:SetFormattedText(L["PROF_TRAIN_CAP"] or "Skill cap reached (%d/%d): visit a trainer.", snap.skillLevel, snap.maxSkillLevel)
        else
            emptyNotice:SetText(L["PROF_MAX_OR_EMPTY"] or "No skill-up recipes available right now.")
        end
        emptyNotice:Show()
        return
    end

    emptyNotice:Hide()
    filterBar:Show()
    scrollFrame:Show()

    local bestOverall = recipes[1]
    PopulateHeroCard(bestOverall)

    if autoSelectPending then
        autoSelectPending = false
        if GetProfSettings().profAutoSelectHero and bestOverall then
            SelectRecipeInWindow(bestOverall)
        end
    end

    local bestNow = nil
    for _, r in ipairs(recipes) do
        if r.craftableNow > 0 then
            bestNow = r
            break
        end
    end

    filterBar:ClearAllPoints()
    if bestNow and bestNow ~= bestOverall then
        nowBar.recipe = bestNow
        nowLabel:SetText(L["PROF_BEST_NOW"] or "Best with your current bags:")
        nowRecipeText:SetText(string.format("%s (%s, %s)",
            bestNow.name or "",
            string.format(L["PROF_COST_FMT"] or "%.1f mats / skill", bestNow.matsPerSkill),
            string.format(L["PROF_CAN_CRAFT_FMT"] or "Can craft: %d", bestNow.craftableNow)))
        nowCraftBtn:SetText(L["PROF_BTN_CRAFT"] or "Craft")
        nowCraftAllBtn:SetText(L["PROF_BTN_CRAFT_ALL"] or "Craft All")
        if self.FitButtonToText then
            self:FitButtonToText(nowCraftAllBtn, 70, 16, nil, 96)
            self:FitButtonToText(nowCraftBtn, 54, 16, nil, 80)
            nowRecipeText:ClearAllPoints()
            nowRecipeText:SetPoint("TOPLEFT", nowLabel, "BOTTOMLEFT", 0, -2)
            nowRecipeText:SetPoint("RIGHT", nowCraftBtn, "LEFT", -6, 0)
        end
        nowBar:Show()
        filterBar:SetPoint("TOPLEFT", nowBar, "BOTTOMLEFT", 0, -6)
        filterBar:SetPoint("TOPRIGHT", nowBar, "BOTTOMRIGHT", 0, -6)
    else
        nowBar.recipe = nil
        nowBar:Hide()
        filterBar:SetPoint("TOPLEFT", heroCard, "BOTTOMLEFT", 0, -6)
        filterBar:SetPoint("TOPRIGHT", heroCard, "BOTTOMRIGHT", 0, -6)
    end

    local maxResults = math.floor(tonumber(GetProfSettings().profMaxResults) or 30)
    if maxResults < 5 then maxResults = 5 elseif maxResults > 50 then maxResults = 50 end
    local displayed = {}
    for _, r in ipairs(recipes) do
        if not filterCraftableOnly or r.craftableNow > 0 then
            displayed[#displayed + 1] = r
            if #displayed >= maxResults then break end
        end
    end

    for idx, r in ipairs(displayed) do
        local row = GetOrCreateRow(idx)
        row.recipe = r
        row.rank:SetText("#" .. idx)
        row.icon:SetTexture(r.icon)
        row.nameText:SetText(r.name or "")
        local costStr = string.format(L["PROF_COST_FMT"] or "%.1f mats / skill", r.matsPerSkill)
        local canStr = string.format(L["PROF_CAN_CRAFT_FMT"] or "Can craft: %d", r.craftableNow)
        local canCol = (r.craftableNow > 0) and "|cff44ee66" or "|cffff7766"
        row.subText:SetText(FormatDifficultyBadge(r) .. "  |cff99aabb•|r  " .. costStr .. "  |cff99aabb•|r  " .. canCol .. canStr .. "|r")
        row.matText:SetText(FormatReagentSummary(r))
        if r.craftableNow > 0 then
            row.actionBtn:SetText(L["PROF_BTN_CRAFT"] or "Craft")
            row.craftAllBtn:SetText(L["PROF_BTN_CRAFT_ALL"] or "Craft All")
            if self.FitButtonToText then
                local w1 = self:FitButtonToText(row.actionBtn, 68, 14, nil, 86)
                local w2 = self:FitButtonToText(row.craftAllBtn, 68, 14, nil, 86)
                local synced = math.max(w1, w2)
                row.actionBtn:SetWidth(synced)
                row.craftAllBtn:SetWidth(synced)
            end
            row.craftAllBtn:Show()
        else
            row.actionBtn:SetText(L["PROF_BTN_SELECT"] or "Select")
            if self.FitButtonToText then
                self:FitButtonToText(row.actionBtn, 68, 14, nil, 86)
            end
            row.craftAllBtn:Hide()
        end
        if idx == 1 then
            row:SetBackdropBorderColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.75)
        else
            row:SetBackdropBorderColor(0.22, 0.24, 0.30, 0.85)
        end
        row:Show()
    end

    for i = #displayed + 1, #rowPool do
        rowPool[i].recipe = nil
        rowPool[i]:Hide()
    end

    scrollChild:SetHeight(math.max(1, #displayed * (ROW_HEIGHT + ROW_GAP)))
end

function FP:ShowProfessionAdvisor(forceManual)
    HookKnownProfessionFrames()
    local s = GetProfSettings()
    filterCraftableOnly = (s.profDefaultCraftableOnly == true)
    autoSelectPending = true
    self:ApplyProfessionScale()
    local anchor = SafeGetTradeSkillAnchor()
    if anchor then
        AnchorAdvisorTo(anchor)
    elseif forceManual then
        userMovedProfFrame = false
        AnchorAdvisorTo(nil)
    end
    profFrame:Show()
    self:RefreshProfessionAdvisor()
end

function FP:ToggleProfessionAdvisor()
    if profFrame:IsShown() then
        profFrame:Hide()
    else
        self:ShowProfessionAdvisor(true)
    end
end

-------------------------------------------------------------------------------
-- Events & Live Refresh Wiring
-------------------------------------------------------------------------------
local refreshPending = false
local function ScheduleAdvisorRefresh(delay)
    if refreshPending then return end
    refreshPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0.15, function()
            refreshPending = false
            if profFrame:IsShown() then
                FP:RefreshProfessionAdvisor()
            elseif SafeGetTradeSkillAnchor() then
                CollectProfessionSnapshot()
            end
            if FP.RefreshProfSlotOverlays then
                FP:RefreshProfSlotOverlays()
            end
        end)
    else
        refreshPending = false
        if profFrame:IsShown() then
            FP:RefreshProfessionAdvisor()
        elseif SafeGetTradeSkillAnchor() then
            CollectProfessionSnapshot()
        end
        if FP.RefreshProfSlotOverlays then
            FP:RefreshProfSlotOverlays()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
eventFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")
eventFrame:RegisterEvent("NEW_RECIPE_LEARNED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_Professions" or arg1 == "Blizzard_TradeSkillUI" then
            HookKnownProfessionFrames()
        end
    elseif event == "PLAYER_LOGIN" then
        HookKnownProfessionFrames()
        FP:ApplyProfessionScale()
    elseif event == "TRADE_SKILL_SHOW" then
        HookKnownProfessionFrames()
        local s = GetProfSettings()
        if s.enableProfessionAdvisor ~= false then
            filterCraftableOnly = (s.profDefaultCraftableOnly == true)
            autoSelectPending = true
            FP:ApplyProfessionScale()
            AnchorAdvisorTo(SafeGetTradeSkillAnchor())
            profFrame:Show()
            FP:RefreshProfessionAdvisor()
            ScheduleAdvisorRefresh(0.25)
            ScheduleDockSync()
        else
            ScheduleAdvisorRefresh(0.15)
        end
    elseif event == "TRADE_SKILL_CLOSE" then
        autoSelectPending = false
        local anchor = SafeGetTradeSkillAnchor()
        UpdateFloatingProfToggle(anchor)
        if not anchor then
            profFrame:Hide()
            if FP.RefreshProfSlotOverlays then FP:RefreshProfSlotOverlays() end
        end
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED"
        or event == "NEW_RECIPE_LEARNED" or event == "BAG_UPDATE_DELAYED" or event == "SKILL_LINES_CHANGED" then
        if profFrame:IsShown() or (event ~= "BAG_UPDATE_DELAYED" and SafeGetTradeSkillAnchor()) then
            ScheduleAdvisorRefresh(0.15)
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if arg1 and pendingItemIDs[arg1] then
            pendingItemIDs[arg1] = nil
            if profFrame:IsShown() then
                ScheduleAdvisorRefresh(0.15)
            end
        end
    end
end)
