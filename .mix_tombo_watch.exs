import Config

config :mix_tombo_watch,
  commands: ["echo hello", "echo world", "mix test"],
  patterns: [~r"lib/.*(ex)$"],
  debounce: 50
