local utils = require("utils")

local function generate_message_block(message)
    local message_block = {}
    for i = 1, #message do
        table.insert(message_block, string.byte(string.sub(message, i)))
    end

end

local function hash(message)
    local message_block = generate_message_block(message)
end


return {hash = hash}