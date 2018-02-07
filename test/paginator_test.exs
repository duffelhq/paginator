defmodule PaginatorTest do
  use Paginator.DataCase

  defp payments_by_customer_name(direction \\ :asc) do
    from(
      p in Payment,
      join: c in assoc(p, :customer),
      order_by: [{^direction, c.name}],
      select: p
    )
  end

  defp payments_with_customer() do
    from(
      p in Payment,
      join: c in assoc(p, :customer),
      select: {p, c}
    )
  end

  setup :create_customers_and_payments

  describe "paginate a collection of payments, sorting by customer name" do
    test "sorts ascending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, limit: 50)

      assert to_ids(entries) == to_ids([p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    test "sorts ascending with before cursor", %{
      payments: {_p1, _p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, before: p11.id, limit: 8)

      assert to_ids(entries) == to_ids([p3, p4, p5, p6, p7, p8, p9, p10])
      assert metadata == %Metadata{after: p10.id, before: p3.id, limit: 8}
    end

    test "sorts ascending with after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, after: p6.id, limit: 8)

      assert to_ids(entries) == to_ids([p7, p8, p9, p10, p11, p12])
      assert metadata == %Metadata{after: nil, before: p7.id, limit: 8}
    end

    test "sorts ascending with before and after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, after: p6.id, before: p10.id, limit: 8)

      assert to_ids(entries) == to_ids([p7, p8, p9])
      assert metadata == %Metadata{after: p9.id, before: p7.id, limit: 8}
    end

    test "sorts descending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, limit: 50)

      assert to_ids(entries) == to_ids([p12, p11, p10, p9, p8, p7, p6, p5, p4, p3, p2, p1])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    test "sorts descending with before cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, before: p11.id, limit: 8)

      assert to_ids(entries) == to_ids([p12])
      assert metadata == %Metadata{after: p12.id, before: nil, limit: 8}
    end

    test "sorts descending with after cursor", %{
      payments: {_p1, _p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, after: p11.id, limit: 8)

      assert to_ids(entries) == to_ids([p10, p9, p8, p7, p6, p5, p4, p3])
      assert metadata == %Metadata{after: p3.id, before: p10.id, limit: 8}
    end

    test "sorts descending with before and after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, after: p11.id, before: p6.id, limit: 8)

      assert to_ids(entries) == to_ids([p10, p9, p8, p7])
      assert metadata == %Metadata{after: p7.id, before: p10.id, limit: 8}
    end

    test "sorts ascending with before cursor at beginning of collection", %{
      payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, before: p1.id, limit: 8)

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts ascending with after cursor at end of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, after: p12.id, limit: 8)

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts descending with before cursor at beginning of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, before: p12.id, limit: 8)

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts descending with after cursor at end of collection", %{
      payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(sort_direction: :desc, after: p1.id, limit: 8)

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "applies a default limit if none is provided", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc)

      assert to_ids(entries) == to_ids([p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    test "enforces the minimum limit", %{
      payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, limit: 0)

      assert to_ids(entries) == to_ids([p1])
      assert metadata == %Metadata{after: p1.id, before: nil, limit: 1}
    end

    test "with include_total_count", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(sort_direction: :asc, limit: 5, include_total_count: true)

      assert metadata == %Metadata{
               after: p5.id,
               before: nil,
               limit: 5,
               total_count: %{total_count: 12, total_count_cap_exceeded: false}
             }
    end
  end

  test "paginate a collection of {payment, customer} tuples", %{
    payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
  } do
    %Page{metadata: metadata} =
      payments_with_customer()
      |> Repo.paginate(sort_direction: :asc, limit: 5, cursor_fetcher: fn {p, _c} -> p.id end)

    assert metadata == %Metadata{after: p5.id, before: nil, limit: 5}
  end

  defp to_ids(entries), do: Enum.map(entries, & &1.id)

  defp create_customers_and_payments(_context) do
    c1 = insert(:customer, %{name: "Bob"})
    c2 = insert(:customer, %{name: "Alice"})
    c3 = insert(:customer, %{name: "Charlie"})

    p1 = insert(:payment, customer: c2)
    p2 = insert(:payment, customer: c2)
    p3 = insert(:payment, customer: c2)
    p4 = insert(:payment, customer: c2)

    p5 = insert(:payment, customer: c1)
    p6 = insert(:payment, customer: c1)
    p7 = insert(:payment, customer: c1)
    p8 = insert(:payment, customer: c1)

    p9 = insert(:payment, customer: c3)
    p10 = insert(:payment, customer: c3)
    p11 = insert(:payment, customer: c3)
    p12 = insert(:payment, customer: c3)

    {:ok, customers: {c1, c2, c3}, payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}}
  end
end
