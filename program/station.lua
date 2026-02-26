---@alias Station {station_id: integer, description: string, arrival_coordinates: ccTweaked.Vector, teleport_coordinates: ccTweaked.Vector}

local focal_port = peripheral.find("focal_port") or error("No focal port connected")
local impetus = peripheral.find("cleric_impetus") or error("No spell circle connected")

local active = true

---@type Station
local this_station = { teleport_coordinates = vector.new(-235.5, 121.0, 120.5)}
---@type Station[]
local stations = {}

---Reset to terminal to thier starting state
local function reset()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)

    if active then
        term.setTextColor(colors.green)
        print("Station is active")

        term.setTextColor(colors.white)
        print("Press any key to begin teleport")
    else
        term.setTextColor(colors.red)
        print("Station is not active")
    end
    term.setTextColor(colors.white)
end

---Checks if the response to a user query was a valid selection
---@param user_input string
---@param min integer
---@param max integer
---@return boolean
local function validate_selection(user_input, min, max)
    if string.match(user_input, "^%d+$") then
        if tonumber(user_input) >= min and tonumber(user_input) <= max then
            return true
        end
    end

    return false
end

---Validate the coordiantes input by user
---@param num string
local function validate_coordinates(num)
    -- Not implementated
end

---Get a coordiante from user
---@param type string
---@return number
local function get_coordinate(type)
    local num
    repeat
        local valid = true
        write(type .. ": ")
        num = read():gsub("%s+", "")

        if not string.match(num, "^[+-]?%d+$") then
            valid = false
            print(num .. " is not a number, please input " .. type .. " again")
        end

        if valid and math.abs(tonumber(num) - this_station.teleport_coordinates[type]) > 10000 and type ~= "y" then
            valid = false
            print(num .. " is not withing 10k blocks, please input " .. type .. " again")
        end

        if valid and (math.abs(tonumber(num) - this_station.teleport_coordinates[type]) > 319 or math.abs(tonumber(num) - this_station.teleport_coordinates[type]) < -64) and type == "y" then
            valid = false
            print(num .. " is outside the world, please input " .. type .. "again")
        end

    until valid

    return assert(tonumber(num))
end

---The function that does the teleporting
---@param destination ccTweaked.Vector
---@return boolean
---@return string
local function teleport(destination)
    focal_port.writeIota(destination)

    term.setTextColor(colors.green)
    print("Please step on the pressure plate")
    term.setTextColor(colors.white)

    os.pullEvent("redstone")

    print("Teleport starting...")
    impetus.activateCircle()

    os.pullEvent("circle_stopped")
    print("Teleport finished")
    sleep(4)

    return true, ""
end

---Called when the user select that they want to teleport to a station
local function station_selected()
    print("Sorry! This feature is yet to be implementated")
    sleep(3)
end

---Called when the user selects they want to teleport to a station
local function coordinates_selected()
    print("\nPlease enter the coordinates")
    local x = get_coordinate("x")
    local y = get_coordinate("y")
    local z = get_coordinate("z")

    teleport(vector.new(x, y, z))
end

local function start_teleport()
    local selected = ""

    repeat
        print()
        term.blit("Where to teleport? Hold q to cancel", "000000000000000000eeeeeeeeeeeeeeeee", "fffffffffffffffffffffffffffffffffff")
        print()
        print("[1]: Stations")
        print("[2]: Coordinates")

        write("> ")
        local selected = read()
        local valid = validate_selection(selected, 1, 2)

        if not valid then print(selected .. " is not a valid selection") end
    until valid

    if selected == "1" then
        station_selected()
    else
        coordinates_selected()
    end
end

local function cancel_teleport()
    repeat
        local event, key, is_held = os.pullEvent("key")
    until key == keys["q"] and is_held
end

while true do
    reset()

    if not active then
        sleep(10)
        goto skip
    end

    repeat
        local event, key, is_held = os.pullEvent("key") -- Wait for user to interact with computer
    until key ~= keys["q"]

    parallel.waitForAny(cancel_teleport, start_teleport)

    ::skip::
end
