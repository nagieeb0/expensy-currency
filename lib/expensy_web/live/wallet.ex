defmodule ExpensyWeb.Wallet do
  use ExpensyWeb, :live_view
  alias Expensy.Wallet

  @moduledoc """
  This is the liveview of the wallet
  I Used it to collect all the UI Elements and utilize some metrics and funcs
  """

  @currency "USD"

  @impl true
  def mount(_params, _session, socket) do
    categories = Wallet.list_categories()

    metrics =
      categories
      |> Enum.map(fn c ->
        {c.id, Map.merge(%{category: c}, Wallet.category_metrics(c.id, c.monthly_budget))}
      end)
      |> Map.new()

    {:ok,
     socket
     |> assign(:categories, categories)
     |> assign(:metrics, metrics)}
  end

  @impl true
  def handle_event("add_expense", %{"category_id" => category_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/expenses/new?category_id=#{category_id}")}
  end

  @impl true
  def handle_event("view_category", %{"category_id" => category_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/categories/#{category_id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>

    <!-- Header -->
      <div class="bg-base-100 border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <h1 class="text-2xl sm:text-3xl font-bold text-base-content">Wallet</h1>
              <p class="text-sm sm:text-base text-base-content/70">
                Track and manage your spending per category
              </p>
            </div>
            <div class="flex gap-2">
              <.link navigate={~p"/expenses/new"} class="btn btn-primary">
                Add Expense
              </.link>
              <.link navigate={~p"/categories/new"} class="btn btn-neutral gap-2">
                New Category
              </.link>
            </div>
          </div>
        </div>
      </div>

      <%= unless Enum.empty?(@categories) do %>
        <div class="stats bg-base-100 border-base-300 border">
          <div class="stat">
            <div class="stat-title">Total Balance</div>
            <div class="stat-value text-success ">{format_money(total_budget(@categories))}</div>
          </div>
          <div class="stat">
            <div class="stat-title">Total Spent</div>
            <div class="stat-value text-error ">{format_money(total_spent(@metrics))}</div>
          </div>

          <div class="stat">
            <div class="stat-title">Categories</div>
            <div class="stat-value ">{length(@categories)}</div>
          </div>
        </div>
      <% end %>

    <!-- Empty state -->
      <%= if Enum.empty?(@categories) do %>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="hero min-h-[60vh] bg-base-100 rounded-2xl mt-8">
            <div class="hero-content text-center">
              <div class="max-w-md">
                <div class="text-7xl mb-4">💰</div>
                <h2 class="text-3xl font-bold">No categories yet</h2>
                <p class="text-base-content/70 mt-2 mb-6">
                  Create your first budget category to start tracking.
                </p>
                <div class="flex flex-col sm:flex-row gap-2 justify-center">
                  <.link navigate={~p"/categories/new"} class="btn btn-primary">
                    Create Category
                  </.link>
                  <.link navigate={~p"/expenses/new"} class="btn btn-outline">Add Expense</.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% else %>

    <!-- Category Cards -->
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-6 mb-10">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
            <%= for cat <- @categories do %>
              <% m = @metrics[cat.id] %>
              <div class="card bg-base-100 shadow hover:shadow-lg transition-all rounded-2xl">
                <div class={[
                  "h-1 w-full",
                  case m.alert do
                    :ok -> "bg-success"
                    :near -> "bg-warning"
                    :over -> "bg-error"
                    _ -> "bg-primary"
                  end
                ]}>
                </div>

                <div class="card-body gap-3">
                  <!-- Header -->
                  <div class="flex items-start justify-between">
                    <div class="flex items-center gap-3">
                      <div class="avatar placeholder"></div>
                      <div>
                        <h3 class="text-lg font-semibold text-base-content">{cat.name}</h3>
                        <p class="text-xs text-base-content/60">Budget category</p>
                      </div>
                    </div>
                    <%= if m.over_budget? do %>
                      <div class="badge badge-error badge-sm">Over</div>
                    <% end %>
                  </div>

    <!-- Numbers -->
                  <div class="bg-base-200/50 rounded-xl p-3 space-y-3">
                    <!-- Budget -->
                    <div class="text-center">
                      <div class="text-xs text-base-content/60">Budget</div>
                      <div class="text-md font-semibold">
                        {if cat.monthly_budget, do: format_money(cat.monthly_budget), else: "∞"}
                      </div>
                    </div>

    <!-- Spent -->
                    <div class="text-center">
                      <div class="text-xs text-base-content/60">Spent</div>
                      <div class={[
                        "text-md text-error font-semibold",
                        (m.over_budget? && "text-error") || ""
                      ]}>
                        {format_money(m.spent)}
                      </div>
                    </div>

    <!-- Remaining -->
                    <div class="text-center">
                      <div class="text-xs text-base-content/60">Remaining</div>
                      <div class={[
                        "text-md font-semibold",
                        if(decimal_lt_zero?(m.remaining), do: "text-error", else: "text-success")
                      ]}>
                        {format_money(m.remaining)}
                      </div>
                    </div>
                  </div>

    <!-- Progress -->
                  <%= if cat.monthly_budget do %>
                    <div>
                      <div class="flex justify-between text-xs mb-1">
                        <span class="text-base-content/60">Progress</span>
                        <span class="font-medium">{min(m.progress_value, 100)}%</span>
                      </div>
                      <progress
                        class={[
                          "progress w-full h-2",
                          case m.alert do
                            :ok -> "progress-success"
                            :near -> "progress-warning"
                            :over -> "progress-error"
                            _ -> "progress-primary"
                          end
                        ]}
                        value={min(m.progress_value, 100)}
                        max="100"
                      >
                      </progress>
                      <%= if m.progress_value > 100 do %>
                        <div class="mt-1 text-[11px] text-error">+{m.progress_value - 100}% over</div>
                      <% end %>
                    </div>
                  <% end %>

    <!-- Status -->
                  <%= cond do %>
                    <% m.over_budget? -> %>
                      <div class="alert alert-error py-2 px-3 rounded-xl">
                        <span class="text-xs">Over by {format_money(Decimal.abs(m.remaining))}</span>
                      </div>
                    <% m.alert == :near -> %>
                      <div class="alert alert-warning py-2 px-3 rounded-xl">
                        <span class="text-xs">Approaching budget</span>
                      </div>
                    <% cat.monthly_budget == nil -> %>
                      <div class="alert alert-info py-2 px-3 rounded-xl">
                        <span class="text-xs">No budget set</span>
                      </div>
                    <% true -> %>
                      <div class="text-xs text-success">Within budget</div>
                  <% end %>

    <!-- Actions -->
                  <div class="card-actions justify-end pt-2">
                    <button
                      phx-click="add_expense"
                      phx-value-category_id={cat.id}
                      class="btn btn-sm btn-outline"
                    >
                      Add Expense
                    </button>
                    <button
                      phx-click="view_category"
                      phx-value-category_id={cat.id}
                      class="btn btn-sm btn-primary"
                    >
                      Details
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(nil), do: Decimal.new(0)
  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(n) when is_float(n), do: Decimal.from_float(n)
  defp to_decimal(bin) when is_binary(bin), do: Decimal.new(bin)
  defp to_decimal(_), do: Decimal.new(0)

  # تنسيق عملة بدقة (2 منازل + فاصلات آلاف) بدون Floats
  defp format_money(term) do
    term
    |> to_decimal()
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> ensure_two_decimals()
    |> add_thousands()
    |> then(&(&1 <> " #{@currency}"))
  end

  defp ensure_two_decimals(str) do
    case String.split(str, ".", parts: 2) do
      [i] -> i <> ".00"
      [i, f] when byte_size(f) == 1 -> i <> "." <> f <> "0"
      [i, f] when byte_size(f) >= 2 -> i <> "." <> String.slice(f, 0, 2)
    end
  end

  defp add_thousands(str) do
    [int, frac] = String.split(str, ".", parts: 2)
    sign = if String.starts_with?(int, "-"), do: "-", else: ""
    int = String.trim_leading(int, "-")

    int_with_commas =
      int
      |> String.to_charlist()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.intersperse(~c',')
      |> List.flatten()
      |> Enum.reverse()
      |> to_string()

    sign <> int_with_commas <> "." <> frac
  end

  defp total_spent(metrics) do
    metrics
    |> Enum.reduce(Decimal.new(0), fn {_id, %{spent: spent}}, acc ->
      Decimal.add(acc, to_decimal(spent))
    end)
  end

  # defp count_over_budget(metrics) do
  #   Enum.count(metrics, fn {_id, %{over_budget?: over?}} -> over? end)
  # end

  defp total_budget(categories) do
    categories
    |> Enum.reduce(Decimal.new(0), fn cat, acc ->
      Decimal.add(acc, to_decimal(cat.monthly_budget))
    end)
  end

  defp decimal_lt_zero?(term), do: Decimal.compare(to_decimal(term), 0) == :lt
end
