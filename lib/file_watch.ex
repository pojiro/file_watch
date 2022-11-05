defmodule FileWatch do
  @moduledoc """
  Documentation for `FileWatch`.
  """

  def main(_args) do
    {:ok, _apps} = Application.ensure_all_started(:file_watch)

    if not (Code.ensure_loaded?(IEx) && IEx.started?()) do
      Process.sleep(:infinity)
    end
  end
end
