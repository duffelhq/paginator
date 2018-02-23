defmodule Paginator.Cursors.EncryptedCursor do
  @behaviour Paginator.Cursor
  @moduledoc false

  alias Plug.Crypto.MessageEncryptor

  def decode(nil, _opts), do: nil

  def decode(encrypted_cursor, opts) do
    {:ok, binary} = MessageEncryptor.decrypt(encrypted_cursor, opts[:encryption_key], opts[:signing_key])
    Plug.Crypto.safe_binary_to_term(binary)
  end

  def encode(values, opts) when is_list(values) do
    encrypt_cursor(values, opts)
  end

  def encode(value, opts) do
    encode([value], opts)
  end

  defp encrypt_cursor(term, opts) do
    MessageEncryptor.encrypt(
      :erlang.term_to_binary(term),
      opts[:encryption_key], # encryption key
      opts[:signing_key] # signing key
    )
  end
end
