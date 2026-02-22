local cc_strings = require("cc.strings")

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

local function define_settings()
    settings.define("station_id", { description = "The station id", type = "number" })
    settings.define("station_description", { description = "The stations description", type = "string" })
    settings.define("arrival_position", { description = "The position a user should arrive on when the station is the destination", type = "table" })
    settings.define("transfer_position", { description = "The position a user should arrive on when the station is used as an inbetween", type = "table" })

    write("Station desc: ")
    settings.set("station_description", read())
    print()

    write("Arival position \"x,y,z\": ")
    local pos = cc_strings.split(read(), "[^%d]+")
    settings.set("arrival_position", vector.new(assert(tonumber(pos[1])), assert(tonumber(pos[2])), assert(tonumber(pos[3]))))
    print()

    write("Transfer position \"x,y,z\": ")
    local pos = cc_strings.split(read(), "[^%d]+")
    settings.set("transfer_position", vector.new(assert(tonumber(pos[1])), assert(tonumber(pos[2])), assert(tonumber(pos[3]))))
    print()

    rednet.host("add station", settings.get("transfer_position"))

    local controller_id = rednet.lookup("add station", "station_controller")
    print(controller_id, type(controller_id))
end


if check_peripherals() then goto quit end
print()


local modem = assert(peripheral.find("modem"))
rednet.open(peripheral.getName(modem))

local settings_defined = define_settings()

::quit::
