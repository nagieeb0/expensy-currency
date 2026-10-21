defmodule Expensy.Repo do
  use Ecto.Repo,
    otp_app: :expensy,
    adapter: Ecto.Adapters.Postgres
end
