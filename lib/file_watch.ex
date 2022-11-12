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

  @doc false
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

  @doc false
  @spec run(assets_dir_path :: String.t()) :: :ok | :error
  def run(assets_dir_path) do
    config_file_path = Path.join(assets_dir_path, Assets.config_file_name())

    case load_config(config_file_path) do
      :ok ->
        wrapper_file_path = Path.join(assets_dir_path, Assets.wrapper_file_name())
        run_impl(wrapper_file_path)

      :error ->
        :error
    end
  end

  @doc false
  @spec run_impl(wrapper_file_path :: String.t()) :: :ok
  def run_impl(wrapper_file_path) when is_binary(wrapper_file_path) do
    # NOTE: run_impl/2 is the essential function of :file_watch,
    # which can be called either as an escript or as a mix task.
    Application.put_env(:file_watch, :main_pid, self())
    FileWatch.Supervisor.start_link(wrapper_file_path: wrapper_file_path)
    if on_iex?(), do: :ok, else: receive(do: (:exit -> :ok))
  end

  @doc false
  def exit() do
    Application.fetch_env!(:file_watch, :main_pid) |> send(:exit)
  end

  @doc false
  def load_config(path) do
    case Assets.read_config(path) do
      {:ok, config} ->
        Application.put_all_env(config)
        Application.get_all_env(:logger) |> Logger.configure()
        :ok

      :error ->
        :error
    end
  end

  @doc false
  def highlight(binary) when is_binary(binary) do
    binary |> String.trim_trailing() |> String.split("\n") |> highlight()
  end

  @doc false
  def highlight(lines) when is_list(lines) do
    """
    \n\s\s#{Enum.join(lines, "\n\s\s")}
    """
  end

  defp help(), do: @moduledoc |> highlight() |> IO.puts()

  defp on_iex?() do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
