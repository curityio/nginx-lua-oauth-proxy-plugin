# Development and Testing

The information here is mostly of interest to Curity developers who code the plugin.\
If you are interested in extending the plugin, the same instructions can be followed.

## Prerequisites

First install OpenResty and the Perl test framework as prerequisites:

```bash
brew install openresty/brew/openresty
cpan Test::Nginx
```

Then add a path of this form to the PATH in `.zprofile`.\
This will ensure that the first nginx command in the PATH has LUA support.

```text
/usr/local/Cellar/openresty/1.19.9.1_2/nginx/sbin
```

## Run Unit Tests

Whenever the plugin code changes, copy the latest plugin to the `lualib` folder.\
The `prove` utility can then be run to execute tests in the project's `t` folder:

```bash
cp plugin/plugin.lua /usr/local/Cellar/openresty/1.19.9.1_2/lualib/oauth-proxy.lua
prove -v
```

## Understand Test Behavior

Each test spins up an instance of NGINX under the `t/servroot` folder which runs on the default test port of 1984.\
Tests that are expected to succeed use proxy_pass to route to a target that runs after the module and simply returns:

```nginx
location /t {
    rewrite_by_lua_block {

        local config = {
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            cookie_name_prefix = 'example',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
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
If required, add `ngx_log_error` statements to C code, then look at test logs at `t/servroot/logs/error.log`.\
If you get cryptic permission errors or locked files, delete the `t/servroot` folder.

## Deploy the Plugin

Run OpenResty and the plugin, with a configuration that toutes to a minimal JWT secured API:

```bash
./docker/deploy.sh openresty
```

Or run Kong and the plugin, with a configuration that toutes to a minimal REST API:

```bash
./docker/deploy.sh kong
```

Call the API at http://localhost:3000, which will initially return an unauthorized error.\
The gateway logs are visible in the terminal window for troubleshooting.

## Run HTTP Tests

Next run some curl based tests in another terminal window:

```bash
./docker/test.sh
```

To troubleshoot failures, see the `docker/response.txt` file and the gateway logs.