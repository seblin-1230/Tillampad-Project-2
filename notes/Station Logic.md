## Routing logic
1. Takes a station or set of coordinates and outputs a list of stations needed to reach the destination (This is a work in progress, want to get the rest of the station logic first)

## Teleport logic
1. User is at Station A and selects a destination
2. Station A sets route = Routing_Logic(destination) (in this case B -> C -> destination)
3. Station A saves it's destination as Station B
4. Station A removes Station B from route
5. Station A generates a random [[Terms#Nonce|nonce]]
6. Station A sends a [[Terms#Teleport request|teleport request]] using nonce and route to Station B
7. Station B saves the route from the request
8. Station B calculates $H_1$ = hash([[Terms#System hash|system_hash]] + computerID() + route + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]]])
9. Station B sends a [[Terms#Teleport response|teleport response]] containing $H_1$ to Station A
10. Station A calculates $H_2$ = hash([[Terms#System hash|system_hash]] + station_b_computerID + route + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]]])
11. Station A checks that $H_1 = H_2$ 
12. Station A calculates $H_3$ = hash([[Terms#System hash|system_hash]] + computerID() + route + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]])
13. Station A sends a [[Terms#Teleport response|teleport response]] containing $H_3$ to Station B
14. Station B calculates $H_4$ = hash([[Terms#System hash|system_hash]] + station_a_computerID() + route + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]])
15. Station B checks that $H_3 = H_4$ 
16. Station B sends a [[Terms#Teleport accept|teleport accept]] to Station A
17. Station A waits for user to get in teleport chamber
18. Station A teleports user to Station B
19. Station B waits for user to arrive in teleport chamber
20. Station B checks if the next destination is the final one (it is not)
21. Repeat steps 2 - 17 with Station B replacing Station A and Station C replacing Station B
22. Station C checks if the next destination is the final one (is is)
23. Station C checks if the final destination is a station (it isn't)
24. If it was it does the verification handshake with the station
25. Teleport user to destination

## Adding station logic
1. Station A is new
2. Station B is existing
3. Admin inputs the [[Terms#Secret key|secret key]] into Station A
4. Station A broadcasts an [[Terms#Add station request|add station request]]
5. Station B generates [[Terms#Nonce|nonce]] and caches Station A:s data
6. Station B sends an [[Terms#Add station verification|add station verification]] using [[Terms#Nonce|nonce]] to Station A
7. Station A calculates $H_1$ = hash([[Terms#System hash|system_hash]] + computerID() + [[Terms#Station data|station_data]] + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]]])
8. 