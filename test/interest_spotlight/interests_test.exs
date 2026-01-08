defmodule InterestSpotlight.InterestsTest do
  use InterestSpotlight.DataCase, async: true

  alias InterestSpotlight.Interests
  alias InterestSpotlight.Interests.Interest

  import InterestSpotlight.AccountsFixtures

  describe "list_interests/0" do
    test "returns interests ordered by name" do
      # There may be seed data, so just verify ordering
      interests = Interests.list_interests()
      names = Enum.map(interests, & &1.name)

      # Verify they're sorted (case-insensitive as that's what SQL does by default)
      assert names == Enum.sort_by(names, &String.downcase/1)
    end

    test "includes newly created interests" do
      {:ok, new_interest} = Interests.create_interest(%{name: "ZZZZZ Unique Test Interest"})

      interests = Interests.list_interests()
      names = Enum.map(interests, & &1.name)

      assert "ZZZZZ Unique Test Interest" in names

      # Clean up
      Interests.delete_interest(new_interest)
    end
  end

  describe "get_interest!/1" do
    test "returns interest by id" do
      {:ok, interest} = Interests.create_interest(%{name: "Test"})
      found = Interests.get_interest!(interest.id)
      assert found.name == "Test"
    end

    test "raises when interest not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Interests.get_interest!(999_999)
      end
    end
  end

  describe "create_interest/1" do
    test "creates interest with valid name" do
      unique_name = "Unique Test Interest #{System.unique_integer()}"
      {:ok, interest} = Interests.create_interest(%{name: unique_name})
      assert interest.name == unique_name
    end

    test "auto-generates slug from name" do
      {:ok, interest} = Interests.create_interest(%{name: "Digital Art"})
      assert interest.slug == "digital-art"
    end

    test "generates slug with special characters removed" do
      {:ok, interest} = Interests.create_interest(%{name: "3D Modeling & Animation!"})
      assert interest.slug == "3d-modeling-animation"
    end

    test "allows custom slug" do
      {:ok, interest} = Interests.create_interest(%{name: "My Interest", slug: "custom-slug"})
      assert interest.slug == "custom-slug"
    end

    test "fails with empty name" do
      {:error, changeset} = Interests.create_interest(%{name: ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails with duplicate name" do
      {:ok, _} = Interests.create_interest(%{name: "Unique Art"})
      {:error, changeset} = Interests.create_interest(%{name: "Unique Art"})
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "fails with duplicate slug" do
      {:ok, _} = Interests.create_interest(%{name: "Art One", slug: "art"})
      {:error, changeset} = Interests.create_interest(%{name: "Art Two", slug: "art"})
      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "fails with invalid slug format" do
      {:error, changeset} = Interests.create_interest(%{name: "Test", slug: "Invalid Slug!"})
      assert %{slug: ["must be lowercase with hyphens only"]} = errors_on(changeset)
    end
  end

  describe "update_interest/2" do
    test "updates interest name" do
      {:ok, interest} = Interests.create_interest(%{name: "Old Name"})
      {:ok, updated} = Interests.update_interest(interest, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "updates slug when name changes" do
      {:ok, interest} = Interests.create_interest(%{name: "Old Name"})
      assert interest.slug == "old-name"

      {:ok, updated} = Interests.update_interest(interest, %{name: "New Name"})
      assert updated.slug == "new-name"
    end

    test "allows updating slug independently" do
      {:ok, interest} = Interests.create_interest(%{name: "My Interest"})
      {:ok, updated} = Interests.update_interest(interest, %{slug: "custom-slug"})
      assert updated.slug == "custom-slug"
      assert updated.name == "My Interest"
    end

    test "fails with empty name" do
      {:ok, interest} = Interests.create_interest(%{name: "Valid"})
      {:error, changeset} = Interests.update_interest(interest, %{name: ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "delete_interest/1" do
    test "deletes interest" do
      {:ok, interest} = Interests.create_interest(%{name: "To Delete"})
      {:ok, deleted} = Interests.delete_interest(interest)
      assert deleted.id == interest.id

      assert_raise Ecto.NoResultsError, fn ->
        Interests.get_interest!(interest.id)
      end
    end
  end

  describe "change_interest/2" do
    test "returns a changeset" do
      interest = %Interest{}
      changeset = Interests.change_interest(interest, %{name: "Test"})
      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "list_user_interests/1" do
    test "returns empty list when no user interests" do
      user = user_fixture()
      assert Interests.list_user_interests(user.id) == []
    end

    test "returns user interests with preloaded interest" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "User Interest"})
      Interests.add_user_interest(user.id, interest.id)

      user_interests = Interests.list_user_interests(user.id)
      assert length(user_interests) == 1
      assert hd(user_interests).interest.name == "User Interest"
    end
  end

  describe "get_user_interest_ids/1" do
    test "returns empty list when no interests" do
      user = user_fixture()
      assert Interests.get_user_interest_ids(user.id) == []
    end

    test "returns list of interest ids" do
      user = user_fixture()
      {:ok, i1} = Interests.create_interest(%{name: "Interest 1"})
      {:ok, i2} = Interests.create_interest(%{name: "Interest 2"})

      Interests.add_user_interest(user.id, i1.id)
      Interests.add_user_interest(user.id, i2.id)

      ids = Interests.get_user_interest_ids(user.id)
      assert length(ids) == 2
      assert i1.id in ids
      assert i2.id in ids
    end
  end

  describe "count_user_interests/1" do
    test "returns 0 when no interests" do
      user = user_fixture()
      assert Interests.count_user_interests(user.id) == 0
    end

    test "returns correct count" do
      user = user_fixture()
      {:ok, i1} = Interests.create_interest(%{name: "Count 1"})
      {:ok, i2} = Interests.create_interest(%{name: "Count 2"})
      {:ok, i3} = Interests.create_interest(%{name: "Count 3"})

      Interests.add_user_interest(user.id, i1.id)
      Interests.add_user_interest(user.id, i2.id)
      Interests.add_user_interest(user.id, i3.id)

      assert Interests.count_user_interests(user.id) == 3
    end
  end

  describe "user_has_minimum_interests?/2" do
    test "returns false when below minimum" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Only One"})
      Interests.add_user_interest(user.id, interest.id)

      refute Interests.user_has_minimum_interests?(user.id)
    end

    test "returns true when at or above minimum" do
      user = user_fixture()

      for i <- 1..3 do
        {:ok, interest} = Interests.create_interest(%{name: "Min #{i}"})
        Interests.add_user_interest(user.id, interest.id)
      end

      assert Interests.user_has_minimum_interests?(user.id)
    end

    test "accepts custom minimum" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Custom"})
      Interests.add_user_interest(user.id, interest.id)

      assert Interests.user_has_minimum_interests?(user.id, 1)
      refute Interests.user_has_minimum_interests?(user.id, 2)
    end
  end

  describe "add_user_interest/2" do
    test "adds user interest" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Add Me"})

      {:ok, _} = Interests.add_user_interest(user.id, interest.id)

      assert interest.id in Interests.get_user_interest_ids(user.id)
    end

    test "handles duplicate gracefully" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Duplicate"})

      {:ok, _} = Interests.add_user_interest(user.id, interest.id)
      {:ok, _} = Interests.add_user_interest(user.id, interest.id)

      # Should still only have one entry
      assert Interests.count_user_interests(user.id) == 1
    end
  end

  describe "remove_user_interest/2" do
    test "removes user interest" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Remove Me"})
      Interests.add_user_interest(user.id, interest.id)

      assert interest.id in Interests.get_user_interest_ids(user.id)

      Interests.remove_user_interest(user.id, interest.id)

      refute interest.id in Interests.get_user_interest_ids(user.id)
    end

    test "handles non-existent interest gracefully" do
      user = user_fixture()
      # Should not raise
      {count, _} = Interests.remove_user_interest(user.id, 999_999)
      assert count == 0
    end
  end

  describe "set_user_interests/2" do
    test "sets user interests replacing existing" do
      user = user_fixture()
      {:ok, i1} = Interests.create_interest(%{name: "Set 1"})
      {:ok, i2} = Interests.create_interest(%{name: "Set 2"})
      {:ok, i3} = Interests.create_interest(%{name: "Set 3"})

      # Add initial interest
      Interests.add_user_interest(user.id, i1.id)
      assert Interests.count_user_interests(user.id) == 1

      # Set new interests
      {:ok, _} = Interests.set_user_interests(user.id, [i2.id, i3.id])

      ids = Interests.get_user_interest_ids(user.id)
      assert length(ids) == 2
      refute i1.id in ids
      assert i2.id in ids
      assert i3.id in ids
    end

    test "clears all interests when given empty list" do
      user = user_fixture()
      {:ok, interest} = Interests.create_interest(%{name: "Clear"})
      Interests.add_user_interest(user.id, interest.id)

      {:ok, _} = Interests.set_user_interests(user.id, [])

      assert Interests.count_user_interests(user.id) == 0
    end
  end
end
