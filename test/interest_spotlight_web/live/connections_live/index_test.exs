defmodule InterestSpotlightWeb.ConnectionsLive.IndexTest do
  use InterestSpotlightWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InterestSpotlight.AccountsFixtures
  import InterestSpotlight.ConnectionsFixtures

  alias InterestSpotlight.Connections

  describe "ConnectionsLive.Index" do
    setup :register_and_log_in_onboarded_user

    test "renders connections page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/connections")

      assert html =~ "Connections"
      assert html =~ "All Users"
      assert html =~ "Connection Requests"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/connections")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays connection count", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections")

      assert html =~ "Connections"
      assert html =~ "1"
    end
  end

  describe "All Users tab" do
    setup :register_and_log_in_onboarded_user

    test "displays all users except current user", %{conn: conn} do
      user2 = onboarded_user_fixture()
      user3 = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ user2.first_name
      assert result =~ user2.last_name
      assert result =~ user3.first_name
      assert result =~ user3.last_name
    end

    test "shows connect button for users not connected", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ "Connect"
      assert result =~ "phx-click=\"send_request\""
      assert result =~ "phx-value-user_id=\"#{other_user.id}\""
    end

    test "shows 'Request Sent' for pending sent requests", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ "Request Sent"
    end

    test "shows 'View Request' for pending received requests", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ "View Request"
    end

    test "shows clickable profile links for connected users", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ "/connections/#{other_user.id}"
      assert result =~ other_user.first_name
    end

    test "sends connection request when connect button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
      |> render_click()

      lv
      |> element("button[phx-click='send_request'][phx-value-user_id='#{other_user.id}']")
      |> render_click()

      # Verify connection was created
      assert Connections.connection_status(user.id, other_user.id) == :pending_sent
    end

    test "shows flash message after sending request", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
      |> render_click()

      result =
        lv
        |> element("button[phx-click='send_request'][phx-value-user_id='#{other_user.id}']")
        |> render_click()

      assert result =~ "Connection request sent"
    end
  end

  describe "Connection Requests tab" do
    setup :register_and_log_in_onboarded_user

    test "switches to requests tab when clicked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/connections")

      # Initially on my_connections tab
      assert html =~ "Connections"

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
        |> render_click()

      # After switching, should see requests tab content
      assert result =~ "Connection Requests"
    end

    test "displays received connection requests", %{conn: conn, user: user} do
      requester = onboarded_user_fixture()
      connection_request_fixture(requester.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
        |> render_click()

      assert result =~ requester.first_name
      assert result =~ requester.last_name
      assert result =~ "Accept"
      assert result =~ "Deny"
    end

    test "displays sent connection requests", %{conn: conn, user: user} do
      addressee = onboarded_user_fixture()
      connection_request_fixture(user.id, addressee.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
        |> render_click()

      assert result =~ "Sent Requests"
      assert result =~ addressee.first_name
      assert result =~ addressee.last_name
      assert result =~ "Cancel"
    end

    test "shows badge with count of received requests", %{conn: conn, user: user} do
      requester1 = onboarded_user_fixture()
      requester2 = onboarded_user_fixture()
      connection_request_fixture(requester1.id, user.id)
      connection_request_fixture(requester2.id, user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections")

      assert html =~ "2"
      assert html =~ "badge"
    end

    test "accepts connection request when accept button clicked", %{conn: conn, user: user} do
      requester = onboarded_user_fixture()
      connection = connection_request_fixture(requester.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
      |> render_click()

      lv
      |> element("button[phx-click='accept_request'][phx-value-id='#{connection.id}']")
      |> render_click()

      # Verify connection was accepted
      assert Connections.connection_status(user.id, requester.id) == :connected
    end

    test "shows flash message after accepting request", %{conn: conn, user: user} do
      requester = onboarded_user_fixture()
      connection = connection_request_fixture(requester.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
      |> render_click()

      result =
        lv
        |> element("button[phx-click='accept_request'][phx-value-id='#{connection.id}']")
        |> render_click()

      assert result =~ "Connection accepted"
    end

    test "rejects connection request when deny button clicked", %{conn: conn, user: user} do
      requester = onboarded_user_fixture()
      connection = connection_request_fixture(requester.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
      |> render_click()

      lv
      |> element("button[phx-click='reject_request'][phx-value-id='#{connection.id}']")
      |> render_click()

      # Verify connection was rejected
      assert is_nil(Connections.connection_status(user.id, requester.id))
    end

    test "cancels sent request when cancel button clicked", %{conn: conn, user: user} do
      addressee = onboarded_user_fixture()
      connection = connection_request_fixture(user.id, addressee.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
      |> render_click()

      lv
      |> element("button[phx-click='cancel_request'][phx-value-id='#{connection.id}']")
      |> render_click()

      # Verify connection was cancelled
      assert is_nil(Connections.connection_status(user.id, addressee.id))
    end

    test "shows empty state when no received requests", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/connections")

      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
        |> render_click()

      assert result =~ "No connection requests"
    end

    test "decrements badge count after accepting request", %{conn: conn, user: user} do
      requester = onboarded_user_fixture()
      connection = connection_request_fixture(requester.id, user.id)

      {:ok, lv, html} = live(conn, ~p"/connections")

      # Should show badge with count 1
      assert html =~ "1"

      lv
      |> element("a[phx-click='switch_tab'][phx-value-tab='requests']")
      |> render_click()

      result =
        lv
        |> element("button[phx-click='accept_request'][phx-value-id='#{connection.id}']")
        |> render_click()

      # Badge should be gone (count is 0)
      refute result =~ "badge-primary"
    end
  end

  describe "My Connections tab" do
    setup :register_and_log_in_onboarded_user

    test "displays my connections tab by default", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/connections")

      # Should be on my_connections tab by default
      assert html =~ "Connections"
    end

    test "displays all accepted connections", %{conn: conn, user: user} do
      friend1 = onboarded_user_fixture()
      friend2 = onboarded_user_fixture()

      accepted_connection_fixture(user.id, friend1.id)
      accepted_connection_fixture(friend2.id, user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections")

      # My connections tab is default, so no need to switch
      assert html =~ friend1.first_name
      assert html =~ friend1.last_name
      assert html =~ friend2.first_name
      assert html =~ friend2.last_name
    end

    test "shows remove button for each connection", %{conn: conn, user: user} do
      friend = onboarded_user_fixture()
      accepted_connection_fixture(user.id, friend.id)

      {:ok, _lv, html} = live(conn, ~p"/connections")

      # My connections tab is default
      assert html =~ "phx-click=\"remove_connection\""
      assert html =~ "hero-x-mark"
    end

    test "shows clickable profile links for each connection", %{conn: conn, user: user} do
      friend = onboarded_user_fixture()
      accepted_connection_fixture(user.id, friend.id)

      {:ok, _lv, html} = live(conn, ~p"/connections")

      # My connections tab is default
      assert html =~ "/connections/#{friend.id}"
      assert html =~ friend.first_name
      assert html =~ "hover:underline"
    end

    test "removes connection when remove button clicked", %{conn: conn, user: user} do
      friend = onboarded_user_fixture()
      connection = accepted_connection_fixture(user.id, friend.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # My connections tab is default, no need to switch
      lv
      |> element("button[phx-click='remove_connection'][phx-value-id='#{connection.id}']")
      |> render_click()

      # Verify connection was removed
      assert is_nil(Connections.connection_status(user.id, friend.id))
    end

    test "shows flash message after removing connection", %{conn: conn, user: user} do
      friend = onboarded_user_fixture()
      connection = accepted_connection_fixture(user.id, friend.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # My connections tab is default, no need to switch
      result =
        lv
        |> element("button[phx-click='remove_connection'][phx-value-id='#{connection.id}']")
        |> render_click()

      assert result =~ "Connection removed"
    end

    test "shows empty state when no connections", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/connections")

      # My connections tab is default
      assert html =~ "No connections yet"
      assert html =~ "Find People to Connect"
    end

    test "empty state has button to switch to all users tab", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/connections")

      # My connections tab is default, just click the button to switch
      result =
        lv
        |> element("button[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      assert result =~ "All Users"
    end
  end

  describe "Real-time updates via PubSub" do
    setup :register_and_log_in_onboarded_user

    test "updates UI when connection request is received", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # Simulate another user sending a connection request
      {:ok, _connection} = Connections.create_connection_request(other_user.id, user.id)

      # Wait for PubSub message to be processed
      :timer.sleep(100)

      # Badge count should update
      html = render(lv)
      assert html =~ "1"
    end

    test "updates UI when connection request is accepted by other user", %{
      conn: conn,
      user: user
    } do
      other_user = onboarded_user_fixture()
      connection = connection_request_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # Simulate the other user accepting the request
      {:ok, _accepted} = Connections.accept_connection_request(connection)

      # Wait for PubSub message
      :timer.sleep(100)

      # Connection should now show in My Connections (which is the default tab)
      html = render(lv)
      assert html =~ other_user.first_name
    end

    test "updates UI when connection is removed by other user", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection = accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # Simulate the other user removing the connection
      {:ok, _removed} = Connections.remove_connection(connection)

      # Wait for PubSub message
      :timer.sleep(100)

      # Connection should no longer appear (My Connections is the default tab)
      html = render(lv)
      refute html =~ other_user.first_name
    end
  end

  describe "User initials display" do
    setup :register_and_log_in_onboarded_user

    test "shows first and last name initials when both present", %{conn: conn} do
      _other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections")

      # Switch to all users tab to see other users
      result =
        lv
        |> element("a[phx-click='switch_tab'][phx-value-tab='all_users']")
        |> render_click()

      # Should show "TU" for "Test User"
      assert result =~ "TU"
    end
  end
end
