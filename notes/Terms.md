### Master disk
	The master disk is a disk that is used to reboot the network after it has shutdown (often due to server restarts)
	It stores a random message and a "Check hash" it is the message but hashed)
	Both of these are then encrypted using hash(admin_pin + static_salt) as the key
	To verify that a admin is using the master disk the station asks for the admin pin
	Then the station does hash(pin + static_salt)
	The station then decrypts the master disk contents using the new hash
	Then the station does hash(drive_message) if this matches the check hash the station continues it's reboot setup

### Session key
	The key used to encrypt messages and salt hashes during a session. Changes every time the network reboots
### Station data
	The data on a specific station

| Key                  | Type    | Explanation                                                           |
| -------------------- | ------- | --------------------------------------------------------------------- |
| station_id           | integer | The id of the station                                                 |
| description          | string  | A short description of the station.                                   |
| arrival_cordinates   | Vector3 | The coordinates to teleport to when arriving at the station           |
| transfer_coordinates | Vector3 | The coordinates to teleport to when using the station as an inbetween |
### Route list
	The route the user is taking to teleport to their destination. Takes the form of a list containing an arbitrary number of stations and optionaly ending in a  coordinates at the end
### System hash
	A hash made from all the files on a computer and all the # peripherals connected to a computer (exluding drives) recalculated on the fly and no parts of it saved to the disk
Calculated with: hash(all_files_hashed + all_periferals_hashed) 
### Nonce
	A string of randomly generated characters used to verify that the hashes sent between two stations aren't saved previous versions
### Teleport request
	A request from one station to another to verify each others integrity

| Key               | Type    | Explanation                                                  |
| ----------------- | ------- | ------------------------------------------------------------ |
| time              | integer | The time the request was sent                                |
| type              | string  | The type of payload                                          |
| route             | list    | A list of stations optionalty ending in a set of coordinates |
| [[#Nonce\|nonce]] | string  | A random string to verify hashes                             |
### Teleport response
	The response to a verification request

| Key          | Type    | Explanation                                         |
| ------------ | ------- | --------------------------------------------------- |
| time         | integer | The time the request was sent                       |
| type         | string  | The type of payload                                 |
| hash         | string  | The hash calculated by hashing all of the variables |
| station_data | table   | The data of the station used to calculate the       |
### Teleport accept
	Sent from accepting station when verification from both stations is done and the teleport can be initiated

| Key  | Type    | Explanation                   |
| ---- | ------- | ----------------------------- |
| time | integer | The time the request was sent |
| type | string  | The type of payload           |
### Session key request
	A request sent from a station when it starts up and detects that it doesn't have a session key

| Key  | Type    | Explanation                   |
| ---- | ------- | ----------------------------- |
| time | integer | The time the request was sent |
| type | string  | The type of payload           |

### Key exchange begin
	Sent from a station begining the process of sending over a session key

| Key  | Type    | Explanation                             |
| ---- | ------- | --------------------------------------- |
| time | integer | The time the request was sent           |
| type | string  | The type of payload                     |
| p    | integer | The prime used as mod in the exchange   |
| g    | integer | The number used as base in the exchange |
### Key exchange recived
	Sent from a station accepting the process of sending over a session key

| Key  | Type    | Explanation                   |
| ---- | ------- | ----------------------------- |
| time | integer | The time the request was sent |
| type | string  | The type of payload           |
### Key exchange public
	Contains the intermediate step for key exchange

| Key        | Type    | Explanation                   |
| ---------- | ------- | ----------------------------- |
| time       | integer | The time the request was sent |
| type       | string  | The type of payload           |
| public_key | integer | The public key being sent     |
### Key exchange final
	The final thing sent in a key exchange. Contains the session key

| Key         | Type    | Explanation                   |
| ----------- | ------- | ----------------------------- |
| time        | integer | The time the request was sent |
| type        | string  | The type of payload           |
| session_key | integer | The session key               |
