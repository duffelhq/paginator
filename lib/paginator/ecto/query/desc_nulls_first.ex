defmodule Paginator.Ecto.Query.DescNullsFirst do
  @moduledoc false

  @behaviour Paginator.Ecto.Query.DynamicFilterBuilder

  import Ecto.Query
  import Paginator.Ecto.Query.FieldOrExpression

  @impl Paginator.Ecto.Query.DynamicFilterBuilder
  def build_dynamic_filter(%{direction: :before, value: nil, next_filters: true}) do
    raise("unstable sort order: nullable columns can't be used as the last term")
  end

  def build_dynamic_filter(args = %{direction: :before, value: nil}) do
    dynamic(
      [{query, args.entity_position}],
      ^field_or_expr_is_nil(args) and ^args.next_filters
    )
  end

  def build_dynamic_filter(args = %{direction: :before, next_filters: true}) do
    dynamic(
      [{query, args.entity_position}],
      ^field_or_expr_greater(args) or ^field_or_expr_is_nil(args)
    )
  end

  def build_dynamic_filter(args = %{direction: :before}) do
    dynamic(
      [{query, args.entity_position}],
      (^field_or_expr_equal(args) and ^args.next_filters) or
        ^field_or_expr_greater(args) or
        ^field_or_expr_is_nil(args)
    )
  end

  def build_dynamic_filter(%{direction: :after, value: nil, next_filters: true}) do
    raise("unstable sort order: nullable columns can't be used as the last term")
  end

  def build_dynamic_filter(args = %{direction: :after, value: nil}) do
    dynamic(
      [{query, args.entity_position}],
      (^field_or_expr_is_nil(args) and ^args.next_filters) or
        not (^field_or_expr_is_nil(args))
    )
  end

  def build_dynamic_filter(args = %{direction: :after, next_filters: true}) do
    dynamic([{query, args.entity_position}], ^field_or_expr_less(args))
  end

  def build_dynamic_filter(args = %{direction: :after}) do
    dynamic(
      [{query, args.entity_position}],
      (^field_or_expr_equal(args) and ^args.next_filters) or
        ^field_or_expr_less(args)
    )
  end
end
