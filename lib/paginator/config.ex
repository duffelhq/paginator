defmodule Paginator.Config do
  alias Paginator.Cursor

  @type t :: %__MODULE__{}

  defstruct [
    :after,
    :after_values,
    :before,
    :before_values,
    :cursor_field,
    :cursor_fetcher,
    :include_total_count,
    :limit,
    :sort_columns,
    :sort_direction,
    :sort_field,
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
      cursor_field: opts[:cursor_field] || :id,
      cursor_fetcher: opts[:cursor_fetcher],
      include_total_count: opts[:include_total_count] || false,
      limit: max(opts[:limit] || @default_limit, @minimum_limit),
      sort_columns: sort_columns(opts[:sort_columns]),
      sort_direction: opts[:sort_direction],
      total_count_limit: opts[:total_count_limit] || @default_total_count_limit
    }
  end

  defp sort_columns(nil), do: [:id]

  defp sort_columns(columns) when is_list(columns) do
    if :id in columns do
      columns
    else
      columns ++ [:id]
    end
  end

  defp sort_columns(_columns), do: raise("expected sort_columns to be a list or nil")
end
