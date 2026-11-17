-------------------------------------------------------------------------------
-- NexusKit - UI/ZonePOIs.lua
-- World Map Toggle Bar, Filter Popover & Interactive Discovery Pins
-- (Flight Masters, Innkeepers, Transports, Hub Services, Dungeon Entrances).
-------------------------------------------------------------------------------
local addonName, FP = ...

local function IsSafeStr(v)
    return type(v) == "string" and (not issecretvalue or not issecretvalue(v)) and v ~= ""
end

local function IsSafeNum(v)
    return type(v) == "number" and (not issecretvalue or not issecretvalue(v))
end

local function GetSettings()
    return (NexusKitDB and NexusKitDB.settings) or {}
end

local function IsZonePOIsEnabled()
    return GetSettings().showZonePOIs == true
end

local CAT_STYLES = {
    flight = {
        icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
        hordeIcon = "Interface\\Icons\\Ability_Mount_Wyvern_01",
        col = { 1.00, 0.72, 0.16 },
        labelKey = "ZONE_POI_CAT_FLIGHT",
        fallback = "Flight Master",
        size = 23,
    },
    inn = {
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        col = { 0.25, 0.90, 1.00 },
        labelKey = "ZONE_POI_CAT_INN",
        fallback = "Innkeeper",
        size = 21,
    },
    transport = {
        icon = "Interface\\Icons\\INV_Misc_Spyglass_03",
        col = { 0.28, 0.96, 0.56 },
        labelKey = "ZONE_POI_CAT_TRANSPORT",
        fallback = "Boat / Zeppelin / Tram",
        size = 21,
    },
    dungeon = {
        icon = "Interface\\Icons\\Spell_Arcane_PortalIronForge",
        col = { 0.82, 0.52, 1.00 },
        labelKey = "ZONE_POI_CAT_DUNGEON",
        fallback = "Dungeon / Raid",
        size = 24,
    },
    repair = {
        icon = "Interface\\Icons\\Trade_BlackSmithing",
        col = { 0.96, 0.80, 0.35 },
        labelKey = "ZONE_POI_CAT_REPAIR",
        fallback = "Repair / Vendor",
        size = 19,
    },
    mailbox = {
        icon = "Interface\\Icons\\INV_Letter_15",
        col = { 0.98, 0.88, 0.45 },
        labelKey = "ZONE_POI_CAT_MAILBOX",
        fallback = "Mailbox",
        size = 19,
    },
    bank = {
        icon = "Interface\\Icons\\INV_Box_01",
        col = { 1.00, 0.84, 0.22 },
        labelKey = "ZONE_POI_CAT_BANK",
        fallback = "Bank",
        size = 20,
    },
    auction = {
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        col = { 1.00, 0.76, 0.24 },
        labelKey = "ZONE_POI_CAT_AUCTION",
        fallback = "Auction House",
        size = 20,
    },
}

local FILTER_ROWS = {
    { key = "zonePOIsOnlyUndiscovered", default = false, labelKey = "ZONE_POI_UNDISC_ONLY", fallback = "Only undiscovered", accent = true, undiscBadge = true },
    { divider = true },
    { key = "zonePOIFlight",            default = true,  labelKey = "SETTING_ZONE_POI_FLIGHT",    fallback = "Flight Masters (Gryphons)",    col = { 1.00, 0.72, 0.16 }, cat = "flight" },
    { key = "zonePOIInn",               default = true,  labelKey = "SETTING_ZONE_POI_INN",       fallback = "Innkeepers",                   col = { 0.25, 0.90, 1.00 }, cat = "inn" },
    { key = "zonePOITransport",         default = true,  labelKey = "SETTING_ZONE_POI_TRANSPORT", fallback = "Boats / Zeppelins / Tram",     col = { 0.28, 0.96, 0.56 }, cat = "transport" },
    { key = "zonePOIServices",          default = true,  labelKey = "SETTING_ZONE_POI_SERVICES",  fallback = "Mailboxes, Bank, Repair, AH",  col = { 0.98, 0.84, 0.38 }, cat = "bank", subCats = { "repair", "mailbox", "auction" } },
    { key = "zonePOIDungeons",          default = true,  labelKey = "SETTING_ZONE_POI_DUNGEONS",  fallback = "Dungeon & Raid Entrances",     col = { 0.76, 0.45, 1.00 }, cat = "dungeon" },
    { divider = true },
    { key = "zonePOIOppositeFaction",   default = false, labelKey = "ZONE_POI_OPP_FACTION",       fallback = "Show opposite faction hubs",   col = { 0.74, 0.66, 0.52 }, oppFaction = true },
}

-- Warm parchment-bronze & antique-gold palette harmonized with Blizzard's World Map frame
local MAP_THEME = {
    panelBg      = { 0.09, 0.07, 0.05, 0.96 },
    headerBg     = { 0.17, 0.13, 0.08, 0.98 },
    footerBg     = { 0.13, 0.10, 0.06, 0.96 },
    goldBorder   = { 0.80, 0.65, 0.32, 0.98 },
    mutedBorder  = { 0.45, 0.37, 0.24, 0.88 },
    dividerGold  = { 0.78, 0.62, 0.28, 0.45 },
    rowHover     = { 0.26, 0.20, 0.11, 0.62 },
    barActiveBg  = { 0.13, 0.10, 0.06, 0.96 },
    barIdleBg    = { 0.07, 0.06, 0.05, 0.92 },
    slotBg       = { 0.05, 0.04, 0.03, 0.98 },
    slotIdleRim  = { 0.42, 0.35, 0.25, 0.90 },
    textBright   = { 0.98, 0.94, 0.84, 1.00 },
    textMuted    = { 0.68, 0.62, 0.52, 1.00 },
    textGold     = { 1.00, 0.84, 0.40, 1.00 },
}

local poiPins = {}
local zoneBar = nil
local filterPanel = nil
local lastMapID = nil
local lastOverlayRoot = nil

local function HideZonePOIPins()
    for _, pin in ipairs(poiPins) do
        pin:Hide()
    end
end

local function SyncOverlayLevel(f, overlayRoot, offset)
    if not f or not overlayRoot then return end
    local strata = overlayRoot.GetFrameStrata and overlayRoot:GetFrameStrata()
    local lvl = ((overlayRoot.GetFrameLevel and overlayRoot:GetFrameLevel()) or 3500) + (offset or 110)
    if strata then f:SetFrameStrata(strata) end
    f:SetFrameLevel(lvl)
end

local function GetPlayerFactionSafe()
    if UnitFactionGroup then
        local ok, fac = pcall(UnitFactionGroup, "player")
        if ok and IsSafeStr(fac) then
            return fac
        end
    end
    return "Alliance"
end

local function ResolveSwatchAppearance(def)
    local fac = GetPlayerFactionSafe()
    if def.undiscBadge then
        return "Interface\\Icons\\INV_Misc_Map_01", { 1.00, 0.78, 0.15 }, true
    elseif def.oppFaction then
        local icon = (fac == "Horde") and CAT_STYLES.flight.icon or CAT_STYLES.flight.hordeIcon
        return icon, def.col or MAP_THEME.mutedBorder, false
    elseif def.cat then
        local st = CAT_STYLES[def.cat] or CAT_STYLES.repair
        local icon = st.icon
        if def.cat == "flight" and fac == "Horde" and st.hordeIcon then
            icon = st.hordeIcon
        end
        return icon, def.col or st.col, false
    end
    return nil, def.col or MAP_THEME.mutedBorder, false
end

-- Layered 1px color frame avoids BackdropTemplate edge clipping under fractional UI scales
local function CreateLayeredBox(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)

    local rim = f:CreateTexture(nil, "BACKGROUND")
    rim:SetAllPoints()
    rim:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.rim = rim

    local bg = f:CreateTexture(nil, "BORDER")
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(unpack(MAP_THEME.slotBg))
    return f
end

local function CreateLayeredCheckbox(parent, size)
    local box = CreateLayeredBox(parent, size)

    local chk = box:CreateTexture(nil, "OVERLAY")
    chk:SetSize(size - 2, size - 2)
    chk:SetPoint("CENTER")
    chk:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check = chk

    return box
end

local function CreateLayeredSwatch(parent, size)
    local sw = CreateLayeredBox(parent, size)

    local tex = sw:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 2, -2)
    tex:SetPoint("BOTTOMRIGHT", -2, 2)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    sw.tex = tex

    local dot = sw:CreateTexture(nil, "OVERLAY")
    dot:SetSize(math.max(5, math.floor(size * 0.34)), math.max(5, math.floor(size * 0.34)))
    dot:SetPoint("TOPRIGHT", 1, 1)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")
    dot:SetVertexColor(1.0, 0.78, 0.15, 1.0)
    dot:Hide()
    sw.dot = dot

    return sw
end

local function RefreshFilterPanelCheckboxes()
    if not filterPanel or not filterPanel.rows then return end
    local L = FP.L or {}
    local s = GetSettings()
    if filterPanel.title then
        filterPanel.title:SetText(L["ZONE_POI_ALL"] or "Important Zone POIs")
    end
    if filterPanel.undiscText then
        filterPanel.undiscText:SetText(L["ZONE_POI_STATUS_UNDISC"] or "Yet to discover")
    end
    if filterPanel.discText then
        filterPanel.discText:SetText(L["ZONE_POI_STATUS_DISC"] or "Discovered")
    end

    local maxRowW = 240
    for _, row in ipairs(filterPanel.rows) do
        local def = row.def
        local checked = def.default and (s[def.key] ~= false) or (s[def.key] == true)

        row.label:SetText(L[def.labelKey] or def.fallback)
        row.box.check:SetShown(checked)

        local iconPath, swatchCol, showDot = ResolveSwatchAppearance(def)
        if row.swatch and iconPath then
            row.swatch.tex:SetTexture(iconPath)
            row.swatch.tex:SetDesaturated(not checked)
            row.swatch.tex:SetAlpha(checked and 1.0 or 0.45)
            row.swatch.dot:SetShown(showDot)
        end

        if row.subSwatches then
            for _, sub in ipairs(row.subSwatches) do
                sub.tex:SetDesaturated(not checked)
                sub.tex:SetAlpha(checked and 1.0 or 0.45)
                if checked then
                    sub.rim:SetVertexColor(swatchCol[1], swatchCol[2], swatchCol[3], 0.90)
                else
                    sub.rim:SetVertexColor(unpack(MAP_THEME.slotIdleRim))
                end
            end
        end

        if checked then
            local c = swatchCol or (def.accent and { 1.00, 0.78, 0.15 }) or MAP_THEME.goldBorder
            row.box.rim:SetVertexColor(c[1], c[2], c[3], 0.98)
            if row.swatch then
                row.swatch.rim:SetVertexColor(c[1], c[2], c[3], 0.98)
            end
            row.label:SetTextColor(unpack(MAP_THEME.textBright))
        else
            row.box.rim:SetVertexColor(unpack(MAP_THEME.slotIdleRim))
            if row.swatch then
                row.swatch.rim:SetVertexColor(unpack(MAP_THEME.slotIdleRim))
            end
            row.label:SetTextColor(unpack(MAP_THEME.textMuted))
        end

        local lblW = math.ceil(row.label:GetStringWidth() or 160)
        local extraW = row.subSwatches and (#row.subSwatches * 17 + 10) or 0
        -- 14px left pad + 15px box + 7px + 19px swatch + 8px + text + extras + 14px right pad
        local needed = 14 + 15 + 7 + 19 + 8 + lblW + extraW + 16
        if needed > maxRowW then
            maxRowW = needed
        end
    end

    if filterPanel.title then
        local titleW = math.ceil(filterPanel.title:GetStringWidth() or 160) + 72
        if titleW > maxRowW then
            maxRowW = titleW
        end
    end
    if filterPanel.undiscText and filterPanel.discText then
        local keyW = math.ceil((filterPanel.undiscText:GetStringWidth() or 90) + (filterPanel.discText:GetStringWidth() or 70)) + 72
        if keyW > maxRowW then
            maxRowW = keyW
        end
    end

    filterPanel:SetWidth(math.max(296, maxRowW))
end

local function RefreshZoneBarVisual()
    if not zoneBar then return end
    local L = FP.L or {}
    local on = IsZonePOIsEnabled()

    local stats = (lastMapID and FP.GetZonePOIStats) and FP:GetZonePOIStats(lastMapID) or nil
    local baseLabel = L["ZONE_POI_BTN"] or "Zone POIs"
    local txt = baseLabel
    if on and stats and stats.total > 0 then
        if stats.undiscovered > 0 then
            txt = string.format("%s (%d)", baseLabel, stats.undiscovered)
        else
            txt = string.format("%s (%d)", baseLabel, stats.total)
        end
    elseif on then
        txt = baseLabel .. ": ON"
    end

    zoneBar.text:SetText(txt)
    local textW = math.ceil(zoneBar.text:GetStringWidth() or 68)
    local mainW = math.max(106, textW + 38)
    zoneBar.mainBtn:SetWidth(mainW)
    zoneBar:SetWidth(mainW + 27)

    if zoneBar.arrow then
        local isOpen = filterPanel and filterPanel:IsShown()
        zoneBar.arrow:SetText(isOpen and "v" or "^")
        if isOpen or on then
            zoneBar.arrow:SetTextColor(unpack(MAP_THEME.textGold))
        else
            zoneBar.arrow:SetTextColor(unpack(MAP_THEME.textMuted))
        end
    end

    if on then
        zoneBar.mainBtn:SetBackdropColor(unpack(MAP_THEME.barActiveBg))
        zoneBar.mainBtn:SetBackdropBorderColor(unpack(MAP_THEME.goldBorder))
        zoneBar.filterBtn:SetBackdropColor(unpack(MAP_THEME.barActiveBg))
        zoneBar.filterBtn:SetBackdropBorderColor(unpack(MAP_THEME.goldBorder))
        zoneBar.text:SetTextColor(unpack(MAP_THEME.textGold))
        zoneBar.logo:SetDesaturated(false)
        zoneBar.logo:SetAlpha(1.0)
    else
        zoneBar.mainBtn:SetBackdropColor(unpack(MAP_THEME.barIdleBg))
        zoneBar.mainBtn:SetBackdropBorderColor(unpack(MAP_THEME.mutedBorder))
        zoneBar.filterBtn:SetBackdropColor(unpack(MAP_THEME.barIdleBg))
        zoneBar.filterBtn:SetBackdropBorderColor(unpack(MAP_THEME.mutedBorder))
        zoneBar.text:SetTextColor(unpack(MAP_THEME.textMuted))
        zoneBar.logo:SetDesaturated(true)
        zoneBar.logo:SetAlpha(0.72)
    end
end

local function EnsureFilterPanel(parentBar)
    if filterPanel then return filterPanel end

    local f = CreateFrame("Frame", "NexusKitZonePOIFilterPanel", parentBar, "BackdropTemplate")
    f:SetWidth(312)
    f:SetPoint("BOTTOMLEFT", parentBar, "TOPLEFT", 0, 6)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(unpack(MAP_THEME.panelBg))
    f:SetBackdropBorderColor(unpack(MAP_THEME.goldBorder))

    local hdr = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    hdr:SetPoint("TOPLEFT", 3, -3)
    hdr:SetPoint("TOPRIGHT", -3, -3)
    hdr:SetHeight(27)
    hdr:SetColorTexture(unpack(MAP_THEME.headerBg))

    local hdrLine = f:CreateTexture(nil, "BORDER")
    hdrLine:SetHeight(1)
    hdrLine:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, 0)
    hdrLine:SetPoint("TOPRIGHT", hdr, "BOTTOMRIGHT", 0, 0)
    hdrLine:SetColorTexture(unpack(MAP_THEME.dividerGold))

    local crest = f:CreateTexture(nil, "ARTWORK")
    crest:SetSize(17, 17)
    crest:SetPoint("LEFT", hdr, "LEFT", 7, 0)
    crest:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", crest, "RIGHT", 7, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetTextColor(unpack(MAP_THEME.textGold))
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", -4, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    f:SetScript("OnHide", function()
        RefreshZoneBarVisual()
    end)

    f.rows = {}
    local y = -35
    for _, def in ipairs(FILTER_ROWS) do
        if def.divider then
            local sep = f:CreateTexture(nil, "OVERLAY")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT", 11, y - 3)
            sep:SetPoint("TOPRIGHT", -11, y - 3)
            sep:SetColorTexture(unpack(MAP_THEME.dividerGold))
            y = y - 8
        else
            local row = CreateFrame("Button", nil, f)
            row:SetHeight(23)
            row:SetPoint("TOPLEFT", 6, y)
            row:SetPoint("TOPRIGHT", -6, y)
            row.def = def

            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            hl:SetColorTexture(unpack(MAP_THEME.rowHover))
            hl:Hide()
            row.hl = hl

            local box = CreateLayeredCheckbox(row, 15)
            box:SetPoint("LEFT", 7, 0)
            row.box = box

            local swatch = CreateLayeredSwatch(row, 19)
            swatch:SetPoint("LEFT", box, "RIGHT", 7, 0)
            row.swatch = swatch

            if def.subCats then
                row.subSwatches = {}
                local prev = nil
                for i = #def.subCats, 1, -1 do
                    local catId = def.subCats[i]
                    local st = CAT_STYLES[catId]
                    local sub = CreateLayeredSwatch(row, 15)
                    if not prev then
                        sub:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                    else
                        sub:SetPoint("RIGHT", prev, "LEFT", -2, 0)
                    end
                    if st then
                        sub.tex:SetTexture(st.icon)
                    end
                    row.subSwatches[#row.subSwatches + 1] = sub
                    prev = sub
                end
            end

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            row.label = lbl

            row:SetScript("OnClick", function(self)
                if not NexusKitDB then return end
                NexusKitDB.settings = NexusKitDB.settings or {}
                local cur = def.default and (NexusKitDB.settings[def.key] ~= false) or (NexusKitDB.settings[def.key] == true)
                NexusKitDB.settings[def.key] = not cur
                if NexusKitDB.settings.showZonePOIs ~= true and def.key ~= "zonePOIOppositeFaction" then
                    NexusKitDB.settings.showZonePOIs = true
                end
                if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
                if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
            end)

            row:SetScript("OnEnter", function(self)
                self.hl:Show()
                self.label:SetTextColor(1, 0.98, 0.88, 1)
            end)
            row:SetScript("OnLeave", function(self)
                self.hl:Hide()
                RefreshFilterPanelCheckboxes()
            end)

            f.rows[#f.rows + 1] = row
            y = y - 24
        end
    end

    -- Compact bottom status legend key (undiscovered amber dot vs discovered green dot)
    local footBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    footBg:SetPoint("BOTTOMLEFT", 3, 3)
    footBg:SetPoint("BOTTOMRIGHT", -3, 3)
    footBg:SetHeight(23)
    footBg:SetColorTexture(unpack(MAP_THEME.footerBg))

    local footLine = f:CreateTexture(nil, "BORDER")
    footLine:SetHeight(1)
    footLine:SetPoint("BOTTOMLEFT", footBg, "TOPLEFT", 0, 0)
    footLine:SetPoint("BOTTOMRIGHT", footBg, "TOPRIGHT", 0, 0)
    footLine:SetColorTexture(unpack(MAP_THEME.dividerGold))

    local undiscDot = f:CreateTexture(nil, "OVERLAY")
    undiscDot:SetSize(7, 7)
    undiscDot:SetPoint("LEFT", footBg, "LEFT", 12, 0)
    undiscDot:SetTexture("Interface\\Buttons\\WHITE8x8")
    undiscDot:SetVertexColor(1.0, 0.78, 0.15, 1.0)

    local undiscText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    undiscText:SetPoint("LEFT", undiscDot, "RIGHT", 6, 0)
    undiscText:SetWordWrap(false)
    undiscText:SetTextColor(1.0, 0.84, 0.38, 1)
    f.undiscText = undiscText

    local discDot = f:CreateTexture(nil, "OVERLAY")
    discDot:SetSize(7, 7)
    discDot:SetPoint("LEFT", undiscText, "RIGHT", 16, 0)
    discDot:SetTexture("Interface\\Buttons\\WHITE8x8")
    discDot:SetVertexColor(0.28, 0.95, 0.50, 0.95)

    local discText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discText:SetPoint("LEFT", discDot, "RIGHT", 6, 0)
    discText:SetWordWrap(false)
    discText:SetTextColor(0.45, 0.92, 0.60, 1)
    f.discText = discText

    f:SetHeight(math.abs(y) + 31)
    f:Hide()
    filterPanel = f
    RefreshFilterPanelCheckboxes()
    return f
end

local function ToggleFilterPanel(bar, overlayRoot)
    local fp = EnsureFilterPanel(bar)
    SyncOverlayLevel(fp, bar:GetParent() or overlayRoot, 125)
    fp:SetShown(not fp:IsShown())
    if fp:IsShown() then
        RefreshFilterPanelCheckboxes()
    end
    RefreshZoneBarVisual()
end

local function EnsureZoneBar(overlayRoot)
    if zoneBar then
        if zoneBar:GetParent() ~= overlayRoot then
            zoneBar:SetParent(overlayRoot)
        end
        zoneBar:ClearAllPoints()
        zoneBar:SetPoint("BOTTOMLEFT", overlayRoot, "BOTTOMLEFT", 12, 34)
        SyncOverlayLevel(zoneBar, overlayRoot, 115)
        if filterPanel then
            SyncOverlayLevel(filterPanel, overlayRoot, 125)
        end
        return zoneBar
    end

    local bar = CreateFrame("Frame", "NexusKitZonePOIMapBar", overlayRoot)
    bar:SetSize(148, 26)
    bar:SetPoint("BOTTOMLEFT", overlayRoot, "BOTTOMLEFT", 12, 34)
    bar:EnableMouse(true)

    local mainBtn = CreateFrame("Button", nil, bar, "BackdropTemplate")
    mainBtn:SetHeight(26)
    mainBtn:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    mainBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mainBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 11,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local logo = mainBtn:CreateTexture(nil, "OVERLAY")
    logo:SetSize(17, 17)
    logo:SetPoint("LEFT", 7, 0)
    logo:SetTexture(FP.LOGO_TEXTURE or "Interface\\AddOns\\NexusKit\\Media\\Logo.tga")
    bar.logo = logo

    local txt = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", logo, "RIGHT", 6, 0)
    txt:SetJustifyH("LEFT")
    txt:SetWordWrap(false)
    bar.text = txt
    bar.mainBtn = mainBtn

    local filterBtn = CreateFrame("Button", nil, bar, "BackdropTemplate")
    filterBtn:SetSize(25, 26)
    filterBtn:SetPoint("LEFT", mainBtn, "RIGHT", 2, 0)
    filterBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 11,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    local arrowTxt = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrowTxt:SetPoint("CENTER", 0, 1)
    arrowTxt:SetText("^")
    bar.arrow = arrowTxt
    bar.filterBtn = filterBtn

    mainBtn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ToggleFilterPanel(bar, overlayRoot)
            return
        end
        if not NexusKitDB then return end
        NexusKitDB.settings = NexusKitDB.settings or {}
        local nextVal = not (NexusKitDB.settings.showZonePOIs == true)
        NexusKitDB.settings.showZonePOIs = nextVal
        if not nextVal and filterPanel then
            filterPanel:Hide()
        end
        if FP.RefreshSettingsUI then FP:RefreshSettingsUI() end
        if FP.RefreshZonePOIs then FP:RefreshZonePOIs() end
    end)

    filterBtn:SetScript("OnClick", function()
        ToggleFilterPanel(bar, overlayRoot)
    end)
    filterBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1.0, 0.88, 0.45, 1.0)
        if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
        local L = FP.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["ZONE_POI_ALL"] or "Important Zone POIs", 1.0, 0.84, 0.40)
        GameTooltip:AddLine(L["ZONE_POI_SUMMARY_TIP"] or "Left-click: toggle zone POIs  |  Right-click: category filters", 0.92, 0.88, 0.78, true)
        GameTooltip:Show()
    end)
    filterBtn:SetScript("OnLeave", function()
        RefreshZoneBarVisual()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
    end)

    mainBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1.0, 0.88, 0.45, 1.0)
        if not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
        local L = FP.L or {}
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(L["ZONE_POI_ALL"] or "Important Zone POIs", 1.0, 0.84, 0.40)
        local stats = (lastMapID and FP.GetZonePOIStats) and FP:GetZonePOIStats(lastMapID) or nil
        if stats and stats.total > 0 then
            GameTooltip:AddLine(string.format("%s: %d / %d",
                L["ZONE_POI_STATUS_UNDISC"] or "Yet to discover",
                stats.undiscovered, stats.total), 1, 0.85, 0.35)
            if stats.totalFlight > 0 then
                GameTooltip:AddLine(string.format("%s: %d / %d",
                    L["ZONE_POI_CAT_FLIGHT"] or "Flight Masters",
                    stats.undiscFlight, stats.totalFlight), 0.95, 0.92, 0.84)
            end
            if stats.totalInn > 0 then
                GameTooltip:AddLine(string.format("%s: %d / %d",
                    L["ZONE_POI_CAT_INN"] or "Innkeepers",
                    stats.undiscInn, stats.totalInn), 0.95, 0.92, 0.84)
            end
        end
        GameTooltip:AddLine(L["ZONE_POI_SUMMARY_TIP"] or "Left-click: toggle zone POIs  |  Right-click: category filters", 0.86, 0.80, 0.68, true)
        GameTooltip:Show()
    end)
    mainBtn:SetScript("OnLeave", function()
        RefreshZoneBarVisual()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
    end)

    zoneBar = bar
    SyncOverlayLevel(bar, overlayRoot, 115)
    RefreshZoneBarVisual()
    return bar
end

local function GetOrCreateZonePOIPin(idx, proxyParent)
    local pin = poiPins[idx]
    if pin then return pin end

    pin = CreateFrame("Button", "NexusKitZonePOIPin" .. idx, proxyParent, "BackdropTemplate")
    pin:SetSize(21, 21)
    pin:EnableMouse(true)
    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    pin:SetBackdropColor(0.05, 0.06, 0.09, 0.95)

    local tex = pin:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 2, -2)
    tex:SetPoint("BOTTOMRIGHT", -2, 2)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    pin.tex = tex

    -- Top-right amber dot marks points still waiting to be discovered
    local undiscDot = pin:CreateTexture(nil, "OVERLAY")
    undiscDot:SetSize(7, 7)
    undiscDot:SetPoint("TOPRIGHT", 2, 2)
    undiscDot:SetTexture("Interface\\Buttons\\WHITE8x8")
    undiscDot:SetVertexColor(1.0, 0.78, 0.15, 1.0)
    undiscDot:Hide()
    pin.undiscDot = undiscDot

    -- Bottom-right green dot marks discovered / learned points
    local discDot = pin:CreateTexture(nil, "OVERLAY")
    discDot:SetSize(6, 6)
    discDot:SetPoint("BOTTOMRIGHT", 2, -2)
    discDot:SetTexture("Interface\\Buttons\\WHITE8x8")
    discDot:SetVertexColor(0.28, 0.95, 0.50, 0.95)
    discDot:Hide()
    pin.discDot = discDot

    pin:SetScript("OnClick", function(self, button)
        local poi = self.poi
        if not poi then return end
        if button == "LeftButton" then
            if FP.SetCustomWaypoint and self.mapID then
                FP:SetCustomWaypoint(poi.x, poi.y, poi.name, self.mapID)
            end
        elseif button == "RightButton" then
            if poi.cat == "dungeon" and poi.guideID and IsShiftKeyDown and IsShiftKeyDown() and FP.ToggleDungeonGuide then
                FP:ToggleDungeonGuide(tostring(poi.guideID))
                return
            end
            if FP.TogglePOIDiscovered then
                FP:TogglePOIDiscovered(poi)
            end
        end
    end)

    pin:SetScript("OnEnter", function(self)
        local poi = self.poi
        if not poi or not GameTooltip or (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then return end
        local L = FP.L or {}
        local st = CAT_STYLES[poi.cat] or CAT_STYLES.repair
        local c = st.col
        local catLabel = L[st.labelKey] or st.fallback

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(string.format("[%s] %s", catLabel, poi.name or "?"), c[1], c[2], c[3])
        if IsSafeStr(poi.sub) then
            GameTooltip:AddLine(poi.sub, 0.84, 0.90, 0.98, true)
        end
        GameTooltip:AddLine(string.format("%s  (%.1f, %.1f)", poi.faction or "Both", poi.x or 0, poi.y or 0), 0.70, 0.76, 0.86)
        if poi.isHearthstone then
            GameTooltip:AddLine(L["ZONE_POI_HEARTH"] or "[Current Hearthstone]", 0.30, 0.95, 1.0)
        end
        if poi.discovered then
            GameTooltip:AddLine(L["ZONE_POI_STATUS_DISC"] or "Discovered", 0.32, 0.95, 0.55)
        else
            GameTooltip:AddLine(L["ZONE_POI_STATUS_UNDISC"] or "Yet to discover", 1.0, 0.72, 0.16)
        end
        local r, g, b = FP:GetAccentColor()
        GameTooltip:AddLine(L["ZONE_POI_TIP_WAYPOINT"] or "Left-click: set navigation arrow", r, g, b, true)
        GameTooltip:AddLine(L["ZONE_POI_TIP_TOGGLE_DISC"] or "Right-click: toggle discovered / undiscovered", 0.74, 0.80, 0.90, true)
        if poi.cat == "dungeon" and poi.guideID then
            GameTooltip:AddLine(L["ZONE_POI_TIP_DUNGEON_GUIDE"] or "Shift+Right-click: open Boss Tactics", 0.80, 0.62, 1.0, true)
        end
        GameTooltip:Show()
    end)

    pin:SetScript("OnLeave", function()
        if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
            GameTooltip:Hide()
        end
    end)

    poiPins[idx] = pin
    return pin
end

function FP:RenderZonePOIsOnMap(proxyParent, currentMapID, w, h, overlayRoot)
    lastOverlayRoot = overlayRoot
    lastMapID = IsSafeNum(currentMapID) and currentMapID or nil

    if overlayRoot then
        local bar = EnsureZoneBar(overlayRoot)
        RefreshZoneBarVisual()
        bar:Show()
        if filterPanel and filterPanel:IsShown() then
            SyncOverlayLevel(filterPanel, overlayRoot, 125)
            RefreshFilterPanelCheckboxes()
        end
    end

    if not IsZonePOIsEnabled() or not proxyParent or not lastMapID or not w or not h then
        HideZonePOIPins()
        return
    end

    local list = self.GetZonePOIs and self:GetZonePOIs(lastMapID) or {}
    local strata = proxyParent.GetFrameStrata and proxyParent:GetFrameStrata()
    local lvl = ((proxyParent.GetFrameLevel and proxyParent:GetFrameLevel()) or 120) + 22

    for idx, poi in ipairs(list) do
        local pin = GetOrCreateZonePOIPin(idx, proxyParent)
        if pin:GetParent() ~= proxyParent then
            pin:SetParent(proxyParent)
        end
        if strata then pin:SetFrameStrata(strata) end
        pin:SetFrameLevel(lvl)
        pin:SetScale(1)

        local st = CAT_STYLES[poi.cat] or CAT_STYLES.repair
        local sz = st.size or 20
        pin:SetSize(sz, sz)
        pin.poi = poi
        pin.mapID = lastMapID

        local texPath = st.icon
        if poi.cat == "flight" and poi.faction == "Horde" and st.hordeIcon then
            texPath = st.hordeIcon
        end
        pin.tex:SetTexture(texPath)

        local c = st.col
        if poi.isHearthstone then
            pin:SetBackdropBorderColor(0.30, 0.96, 1.00, 1.0)
            pin.tex:SetDesaturated(false)
            pin.tex:SetAlpha(1.0)
            pin.undiscDot:Hide()
            pin.discDot:Show()
        elseif poi.discovered then
            pin:SetBackdropBorderColor(0.32, 0.50, 0.40, 0.85)
            pin.tex:SetDesaturated(true)
            pin.tex:SetAlpha(0.72)
            pin.undiscDot:Hide()
            pin.discDot:Show()
        else
            pin:SetBackdropBorderColor(c[1], c[2], c[3], 0.98)
            pin.tex:SetDesaturated(false)
            pin.tex:SetAlpha(1.0)
            pin.undiscDot:Show()
            pin.discDot:Hide()
        end

        pin:ClearAllPoints()
        pin:SetPoint("CENTER", proxyParent, "TOPLEFT", (poi.x / 100) * w, -((poi.y / 100) * h))
        pin:Show()
    end

    for j = #list + 1, #poiPins do
        poiPins[j]:Hide()
    end
end

function FP:HideZonePOIs()
    HideZonePOIPins()
    if filterPanel then filterPanel:Hide() end
    if zoneBar then zoneBar:Hide() end
end

function FP:RefreshZonePOIs()
    RefreshZoneBarVisual()
    RefreshFilterPanelCheckboxes()
    if WorldMapFrame and WorldMapFrame:IsShown() and self.RepositionMapPin then
        self:RepositionMapPin()
    end
end
