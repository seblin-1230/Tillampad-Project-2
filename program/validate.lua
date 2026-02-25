local sha256 = require("sha256")

local function yield()
    os.queueEvent("yield")
    os.pullEvent("yield")
end

---Returns all files in the computer, searches recursivly
---@param path string
---@return string[]
local function get_files_recursive(path)
    local found_files = {}

    for _, file_path in ipairs(fs.list(path)) do
        local full_path = fs.combine(path, file_path)
        if fs.isDir(full_path) then
            local new_file_paths = get_files_recursive(full_path)
            table.move(new_file_paths, 1, #new_file_paths, #found_files + 1, found_files)
        elseif string.match(full_path, "$%.") == nil then
            table.insert(found_files, full_path)
        end
    end

    return found_files
end

---Hash a station using sha256
---@param station_data Station
local function hash_station(station_data)

    local file_paths = get_files_recursive(".")

    local file_contents = {}
    for i, file_path in ipairs(file_paths) do
        local file = assert(fs.open(file_path, "r"))
        file_contents[i] = file.readAll()
        file.close()

        if i % 20 then
            yield()
        end
    end

    local data_string = textutils.serialise(station_data, {compact = true}) .. table.concat(file_contents)

    local out_file = fs.open("out.txt", "w")
    out_file.writeLine(data_string)
    out_file.writeLine(sha256.sha256(data_string))
    out_file.close()
end

hash_station({station_id = 1, computer_id = 18, arrival_coordinates = vector.new(250, 140, 255), description = "The first station", teleport_coordinates = vector.new(251, 140, 257)})