defmodule ExpensyWeb.ExpenseLive.Index do
  use ExpensyWeb, :live_view

  alias Expensy.Wallet

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Expenses
        <:actions>
          <.button variant="primary" navigate={~p"/expenses/new"}>
            <.icon name="hero-plus" /> New Expense
          </.button>
        </:actions>
      </.header>

      <.table
        id="expenses"
        rows={@streams.expenses}
        row_click={fn {_id, expense} -> JS.navigate(~p"/expenses/#{expense}") end}
      >
        <:col :let={{_id, expense}} label="Name">{expense.name}</:col>
        <:col :let={{_id, expense}} label="Description">{expense.description}</:col>
        <:col :let={{_id, expense}} label="Amount">{expense.amount}</:col>
        <:col :let={{_id, expense}} label="Date">{expense.date}</:col>
        <:col :let={{_id, expense}} label="Currency">{expense.currency}</:col>
        <:action :let={{_id, expense}}>
          <div class="sr-only">
            <.link navigate={~p"/expenses/#{expense}"}>Show</.link>
          </div>
          <.link navigate={~p"/expenses/#{expense}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, expense}}>
          <.link
            phx-click={JS.push("delete", value: %{id: expense.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    categories = Wallet.list_categories()

    {:ok,
     socket
     |> assign(:page_title, "Listing Expenses")
     |> assign(:categories, categories)
     |> stream(:expenses, Wallet.list_expenses())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    expense = Wallet.get_expense!(id)
    {:ok, _} = Wallet.delete_expense(expense)

    {:noreply, stream_delete(socket, :expenses, expense)}
  end
end
