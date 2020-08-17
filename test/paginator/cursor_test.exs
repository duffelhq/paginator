defmodule Paginator.CursorTest do
  use ExUnit.Case, async: true

  alias Paginator.Cursor

  describe "encoding and decoding terms" do
    test "it encodes and decodes map cursors" do
      cursor = Cursor.encode(%{a: 1, b: 2})

      assert Cursor.decode(cursor) == %{a: 1, b: 2}
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
