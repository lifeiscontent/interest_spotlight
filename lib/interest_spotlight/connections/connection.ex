defmodule InterestSpotlight.Connections.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending accepted rejected)

  schema "connections" do
    field :status, :string, default: "pending"

    belongs_to :requester, InterestSpotlight.Accounts.User
    belongs_to :user, InterestSpotlight.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:requester_id, :user_id, :status])
    |> validate_required([:requester_id, :user_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_different_users()
    |> unique_constraint([:requester_id, :user_id])
  end

  defp validate_different_users(changeset) do
    requester_id = get_field(changeset, :requester_id)
    user_id = get_field(changeset, :user_id)

    if requester_id && user_id && requester_id == user_id do
      add_error(changeset, :user_id, "cannot connect with yourself")
    else
      changeset
    end
  end
end
