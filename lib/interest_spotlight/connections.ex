defmodule InterestSpotlight.Connections do
  @moduledoc """
  The Connections context - manages user connection requests.
  """

  import Ecto.Query, warn: false
  alias InterestSpotlight.Repo
  alias InterestSpotlight.Connections.Connection

  @doc """
  Creates a connection request from requester to receiver.
  """
  def create_connection_request(requester_id, receiver_id) do
    result =
      %Connection{}
      |> Connection.changeset(%{
        requester_id: requester_id,
        receiver_id: receiver_id,
        status: "pending"
      })
      |> Repo.insert()

    case result do
      {:ok, connection} ->
        broadcast_connection_event(connection, :connection_request_sent)
        {:ok, connection}

      error ->
        error
    end
  end

  @doc """
  Accepts a connection request.
  """
  def accept_connection_request(%Connection{} = connection) do
    result =
      connection
      |> Connection.changeset(%{status: "accepted"})
      |> Repo.update()

    case result do
      {:ok, updated_connection} ->
        broadcast_connection_event(updated_connection, :connection_accepted)
        {:ok, updated_connection}

      error ->
        error
    end
  end

  @doc """
  Rejects a connection request.
  """
  def reject_connection_request(%Connection{} = connection) do
    result =
      connection
      |> Connection.changeset(%{status: "rejected"})
      |> Repo.update()

    case result do
      {:ok, updated_connection} ->
        broadcast_connection_event(updated_connection, :connection_rejected)
        {:ok, updated_connection}

      error ->
        error
    end
  end

  @doc """
  Cancels a connection request (by the requester).
  """
  def cancel_connection_request(%Connection{} = connection) do
    result = Repo.delete(connection)

    case result do
      {:ok, deleted_connection} ->
        broadcast_connection_event(deleted_connection, :connection_cancelled)
        {:ok, deleted_connection}

      error ->
        error
    end
  end

  @doc """
  Removes a connection (unfriend).
  """
  def remove_connection(%Connection{} = connection) do
    result = Repo.delete(connection)

    case result do
      {:ok, deleted_connection} ->
        broadcast_connection_event(deleted_connection, :connection_removed)
        {:ok, deleted_connection}

      error ->
        error
    end
  end

  @doc """
  Gets a connection by ID.
  """
  def get_connection!(id) do
    Connection
    |> Repo.get!(id)
    |> Repo.preload([:requester, :receiver])
  end

  @doc """
  Gets a connection between two users (either direction).
  """
  def get_connection_between(requester_id, receiver_id) do
    from(c in Connection,
      where:
        (c.requester_id == ^requester_id and c.receiver_id == ^receiver_id) or
          (c.requester_id == ^receiver_id and c.receiver_id == ^requester_id)
    )
    |> Repo.one()
  end

  @doc """
  Lists all accepted connections for a user.
  """
  def list_connections(user_id) do
    from(c in Connection,
      where: c.status == "accepted",
      where: c.requester_id == ^user_id or c.receiver_id == ^user_id,
      preload: [:requester, :receiver]
    )
    |> Repo.all()
  end

  @doc """
  Lists pending connection requests received by a user.
  """
  def list_received_requests(user_id) do
    from(c in Connection,
      where: c.status == "pending",
      where: c.receiver_id == ^user_id,
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
      preload: [receiver: [:profile]],
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists connection request history (accepted and rejected) for a user.
  """
  def list_request_history(user_id) do
    from(c in Connection,
      where: c.status in ["accepted", "rejected"],
      where: c.receiver_id == ^user_id,
      preload: [requester: [:profile]],
      order_by: [desc: c.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Counts the number of pending requests received by a user.
  """
  def count_received_requests(user_id) do
    from(c in Connection,
      where: c.status == "pending",
      where: c.receiver_id == ^user_id,
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
      where: c.requester_id == ^user_id or c.receiver_id == ^user_id,
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
        (c.requester_id == ^user_id_1 and c.receiver_id == ^user_id_2) or
          (c.requester_id == ^user_id_2 and c.receiver_id == ^user_id_1)
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

      %Connection{status: "pending", receiver_id: ^current_user_id} ->
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
      connection.receiver
    else
      connection.requester
    end
  end

  @doc """
  Subscribes to connection events for a user.
  """
  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(InterestSpotlight.PubSub, "connections:#{user_id}")
  end

  defp broadcast_connection_event(%Connection{} = connection, event) do
    # Broadcast to both requester and receiver
    Phoenix.PubSub.broadcast(
      InterestSpotlight.PubSub,
      "connections:#{connection.requester_id}",
      {event, connection}
    )

    Phoenix.PubSub.broadcast(
      InterestSpotlight.PubSub,
      "connections:#{connection.receiver_id}",
      {event, connection}
    )
  end
end
