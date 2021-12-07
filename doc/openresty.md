# OpenResty Setup

This briefly shows how to deploy and test the plugin to OpenResty using Docker Desktop.

## Configure the Plugin

The `deploy/openresty/nginx.conf` file configures the plugin with these details for testing:

```text
rewrite_by_lua_block {

    local config = {
        encryption_key = 'NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP',
        cookie_name_prefix = 'example',
        trusted_web_origins = {
            'http://www.example.com'
        }
    }

    local bffToken = require 'bff-token-plugin'
    bffToken.run(config)
}
```

## Deploy the System

Run these commands to deploy a small Docker Compose system containing OpenResty, a tiny API and the plugin:

```bash
cd test
./deploy.sh
```

Then connect to the API at http://localhost:3000, which will initially return an unauthorized error:

```json
{
  "code":"unauthorized",
  "message":"The request failed cookie authorization"
}
```

## Test the Plugin

Next run some simple curl based tests to verify the routing through to the API:

```bash
cd ../test
./test.sh
```

This will output some details to visualize the technical behavior:

```json
TODO
```
