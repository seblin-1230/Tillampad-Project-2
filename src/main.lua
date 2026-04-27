---@alias Station {computer_id: integer, station_id: integer, position: ccTweaked.Vector, name: string, description: stringlib, neighbors: integer[], unsafe: boolean}

local sha256        = require("libs.encryption.sha256")
local crypto        = require("libs.encryption.crypto")
local utils         = require("libs.utils")
local csv           = require("libs.csv")
local teleport      = require("main.teleport")

local Handle_communication = require("main.communication")

local modem = peripheral.find("modem")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count+1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end

---Convert the raw csv reader output to station data
---@param raw table
---@return Station station
local function format_station(raw)
    local station_info = {
        computer_id = raw[2],
        station_id = raw[1],
        position = vector.new(raw[3], raw[4], raw[5]),
        name = raw[6],
        description = raw[7],
        unsafe = false
    }

    local neighbors = {}
    for str in string.gmatch(raw[8], ":") do
        table.insert(neighbors, tonumber(str))
    end

    station_info.neighbors = neighbors

    return station_info
end

---Get all the stations saved to file
---@return Station[]
local function read_stations()
    local unformated_stations = csv.read_file("src/data/stations.csv")

    local stations = {}
    for i, unformated_station in ipairs(unformated_stations) do
        local station_info = format_station(unformated_station)

        stations[station_info.station_id] = station_info
    end

    return stations
end

---Get the data for this station
---@return Station
local function read_this_station()
    local unformated_station = csv.read_file("src/data/individual_stations/station_" .. tostring(os.computerID()) .. ".csv")[1]
    
    local station_info = format_station(unformated_station)
    return station_info
end

local function async_main()
    teleport.initiate(os.computerID(), {}, false)
    print("Teleport done")
end

local session_key = "aVUD5IqcE6E27lVRlByso9tN1IQC3Sdn" --generate_session_key()
local stations = read_stations()
local this = read_this_station()

parallel.waitForAll(
    function() Handle_communication(session_key) end,
    async_main
)