defmodule Paginator.Config do
  @type t :: %__MODULE__{}

  defstruct [:after, :before, :cursor_field, :cursor_fetcher, :include_total_count,
             :limit, :sort_direction, :sort_field, :total_count_limit]

  @default_limit 50
  @minimum_limit 1
  @default_total_count_limit 10_000

  def new(opts) do
    %__MODULE__{
      after: opts[:after],
      before: opts[:before],
      cursor_field: opts[:cursor_field] || :id,
      cursor_fetcher: opts[:cursor_fetcher],
      include_total_count: opts[:include_total_count] || false,
      limit: max(opts[:limit] || @default_limit, @minimum_limit),
      sort_direction: opts[:sort_direction],
      sort_field: opts[:sort_field],
      total_count_limit: opts[:total_count_limit] || @default_total_count_limit,
    }
  end
end
