defmodule FileWatch.FsSubscriber do
  @moduledoc false
  use GenServer

  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            config: FileWatch.Config.t(),
            port_map: %{} | %{port() => String.t()},
            wrapper_file_path: String.t(),
            config_file_name_regex: Regex.t(),
            left_commands: [] | [String.t()]
          }
    defstruct config: %FileWatch.Config{},
              port_map: %{},
              wrapper_file_path: "",
              config_file_name_regex: %Regex{},
              left_commands: []
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(wrapper_file_path: wrapper_file_path) do
    Process.flag(:trap_exit, true)

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

        if state.config.parallel_exec do
          port_map =
            Enum.reduce(state.config.commands, %{}, fn command, acc ->
              Map.put(acc, run(command, state.wrapper_file_path), command)
            end)

          {:noreply, %State{state | port_map: port_map, left_commands: []}}
        else
          [command | left_commands] = state.config.commands
          port_map = Map.put(%{}, run(command, state.wrapper_file_path), command)

          {:noreply, %State{state | port_map: port_map, left_commands: left_commands}}
        end

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

  @impl true
  def handle_info({:EXIT, _port, :normal}, %State{left_commands: []} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _port, :normal}, state) do
    [command | left_commands] = state.left_commands
    port_map = Map.put(state.port_map, run(command, state.wrapper_file_path), command)

    {:noreply, %State{state | port_map: port_map, left_commands: left_commands}}
  end

  defp close_port(port) when is_port(port) do
    if not is_nil(Port.info(port)), do: Port.close(port)
  end

  defp close_ports(ports) when is_list(ports) do
    Enum.map(ports, &close_port(&1))
  end

  @spec run(command :: String.t(), wrapper_file_path :: String.t()) :: port()
  def run(command, wrapper_file_path) when is_binary(command) do
    case :os.type() do
      {:win32, _} ->
        run_on_win(command)

      _ ->
        FileWatch.Assets.maybe_create_wrapper_file(wrapper_file_path)
        run_on_unix(command, wrapper_file_path)
    end
  end

  def run_on_unix(command, wrapper_file_path)
      when is_binary(command) and is_binary(wrapper_file_path) do
    Port.open({:spawn_executable, wrapper_file_path}, [
      :binary,
      :exit_status,
      args: ["bash", "-c", command]
    ])
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
