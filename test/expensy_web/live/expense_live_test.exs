defmodule ExpensyWeb.ExpenseLiveTest do
  use ExpensyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Expensy.WalletFixtures

  @update_attrs %{
    name: "some updated name",
    date: "2025-08-20",
    description: "some updated description",
    amount: "456.7"
  }

  @invalid_attrs %{name: nil, date: nil, description: nil, amount: nil}

  defp create_expense(_) do
    expense = expense_fixture()
    %{expense: expense}
  end

  describe "Index" do
    setup [:create_expense]

    test "lists all expenses", %{conn: conn, expense: expense} do
      {:ok, _index_live, html} = live(conn, ~p"/expenses")
      assert html =~ "Listing Expenses"
      assert html =~ expense.name
    end

    test "updates expense in listing", %{conn: conn, expense: expense} do
      {:ok, index_live, _} = live(conn, ~p"/expenses")

      {:ok, form_live, _} =
        index_live
        |> element("#expenses-#{expense.id} a", "Edit")
        |> render_click()
        |> follow_redirect(conn, ~p"/expenses/#{expense}/edit")

      assert render(form_live) =~ "Edit Expense"

      assert form_live
             |> form("#expense-form", expense: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        form_live
        |> form("#expense-form", expense: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/wallet")

      assert html =~ "Expense updated successfully"

      # زيادة ضمانة: اتأكد إن الاسم فعلاً اتغير في DB
      updated = Expensy.Wallet.get_expense!(expense.id)
      assert updated.name == "some updated name"
    end

    test "deletes expense in listing", %{conn: conn, expense: expense} do
      {:ok, index_live, _html} = live(conn, ~p"/expenses")
      assert index_live |> element("#expenses-#{expense.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#expenses-#{expense.id}")
    end
  end

  describe "Show" do
    setup [:create_expense]

    test "displays expense", %{conn: conn, expense: expense} do
      {:ok, _show_live, html} = live(conn, ~p"/expenses/#{expense}")
      assert html =~ "Show Expense"
      assert html =~ expense.name
    end

    test "updates expense and returns to show", %{conn: conn, expense: expense} do
      {:ok, show_live, _html} = live(conn, ~p"/expenses/#{expense}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/expenses/#{expense}/edit?return_to=show")

      assert render(form_live) =~ "Edit Expense"

      assert form_live
             |> form("#expense-form", expense: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#expense-form", expense: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/expenses/#{expense}")

      html = render(show_live)
      assert html =~ "Expense updated successfully"
      assert html =~ "some updated name"
    end
  end
end
