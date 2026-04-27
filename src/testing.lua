local communication = require("main.communication")

local sha256 = require("libs.encryption.sha256")
local logger = require("main.logger")

-- local session_key = "aVUD5IqcE6E27lVRlByso9tN1IQC3Sdn" --generate_session_key()

-- local data = ""

-- for i = 1, 10000 do
--     data = data .. "hhhhhhhhhhhhhhhhhhhh"
-- end
-- print("data concatinated")

-- local time_sum = 0

-- for i = 1, 100 do
--     local t0 = os.epoch("utc")
--     sha256.hash(data)
--     local t = os.epoch("utc")

--     time_sum = time_sum + (t - t0)

--     if i % 100 == 0 then print(i) end
--     os.sleep(0)
-- end

-- print("Avrage_time: ", time_sum/1000000)

logger:new({station_id = 0})

LOGGER:info("test")