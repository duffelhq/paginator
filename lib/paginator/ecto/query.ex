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

  defp filter_values(query, cursor_fields, values, operator) do
    sorts = Enum.zip(cursor_fields, values)

    sorts
    |> Enum.with_index()
    |> Enum.reduce(query, fn {{column, value}, i}, query ->
      dynamic = true

      dynamic =
        case operator do
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
        where(query, [q], ^dynamic)
      else
        or_where(query, [q], ^dynamic)
      end
    end)
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
