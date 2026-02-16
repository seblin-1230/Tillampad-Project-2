local NETWORK_ID = settings.get("network_id.setting")
local DEVICE_ID = "controller"

-- Other variables
local params = {...}
local modem = peripheral.find("modem")
local protocol = "peripheral_network_" .. tostring(NETWORK_ID)

rednet.open(peripheral.getName(modem))
rednet.host(protocol, DEVICE_ID)

-- Functions
function findRemote(type) 
    rednet.broadcast({
        call_type = "type",
        args = type,
        func = nil
    }, protocol)

    local device_ids = {}
    while true do
        local not_failed, message = rednet.receive(protocol .. "_find_response", 1)
        if not_failed == nil then break end
        table.insert(device_ids, message)
    end

    return device_ids
end

function callRemote(device_name, func, arg1, arg2, arg3, arg4, arg5)
    arg1 = arg1 or nil
    arg2 = arg2 or nil
    arg3 = arg3 or nil
    arg4 = arg4 or nil
    arg5 = arg5 or nil

    local send_id = rednet.lookup(protocol, device_name)
    

    local payload = {
        func = func,
        args = {arg1, arg2, arg3, arg4, arg5},
        call_type = "function"
    }
    
    print(string.format("Sending %s to device %s", textutils.serialise(payload), device_name))
    rednet.send(send_id, payload, protocol)

    local id, message
    repeat
        id, message = rednet.receive(protocol)
        print(string.format("Received message from id %d with message %s", id, textutils.serialise(message)))
    until id == send_id
    return table.unpack(message.outputs)
end

function help()
    term.clear()
    term.setCursorPos(1, 1)

    print("Network ID: " .. tostring(NETWORK_ID))

    textutils.pagedPrint("\nTo use this module add require(remote_controller) to your program. To call a function on a peripheral use callRemote(device_name, function, arg1, arg2, arg3, arg4, arg5). device_name is the name you gave to the peripheral during the setup, function is the name of the function you want to call AS A STRING, arg1-5 are all optional and allow you to pass arguments to the function call. callRemote() returns up to 7 outputs. If you don't remember the device name you set you can use findRemote(type) to the names of every remote peripheral of a certain type or go to the computer hosting the peripheral program as it will say there. To see this again run \"peripheral_controller.lua help\"")
end

if (params[1] == "help") or (params[1] == "h") then
    help()
end