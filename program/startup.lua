local verify = require("verify")
local utils = require("utils")

-- os.pullEvent = utils.pullEventOverride

local function wait_for_master_disk()
    term.setTextColor(colors.orange)
    print("This station is waiting for an admin to insert the master disk")
    term.setTextColor(colors.red)

    repeat
        local event, side = os.pullEvent("disk")

        local passed, reason = verify.master_disk(side)

        if not passed then
            print(reason)
        end
    until passed

    term.setTextColor(colors.green)
    print("Check passed")
end

term.clear()
term.setCursorPos(1, 1)

wait_for_master_disk()
