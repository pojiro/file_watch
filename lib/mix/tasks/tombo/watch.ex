defmodule Mix.Tasks.Tombo.Watch do
  use Mix.Task

  def run(_args) do
    {:ok, _apps} = Application.ensure_all_started(:mix_tombo_watch)

    if not (Code.ensure_loaded?(IEx) && IEx.started?()) do
      Process.sleep(:infinity)
    end
  end
end
