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

## Configuration

The plugin is configured with the following properties and decrypts AES256 encrypted cookies:

| Property | Required? | Description |
| -------- | --------- | ----------- |
| cookie_name_prefix | Yes | The prefix used in the SPA's cookie name, typically representing a company or product |
| encryption_key | Yes | The encryption key used by the plugin to decrypt AES256 encrypted SameSite cookies |
| allow_tokens | Yes | If set to true, then requests with a bearer token are passed straight through to APIs |
| trusted_web_origins | Yes | The web origins from which the plugin will accept cookie requests |
| cors_enabled | Yes | If set to true, then the OAuth Proxy will provide a default CORS implementation |
| cors_allowed_methods | No | The HTTP methods allowed when the SPA calls an API endpoint |
| cors_allowed_headers | No | The HTTP request headers the SPA is allowed to send to the API |
| cors_exposed_headers | No | The HTTP response headers the SPA is allowed to read from the API |
| cors_max_age | No | The time until the next HTTP OPTIONS request  |

## Cross Origin Resource Sharing

[CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) response headers for the SPA can be managed in the OAuth proxy.\
This keeps cookie concerns out of APIs, and provides the following behavior for each API endpoint:

- CORS headers are only returned if the browser request's `origin` header is trusted
- The [access-control-allow-origin](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin) response header allows the SPA's web origin to call the API
- To allow the browser to send cookies, the [access-control-allow-credentials](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials) response header is returned
- Wildcards are then not allowed in other CORS response headers, such as [access-control-allow-headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers)
- The [access-control-max-age](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age) property is used to reduce the number of subsequent pre-flight requests

## Deployment and Testing

The plugin can run in any NGINX based system with the LUA module enabled.
See the [NGINX LUA OAuth Proxy Plugin](https://curity.io/resources/learn/oauth-proxy-plugin-lua) tutorial for further details.

- [Kong Open Source](/doc/kong.md)
- [OpenResty](/doc/openresty.md)

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
