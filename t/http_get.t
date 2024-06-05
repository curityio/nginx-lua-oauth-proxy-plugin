#!/usr/bin/perl

#########################################################################
# Runs unit tests to verify CORS and GET requests from a client viewpoint
#########################################################################

use strict;
use warnings;
use Test::Nginx::Socket 'no_plan';

SKIP: {
    our $at_opaque = "42665300-efe8-419d-be52-07b53e208f46";
    our $at_opaque_cookie = "AcYBf995tTBVsLtQLvOuLUZXHm2c-XqP8t7SKmhBiQtzy5CAw4h_RF6rXyg6kHrvhb8x4WaLQC6h3mw6a3O3Q9A";
    run_tests();
}

__DATA__

=== TEST HTTP_GET_1: GET without an origin header returns 401
#################################################################################################
#  SPA clients are expected to always send the origin header, as supported by all modern browsers
#################################################################################################

--- config
location /t {

    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- error_code: 401

--- error_log
The request was from an untrusted web origin

=== TEST HTTP_GET_2: GET with an untrusted origin header returns 401
###############################################################################################
# Only trusted SPA clients should be able to get data from the browser due to CORS restrictions
###############################################################################################

--- config
location /t {

    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- more_headers
origin: https://www.malicious-site.com

--- error_code: 401

--- error_log
The request was from an untrusted web origin

=== TEST HTTP_GET_3: GET without a cookie or token credential returns 401
##########################################################################################
# Verify that a 401 is received when there is no message credential at all sent to the API
##########################################################################################

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
            allow_tokens = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- more_headers
origin: https://www.example.com

--- error_code: 401

--- error_log
No access token cookie was sent with the request

=== TEST HTTP_GET_4: GET with an invalid cookie returns 401
#####################################################################################
# Verify that a 401 is received when there is an obviously invalid message credential
#####################################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
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
$data .= "origin: https://www.example.com\n";
$data .= "cookie: example-at=xxx";
$data;

--- error_code: 401

--- error_log
A received cookie had an invalid length

=== TEST HTTP_GET_5: GET returns correct CORS response headers with plugin errors
#################################################################################
# Verify that when a 401 is received the SPA can read details due to CORS headers
#################################################################################

--- config
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

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
GET /t

--- more_headers eval
my $data;
$data .= "origin: http://www.example.com\n";
$data .= "cookie: example-at=";
$data;

--- error_code: 401

--- response_headers
access-control-allow-origin: http://www.example.com
access-control-allow-credentials: true

=== TEST HTTP_GET_6: GET with a valid cookie returns 200 and an Authorization header
##################################################################
# Ensure that GET requests work as expected with the correct input
##################################################################

--- config
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

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
    
    proxy_pass http://127.0.0.1:1984/target;
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

--- response_headers eval
"authorization: Bearer " . $main::at_opaque

=== TEST HTTP_GET_7: GET with a valid request and CORS enabled returns the correct CORS response headers
#######################################################################
# Ensure that CORS headers are returned correctly for success responses
#######################################################################
--- config
location /t {
    
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'mycompany-myproduct',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'http://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
    
    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
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

--- response_headers
access-control-allow-origin: http://www.example.com
access-control-allow-credentials: true
vary: origin

=== TEST HTTP_GET_8: GET with a valid request and CORS disabled does not return CORS response headers
###########################################################################
# Ensure that CORS headers can be handled by an API and not the OAuth proxy
###########################################################################
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
    
    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
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
vary:

=== TEST HTTP_GET_9: GET with a valid request removes cookie related headers when forwarding to the API
#########################################################################
# Ensure that the API only receives a JWT and does not know about cookies
#########################################################################
--- config
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

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
    
    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
    add_header 'cookie' $http_cookie;
    add_header 'x-example-csrf' $http_x-example-csrf;
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

--- reponse_headers
cookie:
x-example-csrf:

=== TEST HTTP_GET_10: GET with a valid request passes cookie headers through to the API when required
########################################################
# Ensure that the API can receive cookies if ever needed
########################################################
--- config
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

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
    
    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
    add_header 'cookie' $http_cookie;
    add_header 'x-example-csrf' $http_x-example-csrf;
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

--- reponse_headers eval
cookie: $main::at_opaque_cookie

=== TEST HTTP_GET_11: GET with a bearer token is allowed when enabled
##########################################################################################################
# Verify that mobile and SPA clients can use the same routes, where the first sends access tokens directly
##########################################################################################################

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
            allow_tokens = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }

    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
    add_header 'authorization' $http_authorization;
    return 200;
}

--- request
GET /t

--- more_headers
origin: https://www.example.com
authorization: Bearer xxx

--- error_code: 200

--- reponse_headers
authorization: Bearer xxx

=== TEST HTTP_GET_12: GET with a bearer token is denied when not enabled
#######################################################################################################
# Verify that if a company wants to force mobile and SPA clients to use different routes they can do so
#######################################################################################################

--- config
location /t {

    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }

    proxy_pass http://127.0.0.1:1984/target;
}

--- request
GET /t

--- more_headers
origin: https://www.example.com
authorization: Bearer xxx

--- error_code: 401

--- error_log
No access token cookie was sent with the request

=== TEST HTTP_GET_13: Same origin GET with a valid cookie returns 200 and an Authorization header
#########################################################################################################
# Ensure that GET requests work as expected when same domain hosting is used and no origin header is sent
#########################################################################################################

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
    
    proxy_pass http://127.0.0.1:1984/target;
}
location /target {
    add_header 'authorization' $http_authorization;
    return 200;
}

--- request
GET /t

--- more_headers eval
my $data;
$data .= "cookie: example-at=" . $main::at_opaque_cookie . "\n";
$data;

--- error_code: 200

--- response_headers eval
"authorization: Bearer " . $main::at_opaque