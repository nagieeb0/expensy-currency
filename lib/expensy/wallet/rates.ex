defmodule Expensy.Wallet.Rates do
  @moduledoc false
  @base "USD"
  @rates %{
    "USD" => Decimal.new("1"),
    "EUR" => Decimal.new("0.92"),
    "GBP" => Decimal.new("0.78"),
    "EGP" => Decimal.new("49.0")
  }

  def base, do: @base
  def rate_for(cur), do: Map.get(@rates, cur, Decimal.new("1"))

  def convert(amount, from, to) when from == to, do: Decimal.new(amount)
  def convert(amount, from, to) do
    amt = to_decimal(amount)
    from_rate = rate_for(from)
    to_rate   = rate_for(to)

    amt
    |> Decimal.div(from_rate)
    |> Decimal.mult(to_rate)
  end

  defp to_decimal(%Decimal{}=d), do: d
  defp to_decimal(n) when is_integer(n), do: Decimal.new(n)
  defp to_decimal(n) when is_float(n), do: Decimal.from_float(n)
  defp to_decimal(b) when is_binary(b), do: Decimal.new(b)
end
