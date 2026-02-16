local focal_port = peripheral.find("focal_port") or error("No focal port connected")
local impetus = peripheral.find("cleric_impetus") or error("No spell circle connected")

---The function that does the teleporting
---@param destination ccTweaked.Vector
---@return boolean
---@return string
local function teleport(destination)
    focal_port.writeIota(destination)
    impetus.activateCircle()

    while impetus.isCasting() do
        -- Wait for cast to finish  
    end
    print("Casting done")

    return true, ""
end

print(focal_port.hasFocus())
teleport({x = -200, y = 120, z = 120})