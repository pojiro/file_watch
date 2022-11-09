defmodule Mix.Tasks.File.Watch do
  @shortdoc FileWatch.MixProject.description()
  @moduledoc """
  #{@shortdoc} v#{FileWatch.MixProject.version()}

  ### Show config template

  configuration details are described in it.

      $ mix file.watch --config-template

  ### Start watch

      $ mix file.watch
  """

  use Mix.Task

  alias FileWatch.Assets

  def run(args) do
    assets_dir_path = Application.app_dir(:file_watch, ["priv"])

    case OptionParser.parse(args, strict: [config_template: :boolean]) do
      {[], [], []} ->
        config = Application.get_all_env(:file_watch)

        if config == [] do
          """
          :file_watch config doesn't exist in config file,
          --config-template option shows config template
          """
          |> FileWatch.highlight()
          |> Mix.raise()
        else
          wrapper_file_path = Path.join(assets_dir_path, Assets.wrapper_file_name())
          FileWatch.run_impl(wrapper_file_path)
        end

      {[config_template: true], [], []} ->
        show_config_template(assets_dir_path)

      _ ->
        help()
    end
  end

  defp help(), do: @moduledoc |> FileWatch.highlight() |> IO.puts()

  defp show_config_template(assets_dir_path) do
    "#{Path.join(assets_dir_path, "config.exs") |> File.read!()}"
    |> FileWatch.highlight()
    |> IO.puts()
  end
end
