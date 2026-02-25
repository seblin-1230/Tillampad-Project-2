local sha256 = require("sha256")

local function validate()
    
end

local function hash_station()
    local data = ""
    local files = fs.list("/station/")

    for i = 1, #files do
        local file = assert(fs.open("/station/" .. files[i], "r"))
        data = data .. file.read()
        file.close()
    end

    data = data .. settings.get("station_description") .. settings.get("arrival_position") .. settings.get("transfer_position")

    return sha256.hash(data)
end

return {validate = validate, hash_station()}