defmodule Paginator.Config do
  @moduledoc false

  alias Paginator.Cursor

  @type t :: %__MODULE__{}

  defstruct [
    :after,
    :after_values,
    :before,
    :before_values,
    :cursor_fields,
    :include_total_count,
    :limit,
    :sort_direction,
    :total_count_limit
  ]

  @default_limit 50
  @minimum_limit 1
  @default_total_count_limit 10_000

  def new(opts) do
    %__MODULE__{
      after: opts[:after],
      after_values: Cursor.decode(opts[:after]),
      before: opts[:before],
      before_values: Cursor.decode(opts[:before]),
      cursor_fields: opts[:cursor_fields],
      include_total_count: opts[:include_total_count] || false,
      limit: max(opts[:limit] || @default_limit, @minimum_limit),
      sort_direction: opts[:sort_direction] || :asc,
      total_count_limit: opts[:total_count_limit] || @default_total_count_limit
    }
  end
end
