local routing = {}

---Find the closest station to a position
---@param position ccTweaked.Vector
---@param stations Station[ ]
function routing.find_closest_station(position, stations)
    
end

---Find the best route from the current position to the destination
---@param origin Station
---@param destination Station|ccTweaked.Vector
---@param stations Station[]
function routing.find_route(origin, destination, stations)
    if not destination.computer_id then
        
    end
end

return routing