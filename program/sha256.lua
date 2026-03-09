local utils = require("utils")

local K = {

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
        local word = bit32.bor(bit32.lshift(chunk[i], 24), bit32.lshift(chunk[i+1], 16), bit32.lshift(chunk[i+2], 6), chunk[i+3])
        table.insert(schedule, word)
    end 

    for i = 1, 48 do
        schedule[i+16] = 0
    end

    return schedule
end

local function chunk_loop(chunk, hash_values)
    local message_schedule = message_schedule(chunk)

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