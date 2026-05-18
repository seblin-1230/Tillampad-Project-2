local verify = require("helpers.verify")
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

    goto skip
    repeat
        local event, side = os.pullEvent("disk")

        local passed, reason = verify.master_disk(side)

        if not passed then
            print(reason)
        end
    until passed

    ::skip::
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

    -- Potential vonerability
    -- Since the master disk verification is run before the station verification
    -- An attacker could modify the staition to send the master disk identity to another computer
    -- Before the station has been verified
    -- Solutions:
    -- Have a physical protocol to change master identity when this happens
    local id = shell.openTab("shell")
    print("Press f1 to continue, press f2 to interupt")

    local event, key, is_held = os.pullEvent("key")
    
    shell.switchTab(id)
    shell.exit()

    logger:new({station_id = read_this_station_id()})
    _G.encnet = require("libs.encnet.comms")
    
    local mt = getmetatable(vector.new(0, 0, 0))
    mt.__tostring = function (self)
        return ("v%s,%s,%s"):format(self.x, self.y, self.z)
    end

    shell.run("src/main.lua")
end