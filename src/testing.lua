local utils = require "libs.utils"
local secret_file = fs.open("disk/secret.txt", "r")
local secret_hex = secret_file.readAll()
secret_file.close()

local secret_string = utils.string_from_hex(secret_hex)

print(secret_string)
secret_file = fs.open("disk/secret.txt", "w")
secret_file.write(secret_string)
secret_file.close()