local comms    = {}

local chacha20 = require("libs.encryption.chacha20")


local session_key

local function serialise(obj)
    local objType = type(obj)

    local output

    if objType == "number" then
        output = tostring(obj)
    end
end

---Parse an encrypted payload into its components
---@param payload string
---@return number computer_id
---@return string payload_type
---@return table data
local function parse_payload(payload)
    print("Parsing")
    local nonce = payload:sub(1, 12)
    local payload_type = payload:sub(13, 20)
    local sender = payload:sub(21, 24):byte(1, 4)

    local payload_data = chacha20.crypt(payload:sub(25, #payload), session_key, nonce)

    local lengths = {}
    local current_char = ""
    local i = 1
    LOGGER:info(table.concat({payload_data:byte(1, #payload_data)}, ","))
    while current_char:byte() ~= 0 do
        current_char = payload_data:sub(i)
        LOGGER:info(current_char:byte())

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
    print("Not encrypted payload data: ", payload_data)
    
    local encrypted_payload, nonce = chacha20.crypt(payload_data, session_key)

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
---@param protocol? string The protocol the send the payload on, can be nil
---@param ... any The data to encrypt and send
---@return boolean success If the send succeded, NOT if the payload was recived
function comms.send(recipient, payload_type, protocol, ...)
    local built_payload = build_payload(payload_type, ...)
    print("sending: ", built_payload)
    return rednet.send(recipient, built_payload, protocol)
end

---Broadcast a payload to all computers along a specified protocol
---@param payload_type string The type of the payload, at most 8 characters
---@param protocol string The protocol to broadcast on
---@param ... any The data to encrypt and broadcast
function comms.broadcast(payload_type, protocol, ...)
    local built_payload = build_payload(payload_type, ...)
    rednet.broadcast(built_payload, protocol)
end

---Revice a sent payload either from comms.send or comms.broadcast
---@param protocol_filter? string The protocol to filter all payloads to
---@param timeout? number How long to wait before timing out
---@return number? sender The id of the computer that sent the payload
---@return string? payload_type The payload type of the recived payload
---@return string? protocol The protocol the payload was sent under
---@return ... The decrypted recived data
function comms.receive(protocol_filter, timeout)
    print("Reciving")
    local sender, un_parsed_payload, protocol = rednet.receive(protocol_filter, timeout)
    if not sender then return nil end

    local true_sender, payload_type, data = parse_payload(un_parsed_payload --[[@as string]])


    return true_sender, payload_type, protocol, table.unpack(data)
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
