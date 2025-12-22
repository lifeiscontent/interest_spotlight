defmodule InterestSpotlight.ConnectionsTest do
  use InterestSpotlight.DataCase, async: true

  import InterestSpotlight.AccountsFixtures
  import InterestSpotlight.ConnectionsFixtures

  alias InterestSpotlight.Connections
  alias InterestSpotlight.Connections.Connection

  describe "create_connection_request/2" do
    test "creates a pending connection request between two users" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      assert {:ok, %Connection{} = connection} =
               Connections.create_connection_request(user1.id, user2.id)

      assert connection.requester_id == user1.id
      assert connection.user_id == user2.id
      assert connection.status == "pending"
    end

    test "returns error when user tries to connect with themselves" do
      user = onboarded_user_fixture()

      assert {:error, changeset} = Connections.create_connection_request(user.id, user.id)
      assert "cannot connect with yourself" in errors_on(changeset).user_id
    end

    test "returns error when connection request already exists" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      {:ok, _connection} = Connections.create_connection_request(user1.id, user2.id)

      assert {:error, changeset} = Connections.create_connection_request(user1.id, user2.id)
      assert "has already been taken" in errors_on(changeset).requester_id
    end
  end

  describe "accept_connection_request/1" do
    test "updates connection status to accepted" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert {:ok, %Connection{} = accepted_connection} =
               Connections.accept_connection_request(connection)

      assert accepted_connection.status == "accepted"
      assert accepted_connection.id == connection.id
    end

    test "broadcasts connection_accepted event" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      # Subscribe to both users' connection events
      Connections.subscribe(user1.id)
      Connections.subscribe(user2.id)

      {:ok, accepted_connection} = Connections.accept_connection_request(connection)

      # Both users should receive the event
      assert_receive {:connection_accepted, ^accepted_connection}
      assert_receive {:connection_accepted, ^accepted_connection}
    end
  end

  describe "reject_connection_request/1" do
    test "updates connection status to rejected" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert {:ok, %Connection{} = rejected_connection} =
               Connections.reject_connection_request(connection)

      assert rejected_connection.status == "rejected"
      assert rejected_connection.id == connection.id
    end

    test "broadcasts connection_rejected event" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      Connections.subscribe(user1.id)
      Connections.subscribe(user2.id)

      {:ok, rejected_connection} = Connections.reject_connection_request(connection)

      assert_receive {:connection_rejected, ^rejected_connection}
      assert_receive {:connection_rejected, ^rejected_connection}
    end
  end

  describe "cancel_connection_request/1" do
    test "deletes the connection request" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert {:ok, %Connection{}} = Connections.cancel_connection_request(connection)
      assert is_nil(Connections.get_connection_between(user1.id, user2.id))
    end

    test "broadcasts connection_cancelled event" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      Connections.subscribe(user1.id)
      Connections.subscribe(user2.id)

      {:ok, deleted_connection} = Connections.cancel_connection_request(connection)

      assert_receive {:connection_cancelled, ^deleted_connection}
      assert_receive {:connection_cancelled, ^deleted_connection}
    end
  end

  describe "remove_connection/1" do
    test "deletes an accepted connection" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = accepted_connection_fixture(user1.id, user2.id)

      assert {:ok, %Connection{}} = Connections.remove_connection(connection)
      assert is_nil(Connections.get_connection_between(user1.id, user2.id))
    end

    test "broadcasts connection_removed event" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = accepted_connection_fixture(user1.id, user2.id)

      Connections.subscribe(user1.id)
      Connections.subscribe(user2.id)

      {:ok, deleted_connection} = Connections.remove_connection(connection)

      assert_receive {:connection_removed, ^deleted_connection}
      assert_receive {:connection_removed, ^deleted_connection}
    end
  end

  describe "get_connection!/1" do
    test "returns the connection with given id" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert %Connection{} = fetched_connection = Connections.get_connection!(connection.id)
      assert fetched_connection.id == connection.id
    end

    test "raises Ecto.NoResultsError when connection doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Connections.get_connection!(999_999)
      end
    end
  end

  describe "get_connection_between/2" do
    test "returns connection when user1 is requester" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert %Connection{} = found = Connections.get_connection_between(user1.id, user2.id)
      assert found.id == connection.id
    end

    test "returns connection when user2 is requester (bidirectional)" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      connection = connection_request_fixture(user1.id, user2.id)

      assert %Connection{} = found = Connections.get_connection_between(user2.id, user1.id)
      assert found.id == connection.id
    end

    test "returns nil when no connection exists" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      assert is_nil(Connections.get_connection_between(user1.id, user2.id))
    end
  end

  describe "list_connections/1" do
    test "returns all accepted connections for a user as requester" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      connection1 = accepted_connection_fixture(user1.id, user2.id)
      connection2 = accepted_connection_fixture(user1.id, user3.id)

      connections = Connections.list_connections(user1.id)
      connection_ids = Enum.map(connections, & &1.id)

      assert length(connections) == 2
      assert connection1.id in connection_ids
      assert connection2.id in connection_ids
    end

    test "returns all accepted connections for a user as addressee" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      connection1 = accepted_connection_fixture(user2.id, user1.id)
      connection2 = accepted_connection_fixture(user3.id, user1.id)

      connections = Connections.list_connections(user1.id)
      connection_ids = Enum.map(connections, & &1.id)

      assert length(connections) == 2
      assert connection1.id in connection_ids
      assert connection2.id in connection_ids
    end

    test "does not return pending connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _pending = connection_request_fixture(user1.id, user2.id)

      assert Connections.list_connections(user1.id) == []
    end

    test "does not return rejected connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _rejected = rejected_connection_fixture(user1.id, user2.id)

      assert Connections.list_connections(user1.id) == []
    end

    test "preloads requester and user associations" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      accepted_connection_fixture(user1.id, user2.id)

      [connection] = Connections.list_connections(user1.id)

      assert %InterestSpotlight.Accounts.User{} = connection.requester
      assert %InterestSpotlight.Accounts.User{} = connection.user
    end
  end

  describe "list_received_requests/1" do
    test "returns pending requests received by user" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      request1 = connection_request_fixture(user2.id, user1.id)
      request2 = connection_request_fixture(user3.id, user1.id)

      requests = Connections.list_received_requests(user1.id)
      request_ids = Enum.map(requests, & &1.id)

      assert length(requests) == 2
      assert request1.id in request_ids
      assert request2.id in request_ids
    end

    test "does not return requests sent by user" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _sent_request = connection_request_fixture(user1.id, user2.id)

      assert Connections.list_received_requests(user1.id) == []
    end

    test "does not return accepted connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _accepted = accepted_connection_fixture(user2.id, user1.id)

      assert Connections.list_received_requests(user1.id) == []
    end

    test "orders by inserted_at descending" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      connection_request_fixture(user2.id, user1.id)
      connection_request_fixture(user3.id, user1.id)

      requests = Connections.list_received_requests(user1.id)

      # Should have 2 requests
      assert length(requests) == 2

      # Verify they're ordered by inserted_at desc (most recent first)
      [first, second] = requests
      assert NaiveDateTime.compare(first.inserted_at, second.inserted_at) in [:gt, :eq]
    end
  end

  describe "list_sent_requests/1" do
    test "returns pending requests sent by user" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      request1 = connection_request_fixture(user1.id, user2.id)
      request2 = connection_request_fixture(user1.id, user3.id)

      requests = Connections.list_sent_requests(user1.id)
      request_ids = Enum.map(requests, & &1.id)

      assert length(requests) == 2
      assert request1.id in request_ids
      assert request2.id in request_ids
    end

    test "does not return requests received by user" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _received_request = connection_request_fixture(user2.id, user1.id)

      assert Connections.list_sent_requests(user1.id) == []
    end

    test "does not return accepted connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      _accepted = accepted_connection_fixture(user1.id, user2.id)

      assert Connections.list_sent_requests(user1.id) == []
    end
  end

  describe "count_received_requests/1" do
    test "returns count of pending requests received" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      connection_request_fixture(user2.id, user1.id)
      connection_request_fixture(user3.id, user1.id)

      assert Connections.count_received_requests(user1.id) == 2
    end

    test "returns 0 when user has no received requests" do
      user = onboarded_user_fixture()

      assert Connections.count_received_requests(user.id) == 0
    end

    test "does not count accepted connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      accepted_connection_fixture(user2.id, user1.id)

      assert Connections.count_received_requests(user1.id) == 0
    end
  end

  describe "count_connections/1" do
    test "returns count of accepted connections" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      accepted_connection_fixture(user1.id, user2.id)
      accepted_connection_fixture(user3.id, user1.id)

      assert Connections.count_connections(user1.id) == 2
    end

    test "returns 0 when user has no connections" do
      user = onboarded_user_fixture()

      assert Connections.count_connections(user.id) == 0
    end

    test "does not count pending requests" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection_request_fixture(user1.id, user2.id)

      assert Connections.count_connections(user1.id) == 0
    end
  end

  describe "connected?/2" do
    test "returns true when users are connected" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      accepted_connection_fixture(user1.id, user2.id)

      assert Connections.connected?(user1.id, user2.id)
      assert Connections.connected?(user2.id, user1.id)
    end

    test "returns false when users have pending request" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection_request_fixture(user1.id, user2.id)

      refute Connections.connected?(user1.id, user2.id)
      refute Connections.connected?(user2.id, user1.id)
    end

    test "returns false when users have no connection" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      refute Connections.connected?(user1.id, user2.id)
    end
  end

  describe "connection_status/2" do
    test "returns :connected when users are connected" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      accepted_connection_fixture(user1.id, user2.id)

      assert Connections.connection_status(user1.id, user2.id) == :connected
      assert Connections.connection_status(user2.id, user1.id) == :connected
    end

    test "returns :pending_sent when current user sent request" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection_request_fixture(user1.id, user2.id)

      assert Connections.connection_status(user1.id, user2.id) == :pending_sent
    end

    test "returns :pending_received when current user received request" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection_request_fixture(user1.id, user2.id)

      assert Connections.connection_status(user2.id, user1.id) == :pending_received
    end

    test "returns nil when no connection exists" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      assert is_nil(Connections.connection_status(user1.id, user2.id))
    end

    test "returns nil when connection was rejected" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      rejected_connection_fixture(user1.id, user2.id)

      assert is_nil(Connections.connection_status(user1.id, user2.id))
    end
  end

  describe "get_other_user/2" do
    test "returns user when current user is requester" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection = accepted_connection_fixture(user1.id, user2.id)
      connection = Repo.preload(connection, [:requester, :user])

      other_user = Connections.get_other_user(connection, user1.id)

      assert other_user.id == user2.id
    end

    test "returns requester when current user is addressee" do
      user1 = onboarded_user_fixture()
      user2 = onboarded_user_fixture()

      connection = accepted_connection_fixture(user1.id, user2.id)
      connection = Repo.preload(connection, [:requester, :user])

      other_user = Connections.get_other_user(connection, user2.id)

      assert other_user.id == user1.id
    end
  end
end
