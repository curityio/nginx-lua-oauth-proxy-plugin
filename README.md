# Kong Back End for Front End (BFF) Plugin

[![Quality](https://img.shields.io/badge/quality-experiment-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

A LUA plugin that is used during API calls from SPA clients, to forward JWTs to APIs.\
This is part of a `Back End for Front End` solution for SPAs, in line with [best practices for browser based apps](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-browser-based-apps).

## The Token Handler Pattern

The [Token Handler Pattern](https://curity.io/resources/learn/the-token-handler-pattern/) is a modern evolution of a Back End for Front End approach.\
The SPA uses only SameSite encrypted HTTP Only cookies in the browser, and sends them during API requests.\
The plugin performs the role of the `OAuth Proxy` in this solution, to make API calls work seamlessly:

![Logical Components](/images/logical-components.png)

The plugin translates from encrypted cookies to tokens, so that APIs receive JWTs in the standard way.\
See the [Curity OAuth for Web Home Page](https://curity.io/product/token-service/oauth-for-web/) for further details on this pattern.

## Components

The plugin can be used standalone, or in conjunction with the [Phantom Tokem Plugin](https://curity.io/resources/learn/phantom-token-pattern/):

![API Flow](/images/api-flow.png)

See also the following resources:

- The [Example SPA](https://github.com/curityio/web-oauth-via-bff), which acts as a client to the plugin.
- The [OAuth Agent API](https://github.com/curityio/web-oauth-via-bff), which issues the secure cookies for the SPA.

## Configuration

The plugin is configured with properties in the following manner:

```yaml
plugins:
  - name: bff-token
    config:
      encryption_key: NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP
      cookie_name_prefix: example
      trusted_web_origins:
      - http://www.example.com
```

| Property | Description |
| -------- | ----------- |
| Encryption Key | The encryption key used by the plugin to decrypt AES256 encrypted SameSite cookies |
| Cookie Name Prefix | The prefix used in the SPA's cookie name, typically representing a company or product |
| Trusted Web Origins | The web origins from which the plugin will accept requests |

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
