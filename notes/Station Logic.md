## Things to note
- The session key is a 32 byte secret key randomly generated on network startup, but is containes the time the key was generated to ensure it doesn't generate two identical keys
- Any time $hash()$ is used it means the sha256 algorithm, as it seemed a good balance of preformance and security
- Any time $crypt()$ is used it uses ChaCha20 to encrypt/decrypt using a 4 byte block count and a 12 byte nonce. The key is the session key unless specified otherwise
- Every usage of nonce is a 12 byte semi random number. Bytes 1-4 is the amount of milliseconds since 1970 truncated to fit 4 bytes, bytes 5-6 is the computer ID, and bytes 7-12 are random 
- Every request, response, and other rednet message has the data encrypted using the session key (unless otherwise specified), and is sent as a string with the first 12 bytes being the nonce and the rest being the encrypted data
- Whenever a station gets the [peripheral_detach](https://tweaked.cc/event/peripheral_detach.html) or [peripheral](https://tweaked.cc/event/peripheral.html) events, it clears the session key and shuts down the computer.
- When a station boots up it scans the blocks in the teleporting chambers using the block scanner from plethora and saves $hash(blocks)$ in RAM as $blocks\_hash$
- Every 5 min the stations scan the blocks in the teleporting chambers and check if $hash(blocks)=blocks\_hash$. if it doesn't the station clears the session key and shuts down
- Every time a station is waiting on another station to respond the timeout time is 3 seconds, if it is during a teleport request the rest of the process is skiped and the station is marked as unsafe
---
## Station self validation
This runnes once when the station starts up to do a basic integrity check on the station so nothing obvious has changed
1.  TODO WRITE THIS
---
## Master disk verification
The problem is that you can't store any data on the computer for verification. You just have to trust that the data on the disk is secure. 
One idea i found was to have a message and a hashed version of that message (called a check hash). Both of these are then encrypted with hash(admin_pin + static_salt)
When the station verifys the disk it promts for the admin pin, decrypts the message and check hash, then does hash(message) and checks if it matches with the check hash.
The problem with this setup is that anyone can create a disk that fullfills these requirements. An attacker can just make thier own message, hash it and encrypt it with their own pin, then when the station prompt them for the admin pin they could just input thier new one and the check would pass.

But then I thought about if this even was an issue? Does it matter if anyone can start the network? As long as it doesn't give them access to the session key it should be fine, and since that is generated "on the fly" and stored in the computers ram it shouldn't be accesable through this. I am still going to implement the above logic, but mainly as a detterent and to lower the odds of two stations being initialized at the same time and then generating two conflicting session keys. 

---

With the new logic the biggest vulnerability a station has is between the server restarting and the master disk being inserted. As during this time the station dosn't have any critical data that would be wiped by breaking the computer, and if you can break the computer you can put it in a disk drive and read/write to it. But as I said it is not **that** big of an issue if a determined attacker can create a master disk as all it would allow them to do is restart the network since the session key is never exposed any where.
Right?
But the problem is that since the session key is encrypted with the master secret when sent between stations an attacker can create a master disk where they know the master secret and create a computer that wiretaps the communication between Station A and Station B. Then when Station A sends the encrypted session key the attacker can just decrypt it and now the attacker knows the session key. 

My first idea was to solve this by generating a new key every 10-20 min but how would it be transmited, with the old session key? the one that is compromised? No that won't work.

But if I can't make it impossible I might as well make it really really annoying. The first step is adding a thing to the startup.lua that detects if it is being run from a disk. eg an attacker mined the station computer and put it in a disk drive without disabling list.allow_boot_from_disk, then if it is being run from a disk it prevents itself from being terminated by overiding os.pullEvent with os.pullEventRaw and ignoreing all terminate events, then it creates a new startup.lua in the main hdd of the attackers computer and writes code that makes the computer just quietly shut down then it deletes all the files on the attackers computer (exept the new startup.lua) then disables list.allow_boot_from_disk on the attackers computer. Then it shuts the computer down, it does all od this quietly witout printing anything.

This is ofcourse not enough to deter even a silightly above avarege cc tweaked user as they can just make a new computer and disable list.allow_boot_from_disk before inserting the station computer.
My best bet at doing anything more than annoy someone for 10 seconds until they open google is to create a global salt that is hashed with the master disk contents and the admin pin then compared to a hash on the master disk.
This salt can't be just plain text in the startup script as that can be easily read/written, it will need to be obfuscated, this is not ideal and i would prefer it be impossible to read/write as there is no security through obscurity it will have to do.

There are many ways to obfuscate the salt, and i will go with as many as i can. Ideas so far:
- Hide in the sha256 constants/chacha20 constants
- Hide in world with blockscanner, signs, lecterns and block positions (half forces the attacker to use the station in the same place)
- Do a bunch of random math of the hidden values
- Include a/several fake salt(s) in the code
- Use minifided code and load() to run a human unreadable function
- Creating a salt function and then later reassigning it in a load() call

But I will start by using a datapack to add a hash of the master disk contents to ROM and use that as the master disk verification

---
On station creation generate an encryption key from the master disk and some salt
Use this encryption key to encrypt a verification phrase 
Then on master disk verification generate the encryption key and check if the decrypted verification phrase is correct
If so return true and the encryption key
#### OLD Logic
1. Station reads identity.txt from $master\_disk$ as $identity$
2. Station checks if $hash(identity)=master\_hash$
3. If it does return true
4. Else return false
---
## Integrity check
This is a script on the master disk that an admin runs after master disk verification to confirm that the station is safe.
1. Store a bunch of pre calculated hashes for everything on the station (The files and connected preipherals)
2. Loop over every file on station and compare it's hash to what it should be, If it doesn't match print an error.
3. Loop over every connected peripheral and hash it's metadata, also compare it to the hash list, if something is missing or hash doesn't match print an error
---
## Routing logic
	Takes a station or set of coordinates and outputs a list of stations needed to reach the destination (This is a work in progress, want to get the rest of the station logic first)
	In the example the starting station is Station A, the station closest to the destination is Station G, and the best route is A->C C->F F->G G->destination

When I started looking i found Dijkstra’s algorithm witch seemed like a perfect fit! until i relized that the "distance" between nodes will always be one and therefore the algorithm just becomes breadth first search, and since i don't want to implement A* i'm just going to use BFS. It should be fine since realisticly a network would have at most 200 stations in extreme cases

1. Save $route$ and set it to \[$destination$] 
2. If the $desitation$ is a set of coordinates then:
	1. For every station in the list 
	2. Check if it is closer to the destination than the current best
	3. If it is save that station as the current best
	4. After the loop prepend closest station to $route$, $route=[staiton\_G$, $destination]$
3. Define $visited=\{\},\space queue=[],\space last\_visited=0$ 
4. Add Station A to $queue$, $queue=[A]$
5. Define $visiting=queue[1]$
6. Remove $visiting$ from $queue$
7. Check if $visiting=route[1]$
8. If it doesn't:
	1. Add $visiting$ neighbors to $queue$ unless they have already been visited or they are already in $queue$
	2. Add $\{visiting:last\_visited\}$ to $visited$ 
	3. Set $last\_visited=visiting$
9. If it does:
	1. Check if $last\_visited=0$
	2. if it doesn't
		1. Prepend $visited[last\_visited]$ to $route$
		2. Set $last\_visited = visited[last\_visited]$
	3. If it does:
		1. Exit loop
10. Repeat 5-9 until loop exit
11. Return $route$ 
---
## Teleport logic
1. User is at Station A and selects a $destination$
2. Station A sets $route = routing\_logic(destination)$ (in this case A -> B -> C -> destination)
3. Station A removes Station A from $route$
4. Station A checks if $route$ is empty
5. If it is
	1. Open door out of teleportation chamber
	2. Stop teleportation logic
6. If it isn't
	1. Station A checks if the next station is a set of coordinates
	2. If it is
		1. Teleport user to those coordinates
		2. Stop teleportation logic
	3. If it isn't
		1. Station A saves it's destination as Station B ($route[1]$)
		2. Station A generates a $nonce$
		3. Station A calculates $station\_hash_{A\_A}=hash(files+peripherals+nonce+id_A)$
		4. Station A sends a [[Terms#Teleport initiate|teleport initiate]] to Station B
		5. Station B calculates $station\_hash_{A\_B}=hash(files+peripherals+nonce+id_A)$
		6. Station B checks that $station\_hash_{A\_B}=station\_hash_{A\_A}$
		7. If it dosn't pass Station B sends a [[Terms#Teleport denied|teleport denied]] and abandons this teleport
		8. Station B calculates $station\_hash_{B\_B}=hash(files+peripherals+nonce+id_B)$
		9. Station B sends a [[Terms#Teleport verification|teleport verification]]
		10. Station A calculates $station\_hash_{B\_A}=hash(files+peripherals+nonce+id_B)$
		11. Station A checks that $staiton\_hash_{B\_A}=station\_hash_{B\_B}$
		12. If it doesn't pass Station A sends a [[Terms#Teleport denied|teleport denied]] and abandons this teleport
		13. Station A teleports user to Station B
		14. Station A sends [[Terms#Teleport done|teleport done]] to Station B
		15. Station B saves $route$
7. Repeat steps 3-6 until "Stop teleportation logic" replacing Station A with the station the user is currently at
---
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

Another option is making it impossible to add anything to the station with a huge file, like 9500 kb at least. Full of cryptograficly secrure random data. Then when sending the request for the station hash sending a pointer to some bytes in the file and hashing those along with the stations data. That way hijaking a station and hardcoding the system hash is very hard. But an attacker can still copy the entropy file to a disk and impersonate a station to get the station key as everything else is a constant. And even if you send a bunch of random pointers to to every file and read the bytes the attacker can still clone the entire station onto a disk/poket computer and read the data of of that as you can't randomize the peripherals.

I hav ecome to the conclusion that this is an unsolvable problem. The only way to restart the network is by going to every station and physicaly verifying it personaly.

### Steps
1. Every station computer restarts with all RAM reset and only startup.lua running
2. Every station starts waiting for a disk to be inserted
3. An admin inputs the $master\_disk$ into Station A
4. Station A [[#Master disk verification|verifys the master disk]]
5. If it passes continue else eject disk and restart computer 
6. Station A starts a new shell in the foreground, moving the startup script into the background, and starts waiting for the insert key to be pressed
7. The admin runs the [[#Integrity check|integrity check]] from the master disk
8. If it passes the admin allows the program to continue by pressing insert, else the admin shuts the computer down and fixes the issue
9. Station A saves the [[Terms#Master disk|master disks]] secret ($master\_secret$)
10. Station A asks what station the admin came from
11. The admin responds that they came from no station
12. Station A generates a [[Terms#Session key|session key]] ($session\_key$)
13. Station A teleports admin to Station B
14. Repeat steps 3-10 at Station B
15. The admin inputs Station A
16. Station B sends a [[Terms#Session key request|session key request]] to Station A, encrypted using $master\_secret$
17. Station A checks that the decrypted key request is the $master\_secret\_hash$
18. Station A respondes with the $session\_key$, also encrypted with $master\_secret$ as the key
19. Station B saves $session\_key$ in RAM
20. Station B sends the admin to Station C
21. This process repeats until every station has been verified
22. The admin is at Station Z
23. Station Z sends a request to all stations to clear $master\_secret$ out of RAM this is encrypted using the new $session\_key$
24. All stations clear $master\_secret$ out of RAM
---
## Adding station logic
	Station A is new, Station B is existing
1. An admin builds Station A
2. An admin insert the $master\_disk$ into Station A
3. An admin runs the create station script on Station A from the $master\_disk$
4. Station A copies all the station scripts and the list of stations from the $master\_disk$
5. Station A teleports admin to a random station and start waiting for [[Terms#New station verification|new station verification]]
6. An admin inserts $master\_disk$ into Station B
7. Station B verifys $master\_disk$ and saves $master\_secret$
8. An admin inputs Station A into Station B
9. Station B sends [[Terms#New station verification|new station verification]] to Station A
10. Station A checks that decrypted payload is $master\_secret\_hash$
11. Station A sends 



12. If it does Station B sends the $session\_key$ to Station A, encrypted using $K_{temp}$
13. Station A saves $session\_key$ and waits for the master disk to be removed
14. An admin inputs what stations Station A is neighboring
15. Station A broadcasts [[Terms#New station|new station]] to every station
16. Station A sends [[Terms#New neighbour|new neighbour]] to each of its neighbors
17. Station A adds itself to the $master\_disk$ station list
18. Station A goes into normal operation

---
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
