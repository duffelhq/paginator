defmodule Paginator.DataCase do
  use ExUnit.CaseTemplate

  using _opts do
    quote do
      alias Paginator.Repo

      import Ecto
      import Ecto.Query
      import Paginator.Factory

      alias Paginator.{Address, Customer, Page, Page.Metadata, Payment}
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Paginator.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Paginator.Repo, {:shared, self()})
    end

    :ok
  end
end
