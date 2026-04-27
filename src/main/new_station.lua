local new_station = {}

function new_station.new_station(sender, payload)
    local x, y, z, station_id, station_description = payload.x, payload.y, payload.z, payload.id, payload.description
    -- TODO Finish new_station
end

function new_station.verification(sender, payload)
    local master_secret_hash = payload[1]
    -- TODO Finish new_station_verification
end

function new_station.new_neighbour(sender, payload)
    local station_id = payload[1]
    -- TODO Finish new_neighbour
end

return new_station