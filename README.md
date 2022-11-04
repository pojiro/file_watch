# EsWatch

Automatically run your commands each time you save a file.

Because TDD with [mix test.watch](https://github.com/lpil/mix-test.watch) is awesome🎉

## TODO

- [x] デーモン系コマンドを再起動できるようにする
- [ ] README.md の記述
- [ ] credo の追加
- [ ] test の実装
- [ ] moduledoc 等の追加
- [ ] ライセンス選択
- [x] phoenix_live_reload と mix_test_watch への謝辞
- [x] copyright 付ける

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `es_watch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:es_watch, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/es_watch](https://hexdocs.pm/es_watch).

## Acknowledgment

EsWatch uses or refs the following OSS and so on,

- uses [FileSystem](https://github.com/falood/file_system) for detecting file has been touched
- refs [mix test.watch](https://github.com/lpil/mix-test.watch) for architecture
- refs [Provides live-reload](https://github.com/phoenixframework/phoenix_live_reload) for debounce

## Copyright

EsWatch

Copyright © 2022 Ryota Kinukawa
