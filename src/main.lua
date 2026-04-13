local sha256  = require("libs.encryption.sha256")
local crypto  = require("libs.encryption.crypto")
local utils   = require("src.libs.utils")
local routing = require("routing")

local modem = peripheral.find("modem")

local function generate_session_key()
    local key_count = settings.get("station.key_count")
    local base = tostring(os.epoch("utc")) .. tostring(os.computerID()) .. tostring(key_count) .. crypto.random_bytes(64)

    settings.set("station.key_count", key_count+1)
    settings.save()

    return utils.string_from_hex(sha256.hash(base))
end

---Start the teleport process to a destination
---@param destination integer
local function initiate_teleport(destination)
    local route = routing.find_route(destination)
end

-- term.clear()
-- term.setCursorPos(1, 1)
-- term.setTextColor(colors.white)

local session_key = "aVUD5IqcE6E27lVRlByso9tN1IQC3Sdn" --generate_session_key()

initiate_teleport(1)