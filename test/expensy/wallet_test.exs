defmodule Expensy.WalletTest do
  use Expensy.DataCase

  alias Expensy.Wallet

  describe "categories" do
    alias Expensy.Wallet.Category

    import Expensy.WalletFixtures

    @invalid_attrs %{name: nil, description: nil, monthly_budget: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      [c] = Wallet.list_categories()
      assert c.id == category.id
      assert c.name == category.name
      assert c.description == category.description
      assert Decimal.equal?(c.monthly_budget, category.monthly_budget)
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      c = Wallet.get_category!(category.id)
      assert c.id == category.id
      assert c.name == category.name
      assert c.description == category.description
      assert Decimal.equal?(c.monthly_budget, category.monthly_budget)
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name", description: "some description", monthly_budget: "120.5"}

      assert {:ok, %Category{} = category} = Wallet.create_category(valid_attrs)
      assert category.name == "some name"
      assert category.description == "some description"
      assert category.monthly_budget == Decimal.new("120.5")
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Wallet.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        monthly_budget: "456.7"
      }

      assert {:ok, %Category{} = category} = Wallet.update_category(category, update_attrs)
      assert category.name == "some updated name"
      assert category.description == "some updated description"
      assert category.monthly_budget == Decimal.new("456.7")
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Wallet.update_category(category, @invalid_attrs)
      c = Wallet.get_category!(category.id)
      assert c.id == category.id
      assert c.name == category.name
      assert c.description == category.description
      assert Decimal.equal?(c.monthly_budget, category.monthly_budget)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Wallet.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Wallet.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Wallet.change_category(category)
    end
  end

  describe "expenses" do
    alias Expensy.Wallet.Expense

    import Expensy.WalletFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil, amount: nil}

    test "list_expenses/0 returns all expenses" do
      expense = expense_fixture()
      assert Wallet.list_expenses() == [expense]
    end

    test "get_expense!/1 returns the expense with given id" do
      expense = expense_fixture()
      assert Wallet.get_expense!(expense.id) == expense
    end

    test "create_expense/1 with valid data creates a expense" do
      category = category_fixture()

      valid_attrs = %{
        name: "some name",
        date: ~D[2025-08-19],
        description: "some description",
        amount: "120.50",
        category_id: category.id
      }

      assert {:ok, %Expense{} = expense} = Wallet.create_expense(valid_attrs)
      assert expense.name == "some name"
      assert expense.date == ~D[2025-08-19]
      assert expense.description == "some description"
      assert Decimal.equal?(expense.amount, Decimal.new("120.50"))
      assert expense.category_id == category.id
    end

    test "create_expense/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Wallet.create_expense(@invalid_attrs)
    end

    test "update_expense/2 with valid data updates the expense" do
      expense = expense_fixture()

      update_attrs = %{
        name: "some updated name",
        date: ~D[2025-08-20],
        description: "some updated description",
        amount: "456.7"
      }

      assert {:ok, %Expense{} = expense} = Wallet.update_expense(expense, update_attrs)
      assert expense.name == "some updated name"
      assert expense.date == ~D[2025-08-20]
      assert expense.description == "some updated description"
      assert expense.amount == Decimal.new("456.7")
    end

    test "update_expense/2 with invalid data returns error changeset" do
      expense = expense_fixture()
      assert {:error, %Ecto.Changeset{}} = Wallet.update_expense(expense, @invalid_attrs)
      assert expense == Wallet.get_expense!(expense.id)
    end

    test "delete_expense/1 deletes the expense" do
      expense = expense_fixture()
      assert {:ok, %Expense{}} = Wallet.delete_expense(expense)
      assert_raise Ecto.NoResultsError, fn -> Wallet.get_expense!(expense.id) end
    end

    test "change_expense/1 returns a expense changeset" do
      expense = expense_fixture()
      assert %Ecto.Changeset{} = Wallet.change_expense(expense)
    end
  end
end
