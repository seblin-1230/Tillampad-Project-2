local chacha20 = require("chacha20")
local sha256 = require("sha256")
local utils = require("utils")

local file = fs.open("program/identity.txt", "r")
local message = file.readAll()
local file_o = assert(fs.open("out.txt", "w"))
local hash = sha256.hash(message)

print(hash)
file_o.write(hash)

-- local enc, nonce = chacha20.crypt(message, "Hello this is the key and i stil")
-- print(enc)

-- local dec, nonce = chacha20.crypt(enc, "Hello this is the key and i stil", nonce)
-- print(dec)