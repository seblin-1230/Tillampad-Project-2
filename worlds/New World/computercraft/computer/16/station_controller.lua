local hostname = "station_controller"

local disk_drive = assert(peripheral.find("drive"), "No drive connected")

rednet.open("top")

disk_drive.setDiskLabel("Stations")

local stations = {}

local function read_station_file()
    local stations_file = assert(fs.open(disk_drive.getMountPath() .. "/stations", "r"))
    stations = textutils.unserialise(stations_file.read() --[[@as string]]) --[[@as table]]  or {}
    stations_file.close()
end

local function write_station_file()
    local stations_file = assert(fs.open(disk_drive.getMountPath() .. "/stations", "w"))
    stations_file.write(textutils.serialise(stations))
    stations_file.close()
end

local function handle_station_add()
    rednet.host("add station", hostname)

    while true do
        local station_data
        repeat
            local id, message = rednet.receive("add station")
            if stations[id] == nil then
                station_data = message --[[@as table]]
            end
        until stations[id] == nil

        print("Recived add request, data: " .. textutils.serialise(station_data))
    end
end

local function handle_station_requests()
    repeat
        sleep(0.5)
    until false
end

read_station_file()

parallel.waitForAny(handle_station_add, handle_station_requests)