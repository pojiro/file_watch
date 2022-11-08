defmodule FileWatch.AssetsTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias FileWatch.Assets

  @tag :tmp_dir
  test "create_config_file/1", %{tmp_dir: tmp_dir_path} do
    config_file_name = "test_config.exs"
    config_file_path = Path.join(tmp_dir_path, config_file_name)

    assert capture_io(fn ->
             Assets.create_config_file(config_file_path)
           end) =~ "generated under"

    assert config_file_name in File.ls!(tmp_dir_path)

    assert File.read!(config_file_path) =~
             File.read!(Path.join("priv", "config.exs"))
  end

  test "read_config/2" do
    assert capture_io(fn ->
             assert :error = Assets.read_config("not_exist_file_path")
           end) =~ "Please check"
  end
end
