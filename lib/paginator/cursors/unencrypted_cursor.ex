defmodule Paginator.Cursors.UnencryptedCursor do
  @behaviour Paginator.Cursor
  @moduledoc false

  def decode(encoded_cursor), do: decode(encoded_cursor, nil)

  def decode(nil, _opts), do: nil

  def decode(encoded_cursor, _opts) do
    encoded_cursor
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end

  def encode(value), do: encode(value, nil)

  def encode(values, _opts) when is_list(values) do
    values
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end

  def encode(value, opts) do
    encode([value], opts)
  end
end
