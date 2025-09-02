defmodule Expensy.Wallet.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  the category schema
  """

  schema "categories" do
    field :name, :string
    field :description, :string
    field :monthly_budget, :decimal

    timestamps(type: :utc_datetime)
    has_many :expenses, Expensy.Wallet.Expense, on_delete: :delete_all
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :monthly_budget])
    |> validate_required([:name, :monthly_budget])
    |> validate_length(:name, min: 3, max: 100)
    |> unique_constraint(:name)
    |> validate_length(:description, max: 500)
    |> validate_number(:monthly_budget,
      greater_than: 0,
      less_than: 1_000_000,
      message: "Budget must be between 0 and 1,000,000"
    )
    |> check_constraint(:monthly_budget, name: :monthly_budget_must_be_positive)
  end
end
