# OAuth Proxy Plugin for NGINX LUA Systems

[![Quality](https://img.shields.io/badge/quality-experiment-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

A LUA plugin that is used during API calls from SPA clients, to forward JWTs to APIs.\
This is part of a `Backend for Frontend` solution for SPAs, in line with [best practices for browser based apps](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-browser-based-apps).

## The Token Handler Pattern

The [Token Handler Pattern](https://curity.io/resources/learn/the-token-handler-pattern/) is a modern evolution of a Backend for Frontend approach.\
The SPA uses only SameSite encrypted HTTP Only cookies in the browser, and sends them during API requests.\
This plugin performs the role of an `OAuth Proxy` in this solution, to make API calls work seamlessly:

![Logical Components](/doc/logical-components.png)

The plugin translates from encrypted cookies to tokens, so that APIs receive JWTs in the standard way.\
See the [Curity OAuth for Web Home Page](https://curity.io/product/token-service/oauth-for-web/) for further details on this pattern.

## Components

The plugin can be used standalone, or in conjunction with the [Phantom Token Plugin](https://curity.io/resources/learn/phantom-token-pattern/):

![API Flow](/doc/api-flow.png)

See also the following resources:

- The [Example SPA](https://github.com/curityio/web-oauth-via-bff), which acts as a client to this plugin.
- The [OAuth Agent API](https://github.com/curityio/token-handler-node-express), which issues the secure cookies for the SPA.

## Required Configuration Directives

All of the directives are required for locations where the plugin is enabled.\
The NGINX system will fail to load if the configuration for any locations fail validation:

#### cookie_name_prefix

> **Syntax**: **`cookie_name_prefix`** `string`
>
> **Default**: *``*
>
> **Context**: `location`

The prefix used in the SPA's cookie name, typically representing a company or product name.\
The value supplied must not be empty, and `example` would lead to full cookie names such as `cookie-at`.

#### encryption_key

> **Syntax**: **`encryption_key`** `string`
>
> **Default**: *``*
>
> **Context**: `location`

This must be a 32 byte encryption key expressed as 64 hex characters.\
It is used to decrypt AES256 encrypted secure cookies.\
The key is initially generated with a tool such as `openssl`, as explained in Curity tutorials.

#### trusted_web_origins

> **Syntax**: **`trusted_web_origins`** `string[]`
>
> **Default**: *[]*
>
> **Context**: `location`

A whitelist of at least one web origin from which the plugin will accept requests.\
Multiple origins could be used in special cases where cookies are shared across subdomains.

#### cors_enabled

> **Syntax**: **`cors_enabled`** `boolean`
>
> **Default**: *true*
>
> **Context**: `location`

When enabled, the OAuth proxy implements headers on behalf of the API, to keep CORS out of API code.\
When an origin header is received that is in the trusted_web_origins whitelist, response headers are written.\
The [access-control-allow-origin](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin) header is returned, so that the SPA can call the API.\
The [access-control-allow-credentials](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials) header is returned, so that the SPA can send secured cookies to the API.\
For more fine-grained control over CORS, this can be set to false and CORS can be implemented in the API instead.

## Optional Configuration Directives

#### allow_tokens

> **Syntax**: **`allow_tokens`** `boolean`
>
> **Default**: *false*
>
> **Context**: `location`

If set to true, then requests that already have a bearer token are passed straight through to APIs.\
This can be useful when web and mobile clients share the same API routes.

#### remove_cookie_headers

> **Syntax**: **`remove_cookie_headers`** `boolean`
>
> **Default**: *true*
>
> **Context**: `location`

If set to true, then cookie and CSRF headers are not forwarded to APIs.\
This provides cleaner requests to APIs, which only receive a JWT in the HTTP Authorization header.

#### cors_allowed_methods

> **Syntax**: **`cors_allowed_methods`** `string[]`
>
> **Default**: *[OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE']*
>
> **Context**: `location`

When CORS is enabled, these values are returned in the [access-control-allow-methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods) response header.\
The same value is returned in OPTIONS responses for any API endpoint under the configured location.\
The SPA is then allowed to call a particular API endpoint with those HTTP methods (eg GET, POST).\
A '*' wildcard value should not be configured here, since it will not work with credentialed requests.

#### cors_allowed_headers

> **Syntax**: **`cors_allowed_headers`** `string[]`
>
> **Default**: *['x-example-csrf']*
>
> **Context**: `location`

When CORS is enabled, the plugin returns these values in the [access-contol-allow-headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers) response header.\
Include here any additional [non-safelisted request headers](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_request_header) that the SPA needs to send in API requests.\
The same values are returned in responses for any API endpoint under the configured location.\
To implement POST requests, the values configured should include the CSRF request header name, eg `x-example-csrf`.\
A '*' wildcard value should not be configured here, since it will not work with credentialed requests.

#### cors_exposed_headers

> **Syntax**: **`cors_exposed_headers`** `string[]`
>
> **Default**: *[]*
>
> **Context**: `location`

When CORS is enabled, the plugin returns these values in the [access-contol-expose-headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers) response header.\
Include here any additional [non-safelisted response headers](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_response_header) that the SPA needs to read from API responses.\
The same values are returned in responses for any API endpoint under the configured location.\
A '*' wildcard value should not be configured here, since it will not work with credentialed requests.

#### cors_max_age

> **Syntax**: **`cors_max_age`** `number`
>
> **Default**: *86400*
>
> **Context**: `location`

When CORS is enabled, the plugin returns this value in the [access-contol-max-age](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age) response header.\
When a value is configured, this prevents excessive pre-flight OPTIONS requests to improve efficiency.\
The same value is returned in responses for any API endpoint under the configured location.\

## Deployment and Testing

The plugin can run in any NGINX based system with the LUA module enabled.
See the [NGINX LUA OAuth Proxy Plugin](https://curity.io/resources/learn/oauth-proxy-plugin-lua) tutorial for further details.

- [Kong Open Source](/doc/kong.md)
- [OpenResty](/doc/openresty.md)

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
