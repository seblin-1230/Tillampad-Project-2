local csv = require "libs.csv"
local new_station = {}

function new_station.new_station(sender, payload)
    csv.append_file("data/stations.csv", payload)

    local this_station = get_this_station()
    for neighbor in string.gmatch(payload[8], "[^:]+") do
        if this_station.computer_id == neighbor then
            local new_neighbours = table.concat(this_station.neighbors, ":") .. ":" .. tostring(sender)
            csv.write_file("data/individual_stations/station_" .. tostring(os.computerID()) .. ".csv",
                {
                    this_station.station_id,
                    this_station.computer_id,
                    this_station.position.x,
                    this_station.position.y,
                    this_station.position.z,
                    this_station.name,
                    this_station.description,
                    this_station.next_station
                })
        end
    end

    update_stations()
end

return new_station