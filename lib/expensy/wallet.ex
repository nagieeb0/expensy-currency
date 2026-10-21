defmodule Expensy.Wallet do
  @moduledoc """
  The Wallet context.
  """

  import Ecto.Query, warn: false
  alias Expensy.Repo

  alias Expensy.Wallet.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Expensy.Wallet.Expense

  @doc """
  Returns the list of expenses.

  ## Examples

      iex> list_expenses()
      [%Expense{}, ...]

  """
  def list_expenses do
    Repo.all(Expense)
  end

  @doc """
  Gets a single expense.

  Raises `Ecto.NoResultsError` if the Expense does not exist.

  ## Examples

      iex> get_expense!(123)
      %Expense{}

      iex> get_expense!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expense!(id), do: Repo.get!(Expense, id)

  @doc """
  Creates a expense.

  ## Examples

      iex> create_expense(%{field: value})
      {:ok, %Expense{}}

      iex> create_expense(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expense(attrs) do
    %Expense{}
    |> Expense.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a expense.

  ## Examples

      iex> update_expense(expense, %{field: new_value})
      {:ok, %Expense{}}

      iex> update_expense(expense, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a expense.

  ## Examples

      iex> delete_expense(expense)
      {:ok, %Expense{}}

      iex> delete_expense(expense)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expense(%Expense{} = expense) do
    Repo.delete(expense)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expense changes.

  ## Examples

      iex> change_expense(expense)
      %Ecto.Changeset{data: %Expense{}}

  """
  def change_expense(%Expense{} = expense, attrs \\ %{}) do
    Expense.changeset(expense, attrs)
  end

  def total_spent_for_category(category_id) do
    from(e in Expense,
      where: e.category_id == ^category_id,
      select: sum(e.amount)
    )
    |> Repo.one()
    |> case do
      nil -> Decimal.new(0)
      dec -> dec
    end
  end

  # lib/expense_tracker/finance.ex
  def spending_percent(%Decimal{} = monthly_budget, total_spent) do
    spent = normalize_decimal(total_spent)

    cond do
      Decimal.compare(monthly_budget, 0) in [:lt, :eq] ->
        if Decimal.compare(spent, 0) == :gt, do: Decimal.new(100), else: Decimal.new(0)

      true ->
        spent
        |> Decimal.div(monthly_budget)
        |> Decimal.mult(100)
        |> Decimal.round(0, :half_up)
    end
  end

  defp normalize_decimal(%Decimal{} = d), do: d
  defp normalize_decimal(nil), do: Decimal.new(0)
  defp normalize_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp normalize_decimal(n) when is_float(n), do: Decimal.from_float(n)
  defp normalize_decimal(bin) when is_binary(bin), do: Decimal.new(bin)
  defp normalize_decimal(_), do: Decimal.new(0)

  def remaining_budget(%Decimal{} = monthly_budget, total_spent) do
    Decimal.sub(monthly_budget, normalize_decimal(total_spent))
  end

  def alert_level(percent) when is_integer(percent) do
    cond do
      percent > 100 -> :over
      percent >= 80 -> :near
      true -> :ok
    end
  end

  def total_last_days(category_id, days) do
    from(e in Expense,
      where: e.category_id == ^category_id and e.date >= ^Date.add(Date.utc_today(), -days),
      select: sum(e.amount)
    )
    |> Repo.one()
    |> case do
      nil -> Decimal.new(0)
      dec -> dec
    end
  end

  def summary_last_days(days) do
    from(e in Expense,
      where: e.date >= ^Date.add(Date.utc_today(), -days),
      join: c in assoc(e, :category),
      group_by: [c.id, c.name, c.monthly_budget],
      select: %{
        category_id: c.id,
        name: c.name,
        budget: c.monthly_budget,
        spent: sum(e.amount)
      }
    )
    |> Repo.all()
    |> Enum.map(fn m -> %{m | spent: m.spent || Decimal.new(0)} end)
  end

  def top_categories_by_spending(days, limit \\ 5) do
    from(e in Expense,
      where: e.date >= ^Date.add(Date.utc_today(), -days),
      join: c in assoc(e, :category),
      group_by: [c.id, c.name],
      select: %{category_id: c.id, name: c.name, spent: sum(e.amount)},
      order_by: [desc: sum(e.amount)],
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_expenses_for_category(category_id, page \\ 1, page_size \\ 10) do
    page = max(page, 1)

    Expense
    |> where([e], e.category_id == ^category_id)
    |> order_by([e], desc: e.date, desc: e.inserted_at)
    |> limit(^page_size)
    |> offset(^((page - 1) * page_size))
    |> Repo.all()
  end

  def count_expenses_for_category(category_id) do
    from(e in Expense, where: e.category_id == ^category_id, select: count(e.id))
    |> Repo.one()
  end

  def total_pages_for_category(category_id, page_size \\ 10) do
    total = count_expenses_for_category(category_id)
    pages = ceil_div(total, page_size)
    # أقل حاجة صفحة واحدة حتى لو total = 0
    max(pages, 1)
  end

  def with_date_range(query, from_date, to_date) do
    query
    |> then(fn q ->
      if match?(%Date{}, from_date), do: from(e in q, where: e.date >= ^from_date), else: q
    end)
    |> then(fn q ->
      if match?(%Date{}, to_date), do: from(e in q, where: e.date <= ^to_date), else: q
    end)
  end

  def expenses_between(category_id, from_date, to_date) do
    from(e in Expense, where: e.category_id == ^category_id)
    |> with_date_range(from_date, to_date)
    |> order_by([e], desc: e.date, desc: e.inserted_at)
    |> Repo.all()
  end

  defp ceil_div(a, b) when is_integer(a) and is_integer(b) and b > 0 do
    case a do
      0 -> 0
      _ -> div(a + b - 1, b)
    end
  end

  def category_metrics(category_id, %Decimal{} = monthly_budget) do
    spent = total_spent_for_category(category_id)
    percent = spending_percent(monthly_budget, spent) |> Decimal.to_integer()

    %{
      spent: spent,
      percent: percent,
      remaining: remaining_budget(monthly_budget, spent),
      alert: alert_level(percent),
      progress_value: min(percent, 100),
      over_budget?: percent > 100
    }
  end

  def category_metrics(category_id, monthly_budget) do
    category_metrics(category_id, normalize_decimal(monthly_budget))
  end
end
