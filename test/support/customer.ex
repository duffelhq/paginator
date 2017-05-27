defmodule Paginator.Customer do
  use Ecto.Schema

  import Ecto.Query

  schema "customers" do
    field :name, :string
    field :active, :boolean

    has_many :payments, Paginator.Payment

    timestamps()
  end

  def active(query) do
    query |> where([c], c.active == true)
  end
end
