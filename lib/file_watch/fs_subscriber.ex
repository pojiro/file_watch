defmodule FileWatch.FsSubscriber do
  @moduledoc false
  use GenServer

  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            config: FileWatch.Config.t(),
            port_map: map(),
            wrapper_file_path: String.t()
          }
    defstruct config: %FileWatch.Config{}, port_map: %{}, wrapper_file_path: ""
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(config: config, wrapper_file_path: wrapper_file_path) when is_list(config) do
    config_struct = struct(FileWatch.Config, config)

    case FileSystem.start_link(dirs: Enum.map(config_struct.dirs, &Path.absname(&1))) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        {:ok, %State{config: config_struct, wrapper_file_path: wrapper_file_path}}

      other ->
        {:stop, other}
    end
  end

  @impl true
  def handle_info({:file_event, pid, {path, events}}, %State{} = state)
      when is_pid(pid) and is_binary(path) and is_list(events) do
    if match_any_patterns?(path, state.config.patterns) do
      Logger.debug("matched path: #{path} 👀")

      close_ports(Map.keys(state.port_map))

      port_map =
        case :os.type() do
          {:win32, _} ->
            IO.puts("Windows Not Supported 👀")
            FileWatch.exit()

          _ ->
            run(state.config.commands, state.wrapper_file_path)
            |> then(&to_port_map(state.config.commands, &1))
        end

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
      Logger.debug("command: \"#{command}\" exit, status: #{exit_status} 👀")
    end

    {:noreply, state}
  end

  defp close_port(port) when is_port(port) do
    if not is_nil(Port.info(port)), do: Port.close(port)
  end

  defp close_ports(ports) when is_list(ports) do
    Enum.map(ports, &close_port(&1))
  end

  def to_port_map(commands, ports) do
    Enum.zip(commands, ports)
    |> Enum.reduce(%{}, fn {command, port}, port_map -> Map.put(port_map, port, command) end)
  end

  def run(commands, wrapper_file_path) when is_list(commands) and is_binary(wrapper_file_path) do
    Enum.map(commands, fn command -> run(command, wrapper_file_path) end)
  end

  def run(command, wrapper_file_path) when is_binary(command) and is_binary(wrapper_file_path) do
    Port.open({:spawn_executable, wrapper_file_path}, [
      :binary,
      :exit_status,
      args: ["bash", "-c", command]
    ])
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
