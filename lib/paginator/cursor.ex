defmodule Paginator.Cursor do
  @moduledoc false
  def decode(nil), do: nil

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!()
    |> :erlang.binary_to_term([:safe])
    |> Enum.map(&Paginator.Cursor.Decode.convert/1)
  end

  def encode(values) when is_list(values) do
    values
    |> Enum.map(&Paginator.Cursor.Encode.convert/1)
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end

  def encode(value) do
    encode([value])
  end
end

defprotocol Paginator.Cursor.Encode do
  @fallback_to_any true

  def convert(term)
end

defprotocol Paginator.Cursor.Decode do
  @fallback_to_any true

  def convert(term)
end

defimpl Paginator.Cursor.Encode, for: Any do
  def convert(term), do: term
end

defimpl Paginator.Cursor.Decode, for: Any do
  def convert(term), do: term
end
