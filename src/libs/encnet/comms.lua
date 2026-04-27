local comms    = {}

local chacha20 = require("libs.encryption.chacha20")


local session_key

---Parse a comms payload into normal content
---@param payload string
local function parse_payload(payload)
    local nonce = payload:sub(1, 12)
    local payload_type = payload:sub(13, 20)
    local sender = payload:sub(21, 24):byte(1, 4)
    local payload = payload:sub(25, #payload)
    local decrypted = chacha20.crypt(payload, session_key, nonce)

    return sender, payload_type, decrypted
end

local function build_payload(payload_type, payload)
    if #payload_type > 8 then
        error("Type to long, max 8 chars")
    end

    local tabled_payload = {}
    if type(payload) ~= "table" then
        if type(payload) == "function" then error("Can not send unserialiseable objects") end

        table.insert(tabled_payload, payload)
    else
        tabled_payload = payload
    end

    local encrypted_payload, nonce = chacha20.crypt(textutils.serialise(tabled_payload), session_key)

    local id = os.computerID()
    local id_string = string.char(bit32.extract(id, 0, 8), bit32.extract(id, 8, 8), bit32.extract(id, 16, 8), bit32.extract(id, 24, 8))

    return nonce .. payload_type .. id_string .. encrypted_payload
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

---Send a payload to a computer with "reciver" id,
---@param recipient integer What computer id to send the payload to
---@param payload_type string The type of the payload, at most 8 characters
---@param payload any The payload to encrypt and send
---@param protocol? string The protocol the send the payload on, can be nil
---@return boolean success If the send succeded, NOT if the payload was recived
function comms.send(recipient, payload_type, payload, protocol)
    local built_payload = build_payload(payload_type, payload)
    return rednet.send(recipient, built_payload, protocol)
end

---Broadcast a payload to all computers along a specified protocol
---@param payload_type string The type of the payload, at most 8 characters
---@param payload any The payload to encrypt and broadcast
---@param protocol string The protocol to broadcast on
function comms.broadcast(payload_type, payload, protocol)
    local built_payload = build_payload(payload_type, payload)
    rednet.broadcast(built_payload, protocol)
end

---Revice a sent payload either from comms.send or comms.broadcast
---@param protocol_filter? string The protocol to filter all payloads to
---@param timeout? number How long to wait before timing out
---@return number? sender The id of the computer that sent the payload
---@return string? payload_type The payload type of the recived payload
---@return table? payload The decrypted recived payload
---@return string? protocol The protocol the payload was sent under
function comms.receive(protocol_filter, timeout)
    local sender, un_parsed_payload, protocol = rednet.receive(protocol_filter, timeout)
    if not sender then return nil end

    local true_sender, payload_type, payload = parse_payload(un_parsed_payload --[[@as string]])

    local un_serialised_payload = textutils.unserialise(payload)

    return true_sender, payload_type, un_serialised_payload, protocol
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
