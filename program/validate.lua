local sha256 = require("sha256")

local function append_table(table1, table2)
    for _, v in ipairs(table2) do
        table.insert(table1, v)
    end
end

local function get_files_recursive(path)
    local found_files = {}

    for _, file_path in ipairs(fs.list(path)) do
        local full_path = fs.combine(path, file_path)
        if fs.isDir(file_path) then
            append_table(found_files, get_files_recursive(full_path))
        else
            table.insert(found_files, fs.combine(path, full_path))
        end
    end

    return found_files
end

local function filter_files(file_paths)
    local filtered = {}
    for _, file_path in ipairs(file_paths) do
        if string.match(file_path, "$.") == nil then
            table.insert(filtered, file_path)
        end
    end
end

---Hash a station using sha256
---@param station_data Station
local function hash_station(station_data)
    local data_string = textutils.serialise(station_data, {compact = true})

    local file_paths = get_files_recursive(".")

end

hash_station({station_id = 1, computer_id = 18, arrival_coordinates = vector.new(250, 140, 255), description = "The first station", teleport_coordinates = vector.new(251, 140, 257)})