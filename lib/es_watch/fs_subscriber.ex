defmodule EsWatch.FsSubscriber do
  use GenServer

  require Logger

  @exs_file_name ".eswatch.exs"
  @sh_file_name ".eswatch.sh"
  @sh_content File.read!(Path.join("priv", @sh_file_name))

  defmodule State do
    defstruct config: %EsWatch.Config{}, port_map: %{}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    create_wrap_command_sh(File.cwd!())
    config = Path.join(File.cwd!(), @exs_file_name) |> read_config!()

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
      close_ports(Map.keys(state.port_map))
      port_map = run(state.config.commands)
      debounce(state.config.debounce)
      {:noreply, %State{state | port_map: port_map}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({port, {:data, data}}, state) when is_port(port) do
    IO.write(data)
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, exit_status}}, state) when is_port(port) do
    if Map.has_key?(state.port_map, port) do
      command = Map.get(state.port_map, port)
      Logger.info("\"#{command}\" exit, status: #{exit_status}")
    end

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
    path_to_wrapper = Path.join(File.cwd!(), @sh_file_name)

    Enum.reduce(commands, %{}, fn command, acc ->
      port =
        Port.open({:spawn_executable, path_to_wrapper}, [
          :binary,
          :exit_status,
          args: ["bash", "-c", command]
        ])

      Map.put(acc, port, command)
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

  defp create_wrap_command_sh(path) do
    path = Path.join(path, @sh_file_name)
    File.write!(path, @sh_content)
    File.chmod!(path, 0o775)
  end

  @spec read_config!(path :: String.t()) :: EsWatch.Config.t()
  defp read_config!(path) do
    if File.exists?(path) do
      Config.Reader.read!(path)[:es_watch]
      |> then(&struct(EsWatch.Config, &1))
    else
      %EsWatch.Config{}
    end
  end
end
