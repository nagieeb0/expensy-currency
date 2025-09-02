defmodule ExpensyWeb.ExpenseLive.Show do
  use ExpensyWeb, :live_view

  alias Expensy.Wallet

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Expense {@expense.id}
        <:subtitle>This is a expense record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/wallet"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/expenses/#{@expense}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit expense
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@expense.name}</:item>
        <:item title="Description">{@expense.description}</:item>
        <:item title="Amount">{@expense.amount}</:item>
        <:item title="Date">{@expense.date}</:item>
        <:item title="Currency">{@expense.currency}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Expense")
     |> assign(:expense, Wallet.get_expense!(id))}
  end
end
