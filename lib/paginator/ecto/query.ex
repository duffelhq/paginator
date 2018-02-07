defmodule Paginator.Ecto.Query do
  @moduledoc """
  Documentation for Paginator.Ecto.Query.
  """

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

  defp maybe_where(query, %Config{
         after: nil,
         before: nil,
         cursor_field: cursor_field,
         sort_direction: :asc
       }) do
    order_by(query, asc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: c_after,
         before: nil,
         cursor_field: cursor_field,
         sort_direction: :asc
       }) do
    query
    |> where([q], field(q, ^cursor_field) > ^c_after)
    |> order_by(asc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: c_before,
         cursor_field: cursor_field,
         sort_direction: :asc
       }) do
    query
    |> where([q], field(q, ^cursor_field) < ^c_before)
    |> reverse_order_bys()
    |> order_by(desc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: c_after,
         before: c_before,
         cursor_field: cursor_field,
         sort_direction: :asc
       }) do
    query
    |> where([q], field(q, ^cursor_field) > ^c_after)
    |> where([q], field(q, ^cursor_field) < ^c_before)
    |> order_by(asc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: nil,
         cursor_field: cursor_field,
         sort_direction: :desc
       }) do
    order_by(query, desc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: c_after,
         before: nil,
         cursor_field: cursor_field,
         sort_direction: :desc
       }) do
    query
    |> where([q], field(q, ^cursor_field) < ^c_after)
    |> order_by(desc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: c_before,
         cursor_field: cursor_field,
         sort_direction: :desc
       }) do
    query
    |> where([q], field(q, ^cursor_field) > ^c_before)
    |> reverse_order_bys()
    |> order_by(asc: ^cursor_field)
  end

  defp maybe_where(query, %Config{
         after: c_after,
         before: c_before,
         cursor_field: cursor_field,
         sort_direction: :desc
       }) do
    query
    |> where([q], field(q, ^cursor_field) < ^c_after)
    |> where([q], field(q, ^cursor_field) > ^c_before)
    |> order_by(desc: ^cursor_field)
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
