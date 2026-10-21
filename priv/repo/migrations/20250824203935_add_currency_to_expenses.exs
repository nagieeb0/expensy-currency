defmodule Expensy.Repo.Migrations.AddCurrencyToExpenses do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      add :currency , :string , null: false , default: "USD"
    end
    create index(:expenses, [:currency])
  end
end
