# FileWatch 👀

Automatically run your commands each time you save a file.

Because TDD with [mix test.watch](https://github.com/lpil/mix-test.watch) is awesome🎉

- https://hex.pm/packages/file_watch
- https://hexdocs.pm/file_watch/FileWatch.html

## Usage

### Installation

```
# clone this repo
$ git clone https://github.com/pojiro/file_watch.git
$ cd file_watch
$ mix do escript.build, escript.install

# or
$ mix escript.install github pojiro/file_watch
# or
$ mix escript.install hex file_watch

# if you use asdf, after both of above don't forget to do
$ asdf reshim
```

### Get config template

config template, .fwatch.exs, will be generated under CWD.
configuration details are described in it.

    $ fwatch --config-template

### Start watch

    $ fwatch

## Acknowledgment

FileWatch uses or refs the following OSS and so on,

- uses [FileSystem](https://github.com/falood/file_system) for detecting file has been touched
- refs [mix test.watch](https://github.com/lpil/mix-test.watch) for architecture
- refs [Provides live-reload](https://github.com/phoenixframework/phoenix_live_reload) for debounce

---

Copyright © 2022 Ryota Kinukawa
