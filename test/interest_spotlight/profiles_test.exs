defmodule InterestSpotlight.ProfilesTest do
  use InterestSpotlight.DataCase, async: true

  alias InterestSpotlight.Profiles
  alias InterestSpotlight.Profiles.Profile

  import InterestSpotlight.AccountsFixtures

  describe "get_profile_by_user_id/1" do
    test "returns nil when no profile exists" do
      user = user_fixture()
      assert Profiles.get_profile_by_user_id(user.id) == nil
    end

    test "returns profile when one exists" do
      user = user_fixture()
      {:ok, profile} = Profiles.create_profile(user.id, %{bio: "Test bio"})

      found = Profiles.get_profile_by_user_id(user.id)
      assert found.id == profile.id
      assert found.bio == "Test bio"
    end
  end

  describe "get_or_create_profile/1" do
    test "creates profile when none exists" do
      user = user_fixture()
      assert Profiles.get_profile_by_user_id(user.id) == nil

      profile = Profiles.get_or_create_profile(user.id)
      assert profile.user_id == user.id
      assert profile.id != nil
    end

    test "returns existing profile when one exists" do
      user = user_fixture()
      {:ok, existing} = Profiles.create_profile(user.id, %{bio: "Existing bio"})

      profile = Profiles.get_or_create_profile(user.id)
      assert profile.id == existing.id
      assert profile.bio == "Existing bio"
    end
  end

  describe "create_profile/2" do
    test "creates profile with valid attributes" do
      user = user_fixture()

      {:ok, profile} =
        Profiles.create_profile(user.id, %{
          bio: "My bio",
          instagram: "@insta",
          facebook: "@fb",
          twitter: "@twitter",
          tiktok: "@tiktok",
          youtube: "@youtube"
        })

      assert profile.user_id == user.id
      assert profile.bio == "My bio"
      assert profile.instagram == "@insta"
      assert profile.facebook == "@fb"
      assert profile.twitter == "@twitter"
      assert profile.tiktok == "@tiktok"
      assert profile.youtube == "@youtube"
    end

    test "creates profile with empty attributes" do
      user = user_fixture()
      {:ok, profile} = Profiles.create_profile(user.id)

      assert profile.user_id == user.id
      assert profile.bio == nil
    end
  end

  describe "update_profile/2" do
    test "updates profile with valid attributes" do
      user = user_fixture()
      {:ok, profile} = Profiles.create_profile(user.id, %{bio: "Original"})

      {:ok, updated} = Profiles.update_profile(profile, %{bio: "Updated"})

      assert updated.bio == "Updated"
    end

    test "updates multiple fields" do
      user = user_fixture()
      {:ok, profile} = Profiles.create_profile(user.id)

      {:ok, updated} =
        Profiles.update_profile(profile, %{
          bio: "New bio",
          instagram: "@newinsta",
          twitter: "@newtwitter"
        })

      assert updated.bio == "New bio"
      assert updated.instagram == "@newinsta"
      assert updated.twitter == "@newtwitter"
    end
  end

  describe "change_profile/2" do
    test "returns a changeset" do
      user = user_fixture()
      {:ok, profile} = Profiles.create_profile(user.id)

      changeset = Profiles.change_profile(profile, %{bio: "New bio"})
      assert %Ecto.Changeset{} = changeset
    end

    test "returns changeset with default empty attrs" do
      profile = %Profile{}
      changeset = Profiles.change_profile(profile)
      assert %Ecto.Changeset{} = changeset
    end
  end
end
