defmodule InterestSpotlight.Connections do
  @moduledoc """
  The Connections context - manages user connection requests.
  """

  import Ecto.Query, warn: false
  alias InterestSpotlight.Repo
  alias InterestSpotlight.Connections.Connection

  @doc """
  Creates a connection request from requester to user.
  """
  def create_connection_request(requester_id, user_id) do
    %Connection{}
    |> Connection.changeset(%{
      requester_id: requester_id,
      user_id: user_id,
      status: "pending"
    })
    |> Repo.insert()
  end

  @doc """
  Accepts a connection request.
  """
  def accept_connection_request(%Connection{} = connection) do
    connection
    |> Connection.changeset(%{status: "accepted"})
    |> Repo.update()
  end

  @doc """
  Rejects a connection request.
  """
  def reject_connection_request(%Connection{} = connection) do
    connection
    |> Connection.changeset(%{status: "rejected"})
    |> Repo.update()
  end

  @doc """
  Cancels a connection request (by the requester).
  """
  def cancel_connection_request(%Connection{} = connection) do
    Repo.delete(connection)
  end

  @doc """
  Removes a connection (unfriend).
  """
  def remove_connection(%Connection{} = connection) do
    Repo.delete(connection)
  end

  @doc """
  Gets a connection by ID.
  """
  def get_connection!(id) do
    Repo.get!(Connection, id)
  end

  @doc """
  Gets a connection between two users (either direction).
  """
  def get_connection_between(user_id_1, user_id_2) do
    from(c in Connection,
      where:
        (c.requester_id == ^user_id_1 and c.user_id == ^user_id_2) or
          (c.requester_id == ^user_id_2 and c.user_id == ^user_id_1)
    )
    |> Repo.one()
  end

  @doc """
  Lists all accepted connections for a user.
  """
  def list_connections(user_id) do
    from(c in Connection,
      where: c.status == "accepted",
      where: c.requester_id == ^user_id or c.user_id == ^user_id,
      preload: [:requester, :user]
    )
    |> Repo.all()
  end

  @doc """
  Lists pending connection requests received by a user.
  """
  def list_received_requests(user_id) do
    from(c in Connection,
      where: c.status == "pending",
      where: c.user_id == ^user_id,
      preload: [requester: [:profile]],
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists pending connection requests sent by a user.
  """
  def list_sent_requests(user_id) do
    from(c in Connection,
      where: c.status == "pending",
      where: c.requester_id == ^user_id,
      preload: [user: [:profile]],
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Counts the number of pending requests received by a user.
  """
  def count_received_requests(user_id) do
    from(c in Connection,
      where: c.status == "pending",
      where: c.user_id == ^user_id,
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Counts the total number of connections for a user.
  """
  def count_connections(user_id) do
    from(c in Connection,
      where: c.status == "accepted",
      where: c.requester_id == ^user_id or c.user_id == ^user_id,
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Checks if two users are connected.
  """
  def connected?(user_id_1, user_id_2) do
    from(c in Connection,
      where: c.status == "accepted",
      where:
        (c.requester_id == ^user_id_1 and c.user_id == ^user_id_2) or
          (c.requester_id == ^user_id_2 and c.user_id == ^user_id_1)
    )
    |> Repo.exists?()
  end

  @doc """
  Checks the connection status between two users.
  Returns: nil | :connected | :pending_sent | :pending_received
  """
  def connection_status(current_user_id, other_user_id) do
    connection = get_connection_between(current_user_id, other_user_id)

    case connection do
      nil ->
        nil

      %Connection{status: "accepted"} ->
        :connected

      %Connection{status: "pending", requester_id: ^current_user_id} ->
        :pending_sent

      %Connection{status: "pending", user_id: ^current_user_id} ->
        :pending_received

      _ ->
        nil
    end
  end

  @doc """
  Gets the other user in a connection.
  """
  def get_other_user(%Connection{} = connection, current_user_id) do
    if connection.requester_id == current_user_id do
      connection.user
    else
      connection.requester
    end
  end
end
