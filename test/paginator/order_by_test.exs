defmodule Paginator.OrderByTest do
  use ExUnit.Case, async: true

  alias Paginator.Ecto.OrderBy
  import Ecto.Query

  defp assert_result(result, list) do
    assert(result == list)
  end

  describe "OrderBy.infer_order_by/1" do
    test "parses single order_by with default direction" do
      from(p in "payments",
        order_by: p.charged_at
      )
      |> OrderBy.infer_order_by()
      |> assert_result(charged_at: :asc)
    end

    test "parses multiple order_bys with default direction" do
      from(p in "payments",
        order_by: [p.amount, p.charged_at]
      )
      |> OrderBy.infer_order_by()
      |> assert_result(amount: :asc, charged_at: :asc)
    end

    test "parses multiple seperate order_bys with a given direction" do
      from(p in "payments",
        order_by: [desc: p.charged_at],
        order_by: [asc: p.amount]
      )
      |> OrderBy.infer_order_by()
      |> assert_result(amount: :asc, charged_at: :desc)
    end

    test "rejects order_by with a fragment" do
      assert_raise RuntimeError,
                   "Unsupported `order_by` syntax, could not infer cursor fields for Paginator. Please supply `cursor_fields` manually.",
                   fn ->
                     from(p in "payments",
                       order_by: fragment("amount")
                     )
                     |> OrderBy.infer_order_by()
                   end
    end
  end
end
