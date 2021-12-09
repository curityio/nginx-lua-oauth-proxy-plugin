return {
    name = "oauth-proxy",
    fields = {{
        config = {
            type = "record",
            fields = {
                { encryption_key = { type = "string", required = true } },
                { cookie_name_prefix = { type = "string", required = false, default = "oauth" } },
                { trusted_web_origins = { type = "array", required = false, default = {}, elements = { type = "string" } } },
            }
        }}
    }
}
