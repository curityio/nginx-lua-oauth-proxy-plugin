#!/usr/bin/perl

##########################################################################
# Runs OPTIONS tests to verify security behavior from a client's viewpoint
##########################################################################

use strict;
use warnings;
use Test::Nginx::Socket 'no_plan';

SKIP: {
    run_tests();
}

__DATA__

=== TEST HTTP_OPTIONS_1: OPTIONS without CORS returns no headers
#########################################################################
# Ensure that CORS headers can be handled by an API when CORS is disabled
#########################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.example.com'
            },
            cors_enabled = false
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }

    proxy_pass http://localhost:1984/target;
}
location /target {
    add_header 'access-control-allow-origin' '*';
    return 200;
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 200

--- response_headers
access-control-allow-origin: *

=== TEST HTTP_OPTIONS_2: OPTIONS with CORS and untrusted origin returns no CORS headers
###################################################################
# Ensure that CORS headers do not grant access to untrusted origins
###################################################################

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
OPTIONS /t

--- more_headers
origin: https://www.malicious-site.com

--- error_code: 204

--- response_headers
access-control-allow-origin:
access-control-allow-credentials:
access-control-allow-methods:
access-control-allow-headers:
access-control-expose-headers:
access-control-max-age:
vary:

=== TEST HTTP_OPTIONS_3: OPTIONS with CORS and valid origin returns expected default headers
######################################################################
# Ensure that CORS headers are correctly returned for a trusted origin
######################################################################

--- config
location /t {
    rewrite_by_lua_block {

        local config = {
            cookie_name_prefix = 'example',
            encryption_key = '4e4636356d65563e4c73233847503e3b21436e6f7629724950526f4b5e2e4e50',
            trusted_web_origins = {
                'https://www.other.com',
                'https://www.example.com'
            },
            cors_enabled = true
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE
access-control-allow-headers:
access-control-expose-headers:
access-control-max-age: 86400
vary: origin,access-control-request-headers

=== TEST HTTP_OPTIONS_4: OPTIONS with runtime headers returns those requested by the SPA
###########################################################################################################
# Ensure that CORS runtime headers are correctly allowed by the OAuth proxy, when default settings are used
###########################################################################################################

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
OPTIONS /t

--- more_headers eval
my $data;
$data .= "origin: https://www.example.com\n";
$data .= "access-control-request-headers: x-example-csrf, first, second\n";
$data;

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE
access-control-allow-headers: x-example-csrf,first,second
access-control-expose-headers:
access-control-max-age: 86400
vary: origin,access-control-request-headers

=== TEST HTTP_OPTIONS_5: OPTIONS with custom allowed methods returns expected headers
#####################################################################
# Ensure that custom CORS allow methods can be returned if configured
#####################################################################

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
                'GET',
                'POST'
            }
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: GET,POST
access-control-allow-headers:
access-control-expose-headers:
access-control-max-age: 86400
vary: origin,access-control-request-headers

=== TEST HTTP_OPTIONS_6: OPTIONS with custom allowed headers returns expected headers
#####################################################################
# Ensure that custom CORS allow headers can be returned if configured
#####################################################################

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
            cors_allow_headers = {
                'x-example-csrf',
                'other'
            }
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE
access-control-allow-headers: x-example-csrf,other
access-control-expose-headers:
access-control-max-age: 86400
vary: origin

=== TEST HTTP_OPTIONS_7: OPTIONS with custom expose headers returns expected headers
######################################################################
# Ensure that custom CORS expose headers can be returned if configured
######################################################################

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
            cors_expose_headers = {
                'first',
                'second'
            }
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE
access-control-allow-headers:
access-control-expose-headers: first,second
access-control-max-age: 86400
vary: origin,access-control-request-headers

=== TEST HTTP_OPTIONS_8: OPTIONS with custom max age returns expected headers
###############################################################
# Ensure that custom CORS max age can be returned if configured
###############################################################

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
            cors_max_age = 600
        }

        local oauthProxy = require 'oauth-proxy'
        oauthProxy.run(config)
    }
}

--- request
OPTIONS /t

--- more_headers
origin: https://www.example.com

--- error_code: 204

--- response_headers
access-control-allow-origin: https://www.example.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE
access-control-allow-headers:
access-control-expose-headers:
access-control-max-age: 600
vary: origin,access-control-request-headers