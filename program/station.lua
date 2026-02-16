---@alias Entity {isPlayer: boolean, uuid: string, name: string}

local focal_port = peripheral.find("focal_port") or error("No focal port connected")
local impetus = peripheral.find("cleric_impetus") or error("No spell circle found")

---The function that does the teleporting
---@param entities Entity[]
---@param destination ccTweaked.Vector
---@return boolean
---@return string
local function teleport(entities, destination)
    focal_port.writeIota(entities)
    impetus.activateCircle()

    while impetus.isCasting() do
        -- Wait for cast to finish  
    end
    print("Casting done")

    return true, ""
end

print(focal_port.hasFocus())
teleport(nil, nil)