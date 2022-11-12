defmodule FileWatch.FsSubscriberTest do
  use ExUnit.Case

  alias FileWatch.Assets
  alias FileWatch.FsSubscriber

  test "run/2" do
    wrapper_file_path = Path.join("priv", Assets.wrapper_file_name())

    [port_1, port_2] =
      ["echo hello", "echo world"] |> Enum.map(&FsSubscriber.run(&1, wrapper_file_path))

    assert_receive {^port_1, {:data, "hello\n"}}
    assert_receive {^port_2, {:data, "world\n"}}
  end
end
