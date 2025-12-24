defmodule InterestSpotlight.Connections.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending accepted rejected)

  schema "connections" do
    field :status, :string, default: "pending"

    belongs_to :requester, InterestSpotlight.Accounts.User
    belongs_to :receiver, InterestSpotlight.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:requester_id, :receiver_id, :status])
    |> validate_required([:requester_id, :receiver_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_different_users()
    |> unique_constraint([:requester_id, :receiver_id])
  end

  defp validate_different_users(changeset) do
    requester_id = get_field(changeset, :requester_id)
    receiver_id = get_field(changeset, :receiver_id)

    if requester_id && receiver_id && requester_id == receiver_id do
      add_error(changeset, :receiver_id, "cannot connect with yourself")
    else
      changeset
    end
  end
end
