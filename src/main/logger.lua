---@class LOGGER
---@field station_id number The id of the station the logger is on
---@field log_file ccTweaked.fs.WriteHandle The file handle of the log file
local LOGGER = {}

local function log_path(station_id)
    local time = os.date("%F")
    local base = "/logs/" .. tostring(station_id) .. "-" .. time .. "-"

    for i = 1, 100 do
        local path = base .. tostring(i) .. ".log"
        if not fs.exists(path) then
            return path
        end
    end
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
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [INFO]    : " .. format(...))
    self.log_file.flush()
end

function LOGGER:warning(...)
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [WARNING] : " .. format(...))
    self.log_file.flush()
end

function LOGGER:error(...)
    local time = os.date("[%T]")
    self.log_file.writeLine(time .. " [ERROR]   : " .. format(...))
    self.log_file.flush()
end

return LOGGER