defmodule Paginator.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox, as: EctoSandbox

  using _opts do
    quote do
      alias Paginator.Repo

      import Ecto
      import Ecto.Query
      import Paginator.Factory

      alias Paginator.{Page, Page.Metadata}
      alias Paginator.{Address, Customer, Payment}
    end
  end

  setup tags do
    :ok = EctoSandbox.checkout(Paginator.Repo)

    unless tags[:async] do
      EctoSandbox.mode(Paginator.Repo, {:shared, self()})
    end

    :ok
  end
end
