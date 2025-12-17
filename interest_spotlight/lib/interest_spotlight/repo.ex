defmodule InterestSpotlight.Repo do
  use Ecto.Repo,
    otp_app: :interest_spotlight,
    adapter: Ecto.Adapters.Postgres
end
