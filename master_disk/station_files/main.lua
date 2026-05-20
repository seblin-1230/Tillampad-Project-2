---@alias Station {computer_id: integer, station_id: integer, position: ccTweaked.Vector, name: string, description: string, neighbors: integer[], next_station: integer, unsafe: boolean}

local sha256        = require("libs.encryption.sha256")
local crypto        = require("libs.encryption.crypto")
local utils         = require("libs.utils")
local strings       = require("cc.strings")
local csv           = require("libs.csv")
local teleport      = require("main.teleport")
local verify        = require("helpers.verify")

local communication = require("main.communication")

local modem         = peripheral.find("modem")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count + 1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end

---Convert the raw csv reader output to station data
---@param raw table
---@return Station station
local function format_station(raw)
    local station_info = {
        computer_id = raw[2],
        station_id = raw[1],
        position = vector.new(raw[3], raw[4], raw[5]),
        name = raw[6],
        description = raw[7],
        next_station = tonumber(raw[9]),
        unsafe = false
    }

    local neighbors = {}
    for str in string.gmatch(raw[8], "[^:]+") do
        table.insert(neighbors, tonumber(str))
    end

    station_info.neighbors = neighbors

    return station_info
end

---Get all the stations saved to file
---@return Station[]
---@return integer[]
local function read_stations()
    local unformated_stations = csv.read_file("data/stations.csv")

    local stations = {}
    local ordered_list = {}
    for i, unformated_station in ipairs(unformated_stations) do
        local station_info = format_station(unformated_station)

        setmetatable(station_info, {
            __tostring = function(s) return "Station<" .. s.station_id .. "," .. s.computer_id .. ">" end
        })

        stations[station_info.computer_id] = station_info
        ordered_list[i] = station_info.computer_id
    end

    setmetatable(stations, {
        __tostring = function(stations) return table.concat(stations, ", ") end
    })

    return stations, ordered_list
end

---Get the data for this station
---@return Station
local function read_this_station()
    local unformated_station = csv.read_file("data/individual_stations/station_" ..
        tostring(os.computerID()) .. ".csv")[1]

    local station_info = format_station(unformated_station)

    setmetatable(station_info, {
        __tostring = function(s) return "Station<" .. s.station_id .. "," .. s.computer_id .. ">" end
    })

    return station_info
end



local this_station = read_this_station()
local stations, ordered_stations = read_stations()
local session_key


local w, h = term.getSize()
local center_y = math.floor(h / 2)
local selected = 1
local selected_position = { 0, 0, 0 }

local header_height = 2
local footer_height = 2

local body_top = header_height + 1
local body_bottom = h - footer_height
local body_height = body_bottom - body_top + 1

-- local listHeight = listBottom - listTop + 1

local this_station_list_position = 0
for i, computer_id in pairs(ordered_stations) do
    if computer_id == this_station.computer_id then
        this_station_list_position = i
        break
    end
end
if this_station_list_position == nil then
    error("Not in station list")
end

_G.get_this_station = function()
    local info = debug.getinfo(2, "Sl")
    --LOGGER:info("This station accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)
    return this_station
end

_G.get_stations = function()
    local info = debug.getinfo(2, "Sl")
    --LOGGER:info("Station list accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)
    return stations
end

_G.get_station_ids = function()
    local info = debug.getinfo(2, "Sl")
    --LOGGER:info("Station ids accessed from " .. info.source:gsub("^@", "") .. ":" .. info.currentline)

    local ids = {}
    for i, station in pairs(stations) do
        ids[station.station_id] = true
    end

    return ids
end

_G.get_computer_id = function(station_id)
    local info = debug.getinfo(2, "Sl")
    --LOGGER:info("Computer id for station " ..
    --    tostring(station_id) .. " accessed from " .. info.source:gsub("^@", "" .. ":") .. info.currentline)

    for computer_id, station_info in pairs(stations) do
        if station_info.station_id == station_id then
            return computer_id
        end
    end
    return nil
end

_G.update_stations = function()
    this_station = read_this_station()
    stations, ordered_stations = read_stations()
end


_G.teleport_queue = {}
_G.in_teleport = false
_G.attempting_teleport_payload = nil
_G.route = {}
_G.ready = false


local function clear_line(y)
    term.setCursorPos(1, y)
    term.clearLine()
end

local function set_line_background(y, bg)
    local old_bg = term.getBackgroundColor()

    term.setCursorPos(1, y)
    term.setBackgroundColor(bg)
    term.clearLine()

    term.setBackgroundColor(old_bg)
end

local function get_station_interface_info(selection_id, extra_space)
    if extra_space == nil then extra_space = 0 end
    local station = stations[ordered_stations[selection_id]]

    if station == nil then
        return strings.ensure_width("")
    end

    local station_id = strings.ensure_width("Station " .. tostring(station.station_id), 12)
    local coordinates = strings.ensure_width("; " .. tostring(station.position):gsub("v", ""))
    local name = strings.ensure_width("; " .. station.name, 18)

    return strings.ensure_width(station_id .. name .. coordinates)
end

local function draw_header(page_name)
    -- Draw header
    --LOGGER:info("Drawing header")
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)

    clear_line(1)
    term.setTextColor(colors.purple)
    write(get_station_interface_info(this_station_list_position))
    clear_line(2)
    term.setTextColor(colors.white)
    print(strings.ensure_width(page_name))

    term.setBackgroundColor(colors.black)
end

local function draw_footer()
    term.setBackgroundColor(colors.gray)
    clear_line(h - 1)
    write(strings.ensure_width(strings.ensure_width("\24 or W: Up", w - 25) .. "ETR or SPC: Select", w - 1))

    clear_line(h)
    write(strings.ensure_width(strings.ensure_width("\25 or S: Down", w - 25) .. "Q: Back", w -1))
    term.setBackgroundColor(colors.black)
end

local function draw_station_interface()
    term.clear()
    term.setCursorPos(1, 1)

    draw_header("Station List:")

    -- Draw body
    --LOGGER:info("Drawing body")
    local max_visible = body_height
    local scroll_offset = selected - math.floor(max_visible / 2)

    scroll_offset = math.max(1, scroll_offset)

    local maxOffset = math.max(1, #ordered_stations - max_visible + 1)
    scroll_offset = math.min(scroll_offset, maxOffset)

    for i = 0, max_visible - 1 do
        local itemIndex = scroll_offset + i
        local screenY = body_top + i

        clear_line(screenY)

        if ordered_stations[itemIndex] then
            term.setCursorPos(2, screenY)

            if itemIndex == selected then
                term.setBackgroundColor(colors.white)
                term.setTextColor(colors.black)

                clear_line(screenY)
                term.setCursorPos(2, screenY)
                write("> " .. get_station_interface_info(itemIndex))

                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            else
                write("  " .. get_station_interface_info(itemIndex))
            end
        end
    end

    draw_footer()
end

local function draw_coordinate_interface()
    term.clear()
    term.setCursorPos(1, 1)

    draw_header("Coordinates:")

    clear_line(body_top)
    clear_line(body_top + 1)
    print("Please enter coordinates")

    if selected == 1 then
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        print("   X: " .. tostring(selected_position[1]))
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)

        print("   Y: " .. tostring(selected_position[2]))
        print("   Z: " .. tostring(selected_position[3]))
        print("  Teleport")
    elseif selected == 2 then
        print("   X: " .. tostring(selected_position[1]))

        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        print("   Y: " .. tostring(selected_position[2]))
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)

        print("   Z: " .. tostring(selected_position[3]))
        print("  Teleport")
    elseif selected == 3 then
        print("   X: " .. tostring(selected_position[1]))
        print("   Y: " .. tostring(selected_position[2]))

        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        print("   Z: " .. tostring(selected_position[3]))
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)

        print("  Teleport")
    elseif selected == 4 then
        print("   X: " .. tostring(selected_position[1]))
        print("   Y: " .. tostring(selected_position[2]))
        print("   Z: " .. tostring(selected_position[3]))

        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        print("  Teleport")
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end

    draw_footer()
end

local function draw_main_interface()
    draw_header("Main page")

    clear_line(body_top)
    local message =
    [[
Welcome to TeleNet!
TeleNet is a transportation network utilizing hexcasting to transport you almost anywhere (near) instantly!
TeleNet is also made to be completly secure. If a station has been modifed in any way you will not be teleported there.
Below please select where you want to teleport to!
]]
    print(message)

    local x, y = term.getCursorPos()

    if selected == 1 then
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)

        clear_line(y)
        write(" > Station")

        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)

        clear_line(y + 1)
        write("    Coordinates")
    else
        clear_line(y)
        write("    Station")

        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)

        clear_line(y + 1)
        write(" > Coordinates")

        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
    end



    draw_footer()
end

local function async_main()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)

    local current_interface = 1

    --LOGGER:info(textutils.serialise(ordered_stations, { compact = true }))

    local event, key
    while true do
        --LOGGER:info("Selected: " .. tostring(selected))
        if key == keys.q then
            current_interface = 1
            selected = 1
        end



        if current_interface == 1 then
            if key == keys.up or key == keys.w then
                selected = math.max(1, selected - 1)
            elseif key == keys.down or key == keys.s then
                selected = math.min(2, selected + 1)
            elseif key == keys.enter or key == keys.space then
                current_interface = selected + 1
                selected = 1
            end
        elseif current_interface == 2 then
            if key == keys.up or key == keys.w then
                selected = math.max(1, selected - 1)
            elseif key == keys.down or key == keys.s then
                selected = math.min(#ordered_stations, selected + 1)
            elseif key == keys.enter or key == keys.space then
                term.clear()
                term.setCursorPos(1, 1)
                term.setTextColor(colors.white)

                local selected_station = stations[ordered_stations[selected]]

                if selected == this_station_list_position then
                    print("Cannot teleport to this station, already here")
                else
                    print("Initiating teleport to " .. tostring(selected_station))
                    teleport.initiate(os.computerID(), { destination = selected_station }, false)
                end

                sleep(2)
                current_interface = 1
                selected = 1
            end
        elseif current_interface == 3 then
            if key == keys.up or key == keys.w then
                selected = math.max(1, selected - 1)
            elseif key == keys.down or key == keys.s then
                selected = math.min(4, selected + 1)
            elseif (key == keys.enter or key == keys.space) and selected ~= 4 then
                term.setBackgroundColor(colors.white)
                term.setTextColor(colors.black)

                while true do
                    set_line_background(body_top + 1 + selected, colors.white)

                    if selected == 1 then
                        write("   X: ")
                    elseif selected == 2 then
                        write("   Y: ")
                    elseif selected == 3 then
                        write("   Z: ")
                    end
                    local input = read(nil, nil, nil, tostring(selected_position[selected]))

                    if tonumber(input) then
                        selected_position[selected] = tonumber(input)
                        break
                    end
                end

                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            elseif (key == keys.enter or key == keys.space) and selected == 4 then
                teleport.initiate(os.computerID(),
                    { destination = vector.new(selected_position[1], selected_position[2], selected_position[3]) }, false)
                selected_position = { 0, 0, 0 }
                sleep(4)
                current_interface = 1
                selected = 1
            end
        else
            current_interface = 1
            selected = 1
        end

        term.clear()

        if current_interface == 1 then
            draw_main_interface()
        elseif current_interface == 2 then
            draw_station_interface()
        elseif current_interface == 3 then
            draw_coordinate_interface()
        end

        while true do
            event, key = os.pullEvent()

            if event == "key" or event == "tele_done" then
                break
            end
        end
    end
end

local function watch_disk()
    while true do
        local event, side = os.pullEvent("disk")

        local pass = verify.master_disk(side)
        if pass then
            local drive = assert(peripheral.wrap(side))
            local key_file = fs.open(fs.combine(drive.getMountPath(), "current_key.txt"), "w")
            key_file.write(session_key)
            key_file.close()
            drive.ejectDisk()
        end
    end
end

-- On startup
--LOGGER:info("Starting: " .. os.time("utc"))


term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.yellow)
print(tostring(this_station))
term.setTextColor(colors.white)

if select(1, ...) == nil then
    -- Step 1
    local last_station
    local y = 2

    while true do
        term.setCursorPos(1, y)
        term.clearLine()

        write("Last station (station id)? \n> ")
        local response = read()

        if response == "" or get_station_ids()[tonumber(response)] ~= nil then
            last_station = get_computer_id(tonumber(response))
            break
        else
            term.setCursorPos(1, 2)
            term.clearLine()

            printError("Not a valid station id")
            y = 2
        end
    end


    -- Step 2
    local key_file = assert(fs.open("disk/secret.txt", "r"))
    local master_key = key_file.readAll()
    key_file.close()

    if master_key == nil then
        error("No master key found in disk")
    end

    encnet.open(peripheral.getName(modem), master_key)

    if last_station == nil then
        session_key = generate_session_key()
        print("Session key generated")
    else
        print("Waiting for session key, to inturupt just restart station")

        encnet.send(last_station, "SeKeyReq")

        local sender, payload_type, data
        while payload_type ~= "SeKeyRes" or sender ~= last_station do
            sender, payload_type, data = encnet.receive()
        end

        session_key = data[1]
        print("Session key recived")
    end

    print(this_station.next_station)
    if this_station.next_station ~= -1 then
        print("Waiting for key request from " .. tostring(stations[this_station.next_station]))

        local sender, payload_type, data
        while payload_type ~= "SeKeyReq" do
            sender, payload_type, data = encnet.receive()
        end

        encnet.send(sender, "SeKeyRes", session_key)

        print("Request fullfiled, waiting for rest of network")

        local sender, payload_type, data
        while payload_type ~= "ClearMas" do
            sender, payload_type, data = encnet.receive()
        end
    else
        print("Broadcasting command to clear master key")
        encnet.broadcast("ClearMas")
    end

    session_key = "62133560569735363088340605897410"

    master_key = nil
    encnet.close(peripheral.getName(modem))
    encnet.open(peripheral.getName(modem), session_key)

    set_startup_session_key(session_key)
else
    session_key = select(1, ...)
end

parallel.waitForAll(
    function() communication.Handle_communication(session_key) end,
    async_main,
    watch_disk
)
