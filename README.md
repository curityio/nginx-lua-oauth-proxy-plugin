# Kong BFF Token Plugin

[![Quality](https://img.shields.io/badge/quality-experiment-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

A LUA plugin to demonstrate how to handle translation from secure SameSite cookies to access tokens.\
This is used within a wider `Back End for Front End` solution when the SPA makes calls to APIs.

## Configuration

The plugin is configured with properties in the following manner:

```yaml
plugins:
  - name: bff-token
    config:
      encryption_key: NF65meV>Ls#8GP>;!Cnov)rIPRoK^.NP
      cookie_name_prefix: example
      trusted_web_origin: http://www.example.com
```

| Property | Description |
| -------- | ----------- |
| Encryption Key | The encryption key used by the BFF API to create AES256 encrypted SameSite cookies |
| Cookie Name Prefix | The prefix used in the SPA's cookie name, typically representing a company or product |
| Trusted Web Origin | The web origin from which the BFF will accept secure cookies |

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
