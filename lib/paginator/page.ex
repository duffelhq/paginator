defmodule Paginator.Page do
  @moduledoc """
  Defines a page.

  ## Fields

  * `entries` - a list entries contained in this page.
  * `metadata` - metadata attached to this page.
  """

  @type t :: %__MODULE__{
          entries: [any()] | [],
          metadata: Paginator.Page.Metadata.t()
        }

  defstruct [:metadata, :entries]
end
