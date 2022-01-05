local fiber = require('fiber')

local function stop()
end

local function validate_config(conf_new, conf_old)
    return true
end

local function apply_config(conf, opts)
    if opts.is_master then
    end
    return true
end

local kv_storage = {
    find = function(key)
        local tuple = box.space.kv_store:get{key}
        local a = {};
        a['value'] = tuple['value'];
        a['timestamp'] = tuple['timestamp'];
        return a
    end,
    upsert = function(key, value, ttl)
        local timestamp = math.floor(fiber.time())
        box.space.kv_store:upsert({ key, value, timestamp, ttl }, {{'=', 2, value}, {'=', 3, timestamp}, {'=', 4, ttl}})
        return true
    end,
}

local function init(opts)
    rawset(_G, 'kv_storage', kv_storage)
    if opts.is_master then
        local kv_store = box.schema.space.create('kv_store', {
            engine = 'memtx',
            is_sync = true,
            if_not_exists = true,
        })
        kv_store:format({
            { name = 'key',   type = 'string' },
            { name = 'value', type = 'string' },
            { name = 'timestamp', type = 'number' },
            { name = 'ttl', type = 'number' },
        })
        kv_store:create_index('primary', { type = 'hash', parts = {1, 'string'}, if_not_exists = true })
        for name, _ in pairs(kv_storage) do
            box.schema.func.create('kv_storage.' .. name, { setuid = true, if_not_exists = true })
            box.schema.user.grant('admin', 'execute', 'function', 'kv_storage.' .. name, { if_not_exists = true })
        end
    end
    return true
end

return {
    role_name = 'app.roles.storage',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    dependencies = {'cartridge.roles.vshard-storage'}
}
