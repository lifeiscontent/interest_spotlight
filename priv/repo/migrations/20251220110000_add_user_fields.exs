defmodule InterestSpotlight.Repo.Migrations.AddUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :location, :string
      add :user_type, :string, default: "user", null: false
    end

    create index(:users, [:user_type])
  end
end
