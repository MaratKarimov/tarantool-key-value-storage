local fiber = require('fiber')
local expirationd = require("expirationd")
local expirationd_task_name = 'Delete expired keys task'

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function stop_expirationd_task()
    local tasks = expirationd.tasks()
    local has_value_result = has_value(tasks, expirationd_task_name)
    if has_value_result then
        expirationd.task(expirationd_task_name):stop()
    end
end

local function stop()
end

local function validate_config(conf_new, conf_old)
    return true
end

-- expiration function
local is_key_expired = function(args, tuple)
    return fiber.time() > (tuple[3] + tuple[4])
end

local function apply_config(conf, opts)
    if opts.is_master then
        local tasks = expirationd.tasks()
        local has_value_result = has_value(tasks, expirationd_task_name)
        if (not has_value_result and box.space.kv_store ~= nil) then
            expirationd.start(expirationd_task_name, box.space.kv_store.id, is_key_expired,
                {
                    atomic_iteration = true,
                    tuples_per_iteration = 1000,
                    full_scan_time = 10 * 60,
                    force = true
                }
            )
        end
    end
    return true
end

local kv_storage = {
    find = function(key)
        local a = {};
        a['value'] = box.space.kv_store:get{key}['value'];
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

        stop_expirationd_task()
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
