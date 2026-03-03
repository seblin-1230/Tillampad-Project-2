## Master disk verification
The problem is that you can't store any data on the computer for verification. You just have to trust that the data on the disk is secure. 
One idea i found was to have a message and a hashed version of that message (called a check hash). Both of these are then encrypted with hash(admin_pin + static_salt)
When the station verifys the disk it promts for the admin pin, decrypts the message and check hash, then does hash(message) and checks if it matches with the check hash.
The problem with this setup is that anyone can create a disk that fullfills these requirements. An attacker can just make thier own message, hash it and encrypt it with their own pin, then when the station prompt them for the admin pin they could just input thier new one and the check would pass.

But then I thought about if this even was an issue? Does it matter if anyone can start the network? As long as it doesn't give them access to the session key it should be fine, and since that is generated "on the fly" and stored in the computers ram it shouldn't be accesable through this. I am still going to implement the above logic, but mainly as a detterent and to lower the odds of two stations being initialized at the same time and then generating two conflicting session keys. 
#### Logic
1. Read the master disks data, refered to as $message_{encryped}$ & $check\_hash_{encrypted}$
2. Prompt for $admin\_pin$
3. Decrypt $message_{encryped}$ & $check\_hash_{encryped}$ to $message$ & $check\_hash$ using $admin\_pin$
4. Do $message\_hash=hash(message)$
5. If $message\_hash=check\_hash$ then return true
6. if $message\_hash \ne check\_hash$ then return false
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

## Network restart logic
	Station A is the station used by an admin to initilize the network
	Station B represents another station in the network
	Admin is the user with access to the master disk
Don't need to verify other stations just that this station is uncompormised
Easiest way is printing every line in the station list and if something doesn't match up the admin doesn't continue
But this would either require verifying the master disk or hiding the station list
No either would require verfiying the master disk and itself
Mabye after sending session key Station B verifys Station A:s integrity?
But how.
Back at the same problem of needing a constant for every station that no one else has access to.
Or a "password" stored in the disk that can be hashed and compared to an uneditable file
Above is very easy with a datapack. Use as a last resort
Station B also needs to verify Station A
Again very easy if using a datapack, just send the encrypted disk contents and decrypt them and compare at station B
asymmetric key cryptography would be good if i could find a way to store information
Think about not encrypting every message

Options:
- Store station code encrypted on pastebin. <- worst option, the key would have to be stored in the master disk and i would have to go to every staion myself
- Using something like ftb chunks to claim the stations to prevent mining stations <- could with other technecues be used to prevent writing to the computers
- Use a datapack to store master disk password hash and use contents of master disk to sign messages, encrypting them using something like diffe-helleman key exchange
- Store the password hash outside cc tweaked, eg pastebin. <- effectivly the same as datapack, is more cc tweaked-y but less in the spirit of minecraft

But none of this matters if i can't find a better way to prevent writing to computers without changeing something and making other stations reject the compromised one.
Preventing writing would solve almost all of my problems. It is very easy to prevent writing from the same computer but as far as i know there is no way to prevent ofther computers from writing using a disk drive. You can however have a startup script that detects if the computer id dosn't match what it should be and repetedly shuts the computer down if so.
This however doesn't hold up to scrutiny as you can just disable the shell.allow-booting-from-drives setting before putting the station computer into the drive
As it stands the station hash is very easy to figure out with just a disk drive and some determination.
As previously stated I need a variable that is consistant among every station but no other computers. Free disk space is almost this and prevents the hash being calculated on the station computer but, as I said, that can be read from a disk drive.


1. Every station boots up and broadcasts a [[Terms#Session key request|session key request]] over the protocol "session key request"
2. Every station waits for either a response on "session key request" or a disk being inserted into a drive
3. An admin inserts the [[Terms#Master disk|master disk]] into a drive connected to Station A
4. An admin inputs a pin into Station A
5. Station A computes $H_1$ = hash(pin + static_salt)
6. Station A uses $H_1$ to decrypt the [[Terms#Master disk|master disk]] 
7. Station A computes $H_2$ = hash(master_disk.message)
8. Station A checks if $H_2$ = master_disk.checkHash
9. If it doesn't Station A ejects the disk and goes back to waiting
10. If it does Station A does $K_{secret}$ = hash(master_disk.message + os.time())
11. Station A then pulls events from the protocol "session key request" untill there are none left. Doing the following on all of them. Station B is the station that sent the request
	1. Station A checks that Station B is in its list of stations
	2. Station A generates p and g for Diffie-Hellman key exchange
	3. Station A sends a [[Terms#Key exchange begin|key exchange begin]] to Station B
	4. Station B saves p and g
	5. Station B sends a [[Terms#Key exchange recived|key exchange recived]] to Station A
	6. Station A generates $private_A$ = random_bits(256)
	7. Station B generates $private_B$ = random_bits(256)
	8. Station A computes $public_A=g^{private_A}\mod p$ 
	9. Station B computes $public_B=g^{private_B}\mod p$
	10. Station A and B both send a [[Terms#Key exchange intermidiate|key exchange intermidiate]] with their public keys
	11. Station A and B wait to recive the public keys
	12. Station A computes $K_{temp} = {public_B}^{private_A}\mod p$
	13. Station B computes $K_{temp}={public_A}^{private_B}\mod p$
	14. Station A encrypts $K_{secret}$ with $K_{temp}$
	15. Station A sends a [[Terms#Key exchange final|key exchange final]] containg $K_{secret}$
	16. Station B saves $K_{secret}$ in a local variable and starts normal operation
12. Station A starts normal operation
## Adding station logic
1. Station A is new
2. Station B is existing
3. Admin inputs the [[Terms#Secret key|secret key]] into Station A
4. Station A broadcasts an [[Terms#Add station request|add station request]]
5. Station B generates [[Terms#Nonce|nonce]] and caches Station A:s data
6. Station B sends an [[Terms#Add station verification|add station verification]] using [[Terms#Nonce|nonce]] to Station A
7. Station A calculates $H_1$ = hash([[Terms#System hash|system_hash]] + computerID() + [[Terms#Station data|station_data]] + [[Terms#Secret key|secret_key]] + [[Terms#Nonce|nonce]]])

8. Station A generates p and g for Diffie-Hellman key exchange
	2. Station A sends a [[Terms#Key exchange begin|key exchange begin]] to Station B
	3. Station B saves p and g
	4. Station B sends a [[Terms#Key exchange recived|key exchange recived]] to Station A
	5. Station A generates $private_A$ = random_bits(256)
	6. Station B generates $private_B$ = random_bits(256)
	7. Station A computes $public_A=g^{private_A}\mod p$ 
	8. Station B computes $public_B=g^{private_B}\mod p$
	9. Station A and B both send a [[Terms#Key exchange intermidiate|key exchange intermidiate]] with their public keys
	10. Station A and B wait to recive the public keys
	11. Station A computes $K_{temp} = {public_B}^{private_A}\mod p$
	12. Station B computes $K_{temp}={public_A}^{private_B}\mod p$
	13. Station A encrypts $K_{secret}$ with $K_{temp}$
	14. Station A sends a [[Terms#Key exchange final|key exchange final]] containg $K_{secret}$
	15. Station B saves $K_{secret}$ in a local variable and starts normal operation

## ChaCha20 Encryption

### Initilize matrix state
	Key: 256 bit
	Initial counter: 32 bit starting at 1
	Nonce: 96 bit random number
1. Create 16 item long list, each item is a 32bit number called a word, the list is called a matrix state
2. Words 1-4 are set to the constants, 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574 
3. Words 5-12 are set to the key split into 4 byte chunks using little edian order
4. Word 13 is set to the initial counter
5. Words 14-16 are the nonce, split same as key
6. Words is the matrix state
### Quater round 
	a: A value of the matrix state
	b: A value of the matrix state
	c: A value of the matrix state
	d: A value of the matrix state
	All addition operations are done in mod 2^32
1. $a = a+b$
2. $d = d\oplus a$
3. $d=left\_rotate(d, 16)$
4. $c = c+d$
5. $b=b\oplus c$
6. $b=left\_rotate(b,12)$
7. $a=a+b$
8. $d=d\oplus a$
9. $d = left\_rotate(d,8)$
10. $c=c+d$
11. $b=b\oplus c$
12. $b=left\_rotate(b,7)$

### Double Round
1. $Quater\_Round(a:1,b:5,c:9,d:13)$
2. $Quater\_Round(a:2,b:6,c:10,d:14)$
3. $Quater\_Round(a:3,b:7,c:11,d:15)$
4. $Quater\_Round(a:4,b:8,c:12,d:16)$
5. $Quater\_Round(a:1,b:6,c:11,d:16)$
6. $Quater\_Round(a:2,b:7,c:12,d:13)$
7. $Quater\_Round(a:3,b:8,c:9,d:14)$
8. $Quater\_Round(a:4,b:5,c:10,d:15)$
9. return resulting state

### Serialize matrix state
1. $keystream\_block=empty\_string$
2. Concat $keystream\_block$ with each value in matrix state as little edian number
3. return $keystream\_block$

### Encrypt
	plain_text: The text to encrypt
	key: The key to encrypt with
1. Generate 96bit $nonce$
2. $cipher\_text=empty\_string$
3. for every 512bit (64byte) chunk in $plain\_text$, $i$ is chunk number
	1. $matrix\_state=Initilize(key,i,nonce)$
	2. $initail\_matrix\_state=matrix\_state$
	3. Repeat 10 times
		1. $matrix\_state=Double\_Round(i)$
	4. $matrix\_state=matrix\_state+initai\_state$ (add every word with it's "twin" once, again mod 2^32)
	5. $keystream\_block=Serialize\_Matrix\_State()$
	6. Do $cipher\_text=chunk\oplus keystream\_block$
4. return $cipher_text$
