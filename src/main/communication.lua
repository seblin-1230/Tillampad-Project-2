local function handle_communication(master_key)
    local new_station = require("main.new_station")
    local session_key_module = require("main.session_key_module")
    local teleport = require("main.teleport")

    local function_table = {
        TeleInit = teleport.initiate,
        TeleVeri = teleport.verification,
        TeleDeni = teleport.denied,
        TeleDone = teleport.done,
        TeleWait = teleport.wait,
        TeleQueu = teleport.queue,
        SeKeyReq = session_key_module.request,
        SeKeyRes = session_key_module.response,
        ClearMas = session_key_module.clear_master,
        NewStati = new_station.new_station,
        NewSVeri = new_station.verification,
        NewNeigh = new_station.new_neighbour,
    }

    encnet.open("left", master_key)

    while true do
        local sender, message_type, payload = assert(encnet.receive())

        if not ready and not (message_type == "SeKeyReq" or message_type == "SeKeyRes" or message_type == "ClearMas") then
            
        end

        LOGGER:info("Comm recived; Type: " .. message_type)
        os.queueEvent(message_type, sender, payload)
        local sucess = function_table[message_type](sender, payload, true)


        if not sucess then
            LOGGER:error(string.format("Invalid comm; sender: %d; message type: %s; payload: %s", sender, message_type,
                textutils.serialise(payload)))
        end

        ::continue::
    end
end

local function ready(session_key)
    
end

local function wait_for(payload_type, sender, timeout)
    -- LOGGER:info("Wait for called, type: " .. payload_type)
    local sucess = true

    if timeout ~= nil then
        parallel.waitForAny(
            function()
                repeat
                    local event, fn_sender, payload = os.pullEvent(payload_type)
                    if sender == nil then sender = fn_sender end
                until fn_sender == sender
            end,
            function()
                os.sleep(timeout)
                sucess = false
            end
        )
    else
        repeat
            local event, fn_sender, payload = os.pullEvent(payload_type)
            LOGGER:info(payload_type .. " recived")
            if sender == nil then sender = fn_sender end
        until fn_sender == sender
    end

    return sucess
end

return { Handle_communication = handle_communication, wait_for = wait_for }
