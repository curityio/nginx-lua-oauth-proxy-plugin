# Development and Testing

The information here is mostly of interest to Curity developers who code the plugin.\
If you are interested in extending the plugin, the same instructions can be followed.

## Run Unit Tests

First install OpenResty and the Perl test framework as prerequisites:

```bash
brew install openresty/brew/openresty
cpan Test::Nginx
```

This will make the `prove` utility available, after which tests can be run.\
Run this command to execute all tests in the `t` folder:

```bash
prove -v
```

## Understand Test Behavior

Each test spins up an instance of NGINX under the `t/servroot` folder which runs on the default test port of 1984.\
Tests that are expected to succeed use proxy_pass to route to a target that runs after the module and simply returns:

```nginx
location /t {
    oauth_proxy on;
    oauth_proxy_allow_tokens off;
    oauth_proxy_cookie_prefix "mycompany-myproduct";
    oauth_proxy_hex_encryption_key "4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50";
    oauth_proxy_trusted_web_origin "https://www.example.com";
    
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