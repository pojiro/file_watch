import Config

config :es_watch,
  commands: ["echo hello", "echo world", "mix test"],
  patterns: [~r"lib/.*(ex)$"],
  debounce: 50

config :logger,
  level: :debug
