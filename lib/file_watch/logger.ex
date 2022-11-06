defmodule FileWatch.Logger do
  @moduledoc false
  def configure(config) when is_list(config) do
    config = Keyword.get(config, :logger, nil)

    if not is_nil(config) do
      Logger.configure(config)
    end
  end
end
