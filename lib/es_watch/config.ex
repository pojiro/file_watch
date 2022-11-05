defmodule FileWatch.Config do
  import FileWatch.MixProject, only: [project: 0]

  @app_atom Keyword.fetch!(project(), :app)

  @type t :: %__MODULE__{
          patterns: list(),
          debounce: non_neg_integer(),
          dirs: [String.t()],
          commands: [String.t()]
        }
  defstruct patterns: [], debounce: 0, dirs: [""], commands: [":"]

  @spec get!() :: FileWatch.Config.t()
  def get!() do
    config = Application.get_all_env(@app_atom)

    if Enum.empty?(config) do
      Mix.raise("""
      Please check #{inspect(@app_atom)} config exists in
      #{FileWatch.Application.config_file_path()}
      """)
    end

    struct(FileWatch.Config, config)
  end

  @spec read!(path :: String.t()) :: :ok
  def read!(path) do
    path
    |> Config.Reader.read!()
    |> Application.put_all_env()
  rescue
    File.Error ->
      Mix.raise("""
      Please check following file exists in CWD
      #{FileWatch.Application.config_file_path()}
      """)
  end
end
