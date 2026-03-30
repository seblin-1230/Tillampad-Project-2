local encnet = {}

local chacha20 = require("encryption.chacha20")
local crypto = require("encryption.crypto")
local sha256 = require("encryption.sha256")
local utils  = require("utils")


local session_key

local function parse_message(message)
    
end

local function build_message(message_type, message)
    if #message_type > 8 then
        error("Type to long, max 8 chars")
    end

    local encrypted_payload, nonce = chacha20.crypt(message, session_key)

    local id = os.computerID()
    local id_table = {}
    for i = 0, 3 do
        id_table[i+1] = string.char(bit32.extract(id, i*8, 8))
    end
    local id_string = table.concat(id_table)
    
    return nonce .. message_type .. id_string .. encrypted_payload
end

function encnet.open(modem, new_session_key)
    rednet.open(modem)
    session_key = new_session_key
end

function encnet.close(modem)
    rednet.close(modem)
    session_key = nil
end

function encnet.isOpen(modem)
    return rednet.isOpen(modem)
end

function encnet.send(recipient, message_type, message, protocol)
    local built_message = build_message(message_type, message)
    return rednet.send(recipient, built_message, protocol)
end

function encnet.broadcast(message_type, message, protocol)
    local built_message = build_message(message_type, message)
    return rednet.broadcast(built_message, protocol)
end

function encnet.receive()
    
end

return encnet