return {
    name = "bff-token",
    fields = {{
        config = {
            type = "record",
            fields = {
                { encryption_key = { type = "string", required = true } },
                { cookie_name_prefix = { type = "string", required = false, default = "bff" } },
                { trusted_web_origin = { type = "string", required = true } }
            }
        }}
    }
}
