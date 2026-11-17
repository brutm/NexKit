-- NexusKit  –  Core/Parser.lua
-- Route validation, import-string parsing and custom-route persistence.
local _, FP = ...

------------------------------------------------------------------------
-- Local helpers
------------------------------------------------------------------------
local function Trim(s)
    if not s then return "" end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

------------------------------------------------------------------------
-- Validation helpers
------------------------------------------------------------------------
local VALID_ACTIONS = {
    ACCEPT     = true,
    COMPLETE   = true,
    TURNIN     = true,
    GRIND      = true,
    GOTO       = true,
    TRAIN      = true,
    SET_HEARTH = true,
    USE_HEARTH = true,
    FLY        = true,
}

--- Validate a route table.
-- @param rt  table  the route to validate
-- @return boolean, string|nil   true on success; false + error message on failure
local function ValidateRoute(rt)
    if type(rt) ~= "table" then
        return false, "Route is not a table."
    end
    if not rt.routeId or rt.routeId == "" then
        return false, "Missing routeId."
    end
    if not rt.faction or rt.faction == "" then
        return false, "Missing faction."
    end
    if type(rt.steps) ~= "table" or #rt.steps == 0 then
        return false, "Missing or empty steps array."
    end
    for i, step in ipairs(rt.steps) do
        if type(step) ~= "table" then
            return false, string.format("Step %d is not a table.", i)
        end
        if not step.action or not VALID_ACTIONS[step.action] then
            return false, string.format("Step %d has invalid action: %s", i, tostring(step.action))
        end
        if not step.id then
            step.id = i
        end
        if not step.text or step.text == "" then
            step.text = step.action
        end
    end
    return true
end

------------------------------------------------------------------------
-- RegisterRoute (full validation wrapper – overrides the stub in Init)
------------------------------------------------------------------------
function FP:RegisterRoute(routeTable)
    local ok, err = ValidateRoute(routeTable)
    if not ok then
        FP:Print(string.format(FP.L["IMPORT_ERROR"], err))
        return false
    end
    self.routes[routeTable.routeId] = routeTable
    return true
end

------------------------------------------------------------------------
-- Import-string parser  (format: NK1:META|...#STEP|...#)
------------------------------------------------------------------------

--- Split a |-delimited row into an array; empty fields become nil.
local function SplitPipe(line)
    local fields = {}
    for part in (line .. "|"):gmatch("([^|]*)|") do
        local trimmed = Trim(part)
        if trimmed == "" then
            fields[#fields + 1] = nil
        else
            fields[#fields + 1] = trimmed
        end
    end
    return fields
end

--- Parse a comma-separated string into a list table, or nil if empty.
local function ParseCSV(str)
    if not str or str == "" then return nil end
    local t = {}
    for token in str:gmatch("[^,]+") do
        local trimmed = Trim(token)
        if trimmed ~= "" then
            t[#t + 1] = trimmed
        end
    end
    return (#t > 0) and t or nil
end

--- Attempt to convert a field to a number; returns nil when it cannot.
local function ToNum(v)
    if not v then return nil end
    return tonumber(v)
end

--- Parse a NexusKit import string (version 1; also accepts legacy FP1: prefix).
-- @param str  string   the full NK1: or FP1: string
-- @return table|nil, string|nil   route table on success; nil + error on failure
function FP:ParseImportString(str)
    if type(str) ~= "string" then
        return nil, "Input is not a string."
    end

    str = Trim(str)
    local prefix = str:sub(1, 4)
    if prefix ~= "NK1:" and prefix ~= "FP1:" then
        return nil, "Invalid prefix (expected NK1:)."
    end
    local body = Trim(str:sub(5))
    if body == "" then
        return nil, "Empty import body."
    end

    -- Split into # delimited records (newlines around # are trimmed)
    local lines = {}
    for segment in (body .. "#"):gmatch("([^#]*)#") do
        segment = Trim(segment)
        if segment ~= "" then
            lines[#lines + 1] = segment
        end
    end

    if #lines < 2 then
        return nil, "Import string must contain a META line and at least one STEP."
    end

    ------------------------------------------------------------------
    -- Parse META line
    ------------------------------------------------------------------
    local metaFields = SplitPipe(lines[1])
    if not metaFields[1] or metaFields[1] ~= "META" then
        return nil, "First line is not a META record."
    end

    local routeId  = metaFields[2]
    local title    = metaFields[3]
    local faction  = metaFields[4]
    local minLevel = ToNum(metaFields[5])
    local maxLevel = ToNum(metaFields[6])

    if not routeId or routeId == "" then
        return nil, "META is missing routeId."
    end
    if not faction or faction == "" then
        return nil, "META is missing faction."
    end

    ------------------------------------------------------------------
    -- Parse STEP lines
    ------------------------------------------------------------------
    local steps = {}
    for i = 2, #lines do
        local f = SplitPipe(lines[i])
        if f[1] ~= "STEP" then
            return nil, string.format("Line %d is not a STEP record.", i)
        end

        local rawAction = f[3]
        local action = rawAction and tostring(rawAction):upper():gsub("%s+", "") or nil

        local step = {
            id             = ToNum(f[2]) or f[2] or (i - 1),
            action         = action,
            text           = f[4],
            mapID          = ToNum(f[5]),
            x              = ToNum(f[6]),
            y              = ToNum(f[7]),
            questId        = ToNum(f[8]),
            objectiveIndex = ToNum(f[9]),
            targetLevel    = ToNum(f[10]),
            classes        = ParseCSV(f[11]),
            races          = ParseCSV(f[12]),
            itemID         = ToNum(f[13]),
            isOptional     = (f[14] == "1" or (f[14] and f[14]:lower() == "true")) and true or false,
            minLevel       = ToNum(f[15]),
            maxSkipLevel   = ToNum(f[16]),
        }

        if not step.action or not VALID_ACTIONS[step.action] then
            return nil, string.format("Step %d has invalid action: %s", i - 1, tostring(step.action))
        end

        steps[#steps + 1] = step
    end

    ------------------------------------------------------------------
    -- Build route table
    ------------------------------------------------------------------
    local route = {
        routeId  = routeId,
        title    = title or routeId,
        faction  = faction,
        minLevel = minLevel,
        maxLevel = maxLevel,
        steps    = steps,
    }

    local ok, err = ValidateRoute(route)
    if not ok then
        return nil, err
    end

    return route
end

------------------------------------------------------------------------
-- ImportRoute – persist + register a route table
------------------------------------------------------------------------
function FP:ImportRoute(routeTable)
    if not routeTable or not routeTable.routeId then
        return false, "No route to import."
    end

    local ok = self:RegisterRoute(routeTable)
    if not ok then
        return false, "Validation failed."
    end

    -- Persist into global saved variables so it survives /reload
    if NexusKitDB and NexusKitDB.customRoutes then
        NexusKitDB.customRoutes[routeTable.routeId] = routeTable
    end

    -- Refresh tracker UI so the new route immediately appears in the selector
    if self.RefreshAllUI then
        self:RefreshAllUI()
    end

    return true
end
