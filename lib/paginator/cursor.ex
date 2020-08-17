defmodule Paginator.Cursor do
  @moduledoc false

  def decode(nil), do: nil

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!()
    |> :erlang.binary_to_term([:safe])
  end

  def encode(values) when is_map(values) do
    values
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end
end
