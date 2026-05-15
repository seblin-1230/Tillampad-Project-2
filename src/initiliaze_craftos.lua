periphemu.create("left", "modem")

if os.computerID() ~= 3 then
    periphemu.create(tostring(os.computerID() + 1), "computer")
end

settings.set("computer_id", os.computerID())
settings.save()
shell.run("src/startup.lua")