defmodule InterestSpotlight.ConnectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `InterestSpotlight.Connections` context.
  """

  alias InterestSpotlight.Connections

  @doc """
  Creates a pending connection request between two users.
  """
  def connection_request_fixture(requester_id, receiver_id) do
    {:ok, connection} = Connections.create_connection_request(requester_id, receiver_id)
    connection
  end

  @doc """
  Creates an accepted connection between two users.
  """
  def accepted_connection_fixture(requester_id, receiver_id) do
    connection = connection_request_fixture(requester_id, receiver_id)
    {:ok, accepted_connection} = Connections.accept_connection_request(connection)
    accepted_connection
  end

  @doc """
  Creates a rejected connection between two users.
  """
  def rejected_connection_fixture(requester_id, receiver_id) do
    connection = connection_request_fixture(requester_id, receiver_id)
    {:ok, rejected_connection} = Connections.reject_connection_request(connection)
    rejected_connection
  end
end
