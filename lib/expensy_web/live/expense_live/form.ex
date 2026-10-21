defmodule ExpensyWeb.ExpenseLive.Form do
  use ExpensyWeb, :live_view

  alias Expensy.Wallet
  alias Expensy.Wallet.Expense

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage expense records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="expense-form" phx-change="validate" phx-submit="save" class="space-y-6">
        <!-- Category segmented -->
        <div class="form-control">
          <label class="label">
            <span class="label-text font-medium">Category</span>
          </label>

          <.segmented
            options={Enum.map(@categories, &{&1.name, &1.id})}
            selected={@form[:category_id].value}
            phx_event="select_category"
            param_key="id"
            class="mb-2"
          />
                  <div class="mt-3">
          <button type="button" phx-click="new_category" class="btn btn-outline btn-sm gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-4 h-4"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Add Category
          </button>
        </div>

          <!-- keep selected category in payload -->
          <input type="hidden" name="expense[category_id]" value={@form[:category_id].value || ""} />

          <!-- show category error if any -->
          <%= if Enum.any?(@form.errors, fn {k, _} -> k == :category_id end) do %>
            <label class="label"><span class="label-text-alt text-error">can't be blank</span></label>
          <% end %>
        </div>

        <!-- Currency segmented -->
        <div class="form-control">
          <label class="label">
            <span class="label-text font-medium">Currency</span>
          </label>

          <% selected_currency =
              @form[:currency].value || "USD" %>

        <.segmented
          options={@currencies}
          selected={selected_currency}
          phx_event="select_currency"
          param_key="value"
        />

        <input type="hidden" name="expense[currency]" value={selected_currency} />
        </div>

        <!-- Fields -->
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="300" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:amount]} type="number" label="Amount" step="any" inputmode="decimal" />
        <.input field={@form[:date]} type="date" label="Date" />



        <footer class="flex gap-2">
          <.button phx-disable-with="Saving..." variant="primary">Save Expense</.button>
          <.button navigate={return_path(@return_to, @expense)} type="button">Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    categories = Wallet.list_categories()

    # {label, value}
    currencies = [
      {"USD", "USD"},
      {"EUR", "EUR"},
      {"GBP", "GBP"},
    ]

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:categories, categories)
     |> assign(:currencies, currencies)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    expense = Wallet.get_expense!(id)
    changeset = Wallet.change_expense(expense)

    socket
    |> assign(:page_title, "Edit Expense")
    |> assign(:expense, expense)
    |> assign(:form, to_form(changeset))
  end

defp apply_action(socket, :new, params) do
  expense = %Expense{}
  cats = socket.assigns.categories

  base_params =
    case params["category_id"] do
      nil ->
        case cats do
          [%{id: first_id} | _] -> %{"category_id" => first_id}
          _ -> %{}
        end
      id -> %{"category_id" => id}
    end
    |> Map.put_new("currency", "USD")

  changeset = Wallet.change_expense(expense, base_params)

  socket
  |> assign(:page_title, "New Expense")
  |> assign(:expense, expense)
  |> assign(:form, to_form(changeset))
end


  @impl true
  def handle_event("new_category", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/categories/new")}
  end

  @impl true
  def handle_event("validate", %{"expense" => expense_params}, socket) do
    changeset =
      socket.assigns.expense
      |> Wallet.change_expense(expense_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

def handle_event("select_category", params, socket) do
  id = params["id"] || params["value"] || params["category_id"] ||
         raise ArgumentError, "select_category missing id/value"
  id = if is_binary(id), do: String.to_integer(id), else: id

  changeset =
    socket.assigns.expense
    |> Wallet.change_expense(%{"category_id" => id})
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end


  @impl true
  def handle_event("select_currency", params, socket) do
    currency =
      params["value"] || params["id"] || params["currency"] ||
        raise ArgumentError, "select_currency missing value/id"

    # حدّث params بتاعة الفورم من غير action: :validate
    form = socket.assigns.form
    params = Map.put(form.params || %{}, "currency", currency)

    changeset =
      socket.assigns.expense
      |> Wallet.change_expense(params)  # مفيش Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end


  @impl true
  def handle_event("save", %{"expense" => expense_params}, socket) do
    save_expense(socket, socket.assigns.live_action, expense_params)
  end

  defp save_expense(socket, :edit, expense_params) do
    case Wallet.update_expense(socket.assigns.expense, expense_params) do
      {:ok, expense} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expense updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, expense))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_expense(socket, :new, expense_params) do
    case Wallet.create_expense(expense_params) do
      {:ok, expense} ->
        {:noreply,
         socket
         |> put_flash(:info, "Expense created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, expense))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _expense), do: ~p"/wallet"
  defp return_path("show", expense), do: ~p"/expenses/#{expense}"
end
