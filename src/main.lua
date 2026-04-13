---@alias Station {computer_id: integer, position: ccTweaked.Vector, name: string, description: stringlib, neighbors: integer[], unsafe: boolean}

local sha256  = require("libs.encryption.sha256")
local crypto  = require("libs.encryption.crypto")
local utils   = require("libs.utils")
local csv     = require("libs.csv")
local routing = require("routing")

local modem = peripheral.find("modem")


local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count+1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end

---Get all the stations saved to file
---@return Station[]
local function read_stations()
    local unformated_stations = csv.read_file("src/data/stations.csv")

    local stations = {}
    for i, unformated_station in ipairs(unformated_stations) do
        local station_id = unformated_station[1]
        local station_info = {
            computer_id = unformated_station[2],
            position = vector.new(unformated_station[3], unformated_station[4], unformated_station[5]),
            name = unformated_station[6],
            description = unformated_station[7],
            unsafe = false
        }

        local neighbors = {}
        for str in string.gmatch(unformated_station[8], ":") do
            table.insert(neighbors, tonumber(str))
        end

        stations[station_id] = station_info
    end

    return stations
end

---Start the teleport process to a destination
---@param destination Station
---@param stations Station[]
local function initiate_teleport(destination, stations)
    local route = routing.find_route(destination, stations)
end

-- term.clear()
-- term.setCursorPos(1, 1)
-- term.setTextColor(colors.white)

local session_key = "aVUD5IqcE6E27lVRlByso9tN1IQC3Sdn" --generate_session_key()
local stations = read_stations()

print(textutils.serialise(stations))

initiate_teleport(stations[1], stations)