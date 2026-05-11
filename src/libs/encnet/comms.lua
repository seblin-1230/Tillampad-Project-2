local comms    = {}

local chacha20 = require("libs.encryption.chacha20")


local session_key
local protocol

---Parse an encrypted payload into its components
---@param payload string
---@return number computer_id
---@return string payload_type
---@return table data
local function parse_payload(payload)
    local nonce = payload:sub(1, 12)
    local payload_type = payload:sub(13, 20)
    local sender = payload:sub(21, 24):byte(1, 4)

    local payload_data = chacha20.crypt(payload:sub(25, #payload), session_key, nonce)


    local lengths = {}
    local current_char = ""
    local i = 1
    while current_char:byte() ~= 0 do
        current_char = payload_data:sub(i)

        lengths[i] = string.byte(current_char)
        i = i + 1
    end

    local offset = 0
    local data = {}
    for j, length in ipairs(lengths) do
        data[j] = payload_data:sub(i + offset, i + offset + length - 1)
        offset = offset + length
    end

    return sender, payload_type, data
end

---Build a payload from data
---@param payload_type string
---@param ... nil|boolean|number|string The data
---@return string
local function build_payload(payload_type, ...)
    LOGGER:info("Building payload with type " .. payload_type)
    if #payload_type ~= 8 then
        error("Type not 8 character long")
    end

    local n = select("#", ...)

    local str_table = {}
    local length_table = {}
    for i = 1, n do
        str_table[i] = tostring(select(i, ...))
        length_table[i] = string.char(#str_table[i])
    end
    local payload_data = table.concat(length_table) .. "\00" .. table.concat(str_table)

    local encrypted_payload, nonce = chacha20.crypt(payload_data, session_key)

    local id = os.computerID()
    local id_string = string.char(bit32.extract(id, 0, 8), bit32.extract(id, 8, 8), bit32.extract(id, 16, 8), bit32.extract(id, 24, 8))

    return nonce .. payload_type .. id_string .. encrypted_payload
end

---Open a modem for communication, also set the session key
---@param modem string
---@param new_session_key string
function comms.open(modem, new_session_key, new_protocol)
    rednet.open(modem)
    session_key = new_session_key
    protocol = new_protocol
end

---Close a modem also sets the session key to nil
---@param modem string
function comms.close(modem)
    rednet.close(modem)
    session_key = nil
    protocol = nil
end

---Send a payload to a computer with "reciver" id,
---@param recipient integer What computer id to send the payload to
---@param payload_type string The type of the payload, at most 8 characters
---@param ... any The data to encrypt and send
---@return boolean success If the send succeded, NOT if the payload was recived
function comms.send(recipient, payload_type, ...)
    local built_payload = build_payload(payload_type, ...)
    return rednet.send(recipient, built_payload, protocol)
end

---Broadcast a payload to all computers in the telenet
---@param payload_type string The type of the payload, at most 8 characters
---@param ... any The data to encrypt and broadcast
function comms.broadcast(payload_type, ...)
    local built_payload = build_payload(payload_type, ...)
    rednet.broadcast(built_payload, protocol)
end

---Revice a sent payload either from comms.send or comms.broadcast
---@param timeout? number How long to wait before timing out
---@return number? sender The id of the computer that sent the payload
---@return string? payload_type The payload type of the recived payload
---@return tablelib? data The decrypted recived data
function comms.receive(timeout)
    local sender, un_parsed_payload = rednet.receive(protocol, timeout)
    if not sender then return nil end

    local true_sender, payload_type, data = parse_payload(un_parsed_payload --[[@as string]])

    return true_sender, payload_type, data
end

---Check if a modem is open, identical ti rednet.isOpen
---@param modem string
---@return boolean
function comms.isOpen(modem)
    return rednet.isOpen(modem)
end

return comms
