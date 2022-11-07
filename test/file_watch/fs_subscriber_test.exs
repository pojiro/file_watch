defmodule FileWatch.FsSubscriberTest do
  use ExUnit.Case

  alias FileWatch.Assets
  alias FileWatch.FsSubscriber

  test "run/2 single command" do
    wrapper_file_path = Path.join("priv", Assets.wrapper_file_name())
    port = FsSubscriber.run("echo hello", wrapper_file_path)
    assert_receive {^port, {:data, "hello\n"}}
  end

  test "run/2 multiple commands" do
    wrapper_file_path = Path.join("priv", Assets.wrapper_file_name())
    [port_1, port_2] = FsSubscriber.run(["echo hello", "echo world"], wrapper_file_path)

    assert_receive {^port_1, {:data, "hello\n"}}
    assert_receive {^port_2, {:data, "world\n"}}
  end
end
