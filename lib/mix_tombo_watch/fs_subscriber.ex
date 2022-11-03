defmodule MixTomboWatch.FsSubscriber do
  use GenServer

  defmodule State do
    defstruct config: %MixTomboWatch.Config{}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    config = Path.join(File.cwd!(), ".mix_tombo_watch.exs") |> read_config!()

    case FileSystem.start_link(dirs: Enum.map(config.dirs, &Path.absname(&1))) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        {:ok, %State{config: config}}

      other ->
        {:stop, other}
    end
  end

  @impl true
  def handle_info({:file_event, pid, {path, events}}, %State{config: config} = state)
      when is_pid(pid) and is_binary(path) and is_list(events) do
    if match_any_patterns?(path, config.patterns) do
      run(config.commands)
      debounce(config.debounce)
    end

    {:noreply, state}
  end

  defp run(commands) when is_list(commands) do
    Enum.map(commands, fn command ->
      Application.app_dir(:mix_tombo_watch, ["priv", "wrap_command.sh"])
      |> System.cmd(["bash", "-c", command], into: IO.stream(:stdio, :line))
    end)
  end

  defp debounce(milliseconds) do
    Process.send_after(self(), :debounced, milliseconds)
    debounce()
  end

  defp debounce() do
    receive do
      :debounced -> :ok
      {:file_event, _pid, {_path, _events}} -> debounce()
    end
  end

  defp match_any_patterns?(path, patterns) when is_binary(path) and is_list(patterns) do
    Enum.any?(patterns, &String.match?(path, &1))
  end

  @spec read_config!(path :: String.t()) :: MixTomboWatch.Config.t()
  defp read_config!(path) do
    if File.exists?(path) do
      Config.Reader.read!(path)[:mix_tombo_watch]
      |> then(&struct(MixTomboWatch.Config, &1))
    else
      %MixTomboWatch.Config{}
    end
  end
end
