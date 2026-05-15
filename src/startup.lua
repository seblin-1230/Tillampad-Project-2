local verify = require("verify")
local csv    = require("libs.csv")
local logger = require("main.logger")
local utils  = require("libs.utils")
local crypto = require("libs.encryption.crypto")
local sha256 = require("libs.encryption.sha256")

-- os.pullEvent = utils.pullEventOverride

local function malware()
    settings.set("shell.allow_disk_startup", false)

    settings.set("computer_id", os.getComputerID())

    local startup_file = fs.open("startup.lua", "w")

    startup_file.write([[
        os.pullEvent = nil
        os.pullEventRaw = nil
        os.shutdown()
    ]])
    

    os.reboot()
end

local function wait_for_master_disk()
    term.setTextColor(colors.orange)
    print("This station is waiting for an admin to insert the master disk")
    term.setTextColor(colors.red)

    goto testing_skip
    repeat
        local event, side = os.pullEvent("disk")

        local passed, reason = verify.master_disk(side)

        if not passed then
            print(reason)
        end
    until passed
    ::testing_skip::
end


---Get the data for this station
---@return number
local function read_this_station_id()
    local unformated_station = csv.read_file("src/data/individual_stations/station_" .. tostring(os.computerID()) .. ".csv")[1]

    return unformated_station[1]
end

local id = settings.get("computer_id")

if id ~= os.getComputerID() then
    malware()
else
    term.clear()
    term.setCursorPos(1, 1)

    wait_for_master_disk()

    logger:new({station_id = read_this_station_id()})
    _G.encnet = require("libs.encnet.comms")
    
    local mt = getmetatable(vector.new(0, 0, 0))
    mt.__tostring = function (self)
        return ("v%s,%s,%s"):format(self.x, self.y, self.z)
    end
    -- shell.run("src/main.lua")
end