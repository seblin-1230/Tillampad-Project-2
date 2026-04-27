local utils = require("libs.utils")
local sha256 = require("libs.encryption.sha256")

local file_blacklist = {
    ["rom"] = true,
    ["data"] = true,
    ["main.lua"] = true,
}



local function hash_files()
    LOGGER:info("Initiating file hashing")

    local file_paths = utils.recursive_file_list("src", file_blacklist)

    local tasks = {}
    local results = {}

    for _, path in ipairs(file_paths) do
        local l_path = path:gsub("%s+$", "")
        table.insert(tasks, function()
            LOGGER:info("Attempting hashing of " .. l_path)
            local file = assert(fs.open(l_path, "r"))
            local message = assert(file.readAll())
            file.close()
            results[path] = sha256.hash(message)
            LOGGER:info("Hashed file \"" .. l_path .. "\" : " .. results[path])
        end)
    end

    local ordered = {}
    local total_bytes = 0
    for _, path in ipairs(file_paths) do
        table.insert(ordered, results[path])

        total_bytes = total_bytes + fs.attributes(path).size
    end

    parallel.waitForAll(table.unpack(tasks))

    LOGGER:info("All individual files hashed")

    local file_hash = sha256.hash(table.concat(ordered))
    LOGGER:info("All file hashes hashed, bytes hashed: ", total_bytes, " : ", file_hash)

    return file_hash
end

local function hash_peripherals()
    LOGGER:info("Initiating peripheral hashing")

    local peripheral_names = peripheral.getNames()
    
    local peripheral_types = {}
    for i, name in ipairs(peripheral_names) do
        peripheral_types[i] = peripheral.getType(name)
    end

    local peripheral_hash = sha256.hash(table.concat(peripheral_types))
    LOGGER:info("Peripherals hashed")

    return peripheral_hash
end

local function hash_blocks()
    -- TODO Add this
    return ""
end

function Hash_station(computer_id)
    LOGGER:info("Initiating station hashing")
    local file_hash = hash_files()
    local peripheral_hash = hash_peripherals()
    local block_hash = hash_blocks()

    return sha256.hash(file_hash .. peripheral_hash .. block_hash .. tostring(computer_id))
end

return Hash_station