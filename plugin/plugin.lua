--
-- The main plugin implementation that can run in an NGINX system with the LUA module enabled
--

local _M = { conf = {} }

local base64 = require 'ngx.base64'
local cipher = require 'resty.openssl.cipher'

local VERSION_SIZE    = 1
local GCM_IV_SIZE     = 12
local GCM_TAG_SIZE    = 16
local CURRENT_VERSION = 1

local function array_has_value(arr, val)
    for index, value in ipairs(arr) do
        if value == val then
            return true
        end
    end
    return false
end

local function from_hex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function get_csrf_header_name(config)
    return 'x-' .. config.cookie_name_prefix .. '-csrf'
end

local function initialize_configuration(config)

    if config                    == nil or
       config.cookie_name_prefix == nil or
       config.encryption_key     == nil or
       config.cors_enabled       == nil then
        ngx.log(ngx.WARN, 'The OAuth proxy configuration is invalid and must be corrected')
        return false
    end

    if config.trusted_web_origins == nil then
        config.trusted_web_origins = {}
    end
    
    if config.allow_tokens == nil then
        config.allow_tokens = false
    end

    if config.remove_cookie_headers == nil then
        config.remove_cookie_headers = true
    end

    if config.cors_enabled then

        if config.cors_allow_methods == nil then
            config.cors_allow_methods = { 'OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'}
        end

        if config.cors_allow_headers == nil then
            config.cors_allow_headers = { get_csrf_header_name(config) }
        end

        if config.cors_expose_headers == nil then
            config.cors_expose_headers = {}
        end

        if config.cors_max_age == nil then
            config.cors_max_age = 86400
        end
    end

    return true
end

local function get_encryption_key_bytes(config)

    if #config.encryption_key ~= 64 then
        ngx.log(ngx.WARN, 'The encryption key must be supplied as 64 hex characters')
        return nil
    end
    
    local encryption_key_bytes
    if not pcall(function() encryption_key_bytes = from_hex(config.encryption_key) end) then
        ngx.log(ngx.WARN, 'The encryption key contains invalid hex characters')
        return nil
    end

    return encryption_key_bytes
end

local function add_cors_response_headers(config, is_error)

    local origin = ngx.req.get_headers()['origin']
    if origin and array_has_value(config.trusted_web_origins, origin) then

        if config.cors_enabled or is_error then

            -- For plugin errors we always add these CORS headers, so that the SPA can read the error response body
            ngx.header['access-control-allow-origin'] = origin
            ngx.header['access-control-allow-credentials'] = 'true'
            if #config.trusted_web_origins > 1 then
                ngx.header['vary'] = 'origin'
            end
        end

        if config.cors_enabled then

            local method = ngx.req.get_method():upper()
            if method == 'OPTIONS' then
                if config.cors_allow_methods then
                    local allow_methods_str = table.concat(config.cors_allow_methods, ',')
                    if allow_methods_str then
                        ngx.header['access-control-allow-methods'] = allow_methods_str
                    end
                end
            end

            if config.cors_allow_headers then
                local allow_headers_str = table.concat(config.cors_allow_headers, ',')
                if allow_headers_str then
                    ngx.header['access-control-allow-headers'] = allow_headers_str
                end
            end

            if config.cors_expose_headers then
                local expose_headers_str = table.concat(config.cors_expose_headers, ',')
                if expose_headers_str then
                    ngx.header['access-control-expose-headers'] = expose_headers_str
                end
            end
            
            if config.cors_max_age then
                if config.cors_max_age > 0 then
                    ngx.header['access-control-max-age'] = config.cors_max_age
                end
            end
        end
    end
end

local function error_response(status, code, message, config)

    if config then
        add_cors_response_headers(config, true)
    end

    local method = ngx.req.get_method():upper()
    if method ~= 'HEAD' then
    
        local jsonData = '{"code":"' .. code .. '", "message":"' .. message .. '"}'
        ngx.status = status
        ngx.header['content-type'] = 'application/json'
        ngx.say(jsonData)
    end
    
    ngx.exit(status)
end

local function server_error_response(config)
    error_response(ngx.HTTP_INTERNAL_SERVER_ERROR, 'server_error', 'Problem encountered processing the request', config)
end

local function unauthorized_request_error_response(config)
    error_response(ngx.HTTP_UNAUTHORIZED, 'unauthorized', 'Access denied due to missing or invalid credentials', config)
end

local function decrypt_cookie(encrypted_cookie, encryption_key_bytes)

    local all_bytes, err = base64.decode_base64url(encrypted_cookie)
    if err then
        ngx.log(ngx.WARN, 'A received cookie could not be base64url decoded: ' .. err)
        return nil
    end

    local min_size = VERSION_SIZE + GCM_IV_SIZE + 1 + GCM_TAG_SIZE
    if #all_bytes < min_size then
        ngx.log(ngx.WARN, 'A received cookie had an invalid length')
        return nil
    end

    local offset = 1
    local version_byte = string.byte(all_bytes, offset, VERSION_SIZE)
    if version_byte ~= CURRENT_VERSION then
        ngx.log(ngx.WARN, 'A received cookie had invalid format')
        return nil
    end

    offset = 1 + VERSION_SIZE
    local iv_bytes = string.sub(all_bytes, offset, VERSION_SIZE + GCM_IV_SIZE)
  
    offset = 1 + VERSION_SIZE + GCM_IV_SIZE
    local ciphertext_bytes = string.sub(all_bytes, offset, #all_bytes - GCM_TAG_SIZE)

    offset = #all_bytes - GCM_TAG_SIZE + 1
    local tag_bytes = string.sub(all_bytes, offset)

    local cipher = cipher.new('aes-256-gcm')
    local decrypted_cookie, err = cipher:decrypt(encryption_key_bytes, iv_bytes, ciphertext_bytes, true, nil, tag_bytes)
    if err then
        ngx.log(ngx.WARN, 'Error decrypting cookie: ' .. err)
        return nil
    end

    return decrypted_cookie
end

--
-- The public entry point to decrypt a secure cookie from SPAs and forward the contained access token
--
function _M.run(config)

    -- Start by validating configuration
    if initialize_configuration(config) == false then 
        server_error_response(config)
        return
    end

    -- Pre-flight requests cannot contain cookies, so add CORS headers and return
    local method = ngx.req.get_method():upper()
    if method == 'OPTIONS' then
        if config.cors_enabled then
            add_cors_response_headers(config, false)
            ngx.exit(200)
        end
        return
    end

    -- Next get the encryption key as bytes
    local encryption_key_bytes = get_encryption_key_bytes(config)
    if not encryption_key_bytes then
        server_error_response(config)
        return
    end

    -- If there is already a bearer token, eg for mobile clients, return immediately
    -- Note that the target API must always digitally verify the JWT access token
    if config.allow_tokens then
        local auth_header = ngx.var.http_authorization
        if auth_header and string.len(auth_header) > 7 and string.lower(string.sub(auth_header, 1, 7)) == 'bearer ' then
            return
        end
    end

    -- For cookie requests, verify the web origin in line with OWASP CSRF best practices
    local web_origin = ngx.req.get_headers()['origin']
    if not web_origin or not array_has_value(config.trusted_web_origins, web_origin) then
        ngx.log(ngx.WARN, 'The request was from an untrusted web origin')
        unauthorized_request_error_response(config)
        return
    end

    -- For data changing requests do double submit cookie verification in line with OWASP CSRF best practices
    if method == 'POST' or method == 'PUT' or method == 'DELETE' or method == 'PATCH' then

        local csrf_cookie_name = 'cookie_' .. config.cookie_name_prefix .. '-csrf'
        local csrf_cookie = ngx.var[csrf_cookie_name]
        if not csrf_cookie then
            ngx.log(ngx.WARN, 'No CSRF cookie was sent with the request')
            unauthorized_request_error_response(config)
            return
        end

        local csrf_token = decrypt_cookie(csrf_cookie, encryption_key_bytes)
        if not csrf_token then
            ngx.log(ngx.WARN, 'Error decrypting CSRF cookie')
            unauthorized_request_error_response(config)
            return
        end
        
        local csrf_header = ngx.req.get_headers()[get_csrf_header_name(config)]
        if not csrf_header or csrf_header ~= csrf_token  then
            ngx.log(ngx.WARN, 'Invalid or missing CSRF request header')
            unauthorized_request_error_response(config)
            return
        end
    end

    -- Next verify that the main cookie was received and get the access token
    local at_cookie_name = 'cookie_' .. config.cookie_name_prefix .. '-at'
    local at_cookie = ngx.var[at_cookie_name]
    if not at_cookie then
        ngx.log(ngx.WARN, 'No access token cookie was sent with the request')
        unauthorized_request_error_response(config)
        return
    end

    -- Decrypt the access token cookie, which is encrypted using AES256
    local access_token = decrypt_cookie(at_cookie, encryption_key_bytes)
    if not access_token then
        ngx.log(ngx.WARN, 'Error decrypting access token cookie')
        unauthorized_request_error_response(config)
        return
    end

    -- Set the request header to supply the access token to the next plugin or the target API
    ngx.req.set_header('authorization', 'Bearer ' .. access_token)

    -- Clear headers of no interest to the target API
    if config.remove_cookie_headers then
        ngx.req.clear_header('cookie')
        local csrf_header_name = get_csrf_header_name(config)
        if csrf_header_name then
            ngx.req.clear_header(csrf_header_name)
        end
    end

    -- CORS headers must also be added for the main API request
    if config.cors_enabled then
        add_cors_response_headers(config, false)
    end
end

return _M
