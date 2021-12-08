# OpenResty Setup

This briefly shows how to deploy and test the plugin to OpenResty using Docker Desktop.\
Equivalent steps can be followed for other NGINX setups with the LUA module enabled.

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
