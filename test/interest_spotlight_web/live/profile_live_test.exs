defmodule InterestSpotlightWeb.ProfileLiveTest do
  use InterestSpotlightWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InterestSpotlight.AccountsFixtures

  alias InterestSpotlight.Accounts

  describe "Profile page" do
    setup :register_and_log_in_onboarded_user

    test "renders profile page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "Profile"
      assert html =~ "Profile Photo"
      assert html =~ "Account Information"
    end

    test "redirects if user is not logged in", %{conn: _conn} do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/profile")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays user email", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ user.email
    end

    test "shows placeholder when no profile photo", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      # Should show the placeholder icon (hero-user)
      assert html =~ "hero-user"
      # Should not have an img tag with uploads path
      refute html =~ ~r/<img[^>]+src="\/uploads\//
    end

    test "shows profile photo when present", %{conn: conn, user: user} do
      photo_path = "#{user.id}/profile_photo/#{user.id}.jpg"
      {:ok, _user_with_photo} = Accounts.update_user_profile(user, %{profile_photo: photo_path})

      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "/uploads/#{photo_path}"
    end

    test "shows delete button when profile photo exists", %{conn: conn, user: user} do
      {:ok, _user_with_photo} =
        Accounts.update_user_profile(user, %{profile_photo: "1/photo.jpg"})

      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "Delete"
      assert html =~ "delete_photo"
    end

    test "hides delete button when no profile photo", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      refute html =~ "phx-click=\"delete_photo\""
    end

    test "has link to account settings", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ ~p"/users/settings"
      assert html =~ "Account Settings"
    end
  end

  describe "Photo upload" do
    setup :register_and_log_in_onboarded_user

    test "shows file input for uploading", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "upload-form"
      assert html =~ "Upload Photo"
    end

    test "upload button is disabled when no file selected", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "btn-disabled"
    end

    test "shows supported formats info", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/profile")

      assert html =~ "JPG, JPEG, PNG"
      assert html =~ "5MB"
    end
  end

  describe "Photo deletion" do
    setup %{conn: conn} do
      user = onboarded_user_fixture()

      {:ok, user_with_photo} =
        Accounts.update_user_profile(user, %{profile_photo: "test/photo.jpg"})

      %{conn: log_in_user(conn, user_with_photo), user: user_with_photo}
    end

    test "delete_photo event removes the profile photo from database", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      # Trigger delete
      lv
      |> element("button[phx-click='delete_photo']")
      |> render_click()

      # Verify the photo was removed from database
      updated_user = Accounts.get_user!(user.id)
      assert is_nil(updated_user.profile_photo)
    end

    test "shows success flash after deletion", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> element("button[phx-click='delete_photo']")
        |> render_click()

      assert result =~ "Photo deleted successfully"
    end

    test "hides delete button after deletion", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> element("button[phx-click='delete_photo']")
        |> render_click()

      refute result =~ "phx-click=\"delete_photo\""
    end
  end
end
