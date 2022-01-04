local cartridge = require('cartridge')

local logger = require('log')
local json = require('json')
local vshard = require('vshard')

-- invalid body response generation
local function invalid_body(req, func_name,  msg)
    local resp = req:render{json = { info = msg }}
    resp.status = 400
    logger.info("%s(%d) invalid body: %s", func_name, resp.status, req.body)
    return resp
end

local function internal_error(req, func_name,  msg)
    local resp = req:render{json = { info = msg }}
    resp.status = 500
    logger.info("%s(%d) internal_error: %s", func_name, resp.status, req.body)
    return resp
end

-- create kev/value pair
local function create_kv(request)
    -- parse request body
    local status, body = pcall(function() return request:json() end)
    -- check type of response body
    if type(body) == 'string' then
        return invalid_body(request, 'create', 'Invalid body (not JSON)')
    end
    -- check fields of parsed body
    if body['key'] == nil or body['value'] == nil then
        return invalid_body(request, 'create', 'Missing fields of key or value')
    end
    -- init key var
    local key = body['key']
    -- calculate bucket id
    local bucket_id = vshard.router.bucket_id_strcrc32(key)
    -- upsert data for bucket
    local data, err = vshard.router.callrw(bucket_id, 'kv_storage.upsert', { key, body['value'] })
    if data == nil then
        logger.info(err)
        return internal_error(request, 'create', 'insertion failed')
    end
    local resp = request:render{json = { info = "Successfully created" }}
    resp.status = 201
    return resp
end

local function find(request)
    -- parse request body
    local status, body = pcall(function() return request:json() end)
    -- check type of response body
    if type(body) == 'string' then
        return invalid_body(request, 'find', 'Invalid body (not JSON)')
    end
    -- check fields of parsed body
    if body['key'] == nil then
        return invalid_body(request, 'find', 'Missing field of key')
    end
    -- init key var
    local key = body['key']
    -- calculate bucket id
    local bucket_id = vshard.router.bucket_id_strcrc32(key)
    local data, err = vshard.router.callro(bucket_id, 'kv_storage.find', { key })
    if data == nil  then
        local resp = request:render{json = { info = "Key doesn't exist", msg = err and err.msg }}
        resp.status = 404
        return resp
    end
    local resp = request:render{ json = { key = data.key, value = data.value }}
    resp.status = 200
    return resp
end

local function init(opts)
    local httpd = assert(cartridge.service_get('httpd'), "Failed to get httpd service")
    httpd:route({ method = 'POST', path = '/kv/find' }, find)
    httpd:route({ method = 'POST', path = '/kv' }, create_kv)
    return true
end

local function stop()
    return true
end

local function validate_config(conf_new, conf_old)
    return true
end

local function apply_config(conf, opts)
    return true
end

return {
    role_name = 'app.roles.key-value',
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    dependencies = {'cartridge.roles.vshard-router'},
}
