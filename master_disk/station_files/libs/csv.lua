local csv = {}

function csv.read_file(path)
    path = fs.combine(path)

    local lines = {}
    local i = 1
    for line in io.lines(path, "l") do
        -- print(line)
        local split = {}
        local pos = 1
        while pos <= #line + 1 do
            local next_comma = line:find(",", pos, true)
            if not next_comma then next_comma = #line + 1 end
            local field = line:sub(pos, next_comma - 1)
            local value = tonumber(field) or field
            table.insert(split, value)
            pos = next_comma + 1
        end

        lines[i] = split
        i = i + 1
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

    file.write(table.concat(data, ",") .. "\n")
end

return csv
