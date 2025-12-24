defmodule InterestSpotlight.Repo.Migrations.AddProfileVisibilityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_visibility, :string, default: "public", null: false
    end
  end
end
