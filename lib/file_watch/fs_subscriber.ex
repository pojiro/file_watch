defmodule FileWatch.FsSubscriber do
  @moduledoc false
  use GenServer

  require Logger
  alias FileWatch.Assets
  alias FileWatch.Config

  defmodule State do
    @moduledoc false
    defstruct config: %FileWatch.Config{}, port_map: %{}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([config: config] = args) when is_list(args) do
    config_struct = Config.get(config)

    case FileSystem.start_link(dirs: Enum.map(config_struct.dirs, &Path.absname(&1))) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        {:ok, %State{config: config_struct}}

      other ->
        {:stop, other}
    end
  end

  @impl true
  def handle_info({:file_event, pid, {path, events}}, %State{} = state)
      when is_pid(pid) and is_binary(path) and is_list(events) do
    if match_any_patterns?(path, state.config.patterns) do
      Logger.debug("matched path: #{path}")

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
      Logger.debug("\"#{command}\" exit, status: #{exit_status}")
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
    Enum.reduce(commands, %{}, fn command, acc ->
      port =
        Port.open({:spawn_executable, Assets.wrapper_file_path()}, [
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
end
