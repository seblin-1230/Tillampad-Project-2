local comms    = {}

local chacha20 = require("encryption.chacha20")
local crypto   = require("encryption.crypto")
local sha256   = require("encryption.sha256")
local utils    = require("utils")


local session_key

---Parse a comms message into normal content
---@param message string
local function parse_message(message)
    local nonce = message:sub(1, 12)
    local message_type = message:sub(13, 20)
    local sender = message:sub(21, 24):byte(1, 4)
    local payload = message:sub(25, #message)
    local decrypted = chacha20.crypt(payload, session_key, nonce)

    return sender, message_type, decrypted
end

local function build_message(message_type, message)
    if #message_type > 8 then
        error("Type to long, max 8 chars")
    end

    local encrypted_payload, nonce = chacha20.crypt(message, session_key)

    local id = os.computerID()
    local id_string = string.char(bit32.extract(id, 0, 8), bit32.extract(id, 8, 8), bit32.extract(id, 16, 8), bit32.extract(id, 24, 8))

    return nonce .. message_type .. id_string .. encrypted_payload
end

---Open a modem for communication, also set the session key
---@param modem string
---@param new_session_key string
function comms.open(modem, new_session_key)
    rednet.open(modem)
    session_key = new_session_key
end

---Close a modem also sets the session key to nil
---@param modem string
function comms.close(modem)
    rednet.close(modem)
    session_key = nil
end

---Send a message to a computer with "reciver" id,
---@param recipient integer What computer id to send the message to
---@param message_type string The type of the message, at most 8 characters
---@param message string The message to encrypt and send
---@param protocol? string The protocol the send the message on, can be nil
---@return boolean success If the send succeded, NOT if the message was recived
function comms.send(recipient, message_type, message, protocol)
    local built_message = build_message(message_type, message)
    return rednet.send(recipient, built_message, protocol)
end

---Broadcast a message to all computers along a specified protocol
---@param message_type string The type of the message, at most 8 characters
---@param message string The message to encrypt and broadcast
---@param protocol string The protocol to broadcast on
function comms.broadcast(message_type, message, protocol)
    local built_message = build_message(message_type, message)
    rednet.broadcast(built_message, protocol)
end

---Revice a sent message either from comms.send or comms.broadcast
---@param protocol_filter? string The protocol to filter all messages to
---@param timeout? number How long to wait before timing out
---@return number? sender The id of the computer that sent the message
---@return string? message_type The message type of the recived message
---@return string? payload The decrypted recived payload
---@return string? protocol The protocol the message was sent under
function comms.receive(protocol_filter, timeout)
    local sender, message, protocol = rednet.receive(protocol_filter, timeout)
    if not sender then return nil end

    local true_sender, message_type, payload = parse_message(message --[[@as string]])
    return true_sender, message_type, payload, protocol
end

---Check if a modem is open, identical ti rednet.isOpen
---@param modem string
---@return boolean
function comms.isOpen(modem)
    return rednet.isOpen(modem)
end

---Host a protocol, identical to rednet.host
---@param protocol string The protocol to host
---@param hostname string The name to host with
function comms.host(protocol, hostname)
    rednet.host(protocol, hostname)
end

---Stop hosting a protocol, identical to rednet.host
---@param protocol string The protocol the stop hosting
function comms.unhost(protocol)
    rednet.unhost(protocol)
end

---Find computers hosting the specified protocol, can filter for hostname, identical to rednet.lookup
---@param protocol string The protocol to lookup
---@param hostname string The hostname to filter by
function comms.lookup(protocol, hostname)
    rednet.lookup(protocol, hostname)
end

return comms
