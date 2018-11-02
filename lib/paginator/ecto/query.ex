defmodule Paginator.Ecto.Query do
  @moduledoc false

  import Ecto.Query

  alias Paginator.Config

  def paginate(queryable, config \\ [])

  def paginate(queryable, %Config{} = config) do
    queryable
    |> maybe_where(config)
    |> limit(^query_limit(config))
  end

  def paginate(queryable, opts) do
    paginate(queryable, Config.new(opts))
  end

  defp filter_values(query, cursor_fields, values, :lt) do
    operator_list = Enum.map(cursor_fields, fn x -> {x, :lt} end)
    filter_values(query, cursor_fields, values, operator_list)
  end

  defp filter_values(query, cursor_fields, values, :gt) do
    operator_list = Enum.map(cursor_fields, fn x -> {x, :gt} end)
    filter_values(query, cursor_fields, values, operator_list)
  end

  defp filter_values(query, cursor_fields, values, operators) when is_list(operators) do
    sorts =
      cursor_fields
      |> Enum.zip(values)
      |> Enum.reject(fn val -> match?({_column, nil}, val) end)

    dynamic_sorts =
      sorts
      |> Enum.with_index()
      |> Enum.reduce(true, fn {{column, value}, i}, dynamic_sorts ->
        dynamic = true

        dynamic =
          case Keyword.get(operators, column) do
            :lt ->
              dynamic([q], field(q, ^column) < ^value and ^dynamic)

            :gt ->
              dynamic([q], field(q, ^column) > ^value and ^dynamic)
          end

        dynamic =
          sorts
          |> Enum.take(i)
          |> Enum.reduce(dynamic, fn {prev_column, prev_value}, dynamic ->
            dynamic([q], field(q, ^prev_column) == ^prev_value and ^dynamic)
          end)

        if i == 0 do
          dynamic([q], ^dynamic and ^dynamic_sorts)
        else
          dynamic([q], ^dynamic or ^dynamic_sorts)
        end
      end)

    where(query, [q], ^dynamic_sorts)
  end

  defp maybe_where(query, %Config{
         after_values: nil,
         before_values: nil,
         sort_direction: :asc
       }) do
    query
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before: nil,
         cursor_fields: cursor_fields,
         sort_direction: :asc
       }) do
    query
    |> filter_values(cursor_fields, after_values, :gt)
  end

  defp maybe_where(query, %Config{
         after_values: nil,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: :asc
       }) do
    query
    |> filter_values(cursor_fields, before_values, :lt)
    |> reverse_order_bys()
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: :asc
       }) do
    query
    |> filter_values(cursor_fields, after_values, :gt)
    |> filter_values(cursor_fields, before_values, :lt)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: nil,
         sort_direction: :desc
       }) do
    query
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before: nil,
         cursor_fields: cursor_fields,
         sort_direction: :desc
       }) do
    query
    |> filter_values(cursor_fields, after_values, :lt)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: :desc
       }) do
    query
    |> filter_values(cursor_fields, before_values, :gt)
    |> reverse_order_bys()
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: :desc
       }) do
    query
    |> filter_values(cursor_fields, after_values, :lt)
    |> filter_values(cursor_fields, before_values, :gt)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: nil,
         cursor_fields: cursor_fields,
         sort_direction: sort_direction
       })
       when is_list(sort_direction) do
    validate_sort_direction_list!(sort_direction, cursor_fields)

    query
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before: nil,
         cursor_fields: cursor_fields,
         sort_direction: sort_direction
       })
       when is_list(sort_direction) do
    validate_sort_direction_list!(sort_direction, cursor_fields)

    query
    |> filter_values(
      cursor_fields,
      after_values,
      convert_sort_direction_list(sort_direction, :before)
    )
  end

  defp maybe_where(query, %Config{
         after: nil,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: sort_direction
       })
       when is_list(sort_direction) do
    validate_sort_direction_list!(sort_direction, cursor_fields)

    query
    |> filter_values(
      cursor_fields,
      before_values,
      convert_sort_direction_list(sort_direction, :before)
    )
    |> reverse_order_bys()
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before_values: before_values,
         cursor_fields: cursor_fields,
         sort_direction: sort_direction
       })
       when is_list(sort_direction) do
    validate_sort_direction_list!(sort_direction, cursor_fields)

    query
    |> filter_values(
      cursor_fields,
      after_values,
      convert_sort_direction_list(sort_direction, :after)
    )
    |> filter_values(
      cursor_fields,
      before_values,
      convert_sort_direction_list(sort_direction, :before)
    )
  end

  # performs checks on the provided config before we run queries
  defp validate_sort_direction_list!(direction, cursor_fields) do
    # the list must be a keyword list
    unless Keyword.keyword?(direction),
      do: raise("Expected sort direction to either be a keyword list, :asc or :desc")

    # Check whether all cursor fields have a sorting direction associated
    missing_fields = Enum.filter(cursor_fields, fn x -> !Keyword.has_key?(direction, x) end)

    # if there are fields missing a direction, raise an error informing about the missing fields
    if length(missing_fields) > 0 do
      missing_fields = Enum.join(missing_fields, ", ")
      raise("There is no sorting direction provided for the fields #{missing_fields}")
    end

    # lastly, check whether the values are either ascending or descending
    Enum.each(direction, fn {key, value} ->
      if value != :desc or value != :asc,
        do: raise("Value for #{key} is invalid, please use either :desc or :asc")
    end)
  end

  # converts a column direction to a conditional, for example {column: :desc} to {column: :lt}
  defp convert_sort_direction_list(direction_list, cursor_type) do
    Enum.map(direction_list, fn {key, direction} ->
      operator =
        case {cursor_type, direction} do
          {:after, :asc} -> :lt
          {:after, :desc} -> :gt
          {:before, :asc} -> :gt
          {:before, :desc} -> :lt
        end

      {key, operator}
    end)
  end

  #  In order to return the correct pagination cursors, we need to fetch one more
  # # record than we actually want to return.
  defp query_limit(%Config{limit: limit}) do
    limit + 1
  end

  # This code was taken from https://github.com/elixir-ecto/ecto/blob/v2.1.4/lib/ecto/query.ex#L1212-L1226
  defp reverse_order_bys(query) do
    update_in(query.order_bys, fn
      [] ->
        []

      order_bys ->
        for %{expr: expr} = order_by <- order_bys do
          %{
            order_by
            | expr:
                Enum.map(expr, fn
                  {:desc, ast} -> {:asc, ast}
                  {:asc, ast} -> {:desc, ast}
                end)
          }
        end
    end)
  end
end
