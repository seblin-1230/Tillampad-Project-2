local chacha20 = require("chacha20")
local sha256 = require("sha256")
local utils = require("utils")

-- local key = string.char(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f)
-- local plaintext = [[
-- Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.
-- ]]

-- local encrypted, nonce = chacha20.crypt(plaintext, key)
-- print(string.byte(encrypted, 1, #encrypted))

-- local unencrypted = chacha20.crypt(encrypted, key, nonce)
-- print(unencrypted)

local message = "The quick brown fox jumps over the lazy dog and then decides to jump over the lazy dog again just for the fun."

local file = assert(fs.open("out.txt", "w"))
print(sha256.hash(message))
file.write(sha256.hash(message))