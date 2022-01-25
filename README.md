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

| Property | Required? | Default Value | Description |
| -------- | --------- | ------------- | ----------- |
| cookie_name_prefix | Yes | N/A | The prefix used in the SPA's cookie name, typically representing a company or product |
| encryption_key | Yes | N/A | The encryption key used by the plugin to decrypt AES256 encrypted SameSite cookies |
| trusted_web_origins | Yes | Empty List | The web origins from which the plugin will accept cookie requests |
| cors_enabled | Yes | true | If set to true, then the OAuth Proxy will provide a default CORS implementation |
| cors_allowed_methods | No | Empty List | The HTTP methods allowed when the SPA calls an API endpoint |
| cors_allowed_headers | No | Empty List | The HTTP request headers the SPA is allowed to send to the API |
| cors_exposed_headers | No | Empty List | The HTTP response headers the SPA's Javascript is allowed to read from the API |
| cors_max_age | No | Not written | The time to live until the next HTTP OPTIONS request to an API endpoint |
| allow_tokens | No | false | If set to true, then requests with a bearer token are passed straight through to APIs |
| remove_cookies | No | true | If set to true, then cookies are removed before forwarding requests to the API |

## Cross Origin Resource Sharing (CORS)

Cross origin permissions for the SPA can be configured per API within the OAuth proxy.\
See the [Mozilla CORS Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) for details on standard behavior:

- CORS headers are only written if the browser sends a trusted value in the `origin` header
- The [access-control-allow-origin](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin) response header allows the SPA's web origin to call the API
- The [access-control-allow-credentials](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials) response header allows the SPA to send secure cookies to the API

If required, such as for finer control of CORS responses per API endpoint, you can set `cors_enabled=false`.\
You will then need to implement CORS within your API technology stack.

## Deployment and Testing

The plugin can run in any NGINX based system with the LUA module enabled.
See the [NGINX LUA OAuth Proxy Plugin](https://curity.io/resources/learn/oauth-proxy-plugin-lua) tutorial for further details.

- [Kong Open Source](/doc/kong.md)
- [OpenResty](/doc/openresty.md)

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
