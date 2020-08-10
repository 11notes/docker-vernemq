require "auth/auth_commons"

function auth_on_register(reg)
    if reg.username ~= nil and reg.password ~= nil and reg.client_id ~= nil then
        key = "client:" .. reg.username ..":" .. reg.client_id
        res = redis.cmd(pool, "GET " .. key)
        if res then
            res = json.decode(res)
            if res.passhash == bcrypt.hashpw(reg.password, res.passhash) then
                cache_insert(
                    res.mountpoint,
                    reg.client_id,
                    reg.username,
                    res.publish_acl,
                    res.subscribe_acl
                    )
                return {
                    subscriber_id = {
                        mountpoint = res.mountpoint,
                        client_id = reg.client_id
                    }
                }
            end
        else
            -- save unknown clients for 15' to db
            key = "unknown:" .. reg.username ..":" .. reg.client_id
            value = json.encode({["username"] = reg.username, ["client_id"] = reg.client_id, ["addr"] = reg.addr})
            redis.cmd(pool, "SETEX " .. key .. " 900 " .. value)
        end
    end
    return false
end

pool = "auth_redis"
config = {
    pool_id = pool
}

redis.ensure_pool(config)
hooks = {
    auth_on_register = auth_on_register,
    auth_on_publish = auth_on_publish,
    auth_on_subscribe = auth_on_subscribe,
    on_unsubscribe = on_unsubscribe,
    on_client_gone = on_client_gone,
    on_client_offline = on_client_offline,
    on_session_expired = on_session_expired,

    auth_on_register_m5 = auth_on_register_m5,
    auth_on_publish_m5 = auth_on_publish_m5,
    auth_on_subscribe_m5 = auth_on_subscribe_m5,
}