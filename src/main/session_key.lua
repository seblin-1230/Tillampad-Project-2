local session_key = {}

function session_key.request(sender, payload)
    local master_secret_hash = payload[1]
    -- TODO Finish session_key_request
end

function session_key.response(sender, payload)
    local session_key = payload[1]
    -- TODO Finish session_key_response
end

function session_key.clear_master(sender, payload)
    -- TODO Finish clear_master
end

return session_key