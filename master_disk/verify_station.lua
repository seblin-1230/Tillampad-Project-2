package.path = package.path .. ";/disk/station_files/?.lua;/disk/?.lua"
local correct_hashes = require("hashes")
local utils               = require("station_files.libs.utils")
local sha256              = require("station_files.libs.encryption.sha256")

local file_blacklist = {
    ["rom"] = true,
    ["data"] = true,
    ["disk"] = true,
    ["logs"] = true,
    ["main.lua"] = true,
    [".settings"] = true,
    [".cash_history"] = true
}

local pass = true

local file_list = utils.recursive_file_list("/", file_blacklist)

local modified_files = {}
local tasks = {}
for i, file_path in ipairs(file_list) do
    table.insert(tasks, function (    )
        local file = fs.open(file_path, "r")
        local hash = sha256.hash(file.readAll())

        if hash ~= correct_hashes[file_path] then
            table.insert(modified_files, file_path)
        end
    end)
end

parallel.waitForAll(table.unpack(tasks))

term.setTextColor(colors.red)
for _, file_path in ipairs(modified_files) do
    print(file_path .. " is modified")
    pass = false
end

local peripheral_names = peripheral.getNames()
    
local peripheral_types = {}
for i, name in ipairs(peripheral_names) do
    peripheral_types[i] = peripheral.getType(name)
end

table.sort(peripheral_types)

local peripheral_hash = sha256.hash(table.concat(peripheral_types, "|"))

if peripheral_hash ~= correct_hashes["peripherals"] then
    print("Peripherals modified")
    pass = false
end

-- TODO Block verification

return pass