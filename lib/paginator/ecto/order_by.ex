defmodule Paginator.Ecto.OrderBy do
  @moduledoc false

  # import Ecto.Query

  def infer_order_by(queryable) do
    queryable
    |> get_order_by_expressions()
    |> make_cursor_field_list()
  end

  defp get_order_by_expressions(queryable) do
    queryable.order_bys
    |> Enum.reduce([], fn x, acc -> x.expr ++ acc end)
  end

  defp make_cursor_field_list(expressions) do
    expressions
    |> Enum.map(fn {key, value} ->
      # gets the field name atom from the query struct

      case value do
        # https://github.com/elixir-ecto/ecto/blob/1533413/lib/ecto/query/builder/order_by.ex#L121
        {{:., [], [{:&, [], [0]}, field]}, [], []} ->
          {field, key}

        _ ->
          raise "Unsupported `order_by` syntax, could not infer cursor fields for Paginator. Please supply `cursor_fields` manually."
      end
    end)
  end
end
