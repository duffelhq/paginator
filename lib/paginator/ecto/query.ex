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

  defp get_operator(:asc, :before), do: :lt
  defp get_operator(:desc, :before), do: :gt
  defp get_operator(:asc, :after), do: :gt
  defp get_operator(:desc, :after), do: :lt

  defp get_operator(direction, _),
    do: raise("Invalid sorting value :#{direction}, please use either :asc or :desc")

  defp get_operator_for_field(cursor_fields, key, direction) do
    {_, order} =
      cursor_fields
      |> Enum.find(fn {field_key, _order} ->
        field_key == key
      end)

    get_operator(order, direction)
  end

  # This clause is responsible for transforming legacy list cursors into map cursors
  defp filter_values(query, fields, values, cursor_direction) when is_list(values) do
    new_values =
      fields
      |> Keyword.keys()
      |> Enum.zip(values)
      |> Map.new()

    filter_values(query, fields, new_values, cursor_direction)
  end

  defp filter_values(query, fields, values, cursor_direction) when is_map(values) do
    sorts =
      fields
      |> Enum.map(fn
        {{field, func} = column, _order} when is_function(func) and is_atom(field) ->
          {column, Map.get(values, field)}

        {column, _order} ->
          {column, Map.get(values, column)}
      end)
      |> Enum.reject(fn val -> match?({_column, nil}, val) end)

    dynamic_sorts =
      sorts
      |> Enum.with_index()
      |> Enum.reduce(true, fn {{bound_column, value}, i}, dynamic_sorts ->
        {position, column} = column_position(query, bound_column)

        dynamic = true

        dynamic =
          fields
          |> get_operator_for_field(bound_column, cursor_direction)
          |> build_cursor_where(position, column, value, dynamic)

        dynamic =
          sorts
          |> Enum.take(i)
          |> Enum.reduce(dynamic, fn {prev_column, prev_value}, dynamic ->
            {position, prev_column} = column_position(query, prev_column)
            build_cursor_where(:prev, position, prev_column, prev_value, dynamic)
          end)

        build_cursor_where(:with_sorts, i, dynamic, dynamic_sorts)
      end)

    where(query, [{q, 0}], ^dynamic_sorts)
  end

  defp build_cursor_where(:with_sorts, 0, dynamic, dynamic_sorts) do
    dynamic([{q, position}], ^dynamic and ^dynamic_sorts)
  end

  defp build_cursor_where(:with_sorts, _, dynamic, dynamic_sorts) do
    dynamic([{q, position}], ^dynamic or ^dynamic_sorts)
  end

  defp build_cursor_where(:lt, position, column, value, dynamic) when is_atom(column) do
    dynamic([{q, position}], field(q, ^column) < ^value and ^dynamic)
  end

  defp build_cursor_where(:gt, position, column, value, dynamic) when is_atom(column) do
    dynamic([{q, position}], field(q, ^column) > ^value and ^dynamic)
  end

  defp build_cursor_where(:prev, position, column, value, dynamic) when is_atom(column) do
    dynamic([{q, position}], field(q, ^column) == ^value and ^dynamic)
  end

  defp build_cursor_where(:lt, _position, {_, handler}, value, dynamic)
       when is_function(handler) do
    dynamic([{q, position}], ^handler.() < ^value and ^dynamic)
  end

  defp build_cursor_where(:gt, _position, {_, handler}, value, dynamic)
       when is_function(handler) do
    dynamic([{q, position}], ^handler.() > ^value and ^dynamic)
  end

  defp build_cursor_where(:prev, _position, {_, handler}, value, dynamic)
       when is_function(handler) do
    dynamic([{q, position}], ^handler.() == ^value and ^dynamic)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before: nil
       }) do
    query
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before: nil,
         cursor_fields: cursor_fields
       }) do
    query
    |> filter_values(cursor_fields, after_values, :after)
  end

  defp maybe_where(query, %Config{
         after: nil,
         before_values: before_values,
         cursor_fields: cursor_fields
       }) do
    query
    |> filter_values(cursor_fields, before_values, :before)
    |> reverse_order_bys()
  end

  defp maybe_where(query, %Config{
         after_values: after_values,
         before_values: before_values,
         cursor_fields: cursor_fields
       }) do
    query
    |> filter_values(cursor_fields, after_values, :after)
    |> filter_values(cursor_fields, before_values, :before)
  end

  # With custom column handler
  defp column_position(_query, {_, handler} = column) when is_function(handler),
    do: {0, column}

  # Lookup position of binding in query aliases
  defp column_position(query, {binding_name, column}) do
    case Map.fetch(query.aliases, binding_name) do
      {:ok, position} ->
        {position, column}

      _ ->
        raise(
          ArgumentError,
          "Could not find binding `#{binding_name}` in query aliases: #{inspect(query.aliases)}"
        )
    end
  end

  # Without named binding we assume position of binding is 0
  defp column_position(_query, column), do: {0, column}

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
