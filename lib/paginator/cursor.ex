defmodule Paginator.Cursor do
  @callback decode(String.t(), opts :: list()) :: term
  @callback encode(arg :: term, opts :: list()) :: String.t()
  @callback decode(String.t()) :: term
  @callback encode(arg :: term) :: String.t()
  @optional_callbacks encode: 1, decode: 1
end
