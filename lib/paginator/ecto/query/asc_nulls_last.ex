defmodule Paginator.Ecto.Query.AscNullsLast do
  @behaviour Paginator.Ecto.Query.DynamicFilterBuilder

  import Ecto.Query

  @impl Paginator.Ecto.Query.DynamicFilterBuilder
  def build_dynamic_filter(%{direction: :after, value: nil, next_filters: true}) do
    raise("unstable sort order: nullable columns can't be used as the last term")
  end

  def build_dynamic_filter(args = %{direction: :after, value: nil, column: {_, handler}}) do
    dynamic(
      [{query, args.entity_position}],
      is_nil(^handler.()) and ^args.next_filters
    )
  end

  def build_dynamic_filter(args = %{direction: :after, value: nil}) do
    dynamic(
      [{query, args.entity_position}],
      is_nil(field(query, ^args.column)) and ^args.next_filters
    )
  end

  def build_dynamic_filter(args = %{direction: :after, next_filters: true, column: {_, handler}}) do
    dynamic(
      [{query, args.entity_position}],
      ^handler.() > ^args.value or is_nil(^handler.())
    )
  end

  def build_dynamic_filter(args = %{direction: :after, next_filters: true}) do
    dynamic(
      [{query, args.entity_position}],
      field(query, ^args.column) > ^args.value or is_nil(field(query, ^args.column))
    )
  end

  def build_dynamic_filter(args = %{direction: :after, column: {_, handler}}) do
    dynamic(
      [{query, args.entity_position}],
      (^handler.() == ^args.value and ^args.next_filters) or
        ^handler.() > ^args.value or
        is_nil(^handler.())
    )
  end

  def build_dynamic_filter(args = %{direction: :after}) do
    dynamic(
      [{query, args.entity_position}],
      (field(query, ^args.column) == ^args.value and ^args.next_filters) or
        field(query, ^args.column) > ^args.value or
        is_nil(field(query, ^args.column))
    )
  end

  def build_dynamic_filter(%{direction: :before, value: nil, next_filters: true}) do
    raise("unstable sort order: nullable columns can't be used as the last term")
  end

  def build_dynamic_filter(args = %{direction: :before, value: nil, column: {_, handler}}) do
    dynamic(
      [{query, args.entity_position}],
      (is_nil(^handler.()) and ^args.next_filters) or
        not is_nil(^handler.())
    )
  end

  def build_dynamic_filter(args = %{direction: :before, value: nil}) do
    dynamic(
      [{query, args.entity_position}],
      (is_nil(field(query, ^args.column)) and ^args.next_filters) or
        not is_nil(field(query, ^args.column))
    )
  end

  def build_dynamic_filter(args = %{direction: :before, next_filters: true, column: {_, handler}}) do
    dynamic([{query, args.entity_position}], ^handler.() < ^args.value)
  end

  def build_dynamic_filter(args = %{direction: :before, next_filters: true}) do
    dynamic([{query, args.entity_position}], field(query, ^args.column) < ^args.value)
  end

  def build_dynamic_filter(args = %{direction: :before, column: {_, handler}}) do
    dynamic(
      [{query, args.entity_position}],
      (^handler.() == ^args.value and ^args.next_filters) or
        ^handler.() < ^args.value
    )
  end

  def build_dynamic_filter(args = %{direction: :before}) do
    dynamic(
      [{query, args.entity_position}],
      (field(query, ^args.column) == ^args.value and ^args.next_filters) or
        field(query, ^args.column) < ^args.value
    )
  end
end
