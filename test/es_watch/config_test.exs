defmodule FileWatch.ConfigTest do
  use ExUnit.Case

  @app_atom Keyword.fetch!(FileWatch.MixProject.project(), :app)

  test "get!/0" do
    Application.get_all_env(@app_atom)
    |> Keyword.keys()
    |> Enum.map(fn key -> Application.delete_env(@app_atom, key) end)

    assert_raise Mix.Error, fn -> FileWatch.Config.get!() end
  end

  test "read!/1" do
    assert_raise Mix.Error, fn -> FileWatch.Config.read!("not_exist_path") end
  end
end
