defmodule Paginator.CursorTest do
  use ExUnit.Case, async: true

  alias Paginator.Cursor

  describe "encoding and decoding terms" do
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
