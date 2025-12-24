defmodule InterestSpotlightWeb.AdminLiveTest do
  use InterestSpotlightWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InterestSpotlight.AccountsFixtures

  alias InterestSpotlight.Interests

  describe "Admin Dashboard" do
    setup :register_and_log_in_admin

    test "renders admin dashboard", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Admin Dashboard"
      assert html =~ "Manage Interests"
    end

    test "has link to interests management", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ ~p"/admin/interests"
    end

    test "regular user cannot access admin dashboard", %{conn: _conn} do
      user = onboarded_user_fixture()
      conn = build_conn() |> log_in_user(user)

      assert {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/"
    end

    test "non-authenticated user cannot access admin dashboard", %{conn: _conn} do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/admin")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Admin Interests" do
    setup :register_and_log_in_admin

    test "renders interests management page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/interests")

      assert html =~ "Manage Interests"
      assert html =~ "Back to Dashboard"
      assert html =~ "New interest name"
    end

    test "displays existing interests", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Test Interest"})

      {:ok, _lv, html} = live(conn, ~p"/admin/interests")

      assert html =~ interest.name
    end

    test "can add a new interest", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      result =
        lv
        |> form("form", %{"name" => "New Test Interest"})
        |> render_submit()

      assert result =~ "New Test Interest"
      assert Interests.list_interests() |> Enum.any?(&(&1.name == "New Test Interest"))
    end

    test "ignores empty interest name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/interests")
      initial_count = length(Interests.list_interests())

      lv
      |> form("form", %{"name" => "   "})
      |> render_submit()

      assert length(Interests.list_interests()) == initial_count
    end

    test "can start editing an interest", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Edit Me"})

      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      result =
        lv
        |> element("button[phx-click='start_edit'][phx-value-id='#{interest.id}']")
        |> render_click()

      assert result =~ "Save"
      assert result =~ "Cancel"
    end

    test "can save edited interest", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Edit Me"})

      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      # Start edit
      lv
      |> element("button[phx-click='start_edit'][phx-value-id='#{interest.id}']")
      |> render_click()

      # Save edit
      result =
        lv
        |> form("form[phx-submit='save_edit']", %{"name" => "Updated Name"})
        |> render_submit()

      assert result =~ "Updated Name"
      refute result =~ "Edit Me"

      updated = Interests.get_interest!(interest.id)
      assert updated.name == "Updated Name"
    end

    test "can cancel editing", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Edit Me"})

      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      # Start edit
      lv
      |> element("button[phx-click='start_edit'][phx-value-id='#{interest.id}']")
      |> render_click()

      # Cancel edit
      result =
        lv
        |> element("button[phx-click='cancel_edit']")
        |> render_click()

      refute result =~ "Save"
      assert result =~ "Edit Me"
    end

    test "can delete an interest", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Delete Me"})

      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      result =
        lv
        |> element("button[phx-click='delete'][phx-value-id='#{interest.id}']")
        |> render_click()

      refute result =~ "Delete Me"
      assert_raise Ecto.NoResultsError, fn -> Interests.get_interest!(interest.id) end
    end

    test "shows empty state when no interests", %{conn: conn} do
      # Ensure no interests exist
      for interest <- Interests.list_interests() do
        Interests.delete_interest(interest)
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/interests")

      assert html =~ "No interests yet"
    end

    test "regular user cannot access interests management", %{conn: _conn} do
      user = onboarded_user_fixture()
      conn = build_conn() |> log_in_user(user)

      assert {:error, redirect} = live(conn, ~p"/admin/interests")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/"
    end

    test "updates new_interest state on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      lv
      |> element("input[name='name']")
      |> render_change(%{"name" => "Typing..."})

      # The input should have the new value
      html = render(lv)
      assert html =~ "Typing..."
    end

    test "updates edit_name state on change during editing", %{conn: conn} do
      {:ok, interest} = Interests.create_interest(%{name: "Edit Me"})

      {:ok, lv, _html} = live(conn, ~p"/admin/interests")

      # Start edit
      lv
      |> element("button[phx-click='start_edit'][phx-value-id='#{interest.id}']")
      |> render_click()

      # Change the edit name
      lv
      |> element("input[name='name'][phx-change='update_edit_name']")
      |> render_change(%{"name" => "New Name"})

      html = render(lv)
      assert html =~ "New Name"
    end
  end
end
