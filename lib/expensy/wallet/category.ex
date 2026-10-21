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
  end
end
