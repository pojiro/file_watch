defmodule FileWatchTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias FileWatch.Assets

  describe "run/2" do
    @tag :tmp_dir
    test "without config file", %{tmp_dir: tmp_dir_path} do
      assert capture_io(fn -> FileWatch.run(tmp_dir_path) end) =~ "Please check"
    end

    @tag :tmp_dir
    test "with config file", %{tmp_dir: tmp_dir_path} do
      capture_io(fn ->
        Path.join(tmp_dir_path, Assets.config_file_name())
        |> Assets.create_config_file()

        pid = self()
        send(pid, :exit)
        FileWatch.run(tmp_dir_path)

        assert ^pid = Application.fetch_env!(:file_watch, :main_pid)
      end)
    end
  end

  test "exit/0" do
    Application.put_env(:file_watch, :main_pid, self())
    FileWatch.exit()
    assert_receive(:exit)
  end
end
