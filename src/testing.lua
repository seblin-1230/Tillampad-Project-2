local pbkdf2 = require("libs.encryption.pbkdf2")
local crypto = require("libs.encryption.crypto")

local identity_file = fs.open("src/identity.txt", "r")
local identity = identity_file.readAll()
identity_file.close()

local salt = crypto.random_bytes(32)
print(salt)
local identity_hash = pbkdf2.derive(identity, salt, 20000, "Deriving identity: ")

local master_disk_identity = fs.open("master_disk_identity.hash", "w")
local salt_file = fs.open("salt.txt", "w")
master_disk_identity.write(identity_hash)
salt_file.write(salt)
master_disk_identity.close()
salt_file.close()

-- local enc, nonce = chacha20.crypt(message, "Hello this is the key and i stil")
-- print(enc)

-- local dec, nonce = chacha20.crypt(enc, "Hello this is the key and i stil", nonce)
-- print(dec)