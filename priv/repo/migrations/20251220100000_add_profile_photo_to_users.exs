defmodule InterestSpotlight.Repo.Migrations.AddProfilePhotoToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_photo, :string
    end
  end
end
