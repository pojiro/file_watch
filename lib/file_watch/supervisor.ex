defmodule FileWatch.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link(args) when is_list(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(args) when is_list(args) do
    children = [{FileWatch.FsSubscriber, args}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
