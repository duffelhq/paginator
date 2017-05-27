defmodule Paginator.Page do
  @type t :: %__MODULE__{}

  defstruct [:metadata, :entries]
end
