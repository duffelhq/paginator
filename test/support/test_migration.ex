defmodule Paginator.TestMigration do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add(:name, :string)
      add(:active, :boolean)

      timestamps()
    end

    create table(:payments) do
      add(:description, :text)
      add(:amount, :integer)
      add(:status, :string)

      add(:customer_id, references(:customers))

      timestamps()
    end
  end
end
