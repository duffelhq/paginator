defmodule Paginator.Cursors.UnencryptedCursor do
  @behaviour Paginator.Cursor
  @moduledoc false

  def decode(cursor, opts \\ [])
  def decode(nil, _opts), do: nil

  def decode(encoded_cursor, _opts) do
    {:ok,
     encoded_cursor
     |> Base.url_decode64!()
     |> :erlang.binary_to_term()}
  end

  def decode!(encoded_cursor, opts \\ []) do
    with {:ok, decoded} <- decode(encoded_cursor, opts) do
      decoded
    end
  end

  def encode(values, opts \\ [])

  def encode(values, _opts) when is_list(values) do
    {:ok,
     values
     |> :erlang.term_to_binary()
     |> Base.url_encode64()}
  end

  def encode(value, opts) do
    encode([value], opts)
  end

  def encode!(value, opts \\ []) do
    with {:ok, encoded} <- encode(value, opts) do
      encoded
    end
  end
end
