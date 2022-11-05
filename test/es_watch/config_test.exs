defmodule EsWatch.ConfigTest do
  use ExUnit.Case

  @app_atom Keyword.fetch!(EsWatch.MixProject.project(), :app)

  test "get!/0" do
    Application.get_all_env(@app_atom)
    |> Keyword.keys()
    |> Enum.map(fn key -> Application.delete_env(@app_atom, key) end)

    assert_raise Mix.Error, fn -> EsWatch.Config.get!() end
  end

  test "read!/1" do
    assert_raise Mix.Error, fn -> EsWatch.Config.read!("not_exist_path") end
  end
end
