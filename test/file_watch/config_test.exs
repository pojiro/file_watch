defmodule FileWatch.ConfigTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @tag :tmp_dir
  test "create_template/1", %{tmp_dir: tmp_dir_path} do
    assert capture_io(fn ->
             tmp_dir_path
             |> Path.join("test_config.exs")
             |> FileWatch.Config.create_template()
           end) =~ "generated under"

    assert File.ls!(tmp_dir_path) |> Enum.count() > 0
  end

  test "get/1" do
    assert %FileWatch.Config{} = FileWatch.Config.get([])
  end

  test "read/1" do
    assert capture_io(fn ->
             assert :error = FileWatch.Config.read("not_exist_path")
           end) =~ "Please check"
  end
end
