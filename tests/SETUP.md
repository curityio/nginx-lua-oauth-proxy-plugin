# Basic Plugin Tests

When working on plugins it can be useful to test LUA logic before deploying.

## Development Setup

In order for all LUA NGINX libraries to be available on your system, run one of these commands.\
This may prompt to install XCode command line tools in which case do so.

```bash
brew tap kong/kong
brew install kong
```

```bash
brew tap openresty/brew
brew install openresty
```

Next install unit testing support:

```bash
luarocks install luaunit
```

Use Visual Studio Code as the development IDE and install this extension:

- [Lua language support](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)

## Run Tests

Execute this script to run all tests for the plugin:

```bash
./test.sh
```