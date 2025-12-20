defmodule InterestSpotlight.Interests.UserInterest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_interests" do
    belongs_to :user, InterestSpotlight.Accounts.User
    belongs_to :interest, InterestSpotlight.Interests.Interest

    timestamps(type: :utc_datetime)
  end

  def changeset(user_interest, attrs) do
    user_interest
    |> cast(attrs, [:user_id, :interest_id])
    |> validate_required([:user_id, :interest_id])
    |> unique_constraint([:user_id, :interest_id])
  end
end
