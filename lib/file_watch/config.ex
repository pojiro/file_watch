defmodule FileWatch.Config do
  @moduledoc false
  import FileWatch.MixProject, only: [project: 0, escript_file_name: 0]

  @app_atom Keyword.fetch!(project(), :app)
  @config_file_name ".#{escript_file_name()}.exs"
  @template_content File.read!(Path.join("priv", @config_file_name))

  @type t :: %__MODULE__{
          patterns: list(),
          debounce: non_neg_integer(),
          dirs: [String.t()],
          commands: [String.t()]
        }
  defstruct patterns: [], debounce: 0, dirs: [""], commands: [":"]

  @spec create_template() :: :ok
  def create_template() do
    FileWatch.Assets.config_file_path()
    |> FileWatch.Config.create_template()
  end

  @spec create_template(path :: String.t()) :: :ok
  def create_template(path) do
    lines =
      if File.exists?(path) do
        ["config file is already exists."]
      else
        File.write!(path, @template_content)

        ["The template is generated under CWD with the name `#{@config_file_name}`."]
      end

    lines |> highlight() |> IO.puts()
  end

  @spec get(list()) :: __MODULE__.t()
  def get(config) do
    config = Keyword.get(config, @app_atom, nil)

    if is_nil(config) do
      %__MODULE__{}
    else
      struct(__MODULE__, config)
    end
  end

  @spec read() :: {:ok, keyword()} | :error
  def read() do
    FileWatch.Assets.config_file_path() |> read()
  end

  @spec read(path :: String.t()) :: {:ok, keyword()} | :error
  def read(path) do
    {:ok, Config.Reader.read!(path)}
  rescue
    File.Error ->
      error_lines = [
        "Please check following file exists in CWD",
        "path: #{path}",
        "Or use `--config-template` option to get it."
      ]

      error_lines |> highlight() |> IO.puts()
      :error
  end

  defp highlight(lines) do
    """
    \n\s\s#{Enum.join(lines, "\n\s\s")}
    """
  end
end
