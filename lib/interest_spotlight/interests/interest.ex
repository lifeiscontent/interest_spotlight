defmodule InterestSpotlight.Interests.Interest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "interests" do
    field :name, :string

    many_to_many :users, InterestSpotlight.Accounts.User, join_through: "user_interests"

    timestamps(type: :utc_datetime)
  end

  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:name)
  end
end
