return {
    name = "oauth-proxy",
    fields = {{
        config = {
            type = "record",
            fields = {
                { cookie_name_prefix = { type = "string", required = true } },
                { encryption_key = { type = "string", required = true } },
                { trusted_web_origins = { type = "array", required = true, default = {}, elements = { type = "string" } } },
                { allow_tokens = { type = "boolean", required = false, default= false } },
                { cors_enabled = { type = "boolean", required = true, default = true } },
                { cors_allowed_methods = { type = "array", required = false, default = {}, elements = { type = "string" } } },
                { cors_allowed_headers = { type = "array", required = false, default = {}, elements = { type = "string" } } },
                { cors_exposed_headers = { type = "array", required = false, default = {}, elements = { type = "string" } } },
                { cors_max_age = { type = "number", required = false } }
            }
        }
    }}
}
