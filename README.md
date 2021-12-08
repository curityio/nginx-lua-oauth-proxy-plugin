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
- The [OAuth Agent API](https://github.com/curityio/bff-node-express), which issues the secure cookies for the SPA.

## Configuration

The plugin is configured with the following properties and decrypts AES256 encrypted cookies:

| Property | Description |
| -------- | ----------- |
| Encryption Key | The encryption key used by the plugin to decrypt AES256 encrypted SameSite cookies |
| Cookie Name Prefix | The prefix used in the SPA's cookie name, typically representing a company or product |
| Trusted Web Origins | The web origins from which the plugin will accept cookie requests |

## Defining Routes

The plugin allows you to configure reverse proxy routes the same for web and mobile clients of your APIs:

| Client Type |
| ----------- |
| SPA | No authorization header is sent, and one is calculated from secure cookies received |
| Mobile | If an authorization header is received, it is passed straight through to the API |

## Deployment and Testing

The plugin can run in any NGINX based system with the LUA module enabled.
See the [NGINX LUA OAuth Proxy Plugin](https://curity.io/resources/learn/oauth-proxy-plugin-lua) tutorial for further details.

- [Kong Open Source](/doc/kong.md)
- [OpenResty](/doc/openresty.md)

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
