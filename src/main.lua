---@alias Station {computer_id: integer, station_id: integer, position: ccTweaked.Vector, name: string, description: stringlib, neighbors: integer[], unsafe: boolean}

local sha256             = require("libs.encryption.sha256")
local crypto             = require("libs.encryption.crypto")
local utils              = require("libs.utils")
local csv                = require("libs.csv")
local teleport           = require("main.teleport")
local session_key_module = require("main.session_key_module")

local communication = require("main.communication")

local modem         = peripheral.find("modem")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count + 1)
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
    for str in string.gmatch(raw[8], "[^:]+") do
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

        setmetatable(station_info, {
            __tostring = function(s) return "Station<" .. s.station_id .. "," .. s.computer_id .. ">" end
        })

        stations[station_info.computer_id] = station_info
    end

    setmetatable(stations, {
        __tostring = function(stations) return table.concat(stations, ", ") end
    })

    return stations
end

---Get the data for this station
---@return Station
local function read_this_station()
    local unformated_station = csv.read_file("src/data/individual_stations/station_" ..
        tostring(os.computerID()) .. ".csv")[1]

    local station_info = format_station(unformated_station)

    setmetatable(station_info, {
        __tostring = function(s) return "Station<" .. s.station_id .. "," .. s.computer_id .. ">" end
    })

    return station_info
end



local this_station = read_this_station()
local stations = read_stations()
local session_key

_G.get_this_station = function()
    local info = debug.getinfo(2, "Sl")
    LOGGER:info("This station accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)
    return this_station
end

_G.get_stations = function()
    local info = debug.getinfo(2, "Sl")
    LOGGER:info("Station list accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)
    return stations
end

_G.get_station_ids = function()
    local info = debug.getinfo(2, "Sl")
    LOGGER:info("Station ids accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)

    local ids = {}
    for i, station in pairs(stations) do
        ids[station.station_id] = true
    end

    return ids
end

_G.set_session_key = function (fn_session_key)
    if session_key == nil then
        session_key = fn_session_key
    end
end


_G.teleport_queue = {}
_G.in_teleport = false
_G.attempting_teleport_payload = nil
_G.route = {}
_G.ready = false

local function async_main()
    while true do
        local event, key, is_held = os.pullEvent("key")
        if key == keys.f1 and not is_held then
            if os.computerID() == 0 then
                print("Trying to teleport to -260, 64, 260")
                teleport.initiate(this_station.computer_id, { destination = vector.new(-260, 64, 260) }, false)
            elseif os.computerID() == 1 then
                print("Trying to teleport to station 0")
                teleport.initiate(this_station.computer_id, { destination = stations[0] }, false)
            elseif os.computerID() == 2 then
                print("Trying to teleport to station 3")
                teleport.initiate(this_station.computer_id, { destination = stations[3] }, false)
            end
        end
    end
end

-- On startup
term.clear()
term.setCursorPos(1, 1)

-- Step 1
local last_station
local y = 1
while true do
    term.setCursorPos(1, y)
    term.clearLine()
    term.setTextColor(colors.white)

    write("Last station? > ")
    local response = read()
    
    if response == "" or get_station_ids()[tonumber(response)] ~= nil then
        break
    else
        term.setCursorPos(1, 1)
        term.clearLine()

        printError("Not a valid station id")
        y = 2
    end
end


-- Step 2
local key_file = fs.open("disk/secret.txt", "r")
local master_key = key_file.readAll()
key_file.close()

if last_station == nil then
    session_key = generate_session_key()
else
    session_key_module.request()
    print("Waiting for session key")
end

encnet.close(peripheral.getName(modem))
encnet.open(peripheral.getName(modem), session_key)

parallel.waitForAll(
    function() communication.Handle_communication(session_key) end,
    async_main
)
