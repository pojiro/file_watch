defmodule FileWatch.MixProject do
  use Mix.Project

  @source_url "https://github.com/pojiro/file_watch"

  def project do
    [
      app: :file_watch,
      version: version(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: FileWatch, name: escript_file_name()],
      description: description(),
      package: package()
    ]
  end

  def version(), do: "0.1.2"
  def escript_file_name(), do: "fwatch"
  def description(), do: "File Watcher 👀, like mix test.watch."

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :file_system]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "priv",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "LICENSE"
      ]
    ]
  end
end
