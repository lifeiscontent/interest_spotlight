defmodule InterestSpotlight.Interests do
  @moduledoc """
  The Interests context.
  """

  import Ecto.Query, warn: false
  alias InterestSpotlight.Repo
  alias InterestSpotlight.Interests.{Interest, UserInterest}

  # Interest functions

  def list_interests do
    Interest
    |> order_by(:name)
    |> Repo.all()
  end

  def get_interest!(id), do: Repo.get!(Interest, id)

  def create_interest(attrs \\ %{}) do
    %Interest{}
    |> Interest.changeset(attrs)
    |> Repo.insert()
  end

  def update_interest(%Interest{} = interest, attrs) do
    interest
    |> Interest.changeset(attrs)
    |> Repo.update()
  end

  def delete_interest(%Interest{} = interest) do
    Repo.delete(interest)
  end

  def change_interest(%Interest{} = interest, attrs \\ %{}) do
    Interest.changeset(interest, attrs)
  end

  # User Interest functions

  def list_user_interests(user_id) do
    UserInterest
    |> where([ui], ui.user_id == ^user_id)
    |> preload(:interest)
    |> Repo.all()
  end

  def get_user_interest_ids(user_id) do
    UserInterest
    |> where([ui], ui.user_id == ^user_id)
    |> select([ui], ui.interest_id)
    |> Repo.all()
  end

  def count_user_interests(user_id) do
    UserInterest
    |> where([ui], ui.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  def user_has_minimum_interests?(user_id, minimum \\ 3) do
    count_user_interests(user_id) >= minimum
  end

  def add_user_interest(user_id, interest_id) do
    %UserInterest{}
    |> UserInterest.changeset(%{user_id: user_id, interest_id: interest_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_user_interest(user_id, interest_id) do
    UserInterest
    |> where([ui], ui.user_id == ^user_id and ui.interest_id == ^interest_id)
    |> Repo.delete_all()
  end

  def set_user_interests(user_id, interest_ids) do
    Repo.transaction(fn ->
      # Remove all existing interests
      UserInterest
      |> where([ui], ui.user_id == ^user_id)
      |> Repo.delete_all()

      # Add new interests
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      entries =
        interest_ids
        |> Enum.map(fn interest_id ->
          %{
            user_id: user_id,
            interest_id: interest_id,
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all(UserInterest, entries, on_conflict: :nothing)
    end)
  end
end
