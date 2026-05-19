package.path = package.path .. ";/?.lua"

for _, file in ipairs(fs.list("disk/station_files/")) do
    fs.copy(fs.combine("disk/station_files", file), fs.combine("/", file))
end

local position = vector.new(gps.locate(5, true)):sub(vector.new(-1, 0, 0))
print("Position: " .. tostring(position))

local routing = require("helpers.routing")
local csv = require("libs.csv")

print("Please construct station correctly, press f1 to proceed with check")

while true do
    repeat
        local event, key = os.pullEvent("key")
    until key == keys.f1

    local pass = require("verify_station")

    if not pass then
        printError("Please fix above issues and try again")
    else
        break
    end
end

_G.encnet = require("libs.encnet.comms")

local key_file = fs.open("disk/current_key.txt", "r")
local session_key = key_file.readAll()
key_file.close()

print(session_key)

encnet.open("left", session_key)

local function get_response(required_type)
    local x, y = term.getCursorPos()

    while true do
        term.setCursorPos(1, y)
        term.clearLine()

        write("> ")

        local input = read()

        if required_type == "num" then
            if input:match("^%d+$") then
                return tonumber(input)
            end
        else
            if input ~= "" then
                return input
            end
        end
    end
end

print("Station id?")
local station_id = get_response("num")

print("\nStation name?")
local name = get_response("str")

print("\nStation description?")
local desc = get_response("str")

print("\nAnother stations computer id?")
local other_id = get_response("num")

encnet.send(other_id, "OtheStat", true)

print("Wating for other station list")
local sender, payload_type, data = nil, nil, {}
parallel.waitForAny(
    function ()
        while true do
            sender, payload_type, data = encnet.receive()
            if payload_type == "OtheStat" then return end
        end
    end,
    function ()
        while true do
            local event, key = os.pullEvent("key")
            if key == keys.f1 then 
                data[1] = "{}"
                return
            end
        end
    end
)

---@type Station[]
local stations = textutils.unserialise(data[1])

local neighbors = {}

for computer_id, station_info in pairs(stations) do
    local pos = vector.new(station_info.position.x, station_info.position.y, station_info.position.z)
    print(routing.get_distance(pos, position))
    if routing.get_distance(pos, position) < 10000 and computer_id ~= os.computerID() then
        table.insert(neighbors, tonumber(computer_id))
    end
end

---@type Station
local this_station = {
    station_id = station_id --[[@as number]],
    computer_id = os.getComputerID(),
    name = name --[[@as string]],
    description = desc --[[@as string]],
    position = position,
    neighbors = neighbors,
    next_station = -1
}

stations[this_station.computer_id] = this_station

encnet.broadcast("NewStati", 
    station_id, 
    os.computerID(),
    position.x,
    position.y,
    position.z,
    name, 
    desc, 
    table.concat(neighbors, ":"), 
    -1)

fs.open("data/individual_stations/station_" .. os.computerID() .. ".csv", "w").close()
csv.append_file("data/individual_stations/station_" .. os.computerID() .. ".csv", 
    {
        this_station.station_id,
        this_station.computer_id,
        this_station.position.x,
        this_station.position.y,
        this_station.position.z,
        this_station.name,
        this_station.description,
        table.concat(this_station.neighbors, ":"),
        this_station.next_station
    }
)

print(textutils.serialise(stations))

fs.open("data/stations.csv", "w").close()
for _, station_info in pairs(stations) do
    csv.append_file("data/stations.csv", 
        {
            station_info.station_id,
            station_info.computer_id,
            station_info.position.x,
            station_info.position.y,
            station_info.position.z,
            station_info.name,
            station_info.description,
            table.concat(station_info.neighbors, ":"),
            station_info.next_station
        })
end

sleep(2)

settings.set("computer_id", os.computerID())
settings.set("station.key_count", 0)
settings.set("crypto.use_random_org", true)
settings.save()

shell.run("main.lua", session_key)