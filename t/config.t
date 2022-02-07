#!/usr/bin/perl

###########################################################
# Runs tests related to configuration and defaulting values
###########################################################

use strict;
use warnings;
use Test::Nginx::Socket 'no_plan';

SKIP: {
    our $at_opaque = "42665300-efe8-419d-be52-07b53e208f46";
    our $at_opaque_cookie = "AcYBf995tTBVsLtQLvOuLUZXHm2c-XqP8t7SKmhBiQtzy5CAw4h_RF6rXyg6kHrvhb8x4WaLQC6h3mw6a3O3Q9A";
    run_tests();
}

__DATA__

=== TEST CONFIG_1: A deployment with empty configuration does not crash NGINX
######################################################################################################
# Verify that null configuration is handled in a controller manner rather than causing server problems
######################################################################################################

--- config
location /t {
    rewrite_by_lua_block {
        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(nil)
    }
}

--- request
GET /t

--- error_code: 500

--- error_log
The OAuth proxy configuration is invalid and must be corrected

--- response_body_like chomp
{"code":"server_error", "message":"Problem encountered processing the request"}

=== TEST CONFIG_2: A deployment with missing data does not crash NGINX
#######################################################################################################
# Verify that empty configuration is handled in a controller manner rather than causing server problems
#######################################################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
        }
        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- error_code: 500

--- error_log
The OAuth proxy configuration is invalid and must be corrected

--- response_body_like chomp
{"code":"server_error", "message":"Problem encountered processing the request"}

=== TEST CONFIG_3: A deployment with a misspelt field does not crash NGINX
#####################################################################################################
# Verify that bad configuration is handled in a controller manner rather than causing server problems
#####################################################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefixxx = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }
        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- error_code: 500

--- error_log
The OAuth proxy configuration is invalid and must be corrected

=== TEST CONFIG_4: A deployment with the wrong encryption key size does not crash NGINX
######################################################################
# Verify that an invalid encryption key does not cause server problems
######################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = 'e4636356d65563e4c73233847503e3b2',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }
        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- more_headers eval
my $data;
$data .= "origin: http://www.example.com\n";
$data .= "cookie: example-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 500

--- error_log
The encryption key must be supplied as 64 hex characters

--- response_body_like chomp
{"code":"server_error", "message":"Problem encountered processing the request"}

=== TEST CONFIG_5: A deployment with invalid hex characters does not crash NGINX
######################################################################
# Verify that an invalid encryption key does not cause server problems
######################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = ')-4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }
        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- more_headers eval
my $data;
$data .= "origin: http://www.example.com\n";
$data .= "cookie: example-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 500

--- error_log
The encryption key contains invalid hex characters

--- response_body_like chomp
{"code":"server_error", "message":"Problem encountered processing the request"}

=== TEST CONFIG_6: CORS can be disabled and handled in API code instead
###########################################################
# Verify that when cors_enabled is false it does not return any CORS headers
###########################################################

--- config
location /t {
    
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = false
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
$data .= "cookie: example-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 200

--- response_headers
access-control-allow-origin:
access-control-allow-credentials:

=== TEST CONFIG_7: CORS headers can be customized
############################################################################
# Verify that different CORS headers can be configured, to override defaults
############################################################################

--- config
location /t {
    
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
            },
            cors_enabled = true,
            cors_allow_methods = {
                'OPTIONS', 'GET'
            },
            cors_allow_headers = {
                'myallowedheader1', 'myallowedheader2'
            },
            cors_expose_headers = {
                'myexposedheader'
            },
            cors_max_age = 600
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
$data .= "origin: https://www.example.com\n";
$data .= "cookie: example-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 200

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
vary: origin
