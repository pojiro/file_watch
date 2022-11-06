defmodule FileWatch do
  @shortdoc "File Watcher 👀, like mix test.watch"
  @moduledoc """

  #{@shortdoc}

  ## How to run

    $ ./fwatch

  ## How to get config template

    $ ./fwatch --config-template
  """

  def main(args) do
    case OptionParser.parse(args, strict: [config_template: :boolean]) do
      {[], [], []} -> run(self())
      {[config_template: true], [], []} -> FileWatch.Config.create_template()
      _ -> help()
    end
  end

  def run(pid) do
    case FileWatch.Config.read() do
      {:ok, config} ->
        FileWatch.Logger.configure(config)
        FileWatch.Assets.create_wrapper_file()
        Application.put_env(:file_watch, :main_pid, pid)
        start_link(config: config)

        receive do
          :exit -> :ok
        end

      _ ->
        :ok
    end
  end

  def exit!() do
    Application.fetch_env!(:file_watch, :main_pid) |> send(:exit)
  end

  defp help(), do: IO.puts(@moduledoc)

  use Supervisor

  def start_link(args) when is_list(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(args) when is_list(args) do
    children = [{FileWatch.FsSubscriber, args}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
