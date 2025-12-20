defmodule InterestSpotlightWeb.OnboardingLiveTest do
  use InterestSpotlightWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InterestSpotlight.AccountsFixtures

  alias InterestSpotlight.Accounts
  alias InterestSpotlight.Interests
  alias InterestSpotlight.Profiles

  describe "BasicInfo" do
    setup :register_and_log_in_user

    test "renders basic info page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding")

      assert html =~ "Create account"
      assert html =~ "First name"
      assert html =~ "Last name"
      assert html =~ "City"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding")

      result =
        lv
        |> form("form", %{
          "user" => %{
            "first_name" => "",
            "last_name" => "",
            "location" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end

    test "saves basic info and redirects to interests", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding")

      {:ok, _lv, html} =
        lv
        |> form("form", %{
          "user" => %{
            "first_name" => "John",
            "last_name" => "Doe",
            "location" => "Bangkok"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/onboarding/interests")

      assert html =~ "Choose your interests"
    end

    test "redirects to login if not authenticated", %{conn: _conn} do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/onboarding")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Interests" do
    setup %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        Accounts.update_user_onboarding(user, %{
          first_name: "Test",
          last_name: "User",
          location: "Test City"
        })

      ensure_interests_exist()

      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders interests page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/interests")

      assert html =~ "Choose your interests"
      assert html =~ "minimum"
      assert html =~ "Next"
    end

    test "displays available interests", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/interests")

      # Check that at least one interest is displayed
      interests = Interests.list_interests()
      first_interest = List.first(interests)
      assert html =~ first_interest.name
    end

    test "can toggle interests on and off", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding/interests")

      interests = Interests.list_interests()
      first_interest = List.first(interests)

      # Select an interest
      lv
      |> element("button[phx-click='toggle_interest'][phx-value-id='#{first_interest.id}']")
      |> render_click()

      # Check it's now selected in database
      assert first_interest.id in Interests.get_user_interest_ids(user.id)

      # Deselect the interest
      lv
      |> element("button[phx-click='toggle_interest'][phx-value-id='#{first_interest.id}']")
      |> render_click()

      # Check it's removed
      refute first_interest.id in Interests.get_user_interest_ids(user.id)
    end

    test "next button is disabled when less than 3 interests selected", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/interests")

      # Button should have disabled styling
      assert html =~ "cursor-not-allowed"
    end

    test "can proceed to about page after selecting 3 interests", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding/interests")

      interests = Interests.list_interests() |> Enum.take(3)

      # Select 3 interests
      for interest <- interests do
        lv
        |> element("button[phx-click='toggle_interest'][phx-value-id='#{interest.id}']")
        |> render_click()
      end

      # Click next
      {:ok, _lv, html} =
        lv
        |> element("button[phx-click='next']")
        |> render_click()
        |> follow_redirect(conn, ~p"/onboarding/about")

      assert html =~ "Tell us more about yourself"
    end

    test "has skip link to about page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/interests")

      assert html =~ "Skip"
      assert html =~ ~p"/onboarding/about"
    end
  end

  describe "About" do
    setup %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        Accounts.update_user_onboarding(user, %{
          first_name: "Test",
          last_name: "User",
          location: "Test City"
        })

      ensure_interests_exist()
      interests = Interests.list_interests() |> Enum.take(3)
      for interest <- interests, do: Interests.add_user_interest(user.id, interest.id)

      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders about page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/about")

      assert html =~ "Tell us more about yourself"
      assert html =~ "About"
      assert html =~ "social profiles"
    end

    test "has skip link to dashboard", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/about")

      assert html =~ "Skip"
    end

    test "has back link to interests", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/onboarding/about")

      assert html =~ ~p"/onboarding/interests"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding/about")

      result =
        lv
        |> form("form", %{
          "profile" => %{
            "bio" => "Test bio"
          }
        })
        |> render_change()

      # Should not show errors for optional fields
      refute result =~ "can&#39;t be blank"
    end

    test "saves profile and redirects to dashboard", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/onboarding/about")

      {:ok, _lv, html} =
        lv
        |> form("form", %{
          "profile" => %{
            "bio" => "My bio",
            "instagram" => "@myinsta",
            "facebook" => "@myfb",
            "twitter" => "@mytwitter",
            "tiktok" => "@mytiktok",
            "youtube" => "@myyoutube"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard")

      assert html =~ "Dashboard"

      # Verify profile was saved
      profile = Profiles.get_profile_by_user_id(user.id)
      assert profile.bio == "My bio"
      assert profile.instagram == "@myinsta"
    end

    test "creates profile if one doesn't exist", %{conn: conn, user: user} do
      # Ensure no profile exists
      assert Profiles.get_profile_by_user_id(user.id) == nil

      {:ok, _lv, _html} = live(conn, ~p"/onboarding/about")

      # Profile should be created on mount
      assert Profiles.get_profile_by_user_id(user.id) != nil
    end
  end

  defp ensure_interests_exist do
    if Interests.list_interests() == [] do
      Interests.create_interest(%{name: "Test Interest 1"})
      Interests.create_interest(%{name: "Test Interest 2"})
      Interests.create_interest(%{name: "Test Interest 3"})
      Interests.create_interest(%{name: "Test Interest 4"})
    end
  end
end
