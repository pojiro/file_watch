defmodule FileWatch do
  @shortdoc FileWatch.MixProject.description()
  @moduledoc """
  #{@shortdoc} v#{FileWatch.MixProject.version()}

  ### Get config template

  config template, #{FileWatch.Assets.config_file_name()}, will be generated under CWD.
  configuration details are described in it.

      $ fwatch --config-template

  ### Start watch

      $ fwatch
  """

  alias FileWatch.Assets

  def main(args) do
    assets_dir_path = File.cwd!()

    case OptionParser.parse(args, strict: [config_template: :boolean]) do
      {[], [], []} ->
        run(assets_dir_path)

      {[config_template: true], [], []} ->
        Path.join(assets_dir_path, Assets.config_file_name())
        |> Assets.create_config_file()

      _ ->
        help()
    end
  end

  @spec run(assets_dir_path :: String.t()) :: :ok
  def run(assets_dir_path) do
    Path.join(assets_dir_path, Assets.config_file_name())
    |> Assets.read_config()
    |> case do
      {:ok, config} ->
        Keyword.get(config, :logger, []) |> Logger.configure()

        config = Keyword.get(config, :file_watch, [])
        wrapper_file_path = Path.join(assets_dir_path, Assets.wrapper_file_name())
        Assets.create_wrapper_file(wrapper_file_path)

        run_impl(config, wrapper_file_path)

      _ ->
        :ok
    end
  end

  @doc """
  run_impl/2 is the essential function of :file_watch,
  which can be called either as an escript or as a mix task.
  """
  @spec run_impl(config :: list(), wrapper_file_path :: String.t()) :: :ok
  def run_impl(config, wrapper_file_path) when is_list(config) and is_binary(wrapper_file_path) do
    Application.put_env(:file_watch, :main_pid, self())

    start_link(config: config, wrapper_file_path: wrapper_file_path)

    if on_iex?(), do: :ok, else: receive(do: (:exit -> :ok))
  end

  def exit() do
    Application.fetch_env!(:file_watch, :main_pid) |> send(:exit)
  end

  def highlight(binary) when is_binary(binary) do
    binary |> String.trim_trailing() |> String.split("\n") |> highlight()
  end

  def highlight(lines) when is_list(lines) do
    """
    \n\s\s#{Enum.join(lines, "\n\s\s")}
    """
  end

  defp help(), do: @moduledoc |> highlight() |> IO.puts()

  defp on_iex?() do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end

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
