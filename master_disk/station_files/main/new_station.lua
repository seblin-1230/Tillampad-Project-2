local csv = require("libs.csv")
local new_station = {}

function new_station.new_station(sender, payload, external)
    csv.append_file("data/stations.csv", payload)

    local this_station = get_this_station()

    local existing_neighbors = {}
    for _, n in ipairs(this_station.neighbors) do
        if tonumber(n) ~= -1 then
            table.insert(existing_neighbors, n)
        end
    end
    local new_neighbours = table.concat(existing_neighbors, ":")

    for neighbor in string.gmatch(payload[8], "[^:]+") do
        if this_station.computer_id == tonumber(neighbor) then
            new_neighbours = table.concat(existing_neighbors, ":") .. ":" .. tostring(sender)
        end
    end

    local new_next_station = this_station.next_station
    if this_station.next_station == -1 then
        new_next_station = sender
    end

    local updated_row = {
        this_station.station_id,
        this_station.computer_id,
        this_station.position.x,
        this_station.position.y,
        this_station.position.z,
        this_station.name,
        this_station.description,
        new_neighbours,
        new_next_station
    }

    csv.write_file("data/individual_stations/station_" .. tostring(os.computerID()) .. ".csv",
        { updated_row })

    local all_stations = csv.read_file("data/stations.csv")
    for i, row in ipairs(all_stations) do
        if row[2] == this_station.computer_id then
            all_stations[i] = updated_row
            break
        end
    end
    csv.write_file("data/stations.csv", all_stations)

    update_stations()
end

function new_station.get_other_stations(sender, payload, external)
    if external then
        local stations = get_stations()
        encnet.send(sender, "OtheStat", textutils.serialise(stations, { allow_repetitions = true }))
    end
end

return new_station
