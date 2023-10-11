defmodule Paginator.Payment do
  use Ecto.Schema

  import Ecto.Query

  schema "payments" do
    field(:amount, :integer)
    field(:charged_at, :utc_datetime)
    field(:description, :string)
    field(:status, :string)

    belongs_to(:customer, Paginator.Customer)

    timestamps()
  end

  def successful(query) do
    where(query, [p], p.status == "success")
  end

  def failed(query) do
    where(query, [p], p.status == "failed")
  end
end
