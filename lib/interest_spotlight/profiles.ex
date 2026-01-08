defmodule InterestSpotlight.Profiles do
  @moduledoc """
  The Profiles context.
  """

  import Ecto.Query, warn: false
  alias InterestSpotlight.Repo
  alias InterestSpotlight.Profiles.Profile

  def get_profile_by_user_id(user_id) do
    Repo.get_by(Profile, user_id: user_id)
  end

  def get_or_create_profile(user_id) do
    case get_profile_by_user_id(user_id) do
      nil ->
        %Profile{}
        |> Profile.changeset(%{})
        |> Ecto.Changeset.put_change(:user_id, user_id)
        |> Repo.insert!()

      profile ->
        profile
    end
  end

  def change_profile(%Profile{} = profile, attrs \\ %{}) do
    Profile.changeset(profile, attrs)
  end

  def update_profile(%Profile{} = profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  def create_profile(user_id, attrs \\ %{}) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert()
  end
end
