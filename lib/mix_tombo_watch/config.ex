defmodule MixTomboWatch.Config do
  @type t :: %__MODULE__{
          patterns: list(),
          debounce: non_neg_integer(),
          dirs: [String.t()],
          commands: [String.t()]
        }
  defstruct patterns: [], debounce: 0, dirs: [""], commands: [":"]
end
