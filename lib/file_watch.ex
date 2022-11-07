defmodule FileWatch do
  @shortdoc FileWatch.MixProject.description()
  @moduledoc """

  #{@shortdoc} v#{FileWatch.MixProject.version()}

  ### Get config template

  config template, #{FileWatch.Config.file_name()}, will be generated under CWD.
  configuration details are described in it.

      $ fwatch --config-template

  ### Start watch

      $ fwatch
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

        if not (Code.ensure_loaded?(IEx) && IEx.started?()) do
          recieve_exit()
        end

      _ ->
        :ok
    end
  end

  def recieve_exit() do
    receive do
      :exit -> :ok
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
