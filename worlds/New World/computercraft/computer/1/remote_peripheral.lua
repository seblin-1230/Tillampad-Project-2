-- Persistant variables
local NETWORK_ID = settings.get("network_id.setting")
local DEVICE_ID = settings.get("device_id.setting")
local PERIPHERAL_SIDE = settings.get("side.setting")
local PERIPHERAL_TYPE = settings.get("type.setting")
local KEY = settings.get("key.setting")


-- General variables
local modem = peripheral.find("modem")
local protocol = "peripheral_network_" .. tostring(NETWORK_ID)
-- local response_protocol = "peripheral_network_" .. tostring(NETWORK_ID) .. "device_" .. DEVICE_ID


function callFunction(func, arguments)
    local args_len = #arguments

    -- Allow for arbitary amount of outputs
    local outputs

    -- Allow for calls with up to 7 arguments
    if args_len == 0 then peripheral.call(PERIPHERAL_SIDE, func) 
    elseif args_len == 1 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1])}
    elseif args_len == 2 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2])}
    elseif args_len == 3 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2], arguments[3])}
    elseif args_len == 4 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2], arguments[3], arguments[4])}
    elseif args_len == 5 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2], arguments[3], arguments[4], arguments[5])}
    -- elseif args_len == 6 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6])}
    -- elseif args_len == 7 then outputs = {peripheral.call(PERIPHERAL_SIDE, func, arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7])}
    end

    return outputs
end


-- Script starts here
rednet.open(peripheral.getName(modem))
rednet.host(protocol, DEVICE_ID)

print("Network id: " .. tostring(NETWORK_ID))
print("Device id: " .. DEVICE_ID)
print("Peripheral side: " .. PERIPHERAL_SIDE)
print("Peripheral type: " .. PERIPHERAL_TYPE)
print("Protocol: " .. protocol)

while true do
    local id, message = rednet.receive(protocol)
    local func, args, call_type = message.func, message.args, message.call_type

    if call_type == "function" then
        local outputs = callFunction(func, args)

        rednet.send(id, outputs, protocol)
    else 
        if args == PERIPHERAL_TYPE then rednet.send(id, DEVICE_ID, protocol .. "_find_response") end
    end
end