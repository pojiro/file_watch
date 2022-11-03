defmodule MixTomboWatch.FsSubscriber do
  use GenServer

  defmodule State do
    defstruct config: %MixTomboWatch.Config{}, ports: []
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
  def handle_info({:file_event, pid, {path, events}}, %State{} = state)
      when is_pid(pid) and is_binary(path) and is_list(events) do
    if match_any_patterns?(path, state.config.patterns) do
      close_ports(state.ports)
      ports = run(state.config.commands)
      debounce(state.config.debounce)
      {:noreply, %State{state | ports: ports}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({port, {:data, data}}, state) when is_port(port) do
    IO.write(data)
    {:noreply, state}
  end

  defp close_ports(ports) when is_list(ports) do
    Enum.map(ports, fn port ->
      if not is_nil(Port.info(port)) do
        Port.close(port)
      end
    end)
  end

  defp run(commands) when is_list(commands) do
    path_to_wrapper = Application.app_dir(:mix_tombo_watch, ["priv", "wrap_command.sh"])

    Enum.map(commands, fn command ->
      Port.open({:spawn_executable, path_to_wrapper}, [:binary, args: ["bash", "-c", command]])
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
