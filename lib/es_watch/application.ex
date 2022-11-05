defmodule EsWatch.Application do
  use Application

  import EsWatch.MixProject, only: [escript_file_name: 0]

  @config_file_name ".#{escript_file_name()}.exs"
  @wrapper_file_name ".#{escript_file_name()}.sh"
  @wrapper_content File.read!(Path.join("priv", @wrapper_file_name))

  def start(_type, _args) do
    create_wrapper_file()
    EsWatch.Config.read!(config_file_path())

    children = [EsWatch.FsSubscriber]
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
end
