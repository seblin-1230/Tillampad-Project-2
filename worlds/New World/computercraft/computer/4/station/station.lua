---@alias Entity {uuid: stringlib, name: string }

local focal_port = peripheral.find("focal_port") or error("No focal port connected")
local impetus = peripheral.find("cleric_impetus") or error("No spell circle found")

---The function that does the teleporting
---@param pearl Entity
---@param destination ccTweaked.Vector
---@return boolean
---@return string
local function teleport(pearl, destination)
    local focal_data = {pearl, destination}

    impetus.activateCircle()

    while impetus.isCasting() do
        print("Casting")
    end
    print("Casting done")

    return true, ""
end

print(focal_port.hasFocus())
teleport(nil, nil)