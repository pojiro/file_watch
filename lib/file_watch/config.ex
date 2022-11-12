defmodule FileWatch.Config do
  @moduledoc false

  @type t :: %__MODULE__{
          patterns: list(),
          debounce: non_neg_integer(),
          dirs: [String.t()],
          commands: [String.t()],
          parallel_exec: boolean()
        }
  defstruct patterns: [], debounce: 0, dirs: ["."], commands: [":"], parallel_exec: false
end
