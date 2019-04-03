defmodule Paginator.CursorTest do
  use ExUnit.Case, async: true

  defmodule MYTEST1 do
    defstruct id: nil
  end

  defmodule MYTEST2 do
    defstruct id: nil
  end

  defimpl Paginator.Cursor.Encode, for: MYTEST1 do
    def convert(term), do: {:m1, term.id}
  end

  defimpl Paginator.Cursor.Decode, for: Tuple do
    def convert({:m1, id}), do: %MYTEST1{id: id}
  end

  alias Paginator.Cursor

  describe "encoding and decoding terms" do
    test "cursor for struct with custom implementation is shorter" do
      cursor1 = Cursor.encode([%MYTEST1{id: 1}])

      assert Cursor.decode(cursor1) == [%MYTEST1{id: 1}]

      cursor2 = Cursor.encode([%MYTEST2{id: 1}])

      assert Cursor.decode(cursor2) == [%MYTEST2{id: 1}]
      assert bit_size(cursor1) < bit_size(cursor2)
    end

    test "list of lists " do
      cursor = Cursor.encode([[1]])

      assert Cursor.decode(cursor) == [[1]]
    end

    test "it wraps terms into lists" do
      cursor = Cursor.encode(1)

      assert Cursor.decode(cursor) == [1]
    end

    test "it doesn't wrap a list in a list" do
      cursor = Cursor.encode([1])

      assert Cursor.decode(cursor) == [1]
      refute Cursor.decode(cursor) == [[1]]
    end
  end

  describe "Cursor.decode/1" do
    test "it safely decodes user input" do
      assert_raise ArgumentError, fn ->
        # this binary represents the atom :fubar_0a1b2c3d4e
        <<131, 100, 0, 16, "fubar_0a1b2c3d4e">>
        |> Base.url_encode64()
        |> Cursor.decode()
      end
    end
  end
end
