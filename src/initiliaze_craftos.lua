periphemu.create("left", "modem")
periphemu.create("right", "drive")

local drive = peripheral.wrap("right")

periphemu.create(tostring(os.computerID() + 1), "computer")

settings.set("computer_id", os.computerID())
settings.save()

parallel.waitForAll(
    function()
        shell.run("src/startup.lua")
    end,
    function()
        repeat
            local event, key, is_held = os.pullEvent("key")
        until key == keys.f3
        drive.insertDisk(2)
    end
)