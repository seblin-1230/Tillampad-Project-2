local encnet = {}

local chacha20 = require("encryption.chacha20")
local crypto = require("encryption.crypto")
local sha256 = require("encryption.sha256")
local utils  = require("utils")


local session_key

local function parse_message(message)
    
end

local function build_message(type, message)
    if #type > 8 then
        error("Type to long, max 8 chars")
    end

    local encrypted_payload, nonce = chacha20.crypt(message, session_key)

    local id = os.computerID()
    local id_table = {}
    for i = 0, 9 do
        id_table[i+1] = bit32.extract(id, i*8, 8)
    end
    local id_string = table.concat(id_table)
    print(id_string)
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

function encnet.send(recipient, type, message, protocol)
    local built_message = build_message(type, message)
    return rednet.send(recipient, built_message, protocol)
end

return encnet