local _M = { conf = {} }
local ck = require "resty.cookie"
local aes = require "resty.aes"
local string = require "string"
local table = require "table"

--
-- Return errors due to invalid token cookie
--
local function error_response(status, code, message)

    local jsonData = '{"code":"' .. code .. '", "message":"' .. message .. '"}'
    ngx.status = status
    ngx.header['content-type'] = 'application/json'
    ngx.say(jsonData)
    ngx.exit(status)
end

--
-- Return a generic message for all three of these error categories
--
local function invalid_cookie_error_response()
    error_response(ngx.HTTP_UNAUTHORIZED, "unauthorized", "Missing or invalid bff cookie")
end

local function split(inputstr, sep)
    local result={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(result, str)
    end

    return result
end

local function from_hex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function decrypt_cookie(encrypted_cookie, encryption_key)
    local encrypted = ngx.unescape_uri(encrypted_cookie)

    local parts = split(encrypted, ":")

    local iv = from_hex(parts[1])
    local data = from_hex(parts[2])

    local cipher = aes.cipher(256)
    local aes_256_cbc_md5, err = aes:new(encryption_key, nil, cipher, { iv=iv })

    if err then
        ngx.log(ngx.WARN, "Error creating decipher" .. err)
    end

    return aes_256_cbc_md5:decrypt(data)
end

--
-- The public entry point to decrypt the BFF cookie and then forward the token to the API
--
function _M.run(config)
ngx.log(ngx.INFO, "Request proxied through BFF plugin")
    if ngx.req.get_method() == "OPTIONS" then
        return
    end

    local cookie = ck:new()
    local bff_cookie, err = cookie:get(config.cookie_name_prefix .. "-at")

    if err then
        ngx.log(ngx.WARN, "Error getting BFF cookie - " .. err)
    end

    if not bff_cookie then
        ngx.log(ngx.WARN, "No BFF cookie or invalid cookie sent with request")
        invalid_cookie_error_response()
    end

    local access_token, error = decrypt_cookie(bff_cookie, config.encryption_key)

    if error then
        ngx.log(ngx.WARN, "Error when decrypting BFF cookie - " .. error)
        invalid_cookie_error_response()
    end

    if not access_token then
        ngx.log(ngx.WARN, "Error when decrypting BFF cookie")
        invalid_cookie_error_response()
    end

    ngx.log(ngx.INFO, "Token successfully extracted from encrypted cookie")
    ngx.req.set_header("Authorization", "Bearer " .. access_token)

end

return _M
