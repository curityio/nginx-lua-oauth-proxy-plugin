# Development and Testing

The information here is mostly of interest to Curity developers who code the plugin.\
If you are interested in extending the plugin, the same instructions can be followed.

## Prerequisites

First install OpenResty and the Perl test framework as prerequisites:

```bash
brew install openresty/brew/openresty
sudo cpan Test::Nginx
```

OpenResty will then point to an nginx instance at a path such as this.

```text
/usr/local/Cellar/openresty/1.19.9.1_2/nginx/sbin
```

## Run Unit Tests

The `prove` utility can then be run to execute tests in the project's `t` folder.\
Ensure that `test.sh` points to the correct OpenResty root location and then run it:

```bash
./test.sh
```

## Understand Test Behavior

Each test spins up an instance of NGINX under the `t/servroot` folder which runs on the default test port of 1984.\
Tests that are expected to succeed use proxy_pass to route to a target that runs after the module and simply returns.\
This example returns the decrypted access token as a target API response header, to support assertions.

```nginx
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'resty.oauth-proxy'
        oauthProxy.run(config)
    }
    
    proxy_pass http://localhost:1984/target;
}
location /target {
    add_header 'authorization' $http_authorization;
    return 200;
}
```

## Troubleshoot Failed Tests

If one test out of many is failing, then edit the Makefile to run a single file instead of `*.t`:

```text
prove -v -f t/http_get.t
```

Then add the `ONLY` directive to limit test execution to the single test that is failing:

```text
--- config
location /t {
    ...
}

--- request
GET /t

--- ONLY
```

View the `t/servroot/conf/nginx.conf` file to see the deployed configuration for a test.\
If required, add `ngx_log_error` statements to LUA code, then look at logs at `t/servroot/logs/error.log`.\
If you get cryptic permission errors or locked files, delete the `t/servroot` folder.

## Deploy the Plugin

Run OpenResty and the plugin, with a configuration that routes to a minimal JWT secured API:

```bash
./docker/deploy.sh openresty
```

Or run Kong and the plugin, with a configuration that routes to a minimal REST API:

```bash
./docker/deploy.sh kong
```

Call the API at http://localhost:3000, which will initially return an unauthorized error.\
The gateway logs are visible in the terminal window for troubleshooting.

```curl
AT_COOKIE='AcYBf995tTBVsLtQLvOuLUZXHm2c-XqP8t7SKmhBiQtzy5CAw4h_RF6rXyg6kHrvhb8x4WaLQC6h3mw6a3O3Q9A'
curl -i -X GET http://localhost:3000/api \
-H "origin: http://www.example.com" \
-H "cookie: example-at=$AT_COOKIE"
```

## Run HTTP Tests

Next run some curl based tests in another terminal window:

```bash
./docker/test.sh
```

To troubleshoot failures, see the `docker/response.txt` file and the gateway logs.

## Publishing

Update the tag within each rockspec file to a new version, eg v1.0.2, then rename the rockspec files.\
Then check changes into GitHub, then create a new tag:

```
git tag v1.0.2
git push --tags
```

Login to luarocks.org as curityio and upload the latest rockspec file.\
luarocks install will then work for customers.