defmodule FileWatch.Assets do
  @moduledoc false
  import FileWatch.MixProject, only: [escript_file_name: 0]

  @config_file_name ".#{escript_file_name()}.exs"
  @wrapper_file_name ".#{escript_file_name()}.sh"

  @config_content """
  import Config

  #{File.read!(Path.join("priv", "config.exs")) |> String.trim_trailing()}

  config :logger,
    # use :debug to show matched path and ran command
    #     :none  to suppress logs
    level: :debug

  # On Windows :file_system needs inotifywait.exe,
  # uncomment the following line and configure path to it
  # config :file_system, :fs_windows, executable_file: "path/to/inotifywait.exe"
  """
  @wrapper_content File.read!(Path.join("priv", @wrapper_file_name))

  def config_file_name(), do: @config_file_name

  @spec create_config_file(path :: String.t()) :: :ok
  def create_config_file(path) do
    if File.exists?(path) do
      "config file is already exists."
    else
      File.write!(path, @config_content)
      "#{@config_file_name} is generated under CWD."
    end
    |> FileWatch.highlight()
    |> IO.puts()
  end

  @spec read_config(path :: String.t()) :: {:ok, keyword()} | :error
  def read_config(path) do
    {:ok, Config.Reader.read!(path)}
  rescue
    File.Error ->
      """
      Please check following file exists in CWD,
      path: #{path},
      Or use `--config-template` option to get it.
      """
      |> FileWatch.highlight()
      |> IO.puts()

      :error
  end

  def wrapper_file_name(), do: @wrapper_file_name

  def create_wrapper_file(path) do
    File.write!(path, @wrapper_content)
    File.chmod!(path, 0o775)
  end
end
