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

---Find the best route from the current position to the destination
---@param origin Station
---@param destination Station|ccTweaked.Vector
---@param stations Station[]
function routing.find_route(origin, destination, stations)
    local route = {destination}
    if not destination.computer_id then
        local closest_station = routing.find_closest_station(destination, stations)
        if not closest_station then
            return {}
        end

        table.insert(route, 1, closest_station)
    end


    local visited = {} --[[@type {[Station]: Station}]]
    local queue = {origin} --[[@type (Station[])]]
    local last_visited --[[@type Station]]
    local visiting --[[@type Station]]

    while true do
        visiting = queue[1]
        table.remove(queue, 1)

        if visiting == route[1] then
            if last_visited == nil then
                break
            else
                table.insert(route, 1, visited[last_visited])
                last_visited = visited[last_visited]
            end
        else
            
        end
    end
end

return routing