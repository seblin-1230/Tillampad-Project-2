local crypto = require("libs.encryption.crypto")
local utils = require("libs.utils")
local sha256 = require("libs.encryption.sha256")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count + 1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end

local file = fs.open("disk/current_key.txt", "w")
file.write(generate_session_key())
file.close()