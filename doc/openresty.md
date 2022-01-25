# OpenResty Setup

This briefly shows how to deploy and test the plugin to OpenResty using Docker Desktop.\
Equivalent steps can be followed for other NGINX setups with the LUA module enabled.

## Configure the Plugin

The `deploy/openresty/nginx.conf` file configures the plugin with these details for testing:

```text
rewrite_by_lua_block {

    local config = {
        cookie_name_prefix = 'example',
        encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
        allow_tokens = true,
        trusted_web_origins = {
            'http://www.example.com'
        },
        cors_enabled = true,
        cors_allowed_methods = {
            'OPTIONS',
            'GET',
            'POST',
        },
        cors_allowed_headers = {
            'x-example-csrf'
        },
        cors_exposed_headers = {
        },
        cors_max_age = 86400
    }

    local oauthProxy = require 'oauth-proxy'
    oauthProxy.run(config)
}
```

## Deploy the System

Run these commands to deploy a small Docker Compose system containing OpenResty, a tiny API and the plugin:

```bash
cd deploy
./deploy.sh openresty
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

```text
1. Testing OPTIONS request ...
1. OPTIONS request was handled successfully by the plugin
2. Testing POST with no credential ...
2. POST with no credential failed with the expected error
{
  "code": "unauthorized",
  "message": "The request failed cookie authorization"
}
3. Testing POST from mobile client ...
3. POST from mobile client was successfully routed to the API
{
  "accessToken": "678123egd2huor34"
}
4. Testing GET from an untrusted web origin ...
4. GET from an untrusted web origin was handled correctly
{
  "code": "unauthorized",
  "message": "The request failed cookie authorization"
}
5. Testing CORS headers for error responses to the SPA ...
5. CORS error responses to the SPA have the correct headers
6. Testing GET with a valid encrypted cookie ...
6. GET with a valid encrypted cookie was successfully routed to the API
{
  "accessToken": "1234567890"
}
```
