local utils = require("libs.utils")
local sha256 = require("libs.sha256")
local file = fs.open("disk/hashes.lua", "w")

local file_blacklist = {
    ["rom"] = true,
    ["data"] = true,
    ["disk"] = true,
    ["logs"] = true,
    ["main.lua"] = true,
    [".settings"] = true,
    [".cash_history"] = true
}

local file_list = utils.recursive_file_list("/", file_blacklist)

local hashes = {}
local tasks = {}

for _, path in ipairs(file_list) do
    local l_path = path:gsub("%s+$", "")
    table.insert(tasks, function()
        LOGGER:info("Hashing file \"" .. l_path .. "\"")
        local file = assert(fs.open(l_path, "r"))
        local message = assert(file.readAll())
        file.close()

        hashes[path] = sha256.hash(message)
        LOGGER:info("Hashed file \"" .. l_path .. "\" : " .. hashes[path])
    end)
end

parallel.waitForAll(table.unpack(tasks))


local peripheral_names = peripheral.getNames()

local peripheral_types = {}
for i, name in ipairs(peripheral_names) do
    peripheral_types[i] = peripheral.getType(name)
end

local peripheral_hash = sha256.hash(table.concat(peripheral_types))

hashes["peripherals"] = peripheral_hash

file.write("return " .. textutils.serialise(hashes))
file.close()