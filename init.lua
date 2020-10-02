local has_monitoring_mod = minetest.get_modpath("monitoring")

local hit_count, miss_count

if has_monitoring_mod then
  hit_count = monitoring.counter("auth_cache_hit", "cache hits")
  miss_count = monitoring.counter("auth_cache_cache_miss", "cache misses")
end

local cache = {}

local old_get_auth = minetest.builtin_auth_handler.get_auth
function minetest.builtin_auth_handler.get_auth(name)
  if not cache[name] then
    if has_monitoring_mod then
      miss_count.inc()
    end
    cache[name] = old_get_auth(name)

  elseif has_monitoring_mod then
    hit_count.inc()
  end

  return cache[name]
end

local old_delete_auth = minetest.builtin_auth_handler.delete_auth
function minetest.builtin_auth_handler.delete_auth(name)
  cache[name] = nil
  return old_delete_auth(name)
end

local old_set_password = minetest.builtin_auth_handler.set_password
function minetest.builtin_auth_handler.set_password(name, password)
  cache[name] = nil
  return old_set_password(name, password)
end

local old_set_privileges = minetest.builtin_auth_handler.set_privileges
function minetest.builtin_auth_handler.set_privileges(name, privs)
  cache[name].privs = privs
  return old_set_privileges(name, privs)
end

local old_reload = minetest.builtin_auth_handler.reload
function minetest.builtin_auth_handler.reload()
  cache = {}
  return old_reload()
end

local old_record_login = minetest.builtin_auth_handler.record_login
function minetest.builtin_auth_handler.record_login(name)
  local result = old_record_login(name)
  cache[name].last_login = os.time()
  return result
end

local old_iterate = minetest.builtin_auth_handler.iterate
function minetest.builtin_auth_handler.iterate(...)
  -- TODO: cache!
  return old_iterate(...) -- varargs shenanigans!
end
