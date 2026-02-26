local cc_strings = require("cc.strings")

---@type Station
local station_data = {}

---@type Station[]
local other_stations = {}
local station_hashes = {}

local function check_peripherals()
    local needed_peripherals = {
        "modem",
        "turtle",
        "redstone_relay",
        "focal_port",
        "cleric_impetus"
    }

    local connected_peripherals = {}

    for i, periph in ipairs(peripheral.getNames()) do
        local type, _ = peripheral.getType(periph)
        connected_peripherals[type] = true
    end

    local any_missing = false
    term.setTextColor(colors.red)
    for i, needed_periph in ipairs(needed_peripherals) do
        if not connected_peripherals[needed_periph] then
            any_missing = true
            print("A " .. needed_periph .. " is not found")
        end
    end

    term.setTextColor(colors.white)
    if any_missing then
        print("Add missing peripherals and run program again")
    end

    return any_missing
end

local function copy_files()
    fs.copy("drive/validate.lua", "program/validate.lua")
    fs.copy("drive/sha256.lua", "program/sha256.lua")
    fs.copy("drive/station.lua", "program/station.lua")
    print("Files copied from disk...\n")
end

local function define_settings()
    settings.define("station_data", { description = "The data about this station", type = "table" })

    write("Station desc: ")
    station_data.description = read()
    print()

    write("Arival position \"x,y,z\": ")
    local pos = cc_strings.split(read(), "[^%d]+")
    station_data.arrival_coordinates = vector.new(assert(tonumber(pos[1])), assert(tonumber(pos[2])), assert(tonumber(pos[3])))
    print()

    write("Transfer position \"x,y,z\": ")
    local pos = cc_strings.split(read(), "[^%d]+")
    station_data.teleport_coordinates = vector.new(assert(tonumber(pos[1])), assert(tonumber(pos[2])), assert(tonumber(pos[3])))
    print()

    rednet.broadcast(true, "get-new-id")
    
    write("Station ID: ")
    station_data.station_id = assert(tonumber(read()))
    print()

    station_data.computer_id = os.getComputerID()

    settings.set("station_data", station_data)

    return true
end

local function annonce_existance()
    rednet.broadcast(station_data, "new_staion")

    repeat
        local id, message = rednet.receive("new_staion", 5)

        if id then
            print("Recived data from station " .. id)
            ---@cast message Station
            other_stations[message.station_id] = message
        end
    until id == nil
end

if check_peripherals() then goto quit end
print()
copy_files()

local modem = assert(peripheral.find("modem"))
rednet.open(peripheral.getName(modem))

define_settings()
annonce_existance()


settings.save()
::quit::
