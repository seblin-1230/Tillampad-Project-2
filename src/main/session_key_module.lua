local session_key = {}

function session_key.request(sender, payload, external)
    if external then

    else
        if not ready then
            encnet.send()
        end
    end
    -- TODO Finish session_key_request
end

function session_key.response(sender, payload, external)
    local session_key = payload[1]
    -- TODO Finish session_key_response
end

function session_key.clear_master(sender, payload, external)
    -- TODO Finish clear_master
end

return session_key