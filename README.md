# Kong Back End for Front End (BFF) Plugin

[![Quality](https://img.shields.io/badge/quality-experiment-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

A LUA plugin that acts as an `OAuth Proxy` when implementing the [Token Handler Pattern](https://curity.io/resources/learn/the-token-handler-pattern) for SPAs.

- This enables an SPA to use only secure `SameSite=strict` cookies during API calls
- The plugin translates cookies to tokens so that APIs receive JWTs in the standard way

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
| Encryption Key | The encryption key used by the BFF API to create AES256 encrypted SameSite cookies |
| Cookie Name Prefix | The prefix used in the SPA's cookie name, typically representing a company or product |
| Trusted Web Origins | The web origins from which the OAuth Proxy will accept requests |

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
