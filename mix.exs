defmodule FileWatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_watch,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: FileWatch, name: escript_file_name()]
    ]
  end

  def escript_file_name(), do: "fwatch"

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FileWatch.Application, []},
      extra_applications: [:logger, :file_system]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
