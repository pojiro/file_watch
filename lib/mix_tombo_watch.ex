defmodule MixTomboWatch do
  @moduledoc """
  Documentation for `MixTomboWatch`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MixTomboWatch.hello()
      :world

  """
  def hello do
    :world
  end

  def main(_args) do
    {:ok, _apps} = Application.ensure_all_started(:mix_tombo_watch)

    if not (Code.ensure_loaded?(IEx) && IEx.started?()) do
      Process.sleep(:infinity)
    end
  end
end
