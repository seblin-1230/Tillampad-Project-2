local utils = {}

---Create a shallow copy of a table1
---@param table1 table
---@return table
function utils.copy_table(table1)
    local table2 = {}
    for key, value in pairs(table1) do
        table2[key] = value
    end
    return table2
end

---Takes arbitrary number of numbers and adds them in mod 32
---@param ... number
---@return number
function utils.add32(...)
    local sum = 0
    for _, number in ipairs(arg) do
        sum = sum + number
    end

    return sum % 2^32
end

return utils