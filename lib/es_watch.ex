defmodule EsWatch do
  @moduledoc """
  Documentation for `EsWatch`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> EsWatch.hello()
      :world

  """
  def hello do
    :world
  end

  def main(_args) do
    {:ok, _apps} = Application.ensure_all_started(:es_watch)

    if not (Code.ensure_loaded?(IEx) && IEx.started?()) do
      Process.sleep(:infinity)
    end
  end
end
