defmodule Paginator.Cursor do
  @callback decode(String.t()) :: {:ok, term :: term} | {:error, term :: term}
  @callback encode(arg :: term) :: {:ok, encoded :: String.t()} | {:error, String.t()}
end
