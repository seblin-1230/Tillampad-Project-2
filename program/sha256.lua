local utils = require("utils")

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

local function hash(message)
    local message_block = generate_message_block(message)
    
    for i = 1, #message_block, 64 do
        local chunk = {table.unpack(message_block, i, i+63)}

        
    end

end

return {hash = hash}