local focal_port = peripheral.find("focal_port") or error("No focal port connected")
local impetus = peripheral.find("cleric_impetus") or error("No spell circle connected")

local active = true

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

while true do
    reset()

    if not active then
        sleep(10)
        goto skip
    end

    os.pullEvent("key")
    print()

    ---@type integer|nil
    local selected = -1
    print("Where to teleport?")
    print("[1]: Stations")
    print("[2]: Coordinates")

    repeat
        write("> ")
        selected = tonumber(read())

        if selected ~= 1 and selected ~= 2 then
            print("Invalid selection. Please enter 1 or 2.")
        end
    until selected == 1 or selected == 2

    print("ewoijtiueh")

    ::skip::
end