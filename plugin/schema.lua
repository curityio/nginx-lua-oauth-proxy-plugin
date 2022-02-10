--
-- The Kong schema definition
--

return {
    name = "oauth-proxy",
    fields = {{
        config = {
            type = "record",
            fields = {
                { cookie_name_prefix = { type = "string", required = true } },
                { encryption_key = { type = "string", required = true } },
                { trusted_web_origins = { type = "array", required = true, elements = { type = "string" } } },
                { cors_enabled = { type = "boolean", required = true } },
                { cors_allow_methods = { type = "array", required = false, elements = { type = "string" } } },
                { cors_allow_headers = { type = "array", required = false, elements = { type = "string" } } },
                { cors_expose_headers = { type = "array", required = false, elements = { type = "string" } } },
                { cors_max_age = { type = "number", required = false } },
                { allow_tokens = { type = "boolean", required = false } },
                { remove_cookie_headers = { type = "boolean", required = false } }
            }
        }
    }}
}
