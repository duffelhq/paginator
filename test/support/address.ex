defmodule Paginator.Address do
  use Ecto.Schema

  @primary_key {:city, :string, autogenerate: false}

  schema "addresses" do
    belongs_to(:customer, Paginator.Customer)
  end
end
