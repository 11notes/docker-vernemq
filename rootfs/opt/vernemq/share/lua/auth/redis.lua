require "auth/auth_commons"

pool = "auth_redis"
config = {
  pool_id = pool
}
redis.ensure_pool(config)

-- clean key
local function clean(s)
  if s == nil then return "anonymous" end
  return (tostring(s):gsub("[%s:]", "_"))
end

-- fix wrong hash salt and check length
local function normalize_hash(h)
  if type(h) ~= "string" or #h ~= 60 then return nil end
  return (h:gsub("^%$2[by]%$", "$2a$"))
end

-- store unknown clients for 15'
local function remember_unknown(reg)
  local key = "unknown:" .. clean(reg.username) .. ":" .. clean(reg.client_id)
  local value = json.encode({
    username = clean(reg.username),
    client_id = clean(reg.client_id),
    addr = clean(reg.addr)
  })
  redis.cmd(pool, "SETEX " .. key .. " 900 " .. value)
end

function auth_on_register(reg)
  -- anonymous or incomplete connection: record, then reject authentication
  if reg.username == nil or reg.password == nil or reg.client_id == nil then
    remember_unknown(reg)
    return false
  end

  local password = obf.decrypt(reg.password)
  if password == nil then
    remember_unknown(reg)
    return false
  end

  local key = "client:" .. clean(reg.username) .. ":" .. clean(reg.client_id)
  local res = redis.cmd(pool, "GET " .. key)

  if res then
    res = json.decode(res)

    local stored = normalize_hash(res.passhash)
    if stored == nil then
      -- malformed hash: reject authentication
      return false
    end

    local ok, computed = pcall(bcrypt.hashpw, password, stored)
    if ok and computed == stored then
      cache_insert(
        res.mountpoint,
        reg.client_id,
        reg.username,
        res.publish_acl,
        res.subscribe_acl
      )
      -- return mountpoint with cliend ID (multi tenant)
      return {
        subscriber_id = {
          mountpoint = res.mountpoint,
          client_id = reg.client_id
        }
      }
    end
  else
    remember_unknown(reg)
  end

  return false
end

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