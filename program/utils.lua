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
    local args = {...}
    for _, number in ipairs(args) do
        sum = bit32.band((sum + number), 0xffffffff)
    end

    return sum
end

---Convert a string in to a integer based on its bytes, taken from (https://stackoverflow.com/questions/5241799/lua-dealing-with-non-ascii-byte-streams-byteorder-change)
---@param str string
---@param endian "big"|"little"
---@param signed boolean
---@return integer
function utils.bytes_to_int(str, endian, signed)
    local t = { str:byte(1, -1) }
    if endian == "big" then --reverse bytes
        local tt = {}
        for k = 1, #t do
            tt[#t - k + 1] = t[k]
        end
        t = tt
    end
    local n = 0
    for k = 1, #t do
        n = n + t[k] * 2 ^ ((k - 1) * 8)
    end
    if signed then
        n = (n > 2 ^ (#t * 8 - 1) - 1) and (n - 2 ^ (#t * 8)) or n -- if last bit set, negative.
    end
    return n
end

---Convert a 32 bit integer to a list of integers 0-255 (bytes)
---@param num integer
---@return table
function utils.bytes_from_int32(num)
    return {bit32.extract(num, 0, 8), bit32.extract(num, 8, 8), bit32.extract(num, 16, 8), bit32.extract(num, 24, 8)}
end

---Convert an integer into a hex string padded by "pad" using 0s
---@param num number
---@param pad integer
---@return string
function utils.int_to_hex(num, pad)
    local format = string.format("%%0%dx", pad)
    return string.format(format, num)
end

function utils.print_table_as_hex(raw_table, pad)
    local print_table = {}
    for _, value in ipairs(raw_table) do
        table.insert(print_table, utils.int_to_hex(value, pad))
    end
    textutils.pagedTabulate(print_table)
end

return utils