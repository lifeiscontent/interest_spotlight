defmodule InterestSpotlightWeb.ConnectionsLive.ShowTest do
  use InterestSpotlightWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InterestSpotlight.AccountsFixtures
  import InterestSpotlight.ConnectionsFixtures

  alias InterestSpotlight.Accounts
  alias InterestSpotlight.Accounts.Scope
  alias InterestSpotlight.Connections
  alias InterestSpotlight.Profiles

  describe "ConnectionsLive.Show" do
    setup :register_and_log_in_onboarded_user

    test "renders user profile page", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ other_user.first_name
      assert html =~ other_user.last_name
      assert html =~ other_user.location
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      other_user = onboarded_user_fixture()

      assert {:error, redirect} = live(conn, ~p"/connections/#{other_user.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects to /profile when trying to view own profile", %{conn: conn, user: user} do
      assert {:error, {:live_redirect, %{to: "/profile"}}} =
               live(conn, ~p"/connections/#{user.id}")
    end
  end

  describe "Connection action buttons" do
    setup :register_and_log_in_onboarded_user

    test "shows Connect button when not connected", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "Connect"
      assert html =~ "phx-click=\"send_connection_request\""
    end

    test "shows Cancel Request button when request is pending sent", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "Cancel Request"
      assert html =~ "phx-click=\"cancel_connection_request\""
    end

    test "shows Accept and Reject buttons when request is pending received", %{
      conn: conn,
      user: user
    } do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "Accept Request"
      assert html =~ "Reject"
      assert html =~ "phx-click=\"accept_connection_request\""
      assert html =~ "phx-click=\"reject_connection_request\""
    end

    test "shows Remove Connection button when connected", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "Remove Connection"
      assert html =~ "phx-click=\"remove_connection\""
    end
  end

  describe "Sending connection requests" do
    setup :register_and_log_in_onboarded_user

    test "sends connection request when Connect button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      lv
      |> element("button[phx-click='send_connection_request']")
      |> render_click()

      # Verify connection was created
      assert Connections.connection_status(user.id, other_user.id) == :pending_sent
    end

    test "shows flash message after sending request", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='send_connection_request']")
        |> render_click()

      assert result =~ "Connection request sent"
    end

    test "updates button to Cancel Request after sending", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='send_connection_request']")
        |> render_click()

      assert result =~ "Cancel Request"
      refute result =~ "phx-click=\"send_connection_request\""
    end
  end

  describe "Cancelling connection requests" do
    setup :register_and_log_in_onboarded_user

    test "cancels request when Cancel Request button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      lv
      |> element("button[phx-click='cancel_connection_request']")
      |> render_click()

      # Verify connection was cancelled
      assert is_nil(Connections.connection_status(user.id, other_user.id))
    end

    test "shows flash message after cancelling", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='cancel_connection_request']")
        |> render_click()

      assert result =~ "Connection request cancelled"
    end

    test "updates button back to Connect after cancelling", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='cancel_connection_request']")
        |> render_click()

      assert result =~ "Connect"
      assert result =~ "phx-click=\"send_connection_request\""
    end
  end

  describe "Accepting connection requests" do
    setup :register_and_log_in_onboarded_user

    test "accepts request when Accept Request button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      lv
      |> element("button[phx-click='accept_connection_request']")
      |> render_click()

      # Verify connection was accepted
      assert Connections.connection_status(user.id, other_user.id) == :connected
    end

    test "shows flash message after accepting", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='accept_connection_request']")
        |> render_click()

      assert result =~ "Connection accepted"
    end

    test "updates button to Remove Connection after accepting", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='accept_connection_request']")
        |> render_click()

      assert result =~ "Remove Connection"
      refute result =~ "Accept Request"
    end

    test "shows full profile after accepting connection from private user", %{
      conn: conn,
      user: user
    } do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show hidden content message before accepting (private profile)
      assert html =~ "This profile is private"

      result =
        lv
        |> element("button[phx-click='accept_connection_request']")
        |> render_click()

      # Should show profile sections after accepting
      refute result =~ "This profile is private"
    end
  end

  describe "Rejecting connection requests" do
    setup :register_and_log_in_onboarded_user

    test "rejects request when Reject button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      lv
      |> element("button[phx-click='reject_connection_request']")
      |> render_click()

      # Verify connection was rejected
      assert is_nil(Connections.connection_status(user.id, other_user.id))
    end

    test "shows flash message after rejecting", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='reject_connection_request']")
        |> render_click()

      assert result =~ "Connection rejected"
    end

    test "updates button back to Connect after rejecting", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection_request_fixture(other_user.id, user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='reject_connection_request']")
        |> render_click()

      assert result =~ "Connect"
      assert result =~ "phx-click=\"send_connection_request\""
    end
  end

  describe "Removing connections" do
    setup :register_and_log_in_onboarded_user

    test "removes connection when Remove Connection button clicked", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      lv
      |> element("button[phx-click='remove_connection']")
      |> render_click()

      # Verify connection was removed
      assert is_nil(Connections.connection_status(user.id, other_user.id))
    end

    test "shows flash message after removing", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='remove_connection']")
        |> render_click()

      assert result =~ "Connection removed"
    end

    test "updates button back to Connect after removing", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, _html} = live(conn, ~p"/connections/#{other_user.id}")

      result =
        lv
        |> element("button[phx-click='remove_connection']")
        |> render_click()

      assert result =~ "Connect"
      assert result =~ "phx-click=\"send_connection_request\""
    end

    test "hides profile content after removing connection from private user", %{
      conn: conn,
      user: user
    } do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show profile before removing (connected)
      refute html =~ "This profile is private"

      result =
        lv
        |> element("button[phx-click='remove_connection']")
        |> render_click()

      # Should show hidden message after removing (private profile, not connected)
      assert result =~ "This profile is private"
    end
  end

  describe "Profile privacy" do
    setup :register_and_log_in_onboarded_user

    test "hides interests when not connected and profile is private", %{conn: conn} do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "This profile is private"
      refute html =~ "Interests"
    end

    test "shows interests when not connected but profile is public", %{conn: conn} do
      other_user = onboarded_user_fixture()
      # Profile is public by default

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      refute html =~ "This profile is private"
      assert html =~ "Interests"
    end

    test "hides bio when not connected and profile is private", %{conn: conn} do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      # Add bio to other user's profile
      {:ok, _profile} = Profiles.create_profile(other_user.id, %{bio: "This is my bio"})

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "This profile is private"
      refute html =~ "This is my bio"
      refute html =~ "About"
    end

    test "hides social links when not connected and profile is private", %{conn: conn} do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      # Add social links to other user's profile
      {:ok, _profile} =
        Profiles.create_profile(other_user.id, %{
          instagram: "testuser",
          twitter: "testuser"
        })

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "This profile is private"
      refute html =~ "Social Links"
      refute html =~ "@testuser"
    end

    test "shows interests when connected to private profile", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      accepted_connection_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      refute html =~ "This profile is private"
      assert html =~ "Interests"
    end

    test "shows bio when connected", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, _profile} = Profiles.create_profile(other_user.id, %{bio: "This is my bio"})

      accepted_connection_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "About"
      assert html =~ "This is my bio"
    end

    test "shows social links when connected", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, _profile} =
        Profiles.create_profile(other_user.id, %{
          instagram: "testuser",
          twitter: "testuser"
        })

      accepted_connection_fixture(user.id, other_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ "Social Links"
      assert html =~ "@testuser"
      assert html =~ "instagram.com"
      assert html =~ "twitter.com"
    end
  end

  describe "Profile display" do
    setup :register_and_log_in_onboarded_user

    test "shows user name and location", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      assert html =~ other_user.first_name
      assert html =~ other_user.last_name
      assert html =~ other_user.location
    end

    test "shows profile photo when present", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      # Add profile photo
      {:ok, updated_user} =
        InterestSpotlight.Accounts.update_user_profile(Scope.for_user(other_user), %{
          profile_photo: "test/photo.jpg"
        })

      accepted_connection_fixture(user.id, updated_user.id)

      {:ok, _lv, html} = live(conn, ~p"/connections/#{updated_user.id}")

      assert html =~ "/uploads/test/photo.jpg"
    end

    test "shows initials placeholder when no profile photo", %{conn: conn} do
      other_user = onboarded_user_fixture()

      {:ok, _lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show "TU" for "Test User"
      assert html =~ "TU"
    end
  end

  describe "Real-time updates via PubSub" do
    setup :register_and_log_in_onboarded_user

    test "updates UI when other user sends connection request", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()

      {:ok, lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show Connect button initially
      assert html =~ "Connect"

      # Simulate other user sending a request
      {:ok, _connection} = Connections.create_connection_request(other_user.id, user.id)

      # Wait for PubSub message
      :timer.sleep(100)

      html = render(lv)

      # Should now show Accept/Reject buttons
      assert html =~ "Accept Request"
      assert html =~ "Reject"
    end

    test "updates UI when other user accepts connection request", %{conn: conn, user: user} do
      other_user = onboarded_user_fixture()
      connection = connection_request_fixture(user.id, other_user.id)

      {:ok, lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show Cancel Request button initially
      assert html =~ "Cancel Request"

      # Simulate other user accepting the request
      {:ok, _accepted} = Connections.accept_connection_request(connection)

      # Wait for PubSub message
      :timer.sleep(100)

      html = render(lv)

      # Should now show Remove Connection button
      assert html =~ "Remove Connection"
    end

    test "updates UI when other user removes connection from private profile", %{
      conn: conn,
      user: user
    } do
      other_user = onboarded_user_fixture()
      # Make the other user's profile private
      {:ok, _} =
        Accounts.update_user_profile(Scope.for_user(other_user), %{profile_visibility: "private"})

      connection = accepted_connection_fixture(user.id, other_user.id)

      {:ok, lv, html} = live(conn, ~p"/connections/#{other_user.id}")

      # Should show Remove Connection button and full profile initially (connected)
      assert html =~ "Remove Connection"
      refute html =~ "This profile is private"

      # Simulate other user removing the connection
      {:ok, _removed} = Connections.remove_connection(connection)

      # Wait for PubSub message
      :timer.sleep(100)

      html = render(lv)

      # Should now show Connect button and hidden content (private profile, not connected)
      assert html =~ "Connect"
      assert html =~ "This profile is private"
    end
  end
end
