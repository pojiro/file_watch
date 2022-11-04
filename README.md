# EsWatch

Automatically run your commands each time you save a file.

Because TDD with [mix test.watch](https://github.com/lpil/mix-test.watch) is awesome🎉

## TODO

- [ ] README.md の記述
- [ ] test の実装
- [ ] moduledoc 等の追加
- [ ] ライセンス選択
- [ ] hex publish

## Installation

```
# clone this repo
$ git clone https://github.com/pojiro/es_watch.git
$ cd es_watch
$ mix do escript.build, escript.install

# or
$ mix escript.install github pojiro/es_watch

# if you use asdf, both of above don't forget to do
$ asdf reshim
```

## Acknowledgment

EsWatch uses or refs the following OSS and so on,

- uses [FileSystem](https://github.com/falood/file_system) for detecting file has been touched
- refs [mix test.watch](https://github.com/lpil/mix-test.watch) for architecture
- refs [Provides live-reload](https://github.com/phoenixframework/phoenix_live_reload) for debounce

## Copyright

EsWatch

Copyright © 2022 Ryota Kinukawa
