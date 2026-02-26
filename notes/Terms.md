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
	A hash made from all the files on a computer and all the # peripherals connected to a computer (exluding drives)
Calculated with: hash(all_files_hashed + all_periferals_hashed)
### Secret key
	A key used in hashes between stations to verify that they are acctualy stations
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
### Add station request
| Key          | Type         | Explanation                   |
| ------------ | ------------ | ----------------------------- |
| time         | integer      | The time the request was sent |
| type         | string       | The type of payload           |
| station_data | station_data | The data of the new station   |
### Add station verification
| Key               | Type    | Explanation                      |
| ----------------- | ------- | -------------------------------- |
| time              | integer | The time the request was sent    |
| type              | string  | The type of payload              |
| [[#Nonce\|nonce]] | string  | A random string to verify hashes |
