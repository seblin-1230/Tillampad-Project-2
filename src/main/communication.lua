local new_station = require("main.new_station")
local session_key = require("main.session_key")
local teleport = require("main.teleport")

local function_table = {
    TeleInit = teleport.initiate,
    TeleVeri = teleport.verification,
    TeleDeni = teleport.denied,
    TeleDone = teleport.done,
    SeKeyReq = session_key.request,
    SeKeyRes = session_key.response,
    ClearMas = session_key.clear_master,
    NewStati = new_station.new_station,
    NewSVeri = new_station.verification,
    NewNeigh = new_station.new_neighbour
}

function Handle_communication(session_key)
    encnet.open("left", session_key)

    while true do
        local sender, message_type, payload = assert(encnet.receive())

        LOGGER:info("Comm recived; Type: " .. message_type)
        local sucess = function_table[message_type](sender, payload, true)

        if not sucess then
            LOGGER:error(string.format("Invalid comm; sender: %d; message type: %s; payload: %s", sender, message_type, textutils.serialise(payload)))
        end
    end
end

return Handle_communication