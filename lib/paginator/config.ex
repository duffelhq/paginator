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
    :fetch_cursor_value_fun,
    :include_total_count,
    :total_count_primary_key_field,
    :limit,
    :maximum_limit,
    :sort_direction,
    :total_count_limit,
    :page_booleans
  ]

  @default_total_count_primary_key_field :id
  @default_limit 50
  @minimum_limit 1
  @maximum_limit 500
  @default_total_count_limit 10_000
  @order_directions [
    :asc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc,
    :desc_nulls_first,
    :desc_nulls_last
  ]

  def new(opts \\ []) do
    %__MODULE__{
      after: opts[:after],
      after_values: Cursor.decode(opts[:after]),
      before: opts[:before],
      before_values: Cursor.decode(opts[:before]),
      cursor_fields: opts[:cursor_fields],
      fetch_cursor_value_fun:
        opts[:fetch_cursor_value_fun] || (&Paginator.default_fetch_cursor_value/2),
      include_total_count: opts[:include_total_count] || false,
      total_count_primary_key_field:
        opts[:total_count_primary_key_field] || @default_total_count_primary_key_field,
      limit: limit(opts),
      sort_direction: opts[:sort_direction],
      total_count_limit: opts[:total_count_limit] || @default_total_count_limit,
      page_booleans: opts[:page_booleans] || false
    }
    |> convert_deprecated_config()
  end

  def validate!(%__MODULE__{} = config) do
    unless config.cursor_fields do
      raise(ArgumentError, "expected `:cursor_fields` to be set")
    end

    if !cursor_values_match_cursor_fields?(config.after_values, config.cursor_fields) do
      raise(ArgumentError, message: "expected `:after` cursor to match `:cursor_fields`")
    end

    if !cursor_values_match_cursor_fields?(config.before_values, config.cursor_fields) do
      raise(ArgumentError, message: "expected `:before` cursor to match `:cursor_fields`")
    end
  end

  defp cursor_values_match_cursor_fields?(nil = _cursor_values, _cursor_fields), do: true

  defp cursor_values_match_cursor_fields?(cursor_values, _cursor_fields)
       when is_list(cursor_values) do
    # Legacy cursors are valid by default
    true
  end

  defp cursor_values_match_cursor_fields?(cursor_values, cursor_fields) do
    cursor_keys = cursor_values |> Map.keys() |> Enum.sort()

    sorted_cursor_fields =
      cursor_fields
      |> Enum.map(fn
        {field, value} when is_atom(field) and value in @order_directions ->
          field

        {{schema, field}, value}
        when is_atom(schema) and is_atom(field) and value in @order_directions ->
          {schema, field}

        field when is_atom(field) ->
          field

        {schema, field} when is_atom(schema) and is_atom(field) ->
          {schema, field}
      end)
      |> Enum.sort()

    match?(^cursor_keys, sorted_cursor_fields)
  end

  defp limit(opts) do
    max(opts[:limit] || @default_limit, @minimum_limit)
    |> min(opts[:maximum_limit] || @maximum_limit)
  end

  defp convert_deprecated_config(config) do
    case config do
      %__MODULE__{sort_direction: nil} ->
        %{
          config
          | cursor_fields: build_cursor_fields_from_sort_direction(config.cursor_fields, :asc)
        }

      %__MODULE__{sort_direction: direction} ->
        %{
          config
          | cursor_fields:
              build_cursor_fields_from_sort_direction(config.cursor_fields, direction),
            sort_direction: nil
        }
    end
  end

  defp build_cursor_fields_from_sort_direction(nil, _sorting_direction), do: nil

  defp build_cursor_fields_from_sort_direction(fields, sorting_direction) do
    Enum.map(fields, fn
      {{_binding, _column}, _direction} = field -> field
      {_column, direction} = field when direction in @order_directions -> field
      {_binding, _column} = field -> {field, sorting_direction}
      field -> {field, sorting_direction}
    end)
  end
end
