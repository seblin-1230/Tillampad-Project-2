local routing = {}

---Get the distance between two vectors
---@param vec1 ccTweaked.Vector
---@param vec2 ccTweaked.Vector
---@return number distance
function routing.get_distance(vec1, vec2)
    local x_sq = math.pow(vec1.x - vec2.x, 2)
    local y_sq = math.pow(vec1.y - vec2.y, 2)
    local z_sq = math.pow(vec1.z - vec2.z, 2)

    local d = math.sqrt(x_sq + y_sq + z_sq)
    return math.abs(d)
end

---Find the closest station to a position
---@param position ccTweaked.Vector
---@param stations Station[]
---@return Station? station
function routing.find_closest_station(position, stations)
    local closest_distance = math.huge
    local closest_station --[[@type Station]]
    for id, station in pairs(stations) do
        local distance = routing.get_distance(position, station.position)
        if distance < closest_distance then
            closest_distance = distance
            closest_station = station
        end
    end

    if closest_distance > 10000 or closest_station.unsafe then
        return nil
    end

    return closest_station
end

function routing.generate_adjacent()
    local stations = get_stations()

    local graph = {}
    for id, station in pairs(stations) do
        graph[id] = station.neighbors
    end

    return graph
end

local function bfs(graph, src, par, dist)
    --LOGGER:info("Starting BFS")
    local q = {}
    dist[src] = 0
    table.insert(q, src)

    while #q > 0 do
        local node = table.remove(q, 1)
        for _, neighbor in pairs(graph[node]) do
            if dist[neighbor] == math.huge then
                par[neighbor] = node
                dist[neighbor] = dist[node] + 1
                table.insert(q, neighbor)
            end
        end
        os.sleep(0)
    end
end

---Find the best route from the current position to the destination
---TODO Add handling for nonexistant stations, eg station 0 crashes program
---@param source Station
---@param destination Station|ccTweaked.Vector
function routing.find_route(source, destination)
    local stations = get_stations()

    local route = {}
    if not destination.computer_id then
        --LOGGER:info("Destination is coordinates, finding closest station")
        local closest_station = routing.find_closest_station(destination, stations)
        if not closest_station then
            --LOGGER:warning("No stations within 10k blocks of destination, aborting")
            return {}
        end

        --LOGGER:info("Closest station " .. tostring(closest_station) .. " at " .. tostring(closest_station.position))
        table.insert(route, destination)
        table.insert(route, closest_station.computer_id)
    else
        table.insert(route, destination.computer_id)
    end

    local graph = routing.generate_adjacent()
    local src, des = source.computer_id, route[#route]

    local par = {}
    local dist = {}
    for id, station_info in pairs(stations) do
        par[id] = -1
        dist[id] = math.huge
    end

    bfs(graph, src, par, dist)

    if dist[des] == math.huge then
        --LOGGER:warning("No path found to destination")
        return {}
    end

    local current_node = des
    while par[current_node] ~= -1 do
        table.insert(route, par[current_node])
        current_node = par[current_node]
    end

    --LOGGER:info("Route found: ", textutils.serialise(route, {compact = true}))
    return route
end

return routing