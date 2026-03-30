local verify = require("verify")
local utils = require("utils")
local crypto = require("encryption.crypto")
local sha256 = require("encryption.sha256")

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



local id = settings.get("computer_id")

if id ~= os.getComputerID() then
    malware()
else
    term.clear()
    term.setCursorPos(1, 1)

    wait_for_master_disk()

    _G.encnet = require("encnet.encnet")
    shell.run("src/main.lua")
end