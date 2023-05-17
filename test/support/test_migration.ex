defmodule Paginator.TestMigration do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add(:name, :string)
      add(:active, :boolean)
      add(:internal_uuid, :uuid, null: false)

      timestamps()
    end

    create table(:payments) do
      add(:description, :text)
      add(:charged_at, :utc_datetime)
      add(:amount, :integer)
      add(:status, :string)

      add(:customer_id, references(:customers))

      timestamps()
    end

    create table(:addresses, primary_key: false) do
      add(:city, :string, primary_key: true)

      add(:customer_id, references(:customers))
    end
  end
end
