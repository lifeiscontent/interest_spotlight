defmodule InterestSpotlight.Profiles.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :bio, :string
    field :instagram, :string
    field :facebook, :string
    field :twitter, :string
    field :tiktok, :string
    field :youtube, :string

    belongs_to :user, InterestSpotlight.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :instagram, :facebook, :twitter, :tiktok, :youtube])
    |> validate_length(:bio, max: 500)
    |> validate_length(:instagram, max: 100)
    |> validate_length(:facebook, max: 100)
    |> validate_length(:twitter, max: 100)
    |> validate_length(:tiktok, max: 100)
    |> validate_length(:youtube, max: 100)
  end
end
