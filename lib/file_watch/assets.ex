defmodule FileWatch.Assets do
  @moduledoc false
  import FileWatch.MixProject, only: [escript_file_name: 0]

  @wrapper_file_name ".#{escript_file_name()}.sh"
  @wrapper_content File.read!(Path.join("priv", @wrapper_file_name))

  def wrapper_file_path() do
    Path.join(File.cwd!(), @wrapper_file_name)
  end

  def create_wrapper_file() do
    path = Path.join(File.cwd!(), @wrapper_file_name)
    File.write!(path, @wrapper_content)
    File.chmod!(path, 0o775)
  end
end
