defmodule Expensy.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :name, :string
      add :description, :text
      add :amount, :decimal, precision: 15, scale: 2, null: false
      add :date, :date
      add :category_id, references(:categories, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:expenses, [:category_id])
    create constraint(:expenses, :amount_must_be_positive, check: "amount > 0")
  end
end
