local chunkloader = peripheral.find("chunkloader")
-- Wake control
chunkloader.setWakeOnWorldLoad(true) -- Auto-resume on server restart

-- Turtle identification
print("ID: " .. chunkloader.getTurtleIdString())         -- Get unique turtle ID for remote management

local id_file = fs.open("id.txt", "w")

id_file.write(chunkloader.getTurtleIdString())
id_file.close()