import Config

config :file_watch,
  commands: [
    "echo -e \"  using default config file,\n  modify CWD/.fwatch.exs to fit your use case. 👀\n\""
  ],
  patterns: [~r".*"],
  debounce: 100

config :logger,
  level: :none
