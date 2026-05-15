local pbkdf2 = require("libs.encryption.pbkdf2")

local identity_file = fs.open("/src/identity.txt", "rb")
local identity_data = identity_file.readAll()
identity_file.close()

local hashed = pbkdf2.derive(identity_data, "j8OtehrzI6Iw7jNVJPtgjBUBefMJv38Y", 10000, "Progress: ")

local hashed_file = fs.open("/hashed_identity.txt", "w")
hashed_file.writeLine(hashed)
hashed_file.close()