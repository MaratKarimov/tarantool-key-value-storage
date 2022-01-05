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

local function init(opts)
    if opts.is_master then
        stop_expirationd_task()
    end
    return true
end

return {
    role_name = 'app.roles.expiry-entries',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    dependencies = {'app.roles.storage'}
}
