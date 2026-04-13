local csv = {}

function csv.read_file(path)
    path = fs.combine(path)

    local lines = {}
    local i = 1
    for line in io.lines(path, "l") do
        local split = {}

        for sub_str in string.gmatch(line, "[^,]+") do
            local value = sub_str --[[@type string|number?]]

            if sub_str:match("^[%d|-]+$") ~= nil then
                value = tonumber(sub_str)
            end

            table.insert(split, value)
        end

        lines[i] = split
        i = i +1
    end

    return lines
end

function csv.write_file(path, data)
    path = fs.combine(path)
    local file = fs.open(path, "w")
    assert(file)

    for i, line in ipairs(data) do
        file.writeLine(table.concat(line, ","))
    end
end

function csv.append_file(path, data)
    path = fs.combine(path)
    local file = fs.open(path, "a")
    assert(file)

    file.write("\n" .. table.concat(data, ","))
end

return csv