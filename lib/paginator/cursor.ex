defmodule Paginator.Cursor do
  @callback decode(String.t(), opts :: list()) :: {:ok, term} | {:error, term}
  @callback decode!(String.t(), opts :: list()) :: term
  @callback encode(cursor_fields :: term, opts :: list()) ::
              {:ok, encoded :: String.t()} | {:error, term}
  @callback encode!(cursor_fields :: term, opts :: list()) :: encoded :: String.t()
end
