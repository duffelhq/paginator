defmodule Paginator.Cursor do
  @moduledoc false

  def decode(nil), do: nil

  def decode(encoded_cursor) do
    encoded_cursor
    |> Base.url_decode64!()
    |> Plug.Crypto.non_executable_binary_to_term([:safe])
  end

  def encode(values) when is_map(values) do
    values
    |> Map.to_list()
    |> Enum.sort()
    |> :maps.from_list()
    |> :erlang.term_to_binary([:deterministic, {:minor_version, 1}])
    |> Base.url_encode64()
  end
end
