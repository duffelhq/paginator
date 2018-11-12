defmodule PaginatorTest do
  use Paginator.DataCase

  alias Calendar.DateTime, as: DT

  alias Paginator.Cursor

  setup :create_customers_and_payments

  test "paginates forward", %{
    payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
  } do
    opts = [cursor_fields: [:charged_at, :id], sort_direction: :asc, limit: 4]

    page = payments_by_charged_at() |> Repo.paginate(opts)
    assert to_ids(page.entries) == to_ids([p5, p4, p1, p6])
    assert page.metadata.after == encode_cursor([p6.charged_at, p6.id])

    page = payments_by_charged_at() |> Repo.paginate(opts ++ [after: page.metadata.after])
    assert to_ids(page.entries) == to_ids([p7, p3, p10, p2])
    assert page.metadata.after == encode_cursor([p2.charged_at, p2.id])

    page = payments_by_charged_at() |> Repo.paginate(opts ++ [after: page.metadata.after])
    assert to_ids(page.entries) == to_ids([p12, p8, p9, p11])
    assert page.metadata.after == nil
  end

  test "paginates backward", %{
    payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
  } do
    opts = [cursor_fields: [:charged_at, :id], sort_direction: :asc, limit: 4]

    page =
      payments_by_charged_at()
      |> Repo.paginate(opts ++ [before: encode_cursor([p11.charged_at, p11.id])])

    assert to_ids(page.entries) == to_ids([p2, p12, p8, p9])
    assert page.metadata.before == encode_cursor([p2.charged_at, p2.id])

    page = payments_by_charged_at() |> Repo.paginate(opts ++ [before: page.metadata.before])
    assert to_ids(page.entries) == to_ids([p6, p7, p3, p10])
    assert page.metadata.before == encode_cursor([p6.charged_at, p6.id])

    page = payments_by_charged_at() |> Repo.paginate(opts ++ [before: page.metadata.before])
    assert to_ids(page.entries) == to_ids([p5, p4, p1])
    assert page.metadata.after == encode_cursor([p1.charged_at, p1.id])
    assert page.metadata.before == nil
  end

  test "returns an empty page when there are no results" do
    page =
      payments_by_status("failed")
      |> Repo.paginate(cursor_fields: [:charged_at, :id], limit: 10)

    assert page.entries == []
    assert page.metadata.after == nil
    assert page.metadata.before == nil
  end

  describe "paginate a collection of payments, sorting by charged_at" do
    test "sorts ascending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(cursor_fields: [:charged_at, :id], sort_direction: :asc, limit: 50)

      assert to_ids(entries) == to_ids([p5, p4, p1, p6, p7, p3, p10, p2, p12, p8, p9, p11])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    test "sorts ascending with before cursor", %{
      payments: {p1, p2, p3, _p4, _p5, p6, p7, p8, p9, p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :asc,
          before: encode_cursor([p9.charged_at, p9.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p1, p6, p7, p3, p10, p2, p12, p8])

      assert metadata == %Metadata{
               after: encode_cursor([p8.charged_at, p8.id]),
               before: encode_cursor([p1.charged_at, p1.id]),
               limit: 8
             }
    end

    test "sorts ascending with after cursor", %{
      payments: {_p1, p2, p3, _p4, _p5, _p6, _p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :asc,
          after: encode_cursor([p3.charged_at, p3.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p10, p2, p12, p8, p9, p11])

      assert metadata == %Metadata{
               after: nil,
               before: encode_cursor([p10.charged_at, p10.id]),
               limit: 8
             }
    end

    test "sorts ascending with before and after cursor", %{
      payments: {_p1, p2, p3, _p4, _p5, _p6, _p7, p8, _p9, p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :asc,
          after: encode_cursor([p3.charged_at, p3.id]),
          before: encode_cursor([p8.charged_at, p8.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p10, p2, p12])

      assert metadata == %Metadata{
               after: encode_cursor([p12.charged_at, p12.id]),
               before: encode_cursor([p10.charged_at, p10.id]),
               limit: 8
             }
    end

    test "sorts descending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(cursor_fields: [:charged_at, :id], sort_direction: :desc, limit: 50)

      assert to_ids(entries) == to_ids([p11, p9, p8, p12, p2, p10, p3, p7, p6, p1, p4, p5])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    test "sorts descending with before cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, p9, _p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          before: encode_cursor([p9.charged_at, p9.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p11])

      assert metadata == %Metadata{
               after: encode_cursor([p11.charged_at, p11.id]),
               before: nil,
               limit: 8
             }
    end

    test "sorts descending with after cursor", %{
      payments: {p1, p2, p3, _p4, _p5, p6, p7, p8, p9, p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          after: encode_cursor([p9.charged_at, p9.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p8, p12, p2, p10, p3, p7, p6, p1])

      assert metadata == %Metadata{
               after: encode_cursor([p1.charged_at, p1.id]),
               before: encode_cursor([p8.charged_at, p8.id]),
               limit: 8
             }
    end

    test "sorts descending with before and after cursor", %{
      payments: {_p1, p2, p3, _p4, _p5, _p6, _p7, p8, p9, p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          after: encode_cursor([p9.charged_at, p9.id]),
          before: encode_cursor([p3.charged_at, p3.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p8, p12, p2, p10])

      assert metadata == %Metadata{
               after: encode_cursor([p10.charged_at, p10.id]),
               before: encode_cursor([p8.charged_at, p8.id]),
               limit: 8
             }
    end

    test "sorts ascending with before cursor at beginning of collection", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :asc,
          before: encode_cursor([p5.charged_at, p5.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts ascending with after cursor at end of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at()
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :asc,
          after: encode_cursor([p11.charged_at, p11.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts descending with before cursor at beginning of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          before: encode_cursor([p11.charged_at, p11.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts descending with after cursor at end of collection", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          after: encode_cursor([p5.charged_at, p5.id]),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end
  end

  describe "paginate a collection of payments with customer filter, sorting by amount, charged_at" do
    test "multiple cursor_fields with pre-existing where filter in query", %{
      customers: {c1, _c2, _c3},
      payments: {_p1, _p2, _p3, _p4, p5, p6, p7, p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: _metadata} =
        customer_payments_by_amount(c1)
        |> Repo.paginate(cursor_fields: [:amount, :charged_at, :id], limit: 50)

      assert to_ids(entries) == to_ids([p6, p5, p7, p8])
    end

    test "before cursor with multiple cursor_fields and pre-existing where filter in query", %{
      customers: {c1, _c2, _c3},
      payments: {_p1, _p2, _p3, _p4, _p5, p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      assert %Page{entries: [], metadata: _metadata} =
               customer_payments_by_amount(c1)
               |> Repo.paginate(
                 cursor_fields: [:amount, :charged_at, :id],
                 before: encode_cursor([p6.amount, p6.charged_at, p6.id]),
                 limit: 1
               )
    end
  end

  describe "paginate a collection of payments, sorting by customer name" do
    @tag :skip
    test "sorts ascending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(cursor_fields: [:id], sort_direction: :asc, limit: 50)

      assert to_ids(entries) == to_ids([p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    @tag :skip
    test "sorts ascending with before cursor", %{
      payments: {_p1, _p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          before: encode_cursor(p11.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p3, p4, p5, p6, p7, p8, p9, p10])

      assert metadata == %Metadata{
               after: encode_cursor(p10.id),
               before: encode_cursor(p3.id),
               limit: 8
             }
    end

    @tag :skip
    test "sorts ascending with after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          after: encode_cursor(p6.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p7, p8, p9, p10, p11, p12])
      assert metadata == %Metadata{after: nil, before: encode_cursor(p7.id), limit: 8}
    end

    @tag :skip
    test "sorts ascending with before and after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          after: encode_cursor(p6.id),
          before: encode_cursor(p10.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p7, p8, p9])

      assert metadata == %Metadata{
               after: encode_cursor(p9.id),
               before: encode_cursor(p7.id),
               limit: 8
             }
    end

    @tag :skip
    test "sorts descending without cursors", %{
      payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(cursor_fields: [:id], sort_direction: :desc, limit: 50)

      assert to_ids(entries) == to_ids([p12, p11, p10, p9, p8, p7, p6, p5, p4, p3, p2, p1])
      assert metadata == %Metadata{after: nil, before: nil, limit: 50}
    end

    @tag :skip
    test "sorts descending with before cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :desc,
          before: encode_cursor(p11.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p12])
      assert metadata == %Metadata{after: encode_cursor(p12.id), before: nil, limit: 8}
    end

    @tag :skip
    test "sorts descending with after cursor", %{
      payments: {_p1, _p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :desc,
          after: encode_cursor(p11.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p10, p9, p8, p7, p6, p5, p4, p3])

      assert metadata == %Metadata{
               after: encode_cursor(p3.id),
               before: encode_cursor(p10.id),
               limit: 8
             }
    end

    @tag :skip
    test "sorts descending with before and after cursor", %{
      payments: {_p1, _p2, _p3, _p4, _p5, p6, p7, p8, p9, p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :desc,
          after: encode_cursor(p11.id),
          before: encode_cursor(p6.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([p10, p9, p8, p7])

      assert metadata == %Metadata{
               after: encode_cursor(p7.id),
               before: encode_cursor(p10.id),
               limit: 8
             }
    end

    @tag :skip
    test "sorts ascending with before cursor at beginning of collection", %{
      payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          before: encode_cursor(p1.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    @tag :skip
    test "sorts ascending with after cursor at end of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          after: encode_cursor(p12.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    @tag :skip
    test "sorts descending with before cursor at beginning of collection", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :desc,
          before: encode_cursor(p12.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    @tag :skip
    test "sorts descending with after cursor at end of collection", %{
      payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_customer_name(:desc)
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :desc,
          after: encode_cursor(p1.id),
          limit: 8
        )

      assert to_ids(entries) == to_ids([])
      assert metadata == %Metadata{after: nil, before: nil, limit: 8}
    end

    test "sorts with respect to nil values", %{
      payments: {_p1, _p2, _p3, _p4, _p5, _p6, p7, _p8, _p9, _p10, p11, _p12}
    } do
      %Page{entries: entries, metadata: metadata} =
        payments_by_charged_at(:desc)
        |> Repo.paginate(
          cursor_fields: [:charged_at, :id],
          sort_direction: :desc,
          after: encode_cursor([nil, nil]),
          limit: 8
        )

        assert Enum.count(entries) == 8
        assert metadata == %Metadata{
          before: encode_cursor([p11.charged_at, p11.id]),
          limit: 8,
          after: encode_cursor([p7.charged_at, p7.id])
        }
    end
  end

  test "applies a default limit if none is provided", %{
    payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}
  } do
    %Page{entries: entries, metadata: metadata} =
      payments_by_customer_name()
      |> Repo.paginate(cursor_fields: [:id], sort_direction: :asc)

    assert to_ids(entries) == to_ids([p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12])
    assert metadata == %Metadata{after: nil, before: nil, limit: 50}
  end

  test "enforces the minimum limit", %{
    payments: {p1, _p2, _p3, _p4, _p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
  } do
    %Page{entries: entries, metadata: metadata} =
      payments_by_customer_name()
      |> Repo.paginate(cursor_fields: [:id], sort_direction: :asc, limit: 0)

    assert to_ids(entries) == to_ids([p1])
    assert metadata == %Metadata{after: encode_cursor(p1.id), before: nil, limit: 1}
  end

  describe "with include_total_count" do
    test "when set to :infinity", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          limit: 5,
          total_count_limit: :infinity,
          include_total_count: true
        )

      assert metadata == %Metadata{
               after: encode_cursor(p5.id),
               before: nil,
               limit: 5,
               total_count: 12,
               total_count_cap_exceeded: false
             }
    end

    test "when cap not exceeded", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          limit: 5,
          include_total_count: true
        )

      assert metadata == %Metadata{
               after: encode_cursor(p5.id),
               before: nil,
               limit: 5,
               total_count: 12,
               total_count_cap_exceeded: false
             }
    end

    test "when cap exceeded", %{
      payments: {_p1, _p2, _p3, _p4, p5, _p6, _p7, _p8, _p9, _p10, _p11, _p12}
    } do
      %Page{metadata: metadata} =
        payments_by_customer_name()
        |> Repo.paginate(
          cursor_fields: [:id],
          sort_direction: :asc,
          limit: 5,
          include_total_count: true,
          total_count_limit: 10
        )

      assert metadata == %Metadata{
               after: encode_cursor(p5.id),
               before: nil,
               limit: 5,
               total_count: 10,
               total_count_cap_exceeded: true
             }
    end

    test "when custom total_count_primary_key_field", %{
      addresses: {_a1, a2, _a3}
    } do
      %Page{metadata: metadata} =
        from(a in Address, select: a)
        |> Repo.paginate(
          cursor_fields: [:city],
          sort_direction: :asc,
          limit: 2,
          include_total_count: true,
          total_count_primary_key_field: :city
        )

      assert metadata == %Metadata{
               after: encode_cursor(a2.city),
               before: nil,
               limit: 2,
               total_count: 3,
               total_count_cap_exceeded: false
             }
    end
  end

  test "per-record cursor generation", %{
    payments: {p1, _p2, _p3, _p4, _p5, _p6, p7, _p8, _p9, _p10, _p11, _p12}
  } do
    assert Paginator.cursor_for_record(p1, [:charged_at, :id])
    == encode_cursor([p1.charged_at, p1.id])

    assert Paginator.cursor_for_record(p7, [:amount])
    == encode_cursor([p7.amount])
  end

  defp to_ids(entries), do: Enum.map(entries, & &1.id)

  defp create_customers_and_payments(_context) do
    c1 = insert(:customer, %{name: "Bob"})
    c2 = insert(:customer, %{name: "Alice"})
    c3 = insert(:customer, %{name: "Charlie"})

    a1 = insert(:address, city: "London", customer: c1)
    a2 = insert(:address, city: "New York", customer: c2)
    a3 = insert(:address, city: "Tokyo", customer: c3)

    p1 = insert(:payment, customer: c2, charged_at: days_ago(11))
    p2 = insert(:payment, customer: c2, charged_at: days_ago(6))
    p3 = insert(:payment, customer: c2, charged_at: days_ago(8))
    p4 = insert(:payment, customer: c2, amount: 2, charged_at: days_ago(12))

    p5 = insert(:payment, customer: c1, amount: 3, charged_at: days_ago(13))
    p6 = insert(:payment, customer: c1, amount: 2, charged_at: days_ago(10))
    p7 = insert(:payment, customer: c1, amount: 4, charged_at: days_ago(9))
    p8 = insert(:payment, customer: c1, amount: 5, charged_at: days_ago(4))

    p9 = insert(:payment, customer: c3, charged_at: days_ago(3))
    p10 = insert(:payment, customer: c3, charged_at: days_ago(7))
    p11 = insert(:payment, customer: c3, charged_at: days_ago(2))
    p12 = insert(:payment, customer: c3, charged_at: days_ago(5))

    {:ok, customers: {c1, c2, c3}, addresses: {a1, a2, a3}, payments: {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12}}
  end

  defp payments_by_status(status, direction \\ :asc) do
    from(
      p in Payment,
      where: p.status == ^status,
      order_by: [{^direction, p.charged_at}, {^direction, p.id}],
      select: p
    )
  end

  defp payments_by_charged_at(direction \\ :asc) do
    from(
      p in Payment,
      order_by: [{^direction, p.charged_at}, {^direction, p.id}],
      select: p
    )
  end

  defp payments_by_customer_name(direction \\ :asc) do
    from(
      p in Payment,
      join: c in assoc(p, :customer),
      order_by: [{^direction, c.name}, {^direction, p.id}],
      select: p
    )
  end

  defp customer_payments_by_amount(customer, direction \\ :asc) do
    from(
      p in Payment,
      where: p.customer_id == ^customer.id,
      order_by: [{^direction, p.amount}, {^direction, p.charged_at}, {^direction, p.id}]
    )
  end

  defp encode_cursor(value) do
    Cursor.encode(value)
  end

  defp days_ago(days) do
    DT.add!(DateTime.utc_now(), -(days * 86400))
  end
end
