defmodule InterestSpotlight.Interests.Interest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "interests" do
    field :name, :string
    field :slug, :string

    many_to_many :users, InterestSpotlight.Accounts.User, join_through: "user_interests"

    timestamps(type: :utc_datetime)
  end

  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> generate_slug()
    |> validate_required([:slug])
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase with hyphens only"
    )
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil -> changeset
          name -> put_change(changeset, :slug, slugify(name))
        end

      _slug ->
        changeset
    end
  end

  defp slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
