local k = { 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 }

-- Source - https://stackoverflow.com/a/9080080
-- Posted by jpjacobs, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-02-17, License - CC BY-SA 3.0
---Convert decimal to big edian binary
---@param num number
---@param bits? number
---@return string
local function toBits(num, bits)
    -- returns a table of bits, most significant first.
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {} -- will contain the bits
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    return table.concat(t)
end

---Adds 32 bit integers
---@param ... unknown
---@return integer
local function add32(...)
    local sum = 0
    for i = 1, select("#", ...) do
        sum = sum + select(i, ...)
    end
    return bit32.band(sum, 0xFFFFFFFF)
end

---Hash the input data with sha256
---@param input_data string
local function hash(input_data)
    -- Prepare the data
    local message_block = ""
    for character in string.gmatch(tostring(input_data), ".") do
        message_block = message_block .. toBits(string.byte(character), 8)
    end

    local original_bit_length = #tostring(input_data) * 8
    local length_chunk = toBits(original_bit_length, 64)

    message_block = message_block .. "1"
    for i = 1, 512 - message_block:len() % 512 - 64 do
        message_block = message_block .. "0"
    end

    message_block = message_block .. length_chunk

    -- Chunk loop
    local hash_values = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 }

    for chunk_i = 1, message_block:len(), 512 do
        local chunk = message_block:sub(chunk_i, chunk_i + 511)
        local w = {}
        for i = 1, chunk:len(), 32 do
            table.insert(w, chunk:sub(i, i + 31))
        end

        for i = 1, 48 do
            table.insert(w, "00000000000000000000000000000000")
        end

        for i = 17, 64 do
            local w1 = tonumber(w[i - 15], 2)
            local o0 = bit32.bxor(bit32.rrotate(w1, 7), bit32.rrotate(w1, 18), bit32.rshift(w1, 3))

            local w14 = tonumber(w[i - 2], 2)
            local o1 = bit32.bxor(bit32.rrotate(w14, 17), bit32.rrotate(w14, 19), bit32.rshift(w14, 10))

            w[i] = toBits(add32(tonumber(w[i - 16], 2), o0, tonumber(w[i - 7], 2), o1), 32)
        end

        local a, b, c, d, e, f, g, h = hash_values[1], hash_values[2], hash_values[3], hash_values[4], hash_values[5],
            hash_values[6], hash_values[7], hash_values[8]

        print("i: " .. tostring(0) .. " variables: ", toBits(a, 32), toBits(b, 32), toBits(c, 32), toBits(d, 32),
            toBits(e, 32), toBits(f, 32), toBits(g, 32), toBits(h, 32))

        for i = 1, 64 do
            local S0 = bit32.bxor(
                bit32.rrotate(a, 2),
                bit32.rrotate(a, 13),
                bit32.rrotate(a, 22)
            )
            local S1 = bit32.bxor(
                bit32.rrotate(e, 6),
                bit32.rrotate(e, 11),
                bit32.rrotate(e, 25)
            )

            local choice = bit32.bxor(
                bit32.band(e, f),
                bit32.band(
                    bit32.bnot(e),
                    g
                )
            )
            local majority = bit32.bxor(
                bit32.band(a, b),
                bit32.band(a, c),
                bit32.band(b, c)
            )

            local temp1 = add32(h, S1, choice, tonumber(w[i], 2), k[i])
            local temp2 = add32(S0, majority)

            h = g
            g = f
            f = e
            e = add32(d, temp1)
            d = c
            c = b
            b = a
            a = add32(temp1, temp2)
            print("i: " .. tostring(i) .. " variables: ", toBits(a, 32), toBits(b, 32), toBits(c, 32), toBits(d, 32),
                toBits(e, 32), toBits(f, 32), toBits(g, 32), toBits(h, 32))
        end

        hash_values[1] = add32(hash_values[1], a)
        hash_values[2] = add32(hash_values[2], b)
        hash_values[3] = add32(hash_values[3], c)
        hash_values[4] = add32(hash_values[4], d)
        hash_values[5] = add32(hash_values[5], e)
        hash_values[6] = add32(hash_values[6], f)
        hash_values[7] = add32(hash_values[7], g)
        hash_values[8] = add32(hash_values[8], h)
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", hash_values[1], hash_values[2], hash_values[3],
        hash_values[4], hash_values[5], hash_values[6], hash_values[7], hash_values[8])
end

return { hash = hash }