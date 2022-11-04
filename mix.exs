defmodule MixTomboWatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_tombo_watch,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: MixTomboWatch]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MixTomboWatch.Application, []},
      extra_applications: [:logger, :file_system]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 0.2"}
    ]
  end
end
