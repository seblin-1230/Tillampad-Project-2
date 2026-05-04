local communication = require("main.communication")

local sha256 = require("libs.encryption.sha256")
local logger = require("main.logger")
local encnet = require("libs.encnet.comms")
local utils  = require("libs.utils")


local session_key = "aVUD5IqcE6E27lVRlByso9tN1IQC3Sdn"
encnet.open("left", session_key)

if os.computerID() == 0 then
    encnet.send(1, "JustTemp", nil, "Hello", false, 100)
else
    local sender, payload_type, _, str, bool, num = encnet.receive()
    local true_bool = utils.string_to_bool(bool)
    
    print(str, bool, num)
    sleep(10)
end
