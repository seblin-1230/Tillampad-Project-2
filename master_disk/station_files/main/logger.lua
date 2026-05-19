---@class LOGGER
---@field station_id number The id of the station the logger is on
---@field log_file ccTweaked.fs.WriteHandle The file handle of the log file
local LOGGER = {}

local function log_path(station_id)
    local time = os.date("%F")
    local base = "/logs/TeleNet-" .. tostring(station_id) .. "-" .. time .. "-"

    local files = fs.list("/logs")
    return base .. tostring(#files + 1) .. ".log"
end

local function format(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end

    return table.concat(parts, "")
end

function LOGGER:new(o)
    self.station_id = o.station_id
    self.log_file = fs.open(log_path(o.station_id), "a") --[[@as ccTweaked.fs.WriteHandle]]

    _G.LOGGER = self
end

function LOGGER:info(...)
    local info = debug.getinfo(2, "Sl")
    local source = info.source:gsub("^@", "")
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [INFO] [" .. source .. ":" .. info.currentline .. "] : " .. format(...))
    self.log_file.flush()
end

function LOGGER:warning(...)
    local info = debug.getinfo(2, "Sl")
    local source = info.source:gsub("^@", "")
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [WARNING] [" .. source .. ":" .. info.currentline .. "] : " .. format(...))
    self.log_file.flush()
end

function LOGGER:error(...)
    local info = debug.getinfo(2, "Sl")
    local source = info.source:gsub("^@", "")
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [ERROR] [" .. source .. ":" .. info.currentline .. "] : " .. format(...))
    self.log_file.flush()
end

return LOGGER