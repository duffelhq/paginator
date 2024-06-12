defmodule Paginator.Page.Metadata do
  @moduledoc """
  Defines page metadata.

  ## Fields

  * `after` - an opaque cursor representing the last row of the current page.
  * `before` - an opaque cursor representing the first row of the current page.
  * `limit` - the maximum number of entries that can be contained in this page.
  * `total_count` - the total number of entries matching the query.
  * `total_count_cap_exceeded` - a boolean indicating whether the `:total_count_limit`
  was exceeded.
  """

  @type opaque_cursor :: String.t()

  @type t :: %__MODULE__{
          after: opaque_cursor() | nil,
          before: opaque_cursor() | nil,
          limit: integer(),
          total_count: integer() | nil,
          total_count_cap_exceeded: boolean() | nil,
          has_next_page: boolean() | nil,
          has_previous_page: boolean() | nil
        }

  defstruct [:after, :before, :limit, :total_count, :total_count_cap_exceeded, :has_next_page, :has_previous_page]
end
