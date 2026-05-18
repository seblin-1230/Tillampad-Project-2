local utils = require "libs.utils"
local pbkdf2 = require "libs.encryption.pbkdf2"
local identity_file = fs.open("disk/identity.txt", "r")
local identity = identity_file.readAll()
identity_file.close()

local hash = pbkdf2.derive(identity, "j8OtehrzI6Iw7jNVJPtgjBUBefMJv38Y", 10000, "Progress: ")

print(hash)
hash_file = fs.open("master_disk_identity.hash", "w")
hash_file.write(hash)
hash_file.close()