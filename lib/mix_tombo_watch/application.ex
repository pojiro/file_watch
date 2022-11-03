defmodule MixTomboWatch.Application do
  use Application

  alias MixTomboWatch.FsSubscriber

  def start(_type, _args) do
    children = [FsSubscriber]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
