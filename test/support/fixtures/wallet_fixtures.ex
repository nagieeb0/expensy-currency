defmodule Expensy.WalletFixtures do
  alias Expensy.Wallet

  @moduledoc """
  This is the fixture of the wallet to be used while testing
  """

  def unique_name, do: "some name"

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: unique_name(),
        description: "some description",
        monthly_budget: "120.50"
      })
      |> Wallet.create_category()

    category
  end

  def expense_fixture(attrs \\ %{}) do
    category = Map.get(attrs, :category) || category_fixture()

    base = %{
      name: "some name",
      description: "some description",
      amount: "120.50",
      date: ~D[2025-08-19],
      category_id: category.id
    }

    {:ok, expense} =
      attrs
      |> Enum.into(base)
      |> Wallet.create_expense()

    expense
  end
end
