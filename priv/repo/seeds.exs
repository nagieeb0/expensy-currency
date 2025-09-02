alias Expensy.Repo
alias Expensy.Wallet.{Category, Expense}

import Ecto.Query
require Logger

expenses_per_category = String.to_integer(System.get_env("EXP_PER_CAT") || "60")
wipe = System.get_env("WIPE") in [nil, "", "1", "true"]

seed_val = String.to_integer(System.get_env("SEED") || "20250827")
:rand.seed(:exsplus, {seed_val, seed_val * 2, seed_val * 3})

today = Date.utc_today()
now = DateTime.utc_now() |> DateTime.truncate(:second)

currencies = ~w(USD EUR GBP)

to_dec = fn
  %Decimal{} = d -> d
  n when is_integer(n) -> Decimal.new(n)
  n when is_float(n) -> Decimal.from_float(n)
  b when is_binary(b) -> Decimal.new(b)
end

rand = fn min, max ->
  :rand.uniform(max - min + 1) + min - 1
end

rand_choice = fn list ->
  Enum.at(list, rand.(0, length(list) - 1))
end

if Mix.env() in [:dev, :test] and wipe do
  Logger.info("🧹 Clearing expenses & categories…")
  Repo.delete_all(Expense)
  Repo.delete_all(Category)
end

category_specs = [
  {"Food", "Restaurants, groceries, coffee", "500"},
  {"Transport", "Commute, fuel, metro", "250"},
  {"Rent", "Monthly apartment rent", "900"},
  {"Utilities", "Electricity, water, gas, internet", "300"},
  {"Entertainment", "Cinema, subscriptions, events", "180"},
  {"Shopping", "Clothes & accessories", "350"},
  {"Healthcare", "Medicines & clinic visits", "220"},
  {"Education", "Courses & books", "200"},
  {"Gadgets", "Phones, laptops, accessories", "400"},
  {"Travel", "Flights & hotels", "1200"},
  {"Gifts", "Gifts for family & friends", "150"},
  {"Kids", "Toys, school stuff", "180"},
  {"Pets", "Food & vet", "120"},
  {"Fitness", "Gym & sports", "100"},
  {"Beauty", "Salon & skincare", "120"},
  {"Home", "Furniture & tools", "450"},
  {"Car", "Maintenance & parts", "300"},
  {"Subscriptions", "SaaS & apps", "70"},
  {"Charity", "Donations", "100"},
  {"Misc", "Everything else", "200"}
]

expense_samples = %{
  "Food" => [{"Burger", 12}, {"Pizza", 18}, {"Groceries", 45}, {"Coffee", 4}, {"Sushi", 30}],
  "Transport" => [{"Taxi", 10}, {"Fuel", 35}, {"Metro", 2}, {"Parking", 5}],
  "Rent" => [{"Rent Payment", 900}, {"Maintenance Fee", 50}],
  "Utilities" => [{"Electricity", 60}, {"Water", 30}, {"Gas", 25}, {"Internet", 20}],
  "Entertainment" => [{"Cinema", 8}, {"Netflix", 10}, {"Games", 20}, {"Concert", 40}],
  "Shopping" => [{"T-Shirt", 15}, {"Shoes", 60}, {"Accessories", 12}, {"Jeans", 45}],
  "Healthcare" => [{"Pharmacy", 20}, {"Clinic", 60}, {"Vitamins", 18}],
  "Education" => [{"Book", 12}, {"Course", 70}, {"Stationery", 8}],
  "Gadgets" => [{"Phone Case", 15}, {"Charger", 20}, {"Headphones", 80}],
  "Travel" => [{"Flight", 700}, {"Hotel", 300}, {"Train", 50}, {"Tour", 60}],
  "Gifts" => [{"Birthday Gift", 40}, {"Flowers", 15}, {"Chocolate", 10}],
  "Kids" => [{"Toys", 20}, {"School Bag", 25}, {"Snacks", 5}],
  "Pets" => [{"Pet Food", 18}, {"Vet Visit", 50}, {"Litter", 10}],
  "Fitness" => [{"Gym", 25}, {"Sportswear", 30}, {"Protein", 35}],
  "Beauty" => [{"Salon", 25}, {"Skincare", 20}, {"Perfume", 60}],
  "Home" => [{"Chair", 50}, {"Lamp", 20}, {"Tools", 15}, {"Bedding", 40}],
  "Car" => [{"Oil Change", 30}, {"Car Wash", 7}, {"Tire Repair", 25}],
  "Subscriptions" => [{"Cloud App", 10}, {"Music", 6}, {"Storage", 3}],
  "Charity" => [{"Donation", 20}],
  "Misc" => [{"Misc Item", 10}, {"Postage", 5}, {"Stationery", 4}]
}

Logger.info("🌱 Seeding #{length(category_specs)} categories…")

cats_rows =
  category_specs
  |> Enum.map(fn {name, desc, budget} ->
    %{
      name: name,
      description: desc,
      monthly_budget: to_dec.(budget),
      inserted_at: now,
      updated_at: now
    }
  end)

{_, nil} = Repo.insert_all(Category, cats_rows, returning: false)

categories =
  from(c in Category, order_by: c.inserted_at)
  |> Repo.all()

Logger.info("🧾 Generating expenses (~#{length(categories) * expenses_per_category})…")

batch_size = 1_000

all_rows_stream =
  Stream.flat_map(categories, fn cat ->
    samples = Map.get(expense_samples, cat.name, expense_samples["Misc"])

    Stream.repeatedly(fn ->
      {label, base} = rand_choice.(samples)
      amount = base + rand.(0, max(1, div(base, 2)))
      currency = rand_choice.(currencies)
      date = Date.add(today, -rand.(0, 120))

      %{
        name: label,
        description: "#{label} expense",
        amount: Decimal.new(amount),
        date: date,
        currency: currency,
        category_id: cat.id,
        inserted_at: now,
        updated_at: now
      }
    end)
    |> Enum.take(expenses_per_category)
  end)

rows = Enum.to_list(all_rows_stream)
Logger.info("💾 Inserting expenses in batches of #{batch_size}…")

rows
|> Stream.chunk_every(batch_size)
|> Enum.with_index(1)
|> Enum.each(fn {chunk, i} ->
  Repo.insert_all(Expense, chunk, returning: false)
  Logger.info("  ▸ batch #{i} inserted (#{length(chunk)} rows)")
end)

total_expenses = Repo.aggregate(Expense, :count, :id)
total_categories = Repo.aggregate(Category, :count, :id)

Logger.info("""
✅ Seeding done!
  Categories: #{total_categories}
  Expenses:   #{total_expenses}
  Per-Category target: #{expenses_per_category}
""")
