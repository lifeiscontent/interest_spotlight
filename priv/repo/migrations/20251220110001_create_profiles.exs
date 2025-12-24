defmodule InterestSpotlight.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :bio, :text
      add :instagram, :string
      add :facebook, :string
      add :twitter, :string
      add :tiktok, :string
      add :youtube, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])
  end
end
