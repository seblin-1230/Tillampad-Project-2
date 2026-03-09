local utils = require("utils")

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function pad(message, pad)
    for i = 1, pad do
        table.insert(message, 0)
    end
end

local function generate_message_block(message)
    local message_block = {}
    local message_length = 0
    for i = 1, #message do
        table.insert(message_block, string.byte(message, i))
        message_length = message_length + 8
    end
    table.insert(message_block, 0x80)

    local pad_by = (64 - #message_block % 64) - 8
    pad(message_block, pad_by)

---@diagnostic disable-next-line: deprecated
    local len_bits = string.pack(">I8", message_length)
    for i = 1, 8 do
        table.insert(message_block, string.byte(len_bits, i))
    end

    return message_block
end

local function message_schedule(chunk)
    local schedule = {}
    for i = 1, #chunk, 4 do
        local word = bit32.bor(bit32.lshift(chunk[i], 24), bit32.lshift(chunk[i+1], 16), bit32.lshift(chunk[i+2], 8), chunk[i+3])
        table.insert(schedule, word)
    end 

    for i = 1, 48 do
        schedule[i+16] = 0
    end

    return schedule
end

local function chunk_loop(chunk, hash_values)
    local words = message_schedule(chunk)

    for i = 16, 64 do
        local o0 = bit32.bxor(bit32.rrotate(words[i-14], 7), bit32.rrotate(words[i-14], 18), bit32.rrotate(words[i-14], 3))
        local o1 = bit32.bxor(bit32.rrotate(words[i-2], 17), bit32.rrotate(words[i-2], 19), bit32.rrotate(words[i-2], 10))

        words[i] = utils.add32(words[i-15], o0, words[i-7], o1)
    end

    return 
end

local function hash(message)
    local message_block = generate_message_block(message)
    
    local hash_values = {
        0x6a09e667,
        0xbb67ae85,
        0x3c6ef372,
        0xa54ff53a,
        0x510e527f,
        0x9b05688c,
        0x1f83d9ab,
        0x5be0cd19,
    }

    for i = 1, #message_block, 64 do
        local chunk = {table.unpack(message_block, i, i+63)}

        hash_values = chunk_loop(chunk, hash_values)
        if i == 1 then utils.print_table_as_hex(hash_values, 4) end
    end

end

return {hash = hash}