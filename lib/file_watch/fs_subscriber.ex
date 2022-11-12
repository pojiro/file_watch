defmodule FileWatch.FsSubscriber do
  @moduledoc false
  use GenServer

  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            config: FileWatch.Config.t(),
            port_map: map(),
            wrapper_file_path: String.t(),
            config_file_name_regex: Regex.t()
          }
    defstruct config: %FileWatch.Config{},
              port_map: %{},
              wrapper_file_path: "",
              config_file_name_regex: %Regex{}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(wrapper_file_path: wrapper_file_path) do
    initial_state = %State{
      config: struct(FileWatch.Config, Application.get_all_env(:file_watch)),
      wrapper_file_path: wrapper_file_path,
      config_file_name_regex: FileWatch.Assets.config_file_name() |> file_name_regex()
    }

    watch_target_dirs = Enum.map(initial_state.config.dirs, &Path.absname(&1))

    case FileSystem.start_link(dirs: watch_target_dirs, name: :fs_publisher) do
      {:ok, _} ->
        FileSystem.subscribe(:fs_publisher)
        {:ok, initial_state}

      other ->
        {:stop, other}
    end
  end

  @impl true
  def handle_info({:file_event, pid, {path, events}}, %State{} = state)
      when is_pid(pid) and is_binary(path) and is_list(events) do
    cond do
      match_pattern?(path, state.config_file_name_regex) ->
        debounce(state.config.debounce)

        GenServer.stop(:fs_publisher)
        FileWatch.load_config(path)
        {:stop, :normal, state}

      match_any_patterns?(path, state.config.patterns) ->
        debounce(state.config.debounce)

        close_ports(Map.keys(state.port_map))
        port_map = run(state.config.commands, state.wrapper_file_path)
        {:noreply, %State{state | port_map: port_map}}

      true ->
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

  def run(commands, wrapper_file_path) do
    case :os.type() do
      {:win32, _} ->
        run_on_win(commands)

      _ ->
        FileWatch.Assets.maybe_create_wrapper_file(wrapper_file_path)
        run_on_unix(commands, wrapper_file_path)
    end
    |> then(&to_port_map(commands, &1))
  end

  def run_on_unix(commands, wrapper_file_path)
      when is_list(commands) and is_binary(wrapper_file_path) do
    Enum.map(commands, fn command -> run_on_unix(command, wrapper_file_path) end)
  end

  def run_on_unix(command, wrapper_file_path)
      when is_binary(command) and is_binary(wrapper_file_path) do
    Port.open({:spawn_executable, wrapper_file_path}, [
      :binary,
      :exit_status,
      args: ["bash", "-c", command]
    ])
  end

  def run_on_win(commands) when is_list(commands) do
    Enum.map(commands, fn command -> run_on_win(command) end)
  end

  def run_on_win(command) when is_binary(command) do
    Port.open({:spawn_executable, System.find_executable("cmd")}, [
      :binary,
      :exit_status,
      args: ["/c", command]
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
    Enum.any?(patterns, &match_pattern?(path, &1))
  end

  defp match_pattern?(path, %Regex{} = pattern) when is_binary(path) do
    if String.match?(path, pattern) do
      Logger.debug("matched path: #{path} 👀")
      true
    end
  end

  defp file_name_regex(file_name) do
    file_name |> Regex.escape() |> then(&"#{&1}$") |> Regex.compile!()
  end
end
