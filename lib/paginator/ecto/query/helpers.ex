defmodule Paginator.Ecto.Query.Helpers do
  import Ecto.Query

  def field_or_expr(%{column: {_, handler}}) do
    dynamic([{query, args.entity_position}], ^handler.())
  end

  def field_or_expr(args) do
    dynamic([{query, args.entity_position}], field(query, ^args.column))
  end
end
