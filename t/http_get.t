#!/usr/bin/perl

#######################################################################
# Runs unit tests to verify security behavior from a client's viewpoint
#######################################################################

use strict;
use warnings;
use Test::Nginx::Socket 'no_plan';

SKIP: {
    our $at_opaque = "42665300-efe8-419d-be52-07b53e208f46";
    our $at_opaque_cookie = "AcYBf995tTBVsLtQLvOuLUZXHm2c-XqP8t7SKmhBiQtzy5CAw4h_RF6rXyg6kHrvhb8x4WaLQC6h3mw6a3O3Q9A";
    run_tests();
}

__DATA__

=== TEST HTTP_GET_1: GET with an authorization header is allowed when enabled
# Verify that mobile and SPA clients can use the same routes, where the first sends access tokens directly

--- config
location /t {

    rewrite_by_lua_block {

        local config = {
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            cookie_name_prefix = 'example',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true,
            allow_tokens = true
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

--- request
GET /t

--- more_headers
authorization: bearer xxx

--- error_code: 200

=== TEST HTTP_GET_7: GET with a valid cookie returns 200 and an Authorization header
# Ensure that the happy path for a GET request works

--- config
location /t {
    
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'mycompany-myproduct',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true,
            allow_tokens = true
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

--- request
GET /t

--- more_headers eval
my $data;
$data .= "origin: http://www.example.com\n";
$data .= "cookie: mycompany-myproduct-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 200

--- response_headers eval
"authorization: Bearer " . $main::at_opaque