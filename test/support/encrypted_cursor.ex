defmodule Paginator.Cursors.EncryptedCursor do
  @behaviour Paginator.Cursor
  @moduledoc """
  Example encrypted cursor using plug MessageEncryptor
  Modeled after Plug.Crypto.COOKIE
  """

  alias Plug.Crypto.MessageEncryptor

  def decode(nil, _opts), do: nil

  def decode(encrypted_cursor, opts) do
    with {:ok, binary} <-
           MessageEncryptor.decrypt(encrypted_cursor, opts[:encryption_key], opts[:signing_key]),
         term <- Plug.Crypto.safe_binary_to_term(binary) do
      {:ok, term}
    else
      _err -> {:error, "Could not decode encrypted cursor"}
    end
  end

  def decode!(encrypted_cursor, opts) do
    with {:ok, decoded} <- decode(encrypted_cursor, opts) do
      decoded
    end
  end

  def encode(values, opts) when is_list(values) do
    encrypt_cursor(values, opts)
  end

  def encode(value, opts) do
    encode([value], opts)
  end

  def encode!(value, opts) do
    with {:ok, encoded} <- encode(value, opts) do
      encoded
    end
  end

  defp encrypt_cursor(term, opts) do
    with encrypted_cursor <-
           MessageEncryptor.encrypt(
             :erlang.term_to_binary(term),
             opts[:encryption_key],
             opts[:signing_key]
           ) do
      {:ok, encrypted_cursor}
    end
  end
end
