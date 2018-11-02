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
    config = Config.new(opts)
    paginate(queryable, config)
  end

  defp filter_values(query, cursor_fields, values) do
    fields = Keyword.keys(cursor_fields)

    sorts =
      fields
      |> Enum.zip(values)
      |> Enum.reject(fn val -> match?({_column, nil}, val) end)

    dynamic_sorts =
      sorts
      |> Enum.with_index()
      |> Enum.reduce(true, fn {{column, value}, i}, dynamic_sorts ->
        dynamic = true

        dynamic =
          case Keyword.get(cursor_fields, column) do
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
         after: nil,
         before: nil,
         cursor_fields: cursor_fields
       }) do
    validate_cursor_fields!(cursor_fields)

    query
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before: nil,
         cursor_fields: cursor_fields
       }) do
    validate_cursor_fields!(cursor_fields)

    query
    |> filter_values(
      convert_cursor_fields(cursor_fields, :after),
      after_values
    )
  end

  defp maybe_where(query, %Config{
         after: nil,
         before_values: before_values,
         cursor_fields: cursor_fields
       }) do
    validate_cursor_fields!(cursor_fields)

    query
    |> filter_values(
      convert_cursor_fields(cursor_fields, :before),
      before_values
    )
    |> reverse_order_bys()
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before_values: before_values,
         cursor_fields: cursor_fields
       }) do
    validate_cursor_fields!(cursor_fields)

    query
    |> filter_values(
      convert_cursor_fields(cursor_fields, :after),
      after_values
    )
    |> filter_values(
      convert_cursor_fields(cursor_fields, :before),
      before_values
    )
  end

  defp validate_cursor_fields!(cursor_fields) do
    # the list must be a keyword list
    unless Keyword.keyword?(cursor_fields),
      do: raise("Expected cursor_fields to be a keyword list.")

    Enum.each(cursor_fields, fn {key, value} ->
      unless value == :desc or value == :asc do
        raise(
          "Value for field :#{key} in cursor_fields is invalid, please use either :desc or :asc"
        )
      end
    end)
  end

  # converts a column direction to a conditional, for example {column: :desc} to {column: :lt}
  defp convert_cursor_fields(direction_list, cursor_type) do
    Enum.map(direction_list, fn {key, direction} ->
      operator =
        case {cursor_type, direction} do
          {:before, :asc} -> :lt
          {:before, :desc} -> :gt
          {:after, :asc} -> :gt
          {:after, :desc} -> :lt
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
