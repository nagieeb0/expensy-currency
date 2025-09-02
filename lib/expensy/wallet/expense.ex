defmodule Expensy.Wallet.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  this module is the schema for the expense and everything related to it of feilds
  """
  schema "expenses" do
    field :name, :string
    field :description, :string
    field :amount, :decimal
    field :date, :date
    field :currency, :string, default: "USD"
    belongs_to :category, Expensy.Wallet.Category
    timestamps(type: :utc_datetime)
  end

  @allowed_currencies ~w(USD EUR GBP)

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:name, :description, :amount, :date, :category_id, :currency])
    |> validate_required([:name, :description, :amount, :date, :category_id, :currency])
    |> validate_inclusion(:currency, @allowed_currencies)
    |> validate_number(:amount,
      greater_than: 0,
      less_than: 1_000_000,
      message: "Amount must be between 0 and 1,000,000"
    )
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_change(:date, fn :date, date ->
      if Date.compare(date, Date.utc_today()) == :gt do
        [date: "Date cannot be in the future"]
      else
        []
      end
    end)
    |> foreign_key_constraint(:category_id)
    |> check_constraint(:amount, name: :amount_must_be_positive)
  end
end
