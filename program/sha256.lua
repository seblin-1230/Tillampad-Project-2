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
        table.insert(message_block, string.byte(string.sub(message, i)))
        message_length = message_length + 8
    end
    table.insert(message_block, 1)

    local pad_by = (64 - #message_block % 64) - 8
    pad(message_block, pad_by)

    utils.print_table_as_hex(message_block, 2)
end

local function hash(message)
    local message_block = generate_message_block(message)
end

return {hash = hash}