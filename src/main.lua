local sha256 = require("encryption.sha256")
local crypto = require("encryption.crypto")
local utils  = require("utils")

local modem = peripheral.find("modem")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count+1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end


term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.white)

local session_key = generate_session_key()
