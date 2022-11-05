defmodule FileWatch.Application do
  use Application

  import FileWatch.MixProject, only: [escript_file_name: 0]

  @config_file_name ".#{escript_file_name()}.exs"
  @wrapper_file_name ".#{escript_file_name()}.sh"
  @wrapper_content File.read!(Path.join("priv", @wrapper_file_name))

  def start(_type, _args) do
    create_wrapper_file()
    FileWatch.Config.read!(config_file_path())
    configure_logger()

    children = [FileWatch.FsSubscriber]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def config_file_path() do
    Path.join(File.cwd!(), @config_file_name)
  end

  def wrapper_file_path() do
    Path.join(File.cwd!(), @wrapper_file_name)
  end

  defp create_wrapper_file() do
    path = Path.join(File.cwd!(), @wrapper_file_name)
    File.write!(path, @wrapper_content)
    File.chmod!(path, 0o775)
  end

  defp configure_logger() do
    Application.get_all_env(:logger)
    |> Logger.configure()
  end
end