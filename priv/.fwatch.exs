import Config

config :file_watch,
  dirs: ["."],
  commands: [
    "echo -e \"  using default config file,\n  modify CWD/.fwatch.exs to fit your use case. 👀\n\""
  ],
  # https://hexdocs.pm/elixir/Regex.html
  patterns: [~r".*"],
  debounce: 100

config :logger,
  # use :debug to check matched path and ran command
  level: :none
