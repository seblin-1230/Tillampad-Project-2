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

---Convert an integer to a list of bytes, reverses bytes_to_int, adapted to (https://stackoverflow.com/questions/5241799/lua-dealing-with-non-ascii-byte-streams-byteorder-change)
---@param num integer
---@param endian "big"|"little"
---@param signed boolean
---@return table
function utils.int_to_bytes(num, endian, signed)
    if num < 0 and not signed then
        num = -num
        print "warning, dropping sign from number converting to unsigned"
    end
    local res = {}
    local n = math.ceil(select(2, math.frexp(num)) / 8) -- number of bytes to be used.
    if signed and num < 0 then
        num = num + 2 ^ n
    end
    for k = n, 1, -1 do -- 256 = 2^8 bits per char.
        local mul = 2 ^ (8 * (k - 1))
        res[k] = math.floor(num / mul)
        num = num - res[k] * mul
    end
    assert(num == 0)
    if endian == "big" then
        local t = {}
        for k = 1, n do
            t[k] = res[n - k + 1]
        end
        res = t
    end
    return res
end

---Convert an integer into a hex string padded by "pad" using 0s
---@param num number
---@param pad integer
---@return string
function utils.int_to_hex(num, pad)
    local format = string.format("%%0%dx", pad)
    return string.format(format, num)
end

---Reutrns a nonce, current implemention temporary until i implement better randomness TODO UPDATE TO USE NEW NONCE SYSTEM
---@return [number,number,number] nonce An array containing three 32 bit random numbers
function utils.generate_nonce()
    return { math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF) }
end

return utils